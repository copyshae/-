# 習作台：手機主畫面可見性（待套用到 hello-world）

此 Cloud Agent 只能寫入 `copyshae/-`，**無法直接推送** `copyshae/hello-world`。
下列檔案已依 hello-world 路徑備好，請在有 hello-world 寫入權限的電腦套用後，GitHub Pages 才會更新。

**現況說明（立刻可用）：**

- 線上網址：https://copyshae.github.io/hello-world/directory/apps/teacher-desk/
- 這不是 App Store／Play 商店程式
- 主畫面名稱是 **「習作台」**
- iPhone：Safari → 分享 → **加入主畫面**
- Android：Chrome → 選單 → **加到主畫面**
- 勿在 LINE／Cursor 內建瀏覽器裡找「加入主畫面」

## 將寫入的檔案

| 匯出路徑 | 目標（hello-world） |
|----------|---------------------|
| `directory/apps/teacher-desk/index.html` | 更新（加入主畫面引導＋安裝按鈕） |
| `directory/apps/teacher-desk/manifest.json` | 更新（圖示 purpose 分離） |
| `directory/apps/teacher-desk/sw.js` | 更新（快取 v4） |
| `directory/apps/teacher-desk/share.html` | 同步 |
| `directory/apps/teacher-desk/icon-*.png` | 同步 |
| `directory/index.html` | 更新（目錄標註可加到主畫面） |
| `scripts/README-teacher-desk.md` | 更新（手機找不到圖示排除） |

## Windows 一套指令

在 **Desktop\hello-world** 開 PowerShell：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
git pull origin master
$base = "https://raw.githubusercontent.com/copyshae/-/cursor/teacher-desk-mobile-visibility-fc5d/_export/hello-world"
New-Item -ItemType Directory -Force -Path directory\apps\teacher-desk, scripts | Out-Null
Invoke-WebRequest "$base/directory/apps/teacher-desk/index.html" -OutFile "directory\apps\teacher-desk\index.html"
Invoke-WebRequest "$base/directory/apps/teacher-desk/manifest.json" -OutFile "directory\apps\teacher-desk\manifest.json"
Invoke-WebRequest "$base/directory/apps/teacher-desk/sw.js" -OutFile "directory\apps\teacher-desk\sw.js"
Invoke-WebRequest "$base/directory/apps/teacher-desk/share.html" -OutFile "directory\apps\teacher-desk\share.html"
Invoke-WebRequest "$base/directory/apps/teacher-desk/icon-180.png" -OutFile "directory\apps\teacher-desk\icon-180.png"
Invoke-WebRequest "$base/directory/apps/teacher-desk/icon-192.png" -OutFile "directory\apps\teacher-desk\icon-192.png"
Invoke-WebRequest "$base/directory/apps/teacher-desk/icon-512.png" -OutFile "directory\apps\teacher-desk\icon-512.png"
Invoke-WebRequest "$base/directory/index.html" -OutFile "directory\index.html"
Invoke-WebRequest "$base/scripts/README-teacher-desk.md" -OutFile "scripts\README-teacher-desk.md"
git add directory/apps/teacher-desk directory/index.html scripts/README-teacher-desk.md
git commit -m "加強習作台手機可見性：加入主畫面引導與安裝提示。"
git push origin master
```

或在此倉庫根目錄：

```powershell
powershell -ExecutionPolicy Bypass -File .\_export\hello-world\apply-to-hello-world.ps1
```

套用後請用 Safari／Chrome **重新打開**習作台頁，再執行一次「加入主畫面」。
