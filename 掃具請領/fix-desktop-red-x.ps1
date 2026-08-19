#Requires -Version 5.1
# 修整桌紅 X／白 X（OneDrive 同步錯誤疊圖）
# 不會把檔案搬到大容量碟
$ErrorActionPreference = "Continue"
$desk = [Environment]::GetFolderPath("Desktop")
Write-Host "桌面路徑：$desk"
if ($desk -match "OneDrive") {
  Write-Host "桌面在 OneDrive 底下。同步失敗時，連捷徑／回收筒都會打 X。"
} else {
  Write-Host "桌面不在 OneDrive 路徑；仍可能被 OneDrive 圖示疊加影響。"
}

Write-Host "關閉 Explorer 與 OneDrive..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$local = $env:LOCALAPPDATA
@(
  (Join-Path $local "IconCache.db"),
  (Join-Path $local "Microsoft\Windows\Explorer\iconcache_*.db"),
  (Join-Path $local "Microsoft\Windows\Explorer\thumbcache_*.db")
) | ForEach-Object {
  Get-Item -Path $_ -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}
Write-Host "已清圖示／縮圖快取"

$ie4 = Join-Path $env:SystemRoot "System32\ie4uinit.exe"
if (Test-Path -LiteralPath $ie4) {
  Start-Process $ie4 -ArgumentList "-show" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
}

$od = Join-Path $local "Microsoft\OneDrive\OneDrive.exe"
if (Test-Path -LiteralPath $od) {
  Write-Host "重設並啟動 OneDrive..."
  Start-Process $od -ArgumentList "/reset" -WindowStyle Hidden
  Start-Sleep -Seconds 6
  Start-Process $od
} else {
  Write-Host "找不到 OneDrive.exe。請從開始功能表手動打開 OneDrive。"
}

Start-Process explorer.exe
Start-Sleep -Seconds 3

if ($desk -match "OneDrive") {
  Write-Host "把桌面標成「保留在此裝置」（可能要幾分鐘）..."
  cmd /c "attrib +P /S /D `"$desk`"" | Out-Null
}

Write-Host ""
Write-Host "完成。請等 1～2 分鐘看桌面 X 是否消失。"
Write-Host "若還在：點工作列雲朵 → 查看同步問題 → 有錯誤就選重試。"
Write-Host "不要再跑 split-desktop-test 或 undo-20260717。"
