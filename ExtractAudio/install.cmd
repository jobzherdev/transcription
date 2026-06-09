@echo off
rem install.cmd - ASCII-only launcher (see SPEC section 12). Real logic in install.ps1.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
pause
