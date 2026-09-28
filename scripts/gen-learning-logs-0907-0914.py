#!/usr/bin/env python3
"""Generate 0907–0914 learning logs. One theme per day, consecutive after 0906."""
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

# 接 0906，一天一主題
LOGS = [
    {
        "date": "20260907",
        "num": "0907",
        "prev": ("0906", "學員分享影音圖書館"),
        "next": ("0908", "Cursor 對時字幕與中文人聲"),
        "title": "兩個學習平台：Cursor 學習＋英文短影音",
        "nav_app": ("../../cursor-learn/", "開啟 Cursor 學習"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260906-learning-log.html\">0906 學員影音庫</a>。本日上線兩個 YouTube 學習 PWA：Cursor 相關影片由淺入深；英文短影音可依程度篩選，皆可加入主畫面。",
        "sections": [
            ("一｜入口", [
                "Cursor 學習：<a class=\"inline\" href=\"https://copyshae.github.io/-/cursor-learn/\">https://copyshae.github.io/-/cursor-learn/</a>",
                "英文短影音：<a class=\"inline\" href=\"https://copyshae.github.io/-/english-shorts/\">https://copyshae.github.io/-/english-shorts/</a>",
                "加入主畫面：各站 <code>share.html</code>；網址須打 <strong>copyshae</strong>（有 co）。",
            ]),
            ("二｜重點", [
                "兩邊都是匯入 YouTube 來學；Cursor 站只收 Cursor 相關影片。",
                "清單由淺入深；點縮圖即播；本機進度／匯入可存。",
                "路徑：<code>docs/cursor-learn/</code>、<code>docs/english-shorts/</code>。",
            ]),
        ],
        "app": "https://copyshae.github.io/-/cursor-learn/",
    },
    {
        "date": "20260908",
        "num": "0908",
        "prev": ("0907", "兩個學習平台"),
        "next": ("0909", "中英對照改到影片下方"),
        "title": "Cursor 對時內容字幕與連續中文人聲",
        "nav_app": ("../../cursor-learn/", "開啟 Cursor 學習"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260907-learning-log.html\">0907 兩個學習平台</a>。本日強化 Cursor 學習：持續中文旁白與字幕跟著<strong>內容分段</strong>，不是只唸主題一句。",
        "sections": [
            ("一｜做法", [
                "預建 <code>captions/bundle.json</code>：種子片分段中英內容。",
                "優先：原片字幕翻譯 → 內容字幕包 → 腳本分段；大字／人聲對時跟讀。",
                "開「中文旁白連說」與「影片連播」可連續學多支。",
            ]),
            ("二｜入口", [
                "<a class=\"inline\" href=\"https://copyshae.github.io/-/cursor-learn/\">https://copyshae.github.io/-/cursor-learn/</a>",
            ]),
        ],
        "app": "https://copyshae.github.io/-/cursor-learn/",
    },
    {
        "date": "20260909",
        "num": "0909",
        "prev": ("0908", "對時內容字幕與中文人聲"),
        "next": ("0910", "基金評估台"),
        "title": "中英對照改到影片下方（不遮畫面）",
        "nav_app": ("../../cursor-learn/", "開啟 Cursor 學習"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260908-learning-log.html\">0908 對時字幕</a>。本日把中英對照改放<strong>影片下方兩列</strong>（上英下中），不再蓋住畫面；按「放大」全螢幕仍保留字幕。",
        "sections": [
            ("一｜變更", [
                "預設「中英對照」：字幕區在播放器下方，不遮教學畫面。",
                "字級改為閱讀大小；可切中文／英文／關。",
                "「放大」全螢幕包住影片＋下方字幕（避免 YouTube 內建全螢幕後字幕消失）。",
            ]),
            ("二｜入口", [
                "<a class=\"inline\" href=\"https://copyshae.github.io/-/cursor-learn/\">https://copyshae.github.io/-/cursor-learn/</a>",
            ]),
        ],
        "app": "https://copyshae.github.io/-/cursor-learn/",
    },
    {
        "date": "20260910",
        "num": "0910",
        "prev": ("0909", "中英對照改到影片下方"),
        "next": ("0911", "基金自動搜尋與 ETF"),
        "title": "基金評估台（進出場＋最值得投資排序）",
        "nav_app": ("../../fund-eval/", "開啟基金評估台"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260909-learning-log.html\">0909 中英對照字幕</a>。本日新增基金評估台：欄位 A–P、加碼／減碼標示、投資分數排序；可新增刪除編輯。",
        "sections": [
            ("一｜入口", [
                "正式：<a class=\"inline\" href=\"https://copyshae.github.io/-/fund-eval/\">https://copyshae.github.io/-/fund-eval/</a>",
                "加入主畫面：<a class=\"inline\" href=\"https://copyshae.github.io/-/fund-eval/share.html\">https://copyshae.github.io/-/fund-eval/share.html</a>",
            ]),
            ("二｜功能", [
                "自動算 52 週位階%、年線偏離%；標示加碼／續抱領息／減碼警戒／待補資料。",
                "投資分數綜合買訊、位階、乖離、配息品質等；清單由上而下 #1 最優先。",
                "買點／賣點郵件可設門檻（FormSubmit）；路徑 <code>docs/fund-eval/</code>。",
            ]),
        ],
        "app": "https://copyshae.github.io/-/fund-eval/",
    },
    {
        "date": "20260911",
        "num": "0911",
        "prev": ("0910", "基金評估台"),
        "next": ("0912", "全站 AQ. 金鑰與 Gemini 3.6"),
        "title": "基金自動搜尋網路補資料＋ETF（0052／00747）",
        "nav_app": ("../../fund-eval/", "開啟基金評估台"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260910-learning-log.html\">0910 基金評估台</a>。本日加上 Gemini＋搜尋自動補欄位；台股 ETF 0052／00747 走折溢價邏輯。",
        "sections": [
            ("一｜自動搜尋", [
                "單檔「自動搜尋」或批次「待補／全部」；整理淨值、52 週、配息或折溢價等參考欄位。",
                "台股 ETF 可先試 Yahoo 價位。",
            ]),
            ("二｜ETF", [
                "0052 富邦科技、00747：走 ETF 邏輯（52 週、年線乖離、折溢價、追蹤指數）。",
                "不套用本金配息／HY 利差；其餘境外基金分析照舊。",
            ]),
        ],
        "app": "https://copyshae.github.io/-/fund-eval/",
    },
    {
        "date": "20260912",
        "num": "0912",
        "prev": ("0911", "基金自動搜尋與 ETF"),
        "next": ("0913", "看書拍照＋Google AI"),
        "title": "全站支援 AQ. 金鑰＋改用 Gemini 3.6 Flash",
        "nav_app": ("../../fund-eval/", "開啟基金評估台"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260911-learning-log.html\">0911 自動搜尋與 ETF</a>。本日全站接受 AI Studio 新金鑰 <code>AQ.</code>；模型改 Gemini 3.6 Flash。",
        "sections": [
            ("一｜金鑰", [
                "新金鑰為 <code>AQ.</code>（Auth key），不再限 <code>AIza</code>。",
                "呼叫改 <code>x-goog-api-key</code>：基金／購物帳／習作批改／新聞／掃具／看書／英文短影音／修煉心得等。",
                "金鑰只貼在 App，勿提交 GitHub。",
            ]),
            ("二｜模型", [
                "新用戶無法再用 2.5 Flash；已改 <code>gemini-3.6-flash</code>（備援 3.5）。",
                "購物帳辨識同步更新；請強制重新整理後再試。",
            ]),
        ],
        "app": "https://copyshae.github.io/-/fund-eval/",
    },
    {
        "date": "20260913",
        "num": "0913",
        "prev": ("0912", "AQ. 金鑰與 Gemini 3.6"),
        "next": ("0914", "新聞主播頭條修復"),
        "title": "看書／看文件：拍照＋Google AI 辨識",
        "nav_app": ("../../doc-reader/", "開啟看書／看文件"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260912-learning-log.html\">0912 AQ. 金鑰</a>。本日看書 App 匯入改以拍照為主；有 Gemini 金鑰時用 Google API 辨識文字。",
        "sections": [
            ("一｜變更", [
                "匯入：拍照為主、相簿次之；PDF／網址／貼上收進次要區。",
                "有金鑰 → Google API 辨識；失敗或無金鑰 → 本機 OCR。",
            ]),
            ("二｜入口", [
                "<a class=\"inline\" href=\"https://copyshae.github.io/-/doc-reader/\">https://copyshae.github.io/-/doc-reader/</a>",
            ]),
        ],
        "app": "https://copyshae.github.io/-/doc-reader/",
    },
    {
        "date": "20260914",
        "num": "0914",
        "prev": ("0913", "看書拍照＋Google AI"),
        "next": None,
        "title": "新聞主播：修好頭條即時更新 422",
        "nav_app": ("../../news-anchor/", "開啟新聞主播"),
        "lead": "接日誌 <a class=\"inline\" href=\"./20260913-learning-log.html\">0913 看書拍照</a>。本日修好 Google「頭條」RSS 經 rss2json 回 422：改備援抓 XML 並解析。",
        "sections": [
            ("一｜修復", [
                "原因：rss2json 無法轉換 Google 頭條 RSS（HTTP 422）。",
                "改為備援抓取 XML（allorigins）並解析；失敗再試國內分類。",
                "正式網址請用 <strong>copyshae</strong>（勿打成 pyshae）。",
            ]),
            ("二｜入口", [
                "<a class=\"inline\" href=\"https://copyshae.github.io/-/news-anchor/\">https://copyshae.github.io/-/news-anchor/</a>",
            ]),
        ],
        "app": "https://copyshae.github.io/-/news-anchor/",
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
    prev_date = f"202609{prev_num[2:]}" if prev_num.startswith("09") else f"202608{prev_num[2:]}"
    prev_href = f"./202609{prev_num[2:]}-learning-log.html" if prev_num.startswith("09") else f"../202608/{prev_date}-learning-log.html"
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


def patch_0906_next() -> None:
    for base in (DOCS_609, EXPORT_609):
        path = base / "20260906-learning-log.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        if "20260907-learning-log.html" in t:
            continue
        # extend chain
        old = """        <a class="inline" href="./20260906-learning-log.html">0906</a>
        ｜<a class="inline" href="../index.html">學習日誌首頁</a>"""
        new = """        <a class="inline" href="./20260906-learning-log.html">0906</a> →
        <a class="inline" href="./20260907-learning-log.html">0907</a> →
        <a class="inline" href="./20260908-learning-log.html">0908</a> →
        <a class="inline" href="./20260909-learning-log.html">0909</a> →
        <a class="inline" href="./20260910-learning-log.html">0910</a> →
        <a class="inline" href="./20260911-learning-log.html">0911</a> →
        <a class="inline" href="./20260912-learning-log.html">0912</a> →
        <a class="inline" href="./20260913-learning-log.html">0913</a> →
        <a class="inline" href="./20260914-learning-log.html">0914</a>
        ｜<a class="inline" href="../index.html">學習日誌首頁</a>"""
        if old in t:
            t = t.replace(old, new)
        note_old = "｜上一則：<a class=\"inline\" href=\"./20260905-learning-log.html\">0905 家電家具購物帳</a>\n        ｜App："
        note_new = (
            "｜上一則：<a class=\"inline\" href=\"./20260905-learning-log.html\">0905 家電家具購物帳</a>\n"
            "        ｜下一則：<a class=\"inline\" href=\"./20260907-learning-log.html\">0907 兩個學習平台</a>\n"
            "        ｜App："
        )
        if note_old in t and "0907 兩個學習平台" not in t:
            t = t.replace(note_old, note_new)
        path.write_text(t, encoding="utf-8")
        print("patched", path)


def write_month_index() -> None:
    items = [
        ("20260914", "0914", "新聞主播：修好頭條即時更新 422", "rss2json 422｜備援 XML｜https://copyshae.github.io/-/news-anchor/"),
        ("20260913", "0913", "看書／看文件：拍照＋Google AI 辨識", "拍照為主｜Gemini 辨識｜https://copyshae.github.io/-/doc-reader/"),
        ("20260912", "0912", "全站 AQ. 金鑰＋Gemini 3.6 Flash", "AQ. 金鑰｜3.6 Flash｜基金／購物帳等"),
        ("20260911", "0911", "基金自動搜尋＋ETF（0052／00747）", "自動搜尋補欄位｜ETF 折溢價｜https://copyshae.github.io/-/fund-eval/"),
        ("20260910", "0910", "基金評估台（進出場＋排序）", "投資分數｜加碼減碼｜https://copyshae.github.io/-/fund-eval/"),
        ("20260909", "0909", "中英對照改到影片下方", "不遮畫面｜放大仍有字幕｜https://copyshae.github.io/-/cursor-learn/"),
        ("20260908", "0908", "Cursor 對時內容字幕與中文人聲", "內容分段｜非只唸主題｜https://copyshae.github.io/-/cursor-learn/"),
        ("20260907", "0907", "兩個學習平台：Cursor＋英文短影音", "YouTube 學習｜由淺入深｜加入主畫面"),
        ("20260906", "0906", "學員分享影音圖書館", "問題→國家兩層｜約 294 則｜https://copyshae.github.io/-/xueyuan-lib/"),
        ("20260905", "0905", "家電家具購物帳", "總花費｜辨識登錄｜https://copyshae.github.io/-/home-shop/"),
        ("20260904", "0904", "學習日誌 0830–0903 連續補齊", "一天一主題對齊目錄與 Pages"),
        ("20260903", "0903", "每日14樣功課簡易版（可分享）", "精簡勾選｜與完整版分開｜https://copyshae.github.io/-/daily-14/simple/"),
        ("20260902", "0902", "Google 新聞虛擬主播", "多分類｜口說輸入｜https://copyshae.github.io/-/news-anchor/"),
        ("20260901", "0901", "太陽心語圖片收錄（美聲朗讀）", "原圖語錄｜美聲朗讀｜https://copyshae.github.io/-/taiyang-xinyu/"),
    ]
    lis = []
    for date, num, title, span in items:
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
    <p class="lead">接 0906，連續一天一主題至 <strong>0914</strong>（最新）。由新到舊排列。</p>
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


def sync_existing_0904_06() -> None:
    """Ensure export has 0904–0906 from docs."""
    for n in ("04", "05", "06"):
        src = DOCS_609 / f"202609{n}-learning-log.html"
        if src.exists():
            dst = EXPORT_609 / src.name
            dst.write_text(src.read_text(encoding="utf-8"), encoding="utf-8")
            print("sync export", dst.name)


def patch_directory_index() -> None:
    for base in (DOCS_DIR, EXPORT_DIR):
        path = base / "index.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        t2 = t.replace(
            "202609（0901–0903 連續主題）",
            "202609（0901–0914 連續主題｜最新 0914）",
        )
        if t2 == t and "0914" not in t:
            t2 = t.replace(
                '<a href="202609/">202609（0901–0903 連續主題）</a>',
                '<a href="202609/">202609（0901–0914 連續主題｜最新 0914）</a>',
            )
        path.write_text(t2, encoding="utf-8")
        print("dir index", path)


def main() -> None:
    EXPORT_609.mkdir(parents=True, exist_ok=True)
    DOCS_609.mkdir(parents=True, exist_ok=True)
    sync_existing_0904_06()
    for log in LOGS:
        write_log(log)
    patch_0906_next()
    write_month_index()
    patch_directory_index()
    print("OK 0907–0914")


if __name__ == "__main__":
    main()
