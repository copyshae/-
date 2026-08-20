# 快捷提示詞｜學習日誌（桌面／手機 Cursor）

在 Cursor 對話直接輸入短語即可。**手機 Cursor**（Cloud Agent）請開倉庫 `copyshae/-` 或已套用的 `hello-world`。

線上本頁（套用後）：https://copyshae.github.io/hello-world/directory/logs/prompts/

## 開啟網頁

| 短語 | 開啟 |
|------|------|
| `連日誌`／`連上學習日誌`／`開日誌` | [當月列表 202608](https://copyshae.github.io/hello-world/directory/202608/)（七月仍在 [logs](https://copyshae.github.io/hello-world/directory/logs/)） |
| `日誌首頁`／`學習日誌首頁`／`開首頁` | [學習日誌首頁](https://copyshae.github.io/hello-world/directory/) |

## 安裝／更新快捷詞

| 短語 | 用途 |
|------|------|
| `裝快捷詞` | **桌面**：執行安裝腳本，把全域快捷詞更新到本機 Cursor。**手機**：不必跑，新開對話即可。 |

## 推送工作大要

| 短語 | 用途 |
|------|------|
| `推日誌` | 今日日期、本對話工作大要 |
| `上日誌` | 同上 |
| `收工推日誌` | 收工時用 |
| `推日誌 0727` | 指定月日（當年） |
| `工作大要推 hello-world` | 完整說法 |

寫入：https://github.com/copyshae/hello-world

- `202607` → `directory/logs/`
- `202608` 起 → `directory/YYYYMM/`（例：`directory/202608/`）

手機／Cloud Agent 先寫 `copyshae/-` 的 `_export/hello-world/`，再請電腦套用；不要直接 push hello-world（會 403）。

## 手機 Cursor

1. 開 App／cursor.com/agents，倉庫選 **copyshae/-**。
2. 新開對話，打 `推日誌` 或 `連日誌`。
3. 也可打 `/push-learning-log`。
4. 若開別的倉庫：把下面貼到 Cursor 設定 → Rules → User Rules（同一帳號會同步）：

```
說「推日誌」「連日誌」「日誌首頁」「裝快捷詞」時，依 skill push-learning-log 執行（hello-world 學習日誌）。手機 Cursor 同樣適用。
```

## 換機／新電腦（Windows 做一次）

```powershell
cd <hello-world倉庫>
git pull
powershell -ExecutionPolicy Bypass -File .\install-push-log-shortcut.ps1
```

會安裝到：

- `%USERPROFILE%\.cursor\rules\push-learning-log.mdc`
- `%USERPROFILE%\.cursor\skills\push-learning-log\SKILL.md`

倉庫更新捷徑後再跑一次安裝腳本。手機不要跑這段。

## 倉庫內正式檔

- `.cursor/skills/push-learning-log/SKILL.md`
- `.cursor/rules/push-learning-log.mdc`
- `install-push-log-shortcut.ps1`
