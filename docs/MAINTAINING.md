# 維護流程：追加製作紀錄、同步專案頁

這份是給維護者（或接手的 AI 工作分頁）看的。零件到貨、印製、實機驗證的消息會陸續進來，每一則都照下面做。

> 下面的 `tools/…` 指令在**維護者的工作區**執行（工作區裡有 `repo/`、`site/`、`publish/`、`tools/`），不在本 repo 裡。
> 本 repo 只放公開成品；上傳 ToolHub 用的腳本不公開。

## 1. 追加一筆紀錄（一鍵）

```bash
tools/journal_append.sh "<時間 或 now>" "<角色>" "<內容>" ["<誰做的>"]
# 例：
tools/journal_append.sh now 採購 "ESP32-C3 與感測板到貨。BMP280 模組背面標示 0x76，韌體位址待改。" "採購 bot"
```

- **時間**：台灣時間、含星期，例如 `11/18（二）14:30`；不確定就寫 `約 11/18（二）下午`；`now` 自動帶入現在時間。
- **角色**：產品、採購、接線、機構、切片、韌體、軟體、AI（對應專案頁的接力站）。
- **內容**：第一句（到第一個「。」）是標題，後面每一句變成一條細節。失敗與修正要寫進去（例如「失敗：…。修正：…。」）。
- **誰做的**：只寫角色或分頁的通稱（例如「機構工程師 bot」「採購 bot」「Claude Opus 工作分頁」「CAD R2 分頁」）；不寫私人帳號、任何購買或交易資訊、內部主機名（追加後的 secret 掃描會擋）。

腳本會依序做：

1. 追加到 `repo/docs/JOURNAL.md`。
2. 重建專案頁的「製作紀錄（邊做邊記）」章節；順便查姊妹專案的 ToolHub 頁是否已上架，有就補上連結。
3. 重打包上傳用 zip，跑 secret 掃描（repo 候選檔＋網頁＋zip），**0 命中才繼續**。
4. 用**同一個工具 id** 更新 ToolHub（`tools/toolhub_update.py`）：
   - 先備份：線上 `index.html` 存到 `qa/publish/`，上一個已部署的 zip 在 `publish/history/`。
   - 差異檢查：和上一個已部署的 zip 比，只允許 `index.html` 的製作紀錄、姊妹連結區塊不同，其他檔案必須逐位元組相同；不符就停止。
   - 先讀 CMS 目前的紀錄（標題、描述、分類、slug 等）存檔；`PUT /tools/{id}` 送 `uploadType=zip`、`generateThumbnail=false`、**目前的** `seoSlug`（實測：slug 不送會被依名稱重新產生），以及**從 CMS 目前值取出、逐位元組原樣送回的標題**（不 trim、不正規化；本機不寫死標題）。描述等其他欄位不送，別人改過的值原樣保留；封面一起重送（PUT 會覆蓋整個工具資料夾）。
   - 斷言：標題不可含「八個角色接力」；本專案標題的「Wi‑Fi」必須是不換行連字號 U+2011；不合規就停止、不自己組標題。更新後回讀 CMS，標題（逐位元組）、描述、分類、slug 必須和更新前完全相同。測試：`python3 -I qa/test_title_preserve.py --live`（工作區，唯讀）。
   - 驗證：線上頁含最新一筆、縮圖可下載且非空、favicon 仍內嵌。
5. `repo` commit 並 push 到 GitHub。

先演練不上傳：`DRY_RUN=1 tools/journal_append.sh …`；只更新頁面、先不 push：`NO_PUSH=1 tools/journal_append.sh …`。

**專案頁暫停更新時**（例如有人正在改 ToolHub 標題）：工作區建立 `publish/CMS_PAUSED`（第一行寫原因）。這段期間第 4 步會自動跳過、待辦記到 `publish/PENDING_CMS.md`，紀錄照常 commit＋push 到 GitHub；`toolhub_update.py --go` 會直接拒絕。收到明確解除通知後才刪掉這個檔案，再照待辦上線。

若停在第 3 步（掃描有命中）或第 4 步：紀錄已經追加了，修正後用**同樣參數**加 `SKIP_APPEND=1` 重跑，就不會重複追加。
姊妹專案的 ToolHub 頁是公開網址，掃描只放行 `publish/sister.json` 記錄的那一條（其他 ToolHub 網址仍算命中）。

## 2. 不是只有紀錄的改動

外殼改版、韌體或腳位調整、頁面其他章節修改，**不要用上面的加法更新**（差異檢查會擋下來）。改走完整流程：

1. 外殼新版放進 `cad-drop/` → `tools/refresh_cad.sh`（重建 `repo/cad`、頁面 CAD 區塊、Release 附檔，並掃描）。
2. 韌體改動 → `tools/compile_firmware.sh <variant>` 全部組合重編，`python3 tools/summarize_compile.py` 更新 `qa/compile-esphome.txt`。
3. 頁面 QA：`python3 qa/qa_deck.py`（桌機／手機、深淺色截圖到 `qa/shots/`）。
4. secret 掃描 0 命中後 commit、push；需要更新線上頁時，以同一個工具 id 做完整 PUT 並重跑上線驗證（見 `qa/REPORT.md` 的驗證步驟）。

## 3. 標題規則（2026-11-15 起）

- 格式：「產品名：賣點｜軟硬整合系列」。本專案＝「Wi‑Fi 偵測節點：不裝鏡頭也知道有人｜軟硬整合系列」；姊妹專案＝「兒童 AI 問答機：按住就問，不用螢幕｜軟硬整合系列」。
- ToolHub 標題、頁面 `<title>`、頁首與封面文字、README 與本紀錄的標題都照這個格式；「八個角色接力」不放進任何標題（章節內提到接力的做法可以）。
- 標題字串的修改清單在工作區 `tools/title_edits.json`；只改頁面標題時，`toolhub_update.py --allow-title` 只允許清單內的替換，其餘仍逐字比對。

## 4. 誠實原則（每次都要守）

- 還沒實測的一律寫「尚未實機驗證」；實測後才把該項改成實測結果，並在紀錄裡寫清楚怎麼量、量到多少。
- 規格數字要有來源；查不到就寫「待實物量測」。
- 不寫印表機設定檔細節或 offset 數值。
