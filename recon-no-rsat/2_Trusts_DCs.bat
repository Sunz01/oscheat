@echo off
setlocal enabledelayedexpansion
REM ============================================
REM 2_Trusts_DCs.bat - DC + Trust + Forest info via nltest
REM Uses nltest.exe (built-in on Windows)
REM Output: %TEMP%\norsat_dc_*.log
REM ============================================

set "OUT=%TEMP%"
set "DOM=lioncapital"

echo.
echo === DOMAIN CONTROLLERS ===
nltest.exe /dclist:%DOM%.local > "%OUT%\norsat_dc_list.log" 2>&1
type "%OUT%\norsat_dc_list.log"

echo.
echo === CURRENT LOGON DC ===
nltest.exe /dsgetdc:%DOM%.local > "%OUT%\norsat_dc_current.log" 2>&1
type "%OUT%\norsat_dc_current.log"

echo.
echo === ACTIVE SITE ===
nltest.exe /dsgetsite > "%OUT%\norsat_site.log" 2>&1
type "%OUT%\norsat_site.log"

echo.
echo === DOMAIN TRUSTS ===
nltest.exe /domain_trusts > "%OUT%\norsat_trusts.log" 2>&1
type "%OUT%\norsat_trusts.log"

echo.
echo === TEST TRUST TO DC (Verifies domain access) ===
nltest.exe /testtrust /domain:%DOM%.local > "%OUT%\norsat_trust_test.log" 2>&1
type "%OUT%\norsat_trust_test.log"

echo.
echo === WHO IS LOGGED IN LOCALLY ===
nltest.exe /whoami > "%OUT%\norsat_whoami.log" 2>&1
type "%OUT%\norsat_whoami.log"

echo.
echo === KDC (key distribution center) INFO ===
nltest.exe /dsgetdc:%DOM%.local /writable > "%OUT%\norsat_kdc.log" 2>&1

echo.
echo === DONE ===
dir "%OUT%\norsat_dc_*" "%OUT%\norsat_trust*" "%OUT%\norsat_site*" "%OUT%\norsat_who*" "%OUT%\norsat_kdc*"
pause
endlocal
