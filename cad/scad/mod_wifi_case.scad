// =====================================================================
//  MOD-WIFI R2  Wi-Fi 偵測節點＋HITACHI 日立冷氣 IR 遙控（遙控器 RF11T1）外殼
//  ESP32-C3 SuperMini（已焊排針，塑膠座在板下）＋AHT20+BMP280＋IR LED（5 mm／3 mm 轉接套）＋VS1838B（必要：學習遙控碼）＋IR 驅動洞洞板
//  兩件主件（殼身＝黑、滑蓋＝白）＋小件（3 mm LED 轉接套、頂壓條 ×2＝黑）。
//  單位 mm。座標（組裝座標＝Onshape 匯入座標）：
//    X＝寬（以中心為 0；+X＝USB-C 那側，壁掛正面看在右邊）
//    Y＝長（Y=0＝感測端外表面＝壁掛時的下端；Y=L＝上端，滑蓋由此滑出）
//    Z＝深（Z=0＝背面＝貼牆面＝貼床面；+Z＝滑蓋／朝房間）
//  佈局（Y 由小到大）：感測端牆（格柵、扣點、防滑腳位）→ 感測通風艙（板子直立、感測面朝下端格柵；薄底 2.4）
//        → 雙層實心隔牆＋通風隔熱縫（只留 4 線缺口）→ MCU 艙（C3 橫放：USB-C 朝 +X、天線朝 -X，前方 14.4 mm 空氣＋側牆開窗）
//        → MCU/IR 隔牆（上半排氣槽＋底部 5 線缺口）→ IR 艙（列 1：直立洞洞板；列 2：IR LED 座（-X）＋接收頭座（+X））
//        → 上端牆（降到蓋底以下，滑蓋出口；中段排氣格柵）
//  IR LED：在蓋面（朝室內）上端、往上傾 15°；LED 頂在蓋底下 0.5–1.3，蓋上開喇叭形窗（發射錐 ±25°＋2° 不被遮）。
//  接線：感測 GND(A2)、3V3(A3)、GPIO4(A4)=SDA、GPIO5(B1)=SCL；IR 5V(A1)、GND(A2)、3V3(A3)、GPIO7(B3)=TX、GPIO6(B2)=RX
//        （A 排＝5V 排、B 排＝GPIO5 排，都從 USB 端數；都在 USB 那半，離天線遠）。
//  沿用 R1 已驗證特徵：45° 燕尾滑蓋、fdm_gap 0.30、lid_foot 0.3、彈片＋1.0 切縫＋R0.5、平頂梯形扣點 0.56/1.4/0.5、
//        鑰匙孔（腔頂 1.12 實心）、牆厚 0.8 倍數、肋 ≥1.0、全部免支撐。
//  R2 容差原則：未校準尺寸（PCB 厚、USB 凸出、排針長、感測板、洞洞板、LED、接收頭）都容 ±1 以上——
//        側擋＋頂壓條（摩擦齒、可調高度）＋泡棉/膠帶補，不做緊配口袋（REPORT_R2.md §3）。
//  實測版本：OpenSCAD 2026.10.29 snapshot（--backend Manifold）。
// =====================================================================

include <mod_wifi_ref.scad>   // 參考零件（只供預覽／干涉檢查）

/* [輸出選擇] */
part = "assembly";
// C3 排針：bottom＝已焊、塑膠座在板下、線焊在針尾（預設＝實際購買）；top＝塑膠座在板上（備用）；none＝無排針
esp_hdr = "bottom";              // [bottom, top, none]
// 感測器：aht20_bmp280（預設＝實際購買）；sht31（備用）
sensor_variant = "aht20_bmp280"; // [aht20_bmp280, sht31]
// 感測器端接法：solder＝4 條線直接焊（預設，艙短）；dupont＝焊 4 針排針＋杜邦母頭（艙長 +14.5）
sens_conn = "solder";            // [solder, dupont]
ir_led_ref_kind = 5;             // 預覽用：5＝5 mm LED；3＝3 mm LED＋轉接套
led8_window = true;              // 藍色 GPIO8 LED 窗
led_pwr_window = false;          // 紅色電源 LED 窗（常亮；預設不開）
led_window_type = "hole";        // [hole, thin]
label = ["WIFI", "NODE"];
lid_open_dy = 48;

/* [FDM（沿用已驗證值）] */
fdm_gap  = 0.30;
lid_foot = 0.3;

/* [ESP32-C3 SuperMini（板座標 [bx, by]：bx 自 GPIO5 排板邊、by 自 USB 端板邊）] */
esp_l     = 22.52;  // 官方 Nologo 尺寸圖（四來源一致）
esp_w     = 18.00;  // 官方
esp_row   = 15.24;  // 官方
esp_pin1  = 1.52;   // 估計（原廠 3D 圖量）
esp_pcb_t = 1.0;    // 估計（查無公開值；到貨量）——參考件用
esp_pcb_t_max = 1.6;// 設計上限：天線端角塊勾口開口按 1.6＋0.35 做（薄板用泡棉膠補）
esp_total_h = 4.5;  // PCB 底→USB 頂｜文章（Components101）
esp_usb_w = 8.94; esp_usb_h = 3.26; esp_usb_len = 7.35;   // 16P 母座常見值（文章）
esp_usb_over = 1.5;      // USB-C 凸出板邊（估計 1.5；原廠 3D 圖 1.9–2.0）
esp_usb_over_max = 2.5;  // U 缺口可容的最大凸出（±1）；插頭讓位孔貫穿，凸出 0 也插得到底
esp_usb_bx = 9.0;
esp_boot_xy = [6.2, 8.7];    // 估計（±0.3）
esp_rst_xy  = [11.7, 8.7];
esp_btn_h   = 2.0;
esp_led8_xy = [13.6, 11.1];
esp_led8_win = [14.0, 12.2]; // 與 RST 孔（Ø3.2）留 ≥1.0 肋
esp_ledp_xy = [3.0, 5.2];
esp_ant_bx  = [5.95, 12.05];
esp_ant_by  = [20.4, 22.4];
esp_side_gap = 0.5;  // 板長邊到艙牆（R1 0.3 → 0.5，容排針座歪斜）
esp_end_gap  = 0.3;  // USB 端板邊到 +X 牆
esp_stop_gap = 0.3;  // 天線端板邊到角塊擋面

/* [排針（已焊；典型值，到貨量）] */
hdr_plastic = 2.5;   // 塑膠座高
hdr_tail    = 6.5;   // 塑膠座以下針尾：設計上限（板下總長 9.0；brief 8.5–9；排針原廠圖 5.7±0.2 → 實際約 8.2）
hdr_top_h   = 2.0;   // bottom：板上短針＋焊點凸起（排針短端 3.0 − PCB 1.0；brief 典型 1.0，取 2.0 檢查）
hdr_tip_clear = 1.0; // 針尾尖到內底的餘裕（針尾 ≤10.0 都不碰）
hdr_up      = 6.5;   // top 版：塑膠座以上長針
hdr_short   = 2.0;   // 感測板 dupont 版：感測面側短針
dupont_len  = 14.0;
dupont_w    = 2.6;
wire_d      = 1.3;

/* [感測器小板（lookup；未校準，到貨量）] */
// w＝寬（X）、h＝高（Z，焊孔在下緣）、t＝PCB 厚、w_min／w_max、h_min／h_max＝導槽可容範圍、t_max＝導槽可容最大厚、
// pin_edge＝焊孔中心距下緣、pins＝由感測面看左→右、chips＝[[x 偏移, 中心距下緣, 寬, 高, 厚, 名]]、hole＝[x, 距下緣, 徑]
SENSORS = [
  // AHT20+BMP280：賣家 16×16×1.0；第三方照片量 14.5×14.6、Fritzing 15×15、另一賣家 16×16.5（research/sources_r2_parts.md）→ 導槽容 14.5–17
  ["aht20_bmp280", [["w", 16.0], ["h", 16.0], ["t", 1.0], ["w_min", 14.5], ["w_max", 17.0], ["h_min", 14.5], ["h_max", 17.0], ["t_max", 1.6],
                    ["pin_edge", 1.73], ["pins", ["VDD", "SDA", "GND", "SCL"]],
                    ["chips", [[-3.2, 12.6, 3.0, 3.0, 1.0, "AHT20"], [3.4, 12.8, 2.0, 2.5, 0.95, "BMP280"]]],   // 兩顆都在焊孔對側（估計）
                    ["hole", [0, 0, 0]], ["col", "#6b3fa0"]]],
  ["sht31", [["w", 13.0], ["h", 10.0], ["t", 1.6], ["w_min", 12.0], ["w_max", 14.0], ["h_min", 9.0], ["h_max", 11.0], ["t_max", 1.6],
             ["pin_edge", 1.3], ["pins", ["VIN", "GND", "SCL", "SDA"]],
             ["chips", [[1.0, 5.8, 2.5, 2.5, 0.9, "SHT31"]]], ["hole", [-2.0, 7.6, 3.0]], ["col", "#2d8a4e"]]]
];
sens_air  = 3.0;    // 感測面到下端牆內面的空氣層
sens_turn = 3.5;    // 焊線轉彎空間
sens_raise = 1.0;   // 板底離感測艙內底（空氣可從板下流過）
sens_x    = 0;
lip_t     = 1.2;    // 導槽唇厚

/* [頂壓條（列印小件；摩擦齒卡在導槽內，可調高度）] */
press_h   = 1.6;    // 高（Z）
press_t   = floor((1.6 + 2*fdm_gap - 0.2) / 0.28) * 0.28;   // 厚（Y）：導槽寬（最厚板＋2×fdm_gap）− 0.2，取 0.28 整數倍（fdm_gap 0.30 → 1.96＝7 層）
press_gap = 0.3;    // 最高板時壓條頂到滑蓋
press_tooth = 0.25; // 摩擦齒超出槽底的干涉量

/* [IR LED（5 mm 主；3 mm 用轉接套）] */
ant_clear = 14.4;    // 天線端板邊到 -X 牆（R1 8.0 → 14.4：殼加寬讓 IR 發射／接收相距 ≥25，天線淨空也更大）
led_tilt  = 15;      // 往上（+Y）傾
led5_d = 5.0; led5_fl_d = 5.8; led5_fl_h = 1.0;   // T-1¾ 常見（TSAL6200 類；到貨量）
led5_len = 8.6; led5_len_min = 8.2; led5_len_max = 9.0;  // 凸緣底→頂（TSAL6200 8.7±0.3；設計 8.2–9.0）
led3_d = 3.0; led3_fl_d = 3.8; led3_fl_h = 1.0; led3_len = 5.3;   // T-1（TSAL4400 類）
led_half_angle = 25;     // 半強度角（5 mm 940 nm 常見 ±17–25；取寬者）
led_cone_margin = 2;     // 窗口再加 2°
led_tip_gap = 0.5;       // 最長 LED（9.0）頂到滑蓋底
led_bore = 5.0;          // 卡扣環內徑（側向卡入；容 4.7–5.3）
led_c_open = 4.2;        // 卡扣環開口（< 4.7）
led_collar_h = 3.0;      // 卡扣環高
led_fl_pocket_d = 6.4;   // 凸緣槽徑（容 5.8±0.3）
led_fl_pocket_h = 1.3;   // 凸緣槽高（容 1.0±0.2）
led_tower_d = 9.0;       // 座外徑
led_lead_slot = 4.4;     // 腳線槽寬（往 -Y 開、到內底）
// 3 mm 轉接套
sl_od = 4.95;            // 外徑≈5 mm LED（卡扣環 5.0 夾持）
sl_step = 3.3;           // 3 mm LED 凸緣底在套內的高度（頂點對齊 5 mm 標稱頂點：3.3＋5.3＝8.6）
sl_bore = 3.0;           // 夾 3 mm 本體（兩道縫，容 2.7–3.3）

/* [VS1838B 接收頭（必要；透鏡朝 +Z；口袋＋雙面泡棉膠固定，滑蓋壓頂）] */
rx_body = [6.5, 7.4, 5.2];   // [寬 X, 高 Y（出腳方向）, 深 Z 含透鏡]｜1838 類 6.0–6.9 × 7.3–7.6 × 4.8–5.4；金屬罩款 6.9×7.3×5.2（文章／同類原廠）
rx_tol  = 1.0;               // 口袋容 ±1（多出來的用泡棉補）
rx_gap_top = 0.5;            // 最高接收頭頂到滑蓋底
rx_win_d = 8.0;              // 蓋上接收窗（直段）
rx_win_ch = 0.8;             // 窗口 45° 倒角（接收角更寬）

/* [IR 驅動洞洞板（約 20×15，容 ±1；或飛線）] */
pcb_ir = [20.0, 15.0];       // 寬（X）×高（Z）
pcb_ir_tol = 1.0;
pcb_ir_t_max = 1.6;
pcb_comp_h = 6.0;            // 元件面（朝 -Y）最高（TO-92 直立）
pcb_solder_h = 2.0;          // 焊接面凸出
pcb_x = 4.0;                 // 板中心 X（偏 USB 側，遠離天線）

/* [殼體（牆厚為 0.8 的倍數）] */
wall     = 3.2;
wall_bot = 4.0;
wall_top = 2.4;
wall_mi  = 1.6;     // MCU/IR 隔牆
part_t   = 1.6;
part_gap = 2.0;
lid_t    = 2.2;
lid_gap  = 0.6;
groove_d = 1.5;
groove_v = 0.7;
corner_r = 3.0;
edge_ch  = 0.6;
blk_len  = 2.4;
corner_w = 2.6;
hk       = 0.5;
ledge_len = 1.2;
hook_open = 2.1;    // 角塊平台頂到勾口底（PCB ≤1.6 時實隙 ≥0.35，見 check）
usbsup_len = 1.5;
usbsup_w = [6.5, 11.5];

/* [USB-C 插頭讓位孔（貫穿）] */
usb_cut = [13.8, 9.0];     // 寬（Y）×高（Z）：插頭 12.35×6.5 ±0.7／±1.25
usb_cut_r = 1.5;
usb_rim  = 0.8;
plug_body = [12.35, 6.5];

/* [格柵] */
slot_w = 2.0; rib_w = 1.6; rib_side_w = 2.4; rib_end_w = 1.2;

/* [滑蓋細節（沿用）] */
tongue_w = 4.8; tongue_len = 7.5; tongue_t = 1.6;
slit_w = 1.0; slit_round = true;
bump_h = 0.56; bump_base = 1.4; bump_top = 0.5; bump_len = 2.4;
btn_hole_d = 3.2;    // BOOT/RST 牙籤孔（R1 2.6 → 3.2：容 ±0.8）
led_hole_d = 2.4;
label_size = 4.0; label_lead = 5.6; label_depth = 0.56;

/* [壁掛鑰匙孔（藏在背板內）] */
kh_x    = 7.0;
kh_d    = 7.6; kh_w = 3.6; kh_len = 6.0;
kh_lip  = 1.4; kh_head = 2.52; kh_ceil = 1.12;
floor_t = kh_lip + kh_head + kh_ceil;   // 背板 5.04（MCU 艙、IR 艙）
floor_s = 2.4;                          // 感測艙薄底（鑰匙孔已移出感測艙）

/* [置物架防滑腳位] */
feet_d = 8.4; feet_depth = 0.6; feet_x = 13.6;

/* [盤面（BRIEF_R2_ADD：WIFI 專用區 X 162–220；件實體 X 168–214、Y 6–194）] */
bed_x = 220; bed_y = 220; bed_back_keep = 20;
zone_x = [162, 220];
zone_margin = 6;
plate_gap = 9;          // ≥8（留 1 mm 餘裕）
plate_cy = 100;       // 主件 Y 中心（熱床中段）

$fn = 48;
eps = 0.01;
big = 400;

// ------------------------- lookup -------------------------
function tbl(t, k) = let(i = search([k], t)[0]) assert(i != [], str("查無：", k)) t[i][1];
SV = tbl(SENSORS, sensor_variant);
function sv(k) = tbl(SV, k);
sens_w = sv("w"); sens_h = sv("h"); sens_t = sv("t"); sens_t_max = sv("t_max");
sens_w_max = sv("w_max"); sens_w_min = sv("w_min");
sens_h_max = sv("h_max"); sens_h_min = sv("h_min");
sens_pin_edge = sv("pin_edge"); sens_pins = sv("pins"); sens_np = len(sens_pins);
sens_chips = sv("chips"); sens_hole = sv("hole"); sens_col = sv("col");
function sens_sig(n) = n == "VIN" || n == "VCC" || n == "VDD" ? "3V3" : n;

// ------------------------- 推導尺寸（勿手改） -------------------------
X_in    = (ant_clear + esp_l + esp_end_gap) / 2;
outer_w = 2*(X_in + wall);
X_ue = X_in - esp_end_gap;
X_ae = X_ue - esp_l;

// Z
Z_f = floor_t;
esp_below = esp_hdr == "bottom" ? hdr_plastic + hdr_tail + hdr_tip_clear : 3.82;
Z_e = Z_f + esp_below;
Z_p = Z_e + esp_pcb_t;
Z_u = Z_p + esp_usb_h/2;
pcb_w_max = pcb_ir[0] + pcb_ir_tol; pcb_w_min = pcb_ir[0] - pcb_ir_tol;
pcb_h_max = pcb_ir[1] + pcb_ir_tol; pcb_h_min = pcb_ir[1] - pcb_ir_tol;
Z_s = floor_s + sens_raise;          // 感測板下緣（墊塊頂）
Z_L = max(Z_e + esp_pcb_t_max + (esp_total_h - esp_pcb_t) + lid_gap,   // 厚板時 USB 頂＋0.6
          Z_u + usb_cut[1]/2 + usb_rim,                                // 插頭讓位孔在燕尾槽下
          esp_hdr == "top" ? Z_p + hdr_plastic + hdr_up + 0.6 : 0,     // top 版長針
          Z_s + sens_h_max + press_h + press_gap,                      // 感測板（最高）＋頂壓條
          Z_f + pcb_h_max + press_h + press_gap,                       // 洞洞板（最高）＋頂壓條
          Z_e + hook_open + 0.9 + 0.6 + 0.5);                          // 角塊頂
Z_T = Z_L + lid_t;

// Y：感測艙 → 雙層隔牆 → MCU 艙 → MCU/IR 牆 → IR 艙
y_in0 = wall_bot;
y_sf  = y_in0 + sens_air;            // 感測面
y_sbm = y_sf + sens_t_max;           // 導槽後面（最厚板背面）
sens_reach = sens_conn == "dupont" ? hdr_plastic + dupont_len : 2.0;
y_pa0 = y_sbm + sens_reach + sens_turn;
y_pa1 = y_pa0 + part_t;
y_pb0 = y_pa1 + part_gap;
y_pb1 = y_pb0 + part_t;
y_m0  = y_pb1;
gap_lo = esp_hdr == "top" ? 1.8 : esp_side_gap;     // top 版：-Y 側留 1.8 讓線從板上繞下
y_pcb0 = y_m0 + gap_lo;
y_pcb1 = y_pcb0 + esp_w;
y_m1  = y_pcb1 + esp_side_gap;
y_i0  = y_m1 + wall_mi;
// IR 艙 列 1：洞洞板（元件面朝 -Y）
y_pv  = y_i0 + 1.0 + pcb_comp_h + pcb_ir_t_max/2;
y_r1e = y_pv + pcb_ir_t_max/2 + pcb_solder_h + 0.6;
// 列 2：LED 座（-X）、接收頭座（+X）
lid_top_hw = X_in + groove_d - fdm_gap - (lid_t - groove_v);   // 滑蓋頂面半寬
led_a  = [0, sin(led_tilt), cos(led_tilt)];
led_tc = led_half_angle + led_cone_margin;
P_led_z = Z_L - led_tip_gap - (led5_len_max - led5_d/2)*cos(led_tilt) - led5_d/2;
T_min_z = P_led_z + led5_len_min*cos(led_tilt);                 // 最短 LED 軸向頂點
led_win_rx = led5_d/2 + (Z_T - T_min_z) / (cos(led_tc)*cos(led_tilt)) * sin(led_tc);
led_x  = -(lid_top_hw - 1.0 - led_win_rx);
led_y0 = y_r1e + 0.5 + led_tower_d/2*cos(led_tilt);
P_led  = [led_x, led_y0, P_led_z];
T_min  = P_led + led5_len_min*led_a;
// 窗口 ±Y 邊（蓋頂 Z_T）
led_win_yhi = T_min[1] + led5_d/2*cos(led_tilt) + (Z_T - (T_min[2] - led5_d/2*sin(led_tilt)))*tan(led_tilt + led_tc);
led_win_ylo = T_min[1] - led5_d/2*cos(led_tilt) + (Z_T - (T_min[2] + led5_d/2*sin(led_tilt)))*tan(led_tilt - led_tc);
rx_x   = lid_top_hw - 1.0 - (rx_win_d/2 + rx_win_ch);
rx_y   = led_y0 + 1.0;
rx_pk  = [rx_body[0] + rx_tol + 2*fdm_gap, rx_body[1] + rx_tol + 2*fdm_gap];   // 口袋內尺寸
rx_z0  = Z_L - rx_gap_top - (rx_body[2] + rx_tol);                           // 口袋底（最高接收頭頂在蓋下 0.5）
rx_blk = [rx_x - rx_pk[0]/2 - 1.2, rx_y - rx_pk[1]/2 - 1.2];                 // 座塊 -X、-Y 外緣
led_tower_ytop = led_y0 + (led_fl_pocket_h + led_collar_h)*sin(led_tilt) + led_tower_d/2;
y_i1  = max(led_tower_ytop + 0.6, rx_y + rx_pk[1]/2, led_win_yhi + 1.5 - wall_top);
L     = y_i1 + wall_top;

// C3 腳位
function bxy(p) = [X_ue - p[1], y_pcb1 - p[0]];
function pin_xy(row, n) = bxy([row < 0 ? (esp_w - esp_row)/2 : esp_w - (esp_w - esp_row)/2, esp_pin1 + (n - 1)*2.54]);
// [名稱, row（+1＝A 排 5V 排；-1＝B 排 GPIO5 排）, n（自 USB 端）, 訊號]
sens_wires = [["GND", 1, 2, "GND"], ["3V3", 1, 3, "3V3"], ["GPIO4", 1, 4, "SDA"], ["GPIO5", -1, 1, "SCL"]];
ir_wires   = [["5V", 1, 1, "5V"], ["GND", 1, 2, "GND"], ["3V3", 1, 3, "3V3"], ["GPIO6", -1, 2, "IRRX"], ["GPIO7", -1, 3, "IRTX"]];
Y_uc = bxy([esp_usb_bx, 0])[1];
X_n  = (pin_xy(1, 2)[0] + pin_xy(1, 4)[0]) / 2 - 1.5;   // 雙層隔牆走線缺口中心
notch_w = 7.6; notch_h = 3.6;
X_nI = X_ue - 8.0;                                       // MCU/IR 牆走線缺口中心（USB 那半）
// 鑰匙孔：移出感測艙（感測艙薄底），兩孔上下相距 30
kh_y = [y_pa0 + 1.2 + kh_d/2, y_pa0 + 1.2 + kh_d/2 + 30];

// 滑蓋
y_lead    = y_in0 - groove_d + fdm_gap;
lid_y_tip = 0.4;
y_trail   = L;
lid_hw    = X_in + groove_d - fdm_gap;
slit_end_y = y_lead + tongue_len;
bump_y    = wall_bot/2 + 0.2;
notch_drop = 0.1;

// 角塊／勾口
z_h0 = Z_e + hook_open;
z_ht = z_h0 + 0.9 + 0.6;

// 感測導槽
s_slot_x = sens_w_max/2 + fdm_gap;                          // 槽底（容最寬板）
s_lip_x  = max(sens_w_min - s_slot_x - 0.8,               // 唇內緣：最窄板整片推到一側時，另一邊仍有 0.8 被唇擋（唇自板底 +3 起，避開焊孔）
               sens_conn == "dupont" ? sens_np*2.54/2 + 0.3 : 0);   //   dupont 版：避開排針塑膠座
s_post_x = s_slot_x + 2.4;
s_slot_t = sens_t_max + 2*fdm_gap;
// 洞洞板導槽（相對 pcb_x）
p_slot_x = pcb_w_max/2 + fdm_gap;
p_lip_x  = pcb_w_min - p_slot_x - 0.8;
p_post_x = p_slot_x + 2.4;
p_slot_t = pcb_ir_t_max + 2*fdm_gap;

assert(lid_foot < groove_v, "lid_foot 必須 < groove_v");
assert(z_ht < Z_L - 0.5, "角塊太高");
assert(floor_t >= kh_lip + kh_head + kh_ceil - 1e-6, "背板不夠厚");
assert(s_post_x < X_in - 2, "感測板太寬");
assert(press_t < s_slot_t - 0.1 && press_t < p_slot_t - 0.1, "頂壓條太厚");
assert(rib_w >= 1.0 && rib_side_w >= 1.0 && rib_end_w >= 1.0 && lip_t >= 1.0, "肋需 ≥ 1.0");
assert(ant_clear >= 8, "天線前方空氣需 ≥ 8");
assert(Z_u + usb_cut[1]/2 <= Z_L - usb_rim + 1e-6, "USB 讓位孔碰到燕尾槽");
assert(X_ue + esp_usb_over_max + 0.2 <= X_in + wall - 0.8 + 1e-6, "U 缺口外皮 < 0.8");
assert(pcb_x + p_post_x <= X_in + 1e-6 && pcb_x - p_post_x >= -X_in, "洞洞板導槽超出內腔");
assert(P_led_z > Z_f + 6, "LED 座太低");
assert(led_x - led_tower_d/2 >= -X_in - 1e-6, "LED 座超出內腔");
assert(rx_x + rx_pk[0]/2 + 1.2 <= X_in + 1.2 + 1e-6, "接收頭座超出內腔");
assert(rx_x - led_x >= 25 - 1e-6, "IR 發射與接收相距需 ≥25");
assert(kh_y[1] + kh_len + kh_d/2 <= L - 1.6, "上鑰匙孔太靠上端");

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
module end_extrude(w) { translate([-w/2, y_in0, 0]) rotate([90, 0, 90]) linear_extrude(w) mirror([1, 0]) children(); }
module end_groove() { end_extrude(2*(X_in + groove_d + 0.5)) groove_2d(); }
module end_extrude_r(w) { translate([0, y_in0, 0]) rotate([90, 0, 90]) linear_extrude(w) mirror([1, 0]) children(); }
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
        linear_extrude(eps) offset(delta = -edge_ch) rrect(-outer_w/2, outer_w/2, 0, L, corner_r);
        translate([0, 0, edge_ch]) linear_extrude(Z_T - 2*edge_ch) rrect(-outer_w/2, outer_w/2, 0, L, corner_r);
        translate([0, 0, Z_T - eps]) linear_extrude(eps) offset(delta = -edge_ch) rrect(-outer_w/2, outer_w/2, 0, L, corner_r);
    }
}
module shell() {
    difference() {
        outer_solid();
        translate([-X_in, y_in0, floor_s]) cube([2*X_in, y_pa0 - y_in0, Z_T]);   // 感測艙（薄底）
        translate([-X_in, y_pa0, Z_f]) cube([2*X_in, y_i1 - y_pa0, Z_T]);
    }
}
module partitions() {
    for (y0 = [y_pa0, y_pb0]) translate([-X_in - eps, y0, Z_f - eps]) cube([2*X_in + 2*eps, part_t, (Z_L - 0.4) - Z_f + eps]);
    translate([-X_in - eps, y_m1, Z_f - eps]) cube([2*X_in + 2*eps, wall_mi, (Z_L - 0.4) - Z_f + eps]);   // MCU/IR 牆
}
module wire_notches() {
    translate([X_n - notch_w/2, y_pa0, Z_f]) cube([notch_w, y_pb1 - y_pa0 + 1, notch_h]);   // 底面＝內底（不往下挖：下方是鑰匙孔腔）
    translate([X_nI - notch_w/2, y_m1 - 1, Z_f]) cube([notch_w, wall_mi + 2, notch_h]);
}

// C3 天線端角塊（兩角）：擋面＋板底平台＋45° 勾口（開口 hook_open，容 PCB ≤1.6）
module esp_corner_blocks() {
    u0 = -esp_stop_gap - blk_len;
    for (c = [[y_m0, 1], [y_m1, -1]]) {
        ya = c[1] > 0 ? c[0] - eps : c[0] - (esp_side_gap + corner_w);
        yb = c[1] > 0 ? c[0] + gap_lo + corner_w : c[0] + eps;
        translate([X_ae, yb, 0]) rotate([90, 0, 0]) linear_extrude(yb - ya)
            polygon([[u0, Z_f - eps], [ledge_len, Z_f - eps], [ledge_len, Z_e], [-esp_stop_gap, Z_e],
                     [-esp_stop_gap, z_h0], [hk, z_h0], [hk + 0.9, z_h0 + 0.9], [hk + 0.9, z_ht], [u0, z_ht]]);
    }
}
module esp_usb_support() {
    translate([X_ue - usbsup_len, y_pcb0 + usbsup_w[0], Z_f - eps]) cube([usbsup_len + esp_end_gap + eps, usbsup_w[1] - usbsup_w[0], Z_e - Z_f + eps]);
}
module usb_cuts() {
    // 插頭讓位孔：貫穿側牆（PCB 板邊靠孔兩側的牆面擋拔線拉力）
    translate([X_in - 1, Y_uc, Z_u]) rotate([0, 90, 0]) linear_extrude(wall + 2)
        offset(r = usb_cut_r) offset(delta = -usb_cut_r) square([usb_cut[1], usb_cut[0]], center = true);
    // 母座 U 缺口（向上開口，板子由上放入）：深到可容凸出 esp_usb_over_max＋0.2，外皮留 0.8
    translate([X_in - 1, Y_uc - (esp_usb_w/2 + fdm_gap), Z_u]) cube([1 + (X_ue + esp_usb_over_max + 0.2 - X_in), esp_usb_w + 2*fdm_gap, Z_T]);
}

// 直立板導槽（兩側柱，唇下 45°）：cx＝板中心 X、yf＝板前面、tm＝最厚板、slot_x／lip_x／post_x、z0＝柱底、zlip＝唇起點、zpad＝墊塊頂
module board_posts(cx, yf, tm, slot_x, lip_x, post_x, z0, zlip, zpad) {
    z_top = Z_L - 0.4;
    yf0 = yf - fdm_gap - lip_t; yf1 = yf - fdm_gap;
    yb0 = yf + tm + fdm_gap;    yb1 = yb0 + lip_t;
    for (s = [-1, 1]) translate([cx, 0, 0]) mirror([s < 0 ? 1 : 0, 0, 0]) {
        translate([0, yb1, 0]) rotate([90, 0, 0]) linear_extrude(yb1 - yf0)
            polygon([[slot_x, z0 - eps], [post_x, z0 - eps], [post_x, z_top], [slot_x, z_top]]);
        for (yy = [[yf0, yf1], [yb0, yb1]])
            translate([0, yy[1], 0]) rotate([90, 0, 0]) linear_extrude(yy[1] - yy[0])
                polygon([[lip_x, zlip], [slot_x, zlip - (slot_x - lip_x)], [slot_x + 1.2, zlip - (slot_x - lip_x)], [slot_x + 1.2, z_top], [lip_x, z_top]]);
        if (zpad > z0 + 0.01)
            translate([lip_x, yf1 - eps, z0 - eps]) cube([slot_x - lip_x + eps, yb0 - yf1 + 2*eps, zpad - z0 + eps]);
    }
}
module sens_posts() board_posts(sens_x, y_sf, sens_t_max, s_slot_x, s_lip_x, s_post_x, floor_s, Z_s + 3.0, Z_s);
module pcb_posts()  board_posts(pcb_x, y_pv - pcb_ir_t_max/2, pcb_ir_t_max, p_slot_x, p_lip_x, p_post_x, Z_f, Z_f + 1.5 + (p_slot_x - p_lip_x), Z_f);

// IR LED 座：立柱（頂面＝傾斜 15° 的凸緣平台）＋凸緣槽（上下夾住凸緣）＋C 形卡扣環（側向 -Y 卡入）＋腳線槽（往 -Y 開到內底）
module led_tower() {
    hull() {
        led_frame() translate([0, 0, -eps]) cylinder(d = led_tower_d, h = eps);
        translate([led_x, led_y0, Z_f - 0.3]) linear_extrude(eps) scale([1, cos(led_tilt)]) circle(d = led_tower_d);   // 柱底埋入背板 0.3
    }
    led_frame() translate([0, 0, -0.4]) cylinder(d = led_tower_d, h = 0.4 + led_fl_pocket_h + led_collar_h);   // 往下重疊 0.4（避免與柱頂共面）
}
module led_tower_cuts() {
    led_frame() {
        cylinder(d = led_fl_pocket_d, h = led_fl_pocket_h);                                     // 凸緣槽
        translate([-led_fl_pocket_d/2, -10, 0]) cube([led_fl_pocket_d, 10, led_fl_pocket_h]);   //   往 -Y 開口
        translate([0, 0, led_fl_pocket_h - eps]) cylinder(d = led_bore, h = led_collar_h + 1);  // 卡扣環
        translate([-led_c_open/2, -10, led_fl_pocket_h - eps]) cube([led_c_open, 10, led_collar_h + 1]);
    }
    // 腳線槽：自平台往下到內底、往 -Y 開
    translate([led_x - led_lead_slot/2, led_y0 - led_tower_d, Z_f - 0.01]) cube([led_lead_slot, led_tower_d + 1.2, P_led_z - Z_f + 0.01 + 0.6]);   // 槽面過軸線 1.2（避開柱身橢圓最寬處的共切線）
}
// VS1838B 座：自內底立起的座塊（頂＝口袋底），口袋三面牆（-Y 面開，給腳線往下）、+X 面靠側牆
module rx_seat() {
    translate([rx_blk[0], rx_blk[1], Z_f - eps]) cube([X_in + eps - rx_blk[0], rx_pk[1] + 2.4, Z_L - 0.4 - Z_f + eps]);
}
module rx_seat_cuts() {
    translate([rx_x - rx_pk[0]/2, rx_y - rx_pk[1]/2, rx_z0]) cube([rx_pk[0], rx_pk[1], Z_T]);          // 口袋
    translate([rx_x - (rx_body[0] - 0.4)/2, rx_blk[1] - 1, Z_f - 0.01]) cube([rx_body[0] - 0.4, rx_pk[1]/2 + 1.2, Z_T]);   // -Y 開口＋腳線槽到底（不挖背板：下方是鑰匙孔腔）
}

// 通風格柵
function slot_centers(a, b, pitch) = let(n = floor((b - a - slot_w) / pitch + 1e-6) + 1, used = (n - 1)*pitch + slot_w, s0 = a + (b - a - used)/2 + slot_w/2)
    [for (i = [0 : n - 1]) s0 + i*pitch];
vz0s = floor_s + 1.0;         // 感測艙牆上格柵下緣
vz0  = Z_f + 1.0;             // 其他牆上格柵下緣
vz1  = Z_L - 2.4;             // 牆上格柵上緣
end_slots_x = slot_centers(-(feet_x - feet_d/2 - 1.2), feet_x - feet_d/2 - 1.2, slot_w + rib_end_w);
sens_side_y = slot_centers(y_in0 + 1.5, y_pa0 - 1.5, slot_w + rib_side_w);
ant_win_y   = slot_centers(y_m0 + 1.5, y_m1 - 1.5, slot_w + rib_side_w);
top_slots_x = slot_centers(led_x + led_tower_d/2 + 1.6, rx_blk[0] - 1.6, slot_w + rib_w);
mi_slots_x  = slot_centers(X_ae + 3.0, X_nI - notch_w/2 - 1.0, slot_w + rib_w);
floor_slots_x = slot_centers(-(X_in - 1.4), X_in - 1.4, slot_w + rib_w);
module vents() {
    for (x = end_slots_x) translate([x - slot_w/2, -1, vz0s]) cube([slot_w, y_in0 + 2, vz1 - vz0s]);
    for (s = [-1, 1]) {
        xw = s > 0 ? X_in - 1 : -X_in - wall - 1;
        for (y = sens_side_y) translate([xw, y - slot_w/2, vz0s]) cube([wall + 2, slot_w, vz1 - vz0s]);
        translate([xw, y_pa1, vz0]) cube([wall + 2, part_gap, vz1 - vz0]);      // 隔熱縫兩側通氣
    }
    for (y = ant_win_y) translate([-X_in - wall - 1, y - slot_w/2, vz0]) cube([wall + 2, slot_w, vz1 - vz0]);   // 天線側開窗
    for (x = top_slots_x) translate([x - slot_w/2, y_i1 - 1, vz0]) cube([slot_w, wall_top + 2, (Z_L - 1.6) - vz0]);   // 上端排氣
    for (x = mi_slots_x) translate([x - slot_w/2, y_m1 - 1, Z_p + 1.4]) cube([slot_w, wall_mi + 2, (Z_L - 1.6) - (Z_p + 1.4)]);  // MCU→IR 艙
    for (x = floor_slots_x) translate([x - slot_w/2, y_sbm + fdm_gap + lip_t + 0.6, -1]) cube([slot_w, (y_pa0 - 1.0) - (y_sbm + fdm_gap + lip_t + 0.6), floor_s + 2]);
}

// 扣點
module detent_notch() { translate([-(tongue_w/2 + fdm_gap), -1, Z_L - notch_drop]) cube([tongue_w + 2*fdm_gap, y_in0 + 1 + eps, Z_T]); }
module detent_bump() {
    sl = (bump_base - bump_top) / 2 / bump_h;
    hb = bump_base/2 + sl*(notch_drop + eps);
    translate([-bump_len/2, 0, 0]) rotate([90, 0, 90]) linear_extrude(bump_len)
        polygon([[bump_y - hb, Z_L - notch_drop - eps], [bump_y + hb, Z_L - notch_drop - eps],
                 [bump_y + bump_top/2, Z_L + bump_h], [bump_y - bump_top/2, Z_L + bump_h]]);
}
module keyholes() {
    for (ky = kh_y) translate([kh_x, ky, 0]) {
        translate([0, 0, -1]) cylinder(d = kh_d, h = 1 + kh_lip + eps);
        translate([0, 0, -1]) hull() { cylinder(d = kh_w, h = 1 + kh_lip + eps); translate([0, kh_len, 0]) cylinder(d = kh_w, h = 1 + kh_lip + eps); }
        translate([0, 0, kh_lip]) hull() { cylinder(d = kh_d, h = kh_head); translate([0, kh_len, 0]) cylinder(d = kh_d, h = kh_head); }
    }
}
feet_z = [5.0, Z_T - 5.6];
module feet_recesses() { for (x = [-feet_x, feet_x], z = feet_z) translate([x, -1, z]) rotate([-90, 0, 0]) cylinder(d = feet_d, h = 1 + feet_depth); }

module body(with_bump = true) {
    union() {
        difference() {
            union() {
                shell();
                partitions();
                esp_corner_blocks();
                esp_usb_support();
                sens_posts();
                pcb_posts();
                led_tower();
                rx_seat();
            }
            side_grooves();
            end_groove();
            groove_leadins();
            translate([-X_in, y_i1 - eps, Z_L - 0.2]) cube([2*X_in, wall_top + 1, Z_T]);   // 上端牆降到蓋底以下：滑蓋出口
            usb_cuts();
            vents();
            detent_notch();
            wire_notches();
            keyholes();
            feet_recesses();
            led_tower_cuts();
            rx_seat_cuts();
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
            end_extrude(2*(X_in + groove_d)) lid_edge_2d(false);
            translate([-tongue_w/2 - slit_w/2, lid_y_tip, Z_L - 1]) cube([tongue_w + slit_w, y_lead + 2.0 - lid_y_tip, 1 + tongue_t]);
        }
        translate([0, 0, Z_L - 1]) linear_extrude(lid_t + 2) rrect(-lid_hw, lid_hw, y_lead - 6, y_trail, 2.0);
    }
}
module slit_2d(x0) {
    if (slit_round) hull() {
        translate([x0, -1]) square([slit_w, slit_end_y + 1]);
        translate([x0 + slit_w/2, slit_end_y]) circle(d = slit_w);
    } else translate([x0, -1]) square([slit_w, slit_end_y + 1]);
}
lid_win_x0 = tongue_w/2 + slit_w + 1.0;
lid_win_x1 = X_in - 2.4;
lid_rows_y = [for (i = [0 : 3]) let(y = y_in0 + 1.6 + i*(slot_w + rib_w)) if (y + slot_w/2 <= y_pa0 - 1.0) y];
label_y = y_i0 + (y_r1e - y_i0)/2;     // IR 艙列 1（洞洞板）上方，遠離所有窗孔
label_fits = (y_r1e - y_i0) >= (len(label) - 1)*label_lead + label_size + 0.8;
ant_slot_x = [for (i = [0 : 2]) X_ae - 1.6 - slot_w/2 - i*(slot_w + rib_w)];
lid_tail_grooves_y = [L - 2.2, L - 3.8, L - 5.4];
module lid_hole(p, d) {
    if (led_window_type == "thin" && d == led_hole_d)
        translate([p[0], p[1], Z_L - 1]) cylinder(d = d, h = 1 + lid_t - 0.56);
    else translate([p[0], p[1], Z_L - 1]) cylinder(d = d, h = lid_t + 2);
}
// IR LED 窗：發射錐（半角 led_tc）自最短 LED 頂點起
module led_window_cut() { led_cone(led_tc, 12, led5_len_min); }
module rx_window_cut() {
    translate([rx_x, rx_y, Z_L - 1]) cylinder(d = rx_win_d, h = lid_t + 2);
    translate([rx_x, rx_y, Z_T - rx_win_ch]) cylinder(d1 = rx_win_d, d2 = rx_win_d + 2*rx_win_ch + 0.02, h = rx_win_ch + 0.01);
}
module lid() {
    difference() {
        lid_blank();
        translate([-tongue_w/2 - slit_w/2, -1, Z_L + tongue_t]) cube([tongue_w + slit_w, slit_end_y + 1, lid_t]);
        for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) translate([tongue_w/2 + slit_w/2, 0, 0])
            end_extrude_r(lid_hw - 0.6 - (tongue_w/2 + slit_w/2))
                polygon([[groove_d - fdm_gap - lid_foot - 1, Z_L - 1], [groove_d - fdm_gap + 1, Z_L - 1], [groove_d - fdm_gap + 1, Z_L + lid_foot + 1]]);
        for (s = [-1, 1]) translate([0, 0, Z_L - 1]) linear_extrude(lid_t + 2) slit_2d(s > 0 ? tongue_w/2 : -tongue_w/2 - slit_w);
        translate([-(bump_len/2 + 0.2), bump_y - (bump_base/2 + 0.25), Z_L - 1]) cube([bump_len + 0.4, bump_base + 0.7, lid_t + 2]);
        for (s = [-1, 1], y = lid_rows_y) mirror([s < 0 ? 1 : 0, 0, 0]) translate([lid_win_x0, y - slot_w/2, Z_L - 1]) cube([lid_win_x1 - lid_win_x0, slot_w, lid_t + 2]);
        translate([-(lid_win_x1 - 2), y_pa1, Z_L - 1]) cube([2*(lid_win_x1 - 2), part_gap, lid_t + 2]);
        for (x = ant_slot_x, r = [[y_m0 + 1.0, (y_m0 + y_m1)/2 - 0.8], [(y_m0 + y_m1)/2 + 0.8, y_m1 - 1.0]])
            translate([x - slot_w/2, r[0], Z_L - 1]) cube([slot_w, r[1] - r[0], lid_t + 2]);
        for (b = [esp_boot_xy, esp_rst_xy]) translate([bxy(b)[0], bxy(b)[1], Z_L - 1]) cylinder(d = btn_hole_d, h = lid_t + 2);
        if (led8_window) lid_hole(bxy(esp_led8_win), led_hole_d);
        if (led_pwr_window) lid_hole(bxy(esp_ledp_xy), led_hole_d);
        led_window_cut();
        rx_window_cut();
        if (label_fits) for (i = [0 : len(label) - 1]) if (label[i] != "")
            translate([0, label_y + ((len(label) - 1)/2 - i)*label_lead, Z_T - label_depth]) linear_extrude(label_depth + 1)
                text(label[i], size = label_size, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
        for (y = lid_tail_grooves_y) translate([-6, y - 0.4, Z_T - 0.56]) cube([12, 0.8, 1]);
    }
}

// =====================================================================
//  列印小件
// =====================================================================
// 3 mm LED 轉接套（LED 座標系；外形＝5 mm LED 的凸緣＋本體，可直接卡進 5 mm 座）
sl_top = sl_step + led3_fl_h + 2.7;     // 夾到 3 mm 本體 2.7 mm（頂在 3 mm 透鏡起點下）
module led_sleeve() {
    difference() {
        union() {
            cylinder(d = led5_fl_d, h = led5_fl_h, $fn = 40);
            cylinder(d = sl_od, h = sl_top, $fn = 40);
        }
        translate([-1.7, -0.6, -1]) cube([3.4, 1.2, sl_step + 2]);                 // 兩支腳線孔（2.54 腳距＋彎曲）
        translate([0, 0, sl_step]) cylinder(d = led3_fl_d + 0.4, h = led3_fl_h + 0.15, $fn = 32);   // 3 mm 凸緣座
        translate([0, 0, sl_step + led3_fl_h]) cylinder(d = sl_bore, h = 10, $fn = 32);
        for (s = [-1, 1]) translate([s*sl_od/2, 0, sl_step + led3_fl_h + 0.6 + 5]) cube([sl_od, 0.8, 10], center = true);   // 夾爪縫
    }
}
// 頂壓條：2D 側面輪廓（X＝長、Z＝高），沿 Y 擠出 press_t；兩端各 2 個摩擦齒頂槽底
module press_profile(slot_x) {
    a = slot_x - fdm_gap;            // 本體半長（端面離槽底 0.3）
    polygon(concat([[-a, 0], [a, 0]],
                   [[a, 0.2], [slot_x + press_tooth, 0.5], [a, 0.8], [slot_x + press_tooth, 1.1], [a, 1.4]],
                   [[a, press_h], [-a, press_h]],
                   [[-a, 1.4], [-slot_x - press_tooth, 1.1], [-a, 0.8], [-slot_x - press_tooth, 0.5], [-a, 0.2]]));
}
module press_bar(slot_x) { rotate([90, 0, 0]) translate([0, 0, -press_t/2]) linear_extrude(press_t) press_profile(slot_x); }
// 組裝位置（標稱板高時）
module sens_press_asm() translate([sens_x, y_sf + sens_t_max/2, Z_s + sens_h]) press_bar(s_slot_x);
module pcb_press_asm()  translate([pcb_x, y_pv, Z_f + pcb_ir[1]]) press_bar(p_slot_x);
// =====================================================================
//  盤面（BRIEF_R2_ADD：只放在 WIFI 專用區；物理座標＝熱床前左角為原點）
// =====================================================================
pz_x0 = zone_x[0] + zone_margin;   // 168
pz_x1 = zone_x[1] - zone_margin;   // 214
pz_xc = (pz_x0 + pz_x1)/2;
// 黑盤：殼身（背面貼床）＋ 3 mm 轉接套 ×2（直立）＋頂壓條 ×2（側躺）
blk_body_o = [pz_xc, plate_cy - L/2, 0];
// 小件排在殼身下方，件距 ≥8（pcb_press 頂距殼身 8；sens_press 再往下 8；轉接套再往下 8）
blk_r1 = blk_body_o[1] - plate_gap - press_h;              // pcb_press 底（列印時寬＝press_h）
blk_r2 = blk_r1 - plate_gap - press_h;                     // sens_press 底
blk_r3 = blk_r2 - plate_gap - led5_fl_d/2;                 // 轉接套中心
blk_small_y = blk_r3;
blk_items = [
  ["pcb_press",  [pz_xc, blk_r1, 0]],
  ["sens_press", [pz_xc, blk_r2, 0]],
  ["sleeve_1",   [pz_xc - 7, blk_r3, 0]],
  ["sleeve_2",   [pz_xc + 7, blk_r3, 0]]
];
// 白盤：滑蓋（底面貼床）（接收頭為必要件，窗口常開，不印堵頭）
wht_lid_o = [pz_xc, plate_cy - (lid_y_tip + y_trail)/2, -Z_L];
wht_items = [];
module small_print(name) {
    if (name == "sleeve_1" || name == "sleeve_2") led_sleeve();
    else if (name == "sens_press") linear_extrude(press_t) press_profile(s_slot_x);
    else if (name == "pcb_press") linear_extrude(press_t) press_profile(p_slot_x);
}
module plate_black(colored = false) {
    color(colored ? COL_BODY : undef) {
        translate(blk_body_o) body();
        for (it = blk_items) translate(it[1]) small_print(it[0]);
    }
}
module plate_white(colored = false) {
    color(colored ? COL_LID : undef) {
        translate(wht_lid_o) lid();
        for (it = wht_items) translate(it[1]) small_print(it[0]);
    }
}
assert(pz_xc - outer_w/2 >= pz_x0 - 1e-6 && pz_xc + outer_w/2 <= pz_x1 + 1e-6, "殼身超出 WIFI 區 X 168–214");
assert(blk_body_o[1] >= zone_margin && blk_body_o[1] + L <= bed_y - bed_back_keep - zone_margin, "殼身超出 Y 6–194");
assert(blk_r3 - led5_fl_d/2 >= zone_margin, "黑盤小件超出 Y");

// 試配片盤（選印 COUPON；黑色單盤，≤30 分鐘）：
//  C1 滑軌段＝殼身感測端上段（燕尾槽、扣點、感測導槽上段）＋底板；C2 滑蓋前段（彈片、切縫、鼻片）；
//  C3 IR 段＝殼身上端 -X 角（LED 座、上端牆；切到蓋底下）＋轉接套；C4 USB 段＝+X 牆 USB 孔＋U 缺口
cp_c1_y1 = slit_end_y + 6.5;                   // C1/C2 長
cp_zc = ceil((vz1 + 0.3) / 0.28) * 0.28;       // C1 自此高度起（在牆格柵上方；0.28 整數倍＝層相位同主件）
cp_base = 1.12;
module cp_c1() {   // 組裝座標 → 平移到床面（底 = cp_zc - cp_base）
    translate([0, 0, -(cp_zc - cp_base)]) union() {
        intersection() { body(); translate([-big/2, -1, cp_zc]) cube([big, cp_c1_y1 + 1, big]); }
        intersection() { outer_solid(); translate([-big/2, -1, cp_zc - cp_base]) cube([big, cp_c1_y1 + 1, cp_base + eps]); }
    }
}
module cp_c2() translate([0, 0, -Z_L]) intersection() { lid(); translate([-big/2, -1, -1]) cube([big, cp_c1_y1 + 1.5, big]); }
cp_c3_y0 = led_y0 - led_tower_d/2 - 2.0;
cp_c3_x1 = led_x + led_tower_d/2 + 3.0;      // 只取 LED 座那側（接收頭座容 ±1，到貨量尺寸即可）
cp_c3_zc = floor((P_led_z - 2.2) / 0.28) * 0.28;   // 只留 LED 平台下 2.2
module cp_c3_body() {
    translate([0, 0, -(cp_c3_zc - cp_base)]) union() {
        intersection() { body(); translate([-big/2, cp_c3_y0, cp_c3_zc]) cube([big/2 + cp_c3_x1, big, (Z_L - 0.3) - cp_c3_zc]); }
        intersection() { outer_solid(); translate([-big/2, cp_c3_y0, cp_c3_zc - cp_base]) cube([big/2 + cp_c3_x1, big, cp_base + eps]); }
    }
}
module cp_c3_lid() translate([0, 0, -Z_L]) intersection() { lid(); translate([-big/2, cp_c3_y0 - 1, -1]) cube([big/2 + cp_c3_x1, big, big]); }
cp_c4_y = [Y_uc - usb_cut[0]/2 - 3.0, Y_uc + usb_cut[0]/2 + 3.0];
cp_c4_z0 = floor((Z_u - usb_cut[1]/2 - 2.0) / 0.28) * 0.28;
module cp_c4() {
    translate([0, 0, -(cp_c4_z0 - cp_base)]) union() {
        intersection() { body(); translate([X_in - 4.0, cp_c4_y[0], cp_c4_z0]) cube([big, cp_c4_y[1] - cp_c4_y[0], Z_L - 0.1 - cp_c4_z0]); }
        intersection() { outer_solid(); translate([X_in - 4.0, cp_c4_y[0], cp_c4_z0 - cp_base]) cube([big, cp_c4_y[1] - cp_c4_y[0], cp_base + eps]); }
    }
}
cp_o = [[60, 100], [110, 100], [60, 40], [110, 40], [160, 70], [150, 100]];
module plate_coupon() {
    translate([cp_o[0][0], cp_o[0][1] - cp_c1_y1/2, 0]) cp_c1();
    translate([cp_o[1][0], cp_o[1][1] - cp_c1_y1/2, 0]) cp_c2();
    translate([cp_o[2][0], cp_o[2][1] - (cp_c3_y0 + L)/2, 0]) cp_c3_body();
    translate([cp_o[4][0] - X_in, cp_o[4][1] - Y_uc, 0]) cp_c4();
    translate([cp_o[5][0], cp_o[5][1], 0]) led_sleeve();
}

// =====================================================================
//  預覽配色與場景（BRIEF_R2_ADD：黑殼身、白滑蓋）
// =====================================================================
COL_BODY = "#55585f";   // 黑 PLA（渲染提亮成深灰，細節才看得到；R1 教訓）
COL_LID  = "#f2f1ec";   // 白 PLA
COL_CUT  = "#e9973b";
COL_TXT  = "#26292d";
COL_CONE = "#ff5a3c";
module lbl(p, s, t, ha = "left") color(COL_TXT) translate([p[0], p[1], 60]) linear_extrude(0.1) text(t, size = s, font = "Heiti TC", halign = ha, valign = "center");
module ln(a, b, w = 0.22) color(COL_TXT) hull() { translate([a[0], a[1], 60]) cylinder(d = w, h = 0.1, $fn = 8); translate([b[0], b[1], 60]) cylinder(d = w, h = 0.1, $fn = 8); }
module tick(p, dir) color(COL_TXT) translate([p[0], p[1], 60]) rotate(dir) linear_extrude(0.1) polygon([[0, 0], [1.4, 0.5], [1.4, -0.5]]);
module dim_x(a, b, t, ty = 2.5) { ln(a, b); tick(a, 0); tick(b, 180); lbl([(a[0] + b[0])/2, a[1] + (ty == 0 ? 2.2 : ty)], 1.9, t, "center"); }
module dim_y(a, b, t) { ln(a, b); tick(a, 90); tick(b, -90); lbl([a[0] + 1.2, (a[1] + b[1])/2], 1.9, t, "left"); }
module bt(p, t, sz = 5) color(COL_TXT) translate([p[0], p[1], -0.15]) linear_extrude(0.1) text(t, size = sz, font = "Heiti TC", halign = "center", valign = "center");
module c_body() color(COL_BODY) body();
module c_lid(dy = 0) color(COL_LID) translate([0, dy, 0]) lid();
// 發射錐示意（半透明）
module cone_vis(len = 34) color(COL_CONE, 0.28) led_cone(led_half_angle, len, led5_len);
module all_parts(wires = true) { parts_all(wires); press_bars_asm(); }
function v3(p) = str("[", p[0], ",", p[1], ",", p[2], "]");
function zx(z) = -30 - z;

if (part == "body") {
    body();
} else if (part == "lid_asm") {
    lid();
} else if (part == "lid_print") {
    translate([0, 0, -Z_L]) lid();
} else if (part == "sleeve_asm") {
    led_frame() led_sleeve();
} else if (part == "sens_press_asm") {
    sens_press_asm();
} else if (part == "pcb_press_asm") {
    pcb_press_asm();
} else if (part == "plate_black") {
    plate_black();
} else if (part == "plate_white") {
    plate_white();
} else if (part == "plate_coupon") {
    plate_coupon();
} else if (part == "plate_view") {
    // 兩盤並排示意：左＝黑盤（WIFI 區）、右＝白盤（WIFI 區）；灰＝ASK 區（由另一專案填）
    for (k = [0, 1]) translate([k*240, 0, 0]) {
        color("#d6d6d6") translate([0, 0, -1.2]) cube([bed_x, bed_y - bed_back_keep, 1]);
        color("#e07a6a") translate([0, bed_y - bed_back_keep, -1.2]) cube([bed_x, bed_back_keep, 1]);
        color("#b9c9e6") translate([zone_x[0], 0, -1.1]) cube([zone_x[1] - zone_x[0], bed_y - bed_back_keep, 1]);
        color("#efe3c2") translate([0, 0, -1.1]) cube([158, bed_y - bed_back_keep, 1]);
        if (k == 0) plate_black(true); else plate_white(true);
        bt([79, 110], "ASK 專用區 X 0–158", 7);
        bt([191, 186], "WIFI 區", 5);
        bt([110, 207], "後緣 20 mm 留空（Y offset −20 刻意，不改）", 5);
        bt([110, -12], k == 0 ? "BLACK 盤（黑 PLA）" : "WHITE 盤（白 PLA）", 9);
    }
} else if (part == "assembly") {
    c_body(); all_parts(); c_lid(0);
} else if (part == "assembly_cone") {
    c_body(); all_parts(); c_lid(0); cone_vis();
} else if (part == "back") {
    rotate([0, 180, 0]) { c_body(); all_parts(); c_lid(0); }
} else if (part == "lid_open") {
    c_body(); all_parts(); c_lid(lid_open_dy);
} else if (part == "exploded") {
    c_body();
    translate([0, 0, 26]) all_parts(true);
    translate([0, 12, 52]) c_lid(0);
} else if (part == "top_open") {
    c_body(); all_parts();
} else if (part == "section_combo") {
    // 圖 04：左＝正面剖視（Z＝PCB 頂上方 0.35 水平切）；右＝側面剖視（沿 X＝X_n 縱切，轉成切面朝上）
    za = Z_p + 0.35;
    ax = -16; bx = 52;
    xl = ax - outer_w/2 - 2; xr = bx + 2;
    translate([ax, 0, 0]) intersection() {
        union() { c_body(); all_parts(); }
        color(COL_CUT) translate([-60, -20, -1]) cube([120, L + 40, za + 1]);
    }
    translate([bx, 0, 0]) rotate([0, -90, 0]) intersection() {
        union() { c_body(); all_parts(); c_lid(0); }
        color(COL_CUT) translate([-60, -20, -1]) cube([60 + X_n, L + 40, 80]);
    }
    lbl([ax, L + 6], 2.4, "正面剖視（PCB 上方水平切）", "center");
    lbl([bx - Z_T/2 + 3, L + 6], 2.4, "側面剖視（沿走線）", "center");
    lbl([bx - Z_T/2, L + 2.6], 1.6, "← 蓋／房間　　　牆 →", "center");
    ya = (bxy([esp_ant_bx[0], 0])[1] + bxy([esp_ant_bx[1], 0])[1]) / 2;
    dim_x([ax - X_in, ya - 3.4], [ax + X_ae, ya - 3.4], str(X_ae + X_in), 0);
    lbl([xl, ya + 2.6], 1.9, "陶瓷天線前方", "right");
    lbl([xl, ya - 0.2], 1.9, str(X_ae + X_in, " mm 空氣＋側牆開窗"), "right");
    lbl([xl, y_m1 - 2], 1.9, "MCU 艙：C3 橫放、排針朝背板", "right");
    lbl([xl, (y_pa0 + y_pb1)/2 + 1.4], 1.9, "雙層實心隔牆＋通風隔熱縫", "right");
    lbl([xl, (y_pa0 + y_pb1)/2 - 1.6], 1.9, "只留 4 線缺口", "right");
    lbl([xl, (y_in0 + y_pa0)/2 + 1.6], 1.9, "感測艙：AHT20+BMP280 直立", "right");
    lbl([xl, (y_in0 + y_pa0)/2 - 1.2], 1.9, "感測面朝下端格柵", "right");
    lbl([xl, y_pv], 1.9, "IR 艙列 1：洞洞板（導槽＋頂壓條）", "right");
    lbl([xl, led_y0 + 3], 1.9, "IR LED 座（往上傾 15°）", "right");
    lbl([ax + outer_w/2 + 1.2, rx_y + 3], 1.9, "VS1838B 座", "left");
    lbl([ax + outer_w/2 + 1.2, Y_uc + 4.5], 1.9, "USB-C", "left");
    lbl([xr, y_m0 + 13], 1.9, "C3 元件面朝蓋", "left");
    lbl([xr, y_m0 + 10.3], 1.9, str("PCB 離牆 ", Z_e, " mm（排針 9 mm）"), "left");
    lbl([xr, (y_pa0 + y_pb1)/2], 1.9, "4 線穿隔牆缺口", "left");
    lbl([xr, y_i0 + 1.0], 1.9, "5 線穿 MCU/IR 牆缺口", "left");
    lbl([xr, kh_y[0] + 1], 1.9, "鑰匙孔 ×2（腔藏在背板內）", "left");
} else if (part == "antenna_combo") {
    // 圖 05：過天線中心的 XZ 剖面（保留 +Y 半邊）＋MCU 艙俯視
    ya = (bxy([esp_ant_bx[0], 0])[1] + bxy([esp_ant_bx[1], 0])[1]) / 2;
    rotate([-90, 0, 0]) translate([0, -ya, 0]) intersection() {
        union() { c_body(); esp_ref(); wires_ref(); c_lid(0); }
        color(COL_CUT) translate([-60, ya, -1]) cube([120, (y_m1 + 0.3) - ya, 80]);
    }
    xa = bxy([0, (esp_ant_by[0] + esp_ant_by[1])/2])[0];
    lbl([0, Z_T + 10], 2.4, "天線端剖面（過陶瓷天線中心，從感測端往上看）", "center");
    dim_x([-X_in, Z_p + 2.6], [X_ae, Z_p + 2.6], str(X_ae + X_in), 0);
    lbl([-outer_w/2 - 2, Z_p + 4.6], 1.9, "天線前方空氣", "right");
    lbl([-outer_w/2 - 2, Z_p + 2.0], 1.9, str(X_ae + X_in, " mm（≥8）"), "right");
    lbl([-outer_w/2 - 2, (vz0 + vz1)/2 - 3.2], 1.9, "側牆開窗（格柵）", "right");
    lbl([xa - 1.0, Z_T + 5.2], 1.9, "陶瓷天線（上方只有 2.2 mm 滑蓋）", "left");
    ln([xa, Z_p + 1.3], [xa - 0.4, Z_T + 4.0]);
    dim_y([outer_w/2 + 1.8, 0], [outer_w/2 + 1.8, Z_e], str("PCB 離牆 ", Z_e, " mm"));
    lbl([outer_w/2 + 2, Z_u + 3.4], 1.9, "USB-C（貫穿讓位孔＋U 缺口）", "left");
    lbl([0, -3.2], 1.8, "背面貼牆；排針尾朝背板、尖端離內底 1.0", "center");
    za = Z_p + 0.35; yc = (y_m0 + y_m1)/2; py = -36;
    translate([0, py - yc, -40]) intersection() {
        union() { c_body(); esp_ref(); }
        color(COL_CUT) translate([-60, y_pb0 - 0.5, -1]) cube([120, y_i0 + 0.5 - y_pb0, za + 1]);
    }
    lbl([0, py + (y_i0 - yc) + 4], 2.4, "MCU 艙俯視（PCB 上方水平切）", "center");
    dim_x([-X_in, py], [X_ae, py], str(X_ae + X_in), 0);
    lbl([-outer_w/2 - 2, py + 1.4], 1.9, "天線前方空氣", "right");
    lbl([-outer_w/2 - 2, py + (y_m1 - 1.5 - yc)], 1.9, "角塊：擋面＋45° 勾口", "right");
    lbl([-outer_w/2 - 2, py + (y_m1 - 1.5 - yc) - 2.8], 1.6, "勾口開口容 PCB 0.8–1.6", "right");
    ln([-outer_w/2 - 1.4, py + (y_m1 - 1.5 - yc)], [X_ae - 1.2, py + (y_m1 - 1.5 - yc)]);
    lbl([outer_w/2 + 2, py + (Y_uc - yc)], 1.9, "USB-C（線往右）", "left");
    lbl([outer_w/2 + 2, py + (y_m0 - yc) - 1.0], 1.9, "隔牆 B（下為感測艙）", "left");
    lbl([outer_w/2 + 2, py + (y_m1 - yc) + 1.6], 1.9, "MCU/IR 牆（上為 IR 艙）", "left");
} else if (part == "ir_view") {
    // 圖 11：左＝過 LED 軸的 YZ 剖面（看傾角與發射錐）；右＝正面（蓋面）俯視：IR 窗、接收窗、相距
    translate([-30, 0, 0]) rotate([0, -90, 0]) intersection() {
        union() { c_body(); all_parts(); c_lid(0); }
        color(COL_CUT) translate([led_x - 80, -20, -1]) cube([80, L + 60, 80]);
    }
    // 右圖：正面俯視
    translate([32, 0, 0]) { c_body(); all_parts(false); c_lid(0); }
    // 標註（左圖：畫面 X＝-30 - Z，畫面 Y＝Y）
    lbl([zx(Z_T) - 1, L + 13], 2.4, "IR LED 剖面（過 LED 軸）", "center");
    Tn = P_led + led5_len*led_a;          // 標稱 LED 頂點
    for (th = [led_tilt - led_half_angle, led_tilt, led_tilt + led_half_angle])
        color(th == led_tilt ? COL_TXT : COL_CONE) hull() for (q = [[zx(Tn[2]), Tn[1]], [zx(Tn[2] + 18*cos(th)), Tn[1] + 18*sin(th)]])
            translate([q[0], q[1], 60]) cylinder(d = th == led_tilt ? 0.3 : 0.45, h = 0.1, $fn = 8);
    lbl([zx(Tn[2] + 18*led_a[2]) - 1.0, Tn[1] + 18*led_a[1] + 1.2], 1.9, str("LED 軸：往上傾 ", led_tilt, "°"), "right");
    lbl([zx(Tn[2] + 18*cos(led_tilt + led_half_angle)) - 0.6, Tn[1] + 18*sin(led_tilt + led_half_angle) + 1.6], 1.6, str("+", led_tilt + led_half_angle, "°"), "center");
    lbl([zx(Tn[2] + 18*cos(led_tilt - led_half_angle)) - 2.6, Tn[1] + 18*sin(led_tilt - led_half_angle)], 1.6, str(led_tilt - led_half_angle, "°"), "center");
    lbl([zx(Z_T) - 2, Tn[1] - 8], 1.9, str("發射錐 ±", led_half_angle, "°（窗口按 ±", led_tc, "° 開）"), "right");
    lbl([zx(Z_T) - 2, Tn[1] - 11], 1.9, "喇叭形窗、蓋與殼都不擋", "right");
    lbl([zx(0) + 1, L + 8], 1.7, "背面（牆）", "left");
    lbl([zx(Z_T) - 6, L + 8], 1.7, "蓋面（房間）", "right");
    lbl([zx(0) + 3, led_y0 - 1], 1.7, "← LED 座：凸緣槽＋C 形卡扣", "left");
    lbl([zx(0) + 6, led_y0 - 3.6], 1.7, "（容 Ø4.7–5.3；3 mm 用轉接套）", "left");
    lbl([zx(0) + 3, y_pv], 1.7, "← 洞洞板（導槽＋頂壓條）", "left");
    // 右圖
    lbl([32, L + 13], 2.4, "正面（蓋面）", "center");
    dim_x([32 + led_x, L + 3], [32 + rx_x, L + 3], str("IR 發射 ↔ 接收 ", round((rx_x - led_x)*10)/10, " mm"), 2.2);
    lbl([32 + led_x, led_y0 - 9], 1.8, "IR 發射窗", "center");
    lbl([32 + rx_x, rx_y - 8], 1.8, "VS1838B 窗", "center");
    lbl([32 + rx_x, rx_y - 10.6], 1.5, "（學習遙控碼用）", "center");
} else if (part == "wall_view") {
    rotate([90, 0, 0]) { c_body(); all_parts(); c_lid(0); usb_cable_ref(); cone_vis(24); }
    color("#b9b4aa") translate([-75, 0.0, -30]) cube([150, 1, 150]);
} else if (part == "coupon_view") {
    color(COL_BODY) plate_coupon();
    color("#d6d6d6") translate([0, 0, -1.2]) cube([bed_x, bed_y - bed_back_keep, 1]);
    bt([cp_o[0][0], cp_o[0][1] + 15], "C1 滑軌段", 3.6);
    bt([cp_o[0][0], cp_o[0][1] - 14], "燕尾＋扣點＋感測導槽", 2.8);
    bt([cp_o[1][0], cp_o[1][1] + 15], "C2 滑蓋前段", 3.6);
    bt([cp_o[1][0], cp_o[1][1] - 14], "彈片＋切縫＋鼻片", 2.8);
    bt([cp_o[2][0], cp_o[2][1] - 14], "C3 IR LED 座", 3.6);
    bt([cp_o[4][0] + 2, cp_o[4][1] - 15], "C4 USB-C 段", 3.6);
    bt([cp_o[5][0], cp_o[5][1] - 8], "3 mm 轉接套", 3.0);
    bt([110, 135], "COUPON（選印，黑 PLA，估約 29 分）", 5);
} else if (part == "dims") {
    echo(str("DIMS {\"esp_hdr\":\"", esp_hdr, "\",\"sensor\":\"", sensor_variant, "\",\"sens_conn\":\"", sens_conn, "\",\"Z_f\":", Z_f, ",\"floor_s\":", floor_s, ",\"Z_e\":", Z_e, ",\"Z_p\":", Z_p,
             ",\"Z_u\":", Z_u, ",\"Z_L\":", Z_L, ",\"Z_T\":", Z_T, ",\"Z_s\":", Z_s, ",\"pcb_t\":", esp_pcb_t, ",\"pcb_t_max\":", esp_pcb_t_max, ",\"hook_open\":", hook_open,
             ",\"notch_drop\":", notch_drop, ",\"bump_h\":", bump_h, ",\"bump_base\":", bump_base, ",\"bump_top\":", bump_top,
             ",\"bump_len\":", bump_len, ",\"bump_y\":", bump_y, ",\"lid_t\":", lid_t, ",\"lid_foot\":", lid_foot, ",\"fdm_gap\":", fdm_gap,
             ",\"X_in\":", X_in, ",\"wall\":", wall, ",\"wall_bot\":", wall_bot, ",\"wall_top\":", wall_top, ",\"wall_mi\":", wall_mi, ",\"outer_w\":", outer_w, ",\"L\":", L,
             ",\"y_in0\":", y_in0, ",\"y_sf\":", y_sf, ",\"y_sbm\":", y_sbm, ",\"y_pa0\":", y_pa0, ",\"y_pa1\":", y_pa1, ",\"y_pb0\":", y_pb0,
             ",\"y_m0\":", y_m0, ",\"y_m1\":", y_m1, ",\"y_i0\":", y_i0, ",\"y_i1\":", y_i1, ",\"y_pv\":", y_pv, ",\"y_r1e\":", y_r1e,
             ",\"y_pcb0\":", y_pcb0, ",\"y_pcb1\":", y_pcb1, ",\"X_ue\":", X_ue, ",\"X_ae\":", X_ae,
             ",\"Y_uc\":", Y_uc, ",\"X_n\":", X_n, ",\"X_nI\":", X_nI, ",\"y_lead\":", y_lead, ",\"slit_end_y\":", slit_end_y, ",\"slit_w\":", slit_w,
             ",\"tongue_w\":", tongue_w, ",\"lid_hw\":", lid_hw, ",\"lid_y_tip\":", lid_y_tip, ",\"vz0\":", vz0, ",\"vz0s\":", vz0s, ",\"vz1\":", vz1, ",\"part_t\":", part_t,
             ",\"part_gap\":", part_gap, ",\"kh_x\":", kh_x, ",\"kh_y\":[", kh_y[0], ",", kh_y[1], "],\"kh_len\":", kh_len,
             ",\"kh_lip\":", kh_lip, ",\"kh_head\":", kh_head, ",\"kh_d\":", kh_d, ",\"kh_w\":", kh_w, ",\"floor_t\":", floor_t,
             ",\"ant_x0\":", bxy([0, esp_ant_by[1]])[0], ",\"ant_y\":[", bxy([esp_ant_bx[1], 0])[1], ",", bxy([esp_ant_bx[0], 0])[1], "]",
             ",\"lid_win_x0\":", lid_win_x0, ",\"lid_win_x1\":", lid_win_x1, ",\"lid_rows_y\":", str(lid_rows_y), ",\"label_fits\":", label_fits,
             ",\"ant_slot_x\":", str(ant_slot_x), ",\"label_y\":", label_y, ",\"label_depth\":", label_depth,
             ",\"sens_w\":", sens_w, ",\"sens_h\":", sens_h, ",\"sens_w_max\":", sens_w_max, ",\"sens_w_min\":", sens_w_min, ",\"sens_h_max\":", sens_h_max, ",\"sens_t_max\":", sens_t_max,
             ",\"s_slot_x\":", s_slot_x, ",\"s_lip_x\":", s_lip_x, ",\"s_slot_t\":", s_slot_t,
             ",\"pcb_x\":", pcb_x, ",\"p_slot_x\":", p_slot_x, ",\"p_lip_x\":", p_lip_x, ",\"pcb_w_max\":", pcb_w_max, ",\"pcb_h_max\":", pcb_h_max,
             ",\"usb_cut_w\":", usb_cut[0], ",\"usb_cut_h\":", usb_cut[1], ",\"esp_usb_over\":", esp_usb_over, ",\"esp_usb_over_max\":", esp_usb_over_max,
             ",\"led_tilt\":", led_tilt, ",\"led_tc\":", led_tc, ",\"P_led\":", v3(P_led), ",\"T_min\":", v3(T_min), ",\"led_x\":", led_x, ",\"led_y0\":", led_y0,
             ",\"led_win_yhi\":", led_win_yhi, ",\"led_win_ylo\":", led_win_ylo, ",\"led_win_rx\":", led_win_rx,
             ",\"rx_x\":", rx_x, ",\"rx_y\":", rx_y, ",\"rx_z0\":", rx_z0, ",\"rx_win_d\":", rx_win_d, ",\"rx_win_ch\":", rx_win_ch, ",\"ir_sep\":", rx_x - led_x,
             ",\"press_h\":", press_h, ",\"press_t\":", press_t, ",\"lid_top_hw\":", lid_top_hw,
             ",\"blk_body_o\":", v3(blk_body_o), ",\"wht_lid_o\":", v3(wht_lid_o), ",\"blk_items\":", str([for (i = blk_items) i[1]]), ",\"wht_items\":", str([for (i = wht_items) i[1]]),
             ",\"blk_names\":", str([for (i = blk_items) i[0]]), ",\"wht_names\":", str([for (i = wht_items) i[0]]),
             ",\"sl_top\":", sl_top, ",\"cp_zc\":", cp_zc, ",\"cp_c1_y1\":", cp_c1_y1, ",\"cp_c3_zc\":", cp_c3_zc, ",\"cp_c3_y0\":", cp_c3_y0, ",\"cp_c4_z0\":", cp_c4_z0,
             ",\"cp_o\":", str(cp_o), "}"));
    cube(1);
} else if (part == "check_parts_body") {
    intersection() { body(); parts_all(); }
} else if (part == "check_parts_lid") {
    intersection() { lid(); parts_all(); }
} else if (part == "check_lid_body") {
    intersection() { body(); lid(); }
} else if (part == "check_slide") {
    intersection() { body(false); for (d = [0.5 : 1.0 : L + 4]) translate([0, d, 0]) lid(); }
}
