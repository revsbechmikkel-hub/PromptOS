@echo off
setlocal
cd /d "%~dp0"
echo ======================================
echo       PromptOS Windows Builder
ECHO ======================================
where py >nul 2>nul
if errorlevel 1 (
  echo Python launcher not found. Install Python 3.10+ from https://www.python.org/downloads/windows/
  echo During setup, enable "Add python.exe to PATH".
  pause
  exit /b 1
)
py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)"
if errorlevel 1 (
  echo PromptOS requires Python 3.10 or newer.
  pause
  exit /b 1
)
if not exist .venv py -3 -m venv .venv
call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
if errorlevel 1 goto :failed
python -m pip install -r requirements-windows.txt
if errorlevel 1 goto :failed
python -m unittest discover -s tests
if errorlevel 1 goto :failed
python -m PyInstaller --noconfirm --clean --onefile --windowed --name PromptOS --add-data "models.json;." promptos\main.py
if errorlevel 1 goto :failed
echo.
echo Build complete: dist\PromptOS.exe
where ISCC.exe >nul 2>nul
if not errorlevel 1 (
  ISCC.exe installer\PromptOS.iss
  if errorlevel 1 goto :failed
  echo Installer created in: installer-output\PromptOS-Setup.exe
) else (
  echo Inno Setup was not found. The standalone EXE is ready.
  echo Install Inno Setup to also create PromptOS-Setup.exe:
  echo https://jrsoftware.org/isdl.php
)
echo.
pause
exit /b 0
:failed
echo.
echo Build failed. Read the error above and try again.
pause
exit /b 1
