# 匯出：習作台＋習作批改（Gemini 自動批）

此 Cloud Agent 只能寫入 `copyshae/-`，**無法直接推送** `copyshae/hello-world`。

## 本包內容

- `directory/apps/teacher-desk/` — 手機習作台（繁中）
- `directory/apps/math-grader/` — **手機 Gemini API 自動批**＋進度
- `scripts/math-homework-grader-app.ps1` — 電腦 Gemini 自動批（有答案對照／無答案直接 AI）
- `scripts/pull-export-from-dash-repo.ps1` — **在桌面 hello-world 一鍵下載＋安裝**
- `scripts/install-desktop-apps.ps1`、習作台腳本、rules

## 手機自動批（解決「批改中一整天」＋加速）

正式／預覽頁需套用本包後才會更新。流程：

1. 開 [AI Studio](https://aistudio.google.com/apikey) 申請 API key（≠ 網頁 Gemini Pro）
2. 習作批改 → 貼上並**儲存金鑰**（預設「快速批」）
3. 匯入試卷（可選：正確答案；大圖會自動壓縮）→ 檔名用座號可自動對應
4. 按頂部 **一鍵連續批**（快速模式雙線並行）
5. 若卡在「批改中」：按「全部批改中改回未批」，再用自動批（不要只用「開啟 Gemini 貼上批」）

## 套用（推薦｜人在桌面\hello-world）

若出現「找不到 `_export\...`」或 `install-desktop-apps.ps1` 字串錯誤，在 PowerShell **整段貼上**：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url = 'https://raw.githubusercontent.com/copyshae/-/cursor/mobile-math-grader-auto-b582/_export/hello-world/scripts/pull-export-from-dash-repo.ps1'
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```

完成後：

- **手機**：強制重新整理／刪主畫面圖示再加入，確認標題旁說明寫「手機可真正自動批」
- **電腦**：關掉舊的習作批改 → 再雙擊 `習作批改.vbs` → Gemini金鑰 → Gemini自動批

## 套用（若已 clone 了 `-` 倉庫）

```powershell
cd <copyshae/- 倉庫>
git pull
git checkout cursor/mobile-math-grader-auto-b582
powershell -ExecutionPolicy Bypass -File .\_export\hello-world\apply-to-hello-world.ps1
cd $env:USERPROFILE\Desktop\hello-world
powershell -ExecutionPolicy Bypass -File .\scripts\install-desktop-apps.ps1
```

注意：`_export\...` 只存在於 **`-` 倉庫**，不在 `Desktop\hello-world` 裡。
