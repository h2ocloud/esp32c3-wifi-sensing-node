# 紅外線控制日立冷氣（遙控器 RF11T1）：協定確認、逐鍵錄碼與備案

> 狀態：**只做了編譯驗證，尚未對冷氣實測。** RF11T1 對應 `HITACHI_AC344` 是文獻上的對應，台灣機種要用接收頭確認後才算數。

## 1. 已知線索（間接證據）

| 線索 | 內容 | 來源 |
|---|---|---|
| IRremoteESP8266 支援清單 | `Brand: Hitachi, Model: RF11T1 remote (HITACHI_AC344)`；同協定還有 RF07T4 遙控器、RAS-22NK 冷氣 | https://github.com/crankyoldgit/IRremoteESP8266/blob/master/src/ir_Hitachi.h （檔頭支援清單） |
| AC344 協定格式 | 43 bytes（344 bit）、38 kHz；標頭 3300／1700 µs、位元亮 400 µs、「1」暗 1250 µs、「0」暗 500 µs；用反相位元組對檢查，不是傳統 checksum | ESPHome 2026.10.2 `hitachi_ac344.h` 常數；IRremoteESP8266 `kHitachiAc344StateLength = 43` |
| ESPHome 平台 | `climate: platform: hitachi_ac344`（另有 `hitachi_ac424`），可搭配 `receiver_id` 追蹤遙控器操作 | https://esphome.io/components/climate/climate_ir/ |
| ESPHome 實測紀錄 | 新增 `hitachi_ac344` 的 PR 說明：測試過 RAS-22YK1／25YK1／36YK1 冷氣與 **RF10T1** 遙控器（不是 RF11T1） | https://github.com/esphome/esphome/pull/1336 |
| 已知問題 | 有人回報 `hitachi_ac344`／`ac424` 的擺風在某些機型沒反應（issue 仍開著） | https://github.com/esphome/issues/issues/4977 |

**結論：** 很可能是 AC344，但沒有人在本專案的機種上實測過；所以第一次設定一定要用接收頭錄碼確認（第 3 節）。

### ESPHome `hitachi_ac344` 支援什麼（2026.10.2 原始碼）

| 項目 | 支援 |
|---|---|
| 模式 | 關、冷氣、除濕、送風（本專案設 `supports_heat: false`；協定本身也有暖氣、自動） |
| 溫度 | 16–32 °C，1 °C 一級（以實機為準） |
| 風速 | 自動、低、中、高 |
| 擺風 | 關、左右擺風（原始碼另有上下擺風的切換位元，但 ESPHome 的擺風選項只開放「關／左右」） |
| 接收解碼 | 有（`receiver_id`） |
| **不支援** | RF11T1 上的睡眠、快速、節能、定時、防霉等鍵沒有對應的 Home Assistant 控制項（協定裡有部分按鍵碼，但平台沒有開放）；要用的話走第 5 節的學習碼備案 |

## 2. 你需要

- 接好的 VS1838B 接收頭（**必備**）：VCC→3V3、GND→GND、OUT→GPIO10。腳序以實物為準（常見：面對圓頂、腳朝下，由左到右 OUT、GND、VCC）。
- 接收頭不要被陽光或日光燈直射（環境中的紅外線會造成雜訊）；離 IR 發射 LED 遠一點或有遮擋，避免收到自己發的訊號。
- 原本的 RF11T1 遙控器、USB 線、電腦上的 ESPHome。

## 3. 逐鍵錄碼流程

1. **燒錄碼韌體**：`cd firmware && esphome run ir-learn.yaml --device <序列埠>`。燒完會直接顯示 USB log；之後也可以經 Wi‑Fi 看：`esphome logs ir-learn.yaml`。
2. **遙控器對著接收頭**（約 30 cm–1 m），**一次按一個鍵，按完等 2 秒**，看 log 印了什麼。
3. **照順序按下面每一個鍵**，把結果填進第 6 節的表格：
   開機 → 關機 → 開機 → 冷氣模式 → 設定 24 °C → 溫度＋ → 溫度− → 風速（按到每一段）→ 上下擺風 → 左右擺風 → 睡眠 → 快速 → 節能 → 定時 → 除濕 → 防霉。
4. **判讀 log**：
   - 出現 `climate.hitachi_ac344` 的明細（VERBOSE）、且 `Learn AC344` 的狀態跟著變（模式、溫度、風速）→ **解成 AC344**，主設定可以直接用。
   - 是 `Learn AC424` 跟著變 → 解成 AC424：把 `wifi-node.yaml` 的 `platform: hitachi_ac344` 改成 `hitachi_ac424`。
   - 只有 `[remote.raw] Received Raw` 和 `[remote.pronto] Received Pronto`，兩個 climate 都沒變 → 不是這兩種格式，走第 5 節備案。
   - 什麼都沒印 → 先查接收頭接線、腳序、供電；再確認遙控器有電（用手機相機看遙控器前端會不會閃）。
5. **看 raw 也能大致判斷**：AC344 的 raw 開頭約為 `3300, -1700`，之後是 400 與 −1250／−500 交替；一幀約 690 個數字。AC424 的標頭約 `3416, -1604`、位元亮約 463。接收誤差設 ±25%，看比例即可。

## 4. 用 `hitachi_ac344` 發射並實測

1. 燒回主設定：`esphome run wifi-node.yaml`。
2. 先用手機相機對著 IR LED（多數手機前鏡頭看得到 940 nm），在 Home Assistant 切換冷氣模式，畫面上應該看到 LED 閃。
3. LED 對準冷氣的接收窗，1–3 m、中間沒有遮擋：試「冷氣 24 °C 自動風」→「關」。
4. **沒反應時的排查清單**
   - LED 方向：發射角只有約 ±20°，要對準冷氣接收窗。
   - 距離：先在 1 m 內試。
   - 5 V 電流：用三用電表量 33 Ω 兩端電壓（約 3.4 V＝約 100 mA 脈衝時的峰值；平均值會低很多）；LED 長短腳、電晶體 E／B／C 腳序是否接對。
   - 載波：日立 AC344 是 38 kHz（平台自動設定）；`carrier_duty_percent` 50%。
   - 重複次數：ESPHome 的 AC344 每次只送一次（`repeat = 0`）；冷氣偶爾收不到時再按一次，或在自動化裡送兩次。
   - 擺風沒反應：已知問題（issue #4977），先確認其他功能正常即可。
   - 接收頭先收到自己發的訊號、HA 狀態被蓋掉：把接收頭和 LED 隔開或加遮擋。
5. 用遙控器按一下，若 Home Assistant 的冷氣狀態跟著變，代表 `receiver_id` 的追蹤也正常（注意：這只代表「遙控器按了什麼」）。

## 5. 備案：學習碼固定情境（hitachi_ac344 不能用時）

如果解不出來、或發射後冷氣沒反應、或想用睡眠／快速／節能／防霉等平台沒有的功能：

1. 用 `ir-learn.yaml` 錄下想要的情境：例如「冷氣 24 °C 自動風」「關機」「除濕」「睡眠」。日立冷氣遙控器每次送的是**完整狀態**，所以錄下來的一幀就代表「那個當下的全部設定」。
2. 從 log 複製 `Received Raw: …` 的數字（或 `Received Pronto: …` 的字串）。
3. 貼進 `firmware/packages/ir-raw-scenes.yaml` 對應按鈕的 `code:`（raw）或 `data:`（pronto），把佔位值換掉；需要更多情境就複製一段按鈕。
4. 在 `wifi-node.yaml` 的 `packages` 打開 `ir_raw_scenes`，重新編譯燒錄。Home Assistant 會出現對應的按鈕；也可以在自動化或 script 裡呼叫。
5. 想讓 `climate` 實體消失、只留按鈕：把 `climate:` 整段註解掉即可。

**限制：** 每個按鈕都是固定情境，不能任意調溫度；Home Assistant 不知道冷氣目前的狀態；遙控器改了設定也不會同步。raw 碼很長（約 690 個數字），貼的時候不要漏掉。

## 6. 逐鍵紀錄表（請填寫）

| 按鍵 | log 解碼結果（AC344／AC424／只有 raw／沒收到） | 狀態有沒有正確變化 | 用 ESPHome 發射是否可用 | 備註 |
|---|---|---|---|---|
| 開機 | | | | |
| 關機 | | | | |
| 冷氣模式 | | | | |
| 設定 24 °C | | | | |
| 溫度＋ | | | | |
| 溫度− | | | | |
| 風速（各段） | | | | |
| 上下擺風 | | | | |
| 左右擺風 | | | | |
| 睡眠 | | | | |
| 快速 | | | | |
| 節能 | | | | |
| 定時 | | | | |
| 除濕 | | | | |
| 防霉 | | | | |

填好之後歡迎回報到 repo 的 issue，讓下一個用 RF11T1 的人少走冤枉路。

## 7. 已知限制

- **協定尚待實機驗證**：RF11T1→AC344 只是文獻對應。
- **單向**：節點只會送，冷氣不會回報；Home Assistant 顯示的是「最後送出的指令」或「接收頭聽到遙控器按了什麼」，**不是冷氣的真實狀態**。
- **不同步**：接收頭沒聽到（角度、距離、被擋住）或協定解不出來時，遙控器的操作 Home Assistant 不會知道。
- **視線可達**：紅外線會被牆、家具、窗簾擋住；殼上的 LED 孔要朝冷氣。
- **進階鍵不一定支援**：睡眠、快速、節能、定時、防霉等鍵沒有對應控制項。
- **溫度範圍** 16–32 °C 依 ESPHome 平台，實機可能不同。

## 8. 延伸閱讀：TaiSEIA 有線介面（本專案不實作）

台灣日立部分機型有原廠 Wi‑Fi 模組接口（TaiSEIA），可以用有線序列通訊取得冷氣的真實狀態並控制。有人做過 ESPHome 範例：https://github.com/xangin/TaiSEIA_ESPhome_samples （該 repo 未標示授權，本專案沒有使用其程式碼）。本專案維持紅外線路線：不用拆冷氣、不碰冷氣內部電路。

## 9. 和其他冷氣品牌的協定比較

日立的紅外線協定和大金、三菱等品牌完全不同；ESPHome 也是每個品牌（甚至每種格式）一個平台。換冷氣品牌時，要換 `climate` 的 `platform`，並重新用 `ir-learn.yaml` 確認。
