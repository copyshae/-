#Requires -Version 5.1
# 靈命七習慣｜電腦視窗版（14樣功課＋七習慣象限，可與手機同步）
param([string]$WorkDir = "")

$ErrorActionPreference = 'Stop'
$desk = [Environment]::GetFolderPath('Desktop')
$PhoneDaily = 'https://copyshae.github.io/-/daily-14/'
$PhoneHabits = 'https://copyshae.github.io/-/habits-7/'
$DeskUrl = 'https://copyshae.github.io/-/life-desk/'

if ([string]::IsNullOrWhiteSpace($WorkDir)) {
  $WorkDir = Join-Path $desk '靈命七習慣資料'
}
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
foreach ($sub in @('今日存檔', '從手機匯入', '匯出給手機')) {
  New-Item -ItemType Directory -Force -Path (Join-Path $WorkDir $sub) | Out-Null
}

function Get-TodayStamp {
  (Get-Date).ToString('yyyyMMdd')
}

function Open-AppWindow([string]$Url, [string]$Title) {
  $edge = ${(Get-Command msedge -ErrorAction SilentlyContinue).Source}
  if (-not $edge) {
    $edge = Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'
  }
  if (-not (Test-Path -LiteralPath $edge)) {
    $edge = Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'
  }
  if (Test-Path -LiteralPath $edge) {
    $args = @(
      "--app=$Url",
      "--window-size=1280,840",
      "--new-window"
    )
    Start-Process -FilePath $edge -ArgumentList $args | Out-Null
    return
  }
  $chrome = Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'
  if (-not (Test-Path -LiteralPath $chrome)) {
    $chrome = Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'
  }
  if (Test-Path -LiteralPath $chrome) {
    Start-Process -FilePath $chrome -ArgumentList @("--app=$Url", "--window-size=1280,840") | Out-Null
    return
  }
  Start-Process $Url
}

try {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
  [System.Windows.Forms.Application]::EnableVisualStyles()

  $form = New-Object System.Windows.Forms.Form
  $form.Text = '靈命七習慣｜電腦版（與手機同步）'
  $form.Size = New-Object System.Drawing.Size(520, 460)
  $form.StartPosition = 'CenterScreen'
  $form.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 10)

  $lbl = New-Object System.Windows.Forms.Label
  $lbl.Text = "首要：身心靈提升｜靈命持續成長`r`n資料夾：$WorkDir`r`n今日：" + (Get-TodayStamp)
  $lbl.AutoSize = $false
  $lbl.Location = New-Object System.Drawing.Point(16, 14)
  $lbl.Size = New-Object System.Drawing.Size(470, 70)
  $form.Controls.Add($lbl)

  function Add-BigBtn([string]$text, [int]$y, [scriptblock]$click) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point(16, $y)
    $b.Size = New-Object System.Drawing.Size(470, 40)
    $b.Add_Click($click)
    $form.Controls.Add($b)
    return $b
  }

  [void](Add-BigBtn '開啟電腦版視窗（14樣＋七習慣＋同步匯出）' 95 { Open-AppWindow $DeskUrl 'life-desk' })
  [void](Add-BigBtn '開啟：每日14樣功課（可讀誦／匯出同步）' 145 { Open-AppWindow $PhoneDaily 'daily14' })
  [void](Add-BigBtn '開啟：七習慣＋時間象限（可讀誦今日紀錄）' 195 { Open-AppWindow $PhoneHabits 'habits7' })
  [void](Add-BigBtn '打開同步資料夾（今日存檔／匯入匯出）' 245 {
    Start-Process explorer.exe $WorkDir
  })
  [void](Add-BigBtn '複製手機網址到剪貼簿' 295 {
    $txt = "14樣：$PhoneDaily`r`n七習慣：$PhoneHabits`r`n電腦版：$DeskUrl"
    [System.Windows.Forms.Clipboard]::SetText($txt)
    [System.Windows.Forms.MessageBox]::Show("已複製：`r`n$txt", '靈命七習慣')
  })

  $tip = New-Object System.Windows.Forms.Label
  $tip.Text = "同步：手機匯出含今日日期的 JSON／CSV／Word／PDF／PNG → 放入「從手機匯入」→ 電腦 App 按匯入。`r`n讀誦：各頁有「讀誦今日紀錄／讀誦今日」按鈕。"
  $tip.Location = New-Object System.Drawing.Point(16, 350)
  $tip.Size = New-Object System.Drawing.Size(470, 60)
  $form.Controls.Add($tip)

  # auto open desk window
  Open-AppWindow $DeskUrl 'life-desk'
  [void]$form.ShowDialog()
} catch {
  try {
    Open-AppWindow $DeskUrl 'life-desk'
    Start-Process explorer.exe $WorkDir
  } catch {
    Start-Process $DeskUrl
  }
}
