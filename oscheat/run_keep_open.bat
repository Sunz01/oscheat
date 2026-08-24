@echo off
REM Bulletproof wrapper: keeps cmd window open no matter what
setlocal
cd /d "%~dp0"
if not exist "oscheat.bat" (
    echo.
    echo ERROR: oscheat.bat not found in %~dp0
    echo Place this run_keep_open.bat in the same folder as oscheat.bat
    echo.
    pause
    exit /b 1
)
call oscheat.bat
pause
