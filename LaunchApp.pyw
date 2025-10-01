# LaunchApp.pyw
# ASCII-only. Creates venv, installs deps (offline if wheels found), runs Streamlit on localhost.
import os, sys, subprocess, shutil, time, webbrowser, traceback

HERE = os.path.abspath(os.path.dirname(__file__))
LOG = os.path.join(HERE, "launch.log")

def log(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {msg}\n")

def msgbox(title, text):
    # GUI message without console (std lib)
    try:
        import tkinter as tk
        from tkinter import messagebox
        root = tk.Tk(); root.withdraw()
        messagebox.showinfo(title, text)
        root.destroy()
    except Exception:
        # fallback: write to log
        log(f"[MSGBOX:{title}] {text}")

def errbox(title, text):
    try:
        import tkinter as tk
        from tkinter import messagebox
        root = tk.Tk(); root.withdraw()
        messagebox.showerror(title, text)
        root.destroy()
    except Exception:
        log(f"[ERRBOX:{title}] {text}")

def find_system_python():
    # Try current pythonw/python; fallback to 'py -3.11'
    exe = sys.executable or ""
    if exe and os.path.exists(exe):
        return exe
    # Try common names
    for cand in ("pythonw.exe", "python.exe"):
        p = shutil.which(cand)
        if p: return p
    # Try py launcher (silent check)
    try:
        out = subprocess.run(["py", "-3.11", "--version"], capture_output=True)
        if out.returncode == 0:
            return "py -3.11"
    except Exception:
        pass
    return None

def run(cmd, env=None, cwd=None, check=True):
    log(f"$ {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    r = subprocess.run(cmd, env=env, cwd=cwd, capture_output=True, text=True, shell=False)
    open(LOG, "a", encoding="utf-8").write(r.stdout)
    open(LOG, "a", encoding="utf-8").write(r.stderr)
    if check and r.returncode != 0:
        raise RuntimeError(f"Command failed: {cmd}\nExit {r.returncode}")
    return r

def main():
    open(LOG, "w", encoding="utf-8").write("=== TER App Launch ===\n")
    py = find_system_python()
    if not py:
        errbox("Python not found", "Python 3.11 (64-bit) not found in PATH. Please install it.")
        return

    # If launcher is "py -3.11", we cannot pass it directly to subprocess with shell=False
    # So if py is a string with space, split it:
    py_cmd = py.split() if isinstance(py, str) else [py]

    venv_dir = os.path.join(HERE, ".venv")
    vpy = os.path.join(venv_dir_
