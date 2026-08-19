#Requires -Version 5.1
# 快速啟動習作台：先顯示「正在啟動」，再開主程式（不卡住）
param([string]$WorkDir = "")

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$desk = [Environment]::GetFolderPath("Desktop")
if ([string]::IsNullOrWhiteSpace($WorkDir)) {
  $cand = Join-Path $desk "習作台資料"
  $legacy = Join-Path $desk "TeacherDesk"
  if (Test-Path -LiteralPath $cand) { $WorkDir = $cand }
  elseif (Test-Path -LiteralPath $legacy) { $WorkDir = $legacy }
  else { $WorkDir = $cand }
}

$mainPs1 = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "teacher-desk-app.ps1"
if (-not (Test-Path -LiteralPath $mainPs1)) {
  [void][System.Windows.Forms.MessageBox]::Show(
    "找不到程式：`n$mainPs1`n`n請在 PowerShell 執行 refresh-desktop-vbs.ps1 更新。",
    "習作台",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Warning
  )
  exit 1
}

$existing = @(Get-Process -Name powershell -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowTitle -like "*習作台*" -and $_.MainWindowTitle -notlike "*正在啟動*" })
if ($existing.Count -gt 0) {
  [void][System.Windows.Forms.MessageBox]::Show("習作台已在執行，請看工作列。", "習作台")
  exit 0
}

$splash = New-Object System.Windows.Forms.Form
$splash.Text = "習作台"
$splash.FormBorderStyle = "FixedDialog"
$splash.MaximizeBox = $false
$splash.MinimizeBox = $false
$splash.ControlBox = $true
$splash.StartPosition = "CenterScreen"
$splash.Size = New-Object System.Drawing.Size(380, 118)
$splash.TopMost = $true
$splash.BackColor = [System.Drawing.Color]::FromArgb(245, 248, 244)

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = "正在啟動習作台…" + [Environment]::NewLine + "出現主視窗後此畫面會自動關閉"
$lbl.Dock = "Fill"
$lbl.TextAlign = "MiddleCenter"
$lbl.Font = New-Object System.Drawing.Font("Microsoft JhengHei UI", 11)
$lbl.ForeColor = [System.Drawing.Color]::FromArgb(20, 70, 50)
$splash.Controls.Add($lbl)
$splash.Show()
$splash.Refresh()
[System.Windows.Forms.Application]::DoEvents()

$arg = "-NoLogo -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$mainPs1`" -WorkDir `"$WorkDir`""
$p = Start-Process -FilePath "powershell.exe" -ArgumentList $arg -PassThru -WindowStyle Hidden

$ready = $false
$deadline = (Get-Date).AddSeconds(45)
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Milliseconds 350
  [System.Windows.Forms.Application]::DoEvents()
  if ($p.HasExited) { break }
  $hit = @(Get-Process -Name powershell -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -like "*習作台｜*" })
  if ($hit.Count -gt 0) { $ready = $true; break }
}

$splash.Close()
$splash.Dispose()

if ($p.HasExited -and -not $ready) {
  [void][System.Windows.Forms.MessageBox]::Show(
    "主程式立刻結束。請看桌面「習作台錯誤.txt」，或再跑 refresh-desktop-vbs.ps1。",
    "習作台",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Error
  )
  exit 1
}
