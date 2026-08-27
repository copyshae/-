# 匯出最終包｜與電腦版同步＋今日合併（2026-08-16）

本包把 **hello-world 電腦完整版** 與今日討論一併合併：

| 項目 | 內容 |
|------|------|
| 電腦習作批改 | 測試金鑰、503／免費額度自動等待重試、自產練習／回傳循環／數位練習包（完整流程） |
| 電腦習作台 | 完整版（篩選／管道／匯入匯出）＋處理掃描匯入 |
| 手機習作批改 | **批完後續完整鏈**（測試金鑰／練習模板／發放／寫入習作台／回傳循環／待批清單／練習包／無裝置列印／待認知） |
| 手機習作台 | 同步程度（含待判定）、掃描王匯入、群發文（一～四）、需列印座號 |
| 預設批閱 | **ChatPlayground AI**（終身 Unlimited）：一鍵複製提示＋下載試卷＋開站；貼回覆即標已批。Gemini 金鑰為選用備援。 |

> Cloud Agent **無法推** `copyshae/hello-world`。請在電腦跑下方指令，才會更新正式手機網址與本機捷徑。

## 恢復桌面視窗程式（依學習日誌）

**本機一鍵（掃描＋恢復；純 ASCII 啟動器，避免 PS5.1 中文亂碼）：**

```powershell
irm https://raw.githubusercontent.com/copyshae/-/cursor/restore-desktop-apps-459a/_export/hello-world/scripts/run-scan-and-restore.ps1 | iex
```

只掃描、不恢復：

```powershell
irm https://raw.githubusercontent.com/copyshae/-/cursor/restore-desktop-apps-459a/_export/hello-world/scripts/run-scan-desktop-clues.ps1 | iex
```

（腳本會以 UTF-8 BOM 下載後再執行，解決繁中 Windows `ParserError`／亂碼。）

<details><summary>進階：手動下載 scan 腳本</summary>

```powershell
$u = "https://raw.githubusercontent.com/copyshae/-/cursor/restore-desktop-apps-459a/_export/hello-world/scripts/run-scan-desktop-clues.ps1"
$i = Join-Path $env:TEMP "run-scan-desktop-clues.ps1"
$wc = New-Object Net.WebClient; $wc.Encoding = [Text.Encoding]::UTF8
[IO.File]::WriteAllText($i, $wc.DownloadString($u), (New-Object Text.UTF8Encoding $true))
powershell -ExecutionPolicy Bypass -File $i
powershell -ExecutionPolicy Bypass -File $i -Restore
```

</details>

或只恢復習作批改／習作台／習作工具：

```powershell
irm https://raw.githubusercontent.com/copyshae/-/cursor/restore-desktop-apps-459a/_export/hello-world/scripts/run-restore-desktop-apps.ps1 | iex
```

學習日誌記載的桌面程式：

| 日誌 | 程式 | 桌面捷徑 |
|------|------|----------|
| [0803](https://copyshae.github.io/hello-world/directory/202608/20260803-learning-log.html) | 數學習作批改 | `習作批改.vbs` → `MathGradingApp\` |
| [0805](https://copyshae.github.io/hello-world/directory/202608/20260805-learning-log.html) | 習作台（掃描匯入） | `習作台.vbs` → `習作台程式\` |
| [0817](https://copyshae.github.io/hello-world/directory/202608/20260817-learning-log.html) | 換機一鍵裝兩個視窗 | `bootstrap-desktop-apps.ps1` |
| [0818](https://copyshae.github.io/hello-world/directory/202608/20260818-learning-log.html) | ChatPlayground、快速啟動 | `習作工具.vbs`（選單） |
| [0819](https://copyshae.github.io/hello-world/directory/202608/20260819-learning-log.html) | 掃具台 | `掃具台.cmd` → 開 PWA |
| [0801](https://copyshae.github.io/hello-world/directory/202608/20260801-learning-log.html) | 護眼提醒 | `護眼提醒.vbs` → `EyeCareReminder\` |
| [0721](https://copyshae.github.io/hello-world/directory/logs/20260721-chrome-quick-login.html) | ChromeQuickLogin | `ChromeQuickLogin.lnk` → `ChromeQuickLogin\` |

桌面線索對照（掃描腳本會找這些）：

| 線索 | 可能程式 | 舊版勿用 |
|------|----------|----------|
| `習作批改.vbs`、`MathGradingApp\` | 習作批改 | `grade-math.vbs` |
| `習作台.vbs`、`習作台程式\` | 習作台 | `習作台.cmd` |
| `習作工具.vbs` | 選單入口 | — |
| `護眼提醒.vbs`、`EyeCareReminder\` | 護眼提醒 | — |
| `掃具台.cmd`、`掃具台程式\` | 掃具台 | — |
| `ChromeQuickLogin.lnk`、`ChromeQuickLogin\` | 常用網址啟動器 | 勿把帳密寫進捷徑 |
| `ChromeQuickLogin-vault-*.zip` | 換機金庫 | 須含 vault.dat＋meta.json |
| `習作程式版本.txt` | 上次更新紀錄 | — |
| `習作台錯誤.txt` | 習作台上次啟動失敗 | — |

**只恢復 ChromeQuickLogin**（0721；程式私有庫＋桌面金庫 zip）：

```powershell
irm https://raw.githubusercontent.com/copyshae/-/cursor/restore-desktop-apps-459a/_export/hello-world/scripts/restore-chrome-quick-login.ps1 | iex
```

首次換機、桌面尚無 hello-world 資料夾時（會 clone 並建立工作資料夾）：

```powershell
$u = "https://raw.githubusercontent.com/copyshae/-/cursor/restore-desktop-apps-459a/_export/hello-world/scripts/restore-desktop-apps.ps1"
$i = Join-Path $env:TEMP "restore-desktop-apps.ps1"
Invoke-WebRequest -Uri $u -OutFile $i -UseBasicParsing
powershell -ExecutionPolicy Bypass -File $i -FirstInstall
```

或依 [0817 說明](https://copyshae.github.io/hello-world/directory/apps/desktop-install.html)：

```powershell
irm https://raw.githubusercontent.com/copyshae/hello-world/master/scripts/bootstrap-desktop-apps.ps1 | iex
```

**關掉**舊視窗後，雙擊 **`習作工具.vbs`**（建議只留這一個捷徑）。啟動會先顯示「正在啟動…」。標題列應含 **`[20260818-fast5]`**，習作批改有 **ChatPlayground批** 與 **③ 貼上自動批閱**。桌面會產生 `習作程式版本.txt` 與 `桌面程式線索報告.txt`。勿用 `習作台.cmd` 或 `MathGrading` 舊捷徑。

## 一鍵套用（PowerShell 整段貼上）

PR 尚未合併進 `main` 時，先設分支再拉（含 ChatPlayground AI 備援）：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$env:DASH_EXPORT_BRANCH = 'cursor/restore-desktop-apps-459a'
$url = "https://raw.githubusercontent.com/copyshae/-/$env:DASH_EXPORT_BRANCH/_export/hello-world/scripts/pull-export-from-dash-repo.ps1"
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```

已合併 `main` 後可改：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Remove-Item Env:DASH_EXPORT_BRANCH -ErrorAction SilentlyContinue
$url = 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/scripts/pull-export-from-dash-repo.ps1'
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```

完成後：

1. **關掉**舊的習作批改／習作台視窗  
2. 再雙擊桌面 **`習作工具.vbs`**（或 `習作批改.vbs`、`習作台.vbs`）  
3. 手機強制重新整理：  
   - https://copyshae.github.io/hello-world/directory/apps/math-grader/  
   - https://copyshae.github.io/hello-world/directory/apps/teacher-desk/  

## 預覽（PR 分支，raw.githack）

- 入口：https://raw.githack.com/copyshae/-/6346b90/_export/hello-world/directory/apps/index.html  
- 習作批改：https://raw.githack.com/copyshae/-/6346b90/_export/hello-world/directory/apps/math-grader/index.html  
- 習作台：https://raw.githack.com/copyshae/-/6346b90/_export/hello-world/directory/apps/teacher-desk/index.html  

（推送後請把 SHA 換成最新 commit。勿用 jsDelivr 開 HTML。）

## 規格依據

https://copyshae.github.io/hello-world/directory/202608/20260803-learning-log.html

手機批閱路徑（ChatPlayground／貼上自動批閱）：
https://copyshae.github.io/hello-world/directory/202608/20260818-learning-log.html
