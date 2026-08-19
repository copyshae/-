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
  @{ Src = 'directory\apps\math-grader'; Dst = 'directory\apps\math-grader' },
  @{ Src = 'directory\apps\scan-equip'; Dst = 'directory\apps\scan-equip' },
  @{ Src = 'directory\202608\20260819-learning-log.html'; Dst = 'directory\202608\20260819-learning-log.html' },
  @{ Src = 'directory\202608\index.html'; Dst = 'directory\202608\index.html' },
  @{ Src = 'directory\index.html'; Dst = 'directory\index.html' },
  @{ Src = 'scripts\teacher-desk-app.ps1'; Dst = 'scripts\teacher-desk-app.ps1' },
  @{ Src = 'scripts\install-teacher-desk.ps1'; Dst = 'scripts\install-teacher-desk.ps1' },
  @{ Src = 'scripts\README-teacher-desk.md'; Dst = 'scripts\README-teacher-desk.md' },
  @{ Src = 'scripts\math-homework-grader-app.ps1'; Dst = 'scripts\math-homework-grader-app.ps1' },
  @{ Src = 'scripts\install-math-homework-grader.ps1'; Dst = 'scripts\install-math-homework-grader.ps1' },
  @{ Src = 'scripts\README-math-homework-grader.md'; Dst = 'scripts\README-math-homework-grader.md' },
  @{ Src = 'scripts\install-desktop-apps.ps1'; Dst = 'scripts\install-desktop-apps.ps1' }
)

foreach ($p in $pairs) {
  $from = Join-Path $here $p.Src
  if (-not (Test-Path -LiteralPath $from)) {
    Write-Host "略過（沒有）：$($p.Src)"
    continue
  }
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

$rulesSrc = Join-Path $here '.cursor\rules'
if (Test-Path -LiteralPath $rulesSrc) {
  $rules = Join-Path $dest '.cursor\rules'
  New-Item -ItemType Directory -Force -Path $rules | Out-Null
  Copy-Item -LiteralPath (Join-Path $rulesSrc '*') -Destination $rules -Force -ErrorAction SilentlyContinue
}

Push-Location $dest
try {
  git add directory/apps/teacher-desk directory/apps/math-grader directory/apps/scan-equip `
    directory/202608/20260819-learning-log.html directory/202608/index.html directory/index.html `
    scripts/teacher-desk-app.ps1 scripts/install-teacher-desk.ps1 scripts/README-teacher-desk.md `
    scripts/math-homework-grader-app.ps1 scripts/install-math-homework-grader.ps1 scripts/README-math-homework-grader.md `
    scripts/install-desktop-apps.ps1 .cursor/rules 2>$null
  git status --short
  $msg = 'Add 20260819 learning log: scan-equip live and CSV negative import.'
  git commit -m $msg
  git push origin HEAD
  Write-Host '完成。'
  Write-Host '請再跑：powershell -ExecutionPolicy Bypass -File .\scripts\install-desktop-apps.ps1'
  Write-Host '習作批改：Gemini金鑰 →「Gemini自動批」或「連續自動批」（答案可選）。'
} finally {
  Pop-Location
}
