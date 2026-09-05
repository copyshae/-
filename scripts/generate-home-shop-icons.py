#!/usr/bin/env python3
"""產生家電家具購物帳 PWA 圖示：沙發＋家電輪廓＋收據。"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "home-shop"

BG_TOP = (232, 244, 248)
BG_BOT = (196, 220, 228)
ACCENT = (30, 90, 110)
WOOD = (180, 120, 70)
PAPER = (255, 252, 245)
INK = (28, 48, 58)
LINE = (50, 110, 130)


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
    lw = max(2, size // 64)
    s = size

    # sofa
    sx, sy = s * 0.18, s * 0.52
    sw, sh = s * 0.42, s * 0.22
    d.rounded_rectangle([sx, sy, sx + sw, sy + sh], radius=s * 0.04, fill=WOOD, outline=ACCENT, width=lw)
    d.rounded_rectangle(
        [sx + sw * 0.08, sy - sh * 0.35, sx + sw * 0.92, sy + sh * 0.15],
        radius=s * 0.03,
        fill=(210, 150, 95),
        outline=ACCENT,
        width=lw,
    )
    # legs
    leg_w = s * 0.035
    for lx in (sx + sw * 0.12, sx + sw * 0.78):
        d.rectangle([lx, sy + sh, lx + leg_w, sy + sh + s * 0.06], fill=ACCENT)

    # appliance (fridge-like)
    ax, ay = s * 0.58, s * 0.28
    aw, ah = s * 0.22, s * 0.38
    d.rounded_rectangle([ax, ay, ax + aw, ay + ah], radius=s * 0.025, fill=(240, 246, 250), outline=ACCENT, width=lw)
    d.line([(ax, ay + ah * 0.42), (ax + aw, ay + ah * 0.42)], fill=LINE, width=lw)
    d.line([(ax + aw * 0.82, ay + ah * 0.12), (ax + aw * 0.82, ay + ah * 0.32)], fill=LINE, width=max(2, lw))
    d.line([(ax + aw * 0.82, ay + ah * 0.52), (ax + aw * 0.82, ay + ah * 0.78)], fill=LINE, width=max(2, lw))

    # receipt
    rx, ry = s * 0.28, s * 0.18
    rw, rh = s * 0.28, s * 0.34
    d.rounded_rectangle([rx, ry, rx + rw, ry + rh], radius=s * 0.02, fill=PAPER, outline=ACCENT, width=lw)
    for i in range(4):
        y = ry + rh * (0.22 + i * 0.16)
        d.line([(rx + rw * 0.15, y), (rx + rw * 0.85, y)], fill=(170, 190, 200), width=max(2, lw - 1))
    # $ mark circle
    cx, cy, cr = rx + rw * 0.5, ry + rh * 0.12, s * 0.045
    d.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=ACCENT)
    # coin shine
    d.ellipse([cx - cr * 0.35, cy - cr * 0.55, cx + cr * 0.15, cy - cr * 0.05], fill=(90, 160, 180))

    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for size, name in ((180, "icon-180.png"), (192, "icon-192.png"), (512, "icon-512.png")):
        draw_icon(size).save(OUT / name, "PNG")
        print("wrote", OUT / name)


if __name__ == "__main__":
    main()
