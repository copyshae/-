# ASCII-only. irm .../run-restore-desktop-apps.ps1 | iex
param(
  [switch]$ShowTip,
  [switch]$FirstInstall,
  [switch]$SkipScan
)
$ErrorActionPreference = "Stop"
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/restore-desktop-apps-459a" }
$url = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts/refresh-desktop-vbs.ps1"
$tmp = Join-Path $env:TEMP ("refresh-desktop-vbs-" + [guid]::NewGuid().ToString() + ".ps1")

$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$wc.Headers.Add("User-Agent", "restore-desktop-apps")
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
try {
  & powershell.exe @arg
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
} finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}
