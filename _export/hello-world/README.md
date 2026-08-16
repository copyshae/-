# 20260801 學習日誌匯出（待套用到 hello-world）

此 Cloud Agent 目前只能寫入 `copyshae/-`，**無法直接推送到** `copyshae/hello-world`。
下列檔案已依 hello-world 路徑備好，請在有 hello-world 寫入權限的電腦套用。

**流程、回覆、說明、commit 訊息一律使用繁體中文。**

## 將寫入的檔案

| 匯出路徑 | 目標（hello-world） |
|----------|---------------------|
| `directory/logs/20260801-learning-log.html` | 新增 |
| `directory/logs/index.html` | 更新（頂部加 20260801） |
| `directory/index.html` | 更新（加 202608 連結） |
| `.cursor/skills/push-learning-log/SKILL.md` | 更新（全程繁體中文） |
| `.cursor/rules/push-learning-log.mdc` | 更新 |
| `directory/logs/prompts/push-learning-log.md` | 更新 |
| `install-push-log-shortcut.ps1` | 更新（繁體中文提示） |

線上目標：https://copyshae.github.io/hello-world/directory/logs/20260801-learning-log.html

## Windows 一套指令

在 **Desktop\hello-world**（或你的 clone）開 PowerShell：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
git pull origin master
$base = "https://raw.githubusercontent.com/copyshae/-/cursor/push-log-20260801-0e54/_export/hello-world"
New-Item -ItemType Directory -Force -Path directory\logs\prompts, .cursor\skills\push-learning-log, .cursor\rules | Out-Null
Invoke-WebRequest "$base/directory/logs/20260801-learning-log.html" -OutFile "directory\logs\20260801-learning-log.html"
Invoke-WebRequest "$base/directory/logs/index.html" -OutFile "directory\logs\index.html"
Invoke-WebRequest "$base/directory/index.html" -OutFile "directory\index.html"
Invoke-WebRequest "$base/.cursor/skills/push-learning-log/SKILL.md" -OutFile ".cursor\skills\push-learning-log\SKILL.md"
Invoke-WebRequest "$base/.cursor/rules/push-learning-log.mdc" -OutFile ".cursor\rules\push-learning-log.mdc"
Invoke-WebRequest "$base/directory/logs/prompts/push-learning-log.md" -OutFile "directory\logs\prompts\push-learning-log.md"
Invoke-WebRequest "$base/install-push-log-shortcut.ps1" -OutFile "install-push-log-shortcut.ps1"
git add directory/logs/20260801-learning-log.html directory/logs/index.html directory/index.html .cursor/skills/push-learning-log/SKILL.md .cursor/rules/push-learning-log.mdc directory/logs/prompts/push-learning-log.md install-push-log-shortcut.ps1
git commit -m "新增 20260801 學習日誌：LINE 轉發雛形與看診備忘歸檔；捷徑流程改繁體中文。"
git push origin master
powershell -ExecutionPolicy Bypass -File .\install-push-log-shortcut.ps1
```

## 內容大要（不含個資細節）

- LINE 官方帳號群組轉發雛形 → Draft PR https://github.com/copyshae/-/pull/3
- LINE 對話整理成個人看診備忘 → Draft PR https://github.com/copyshae/-/pull/4（細節不進公開日誌）
- 快捷詞 `推日誌`／`tui-ri-zhi`；開啟首頁可用 `連日誌首頁`
