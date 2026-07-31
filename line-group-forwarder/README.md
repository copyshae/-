# LINE 群組群發轉發

把某個 LINE 群組設成「群發群組」：訊息丟進去後，自動轉發到你勾選的多個目標群組。

> **重要限制（LINE 平台規則）**  
> 這不是去操控你手機上的一般 LINE App，而是透過 **LINE 官方帳號（Messaging API）** 合法轉發。  
> 我無法直接在你的實體手機上安裝 App；請用下方方式部署後，用手機瀏覽器開啟管理後台（可加到主畫面當捷徑）。

## 你會得到什麼

1. **Webhook 機器人**：官方帳號在「群發群組」收到訊息 → 自動 push 到勾選的群組  
2. **手機友善管理後台**：選來源群組、勾選目標群組、儲存規則  
3. **支援類型**：文字、貼圖、位置、圖片（需 HTTPS 公開網址）；影片／語音目前改以文字提示

## 使用前準備

1. 到 [LINE Developers](https://developers.line.biz/) 建立 Provider → Messaging API Channel  
2. 建立或連結 **LINE 官方帳號**  
3. 在 Channel 的 Messaging API 分頁：
   - 取得 **Channel secret**、**Channel access token**
   - 開啟 **Allow bot to join group chats**（允許加入群組）
   - 關閉「自動回應訊息」等會搶答的功能（建議）
4. 準備一個可公開 HTTPS 的主機（例如 Railway、Render、Fly.io、Cloudflare Tunnel + 家用電腦）

> LINE 規定：**同一個群組同時間只能有一個官方帳號**。請把本 Bot 加進「群發群組」與所有目標群組。

## 快速啟動

```bash
cd line-group-forwarder
cp .env.example .env
# 編輯 .env 填入金鑰與密碼
npm install
npm start
```

`.env` 範例：

```env
CHANNEL_SECRET=...
CHANNEL_ACCESS_TOKEN=...
ADMIN_PASSWORD=請改成強密碼
PORT=3000
PUBLIC_BASE_URL=https://你的網域
```

在 LINE Developers Console 把 Webhook URL 設成：

```text
https://你的網域/webhook
```

啟用 Use webhook，並用 Verify 測試。

## 操作流程（手機可完成）

1. 用手機瀏覽器開啟 `https://你的網域/`  
2. 輸入管理密碼進入後台  
3. 在 LINE 裡把官方帳號 **邀請進**：
   - 一個「群發／中繼」群組  
   - 所有要收到訊息的目標群組  
4. 回後台按「重新整理」，選來源群組，勾選目標，按「儲存規則」  
5. 之後只要把資料 **分享／貼到群發群組**，Bot 會自動轉發到勾選的群組

## 為什麼不能做成「純手機 App 監控一般 LINE」？

LINE 不開放一般個人帳號讀取／代發群組訊息的 API。若用無障礙服務或腳本去點 LINE App，會違反服務條款且不穩定。  
**官方帳號 Bot** 才是可長期維護的做法。

## 目錄說明

```text
line-group-forwarder/
  src/           伺服器與 webhook
  public/        手機友善管理介面
  data/          執行後產生的設定與暫存（已 gitignore）
  .env.example   環境變數範本
```

## 注意事項

- 轉發訊息會消耗官方帳號的月訊息額度  
- 轉發內容會顯示為「官方帳號發送」，不是你的個人帳號  
- `PUBLIC_BASE_URL` 必須是 HTTPS，圖片轉發才會成功  
- 請勿把 `.env`、token 提交到 Git
