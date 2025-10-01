# RunApp.pyw  (AUTO-BUILD vendor + launch Streamlit sin consola)
# Guarda este archivo junto a app.py y requirements.txt
import os, sys, subprocess, time, webbrowser, tkinter as tk
from tkinter import messagebox

HERE = os.path.abspath(os.path.dirname(__file__))
VENDOR = os.path.join(HERE, "vendor")
LOG = os.path.join(HERE, "run_app.log")
REQ = os.path.join(HERE, "requirements.txt")

def log(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {msg}\n")

def msgbox(title, text):
    try:
        root = tk.Tk(); root.withdraw()
        messagebox.showinfo(title, text)
        root.destroy()
    except Exception:
        pass

def errbox(title, text):
    try:
        root = tk.Tk(); root.withdraw()
        messagebox.showerror(title, text)
        root.destroy()
    except Exception:
        pass

def run(cmd, env=None, cwd=None, check=True):
    log("$ " + " ".join(cmd))
    r = subprocess.run(cmd, env=env, cwd=cwd, capture_output=True, text=True, shell=False)
    log(r.stdout); log(r.stderr)
    if check and r.returncode != 0:
        raise RuntimeError(f"Command failed (exit {r.returncode}): {' '.join(cmd)}")
    return r

def ensure_vendor(py_exe):
    """Si no existe vendor, lo construye con pip --target vendor -r requirements.txt"""
    if os.path.isdir(VENDOR) and os.listdir(VENDOR):
        return
    if not os.path.exists(REQ):
        errbox("Falta requirements.txt", "No se encontró requirements.txt junto a RunApp.pyw")
        raise SystemExit(1)
    os.makedirs(VENDOR, exist_ok=True)
    msgbox("Preparando librerías", "Se instalarán las librerías en la carpeta local 'vendor'.")
    # Actualiza pip/wheel (silencioso) y construye vendor
    run([py_exe, "-m", "pip", "install", "--upgrade", "pip", "wheel"], check=False)
    run([py_exe, "-m", "pip", "install", "--target", VENDOR, "-r", REQ])

def main():
    open(LOG, "w", encoding="utf-8").write("=== RunApp (auto-build vendor) ===\n")

    # 1) Detectar Python "sin consola" si es posible
    py = sys.executable or "python"
    # Si el .pyw lo lanza python.exe, vale; si lo lanza pythonw.exe, mejor
    # No forzamos nada aquí; el .cmd que te dejo intenta pythonw primero.

    # 2) Construir vendor si no existe
    ensure_vendor(py)

    # 3) Ajustar entorno para usar vendor sin venv/instalación
    env = os.environ.copy()
    env["PYTHONPATH"] = VENDOR + os.pathsep + env.get("PYTHONPATH", "")
    env["STREAMLIT_BROWSER_GATHER_USAGE_STATS"] = "false"

    # 4) Abrir navegador y lanzar Streamlit
    url = "http://localhost:8501"
    try:
        webbrowser.open(url, new=1)
    except Exception:
        pass

    cmd = [py, "-m", "streamlit", "run", "app.py",
           "--server.address", "localhost",
           "--server.port", "8501",
           "--server.headless", "false"]
    log("Launching Streamlit...")
    with open(LOG, "a", encoding="utf-8") as f:
        subprocess.Popen(cmd, cwd=HERE, env=env, stdout=f, stderr=f)

    msgbox("Abriendo", "La app se está abriendo en http://localhost:8501")
    time.sleep(1)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log(f"ERROR: {e}")
        errbox("Error", f"Consulta run_app.log para más detalle.\n\n{e}")
