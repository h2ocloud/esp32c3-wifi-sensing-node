#!/usr/bin/env python3
# SPDX-License-Identifier: CC0-1.0
"""產生 wiring/ 底下的三張 SVG（只用 Python 標準函式庫）。

    python3 src/make_wiring.py

輸出（寫到本檔上一層的 wiring/）：
    wiring_main.svg       接線總圖：ESP32-C3 SuperMini + AHT20/BMP280 + IR 發射/接收
    wiring_ir.svg         紅外線電路放大圖（簡化原理圖 + 零件腳位 + 計算）
    wiring_checklist.svg  接線檢查清單

板圖、模組圖、零件圖全部在這支程式裡自己畫（不使用任何第三方板圖或零件庫），
以 CC0-1.0 釋出。ESP32-C3 SuperMini 的腳位座標由板子幾何算出，
所有接到板子的線，端點都直接取自 pin_xy()，保證落在腳位中心。
"""
from pathlib import Path
from xml.sax.saxutils import escape

OUT_DIR = Path(__file__).resolve().parent.parent

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


# ---------------------------------------------------------------- 板子幾何
MM = 40.0                       # 1 mm = 40 px（SVG 單位 = PNG 像素）
BX, BY = 640.0, 520.0           # 板子左上角
BW, BH = 18.00 * MM, 22.52 * MM  # PCB 18.00 x 22.52 mm
ROW_SPACING = 15.24             # 兩排中心距 mm
PITCH = 2.54 * MM
PIN1_FROM_TOP = 1.52            # 第 1 腳中心距 USB 端板邊（估計）mm
COL_L = BX + (18.00 - ROW_SPACING) / 2 * MM
COL_R = BX + (18.00 + ROW_SPACING) / 2 * MM
PAD_R = 0.9 * MM
HOLE_R = 0.5 * MM


def pin_xy(side, k):
    """side: 'L' 左排 / 'R' 右排（元件面朝上、USB-C 朝上看）；k: 1..8，#1 在 USB 端。"""
    x = COL_L if side == "L" else COL_R
    return (x, BY + (PIN1_FROM_TOP + (k - 1) * 2.54) * MM)


# 腳名（Nologo 原理圖 H1/H2、尺寸圖絲印；espboards 腳位圖交叉核對）
PINS = {
    ("L", 1): ("GPIO5", "used"), ("L", 2): ("GPIO6", "spare"), ("L", 3): ("GPIO7", "spare"),
    ("L", 4): ("GPIO8", "avoid"), ("L", 5): ("GPIO9", "avoid"), ("L", 6): ("GPIO10", "used"),
    ("L", 7): ("GPIO20 RX", "avoid"), ("L", 8): ("GPIO21 TX", "avoid"),
    ("R", 1): ("5V", "used"), ("R", 2): ("GND", "used"), ("R", 3): ("3V3", "used"),
    ("R", 4): ("GPIO4", "used"), ("R", 5): ("GPIO3", "used"), ("R", 6): ("GPIO2", "avoid"),
    ("R", 7): ("GPIO1", "spare"), ("R", 8): ("GPIO0", "spare"),
}
USED_RING = {("L", 1): C_SCL, ("L", 6): C_IO10, ("R", 1): C_5V, ("R", 2): C_GND,
             ("R", 3): C_3V3, ("R", 4): C_SDA, ("R", 5): C_IO3}


def draw_pad(svg, x, y, state, ring=None, k=1.0):
    if state == "avoid":
        svg.circle(x, y, PAD_R * k, fill="url(#hatchAvoid)", stroke="#495057", sw=3)
    else:
        svg.circle(x, y, PAD_R * k, fill="#d4a72c", stroke="#8c6d12", sw=3)
    if ring:
        svg.circle(x, y, PAD_R * k + 5, fill="none", stroke=ring, sw=5)
    svg.circle(x, y, HOLE_R * k, fill="#3b3b3b")


def draw_c3_board(svg):
    # PCB
    svg.rect(BX, BY, BW, BH, fill="#1f2a36", stroke="#0b0f14", sw=4, rx=14)
    cx = BX + BW / 2
    # USB-C（示意寬度，朝上、凸出板邊）
    uw, top, bot = 256, BY - 64, BY + 230
    svg.rect(cx - uw / 2, top, uw, bot - top, fill="#cfd4da", stroke="#6c757d", sw=3, rx=20)
    svg.rect(cx - uw / 2 + 30, top + 14, uw - 60, 34, fill="#495057", rx=12)
    svg.text(cx, top + 118, "USB-C", size=30, weight=700, anchor="middle")
    svg.text(cx, top + 160, "↑ 朝上", size=26, weight=700, anchor="middle")
    # 按鍵（示意）
    for bx, lab in ((cx - 100, "BOOT"), (cx + 20, "RST")):
        svg.rect(bx, BY + 285, 80, 70, fill="#e9ecef", stroke="#868e96", sw=2, rx=8)
        svg.circle(bx + 40, BY + 320, 18, fill="#495057")
        svg.text(bx + 40, BY + 386, lab, size=22, weight=700, fill="#e9ecef", anchor="middle")
    # 晶片（示意）
    svg.add(f'<rect x="{f(cx - 62)}" y="{f(BY + 460)}" width="124" height="124" rx="6" '
            f'fill="#343a40" stroke="#adb5bd" stroke-width="2" '
            f'transform="rotate(45 {f(cx)} {f(BY + 522)})"/>')
    svg.text(cx, BY + 530, "ESP32-C3", size=22, weight=700, fill="#f1f3f5", anchor="middle")
    svg.text(cx, BY + 640, "元件面朝上", size=22, weight=700, fill="#dee2e6", anchor="middle")
    # 陶瓷天線（USB 對側短邊）
    ax0, ax1 = BX + 5.9 * MM, BX + 12.5 * MM
    svg.rect(ax0, BY + 20.3 * MM, ax1 - ax0, 2.0 * MM, fill="#f4a3a3", stroke="#c92a2a", sw=3, rx=4)
    svg.text((ax0 + ax1) / 2, BY + 21.3 * MM + 8, "陶瓷天線", size=22, weight=700, anchor="middle")
    # 16 支腳
    for (side, k), (name, state) in PINS.items():
        x, y = pin_xy(side, k)
        draw_pad(svg, x, y, state, USED_RING.get((side, k)))
        name_fill = {"used": "#ffffff", "spare": "#d0d7de", "avoid": "#9aa5b1"}[state]
        weight = 700 if state == "used" else 400
        num = ("#%d" % k, {"fill": "#8fa3b8", "size": 22})
        if side == "L":
            svg.text(x + PAD_R + 10, y + 8,
                     [num, (name, {"fill": name_fill, "weight": weight, "dx": 8})], size=24)
        else:
            svg.text(x - PAD_R - 10, y + 8,
                     [(name, {"fill": name_fill, "weight": weight}), (num[0], dict(num[1], dx=8))],
                     size=24, anchor="end")
    # 欄名
    svg.text(COL_L, BY - 16, "左排", size=24, weight=700, anchor="middle")
    svg.text(COL_R, BY - 16, "右排", size=24, weight=700, anchor="middle")


# ---------------------------------------------------------------- 主圖
def make_main():
    W, H = 3000, 2400
    s = Svg(W, H, "Wi-Fi 偵測節點接線總圖",
            "ESP32-C3 SuperMini（元件面朝上、USB-C 朝上）接 AHT20+BMP280 I2C 模組、"
            "IR 發射（GPIO3 經 NPN 驅動 940 nm LED，5V 供電）與 IR 接收頭（必備，GPIO10），用於紅外線控制日立（Hitachi）冷氣（遙控器 RF11T1）。"
            "板圖自繪，CC0-1.0。")
    hatch_defs(s)
    s.text(40, 66, "Wi-Fi 偵測節點接線總圖：ESP32-C3 SuperMini ＋ AHT20/BMP280 ＋ 紅外線控制日立冷氣（遙控器 RF11T1）",
           size=40, weight=700)
    s.text(40, 112, "元件面朝上、USB-C 朝上看；每條線的端點由程式算到腳位中心。"
           "分接／IR 驅動小板的內部電路見 wiring_ir.svg。", size=26, fill=MUTED)

    draw_c3_board(s)
    s.text(BX, 410, "ESP32-C3 SuperMini", size=30, weight=700)

    # 天線淨空區（板子下方約 8 mm）
    kx0, kx1, ky0 = BX - 40, BX + BW + 40, BY + BH
    ky1 = ky0 + 8 * MM
    s.rect(kx0, ky0, kx1 - kx0, ky1 - ky0, fill="url(#hatchKeep)", stroke="#c92a2a", sw=3,
           extra='stroke-dasharray="14 10"')
    s.rect(kx0 + 70, ky0 + 66, kx1 - kx0 - 140, 190, fill="#ffffff", stroke="#c92a2a", sw=2, rx=12,
           extra='fill-opacity="0.92"')
    s.text((kx0 + kx1) / 2, ky0 + 120, "↓ 天線端：保持淨空", size=34, weight=700, fill="#a61e1e",
           anchor="middle")
    s.text((kx0 + kx1) / 2, ky0 + 170, "天線前方約 8 mm 內不放線、不放金屬", size=26,
           anchor="middle")
    s.text((kx0 + kx1) / 2, ky0 + 214, "（斜線區高度＝8 mm，依板圖比例）", size=22,
           fill=MUTED, anchor="middle")

    # ---- 分接／IR 驅動小板 P
    PX0, PX1, PY0, PY1 = 1460.0, 2080.0, 520.0, 1420.0
    s.rect(PX0, PY0, PX1 - PX0, PY1 - PY0, fill="#f6f1e3", stroke="#8a7b55", sw=3, rx=16)
    pmid = (PX0 + PX1) / 2
    s.text(pmid + 30, 566, "分接／IR 驅動小板", size=28, weight=700, anchor="middle")
    s.text(pmid + 30, 600, "（洞洞板）", size=22, fill=MUTED, anchor="middle")

    left_terms = [("R", 1, "5V", C_5V, T_5V), ("R", 2, "GND", C_GND, T_GND),
                  ("R", 3, "3V3", C_3V3, T_3V3), ("R", 4, "SDA", C_SDA, T_SDA),
                  ("R", 5, "GPIO3", C_IO3, T_IO3)]
    for side, k, lab, col, tcol in left_terms:
        x0, y0 = pin_xy(side, k)
        draw_wire(s, [(x0, y0), (PX0, y0)], col, lab)
        s.text(PX0 + 22, y0 + 8, lab, size=24, weight=700, fill=tcol)

    # 右側端子
    SENS = {"SCL": 600.0, "GND": 680.0, "SDA": 760.0, "VDD": 840.0}
    RX = {"OUT": 1010.0, "GND": 1070.0, "VCC": 1130.0}
    LED_A, LED_K = 1250.0, 1310.0
    right_terms = [(SENS["GND"], "GND", T_GND), (SENS["SDA"], "SDA", T_SDA),
                   (SENS["VDD"], "3V3", T_3V3), (RX["GND"], "GND", T_GND),
                   (RX["VCC"], "3V3", T_3V3), (LED_A, "LED+", T_5V), (LED_K, "LED−", INK)]
    for y, lab, tcol in right_terms:
        s.text(PX1 - 22, y + 8, lab, size=24, weight=700, fill=tcol, anchor="end")

    # 板內接法（同名端子相連）
    tx = PX0 + 130
    s.text(tx, 690, "板內接法（同名端子相連）", size=24, weight=700)
    s.lines(tx, 740, [
        [("GND", {"fill": T_GND, "weight": 700}), (" → 感測、接收、Q 的 E", {})],
        [("3V3", {"fill": T_3V3, "weight": 700}), (" → 感測 VDD、接收 VCC", {})],
        [("SDA", {"fill": T_SDA, "weight": 700}), (" → 感測 SDA", {})],
        [("5V", {"fill": T_5V, "weight": 700}), (" → 33 Ω → LED+", {})],
        [("LED−", {"weight": 700}), (" → Q 的 C（集極）", {})],
        [("GPIO3", {"fill": T_IO3, "weight": 700}), (" → 1 kΩ → Q 的 B", {})],
        "（建議）10 kΩ 接在 B 與 E 之間",
    ], size=22, lh=44)
    s.lines(tx, 1072, ["Q1：S8050 或 2N2222（TO-92）", "33 Ω 1/4 W、1 kΩ", "電路圖見 wiring_ir.svg"],
            size=22, lh=40, fill=MUTED)

    # ---- AHT20+BMP280 模組 S（示意，轉 180° 擺放）
    SX0, SX1, SY0, SY1 = 2240.0, 2580.0, 540.0, 930.0
    SPX = 2275.0
    s.text(SX0, 520, "AHT20+BMP280 二合一模組", size=24, weight=700)
    s.rect(SX0, SY0, SX1 - SX0, SY1 - SY0, fill="#2f3d8f", stroke="#18215a", sw=3, rx=14)
    for name, y in SENS.items():
        s.circle(SPX, y, 17, fill="#d4a72c", stroke="#8c6d12", sw=3)
        s.circle(SPX, y, 8, fill="#3b3b3b")
        s.text(SPX + 32, y + 9, name, size=26, weight=700, fill="#ffffff")
    s.rect(2430, 580, 100, 90, fill="#e9ecef", stroke="#adb5bd", sw=2, rx=6)
    s.text(2480, 633, "AHT20", size=22, weight=700, anchor="middle")
    s.text(2480, 708, "0x38", size=22, weight=700, fill="#ffffff", anchor="middle")
    s.rect(2415, 745, 130, 70, fill="#adb5bd", stroke="#868e96", sw=2, rx=6)
    s.text(2480, 789, "BMP280", size=22, weight=700, anchor="middle")
    s.text(2480, 852, "0x77／0x76", size=22, weight=700, fill="#ffffff", anchor="middle")
    s.text(SX0 + 20, 908, "腳序以實物絲印為準", size=22, fill="#e7ebff")

    for name, col, net in (("GND", C_GND, "GND"), ("SDA", C_SDA, "SDA"), ("VDD", C_3V3, "3V3")):
        y = SENS[name]
        draw_wire(s, [(PX1, y), (SPX, y)], col, net)

    # SCL：左排 #1 → 越過板子上方 → 感測板 SCL
    l1 = pin_xy("L", 1)
    draw_wire(s, [l1, (560, l1[1]), (560, 330), (2160, 330), (2160, SENS["SCL"]),
                  (SPX, SENS["SCL"])], C_SCL, "SCL")
    s.text(1560, 316, [("黃：", {"fill": T_SCL, "weight": 700}),
                       ("GPIO5（左排 #1）→ 感測板 SCL", {})], size=24)

    # ---- IR 接收頭（必備，轉 90° 擺放：腳朝左，由上而下 OUT/GND/VCC）
    RXT, RXB0, RXB1 = 2275.0, 2350.0, 2440.0
    for name, y in RX.items():
        s.line(RXT, y, RXB0, y, stroke="#868e96", sw=6)
    s.rect(RXB0, 975, RXB1 - RXB0, 190, fill="#343a40", stroke="#1a1a1a", sw=3, rx=12)
    s.circle((RXB0 + RXB1) / 2, 1070, 30, fill="#6c757d")
    for name, y in RX.items():
        s.text(RXB1 + 18, y + 8, name, size=24, weight=700,
               fill=T_IO10 if name == "OUT" else (T_3V3 if name == "VCC" else INK))
    s.text(2590, 1000, "IR 接收頭（必備）", size=24, weight=700)
    s.lines(2590, 1036, ["VS1838B，38 kHz；錄遙控碼用", "腳序以實物為準", "避開陽光／日光燈直射",
                         "離 IR LED 遠一點或加遮擋"], size=22, lh=34)
    draw_wire(s, [(PX1, RX["GND"]), (RXT, RX["GND"])], C_GND, "GND")
    draw_wire(s, [(PX1, RX["VCC"]), (RXT, RX["VCC"])], C_3V3, "3V3")

    # GPIO10：左排 #6 → 越過上方（最外圈）→ 接收頭 OUT
    l6 = pin_xy("L", 6)
    draw_wire(s, [l6, (500, l6[1]), (500, 250), (2700, 250), (2700, 950), (2170, 950),
                  (2170, RX["OUT"]), (RXT, RX["OUT"])], C_IO10, "GPIO10")
    s.text(1560, 236, [("紫：", {"fill": T_IO10, "weight": 700}),
                       ("GPIO10（左排 #6）→ 接收頭 OUT", {})], size=24)

    # ---- IR LED（940 nm 5 mm，腳朝 P）
    lb = 2200.0
    s.line(PX1, LED_A, lb + 4, LED_A, stroke="#868e96", sw=6)
    s.line(PX1, LED_K, lb + 4, LED_K, stroke="#868e96", sw=6)
    s.circle(PX1, LED_A, 9, fill="#c9a227", stroke="#6b5a1e", sw=3)
    s.circle(PX1, LED_K, 9, fill="#c9a227", stroke="#6b5a1e", sw=3)
    s.path(f"M{lb},1224 L{lb + 22},1224 L{lb + 22},1336 L{lb},1336 L{lb},1318 L{lb + 6},1318 "
           f"L{lb + 6},1224 Z", fill="#b197fc", stroke="#5f3dc4", sw=3)
    s.path(f"M{lb + 22},1232 L{lb + 100},1232 A48,48 0 0 1 {lb + 100},1328 L{lb + 22},1328 Z",
           fill="#d0bfff", stroke="#5f3dc4", sw=3)
    s.text(PX1 + 12, LED_A - 14, "陽極 +", size=22, weight=700, fill=T_5V)
    s.text(PX1 + 12, LED_K + 34, "陰極 −", size=22, weight=700)
    for i, r in enumerate((26, 46, 66)):
        s.path(f"M{lb + 160 + i * 4},{1280 - r} A{r},{r} 0 0 1 {lb + 160 + i * 4},{1280 + r}",
               stroke="#7048e8", sw=4)
    s.line(lb + 236, 1280, lb + 262, 1280, stroke="#7048e8", sw=4, extra='marker-end="url(#arrowIR)"')
    s.text(lb + 276, 1272, "對準冷氣接收窗", size=24, weight=700, fill=T_IO10)
    s.text(lb + 276, 1306, "需視線可達", size=22)
    s.text(lb - 10, 1380, "IR LED 940 nm、5 mm（型號以實物為準）", size=22)

    # ---- 左欄：怎麼看
    s.rect(40, 380, 430, 600, fill="#f8f9fa", stroke="#ced4da", sw=2, rx=12)
    s.text(62, 424, "怎麼看這張圖", size=26, weight=700)
    s.lines(62, 470, [
        "• 元件面朝上、USB-C 朝上",
        "• 左排、右排的 #1 都在",
        "  USB 端，往下到 #8",
        "• 板上絲印只有 5V、G、",
        "  3.3、21、0；其餘腳",
        "  照本圖位置對",
        "• 翻到背面看，左右對調",
        "• 絲印以實物為準",
        "• 線色只是建議；接線",
        "  看絲印與腳位",
        "• 天線在 USB 對側短邊",
    ], size=24, lh=44)

    # ---- 腳位圖例（P 下方）
    gx, gy = 1460.0, 1460.0
    s.rect(gx, gy, 620, 300, fill="#f8f9fa", stroke="#ced4da", sw=2, rx=12)
    s.text(gx + 22, gy + 42, "腳位圖例", size=26, weight=700)
    items = [("used", C_SDA, "已使用（外圈＝線色）"), ("avoid", None, "避開：strapping／LED／BOOT／UART0"),
             ("spare", None, "未使用（保留）")]
    for i, (st, ring, lab) in enumerate(items):
        yy = gy + 92 + i * 62
        s.rect(gx + 22, yy - 27, 54, 54, fill="#1f2a36", rx=8)
        draw_pad(s, gx + 49, yy, st, ring, k=0.55)
        s.text(gx + 92, yy + 8, lab, size=24)
    s.circle(gx + 48, gy + 272, 9, fill=C_SDA, stroke="#141414", sw=3)
    s.text(gx + 92, gy + 280, "線端圓點＝腳位中心", size=24)

    # ---- 外殼（R2）配置
    ex, ey = 2120.0, 1460.0
    s.rect(ex, ey, 840, 300, fill="#fff9db", stroke="#e0c341", sw=2, rx=12)
    s.text(ex + 22, ey + 42, "外殼（R2）配置", size=26, weight=700)
    s.lines(ex + 22, ey + 90, [
        "• 感測器放下格、C3 板子放上格",
        "• 天線端淨空：天線前方約 8 mm 內不放線、不放金屬",
        "• 感測器遠離 C3 的熱源（LDO、晶片）與天線",
        "• IR LED 從外殼開孔對準冷氣；接收頭避開陽光／日光燈直射",
        "• 接收頭離 IR LED 遠一點或加遮擋（免得收到自己發的訊號）",
    ], size=24, lh=42)

    # ---- 下排三格
    by0 = 1800.0
    s.rect(40, by0, 1000, 540, fill="#f8f9fa", stroke="#ced4da", sw=2, rx=12)
    s.text(62, by0 + 44, "接線對照（兩端腳名；線色只是建議）", size=26, weight=700)
    rows = [
        (C_3V3, False, [("3V3", {"fill": T_3V3, "weight": 700}),
                        ("（右排 #3）→ 分接板 → 感測 VDD、接收 VCC", {})]),
        (C_GND, False, [("GND", {"weight": 700}), ("（右排 #2）→ 分接板 → 感測 GND、接收 GND、Q 的 E", {})]),
        (C_SDA, False, [("GPIO4", {"fill": T_SDA, "weight": 700}), ("（右排 #4）→ 分接板 → 感測 SDA", {})]),
        (C_SCL, False, [("GPIO5", {"fill": T_SCL, "weight": 700}), ("（左排 #1）→ 感測 SCL", {})]),
        (C_5V, False, [("5V", {"fill": T_5V, "weight": 700}), ("（右排 #1，USB VBUS）→ 33 Ω → LED+", {})]),
        (C_IO3, False, [("GPIO3", {"fill": T_IO3, "weight": 700}), ("（右排 #5）→ 1 kΩ → Q 的 B", {})]),
        (C_IO10, False, [("GPIO10", {"fill": T_IO10, "weight": 700}), ("（左排 #6）→ 接收頭 OUT（必備）", {})]),
    ]
    for i, (col, dashed, txt) in enumerate(rows):
        yy = by0 + 104 + i * 60
        draw_wire(s, [(66, yy - 8), (140, yy - 8)], col, "legend", dashed=dashed, end_dots=False)
        s.text(162, yy, txt, size=24)
    s.text(62, by0 + 520, "紅＝3V3、黑＝GND、藍＝SDA、黃＝SCL、橙＝5V、綠＝GPIO3、紫＝GPIO10",
           size=22, fill=MUTED)

    s.rect(1070, by0, 1000, 540, fill="#f8f9fa", stroke="#ced4da", sw=2, rx=12)
    s.text(1092, by0 + 44, "I²C 與電源注意", size=26, weight=700)
    s.lines(1092, by0 + 96, [
        [("• VDD 一定接 ", {}), ("3V3", {"fill": T_3V3, "weight": 700}), ("，不接 5V：", {})],
        "  模組的 SDA/SCL 上拉接在 VDD，接 5V 會把 5V 灌進 GPIO",
        "• 多數二合一小板已內建 I²C 上拉（到貨確認）；",
        "  沒有就 SDA、SCL 各加 4.7–10 kΩ 到 3V3",
        "• 位址：AHT20＝0x38；BMP280＝0x77（SDO 接 VDDIO，",
        "  多數小板）或 0x76（SDO 接地）；有 SDO 焊點／跳線就改它",
        "• 常見絲印腳序 VDD、SDA、GND、SCL（本圖模組轉 180°）",
        "• C3 只有一支 GND、一支 3V3 → 由分接小板分給各模組",
        "• 接收頭 VCC 接 3V3，OUT 才不會超過 3.3 V",
    ], size=23, lh=47)

    s.rect(2100, by0, 860, 540, fill="#f8f9fa", stroke="#ced4da", sw=2, rx=12)
    s.text(2122, by0 + 44, "避開的腳（灰色斜線）", size=26, weight=700)
    s.lines(2122, by0 + 96, [
        "• GPIO2、GPIO8、GPIO9：strapping（開機取樣）",
        "• GPIO8：板載藍 LED（低電位亮）",
        "• GPIO9：BOOT 鍵",
        "• GPIO20／21：UART0 RX／TX（保留序列埠 log）",
        "• GPIO18／19：USB D−／D+（未拉出）",
        "• GPIO0／1：XTAL_32K 腳，本設計保留不用",
        "• GPIO6／7：JTAG，保留備用",
        "• GPIO4／5 用作 I²C → pad JTAG 不能用，",
        "  USB 燒錄與 log 不受影響",
    ], size=23, lh=47)

    s.text(W - 40, H - 22, "板圖自繪，CC0-1.0", size=22, fill=MUTED, anchor="end")
    return s


# ---------------------------------------------------------------- 零件小圖
def draw_resistor_v(s, x, y0, y1, label_lines=(), dashed=False, side="right"):
    dash = 'stroke-dasharray="10 7"' if dashed else ""
    s.rect(x - 24, y0, 48, y1 - y0, fill="#ffffff", stroke=INK, sw=4, rx=4, extra=dash)
    lx = x + 46 if side == "right" else x - 46
    anchor = "start" if side == "right" else "end"
    for i, (t, sz, w) in enumerate(label_lines):
        s.text(lx, (y0 + y1) / 2 - 4 + i * 34, t, size=sz, weight=w, anchor=anchor)


def draw_to92(s, cx, y, pins, title):
    """TO-92 正視圖：平面朝自己、腳朝下。pins: 由左到右三個腳名。"""
    s.text(cx, y - 18, title, size=24, weight=700, anchor="middle")
    s.path(f"M{cx - 52},{y + 10} L{cx + 52},{y + 10} L{cx + 52},{y + 70} "
           f"A60,30 0 0 1 {cx - 52},{y + 70} Z", fill="#343a40", stroke=INK, sw=3)
    s.text(cx, y + 54, "平面", size=22, fill="#f1f3f5", anchor="middle")
    for i, p in enumerate(pins):
        lx = cx - 40 + i * 40
        s.line(lx, y + 96, lx, y + 170, stroke="#868e96", sw=6)
        s.text(lx, y + 202, p, size=24, weight=700, anchor="middle")


def make_ir():
    W, H = 2400, 1910
    s = Svg(W, H, "紅外線電路放大圖",
            "GPIO3 經 1 kΩ 驅動 NPN（S8050 或 2N2222），5V 經 33 Ω 與 940 nm IR LED 到集極；"
            "VS1838B 接收頭（必備）接 GPIO10。用於紅外線控制日立（Hitachi）冷氣（遙控器 RF11T1）。零件圖自繪，CC0-1.0。")
    hatch_defs(s)
    s.text(40, 66, "紅外線電路放大圖｜紅外線控制日立（Hitachi）冷氣（遙控器 RF11T1）", size=40, weight=700)
    s.text(40, 112, "分接／IR 驅動小板照這張焊；腳位都以 ESP32-C3 SuperMini 元件面朝上、USB-C 朝上的位置標示。",
           size=26, fill=MUTED)

    # ---- A. 發射驅動
    s.rect(40, 150, 1140, 1060, fill="#fbfbfc", stroke="#ced4da", sw=2, rx=14)
    s.text(70, 200, "A. IR 發射驅動（GPIO3 → NPN → 940 nm IR LED）", size=28, weight=700)
    X = 780.0
    # 5V
    s.circle(X, 262, 12, fill=C_5V, stroke=INK, sw=3)
    s.text(X + 28, 271, "5V（C3 右排 #1，USB VBUS）", size=26, weight=700, fill=T_5V)
    s.line(X, 274, X, 310, sw=4)
    draw_resistor_v(s, X, 310, 430, [("R2  33 Ω 1/4 W", 24, 700), ("串在 5V 路徑上", 22, 400)])
    s.line(X, 430, X, 490, sw=4)
    # LED
    s.path(f"M{X - 50},490 L{X + 50},490 L{X},570 Z", fill="#d0bfff", stroke=INK, sw=4)
    s.line(X - 50, 570, X + 50, 570, sw=4)
    for dy in (0, 34):
        s.line(X + 62, 500 + dy, X + 104, 532 + dy, stroke="#7048e8", sw=4,
               extra='marker-end="url(#arrowIR)"')
    s.text(X - 66, 506, "陽極（長腳）", size=22, anchor="end")
    s.text(X - 66, 588, "陰極（短腳／平邊）", size=22, anchor="end")
    s.text(X + 126, 522, "IR LED 940 nm、5 mm", size=24, weight=700)
    s.text(X + 126, 556, "If ≈ 103 mA（脈衝）", size=22)
    s.line(X, 570, X, 668, sw=4)
    # NPN
    s.circle(X - 15, 740, 62, fill="#ffffff", stroke=INK, sw=3)
    s.line(X - 35, 702, X - 35, 778, sw=6)
    s.path(f"M{X - 35},722 L{X},690 L{X},668", sw=4)
    s.path(f"M{X - 35},758 L{X},790 L{X},880", sw=4)
    s.path(f"M{X - 14},778 L{X},790 L{X - 18},792", sw=4)
    s.text(X + 14, 678, "C", size=22, weight=700)
    s.text(X + 14, 842, "E", size=22, weight=700)
    s.text(X - 92, 726, "B", size=22, weight=700, anchor="end")
    s.text(X + 70, 728, "Q1  NPN：S8050 或 2N2222", size=24, weight=700)
    s.text(X + 70, 762, "TO-92 包裝", size=22)
    s.text(X + 70, 794, "腳序以實物 datasheet 為準", size=22)
    # 基極
    s.circle(380, 740, 12, fill=C_IO3, stroke=INK, sw=3)
    s.text(356, 749, "GPIO3（C3 右排 #5）", size=24, weight=700, fill=T_IO3, anchor="end")
    s.line(392, 740, 500, 740, sw=4)
    s.rect(500, 716, 130, 48, fill="#ffffff", stroke=INK, sw=4, rx=4)
    s.text(565, 700, "R1  1 kΩ", size=24, weight=700, anchor="middle")
    s.text(565, 800, "Ib ≈ 2.6 mA", size=22, anchor="middle")
    s.line(630, 740, X - 35, 740, sw=4)
    # 建議的 10 kΩ 下拉
    s.circle(680, 740, 7, fill=INK)
    s.line(680, 740, 680, 812, sw=3, extra='stroke-dasharray="10 7"')
    draw_resistor_v(s, 680, 812, 922, [("R3  10 kΩ（建議）", 22, 700), ("開機時把 B 拉低", 22, 400)],
                    dashed=True, side="left")
    s.path(f"M680,922 L680,960 L{X},960", sw=3, extra='stroke-dasharray="10 7"')
    s.circle(X, 960, 7, fill=INK)
    # GND
    s.line(X, 880, X, 1010, sw=4)
    for i, hw in enumerate((40, 26, 12)):
        s.line(X - hw, 1010 + i * 12, X + hw, 1010 + i * 12, sw=4)
    s.text(X + 60, 1026, "GND（C3 右排 #2）", size=24, weight=700)
    s.lines(70, 1108, ["電阻選擇：33 Ω 放在 5V 與 LED 陽極之間（電阻就在 5V 路徑上）",
                       "LED 從 USB 5V 供電；GPIO3 只推電晶體基極（約 2.6 mA）"], size=22, lh=40, fill=MUTED)

    # ---- B. 接收（必備：首次設定要用它錄遙控碼、確認協定）
    s.rect(1220, 150, 1140, 640, fill="#fbfbfc", stroke="#ced4da", sw=2, rx=14)
    s.text(1250, 200, "B. IR 接收頭（必備：首次設定用它錄遙控碼、確認協定）", size=28, weight=700)
    s.rect(1300, 260, 180, 290, fill="#343a40", stroke=INK, sw=3, rx=14)
    s.circle(1390, 340, 40, fill="#6c757d")
    s.text(1390, 440, "VS1838B", size=24, weight=700, fill="#ffffff", anchor="middle")
    s.text(1390, 476, "38 kHz", size=22, fill="#f1f3f5", anchor="middle")
    for y, pin, txt, tcol, wcol in ((320, "OUT", "→ GPIO10（左排 #6）", T_IO10, C_IO10),
                                     (405, "GND", "→ GND（右排 #2）", INK, C_GND),
                                     (490, "VCC", "→ 3V3（右排 #3）", T_3V3, C_3V3)):
        s.text(1494, y - 12, pin, size=22, weight=700, fill="#495057")
        draw_wire(s, [(1480, y), (1640, y)], wcol, "rx-" + pin, end_dots=False)
        s.circle(1640, y, 10, fill=wcol, stroke="#141414", sw=3)
        s.text(1664, y + 8, txt, size=24, weight=700, fill=tcol)
    s.lines(1250, 606, ["• VCC 接 3V3、不接 5V：OUT 才不會超過 3.3 V",
                        "• 38 kHz；輸出低電位有效（ESPHome 設 inverted: true）",
                        "• 避開陽光／日光燈直射（會誤觸）；離 IR LED 遠一點或加遮擋，免得收到自己發的訊號",
                        "• 常見腳序 OUT-GND-VCC（面對圓頂、腳朝下由左到右），以實物為準"],
            size=22, lh=42)

    # ---- C. 零件腳位
    s.rect(1220, 830, 1140, 400, fill="#fbfbfc", stroke="#ced4da", sw=2, rx=14)
    s.text(1250, 878, "C. 零件腳位（以實物 datasheet 為準）", size=28, weight=700)
    # LED 側視：長腳＝陽極；陰極側的塑膠外緣是平邊
    lx, ty = 1330, 940
    s.text(lx + 10, ty, "IR LED", size=24, weight=700, anchor="middle")
    s.path(f"M{lx - 34},1020 L{lx - 34},1000 A44,44 0 0 1 {lx + 54},1000 L{lx + 54},1020 Z",
           fill="#d0bfff", stroke="#5f3dc4", sw=3)
    s.path(f"M{lx - 46},1020 L{lx + 54},1020 L{lx + 54},1034 L{lx - 46},1034 "
           f"A6,6 0 0 1 {lx - 46},1020 Z", fill="#b197fc", stroke="#5f3dc4", sw=3)
    s.line(lx - 8, 1034, lx - 8, 1160, stroke="#868e96", sw=6)
    s.line(lx + 28, 1034, lx + 28, 1118, stroke="#868e96", sw=6)
    s.text(lx - 18, 1194, "長腳＝陽極 +", size=22, weight=700, fill=T_5V, anchor="middle")
    s.text(lx + 50, 1124, "短腳＝陰極 −", size=22, weight=700, anchor="start")
    s.text(lx + 66, 1034, "← 平邊＝陰極側", size=22, anchor="start")
    draw_to92(s, 1700, ty + 18, ("E", "B", "C"), "S8050")
    draw_to92(s, 1870, ty + 18, ("E", "B", "C"), "PN2222A")
    draw_to92(s, 2040, ty + 18, ("C", "B", "E"), "P2N2222A")
    s.text(1870, 1212, "TO-92：平面朝自己、腳朝下，由左到右", size=22, fill=MUTED, anchor="middle")
    # VS1838B 正視：面對圓頂、腳朝下
    vx = 2256
    s.text(vx, ty, "VS1838B", size=24, weight=700, anchor="middle")
    s.rect(vx - 92, 958, 184, 96, fill="#343a40", stroke=INK, sw=3, rx=10)
    s.circle(vx, 1006, 32, fill="#6c757d")
    for i, (p, col) in enumerate((("OUT", T_IO10), ("GND", INK), ("VCC", T_3V3))):
        px = vx - 64 + i * 64
        s.line(px, 1054, px, 1140, stroke="#868e96", sw=6)
        s.text(px, 1174, p, size=22, weight=700, fill=col, anchor="middle")

    # ---- D. 計算
    s.rect(40, 1262, 2320, 600, fill="#f8f9fa", stroke="#ced4da", sw=2, rx=14)
    s.text(70, 1312, "D. IR LED 驅動計算（細節與來源見 PINMAP.md）", size=28, weight=700)
    s.lines(70, 1368, [
        "• 限流電阻：R = (Vbus − Vf − Vce(sat)) ÷ If = (5.0 − 1.35 − 0.25) ÷ 0.10 ≈ 34 Ω → 取 33 Ω（E12）",
        "• LED 電流：If = (5.0 − Vf − 0.25) ÷ 33 Ω；Vf 1.2 V → 約 108 mA、1.35 V → 約 103 mA、1.4 V → 約 102 mA",
        "• 電阻功率：峰值 I²R ≈ 0.103² × 33 ≈ 0.35 W；38 kHz 載波約 50% × 協定 mark 約 50% → 平均約 0.09 W，"
        "每次發送約 0.1–0.5 s，1/4 W 足夠",
        "• 基極：Ib = (3.3 − 0.7) ÷ 1 kΩ ≈ 2.6 mA，強制 β ≈ 103 ÷ 2.6 ≈ 40；S8050 在 100 mA 的最小 hFE 為 85"
        "（onsemi SS8050）→ 確實飽和",
        "• 改用 2N2222／PN2222A：150 mA、VCE = 1 V 的最小 hFE 是 50，餘裕較小；要更穩可把 1 kΩ 改 680 Ω（Ib ≈ 3.8 mA）",
        "• 不用 GPIO 直驅：ESP32-C3 單腳 IOH 典型 40 mA、IOL 28 mA（datasheet 表 5-4），遠低於 100 mA",
        "• 不從 3V3 供電：扣掉 Vf、Vce 後餘裕小，電流對 Vf 很敏感；100 mA 脈衝還會和 Wi-Fi 發射尖峰（最高 335 mA）"
        "共用板上 ME6211（500 mA）",
        "• LED 型號未確認：實物 datasheet 的連續／脈衝電流上限若低於 100 mA，改用 47–68 Ω",
        "• 故障情況：GPIO3 若一直維持高電位，LED 會持續約 103 mA、33 Ω 持續約 0.35 W（超過 1/4 W）"
        "→ 韌體閒置須為低電位；要更保險可用 1/2 W",
    ], size=23, lh=58)
    s.text(W - 40, H - 22, "板圖自繪，CC0-1.0", size=22, fill=MUTED, anchor="end")
    return s


# ---------------------------------------------------------------- 檢查清單
def make_checklist():
    W = 1600
    groups = [
        ("接線前", "#495057", [
            ("先拔掉 USB（斷電）再接線、改線", None),
            ("對腳看絲印，不要看線色", "線色只是建議；杜邦線每包顏色不同，以絲印與腳位為準"),
        ]),
        ("感測板 AHT20+BMP280（I²C）", "#1971c2", [
            ([("VDD → ", {}), ("3V3", {"fill": T_3V3, "weight": 700}), ("（右排 #3），不是 5V", {})],
             "接 5V 會讓模組上的上拉把 5V 灌進 GPIO"),
            ([("GND → ", {}), ("GND", {"weight": 700}), ("（右排 #2）", {})], None),
            ([("SDA → ", {}), ("GPIO4", {"fill": T_SDA, "weight": 700}), ("（右排 #4）", {})], None),
            ([("SCL → ", {}), ("GPIO5", {"fill": T_SCL, "weight": 700}), ("（左排 #1）", {})], None),
        ]),
        ("紅外線發射／接收", "#7048e8", [
            ("IR LED 長腳＝陽極（接 33 Ω／5V 側），短腳＝陰極（接電晶體 C）",
             "陰極那側的塑膠外緣有平邊；以實物為準"),
            ("電晶體 E／B／C 以實物 datasheet 為準",
             "S8050、PN2222A 常見 E-B-C；P2N2222A 是 C-B-E（平面朝自己、腳朝下由左到右）"),
            ([("33 Ω 串在 ", {}), ("5V", {"fill": T_5V, "weight": 700}),
              ("（右排 #1）→ LED 的路徑上", {})], "1 kΩ 串在 GPIO3（右排 #5）→ 電晶體基極 B"),
            ([("接收頭 VS1838B（必備）VCC → ", {}), ("3V3", {"fill": T_3V3, "weight": 700}),
              ("，不接 5V", {})], "OUT → GPIO10（左排 #6）；避開陽光／日光燈直射，離 IR LED 遠一點或加遮擋"),
            ("IR LED 對準冷氣的接收窗，中間不要擋住", "需視線可達；外殼開孔對準 LED"),
            ("線不要經過天線端", "天線在 USB 對側短邊；天線前方約 8 mm 內不放線、不放金屬"),
        ]),
        ("通電前／通電後", "#2f9e44", [
            ("通電前：三用電表量 3V3 對 GND、5V 對 GND，都不應導通",
             "剛碰到時嗶一下是電容充電；一直響才是短路，先不要插 USB"),
            ("通電後：看開機 log 的 I²C 掃描，應出現 0x38 與 0x76 或 0x77",
             "0x38＝AHT20；0x77 或 0x76＝BMP280（看 SDO 接法）"),
            ("通電後：用遙控器（RF11T1）對著接收頭按鍵，log 應出現解碼或 raw 輸出",
             "用來錄遙控碼、確認協定；沒有任何輸出先查 OUT 是否接 GPIO10、VCC 是否接 3V3"),
        ]),
    ]
    y = 200
    blocks = []
    n = 0
    for gname, gcol, items in groups:
        blocks.append(("group", y, gname, gcol))
        y += 76
        for main, note in items:
            n += 1
            blocks.append(("item", y, n, main, note))
            y += 112 if note else 80
        y += 20
    H = int(y + 90)
    s = Svg(W, H, "接線檢查清單", "ESP32-C3 SuperMini + AHT20/BMP280 + IR 的接線檢查清單，每項附勾選框。")
    s.text(60, 92, "接線檢查清單", size=46, weight=700)
    s.text(60, 140, "ESP32-C3 SuperMini＋AHT20/BMP280＋紅外線控制日立（Hitachi）冷氣（遙控器 RF11T1）", size=26, fill=MUTED)
    for b in blocks:
        if b[0] == "group":
            _, by, gname, gcol = b
            s.rect(60, by, 1480, 56, fill="#f1f3f5", rx=10)
            s.rect(60, by, 12, 56, fill=gcol, rx=4)
            s.text(92, by + 39, gname, size=30, weight=700)
        else:
            _, by, num, main, note = b
            s.rect(84, by + 4, 46, 46, fill="#ffffff", stroke=INK, sw=4, rx=6)
            s.text(160, by + 40, str(num), size=28, weight=700, fill=MUTED, anchor="middle")
            s.text(196, by + 40, main, size=30, weight=700)
            if note:
                s.text(196, by + 82, note, size=24, fill=MUTED)
    s.text(60, H - 40, "對照：wiring_main.svg、wiring_ir.svg、PINMAP.md", size=22, fill=MUTED)
    s.text(W - 60, H - 40, "授權：CERN-OHL-P-2.0", size=22, fill=MUTED, anchor="end")
    return s


def main():
    outputs = {
        "wiring_main.svg": make_main(),
        "wiring_ir.svg": make_ir(),
        "wiring_checklist.svg": make_checklist(),
    }
    for name, svg in outputs.items():
        (OUT_DIR / name).write_text(svg.render(), encoding="utf-8")
        print(f"wrote {name} ({svg.w}x{svg.h})")


if __name__ == "__main__":
    main()
