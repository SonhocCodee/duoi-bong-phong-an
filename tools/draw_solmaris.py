#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Vẽ 2 sơ đồ VÙNG TÂY SOLMARIS bằng PIL:
- design/solmaris_so_do.png   : tổng thể vùng, các map + tuyến quest Phần 3
- design/solmaris_layout.png  : layout THÀNH Solmaris đúng lưới 240x170 ô
                                (khớp design/solmaris_layout.md)

Chạy: python3 tools/draw_solmaris.py
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


BG = (232, 202, 142)
SAND = (226, 190, 128)
SAND_D = (198, 160, 96)
ROCK = (186, 118, 76)
WATER = (62, 174, 178)
WATER_D = (34, 132, 148)
INK = (54, 38, 24)
ACCENT = (196, 66, 52)
TRIBE = (66, 108, 104)
PAPER = (250, 242, 220)
DANGER = (154, 48, 36)


def box(draw, xy, fill, outline=INK, w=3, r=14):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=w)


def center_text(draw, cx, y, text, font, fill=INK):
    draw.text((cx, y), text, font=font, fill=fill, anchor="ma")


# ================================================================ SƠ ĐỒ VÙNG
NODES = [
    ("approach", "FENMIRE APPROACH", "cuối Phần 2 • cổng caravan mở", "khi có flag nam_giai_phong", (1510, 230), INK),
    ("westgate", "WESTGATE", "Cổng Tây vào vùng • cửa khẩu tường", "Lv 13 • bọ cạp cát ★Q1", (1080, 300), INK),
    ("oasis", "SUNWELL OASIS", "Thị trấn ốc đảo — hub khởi vùng", "Lv 13 • NPC sống ★Q1-Q2, liên minh", (760, 500), WATER_D),
    ("dunefield", "DUNEFIELD", "Biển cát + đụn + xương khô", "Lv 13–15 • farm/respawn ★Q1-Q2", (1080, 650), INK),
    ("dunehawk", "DUNEHAWK CAMP", "Trại Bộ Lạc Diều Cát (tên đề xuất)", "điều kiện: dọn lính đào ngũ ★Q3A", (420, 760), TRIBE),
    ("canyon", "REDROCK CANYON", "Hẻm núi đá đỏ + ĐẤU TRƯỜNG", "Lv 15–16 • boss Kassia Vane ★Q5", (1390, 820), DANGER),
    ("stonesong", "STONESONG CAMP", "Trại Bộ Lạc Đá Vang (tên đề xuất)", "điều kiện: bằng chứng lời thề ★Q3B", (760, 930), TRIBE),
    ("ruins", "BURIED SAND RUINS", "Tàn tích cổ — DUNGEON nhiều phòng", "Lv 16–17 • lời thề Vesskar ★Q3B", (420, 1110), ROCK),
    ("lair", "VESSKAR'S LAIR", "Hang rồng cát — đối mặt Vesskar", "Lv 17–18 • đánh / đàm phán ★Q6–Q7", (1010, 1180), DANGER),
    ("solmaris", "SOLMARIS (thành)", "Đường vào thành — CHƯA DỰNG", "chờ duyệt layout • xem solmaris_layout", (1450, 1240), ACCENT),
]
EDGES = [
    ("approach", "westgate"), ("westgate", "oasis"), ("oasis", "dunefield"),
    ("dunefield", "dunehawk"), ("dunefield", "canyon"),
    ("canyon", "stonesong"), ("canyon", "ruins"),
    ("ruins", "lair"), ("lair", "solmaris"),
]


def draw_region():
    Wd, Hd = 1800, 1560
    im = Image.new("RGB", (Wd, Hd), BG)
    d = ImageDraw.Draw(im)
    rnd = random.Random(13)
    for _ in range(54):
        cx, cy = rnd.uniform(0, Wd), rnd.uniform(120, Hd)
        rx, ry = rnd.uniform(60, 220), rnd.uniform(28, 90)
        col = rnd.choice((SAND, SAND_D, (216, 176, 112), ROCK))
        d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)
    for _ in range(240):
        x, y = rnd.uniform(10, Wd - 10), rnd.uniform(130, Hd - 10)
        d.ellipse([x - 2, y - 1, x + 2, y + 1], fill=(176, 138, 82))
    # ốc đảo nhỏ cạnh node Oasis
    d.ellipse([560, 410, 900, 570], fill=WATER_D)
    d.ellipse([585, 428, 875, 552], fill=WATER)
    center_text(d, 730, 438, "Sunwell", F(21), (238, 255, 250))
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
            d.line([xa, ya, xb, yb], fill=(132, 92, 50), width=7)
    d.line([1740, 118, 1652, 178], fill=INK, width=8)
    d.polygon([(1632, 172), (1674, 176), (1652, 202)], fill=INK)
    d.text((1130, 74), "từ FENMIRE (Vùng Nam) — caravan mở cuối Phần 2",
           font=F(21, True), fill=INK, anchor="ma")
    for key, name, sub1, sub2, (cx, cy), edge in NODES:
        bw, bh = (430 if key in ("lair", "solmaris") else 390), 118
        dashed = (key == "solmaris")
        box(d, [cx - bw // 2, cy - bh // 2, cx + bw // 2, cy + bh // 2],
            PAPER, outline=edge, w=5 if not dashed else 4)
        if dashed:
            for x in range(cx - bw // 2 + 14, cx + bw // 2 - 14, 26):
                d.line([x, cy - bh // 2 + 10, x + 13, cy - bh // 2 + 10], fill=edge, width=3)
        center_text(d, cx, cy - 46, name, F(26, True))
        center_text(d, cx, cy - 8, sub1, F(19))
        center_text(d, cx, cy + 22, sub2, F(18), (104, 76, 42))
    d.rectangle([0, 0, Wd, 64], fill=(92, 58, 34))
    d.text((36, 14), "VÙNG TÂY — SOLMARIS • SƠ ĐỒ TỔNG THỂ (Phần 3, Lv 13–18)",
           font=F(32, True), fill=(255, 246, 220))
    d.rectangle([24, Hd - 128, Wd - 24, Hd - 16], fill=PAPER, outline=INK, width=3)
    d.text((44, Hd - 112),
           "★Q1–Q7 = tuyến chính (xem solmaris_so_do.md §3). Đường đứt nâu = đường caravan / đường cát.",
           font=F(20), fill=INK)
    d.text((44, Hd - 76),
           "Tuyến: Westgate → Sunwell Oasis → Dunefield → 2 trại bộ lạc → Redrock Canyon → Buried Sand Ruins → Vesskar's Lair.",
           font=F(20), fill=INK)
    d.text((44, Hd - 40),
           "Tên Dunehawk / Stonesong / Kassia Vane là ĐỀ XUẤT chờ user duyệt. Nội thành Solmaris chưa dựng.",
           font=F(20), fill=INK)
    im.save(os.path.join(DESIGN, "solmaris_so_do.png"))
    print("region:", im.size)


# ================================================================ LAYOUT THÀNH
GW, GH = 240, 170
SCALE = 6
OX, OY = 90, 150

ZONES = [
    (80, 18, 165, 45, (176, 118, 82), "PHỦ HỘI ĐỒNG LÍNH ĐÁNH THUÊ", "80–165 × 18–45"),
    (18, 20, 48, 48, (96, 164, 170), "THÁP NƯỚC + HẦM CHỨA", "18–48 × 20–48"),
    (35, 52, 96, 124, (226, 190, 110), "CHỢ PHIÊN LỚN (GRAND BAZAAR)", "35–96 × 52–124"),
    (104, 66, 139, 103, (94, 190, 196), "ỐC ĐẢO + ĐÀI PHUN TRUNG TÂM", "104–139 × 66–103"),
    (148, 55, 202, 112, (204, 164, 104), "KHU CARAVAN + KHO HÀNG", "148–202 × 55–112"),
    (25, 128, 96, 152, (216, 176, 126), "KHU NHÀ ĐẤT NUNG / DÂN CƯ", "25–96 × 128–152"),
    (106, 128, 178, 152, (188, 146, 96), "CHUỒNG LẠC ĐÀ + XƯỞNG DA", "106–178 × 128–152"),
    (15, 66, 30, 104, (150, 104, 150), "ĐỀN CỔNG PHONG ẤN", "15–30 × 66–104"),
]


def cell_rect(c0, r0, c1, r1):
    return [OX + c0 * SCALE, OY + r0 * SCALE, OX + (c1 + 1) * SCALE, OY + (r1 + 1) * SCALE]


def draw_city():
    Wd = OX * 2 + GW * SCALE + 330
    Hd = OY + GH * SCALE + 190
    im = Image.new("RGB", (Wd, Hd), (238, 224, 186))
    d = ImageDraw.Draw(im)
    # cát ngoài thành + khu bộ lạc ngoài tường phía đông
    d.rectangle(cell_rect(214, 48, 236, 122), fill=(232, 200, 132), outline=INK, width=2)
    center_text(d, OX + 225 * SCALE, OY + 58 * SCALE, "KHU BỘ LẠC", F(18, True))
    center_text(d, OX + 225 * SCALE, OY + 82 * SCALE, "NGOÀI TƯỜNG", F(18, True))
    center_text(d, OX + 225 * SCALE, OY + 104 * SCALE, "lều + lửa trại", F(15))
    # đất trong thành
    d.rectangle(cell_rect(8, 8, 211, 161), fill=(222, 188, 126))
    # tường sa thạch dày 3 ô
    wall = (166, 112, 66)
    d.rectangle(cell_rect(10, 10, 209, 12), fill=wall)
    d.rectangle(cell_rect(10, 159, 209, 161), fill=wall)
    d.rectangle(cell_rect(10, 10, 12, 161), fill=wall)
    d.rectangle(cell_rect(207, 10, 209, 161), fill=wall)
    # cổng Đông (hàng 78-91): hở tường + đường caravan ra khu bộ lạc
    d.rectangle(cell_rect(207, 78, 209, 91), fill=(250, 242, 220))
    d.rectangle(cell_rect(210, 78, 239, 91), fill=(198, 160, 96))
    # cổng Tây nhỏ hướng hang Vesskar (hàng 80-89 ở tường tây)
    d.rectangle(cell_rect(10, 80, 12, 89), fill=(250, 242, 220))
    # khu chức năng
    for (c0, r0, c1, r1, col, _l1, _l2) in ZONES:
        d.rectangle(cell_rect(c0, r0, c1, r1), fill=col, outline=INK, width=2)
    # ốc đảo trung tâm: hồ + đài phun
    d.ellipse(cell_rect(107, 70, 136, 99), fill=WATER)
    d.ellipse(cell_rect(116, 78, 127, 91), fill=(238, 228, 198), outline=INK, width=2)
    center_text(d, OX + 121.5 * SCALE, OY + 84.5 * SCALE, "ĐÀI PHUN", F(15, True))
    # đường chính hữu cơ: cổng Đông -> nam caravan -> bắc ốc đảo -> bắc chợ.
    # Cố ý vòng tránh hồ/đài phun trung tâm để không cắt qua mặt nước.
    road_cells = [(208, 84), (190, 96), (164, 108), (143, 106), (140, 84),
                  (140, 62), (104, 58), (70, 60), (35, 64)]
    pts = [(OX + x * SCALE, OY + y * SCALE) for x, y in road_cells]
    d.line(pts, fill=(176, 138, 84), width=22, joint="curve")
    d.line(pts, fill=(206, 170, 106), width=12, joint="curve")
    # sạp chợ: các ô cam xô lệch trong Grand Bazaar
    rnd = random.Random(4)
    for _ in range(18):
        sx = rnd.uniform(39, 88); sy = rnd.uniform(57, 116)
        d.rectangle(cell_rect(int(sx), int(sy), int(sx) + 4, int(sy) + 2),
                    fill=(196, 104, 62), outline=INK, width=1)
    # nhãn cổng vẽ SAU khu/đường để không bị các lớp sau phủ mất chữ
    center_text(d, OX + 181 * SCALE, OY + 70 * SCALE, "CỔNG ĐÔNG (hàng 78–91) → Fenmire", F(17, True))
    # nhãn khu có tấm lót giấy
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
            center_text(d, cx, cy + 6, l2, f2, (92, 66, 38))
        else:
            center_text(d, cx, cy - 11, l1, f1)
    zone_label(122, 31, "PHỦ HỘI ĐỒNG LÍNH ĐÁNH THUÊ", "80–165 × 18–45")
    zone_label(33, 34, "THÁP NƯỚC + HẦM CHỨA", "18–48 × 20–48")
    zone_label(65, 122, "CHỢ PHIÊN LỚN (GRAND BAZAAR)", "35–96 × 52–124")
    zone_label(121, 108, "ỐC ĐẢO + ĐÀI PHUN TRUNG TÂM", "104–139 × 66–103")
    zone_label(175, 104, "KHU CARAVAN + KHO HÀNG", "148–202 × 55–112")
    zone_label(60, 140, "KHU NHÀ ĐẤT NUNG / DÂN CƯ", "25–96 × 128–152")
    zone_label(142, 140, "CHUỒNG LẠC ĐÀ + XƯỞNG DA", "106–178 × 128–152")
    zone_label(22, 58, "ĐỀN CỔNG PHONG ẤN", None)

    def star(c, r, label, dx=14, dy=-8):
        x, y = OX + c * SCALE + 3, OY + r * SCALE + 3
        d.polygon([(x, y - 11), (x + 3, y - 3), (x + 11, y - 3), (x + 5, y + 2),
                   (x + 7, y + 10), (x, y + 5), (x - 7, y + 10), (x - 5, y + 2),
                   (x - 11, y - 3), (x - 3, y - 3)], fill=ACCENT, outline=INK)
        d.text((x + dx, y + dy), label, font=F(16, True), fill=INK)
    star(208, 84, "P1 Spawn từ cổng Đông", dx=-176, dy=-34)
    star(66, 56, "★ Bảng Nhiệm Vụ ở chợ", dx=14, dy=-28)
    star(110, 95, "P2 Đài phun (điểm hẹn liên minh)", dx=-150, dy=18)
    star(11, 84, "P3 Cổng Tây nhỏ → hang Vesskar", dx=16, dy=150)
    star(225, 84, "P4 Khu bộ lạc ngoài tường", dx=-176, dy=48)
    for c in range(0, GW + 1, 20):
        d.line([OX + c * SCALE, OY, OX + c * SCALE, OY + GH * SCALE], fill=(190, 172, 132), width=1)
        d.text((OX + c * SCALE, OY - 22), str(c), font=F(15), fill=INK, anchor="ma")
    for r in range(0, GH + 1, 20):
        d.line([OX, OY + r * SCALE, OX + GW * SCALE, OY + r * SCALE], fill=(190, 172, 132), width=1)
        d.text((OX - 34, OY + r * SCALE), str(r), font=F(15), fill=INK, anchor="ma")
    d.rectangle([OX, OY, OX + GW * SCALE, OY + GH * SCALE], outline=INK, width=3)
    d.rectangle([0, 0, Wd, 64], fill=(92, 58, 34))
    d.text((36, 14), "THÀNH SOLMARIS — LAYOUT 240×170 Ô (bản chờ duyệt, CHƯA dựng scene)",
           font=F(29, True), fill=(255, 246, 220))
    lx = OX + GW * SCALE + 56
    d.text((lx, OY + 4), "CHÚ THÍCH", font=F(22, True), fill=INK)
    notes = [
        "Mỗi ô = 64px. Toàn thành",
        "240×170 ô = 15.360×10.880px.",
        "",
        "Tường SA THẠCH dày 3 ô,",
        "không tháp đá xám như Đông,",
        "không hào nước như Fenmire.",
        "",
        "Trung tâm là ỐC ĐẢO THẬT",
        "+ đài phun — nước là quyền",
        "lực: ai giữ nước, người đó",
        "cai trị chợ và caravan.",
        "",
        "Chợ phiên lớn ở tây-trung,",
        "phủ hội đồng ở gò bắc, khu",
        "bộ lạc NẰM NGOÀI tường đông",
        "— bố cục tự kể chuyện phân",
        "biệt trong/ngoài thành.",
        "",
        "★/P1–P4: portal, spawn,",
        "điểm quest — chi tiết ở",
        "solmaris_layout.md.",
    ]
    for i, t in enumerate(notes):
        d.text((lx, OY + 44 + i * 27), t, font=F(18), fill=INK)
    d.text((36, Hd - 46),
           "Sơ đồ vẽ đúng lưới 240×170 của solmaris_layout.md. Nhà cửa khi dựng thật phải HỮU CƠ (lệch hàng, nhiều cỡ/màu mái) — lưới này chỉ là phân khu chức năng.",
           font=F(18), fill=INK)
    im.save(os.path.join(DESIGN, "solmaris_layout.png"))
    print("city:", im.size)


if __name__ == "__main__":
    draw_region()
    draw_city()
