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
Write-Host "Install done. Double-click on Desktop:"
Write-Host "  teacher-desk VBS / grader VBS"
Write-Host "Work folders:"
Write-Host "  Desktop\TeacherDesk data / Desktop\MathGrading"
Write-Host ""
Write-Host "Grader: set Gemini key, then Gemini auto grade"
