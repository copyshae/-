#!/usr/bin/env python3
"""彙整太陽盛德導師親身口述影音：福到你家、導師親唱、YouTube 演講／訪談。"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "taiyang-lib" / "catalog.json"
MUSIC_CAT = ROOT / "docs" / "taiyang-music" / "catalog.json"
RSS_URL = "https://open.firstory.me/rss/user/ckkqh9wqi6tum0805k7lkq87f"

YT_QUERIES = [
    "太陽盛德導師 演講",
    "太陽盛德導師 訪談",
    "太陽盛德導師 共修精華",
    "太陽盛德導師 太陽心語",
    "太陽盛德導師 開示",
    "太阳盛德导师 口述",
    "太陽盛德導師 超級生命密碼 解答",
]

SKIP_TITLE = [
    "伴奏", "演奏版", "Instrumental", "蔡禮旭", "蔡礼旭", "弟子規41", "弟子规41",
    "小貝", "小貝", "翻唱", "cover", "KTV",
]

MASTER_MARKERS = ("太陽盛德", "太阳盛德", "盛德導師", "盛德导师")


def yt_search(query: str, limit: int = 25) -> list[dict]:
    cmd = ["yt-dlp", "--flat-playlist", "--dump-json", f"ytsearch{limit}:{query}"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    out = []
    for line in r.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            out.append(json.loads(line))
        except json.JSONDecodeError:
            pass
    return out


def parse_rfc2822(s: str) -> str:
    if not s:
        return ""
    try:
        from email.utils import parsedate_to_datetime
        return parsedate_to_datetime(s).strftime("%Y-%m-%d")
    except Exception:
        return s[:10] if len(s) >= 10 else ""


def load_fu_dao() -> list[dict]:
    items = []
    data = urllib.request.urlopen(RSS_URL, timeout=60).read()
    root = ET.fromstring(data)
    for item in root.find("channel").findall("item"):
        guid = (item.findtext("guid") or "").strip()
        title = re.sub(r"\s+", " ", (item.findtext("title") or "").strip())
        enc = item.find("enclosure")
        audio = enc.get("url") if enc is not None else ""
        if not guid or not audio:
            continue
        dur = item.find("{http://www.itunes.com/dtds/podcast-1.0.dtd}duration")
        items.append({
            "id": "fd-" + guid,
            "title": title,
            "date": parse_rfc2822(item.findtext("pubDate") or ""),
            "type": "audio",
            "playUrl": audio,
            "openUrl": f"https://copyshae.github.io/-/fu-dao-ni-jia/simple/?ep={guid}",
            "localApp": "fu-dao-ni-jia",
            "localId": guid,
            "duration": (dur.text or "").strip() if dur is not None else "",
        })
    return items


def load_master_songs() -> list[dict]:
    if not MUSIC_CAT.exists():
        return []
    cat = json.loads(MUSIC_CAT.read_text(encoding="utf-8"))
    items = []
    for s in cat.get("songs", []):
        if s.get("performer") != "master":
            continue
        vid = s.get("id")
        if not vid:
            continue
        items.append({
            "id": "song-" + vid,
            "title": s.get("title") or s.get("name") or "歌曲",
            "date": "",
            "type": "video",
            "playUrl": f"https://www.youtube.com/watch?v={vid}",
            "openUrl": f"https://copyshae.github.io/-/taiyang-music/simple/?song={vid}",
            "localApp": "taiyang-music",
            "localId": vid,
            "duration": "",
        })
    return items


def is_master_oral(title: str) -> bool:
    if not any(m in title for m in MASTER_MARKERS):
        return False
    if any(w in title for w in SKIP_TITLE):
        return False
    # 排除純歌曲 MV 已由 songs 收錄
    if any(x in title for x in ("Official Music Video", "演唱版", "詞曲", "創作新歌", "〈", "《")):
        if any(x in title for x in ("演講", "訪談", "專訪", "共修", "精華", "開示", "心語", "解答", "巡迴")):
            return True
        if "MV" in title or "Music Video" in title or "演唱" in title:
            return False
    return True


def load_youtube_oral() -> list[dict]:
    seen: set[str] = set()
    items = []
    for q in YT_QUERIES:
        for d in yt_search(q, limit=30):
            vid = d.get("id")
            title = d.get("title") or ""
            if not vid or vid in seen or not is_master_oral(title):
                continue
            seen.add(vid)
            items.append({
                "id": "yt-" + vid,
                "title": title,
                "date": (d.get("upload_date") or "")[:4] + "-" + (d.get("upload_date") or "")[4:6] + "-" + (d.get("upload_date") or "")[6:8]
                if d.get("upload_date") and len(d.get("upload_date", "")) == 8 else "",
                "type": "video",
                "playUrl": f"https://www.youtube.com/watch?v={vid}",
                "openUrl": f"https://www.youtube.com/watch?v={vid}",
                "localApp": None,
                "localId": vid,
                "duration": str(d.get("duration") or ""),
            })
    return items


def build() -> dict:
    broadcast = load_fu_dao()
    songs = load_master_songs()
    lectures = load_youtube_oral()

    categories = [
        {
            "id": "broadcast",
            "name": "廣播訪談｜福到你家",
            "desc": "正聲廣播 FM104.1，子榕專訪，導師親口解答（音檔）",
            "items": broadcast,
        },
        {
            "id": "lecture",
            "name": "演講・共修・訪談",
            "desc": "導師親述：演講、媒體專訪、共修精華（YouTube）",
            "items": sorted(lectures, key=lambda x: x.get("date") or "", reverse=True),
        },
        {
            "id": "music",
            "name": "導師親唱歌曲",
            "desc": "太陽盛德導師親唱創作歌曲（YouTube 影音）",
            "items": songs,
        },
    ]
    total = sum(len(c["items"]) for c in categories)
    return {
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "title": "太陽盛德導師｜親身口述影音圖書館",
        "subtitle": "廣播、演講、導師親唱 — 圖書館式分類",
        "count": total,
        "categories": categories,
    }


def main() -> int:
    if subprocess.run(["which", "yt-dlp"], capture_output=True).returncode != 0:
        print("yt-dlp not found; only RSS + music catalog", file=sys.stderr)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    cat = build()
    OUT.write_text(json.dumps(cat, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {cat['count']} items -> {OUT}")
    for c in cat["categories"]:
        print(f"  {c['name']}: {len(c['items'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
