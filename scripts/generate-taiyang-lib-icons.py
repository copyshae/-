#!/usr/bin/env python3
"""產生太陽盛德導師影音圖書館 PWA 圖示（書本＋播放＋太陽）。"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "taiyang-lib"

BG_TOP = (255, 253, 248)
BG_BOT = (245, 230, 200)
ACCENT = (139, 90, 20)
ACCENT2 = (196, 146, 42)
PAPER = (255, 252, 245)
WHITE = (255, 255, 255)


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for y in range(size):
        t = y / max(size - 1, 1)
        col = (
            lerp(BG_TOP[0], BG_BOT[0], t),
            lerp(BG_TOP[1], BG_BOT[1], t),
            lerp(BG_TOP[2], BG_BOT[2], t),
            255,
        )
        draw.line([(0, y), (size, y)], fill=col)

    pad = size * 0.06
    radius = size * 0.16
    draw.rounded_rectangle(
        [pad, pad, size - pad, size - pad],
        radius=radius,
        fill=(255, 250, 242, 255),
        outline=ACCENT,
        width=max(2, size // 96),
    )

    cx = size // 2
    book_w = size * 0.58
    book_h = size * 0.40
    bx = cx - book_w / 2
    by = cy = size * 0.46

    lw = max(2, size // 72)
    draw.polygon(
        [
            (cx, by),
            (bx, by + book_h * 0.12),
            (bx, by + book_h),
            (cx, by + book_h * 0.90),
        ],
        fill=PAPER,
        outline=ACCENT,
    )
    draw.polygon(
        [
            (cx, by),
            (bx + book_w, by + book_h * 0.12),
            (bx + book_w, by + book_h),
            (cx, by + book_h * 0.90),
        ],
        fill=WHITE,
        outline=ACCENT,
    )
    draw.line([(cx, by), (cx, by + book_h * 0.90)], fill=ACCENT, width=lw)

    # 左頁：音波
    ax = bx + book_w * 0.20
    ay = cy + size * 0.02
    for i in range(3):
        r = size * (0.045 + i * 0.018)
        draw.arc(
            [ax - r, ay - r, ax + r, ay + r],
            start=-55,
            end=55,
            fill=ACCENT,
            width=max(2, size // 80),
        )

    # 右頁：播放
    pr = size * 0.085
    px = cx + book_w * 0.24
    py = cy + size * 0.02
    draw.ellipse(
        [px - pr, py - pr, px + pr, py + pr],
        fill=ACCENT2,
        outline=ACCENT,
        width=max(1, size // 128),
    )
    ts = pr * 0.55
    draw.polygon(
        [
            (px - ts * 0.35, py - ts),
            (px - ts * 0.35, py + ts),
            (px + ts * 0.95, py),
        ],
        fill=WHITE,
    )

    # 頂部小太陽（太陽盛德）
    sun_r = size * 0.065
    sx, sy = cx, by - sun_r * 1.35
    draw.ellipse(
        [sx - sun_r, sy - sun_r, sx + sun_r, sy + sun_r],
        fill=ACCENT2,
        outline=ACCENT,
        width=max(1, size // 128),
    )
    ray_len = size * 0.045
    for deg in range(0, 360, 45):
        rad = math.radians(deg)
        x1 = sx + (sun_r * 1.15) * math.cos(rad)
        y1 = sy + (sun_r * 1.15) * math.sin(rad)
        x2 = sx + (sun_r * 1.15 + ray_len) * math.cos(rad)
        y2 = sy + (sun_r * 1.15 + ray_len) * math.sin(rad)
        draw.line([(x1, y1), (x2, y2)], fill=ACCENT2, width=max(2, size // 96))

    return img


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for size, name in ((512, "icon-512.png"), (192, "icon-192.png"), (180, "icon-180.png")):
        path = OUT / name
        draw_icon(size).convert("RGB").save(path, optimize=True)
        print(f"Wrote {path}")
    # iOS Safari 常用根目錄 apple-touch-icon.png
    icon180 = OUT / "icon-180.png"
    apple = OUT / "apple-touch-icon.png"
    apple.write_bytes(icon180.read_bytes())
    print(f"Wrote {apple}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
