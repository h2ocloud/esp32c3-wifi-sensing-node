// =====================================================================
//  mod_wifi_ref.scad — 參考零件（只供預覽與干涉檢查，不會進任何 STL）
//  ESP32-C3 SuperMini（PCB、USB-C 母座、BOOT/RST、LED、陶瓷天線、晶片、焊盤、選配排針＋杜邦母頭）、
//  GY-SHT31-D／AHT20 小板（直排針＋杜邦母頭）、4 條杜邦線。
//  本檔不宣告頂層參數，全部引用 mod_wifi_case.scad 的全域值（被 include 時才解析）。
// =====================================================================

// 線色：3V3/VIN 紅、GND 黑、SDA 藍、SCL 黃
function wire_col(sig) = sig == "3V3" ? "#d62728" : sig == "GND" ? "#1e1e1e" : sig == "SDA" ? "#1f6fd1" : "#f2c200";

// ---------------- ESP32-C3 SuperMini ----------------
// 板座標 [bx, by]：bx 自 GPIO5 排板邊量起、by 自 USB 端板邊量起（元件面朝上、USB 朝上看）
module esp_ref(colored = true, wires_stub = true) {
    t = esp_pcb_t;
    // PCB（四角 R0.5）
    color(colored ? "#1d4f9c" : "#444") translate([0, 0, Z_e]) linear_extrude(t)
        offset(r = 0.5) offset(delta = -0.5) translate([X_ae, y_pcb0]) square([esp_l, esp_w]);
    // 焊盤（16 個鍍金環，示意）
    for (row = [-1, 1], n = [1 : 8]) {
        p = pin_xy(row, n);
        color("#d9b54a") translate([p[0], p[1], Z_e - 0.02]) difference() {
            cylinder(d = 1.6, h = t + 0.06, $fn = 16);
            translate([0, 0, -1]) cylinder(d = 1.0, h = t + 2, $fn = 12);
        }
    }
    // USB-C 母座（橢圓外殼，凸出 USB 端板邊 esp_usb_over）
    color("#c9ccd1") translate([X_ue + esp_usb_over, bxy([esp_usb_bx, 0])[1], Z_u]) rotate([0, -90, 0])
        linear_extrude(esp_usb_len) hull() for (s = [-1, 1]) translate([0, s*(esp_usb_w/2 - esp_usb_h/2)]) circle(d = esp_usb_h, $fn = 24);
    // BOOT / RST 按鍵（本體＋按柄）
    for (b = [esp_boot_xy, esp_rst_xy]) {
        q = bxy(b);
        color("#e6e6e6") translate([q[0] - 1.5, q[1] - 2.0, Z_p]) cube([3.0, 4.0, 1.2]);
        color("#2b2b2b") translate([q[0], q[1], Z_p]) cylinder(d = 1.4, h = esp_btn_h, $fn = 16);
    }
    // LED：藍（GPIO8）、紅（電源）
    color("#2f6bff") translate(concat(bxy(esp_led8_xy), [Z_p]) - [0.5, 0.3, 0]) cube([1.0, 0.6, 0.45]);
    color("#ff3030") translate(concat(bxy(esp_ledp_xy), [Z_p]) - [0.3, 0.5, 0]) cube([0.6, 1.0, 0.45]);
    // 陶瓷天線（by 20.0–22.2、bx 5.5–12.0）
    a0 = bxy([esp_ant_bx[1], esp_ant_by[1]]);
    color("#b8452e") translate([a0[0], a0[1], Z_p]) cube([esp_ant_by[1] - esp_ant_by[0], esp_ant_bx[1] - esp_ant_bx[0], 1.1]);
    // ESP32-C3（QFN32 5×5）、晶振、LDO（示意位置）
    c = bxy([9.6, 14.6]);
    color("#262626") translate([c[0], c[1], Z_p]) rotate(45) translate([-2.5, -2.5, 0]) cube([5, 5, 0.85]);
    x = bxy([3.2, 17.6]);
    color("#bcbcbc") translate([x[0] - 1.25, x[1] - 1.6, Z_p]) cube([2.5, 3.2, 0.8]);
    r = bxy([14.6, 15.4]);
    color("#303030") translate([r[0] - 1.5, r[1] - 1.45, Z_p]) cube([3.0, 2.9, 1.1]);
    // 排針（esp_hdr="bottom"：塑膠座貼 PCB 底、長針朝背板）＋使用中 4 支腳的杜邦母頭
    if (esp_hdr == "bottom") {
        for (row = [-1, 1]) {
            p1 = pin_xy(row, 1); p8 = pin_xy(row, 8);
            color("#111") translate([p8[0] - 1.27, p1[1] - 1.27, Z_e - hdr_plastic]) cube([p1[0] - p8[0] + 2.54, 2.54, hdr_plastic]);
            for (n = [1 : 8]) {
                p = pin_xy(row, n);
                color("#d4af37") translate([p[0] - 0.32, p[1] - 0.32, Z_e - hdr_plastic - hdr_long]) cube([0.64, 0.64, hdr_plastic + hdr_long + t + 1.5]);
            }
        }
        for (u = esp_used) {
            p = pin_xy(u[1], u[2]);
            color(colored ? wire_col(u[3]) : "#444")
                translate([p[0] - dupont_w/2, p[1] - dupont_w/2, Z_e - hdr_plastic - dupont_len]) cube([dupont_w, dupont_w, dupont_len]);
        }
    } else if (wires_stub) {
        // 直焊：焊點（上）＋出線（下）
        for (u = esp_used) {
            p = pin_xy(u[1], u[2]);
            color("#c0c0c0") translate([p[0], p[1], Z_p]) cylinder(d1 = 1.5, d2 = 0.6, h = 0.9, $fn = 12);
        }
    }
}

// ---------------- 感測器小板（直立；感測面朝 -Y 下端格柵；排針在下緣、長端朝 +Y） ----------------
// 由感測面看（排針在下）：左→右 依 sens_pins 順序（+X 為右）
function sens_pin_x(i) = sens_x + (i - (sens_np - 1)/2) * 2.54;
module sens_ref(colored = true, conn = sens_conn) {
    zp = Z_s + sens_pin_edge;
    difference() {
        color(colored ? sens_col : "#444") translate([sens_x - sens_w/2, y_sf, Z_s]) cube([sens_w, sens_t, sens_h]);
        if (sens_hole[2] > 0)
            translate([sens_x + sens_hole[0], y_sf - 1, Z_s + sens_hole[1]]) rotate([-90, 0, 0]) cylinder(d = sens_hole[2], h = sens_t + 2, $fn = 20);
    }
    // 感測晶片（感測面）
    color("#3a3a3a") translate([sens_x + sens_chip[0] - sens_chip_wh[0]/2, y_sf - sens_chip_wh[2], Z_s + sens_chip[1] - sens_chip_wh[1]/2])
        cube([sens_chip_wh[0], sens_chip_wh[2], sens_chip_wh[1]]);
    // 排針：塑膠座貼板背、長針朝 +Y；感測面側為短針＋焊點
    if (conn == "dupont") {
        color("#111") translate([sens_pin_x(0) - 1.27, y_sb, zp - 1.27]) cube([sens_np*2.54, hdr_plastic, 2.54]);
        for (i = [0 : sens_np - 1]) {
            color("#d4af37") translate([sens_pin_x(i) - 0.32, y_sf - hdr_short, zp - 0.32]) cube([0.64, hdr_short + sens_t + hdr_plastic + hdr_long, 0.64]);
            color(colored ? wire_col(sens_sig(sens_pins[i])) : "#444")
                translate([sens_pin_x(i) - dupont_w/2, y_sb + hdr_plastic, zp - dupont_w/2]) cube([dupont_w, dupont_len, dupont_w]);
        }
    } else {
        for (i = [0 : sens_np - 1])
            color("#c0c0c0") translate([sens_pin_x(i), y_sf - 0.6, zp]) rotate([-90, 0, 0]) cylinder(d1 = 1.6, d2 = 0.8, h = 0.6, $fn = 12);
    }
}

// ---------------- 杜邦線（示意＋走線檢查） ----------------
module poly_tube(pts, d) {
    for (i = [0 : len(pts) - 2]) hull() {
        translate(pts[i]) sphere(d = d, $fn = 10);
        translate(pts[i + 1]) sphere(d = d, $fn = 10);
    }
}
// 第 k 條線（esp_used 的順序）：C3 焊點/母頭 → 下到內底 → 穿雙層隔牆缺口 → 感測器母頭尾
function wire_pts(k) = let(
    u   = esp_used[k],
    p   = pin_xy(u[1], u[2]),
    i   = search([u[3]], [for (n = sens_pins) sens_sig(n)])[0],
    xs  = sens_pin_x(i),
    zw  = Z_f + wire_d/2 + 0.25,                                  // 沿內底走
    xw  = X_n + (k - (len(esp_used) - 1)/2) * (wire_d + 0.3),     // 在缺口內並排
    zs  = Z_s + sens_pin_edge,
    ys  = sens_conn == "dupont" ? y_sb + hdr_plastic + dupont_len : y_sb + 0.3,
    zt  = esp_hdr == "bottom" ? Z_e - hdr_plastic - dupont_len + 0.4 : Z_e - 0.4)
    [[p[0], p[1], zt], [p[0], p[1], zw + 1.6], [xw, p[1] - 1.4, zw], [xw, y_m0 + 0.2, zw], [xw, y_pa0 - 1.1, zw],
     [xs, ys + 2.0, max(zw, zs - 1.2)], [xs, ys + 0.8, zs], [xs, ys - 0.5, zs]];
module wires_ref(d = wire_d) {
    for (k = [0 : len(esp_used) - 1]) color(wire_col(esp_used[k][3])) poly_tube(wire_pts(k), d);
}

// USB-C 線（示意；壁掛圖用）：插頭模具外殼 12.35×6.5、往 +X 出殼後往下（-Y）沿牆走
module usb_cable_ref() {
    x0 = X_ue + esp_usb_over;
    color("#2a2a2a") translate([x0 + 0.3, Y_uc, Z_u]) rotate([0, 90, 0]) linear_extrude(18)
        offset(r = 1.6) offset(delta = -1.6) square([plug_body[1], plug_body[0]], center = true);
    color("#2a2a2a") poly_tube([[x0 + 18, Y_uc, Z_u], [x0 + 24, Y_uc, Z_u], [x0 + 28, Y_uc - 4, Z_u - 1], [x0 + 29, Y_uc - 12, Z_u - 3], [x0 + 29, -45, Z_u - 3]], 3.6);
}

// 天線區（陶瓷天線本體）外擴 m
module ant_zone(m = 0, z0 = -1, z1 = 100) {
    a0 = bxy([esp_ant_bx[1], esp_ant_by[1]]);
    translate([a0[0] - m, a0[1] - m, z0]) cube([esp_ant_by[1] - esp_ant_by[0] + 2*m, esp_ant_bx[1] - esp_ant_bx[0] + 2*m, z1 - z0]);
}

// 干涉檢查用全部參考件
module parts_all(wires = true) {
    esp_ref();
    sens_ref();
    if (wires) wires_ref();
}
