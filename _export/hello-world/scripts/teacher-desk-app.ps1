#Requires -Version 5.1
# 習作台（繁體中文）— 精簡穩定版
param([string]$WorkDir = "")

$ErrorActionPreference = 'Stop'
$logPath = Join-Path ([Environment]::GetFolderPath('Desktop')) '習作台錯誤.txt'

function Write-LaunchLog([string]$text) {
  try {
    $enc = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($logPath, $text, $enc)
  } catch {}
}

function Show-Fail([string]$text) {
  Write-LaunchLog $text
  try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    [void][System.Windows.Forms.MessageBox]::Show($text, '習作台錯誤')
  } catch {
    Write-Host $text
  }
}

try {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
  [System.Windows.Forms.Application]::EnableVisualStyles()
  try {
    $zh = [System.Globalization.CultureInfo]::GetCultureInfo('zh-TW')
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $zh
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $zh
  } catch {}

  $desk = [Environment]::GetFolderPath('Desktop')
  if ([string]::IsNullOrWhiteSpace($WorkDir)) {
    $WorkDir = Join-Path $desk '習作台資料'
  }
  if (-not (Test-Path -LiteralPath $WorkDir)) {
    New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
  }
  foreach ($sub in @('掃描匯入', '練習回傳', '匯出給手機')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $WorkDir $sub) | Out-Null
  }

  $statePath = Join-Path $WorkDir '班級狀態.json'
  $legacyPath = Join-Path $WorkDir 'class-state.json'
  if (-not (Test-Path -LiteralPath $statePath) -and (Test-Path -LiteralPath $legacyPath)) {
    $statePath = $legacyPath
  }

  function New-UiFont([double]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
    foreach ($name in @('Microsoft JhengHei UI', 'Microsoft JhengHei', 'Segoe UI', 'Tahoma')) {
      try { return New-Object System.Drawing.Font($name, $size, $style) } catch {}
    }
    return [System.Drawing.SystemFonts]::DefaultFont
  }

  function Get-DefaultState {
    $seats = @{}
    $seats['00'] = @{ level = '未標'; send = '未發'; note = '試發' }
    for ($i = 1; $i -le 35; $i++) {
      $id = '{0:D2}' -f $i
      $seats[$id] = @{ level = '未標'; send = '未發'; note = '' }
    }
    return @{
      classLabel    = '本班數學'
      seatCount     = 35
      deadline      = '今晚 21:00'
      sendChannel   = 'line_group'
      returnChannel = 'line_dm'
      seats         = $seats
    }
  }

  function Ensure-State($st) {
    if ($null -eq $st) { return (Get-DefaultState) }
    $n = 35
    try { $n = [int]$st.seatCount } catch { $n = 35 }
    if ($n -lt 1) { $n = 1 }
    if ($n -gt 60) { $n = 60 }
    $st.seatCount = $n
    if (-not $st.classLabel) { $st.classLabel = '本班數學' }
    if (-not $st.deadline) { $st.deadline = '今晚 21:00' }
    if (-not $st.sendChannel) { $st.sendChannel = 'line_group' }
    if (-not $st.returnChannel) { $st.returnChannel = 'line_dm' }

    $seats = @{}
    if ($st.seats -is [hashtable]) {
      foreach ($k in $st.seats.Keys) { $seats[$k] = $st.seats[$k] }
    } elseif ($st.seats) {
      foreach ($p in $st.seats.PSObject.Properties) {
        $v = $p.Value
        $seats[$p.Name] = @{
          level = $(if ($v.level) { [string]$v.level } else { '未標' })
          send  = $(if ($v.send) { [string]$v.send } else { '未發' })
          note  = $(if ($v.note) { [string]$v.note } else { '' })
        }
      }
    }
    if (-not $seats.ContainsKey('00')) {
      $seats['00'] = @{ level = '未標'; send = '未發'; note = '試發' }
    } else {
      $s0 = $seats['00']
      if ($s0 -isnot [hashtable]) {
        $seats['00'] = @{
          level = $(if ($s0.level) { [string]$s0.level } else { '未標' })
          send  = $(if ($s0.send) { [string]$s0.send } else { '未發' })
          note  = $(if ($s0.note) { [string]$s0.note } else { '試發' })
        }
      } else {
        if (-not $s0.ContainsKey('level') -or -not $s0.level) { $s0.level = '未標' }
        if (-not $s0.ContainsKey('send') -or -not $s0.send) { $s0.send = '未發' }
        if (-not $s0.ContainsKey('note') -or -not $s0.note) { $s0.note = '試發' }
      }
    }
    for ($i = 1; $i -le $n; $i++) {
      $id = '{0:D2}' -f $i
      if (-not $seats.ContainsKey($id)) {
        $seats[$id] = @{ level = '未標'; send = '未發'; note = '' }
      } else {
        $s = $seats[$id]
        if ($s -isnot [hashtable]) {
          $seats[$id] = @{
            level = $(if ($s.level) { [string]$s.level } else { '未標' })
            send  = $(if ($s.send) { [string]$s.send } else { '未發' })
            note  = $(if ($s.note) { [string]$s.note } else { '' })
          }
        } else {
          if (-not $s.ContainsKey('level') -or -not $s.level) { $s.level = '未標' }
          if (-not $s.ContainsKey('send') -or -not $s.send) { $s.send = '未發' }
          if (-not $s.ContainsKey('note')) { $s.note = '' }
        }
      }
    }
    foreach ($k in @($seats.Keys)) {
      if ($k -eq '00') { continue }
      $num = 0
      if (-not [int]::TryParse($k, [ref]$num) -or $num -lt 1 -or $num -gt $n) { $seats.Remove($k) }
    }
    $st.seats = $seats
    return $st
  }

  function Save-StateFile($st, $path) {
    $obj = [ordered]@{
      _schema       = 'teacher-desk-v1'
      exportedAt    = (Get-Date).ToString('o')
      classLabel    = $st.classLabel
      seatCount     = $st.seatCount
      deadline      = $st.deadline
      sendChannel   = $st.sendChannel
      returnChannel = $st.returnChannel
      seats         = [ordered]@{}
    }
    foreach ($k in ($st.seats.Keys | Sort-Object)) {
      $obj.seats[$k] = $st.seats[$k]
    }
    $json = $obj | ConvertTo-Json -Depth 6
    $enc = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($path, $json, $enc)
  }

  function Load-StateFile($path) {
    if (-not (Test-Path -LiteralPath $path)) { return (Ensure-State (Get-DefaultState)) }
    try {
      $obj = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
      $st = @{
        classLabel    = [string]$obj.classLabel
        seatCount     = [int]$obj.seatCount
        deadline      = [string]$obj.deadline
        sendChannel   = [string]$obj.sendChannel
        returnChannel = [string]$obj.returnChannel
        seats         = $obj.seats
      }
      return (Ensure-State $st)
    } catch {
      return (Ensure-State (Get-DefaultState))
    }
  }


  function Get-SeatRoundFromName([string]$fileName) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $seat = ''
    $round = 1
    $m = [regex]::Match($base, '(\d{1,2})\s*[-_ ]\s*[RrＲｒ]\s*0*(\d{1,2})\b')
    if ($m.Success) {
      $seat = '{0:D2}' -f [int]$m.Groups[1].Value
      $round = [Math]::Max(1, [int]$m.Groups[2].Value)
      return @{ SeatId = $seat; Round = $round }
    }
    $m = [regex]::Match($base, '^(\d{1,2})$')
    if ($m.Success) {
      $seat = '{0:D2}' -f [int]$m.Groups[1].Value
      return @{ SeatId = $seat; Round = $round }
    }
    $m = [regex]::Match($base, '(?:座號|座)\s*(\d{1,2})\b')
    if ($m.Success) {
      $seat = '{0:D2}' -f [int]$m.Groups[1].Value
      return @{ SeatId = $seat; Round = $round }
    }
    return @{ SeatId = $seat; Round = $round }
  }

  function Get-SuggestedScanName([string]$seatId, [int]$round, [string]$fileName) {
    $sid = if ($seatId) { $seatId } else { '00' }
    $ext = [System.IO.Path]::GetExtension($fileName)
    if ([string]::IsNullOrWhiteSpace($ext)) { $ext = '.pdf' }
    return ('{0}-R{1:D2}{2}' -f $sid, $round, $ext.ToLowerInvariant())
  }

  $script:StatePath = Join-Path $WorkDir '班級狀態.json'
  $script:State = Load-StateFile $statePath
  $script:SelectedId = $null
  $Levels = @('未標', '跟上', '略落後', '明顯落後', '需補先備')
  $Sends = @('未發', '已發', '待回', '已回')

  function Get-LevelColor([string]$level) {
    switch ($level) {
      '跟上'     { return [System.Drawing.Color]::FromArgb(220, 245, 230) }
      '略落後'   { return [System.Drawing.Color]::FromArgb(255, 248, 220) }
      '明顯落後' { return [System.Drawing.Color]::FromArgb(255, 235, 220) }
      '需補先備' { return [System.Drawing.Color]::FromArgb(255, 228, 228) }
      default    { return [System.Drawing.Color]::FromArgb(245, 248, 246) }
    }
  }

  function Build-SendMessage {
    $ids = @()
    foreach ($k in ($script:State.seats.Keys | Sort-Object)) {
      if ($script:State.seats[$k].send -eq '未發') { $ids += $k }
    }
    if ($ids.Count -eq 0) {
      foreach ($k in ($script:State.seats.Keys | Sort-Object)) {
        $s = $script:State.seats[$k]
        if ($s.send -ne '已回' -and ($s.send -in @('已發', '待回') -or $s.level -in @('略落後', '明顯落後', '需補先備'))) {
          $ids += $k
        }
      }
    }
    $list = if ($ids.Count) { ($ids -join '、') } else { '（請先把要發的座號標成未發）' }
    return @"
【$($script:State.classLabel)｜今日練習】
請座號：$list
1. 依老師發的檔／連結完成練習
2. 完成後請個別傳給老師，不要傳班級群組
3. 截止：$($script:State.deadline)
"@
  }

  $uiFont = New-UiFont 10
  $form = New-Object System.Windows.Forms.Form
  $form.Text = '習作台｜掌握與發送'
  $form.Size = New-Object System.Drawing.Size(920, 680)
  $form.StartPosition = 'CenterScreen'
  $form.Font = $uiFont
  $form.BackColor = [System.Drawing.Color]::FromArgb(232, 239, 230)
  $form.MinimizeBox = $true
  $form.MaximizeBox = $true

  $top = New-Object System.Windows.Forms.Panel
  $top.Dock = 'Top'
  $top.Height = 70
  $top.BackColor = [System.Drawing.Color]::FromArgb(45, 106, 79)
  $form.Controls.Add($top)

  $lblBrand = New-Object System.Windows.Forms.Label
  $lblBrand.Text = '習作台'
  $lblBrand.ForeColor = [System.Drawing.Color]::White
  $lblBrand.Font = New-UiFont 16 ([System.Drawing.FontStyle]::Bold)
  $lblBrand.Location = New-Object System.Drawing.Point(14, 10)
  $lblBrand.AutoSize = $true
  $top.Controls.Add($lblBrand)

  $lblSub = New-Object System.Windows.Forms.Label
  $lblSub.Text = '掌握程度／發送 · 複製群發文案（只用座號）'
  $lblSub.ForeColor = [System.Drawing.Color]::FromArgb(220, 240, 230)
  $lblSub.Location = New-Object System.Drawing.Point(16, 42)
  $lblSub.AutoSize = $true
  $top.Controls.Add($lblSub)

  $lblClass = New-Object System.Windows.Forms.Label
  $lblClass.Text = '班級'; $lblClass.Location = New-Object System.Drawing.Point(16, 84); $lblClass.AutoSize = $true
  $form.Controls.Add($lblClass)
  $txtClass = New-Object System.Windows.Forms.TextBox
  $txtClass.Text = $script:State.classLabel
  $txtClass.Location = New-Object System.Drawing.Point(56, 80); $txtClass.Width = 120
  $form.Controls.Add($txtClass)

  $lblCount = New-Object System.Windows.Forms.Label
  $lblCount.Text = '人數'; $lblCount.Location = New-Object System.Drawing.Point(190, 84); $lblCount.AutoSize = $true
  $form.Controls.Add($lblCount)
  $numSeats = New-Object System.Windows.Forms.NumericUpDown
  $numSeats.Minimum = 1; $numSeats.Maximum = 60
  $numSeats.Value = [Math]::Max(1, [Math]::Min(60, [decimal]$script:State.seatCount))
  $numSeats.Location = New-Object System.Drawing.Point(230, 80); $numSeats.Width = 55
  $form.Controls.Add($numSeats)

  $lblDl = New-Object System.Windows.Forms.Label
  $lblDl.Text = '截止'; $lblDl.Location = New-Object System.Drawing.Point(300, 84); $lblDl.AutoSize = $true
  $form.Controls.Add($lblDl)
  $txtDeadline = New-Object System.Windows.Forms.TextBox
  $txtDeadline.Text = $script:State.deadline
  $txtDeadline.Location = New-Object System.Drawing.Point(340, 80); $txtDeadline.Width = 110
  $form.Controls.Add($txtDeadline)

  $btnApply = New-Object System.Windows.Forms.Button
  $btnApply.Text = '套用'
  $btnApply.Location = New-Object System.Drawing.Point(460, 78); $btnApply.Width = 70
  $form.Controls.Add($btnApply)

  $lblSendCh = New-Object System.Windows.Forms.Label
  $lblSendCh.Text = '發放'
  $lblSendCh.Location = New-Object System.Drawing.Point(16, 112)
  $lblSendCh.AutoSize = $true
  $form.Controls.Add($lblSendCh)
  $cmbSendCh = New-Object System.Windows.Forms.ComboBox
  $cmbSendCh.DropDownStyle = 'DropDownList'
  $cmbSendCh.Location = New-Object System.Drawing.Point(56, 108)
  $cmbSendCh.Width = 160
  @('line_group', 'classroom', 'drive', 'lms') | ForEach-Object { [void]$cmbSendCh.Items.Add($_) }
  $idxSend = $cmbSendCh.Items.IndexOf([string]$script:State.sendChannel)
  $cmbSendCh.SelectedIndex = $(if ($idxSend -ge 0) { $idxSend } else { 0 })
  $form.Controls.Add($cmbSendCh)

  $lblRetCh = New-Object System.Windows.Forms.Label
  $lblRetCh.Text = '回傳'
  $lblRetCh.Location = New-Object System.Drawing.Point(230, 112)
  $lblRetCh.AutoSize = $true
  $form.Controls.Add($lblRetCh)
  $cmbRetCh = New-Object System.Windows.Forms.ComboBox
  $cmbRetCh.DropDownStyle = 'DropDownList'
  $cmbRetCh.Location = New-Object System.Drawing.Point(270, 108)
  $cmbRetCh.Width = 160
  @('line_dm', 'classroom', 'drive', 'lms') | ForEach-Object { [void]$cmbRetCh.Items.Add($_) }
  $idxRet = $cmbRetCh.Items.IndexOf([string]$script:State.returnChannel)
  $cmbRetCh.SelectedIndex = $(if ($idxRet -ge 0) { $idxRet } else { 0 })
  $form.Controls.Add($cmbRetCh)

  $lblFilter = New-Object System.Windows.Forms.Label
  $lblFilter.Text = '篩選'
  $lblFilter.Location = New-Object System.Drawing.Point(450, 112)
  $lblFilter.AutoSize = $true
  $form.Controls.Add($lblFilter)
  $cmbFilter = New-Object System.Windows.Forms.ComboBox
  $cmbFilter.DropDownStyle = 'DropDownList'
  $cmbFilter.Location = New-Object System.Drawing.Point(490, 108)
  $cmbFilter.Width = 120
  @('全部', '未發', '待回', '需關注', '需補先備') | ForEach-Object { [void]$cmbFilter.Items.Add($_) }
  $cmbFilter.SelectedIndex = 0
  $form.Controls.Add($cmbFilter)

  $lblSummary = New-Object System.Windows.Forms.Label
  $lblSummary.Location = New-Object System.Drawing.Point(620, 112); $lblSummary.AutoSize = $true
  $lblSummary.ForeColor = [System.Drawing.Color]::FromArgb(45, 106, 79)
  $form.Controls.Add($lblSummary)

  $lblFlow = New-Object System.Windows.Forms.Label
  $lblFlow.Text = '今日流程：批改→程度→自產練習→發放→習作台標發送→回傳循環／歷程｜換機傳 0803同步包'
  $lblFlow.Location = New-Object System.Drawing.Point(16, 140)
  $lblFlow.Size = New-Object System.Drawing.Size(880, 22)
  $lblFlow.ForeColor = [System.Drawing.Color]::FromArgb(60, 80, 70)
  $form.Controls.Add($lblFlow)

  $gridHost = New-Object System.Windows.Forms.FlowLayoutPanel
  $gridHost.Location = New-Object System.Drawing.Point(16, 168)
  $gridHost.Size = New-Object System.Drawing.Size(520, 340)
  $gridHost.AutoScroll = $true
  $gridHost.WrapContents = $true
  $gridHost.Anchor = 'Top,Bottom,Left'
  $form.Controls.Add($gridHost)

  $right = New-Object System.Windows.Forms.Panel
  $right.Location = New-Object System.Drawing.Point(550, 168)
  $right.Size = New-Object System.Drawing.Size(340, 400)
  $right.Anchor = 'Top,Bottom,Right'
  $form.Controls.Add($right)

  $lblSid = New-Object System.Windows.Forms.Label
  $lblSid.Text = '座號：—（請點左側）'
  $lblSid.Font = New-UiFont 11 ([System.Drawing.FontStyle]::Bold)
  $lblSid.AutoSize = $true
  $right.Controls.Add($lblSid)

  $lblLevel = New-Object System.Windows.Forms.Label
  $lblLevel.Text = '程度'
  $lblLevel.Location = New-Object System.Drawing.Point(0, 38)
  $lblLevel.AutoSize = $true
  $right.Controls.Add($lblLevel)

  $cmbLevel = New-Object System.Windows.Forms.ComboBox
  $cmbLevel.DropDownStyle = 'DropDownList'
  $cmbLevel.Location = New-Object System.Drawing.Point(40, 34); $cmbLevel.Width = 110
  $Levels | ForEach-Object { [void]$cmbLevel.Items.Add($_) }
  $cmbLevel.SelectedIndex = 0
  $right.Controls.Add($cmbLevel)

  $lblSend = New-Object System.Windows.Forms.Label
  $lblSend.Text = '發送'
  $lblSend.Location = New-Object System.Drawing.Point(160, 38)
  $lblSend.AutoSize = $true
  $right.Controls.Add($lblSend)

  $cmbSend = New-Object System.Windows.Forms.ComboBox
  $cmbSend.DropDownStyle = 'DropDownList'
  $cmbSend.Location = New-Object System.Drawing.Point(200, 34); $cmbSend.Width = 110
  $Sends | ForEach-Object { [void]$cmbSend.Items.Add($_) }
  $cmbSend.SelectedIndex = 0
  $right.Controls.Add($cmbSend)

  $btnSaveSeat = New-Object System.Windows.Forms.Button
  $btnSaveSeat.Text = '儲存此座號'
  $btnSaveSeat.Location = New-Object System.Drawing.Point(0, 80)
  $btnSaveSeat.Size = New-Object System.Drawing.Size(310, 34)
  $btnSaveSeat.BackColor = [System.Drawing.Color]::FromArgb(45, 106, 79)
  $btnSaveSeat.ForeColor = [System.Drawing.Color]::White
  $btnSaveSeat.FlatStyle = 'Flat'
  $right.Controls.Add($btnSaveSeat)

  $btnCopySend = New-Object System.Windows.Forms.Button
  $btnCopySend.Text = '複製群發文'
  $btnCopySend.Location = New-Object System.Drawing.Point(0, 126)
  $btnCopySend.Size = New-Object System.Drawing.Size(150, 36)
  $btnCopySend.BackColor = [System.Drawing.Color]::FromArgb(45, 106, 79)
  $btnCopySend.ForeColor = [System.Drawing.Color]::White
  $btnCopySend.FlatStyle = 'Flat'
  $right.Controls.Add($btnCopySend)

  $btnCopyRet = New-Object System.Windows.Forms.Button
  $btnCopyRet.Text = '複製回傳說明'
  $btnCopyRet.Location = New-Object System.Drawing.Point(160, 126)
  $btnCopyRet.Size = New-Object System.Drawing.Size(150, 36)
  $right.Controls.Add($btnCopyRet)

  $btnMarkSent = New-Object System.Windows.Forms.Button
  $btnMarkSent.Text = '未發→已發'
  $btnMarkSent.Location = New-Object System.Drawing.Point(0, 168)
  $btnMarkSent.Size = New-Object System.Drawing.Size(150, 30)
  $right.Controls.Add($btnMarkSent)

  $btnMarkPending = New-Object System.Windows.Forms.Button
  $btnMarkPending.Text = '已發→待回'
  $btnMarkPending.Location = New-Object System.Drawing.Point(160, 168)
  $btnMarkPending.Size = New-Object System.Drawing.Size(150, 30)
  $right.Controls.Add($btnMarkPending)

  $btnProcessScan = New-Object System.Windows.Forms.Button
  $btnProcessScan.Text = '處理掃描匯入'
  $btnProcessScan.Location = New-Object System.Drawing.Point(0, 210)
  $btnProcessScan.Size = New-Object System.Drawing.Size(310, 34)
  $btnProcessScan.BackColor = [System.Drawing.Color]::FromArgb(45, 106, 79)
  $btnProcessScan.ForeColor = [System.Drawing.Color]::White
  $btnProcessScan.FlatStyle = 'Flat'
  $right.Controls.Add($btnProcessScan)

  $btnExport = New-Object System.Windows.Forms.Button
  $btnExport.Text = '匯出班級資料'
  $btnExport.Location = New-Object System.Drawing.Point(0, 252)
  $btnExport.Size = New-Object System.Drawing.Size(150, 30)
  $right.Controls.Add($btnExport)

  $btnImport = New-Object System.Windows.Forms.Button
  $btnImport.Text = '匯入班級資料'
  $btnImport.Location = New-Object System.Drawing.Point(160, 252)
  $btnImport.Size = New-Object System.Drawing.Size(150, 30)
  $right.Controls.Add($btnImport)

  $btnImportGrader = New-Object System.Windows.Forms.Button
  $btnImportGrader.Text = '從批改進度匯入程度'
  $btnImportGrader.Location = New-Object System.Drawing.Point(0, 290)
  $btnImportGrader.Size = New-Object System.Drawing.Size(310, 30)
  $right.Controls.Add($btnImportGrader)

  $btnExportPack = New-Object System.Windows.Forms.Button
  $btnExportPack.Text = '匯出0803同步包'
  $btnExportPack.Location = New-Object System.Drawing.Point(0, 328)
  $btnExportPack.Size = New-Object System.Drawing.Size(150, 30)
  $btnExportPack.BackColor = [System.Drawing.Color]::FromArgb(45, 106, 79)
  $btnExportPack.ForeColor = [System.Drawing.Color]::White
  $btnExportPack.FlatStyle = 'Flat'
  $right.Controls.Add($btnExportPack)

  $btnImportPack = New-Object System.Windows.Forms.Button
  $btnImportPack.Text = '匯入0803同步包'
  $btnImportPack.Location = New-Object System.Drawing.Point(160, 328)
  $btnImportPack.Size = New-Object System.Drawing.Size(150, 30)
  $right.Controls.Add($btnImportPack)

  $btnOpenWork = New-Object System.Windows.Forms.Button
  $btnOpenWork.Text = '開啟工作夾'
  $btnOpenWork.Location = New-Object System.Drawing.Point(0, 366)
  $btnOpenWork.Size = New-Object System.Drawing.Size(150, 30)
  $right.Controls.Add($btnOpenWork)

  $btnOpenScan = New-Object System.Windows.Forms.Button
  $btnOpenScan.Text = '開掃描匯入夾'
  $btnOpenScan.Location = New-Object System.Drawing.Point(160, 366)
  $btnOpenScan.Size = New-Object System.Drawing.Size(150, 30)
  $right.Controls.Add($btnOpenScan)

  $txtPreview = New-Object System.Windows.Forms.TextBox
  $txtPreview.Multiline = $true
  $txtPreview.ScrollBars = 'Vertical'
  $txtPreview.ReadOnly = $true
  $txtPreview.Location = New-Object System.Drawing.Point(16, 580)
  $txtPreview.Size = New-Object System.Drawing.Size(874, 100)
  $txtPreview.Anchor = 'Left,Right,Bottom'
  $form.Controls.Add($txtPreview)

  $form.Size = New-Object System.Drawing.Size(920, 740)

  function Build-ReturnMessage {
    $mapSend = @{
      line_group = '通訊軟體班級群組公告'
      classroom  = 'Google 教室作業'
      drive      = '雲端「數位練習」連結'
      lms        = '學校平台／email'
    }
    $mapRet = @{
      line_dm   = '通訊軟體個別傳給老師（圖／PDF）'
      classroom = 'Google 教室繳交'
      drive     = '雲端回傳夾'
      lms       = '學校平台／email'
    }
    $s = $mapSend[[string]$script:State.sendChannel]
    $r = $mapRet[[string]$script:State.returnChannel]
    if (-not $s) { $s = '老師指定方式' }
    if (-not $r) { $r = '個別傳給老師' }
    return @"
【回傳說明｜$($script:State.classLabel)】
發放：$s
回傳：$r
截止：$($script:State.deadline)
檔名建議：座號-R次數（例 05-R01.pdf）
"@
  }

  function Update-SummaryLabel {
    $c = @{ '跟上' = 0; '略落後' = 0; '明顯落後' = 0; '需補先備' = 0; '未發' = 0 }
    foreach ($k in $script:State.seats.Keys) {
      $s = $script:State.seats[$k]
      if ($c.ContainsKey([string]$s.level)) { $c[[string]$s.level]++ }
      if ($s.send -eq '未發') { $c['未發']++ }
    }
    $lblSummary.Text = ("跟上{0} 略落後{1} 明顯{2} 先備{3}｜未發{4}" -f $c['跟上'], $c['略落後'], $c['明顯落後'], $c['需補先備'], $c['未發'])
  }

  function Test-SeatVisible([string]$id, $seat) {
    $f = [string]$cmbFilter.SelectedItem
    if (-not $f -or $f -eq '全部') { return $true }
    if ($f -eq '未發') { return ($seat.send -eq '未發') }
    if ($f -eq '待回') { return ($seat.send -eq '待回') }
    if ($f -eq '需補先備') { return ($seat.level -eq '需補先備') }
    if ($f -eq '需關注') {
      return ($seat.level -in @('略落後', '明顯落後', '需補先備') -or $seat.send -in @('未發', '待回'))
    }
    return $true
  }

  function Refresh-Grid {
    $gridHost.SuspendLayout()
    $gridHost.Controls.Clear()
    foreach ($k in ($script:State.seats.Keys | Sort-Object)) {
      $s = $script:State.seats[$k]
      if (-not (Test-SeatVisible $k $s)) { continue }
      $b = New-Object System.Windows.Forms.Button
      $b.Size = New-Object System.Drawing.Size(68, 48)
      $b.Margin = New-Object System.Windows.Forms.Padding(3)
      $b.FlatStyle = 'Flat'
      $b.Text = ($k + "`n" + $s.send)
      $b.BackColor = Get-LevelColor ([string]$s.level)
      $b.Tag = $k
      $b.Add_Click({
        param($sender, $eventArgs)
        $id = [string]$sender.Tag
        $script:SelectedId = $id
        $seat = $script:State.seats[$id]
        $lblSid.Text = "座號：$id"
        $cmbLevel.SelectedItem = [string]$seat.level
        $cmbSend.SelectedItem = [string]$seat.send
      })
      [void]$gridHost.Controls.Add($b)
    }
    $gridHost.ResumeLayout()
    Update-SummaryLabel
    $txtPreview.Text = Build-SendMessage
  }

  function Persist-Header {
    $script:State.classLabel = $txtClass.Text.Trim()
    if (-not $script:State.classLabel) { $script:State.classLabel = '本班數學' }
    $script:State.deadline = $txtDeadline.Text.Trim()
    if (-not $script:State.deadline) { $script:State.deadline = '今晚 21:00' }
    $script:State.seatCount = [int]$numSeats.Value
    $script:State.sendChannel = [string]$cmbSendCh.SelectedItem
    $script:State.returnChannel = [string]$cmbRetCh.SelectedItem
    $script:State = Ensure-State $script:State
    Save-StateFile $script:State $script:StatePath
  }

  $btnApply.Add_Click({
    Persist-Header
    Refresh-Grid
  })
  $btnSaveSeat.Add_Click({
    if (-not $script:SelectedId) {
      [void][System.Windows.Forms.MessageBox]::Show('請先點左側座號。', '習作台')
      return
    }
    Persist-Header
    $id = $script:SelectedId
    $script:State.seats[$id].level = [string]$cmbLevel.SelectedItem
    $script:State.seats[$id].send = [string]$cmbSend.SelectedItem
    Save-StateFile $script:State $script:StatePath
    Refresh-Grid
  })
  $btnCopySend.Add_Click({
    Persist-Header
    $msg = Build-SendMessage
    [System.Windows.Forms.Clipboard]::SetText($msg)
    $txtPreview.Text = $msg
    [void][System.Windows.Forms.MessageBox]::Show('已複製，請貼到班級群組。', '習作台')
  })
  $btnCopyRet.Add_Click({
    Persist-Header
    $msg = Build-ReturnMessage
    [System.Windows.Forms.Clipboard]::SetText($msg)
    $txtPreview.Text = $msg
    [void][System.Windows.Forms.MessageBox]::Show('已複製回傳說明。', '習作台')
  })
  $cmbFilter.Add_SelectedIndexChanged({ Refresh-Grid })
  $btnMarkSent.Add_Click({
    Persist-Header
    foreach ($k in @($script:State.seats.Keys)) {
      if ($script:State.seats[$k].send -eq '未發') { $script:State.seats[$k].send = '已發' }
    }
    Save-StateFile $script:State $script:StatePath
    Refresh-Grid
  })

  $btnMarkPending.Add_Click({
    Persist-Header
    foreach ($k in @($script:State.seats.Keys)) {
      if ($script:State.seats[$k].send -eq '已發') { $script:State.seats[$k].send = '待回' }
    }
    Save-StateFile $script:State $script:StatePath
    Refresh-Grid
  })

  $btnProcessScan.Add_Click({
    Persist-Header
    $scanDir = Join-Path $WorkDir '掃描匯入'
    $outDir = Join-Path $WorkDir '練習回傳'
    New-Item -ItemType Directory -Force -Path $scanDir, $outDir | Out-Null
    $files = @(Get-ChildItem -LiteralPath $scanDir -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Extension -match '\.(pdf|png|jpe?g|gif|webp|heic|heif)$' })
    if ($files.Count -eq 0) {
      [void][System.Windows.Forms.MessageBox]::Show("掃描匯入夾沒有 PDF／圖片檔。`r`n請把手機下載的 05-R01.pdf 放到：`r`n$scanDir", '習作台')
      return
    }
    $done = 0
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($f in $files) {
      $g = Get-SeatRoundFromName $f.Name
      $sid = $g.SeatId
      if (-not $sid -or -not $script:State.seats.ContainsKey($sid)) {
        $lines.Add(("略過 {0}（無法對應座號）" -f $f.Name))
        continue
      }
      $round = [int]$g.Round
      if ($round -lt 1) { $round = 1 }
      $outName = Get-SuggestedScanName $sid $round $f.Name
      $dest = Join-Path $outDir $outName
      Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
      $script:State.seats[$sid].send = '待回'
      if (-not $script:State.seats[$sid].note) {
        $script:State.seats[$sid].note = ('掃描回傳 R{0:D2}' -f $round)
      }
      $done++
      $lines.Add(("$($f.Name) → $outName（座號 $sid 標待回）"))
    }
    Save-StateFile $script:State $script:StatePath
    Refresh-Grid
    $msg = "已處理 $done 個檔，輸出到：`r`n$outDir`r`n`r`n" + ($lines -join "`r`n")
    [void][System.Windows.Forms.MessageBox]::Show($msg, '習作台｜掃描匯入')
  })

  $btnExport.Add_Click({
    Persist-Header
    $exportDir = Join-Path $WorkDir '匯出給手機'
    New-Item -ItemType Directory -Force -Path $exportDir | Out-Null
    $out = Join-Path $exportDir '班級狀態.json'
    Save-StateFile $script:State $out
    # 相容舊檔名
    Copy-Item -LiteralPath $out -Destination (Join-Path $exportDir 'class-state.json') -Force
    [void][System.Windows.Forms.MessageBox]::Show("已匯出：`r`n$out`r`n可傳到另一台電腦／手機習作台匯入。`r`n換機請一併帶「習作批改進度.json」。", '習作台')
    Start-Process explorer.exe $exportDir
  })

  $btnImport.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = '班級資料檔 (*.json)|*.json|所有檔案 (*.*)|*.*'
    $dlg.Title = '匯入班級資料'
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    try {
      $rawObj = Get-Content -LiteralPath $dlg.FileName -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($rawObj._schema -eq 'math-grader-v1') {
        [void][System.Windows.Forms.MessageBox]::Show('這是習作批改進度檔。請改按「從批改進度匯入程度」。', '習作台')
        return
      }
      $script:State = Load-StateFile $dlg.FileName
      $script:StatePath = Join-Path $WorkDir '班級狀態.json'
      Save-StateFile $script:State $script:StatePath
      $txtClass.Text = $script:State.classLabel
      $txtDeadline.Text = $script:State.deadline
      $numSeats.Value = [Math]::Max(1, [Math]::Min(60, [decimal]$script:State.seatCount))
      $script:SelectedId = $null
      $lblSid.Text = '座號：—（請點左側）'
      Refresh-Grid
      [void][System.Windows.Forms.MessageBox]::Show('已匯入並覆蓋本機班級資料。', '習作台')
    } catch {
      [void][System.Windows.Forms.MessageBox]::Show("匯入失敗：$($_.Exception.Message)", '習作台')
    }
  })

  $btnImportGrader.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = '批改進度 (*.json)|*.json|所有檔案 (*.*)|*.*'
    $dlg.Title = '匯入習作批改進度（只更新程度）'
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    try {
      $g = Get-Content -LiteralPath $dlg.FileName -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($g._schema -eq 'teacher-desk-v1') {
        [void][System.Windows.Forms.MessageBox]::Show('這是班級狀態檔。請改按「匯入班級資料」。', '習作台')
        return
      }
      if (-not $g.seats) { throw '檔案沒有 seats' }
      Persist-Header
      $n = 0
      foreach ($p in $g.seats.PSObject.Properties) {
        $id = [string]$p.Name
        $src = $p.Value
        if (-not $src) { continue }
        if (-not $script:State.seats.ContainsKey($id)) {
          $num = 0
          if ($id -eq '00' -or ([int]::TryParse($id, [ref]$num) -and $num -ge 1 -and $num -le [int]$script:State.seatCount)) {
            $script:State.seats[$id] = @{ level = '未標'; send = '未發'; note = $(if ($id -eq '00') { '試發' } else { '' }) }
          } else { continue }
        }
        $lv = [string]$src.level
        if ($lv -and $lv -ne '未標' -and $lv -ne '待判定') {
          $script:State.seats[$id].level = $lv
          $n++
        } elseif ($lv -eq '待判定') {
          $script:State.seats[$id].level = '需補先備'
          $n++
        }
        $st = [string]$src.status
        if (($st -eq '已批' -or $st -eq '待認知') -and $src.note) {
          $script:State.seats[$id].note = ([string]$src.note).Substring(0, [Math]::Min(40, ([string]$src.note).Length))
        }
      }
      if ($g.classLabel) { $script:State.classLabel = [string]$g.classLabel; $txtClass.Text = $script:State.classLabel }
      if ($g.seatCount) {
        $script:State.seatCount = [int]$g.seatCount
        $numSeats.Value = [Math]::Max(1, [Math]::Min(60, [decimal]$script:State.seatCount))
      }
      $script:State = Ensure-State $script:State
      Save-StateFile $script:State $script:StatePath
      Refresh-Grid
      $msg = if ($n -gt 0) { "已從批改進度匯入 $n 個座號程度。" } else { '檔案裡沒有可匯入的程度。' }
      [void][System.Windows.Forms.MessageBox]::Show($msg, '習作台')
    } catch {
      [void][System.Windows.Forms.MessageBox]::Show("匯入失敗：$($_.Exception.Message)", '習作台')
    }
  })

  $btnExportPack.Add_Click({
    Persist-Header
    $exportDir = Join-Path $WorkDir '匯出給手機'
    New-Item -ItemType Directory -Force -Path $exportDir | Out-Null
    $mgOut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'MathGrading\輸出\習作批改進度.json'
    $grader = $null
    if (Test-Path -LiteralPath $mgOut) {
      try { $grader = Get-Content -LiteralPath $mgOut -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
    }
    if (-not $grader) {
      $seats = [ordered]@{}
      foreach ($k in ($script:State.seats.Keys | Sort-Object)) {
        $s = $script:State.seats[$k]
        $seats[$k] = @{
          status = '未批'; level = $s.level; note = $s.note; history = @{ attempts = @() }
        }
      }
      $grader = [ordered]@{
        _schema = 'math-grader-v1'; classLabel = $script:State.classLabel
        seatCount = $script:State.seatCount; seats = $seats
        features = @('0803', 'level')
      }
    }
    $deskObj = Get-Content -LiteralPath $script:StatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $pack = [ordered]@{
      _schema = 'sync-pack-v1'
      exportedAt = (Get-Date).ToString('o')
      features = @('0803', 'history', 'practice-loop', 'level', 'send', 'log')
      grader = $grader
      desk = $deskObj
    }
    $path = Join-Path $exportDir '0803同步包.json'
    $utf8Bom = New-Object System.Text.UTF8Encoding $true
    [IO.File]::WriteAllText($path, ($pack | ConvertTo-Json -Depth 10), $utf8Bom)
    [void][System.Windows.Forms.MessageBox]::Show("已匯出：`r`n$path`r`n（若桌面有批改進度會一併打包歷程）", '0803同步包')
    Start-Process explorer.exe $exportDir
  })

  $btnImportPack.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = '0803同步包 (*.json)|*.json|所有檔案 (*.*)|*.*'
    $dlg.Title = '匯入 0803 同步包'
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    try {
      $pack = Get-Content -LiteralPath $dlg.FileName -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($pack._schema -eq 'sync-pack-v1' -and $pack.desk) {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ('desk-' + [guid]::NewGuid().ToString('n') + '.json')
        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [IO.File]::WriteAllText($tmp, ($pack.desk | ConvertTo-Json -Depth 8), $utf8Bom)
        $script:State = Load-StateFile $tmp
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
      } elseif ($pack.seats -and -not $pack.grader) {
        $script:State = Load-StateFile $dlg.FileName
      } else {
        throw '請選擇 0803同步包.json'
      }
      $script:StatePath = Join-Path $WorkDir '班級狀態.json'
      Save-StateFile $script:State $script:StatePath
      $txtClass.Text = $script:State.classLabel
      $txtDeadline.Text = $script:State.deadline
      $numSeats.Value = [Math]::Max(1, [Math]::Min(60, [decimal]$script:State.seatCount))
      $si = $cmbSendCh.Items.IndexOf([string]$script:State.sendChannel)
      if ($si -ge 0) { $cmbSendCh.SelectedIndex = $si }
      $ri = $cmbRetCh.Items.IndexOf([string]$script:State.returnChannel)
      if ($ri -ge 0) { $cmbRetCh.SelectedIndex = $ri }
      # 若包內有批改進度，另存到 MathGrading 輸出供批改匯入
      if ($pack.grader) {
        $mgOutDir = Join-Path ([Environment]::GetFolderPath('Desktop')) 'MathGrading\輸出'
        New-Item -ItemType Directory -Force -Path $mgOutDir | Out-Null
        $gp = Join-Path $mgOutDir '習作批改進度.json'
        [IO.File]::WriteAllText($gp, ($pack.grader | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding $true))
      }
      Refresh-Grid
      [void][System.Windows.Forms.MessageBox]::Show('已匯入 0803 同步包（班級狀態已套用；批改進度若有則寫入 MathGrading\輸出）。', '習作台')
    } catch {
      [void][System.Windows.Forms.MessageBox]::Show("匯入失敗：$($_.Exception.Message)", '習作台')
    }
  })

  $btnOpenScan.Add_Click({
    $scanDir = Join-Path $WorkDir '掃描匯入'
    New-Item -ItemType Directory -Force -Path $scanDir | Out-Null
    Start-Process explorer.exe $scanDir
  })

  $btnOpenWork.Add_Click({ Start-Process explorer.exe $WorkDir })

  $form.Add_FormClosing({
    try {
      Persist-Header
      if ($script:SelectedId) {
        $script:State.seats[$script:SelectedId].level = [string]$cmbLevel.SelectedItem
        $script:State.seats[$script:SelectedId].send = [string]$cmbSend.SelectedItem
        Save-StateFile $script:State $script:StatePath
      }
    } catch {}
  })

  Refresh-Grid
  if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue }
  [void]$form.ShowDialog()
}
catch {
  $msg = "習作台啟動失敗（已寫入桌面「習作台錯誤.txt」）`r`n`r`n$($_.Exception.Message)`r`n`r`n$($_.ScriptStackTrace)"
  Show-Fail $msg
  exit 1
}
