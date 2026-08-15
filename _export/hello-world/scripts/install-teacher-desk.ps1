#Requires -Version 5.1
# Teacher Desk installer (ASCII-only so Windows PowerShell 5.1 never mojibakes)
# Writes launchers that use -ExecutionPolicy Bypass
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $here 'teacher-desk-app.ps1'
if (-not (Test-Path -LiteralPath $src)) { throw "Missing $src" }

$desk = [Environment]::GetFolderPath('Desktop')
Write-Host ("Desktop: {0}" -f $desk)

$appDir = Join-Path $desk 'TeacherDeskApp'
$work = Join-Path $desk 'TeacherDeskData'

# Legacy Chinese folder name via codepoints: XiZuoTai + Data
$legacyName = ([string][char]0x7FD2) + ([string][char]0x4F5C) + ([string][char]0x53F0) + ([string][char]0x8CC7) + ([string][char]0x6599)
$legacyWork = Join-Path $desk $legacyName
$zhCmdName = ([string][char]0x7FD2) + ([string][char]0x4F5C) + ([string][char]0x53F0) + '.cmd'
$zhVbsName = ([string][char]0x7FD2) + ([string][char]0x4F5C) + ([string][char]0x53F0) + '.vbs'
$zhState = ([string][char]0x73ED) + ([string][char]0x7D1A) + ([string][char]0x72C0) + ([string][char]0x614B) + '.json'
$zhScan = ([string][char]0x6383) + ([string][char]0x63CF) + ([string][char]0x532F) + ([string][char]0x5165)
$zhExport = ([string][char]0x532F) + ([string][char]0x51FA) + ([string][char]0x7D66) + ([string][char]0x624B) + ([string][char]0x6A5F)

New-Item -ItemType Directory -Force -Path $appDir, $work,
  (Join-Path $work 'scans-in'),
  (Join-Path $work 'export-phone'),
  (Join-Path $work $zhScan),
  (Join-Path $work $zhExport) | Out-Null

function Copy-IfMissing([string]$from, [string]$to) {
  if (-not (Test-Path -LiteralPath $from)) { return }
  if (-not (Test-Path -LiteralPath $to)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $to) | Out-Null
    Copy-Item -LiteralPath $from -Destination $to -Recurse -Force
  }
}
if (Test-Path -LiteralPath $legacyWork) {
  Copy-IfMissing (Join-Path $legacyWork $zhState) (Join-Path $work $zhState)
  Copy-IfMissing (Join-Path $legacyWork 'class-state.json') (Join-Path $work 'class-state.json')
  Copy-IfMissing (Join-Path $legacyWork $zhScan) (Join-Path $work $zhScan)
  Copy-IfMissing (Join-Path $legacyWork $zhExport) (Join-Path $work $zhExport)
}

$raw = Get-Content -LiteralPath $src -Raw -Encoding UTF8
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText((Join-Path $appDir 'teacher-desk-app.ps1'), $raw, $utf8Bom)

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
    (Join-Path $desk $zhCmdName)
  )) {
  [System.IO.File]::WriteAllText($p, $cmdBody, $ascii)
  Write-Host ("Wrote: {0}" -f $p)
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
Write-Host ("Wrote: {0}" -f (Join-Path $appDir 'start.cmd'))

$vbs = @'
Set sh = CreateObject("WScript.Shell")
desk = sh.SpecialFolders("Desktop")
sh.Run """" & desk & "\TeacherDesk-start.cmd""", 1, False
'@
$utf16 = New-Object System.Text.UnicodeEncoding $false, $true
foreach ($p in @((Join-Path $desk 'TeacherDesk-start.vbs'), (Join-Path $desk $zhVbsName))) {
  [System.IO.File]::WriteAllText($p, $vbs.Replace("`n", "`r`n"), $utf16)
  Write-Host ("Wrote: {0}" -f $p)
}

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
Write-Host ("Wrote: {0}" -f (Join-Path $desk 'TeacherDesk-ABS.cmd'))

Write-Host ""
Write-Host "===== INSTALL OK ====="
Write-Host ("Desktop: {0}" -f $desk)
Write-Host "Try in order:"
Write-Host "  1) TeacherDesk-ABS.cmd"
Write-Host "  2) TeacherDesk-DEBUG.cmd"
Write-Host "  3) TeacherDeskApp\start.cmd"
$ps1Check = Join-Path $appDir 'teacher-desk-app.ps1'
Write-Host ("App: {0}" -f $ps1Check)
Write-Host ("Exists: {0}" -f (Test-Path -LiteralPath $ps1Check))
Write-Host "======================"
