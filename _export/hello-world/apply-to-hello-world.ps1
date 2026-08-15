# 把習作台「手機主畫面可見性」修正套用到本機 hello-world。
# 用法（在此倉庫根目錄）：
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
  New-Item -ItemType Directory -Force -Path `
    (Join-Path $dest 'directory\apps\teacher-desk'), `
    (Join-Path $dest 'scripts') | Out-Null

  $files = @(
    'directory\apps\teacher-desk\index.html',
    'directory\apps\teacher-desk\manifest.json',
    'directory\apps\teacher-desk\sw.js',
    'directory\apps\teacher-desk\share.html',
    'directory\apps\teacher-desk\icon-180.png',
    'directory\apps\teacher-desk\icon-192.png',
    'directory\apps\teacher-desk\icon-512.png',
    'directory\index.html',
    'scripts\README-teacher-desk.md'
  )
  foreach ($rel in $files) {
    Copy-Item (Join-Path $src $rel) (Join-Path $dest $rel) -Force
  }

  git add directory/apps/teacher-desk directory/index.html scripts/README-teacher-desk.md
  git commit -m '加強習作台手機可見性：加入主畫面引導與安裝提示。'
  git push origin master
  Write-Host '完成：https://copyshae.github.io/hello-world/directory/apps/teacher-desk/'
  Write-Host '手機請用 Safari／Chrome 重新打開該頁 → 加入主畫面 → 桌面找「習作台」。'
}
finally {
  Pop-Location
}
