# Apply staged 20260801 learning log into local hello-world clone.
# Usage (from this repo root, with hello-world writable nearby):
#   powershell -ExecutionPolicy Bypass -File .\_export\hello-world\apply-to-hello-world.ps1

$ErrorActionPreference = 'Stop'
$candidates = @(
  (Join-Path $env:USERPROFILE 'Desktop\hello-world'),
  (Join-Path $env:USERPROFILE 'hello-world')
)
$dest = $candidates | Where-Object { Test-Path (Join-Path $_ '.git') } | Select-Object -First 1
if (-not $dest) {
  throw '找不到本機 hello-world。請先 clone 到 Desktop\hello-world。'
}

$src = $PSScriptRoot
Push-Location $dest
try {
  git pull origin master
  New-Item -ItemType Directory -Force -Path (Join-Path $dest 'directory\logs') | Out-Null
  Copy-Item (Join-Path $src 'directory\logs\20260801-learning-log.html') (Join-Path $dest 'directory\logs\20260801-learning-log.html') -Force
  Copy-Item (Join-Path $src 'directory\logs\index.html') (Join-Path $dest 'directory\logs\index.html') -Force
  Copy-Item (Join-Path $src 'directory\index.html') (Join-Path $dest 'directory\index.html') -Force
  git add directory/logs/20260801-learning-log.html directory/logs/index.html directory/index.html
  git commit -m 'Add 20260801 learning log: LINE forwarder and visit notes archive.'
  git push origin master
  Write-Host 'Done: https://copyshae.github.io/hello-world/directory/logs/20260801-learning-log.html'
}
finally {
  Pop-Location
}
