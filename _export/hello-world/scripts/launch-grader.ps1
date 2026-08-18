#Requires -Version 5.1
# 快速啟動習作批改：先顯示「正在啟動」，再載入主程式
param([string]$WorkDir = "")

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$desk = [Environment]::GetFolderPath("Desktop")
if ([string]::IsNullOrWhiteSpace($WorkDir)) {
  $WorkDir = Join-Path $desk "MathGrading"
}

$mainPs1 = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "math-homework-grader-app.ps1"
if (-not (Test-Path -LiteralPath $mainPs1)) {
  [void][System.Windows.Forms.MessageBox]::Show(
    "找不到程式：`n$mainPs1`n`n請在 PowerShell 執行 refresh-desktop-vbs.ps1 更新。",
    "習作批改",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Warning
  )
  exit 1
}

$splash = New-Object System.Windows.Forms.Form
$splash.Text = "習作批改"
$splash.FormBorderStyle = "FixedDialog"
$splash.MaximizeBox = $false
$splash.MinimizeBox = $false
$splash.ControlBox = $true
$splash.StartPosition = "CenterScreen"
$splash.Size = New-Object System.Drawing.Size(380, 118)
$splash.TopMost = $true
$splash.BackColor = [System.Drawing.Color]::FromArgb(245, 248, 244)

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = "正在啟動習作批改…"
$lbl.Dock = "Fill"
$lbl.TextAlign = "MiddleCenter"
$lbl.Font = New-Object System.Drawing.Font("Microsoft JhengHei UI", 12)
$lbl.ForeColor = [System.Drawing.Color]::FromArgb(20, 70, 50)
$splash.Controls.Add($lbl)

$splash.Add_Shown({
  [System.Windows.Forms.Application]::DoEvents()
  try {
    & $mainPs1 -WorkDir $WorkDir
  } catch {
    [void][System.Windows.Forms.MessageBox]::Show(
      ("啟動失敗：`n{0}" -f $_.Exception.Message),
      "習作批改",
      [System.Windows.Forms.MessageBoxButtons]::OK,
      [System.Windows.Forms.MessageBoxIcon]::Error
    )
  } finally {
    $splash.Close()
  }
})

[void]$splash.ShowDialog()
