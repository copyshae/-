#!/usr/bin/env python3
"""從 Google News RSS 抓取新聞，輸出 JSON 供 news-anchor PWA 使用。"""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

USER_AGENT = "Mozilla/5.0 (compatible; news-anchor/1.0; +https://github.com/copyshae/-)"
DEFAULT_OUTPUT = Path(__file__).resolve().parents[1] / "docs" / "news-anchor" / "news-cache.json"

FEEDS: dict[str, str] = {
    "headlines": "https://news.google.com/rss?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
    "world": "https://news.google.com/rss/headlines/section/topic/WORLD?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
    "nation": "https://news.google.com/rss/headlines/section/topic/NATION?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
    "business": "https://news.google.com/rss/headlines/section/topic/BUSINESS?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
    "technology": "https://news.google.com/rss/headlines/section/topic/TECHNOLOGY?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
    "entertainment": "https://news.google.com/rss/headlines/section/topic/ENTERTAINMENT?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
    "sports": "https://news.google.com/rss/headlines/section/topic/SPORTS?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
    "science": "https://news.google.com/rss/headlines/section/topic/SCIENCE?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
    "health": "https://news.google.com/rss/headlines/section/topic/HEALTH?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
}

CATEGORY_LABELS: dict[str, str] = {
    "headlines": "頭條",
    "world": "國際",
    "nation": "台灣",
    "business": "財經",
    "technology": "科技",
    "entertainment": "娛樂",
    "sports": "體育",
    "science": "科學",
    "health": "健康",
}


def fetch_rss(url: str, timeout: int = 25) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode("utf-8", errors="replace")


def clean_title(title: str) -> str:
    title = re.sub(r"\s*-\s*[^-]+$", "", title.strip())
    return title.strip()


def normalize_space(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip())


def titles_similar(a: str, b: str) -> bool:
    a, b = normalize_space(a), normalize_space(b)
    if not a or not b:
        return True
    if a == b:
        return True
    return a in b or b in a


def extract_related_titles(desc: str, main_title: str, limit: int = 4) -> list[str]:
    """從 Google News RSS 的 HTML description 抽出相關標題。"""
    if not desc:
        return []
    related: list[str] = []
    seen: set[str] = set()
    for match in re.finditer(r"<a[^>]*>([^<]+)</a>", desc, re.I):
        title = normalize_space(html.unescape(match.group(1)))
        if not title or title in seen or titles_similar(title, main_title):
            continue
        seen.add(title)
        related.append(title)
        if len(related) >= limit:
            break
    return related


def parse_rss(xml_text: str, limit: int = 12) -> list[dict]:
    root = ET.fromstring(xml_text)
    channel = root.find("channel")
    if channel is None:
        return []
    items: list[dict] = []
    for item in channel.findall("item"):
        title_el = item.find("title")
        link_el = item.find("link")
        pub_el = item.find("pubDate")
        desc_el = item.find("description")
        source_el = item.find("source")
        title = clean_title(title_el.text or "") if title_el is not None else ""
        if not title:
            continue
        source = ""
        if source_el is not None and source_el.text:
            source = source_el.text.strip()
        elif title_el is not None and title_el.text and " - " in title_el.text:
            source = title_el.text.rsplit(" - ", 1)[-1].strip()
        desc = (desc_el.text or "").strip() if desc_el is not None else ""
        items.append(
            {
                "title": title,
                "link": (link_el.text or "").strip() if link_el is not None else "",
                "pubDate": (pub_el.text or "").strip() if pub_el is not None else "",
                "description": desc,
                "relatedTitles": extract_related_titles(desc, title),
                "source": source,
            }
        )
        if len(items) >= limit:
            break
    return items


def build_search_url(keyword: str) -> str:
    q = urllib.parse.quote(keyword.strip())
    return f"https://news.google.com/rss/search?q={q}&hl=zh-TW&gl=TW&ceid=TW:zh-Hant"


def build_cache(categories: list[str] | None, per_feed: int, keywords: list[str] | None = None) -> dict:
    cats = categories or list(FEEDS.keys())
    payload: dict = {
        "updatedAt": datetime.now(timezone.utc).isoformat(),
        "feeds": {},
    }
    for key in cats:
        url = FEEDS.get(key)
        if not url:
            print(f"略過未知分類：{key}", file=sys.stderr)
            continue
        try:
            xml_text = fetch_rss(url)
            items = parse_rss(xml_text, limit=per_feed)
            payload["feeds"][key] = {
                "label": CATEGORY_LABELS.get(key, key),
                "url": url,
                "items": items,
            }
            print(f"✓ {CATEGORY_LABELS.get(key, key)}：{len(items)} 則", file=sys.stderr)
        except (urllib.error.URLError, ET.ParseError, TimeoutError) as exc:
            print(f"✗ {key} 抓取失敗：{exc}", file=sys.stderr)
            payload["feeds"][key] = {
                "label": CATEGORY_LABELS.get(key, key),
                "url": url,
                "items": [],
                "error": str(exc),
            }
    for kw in keywords or []:
        kw = kw.strip()
        if not kw:
            continue
        url = build_search_url(kw)
        feed_key = "search:" + kw
        try:
            xml_text = fetch_rss(url)
            items = parse_rss(xml_text, limit=per_feed)
            payload["feeds"][feed_key] = {
                "label": f"「{kw}」相關",
                "url": url,
                "keyword": kw,
                "items": items,
            }
            print(f"✓ 關鍵字「{kw}」：{len(items)} 則", file=sys.stderr)
        except (urllib.error.URLError, ET.ParseError, TimeoutError) as exc:
            print(f"✗ 關鍵字「{kw}」抓取失敗：{exc}", file=sys.stderr)
            payload["feeds"][feed_key] = {
                "label": f"「{kw}」相關",
                "url": url,
                "keyword": kw,
                "items": [],
                "error": str(exc),
            }
    return payload


def main() -> int:
    parser = argparse.ArgumentParser(description="抓取 Google News RSS 並輸出 JSON")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"輸出路徑（預設 {DEFAULT_OUTPUT}）",
    )
    parser.add_argument(
        "-c",
        "--category",
        action="append",
        dest="categories",
        choices=sorted(FEEDS.keys()),
        help="只抓指定分類，可重複指定；預設全部",
    )
    parser.add_argument(
        "-n",
        "--limit",
        type=int,
        default=10,
        help="每個分類最多幾則（預設 10）",
    )
    parser.add_argument(
        "-k",
        "--keyword",
        action="append",
        dest="keywords",
        help="搜尋關鍵字（Google 新聞 RSS），可重複指定",
    )
    args = parser.parse_args()
    cache = build_cache(
        args.categories,
        max(1, min(args.limit, 30)),
        args.keywords,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"已寫入 {args.output}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
