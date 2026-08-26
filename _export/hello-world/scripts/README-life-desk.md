# 靈命七習慣｜電腦版視窗程式

## 首要宗旨

身心靈提升、靈命持續成長

## 安裝（電腦）

```powershell
cd $env:USERPROFILE\Desktop\hello-world
powershell -ExecutionPolicy Bypass -File .\scripts\install-life-desk.ps1
```

或從 dash 倉庫 raw 安裝：

```powershell
$dir = Join-Path $env:USERPROFILE 'Desktop\靈命七習慣程式'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url = 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/scripts/life-desk-app.ps1'
Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir 'life-desk-app.ps1') -UseBasicParsing
$url2 = 'https://raw.githubusercontent.com/copyshae/-/main/_export/hello-world/scripts/install-life-desk.ps1'
Invoke-WebRequest -Uri $url2 -OutFile (Join-Path $env:TEMP 'install-life-desk.ps1') -UseBasicParsing
powershell -ExecutionPolicy Bypass -File (Join-Path $env:TEMP 'install-life-desk.ps1')
```

雙擊桌面：**靈命七習慣.cmd**

## 功能

| 功能 | 說明 |
|------|------|
| 電腦視窗 | Edge／Chrome 應用模式開啟，含 14樣＋七習慣分頁 |
| 與手機同步 | 雙方匯出／匯入 JSON（檔名含今日日期） |
| 今日存檔格式 | JSON、CSV、TXT、MD、Word(.doc)、PDF（另存）、PNG、JPG |
| 語音讀誦 | 電腦版／手機版皆可「讀誦今日紀錄」；可選男聲／女聲多種並試聽 |

## 手機網址

- 電腦殼頁：https://copyshae.github.io/-/life-desk/
- 14樣：https://copyshae.github.io/-/daily-14/
- 七習慣：https://copyshae.github.io/-/habits-7/
