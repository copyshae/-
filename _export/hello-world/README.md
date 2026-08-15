# 習作台：桌面 .vbs／.cmd 開不起來（待套用到 hello-world）

此 Cloud Agent 只能寫入 `copyshae/-`，**無法直接推送** `copyshae/hello-world`。

## 原因

舊版 `install-teacher-desk.ps1` 用 `Set-Content -Encoding ASCII` 寫入含中文路徑的 `.cmd`／`.vbs`，路徑變成 `?????`：

- `.vbs`：找不到要啟動的檔 → 好像沒反應
- `.cmd`：PowerShell 找不到腳本 → 視窗一閃就關閉

## 立刻修復（本機）

在 **Desktop\hello-world** 開 PowerShell（套用本分支匯出後）：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
git pull origin master
# 若尚未把本 PR 匯出套用到 hello-world，先跑 apply 或手動下載 scripts
powershell -ExecutionPolicy Bypass -File .\scripts\install-teacher-desk.ps1
```

然後雙擊桌面 **`TeacherDesk-start.cmd`**（不要用壞掉的舊檔）。

## 修正重點

- 程式／資料改用英文路徑：`TeacherDeskApp`、`TeacherDeskData`
- `.cmd`／`.vbs` **內容純 ASCII**，不再被編碼弄壞
- 啟動前檢查腳本是否存在；失敗會 `pause` 並寫 `TeacherDesk-error.txt`
- 自動從舊資料夾 `習作台資料` 遷移班級狀態

## 將寫入的檔案

| 匯出路徑 | 說明 |
|----------|------|
| `scripts/install-teacher-desk.ps1` | 新啟動器安裝 |
| `scripts/teacher-desk-app.ps1` | 預設資料夾／錯誤檔名 |
| `scripts/install-desktop-apps.ps1` | 提示改推 cmd |
| `scripts/README-teacher-desk.md` | 說明 |

另含先前的手機 PWA 可見性檔案（`directory/apps/teacher-desk/*`）。

## Windows 一套指令（從本分支 raw 拉）

```powershell
cd $env:USERPROFILE\Desktop\hello-world
git pull origin master
$base = "https://raw.githubusercontent.com/copyshae/-/cursor/teacher-desk-mobile-visibility-fc5d/_export/hello-world"
New-Item -ItemType Directory -Force -Path scripts | Out-Null
Invoke-WebRequest "$base/scripts/install-teacher-desk.ps1" -OutFile "scripts\install-teacher-desk.ps1"
Invoke-WebRequest "$base/scripts/teacher-desk-app.ps1" -OutFile "scripts\teacher-desk-app.ps1"
Invoke-WebRequest "$base/scripts/install-desktop-apps.ps1" -OutFile "scripts\install-desktop-apps.ps1"
Invoke-WebRequest "$base/scripts/README-teacher-desk.md" -OutFile "scripts\README-teacher-desk.md"
git add scripts/install-teacher-desk.ps1 scripts/teacher-desk-app.ps1 scripts/install-desktop-apps.ps1 scripts/README-teacher-desk.md
git commit -m "修復習作台桌面啟動：.cmd／.vbs 改用 ASCII 路徑。"
git push origin master
powershell -ExecutionPolicy Bypass -File .\scripts\install-teacher-desk.ps1
```

或：

```powershell
powershell -ExecutionPolicy Bypass -File .\_export\hello-world\apply-to-hello-world.ps1
```
