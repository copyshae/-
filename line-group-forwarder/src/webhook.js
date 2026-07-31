import { upsertGroup, removeGroup, getTargetsForHub } from "./store.js";
import {
  fetchGroupSummary,
  buildForwardMessages,
  pushToGroups,
} from "./line.js";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import crypto from "node:crypto";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const mediaDir = path.join(__dirname, "..", "data", "media");

function ensureMediaDir() {
  if (!fs.existsSync(mediaDir)) fs.mkdirSync(mediaDir, { recursive: true });
}

/**
 * Save LINE message binary and return public URLs for push message.
 */
async function hostBinaryMessage({ message, blobClient, publicBaseUrl }) {
  if (!publicBaseUrl) return null;
  ensureMediaDir();
  const stream = await blobClient.getMessageContent(message.id);
  const chunks = [];
  for await (const chunk of stream) chunks.push(chunk);
  const buffer = Buffer.concat(chunks);
  const id = crypto.randomBytes(16).toString("hex");
  const ext =
    message.type === "image"
      ? "jpg"
      : message.type === "video"
        ? "mp4"
        : message.type === "audio"
          ? "m4a"
          : "bin";
  const filename = `${id}.${ext}`;
  fs.writeFileSync(path.join(mediaDir, filename), buffer);

  // Auto-clean after 1 hour
  setTimeout(
    () => {
      try {
        fs.unlinkSync(path.join(mediaDir, filename));
      } catch {
        /* ignore */
      }
    },
    60 * 60 * 1000
  );

  const url = `${publicBaseUrl.replace(/\/$/, "")}/media/${filename}`;
  // LINE 要求 image/video 的 URL 必須是 HTTPS，且 video 需另附 JPEG 預覽圖。
  // 無物件儲存時：圖片可完整轉發；影片／語音改以文字提示。
  if (message.type === "image") {
    return [
      {
        type: "image",
        originalContentUrl: url,
        previewImageUrl: url,
      },
    ];
  }
  return null;
}

export function createWebhookHandler({ client, blobClient, publicBaseUrl }) {
  return async function handleEvents(events) {
    for (const event of events) {
      try {
        await handleOne(event, { client, blobClient, publicBaseUrl });
      } catch (err) {
        console.error("handle event error:", err);
      }
    }
  };
}

async function handleOne(event, { client, blobClient, publicBaseUrl }) {
  const source = event.source || {};

  if (event.type === "join" && source.groupId) {
    const summary = await fetchGroupSummary(client, source.groupId);
    upsertGroup(summary);
    try {
      await client.replyMessage({
        replyToken: event.replyToken,
        messages: [
          {
            type: "text",
            text: "已加入此群組。請到管理後台把某個群組設成「群發群組」，並勾選要自動轉發的目標群組。",
          },
        ],
      });
    } catch {
      /* ignore */
    }
    return;
  }

  if (event.type === "leave" && source.groupId) {
    removeGroup(source.groupId);
    return;
  }

  if (event.type === "message" && source.groupId) {
    // Refresh group meta opportunistically
    const summary = await fetchGroupSummary(client, source.groupId);
    upsertGroup(summary);

    const targets = getTargetsForHub(source.groupId);
    if (!targets.length) return;

    // Avoid forwarding bot's own messages (LINE usually doesn't send those)
    let messages = [];
    if (["image", "video", "audio"].includes(event.message?.type)) {
      try {
        const hosted = await hostBinaryMessage({
          message: event.message,
          blobClient,
          publicBaseUrl,
        });
        messages = hosted || (await buildForwardMessages(event, blobClient));
      } catch (err) {
        console.error("binary host failed:", err);
        messages = await buildForwardMessages(event, blobClient);
      }
    } else {
      messages = await buildForwardMessages(event, blobClient);
    }

    if (!messages.length) return;

    // Prefix text with source hint for clarity
    if (messages[0]?.type === "text" && !messages[0].text.startsWith("【")) {
      const fromName = summary.name || "群發群組";
      messages = [
        {
          type: "text",
          text: `【轉自：${fromName}】\n${messages[0].text}`,
        },
        ...messages.slice(1),
      ];
    }

    const results = await pushToGroups(client, targets, messages);
    console.log("forward results:", results);
  }
}

export { mediaDir };
