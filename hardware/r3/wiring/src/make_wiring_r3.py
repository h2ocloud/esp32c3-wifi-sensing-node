#!/usr/bin/env python3
# SPDX-License-Identifier: CC0-1.0
"""R3 麵包板接線圖（只用 Python 標準函式庫）。由 src/make_wiring.py（R2）改寫。

    python3 make_wiring_r3.py      → 同目錄寫出 wiring_r3_breadboard.svg

擺位依外殼設計定稿（2026-11-21）：C3 跨中溝插 C 排／G 排、USB-C 朝右；
DHT11 杜邦線 J2=GND、J3=3V3、J4=GPIO4；IR LED 陽極 J16、陰極 J15；
220 Ω 在 H16–H17；VS1838B 平躺插 C12–C14、鏡頭朝上蓋。
所有孔位座標由 hole() 從麵包板幾何算出，每條線的端點都落在孔中心。
板圖、零件圖全部自繪，CC0-1.0。
"""
from pathlib import Path
from xml.sax.saxutils import escape

OUT_DIR = Path(__file__).resolve().parent

FONT = ("'Noto Sans TC','PingFang TC','Microsoft JhengHei','Heiti TC',"
        "'Noto Sans CJK TC',sans-serif")
INK = "#1a1a1a"
MUTED = "#4f5963"

# 線色（建議）
C_5V = "#f76707"
C_GND = "#2b2b2b"
C_3V3 = "#e03131"
C_SDA = "#1971c2"
C_SCL = "#fcc419"
C_IO3 = "#2f9e44"
C_IO10 = "#7048e8"
# 文字用（對白底對比足夠的深色版本）
T_5V = "#c2410c"
T_GND = "#1a1a1a"
T_3V3 = "#c92a2a"
T_SDA = "#1864ab"
T_SCL = "#8a6100"
T_IO3 = "#2b8a3e"
T_IO10 = "#5f3dc4"


def f(v):
    return f"{v:.1f}".rstrip("0").rstrip(".")


class Svg:
    def __init__(self, w, h, title, desc):
        self.w, self.h, self.title, self.desc = w, h, title, desc
        self.defs = []
        self.body = []

    def add(self, s):
        self.body.append(s)

    def rect(self, x, y, w, h, fill="none", stroke="none", sw=0, rx=0, extra=""):
        self.add(f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(rx)}" '
                 f'fill="{fill}" stroke="{stroke}" stroke-width="{f(sw)}" {extra}/>')

    def line(self, x1, y1, x2, y2, stroke=INK, sw=3, extra=""):
        self.add(f'<line x1="{f(x1)}" y1="{f(y1)}" x2="{f(x2)}" y2="{f(y2)}" '
                 f'stroke="{stroke}" stroke-width="{f(sw)}" stroke-linecap="round" {extra}/>')

    def circle(self, cx, cy, r, fill="none", stroke="none", sw=0, extra=""):
        self.add(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="{fill}" '
                 f'stroke="{stroke}" stroke-width="{f(sw)}" {extra}/>')

    def path(self, d, fill="none", stroke=INK, sw=3, extra=""):
        self.add(f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{f(sw)}" '
                 f'stroke-linejoin="round" stroke-linecap="round" {extra}/>')

    def text(self, x, y, content, size=24, weight=400, fill=INK, anchor="start", extra=""):
        """content: 字串，或 [(字串, {fill, weight, size, dx}), ...]"""
        if isinstance(content, str):
            inner = escape(content)
        else:
            parts = []
            for seg, st in content:
                attrs = []
                if "fill" in st:
                    attrs.append(f'fill="{st["fill"]}"')
                if "weight" in st:
                    attrs.append(f'font-weight="{st["weight"]}"')
                if "size" in st:
                    attrs.append(f'font-size="{st["size"]}"')
                if "dx" in st:
                    attrs.append(f'dx="{st["dx"]}"')
                parts.append(f'<tspan {" ".join(attrs)}>{escape(seg)}</tspan>')
            inner = "".join(parts)
        self.add(f'<text x="{f(x)}" y="{f(y)}" font-size="{size}" font-weight="{weight}" '
                 f'fill="{fill}" text-anchor="{anchor}" {extra}>{inner}</text>')

    def lines(self, x, y, rows, size=24, lh=None, **kw):
        lh = lh or round(size * 1.45)
        for i, r in enumerate(rows):
            xx = x
            if isinstance(r, str) and r.startswith("  "):   # 續行縮排（SVG 會吃掉前導空白）
                xx, r = x + round(size * 1.1), r.strip()
            self.text(xx, y + i * lh, r, size=size, **kw)
        return y + len(rows) * lh

    def render(self):
        head = (f'<?xml version="1.0" encoding="UTF-8"?>\n'
                f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
                f'viewBox="0 0 {self.w} {self.h}" font-family="{FONT}">\n'
                f'<title>{escape(self.title)}</title>\n<desc>{escape(self.desc)}</desc>\n'
                f'<defs>{"".join(self.defs)}</defs>\n'
                f'<rect x="0" y="0" width="{self.w}" height="{self.h}" fill="#ffffff"/>\n')
        return head + "\n".join(self.body) + "\n</svg>\n"


# ---------------------------------------------------------------- 線（導線）
def wire_d(pts, hops=(), r=14):
    """正交折線 → path d；hops 為落在水平段上的跨線點，畫成半圓弧（不相連）。"""
    d = [f"M{f(pts[0][0])},{f(pts[0][1])}"]
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        if abs(y1 - y2) < 1e-6 and hops:
            sgn = 1 if x2 > x1 else -1
            hs = sorted([hx for hx, hy in hops
                         if abs(hy - y1) < 1e-6 and min(x1, x2) + r < hx < max(x1, x2) - r],
                        reverse=(sgn < 0))
            for hx in hs:
                d.append(f"L{f(hx - sgn * r)},{f(y1)}")
                d.append(f"A{r},{r} 0 0 {1 if sgn > 0 else 0} {f(hx + sgn * r)},{f(y1)}")
        d.append(f"L{f(x2)},{f(y2)}")
    return " ".join(d)


def draw_wire(svg, pts, color, net, dashed=False, w=8, casing="#141414", end_dots=True):
    d = wire_d(pts)
    dash = ' stroke-dasharray="20 12"' if dashed else ""
    svg.add(f'<path d="{d}" fill="none" stroke="{casing}" stroke-width="{w + 5}" '
            f'stroke-linecap="round" stroke-linejoin="round"{dash}/>')
    svg.add(f'<path class="wire" data-net="{net}" d="{d}" fill="none" stroke="{color}" '
            f'stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"{dash}/>')
    if end_dots:
        for (x, y) in (pts[0], pts[-1]):
            svg.circle(x, y, 9, fill=color, stroke=casing, sw=3)


def hatch_defs(svg):
    svg.defs.append(
        '<pattern id="hatchAvoid" patternUnits="userSpaceOnUse" width="10" height="10" '
        'patternTransform="rotate(45)"><rect width="10" height="10" fill="#c7ccd1"/>'
        '<rect width="4" height="10" fill="#6c757d"/></pattern>')
    svg.defs.append(
        '<pattern id="hatchKeep" patternUnits="userSpaceOnUse" width="22" height="22" '
        'patternTransform="rotate(45)"><rect width="22" height="22" fill="#fff5f5"/>'
        '<rect width="6" height="22" fill="#ffc9c9"/></pattern>')
    svg.defs.append(
        '<marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" '
        'markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" '
        'fill="#1a1a1a"/></marker>')
    svg.defs.append(
        '<marker id="arrowIR" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" '
        'markerHeight="6" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#7048e8"/></marker>')


# ---------------------------------------------------------------- 麵包板幾何
# SYB-170：17 行（1–17）× 10 排（A–E ｜中溝｜ F–J），無電源排；外形 47 × 35 × 8.5 mm
MM = 22.0                       # 1 mm = 22 px
P = 2.54 * MM                   # 孔距
BB_W, BB_H = 47.0, 35.0
ROWS = "ABCDEFGHIJ"
RIDX = {r: (i if i < 5 else i + 2) for i, r in enumerate(ROWS)}   # E→F 中心距 3 格（7.62 mm）
EDGE_U = (BB_W / 2.54 - 16) / 2          # 第 1／17 行中心到短邊（格）≈ 0.75
EDGE_V = (BB_H / 2.54 - 11) / 2          # A／J 排中心到長邊（格）≈ 1.39
# 視角：照外殼擺法從上往下看——USB-C 朝右，第 1 行在右、第 17 行在左，A 排在上、J 排在下
XR, YT = 1716.0, 470.0                   # u=0（第 0 行位置）的 x；A 排的 y


def X(u):
    return XR - u * P


def Y(v):
    return YT + v * P


def hole(name):
    """'J16' → 孔中心 (x, y)"""
    return (X(int(name[1:])), Y(RIDX[name[0]]))


def pt(u, v):
    return (X(u), Y(v))


# ESP32-C3 SuperMini：18.00 × 22.52 mm，兩排中心距 15.24 mm（6 格），#1 距 USB 端板邊 1.52 mm（估計）
C3_PIN1_EDGE = 1.52 / 2.54
C3_LEN = 22.52 / 2.54
C3_U0 = 1 - C3_PIN1_EDGE                 # USB 端板邊（u）
C3_U1 = C3_U0 + C3_LEN                   # 天線端板邊（u）
C3_V0, C3_V1 = 5 - 9.0 / 2.54, 5 + 9.0 / 2.54
KEEP_U1 = C3_U1 + 8.0 / 2.54             # 天線前方 8 mm

# 板上絲印 #k 在第 k 行：左排（GPIO）插 C 排、右排（電源）插 G 排
LEFT = ["GPIO5", "GPIO6", "GPIO7", "GPIO8", "GPIO9", "GPIO10", "GPIO20", "GPIO21"]
RIGHT = ["5V", "GND", "3V3", "GPIO4", "GPIO3", "GPIO2", "GPIO1", "GPIO0"]
AVOID = {"GPIO8", "GPIO9", "GPIO20", "GPIO21", "GPIO2"}
USED = {"GPIO10": C_IO10, "GND": C_GND, "3V3": C_3V3, "GPIO4": C_SDA, "GPIO3": C_IO3}
C_DHT = C_SDA          # DHT DATA 用藍色
T_DHT = T_SDA

# ---------------------------------------------------------------- 導線（每點都是 (u, v) 格座標）
WIRES = [
    # (net, color, [(u,v)...], 說明)
    ("GPIO10", C_IO10, [(6, 0), (6, -2.1), (14.67, -2.1), (14.67, 3.5), (14, 4)]),
    ("3V3", C_3V3, [(3, 9), (3.5, 9.5), (12.5, 9.5), (12.5, 4.5), (12, 4)]),
    ("GND", C_GND, [(2, 10), (2.5, 10.5), (12.5, 10.5), (13, 10)]),
    ("GND", C_GND, [(13, 7), (13, 4)]),
    ("GND", C_GND, [(13, 8), (13.5, 7.5), (14.5, 7.5), (15, 8)]),
    ("GPIO3", C_IO3, [(5, 11), (5.5, 11.5), (13.5, 11.5), (13.5, 8.5), (16.5, 8.5), (17, 8)]),
]
# DHT11 模組：三條杜邦線從 J2／J3／J4 往下（DHT 艙在 J 排這一側）
DHT_Y = 13.6                    # 模組排針位置（v）


def draw_breadboard(s):
    x0, x1 = X(17 + EDGE_U), X(1 - EDGE_U)
    y0, y1 = Y(-EDGE_V), Y(11 + EDGE_V)
    s.rect(x0, y0, x1 - x0, y1 - y0, fill="#f4f1ea", stroke="#a39e93", sw=3, rx=10)
    # 中溝
    s.rect(x0 + 6, Y(5.5) - 0.9 * MM, x1 - x0 - 12, 1.8 * MM, fill="#e3ded3", rx=4)
    # 行號（上緣內側）與排字（左緣內側）
    for c in range(1, 18):
        if c != 6:          # 第 6 行上緣有紫線經過
            s.text(X(c), Y(-0.92), str(c), size=16, weight=700, fill="#857f73", anchor="middle")
        if c not in (2, 3, 4, 15, 16):   # 下緣有 DHT 線、LED 腳經過
            s.text(X(c), Y(11.95) + 6, str(c), size=16, weight=700, fill="#857f73", anchor="middle")
    for r in ROWS:
        s.text(X(17.47), Y(RIDX[r]) + 6, r, size=16, weight=700, fill="#857f73", anchor="middle")
    # 孔
    for c in range(1, 18):
        for r in ROWS:
            x, y = hole(f"{r}{c}")
            s.rect(x - 7, y - 7, 14, 14, fill="#57534b", rx=2)
    return x0, x1, y0, y1


def draw_c3(s):
    xa, xb = X(C3_U1), X(C3_U0)          # 天線端（左）、USB 端（右）
    ya, yb = Y(C3_V0), Y(C3_V1)
    s.rect(xa, ya, xb - xa, yb - ya, fill="#1f2a36", stroke="#0b0f14", sw=4, rx=12, extra='opacity="0.96"')
    # USB-C（朝右、略凸出板邊）
    uy0, uy1 = Y(5) - 4.5 * MM, Y(5) + 4.5 * MM
    ux1 = xb + 1.3 * MM
    s.rect(ux1 - 7.4 * MM, uy0, 7.4 * MM, uy1 - uy0, fill="#cfd4da", stroke="#6c757d", sw=3, rx=16)
    s.rect(ux1 - 14, uy0 + 22, 8, uy1 - uy0 - 44, fill="#495057", rx=3)
    s.text(ux1 - 3.9 * MM, Y(5) + 7, "USB-C", size=20, weight=700, anchor="middle")
    # 晶片
    cx = X(4.6)
    s.add(f'<rect x="{f(cx - 33)}" y="{f(Y(5) - 33)}" width="66" height="66" rx="5" fill="#343a40" '
          f'stroke="#adb5bd" stroke-width="2" transform="rotate(45 {f(cx)} {f(Y(5))})"/>')
    s.text(cx, Y(5) + 6, "C3", size=17, weight=700, fill="#f1f3f5", anchor="middle")
    # 陶瓷天線（USB 對側＝左端）
    s.rect(xa + 6, Y(5) - 3.3 * MM, 1.9 * MM, 6.6 * MM, fill="#f4a3a3", stroke="#c92a2a", sw=3, rx=4)
    s.text(X(7.15), Y(4.15), "天線", size=17, weight=700, fill="#ffc9c9", anchor="middle")
    s.text(X(7.15), Y(5.85) + 12, "←", size=20, weight=700, fill="#ffc9c9", anchor="middle")
    s.text(cx, Y(3.85), "ESP32-C3 SuperMini", size=17, weight=700, fill="#dee2e6", anchor="middle")
    s.text(cx, Y(6.35), "元件面朝上", size=17, weight=700, fill="#dee2e6", anchor="middle")
    # 16 支腳
    for k in range(1, 9):
        for row, names, dy_name, dy_num in (("C", LEFT, 40, 60), ("G", RIGHT, -46, -26)):
            name = names[k - 1]
            x, y = hole(f"{row}{k}")
            state = "avoid" if name in AVOID else ("used" if name in USED else "spare")
            if state == "avoid":
                s.circle(x, y, 15, fill="url(#hatchAvoid)", stroke="#495057", sw=3)
            else:
                s.circle(x, y, 15, fill="#d4a72c", stroke="#8c6d12", sw=3)
            if name in USED:
                s.circle(x, y, 20, fill="none", stroke=USED[name], sw=5)
            s.circle(x, y, 6, fill="#3b3b3b")
            short = name.replace("GPIO", "IO")
            col = {"used": "#ffffff", "spare": "#d0d7de", "avoid": "#9aa5b1"}[state]
            s.text(x, y + dy_name, short, size=16, weight=700 if state == "used" else 400,
                   fill=col, anchor="middle")
            s.text(x, y + dy_num, f"#{k}", size=16, fill="#8fa3b8", anchor="middle")
    return xa, xb, ya, yb


def resistor_h(s, a, b, label, dashed=False, lab_dy=-16, size=16):
    (x1, y1), (x2, y2) = hole(a), hole(b)
    dash = ' stroke-dasharray="7 5"' if dashed else ""
    s.line(x1, y1, x2, y2, stroke="#868e96", sw=4, extra=dash)
    xm = (x1 + x2) / 2
    s.rect(xm - 17, y1 - 8, 34, 16, fill="#f1e1c6" if not dashed else "#ffffff",
           stroke=INK, sw=2.5, rx=5, extra=dash)
    for i, bc in enumerate(("#c92a2a", "#c92a2a", "#6b3e26") if label.startswith("220") else
                           ("#6b3e26", "#1a1a1a", "#f08c00")):
        s.rect(xm - 10 + i * 7, y1 - 8, 3.5, 16, fill=bc)
    for (x, y) in ((x1, y1), (x2, y2)):
        s.circle(x, y, 5, fill="#868e96")


def lead(s, x1, y1, x2, y2):
    s.line(x1, y1, x2, y2, stroke="#868e96", sw=5)


def make_r3():
    W, H = 2440, 2400
    s = Svg(W, H, "Wi‑Fi 偵測節點 R3 麵包板接線圖",
            "ESP32-C3 SuperMini 跨插 170 孔麵包板，接 DHT11、VS1838B 紅外線接收頭、IR LED（220 Ω 直驅）。")
    hatch_defs(s)
    # ---------------- 標題
    s.text(36, 62, "Wi‑Fi 偵測節點 R3 麵包板接線圖：ESP32‑C3 SuperMini ＋ DHT11 ＋ 紅外線控制日立冷氣（遙控器 RF11T1）",
           size=38, weight=700)
    s.text(36, 108, "全部插在一片 170 孔迷你麵包板上（SYB-170，17 行 × A–J 10 排，沒有電源排），以後不用拔線；"
           "照外殼擺法從上往下看：USB-C 朝右。每條線的端點由程式算到孔中心。", size=22, fill=MUTED)

    # ---------------- 麵包板 + C3
    bx0, bx1, by0, by1 = draw_breadboard(s)
    # 天線淨空區（板子寬度 × 天線前方 8 mm）
    kx0, kx1 = X(KEEP_U1), X(C3_U1)
    s.rect(kx0, Y(C3_V0), kx1 - kx0, Y(C3_V1) - Y(C3_V0), fill="url(#hatchKeep)",
           stroke="#e03131", sw=3, rx=6, extra='opacity="0.82" stroke-dasharray="10 6"')
    s.text((kx0 + kx1) / 2, Y(5.5) - 20, "天線淨空", size=18, weight=700, fill="#a61e1e", anchor="middle")
    s.text((kx0 + kx1) / 2, Y(5.5) + 6, "前方 8 mm", size=17, weight=700, fill="#a61e1e", anchor="middle")
    s.text((kx0 + kx1) / 2, Y(5.5) + 30, "不放零件", size=17, weight=700, fill="#a61e1e", anchor="middle")
    draw_c3(s)

    # ---------------- 被動元件（畫在線下面）
    resistor_h(s, "H17", "H16", "220")
    resistor_h(s, "I17", "I16", "220", dashed=True)
    resistor_h(s, "D14", "D12", "10k", dashed=True)

    # ---------------- 導線
    for net, color, pts in WIRES:
        draw_wire(s, [pt(*p) for p in pts], color, net, w=8)
    # DHT11 三條杜邦線（直下到模組）
    dht = [("J4", C_DHT, "GPIO4", "S"), ("J3", C_3V3, "3V3", "VCC"), ("J2", C_GND, "GND", "GND")]
    for hn, colr, net, _ in dht:
        x, y = hole(hn)
        draw_wire(s, [(x, y), (x, Y(DHT_Y))], colr, net, w=8)

    # ---------------- DHT11 模組（DHT 艙，J 排外側）
    mx0, mx1 = X(4.85), X(1.15)
    my0 = Y(DHT_Y) + 6
    s.rect(mx0, my0, mx1 - mx0, 190, fill="#1864ab", stroke="#0b3d6e", sw=3, rx=10)
    s.rect(mx0 + 30, my0 + 66, mx1 - mx0 - 60, 110, fill="#4dabf7", stroke="#1c7ed6", sw=3, rx=8)
    for i in range(4):
        s.line(mx0 + 44, my0 + 86 + i * 24, mx1 - 44, my0 + 86 + i * 24, stroke="#1c7ed6", sw=3)
    for hn, colr, net, lab in dht:
        x, _ = hole(hn)
        s.rect(x - 12, my0 - 4, 24, 20, fill="#212529", rx=3)
        s.text(x, my0 + 44, lab, size=17, weight=700, fill="#ffffff", anchor="middle")
    s.text((mx0 + mx1) / 2, my0 + 222, "DHT11 三腳模組（杜邦線）", size=20, weight=700, anchor="middle")
    s.text((mx0 + mx1) / 2, my0 + 250, "腳序各家不同，照絲印接", size=17, fill=MUTED, anchor="middle")

    # ---------------- IR LED（J15 陰極、J16 陽極，腳彎 90° 頭朝外）
    (xk, yk), (xa_, ya_) = hole("J15"), hole("J16")
    ly = by1 + 34
    lead(s, xk, yk, xk, ly)
    lead(s, xa_, ya_, xa_, ly)
    lcx = (xk + xa_) / 2
    s.rect(lcx - 50, ly, 100, 22, fill="#b197fc", stroke="#5f3dc4", sw=3, rx=4)
    s.path(f"M{f(lcx - 44)},{f(ly + 22)} L{f(lcx - 44)},{f(ly + 66)} A44,44 0 0 0 {f(lcx + 44)},{f(ly + 66)} "
           f"L{f(lcx + 44)},{f(ly + 22)} Z", fill="#d0bfff", stroke="#5f3dc4", sw=3)
    for dx in (-30, 0, 30):
        s.line(lcx + dx, ly + 124, lcx + dx * 1.6, ly + 178, stroke="#7048e8", sw=4,
               extra='marker-end="url(#arrowIR)"')
    s.text(lcx, ly + 214, "IR LED 5 mm（940 nm）", size=19, weight=700, anchor="middle")
    s.text(lcx, ly + 240, "腳彎 90°，頭朝外殼 IR 窗", size=17, fill=MUTED, anchor="middle")
    # LED 腳名標在兩側
    s.text(xa_ - 56, ly + 50, "＋陽極（長腳）", size=16, weight=700, fill="#c2410c", anchor="end")
    s.text(xa_ - 56, ly + 72, "插 J16", size=16, weight=700, fill="#c2410c", anchor="end")
    s.text(xk + 56, ly + 50, "－陰極（短腳）", size=16, weight=700, fill=INK)
    s.text(xk + 56, ly + 72, "插 J15", size=16, weight=700, fill=INK)

    # ---------------- VS1838B（C12 VCC、C13 GND、C14 OUT；平躺、鏡頭朝上蓋）
    (x12, yc), (x13, _), (x14, _) = hole("C12"), hole("C13"), hole("C14")
    rb0, rb1 = Y(-1.12), Y(1.62)
    for xx in (x12, x13, x14):
        lead(s, xx, yc, xx, rb1)
    s.rect(X(14.33), rb0, X(11.67) - X(14.33), rb1 - rb0, fill="#343a40", stroke="#111", sw=3, rx=10)
    s.circle(x13, rb0 + 50, 30, fill="#495057", stroke="#adb5bd", sw=3)
    s.text(x13, rb0 + 56, "鏡頭", size=16, weight=700, fill="#f1f3f5", anchor="middle")
    for xx, lab in ((x14, "OUT"), (x13, "GND"), (x12, "VCC")):
        s.text(xx, rb1 - 14, lab, size=16, weight=700, fill="#ffffff", anchor="middle")

    # ---------------- 孔位標籤（只標有用到的孔）
    LM = X(17 + EDGE_U) - 14            # 板子左外側
    RM = X(1 - EDGE_U) + 14             # 板子右外側
    tags = [
        ("A6", hole("A6")[0] - 14, hole("A6")[1] + 30, "end", T_IO10),
        ("J4", hole("J4")[0] + 13, Y(12.3) + 4, "start", T_DHT),
        ("J3", hole("J3")[0] + 13, Y(12.3) + 4, "start", T_3V3),
        ("J2", hole("J2")[0] + 13, Y(12.3) + 4, "start", INK),
    ]
    for t, x, y, anc, colr in tags:
        s.text(x, y, t, size=16, weight=700, fill=colr, anchor=anc)
    left = [
        (-0.15, [("VS1838B：平躺、鏡頭朝上蓋", {"weight": 700})]),
        (0.75, [("C14 OUT", {"fill": T_IO10, "weight": 700}), ("、C13 GND、", {}),
                ("C12 VCC", {"fill": T_3V3, "weight": 700})]),
        (1.6, [("（腳序以實物為準）", {"fill": MUTED})]),
        (3, [("D12–D14：10 kΩ 上拉（選配）", {"fill": MUTED})]),
        (4, [("E14", {"fill": T_IO10, "weight": 700}), ("、E13、", {"weight": 700}),
             ("E12", {"fill": T_3V3, "weight": 700})]),
        (7, [("F13", {"weight": 700}), ("（短線跨溝接 E13）", {})]),
        (8, [("G17", {"fill": T_IO3, "weight": 700}), ("、G15、G13", {"weight": 700})]),
        (9, [("H16–H17：220 Ω（直驅）", {"weight": 700})]),
        (10, [("I16–I17：220 Ω 並聯（選配）", {"fill": MUTED}), ("、I13", {"weight": 700})]),
        (11, [("J16＝LED 陽極、J15＝陰極", {"weight": 700})]),
    ]
    for v, txt in left:
        s.text(LM, Y(v) + 6, txt, size=17, anchor="end")
    right = [
        (9, [("H3", {"fill": T_3V3, "weight": 700}), ("：3V3 → E12", {})]),
        (10, [("I2", {"weight": 700}), ("：GND → I13", {})]),
        (11, [("J5", {"fill": T_IO3, "weight": 700}), ("：GPIO3 → G17", {})]),
    ]
    for v, txt in right:
        s.text(RM, Y(v) + 6, txt, size=17)

    # ---------------- 線的文字（R2 風格）
    s.text(X(10.3), Y(-2.1) - 16, [("紫：GPIO10（左排 #6，A6）", {"fill": T_IO10, "weight": 700}),
                                     ("→ 外緣繞過 → E14 → 接收頭 OUT（C14）", {})], size=20, anchor="middle")
    # 右側：USB
    s.text(X(-0.45) + 24, Y(5) - 54, "USB-C → 朝右", size=22, weight=700)
    s.text(X(-0.45) + 24, Y(5) - 24, "（外殼 USB 開口）", size=18, fill=MUTED)

    # ---------------- 左側：怎麼看
    s.rect(28, 170, 352, 660, fill="#f8f9fa", stroke="#ced4da", sw=2, rx=12)
    s.text(48, 210, "怎麼看這張圖", size=24, weight=700)
    s.lines(48, 254, [
        "• 照外殼擺法從上往下看：",
        "  USB-C 朝右，第 1 行在右",
        "• 行號 1–17、排 A–J 照板上絲印",
        "• 同一行 A–E 五孔相通、F–J",
        "  五孔相通；中溝兩邊不通",
        "• 沒有電源排：C3 的 G2＝GND、",
        "  G3＝3V3，由那一行分出去",
        "• C3 跨中溝：左排插 C1–C8、",
        "  右排插 G1–G8（#1 在 USB 端）",
        "• 灰斜線腳＝避開，金色＝可用",
        "• 虛線元件＝選配",
        "• 線色只是建議，孔位才是重點",
    ], size=19, lh=46)

    # ---------------- 右側：圖例 + 匯流
    rx = 1990
    s.rect(rx, 170, 422, 330, fill="#f8f9fa", stroke="#ced4da", sw=2, rx=12)
    s.text(rx + 20, 210, "腳位圖例", size=24, weight=700)
    yy = 256
    for state, lab in (("used", "已使用（外圈＝線色）"), ("avoid", "避開：strapping／LED／BOOT／UART0"),
                       ("spare", "未使用（保留）")):
        cx_, cy_ = rx + 40, yy - 6
        if state == "avoid":
            s.circle(cx_, cy_, 15, fill="url(#hatchAvoid)", stroke="#495057", sw=3)
        else:
            s.circle(cx_, cy_, 15, fill="#d4a72c", stroke="#8c6d12", sw=3)
        if state == "used":
            s.circle(cx_, cy_, 20, fill="none", stroke=C_IO3, sw=5)
        s.circle(cx_, cy_, 6, fill="#3b3b3b")
        s.text(rx + 72, yy, lab, size=18)
        yy += 52
    s.rect(rx + 30, yy - 18, 14, 14, fill="#57534b", rx=2)
    s.text(rx + 72, yy - 4, "麵包板孔（線端圓點＝孔中心）", size=18)
    s.rect(rx + 22, yy + 26, 30, 22, fill="url(#hatchKeep)", stroke="#e03131", sw=2)
    s.text(rx + 72, yy + 44, "天線淨空：前方 8 mm 不放零件", size=18)

    s.rect(rx, 520, 422, 420, fill="#fff9db", stroke="#f2c94c", sw=2, rx=12)
    s.text(rx + 20, 560, "哪一行當電源線用", size=24, weight=700)
    s.lines(rx + 20, 604, [
        [("第 2 行下半（G2–J2）＝ ", {}), ("GND", {"weight": 700})],
        "  H2 空、I2→I13、J2→DHT",
        [("第 3 行下半＝ ", {}), ("3V3", {"fill": T_3V3, "weight": 700})],
        "  H3→E12、J3→DHT、I3 空",
        [("第 13 行上下兩半＝ ", {}), ("GND", {"weight": 700})],
        "  F13–E13 跨溝短線接通",
        [("第 15 行下半＝ ", {}), ("GND", {"weight": 700}), ("（LED 陰極）", {})],
        [("第 12 行上半＝ ", {}), ("3V3", {"fill": T_3V3, "weight": 700}), ("（接收頭）", {})],
    ], size=18, lh=40)

    # ---------------- 下方三格
    by = 1540
    s.rect(28, by, 900, 820, fill="#f8f9fa", stroke="#ced4da", sw=2, rx=12)
    s.text(50, by + 44, "接線對照（孔位 → 孔位；線色只是建議）", size=24, weight=700)
    rows = [
        (C_GND, [("GND", {"weight": 700}), ("：DHT 黑線 J2；I2 → I13；F13 → E13；G13 → G15", {})]),
        (C_3V3, [("3V3", {"fill": T_3V3, "weight": 700}), ("：DHT 紅線 J3；H3 → E12（接收頭 VCC 那一行）", {})]),
        (C_DHT, [("GPIO4", {"fill": T_DHT, "weight": 700}), ("：DHT 的 S／DATA 線 → J4", {})]),
        (C_IO3, [("GPIO3", {"fill": T_IO3, "weight": 700}), ("：J5 → G17 → 220 Ω（H17–H16）→ LED 陽極 J16", {})]),
        (C_IO10, [("GPIO10", {"fill": T_IO10, "weight": 700}), ("：A6 → E14（接收頭 OUT 那一行）", {})]),
    ]
    for i, (colr, txt) in enumerate(rows):
        y_ = by + 100 + i * 52
        draw_wire(s, [(56, y_ - 7), (120, y_ - 7)], colr, "legend", end_dots=False)
        s.text(140, y_, txt, size=19)
    s.lines(50, by + 384, [
        "零件腳（直接插板）",
        "• C3：左排 C1–C8、右排 G1–G8（#1 在第 1 行、USB 端）",
        "• VS1838B：C12＝VCC、C13＝GND、C14＝OUT（平躺、腳朝中溝；",
        "  腳序以實物為準，常見正面腳朝下由左到右 OUT、GND、VCC）",
        "• IR LED：陽極（長腳）J16、陰極（短腳／平邊）J15",
        "• 220 Ω：H16–H17（直驅約 9 mA，約 1 m）",
        "• 選配：第二顆 220 Ω 插 I16–I17 並聯（約 18 mA，最多兩顆）",
        "• 選配：10 kΩ 插 D12–D14，當接收頭 OUT 的上拉",
        "• 1 kΩ 現在用不到，留給電晶體升級版",
    ], size=19, lh=44)

    # NPN 升級（示意電路，不是導線）
    nx = 950
    s.rect(nx, by, 700, 820, fill="#f8f9fa", stroke="#ced4da", sw=2, rx=12)
    s.text(nx + 22, by + 44, "之後升級：NPN 電晶體版（距離較遠）", size=24, weight=700)
    s.text(nx + 22, by + 80, "S8050 或 2N2222 ", size=19, weight=700)
    s.rect(nx + 196, by + 60, 92, 30, fill="#ffe3e3", stroke="#e03131", sw=2, rx=6)
    s.text(nx + 242, by + 81, "需補料", size=18, weight=700, fill="#c92a2a", anchor="middle")
    s.text(nx + 302, by + 80, "；韌體不用改", size=19, fill=MUTED)
    # 電路
    gx = nx + 230
    s.text(gx, by + 136, "5V（右排 #1，G1 那一行）", size=19, weight=700, fill=T_5V, anchor="middle")
    s.line(gx, by + 148, gx, by + 172, stroke=C_5V, sw=5)
    s.line(gx - 60, by + 172, gx + 60, by + 172, stroke=C_5V, sw=5)
    for dx in (-60, 0, 60):
        s.line(gx + dx, by + 172, gx + dx, by + 196, stroke=INK, sw=4)
        s.rect(gx + dx - 13, by + 196, 26, 60, fill="#ffffff", stroke=INK, sw=3, rx=3)
        s.line(gx + dx, by + 256, gx + dx, by + 280, stroke=INK, sw=4)
    s.line(gx - 60, by + 280, gx + 60, by + 280, stroke=INK, sw=4)
    s.text(gx + 84, by + 224, "3 × 220 Ω 並聯", size=18, weight=700)
    s.text(gx + 84, by + 248, "（≈ 73 Ω）", size=18, fill=MUTED)
    s.line(gx, by + 280, gx, by + 310, stroke=INK, sw=4)
    s.path(f"M{gx - 26},{by + 310} L{gx + 26},{by + 310} L{gx},{by + 350} Z", fill="#d0bfff", stroke=INK, sw=3)
    s.line(gx - 26, by + 352, gx + 26, by + 352, stroke=INK, sw=4)
    s.text(gx + 84, by + 338, "IR LED（陽極在上）", size=18, weight=700)
    s.line(gx, by + 352, gx, by + 410, stroke=INK, sw=4)
    s.text(gx + 14, by + 400, "C", size=18, weight=700)
    # 電晶體
    s.circle(gx - 10, by + 450, 46, fill="#ffffff", stroke=INK, sw=3)
    s.line(gx - 30, by + 420, gx - 30, by + 480, stroke=INK, sw=5)
    s.line(gx - 30, by + 438, gx, by + 410, stroke=INK, sw=4)
    s.line(gx - 30, by + 462, gx, by + 490, stroke=INK, sw=4)
    s.line(gx, by + 490, gx, by + 540, stroke=INK, sw=4)
    s.text(gx + 14, by + 512, "E", size=18, weight=700)
    s.text(gx, by + 566, "GND", size=19, weight=700, anchor="middle")
    s.line(gx - 30, by + 450, gx - 90, by + 450, stroke=INK, sw=4)
    s.text(gx - 48, by + 440, "B", size=18, weight=700, anchor="middle")
    s.rect(gx - 160, by + 438, 70, 24, fill="#ffffff", stroke=INK, sw=3, rx=3)
    s.text(gx - 125, by + 425, "1 kΩ", size=18, weight=700, anchor="middle")
    s.line(gx - 160, by + 450, gx - 190, by + 450, stroke=C_IO3, sw=5)
    s.text(gx - 196, by + 457, "GPIO3", size=19, weight=700, fill=T_IO3, anchor="end")
    s.text(gx + 60, by + 456, "NPN（TO-92）", size=18, weight=700)
    s.text(gx + 60, by + 480, "E／B／C 腳序依廠牌", size=17, fill=MUTED)
    s.lines(nx + 22, by + 620, [
        "• LED 約 45–50 mA，比直驅（約 9 mA）遠很多",
        "• 建議另加 10 kΩ 接在 B 與 E 之間（手上有）",
        "• LM337LZ 長得像電晶體，但是穩壓 IC，不能代用",
        "• 補料到貨後再排孔位；現在的直驅線路不用動",
    ], size=18, lh=42)

    # 注意
    zx = 1672
    s.rect(zx, by, 740, 820, fill="#fff9db", stroke="#f2c94c", sw=2, rx=12)
    s.text(zx + 22, by + 44, "注意事項", size=24, weight=700)
    s.lines(zx + 22, by + 96, [
        [("• DHT11 的 VCC 接 ", {}), ("3V3（J3）", {"fill": T_3V3, "weight": 700}), ("，不要接 5V", {})],
        "  模組上拉接在 VCC，接 5V 會把 5V 灌進 GPIO",
        "• 第 1 行下半（H1–J1）是 5V：不要插任何東西",
        "• 先拔 USB 再插線、改線",
        "• C3 兩排距 6 格（15.24 mm）：C 排與 G 排",
        "• 接收頭只接 3V3，OUT 才不會超過 3.3 V",
        "• LED 長腳＝陽極（J16）；插反只是不亮，不會壞",
        "• LED 與接收頭方向不同（側窗 vs 上蓋），",
        "  減少自己發的訊號被自己收到",
        "• 天線端（左邊紅框）不放零件；第 12 行在",
        "  8 mm 邊界上，接收頭是外殼定稿位置",
        "• 麵包板：SYB-170，約 47 × 35 × 8.5 mm",
        "  （孔距 2.54 mm；尺寸到貨再量）",
        "• 板上字樣若左右相反，見 PINMAP_R3.md",
    ], size=18, lh=44)

    s.text(W - 36, H - 16, "板圖自繪，CC0-1.0", size=18, fill=MUTED, anchor="end")
    return s


def main():
    svg = make_r3()
    out = OUT_DIR / "wiring_r3_breadboard.svg"
    out.write_text(svg.render(), encoding="utf-8")
    print(f"wrote {out.name} ({svg.w}x{svg.h})")


if __name__ == "__main__":
    main()
