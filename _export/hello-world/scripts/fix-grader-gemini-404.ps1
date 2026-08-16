#Requires -Version 5.1
<#
.SYNOPSIS
  一鍵更新桌面習作批改，並確認已含 AQ. 金鑰支援。
#>
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/sync-desk-grader-devices-2663" }
$needBuild = "20260817-aq20"
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$url = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts/math-homework-grader-app.ps1?t=$ts"

$desk = [Environment]::GetFolderPath("Desktop")
$appDir = Join-Path $desk "MathGradingApp"
$work = Join-Path $desk "MathGrading"
New-Item -ItemType Directory -Force -Path $appDir | Out-Null
New-Item -ItemType Directory -Force -Path $work | Out-Null

Write-Host "=== 更新習作批改 ==="
Write-Host "分支: $branch"
Write-Host "目標建置: $needBuild"
Write-Host "下載: $url"
Write-Host ""

$tmp = Join-Path $env:TEMP ("math-homework-grader-app-" + $ts + ".ps1")
try {
  Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
} catch {
  throw ("下載失敗。請確認網路，或先 git pull hello-world 後跑 install-math-homework-grader.ps1。`n" + $_.Exception.Message)
}

$bytes = [System.IO.File]::ReadAllBytes($tmp)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) { $text = $text.Substring(1) }

$okAq = ($text -match 'AQ\.') -and ($text -match 'Test-GeminiApiKeyLooksValid') -and ($text -match 'x-goog-api-key')
$okBuild = $text -match [regex]::Escape($needBuild)
if (-not $okAq -or -not $okBuild) {
  Write-Host "下載內容檢查失敗："
  Write-Host ("  含 AQ. 支援: " + $okAq)
  Write-Host ("  含建置 $needBuild: " + $okBuild)
  throw "遠端腳本尚未含新版。請稍等 push 完成後再跑，或改用本機 hello-world\scripts\install-math-homework-grader.ps1"
}

$dest = Join-Path $appDir "math-homework-grader-app.ps1"
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($dest, $text, $utf8Bom)
Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
Write-Host "已寫入: $dest"

# 清掉誤存的非金鑰文字（保留 AIza / AQ.）
$keyPath = Join-Path $work "gemini-api-key.txt"
if (Test-Path -LiteralPath $keyPath) {
  $rawKey = [System.IO.File]::ReadAllText($keyPath).Trim()
  $rawKey = ($rawKey -split "`r|`n")[0].Trim().Trim('"', "'")
  if ($rawKey -and ($rawKey -notmatch '^(?i)(AIza|AQ\.)')) {
    $bak = Join-Path $work ("gemini-api-key-bad-" + $ts + ".txt")
    Move-Item -LiteralPath $keyPath -Destination $bak -Force
    Write-Host "已暫存可疑舊金鑰到: $bak（開頭不是 AIza／AQ.）"
    Write-Host "請重新貼上 AI Studio 的 Copy key。"
  } else {
    Write-Host ("目前金鑰檔: " + $(if ($rawKey) { $rawKey.Substring(0, [Math]::Min(4, $rawKey.Length)) + "… 長度 " + $rawKey.Length } else { "空白" }))
  }
} else {
  Write-Host "尚無 gemini-api-key.txt（稍後在程式內貼上）"
}

$settingsPath = Join-Path $work "settings.json"
if (Test-Path -LiteralPath $settingsPath) {
  $raw = [System.IO.File]::ReadAllText($settingsPath)
  $raw2 = $raw.Replace("gemini-2.0-flash", "gemini-3.5-flash").Replace("gemini-1.5-flash", "gemini-3.5-flash")
  [System.IO.File]::WriteAllText($settingsPath, $raw2, $utf8Bom)
}

$vbs = @"
Set sh = CreateObject("WScript.Shell")
desk = sh.SpecialFolders("Desktop")
ps1 = desk & "\MathGradingApp\math-homework-grader-app.ps1"
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File """ & ps1 & """ -WorkDir """ & desk & "\MathGrading"""
sh.Run cmd, 1, False
"@
Set-Content -LiteralPath (Join-Path $desk "習作批改.vbs") -Value $vbs -Encoding ASCII
Set-Content -LiteralPath (Join-Path $desk "grade-math.vbs") -Value $vbs -Encoding ASCII
Set-Content -LiteralPath (Join-Path $appDir "launch.vbs") -Value $vbs -Encoding ASCII

$cmdUpdate = @"
@echo off
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix-grader-gemini-404.ps1"
pause
"@
# 若此腳本是從 GitHub raw 下載到 TEMP 執行，另寫一份到桌面方便下次
$fixOnDesk = Join-Path $desk "fix-grader-gemini-404.ps1"
if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
  try { Copy-Item -LiteralPath $PSCommandPath -Destination $fixOnDesk -Force } catch {}
}

Write-Host ""
Write-Host "DONE"
Write-Host "1) 關掉所有舊的「數學習作批改」視窗"
Write-Host "2) 雙擊桌面「習作批改.vbs」"
Write-Host "3) 看標題是否含: $needBuild"
Write-Host "4) Gemini金鑰 → 貼上 AQ. 或 AIza 整串 → 測試金鑰 → 儲存"
Write-Host "5) 再按 Gemini自動批"
Write-Host ""
Write-Host "若標題沒有 $needBuild，代表還在開舊檔。請只開桌面「習作批改.vbs」。"
