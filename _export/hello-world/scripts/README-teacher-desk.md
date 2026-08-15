# 習作台｜老師掌握與發送（繁體中文）

桌面視窗與 iPhone 網頁 App 皆為**繁體中文介面**。功能：程度／發送狀態、篩選、發放與回傳管道、LINE 文案、批次改狀態、班級資料互通、掃描匯入。只用座號，不存姓名。

## 桌面安裝（一定要跑）

```powershell
cd $env:USERPROFILE\Desktop\hello-world
git pull origin master
powershell -ExecutionPolicy Bypass -File .\scripts\install-desktop-apps.ps1
```

桌面捷徑：
- **習作台.vbs**
- **習作批改.vbs**（若一併安裝）

資料夾：
- `桌面\習作台程式\`
- `桌面\習作台資料\`（班級狀態.json、掃描匯入）

## 手機（不是 App Store）

網址：https://copyshae.github.io/hello-world/directory/apps/teacher-desk/

主畫面圖示名稱：**習作台**（不是 teacher-desk）

### iPhone

1. 用 **Safari** 打開上方網址（不要用 LINE／Cursor 內建瀏覽器）
2. 點底部分享 → **加入主畫面**
3. 回到桌面找綠色圖示「習作台」

### Android

1. 用 **Chrome** 打開上方網址
2. 選單 → **加到主畫面**（或頁面上的「加到主畫面」按鈕）
3. 回到桌面找「習作台」

### 為什麼手機上沒看到？

| 情況 | 作法 |
|------|------|
| 還沒加入主畫面 | 依上面步驟加一次 |
| 在 App Store／Play 商店找 | 找不到是正常的；這是網頁 App |
| 圖示名稱不對 | 找「習作台」，不是英文名 |
| 用內建瀏覽器開啟 | 改用 Safari／Chrome 再開一次再加入 |

## 手機 ↔ 電腦同步

一端「匯出班級資料」→ AirDrop／雲端傳檔 → 另一端「匯入班級資料」
