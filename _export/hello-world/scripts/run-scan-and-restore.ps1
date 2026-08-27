#Requires -Version 5.1
# ASCII-only: scan desktop clues then restore matching apps (UTF-8 BOM safe).
# Paste in Windows PowerShell:
#   irm https://raw.githubusercontent.com/copyshae/-/cursor/restore-desktop-apps-459a/_export/hello-world/scripts/run-scan-and-restore.ps1 | iex

$ErrorActionPreference = "Stop"
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/restore-desktop-apps-459a" }
$runnerUrl = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts/run-scan-desktop-clues.ps1"
$tmp = Join-Path $env:TEMP ("run-scan-desktop-clues-" + [guid]::NewGuid().ToString() + ".ps1")

$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
try {
  $text = $wc.DownloadString($runnerUrl)
} finally {
  $wc.Dispose()
}
if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) {
  $text = $text.Substring(1)
}
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($tmp, $text, $utf8Bom)

try {
  & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $tmp -Restore
  exit $LASTEXITCODE
} finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}
