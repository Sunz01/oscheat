@echo off
REM ============================================================================
REM OSCheat C# build - simple version
REM Compiles oscheat.cs -> oscheat.exe using built-in csc.exe
REM No install required - .NET Framework ships with Windows
REM ============================================================================

setlocal EnableDelayedExpansion
cd /d "%~dp0"

REM Find csc.exe (try multiple versions)
set "CSC="
if exist "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" set "CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if "!CSC!"=="" if exist "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe" set "CSC=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if "!CSC!"=="" if exist "C:\Windows\Microsoft.NET\Framework64\v3.5\csc.exe" set "CSC=C:\Windows\Microsoft.NET\Framework64\v3.5\csc.exe"
if "!CSC!"=="" if exist "C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe" set "CSC=C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe"

if "!CSC!"=="" (
    echo ERROR: csc.exe not found in any .NET Framework folder.
    echo This means .NET Framework is not installed.
    echo.
    echo Run CHECK_TOOLS.bat for more diagnostics.
    pause
    exit /b 1
)

if not exist "oscheat.cs" (
    echo ERROR: oscheat.cs not found in %~dp0
    echo Place oscheat.cs in the same folder as this BAT file.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Building oscheat.exe
echo  Compiler: !CSC!
echo  Source:   oscheat.cs
echo  Output:   oscheat.exe
echo ============================================================
echo.

REM Compile
"!CSC!" /nologo /target:exe /out:oscheat.exe oscheat.cs /reference:System.Web.Extensions.dll
set "ERR=!errorlevel!"

echo.
if !ERR! EQU 0 (
    if exist oscheat.exe (
        echo BUILD SUCCESS!
        echo.
        for %%f in (oscheat.exe) do echo   File: oscheat.exe %%~zf bytes
        echo.
        echo To run: double-click oscheat.exe
        echo.
    ) else (
        echo BUILD SUCCEEDED but no .exe produced? weird.
    )
) else (
    echo BUILD FAILED with exit code !ERR!
    echo.
    echo Common causes:
    echo   1. .NET Framework 4.0 not installed ^(Windows 7 may not have it^)
    echo   2. oscheat.cs has syntax errors
    echo   3. Missing file paths
    echo.
)

echo.
echo Press any key to close...
pause > nul
endlocal
