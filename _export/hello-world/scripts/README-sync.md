# 兩台電腦＋手機：完整同步指南（含日誌全部功能）

功能總表見 **`FEATURES-FROM-LOGS.md`**（0803／08017／工作日誌彙整）。

## 一份檔打通三端

傳 **`0803同步包.json`**（建議）：

- 習作批改進度（程度、批改狀態）
- **練習回傳循環歷程日誌**（rounds／分數／回饋／下一輪）
- 最新練習文案
- 習作台班級狀態（發送／回傳／期限／管道）

也可分傳：`習作批改進度.json`＋`班級狀態.json`。

權威：程度←批改；發送／回傳←習作台；掃描本體用 `05-R01.pdf` 傳檔。

## 日常（同一手機、正式站）

1. 批改自動批 → 程度寫入習作台  
2. 批完後續：模板／發放訊息／回傳循環（存歷程）  
3. 習作台標未發／已發／待回；複製群發／回傳說明  

正式網址：  
https://copyshae.github.io/hello-world/directory/apps/math-grader/  
https://copyshae.github.io/hello-world/directory/apps/teacher-desk/

## 換機／兩台電腦

1. 任一端「匯出0803同步包」  
2. 傳到另一端「匯入0803同步包」  
3. 電腦另跑 `install-desktop-apps.ps1`（見 08017）；金鑰用密碼管理器還原  

## 桌面按鈕

| App | 按鈕 |
|-----|------|
| 習作批改 | 同步程度→習作台；匯出進度；匯出／匯入0803同步包；練習歷程夾 |
| 習作台 | 管道／篩選／回傳說明；從批改進度匯入程度；匯出／匯入0803同步包 |

## 套用

```powershell
cd $env:USERPROFILE\Desktop\hello-world
$env:DASH_EXPORT_BRANCH = 'cursor/sync-desk-grader-devices-2663'
# pull-export 後：
powershell -ExecutionPolicy Bypass -File .\scripts\install-desktop-apps.ps1
```

手機強制重新整理（SW：math-grader-v16、teacher-desk-v7）。
