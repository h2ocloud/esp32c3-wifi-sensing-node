# NOTICE — 上游與第三方

本 repo **沒有複製**任何上游原始碼；韌體在編譯時由 ESPHome 下載下列元件。散布編譯後的韌體時，須遵守各自授權並提供對應原始碼（本 repo＋下列上游版本）。

| 元件 | 用途 | 授權 | 來源 |
|---|---|---|---|
| ESPectre SDK（ESP-IDF 元件 `francescopace/espectre` 3.0.0） | Wi-Fi CSI 動作偵測核心 | GPL-3.0-only（另有商業授權，本專案未使用） | https://github.com/francescopace/espectre |
| ESPHome 2026.10.2（含內建 `espectre`、`aht10`、`bmp280_i2c`、`hitachi_ac344`、`hitachi_ac424`、`climate_ir`、`remote_transmitter`、`remote_receiver`、`web_server`、`prometheus`、`mqtt` 等元件） | 韌體框架 | Python 部分 MIT；C/C++ 執行程式碼 GPLv3 | https://github.com/esphome/esphome |
| ESP-IDF 5.5.6 | SDK／RTOS | Apache-2.0（含其他第三方元件，見 ESP-IDF 授權） | https://github.com/espressif/esp-idf |

ESPectre 的授權說明（摘要，原文見上游 `LICENSING.md`）：ESPectre 第一方程式碼以 GPL-3.0-only 釋出；散布結合 ESPectre 的韌體時，整體必須以 GPLv3 授權並提供完整對應原始碼；其 ESPHome 前端為 GPL-only。

ESPHome 的授權說明（摘要，原文見上游 `LICENSE`）：C/C++ 執行程式碼（.c、.cpp、.h、.hpp、.tcc、.ino）為 GPLv3，Python 與其他部分為 MIT。

接線圖中的板子、模組、電晶體、LED、接收頭圖形為本專案自繪（CC0-1.0），未使用第三方元件圖。
