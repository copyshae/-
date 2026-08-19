#Requires -Version 5.1
# 復原「不小心跑了 undo-20260717」：把剛搬回桌面／下載／文件／圖片的歸檔，再放回 F: 歸檔夾
# 只搬已知那次預覽出現的項目，不會把整份桌面都搬走
$ErrorActionPreference = "Stop"
$desk = [Environment]::GetFolderPath("Desktop")
$docs = [Environment]::GetFolderPath("MyDocuments")
$pics = [Environment]::GetFolderPath("MyPictures")
$downs = Join-Path $env:USERPROFILE "Downloads"

New-Item -ItemType Directory -Force -Path "F:\桌面歸檔","F:\下載歸檔","F:\文件歸檔","F:\圖片歸檔" | Out-Null

$pairs = @(
  @{ From = $desk;  To = "F:\桌面歸檔"; Names = @("1150717", "2026-07-29_桌面整理", "README.txt") }
  @{ From = $downs; To = "F:\下載歸檔"; Names = @() }
  @{ From = $docs;  To = "F:\文件歸檔"; Names = @() }
  @{ From = $pics;  To = "F:\圖片歸檔"; Names = @() }
)

$ok = 0
foreach ($p in $pairs) {
  if (-not (Test-Path -LiteralPath $p.From)) { continue }
  $names = @($p.Names)
  if ($names.Count -eq 0) { continue }
  foreach ($n in $names) {
    $src = Join-Path $p.From $n
    if (-not (Test-Path -LiteralPath $src)) { continue }
    $dest = Join-Path $p.To $n
    if (Test-Path -LiteralPath $dest) {
      Write-Host "目標已有，略過：$dest"
      continue
    }
    Move-Item -LiteralPath $src -Destination $dest
    Write-Host "已搬回：$src → $dest"
    $ok++
  }
}
Write-Host ""
Write-Host ("完成，搬回 {0} 項到 F: 歸檔夾。" -f $ok)
Write-Host "Excel：若剛跑巨集，請關閉時選「不要儲存」。"
