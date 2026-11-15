# 介面：Home Assistant、HTTP JSON、/metrics、MQTT

> 回應範例是依 ESPHome 2026.10.2 原始碼整理的**格式示意**，不是實機輸出。

## Home Assistant（ESPHome 原生 API，自動探索）

| 類別 | 實體名稱 | 說明 |
|---|---|---|
| binary_sensor | Motion | ESPectre 判斷：有動／沒動 |
| binary_sensor | Calibrating | 校準中（診斷） |
| sensor | Movement Score | 移動分數 0–1，每次評估都更新（預設 250 ms；量很大，建議在 HA recorder 排除） |
| sensor | CSI Accepted Rate、CSI Occupancy、Traffic RX Rate | 診斷；按 Refresh 才更新 |
| sensor | Temperature、Humidity | AHT20 |
| sensor | Pressure、BMP280 Temperature | BMP280（後者為診斷） |
| sensor | Wi-Fi Signal、Uptime | 診斷 |
| select | CSI Traffic Source | ping／dns／dns_tcp／wifi_raw／external |
| button | Recalibrate、Restart | |
| climate | Hitachi AC | 日立 AC344：模式（OFF＝關、COOL、DRY、FAN_ONLY）、目標溫度 16–32 °C、風速（AUTO、LOW、MEDIUM、HIGH）、擺風（OFF、HORIZONTAL）；目前溫度／濕度來自 AHT20；接收頭聽到遙控器時更新「預期狀態」 |

## HTTP（ESPHome `web_server` v3，port 80）

ESPHome 2026.10 的 URL 用**實體名稱**（空白寫成 `%20`）。只在受信任的區網使用；要保護就打開 `web_server.auth`。

| 方法 | 路徑 | 說明 |
|---|---|---|
| GET | `/` | 內建網頁（前端 JS 從網路載入） |
| GET | `/sensor/Temperature` | `{"id":"sensor/Temperature","value":25.1,"state":"25.1 °C"}` |
| GET | `/sensor/Humidity`、`/sensor/Pressure`、`/sensor/Movement%20Score` | 同上 |
| GET | `/binary_sensor/Motion` | `{"id":"binary_sensor/Motion","value":false,"state":"OFF"}` |
| GET | `/climate/Hitachi%20AC` | 預期狀態：mode、target_temperature、current_temperature、fan_mode、swing_mode…（不是冷氣真實狀態） |
| POST | `/climate/Hitachi%20AC/set?mode=COOL&target_temperature=26&fan_mode=AUTO` | 送紅外線指令。`mode`：OFF、COOL、DRY、FAN_ONLY（`supports_heat: false`）；`fan_mode`：AUTO、LOW、MEDIUM、HIGH；`swing_mode`：OFF、HORIZONTAL |
| POST | `/button/Recalibrate/press` | 重新校準 |
| GET | `/events` | Server-Sent Events，狀態變化即時推送 |
| GET | `/metrics` | Prometheus 格式（`prometheus` 元件） |

```bash
curl -s http://wifi-node.local/sensor/Temperature
curl -s -X POST "http://wifi-node.local/climate/Hitachi%20AC/set?mode=COOL&target_temperature=26"
curl -s http://wifi-node.local/metrics
```

`wifi-node.local` 是韌體預設的 mDNS 名稱，只在同一個區網內解析得到；多台時請改 `device_name`。

### 為什麼不像前一個專案自己寫 `/api/v1/...`

前一個專案（機房溫濕度感測器）用 Arduino 自寫 HTTP API（latest、history、health、metrics）。這次改用 ESPHome：每個實體自動有 JSON 端點、可以 POST 控制冷氣、`/metrics` 由 prometheus 元件提供，不用維護自己的 HTTP 程式碼。差別：**裝置上沒有歷史緩衝**（歷史交給 Home Assistant recorder 或 Prometheus），也沒有自訂的 health JSON（用 Wi-Fi Signal、Uptime 實體代替）。

## MQTT（選配，預設關）

打開 `packages/mqtt.yaml`：broker、帳號、密碼都從 `secrets.yaml` 讀；topic 前綴預設 `wifi-node/`，例如 `wifi-node/sensor/temperature/state`、`wifi-node/climate/hitachi_ac/mode/command`。`discovery: false`（已有 HA API 時避免重複）；只用 MQTT 時改成 true。
