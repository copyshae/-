#!/usr/bin/env python3
"""Generate 0916–0918 learning logs. One theme per day, consecutive after 0915."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPORT_609 = ROOT / "_export/hello-world/directory/202609"
DOCS_609 = ROOT / "docs/directory/202609"
EXPORT_DIR = ROOT / "_export/hello-world/directory"
DOCS_DIR = ROOT / "docs/directory"

STYLE = """    :root {
      --ink: #1a1f1c; --paper: #e8efe6; --accent: #2d6a4f; --muted: #4a5c52; --line: rgba(45, 106, 79, 0.2);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      min-height: 100vh; font-family: "DM Sans", sans-serif; color: var(--ink); line-height: 1.7;
      background:
        radial-gradient(ellipse 80% 50% at 10% 0%, rgba(149, 213, 178, 0.35), transparent 55%),
        linear-gradient(160deg, #f4faf6 0%, var(--paper) 50%, #d8e8dc 100%);
    }
    .wrap { max-width: 52rem; margin: 0 auto; padding: 2rem 1.35rem 4rem; }
    .nav { display: flex; flex-wrap: wrap; gap: 1rem; margin-bottom: 2rem; font-size: 0.95rem; }
    .nav a { color: var(--accent); text-decoration: none; font-weight: 500; }
    .nav a:hover { text-decoration: underline; text-underline-offset: 0.2em; }
    article {
      background: rgba(255,255,255,0.55); border: 1px solid var(--line); padding: 1.75rem 1.5rem 2.5rem;
    }
    h1 {
      font-family: "Instrument Serif", Georgia, serif; font-size: clamp(1.45rem, 4.5vw, 2rem);
      font-weight: 400; color: var(--accent); line-height: 1.35; margin-bottom: 0.75rem;
    }
    .lead { color: var(--muted); margin-bottom: 1.5rem; }
    h2 {
      font-family: "Instrument Serif", Georgia, serif; font-size: 1.3rem; font-weight: 400;
      color: var(--accent); margin: 1.75rem 0 0.85rem; padding-top: 0.75rem; border-top: 1px solid var(--line);
    }
    ul, ol { margin: 0.5rem 0 0.85rem 1.35rem; }
    li { margin: 0.3rem 0; }
    code { font-size: 0.9em; background: rgba(45,106,79,0.1); padding: 0.1em 0.35em; }
    a.inline { color: var(--accent); word-break: break-all; }
    .callout {
      margin: 1rem 0; padding: 0.85rem 1rem; border-left: 3px solid var(--accent);
      background: rgba(45,106,79,0.08); font-size: 0.95rem;
    }
    .note { font-size: 0.85rem; color: var(--muted); margin-top: 1rem; }
    .chain {
      margin: 1rem 0 0; padding: 0.85rem 1rem; background: rgba(255,255,255,0.65);
      border: 1px dashed var(--line); font-size: 0.92rem;
    }"""

LOGS = [
    {
        "date": "20260916",
        "num": "0916",
        "prev": ("0915", "雙目錄可滑動點選"),
        "next": ("0917", "錯題成因台"),
        "title": "每日14樣功課：改寫為最新潛修清單",
        "nav_app": ("../../apps/daily-14/", "開啟每日14樣功課"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260915-learning-log.html\">0915 雙目錄可滑動點選</a>。本日依最新「每日 14 樣功課」清單改寫完整版與簡易版；本機儲存鍵升版，舊勾選不延用以免編號錯位。",
        "sections": [
            ("一｜新清單（標題）", [
                "1. 基本潛修步驟一：懺悔心法 加 發願 加 行願",
                "2. 基本潛修步驟二：愛與感恩心法 加 秒秒感恩",
                "3. 基本潛修步驟三：太陽心法",
                "4. 看弟子規影片 1 集或以上",
                "5. 聆聽超碼歌曲 3 次以上",
                "6. 照鏡子",
                "7. 閱讀超碼書籍、聆聽網路學習音檔",
                "8. 寫心得",
                "9. 參加每週網路共修",
                "10. 隨時度人",
                "11. 做到去我",
                "12. 積極營造生活",
                "13. 秒秒 GPS、秒秒轉念",
                "14. 從生活中隨機參悟空",
            ]),
            ("二｜同步與儲存", [
                "主 App：完整版與 <code>simple/</code> 簡易版；每項含說明 <code>note</code>。",
                "本機鍵：<code>daily14-v2</code>／<code>daily14-simple-v2</code>（與舊版分開）。",
                "對照：七習慣 <code>DAILY14_MAP</code>、靈命台讀誦標題一併更新。",
            ]),
            ("三｜入口", [
                "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/daily-14/\">https://copyshae.github.io/-/daily-14/</a>",
                "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/daily-14/simple/\">https://copyshae.github.io/-/daily-14/simple/</a>",
            ]),
        ],
        "app": "https://copyshae.github.io/-/daily-14/",
    },
    {
        "date": "20260917",
        "num": "0917",
        "prev": ("0916", "每日14樣功課改寫"),
        "next": ("0918", "手機空間清理"),
        "title": "錯題成因台：概念／計算／粗心",
        "nav_app": ("../../error-cause/", "開啟錯題成因台"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260916-learning-log.html\">0916 每日14樣功課</a>。本日新增「錯題成因台」：用 Gemini 依座號把數學錯題分成<strong>概念錯／計算錯／粗心</strong>，並產出明日講解一句話＋3 題補強與解答。",
        "sections": [
            ("一｜功能", [
                "資料來源：習作批改本機進度、貼上文字、拍照／上傳（掃描王）。",
                "金鑰與習作批改共用本機 <code>math-grader-gemini-key</code>。",
                "單座號分析、整班摘要、儲存／匯出 JSON；只用座號、不存姓名。",
            ]),
            ("二｜入口", [
                "主頁：<a class=\"inline\" href=\"https://copyshae.github.io/-/error-cause/\">https://copyshae.github.io/-/error-cause/</a>",
                "加入主畫面：<a class=\"inline\" href=\"https://copyshae.github.io/-/error-cause/share.html\">https://copyshae.github.io/-/error-cause/share.html</a>",
            ]),
        ],
        "app": "https://copyshae.github.io/-/error-cause/",
    },
    {
        "date": "20260918",
        "num": "0918",
        "prev": ("0917", "錯題成因台"),
        "next": None,
        "title": "手機空間清理：Google 相簿雲端備份",
        "nav_app": ("../../phone-clean/", "開啟手機空間清理"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260917-learning-log.html\">0917 錯題成因台</a>。本日上線手機空間清理頁：引導開啟 Google 相簿「所有照片」權限與雲端備份，備份後釋放裝置空間；並可一鍵清本站快取／掃描圖／收據照片。",
        "sections": [
            ("一｜Google 相簿", [
                "iPhone／Android：開啟備份與「所有照片」權限。",
                "備份完成後在 Google 相簿按「釋放裝置空間」。",
                "權限被拒：系統設定改回允許後重開 App。",
            ]),
            ("二｜一鍵安全清理", [
                "清本站快取、掃描圖、曲庫暫存、購物帳收據照片（保留進度與金鑰）。",
                "另附 Facebook 快取、下載資料夾、非私密截圖、Safari 網站資料步驟。",
                "習作工具首頁已加「清理手機空間」入口。",
            ]),
            ("三｜入口", [
                "主頁：<a class=\"inline\" href=\"https://copyshae.github.io/-/phone-clean/\">https://copyshae.github.io/-/phone-clean/</a>",
                "加入主畫面：<a class=\"inline\" href=\"https://copyshae.github.io/-/phone-clean/share.html\">https://copyshae.github.io/-/phone-clean/share.html</a>",
            ]),
        ],
        "app": "https://copyshae.github.io/-/phone-clean/",
    },
]

CHAIN_IDS = [
    ("0830", "../202608/20260830-learning-log.html"),
    ("0831", "../202608/20260831-learning-log.html"),
    ("0901", "./20260901-learning-log.html"),
    ("0902", "./20260902-learning-log.html"),
    ("0903", "./20260903-learning-log.html"),
    ("0904", "./20260904-learning-log.html"),
    ("0905", "./20260905-learning-log.html"),
    ("0906", "./20260906-learning-log.html"),
    ("0907", "./20260907-learning-log.html"),
    ("0908", "./20260908-learning-log.html"),
    ("0909", "./20260909-learning-log.html"),
    ("0910", "./20260910-learning-log.html"),
    ("0911", "./20260911-learning-log.html"),
    ("0912", "./20260912-learning-log.html"),
    ("0913", "./20260913-learning-log.html"),
    ("0914", "./20260914-learning-log.html"),
    ("0915", "./20260915-learning-log.html"),
    ("0916", "./20260916-learning-log.html"),
    ("0917", "./20260917-learning-log.html"),
    ("0918", "./20260918-learning-log.html"),
]


def chain_html(upto: str) -> str:
    parts = []
    for num, href in CHAIN_IDS:
        parts.append(f'<a class="inline" href="{href}">{num}</a>')
        if num == upto:
            break
    return " →\n        ".join(parts)


def render(log: dict) -> str:
    date, num = log["date"], log["num"]
    prev_num, prev_title = log["prev"]
    prev_href = f"./202609{prev_num[2:]}-learning-log.html"
    next_html = ""
    if log["next"]:
        nn, nt = log["next"]
        next_html = f'｜下一則：<a class="inline" href="./202609{nn[2:]}-learning-log.html">{nn} {nt}</a>'
    nav_href, nav_label = log["nav_app"]
    body_sections = []
    for title, items in log["sections"]:
        lis = "\n".join(f"        <li>{x}</li>" for x in items)
        body_sections.append(f"      <h2>{title}</h2>\n      <ul>\n{lis}\n      </ul>")
    sections_html = "\n\n".join(body_sections)
    url = f"https://copyshae.github.io/-/directory/202609/{date}-learning-log.html"
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
      <a href="../../index.html">← 習作工具首頁</a>
      <a href="../index.html">← 學習日誌首頁</a>
      <a href="./index.html">← 本月列表</a>
      <a href="{nav_href}">{nav_label}</a>
    </nav>
    <article>
      <h1>{date} {log["title"]}</h1>
      <p class="lead">{log["lead"]}</p>
      <div class="callout"><strong>手機立刻可開（免開電腦；網址須有 <code>co</code>：copyshae）：</strong><br />
        本篇：<a class="inline" href="{url}">{url}</a><br />
        App：<a class="inline" href="{log["app"]}">{log["app"]}</a>
      </div>

{sections_html}

      <div class="chain">
        <strong>日期連續（依主題一天接一天）</strong>：
        {chain_html(num)}
        ｜<a class="inline" href="../index.html">學習日誌首頁</a>
      </div>
      <p class="note">
        本篇：<a class="inline" href="{url}">{url}</a>
        ｜上一則：<a class="inline" href="{prev_href}">{prev_num} {prev_title}</a>
        {next_html}
        ｜App：<a class="inline" href="{log["app"]}">{log["app"]}</a>
        ｜<a class="inline" href="../index.html">學習日誌首頁</a>
      </p>
    </article>
  </div>
</body>
</html>
"""


def write_log(log: dict) -> None:
    html = render(log)
    name = f"{log['date']}-learning-log.html"
    for base in (DOCS_609, EXPORT_609):
        base.mkdir(parents=True, exist_ok=True)
        (base / name).write_text(html, encoding="utf-8")
        print("wrote", base / name)


def patch_0915_next() -> None:
    for base in (DOCS_609, EXPORT_609):
        path = base / "20260915-learning-log.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        old_chain_end = (
            '<a class="inline" href="./20260915-learning-log.html">0915</a>\n'
            "        ｜<a class=\"inline\" href=\"../index.html\">學習日誌首頁</a>"
        )
        new_chain_end = (
            '<a class="inline" href="./20260915-learning-log.html">0915</a> →\n'
            '        <a class="inline" href="./20260916-learning-log.html">0916</a> →\n'
            '        <a class="inline" href="./20260917-learning-log.html">0917</a> →\n'
            '        <a class="inline" href="./20260918-learning-log.html">0918</a>\n'
            '        ｜<a class="inline" href="../index.html">學習日誌首頁</a>'
        )
        if "20260918-learning-log.html" not in t and old_chain_end in t:
            t = t.replace(old_chain_end, new_chain_end)
        note_old = (
            "｜上一則：<a class=\"inline\" href=\"./20260914-learning-log.html\">0914 新聞主播頭條修復</a>\n"
            "        \n"
            "        ｜App："
        )
        note_new = (
            "｜上一則：<a class=\"inline\" href=\"./20260914-learning-log.html\">0914 新聞主播頭條修復</a>\n"
            "        ｜下一則：<a class=\"inline\" href=\"./20260916-learning-log.html\">0916 每日14樣功課改寫</a>\n"
            "        ｜App："
        )
        if "0916 每日14樣功課" not in t and note_old in t:
            t = t.replace(note_old, note_new)
        path.write_text(t, encoding="utf-8")
        print("patched", path)


def write_month_index() -> None:
    items = [
        ("20260918", "手機空間清理：Google 相簿雲端備份", "相簿備份｜釋放空間｜https://copyshae.github.io/-/phone-clean/"),
        ("20260917", "錯題成因台：概念／計算／粗心", "Gemini｜座號｜https://copyshae.github.io/-/error-cause/"),
        ("20260916", "每日14樣功課：改寫為最新潛修清單", "潛修清單｜v2 儲存｜https://copyshae.github.io/-/daily-14/"),
        ("20260915", "太陽盛德創作歌曲：雙目錄可滑動點選", "搜尋曲庫｜天圓音樂頻道｜https://copyshae.github.io/-/directory/apps/taiyang-music/"),
        ("20260914", "新聞主播：修好頭條即時更新 422", "rss2json 422｜備援 XML｜https://copyshae.github.io/-/news-anchor/"),
        ("20260913", "看書／看文件：拍照＋Google AI 辨識", "拍照為主｜Gemini 辨識｜https://copyshae.github.io/-/doc-reader/"),
        ("20260912", "全站 AQ. 金鑰＋Gemini 3.6 Flash", "AQ. 金鑰｜3.6 Flash｜基金／購物帳等"),
        ("20260911", "基金自動搜尋＋ETF（0052／00747）", "自動搜尋補欄位｜ETF 折溢價｜https://copyshae.github.io/-/fund-eval/"),
        ("20260910", "基金評估台（進出場＋排序）", "投資分數｜加碼減碼｜https://copyshae.github.io/-/fund-eval/"),
        ("20260909", "中英對照改到影片下方", "不遮畫面｜放大仍有字幕｜https://copyshae.github.io/-/cursor-learn/"),
        ("20260908", "Cursor 對時內容字幕與中文人聲", "內容分段｜非只唸主題｜https://copyshae.github.io/-/cursor-learn/"),
        ("20260907", "兩個學習平台：Cursor＋英文短影音", "YouTube 學習｜由淺入深｜加入主畫面"),
        ("20260906", "學員分享影音圖書館", "問題→國家兩層｜約 294 則｜https://copyshae.github.io/-/xueyuan-lib/"),
        ("20260905", "家電家具購物帳", "總花費｜辨識登錄｜https://copyshae.github.io/-/home-shop/"),
        ("20260904", "學習日誌 0830–0903 連續補齊", "一天一主題對齊目錄與 Pages"),
        ("20260903", "每日14樣功課簡易版（可分享）", "精簡勾選｜與完整版分開｜https://copyshae.github.io/-/daily-14/simple/"),
        ("20260902", "Google 新聞虛擬主播", "多分類｜口說輸入｜https://copyshae.github.io/-/news-anchor/"),
        ("20260901", "太陽心語圖片收錄（美聲朗讀）", "原圖語錄｜美聲朗讀｜https://copyshae.github.io/-/taiyang-xinyu/"),
    ]
    lis = []
    for date, title, span in items:
        lis.append(
            f"""      <li>
        <a href="{date}-learning-log.html">
          {date} {title}
          <span>{span}</span>
        </a>
      </li>"""
        )
    html = f"""<!DOCTYPE html>
<html lang="zh-Hant">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>202609｜學習日誌</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=DM+Sans:opsz,wght@9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet" />
  <style>
    :root {{ --ink: #1a1f1c; --paper: #e8efe6; --accent: #2d6a4f; --muted: #4a5c52; }}
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      min-height: 100vh; font-family: "DM Sans", sans-serif; color: var(--ink);
      background:
        radial-gradient(ellipse 80% 60% at 20% 10%, rgba(149, 213, 178, 0.45), transparent 55%),
        radial-gradient(ellipse 70% 50% at 90% 80%, rgba(45, 106, 79, 0.18), transparent 50%),
        linear-gradient(160deg, #f4faf6 0%, var(--paper) 45%, #d8e8dc 100%);
    }}
    .wrap {{ max-width: 40rem; margin: 0 auto; padding: 2.5rem 1.5rem 4rem; }}
    .nav {{ display: flex; flex-wrap: wrap; gap: 1rem; margin-bottom: 2rem; }}
    .nav a {{ color: var(--accent); text-decoration: none; font-weight: 500; font-size: 0.95rem; }}
    .nav a:hover {{ text-decoration: underline; text-underline-offset: 0.2em; }}
    h1 {{
      font-family: "Instrument Serif", Georgia, serif; font-size: clamp(1.6rem, 5vw, 2.2rem);
      font-weight: 400; color: var(--accent); letter-spacing: 0.04em; line-height: 1.3;
    }}
    .lead {{ margin-top: 0.75rem; color: var(--muted); font-size: 1.05rem; line-height: 1.6; }}
    .dir-list {{ list-style: none; margin-top: 1.25rem; display: flex; flex-direction: column; gap: 0.85rem; }}
    .dir-list a {{
      display: block; padding: 1.15rem 1.35rem; background: rgba(255, 255, 255, 0.55);
      border: 1px solid rgba(45, 106, 79, 0.22); color: var(--ink); text-decoration: none;
      font-weight: 600; font-size: 1.15rem;
    }}
    .dir-list a:hover {{ background: rgba(255, 255, 255, 0.9); border-color: var(--accent); }}
    .dir-list a span {{ display: block; margin-top: 0.35rem; font-weight: 400; font-size: 0.9rem; color: var(--muted); }}
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
    <p class="lead">接 0915，連續一天一主題至 <strong>0918</strong>（最新）。由新到舊排列。</p>
    <ul class="dir-list">
{chr(10).join(lis)}
    </ul>
  </div>
</body>
</html>
"""
    for base in (DOCS_609, EXPORT_609):
        (base / "index.html").write_text(html, encoding="utf-8")
        print("index", base)


def patch_directory_index() -> None:
    for base in (DOCS_DIR, EXPORT_DIR):
        path = base / "index.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        t = t.replace(
            "202609（0901–0915 連續主題｜最新 0915）",
            "202609（0901–0918 連續主題｜最新 0918）",
        )
        path.write_text(t, encoding="utf-8")
        print("dir index", path)


def write_learning_log_redirect() -> None:
    html = """<!DOCTYPE html>
<html lang="zh-Hant">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>學習日誌｜最新</title>
  <link rel="canonical" href="./202609/20260918-learning-log.html" />
  <meta http-equiv="refresh" content="0; url=./202609/20260918-learning-log.html" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&family=Instrument+Serif&display=swap" rel="stylesheet" />
  <style>
    :root { --ink:#1a1f1c; --paper:#e8efe6; --accent:#2d6a4f; --muted:#4a5c52; --line:rgba(45,106,79,.22); }
    * { box-sizing:border-box; margin:0; padding:0; }
    body {
      min-height:100vh; font-family:"DM Sans",sans-serif; color:var(--ink); line-height:1.7;
      background: radial-gradient(ellipse 80% 50% at 10% 0%, rgba(149,213,178,.35), transparent 55%),
        linear-gradient(160deg,#f4faf6 0%, var(--paper) 50%, #d8e8dc 100%);
    }
    .wrap { max-width:40rem; margin:0 auto; padding:2rem 1.35rem 4rem; }
    a { color:var(--accent); }
    h1 { font-family:"Instrument Serif",Georgia,serif; font-weight:400; color:var(--accent); font-size:clamp(1.5rem,5vw,2rem); margin:1rem 0 .75rem; }
    .card { background:rgba(255,255,255,.55); border:1px solid var(--line); padding:1.25rem 1.2rem; margin:.75rem 0; }
    .muted { color:var(--muted); font-size:.95rem; }
    code { font-size:.9em; background:rgba(45,106,79,.1); padding:.1em .35em; }
  </style>
</head>
<body>
  <div class="wrap">
    <p><a href="./">← 學習日誌首頁</a></p>
    <h1>學習日誌最新</h1>
    <p class="muted">正式檔名：<code>directory/YYYYMM/YYYYMMDD-learning-log.html</code>。</p>
    <div class="card">
      <p><strong>今天 0918（手機空間清理：Google 相簿雲端備份）</strong></p>
      <p><a href="./202609/20260918-learning-log.html">https://copyshae.github.io/-/directory/202609/20260918-learning-log.html</a></p>
    </div>
    <div class="card">
      <p><strong>0916–0917</strong></p>
      <p><a href="./202609/20260916-learning-log.html">0916 每日14樣功課改寫</a> ·
         <a href="./202609/20260917-learning-log.html">0917 錯題成因台</a></p>
    </div>
    <div class="card">
      <p><strong>九月列表</strong></p>
      <p><a href="./202609/">https://copyshae.github.io/-/directory/202609/</a></p>
    </div>
  </div>
</body>
</html>
"""
    for base in (DOCS_DIR, EXPORT_DIR):
        (base / "learning-log.html").write_text(html, encoding="utf-8")
        print("learning-log redirect", base)


def main() -> None:
    EXPORT_609.mkdir(parents=True, exist_ok=True)
    DOCS_609.mkdir(parents=True, exist_ok=True)
    for log in LOGS:
        write_log(log)
    patch_0915_next()
    write_month_index()
    patch_directory_index()
    write_learning_log_redirect()
    print("OK 0916–0918")


if __name__ == "__main__":
    main()
