@echo off
setlocal
cd /d "%~dp0"

REM primero intenta pythonw (sin consola)
where pythonw >nul 2>&1
if %errorlevel%==0 (
  pythonw RunApp.pyw
  exit /b %errorlevel%
)

REM si no, python normal (verás consola unos segundos)
python RunApp.pyw
exit /b %errorlevel%
