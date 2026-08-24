@echo off
REM ============================================================
REM OSCheat launcher - V2 (fixed)
REM Runs oscheat.ps1 in PowerShell with execution policy bypass.
REM Works even when PowerShell execution policy is locked.
REM ============================================================

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%oscheat.ps1"

REM Locate powershell.exe using full path (avoids any PATH issues)
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
echo  OSCheat Launcher v2
echo  Running: %PS_SCRIPT%
echo  Using:   %PS_EXE%
echo ============================================================
echo.

REM Method 1 (preferred): direct execution with bypass
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -NonInteractive -File "%PS_SCRIPT%"

REM If that fails, this catches the error
if errorlevel 1 (
    echo.
    echo ============================================================
    echo  Direct run failed (error %errorlevel%). Trying alternative method...
    echo ============================================================
    echo.

    REM Method 2: read script as command via stdin
    type "%PS_SCRIPT%" | "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -NonInteractive -Command -
)

endlocal
