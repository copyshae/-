# 把習作台修正套用到本機 hello-world（手機可見性 + 桌面啟動修復）。
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
    (Join-Path $dest 'scripts'), `
    (Join-Path $dest '.cursor\rules') | Out-Null

  $files = @(
    'directory\apps\teacher-desk\index.html',
    'directory\apps\teacher-desk\manifest.json',
    'directory\apps\teacher-desk\sw.js',
    'directory\apps\teacher-desk\share.html',
    'directory\apps\teacher-desk\icon-180.png',
    'directory\apps\teacher-desk\icon-192.png',
    'directory\apps\teacher-desk\icon-512.png',
    'directory\index.html',
    'scripts\README-teacher-desk.md',
    'scripts\install-teacher-desk.ps1',
    'scripts\teacher-desk-app.ps1',
    'scripts\install-desktop-apps.ps1',
    '.cursor\rules\teacher-desk-mobile.mdc'
  )
  foreach ($rel in $files) {
    $from = Join-Path $src $rel
    if (Test-Path -LiteralPath $from) {
      Copy-Item -LiteralPath $from -Destination (Join-Path $dest $rel) -Force
    }
  }

  git add directory/apps/teacher-desk directory/index.html scripts `
    .cursor/rules/teacher-desk-mobile.mdc
  git status
  git commit -m '修復習作台：桌面 .cmd／.vbs 啟動與手機加入主畫面引導。'
  git push origin master

  Write-Host ''
  Write-Host '正在重新安裝桌面啟動器…'
  powershell -ExecutionPolicy Bypass -File .\scripts\install-teacher-desk.ps1
  Write-Host ''
  Write-Host '完成。請雙擊桌面 TeacherDesk-start.cmd'
  Write-Host '手機：https://copyshae.github.io/hello-world/directory/apps/teacher-desk/'
}
finally {
  Pop-Location
}
