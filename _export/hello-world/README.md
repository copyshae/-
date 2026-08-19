# 匯出最終包｜與電腦版同步＋今日合併（2026-08-19）

本包把 **hello-world 電腦完整版** 與今日討論一併合併：

| 項目 | 內容 |
|------|------|
| **手機 Cursor 快捷詞** | 倉庫內 `push-learning-log` 規則／skill；打「推日誌」「連日誌」。說明頁 `directory/logs/prompts/` |
| 電腦習作批改 | 測試金鑰、503 自動重試、自產練習／回傳循環／數位練習包（完整流程） |
| 電腦習作台 | 完整版（篩選／管道／匯入匯出）＋處理掃描匯入 |
| 手機習作批改 | **批完後續**（練習模板／發放訊息／寫入習作台／回傳循環／歷程） |
| 手機習作台 | 同步程度、掃描王匯入、群發文 |
| **手機掃具台** | **新增同步**：CSV 匯入負數修正、iOS 分享、確認框、請領負數扣回 |

> Cloud Agent **無法推** `copyshae/hello-world`。請在電腦跑下方指令，才會更新正式手機網址、本機捷徑與學習日誌頁。

合併前若要先套用本分支，先設 `$env:DASH_EXPORT_BRANCH = 'cursor/mobile-push-log-shortcut-c862'`。

## 一鍵套用（PowerShell 整段貼上）

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$env:DASH_EXPORT_BRANCH = 'cursor/mobile-push-log-shortcut-c862'
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url = "https://raw.githubusercontent.com/copyshae/-/$env:DASH_EXPORT_BRANCH/_export/hello-world/scripts/pull-export-from-dash-repo.ps1"
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```

完成後：

1. **關掉**舊的習作批改／習作台視窗  
2. 再雙擊桌面 `習作批改.vbs`、`習作台.cmd`  
3. 手機強制重新整理：  
   - https://copyshae.github.io/hello-world/directory/apps/math-grader/  
   - https://copyshae.github.io/hello-world/directory/apps/teacher-desk/  
   - https://copyshae.github.io/hello-world/directory/apps/scan-equip/  
   - https://copyshae.github.io/hello-world/directory/202608/20260819-learning-log.html  
   - https://copyshae.github.io/hello-world/directory/logs/prompts/  

## 規格依據

https://copyshae.github.io/hello-world/directory/202608/20260803-learning-log.html
