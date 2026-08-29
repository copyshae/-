#Requires -Version 5.1
# Pull latest export from copyshae/- branch into Desktop\hello-world and reinstall.
# No single-quotes (avoids Windows PowerShell string terminator bugs).
$ErrorActionPreference = "Stop"
$branch = "main"
$base = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here
if ((Split-Path -Leaf $here) -eq "scripts") {
  $root = Split-Path -Parent $here
}
if (-not (Test-Path -LiteralPath (Join-Path $root "directory"))) {
  $root = Join-Path ([Environment]::GetFolderPath("Desktop")) "hello-world"
}
if (-not (Test-Path -LiteralPath $root)) {
  throw "hello-world not found: $root"
}

Write-Host "Target: $root"
Write-Host "Source: $base"
Write-Host ""

function Save-RemoteFile([string]$Rel) {
  $relUrl = $Rel.Replace([string][char]92, "/")
  $url = "$base/$relUrl"
  Write-Host "Download $Rel"
  $relPath = $Rel.Replace("/", [string][char]92)
  $path = Join-Path $root $relPath
  $parent = Split-Path -Parent $path
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  $tmp = Join-Path $env:TEMP ("hw-pull-" + [guid]::NewGuid().ToString() + ".bin")
  try {
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    $bytes = [System.IO.File]::ReadAllBytes($tmp)
    if ($Rel -like "*.ps1") {
      $text = [System.Text.Encoding]::UTF8.GetString($bytes)
      if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) {
        $text = $text.Substring(1)
      }
      $utf8Bom = New-Object System.Text.UTF8Encoding $true
      [System.IO.File]::WriteAllText($path, $text, $utf8Bom)
    } else {
      [System.IO.File]::WriteAllBytes($path, $bytes)
    }
  } finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
  }
  Write-Host "  Saved $path"
}

$files = @(
  "scripts/install-desktop-apps.ps1",
  "scripts/install-math-homework-grader.ps1",
  "scripts/math-homework-grader-app.ps1",
  "scripts/README-math-homework-grader.md",
  "scripts/install-teacher-desk.ps1",
  "scripts/teacher-desk-app.ps1",
  "scripts/README-teacher-desk.md",
  "directory/apps/math-grader/index.html",
  "directory/apps/math-grader/sw.js",
  "directory/apps/math-grader/manifest.json",
  "directory/apps/math-grader/share.html",
  "directory/apps/math-grader/icon-180.png",
  "directory/apps/math-grader/icon-192.png",
  "directory/apps/math-grader/icon-512.png",
  "directory/apps/teacher-desk/index.html",
  "directory/apps/teacher-desk/sw.js",
  "directory/apps/teacher-desk/manifest.json",
  "directory/apps/teacher-desk/share.html",
  "directory/apps/teacher-desk/icon-180.png",
  "directory/apps/teacher-desk/icon-192.png",
  "directory/apps/teacher-desk/icon-512.png",
  "directory/apps/scan-equip/index.html",
  "directory/apps/scan-equip/sw.js",
  "directory/apps/scan-equip/manifest.json",
  "directory/apps/scan-equip/share.html",
  "directory/apps/scan-equip/icon-180.png",
  "directory/apps/scan-equip/icon-192.png",
  "directory/apps/scan-equip/icon-512.png",
  "directory/apps/daily-14/index.html",
  "directory/apps/daily-14/sw.js",
  "directory/apps/daily-14/manifest.json",
  "directory/apps/daily-14/icon-180.png",
  "directory/apps/daily-14/icon-192.png",
  "directory/apps/daily-14/icon-512.png",
  "directory/apps/habits-7/index.html",
  "directory/apps/habits-7/sw.js",
  "directory/apps/habits-7/manifest.json",
  "directory/apps/habits-7/icon-180.png",
  "directory/apps/habits-7/icon-192.png",
  "directory/apps/habits-7/icon-512.png",
  "directory/apps/doc-reader/index.html",
  "directory/apps/doc-reader/sw.js",
  "directory/apps/doc-reader/tts-voices.js",
  "directory/apps/doc-reader/manifest.json",
  "directory/apps/doc-reader/icon-180.png",
  "directory/apps/doc-reader/icon-192.png",
  "directory/apps/doc-reader/icon-512.png",
  "directory/index.html",
  "directory/learning-log.html",
  "directory/202608/index.html",
  "directory/202608/20260821-learning-log.html",
  "directory/202608/20260822-learning-log.html",
  "directory/202608/20260823-learning-log.html",
  "directory/202608/20260824-learning-log.html",
  "directory/202608/20260825-learning-log.html",
  "directory/202608/20260826-learning-log.html",
  "directory/202608/20260827-learning-log.html",
  "directory/202608/20260828-learning-log.html",
  "directory/202608/20260829-learning-log.html",
  "directory/202608/20260820-learning-log.html",
  "directory/apps/dizigui-41/index.html",
  "directory/apps/dizigui-41/sw.js",
  "directory/apps/dizigui-41/manifest.json",
  "directory/apps/dizigui-41/share.html",
  "directory/apps/dizigui-41/episodes.js",
  "directory/apps/dizigui-41/dizigui-icon-180.png",
  "directory/apps/dizigui-41/dizigui-icon-192.png",
  "directory/apps/dizigui-41/dizigui-icon-512.png",
  "directory/apps/taiyang-music/index.html",
  "directory/apps/taiyang-music/sw.js",
  "directory/apps/taiyang-music/manifest.json",
  "directory/apps/taiyang-music/share.html",
  "directory/apps/taiyang-music/catalog.json",
  "scripts/install-scan-equip.ps1",
  "scripts/scan-equip-app.ps1",
  "scripts/README-scan-equip.md"
)

foreach ($f in $files) {
  try {
    Save-RemoteFile $f
  } catch {
    Write-Host ("Skip " + $f + " : " + $_.Exception.Message)
  }
}

Write-Host ""
Write-Host "Reset MathGrading geminiModel if old 2.0/1.5..."
$mg = Join-Path ([Environment]::GetFolderPath("Desktop")) "MathGrading"
$settingsPath = Join-Path $mg "settings.json"
if (Test-Path -LiteralPath $settingsPath) {
  try {
    $raw = [System.IO.File]::ReadAllText($settingsPath)
    if ($raw -match "gemini-2\.0|gemini-1\.5") {
      $raw2 = $raw.Replace("gemini-2.0-flash", "gemini-2.5-flash").Replace("gemini-1.5-flash", "gemini-2.5-flash")
      $utf8Bom = New-Object System.Text.UTF8Encoding $true
      [System.IO.File]::WriteAllText($settingsPath, $raw2, $utf8Bom)
      Write-Host "  settings.json -> gemini-2.5-flash"
    } else {
      Write-Host "  settings.json OK"
    }
  } catch {
    Write-Host ("  skip settings: " + $_.Exception.Message)
  }
}

Write-Host ""
Write-Host "Install desktop shortcuts..."
$install = Join-Path $root "scripts\install-desktop-apps.ps1"
if (-not (Test-Path -LiteralPath $install)) {
  throw "Missing install script: $install"
}
& $install

Write-Host ""
Write-Host "Push hello-world GitHub Pages (math-grader / teacher-desk)..."
Push-Location $root
try {
  # GitHub Pages 使用的預設分支為 master；避免推到 main 導致仍是 404
  $pagesBranch = 'master'
  try { & git fetch origin $pagesBranch 2>$null | Out-Null } catch {}
  $curBranch = (& git branch --show-current 2>$null).Trim()
  if ($curBranch -ne $pagesBranch) {
    try { & git checkout $pagesBranch 2>$null | Out-Null } catch {
      try { & git checkout -B $pagesBranch origin/$pagesBranch 2>$null | Out-Null } catch {}
    }
  }
  $curBranch2 = (& git branch --show-current 2>$null).Trim()
  if ($curBranch2 -ne $pagesBranch) {
    throw ("無法切換到 $pagesBranch（目前為：$curBranch2），已停止以避免推錯分支。")
  }
  try { & git pull origin $pagesBranch 2>$null | Out-Null } catch {}

  git add directory/apps/math-grader directory/apps/teacher-desk directory/apps/scan-equip directory/apps/daily-14 directory/apps/habits-7 directory/apps/doc-reader directory/apps/dizigui-41 directory/apps/taiyang-music `
    directory/index.html directory/learning-log.html `
    directory/202608/index.html directory/202608/20260821-learning-log.html directory/202608/20260822-learning-log.html directory/202608/20260823-learning-log.html directory/202608/20260824-learning-log.html directory/202608/20260825-learning-log.html directory/202608/20260826-learning-log.html directory/202608/20260827-learning-log.html directory/202608/20260828-learning-log.html directory/202608/20260829-learning-log.html directory/202608/20260820-learning-log.html `
    scripts/install-desktop-apps.ps1 `
    scripts/math-homework-grader-app.ps1 scripts/install-math-homework-grader.ps1 `
    scripts/teacher-desk-app.ps1 scripts/install-teacher-desk.ps1 `
    scripts/scan-equip-app.ps1 scripts/install-scan-equip.ps1 scripts/README-scan-equip.md 2>$null
  $pending = git status --porcelain
  if ($pending) {
    git commit -m "學習日誌 0824–0829：弟子規／盛德歌曲 KTV（電腦同步）"
    git push origin HEAD
    Write-Host "Pushed. Phone URL:"
    Write-Host "https://copyshae.github.io/hello-world/directory/apps/habits-7/"
    Write-Host "daily-14 (separate): https://copyshae.github.io/hello-world/directory/apps/daily-14/"
  } else {
    Write-Host "No git changes to push."
  }
} catch {
  Write-Host ("Git push skipped: " + $_.Exception.Message)
  Write-Host "Files are already on disk; you can commit/push hello-world manually."
} finally {
  Pop-Location
}

Write-Host ""
Write-Host "DONE. Close old grader window, then open desktop shortcut again."
Write-Host "Phone: open math-grader URL above, scroll to 批完後續."
Write-Host "Desktop: Gemini key -> Gemini auto grade"
