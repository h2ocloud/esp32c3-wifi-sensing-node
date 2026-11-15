// =====================================================================
//  MOD-WIFI-20261115  Wi-Fi 偵測節點外殼（ESP32-C3 SuperMini＋GY-SHT31-D／AHT20）— 兩件式滑蓋殼（全新設計）
//  用途：ESPectre（Wi-Fi CSI 動作偵測）＋溫濕度；USB-C 供電；壁掛／置物架；室內居家。
//  單位 mm。座標（組裝座標＝Onshape 匯入座標）：
//    X＝寬（以中心為 0；+X＝USB-C 那側，壁掛正面看在右邊）
//    Y＝長（Y=0＝感測端外表面＝壁掛時的下端；Y=L＝上端，滑蓋由此滑出）
//    Z＝深（Z=0＝背面＝貼牆面＝貼床面；+Z＝滑蓋／朝房間）
//  佈局（Y 由小到大）：感測端牆（格柵、扣點、防滑腳位）→ 感測通風艙（板子直立、感測面朝下端格柵）
//        → 雙層實心隔牆＋通風隔熱縫（只留 4 線缺口）→ MCU 艙（C3 橫放：USB-C 朝 +X 側牆、天線朝 -X 側開窗）
//        → 上端牆（降到蓋底以下，滑蓋出口）
//  接線（C3 同一排相鄰 4 腳）：GND(右排#2)→GND、3V3(#3)→VIN、GPIO4(#4)→SDA、GPIO3(#5)→SCL。
//        不用 GPIO8（藍 LED＋strapping）、GPIO9（BOOT＋strapping）。
//  沿用已驗證特徵：45° 燕尾滑蓋、fdm_gap 0.30、lid_foot 0.3、彈片＋1.0 切縫＋R0.5、平頂梯形扣點 0.56/1.4/0.5、
//        天線端角塊 45° 楔口 wedge_gap 0.50、牆厚 0.8 倍數、肋 ≥1.0、全部免支撐（只有 ≤7.6 mm 短橋接）。
//  列印：PLA、Cura 5.6 Low 0.28、殼身背面貼床、滑蓋底面貼床（詳 PRINT.md）。
//  實測版本：OpenSCAD 2026.10.29 snapshot（--backend Manifold）。
//  尺寸來源與可信度：檔頭參數註解（官方／文章／估計）＋ REPORT.md §2（含 URL）。
// =====================================================================

include <mod_wifi_ref.scad>   // 參考零件（只供預覽／干涉檢查）

/* [輸出選擇] */
part = "assembly"; // [body, lid_asm, lid_print, body_plate, lid_plate, plate, plate_view, assembly, lid_open, exploded, top_open, back, section_combo, antenna_combo, section_wire, section_ant, wall_view, dims, check_parts_body, check_parts_lid, check_lid_body, check_slide]
// C3 排針：none＝不焊排針、4 條線直接焊在孔上（預設，殼最薄）；bottom＝排針焊在板底＋杜邦母頭朝背板（已焊針的板子；殼自動加深）
esp_hdr = "none";          // [none, bottom]
// 感測器：sht31＝GY-SHT31-D（預設）；aht20＝AHT20 小 I2C 板（尺寸見 SENSORS 表）
sensor_variant = "sht31";  // [sht31, aht20]
// 感測器端接法：dupont＝直排針＋杜邦母頭（預設）；solder＝線直接焊在板上（感測艙縮短約 14 mm）
sens_conn = "dupont";      // [dupont, solder]
// 藍色 GPIO8 LED 窗（韌體可控；可當狀態燈）
led8_window = true;
// 紅色電源 LED 窗（常亮、韌體關不掉；臥室夜間會看到，預設不開）
led_pwr_window = false;
// LED 窗形式：hole＝貫穿小孔（任何顏色的 PLA 都看得到）；thin＝留 0.56 mm 薄皮（白/淺色蓋才透光，外觀最乾淨）
led_window_type = "hole";  // [hole, thin]
// 蓋面凹字（凹 label_depth；兩行置中）；空字串為無字
label = ["WIFI", "NODE"];
lid_open_dy = 40;          // 只影響 lid_open 預覽

/* [FDM（沿用已驗證值）] */
fdm_gap   = 0.30;   // 燕尾、板邊、導槽、擋面配合間隙（每側）
wedge_gap = 0.50;   // 天線端楔口離 PCB 頂面（0.28 層高量化後 ≥0.35，見 build/check.txt）
lid_foot  = 0.3;    // 滑蓋貼床面燕尾外緣 45° 防象腳倒角（< groove_v）

/* [ESP32-C3 SuperMini（板座標 [bx, by]：bx 自 GPIO5 排板邊、by 自 USB 端板邊；來源見 REPORT §2）] */
esp_l     = 22.52;  // PCB 長（USB 端→天線端）｜官方：Nologo 尺寸圖 22.52；espboards 22.52、Mischianti／Components101 22.5（高）
esp_w     = 18.00;  // PCB 寬｜官方：Nologo 18.00；另 3 來源一致（高）
esp_row   = 15.24;  // 兩排針中心距｜官方：Nologo 尺寸圖 15.24＝0.6"（高）
esp_pin1  = 1.52;   // 第 1 腳中心距 USB 端板邊｜估計：原廠 3D 圖量 1.52、Mischianti 圖量 1.55（±0.2）
esp_pcb_t = 1.0;    // PCB 厚｜估計（未查到公開值；到貨要量）
esp_total_h = 4.5;  // PCB 底→USB-C 頂｜Components101 22.5×18×4.5（中）
esp_usb_w = 8.94;   // USB-C 母座外殼寬｜常見 8.94（中）
esp_usb_h = 3.26;   // USB-C 母座外殼高｜常見 3.26（中）
esp_usb_len = 7.35; // USB-C 母座長｜常見 7.35（中）
esp_usb_over = 1.5; // USB-C 凸出 PCB 板邊｜估計：Mischianti 圖量 1.5、原廠 3D 圖量 1.9–2.0。讓位凹槽以 1.5 定位（插頭可插到底），U 缺口容到 esp_usb_over_max
esp_usb_over_max = 2.1;  // U 缺口可容的最大凸出（檢查 #12 以此驗證）
esp_usb_bx = 9.0;   // USB-C 中心 bx（板寬中央）｜照片（中）
esp_boot_xy = [6.2, 8.7];    // BOOT 鍵中心｜估計：原廠 3D 圖量 (6.2, 8.7)、Mischianti 圖量 (6.35, 8.7)（±0.3）；按鍵「SMD KEY 3*4*2」（官方原理圖）
esp_rst_xy  = [11.7, 8.7];   // RST 鍵中心｜估計：原廠 3D 圖 (11.7, 8.7)、Mischianti (11.8, 8.7)
esp_btn_h   = 2.0;           // 按鍵總高｜官方料號 3×4×2
esp_led8_xy = [13.6, 11.1];  // 藍 LED（GPIO8，低電位亮）｜估計：原廠 3D 圖 (13.6, 11.1)、Mischianti (13.4, 11.0)
esp_led8_win = [13.8, 11.8]; // 藍 LED 窗中心：兩來源之間並與 RST 孔留 ≥1.0 肋
esp_ledp_xy = [3.0, 5.2];    // 紅色電源 LED（常亮）｜估計：原廠 3D 圖 (3.0, 5.2)
esp_ant_bx  = [5.95, 12.05]; // 陶瓷天線 bx（置中，本體約 6.1×2）｜估計：原廠 3D 圖
esp_ant_by  = [20.4, 22.4];  // 陶瓷天線 by（貼天線端板邊）｜估計：原廠 3D 圖

/* [排針／杜邦（常見規格，估計）] */
hdr_plastic = 2.5;   // 排針塑膠座高
hdr_long    = 6.0;   // 塑膠座以下長針
hdr_short   = 2.0;   // 感測板感測面側短針＋焊點
dupont_len  = 14.0;  // 杜邦母頭塑膠殼長（常見 14；有 14.5–15）
dupont_w    = 2.6;   // 母頭外寬
dupont_bend = 3.56;  // esp_hdr="bottom"：母頭尾到內底的彎線空間（3.56 使 Z_e 與預設版差 0.28 的整數倍，量化結果相同）
wire_d      = 1.3;   // 杜邦線外徑

/* [感測器小板（lookup；未校準，到貨要量）] */
// 欄位：w＝沿排針寬（X）、h＝垂直排針高（Z）、t＝PCB 厚、pin_edge＝排針中心距下緣、
//       pins＝由感測面看（排針在下）左→右、chip＝晶片中心 [x 偏移, 距下緣]、chip_wh＝[寬, 高, 厚]、
//       hole＝[x 偏移, 距下緣, 孔徑]（0＝無孔）、col＝預覽色
SENSORS = [
  ["sht31", [["w", 13.0], ["h", 10.0], ["t", 1.6], ["pin_edge", 1.3], ["pins", ["VIN", "GND", "SCL", "SDA"]],
             ["chip", [1.0, 5.8]], ["chip_wh", [2.5, 2.5, 0.9]], ["hole", [-2.0, 7.6, 3.0]], ["col", "#2d8a4e"]]],
  ["aht20", [["w", 15.0], ["h", 10.4], ["t", 1.6], ["pin_edge", 1.3], ["pins", ["VIN", "GND", "SCL", "SDA"]],
             ["chip", [0.0, 6.4]], ["chip_wh", [3.0, 3.0, 1.0]], ["hole", [0, 0, 0]], ["col", "#1f5fae"]]]
];
sens_air  = 3.0;   // 感測面到下端牆內面的空氣層（含短針＋焊點 2.0）
sens_turn = 3.5;   // 感測器母頭尾到隔牆的轉彎空間
sens_top_gap = 0.8;// 感測板上緣到滑蓋
sens_x    = 0;     // 感測板中心 X
lip_t     = 1.2;   // 導槽前後唇厚（肋 ≥1.0）

/* [殼體（牆厚為 0.8 的倍數）] */
wall     = 3.2;    // 側牆（含燕尾槽，槽後剩 1.7）
wall_bot = 4.0;    // 感測端牆（扣點缺口＋凸點＋格柵）
wall_top = 2.4;    // 上端牆（滑蓋出口）
part_t   = 1.6;    // 雙層隔牆每片厚
part_gap = 2.0;    // 兩片隔牆之間的通風隔熱縫（兩側牆開槽通到室內空氣）
ant_clear = 8.0;   // 天線端板邊到天線側牆內面的空氣（brief ≥8）
esp_under = 3.82;  // esp_hdr="none"：PCB 底面到背板內面（焊線出線＋彎線 ≥3.5）。取 3.82 是為了 0.28 層高量化：
                   //   首層 0.28／0.20 時楔口實隙都是 0.40、扣點頂層寬 0.77／0.90（4.0 時首層 0.28 會變 0.68，見 build/check.txt）
lid_t    = 2.2;    // 滑蓋厚
lid_gap  = 0.6;    // 板上最高點到滑蓋（最低要求；實際由 USB 插頭開口決定）
groove_d = 1.5;    // 燕尾槽深
groove_v = 0.7;    // 燕尾直邊高
corner_r = 3.0;    // 外殼垂直邊圓角
edge_ch  = 0.6;    // 外殼上下外緣 45° 倒角（底：防象腳）
blk_len  = 2.4;    // 天線端角塊擋塊長（X）
corner_w = 2.6;    // 角塊壓/托住板角的寬度（自板長邊往內；第 8 腳焊盤自 2.4 起，楔口只到 1.4）
hk       = 0.5;    // 楔口平底長
ledge_len = 1.2;   // 角塊伸入 PCB 底下的支撐長（bottom 版塑膠座自 1.9 起）
usbsup_len = 1.5;  // USB 端板底支撐伸入長（兩排針之間）

/* [USB-C 插頭（插頭模具外殼 12.35×6.5 為常見上限，見 REPORT）] */
plug_typec = [13.4, 8.0];  // 外側讓位凹槽寬×高（每側 ≥0.5）
plug_body  = [12.35, 6.5]; // 檢查用插頭模具外殼
usb_rim    = 0.8;          // 讓位凹槽頂到燕尾槽底的實心
usb_lip    = 0.8;          // 讓位凹槽底到側牆內面的實心（PCB 板邊靠在這片上，擋拔線拉力）

/* [格柵（開口 2.0＝短橋接，免支撐）] */
slot_w     = 2.0;
rib_w      = 1.6;   // 一般肋（≥1.0）
rib_side_w = 2.4;   // 側牆肋（側牆上方還要承受滑蓋）
rib_end_w  = 1.2;   // 感測端牆肋

/* [滑蓋細節（沿用；扣點為平頂梯形）] */
tongue_w   = 4.8;
tongue_len = 7.5;
tongue_t   = 1.6;
slit_w     = 1.0;
slit_round = true;  // 切縫末端 R0.5
bump_h     = 0.56;  // 扣點高（0.28 層高兩層）
bump_base  = 1.4;
bump_top   = 0.5;
bump_len   = 2.4;
btn_hole_d = 2.6;   // BOOT/RST 牙籤孔（小孔；按鍵在蓋下約 4 mm，手指碰不到）
led_hole_d = 2.4;   // LED 窗
label_size = 4.5;   // 凹字大小（字高 4.4、筆畫約 0.9，0.4 噴嘴可印；單行 "WIFI-NODE" 需 33 mm 寬，蓋面只有 30，故分兩行）
label_lead = 6.2;   // 行距
label_depth = 0.56; // 凹字深（0.28 層高兩層；brief 0.4–0.6）
label_y_set = 0;    // >0 時覆蓋字的位置 Y

/* [壁掛鑰匙孔（藏在背板內，不穿透電子艙）] */
kh_x    = 7.0;          // 兩個鑰匙孔在同一垂直線（USB 側，遠離天線）
kh_y    = [9.0, 39.0];  // 入口圓心 Y（壁掛時下、上）
kh_d    = 7.6;          // 螺絲頭入口／頭部腔（螺絲頭 Ø6–7）
kh_w    = 3.6;          // 螺絲桿槽寬（M3）
kh_len  = 6.0;          // 入口圓心→掛點（槽端）距離；掛上後殼往下滑 6 mm
kh_lip  = 1.4;          // 背面唇厚（5 層）
kh_head = 2.52;         // 頭部腔高（9 層；M3 盤頭 ≤2.4）
kh_ceil = 1.12;         // 腔頂到電子艙的實心（4 層；不漏光、不碰板）
floor_t = kh_lip + kh_head + kh_ceil;   // 背板 5.04

/* [置物架防滑腳位（感測端外表面，4 個淺凹圓）] */
feet_d = 8.4;       // 3M Bumpon 類 Ø7.9 自黏腳墊
feet_depth = 0.6;
feet_x = 12.2;
feet_z = [4.8, 13.9];

/* [一盤排版] */
bed_x = 220;
bed_y = 220;
bed_back_keep = 20; // 後緣留空（Cura 噴頭 Y offset −20 為刻意設定，不補償、不改）
plate_gap = 10;     // ≥ 8

$fn = 48;
eps = 0.01;
big = 400;

// ------------------------- lookup -------------------------
function tbl(t, k) = let(i = search([k], t)[0]) assert(i != [], str("查無：", k)) t[i][1];
SV = tbl(SENSORS, sensor_variant);
function sv(k) = tbl(SV, k);
sens_w = sv("w"); sens_h = sv("h"); sens_t = sv("t"); sens_pin_edge = sv("pin_edge");
sens_pins = sv("pins"); sens_np = len(sens_pins);
sens_chip = sv("chip"); sens_chip_wh = sv("chip_wh"); sens_hole = sv("hole"); sens_col = sv("col");
function sens_sig(n) = n == "VIN" || n == "VCC" ? "3V3" : n;

// ------------------------- 推導尺寸（勿手改） -------------------------
X_in    = (ant_clear + esp_l + fdm_gap) / 2;   // 內腔半寬（C3 長＋天線淨空決定）
outer_w = 2*(X_in + wall);

// Y：感測艙 → 雙層隔牆 → MCU 艙
y_in0 = wall_bot;                                   // 感測端牆內面
y_sf  = y_in0 + sens_air;                           // 感測面
y_sb  = y_sf + sens_t;                              // 感測板背面
sens_reach = sens_conn == "dupont" ? hdr_plastic + dupont_len : 2.0;
y_pa0 = y_sb + sens_reach + sens_turn;              // 隔牆 A（感測側面）
y_pa1 = y_pa0 + part_t;
y_pb0 = y_pa1 + part_gap;                           // 隔牆 B
y_pb1 = y_pb0 + part_t;
y_m0  = y_pb1;                                      // MCU 艙下緣
y_m1  = y_m0 + esp_w + 2*fdm_gap;                   // MCU 艙上緣＝上端牆內面
L     = y_m1 + wall_top;                            // 殼長

// C3 在殼內：USB 端板邊靠 +X 側牆、天線端朝 -X
X_ue   = X_in - fdm_gap;                            // PCB USB 端板邊
X_ae   = X_ue - esp_l;                              // PCB 天線端板邊
y_pcb0 = y_m0 + fdm_gap;                            // PCB -Y 長邊（5V/GND/3V3/GPIO4 排）
y_pcb1 = y_pcb0 + esp_w;                            // PCB +Y 長邊（GPIO5 排）
function bxy(p) = [X_ue - p[1], y_pcb1 - p[0]];     // 板座標 → 殼 [X, Y]
// row：-1＝GPIO5 排（bx 1.38）；+1＝5V 排（bx 16.62）。n＝1..8 自 USB 端
function pin_xy(row, n) = bxy([row < 0 ? (esp_w - esp_row)/2 : esp_w - (esp_w - esp_row)/2, esp_pin1 + (n - 1)*2.54]);
// 使用中的腳：[名稱, row, n, 訊號]
esp_used = [["GND", 1, 2, "GND"], ["3V3", 1, 3, "3V3"], ["GPIO4", 1, 4, "SDA"], ["GPIO3", 1, 5, "SCL"]];
Y_uc = bxy([esp_usb_bx, 0])[1];                     // USB-C 中心 Y
X_n  = (pin_xy(1, 2)[0] + pin_xy(1, 5)[0]) / 2;     // 隔牆走線缺口中心 X（對齊 4 支腳）
notch_w = 7.6;
notch_h = 3.6;

// Z
Z_f = floor_t;
esp_below = esp_hdr == "bottom" ? hdr_plastic + dupont_len + dupont_bend : esp_under;
Z_e = Z_f + esp_below;                              // C3 PCB 底面
Z_p = Z_e + esp_pcb_t;                              // C3 PCB 頂面
Z_u = Z_p + esp_usb_h/2;                            // USB-C 軸心
Z_L = max(Z_e + esp_total_h + lid_gap,              // 滑蓋底面
          Z_u + plug_typec[1]/2 + usb_rim,          //   USB 插頭讓位凹槽要在燕尾槽下方
          Z_f + sens_h + sens_top_gap);             //   感測板直立
Z_T = Z_L + lid_t;                                  // 殼頂＝蓋頂
Z_s = Z_L - sens_top_gap - sens_h;                  // 感測板下緣（板頂離蓋 0.8；低於內底時墊高）

// 滑蓋
y_lead    = y_in0 - groove_d + fdm_gap;             // 滑蓋前緣（燕尾）
lid_y_tip = 0.4;                                    // 鼻片前緣
y_trail   = L;                                      // 蓋尾與上端齊平
lid_hw    = X_in + groove_d - fdm_gap;              // 滑蓋半寬（底面）
slit_end_y = y_lead + tongue_len;                   // 彈片根部
bump_y    = wall_bot/2 + 0.2;
notch_drop = 0.1;

// 角塊／楔口
z_h0 = Z_p + wedge_gap;                             // 楔口下緣
z_ht = z_h0 + 0.9 + 0.6;                            // 角塊頂

// 感測導槽
s_slot_x = sens_w/2 + fdm_gap + 0.3;                // 槽底（可容板寬 +0.6）
s_lip_x  = max(sens_w/2 - 1.0, sens_np*2.54/2 + 0.4);   // 唇內緣（避開排針塑膠座）
s_post_x = s_slot_x + 2.4;

assert(lid_foot < groove_v, "lid_foot 必須 < groove_v");
assert(z_ht < Z_L - 0.5, "角塊太高");
assert(floor_t >= kh_lip + kh_head + kh_ceil - 1e-6, "背板不夠厚，鑰匙孔會穿透");
assert(s_post_x < X_in - 2, "感測板太寬");
assert(Z_s >= Z_f - 1e-6, "感測板放不下");
assert(plate_gap >= 8, "盤面間距需 ≥ 8");
assert(rib_w >= 1.0 && rib_side_w >= 1.0 && rib_end_w >= 1.0 && lip_t >= 1.0, "肋需 ≥ 1.0");
assert(ant_clear >= 8, "天線前方空氣需 ≥ 8");
assert(Z_u + plug_typec[1]/2 <= Z_L - usb_rim + 1e-6, "USB 讓位凹槽碰到燕尾槽");
assert(X_in + usb_lip <= X_ue + esp_usb_over + 1e-6, "讓位凹槽要比母座口深（插頭才插得到底）");

// =====================================================================
//  滑軌截面（已驗證；u＝自內腔面往牆內，v＝Z）
// =====================================================================
module lid_edge_2d(foot = true) {
    f = foot ? lid_foot : 0;
    polygon([[-big, Z_L], [groove_d - fdm_gap - f, Z_L], [groove_d - fdm_gap, Z_L + f],
             [groove_d - fdm_gap, Z_L + groove_v],
             [groove_d - fdm_gap - (lid_t - groove_v), Z_T], [-big, Z_T]]);
}
module groove_2d() {
    k = groove_d - fdm_gap + groove_v + fdm_gap*sqrt(2);
    polygon([[-3, Z_L], [groove_d, Z_L], [groove_d, Z_L + (k - groove_d)], [-3, Z_L + k + 3]]);
}
module rrect(x0, x1, y0, y1, r) hull() for (x = [x0 + r, x1 - r], y = [y0 + r, y1 - r]) translate([x, y]) circle(r);
module side_grooves() {
    for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0])
        translate([X_in, y_in0 - groove_d - 0.5, 0]) rotate([-90, 0, 0])
            linear_extrude(L + 2) mirror([0, 1, 0]) groove_2d();
}
// 把 (u, Z) 截面沿 X 擠出，u＝自感測端牆內面往 -Y（牆內）
module end_extrude(w) {
    translate([-w/2, y_in0, 0]) rotate([90, 0, 90]) linear_extrude(w) mirror([1, 0]) children();
}
module end_groove() { end_extrude(2*(X_in + groove_d + 0.5)) groove_2d(); }
// 同 end_extrude，但只往 +X 擠出 w（從原點起）
module end_extrude_r(w) {
    translate([0, y_in0, 0]) rotate([90, 0, 90]) linear_extrude(w) mirror([1, 0]) children();
}
// +X 側燕尾槽在 USB 缺口兩端的 45° 導入（避免蓋緣滑過缺口後卡邊）
module groove_leadins() {
    n0 = Y_uc - (esp_usb_w/2 + fdm_gap); n1 = Y_uc + (esp_usb_w/2 + fdm_gap);
    module sl(y, big_) translate([X_in, y, 0]) rotate([-90, 0, 0]) linear_extrude(0.01) mirror([0, 1, 0])
        if (big_) offset(delta = 0.4) groove_2d(); else groove_2d();
    hull() { sl(n0 - 0.01, true); sl(n0 - 2.0, false); }
    hull() { sl(n1, true); sl(n1 + 2.0, false); }
}

// =====================================================================
//  殼身
// =====================================================================
module outer_solid() {
    hull() {
        translate([0, 0, 0])            linear_extrude(eps) offset(delta = -edge_ch) rrect(-outer_w/2, outer_w/2, 0, L, corner_r);
        translate([0, 0, edge_ch])      linear_extrude(Z_T - 2*edge_ch) rrect(-outer_w/2, outer_w/2, 0, L, corner_r);
        translate([0, 0, Z_T - eps])    linear_extrude(eps) offset(delta = -edge_ch) rrect(-outer_w/2, outer_w/2, 0, L, corner_r);
    }
}
module shell() {
    difference() {
        outer_solid();
        translate([-X_in, y_in0, Z_f]) cube([2*X_in, y_m1 - y_in0, Z_T]);
    }
}
// 雙層隔牆（頂離蓋 0.4）
module partitions() {
    for (y0 = [y_pa0, y_pb0]) translate([-X_in - eps, y0, Z_f - eps]) cube([2*X_in + 2*eps, part_t, (Z_L - 0.4) - Z_f + eps]);
}
module wire_notch() {
    translate([X_n - notch_w/2, y_pa0 - 1, Z_f - eps]) cube([notch_w, y_pb1 - y_pa0 + 2, notch_h + eps]);
}

// C3 天線端角塊（兩角）：擋面（擋插線推力）＋板底支撐＋45° 楔口壓板角。
// 一塊黏隔牆 B、一塊黏上端牆；自內底立起。單一 (X,Z) 截面一次擠出（避免共面非流形）。
module esp_corner_blocks() {
    u0 = -fdm_gap - blk_len;
    for (c = [[y_m0, 1], [y_m1, -1]]) {
        ya = c[1] > 0 ? c[0] - eps : c[0] - (fdm_gap + corner_w);
        yb = c[1] > 0 ? c[0] + fdm_gap + corner_w : c[0] + eps;
        translate([X_ae, yb, 0]) rotate([90, 0, 0]) linear_extrude(yb - ya)
            polygon([[u0, Z_f - eps], [ledge_len, Z_f - eps], [ledge_len, Z_e], [-fdm_gap, Z_e],
                     [-fdm_gap, z_h0], [hk, z_h0], [hk + 0.9, z_h0 + 0.9], [hk + 0.9, z_ht], [u0, z_ht]]);
    }
}
// USB 端板底支撐（兩排針之間；黏 +X 側牆）
usbsup_w = [6.5, 11.5];   // 支撐在板寬方向的範圍（自 -Y 長邊）：避開 USB 殼穿孔固定腳（約 bx 9±4.3）與兩排塑膠座
module esp_usb_support() {
    translate([X_ue - usbsup_len, y_pcb0 + usbsup_w[0], Z_f - eps]) cube([usbsup_len + fdm_gap + eps, usbsup_w[1] - usbsup_w[0], Z_e - Z_f + eps]);
}
module usb_cuts() {
    // 母座 U 型缺口（側牆內側；向上開口，板子由上放入）：深到可容 esp_usb_over_max（2.1）＋0.2
    translate([X_in - 1, Y_uc - (esp_usb_w/2 + fdm_gap), Z_p - 0.2]) cube([1 + (X_ue + esp_usb_over_max + 0.2 - X_in), esp_usb_w + 2*fdm_gap, Z_T]);
    // 插頭模具外殼讓位凹槽（外側）：槽底留 usb_lip 0.8（2 道牆）＝比母座口平面再深 0.4，插頭一定插得到底
    translate([X_in + usb_lip, Y_uc, Z_u]) rotate([0, 90, 0]) linear_extrude(wall + 2)
        offset(r = 1.5) offset(delta = -1.5) square([plug_typec[1], plug_typec[0]], center = true);
}

// 感測板導槽（兩側柱；板子由上往下插入；唇下 45°）
module sens_posts() {
    z_top = Z_L - 0.4;
    z_lip0 = Z_s + 3.0;
    yf0 = y_sf - fdm_gap - lip_t; yf1 = y_sf - fdm_gap;
    yb0 = y_sb + fdm_gap;         yb1 = yb0 + lip_t;
    for (s = [-1, 1]) translate([sens_x, 0, 0]) mirror([s < 0 ? 1 : 0, 0, 0]) {
        translate([0, yb1, 0]) rotate([90, 0, 0]) linear_extrude(yb1 - yf0)
            polygon([[s_slot_x, Z_f - eps], [s_post_x, Z_f - eps], [s_post_x, z_top], [s_slot_x, z_top]]);
        for (yy = [[yf0, yf1], [yb0, yb1]])
            translate([0, yy[1], 0]) rotate([90, 0, 0]) linear_extrude(yy[1] - yy[0])
                polygon([[s_lip_x, z_lip0], [s_slot_x, z_lip0 - (s_slot_x - s_lip_x)], [s_slot_x + 1.2, z_lip0 - (s_slot_x - s_lip_x)], [s_slot_x + 1.2, z_top], [s_lip_x, z_top]]);
        if (Z_s > Z_f + 0.01)   // 槽底墊高（板角坐在上面）
            translate([s_lip_x, yf1 - eps, Z_f - eps]) cube([s_slot_x - s_lip_x + eps, yb0 - yf1 + 2*eps, Z_s - Z_f + eps]);
    }
}

// 通風格柵
function slot_centers(a, b, pitch) = let(n = floor((b - a - slot_w) / pitch + 1e-6) + 1, used = (n - 1)*pitch + slot_w, s0 = a + (b - a - used)/2 + slot_w/2)
    [for (i = [0 : n - 1]) s0 + i*pitch];
vz0 = Z_f + 1.0;              // 牆上格柵下緣
vz1 = Z_L - 2.4;              // 牆上格柵上緣（燕尾槽下方留實心）
end_slots_x = slot_centers(-(feet_x - feet_d/2 - 1.2), feet_x - feet_d/2 - 1.2, slot_w + rib_end_w);
sens_side_y = slot_centers(y_in0 + 1.5, y_pa0 - 1.5, slot_w + rib_side_w);
ant_win_y   = slot_centers(y_m0 + 1.5, y_m1 - 1.5, slot_w + rib_side_w);
top_slots_x = concat([-(X_in - 2.4)], slot_centers(-3.6, X_in - 2.4 - 1.0, slot_w + rib_w));
floor_slots_x = slot_centers(-(X_in - 1.4), -1.0, slot_w + rib_w);
module vents() {
    // 感測端牆：垂直格柵（感測面正前方）
    for (x = end_slots_x) translate([x - slot_w/2, -1, vz0]) cube([slot_w, y_in0 + 2, vz1 - vz0]);
    for (s = [-1, 1]) {
        xw = s > 0 ? X_in - 1 : -X_in - wall - 1;
        // 感測艙兩側牆
        for (y = sens_side_y) translate([xw, y - slot_w/2, vz0]) cube([wall + 2, slot_w, vz1 - vz0]);
        // 隔熱縫兩側通氣（縫寬即槽寬）
        translate([xw, y_pa1, vz0]) cube([wall + 2, part_gap, vz1 - vz0]);
    }
    // 天線側（-X）側牆開窗：天線前方
    for (y = ant_win_y) translate([-X_in - wall - 1, y - slot_w/2, vz0]) cube([wall + 2, slot_w, vz1 - vz0]);
    // 上端牆：排氣（壁掛時在最上方）
    for (x = top_slots_x) translate([x - slot_w/2, y_m1 - 1, vz0]) cube([slot_w, wall_top + 2, (Z_L - 1.6) - vz0]);
    // 背板（感測艙，避開鑰匙孔）
    for (x = floor_slots_x) translate([x - slot_w/2, y_sb + hdr_plastic + 1.0, -1]) cube([slot_w, (y_pa0 - 1.2) - (y_sb + hdr_plastic + 1.0), Z_f + 2]);
}

// 扣點：感測端牆上緣中央貫穿缺口（鼻片）＋平頂梯形凸點
module detent_notch() {
    translate([-(tongue_w/2 + fdm_gap), -1, Z_L - notch_drop]) cube([tongue_w + 2*fdm_gap, y_in0 + 1 + eps, Z_T]);
}
module detent_bump() {
    sl = (bump_base - bump_top) / 2 / bump_h;
    hb = bump_base/2 + sl*(notch_drop + eps);
    translate([-bump_len/2, 0, 0]) rotate([90, 0, 90]) linear_extrude(bump_len)
        polygon([[bump_y - hb, Z_L - notch_drop - eps], [bump_y + hb, Z_L - notch_drop - eps],
                 [bump_y + bump_top/2, Z_L + bump_h], [bump_y - bump_top/2, Z_L + bump_h]]);
}

// 背面鑰匙孔（入口 Ø7.6 → 往 +Y 的 3.6 槽；頭部腔藏在背板內，腔頂留 1.12 實心）
module keyholes() {
    for (ky = kh_y) translate([kh_x, ky, 0]) {
        translate([0, 0, -1]) cylinder(d = kh_d, h = 1 + kh_lip + eps);
        translate([0, 0, -1]) hull() { cylinder(d = kh_w, h = 1 + kh_lip + eps); translate([0, kh_len, 0]) cylinder(d = kh_w, h = 1 + kh_lip + eps); }
        translate([0, 0, kh_lip]) hull() { cylinder(d = kh_d, h = kh_head); translate([0, kh_len, 0]) cylinder(d = kh_d, h = kh_head); }
    }
}
// 置物架立放：感測端外表面 4 個防滑腳位（淺凹圓，貼 Ø7.9 自黏腳墊）
module feet_recesses() {
    for (x = [-feet_x, feet_x], z = feet_z) translate([x, -1, z]) rotate([-90, 0, 0]) cylinder(d = feet_d, h = 1 + feet_depth);
}

module body(with_bump = true) {
    union() {
        difference() {
            union() {
                shell();
                partitions();
                esp_corner_blocks();
                esp_usb_support();
                sens_posts();
            }
            side_grooves();
            end_groove();
            groove_leadins();
            // 上端牆降到蓋底以下：滑蓋出口
            translate([-X_in, y_m1 - eps, Z_L - 0.2]) cube([2*X_in, wall_top + 1, Z_T]);
            usb_cuts();
            vents();
            detent_notch();
            wire_notch();
            keyholes();
            feet_recesses();
        }
        if (with_bump) detent_bump();
    }
}

// =====================================================================
//  滑蓋（組裝座標；底面在 Z_L；列印時平移 -Z_L）
// =====================================================================
module lid_blank() {
    intersection() {
        translate([0, lid_y_tip - 1, 0]) rotate([-90, 0, 0]) linear_extrude(y_trail - lid_y_tip + 1) mirror([0, 1, 0])
            intersection_for(s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0]) translate([X_in, 0]) lid_edge_2d();
        union() {
            end_extrude(2*(X_in + groove_d)) lid_edge_2d(false);   // 前緣倒角在 lid() 內再切（只切切縫外側）
            // 鼻片：前緣往 -Y 延伸到 lid_y_tip（伸入感測端牆扣點缺口）；底面由側截面決定，與蓋底同一平面
            translate([-tongue_w/2 - slit_w/2, lid_y_tip, Z_L - 1]) cube([tongue_w + slit_w, y_lead + 2.0 - lid_y_tip, 1 + tongue_t]);
        }
        // 蓋尾兩角 R2.0（圓心在燕尾頂邊內側 0.5；R1.5 時圓心正好落在頂邊上，會留下退化面）
        translate([0, 0, Z_L - 1]) linear_extrude(lid_t + 2) rrect(-lid_hw, lid_hw, y_lead - 6, y_trail, 2.0);
    }
}
module slit_2d(x0) {
    if (slit_round) hull() {
        translate([x0, -1]) square([slit_w, slit_end_y + 1]);
        translate([x0 + slit_w/2, slit_end_y]) circle(d = slit_w);
    } else translate([x0, -1]) square([slit_w, slit_end_y + 1]);
}
// 蓋面開孔位置
lid_win_x0 = tongue_w/2 + slit_w + 1.0;               // 彈片側窗內緣（切縫外留 1.0 肋）
lid_win_x1 = X_in - 2.4;
// 感測艙橫向槽列（Y 中心；中央 ±lid_win_x0 留實心脊，彈片根部不被切斷）；最多 4 列，不越過隔牆 A
lid_rows_y = [for (i = [0 : 3]) let(y = y_in0 + 1.6 + i*(slot_w + rib_w)) if (y + slot_w/2 <= y_pa0 - 1.0) y];
label_y = label_y_set > 0 ? label_y_set : (lid_rows_y[len(lid_rows_y) - 1] + slot_w/2 + y_pa1) / 2;
label_fits = (y_pa1 - (lid_rows_y[len(lid_rows_y) - 1] + slot_w/2)) >= (len(label) - 1)*label_lead + label_size + 1.6;   // 字高＋上下各 0.8；放不下（如 sens_conn="solder"）就不刻字
ant_slot_x = [X_ae - 1.6 - slot_w/2 - (slot_w + rib_w), X_ae - 1.6 - slot_w/2];   // 天線淨空區上方縱槽
lid_tail_grooves_y = [L - 2.2, L - 3.8, L - 5.4];
module lid_hole(p, d) {
    if (led_window_type == "thin" && d == led_hole_d)
        translate([p[0], p[1], Z_L - 1]) cylinder(d = d, h = 1 + lid_t - 0.56);   // 由下往上掏，頂面留 0.56
    else translate([p[0], p[1], Z_L - 1]) cylinder(d = d, h = lid_t + 2);
}
module lid() {
    difference() {
        lid_blank();
        translate([-tongue_w/2 - slit_w/2, -1, Z_L + tongue_t]) cube([tongue_w + slit_w, slit_end_y + 1, lid_t]);   // 彈片減薄（底面平）
        // 前緣燕尾貼床面 45° 防象腳倒角（只在切縫外側；鼻片在扣點缺口內不需要）。
        // 止於側邊前 0.6：不和側面倒角在角點交會（交會線會在 float32 STL 留下退化面）
        for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) translate([tongue_w/2 + slit_w/2, 0, 0])
            end_extrude_r(lid_hw - 0.6 - (tongue_w/2 + slit_w/2))
                polygon([[groove_d - fdm_gap - lid_foot - 1, Z_L - 1], [groove_d - fdm_gap + 1, Z_L - 1], [groove_d - fdm_gap + 1, Z_L + lid_foot + 1]]);
        // 彈片切縫（末端 R0.5）
        for (s = [-1, 1]) translate([0, 0, Z_L - 1]) linear_extrude(lid_t + 2) slit_2d(s > 0 ? tongue_w/2 : -tongue_w/2 - slit_w);
        // 鼻片扣孔（兩側壁 1.0；前 0.25／後 0.45 間隙——後緣避開 lid_foot 倒角線 y_lead+lid_foot，免得留下 0.05 薄片）
        translate([-(bump_len/2 + 0.2), bump_y - (bump_base/2 + 0.25), Z_L - 1]) cube([bump_len + 0.4, bump_base + 0.7, lid_t + 2]);
        // 感測艙：4 列橫向槽（左右各一段，中央實心脊連到彈片根部）
        for (s = [-1, 1], y = lid_rows_y) mirror([s < 0 ? 1 : 0, 0, 0]) translate([lid_win_x0, y - slot_w/2, Z_L - 1]) cube([lid_win_x1 - lid_win_x0, slot_w, lid_t + 2]);
        // 隔熱縫上方：通氣槽
        translate([-(lid_win_x1 - 2), y_pa1, Z_L - 1]) cube([2*(lid_win_x1 - 2), part_gap, lid_t + 2]);
        // 天線淨空區上方：縱槽（兩段，中間 1.6 橫樑）
        for (x = ant_slot_x, r = [[y_m0 + 1.0, (y_m0 + y_m1)/2 - 0.8], [(y_m0 + y_m1)/2 + 0.8, y_m1 - 1.0]])
            translate([x - slot_w/2, r[0], Z_L - 1]) cube([slot_w, r[1] - r[0], lid_t + 2]);
        // BOOT / RST 牙籤孔
        for (b = [esp_boot_xy, esp_rst_xy]) translate([bxy(b)[0], bxy(b)[1], Z_L - 1]) cylinder(d = btn_hole_d, h = lid_t + 2);
        // LED 窗
        if (led8_window) lid_hole(bxy(esp_led8_win), led_hole_d);
        if (led_pwr_window) lid_hole(bxy(esp_ledp_xy), led_hole_d);
        // 凹字
        if (label_fits) for (i = [0 : len(label) - 1]) if (label[i] != "")
            translate([0, label_y + ((len(label) - 1)/2 - i)*label_lead, Z_T - label_depth]) linear_extrude(label_depth + 1)
                text(label[i], size = label_size, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
        // 蓋尾推蓋止滑凹溝
        for (y = lid_tail_grooves_y) translate([-6, y - 0.4, Z_T - 0.56]) cube([12, 0.8, 1]);
    }
}

// =====================================================================
//  一盤（殼身＋滑蓋）：熱床前左角為原點，置中於 220×220，Y 0–200
// =====================================================================
body_bb = [[-outer_w/2, outer_w/2], [0, L]];
lid_bb  = [[-lid_hw, lid_hw], [lid_y_tip, y_trail]];
plate_items = ["body", "lid"];
function p_bb(i) = plate_items[i] == "body" ? body_bb : lid_bb;
function p_w(i)  = p_bb(i)[0][1] - p_bb(i)[0][0];
function p_left(i) = i <= 0 ? 0 : p_left(i - 1) + p_w(i - 1) + plate_gap;
plate_w  = p_left(len(plate_items) - 1) + p_w(len(plate_items) - 1);
plate_x0 = bed_x/2 - plate_w/2;
function p_shift(i) = [plate_x0 + p_left(i) - p_bb(i)[0][0], bed_y/2 - (p_bb(i)[1][0] + p_bb(i)[1][1])/2];
function p_range(i) = [[p_bb(i)[0][0] + p_shift(i)[0], p_bb(i)[0][1] + p_shift(i)[0]],
                       [p_bb(i)[1][0] + p_shift(i)[1], p_bb(i)[1][1] + p_shift(i)[1]]];
for (i = [0 : len(plate_items) - 1]) {
    assert(p_range(i)[0][0] >= 0 && p_range(i)[0][1] <= bed_x, "plate X 超出熱床");
    assert(p_range(i)[1][0] >= 0 && p_range(i)[1][1] <= bed_y - bed_back_keep, "plate Y 超出 0–200");
}
module plate_part(i, colored = false) {
    translate([p_shift(i)[0], p_shift(i)[1], 0])
        if (plate_items[i] == "body") { if (colored) c_body(); else body(); }
        else if (colored) color(COL_LID) translate([0, 0, -Z_L]) lid();
        else translate([0, 0, -Z_L]) lid();
}
module plate(colored = false) {
    for (i = [0 : len(plate_items) - 1]) plate_part(i, colored);
    for (i = [0 : len(plate_items) - 1])
        echo(str("PLATE ", i, " ", plate_items[i], " X[", p_range(i)[0][0], ",", p_range(i)[0][1], "] Y[", p_range(i)[1][0], ",", p_range(i)[1][1], "]"));
}

// =====================================================================
//  預覽配色與場景
// =====================================================================
COL_BODY = "#5b6169";   // 殼身：深灰（渲染時稍提亮，細節才看得到）
COL_LID  = "#efeee9";   // 滑蓋：暖白（對比）
COL_CUT  = "#e9973b";   // 剖面切面：橘
COL_TXT  = "#26292d";
// 圖面標註（俯視正交圖用；Z 放高處）
module lbl(p, s, t, ha = "left") color(COL_TXT) translate([p[0], p[1], 60]) linear_extrude(0.1) text(t, size = s, font = "Heiti TC", halign = ha, valign = "center");
module ln(a, b, w = 0.22) color(COL_TXT) hull() { translate([a[0], a[1], 60]) cylinder(d = w, h = 0.1, $fn = 8); translate([b[0], b[1], 60]) cylinder(d = w, h = 0.1, $fn = 8); }
module tick(p, dir) color(COL_TXT) translate([p[0], p[1], 60]) rotate(dir) linear_extrude(0.1) polygon([[0, 0], [1.4, 0.5], [1.4, -0.5]]);
module dim_x(a, b, t, ty = 2.5) { ln(a, b); tick(a, 0); tick(b, 180); lbl([(a[0] + b[0])/2, a[1] + (ty == 0 ? 2.2 : ty)], 1.9, t, "center"); }
module dim_y(a, b, t) { ln(a, b); tick(a, 90); tick(b, -90); lbl([a[0] + 1.2, (a[1] + b[1])/2], 1.9, t, "left"); }
module bt(p, t, sz = 5) color(COL_TXT) translate([p[0], p[1], -0.15]) linear_extrude(0.1) text(t, size = sz, font = "Heiti TC", halign = "center", valign = "center");   // 熱床上的字
module arrow_up(p, t) { ln(p, p + [0, 6]); tick(p + [0, 6], -90); lbl(p + [1.2, 3], 1.7, t, "left"); }
module c_body() color(COL_BODY) body();
module c_lid(dy = 0) color(COL_LID) translate([0, dy, 0]) lid();

if (part == "body") {
    body();
} else if (part == "lid_asm") {
    lid();
} else if (part == "lid_print") {
    translate([0, 0, -Z_L]) lid();
} else if (part == "body_plate") {
    plate_part(0);
} else if (part == "lid_plate") {
    plate_part(1);
} else if (part == "plate") {
    plate();
} else if (part == "plate_view") {
    plate(true);
    color("#c8c8c8") translate([0, 0, -1.2]) cube([bed_x, bed_y - bed_back_keep, 1]);
    color("#e07a6a") translate([0, bed_y - bed_back_keep, -1.2]) cube([bed_x, bed_back_keep, 1]);
    bt([bed_x/2, bed_y - bed_back_keep/2], "後緣 20 mm 留空（噴頭 Y offset −20 為刻意設定，不改不補償）", 4.6);
    bt([bed_x/2, 40], "Ender-3 220×220｜PLA｜Cura Low 0.28｜免支撐", 5.5);
    bt([bed_x/2, 30], "零件全部在 Y 0–200；間距 10 mm；整盤置中 (110,110)", 5.5);
    bt([(p_range(0)[0][0] + p_range(0)[0][1])/2, p_range(0)[1][0] - 7], "殼身：背面貼床", 4);
    bt([(p_range(1)[0][0] + p_range(1)[0][1])/2, p_range(1)[1][0] - 7], "滑蓋：底面貼床", 4);
} else if (part == "assembly" || part == "antenna_end") {
    c_body(); parts_all(); c_lid(0);
} else if (part == "back") {
    // 翻面（繞 Y 轉 180°，背面朝上）讓背面受光：看鑰匙孔、背板格柵、天線側開窗、感測端防滑腳位
    rotate([0, 180, 0]) { c_body(); parts_all(); c_lid(0); }
} else if (part == "lid_open") {
    c_body(); parts_all(); c_lid(lid_open_dy);
} else if (part == "exploded") {
    c_body();
    translate([0, 0, 22]) parts_all(true);
    translate([0, 10, 44]) c_lid(0);
} else if (part == "top_open") {
    c_body(); parts_all();
} else if (part == "section_wire") {
    // 沿走線缺口中心 X＝X_n 的 YZ 剖面（保留 -X 那半）：C3、焊線、雙層隔牆＋缺口、感測板、鑰匙孔
    intersection() {
        union() { c_body(); parts_all(); c_lid(0); }
        translate([-60, -20, -1]) cube([60 + X_n, L + 40, 80]);
    }
} else if (part == "section_ant") {
    // 過天線中心 Y 的 XZ 剖面（保留 +Y 那半）：天線、前方 8 mm 空氣、側牆開窗、蓋、背板距離
    ya = bxy([(esp_ant_bx[0] + esp_ant_bx[1])/2, 0])[1];
    intersection() {
        union() { c_body(); parts_all(); c_lid(0); }
        translate([-60, ya, -1]) cube([120, L + 20, 80]);
    }
} else if (part == "section_combo") {
    // 圖 04：左＝正面剖視（Z＝PCB 頂上方 0.35 水平切，拿掉上半與蓋）；右＝側面剖視（沿走線缺口 X＝X_n 縱切，轉成切面朝上）
    // 正交俯視相機；壁掛姿態：Y 朝上（感測端在下）。版面中心約 (0, 27)
    za = Z_p + 0.35;
    ax = -14;                 // 左圖中心 X
    bx = 37;                  // 右圖（側剖）牆面 X；左緣＝bx-Z_T
    xl = ax - outer_w/2 - 2;  // 左圖左側標註右對齊線
    xr = bx + 2;              // 右圖右側標註左對齊線
    translate([ax, 0, 0]) intersection() {
        union() { c_body(); parts_all(); }
        color(COL_CUT) translate([-60, -20, -1]) cube([120, L + 40, za + 1]);
    }
    translate([bx, 0, 0]) rotate([0, -90, 0]) intersection() {
        union() { c_body(); parts_all(); c_lid(0); }
        color(COL_CUT) translate([-60, -20, -1]) cube([60 + X_n, L + 40, 80]);
    }
    ya = (bxy([esp_ant_bx[0], 0])[1] + bxy([esp_ant_bx[1], 0])[1]) / 2;
    ax_ant = ax + bxy([0, (esp_ant_by[0] + esp_ant_by[1])/2])[0];
    lbl([ax, L + 6], 2.4, "正面剖視（PCB 上方水平切）", "center");
    lbl([bx - Z_T/2 + 3, L + 6], 2.4, "側面剖視（沿走線）", "center");
    lbl([bx - Z_T/2, L + 2.6], 1.6, "← 蓋／房間　　　牆 →", "center");
    // 左圖
    dim_x([ax - X_in, ya - 3.2], [ax + X_ae, ya - 3.2], str(X_ae + X_in), 0);
    lbl([xl, ya + 3], 1.9, "陶瓷天線前方", "right");
    lbl([xl, ya + 0.2], 1.9, str("留 ", X_ae + X_in, " mm 空氣＋側牆開窗"), "right");
    ln([xl + 0.6, ya + 3], [ax_ant - 0.6, ya + 3]);
    lbl([xl, y_m1 - 1], 1.9, "MCU 艙：C3 橫放、熱往上排", "right");
    lbl([xl, (y_pa0 + y_pb1)/2 + 1.4], 1.9, "雙層實心隔牆＋通風隔熱縫", "right");
    lbl([xl, (y_pa0 + y_pb1)/2 - 1.6], 1.9, "只留 4 線缺口（右）", "right");
    lbl([xl, (y_sb + y_pa0)/2 + 2], 1.9, "感測艙：四面＋背＋蓋格柵", "right");
    lbl([xl, y_sf - 1.5], 1.9, "感測面朝下端格柵", "right");
    ln([xl + 0.6, y_sf - 1.5], [ax - sens_w/2 - 0.5, y_sf + 0.3]);
    lbl([ax + outer_w/2 + 1.2, Y_uc + 5.5], 1.9, "USB-C", "left");
    lbl([ax + outer_w/2 + 1.2, Y_uc + 2.8], 1.6, "線往右→下", "left");
    // 右圖
    lbl([xr, y_m0 + 13], 1.9, "C3 元件面朝蓋", "left");
    lbl([xr, y_m0 + 10.3], 1.9, str("PCB 離牆 ", Z_e, " mm"), "left");
    lbl([xr, kh_y[1] + kh_len/2 - 3.5], 1.9, "鑰匙孔 ×2", "left");
    lbl([xr, kh_y[1] + kh_len/2 - 6.2], 1.6, "頭部腔藏在背板內、不穿透", "left");
    lbl([xr, (y_pa0 + y_pb1)/2], 1.9, "4 線穿過隔牆缺口", "left");
    lbl([xr, y_sb + 7], 1.9, "感測板直立＋杜邦母頭", "left");
    lbl([xr, kh_y[0] + kh_len/2 - 3.5], 1.9, "鑰匙孔", "left");
} else if (part == "antenna_combo") {
    // 圖 05：過天線中心的 XZ 剖面（保留 +Y 半邊），轉成切面朝上；正交俯視。下＝背面（貼牆）、上＝滑蓋（朝房間）
    ya = (bxy([esp_ant_bx[0], 0])[1] + bxy([esp_ant_bx[1], 0])[1]) / 2;
    rotate([-90, 0, 0]) translate([0, -ya, 0]) intersection() {
        union() { c_body(); parts_all(); c_lid(0); }
        color(COL_CUT) translate([-60, ya, -1]) cube([120, L + 20, 80]);
    }
    // 轉換後：畫面 X＝原 X、畫面 Y＝原 Z
    xa = bxy([0, (esp_ant_by[0] + esp_ant_by[1])/2])[0];
    lbl([0, Z_T + 10], 2.4, "天線端剖面（過陶瓷天線中心，從感測端往上看）", "center");
    dim_x([-X_in, Z_p + 2.6], [X_ae, Z_p + 2.6], str(X_ae + X_in), 0);
    lbl([-outer_w/2 - 2, Z_p + 4.6], 1.9, "天線前方空氣", "right");
    lbl([-outer_w/2 - 2, Z_p + 2.0], 1.9, str(X_ae + X_in, " mm（≥8）"), "right");
    lbl([-outer_w/2 - 2, (vz0 + vz1)/2 - 3.2], 1.9, "側牆開窗（格柵）", "right");
    ln([-outer_w/2 - 1.4, (vz0 + vz1)/2 - 3.2], [-X_in - wall/2, (vz0 + vz1)/2 - 1.0]);
    lbl([xa - 1.0, Z_T + 5.2], 1.9, "陶瓷天線（上方只有 2.2 mm 滑蓋）", "left");
    ln([xa, Z_p + 1.3], [xa - 0.4, Z_T + 4.0]);
    dim_y([outer_w/2 + 1.8, 0], [outer_w/2 + 1.8, Z_e], str("PCB 離牆 ", Z_e, " mm"));
    lbl([outer_w/2 + 2, Z_u + 2.4], 1.9, "USB-C 母座（伸入側牆 U 缺口）", "left");
    lbl([0, -3.2], 1.8, "背面貼牆；鑰匙孔頭部腔藏在背板內、不穿透到電子艙", "center");
    // 下圖：MCU 艙俯視（PCB 上方水平切）——角塊只壓板角、天線前方淨空、側牆開窗
    za = Z_p + 0.35;
    yc = (y_m0 + y_m1)/2;
    py = -33;                                   // 下圖中心在畫面 Y
    translate([0, py - yc, -40]) intersection() {
        union() { c_body(); parts_all(false); }
        color(COL_CUT) translate([-60, y_pb0 - 0.5, -1]) cube([120, L - y_pb0 + 1, za + 1]);
    }
    lbl([0, py + (L - yc) + 4], 2.4, "MCU 艙俯視（PCB 上方水平切）", "center");
    dim_x([-X_in, py], [X_ae, py], str(X_ae + X_in), 0);
    lbl([-outer_w/2 - 2, py + 1.4], 1.9, "天線前方空氣", "right");
    lbl([-outer_w/2 - 2, py - 1.4], 1.9, "＋側牆開窗", "right");
    lbl([-outer_w/2 - 2, py + (y_m1 - 1.5 - yc)], 1.9, "角塊：擋面＋45° 楔口", "right");
    lbl([-outer_w/2 - 2, py + (y_m1 - 1.5 - yc) - 2.8], 1.6, "只壓板角，離天線 ≥2.5", "right");
    ln([-outer_w/2 - 1.4, py + (y_m1 - 1.5 - yc)], [X_ae - 1.2, py + (y_m1 - 1.5 - yc)]);
    lbl([outer_w/2 + 2, py + (y_m1 - yc) + 1.5], 1.9, "上端牆排氣格柵", "left");
    lbl([outer_w/2 + 2, py + (Y_uc - yc)], 1.9, "USB-C（線往右）", "left");
    lbl([outer_w/2 + 2, py + (y_m0 - yc) - 1.0], 1.9, "隔牆 B（下為感測艙）", "left");
} else if (part == "wall_view") {
    // 壁掛姿態（感測端朝下、USB 線往右下）
    rotate([90, 0, 0]) {
        c_body(); parts_all(); c_lid(0);
        usb_cable_ref();
    }
    color("#b9b4aa") translate([-70, 0.0, -30]) cube([140, 1, 130]);
} else if (part == "dims") {
    echo(str("DIMS {\"esp_hdr\":\"", esp_hdr, "\",\"sensor\":\"", sensor_variant, "\",\"Z_f\":", Z_f, ",\"Z_e\":", Z_e, ",\"Z_p\":", Z_p,
             ",\"Z_u\":", Z_u, ",\"Z_L\":", Z_L, ",\"Z_T\":", Z_T, ",\"Z_s\":", Z_s, ",\"pcb_t\":", esp_pcb_t, ",\"wedge_gap\":", wedge_gap,
             ",\"notch_drop\":", notch_drop, ",\"bump_h\":", bump_h, ",\"bump_base\":", bump_base, ",\"bump_top\":", bump_top,
             ",\"bump_len\":", bump_len, ",\"bump_y\":", bump_y, ",\"lid_t\":", lid_t, ",\"lid_foot\":", lid_foot, ",\"fdm_gap\":", fdm_gap,
             ",\"X_in\":", X_in, ",\"wall\":", wall, ",\"wall_bot\":", wall_bot, ",\"wall_top\":", wall_top, ",\"outer_w\":", outer_w, ",\"L\":", L,
             ",\"y_in0\":", y_in0, ",\"y_sf\":", y_sf, ",\"y_sb\":", y_sb, ",\"y_pa0\":", y_pa0, ",\"y_pa1\":", y_pa1, ",\"y_pb0\":", y_pb0,
             ",\"y_m0\":", y_m0, ",\"y_m1\":", y_m1, ",\"y_pcb0\":", y_pcb0, ",\"y_pcb1\":", y_pcb1, ",\"X_ue\":", X_ue, ",\"X_ae\":", X_ae,
             ",\"Y_uc\":", Y_uc, ",\"X_n\":", X_n, ",\"y_lead\":", y_lead, ",\"slit_end_y\":", slit_end_y, ",\"slit_w\":", slit_w,
             ",\"tongue_w\":", tongue_w, ",\"lid_hw\":", lid_hw, ",\"vz0\":", vz0, ",\"vz1\":", vz1, ",\"part_t\":", part_t,
             ",\"part_gap\":", part_gap, ",\"kh_x\":", kh_x, ",\"kh_y\":[", kh_y[0], ",", kh_y[1], "],\"kh_len\":", kh_len,
             ",\"kh_lip\":", kh_lip, ",\"kh_head\":", kh_head, ",\"kh_d\":", kh_d, ",\"kh_w\":", kh_w, ",\"floor_t\":", floor_t,
             ",\"ant_x0\":", bxy([0, esp_ant_by[1]])[0], ",\"ant_y\":[", bxy([esp_ant_bx[1], 0])[1], ",", bxy([esp_ant_bx[0], 0])[1], "]",
             ",\"lid_win_x0\":", lid_win_x0, ",\"lid_win_x1\":", lid_win_x1, ",\"lid_rows_y\":", str(lid_rows_y), ",\"label_fits\":", label_fits,
             ",\"ant_slot_x\":[", ant_slot_x[0], ",", ant_slot_x[1], "],\"label_y\":", label_y, ",\"label_depth\":", label_depth,
             ",\"sens_w\":", sens_w, ",\"sens_h\":", sens_h, ",\"s_slot_x\":", s_slot_x, ",\"s_lip_x\":", s_lip_x,
             ",\"plug_w\":", plug_typec[0], ",\"plug_h\":", plug_typec[1], ",\"esp_usb_over\":", esp_usb_over, "}"));
    cube(1);
} else if (part == "check_parts_body") {
    intersection() { body(); parts_all(); }
} else if (part == "check_parts_lid") {
    intersection() { lid(); parts_all(); }
} else if (part == "check_lid_body") {
    intersection() { body(); lid(); }
} else if (part == "check_slide") {
    // 滑蓋自關閉位置一路往 +Y 滑出（不含扣點凸起：那是彈片要越過處）
    intersection() { body(false); for (d = [0.5 : 1.0 : L + 4]) translate([0, d, 0]) lid(); }
}
