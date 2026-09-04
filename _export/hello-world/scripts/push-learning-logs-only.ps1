#Requires -Version 5.1
# Sync learning logs 0820-0906 to Desktop\hello-world and push GitHub Pages (master).
# ASCII-safe for Windows PowerShell 5.1 (save as UTF-8 with BOM).
$ErrorActionPreference = "Stop"
$branch = "main"
$base = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world"

$root = Join-Path ([Environment]::GetFolderPath("Desktop")) "hello-world"
if (-not (Test-Path -LiteralPath $root)) {
  throw "hello-world not found: $root. Run: git clone https://github.com/copyshae/hello-world.git Desktop\hello-world"
}

function Save-RemoteFile([string]$Rel) {
  $url = "$base/$($Rel.Replace('\','/'))"
  $path = Join-Path $root ($Rel.Replace("/",[char]92))
  $parent = Split-Path -Parent $path
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  Write-Host "Download $Rel"
  $tmp = Join-Path $env:TEMP ("hw-log-" + [guid]::NewGuid().ToString() + ".bin")
  try {
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    [System.IO.File]::WriteAllBytes($path, [System.IO.File]::ReadAllBytes($tmp))
  } finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
  }
}

$files = @(
  "directory/index.html",
  "directory/learning-log.html",
  "directory/202608/index.html",
  "directory/202608/20260820-learning-log.html",
  "directory/202608/20260821-learning-log.html",
  "directory/202608/20260822-learning-log.html",
  "directory/202608/20260823-learning-log.html",
  "directory/202608/20260824-learning-log.html",
  "directory/202608/20260825-learning-log.html",
  "directory/202608/20260826-learning-log.html",
  "directory/202608/20260827-learning-log.html",
  "directory/202608/20260828-learning-log.html",
  "directory/202608/20260829-learning-log.html",
  "directory/202608/20260830-learning-log.html",
  "directory/202608/20260831-learning-log.html",
  "directory/202609/index.html",
  "directory/202609/20260901-learning-log.html",
  "directory/202609/20260902-learning-log.html",
  "directory/202609/20260903-learning-log.html",
  "directory/202609/20260904-learning-log.html",
  "directory/202609/20260905-learning-log.html",
  "directory/202609/20260906-learning-log.html"
)

foreach ($f in $files) { Save-RemoteFile $f }

Set-Location $root
$pagesBranch = "master"
git fetch origin $pagesBranch 2>$null
$cur = (& git branch --show-current 2>$null)
if ($cur) { $cur = $cur.Trim() }
if ($cur -ne $pagesBranch) {
  git checkout $pagesBranch 2>$null
  if ($LASTEXITCODE -ne 0) { git checkout -B $pagesBranch "origin/$pagesBranch" }
}
git pull origin $pagesBranch 2>$null

Write-Host ""
Write-Host "=== git status (expect 0830-0906 logs) ==="
git add directory/index.html directory/learning-log.html directory/202608/ directory/202609/
git status --short

$pending = git status --porcelain
if (-not $pending) {
  Write-Host ""
  Write-Host "[WARN] No changes to commit. Files may already match remote." -ForegroundColor Yellow
  git log -1 --oneline
  exit 1
}

$msg = "learning log 0830-0906 one topic per day after 0829"
git commit -m $msg
Write-Host ""
Write-Host "=== git push origin master ==="
git push origin $pagesBranch
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "[ERROR] git push failed. Try: gh auth login ; git push origin master" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "[OK] Pushed. Latest: https://copyshae.github.io/hello-world/directory/202609/20260906-learning-log.html"
git log -1 --oneline
