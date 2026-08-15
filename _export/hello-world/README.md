# 匯出：習作台＋習作批改（Gemini 自動批修復）

此 Cloud Agent 只能寫入 `copyshae/-`，**無法直接推送** `copyshae/hello-world`。

## 本包內容

- `directory/apps/teacher-desk/` — 手機習作台（繁中）
- `directory/apps/math-grader/` — 手機批改輔助（網頁仍手動）
- `scripts/math-homework-grader-app.ps1` — **修復 Gemini 自動批閱**
  - 模型改 **gemini-2.5-flash**（2.0-flash 已下線）
  - 預設模式 **API 自動批**（不是網頁手動）
- `scripts/teacher-desk-*`、`install-desktop-apps.ps1`、rules

## 為何「Gemini 無法自動接手批閱」

1. 選了「網頁批閱」→ 只開瀏覽器，要自己貼＝**非自動**  
2. 未設定 AI Studio **API 金鑰**（網頁 Pro 訂閱不夠）  
3. 舊版打 `gemini-2.0-flash` → **2026-06 已下線** → 自動失敗  

## 套用（電腦）

```powershell
cd <此倉庫>
git pull
powershell -ExecutionPolicy Bypass -File .\_export\hello-world\apply-to-hello-world.ps1
cd $env:USERPROFILE\Desktop\hello-world
powershell -ExecutionPolicy Bypass -File .\scripts\install-desktop-apps.ps1
```

然後開 **習作批改** →「Gemini金鑰」→ 選 **請 Gemini 自動批閱（API＝真正自動）** →「開始批此生」。
