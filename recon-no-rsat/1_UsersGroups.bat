@echo off
setlocal enabledelayedexpansion
REM ============================================
REM 1_UsersGroups.bat - Domain users/groups via built-in tools
REM NO dsquery needed - uses net.exe only
REM Output: %TEMP%\norsat_users.log
REM ============================================

set "OUT=%TEMP%"

echo.
echo === ALL DOMAIN USERS ===
net.exe user /domain > "%OUT%\norsat_users.log" 2>&1
type "%OUT%\norsat_users.log"

echo.
echo === USER COUNT ===
find /c "The command completed successfully" < "%OUT%\norsat_users.log" > "%OUT%\norsat_count.log" 2>&1

echo.
echo === ALL DOMAIN GROUPS ===
net.exe group /domain > "%OUT%\norsat_groups.log" 2>&1
type "%OUT%\norsat_groups.log"

echo.
echo === MEMBERS OF SPECIFIC GROUPS (Domain Admins) ===
net.exe group "Domain Admins" /domain > "%OUT%\norsat_da.log" 2>&1
type "%OUT%\norsat_da.log"

echo.
echo --- Enterprise Admins ---
net.exe group "Enterprise Admins" /domain > "%OUT%\norsat_ea.log" 2>&1
type "%OUT%\norsat_ea.log"

echo --- Schema Admins ---
net.exe group "Schema Admins" /domain > "%OUT%\norsat_schema.log" 2>&1
type "%OUT%\norsat_schema.log"

echo --- Account Operators ---
net.exe group "Account Operators" /domain > "%OUT%\norsat_acctops.log" 2>&1
type "%OUT%\norsat_acctops.log"

echo --- Backup Operators ---
net.exe group "Backup Operators" /domain > "%OUT%\norsat_backup.log" 2>&1
type "%OUT%\norsat_backup.log"

echo --- Server Operators ---
net.exe group "Server Operators" /domain > "%OUT%\norsat_srvops.log" 2>&1
type "%OUT%\norsat_srvops.log"

echo --- Print Operators ---
net.exe group "Print Operators" /domain > "%OUT%\norsat_printops.log" 2>&1
type "%OUT%\norsat_printops.log"

echo --- DCOM Users ---
net.exe localgroup "Distributed COM Users" > "%OUT%\norsat_dcom_local.log" 2>&1
type "%OUT%\norsat_dcom_local.log"

echo.
echo === COMPUTERS (via net view) ===
net.exe view > "%OUT%\norsat_view.log" 2>&1
type "%OUT%\norsat_view.log"

echo.
echo === DONE ===
dir "%OUT%\norsat_*"
pause
endlocal
