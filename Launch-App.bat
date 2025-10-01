@echo off
setlocal enableextensions
cd /d "%~dp0"

REM -------- 0) Elegir Python (py o python) --------
set "PY=py -3"
%PY% --version >nul 2>&1 || set "PY=python"

echo.
echo ============================================
echo   Lanzando TER App (modo sencillo)
echo   Carpeta: %cd%
echo ============================================
echo.

REM -------- 1) Instalar/validar dependencias --------
echo [1/2] Instalando dependencias (perfil de usuario)...
%PY% -m pip install --user --disable-pip-version-check -r requirements.txt
if errorlevel 1 (
  echo.
  echo   * Instalacion ONLINE fallo (posible proxy/firewall).
  if exist "offline\wheels" (
    echo   * Intentando modo OFFLINE desde offline\wheels ...
    %PY% -m pip install --user --no-index --find-links="offline\wheels" -r requirements.txt
    if errorlevel 1 (
      echo.
      echo ERROR: Tampoco se pudo instalar desde offline\wheels.
      echo       Revisa que haya .whl compatibles en esa carpeta.
      echo.
      pause
      exit /b 2
    )
  ) else (
    echo   * No hay carpeta offline\wheels con ruedas locales.
    echo     (Si no teneis internet, prepara esa carpeta con: 
    echo      pip download -r requirements.txt -d offline\wheels)
    echo.
    pause
    exit /b 1
  )
)

REM -------- 2) Lanzar Streamlit --------
echo.
echo [2/2] Abriendo la aplicacion en http://localhost:8501
start "" "http://localhost:8501"

%PY% -m streamlit run app.py ^
  --server.address localhost ^
  --server.port 8501 ^
  --server.headless false

echo.
echo (Si no abrio automaticamente, abre manualmente http://localhost:8501)
echo.
pause
