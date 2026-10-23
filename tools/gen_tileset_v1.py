#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh bộ tileset mẫu v1 + prop + mockup kiểu Stardew Valley cho "Dưới Bóng Phong Ấn".

Kỹ thuật (kết hợp, theo chuẩn đã duyệt ở sprite v3):
- Vẽ SUPERSAMPLE 4x (tile 64px -> canvas 256) bằng PIL: hình khối thật,
  shading nhiều lớp, texture hạt/vệt có kiểm soát, chi tiết nhỏ (lá, ngói,
  thớ gỗ, viên đá, ngọn cỏ). Sau đó downscale LANCZOS + unsharp nhẹ.
- Texture của tile nền vẽ kiểu WRAP-AROUND (mỗi chi tiết vẽ lặp ở 9 offset
  +/-64px) nên ghép lưới không lộ mối nối.
- Tile chuyển tiếp (cỏ/đất, đất/nước) dùng chung một profile biên lượn sóng
  h(x)/w(y) cho mọi tile: mask H (đất ở dưới biên), mask V (đất ở phải biên),
  góc lồi = H AND V, góc lõm = H OR V -> các tile khớp nhau ở mọi cạnh.
- Prop vẽ nguyên con trên canvas riêng, nền trong suốt, có bóng đổ mềm.

Chạy: python3 tools/gen_tileset_v1.py
Đầu ra:
- game/assets/tilesets/exterior_v1.png (+ .tres), interior_tavern_v1.png (+ .tres)
- game/assets/props/*.png
- design/tileset_mockup_v1.png, design/tavern_mockup_v1.png
"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageChops, ImageFilter

SS = 4
T = 64                      # cạnh tile cuối (px)
W = T * SS                  # 256 - canvas vẽ 1 tile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TILE_DIR = os.path.join(ROOT, "game", "assets", "tilesets")
PROP_DIR = os.path.join(ROOT, "game", "assets", "props")
DESIGN_DIR = os.path.join(ROOT, "design")
for dd in (TILE_DIR, PROP_DIR, DESIGN_DIR):
    os.makedirs(dd, exist_ok=True)

# ---------------- palette (dịu, tông Stardew mùa xuân) ----------------
GRASS = (104, 160, 76); GRASS_L = (138, 192, 100); GRASS_D = (76, 128, 56); GRASS_XD = (58, 106, 44)
GRASS_DARK = (84, 138, 64)
DIRT = (158, 118, 76); DIRT_L = (186, 148, 100); DIRT_D = (124, 90, 54); PEBBLE = (168, 158, 142)
SAND = (219, 196, 142); SAND_D = (198, 172, 112)
WATER = (72, 130, 176); WATER_D = (50, 104, 152); WATER_L = (128, 188, 226); FOAM = (224, 242, 248)
SOIL = (130, 94, 58); SOIL_D = (104, 72, 42); SOIL_L = (156, 120, 80)
WOOD = (146, 102, 62); WOOD_L = (176, 132, 84); WOOD_D = (106, 70, 40); WOOD_XD = (78, 50, 28)
PLASTER = (238, 228, 202)
STONE = (148, 148, 150); STONE_L = (178, 178, 180); STONE_D = (110, 110, 116)
ROOF = (146, 88, 58); ROOF_L = (176, 116, 78); ROOF_D = (112, 64, 42)
LEAF = (74, 138, 62); LEAF_L = (110, 176, 84); LEAF_D = (48, 104, 46); LEAF_HI = (156, 214, 118)

def A(col, a):
    return col[:3] + (a,)

# PIL 10.2: rounded_rectangle chết với toạ độ float -> bọc lại: ép int + kẹp radius.
_orig_rr = ImageDraw.ImageDraw.rounded_rectangle
def _rr(self, xy, radius=0, **kw):
    x0, y0, x1, y1 = [int(round(v)) for v in xy]
    radius = max(0, min(int(round(radius)), (x1 - x0) // 2, (y1 - y0) // 2))
    return _orig_rr(self, [x0, y0, x1, y1], radius=radius, **kw)
ImageDraw.ImageDraw.rounded_rectangle = _rr

# ---------------- helpers (toạ độ theo px cuối, tự nhân SS) ----------------

def canvas(w, h=None):
    return Image.new("RGBA", (int(w * SS), int((h or w) * SS)), (0, 0, 0, 0))

def P_(pts):
    return [(x * SS, y * SS) for (x, y) in pts]

def poly(im, pts, fill=None, outline=None, ow=1.0):
    d = ImageDraw.Draw(im)
    d.polygon(P_(pts), fill=fill, outline=outline, width=max(1, int(ow * SS)) if outline else 1)

def ell_pts(cx, cy, rx, ry, rot=0.0, n=36):
    pts = []
    rr = math.radians(rot)
    for i in range(n + 1):
        a = 2 * math.pi * i / n
        ex, ey = rx * math.cos(a), ry * math.sin(a)
        pts.append((cx + ex * math.cos(rr) - ey * math.sin(rr),
                    cy + ex * math.sin(rr) + ey * math.cos(rr)))
    return pts

def ell(im, cx, cy, rx, ry, fill=None, outline=None, ow=1.0, rot=0.0):
    poly(im, ell_pts(cx, cy, rx, ry, rot), fill=fill, outline=outline, ow=ow)

def line(im, p0, p1, fill, w=1.6):
    d = ImageDraw.Draw(im)
    d.line([p0[0] * SS, p0[1] * SS, p1[0] * SS, p1[1] * SS], fill=fill,
           width=max(1, int(w * SS)), joint="curve")
    r = w / 2.0
    ell(im, p0[0], p0[1], r, r, fill=fill)
    ell(im, p1[0], p1[1], r, r, fill=fill)

def rrect(im, box, r, fill=None, outline=None, ow=1.0):
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([box[0] * SS, box[1] * SS, box[2] * SS, box[3] * SS],
                        radius=r * SS, fill=fill, outline=outline,
                        width=max(1, int(ow * SS)) if outline else 1)

def finish(im, w, h=None):
    out = im.resize((int(w), int(h or w)), Image.LANCZOS)
    return out.filter(ImageFilter.UnsharpMask(radius=2, percent=52, threshold=3))

def soft_shadow(im, cx, cy, rx, ry, alpha=95):
    """Bóng đổ mềm: vẽ ellipse đen lên layer riêng, blur rồi composite."""
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS],
              fill=(20, 26, 16, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(4.4 * SS))
    im.alpha_composite(layer)

# ---------------- texture wrap-around cho tile nền ----------------

def speck(im, seed, n, cols, rmin=0.5, rmax=1.3, wrap=True):
    """Chấm hạt ngẫu nhiên; wrap=True thì vẽ lặp 9 offset để liền mối nối."""
    rnd = random.Random(seed)
    d = ImageDraw.Draw(im)
    offs = [(-T, -T), (0, -T), (T, -T), (-T, 0), (0, 0), (T, 0), (-T, T), (0, T), (T, T)] if wrap else [(0, 0)]
    for _ in range(n):
        x, y = rnd.uniform(0, T), rnd.uniform(0, T)
        r = rnd.uniform(rmin, rmax)
        col = rnd.choice(cols)
        for dx, dy in offs:
            d.ellipse([(x + dx - r) * SS, (y + dy - r * 0.8) * SS,
                       (x + dx + r) * SS, (y + dy + r * 0.8) * SS], fill=col)

def blade(im, x, y, h, col, lean=0.0):
    """Một ngọn cỏ: 1 nét cong nhẹ (2 đoạn) từ gốc lên."""
    line(im, (x, y), (x + lean * 0.5, y - h * 0.6), col, 1.15)
    line(im, (x + lean * 0.5, y - h * 0.6), (x + lean, y - h), col, 0.95)

def tuft(im, x, y, s, cols, seed):
    rnd = random.Random(seed)
    for k in range(6):
        dx = rnd.uniform(-2.6, 2.6)
        blade(im, x + dx, y, s * rnd.uniform(0.7, 1.25), rnd.choice(cols),
              lean=dx * rnd.uniform(0.2, 0.5))

def tufts_wrap(im, seed, n, smin=4.0, smax=7.5, cols=(GRASS_D, GRASS_D, GRASS_L)):
    rnd = random.Random(seed)
    offs = [(-T, -T), (0, -T), (T, -T), (-T, 0), (0, 0), (T, 0), (-T, T), (0, T), (T, T)]
    for i in range(n):
        x, y = rnd.uniform(0, T), rnd.uniform(0, T)
        s = rnd.uniform(smin, smax)
        for dx, dy in offs:
            tuft(im, x + dx, y + dy, s, cols, seed * 1000 + i)


def ell9(im, cx, cy, rx, ry, fill):
    """Ellipse vẽ lặp 9 offset (wrap) cho lớp mảng mềm của tile nền."""
    for dx in (-T, 0, T):
        for dy in (-T, 0, T):
            ell(im, cx + dx, cy + dy, rx, ry, fill=fill)

def wrapped_blur(im, radius):
    """Blur mà không tạo vệt ở cạnh tile: lát 3x3 rồi crop tâm."""
    big = Image.new("RGBA", (W * 3, W * 3), (0, 0, 0, 0))
    for dx in (0, W, 2 * W):
        for dy in (0, W, 2 * W):
            big.alpha_composite(im, (dx, dy))
    big = big.filter(ImageFilter.GaussianBlur(radius))
    return big.crop((W, W, 2 * W, 2 * W))

def base_fill(col):
    im = canvas(T)
    ImageDraw.Draw(im).rectangle([0, 0, W, W], fill=col + (255,))
    return im

# ============================================================ TILE NGOÀI TRỜI

def grass_im(seed, flowers=False, tall=False, sparse=False, dark=False):
    base = GRASS_DARK if dark else GRASS
    im = base_fill(base)
    # mảng sáng/tối mềm lớn cho đỡ phẳng
    ov = canvas(T)
    if sparse:
        for (cx, cy, rx, ry) in [(18, 22, 17, 12), (46, 48, 19, 13), (52, 12, 12, 9)]:
            ell9(ov, cx, cy, rx, ry, A(DIRT, 165))
            ell9(ov, cx, cy, rx * 0.6, ry * 0.6, A(DIRT_D, 90))
    else:
        ell9(ov, 20, 18, 24, 15, A(GRASS_L, 40))
        ell9(ov, 50, 52, 22, 14, A(GRASS_D, 36))
    ov = wrapped_blur(ov, 2.4 * SS)
    im.alpha_composite(ov)
    speck(im, seed, 48, [A(GRASS_L, 34), A(GRASS_D, 32)], 0.3, 0.65)
    speck(im, seed + 9, 16, [A(GRASS_D, 45)], 0.3, 0.6)
    if sparse:
        speck(im, seed + 4, 60, [A(DIRT_L, 150), A(PEBBLE, 130)], 0.5, 1.1)
    tufts_wrap(im, seed + 1, 6 if not tall else 4, 4.0, 6.5)
    if tall:
        tufts_wrap(im, seed + 2, 13, 7.0, 11.5)
    if flowers:
        rnd = random.Random(seed + 77)
        fcols = [(250, 246, 235), (250, 214, 92), (244, 164, 188), (196, 178, 240)]
        offs = [(-T, -T), (0, -T), (T, -T), (-T, 0), (0, 0), (T, 0), (-T, T), (0, T), (T, T)]
        for i in range(11):
            x, y = rnd.uniform(4, T - 4), rnd.uniform(4, T - 4)
            col = rnd.choice(fcols)
            for dx, dy in offs:
                blade(im, x + dx, y + dy, 3.4, GRASS_D, 0.4)
                for px, py in [(-1.3, 0), (1.3, 0), (0, -1.3), (0, 1.3)]:
                    ell(im, x + dx + px, y + dy + py, 1.05, 1.05, fill=col + (235,))
                ell(im, x + dx, y + dy, 0.75, 0.75, fill=(250, 190, 70, 255))
    return im

def dirt_im(seed):
    im = base_fill(DIRT)
    ov = canvas(T)
    ell9(ov, 22, 26, 25, 16, A(DIRT_L, 60))
    ell9(ov, 48, 50, 22, 14, A(DIRT_D, 55))
    ov = wrapped_blur(ov, 2.4 * SS)
    im.alpha_composite(ov)
    speck(im, seed, 105, [A(DIRT_L, 70), A(DIRT_D, 68)], 0.3, 0.8)
    speck(im, seed + 3, 22, [A(PEBBLE, 190), A(STONE_D, 130)], 0.7, 1.7)   # sỏi
    rnd = random.Random(seed + 5)                                          # vệt nứt/vệt bánh xe mờ
    for _ in range(5):
        x, y = rnd.uniform(6, 58), rnd.uniform(6, 58)
        line(im, (x, y), (x + rnd.uniform(-9, 9), y + rnd.uniform(-3, 3)), A(DIRT_D, 90), 0.9)
    return im

def field_im(seed):
    im = base_fill(SOIL)
    d = ImageDraw.Draw(im)
    for i, ry in enumerate([8, 24, 40, 56]):                     # luống ngang, liền theo x
        d.rectangle([0, (ry - 4.6) * SS, W, (ry + 4.6) * SS], fill=SOIL_D + (255,))
        d.rectangle([0, (ry - 4.6) * SS, W, (ry - 1.8) * SS], fill=SOIL_L + (200,))
    speck(im, seed, 180, [A(SOIL_L, 130), A(SOIL_D, 140)])
    rnd = random.Random(seed + 8)                                 # mầm non theo hàng
    offs = [(-T, 0), (0, 0), (T, 0)]
    for ry in [8, 24, 40, 56]:
        for x in range(4, 64, 8):
            jx = x + rnd.uniform(-1.2, 1.2)
            for dx, dy in offs:
                blade(im, jx + dx, ry + 1.5, 3.6, (96, 168, 74, 255), 0.5)
                blade(im, jx + dx + 1.6, ry + 1.5, 2.8, (120, 190, 92, 255), -0.4)
    return im

def water_im(seed, phase=0.0):
    im = base_fill(WATER)
    ov = canvas(T)
    ell9(ov, 18, 20, 26, 14, A(WATER_L, 46))
    ell9(ov, 48, 50, 24, 13, A(WATER_D, 60))
    ov = wrapped_blur(ov, 2.6 * SS)
    im.alpha_composite(ov)
    d = ImageDraw.Draw(im)
    rnd = random.Random(seed)
    for r_ in range(4):                                           # gợn sóng ngang, wrap theo x
        y0 = 9 + r_ * 15 + rnd.uniform(-2, 2)
        for seg in range(3):
            x0 = (seg * 22 + phase * 11 + rnd.uniform(-2, 2)) % 64
            pts = []
            for k in range(13):
                xx = x0 + k * 1.25
                pts.append((xx * SS, (y0 + 1.6 * math.sin(k / 12 * math.pi)) * SS))
            for dx in (-T, 0, T):
                d.line([(px + dx * SS, py) for px, py in pts],
                       fill=A(WATER_L, 165), width=int(1.15 * SS))
    speck(im, seed + 6, 22, [A(FOAM, 200), A(WATER_L, 170)], 0.4, 0.9)
    return im

def sand_im(seed):
    im = base_fill(SAND)
    speck(im, seed, 220, [A(SAND_D, 120), A((236, 216, 168), 130), A(PEBBLE, 90)])
    return im

# ---- profile biên lượn sóng dùng chung cho mọi tile chuyển tiếp ----
def hprof(x):
    return 33 + 2.4 * math.sin(2 * math.pi * x / T) + 1.4 * math.sin(4 * math.pi * x / T + 1.3)

def mask_H():
    """Mask phần DƯỚI biên lượn sóng (theo trục x)."""
    m = Image.new("L", (W, W), 0)
    pts = [(x * SS, hprof(x) * SS) for x in range(0, T + 1, 2)] + [(W, W), (0, W)]
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return m

def mask_V():
    """Mask phần bên PHẢI biên lượn sóng (theo trục y) — cùng profile với mask_H."""
    m = Image.new("L", (W, W), 0)
    pts = [(hprof(y) * SS, y * SS) for y in range(0, T + 1, 2)] + [(W, W), (W, 0)]
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return m

def dilate(mask, px_final=2.6):
    return mask.filter(ImageFilter.MaxFilter(int(px_final * SS) | 1))

def transition(land_im, ground_im, ground_mask, seed, shore=False):
    """ground phủ theo mask lên land; dải biên ở phía land sát biên
    (cát sáng cho bờ nước, đất khô cho đường đất) + hạt vỡ viền cho đỡ nét vector."""
    band = ImageChops.subtract(dilate(ground_mask, 2.0), ground_mask)
    edge_im = sand_im(seed + 31) if shore else None
    if edge_im is None:
        edge_im = base_fill((178, 150, 104))
        speck(edge_im, seed + 31, 120, [A(DIRT_L, 120), A(GRASS_D, 90)], 0.3, 0.8)
    out = Image.composite(edge_im, land_im, band)
    out = Image.composite(ground_im, out, ground_mask)
    fringe = ImageChops.subtract(dilate(ground_mask, 3.6), dilate(ground_mask, 1.4))
    dots = canvas(T)
    speck(dots, seed + 47, 90, [A(DIRT, 165), A(DIRT_L, 150)], 0.35, 0.8, wrap=False)
    out = Image.composite(dots, out, fringe.point(lambda v: v * 120 // 255))
    return out

def build_exterior():
    tiles = {}
    tiles["grass"] = grass_im(101)
    tiles["grass_flower"] = grass_im(202, flowers=True)
    tiles["grass_tall"] = grass_im(303, tall=True)
    tiles["grass_sparse"] = grass_im(404, sparse=True)
    tiles["grass_dark"] = grass_im(505, dark=True)
    tiles["dirt"] = dirt_im(111)
    tiles["field"] = field_im(121)
    tiles["water_a"] = water_im(131, 0.0)
    tiles["water_b"] = water_im(141, 0.5)
    tiles["sand"] = sand_im(151)

    g = tiles["grass"]; dt = tiles["dirt"]; wt = tiles["water_a"]
    H = mask_H(); V = mask_V()
    nH = ImageChops.invert(H); nV = ImageChops.invert(V)
    tiles["path_s"] = transition(g, dt, H, 211)                    # cỏ trên / đất dưới
    tiles["path_n"] = transition(g, dt, nH, 212)                   # đất trên / cỏ dưới
    tiles["path_w"] = transition(g, dt, nV, 213)                   # đất trái / cỏ phải
    tiles["path_e"] = transition(g, dt, V, 214)                    # cỏ trái / đất phải
    tiles["path_corner_convex"] = transition(g, dt, ImageChops.multiply(H, V), 215)   # đất góc dưới-phải (lồi)
    tiles["path_corner_concave"] = transition(g, dt, ImageChops.lighter(H, V), 216)   # đất gần hết, cỏ lõm góc trên-trái
    tiles["shore_s"] = transition(g, wt, H, 221, shore=True)                   # cỏ trên / nước dưới
    tiles["shore_n"] = transition(g, wt, nH, 222, shore=True)                  # nước trên / cỏ dưới
    tiles["shore_w"] = transition(g, wt, nV, 223, shore=True)                  # nước trái / cỏ phải
    tiles["shore_e"] = transition(g, wt, V, 224, shore=True)                   # cỏ trái / nước phải
    tiles["shore_corner"] = transition(g, wt, ImageChops.multiply(H, V), 225, shore=True)  # nước góc dưới-phải

    # hàng rào (vẽ trên nền cỏ)
    tiles["fence_h"] = fence_tile(horizontal=True)
    tiles["fence_v"] = fence_tile(horizontal=False)
    tiles["pebbles"] = pebble_tile(606)
    return tiles

def fence_tile(horizontal=True):
    im = grass_im(707)
    soft_shadow(im, 32, 40, 27, 5, 60)
    d = ImageDraw.Draw(im)
    def rail(y):
        d.rounded_rectangle([1 * SS, (y - 2.2) * SS, 63 * SS, (y + 2.2) * SS],
                            radius=2 * SS, fill=WOOD + (255,))
        d.rectangle([1 * SS, (y - 2.2) * SS, 63 * SS, (y - 0.6) * SS], fill=WOOD_L + (200,))
    def post(x):
        d.rounded_rectangle([(x - 2.6) * SS, 16 * SS, (x + 2.6) * SS, 46 * SS],
                            radius=1.6 * SS, fill=WOOD + (255,), outline=WOOD_XD + (255,), width=SS)
        d.polygon(P_([(x - 2.6, 16), (x + 2.6, 16), (x, 12.6)]), fill=WOOD_D + (255,))
        d.rectangle([(x - 2.6) * SS, 16 * SS, (x - 1.1) * SS, 46 * SS], fill=WOOD_L + (170,))
    if horizontal:
        rail(24); rail(37)
        for x in (6, 32, 58): post(x)
        speck(im, 708, 26, [A(WOOD_XD, 160)], 0.4, 0.8, wrap=False)
        return im
    return fence_tile_rot()

def fence_tile_rot():
    # vẽ rào dọc trực tiếp (không xoay ảnh cỏ để tránh lệch texture)
    im = grass_im(707)
    soft_shadow(im, 40, 32, 5, 27, 60)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([(24 - 2.2) * SS, 1 * SS, (24 + 2.2) * SS, 63 * SS], radius=2 * SS, fill=WOOD + (255,))
    d.rounded_rectangle([(37 - 2.2) * SS, 1 * SS, (37 + 2.2) * SS, 63 * SS], radius=2 * SS, fill=WOOD + (255,))
    for y in (6, 32, 58):
        d.rounded_rectangle([16 * SS, (y - 2.6) * SS, 46 * SS, (y + 2.6) * SS],
                            radius=1.6 * SS, fill=WOOD + (255,), outline=WOOD_XD + (255,), width=SS)
    return im

def pebble_tile(seed):
    im = grass_im(808)
    rnd = random.Random(seed)
    for (cx, cy, r) in [(22, 26, 5.5), (33, 33, 4.2), (44, 24, 3.4), (28, 42, 3.0)]:
        ell(im, cx + 1, cy + r * 0.55, r, r * 0.42, fill=A(GRASS_XD, 90))
        ell(im, cx, cy, r, r * 0.78, fill=STONE + (255,), outline=STONE_D + (255,), ow=0.9)
        ell(im, cx - r * 0.3, cy - r * 0.28, r * 0.42, r * 0.26, fill=STONE_L + (220,))
    speck(im, seed, 20, [A(PEBBLE, 200)], 0.6, 1.2, wrap=False)
    return im

EXTERIOR_ORDER = [
    "grass", "grass_flower", "grass_tall", "grass_sparse", "dirt", "field", "water_a", "water_b",
    "path_s", "path_n", "path_w", "path_e", "path_corner_convex", "path_corner_concave", "shore_s", "shore_n",
    "shore_w", "shore_e", "shore_corner", "fence_h", "fence_v", "pebbles", "grass_dark", "sand",
]

# ============================================================ TILE NỘI THẤT (QUÁN RƯỢU)

def wood_floor_im(seed, vertical=False, dark=False):
    base = (116, 80, 48) if dark else WOOD
    li = (140, 102, 62) if dark else WOOD_L
    dk = (84, 56, 30) if dark else WOOD_D
    im = base_fill(base)
    d = ImageDraw.Draw(im)
    rnd = random.Random(seed)
    for r_ in range(4):                                    # ván ngang cao 16px, liền theo y
        y0 = r_ * 16
        tone = li if r_ % 2 == 0 else base
        d.rectangle([0, y0 * SS, W, (y0 + 16) * SS], fill=tone + (110,))
        jt = rnd.uniform(-9, 9)  # lệch tông nhẹ từng ván cho đỡ đều
        jtone = tuple(max(0, min(255, int(c + jt))) for c in base)
        d.rectangle([0, y0 * SS, W, (y0 + 16) * SS], fill=jtone + (70,))
        d.rectangle([0, (y0 + 15.2) * SS, W, (y0 + 16) * SS], fill=dk + (205,))       # khe ván
        d.rectangle([0, y0 * SS, W, (y0 + 1.1) * SS], fill=A(li, 170))               # mép sáng
        for gx in range(6):                                # thớ gỗ: vệt cong mờ
            gy = y0 + 3 + rnd.uniform(0, 10)
            pts = [((gx * 12 + k * 2.2) * SS, (gy + 0.8 * math.sin(k / 10 * math.pi)) * SS) for k in range(11)]
            d.line(pts, fill=A(dk, 80), width=int(0.8 * SS))
        jx = (r_ * 29 + 14) % 64                           # mối nối dọc so le
        d.rectangle([jx * SS, y0 * SS, (jx + 1.2) * SS, (y0 + 16) * SS], fill=dk + (230,))
    speck(im, seed + 2, 90, [A(dk, 110), A(li, 100)], 0.4, 1.0)
    if vertical:
        im = im.transpose(Image.ROTATE_90)
    return im

def wall_plank_im(seed):
    im = base_fill((96, 66, 40))
    d = ImageDraw.Draw(im)
    for c_ in range(4):                                    # ván dọc rộng 16px
        x0 = c_ * 16
        d.rectangle([x0 * SS, 0, (x0 + 16) * SS, W], fill=(WOOD if c_ % 2 == 0 else WOOD_D) + (120,))
        d.rectangle([(x0 + 15.2) * SS, 0, (x0 + 16) * SS, W], fill=WOOD_XD + (255,))
    d.rectangle([0, 40 * SS, W, 47 * SS], fill=WOOD_XD + (255,))        # xà ngang
    d.rectangle([0, 40 * SS, W, 41.4 * SS], fill=A(WOOD_L, 200))
    d.rectangle([0, 60 * SS, W, W], fill=(60, 40, 22, 255))             # chân tường tối
    for nx, ny in [(8, 43.5), (56, 43.5), (24, 8), (44, 30)]:
        ell(im, nx, ny, 1.0, 1.0, fill=(40, 30, 20, 255))
    speck(im, seed, 80, [A(WOOD_XD, 120), A(WOOD_L, 80)], 0.4, 0.9)
    return im

def wall_stone_im(seed):
    im = base_fill((104, 102, 104))
    d = ImageDraw.Draw(im)
    rnd = random.Random(seed)
    rows = [(0, 21), (21, 43), (43, 64)]
    for ri, (y0, y1) in enumerate(rows):
        off = 0 if ri % 2 == 0 else 21
        for x0 in range(-21, 64, 42):
            xx = x0 + off
            tone = rnd.choice([STONE, STONE_L, (138, 138, 140)])
            rrect(im, (xx + 1.6, y0 + 1.6, xx + 40.4, y1 - 1.6), 3.2, fill=tone + (255,))
            ell(im, xx + 12, y0 + 6.5, 7, 2.6, fill=A(STONE_L, 110))
    speck(im, seed + 1, 80, [A(STONE_D, 85), A(STONE_L, 90)], 0.35, 0.9)
    return im

def stone_floor_im(seed):
    im = base_fill((116, 114, 112))
    d = ImageDraw.Draw(im)
    rnd = random.Random(seed)
    for ri, (y0, y1) in enumerate([(0, 32), (32, 64)]):
        off = 0 if ri == 0 else 16
        for x0 in range(-16, 64, 32):
            xx = x0 + off
            tone = rnd.choice([(128, 126, 124), (120, 118, 118), (134, 132, 128)])
            rrect(im, (xx + 1.8, y0 + 1.8, xx + 30.2, y1 - 1.8), 4, fill=tone + (255,))
            ell(im, xx + 10, y0 + 8, 6, 2.4, fill=A(STONE_L, 90))
    speck(im, seed + 3, 120, [A(STONE_D, 120), A((90, 88, 88), 110)], 0.4, 1.0)
    return im

def rug_im(seed):
    im = base_fill((146, 52, 48))
    d = ImageDraw.Draw(im)
    d.rectangle([3 * SS, 3 * SS, 61 * SS, 61 * SS], outline=(226, 190, 130, 255), width=int(1.6 * SS))
    d.rectangle([7 * SS, 7 * SS, 57 * SS, 57 * SS], outline=A((226, 190, 130), 200), width=int(1.0 * SS))
    cx, cy = 32, 32                                            # hoa văn thoi ở tâm (đối xứng 4 phía -> nối được)
    poly(im, [(cx, cy - 13), (cx + 13, cy), (cx, cy + 13), (cx - 13, cy)], outline=(240, 205, 140, 255), ow=1.5)
    poly(im, [(cx, cy - 7), (cx + 7, cy), (cx, cy + 7), (cx - 7, cy)], fill=A((196, 96, 60), 220))
    for (px, py) in [(10, 10), (54, 10), (10, 54), (54, 54)]:
        ell(im, px, py, 2.2, 2.2, fill=(240, 205, 140, 220))
    speck(im, seed, 90, [A((110, 38, 36), 130), A((176, 84, 66), 120)], 0.4, 0.9)
    return im

def build_interior():
    tiles = {}
    tiles["floor_a"] = wood_floor_im(11)
    tiles["floor_b"] = wood_floor_im(22, vertical=True)
    tiles["floor_dark"] = wood_floor_im(33, dark=True)
    tiles["wall_plank"] = wall_plank_im(44)
    tiles["wall_stone"] = wall_stone_im(55)
    tiles["stone_floor"] = stone_floor_im(66)
    tiles["rug"] = rug_im(77)
    tiles["floor_c"] = wood_floor_im(88)
    return tiles

INTERIOR_ORDER = ["floor_a", "floor_b", "floor_dark", "wall_plank",
                  "wall_stone", "stone_floor", "rug", "floor_c"]

# ============================================================ PROP NGOÀI TRỜI

def draw_canopy(im, cx, cy, R, seed, dark_base=False):
    """Tán lá: nhiều lớp ellipse chồng nhau tối->sáng, điểm sáng lá, đốm tối tạo chiều sâu."""
    rnd = random.Random(seed)
    blobs = []
    n = 26
    for i in range(n):
        a = rnd.uniform(0, 2 * math.pi)
        rr = math.sqrt(rnd.uniform(0, 1)) * R * 0.72
        bx, by = cx + rr * math.cos(a) * 1.12, cy + rr * math.sin(a) * 0.82
        br = R * rnd.uniform(0.34, 0.55)
        blobs.append((bx, by, br))
    for (bx, by, br) in blobs:  # lớp bóng dưới-phải
        ell(im, bx + R * 0.05, by + R * 0.07, br, br * 0.88, fill=(58, 122, 54, 255))
    for (bx, by, br) in blobs:  # lớp chính
        ell(im, bx, by, br, br * 0.88, fill=LEAF + (255,))
    for (bx, by, br) in blobs:  # lớp sáng trên-trái
        ell(im, bx - br * 0.24, by - br * 0.3, br * 0.62, br * 0.52, fill=LEAF_L + (235,))
    rnd2 = random.Random(seed + 5)
    for _ in range(int(R * 2.6)):  # điểm sáng lá
        a = rnd2.uniform(0, 2 * math.pi); rr = math.sqrt(rnd2.uniform(0, 1)) * R * 0.8
        x, y = cx + rr * math.cos(a) * 1.1, cy + rr * math.sin(a) * 0.8 - R * 0.12
        ell(im, x, y, rnd2.uniform(1.0, 2.2), rnd2.uniform(0.8, 1.6), fill=A(LEAF_HI, 190))
    for _ in range(int(R * 0.9)):  # đốm tối sâu trong tán
        a = rnd2.uniform(0, 2 * math.pi); rr = math.sqrt(rnd2.uniform(0, 1)) * R * 0.62
        x, y = cx + rr * math.cos(a), cy + rr * math.sin(a) * 0.8 + R * 0.16
        ell(im, x, y, rnd2.uniform(1.6, 3.2), rnd2.uniform(1.2, 2.4), fill=A(LEAF_D, 130))

def draw_trunk(im, cx, base_y, top_y, w_bot, w_top, seed):
    pts = [(cx - w_top / 2, top_y), (cx + w_top / 2, top_y),
           (cx + w_bot / 2 + 4, base_y), (cx + w_bot / 2 - 2, base_y - 6),
           (cx - w_bot / 2 + 2, base_y - 6), (cx - w_bot / 2 - 4, base_y)]
    poly(im, pts, fill=(110, 78, 50, 255))
    rnd = random.Random(seed)
    for _ in range(16):  # thớ vỏ dọc
        x = cx + rnd.uniform(-w_bot / 2 + 2, w_bot / 2 - 2)
        y0 = rnd.uniform(top_y + 4, base_y - 16)
        line(im, (x, y0), (x + rnd.uniform(-1.5, 1.5), y0 + rnd.uniform(6, 14)),
             A((74, 50, 30), 170), 1.2)
    for _ in range(7):   # vệt sáng vỏ
        x = cx + rnd.uniform(-w_bot / 2 + 1, -1)
        y0 = rnd.uniform(top_y + 6, base_y - 14)
        line(im, (x, y0), (x + 0.8, y0 + rnd.uniform(5, 10)), A((158, 120, 80), 150), 1.1)
    # rễ toả
    for dx in (-1, -0.35, 0.4, 1):
        poly(im, [(cx + dx * w_bot * 0.28, base_y - 7), (cx + dx * w_bot * 0.62, base_y),
                  (cx + dx * w_bot * 0.2, base_y)], fill=(96, 66, 42, 255))
    # cành vươn vào tán
    line(im, (cx, top_y + 12), (cx - 16, top_y - 12), (96, 66, 42, 255), 4.2)
    line(im, (cx, top_y + 10), (cx + 15, top_y - 14), (96, 66, 42, 255), 3.8)

def prop_oak():
    w, h = 208, 216
    im = canvas(w, h)
    soft_shadow(im, 104, 203, 58, 10, 68)
    draw_trunk(im, 104, 206, 102, 24, 13, 5)
    draw_canopy(im, 104, 70, 62, 12)
    return finish(im, w, h)

def prop_small_tree():
    w, h = 128, 152
    im = canvas(w, h)
    soft_shadow(im, 64, 140, 35, 7, 62)
    draw_trunk(im, 64, 142, 84, 12, 7, 8)
    draw_canopy(im, 64, 52, 40, 21)
    rnd = random.Random(31)  # quả đỏ điểm xuyết
    for _ in range(9):
        a = rnd.uniform(0, 2 * math.pi); rr = math.sqrt(rnd.uniform(0, 1)) * 30
        ell(im, 64 + rr * math.cos(a) * 1.1, 54 + rr * math.sin(a) * 0.8, 2.3, 2.3,
            fill=(206, 64, 54, 255))
        ell(im, 63 + rr * math.cos(a) * 1.1, 53 + rr * math.sin(a) * 0.8, 0.8, 0.8,
            fill=(250, 190, 170, 255))
    return finish(im, w, h)

def prop_bush():
    w, h = 96, 76
    im = canvas(w, h)
    soft_shadow(im, 48, 66, 35, 6, 52)
    draw_canopy(im, 48, 40, 30, 33)
    rnd = random.Random(41)  # quả mọng tím
    for _ in range(7):
        ell(im, rnd.uniform(24, 72), rnd.uniform(26, 54), 1.9, 1.9, fill=(128, 84, 168, 255))
    return finish(im, w, h)

def prop_boulder():
    w, h = 84, 66
    im = canvas(w, h)
    soft_shadow(im, 42, 57, 33, 6, 58)
    # khối phụ trái + phải, khối chính giữa-trên
    ell(im, 24, 42, 17, 13, fill=(138, 138, 140, 255), outline=STONE_D + (255,), ow=1.2)
    ell(im, 60, 44, 15, 11.5, fill=(142, 142, 144, 255), outline=STONE_D + (255,), ow=1.2)
    ell(im, 42, 36, 21, 17, fill=STONE + (255,), outline=STONE_D + (255,), ow=1.3)
    ell(im, 35, 27, 9.5, 5.6, fill=A(STONE_L, 200))            # mảng sáng trên-trái
    ell(im, 55, 31, 6.5, 4.2, fill=A(STONE_L, 140))
    ell(im, 42, 49, 18, 4.6, fill=A(STONE_D, 105))            # tối chân đá
    line(im, (30, 40), (38, 47), A(STONE_D, 130), 1.0)        # vết nứt nhỏ
    speck(im, 55, 26, [A(STONE_D, 110), A(STONE_L, 110)], 0.35, 0.8, wrap=False)
    for (mx, my) in [(18, 52), (64, 53), (36, 55)]:           # rêu chân đá
        ell(im, mx, my, 4.5, 2.1, fill=A(LEAF, 185))
    return finish(im, w, h)

def prop_barrel(w=46, h=54, wine=False):
    im = canvas(w, h)
    soft_shadow(im, w / 2, h - 4, w * 0.42, 4, 52)
    cx = w / 2
    body = [(cx - 15, 8), (cx + 15, 8), (cx + 18.5, h / 2), (cx + 14, h - 8), (cx - 14, h - 8), (cx - 18.5, h / 2)]
    poly(im, body, fill=WOOD + (255,), outline=WOOD_XD + (255,), ow=1.2)
    d = ImageDraw.Draw(im)
    for dx in (-9.5, -3.2, 3.2, 9.5):  # nan gỗ dọc cong theo thân
        pts = []
        for k in range(13):
            t = k / 12
            bulge = math.sin(t * math.pi) * 3.4
            pts.append(((cx + dx * (0.82 + 0.18 * math.sin(t * math.pi)) + (bulge if dx > 0 else -bulge) * abs(dx) / 10) * SS,
                        (8 + t * (h - 16)) * SS))
        d.line(pts, fill=A(WOOD_D, 170), width=int(1.0 * SS))
    ell(im, cx, 8.5, 15, 4.6, fill=WOOD_L + (255,), outline=WOOD_XD + (255,), ow=1.1)
    ell(im, cx, 8.5, 8.5, 2.4, fill=A(WOOD_D, 160))
    for hy in (16.5, h - 17.5):  # đai sắt
        d.rectangle([(cx - 18.6) * SS, (hy - 1.7) * SS, (cx + 18.6) * SS, (hy + 1.7) * SS],
                    fill=(70, 70, 78, 255))
        d.rectangle([(cx - 18.6) * SS, (hy - 1.7) * SS, (cx + 18.6) * SS, (hy - 0.5) * SS],
                    fill=(120, 120, 130, 200))
    return finish(im, w, h)

def prop_sack():
    w, h = 48, 50
    im = canvas(w, h)
    soft_shadow(im, 24, 44, 18, 4, 52)
    poly(im, ell_pts(24, 31, 16.5, 13.5), fill=(186, 158, 116, 255), outline=(140, 114, 78, 255), ow=1.2)
    ell(im, 17, 24, 6.5, 8.5, fill=A((214, 188, 142), 170))
    poly(im, [(19, 19), (29, 19), (26.5, 10), (21.5, 10)], fill=(168, 138, 98, 255),
         outline=(140, 114, 78, 255), ow=1.1)  # cổ bao
    line(im, (18.5, 18.5), (29.5, 18.5), (120, 84, 50, 255), 2.2)  # dây buộc
    line(im, (24, 18.5), (27, 13.5), (120, 84, 50, 255), 1.6)
    speck(im, 66, 40, [A((150, 124, 88), 130)], 0.4, 0.9, wrap=False)
    return finish(im, w, h)

def prop_well():
    w, h = 116, 118
    im = canvas(w, h)
    soft_shadow(im, 58, 106, 45, 8, 52)
    d = ImageDraw.Draw(im)
    # thân giếng đá (elip phối cảnh)
    d.rectangle([26 * SS, 66 * SS, 90 * SS, 100 * SS], fill=STONE + (255,))
    ell(im, 58, 100, 32, 9, fill=(128, 128, 132, 255))
    d.rectangle([26 * SS, 82 * SS, 90 * SS, 84 * SS], fill=A(STONE_D, 150))
    for jx in (42, 58, 74):
        d.rectangle([jx * SS, 70 * SS, (jx + 1.4) * SS, 82 * SS], fill=A(STONE_D, 130))
        d.rectangle([jx * SS, 84 * SS, (jx + 1.4) * SS, 97 * SS], fill=A(STONE_D, 110))
    ell(im, 58, 68, 33, 10.5, fill=STONE_L + (255,), outline=STONE_D + (255,), ow=1.3)
    ell(im, 58, 68, 24.5, 7.2, fill=(28, 44, 58, 255))
    ell(im, 52, 66.4, 8, 2.2, fill=A(WATER_L, 150))
    rnd = random.Random(71)  # viên đá trên thân
    for _ in range(12):
        sx, sy = rnd.uniform(30, 84), rnd.uniform(74, 96)
        ell(im, sx, sy, rnd.uniform(2.5, 4.5), rnd.uniform(1.6, 2.8), fill=A(STONE_D, 120))
    # 2 cột + trục quay + mái
    for px in (27, 89):
        rrect(im, (px - 3, 26, px + 3, 72), 1.6, fill=WOOD + (255,), outline=WOOD_XD + (255,), ow=1.0)
    line(im, (27, 33), (89, 33), WOOD_D + (255,), 3.4)
    ell(im, 58, 33, 4.4, 4.4, fill=WOOD_XD + (255,))
    line(im, (58, 33), (58, 52), (90, 70, 44, 255), 1.5)  # dây thừng
    rrect(im, (51, 52, 65, 65), 2, fill=WOOD + (255,), outline=WOOD_XD + (255,), ow=1.1)  # gàu
    d.rectangle([51 * SS, 55 * SS, 65 * SS, 57 * SS], fill=(70, 70, 78, 255))
    roof = [(14, 30), (102, 30), (84, 8), (32, 8)]
    poly(im, roof, fill=ROOF + (255,), outline=ROOF_D + (255,), ow=1.3)
    for k in range(4):  # hàng ngói mái giếng
        y = 13.5 + k * 4.4
        line(im, (32 + k * 1.5, y), (84 - k * 1.5, y), A(ROOF_D, 170), 1.1)
    line(im, (20, 29), (96, 29), A(ROOF_L, 200), 1.6)
    return finish(im, w, h)

def shingle_layer(w, h, y0, y1, x_left, x_right, seed):
    """Lớp ngói: hàng vảy ngói so le, dùng làm layer rồi clip theo hình mái."""
    layer = canvas(w, h)
    d = ImageDraw.Draw(layer)
    rnd = random.Random(seed)
    row_h = 15
    rows = int((y1 - y0) / row_h) + 1
    for r_ in range(rows):
        y = y0 + r_ * row_h
        tone = ROOF if r_ % 2 == 0 else (120, 70, 46)
        d.rectangle([0, y * SS, w * SS, (y + row_h) * SS], fill=tone + (255,))
        off = 0 if r_ % 2 == 0 else 10
        for x in range(-22 + off, int(w) + 22, 19):
            d.arc([(x) * SS, (y + 2) * SS, (x + 22) * SS, (y + 2 + 20) * SS],
                  0, 180, fill=ROOF_D + (235,), width=int(2.0 * SS))
            d.arc([(x) * SS, (y + 0.5) * SS, (x + 22) * SS, (y + 0.5 + 20) * SS],
                  0, 180, fill=A(ROOF_L, 150), width=int(1.0 * SS))
    speck(layer, seed, 260, [A(ROOF_D, 110), A(ROOF_L, 100)], 0.5, 1.2, wrap=False)
    return layer

def prop_house():
    w, h = 320, 264
    im = canvas(w, h)
    soft_shadow(im, 168, 244, 150, 12, 72)
    d = ImageDraw.Draw(im)
    # móng đá
    rrect(im, (36, 208, 292, 238), 5, fill=STONE + (255,), outline=STONE_D + (255,), ow=1.3)
    for (sx, sy, sr) in [(70, 222, 9), (130, 226, 11), (200, 220, 10), (258, 225, 9), (100, 216, 7)]:
        ell(im, sx, sy, sr, sr * 0.55, fill=A(STONE_L, 170))
    # tường thạch cao + khung gỗ
    rrect(im, (46, 100, 282, 214), 3, fill=PLASTER + (255,))
    speck(im, 909, 200, [A((214, 202, 172), 120), A((250, 244, 224), 110)], 0.5, 1.2, wrap=False)
    beams = [(46, 100, 58, 214), (270, 100, 282, 214), (46, 100, 282, 113),
             (46, 196, 282, 208), (150, 113, 162, 196), (196, 113, 208, 196)]
    for (x0, y0, x1, y1) in beams:
        d.rectangle([x0 * SS, y0 * SS, x1 * SS, y1 * SS], fill=WOOD_D + (255,))
    line(im, (58, 196), (150, 113), WOOD_D + (255,), 7)   # thanh chéo
    line(im, (270, 196), (208, 113), WOOD_D + (255,), 7)
    # mái ngói lớn
    roof_mask = Image.new("L", (int(w * SS), int(h * SS)), 0)
    ImageDraw.Draw(roof_mask).polygon(P_([(22, 120), (298, 120), (248, 36), (72, 36)]), fill=255)
    layer = shingle_layer(w, h, 32, 122, 22, 298, 913)
    im.paste(Image.composite(layer, canvas(w, h), roof_mask), (0, 0))
    poly(im, [(22, 120), (298, 120), (248, 36), (72, 36)], outline=ROOF_D + (255,), ow=2.0)
    d.rectangle([66 * SS, 29 * SS, 254 * SS, 38 * SS], fill=WOOD_XD + (255,))  # nóc mái
    d.rectangle([66 * SS, 29 * SS, 254 * SS, 32.5 * SS], fill=A(WOOD_L, 190))
    d.rectangle([22 * SS, 116 * SS, 298 * SS, 122 * SS], fill=WOOD_XD + (255,))  # viền mái hiên
    # ống khói đá + khói
    rrect(im, (224, 14, 252, 60), 2, fill=STONE + (255,), outline=STONE_D + (255,), ow=1.2)
    d.rectangle([220 * SS, 11 * SS, 256 * SS, 18 * SS], fill=STONE_D + (255,))
    smoke = canvas(w, h)
    for (sx, sy, sr, sa) in [(243, -2, 7, 90), (250, -14, 10, 65), (259, -28, 13, 42)]:
        ell(smoke, sx, sy + 34, sr, sr * 0.8, fill=(245, 245, 245, sa))
    smoke = smoke.filter(ImageFilter.GaussianBlur(2.2 * SS))
    im.alpha_composite(smoke)
    # cửa chính vòm
    d.rectangle([102 * SS, 144 * SS, 140 * SS, 214 * SS], fill=WOOD_D + (255,))
    ell(im, 121, 144, 19, 14, fill=WOOD_D + (255,))
    d.rectangle([106 * SS, 148 * SS, 136 * SS, 210 * SS], fill=WOOD + (255,))
    ell(im, 121, 148, 15, 11, fill=WOOD + (255,))
    for lx in (114.5, 121, 127.5):
        line(im, (lx, 144), (lx, 210), A(WOOD_XD, 200), 1.1)
    ell(im, 131, 184, 2.6, 2.6, fill=(52, 44, 34, 255)); ell(im, 131, 184, 1.2, 1.2, fill=(200, 180, 90, 255))
    rrect(im, (96, 212, 146, 220), 2, fill=STONE + (255,), outline=STONE_D + (255,), ow=1.0)  # bậc thềm
    # cửa sổ ấm sáng + bậu hoa
    for wx in (66, 216):
        rrect(im, (wx, 130, wx + 38, 170), 2.5, fill=WOOD_XD + (255,))
        rrect(im, (wx + 3.5, 133.5, wx + 34.5, 166.5), 2, fill=(252, 208, 116, 255,))
        d.rectangle([(wx + 17.5) * SS, 133.5 * SS, (wx + 20.5) * SS, 166.5 * SS], fill=WOOD_XD + (255,))
        d.rectangle([(wx + 3.5) * SS, 148 * SS, (wx + 34.5) * SS, 151 * SS], fill=WOOD_XD + (255,))
        ell(im, wx + 10, 141, 4.5, 3.2, fill=A((255, 240, 190), 200))
        rrect(im, (wx - 2, 170, wx + 40, 178), 2, fill=WOOD + (255,), outline=WOOD_XD + (255,), ow=1.0)
        for fx in range(4):
            ell(im, wx + 4 + fx * 9, 169, 3.1, 3.4, fill=(86, 150, 66, 255))
            ell(im, wx + 6 + fx * 9, 167.4, 1.9, 1.9, fill=(226, 92, 108, 255))
    return finish(im, w, h)

# ============================================================ PROP NỘI THẤT

def prop_table():
    w, h = 168, 118
    im = canvas(w, h)
    soft_shadow(im, 84, 100, 67, 9, 58)
    d = ImageDraw.Draw(im)
    # 2 ghế (nhìn 3/4 từ trên): lưng ghế + mặt ngồi
    for gx in (26, 118):
        rrect(im, (gx, 6, gx + 24, 20), 3, fill=WOOD_D + (255,), outline=WOOD_XD + (255,), ow=1.1)
        rrect(im, (gx + 1, 18, gx + 23, 38), 3, fill=WOOD + (255,), outline=WOOD_XD + (255,), ow=1.1)
        rrect(im, (gx, 84, gx + 24, 98), 3, fill=WOOD_D + (255,), outline=WOOD_XD + (255,), ow=1.1)
        rrect(im, (gx + 1, 78, gx + 23, 96), 3, fill=WOOD + (255,), outline=WOOD_XD + (255,), ow=1.1)
    # mặt bàn
    rrect(im, (34, 26, 134, 88), 6, fill=WOOD + (255,), outline=WOOD_XD + (255,), ow=1.6)
    rrect(im, (38, 30, 130, 84), 5, fill=WOOD_L + (165,))
    for gy in (42, 57, 72):
        line(im, (40, gy), (128, gy), A(WOOD_D, 130), 1.0)
    # cốc bia + nến trên bàn
    for (mx, my) in [(58, 46), (104, 64)]:
        rrect(im, (mx, my, mx + 10, my + 13), 2, fill=(196, 150, 84, 255), outline=WOOD_XD + (255,), ow=1.0)
        ell(im, mx + 5, my + 1.5, 5, 2.2, fill=(246, 226, 170, 255))
    ell(im, 86, 52, 3.4, 3.4, fill=(250, 214, 130, 255))
    ell(im, 86, 52, 6.5, 6.5, fill=A((255, 180, 80), 70))
    rrect(im, (83.8, 55, 88.2, 64), 1, fill=(238, 232, 218, 255), outline=(170, 160, 140, 255), ow=0.7)
    return finish(im, w, h)

def prop_bar():
    w, h = 232, 92
    im = canvas(w, h)
    soft_shadow(im, 116, 84, 107, 7, 58)
    d = ImageDraw.Draw(im)
    # thân quầy
    rrect(im, (6, 30, 226, 82), 4, fill=(104, 68, 38, 255), outline=WOOD_XD + (255,), ow=1.5)
    for px in range(5):  # ô ván trang trí mặt trước
        x0 = 16 + px * 42
        rrect(im, (x0, 42, x0 + 32, 72), 3, fill=A(WOOD_D, 190), outline=A(WOOD_XD, 220), ow=1.1)
        ell(im, x0 + 16, 57, 2.0, 2.0, fill=(196, 158, 84, 255))
    # mặt quầy sáng + gờ
    rrect(im, (2, 20, 230, 34), 4, fill=WOOD_L + (255,), outline=WOOD_XD + (255,), ow=1.4)
    d.rectangle([2 * SS, 20 * SS, 230 * SS, 24 * SS], fill=A((214, 172, 116), 200))
    # chai + cốc trên mặt quầy
    rnd = random.Random(97)
    bcols = [(84, 130, 74), (122, 84, 52), (70, 104, 140), (150, 96, 60)]
    for bx in (30, 52, 168, 192):
        bc = rnd.choice(bcols)
        rrect(im, (bx, 4, bx + 8, 21), 2, fill=bc + (255,), outline=A((30, 30, 30), 160), ow=0.8)
        d.rectangle([(bx + 2.6) * SS, 0, (bx + 5.4) * SS, 5 * SS], fill=bc + (255,))
        ell(im, bx + 2.4, 9, 1.4, 3.4, fill=A((255, 255, 255), 110))
    for mx in (96, 116):
        rrect(im, (mx, 10, mx + 10, 21), 2, fill=(196, 150, 84, 255), outline=WOOD_XD + (255,), ow=0.9)
        ell(im, mx + 5, 11, 5, 2, fill=(246, 226, 170, 255))
    return finish(im, w, h)

def flame(im, cx, base_y, hgt, wid, col):
    pts = [(cx - wid, base_y), (cx - wid * 0.62, base_y - hgt * 0.45),
           (cx - wid * 0.22, base_y - hgt * 0.72), (cx, base_y - hgt),
           (cx + wid * 0.3, base_y - hgt * 0.66), (cx + wid * 0.62, base_y - hgt * 0.42),
           (cx + wid, base_y)]
    poly(im, pts, fill=col)

def prop_fireplace():
    w, h = 152, 148
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    # hào quang lửa (dưới cùng)
    glow = canvas(w, h)
    ell(glow, 76, 96, 62, 44, fill=(255, 166, 66, 66))
    glow = glow.filter(ImageFilter.GaussianBlur(6 * SS))
    im.alpha_composite(glow)
    # khung đá + bệ
    rrect(im, (14, 18, 138, 132), 6, fill=STONE + (255,), outline=STONE_D + (255,), ow=1.6)
    rnd = random.Random(53)
    for _ in range(16):
        sx, sy = rnd.uniform(20, 128), rnd.uniform(24, 52)
        ell(im, sx, sy, rnd.uniform(3, 6), rnd.uniform(2, 3.4), fill=A(STONE_L, 130))
    rrect(im, (8, 128, 144, 140), 4, fill=STONE_D + (255,))
    # họng lò vòm
    d.rectangle([44 * SS, 62 * SS, 108 * SS, 130 * SS], fill=(26, 20, 18, 255))
    poly(im, ell_pts(76, 62, 32, 20) , fill=(26, 20, 18, 255))
    poly(im, ell_pts(76, 62, 32, 20), outline=STONE_D + (255,), ow=2.0)
    # củi
    for (lx, ang) in [(62, -14), (88, 12), (76, 2)]:
        line(im, (lx - 11, 124), (lx + 11, 124 - ang * 0.4), (96, 62, 34, 255), 6.4)
        ell(im, lx + 11, 124 - ang * 0.4, 3.1, 3.1, fill=(196, 152, 104, 255))
    # lửa 3 lớp
    flame(im, 76, 126, 44, 17, (232, 106, 34, 255))
    flame(im, 73, 126, 33, 12, (246, 160, 52, 255))
    flame(im, 77, 126, 21, 7.5, (252, 220, 130, 255))
    flame(im, 76, 126, 11, 4, (255, 246, 214, 255))
    for _ in range(6):  # tia lửa bay
        ex, ey = rnd.uniform(58, 94), rnd.uniform(66, 96)
        ell(im, ex, ey, 1.1, 1.1, fill=(255, 190, 90, 230))
    # mặt lò (mantel) gỗ + 2 bình gốm nhỏ trang trí
    rrect(im, (10, 8, 142, 20), 3, fill=WOOD_D + (255,), outline=WOOD_XD + (255,), ow=1.2)
    for nx, bc in [(34, (122, 84, 52)), (112, (70, 104, 140))]:
        rrect(im, (nx, 1.5, nx + 6.4, 8.6), 1.6, fill=bc + (255,), outline=A((30, 30, 30), 140), ow=0.7)
    return finish(im, w, h)

def prop_lamp():
    w, h = 64, 84
    im = canvas(w, h)
    glow = canvas(w, h)
    ell(glow, 32, 52, 27, 27, fill=(255, 186, 84, 74))
    glow = glow.filter(ImageFilter.GaussianBlur(4.5 * SS))
    im.alpha_composite(glow)
    d = ImageDraw.Draw(im)
    d.line([32 * SS, 0, 32 * SS, 26 * SS], fill=(52, 46, 40, 255), width=int(1.8 * SS))
    for k in range(3):
        ell(im, 32, 6 + k * 7, 1.6, 2.6, outline=(52, 46, 40, 255), ow=1.1)
    poly(im, [(20, 34), (44, 34), (38, 24), (26, 24)], fill=(70, 66, 62, 255), outline=(40, 38, 34, 255), ow=1.1)
    rrect(im, (23, 34, 41, 56), 3, fill=(250, 200, 104, 255), outline=(52, 46, 40, 255), ow=1.4)
    flame(im, 32, 53, 13, 4.6, (246, 160, 52, 255))
    flame(im, 32, 53, 8, 2.8, (255, 240, 190, 255))
    d.rectangle([23 * SS, 40 * SS, 41 * SS, 42 * SS], fill=A((52, 46, 40), 200))
    poly(im, [(24, 62), (40, 62), (36, 56), (28, 56)], fill=(70, 66, 62, 255))
    return finish(im, w, h)

def prop_shelf():
    w, h = 104, 72
    im = canvas(w, h)
    soft_shadow(im, 52, 66, 46, 5, 70)
    d = ImageDraw.Draw(im)
    rnd = random.Random(61)
    bcols = [(84, 130, 74), (122, 84, 52), (70, 104, 140), (150, 96, 60), (104, 74, 130)]
    for shelf_y in (26, 52):
        for bx in range(10, 92, 13):
            bc = rnd.choice(bcols)
            hh = rnd.uniform(13, 18)
            rrect(im, (bx, shelf_y - hh, bx + 8, shelf_y), 2, fill=bc + (255,),
                  outline=A((30, 30, 30), 150), ow=0.8)
            ell(im, bx + 2.2, shelf_y - hh + 4, 1.3, 3.2, fill=A((255, 255, 255), 110))
        d.rectangle([6 * SS, shelf_y * SS, 98 * SS, (shelf_y + 3.4) * SS], fill=WOOD_D + (255,))
        d.rectangle([6 * SS, shelf_y * SS, 98 * SS, (shelf_y + 1.2) * SS], fill=A(WOOD_L, 200))
    for px in (8, 92):
        d.rectangle([px * SS, 4 * SS, (px + 3.4) * SS, 62 * SS], fill=WOOD_XD + (255,))
    return finish(im, w, h)

# ============================================================ LẮP ATLAS + .tres + MOCKUP

def save_atlas(tiles, order, cols, path_png, path_tres, res_path):
    rows = math.ceil(len(order) / cols)
    atlas = Image.new("RGBA", (cols * T, rows * T), (0, 0, 0, 0))
    for i, name in enumerate(order):
        tile = finish(tiles[name], T)
        atlas.alpha_composite(tile, ((i % cols) * T, (i // cols) * T))
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

def tile_get(atlas, order, name):
    i = order.index(name)
    cols = 8 if len(order) > 8 else 4
    return atlas.crop(((i % cols) * T, (i // cols) * T, (i % cols) * T + T, (i // cols) * T + T))

def paste(scene, im, x, y):
    scene.alpha_composite(im, (int(x), int(y)))

def build_village_mockup(ext_atlas, props, player_frame):
    cols, rows = 15, 10
    scene = Image.new("RGBA", (cols * T, rows * T), (0, 0, 0, 255))
    G = lambda n: tile_get(ext_atlas, EXTERIOR_ORDER, n)
    # nền cỏ: rải biến thể có chủ đích
    layout_var = {}
    for (x, y) in [(1, 1), (6, 2), (11, 1), (3, 7), (13, 4), (8, 8), (0, 4), (5, 5)]:
        layout_var[(x, y)] = "grass_flower"
    for (x, y) in [(2, 3), (10, 6), (12, 8), (4, 1), (7, 7), (13, 2)]:
        layout_var[(x, y)] = "grass_tall"
    for (x, y) in [(9, 3), (1, 6), (12, 5)]:
        layout_var[(x, y)] = "grass_sparse"
    for y in range(rows):
        for x in range(cols):
            paste(scene, G(layout_var.get((x, y), "grass")), x * T, y * T)
    # ao nước góc dưới-trái + bờ (shore_s = cỏ trên/nước dưới: đặt ở cạnh bắc của ao)
    pond = {(0, 8): "shore_s", (1, 8): "shore_s", (0, 9): "water_a", (1, 9): "water_b",
            (2, 8): "shore_w", (2, 9): "shore_w"}
    for (x, y), n in pond.items():
        paste(scene, G(n), x * T, y * T)
    # đường đất: ngang hàng 5 (cặp path_s/path_n) rồi rẽ lên nhà
    for x in range(0, 15):
        paste(scene, G("path_s"), x * T, 5 * T)
        paste(scene, G("path_n"), x * T, 6 * T)
    for y in (2, 3, 4):  # nhánh dọc lên cửa nhà (cặp path_e/path_w), đầu trên bị nhà che
        paste(scene, G("path_e"), 5 * T, y * T)
        paste(scene, G("path_w"), 6 * T, y * T)
    # ruộng dưới-phải + rào bao
    for y in (7, 8):
        for x in (11, 12, 13):
            paste(scene, G("field"), x * T, y * T)
    for x in (11, 12, 13):  # rào ở mép nam của ruộng
        paste(scene, G("fence_h"), x * T, 9 * T)
    paste(scene, G("pebbles"), 3 * T, 2 * T)

    # ---- prop theo thứ tự Y-sort (vẽ từ bắc xuống nam) ----
    house = props["house"]
    paste(scene, house, 4 * T - 8, 0)                       # nhà ở phía bắc (tiles 4..8)
    paste(scene, props["well"], 9 * T + 6, 1 * T + 26)      # giếng cạnh nhà
    paste(scene, props["barrel"], 8 * T + 30, 2 * T + 40)
    paste(scene, props["sack"], 8 * T + 62, 2 * T + 52)
    paste(scene, props["small_tree"], 12 * T + 8, 1 * T + 4)
    paste(scene, props["bush"], 1 * T + 8, 3 * T + 22)
    paste(scene, props["boulder"], 3 * T + 6, 6 * T + 8)
    # player đứng SAU cây sồi (vẽ player trước, cây sau -> tán/trunk che một phần = Y-sort)
    oak = props["oak"]
    oak_x, oak_y = 1 * T + 2, 1 * T + 30                     # gốc cây ~ (66+104, 94+216) -> trunk ở x~170
    pl = player_frame.resize((84, 84), Image.LANCZOS)
    # bóng player
    sh = Image.new("RGBA", scene.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([206, 268, 250, 280], fill=(20, 26, 16, 80))
    scene.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3)))
    paste(scene, pl, 186, 196)                               # chân player ~ y 280, đầu khuất sau tán cây
    paste(scene, oak, oak_x, oak_y)                          # cây vẽ sau -> che player
    paste(scene, props["bush"], 13 * T + 16, 3 * T + 30)
    return scene

def build_tavern_mockup(int_atlas, props):
    cols, rows = 11, 8
    scene = Image.new("RGBA", (cols * T, rows * T), (24, 18, 14, 255))
    G = lambda n: tile_get(int_atlas, INTERIOR_ORDER, n)
    # tường: hàng 0 = wall_plank, 2 đầu = wall_stone; dải tối dưới tường (bóng chân tường)
    for x in range(cols):
        paste(scene, G("wall_stone" if x in (0, cols - 1) else "wall_plank"), x * T, 0)
    for y in range(1, rows):
        for x in range(cols):
            n = "floor_b" if (x + y) % 7 == 0 else ("floor_dark" if y == 1 else "floor_a")
            paste(scene, G(n), x * T, y * T)
    shade = Image.new("RGBA", scene.size, (0, 0, 0, 0))
    ImageDraw.Draw(shade).rectangle([0, 64, cols * T, 84], fill=(0, 0, 0, 70))
    scene.alpha_composite(shade.filter(ImageFilter.GaussianBlur(4)))
    for (x, y) in [(4, 4), (5, 4), (4, 5), (5, 5)]:            # thảm giữa phòng
        paste(scene, G("rug"), x * T, y * T)
    # prop theo Y-sort
    paste(scene, props["fireplace"], 1 * T + 4, 22)            # lò sưởi áp tường trái-trên
    paste(scene, props["shelf"], 3 * T + 12, 30)               # kệ chai trên tường
    paste(scene, props["bar"], 7 * T + 2, 52)                  # quầy bar phải-trên
    paste(scene, props["wine_barrel"], 9 * T + 44, 1 * T + 58)
    paste(scene, props["wine_barrel"], 10 * T + 8, 1 * T + 66)
    paste(scene, props["table"], 2 * T + 2, 4 * T + 6)         # bàn dưới-trái
    paste(scene, props["table"], 7 * T + 6, 5 * T + 2)         # bàn dưới-phải
    paste(scene, props["barrel"], 0 * T + 8, 6 * T + 18)
    paste(scene, props["lamp"], 5 * T + 0, 1 * T + 6)          # đèn treo giữa phòng
    # ám ấm toàn phòng + vignette nhẹ
    warm = Image.new("RGBA", scene.size, (255, 166, 66, 22))
    scene.alpha_composite(warm)
    return scene

def main():
    ext = build_exterior()
    atlas = save_atlas(ext, EXTERIOR_ORDER, 8,
                       os.path.join(TILE_DIR, "exterior_v1.png"),
                       os.path.join(TILE_DIR, "exterior_v1.tres"),
                       "res://assets/tilesets/exterior_v1.png")
    print("exterior atlas:", atlas.size)
    interior = build_interior()
    iatlas = save_atlas(interior, INTERIOR_ORDER, 4,
                        os.path.join(TILE_DIR, "interior_tavern_v1.png"),
                        os.path.join(TILE_DIR, "interior_tavern_v1.tres"),
                        "res://assets/tilesets/interior_tavern_v1.png")
    print("interior atlas:", iatlas.size)

    props = {
        "oak": prop_oak(), "small_tree": prop_small_tree(), "bush": prop_bush(),
        "house": prop_house(), "well": prop_well(), "barrel": prop_barrel(),
        "sack": prop_sack(), "boulder": prop_boulder(),
        "table": prop_table(), "bar": prop_bar(), "fireplace": prop_fireplace(),
        "lamp": prop_lamp(), "shelf": prop_shelf(), "wine_barrel": prop_barrel(52, 60),
    }
    for name, im in props.items():
        im.save(os.path.join(PROP_DIR, name + ".png"))
    print("props:", ", ".join(sorted(props)))

    sheet = Image.open(os.path.join(ROOT, "game", "assets", "sprites", "player_spritesheet.png"))
    player_frame = sheet.crop((0, 0, 128, 128))  # idle_down frame 0

    village = build_village_mockup(atlas, props, player_frame)
    village = village.resize((village.width * 3 // 2, village.height * 3 // 2), Image.LANCZOS)
    village.convert("RGB").save(os.path.join(DESIGN_DIR, "tileset_mockup_v1.png"))
    print("village mockup:", village.size)

    tavern = build_tavern_mockup(iatlas, props)
    tavern = tavern.resize((tavern.width * 3 // 2, tavern.height * 3 // 2), Image.LANCZOS)
    tavern.convert("RGB").save(os.path.join(DESIGN_DIR, "tavern_mockup_v1.png"))
    print("tavern mockup:", tavern.size)

if __name__ == "__main__":
    main()
