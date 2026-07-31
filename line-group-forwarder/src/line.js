import { messagingApi } from "@line/bot-sdk";

const { MessagingApiClient, MessagingApiBlobClient } = messagingApi;

export function createLineClients({ channelAccessToken }) {
  const client = new MessagingApiClient({ channelAccessToken });
  const blobClient = new MessagingApiBlobClient({ channelAccessToken });
  return { client, blobClient };
}

export async function fetchGroupSummary(client, groupId) {
  try {
    const summary = await client.getGroupSummary(groupId);
    let memberCount = null;
    try {
      const count = await client.getGroupMembersCount(groupId);
      memberCount = count.count;
    } catch {
      // ignore count failures
    }
    return {
      id: groupId,
      name: summary.groupName,
      pictureUrl: summary.pictureUrl || null,
      memberCount,
    };
  } catch {
    return { id: groupId, name: groupId, pictureUrl: null, memberCount: null };
  }
}

/**
 * Convert an inbound message event into push-message objects for forwarding.
 * Supports text / image / sticker / location / video / audio.
 */
export async function buildForwardMessages(event, blobClient) {
  const message = event.message;
  if (!message?.type) return [];

  switch (message.type) {
    case "text":
      return [{ type: "text", text: message.text }];
    case "sticker":
      return [
        {
          type: "sticker",
          packageId: message.packageId,
          stickerId: message.stickerId,
        },
      ];
    case "location":
      return [
        {
          type: "location",
          title: message.title || "位置",
          address: message.address || "",
          latitude: message.latitude,
          longitude: message.longitude,
        },
      ];
    case "image":
    case "video":
    case "audio": {
      // Re-send as original content URL is not exposed; use LINE content API
      // by downloading is not needed for push if we use the same messageId —
      // Messaging API requires hosted URLs for image/video/audio push.
      // Practical approach: reply-style isn't available across groups, so we
      // send a text notice with type, OR host temporarily. For MVP without
      // object storage, forward a text placeholder and note limitation.
      // Better: use getMessageContent and data URI is not allowed by LINE.
      // So we use "image" with originalContentUrl only if we host it.
      return await forwardBinaryAsTextFallback(message);
    }
    default:
      return [
        {
          type: "text",
          text: `【自動轉發】收到不支援的訊息類型：${message.type}`,
        },
      ];
  }
}

async function forwardBinaryAsTextFallback(message) {
  const label =
    message.type === "image"
      ? "圖片"
      : message.type === "video"
        ? "影片"
        : "語音";
  return [
    {
      type: "text",
      text: `【自動轉發】來源群組有一則${label}訊息（目前版本請在來源群組查看原檔；文字／貼圖／位置可完整轉發）。`,
    },
  ];
}

export async function pushToGroups(client, groupIds, messages) {
  const results = [];
  for (const groupId of groupIds) {
    try {
      await client.pushMessage({
        to: groupId,
        messages,
      });
      results.push({ groupId, ok: true });
    } catch (err) {
      results.push({
        groupId,
        ok: false,
        error: err?.message || String(err),
      });
    }
  }
  return results;
}
