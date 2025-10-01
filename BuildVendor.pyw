# BuildVendor.pyw
# Crea carpeta ./vendor con todas las dependencias de requirements.txt (sin consola).
import os, sys, subprocess, shutil, time, tkinter as tk
from tkinter import messagebox, filedialog

HERE = os.path.abspath(os.path.dirname(__file__))
LOG = os.path.join(HERE, "build_vendor.log")
VENDOR = os.path.join(HERE, "vendor")
REQ = os.path.join(HERE, "requirements.txt")

def log(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {msg}\n")

def run(cmd, env=None):
    log(f"$ {' '.join(cmd)}")
    r = subprocess.run(cmd, capture_output=True, text=True, env=env, cwd=HERE)
    log(r.stdout); log(r.stderr)
    if r.returncode != 0:
        raise RuntimeError(f"Command failed: {cmd} (exit {r.returncode})")
    return r

def main():
    open(LOG, "w", encoding="utf-8").write("=== Build vendor ===\n")
    if not os.path.exists(REQ):
        messagebox.showerror("Error", "No se encontró requirements.txt")
        return
    # Python actual
    py = sys.executable
    if not py or not os.path.exists(py):
        messagebox.showerror("Error", "Python no encontrado (sys.executable).")
        return
    # Limpiar/crear vendor
    if os.path.isdir(VENDOR):
        if not messagebox.askyesno("Confirmar", "La carpeta 'vendor' ya existe. ¿Reemplazarla?"):
            return
        shutil.rmtree(VENDOR, ignore_errors=True)
    os.makedirs(VENDOR, exist_ok=True)
    # Asegurar pip/wheel
    run([py, "-m", "pip", "install", "--upgrade", "pip", "wheel"])
    # Instalar en vendor (sin tocar el sistema)
    run([py, "-m", "pip", "install", "--target", VENDOR, "-r", REQ])
    messagebox.showinfo("Éxito", "Carpeta 'vendor' creada con todas las dependencias.\nYa puedes crear el ZIP portable.")

if __name__ == "__main__":
    try:
        root = tk.Tk(); root.withdraw()
        main()
    except Exception as e:
        log(f"ERROR: {e}")
        messagebox.showerror("Fallo", f"Revisa build_vendor.log\n\n{e}")
