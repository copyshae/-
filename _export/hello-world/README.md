# 匯出：習作台＋習作批改（Gemini 自動批）

此 Cloud Agent 只能寫入 `copyshae/-`，**無法直接推送** `copyshae/hello-world`。

## 本包內容

- `directory/apps/teacher-desk/` — 手機習作台（繁中）
- `directory/apps/math-grader/` — 手機批改輔助
- `scripts/math-homework-grader-app.ps1` — Gemini 自動批（有答案對照／無答案直接 AI）
- `scripts/pull-export-from-dash-repo.ps1` — **在桌面 hello-world 一鍵下載＋安裝**
- `scripts/install-desktop-apps.ps1`、習作台腳本、rules

## 套用（推薦｜人在桌面\hello-world）

若出現「找不到 `_export\...`」或 `install-desktop-apps.ps1` 字串錯誤，在 PowerShell **整段貼上**：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$dir = Join-Path $PWD 'scripts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url = 'https://raw.githubusercontent.com/copyshae/-/cursor/teacher-desk-scan-parity-c36c/_export/hello-world/scripts/pull-export-from-dash-repo.ps1'
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'pull-export-from-dash-repo.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File .\scripts\pull-export-from-dash-repo.ps1
```

完成後：**關掉舊的習作批改** → 再雙擊桌面 `習作批改.vbs` → Gemini金鑰 → Gemini自動批。

## 套用（若已 clone 了 `-` 倉庫）

```powershell
cd <copyshae/- 倉庫>
git pull
git checkout cursor/teacher-desk-scan-parity-c36c
powershell -ExecutionPolicy Bypass -File .\_export\hello-world\apply-to-hello-world.ps1
cd $env:USERPROFILE\Desktop\hello-world
powershell -ExecutionPolicy Bypass -File .\scripts\install-desktop-apps.ps1
```

注意：`_export\...` 只存在於 **`-` 倉庫**，不在 `Desktop\hello-world` 裡。
