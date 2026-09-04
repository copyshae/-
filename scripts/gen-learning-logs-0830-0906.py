#!/usr/bin/env python3
"""Generate 20260830–20260906 learning logs (one topic per day, after 0829)."""
from pathlib import Path

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

LOGS = [
    {
        "ym": "202608",
        "date": "20260830",
        "num": "0830",
        "prev": ("0829", "202608", "20260829", "選歌置頂 · 內建歌詞"),
        "title": "Google 新聞虛擬主播 PWA",
        "nav_app": ("../apps/news-anchor/", "開啟 Google 新聞虛擬主播"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260829-learning-log.html\">0829 選歌置頂 · 內建歌詞</a>。本日把尚未上線的「Google 新聞虛擬主播」獨立成一天一主題：六種主播、口說／文字選類、演播室播報與加入主畫面。",
        "sections": [
            ("一｜入口", [
                "主版：<a class=\"inline\" href=\"https://copyshae.github.io/-/news-anchor/\">https://copyshae.github.io/-/news-anchor/</a>",
                "加入主畫面：<a class=\"inline\" href=\"https://copyshae.github.io/-/news-anchor/share.html\">share.html</a>",
                "習作工具主頁 →「打開 Google 新聞虛擬主播」",
                "來源：<code>docs/news-anchor/</code>；新聞快取 <code>news-cache.json</code>；腳本 <code>scripts/fetch_google_news.py</code>",
            ]),
            ("二｜播報功能", [
                "從 Google 新聞 RSS 抓頭條；分類含頭條、科技、教育、AI 等。",
                "六種虛擬主播人物；口說或文字輸入選類；可全螢幕播報。",
                "播報含相關報導摘要與媒體原文內文（解碼 Google News 連結後抓取）。",
                "演播室：時鐘、跑馬燈、專業主播語音風格；結束可接播下一類。",
            ]),
            ("三｜口型與穩定", [
                "寫實主播肖像；idle／talk 完整影片避免肖像斷線。",
                "Azure TTS 失敗自動改系統語音；手機需手勢解鎖音訊。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/news-anchor/",
    },
    {
        "ym": "202608",
        "date": "20260831",
        "num": "0831",
        "prev": ("0830", "202608", "20260830", "Google 新聞虛擬主播"),
        "title": "超碼修煉心得 PWA（四步法）",
        "nav_app": ("../apps/chaoma-xinde/", "開啟超碼修煉心得"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260830-learning-log.html\">0830 Google 新聞虛擬主播</a>。本日推上「超碼修煉心得」手機 PWA：依 SOP 四步法生成心得，支援文字／口說／拍照／影片與導師影音圖片網搜參考。",
        "sections": [
            ("一｜入口", [
                "主版：<a class=\"inline\" href=\"https://copyshae.github.io/-/chaoma-xinde/\">https://copyshae.github.io/-/chaoma-xinde/</a>",
                "加入主畫面：<a class=\"inline\" href=\"https://copyshae.github.io/-/chaoma-xinde/share.html\">share.html</a>",
                "習作工具主頁橘色按鈕「✍️ 打開超碼修煉心得」",
                "來源：<code>docs/chaoma-xinde/</code>",
            ]),
            ("二｜生成與素材", [
                "四步法：素材 → 潤飾 → 印證（聖賢／太陽盛德導師）→ 格式檢核。",
                "輸入：文字、口說、拍照、圖片、錄影／選影片；可網搜導師影音／圖片參考。",
                "有 Gemini 金鑰時解析圖片／影片；無金鑰本機模板 fallback。",
            ]),
            ("三｜編輯與匯出", [
                "全文可打字或口說修改；心得寫完可「🔊 誦讀心得」。",
                "作者日期優先網路取得（Asia/Taipei），可手動校正。",
                "匯出 Word／PDF；圖片可附加於文末；可分享到其他 App。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/chaoma-xinde/",
    },
    {
        "ym": "202609",
        "date": "20260901",
        "num": "0901",
        "prev": ("0831", "202608", "20260831", "超碼修煉心得"),
        "title": "弟子規 41 集：新增 1×／1.5× 倍速",
        "nav_app": ("../apps/dizigui-41/", "開啟弟子規 41 集"),
        "lead": "接日誌 <a class=\"inline\" href=\"../202608/20260831-learning-log.html\">0831 超碼修煉心得</a>。本日為弟子規 41 集補上 1×、1.5× 倍速（原僅 1.75／2），讓慢速精聽與快速複習都方便。",
        "sections": [
            ("一｜入口", [
                "主版：<a class=\"inline\" href=\"https://copyshae.github.io/-/dizigui-41/\">https://copyshae.github.io/-/dizigui-41/</a>",
                "鏡像：<a class=\"inline\" href=\"https://copyshae.github.io/-/directory/apps/dizigui-41/\">directory/apps/dizigui-41/</a>",
                "來源：<code>docs/dizigui-41/</code>；SW v7",
            ]),
            ("二｜倍速", [
                "選項：1×、1.5×、1.75×、2×；偏好存本機。",
                "仍可從第 1 集連播至第 41 集；YouTube 嵌入播放。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/dizigui-41/",
    },
    {
        "ym": "202609",
        "date": "20260902",
        "num": "0902",
        "prev": ("0901", "202609", "20260901", "弟子規 1×／1.5× 倍速"),
        "title": "創作歌曲簡易版 · 抬頭更名 · 去 KTV 精簡",
        "nav_app": ("../apps/taiyang-music/", "開啟太陽盛德導師創作歌曲"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260901-learning-log.html\">0901 弟子規倍速</a>。本日整理盛德歌曲：完整版去除 KTV、抬頭改為「太陽盛德導師創作歌曲」，並另建可分享的簡易版。",
        "sections": [
            ("一｜入口", [
                "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-music/\">https://copyshae.github.io/-/taiyang-music/</a>",
                "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-music/simple/\">https://copyshae.github.io/-/taiyang-music/simple/</a>",
                "習作工具主頁按鈕文案已同步為「太陽盛德導師創作歌曲」",
            ]),
            ("二｜完整版精簡", [
                "移除 KTV 大字幕、評分、字幕同步；保留選歌即播、連播、伴唱、分類篩選。",
                "修正先前按 KTV 後播放視窗突然放大的問題（相關邏輯已卸下）。",
            ]),
            ("三｜簡易版", [
                "僅選歌＋播放，適合分享給朋友；可加入主畫面。",
                "與完整版分開入口，避免介面過重。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/taiyang-music/",
    },
    {
        "ym": "202609",
        "date": "20260903",
        "num": "0903",
        "prev": ("0902", "202609", "20260902", "創作歌曲簡易版"),
        "title": "每日14樣功課簡易版（可分享）",
        "nav_app": ("../apps/daily-14/simple/", "開啟14樣功課簡易版"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260902-learning-log.html\">0902 創作歌曲簡易版</a>。本日新增每日14樣功課簡易版：只留勾選與重設今日，可分享網址，且不覆寫完整版記錄。",
        "sections": [
            ("一｜入口", [
                "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/daily-14/simple/\">https://copyshae.github.io/-/daily-14/simple/</a>",
                "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/daily-14/\">https://copyshae.github.io/-/daily-14/</a>",
                "訪客試用：簡易版加 <code>?guest=1</code>（sessionStorage，不寫入個人長期記錄）",
            ]),
            ("二｜與完整版分開", [
                "儲存 key：簡易版 <code>daily14-simple-v1</code>、完整版 <code>daily14-v1</code>，互不覆寫。",
                "簡易版無七習慣、無匯入匯出、無撤銷；完整版功能維持不變。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/daily-14/simple/",
    },
    {
        "ym": "202609",
        "date": "20260904",
        "num": "0904",
        "prev": ("0903", "202609", "20260903", "每日14樣功課簡易版"),
        "title": "福到你家：正聲廣播節目 PWA",
        "nav_app": ("../apps/fu-dao-ni-jia/", "開啟福到你家"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260903-learning-log.html\">0903 14樣功課簡易版</a>。本日新增正聲廣播「福到你家」手機 PWA：344 集選集即播、連播、倍速，完整版與簡易版皆可加入主畫面。",
        "sections": [
            ("一｜入口", [
                "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/fu-dao-ni-jia/\">https://copyshae.github.io/-/fu-dao-ni-jia/</a>",
                "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/fu-dao-ni-jia/simple/\">simple/</a>（分享單集 <code>?ep=</code>）",
                "加入主畫面：<a class=\"inline\" href=\"https://copyshae.github.io/-/fu-dao-ni-jia/share.html\">share.html</a>",
                "來源：Firstory RSS；目錄 <code>catalog.json</code>；腳本 <code>scripts/build-fu-dao-catalog.py</code>",
            ]),
            ("二｜播放", [
                "344 集清單；搜尋、連播、倍速。",
                "選集即播；簡易版適合把單集網址傳給朋友。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/fu-dao-ni-jia/",
    },
    {
        "ym": "202609",
        "date": "20260905",
        "num": "0905",
        "prev": ("0904", "202609", "20260904", "福到你家"),
        "title": "太陽盛德導師影音圖書館（親身口述）",
        "nav_app": ("../apps/taiyang-lib/", "開啟導師影音圖書館"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260904-learning-log.html\">0904 福到你家</a>。本日新增太陽盛德導師親身口述影音圖書館：福到你家、演講訪談、導師親唱共約 488 則，可跨分類快速搜尋。",
        "sections": [
            ("一｜入口", [
                "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-lib/\">https://copyshae.github.io/-/taiyang-lib/</a>",
                "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-lib/simple/\">simple/</a>（單則 <code>?item=</code>、搜尋 <code>?q=</code>）",
                "腳本：<code>scripts/build-taiyang-lib-catalog.py</code>",
            ]),
            ("二｜內容與搜尋", [
                "分類：福到你家 344、演講訪談 87、導師親唱 57。",
                "快速搜尋可跨分類；Enter 播放第一筆；分享連結不寫入個人記錄。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/taiyang-lib/",
    },
    {
        "ym": "202609",
        "date": "20260906",
        "num": "0906",
        "prev": ("0905", "202609", "20260905", "太陽盛德導師影音圖書館"),
        "title": "太陽心語圖片收錄 PWA",
        "nav_app": ("../apps/taiyang-xinyu/", "開啟太陽心語"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260905-learning-log.html\">0905 導師影音圖書館</a>。本日推上太陽心語圖片收錄：網路搜尋＋種子語錄、美聲朗讀或無聲瀏覽，並優先顯示網路原圖。",
        "sections": [
            ("一｜入口", [
                "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-xinyu/\">https://copyshae.github.io/-/taiyang-xinyu/</a>",
                "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-xinyu/simple/\">simple/</a>",
                "建目錄：<code>scripts/build-taiyang-xinyu-catalog.py</code>；朗讀對照 <code>data/taiyang-xinyu-read-overrides.json</code>",
            ]),
            ("二｜瀏覽與朗讀", [
                "點選切換圖片、上一則／下一則、搜尋分類。",
                "美聲朗讀（共用 <code>tts-voices.js</code>）或無聲模式；原圖只唸圖上內容。",
                "有 <code>imageUrl</code> 時優先網路原圖，失敗再 fallback 本站鏡像／卡片。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/-/taiyang-xinyu/",
    },
]


def prev_href(log):
    prev_num, prev_ym, prev_date, _ = log["prev"]
    if prev_ym == log["ym"]:
        return f"./{prev_date}-learning-log.html"
    return f"../{prev_ym}/{prev_date}-learning-log.html"


def render(log):
    date = log["date"]
    ym = log["ym"]
    num = log["num"]
    prev_num, prev_ym, prev_date, prev_title = log["prev"]
    url_dash = f"https://copyshae.github.io/-/directory/{ym}/{date}-learning-log.html"
    url_hw = f"https://copyshae.github.io/hello-world/directory/{ym}/{date}-learning-log.html"
    nav_href, nav_label = log["nav_app"]
    lead = log["lead"]

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
      <p class="lead">{lead}</p>

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
        <a class="inline" href="{prev_href(log)}">{prev_num} {prev_title}</a>
      </p>
    </article>
  </div>
</body>
</html>
"""


def main():
    roots = [
        Path("_export/hello-world/directory"),
        Path("docs/directory"),
    ]
    for log in LOGS:
        for root in roots:
            base = root / log["ym"]
            base.mkdir(parents=True, exist_ok=True)
            path = base / f"{log['date']}-learning-log.html"
            path.write_text(render(log), encoding="utf-8")
            print("wrote", path)


if __name__ == "__main__":
    main()
