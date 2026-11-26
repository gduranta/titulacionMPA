@echo off
chcp 65001 >nul
title titulacionMPA - Gestor de Servidor Local + Cloudflare
cd /d "%~dp0\.."

if /I "%~1"=="start" goto iniciar
if /I "%~1"=="stop" goto detener
if /I "%~1"=="status" goto estado

:menu
cls
echo ============================================================
echo   titulacionMPA - Servidor Local + Cloudflare Tunnel
echo ============================================================
echo   [1] Iniciar servicio (Shiny + Cloudflare Tunnel)
echo   [2] Detener servicio
echo   [3] Ver estado del servicio
echo   [4] Salir
echo ============================================================
set /p op="Selecciona una opcion (1-4): "

if "%op%"=="1" goto iniciar
if "%op%"=="2" goto detener
if "%op%"=="3" goto estado
if "%op%"=="4" exit /b 0
goto menu

:iniciar
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lanzar_con_cloudflare.ps1"
echo.
pause
goto menu

:detener
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lanzar_con_cloudflare.ps1" -Stop
echo.
pause
goto menu

:estado
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lanzar_con_cloudflare.ps1" -Status
echo.
pause
goto menu
