# 習作台｜老師掌握與發送（繁體中文）

桌面視窗與 iPhone 網頁 App 皆為**繁體中文介面**。功能：程度／發送狀態、篩選、發放與回傳管道、LINE 文案、批次改狀態、班級資料互通、掃描匯入。只用座號，不存姓名。

## 桌面安裝／修復（一定要跑）

```powershell
cd $env:USERPROFILE\Desktop\hello-world
git pull origin master
powershell -ExecutionPolicy Bypass -File .\scripts\install-teacher-desk.ps1
```

或一併安裝批改：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-desktop-apps.ps1
```

### 啟動（請用這個）

雙擊桌面 **`TeacherDesk-start.cmd`**（最穩）

也可：`習作台.cmd`／`TeacherDesk-start.vbs`／`習作台.vbs`

| 路徑 | 說明 |
|------|------|
| `Desktop\TeacherDeskApp\` | 程式 |
| `Desktop\TeacherDeskData\` | 資料（班級狀態.json） |
| `Desktop\TeacherDesk-error.txt` | 啟動失敗時的錯誤紀錄 |
| `Desktop\習作台-啟動說明.txt` | 說明 |

### 若 `.vbs` 開不起來、`.cmd` 一閃就沒

1. **重新執行上方安裝指令**（舊版會把中文路徑寫成 `?????`）
2. 改雙擊 **`TeacherDesk-start.cmd`**
3. 若仍失敗，把桌面 `TeacherDesk-error.txt` 內容貼給 Cursor

## 手機

https://copyshae.github.io/hello-world/directory/apps/teacher-desk/

Safari → 分享 → **加入主畫面**（圖示名稱「習作台」）

## 手機 ↔ 電腦同步

一端「匯出班級資料」→ AirDrop／雲端傳檔 → 另一端「匯入班級資料」
