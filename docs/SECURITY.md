# 安全與隱私

## 帳密
- Wi-Fi SSID／密碼、fallback AP 密碼、OTA 密碼、選配的 MQTT／web 帳密都放在 `firmware/secrets.yaml`，**已列入 .gitignore**；repo 只有 `secrets.example.yaml`（假值）。
- 編譯後的映像檔（`.esphome/`、`*.bin`）含有帳密，不要分享、不要上傳。
- Home Assistant API 金鑰**不寫在任何檔案**：`api.encryption` 不設 `key`，第一次被 Home Assistant 連上時才配發（ESPHome 2026.10 執行期佈建）。

## ESPHome 編譯時的兩條警告與處理
1. `provisioning is configured, but credentials are set in the configuration for: wifi`：本專案為了一般 ESPHome 用法，Wi-Fi 仍由 `secrets.yaml` 編進韌體；佈建時間窗主要用來限制 **API 金鑰**的配發時機。
2. `The 'api' encryption key provisioned at runtime also authenticates OTA uploads`：拿到 API 金鑰的人也能 OTA 上傳韌體。因此加了 `provisioning: timeout: 15min`：只有開機後 15 分鐘內接受第一次配對；之後要重新配對就重開機。**請只在自己的網路配對。**

## 網路
- HTTP（web_server、`/metrics`）預設沒有登入，**只能在受信任的區網使用，不要做連接埠轉發**。需要時打開 `web_server.auth`。
- 要從外面看，走 Home Assistant 的遠端存取或 VPN。
- 韌體不連任何雲端服務；mDNS 名稱預設 `wifi-node`（不含個人資訊）。

## 隱私
CSI 沒有影像與聲音，但「什麼時候有人在動」能看出作息、睡眠與家中無人的時段。資料只留在自己的 Home Assistant；分享截圖或資料前請先想清楚。
