# 匯出：習作台強化（待套用到 hello-world）

此 Cloud Agent 只能寫入 `copyshae/-`，**無法直接推送** `copyshae/hello-world`。

## 本包內容

- `directory/apps/teacher-desk/` — 手機 PWA（檔名猜座號、PDF 提示、favicon、SW v4）
- `scripts/teacher-desk-app.ps1` — 桌面：處理掃描匯入、匯出／匯入班級資料、已發→待回
- `scripts/install-teacher-desk.ps1`、`scripts/README-teacher-desk.md`
- `.cursor/rules/teacher-desk.mdc`

## 在有 hello-world 權限的電腦執行

```powershell
cd <此倉庫>
powershell -ExecutionPolicy Bypass -File .\_export\hello-world\apply-to-hello-world.ps1
```

（需本機已有 `Desktop\hello-world`）

套用後線上頁：https://copyshae.github.io/hello-world/directory/apps/teacher-desk/

再跑一次安裝以更新桌面程式：

```powershell
cd $env:USERPROFILE\Desktop\hello-world
powershell -ExecutionPolicy Bypass -File .\scripts\install-teacher-desk.ps1
```
