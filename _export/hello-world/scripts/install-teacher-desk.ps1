#Requires -Version 5.1
# 安裝／修復習作台桌面啟動器
# 重點：.cmd／.vbs 內容只用 ASCII 路徑，避免 Encoding ASCII 把中文路徑變成 ?????
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $here 'teacher-desk-app.ps1'
if (-not (Test-Path -LiteralPath $src)) { throw "找不到 $src" }

$desk = [Environment]::GetFolderPath('Desktop')
# 內部路徑固定英文，.cmd／.vbs 才不會因編碼壞掉
$appDir = Join-Path $desk 'TeacherDeskApp'
$work = Join-Path $desk 'TeacherDeskData'
$legacyWork = Join-Path $desk '習作台資料'
$legacyApp = Join-Path $desk '習作台程式'

New-Item -ItemType Directory -Force -Path $appDir, $work,
  (Join-Path $work 'scans-in'),
  (Join-Path $work 'export-phone'),
  (Join-Path $work '掃描匯入'),
  (Join-Path $work '匯出給手機') | Out-Null

# 舊中文資料夾 → 新英文資料夾（只在尚未遷移時複製）
function Copy-IfMissing([string]$from, [string]$to) {
  if (-not (Test-Path -LiteralPath $from)) { return }
  if (-not (Test-Path -LiteralPath $to)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $to) | Out-Null
    Copy-Item -LiteralPath $from -Destination $to -Recurse -Force
  }
}
if (Test-Path -LiteralPath $legacyWork) {
  Copy-IfMissing (Join-Path $legacyWork '班級狀態.json') (Join-Path $work '班級狀態.json')
  Copy-IfMissing (Join-Path $legacyWork 'class-state.json') (Join-Path $work 'class-state.json')
  Copy-IfMissing (Join-Path $legacyWork '掃描匯入') (Join-Path $work '掃描匯入')
  Copy-IfMissing (Join-Path $legacyWork '匯出給手機') (Join-Path $work '匯出給手機')
}

$raw = Get-Content -LiteralPath $src -Raw -Encoding UTF8
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText((Join-Path $appDir 'teacher-desk-app.ps1'), $raw, $utf8Bom)

# .cmd 內容必須是純 ASCII（路徑也是英文）
$cmd = @"
@echo off
setlocal
title Teacher Desk / XiZuoTai
cd /d "%USERPROFILE%\Desktop"
echo.
echo [Teacher Desk] starting...
echo.

set "APP=%USERPROFILE%\Desktop\TeacherDeskApp\teacher-desk-app.ps1"
set "WORK=%USERPROFILE%\Desktop\TeacherDeskData"
set "ERRLOG=%USERPROFILE%\Desktop\TeacherDesk-error.txt"

if not exist "%APP%" (
  echo ERROR: script not found:
  echo   %APP%
  echo.
  echo Please re-run:
  echo   powershell -ExecutionPolicy Bypass -File scripts\install-teacher-desk.ps1
  echo.
  pause
  exit /b 1
)

if exist "%ERRLOG%" del /f /q "%ERRLOG%" >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%APP%" -WorkDir "%WORK%"
set ERR=%ERRORLEVEL%

if exist "%ERRLOG%" (
  echo.
  echo ===== error log =====
  type "%ERRLOG%"
  echo =====================
)

if not "%ERR%"=="0" (
  echo.
  echo FAILED, exit code %ERR%
  echo Copy the text above to Cursor.
  echo.
  pause
  exit /b %ERR%
)

endlocal
"@

$ascii = New-Object System.Text.ASCIIEncoding
$cmdPathAscii = Join-Path $desk 'TeacherDesk-start.cmd'
$cmdPathZh = Join-Path $desk '習作台.cmd'
$cmdPathInApp = Join-Path $appDir 'start.cmd'
foreach ($p in @($cmdPathAscii, $cmdPathZh, $cmdPathInApp)) {
  [System.IO.File]::WriteAllText($p, $cmd.Replace("`n", "`r`n"), $ascii)
}

# VBS 也只用 ASCII 內容，呼叫英文檔名的 cmd（最穩）
$vbs = @"
Set sh = CreateObject("WScript.Shell")
desk = sh.SpecialFolders("Desktop")
sh.Run """" & desk & "\TeacherDesk-start.cmd""", 1, False
"@
$vbsPathAscii = Join-Path $desk 'TeacherDesk-start.vbs'
$vbsPathZh = Join-Path $desk '習作台.vbs'
$utf16 = New-Object System.Text.UnicodeEncoding $false, $true
foreach ($p in @($vbsPathAscii, $vbsPathZh)) {
  [System.IO.File]::WriteAllText($p, $vbs.Replace("`n", "`r`n"), $utf16)
}

$readme = @"
習作台桌面啟動說明
================

請雙擊其中一個：
  TeacherDesk-start.cmd   ← 最穩，建議用這個
  習作台.cmd
  TeacherDesk-start.vbs
  習作台.vbs

程式目錄：Desktop\TeacherDeskApp\
資料目錄：Desktop\TeacherDeskData\
錯誤紀錄：Desktop\TeacherDesk-error.txt

若視窗一閃就沒：
1. 雙擊 TeacherDesk-start.cmd（不要關太快）
2. 看有沒有錯誤文字，或桌面是否出現 TeacherDesk-error.txt
3. 在 hello-world 重新執行：
   powershell -ExecutionPolicy Bypass -File .\scripts\install-teacher-desk.ps1
"@
[System.IO.File]::WriteAllText((Join-Path $desk '習作台-啟動說明.txt'), $readme, $utf8Bom)
[System.IO.File]::WriteAllText((Join-Path $appDir 'README.txt'), $readme, $utf8Bom)

Write-Host ""
Write-Host "已安裝／修復完成"
Write-Host "請雙擊桌面：TeacherDesk-start.cmd   （最穩）"
Write-Host "或：習作台.cmd"
Write-Host "資料夾：Desktop\TeacherDeskData\"
Write-Host "若失敗：看 Desktop\TeacherDesk-error.txt"
Write-Host ""
