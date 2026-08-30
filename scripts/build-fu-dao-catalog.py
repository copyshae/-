#!/usr/bin/env python3
"""從 Firstory RSS 產生「福到你家」節目 catalog.json。"""
import json
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

RSS_URL = "https://open.firstory.me/rss/user/ckkqh9wqi6tum0805k7lkq87f"
OUT_PATH = "docs/fu-dao-ni-jia/catalog.json"


def parse_rfc2822(s):
    if not s:
        return ""
    try:
        from email.utils import parsedate_to_datetime
        return parsedate_to_datetime(s).astimezone(timezone.utc).strftime("%Y-%m-%d")
    except Exception:
        return s[:10] if len(s) >= 10 else s


def clean_title(t):
    t = re.sub(r"\s+", " ", (t or "").strip())
    return t


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else OUT_PATH
    data = urllib.request.urlopen(RSS_URL, timeout=60).read()
    root = ET.fromstring(data)
    channel = root.find("channel")
    episodes = []
    for item in channel.findall("item"):
        guid = (item.findtext("guid") or "").strip()
        title = clean_title(item.findtext("title"))
        enc = item.find("enclosure")
        audio = enc.get("url") if enc is not None else ""
        if not guid or not audio:
            continue
        pub = parse_rfc2822(item.findtext("pubDate"))
        dur = item.find("{http://www.itunes.com/dtds/podcast-1.0.dtd}duration")
        duration = (dur.text or "").strip() if dur is not None else ""
        episodes.append({
            "id": guid,
            "title": title,
            "date": pub,
            "audioUrl": audio,
            "duration": duration,
        })
    catalog = {
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "source": RSS_URL,
        "program": "福到你家",
        "station": "正聲廣播電台 FM104.1",
        "host": "黃子榕",
        "guest": "太陽盛德導師",
        "count": len(episodes),
        "episodes": episodes,
    }
    with open(out, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(episodes)} episodes → {out}")


if __name__ == "__main__":
    main()
