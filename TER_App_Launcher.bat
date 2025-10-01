@echo off
setlocal
cd /d "%~dp0"

REM Detectar Python
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

REM Crear venv si no existe
if not exist ".venv" (
  echo Creando entorno virtual .venv ...
  %PY_EXE% -m venv .venv || (echo Error creando venv & pause & exit /b 1)
)

REM Activar venv e instalar deps si faltan
call ".venv\Scripts\activate"
%PY_EXE% -m pip install --upgrade pip wheel >nul

echo Comprobando dependencias...
%PY_EXE% - <<PYCODE
import importlib.util, sys
mods = ["streamlit","pandas","numpy","openpyxl","xlsxwriter","win32com"]
missing = [m for m in mods if importlib.util.find_spec(m) is None]
print("OK" if not missing else "MISSING:"+",".join(missing))
sys.exit(0 if not missing else 1)
PYCODE

if errorlevel 1 (
  echo Instalando dependencias (Internet)...
  pip install -r requirements.txt || (
    echo Error instalando desde Internet. Si la red esta capada, prepara paquete offline.
    pause & exit /b 1
  )
)

REM Forzar modo local/localhost
set STREAMLIT_BROWSER_GATHER_USAGE_STATS=false
set STREAMLIT_SERVER_ADDRESS=localhost
set STREAMLIT_SERVER_PORT=8501

REM Abrir navegador y lanzar en localhost
start "" http://localhost:8501
streamlit run app.py --server.address localhost --server.port 8501 --server.headless false
