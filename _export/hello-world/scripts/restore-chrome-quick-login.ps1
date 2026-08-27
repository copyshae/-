#Requires -Version 5.1
<#
.SYNOPSIS
  依 20260721 學習日誌恢復桌面「ChromeQuickLogin」（常用網址啟動器）。

.DESCRIPTION
  規格：https://copyshae.github.io/hello-world/directory/logs/20260721-chrome-quick-login.html

  桌面線索：
    Desktop\ChromeQuickLogin\     程式（Python + Tkinter）
    Desktop\ChromeQuickLogin.lnk  捷徑（英文檔名較穩）
    Desktop\啟動.bat              （專案內）
    ChromeQuickLogin-vault-*.zip  換機金庫（vault.dat + meta.json）

  程式私有庫：github.com/copyshae/ChromeQuickLogin（不含金庫）
  金庫不進 Git；PIN 自己記，忘記無法還原。

.PARAMETER VaultZip
  指定換機 zip 路徑；省略則自動找桌面 ChromeQuickLogin-vault-*.zip。

.PARAMETER SkipClone
  不嘗試 git clone／pull，只建捷徑與還原金庫。
#>
param(
  [string]$VaultZip = "",
  [switch]$SkipClone
)

$ErrorActionPreference = "Stop"
$desk = [Environment]::GetFolderPath("Desktop")
$appDir = Join-Path $desk "ChromeQuickLogin"
$remote = "https://github.com/copyshae/ChromeQuickLogin.git"
$utf8Bom = New-Object System.Text.UTF8Encoding $true
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$notePath = Join-Path $desk "ChromeQuickLogin-恢復說明.txt"

Write-Host "===== 恢復 ChromeQuickLogin（0721 學習日誌）====="
Write-Host "說明：https://copyshae.github.io/hello-world/directory/logs/20260721-chrome-quick-login.html"
Write-Host "桌面：$desk"
Write-Host ""

function New-DesktopShortcut([string]$TargetPath, [string]$LinkPath, [string]$WorkDir) {
  $w = New-Object -ComObject WScript.Shell
  $sc = $w.CreateShortcut($LinkPath)
  $sc.TargetPath = $TargetPath
  $sc.WorkingDirectory = $WorkDir
  $sc.WindowStyle = 1
  $sc.Description = "ChromeQuickLogin 常用網址啟動器"
  $sc.Save()
}

# 1) 程式：clone／pull 私有庫
$cloned = $false
if (-not $SkipClone) {
  if (-not (Test-Path -LiteralPath (Join-Path $appDir ".git"))) {
    if (Test-Path -LiteralPath $appDir) {
      Write-Host "已有資料夾 $appDir（非 git）。略過 clone，改用現有檔。"
    } else {
      Write-Host "嘗試 clone 私有庫 $remote ..."
      try {
        & git clone $remote $appDir
        if ($LASTEXITCODE -eq 0) {
          $cloned = $true
          Write-Host "  clone 成功。"
        } else {
          Write-Host "  clone 失敗（結束代碼 $LASTEXITCODE）。私有庫需先 gh auth login／本機有權限。"
        }
      } catch {
        Write-Host "  clone 例外：$($_.Exception.Message)"
      }
    }
  } else {
    Write-Host "已有倉庫，git pull ..."
    try {
      & git -C $appDir pull
      $cloned = $true
    } catch {
      Write-Host "  pull 失敗：$($_.Exception.Message)"
    }
  }
}

if (-not (Test-Path -LiteralPath $appDir)) {
  $msg = @"
找不到 $appDir

請擇一：
1. 本機有 GitHub 權限時再跑本腳本（會 clone 私有庫）
2. 從另一台把 Desktop\ChromeQuickLogin 整夾複製過來
3. 在 Cursor 開私有庫後，把「工作電腦安裝提示詞.md」整段貼上

學習日誌：https://copyshae.github.io/hello-world/directory/logs/20260721-chrome-quick-login.html
"@
  [System.IO.File]::WriteAllText($notePath, $msg, $utf8Bom)
  Write-Host $msg
  throw "ChromeQuickLogin 程式目錄不存在，已寫入 $notePath"
}

# 2) 金庫：還原 vault zip
$dataDir = Join-Path $appDir "data"
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

if ([string]::IsNullOrWhiteSpace($VaultZip)) {
  $zips = @(Get-ChildItem -LiteralPath $desk -Filter "ChromeQuickLogin-vault-*.zip" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending)
  if ($zips.Count -gt 0) { $VaultZip = $zips[0].FullName }
}

$vaultRestored = $false
if ($VaultZip -and (Test-Path -LiteralPath $VaultZip)) {
  Write-Host "還原金庫：$VaultZip"
  $tmp = Join-Path $env:TEMP ("cql-vault-" + [guid]::NewGuid().ToString())
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  try {
    Expand-Archive -LiteralPath $VaultZip -DestinationPath $tmp -Force
    $vault = Get-ChildItem -Path $tmp -Recurse -Filter "vault.dat" -ErrorAction SilentlyContinue | Select-Object -First 1
    $meta = Get-ChildItem -Path $tmp -Recurse -Filter "meta.json" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $vault -or -not $meta) {
      Write-Host "  zip 內缺 vault.dat 或 meta.json（兩者都要，漏拷會解不開）。"
    } else {
      Copy-Item -LiteralPath $vault.FullName -Destination (Join-Path $dataDir "vault.dat") -Force
      Copy-Item -LiteralPath $meta.FullName -Destination (Join-Path $dataDir "meta.json") -Force
      $vaultRestored = $true
      Write-Host "  已寫入 data\vault.dat 與 data\meta.json"
    }
  } finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
} else {
  $hasVault = Test-Path -LiteralPath (Join-Path $dataDir "vault.dat")
  $hasMeta = Test-Path -LiteralPath (Join-Path $dataDir "meta.json")
  if ($hasVault -and $hasMeta) {
    Write-Host "data\ 已有 vault.dat + meta.json，略過 zip。"
    $vaultRestored = $true
  } else {
    Write-Host "未找到換機 zip。請把 ChromeQuickLogin-vault-*.zip 放到桌面後重跑，或手動把 vault.dat＋meta.json 放進 data\"
  }
}

# 3) Python 依賴（若有 requirements.txt）
$req = Join-Path $appDir "requirements.txt"
$venvPy = Join-Path $appDir ".venv\Scripts\python.exe"
if ((Test-Path -LiteralPath $req) -and -not (Test-Path -LiteralPath $venvPy)) {
  Write-Host "建立 venv 並安裝依賴 ..."
  try {
    & python -m venv (Join-Path $appDir ".venv")
    & (Join-Path $appDir ".venv\Scripts\pip.exe") install -r $req
  } catch {
    Write-Host "  venv／pip 失敗：$($_.Exception.Message)（可稍後手動處理）"
  }
}

# 4) 啟動捷徑（英文檔名較穩，見 0721 日誌）
$bat = Join-Path $appDir "啟動.bat"
$pyMain = $null
foreach ($cand in @("main.py", "app.py", "chrome_quick_login.py", "launcher.py")) {
  $p = Join-Path $appDir $cand
  if (Test-Path -LiteralPath $p) { $pyMain = $p; break }
}

$lnk = Join-Path $desk "ChromeQuickLogin.lnk"
if (Test-Path -LiteralPath $bat) {
  New-DesktopShortcut $bat $lnk $appDir
  Write-Host "捷徑：$lnk → 啟動.bat"
} elseif ($pyMain) {
  $py = if (Test-Path -LiteralPath $venvPy) { $venvPy } else { "python" }
  # 用 vbs 隱藏黑窗啟動
  $vbs = Join-Path $appDir "launch.vbs"
  $vbsBody = @"
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = "$($appDir.Replace('"','""'))"
cmd = """$py"" ""$($pyMain.Replace('"','""'))"""
sh.Run cmd, 0, False
"@
  [System.IO.File]::WriteAllText($vbs, $vbsBody, (New-Object System.Text.UnicodeEncoding $false, $true))
  New-DesktopShortcut $vbs $lnk $appDir
  Write-Host "捷徑：$lnk → launch.vbs"
} else {
  Write-Host "找不到 啟動.bat 或主程式 .py，請開 Cursor 對私有庫貼「工作電腦安裝提示詞.md」。"
}

$note = @"
ChromeQuickLogin 恢復說明
時間：$stamp
程式夾：$appDir
捷徑：$lnk
clone／pull：$(if ($cloned) { '有' } else { '無／略過' })
金庫還原：$(if ($vaultRestored) { '有' } else { '無（請放 zip 或手動 data\）' })

使用（0721 學習日誌）：
1. 雙擊桌面 ChromeQuickLogin.lnk
2. 輸入 4–6 位 PIN（兩台必須同一組；忘記無法還原）
3. 選網站 →「開啟並自動登入」；Chrome 倒數時點帳號欄

換機口訣：程式走 Git｜金庫走 zip｜PIN 自己記｜提示詞貼 Cursor
打包換機：在原機跑 打包換機.ps1 → 桌面產生 ChromeQuickLogin-vault-*.zip
學習日誌：https://copyshae.github.io/hello-world/directory/logs/20260721-chrome-quick-login.html
"@
[System.IO.File]::WriteAllText($notePath, $note, $utf8Bom)

Write-Host ""
Write-Host "完成。詳見：$notePath"
Write-Host "請雙擊桌面 ChromeQuickLogin.lnk（勿把帳密寫進捷徑或網址）。"
