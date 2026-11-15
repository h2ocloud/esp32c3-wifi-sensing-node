# 韌體：路線選擇、需求、建置與已知限制

> 狀態：ESPHome 2026.10.2 編譯通過（8 種設定組合），**尚未燒進實機**。

## 1. 為什麼選 ESPHome 內建的 `espectre`

ESPectre（https://github.com/francescopace/espectre ，GPL-3.0-only）提供 ESPHome、Native、Matter 三種前端，另有給研究用的 MicroPython 版。

| 路線 | 優點 | 缺點 | 本專案 |
|---|---|---|---|
| **ESPHome 內建 `espectre`**（ESPHome 2026.10 起） | 不用拉外部元件；可和 `aht10`、`bmp280_i2c`、`climate: hitachi_ac344` 寫在同一份 YAML；Home Assistant 自動探索 | 沒有 ESPectre 的 Direct API（瀏覽器工具），需要時要加 `espectre_direct` 附加元件；可調項目比外部元件少 | **採用** |
| ESPHome external component（從 GitHub 拉） | 功能最完整、含 Direct API | 上游已標示淘汰，預計 ESPectre 3.3 移除 | 不採用 |
| Native／Matter 韌體 | 官方映像檔、瀏覽器燒錄 | 不能加自己的感測器與紅外線 | 不採用 |

上游的 C3 範例（`espectre-c3.yaml`）註明 ESP32-C3 Super Mini 由社群驗證過；範例本身使用 external component，本專案改用內建元件。

## 2. 版本與框架需求

| 項目 | 需求 | 本專案編譯實際使用 |
|---|---|---|
| ESPHome | ≥ 2026.10（內建 `espectre`） | 2026.10.2 |
| 框架 | ESP-IDF ≥ 5.5.3，或 Arduino ≥ 3.3.7（元件 schema 的 `require_framework_version`） | ESP-IDF 5.5.6 |
| ESPectre SDK | ESPHome 釘選的 ESP-IDF 元件 | `francescopace/espectre` 3.0.0 |
| 晶片 | ESP32、S2、S3、C3、C5、C6 | ESP32-C3（board `esp32-c3-devkitm-1`，4 MB） |
| Python | ESPHome 2026.10.2 要求 3.12–3.14 | 3.12（venv） |

## 3. CSI 需要流量

CSI（通道狀態資訊）是 Wi-Fi 晶片在**收到封包時**順便算出來的，所以必須有穩定的封包流。

- 預設 `traffic_generator_mode: ping`：節點自己 ping **預設閘道**，用回覆封包取得 CSI，不需要任何設定。
- 要 ping 別台（例如閘道擋 ICMP）：打開 `packages/csi-ping-target.yaml`，目標寫在 `secrets.yaml` 的 `csi_ping_target`。範本值 `192.0.2.1` 是 RFC 5737 文件專用位址（沒有人會回），**一定要換成自己網路裡一直開著、會回 ping 的主機**。設定檔裡不寫死任何 IP。
- 其他模式：`dns`、`dns_tcp`、`wifi_raw`、`external`（例如 Home Assistant 的 ESPectre Traffic Generator 附加元件），見上游文件。
- 網路要允許這些區網流量；有用戶端隔離（client isolation）的訪客網路通常不行。

## 4. 元件自動做的設定（已在編譯產物的 sdkconfig 確認）

- `CONFIG_ESP_WIFI_CSI_ENABLED=y`
- 關閉 AMPDU TX／RX（CSI 每個封包回報一次，聚合會吃掉樣本；整機 Wi-Fi 吞吐量會下降）
- **Wi-Fi 省電關閉**（`wifi.force_power_save_off`，連斷線時的省電也關）：無線電一直醒著 → 耗電、發熱比一般 ESPHome 裝置高
- **停止 ESPHome 的週期漫遊掃描**（掃描會讓無線電離開頻道好幾秒、打斷偵測）；失去基地台時仍會正常重連

## 5. 記憶體（編譯結果；RAM＝靜態配置，Flash＝應用程式分區 1,835,008 B）

| 設定 | RAM | Flash |
|---|---|---|
| 預設（CSI＋AHT20/BMP280＋IR 發射＋VS1838B 接收＋`hitachi_ac344`＋web_server＋prometheus） | 34.2%（109,842 B） | 61.0%（1,118,484 B） |
| ＋學習碼按鈕（`ir-raw-scenes`） | 34.2% | 61.1% |
| ＋MQTT | 35.4% | 67.7% |
| 全部選配 | 35.5% | 67.9% |
| 錄碼韌體（`ir-learn.yaml`：Wi-Fi＋API log＋dump all＋AC344／AC424 解碼，不含 ESPectre） | 33.4% | 52.8% |

- web_server＋prometheus：靜態 RAM ＋320 B、Flash ＋約 38.3 KiB；**執行期** HTTP 伺服器工作與連線緩衝在 heap，要實機才量得到。
- 紅外線發射＋接收＋日立 climate：靜態 RAM ＋5,158 B、Flash ＋50,458 B；接收緩衝（`receive_symbols: 512`，每個 symbol 4 B，預設 4 組）約 8 KB 在 heap，未計入。
- 4 MB flash、預設雙 OTA 分區，OTA 更新空間足夠。

## 6. RMT 資源與日立長幀

ESP32-C3 的 RMT 有 2 個發送、2 個接收通道（ESP-IDF `SOC_RMT_TX/RX_CANDIDATES_PER_GROUP=2`）。紅外線發射用 1 個 TX；VS1838B 接收用 1 個 RX。ESPectre 不使用 RMT。

日立 AC344 一幀 344 bit＋標頭＋結尾 ≈ 346 個 RMT symbol，比 C3 每個接收通道的硬體記憶體（96 symbol）長。C3 支援接收 ping-pong（編譯產物 sdkconfig：`SOC_RMT_SUPPORT_RX_PINGPONG=y`），所以設定 `receive_symbols: 512` 讓驅動分段接續；**能不能完整收到長幀要實機確認**（發射不受影響）。收不完整時 `ir-learn.yaml` 的 raw 會被截斷、climate 解不出來，這時可試著把接收頭移近遙控器、或回報上游。

## 7. 日立冷氣（遙控器 RF11T1）

- 預設 `climate: hitachi_ac344`（IRremoteESP8266 支援清單：RF11T1 → HITACHI_AC344）；`receiver_id: ir_rx` 追蹤遙控器操作；`supports_heat: false`（RF11T1 沒有暖氣鍵）。
- 第一次設定先燒 `ir-learn.yaml` 逐鍵錄碼確認協定；解成 AC424 就換 `hitachi_ac424`；都解不出來用 `packages/ir-raw-scenes.yaml` 的學習碼固定情境。
- 細節：`docs/IR_HITACHI.md`。

## 8. 建置與燒錄

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install "esphome==2026.10.2"
cd firmware && cp secrets.example.yaml secrets.yaml   # 填自己的值
esphome config wifi-node.yaml                         # 先驗證設定
esphome compile wifi-node.yaml
esphome run ir-learn.yaml                             # 第一次：錄 RF11T1 遙控碼、確認協定
esphome run wifi-node.yaml                            # USB 燒錄並看 log
```

- C3 SuperMini 走內建 USB-Serial/JTAG，macOS 上通常是 `/dev/cu.usbmodem*`。
- 燒不進去：按住 BOOT → 點一下 RST → 放開 BOOT；部分副廠板 QIO 不穩時，打開 `esp32.flash_mode: dio`。
- 第一次開機：看 log 的 I²C 掃描（0x38、0x76／0x77）、Wi-Fi 連線、ESPectre 校準完成。校準期間房間保持安靜。
- Home Assistant：設定 → 裝置與服務 → ESPHome 會出現 `wifi-node`；開機 15 分鐘內完成配對。

## 9. 已知限制（韌體面）

- 未實機驗證：CSI 偵測品質、誤報率、I²C 位址、日立 RF11T1 協定（AC344？）、接收頭長幀都還沒測。
- 溫度讀值受板子發熱影響，建議和參考溫度計比對後在 `sensor` 加 `filters: - offset:`。
- 一台只顧一個空間；Mesh 網路建議固定連同一台基地台。
- 編譯時的兩條 provisioning 警告與處理方式見 `docs/SECURITY.md`。
