@echo off
setlocal enableextensions
cd /d "%~dp0"
set LOG=run_app.log
echo === TER App launcher (verbose) === > "%LOG%"

REM ---- helper "tee" (por si tu Windows no tiene tee) ----
goto :teeSkip
:tee
setlocal enabledelayedexpansion
set "LINE="
set /p LINE=
echo !LINE!
>>"%LOG%" echo !LINE!
exit /b
:teeSkip

echo [1/5] Detectando Python... | tee -a "%LOG%"

REM Intentos por orden: pythonw, python, py -3.11, py -3.10
set "PYEXE="
where pythonw >nul 2>&1 && for /f "delims=" %%P in ('where pythonw') do set "PYEXE=%%P"
if not defined PYEXE (
  where python >nul 2>&1 && for /f "delims=" %%P in ('where python') do set "PYEXE=%%P"
)
if not defined PYEXE (
  for /f "delims=" %%P in ('where py 2^>nul') do set "PYLAUNCH=%%P"
  if defined PYLAUNCH (
    "%PYLAUNCH%" -3.11 --version >nul 2>&1 && set "PYEXE=%PYLAUNCH% -3.11"
    if not defined PYEXE "%PYLAUNCH%" -3.10 --version >nul 2>&1 && set "PYEXE=%PYLAUNCH% -3.10"
  )
)

if not defined PYEXE (
  echo ERROR: Python no encontrado. Instala Python 3.10/3.11/3.12 y vuelve a ejecutar. | tee -a "%LOG%"
  echo Pulsa una tecla para cerrar...
  pause >nul
  exit /b 1
)

echo Usando: %PYEXE% | tee -a "%LOG%"
for /f "tokens=* delims=" %%V in ('%PYEXE% --version 2^>^&1') do echo %%V | tee -a "%LOG%"

echo. | tee -a "%LOG%"
echo [2/5] Comprobando carpeta vendor... | tee -a "%LOG%"
set "VENDOR=%cd%\vendor"
if not exist "%VENDOR%" mkdir "%VENDOR%"

REM ¿Vendor vacio?
dir /b "%VENDOR%" >nul 2>&1
if errorlevel 1 (
  echo vendor vacio: se instalaran dependencias. | tee -a "%LOG%"
  echo Actualizando pip/wheel... | tee -a "%LOG%"
  %PYEXE% -m pip install --upgrade pip wheel >> "%LOG%" 2>&1

  if exist "%cd%\offline\wheels" (
    echo Instalacion OFFLINE desde offline\wheels ... | tee -a "%LOG%"
    %PYEXE% -m pip install --no-index --find-links="%cd%\offline\wheels" --target "%VENDOR%" -r requirements.txt >> "%LOG%" 2>&1
  ) else (
    echo Instalacion ONLINE (PyPI) ... | tee -a "%LOG%"
    %PYEXE% -m pip install --target "%VENDOR%" -r requirements.txt >> "%LOG%" 2>&1
  )

  if errorlevel 1 (
    echo ERROR instalando dependencias. Revisa run_app.log. | tee -a "%LOG%"
    echo Si no hay internet, coloca los .whl en offline\wheels y vuelve a ejecutar. | tee -a "%LOG%"
    echo Pulsa una tecla para cerrar...
    pause >nul
    exit /b 2
  )
) else (
  echo vendor ya presente. | tee -a "%LOG%"
)

echo. | tee -a "%LOG%"
echo [3/5] Ajustando entorno (PYTHONPATH=vendor) ... | tee -a "%LOG%"
set "PYTHONPATH=%VENDOR%;%PYTHONPATH%"
set STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

echo [4/5] Abriendo navegador en http://localhost:8501 ... | tee -a "%LOG%"
start "" "http://localhost:8501"

echo [5/5] Lanzando Streamlit ... | tee -a "%LOG%"
echo Comando: %PYEXE% -m streamlit run app.py --server.address localhost --server.port 8501 --server.headless false | tee -a "%LOG%"
start "" %PYEXE% -m streamlit run app.py --server.address localhost --server.port 8501 --server.headless false

echo.
echo Si la app no abre, revisa run_app.log. Esta ventana se cerrara en 5s...
timeout /t 5 >nul
exit /b 0
