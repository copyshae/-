@echo off
chcp 65001 >nul
title 推學習日誌 0821–0829 到 hello-world
echo.
echo === 推學習日誌到 hello-world 正式站 ===
echo.

set "ROOT=%USERPROFILE%\Desktop\hello-world"
if not exist "%ROOT%" (
  echo [錯誤] 找不到 %ROOT%
  echo 請先在桌面 clone hello-world 倉庫。
  pause
  exit /b 1
)

cd /d "%ROOT%"
set "TMP=%TEMP%\push-learning-logs-only.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/scripts/push-learning-logs-only.ps1' -OutFile '%TMP%' -UseBasicParsing; & '%TMP%'"

echo.
pause
