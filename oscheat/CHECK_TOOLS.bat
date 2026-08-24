@echo off
echo ============================================================
echo  Checking what's available on this Windows machine
echo ============================================================
echo.
echo --- PowerShell ---
where powershell.exe
echo.

echo --- Python ---
where python
where py
echo.

echo --- Node.js ---
where node
echo.

echo --- C# Compiler (csc.exe) ---
if exist "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" (
    echo [FOUND] C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe
) else (
    echo [NOT FOUND] Framework v4.0.30319
)
if exist "C:\Windows\Microsoft.NET\Framework64\v3.5\csc.exe" (
    echo [FOUND] C:\Windows\Microsoft.NET\Framework64\v3.5\csc.exe
)
echo.

echo --- Other tools ---
where git
where wmic
where sc
where cscript
echo.

echo ============================================================
echo  Recommendation:
if exist "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" (
    echo  Use C# version. Run build_cs.bat to make oscheat.exe.
) else (
    if not "%python%" == "" (
        echo  Python is available! Run: python oscheat.py
    ) else (
        echo  C# compiler missing AND no Python.
        echo  Try: run_keep_open.bat (works if PowerShell -File works)
    )
)
echo ============================================================
echo.
pause
