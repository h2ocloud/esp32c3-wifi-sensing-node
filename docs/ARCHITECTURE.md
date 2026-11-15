# 架構

```
           2.4 GHz Wi-Fi（固定一台基地台）
  [基地台] <──── ping／回覆封包 ────> [ESP32-C3 SuperMini]
                                         │  ESPHome 2026.10
                                         │  ├─ espectre：CSI → Movement Score → Motion
       [AHT20+BMP280] ── I²C (GPIO4/5) ──┤  ├─ aht10(AHT20)、bmp280_i2c
                                         │  ├─ remote_transmitter (GPIO3) → climate: hitachi_ac344
  [IR LED 940 nm] <─ NPN ← GPIO3 ────────┤  ├─ remote_receiver (GPIO10)：錄碼＋追蹤遙控器
  [VS1838B] ── OUT → GPIO10（必備）──────┤  ├─ api（HA 自動探索）、web_server、prometheus
                                         │  └─ mqtt（選配，預設關）
                                         ▼
                 [Home Assistant]   [HTTP JSON / SSE]   [Prometheus /metrics]
```

## 實體配置（外殼）
- 壁掛時長軸垂直：**感測器在下格**（冷空氣從下方與兩側格柵進來）、**C3 在上格**（熱往上排）、中間雙層隔牆＋通風縫。
- **天線端淨空**：C3 的陶瓷天線朝側牆，前方約 8 mm 只有空氣；線束、螺絲、感測器、紅外線電路都不放在天線區。
- 紅外線 LED 朝冷氣方向開孔；接收頭（必備）窗口朝室內、遠離發射 LED（R2 外殼：上端右側 Ø8 接收窗，與發射相距 25.4 mm）。

## 資料流
- 動作：每 250 ms（預設評估週期）更新移動分數；Motion 只在狀態改變時送出。
- 環境：每 60 秒一次（`env_update_interval`）。
- 冷氣：Home Assistant／HTTP 下指令 → 送一次完整的日立 AC344 狀態幀（43 bytes）；冷氣沒有回饋。接收頭聽到 RF11T1 遙控器的訊號且解得出來時，更新 HA 上的「預期狀態」（只代表遙控器按了什麼）。
- 第一次設定：先燒 `ir-learn.yaml` 逐鍵錄碼確認協定（`docs/IR_HITACHI.md`）。
