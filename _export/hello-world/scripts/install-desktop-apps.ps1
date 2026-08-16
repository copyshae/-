#Requires -Version 5.1
# Install desktop apps (Traditional Chinese UI in child scripts)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$desk = [Environment]::GetFolderPath('Desktop')

Write-Host "Desktop: $desk"
Write-Host "Scripts: $here"
Write-Host ""

$teacherInstall = Join-Path $here 'install-teacher-desk.ps1'
if (-not (Test-Path -LiteralPath $teacherInstall)) {
  throw "Missing install-teacher-desk.ps1. Run git pull first."
}
& $teacherInstall

$graderInstall = Join-Path $here 'install-math-homework-grader.ps1'
if (Test-Path -LiteralPath $graderInstall) {
  & $graderInstall
} else {
  Write-Host "Skip math grader (install script not found)"
}

Write-Host ""
Write-Host "安裝完成。請雙擊桌面："
Write-Host "  習作台.vbs ／ 習作批改.vbs"
Write-Host "資料夾："
Write-Host "  桌面\習作台資料 ／ 桌面\MathGrading"
Write-Host ""
Write-Host "習作批改：先設定 Gemini 金鑰，再自動批"
