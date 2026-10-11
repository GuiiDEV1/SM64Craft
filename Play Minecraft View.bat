@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launcher\play-minecraft-view.ps1"
if errorlevel 1 (
    echo.
    echo Minecraft View nao iniciou. Veja a mensagem acima.
    pause
)
endlocal
