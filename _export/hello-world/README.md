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

## 只更新桌面兩個 .vbs（＋電腦視窗程式）

PowerShell 貼上（覆寫 `習作批改.vbs`、`習作台.vbs`，並更新 `MathGradingApp`／`習作台程式` 裡的 ps1）：

```powershell
irm https://raw.githubusercontent.com/copyshae/-/cursor/textbook-grade-format-459a/_export/hello-world/scripts/refresh-desktop-vbs.ps1 | iex
```

**關掉**舊的習作批改視窗後，再雙擊 `習作批改.vbs`。新視窗標題列應含 **`[20260818-sync]`**，並有綠色 **ChatPlayground批** 與下方 **③ 貼上自動批閱**。若畫面仍舊：代表只更新了 vbs、ps1 沒重下，或舊視窗沒關；腳本結束會跳提示框，桌面會有 `習作程式版本.txt`。勿用 `習作台.cmd` 或 `MathGrading` 舊捷徑。

## 一鍵套用（PowerShell 整段貼上）

PR 尚未合併進 `main` 時，先設分支再拉（含 ChatPlayground AI 備援）：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$env:DASH_EXPORT_BRANCH = 'cursor/textbook-grade-format-459a'
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
2. 再雙擊桌面兩個捷徑：`習作批改.vbs`、`習作台.vbs`  
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
