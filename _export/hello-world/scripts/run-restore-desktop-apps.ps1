#Requires -Version 5.1
# ASCII-only bootstrap: download restore-desktop-apps.ps1 as UTF-8 BOM, then run.
param(
  [switch]$ShowTip,
  [switch]$FirstInstall,
  [switch]$SkipScan
)

$ErrorActionPreference = "Stop"
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/restore-desktop-apps-459a" }
$url = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts/restore-desktop-apps.ps1"
$tmp = Join-Path $env:TEMP ("restore-desktop-apps-" + [guid]::NewGuid().ToString() + ".ps1")

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

$arg = @("-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $tmp)
if ($ShowTip) { $arg += "-ShowTip" }
if ($FirstInstall) { $arg += "-FirstInstall" }
if ($SkipScan) { $arg += "-SkipScan" }

try {
  & powershell.exe @arg
  exit $LASTEXITCODE
} finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}
