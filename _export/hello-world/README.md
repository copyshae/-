# 匯出：習作台＋習作批改（含批完後續）

Cloud Agent **無法推送** `copyshae/hello-world`。倉庫名 `copyshae/-` 的 GitHub Pages 先前已證實無法穩定啟用，請改套用到 **hello-world**（正式網址本來就能開）。

## 本包內容

- `directory/apps/math-grader/` — 手機習作批改（含「批完後續」：自產練習／發放訊息／回傳循環）
- `directory/apps/teacher-desk/` — 手機習作台（繁中）
- 桌面安裝腳本、`pull-export-from-dash-repo.ps1`

## 套用（推薦｜在桌面\hello-world 的 PowerShell 整段貼上）

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url = 'https://raw.githubusercontent.com/copyshae/-/_export/hello-world will load from main/_export/hello-world/scripts/pull-export-from-dash-repo.ps1'
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```

腳本會下載匯出檔並（若有）推上 hello-world。完成後手機開：

**https://copyshae.github.io/hello-world/directory/apps/math-grader/**

往下捲找 **「批完後續」**。若看不到，強制重新整理或清掉該站快取後再開。

## 電腦版

桌面「習作批改」本來就有 0803 後續（自產練習、回傳循環、數位練習包）。關掉舊視窗後再雙擊 `習作批改.vbs` 即可。

桌面「習作台」若雙擊 `習作台.vbs` 出現 **80070002 找不到檔案**，請在 hello-world 重跑：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
git pull origin master
powershell -ExecutionPolicy Bypass -File .\scripts\install-teacher-desk.ps1
```

（會覆寫捷徑；`習作台資料` 保留。）然後再雙擊 **習作台.vbs**。
