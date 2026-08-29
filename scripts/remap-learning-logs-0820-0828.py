#!/usr/bin/env python3
"""重編 0820–0828 日誌編號；0829 不動。原 0820→0828，0821→0820 … 0828→0827。"""
import re
from pathlib import Path

NEW_FROM_OLD = {
    20: 21, 21: 22, 22: 23, 23: 24, 24: 25,
    25: 26, 26: 27, 27: 28, 28: 20, 29: 29,
}

OLD_TO_NEW = {old: new for new, old in NEW_FROM_OLD.items()}

INDEX_ENTRIES = [
    (29, "20260829 選歌置頂 · 內建歌詞 · 習作工具入口",
     "KTV／一般播放｜歌詞快取｜橘色入口｜https://copyshae.github.io/hello-world/directory/apps/taiyang-music/"),
    (28, "20260828 環境教育終身學習網・國中課堂影片",
     "蟹蟹蒞臨｜護蟹任務｜南疆沃海｜海J16｜線上 https://copyshae.github.io/hello-world/directory/202608/20260828-learning-log.html"),
    (27, "20260827 練唱紀錄 · A-B 循環 · 成果分享卡",
     "本機紀錄｜難句循環｜PNG 成果卡｜https://copyshae.github.io/hello-world/directory/apps/taiyang-music/"),
    (26, "20260826 KTV 唱完評分與練唱建議",
     "綜合分數｜提升建議｜歷史最佳｜https://copyshae.github.io/hello-world/directory/apps/taiyang-music/"),
    (25, "20260825 盛德歌曲 KTV 模式（大字幕 · 伴唱）",
     "快捷鍵 K｜字幕同步｜伴唱切換｜https://copyshae.github.io/hello-world/directory/apps/taiyang-music/"),
    (24, "20260824 太陽盛德導師歌曲連播 PWA",
     "注入彩虹×3｜富有×3｜曲庫自動更新｜https://copyshae.github.io/hello-world/directory/apps/taiyang-music/"),
    (23, "20260823 弟子規 41 集 PWA（蔡禮旭 · 1.75／2 倍速）",
     "細講弟子規 1–41 集｜加入主畫面｜https://copyshae.github.io/hello-world/directory/apps/dizigui-41/"),
    (22, "20260822 看書／看文件（doc-reader）",
     "中英讀誦｜英文逐句／全文譯中｜節錄四面向｜疊加七習慣｜https://copyshae.github.io/hello-world/directory/apps/doc-reader/"),
    (21, "20260821 七個好習慣分類（獨立 App）",
     "匯出匯入四格式｜時間象限｜康軒國一｜https://copyshae.github.io/hello-world/directory/apps/habits-7/"),
    (20, "20260820 每日14樣功課備忘錄",
     "勾選消失｜每日重置｜加到主畫面｜https://copyshae.github.io/hello-world/directory/apps/daily-14/"),
]


def remap_refs(text: str) -> str:
    for old in sorted(OLD_TO_NEW.keys(), reverse=True):
        text = text.replace(f"202608{old:02d}", f"@@D{old:02d}@@")
    for old, new in OLD_TO_NEW.items():
        text = text.replace(f"@@D{old:02d}@@", f"202608{new:02d}")

    def short_num(old: int) -> str:
        return f"082{old % 10}" if old >= 20 else f"082{old}"

    for old in sorted(OLD_TO_NEW.keys(), reverse=True):
        pat = re.compile(r"(?<![0-9/])" + re.escape(short_num(old)) + r"(?![0-9])")
        text = pat.sub(f"@@N{old:02d}@@", text)
    for old, new in OLD_TO_NEW.items():
        text = text.replace(f"@@N{old:02d}@@", short_num(new))
    return text


def patch_index_list(html: str) -> str:
    start = html.find('<ul class="dir-list" id="log-list">')
    marker = '<a href="20260819-learning-log.html">'
    end = html.find(marker)
    if start == -1 or end == -1:
        raise ValueError("index.html 找不到列表區塊")
    end = html.rfind("<li", start, end)
    items = []
    for num, title, span in INDEX_ENTRIES:
        items.append(f"""      <li>
        <a href="202608{num:02d}-learning-log.html">
          {title}
          <span>{span}</span>
        </a>
      </li>""")
    new_block = '<ul class="dir-list" id="log-list">\n' + "\n".join(items) + "\n      <li>\n        "
    return html[:start] + new_block + html[end:]


def finalize_content(new_num: int, content: str) -> str:
    if new_num == 29:
        content = content.replace(
            './20260828-learning-log.html">0828 練唱紀錄與成果卡',
            './20260827-learning-log.html">0827 練唱紀錄與成果卡',
        ).replace(
            './20260828-learning-log.html">0828 練唱紀錄 · A-B 循環 · 成果卡',
            './20260827-learning-log.html">0827 練唱紀錄 · A-B 循環 · 成果卡',
        )
    if new_num == 28:
        content = content.replace(
            './20260819-learning-log.html">0819',
            './20260827-learning-log.html">0827 練唱紀錄 · A-B 循環 · 成果卡',
        )
        content = content.replace("日誌日期接線上最後一篇", "接日誌")
    return content


def process_dir(src_dir: Path) -> None:
    needed = set(NEW_FROM_OLD.values())
    originals = {}
    for n in needed:
        path = src_dir / f"202608{n:02d}-learning-log.html"
        if not path.exists():
            raise FileNotFoundError(path)
        originals[n] = path.read_text(encoding="utf-8")
    for new_num, old_num in NEW_FROM_OLD.items():
        content = originals[old_num]
        if new_num != 29:
            content = remap_refs(content)
        content = finalize_content(new_num, content)
        out = src_dir / f"202608{new_num:02d}-learning-log.html"
        out.write_text(content, encoding="utf-8")
        print("wrote", out)
    idx = src_dir / "index.html"
    if idx.exists():
        idx.write_text(patch_index_list(idx.read_text(encoding="utf-8")), encoding="utf-8")
        print("index", idx)


def main():
    export_dir = Path("_export/hello-world/directory/202608")
    docs_dir = Path("docs/directory/202608")
    if export_dir.exists():
        process_dir(export_dir)
    if docs_dir.exists():
        import shutil
        for n in range(20, 30):
            src = export_dir / f"202608{n:02d}-learning-log.html"
            if src.exists():
                shutil.copy2(src, docs_dir / src.name)
        idx_src = export_dir / "index.html"
        if idx_src.exists():
            shutil.copy2(idx_src, docs_dir / "index.html")
        print("synced docs/directory/202608")
    for rel in ["_export/hello-world/directory/learning-log.html", "docs/directory/learning-log.html"]:
        p = Path(rel)
        if p.exists():
            t = p.read_text(encoding="utf-8")
            t = t.replace("0824 弟子規41集", "0820 14樣").replace("0825 盛德歌曲", "0821 七習慣")
            p.write_text(t, encoding="utf-8")


if __name__ == "__main__":
    main()
