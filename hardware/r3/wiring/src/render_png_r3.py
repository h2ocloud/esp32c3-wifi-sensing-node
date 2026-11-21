#!/usr/bin/env python3
# SPDX-License-Identifier: CC0-1.0
"""把 wiring/*.svg 轉成 PNG（1 SVG 單位 = 1 像素），並可做版面檢查。

需要 Python 套件 playwright 與其 Chromium：
    pip install playwright && python3 -m playwright install chromium

    python3 src/render_png.py            # 產生 PNG
    python3 src/render_png.py --check    # 另外檢查：字與字重疊、字被線蓋住、字超出畫布、異網線交叉

自己啟動一個 headless Chromium，用完即關，不連接任何已開啟的瀏覽器。
PNG 不寫入任何文字型 metadata。
"""
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

WIRING = Path(__file__).resolve().parent
FILES = ["wiring_r3_breadboard.svg"]

COLLECT_JS = """
() => {
  const svg = document.documentElement;
  const W = +svg.getAttribute('width'), H = +svg.getAttribute('height');
  const texts = [...document.querySelectorAll('text')].map(t => {
    const b = t.getBBox();
    return {s: t.textContent, x: b.x, y: b.y, w: b.width, h: b.height,
            fs: parseFloat(getComputedStyle(t).fontSize)};
  });
  const wires = [...document.querySelectorAll('path.wire')].map(p => {
    const L = p.getTotalLength(), pts = [];
    for (let i = 0; i <= L; i += 3) { const q = p.getPointAtLength(i); pts.push([q.x, q.y]); }
    return {net: p.dataset.net, w: +p.getAttribute('stroke-width'), pts};
  });
  const minFont = Math.min(...[...document.querySelectorAll('text, tspan')]
                     .map(e => parseFloat(getComputedStyle(e).fontSize)));
  return {W, H, texts, wires, minFont};
}
"""


def shrink(b, k=0.14):
    dy = b["h"] * k
    return (b["x"] + 1, b["y"] + dy, b["x"] + b["w"] - 1, b["y"] + b["h"] - dy)


def overlap(a, b):
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def check(data, name):
    issues = []
    tb = [(t, shrink(t)) for t in data["texts"] if t["s"].strip()]
    for i in range(len(tb)):
        for j in range(i + 1, len(tb)):
            if overlap(tb[i][1], tb[j][1]):
                issues.append(f"字重疊：『{tb[i][0]['s'][:24]}』×『{tb[j][0]['s'][:24]}』")
    for t, r in tb:
        if r[0] < 0 or r[1] < 0 or r[2] > data["W"] or r[3] > data["H"]:
            issues.append(f"字超出畫布：『{t['s'][:30]}』")
        for wv in data["wires"]:
            pad = wv["w"] / 2 + 2.5
            if any(r[0] - pad < x < r[2] + pad and r[1] - pad < y < r[3] + pad for x, y in wv["pts"]):
                issues.append(f"線蓋字：{wv['net']} ×『{t['s'][:24]}』")
                break
    segs = []
    for wv in data["wires"]:
        if wv["net"] == "legend":
            continue
        p = wv["pts"]
        segs.append((wv["net"], p))
    for i in range(len(segs)):
        for j in range(i + 1, len(segs)):
            if segs[i][0] == segs[j][0]:
                continue
            a, b = segs[i][1], segs[j][1]
            hit = None
            bset = {(round(x / 4), round(y / 4)) for x, y in b}
            for x, y in a:
                if (round(x / 4), round(y / 4)) in bset:
                    hit = (x, y)
                    break
            if hit:
                issues.append(f"異網線交叉：{segs[i][0]} × {segs[j][0]} 約在 ({hit[0]:.0f},{hit[1]:.0f})")
    print(f"[{name}] 畫布 {data['W']}x{data['H']}，最小字級 {data['minFont']} px，"
          f"文字 {len(tb)} 段，導線 {len(data['wires'])} 條")
    for s in issues:
        print("  ! " + s)
    if not issues:
        print("  OK：無重疊、無蓋字、無越界、無異網交叉")
    return issues


def main():
    do_check = "--check" in sys.argv
    total = 0
    with sync_playwright() as p:
        browser = p.chromium.launch()
        try:
            for name in FILES:
                svg = WIRING / name
                text = svg.read_text(encoding="utf-8")
                w = int(text.split('width="', 1)[1].split('"', 1)[0])
                h = int(text.split('height="', 1)[1].split('"', 1)[0])
                page = browser.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
                page.goto(svg.as_uri())
                page.evaluate("document.fonts.ready.then(() => true)")
                page.wait_for_timeout(200)
                out = svg.with_suffix(".png")
                page.screenshot(path=str(out), clip={"x": 0, "y": 0, "width": w, "height": h})
                print(f"wrote {out.name} ({w}x{h})")
                if do_check:
                    total += len(check(page.evaluate(COLLECT_JS), name))
                page.close()
        finally:
            browser.close()
    if do_check:
        print("檢查結果：" + ("全部通過" if total == 0 else f"{total} 個問題"))


if __name__ == "__main__":
    main()
