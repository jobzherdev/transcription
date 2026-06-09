@echo off
rem uninstall.cmd - ASCII-only launcher (see SPEC section 12). Real logic in uninstall.ps1.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
echo.
pause
