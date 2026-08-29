---
name: push-learning-log
description: >-
  hello-world 學習日誌捷徑：推送工作大要，或開啟線上學習日誌／學習日誌首頁。
  觸發「推日誌」「上日誌」「收工推日誌」「工作大要推 hello-world」「推到 github hello world」、
  「連日誌」「連上學習日誌」「開日誌」「日誌首頁」「學習日誌首頁」「開首頁」「裝快捷詞」時立刻使用。
  桌面 Cursor 與手機 Cursor（Cloud Agent）都適用。
---

# 學習日誌捷徑（hello-world）

手機 Cursor 是 **Cloud Agent**，必須靠倉庫內的 `.cursor/rules` 與 `.cursor/skills`。
開 **copyshae/-** 倉庫說話即可；也可輸入 `/push-learning-log`。

## A｜開啟網頁（只開連結、不改檔）

把網址用 Markdown 連結回給使用者。**優先 dash 鏡射**（手機免開電腦）：

| 短語 | 開啟 |
|------|------|
| `連日誌`／`連上學習日誌`／`開日誌` | [0820–0829 列表](https://copyshae.github.io/-/directory/202608/) |
| `日誌首頁`／`學習日誌首頁`／`開首頁` | [學習日誌首頁](https://copyshae.github.io/-/directory/) |
| `最新日誌` | [0829](https://copyshae.github.io/-/directory/202608/20260829-learning-log.html) 或 [learning-log.html](https://copyshae.github.io/-/learning-log.html) |
| 快捷詞說明（手機長按複製） | [prompts 頁](https://copyshae.github.io/-/directory/logs/prompts/) |

hello-world 正式站（需 PAT 或電腦同步後才最新）：https://copyshae.github.io/hello-world/directory/202608/

Windows 桌面例：`Start-Process "https://…"`。Cloud Agent／手機不要用 `Start-Process`。

## B｜安裝／更新快捷詞

### 桌面 Windows

使用者說 `裝快捷詞` 時：

1. 找到 hello-world 倉庫根目錄（優先 `%USERPROFILE%\Desktop\hello-world`）。
2. 執行：`powershell -ExecutionPolicy Bypass -File .\install-push-log-shortcut.ps1`
3. 回覆安裝完成，提醒「重新開一個 Cursor 對話」。

### 手機 Cursor／Cloud Agent

不必跑 PowerShell。確認本對話已載入本 skill／規則即可。回覆：

- 請在手機 Cursor **開倉庫 copyshae/-** 再新開對話。
- 直接打 `推日誌`、`連日誌`、`日誌首頁`。
- 若開的是別的倉庫：把下方短句貼到 Cursor 設定 → Rules → User Rules：

```
說「推日誌」「連日誌」「日誌首頁」「裝快捷詞」時，依 skill push-learning-log 執行（hello-world 學習日誌）。手機 Cursor 同樣適用。
```

## C｜推送工作大要

### 觸發短語

- `推日誌`／`上日誌`／`收工推日誌`
- `工作大要推 hello-world`／`推到 github hello world`
- 可加日期：`推日誌 0830`

### 日期

- 未指定：用**當天**（台北日曆）。
- 指定月日則用該日（當年）。
- 該日檔已存在就**更新同一檔**，不要另開「0830-二」。
- `20260819` 起放 `directory/202608/`，**不要**再寫進 `directory/logs/`（202607 相容路徑）。

檔名：`YYYYMMDD-learning-log.html`。

### 環境一：Cloud Agent／手機（本倉庫 copyshae/-）

1. 讀 `工作日誌.md` 與本對話，只寫工作大要。勿寫密碼、vault、個資、學生姓名。
2. HTML 對齊既有篇（CSS、nav、分節、線上連結）；nav 連回 `directory/` 與該月 `index.html`。
3. 寫入 `_export/hello-world/directory/YYYYMM/YYYYMMDD-learning-log.html`。
4. 更新該月 `_export/hello-world/directory/YYYYMM/index.html` 最上方一筆（由新到舊）。
5. 若是新月份，在 `_export/hello-world/directory/index.html` 列表最上方加該月連結。
6. 同步在 `工作日誌.md` 補同一天重點。
7. Commit＋push **本倉庫 main**。
8. **不要** `git push` `copyshae/hello-world`（Cloud Agent 會 403）。
9. push 後 CI「鏡射學習日誌到 Pages」會自動同步 dash 鏡射；約 1–2 分鐘後可開：
   - https://copyshae.github.io/-/directory/YYYYMM/YYYYMMDD-learning-log.html
10. 若需立刻重跑鏡射：`gh workflow run mirror-learning-log-pages.yml --ref main`
11. GitHub 手機 App 也可：Actions → **推學習日誌（手機可跑）** → Run workflow
12. hello-world 正式站：在 repo Settings → Secrets 設 **HELLO_WORLD_TOKEN**（hello-world 的 PAT，repo 權限）後 CI 會代推；或請使用者在電腦跑 `推學習日誌.bat`

### 環境二：桌面且已有 hello-world

1. 本機倉庫：`%USERPROFILE%\Desktop\hello-world`；先 `git pull`。
2. 依日期寫入 `directory/YYYYMM/`；更新該月 `index.html`。
3. 或跑 `_export/hello-world/scripts/push-learning-logs-only.ps1` 只推日誌。
4. Commit＋push `origin master`。
5. 回覆線上連結（dash 與 hello-world 各一）。

### Commit 訊息

- 本倉庫（dash）：繁中，例 `學習日誌：20260830 …`
- hello-world：`Add YYYYMMDD learning log: …`

### 機密

不要提交 `.env`、token、`auth.json`、金鑰、學生姓名。
