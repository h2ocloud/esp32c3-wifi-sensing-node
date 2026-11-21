# hardware/r3 — 外殼 R3（麵包板版）

R3 是為 170 孔迷你麵包板設計的兩件式外殼：**黑色殼身＋白色滑蓋**，PLA、免支撐、0.28 mm 層高。C3 直接插在麵包板上，麵包板用背膠黏在殼內；DHT11 模組放在下端的通風艙，IR LED 與 VS1838B 從蓋上的窗口朝房間。授權 CERN-OHL-P-2.0（見 [`../../LICENSES/CERN-OHL-P-2.0.txt`](../../LICENSES/CERN-OHL-P-2.0.txt)）。

> **狀態：靜態檢查通過，尚未印出，尚未實機驗證。**
> 兩版各 37 項干涉／功能檢查加 STL 檢查全部通過，14 組負向對照都有反應；沒有任何列印或實物量測的數字。

## 兩個版本

| | 高版（主） | 薄版（備選） |
|---|---|---|
| 外形（寬 × 長 × 深） | 60.6 × 72.9 × 37.6 mm | 60.6 × 72.9 × 27.8 mm |
| DHT11 接回麵包板 | 公母杜邦線，公頭直立插 J2–J4，不用補料 | J2–J4 插 1×3 90° 排針（或彎針、3 條扁跳線），母頭平躺 |
| LED、VS1838B 的腳 | 留長，墊高約 10 mm | LED 腳剪短；VS1838B 折平 |
| 隔牆 | 上緣有缺口讓線翻過去 | 雙層隔牆開孔讓母頭穿過 |
| 滑蓋 | 兩版通用 | 兩版通用 |

兩版的底面積相同，高版殼身深 9.8 mm。`img/` 的算繪圖畫的是**薄版**，目前沒有高版算繪圖。

## 資料夾

| 路徑 | 內容 |
|---|---|
| `scad/` | OpenSCAD 原始檔：`mod_wifi_r3_case.scad`（參數、殼身、滑蓋）、`mod_wifi_r3_ref.scad`（參考零件）。參數 `bb_dht_conn`：`angle`＝薄版、`straight`＝高版 |
| `stl/tall/plate/` | 高版的列印姿態：`WIFI_R3_BLACK.stl`（殼身）、`WIFI_R3_WHITE.stl`（滑蓋） |
| `stl/tall/assembled/` | 高版的組裝座標：`01_body.stl`、`02_lid.stl` |
| `stl/angle/plate/`、`stl/angle/assembled/` | 薄版的同一組檔案 |
| `img/` | 算繪圖（薄版）：`01_iso_closed.png`（閉合）、`02_top_open.png`（開蓋俯視）、`03_breadboard.png`（麵包板擺位） |
| `check/` | `r3_check.txt`（兩版各 37 項檢查，全部通過）、`r3_negative_controls.txt`（14 組負向對照） |
| `wiring/` | 麵包板接線圖（PNG＋SVG）；**還沒放進來**，之後補上 |

G-code 與 STEP 不放在 git；等 G-code 到齊後，附在 Release v0.2.0。

## 相關文件

- 麵包板孔位、腳位、直驅與電晶體版：[`../../docs/BREADBOARD_R3.md`](../../docs/BREADBOARD_R3.md)
- 零件表（已有／需補料）：[`../../bom/BOM_R3.md`](../../bom/BOM_R3.md)
