@echo off
setlocal enabledelayedexpansion
REM ============================================
REM  3_WMIC_Recon.bat - Host info via wmic.exe (signed) only
REM ============================================

set "OUT=%TEMP%"

echo.
echo === LOCAL SYSTEM ===
wmic.exe computersystem get Name,Domain,DomainRole,Manufacturer,Model,SystemType /format:list > "%OUT%\wmic_system.log" 2>&1
wmic.exe os get Caption,Version,BuildNumber,OSArchitecture,InstallDate,LastBootUpTime /format:list > "%OUT%\wmic_os.log" 2>&1
wmic.exe cpu get Name,NumberOfCores,NumberOfLogicalProcessors /format:list > "%OUT%\wmic_cpu.log" 2>&1
wmic.exe csproduct get Name,Vendor,Version,UUID /format:list > "%OUT%\wmic_product.log" 2>&1

echo.
echo === LOCAL USERS + GROUPS ===
wmic.exe useraccount get Name,SID,PasswordRequired,PasswordExpires,Disabled,FullName /format:list > "%OUT%\wmic_users.log" 2>&1
wmic.exe group get Name,SID,Description /format:list > "%OUT%\wmic_groups.log" 2>&1

echo.
echo === RUNNING PROCESSES ===
wmic.exe process get Name,ProcessId,ParentProcessId,CommandLine /format:list > "%OUT%\wmic_processes.log" 2>&1
findstr /i "lsass mimikatz procdump secretsdump nmap sqlcmd" "%OUT%\wmic_processes.log" > "%OUT%\wmic_interesting_procs.log" 2>&1

echo.
echo === SERVICES ===
wmic.exe service get Name,State,StartMode,StartName,PathName /format:list > "%OUT%\wmic_services.log" 2>&1
wmic.exe service get Name,PathName /format:list | findstr /v /i "\\windows\\" | findstr /v "^$" > "%OUT%\wmic_unquoted.log" 2>&1

echo.
echo === SOFTWARE ===
wmic.exe product get Name,Vendor,Version /format:list > "%OUT%\wmic_software.log" 2>&1

echo.
echo === STARTUP / AUTORUNS ===
wmic.exe startup get Name,Command,Location,User /format:list > "%OUT%\wmic_startup.log" 2>&1

echo.
echo === PATCHES ===
wmic.exe qfe get HotFixID,InstalledOn,Caption /format:list > "%OUT%\wmic_patches.log" 2>&1

echo.
echo === NETWORK ===
wmic.exe nicconfig get Description,IPAddress,DefaultIPGateway,DNSServerSearchOrder,MACAddress /format:list > "%OUT%\wmic_nic.log" 2>&1
wmic.exe netlogin get Name,LastLogon,LogonServer /format:list > "%OUT%\wmic_logons.log" 2>&1

echo.
echo === Done ===
dir "%OUT%\wmic_*.log"
pause
endlocal
