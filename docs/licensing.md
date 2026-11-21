# 授權說明與理由

| 部分 | 授權 | 理由 |
|---|---|---|
| `firmware/`（ESPHome YAML） | **GPL-3.0-only** | 見下 |
| `cad/`、`wiring/`、`bom/`、`hardware/r3/`（R3 麵包板版） | **CERN-OHL-P-2.0** | 硬體預設採寬鬆型開源硬體授權，方便改作與製造 |
| `wiring/` 內自繪的元件圖（SuperMini、感測板、電晶體、LED、接收頭） | **CC0-1.0** | 讓別人可以直接拿去畫自己的圖 |
| `docs/` | 跟著所描述的部分：韌體相關（FIRMWARE、API、IR_HITACHI、SECURITY）GPL-3.0-only；硬體相關（PRINTING、ARCHITECTURE）CERN-OHL-P-2.0 | 避免文件與所描述的程式碼授權不一致 |

## 為什麼韌體是 GPL-3.0-only，而不是預設的 MIT

1. 韌體編譯時會把 ESPectre SDK（ESP-IDF 元件 `francescopace/espectre`，**GPL-3.0-only**）與 ESPHome 的 C++ 執行程式碼（**GPLv3**）連結成一個映像檔。
2. ESPectre 的 `LICENSING.md` 明寫：散布結合 ESPectre 的韌體時，整體必須以 GPLv3 授權並提供完整對應原始碼；其 ESPHome 前端為 GPL-only。
3. 本 repo 的 YAML 是產生該結合程式的設定原始碼（Corresponding Source 的一部分）。為了和上游一致、避免授權相容性疑慮，採保守的 **GPL-3.0-only**（不是 or-later，因為 ESPectre 本身就是 only）。
4. 硬體設計（外殼、接線、BOM）與韌體是獨立的作品，不受 GPL 影響，維持 CERN-OHL-P-2.0。

## 散布編譯好的韌體時

- 一併提供本 repo（對應版本）與上游版本資訊（`NOTICE.md`），即可滿足「完整對應原始碼」。
- 本專案的 GitHub Release **不附編譯好的韌體**：每個人的 `secrets.yaml` 不同，映像檔內會含 Wi-Fi 帳密。
