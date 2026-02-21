@echo off

set "MODE=%~1"

set "DATA_DIR=%~dp0"

cd "%DATA_DIR%\.."

if "%MODE%"=="" set "MODE=rece"

if /I "%MODE%"=="send" (

    "%DATA_DIR%\cygwin64\bin\bash.exe" "%DATA_DIR%\send.sh"

) else if /I "%MODE%"=="rece" (

    "%DATA_DIR%\cygwin64\bin\bash.exe" "%DATA_DIR%\receive.sh"

) else (
    echo Usage:
    echo    %~nx0 [send^|rece]
    exit /b 1
)
