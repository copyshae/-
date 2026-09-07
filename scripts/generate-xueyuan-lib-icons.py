#!/usr/bin/env python3
"""產生學員分享影音圖書館 PWA 圖示（人群＋播放＋心）。"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "xueyuan-lib"

BG_TOP = (248, 252, 255)
BG_BOT = (210, 232, 245)
ACCENT = (30, 95, 130)
ACCENT2 = (56, 150, 180)
HEART = (196, 92, 74)
WHITE = (255, 255, 255)
PAPER = (255, 252, 248)


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
        fill=(255, 252, 248, 255),
        outline=ACCENT,
        width=max(2, size // 96),
    )

    cx = size // 2
    # 三人剪影（學員）
    heads = [
        (cx - size * 0.18, size * 0.38),
        (cx, size * 0.34),
        (cx + size * 0.18, size * 0.38),
    ]
    hr = size * 0.055
    for hx, hy in heads:
        draw.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=ACCENT2, outline=ACCENT, width=max(1, size // 128))
        # 肩
        bw = size * 0.12
        bh = size * 0.10
        draw.ellipse(
            [hx - bw, hy + hr * 0.6, hx + bw, hy + hr * 0.6 + bh],
            fill=ACCENT,
        )

    # 播放鈕
    pr = size * 0.11
    px, py = cx, size * 0.68
    draw.ellipse(
        [px - pr, py - pr, px + pr, py + pr],
        fill=ACCENT2,
        outline=ACCENT,
        width=max(1, size // 128),
    )
    ts = pr * 0.5
    draw.polygon(
        [
            (px - ts * 0.35, py - ts),
            (px - ts * 0.35, py + ts),
            (px + ts * 0.95, py),
        ],
        fill=WHITE,
    )

    # 小愛心（感恩／愛）
    cr = size * 0.04
    hx, hy = cx + size * 0.28, size * 0.28
    draw.ellipse([hx - cr, hy - cr * 0.5, hx, hy + cr * 0.5], fill=HEART)
    draw.ellipse([hx, hy - cr * 0.5, hx + cr, hy + cr * 0.5], fill=HEART)
    draw.polygon([(hx - cr * 1.05, hy), (hx + cr * 1.05, hy), (hx, hy + cr * 1.35)], fill=HEART)

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
