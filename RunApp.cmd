@echo off
setlocal
cd /d "%~dp0"

REM Intentar pythonw (sin consola)
where pythonw >nul 2>&1
if %errorlevel%==0 (
  pythonw RunApp.pyw
  exit /b %errorlevel%
)

REM Fallback: py launcher en modo -w (sin consola)
py -3.11 -w RunApp.pyw
exit /b %errorlevel%
