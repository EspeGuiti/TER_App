@echo off
setlocal

rem ===========================
rem Simple launcher (ASCII only)
rem - creates .venv if needed
rem - installs requirements if missing
rem - tries online first; if fail and offline\wheels exists, installs offline
rem - logs all output to launch.log
rem ===========================

cd /d "%~dp0"
set "LOGFILE=%~dp0launch.log"
echo. > "%LOGFILE%"
echo ===== TER App Launch ===== >> "%LOGFILE%"
echo %DATE% %TIME% >> "%LOGFILE%"

rem 1) detect python (python or py -3.11)
set "PY_EXE=python"
%PY_EXE% --version >>"%LOGFILE%" 2>&1
if errorlevel 1 (
  py -3.11 --version >>"%LOGFILE%" 2>&1 && set "PY_EXE=py -3.11"
)
%PY_EXE% --version >>"%LOGFILE%" 2>&1
if errorlevel 1 (
  echo Python not found in PATH. Install Python 3.11 64-bit. >>"%LOGFILE%"
  echo Python not found in PATH. Install Python 3.11 64-bit.
  pause
  exit /b 1
)

rem 2) create venv if missing
if not exist ".venv" (
  echo Creating .venv ... >>"%LOGFILE%"
  %PY_EXE% -m venv .venv >>"%LOGFILE%" 2>&1
  if errorlevel 1 (
    echo Error creating venv (see launch.log). >>"%LOGFILE%"
    echo Error creating venv (see launch.log).
    pause
    exit /b 1
  )
)

rem 3) activate venv and upgrade pip
call ".venv\Scripts\activate" >>"%LOGFILE%" 2>&1
%PY_EXE% -m pip install --upgrade pip wheel >>"%LOGFILE%" 2>&1

rem 4) check imports (only install if missing)
echo Checking dependencies... >>"%LOGFILE%"
%PY_EXE% - <<PYCODE >>"%LOGFILE%" 2>&1
import importlib.util, sys
mods = ["streamlit","pandas","numpy","openpyxl","xlsxwriter","win32com"]
missing = [m for m in mods if importlib.util.find_spec(m) is None]
print("OK" if not missing else "MISSING:"+",".join(missing))
sys.exit(0 if not missing else 1)
PYCODE

if errorlevel 1 (
  echo Installing requirements online... >>"%LOGFILE%"
  pip install -r requirements.txt >>"%LOGFILE%" 2>&1
  if errorlevel 1 (
    echo Online install failed. >>"%LOGFILE%"
    if exist "offline\wheels" (
      echo Trying offline install from offline\wheels ... >>"%LOGFILE%"
      pip install --no-index --find-links=offline\wheels -r requirements.txt >>"%LOGFILE%" 2>&1
      if errorlevel 1 (
        echo Offline install failed. See launch.log. >>"%LOGFILE%"
        echo Installation failed (online and offline). See launch.log for details.
        pause
        exit /b 1
      )
    ) else (
      echo No offline\wheels folder found. >>"%LOGFILE%"
      echo Installation failed and no offline package found. See launch.log.
      pause
      exit /b 1
    )
  )
) else (
  echo Dependencies OK. >>"%LOGFILE%"
)

rem 5) force localhost and fixed port
set STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

rem 6) start browser and run streamlit
start "" http://localhost:8501
streamlit run app.py --server.address localhost --server.port 8501 --server.headless false >>"%LOGFILE%" 2>&1
exit /b 0

