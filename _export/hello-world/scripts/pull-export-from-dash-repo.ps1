#Requires -Version 5.1
# Pull latest export from copyshae/- branch into Desktop\hello-world and reinstall.
# No single-quotes (avoids Windows PowerShell string terminator bugs).
$ErrorActionPreference = "Stop"
# 預設 main；尚未合併時可：$env:DASH_EXPORT_BRANCH='cursor/textbook-grade-format-459a'
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "main" }
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
  "directory/apps/index.html",
  "directory/202608/index.html",
  "directory/202608/20260818-learning-log.html",
  "scripts/sync-docs-from-export.sh"
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
  git add directory/apps/math-grader directory/apps/teacher-desk directory/apps/index.html `
    directory/202608/index.html directory/202608/20260818-learning-log.html `
    scripts/install-desktop-apps.ps1 `
    scripts/math-homework-grader-app.ps1 scripts/install-math-homework-grader.ps1 `
    scripts/teacher-desk-app.ps1 scripts/install-teacher-desk.ps1 2>$null
  $pending = git status --porcelain
  if ($pending) {
    git commit -m "手機習作批改／習作台：ChatPlayground AI 預設批閱＋國中課本形式"
    git push origin HEAD
    Write-Host "Pushed. Phone URL:"
    Write-Host "https://copyshae.github.io/hello-world/directory/apps/math-grader/"
    Write-Host "https://copyshae.github.io/hello-world/directory/apps/teacher-desk/"
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
Write-Host "DONE. Close old grader/desk window, then open desktop shortcut again."
Write-Host "Phone: ChatPlayground AI 自動批閱 → 貼回覆套用。Teacher desk: sync level → copy group message."
Write-Host "Desktop: Gemini key -> Gemini auto grade"
