#!/usr/bin/env python3
"""從 Google News RSS 抓取新聞，並可解碼原文連結抓取內文，輸出 JSON 供 news-anchor PWA。

Google News RSS 的 description 通常只有相關報導連結，不含完整內文。
需 pip install googlenewsdecoder 才能抓取原文（--no-articles 可略過）。
"""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

try:
    from googlenewsdecoder import gnewsdecoder
except ImportError:  # pragma: no cover - 選用依賴
    gnewsdecoder = None  # type: ignore[misc, assignment]

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


def resolve_publisher_url(link: str, interval: float = 0.5) -> str | None:
    """將 news.google.com/rss/articles/... 解碼為媒體原文 URL。"""
    if not link or "news.google.com" not in link:
        return link or None
    if gnewsdecoder is None:
        return None
    try:
        result = gnewsdecoder(link, interval=interval)
        if result.get("status") and result.get("decoded_url"):
            return str(result["decoded_url"])
    except Exception as exc:  # noqa: BLE001
        print(f"  解碼失敗：{exc}", file=sys.stderr)
    return None


def fetch_page(url: str, timeout: int = 20) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode("utf-8", errors="replace")


def _meta_content(html_text: str, *patterns: str) -> str:
    for pattern in patterns:
        match = re.search(pattern, html_text, re.I | re.S)
        if match:
            text = normalize_space(html.unescape(match.group(1)))
            if len(text) > 20:
                return text
    return ""


def _json_ld_body(html_text: str) -> str:
    for block in re.finditer(r'<script[^>]+type=["\']application/ld\+json["\'][^>]*>(.*?)</script>', html_text, re.I | re.S):
        raw = block.group(1).strip()
        if not raw:
            continue
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            continue
        nodes = data if isinstance(data, list) else [data]
        for node in nodes:
            if not isinstance(node, dict):
                continue
            body = node.get("articleBody") or node.get("description")
            if isinstance(body, str) and len(body) > 40:
                return normalize_space(html.unescape(re.sub(r"<[^>]+>", " ", body)))
    return ""


def _paragraph_body(html_text: str) -> str:
    chunks: list[str] = []
    for block in re.finditer(r"<p[^>]*>(.*?)</p>", html_text, re.I | re.S):
        text = normalize_space(html.unescape(re.sub(r"<[^>]+>", " ", block.group(1))))
        if len(text) < 40:
            continue
        if re.search(r"(cookie|javascript|browser does not support|您的瀏覽器)", text, re.I):
            continue
        if re.fullmatch(r"[\d:/\s]+", text):
            continue
        chunks.append(text)
        if sum(len(c) for c in chunks) >= 1200:
            break
    return normalize_space(" ".join(chunks))


def extract_article_text(html_text: str) -> str:
    """從媒體原文 HTML 抽出可播報內文。"""
    for extractor in (
        lambda h: _json_ld_body(h),
        lambda h: _meta_content(
            h,
            r'<meta[^>]+property=["\']og:description["\'][^>]+content=["\']([^"\']*)["\']',
            r'<meta[^>]+content=["\']([^"\']*)["\'][^>]+property=["\']og:description["\']',
            r'<meta[^>]+name=["\']description["\'][^>]+content=["\']([^"\']*)["\']',
        ),
        lambda h: _paragraph_body(h),
    ):
        text = extractor(html_text)
        if len(text) >= 40:
            return text[:2000]
    return ""


def make_article_summary(text: str, max_len: int = 320) -> str:
    text = normalize_space(text)
    if not text:
        return ""
    parts = re.split(r"(?<=[。！？!?])", text)
    summary = ""
    for part in parts:
        part = part.strip()
        if not part:
            continue
        if len(summary) + len(part) > max_len and summary:
            break
        summary += part
        if len(summary) >= max_len * 0.65:
            break
    if not summary:
        summary = text[:max_len]
    return summary[:max_len]


def enrich_items_with_articles(
    items: list[dict],
    *,
    per_feed: int,
    interval: float,
) -> None:
    """就地填入 publisherUrl / articleText / articleSummary。"""
    if gnewsdecoder is None:
        print("  略過原文抓取（請 pip install googlenewsdecoder）", file=sys.stderr)
        return
    for idx, item in enumerate(items[:per_feed]):
        link = item.get("link") or ""
        title = item.get("title") or ""
        print(f"  原文 {idx + 1}/{min(len(items), per_feed)}：{title[:36]}…", file=sys.stderr)
        publisher = resolve_publisher_url(link, interval=interval)
        if not publisher:
            continue
        item["publisherUrl"] = publisher
        try:
            page = fetch_page(publisher)
            body = extract_article_text(page)
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            print(f"    抓取失敗：{exc}", file=sys.stderr)
            continue
        if body:
            item["articleText"] = body
            item["articleSummary"] = make_article_summary(body)
            print(f"    ✓ {len(body)} 字", file=sys.stderr)
        time.sleep(interval)


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


def build_cache(
    categories: list[str] | None,
    per_feed: int,
    keywords: list[str] | None = None,
    *,
    fetch_articles: bool = True,
    article_limit: int = 5,
    decode_interval: float = 0.6,
) -> dict:
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
            if fetch_articles and items:
                enrich_items_with_articles(items, per_feed=article_limit, interval=decode_interval)
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
            if fetch_articles and items:
                enrich_items_with_articles(items, per_feed=article_limit, interval=decode_interval)
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
    parser.add_argument(
        "--no-articles",
        action="store_true",
        help="不抓取媒體原文內文（僅 RSS 標題與相關連結）",
    )
    parser.add_argument(
        "--article-limit",
        type=int,
        default=5,
        help="每個分類最多抓取幾則原文內文（預設 5）",
    )
    parser.add_argument(
        "--decode-interval",
        type=float,
        default=0.6,
        help="解碼／抓取原文間隔秒數（預設 0.6）",
    )
    args = parser.parse_args()
    cache = build_cache(
        args.categories,
        max(1, min(args.limit, 30)),
        args.keywords,
        fetch_articles=not args.no_articles,
        article_limit=max(1, min(args.article_limit, 15)),
        decode_interval=max(0.2, args.decode_interval),
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"已寫入 {args.output}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
