#Requires -Version 5.1
<#
.SYNOPSIS
  依 hello-world 學習日誌，恢復桌面 WinForms 視窗程式。

.DESCRIPTION
  來源（GitHub Pages 學習日誌）：
    0803 數學習作批改視窗 → MathGradingApp、習作批改.vbs
    0805 桌面習作台、掃描匯入 → 習作台程式、習作台.vbs
    0817 換機 clone 一鍵裝 → bootstrap-desktop-apps.ps1
    0818 快速啟動、ChatPlayground → refresh-desktop-vbs.ps1、習作工具.vbs
  0801 護眼提醒 → EyeCareReminder、護眼提醒.vbs（hello-world 分支 eye-care）
  0819 掃具台 → 掃具台.cmd、掃具台程式（hello-world master）

  建議先跑 scan-desktop-clues.ps1 掃桌面線索再 -Restore。
  本腳本：下載最新 ps1 + 捷徑到桌面，標題列應含 [20260818-fast5]。

.NOTES
  完整掃描桌面線索：scan-desktop-clues.ps1（對照 0801～0819 學習日誌）。
#>
param(
  [switch]$ShowTip,
  [switch]$FirstInstall,
  [switch]$SkipScan
)

$ErrorActionPreference = "Stop"
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/restore-desktop-apps-459a" }
$dashBase = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts"
$refreshUrl = "$dashBase/refresh-desktop-vbs.ps1"
$scanUrl = "$dashBase/scan-desktop-clues.ps1"

if (-not $SkipScan) {
  Write-Host "先掃描桌面線索（對照學習日誌）..."
  $scanTmp = Join-Path $env:TEMP ("scan-hw-" + [guid]::NewGuid().ToString() + ".ps1")
  try {
    Invoke-WebRequest -Uri $scanUrl -OutFile $scanTmp -UseBasicParsing
    & powershell.exe -ExecutionPolicy Bypass -File $scanTmp
  } catch {
    Write-Host "（略過掃描：$($_.Exception.Message)）"
  } finally {
    Remove-Item -LiteralPath $scanTmp -Force -ErrorAction SilentlyContinue
  }
  Write-Host ""
}
Write-Host "===== 恢復桌面習作視窗（依學習日誌）====="
Write-Host "分支：$branch"
Write-Host ""
Write-Host "規格依據："
Write-Host "  https://copyshae.github.io/hello-world/directory/202608/20260803-learning-log.html"
Write-Host "  https://copyshae.github.io/hello-world/directory/202608/20260805-learning-log.html"
Write-Host "  https://copyshae.github.io/hello-world/directory/202608/20260817-learning-log.html"
Write-Host ""

if ($FirstInstall) {
  $hw = Join-Path ([Environment]::GetFolderPath("Desktop")) "hello-world"
  if (-not (Test-Path -LiteralPath $hw)) {
    Write-Host "首次安裝：clone hello-world 到桌面 ..."
    $cloneUrl = "https://github.com/copyshae/hello-world.git"
    git clone $cloneUrl $hw
  }
  $bootstrap = Join-Path $hw "scripts\bootstrap-desktop-apps.ps1"
  if (Test-Path -LiteralPath $bootstrap) {
    Write-Host "執行 bootstrap-desktop-apps.ps1（建立工作資料夾）..."
    & $bootstrap
  } else {
    Write-Host "（略過 bootstrap：找不到 $bootstrap）"
  }
}

$tmp = Join-Path $env:TEMP ("restore-hw-" + [guid]::NewGuid().ToString() + ".ps1")
try {
  Invoke-WebRequest -Uri $refreshUrl -OutFile $tmp -UseBasicParsing
  $arg = @("-ExecutionPolicy", "Bypass", "-File", $tmp)
  if ($ShowTip) { $arg += "-ShowTip" }
  & powershell.exe @arg
} finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "完成。請："
Write-Host "  1. 關掉所有舊的習作批改／習作台視窗"
Write-Host "  2. 雙擊桌面「習作工具.vbs」（或 習作批改.vbs／習作台.vbs）"
Write-Host "  3. 標題列應含 [20260818-fast5]；桌面會有 習作程式版本.txt"
Write-Host "  4. 完整線索報告：桌面\桌面程式線索報告.txt"
Write-Host ""
Write-Host "若要連護眼／掃具台一併恢復（桌面有線索才做）："
Write-Host "  powershell -ExecutionPolicy Bypass -File scan-desktop-clues.ps1 -Restore"
