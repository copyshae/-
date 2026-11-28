#!/usr/bin/env python3
"""Generate 0916 learning log. Continues after 0915 (one theme per day)."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPORT_609 = ROOT / "_export/hello-world/directory/202609"
DOCS_609 = ROOT / "docs/directory/202609"
EXPORT_DIR = ROOT / "_export/hello-world/directory"
DOCS_DIR = ROOT / "docs/directory"
EXPORT_611 = ROOT / "_export/hello-world/directory/202611"
DOCS_611 = ROOT / "docs/directory/202611"

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
    "date": "20260916",
    "num": "0916",
    "prev": ("0915", "雙目錄可滑動點選"),
    "next": None,
    "title": "公開資料分析：二林選情、核電利弊與戰時核安",
    "nav_app": ("../index.html", "學習日誌首頁"),
    "lead": "接日誌 <a class=\"inline\" href=\"./20260915-learning-log.html\">0915 雙目錄可滑動點選</a>。本日用 Cursor 雲端 Agent 搜尋公開資料，整理<strong>二林鎮長／第8選區縣議員</strong>政治貢獻評分，以及<strong>核電 vs 非核家園</strong>、<strong>台海若攻擊核電廠</strong>的風險層級（非投票建議）。",
    "sections": [
        (
            "一｜二林鎮長三人（政治貢獻綜合）",
            [
                "候選人：1 許杰霖（無黨）、2 吳聰明（民進黨）、3 陳一惇（國民黨）。",
                "綜合排序（含誠信構面）：<strong>陳一惇 90</strong> → 吳聰明 69 → 許杰霖 66。",
                "陳一惇：縣議員四連霸、台76／中科／漁養等紀錄最完整；許杰霖曾任鎮代會主席但有賄選交保案（未定讞）；吳聰明鎮代三連霸、村里建設扎實。",
            ],
        ),
        (
            "二｜彰化縣議員第8選區（二林／大城／芳苑／竹塘）",
            [
                "應選5席、9人參選。終身貢獻領先：<strong>吳淑娟、張國棟</strong>；近一年公開積極度較突出：<strong>洪子超、洪騰明</strong>。",
                "挑戰者中近一年聲量較高：洪雅婷（長照／青農）；曾温泉接棒陳一惇系統；謝淑如、黃淑儀、洪健興公開可查作為較少。",
            ],
        ),
        (
            "三｜核電 vs 非核家園",
            [
                "平衡加權約核電 63／非核 61；若只問<strong>經濟命脈</strong>（半導體／AI、供電、氣電曝險）則核電選項約 <strong>76 vs 53</strong>。",
                "最貼經濟命脈的答案是<strong>核綠共存</strong>：核／氣先吃飽，綠電滿足 RE100；不是廢綠只靠核。",
                "2025/05 後商用核電占比為零；再生能源約 13%；燃氣約近半。",
            ],
        ),
        (
            "四｜台海若「攻擊核電廠」",
            [
                "<strong>被波及／打外電／致癱</strong>：風險高；<strong>蓄意打成核災</strong>：低～中，但不是零。",
                "攻擊 ≠ 核爆。關鍵脆弱點多為<strong>用過燃料池冷卻</strong>與廠區火災／失電；機組已停仍非「廠區無放射性物質」。",
                "烏克蘭札波羅熱顯示：占領與干擾常見，全國性輻射異常並非常態，但長期處在懸崖邊。",
            ],
        ),
        (
            "五｜注意",
            [
                "以上為公開報導與官方文件之結構化整理，屬分析框架，<strong>非投票建議、非情報預測</strong>。",
                "詳細對照已寫入本倉 <code>工作日誌.md</code>（接續 0916）。",
            ],
        ),
    ],
    "app": "https://copyshae.github.io/-/directory/",
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
    ("0916", "./20260916-learning-log.html"),
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
        日誌首頁：<a class="inline" href="{log["app"]}">{log["app"]}</a>
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


def patch_0915() -> None:
    for base in (DOCS_609, EXPORT_609):
        path = base / "20260915-learning-log.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        # remove any 1128 links, ensure 0916
        t = t.replace(
            '<a class="inline" href="../202611/20261128-learning-log.html">1128</a>',
            '<a class="inline" href="./20260916-learning-log.html">0916</a>',
        )
        t = t.replace(
            '｜下一則：<a class="inline" href="../202611/20261128-learning-log.html">1128 二林選情與核電／戰時核安</a>',
            '｜下一則：<a class="inline" href="./20260916-learning-log.html">0916 二林選情與核電／戰時核安</a>',
        )
        if 'href="./20260916-learning-log.html">0916</a>' not in t:
            t = t.replace(
                '<a class="inline" href="./20260915-learning-log.html">0915</a>\n'
                "        ｜<a class=\"inline\" href=\"../index.html\">學習日誌首頁</a>",
                '<a class="inline" href="./20260915-learning-log.html">0915</a> →\n'
                '        <a class="inline" href="./20260916-learning-log.html">0916</a>\n'
                "        ｜<a class=\"inline\" href=\"../index.html\">學習日誌首頁</a>",
            )
        if '下一則：<a class="inline" href="./20260916-learning-log.html">' not in t:
            t = t.replace(
                "｜上一則：<a class=\"inline\" href=\"./20260914-learning-log.html\">0914 新聞主播頭條修復</a>\n"
                "        ｜App：",
                "｜上一則：<a class=\"inline\" href=\"./20260914-learning-log.html\">0914 新聞主播頭條修復</a>\n"
                "        ｜下一則：<a class=\"inline\" href=\"./20260916-learning-log.html\">0916 二林選情與核電／戰時核安</a>\n"
                "        ｜App：",
            )
            # blank line variant
            t = t.replace(
                "｜上一則：<a class=\"inline\" href=\"./20260914-learning-log.html\">0914 新聞主播頭條修復</a>\n"
                "        \n"
                "        ｜App：",
                "｜上一則：<a class=\"inline\" href=\"./20260914-learning-log.html\">0914 新聞主播頭條修復</a>\n"
                "        ｜下一則：<a class=\"inline\" href=\"./20260916-learning-log.html\">0916 二林選情與核電／戰時核安</a>\n"
                "        ｜App：",
            )
        path.write_text(t, encoding="utf-8")
        print("patched", path)


def write_month_index() -> None:
    for base in (DOCS_609, EXPORT_609):
        path = base / "index.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        t = t.replace(
            "連續一天一主題至 <strong>0915</strong>（最新）",
            "連續一天一主題至 <strong>0916</strong>（最新）",
        )
        t = t.replace(
            "連續一天一主題至 <strong>0914</strong>（最新）",
            "連續一天一主題至 <strong>0916</strong>（最新）",
        )
        item = """      <li>
        <a href="20260916-learning-log.html">
          20260916 公開資料分析：二林選情、核電利弊與戰時核安
          <span>鎮長／議員評分｜核電 vs 非核｜攻擊核電廠風險</span>
        </a>
      </li>
"""
        if "20260916-learning-log.html" not in t:
            t = t.replace(
                '    <ul class="dir-list">\n      <li>\n        <a href="20260915-learning-log.html">',
                f'    <ul class="dir-list">\n{item}      <li>\n        <a href="20260915-learning-log.html">',
            )
        path.write_text(t, encoding="utf-8")
        print("index", path)


def patch_directory_index() -> None:
    for base in (DOCS_DIR, EXPORT_DIR):
        path = base / "index.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        # remove 202611 entry if added
        t = t.replace(
            '      <li>\n        <a href="202611/">202611（1128｜最新）</a>\n      </li>\n',
            "",
        )
        t = t.replace(
            "202609（0901–0915 連續主題｜最新 0915）",
            "202609（0901–0916 連續主題｜最新 0916）",
        )
        t = t.replace(
            "202609（0901–0914 連續主題｜最新 0914）",
            "202609（0901–0916 連續主題｜最新 0916）",
        )
        path.write_text(t, encoding="utf-8")
        print("dir index", path)


def patch_learning_log_redirect() -> None:
    for base in (DOCS_DIR, EXPORT_DIR):
        path = base / "learning-log.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        t = t.replace(
            "./202611/20261128-learning-log.html",
            "./202609/20260916-learning-log.html",
        )
        t = t.replace(
            "./202608/20260829-learning-log.html",
            "./202609/20260916-learning-log.html",
        )
        path.write_text(t, encoding="utf-8")
        print("redirect", path)


def remove_nov_artifacts() -> None:
    import shutil

    for d in (DOCS_611, EXPORT_611):
        if d.exists():
            shutil.rmtree(d)
            print("removed", d)
    old_script = ROOT / "scripts/gen-learning-logs-1128.py"
    if old_script.exists():
        old_script.unlink()
        print("removed", old_script)


def main() -> None:
    remove_nov_artifacts()
    write_log()
    patch_0915()
    write_month_index()
    patch_directory_index()
    patch_learning_log_redirect()
    print("done 0916")


if __name__ == "__main__":
    main()
