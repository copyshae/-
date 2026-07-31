import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataDir = path.join(__dirname, "..", "data");
const storePath = path.join(dataDir, "store.json");

const defaultStore = () => ({
  groups: {},
  // hubGroupId -> [targetGroupId, ...]
  rules: {},
  updatedAt: null,
});

function ensureDataDir() {
  if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
  }
}

function readStore() {
  ensureDataDir();
  if (!fs.existsSync(storePath)) {
    return defaultStore();
  }
  try {
    const raw = fs.readFileSync(storePath, "utf8");
    return { ...defaultStore(), ...JSON.parse(raw) };
  } catch {
    return defaultStore();
  }
}

function writeStore(store) {
  ensureDataDir();
  store.updatedAt = new Date().toISOString();
  fs.writeFileSync(storePath, JSON.stringify(store, null, 2), "utf8");
  return store;
}

export function listGroups() {
  const store = readStore();
  return Object.values(store.groups).sort((a, b) =>
    String(a.name || "").localeCompare(String(b.name || ""), "zh-Hant")
  );
}

export function upsertGroup({ id, name, pictureUrl, memberCount }) {
  const store = readStore();
  const prev = store.groups[id] || {};
  store.groups[id] = {
    id,
    name: name || prev.name || id,
    pictureUrl: pictureUrl ?? prev.pictureUrl ?? null,
    memberCount: memberCount ?? prev.memberCount ?? null,
    joinedAt: prev.joinedAt || new Date().toISOString(),
    lastSeenAt: new Date().toISOString(),
  };
  writeStore(store);
  return store.groups[id];
}

export function removeGroup(id) {
  const store = readStore();
  delete store.groups[id];
  delete store.rules[id];
  for (const hubId of Object.keys(store.rules)) {
    store.rules[hubId] = (store.rules[hubId] || []).filter((t) => t !== id);
    if (store.rules[hubId].length === 0) delete store.rules[hubId];
  }
  writeStore(store);
}

export function getRules() {
  return readStore().rules;
}

export function getTargetsForHub(hubGroupId) {
  const rules = getRules();
  return rules[hubGroupId] || [];
}

export function setRule(hubGroupId, targetGroupIds) {
  const store = readStore();
  const unique = [...new Set(targetGroupIds)].filter(
    (id) => id && id !== hubGroupId && store.groups[id]
  );
  if (unique.length === 0) {
    delete store.rules[hubGroupId];
  } else {
    store.rules[hubGroupId] = unique;
  }
  writeStore(store);
  return store.rules[hubGroupId] || [];
}

export function getConfigSnapshot() {
  const store = readStore();
  return {
    groups: listGroups(),
    rules: store.rules,
    updatedAt: store.updatedAt,
  };
}
