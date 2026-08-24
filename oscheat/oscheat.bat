@echo off
REM ============================================================
REM OSCheat launcher (BAT version)
REM Bypasses PowerShell execution policy by streaming content
REM through stdin (which policies DO NOT block).
REM ============================================================

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%oscheat.ps1"

if not exist "%PS_SCRIPT%" (
    echo ERROR: oscheat.ps1 not found in %SCRIPT_DIR%
    echo Please make sure both oscheat.bat and oscheat.ps1 are in the same directory.
    pause
    exit /b 1
)

echo OSCheat launcher - running oscheat.ps1...
echo.
echo Press any key to start (or Ctrl+C to abort)...
pause >nul

REM Stream the .ps1 over stdin to bypass the execution policy.
REM Cmd.exe -> powershell.exe -> reads from pipe (Bypass applies)
type "%PS_SCRIPT%" | powershell -ExecutionPolicy Bypass -NoProfile -NonInteractive -File -

endlocal
