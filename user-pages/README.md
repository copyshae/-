# GitHub 根網域導向（copyshae.github.io → 習作工具）

## 問題
只開 `https://copyshae.github.io/` 會 **404**，因為主站部署在倉庫 `-` 的 `docs/`，網址是：

- **習作工具**：https://copyshae.github.io/-/
- **新聞主播**：https://copyshae.github.io/-/news-anchor/

## 解法（只需做一次）
在 GitHub 建立 **`copyshae.github.io`** 使用者 Pages 倉庫，內容用本目錄的 `index.html`：

```bash
# 本機（需有 copyshae 帳號權限）
cd /path/to/empty
cp /path/to/this-repo/user-pages/index.html .
git init && git add index.html
git commit -m "根網域導向新聞主播"
gh repo create copyshae.github.io --public --source=. --push
```

或 GitHub 網頁：**New repository** → 名稱 **`copyshae.github.io`** → 上傳 `user-pages/index.html` → Settings → Pages → Deploy from branch `main` / root。

完成後，開根網域會自動跳到新聞主播。

## 已在本站做的
- `docs/404.html`：`-/` 底下打錯路徑時顯示正確連結
