@echo off
title titulacionMPA - Servidor Local + Cloudflare Tunnel
cd /d "%~dp0\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lanzar_con_cloudflare.ps1"
pause
