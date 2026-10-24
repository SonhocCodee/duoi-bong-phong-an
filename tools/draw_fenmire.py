#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Vẽ 2 sơ đồ VÙNG NAM FENMIRE bằng PIL:
- design/fenmire_so_do.png    : sơ đồ TỔNG THỂ vùng (các map nối đường đi,
                                cấp độ quái + điểm quest chính từng khu)
- design/fenmire_layout.png   : layout THÀNH Fenmire vẽ ĐÚNG lưới 220x160 ô
                                (cùng hệ toạ độ với design/fenmire_layout.md)

Số liệu khu trong layout (cột x hàng) nằm ở ZONES bên dưới — khi sửa bố cục
phải sửa cả design/fenmire_layout.md cho khớp.

Chạy: python3 tools/draw_fenmire.py
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

# palette giấy/sơ đồ (đầm lầy: rêu, bùn, teal đục, vàng đèn lồng làm accent)
BG = (196, 204, 178)
WATER = (94, 128, 108)
WATER_D = (70, 104, 86)
LAND = (150, 168, 118)
GRASS = (124, 152, 92)
MUD = (168, 142, 100)
PLANK = (178, 142, 94)
INK = (38, 44, 34)
ACCENT = (214, 152, 52)      # vàng đèn lồng
DANGER = (168, 62, 52)
CULT = (110, 84, 150)
PAPER = (238, 240, 226)

def box(draw, xy, fill, outline=INK, w=3, r=14):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=w)

def center_text(draw, cx, y, text, font, fill=INK):
    draw.text((cx, y), text, font=font, fill=fill, anchor="ma")

# ================================================================ SƠ ĐỒ VÙNG

NODES = [
    # key, tên hiển thị, dòng phụ 1, dòng phụ 2, (cx, cy), màu viền
    ("miregate", "MIREGATE", "Cổng Tường Nam — cửa khẩu", "từ Vùng Đông xuống • Lv 7", (1290, 190), INK),
    ("reedmere", "REEDMERE", "Làng Bãi Sậy — làng khởi vùng", "Lv 7 • hub đầu vùng ★Q1", (930, 400), INK),
    ("drownedwood", "DROWNEDWOOD", "Rừng Ngập Nước", "Lv 7–9 • rắn đầm, đỉa trâu", (430, 520), INK),
    ("venomfen", "VENOMFEN", "Đầm Độc", "Lv 9–10 • bóng độc, nấm độc ★Q3", (330, 820), DANGER),
    ("fevercamp", "FEVERCAMP", "Trại Tị Nạn Dịch Bệnh", "Lv 8 • vùng an toàn ★Q2", (1010, 760), CULT),
    ("blackmere", "BLACKMERE", "Hồ Đầm Lớn", "Lv 10–11 • dân chài, quái hồ ★Q4", (520, 1130), INK),
    ("temple", "SUNKEN TIDE TEMPLE", "Đền Chìm Triều — DUNGEON", "Lv 11–12 • puzzle triều ★Q5", (1150, 1100), CULT),
    ("fenmire", "FENMIRE (thành)", "Đường vào thành — CHƯA DỰNG", "Lv 12 • cao trào Phần 2 ★Q6", (1150, 1360), ACCENT),
]
EDGES = [
    ("miregate", "reedmere"), ("reedmere", "drownedwood"),
    ("drownedwood", "venomfen"), ("venomfen", "fevercamp"),
    ("venomfen", "blackmere"), ("fevercamp", "temple"),
    ("blackmere", "temple"), ("temple", "fenmire"),
]

def draw_region():
    Wd, Hd = 1800, 1560
    im = Image.new("RGB", (Wd, Hd), BG)
    d = ImageDraw.Draw(im)
    rnd = random.Random(7)
    # nền đầm: mảng nước đục hữu cơ + bãi cỏ/bùn
    for _ in range(46):
        cx, cy = rnd.uniform(0, Wd), rnd.uniform(120, Hd)
        rx, ry = rnd.uniform(60, 210), rnd.uniform(34, 100)
        col = rnd.choice((WATER, WATER_D, LAND, GRASS, MUD))
        d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)
    for _ in range(260):   # chấm sậy/bùn trang trí nền
        x, y = rnd.uniform(10, Wd - 10), rnd.uniform(130, Hd - 10)
        d.line([x, y, x + rnd.uniform(-2, 2), y - rnd.uniform(6, 13)], fill=(86, 116, 62), width=3)
    # hồ Blackmere lớn phía tây-nam
    d.ellipse([180, 980, 780, 1300], fill=WATER_D)
    d.ellipse([210, 1010, 750, 1270], fill=WATER)
    center_text(d, 330, 1000, "mặt hồ", F(22), (230, 238, 220))
    # đường đi: nét đứt nâu đất nối các node
    pos = {k: xy for k, *_rest, xy, _c in [(n[0], n[1], n[2], n[3], n[4], n[5]) for n in NODES]}
    pos = {n[0]: n[4] for n in NODES}
    for a, b in EDGES:
        (x0, y0), (x1, y1) = pos[a], pos[b]
        n = 42
        for i in range(n):
            t0, t1 = i / n, (i + 0.55) / n
            bend = math.sin(t0 * math.pi) * 26
            xa = x0 + (x1 - x0) * t0 + bend * 0.4
            ya = y0 + (y1 - y0) * t0 + bend
            xb = x0 + (x1 - x0) * t1 + math.sin(t1 * math.pi) * 26 * 0.4
            yb = y0 + (y1 - y0) * t1 + math.sin(t1 * math.pi) * 26
            d.line([xa, ya, xb, yb], fill=(120, 92, 54), width=7)
    # mũi tên hướng vào từ Vùng Đông: từ góc ĐÔNG-BẮC trỏ XUỐNG Miregate
    d.line([1745, 105, 1515, 158], fill=INK, width=8)
    d.polygon([(1492, 150), (1540, 152), (1518, 178)], fill=INK)
    d.text((1300, 74), "từ ALDENMERE (Vùng Đông) — Cổng Tường Nam mở cuối Phần 1",
           font=F(21, True), fill=INK, anchor="ma")
    # node boxes
    for key, name, sub1, sub2, (cx, cy), edge in NODES:
        bw, bh = 380, 118
        dashed = (key == "fenmire")
        box(d, [cx - bw // 2, cy - bh // 2, cx + bw // 2, cy + bh // 2],
            PAPER, outline=edge, w=5 if not dashed else 4)
        if dashed:   # gạch thêm nét đứt trong viền = "chưa dựng"
            for x in range(cx - bw // 2 + 14, cx + bw // 2 - 14, 26):
                d.line([x, cy - bh // 2 + 10, x + 13, cy - bh // 2 + 10], fill=edge, width=3)
        center_text(d, cx, cy - 46, name, F(27, True))
        center_text(d, cx, cy - 8, sub1, F(20))
        center_text(d, cx, cy + 22, sub2, F(19), (86, 70, 40))
    # tiêu đề + chú thích
    d.rectangle([0, 0, Wd, 64], fill=(52, 66, 48))
    d.text((36, 14), "VÙNG NAM — FENMIRE • SƠ ĐỒ TỔNG THỂ (Phần 2, Lv 7–12)",
           font=F(32, True), fill=(240, 244, 230))
    d.rectangle([24, Hd - 128, Wd - 24, Hd - 16], fill=PAPER, outline=INK, width=3)
    d.text((44, Hd - 112),
           "★Q1–Q6 = điểm quest chính (xem fenmire_so_do.md §3). Đường đứt nâu = đường bộ / đường ván qua đầm.",
           font=F(20), fill=INK)
    d.text((44, Hd - 76),
           "Tuyến chính: Miregate → Reedmere → Drownedwood → Venomfen → Fevercamp → Sunken Tide Temple → Fenmire.",
           font=F(20), fill=INK)
    d.text((44, Hd - 40),
           "Nhánh phụ: Venomfen → Blackmere (dân chài) → Temple. Thành Fenmire: BẢN THIẾT KẾ (fenmire_layout), chưa dựng.",
           font=F(20), fill=INK)
    im.save(os.path.join(DESIGN, "fenmire_so_do.png"))
    print("region:", im.size)

# ================================================================ LAYOUT THÀNH

GW, GH = 220, 160          # lưới thành (cột x hàng) — khớp fenmire_layout.md §1
SCALE = 6                  # px / ô
OX, OY = 90, 150           # gốc lưới trên canvas

ZONES = [
    # (c0, r0, c1, r1, màu, nhãn dòng 1, nhãn dòng 2)
    (64, 16, 155, 46, (196, 178, 120), "CHỢ NỔI + BẾN THUYỀN", "64–155 × 16–46"),
    (16, 52, 96, 104, (172, 186, 128), "DÂN CHÀI NHÀ SÀN — TÂY", "16–96 × 52–104"),
    (124, 52, 203, 104, (172, 186, 128), "DÂN CHÀI NHÀ SÀN — ĐÔNG", "124–203 × 52–104"),
    (16, 110, 76, 140, (186, 160, 110), "BÃI MUỐI + SƠ CHẾ CÁ", "16–76 × 110–140"),
    (144, 110, 203, 140, (176, 158, 196), "NHÀ THƯƠNG + KHO THUỐC", "144–203 × 110–140"),
    (84, 107, 135, 146, (150, 128, 178), "NỘI THÀNH THƯỢNG — ĐỀN GIÁO PHÁI", "84–135 × 107–146"),
]

def cell_rect(c0, r0, c1, r1):
    return [OX + c0 * SCALE, OY + r0 * SCALE, OX + (c1 + 1) * SCALE, OY + (r1 + 1) * SCALE]

def draw_city():
    Wd = OX * 2 + GW * SCALE + 330
    Hd = OY + GH * SCALE + 190
    im = Image.new("RGB", (Wd, Hd), (226, 228, 210))
    d = ImageDraw.Draw(im)
    # nước đầm quanh cù lao
    d.rectangle([OX - 26, OY - 26, OX + GW * SCALE + 26, OY + GH * SCALE + 26], fill=WATER)
    # cù lao (đất) cols 8-211, rows 8-151
    d.rectangle(cell_rect(8, 8, 211, 151), fill=(158, 172, 116))
    # tường ngoài dày 3 ô: vành cols/rows 10-12 & 207-209 / 147-149
    wall = (122, 106, 78)
    d.rectangle(cell_rect(10, 10, 209, 12), fill=wall)
    d.rectangle(cell_rect(10, 147, 209, 149), fill=wall)
    d.rectangle(cell_rect(10, 10, 12, 149), fill=wall)
    d.rectangle(cell_rect(207, 10, 209, 149), fill=wall)
    # hào nước trong tường (rows/cols 13) — vạch teal sát tường
    d.rectangle(cell_rect(13, 13, 206, 13), fill=WATER_D)
    d.rectangle(cell_rect(13, 146, 206, 146), fill=WATER_D)
    d.rectangle(cell_rect(13, 13, 13, 146), fill=WATER_D)
    d.rectangle(cell_rect(206, 13, 206, 146), fill=WATER_D)
    # Kênh Lớn (Grand Canal) cols 104-115, rows 13-104 + bến kết thúc rows 100-104
    d.rectangle(cell_rect(104, 13, 115, 104), fill=WATER)
    # đường ván 2 bờ kênh
    d.rectangle(cell_rect(97, 13, 103, 106), fill=PLANK)
    d.rectangle(cell_rect(116, 13, 123, 106), fill=PLANK)
    # các khu chức năng (chỉ tô nền — nhãn vẽ SAU CÙNG, có tấm lót, để không bị
    # hẻm ván / bể nước / khối đền đè lên chữ như bản soi vòng 1)
    for (c0, r0, c1, r1, col, l1, l2) in ZONES:
        d.rectangle(cell_rect(c0, r0, c1, r1), fill=col, outline=INK, width=2)
    # bể chợ nổi trong khu chợ: nước + sạp bè
    d.rectangle(cell_rect(76, 22, 143, 40), fill=WATER)
    rnd = random.Random(3)
    for _ in range(14):
        sx = rnd.uniform(79, 136); sy = rnd.uniform(24, 37)
        d.rectangle(cell_rect(int(sx), int(sy), int(sx) + 4, int(sy) + 2),
                    fill=(196, 120, 70), outline=INK, width=1)
    center_text(d, OX + 110 * SCALE, OY + 20.5 * SCALE, "bể chợ nổi — sạp trên bè", F(16), INK)
    # hẻm ván trong 2 khu dân chài (đường plank mảnh)
    for r in (64, 78, 92):
        d.rectangle(cell_rect(16, r, 96, r + 1), fill=PLANK)
        d.rectangle(cell_rect(124, r, 203, r + 1), fill=PLANK)
    for c in (36, 60, 84):
        d.rectangle(cell_rect(c, 52, c + 1, 104), fill=PLANK)
    for c in (140, 164, 188):
        d.rectangle(cell_rect(c, 52, c + 1, 104), fill=PLANK)
    # dải nước dưới nhà sàn ở nam 2 khu dân chài (nhà sàn trên mặt nước)
    d.rectangle(cell_rect(16, 97, 96, 104), fill=WATER)
    d.rectangle(cell_rect(124, 97, 203, 104), fill=WATER)
    # Đền giáo phái (trong nội thành thượng): khối đền chính + bể triều
    d.rectangle(cell_rect(92, 116, 127, 138), fill=(96, 74, 128), outline=INK, width=3)
    center_text(d, OX + 110 * SCALE, OY + 124 * SCALE, "ĐỀN TRIỀU CHÌM", F(19, True), (240, 238, 250))
    center_text(d, OX + 110 * SCALE, OY + 131 * SCALE, "(nội thành)", F(15), (240, 238, 250))
    d.rectangle(cell_rect(100, 141, 119, 144), fill=WATER_D)
    # tường trong bao nội thành thượng (rows 107-108, cols 84-135; 2 bên hông)
    d.rectangle(cell_rect(84, 107, 135, 108), fill=wall)
    d.rectangle(cell_rect(84, 107, 85, 146), fill=wall)
    d.rectangle(cell_rect(134, 107, 135, 146), fill=wall)
    # CỔNG BẮC (cols 104-115, rows 10-12): hở tường + cầu đường bộ qua hào ngoài
    d.rectangle(cell_rect(104, 10, 115, 12), fill=(240, 236, 210))
    d.rectangle(cell_rect(104, 0, 115, 9), fill=PLANK)
    center_text(d, OX + 110 * SCALE, OY - 62, "▲ CỔNG BẮC (104–115) + cầu cạn từ đường Fenmire", F(19, True))
    # cổng đền (cols 104-115 ở tường trong rows 107-108)
    d.rectangle(cell_rect(104, 107, 115, 108), fill=(240, 236, 210))
    # ---- NHÃN KHU (vẽ cuối, có tấm lót giấy để chữ không bị hình đè) ----
    def zone_label(cx_cell, cy_cell, l1, l2=None, paper=(238, 240, 226)):
        cx = OX + cx_cell * SCALE
        cy = OY + cy_cell * SCALE
        f1, f2 = F(19, True), F(16)
        w1 = d.textlength(l1, font=f1)
        w2 = d.textlength(l2, font=f2) if l2 else 0
        hw = max(w1, w2) / 2 + 12
        hh = 34 if l2 else 20
        d.rectangle([cx - hw, cy - hh, cx + hw, cy + hh], fill=paper, outline=INK, width=1)
        if l2:
            center_text(d, cx, cy - 24, l1, f1)
            center_text(d, cx, cy + 6, l2, f2, (70, 62, 44))
        else:
            center_text(d, cx, cy - 11, l1, f1)
    zone_label(110, 43.5, "CHỢ NỔI + BẾN THUYỀN", "64–155 × 16–46")
    zone_label(56, 72, "DÂN CHÀI NHÀ SÀN — TÂY", "16–96 × 52–104")
    zone_label(164, 72, "DÂN CHÀI NHÀ SÀN — ĐÔNG", "124–203 × 52–104")
    zone_label(46, 125, "BÃI MUỐI + SƠ CHẾ CÁ", "16–76 × 110–140")
    zone_label(174, 120, "NHÀ THƯƠNG + KHO THUỐC", "144–203 × 110–140")
    zone_label(110, 111.5, "NỘI THÀNH THƯỢNG — ĐỀN GIÁO PHÁI", None)
    # điểm portal / spawn / quest (sao vàng)
    def star(c, r, label, dx=14, dy=-8):
        x, y = OX + c * SCALE + 3, OY + r * SCALE + 3
        d.polygon([(x, y - 11), (x + 3, y - 3), (x + 11, y - 3), (x + 5, y + 2),
                   (x + 7, y + 10), (x, y + 5), (x - 7, y + 10), (x - 5, y + 2),
                   (x - 11, y - 3), (x - 3, y - 3)], fill=ACCENT, outline=INK)
        d.text((x + dx, y + dy), label, font=F(17, True), fill=INK)
    star(110, 14, "P1 Spawn từ cổng Bắc")
    star(66, 18, "★ Bảng Nhiệm Vụ", dx=14, dy=-30)
    star(196, 136, "P2 Cống Ngập", dx=-138, dy=-6)
    star(110, 105, "P3 Cổng đền (gate theo quest)", dx=20, dy=-26)
    star(15, 58, "P4 Bến phà → Blackmere", dx=14, dy=-8)
    # lưới mờ 10 ô + nhãn toạ độ
    for c in range(0, GW + 1, 20):
        d.line([OX + c * SCALE, OY, OX + c * SCALE, OY + GH * SCALE], fill=(170, 176, 150), width=1)
        d.text((OX + c * SCALE, OY - 22), str(c), font=F(15), fill=INK, anchor="ma")
    for r in range(0, GH + 1, 20):
        d.line([OX, OY + r * SCALE, OX + GW * SCALE, OY + r * SCALE], fill=(170, 176, 150), width=1)
        d.text((OX - 34, OY + r * SCALE), str(r), font=F(15), fill=INK, anchor="ma")
    # khung map
    d.rectangle([OX, OY, OX + GW * SCALE, OY + GH * SCALE], outline=INK, width=3)
    # tiêu đề + chú thích phải
    d.rectangle([0, 0, Wd, 64], fill=(52, 66, 48))
    d.text((36, 14), "THÀNH FENMIRE — LAYOUT 220×160 Ô (bản chờ duyệt, CHƯA dựng scene)",
           font=F(30, True), fill=(240, 244, 230))
    lx = OX + GW * SCALE + 56
    d.text((lx, OY + 4), "CHÚ THÍCH", font=F(22, True), fill=INK)
    notes = [
        "Mỗi ô = 64px. Toàn thành",
        "220×160 ô = 14.080×10.240px.",
        "",
        "Tường gỗ–đá dày 3 ô (nâu)",
        "+ hào nước sát trong tường.",
        "Kênh Lớn 104–115 chạy dọc",
        "thành; 2 bờ là đường ván.",
        "",
        "Nhà sàn dân chài đứng trên",
        "dải nước phía nam 2 khu dân",
        "(hàng 97–104): đi lại bằng",
        "hẻm ván (vạch nâu nhạt).",
        "",
        "Nội thành thượng ở GÒ CAO",
        "phía NAM (xa cổng Bắc nhất)",
        "— đền giáo phái chiếm vị",
        "trí cao nhất thành.",
        "",
        "★/P1–P4: portal, spawn,",
        "điểm quest — chi tiết ở",
        "fenmire_layout.md §7–§8.",
        "",
        "P2 = miệng Cống Ngập ở góc",
        "đông-nam khu nhà thương:",
        "đường điều tra lén xuống",
        "hầm chứa thuốc / vào đền.",
    ]
    for i, t in enumerate(notes):
        d.text((lx, OY + 44 + i * 27), t, font=F(18), fill=INK)
    d.text((36, Hd - 46),
           "Sơ đồ vẽ đúng lưới 220×160 của fenmire_layout.md. Nhà cửa khi dựng thật phải HỮU CƠ (lệch hàng, nhiều cỡ/màu) — lưới này chỉ là phân khu chức năng, như quy ước đã chốt ở Aldenmere.",
           font=F(18), fill=INK)
    im.save(os.path.join(DESIGN, "fenmire_layout.png"))
    print("city:", im.size)

if __name__ == "__main__":
    draw_region()
    draw_city()
