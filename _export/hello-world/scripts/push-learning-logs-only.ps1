#Requires -Version 5.1
# 只同步學習日誌 0821–0829 到 Desktop\hello-world 並推上 GitHub（略過桌面捷徑安裝）
$ErrorActionPreference = "Stop"
$branch = "main"
$base = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world"

$root = Join-Path ([Environment]::GetFolderPath("Desktop")) "hello-world"
if (-not (Test-Path -LiteralPath $root)) {
  throw "找不到 $root`n請先：git clone https://github.com/copyshae/hello-world.git Desktop\hello-world"
}

function Save-RemoteFile([string]$Rel) {
  $url = "$base/$($Rel.Replace('\','/'))"
  $path = Join-Path $root ($Rel.Replace("/",[char]92))
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
  Write-Host "下載 $Rel"
  Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing
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
  "directory/202608/20260829-learning-log.html"
)

foreach ($f in $files) { Save-RemoteFile $f }

Set-Location $root
$pagesBranch = "master"
git fetch origin $pagesBranch 2>$null
if ((git branch --show-current).Trim() -ne $pagesBranch) {
  git checkout $pagesBranch 2>$null
  if ($LASTEXITCODE -ne 0) { git checkout -B $pagesBranch "origin/$pagesBranch" }
}
git pull origin $pagesBranch 2>$null

Write-Host ""
Write-Host "=== git status（應看到 0821–0829 等新檔）==="
git add directory/index.html directory/learning-log.html directory/202608/
git status --short

$pending = git status --porcelain
if (-not $pending) {
  Write-Host ""
  Write-Host "[警告] 沒有任何變更可提交。可能下載失敗或檔案已相同。" -ForegroundColor Yellow
  git log -1 --oneline
  exit 1
}

git commit -m "學習日誌 0821–0829：14樣／七習慣／看書文件／弟子規／盛德KTV"
Write-Host ""
Write-Host "=== 推上 GitHub ==="
git push origin $pagesBranch
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "[錯誤] git push 失敗。請重新登入 GitHub 後再執行：git push origin master" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "=== 成功 ===" -ForegroundColor Green
git log -1 --oneline
Write-Host ""
Write-Host "等 1–2 分鐘後開啟："
Write-Host "  https://copyshae.github.io/hello-world/directory/202608/index.html"
Write-Host "  最上方應為 20260829"
