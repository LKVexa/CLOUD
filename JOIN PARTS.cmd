@echo off
setlocal EnableExtensions DisableDelayedExpansion
powershell.exe -NoLogo -NoProfile -File "%~dp0JOIN PARTS.ps1"
set "join_result=%errorlevel%"
echo.
pause
exit /b %join_result%
