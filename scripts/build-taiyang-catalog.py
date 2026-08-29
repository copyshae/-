#!/usr/bin/env python3
"""搜尋太陽盛德導師 YouTube 歌曲，產生 catalog.json。"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "taiyang-music" / "catalog.json"

PRIORITY = [
    {"id": "hTEv2f-9WIM", "name": "注入彩虹", "repeat": 3, "title": "〈注入彩虹〉太陽盛德導師演唱版"},
    {"id": "tkYxdmQlhtQ", "name": "富有", "repeat": 3, "title": "〈富有〉太陽盛德導師演唱版"},
]

QUERIES = [
    "太陽盛德導師 演唱版",
    "太陽盛德 導師 詞曲 MV",
    "太阳盛德导师 官方 MV",
    "太陽盛德導師創作 歌曲",
]

SKIP = [
    "共修", "精華", "解析", "專訪", "訪談", "案例", "呼吸法", "改運", "財富的關鍵",
    "身體病痛", "祖德", "能量是如何", "什麼是德", "負評", "爭議", "評價", "Las Vegas",
    "生活百分百", "民視新聞", "音乐书", "音樂書", "小貝", "注入彩虹", "富 有", "富有",
]


def yt_search(query: str, limit: int = 35) -> list[dict]:
    cmd = [
        "yt-dlp", "--flat-playlist", "--dump-json",
        f"ytsearch{limit}:{query}",
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    items = []
    for line in r.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            items.append(json.loads(line))
        except json.JSONDecodeError:
            pass
    return items


def song_name(title: str) -> str:
    matches = re.findall(r"[〈《]([^〉》]+)[〉》]", title)
    if matches:
        return clean_name(matches[-1])
    m = re.search(r"【([^】]+)】", title)
    if m:
        return clean_name(m.group(1))
    m = re.search(r"歌曲名[:：]\s*([^\s#]+)", title)
    if m:
        return clean_name(m.group(1))
    m = re.search(r"✨([^✨☀️🎶]+)✨", title)
    if m:
        return clean_name(m.group(1))
    t = re.sub(r"#[^\s]+", "", title)
    t = re.sub(r"[\U00010000-\U0010ffff]", "", t)
    t = re.sub(r"[☀️✨🎶💫⭐🕺🎤🎵🌈🌺]", "", t).strip()
    return clean_name(t[:24] if t else "未知曲目")


def clean_name(name: str) -> str:
    name = re.sub(r"\s+", "", name)
    name = name.strip("〈《【】》〉")
    for prefix in ("數位心靈淨化", "太陽盛德導師", "太阳盛德导师"):
        name = name.replace(prefix, "")
    name = name.split("-")[0].split("|")[0].strip()
    return name[:20] if len(name) >= 2 else ""


def score(title: str) -> int:
    s = 0
    if "太陽盛德導師演唱" in title or "太阳盛德导师演唱" in title:
        s += 50
    if "導師演唱" in title or "导师演唱" in title:
        s += 30
    if "Official" in title or "官方" in title:
        s += 20
    if "和音版" in title:
        s -= 5
    if "伴奏" in title or "演奏" in title:
        s -= 40
    if "佳潔" in title or "若陽" in title or "季澤" in title:
        s -= 10
    return s


def should_skip(title: str, name: str) -> bool:
    if any(w in title for w in SKIP):
        return True
    if name in ("注入彩虹", "富有"):
        return True
    if not any(k in title for k in ("太陽盛德", "太阳盛德", "盛德")):
        return True
    if not any(m in title for m in ("演唱", "MV", "版", "詞曲", "歌曲", "創作", "〈", "《")):
        return True
    return False


def build_catalog() -> dict:
    seen_ids: set[str] = {p["id"] for p in PRIORITY}
    by_name: dict[str, dict] = {}

    for q in QUERIES:
        for d in yt_search(q):
            vid = d.get("id")
            title = d.get("title") or ""
            if not vid or vid in seen_ids:
                continue
            name = clean_name(song_name(title))
            if should_skip(title, name):
                continue
            if len(name) < 2 or "三立" in name or "台灣台" in name or "OfficialMusic" in name:
                continue
            seen_ids.add(vid)
            cand = {"id": vid, "name": name, "repeat": 1, "title": title}
            prev = by_name.get(name)
            if not prev or score(title) > score(prev["title"]):
                by_name[name] = cand

    others = sorted(by_name.values(), key=lambda x: x["name"])
    songs = PRIORITY + others
    return {
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "artist": "太陽盛德導師",
        "songs": songs,
        "queueNote": "注入彩虹、富有各連播 3 次；其餘著作歌曲各 1 次",
    }


def main() -> int:
    if not subprocess.run(["which", "yt-dlp"], capture_output=True).returncode == 0:
        print("yt-dlp not found", file=sys.stderr)
        return 1
    catalog = build_catalog()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(catalog['songs'])} songs -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
