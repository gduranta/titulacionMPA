param(
  [int]$Port = 3838,
  [string]$ExcelPath = "",
  [string]$TunnelName = "",
  [string]$PublicUrl = "",
  [bool]$AutoPush = $true,
  [switch]$Stop,
  [switch]$Status
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot
$PidFile = Join-Path $env:TEMP "titulacionMPA_pids.json"

function Get-ServiceProcesses {
  $pids = @()
  if (Test-Path $PidFile) {
    try {
      $info = Get-Content $PidFile -Raw | ConvertFrom-Json
      if ($info.rPid) { $pids += [int]$info.rPid }
      if ($info.cfPid) { $pids += [int]$info.cfPid }
    } catch {}
  }

  # Respaldo: detectar procesos escuchando en el puerto o cloudflared apuntando al puerto
  try {
    $conns = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    foreach ($c in $conns) {
      if ($c.OwningProcess -gt 0) { $pids += [int]$c.OwningProcess }
    }
  } catch {}

  try {
    $cfProcs = Get-CimInstance Win32_Process -Filter "Name = 'cloudflared.exe'" -ErrorAction SilentlyContinue |
      Where-Object { $_.CommandLine -match "127\.0\.0\.1:$Port" -or ($TunnelName -and $_.CommandLine -match [regex]::Escape($TunnelName)) }
    foreach ($p in $cfProcs) {
      $pids += [int]$p.ProcessId
    }
  } catch {}

  $unique = $pids | Select-Object -Unique
  $active = @()
  foreach ($procId in $unique) {
    $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($p) { $active += $p }
  }
  return $active
}

function Stop-MpaService {
  $active = Get-ServiceProcesses
  if ($active.Count -eq 0) {
    Write-Host "[Estado] No hay procesos activos de titulacionMPA en el puerto $Port." -ForegroundColor Yellow
  } else {
    foreach ($p in $active) {
      Write-Host "[Deteniendo] $($p.ProcessName) (PID $($p.Id))..." -ForegroundColor Yellow
      Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] Servicio detenido correctamente." -ForegroundColor Green
  }
  if (Test-Path $PidFile) { Remove-Item $PidFile -Force -ErrorAction SilentlyContinue }
}

function Show-MpaStatus {
  $active = Get-ServiceProcesses
  if ($active.Count -eq 0) {
    Write-Host "[Estado] Servicio DETENIDO (puerto $Port libre)." -ForegroundColor Yellow
  } else {
    Write-Host "[Estado] Servicio ACTIVO en puerto ${Port}:" -ForegroundColor Green
    foreach ($p in $active) {
      Write-Host "  - $($p.ProcessName) (PID $($p.Id))"
    }
  }
}

if ($Stop) {
  Stop-MpaService
  exit 0
}

if ($Status) {
  Show-MpaStatus
  exit 0
}

function Save-PidFile([int]$RPid, [int]$CfPid) {
  $obj = @{ rPid = $RPid; cfPid = $CfPid; port = $Port }
  [System.IO.File]::WriteAllText($PidFile, ($obj | ConvertTo-Json), [System.Text.UTF8Encoding]::new($false))
}

function Find-Rscript {
  $cmd = Get-Command Rscript -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $candidates = Get-ChildItem "C:\Program Files\R\*\bin\Rscript.exe" -ErrorAction SilentlyContinue | Sort-Object FullName -Descending
  if ($candidates) { return $candidates[0].FullName }
  throw "No se encontró Rscript.exe en PATH ni en C:\Program Files\R."
}

function Find-Cloudflared {
  $cmd = Get-Command cloudflared -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $default = "C:\Program Files (x86)\cloudflared\cloudflared.exe"
  if (Test-Path $default) { return $default }
  throw "No se encontró cloudflared.exe. Instálalo con: winget install Cloudflare.cloudflared"
}

function Update-PagesConfig([string]$Url) {
  $cfgPath = Join-Path $RepoRoot "docs\config.json"
  $obj = [ordered]@{
    serverUrl   = $Url
    updatedAt   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")
    institution = "Municipalidad Provincial de Anta - GDUR"
    appName     = "Sistema de Formalización y Titulación de Predios (titulacionMPA)"
  }
  $json = $obj | ConvertTo-Json -Depth 4
  [System.IO.File]::WriteAllText($cfgPath, $json + "`n", [System.Text.UTF8Encoding]::new($false))
  Write-Host "[GitHub Pages] docs/config.json actualizado con: $Url" -ForegroundColor Green

  if ($AutoPush) {
    $diff = git status --porcelain docs/config.json
    if ($diff) {
      git add docs/config.json
      git commit -m "chore: update cloudflare tunnel url"
      git push origin HEAD
      Write-Host "[GitHub Pages] Cambios enviados a GitHub. En ~30s estará activo en GitHub Pages." -ForegroundColor Cyan
    }
  }
}

$existing = Get-ServiceProcesses
if ($existing.Count -gt 0) {
  Write-Host "Ya existe una instancia activa. Deteniéndola antes de reiniciar..." -ForegroundColor Yellow
  Stop-MpaService
  Start-Sleep -Milliseconds 500
}

$RscriptBin = Find-Rscript
$CloudflaredBin = Find-Cloudflared

$env:MPA_PORT = "$Port"
$env:MPA_HOST = "127.0.0.1"
if ($ExcelPath) { $env:MPA_EXCEL_PATH = $ExcelPath }

Write-Host "=== 1. Iniciando servidor local Shiny en http://127.0.0.1:$Port ===" -ForegroundColor Cyan
$rLog = Join-Path $env:TEMP "titulacionMPA_shiny.log"
$rErr = Join-Path $env:TEMP "titulacionMPA_shiny_err.log"
$rProc = Start-Process -FilePath $RscriptBin `
  -ArgumentList @("--vanilla", (Join-Path $RepoRoot "deploy\iniciar_servidor.R")) `
  -WorkingDirectory $RepoRoot `
  -RedirectStandardOutput $rLog `
  -RedirectStandardError $rErr `
  -NoNewWindow -PassThru

Save-PidFile -RPid $rProc.Id -CfPid 0

try {
  $ready = $false
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 500
    if ($rProc.HasExited) {
      Write-Host (Get-Content $rErr -Raw -ErrorAction SilentlyContinue) -ForegroundColor Red
      throw "El servidor R terminó inesperadamente (código $($rProc.ExitCode))."
    }
    try {
      $resp = Invoke-WebRequest -Uri "http://127.0.0.1:$Port" -UseBasicParsing -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) {
    throw "Tiempo de espera agotado esperando a Shiny en http://127.0.0.1:$Port"
  }
  Write-Host "[Shiny] Servidor listo en http://127.0.0.1:$Port (PID $($rProc.Id))" -ForegroundColor Green

  if ($TunnelName) {
    Write-Host "=== 2. Iniciando Cloudflare Named Tunnel '$TunnelName' ===" -ForegroundColor Cyan
    if ($PublicUrl) { Update-PagesConfig -Url $PublicUrl }
    $cfProc = Start-Process -FilePath $CloudflaredBin `
      -ArgumentList @("tunnel", "--no-autoupdate", "run", $TunnelName) `
      -NoNewWindow -PassThru
    Save-PidFile -RPid $rProc.Id -CfPid $cfProc.Id
    try {
      Wait-Process -Id $cfProc.Id
    } finally {
      if ($cfProc -and -not $cfProc.HasExited) {
        Stop-Process -Id $cfProc.Id -Force -ErrorAction SilentlyContinue
      }
    }
  } else {
    Write-Host "=== 2. Iniciando Cloudflare Quick Tunnel hacia http://127.0.0.1:$Port ===" -ForegroundColor Cyan
    Write-Host "Presiona Ctrl+C o usa la opción 'Detener servicio' del lanzador para cerrar." -ForegroundColor Yellow

    $cfErr = Join-Path $env:TEMP "titulacionMPA_cloudflared.log"
    if (Test-Path $cfErr) { Remove-Item $cfErr -Force }

    $cfProc = Start-Process -FilePath $CloudflaredBin `
      -ArgumentList @("tunnel", "--no-autoupdate", "--url", "http://127.0.0.1:$Port", "--logfile", $cfErr) `
      -NoNewWindow -PassThru

    Save-PidFile -RPid $rProc.Id -CfPid $cfProc.Id

    try {
      $tunnelUrl = ""
      for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 500
        if ($cfProc.HasExited) { throw "cloudflared terminó inesperadamente." }
        if (Test-Path $cfErr) {
          $txt = Get-Content $cfErr -Raw -ErrorAction SilentlyContinue
          if ($txt -match 'https://[a-z0-9-]+\.trycloudflare\.com') {
            $tunnelUrl = $Matches[0]
            break
          }
        }
      }

      if (-not $tunnelUrl) {
        throw "No se pudo detectar la URL *.trycloudflare.com en $cfErr"
      }

      Write-Host "[Cloudflare] Túnel activo: $tunnelUrl" -ForegroundColor Green
      Update-PagesConfig -Url $tunnelUrl
      Write-Host "Manteniendo servidor activo. No cierres esta ventana..." -ForegroundColor Cyan

      Wait-Process -Id $cfProc.Id
    } finally {
      if ($cfProc -and -not $cfProc.HasExited) {
        Stop-Process -Id $cfProc.Id -Force -ErrorAction SilentlyContinue
      }
    }
  }
} finally {
  if ($rProc -and -not $rProc.HasExited) {
    Write-Host "Deteniendo servidor R..." -ForegroundColor Yellow
    Stop-Process -Id $rProc.Id -Force -ErrorAction SilentlyContinue
  }
  if (Test-Path $PidFile) { Remove-Item $PidFile -Force -ErrorAction SilentlyContinue }
}
