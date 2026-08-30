#!/usr/bin/env python3
"""產生太陽心語 PWA 圖示：小太陽＋語錄卡片＋圖片框（與影音圖書館區隔）。"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "taiyang-xinyu"

BG_TOP = (255, 252, 245)
BG_BOT = (255, 228, 195)
ACCENT = (196, 92, 42)
ACCENT2 = (232, 148, 90)
SUN = (255, 204, 64)
SUN_RAY = (255, 180, 50)
CARD = (255, 255, 255)
FRAME = (245, 235, 220)
INK = (90, 58, 34)
MUTED = (170, 130, 95)


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def draw_sun(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, size: int) -> None:
    lw = max(2, size // 72)
    for i in range(12):
        ang = math.radians(i * 30)
        inner = r * 1.12
        outer = r * 1.42
        x1 = cx + math.cos(ang) * inner
        y1 = cy + math.sin(ang) * inner
        x2 = cx + math.cos(ang) * outer
        y2 = cy + math.sin(ang) * outer
        draw.line([(x1, y1), (x2, y2)], fill=SUN_RAY, width=lw)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=SUN, outline=ACCENT, width=lw)


def draw_quote_marks(draw: ImageDraw.ImageDraw, x: float, y: float, s: float) -> None:
    lw = max(2, int(s * 0.18))
    for dx in (0, s * 0.55):
        draw.arc(
            [x + dx, y, x + dx + s * 0.42, y + s * 0.55],
            start=200, end=340, fill=ACCENT2, width=lw,
        )


def draw_sound_wave(draw: ImageDraw.ImageDraw, x: float, y: float, h: float, size: int) -> None:
    lw = max(2, size // 80)
    for i, frac in enumerate((0.35, 0.65, 0.95)):
        hh = h * frac
        draw.line([(x + i * h * 0.35, y - hh / 2), (x + i * h * 0.35, y + hh / 2)], fill=ACCENT, width=lw)
    draw.arc([x + h * 0.55, y - h * 0.55, x + h * 1.55, y + h * 0.55], start=-55, end=55, fill=ACCENT, width=lw)


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
        fill=(255, 252, 247, 255),
        outline=ACCENT,
        width=max(2, size // 96),
    )

    cx = size * 0.5
    sun_r = size * 0.11
    draw_sun(draw, cx, size * 0.24, sun_r, size)

    # 語錄圖片框（Polaroid 風）
    fw = size * 0.58
    fh = size * 0.42
    fx = cx - fw / 2
    fy = size * 0.34
    shadow = size * 0.012
    draw.rounded_rectangle(
        [fx + shadow, fy + shadow, fx + fw + shadow, fy + fh + shadow + size * 0.08],
        radius=size * 0.025,
        fill=(210, 180, 150, 120),
    )
    draw.rounded_rectangle(
        [fx, fy, fx + fw, fy + fh + size * 0.08],
        radius=size * 0.025,
        fill=CARD,
        outline=ACCENT,
        width=max(2, size // 80),
    )
    inner_pad = size * 0.035
    draw.rounded_rectangle(
        [fx + inner_pad, fy + inner_pad, fx + fw - inner_pad, fy + fh - inner_pad * 0.5],
        radius=size * 0.018,
        fill=FRAME,
        outline=ACCENT2,
        width=max(1, size // 128),
    )

    draw_quote_marks(draw, fx + inner_pad * 1.2, fy + inner_pad * 1.1, size * 0.05)

    lw = max(2, size // 72)
    line_x1 = fx + fw * 0.18
    line_x2 = fx + fw * 0.82
    base_y = fy + fh * 0.38
    for i, (x2_frac, col) in enumerate([(0.82, ACCENT), (0.72, INK), (0.62, MUTED)]):
        ly = base_y + i * size * 0.045
        draw.line([(line_x1, ly), (fx + fw * x2_frac, ly)], fill=col, width=lw)

    # 底部標籤「心語」暗示
    tag_w = size * 0.22
    tag_h = size * 0.07
    tx = cx - tag_w / 2
    ty = fy + fh + size * 0.015
    draw.rounded_rectangle([tx, ty, tx + tag_w, ty + tag_h], radius=tag_h / 2, fill=ACCENT)
    dot_r = tag_h * 0.12
    draw.ellipse([tx + tag_w * 0.22 - dot_r, ty + tag_h * 0.5 - dot_r,
                  tx + tag_w * 0.22 + dot_r, ty + tag_h * 0.5 + dot_r], fill=SUN)
    draw.ellipse([tx + tag_w * 0.78 - dot_r, ty + tag_h * 0.5 - dot_r,
                  tx + tag_w * 0.78 + dot_r, ty + tag_h * 0.5 + dot_r], fill=SUN)

    # 右下角小音波（朗讀）
    draw_sound_wave(draw, size * 0.78, size * 0.78, size * 0.07, size)

    return img


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for size, name in ((512, "icon-512.png"), (192, "icon-192.png"), (180, "icon-180.png")):
        path = OUT / name
        draw_icon(size).convert("RGB").save(path, optimize=True)
        print(f"Wrote {path}")
    apple = OUT / "apple-touch-icon.png"
    apple.write_bytes((OUT / "icon-180.png").read_bytes())
    print(f"Wrote {apple}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
