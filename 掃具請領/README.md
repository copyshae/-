# 114 學年掃具請領（已整理）

請用瀏覽器下載，不要依賴 Cursor 右鍵下載。

## Excel（建議）
https://github.com/copyshae/-/raw/cursor/launch-efficiency-459a/掃具請領/114學年掃具請領_已整理.xlsx

## CSV（用 Excel 開）
https://github.com/copyshae/-/raw/cursor/launch-efficiency-459a/掃具請領/114學年掃具請領_已整理.csv

下載後放到 `F:\test`，若要蓋原檔，改名為 `114學年掃具請領.xlsx`。

## 本機一鍵存回 F:（學習日誌 20260717 復原）

在 **Windows PowerShell**（不是 Cursor 雲端）貼上：

```powershell
irm https://raw.githubusercontent.com/copyshae/-/cursor/launch-efficiency-459a/掃具請領/restore-20260717-to-F.ps1 | iex
```

會建立 `F:\桌面歸檔` 等資料夾，並把已整理 Excel 下載到 `F:\test`。
