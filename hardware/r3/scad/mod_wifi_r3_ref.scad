// =====================================================================
//  mod_wifi_r3_ref.scad — R3（麵包板版）參考零件：只供預覽與干涉檢查，不會進任何 STL
//  麵包板 SYB-170（17 排 × 10 欄＋中溝）、ESP32-C3 SuperMini（排針朝下插麵包板）、DHT11 三腳模組（彎針＋杜邦母頭）、
//  麵包板端 1×3 90° 排針＋杜邦母頭（或直針直立母頭＝tall 版）、IR LED 5 mm、VS1838B（平躺、透鏡朝蓋）、
//  S8050（TO-92）、電阻 ×3、跨溝短跳線 ×2、杜邦／跳線（示意）、USB-C 插頭。
//  本檔不宣告頂層參數，全部引用 mod_wifi_r3_case.scad 的全域值。
//  麵包板座標：排 r＝1..17（r=1 在 +X＝USB 端）；欄 p＝A..E＝0..4、F..J＝7..11（A 在 +Y＝上端）。
// =====================================================================

// 線色：5V 橘、GND 黑、3V3 紅、DATA 黃、TX 綠、RX 紫
function wcol(n) = n == "5V" ? "#ff7f0e" : n == "GND" ? "#1e1e1e" : n == "3V3" ? "#d62728" : n == "DATA" ? "#f2c200" :
                   n == "TX" ? "#2ca02c" : n == "RX" ? "#9467bd" : "#888";

// 孔位（d＝麵包板相對標稱位置的偏移 [dx, dy, dz]）
function hole(r, p, d = [0, 0, 0]) = [row_x(r) + d[0], col_y(p) + d[1]];

// ---------------- 麵包板 ----------------
// l／w＝本體長寬、ht＝含背膠總高（頂面＝Z_f＋ht）；d＝[dx, dy]（浮動偏移）
module bb_ref(colored = true, l = bb_l, w = bb_w, ht = bb_ht, d = [0, 0, 0], holes = true) {
    z0 = Z_f + bb_tape_vis; top = Z_f + ht;
    color(colored ? "#f4f3ee" : "#444") difference() {
        translate([bb_cx + d[0] - l/2, bb_cy + d[1] - w/2, colored ? z0 : Z_f]) cube([l, w, top - (colored ? z0 : Z_f)]);
        if (holes) {
            for (r = [1 : bb_rows], p = [0, 1, 2, 3, 4, 7, 8, 9, 10, 11]) let(q = hole(r, p, d))
                translate([q[0] - 0.45, q[1] - 0.45, top - 1.5]) cube([0.9, 0.9, 2]);
            translate([bb_cx + d[0] - 20.3, bb_cy + d[1] - 1.1, top - 0.8]) cube([40.6, 2.2, 1]);   // 中溝
            for (s = [-1, 1]) translate([bb_cx + d[0] + s*bb_mhole/2, bb_cy + d[1], top - 3]) cylinder(d = 2.0, h = 4, $fn = 16);   // 溝內安裝孔
        }
    }
    if (colored && holes) {
        // 拼接燕尾凸榫（示意：凸 bb_tab_vis、寬 4.6、只在下半部 4.2）：+Y 長邊中央、-X 短邊中央；凹槽面不畫
        color("#f4f3ee") {
            translate([bb_cx + d[0] - 2.3, bb_cy + d[1] + w/2 - 0.01, z0]) cube([4.6, bb_tab_vis, 4.2]);
            translate([bb_cx + d[0] - l/2 - bb_tab_vis + 0.01, bb_cy + d[1] - 2.3, z0]) cube([bb_tab_vis, 4.6, 4.2]);
        }
        color("#c9a227") translate([bb_cx + d[0] - l/2, bb_cy + d[1] - w/2, Z_f]) cube([l, w, bb_tape_vis]);   // 背膠（示意）
    }
}
// 麵包板極值外框（實心，含背膠；凸榫另計）：檢查用
module bb_box(l, w, ht, d = [0, 0, 0], tab = 0) {
    translate([bb_cx + d[0] - l/2, bb_cy + d[1] - w/2, Z_f + 0.01]) cube([l, w, ht - 0.01]);
    if (tab > 0) {   // 凸榫可能在任一邊中央（買到的方向不定）：四邊中央都放
        for (s = [-1, 1]) {
            translate([bb_cx + d[0] - 2.3, bb_cy + d[1] + s*(w/2 + tab/2) - tab/2, Z_f + 0.01]) cube([4.6, tab, 4.2]);
            translate([bb_cx + d[0] + s*(l/2 + tab/2) - tab/2, bb_cy + d[1] - 2.3, Z_f + 0.01]) cube([tab, 4.6, 4.2]);
        }
    }
}

// ---------------- ESP32-C3 SuperMini（排針朝下插在 B1–B8／F1–F8） ----------------
// t＝PCB 厚；over＝USB-C 凸出板邊；d＝整組偏移；zt＝麵包板頂面（排針塑膠座底）
module esp_ref(colored = true, t = esp_pcb_t, over = esp_usb_over, d = [0, 0, 0], zt = bb_top_nom) {
    ze = zt + hdr_plastic;          // PCB 底
    zp = ze + t;
    function bq(p) = bxy(p) + [d[0], d[1]];
    translate([0, 0, 0]) {
        color(colored ? "#1d4f9c" : "#444") translate([0, 0, ze]) linear_extrude(t)
            offset(r = 0.5) offset(delta = -0.5) translate([X_ae + d[0], Y_top - esp_w + d[1]]) square([esp_l, esp_w]);
        color("#c9ccd1") translate([X_ue + over + d[0], Y_uc + d[1], zp + esp_usb_h/2]) rotate([0, -90, 0])
            linear_extrude(esp_usb_len) hull() for (s = [-1, 1]) translate([0, s*(esp_usb_w/2 - esp_usb_h/2)]) circle(d = esp_usb_h, $fn = 24);
        for (b = [esp_boot_xy, esp_rst_xy]) let(q = bq(b)) {
            color("#e6e6e6") translate([q[0] - 2.0, q[1] - 1.5, zp]) cube([4.0, 3.0, 1.2]);
            color("#2b2b2b") translate([q[0], q[1], zp]) cylinder(d = 1.4, h = esp_btn_h, $fn = 16);
        }
        color("#2f6bff") translate(concat(bq(esp_led8_xy), [zp]) - [0.3, 0.5, 0]) cube([0.6, 1.0, 0.45]);
        color("#ff3030") translate(concat(bq(esp_ledp_xy), [zp]) - [0.3, 0.5, 0]) cube([0.6, 1.0, 0.45]);
        a0 = bq([esp_ant_bx[1], esp_ant_by[1]]);
        color("#b8452e") translate([a0[0], a0[1], zp]) cube([esp_ant_by[1] - esp_ant_by[0], esp_ant_bx[1] - esp_ant_bx[0], 1.1]);
        c = bq([9.6, 14.6]);
        color("#262626") translate([c[0], c[1], zp]) rotate(45) translate([-2.5, -2.5, 0]) cube([5, 5, 0.85]);
        // 排針：塑膠座在 PCB 與麵包板之間、針插進麵包板（示意 6.0）
        for (p = [esp_colL, esp_colR]) {
            q1 = hole(esp_row1, p, d); q8 = hole(esp_row1 + 7, p, d);
            color("#111") translate([q8[0] - 1.27, q1[1] - 1.25, zt]) cube([q1[0] - q8[0] + 2.54, 2.5, hdr_plastic]);
            for (n = [0 : 7]) let(q = hole(esp_row1 + n, p, d)) {
                color("#d4af37") translate([q[0] - 0.32, q[1] - 0.32, zt - 6.0]) cube([0.64, 0.64, 6.0 + hdr_plastic + t]);
                color("#c0c0c0") translate([q[0], q[1], zp]) cylinder(d1 = 1.6, d2 = 0.64, h = hdr_top_h, $fn = 12);
            }
        }
    }
}

// ---------------- DHT11 三腳模組（彎針在 +X 端；平放在支撐肋上；DHT11 在 -X 端朝蓋） ----------------
module dht_ref(colored = true, l = dht_l, w = dht_w, t = dht_t, housings = true) {
    x0 = dht_x0; x1 = x0 + l; y0 = dht_cy - w/2; z0 = dht_z0;
    color(colored ? "#1f4fa3" : "#444") difference() {
        translate([x0, y0, z0]) cube([l, w, t]);
        translate([x1 - 8.5, dht_cy + w/2 - 3.2, z0 - 1]) cylinder(d = 3.0, h = t + 2, $fn = 20);   // 安裝孔（示意）
    }
    // DHT11 本體（ASAIR 尺寸 15.5×12×5.5）：長邊沿模組長軸，在 -X 端
    color(colored ? "#5fb3d9" : "#444") translate([x0 + 1.0, dht_cy - dht_body[1]/2, z0 + t]) cube([dht_body[0], dht_body[1], dht_body[2]]);
    if (colored) for (i = [0 : 3], j = [0 : 2]) color("#2a5f7a") translate([x0 + 3.5 + i*3.4, dht_cy - 3.6 + j*3.6, z0 + t + dht_body[2] - 0.2]) cube([1.6, 1.6, 0.3]);
    // 紅色電源 LED（3 mm 直立）
    color("#e03030") translate([x1 - 5.0, dht_cy - w/2 + 2.6, z0 + t]) { cylinder(d = 3.0, h = 4.0, $fn = 16); translate([0, 0, 4.0]) sphere(d = 3.0, $fn = 16); }
    // 彎針排針：塑膠座在背面（較差情形：往下掛 2.5）、針沿 +X 伸出板邊
    color("#111") translate([x1 - 2.5, dht_cy - 3*2.54/2, z0 - dht_hdr_plastic]) cube([2.5, 3*2.54, dht_hdr_plastic]);
    for (i = [-1 : 1]) {
        color("#d4af37") translate([x1 - 1.27, dht_cy + i*2.54 - 0.32, z0 - dht_hdr_plastic/2 - 0.32]) cube([1.27 + dht_hdr_pins, 0.64, 0.64]);
        if (housings) color(colored ? wcol(i == -1 ? "GND" : i == 0 ? "3V3" : "DATA") : "#444")
            translate([x1, dht_cy + i*2.54 - dupont_w/2, z0 - dht_hdr_plastic/2 - dupont_w/2]) cube([dupont_len, dupont_w, dupont_w]);
    }
}

// ---------------- 麵包板端 DHT 接頭（J2 GND、J3 3V3、J4 DATA） ----------------
// angle＝1×3 90° 排針：塑膠座貼麵包板、橫針朝 -Y、母頭平躺穿過雙層隔牆孔；straight＝直針＋直立母頭（tall 版）
module bb_dht_hdr_ref(colored = true, kind = bb_dht_conn, d = [0, 0, 0], zt = bb_top_nom) {
    ys = col_y(dht_col) + d[1];
    for (k = [0 : 2]) let(r = dht_rows[k], x = row_x(r) + d[0], n = ["GND", "3V3", "DATA"][k]) {
        if (kind == "angle") {
            color("#111") translate([x - 1.27, ys - 1.25, zt]) cube([2.54, 2.5, 2.5]);
            color("#d4af37") translate([x - 0.32, ys - 1.25 - dht_hdr_pins, zt + 1.27 - 0.32]) cube([0.64, dht_hdr_pins + 1.25, 0.64]);
            color(colored ? wcol(n) : "#444") translate([x - dupont_w/2, ys - 1.25 - dupont_len, zt + 1.27 - dupont_w/2]) cube([dupont_w, dupont_len, dupont_w]);
        } else {
            color("#111") translate([x - 1.27, ys - 1.25, zt]) cube([2.54, 2.5, 2.5]);
            color(colored ? wcol(n) : "#444") translate([x - dupont_w/2, ys - dupont_w/2, zt + 2.5]) cube([dupont_w, dupont_w, dupont_len]);
        }
    }
}
// 母頭（只有母頭外殼，檢查用；可加偏移）
module bb_dht_housings(kind = bb_dht_conn, d = [0, 0, 0], zt = bb_top_nom) {
    ys = col_y(dht_col) + d[1];
    for (r = dht_rows) let(x = row_x(r) + d[0])
        if (kind == "angle") translate([x - dupont_w/2, ys - 1.25 - dupont_len, zt + 1.27 - dupont_w/2]) cube([dupont_w, dupont_len, dupont_w]);
        else translate([x - dupont_w/2, ys - dupont_w/2, zt + 2.5]) cube([dupont_w, dupont_w, dupont_len + 3.0]);   // ＋彎線 3
}

// ---------------- IR LED（5 mm；腳插 J14 陽極／J15 陰極；可往 +Y 傾 tilt） ----------------
// gap＝凸緣底離麵包板；len＝凸緣底→頂
module led_ref(colored = true, tilt = 0, gap = 0.5 + raise, len = led5_len, d = [0, 0, 0], zt = bb_top_nom) {
    translate([led_x + d[0], led_y + d[1], zt + gap]) rotate([-tilt, 0, 0]) color(colored ? "#cfd8dc" : "#444", colored ? 0.85 : 1) {
        cylinder(d = led5_fl_d, h = led5_fl_h, $fn = 32);
        cylinder(d = led5_d, h = len - led5_d/2, $fn = 32);
        translate([0, 0, len - led5_d/2]) sphere(d = led5_d, $fn = 32);
    }
    if (colored) color("#c8c8c8") for (s = [-1, 1]) translate([led_x + d[0] + s*1.27 - 0.25, led_y + d[1] - 0.25, zt - 0.5]) cube([0.5, 0.5, gap + 0.6]);
}
// 發射錐（自 LED 頂點起，半角 ang；r1＝透鏡半徑）
function led_tip(tilt, d, ztip) = [led_x + d[0], led_y + d[1] + led5_len_max*sin(tilt), ztip - led5_len_max*(1 - cos(tilt))];
module led_cone_at(tilt, d, ztip, ang, len = 18) translate(led_tip(tilt, d, ztip)) rotate([-tilt, 0, 0])
    cylinder(r1 = led5_d/2, r2 = led5_d/2 + len*tan(ang), h = len, $fn = 40);

// ---------------- VS1838B（腳插 C12 VCC／C13 GND／C14 OUT；腳往後折 90°，本體朝 +Y 平躺、透鏡朝蓋） ----------------
module rx_ref(colored = true, b = rx_body, lift = 0.5 + raise, d = [0, 0, 0], zt = bb_top_nom) {
    y0 = col_y(rx_col) + d[1] + 1.0;      // 本體底面（出腳面）離孔 1.0
    translate([rx_x + d[0] - b[0]/2, y0, zt + lift]) {
        color(colored ? "#1b1b1b" : "#444") cube([b[0], b[1], b[2] - 1.0]);
        color(colored ? "#2b2b2b" : "#444") translate([b[0]/2, rx_dome_off - 1.0, b[2] - 1.0]) scale([1, 1, 0.5]) sphere(d = 4.0, $fn = 24);
    }
    if (colored) color("#c8c8c8") for (r = rx_rows) let(q = hole(r, rx_col, d)) {
        translate([q[0] - 0.25, q[1] - 0.25, zt - 0.5]) cube([0.5, 0.5, lift + 1.3]);
        translate([q[0] - 0.25, q[1] - 0.25, zt + lift + 0.8]) cube([0.5, 1.3, 0.5]);
    }
}
// 透鏡頂點
function rx_dome(d, zt, b = rx_body, lift = 0.5 + raise) = [rx_x + d[0], col_y(rx_col) + d[1] + 1.0 + rx_dome_off - 1.0, zt + lift + b[2]];

// ---------------- S8050（TO-92：F13 E、F14 B、F15 C；平面朝 +Y＝中溝那側；電晶體版才插） ----------------
module q1_ref(colored = true, d = [0, 0, 0], zt = bb_top_nom) {
    q = hole(14, q1_col, d);
    color(colored ? "#202020" : "#444") translate([q[0], q[1], zt + 2.0]) intersection() {
        translate([0, -0.8, 0]) cylinder(d = 4.8, h = 4.6, $fn = 32);      // 圓背朝 -Y
        translate([-2.4, -2.3, 0]) cube([4.8, 3.8, 4.6]);                   // 平面在 +Y 1.5
    }
    if (colored) color("#c8c8c8") for (r = [13, 14, 15]) let(h = hole(r, q1_col, d)) translate([h[0] - 0.22, h[1] - 0.22, zt - 0.5]) cube([0.44, 0.44, 2.6]);
}
// ---------------- 電阻（a、b＝[排, 欄]；hairpin＝直立） ----------------
module res_ref(a, b, colored = true, bands = ["#ff7f0e", "#ff7f0e", "#1e1e1e"], hairpin = false, d = [0, 0, 0], zt = bb_top_nom) {
    p = hole(a[0], a[1], d); q = hole(b[0], b[1], d);
    if (!hairpin) {
        m = (p + q)/2; v = q - p; L_ = norm(v); ang = atan2(v[1], v[0]);
        color(colored ? "#d9c7a0" : "#444") translate([m[0], m[1], zt + 2.2]) rotate([0, 90, ang]) cylinder(d = 1.8, h = 6.3, center = true, $fn = 16);
        if (colored) {
            for (i = [0 : 2]) color(bands[i]) translate([m[0], m[1], zt + 2.2]) rotate([0, 90, ang]) translate([0, 0, -2.0 + i*1.2]) cylinder(d = 1.86, h = 0.5, $fn = 16);
            color("#c8c8c8") for (e = [p, q]) translate([e[0] - 0.2, e[1] - 0.2, zt - 0.5]) cube([0.4, 0.4, 2.9]);
            color("#c8c8c8") hull() { translate([p[0], p[1], zt + 2.2]) sphere(d = 0.4, $fn = 8); translate([q[0], q[1], zt + 2.2]) sphere(d = 0.4, $fn = 8); }
        }
    } else {
        color(colored ? "#d9c7a0" : "#444") translate([q[0], q[1], zt + 1.0]) cylinder(d = 1.8, h = 6.3, $fn = 16);
        if (colored) {
            for (i = [0 : 2]) color(bands[i]) translate([q[0], q[1], zt + 2.2 + i*1.2]) cylinder(d = 1.86, h = 0.5, $fn = 16);
            color("#c8c8c8") { translate([p[0] - 0.2, p[1] - 0.2, zt - 0.5]) cube([0.4, 0.4, 8.6]);
                               hull() { translate([p[0], p[1], zt + 8.0]) sphere(d = 0.4, $fn = 8); translate([q[0], q[1], zt + 8.0]) sphere(d = 0.4, $fn = 8); } }
        }
    }
}
// ---------------- 跳線（貼麵包板面；pts＝[[排, 欄], …] 或 [x, y] 絕對座標；示意） ----------------
function jp(p, d) = [row_x(p[0]) + d[0], col_y(p[1]) + d[1]];   // p＝[排, 欄]（可為小數，畫線用）
module jumper(pts, n, colored = true, d = [0, 0, 0], zt = bb_top_nom, z = 0.9) {
    color(colored ? wcol(n) : "#444") {
        for (i = [0 : len(pts) - 2]) hull() {
            a = jp(pts[i], d); b = jp(pts[i + 1], d);
            translate([a[0], a[1], zt + z]) sphere(d = 1.1, $fn = 10);
            translate([b[0], b[1], zt + z]) sphere(d = 1.1, $fn = 10);
        }
        for (e = [pts[0], pts[len(pts) - 1]]) let(q = jp(e, d)) translate([q[0], q[1], zt - 0.5]) cylinder(d = 0.6, h = z + 0.5, $fn = 8);
    }
}
// 麵包板上全部 IR 零件與跳線（drive＝direct：直驅版預設；npn：補 S8050 後的電晶體版）
// 定案腳位：DHT11 DATA＝GPIO4（J4）、IR TX＝GPIO3、VS1838B OUT＝GPIO10（BRIEF_R3 追加 3）
module bb_parts(colored = true, d = [0, 0, 0], zt = bb_top_nom, wires = true, drive = ir_drive) {
    R220 = ["#d62728", "#d62728", "#8b4513"]; R1K = ["#8b4513", "#1e1e1e", "#d62728"]; R10K = ["#8b4513", "#1e1e1e", "#ff7f0e"];
    led_ref(colored, 0, 0.5 + raise, led5_len, d, zt);
    rx_ref(colored, rx_body, 0.5 + raise, d, zt);
    bb_dht_hdr_ref(colored, bb_dht_conn, d, zt);
    res_ref([16, 9], [17, 9], colored, R220, true, d, zt);                          // 220 Ω：H16（陽極列）↔ H17
    if (drive == "npn") {
        q1_ref(colored, d, zt);                                                      // S8050：F13 E／F14 B／F15 C
        res_ref([16, 7], [17, 7], colored, R220, true, d, zt);                      // 3×220 Ω 並聯
        res_ref([16, 8], [17, 8], colored, R220, true, d, zt);
        res_ref([14, 9], [12, 9], colored, R1K, true, d, zt);                       // 1 kΩ：H12 ↔ H14
        res_ref([14, 10], [13, 10], colored, R10K, true, d, zt);                    // 10 kΩ：I13 ↔ I14
    } else jumper([[15, 7], [13, 7]], "GND", colored, d, zt, 0.8);                  // 直驅：陰極列 F15 → GND 列 F13
    if (wires) {
        jumper([[2, 9], [2.6, 9.4], [12.4, 9.4], [13, 11]], "GND", colored, d, zt, 1.0);                 // H2 → J13（GND 列）
        jumper([[3, 9], [3.6, 9.2], [11.6, 9.2], [11.9, 6.0], [12, 4]], "3V3", colored, d, zt, 1.8);     // H3 → E12（跨溝）
        jumper([[2, 10], [2.6, 10.1], [12.6, 10.1], [12.9, 6.0], [13, 4]], "GND", colored, d, zt, 2.4);  // I2 → E13（跨溝）
        jumper([[6, 0], [11.2, -0.2], [11.4, 5.5], [13.9, 5.5], [14, 4]], "RX", colored, d, zt, 3.0);    // A6 → 溝 → E14
        if (drive == "npn") {
            jumper([[5, 9], [5.6, 10.7], [11.4, 10.7], [12, 11]], "TX", colored, d, zt, 1.4);            // H5 → J12
            jumper([[1, 9], [1.6, 10.9], [16.4, 10.9], [17, 11]], "5V", colored, d, zt, 0.6);            // H1 → J17
        } else jumper([[5, 9], [5.6, 10.7], [16.4, 10.7], [17, 11]], "TX", colored, d, zt, 1.4);         // H5 → J17
    }
}
// 麵包板零件最大包絡（任何東西都不得超過麵包板頂面＋parts_hmax）：檢查用
module bb_envelope(l = bb_lmax, w = bb_wmax, d = [0, 0, 0], h = parts_hmax) translate([bb_cx + d[0] - l/2, bb_cy + d[1] - w/2, bb_top_max + d[2]]) cube([l, w, h]);

// ---------------- USB-C 插頭（模具外殼 w×h，自母座口往 +X 25；金屬殼 8.25×2.40 插入 6.65） ----------------
module usb_plug(w = plug_body[0], h = plug_body[1], r = 0.0, over = esp_usb_over, d = [0, 0, 0], zt = bb_top_nom, t = esp_pcb_t) {
    x0 = X_ue + over + d[0];
    zu = zt + hdr_plastic + t + esp_usb_h/2;
    translate([x0, Y_uc + d[1], zu]) rotate([0, 90, 0]) linear_extrude(25)
        if (r > 0) offset(r = r) offset(delta = -r) square([h, w], center = true); else square([h, w], center = true);
    translate([x0 - 6.65, Y_uc + d[1], zu]) rotate([0, 90, 0]) linear_extrude(6.65) square([2.40, 8.25], center = true);
}
module usb_receptacle(over, d = [0, 0, 0], zt = bb_top_nom, t = esp_pcb_t) translate([X_ue + over + d[0], Y_uc + d[1], zt + hdr_plastic + t + esp_usb_h/2]) rotate([0, -90, 0])
    linear_extrude(esp_usb_len) hull() for (s = [-1, 1]) translate([0, s*(esp_usb_w/2 - esp_usb_h/2)]) circle(d = esp_usb_h, $fn = 24);
module usb_cable_ref() color("#2b2b2b") {
    translate([X_ue + esp_usb_over, Y_uc, Z_u]) rotate([0, 90, 0]) linear_extrude(18) offset(r = 1) offset(delta = -1) square([plug_body[1], plug_body[0]], center = true);
    translate([X_ue + esp_usb_over + 18, Y_uc, Z_u]) rotate([0, 90, 0]) cylinder(d = 3.5, h = 8, $fn = 16);
    translate([X_ue + esp_usb_over + 26, Y_uc, Z_u]) rotate([90, 0, 0]) rotate_extrude(angle = 90, $fn = 24) translate([6, 0]) circle(d = 3.5, $fn = 12);
}

// 全部參考件（標稱位置）
module parts_all(colored = true, wires = true) {
    bb_ref(colored);
    esp_ref(colored);
    bb_parts(colored, [0, 0, 0], bb_top_nom, wires);
    dht_ref(colored);
}
