import "dotenv/config";
import express from "express";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { middleware } from "@line/bot-sdk";
import { createLineClients } from "./line.js";
import { createWebhookHandler, mediaDir } from "./webhook.js";
import {
  getConfigSnapshot,
  setRule,
  listGroups,
  upsertGroup,
} from "./store.js";
import { fetchGroupSummary } from "./line.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT || 3000);
const CHANNEL_SECRET = process.env.CHANNEL_SECRET || "";
const CHANNEL_ACCESS_TOKEN = process.env.CHANNEL_ACCESS_TOKEN || "";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "change-me";
const PUBLIC_BASE_URL = (process.env.PUBLIC_BASE_URL || "").replace(/\/$/, "");

if (!CHANNEL_SECRET || !CHANNEL_ACCESS_TOKEN) {
  console.warn(
    "[warn] CHANNEL_SECRET / CHANNEL_ACCESS_TOKEN 尚未設定。請複製 .env.example 為 .env 並填入。"
  );
}

const { client, blobClient } = createLineClients({
  channelAccessToken: CHANNEL_ACCESS_TOKEN || "dummy",
});

const handleEvents = createWebhookHandler({
  client,
  blobClient,
  publicBaseUrl: PUBLIC_BASE_URL,
});

const app = express();

app.use("/media", express.static(mediaDir));
app.use(express.static(path.join(__dirname, "..", "public")));

// LINE webhook — must use raw body verification via line middleware
app.post(
  "/webhook",
  middleware({
    channelSecret: CHANNEL_SECRET || "dummy",
  }),
  async (req, res) => {
    try {
      await handleEvents(req.body.events || []);
      res.status(200).end();
    } catch (err) {
      console.error(err);
      res.status(500).end();
    }
  }
);

app.use(express.json());

function requireAdmin(req, res, next) {
  const password = req.headers["x-admin-password"] || req.query.password;
  if (password !== ADMIN_PASSWORD) {
    return res.status(401).json({ error: "未授權：管理密碼錯誤" });
  }
  next();
}

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    hasCredentials: Boolean(CHANNEL_SECRET && CHANNEL_ACCESS_TOKEN),
    publicBaseUrl: PUBLIC_BASE_URL || null,
  });
});

app.get("/api/config", requireAdmin, (_req, res) => {
  res.json(getConfigSnapshot());
});

app.post("/api/rules", requireAdmin, (req, res) => {
  const { hubGroupId, targetGroupIds } = req.body || {};
  if (!hubGroupId) {
    return res.status(400).json({ error: "缺少 hubGroupId" });
  }
  const targets = setRule(hubGroupId, targetGroupIds || []);
  res.json({ hubGroupId, targetGroupIds: targets, config: getConfigSnapshot() });
});

app.post("/api/groups/refresh", requireAdmin, async (_req, res) => {
  const groups = listGroups();
  const updated = [];
  for (const g of groups) {
    const summary = await fetchGroupSummary(client, g.id);
    updated.push(upsertGroup(summary));
  }
  res.json({ groups: updated, config: getConfigSnapshot() });
});

app.get("*", (_req, res) => {
  res.sendFile(path.join(__dirname, "..", "public", "index.html"));
});

app.listen(PORT, () => {
  console.log(`LINE 群組群發轉發服務已啟動：http://localhost:${PORT}`);
  console.log(`Webhook URL：${PUBLIC_BASE_URL || "（請設定 PUBLIC_BASE_URL）"}/webhook`);
  console.log(`管理後台：http://localhost:${PORT}/`);
});
