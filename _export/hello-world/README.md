# 匯出最終包｜學習日誌：8 月 3 日後一天一主題

未上線工作接在 0803 之後，一天一篇（0804–0816）：

- 0804 習作台手機可見　0805 桌面掃描／捷徑　0806 Gemini 404
- 0807 手機 API 自動批　0808 快速批　0809 批完後續
- 0810 匯出 hello-world　0811 金鑰／503／額度　0812 進度備份
- 0813 國中課本形式　0814 ChatPlayground　0815 0803 延伸　0816 失敗回未批
- `directory/202608/20260817-push-logs.html` 補推說明
- `directory/202608/index.html` 8 月列表（含既有 0817 換機安裝）

套用後線上列表：https://copyshae.github.io/hello-world/directory/202608/

合併前進本機套用（指定本 PR 分支）：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$env:DASH_EXPORT_BRANCH = 'cursor/push-unlogged-days-aafd'
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url = "https://raw.githubusercontent.com/copyshae/-/$env:DASH_EXPORT_BRANCH/_export/hello-world/scripts/pull-export-from-dash-repo.ps1"
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```

---

# 匯出最終包｜與電腦版同步＋今日合併（2026-08-16）

本包把 **hello-world 電腦完整版** 與今日討論一併合併：

| 項目 | 內容 |
|------|------|
| 電腦習作批改 | 測試金鑰、503 自動重試、自產練習／回傳循環／數位練習包（完整流程） |
| 電腦習作台 | 完整版（篩選／管道／匯入匯出）＋處理掃描匯入 |
| 手機習作批改 | **批完後續**（練習模板／發放訊息／寫入習作台／回傳循環／歷程） |
| 手機習作台 | 同步程度、掃描王匯入、群發文 |

> Cloud Agent **無法推** `copyshae/hello-world`。請在電腦跑下方指令，才會更新正式手機網址與本機捷徑。

## 一鍵套用（PowerShell 整段貼上）

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url = 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/scripts/pull-export-from-dash-repo.ps1'
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```

完成後：

1. **關掉**舊的習作批改／習作台視窗  
2. 再雙擊桌面 `習作批改.vbs`、`習作台.cmd`  
3. 手機強制重新整理：  
   - https://copyshae.github.io/hello-world/directory/apps/math-grader/  
   - https://copyshae.github.io/hello-world/directory/apps/teacher-desk/  

## 規格依據

https://copyshae.github.io/hello-world/directory/202608/20260803-learning-log.html
