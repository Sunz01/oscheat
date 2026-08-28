@echo off
setlocal enabledelayedexpansion
REM ============================================
REM Run_All_NoRSAT.bat - Master runner
REM Uses ONLY built-in Windows tools, NO RSAT required
REM Tools: net.exe, nltest.exe, whoami.exe, certutil.exe,
REM         vaultcmd.exe, cmdkey.exe, klist.exe, powershell.exe (default),
REM         reg.exe, netsh.exe, findstr, find, type
REM ============================================

set "OUT=%TEMP%"
echo.
echo === SIGNED-BINARY RECON (NO RSAT REQUIRED) ===
echo Output: %OUT%\norsat_*.log
echo.

echo.
echo ================ 1. Users / Groups ================
call "1_UsersGroups.bat" <nul 2>nul

echo.
echo ================ 2. Trusts + DCs ================
call "2_Trusts_DCs.bat" <nul 2>nul

echo.
echo ================ 3. AD CS Discovery ================
call "3_ADCS_Discover.bat" <nul 2>nul

echo.
echo ================ 4. High-Value Recon ================
call "4_HighValue_Recon.bat" <nul 2>nul

echo.
echo ===========================================
echo    SUMMARY
echo ===========================================
echo.
echo --- Domain Admins (NetBIOS-compatible) ---
type "%OUT%\norsat_da.log" 2>nul
echo.
echo --- Domain Controllers ---
type "%OUT%\norsat_dc_list.log" 2>nul
echo.
echo --- Domain Trusts ---
type "%OUT%\norsat_trusts.log" 2>nul
echo.
echo --- CAs Found ---
type "%OUT%\norsat_adcs_cas.log" 2>nul
echo.
echo --- Stored Credentials ---
type "%OUT%\norsat_hv_creds.log" 2>nul
echo.
echo --- Autologon Cleartext (if any) ---
type "%OUT%\norsat_hv_autologon.log" 2>nul
echo.
echo ============================================
echo All logs in: %OUT%
echo ============================================
dir "%OUT%\norsat_*" 2>nul
pause
endlocal
