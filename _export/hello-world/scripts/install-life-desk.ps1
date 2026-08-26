#Requires -Version 5.1
# 安裝靈命七習慣電腦版視窗程式
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $here 'life-desk-app.ps1'
if (-not (Test-Path -LiteralPath $src)) { throw "找不到 $src" }

$desk = [Environment]::GetFolderPath('Desktop')
$appDir = Join-Path $desk '靈命七習慣程式'
$work = Join-Path $desk '靈命七習慣資料'
New-Item -ItemType Directory -Force -Path $appDir, $work | Out-Null
foreach ($sub in @('今日存檔', '從手機匯入', '匯出給手機')) {
  New-Item -ItemType Directory -Force -Path (Join-Path $work $sub) | Out-Null
}

$raw = Get-Content -LiteralPath $src -Raw -Encoding UTF8
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText((Join-Path $appDir 'life-desk-app.ps1'), $raw, $utf8Bom)

$launcherPs1 = Join-Path $appDir '啟動.ps1'
$launchBody = @"
#Requires -Version 5.1
`$ErrorActionPreference = 'Stop'
`$app = Join-Path `$PSScriptRoot 'life-desk-app.ps1'
`$work = Join-Path ([Environment]::GetFolderPath('Desktop')) '靈命七習慣資料'
powershell -NoProfile -ExecutionPolicy Bypass -File `$app -WorkDir `$work
"@
[System.IO.File]::WriteAllText($launcherPs1, $launchBody, $utf8Bom)

$cmd = @"
@echo off
chcp 65001 >nul
title 靈命七習慣電腦版
cd /d "%USERPROFILE%\Desktop\靈命七習慣程式"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\啟動.ps1"
"@
Set-Content -LiteralPath (Join-Path $desk '靈命七習慣.cmd') -Value $cmd -Encoding ASCII

$vbs = @"
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = sh.ExpandEnvironmentStrings("%USERPROFILE%\Desktop\靈命七習慣程式")
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -File "".\啟動.ps1""", 1, False
"@
Set-Content -LiteralPath (Join-Path $desk '靈命七習慣.vbs') -Value $vbs -Encoding ASCII

Write-Host "已安裝完成"
Write-Host "請雙擊桌面：靈命七習慣.cmd  或  靈命七習慣.vbs"
Write-Host "資料夾：桌面\靈命七習慣資料\"
Write-Host "網頁版：$('https://copyshae.github.io/-/life-desk/')"
Write-Host "手機 14樣：https://copyshae.github.io/-/daily-14/"
Write-Host "手機 七習慣：https://copyshae.github.io/-/habits-7/"
