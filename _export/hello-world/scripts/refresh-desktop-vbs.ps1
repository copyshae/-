#Requires -Version 5.1
# 覆寫桌面兩個捷徑：習作批改.vbs、習作台.vbs（並更新對應 ps1）
# No single-quotes (avoids Windows PowerShell string terminator bugs).
$ErrorActionPreference = "Stop"
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/textbook-grade-format-459a" }
$base = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts"
$desk = [Environment]::GetFolderPath("Desktop")
$utf16 = New-Object System.Text.UnicodeEncoding $false, $true
$utf8Bom = New-Object System.Text.UTF8Encoding $true

function Save-Utf16([string]$Path, [string]$Text) {
  [System.IO.File]::WriteAllText($Path, $Text, $utf16)
}

function Save-RemotePs1([string]$Name, [string]$DestDir) {
  New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
  Write-Host "Download $Name"
  $tmp = Join-Path $env:TEMP ("hw-vbs-" + [guid]::NewGuid().ToString() + ".ps1")
  try {
    Invoke-WebRequest -Uri "$base/$Name" -OutFile $tmp -UseBasicParsing
    $bytes = [System.IO.File]::ReadAllBytes($tmp)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) {
      $text = $text.Substring(1)
    }
    [System.IO.File]::WriteAllText((Join-Path $DestDir $Name), $text, $utf8Bom)
  } finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
  }
}

$graderDir = Join-Path $desk "MathGradingApp"
$deskAppDir = Join-Path $desk "習作台程式"
Save-RemotePs1 "math-homework-grader-app.ps1" $graderDir
Save-RemotePs1 "teacher-desk-app.ps1" $deskAppDir

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

Write-Host "OK"
Write-Host (Join-Path $desk "習作批改.vbs")
Write-Host (Join-Path $desk "習作台.vbs")
Write-Host "Close OLD grader window first, then double-click 習作批改.vbs"
Write-Host "New UI: title has ChatPlayground, green ChatPlayground批 button, section ③ paste box"
