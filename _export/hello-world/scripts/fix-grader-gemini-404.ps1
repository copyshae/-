#Requires -Version 5.1
# Minimal fix: download grader only into Desktop\MathGradingApp and refresh shortcut.
$ErrorActionPreference = "Stop"
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/sync-desk-grader-devices-2663" }
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$url = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts/math-homework-grader-app.ps1?t=$ts"
$desk = [Environment]::GetFolderPath("Desktop")
$appDir = Join-Path $desk "MathGradingApp"
$work = Join-Path $desk "MathGrading"
New-Item -ItemType Directory -Force -Path $appDir | Out-Null
New-Item -ItemType Directory -Force -Path $work | Out-Null

Write-Host "Download math-homework-grader-app.ps1 ..."
$tmp = Join-Path $env:TEMP "math-homework-grader-app.ps1"
Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
$bytes = [System.IO.File]::ReadAllBytes($tmp)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) { $text = $text.Substring(1) }
$dest = Join-Path $appDir "math-homework-grader-app.ps1"
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($dest, $text, $utf8Bom)
Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
Write-Host "Saved $dest"

$settingsPath = Join-Path $work "settings.json"
if (Test-Path -LiteralPath $settingsPath) {
  $raw = [System.IO.File]::ReadAllText($settingsPath)
  $raw2 = $raw.Replace("gemini-2.0-flash", "gemini-3.5-flash").Replace("gemini-1.5-flash", "gemini-3.5-flash")
  [System.IO.File]::WriteAllText($settingsPath, $raw2, $utf8Bom)
  Write-Host "Updated settings.json retired model names -> gemini-3.5-flash"
}

$vbs = @"
Set sh = CreateObject("WScript.Shell")
desk = sh.SpecialFolders("Desktop")
ps1 = desk & "\MathGradingApp\math-homework-grader-app.ps1"
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File """ & ps1 & """ -WorkDir """ & desk & "\MathGrading"""
sh.Run cmd, 1, False
"@
Set-Content -LiteralPath (Join-Path $desk "grade-math.vbs") -Value $vbs -Encoding ASCII
Set-Content -LiteralPath (Join-Path $appDir "launch.vbs") -Value $vbs -Encoding ASCII

Write-Host "DONE"
Write-Host "1) Close old grader window"
Write-Host "2) Double-click Desktop\grade-math.vbs"
Write-Host "3) Gemini key -> Test key (real generateContent) -> auto grade"
