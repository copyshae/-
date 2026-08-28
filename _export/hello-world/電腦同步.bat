@echo off
chcp 65001 >nul
title hello-world 電腦同步
echo.
echo === hello-world 電腦同步（0821-0823）===
echo.

set "ROOT=%USERPROFILE%\Desktop\hello-world"
if not exist "%ROOT%" (
  echo [錯誤] 找不到 %ROOT%
  echo 請先在桌面 clone hello-world 倉庫。
  pause
  exit /b 1
)

cd /d "%ROOT%"
set "TMP=%TEMP%\sync-hello-world.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/sync-hello-world.ps1' -OutFile '%TMP%' -UseBasicParsing; & '%TMP%'"

pause
