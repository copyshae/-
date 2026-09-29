#!/usr/bin/env python3
"""Generate 0915 learning log. Continues after 0914 (one theme per day)."""
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

LOG = {
    "date": "20260915",
    "num": "0915",
    "prev": ("0914", "新聞主播頭條修復"),
    "next": None,
    "title": "太陽盛德創作歌曲：雙目錄可滑動點選",
    "nav_app": ("../../apps/taiyang-music/", "開啟太陽盛德創作歌曲"),
    "lead": "接日誌 <a class=\"inline\" href=\"./20260914-learning-log.html\">0914 新聞主播</a>。本日把先前網路搜尋曲庫與天圓音樂官方頻道拆成<strong>兩個目錄</strong>，介面可左右滑動點選；搜尋目錄保留連播／選歌／伴唱等原功能。",
    "sections": [
        ("一｜兩個目錄", [
            "<strong>搜尋曲庫</strong>（<code>catalog.json</code>）：先前關鍵字搜尋的歌曲，可連播、選歌即播、分類、伴唱。",
            "<strong>天圓音樂</strong>（<code>channel-directory.json</code>）：官方頻道 <a class=\"inline\" href=\"https://www.youtube.com/@supertianyuan168\">@supertianyuan168</a>，自成一格供程式讀取。",
            "索引：<code>directories.json</code>；兩格可左右滑動後點選。",
        ]),
        ("二｜入口", [
            "完整版：<a class=\"inline\" href=\"https://copyshae.github.io/-/directory/apps/taiyang-music/\">https://copyshae.github.io/-/directory/apps/taiyang-music/</a>",
            "簡易版：<a class=\"inline\" href=\"https://copyshae.github.io/-/directory/apps/taiyang-music/simple/\">https://copyshae.github.io/-/directory/apps/taiyang-music/simple/</a>",
            "網址須打 <strong>copyshae</strong>（有 co）。",
        ]),
    ],
    "app": "https://copyshae.github.io/-/directory/apps/taiyang-music/",
}

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


def write_log() -> None:
    html = render(LOG)
    name = f"{LOG['date']}-learning-log.html"
    for base in (DOCS_609, EXPORT_609):
        base.mkdir(parents=True, exist_ok=True)
        (base / name).write_text(html, encoding="utf-8")
        print("wrote", base / name)


def patch_0914_next() -> None:
    for base in (DOCS_609, EXPORT_609):
        path = base / "20260914-learning-log.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        # chain extend
        if "20260915-learning-log.html" not in t:
            t = t.replace(
                '<a class="inline" href="./20260914-learning-log.html">0914</a>\n        ｜<a class="inline" href="../index.html">學習日誌首頁</a>',
                '<a class="inline" href="./20260914-learning-log.html">0914</a> →\n'
                '        <a class="inline" href="./20260915-learning-log.html">0915</a>\n'
                '        ｜<a class="inline" href="../index.html">學習日誌首頁</a>',
            )
        if "0915" not in t.split("下一則")[-1] if "下一則" in t else True:
            old = "｜App：<a class=\"inline\" href=\"https://copyshae.github.io/-/news-anchor/\">https://copyshae.github.io/-/news-anchor/</a>"
            # insert next before App in note if missing
            if "下一則：<a class=\"inline\" href=\"./20260915-learning-log.html\">" not in t:
                t = t.replace(
                    "｜上一則：<a class=\"inline\" href=\"./20260913-learning-log.html\">0913 看書拍照＋Google AI</a>\n"
                    "        ｜App：",
                    "｜上一則：<a class=\"inline\" href=\"./20260913-learning-log.html\">0913 看書拍照＋Google AI</a>\n"
                    "        ｜下一則：<a class=\"inline\" href=\"./20260915-learning-log.html\">0915 雙目錄可滑動點選</a>\n"
                    "        ｜App：",
                )
                # alternate title text for 0913
                if "下一則：<a class=\"inline\" href=\"./20260915-learning-log.html\">" not in t:
                    t = t.replace(
                        "｜上一則：<a class=\"inline\" href=\"./20260913-learning-log.html\">0913 看書拍照＋Google AI 辨識</a>\n"
                        "        ｜App：",
                        "｜上一則：<a class=\"inline\" href=\"./20260913-learning-log.html\">0913 看書拍照＋Google AI 辨識</a>\n"
                        "        ｜下一則：<a class=\"inline\" href=\"./20260915-learning-log.html\">0915 雙目錄可滑動點選</a>\n"
                        "        ｜App：",
                    )
        path.write_text(t, encoding="utf-8")
        print("patched", path)


def write_month_index() -> None:
    # reuse existing index and prepend 0915
    for base in (DOCS_609, EXPORT_609):
        path = base / "index.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        t = t.replace(
            "連續一天一主題至 <strong>0914</strong>（最新）",
            "連續一天一主題至 <strong>0915</strong>（最新）",
        )
        item = """      <li>
        <a href="20260915-learning-log.html">
          20260915 太陽盛德創作歌曲：雙目錄可滑動點選
          <span>搜尋曲庫｜天圓音樂頻道｜https://copyshae.github.io/-/directory/apps/taiyang-music/</span>
        </a>
      </li>
"""
        if "20260915-learning-log.html" not in t:
            t = t.replace(
                '    <ul class="dir-list">\n      <li>\n        <a href="20260914-learning-log.html">',
                f'    <ul class="dir-list">\n{item}      <li>\n        <a href="20260914-learning-log.html">',
            )
        path.write_text(t, encoding="utf-8")
        print("index", path)


def patch_directory_index() -> None:
    for base in (DOCS_DIR, EXPORT_DIR):
        path = base / "index.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        t = t.replace(
            "202609（0901–0914 連續主題｜最新 0914）",
            "202609（0901–0915 連續主題｜最新 0915）",
        )
        path.write_text(t, encoding="utf-8")
        print("dir index", path)


def main() -> None:
    write_log()
    patch_0914_next()
    write_month_index()
    patch_directory_index()
    print("done 0915")


if __name__ == "__main__":
    main()
