#Requires -Version 5.1
# 檢查桌面紅 X：OneDrive 同步／捷徑失效
# 不會把檔案搬到大容量碟歸檔夾
$ErrorActionPreference = "Continue"
$desk = [Environment]::GetFolderPath("Desktop")
Write-Host "桌面：$desk"
Write-Host ""

$od = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
if ($od) {
  Write-Host "OneDrive 正在執行。"
} else {
  Write-Host "OneDrive 沒有在執行（學習日誌 0717：雲端檔案提供者未執行 → 圖示常打紅 X）"
  $exe = Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive\OneDrive.exe"
  if (Test-Path -LiteralPath $exe) {
    Write-Host "正在啟動 OneDrive..."
    Start-Process $exe
    Start-Sleep -Seconds 3
  } else {
    Write-Host "找不到 OneDrive.exe。請從開始功能表開啟 OneDrive。"
  }
}

Write-Host ""
Write-Host "=== 失效捷徑（目標不存在）==="
$broken = 0
Get-ChildItem -LiteralPath $desk -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -eq ".lnk" } |
  ForEach-Object {
    try {
      $sh = New-Object -ComObject WScript.Shell
      $t = $sh.CreateShortcut($_.FullName).TargetPath
      if ($t -and -not (Test-Path -LiteralPath $t)) {
        Write-Host ("  {0} → {1}" -f $_.Name, $t)
        $broken++
      }
    } catch {}
  }
if ($broken -eq 0) { Write-Host "  沒有掃到失效捷徑（或桌面主要是資料夾／vbs）" }

Write-Host ""
Write-Host "請再做："
Write-Host "1. 工作列雲朵圖示：若有紅 X／驚嘆號，點開看錯誤"
Write-Host "2. 桌面空白處右鍵 → 重新整理（F5）"
Write-Host "3. 若圖示仍紅 X：對資料夾右鍵 → 一律保留在此裝置上"
Write-Host "4. 不要再跑 restore／undo 歸檔腳本"
Write-Host ""
Write-Host "Excel 拆欄請只用桌面 test 那份，關閉時若不想改原檔請選「不要儲存」。"
