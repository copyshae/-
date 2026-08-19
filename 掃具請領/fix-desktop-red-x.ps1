#Requires -Version 5.1
# 修復「0717 歸檔復原後桌面大量紅 X」
# 原因：當日原位置留了「捷徑回指」歸檔夾；只把檔搬回桌面、沒刪失效捷徑，OneDrive／圖示快取也會整桌打 X
# 不會把檔案再搬到大容量碟
$ErrorActionPreference = "Continue"
$desk = [Environment]::GetFolderPath("Desktop")
Write-Host "桌面：$desk"

function Get-LnkTarget([string]$path) {
  try {
    $sh = New-Object -ComObject WScript.Shell
    return [string]$sh.CreateShortcut($path).TargetPath
  } catch { return "" }
}

# 1) 刪除指回歸檔夾、但桌面已有實體的失效捷徑
$archiveRoots = @("D:\桌面歸檔", "F:\桌面歸檔", "D:\下載歸檔", "F:\下載歸檔")
$removed = 0
Get-ChildItem -LiteralPath $desk -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -eq ".lnk" } |
  ForEach-Object {
    $t = Get-LnkTarget $_.FullName
    if (-not $t) { return }
    $hit = $false
    foreach ($root in $archiveRoots) {
      if ($t.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) { $hit = $true }
    }
    $gone = -not (Test-Path -LiteralPath $t)
    $localTwin = Join-Path $desk ([IO.Path]::GetFileNameWithoutExtension($_.Name))
    if ($hit -and ($gone -or (Test-Path -LiteralPath $localTwin))) {
      Remove-Item -LiteralPath $_.FullName -Force
      Write-Host ("已刪失效回指捷徑：" + $_.Name)
      $removed++
    }
  }
Write-Host ("刪除回指捷徑：{0}" -f $removed)

# 2) 啟動 OneDrive（雲端未執行時整桌會紅 X）
$od = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
if (-not $od) {
  $exe = Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive\OneDrive.exe"
  if (Test-Path -LiteralPath $exe) {
    Write-Host "啟動 OneDrive..."
    Start-Process $exe
    Start-Sleep -Seconds 4
  } else {
    Write-Host "找不到 OneDrive，請從開始功能表打開。"
  }
}

# 3) 清圖示快取並重啟 Explorer（比只按 F5 有效）
Write-Host "重整桌面圖示..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
$cache = Join-Path $env:LOCALAPPDATA "IconCache.db"
if (Test-Path -LiteralPath $cache) {
  Remove-Item -LiteralPath $cache -Force -ErrorAction SilentlyContinue
}
Start-Process explorer.exe
Start-Sleep -Seconds 2
Write-Host "請再看桌面：紅 X 應會少很多。若還有，對該圖示右鍵 → 一律保留在此裝置上。"
Write-Host "不要再跑 undo-20260717-archive.ps1。"
