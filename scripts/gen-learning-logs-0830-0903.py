#!/usr/bin/env python3
"""Generate 0830–0903 learning logs (exclude chaoma-xinde). One theme per day, consecutive after 0829."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPORT_608 = ROOT / "_export/hello-world/directory/202608"
EXPORT_609 = ROOT / "_export/hello-world/directory/202609"
DOCS_608 = ROOT / "docs/directory/202608"
DOCS_609 = ROOT / "docs/directory/202609"

STYLE = """    :root {
      --ink: #1a1f1c;
      --paper: #e8efe6;
      --accent: #2d6a4f;
      --muted: #4a5c52;
      --line: rgba(45, 106, 79, 0.2);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      min-height: 100vh;
      font-family: "DM Sans", sans-serif;
      color: var(--ink);
      line-height: 1.7;
      background:
        radial-gradient(ellipse 80% 50% at 10% 0%, rgba(149, 213, 178, 0.35), transparent 55%),
        linear-gradient(160deg, #f4faf6 0%, var(--paper) 50%, #d8e8dc 100%);
    }
    .wrap { max-width: 52rem; margin: 0 auto; padding: 2rem 1.35rem 4rem; }
    .nav { display: flex; flex-wrap: wrap; gap: 1rem; margin-bottom: 2rem; font-size: 0.95rem; }
    .nav a { color: var(--accent); text-decoration: none; font-weight: 500; }
    .nav a:hover { text-decoration: underline; text-underline-offset: 0.2em; }
    article {
      background: rgba(255,255,255,0.55);
      border: 1px solid var(--line);
      padding: 1.75rem 1.5rem 2.5rem;
    }
    h1 {
      font-family: "Instrument Serif", Georgia, serif;
      font-size: clamp(1.45rem, 4.5vw, 2rem);
      font-weight: 400;
      color: var(--accent);
      line-height: 1.35;
      margin-bottom: 0.75rem;
    }
    .lead { color: var(--muted); margin-bottom: 1.5rem; }
    h2 {
      font-family: "Instrument Serif", Georgia, serif;
      font-size: 1.3rem;
      font-weight: 400;
      color: var(--accent);
      margin: 1.75rem 0 0.85rem;
      padding-top: 0.75rem;
      border-top: 1px solid var(--line);
    }
    ul, ol { margin: 0.5rem 0 0.85rem 1.35rem; }
    li { margin: 0.3rem 0; }
    code { font-size: 0.9em; background: rgba(45,106,79,0.1); padding: 0.1em 0.35em; }
    a.inline { color: var(--accent); word-break: break-all; }
    .callout {
      margin: 1rem 0;
      padding: 0.85rem 1rem;
      border-left: 3px solid var(--accent);
      background: rgba(45,106,79,0.08);
      font-size: 0.95rem;
    }
    .note { font-size: 0.85rem; color: var(--muted); margin-top: 1rem; }"""

# 接 0829，一天一主題；不含超碼修煉心得
LOGS = [
    {
        "month": "202608",
        "date": "20260830",
        "num": "0830",
        "prev": ("0829", "20260829", "選歌置頂 · 內建歌詞 · 習作工具入口", "../202608/"),
        "title": "福到你家（正聲廣播）完整版＋簡易版",
        "nav_app": ("../apps/fu-dao-ni-jia/", "開啟福到你家"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260829-learning-log.html\">0829 選歌置頂 · 內建歌詞</a>。本日新增正聲廣播《福到你家》手機 PWA：完整版與可分享簡易版，選集即播、搜尋、連播、倍速。",
        "sections": [
            ("一｜入口", [
                "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/fu-dao-ni-jia/\">https://copyshae.github.io/-/fu-dao-ni-jia/</a>",
                "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/fu-dao-ni-jia/simple/\">https://copyshae.github.io/-/fu-dao-ni-jia/simple/</a>",
                "加入主畫面：<a class=\"inline\" href=\"https://copyshae.github.io/-/fu-dao-ni-jia/share.html\">https://copyshae.github.io/-/fu-dao-ni-jia/share.html</a>",
                "鏡像：<a class=\"inline\" href=\"https://copyshae.github.io/-/directory/apps/fu-dao-ni-jia/\">https://copyshae.github.io/-/directory/apps/fu-dao-ni-jia/</a>",
            ]),
            ("二｜功能", [
                "目錄約 344 集（Firstory RSS）；選集即播、關鍵字搜尋、連播、倍速。",
                "簡易版可分享單集 <code>?ep=</code>；與完整版記錄分開。",
                "建目錄：<code>scripts/build-fu-dao-catalog.py</code>；路徑 <code>docs/fu-dao-ni-jia/</code>。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/directory/apps/fu-dao-ni-jia/",
    },
    {
        "month": "202608",
        "date": "20260831",
        "num": "0831",
        "prev": ("0830", "20260830", "福到你家（正聲廣播）", "../202608/"),
        "title": "太陽盛德導師影音圖書館（親身口述）",
        "nav_app": ("../apps/taiyang-lib/", "開啟導師影音圖書館"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260830-learning-log.html\">0830 福到你家</a>。本日新增導師親身口述影音圖書館：福到你家音檔、演講訪談、導師親唱共約 488 則；完整版與簡易版皆可快速搜尋、點選播放。",
        "sections": [
            ("一｜入口", [
                "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-lib/\">https://copyshae.github.io/-/taiyang-lib/</a>",
                "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-lib/simple/\">https://copyshae.github.io/-/taiyang-lib/simple/</a>",
                "鏡像：<a class=\"inline\" href=\"https://copyshae.github.io/-/directory/apps/taiyang-lib/\">https://copyshae.github.io/-/directory/apps/taiyang-lib/</a>",
            ]),
            ("二｜分類與播放", [
                "分類：福到你家（音檔）、演講・共修・訪談（YouTube）、導師親唱歌選。",
                "音檔：先選列表，再按大顆「▶ 播放」（iPhone 需此一步）。",
                "YouTube 影音：按「在 YouTube 播放」直連；簡易版 iOS 另有紅色直連按鈕。",
                "分享：簡易版 <code>?item=</code> 單則、<code>?q=</code> 搜尋；分享連結不寫入個人記錄。",
            ]),
            ("三｜建置", [
                "路徑 <code>docs/taiyang-lib/</code>；腳本 <code>scripts/build-taiyang-lib-catalog.py</code>。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/directory/apps/taiyang-lib/",
    },
    {
        "month": "202609",
        "date": "20260901",
        "num": "0901",
        "prev": ("0831", "20260831", "太陽盛德導師影音圖書館", "../202608/"),
        "title": "太陽心語圖片收錄（美聲朗讀）",
        "nav_app": ("../apps/taiyang-xinyu/", "開啟太陽心語"),
        "lead": "接日誌 <a class=\"inline\" href=\"../202608/20260831-learning-log.html\">0831 導師影音圖書館</a>。本日新增太陽心語圖片收錄 PWA：網路搜尋＋種子語錄、點圖彈出、美聲朗讀或無聲瀏覽；原圖只唸圖上語錄。",
        "sections": [
            ("一｜入口", [
                "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-xinyu/\">https://copyshae.github.io/-/taiyang-xinyu/</a>",
                "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-xinyu/simple/\">https://copyshae.github.io/-/taiyang-xinyu/simple/</a>",
                "鏡像：<a class=\"inline\" href=\"https://copyshae.github.io/-/directory/apps/taiyang-xinyu/\">https://copyshae.github.io/-/directory/apps/taiyang-xinyu/</a>",
                "網址須打 <strong>copyshae</strong>（有 co）；誤打 pyshae 會 404。",
            ]),
            ("二｜朗讀與收錄", [
                "種子語錄：標題唸一次＋主文；原圖／縮圖只唸手動對照的圖上內容。",
                "手動對照：<code>data/taiyang-xinyu-read-overrides.json</code>；篩選非語錄：<code>data/taiyang-xinyu-blocklist.json</code>。",
                "圖片鏡像至 <code>cards/mirror/</code>；優先網路原圖，失敗才用本站鏡像。",
                "iOS 朗讀：閒置不先 <code>cancel()</code>；共用 <code>docs/shared/tts-voices.js</code>。",
            ]),
            ("三｜建置", [
                "路徑 <code>docs/taiyang-xinyu/</code>；腳本 <code>scripts/build-taiyang-xinyu-catalog.py</code>。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/directory/apps/taiyang-xinyu/",
    },
    {
        "month": "202609",
        "date": "20260902",
        "num": "0902",
        "prev": ("0901", "20260901", "太陽心語圖片收錄", "./"),
        "title": "Google 新聞虛擬主播",
        "nav_app": ("../../news-anchor/", "開啟新聞主播"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260901-learning-log.html\">0901 太陽心語</a>。本日整理 Google 新聞虛擬主播：多分類、多主播風格、口說／文字輸入、可加入主畫面；RSS 與原文摘要播報。",
        "sections": [
            ("一｜入口", [
                "正式：<a class=\"inline\" href=\"https://copyshae.github.io/-/news-anchor/\">https://copyshae.github.io/-/news-anchor/</a>",
                "加入主畫面：<a class=\"inline\" href=\"https://copyshae.github.io/-/news-anchor/share.html\">https://copyshae.github.io/-/news-anchor/share.html</a>",
            ]),
            ("二｜功能摘要", [
                "分類含國際、台灣、財經、教育、AI 等；口說別名可切換。",
                "快取 <code>news-cache.json</code>；腳本 <code>scripts/fetch_google_news.py</code> 更新。",
                "播報可含相關報導摘要與媒體原文重點（依快取／即時合併）。",
                "路徑 <code>docs/news-anchor/</code>。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/news-anchor/",
    },
    {
        "month": "202609",
        "date": "20260903",
        "num": "0903",
        "prev": ("0902", "20260902", "Google 新聞虛擬主播", "./"),
        "title": "每日14樣功課簡易版（可分享）",
        "nav_app": ("../apps/daily-14/simple/", "開啟14樣功課簡易版"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260902-learning-log.html\">0902 新聞虛擬主播</a>。本日補推每日14樣功課簡易版：精簡勾選＋重設今日，可分享網址；與完整版記錄分開、互不覆寫。",
        "sections": [
            ("一｜入口", [
                "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/daily-14/simple/\">https://copyshae.github.io/-/daily-14/simple/</a>",
                "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/daily-14/\">https://copyshae.github.io/-/daily-14/</a>",
                "鏡像：<a class=\"inline\" href=\"https://copyshae.github.io/-/directory/apps/daily-14/\">https://copyshae.github.io/-/directory/apps/daily-14/</a>",
            ]),
            ("二｜與完整版差異", [
                "簡易版僅 14 項勾選＋重設今日；無七習慣、無匯入匯出、無撤銷。",
                "儲存 key <code>daily14-simple-v1</code>，完整版為 <code>daily14-v1</code>，互不覆寫。",
                "訪客試用：<code>?guest=1</code>（sessionStorage）。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/directory/apps/daily-14/",
    },
]


def render(log: dict) -> str:
    month = log["month"]
    date = log["date"]
    num = log["num"]
    prev_num, prev_date, prev_title, prev_dir = log["prev"]
    url_dash = f"https://copyshae.github.io/-/directory/{month}/{date}-learning-log.html"
    url_hw = f"https://copyshae.github.io/hello-world/directory/{month}/{date}-learning-log.html"
    nav_href, nav_label = log["nav_app"]
    prev_href = f"{prev_dir}{prev_date}-learning-log.html"

    sections_html = ""
    for heading, items in log["sections"]:
        lis = "\n".join(f"        <li>{item}</li>" for item in items)
        sections_html += f"""
      <h2>{heading}</h2>
      <ul>
{lis}
      </ul>"""

    return f"""<!DOCTYPE html>
<html lang="zh-Hant">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{date} 學習日誌・{log["title"]}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&family=Instrument+Serif&display=swap" rel="stylesheet" />
  <style>
{STYLE}
  </style>
</head>
<body>
  <div class="wrap">
    <nav class="nav">
      <a href="../../index.html">← 首頁</a>
      <a href="../index.html">← 學習日誌</a>
      <a href="./index.html">← 日誌列表</a>
      <a href="{nav_href}">{nav_label}</a>
    </nav>
    <article>
      <h1>{date} {log["title"]}</h1>
      <p class="lead">{log["lead"]}</p>

      <div class="callout"><strong>手機立刻可開（免開電腦）：</strong><br />
        <a class="inline" href="{url_dash}">{url_dash}</a><br />
        正式 hello-world：
        <a class="inline" href="{url_hw}">{url_hw}</a>
      </div>
{sections_html}

      <p class="note">
        hello-world：
        <a class="inline" href="{url_hw}">{url_hw}</a>
        ｜App：
        <a class="inline" href="{log["note_app"]}">{log["note_app"]}</a>
        ｜上一則：
        <a class="inline" href="{prev_href}">{prev_num} {prev_title}</a>
      </p>
    </article>
  </div>
</body>
</html>
"""


INDEX_STYLE = """    :root {
      --ink: #1a1f1c;
      --paper: #e8efe6;
      --accent: #2d6a4f;
      --muted: #4a5c52;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      min-height: 100vh;
      font-family: "DM Sans", sans-serif;
      color: var(--ink);
      background:
        radial-gradient(ellipse 80% 60% at 20% 10%, rgba(149, 213, 178, 0.45), transparent 55%),
        radial-gradient(ellipse 70% 50% at 90% 80%, rgba(45, 106, 79, 0.18), transparent 50%),
        linear-gradient(160deg, #f4faf6 0%, var(--paper) 45%, #d8e8dc 100%);
    }
    .wrap { max-width: 40rem; margin: 0 auto; padding: 2.5rem 1.5rem 4rem; }
    .nav { display: flex; flex-wrap: wrap; gap: 1rem; margin-bottom: 2rem; }
    .nav a { color: var(--accent); text-decoration: none; font-weight: 500; font-size: 0.95rem; }
    .nav a:hover { text-decoration: underline; text-underline-offset: 0.2em; }
    h1 {
      font-family: "Instrument Serif", Georgia, serif;
      font-size: clamp(1.6rem, 5vw, 2.2rem);
      font-weight: 400; color: var(--accent); letter-spacing: 0.04em; line-height: 1.3;
    }
    .lead { margin-top: 0.75rem; color: var(--muted); font-size: 1.05rem; line-height: 1.6; }
    .dir-list { list-style: none; margin-top: 1.25rem; display: flex; flex-direction: column; gap: 0.85rem; }
    .dir-list a {
      display: block; padding: 1.15rem 1.35rem;
      background: rgba(255, 255, 255, 0.55);
      border: 1px solid rgba(45, 106, 79, 0.22);
      color: var(--ink); text-decoration: none; font-weight: 600; font-size: 1.15rem;
    }
    .dir-list a:hover { background: rgba(255, 255, 255, 0.9); border-color: var(--accent); }
    .dir-list a span { display: block; margin-top: 0.35rem; font-weight: 400; font-size: 0.9rem; color: var(--muted); }
"""


def write_month_index_609() -> str:
    items = [
        ("20260903-learning-log.html", "20260903 每日14樣功課簡易版（可分享）",
         "精簡勾選｜與完整版分開｜https://copyshae.github.io/-/directory/apps/daily-14/"),
        ("20260902-learning-log.html", "20260902 Google 新聞虛擬主播",
         "多分類｜口說輸入｜加入主畫面｜https://copyshae.github.io/-/news-anchor/"),
        ("20260901-learning-log.html", "20260901 太陽心語圖片收錄（美聲朗讀）",
         "原圖語錄｜美聲朗讀｜無聲模式｜https://copyshae.github.io/-/directory/apps/taiyang-xinyu/"),
    ]
    lis = "\n".join(
        f"""      <li>
        <a href="{href}">
          {title}
          <span>{span}</span>
        </a>
      </li>"""
        for href, title, span in items
    )
    return f"""<!DOCTYPE html>
<html lang="zh-Hant">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>202609｜學習日誌</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=DM+Sans:opsz,wght@9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet" />
  <style>
{INDEX_STYLE}
  </style>
</head>
<body>
  <div class="wrap">
    <nav class="nav">
      <a href="../../">← 回到首頁</a>
      <a href="../">← 學習日誌</a>
      <a href="../202608/">← 202608</a>
    </nav>
    <h1>202609</h1>
    <p class="lead">接 0831，連續一天一主題（0901–0903；不含超碼修煉心得）。由新到舊排列。</p>
    <ul class="dir-list">
{lis}
    </ul>
  </div>
</body>
</html>
"""


def main():
    for d in (EXPORT_608, EXPORT_609, DOCS_608, DOCS_609):
        d.mkdir(parents=True, exist_ok=True)

    for log in LOGS:
        html = render(log)
        month = log["month"]
        name = f"{log['date']}-learning-log.html"
        for base in (
            ROOT / "_export/hello-world/directory" / month,
            ROOT / "docs/directory" / month,
        ):
            path = base / name
            path.write_text(html, encoding="utf-8")
            print("wrote", path)

    idx = write_month_index_609()
    for base in (EXPORT_609, DOCS_609):
        p = base / "index.html"
        p.write_text(idx, encoding="utf-8")
        print("wrote", p)


if __name__ == "__main__":
    main()
