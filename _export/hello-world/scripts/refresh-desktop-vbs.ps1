#Requires -Version 5.1
# 覆寫桌面捷徑 + 快速啟動器 + ps1 本體
# No single-quotes (avoids Windows PowerShell string terminator bugs).
param([switch]$ShowTip)

$ErrorActionPreference = "Stop"
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/launch-efficiency-459a" }
$base = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts"
$expectedBuild = "20260818-fast5"
$desk = [Environment]::GetFolderPath("Desktop")
$utf16 = New-Object System.Text.UnicodeEncoding $false, $true
$utf8Bom = New-Object System.Text.UTF8Encoding $true
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$psLaunch = "powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File"

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
    if ($MustContain -and $MustContain.Count -gt 0) {
      foreach ($needle in $MustContain) {
        if ($text -notlike "*$needle*") {
          throw "Downloaded $Name missing marker: $needle"
        }
      }
    }
    $dest = Join-Path $DestDir $Name
    [System.IO.File]::WriteAllText($dest, $text, $utf8Bom)
    Write-Host ("  OK {0}" -f $dest)
    return $dest
  } finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
  }
}

function Make-VbsLaunch([string]$ps1Rel, [string]$workSub) {
  if ($workSub) {
    return @"
Set sh = CreateObject("WScript.Shell")
desk = sh.SpecialFolders("Desktop")
ps1 = desk & "\$ps1Rel"
cmd = "$psLaunch """ & ps1 & """ -WorkDir """ & desk & "\$workSub"""
sh.Run cmd, 0, False
"@
  }
  return @"
Set sh = CreateObject("WScript.Shell")
desk = sh.SpecialFolders("Desktop")
ps1 = desk & "\$ps1Rel"
cmd = "$psLaunch """ & ps1 & """"
sh.Run cmd, 0, False
"@
}

$graderDir = Join-Path $desk "MathGradingApp"
$deskAppDir = Join-Path $desk "習作台程式"
$hubDir = Join-Path $desk "習作工具程式"
New-Item -ItemType Directory -Force -Path $graderDir, $deskAppDir, $hubDir | Out-Null

Save-RemotePs1 "math-homework-grader-app.ps1" $graderDir @($expectedBuild, "ChatPlayground批")
Save-RemotePs1 "teacher-desk-app.ps1" $deskAppDir @($expectedBuild, "從批改進度檔同步")
Save-RemotePs1 "launch-grader.ps1" $graderDir @("出現主視窗後此畫面會自動關閉")
Save-RemotePs1 "launch-teacher-desk.ps1" $deskAppDir @("出現主視窗後此畫面會自動關閉")
Save-RemotePs1 "launch-homework-apps.ps1" $hubDir @("習作工具")

Save-Utf16 (Join-Path $desk "習作工具.vbs") (Make-VbsLaunch "習作工具程式\launch-homework-apps.ps1" "")
Save-Utf16 (Join-Path $desk "習作批改.vbs") (Make-VbsLaunch "MathGradingApp\launch-grader.ps1" "MathGrading")
Save-Utf16 (Join-Path $desk "習作台.vbs") (Make-VbsLaunch "習作台程式\launch-teacher-desk.ps1" "習作台資料")
Save-Utf16 (Join-Path $graderDir "launch.vbs") (Make-VbsLaunch "MathGradingApp\launch-grader.ps1" "MathGrading")
Save-Utf16 (Join-Path $deskAppDir "啟動習作台.vbs") (Make-VbsLaunch "習作台程式\launch-teacher-desk.ps1" "習作台資料")

$notePath = Join-Path $desk "習作程式版本.txt"
$note = @(
  "更新時間：$stamp"
  "分支：$branch"
  "版本：$expectedBuild"
  ""
  "建議只留一個捷徑：習作工具.vbs"
  "啟動會先顯示「正在啟動…」（不再無反應等很久）"
  "標題列應含 [$expectedBuild]"
) -join "`r`n"
[System.IO.File]::WriteAllText($notePath, $note, $utf8Bom)

Write-Host ""
Write-Host "OK — 請雙擊桌面「習作工具.vbs」"
Write-Host $notePath

if ($ShowTip) {
  Add-Type -AssemblyName System.Windows.Forms
  [void][System.Windows.Forms.MessageBox]::Show(
    "已更新。請雙擊「習作工具.vbs」選程式。`n啟動時會先顯示「正在啟動…」。",
    "桌面習作程式",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
  )
}
