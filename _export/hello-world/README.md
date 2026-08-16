# 匯出：習作台＋習作批改（含批完後續）

Cloud Agent **無法推送** `copyshae/hello-world`。倉庫名 `copyshae/-` 的 GitHub Pages 先前已證實無法穩定啟用，請改套用到 **hello-world**（正式網址本來就能開）。

## 本包內容

- `directory/apps/math-grader/` — 手機習作批改（含「批完後續」：自產練習／發放訊息／回傳循環）
- `directory/apps/teacher-desk/` — 手機習作台（繁中）
- 桌面安裝腳本、`pull-export-from-dash-repo.ps1`、`scripts/README-sync.md`（兩台電腦＋手機同步）

## 套用（推薦｜在桌面\hello-world 的 PowerShell 整段貼上）

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
# 合併進 main 前可暫設：$env:DASH_EXPORT_BRANCH = 'cursor/sync-desk-grader-devices-2663'
$url = 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/scripts/pull-export-from-dash-repo.ps1'
# 若要用本功能分支：把上面 main 改成 cursor/sync-desk-grader-devices-2663
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```

腳本會下載匯出檔並（若有）推上 hello-world。完成後手機開：

**https://copyshae.github.io/hello-world/directory/apps/math-grader/**

往下捲找 **「批完後續」** 與 **「跨裝置／與習作台同步」**。若看不到，強制重新整理或清掉該站快取後再開。

## 電腦版

桌面「習作批改」本來就有 0803 後續（自產練習、回傳循環、數位練習包）。關掉舊視窗後再雙擊 `習作批改.vbs` 即可。

桌面「習作台」若雙擊 `習作台.vbs` 出現 **80070002 找不到檔案**，請在 hello-world 重跑：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
git pull origin master
powershell -ExecutionPolicy Bypass -File .\scripts\install-teacher-desk.ps1
```

（會覆寫捷徑；`習作台資料` 保留。）然後再雙擊 **習作台.vbs**。

跨裝置／批改↔習作台：見 `scripts/README-sync.md`。桌面批改有「同步程度→習作台」「匯出批改進度JSON」。
