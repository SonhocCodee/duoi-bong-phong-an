#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh tileset ĐẦM LẦY v1 cho VÙNG NAM FENMIRE — "Dưới Bóng Phong Ấn".

Kế thừa pipeline của tools/gen_tileset_v1.py (import trực tiếp module đó):
vẽ SUPERSAMPLE 4x bằng PIL (tile 64px -> canvas 256), texture hạt
WRAP-AROUND (vẽ lặp 9 offset) để ghép lưới không lộ mối nối, profile biên
lượn sóng dùng chung (mask_H / mask_V của v1) cho mọi tile chuyển tiếp,
downscale LANCZOS + unsharp nhẹ khi finish().

Khác v1 ở palette + texture: nước ĐỤC xanh rêu (không xanh trong như Đông),
bùn ướt bóng / bùn khô nứt mạng, cỏ đầm sẫm có sậy non, đường VÁN GỖ bắc
qua nước/bùn (đi lại trên ván là chữ ký giao thông của Fenmire).

Chạy: python3 tools/gen_swamp_tileset.py
Đầu ra:
- game/assets/tilesets/swamp_v1.png (lưới 5x4, tile 64px) + swamp_v1.tres
- game/assets/props/mangrove.png, reed_clump.png, glowshroom.png, swamp_log.png
- design/fenmire_mockup_v1.png (mockup ghép tileset + prop để soi chất đầm)
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_tileset_v1 import (  # noqa: E402  — kế thừa kỹ thuật v1
    SS, T, W, A, canvas, poly, ell, ell_pts, line, rrect, finish,
    soft_shadow, speck, blade, ell9, wrapped_blur, base_fill,
    mask_H, mask_V, dilate,
)
from PIL import Image, ImageDraw, ImageChops, ImageFilter  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TILE_DIR = os.path.join(ROOT, "game", "assets", "tilesets")
PROP_DIR = os.path.join(ROOT, "game", "assets", "props")
DESIGN_DIR = os.path.join(ROOT, "design")
for dd in (TILE_DIR, PROP_DIR, DESIGN_DIR):
    os.makedirs(dd, exist_ok=True)

# ---------------- palette đầm lầy (u ám, rêu, bùn, teal đục) ----------------
MWATER = (62, 92, 74)        # nước đục xanh rêu
MWATER_D = (40, 66, 54)      # nước sâu / bóng rễ
MWATER_L = (110, 148, 112)   # mảng sáng mặt nước
ALGAE = (88, 128, 66)        # váng rêu/tảo
FOAM_M = (196, 208, 178)     # bọt bẩn bờ nước
MUD = (104, 84, 58)          # bùn ướt
MUD_L = (132, 108, 76)
MUD_D = (76, 60, 40)
MUDDRY = (148, 122, 84)      # bùn khô
MUDDRY_D = (108, 86, 56)     # vết nứt bùn khô
SGRASS = (72, 112, 58)       # cỏ đầm
SGRASS_L = (104, 148, 76)
SGRASS_D = (50, 84, 44)
SGRASS_XD = (36, 62, 34)
REED = (126, 156, 84)        # sậy non
REED_D = (84, 112, 58)
CATTAIL = (110, 76, 44)      # bông sậy nâu (đuôi mèo)
PLANK = (128, 96, 62)        # ván gỗ ẩm
PLANK_L = (156, 122, 80)
PLANK_D = (94, 68, 42)
PLANK_XD = (64, 46, 28)
MOSS = (92, 140, 66)

# ============================================================ TILE ĐẦM LẦY

def murky_water_im(seed, phase=0.0, deep=False):
    """Nước đục xanh rêu: mảng rêu/tảo mềm + gợn ngắn đứt đoạn + váng nổi.
    phase 0/0.5 = 2 pha animation (gợn lệch nửa nhịp như water_a/water_b của v1)."""
    im = base_fill(MWATER_D if deep else MWATER)
    ov = canvas(T)
    ell9(ov, 20, 18, 26, 14, A(ALGAE, 52))
    ell9(ov, 50, 52, 24, 13, A(MWATER_D, 66))
    ell9(ov, 44, 12, 13, 8, A(MWATER_L, 34))
    ov = wrapped_blur(ov, 2.6 * SS)
    im.alpha_composite(ov)
    d = ImageDraw.Draw(im)
    rnd = random.Random(seed)
    for r_ in range(4):                       # gợn sóng NGẮN, đứt đoạn (nước đứng, không chảy)
        y0 = 10 + r_ * 15 + rnd.uniform(-2, 2)
        for seg in range(3):
            x0 = (seg * 22 + phase * 11 + rnd.uniform(-2, 2)) % 64
            pts = []
            for k in range(9):
                xx = x0 + k * 1.3
                pts.append((xx * SS, (y0 + 1.3 * math.sin(k / 8 * math.pi)) * SS))
            for dx in (-T, 0, T):
                d.line([(px + dx * SS, py) for px, py in pts],
                       fill=A(MWATER_L, 130), width=int(1.1 * SS))
    # váng tảo: đốm xanh rêu mềm, wrap để không lộ mối
    speck(im, seed + 6, 30, [A(ALGAE, 150), A(SGRASS_L, 110)], 0.5, 1.3)
    speck(im, seed + 8, 10, [A(FOAM_M, 120)], 0.4, 0.8)   # bọt bẩn lác đác
    if deep:
        speck(im, seed + 11, 16, [A(MWATER, 90)], 0.6, 1.6)
    return im

def wet_mud_im(seed):
    """Bùn ướt: nền nâu sẫm bóng nước, vệt sáng ẩm, sỏi chìm, dấu chân mờ."""
    im = base_fill(MUD)
    ov = canvas(T)
    ell9(ov, 22, 24, 25, 15, A(MUD_L, 62))
    ell9(ov, 48, 50, 22, 13, A(MUD_D, 60))
    ov = wrapped_blur(ov, 2.4 * SS)
    im.alpha_composite(ov)
    # vũng nước nông phản sáng trên mặt bùn
    ov2 = canvas(T)
    ell9(ov2, 16, 44, 11, 5.5, A(MWATER_L, 66))
    ell9(ov2, 52, 18, 9, 4.5, A(MWATER_L, 52))
    ov2 = wrapped_blur(ov2, 1.4 * SS)
    im.alpha_composite(ov2)
    speck(im, seed, 95, [A(MUD_L, 80), A(MUD_D, 84)], 0.3, 0.85)
    speck(im, seed + 3, 14, [A((150, 142, 124), 150)], 0.6, 1.4)   # sỏi chìm
    rnd = random.Random(seed + 5)                                  # dấu chân / vệt kéo mờ
    for _ in range(4):
        x, y = rnd.uniform(8, 56), rnd.uniform(8, 56)
        ell(im, x, y, rnd.uniform(2.4, 3.6), rnd.uniform(1.4, 2.0), fill=A(MUD_D, 95))
    return im

def dry_mud_im(seed):
    """Bùn khô nứt: nền sáng hơn bùn ướt, mạng nứt đa giác + mảng bong mép."""
    im = base_fill(MUDDRY)
    ov = canvas(T)
    ell9(ov, 24, 22, 24, 14, A((168, 140, 98), 60))
    ell9(ov, 48, 50, 22, 13, A(MUDDRY_D, 46))
    ov = wrapped_blur(ov, 2.4 * SS)
    im.alpha_composite(ov)
    rnd = random.Random(seed)
    # mạng nứt: các đoạn gãy nối nhau, wrap 9 offset để liền lưới
    offs = [(-T, -T), (0, -T), (T, -T), (-T, 0), (0, 0), (T, 0), (-T, T), (0, T), (T, T)]
    for _ in range(9):
        x, y = rnd.uniform(2, 62), rnd.uniform(2, 62)
        pts = [(x, y)]
        for _ in range(rnd.randint(2, 4)):
            x += rnd.uniform(-11, 11); y += rnd.uniform(-8, 8)
            pts.append((x, y))
        for dx, dy in offs:
            pp = [(px + dx, py + dy) for (px, py) in pts]
            for a, b in zip(pp, pp[1:]):
                line(im, a, b, A(MUDDRY_D, 215), 1.15)
    speck(im, seed + 4, 70, [A((172, 146, 104), 100), A(MUDDRY_D, 80)], 0.3, 0.8)
    for _ in range(5):   # mép mảng bong sáng
        x, y = rnd.uniform(6, 58), rnd.uniform(6, 58)
        ell(im, x, y, rnd.uniform(2.5, 4.5), rnd.uniform(1.4, 2.4), fill=A((186, 160, 114), 90))
    return im

def reed_blade(im, x, y, h, col, lean=0.0, w=1.2):
    blade(im, x, y, h, col, lean)

def swamp_grass_im(seed, reeds=False):
    """Cỏ đầm: sẫm và ẩm hơn cỏ Đông, túm cỏ cao kiểu lau sậy non, đốm bùn chân cỏ."""
    im = base_fill(SGRASS)
    ov = canvas(T)
    ell9(ov, 20, 18, 24, 15, A(SGRASS_L, 38))
    ell9(ov, 50, 52, 22, 14, A(SGRASS_D, 40))
    ell9(ov, 34, 40, 15, 9, A(MUD, 52))          # vệt bùn ngấm giữa cỏ
    ov = wrapped_blur(ov, 2.4 * SS)
    im.alpha_composite(ov)
    speck(im, seed, 52, [A(SGRASS_L, 36), A(SGRASS_D, 36)], 0.3, 0.65)
    # túm cỏ đầm (dùng lại kỹ thuật tuft của v1 nhưng palette đầm + cao hơn)
    rnd = random.Random(seed + 1)
    offs = [(-T, -T), (0, -T), (T, -T), (-T, 0), (0, 0), (T, 0), (-T, T), (0, T), (T, T)]
    n_tuft = 12 if reeds else 8
    for i in range(n_tuft):
        x, y = rnd.uniform(0, T), rnd.uniform(0, T)
        s = rnd.uniform(6.0, 10.5) if reeds else rnd.uniform(4.5, 8.0)
        for dx, dy in offs:
            for k in range(5):
                ddx = rnd.uniform(-2.4, 2.4)
                reed_blade(im, x + dx + ddx, y + dy, s * rnd.uniform(0.7, 1.25),
                           rnd.choice((SGRASS_D, REED_D, REED)), lean=ddx * 0.35)
        if reeds and i % 3 == 0:   # bông sậy đuôi mèo lác đác
            for dx, dy in offs:
                line(im, (x + dx, y + dy), (x + dx + 1.2, y + dy - s - 3.2), REED_D + (255,), 1.4)
                line(im, (x + dx + 1.2, y + dy - s - 3.2), (x + dx + 1.7, y + dy - s - 7.5),
                     CATTAIL + (255,), 2.3)
    return im

def plank_im(seed, mossy=False):
    """Đường ván gỗ: 4 ván ngang liền theo y (nhịp cầu ván), đinh 2 đầu,
    thớ gỗ ẩm + rêu ở khe nếu mossy. Ghép dọc liên tục không lộ mối."""
    im = base_fill(PLANK)
    # LƯU Ý KỸ THUẬT (rút từ v1): ImageDraw trên ảnh RGBA GHI ĐÈ alpha chứ không
    # hoà trộn — vẽ rectangle alpha 120 trực tiếp sẽ làm cả tấm ván bán trong
    # suốt (lộ nền cỏ/bùn bên dưới khi ghép). Vì vậy lớp tông ván phải vẽ lên
    # layer riêng rồi alpha_composite.
    ov = canvas(T)
    d = ImageDraw.Draw(ov)
    rnd = random.Random(seed)
    for r_ in range(4):
        y0 = r_ * 16
        tone = PLANK_L if r_ % 2 == 0 else PLANK
        jt = rnd.uniform(-8, 8)
        jtone = tuple(max(0, min(255, int(c + jt))) for c in tone)
        d.rectangle([0, y0 * SS, W, (y0 + 16) * SS], fill=jtone + (120,))
        d.rectangle([0, (y0 + 15.0) * SS, W, (y0 + 16) * SS], fill=PLANK_XD + (230,))  # khe ván
        d.rectangle([0, y0 * SS, W, (y0 + 1.1) * SS], fill=A(PLANK_L, 170))            # mép sáng
    im.alpha_composite(ov)
    d = ImageDraw.Draw(im)
    for r_ in range(4):
        y0 = r_ * 16
        for gx in range(5):   # thớ gỗ cong mờ
            gy = y0 + 3 + rnd.uniform(0, 10)
            pts = [((gx * 14 + k * 2.4) * SS, (gy + 0.8 * math.sin(k / 10 * math.pi)) * SS)
                   for k in range(11)]
            d.line(pts, fill=A(PLANK_D, 85), width=int(0.8 * SS))
        for nx in (5.5, 58.5):   # đinh sắt 2 đầu ván
            ell(im, nx, y0 + 8, 1.15, 1.15, fill=(52, 48, 44, 255))
            ell(im, nx - 0.4, y0 + 7.6, 0.45, 0.45, fill=(168, 164, 156, 220))
        if mossy:   # rêu bám mép dưới + góc ván
            ell(im, rnd.uniform(4, 60), y0 + 14.6, rnd.uniform(3, 6), 1.5, fill=A(MOSS, 130))
    speck(im, seed + 2, 70, [A(PLANK_D, 100), A(PLANK_L, 90)], 0.35, 0.9)
    if mossy:
        speck(im, seed + 7, 26, [A(MOSS, 120), A(SGRASS_D, 100)], 0.4, 1.0)
    return im

def swamp_transition(land_im, ground_im, ground_mask, seed):
    """Như transition() của v1 nhưng dải biên là BÙN ƯỚT sẫm (bờ đầm lầy
    không có cát sáng như bờ hồ Đông) + hạt vỡ viền bùn/cỏ."""
    from gen_tileset_v1 import ImageChops as _C  # noqa: F401  (giữ ý kế thừa, không dùng trực tiếp)
    band = ImageChops.subtract(dilate(ground_mask, 2.0), ground_mask)
    edge_im = wet_mud_im(seed + 31)
    out = Image.composite(edge_im, land_im, band)
    out = Image.composite(ground_im, out, ground_mask)
    fringe = ImageChops.subtract(dilate(ground_mask, 3.6), dilate(ground_mask, 1.4))
    dots = canvas(T)
    speck(dots, seed + 47, 90, [A(MUD, 170), A(MUD_L, 150), A(SGRASS_D, 130)], 0.35, 0.8, wrap=False)
    out = Image.composite(dots, out, fringe.point(lambda v: v * 120 // 255))
    return out

def plank_edge_im(seed, side="s"):
    """Ván gỗ ở nửa trên + nước đục nửa dưới (mép cầu ván nhìn xuống nước).
    Chỉ sinh bản 's'; các hướng còn lại xoay từ bản này khi ghép mockup nếu cần,
    còn trong atlas giữ 1 bản làm mẫu mép — xem ghi chú tileset."""
    top = plank_im(seed)
    bot = murky_water_im(seed + 5)
    m = mask_H()
    return Image.composite(bot, top, m)

def build_swamp():
    tiles = {}
    tiles["water_murky_a"] = murky_water_im(131, 0.0)
    tiles["water_murky_b"] = murky_water_im(141, 0.5)
    tiles["water_deep"] = murky_water_im(161, 0.25, deep=True)
    tiles["mud_wet"] = wet_mud_im(111)
    tiles["mud_dry"] = dry_mud_im(121)
    tiles["swamp_grass"] = swamp_grass_im(101)
    tiles["swamp_grass_reeds"] = swamp_grass_im(202, reeds=True)
    tiles["plank"] = plank_im(301)
    tiles["plank_mossy"] = plank_im(302, mossy=True)

    g = tiles["swamp_grass"]; wt = tiles["water_murky_a"]; md = tiles["mud_wet"]
    H = mask_H(); V = mask_V()
    nH = ImageChops.invert(H); nV = ImageChops.invert(V)
    # bờ nước trên nền cỏ đầm (4 hướng + góc lồi + góc lõm) — cùng quy ước v1
    tiles["shore_s"] = swamp_transition(g, wt, H, 221)                    # cỏ trên / nước dưới
    tiles["shore_n"] = swamp_transition(g, wt, nH, 222)                   # nước trên / cỏ dưới
    tiles["shore_w"] = swamp_transition(g, wt, nV, 223)                   # nước trái / cỏ phải
    tiles["shore_e"] = swamp_transition(g, wt, V, 224)                    # cỏ trái / nước phải
    tiles["shore_corner_convex"] = swamp_transition(g, wt, ImageChops.multiply(H, V), 225)
    tiles["shore_corner_concave"] = swamp_transition(g, wt, ImageChops.lighter(H, V), 226)
    # bờ bùn–nước (bãi bùn ngập): bùn trên / nước dưới, dùng cho bãi triều rút
    tiles["mud_shore_s"] = swamp_transition(md, wt, H, 231)
    tiles["mud_shore_n"] = swamp_transition(md, wt, nH, 232)
    # cỏ–bùn: lối mòn bùn giữa cỏ đầm
    tiles["mud_path_s"] = swamp_transition(g, md, H, 241)
    tiles["plank_edge_s"] = plank_edge_im(303)
    return tiles

SWAMP_ORDER = [
    "water_murky_a", "water_murky_b", "water_deep", "mud_wet", "mud_dry",
    "swamp_grass", "swamp_grass_reeds", "plank", "plank_mossy", "shore_s",
    "shore_n", "shore_w", "shore_e", "shore_corner_convex", "shore_corner_concave",
    "mud_shore_s", "mud_shore_n", "mud_path_s", "plank_edge_s", "swamp_grass",
]
# Lưu ý: ô cuối (4:3) lặp swamp_grass làm ô đệm cho đủ lưới 5x4 — khi dựng thật
# chỉ dùng 19 tile đầu; xem design/fenmire_so_do.md §trạng thái art.
SWAMP_COLS = 5

# ============================================================ PROP ĐẦM LẦY

def draw_swamp_canopy(im, cx, cy, R, seed):
    """Tán cây đầm: sẫm, rủ xuống (blob lệch xuống + tua lá rủ) — khác tán sồi Đông tròn sáng."""
    rnd = random.Random(seed)
    blobs = []
    for i in range(24):
        a = rnd.uniform(0, 2 * math.pi)
        rr = math.sqrt(rnd.uniform(0, 1)) * R * 0.72
        bx, by = cx + rr * math.cos(a) * 1.14, cy + rr * math.sin(a) * 0.84 + R * 0.08
        blobs.append((bx, by, R * rnd.uniform(0.34, 0.55)))
    for (bx, by, br) in blobs:
        ell(im, bx + R * 0.05, by + R * 0.08, br, br * 0.86, fill=(34, 76, 38, 255))
    for (bx, by, br) in blobs:
        ell(im, bx, by, br, br * 0.86, fill=(52, 102, 48, 255))
    for (bx, by, br) in blobs:
        ell(im, bx - br * 0.22, by - br * 0.3, br * 0.6, br * 0.5, fill=A((86, 140, 66), 235))
    rnd2 = random.Random(seed + 5)
    for _ in range(int(R * 1.5)):   # điểm sáng lá thưa (đầm ít nắng lọt)
        a = rnd2.uniform(0, 2 * math.pi); rr = math.sqrt(rnd2.uniform(0, 1)) * R * 0.8
        x, y = cx + rr * math.cos(a) * 1.1, cy + rr * math.sin(a) * 0.8
        ell(im, x, y, rnd2.uniform(0.9, 1.9), rnd2.uniform(0.7, 1.4), fill=A((140, 190, 104), 170))
    for _ in range(9):   # tua lá/rêu rủ xuống mép tán
        x = cx + rnd2.uniform(-R * 0.85, R * 0.85)
        y0 = cy + R * rnd2.uniform(0.35, 0.6)
        line(im, (x, y0), (x + rnd2.uniform(-2, 2), y0 + rnd2.uniform(8, 18)),
             A((64, 110, 54), 200), 1.3)

def prop_mangrove():
    """Cây đước: thân ngắn, RỄ CHỐNG CONG toả xuống nước/bùn (chữ ký đước),
    tán rủ sẫm. Chân neo ở mặt nước — đặt ở ô bờ/nước nông."""
    w, h = 200, 208
    im = canvas(w, h)
    soft_shadow(im, 100, 196, 62, 8, 62)
    # gợn nước quanh rễ
    for (rx, ry, rr) in [(52, 192, 20), (100, 198, 26), (148, 192, 20)]:
        ell(im, rx, ry, rr, rr * 0.3, fill=None, outline=A(MWATER_L, 110), ow=1.2)
    cx = 100
    # rễ chống: các cung cong từ thân (y~120) toả xuống mặt nước (y~196)
    rnd = random.Random(9)
    for dx, spread in [(-52, -30), (-34, -16), (-16, -6), (16, 6), (34, 16), (52, 30), (0, 0)]:
        top = (cx + dx * 0.25, 118)
        mid = (cx + dx * 0.95, 152)
        foot = (cx + dx, 197)
        pts = []
        for k in range(13):
            t = k / 12
            # cung cong bậc 2 qua top -> mid -> foot
            x = (1 - t) ** 2 * top[0] + 2 * (1 - t) * t * mid[0] + t ** 2 * foot[0]
            y = (1 - t) ** 2 * top[1] + 2 * (1 - t) * t * mid[1] + t ** 2 * foot[1]
            pts.append((x * SS, y * SS))
        ImageDraw.Draw(im).line(pts, fill=(92, 66, 42, 255), width=int(4.6 * SS), joint="curve")
        ImageDraw.Draw(im).line([(px - 1.5 * SS, py) for px, py in pts],
                                fill=A((140, 106, 68), 160), width=int(1.5 * SS))
        ell(im, foot[0], 197, 4.5, 1.8, fill=A(MUD_D, 160))   # bùn bám chân rễ
    # thân ngắn hơi nghiêng + vỏ sẫm ẩm
    poly(im, [(cx - 9, 128), (cx + 8, 124), (cx + 5, 74), (cx - 5, 72)], fill=(100, 72, 46, 255))
    for _ in range(10):
        x = cx + rnd.uniform(-6, 6); y0 = rnd.uniform(80, 116)
        line(im, (x, y0), (x + rnd.uniform(-1, 1), y0 + rnd.uniform(5, 11)), A((66, 46, 28), 170), 1.1)
    ell(im, cx - 2, 150, 10, 4, fill=A(MOSS, 150))   # rêu bám thân ngang mực nước
    line(im, (cx, 84), (cx - 20, 60), (84, 58, 36, 255), 3.8)
    line(im, (cx, 82), (cx + 19, 58), (84, 58, 36, 255), 3.4)
    draw_swamp_canopy(im, cx, 52, 56, 17)
    return finish(im, w, h)

def prop_reed_clump():
    """Bụi sậy cao: nhiều thân mảnh cong, lá dài rủ, vài bông đuôi mèo nâu."""
    w, h = 96, 104
    im = canvas(w, h)
    soft_shadow(im, 48, 97, 34, 5, 55)
    ell(im, 48, 96, 30, 4.5, fill=A(MUD_D, 110))
    rnd = random.Random(23)
    for i in range(26):
        x = 48 + rnd.uniform(-26, 26)
        hgt = rnd.uniform(46, 88)
        lean = rnd.uniform(-9, 9)
        col = rnd.choice((REED, REED_D, SGRASS_L, (104, 140, 70)))
        line(im, (x, 98), (x + lean * 0.4, 98 - hgt * 0.6), col + (255,), 1.5)
        line(im, (x + lean * 0.4, 98 - hgt * 0.6), (x + lean, 98 - hgt), col + (255,), 1.2)
        if i % 4 == 0:   # lá dài rủ từ giữa thân
            line(im, (x + lean * 0.3, 98 - hgt * 0.55),
                 (x + lean * 0.3 + rnd.uniform(8, 15) * (1 if i % 8 else -1), 98 - hgt * 0.3),
                 A(REED_D, 220), 1.3)
    for i in range(6):   # bông đuôi mèo
        x = 48 + rnd.uniform(-22, 22); top = rnd.uniform(16, 40)
        line(im, (x, 98), (x + 2, top + 12), REED_D + (255,), 1.5)
        line(im, (x + 2, top + 12), (x + 2.6, top), CATTAIL + (255,), 3.4)
        ell(im, x + 2.6, top - 1.5, 1.1, 1.1, fill=(210, 180, 110, 255))
    return finish(im, w, h)

def prop_glowshroom():
    """Nấm độc phát sáng nhẹ: mũ tím-xanh có đốm, hào quang teal mờ —
    điểm sáng nguy hiểm quanh Đầm Độc / Đền Chìm Triều. Phát sáng NHẸ có chủ ý."""
    w, h = 88, 76
    im = canvas(w, h)
    soft_shadow(im, 44, 68, 32, 5, 58)
    glow = canvas(w, h)
    ell(glow, 44, 46, 34, 26, fill=(84, 220, 190, 52))
    glow = glow.filter(ImageFilter.GaussianBlur(4.2 * SS))
    im.alpha_composite(glow)
    rnd = random.Random(37)
    shrooms = [(30, 66, 15), (50, 68, 19), (64, 64, 11), (40, 62, 8)]
    for (cx, by, r) in sorted(shrooms, key=lambda s: -s[2]):
        # thân nấm
        poly(im, [(cx - r * 0.22, by), (cx + r * 0.22, by), (cx + r * 0.13, by - r * 0.75),
                  (cx - r * 0.13, by - r * 0.75)], fill=(206, 216, 196, 255))
        # mũ: nửa elip tím than -> teal ở mép (độc mà đẹp)
        ell(im, cx, by - r * 0.78, r, r * 0.62, fill=(96, 74, 148, 255))
        ell(im, cx, by - r * 0.86, r * 0.66, r * 0.4, fill=A((140, 110, 196), 220))
        ell(im, cx, by - r * 0.6, r * 0.94, r * 0.2, fill=A((84, 220, 190), 165))  # vành phát sáng
        for _ in range(4):   # đốm sáng trên mũ
            ell(im, cx + rnd.uniform(-r * 0.6, r * 0.6), by - r * 0.78 + rnd.uniform(-r * 0.25, r * 0.2),
                rnd.uniform(0.8, 1.6), rnd.uniform(0.7, 1.2), fill=A((196, 255, 236), 220))
    for _ in range(7):   # bào tử sáng li ti bay quanh
        ell(im, rnd.uniform(14, 74), rnd.uniform(20, 52), 0.8, 0.8, fill=A((150, 255, 220), 190))
    return finish(im, w, h)

def prop_swamp_log():
    """Khúc gỗ mục nằm ngang: rêu + nấm nhỏ bám, dùng chắn đường/trang trí bờ."""
    w, h = 128, 56
    im = canvas(w, h)
    soft_shadow(im, 64, 47, 54, 6, 55)
    d = ImageDraw.Draw(im)
    rrect(im, (8, 22, 118, 44), 9, fill=(106, 76, 48, 255), outline=(70, 48, 28, 255), ow=1.2)
    d.rectangle([8 * SS, 22 * SS, 118 * SS, 27 * SS], fill=A((146, 110, 70), 170))
    ell(im, 12, 33, 5.5, 10.5, fill=(178, 142, 96, 255), outline=(120, 90, 56, 255), ow=1.1)
    ell(im, 12, 33, 2.8, 5.4, fill=A((140, 106, 64), 200))
    rnd = random.Random(43)
    for _ in range(8):   # vệt vỏ nứt dọc
        x = rnd.uniform(22, 108); y = rnd.uniform(26, 40)
        line(im, (x, y), (x + rnd.uniform(5, 12), y + rnd.uniform(-1.5, 1.5)), A((70, 48, 28), 170), 1.0)
    for (mx, my, mr) in [(38, 23, 9), (74, 22, 12), (100, 24, 7)]:   # mảng rêu trên lưng gỗ
        ell(im, mx, my, mr, mr * 0.4, fill=A(MOSS, 205))
        ell(im, mx - 2, my - 1, mr * 0.5, mr * 0.22, fill=A(SGRASS_L, 170))
    for (nx, ny) in [(58, 20), (88, 19)]:   # nấm con trên gỗ mục
        line(im, (nx, ny + 4), (nx, ny - 2), (206, 216, 196, 255), 1.6)
        ell(im, nx, ny - 3, 3.6, 2.2, fill=(150, 96, 60, 255))
    return finish(im, w, h)

# ============================================================ ATLAS + .tres + MOCKUP

def save_atlas(tiles, order, cols, path_png, path_tres, res_path):
    rows = math.ceil(len(order) / cols)
    atlas = Image.new("RGBA", (cols * T, rows * T), (0, 0, 0, 0))
    for i, name in enumerate(order):
        atlas.alpha_composite(finish(tiles[name], T), ((i % cols) * T, (i // cols) * T))
    atlas.save(path_png)
    lines = ['[gd_resource type="TileSet" load_steps=3 format=3]', '',
             f'[ext_resource type="Texture2D" path="{res_path}" id="1"]', '',
             '[sub_resource type="TileSetAtlasSource" id="AtlasSource_1"]',
             'texture = ExtResource("1")',
             'texture_region_size = Vector2i(64, 64)']
    for i, name in enumerate(order):
        lines.append(f'{i % cols}:{i // cols}/0 = 0')
    lines += ['', '[resource]', 'tile_size = Vector2i(64, 64)',
              'sources/0 = SubResource("AtlasSource_1")', '']
    with open(path_tres, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return atlas

def tile_get(atlas, order, name, cols):
    i = order.index(name)
    return atlas.crop(((i % cols) * T, (i // cols) * T, (i % cols) * T + T, (i // cols) * T + T))

def build_mockup(atlas, props):
    """Cảnh đầm mẫu 15x10 ô: hồ nước đục phía tây-nam, bãi bùn, cỏ đầm + sậy,
    đường VÁN GỖ bắc qua nước từ đông sang tây, đước ở bờ, nấm độc ở góc độc."""
    cols, rows = 15, 10
    scene = Image.new("RGBA", (cols * T, rows * T), (0, 0, 0, 255))
    G = lambda n: tile_get(atlas, SWAMP_ORDER, n, SWAMP_COLS)  # noqa: E731
    def paste(im, x, y):
        scene.alpha_composite(im, (int(x), int(y)))
    # nền cỏ đầm + biến thể sậy + bãi bùn khô góc đông-bắc
    for y in range(rows):
        for x in range(cols):
            n = "swamp_grass"
            if (x, y) in [(6, 1), (10, 3), (3, 6), (12, 7), (7, 8), (13, 2)]:
                n = "swamp_grass_reeds"
            if x >= 12 and y <= 2:
                n = "mud_dry"
            if (x, y) in [(11, 4), (11, 5), (12, 5)]:
                n = "mud_wet"
            paste(G(n), x * T, y * T)
    # mặt nước đục: khối tây-nam + bờ chuyển tiếp khớp profile chung
    water_cells = {(0, 7): "water_murky_a", (1, 7): "water_murky_b", (0, 8): "water_murky_b",
                   (1, 8): "water_deep", (0, 9): "water_deep", (1, 9): "water_murky_a",
                   (2, 8): "water_murky_a", (2, 9): "water_murky_b"}
    for (x, y), n in water_cells.items():
        paste(G(n), x * T, y * T)
    shore = {(0, 6): "shore_s", (1, 6): "shore_s", (2, 6): "shore_s",
             (2, 7): "shore_e", (3, 8): "shore_w", (3, 9): "shore_w",
             (3, 7): "shore_corner_convex"}
    # shore_e đặt ở (2,7): nước bên phải theo quy ước v1 (cỏ trái/nước phải) ->
    # ở đây dùng làm mép đông của hồ; shore_w ở cột 3 = nước trái/cỏ phải (bờ đông hồ).
    shore[(2, 7)] = "water_murky_a"
    for (x, y), n in shore.items():
        paste(G(n), x * T, y * T)
    # bãi bùn ngập nối cỏ xuống nước ở góc tây-bắc hồ
    paste(G("mud_path_s"), 5 * T, 6 * T)
    paste(G("mud_shore_s"), 5 * T, 7 * T)
    paste(G("water_murky_b"), 5 * T, 8 * T)
    paste(G("water_murky_a"), 5 * T, 9 * T)
    paste(G("shore_w"), 4 * T, 8 * T)
    paste(G("shore_w"), 4 * T, 9 * T)
    paste(G("shore_e"), 6 * T, 8 * T)
    paste(G("shore_e"), 6 * T, 9 * T)
    # ĐƯỜNG VÁN GỖ: ngang hàng 4-5 từ bờ đông qua kênh nước nhỏ tới bãi bùn
    for x in range(4, 15):
        paste(G("plank_mossy" if x % 3 == 0 else "plank"), x * T, 4 * T)
    for x in (8, 9):   # đoạn kênh: ván bắc qua nước (vẽ nước trước, ván đè lên)
        paste(G("water_murky_a"), x * T, 5 * T)
        paste(G("plank"), x * T, 5 * T)
    paste(G("plank_edge_s"), 7 * T, 5 * T)
    # prop theo Y-sort (bắc -> nam)
    paste(props["mangrove"], 0 * T + 6, 3 * T + 2)          # đước bờ tây hồ
    paste(props["reed_clump"], 3 * T + 30, 5 * T + 18)      # sậy mép bờ
    paste(props["swamp_log"], 10 * T + 8, 6 * T + 20)       # gỗ mục trên cỏ
    paste(props["glowshroom"], 13 * T + 20, 1 * T + 8)      # nấm độc trên bùn khô
    paste(props["reed_clump"], 6 * T + 36, 7 * T + 26)      # sậy ở cửa bãi bùn
    paste(props["mangrove"], 11 * T + 30, 6 * T + 30)       # đước thứ hai phía nam
    paste(props["glowshroom"], 2 * T + 40, 8 * T + 30)      # nấm độc ven nước sâu
    return scene

def main():
    tiles = build_swamp()
    atlas = save_atlas(tiles, SWAMP_ORDER, SWAMP_COLS,
                       os.path.join(TILE_DIR, "swamp_v1.png"),
                       os.path.join(TILE_DIR, "swamp_v1.tres"),
                       "res://assets/tilesets/swamp_v1.png")
    print("swamp atlas:", atlas.size, "tiles:", len(SWAMP_ORDER))
    props = {
        "mangrove": prop_mangrove(), "reed_clump": prop_reed_clump(),
        "glowshroom": prop_glowshroom(), "swamp_log": prop_swamp_log(),
    }
    for name, im in props.items():
        im.save(os.path.join(PROP_DIR, name + ".png"))
        print("prop:", name, im.size)
    mock = build_mockup(atlas, props)
    mock = mock.resize((mock.width * 3 // 2, mock.height * 3 // 2), Image.LANCZOS)
    mock.convert("RGB").save(os.path.join(DESIGN_DIR, "fenmire_mockup_v1.png"))
    print("fenmire mockup:", mock.size)

if __name__ == "__main__":
    main()
