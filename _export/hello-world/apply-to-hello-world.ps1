#Requires -Version 5.1
# 把本匯出目錄套用到本機 Desktop\hello-world 並推上 GitHub Pages（master）
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
  @{ Src = 'directory\apps\daily-14'; Dst = 'directory\apps\daily-14' },
  @{ Src = 'directory\apps\habits-7'; Dst = 'directory\apps\habits-7' },
  @{ Src = 'directory\apps\doc-reader'; Dst = 'directory\apps\doc-reader' },
  @{ Src = 'directory\index.html'; Dst = 'directory\index.html' },
  @{ Src = 'directory\learning-log.html'; Dst = 'directory\learning-log.html' },
  @{ Src = 'directory\202608\index.html'; Dst = 'directory\202608\index.html' },
  @{ Src = 'directory\202608\20260821-learning-log.html'; Dst = 'directory\202608\20260821-learning-log.html' },
  @{ Src = 'directory\202608\20260822-learning-log.html'; Dst = 'directory\202608\20260822-learning-log.html' },
  @{ Src = 'directory\202608\20260823-learning-log.html'; Dst = 'directory\202608\20260823-learning-log.html' },
  @{ Src = 'scripts\teacher-desk-app.ps1'; Dst = 'scripts\teacher-desk-app.ps1' },
  @{ Src = 'scripts\install-teacher-desk.ps1'; Dst = 'scripts\install-teacher-desk.ps1' },
  @{ Src = 'scripts\README-teacher-desk.md'; Dst = 'scripts\README-teacher-desk.md' },
  @{ Src = 'scripts\math-homework-grader-app.ps1'; Dst = 'scripts\math-homework-grader-app.ps1' },
  @{ Src = 'scripts\install-math-homework-grader.ps1'; Dst = 'scripts\install-math-homework-grader.ps1' },
  @{ Src = 'scripts\README-math-homework-grader.md'; Dst = 'scripts\README-math-homework-grader.md' },
  @{ Src = 'scripts\scan-equip-app.ps1'; Dst = 'scripts\scan-equip-app.ps1' },
  @{ Src = 'scripts\install-scan-equip.ps1'; Dst = 'scripts\install-scan-equip.ps1' },
  @{ Src = 'scripts\README-scan-equip.md'; Dst = 'scripts\README-scan-equip.md' },
  @{ Src = 'scripts\install-desktop-apps.ps1'; Dst = 'scripts\install-desktop-apps.ps1' },
  @{ Src = 'scripts\pull-export-from-dash-repo.ps1'; Dst = 'scripts\pull-export-from-dash-repo.ps1' }
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

# doc-reader / habits-7 可能只在 dash 的 docs，從 _export 同層補拷（若匯出包未含目錄）
$dashRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $here)) ''
if (Test-Path -LiteralPath (Join-Path $dashRoot 'docs\doc-reader')) {
  $drFrom = Join-Path $dashRoot 'docs\doc-reader'
  $drTo = Join-Path $dest 'directory\apps\doc-reader'
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $drTo) | Out-Null
  Copy-Item -LiteralPath $drFrom -Destination (Split-Path -Parent $drTo) -Recurse -Force
  Write-Host "已從 docs\doc-reader 補拷看書／看文件"
}
if (Test-Path -LiteralPath (Join-Path $dashRoot 'docs\habits-7')) {
  $h7From = Join-Path $dashRoot 'docs\habits-7'
  $h7To = Join-Path $dest 'directory\apps\habits-7'
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $h7To) | Out-Null
  Copy-Item -LiteralPath $h7From -Destination (Split-Path -Parent $h7To) -Recurse -Force
  Write-Host "已從 docs\habits-7 補拷七習慣"
}

$rulesSrc = Join-Path $here '.cursor\rules'
if (Test-Path -LiteralPath $rulesSrc) {
  $rules = Join-Path $dest '.cursor\rules'
  New-Item -ItemType Directory -Force -Path $rules | Out-Null
  Copy-Item -LiteralPath (Join-Path $rulesSrc '*') -Destination $rules -Force -ErrorAction SilentlyContinue
}

Push-Location $dest
try {
  $pagesBranch = 'master'
  try { git fetch origin $pagesBranch 2>$null | Out-Null } catch {}
  $cur = (& git branch --show-current 2>$null).Trim()
  if ($cur -ne $pagesBranch) {
    git checkout $pagesBranch 2>$null
    if ($LASTEXITCODE -ne 0) { git checkout -B $pagesBranch origin/$pagesBranch 2>$null }
  }
  git pull origin $pagesBranch 2>$null

  git add directory/apps/teacher-desk directory/apps/math-grader directory/apps/scan-equip `
    directory/apps/daily-14 directory/apps/habits-7 directory/apps/doc-reader `
    directory/index.html directory/learning-log.html `
    directory/202608/index.html directory/202608/20260821-learning-log.html `
    directory/202608/20260822-learning-log.html directory/202608/20260823-learning-log.html `
    scripts/ .cursor/rules 2>$null
  git status --short
  if (git diff --cached --quiet) {
    Write-Host "沒有變更可提交。"
  } else {
    $msg = '同步學習日誌 0821–0823＋habits-7／doc-reader／daily-14（電腦套用）'
    git commit -m $msg
    git push origin $pagesBranch
    Write-Host '已推上 hello-world Pages。'
  }
  Write-Host ''
  Write-Host '最新日誌：https://copyshae.github.io/hello-world/directory/202608/20260823-learning-log.html'
  Write-Host '七習慣：https://copyshae.github.io/hello-world/directory/apps/habits-7/'
  Write-Host '看書文件：https://copyshae.github.io/hello-world/directory/apps/doc-reader/'
  Write-Host '14樣功課：https://copyshae.github.io/hello-world/directory/apps/daily-14/'
  Write-Host ''
  Write-Host '（手機免開電腦也可用 dash 鏡射：https://copyshae.github.io/-/directory/202608/）'
} finally {
  Pop-Location
}
