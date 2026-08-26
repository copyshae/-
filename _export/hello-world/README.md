# 匯出最終包｜每日14樣功課備忘錄（2026-08-20）

## 手機直接用（不必開電腦）

正式預覽／主畫面捷徑：

**https://copyshae.github.io/-/daily-14/**

Safari／Chrome →「分享」→「加入主畫面」。進度存在手機瀏覽器，隔日自動重置。

習作工具主頁入口：https://copyshae.github.io/-/

---

本包另含 hello-world 匯出（學習日誌 0820）。**只有要同步 hello-world 學習日誌站時**才需在電腦跑下方腳本；單純用備忘錄不用跑。

| 項目 | 內容 |
|------|------|
| 每日14樣功課 | 勾選後消失、台北時區每日重置、可加到手機主畫面 |
| 學習日誌 | `20260820-learning-log.html`（可選，套用到 hello-world） |

## 可選：套用到 hello-world（電腦）

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url = 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/scripts/pull-export-from-dash-repo.ps1'
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```
