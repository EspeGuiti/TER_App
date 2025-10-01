@echo off
setlocal
REM ===========================
REM Lanzador todo-en-uno (Windows)
REM - Crea venv .venv si no existe
REM - Instala requirements si faltan
REM - Arranca la app en http://localhost:8501
REM ===========================

cd /d "%~dp0"

REM 1) Comprobar Python
python --version >nul 2>&1
if errorlevel 1 (
  echo.
  echo ❌ No se encontro Python en PATH.
  echo Instala Python 3.11 (64-bit) desde Software Center o IT y vuelve a ejecutar.
  pause
  exit /b 1
)

REM 2) Crear venv si no existe
if not exist .venv (
  echo.
  echo ⏳ Creando entorno virtual .venv ...
  python -m venv .venv
  if errorlevel 1 (
    echo ❌ Error creando el entorno virtual.
    pause
    exit /b 1
  )
)

REM 3) Activar venv y actualizar pip
call .venv\Scripts\activate
python -m pip --version >nul 2>&1 || (python -m ensurepip)
python -m pip install --upgrade pip wheel >nul

REM 4) Instalar requirements solo si faltan (o si hay cambios)
echo.
echo ⏳ Comprobando dependencias...
pip install -r requirements.txt >nul
if errorlevel 1 (
  echo.
  echo ❌ No se pudieron instalar dependencias desde Internet.
  echo - Si estais tras proxy corporativo, probad:
  echo      set HTTP_PROXY=http://usuario:pass@proxy:puerto
  echo      set HTTPS_PROXY=%%HTTP_PROXY%%
  echo - Si no hay salida a Internet, pedid el paquete OFFLINE.
  pause
  exit /b 1
)

REM 5) Forzar puerto fijo y abrir navegador
set STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

echo.
echo ✅ Todo listo. Abriendo la app...
start "" http://localhost:8501

REM 6) Lanzar Streamlit
streamlit run app.py --server.port 8501 --server.headless false
