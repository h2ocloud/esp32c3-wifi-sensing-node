# firmware/

| 檔案 | 用途 |
|---|---|
| `wifi-node.yaml` | 主設定：ESPectre（CSI 動作）＋AHT20/BMP280＋紅外線控制日立冷氣（遙控器 RF11T1，`hitachi_ac344`）＋HA API＋web_server＋/metrics |
| `wifi-node-dht11.yaml` | **R3 麵包板版**：同上，但溫濕度改用 DHT11 三腳模組（`dht` 平台、`model: DHT11`、DATA＝GPIO4），沒有氣壓；接線見 `../docs/BREADBOARD_R3.md` |
| `secrets.example.yaml` | 帳密範本（假值）。複製成 `secrets.yaml` 再填；`secrets.yaml` 已 gitignore |
| `packages/csi-ping-target.yaml` | 選配：指定 CSI ping 目標（預設 ping 預設閘道） |
| `packages/mqtt.yaml` | 選配：MQTT |
| `packages/ir-hardware.yaml` | 紅外線發射（GPIO3）＋VS1838B 接收（GPIO10，必備）；主設定與 `ir-learn.yaml` 共用 |
| `packages/ir-raw-scenes.yaml` | 備案：學習到的 raw／pronto 固定情境按鈕（碼為佔位，要換成自己錄的） |
| `ir-learn.yaml` | 錄遙控碼、確認協定：`dump: all`（含 raw、pronto）＋`hitachi_ac344`／`ac424` 解碼；保留 Wi-Fi 與 API log；不含 ESPectre |

授權：GPL-3.0-only（理由見 `../docs/licensing.md`）。狀態：ESPHome 2026.10.2 編譯通過，尚未實機驗證。

用哪一份：手上是 AHT20+BMP280 小板、照 R2 接線 → `wifi-node.yaml`；手上是 DHT11 三腳模組、照 R3 麵包板接線 → `wifi-node-dht11.yaml`。兩份的紅外線腳位（`packages/ir-hardware.yaml`）與錄碼韌體 `ir-learn.yaml` 共用。
建置步驟、版本需求、已知限制：`../docs/FIRMWARE.md`；介面：`../docs/API.md`；日立冷氣協定與逐鍵錄碼：`../docs/IR_HITACHI.md`。
