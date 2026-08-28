@echo off
REM ===============================================
REM run_stdin_vbs.bat - VBS via cscript stdin
REM Bypass: no .vbs file on disk, all inline via echo
REM ===============================================
REM This won't work because VBS doesn't read stdin from cscript.
REM Use the JScript version instead.
echo [Use run_stdin_js.bat instead - VBS does not support stdin]
exit /b
