#Requires -Version 5.1
# ASCII-only bootstrap: download scan-desktop-clues.ps1 as UTF-8 with BOM, then run.
# Usage:
#   irm https://raw.githubusercontent.com/copyshae/-/cursor/restore-desktop-apps-459a/_export/hello-world/scripts/run-scan-desktop-clues.ps1 | iex
#   Or with restore:
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/copyshae/-/cursor/restore-desktop-apps-459a/_export/hello-world/scripts/run-scan-desktop-clues.ps1))) -Restore
param(
  [switch]$Restore,
  [switch]$ShowTip
)

$ErrorActionPreference = "Stop"
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/restore-desktop-apps-459a" }
$url = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts/scan-desktop-clues.ps1"
$tmp = Join-Path $env:TEMP ("scan-desktop-clues-" + [guid]::NewGuid().ToString() + ".ps1")

Write-Host "Download (UTF-8) ..."
Write-Host $url

$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
try {
  $text = $wc.DownloadString($url)
} finally {
  $wc.Dispose()
}
if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) {
  $text = $text.Substring(1)
}

$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($tmp, $text, $utf8Bom)
Write-Host ("Saved: {0}" -f $tmp)

$arg = @("-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $tmp)
if ($Restore) { $arg += "-Restore" }
if ($ShowTip) { $arg += "-ShowTip" }

try {
  & powershell.exe @arg
  exit $LASTEXITCODE
} finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}
