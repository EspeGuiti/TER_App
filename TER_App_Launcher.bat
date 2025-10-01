@echo off
setlocal

REM ===========================
REM Lanzador simple estilo "funciona o funciona"
REM - Crea .venv si no existe
REM - Instala requirements SOLO si faltan
REM - Si falla la instalacion online y hay offline\wheels, usa modo offline
REM - Lanza Streamlit
REM ===========================

cd /d "%~dp0"

REM 1) Detectar Python (python o py -3.11)
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

REM 2) Crear venv si no existe
if not exist ".venv" (
  echo Creando entorno virtual .venv ...
  %PY_EXE% -m venv .venv
  if errorlevel 1 (
    echo Error creando el entorno virtual.
    pause
    exit /b 1
  )
)

REM 3) Activar venv y actualizar pip wheel
call ".venv\Scripts\activate"
%PY_EXE% -m pip install --upgrade pip wheel >nul 2>&1

REM 4) Comprobar si faltan dependencias (sin reinstalar si ya estan)
echo Comprobando dependencias...
%PY_EXE% - <<PYCODE
import importlib.util, sys
reqs = [
    ("streamlit","streamlit"),
    ("pandas","pandas"),
    ("numpy","numpy"),
    ("openpyxl","openpyxl"),
    ("xlsxwriter","xlsxwriter"),
    ("win32com.client","win32com"),  # pywin32
]
missing = []
for mod_display, mod_probe in reqs:
    if mod_probe == "win32com":
        ok = importlib.util.find_spec("win32com") is not None
    else:
        ok = importlib.util.find_spec(mod_probe) is not None
    if not ok:
        missing.append(mod_display)
if missing:
    print("MISSING:" + ",".join(missing))
    sys.exit(1)
else:
    print("OK")
    sys.exit(0)
PYCODE

if errorlevel 1 (
  echo Faltan paquetes. Instalando desde Internet...
  pip install -r requirements.txt
  if errorlevel 1 (
    echo Fallo instalando desde Internet.
    if exist "offline\wheels" (
      echo Intentando instalacion OFFLINE desde .\offline\wheels ...
      pip install --no-index --find-links=offline\wheels -r requirements.txt
      if errorlevel 1 (
        echo ERROR: Tampoco se pudo instalar offline. Revisa la carpeta offline\wheels.
        pause
        exit /b 1
      )
    ) else (
      echo No hay carpeta offline\wheels para modo offline.
      echo Si estais tras firewall, pedid el ZIP offline con wheels.
      pause
      exit /b 1
    )
  )
) else (
  echo Dependencias OK. (No se reinstala nada)
)

REM 5) Abrir navegador y lanzar Streamlit
set STREAMLIT_BROWSER_GATHER_USAGE_STATS=false
start "" http://localhost:8501
streamlit run app.py --server.port 8501 --server.headless false

