# 114 學年掃具請領（已整理）

請用瀏覽器下載，不要依賴 Cursor 右鍵下載。

## Excel（建議）
https://github.com/copyshae/-/raw/cursor/launch-efficiency-459a/掃具請領/114學年掃具請領_已整理.xlsx

## CSV（用 Excel 開）
https://github.com/copyshae/-/raw/cursor/launch-efficiency-459a/掃具請領/114學年掃具請領_已整理.csv

下載後放到 `F:\test`，若要蓋原檔，改名為 `114學年掃具請領.xlsx`。

## 復原 20260717（把歸檔搬回桌面／下載／文件／圖片）

當天是把檔案搬到大容量碟的「桌面歸檔／下載歸檔／文件歸檔／圖片歸檔」。若要**復原這個結果**（搬回系統原資料夾），在本機 PowerShell：

```powershell
irm https://raw.githubusercontent.com/copyshae/-/cursor/launch-efficiency-459a/掃具請領/undo-20260717-archive.ps1 | iex
```

會先列出要搬的項目，輸入「是」才真正搬移。不會動 `私人` 資料夾。
