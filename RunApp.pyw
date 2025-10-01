# RunApp.pyw
# Lanza la app usando vendor/ sin pip ni venv (no abre consola).
import os, sys, subprocess, time, webbrowser, tkinter as tk
from tkinter import messagebox

HERE = os.path.abspath(os.path.dirname(__file__))
VENDOR = os.path.join(HERE, "vendor")
LOG = os.path.join(HERE, "run_app.log")

def log(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {msg}\n")

def errbox(title, text):
    try:
        root = tk.Tk(); root.withdraw()
        messagebox.showerror(title, text)
        root.destroy()
    except: pass

def main():
    open(LOG, "w", encoding="utf-8").write("=== RunApp ===\n")
    # Python actual (pythonw.exe idealmente)
    py = sys.executable or "python"
    # Verificar vendor
    if not (os.path.isdir(VENDOR) and os.listdir(VENDOR)):
        errbox("Falta vendor", "No se encontró la carpeta 'vendor' con las librerías.\n"
                               "Pide el ZIP portable correcto o genera vendor con BuildVendor.pyw.")
        return
    env = os.environ.copy()
    # Añadir vendor al sys.path
    env["PYTHONPATH"] = VENDOR + os.pathsep + env.get("PYTHONPATH", "")
    env["STREAMLIT_BROWSER_GATHER_USAGE_STATS"] = "false"
    # Abrir navegador antes, por políticas
    url = "http://localhost:8501"
    try:
        webbrowser.open(url, new=1)
    except Exception: pass
    # Ejecutar streamlit desde vendor
    cmd = [py, "-m", "streamlit", "run", "app.py",
           "--server.address", "localhost",
           "--server.port", "8501",
           "--server.headless", "false"]
    log(f"$ {' '.join(cmd)}")
    with open(LOG, "a", encoding="utf-8") as f:
        p = subprocess.Popen(cmd, cwd=HERE, env=env, stdout=f, stderr=f)
    # Pequeño aviso
    try:
        root = tk.Tk(); root.withdraw()
        messagebox.showinfo("Abriendo", "La app se está abriendo en http://localhost:8501")
        root.destroy()
    except Exception: pass
    time.sleep(1)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log(f"ERROR: {e}")
        errbox("Error", "Revisa run_app.log")
