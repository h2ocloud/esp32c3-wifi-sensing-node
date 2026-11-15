# wiring／接線圖與腳位表

ESP32-C3 SuperMini（排針已焊）＋ AHT20+BMP280 二合一 I²C 模組＋紅外線控制日立（Hitachi）冷氣（遙控器 RF11T1）：IR 發射電路＋IR 接收頭 VS1838B（必備，首次設定用來錄遙控碼、確認協定）。

## 檔案

| 檔案 | 內容 |
|---|---|
| `wiring_main.svg`／`.png` | 接線總圖：C3 全部 16 支腳、USB-C 與天線方向、感測板、分接／IR 驅動小板、IR LED、IR 接收頭（必備）、避開腳位圖例、外殼配置注意 |
| `wiring_ir.svg`／`.png` | 紅外線電路放大圖：簡化原理圖、零件腳位（LED、S8050／PN2222A／P2N2222A、VS1838B）、驅動計算 |
| `wiring_checklist.svg`／`.png` | 接線檢查清單（附勾選框） |
| `PINMAP.md` | 腳位表、避開腳位與來源頁碼、I²C 位址、IR LED 驅動計算、ESPHome 片段、待實物確認、來源清單 |
| `pinmap.csv` | 主表（UTF-8，含表頭） |
| `src/make_wiring.py` | 產生三張 SVG（只用 Python 標準函式庫） |
| `src/render_png.py` | 用 Playwright 的 headless Chromium 把 SVG 轉 PNG，並可檢查版面 |

板子方向一律是**元件面朝上、USB-C 朝上**；兩排的 #1 都在 USB 端。絲印、模組腳序、零件腳序都**以實物為準**。

## 授權

- 接線圖與文件：CERN-OHL-P-2.0
- 自繪板圖、模組圖、零件圖（含在 SVG／PNG 內）：CC0-1.0。全部由 `src/make_wiring.py` 自己畫，沒有使用任何第三方板圖或零件庫。
- `src/` 內的產生腳本：CC0-1.0

## 如何重建

```sh
cd wiring
python3 src/make_wiring.py          # 產生 wiring_main.svg、wiring_ir.svg、wiring_checklist.svg
python3 src/render_png.py --check   # 轉 PNG（1 SVG 單位＝1 px），並檢查字重疊、線蓋字、越界、異網交叉
```

- `make_wiring.py` 先定義板子幾何（18.00 × 22.52 mm、兩排中心距 15.24 mm、腳距 2.54 mm），再由 `pin_xy()` 算出每支腳的座標；所有接到 C3 的線，端點都直接取自 `pin_xy()`，保證落在腳位中心。
- `render_png.py` 需要 `pip install playwright` 與 `python3 -m playwright install chromium`。它會自己啟動一個 headless Chromium、用完關閉，不連接任何已開啟的瀏覽器；PNG 不寫入文字型 metadata。
- 字型使用系統的繁體中文字型（Noto Sans TC、PingFang TC、Microsoft JhengHei 等擇一）；不同系統轉出的 PNG 字形可能略有差異。
