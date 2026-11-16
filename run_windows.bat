@echo off
cd /d "%~dp0"
where py >nul 2>nul || (echo Install Python 3.10+ first: https://www.python.org/downloads/windows/ & pause & exit /b 1)
py -3 -m promptos.main
if errorlevel 1 pause
