const loginEl = document.getElementById("login");
const dashboardEl = document.getElementById("dashboard");
const passwordEl = document.getElementById("password");
const loginBtn = document.getElementById("loginBtn");
const loginError = document.getElementById("loginError");
const hubList = document.getElementById("hubList");
const targetList = document.getElementById("targetList");
const targetsPanel = document.getElementById("targetsPanel");
const saveBtn = document.getElementById("saveBtn");
const saveMsg = document.getElementById("saveMsg");
const refreshBtn = document.getElementById("refreshBtn");
const rulesView = document.getElementById("rulesView");

let password = localStorage.getItem("adminPassword") || "";
let config = { groups: [], rules: {} };
let selectedHubId = null;

async function api(path, options = {}) {
  const res = await fetch(path, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      "x-admin-password": password,
      ...(options.headers || {}),
    },
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error || `HTTP ${res.status}`);
  }
  return res.json();
}

function groupName(id) {
  return config.groups.find((g) => g.id === id)?.name || id;
}

function avatarHtml(group) {
  if (group.pictureUrl) {
    return `<img class="avatar" src="${group.pictureUrl}" alt="" />`;
  }
  const ch = (group.name || "?").trim().charAt(0) || "?";
  return `<div class="avatar placeholder">${ch}</div>`;
}

function renderHubs() {
  if (!config.groups.length) {
    hubList.innerHTML =
      '<p class="empty">尚無群組。請把官方帳號加入群組後再按重新整理。</p>';
    return;
  }
  hubList.innerHTML = config.groups
    .map(
      (g) => `
      <label class="item ${selectedHubId === g.id ? "active" : ""}" data-hub="${g.id}">
        ${avatarHtml(g)}
        <div class="meta">
          <strong>${escapeHtml(g.name)}</strong>
          <span>${g.memberCount != null ? `${g.memberCount} 人` : "群組"} · 點選設為群發來源</span>
        </div>
        <input type="radio" name="hub" value="${g.id}" ${selectedHubId === g.id ? "checked" : ""} />
      </label>`
    )
    .join("");

  hubList.querySelectorAll("[data-hub]").forEach((el) => {
    el.addEventListener("click", () => {
      selectedHubId = el.getAttribute("data-hub");
      renderHubs();
      renderTargets();
      targetsPanel.hidden = false;
    });
  });
}

function renderTargets() {
  if (!selectedHubId) {
    targetsPanel.hidden = true;
    return;
  }
  const selected = new Set(config.rules[selectedHubId] || []);
  const candidates = config.groups.filter((g) => g.id !== selectedHubId);
  if (!candidates.length) {
    targetList.innerHTML = '<p class="empty">沒有其他可轉發的群組。</p>';
    return;
  }
  targetList.innerHTML = candidates
    .map(
      (g) => `
      <label class="item ${selected.has(g.id) ? "active" : ""}">
        ${avatarHtml(g)}
        <div class="meta">
          <strong>${escapeHtml(g.name)}</strong>
          <span>勾選後會自動收到群發內容</span>
        </div>
        <input type="checkbox" value="${g.id}" ${selected.has(g.id) ? "checked" : ""} />
      </label>`
    )
    .join("");

  targetList.querySelectorAll("input[type=checkbox]").forEach((input) => {
    input.addEventListener("change", () => {
      input.closest(".item").classList.toggle("active", input.checked);
    });
  });
}

function renderRules() {
  const entries = Object.entries(config.rules || {});
  if (!entries.length) {
    rulesView.innerHTML = '<p class="empty">尚未設定任何轉發規則。</p>';
    return;
  }
  rulesView.innerHTML = entries
    .map(([hub, targets]) => {
      const names = targets.map((id) => escapeHtml(groupName(id))).join("、");
      return `<div class="rule-card"><strong>${escapeHtml(groupName(hub))}</strong> → ${names || "（無）"}</div>`;
    })
    .join("");
}

function escapeHtml(str) {
  return String(str)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

async function loadConfig() {
  config = await api("/api/config");
  if (!selectedHubId) {
    const firstHub = Object.keys(config.rules || {})[0];
    selectedHubId = firstHub || config.groups[0]?.id || null;
  }
  renderHubs();
  renderTargets();
  renderRules();
  if (selectedHubId) targetsPanel.hidden = false;
}

async function doLogin() {
  loginError.hidden = true;
  password = passwordEl.value.trim();
  try {
    await loadConfig();
    localStorage.setItem("adminPassword", password);
    loginEl.hidden = true;
    dashboardEl.hidden = false;
  } catch (err) {
    loginError.textContent = err.message || "登入失敗";
    loginError.hidden = false;
  }
}

loginBtn.addEventListener("click", doLogin);
passwordEl.addEventListener("keydown", (e) => {
  if (e.key === "Enter") doLogin();
});

saveBtn.addEventListener("click", async () => {
  saveMsg.hidden = true;
  if (!selectedHubId) return;
  const targetGroupIds = [...targetList.querySelectorAll("input[type=checkbox]:checked")].map(
    (el) => el.value
  );
  try {
    const data = await api("/api/rules", {
      method: "POST",
      body: JSON.stringify({ hubGroupId: selectedHubId, targetGroupIds }),
    });
    config = data.config;
    renderRules();
    saveMsg.textContent = "已儲存。之後丟進此群發群組的訊息會自動轉發。";
    saveMsg.hidden = false;
  } catch (err) {
    saveMsg.textContent = err.message;
    saveMsg.hidden = false;
    saveMsg.classList.remove("ok");
    saveMsg.classList.add("error");
  }
});

refreshBtn.addEventListener("click", async () => {
  try {
    const data = await api("/api/groups/refresh", { method: "POST", body: "{}" });
    config = data.config;
    renderHubs();
    renderTargets();
    renderRules();
  } catch (err) {
    alert(err.message);
  }
});

if (password) {
  passwordEl.value = password;
  doLogin().catch(() => {
    localStorage.removeItem("adminPassword");
    password = "";
  });
}
