@echo off
REM Double-click this file to run the workshop setup.
REM It asks for admin rights, then runs setup-windows.ps1 from the same folder.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Asking for permission to install... click Yes on the pop-up.
    if "%~1"=="" (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    ) else (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"
    )
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1" %*
