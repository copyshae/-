#!/usr/bin/env python3
"""搜尋太陽盛德導師 YouTube 歌曲，產生 catalog.json（分類：導師親唱／其他演唱者）。"""
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
    {
        "id": "hTEv2f-9WIM",
        "name": "注入彩虹",
        "repeat": 3,
        "title": "〈注入彩虹〉太陽盛德導師演唱版",
        "performer": "master",
        "performerLabel": "太陽盛德導師",
    },
    {
        "id": "tkYxdmQlhtQ",
        "name": "富有",
        "repeat": 3,
        "title": "〈富有〉太陽盛德導師演唱版",
        "performer": "master",
        "performerLabel": "太陽盛德導師",
    },
]

QUERIES = [
    "太陽盛德導師 演唱版",
    "太陽盛德 導師 詞曲 MV",
    "太阳盛德导师 官方 MV",
    "太陽盛德導師創作",
    "太阳盛德导师创作 正能量歌曲",
    "太陽盛德導師 詞曲 演唱",
]

SKIP = [
    "共修", "精華", "解析", "專訪", "专访", "訪談", "访谈", "案例", "呼吸法", "改運", "財富的關鍵",
    "身體病痛", "祖德", "能量是如何", "什麼是德", "負評", "爭議", "評價", "Las Vegas",
    "生活百分百", "民視新聞", "音乐书", "音樂書", "小貝",
]

MASTER_NAMES = frozenset({"太陽盛德導師", "太阳盛德导师", "太陽盛德", "太阳盛德"})


def yt_search(query: str, limit: int = 35) -> list[dict]:
    cmd = ["yt-dlp", "--flat-playlist", "--dump-json", f"ytsearch{limit}:{query}"]
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


def clean_singer(name: str) -> str:
    name = re.sub(r"\s+", "", name.strip())
    for bad in ("演唱", "演奏", "創作", "官方", "MV"):
        name = name.replace(bad, "")
    return name[:12] if name else "其他演唱者"


def classify_performer(title: str) -> tuple[str, str]:
    """回傳 (performer, performerLabel)；performer 為 master 或 other。"""
    # 他人演唱・導師原創
    m = re.search(r"([^\s〈《]+)演唱[・·](?=.*太陽盛德|.*太阳盛德)", title)
    if m:
        singer = clean_singer(m.group(1))
        if singer not in MASTER_NAMES and "盛德" not in singer:
            return "other", singer

    m = re.search(r"([^\s〈《]+)演唱版", title)
    if m:
        singer = clean_singer(m.group(1))
        if singer not in MASTER_NAMES and "盛德" not in singer and "導師" not in singer:
            return "other", singer

    for pat in (
        r"演唱者[：:]\s*([^\s#]+)",
        r"演奏者[：:]\s*([^\s#]+)",
        r"Sung by\s+([^(\n|]+)",
    ):
        m = re.search(pat, title, re.I)
        if m:
            return "other", clean_singer(m.group(1))

    # 季泽 《出发》
    m = re.match(r"^([^\s《〈#]+)\s*[《〈]", title)
    if m:
        singer = clean_singer(m.group(1))
        if singer not in MASTER_NAMES and "盛德" not in singer:
            return "other", singer

    m = re.search(r"💫[^💫]*💫([^🎤☀️#]+)🎤", title)
    if m:
        return "other", clean_singer(m.group(1))

    m = re.search(r"🎶[^🎶]*🎶🕺([^🕺🎤#]+)🕺", title)
    if m:
        return "other", clean_singer(m.group(1))

    master_markers = (
        "太陽盛德導師演唱",
        "太阳盛德导师演唱",
        "導師演唱版",
        "导师演唱版",
        "導師演唱・",
        "導師演唱·",
    )
    if any(x in title for x in master_markers):
        return "master", "太陽盛德導師"

    if "太陽盛德導師作品" in title or "太陽盛德導師《" in title:
        return "master", "太陽盛德導師"

    if ("太陽盛德導師" in title or "太阳盛德导师" in title) and any(
        x in title for x in ("創作", "词曲", "詞曲", "原創")
    ):
        if "演唱" not in title or "導師演唱" in title or "导师演唱" in title:
            if "導師原創" in title and "演唱・" in title:
                pass  # 已在上方處理
            elif "導師演唱" in title or "导师演唱" in title:
                return "master", "太陽盛德導師"

    if "#太阳盛德导师创作" in title or "#太陽盛德導師創作" in title:
        return "other", "其他演唱者"

    if "太陽盛德導師" in title or "太阳盛德导师" in title:
        return "master", "太陽盛德導師"

    return "other", "其他演唱者"


def score(title: str, performer: str) -> int:
    s = 0
    if performer == "master":
        s += 40
    if "太陽盛德導師演唱" in title or "太阳盛德导师演唱" in title:
        s += 50
    if "Official" in title or "官方" in title:
        s += 15
    if "和音版" in title:
        s -= 5
    if "伴奏" in title or "演奏版" in title:
        s -= 50
    return s


def should_skip(title: str, name: str) -> bool:
    if any(w in title for w in SKIP):
        return True
    if not any(k in title for k in ("太陽盛德", "太阳盛德", "盛德")):
        return True
    if not any(m in title for m in ("演唱", "MV", "版", "詞曲", "歌曲", "創作", "〈", "《", "词曲")):
        return True
    if len(name) < 2 or "三立" in name or "台灣台" in name:
        return True
    return False


def song_entry(vid: str, title: str, repeat: int = 1) -> dict:
    name = clean_name(song_name(title))
    performer, label = classify_performer(title)
    return {
        "id": vid,
        "name": name,
        "repeat": repeat,
        "title": title,
        "performer": performer,
        "performerLabel": label,
    }


def build_catalog() -> dict:
    seen_ids: set[str] = {p["id"] for p in PRIORITY}
    # key: (name, performer, performerLabel) for dedup
    pool: dict[tuple[str, str, str], dict] = {}

    for q in QUERIES:
        for d in yt_search(q):
            vid = d.get("id")
            title = d.get("title") or ""
            if not vid or vid in seen_ids:
                continue
            entry = song_entry(vid, title, 1)
            if should_skip(title, entry["name"]):
                continue
            # 跳過與優先曲同名的非導師版（仍可在 other 搜尋中收錄）
            if entry["name"] in ("注入彩虹", "富有") and entry["performer"] == "master":
                continue
            seen_ids.add(vid)
            key = (entry["name"], entry["performer"], entry["performerLabel"])
            prev = pool.get(key)
            if not prev or score(title, entry["performer"]) > score(prev["title"], prev["performer"]):
                pool[key] = entry

    masters = sorted(
        [s for s in pool.values() if s["performer"] == "master"],
        key=lambda x: x["name"],
    )
    others = sorted(
        [s for s in pool.values() if s["performer"] == "other"],
        key=lambda x: (x["name"], x["performerLabel"]),
    )
    songs = PRIORITY + masters + others
    mc = sum(1 for s in songs if s["performer"] == "master")
    oc = sum(1 for s in songs if s["performer"] == "other")
    return {
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "artist": "太陽盛德導師",
        "songs": songs,
        "counts": {"master": mc, "other": oc, "total": len(songs)},
        "queueNote": "注入彩虹、富有各×3 → 導師親唱各×1 → 其他演唱者各×1",
    }


def main() -> int:
    if subprocess.run(["which", "yt-dlp"], capture_output=True).returncode != 0:
        print("yt-dlp not found", file=sys.stderr)
        return 1
    catalog = build_catalog()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    c = catalog["counts"]
    print(f"Wrote {c['total']} songs (master {c['master']}, other {c['other']}) -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
