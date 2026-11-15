# 腳位表（PINMAP）

ESP32-C3 SuperMini ＋ AHT20+BMP280 二合一 I²C 模組 ＋ 紅外線控制日立（Hitachi）冷氣（遙控器 RF11T1）：IR 發射電路＋IR 接收頭（必備）。

IR 接收頭 VS1838B 是**必備**元件：首次設定要用它錄下 RF11T1 遙控器的訊號、確認協定。

- 接線總圖：[`wiring_main.svg`](wiring_main.svg)（PNG：[`wiring_main.png`](wiring_main.png)）
- 紅外線電路放大圖：[`wiring_ir.svg`](wiring_ir.svg)（PNG：[`wiring_ir.png`](wiring_ir.png)）
- 接線檢查清單：[`wiring_checklist.svg`](wiring_checklist.svg)（PNG：[`wiring_checklist.png`](wiring_checklist.png)）
- 主表的機器可讀版本：[`pinmap.csv`](pinmap.csv)

## 1. 方向與編號規則

- **元件面朝上、USB-C 朝上**看板子。左邊那排叫「左排」、右邊那排叫「右排」。
- 兩排都是 **#1 在 USB 端**，往下（往天線端）到 #8。
- 陶瓷晶片天線在 **USB 對側的短邊**（圖上朝下）。
- 板上絲印只印了少數字樣（右上 `5V`、`G`、`3.3`；左下 `21`、右下 `0`），其他腳請照本表位置對。**絲印以實物為準。**
- 翻到背面看，左右會對調。Nologo 產品頁的「引腳圖」就是**背面視圖**（5V 在左邊），和元件面的尺寸圖左右相反，對照時要注意。
- 線色只是建議；接線時以絲印與腳位為準。

## 2. 主表（接線）

C3 只有一支 GND、一支 3V3，所以 GND、3V3（以及為了走線方便的 SDA）先接到一塊「分接／IR 驅動小板」（洞洞板），再分給感測板、IR 驅動與接收頭。電氣上就是同名的點接在一起。

| 連接對象 | 對象腳 | C3 腳名 | 位置 | 線色（建議） | 說明 |
|---|---|---|---|---|---|
| AHT20+BMP280 模組 | VDD | 3V3 | 右排 #3 | 紅 | 經分接小板。**一定接 3V3，不接 5V**：模組的 SDA/SCL 上拉接在 VDD，接 5V 會把 5V 灌進 GPIO |
| AHT20+BMP280 模組 | GND | GND | 右排 #2 | 黑 | 經分接小板（GND 匯流） |
| AHT20+BMP280 模組 | SDA | GPIO4 | 右排 #4 | 藍 | 經分接小板轉接；ESP32-C3 的 I²C 走 GPIO matrix，可接任意 GPIO |
| AHT20+BMP280 模組 | SCL | GPIO5 | 左排 #1 | 黃 | 直接接到模組 |
| IR 驅動（33 Ω → LED 陽極） | 5V 輸入 | 5V（USB VBUS） | 右排 #1 | 橙 | 這支腳接在 USB VBUS、板上二極體之前；LED 脈衝電流約 103 mA |
| IR 驅動（1 kΩ → Q1 基極 B） | 訊號輸入 | GPIO3 | 右排 #5 | 綠 | RMT 發射；基極電流約 2.6 mA |
| IR 驅動（Q1 射極 E） | GND | GND | 右排 #2 | 黑 | 分接小板 GND 匯流 |
| IR 接收頭 VS1838B（必備） | VCC | 3V3 | 右排 #3 | 紅 | **不接 5V**，OUT 才不會超過 3.3 V |
| IR 接收頭 VS1838B（必備） | GND | GND | 右排 #2 | 黑 | 分接小板 GND 匯流 |
| IR 接收頭 VS1838B（必備） | OUT | GPIO10 | 左排 #6 | 紫 | RMT 接收（38 kHz）；輸出低電位有效（ESPHome 設 `inverted: true`）；首次設定用來錄遙控碼、確認協定 |

模組腳序：常見絲印為 `VDD, SDA, GND, SCL`，**各家可能不同，以實物絲印為準**。總圖上的模組轉了 180° 擺放（由上而下 SCL、GND、SDA、VDD），只是為了讓線不交叉。

IR 驅動電路（細節見 `wiring_ir.svg`）：

```
5V（右排 #1）─ 33 Ω 1/4 W ─ IR LED 陽極（長腳）│ 陰極（短腳／平邊）─ Q1 集極 C
GPIO3（右排 #5）─ 1 kΩ ─ Q1 基極 B            （建議）10 kΩ 接在 B 與 E 之間
Q1 射極 E ─ GND（右排 #2）                     Q1 = S8050 或 2N2222（NPN，TO-92）
```

33 Ω 放在「5V 與 LED 陽極之間」（電阻就在 5V 路徑上）。TO-92 的 E/B/C 腳序因廠牌而異，**以實物 datasheet 為準**（見第 6 節）。

## 3. C3 全部 16 支腳

| 位置 | 腳名 | 本設計 | 備註 |
|---|---|---|---|
| 左排 #1 | GPIO5 | 使用：I²C SCL | JTAG MTDI；當 I²C 用之後 pad JTAG 不能用 |
| 左排 #2 | GPIO6 | 未使用（保留） | JTAG MTCK |
| 左排 #3 | GPIO7 | 未使用（保留） | JTAG MTDO |
| 左排 #4 | GPIO8 | **避開** | strapping；板載藍 LED（低電位亮） |
| 左排 #5 | GPIO9 | **避開** | strapping；BOOT 鍵 |
| 左排 #6 | GPIO10 | 使用：IR 接收（必備） | 一般 GPIO |
| 左排 #7 | GPIO20（RX） | **避開** | UART0 RX，保留序列埠 log |
| 左排 #8 | GPIO21（TX） | **避開** | UART0 TX，保留序列埠 log |
| 右排 #1 | 5V | 使用：IR LED 電源 | USB VBUS |
| 右排 #2 | GND | 使用 | 全系統共地 |
| 右排 #3 | 3V3 | 使用：感測板、接收頭 | 板上 ME6211 LDO 輸出 |
| 右排 #4 | GPIO4 | 使用：I²C SDA | JTAG MTMS；當 I²C 用之後 pad JTAG 不能用 |
| 右排 #5 | GPIO3 | 使用：IR 發射 | 一般 GPIO |
| 右排 #6 | GPIO2 | **避開** | strapping |
| 右排 #7 | GPIO1 | 未使用（保留） | XTAL_32K_N |
| 右排 #8 | GPIO0 | 未使用（保留） | XTAL_32K_P |

## 4. 避開與特殊用途腳位

「DS」＝ Espressif《ESP32-C3 Series Datasheet》v2.5（來源 S1），頁碼為 PDF 印刷頁碼。

| 腳 | 原因 | 來源 |
|---|---|---|
| GPIO2 | strapping 腳（預設浮接）；官方建議上拉以防開機毛刺 | DS §2.3.4 p.23；表 3-1 p.30；表 3-3 註 2 p.31 |
| GPIO8 | strapping 腳：下載模式時須為高電位，並控制 ROM 訊息輸出；SuperMini 上接藍色 LED（3.3 V → 5.1 kΩ → LED → GPIO8，低電位亮）與 10 kΩ 上拉 | DS §3 p.30、表 3-3 p.31；S2 原理圖；S5 `led0 = GPIO8 ACTIVE_LOW`；S4 `LED_BUILTIN = 8` |
| GPIO9 | strapping 腳：開機時為低電位會進下載模式（預設弱上拉）；SuperMini 上接 BOOT 鍵（10 kΩ 上拉） | DS 表 3-1 p.30、表 3-3 p.31；S2 原理圖；S5 `sw0 = GPIO9` |
| GPIO20／21 | UART0 RX／TX（IO MUX 預設功能），保留序列埠 log | DS 表 2-4 p.20、§2.3.4 p.23；S4 `RX = 20`、`TX = 21` |
| GPIO18／19 | USB D−／D+（USB Serial/JTAG）；SuperMini 內部接 USB-C，未拉出到排針 | DS 表 2-7 p.24、§2.3.4 p.23；S2 原理圖 |
| GPIO12–17 | SPI0/1 接封裝內 flash（晶片 ESP32-C3FN4），不建議他用；未拉出 | DS §2.3.4 p.23（priority 4）、表 2-12 p.29；S2 產品參數 |
| GPIO11 | VDD_SPI（flash 電源）；未拉出 | DS §2.3.4 p.23 |
| GPIO0／1 | XTAL_32K_P／N。SuperMini 原理圖只有 40 MHz 晶振、沒有 32 kHz 晶振，所以可當一般 GPIO；**本設計保留不用** | DS 表 2-6 p.21、表 2-7 p.24；S2 原理圖（CY1 40 MHz） |
| GPIO6／7 | JTAG MTCK／MTDO，保留備用 | DS 表 2-4 p.20、§2.3.4 p.23 |
| GPIO4／5（已使用） | JTAG MTMS／MTDI，官方列為「使用時注意」（priority 3）。拿來當 I²C 會讓 pad JTAG 不能用，但官方說明可改用 USB Serial/JTAG，所以 **USB 燒錄與 log 不受影響**。這兩支腳開機時沒有毛刺（毛刺表只列 MTCK、MTDO、GPIO10、U0RXD、GPIO18） | DS §2.3.3 p.22、§2.3.4 p.23、表 2-2 p.18 |
| GPIO3（已使用） | 一般 GPIO（priority 2）。重置期間只開輸入、沒有上下拉（浮接），所以**建議在 Q1 的 B–E 間加 10 kΩ**，開機時讓電晶體保持關閉 | DS 表 2-1 p.16、§2.3.4 p.23 |
| GPIO10（已使用） | 一般 GPIO（priority 2）；上電時有約 5 ns 的低電位毛刺，當輸入用沒有影響 | DS 表 2-2 p.18、§2.3.4 p.23 |

I²C 為什麼不用預設腳：ESP32-C3 的 I²C 走 GPIO matrix，可接任意 GPIO（DS 表 2-7 p.24 的 I2C 欄、§2.3.1 p.19）。Arduino 的 SuperMini variant 預設 `SDA = 8`、`SCL = 9`（S4），Zephyr 的板級定義用 SDA = GPIO9、SCL = GPIO10（S5），這些都是慣例；本專案刻意不用，因為 GPIO8／9 是 strapping，而且接著 LED 與 BOOT 鍵。

紅外線用的 RMT：ESP32-C3 有 2 個發射、2 個接收通道（DS §4.2.1.8 p.50），IR 發射與接收各用 1 個。

## 5. I²C 位址

| 元件 | 位址 | 依據 |
|---|---|---|
| AHT20 | **0x38**（固定） | Aosong AHT20 datasheet p.12（S7） |
| BMP280 | **0x76**：SDO 接 GND；**0x77**：SDO 接 VDDIO；SDO 不能浮接 | Bosch BMP280 datasheet §5.2 p.28（S6） |

- 本專案預設 **0x77**：這是 ESPHome `bmp280_i2c` 的預設值（S9），也是多數二合一小板的常見接法。模組層級沒有官方文件可查，**待實物確認**——開機 log 的 I²C 掃描看到 0x76 就改設定。
- 板上若有 SDO 焊點／跳線（常標 `SDO`、`ADDR` 或 `0x76/0x77`）：把 SDO 改接 GND 就是 0x76，改接 VDDIO 就是 0x77；通常要先切斷原本的細走線或焊橋再改焊。焊點位置因板而異，**待實物確認**。
- 兩顆位址不衝突（0x38 與 0x76/0x77）。
- 上拉：BMP280 的 SDA 為開汲極，必須外接上拉到 VDDIO（S6 p.28）；AHT20 的上拉電源必須來自 VDD（S7 p.9）。多數二合一小板已內建上拉（到貨確認）；沒有就 SDA、SCL 各加 4.7–10 kΩ 到 3V3（AHT20 datasheet 例示 2.0–4.7 kΩ，線短、100 kHz 時 4.7–10 kΩ 可用）。
- 電源：BMP280 的 VDD/VDDIO 最高 3.6 V（絕對最大 4.25 V，S6 表 2 p.7、表 3 p.9），AHT20 可 2.2–5.5 V（S7 p.9）——這也是 VDD 必須接 3V3 的另一個原因。

## 6. IR LED 驅動計算

假設：Vbus = 5.0 V（USB）、LED 目標 If = 100 mA、Vce(sat) ≈ 0.25 V。LED 型號**未確認，以實物為準**；下面的 Vf 範圍 1.2–1.4 V 是 940 nm 紅外 LED 的常見值，參考型號 Vishay TSAL6200 在 100 mA 時 Vf 典型 1.35 V、最大 1.6 V（S16）。

**限流電阻**

R = (Vbus − Vf − Vce(sat)) ÷ If = (5.0 − 1.35 − 0.25) ÷ 0.10 ≈ **34 Ω → 取 33 Ω（E12）**

| 條件 | If = (Vbus − Vf − 0.25) ÷ 33 Ω |
|---|---|
| Vbus 5.0 V、Vf 1.20 V | ≈ 108 mA（上限） |
| Vbus 5.0 V、Vf 1.35 V | ≈ 103 mA（典型） |
| Vbus 5.0 V、Vf 1.40 V | ≈ 102 mA（下限） |
| 參考：Vf 1.6 V（TSAL6200 最大） | ≈ 95 mA |
| 參考：USB 電壓 5.25 V、Vf 1.2 V | ≈ 115 mA |
| 參考：USB 電壓 4.75 V、Vf 1.4 V | ≈ 94 mA |

**電阻功率**

- 峰值：I²R ≈ 0.103² × 33 ≈ **0.35 W**。
- IR 訊號是 38 kHz 載波（ESPHome 設 `carrier_duty_percent: 50%`，S10），協定的 mark／space 約各半，所以發送期間的平均功率約峰值的 25%：0.35 × 0.5 × 0.5 ≈ **0.09 W**；每次發送只有約 0.1–0.5 s（估計）。**1/4 W 足夠。**
- 發送期間的平均電流約 103 mA × 25% ≈ 26 mA；不發送時為 0。
- 故障情況：若 GPIO3 卡在高電位（例如韌體錯誤），LED 會持續約 103 mA、33 Ω 持續約 0.35 W，**超過 1/4 W**，LED 也會長時間處在連續電流上限附近。ESPHome `remote_transmitter` 閒置時預設輸出低電位（`eot_level` 預設 false，S10），加上建議的 10 kΩ B–E 下拉，正常不會發生；想更保險可改用 1/2 W 電阻。

**基極電流與飽和**

- Ib = (3.3 − 0.7) ÷ 1 kΩ ≈ **2.6 mA**；強制 β = Ic ÷ Ib ≈ 103 ÷ 2.6 ≈ **40**。
- S8050：onsemi SS8050（頂面印字 S8050B/C/D）在 VCE = 1 V、Ic = 100 mA 時 hFE 最小 **85**（S12）；UTC S8050 在 VCE = 1 V、Ic = 150 mA 時最小 **120**（S13）。強制 β 40 只有最小值的一半以下 → **確實飽和**。
- 2N2222：onsemi PN2222A／P2N2222A 沒有列 100 mA 的數值；在 Ic = 150 mA 時 hFE 最小 **100（VCE = 10 V）**、**50（VCE = 1 V）**（S14、S15）。飽和看的是低 VCE 那一欄：40 < 50，仍會飽和，但**餘裕只有約 1.25 倍**。最差情況 Vce 可能落在 0.3–0.6 V，If 會降到約 90–100 mA（往安全方向）。想要更深的飽和，可把 1 kΩ 改成 **680 Ω**（Ib ≈ 3.8 mA、強制 β ≈ 27），仍遠低於 GPIO 的驅動能力。
- 建議的 10 kΩ B–E 下拉只分走約 0.07 mA，可忽略。

**為什麼不用 GPIO 直接驅動 LED**

ESP32-C3 單腳的驅動能力：高電位輸出 IOH 典型 **40 mA**（VDD = 3.3 V、VOH ≥ 2.64 V、PAD_DRIVER = 3）、低電位吸入 IOL 典型 **28 mA**（DS 表 5-4 p.56）。遠低於 100 mA，直驅會傷腳，而且 LED 電流小、發射距離很短。

**為什麼 LED 不從 3V3 供電**

- 3.3 V 扣掉 Vf 1.35 V 與 Vce 0.25 V 只剩約 1.7 V，電阻要降到約 17 Ω；Vf 每差 0.15 V，電流就差約 9 mA（約 9%），用 5 V 時只差約 4.5 mA（約 4%）。
- 100 mA 的脈衝會和 Wi-Fi 發射尖峰共用板上的 3.3 V LDO：SuperMini 的 3.3 V 來自 **ME6211**（S2 原理圖，SOT23-5 ME6211 3V3），原廠標示最大輸出電流 **500 mA**（S17）；ESP32-C3 的 Wi-Fi 發射峰值最高 **335 mA**（802.11b 1 Mbps @ 21 dBm，DS 表 5-7 p.57）。兩者相加已逼近 LDO 上限，容易造成電壓下陷、重開機。
- 所以 LED 從 **右排 #1 的 5V** 取電：依 Nologo 原理圖，這支腳直接接 USB VBUS（在 BAT60J 二極體與 LDO 之前，S2），LED 電流不經過 LDO。
- 注意：本設計假設由 USB 5V 供電。Nologo 說明 5V 腳可外接 3.3–6 V 電源（但不能同時接 USB，S2）；若改從 5V 腳外接電源，請用 5 V，否則 LED 電流會改變（例如 6 V 時約 133 mA）。

**LED 規格未確認時**

若實物 datasheet 的連續或脈衝電流上限**低於 100 mA**，把 33 Ω 改成 **47–68 Ω**（If 約 72–50 mA）。參考：TSAL6200 的連續 IF 上限 100 mA、脈衝 IFM 200 mA（tp/T = 0.5、tp = 100 µs，S16）。

## 7. ESPHome 對應設定（片段）

完整設定見 `firmware/`；以下只列與接線對應的部分。

```yaml
i2c:
  sda: GPIO4      # 右排 #4
  scl: GPIO5      # 左排 #1
  scan: true      # 開機 log 會列出掃到的位址：應有 0x38 與 0x77 或 0x76

sensor:
  - platform: aht10
    variant: AHT20
    temperature:
      name: "溫度"
    humidity:
      name: "濕度"
  - platform: bmp280_i2c
    address: 0x77     # SDO 接地的模組改 0x76
    temperature:
      name: "BMP280 溫度"
    pressure:
      name: "氣壓"

remote_transmitter:
  id: ir_tx
  pin: GPIO3          # 右排 #5，經 1 kΩ 到 Q1 基極
  carrier_duty_percent: 50%

remote_receiver:      # 必備：首次設定用它錄 RF11T1 的訊號、確認協定
  id: ir_rx
  pin:
    number: GPIO10    # 左排 #6
    inverted: true    # VS1838B 輸出低電位有效
  dump: all

climate:
  - platform: hitachi_ac344  # RF11T1 在文獻中對應 AC344（S20）；先用接收頭錄碼確認，不行再試 hitachi_ac424
    name: "冷氣"
    transmitter_id: ir_tx
    receiver_id: ir_rx  # 用原廠遙控器操作時，ESPHome 也能同步冷氣狀態
```

- `aht10` 元件以 `variant: AHT20` 支援 AHT20（S8）；`bmp280_i2c` 預設位址 0x77、另一個可選 0x76（S9）。
- ESPHome 的 IR 冷氣平台支援日立（Hitachi）的 `hitachi_ac344` 與 `hitachi_ac424`，兩者都支援接收頭（S11）。遙控器 RF11T1 沒有日立官方的協定資料；IRremoteESP8266 的支援清單把「RF11T1 remote」列為 HITACHI_AC344（S20），所以預設用 `hitachi_ac344`，但台灣機種仍**待實物確認**：先用 `dump: all` 按遙控器看 log，能解碼就選對應平台；只有 raw 輸出時先把 raw 碼存下來，再決定用 raw 發送或其他平台。
- 兩個日立平台的訊框分別是 43 bytes（344 bits）與 53 bytes（424 bits）（S19），約需 350／430 個 RMT symbol；ESPHome 文件列出 ESP32-C3 的 RMT 記憶體為每個方向 96 symbols（區塊 48）（S10）。長訊框要靠驅動分段接收，C3 能否完整收到，**待實機確認**；發射不受影響。
- 接收頭擺放：避開陽光、日光燈直射（強光含紅外線，會誤觸）；離 IR 發射 LED 遠一點或中間加遮擋，免得收到自己發出的訊號。

## 8. 待實物確認

1. SuperMini 的腳位與絲印：本表依 Nologo 原理圖與尺寸圖；仿板可能不同。到貨先用三用電表確認 5V、GND、3V3 的位置。
2. 第 1 腳中心距 USB 端板邊約 1.52 mm（估計，由尺寸圖比例推得）——只影響圖面位置，不影響接線。
3. 感測板的絲印腳序、是否內建 I²C 上拉、BMP280 位址（0x77 或 0x76）、SDO 焊點位置。
4. IR LED 型號、Vf 與連續／脈衝電流上限。
5. 電晶體的廠牌與腳序（E-B-C 或 C-B-E）。
6. VS1838B 的腳序：查不到原廠官方 datasheet；本文以常見的 OUT-GND-VCC 為準，並以同類 38 kHz 接收頭 Vishay TSOP382 的 `1 = OUT, 2 = GND, 3 = VS`（S18）作參考。
7. 日立遙控器 RF11T1 的協定（文獻對應 `hitachi_ac344`；也可能是 `hitachi_ac424` 或只能 raw），以及 C3 接收頭能否收到完整長訊框——用接收頭錄碼確認。
8. 每次發送時間 0.1–0.5 s 與 mark／space 約各半是估計值。

## 9. 來源清單

查閱日期皆為 2026-11-15。類別：官方＝元件或開發板原廠、晶片原廠、該軟體專案自己的文件；文章＝第三方技術文件；估計＝推算。

| 代號 | 用來核對的事實 | 來源 | 類別 |
|---|---|---|---|
| S1 | ESP32-C3 腳位功能、strapping（GPIO2/8/9）、JTAG（GPIO4–7）、UART0（GPIO20/21）、USB（GPIO18/19）、flash（GPIO11–17）、XTAL_32K（GPIO0/1）、重置狀態、開機毛刺、RMT 通道數、IOH/IOL、Wi-Fi 發射峰值電流（Datasheet v2.5：表 2-1 p.16、表 2-2 p.18、表 2-4 p.19–20、表 2-6 p.21、§2.3.3 p.22、§2.3.4 p.23、表 2-7 p.24、表 2-12 p.29、表 3-1 p.30、表 3-3 p.31、§4.2.1.8 p.50、表 5-4 p.56、表 5-7 p.57） | https://www.espressif.com/sites/default/files/documentation/esp32-c3_datasheet_en.pdf | 官方 |
| S2 | SuperMini 原理圖（H1/H2 排針對應、5V 腳＝VBUS、BAT60J、ME6211 3V3、GPIO8 藍 LED、GPIO9 BOOT 鍵、只有 40 MHz 晶振）、尺寸圖（22.52 × 18 mm、兩排中心距 15.24 mm、絲印 5V/G/3.3/21/0、天線在 USB 對側）、晶片 ESP32-C3FN4、外接電源說明 | https://www.nologo.tech/product/esp32/esp32c3/esp32c3supermini/esp32C3SuperMini.html | 官方 |
| S3 | SuperMini 元件面腳位圖（左排 GPIO5–10、20、21；右排 5V、GND、3V3、GPIO4–0），與 S2 交叉核對 | https://www.espboards.dev/esp32/esp32-c3-super-mini/ | 文章 |
| S4 | Arduino-ESP32 的 SuperMini variant：`SDA = 8`、`SCL = 9`、`LED_BUILTIN = 8`、`TX = 21`、`RX = 20` | https://github.com/espressif/arduino-esp32/blob/master/variants/nologo_esp32c3_super_mini/pins_arduino.h | 官方 |
| S5 | Zephyr 的 SuperMini 板級定義：藍 LED GPIO8（低電位有效）、使用者按鍵 GPIO9、I²C 預設 SDA = GPIO9／SCL = GPIO10 | https://docs.zephyrproject.org/latest/boards/others/esp32c3_supermini/doc/index.html 、 https://github.com/zephyrproject-rtos/zephyr/blob/main/boards/others/esp32c3_supermini/esp32c3_supermini.dts | 文章 |
| S6 | BMP280 I²C 位址 0x76／0x77 與 SDO 接法、SDO 不可浮接、SDA 需上拉、VDD/VDDIO 上限 3.6 V（Datasheet rev 1.26：§5.2 p.28、表 2 p.7、表 3 p.9） | https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmp280-ds001.pdf | 官方 |
| S7 | AHT20 I²C 位址 0x38（p.12）、供電 2.2–5.5 V 與上拉電源須來自 VDD（p.9）（Datasheet V1.0） | https://www.aosong.com/userfiles/files/media/Data%20Sheet%20AHT20.pdf | 官方 |
| S8 | ESPHome `aht10` 元件 `variant: AHT20` | https://esphome.io/components/sensor/aht10/ | 官方 |
| S9 | ESPHome `bmp280_i2c` 預設位址 0x77、另可 0x76 | https://esphome.io/components/sensor/bmp280/ | 官方 |
| S10 | ESPHome `remote_transmitter`：IR 用 `carrier_duty_percent: 50%`、ESP32-C3 RMT 記憶體 96 symbols、`eot_level` 預設 false | https://esphome.io/components/remote_transmitter/ | 官方 |
| S11 | ESPHome IR 冷氣平台：日立（Hitachi）為 `hitachi_ac344`、`hitachi_ac424`，支援接收頭 | https://esphome.io/components/climate/climate_ir/ | 官方 |
| S11b | ESPHome `remote_receiver` 的 `pin`、`dump` 設定 | https://esphome.io/components/remote_receiver/ | 官方 |
| S19 | ESPHome 日立平台訊框長度：`HITACHI_AC344_STATE_LENGTH = 43`、`HITACHI_AC424_STATE_LENGTH = 53`（bytes） | https://github.com/esphome/esphome/blob/dev/esphome/components/hitachi_ac344/hitachi_ac344.h 、 https://github.com/esphome/esphome/blob/dev/esphome/components/hitachi_ac424/hitachi_ac424.h | 官方 |
| S20 | IRremoteESP8266 支援清單：「RF11T1 remote (HITACHI_AC344)」 | https://github.com/crankyoldgit/IRremoteESP8266/blob/master/SupportedProtocols.md | 文章 |
| S12 | onsemi SS8050（頂面印字 S8050B/C/D）：TO-92 腳序 1 = E、2 = B、3 = C；hFE 最小 85（VCE = 1 V、Ic = 100 mA） | https://www.onsemi.com/download/data-sheet/pdf/ss8050-d.pdf | 官方 |
| S13 | UTC S8050：TO-92 腳序 E-B-C；hFE 最小 120（VCE = 1 V、Ic = 150 mA）（UTC datasheet，經 components101 轉載） | https://components101.com/sites/default/files/component_datasheet/S8050%20Transistor%20Datasheet.pdf | 官方 |
| S14 | onsemi PN2222A：TO-92 腳序 E-B-C；hFE 最小 100（Ic = 150 mA、VCE = 10 V）、50（Ic = 150 mA、VCE = 1 V） | https://www.onsemi.com/download/data-sheet/pdf/pn2222a-d.pdf | 官方 |
| S15 | onsemi P2N2222A：TO-92 STYLE 17 腳序 1 = C、2 = B、3 = E；hFE 同 S14 | https://www.onsemi.com/download/data-sheet/pdf/p2n2222a-d.pdf | 官方 |
| S16 | 參考用 940 nm 5 mm IR LED（Vishay TSAL6200，非本專案指定型號）：IF 100 mA、IFM 200 mA（tp/T = 0.5、tp = 100 µs）、Vf 典型 1.35 V／最大 1.6 V @ 100 mA | https://www.vishay.com/docs/81010/tsal6200.pdf | 官方 |
| S17 | ME6211 最大輸出電流 500 mA、最大輸入 6.5 V（原廠 LDO 產品表） | https://www.microne.com.cn/ldo%e7%ba%bf%e6%80%a7%e7%a8%b3%e5%8e%8b%e5%99%a8 | 官方 |
| S18 | 參考用 38 kHz 接收頭（Vishay TSOP382，非 VS1838B）：腳序 1 = OUT、2 = GND、3 = VS；供電 2.0–5.5 V；輸出低電位有效 | https://www.vishay.com/docs/82491/tsop382.pdf | 官方 |
| E1 | 第 1 腳中心距 USB 端板邊約 1.52 mm（由 S2 尺寸圖比例推得） | — | 估計 |
| E2 | 每次 IR 發送約 0.1–0.5 s、mark／space 約各半、平均功率約峰值 25% | — | 估計 |

### SuperMini 腳位交叉核對結果

- S2 原理圖（H1/H2）＋S2 尺寸圖（元件面絲印）＋S3 元件面腳位圖：16 支腳的位置**完全一致**。
- S4（Arduino variant）與 S5（Zephyr）對 LED＝GPIO8、BOOT＝GPIO9、UART0＝GPIO20/21 的描述與 S2 一致。
- 需要注意的差異：
  - S2 產品頁的「引腳圖」是**背面視圖**（5V 在左），尺寸圖與 S3 是元件面（5V 在右）。不是矛盾，但很容易看錯；本專案一律用元件面。
  - S3 把 GPIO4–7 標成「bootstrapping」，與 Espressif 官方不符（官方的 strapping 只有 GPIO2、8、9，GPIO4–7 是 JTAG）；本表以官方 datasheet 為準。
  - 預設 I²C 腳各家不同（Arduino：8/9；Zephyr：9/10）；本專案刻意用 4/5。
