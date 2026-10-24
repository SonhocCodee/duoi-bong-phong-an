#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Vẽ sơ đồ SIGILSPIRE (tháp trung tâm, endgame) bằng PIL:
- design/sigilspire_so_do.png : sơ đồ DỌC của tháp, từ Đất Chết Trung Tâm
                                ở dưới lên Đỉnh Tháp / Đài Sigilspire ở trên
                                (kèm tuyến quest thap_01..thap_04 + 3 ending)

Chạy: python3 tools/draw_sigilspire.py
"""
import os
import random
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESIGN = os.path.join(ROOT, "design")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONTB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def F(size, bold=False):
    return ImageFont.truetype(FONTB if bold else FONT, size)


BG = (186, 182, 198)
ASH = (142, 138, 154)
ASH_D = (74, 70, 84)
ASH_M = (108, 100, 128)
INK = (34, 32, 44)
PAPER = (246, 244, 250)
PURPLE = (104, 62, 148)
PURPLE_D = (62, 38, 92)
PURPLE_L = (196, 172, 226)
SEAL = (150, 96, 196)
DANGER = (120, 52, 60)
GREY_TX = (84, 80, 98)


def box(draw, xy, fill, outline=INK, w=3, r=14):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=w)


def center_text(draw, cx, y, text, font, fill=INK):
    draw.text((cx, y), text, font=font, fill=fill, anchor="ma")


# ================================================================ SƠ ĐỒ DỌC
# Thứ tự trong danh sách: từ ĐỈNH tháp xuống ĐẤT (để vẽ từ trên xuống dưới).
# Nội dung từng tầng: xem design/sigilspire_so_do.md §2.
FLOORS = [
    ("summit", "TẦNG 7 — ĐỈNH THÁP / ĐÀI SIGILSPIRE",
     "map: sigilspire_summit — sân thượng tròn + Bệ Phong Ấn",
     "Vua Trên Đỉnh — BOSS CUỐI 3 PHASE  ★Q4",
     "Chọn 1 trong 3 ENDING: Phong Ấn Mới / Phá Ấn / Thay Thế",
     860, PURPLE_D),
    ("f6", "TẦNG 6 — PHÒNG PHONG ẤN SỐNG",
     "map: sigilspire_f6 — phòng neo ấn của công chúa",
     "Công chúa Seraphine — VẬT PHONG ẤN SỐNG (twist)  ★Q3",
     "Không boss — đối thoại quyết định dài nhất game",
     980, DANGER),
    ("f5", "TẦNG 5 — TẦNG SỬ ẤN",
     "map: sigilspire_f5 — thư viện / vòng bia đá lịch sử phong ấn",
     "Không combat bắt buộc — NPC Người Ghi Ấn Cuối Cùng  ★Q2",
     "Sự thật: tên / tuổi / vai trò thật của công chúa + hợp đồng gốc",
     1060, PURPLE),
    ("f2", "TẦNG 3–4 — KÝ ỨC TÂY & BẮC",
     "map: sigilspire_f2 — sa mạc không gió / hành lang băng không lạnh",
     "Mini-boss: Hồi Âm Của Hiệp Sĩ Đen",
     "Địch: Bóng Ấn dạng Tây & Bắc (Lv 25)",
     1140, PURPLE),
    ("f1", "TẦNG 1–2 — KÝ ỨC ĐÔNG & NAM",
     "map: sigilspire_f1 — rừng nhà kính chết / đầm nước đen",
     "Mini-boss: Hồi Âm Của Morvain",
     "Địch: Bóng Ấn dạng Đông & Nam (Lv 25)",
     1220, PURPLE),
    ("base", "TẦNG 0 — CỔNG BỐN CHÌA",
     "map: sigilspire_base — sảnh chân tháp, 4 ổ khoá trụ",
     "Lính Gác Phong Ấn + Bóng Ấn — Vua lên tiếng qua ấn  ★Q1",
     "Tra đủ 4 Chìa Phong Ấn vào 4 ổ khoá mới leo lên được",
     1300, PURPLE_D),
]


def draw_floor(d, cx, cy, w, h, title, sub1, sub2, sub3, edge):
    box(d, [cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2],
        PAPER, outline=edge, w=5)
    center_text(d, cx, cy - 74, title, F(27, True), edge)
    center_text(d, cx, cy - 34, sub1, F(20))
    center_text(d, cx, cy + 2, sub2, F(20, True))
    center_text(d, cx, cy + 36, sub3, F(18), GREY_TX)


def draw_tower():
    Wd, Hd = 1800, 2240
    cx = Wd // 2
    im = Image.new("RGB", (Wd, Hd), BG)
    d = ImageDraw.Draw(im)
    rnd = random.Random(25)
    # nền xám tro: mảng tro loang + hạt tro / tàn ấn tím
    for _ in range(54):
        ex, ey = rnd.uniform(0, Wd), rnd.uniform(120, Hd)
        rx, ry = rnd.uniform(60, 220), rnd.uniform(28, 90)
        col = rnd.choice((ASH, (172, 168, 186), (198, 190, 214), PURPLE_L))
        d.ellipse([ex - rx, ey - ry, ex + rx, ey + ry], fill=col)
    for _ in range(240):
        x, y = rnd.uniform(10, Wd - 10), rnd.uniform(130, Hd - 10)
        d.ellipse([x - 2, y - 1, x + 2, y + 1], fill=(118, 112, 134))
    # thân tháp: khối thuôn xám tím sau các hộp tầng (rộng dần xuống chân)
    d.polygon([(cx - 400, 190), (cx + 400, 190),
               (cx + 660, 1690), (cx - 660, 1690)], fill=ASH_M)
    d.polygon([(cx - 400, 190), (cx + 400, 190),
               (cx + 660, 1690), (cx - 660, 1690)], outline=PURPLE_D)
    # vòng phong ấn lớn sau đỉnh tháp
    for r in (150, 118, 86):
        d.ellipse([cx - r, 268 - r, cx + r, 268 + r], outline=SEAL, width=4)
    # mũi tháp + tinh thể ấn trên đỉnh
    d.polygon([(cx - 70, 178), (cx + 70, 178), (cx, 84)], fill=ASH_D, outline=INK)
    d.polygon([(cx, 96), (cx + 26, 132), (cx, 168), (cx - 26, 132)],
              fill=SEAL, outline=PURPLE_D)
    # trục leo tháp ở mép trái thân tháp: đường lên + mũi tên
    ax = cx - 716
    d.line([ax, 1810, ax, 300], fill=PURPLE_D, width=7)
    d.polygon([(ax, 268), (ax - 14, 302), (ax + 14, 302)], fill=PURPLE_D)
    d.text((ax - 58, 1020), "LEO LÊN", font=F(20, True), fill=PURPLE_D, anchor="ma")
    # các tầng (vẽ từ đỉnh xuống)
    ys = [280, 540, 800, 1060, 1320, 1580]
    for (key, title, s1, s2, s3, w, edge), cy in zip(FLOORS, ys):
        # cầu nối giữa hai tầng
        if cy != ys[0]:
            d.rectangle([cx - 26, cy - 155, cx + 26, cy - 105], fill=ASH_D)
        draw_floor(d, cx, cy, w, 210, title, s1, s2, s3, edge)
    # ĐẤT CHẾT TRUNG TÂM — nền đất dưới chân tháp (hộp tối, chữ sáng)
    gy, gw, gh = 1900, 1480, 240
    d.rectangle([cx - gw // 2 - 60, gy + 40, cx + gw // 2 + 60, gy + gh // 2 + 30],
                fill=ASH_D)
    box(d, [cx - gw // 2, gy - gh // 2, cx + gw // 2, gy + gh // 2],
        ASH_D, outline=PURPLE_D, w=5)
    center_text(d, cx, gy - 88, "ĐẤT CHẾT TRUNG TÂM", F(29, True), (244, 240, 252))
    center_text(d, cx, gy - 46, "map: dat_chet — Trạm Gác Tro", F(21), (226, 220, 240))
    center_text(d, cx, gy - 10,
                "Vào từ Frostgard Approach — cổng tháp KHOÁ", F(20, True), (226, 220, 240))
    center_text(d, cx, gy + 26,
                "Cần đủ 4 Chìa Phong Ấn (flag: sigilspire_open)", F(20), PURPLE_L)
    center_text(d, cx, gy + 60,
                "Chìa Rễ Xanh (Đông) • Chìa Triều Ngọc (Nam) • Chìa Vảy Cát (Tây) • Chìa Sắt Băng (Bắc)",
                F(18), (200, 194, 214))
    # thanh tiêu đề
    d.rectangle([0, 0, Wd, 64], fill=PURPLE_D)
    d.text((36, 14), "SIGILSPIRE — THÁP TRUNG TÂM • SƠ ĐỒ DỌC (Đợt cuối / Endgame, Lv 25)",
           font=F(31, True), fill=(244, 240, 252))
    # hộp ghi chú cuối ảnh
    d.rectangle([24, Hd - 176, Wd - 24, Hd - 16], fill=PAPER, outline=INK, width=3)
    d.text((44, Hd - 160),
           "★Q1–Q4 = tuyến chính trong tháp. Thứ tự quest: thap_01..thap_04, rồi chọn 1 ending: thap_05a / thap_05b / thap_05c.",
           font=F(20), fill=INK)
    d.text((44, Hd - 124),
           "Đường đi: Frostgard Approach → Đất Chết Trung Tâm → Tầng 0 → leo lên Tầng 7. Không có quest phụ trong tháp.",
           font=F(20), fill=INK)
    d.text((44, Hd - 88),
           "Chi tiết tầng / quest / 3 ending: xem sigilspire_so_do.md (§2 bảng tầng, §4 cổng 4 chìa, §5–§6 quest + ending).",
           font=F(20), fill=INK)
    d.text((44, Hd - 52),
           "Tên boss cuối (Vua Trên Đỉnh) và mọi tên riêng trong ảnh là theo thiết kế đợt cuối.",
           font=F(20, True), fill=PURPLE_D)
    im.save(os.path.join(DESIGN, "sigilspire_so_do.png"))
    print("tower:", im.size)


if __name__ == "__main__":
    draw_tower()
