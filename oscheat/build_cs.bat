@echo off
REM ============================================================================
REM OSCheat C# build script (v2 - simplified)
REM Compiles oscheat.cs to oscheat.exe using built-in csc.exe
REM ============================================================================

setlocal EnableDelayedExpansion
cd /d "%~dp0"

REM Find csc.exe (try multiple paths)
set "CSC="
set "CSC_PATHS=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe C:\Windows\Microsoft.NET\Framework64\v3.5\csc.exe C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe C:\Windows\Microsoft.NET\Framework64\v2.0.50727\csc.exe C:\Windows\Microsoft.NET\Framework\v2.0.50727\csc.exe"

for %%p in (!CSC_PATHS!) do (
    if "!CSC!"=="" if exist "%%~p" set "CSC=%%~p"
)

if "!CSC!"=="" (
    echo.
    echo ERROR: csc.exe not found in any .NET Framework folder.
    echo.
    echo This means .NET Framework is not installed or blocked.
    echo Try running CHECK_TOOLS.bat for more diagnostics.
    echo.
    pause
    exit /b 1
)

if not exist "oscheat.cs" (
    echo.
    echo ERROR: oscheat.cs not found in this folder.
    echo Place oscheat.cs in the same folder as this BAT file.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  OSCheat build
echo  Compiler: !CSC!
echo  Source:   oscheat.cs
echo  Output:   oscheat.exe
echo ============================================================
echo.
echo Compiling...

REM Compile - no fancy /reference flags, just use defaults
"!CSC!" /nologo /target:exe /out:oscheat.exe oscheat.cs
set "ERR=!errorlevel!"

echo.
if !ERR! EQU 0 (
    if exist oscheat.exe (
        echo BUILD SUCCESS!
        echo.
        for %%f in (oscheat.exe) do echo   oscheat.exe = %%~zf bytes
        echo.
        echo You can now double-click oscheat.exe to run OSCheat
        echo.
    ) else (
        echo BUILD SUCCEEDED but no exe produced?
    )
) else (
    echo BUILD FAILED with exit code !ERR!
    echo.
    echo Common causes:
    echo   1. oscheat.cs has syntax errors
    echo   2. Missing C# dependencies
    echo   3. .NET Framework version mismatch
    echo.
    echo Check oscheat.cs lines mentioned in errors above.
)

echo.
pause
endlocal
