#Requires -Version 5.1
# 依學習日誌 20260717 復原：下載／文件／圖片歸檔到本機大容量碟
# 當日原文是 D:；本次依你指定改存 F:（BackUp）
# 在「本機 Windows PowerShell」執行，不要在 Cursor 雲端跑
$ErrorActionPreference = "Stop"
$Root = "F:\"
$TestDir = Join-Path $Root "test"
$Archive = @{
  "私人"     = @("掃描檔", "證件合約", "財務", "家庭")
  "桌面歸檔" = @()
  "下載歸檔" = @()
  "文件歸檔" = @()
  "圖片歸檔" = @()
  "工具軟體" = @()
}

Write-Host "=== 20260717 歸檔動作復原（目標 F:）==="
if (-not (Test-Path -LiteralPath $Root)) {
  throw "找不到 F: 。請確認 BackUp 碟已接上。"
}

foreach ($name in $Archive.Keys) {
  $dir = Join-Path $Root $name
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  Write-Host "資料夾：$dir"
  foreach ($sub in $Archive[$name]) {
    New-Item -ItemType Directory -Force -Path (Join-Path $dir $sub) | Out-Null
  }
}
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null

$xlsxUrl = "https://raw.githubusercontent.com/copyshae/-/cursor/launch-efficiency-459a/掃具請領/114學年掃具請領_已整理.xlsx"
$destXlsx = Join-Path $TestDir "114學年掃具請領_已整理.xlsx"
Write-Host "下載掃具請領已整理檔 → $destXlsx"
Invoke-WebRequest -Uri $xlsxUrl -OutFile $destXlsx -UseBasicParsing

$note = Join-Path $TestDir "20260717歸檔說明.txt"
@(
  "依學習日誌 20260717 復原（目標改為 F:）"
  "線上：https://copyshae.github.io/hello-world/directory/logs/20260717-learning-log.html"
  ""
  "當日原則：桌面／下載／文件／圖片歸檔到本機大容量碟；財務不上雲。"
  "當日路徑是 D:\桌面歸檔 等；本次改為："
  "  F:\桌面歸檔"
  "  F:\下載歸檔"
  "  F:\文件歸檔"
  "  F:\圖片歸檔"
  "  F:\私人（證件／財務／家庭，不上 OneDrive）"
  ""
  "掃具請領已整理："
  "  $destXlsx"
  "若要蓋原檔，複製成 F:\test\114學年掃具請領.xlsx"
) -join "`r`n" | Set-Content -LiteralPath $note -Encoding UTF8

Write-Host ""
Write-Host "完成。請到檔案總管打開：F:\test"
Write-Host $destXlsx
Write-Host $note
