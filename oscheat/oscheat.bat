@echo off
REM ============================================================
REM OSCheat launcher - V3 (CMD-window-stays-open fix)
REM Uses full path to powershell and keeps cmd open after run.
REM ============================================================

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%oscheat.ps1"

REM Locate powershell.exe with full path (resolves any PATH issues)
if exist "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_EXE=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
) else (
    set "PS_EXE=powershell.exe"
)

if not exist "%PS_SCRIPT%" (
    echo.
    echo ERROR: oscheat.ps1 not found in %SCRIPT_DIR%
    echo Please make sure both oscheat.bat and oscheat.ps1 are in the same directory.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  OSCheat Launcher v3
echo  Script:   %PS_SCRIPT%
echo  PowerShell: %PS_EXE%
echo ============================================================
echo.

REM Run PowerShell with bypass. After it exits, pause so the cmd window stays open.
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -NonInteractive -File "%PS_SCRIPT%"
set "PS_ERROR=%errorlevel%"

echo.
echo ============================================================
echo  OSCheat finished. Exit code: %PS_ERROR%
echo ============================================================
echo.
pause
endlocal
