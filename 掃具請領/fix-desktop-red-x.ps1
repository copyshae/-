#Requires -Version 5.1
# 說明並處理桌面綠勾／紅 X（OneDrive 疊圖）
# 綠勾＝已同步到這台（正常）。紅 X＝這項同步失敗。
# 不會把檔案搬到大容量碟。
$ErrorActionPreference = "Continue"
$desk = [Environment]::GetFolderPath("Desktop")
Write-Host "桌面：$desk"
Write-Host ""
Write-Host "綠勾：OneDrive 表示「檔案已在這台電腦」。上一支腳本把桌面標成保留在此裝置，所以會出現綠勾。"
Write-Host "紅 X：這個捷徑／資料夾同步失敗。常因捷徑指到已搬走的程式，或桌面被 OneDrive 備份。"
Write-Host ""

Write-Host "=== 紅 X 常見：捷徑目標不存在 ==="
Get-ChildItem -LiteralPath $desk -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -eq ".lnk" } |
  ForEach-Object {
    try {
      $sh = New-Object -ComObject WScript.Shell
      $t = [string]$sh.CreateShortcut($_.FullName).TargetPath
      if ($t -and -not (Test-Path -LiteralPath $t)) {
        Write-Host ("  " + $_.Name + " → 找不到：" + $t)
      }
    } catch {}
  }

Write-Host ""
Write-Host "若要桌面都不要勾、也不要 X：關掉 OneDrive「備份桌面」。"
Write-Host "正在打開 OneDrive 設定。請選：同步和備份 → 管理備份 → 桌面 → 停止備份。"
Write-Host "停止後檔案仍在桌面，只是不再由雲端管圖示。"
$od = Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive\OneDrive.exe"
if (Test-Path -LiteralPath $od) {
  Start-Process $od
}
Start-Process "https://www.microsoft.com/zh-tw/microsoft-365/onedrive/desktop-app"
Write-Host ""
Write-Host "快捷：工作列雲朵 右鍵 → 設定 → 同步和備份 → 管理備份 → 關閉「桌面」。"
