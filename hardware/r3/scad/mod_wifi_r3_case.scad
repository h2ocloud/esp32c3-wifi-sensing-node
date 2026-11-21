// =====================================================================
//  MOD-WIFI-R3-20261121  Wi-Fi 偵測節點（麵包板版）＋HITACHI 日立冷氣 IR 遙控（RF11T1）外殼
//  ESP32-C3 SuperMini（排針朝下，直接插麵包板）＋DHT11 三腳模組（杜邦線）＋IR LED 5 mm＋VS1838B＋S8050＋電阻
//  ＋白色迷你麵包板 SYB-170（背膠黏殼底）。兩件：殼身＝黑、滑蓋＝白（R2 配色）。以 R2 scad 為底改（_R2_backup/scad/）。
//  單位 mm。座標（組裝座標＝Onshape 匯入座標）：
//    X＝寬（中心 0；+X＝USB-C 那側＝壁掛正面看右邊）
//    Y＝長（Y=0＝下端＝DHT 艙端；Y=L＝上端，滑蓋由此滑出）
//    Z＝深（Z=0＝背面＝貼牆面＝貼床面；+Z＝滑蓋／朝房間）
//  佈局（Y 由小到大）：下端牆（扣點、格柵、立放腳位）→ DHT 通風艙（模組平放在支撐肋上、DHT11 朝蓋、背膠固定）
//        → 雙層實心隔牆＋通風隔熱縫（只開 DHT 杜邦母頭孔）→ 麵包板艙（麵包板長軸沿 X，推到右下角黏底）→ 上端牆（滑蓋出口）
//  麵包板上：C3 插 1–8 排（USB 朝 +X 側牆孔、天線朝 -X）；9–10 排淨空（天線端）；IR 電路在 11–17 排；
//        DHT 接頭＝J2/J3/J4（就是 C3 的 GND／3V3／GPIO4 排）插 1×3 90° 排針，母頭平躺穿過雙層隔牆孔進 DHT 艙。
//  IR LED 直立插 J16（陽）／J15（陰），預設直驅（GPIO3→220 Ω H16–H17→LED→F15–F13 跳線→GND），補 S8050 後改電晶體版，從蓋上的喇叭形大窗朝房間發射（可往上彎 0–15°）；
//  VS1838B 插 C12–C14，腳往後折 90° 平躺、透鏡朝蓋上的接收窗（與發射窗相距 ≥25）。
//  沿用 R1/R2 已驗證：45° 燕尾滑蓋、fdm_gap 0.30、lid_foot 0.3、彈片＋1.0 切縫＋R0.5、平頂梯形扣點 0.56/1.4/0.5、
//        鑰匙孔（腔頂 1.12）、牆厚 0.8 倍數、肋 ≥1.0、免支撐、雙層隔牆＋隔熱縫。
//  R3 容差原則：麵包板長寬 ±1、含背膠高 8.3–10.0、DHT 模組 PCB ±1.5/±1.0、LED／接收頭位置 ±2 都放得下（REPORT_R3.md）。
//  實測版本：OpenSCAD 2026.10.29 snapshot（--backend Manifold）。
// =====================================================================

include <mod_wifi_r3_ref.scad>

/* [輸出選擇] */
part = "assembly";
// 麵包板端 DHT 接頭：angle＝1×3 90° 排針（母頭平躺；預設＝薄殼）；straight＝直針＋直立母頭（殼加深＝tall 版）
bb_dht_conn = "angle";        // [angle, straight]
// 麵包板 IR 驅動（只影響參考件與渲染；殼不變）：direct＝直驅 GPIO3→220 Ω→LED（預設，現有料）；npn＝補 S8050 後 5V→3×220 Ω→LED→C
ir_drive = "direct";          // [direct, npn]
label = ["WIFI", "NODE"];
lid_open_dy = 52;

/* [FDM（沿用已驗證值）] */
fdm_gap  = 0.30;
lid_foot = 0.3;

/* [麵包板 SYB-170（research/sources_r3_parts.md）] */
bb_l = 47.2; bb_w = 35.2;      // 本體長×寬（不含燕尾）｜RS PRO ZY170 尺寸圖；Pololu／SparkFun 47×35
bb_tol = 1.0;                  // 長寬 ±1（brief）→ 46.2–48.2 × 34.2–36.2
bb_ht = 8.8; bb_ht_min = 8.3; bb_ht_max = 10.0;   // 含背膠總高（RS 本體 8.0＋背膠≈0.7；賣家 8.5–10）
bb_gap = 1.0;                  // 最大板四周到定位角擋
bb_tab = 2.0;                  // 燕尾凸榫（凸 1.2–1.8、寬 4.6、只在下半 4.2）讓位：四面牆離定位框 2.0
bb_extra_bot = 2.0;            // 下側（DHT 隔牆側）多留：LED 發射錐不被隔牆頂擋
bb_extra_top = 0.5;            // 上側多留：接收窗到蓋尾的肋
bb_stop_h = 4.0;               // 角擋高（低於燕尾頂 4.2？不需要：角擋在四角，凸榫在邊中央）
bb_stop_leg = 4.5;             // 角擋兩臂長（自角起；凸榫在邊中央 ±2.3，不碰）
bb_stop_leg_ref = 8.0;         // 右下（參考角，麵包板推到這裡）臂長
bb_mhole = 37.7;               // 溝內兩安裝孔距（不使用，只畫）
bb_rows = 17;
bb_pos_tol = 1.0;              // 推到右下角後的位置誤差（尺寸 ±0.5＋沒貼齊 0.5）
bb_tab_vis = 1.5; bb_tape_vis = 0.7;

/* [ESP32-C3 SuperMini（板座標 [bx, by]：bx 自 GPIO5 排板邊、by 自 USB 端板邊；R2 已查證）] */
esp_l = 22.52; esp_w = 18.00; esp_row = 15.24;   // 官方 Nologo 尺寸圖
esp_pin1  = 1.52;     // 估計（原廠 3D 圖量）
esp_pcb_t = 1.0;      // 估計（到貨量）
esp_usb_w = 8.94; esp_usb_h = 3.26; esp_usb_len = 7.35;
esp_usb_over = 1.9;   // USB-C 凸出板邊（原廠 3D 圖 1.9；到貨量）
esp_usb_over_max = 2.5;
esp_usb_bx = 9.0;
esp_boot_xy = [6.2, 8.7]; esp_rst_xy = [11.7, 8.7]; esp_btn_h = 2.0;
esp_led8_xy = [13.6, 11.1]; esp_led8_win = [14.2, 12.6]; esp_ledp_xy = [3.0, 5.2];
esp_ant_bx = [5.95, 12.05]; esp_ant_by = [20.4, 22.4];
esp_row1 = 1; esp_colL = 2; esp_colR = 8;          // C3 跨溝插 C1–C8（GPIO5 排）／G1–G8（5V 排）（BRIEF_R3 追加 4：約 c、g）
esp_alt_dy = 2.54;                                  // 也容許插 B/F（整顆往 +Y 一格）：USB 孔、BOOT/RST 孔、天線槽都涵蓋兩種
hdr_plastic = 2.5; hdr_top_h = 2.0;                 // 排針塑膠座 2.5、板上短針 2.0（BOOMELE 規格）

/* [DHT11 三腳模組（通用 DHT11 三腳模組類；查無原廠圖，以同型通用模組＋照片推估）] */
dht_l = 30.5; dht_w = 13.6; dht_t = 1.6;            // PCB（28–32 × 12–14）
dht_l_tol = 1.5; dht_w_tol = 1.0;
dht_body = [16.0, 12.5, 6.0];                       // DHT11 本體（ASAIR V1.3：16×12.5×6；舊版 15.5×12×5.5）
dht_rib_h = 4.5;                                    // 支撐肋高（背面彎針塑膠座 2.5 也離底；空氣從板下流過）
dht_hdr_plastic = 2.5; dht_hdr_pins = 5.8;          // 彎針：塑膠座 2.5、針伸出板邊 5.8
dht_end_gap = 1.0;                                  // 模組 -X 端到左牆
dht_side_gap = 1.0;                                 // 最寬模組到艙壁
dht_bend = 4.0;                                     // 母頭尾端彎線
dupont_len = 14.3; dupont_w = 2.6;                  // 杜邦母頭 2.54×2.54×14.0±0.25（Pololu #1900）
dht_col = 11; dht_rows = [2, 3, 4];                 // 麵包板端：J2 GND、J3 3V3、J4 GPIO4

/* [IR LED 5 mm（直立，J16 陽／J15 陰）] */
led5_d = 5.0; led5_fl_d = 5.8; led5_fl_h = 1.0;     // T-1¾（到貨量）
led5_len = 8.6; led5_len_min = 8.2; led5_len_max = 9.0;   // 凸緣底→頂
led_rows = [15, 16]; led_col = 11;          // J15 陰極、J16 陽極
led_half_angle = 25; led_cone_margin = 2;           // 窗口按 ±27° 開
led_tilt_max = 15;                                  // 可往 +Y（壁掛時往上）彎 0–15°
led_fl_gap_max = 1.0;                               // 凸緣底離麵包板 0–1（腳剪短）
led_lean = 1.0;                                     // 腳歪 ±1
/* [VS1838B（C12 VCC／C13 GND／C14 OUT；平躺透鏡朝蓋）] */
rx_body = [6.5, 7.4, 5.2];                          // 寬×高（出腳方向）×深（含透鏡）｜R2 研究
rx_rows = [12, 13, 14]; rx_col = 2;
rx_dome_off = 6.5;                                  // 透鏡中心離插孔（出腳面 1.0＋本體上段）
rx_win_d = 12.0; rx_win_ch = 1.5;                   // 接收窗直徑＋頂面 45° 倒角
q1_col = 7;                                         // S8050（電晶體版）插 F13 E／F14 B／F15 C
/* [麵包板零件高度] */
parts_hmax = 10.0;                                  // 麵包板頂面以上任何零件（LED 頂、TO-92、直立電阻、跳線）都 ≤ 10.0
lid_clear  = 0.6;

/* [殼體（牆厚為 0.8 的倍數）] */
wall = 3.2; wall_bot = 4.0; wall_top = 2.4;
part_t = 1.6; part_gap = 2.0;
lid_t = 2.2; groove_d = 1.5; groove_v = 0.7;
corner_r = 3.0; edge_ch = 0.6;

/* [USB-C 插頭讓位孔（貫穿 +X 牆）] */
plug_body = [12.35, 6.5];   // USB-IF 規範上限（檢查用標準插頭）
plug_env  = [13.0, 7.2];    // 開口按 13.0×7.2（Amphenol 12.35×6.6 已超規；research）
usb_clr = 0.4; usb_cut_r = 1.5; usb_rim = 0.8;

/* [格柵] */
slot_w = 2.0; rib_w = 1.6; rib_side_w = 2.4; rib_end_w = 1.2;

/* [滑蓋細節（沿用 R2）] */
tongue_w = 4.8; tongue_len = 7.5; tongue_t = 1.6;
slit_w = 1.0; slit_round = true;
bump_h = 0.56; bump_base = 1.4; bump_top = 0.5; bump_len = 2.4;
btn_hole_d = 4.0;           // BOOT/RST 牙籤孔（R2 3.2 → 4.0：麵包板位置 ±1）
led_hole_d = 3.0;           // 藍色 GPIO8 LED 窗
led8_window = false;        // 預設關：藍 LED 離 RST 孔 2.4，從 RST 長圓孔看得到；開了會與 RST 孔只剩 0.4 肋（兩種插法都涵蓋時）
label_size = 4.0; label_lead = 5.6; label_depth = 0.56;

/* [壁掛鑰匙孔（藏在背板內；兩孔上下相距 30＝R2 同）] */
kh_x = 0;
kh_d = 7.6; kh_w = 3.6; kh_len = 6.0;
kh_lip = 1.4; kh_head = 2.52; kh_ceil = 1.12;
floor_t = kh_lip + kh_head + kh_ceil;   // 麵包板艙背板 5.04
floor_s = 2.4;                          // DHT 艙薄底（有格柵）

/* [立放腳位] */
feet_d = 8.4; feet_depth = 0.6; feet_x = 21.0;

/* [盤面（單件置中；熱床物理座標）] */
bed_x = 220; bed_y = 220; bed_back_keep = 20;
plate_c = [110, 110];

$fn = 48;
eps = 0.01;
big = 400;

// ------------------------- 推導尺寸（勿手改） -------------------------
bb_lmax = bb_l + bb_tol; bb_wmax = bb_w + bb_tol; bb_lmin = bb_l - bb_tol; bb_wmin = bb_w - bb_tol;
bb_loc  = [bb_lmax + 2*bb_gap, bb_wmax + 2*bb_gap];          // 定位框 50.2 × 38.2
X_in    = bb_loc[0]/2 + bb_tab;
outer_w = 2*(X_in + wall);
dht_lmax = dht_l + dht_l_tol; dht_wmax = dht_w + dht_w_tol;

// Z
Z_f = floor_t;
bb_top_nom = Z_f + bb_ht; bb_top_max = Z_f + bb_ht_max; bb_top_min = Z_f + bb_ht_min;
Z_L = bb_dht_conn == "angle" ? bb_top_max + parts_hmax + lid_clear
                             : bb_top_max + max(hdr_plastic + dupont_len, 14.0) + 3.0 + lid_clear;   // tall：直針＋直立母頭（2.5＋14.3）或公母杜邦公頭直插（14.0），＋彎線 3
raise = Z_L - (bb_top_max + parts_hmax + lid_clear);   // tall 版：LED、接收頭腳留長整顆墊高這麼多（angle 版 0）
Z_T = Z_L + lid_t;

// Y：DHT 艙 → 雙層隔牆 → 麵包板艙
y_in0 = wall_bot;
y_pa0 = y_in0 + dht_wmax + 2*dht_side_gap;
y_pa1 = y_pa0 + part_t;
y_pb0 = y_pa1 + part_gap;
y_pb1 = y_pb0 + part_t;
y_b0  = y_pb1;
y_loc0 = y_b0 + bb_tab + bb_extra_bot;                       // 定位框下緣
y_loc1 = y_loc0 + bb_loc[1];
y_b1  = y_loc1 + bb_tab + bb_extra_top;
L     = y_b1 + wall_top;
// 麵包板（標稱板推到右下角＝+X、-Y 角擋）
bb_cx = bb_loc[0]/2 - bb_l/2;
bb_cy = y_loc0 + bb_w/2;
function row_x(r) = bb_cx + (9 - r)*2.54;
function col_y(p) = bb_cy + (5.5 - p)*2.54;

// C3
X_ue = row_x(esp_row1) + esp_pin1;
X_ae = X_ue - esp_l;
Y_top = col_y(esp_colL) + (esp_w - esp_row)/2;
function bxy(p) = [X_ue - p[1], Y_top - p[0]];
Y_uc = bxy([esp_usb_bx, 0])[1];
Z_e = bb_top_nom + hdr_plastic; Z_p = Z_e + esp_pcb_t; Z_u = Z_p + esp_usb_h/2;
// USB 讓位孔：插頭 13.0×7.2 ＋ 0.4 ＋ 位置（Y ±bb_pos_tol；Z＝麵包板高 8.3–10.0、PCB 0.8–1.6）
zu_min = bb_top_min + hdr_plastic + 0.8 + esp_usb_h/2;
zu_max = bb_top_max + hdr_plastic + 1.6 + esp_usb_h/2;
usb_cut_y = [Y_uc - plug_env[0]/2 - usb_clr - bb_pos_tol, Y_uc + esp_alt_dy + plug_env[0]/2 + usb_clr + bb_pos_tol];
usb_cut_z = [zu_min - plug_env[1]/2 - usb_clr, zu_max + plug_env[1]/2 + usb_clr];

// DHT 母頭穿隔牆孔（J2–J4 → X；麵包板頂 min/max → Z）
dslot_x = [row_x(dht_rows[2]) - dupont_w/2 - bb_pos_tol - 0.3, row_x(dht_rows[0]) + dupont_w/2 + bb_pos_tol + 0.3];
dslot_z = [bb_top_min - 0.4, bb_dht_conn == "angle" ? bb_top_max + 1.27 + dupont_w/2 + 0.4 : Z_T];
// DHT 模組
dht_x0 = -X_in + dht_end_gap;
dht_cy = (y_in0 + y_pa0)/2;
dht_z0 = floor_s + dht_rib_h;

// IR
led_x = (row_x(led_rows[0]) + row_x(led_rows[1]))/2;
led_y = col_y(led_col);
led_tip_span = (bb_top_max + led_fl_gap_max + led5_len_max) - (bb_top_min + led5_len_min);
led_tip_hi = Z_L - lid_clear;                      // 最高 LED 頂（angle 版＝bb_top_max＋1＋9.0）
led_tip_lo = led_tip_hi - led_tip_span;            // 最低 LED 頂（tall 版要把 LED 墊高到這個範圍，見 REPORT）
led_pos_tol = bb_pos_tol + led_lean;
led_tc = led_half_angle + led_cone_margin;
rx_x = row_x(rx_rows[1]);
rx_y = col_y(rx_col) + rx_dome_off;
ir_sep = norm([rx_x - led_x, rx_y - led_y]);

// 滑蓋
y_lead    = y_in0 - groove_d + fdm_gap;
lid_y_tip = 0.4;
y_trail   = L;
lid_hw    = X_in + groove_d - fdm_gap;
lid_top_hw = lid_hw - (lid_t - groove_v);
slit_end_y = y_lead + tongue_len;
bump_y    = wall_bot/2 + 0.2;
notch_drop = 0.1;

// 鑰匙孔（麵包板艙背板內；上下相距 30）
kh_y = [y_pa0 + 6.4, y_pa0 + 6.4 + 30];

assert(lid_foot < groove_v, "lid_foot 必須 < groove_v");
assert(floor_t >= kh_lip + kh_head + kh_ceil - 1e-6, "背板不夠厚");
assert(rib_w >= 1.0 && rib_side_w >= 1.0 && rib_end_w >= 1.0, "肋需 ≥ 1.0");
assert(usb_cut_z[1] <= Z_L - usb_rim + 1e-6, "USB 讓位孔碰到燕尾槽");
assert(X_ue + 0.5 + esp_usb_over_max + 0.3 <= X_in + 1e-6, "USB-C 母座（最大凸出）會頂到 +X 牆");
assert(dht_x0 + dht_lmax + dupont_len + dht_bend <= X_in + 1e-6, "DHT 模組＋母頭＋彎線 超出 DHT 艙");
assert(ir_sep >= 25 - 1e-6, "IR 發射與接收相距需 ≥25");
assert(kh_y[0] - kh_d/2 >= y_pa0 + 1.2 - 1e-6 && kh_y[1] + kh_len + kh_d/2 <= L - 1.6, "鑰匙孔超出厚背板");
assert(bb_top_max + parts_hmax + lid_clear <= Z_L + 1e-6, "滑蓋太低");
assert(row_x(17) - 1.27 >= -bb_loc[0]/2 + bb_gap - 1e-6, "麵包板孔位超出板");

// =====================================================================
//  滑軌截面（R2 已驗證；u＝自內腔面往牆內，v＝Z）
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
        translate([-X_in, y_in0, floor_s]) cube([2*X_in, y_pa0 - y_in0, Z_T]);   // DHT 艙（薄底）
        translate([-X_in, y_pa0, Z_f]) cube([2*X_in, y_b1 - y_pa0, Z_T]);       // 隔牆區＋麵包板艙
    }
}
module partitions() {
    for (y0 = [y_pa0, y_pb0]) translate([-X_in - eps, y0, Z_f - eps]) cube([2*X_in + 2*eps, part_t, (Z_L - 0.4) - Z_f + eps]);
}
// 麵包板定位角擋（四角 L 形；右下為參考角，臂較長）
module bb_stops() {
    for (sx = [-1, 1], sy = [-1, 1]) {
        leg = (sx > 0 && sy < 0) ? bb_stop_leg_ref : bb_stop_leg;
        xc = sx*bb_loc[0]/2; yc = sy < 0 ? y_loc0 : y_loc1;
        yw = sy < 0 ? y_b0 - eps : y_b1 + eps;           // 牆面
        xw = sx*(X_in + eps);
        // 沿 X 的臂（填滿定位框與 ±Y 牆之間的帶）
        translate([min(xc - sx*leg, xw), min(yc, yw), Z_f - eps]) cube([abs(xw - (xc - sx*leg)), abs(yw - yc), bb_stop_h + eps]);
        // 沿 Y 的臂（填滿定位框與 ±X 牆之間的帶）
        translate([min(xc, xw), min(yc - sy*leg, yw), Z_f - eps]) cube([abs(xw - xc), abs(yw - (yc - sy*leg)), bb_stop_h + eps]);
    }
}
// DHT 艙支撐肋（沿 Y，放在底板格柵肋上；肋頂貼雙面泡棉膠）
function slot_centers(a, b, pitch) = let(n = floor((b - a - slot_w) / pitch + 1e-6) + 1, used = (n - 1)*pitch + slot_w, s0 = a + (b - a - used)/2 + slot_w/2)
    [for (i = [0 : n - 1]) s0 + i*pitch];
floor_slots_x = slot_centers(-(X_in - 1.4), X_in - 1.4, slot_w + rib_w);
function nearest_mid(t) = let(m = [for (i = [0 : len(floor_slots_x) - 2]) (floor_slots_x[i] + floor_slots_x[i + 1])/2],
                              d = [for (v = m) abs(v - t)], k = search(min(d), d)[0]) m[k];
dht_rib_x = [nearest_mid(dht_x0 + 4.0), nearest_mid(dht_x0 + dht_body[0] - 2.0), nearest_mid(dht_x0 + dht_l - 8.0)];
module dht_ribs() {
    for (x = dht_rib_x) translate([x - rib_w/2, y_in0 + 2.0, floor_s - eps]) cube([rib_w, (y_pa0 - 2.0) - (y_in0 + 2.0), dht_rib_h + eps]);
}
module dht_slot() translate([dslot_x[0], y_pa0 - 1, dslot_z[0]]) cube([dslot_x[1] - dslot_x[0], y_pb1 - y_pa0 + 2, dslot_z[1] - dslot_z[0]]);
module usb_cut() {
    translate([X_in - 1, (usb_cut_y[0] + usb_cut_y[1])/2, (usb_cut_z[0] + usb_cut_z[1])/2]) rotate([0, 90, 0]) linear_extrude(wall + 2)
        offset(r = usb_cut_r) offset(delta = -usb_cut_r) square([usb_cut_z[1] - usb_cut_z[0], usb_cut_y[1] - usb_cut_y[0]], center = true);
}

// 通風格柵
vz0s = floor_s + 1.0;            // DHT 艙牆上格柵下緣
vz0  = Z_f + 1.0;
vz1  = Z_L - 2.4;                // 牆上格柵上緣
vzb  = bb_top_max + 0.6;         // 麵包板艙牆上格柵下緣（麵包板頂以上）
end_slots_x  = slot_centers(-(feet_x - feet_d/2 - 1.2), feet_x - feet_d/2 - 1.2, slot_w + rib_end_w);
dht_side_y   = slot_centers(y_in0 + 1.5, y_pa0 - 1.5, slot_w + rib_side_w);
top_slots_x  = slot_centers(-(X_in - 3.0), X_in - 3.0, slot_w + rib_w);
left_slots_y = slot_centers(y_b0 + 2.0, y_b1 - 2.0, slot_w + rib_side_w);
right_slots_y = concat(slot_centers(y_b0 + 2.0, usb_cut_y[0] - 2.0, slot_w + rib_side_w), slot_centers(usb_cut_y[1] + 2.0, y_b1 - 2.0, slot_w + rib_side_w));
dht_floor_x  = [for (x = floor_slots_x) if (min([for (r = dht_rib_x) abs(x - r)]) > 1.0) x];
module vents() {
    for (x = end_slots_x) translate([x - slot_w/2, -1, vz0s]) cube([slot_w, y_in0 + 2, vz1 - vz0s]);
    for (s = [-1, 1]) {
        xw = s > 0 ? X_in - 1 : -X_in - wall - 1;
        for (y = dht_side_y) translate([xw, y - slot_w/2, vz0s]) cube([wall + 2, slot_w, vz1 - vz0s]);
        translate([xw, y_pa1, vz0]) cube([wall + 2, part_gap, vz1 - vz0]);      // 隔熱縫兩側通氣
        for (y = (s > 0 ? right_slots_y : left_slots_y)) translate([xw, y - slot_w/2, vzb]) cube([wall + 2, slot_w, vz1 - vzb]);
    }
    for (x = top_slots_x) translate([x - slot_w/2, y_b1 - 1, vzb]) cube([slot_w, wall_top + 2, (Z_L - 1.6) - vzb]);
    for (x = dht_floor_x) translate([x - slot_w/2, y_in0 + 1.2, -1]) cube([slot_w, (y_pa0 - 1.2) - (y_in0 + 1.2), floor_s + 2]);
}

// 扣點（R2）
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
                bb_stops();
                dht_ribs();
            }
            side_grooves();
            end_groove();
            translate([-X_in, y_b1 - eps, Z_L - 0.2]) cube([2*X_in, wall_top + 1, Z_T]);   // 上端牆降到蓋底以下：滑蓋出口
            usb_cut();
            dht_slot();
            vents();
            detent_notch();
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
            end_extrude(2*(X_in + groove_d)) lid_edge_2d(false);
            translate([-tongue_w/2 - slit_w/2, lid_y_tip, Z_L - 1]) cube([tongue_w + slit_w, y_lead + 2.0 - lid_y_tip, 1 + tongue_t]);
        }
        translate([0, 0, Z_L - 1]) linear_extrude(lid_t + 2) rrect(-(lid_hw + 0.3), lid_hw + 0.3, y_lead - 6, y_trail, 2.3);   // 外擴 0.3：避免與燕尾外緣共面（R3 實測 4 條非流形邊）
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
gap_slot_x = [-1.0, lid_win_x1 - 2];          // 隔熱縫上方蓋槽：只開右半（左半是 IR 發射窗）
// 天線上方縱槽（沿 Y）：天線在 C3 -X 端
ant_y = [bxy([esp_ant_bx[1], 0])[1], bxy([esp_ant_bx[0], 0])[1]];
ant_x = [bxy([0, esp_ant_by[1]])[0], bxy([0, esp_ant_by[0]])[0]];
ant_slots = [[ant_x[1] + 0.2, ant_y[0] - 2.0, ant_y[1] + esp_alt_dy + 2.0], [ant_x[1] - 3.4, ant_y[0] - 2.0, min(ant_y[1] + esp_alt_dy + 0.2, rx_y - rx_win_d/2 - rx_win_ch - 1.5)]];   // [x, y0, y1]（含 B/F 插法）
label_c = [13.0, (y_pb1 + bxy(esp_rst_xy)[1] - btn_hole_d/2)/2 - 1.0];
lid_tail_grooves_y = [L - 2.2, L - 3.8, L - 5.4];
tail_groove_x = [4.0, 16.0];
// IR LED 窗：發射錐（半角 led_tc）＝ 4 個位置極值 × 傾角 0／led_tilt_max，自最低 LED 頂點起，全部 hull
module led_window_cut() hull() for (sx = [-1, 1], sy = [-1, 1], t = [0, led_tilt_max])
    led_cone_at(t, [sx*led_pos_tol, sy*led_pos_tol, 0], led_tip_lo, led_tc, (Z_T + 1.5 - led_tip_lo)/cos(t) + 2);
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
        // DHT 艙上方格柵
        for (s = [-1, 1], y = lid_rows_y) mirror([s < 0 ? 1 : 0, 0, 0]) translate([lid_win_x0, y - slot_w/2, Z_L - 1]) cube([lid_win_x1 - lid_win_x0, slot_w, lid_t + 2]);
        translate([gap_slot_x[0], y_pa1, Z_L - 1]) cube([gap_slot_x[1] - gap_slot_x[0], part_gap, lid_t + 2]);
        // 天線上方縱槽
        for (a = ant_slots) translate([a[0] - slot_w/2, a[1], Z_L - 1]) cube([slot_w, a[2] - a[1], lid_t + 2]);
        // BOOT/RST 牙籤孔、藍 LED 窗
        for (b = [esp_boot_xy, esp_rst_xy]) hull() for (k = [0, 1]) translate([bxy(b)[0], bxy(b)[1] + k*esp_alt_dy, Z_L - 1]) cylinder(d = btn_hole_d, h = lid_t + 2);   // 長圓孔：C/G、B/F 兩種插法
        if (led8_window) hull() for (k = [0, 1]) translate([bxy(esp_led8_win)[0], bxy(esp_led8_win)[1] + k*esp_alt_dy, Z_L - 1]) cylinder(d = led_hole_d, h = lid_t + 2);
        led_window_cut();
        rx_window_cut();
        for (i = [0 : len(label) - 1]) if (label[i] != "")
            translate([label_c[0], label_c[1] + ((len(label) - 1)/2 - i)*label_lead, Z_T - label_depth]) linear_extrude(label_depth + 1)
                text(label[i], size = label_size, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
        for (y = lid_tail_grooves_y) translate([tail_groove_x[0], y - 0.4, Z_T - 0.56]) cube([tail_groove_x[1] - tail_groove_x[0], 0.8, 1]);
    }
}

// =====================================================================
//  盤面（單件一盤；外框中心在物理 (110,110)；Y offset −20 不補償）
// =====================================================================
blk_body_o = [plate_c[0], plate_c[1] - L/2, 0];
wht_lid_o  = [plate_c[0], plate_c[1] - (lid_y_tip + y_trail)/2, -Z_L];
module plate_black(colored = false) color(colored ? COL_BODY : undef) translate(blk_body_o) body();
module plate_white(colored = false) color(colored ? COL_LID : undef) translate(wht_lid_o) lid();
assert(blk_body_o[1] >= 0 && blk_body_o[1] + L <= bed_y - bed_back_keep, "殼身超出熱床 Y 0–200");

// =====================================================================
//  預覽配色與場景
// =====================================================================
COL_BODY = "#55585f";   // 黑 PLA（渲染提亮成深灰）
COL_LID  = "#f2f1ec";   // 白 PLA
COL_CUT  = "#e9973b";
COL_TXT  = "#26292d";
COL_CONE = "#ff5a3c";
COL_RX   = "#7a5cff";
module lbl(p, s, t, ha = "left", z = 80) color(COL_TXT) translate([p[0], p[1], z]) linear_extrude(0.1) text(t, size = s, font = "Heiti TC", halign = ha, valign = "center");
module ln(a, b, w = 0.25, z = 80) color(COL_TXT) hull() { translate([a[0], a[1], z]) cylinder(d = w, h = 0.1, $fn = 8); translate([b[0], b[1], z]) cylinder(d = w, h = 0.1, $fn = 8); }
module tick(p, dir, z = 80) color(COL_TXT) translate([p[0], p[1], z]) rotate(dir) linear_extrude(0.1) polygon([[0, 0], [1.4, 0.5], [1.4, -0.5]]);
module dim_x(a, b, t, ty = 2.2) { ln(a, b); tick(a, 0); tick(b, 180); lbl([(a[0] + b[0])/2, a[1] + ty], 1.9, t, "center"); }
module dim_y(a, b, t) { ln(a, b); tick(a, 90); tick(b, -90); lbl([a[0] + 1.2, (a[1] + b[1])/2], 1.9, t, "left"); }
module c_body() color(COL_BODY) body();
module c_lid(dy = 0) color(COL_LID) translate([0, dy, 0]) lid();
module cone_vis(len = 30, tilt = 0) color(COL_CONE, 0.30) led_cone_at(tilt, [0, 0, 0], bb_top_nom + 0.5 + led5_len, led_half_angle, len);
module rx_cone_vis(len = 22) color(COL_RX, 0.25) translate(rx_dome([0, 0, 0], bb_top_nom)) cylinder(r1 = 2.0, r2 = 2.0 + len*tan(30), h = len, $fn = 40);
module ant_zone_vis() color("#ffb000", 0.35) translate([ant_x[0] - 6.0, ant_y[0] - 2, bb_top_nom + 0.05]) cube([ant_x[1] - ant_x[0] + 6.0 + 2.0, ant_y[1] - ant_y[0] + 4, 0.3]);
function v3(p) = str("[", p[0], ",", p[1], ",", p[2], "]");

if (part == "body") {
    body();
} else if (part == "lid_asm") {
    lid();
} else if (part == "lid_print") {
    translate([0, 0, -Z_L]) lid();
} else if (part == "plate_black") {
    plate_black();
} else if (part == "plate_white") {
    plate_white();
} else if (part == "assembly") {
    c_body(); parts_all(); c_lid(0);
} else if (part == "assembly_cone") {
    c_body(); parts_all(); c_lid(0); cone_vis(34);
} else if (part == "lid_open") {
    c_body(); parts_all(); c_lid(lid_open_dy);
} else if (part == "top_open") {
    c_body(); parts_all(); ant_zone_vis();
} else if (part == "back") {
    rotate([0, 180, 0]) { c_body(); parts_all(); c_lid(0); }
} else if (part == "exploded") {
    c_body();
    translate([0, 0, 22]) { bb_ref(); esp_ref(); bb_parts(); }
    translate([0, -26, 0]) dht_ref();
    translate([0, 14, 54]) c_lid(0);
} else if (part == "top_view") {
    // 圖：開蓋俯視（正投影）＋麵包板排／欄標註
    c_body(); parts_all(); ant_zone_vis();
    lbl([0, L + 7], 2.6, "開蓋俯視（蓋拿掉）：麵包板推到右下角黏底", "center");
    lbl([-X_in - wall - 2, dht_cy + 2], 1.9, "DHT11 艙", "right");
    lbl([-X_in - wall - 2, dht_cy - 1], 1.6, "（模組平放、背膠）", "right");
    lbl([-X_in - wall - 2, (y_pa0 + y_pb1)/2], 1.6, "雙層隔牆", "right");
    lbl([-X_in - wall - 2, led_y], 1.6, "IR LED J15/J16", "right");
    lbl([-X_in - wall - 2, rx_y - 1], 1.6, "VS1838B C12–C14", "right");
    lbl([X_in + wall + 1.5, Y_uc + 7], 1.6, "USB-C", "left");
    lbl([(ant_x[0] + ant_x[1])/2 - 3, y_pa1 + 1.0], 1.6, "↑ 天線淨空 9–10 排", "center");
} else if (part == "bb_view") {
    // 圖 03：麵包板擺位特寫（蓋拿掉、正投影；直驅版）＋排／欄號＋零件孔位
    c_body(); parts_all(); ant_zone_vis();
    for (r = [1 : 17]) lbl([row_x(r), y_loc1 + 1.6], 1.1, str(r), "center");
    for (p = [0, 1, 2, 3, 4, 7, 8, 9, 10, 11]) lbl([X_in + wall + 1.2, col_y(p)], 1.5, ["A","B","C","D","E","","","F","G","H","I","J"][p], "left");
    lbl([0, L + 9], 2.4, "麵包板擺位（蓋拿掉；直驅版預設）", "center");
    lbl([0, L + 5.6], 1.6, "排 1 = C3 USB 端；欄 A 在上（接收頭側）、J 在下（DHT 艙側）", "center");
    lx = -X_in - wall - 2;
    lbl([lx, col_y(2) + 4], 1.6, "VS1838B C12 VCC", "right");
    lbl([lx, col_y(2) + 1.6], 1.6, "C13 GND／C14 OUT→GPIO10", "right");
    lbl([lx, col_y(2) - 0.8], 1.4, "（腳後折 90°、透鏡朝蓋）", "right");
    lbl([lx, led_y + 3.2], 1.6, "IR LED J16 陽／J15 陰", "right");
    lbl([lx, led_y + 0.8], 1.6, "220 Ω H16–H17（GPIO3）", "right");
    lbl([lx, led_y - 1.6], 1.6, "陰極跳線 F15→F13（GND）", "right");
    lbl([lx, dht_cy], 1.6, "DHT11（杜邦線→J2/J3/J4）", "right");
    rx_ = X_in + wall + 5;
    lbl([rx_, Y_uc + 3.2], 1.6, "C3 C1–C8／G1–G8", "left");
    lbl([rx_, Y_uc + 0.8], 1.6, "USB-C → 右牆孔", "left");
    lbl([rx_, col_y(dht_col) - 2.2], 1.6, "DHT：J2 GND／J3 3V3", "left");
    lbl([rx_, col_y(dht_col) - 4.6], 1.6, "J4 GPIO4（DATA）", "left");
    lbl([-3.0, y_loc0 - 2.4], 1.4, "↑ 天線淨空 9–10 排", "center");
} else if (part == "section_combo") {
    // 圖：左＝過 LED 與 DHT 母頭的 YZ 縱剖；右＝過 USB 軸的 YZ 剖面（從 +X 看）
    xa = led_x; xb = row_x(dht_rows[1]);
    translate([-34, 0, 0]) rotate([0, -90, 0]) intersection() {
        union() { c_body(); parts_all(); c_lid(0); }
        color(COL_CUT) translate([xa - 80, -20, -1]) cube([80, L + 40, 80]);
    }
    translate([34, 0, 0]) rotate([0, -90, 0]) intersection() {
        union() { c_body(); parts_all(); c_lid(0); }
        color(COL_CUT) translate([xb - 80, -20, -1]) cube([80, L + 40, 80]);
    }
    lbl([-34 - Z_T/2, L + 8], 2.3, "縱剖 1：過 IR LED（x=" , "center");
    lbl([-34 - Z_T/2, L + 5], 1.8, str("x=", round(xa*10)/10, "，看發射錐與隔牆"), "center");
    lbl([34 - Z_T/2, L + 8], 2.3, "縱剖 2：過 DHT 母頭", "center");
    lbl([34 - Z_T/2, L + 5], 1.8, str("x=", round(xb*10)/10, "，母頭穿雙層隔牆"), "center");
    lbl([-34 - Z_T - 2, L - 3], 1.6, "← 蓋（房間）", "right");
    lbl([-34 + 2, L - 3], 1.6, "背（牆）→", "left");
} else if (part == "ir_view") {
    // 圖：左＝過 LED 的 YZ 剖面（發射錐 ±25°、0° 與 15°）；右＝正面（蓋面）IR 窗、接收窗、相距
    translate([-30, 0, 0]) rotate([0, -90, 0]) {
        intersection() {
            union() { c_body(); parts_all(); c_lid(0); }
            color(COL_CUT) translate([led_x - 80, -20, -1]) cube([80, L + 60, 80]);
        }
        cone_vis(16, 0);
    }
    translate([34, 0, 0]) { c_body(); parts_all(false); c_lid(0); }
    lbl([-30 - Z_T/2, L + 9], 2.3, "IR LED 剖面（過 LED 軸）", "center");
    lbl([-30 - Z_T/2, L + 6], 1.7, "發射錐 ±25°（窗口按 ±27°、位置 ±2、往上彎 0–15° 開）", "center");
    lbl([34, L + 9], 2.3, "正面（蓋面）", "center");
    dim_x([34 + led_x, L + 3.5], [34 + rx_x, L + 3.5], "", 0);
    lbl([34, L + 5.8], 1.8, str("IR 發射 ↔ 接收 ", round(ir_sep*10)/10, " mm（≥25）"), "center");
    lbl([34 + led_x, led_y - 12.5], 1.8, "IR 發射窗", "center");
    lbl([34 + rx_x + 10, rx_y], 1.8, "VS1838B 接收窗", "left");
} else if (part == "wall_view") {
    rotate([90, 0, 0]) { c_body(); parts_all(); c_lid(0); usb_cable_ref(); cone_vis(24, 10); }
    color("#b9b4aa") translate([-80, 0.0, -40]) cube([160, 1, 160]);
} else if (part == "plate_view") {
    for (k = [0, 1]) translate([k*240, 0, 0]) {
        color("#d6d6d6") translate([0, 0, -1.2]) cube([bed_x, bed_y - bed_back_keep, 1]);
        color("#e07a6a") translate([0, bed_y - bed_back_keep, -1.2]) cube([bed_x, bed_back_keep, 1]);
        if (k == 0) plate_black(true); else plate_white(true);
        lbl([110, 207], 6, "後緣 20 mm 留空（Y offset −20 刻意，不改）", "center", 40);
        lbl([110, -14], 9, k == 0 ? "BLACK 盤（黑 PLA）：殼身" : "WHITE 盤（白 PLA）：滑蓋", "center", 40);
        lbl([110, 30], 5, "置中 (110,110)", "center", 40);
    }
} else if (part == "dims") {
    echo(str("DIMS {\"bb_dht_conn\":\"", bb_dht_conn, "\",\"Z_f\":", Z_f, ",\"floor_s\":", floor_s, ",\"Z_L\":", Z_L, ",\"Z_T\":", Z_T,
             ",\"bb_top_nom\":", bb_top_nom, ",\"bb_top_max\":", bb_top_max, ",\"bb_top_min\":", bb_top_min, ",\"Z_e\":", Z_e, ",\"Z_u\":", Z_u,
             ",\"notch_drop\":", notch_drop, ",\"bump_h\":", bump_h, ",\"bump_base\":", bump_base, ",\"bump_top\":", bump_top,
             ",\"bump_len\":", bump_len, ",\"bump_y\":", bump_y, ",\"lid_t\":", lid_t, ",\"lid_foot\":", lid_foot, ",\"fdm_gap\":", fdm_gap,
             ",\"X_in\":", X_in, ",\"wall\":", wall, ",\"wall_bot\":", wall_bot, ",\"wall_top\":", wall_top, ",\"outer_w\":", outer_w, ",\"L\":", L,
             ",\"y_in0\":", y_in0, ",\"y_pa0\":", y_pa0, ",\"y_pa1\":", y_pa1, ",\"y_pb0\":", y_pb0, ",\"y_pb1\":", y_pb1, ",\"y_b0\":", y_b0, ",\"y_b1\":", y_b1,
             ",\"y_loc0\":", y_loc0, ",\"y_loc1\":", y_loc1, ",\"bb_loc\":[", bb_loc[0], ",", bb_loc[1], "],\"bb_cx\":", bb_cx, ",\"bb_cy\":", bb_cy,
             ",\"X_ue\":", X_ue, ",\"X_ae\":", X_ae, ",\"Y_uc\":", Y_uc,
             ",\"usb_cut_y\":[", usb_cut_y[0], ",", usb_cut_y[1], "],\"usb_cut_z\":[", usb_cut_z[0], ",", usb_cut_z[1], "]",
             ",\"dslot_x\":[", dslot_x[0], ",", dslot_x[1], "],\"dslot_z\":[", dslot_z[0], ",", dslot_z[1], "]",
             ",\"dht_x0\":", dht_x0, ",\"dht_cy\":", dht_cy, ",\"dht_z0\":", dht_z0, ",\"dht_rib_x\":", str(dht_rib_x), ",\"dht_rib_h\":", dht_rib_h,
             ",\"y_lead\":", y_lead, ",\"slit_end_y\":", slit_end_y, ",\"slit_w\":", slit_w, ",\"tongue_w\":", tongue_w, ",\"lid_hw\":", lid_hw, ",\"lid_top_hw\":", lid_top_hw,
             ",\"vz0\":", vz0, ",\"vz0s\":", vz0s, ",\"vz1\":", vz1, ",\"vzb\":", vzb, ",\"part_t\":", part_t, ",\"part_gap\":", part_gap,
             ",\"kh_x\":", kh_x, ",\"kh_y\":[", kh_y[0], ",", kh_y[1], "],\"kh_len\":", kh_len, ",\"kh_lip\":", kh_lip, ",\"kh_head\":", kh_head,
             ",\"kh_d\":", kh_d, ",\"kh_w\":", kh_w, ",\"floor_t\":", floor_t,
             ",\"ant_x\":[", ant_x[0], ",", ant_x[1], "],\"ant_y\":[", ant_y[0], ",", ant_y[1], "],\"ant_slots\":", str(ant_slots),
             ",\"lid_win_x0\":", lid_win_x0, ",\"lid_win_x1\":", lid_win_x1, ",\"lid_rows_y\":", str(lid_rows_y), ",\"label_c\":", str(label_c), ",\"label_depth\":", label_depth,
             ",\"led_x\":", led_x, ",\"led_y\":", led_y, ",\"led_tip_lo\":", led_tip_lo, ",\"led_tip_hi\":", led_tip_hi, ",\"led_pos_tol\":", led_pos_tol, ",\"led_tc\":", led_tc,
             ",\"rx_x\":", rx_x, ",\"rx_y\":", rx_y, ",\"rx_win_d\":", rx_win_d, ",\"rx_win_ch\":", rx_win_ch, ",\"ir_sep\":", ir_sep,
             ",\"boot\":", str(bxy(esp_boot_xy)), ",\"rst\":", str(bxy(esp_rst_xy)), ",\"led8\":", str(bxy(esp_led8_win)), ",\"btn_hole_d\":", btn_hole_d,
             ",\"row1_x\":", row_x(1), ",\"blk_body_o\":", v3(blk_body_o), ",\"wht_lid_o\":", v3(wht_lid_o), ",\"gap_slot_x\":", str(gap_slot_x), "}"));
    cube(1);
} else if (part == "check_parts_body") {
    intersection() { body(); parts_all(false); }
} else if (part == "check_parts_lid") {
    intersection() { lid(); parts_all(false); }
} else if (part == "check_lid_body") {
    intersection() { body(); lid(); }
} else if (part == "check_slide") {
    intersection() { body(false); for (d = [0.5 : 1.0 : L + 4]) translate([0, d, 0]) lid(); }
}
