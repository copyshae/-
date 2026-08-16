#Requires -Version 5.1
<#
.SYNOPSIS
  數學習作批改視窗：每人一檔輸入 → 批改後輸出每人註記檔。

.DESCRIPTION
  資料夾結構：
    工作資料夾\
      標準答案\   （放答案 PDF／圖）
      輸入\       （每位學生一個試卷 PDF／圖檔）
      輸出\       （座號-註記.md、座號-批閱註記.pdf、座號-試卷含批閱.pdf、全班存疑清單）
      認知輸入\   （老師看懂後：05-Q3.txt）
      重謄補充\   （看不懂處重謄掃描：05-Q3.pdf）

  流程：全班各自批閱 → 輸出 PDF 註記 → 彙整存疑 → 老師補認知／重謄 → 再產 PDF。
  原則：接受等價合理解法；✓ 可快速打勾；? 存疑待人工。
#>
param(
  [string]$WorkDir = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:PyMakePdf = Join-Path $script:ScriptDir 'math_grade_make_note_pdf.py'
# 視窗標題會顯示；用來確認本機是否已裝到含 AQ. 金鑰支援的版本
$script:AppBuild = '20260817-aq24'
# also check beside installed copy
if (-not (Test-Path -LiteralPath $script:PyMakePdf)) {
  $alt = Join-Path (Split-Path -Parent $script:ScriptDir) 'scripts\math_grade_make_note_pdf.py'
  if (Test-Path -LiteralPath $alt) { $script:PyMakePdf = $alt }
}

function Get-DefaultWorkDir {
  $desk = [Environment]::GetFolderPath('Desktop')
  return (Join-Path $desk 'MathGrading')
}

function Ensure-WorkTree([string]$root) {
  foreach ($n in @('標準答案', '輸入', '輸出', '認知輸入', '重謄補充', '數位練習', '列印專用', '練習回傳', '練習歷程', '手寫匯入')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $root $n) | Out-Null
  }
  $printList = Join-Path (Join-Path $root '列印專用') '需列印座號.txt'
  if (-not (Test-Path -LiteralPath $printList)) {
    @(
      '# 沒有手機／平板等通訊裝置、需要紙本練習的座號'
      '# 一行一個，或用逗號分隔，例如：03  或  07, 12, 18'
      ''
    ) | Set-Content -LiteralPath $printList -Encoding UTF8
  }
  $tabletGuide = Join-Path $root '手寫板即時批閱說明.txt'
  if (-not (Test-Path -LiteralPath $tabletGuide)) {
    @(
      '手寫板 → 即時批閱'
      '================'
      ''
      '1. 手寫板／平板寫完後，把圖檔或 PDF 存到「手寫匯入」資料夾'
      '   （也可在程式裡改成你的 OneNote／繪圖軟體匯出資料夾）'
      '2. 左側選好座號，按「手寫板匯入並批」'
      '3. 檔案會改名複製到「練習回傳」（如 05-R02.jpg），並複製 Cursor 批閱提示'
      '4. 到 Cursor 貼上並附檔 → 把回饋貼回「練習回傳循環」→ 產下一輪練習'
      ''
      '提示：檔名若已是 05-R01.jpg 會直接沿用；否則依目前座號自動編次數。'
    ) | Set-Content -LiteralPath $tabletGuide -Encoding UTF8
  }
  $hwGuide = Join-Path $root '手寫辨識加強說明.txt'
  if (-not (Test-Path -LiteralPath $hwGuide)) {
    @(
      '手寫難辨時怎麼批'
      '================'
      ''
      '1. 檔名請改成座號，試發用 00.pdf／00.jpg（不要用 S__44097539 這種 LINE 檔名）'
      '2. 批閱方式選「請 Gemini 自動批閱（API）」＝真正自動；「網頁批閱」仍要手動貼'
      '3. 首次按「Gemini金鑰」到 aistudio.google.com/apikey 貼上 key'
      '4. AI 會先給「手寫轉譯稿」＋「認知輸入清單」；看不清處標 ?'
      '5. 你把看懂的字寫進「認知輸入」：例如 05-Q3.txt 內容寫該題正確轉譯'
      '6. 仍看不清 → 請學生重謄該題，放到「重謄補充」：05-Q3.pdf'
      '7. 按「套用認知／重謄並重產PDF」'
      ''
      '拍照技巧：光線均勻、避免陰影、一次一頁、手機橫拍對齊紙邊、必要時分題特寫。'
    ) | Set-Content -LiteralPath $hwGuide -Encoding UTF8
  }
  $cogSample = Join-Path (Join-Path $root '認知輸入') '範例-05-Q3.txt'
  if (-not (Test-Path -LiteralPath $cogSample)) {
    @(
      '（範例）座號 05 第 3 題手寫轉譯'
      '原式：2/3 + 1/6 = 5/6'
      '說明：個位的 5 原先掃描像 S，老師確認是 5。'
    ) | Set-Content -LiteralPath $cogSample -Encoding UTF8
  }
  $readme = Join-Path $root '說明.txt'
  @(
    '全班試卷批改（一人一檔 → 個人 PDF 註記）'
    ''
    '1. 標準答案 →「標準答案」'
    '2. 每位學生試卷一個檔 →「輸入」（試發用 00.pdf／00.jpg；勿用 LINE 亂碼檔名）'
    '3. 批改後「輸出」會有：05-註記.md、05-批閱註記.pdf、05-試卷含批閱.pdf'
    '4. 練習題由 Cursor 自產（指導＋題＋解答＋影片）→「數位練習」'
    '5. 手寫太差：選「手寫加強批閱」→ 見「手寫辨識加強說明.txt」'
    '6. 回傳／手寫板：圖檔進「練習回傳」或「手寫匯入」→「手寫板匯入並批」'
    '7. 歷程在「練習歷程」；沒裝置才用「列印專用」'
  ) | Set-Content -LiteralPath $readme -Encoding UTF8
}

function Find-Python {
  foreach ($c in @('python', 'python3', 'py')) {
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
  }
  return $null
}

function Invoke-MakePdf {
  param(
    [string]$Root,
    [string]$Student = '',
    [switch]$UnclearList,
    [switch]$ApplyClarifications,
    [switch]$MergeOriginal,
    [switch]$ClassReport,
    [switch]$DigitalPack,
    [switch]$PrintPack,
    [switch]$PendingReturns,
    [switch]$JunyiList,
    [switch]$ProgressHtml,
    [switch]$AppendAttempt,
    [string]$AttemptJson = ''
  )
  $py = Find-Python
  if (-not $py) {
    [void][System.Windows.Forms.MessageBox]::Show('找不到 python。請先安裝 Python，並 pip install pypdf reportlab', 'PDF')
    return $false
  }
  if (-not (Test-Path -LiteralPath $script:PyMakePdf)) {
    $localPy = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'math_grade_make_note_pdf.py'
    if (Test-Path -LiteralPath $localPy) { $script:PyMakePdf = $localPy }
  }
  if (-not (Test-Path -LiteralPath $script:PyMakePdf)) {
    [void][System.Windows.Forms.MessageBox]::Show("找不到 math_grade_make_note_pdf.py`n請放到與批改程式相同資料夾", 'PDF')
    return $false
  }
  $argList = @($script:PyMakePdf, '--work-dir', $Root)
  if ($MergeOriginal) { $argList += '--merge-original' }
  if ($Student) { $argList += @('--student', $Student) }
  if ($UnclearList) { $argList += '--unclear-list' }
  if ($ApplyClarifications) { $argList += '--apply-clarifications' }
  if ($ClassReport) { $argList += '--class-report' }
  if ($DigitalPack) { $argList += '--digital-pack' }
  if ($PrintPack) { $argList += '--print-pack' }
  if ($PendingReturns) { $argList += '--pending-returns' }
  if ($JunyiList) { $argList += '--junyi-list' }
  if ($ProgressHtml) { $argList += '--progress-html' }
  if ($AppendAttempt) {
    $argList += '--append-attempt'
    if ($AttemptJson) { $argList += @('--attempt-json', $AttemptJson) }
  }
  $p = Start-Process -FilePath $py -ArgumentList $argList -Wait -PassThru -NoNewWindow
  return ($p.ExitCode -eq 0)
}

function Get-StudentId([string]$fileName) {
  $base = [IO.Path]::GetFileNameWithoutExtension($fileName)
  if ($base -match '^(\d{1,3})') { return $Matches[1].PadLeft(2, '0') }
  # 常見：座號-試卷、00-R01、掃描_05
  if ($base -match '(?:^|[^\d])(\d{1,3})(?:[^\d]|$)') { return $Matches[1].PadLeft(2, '0') }
  return $base
}

function Test-InputExtension([string]$ext) {
  if ([string]::IsNullOrWhiteSpace($ext)) { return $false }
  $e = $ext.TrimStart('.').ToLowerInvariant()
  return @('pdf','png','jpg','jpeg','tif','tiff','bmp','heic','heif','webp','gif') -contains $e
}

function Get-InputFiles([string]$root) {
  $dir = Join-Path $root '輸入'
  if (-not (Test-Path -LiteralPath $dir)) { return @() }
  Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
    Where-Object { Test-InputExtension $_.Extension } |
    Sort-Object Name
}

function Get-InputSkipped([string]$root) {
  $dir = Join-Path $root '輸入'
  if (-not (Test-Path -LiteralPath $dir)) { return @() }
  Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
    Where-Object { -not (Test-InputExtension $_.Extension) } |
    Sort-Object Name
}

function Get-NotePath([string]$root, [string]$studentId) {
  return (Join-Path (Join-Path $root '輸出') ($studentId + '-註記.md'))
}

function Get-TextbookMathPromptRule {
  return @(
    '【國中課本直式｜強制】所有算式、轉譯稿、練習題、解答一律用臺灣國中課本寫法：'
    '・加減等於用全形：＋ － ＝；乘除用 × ÷；分數寫 a／b（全形斜線）。'
    '・省略號用 ……；括號可用 （ ）；題號／選項可用 ①②③ 寫在右側。'
    '・禁止 LaTeX 與英文算式符號：不要 $$、\dfrac、\frac、\times、\cdots、\div、*、以及半形 + - = /。'
    '・直式計算請用空白對齊位值，不要用程式碼框或表格硬排。'
  ) -join "`r`n"
}

function Convert-ToWinFormsText([string]$text) {
  if ($null -eq $text) { return '' }
  $t = [string]$text
  $t = $t -replace "`r`n", "`n"
  $t = $t -replace "`r", "`n"
  $t = $t -replace "`n", "`r`n"
  return $t
}

function Convert-ToTextbookMath([string]$text) {
  if ([string]::IsNullOrEmpty($text)) { return $text }
  $lines = [regex]::Split([string]$text, '\r\n|\n|\r')
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($line in $lines) {
    if ($line -match 'https?://|www\.|youtube\.com|search_query=') {
      $out.Add($line)
      continue
    }
    $t = $line
    # 先清 LaTeX
    $t = [regex]::Replace($t, '\$\$', '')
    $t = [regex]::Replace($t, '(?<![\\])\$', '')
    $t = [regex]::Replace($t, '\\dfrac\s*\{([^{}]*)\}\s*\{([^{}]*)\}', '$1／$2')
    $t = [regex]::Replace($t, '\\frac\s*\{([^{}]*)\}\s*\{([^{}]*)\}', '$1／$2')
    $t = [regex]::Replace($t, '\\sqrt\s*\{([^{}]*)\}', '√($1)')
    $t = [regex]::Replace($t, '\\times', '×')
    $t = [regex]::Replace($t, '\\cdot', '·')
    $t = [regex]::Replace($t, '\\cdots', '……')
    $t = [regex]::Replace($t, '\\ldots', '……')
    $t = [regex]::Replace($t, '\\dots', '……')
    $t = [regex]::Replace($t, '\\div', '÷')
    $t = [regex]::Replace($t, '\\pm', '±')
    $t = [regex]::Replace($t, '\\leq|\\le', '≦')
    $t = [regex]::Replace($t, '\\geq|\\ge', '≧')
    $t = [regex]::Replace($t, '\\neq|\\ne', '≠')
    $t = [regex]::Replace($t, '\\left\(', '（')
    $t = [regex]::Replace($t, '\\right\)', '）')
    $t = [regex]::Replace($t, '\\left\[', '［')
    $t = [regex]::Replace($t, '\\right\]', '］')
    $t = [regex]::Replace($t, '\\,', ' ')
    $t = [regex]::Replace($t, '\\;', ' ')
    $t = [regex]::Replace($t, '\\!', '')
    $t = [regex]::Replace($t, '\\{|\\}', '')
    # 半形運算符 → 課本符號（避開已經是全形者）
    $t = $t -replace '\.\.\.', '……'
    $t = $t -replace '\.\.', '……'
    $t = $t -replace '=', '＝'
    $t = $t -replace '\+', '＋'
    # 減號：數字間或運算減
    $t = [regex]::Replace($t, '(?<=\d)\s*-\s*(?=\d)', '－')
    $t = [regex]::Replace($t, '(?<=[）\)])\s*-\s*(?=\d)', '－')
    $t = [regex]::Replace($t, '(?<=[＋×÷＝])\s*-\s*(?=\d)', '－')
    $t = [regex]::Replace($t, '(?<=^|[\s（\(])-(?=\d)', '－')
    $t = [regex]::Replace($t, '(?<=\d)\s*/\s*(?=\d)', '／')
    $t = [regex]::Replace($t, '(?<=\d)\s*[xX×*]\s*(?=\d)', '×')
    $t = [regex]::Replace($t, '(?<=\d)\s*÷\s*(?=\d)', '÷')
    # 半形括號 → 全形（但保留「5) 個別建議」這類章節編號的半形右括號）
    if ($t -notmatch '^\s*\d+[)）]') {
      $t = $t -replace '\(', '（'
      $t = $t -replace '\)', '）'
    } else {
      # 章節行：只轉左括號，右括號若屬「數字)」則保留半形以便分段
      $t = [regex]::Replace($t, '(?<!\d)\(', '（')
      $t = [regex]::Replace($t, '(?<!\d)\)', '）')
    }
    # (1)(2) → ①②（僅全形括號選項；勿動「1) 題號註記」這類章節標題，否則 Gemini 分段會失效）
    $circ = @{
      '1' = '①'; '2' = '②'; '3' = '③'; '4' = '④'; '5' = '⑤'
      '6' = '⑥'; '7' = '⑦'; '8' = '⑧'; '9' = '⑨'; '10' = '⑩'
    }
    foreach ($k in @('10','9','8','7','6','5','4','3','2','1')) {
      $t = [regex]::Replace($t, '\(\s*' + $k + '\s*\)', [string]$circ[$k])
    }
    $out.Add($t)
  }
  return ($out -join "`r`n")
}

function Load-Note([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) {
    return [pscustomobject]@{
      studentId = ''
      sourceFile = ''
      overall = '未批'
      level = '待判定'
      summary = ''
      diagnosis = ''
      advice = ''
      practice = ''
      itemsText = ''
    }
  }
  $raw = Get-Content -LiteralPath $path -Encoding UTF8 -Raw
  $o = [pscustomobject]@{
    studentId = ''
    sourceFile = ''
    overall = '未批'
    level = '待判定'
    summary = ''
    diagnosis = ''
    advice = ''
    practice = ''
    itemsText = ''
  }
  if ($raw -match '(?m)^- 座號[：:]\s*(.+)$') { $o.studentId = $Matches[1].Trim() }
  if ($raw -match '(?m)^- 來源檔[：:]\s*(.+)$') { $o.sourceFile = $Matches[1].Trim() }
  if ($raw -match '(?m)^- 總評[：:]\s*(.+)$') { $o.overall = $Matches[1].Trim() }
  if ($raw -match '(?m)^- 程度[：:]\s*(.+)$') { $o.level = $Matches[1].Trim() }
  if ($raw -match '(?s)## 對錯摘要\s*(.*?)(?=##|$)') { $o.summary = $Matches[1].Trim() }
  if ($raw -match '(?s)## 個別診斷結果\s*(.*?)(?=##|$)') { $o.diagnosis = $Matches[1].Trim() }
  elseif ($raw -match '(?s)## 個別建議\s*(.*?)(?=##|$)') { $o.advice = $Matches[1].Trim() }
  if ($raw -match '(?s)## 個別建議\s*(.*?)(?=##|$)') { $o.advice = $Matches[1].Trim() }
  if ($raw -match '(?s)## 依程度自學／補救練習\s*(.*?)(?=##|$)') { $o.practice = $Matches[1].Trim() }
  elseif ($raw -match '(?s)## 需再練習\s*(.*?)(?=##|$)') { $o.practice = $Matches[1].Trim() }
  if ($raw -match '(?s)## 題號註記\s*(.*?)(?=##|$)') { $o.itemsText = $Matches[1].Trim() }
  return $o
}

function Get-PracticeTemplate([string]$level) {
  switch -Regex ($level) {
    '跟上' {
      return @"
### 程度：跟上｜目標：再提升（少重複、多挑戰）
說明：已掌握本單元。A 少練；重心 B、C。禁止整份只改數字。不使用均一；練習／指導／影片由此產生。

#### 自學指導（先看再做）
- 重點觀念：________
- 解題步驟口訣：________
- 易錯提醒：________

#### 建議影片／學習連結（1～2 個）
- 搜尋關鍵詞：________
- 連結：https://www.youtube.com/results?search_query=________
- 備用關鍵詞：________

#### 練習題（先做完再看解答）
【A 鞏固｜少而精】
1. …
【B 靈活】
2. …
3. …
【C 再提升｜必做】
4. …
5. …
6. …
【D 超前伸展｜選做】
7. …

---
#### 解答（全部題目完成後再看）
1. …
2. …
3. …
4. …
5. …
6. …
7. …
提升小提示：挑戰題做完寫「我多學到什麼」。
"@
    }
    '略落後' {
      return @"
### 程度：略落後｜目標：跟上本單元
先復習：________（本單元核心觀念）
不使用均一；練習／指導／影片由此產生。

#### 自學指導（先看再做）
- 先搞懂：________
- 步驟：1) … 2) … 3) …
- 做完自問：________

#### 建議影片／學習連結
- 搜尋關鍵詞：________
- 連結：https://www.youtube.com/results?search_query=________

#### 練習題（先做完再看解答）
【A 關鍵基本】
1. …
2. …
3. …
【B 對應錯題類型】
4. …
5. …

---
#### 解答（全部題目完成後再看）
1. …
2. …
3. …
4. …
5. …
"@
    }
    '明顯落後' {
      return @"
### 程度：明顯落後｜目標：多次補齊、每次有成就（漸次跟上）
原則：每次只補 1 個小洞、題數 ≤ 3；做對就停，隔日再補。
本次只補：________
不使用均一；練習／指導／影片由此自動產生。

#### 自學指導（短、好懂）
- 今天只要會：________
- 跟著做：第一步… → 第二步… → 第三步…
- 做對的樣子：（簡短示範）

#### 建議影片／學習連結（對準本次這 1 點）
- 搜尋關鍵詞：________（年級＋單元＋教學）
- 連結：https://www.youtube.com/results?search_query=________
- 看片重點：________（不必整部）

#### 練習題（≤3 題）
【A 本次小洞｜求做對有成就】
1. …
2. …
【B 極簡銜接｜選做】
3. …

---
#### 解答（逐步寫）
1. …
2. …
3. …
說明：本次成功＝有成就；其餘下次再補。
"@
    }
    '需補先備' {
      return @"
### 程度：需補先備｜目標：分次回到起點（多次補齊）
本次只補：________（1 個觀念）
尚未補、下次再補：________
不使用均一；練習／指導／影片由此產生。

#### 自學指導
- 先回到：________
- 超短步驟：________
- 不會就先看影片再做 1～2 題

#### 建議影片／學習連結（先備觀念）
- 搜尋關鍵詞：________
- 連結：https://www.youtube.com/results?search_query=________

#### 練習題（≤3 題）
1. …
2. …
3. （選做）

---
#### 解答
1. …
2. …
3. …
建議：與導師協調；家長說明「多次小補」。
"@
    }
    default {
      return @"
### 程度：待判定
#### 自學指導
- …
#### 建議影片／學習連結
- 搜尋關鍵詞：…
- 連結：https://www.youtube.com/results?search_query=…
#### 練習題（先做完再看解答）
1. …
---
#### 解答（全部題目完成後再看）
1. …
"@
    }
  }
}

function Save-Note {
  param(
    [string]$Root,
    [string]$StudentId,
    [string]$SourceFile,
    [string]$Overall,
    [string]$Level,
    [string]$ItemsText,
    [string]$Summary,
    [string]$Diagnosis,
    [string]$Advice,
    [string]$Practice
  )
  $path = Get-NotePath $Root $StudentId
  if ([string]::IsNullOrWhiteSpace($Practice)) {
    $Practice = Get-PracticeTemplate $Level
  }
  $ItemsText = Convert-ToTextbookMath (Convert-ToWinFormsText $ItemsText)
  $Summary = Convert-ToTextbookMath (Convert-ToWinFormsText $Summary)
  $Diagnosis = Convert-ToTextbookMath (Convert-ToWinFormsText $Diagnosis)
  $Advice = Convert-ToTextbookMath (Convert-ToWinFormsText $Advice)
  $Practice = Convert-ToTextbookMath (Convert-ToWinFormsText $Practice)
  $lines = @(
    "# 批閱註記｜座號 $StudentId"
    ''
    '- 座號：' + $StudentId
    '- 來源檔：' + $SourceFile
    '- 總評：' + $Overall
    '- 程度：' + $Level
    '- 批改時間：' + (Get-Date -Format 'yyyy-MM-dd HH:mm')
    '- 原則：接受其他合理等價解法；存疑項請人工終核'
    '- 算式格式：國中課本直式（全形＋－＝、分數 a／b、……、①；禁止 LaTeX）'
    ''
    '## 題號註記'
    $(if ($ItemsText) { $ItemsText } else { '（尚未填題號；格式例：1 ✓｜2 ✗ 計算錯｜只寫試卷上有的題）' })
    ''
    '## 對錯摘要'
    $(if ($Summary) { $Summary } else { '（初核摘要）' })
    ''
    '## 個別診斷結果'
    $(if ($Diagnosis) { $Diagnosis } else { '（弱點類型：計算／觀念／審題／先備不足／粗心…；是否跟得上進度）' })
    ''
    '## 個別建議'
    $(if ($Advice) { $Advice } else { '（給學生／家長的短建議）' })
    ''
    '## 依程度自學／補救練習'
    $Practice
    ''
  )
  $utf8Bom = New-Object System.Text.UTF8Encoding $true
  [IO.File]::WriteAllText($path, ($lines -join "`r`n"), $utf8Bom)
  return $path
}

function Export-ClassCsv([string]$root) {
  $outDir = Join-Path $root '輸出'
  $csv = Join-Path $outDir '全班總表.csv'
  $rows = @()
  $rows += '座號,來源檔,總評,程度,註記檔,批改時間'
  Get-ChildItem -LiteralPath $outDir -Filter '*-註記.md' -File -ErrorAction SilentlyContinue |
    Sort-Object Name |
    ForEach-Object {
      $n = Load-Note $_.FullName
      $id = Get-StudentId $_.Name.Replace('-註記', '')
      if (-not $n.studentId) { $n.studentId = $id }
      $rows += ('{0},{1},{2},{3},{4},{5}' -f $n.studentId, ($n.sourceFile -replace ',', '，'), ($n.overall -replace ',', '，'), ($n.level -replace ',', '，'), $_.Name, (Get-Date -Format 'yyyy-MM-dd HH:mm'))
    }
  $utf8Bom = New-Object System.Text.UTF8Encoding $true
  [IO.File]::WriteAllText($csv, ($rows -join "`r`n"), $utf8Bom)
  return $csv
}

function Get-TeacherDeskWorkDir {
  Join-Path ([Environment]::GetFolderPath('Desktop')) '習作台資料'
}

function Map-LevelForDesk([string]$level) {
  if ($level -eq '待判定') { return '需補先備' }
  if ([string]::IsNullOrWhiteSpace($level)) { return '未標' }
  return $level
}

function Export-LevelsToTeacherDesk([string]$root) {
  $deskDir = Get-TeacherDeskWorkDir
  New-Item -ItemType Directory -Force -Path $deskDir | Out-Null
  $path = Join-Path $deskDir '班級狀態.json'
  $legacy = Join-Path $deskDir 'class-state.json'
  $st = $null
  if (Test-Path -LiteralPath $path) {
    try {
      $obj = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
      $st = @{
        classLabel    = $(if ($obj.classLabel) { [string]$obj.classLabel } else { '本班數學' })
        seatCount     = $(if ($obj.seatCount) { [int]$obj.seatCount } else { 35 })
        deadline      = $(if ($obj.deadline) { [string]$obj.deadline } else { '今晚 21:00' })
        sendChannel   = $(if ($obj.sendChannel) { [string]$obj.sendChannel } else { 'line_group' })
        returnChannel = $(if ($obj.returnChannel) { [string]$obj.returnChannel } else { 'line_dm' })
        seats         = @{}
      }
      if ($obj.seats) {
        foreach ($p in $obj.seats.PSObject.Properties) {
          $v = $p.Value
          $st.seats[$p.Name] = @{
            level = $(if ($v.level) { [string]$v.level } else { '未標' })
            send  = $(if ($v.send) { [string]$v.send } else { '未發' })
            note  = $(if ($v.note) { [string]$v.note } else { '' })
          }
        }
      }
    } catch { $st = $null }
  }
  if ($null -eq $st) {
    $st = @{
      classLabel = '本班數學'; seatCount = 35; deadline = '今晚 21:00'
      sendChannel = 'line_group'; returnChannel = 'line_dm'; seats = @{}
    }
    $st.seats['00'] = @{ level = '未標'; send = '未發'; note = '試發' }
    for ($i = 1; $i -le 35; $i++) {
      $id = '{0:D2}' -f $i
      $st.seats[$id] = @{ level = '未標'; send = '未發'; note = '' }
    }
  }
  $outDir = Join-Path $root '輸出'
  $n = 0
  Get-ChildItem -LiteralPath $outDir -Filter '*-註記.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
    $note = Load-Note $_.FullName
    $id = if ($note.studentId) { Get-StudentId $note.studentId } else { Get-StudentId $_.Name.Replace('-註記', '') }
    if (-not $id) { return }
    $lv = Map-LevelForDesk ([string]$note.level)
    if ($lv -eq '未標') { return }
    if (-not $st.seats.ContainsKey($id)) {
      $st.seats[$id] = @{ level = '未標'; send = '未發'; note = $(if ($id -eq '00') { '試發' } else { '' }) }
    }
    $st.seats[$id].level = $lv
    if (-not $st.seats[$id].send) { $st.seats[$id].send = '未發' }
    $n++
  }
  $orderedSeats = [ordered]@{}
  foreach ($k in ($st.seats.Keys | Sort-Object)) { $orderedSeats[$k] = $st.seats[$k] }
  $payload = [ordered]@{
    _schema       = 'teacher-desk-v1'
    exportedAt    = (Get-Date).ToString('o')
    classLabel    = $st.classLabel
    seatCount     = $st.seatCount
    deadline      = $st.deadline
    sendChannel   = $st.sendChannel
    returnChannel = $st.returnChannel
    seats         = $orderedSeats
  }
  $utf8Bom = New-Object System.Text.UTF8Encoding $true
  $json = $payload | ConvertTo-Json -Depth 6
  [IO.File]::WriteAllText($path, $json, $utf8Bom)
  Copy-Item -LiteralPath $path -Destination $legacy -Force -ErrorAction SilentlyContinue
  $exportDir = Join-Path $deskDir '匯出給手機'
  New-Item -ItemType Directory -Force -Path $exportDir | Out-Null
  Copy-Item -LiteralPath $path -Destination (Join-Path $exportDir '班級狀態.json') -Force
  return @{ Path = $path; Count = $n }
}

function Export-GraderProgressJson([string]$root) {
  $outDir = Join-Path $root '輸出'
  $histDir = Join-Path $root '練習歷程'
  $digDir = Join-Path $root '數位練習'
  New-Item -ItemType Directory -Force -Path $outDir, $histDir, $digDir | Out-Null
  $seats = [ordered]@{}
  $seats['00'] = @{ status = '未批'; level = '未標'; note = '試發'; history = @{ attempts = @() } }
  for ($i = 1; $i -le 35; $i++) {
    $id = '{0:D2}' -f $i
    $seats[$id] = @{ status = '未批'; level = '未標'; note = ''; history = @{ attempts = @() } }
  }
  Get-ChildItem -LiteralPath $outDir -Filter '*-註記.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
    $note = Load-Note $_.FullName
    $id = if ($note.studentId) { Get-StudentId $note.studentId } else { Get-StudentId $_.Name.Replace('-註記', '') }
    if (-not $id) { return }
    if (-not $seats.Contains($id)) {
      $seats[$id] = @{ status = '未批'; level = '未標'; note = ''; history = @{ attempts = @() } }
    }
    $lv = [string]$note.level
    if ($lv -eq '待判定') { $lv = '需補先備' }
    $seats[$id].level = $(if ($lv) { $lv } else { '未標' })
    $seats[$id].status = '已批'
    $ov = [string]$note.overall
    if ($ov.Length -gt 40) { $ov = $ov.Substring(0, 40) }
    $seats[$id].note = $ov
    if ($note.summary) { $seats[$id].lastReply = [string]$note.summary }
    if ($note.practice) { $seats[$id].practice = [string]$note.practice }
  }
  # 0803：併入練習歷程 attempts
  Get-ChildItem -LiteralPath $histDir -Filter '*-歷程.json' -File -ErrorAction SilentlyContinue | ForEach-Object {
    $id = Get-StudentId ($_.BaseName -replace '-歷程$', '')
    if (-not $id) { return }
    if (-not $seats.Contains($id)) {
      $seats[$id] = @{ status = '未批'; level = '未標'; note = ''; history = @{ attempts = @() } }
    }
    try {
      $h = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
      $attempts = @()
      foreach ($a in @($h.attempts)) {
        $attempts += [ordered]@{
          round         = $(if ($a.round) { [int]$a.round } else { 1 })
          score         = $(if ($null -ne $a.score) { [double]$a.score } else { 0 })
          maxScore      = $(if ($a.maxScore) { [double]$a.maxScore } else { 100 })
          targetScore   = $(if ($a.targetScore) { [double]$a.targetScore } else { 80 })
          goal          = $(if ($a.goal) { [string]$a.goal } else { '' })
          problemPoints = $(if ($a.problemPoints) { [string]$a.problemPoints } else { '' })
          feedback      = $(if ($a.feedback) { [string]$a.feedback } else { '' })
          nextPractice  = $(if ($a.nextPractice) { [string]$a.nextPractice } else { '' })
          goalMet       = [bool]$a.goalMet
          sourceFile    = $(if ($a.sourceFile) { [string]$a.sourceFile } else { '' })
          at            = $(if ($a.at) { $a.at } else { $null })
        }
      }
      $seats[$id].history = @{ attempts = $attempts }
      if ($attempts.Count -gt 0) {
        $last = $attempts[-1]
        if ($last.nextPractice) { $seats[$id].latestPractice = [string]$last.nextPractice }
        $seats[$id].note = ('R{0} {1}/{2}' -f $last.round, $last.score, $last.maxScore)
      }
    } catch {}
  }
  # 若尚無 latestPractice，嘗試數位練習 HTML 內文（精簡）
  Get-ChildItem -LiteralPath $digDir -Filter '*-練習題.html' -File -ErrorAction SilentlyContinue | ForEach-Object {
    $id = Get-StudentId ($_.BaseName -replace '-練習題$', '')
    if (-not $id -or -not $seats.Contains($id)) { return }
    if ($seats[$id].latestPractice) { return }
    try {
      $raw = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
      if ($raw -match '(?s)<pre>(.*?)</pre>') {
        $txt = [System.Net.WebUtility]::HtmlDecode($Matches[1]).Trim()
        if ($txt.Length -gt 8000) { $txt = $txt.Substring(0, 8000) }
        $seats[$id].latestPractice = $txt
      }
    } catch {}
  }
  $payload = [ordered]@{
    _schema    = 'math-grader-v1'
    exportedAt = (Get-Date).ToString('o')
    features   = @('0803', 'history', 'practice-loop', 'level')
    classLabel = '本班數學'
    seatCount  = 35
    seats      = $seats
  }
  $path = Join-Path $outDir '習作批改進度.json'
  $utf8Bom = New-Object System.Text.UTF8Encoding $true
  [IO.File]::WriteAllText($path, ($payload | ConvertTo-Json -Depth 8), $utf8Bom)
  return $path
}

function Merge-HistoryAttempts($existing, $incoming) {
  $map = @{}
  foreach ($a in @($existing)) {
    if (-not $a) { continue }
    $r = 0
    try { $r = [int]$a.round } catch { $r = 0 }
    if ($r -lt 1) { continue }
    $map[$r] = $a
  }
  foreach ($a in @($incoming)) {
    if (-not $a) { continue }
    $r = 0
    try { $r = [int]$a.round } catch { $r = 0 }
    if ($r -lt 1) { continue }
    if (-not $map.ContainsKey($r)) { $map[$r] = $a; continue }
    $oldAt = 0L; $newAt = 0L
    try { if ($map[$r].at) { $oldAt = [int64]$map[$r].at } } catch {}
    try { if ($a.at) { $newAt = [int64]$a.at } } catch {}
    if ($newAt -ge $oldAt) { $map[$r] = $a }
  }
  return @($map.Keys | Sort-Object | ForEach-Object { $map[$_] })
}

function Write-PracticeHtmlFile([string]$root, [string]$id, [string]$body, [string]$level) {
  if ([string]::IsNullOrWhiteSpace($body)) { return $null }
  $body = Convert-ToTextbookMath $body
  $digDir = Join-Path $root '數位練習'
  New-Item -ItemType Directory -Force -Path $digDir | Out-Null
  $safe = ($body -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;')
  $html = @"
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>座號 $id 練習</title>
<style>body{font-family:sans-serif;line-height:1.6;padding:1rem;max-width:40rem;margin:auto;white-space:pre-wrap}</style>
</head>
<body>
<h1>座號 $id｜$level</h1>
<pre>$safe</pre>
</body>
</html>
"@
  $path = Join-Path $digDir ($id + '-練習題.html')
  $utf8Bom = New-Object System.Text.UTF8Encoding $true
  [IO.File]::WriteAllText($path, $html, $utf8Bom)
  return $path
}

function Import-GraderProgressJson([string]$root, [string]$jsonPath) {
  $obj = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($obj._schema -eq 'teacher-desk-v1') { throw '這是班級狀態檔，請改匯入班級狀態或 0803 同步包' }
  if ($obj._schema -eq 'sync-pack-v1' -and $obj.grader) { $obj = $obj.grader }
  if (-not $obj.seats) { throw '不是習作批改進度檔' }
  $histDir = Join-Path $root '練習歷程'
  New-Item -ItemType Directory -Force -Path $histDir | Out-Null
  $nLevel = 0; $nHist = 0; $nPrac = 0
  foreach ($p in $obj.seats.PSObject.Properties) {
    $id = [string]$p.Name
    $src = $p.Value
    if (-not $src) { continue }
    $lv = [string]$src.level
    if ($lv -eq '待判定') { $lv = '需補先備' }
    if ($lv -and $lv -ne '未標') { $nLevel++ }

    $incoming = @()
    if ($src.history -and $src.history.attempts) { $incoming = @($src.history.attempts) }
    $histPath = Join-Path $histDir ($id + '-歷程.json')
    $existing = @()
    if (Test-Path -LiteralPath $histPath) {
      try {
        $old = Get-Content -LiteralPath $histPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($old.attempts) { $existing = @($old.attempts) }
      } catch {}
    }
    $merged = Merge-HistoryAttempts $existing $incoming
    if ($merged.Count -gt 0) {
      $payload = [ordered]@{
        studentId = $id
        attempts  = @($merged | ForEach-Object {
          [ordered]@{
            round         = $(if ($_.round) { [int]$_.round } else { 1 })
            score         = $(if ($null -ne $_.score) { [double]$_.score } else { 0 })
            maxScore      = $(if ($_.maxScore) { [double]$_.maxScore } else { 100 })
            targetScore   = $(if ($_.targetScore) { [double]$_.targetScore } else { 80 })
            goal          = $(if ($_.goal) { [string]$_.goal } else { '' })
            problemPoints = $(if ($_.problemPoints) { [string]$_.problemPoints } else { '' })
            feedback      = $(if ($_.feedback) { [string]$_.feedback } else { '' })
            nextPractice  = $(if ($_.nextPractice) { [string]$_.nextPractice } else { '' })
            goalMet       = [bool]$_.goalMet
            sourceFile    = $(if ($_.sourceFile) { [string]$_.sourceFile } else { '' })
            at            = $(if ($_.at) { $_.at } else { $null })
          }
        })
      }
      $utf8Bom = New-Object System.Text.UTF8Encoding $true
      [IO.File]::WriteAllText($histPath, ($payload | ConvertTo-Json -Depth 8), $utf8Bom)
      $nHist++
      $last = $merged[-1]
      $body = ''
      if ($src.latestPractice) { $body = [string]$src.latestPractice }
      elseif ($last.nextPractice) { $body = [string]$last.nextPractice }
      elseif ($src.practice) { $body = [string]$src.practice }
      if ($body) {
        [void](Write-PracticeHtmlFile $root $id $body $(if ($lv) { $lv } else { '未標' }))
        $nPrac++
      }
    } elseif ($src.latestPractice -or $src.practice) {
      $body = if ($src.latestPractice) { [string]$src.latestPractice } else { [string]$src.practice }
      [void](Write-PracticeHtmlFile $root $id $body $(if ($lv) { $lv } else { '未標' }))
      $nPrac++
    }
  }
  return @{ Levels = $nLevel; Histories = $nHist; Practices = $nPrac }
}

function Export-SyncPack0803([string]$root) {
  $graderPath = Export-GraderProgressJson $root
  $grader = Get-Content -LiteralPath $graderPath -Raw -Encoding UTF8 | ConvertFrom-Json
  # 同步程度到習作台後一併打包
  $deskInfo = Export-LevelsToTeacherDesk $root
  $desk = Get-Content -LiteralPath $deskInfo.Path -Raw -Encoding UTF8 | ConvertFrom-Json
  $pack = [ordered]@{
    _schema    = 'sync-pack-v1'
    exportedAt = (Get-Date).ToString('o')
    features   = @('0803', 'history', 'practice-loop', 'level', 'send', 'digital-practice')
    grader     = $grader
    desk       = $desk
  }
  $outDir = Join-Path $root '輸出'
  $path = Join-Path $outDir '0803同步包.json'
  $utf8Bom = New-Object System.Text.UTF8Encoding $true
  [IO.File]::WriteAllText($path, ($pack | ConvertTo-Json -Depth 10), $utf8Bom)
  $exportDir = Join-Path (Get-TeacherDeskWorkDir) '匯出給手機'
  New-Item -ItemType Directory -Force -Path $exportDir | Out-Null
  Copy-Item -LiteralPath $path -Destination (Join-Path $exportDir '0803同步包.json') -Force
  return $path
}

function Import-SyncPack0803([string]$root, [string]$jsonPath) {
  $obj = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($obj._schema -ne 'sync-pack-v1') {
    # 相容：純進度檔也當部分匯入
    if ($obj.seats) {
      $r = Import-GraderProgressJson $root $jsonPath
      return @{ Grader = $r; Desk = $null; Path = $jsonPath }
    }
    throw '請選擇 0803同步包.json（或習作批改進度.json）'
  }
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ('grader-progress-' + [guid]::NewGuid().ToString('n') + '.json')
  try {
    $utf8Bom = New-Object System.Text.UTF8Encoding $true
    [IO.File]::WriteAllText($tmp, ($obj.grader | ConvertTo-Json -Depth 10), $utf8Bom)
    $r = Import-GraderProgressJson $root $tmp
  } finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
  }
  $deskPath = $null
  if ($obj.desk) {
    $deskDir = Get-TeacherDeskWorkDir
    New-Item -ItemType Directory -Force -Path $deskDir | Out-Null
    $deskPath = Join-Path $deskDir '班級狀態.json'
    [IO.File]::WriteAllText($deskPath, ($obj.desk | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding $true))
    Copy-Item -LiteralPath $deskPath -Destination (Join-Path $deskDir 'class-state.json') -Force -ErrorAction SilentlyContinue
  }
  # 再把進度程度寫進習作台（覆蓋 desk 中程度欄）
  [void](Export-LevelsToTeacherDesk $root)
  return @{ Grader = $r; Desk = $deskPath; Path = $jsonPath }
}

function Get-AnswerFiles([string]$root) {
  $dir = Join-Path $root '標準答案'
  if (-not (Test-Path -LiteralPath $dir)) { return @() }
  Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -match '\.(pdf|png|jpe?g|tif{1,2}|bmp|txt|md)$' } |
    Sort-Object Name
}

function Get-ExpectedQuestionCount([string]$root) {
  # 從配分表／文字答案推估實際題數；推不出則 0（不硬加題）
  $dir = Join-Path $root '標準答案'
  if (-not (Test-Path -LiteralPath $dir)) { return 0 }
  $maxQ = 0
  $files = @(Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -match '\.(txt|md)$' })
  foreach ($f in $files) {
    try {
      $raw = Get-Content -LiteralPath $f.FullName -Encoding UTF8 -Raw
    } catch { continue }
    if ([string]::IsNullOrWhiteSpace($raw)) { continue }
    foreach ($m in [regex]::Matches($raw, '(?m)(?:^|\n)\s*(?:第\s*)?(\d{1,2})\s*[題\.、:：\)）\.]')) {
      $n = 0
      [void][int]::TryParse($m.Groups[1].Value, [ref]$n)
      if ($n -gt $maxQ -and $n -le 40) { $maxQ = $n }
    }
    foreach ($m in [regex]::Matches($raw, '(?m)^\s*(\d{1,2})\s*[\)）]\s*\S')) {
      $n = 0
      [void][int]::TryParse($m.Groups[1].Value, [ref]$n)
      if ($n -gt $maxQ -and $n -le 40) { $maxQ = $n }
    }
  }
  return $maxQ
}

function Normalize-ItemMarksText {
  param(
    [string]$MarksText,
    [int]$MaxQuestion = 0
  )
  if ([string]::IsNullOrWhiteSpace($MarksText)) { return '' }
  $byNum = @{}
  foreach ($ln in ($MarksText -split "`r?`n")) {
    $t = $ln.Trim()
    if ($t -match '^(\d{1,2})\s*([✓✗√×xX?？].*)$') {
      $n = [int]$Matches[1]
      if ($n -lt 1 -or $n -gt 40) { continue }
      if ($MaxQuestion -gt 0 -and $n -gt $MaxQuestion) { continue }
      $mark = $Matches[2].Trim()
      # 統一 x/X → ✗
      if ($mark -match '^[xX×]') { $mark = '✗' + $mark.Substring(1) }
      if ($mark -match '^√') { $mark = '✓' + $mark.Substring(1) }
      $byNum[$n] = ("{0} {1}" -f $n, $mark.Trim())
    }
  }
  if ($byNum.Count -eq 0) { return '' }
  $nums = @($byNum.Keys | Sort-Object)
  # 若未指定上限，只用實際出現的題號（不自動補到 3）
  $lines = New-Object System.Collections.ArrayList
  foreach ($n in $nums) { [void]$lines.Add([string]$byNum[$n]) }
  return ($lines -join "`r`n")
}

function Get-QuestionNumsFromMarks([string]$marksText) {
  $nums = New-Object System.Collections.ArrayList
  foreach ($ln in (($marksText -split "`r?`n"))) {
    if ($ln -match '^\s*(\d{1,2})\s*[✓✗√×xX?？]') {
      $n = [int]$Matches[1]
      if ($nums -notcontains $n) { [void]$nums.Add($n) }
    }
  }
  return @($nums | Sort-Object)
}

function Get-SettingsPath([string]$root) {
  Join-Path $root 'settings.json'
}

function Get-GeminiKeyPath([string]$root) {
  Join-Path $root 'gemini-api-key.txt'
}

function Normalize-GeminiApiKey([string]$key) {
  if ([string]::IsNullOrWhiteSpace($key)) { return '' }
  $k = $key.Trim()
  $k = $k -replace '[\u200B-\u200D\uFEFF]', ''
  $k = ($k -split "`r|`n")[0].Trim()
  if ($k -match '^(?i)Bearer\s+(.+)$') { $k = $Matches[1].Trim() }
  if ($k -match '^(?i)(?:GEMINI[_ ]?API[_ ]?KEY|GOOGLE[_ ]?API[_ ]?KEY|API[_ ]?KEY)\s*[:=]\s*(.+)$') {
    $k = $Matches[1].Trim()
  }
  $k = $k.Trim('"', "'", ' ', "`t", '`', '「', '」')
  return $k
}

function Test-GeminiApiKeyLooksValid([string]$key) {
  $k = Normalize-GeminiApiKey $key
  if ([string]::IsNullOrWhiteSpace($k) -or $k.Length -lt 20) { return $false }
  # 舊版 Standard：AIza…；2026 AI Studio 新 Auth 金鑰：AQ.…
  if ($k -match '^(?i)AIza[0-9A-Za-z_\-]{10,}') { return $true }
  if ($k -match '^(?i)AQ\.[0-9A-Za-z_\.\-]{10,}') { return $true }
  return $false
}

function Get-GeminiApiKeyHint([string]$key) {
  $k = Normalize-GeminiApiKey $key
  if ([string]::IsNullOrWhiteSpace($k)) { return '（空白）' }
  $prefix = $k.Substring(0, [Math]::Min(4, $k.Length))
  return ("開頭「{0}…」長度 {1}" -f $prefix, $k.Length)
}

function Invoke-GeminiRest {
  param(
    [ValidateSet('Get','Post')]
    [string]$Method,
    [string]$ApiKey,
    [string]$PathAndQuery,
    [byte[]]$BodyBytes = $null,
    [int]$TimeoutSec = 60
  )
  $k = Normalize-GeminiApiKey $ApiKey
  if ([string]::IsNullOrWhiteSpace($k)) { throw '金鑰空白' }
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $base = 'https://generativelanguage.googleapis.com/v1beta/'
  # 兩種認證都試：標頭（官方建議）→ 查詢字串（舊相容）
  $modes = @(
    @{ Name = 'header'; Uri = ($base + $PathAndQuery); UseHeader = $true },
    @{
      Name = 'query'
      Uri = $(
        if ($PathAndQuery -match '\?') { $base + $PathAndQuery + '&key=' + [uri]::EscapeDataString($k) }
        else { $base + $PathAndQuery + '?key=' + [uri]::EscapeDataString($k) }
      )
      UseHeader = $false
    }
  )
  $lastDetail = ''
  foreach ($mode in $modes) {
    $req = $null
    $resp = $null
    $reader = $null
    try {
      $req = [System.Net.HttpWebRequest]::Create($mode.Uri)
      $req.Method = $Method.ToUpperInvariant()
      $req.Timeout = [Math]::Max(5000, $TimeoutSec * 1000)
      $req.ReadWriteTimeout = [Math]::Max(5000, $TimeoutSec * 1000)
      $req.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
      $req.Accept = 'application/json'
      $req.UserAgent = "MathHomeworkGrader/$($script:AppBuild)"
      if ($mode.UseHeader) {
        $req.Headers.Add('x-goog-api-key', $k)
      }
      if ($Method -eq 'Post') {
        if ($null -eq $BodyBytes) { $BodyBytes = [byte[]]@() }
        $req.ContentType = 'application/json; charset=utf-8'
        $req.ContentLength = $BodyBytes.Length
        $rs = $req.GetRequestStream()
        try { $rs.Write($BodyBytes, 0, $BodyBytes.Length) } finally { $rs.Close() }
      }
      $resp = $req.GetResponse()
      $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
      $text = $reader.ReadToEnd()
      if ([string]::IsNullOrWhiteSpace($text)) { return $null }
      return ($text | ConvertFrom-Json)
    } catch {
      $detail = [string]$_.Exception.Message
      try {
        $ex = $_.Exception
        $webEx = $ex
        if ($ex -isnot [System.Net.WebException] -and $ex.InnerException) { $webEx = $ex.InnerException }
        if ($webEx -is [System.Net.WebException] -and $webEx.Response) {
          $errResp = $webEx.Response
          $errReader = New-Object System.IO.StreamReader($errResp.GetResponseStream())
          $errBody = $errReader.ReadToEnd()
          $errReader.Close()
          try { $errResp.Close() } catch {}
          if (-not [string]::IsNullOrWhiteSpace($errBody)) {
            $detail += "`n" + $errBody.Substring(0, [Math]::Min(800, $errBody.Length))
          }
        }
      } catch {}
      $lastDetail = ("[$($mode.Name)] " + $detail)
      continue
    } finally {
      try { if ($reader) { $reader.Close() } } catch {}
      try { if ($resp) { $resp.Close() } } catch {}
    }
  }
  throw $lastDetail
}

function Get-GeminiApiKey([string]$root) {
  $p = Get-GeminiKeyPath $root
  if (-not (Test-Path -LiteralPath $p)) { return '' }
  try {
    $k = Normalize-GeminiApiKey ((Get-Content -LiteralPath $p -Encoding UTF8 -Raw))
    if ($k -match '^\s*#') { return '' }
    return $k
  } catch { return '' }
}

function Save-GeminiApiKey([string]$root, [string]$key) {
  $p = Get-GeminiKeyPath $root
  $k = Normalize-GeminiApiKey $key
  $utf8 = New-Object System.Text.UTF8Encoding $true
  [IO.File]::WriteAllText($p, ($k + "`r`n"), $utf8)
}

function Get-RestErrorDetail {
  param($ErrorRecord)
  $msg = ''
  try { $msg = [string]$ErrorRecord.Exception.Message } catch {}
  try {
    if ($ErrorRecord.Exception.InnerException) {
      $msg += ' | ' + [string]$ErrorRecord.Exception.InnerException.Message
    }
  } catch {}
  try {
    $resp = $ErrorRecord.Exception.Response
    if ($null -ne $resp) {
      $stream = $resp.GetResponseStream()
      if ($null -ne $stream) {
        $reader = New-Object System.IO.StreamReader($stream)
        $body = $reader.ReadToEnd()
        $reader.Close()
        if (-not [string]::IsNullOrWhiteSpace($body)) {
          $msg += "`n" + $body.Substring(0, [Math]::Min(800, $body.Length))
        }
      }
    }
  } catch {}
  return $msg
}

function Get-GeminiHardcodedFallbacks {
  # 優先序：現行 3.x → 別名 → 仍可用的 2.5（2.0／1.5 已下線勿列）
  @(
    'gemini-3.7-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3-flash-preview',
    'gemini-flash-latest',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.5-pro'
  )
}

function Test-GeminiModelNameUsable([string]$name) {
  if ([string]::IsNullOrWhiteSpace($name)) { return $false }
  $n = $name.Trim() -replace '^models/', ''
  if ($n -match 'gemini-2\.0|gemini-1\.5|gemini-1\.0|gemini-pro$|gemini-pro-vision') { return $false }
  if ($n -match 'image|tts|live|embedding|aqa|computer-use|robotics|native-audio') { return $false }
  if ($n -notmatch 'gemini') { return $false }
  return $true
}

function Get-GeminiListedModels([string]$ApiKey) {
  $k = Normalize-GeminiApiKey $ApiKey
  $names = New-Object System.Collections.ArrayList
  $pageToken = ''
  $page = 0
  while ($page -lt 6) {
    $page++
    $pq = 'models?pageSize=100'
    if ($pageToken) { $pq += '&pageToken=' + [uri]::EscapeDataString($pageToken) }
    $resp = Invoke-GeminiRest -Method Get -ApiKey $k -PathAndQuery $pq -TimeoutSec 45
    foreach ($m in @($resp.models)) {
      $n = ([string]$m.name) -replace '^models/', ''
      if (-not (Test-GeminiModelNameUsable $n)) { continue }
      $methods = @()
      try { $methods = @($m.supportedGenerationMethods) } catch {}
      if ($methods.Count -gt 0 -and ($methods -notcontains 'generateContent')) { continue }
      if ($names -notcontains $n) { [void]$names.Add($n) }
    }
    $pageToken = ''
    try { $pageToken = [string]$resp.nextPageToken } catch {}
    if ([string]::IsNullOrWhiteSpace($pageToken)) { break }
  }
  return @($names.ToArray())
}

function Get-GeminiPreferredModelOrder {
  param(
    [string]$ApiKey,
    [string]$Preferred = ''
  )
  $hard = @(Get-GeminiHardcodedFallbacks)
  $listed = @()
  if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
    try { $listed = @(Get-GeminiListedModels $ApiKey) } catch { $listed = @() }
  }
  $ordered = New-Object System.Collections.ArrayList
  $add = {
    param([string]$n)
    if ([string]::IsNullOrWhiteSpace($n)) { return }
    if (-not (Test-GeminiModelNameUsable $n)) { return }
    if ($ordered -contains $n) { return }
    [void]$ordered.Add($n)
  }
  & $add $Preferred
  foreach ($h in $hard) {
    if ($listed.Count -eq 0 -or ($listed -contains $h)) { & $add $h }
  }
  # ListModels 有、但硬編清單沒有的：先 flash／lite，其餘殿後
  $flashFirst = @($listed | Where-Object { $_ -match 'flash' -and $_ -notmatch 'lite' })
  $liteNext = @($listed | Where-Object { $_ -match 'lite' })
  $rest = @($listed | Where-Object { $_ -notin $flashFirst -and $_ -notin $liteNext })
  foreach ($n in ($flashFirst + $liteNext + $rest)) { & $add $n }
  if ($ordered.Count -eq 0) {
    foreach ($h in $hard) { & $add $h }
  }
  return @($ordered.ToArray())
}

function Test-GeminiApiKey([string]$ApiKey) {
  $k = Normalize-GeminiApiKey $ApiKey
  if ([string]::IsNullOrWhiteSpace($k)) { throw '金鑰空白' }
  if ($k.Length -lt 20) { throw '金鑰太短，可能貼不完整。請重新從 aistudio.google.com/apikey 複製整串。' }
  if (-not (Test-GeminiApiKeyLooksValid $k)) {
    throw ("這不像 Google AI Studio 的 API 金鑰。`n目前可接受：以 AIza 開頭（舊）或以 AQ. 開頭（2026 新 Auth 金鑰）。`n你貼的是：" + (Get-GeminiApiKeyHint $k) + "`n請勿貼 Gemini 網頁／訂閱相關文字；請到 aistudio.google.com/apikey 按 Create API key 複製整串。")
  }
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $names = @()
  try {
    $names = @(Get-GeminiListedModels $k)
  } catch {
    $msg = Get-RestErrorDetail $_
    if ($msg -match '401|403|PERMISSION|API[_ ]?key|UNAUTHENTICATED|INVALID.*key|金鑰') {
      throw ("金鑰無效或未開通。請到 aistudio.google.com/apikey 新建一把（建議在 AI Studio 產生、並限制 Generative Language API）。`n原始：$msg")
    }
    if ($msg -match '503|429|Unavailable|無法使用') {
      throw ("Google 暫時忙碌（503／429）。金鑰格式可接受，請等 1～2 分鐘再測。`n原始：$msg")
    }
    throw ("測試金鑰失敗：$msg")
  }
  if ($names.Count -eq 0) {
    throw '金鑰能連上，但列不出可用 generateContent 模型。請到 aistudio.google.com/apikey 新建金鑰，並確認帳號已開通 Gemini API。'
  }

  $preferred = ''
  $order = @(Get-GeminiPreferredModelOrder -ApiKey $k)
  $probePrompt = '回覆一個字：好'
  $ser = $null
  try {
    Add-Type -AssemblyName System.Web.Extensions -ErrorAction SilentlyContinue
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  } catch {}
  $probeJson = '{"contents":[{"role":"user","parts":[{"text":"回覆一個字：好"}]}],"generationConfig":{"temperature":0,"maxOutputTokens":8}}'
  if ($ser) {
    $probeJson = $ser.Serialize(@{
      contents = @(@{ role = 'user'; parts = @(@{ text = $probePrompt }) })
      generationConfig = @{ temperature = 0; maxOutputTokens = 8 }
    })
  }
  $probeBytes = [Text.Encoding]::UTF8.GetBytes($probeJson)
  $probeTried = New-Object System.Collections.ArrayList
  foreach ($m in ($order | Select-Object -First 8)) {
    [void]$probeTried.Add($m)
    try {
      $null = Invoke-GeminiRest -Method Post -ApiKey $k -PathAndQuery ("models/${m}:generateContent") -BodyBytes $probeBytes -TimeoutSec 60
      $preferred = $m
      break
    } catch {
      $em = Get-RestErrorDetail $_
      if ($em -match '401|403|PERMISSION|API[_ ]?key|UNAUTHENTICATED|INVALID.*key') {
        throw ("金鑰無效或權限不足（無法 generateContent）。請到 aistudio.google.com/apikey 新建（新鑰常以 AQ. 開頭），並限制 Generative Language API。`n原始：$em")
      }
      continue
    }
  }
  if ([string]::IsNullOrWhiteSpace($preferred)) {
    throw ("金鑰可列出模型，但實際呼叫 generateContent 全失敗（常為 404／金鑰限制）。`n已試：$([string]::Join(', ', $probeTried.ToArray()))`n請到 aistudio.google.com/apikey 新建金鑰後再測。`n帳號可列模型例：" + (($names | Select-Object -First 5) -join ', '))
  }

  return [pscustomobject]@{
    Ok = $true
    ModelCount = $names.Count
    Sample = ($names | Select-Object -First 5) -join ', '
    PreferredModel = $preferred
  }
}

function Get-FileMimeType([string]$path) {
  $ext = [IO.Path]::GetExtension($path).ToLowerInvariant()
  switch ($ext) {
    '.png' { return 'image/png' }
    '.jpg' { return 'image/jpeg' }
    '.jpeg' { return 'image/jpeg' }
    '.gif' { return 'image/gif' }
    '.webp' { return 'image/webp' }
    '.bmp' { return 'image/bmp' }
    '.tif' { return 'image/tiff' }
    '.tiff' { return 'image/tiff' }
    '.heic' { return 'image/heic' }
    '.heif' { return 'image/heif' }
    '.pdf' { return 'application/pdf' }
    '.txt' { return 'text/plain' }
    '.md' { return 'text/plain' }
    default { return 'application/octet-stream' }
  }
}

function New-GeminiInlinePart([string]$path) {
  $mime = Get-FileMimeType $path
  $bytes = [IO.File]::ReadAllBytes($path)
  if ($bytes.Length -gt 18MB) {
    throw "檔案太大（$([IO.Path]::GetFileName($path))），請先壓縮或改拍清晰照片（建議 < 15MB）"
  }
  if ($mime -eq 'text/plain') {
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    return @{ text = ("【檔案：$([IO.Path]::GetFileName($path))】`n" + $text) }
  }
  return @{
    inline_data = @{
      mime_type = $mime
      data = [Convert]::ToBase64String($bytes)
    }
  }
}

function Invoke-GeminiGenerateContent {
  param(
    [string]$ApiKey,
    [string]$Model,
    [string]$Prompt,
    [string[]]$FilePaths
  )
  $ApiKey = Normalize-GeminiApiKey $ApiKey
  if ([string]::IsNullOrWhiteSpace($ApiKey)) { throw '尚未設定 Gemini API 金鑰' }
  # 2.0／1.5 已下線；空白或舊名改由動態清單決定
  if ([string]::IsNullOrWhiteSpace($Model) -or $Model -match 'gemini-2\.0|gemini-1\.5|gemini-1\.0') {
    $Model = ''
  }

  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  $parts = New-Object System.Collections.ArrayList
  [void]$parts.Add(@{ text = $Prompt })
  foreach ($fp in $FilePaths) {
    if (-not (Test-Path -LiteralPath $fp)) { continue }
    [void]$parts.Add((New-GeminiInlinePart $fp))
  }

  $payload = @{
    contents = @(
      @{
        role = 'user'
        parts = @($parts.ToArray())
      }
    )
    generationConfig = @{
      temperature = 0.2
    }
  }

  Add-Type -AssemblyName System.Web.Extensions -ErrorAction SilentlyContinue
  $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  $ser.MaxJsonLength = [int]::MaxValue
  $json = $ser.Serialize($payload)
  $bytes = [Text.Encoding]::UTF8.GetBytes($json)

  # 先 ListModels，再依現行 3.x／2.5 優先序嘗試；跳過已下線／404
  $models = @(Get-GeminiPreferredModelOrder -ApiKey $ApiKey -Preferred $Model)
  $tried = New-Object System.Collections.ArrayList
  $lastDetail = ''
  $saw404 = $false
  foreach ($m in $models) {
    [void]$tried.Add($m)
    $attempt = 0
    $maxAttempt = 3
    while ($attempt -lt $maxAttempt) {
      $attempt++
      try {
        $resp = Invoke-GeminiRest -Method Post -ApiKey $ApiKey -PathAndQuery ("models/${m}:generateContent") -BodyBytes $bytes -TimeoutSec 180
        $text = ''
        try {
          foreach ($c in $resp.candidates) {
            foreach ($p in $c.content.parts) {
              if ($p.text) { $text += [string]$p.text }
            }
          }
        } catch {}
        if ([string]::IsNullOrWhiteSpace($text)) {
          throw ("Gemini 沒有回傳文字（model=$m）。原始：" + ($resp | ConvertTo-Json -Depth 6 -Compress))
        }
        return [pscustomobject]@{ Text = $text; Model = $m }
      } catch {
        $msg = Get-RestErrorDetail $_
        $lastDetail = $msg
        if ($msg -match '404|not found|NOT_FOUND|找不到|is not found|not supported|was not found') {
          $saw404 = $true
          break
        }
        if ($msg -match 'API[_ ]?key|PERMISSION|401|403|INVALID_ARGUMENT.*key|金鑰|UNAUTHENTICATED') {
          throw ("Gemini 金鑰無效或未開通。請按「Gemini金鑰」到 aistudio.google.com/apikey 重建（新鑰常以 AQ. 開頭；建議限制 Generative Language API）。`n原始：" + $msg)
        }
        # 503／429／忙碌：同模型重試，再換下一個模型
        if ($msg -match '503|429|Unavailable|無法使用|RESOURCE_EXHAUSTED|quota|rate|過載|暫時') {
          if ($attempt -lt $maxAttempt) {
            Start-Sleep -Seconds (2 * $attempt)
            continue
          }
          break
        }
        if ($msg -match 'INVALID_ARGUMENT|unsupported|FAILED_PRECONDITION|400') { break }
        throw
      }
    }
  }
  $hint = "已嘗試模型：$([string]::Join(', ', $tried.ToArray()))"
  if ($saw404) {
    $hint += "`n全部 404：模型名過舊或此金鑰無權呼叫。請按「Gemini金鑰」→「測試金鑰」（會實際試 generateContent），或到 aistudio.google.com/apikey 新建金鑰。"
    $hint += "`n勿再用 gemini-2.0-flash（已下線）。現行可用例：gemini-3.5-flash、gemini-2.5-flash、gemini-flash-latest。"
  } else {
    $hint += "`n若出現 503，多半是 Google 暫時忙碌，等 1～2 分鐘再按「Gemini自動批」。"
  }
  if ($lastDetail) { throw ($lastDetail + "`n`n" + $hint) }
  throw $hint
}

function Get-GeminiReplySection([string]$text, [int]$num) {
  if ([string]::IsNullOrWhiteSpace($text) -or $num -lt 0) { return '' }
  $circ = @('①','②','③','④','⑤','⑥','⑦','⑧','⑨','⑩')
  # 接受 5) / 5） / ⑤ / **5)** / ### 5)
  $heads = @(
    [string]$num + '\)',
    [string]$num + '）'
  )
  if ($num -ge 1 -and $num -le 10) { $heads += [regex]::Escape($circ[$num - 1]) }
  $head = '(?:' + ($heads -join '|') + ')'
  $nextParts = New-Object System.Collections.ArrayList
  for ($i = $num + 1; $i -le 10; $i++) {
    [void]$nextParts.Add([string]$i + '\)')
    [void]$nextParts.Add([string]$i + '）')
    if ($i -ge 1 -and $i -le 10) { [void]$nextParts.Add([regex]::Escape($circ[$i - 1])) }
  }
  $next = if ($nextParts.Count -gt 0) { '(?:' + ($nextParts -join '|') + ')' } else { '(?!)' }
  # 必須像章節標題：數字) 後面接標題字，避免誤切「2 ✗」
  $pat = '(?ms)(?:^|\n)[ \t#*\-　]{0,8}' + $head + '(?![✓✗√×xX?？\d])\s*(.*?)(?=(?:^|\n)[ \t#*\-　]{0,8}' + $next + '(?![✓✗√×xX?？\d])|\z)'
  if ($text -match $pat) {
    return (Strip-SectionTitlePrefix $Matches[1].Trim())
  }
  return ''
}

function Strip-SectionTitlePrefix([string]$body) {
  if ([string]::IsNullOrWhiteSpace($body)) { return '' }
  $b = $body.Trim()
  $b = [regex]::Replace($b, '^(?:題號註記|對錯摘要|個別診斷結果|診斷結果|診斷|程度分級|程度|個別建議|短建議|依程度自學練習|依程度自學|自學練習)\s*[：:\)）\-—–]*\s*', '')
  return $b.Trim()
}

function Get-GeminiKeywordBlock {
  param(
    [string]$Text,
    [string[]]$StartKeys,
    [string[]]$StopKeys
  )
  if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
  $startPat = '(?:' + (($StartKeys | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')'
  $stopPat = '(?:' + (($StopKeys | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')'
  $pat = '(?ms)(?:^|\n)\s*(?:#{1,6}\s*|\*{0,2}\s*|【\s*)?' + $startPat + '\s*(?:】)?\s*[：:\）\)]*\s*\*{0,2}\s*\n?(.*?)(?=(?:^|\n)\s*(?:#{1,6}\s*|\*{0,2}\s*|【\s*)?(?:' + $stopPat + ')|\z)'
  if ($Text -match $pat) {
    $b = Strip-SectionTitlePrefix $Matches[1].Trim()
    if ($b.Length -gt 0) { return $b }
  }
  return ''
}

function Get-ItemMarksFromText([string]$text) {
  $lines = New-Object System.Collections.ArrayList
  foreach ($ln in (($text -split "`r?`n"))) {
    $t = $ln.Trim()
    # 只要「題號＋對錯符號」；不要把「3) 個別診斷」或練習「3. …」當題號註記
    if ($t -match '^\d{1,2}\s*[✓✗√×xX?？]') { [void]$lines.Add($t) }
  }
  if ($lines.Count -gt 0) { return ($lines -join "`r`n") }
  return ''
}

function Strip-InventedQuestionMentions([string]$text, [int[]]$allowedNums) {
  if ([string]::IsNullOrWhiteSpace($text)) { return $text }
  if ($null -eq $allowedNums -or $allowedNums.Count -eq 0) { return $text }
  $allow = @{}
  foreach ($n in $allowedNums) { $allow[[int]$n] = $true }
  $kept = New-Object System.Collections.ArrayList
  foreach ($ln in ($text -split "`r?`n")) {
    $drop = $false
    foreach ($m in [regex]::Matches($ln, '第\s*(\d{1,2})\s*題')) {
      $n = [int]$m.Groups[1].Value
      if (-not $allow.ContainsKey($n)) { $drop = $true; break }
    }
    if (-not $drop -and $ln -match '^\s*(\d{1,2})\s*[✓✗√×xX?？]') {
      $n = [int]$Matches[1]
      if (-not $allow.ContainsKey($n)) { $drop = $true }
    }
    if (-not $drop) { [void]$kept.Add($ln) }
  }
  return (($kept -join "`r`n").Trim())
}

function Map-OverallFromGemini([string]$text) {
  if ($text -match '總評[：:\s]*(全對|大致正確|多對|部分錯誤|混雜|多錯|需補救|看不懂為主|存疑多)') {
    switch -Regex ($Matches[1]) {
      '全對|大致正確|多對' { return '大致正確' }
      '部分錯誤|混雜' { return '部分錯誤' }
      '多錯|需補救' { return '需補救' }
      '看不懂|存疑' { return '存疑多' }
    }
  }
  if ($text -match '完全正確|全對|100\s*分') { return '大致正確' }
  if ($text -match '(?m)^\d+\s*[✗×xX]') { return '部分錯誤' }
  if ($text -match '(?m)^\d+\s*[✓√]' -and $text -notmatch '(?m)^\d+\s*[✗×xX?？]') { return '大致正確' }
  return ''
}

function Apply-GeminiReplyToForm([string]$text) {
  # 欄位對照（禁止錯位）：
  # 題號註記 ← 1)／【題號註記】只取 ✓✗?
  # 對錯摘要 ← 2)／【對錯摘要】
  # 診斷結果 ← 3)／【個別診斷】（絕不可塞題號註記）
  # 程度     ← 4)／程度：
  # 個別建議 ← 5)／【個別建議】
  # 自學練習 ← 6)／【自學練習】
  $raw = Convert-ToWinFormsText $text
  $script:SuppressPracticeAutoFill = $true
  try {
    $maxQ = 0
    try { $maxQ = [int](Get-ExpectedQuestionCount $script:WorkDir) } catch { $maxQ = 0 }

    $sec1 = Get-GeminiReplySection $raw 1
    $sec2 = Get-GeminiReplySection $raw 2
    $sec3 = Get-GeminiReplySection $raw 3
    $sec4 = Get-GeminiReplySection $raw 4
    $sec5 = Get-GeminiReplySection $raw 5
    $sec6 = Get-GeminiReplySection $raw 6

    # 以欄位名稱再補一次（比純數字穩，避免 1)～6) 與題號打架）
    if (-not $sec1) {
      $sec1 = Get-GeminiKeywordBlock -Text $raw -StartKeys @('題號註記') -StopKeys @(
        '對錯摘要', '個別診斷', '診斷結果', '程度分級', '個別建議', '依程度自學', '自學練習', '自學指導'
      )
    }
    if (-not $sec2) {
      $sec2 = Get-GeminiKeywordBlock -Text $raw -StartKeys @('對錯摘要') -StopKeys @(
        '題號註記', '個別診斷', '診斷結果', '程度分級', '個別建議', '依程度自學', '自學練習'
      )
    }
    if (-not $sec3) {
      $sec3 = Get-GeminiKeywordBlock -Text $raw -StartKeys @('個別診斷結果', '診斷結果', '個別診斷') -StopKeys @(
        '題號註記', '對錯摘要', '程度分級', '個別建議', '依程度自學', '自學練習', '自學指導'
      )
    }
    if (-not $sec5) {
      $sec5 = Get-GeminiKeywordBlock -Text $raw -StartKeys @('個別建議', '給學生的建議', '短建議') -StopKeys @(
        '依程度自學', '自學練習', '自學指導', '練習題', '解答', '題號註記', '對錯摘要', '個別診斷', '程度分級'
      )
    }
    if (-not $sec6) {
      $sec6 = Get-GeminiKeywordBlock -Text $raw -StartKeys @('依程度自學練習', '依程度自學', '自學練習') -StopKeys @(
        '個別建議', '題號註記', '對錯摘要', '個別診斷', '程度分級', '總評'
      )
    }

    # --- 題號註記：只留實際有批到的題，不預設第 3 題 ---
    $marks = Get-ItemMarksFromText $sec1
    if (-not $marks) { $marks = Get-ItemMarksFromText $sec2 }
    # 禁止用全文掃描（會把別段內容捲進來造成錯位）
    $marks = Normalize-ItemMarksText -MarksText $marks -MaxQuestion $maxQ
    $allowed = @(Get-QuestionNumsFromMarks $marks)
    if ($marks) {
      $txtItems.Text = Convert-ToTextbookMath $marks
    } else {
      $txtItems.Text = '（尚無題號註記｜請依試卷實際題數填，例如：1 ✓）'
    }

    # --- 對錯摘要 ---
    if ($sec2 -and $sec2 -notmatch '^\s*題號註記') {
      $sum = Strip-InventedQuestionMentions $sec2 $allowed
      $txtSummary.Text = Convert-ToTextbookMath $sum
    } else {
      if ($allowed.Count -gt 0) {
        $txtSummary.Text = ('已批題號：' + ($allowed -join '、') + '｜詳見診斷欄／輸出資料夾')
      } else {
        $txtSummary.Text = '（Gemini 自動批閱完成，詳見診斷欄／輸出資料夾）'
      }
    }

    # --- 診斷結果：絕不可回填 sec1 題號註記 ---
    $diag = ''
    if ($sec3) {
      $diagLines = New-Object System.Collections.ArrayList
      foreach ($ln in ($sec3 -split "`r?`n")) {
        if ($ln -notmatch '^\s*\d{1,2}\s*[✓✗√×xX?？]') { [void]$diagLines.Add($ln) }
      }
      $diag = Strip-InventedQuestionMentions (($diagLines -join "`r`n").Trim()) $allowed
      if ($diag -match '題號註記') { $diag = '' }
    }
    if ($diag) {
      $txtDiagnosis.Text = Convert-ToTextbookMath $diag
    } else {
      $txtDiagnosis.Text = '（尚無診斷文字｜請看對錯摘要與題號註記）'
    }

    # --- 程度 ---
    $lvBlob = ($sec4 + "`n" + $raw)
    if ($lvBlob -match '程度[：:\s]*(跟上|略落後|明顯落後|需補先備|待判定)') {
      $lv = $Matches[1]
      $idx = $cmbLevel.Items.IndexOf($lv)
      if ($idx -ge 0) { $cmbLevel.SelectedIndex = $idx }
    } elseif ($raw -match '完全正確|全對|100\s*分') {
      $idx2 = $cmbLevel.Items.IndexOf('跟上')
      if ($idx2 -ge 0) { $cmbLevel.SelectedIndex = $idx2 }
    }

    $ov = Map-OverallFromGemini (($marks + "`n" + $sec2 + "`n" + $raw))
    if ($ov) {
      $idx = $cmbOverall.Items.IndexOf($ov)
      if ($idx -ge 0) { $cmbOverall.SelectedIndex = $idx }
    }

    # --- 個別建議 ---
    if ($sec5 -and $sec5 -notmatch '^\s*\d{1,2}\s*[✓✗]' -and $sec5 -notmatch '題號註記') {
      $adv = Strip-InventedQuestionMentions $sec5 $allowed
      $txtAdvice.Text = Convert-ToTextbookMath $adv
    } elseif ([string]::IsNullOrWhiteSpace($txtAdvice.Text) -or $txtAdvice.Text -match '^\s*（|給學生') {
      $lvNow = [string]$cmbLevel.SelectedItem
      $txtAdvice.Text = switch ($lvNow) {
        '跟上' { '已掌握本卷題型，可再挑戰稍難的應用題；維持正確書寫步驟。' }
        '略落後' { '請針對錯題重練同類題，先求步驟完整再求速度。' }
        '明顯落後' { '先補本單元關鍵觀念，每天少量練習並對照解答步驟。' }
        '需補先備' { '先回到先備觀念，再做本單元基本題。' }
        default { '請依診斷弱點重看例題步驟，再做同類練習。' }
      }
    }

    # --- 自學練習（與試卷題號分開；練習題編號是練習用，不是多出試卷第 3 題）---
    if ($sec6 -and $sec6 -notmatch '題號註記') {
      $prac = Strip-InventedQuestionMentions $sec6 $allowed
      # 若誤抓到超短或其實是建議，仍用模板
      if ($prac.Length -ge 20) {
        $txtPractice.Text = Convert-ToTextbookMath $prac
      } else {
        $lvNow = [string]$cmbLevel.SelectedItem
        if (-not $lvNow -or $lvNow -eq '待判定') { $lvNow = '略落後' }
        $txtPractice.Text = Get-PracticeTemplate $lvNow
      }
    } else {
      $lvNow = [string]$cmbLevel.SelectedItem
      if (-not $lvNow -or $lvNow -eq '待判定') { $lvNow = '略落後' }
      $txtPractice.Text = Get-PracticeTemplate $lvNow
    }
  } finally {
    $script:SuppressPracticeAutoFill = $false
  }
}

function Show-GeminiKeyDialog {
  $saved = Get-GeminiApiKey $script:WorkDir
  $has = -not [string]::IsNullOrWhiteSpace($saved)
  $dlg = New-Object System.Windows.Forms.Form
  $dlg.Text = ("設定 Gemini API 金鑰｜$($script:AppBuild)")
  $dlg.Size = New-Object System.Drawing.Size(580, 340)
  $dlg.StartPosition = 'CenterParent'
  $dlg.Font = $font
  $lbl = New-Object System.Windows.Forms.Label
  $lbl.Location = New-Object System.Drawing.Point(12, 12)
  $lbl.Size = New-Object System.Drawing.Size(540, 100)
  $savedHint = if ($has) { Get-GeminiApiKeyHint $saved } else { '尚未設定' }
  $lbl.Text = "請到 https://aistudio.google.com/apikey → Create API key → Copy key。`n可接受：AIza…（舊）或 AQ.…（2026 新 Auth）。≠ Gemini 網頁訂閱。`n存於本機 MathGrading\gemini-api-key.txt。標題有 $($script:AppBuild) 才是新版。`n目前已存：$savedHint"
  $dlg.Controls.Add($lbl)
  $tb = New-Object System.Windows.Forms.TextBox
  $tb.Location = New-Object System.Drawing.Point(12, 118)
  $tb.Width = 540
  $tb.UseSystemPasswordChar = $true
  # 不自動填入舊鑰，避免一直測到錯誤的舊內容；請重新貼上
  $tb.Text = ''
  $dlg.Controls.Add($tb)
  $btnTest = New-Object System.Windows.Forms.Button
  $btnTest.Text = '測試金鑰'
  $btnTest.Location = New-Object System.Drawing.Point(12, 160)
  $btnTest.Size = New-Object System.Drawing.Size(110, 32)
  $btnTest.Add_Click({
      try {
        $r = Test-GeminiApiKey $tb.Text
        [void][System.Windows.Forms.MessageBox]::Show(
          ("金鑰可用，且已實際試過 generateContent。`n建議模型：" + $r.PreferredModel + "`n可列出模型約 " + $r.ModelCount + " 個。`n例：" + $r.Sample + "`n建置：$($script:AppBuild)"),
          '測試成功'
        )
      } catch {
        [void][System.Windows.Forms.MessageBox]::Show(
          ([string]$_.Exception.Message + "`n`n建置：$($script:AppBuild)`n若建置不是 20260817-aq24 起，請先跑更新腳本。"),
          '測試失敗'
        )
      }
    })
  $dlg.Controls.Add($btnTest)
  $btnPasteSaved = New-Object System.Windows.Forms.Button
  $btnPasteSaved.Text = '載入已存'
  $btnPasteSaved.Location = New-Object System.Drawing.Point(130, 160)
  $btnPasteSaved.Size = New-Object System.Drawing.Size(100, 32)
  $btnPasteSaved.Add_Click({
      if ($has) { $tb.Text = $saved; $tb.UseSystemPasswordChar = $true }
      else { [void][System.Windows.Forms.MessageBox]::Show('尚未有已存金鑰', '提示') }
    })
  $dlg.Controls.Add($btnPasteSaved)
  $btnOk = New-Object System.Windows.Forms.Button
  $btnOk.Text = '儲存'
  $btnOk.Location = New-Object System.Drawing.Point(340, 160)
  $btnOk.Size = New-Object System.Drawing.Size(100, 32)
  $btnOk.DialogResult = 'None'
  $btnOk.Add_Click({
      $k = Normalize-GeminiApiKey $tb.Text
      if ([string]::IsNullOrWhiteSpace($k)) {
        [void][System.Windows.Forms.MessageBox]::Show('金鑰空白，未儲存', '提示')
        return
      }
      $picked = 'gemini-3.5-flash'
      try {
        $tr = Test-GeminiApiKey $k
        if ($tr.PreferredModel) { $picked = [string]$tr.PreferredModel }
      } catch {
        $ask = [System.Windows.Forms.MessageBox]::Show(
          ("測試未通過：`n" + $_.Exception.Message + "`n`n仍要強制儲存嗎？（通常不建議）"),
          '金鑰測試',
          [System.Windows.Forms.MessageBoxButtons]::YesNo,
          [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($ask -ne [System.Windows.Forms.DialogResult]::Yes) { return }
      }
      Save-GeminiApiKey $script:WorkDir $k
      $script:settings | Add-Member -NotePropertyName geminiModel -NotePropertyValue $picked -Force
      Save-Settings $script:WorkDir $script:settings
      [void][System.Windows.Forms.MessageBox]::Show(("已儲存 Gemini API 金鑰。`n預設模型：$picked`n可再按「Gemini自動批」。"), '完成')
      $dlg.DialogResult = 'OK'
      $dlg.Close()
    })
  $dlg.Controls.Add($btnOk)
  $btnOpen = New-Object System.Windows.Forms.Button
  $btnOpen.Text = '開啟申請頁'
  $btnOpen.Location = New-Object System.Drawing.Point(240, 160)
  $btnOpen.Size = New-Object System.Drawing.Size(90, 32)
  $btnOpen.Add_Click({ Start-Process 'https://aistudio.google.com/apikey' })
  $dlg.Controls.Add($btnOpen)
  $btnCancel = New-Object System.Windows.Forms.Button
  $btnCancel.Text = '關閉'
  $btnCancel.Location = New-Object System.Drawing.Point(450, 160)
  $btnCancel.Size = New-Object System.Drawing.Size(90, 32)
  $btnCancel.DialogResult = 'Cancel'
  $dlg.Controls.Add($btnCancel)
  $hint2 = New-Object System.Windows.Forms.Label
  $hint2.Location = New-Object System.Drawing.Point(12, 210)
  $hint2.Size = New-Object System.Drawing.Size(540, 70)
  $hint2.Text = "步驟：Copy key → 貼上上方欄位 → 測試金鑰 → 儲存。`n若仍失敗：刪除舊鑰再建一把 AQ. 新鑰；並確認視窗標題含 $($script:AppBuild)。"
  $dlg.Controls.Add($hint2)
  $dlg.CancelButton = $btnCancel
  return ($dlg.ShowDialog() -eq 'OK')
}

function Load-Settings([string]$root) {
  $p = Get-SettingsPath $root
  $defaults = [pscustomobject]@{
    mode = 'gemini_auto'
    answerHint = ''
    preferredSend = '未指定（日後再選）'
    preferredReturn = '未指定（日後再選）'
    tabletImportDir = ''
    geminiModel = 'gemini-3.5-flash'
    tools = [pscustomobject]@{
      line_group = $true
      line_dm    = $true
      classroom  = $true
      drive      = $true
      lms        = $true
      junyi      = $false
      print      = $true
      loop       = $true
    }
  }
  if (Test-Path -LiteralPath $p) {
    try {
      $s = Get-Content -LiteralPath $p -Encoding UTF8 -Raw | ConvertFrom-Json
      if (-not $s.tools) { $s | Add-Member -NotePropertyName tools -NotePropertyValue $defaults.tools -Force }
      if (-not $s.preferredSend) { $s | Add-Member -NotePropertyName preferredSend -NotePropertyValue $defaults.preferredSend -Force }
      if (-not $s.preferredReturn) { $s | Add-Member -NotePropertyName preferredReturn -NotePropertyValue $defaults.preferredReturn -Force }
      if ($null -eq $s.PSObject.Properties['tabletImportDir']) {
        $s | Add-Member -NotePropertyName tabletImportDir -NotePropertyValue '' -Force
      }
      if ($null -eq $s.PSObject.Properties['geminiModel'] -or [string]::IsNullOrWhiteSpace([string]$s.geminiModel) -or [string]$s.geminiModel -match 'gemini-2\.0|gemini-1\.5|gemini-1\.0') {
        $s | Add-Member -NotePropertyName geminiModel -NotePropertyValue $defaults.geminiModel -Force
      }
      if ($null -eq $s.PSObject.Properties['mode'] -or [string]::IsNullOrWhiteSpace([string]$s.mode)) {
        $s | Add-Member -NotePropertyName mode -NotePropertyValue 'gemini_auto' -Force
      }
      return $s
    } catch {}
  }
  return $defaults
}

function Save-Settings([string]$root, $settings) {
  ($settings | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath (Get-SettingsPath $root) -Encoding UTF8
}

function Get-ToolCatalog {
  return @(
    [pscustomobject]@{ Id = 'line_group'; Title = 'LINE 班級群組'; Role = '偏發放'; Tip = '發練習連結／公告最方便；不建議全班回傳圖塞群組（難對座號、洗版）' }
    [pscustomobject]@{ Id = 'line_dm';    Title = 'LINE 個別傳老師'; Role = '偏回傳'; Tip = '學生／家長私訊傳 PDF／圖 → 老師另存「練習回傳\\05-R01.jpg」' }
    [pscustomobject]@{ Id = 'classroom';  Title = 'Google Classroom'; Role = '發＋回'; Tip = '發作業＋繳交最整齊；下載後丟「練習回傳」即可批' }
    [pscustomobject]@{ Id = 'drive';      Title = 'Google雲端／OneDrive'; Role = '發＋回'; Tip = '共用「發放」「回傳」兩夾；檔名 05-R01.jpg' }
    [pscustomobject]@{ Id = 'lms';        Title = '學校LMS／email'; Role = '發＋回'; Tip = '校內平台或信箱收件，最後匯入「練習回傳」' }
    [pscustomobject]@{ Id = 'junyi';      Title = '均一（可不用）'; Role = '選用'; Tip = '預設不用。改由 Cursor 自動產練習＋指導＋影片連結' }
    [pscustomobject]@{ Id = 'print';      Title = '無裝置列印'; Role = '發'; Tip = '只印「需列印座號」；有裝置仍走數位' }
    [pscustomobject]@{ Id = 'loop';       Title = '練習回傳循環'; Role = '批＋調題'; Tip = '回饋→調題→分數進步→達標為止（與上面發放管道並用）' }
  )
}

function Show-ToolPickerDialog {
  $dlg = New-Object System.Windows.Forms.Form
  $dlg.Text = '發放／回傳工具（可複選，日後再抉擇）'
  $dlg.Size = New-Object System.Drawing.Size(760, 580)
  $dlg.StartPosition = 'CenterParent'
  $dlg.Font = $font

  $hint = New-Object System.Windows.Forms.Label
  $hint.Text = "怎麼選？`n• 只想快：發＝LINE班級群組；回＝LINE個別傳老師（別把全班圖塞群組）`n• 想整齊長期用：Classroom 或 雲端兩夾`n勾選＝常用；偏好可日後再改，按鈕都還在。"
  $hint.Location = New-Object System.Drawing.Point(12, 8)
  $hint.Size = New-Object System.Drawing.Size(720, 58)
  $dlg.Controls.Add($hint)

  $checks = @{}
  $y = 72
  foreach ($t in Get-ToolCatalog) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = "[$($t.Role)] $($t.Title)  —  $($t.Tip)"
    $cb.Location = New-Object System.Drawing.Point(16, $y)
    $cb.Size = New-Object System.Drawing.Size(710, 34)
    $on = $true
    try { $on = [bool]$script:settings.tools.($t.Id) } catch { $on = $true }
    $cb.Checked = $on
    $dlg.Controls.Add($cb)
    $checks[$t.Id] = $cb
    $y += 36
  }

  $lblSend = New-Object System.Windows.Forms.Label
  $lblSend.Text = '偏好發放'
  $lblSend.Location = New-Object System.Drawing.Point(16, $y + 8)
  $lblSend.Size = New-Object System.Drawing.Size(90, 24)
  $dlg.Controls.Add($lblSend)

  $cmbSend = New-Object System.Windows.Forms.ComboBox
  $cmbSend.DropDownStyle = 'DropDownList'
  $cmbSend.Items.AddRange(@(
      '未指定（日後再選）',
      'LINE 班級群組',
      'Google Classroom',
      'Google雲端／OneDrive',
      '學校LMS／email',
      '無裝置列印'
    ))
  $cmbSend.Location = New-Object System.Drawing.Point(110, $y + 4)
  $cmbSend.Size = New-Object System.Drawing.Size(240, 28)
  $idxS = $cmbSend.Items.IndexOf([string]$script:settings.preferredSend)
  $cmbSend.SelectedIndex = $(if ($idxS -ge 0) { $idxS } else { 0 })
  $dlg.Controls.Add($cmbSend)

  $lblRet = New-Object System.Windows.Forms.Label
  $lblRet.Text = '偏好回傳'
  $lblRet.Location = New-Object System.Drawing.Point(370, $y + 8)
  $lblRet.Size = New-Object System.Drawing.Size(90, 24)
  $dlg.Controls.Add($lblRet)

  $cmbRet = New-Object System.Windows.Forms.ComboBox
  $cmbRet.DropDownStyle = 'DropDownList'
  $cmbRet.Items.AddRange(@(
      '未指定（日後再選）',
      'LINE 個別傳老師',
      'Google Classroom',
      'Google雲端／OneDrive',
      '學校LMS／email'
    ))
  $cmbRet.Location = New-Object System.Drawing.Point(460, $y + 4)
  $cmbRet.Size = New-Object System.Drawing.Size(240, 28)
  $idxR = $cmbRet.Items.IndexOf([string]$script:settings.preferredReturn)
  $cmbRet.SelectedIndex = $(if ($idxR -ge 0) { $idxR } else { 0 })
  $dlg.Controls.Add($cmbRet)

  $btnOk = New-Object System.Windows.Forms.Button
  $btnOk.Text = '儲存選擇'
  $btnOk.Location = New-Object System.Drawing.Point(460, $y + 44)
  $btnOk.Size = New-Object System.Drawing.Size(100, 32)
  $btnOk.Add_Click({
      $tools = [pscustomobject]@{}
      foreach ($k in $checks.Keys) {
        $tools | Add-Member -NotePropertyName $k -NotePropertyValue ([bool]$checks[$k].Checked) -Force
      }
      $script:settings | Add-Member -NotePropertyName tools -NotePropertyValue $tools -Force
      $script:settings | Add-Member -NotePropertyName preferredSend -NotePropertyValue ([string]$cmbSend.SelectedItem) -Force
      $script:settings | Add-Member -NotePropertyName preferredReturn -NotePropertyValue ([string]$cmbRet.SelectedItem) -Force
      Save-Settings $script:WorkDir $script:settings
      $lines = @(
        '我的發放／回傳工具選擇（可隨時改）'
        '================================'
        ('偏好發放：' + $script:settings.preferredSend)
        ('偏好回傳：' + $script:settings.preferredReturn)
        ''
        '建議組合：'
        '・快又省事 → 發：LINE班級群組　回：LINE個別傳老師'
        '・練習來源 → Cursor 自動產題＋指導＋影片連結（不用均一）'
        '・要長期整齊 → Classroom 或 雲端兩夾'
        '・群組只公告，不要當作業回收桶'
        ''
        '已勾選常用工具：'
      )
      foreach ($t in Get-ToolCatalog) {
        $flag = if ($checks[$t.Id].Checked) { '☑' } else { '☐' }
        $lines += ("$flag $($t.Title)｜$($t.Tip)")
      }
      $out = Join-Path $script:WorkDir '我的工具選擇.txt'
      $utf8Bom = New-Object System.Text.UTF8Encoding $true
      [IO.File]::WriteAllText($out, ($lines -join "`r`n"), $utf8Bom)
      $status.Text = '已儲存工具選擇：' + $out
      $dlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
      $dlg.Close()
    })
  $dlg.Controls.Add($btnOk)

  $btnGuide = New-Object System.Windows.Forms.Button
  $btnGuide.Text = '開說明'
  $btnGuide.Location = New-Object System.Drawing.Point(570, $y + 44)
  $btnGuide.Size = New-Object System.Drawing.Size(90, 32)
  $btnGuide.Add_Click({
      [void](Invoke-MakePdf -Root $script:WorkDir -PendingReturns)
      $g = Join-Path $script:WorkDir '數位發放與回傳說明.txt'
      if (Test-Path -LiteralPath $g) { Start-Process notepad.exe $g }
    })
  $dlg.Controls.Add($btnGuide)

  $btnQuick = New-Object System.Windows.Forms.Button
  $btnQuick.Text = '一鍵：LINE群發＋個別回'
  $btnQuick.Location = New-Object System.Drawing.Point(16, $y + 44)
  $btnQuick.Size = New-Object System.Drawing.Size(220, 32)
  $btnQuick.BackColor = [System.Drawing.Color]::FromArgb(30, 110, 90)
  $btnQuick.ForeColor = [System.Drawing.Color]::White
  $btnQuick.FlatStyle = 'Flat'
  $btnQuick.Add_Click({
      $cmbSend.SelectedItem = 'LINE 班級群組'
      $cmbRet.SelectedItem = 'LINE 個別傳老師'
      foreach ($k in @('line_group', 'line_dm', 'loop', 'print')) {
        if ($checks.ContainsKey($k)) { $checks[$k].Checked = $true }
      }
      [void][System.Windows.Forms.MessageBox]::Show(
        "已選好常用組合：`n發放 → LINE 班級群組`n回傳 → LINE 個別傳老師`n`n再按「儲存選擇」即可。`n（有 Classroom／雲端也可再勾，日後換用）",
        'LINE 組合'
      )
    })
  $dlg.Controls.Add($btnQuick)

  [void]$dlg.ShowDialog($form)
}

function Get-TabletImportDir([string]$root) {
  $custom = ''
  try { $custom = [string]$script:settings.tabletImportDir } catch {}
  if ($custom -and (Test-Path -LiteralPath $custom)) { return $custom }
  $def = Join-Path $root '手寫匯入'
  New-Item -ItemType Directory -Force -Path $def | Out-Null
  return $def
}

function Get-NextPracticeRound([string]$root, [string]$sid) {
  $used = New-Object 'System.Collections.Generic.HashSet[int]'
  $histPath = Join-Path (Join-Path $root '練習歷程') ($sid + '-歷程.json')
  if (Test-Path -LiteralPath $histPath) {
    try {
      $h = Get-Content -LiteralPath $histPath -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($a in @($h.attempts)) {
        [void]$used.Add([int]$a.round)
      }
    } catch {}
  }
  $retDir = Join-Path $root '練習回傳'
  if (Test-Path -LiteralPath $retDir) {
    Get-ChildItem -LiteralPath $retDir -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -match ('^' + $sid) } |
      ForEach-Object {
        if ($_.BaseName -match '[Rr]0*(\d+)') { [void]$used.Add([int]$Matches[1]) }
        elseif ($_.BaseName -match '第\s*(\d+)\s*次') { [void]$used.Add([int]$Matches[1]) }
      }
  }
  $n = 1
  while ($used.Contains($n)) { $n++ }
  return $n
}

function Import-TabletFileToReturn {
  param(
    [string]$Root,
    [string]$Sid,
    [System.IO.FileInfo]$SourceFile
  )
  $retDir = Join-Path $Root '練習回傳'
  New-Item -ItemType Directory -Force -Path $retDir | Out-Null
  $ext = $SourceFile.Extension.ToLowerInvariant()
  if ($ext -notmatch '\.(pdf|png|jpe?g|tif{1,2}|bmp|webp)$') {
    throw "不支援的檔案類型：$ext"
  }
  # If already named like 05-R01.jpg keep stem when seat matches
  $destName = $null
  if ($SourceFile.BaseName -match ('^' + $Sid + '([-_].*)?$')) {
    if ($SourceFile.BaseName -match '[Rr]0*\d+' -or $SourceFile.BaseName -match '第\s*\d+\s*次') {
      $destName = $SourceFile.Name
    }
  }
  if (-not $destName) {
    $rnd = Get-NextPracticeRound $Root $Sid
    $destName = ('{0}-R{1:D2}{2}' -f $Sid, $rnd, $ext)
  }
  $dest = Join-Path $retDir $destName
  if (Test-Path -LiteralPath $dest) {
    $rnd = Get-NextPracticeRound $Root $Sid
    $destName = ('{0}-R{1:D2}{2}' -f $Sid, $rnd, $ext)
    $dest = Join-Path $retDir $destName
  }
  Copy-Item -LiteralPath $SourceFile.FullName -Destination $dest -Force
  return (Get-Item -LiteralPath $dest)
}

function Show-TabletImportAndGrade {
  Ensure-WorkTree $script:WorkDir
  if (-not $script:current) {
    [void][System.Windows.Forms.MessageBox]::Show('請先在左側選一位學生（座號），再匯入手寫檔。', '手寫板')
    return
  }
  $sid = Get-StudentId $script:current.Name
  $importDir = Get-TabletImportDir $script:WorkDir

  $dlg = New-Object System.Windows.Forms.Form
  $dlg.Text = "手寫板匯入並批｜座號 $sid"
  $dlg.Size = New-Object System.Drawing.Size(640, 420)
  $dlg.StartPosition = 'CenterParent'
  $dlg.Font = $font

  $lbl = New-Object System.Windows.Forms.Label
  $lbl.Text = "把平板／手寫板匯出的圖或 PDF 放到下方資料夾後選檔，一鍵進「練習回傳」並複製 Cursor 批閱提示。"
  $lbl.Location = New-Object System.Drawing.Point(12, 10)
  $lbl.Size = New-Object System.Drawing.Size(600, 40)
  $dlg.Controls.Add($lbl)

  $lblDir = New-Object System.Windows.Forms.Label
  $lblDir.Text = '匯入資料夾：' + $importDir
  $lblDir.Location = New-Object System.Drawing.Point(12, 55)
  $lblDir.Size = New-Object System.Drawing.Size(480, 40)
  $dlg.Controls.Add($lblDir)

  $btnPickDir = New-Object System.Windows.Forms.Button
  $btnPickDir.Text = '改資料夾'
  $btnPickDir.Location = New-Object System.Drawing.Point(500, 55)
  $btnPickDir.Size = New-Object System.Drawing.Size(100, 28)
  $btnPickDir.Add_Click({
      $fb = New-Object System.Windows.Forms.FolderBrowserDialog
      $fb.SelectedPath = $importDir
      if ($fb.ShowDialog() -eq 'OK') {
        $script:settings | Add-Member -NotePropertyName tabletImportDir -NotePropertyValue $fb.SelectedPath -Force
        Save-Settings $script:WorkDir $script:settings
        $importDir = $fb.SelectedPath
        $lblDir.Text = '匯入資料夾：' + $importDir
        Refresh-TabletList
      }
    })
  $dlg.Controls.Add($btnPickDir)

  $listFiles = New-Object System.Windows.Forms.ListBox
  $listFiles.Location = New-Object System.Drawing.Point(12, 100)
  $listFiles.Size = New-Object System.Drawing.Size(590, 180)
  $dlg.Controls.Add($listFiles)

  function Refresh-TabletList {
    $listFiles.Items.Clear()
    if (-not (Test-Path -LiteralPath $importDir)) { return }
    $files = @(Get-ChildItem -LiteralPath $importDir -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Extension -match '\.(pdf|png|jpe?g|tif{1,2}|bmp|webp)$' } |
      Sort-Object LastWriteTime -Descending)
    foreach ($f in $files) {
      [void]$listFiles.Items.Add(('{0} ｜ {1}' -f $f.Name, $f.LastWriteTime.ToString('MM-dd HH:mm')))
    }
    if ($listFiles.Items.Count -gt 0) { $listFiles.SelectedIndex = 0 }
  }
  Refresh-TabletList

  $btnOpenDir = New-Object System.Windows.Forms.Button
  $btnOpenDir.Text = '開匯入夾'
  $btnOpenDir.Location = New-Object System.Drawing.Point(12, 295)
  $btnOpenDir.Size = New-Object System.Drawing.Size(100, 32)
  $btnOpenDir.Add_Click({ Start-Process explorer.exe $importDir; Start-Sleep -Milliseconds 400; Refresh-TabletList })
  $dlg.Controls.Add($btnOpenDir)

  $btnRefresh = New-Object System.Windows.Forms.Button
  $btnRefresh.Text = '重新整理'
  $btnRefresh.Location = New-Object System.Drawing.Point(120, 295)
  $btnRefresh.Size = New-Object System.Drawing.Size(100, 32)
  $btnRefresh.Add_Click({ Refresh-TabletList })
  $dlg.Controls.Add($btnRefresh)

  $btnGo = New-Object System.Windows.Forms.Button
  $btnGo.Text = '匯入並立即批閱'
  $btnGo.Location = New-Object System.Drawing.Point(280, 295)
  $btnGo.Size = New-Object System.Drawing.Size(160, 32)
  $btnGo.BackColor = [System.Drawing.Color]::FromArgb(30, 100, 70)
  $btnGo.ForeColor = [System.Drawing.Color]::White
  $btnGo.FlatStyle = 'Flat'
  $btnGo.Add_Click({
      if ($listFiles.SelectedIndex -lt 0) {
        [void][System.Windows.Forms.MessageBox]::Show('請先選一個手寫檔（或把檔案存進匯入夾後按重新整理）', '手寫板')
        return
      }
      $files = @(Get-ChildItem -LiteralPath $importDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '\.(pdf|png|jpe?g|tif{1,2}|bmp|webp)$' } |
        Sort-Object LastWriteTime -Descending)
      if ($listFiles.SelectedIndex -ge $files.Count) { return }
      $src = $files[$listFiles.SelectedIndex]
      try {
        $dest = Import-TabletFileToReturn -Root $script:WorkDir -Sid $sid -SourceFile $src
      } catch {
        [void][System.Windows.Forms.MessageBox]::Show([string]$_.Exception.Message, '匯入失敗')
        return
      }
      $rnd = 1
      if ($dest.BaseName -match '[Rr]0*(\d+)') { $rnd = [int]$Matches[1] }
      $prompt = Build-ReturnCursorPrompt $script:WorkDir $sid $dest $rnd
      [System.Windows.Forms.Clipboard]::SetText($prompt)
      Start-Process -FilePath $dest.FullName
      $status.Text = "手寫已匯入：$($dest.Name)｜已複製 Cursor 批閱提示"
      $dlg.Close()
      [void][System.Windows.Forms.MessageBox]::Show(
        "已匯入練習回傳：$($dest.Name)`n`n已複製「批閱回傳」提示到剪貼簿，並開啟檔案。`n請到 Cursor 貼上並附檔。`n批完後打開「練習回傳循環」貼回分數／指導／下一輪練習。",
        '手寫板即時批閱'
      )
      Show-PracticeLoopDialog
    })
  $dlg.Controls.Add($btnGo)

  $btnCancel = New-Object System.Windows.Forms.Button
  $btnCancel.Text = '關閉'
  $btnCancel.Location = New-Object System.Drawing.Point(500, 295)
  $btnCancel.Size = New-Object System.Drawing.Size(100, 32)
  $btnCancel.Add_Click({ $dlg.Close() })
  $dlg.Controls.Add($btnCancel)

  $hint2 = New-Object System.Windows.Forms.Label
  $hint2.Text = '也可把 OneNote／Whiteboard／繪圖軟體的預設匯出路徑設成「改資料夾」。'
  $hint2.Location = New-Object System.Drawing.Point(12, 340)
  $hint2.Size = New-Object System.Drawing.Size(600, 30)
  $dlg.Controls.Add($hint2)

  [void]$dlg.ShowDialog($form)
}

function Get-LatestReturnFile([string]$root, [string]$sid) {
  $dir = Join-Path $root '練習回傳'
  if (-not (Test-Path -LiteralPath $dir)) { return $null }
  $hits = @(Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match ('^' + $sid) -and $_.Extension -match '\.(pdf|png|jpe?g|tif{1,2}|bmp|webp)$' } |
    Sort-Object LastWriteTime -Descending)
  if ($hits.Count -gt 0) { return $hits[0] }
  return $null
}

function Get-StudentLevelFromNote([string]$root, [string]$sid) {
  $p = Get-NotePath $root $sid
  if (-not (Test-Path -LiteralPath $p)) { return '待判定' }
  $n = Load-Note $p
  if ($n.level) { return [string]$n.level }
  return '待判定'
}

function Test-IsBehindLevel([string]$level) {
  return ($level -match '明顯落後|需補先備')
}

function Build-ReturnCursorPrompt([string]$root, [string]$sid, $returnFile, [int]$round) {
  $histPath = Join-Path (Join-Path $root '練習歷程') ($sid + '-歷程.json')
  $histTxt = ''
  if (Test-Path -LiteralPath $histPath) {
    $histTxt = Get-Content -LiteralPath $histPath -Raw -Encoding UTF8
  }
  $level = Get-StudentLevelFromNote $root $sid
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('請批閱這位學生「練習回傳」第 ' + $round + ' 次（PDF／圖檔）。')
  [void]$sb.AppendLine((Get-TextbookMathPromptRule))
  [void]$sb.AppendLine('程度：' + $level)
  [void]$sb.AppendLine('每次回饋都要含：分數、問題點、進步說明、下一次練習（含自學指導＋建議影片連結或 YouTube 搜尋頁）。')
  [void]$sb.AppendLine('不要依賴均一指派；請直接自動產生練習題、逐步指導、合適教學影片連結／搜尋關鍵詞。')
  if (Test-IsBehindLevel $level) {
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('【落後生｜多次補齊 → 有成就 → 漸次跟上】')
    [void]$sb.AppendLine('- 回饋先寫做對／進步之處，再寫「下一次要補的那一小點」。')
    [void]$sb.AppendLine('- 一次只補 1 個洞、題數 ≤ 3；下一題只難一點點。')
    [void]$sb.AppendLine('- 「多次」是分日／分次小補；兩次之間宜隔開。')
    [void]$sb.AppendLine('- 階段小目標（約 60～70%）做對＝本次成功。')
    [void]$sb.AppendLine('- 必須附：自學指導（短步驟）＋ 1 個對準本次問題的影片搜尋連結（可用 youtube results?search_query=）。')
  } else {
    [void]$sb.AppendLine('目標：針對問題點給適切回饋並自動產下一輪練習；略落後建議本單元 ≤ 3 輪。')
  }
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('請輸出可直接貼回批改程式的欄位：')
  [void]$sb.AppendLine('1) 分數：得分/滿分')
  [void]$sb.AppendLine('2) 問題點')
  [void]$sb.AppendLine('3) 回饋說明（先成就再下一步）')
  [void]$sb.AppendLine('4) 是否達標：是／否')
  [void]$sb.AppendLine('5) 下一次練習全文：須含「自學指導」「建議影片／學習連結」「練習題」「解答」（題目與解答分段）')
  [void]$sb.AppendLine('6) 分數進步一句話＋本次成就一句話')
  [void]$sb.AppendLine('影片規則：優先給可點的 YouTube 搜尋結果連結；若有把握再給具體影片 URL；禁止捏造不存在的影片網址。')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('座號：' + $sid)
  [void]$sb.AppendLine('本輪回傳檔：' + $(if ($returnFile) { $returnFile.FullName } else { '（尚未放入練習回傳）' }))
  [void]$sb.AppendLine('建議回傳檔名格式：' + $sid + '-R' + ('{0:D2}' -f $round) + '.jpg 或 .pdf')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('既有歷程 JSON（若有）：')
  if ($histTxt) { [void]$sb.AppendLine($histTxt) } else { [void]$sb.AppendLine('（尚無，此為第 1 次）') }
  return $sb.ToString()
}

function Show-PracticeLoopDialog {
  if (-not $script:current) {
    [void][System.Windows.Forms.MessageBox]::Show('請先在主畫面選左側一位學生', '提示')
    return
  }
  $sid = Get-StudentId $script:current.Name
  Ensure-WorkTree $script:WorkDir
  $level = Get-StudentLevelFromNote $script:WorkDir $sid
  $behind = Test-IsBehindLevel $level

  $dlg = New-Object System.Windows.Forms.Form
  $dlg.Text = "練習回傳循環｜座號 $sid｜$level"
  $dlg.Size = New-Object System.Drawing.Size(780, 680)
  $dlg.StartPosition = 'CenterParent'
  $dlg.Font = $font

  $ret = Get-LatestReturnFile $script:WorkDir $sid
  $roundGuess = 1
  $histPath = Join-Path (Join-Path $script:WorkDir '練習歷程') ($sid + '-歷程.json')
  if (Test-Path -LiteralPath $histPath) {
    try {
      $h = Get-Content -LiteralPath $histPath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($h.attempts) { $roundGuess = @($h.attempts).Count + 1 }
    } catch {}
  }
  if ($ret -and $ret.BaseName -match '[Rr]0*(\d+)') { $roundGuess = [int]$Matches[1] }
  elseif ($ret -and $ret.BaseName -match '第\s*(\d+)\s*次') { $roundGuess = [int]$Matches[1] }

  $paceNote = if ($behind) {
    '落後生：多次補齊（每次 1 點、≤3 題）→ 有成就再下次；勿一次補完、勿連催多輪。'
  } else {
    '可依問題點調下一輪；略落後也建議分次、少題。'
  }
  $lblInfo = New-Object System.Windows.Forms.Label
  $lblInfo.Text = $(if ($ret) { "最新回傳：$($ret.Name)`n$paceNote" } else { "尚無回傳檔 → 請放到「練習回傳」夾`n$paceNote" })
  $lblInfo.Location = New-Object System.Drawing.Point(12, 8)
  $lblInfo.Size = New-Object System.Drawing.Size(740, 42)
  $dlg.Controls.Add($lblInfo)

  function Add-DlgLabel([int]$yy, [string]$text) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Location = New-Object System.Drawing.Point(12, $yy)
    $l.Size = New-Object System.Drawing.Size(120, 24)
    $dlg.Controls.Add($l)
  }

  Add-DlgLabel 56 '次數 R'
  $numRound = New-Object System.Windows.Forms.NumericUpDown
  $numRound.Location = New-Object System.Drawing.Point(140, 54)
  $numRound.Size = New-Object System.Drawing.Size(70, 28)
  $numRound.Minimum = 1; $numRound.Maximum = 99; $numRound.Value = [Math]::Max(1, [Math]::Min(99, $roundGuess))
  $dlg.Controls.Add($numRound)

  Add-DlgLabel 56 '分數'
  $txtScore = New-Object System.Windows.Forms.TextBox
  $txtScore.Location = New-Object System.Drawing.Point(280, 54)
  $txtScore.Size = New-Object System.Drawing.Size(60, 28)
  $txtScore.Text = '0'
  $dlg.Controls.Add($txtScore)

  $lblSlash = New-Object System.Windows.Forms.Label
  $lblSlash.Text = '/'
  $lblSlash.Location = New-Object System.Drawing.Point(345, 56)
  $lblSlash.Size = New-Object System.Drawing.Size(20, 24)
  $dlg.Controls.Add($lblSlash)

  $txtMax = New-Object System.Windows.Forms.TextBox
  $txtMax.Location = New-Object System.Drawing.Point(365, 54)
  $txtMax.Size = New-Object System.Drawing.Size(60, 28)
  $txtMax.Text = '100'
  $dlg.Controls.Add($txtMax)

  Add-DlgLabel 56 '目標%'
  $txtTarget = New-Object System.Windows.Forms.TextBox
  $txtTarget.Location = New-Object System.Drawing.Point(520, 54)
  $txtTarget.Size = New-Object System.Drawing.Size(60, 28)
  $txtTarget.Text = $(if ($behind) { '65' } else { '80' })
  $dlg.Controls.Add($txtTarget)

  $chkMet = New-Object System.Windows.Forms.CheckBox
  $chkMet.Text = '階段成功'
  $chkMet.Location = New-Object System.Drawing.Point(600, 56)
  $chkMet.Size = New-Object System.Drawing.Size(120, 24)
  $dlg.Controls.Add($chkMet)

  Add-DlgLabel 94 '學習目標'
  $txtGoal = New-Object System.Windows.Forms.TextBox
  $txtGoal.Location = New-Object System.Drawing.Point(140, 92)
  $txtGoal.Size = New-Object System.Drawing.Size(600, 28)
  $txtGoal.Text = $(if ($behind) {
      '多次補齊：本次只穩 1 點並讓她有成就；其餘下次再補，漸次跟上'
    } else {
      '針對問題點練到穩定掌握'
    })
  $dlg.Controls.Add($txtGoal)

  Add-DlgLabel 130 '問題點'
  $txtPP = New-Object System.Windows.Forms.TextBox
  $txtPP.Multiline = $true; $txtPP.ScrollBars = 'Vertical'
  $txtPP.Location = New-Object System.Drawing.Point(140, 128)
  $txtPP.Size = New-Object System.Drawing.Size(600, 64)
  $dlg.Controls.Add($txtPP)

  Add-DlgLabel 200 '回饋說明'
  $txtFb = New-Object System.Windows.Forms.TextBox
  $txtFb.Multiline = $true; $txtFb.ScrollBars = 'Vertical'
  $txtFb.Location = New-Object System.Drawing.Point(140, 198)
  $txtFb.Size = New-Object System.Drawing.Size(600, 80)
  $txtFb.Text = $(if ($behind) { '（先寫她做對了什麼 → 再寫下一步一小步；語氣要有成就感）' } else { '' })
  $dlg.Controls.Add($txtFb)

  Add-DlgLabel 288 '下一輪練習'
  $txtNext = New-Object System.Windows.Forms.TextBox
  $txtNext.Multiline = $true; $txtNext.ScrollBars = 'Vertical'
  $txtNext.Location = New-Object System.Drawing.Point(140, 286)
  $txtNext.Size = New-Object System.Drawing.Size(600, 150)
  if ($behind) {
    $txtNext.Text = @"
#### 練習題（本次補齊｜≤3題｜先延續成就）
【成就延續】剛做對的類型再穩一次
1. …

【下一次要補的一小點】（只難一點點；會做就停）
2. …
3. （選做）

---
#### 解答（全部題目完成後再看）
1. …
2. …
3. …
備註：未補完的洞下次再補＝多次補齊；中間可隔日，不要連催。
"@
  } else {
    $txtNext.Text = "#### 練習題（先做完再看解答）`r`n1. …`r`n`r`n---`r`n#### 解答（全部題目完成後再看）`r`n1. …"
  }
  $dlg.Controls.Add($txtNext)

  $btnOpenRet = New-Object System.Windows.Forms.Button
  $btnOpenRet.Text = '開回傳檔／夾'
  $btnOpenRet.Location = New-Object System.Drawing.Point(12, 460)
  $btnOpenRet.Size = New-Object System.Drawing.Size(130, 32)
  $btnOpenRet.Add_Click({
      Start-Process explorer.exe (Join-Path $script:WorkDir '練習回傳')
      if ($ret) { Start-Process -FilePath $ret.FullName }
    })
  $dlg.Controls.Add($btnOpenRet)

  $btnPrompt = New-Object System.Windows.Forms.Button
  $btnPrompt.Text = '複製Cursor批回傳'
  $btnPrompt.Location = New-Object System.Drawing.Point(150, 460)
  $btnPrompt.Size = New-Object System.Drawing.Size(150, 32)
  $btnPrompt.Add_Click({
      $p = Build-ReturnCursorPrompt $script:WorkDir $sid $ret ([int]$numRound.Value)
      [System.Windows.Forms.Clipboard]::SetText($p)
      if ($ret) { Start-Process -FilePath $ret.FullName }
      [void][System.Windows.Forms.MessageBox]::Show('已複製「批閱回傳」提示。請到 Cursor 貼上並附回傳檔，再把分數／問題點／回饋／下一輪練習貼回本視窗。', 'Cursor')
    })
  $dlg.Controls.Add($btnPrompt)

  $btnSave = New-Object System.Windows.Forms.Button
  $btnSave.Text = '儲存本輪＋下一輪數位練習'
  $btnSave.Location = New-Object System.Drawing.Point(310, 460)
  $btnSave.Size = New-Object System.Drawing.Size(240, 32)
  $btnSave.BackColor = [System.Drawing.Color]::FromArgb(30, 100, 70)
  $btnSave.ForeColor = [System.Drawing.Color]::White
  $btnSave.FlatStyle = 'Flat'
  $btnSave.Add_Click({
      $score = 0.0; $max = 100.0; $target = 80.0
      [void][double]::TryParse($txtScore.Text, [ref]$score)
      [void][double]::TryParse($txtMax.Text, [ref]$max)
      [void][double]::TryParse($txtTarget.Text, [ref]$target)
      if ($max -le 0) { $max = 100 }
      $payload = [ordered]@{
        studentId     = $sid
        round         = [int]$numRound.Value
        sourceFile    = $(if ($ret) { $ret.Name } else { '' })
        score         = $score
        maxScore      = $max
        targetScore   = $target
        goal          = $txtGoal.Text
        problemPoints = $txtPP.Text
        feedback      = $txtFb.Text
        nextPractice  = $txtNext.Text
        goalMet       = [bool]$chkMet.Checked
      }
      # auto goalMet from score if unchecked but score high
      if (-not $chkMet.Checked -and $max -gt 0 -and (100.0 * $score / $max) -ge $target) {
        $payload.goalMet = $true
      }
      $jsonPath = Join-Path (Join-Path $script:WorkDir '練習歷程') ($sid + '-attempt-tmp.json')
      $utf8Bom = New-Object System.Text.UTF8Encoding $true
      [IO.File]::WriteAllText($jsonPath, ($payload | ConvertTo-Json -Depth 5), $utf8Bom)
      if (Invoke-MakePdf -Root $script:WorkDir -AppendAttempt -AttemptJson $jsonPath) {
        $status.Text = "已儲存座號 $sid 第 $($numRound.Value) 次回饋／歷程"
        $prog = Join-Path (Join-Path $script:WorkDir '練習歷程') ($sid + '-歷程.html')
        if (Test-Path -LiteralPath $prog) { Start-Process -FilePath $prog }
        [void][System.Windows.Forms.MessageBox]::Show(
          "已寫入練習歷程（含分數進步）。`n未達標者已更新「數位練習」下一輪題目。`n可再依你偏好的發放工具傳給學生。",
          '完成'
        )
      }
    })
  $dlg.Controls.Add($btnSave)

  $btnHist = New-Object System.Windows.Forms.Button
  $btnHist.Text = '開歷程'
  $btnHist.Location = New-Object System.Drawing.Point(560, 460)
  $btnHist.Size = New-Object System.Drawing.Size(90, 32)
  $btnHist.Add_Click({
      [void](Invoke-MakePdf -Root $script:WorkDir -Student $sid -ProgressHtml)
      $prog = Join-Path (Join-Path $script:WorkDir '練習歷程') ($sid + '-歷程.html')
      if (Test-Path -LiteralPath $prog) { Start-Process -FilePath $prog }
      else { Start-Process explorer.exe (Join-Path $script:WorkDir '練習歷程') }
    })
  $dlg.Controls.Add($btnHist)

  $btnPending = New-Object System.Windows.Forms.Button
  $btnPending.Text = '待批清單'
  $btnPending.Location = New-Object System.Drawing.Point(660, 460)
  $btnPending.Size = New-Object System.Drawing.Size(90, 32)
  $btnPending.Add_Click({
      if (Invoke-MakePdf -Root $script:WorkDir -PendingReturns) {
        $p = Join-Path (Join-Path $script:WorkDir '練習歷程') '待批閱回傳清單.md'
        if (Test-Path -LiteralPath $p) { Start-Process -FilePath $p }
      }
    })
  $dlg.Controls.Add($btnPending)

  $foot = New-Object System.Windows.Forms.Label
  $foot.Text = '落後生＝多次補齊（每次有成就）→ 漸次跟上。發放用群組公告、回傳走個別；工具可在「工具選擇」改。'
  $foot.Location = New-Object System.Drawing.Point(12, 520)
  $foot.Size = New-Object System.Drawing.Size(740, 40)
  $dlg.Controls.Add($foot)
  $foot.Location = New-Object System.Drawing.Point(12, 505)
  $foot.Size = New-Object System.Drawing.Size(740, 40)
  $dlg.Controls.Add($foot)

  [void]$dlg.ShowDialog($form)
}

function Build-CursorPrompt([string]$root) {
  $inputs = @(Get-InputFiles $root)
  $ansDir = Join-Path $root '標準答案'
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('請初核下列數學習作（加速人工打勾；非最終成績）。')
  [void]$sb.AppendLine('規則：有標準答案時以答案為準；接受其他合理等價解法；潦草／不確定標「存疑」。')
  [void]$sb.AppendLine((Get-TextbookMathPromptRule))
  [void]$sb.AppendLine('每位學生輸出一份註記：題號註記、對錯摘要、診斷、程度、建議、自學練習（含自學指導＋建議影片＋練習題＋解答）。')
  [void]$sb.AppendLine('不要用均一指派；請直接自動產生練習題、指導步驟、合適網路教學影片連結或 YouTube 搜尋頁。')
  [void]$sb.AppendLine('跟上者：少鞏固、多再提升挑戰；好的學生要能再進步。')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('工作資料夾：' + $root)
  [void]$sb.AppendLine('標準答案資料夾：' + $ansDir)
  [void]$sb.AppendLine('輸入檔：')
  foreach ($f in $inputs) {
    [void]$sb.AppendLine(' - ' + $f.FullName)
  }
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('請依檔名座號逐人批閱；正確題標 ✓ 供我快速打勾，存疑標 ?。')
  return $sb.ToString()
}

function Build-CursorPromptOne([string]$root, $studentFile, [switch]$HandwritingHard) {
  $id = Get-StudentId $studentFile.Name
  $ansFiles = @(Get-AnswerFiles $root)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('請直接批閱這一位學生的數學試卷（一人一檔）。')
  [void]$sb.AppendLine((Get-TextbookMathPromptRule))
  if ($HandwritingHard) {
    [void]$sb.AppendLine('【手寫加強模式｜辨識優先】')
    [void]$sb.AppendLine('這份是手寫／掃描，字跡可能很差。請依下列強制規則：')
    [void]$sb.AppendLine('A. 先「逐格／逐位」判讀數字與運算符號；放大細節再決定。')
    [void]$sb.AppendLine('B. 只對「有把握」的內容判 ✓／✗；沒把握一律標 ?，禁止猜答案硬批。')
    [void]$sb.AppendLine('C. 每個 ? 必須寫：位置（第幾題／哪一行）、你看到的候選（例如 6 或 0）、為何不確定。')
    [void]$sb.AppendLine('D. 先輸出「手寫轉譯稿」：把看得懂的式子打成純文字；看不清處用【?】占位。')
    [void]$sb.AppendLine('E. 能批的題先批完；整題都看不清就整題 ?，不要整份放棄。')
    [void]$sb.AppendLine('F. 最後給「老師認知輸入清單」：要我補哪幾格文字／是否建議學生重謄。')
    [void]$sb.AppendLine('G. 程度判定：若 ? 太多，程度可寫「待判定」，並說明待認知後再定。')
  } else {
    if ($ansFiles.Count -gt 0) {
      [void]$sb.AppendLine('【模式｜對照正確答案】')
      [void]$sb.AppendLine('規則：必須以我一併提供的「正確答案」檔為批改依據；學生卷與答案不一致才可判 ✗。')
      [void]$sb.AppendLine('接受合理等價解法；看不懂標 ? 存疑（供我人工確認／重謄）。禁止忽略答案自行另立標準。')
    } else {
      [void]$sb.AppendLine('【模式｜直接 AI 批閱（無標準答案檔）】')
      [void]$sb.AppendLine('規則：未附正確答案檔；請依題意與數學正確性直接批改（合理等價解法給 ✓）。')
      [void]$sb.AppendLine('看不懂標 ? 存疑；字跡潦草寧可多標 ?，不要猜錯。')
    }
    [void]$sb.AppendLine('若字跡潦草：寧可多標 ?，不要猜錯；可先給看得懂題目的診斷與練習。')
  }
  [void]$sb.AppendLine('請務必輸出：')
  if ($HandwritingHard) {
    [void]$sb.AppendLine('0) 手寫轉譯稿（純文字式子＋【?】）')
    [void]$sb.AppendLine('0b) 老師認知輸入清單（題號／位置／候選字）')
  }
  [void]$sb.AppendLine('1) 題號註記（✓／✗／?；? 要附原因）')
  [void]$sb.AppendLine('2) 對錯摘要（分開：已確認／仍存疑）')
  [void]$sb.AppendLine('3) 個別診斷結果（弱點類型、是否跟得上進度；存疑多則待判定）')
  [void]$sb.AppendLine('4) 程度分級：跟上／略落後／明顯落後／需補先備／待判定')
  [void]$sb.AppendLine('5) 個別建議（短）')
  [void]$sb.AppendLine('6) 依程度自學練習（請一次寫完整，我會存成數位練習給學生）：')
  [void]$sb.AppendLine('【格式強制】必須依序出現「1)」「2)」「3)」「4)」「5)」「6)」六個標題；內容不可互相塞錯欄。')
  [void]$sb.AppendLine('【題數強制】題號註記只能寫學生卷／正確答案上「實際出現」的題；禁止虛構第 3 題（若只有 1～2 題就只寫到實際題號）。')
  [void]$sb.AppendLine('【對照】1)=題號註記 2)=對錯摘要 3)=診斷 4)=程度 5)=個別建議 6)=自學練習；練習題編號屬於第 6) 段，不是試卷多出的題。')
  [void]$sb.AppendLine('   a. 自學指導：短步驟／口訣／易錯提醒')
  [void]$sb.AppendLine('   b. 建議影片／學習連結：給 1～2 個；優先 https://www.youtube.com/results?search_query=編碼後關鍵詞 ；有把握才給具體影片 URL；禁止捏造網址')
  [void]$sb.AppendLine('   c. 練習題（先全部列出）')
  [void]$sb.AppendLine('   d. 解答（全部放在題目之後另段）')
  [void]$sb.AppendLine('   - 跟上：少鞏固、多靈活＋再提升挑戰；禁止只改數字。')
  [void]$sb.AppendLine('   - 略落後：對應錯題，少而精。')
  [void]$sb.AppendLine('   - 明顯落後／需補先備：多次補齊（每次 1 點、≤3 題），先有成就再漸次跟上。')
  [void]$sb.AppendLine('   - 待判定：先給「已確認錯題」對應的少量練習；存疑題等我認知後再補。')
  [void]$sb.AppendLine('不要要求學生另上均一完成任務；練習與指導由此直接產生。')
  [void]$sb.AppendLine('格式方便我貼回批改程式／存成 輸出\' + $id + '-註記.md')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('座號：' + $id)
  if ($id -notmatch '^\d{2}$') {
    [void]$sb.AppendLine('（注意：檔名未含清楚座號，請老師核對真實座號；目前暫用：' + $id + '）')
  }
  [void]$sb.AppendLine('學生試卷：' + $studentFile.FullName)
  [void]$sb.AppendLine('正確答案檔：')
  if ($ansFiles.Count -eq 0) {
    [void]$sb.AppendLine(' （無｜採直接 AI 批閱）')
  } else {
    foreach ($a in $ansFiles) { [void]$sb.AppendLine(' - ' + $a.FullName) }
  }
  return $sb.ToString()
}

# ----- UI -----
if ([string]::IsNullOrWhiteSpace($WorkDir)) { $WorkDir = Get-DefaultWorkDir }
Ensure-WorkTree $WorkDir
$script:WorkDir = $WorkDir
$script:settings = Load-Settings $WorkDir

$font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 12)
$fontBig = New-Object System.Drawing.Font('Microsoft JhengHei UI', 15, [System.Drawing.FontStyle]::Bold)

$form = New-Object System.Windows.Forms.Form
$form.Text = ("數學習作批改（Gemini 自動批｜對照答案或直接 AI｜一人一檔｜$($script:AppBuild)）")
$form.Size = New-Object System.Drawing.Size(1100, 900)
$form.StartPosition = 'CenterScreen'
$form.Font = $font
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 248, 244)

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = 'Gemini 自動批：有正確答案就對照；沒有就直接 AI 批（都自動處理）'
$lbl.Font = $fontBig
$lbl.ForeColor = [System.Drawing.Color]::FromArgb(20, 70, 50)
$lbl.Location = New-Object System.Drawing.Point(16, 10)
$lbl.Size = New-Object System.Drawing.Size(960, 28)

# --- 開始區：答案＋模式 ---
$grpStart = New-Object System.Windows.Forms.GroupBox
$grpStart.Text = '① 開始：正確答案（可選）與批閱方式'
$grpStart.Location = New-Object System.Drawing.Point(16, 42)
$grpStart.Size = New-Object System.Drawing.Size(950, 88)

$lblAns = New-Object System.Windows.Forms.Label
$lblAns.Location = New-Object System.Drawing.Point(12, 28)
$lblAns.Size = New-Object System.Drawing.Size(700, 22)
$grpStart.Controls.Add($lblAns)

$cmbMode = New-Object System.Windows.Forms.ComboBox
$cmbMode.DropDownStyle = 'DropDownList'
$cmbMode.Items.AddRange(@(
    '自己對照批（開啟答案＋學生卷）',
    '請 Cursor 直接批閱（複製提示並開檔）',
    '請 Cursor 手寫加強批閱（難辨／潦草）',
    '請 Gemini 自動批閱（API＝真正自動）',
    '請 Gemini 自動手寫加強（API）',
    '請 Gemini 網頁批閱（要手動貼，非自動）',
    '請 Gemini 網頁手寫加強（要手動貼）'
  ))
$cmbMode.Location = New-Object System.Drawing.Point(12, 52)
$cmbMode.Size = New-Object System.Drawing.Size(480, 28)
# 預設：Gemini API 自動批閱（最後用 Gemini）
if (-not $script:settings.mode) { $script:settings.mode = 'gemini_auto' }
switch ($script:settings.mode) {
  'gemini_auto_hw' { $cmbMode.SelectedIndex = 4 }
  'gemini_auto' { $cmbMode.SelectedIndex = 3 }
  'gemini_hw' { $cmbMode.SelectedIndex = 6 }
  'gemini' { $cmbMode.SelectedIndex = 5 }
  'cursor_hw' { $cmbMode.SelectedIndex = 2 }
  'cursor' { $cmbMode.SelectedIndex = 1 }
  'manual' { $cmbMode.SelectedIndex = 0 }
  default { $cmbMode.SelectedIndex = 3 }
}
$grpStart.Controls.Add($cmbMode)

function Refresh-AnswerLabel {
  $files = @(Get-AnswerFiles $script:WorkDir)
  if ($files.Count -eq 0) {
    $lblAns.Text = '正確答案：尚未載入（可選｜沒有也能「直接 AI 批」）'
    $lblAns.ForeColor = [System.Drawing.Color]::FromArgb(120, 80, 20)
  } else {
    $names = ($files | ForEach-Object { $_.Name }) -join '、'
    $lblAns.Text = "正確答案：已載入 $($files.Count) 個｜對照批｜$names"
    $lblAns.ForeColor = [System.Drawing.Color]::FromArgb(20, 70, 50)
  }
}

$btnLoadAns = New-Object System.Windows.Forms.Button
$btnLoadAns.Text = '載入正確答案'
$btnLoadAns.Location = New-Object System.Drawing.Point(500, 48)
$btnLoadAns.Size = New-Object System.Drawing.Size(110, 32)
$btnLoadAns.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Title = '選擇正確答案（可多選）'
    $ofd.Filter = '答案檔|*.pdf;*.png;*.jpg;*.jpeg;*.txt;*.md|所有檔|*.*'
    $ofd.Multiselect = $true
    if ($ofd.ShowDialog() -eq 'OK') {
      $dest = Join-Path $script:WorkDir '標準答案'
      foreach ($f in $ofd.FileNames) {
        Copy-Item -LiteralPath $f -Destination (Join-Path $dest ([IO.Path]::GetFileName($f))) -Force
      }
      Refresh-AnswerLabel
      $status.Text = '已載入正確答案，可開始一檔一檔批'
    }
  })
$grpStart.Controls.Add($btnLoadAns)

$btnGeminiKey = New-Object System.Windows.Forms.Button
$btnGeminiKey.Text = 'Gemini金鑰'
$btnGeminiKey.Location = New-Object System.Drawing.Point(620, 48)
$btnGeminiKey.Size = New-Object System.Drawing.Size(100, 32)
$btnGeminiKey.Add_Click({ [void](Show-GeminiKeyDialog) })
$grpStart.Controls.Add($btnGeminiKey)

$btnOpenAns = New-Object System.Windows.Forms.Button
$btnOpenAns.Text = '開啟答案'
$btnOpenAns.Location = New-Object System.Drawing.Point(730, 48)
$btnOpenAns.Size = New-Object System.Drawing.Size(90, 32)
$btnOpenAns.Add_Click({
    $files = @(Get-AnswerFiles $script:WorkDir)
    if ($files.Count -eq 0) {
      [void][System.Windows.Forms.MessageBox]::Show('尚未載入正確答案', '提示')
      return
    }
    foreach ($f in $files) { Start-Process -FilePath $f.FullName }
  })
$grpStart.Controls.Add($btnOpenAns)

$btnOpenAnsFolder = New-Object System.Windows.Forms.Button
$btnOpenAnsFolder.Text = '答案夾'
$btnOpenAnsFolder.Location = New-Object System.Drawing.Point(830, 48)
$btnOpenAnsFolder.Size = New-Object System.Drawing.Size(80, 32)
$btnOpenAnsFolder.Add_Click({ Start-Process explorer.exe (Join-Path $script:WorkDir '標準答案') })
$grpStart.Controls.Add($btnOpenAnsFolder)

$cmbMode.Add_SelectedIndexChanged({
    $mode = 'manual'
    switch ($cmbMode.SelectedIndex) {
      1 { $mode = 'cursor' }
      2 { $mode = 'cursor_hw' }
      3 { $mode = 'gemini_auto' }
      4 { $mode = 'gemini_auto_hw' }
      5 { $mode = 'gemini' }
      6 { $mode = 'gemini_hw' }
    }
    $script:settings | Add-Member -NotePropertyName mode -NotePropertyValue $mode -Force
    Save-Settings $script:WorkDir $script:settings
  })

$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Location = New-Object System.Drawing.Point(16, 136)
$lblPath.Size = New-Object System.Drawing.Size(960, 22)

$list = New-Object System.Windows.Forms.ListBox
$list.Location = New-Object System.Drawing.Point(16, 164)
$list.Size = New-Object System.Drawing.Size(300, 400)
$list.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 13)

$grp = New-Object System.Windows.Forms.GroupBox
$grp.Text = '② 目前學生註記'
$grp.Location = New-Object System.Drawing.Point(336, 164)
$grp.Size = New-Object System.Drawing.Size(720, 400)

function Add-L([int]$y, [string]$t) {
  $l = New-Object System.Windows.Forms.Label
  $l.Text = $t
  $l.Location = New-Object System.Drawing.Point(16, $y)
  $l.Size = New-Object System.Drawing.Size(100, 28)
  $grp.Controls.Add($l)
}

Add-L 24 '總評'
$cmbOverall = New-Object System.Windows.Forms.ComboBox
$cmbOverall.DropDownStyle = 'DropDownList'
$cmbOverall.Items.AddRange(@('未批', '大致正確', '部分錯誤', '需補救', '存疑多'))
$cmbOverall.SelectedIndex = 0
$cmbOverall.Location = New-Object System.Drawing.Point(120, 24)
$cmbOverall.Size = New-Object System.Drawing.Size(150, 28)
$grp.Controls.Add($cmbOverall)

$lbLevel = New-Object System.Windows.Forms.Label
$lbLevel.Text = '程度'
$lbLevel.Location = New-Object System.Drawing.Point(280, 24)
$lbLevel.Size = New-Object System.Drawing.Size(50, 28)
$grp.Controls.Add($lbLevel)
$cmbLevel = New-Object System.Windows.Forms.ComboBox
$cmbLevel.DropDownStyle = 'DropDownList'
$cmbLevel.Items.AddRange(@('待判定', '跟上', '略落後', '明顯落後', '需補先備'))
$cmbLevel.SelectedIndex = 0
$cmbLevel.Location = New-Object System.Drawing.Point(330, 24)
$cmbLevel.Size = New-Object System.Drawing.Size(140, 28)
$grp.Controls.Add($cmbLevel)

$btnFillPractice = New-Object System.Windows.Forms.Button
$btnFillPractice.Text = '依程度給練習'
$btnFillPractice.Location = New-Object System.Drawing.Point(480, 22)
$btnFillPractice.Size = New-Object System.Drawing.Size(130, 30)
$btnFillPractice.Add_Click({
    $txtPractice.Text = Get-PracticeTemplate ([string]$cmbLevel.SelectedItem)
  })
$grp.Controls.Add($btnFillPractice)
$cmbLevel.Add_SelectedIndexChanged({
    if ($script:SuppressPracticeAutoFill) { return }
    # 換程度時自動帶入對應練習架構（跟上＝再提升；落後＝補救）
    $lv = [string]$cmbLevel.SelectedItem
    if ($lv -and $lv -ne '待判定') {
      $txtPractice.Text = Get-PracticeTemplate $lv
    }
  })

Add-L 58 '題號註記'
$txtItems = New-Object System.Windows.Forms.TextBox
$txtItems.Multiline = $true
$txtItems.ScrollBars = 'Vertical'
$txtItems.Location = New-Object System.Drawing.Point(120, 58)
$txtItems.Size = New-Object System.Drawing.Size(580, 52)
$txtItems.Text = '（尚無題號註記｜依試卷實際題數填）'
$grp.Controls.Add($txtItems)

Add-L 116 '對錯摘要'
$txtSummary = New-Object System.Windows.Forms.TextBox
$txtSummary.Multiline = $true
$txtSummary.ScrollBars = 'Vertical'
$txtSummary.Location = New-Object System.Drawing.Point(120, 116)
$txtSummary.Size = New-Object System.Drawing.Size(580, 44)
$grp.Controls.Add($txtSummary)

Add-L 166 '診斷結果'
$txtDiagnosis = New-Object System.Windows.Forms.TextBox
$txtDiagnosis.Multiline = $true
$txtDiagnosis.ScrollBars = 'Vertical'
$txtDiagnosis.Location = New-Object System.Drawing.Point(120, 166)
$txtDiagnosis.Size = New-Object System.Drawing.Size(580, 72)
$txtDiagnosis.Text = "弱點：`r`n是否跟上："
$grp.Controls.Add($txtDiagnosis)

Add-L 244 '個別建議'
$txtAdvice = New-Object System.Windows.Forms.TextBox
$txtAdvice.Multiline = $true
$txtAdvice.ScrollBars = 'Vertical'
$txtAdvice.Location = New-Object System.Drawing.Point(120, 244)
$txtAdvice.Size = New-Object System.Drawing.Size(580, 44)
$grp.Controls.Add($txtAdvice)

Add-L 294 '自學練習'
$txtPractice = New-Object System.Windows.Forms.TextBox
$txtPractice.Multiline = $true
$txtPractice.ScrollBars = 'Vertical'
$txtPractice.Location = New-Object System.Drawing.Point(120, 294)
$txtPractice.Size = New-Object System.Drawing.Size(580, 90)
$txtPractice.Text = '（先寫全部練習題；解答另段「解答」，做完再看）'
$grp.Controls.Add($txtPractice)

$status = New-Object System.Windows.Forms.Label
$status.Location = New-Object System.Drawing.Point(16, 760)
$status.Size = New-Object System.Drawing.Size(1040, 40)
$status.Text = '可載入正確答案（對照批）或直接按 Gemini 自動批（預設）'

$script:files = @()
$script:current = $null
# 連續自動批：成功後不跳確認窗，直接下一位
$script:SilentAutoContinue = $false
$script:AutoBatchDone = 0

function Refresh-PathLabel {
  $lblPath.Text = '工作資料夾：' + $script:WorkDir + '　　（輸入＝學生卷｜輸出＝註記PDF）'
}

function Ensure-AnswerOrWarn {
  param(
    # 自動批：答案可選；只提示是否要載入，選「否」仍可直接 AI 批
    [switch]$OfferForAuto
  )
  $files = @(Get-AnswerFiles $script:WorkDir)
  if ($files.Count -eq 0) {
    if ($OfferForAuto) {
      # 連續／靜默模式不打斷：直接 AI 批
      if ($script:SilentAutoContinue) { return $true }
      $ask = [System.Windows.Forms.MessageBox]::Show(
        "尚未載入正確答案。`n`n「是」＝現在載入（對照批）`n「否」＝直接用 Gemini AI 批（無答案檔）",
        '對照答案 或 直接 AI 批',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
      )
      if ($ask -ne 'Yes') { return $true }
      $ofd = New-Object System.Windows.Forms.OpenFileDialog
      $ofd.Title = '選擇正確答案（可多選）'
      $ofd.Filter = '答案檔|*.pdf;*.png;*.jpg;*.jpeg;*.txt;*.md|所有檔|*.*'
      $ofd.Multiselect = $true
      if ($ofd.ShowDialog() -ne 'OK') { return $true }
      $dest = Join-Path $script:WorkDir '標準答案'
      New-Item -ItemType Directory -Force -Path $dest | Out-Null
      foreach ($f in $ofd.FileNames) {
        Copy-Item -LiteralPath $f -Destination (Join-Path $dest ([IO.Path]::GetFileName($f))) -Force
      }
      Refresh-AnswerLabel
      return $true
    }
    $r = [System.Windows.Forms.MessageBox]::Show(
      "尚未載入正確答案。`n建議先載入以便比對；沒有也可繼續（自行對照／AI 直接批）。`n仍要繼續嗎？",
      '正確答案（可選）',
      [System.Windows.Forms.MessageBoxButtons]::YesNo,
      [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    return ($r -eq 'Yes')
  }
  return $true
}

function Refresh-List {
  $list.Items.Clear()
  $script:files = @(Get-InputFiles $script:WorkDir)
  foreach ($f in $script:files) {
    $id = Get-StudentId $f.Name
    $note = Get-NotePath $script:WorkDir $id
    $mark = if (Test-Path -LiteralPath $note) { '〔已有註記〕' } else { '〔未批〕' }
    [void]$list.Items.Add("$id  $($f.Name)  $mark")
  }
  $inDir = Join-Path $script:WorkDir '輸入'
  $skipped = @(Get-InputSkipped $script:WorkDir)
  $allCount = @(Get-ChildItem -LiteralPath $inDir -File -ErrorAction SilentlyContinue).Count
  if ($script:files.Count -eq 0 -and $allCount -gt 0) {
    $names = ($skipped | Select-Object -First 5 | ForEach-Object { $_.Name }) -join '、'
    $status.Text = ("輸入夾有 {0} 個檔，但副檔名不支援（需 pdf/png/jpg/heic…）。例：{1}" -f $allCount, $names)
    [void][System.Windows.Forms.MessageBox]::Show(
      ("「輸入」夾目前有 {0} 個檔，但程式認不到。`n`n請用：PDF、PNG、JPG、HEIC、WEBP。`n若是 Word／Pages／壓縮檔，請先匯出成 PDF 再放入。`n`n資料夾：`n{1}" -f $allCount, $inDir),
      '輸入檔未列入清單'
    )
  } elseif ($script:files.Count -eq 0) {
    $status.Text = ('輸入 0 人｜請把學生卷放入：' + $inDir)
  } else {
    $extra = if ($skipped.Count -gt 0) { "｜另有 $($skipped.Count) 個不支援副檔名未列入" } else { '' }
    $status.Text = ('輸入 {0} 人{1}｜{2}' -f $script:files.Count, $extra, $script:WorkDir)
  }
}

function Load-Selected {
  if ($list.SelectedIndex -lt 0) { return }
  $f = $script:files[$list.SelectedIndex]
  $script:current = $f
  $id = Get-StudentId $f.Name
  $n = Load-Note (Get-NotePath $script:WorkDir $id)
  $script:SuppressPracticeAutoFill = $true
  try {
    if ($n.overall -and $cmbOverall.Items.Contains($n.overall)) {
      $cmbOverall.SelectedItem = $n.overall
    } else { $cmbOverall.SelectedIndex = 0 }
    if ($n.level -and $cmbLevel.Items.Contains($n.level)) {
      $cmbLevel.SelectedItem = $n.level
    } else { $cmbLevel.SelectedIndex = 0 }
    $txtItems.Text = $(if ($n.itemsText) { $n.itemsText } else { '（尚無題號註記｜依試卷實際題數填）' })
    $txtSummary.Text = [string]$n.summary
    $txtDiagnosis.Text = $(if ($n.diagnosis) { [string]$n.diagnosis } else { "弱點：`r`n是否跟上：" })
    $txtAdvice.Text = [string]$n.advice
    $txtPractice.Text = $(if ($n.practice) { [string]$n.practice } else { '（題目＋解答；可按「依程度帶入練習架構」）' })
  } finally {
    $script:SuppressPracticeAutoFill = $false
  }

  # 若建議／練習空白，但已有 Gemini回覆.md，自動重填各欄
  $needAdvice = [string]::IsNullOrWhiteSpace($txtAdvice.Text) -or $txtAdvice.Text -match '^\s*（|給學生'
  $needPractice = [string]::IsNullOrWhiteSpace($txtPractice.Text) -or $txtPractice.Text -match '^\s*（|依程度帶入|先寫全部練習'
  $replyPath = Join-Path (Join-Path $script:WorkDir '輸出') ($id + '-Gemini回覆.md')
  if (($needAdvice -or $needPractice) -and (Test-Path -LiteralPath $replyPath)) {
    try {
      $reply = Get-Content -LiteralPath $replyPath -Encoding UTF8 -Raw
      if (-not [string]::IsNullOrWhiteSpace($reply)) {
        Apply-GeminiReplyToForm $reply
        $status.Text = '目前：座號 ' + $id + '｜' + $f.Name + '｜已從 Gemini回覆重填建議／練習'
        return
      }
    } catch {}
  }
  $status.Text = '目前：座號 ' + $id + '｜' + $f.Name
}

$list.Add_SelectedIndexChanged({ Load-Selected })

function Start-GradeCurrent {
  if (-not $script:current) {
    [void][System.Windows.Forms.MessageBox]::Show('請先選左側一位學生', '提示')
    return
  }
  # Gemini 自動批：答案可選；其他模式仍提醒
  $preIdx = $cmbMode.SelectedIndex
  $willGeminiAuto = ($preIdx -eq 3 -or $preIdx -eq 4)
  if ($willGeminiAuto) {
    if (-not (Ensure-AnswerOrWarn -OfferForAuto)) { return }
  } else {
    if (-not (Ensure-AnswerOrWarn)) { return }
  }

  $id = Get-StudentId $script:current.Name
  if ($id -notmatch '^\d{1,2}$' -or $script:current.Name -match '^S__') {
    $ask = [System.Windows.Forms.MessageBox]::Show(
      ("目前檔名像是通訊軟體亂碼（$($script:current.Name)），座號讀成「$id」，容易批不出來。`n`n要先改成座號檔名嗎？`n試發請用 00（例如 00.jpg）`n選「是」會請你輸入座號並改名。"),
      '請先改座號檔名',
      [System.Windows.Forms.MessageBoxButtons]::YesNo,
      [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($ask -eq 'Yes') {
      $formAsk = New-Object System.Windows.Forms.Form
      $formAsk.Text = '輸入座號（試發用 00）'
      $formAsk.Size = New-Object System.Drawing.Size(320, 140)
      $formAsk.StartPosition = 'CenterParent'
      $tb = New-Object System.Windows.Forms.TextBox
      $tb.Location = New-Object System.Drawing.Point(20, 20)
      $tb.Width = 260
      $tb.Text = '00'
      $formAsk.Controls.Add($tb)
      $ok = New-Object System.Windows.Forms.Button
      $ok.Text = '確定'
      $ok.Location = New-Object System.Drawing.Point(110, 60)
      $ok.DialogResult = 'OK'
      $formAsk.Controls.Add($ok)
      $formAsk.AcceptButton = $ok
      $dr = $formAsk.ShowDialog()
      $input = if ($dr -eq 'OK') { $tb.Text.Trim() } else { '' }
      if ($input -match '^\d{1,2}$') {
        $newId = $input.PadLeft(2, '0')
        $ext = $script:current.Extension
        $dest = Join-Path $script:current.DirectoryName ($newId + $ext)
        if (Test-Path -LiteralPath $dest) {
          [void][System.Windows.Forms.MessageBox]::Show("已存在 $newId$ext，請先換名或刪除舊檔。", '無法改名')
          return
        }
        Rename-Item -LiteralPath $script:current.FullName -NewName ($newId + $ext)
        Refresh-List
        $idx = 0
        foreach ($f in $script:files) {
          if ($f.Name -eq ($newId + $ext)) { $list.SelectedIndex = $idx; break }
          $idx++
        }
        if (-not $script:current) { return }
      } else {
        return
      }
    }
  }

  if ($cmbMode.SelectedIndex -ge 1) {
    # 1–2 Cursor 手動｜3–4 Gemini API 自動｜5–6 Gemini 網頁手動
    $idx = $cmbMode.SelectedIndex
    $useGeminiAuto = ($idx -eq 3 -or $idx -eq 4)
    $useGeminiWeb = ($idx -eq 5 -or $idx -eq 6)
    $useGemini = ($useGeminiAuto -or $useGeminiWeb)
    $hw = ($idx -eq 2 -or $idx -eq 4 -or $idx -eq 6)

    if (-not $hw -and -not $useGeminiAuto) {
      $sug = [System.Windows.Forms.MessageBox]::Show(
        "若剛剛批不出來／字跡很差，建議改用「手寫加強批閱」。`n`n現在改用加強模式嗎？",
        '批閱模式',
        [System.Windows.Forms.MessageBoxButtons]::YesNo
      )
      if ($sug -eq 'Yes') {
        if ($useGeminiWeb) { $cmbMode.SelectedIndex = 6 }
        else { $cmbMode.SelectedIndex = 2 }
        $hw = $true
        $idx = $cmbMode.SelectedIndex
      }
    }

    $ansList = @(Get-AnswerFiles $script:WorkDir)
    $hasAns = ($ansList.Count -gt 0)
    $p = Build-CursorPromptOne $script:WorkDir $script:current -HandwritingHard:$hw
    if ($useGemini) {
      if ($hasAns) {
        $p = ("【任務】你是數學老師助理，用 Google Gemini 自動批閱。`r`n" +
          "【模式】對照正確答案`r`n" +
          "【已附檔】1) 學生試卷 2) 正確答案（可能多檔）。`r`n" +
          "【必做】先看正確答案，再對學生卷逐題判 ✓／✗／?；以答案為準，等價解法可給 ✓。`r`n" +
          "【題數】只批答案／試卷上實際有的題；禁止多寫不存在的題號。`r`n" +
          "【欄位】1)題號註記 2)對錯摘要 3)診斷 4)程度 5)建議 6)練習；內容禁止互相塞錯。`r`n" +
          "【禁止】不要要我再貼檔；不要忽略正確答案自行出標準。`r`n" +
          (Get-TextbookMathPromptRule) + "`r`n`r`n") + $p
      } else {
        $p = ("【任務】你是數學老師助理，用 Google Gemini 自動批閱。`r`n" +
          "【模式】直接 AI 批閱（未附正確答案檔）`r`n" +
          "【已附檔】學生試卷。`r`n" +
          "【必做】依題意與數學正確性逐題判 ✓／✗／?；等價解法可給 ✓；看不清標 ?。`r`n" +
          "【題數】只批試卷上實際有的題；禁止多寫不存在的題號。`r`n" +
          "【欄位】1)題號註記 2)對錯摘要 3)診斷 4)程度 5)建議 6)練習；內容禁止互相塞錯。`r`n" +
          "【禁止】不要要我再貼檔。`r`n" +
          (Get-TextbookMathPromptRule) + "`r`n`r`n") + $p
      }
    }

    if ($useGeminiAuto) {
      $key = Get-GeminiApiKey $script:WorkDir
      if ([string]::IsNullOrWhiteSpace($key)) {
        $ask = [System.Windows.Forms.MessageBox]::Show(
          "自動批閱需要 Gemini API 金鑰（與網頁 Pro 訂閱分開，到 AI Studio 免費申請）。`n`n現在設定嗎？",
          '需要 Gemini 金鑰',
          [System.Windows.Forms.MessageBoxButtons]::YesNo
        )
        if ($ask -ne 'Yes') { $script:SilentAutoContinue = $false; $script:AutoBatchDone = 0; return }
        if (-not (Show-GeminiKeyDialog)) { $script:SilentAutoContinue = $false; $script:AutoBatchDone = 0; return }
        $key = Get-GeminiApiKey $script:WorkDir
        if ([string]::IsNullOrWhiteSpace($key)) { $script:SilentAutoContinue = $false; $script:AutoBatchDone = 0; return }
      }

      $sid = Get-StudentId $script:current.Name
      $files = New-Object System.Collections.ArrayList
      [void]$files.Add($script:current.FullName)
      # 有正確答案就全部附上；沒有就純 AI 直接批
      foreach ($a in $ansList) {
        [void]$files.Add($a.FullName)
      }

      $modeLabel = if ($hasAns) { "對照答案 $($ansList.Count) 檔" } else { '直接 AI 批' }
      $status.Text = "Gemini 自動批閱中（座號 $sid｜$modeLabel）…"
      $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
      [System.Windows.Forms.Application]::DoEvents()
      try {
        $model = 'gemini-3.5-flash'
        try {
          if ($script:settings.geminiModel) {
            $cand = [string]$script:settings.geminiModel
            if ($cand -and $cand -notmatch 'gemini-2\.0|gemini-1\.5|gemini-1\.0') { $model = $cand }
          }
        } catch {}
        $result = Invoke-GeminiGenerateContent -ApiKey $key -Model $model -Prompt $p -FilePaths @($files.ToArray())
        $text = Convert-ToTextbookMath (Convert-ToWinFormsText ([string]$result.Text))
        Apply-GeminiReplyToForm $text
        $outDir = Join-Path $script:WorkDir '輸出'
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        $utf8 = New-Object System.Text.UTF8Encoding $true
        [IO.File]::WriteAllText((Join-Path $outDir ($sid + '-Gemini提示.txt')), $p, $utf8)
        [IO.File]::WriteAllText((Join-Path $outDir ($sid + '-Gemini回覆.md')), $text, $utf8)
        # 自動寫入註記並嘗試產 PDF（老師仍可再改）
        $saved = $false
        try { $saved = [bool](Save-Current) } catch { $saved = $false }
        if ($script:SilentAutoContinue) { $script:AutoBatchDone++ }
        $status.Text = "Gemini 已自動批完（$($result.Model)）｜$modeLabel｜座號 $sid｜註記已寫入"
        $extra = if ($saved) { "`n已自動輸出此生 PDF／註記。" } else { "`n請再按「輸出此生PDF」確認。" }

        if ($script:SilentAutoContinue) {
          # 連續模式：不跳確認，直接下一位未批
          $form.Cursor = [System.Windows.Forms.Cursors]::Default
          Select-NextUngraded -Quiet
          if ($script:current) {
            Start-GradeCurrent
          } else {
            $n = $script:AutoBatchDone
            $script:SilentAutoContinue = $false
            $script:AutoBatchDone = 0
            $status.Text = "連續自動批完成｜共 $n 份（Gemini）"
            [void][System.Windows.Forms.MessageBox]::Show(
              ("連續自動批完成。`n已用 Gemini 自動處理 $n 份。`n`n請抽查「輸出」夾的註記／PDF。"),
              '連續自動批完成'
            )
          }
        } else {
          $ansHint = if ($hasAns) { "答案檔：$($ansList.Count) 個｜對照批" } else { '模式：直接 AI 批（無答案檔）' }
          $next = [System.Windows.Forms.MessageBox]::Show(
            ("已自動批完座號 $sid（模型：$($result.Model)）。`n$ansHint`n回覆：輸出\$sid-Gemini回覆.md" + $extra + "`n`n要繼續自動批「下一位未批」嗎？"),
            'Gemini 自動批閱',
            [System.Windows.Forms.MessageBoxButtons]::YesNo
          )
          if ($next -eq 'Yes') {
            Select-NextUngraded -Quiet
            if ($script:current) { Start-GradeCurrent }
          }
        }
      } catch {
        $script:SilentAutoContinue = $false
        $script:AutoBatchDone = 0
        $status.Text = 'Gemini 自動批閱失敗'
        [void][System.Windows.Forms.MessageBox]::Show(
          ("自動批閱失敗：`n" + $_.Exception.Message + "`n`n請確認：Gemini 金鑰有效、網路正常。`n若是 503，等 1～2 分鐘再按一次「Gemini自動批」。"),
          '錯誤'
        )
      } finally {
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
      }
      return
    }

    [System.Windows.Forms.Clipboard]::SetText($p)
    try {
      $sid = Get-StudentId $script:current.Name
      $tag = if ($useGemini) { 'Gemini提示' } else { 'Cursor提示' }
      $promptPath = Join-Path (Join-Path $script:WorkDir '輸出') ($sid + '-' + $tag + '.txt')
      $utf8 = New-Object System.Text.UTF8Encoding $true
      [System.IO.File]::WriteAllText($promptPath, $p, $utf8)
    } catch {}
    Start-Process -FilePath $script:current.FullName
    $ans = @(Get-AnswerFiles $script:WorkDir)
    foreach ($a in $ans) { Start-Process -FilePath $a.FullName }
    if ($useGeminiWeb) {
      try { Start-Process 'https://gemini.google.com/app' } catch {}
      $toolName = 'Gemini'
      $step1 = "1. 已開啟 Gemini 網頁（若沒開請到 https://gemini.google.com/app）"
      $fileHint = "輸出\{座號}-Gemini提示.txt"
    } else {
      $toolName = 'Cursor'
      $step1 = '1. 開 Cursor 對話'
      $fileHint = "輸出\{座號}-Cursor提示.txt"
    }
    if ($hw) {
      $status.Text = "已複製「手寫加強」提示｜請到 ${toolName}：貼上＋附上學生卷圖檔"
      [void][System.Windows.Forms.MessageBox]::Show(
        ("【一定要做這 3 步，否則會批不出來】`n`n" + $step1 + "`n2. Ctrl+V 貼上提示（已在剪貼簿）`n3. 再把學生卷圖／PDF「附檔／上傳」加進去後送出`n`n只貼文字不附圖＝無法辨識手寫。`n`n提示也已存到 " + $fileHint + "`n`n想免手動貼檔：選「Gemini 自動批閱」並設定 API 金鑰。"),
        ("手寫加強批閱（$toolName）")
      )
    } else {
      $status.Text = "已複製 $toolName 提示｜請到 ${toolName}：貼上＋附檔"
      [void][System.Windows.Forms.MessageBox]::Show(
        ("【一定要做這 3 步】`n`n" + $step1 + "`n2. 貼上提示（Ctrl+V）`n3. 附上學生卷檔後送出`n`n想免手動貼檔：選「Gemini 自動批閱（API）」並按「Gemini金鑰」。"),
        ("請 $toolName 批閱")
      )
    }
  } else {
    # 自己對照
    Start-Process -FilePath $script:current.FullName
    $ans = @(Get-AnswerFiles $script:WorkDir)
    foreach ($a in $ans) { Start-Process -FilePath $a.FullName }
    $status.Text = '已開啟答案＋此生試卷，請對照後填註記'
  }
}

function Save-Current {
  if (-not $script:current) {
    [void][System.Windows.Forms.MessageBox]::Show('請先選左側一位學生', '提示')
    return $null
  }
  $id = Get-StudentId $script:current.Name
  $path = Save-Note -Root $script:WorkDir -StudentId $id -SourceFile $script:current.Name `
    -Overall ([string]$cmbOverall.SelectedItem) -Level ([string]$cmbLevel.SelectedItem) `
    -ItemsText $txtItems.Text -Summary $txtSummary.Text `
    -Diagnosis $txtDiagnosis.Text -Advice $txtAdvice.Text -Practice $txtPractice.Text
  [void](Invoke-MakePdf -Root $script:WorkDir -Student $id -MergeOriginal)
  Refresh-List
  for ($i = 0; $i -lt $list.Items.Count; $i++) {
    if ($list.Items[$i].ToString().StartsWith($id + ' ')) { $list.SelectedIndex = $i; break }
  }
  $pdf1 = Join-Path (Join-Path $script:WorkDir '輸出') ($id + '-批閱註記.pdf')
  $dig = Join-Path (Join-Path $script:WorkDir '數位練習') ($id + '-練習題.html')
  $status.Text = "已輸出：$path ｜ PDF：$pdf1 ｜ 數位練習：$dig"
  return $path
}

function Select-NextUngraded {
  param([switch]$Quiet)
  Refresh-List
  for ($i = 0; $i -lt $script:files.Count; $i++) {
    $id = Get-StudentId $script:files[$i].Name
    $note = Get-NotePath $script:WorkDir $id
    if (-not (Test-Path -LiteralPath $note)) {
      $list.SelectedIndex = $i
      Load-Selected
      $status.Text = "下一位未批：座號 $id"
      return $true
    }
  }
  $script:current = $null
  if (-not $Quiet) {
    [void][System.Windows.Forms.MessageBox]::Show("全員都有註記了。`n可按「產生全班存疑清單」處理看不懂的地方。", '完成')
  }
  return $false
}

$y1 = 580
$btnWork = New-Object System.Windows.Forms.Button
$btnWork.Text = '選工作資料夾'
$btnWork.Location = New-Object System.Drawing.Point(16, $y1)
$btnWork.Size = New-Object System.Drawing.Size(130, 36)
$btnWork.Add_Click({
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.SelectedPath = $script:WorkDir
    if ($d.ShowDialog() -eq 'OK') {
      $script:WorkDir = $d.SelectedPath
      Ensure-WorkTree $script:WorkDir
      $script:settings = Load-Settings $script:WorkDir
      switch ($script:settings.mode) {
        'gemini_auto_hw' { $cmbMode.SelectedIndex = 4 }
        'gemini_auto' { $cmbMode.SelectedIndex = 3 }
        'gemini_hw' { $cmbMode.SelectedIndex = 6 }
        'gemini' { $cmbMode.SelectedIndex = 5 }
        'cursor_hw' { $cmbMode.SelectedIndex = 2 }
        'cursor' { $cmbMode.SelectedIndex = 1 }
        default { $cmbMode.SelectedIndex = 0 }
      }
      Refresh-PathLabel
      Refresh-AnswerLabel
      Refresh-List
    }
  })

$btnOpenIn = New-Object System.Windows.Forms.Button
$btnOpenIn.Text = '輸入夾'
$btnOpenIn.Location = New-Object System.Drawing.Point(156, $y1)
$btnOpenIn.Size = New-Object System.Drawing.Size(90, 36)
$btnOpenIn.Add_Click({
  $inDir = Join-Path $script:WorkDir '輸入'
  New-Item -ItemType Directory -Force -Path $inDir | Out-Null
  Start-Process explorer.exe $inDir
  Start-Sleep -Milliseconds 500
  Refresh-List
})

$btnOpenOut = New-Object System.Windows.Forms.Button
$btnOpenOut.Text = '輸出夾'
$btnOpenOut.Location = New-Object System.Drawing.Point(256, $y1)
$btnOpenOut.Size = New-Object System.Drawing.Size(90, 36)
$btnOpenOut.Add_Click({ Start-Process explorer.exe (Join-Path $script:WorkDir '輸出') })

$btnGrade = New-Object System.Windows.Forms.Button
$btnGrade.Text = 'Gemini自動批'
$btnGrade.Location = New-Object System.Drawing.Point(356, $y1)
$btnGrade.Size = New-Object System.Drawing.Size(120, 36)
$btnGrade.BackColor = [System.Drawing.Color]::FromArgb(40, 90, 140)
$btnGrade.ForeColor = [System.Drawing.Color]::White
$btnGrade.FlatStyle = 'Flat'
$btnGrade.Add_Click({
  # 一鍵：強制 Gemini API 自動（有答案對照／無答案直接 AI）
  if ($cmbMode.SelectedIndex -lt 3 -or $cmbMode.SelectedIndex -gt 4) {
    $cmbMode.SelectedIndex = 3
  }
  Start-GradeCurrent
})

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = '輸出此生PDF'
$btnSave.Location = New-Object System.Drawing.Point(486, $y1)
$btnSave.Size = New-Object System.Drawing.Size(130, 36)
$btnSave.BackColor = [System.Drawing.Color]::FromArgb(30, 100, 70)
$btnSave.ForeColor = [System.Drawing.Color]::White
$btnSave.FlatStyle = 'Flat'
$btnSave.Add_Click({ [void](Save-Current) })

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Text = '下一位未批'
$btnNext.Location = New-Object System.Drawing.Point(626, $y1)
$btnNext.Size = New-Object System.Drawing.Size(100, 36)
$btnNext.Add_Click({ Select-NextUngraded })

$btnAutoAll = New-Object System.Windows.Forms.Button
$btnAutoAll.Text = '連續自動批'
$btnAutoAll.Location = New-Object System.Drawing.Point(736, $y1)
$btnAutoAll.Size = New-Object System.Drawing.Size(110, 36)
$btnAutoAll.BackColor = [System.Drawing.Color]::FromArgb(45, 106, 79)
$btnAutoAll.ForeColor = [System.Drawing.Color]::White
$btnAutoAll.FlatStyle = 'Flat'
$btnAutoAll.Add_Click({
  # Gemini API 連續自動批：有答案就對照，沒有就直接 AI
  $cmbMode.SelectedIndex = 3
  [void](Ensure-AnswerOrWarn -OfferForAuto)
  $key = Get-GeminiApiKey $script:WorkDir
  if ([string]::IsNullOrWhiteSpace($key)) {
    $askKey = [System.Windows.Forms.MessageBox]::Show(
      "連續自動批需要 Gemini API 金鑰。`n`n現在設定嗎？",
      '需要 Gemini 金鑰',
      [System.Windows.Forms.MessageBoxButtons]::YesNo
    )
    if ($askKey -ne 'Yes') { return }
    if (-not (Show-GeminiKeyDialog)) { return }
  }
  # 若目前這份已有註記，跳到下一位未批
  if ($script:current) {
    $curId = Get-StudentId $script:current.Name
    $curNote = Get-NotePath $script:WorkDir $curId
    if (Test-Path -LiteralPath $curNote) { [void](Select-NextUngraded -Quiet) }
  } else {
    [void](Select-NextUngraded -Quiet)
  }
  if (-not $script:current) {
    [void][System.Windows.Forms.MessageBox]::Show('沒有未批學生（請把試卷放入「輸入」夾）。', '提示')
    return
  }
  $ansN = @(Get-AnswerFiles $script:WorkDir).Count
  $modeHint = if ($ansN -gt 0) { "有正確答案 $ansN 檔 → 對照批" } else { '無正確答案 → 直接 AI 批' }
  $confirm = [System.Windows.Forms.MessageBox]::Show(
    ("將用 Gemini 連續自動批所有未批學生。`n$modeHint`n`n每份成功會自動存註記／PDF，再處理下一位。`n中途失敗會停下。`n`n開始？"),
    '連續自動批',
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
  )
  if ($confirm -ne 'Yes') { return }
  $script:SilentAutoContinue = $true
  $script:AutoBatchDone = 0
  $status.Text = "連續自動批開始｜Gemini｜$modeHint"
  Start-GradeCurrent
})

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = '重新整理'
$btnRefresh.Location = New-Object System.Drawing.Point(856, $y1)
$btnRefresh.Size = New-Object System.Drawing.Size(90, 36)
$btnRefresh.Add_Click({ Refresh-List; Refresh-AnswerLabel })

$y2 = 626
$btnCsv = New-Object System.Windows.Forms.Button
$btnCsv.Text = '全班學習總表'
$btnCsv.Location = New-Object System.Drawing.Point(16, $y2)
$btnCsv.Size = New-Object System.Drawing.Size(130, 28)
$btnCsv.BackColor = [System.Drawing.Color]::FromArgb(120, 70, 20)
$btnCsv.ForeColor = [System.Drawing.Color]::White
$btnCsv.FlatStyle = 'Flat'
$btnCsv.Add_Click({
    $csv = Export-ClassCsv $script:WorkDir
    if (Invoke-MakePdf -Root $script:WorkDir -ClassReport) {
      $rep = Join-Path (Join-Path $script:WorkDir '輸出') '全班學習狀況總表.pdf'
      $status.Text = "已產出導師／家長用總表：$rep ｜ $csv"
      if (Test-Path -LiteralPath $rep) { Start-Process -FilePath $rep }
      [void][System.Windows.Forms.MessageBox]::Show(
        "已產出全班學習狀況總表（導師／家長用）：`n$rep`n`n另有 .md / .csv。`n建議在全班逐一經 Cursor＋老師確認後再產。",
        '全班總表'
      )
    } else {
      $status.Text = '已匯出簡易 CSV：' + $csv
    }
  })

$btnSyncDesk = New-Object System.Windows.Forms.Button
$btnSyncDesk.Text = '同步程度→習作台'
$btnSyncDesk.Location = New-Object System.Drawing.Point(156, $y2)
$btnSyncDesk.Size = New-Object System.Drawing.Size(140, 28)
$btnSyncDesk.BackColor = [System.Drawing.Color]::FromArgb(45, 106, 79)
$btnSyncDesk.ForeColor = [System.Drawing.Color]::White
$btnSyncDesk.FlatStyle = 'Flat'
$btnSyncDesk.Add_Click({
    try {
      $r = Export-LevelsToTeacherDesk $script:WorkDir
      $status.Text = "已同步 $($r.Count) 個程度 → $($r.Path)"
      [void][System.Windows.Forms.MessageBox]::Show(
        ("已把註記程度寫入習作台班級狀態。`n更新 {0} 座`n`n{1}`n`n請打開桌面「習作台」查看；也可把匯出檔傳到另一台／手機。" -f $r.Count, $r.Path),
        '同步習作台'
      )
    } catch {
      [void][System.Windows.Forms.MessageBox]::Show("同步失敗：$($_.Exception.Message)", '同步習作台')
    }
  })

$btnExportProgress = New-Object System.Windows.Forms.Button
$btnExportProgress.Text = '匯出批改進度JSON'
$btnExportProgress.Location = New-Object System.Drawing.Point(306, $y2)
$btnExportProgress.Size = New-Object System.Drawing.Size(150, 28)
$btnExportProgress.Add_Click({
    try {
      $p = Export-GraderProgressJson $script:WorkDir
      $status.Text = '已匯出：' + $p
      Start-Process explorer.exe "/select,`"$p`""
      [void][System.Windows.Forms.MessageBox]::Show(
        "已匯出含 0803 練習歷程的批改進度：`n$p`n`n傳到另一端「匯入批改進度」或併入「0803同步包」。",
        '匯出批改進度'
      )
    } catch {
      [void][System.Windows.Forms.MessageBox]::Show("匯出失敗：$($_.Exception.Message)", '匯出批改進度')
    }
  })

$btnUnclear = New-Object System.Windows.Forms.Button
$btnUnclear.Text = '產生全班存疑清單'
$btnUnclear.Location = New-Object System.Drawing.Point(466, $y2)
$btnUnclear.Size = New-Object System.Drawing.Size(160, 28)
$btnUnclear.Add_Click({
    if (Invoke-MakePdf -Root $script:WorkDir -UnclearList) {
      $p = Join-Path (Join-Path $script:WorkDir '輸出') '全班存疑清單.md'
      $status.Text = '存疑清單：' + $p
      if (Test-Path -LiteralPath $p) { Start-Process -FilePath $p }
    }
  })

$btnClarify = New-Object System.Windows.Forms.Button
$btnClarify.Text = '套用認知／重謄並重產PDF'
$btnClarify.Location = New-Object System.Drawing.Point(636, $y2)
$btnClarify.Size = New-Object System.Drawing.Size(190, 28)
$btnClarify.Add_Click({
    if (Invoke-MakePdf -Root $script:WorkDir -ApplyClarifications -UnclearList -MergeOriginal) {
      $status.Text = '已套用認知／重謄並重產 PDF'
      [void][System.Windows.Forms.MessageBox]::Show("已讀取「認知輸入」「重謄補充」並重產輸出 PDF。", '完成')
    }
  })

$btnOpenCog = New-Object System.Windows.Forms.Button
$btnOpenCog.Text = '認知／重謄夾'
$btnOpenCog.Location = New-Object System.Drawing.Point(836, $y2)
$btnOpenCog.Size = New-Object System.Drawing.Size(110, 28)
$btnOpenCog.Add_Click({
    Start-Process explorer.exe (Join-Path $script:WorkDir '認知輸入')
    Start-Process explorer.exe (Join-Path $script:WorkDir '重謄補充')
  })

$yPack = 598
$btnExportPack = New-Object System.Windows.Forms.Button
$btnExportPack.Text = '匯出0803同步包'
$btnExportPack.Location = New-Object System.Drawing.Point(16, $yPack)
$btnExportPack.Size = New-Object System.Drawing.Size(150, 28)
$btnExportPack.BackColor = [System.Drawing.Color]::FromArgb(45, 106, 79)
$btnExportPack.ForeColor = [System.Drawing.Color]::White
$btnExportPack.FlatStyle = 'Flat'
$btnExportPack.Add_Click({
    try {
      $p = Export-SyncPack0803 $script:WorkDir
      $status.Text = '已匯出同步包：' + $p
      Start-Process explorer.exe "/select,`"$p`""
      [void][System.Windows.Forms.MessageBox]::Show(
        "已匯出 0803 同步包（批改＋練習歷程日誌＋數位練習＋班級發送）：`n$p`n`n傳到另一台電腦／手機後「匯入0803同步包」。",
        '0803同步包'
      )
    } catch {
      [void][System.Windows.Forms.MessageBox]::Show("匯出失敗：$($_.Exception.Message)", '0803同步包')
    }
  })

$btnImportPack = New-Object System.Windows.Forms.Button
$btnImportPack.Text = '匯入0803同步包'
$btnImportPack.Location = New-Object System.Drawing.Point(176, $yPack)
$btnImportPack.Size = New-Object System.Drawing.Size(150, 28)
$btnImportPack.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = '0803同步包 (*.json)|*.json|所有檔案 (*.*)|*.*'
    $dlg.Title = '匯入 0803 同步包／批改進度'
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    try {
      $r = Import-SyncPack0803 $script:WorkDir $dlg.FileName
      $g = $r.Grader
      $msg = "已匯入。`n程度相關座號：$($g.Levels)`n練習歷程日誌：$($g.Histories)`n數位練習：$($g.Practices)"
      if ($r.Desk) { $msg += "`n班級狀態：$($r.Desk)" }
      $status.Text = '已匯入 0803 同步包（含歷程日誌）'
      Refresh-List
      [void][System.Windows.Forms.MessageBox]::Show($msg, '0803同步包')
    } catch {
      [void][System.Windows.Forms.MessageBox]::Show("匯入失敗：$($_.Exception.Message)", '0803同步包')
    }
  })

$btnOpenHist = New-Object System.Windows.Forms.Button
$btnOpenHist.Text = '練習歷程夾'
$btnOpenHist.Location = New-Object System.Drawing.Point(336, $yPack)
$btnOpenHist.Size = New-Object System.Drawing.Size(120, 28)
$btnOpenHist.Add_Click({
    $d = Join-Path $script:WorkDir '練習歷程'
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    Start-Process explorer.exe $d
  })

$y3 = 692
$btnDigital = New-Object System.Windows.Forms.Button
$btnDigital.Text = '數位練習包（手機）'
$btnDigital.Location = New-Object System.Drawing.Point(16, $y3)
$btnDigital.Size = New-Object System.Drawing.Size(170, 32)
$btnDigital.BackColor = [System.Drawing.Color]::FromArgb(30, 110, 90)
$btnDigital.ForeColor = [System.Drawing.Color]::White
$btnDigital.FlatStyle = 'Flat'
$btnDigital.Add_Click({
    if (Invoke-MakePdf -Root $script:WorkDir -DigitalPack) {
      $dir = Join-Path $script:WorkDir '數位練習'
      $status.Text = "已產出數位練習包：$dir"
      Start-Process explorer.exe $dir
      $idx = Join-Path $dir 'index.html'
      if (Test-Path -LiteralPath $idx) { Start-Process -FilePath $idx }
      [void][System.Windows.Forms.MessageBox]::Show(
        "已產出「數位練習」資料夾（手機／平板可開）。`n`n建議：`n1. 整夾放到 Google 雲端／OneDrive 分享連結`n2. 或用 LINE 傳「座號-練習題.html」（做完再傳解答）`n3. 也可複製「LINE發放文案.txt」`n`n沒有裝置的學生：填「列印專用\需列印座號.txt」後按「無裝置列印包」。",
        '數位發放'
      )
    }
  })

$btnCopyLine = New-Object System.Windows.Forms.Button
$btnCopyLine.Text = '複製此生LINE訊息'
$btnCopyLine.Location = New-Object System.Drawing.Point(196, $y3)
$btnCopyLine.Size = New-Object System.Drawing.Size(160, 32)
$btnCopyLine.Add_Click({
    if (-not $script:current) {
      [void][System.Windows.Forms.MessageBox]::Show('請先選左側一位學生', '提示')
      return
    }
    $id = Get-StudentId $script:current.Name
    [void](Invoke-MakePdf -Root $script:WorkDir -Student $id -DigitalPack)
    $msgPath = Join-Path (Join-Path $script:WorkDir '數位練習') ($id + '-LINE訊息.txt')
    if (-not (Test-Path -LiteralPath $msgPath)) {
      [void][System.Windows.Forms.MessageBox]::Show("尚未有座號 $id 的練習內容。請先輸出此生註記／練習。", '提示')
      return
    }
    $msg = Get-Content -LiteralPath $msgPath -Raw -Encoding UTF8
    [System.Windows.Forms.Clipboard]::SetText($msg.Trim())
    $status.Text = "已複製座號 $id 的 LINE 發放訊息"
    [void][System.Windows.Forms.MessageBox]::Show("已複製到剪貼簿，可貼到 LINE／班級群組。`n`n$($msg.Trim())", 'LINE 訊息')
  })

$btnPrintPack = New-Object System.Windows.Forms.Button
$btnPrintPack.Text = '無裝置列印包'
$btnPrintPack.Location = New-Object System.Drawing.Point(366, $y3)
$btnPrintPack.Size = New-Object System.Drawing.Size(140, 32)
$btnPrintPack.BackColor = [System.Drawing.Color]::FromArgb(140, 90, 40)
$btnPrintPack.ForeColor = [System.Drawing.Color]::White
$btnPrintPack.FlatStyle = 'Flat'
$btnPrintPack.Add_Click({
    Ensure-WorkTree $script:WorkDir
    $listPath = Join-Path (Join-Path $script:WorkDir '列印專用') '需列印座號.txt'
    Start-Process notepad.exe $listPath
    $r = [System.Windows.Forms.MessageBox]::Show(
      "請在「需列印座號.txt」填入沒有通訊裝置的座號並存檔。`n`n存好後按「是」產出紙本 PDF（只印這些人）。",
      '無裝置列印包',
      [System.Windows.Forms.MessageBoxButtons]::YesNo
    )
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    if (Invoke-MakePdf -Root $script:WorkDir -PrintPack) {
      $dir = Join-Path $script:WorkDir '列印專用'
      $status.Text = "已產出列印包：$dir"
      Start-Process explorer.exe $dir
      [void][System.Windows.Forms.MessageBox]::Show(
        "已依「需列印座號.txt」產出練習題／解答 PDF。`n只印這些座號即可，其餘用數位發放。`n`n$dir",
        '列印包'
      )
    }
  })

$btnOpenDigital = New-Object System.Windows.Forms.Button
$btnOpenDigital.Text = '數位／列印夾'
$btnOpenDigital.Location = New-Object System.Drawing.Point(516, $y3)
$btnOpenDigital.Size = New-Object System.Drawing.Size(120, 32)
$btnOpenDigital.Add_Click({
    Start-Process explorer.exe (Join-Path $script:WorkDir '數位練習')
    Start-Process explorer.exe (Join-Path $script:WorkDir '列印專用')
  })

$y4 = 738
$btnTools = New-Object System.Windows.Forms.Button
$btnTools.Text = '工具選擇（LINE群／個別…）'
$btnTools.Location = New-Object System.Drawing.Point(16, $y4)
$btnTools.Size = New-Object System.Drawing.Size(220, 32)
$btnTools.BackColor = [System.Drawing.Color]::FromArgb(50, 80, 120)
$btnTools.ForeColor = [System.Drawing.Color]::White
$btnTools.FlatStyle = 'Flat'
$btnTools.Add_Click({ Show-ToolPickerDialog })

$btnLoop = New-Object System.Windows.Forms.Button
$btnLoop.Text = '練習回傳循環'
$btnLoop.Location = New-Object System.Drawing.Point(246, $y4)
$btnLoop.Size = New-Object System.Drawing.Size(140, 32)
$btnLoop.BackColor = [System.Drawing.Color]::FromArgb(30, 100, 70)
$btnLoop.ForeColor = [System.Drawing.Color]::White
$btnLoop.FlatStyle = 'Flat'
$btnLoop.Add_Click({ Show-PracticeLoopDialog })

$btnRetFolder = New-Object System.Windows.Forms.Button
$btnRetFolder.Text = '練習回傳夾'
$btnRetFolder.Location = New-Object System.Drawing.Point(396, $y4)
$btnRetFolder.Size = New-Object System.Drawing.Size(110, 32)
$btnRetFolder.Add_Click({
    Ensure-WorkTree $script:WorkDir
    Start-Process explorer.exe (Join-Path $script:WorkDir '練習回傳')
  })

$btnJunyi = New-Object System.Windows.Forms.Button
$btnJunyi.Text = '自產練習說明'
$btnJunyi.Location = New-Object System.Drawing.Point(516, $y4)
$btnJunyi.Size = New-Object System.Drawing.Size(130, 32)
$btnJunyi.BackColor = [System.Drawing.Color]::FromArgb(40, 100, 90)
$btnJunyi.ForeColor = [System.Drawing.Color]::White
$btnJunyi.FlatStyle = 'Flat'
$btnJunyi.Add_Click({
    Ensure-WorkTree $script:WorkDir
    $guide = Join-Path $script:WorkDir '自產練習與影片說明.txt'
    $utf8Bom = New-Object System.Text.UTF8Encoding $true
    $body = @(
      '自產練習與影片（不用均一）'
      '===================='
      ''
      '做法：'
      '1. 選「請 Cursor 直接批閱」→ Cursor 會自動產出：診斷、程度、自學指導、練習題、解答、建議影片連結／搜尋頁'
      '2. 貼回右側後按「輸出此生PDF」→「數位練習」會有手機可開的練習'
      '3. 回傳循環時，Cursor 同樣會依問題點再產「下一輪練習＋指導＋影片」'
      ''
      '影片規則：'
      '- 優先用 YouTube 搜尋結果頁（可點）：'
      '  https://www.youtube.com/results?search_query=年級+單元+教學'
      '- 有把握才貼具體影片網址；不要捏造連結'
      ''
      '發放：LINE 群公告＋個別傳練習檔；回傳圖檔到「練習回傳」'
      '均一：可完全不用。'
    ) -join "`r`n"
    [IO.File]::WriteAllText($guide, $body, $utf8Bom)
    Start-Process notepad.exe $guide
    $status.Text = '已開：自產練習與影片說明（不用均一）'
  })

$btnTablet = New-Object System.Windows.Forms.Button
$btnTablet.Text = '手寫板匯入並批'
$btnTablet.Location = New-Object System.Drawing.Point(656, $y4)
$btnTablet.Size = New-Object System.Drawing.Size(140, 32)
$btnTablet.BackColor = [System.Drawing.Color]::FromArgb(20, 90, 130)
$btnTablet.ForeColor = [System.Drawing.Color]::White
$btnTablet.FlatStyle = 'Flat'
$btnTablet.Add_Click({ Show-TabletImportAndGrade })

$form.Size = New-Object System.Drawing.Size(1100, 920)
$status.Location = New-Object System.Drawing.Point(16, 790)
$status.Size = New-Object System.Drawing.Size(1040, 40)

$form.Controls.AddRange(@(
    $lbl, $grpStart, $lblPath, $list, $grp, $status,
    $btnWork, $btnOpenIn, $btnOpenOut, $btnGrade, $btnSave, $btnNext, $btnAutoAll, $btnRefresh,
    $btnCsv, $btnSyncDesk, $btnExportProgress, $btnUnclear, $btnClarify, $btnOpenCog,
    $btnExportPack, $btnImportPack, $btnOpenHist,
    $btnDigital, $btnCopyLine, $btnPrintPack, $btnOpenDigital,
    $btnTools, $btnLoop, $btnRetFolder, $btnJunyi, $btnTablet
  ))

Refresh-PathLabel
Refresh-AnswerLabel
Refresh-List
if ($list.Items.Count -gt 0) { $list.SelectedIndex = 0 }

[void]$form.ShowDialog()
