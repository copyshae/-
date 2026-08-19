#Requires -Version 5.1
# 復原 20260717：把大容量碟上的「桌面／下載／文件／圖片歸檔」搬回系統原資料夾
# 學習日誌：https://copyshae.github.io/hello-world/directory/logs/20260717-learning-log.html
# 請在本機 Windows PowerShell 執行。不會動 F:\私人 或 D:\私人。
$ErrorActionPreference = "Stop"

function Get-DownloadsDir {
  $p = Join-Path $env:USERPROFILE "Downloads"
  if (Test-Path -LiteralPath $p) { return $p }
  return [Environment]::GetFolderPath("UserProfile")
}

$jobs = @(
  @{ Name = "桌面"; Archives = @("D:\桌面歸檔", "F:\桌面歸檔"); Dest = [Environment]::GetFolderPath("Desktop") }
  @{ Name = "下載"; Archives = @("D:\下載歸檔", "F:\下載歸檔"); Dest = (Get-DownloadsDir) }
  @{ Name = "文件"; Archives = @("D:\文件歸檔", "F:\文件歸檔"); Dest = [Environment]::GetFolderPath("MyDocuments") }
  @{ Name = "圖片"; Archives = @("D:\圖片歸檔", "F:\圖片歸檔"); Dest = [Environment]::GetFolderPath("MyPictures") }
)

Write-Host "=== 復原 20260717 歸檔結果 ==="
Write-Host "會把歸檔夾裡的檔案搬回：桌面、下載、文件、圖片"
Write-Host "不會搬：私人／財務／證件"
Write-Host ""

$plan = New-Object System.Collections.Generic.List[object]
foreach ($j in $jobs) {
  if (-not $j.Dest) {
    Write-Host ("略過 {0}：找不到系統資料夾" -f $j.Name)
    continue
  }
  New-Item -ItemType Directory -Force -Path $j.Dest | Out-Null
  foreach ($arc in $j.Archives) {
    if (-not (Test-Path -LiteralPath $arc)) { continue }
    $items = @(Get-ChildItem -LiteralPath $arc -Force -ErrorAction SilentlyContinue)
    Write-Host ("找到 {0}：{1}（{2} 項）→ {3}" -f $j.Name, $arc, $items.Count, $j.Dest)
    foreach ($it in $items) {
      $plan.Add([pscustomobject]@{
        Kind = $j.Name
        From = $it.FullName
        To   = (Join-Path $j.Dest $it.Name)
      })
    }
  }
}

if ($plan.Count -eq 0) {
  Write-Host ""
  Write-Host "沒有找到 D:\ 或 F: 上的歸檔資料夾，無法復原。"
  Write-Host "請確認本機有：桌面歸檔／下載歸檔／文件歸檔／圖片歸檔"
  exit 0
}

Write-Host ""
Write-Host ("預覽共 {0} 項（前 20 項）：" -f $plan.Count)
$plan | Select-Object -First 20 | ForEach-Object {
  Write-Host ("  [{0}] {1}" -f $_.Kind, $_.From)
}

$ans = Read-Host "確定搬回原位置？請輸入「是」後按 Enter（其他則取消）"
if ($ans -ne "是") {
  Write-Host "已取消，沒有搬任何檔案。"
  exit 0
}

$ok = 0
$skip = 0
$fail = 0
foreach ($p in $plan) {
  try {
    if (Test-Path -LiteralPath $p.To) {
      Write-Host ("略過（目標已有同名）：{0}" -f $p.To)
      $skip++
      continue
    }
    Move-Item -LiteralPath $p.From -Destination $p.To
    $ok++
  } catch {
    Write-Host ("失敗：{0}｜{1}" -f $p.From, $_.Exception.Message)
    $fail++
  }
}

Write-Host ""
Write-Host ("完成：搬回 {0}｜略過同名 {1}｜失敗 {2}" -f $ok, $skip, $fail)
Write-Host "請到桌面、下載、文件、圖片查看。"
