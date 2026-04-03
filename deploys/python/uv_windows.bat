@echo off
echo Installing uv safely...

set URL=https://astral.sh/uv/install.ps1
set TMP=%TEMP%\uv_install.ps1

powershell -Command "Invoke-WebRequest -Uri %URL% -OutFile %TMP%"

powershell -ExecutionPolicy Bypass -File %TMP%

del %TMP%

echo.
uv --version
pause
