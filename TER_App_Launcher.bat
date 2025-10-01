@echo off
setlocal

REM Ir a la carpeta del script
cd /d "%~dp0"

REM ----- Seleccionar ejecutable de Python (python o py -3.11) -----
set "PY_EXE=python"
%PY_EXE% --version >nul 2>&1
if errorlevel 1 (
  py -3.11 --version >nul 2>&1 && set "PY_EXE=py -3.11"
)
%PY_EXE% --version >nul 2>&1 || (
  echo No se encontro Python en PATH. Instala Python 3.11 (64-bit) y vuelve a ejecutar.
  pause
  exit /b 1
)

REM ----- Crear venv si no existe -----
if not exist ".venv" (
  echo Creando entorno virtual .venv ...
  %PY_EXE% -m venv .venv || goto :error
)

REM ----- Activar venv y actualizar pip -----
call ".venv\Scripts\activate" || goto :error
%PY_EXE% -m pip install --upgrade pip wheel || goto :error

REM ----- Instalar dependencias -----
echo Instalando dependencias (requirements.txt) ...
pip install -r requirements.txt || goto :error

REM ----- Abrir navegador y lanzar Streamlit -----
start "" http://localhost:8501
streamlit run app.py --server.port 8501 --server.headless false
exit /b 0

:error
echo.
echo Hubo un error durante la instalacion o el lanzamiento.
echo Deja esta ventana abierta y copia el mensaje de arriba para revisarlo.
pause
exit /b 1
