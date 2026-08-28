@echo off
setlocal enabledelayedexpansion
REM ============================================
REM  2_NetBuiltin_Recon.bat - Local + domain info via built-in net.exe
REM ============================================

set "OUT=%TEMP%"

echo.
echo === LOCAL IDENTITY ===
whoami.exe /all > "%OUT%\net_whoami.log" 2>&1
whoami.exe /groups > "%OUT%\net_whoami_groups.log" 2>&1
whoami.exe /priv > "%OUT%\net_whoami_priv.log" 2>&1

echo === LOCAL ADMINS ===
net.exe localgroup Administrators > "%OUT%\net_local_admins.log" 2>&1
net.exe localgroup "Remote Desktop Users" > "%OUT%\net_rdp_users.log" 2>&1
net.exe localgroup "Distributed COM Users" > "%OUT%\net_dcom_users.log" 2>&1

echo.
echo === DOMAIN ===
net.exe user /domain > "%OUT%\net_domain_users.log" 2>&1
net.exe group /domain > "%OUT%\net_domain_groups.log" 2>&1
net.exe accounts /domain > "%OUT%\net_domain_policy.log" 2>&1

echo.
echo === TRUSTS ===
nltest.exe /domain_trusts > "%OUT%\net_trusts.log" 2>&1
nltest.exe /dclist:lioncapital.local > "%OUT%\net_dcs.log" 2>&1

echo.
echo === SESSIONS ===
net.exe session > "%OUT%\net_sessions.log" 2>&1
net.exe use > "%OUT%\net_connections.log" 2>&1
net.exe share > "%OUT%\net_shares.log" 2>&1

echo.
echo === KERBEROS TICKETS (own session) ===
klist.exe tickets > "%OUT%\net_tickets.log" 2>&1

echo.
echo === Done. Files in %OUT% ===
dir "%OUT%\net_*.log"
pause
endlocal
