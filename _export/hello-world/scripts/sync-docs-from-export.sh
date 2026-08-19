#!/usr/bin/env bash
# 從 _export/hello-world/directory/apps 同步到 docs/（習作批改 mg、習作台 td）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SRC="$ROOT/_export/hello-world/directory/apps"
DOCS="$ROOT/docs"

sync_app() {
  local name="$1"
  local src="$SRC/$name"
  for dest in "$DOCS/$name" "$DOCS/$([ "$name" = "math-grader" ] && echo mg || echo td)"; do
    mkdir -p "$dest"
    cp -a "$src"/. "$dest"/
    echo "已同步 $name → $dest"
  done
}

sync_app math-grader
sync_app teacher-desk

cat > "$DOCS/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <meta name="theme-color" content="#1b4332" />
  <title>習作工具</title>
  <style>
    :root { --accent: #1b4332; --muted: #4a5c52; --paper: #e8efe6; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      min-height: 100vh; font-family: "PingFang TC", "Noto Sans TC", sans-serif;
      color: #1a1f1c; line-height: 1.55;
      background: linear-gradient(160deg, #f4faf6 0%, var(--paper) 55%, #d8e8dc 100%);
      padding: 2rem 1.2rem 3rem;
    }
    .wrap { max-width: 22rem; margin: 0 auto; }
    h1 { font-size: 2rem; font-weight: 700; color: var(--accent); }
    p { margin-top: 0.6rem; color: var(--muted); font-size: 1rem; }
    a.btn {
      display: block; margin-top: 1.4rem; text-align: center; text-decoration: none;
      background: var(--accent); color: #fff; font-weight: 700; font-size: 1.15rem;
      padding: 1rem 1.1rem;
    }
    a.btn.secondary {
      background: transparent; color: var(--accent); border: 1px solid var(--accent);
      margin-top: 0.7rem; font-size: 1rem; font-weight: 600;
    }
    .note { margin-top: 1.4rem; font-size: 0.9rem; color: var(--muted); }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>習作工具</h1>
    <p>請按下面按鈕進入。不用理會英文中轉頁。</p>
    <a class="btn" href="./math-grader/">打開習作批改</a>
    <a class="btn secondary" href="./teacher-desk/">打開習作台</a>
    <p class="note">習作批改：匯入試卷 → ChatPlayground AI 自動批閱 → 貼回覆套用。整班用「連續 ChatPlayground 批」。習作台：同步程度 → 複製群發文。</p>
  </div>
</body>
</html>
HTML

echo "已更新 docs/index.html"
