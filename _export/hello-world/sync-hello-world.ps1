#Requires -Version 5.1
# 一鍵同步 hello-world（0821–0823 + habits-7 / doc-reader / daily-14）
# 用法：在 PowerShell 執行此檔，或雙擊「電腦同步.bat」
$ErrorActionPreference = 'Stop'

$root = Join-Path ([Environment]::GetFolderPath('Desktop')) 'hello-world'
if (-not (Test-Path -LiteralPath $root)) {
  Write-Host ''
  Write-Host '找不到 Desktop\hello-world'
  Write-Host '請先 clone：'
  Write-Host '  cd $env:USERPROFILE\Desktop'
  Write-Host '  git clone https://github.com/copyshae/hello-world.git'
  Write-Host ''
  Read-Host '按 Enter 結束'
  exit 1
}

Set-Location $root
$scriptDir = Join-Path $root 'scripts'
New-Item -ItemType Directory -Force -Path $scriptDir | Out-Null

$url = 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/scripts/pull-export-from-dash-repo.ps1'
$pull = Join-Path $scriptDir 'pull-export-from-dash-repo.ps1'
Write-Host "下載最新同步腳本..."
Invoke-WebRequest -Uri $url -OutFile $pull -UseBasicParsing

Write-Host ''
Write-Host '開始同步 hello-world（約 1 分鐘）...'
Write-Host ''
& powershell -ExecutionPolicy Bypass -File $pull

Write-Host ''
Write-Host '完成。請用瀏覽器確認（最上方應為 20260829）：'
Write-Host '  https://copyshae.github.io/hello-world/directory/202608/index.html'
Write-Host '  https://copyshae.github.io/hello-world/directory/202608/20260821-learning-log.html'
Write-Host ''
try {
  Start-Process 'https://copyshae.github.io/hello-world/directory/202608/'
} catch {}

Read-Host '按 Enter 結束'
