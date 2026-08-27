# ASCII-only entry for: irm .../run-scan-and-restore.ps1 | iex
# No BOM, no Requires-directive (those break Invoke-Expression on Windows PowerShell 5.1).
$ErrorActionPreference = "Stop"
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/restore-desktop-apps-459a" }
$url = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts/scan-desktop-clues.ps1"
$tmp = Join-Path $env:TEMP ("scan-desktop-clues-" + [guid]::NewGuid().ToString() + ".ps1")

Write-Host "Download scan-desktop-clues.ps1 ..."
Write-Host $url

$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "restore-desktop-apps")
try {
  # Download raw bytes so encoding stays intact
  $bytes = $wc.DownloadData($url)
} finally {
  $wc.Dispose()
}
[System.IO.File]::WriteAllBytes($tmp, $bytes)
Write-Host ("Saved: {0}" -f $tmp)

try {
  & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $tmp -Restore
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
} finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}
