#!/usr/bin/env python3
"""合併種子語錄、手動連結與網路搜尋，產生太陽心語 catalog.json 與語錄卡片。"""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
import textwrap
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "data" / "taiyang-xinyu-seed.json"
LINKS = ROOT / "data" / "taiyang-xinyu-links.json"
OUT_DIR = ROOT / "docs" / "taiyang-xinyu"
CARDS = OUT_DIR / "cards"
MIRROR = CARDS / "mirror"
CATALOG = OUT_DIR / "catalog.json"

BG_TOP = (255, 252, 245)
BG_BOT = (255, 235, 200)
ACCENT = (196, 92, 42)
INK = (58, 40, 24)
MUTED = (122, 96, 64)
SUN = (255, 200, 60)

IMAGE_QUERIES = [
    "太陽心語 太陽盛德",
    "太陽心語 site:cdn.richestlife.com",
    "太陽心語 site:richestlife.com",
    "太陽盛德 心語 箴言",
]

TEXT_QUERIES = [
    "太陽心語 site:richestlife.com",
    "太陽心語 site:facebook.com/photo",
]

SKIP_IMAGE_HOST = (
    "shopee.", "蝦皮", "logo", "icon", "avatar", "favicon", "pixel",
    "profile", "emoji", "button", "banner-ad",
)

XINYU_MARK = re.compile(r"太陽心語|心語|箴言|導師")


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc" if bold else "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/truetype/noto/NotoSansCJK-Bold.ttc" if bold else "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for p in candidates:
        if Path(p).exists():
            try:
                return ImageFont.truetype(p, size)
            except OSError:
                pass
    return ImageFont.load_default()


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def wrap_text(text: str, width: int) -> list[str]:
    lines: list[str] = []
    for para in (text or "").split("\n"):
        para = para.strip()
        if not para:
            continue
        lines.extend(textwrap.wrap(para, width=width) or [para])
    return lines


def draw_sun(draw: ImageDraw.ImageDraw, cx: int, cy: int, r: int) -> None:
    import math
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=SUN, outline=ACCENT, width=max(2, r // 24))
    for i in range(8):
        rad = math.radians(i * 45)
        x1 = cx + int(math.cos(rad) * (r + 4))
        y1 = cy + int(math.sin(rad) * (r + 4))
        x2 = cx + int(math.cos(rad) * (r + r // 3))
        y2 = cy + int(math.sin(rad) * (r + r // 3))
        draw.line([(x1, y1), (x2, y2)], fill=ACCENT, width=max(2, r // 20))


def draw_card(item: dict, path: Path) -> None:
    w, h = 720, 960
    img = Image.new("RGB", (w, h), BG_TOP)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        col = (lerp(BG_TOP[0], BG_BOT[0], t), lerp(BG_TOP[1], BG_BOT[1], t), lerp(BG_TOP[2], BG_BOT[2], t))
        draw.line([(0, y), (w, y)], fill=col)

    pad = 48
    draw.rounded_rectangle([pad, pad, w - pad, h - pad], radius=28, fill=(255, 255, 255), outline=ACCENT, width=3)
    draw_sun(draw, w - pad - 56, pad + 56, 36)

    title_font = load_font(42, bold=True)
    quote_font = load_font(36, bold=True)
    plain_font = load_font(28)
    meta_font = load_font(22)

    y = pad + 36
    title = item.get("title") or "太陽心語"
    draw.text((pad + 36, y), title, fill=ACCENT, font=title_font)
    y += 58
    draw.line([(pad + 36, y), (w - pad - 36, y)], fill=ACCENT, width=2)
    y += 28

    for line in wrap_text(item.get("text") or "", 14):
        draw.text((pad + 36, y), line, fill=INK, font=quote_font)
        y += 52

    y += 12
    for line in wrap_text(item.get("plain") or "", 18):
        draw.text((pad + 36, y), line, fill=MUTED, font=plain_font)
        y += 38

    cat = item.get("category") or ""
    footer = f"太陽心語 · {cat}" if cat else "太陽心語"
    bbox = draw.textbbox((0, 0), footer, font=meta_font)
    tw = bbox[2] - bbox[0]
    draw.text(((w - tw) // 2, h - pad - 48), footer, fill=ACCENT, font=meta_font)

    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG", optimize=True)


def slug_id(prefix: str, key: str) -> str:
    h = hashlib.sha1(key.encode("utf-8")).hexdigest()[:10]
    return f"{prefix}-{h}"


def clean_title(s: str) -> str:
    s = re.sub(r"\s+", " ", (s or "").strip())
    s = re.sub(r"[-_|｜]+", " ", s)
    s = re.sub(r"\.(jpg|jpeg|png|webp).*$", "", s, flags=re.I)
    return s[:80] if s else "太陽心語"


def guess_category(title: str, text: str = "") -> str:
    blob = title + text
    rules = [
        ("感恩", "感恩"), ("懺悔", "德行"), ("愛", "和諧"), ("修行", "修行"),
        ("智慧", "智慧"), ("心法", "心法"), ("豐盛", "生活"), ("富足", "生活"),
        ("轉念", "心法"), ("盲點", "修行"), ("共修", "修行"),
    ]
    for kw, cat in rules:
        if kw in blob:
            return cat
    return "生活"


def normalize_url(url: str) -> str:
    from urllib.parse import quote, unquote, urlsplit, urlunsplit
    p = urlsplit(url.strip())
    segs = []
    for seg in p.path.split("/"):
        if not seg:
            segs.append("")
            continue
        try:
            seg = unquote(seg)
        except Exception:
            pass
        segs.append(quote(seg, safe=""))
    path = "/".join(segs)
    if path and not path.startswith("/"):
        path = "/" + path
    return urlunsplit((p.scheme, p.netloc, path, p.query, p.fragment))


def guess_ext(data: bytes, url: str) -> str:
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return ".png"
    if data[:3] == b"GIF":
        return ".gif"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return ".webp"
    low = url.lower()
    for ext in (".png", ".jpg", ".jpeg", ".webp", ".gif"):
        if ext in low:
            return ext if ext != ".jpeg" else ".jpg"
    return ".jpg"


def mirror_image(url: str, dest_base: Path) -> Path | None:
    enc = normalize_url(url)
    try:
        req = urllib.request.Request(enc, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
        if len(data) < 800:
            return None
        ext = guess_ext(data, url)
        dest = dest_base.with_suffix(ext)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        return dest
    except Exception as e:
        print(f"鏡像失敗 [{url[:70]}…]: {e}")
        return None


def is_good_image(url: str, title: str = "") -> bool:
    if not url or not url.startswith("http"):
        return False
    low = (url + " " + title).lower()
    if any(x in low for x in SKIP_IMAGE_HOST):
        return False
    if not re.search(r"\.(jpg|jpeg|png|webp|gif)(\?|$)", low, re.I):
        if "lookaside.fbsbx.com" not in low and "cdn.richestlife.com" not in low:
            return False
    return True


def search_images_ddgs() -> list[dict]:
    try:
        from ddgs import DDGS
    except ImportError:
        print("ddgs 未安裝，略過圖片搜尋（pip install ddgs）")
        return []

    out: list[dict] = []
    seen: set[str] = set()
    for q in IMAGE_QUERIES:
        try:
            rows = list(DDGS().images(q, max_results=20))
        except Exception as e:
            print(f"圖片搜尋失敗 [{q}]: {e}")
            continue
        for row in rows:
            img = (row.get("image") or "").strip()
            if not is_good_image(img, row.get("title") or ""):
                continue
            if img in seen:
                continue
            seen.add(img)
            title = clean_title(row.get("title") or "")
            page = (row.get("url") or "").strip()
            text = title
            if XINYU_MARK.search(title) or "richestlife" in img or "richestlife" in page:
                out.append({
                    "id": slug_id("web", img),
                    "title": title,
                    "text": text,
                    "plain": "",
                    "category": guess_category(title),
                    "date": "",
                    "source": "網路搜尋",
                    "imageUrl": img,
                    "pageUrl": page,
                })
    return out


def search_youtube_thumbs() -> list[dict]:
    cmd = ["yt-dlp", "--flat-playlist", "--dump-json", "ytsearch20:太陽盛德 太陽心語"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    out: list[dict] = []
    for line in r.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        title = (d.get("title") or "").strip()
        vid = d.get("id") or ""
        if not vid or "太陽心語" not in title and "太阳心语" not in title:
            continue
        img = f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg"
        out.append({
            "id": slug_id("yt", vid),
            "title": clean_title(title),
            "text": title,
            "plain": "YouTube 太陽心語相關影音縮圖",
            "category": guess_category(title),
            "date": "",
            "source": "YouTube 搜尋",
            "imageUrl": img,
            "pageUrl": f"https://www.youtube.com/watch?v={vid}",
        })
    return out


def fetch_page_images(url: str) -> list[str]:
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        html = urllib.request.urlopen(req, timeout=20).read().decode("utf-8", "ignore")
    except Exception:
        return []
    imgs = re.findall(r'https?://[^"\']+\.(?:jpg|jpeg|png|webp)[^"\']*', html, re.I)
    og = re.search(r'property="og:image"\s+content="([^"]+)"', html, re.I)
    if og:
        imgs.insert(0, og.group(1))
    return [u.replace("&amp;", "&") for u in imgs if is_good_image(u)]


def search_richestlife_articles() -> list[dict]:
    try:
        from ddgs import DDGS
    except ImportError:
        return []

    out: list[dict] = []
    seen: set[str] = set()
    for q in TEXT_QUERIES:
        try:
            rows = list(DDGS().text(q, max_results=12))
        except Exception as e:
            print(f"文章搜尋失敗 [{q}]: {e}")
            continue
        for row in rows:
            page = (row.get("href") or "").strip()
            title = clean_title(row.get("title") or "")
            if not page or page in seen:
                continue
            if "richestlife" not in page and "facebook.com" not in page:
                continue
            seen.add(page)
            for img in fetch_page_images(page)[:2]:
                out.append({
                    "id": slug_id("art", img),
                    "title": title,
                    "text": title,
                    "plain": "",
                    "category": guess_category(title),
                    "date": "",
                    "source": "網路搜尋",
                    "imageUrl": img,
                    "pageUrl": page,
                })
    return out


def merge_items() -> list[dict]:
    seed = json.loads(SEED.read_text(encoding="utf-8"))
    links = json.loads(LINKS.read_text(encoding="utf-8")) if LINKS.exists() else []
    web = search_images_ddgs()
    yt = search_youtube_thumbs()
    art = search_richestlife_articles()

    print(f"種子 {len(seed)}｜手動 {len(links)}｜圖搜 {len(web)}｜YouTube {len(yt)}｜文章 {len(art)}")

    seen_id: set[str] = set()
    seen_img: set[str] = set()
    out: list[dict] = []

    for src in seed + links + web + yt + art:
        if src.get("disabled"):
            continue
        iid = (src.get("id") or "").strip()
        if not iid or iid in seen_id:
            continue
        title = (src.get("title") or "").strip()
        text = (src.get("text") or "").strip()
        img = (src.get("imageUrl") or "").strip()
        if not title and not text and not img:
            continue
        if img:
            if img in seen_img:
                continue
            seen_img.add(img)
        seen_id.add(iid)
        out.append({
            "id": iid,
            "title": title or text[:24] or "太陽心語",
            "text": text,
            "plain": (src.get("plain") or "").strip(),
            "category": (src.get("category") or guess_category(title, text)).strip(),
            "date": (src.get("date") or "").strip(),
            "source": (src.get("source") or "種子語錄").strip(),
            "imageUrl": img,
            "pageUrl": (src.get("pageUrl") or "").strip(),
        })
    return out


def build() -> dict:
    items = merge_items()
    CARDS.mkdir(parents=True, exist_ok=True)
    MIRROR.mkdir(parents=True, exist_ok=True)

    for it in items:
        ext_url = (it.get("imageUrl") or "").strip()
        if ext_url:
            it["imageUrl"] = normalize_url(ext_url)
            mirrored = mirror_image(it["imageUrl"], MIRROR / it["id"])
            if mirrored:
                it["imageLocal"] = f"cards/mirror/{mirrored.name}"
                print(f"鏡像 {it['id']} → {it['imageLocal']}")
            else:
                rel = f"cards/{it['id']}.png"
                draw_card(it, CARDS / f"{it['id']}.png")
                it["imageLocal"] = rel
                print(f"外部圖失效，改卡片 {it['id']}")
        else:
            rel = f"cards/{it['id']}.png"
            draw_card(it, CARDS / f"{it['id']}.png")
            it["imageLocal"] = rel

    cats: dict[str, list] = {}
    for it in items:
        cats.setdefault(it["category"], []).append(it)

    categories = [{"id": name, "name": name, "items": cats[name]} for name in sorted(cats.keys())]

    catalog = {
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "count": len(items),
        "categories": categories,
        "items": items,
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {CATALOG} ({len(items)} items, {len(categories)} categories)")
    return catalog


if __name__ == "__main__":
    build()
