@echo off
setlocal enableextensions
cd /d "%~dp0"

REM Usar 'py -3' si está; si no, 'python'
set "PY=py -3"
%PY% --version >nul 2>&1 || set "PY=python"

echo.
echo ==============================
echo  Lanzando TER App (rapido)
echo  Carpeta: %cd%
echo ==============================
echo.

set "REQ=requirements.txt"
set "HASHFILE=.req.hash"
set "URL=http://localhost:8501"

REM --- calcular hash actual de requirements.txt ---
for /f "tokens=1" %%H in ('certutil -hashfile "%REQ%" MD5 ^| find /i /v "hash"') do set "CURR_HASH=%%H"

REM --- si no hay hash previo, instalamos ---
if not exist "%HASHFILE%" goto :INSTALL

for /f "usebackq delims=" %%A in ("%HASHFILE%") do set "PREV_HASH=%%A"
if /i "%CURR_HASH%"=="%PREV_HASH%" (
  echo [1/2] Requisitos sin cambios; omito pip install.
  goto :RUN
)

:INSTALL
echo [1/2] Instalando dependencias (perfil de usuario)...
%PY% -m pip install --user --disable-pip-version-check --upgrade-strategy only-if-needed -r "%REQ%"
if errorlevel 1 (
  echo.
  echo ERROR instalando dependencias (posible proxy/firewall).
  echo Si no teneis internet, cread "offline\wheels" con:
  echo    pip download -r requirements.txt -d offline\wheels
  echo y cambiad la linea pip por la variante --no-index/--find-links.
  echo.
  pause
  exit /b 1
)
> "%HASHFILE%" echo %CURR_HASH%

:RUN
echo.
echo [2/2] Iniciando servidor Streamlit en %URL%

REM Lanza el servidor en esta consola (bloquea hasta que cierres la app)
REM En paralelo, abre el navegador con un retardo de 5 segundos (para dar
REM tiempo a que el servidor quede escuchando).
start "" cmd /c "timeout /t 5 /nobreak >nul & start "" "%URL%""

%PY% -m streamlit run app.py ^
  --server.address localhost ^
  --server.port 8501 ^
  --server.headless false

echo.
echo (Si no abrio automaticamente, copia y pega en el navegador:)
echo   %URL%
echo.
pause
