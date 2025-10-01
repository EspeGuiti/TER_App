@echo off
setlocal
cd /d "%~dp0"

REM try pythonw.exe first (no console)
where pythonw >nul 2>&1
if %errorlevel%==0 (
  pythonw LaunchApp.pyw
  exit /b %errorlevel%
)

REM fallback to py -3.11 -w (no console)
py -3.11 -w LaunchApp.pyw
exit /b %errorlevel%
