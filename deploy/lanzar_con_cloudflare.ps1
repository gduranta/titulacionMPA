param(
  [int]$Port = 3838,
  [string]$ExcelPath = "",
  [string]$TunnelName = "",
  [string]$PublicUrl = "",
  [bool]$AutoPush = $true
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

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
  Write-Host "[Shiny] Servidor listo en http://127.0.0.1:$Port" -ForegroundColor Green

  if ($TunnelName) {
    Write-Host "=== 2. Iniciando Cloudflare Named Tunnel '$TunnelName' ===" -ForegroundColor Cyan
    if ($PublicUrl) { Update-PagesConfig -Url $PublicUrl }
    & $CloudflaredBin tunnel --no-autoupdate run $TunnelName
  } else {
    Write-Host "=== 2. Iniciando Cloudflare Quick Tunnel hacia http://127.0.0.1:$Port ===" -ForegroundColor Cyan
    Write-Host "Presiona Ctrl+C para detener el servidor y el túnel." -ForegroundColor Yellow

    $cfErr = Join-Path $env:TEMP "titulacionMPA_cloudflared.log"
    if (Test-Path $cfErr) { Remove-Item $cfErr -Force }

    $cfProc = Start-Process -FilePath $CloudflaredBin `
      -ArgumentList @("tunnel", "--no-autoupdate", "--url", "http://127.0.0.1:$Port", "--logfile", $cfErr) `
      -NoNewWindow -PassThru

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
}
