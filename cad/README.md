# cad/ — 外殼（R2）

黑色殼身＋白色滑蓋（沿長軸滑開）。授權 CERN-OHL-P-2.0（見 `../LICENSES/CERN-OHL-P-2.0.txt`）。**尚未印出實物驗證。**

| 路徑 | 內容 |
|---|---|
| `scad/` | OpenSCAD 原始檔（`mod_wifi_case.scad` 主檔、`mod_wifi_ref.scad` 參考件） |
| `stl/assembled/` | 組裝座標：殼身、滑蓋、3 mm LED 轉接套、兩條頂壓條 |
| `stl/plate/` | 列印姿態：`WIFI_BLACK.stl`、`WIFI_WHITE.stl`、選印 `WIFI_COUPON.stl` |
| `stl/variant_*/` | 備用版本（排針朝上、杜邦線接感測板、SHT31 感測板） |
| `img/` | 算繪圖 01–11 |
| `glb/` | 殼身＋滑蓋分件的 GLB（專案頁 3D 檢視器用） |
| `PRINT_ORDER.md` | 列印順序（和姊妹專案一起排的兩盤，通用說明） |
| `ASSEMBLY.md` | 組裝步驟（外殼 R2 的 CAD 文件；IR 腳位以 `../wiring/` 為準，見文件開頭） |

- Onshape 公開文件（R2）：https://cad.onshape.com/documents/20e3a641bf055fec6fb69fdc/w/8c8c83e86c0f45c5d3bed645/e/2099ef07d5082cb81859d333
- Onshape（R1，同一文件的舊零件工作室）：https://cad.onshape.com/documents/20e3a641bf055fec6fb69fdc/w/8c8c83e86c0f45c5d3bed645/e/e251f40771bee661eb76bb3a
- STEP 與兩盤 G-code 檔案太大，不放在 git，附在 Release：https://github.com/h2ocloud/esp32c3-wifi-sensing-node/releases/tag/v0.1.0
