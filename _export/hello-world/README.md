# 匯出最終包｜七個好習慣分類（2026-08-27）

## 兩支 App 分開（不要混）

| App | 網址 | 用途 |
|-----|------|------|
| **七個好習慣分類** | https://copyshae.github.io/-/habits-7/ | 人事時地物 → 七習慣＋時間象限；康軒國一上課建議 |
| **每日14樣功課** | https://copyshae.github.io/-/daily-14/ | 14 項功課勾選備忘錄（維持原樣） |

習作工具主頁：https://copyshae.github.io/-/

---

本包另含 hello-world 匯出（學習日誌 0827）。**只有要同步 hello-world 學習日誌站時**才需在電腦跑下方腳本。

## 可選：套用到 hello-world（電腦）

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url = 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/scripts/pull-export-from-dash-repo.ps1'
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```
