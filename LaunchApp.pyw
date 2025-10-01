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
    vpy = os.path.join(venv_dir, "Scripts", "python.exe")
    spath = os.path.join(venv_dir, "Scripts")

    # 1) Create venv if missing
    if not os.path.exists(vpy):
        log("Creating venv...")
        run(py_cmd + ["-m", "venv", ".venv"])

    env = os.environ.copy()
    env["PATH"] = spath + os.pathsep + env.get("PATH", "")

    # 2) Ensure pip
    log("Ensuring pip...")
    try:
        run([vpy, "-m", "pip", "--version"], env=env, check=True)
    except Exception:
        run([vpy, "-m", "ensurepip"], env=env, check=False)
        run([vpy, "-m", "pip", "install", "--upgrade", "pip", "wheel"], env=env, check=True)
    else:
        run([vpy, "-m", "pip", "install", "--upgrade", "pip", "wheel"], env=env, check=True)

    # 3) Check imports; install only if missing
    code = r"""
import importlib.util, sys
mods = ["streamlit","pandas","numpy","openpyxl","xlsxwriter","win32com"]
missing = [m for m in mods if importlib.util.find_spec(m) is None]
print("OK" if not missing else "MISSING:"+",".join(missing))
sys.exit(0 if not missing else 1)
"""
    chk = subprocess.run([vpy, "-c", code], env=env, capture_output=True, text=True)
    need_install = (chk.returncode != 0)

    if need_install:
        wheels_dir = os.path.join(HERE, "offline", "wheels")
        req_file = os.path.join(HERE, "requirements.txt")

        if os.path.isdir(wheels_dir) and os.listdir(wheels_dir):
            # OFFLINE first (if wheels exist)
            log("Installing requirements OFFLINE...")
            run([vpy, "-m", "pip", "install", "--no-index",
                 f"--find-links={wheels_dir}", "-r", req_file], env=env, check=True)
        else:
            # ONLINE
            log("Installing requirements ONLINE...")
            try:
                run([vpy, "-m", "pip", "install", "-r", req_file], env=env, check=True)
            except Exception as e:
                # If online fails and we have empty/no wheels: show error
                errbox("Install failed",
                       "Could not install requirements online. If internet is blocked,\n"
                       "add wheels under ./offline/wheels and relaunch.\nSee launch.log.")
                log(traceback.format_exc())
                return

    # 4) Launch Streamlit on localhost:8501
    url = "http://localhost:8501"
    webbrowser.open(url, new=1)
    log("Starting Streamlit...")
    # Use module form to ensure correct entry
    p = subprocess.Popen([vpy, "-m", "streamlit", "run", "app.py",
                          "--server.address", "localhost",
                          "--server.port", "8501",
                          "--server.headless", "false"],
                         cwd=HERE, env=env,
                         stdout=open(LOG, "a", encoding="utf-8"),
                         stderr=open(LOG, "a", encoding="utf-8"))
    # Optional: brief toast that we are launching
    msgbox("Launching", "The app is launching at http://localhost:8501")
    # Do not wait; exit launcher and leave Streamlit running
    time.sleep(1)

if __name__ == "__main__":
    try:
        main()
    except Exception:
        errbox("Unexpected error", "See launch.log for details.")
        log(traceback.format_exc())
