// =====================================================================
//  mod_wifi_ref.scad — 參考零件（只供預覽與干涉檢查，不會進任何 STL）— R2
//  ESP32-C3 SuperMini（PCB、USB-C、BOOT/RST、LED、陶瓷天線、已焊排針：bottom＝塑膠座在板下／top＝在板上）、
//  AHT20+BMP280（或 GY-SHT31-D）直立小板、IR LED（5 mm；或 3 mm＋列印轉接套）、VS1838B 接收頭、
//  IR 驅動洞洞板（NPN TO-92＋2 電阻）、感測線（4 條）、IR 線（5 條）、USB-C 線。
//  本檔不宣告頂層參數，全部引用 mod_wifi_case.scad 的全域值（被 include 時才解析）。
// =====================================================================

// 線色：3V3 紅、GND 黑、SDA 藍、SCL 黃、5V 橘、IR TX 綠、IR RX 紫
function wire_col(sig) = sig == "3V3" ? "#d62728" : sig == "GND" ? "#1e1e1e" : sig == "SDA" ? "#1f6fd1" :
                         sig == "SCL" ? "#f2c200" : sig == "5V" ? "#ff7f0e" : sig == "IRTX" ? "#2ca02c" : "#9467bd";

// ---------------- ESP32-C3 SuperMini ----------------
// 板座標 [bx, by]：bx 自 GPIO5 排板邊量起、by 自 USB 端板邊量起（元件面朝上、USB 朝上看）
// t＝PCB 厚（檢查時可代入 0.8／1.6）、hdr_len＝板下排針總長（塑膠座＋針尾）
module esp_ref(colored = true, t = esp_pcb_t, hdr_len = hdr_plastic + hdr_tail, over = esp_usb_over) {
    zp = Z_e + t;
    // PCB（四角 R0.5）
    color(colored ? "#1d4f9c" : "#444") translate([0, 0, Z_e]) linear_extrude(t)
        offset(r = 0.5) offset(delta = -0.5) translate([X_ae, y_pcb0]) square([esp_l, esp_w]);
    // USB-C 母座（凸出 USB 端板邊 over）
    color("#c9ccd1") translate([X_ue + over, bxy([esp_usb_bx, 0])[1], zp + esp_usb_h/2]) rotate([0, -90, 0])
        linear_extrude(esp_usb_len) hull() for (s = [-1, 1]) translate([0, s*(esp_usb_w/2 - esp_usb_h/2)]) circle(d = esp_usb_h, $fn = 24);
    // BOOT / RST
    for (b = [esp_boot_xy, esp_rst_xy]) {
        q = bxy(b);
        color("#e6e6e6") translate([q[0] - 1.5, q[1] - 2.0, zp]) cube([3.0, 4.0, 1.2]);
        color("#2b2b2b") translate([q[0], q[1], zp]) cylinder(d = 1.4, h = esp_btn_h, $fn = 16);
    }
    // LED：藍（GPIO8）、紅（電源）
    color("#2f6bff") translate(concat(bxy(esp_led8_xy), [zp]) - [0.5, 0.3, 0]) cube([1.0, 0.6, 0.45]);
    color("#ff3030") translate(concat(bxy(esp_ledp_xy), [zp]) - [0.3, 0.5, 0]) cube([0.6, 1.0, 0.45]);
    // 陶瓷天線
    a0 = bxy([esp_ant_bx[1], esp_ant_by[1]]);
    color("#b8452e") translate([a0[0], a0[1], zp]) cube([esp_ant_by[1] - esp_ant_by[0], esp_ant_bx[1] - esp_ant_bx[0], 1.1]);
    // ESP32-C3、晶振、LDO（示意）
    c = bxy([9.6, 14.6]);
    color("#262626") translate([c[0], c[1], zp]) rotate(45) translate([-2.5, -2.5, 0]) cube([5, 5, 0.85]);
    x = bxy([3.2, 17.6]);
    color("#bcbcbc") translate([x[0] - 1.25, x[1] - 1.6, zp]) cube([2.5, 3.2, 0.8]);
    r = bxy([14.6, 15.4]);
    color("#303030") translate([r[0] - 1.5, r[1] - 1.45, zp]) cube([3.0, 2.9, 1.1]);
    // 排針（2×8）
    for (row = [-1, 1]) {
        p1 = pin_xy(row, 1); p8 = pin_xy(row, 8);
        if (esp_hdr == "bottom") {
            color("#111") translate([p8[0] - 1.27, p1[1] - 1.27, Z_e - hdr_plastic]) cube([p1[0] - p8[0] + 2.54, 2.54, hdr_plastic]);
            for (n = [1 : 8]) {
                p = pin_xy(row, n);
                color("#d4af37") translate([p[0] - 0.32, p[1] - 0.32, Z_e - hdr_len]) cube([0.64, 0.64, hdr_len + t]);
                color("#c0c0c0") translate([p[0], p[1], zp]) cylinder(d1 = 1.6, d2 = 0.64, h = hdr_top_h, $fn = 12);   // 板上焊點
            }
        } else if (esp_hdr == "top") {
            color("#111") translate([p8[0] - 1.27, p1[1] - 1.27, zp]) cube([p1[0] - p8[0] + 2.54, 2.54, hdr_plastic]);
            for (n = [1 : 8]) {
                p = pin_xy(row, n);
                color("#d4af37") translate([p[0] - 0.32, p[1] - 0.32, Z_e - 1.5]) cube([0.64, 0.64, 1.5 + t + hdr_plastic + hdr_up]);
            }
        } else for (n = [1 : 8]) {
            p = pin_xy(row, n);
            color("#d9b54a") translate([p[0], p[1], Z_e - 0.02]) difference() {
                cylinder(d = 1.6, h = t + 0.06, $fn = 16);
                translate([0, 0, -1]) cylinder(d = 1.0, h = t + 2, $fn = 12);
            }
        }
    }
}

// ---------------- 感測器小板（直立；感測面朝 -Y 下端格柵；4 孔在下緣） ----------------
function sens_pin_x(i) = sens_x + (i - (sens_np - 1)/2) * 2.54;
// w／h／t 可代入公差極值做檢查
module sens_ref(colored = true, conn = sens_conn, w = sens_w, h = sens_h, t = sens_t) {
    zp = Z_s + sens_pin_edge;
    difference() {
        color(colored ? sens_col : "#444") translate([sens_x - w/2, y_sf, Z_s]) cube([w, t, h]);
        if (sens_hole[2] > 0)
            translate([sens_x + sens_hole[0], y_sf - 1, Z_s + sens_hole[1]]) rotate([-90, 0, 0]) cylinder(d = sens_hole[2], h = t + 2, $fn = 20);
        for (i = [0 : sens_np - 1]) translate([sens_pin_x(i), y_sf - 1, zp]) rotate([-90, 0, 0]) cylinder(d = 1.0, h = t + 2, $fn = 12);
    }
    // 晶片（感測面）：[x 偏移, 中心距下緣, 寬, 高, 厚, 名]
    for (c = sens_chips)
        color(c[5] == "BMP280" ? "#b9bcc2" : "#e8e4d8") translate([sens_x + c[0] - c[2]/2, y_sf - c[4], Z_s + c[1] - c[3]/2]) cube([c[2], c[4], c[3]]);
    if (conn == "dupont") {
        color("#111") translate([sens_pin_x(0) - 1.27, y_sf + t, zp - 1.27]) cube([sens_np*2.54, hdr_plastic, 2.54]);
        for (i = [0 : sens_np - 1]) {
            color("#d4af37") translate([sens_pin_x(i) - 0.32, y_sf - hdr_short, zp - 0.32]) cube([0.64, hdr_short + t + hdr_plastic + 6.0, 0.64]);
            color(colored ? wire_col(sens_sig(sens_pins[i])) : "#444")
                translate([sens_pin_x(i) - dupont_w/2, y_sf + t + hdr_plastic, zp - dupont_w/2]) cube([dupont_w, dupont_len, dupont_w]);
        }
    } else for (i = [0 : sens_np - 1])
        color("#c0c0c0") translate([sens_pin_x(i), y_sf - 0.6, zp]) rotate([-90, 0, 0]) cylinder(d1 = 1.6, d2 = 0.8, h = 0.6, $fn = 12);
}

// ---------------- IR LED（5 mm；或 3 mm 裝在列印轉接套裡） ----------------
// LED 座標：原點＝5 mm LED 凸緣底面中心（P_led），+z 沿 LED 軸（往 +Y 傾 led_tilt）
module led_frame() translate(P_led) rotate([-led_tilt, 0, 0]) children();
module led5_body(len = led5_len, d = led5_d) {
    cylinder(d = led5_fl_d, h = led5_fl_h, $fn = 32);
    cylinder(d = d, h = len - d/2, $fn = 32);
    translate([0, 0, len - d/2]) sphere(d = d, $fn = 32);
}
module led3_body() {
    cylinder(d = led3_fl_d, h = led3_fl_h, $fn = 24);
    cylinder(d = led3_d, h = led3_len - led3_d/2, $fn = 24);
    translate([0, 0, led3_len - led3_d/2]) sphere(d = led3_d, $fn = 24);
}
// leads＝true：腳線（沿軸往下到殼底，再彎往洞洞板，僅示意）
module ir_led_ref(kind = ir_led_ref_kind, len = led5_len, leads = true, colored = true) {
    led_frame() {
        if (kind == 5) color(colored ? "#5a5a66" : "#444") led5_body(len, led5_d - 0.1);   // 參考件 Ø4.9（實物 5.0 由卡扣環夾持＝接觸）
        else {
            color(COL_BODY) led_sleeve();
            color(colored ? "#5a5a66" : "#444") translate([0, 0, sl_step]) led3_body();
        }
    }
    if (leads) color("#c8c8c8") for (s = [-1, 1]) {
        p0 = P_led + [s*1.27, 0, 0];
        drop = (P_led[2] - (Z_f + 1.2)) / cos(led_tilt);
        p1 = p0 + drop*[0, -sin(led_tilt), -cos(led_tilt)];
        poly_tube([p0 + [0, 0, 0.2], p1, [p1[0], p1[1] - 2.0, Z_f + 0.7]], 0.5);
    }
}
// 發射錐（示意／檢查）：自 LED 頂點起，半角 ang，長 len
module led_cone(ang = led_half_angle, len = 30, apex_len = led5_len_min) {
    led_frame() translate([0, 0, apex_len]) cylinder(r1 = led5_d/2, r2 = led5_d/2 + len*tan(ang), h = len, $fn = 48);
}

// ---------------- VS1838B 接收頭（透鏡朝 +Z；腳往 -Y 出、彎 90° 往下） ----------------
module rx_ref(colored = true, b = rx_body) {
    z0 = rx_z0;
    color(colored ? "#2a2a2a" : "#444") translate([rx_x - b[0]/2, rx_y - b[1]/2, z0]) cube([b[0], b[1], b[2] - 1.0]);
    color(colored ? "#3c3c46" : "#444") translate([rx_x, rx_y, z0 + b[2] - 1.0]) scale([1, 1, 2.0/(min(b[0], b[1]) - 1.0)]) sphere(d = min(b[0], b[1]) - 1.0, $fn = 32);   // 圓頂高 1.0
    color("#c8c8c8") for (i = [-1 : 1]) {
        x = rx_x + i*2.54;
        poly_tube([[x, rx_y - b[1]/2 + 0.2, z0 + 1.0], [x, rx_y - b[1]/2 - 1.2, z0 + 1.0], [x, rx_y - b[1]/2 - 1.2, Z_f + 1.0]], 0.5);
    }
}

// ---------------- IR 驅動洞洞板（直立在兩側導槽；元件面朝 -Y） ----------------
module pcb_ir_ref(colored = true, w = pcb_ir[0], h = pcb_ir[1], t = 1.6) {
    yb = y_pv - t/2;
    color(colored ? "#c9a46a" : "#444") difference() {
        translate([pcb_x - w/2, yb, Z_f]) cube([w, t, h]);
        for (i = [-3 : 3], j = [0 : 4]) translate([pcb_x + i*2.54, yb - 1, Z_f + 2.5 + j*2.54]) rotate([-90, 0, 0]) cylinder(d = 1.0, h = t + 2, $fn = 8);
    }
    // NPN TO-92（直立，本體 4.8×4.0×3.7，平面朝 -Y）
    color(colored ? "#1b1b1b" : "#444") translate([pcb_x - 5.6, yb - 3.7, Z_f + 6.0]) intersection() {
        translate([2.4, 3.7, 0]) cylinder(d = 4.8, h = 4.8, $fn = 24);
        translate([0, 0, 0]) cube([4.8, 3.7, 4.8]);
    }
    // 電阻 ×2（臥式，Ø2.3×6.3）
    for (k = [0, 1]) color(colored ? (k == 0 ? "#d8b38a" : "#9ec3e6") : "#444")
        translate([pcb_x + 0.4, yb - 1.3, Z_f + 4.0 + k*5.5]) rotate([0, 90, 0]) cylinder(d = 2.3, h = 6.3, $fn = 16);   // 元件放中間（離左右板邊 ≥3，避開導槽唇）
}

// ---------------- 線（示意＋走線檢查） ----------------
module poly_tube(pts, d) {
    for (i = [0 : len(pts) - 2]) hull() {
        translate(pts[i]) sphere(d = d, $fn = 10);
        translate(pts[i + 1]) sphere(d = d, $fn = 10);
    }
}
// 焊點高度（C3 端）：bottom＝針尾、塑膠座下 2 mm；top＝板上排針頂下 1 mm；none＝板底焊盤下
function esp_wire_z() = esp_hdr == "bottom" ? Z_e - hdr_plastic - 2.0 : esp_hdr == "top" ? Z_p + hdr_plastic + hdr_up - 1.0 : Z_e - 0.4;
// 感測線 k（sens_wires）：C3 焊點 → 下到內底 → 穿雙層隔牆缺口 → 感測板背面焊孔
function wire_pts(k) = let(
    u   = sens_wires[k],
    p   = pin_xy(u[1], u[2]),
    i   = search([u[3]], [for (n = sens_pins) sens_sig(n)])[0],
    xs  = sens_pin_x(i),
    zw  = Z_f + wire_d/2 + 0.25,
    xw  = X_n + (k - (len(sens_wires) - 1)/2) * (wire_d + 0.3),
    zs  = Z_s + sens_pin_edge,
    zl  = floor_s + wire_d/2 + 0.25,
    ys  = sens_conn == "dupont" ? y_sf + sens_t + hdr_plastic + dupont_len : y_sf + sens_t + 0.3,
    zt  = esp_wire_z(),
    // 另一排（+Y 側）的線先貼內底往 -Y 走到板下中央，再往缺口
    pre = (u[1] < 0 && esp_hdr != "top") ? [[p[0] - 1.27, p[1], zw], [p[0] - 1.27, y_pcb0 + esp_w/2, zw]] : [],
    top = esp_hdr == "top" ? [[p[0], p[1], zt + 1.5], [p[0], y_pcb0 - gap_lo/2, zt + 1.5], [p[0], y_pcb0 - gap_lo/2, zw + 1.0]] : [[p[0], p[1], zw + 1.6]])
    concat([[p[0], p[1], zt]], top, pre,
           [[xw, min(p[1], y_pcb0 + 3.0) - 1.4, zw], [xw, y_m0 + 0.2, zw], [xw, y_pa0 - 1.1, zw], [xw, y_pa0 - 2.4, zl],
            [xs, ys + 2.0, max(zl, zs - 1.2)], [xs, ys + 0.8, zs], [xs, ys - 0.5, zs]]);
// IR 線 k（ir_wires）：C3 焊點 → 內底 → 板下穿到 +Y → MCU/IR 牆缺口 → 洞洞板下緣
function irw_pts(k) = let(
    u   = ir_wires[k],
    p   = pin_xy(u[1], u[2]),
    zw  = Z_f + wire_d/2 + 0.25,
    xw  = X_nI + (k - (len(ir_wires) - 1)/2) * (wire_d + 0.25),
    zt  = esp_wire_z(),
    xpb = pcb_x - 7.0 + k*3.2,
    // top 版：從板上排針頂往 -Y 越過板邊，走 -Y 側 1.8 繞線間隙下到內底，再從板下穿到 +Y
    top = esp_hdr == "top" ? [[p[0], p[1], zt + 1.5], [p[0], y_pcb0 - gap_lo/2, zt + 1.5], [p[0], y_pcb0 - gap_lo/2, zw + 1.0], [p[0] - 1.27, y_pcb0 + 2.0, zw]] : [[p[0], p[1], zw + 1.6]])
    concat([[p[0], p[1], zt]], top,
           [[p[0] - 1.27, p[1] + (u[1] > 0 ? 1.4 : -1.4), zw], [xw, y_m1 - 0.6, zw], [xw, y_i0 + 0.6, zw],
            [xpb, y_pv - 3.0, zw], [xpb, y_pv - 1.4, Z_f + 1.6]]);
module wires_ref(d = wire_d) {
    for (k = [0 : len(sens_wires) - 1]) color(wire_col(sens_wires[k][3])) poly_tube(wire_pts(k), d);
    for (k = [0 : len(ir_wires) - 1]) color(wire_col(ir_wires[k][3])) poly_tube(irw_pts(k), d);
}

// USB-C 線（示意；壁掛圖用）
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

// 頂壓條（列印件，組裝位置；預覽／干涉用）
module press_bars_asm(colored = true) {
    color(colored ? COL_BODY : "#444") { sens_press_asm(); pcb_press_asm(); }
}

// 干涉檢查用全部參考件（不含列印小件）
module parts_all(wires = true) {
    esp_ref();
    sens_ref();
    ir_led_ref(leads = wires);
    rx_ref();
    pcb_ir_ref();
    if (wires) wires_ref();
}
