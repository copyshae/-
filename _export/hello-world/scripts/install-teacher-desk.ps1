#Requires -Version 5.1
# 安裝／修復習作台桌面啟動器
# 1) .cmd／.vbs 內容只用 ASCII（或絕對路徑用系統編碼）
# 2) GetFolderPath('Desktop') 對齊 OneDrive 桌面
# 3) cmd 樣板用 @' '@，避免安裝時把 $變數展開壞掉
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $here 'teacher-desk-app.ps1'
if (-not (Test-Path -LiteralPath $src)) { throw "找不到 $src" }

$desk = [Environment]::GetFolderPath('Desktop')
Write-Host ("實際桌面路徑：{0}" -f $desk)

$appDir = Join-Path $desk 'TeacherDeskApp'
$work = Join-Path $desk 'TeacherDeskData'
$legacyWork = Join-Path $desk '習作台資料'

New-Item -ItemType Directory -Force -Path $appDir, $work,
  (Join-Path $work 'scans-in'),
  (Join-Path $work 'export-phone'),
  (Join-Path $work '掃描匯入'),
  (Join-Path $work '匯出給手機') | Out-Null

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

# 字面字串：不可用 @" "@
$cmd = @'
@echo off
setlocal
title Teacher Desk
echo.
echo [Teacher Desk] starting...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0TeacherDeskApp\teacher-desk-app.ps1" -WorkDir "%~dp0TeacherDeskData"
set ERR=%ERRORLEVEL%

if exist "%~dp0TeacherDesk-error.txt" (
  echo.
  echo ===== TeacherDesk-error.txt =====
  type "%~dp0TeacherDesk-error.txt"
  echo =================================
)

if not "%ERR%"=="0" (
  echo.
  echo FAILED, exit code %ERR%
  echo.
)

echo.
echo If no green window appeared, copy this text to Cursor.
pause
endlocal
'@

$ascii = New-Object System.Text.ASCIIEncoding
$cmdBody = $cmd.Replace("`n", "`r`n")
foreach ($p in @(
    (Join-Path $desk 'TeacherDesk-start.cmd'),
    (Join-Path $desk 'TeacherDesk-DEBUG.cmd'),
    (Join-Path $desk '習作台.cmd')
  )) {
  [System.IO.File]::WriteAllText($p, $cmdBody, $ascii)
  Write-Host ("已寫入：{0}" -f $p)
}

$cmdInApp = @'
@echo off
setlocal
title Teacher Desk
echo [Teacher Desk] starting from app folder...
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0teacher-desk-app.ps1" -WorkDir "%~dp0..\TeacherDeskData"
echo exit=%ERRORLEVEL%
if exist "%~dp0..\TeacherDesk-error.txt" type "%~dp0..\TeacherDesk-error.txt"
pause
endlocal
'@
[System.IO.File]::WriteAllText((Join-Path $appDir 'start.cmd'), $cmdInApp.Replace("`n", "`r`n"), $ascii)
Write-Host ("已寫入：{0}" -f (Join-Path $appDir 'start.cmd'))

$vbs = @'
Set sh = CreateObject("WScript.Shell")
desk = sh.SpecialFolders("Desktop")
sh.Run """" & desk & "\TeacherDesk-start.cmd""", 1, False
'@
$utf16 = New-Object System.Text.UnicodeEncoding $false, $true
foreach ($p in @((Join-Path $desk 'TeacherDesk-start.vbs'), (Join-Path $desk '習作台.vbs'))) {
  [System.IO.File]::WriteAllText($p, $vbs.Replace("`n", "`r`n"), $utf16)
  Write-Host ("已寫入：{0}" -f $p)
}

# 絕對路徑啟動器（寫死這次偵測到的桌面完整路徑）
$ps1Abs = Join-Path $appDir 'teacher-desk-app.ps1'
$logAbs = Join-Path $desk 'TeacherDesk-error.txt'
$absCmd = @"
@echo off
setlocal
title Teacher Desk ABS
echo.
echo [Teacher Desk ABS]
echo.

if not exist "$ps1Abs" (
  echo MISSING:
  echo $ps1Abs
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "$ps1Abs" -WorkDir "$work"
set ERR=%ERRORLEVEL%

if exist "$logAbs" (
  echo.
  echo ===== error =====
  type "$logAbs"
  echo =================
)

echo.
echo exit=%ERR%
echo If no green window, copy this text to Cursor.
pause
endlocal
"@
[System.IO.File]::WriteAllText((Join-Path $desk 'TeacherDesk-ABS.cmd'), $absCmd.Replace("`n", "`r`n"), [System.Text.Encoding]::Default)
Write-Host ("已寫入：{0}" -f (Join-Path $desk 'TeacherDesk-ABS.cmd'))

Write-Host ""
Write-Host "===== 安裝完成 ====="
Write-Host ("桌面：{0}" -f $desk)
Write-Host "請依序試："
Write-Host "  1) TeacherDesk-ABS.cmd     ← 優先"
Write-Host "  2) TeacherDesk-DEBUG.cmd"
Write-Host "  3) TeacherDeskApp\start.cmd"
$ps1Check = Join-Path $appDir 'teacher-desk-app.ps1'
Write-Host ("程式：{0}" -f $ps1Check)
Write-Host ("存在：{0}" -f (Test-Path -LiteralPath $ps1Check))
Write-Host "===================="
