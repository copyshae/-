# ASCII-only. For irm|iex scan only (no -Restore). Prefer run-scan-and-restore.ps1 for full restore.
param(
  [switch]$Restore,
  [switch]$ShowTip
)
$ErrorActionPreference = "Stop"
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/restore-desktop-apps-459a" }
$url = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts/scan-desktop-clues.ps1"
$tmp = Join-Path $env:TEMP ("scan-desktop-clues-" + [guid]::NewGuid().ToString() + ".ps1")

Write-Host "Download (bytes) ..."
Write-Host $url
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "restore-desktop-apps")
try {
  $bytes = $wc.DownloadData($url)
} finally {
  $wc.Dispose()
}
[System.IO.File]::WriteAllBytes($tmp, $bytes)

$arg = @("-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $tmp)
if ($Restore) { $arg += "-Restore" }
if ($ShowTip) { $arg += "-ShowTip" }
try {
  & powershell.exe @arg
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
} finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}
