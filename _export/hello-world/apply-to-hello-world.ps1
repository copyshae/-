#Requires -Version 5.1
# 把本匯出目錄套用到本機 Desktop\hello-world 並推上 GitHub Pages
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path ([Environment]::GetFolderPath('Desktop')) 'hello-world'
if (-not (Test-Path -LiteralPath $dest)) {
  throw "找不到 $dest。請先 clone copyshae/hello-world 到桌面。"
}

$pairs = @(
  @{ Src = 'directory\apps\teacher-desk'; Dst = 'directory\apps\teacher-desk' },
  @{ Src = 'scripts\teacher-desk-app.ps1'; Dst = 'scripts\teacher-desk-app.ps1' },
  @{ Src = 'scripts\install-teacher-desk.ps1'; Dst = 'scripts\install-teacher-desk.ps1' },
  @{ Src = 'scripts\README-teacher-desk.md'; Dst = 'scripts\README-teacher-desk.md' }
)

foreach ($p in $pairs) {
  $from = Join-Path $here $p.Src
  $to = Join-Path $dest $p.Dst
  $parent = Split-Path -Parent $to
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  if (Test-Path -LiteralPath $from -PathType Container) {
    Copy-Item -LiteralPath $from -Destination $parent -Recurse -Force
  } else {
    Copy-Item -LiteralPath $from -Destination $to -Force
  }
  Write-Host "已複製 $($p.Src)"
}

if (Test-Path -LiteralPath (Join-Path $here '.cursor\rules\teacher-desk.mdc')) {
  $rules = Join-Path $dest '.cursor\rules'
  New-Item -ItemType Directory -Force -Path $rules | Out-Null
  Copy-Item -LiteralPath (Join-Path $here '.cursor\rules\teacher-desk.mdc') -Destination (Join-Path $rules 'teacher-desk.mdc') -Force
}

Push-Location $dest
try {
  git add directory/apps/teacher-desk scripts/teacher-desk-app.ps1 scripts/install-teacher-desk.ps1 scripts/README-teacher-desk.md .cursor/rules/teacher-desk.mdc 2>$null
  git status --short
  $msg = '強化習作台：掃描檔名自動座號、桌面掃描匯入夾處理與班級資料互通。'
  git commit -m $msg
  git push origin HEAD
  Write-Host '完成。線上頁：https://copyshae.github.io/hello-world/directory/apps/teacher-desk/'
  Write-Host '本機請再跑：powershell -ExecutionPolicy Bypass -File .\scripts\install-teacher-desk.ps1'
} finally {
  Pop-Location
}
