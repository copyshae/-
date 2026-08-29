#!/usr/bin/env python3
"""產生太陽盛德歌曲內建歌詞 JSON（優先曲目手動、其餘預留 yt-dlp 擴充）。"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs" / "taiyang-music" / "catalog.json"
LYRICS_DIR = ROOT / "docs" / "taiyang-music" / "lyrics"

# 手動歌詞（官方詞；播放時依片長分段同步）
MANUAL: dict[str, dict] = {
    "注入彩虹": {
        "duration": 314,
        "lines": [
            "一道彩虹化入千年萬境中",
            "奇妙感覺就讓我漸漸會懂",
            "這份愛的禮物 我好感動",
            "千年歲月等待 終於接通",
            "這就是愛 我懂 我誦",
            "我願與 天地相擁",
            "彩虹能量滿溢 終身受用",
            "紅橙黃綠 藍靛紫 圓滿成總",
            "彩虹現 吉祥種",
            "注入彩虹光 萬世通",
            "一道彩虹化入千年萬境中",
            "奇妙感覺就讓我漸漸會懂",
            "這份愛的禮物 我好感動",
            "千年歲月等待 終於接通",
            "這就是愛 我懂 我誦",
            "我願與 天地相擁",
            "彩虹能量滿溢 終身受用",
            "紅橙黃綠 藍靛紫 圓滿成總",
            "彩虹能量滿溢 終身受用",
            "彩虹現 吉祥種",
            "注入彩虹光 萬世通",
            "紅橙黃綠 藍靛紫 圓滿成總",
            "彩虹現 吉祥種",
            "彩虹能量滿溢 終身受用",
            "注入彩虹光 萬世通",
        ],
    },
    "富有": {
        "duration": 345,
        "lines": [
            "人生的富有 你我的追求",
            "有誰會說夠 今生無怨尤",
            "風塵僕僕 一生守候",
            "換來多少值得久留",
            "用盡生命 一再強求",
            "究竟多少真的享有",
            "生命歲月 就在這其中溜走",
            "讓我不得不想想 努力的理由",
            "人生苦短 何時干休",
            "真正滿足 擁有多久",
            "當我接通 天地源頭",
            "才知生命 早已富有",
            "在這一刻 我才明白理由",
            "接通天地 享受真正富有",
            "今生苦苦所求 此刻全部擁有",
            "我願已足 不必再外求",
            "我愛這分感覺 這分緣由",
            "深知接通天地祝福的重要",
            "理由是讓我們成就 懂得享有",
            "是讓今生來世 時時富有",
            "愛天地 愛自己",
            "愛你愛我愛地球",
            "今生無悔不貪求",
            "源來源來 原來原來",
            "富有就在秒秒經由",
            "富有就在日常的生活中",
            "富有就在生命花開花落",
            "那是我們享受的理由",
        ],
    },
}


def main() -> int:
    if not CATALOG.exists():
        print("catalog.json 不存在", file=__import__("sys").stderr)
        return 1
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    LYRICS_DIR.mkdir(parents=True, exist_ok=True)
    index: dict = {"updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%d"), "byVideoId": {}, "byName": {}}

    for song in catalog.get("songs", []):
        name = song.get("name") or ""
        vid = song.get("id") or ""
        karaoke_id = song.get("karaokeId")
        manual = MANUAL.get(name)
        if not manual:
            continue
        payload = {
            "name": name,
            "videoIds": [x for x in [vid, karaoke_id] if x],
            "duration": manual["duration"],
            "source": "manual",
            "lines": manual["lines"],
        }
        for out_id in payload["videoIds"]:
            path = LYRICS_DIR / f"{out_id}.json"
            path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
            index["byVideoId"][out_id] = path.name
        name_path = LYRICS_DIR / f"{name}.json"
        name_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        index["byName"][name] = name_path.name

    (LYRICS_DIR / "index.json").write_text(
        json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"歌詞已寫入 {LYRICS_DIR}（{len(index['byName'])} 首）")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
