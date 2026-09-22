#!/usr/bin/env python3
"""產生基金評估台 PWA 圖示：淨值曲線＋進出場標記。"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "fund-eval"

BG_TOP = (236, 245, 242)
BG_BOT = (200, 220, 214)
ACCENT = (20, 90, 78)
BUY = (14, 122, 76)
SELL = (180, 35, 24)
LINE = (40, 110, 95)
PAPER = (250, 252, 250)


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), BG_BOT)
    px = img.load()
    for y in range(size):
        t = y / max(1, size - 1)
        c = (
            lerp(BG_TOP[0], BG_BOT[0], t),
            lerp(BG_TOP[1], BG_BOT[1], t),
            lerp(BG_TOP[2], BG_BOT[2], t),
        )
        for x in range(size):
            px[x, y] = c

    d = ImageDraw.Draw(img)
    lw = max(2, size // 48)
    s = size
    pad = s * 0.14
    # panel
    d.rounded_rectangle(
        [pad, pad, s - pad, s - pad],
        radius=s * 0.08,
        fill=PAPER,
        outline=ACCENT,
        width=lw,
    )
    # chart polyline (dip then recover) — buy zone left, sell zone right
    pts = [
        (s * 0.22, s * 0.58),
        (s * 0.32, s * 0.68),
        (s * 0.42, s * 0.62),
        (s * 0.52, s * 0.48),
        (s * 0.62, s * 0.40),
        (s * 0.72, s * 0.34),
        (s * 0.78, s * 0.30),
    ]
    d.line(pts, fill=LINE, width=max(3, lw + 1))
    # buy marker (triangle up)
    bx, by = pts[1]
    tri = [(bx, by - s * 0.07), (bx - s * 0.045, by + s * 0.02), (bx + s * 0.045, by + s * 0.02)]
    d.polygon(tri, fill=BUY)
    # sell marker (triangle down)
    sx, sy = pts[-1]
    tri2 = [(sx, sy + s * 0.07), (sx - s * 0.045, sy - s * 0.02), (sx + s * 0.045, sy - s * 0.02)]
    d.polygon(tri2, fill=SELL)
    # MA dashed feel
    d.line([(s * 0.22, s * 0.52), (s * 0.78, s * 0.52)], fill=(160, 185, 175), width=max(1, lw - 1))
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for size, name in ((180, "icon-180.png"), (192, "icon-192.png"), (512, "icon-512.png")):
        draw_icon(size).save(OUT / name, "PNG")
        print("wrote", OUT / name)


if __name__ == "__main__":
    main()
