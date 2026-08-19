# 114 學年掃具請領（已整理）

請用瀏覽器下載，不要依賴 Cursor 右鍵下載。

## Excel（建議）
https://github.com/copyshae/-/raw/cursor/launch-efficiency-459a/掃具請領/114學年掃具請領_已整理.xlsx

## CSV（用 Excel 開）
https://github.com/copyshae/-/raw/cursor/launch-efficiency-459a/掃具請領/114學年掃具請領_已整理.csv

下載後放到「下載」資料夾或你指定的原檔資料夾。**不要**再自動搬到大容量碟歸檔夾。

## 復原 20260717（只搬回原位置，不再設歸檔到大容量碟）

當天曾把檔案搬到 `桌面歸檔／下載歸檔／文件歸檔／圖片歸檔`。若要搬回系統原資料夾，在本機 PowerShell：

```powershell
$env:UNDO_ARCHIVE="是"; irm https://raw.githubusercontent.com/copyshae/-/cursor/launch-efficiency-459a/掃具請領/undo-20260717-archive.ps1 | iex
```

若停在「請輸入是」沒反應：注音打完「是」後要**再按 Enter**（有時兩次）。或用上面這行，不必再問。

**已取消**：建立 `F:\桌面歸檔` 等、把下載／文件／圖片直接搬到大容量碟的腳本不再使用。
