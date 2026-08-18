#Requires -Version 5.1
# 覆寫桌面兩個捷徑：習作批改.vbs、習作台.vbs（並更新對應 ps1）
# No single-quotes (avoids Windows PowerShell string terminator bugs).
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/textbook-grade-format-459a" }
$base = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts"
$expectedBuild = "20260818-sync"
$desk = [Environment]::GetFolderPath("Desktop")
$utf16 = New-Object System.Text.UnicodeEncoding $false, $true
$utf8Bom = New-Object System.Text.UTF8Encoding $true
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Save-Utf16([string]$Path, [string]$Text) {
  [System.IO.File]::WriteAllText($Path, $Text, $utf16)
}

function Save-RemotePs1([string]$Name, [string]$DestDir, [string[]]$MustContain) {
  New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
  Write-Host "Download $Name ..."
  $q = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $tmp = Join-Path $env:TEMP ("hw-vbs-" + [guid]::NewGuid().ToString() + ".ps1")
  try {
    Invoke-WebRequest -Uri "$base/$Name`?t=$q" -OutFile $tmp -UseBasicParsing
    $bytes = [System.IO.File]::ReadAllBytes($tmp)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) {
      $text = $text.Substring(1)
    }
    foreach ($needle in $MustContain) {
      if ($text -notlike "*$needle*") {
        throw "Downloaded $Name missing marker: $needle (GitHub may still be old; retry in 1 min)"
      }
    }
    $dest = Join-Path $DestDir $Name
    [System.IO.File]::WriteAllText($dest, $text, $utf8Bom)
    $info = Get-Item -LiteralPath $dest
    Write-Host ("  OK {0} ({1} bytes, {2})" -f $dest, $info.Length, $info.LastWriteTime)
    return $dest
  } finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
  }
}

$graderDir = Join-Path $desk "MathGradingApp"
$deskAppDir = Join-Path $desk "習作台程式"
$graderPs1 = Save-RemotePs1 "math-homework-grader-app.ps1" $graderDir @(
  $expectedBuild, "ChatPlayground批", "③ 貼上自動批閱"
)
$deskPs1 = Save-RemotePs1 "teacher-desk-app.ps1" $deskAppDir @(
  $expectedBuild, "從批改進度檔同步"
)

$graderVbs = @"
Set sh = CreateObject("WScript.Shell")
desk = sh.SpecialFolders("Desktop")
ps1 = desk & "\MathGradingApp\math-homework-grader-app.ps1"
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File """ & ps1 & """ -WorkDir """ & desk & "\MathGrading"""
sh.Run cmd, 0, False
"@
$deskVbs = @"
Set sh = CreateObject("WScript.Shell")
desk = sh.SpecialFolders("Desktop")
ps1 = desk & "\習作台程式\teacher-desk-app.ps1"
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File """ & ps1 & """ -WorkDir """ & desk & "\習作台資料"""
sh.Run cmd, 0, False
"@

Save-Utf16 (Join-Path $desk "習作批改.vbs") $graderVbs
Save-Utf16 (Join-Path $desk "習作台.vbs") $deskVbs
Save-Utf16 (Join-Path $graderDir "launch.vbs") $graderVbs
Save-Utf16 (Join-Path $deskAppDir "啟動習作台.vbs") $deskVbs

$notePath = Join-Path $desk "習作程式版本.txt"
$note = @(
  "更新時間：$stamp"
  "分支：$branch"
  "版本：$expectedBuild"
  ""
  "請用這兩個捷徑（不要用舊的 習作台.cmd）："
  "  習作批改.vbs"
  "  習作台.vbs"
  ""
  "關掉舊視窗後再雙擊。新視窗標題列應含 [$expectedBuild]"
  "習作批改：綠色 ChatPlayground批、下方 ③ 貼上自動批閱"
  "習作台：右側 從批改進度檔同步"
  ""
  "ps1 路徑："
  "  $graderPs1"
  "  $deskPs1"
) -join "`r`n"
[System.IO.File]::WriteAllText($notePath, $note, $utf8Bom)

Write-Host ""
Write-Host "OK — wrote desktop version note: $notePath"
Write-Host "Close OLD windows, then double-click 習作批改.vbs / 習作台.vbs"

[void][System.Windows.Forms.MessageBox]::Show(
  @"
已更新 ps1 + vbs（$stamp）

1. 先關掉所有舊的習作批改／習作台視窗
2. 雙擊桌面「習作批改.vbs」「習作台.vbs」
   （不要用 習作台.cmd 或 MathGrading 舊捷徑）

新視窗標題列要有 [$expectedBuild]
習作批改：ChatPlayground批 + ③ 貼上自動批閱
習作台：從批改進度檔同步

詳細寫在桌面「習作程式版本.txt」
"@,
  "桌面習作程式已更新",
  [System.Windows.Forms.MessageBoxButtons]::OK,
  [System.Windows.Forms.MessageBoxIcon]::Information
)
