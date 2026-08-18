#Requires -Version 5.1
# 桌面一鍵選單：習作批改／習作台（免記多個捷徑）
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$desk = [Environment]::GetFolderPath("Desktop")
$graderDir = Join-Path $desk "MathGradingApp"
$deskDir = Join-Path $desk "習作台程式"
$launchGrader = Join-Path $graderDir "launch-grader.ps1"
$launchDesk = Join-Path $deskDir "launch-teacher-desk.ps1"

$font = New-Object System.Drawing.Font("Microsoft JhengHei UI", 11)
$fontBig = New-Object System.Drawing.Font("Microsoft JhengHei UI", 13, [System.Drawing.FontStyle]::Bold)

$form = New-Object System.Windows.Forms.Form
$form.Text = "習作工具"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(360, 248)
$form.Font = $font
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 248, 244)

$title = New-Object System.Windows.Forms.Label
$title.Text = "請選擇要開啟的程式"
$title.Font = $fontBig
$title.ForeColor = [System.Drawing.Color]::FromArgb(20, 70, 50)
$title.Location = New-Object System.Drawing.Point(24, 16)
$title.AutoSize = $true

$tip = New-Object System.Windows.Forms.Label
$tip.Text = "建議只留桌面「習作工具.vbs」這一個捷徑。"
$tip.ForeColor = [System.Drawing.Color]::FromArgb(74, 92, 82)
$tip.Location = New-Object System.Drawing.Point(24, 48)
$tip.Size = New-Object System.Drawing.Size(300, 36)

$btnGrader = New-Object System.Windows.Forms.Button
$btnGrader.Text = "習作批改"
$btnGrader.Location = New-Object System.Drawing.Point(24, 92)
$btnGrader.Size = New-Object System.Drawing.Size(300, 44)
$btnGrader.BackColor = [System.Drawing.Color]::FromArgb(27, 67, 50)
$btnGrader.ForeColor = [System.Drawing.Color]::White
$btnGrader.FlatStyle = "Flat"

$btnDesk = New-Object System.Windows.Forms.Button
$btnDesk.Text = "習作台"
$btnDesk.Location = New-Object System.Drawing.Point(24, 144)
$btnDesk.Size = New-Object System.Drawing.Size(300, 44)
$btnDesk.BackColor = [System.Drawing.Color]::FromArgb(45, 106, 79)
$btnDesk.ForeColor = [System.Drawing.Color]::White
$btnDesk.FlatStyle = "Flat"

function Start-App([string]$launcher) {
  if (-not (Test-Path -LiteralPath $launcher)) {
    [void][System.Windows.Forms.MessageBox]::Show(
      "找不到：`n$launcher`n`n請執行 refresh-desktop-vbs.ps1 更新。",
      "習作工具",
      [System.Windows.Forms.MessageBoxButtons]::OK,
      [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    return
  }
  $form.Hide()
  try {
    & $launcher
  } finally {
    $form.Close()
  }
}

$btnGrader.Add_Click({ Start-App $launchGrader })
$btnDesk.Add_Click({ Start-App $launchDesk })

$form.Controls.AddRange(@($title, $tip, $btnGrader, $btnDesk))
[void]$form.ShowDialog()
