#!/usr/bin/env python3
"""Generate 0918: projected winners vs incumbents contribution scores."""
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
    ul { margin: 0.5rem 0 0.85rem 1.35rem; }
    li { margin: 0.3rem 0; }
    table { width: 100%; border-collapse: collapse; margin: 0.75rem 0 1rem; font-size: 0.9rem; }
    th, td { border: 1px solid var(--line); padding: 0.4rem 0.5rem; text-align: left; vertical-align: top; }
    th { background: rgba(45,106,79,0.1); font-weight: 600; }
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

CHAIN = [
    ("0830", "../202608/20260830-learning-log.html"),
    ("0831", "../202608/20260831-learning-log.html"),
] + [(f"090{i}" if i < 10 else f"09{i}", f"./2026090{i}-learning-log.html" if i < 10 else f"./202609{i}-learning-log.html") for i in range(1, 19)]


def chain_html(upto: str) -> str:
    parts = []
    for num, href in CHAIN:
        # fix 0901-0909 paths already correct; 0910+ need 20260910 form
        if num.startswith("09") and len(num) == 4:
            n = int(num[2:])
            href = f"./202609{n:02d}-learning-log.html" if n >= 10 else f"./2026090{n}-learning-log.html"
            if n <= 3 and False:
                pass
        if num in ("0830", "0831"):
            pass
        elif num.startswith("09"):
            n = int(num[2:])
            href = f"./202609{n:02d}-learning-log.html"
        parts.append(f'<a class="inline" href="{href}">{num}</a>')
        if num == upto:
            break
    return " →\n        ".join(parts)


def render() -> str:
    date, num = "20260918", "0918"
    url = f"https://copyshae.github.io/-/directory/202609/{date}-learning-log.html"
    app = "https://copyshae.github.io/-/directory/"
    return f"""<!DOCTYPE html>
<html lang="zh-Hant">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{date} 學習日誌・可能當選人 vs 現任貢獻進退</title>
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
    </nav>
    <article>
      <h1>{date} 開票領先＝可能當選：vs 現任的台灣貢獻分數</h1>
      <p class="lead">接 <a class="inline" href="./20260917-learning-log.html">0917 全台縣市長五項前五</a>。依晚間公開開票（領先／自行宣布）把 22 縣市可能當選人當「準當選」，對照現任的「對台灣貢獻」分數，看進步或退步（非正式公告）。</p>
      <div class="callout"><strong>手機立刻可開：</strong><br />
        本篇：<a class="inline" href="{url}">{url}</a><br />
        日誌首頁：<a class="inline" href="{app}">{app}</a>
      </div>

      <h2>一｜總判斷</h2>
      <ul>
        <li>22 縣市平均約 <strong>75→76</strong>（微進）；六都約 <strong>77→81</strong>（較明顯往好）。</li>
        <li><strong>偏更好</strong>：北桃科技廊帶延續、台中自低谷翻轉、宜蘭結束代理動盪。</li>
        <li><strong>明顯退步風險</strong>：高雄／嘉義縣／台東／嘉義市等高標交棒。</li>
        <li>雲林、花蓮超微差，結果仍可能翻盤。</li>
      </ul>

      <h2>二｜六都對照（現任分 → 當選分）</h2>
      <table>
        <thead><tr><th>縣市</th><th>現任→可能當選</th><th>現任</th><th>當選</th><th>進退</th></tr></thead>
        <tbody>
          <tr><td>台北</td><td>蔣萬安→蔣萬安</td><td>78</td><td>81</td><td>+3</td></tr>
          <tr><td>新北</td><td>侯友宜→李四川</td><td>82</td><td>84</td><td>+2</td></tr>
          <tr><td>桃園</td><td>張善政→張善政</td><td>82</td><td>86</td><td>+4</td></tr>
          <tr><td>台中</td><td>盧秀燕→何欣純</td><td>61</td><td>77</td><td>+16</td></tr>
          <tr><td>台南</td><td>黃偉哲→陳亭妃</td><td>72</td><td>78</td><td>+6</td></tr>
          <tr><td>高雄</td><td>陳其邁→賴瑞隆</td><td>88</td><td>79</td><td>-9</td></tr>
        </tbody>
      </table>

      <h2>三｜注意</h2>
      <ul>
        <li>自行宣布／領先 ≠ 中選會公告；分數非民調、非投票建議。</li>
        <li>完整 22 縣市見 Cursor canvas「22縣市可能當選人 vs 現任」；工作日誌接續 0918。</li>
      </ul>

      <div class="chain">
        <strong>日期連續</strong>：
        {chain_html(num)}
        ｜<a class="inline" href="../index.html">學習日誌首頁</a>
      </div>
      <p class="note">
        本篇：<a class="inline" href="{url}">{url}</a>
        ｜上一則：<a class="inline" href="./20260917-learning-log.html">0917 全台縣市長五項前五</a>
        ｜<a class="inline" href="../index.html">學習日誌首頁</a>
      </p>
    </article>
  </div>
</body>
</html>
"""


def patch_prev() -> None:
    for base in (DOCS_609, EXPORT_609):
        path = base / "20260917-learning-log.html"
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        if 'href="./20260918-learning-log.html">0918</a>' not in t:
            t = t.replace(
                '<a class="inline" href="./20260917-learning-log.html">0917</a>\n'
                "        ｜<a class=\"inline\" href=\"../index.html\">學習日誌首頁</a>",
                '<a class="inline" href="./20260917-learning-log.html">0917</a> →\n'
                '        <a class="inline" href="./20260918-learning-log.html">0918</a>\n'
                "        ｜<a class=\"inline\" href=\"../index.html\">學習日誌首頁</a>",
            )
        if "20260918-learning-log.html\">0918" not in t or "下一則" not in t:
            t = t.replace(
                "｜上一則：<a class=\"inline\" href=\"./20260916-learning-log.html\">0916 二林選情與核電／戰時核安</a>\n"
                "        ｜<a class=\"inline\" href=\"../index.html\">學習日誌首頁</a>",
                "｜上一則：<a class=\"inline\" href=\"./20260916-learning-log.html\">0916 二林選情與核電／戰時核安</a>\n"
                "        ｜下一則：<a class=\"inline\" href=\"./20260918-learning-log.html\">0918 當選人 vs 現任貢獻</a>\n"
                "        ｜<a class=\"inline\" href=\"../index.html\">學習日誌首頁</a>",
            )
        path.write_text(t, encoding="utf-8")
        print("patched", path)


def write_indexes() -> None:
    for base in (DOCS_609, EXPORT_609):
        path = base / "index.html"
        t = path.read_text(encoding="utf-8")
        t = t.replace("至 <strong>0917</strong>（最新）", "至 <strong>0918</strong>（最新）")
        item = """      <li>
        <a href="20260918-learning-log.html">
          20260918 開票領先＝可能當選：vs 現任的台灣貢獻分數
          <span>22縣市｜六都 77→81｜總判斷微進</span>
        </a>
      </li>
"""
        if "20260918-learning-log.html" not in t:
            t = t.replace(
                '    <ul class="dir-list">\n      <li>\n        <a href="20260917-learning-log.html">',
                f'    <ul class="dir-list">\n{item}      <li>\n        <a href="20260917-learning-log.html">',
            )
        path.write_text(t, encoding="utf-8")
    for base in (DOCS_DIR, EXPORT_DIR):
        path = base / "index.html"
        t = path.read_text(encoding="utf-8")
        t = t.replace(
            "202609（0901–0917 連續主題｜最新 0917）",
            "202609（0901–0918 連續主題｜最新 0918）",
        )
        path.write_text(t, encoding="utf-8")
        path = base / "learning-log.html"
        t = path.read_text(encoding="utf-8")
        t = t.replace("./202609/20260917-learning-log.html", "./202609/20260918-learning-log.html")
        t = t.replace(
            "今天 0917（全台縣市長 · 五項優質度前五）",
            "今天 0918（可能當選人 vs 現任 · 貢獻進退）",
        )
        path.write_text(t, encoding="utf-8")
    print("indexes ok")


def main() -> None:
    html = render()
    for base in (DOCS_609, EXPORT_609):
        base.mkdir(parents=True, exist_ok=True)
        (base / "20260918-learning-log.html").write_text(html, encoding="utf-8")
        print("wrote", base / "20260918-learning-log.html")
    patch_prev()
    write_indexes()
    print("done 0918")


if __name__ == "__main__":
    main()
