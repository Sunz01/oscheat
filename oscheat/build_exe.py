#!/usr/bin/env python3
"""
Build OSCheat.py into a Windows .exe using PyInstaller
Run this on a WINDOWS machine where Python 3.x is installed.

Usage:
    pip install pyinstaller
    python build_exe.py
"""

import subprocess
import shutil
import os
import sys
from pathlib import Path

HERE = Path(__file__).parent
EXE_NAME = "oscheat"

def main():
    # Clean old build artifacts
    for d in ["build", "dist", "__pycache__"]:
        p = HERE / d
        if p.exists():
            shutil.rmtree(p)
    
    # Build command
    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--onefile",                    # single .exe
        "--noconfirm",                  # don't prompt on overwrite
        f"--name={EXE_NAME}",           # output name = oscheat.exe
        "--clean",                      # clean cache before build
        str(HERE / "oscheat.py"),       # script to compile
    ]
    
    print("Building oscheat.exe with PyInstaller...")
    print(f"Command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, check=True, cwd=str(HERE))
        print("\n✓ Build successful!")
        exe_path = HERE / "dist" / f"{EXE_NAME}.exe"
        if exe_path.exists():
            size_mb = exe_path.stat().st_size / (1024 * 1024)
            print(f"Output: {exe_path} ({size_mb:.1f} MB)")
            print(f"\nTo use: copy oscheat.exe to target and double-click or run from cmd")
    except subprocess.CalledProcessError as e:
        print(f"\n✗ Build failed with exit code {e.returncode}")
        sys.exit(1)
    except FileNotFoundError:
        print("\n✗ PyInstaller not found. Install with:")
        print("    pip install pyinstaller")
        sys.exit(1)

if __name__ == "__main__":
    main()
