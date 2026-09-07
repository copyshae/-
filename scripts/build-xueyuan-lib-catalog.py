#!/usr/bin/env python3
"""彙整超級生命密碼學員分享影音。

兩層分類：
1. 解決什麼問題（轉念、親子、事業…）
2. 哪個國家／地區（台灣、馬來西亞、新加坡…）
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "xueyuan-lib" / "catalog.json"

# 確保 pip 安裝的 yt-dlp 可用
_local_bin = Path.home() / ".local" / "bin"
if _local_bin.exists():
    os.environ["PATH"] = str(_local_bin) + ":" + os.environ.get("PATH", "")

# —— 第二層：國家／地區 ——
COUNTRIES = [
    {
        "id": "tw",
        "name": "台灣",
        "markers": ["台灣", "臺灣", "台北", "臺北", "高雄", "台中", "臺中", "彰化", "台南", "桃園", "Taiwan", "TW"],
        "query_extra": "台灣",
    },
    {
        "id": "my",
        "name": "馬來西亞",
        "markers": ["馬來西亞", "马来西亚", "大馬", "吉隆坡", "檳城", "柔佛", "Malaysia", "MY"],
        "query_extra": "馬來西亞",
    },
    {
        "id": "sg",
        "name": "新加坡",
        "markers": ["新加坡", "Singapore", "SG"],
        "query_extra": "新加坡",
    },
    {
        "id": "cn",
        "name": "中國",
        "markers": ["中國", "大陆", "大陸", "北京", "上海", "深圳", "廣州", "广州", "China", "CN"],
        "query_extra": "中國",
    },
    {
        "id": "hk",
        "name": "香港",
        "markers": ["香港", "Hong Kong", "HK"],
        "query_extra": "香港",
    },
    {
        "id": "us",
        "name": "美國",
        "markers": ["美國", "美国", "加州", "紐約", "USA", "US", "America"],
        "query_extra": "美國",
    },
    {
        "id": "other",
        "name": "其他／未標",
        "markers": [],
        "query_extra": "",
    },
]

# —— 第一層：解決什麼問題 ——
PROBLEMS = [
    {
        "id": "zhuanian",
        "name": "轉念・境緣",
        "desc": "心念轉換、境緣無好醜、一念轉世界轉",
        "keywords": ["轉念", "境緣", "一念", "心念", "放下", "執著"],
        "base_queries": [
            "超級生命密碼 學員 轉念",
            "超級生命密碼 學員 境緣",
            "天圓文化 學員 轉念 分享",
        ],
    },
    {
        "id": "qinzi",
        "name": "親子・家庭",
        "desc": "親子教養、家庭關係、夫妻相處",
        "keywords": ["親子", "家庭", "孩子", "兒女", "夫妻", "教養", "父母"],
        "base_queries": [
            "超級生命密碼 學員 親子",
            "超級生命密碼 學員 家庭",
            "天圓文化 學員 親子 分享",
        ],
    },
    {
        "id": "shiye",
        "name": "事業・工作",
        "desc": "職場、事業抉擇、工作壓力與方向",
        "keywords": ["事業", "工作", "職場", "創業", "老闆", "同事"],
        "base_queries": [
            "超級生命密碼 學員 事業",
            "超級生命密碼 學員 工作",
            "天圓文化 學員 事業 分享",
        ],
    },
    {
        "id": "jiankang",
        "name": "健康・身心",
        "desc": "身心調適、壓力、睡眠與健康轉念",
        "keywords": ["健康", "身心", "身體", "壓力", "生病", "療癒", "睡眠"],
        "base_queries": [
            "超級生命密碼 學員 健康",
            "超級生命密碼 學員 身心",
            "天圓文化 學員 健康 分享",
        ],
    },
    {
        "id": "renji",
        "name": "人際・感情",
        "desc": "人際衝突、感情、溝通與和解",
        "keywords": ["人際", "感情", "溝通", "朋友", "關係", "和解", "衝突"],
        "base_queries": [
            "超級生命密碼 學員 人際",
            "超級生命密碼 學員 感情",
            "天圓文化 學員 人際 分享",
        ],
    },
    {
        "id": "fuzu",
        "name": "財務・富足",
        "desc": "金錢觀、債務、富足與豐盛",
        "keywords": ["財務", "富足", "金錢", "債務", "豐盛", "錢"],
        "base_queries": [
            "超級生命密碼 學員 富足",
            "超級生命密碼 學員 財務",
            "天圓文化 學員 富足 分享",
        ],
    },
    {
        "id": "xiuxing",
        "name": "修行・共修",
        "desc": "共修心得、實修見證、生命密碼應用",
        "keywords": ["共修", "修行", "實修", "生命密碼", "修煉", "見證", "心得"],
        "base_queries": [
            "超級生命密碼 學員 共修",
            "超級生命密碼 學員 分享 心得",
            "超級生命密碼 學員 見證",
            "太陽盛德 學員 分享",
        ],
    },
    {
        "id": "ganen",
        "name": "感恩・愛",
        "desc": "感恩實踐、愛與祝福、服務助人",
        "keywords": ["感恩", "愛", "祝福", "服務", "助人", "愛與感恩"],
        "base_queries": [
            "超級生命密碼 學員 感恩",
            "超級生命密碼 學員 愛與感恩",
            "天圓文化 學員 感恩 分享",
        ],
    },
]

STUDENT_MARKERS = (
    "學員", "学生", "分享", "心得", "見證", "共修",
    "超級生命密碼", "超碼", "天圓", "生命密碼",
)
SKIP_TITLE = (
    "伴奏", "演奏版", "Instrumental", "蔡禮旭", "蔡礼旭", "弟子規41", "弟子规41",
    "翻唱", "cover", "KTV", "Official Music Video",
)
MASTER_ONLY = ("太陽盛德導師親口", "導師親唱", "導師親述", "子榕專訪")


def yt_search(query: str, limit: int = 15) -> list[dict]:
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


def format_date(upload: str) -> str:
    if upload and len(upload) == 8 and upload.isdigit():
        return f"{upload[:4]}-{upload[4:6]}-{upload[6:8]}"
    return ""


def detect_country(title: str, channel: str = "") -> dict:
    blob = title + " " + (channel or "")
    for c in COUNTRIES:
        if c["id"] == "other":
            continue
        if any(m in blob for m in c["markers"]):
            return {"id": c["id"], "name": c["name"]}
    return {"id": "other", "name": "其他／未標"}


def is_student_share(title: str) -> bool:
    if any(w in title for w in SKIP_TITLE):
        return False
    if any(w in title for w in MASTER_ONLY):
        return False
    if ("太陽盛德導師" in title or "太阳盛德导师" in title) and not any(
        x in title for x in ("學員", "学生", "分享", "心得", "見證")
    ):
        if any(x in title for x in ("演講", "專訪", "訪談", "開示", "中天")):
            return False
    return any(m in title for m in STUDENT_MARKERS)


def match_problem(title: str, problem: dict) -> bool:
    return any(k in title for k in problem["keywords"])


def make_item(d: dict, problem: dict, country_hint: dict | None = None) -> dict:
    vid = d.get("id")
    title = d.get("title") or ""
    channel = d.get("channel") or d.get("uploader") or ""
    country = country_hint or detect_country(title, channel)
    tags = [k for k in problem["keywords"] if k in title] or problem["keywords"][:2]
    return {
        "id": "yt-" + vid,
        "title": title,
        "date": format_date(d.get("upload_date") or ""),
        "type": "video",
        "playUrl": f"https://www.youtube.com/watch?v={vid}",
        "openUrl": f"https://www.youtube.com/watch?v={vid}",
        "localApp": None,
        "localId": vid,
        "duration": str(d.get("duration") or ""),
        "problemId": problem["id"],
        "problemName": problem["name"],
        "problemTags": tags,
        "countryId": country["id"],
        "country": country["name"],
        "channel": channel,
    }


def load_problem_videos(problem: dict, global_seen: set[str]) -> list[dict]:
    items: list[dict] = []
    # 一般搜尋
    queries: list[tuple[str, dict | None]] = [(q, None) for q in problem["base_queries"]]
    # 再依主要國家加搜尋（台灣、馬來西亞、新加坡、中國）
    for c in COUNTRIES:
        if c["id"] in ("other", "us", "hk"):
            continue
        for bq in problem["base_queries"][:2]:
            queries.append((f"{bq} {c['query_extra']}", {"id": c["id"], "name": c["name"]}))

    for q, country_hint in queries:
        for d in yt_search(q, limit=12):
            vid = d.get("id")
            title = d.get("title") or ""
            if not vid or vid in global_seen:
                continue
            if not is_student_share(title):
                continue
            if not match_problem(title, problem) and problem["id"] != "xiuxing":
                if "學員" not in title and "学生" not in title:
                    continue
            # 若有國家 hint 搜尋，標題未標國家時沿用 hint
            detected = detect_country(title, d.get("channel") or d.get("uploader") or "")
            if country_hint and detected["id"] == "other":
                country = country_hint
            else:
                country = detected
            global_seen.add(vid)
            items.append(make_item(d, problem, country))

    items.sort(key=lambda x: (x.get("country") or "", x.get("date") or ""), reverse=False)
    # 同國家內再依日期新→舊
    items.sort(key=lambda x: x.get("date") or "", reverse=True)
    return items


def group_by_country(items: list[dict]) -> list[dict]:
    """問題分類下的國家分支（含連結用 id）。"""
    buckets: dict[str, list] = {c["id"]: [] for c in COUNTRIES}
    for it in items:
        cid = it.get("countryId") or "other"
        if cid not in buckets:
            cid = "other"
        buckets[cid].append(it)
    out = []
    for c in COUNTRIES:
        lst = buckets[c["id"]]
        if not lst and c["id"] == "other":
            continue
        if not lst:
            continue
        out.append({
            "id": c["id"],
            "name": c["name"],
            "count": len(lst),
            "items": lst,
        })
    # 若全空，至少放 other
    if not out and items:
        out.append({"id": "other", "name": "其他／未標", "count": len(items), "items": items})
    return out


def build() -> dict:
    global_seen: set[str] = set()
    categories = []
    for problem in PROBLEMS:
        print(f"搜尋：{problem['name']} …", flush=True)
        items = load_problem_videos(problem, global_seen)
        countries = group_by_country(items)
        categories.append({
            "id": problem["id"],
            "name": problem["name"],
            "desc": problem["desc"],
            "keywords": problem["keywords"],
            "items": items,
            "countries": countries,
        })
        country_summary = ", ".join(f"{c['name']}{c['count']}" for c in countries) or "無"
        print(f"  → {len(items)} 則｜{country_summary}", flush=True)

    total = sum(len(c["items"]) for c in categories)
    return {
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "title": "超級生命密碼｜學員分享影音圖書館",
        "subtitle": "先依「解決什麼問題」分類，再依國家／地區分支",
        "count": total,
        "countries": [{"id": c["id"], "name": c["name"]} for c in COUNTRIES],
        "categories": categories,
    }


def main() -> int:
    if subprocess.run(["which", "yt-dlp"], capture_output=True).returncode != 0:
        print("yt-dlp not found", file=sys.stderr)
        return 1
    OUT.parent.mkdir(parents=True, exist_ok=True)
    cat = build()
    OUT.write_text(json.dumps(cat, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {cat['count']} items -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
