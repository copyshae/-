#!/usr/bin/env python3
"""Generate 20260824–20260829 learning log HTML files."""
from pathlib import Path

BASE = Path("_export/hello-world/directory/202608")
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
        "date": "20260824",
        "num": "0824",
        "prev": ("0823", "20260823", "看書／看文件（doc-reader）"),
        "title": "弟子規 41 集 PWA（蔡禮旭老師 · 1.75／2 倍速）",
        "nav_app": ("../apps/dizigui-41/", "開啟弟子規 41 集"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260823-learning-log.html\">0823 看書／看文件</a>。本日新增蔡禮旭老師《細講弟子規》第 1～41 集手機 PWA：可選 1.75 倍或 2 倍速連播，加入主畫面後像獨立 App 使用。",
        "sections": [
            ("一｜入口", [
                "主版（dash Pages）：<a class=\"inline\" href=\"https://copyshae.github.io/-/dizigui-41/\">https://copyshae.github.io/-/dizigui-41/</a>",
                "加入主畫面說明：<a class=\"inline\" href=\"https://copyshae.github.io/-/dizigui-41/share.html\">https://copyshae.github.io/-/dizigui-41/share.html</a>",
                "hello-world 鏡像：<a class=\"inline\" href=\"https://copyshae.github.io/hello-world/directory/apps/dizigui-41/\">https://copyshae.github.io/hello-world/directory/apps/dizigui-41/</a>",
                "習作工具主頁：<a class=\"inline\" href=\"https://copyshae.github.io/-/\">https://copyshae.github.io/-/</a> →「打開弟子規41集」",
                "來源：<code>docs/dizigui-41/</code>（集數清單 <code>episodes.js</code>）",
            ]),
            ("二｜播放與倍速", [
                "第 1～41 集清單；點選單集或「從第 1 集開始連播」。",
                "倍速：原速、1.75×、2×；偏好存本機。",
                "YouTube 嵌入播放；可暫停、上一集／下一集。",
            ]),
            ("三｜加入主畫面", [
                "Safari／Chrome →「加入主畫面」；圖示為弟子規卷軸（<code>dizigui-icon-*.png</code>）。",
                "修正 iPhone 仍顯示七習慣「7」圖示的快取：圖示檔名獨立、SW 網路優先、版本參數強制更新。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/hello-world/directory/apps/dizigui-41/",
    },
    {
        "date": "20260825",
        "num": "0825",
        "prev": ("0824", "20260824", "弟子規 41 集 PWA"),
        "title": "太陽盛德導師歌曲連播 PWA",
        "nav_app": ("../apps/taiyang-music/", "開啟盛德歌曲連播"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260824-learning-log.html\">0824 弟子規 41 集</a>。本日新增太陽盛德導師歌曲連播手機 PWA：依天圓文化曲庫自動排播放順序，可加入主畫面離線快取。",
        "sections": [
            ("一｜入口", [
                "主版：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-music/\">https://copyshae.github.io/-/taiyang-music/</a>",
                "分享／加入主畫面：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-music/share.html\">https://copyshae.github.io/-/taiyang-music/share.html</a>",
                "hello-world 鏡像：<a class=\"inline\" href=\"https://copyshae.github.io/hello-world/directory/apps/taiyang-music/\">https://copyshae.github.io/hello-world/directory/apps/taiyang-music/</a>",
                "來源：<code>docs/taiyang-music/</code>（曲庫 <code>catalog.json</code>）",
            ]),
            ("二｜播放順序", [
                "① 〈注入彩虹〉×3 → ② 〈富有〉×3 → ③ 導師親唱各×1 → ④ 其他演唱者各×1。",
                "分類欄位 <code>performer</code>：<code>master</code>（導師親唱）或 <code>other</code>（其他演唱者）；App 可篩選。",
            ]),
            ("三｜曲庫更新", [
                "<code>scripts/build-taiyang-catalog.py</code> 以 yt-dlp 搜尋 YouTube 更新曲庫。",
                "App 內「更新曲庫」；每週一 GitHub Actions（<code>update-taiyang-catalog.yml</code>）自動更新。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/hello-world/directory/apps/taiyang-music/",
    },
    {
        "date": "20260826",
        "num": "0826",
        "prev": ("0825", "20260825", "太陽盛德導師歌曲連播 PWA"),
        "title": "盛德歌曲 KTV 模式（大字幕 · 伴唱切換）",
        "nav_app": ("../apps/taiyang-music/", "開啟盛德歌曲 KTV"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260825-learning-log.html\">0825 盛德歌曲連播</a>。本日加入 KTV 模式：大字幕同步字幕、伴唱／原唱切換，快捷鍵 <strong>K</strong> 一鍵開關。",
        "sections": [
            ("一｜KTV 模式", [
                "按「🎤 KTV 模式」或快捷鍵 <strong>K</strong> 進入；畫面顯示大字幕區與 KTV 標籤。",
                "字幕隨播放進度更新；若 YouTube 有 CC 字幕會同步抓取。",
            ]),
            ("二｜伴唱切換", [
                "伴唱／原唱切換按鈕；切換時保留目前播放位置。",
                "適合跟唱練習：先聽導師親唱熟悉，再切伴唱自己唱。",
            ]),
            ("三｜使用方式", [
                "手機 Safari／Chrome → 加入主畫面後，像 KTV 機台一樣全螢幕使用。",
                "網址：<a class=\"inline\" href=\"https://copyshae.github.io/-/taiyang-music/\">https://copyshae.github.io/-/taiyang-music/</a>",
            ]),
        ],
        "note_app": "https://copyshae.github.io/hello-world/directory/apps/taiyang-music/",
    },
    {
        "date": "20260827",
        "num": "0827",
        "prev": ("0826", "20260826", "KTV 模式（大字幕 · 伴唱）"),
        "title": "KTV 唱完評分與練唱建議",
        "nav_app": ("../apps/taiyang-music/", "開啟盛德歌曲 KTV"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260826-learning-log.html\">0826 KTV 大字幕</a>。本日加入唱完自動評分：依完成度、伴唱使用、字幕跟唱等給綜合分數與提升建議。",
        "sections": [
            ("一｜唱完評分", [
                "KTV 模式播完一曲後顯示綜合評分（0～100）與星等。",
                "考量：是否唱完整段、是否使用伴唱、字幕跟唱比例、暫停次數等。",
            ]),
            ("二｜提升建議", [
                "依本場表現產生 2～4 則具體建議（例如：某段常停頓、可先聽導師親唱等）。",
                "首次練唱會提示「繼續加油」；重唱同一首會比較歷史最佳。",
            ]),
            ("三｜歷史最佳", [
                "每首歌記錄歷史最高分；唱完顯示是否刷新個人最佳。",
                "資料存本機 localStorage，換手機需重新累積。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/hello-world/directory/apps/taiyang-music/",
    },
    {
        "date": "20260828",
        "num": "0828",
        "prev": ("0827", "20260827", "KTV 唱完評分與建議"),
        "title": "練唱紀錄 · A-B 循環 · 成果分享卡",
        "nav_app": ("../apps/taiyang-music/", "開啟盛德歌曲 KTV"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260827-learning-log.html\">0827 KTV 評分</a>。本日加入練唱紀錄、A-B 段循環練習，以及可下載的本場小結／單曲成果卡。",
        "sections": [
            ("一｜練唱紀錄", [
                "每場 KTV 練唱寫入本機紀錄：曲名、分數、日期、伴唱與字幕使用情形。",
                "可查看最近練唱列表，追蹤進步軌跡。",
            ]),
            ("二｜A-B 段循環", [
                "播放中按「設 A」「設 B」標記起訖點；該段會循環播放，方便練難句。",
                "狀態列顯示 A-B 段時間；可清除循環恢復整首播放。",
                "評分建議會指出常停頓熱點，提示用 A-B 單練。",
            ]),
            ("三｜成果分享卡", [
                "唱完可產生「本場小結」或單曲成果 PNG 圖卡（含分數、曲名、日期）。",
                "一鍵下載分享；方便記錄靈修／練唱成果。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/hello-world/directory/apps/taiyang-music/",
    },
    {
        "date": "20260829",
        "num": "0829",
        "prev": ("0828", "20260828", "練唱紀錄 · A-B 循環 · 成果卡"),
        "title": "選歌置頂 · 內建歌詞 · 習作工具入口",
        "nav_app": ("../apps/taiyang-music/", "開啟盛德歌曲 KTV"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260828-learning-log.html\">0828 練唱紀錄與成果卡</a>。本日優化選歌流程：選單置頂、選歌後再決定 KTV 或一般播放；內建歌詞 localStorage 快取並同步大字幕；習作工具主頁加入橘色 KTV 入口。",
        "sections": [
            ("一｜選歌流程", [
                "歌曲選單移至頁面最上方；先選曲，再按「🎤 KTV 模式」或「▶ 一般播放」。",
                "KTV 與一般模式皆顯示選單，不必來回切換頁面。",
            ]),
            ("二｜內建歌詞", [
                "重點歌曲（注入彩虹、富有等）有內建歌詞 JSON（<code>docs/taiyang-music/lyrics/</code>）。",
                "首次可從網路抓取 YouTube 字幕並快取本機；大字幕優先使用內建歌詞。",
                "建置腳本：<code>scripts/build-taiyang-lyrics.py</code>。",
            ]),
            ("三｜習作工具入口", [
                "主頁 <code>docs/index.html</code> 新增橘色「🎤 打開盛德歌曲 KTV」按鈕。",
                "學習日誌連結更新至 0829；手機可從主頁一次進入所有 App。",
            ]),
        ],
        "note_app": "https://copyshae.github.io/hello-world/directory/apps/taiyang-music/",
    },
]


def render(log):
    date = log["date"]
    num = log["num"]
    prev_num, prev_date, prev_title = log["prev"]
    url_dash = f"https://copyshae.github.io/-/directory/202608/{date}-learning-log.html"
    url_hw = f"https://copyshae.github.io/hello-world/directory/202608/{date}-learning-log.html"
    nav_href, nav_label = log["nav_app"]

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
        <a class="inline" href="./{prev_date}-learning-log.html">{prev_num} {prev_title}</a>
      </p>
    </article>
  </div>
</body>
</html>
"""


def main():
    BASE.mkdir(parents=True, exist_ok=True)
    for log in LOGS:
        path = BASE / f"{log['date']}-learning-log.html"
        path.write_text(render(log), encoding="utf-8")
        print("wrote", path)


if __name__ == "__main__":
    main()
