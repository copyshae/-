# 匯出最終包｜七個好習慣分類（2026-08-27）

## 兩支 App 分開（不要混）

| App | 網址 | 用途 |
|-----|------|------|
| **七個好習慣分類** | https://copyshae.github.io/-/habits-7/ | 人事時地物 → 七習慣＋時間象限；康軒國一上課建議 |
| **每日14樣功課** | https://copyshae.github.io/-/daily-14/ | 14 項功課勾選備忘錄（維持原樣） |

習作工具主頁：https://copyshae.github.io/-/

---

本包另含 hello-world 匯出（學習日誌 **0821–0823**，並保留 hello-world 專用 **0820 環境教育**）。**只有要同步 hello-world 學習日誌站時**才需在電腦跑下方腳本。

## 可選：套用到 hello-world（電腦）

**請在 `Desktop\hello-world` 資料夾內執行**（不要在 `C:\Users\你的帳號>` 執行）：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url = 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/scripts/pull-export-from-dash-repo.ps1'
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```

同步完成後，電腦正式站應顯示：

- 最新日誌 0823：https://copyshae.github.io/hello-world/directory/202608/20260823-learning-log.html
- 0822 七習慣：https://copyshae.github.io/hello-world/directory/apps/habits-7/
- 0821 14樣：https://copyshae.github.io/hello-world/directory/apps/daily-14/
- 0820 環境教育（保留）：https://copyshae.github.io/hello-world/directory/202608/20260820-learning-log.html

（手機免開電腦也可用 dash 鏡射：https://copyshae.github.io/-/directory/202608/）
