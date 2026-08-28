@echo off
setlocal enabledelayedexpansion
REM ============================================
REM 3_ADCS_Discover.bat - AD CS CA discovery via certutil + LDAP
REM Uses certutil.exe (built-in). For CA templates needs RSAT
REM Output: %TEMP%\norsat_adcs_*.log
REM ============================================

set "OUT=%TEMP%"
set "DOM=lioncapital"

echo.
echo === AD CS AUTO-DISCOVERY ===
certutil.exe -ADCA > "%OUT%\norsat_adcs_cas.log" 2>&1
type "%OUT%\norsat_adcs_cas.log"

echo.
echo === ALL TEMPLATES (local machine) ===
certutil.exe -CATemplates > "%OUT%\norsat_adcs_templates.log" 2>&1
type "%OUT%\norsat_adcs_templates.log"

echo.
echo === STORE-LEVEL ENROLLMENT CHECK ===
certutil.exe -enrollment -user > "%OUT%\norsat_adcs_userenroll.log" 2>&1
certutil.exe -enrollment -machine > "%OUT%\norsat_adcs_machineenroll.log" 2>&1

echo.
echo === WEB ENROLLMENT URL CHECK (no RSAT needed) ===
echo --- HTTP enrollment ---
curl.exe -I "http://pwnaddbls01.lioncapita.local/certsrv/" 2>&1 | findstr /i "HTTP\|Server" >> "%OUT%\norsat_adcs_http.log"

echo.
echo --- WSUS / WS-ENROLLMENT URL ---
curl.exe -I "http://pwnaddbls01.lioncapita.local/ADPolicy/ADCS/" 2>&1 >> "%OUT%\norsat_adcs_http.log"

echo.
echo === LOCAL CA INSTALLED? ===
certutil.exe -store Root > "%OUT%\norsat_adcs_local_root.log" 2>&1
findstr /i "CN=" "%OUT%\norsat_adcs_local_root.log" > "%OUT%\norsat_adcs_local_ca.log" 2>&1
type "%OUT%\norsat_adcs_local_ca.log"

echo.
echo === TRYGET LDAPS QUERY (no RSAT - works with raw LDAP via ADSI) ===
echo --- Method: PowerShell ADSI without RSAT module ---

powershell -NoProfile -Command "try { $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain(); Write-Output ('Domain: ' + $dom.Name); Write-Output ('PDC: ' + $dom.PdcRoleOwner); Write-Output ('Forest: ' + $dom.Forest.Name) } catch { Write-Output ('PowerShell ADSI failed: ' + $_.Exception.Message) }" > "%OUT%\norsat_adcs_pdc.log" 2>&1
type "%OUT%\norsat_adcs_pdc.log"

echo.
echo === DONE ===
dir "%OUT%\norsat_adcs_*"
pause
endlocal
