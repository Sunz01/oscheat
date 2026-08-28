@echo off
setlocal enabledelayedexpansion

REM ===============================================
REM run_ad_recon_inline.bat - PS1 via -Command (no .ps1 file)
REM Workaround for Trellix scanning .ps1 files
REM Output: %TEMP%\ad_recon_adsi.log
REM ===============================================

set "OUT=%TEMP%"

echo.
echo === AD RECON via inline PowerShell (Trellix bypass) ===
echo Output: %OUT%\ad_recon_adsi.log
echo.

REM ----- Step 1: domain info -----
echo [1/16] Domain info...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$d=[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain(); Write-Output ('Domain: '+$d.Name); Write-Output ('PDC: '+$d.PdcRoleOwner); Write-Output ('SID: '+$d.DomainSid); Write-Output ('GUID: '+$d.Forest.RootDomain.DomainGuid); Write-Output ('Forest: '+$d.Forest.Name)" 2>&1

echo.
echo [2/16] Forest info...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$f=[System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest(); Write-Output ('Schema Master: '+$f.SchemaRoleOwner); Write-Output ('Naming Master: '+$f.NamingRoleOwner); Write-Output ('Sites: '+(($f.Sites | Select-Object -ExpandProperty Name) -join ', ')); Write-Output ('GCs: '+(($f.FindAllGlobalCatalogs() | Select-Object -ExpandProperty Name) -join ', '))" 2>&1

echo.
echo [3/16] Domain Controllers...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=8192))'; $s.PageSize=1000; foreach($r in $s.FindAll()){Write-Output ($r.Properties['name'][0]+' | '+$r.Properties['operatingsystem'][0]+' | '+$r.Properties['dnshostname'][0])}" 2>&1

echo.
echo [4/16] All domain users (count)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=user)(objectClass=user))'; $s.PageSize=1000; $s.SizeLimit=0; Write-Output ('Total users: '+$s.FindAll().Count)" 2>&1

echo.
echo [5/16] SPN users (Kerberoastable)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=user)(objectClass=user)(servicePrincipalName=*))'; $s.PageSize=1000; $s.SizeLimit=0; $res=$s.FindAll(); Write-Output ('Total SPN: '+$res.Count); foreach($r in $res){$u=$r.GetDirectoryEntry(); Write-Output ('  '+$u.samaccountname+' -> '+(($u.servicePrincipalName | Select-Object -First 1)))}" 2>&1

echo.
echo [6/16] AS-REP Roastable (no-preauth)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=user)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))'; $s.PageSize=1000; $res=$s.FindAll(); Write-Output ('Total AS-REP: '+$res.Count); foreach($r in $res){Write-Output ('  '+$r.Properties['samaccountname'][0])}" 2>&1

echo.
echo [7/16] Never-expiring password accounts...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=user)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=65536))'; $s.PageSize=1000; $res=$s.FindAll(); Write-Output ('Total never-expire: '+$res.Count); foreach($r in $res){Write-Output ('  '+$r.Properties['samaccountname'][0])}" 2>&1

echo.
echo [8/16] All domain groups (count)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=group))'; $s.PageSize=1000; Write-Output ('Total groups: '+$s.FindAll().Count)" 2>&1

echo.
echo [9/16] Privileged group memberships...
echo --- Domain Admins ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(memberOf=CN=Domain Admins,CN=Users,DC=lioncapital,DC=local)'; $s.PageSize=1000; $res=$s.FindAll(); Write-Output ('Total DA: '+$res.Count); foreach($r in $res){$u=$r.GetDirectoryEntry(); Write-Output ('  '+$u.samaccountname)}" 2>&1

echo --- Enterprise Admins ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(memberOf=CN=Enterprise Admins,CN=Users,DC=lioncapital,DC=local)'; $s.PageSize=1000; $res=$s.FindAll(); Write-Output ('Total EA: '+$res.Count); foreach($r in $res){$u=$r.GetDirectoryEntry(); Write-Output ('  '+$u.samaccountname)}" 2>&1

echo --- Schema Admins ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(memberOf=CN=Schema Admins,CN=Users,DC=lioncapital,DC=local)'; $s.PageSize=1000; $res=$s.FindAll(); Write-Output ('Total Schema: '+$res.Count); foreach($r in $res){$u=$r.GetDirectoryEntry(); Write-Output ('  '+$u.samaccountname)}" 2>&1

echo --- Account Operators ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(memberOf=CN=Account Operators,CN=Users,DC=lioncapital,DC=local)'; $s.PageSize=1000; foreach($r in $s.FindAll()){$u=$r.GetDirectoryEntry(); Write-Output ('  '+$u.samaccountname)}" 2>&1

echo --- Backup Operators ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(memberOf=CN=Backup Operators,CN=Users,DC=lioncapital,DC=local)'; $s.PageSize=1000; foreach($r in $s.FindAll()){$u=$r.GetDirectoryEntry(); Write-Output ('  '+$u.samaccountname)}" 2>&1

echo --- Cert Publishers ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(memberOf=CN=Cert Publishers,CN=Users,DC=lioncapital,DC=local)'; $s.PageSize=1000; foreach($r in $s.FindAll()){$u=$r.GetDirectoryEntry(); Write-Output ('  '+$u.samaccountname)}" 2>&1

echo --- DnsAdmins ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(memberOf=CN=DnsAdmins,CN=Users,DC=lioncapital,DC=local)'; $s.PageSize=1000; foreach($r in $s.FindAll()){$u=$r.GetDirectoryEntry(); Write-Output ('  '+$u.samaccountname)}" 2>&1

echo.
echo [10/16] All domain computers...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=computer))'; $s.PageSize=1000; $res=$s.FindAll(); Write-Output ('Total computers: '+$res.Count); foreach($r in $res){Write-Output ('  '+$r.Properties['name'][0]+' | '+($r.Properties['operatingsystem'][0]))}" 2>&1

echo.
echo [11/16] All OUs...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=organizationalUnit))'; $s.PageSize=1000; $res=$s.FindAll(); Write-Output ('Total OUs: '+$res.Count); foreach($r in $res){Write-Output ('  '+$r.Properties['name'][0]+' -> '+$r.Properties['distinguishedname'][0])}" 2>&1

echo.
echo [12/16] AD CS - Enterprise CAs...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=pKIEnrollmentService))'; $s.PageSize=100; foreach($r in $s.FindAll()){Write-Output ('  CA: '+$r.Properties['name'][0]+' @ '+$r.Properties['dnshostname'][0])}" 2>&1

echo.
echo [13/16] Certificate Templates...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectClass=pKICertificateTemplate))'; $s.PageSize=1000; $res=$s.FindAll(); Write-Output ('Total templates: '+$res.Count); foreach($r in $res){Write-Output ('  '+$r.Properties['name'][0]+' (display: '+$r.Properties['displayname'][0]+')')}" 2>&1

echo.
echo [14/16] ESC1 candidates (ENROLLEE_SUPPLIES_SUBJECT)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectClass=pKICertificateTemplate)(msPKI-Certificate-Name-Flag:1.2.840.113556.1.4.803:=1))'; $s.PageSize=1000; $res=$s.FindAll(); Write-Output ('Total ESC1: '+$res.Count); foreach($r in $res){Write-Output ('  [ESC1] '+$r.Properties['name'][0]+' (display: '+$r.Properties['displayname'][0]+')')}" 2>&1

echo.
echo [15/16] ESC6 candidates (CA flag 0x80000)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=pKIEnrollmentService)(flags:1.2.840.113556.1.4.803:=524288))'; $s.PageSize=100; $res=$s.FindAll(); Write-Output ('Total ESC6: '+$res.Count); foreach($r in $res){Write-Output ('  [ESC6] '+$r.Properties['name'][0])}" 2>&1

echo.
echo [16/16] Computers with LAPS...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[adsisearcher]'(&(objectCategory=computer)(ms-Mcs-AdmPwd=*))'; $s.PageSize=1000; $res=$s.FindAll(); Write-Output ('Total LAPS machines: '+$res.Count); foreach($r in $res){Write-Output ('  '+$r.Properties['name'][0]+' : '+$r.Properties['ms-Mcs-AdmPwd'][0])}" 2>&1

echo.
echo ===========================================
echo      DONE
echo ===========================================
echo Copy all output to: %OUT%\ad_recon_adsi.log
pause
endlocal
