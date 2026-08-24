@echo off
REM ============================================================================
REM OSCheat - C# build script using built-in csc.exe
REM No install required - csc.exe ships with .NET Framework (built into Windows)
REM ============================================================================

setlocal
set "SCRIPT_DIR=%~dp0"
set "CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
set "SOURCE=%SCRIPT_DIR%oscheat.cs"
set "OUTPUT=%SCRIPT_DIR%oscheat.exe"

REM Check if Framework 4 exists, fall back to 3.5 or 2.0 if not
if not exist "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" (
    if exist "C:\Windows\Microsoft.NET\Framework64\v3.5\csc.exe" (
        set "CSC=C:\Windows\Microsoft.NET\Framework64\v3.5\csc.exe"
    ) else (
        if exist "C:\Windows\Microsoft.NET\Framework64\v2.0.50727\csc.exe" (
            set "CSC=C:\Windows\Microsoft.NET\Framework64\v2.0.50727\csc.exe"
        )
    )
)

if not exist "%SOURCE%" (
    echo.
    echo ERROR: oscheat.cs not found in %SCRIPT_DIR%
    echo.
    pause
    exit /b 1
)

echo.
echo Building oscheat.exe using built-in C# compiler...
echo   Source:  %SOURCE%
echo   Compiler: %CSC%
echo   Output:  %OUTPUT%
echo.

REM Compile - use /nologo to suppress banner, /target:exe for executable, /out for output path
"%CSC%" /nologo /target:exe /out:"%OUTPUT%" "%SOURCE%" /reference:System.Web.Extensions.dll
set "BUILD_ERROR=%errorlevel%"

if %BUILD_ERROR% == 0 (
    if exist "%OUTPUT%" (
        echo.
        echo SUCCESS: %OUTPUT% built!
        echo.
        for %%f in ("%OUTPUT%") do echo   Size: %%~zf bytes
        echo.
        echo Run with:
        echo   cd /d "%SCRIPT_DIR%"
        echo   oscheat.exe
        echo.
    ) else (
        echo.
        echo BUILD COMPLETED BUT EXE NOT FOUND
        echo.
    )
) else (
    echo.
    echo BUILD FAILED with exit code %BUILD_ERROR%
    echo Common issues:
    echo   1. .NET Framework not installed (rare on Win10+)
    echo   2. Try a different .NET Framework version path
    echo.
)

echo Press any key to close...
pause > nul
endlocal
