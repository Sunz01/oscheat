@echo off
setlocal enabledelayedexpansion
REM ============================================
REM  Run_All_Signed.bat - Pure signed-binary recon
REM  Tools used (ALL Microsoft-signed, all expected by EDR):
REM    dsquery.exe   dsget.exe   net.exe   nltest.exe
REM    whoami.exe    klist.exe   wmic.exe   findstr
REM  Output: %TEMP%\*_*.log and *_*.txt
REM ============================================

set "OUT=%TEMP%"
echo.
echo === SIGNED-BINARY RECON (zero detection) ===
echo Output: %OUT%
echo.

call "1_DSQuery_Recon.bat" <nul 2>nul
echo.
call "2_NetBuiltin_Recon.bat" <nul 2>nul
echo.
call "3_WMIC_Recon.bat" <nul 2>nul

echo.
echo === SUMMARY ===
echo --- High-value AD accounts ---
type "%OUT%\dsq_priv_users.txt" 2>nul
echo.
echo --- Domain Admins ---
type "%OUT%\dsq_da.txt" 2>nul
echo.
echo --- Service Accounts ---
type "%OUT%\dsq_svc_accts.txt" 2>nul
echo.
echo --- Local admins / RDP users ---
type "%OUT%\net_local_admins.log" 2>nul
type "%OUT%\net_rdp_users.log" 2>nul
echo.
echo --- Unquoted service paths ---
type "%OUT%\wmic_unquoted.log" 2>nul
echo.
echo === ALL LOGS IN %OUT% ===
dir "%OUT%\dsq_*" "%OUT%\net_*" "%OUT%\wmic_*" 2>nul
pause
endlocal
