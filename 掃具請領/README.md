# 114 學年掃具請領（已整理）

請用瀏覽器下載，不要依賴 Cursor 右鍵下載。

## Excel（建議）
https://github.com/copyshae/-/raw/cursor/launch-efficiency-459a/掃具請領/114學年掃具請領_已整理.xlsx

## CSV（用 Excel 開）
https://github.com/copyshae/-/raw/cursor/launch-efficiency-459a/掃具請領/114學年掃具請領_已整理.csv

## 你現在檔已開著：用 Excel 巨集（最快）

1. 在 Excel 按 **Alt+F11**
2. 功能表 **插入 → 模組**
3. 打開 GitHub 這頁，全選複製貼上：  
   https://raw.githubusercontent.com/copyshae/-/cursor/launch-efficiency-459a/掃具請領/SplitOtherItems.bas
4. 按 **F5** 執行 `SplitOtherItems`

會在**同一個 test 資料夾**產生 `114學年掃具請領_已整理.xlsx`（原檔不動）。

會拆出例如：氣窗擦、小垃圾桶、廁所小刷、鹽酸、肥皂、水桶、拖把桶、鋼絲絨、菜瓜布、小刷、短刷子、旋轉拖把桶，並在總計列加總。

在本機 PowerShell 貼上（不要搬到大容量碟）：

```powershell
irm https://raw.githubusercontent.com/copyshae/-/cursor/launch-efficiency-459a/掃具請領/split-desktop-test.ps1 | iex
```

會讀 `桌面\test` 的掃具請領 Excel，把「其他細項」拆成獨立欄位並統計，存成：

`桌面\test\114學年掃具請領_已整理.xlsx`

## 復原 20260717（只搬回原位置，不再設歸檔到大容量碟）

當天曾把檔案搬到 `桌面歸檔／下載歸檔／文件歸檔／圖片歸檔`。若要搬回系統原資料夾，在本機 PowerShell：

```powershell
$env:UNDO_ARCHIVE="是"; irm https://raw.githubusercontent.com/copyshae/-/cursor/launch-efficiency-459a/掃具請領/undo-20260717-archive.ps1 | iex
```

若停在「請輸入是」沒反應：注音打完「是」後要**再按 Enter**（有時兩次）。或用上面這行，不必再問。

**已取消**：建立 `F:\桌面歸檔` 等、把下載／文件／圖片直接搬到大容量碟的腳本不再使用。
