# 匯出最終包｜每日14樣功課備忘錄（2026-08-20）

本包新增 **每日14樣功課** 手機勾選備忘錄（PWA），並更新學習日誌入口。

| 項目 | 內容 |
|------|------|
| 每日14樣功課 | 勾選後消失、台北時區每日重置、可加到手機主畫面 |
| 學習日誌 | `20260820-learning-log.html`；目錄與「最新」導向本篇 |
| 既有 App | 習作批改／習作台／掃具台一併可同步 |

> Cloud Agent **無法推** `copyshae/hello-world`。請在電腦跑下方指令，才會更新正式手機網址。

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

1. 手機開啟：https://copyshae.github.io/hello-world/directory/apps/daily-14/
2. Safari／Chrome →「加入主畫面」
3. 學習日誌：https://copyshae.github.io/hello-world/directory/202608/20260820-learning-log.html

## 規格依據

海報「每日14樣功課」（天圓文化／超級生命密碼）＋本倉庫 `docs/daily-14/`。
