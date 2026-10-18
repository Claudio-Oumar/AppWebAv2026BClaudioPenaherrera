@echo off
chcp 65001 >nul
setlocal
title PoliMusic - Despliegue en IIS

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ================================================================
    echo   Se necesitan permisos de administrador para:
    echo     - Habilitar Classic ASP en IIS
    echo     - Copiar la aplicacion a C:\inetpub\wwwroot
    echo     - Configurar el App Pool y los permisos
    echo.
    echo   Windows mostrara un aviso de UAC. Aceptalo.
    echo ================================================================
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\deploy-iis.ps1"

echo.
echo ----------------------------------------------------------------
echo  Revisa el detalle en: %~dp0tools\deploy-log.txt
echo  Luego abre:  http://localhost/
echo ----------------------------------------------------------------
echo.
pause
