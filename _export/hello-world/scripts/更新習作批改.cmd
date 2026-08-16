@echo off
chcp 65001 >nul
set BRANCH=cursor/sync-desk-grader-devices-2663
echo 下載並執行更新腳本（分支 %BRANCH%）...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $u='https://raw.githubusercontent.com/copyshae/-/%BRANCH%/_export/hello-world/scripts/fix-grader-gemini-404.ps1?t='+[DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); $p=Join-Path $env:TEMP 'fix-grader-gemini-404.ps1'; Invoke-WebRequest -Uri $u -OutFile $p -UseBasicParsing; & $p"
echo.
pause
