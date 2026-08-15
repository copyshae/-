#Requires -Version 5.1
<#
  在「桌面\hello-world」直接執行，從 GitHub 分支下載最新匯出檔並安裝桌面程式。
  用法（PowerShell）：
    cd $env:USERPROFILE\Desktop\hello-world
    powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
#>
$ErrorActionPreference = 'Stop'
$branch = 'cursor/teacher-desk-scan-parity-c36c'
$base = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world"

# 若腳本放在 hello-world\scripts，工作根目錄上一级；若在 hello-world 根目錄則用本身
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here
if ((Split-Path -Leaf $here) -eq 'scripts') {
  $root = Split-Path -Parent $here
}
if (-not (Test-Path -LiteralPath (Join-Path $root 'directory'))) {
  # 後援：桌面\hello-world
  $root = Join-Path ([Environment]::GetFolderPath('Desktop')) 'hello-world'
}
if (-not (Test-Path -LiteralPath $root)) {
  throw "找不到 hello-world：$root"
}

Write-Host "目標：$root"
Write-Host "來源：$base"
Write-Host ""

function Get-RemoteText([string]$Rel) {
  $url = "$base/$($Rel.Replace('\','/'))"
  Write-Host "下載 $Rel ..."
  $r = Invoke-WebRequest -Uri $url -UseBasicParsing
  return [string]$r.Content
}

function Save-RemoteFile([string]$Rel) {
  $text = Get-RemoteText $Rel
  $path = Join-Path $root ($Rel.Replace('/', '\'))
  $parent = Split-Path -Parent $path
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  $utf8 = New-Object System.Text.UTF8Encoding $true
  [System.IO.File]::WriteAllText($path, $text, $utf8)
  Write-Host "  → $path"
}

$files = @(
  'scripts/install-desktop-apps.ps1',
  'scripts/install-math-homework-grader.ps1',
  'scripts/math-homework-grader-app.ps1',
  'scripts/README-math-homework-grader.md',
  'scripts/install-teacher-desk.ps1',
  'scripts/teacher-desk-app.ps1',
  'scripts/README-teacher-desk.md',
  'directory/apps/math-grader/index.html',
  'directory/apps/math-grader/sw.js',
  'directory/apps/math-grader/manifest.json',
  'directory/apps/math-grader/share.html'
)

foreach ($f in $files) {
  try {
    Save-RemoteFile $f
  } catch {
    Write-Host "略過 $f ：$($_.Exception.Message)"
  }
}

# teacher-desk 多檔：至少抓 index + sw
foreach ($f in @(
  'directory/apps/teacher-desk/index.html',
  'directory/apps/teacher-desk/sw.js',
  'directory/apps/teacher-desk/manifest.json'
)) {
  try { Save-RemoteFile $f } catch { Write-Host "略過 $f" }
}

Write-Host ""
Write-Host "檔案已更新。重設本機模型設定（避免卡在已下線的 2.0-flash）…"
$mg = Join-Path ([Environment]::GetFolderPath('Desktop')) 'MathGrading'
$settingsPath = Join-Path $mg 'settings.json'
if (Test-Path -LiteralPath $settingsPath) {
  try {
    $raw = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8
    if ($raw -match 'gemini-2\.0|gemini-1\.5') {
      $raw2 = $raw -replace '"geminiModel"\s*:\s*"[^"]*"', '"geminiModel": "gemini-2.5-flash"'
      $utf8 = New-Object System.Text.UTF8Encoding $true
      [System.IO.File]::WriteAllText($settingsPath, $raw2, $utf8)
      Write-Host "  已把 settings.json 的 geminiModel 改成 gemini-2.5-flash"
    } else {
      Write-Host "  settings.json 模型設定 OK"
    }
  } catch {
    Write-Host "  （略過 settings 修正：$($_.Exception.Message)）"
  }
}

Write-Host ""
Write-Host "開始安裝桌面捷徑…"
$install = Join-Path $root 'scripts\install-desktop-apps.ps1'
& $install
Write-Host ""
Write-Host "完成。請關閉舊的「習作批改」視窗，再雙擊桌面 習作批改.vbs"
Write-Host "標題應類似：Gemini 自動批｜對照答案或直接 AI"
Write-Host "然後：Gemini金鑰 → Gemini自動批（不要再用網頁版）"
