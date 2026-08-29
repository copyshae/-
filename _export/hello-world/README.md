# 匯出最終包｜學習日誌 0824–0829（2026-08-29）

## 兩支 App 分開（不要混）

| App | 網址 | 用途 |
|-----|------|------|
| **七個好習慣分類** | https://copyshae.github.io/-/habits-7/ | 人事時地物 → 七習慣＋時間象限；康軒國一上課建議 |
| **每日14樣功課** | https://copyshae.github.io/-/daily-14/ | 14 項功課勾選備忘錄（維持原樣） |
| **弟子規 41 集** | https://copyshae.github.io/-/dizigui-41/ | 蔡禮旭《細講弟子規》1–41 集；1.75／2 倍速 |
| **盛德歌曲 KTV** | https://copyshae.github.io/-/taiyang-music/ | 連播、KTV 大字幕、伴唱、評分、練唱紀錄 |

習作工具主頁：https://copyshae.github.io/-/

---

本包另含 hello-world 匯出（學習日誌 **0821–0829**）。**只有要同步 hello-world 學習日誌站時**才需在電腦跑下方腳本。

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

- 最新日誌 0829：https://copyshae.github.io/hello-world/directory/202608/20260829-learning-log.html
- 0824 弟子規：https://copyshae.github.io/hello-world/directory/apps/dizigui-41/
- 0825–0829 盛德歌曲 KTV：https://copyshae.github.io/hello-world/directory/apps/taiyang-music/
- 0823 看書文件：https://copyshae.github.io/hello-world/directory/apps/doc-reader/

（手機免開電腦也可用 dash 鏡射：https://copyshae.github.io/-/directory/202608/）

## 手機 Cursor 推日誌／連日誌

1. 手機 Cursor 開倉庫 **copyshae/-**，新開對話。
2. 說 **連日誌**、**日誌首頁**、**推日誌**（可加日期，如 `推日誌 0830`）。
3. Agent push 到 main 後，CI 約 1–2 分鐘同步 dash Pages。
4. 快捷詞說明：https://copyshae.github.io/-/directory/logs/prompts/
5. GitHub 手機 App 可手動跑 Actions → **推學習日誌（手機可跑）**。

hello-world 正式站：在 copyshae/- 的 Settings → Secrets 設 **HELLO_WORLD_TOKEN**，或電腦雙擊 `推學習日誌.bat`。
