#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Vẽ 2 sơ đồ VÙNG BẮC FROSTGARD bằng PIL:
- design/frostgard_so_do.png   : tổng thể vùng, các map + tuyến quest Phần 4
- design/frostgard_layout.png  : layout THÀNH Frostgard đúng lưới 240x170 ô
                                (khớp design/frostgard_layout.md)

Chạy: python3 tools/draw_frostgard.py
"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESIGN = os.path.join(ROOT, "design")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONTB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def F(size, bold=False):
    return ImageFont.truetype(FONTB if bold else FONT, size)


BG = (216, 230, 242)
SNOW = (238, 242, 248)
SNOW_D = (198, 214, 232)
ICE = (168, 218, 220)
ICE_D = (69, 123, 157)
INK = (34, 44, 58)
ACCENT = (232, 106, 34)
PAPER = (250, 248, 240)
DANGER = (120, 52, 60)
PINE = (34, 66, 52)
STEEL = (110, 118, 132)


def box(draw, xy, fill, outline=INK, w=3, r=14):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=w)


def center_text(draw, cx, y, text, font, fill=INK):
    draw.text((cx, y), text, font=font, fill=fill, anchor="ma")


# ================================================================ SƠ ĐỒ VÙNG
NODES = [
    ("oasis", "SUNWELL OASIS", "Cuối Phần 3 • caravan đi Bắc mở", "khi có flag tay_giai_phong", (1510, 230), INK),
    ("northgate", "NORTHGATE", "Cổng Bắc vào vùng • đoạn tường khổng lồ", "Lv 19 • sói tuyết ★Q1", (1080, 300), INK),
    ("hearthwick", "HEARTHWICK", "Làng Lò Sưởi (tên đề xuất) — hub khởi vùng", "Lv 19 • NPC sống ★Q1-Q3, Q5, phụ", (760, 500), ACCENT),
    ("snowpine", "SNOWPINE FOREST", "Rừng thông tuyết dày đặc", "Lv 20 • sói / hồn ma / quái băng", (420, 700), PINE),
    ("lake", "FROZEN LAKE", "Hồ đóng băng — đi trên mặt băng", "Lv 20–21 • quái băng ★phụ", (760, 900), ICE_D),
    ("ghostwatch", "GHOSTWATCH POST", "Trạm gác ma bỏ hoang", "Lv 21–22 • hiệp sĩ đang nhớ ★Q3/Q5", (1120, 760), STEEL),
    ("crypt", "LEGION CRYPT", "Hầm mộ quân đoàn — DUNGEON nhiều phòng", "Lv 22 • bia 5 đội trưởng ★Q4", (1450, 960), DANGER),
    ("pass", "HOWLING PASS", "Đèo gió rít — hẻm núi đá", "Lv 22–23 • sói / hồn ma / elite", (420, 1060), INK),
    ("approach", "FROSTGARD APPROACH", "Tiền sảnh pháo đài — ngai băng + Vharok", "Lv 23–24 • boss Vharok ★Q6-Q7", (900, 1180), DANGER),
    ("frostgard", "FROSTGARD (thành)", "Nội thành — CHƯA DỰNG", "chờ duyệt layout • xem frostgard_layout", (1450, 1240), ACCENT),
]
EDGES = [
    ("oasis", "northgate"), ("northgate", "hearthwick"), ("hearthwick", "snowpine"),
    ("snowpine", "lake"), ("lake", "ghostwatch"), ("ghostwatch", "crypt"),
    ("hearthwick", "pass"), ("pass", "approach"), ("approach", "frostgard"),
]


def draw_region():
    Wd, Hd = 1800, 1560
    im = Image.new("RGB", (Wd, Hd), BG)
    d = ImageDraw.Draw(im)
    rnd = random.Random(24)
    for _ in range(54):
        cx, cy = rnd.uniform(0, Wd), rnd.uniform(120, Hd)
        rx, ry = rnd.uniform(60, 220), rnd.uniform(28, 90)
        col = rnd.choice((SNOW, SNOW_D, (226, 236, 246), ICE))
        d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)
    for _ in range(240):
        x, y = rnd.uniform(10, Wd - 10), rnd.uniform(130, Hd - 10)
        d.ellipse([x - 2, y - 1, x + 2, y + 1], fill=(170, 190, 214))
    # hồ băng nhỏ cạnh node Frozen Lake
    d.ellipse([560, 810, 900, 960], fill=ICE_D)
    d.ellipse([585, 826, 875, 944], fill=ICE)
    center_text(d, 730, 856, "Frozen Lake", F(21), (240, 252, 252))
    pos = {n[0]: n[4] for n in NODES}
    for a, b in EDGES:
        (x0, y0), (x1, y1) = pos[a], pos[b]
        n = 42
        for i in range(n):
            t0, t1 = i / n, (i + 0.55) / n
            bend = math.sin(t0 * math.pi) * 24
            xa = x0 + (x1 - x0) * t0 + bend * 0.35
            ya = y0 + (y1 - y0) * t0 + bend
            xb = x0 + (x1 - x0) * t1 + math.sin(t1 * math.pi) * 24 * 0.35
            yb = y0 + (y1 - y0) * t1 + math.sin(t1 * math.pi) * 24
            d.line([xa, ya, xb, yb], fill=(92, 110, 132), width=7)
    d.text((1130, 74), "từ SOLMARIS (Vùng Tây) — caravan mở cuối Phần 3",
           font=F(21, True), fill=INK, anchor="ma")
    for key, name, sub1, sub2, (cx, cy), edge in NODES:
        bw, bh = (430 if key in ("approach", "frostgard") else 390), 118
        dashed = (key == "frostgard")
        box(d, [cx - bw // 2, cy - bh // 2, cx + bw // 2, cy + bh // 2],
            PAPER, outline=edge, w=5 if not dashed else 4)
        if dashed:
            for x in range(cx - bw // 2 + 14, cx + bw // 2 - 14, 26):
                d.line([x, cy - bh // 2 + 10, x + 13, cy - bh // 2 + 10], fill=edge, width=3)
        center_text(d, cx, cy - 46, name, F(26, True))
        center_text(d, cx, cy - 8, sub1, F(19))
        center_text(d, cx, cy + 22, sub2, F(18), (72, 88, 108))
    d.rectangle([0, 0, Wd, 64], fill=(38, 54, 74))
    d.text((36, 14), "VÙNG BẮC — FROSTGARD • SƠ ĐỒ TỔNG THỂ (Phần 4, Lv 19–24)",
           font=F(32, True), fill=(240, 248, 255))
    d.rectangle([24, Hd - 128, Wd - 24, Hd - 16], fill=PAPER, outline=INK, width=3)
    d.text((44, Hd - 112),
           "★Q1–Q7 = tuyến chính (xem frostgard_so_do.md §3). Đường = đường caravan / đường tuyết.",
           font=F(20), fill=INK)
    d.text((44, Hd - 76),
           "Tuyến: Sunwell Oasis → Northgate → Hearthwick → Snowpine → Frozen Lake → Ghostwatch → Legion Crypt;",
           font=F(20), fill=INK)
    d.text((44, Hd - 40),
           "nhánh Hearthwick → Howling Pass → Frostgard Approach. Tên Valdemar / Vharok / Hearthwick là ĐỀ XUẤT chờ duyệt.",
           font=F(20), fill=INK)
    im.save(os.path.join(DESIGN, "frostgard_so_do.png"))
    print("region:", im.size)


# ================================================================ LAYOUT THÀNH
GW, GH = 240, 170
SCALE = 6
OX, OY = 90, 150

ZONES = [
    (92, 18, 148, 44, (150, 178, 205), "NGAI BĂNG + SẢNH VUA ĐÓNG BĂNG", "92–148 × 18–44"),
    (18, 20, 60, 50, (168, 158, 190), "NHÀ NGUYỆN KHÔNG CHUÔNG + THÁP CHUÔNG", "18–60 × 20–50"),
    (172, 20, 222, 50, (140, 152, 168), "DOANH TRẠI HIỆP SĨ BĂNG", "172–222 × 20–50"),
    (18, 62, 56, 112, (120, 128, 138), "NGHĨA TRANG QUÂN ĐOÀN + ĐÀI DANH SÁCH", "18–56 × 62–112"),
    (176, 62, 224, 108, (196, 140, 96), "XƯỞNG RÈN THÉP BĂNG + KHO THÉP", "176–224 × 62–108"),
    (26, 120, 108, 152, (206, 220, 234), "KHU DÂN CƯ ĐÓNG BĂNG + NHÀ TRỌ LÒ SƯỞI", "26–108 × 120–152"),
    (128, 124, 168, 152, (150, 110, 100), "ĐIỂM TẬP KẾT TRƯNG THU", "128–168 × 124–152"),
]


def cell_rect(c0, r0, c1, r1):
    return [OX + c0 * SCALE, OY + r0 * SCALE, OX + (c1 + 1) * SCALE, OY + (r1 + 1) * SCALE]


def draw_city():
    Wd = OX * 2 + GW * SCALE + 330
    Hd = OY + GH * SCALE + 190
    im = Image.new("RGB", (Wd, Hd), (226, 236, 246))
    d = ImageDraw.Draw(im)
    # đất trong thành
    d.rectangle(cell_rect(8, 8, 231, 161), fill=(232, 238, 246))
    # tường đá đen + băng dày 3 ô
    wall = (52, 56, 68)
    d.rectangle(cell_rect(10, 10, 229, 12), fill=wall)
    d.rectangle(cell_rect(10, 159, 229, 161), fill=wall)
    d.rectangle(cell_rect(10, 10, 12, 161), fill=wall)
    d.rectangle(cell_rect(227, 10, 229, 161), fill=wall)
    # cổng sắt Nam (cột 115-124 ở tường nam) + đường vào
    d.rectangle(cell_rect(115, 159, 124, 161), fill=(250, 248, 240))
    d.rectangle(cell_rect(115, 162, 124, 169), fill=(198, 214, 232))
    # cổng Bắc dự kiến đi đất chết / Sigilspire (đợt cuối) — vạch đứt
    d.rectangle(cell_rect(115, 10, 124, 12), fill=(168, 218, 220))
    # khu chức năng
    for (c0, r0, c1, r1, col, _l1, _l2) in ZONES:
        d.rectangle(cell_rect(c0, r0, c1, r1), fill=col, outline=INK, width=2)
    # Lò Lớn Trung Tâm: vòng lò + lửa ở tâm (khoảng 120, 85)
    d.ellipse(cell_rect(102, 70, 138, 100), fill=(120, 110, 104), outline=INK, width=2)
    d.ellipse(cell_rect(112, 78, 128, 94), fill=ACCENT)
    center_text(d, OX + 120 * SCALE, OY + 85 * SCALE, "LÒ LỚN", F(15, True), (255, 255, 255))
    # đường chính: cổng Nam -> Lò Lớn -> Ngai Băng; nhánh đông-tây ở hàng lò
    road_cells = [(120, 160), (120, 120), (120, 102), (120, 60), (120, 44)]
    pts = [(OX + x * SCALE, OY + y * SCALE) for x, y in road_cells]
    d.line(pts, fill=(168, 186, 206), width=22, joint="curve")
    d.line(pts, fill=(206, 220, 236), width=12, joint="curve")
    pts2 = [(OX + 56 * SCALE, OY + 85 * SCALE), (OX + 102 * SCALE, OY + 85 * SCALE)]
    d.line(pts2, fill=(206, 220, 236), width=10)
    pts3 = [(OX + 138 * SCALE, OY + 85 * SCALE), (OX + 176 * SCALE, OY + 85 * SCALE)]
    d.line(pts3, fill=(206, 220, 236), width=10)
    # nhà dân: các ô nhỏ xô lệch trong khu dân cư
    rnd = random.Random(4)
    for _ in range(14):
        sx = rnd.uniform(30, 100); sy = rnd.uniform(124, 146)
        d.rectangle(cell_rect(int(sx), int(sy), int(sx) + 4, int(sy) + 2),
                    fill=(150, 170, 195), outline=INK, width=1)
    # bia mộ trong nghĩa trang
    for _ in range(10):
        sx = rnd.uniform(22, 50); sy = rnd.uniform(66, 106)
        d.rectangle(cell_rect(int(sx), int(sy), int(sx) + 1, int(sy) + 2),
                    fill=(90, 96, 108), outline=INK, width=1)

    def zone_label(cx_cell, cy_cell, l1, l2=None):
        cx = OX + cx_cell * SCALE
        cy = OY + cy_cell * SCALE
        f1, f2 = F(18, True), F(15)
        w1 = d.textlength(l1, font=f1)
        w2 = d.textlength(l2, font=f2) if l2 else 0
        hw = max(w1, w2) / 2 + 12
        hh = 34 if l2 else 20
        d.rectangle([cx - hw, cy - hh, cx + hw, cy + hh], fill=PAPER, outline=INK, width=1)
        if l2:
            center_text(d, cx, cy - 24, l1, f1)
            center_text(d, cx, cy + 6, l2, f2, (72, 84, 100))
        else:
            center_text(d, cx, cy - 11, l1, f1)
    zone_label(120, 31, "NGAI BĂNG + SẢNH VUA ĐÓNG BĂNG", "92–148 × 18–44 • gò cao phía bắc")
    zone_label(39, 35, "NHÀ NGUYỆN KHÔNG CHUÔNG", "18–60 × 20–50 + tháp chuông lớn")
    zone_label(197, 35, "DOANH TRẠI HIỆP SĨ BĂNG", "172–222 × 20–50")
    zone_label(37, 87, "NGHĨA TRANG QUÂN ĐOÀN", "18–56 × 62–112 + đài danh sách tên")
    zone_label(120, 108, "LÒ LỚN TRUNG TÂM", "100–140 × 68–102")
    zone_label(200, 85, "XƯỞNG RÈN THÉP BĂNG + KHO THÉP", "176–224 × 62–108")
    zone_label(67, 136, "KHU DÂN CƯ ĐÓNG BĂNG + NHÀ TRỌ", "26–108 × 120–152")
    zone_label(148, 138, "ĐIỂM TẬP KẾT TRƯNG THU", "128–168 × 124–152 • góc tối cạnh cổng")

    def star(c, r, label, dx=14, dy=-8):
        x, y = OX + c * SCALE + 3, OY + r * SCALE + 3
        d.polygon([(x, y - 11), (x + 3, y - 3), (x + 11, y - 3), (x + 5, y + 2),
                   (x + 7, y + 10), (x, y + 5), (x - 7, y + 10), (x - 5, y + 2),
                   (x - 11, y - 3), (x - 3, y - 3)], fill=ACCENT, outline=INK)
        d.text((x + dx, y + dy), label, font=F(16, True), fill=INK)
    star(120, 160, "P1 Cổng sắt Nam ← Approach", dx=-150, dy=18)
    star(120, 85, "★ Lò Lớn (điểm hẹn / sưởi)", dx=16, dy=-30)
    star(120, 11, "P2 Cổng Bắc → đất chết / Sigilspire (đợt cuối)", dx=16, dy=-8)
    star(37, 87, "★ Đài Danh Sách Tên", dx=16, dy=40)
    for c in range(0, GW + 1, 20):
        d.line([OX + c * SCALE, OY, OX + c * SCALE, OY + GH * SCALE], fill=(196, 210, 226), width=1)
        d.text((OX + c * SCALE, OY - 22), str(c), font=F(15), fill=INK, anchor="ma")
    for r in range(0, GH + 1, 20):
        d.line([OX, OY + r * SCALE, OX + GW * SCALE, OY + r * SCALE], fill=(196, 210, 226), width=1)
        d.text((OX - 34, OY + r * SCALE), str(r), font=F(15), fill=INK, anchor="ma")
    d.rectangle([OX, OY, OX + GW * SCALE, OY + GH * SCALE], outline=INK, width=3)
    d.rectangle([0, 0, Wd, 64], fill=(38, 54, 74))
    d.text((36, 14), "THÀNH FROSTGARD — LAYOUT 240×170 Ô (bản chờ duyệt, CHƯA dựng scene)",
           font=F(29, True), fill=(240, 248, 255))
    lx = OX + GW * SCALE + 56
    d.text((lx, OY + 4), "CHÚ THÍCH", font=F(22, True), fill=INK)
    notes = [
        "Mỗi ô = 64px. Toàn thành",
        "240×170 ô = 15.360×10.880px.",
        "",
        "Tường ĐÁ ĐEN + BĂNG dày 3 ô,",
        "cổng SẮT ở phía Nam (vào từ",
        "Frostgard Approach).",
        "",
        "Trung tâm là LÒ LỚN — vừa",
        "sưởi cả thành vừa là lò rèn:",
        "lửa tắt = thành chết cóng.",
        "",
        "Ngai băng ở gò bắc, nhà",
        "nguyện KHÔNG chuông ở tây-",
        "bắc, nghĩa trang quân đoàn",
        "ở phía tây — thành tự kể",
        "chuyện Trụ Hàn bằng người.",
        "",
        "★/P1–P2: portal, spawn,",
        "điểm quest — chi tiết ở",
        "frostgard_layout.md.",
    ]
    for i, t in enumerate(notes):
        d.text((lx, OY + 44 + i * 27), t, font=F(18), fill=INK)
    d.text((36, Hd - 46),
           "Sơ đồ vẽ đúng lưới 240×170 của frostgard_layout.md. Nhà cửa khi dựng thật phải HỮU CƠ (lệch hàng, nhiều cỡ/màu mái) — lưới này chỉ là phân khu chức năng.",
           font=F(18), fill=INK)
    im.save(os.path.join(DESIGN, "frostgard_layout.png"))
    print("city:", im.size)


if __name__ == "__main__":
    draw_region()
    draw_city()
