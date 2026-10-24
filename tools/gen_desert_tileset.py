#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh tileset SA MẠC v1 cho VÙNG TÂY SOLMARIS.

Kế thừa pipeline supersample 4x + wrap-around texture + transition profile
của tools/gen_tileset_v1.py. Palette: cát vàng cháy, đá sa thạch đỏ/nâu,
xương trắng ngà, nước ốc đảo trong xanh ngọc.

Đầu ra:
- game/assets/tilesets/desert_v1.png + desert_v1.tres (lưới 5x4, tile 64px)
- game/assets/props/palm_tree.png, cactus.png, bone_rib.png,
  tribal_tent.png, campfire.png
- design/solmaris_mockup_v1.png
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_tileset_v1 import (  # noqa: E402
    SS, T, W, A, canvas, poly, ell, line, rrect, finish, soft_shadow,
    speck, blade, ell9, wrapped_blur, base_fill, mask_H, mask_V,
    transition, flame,
)
from PIL import Image, ImageDraw, ImageChops  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TILE_DIR = os.path.join(ROOT, "game", "assets", "tilesets")
PROP_DIR = os.path.join(ROOT, "game", "assets", "props")
DESIGN_DIR = os.path.join(ROOT, "design")
for dd in (TILE_DIR, PROP_DIR, DESIGN_DIR):
    os.makedirs(dd, exist_ok=True)

SAND = (224, 190, 128)
SAND_L = (242, 216, 164)
SAND_D = (198, 160, 96)
SAND_XD = (168, 126, 70)
ROCK = (176, 116, 76)
ROCK_L = (204, 148, 102)
ROCK_D = (132, 82, 52)
EARTH = (190, 148, 92)
EARTH_D = (138, 100, 58)
WATER = (62, 174, 178)
WATER_D = (34, 132, 148)
WATER_L = (142, 226, 218)
BONE = (238, 228, 198)
BONE_D = (204, 190, 154)
DRY = (178, 154, 82)
DRY_D = (138, 116, 54)
STONE = (202, 164, 116)
STONE_L = (226, 196, 142)
STONE_D = (156, 118, 76)


def sand_im(seed, dune=False):
    im = base_fill(SAND)
    ov = canvas(T)
    ell9(ov, 20, 20, 25, 15, A(SAND_L, 46))
    ell9(ov, 50, 52, 23, 14, A(SAND_D, 42))
    ov = wrapped_blur(ov, 2.5 * SS)
    im.alpha_composite(ov)
    if dune:
        d = ImageDraw.Draw(im)
        for y in (18, 38, 56):
            pts = []
            for x in range(0, 65, 4):
                pts.append((x * SS, (y + 3.2 * math.sin(x / 64 * math.pi)) * SS))
            d.line(pts, fill=A(SAND_D, 150), width=int(1.7 * SS))
            pts2 = [(x * SS, (y - 2.0 + 3.2 * math.sin(x / 64 * math.pi)) * SS) for x in range(0, 65, 4)]
            d.line(pts2, fill=A(SAND_L, 130), width=int(1.0 * SS))
    speck(im, seed, 26, [A(SAND_L, 46), A(SAND_D, 44), A(SAND_XD, 18)], 0.25, 0.6)
    return im


def rocky_sand_im(seed):
    im = sand_im(seed)
    rnd = random.Random(seed)
    for _ in range(9):
        x, y = rnd.uniform(5, 59), rnd.uniform(6, 58)
        r = rnd.uniform(2.2, 5.2)
        ell(im, x + 0.8, y + r * 0.45, r, r * 0.4, fill=A(SAND_XD, 105))
        ell(im, x, y, r, r * 0.72, fill=rnd.choice((ROCK, ROCK_L, STONE_D)) + (255,),
            outline=ROCK_D + (255,), ow=0.8)
        ell(im, x - r * 0.3, y - r * 0.25, r * 0.42, r * 0.24, fill=A(STONE_L, 160))
    speck(im, seed + 3, 45, [A(ROCK_D, 130), A(BONE, 110)], 0.4, 1.0)
    return im


def cracked_im(seed):
    im = base_fill(EARTH)
    ov = canvas(T)
    ell9(ov, 22, 20, 25, 15, A(SAND_L, 46))
    ell9(ov, 50, 52, 22, 13, A(EARTH_D, 46))
    ov = wrapped_blur(ov, 2.4 * SS)
    im.alpha_composite(ov)
    rnd = random.Random(seed)
    offs = [(-T, -T), (0, -T), (T, -T), (-T, 0), (0, 0), (T, 0), (-T, T), (0, T), (T, T)]
    for _ in range(10):
        x, y = rnd.uniform(2, 62), rnd.uniform(2, 62)
        pts = [(x, y)]
        for _ in range(rnd.randint(2, 4)):
            x += rnd.uniform(-12, 12)
            y += rnd.uniform(-8, 8)
            pts.append((x, y))
        for dx, dy in offs:
            pp = [(px + dx, py + dy) for px, py in pts]
            for a, b in zip(pp, pp[1:]):
                line(im, a, b, A(EARTH_D, 215), 1.1)
    speck(im, seed + 4, 38, [A(SAND_L, 82), A(EARTH_D, 62)], 0.25, 0.65)
    return im


def oasis_water_im(seed, phase=0.0):
    im = base_fill(WATER)
    ov = canvas(T)
    ell9(ov, 20, 18, 26, 14, A(WATER_L, 58))
    ell9(ov, 50, 52, 24, 13, A(WATER_D, 62))
    ov = wrapped_blur(ov, 2.6 * SS)
    im.alpha_composite(ov)
    d = ImageDraw.Draw(im)
    rnd = random.Random(seed)
    for r_ in range(4):
        y0 = 10 + r_ * 15 + rnd.uniform(-2, 2)
        for seg in range(3):
            x0 = (seg * 22 + phase * 11 + rnd.uniform(-2, 2)) % 64
            pts = []
            for k in range(10):
                xx = x0 + k * 1.35
                pts.append((xx * SS, (y0 + 1.2 * math.sin(k / 9 * math.pi)) * SS))
            for dx in (-T, 0, T):
                d.line([(px + dx * SS, py) for px, py in pts], fill=A(WATER_L, 165), width=int(1.1 * SS))
    speck(im, seed + 6, 18, [A((230, 255, 248), 160)], 0.35, 0.8)
    return im


def dry_grass_im(seed):
    im = sand_im(seed)
    rnd = random.Random(seed + 1)
    offs = [(-T, -T), (0, -T), (T, -T), (-T, 0), (0, 0), (T, 0), (-T, T), (0, T), (T, T)]
    for _ in range(9):
        x, y = rnd.uniform(0, T), rnd.uniform(0, T)
        s = rnd.uniform(5.0, 9.0)
        for dx, dy in offs:
            for _k in range(5):
                ddx = rnd.uniform(-2.6, 2.6)
                blade(im, x + dx + ddx, y + dy, s * rnd.uniform(0.7, 1.2),
                      rnd.choice((DRY_D, DRY, (198, 174, 96))), lean=ddx * 0.4)
    return im


def sandstone_floor_im(seed):
    im = base_fill(STONE)
    d = ImageDraw.Draw(im)
    rnd = random.Random(seed)
    for ri, (y0, y1) in enumerate([(0, 32), (32, 64)]):
        off = 0 if ri == 0 else 16
        for x0 in range(-16, 64, 32):
            xx = x0 + off
            tone = rnd.choice((STONE, STONE_L, (190, 150, 104)))
            rrect(im, (xx + 1.8, y0 + 1.8, xx + 30.2, y1 - 1.8), 3.5, fill=tone + (255,))
            ell(im, xx + 10, y0 + 8, 6, 2.3, fill=A(STONE_L, 95))
    speck(im, seed + 3, 44, [A(STONE_D, 82), A(SAND_D, 72)], 0.3, 0.75)
    d.rectangle([0, 31 * SS, W, 32.2 * SS], fill=A(STONE_D, 130))
    return im


def sandstone_brick_im(seed):
    im = base_fill(ROCK)
    rnd = random.Random(seed)
    rows = [(0, 21), (21, 43), (43, 64)]
    for ri, (y0, y1) in enumerate(rows):
        off = 0 if ri % 2 == 0 else 21
        for x0 in range(-21, 64, 42):
            xx = x0 + off
            tone = rnd.choice((ROCK, ROCK_L, STONE))
            rrect(im, (xx + 1.6, y0 + 1.6, xx + 40.4, y1 - 1.6), 3.0, fill=tone + (255,))
            ell(im, xx + 12, y0 + 6.2, 7, 2.5, fill=A(STONE_L, 105))
    speck(im, seed + 1, 42, [A(ROCK_D, 70), A(STONE_L, 66)], 0.3, 0.7)
    return im


def bone_sand_im(seed):
    im = sand_im(seed)
    rnd = random.Random(seed)
    for _ in range(4):
        x, y = rnd.uniform(10, 54), rnd.uniform(12, 52)
        r = rnd.uniform(5, 9)
        ell(im, x, y, r, r * 0.55, fill=None, outline=BONE + (235,), ow=1.5)
        ell(im, x, y, r * 0.62, r * 0.34, fill=None, outline=BONE_D + (200,), ow=1.1)
    speck(im, seed + 8, 18, [A(BONE, 170), A(BONE_D, 140)], 0.5, 1.2)
    return im


def build_desert():
    tiles = {}
    tiles["sand"] = sand_im(401)
    tiles["sand_dune"] = sand_im(402, dune=True)
    tiles["rocky_sand"] = rocky_sand_im(403)
    tiles["cracked"] = cracked_im(404)
    tiles["water_a"] = oasis_water_im(411, 0.0)
    tiles["water_b"] = oasis_water_im(421, 0.5)
    s = tiles["sand"]
    wt = tiles["water_a"]
    cr = tiles["cracked"]
    H = mask_H(); V = mask_V()
    nH = ImageChops.invert(H); nV = ImageChops.invert(V)
    tiles["shore_s"] = transition(s, wt, H, 431, shore=True)
    tiles["shore_n"] = transition(s, wt, nH, 432, shore=True)
    tiles["shore_w"] = transition(s, wt, nV, 433, shore=True)
    tiles["shore_e"] = transition(s, wt, V, 434, shore=True)
    tiles["shore_cvx"] = transition(s, wt, ImageChops.multiply(H, V), 435, shore=True)
    tiles["shore_ccv"] = transition(s, wt, ImageChops.lighter(H, V), 436, shore=True)
    tiles["dry_grass"] = dry_grass_im(441)
    tiles["sandstone_floor"] = sandstone_floor_im(451)
    tiles["sandstone_brick"] = sandstone_brick_im(461)
    tiles["bone_sand"] = bone_sand_im(471)
    tiles["path_s"] = transition(s, cr, H, 481)
    tiles["path_n"] = transition(s, cr, nH, 482)
    tiles["scrub_sand"] = rocky_sand_im(491)
    tiles["sand_pad"] = sand_im(499)
    return tiles


DESERT_ORDER = [
    "sand", "sand_dune", "rocky_sand", "cracked", "water_a",
    "water_b", "shore_s", "shore_n", "shore_w", "shore_e",
    "shore_cvx", "shore_ccv", "dry_grass", "sandstone_floor", "sandstone_brick",
    "bone_sand", "path_s", "path_n", "scrub_sand", "sand_pad",
]
DESERT_COLS = 5


def prop_palm():
    w, h = 176, 208
    im = canvas(w, h)
    soft_shadow(im, 88, 196, 58, 8, 62)
    # thân cong từng đốt
    pts = []
    for k in range(15):
        t = k / 14
        x = 78 + 22 * math.sin(t * 1.15)
        y = 188 - t * 112
        pts.append((x, y))
    d = ImageDraw.Draw(im)
    d.line([(x * SS, y * SS) for x, y in pts], fill=(126, 88, 52, 255), width=int(9 * SS), joint="curve")
    d.line([(x * SS - 2 * SS, y * SS) for x, y in pts], fill=A((176, 132, 82), 150), width=int(2 * SS), joint="curve")
    for k in range(1, 13):
        x, y = pts[k]
        line(im, (x - 5, y), (x + 5, y - 2), A((84, 56, 32), 180), 1.2)
    cx, cy = pts[-1]
    rnd = random.Random(17)
    for a_deg in (-155, -120, -82, -42, -8, 28, 68, 112, 150):
        a = math.radians(a_deg)
        length = rnd.uniform(48, 66)
        ex, ey = cx + math.cos(a) * length, cy + math.sin(a) * length * 0.52 + 12
        mx, my = cx + math.cos(a) * length * 0.55, cy + math.sin(a) * length * 0.3 - 9
        d.line([cx * SS, cy * SS, mx * SS, my * SS, ex * SS, ey * SS],
               fill=(66, 132, 58, 255), width=int(3.2 * SS), joint="curve")
        for t in (0.35, 0.55, 0.75, 0.92):
            x = cx + (ex - cx) * t
            y = cy + (ey - cy) * t + math.sin(t * math.pi) * -4
            line(im, (x, y), (x + 3, y + 7), A((46, 104, 44), 190), 1.0)
    for dx in (-6, 2, 9):
        ell(im, cx + dx, cy + 8, 5, 5, fill=(112, 76, 38, 255), outline=(76, 48, 24, 255), ow=0.8)
    return finish(im, w, h)


def prop_cactus():
    w, h = 112, 152
    im = canvas(w, h)
    soft_shadow(im, 56, 141, 38, 6, 58)
    green = (74, 138, 70, 255)
    dark = (48, 102, 50, 255)
    light = (116, 180, 92, 255)
    rrect(im, (44, 28, 68, 140), 11, fill=green, outline=dark, ow=1.4)
    rrect(im, (18, 62, 38, 104), 9, fill=green, outline=dark, ow=1.2)
    rrect(im, (18, 88, 48, 104), 8, fill=green)
    rrect(im, (74, 48, 94, 94), 9, fill=green, outline=dark, ow=1.2)
    rrect(im, (62, 78, 94, 94), 8, fill=green)
    for x in (50, 57, 64):
        line(im, (x, 34), (x, 134), A(light, 130), 1.0)
    rnd = random.Random(29)
    for _ in range(30):
        x, y = rnd.uniform(23, 89), rnd.uniform(34, 132)
        if 40 < x < 72 or y > 82:
            ell(im, x, y, 0.65, 0.65, fill=(240, 244, 210, 230))
    ell(im, 56, 25, 7, 5, fill=(226, 92, 108, 255))
    ell(im, 56, 22, 3.5, 3, fill=(246, 150, 150, 255))
    return finish(im, w, h)


def prop_bone_rib():
    w, h = 224, 156
    im = canvas(w, h)
    soft_shadow(im, 112, 139, 88, 8, 55)
    d = ImageDraw.Draw(im)
    for i, x in enumerate((42, 82, 122, 162, 198)):
        top = 24 + abs(i - 2) * 10
        d.arc([(x - 34) * SS, top * SS, (x + 42) * SS, 142 * SS], 180, 355,
              fill=BONE + (255,), width=int(8 * SS))
        d.arc([(x - 30) * SS, (top + 5) * SS, (x + 38) * SS, 140 * SS], 180, 350,
              fill=A(BONE_D, 150), width=int(2 * SS))
    for x in (28, 66, 106, 146, 184):
        ell(im, x, 137, 10, 6, fill=BONE + (255,), outline=BONE_D + (255,), ow=1.0)
    line(im, (18, 138), (208, 138), BONE_D + (255,), 5.0)
    return finish(im, w, h)


def prop_tribal_tent():
    w, h = 256, 184
    im = canvas(w, h)
    soft_shadow(im, 128, 168, 104, 10, 62)
    # thân lều hình vòm + mái vải nhiều tông
    poly(im, [(30, 166), (48, 78), (88, 38), (168, 38), (208, 78), (226, 166)],
         fill=(190, 142, 92, 255), outline=(110, 74, 42, 255), ow=1.5)
    poly(im, [(48, 78), (88, 38), (112, 38), (82, 166), (30, 166)],
         fill=A((214, 170, 112), 180))
    poly(im, [(168, 38), (208, 78), (226, 166), (174, 166), (146, 38)],
         fill=A((164, 116, 72), 150))
    # dải hoa văn bộ lạc
    d = ImageDraw.Draw(im)
    d.rectangle([34 * SS, 118 * SS, 222 * SS, 132 * SS], fill=(146, 54, 44, 255))
    for x in range(42, 218, 18):
        poly(im, [(x, 128), (x + 7, 120), (x + 14, 128)], fill=(240, 205, 140, 255))
    d.rectangle([34 * SS, 132 * SS, 222 * SS, 136 * SS], fill=(66, 108, 104, 255))
    # cửa lều tối + 2 cọc + cờ
    poly(im, [(108, 166), (112, 104), (128, 88), (144, 104), (148, 166)],
         fill=(54, 34, 24, 255), outline=(94, 58, 32, 255), ow=1.2)
    poly(im, [(112, 104), (128, 88), (128, 166), (108, 166)], fill=A((92, 54, 34), 170))
    line(im, (128, 88), (128, 20), (92, 62, 36, 255), 2.4)
    poly(im, [(128, 20), (162, 28), (128, 38)], fill=(196, 66, 52, 255), outline=(110, 36, 30, 255), ow=1.0)
    for x in (42, 214):
        line(im, (x, 72), (x - 4, 168), (92, 62, 36, 255), 3.0)
    speck(im, 808, 80, [A((110, 74, 42), 110), A((240, 216, 164), 80)], 0.4, 0.9, wrap=False)
    return finish(im, w, h)


def prop_campfire():
    w, h = 112, 96
    im = canvas(w, h)
    soft_shadow(im, 56, 82, 42, 7, 58)
    glow = canvas(w, h)
    ell(glow, 56, 55, 38, 28, fill=(255, 166, 66, 58))
    glow = glow.filter(__import__("PIL.ImageFilter", fromlist=["GaussianBlur"]).GaussianBlur(4.5 * SS))
    im.alpha_composite(glow)
    rnd = random.Random(53)
    for i in range(10):
        ang = 6.283185307179586 * i / 10
        x, y = 56 + math.cos(ang) * 29, 76 + math.sin(ang) * 9
        ell(im, x, y, rnd.uniform(5, 8), rnd.uniform(3.5, 5), fill=(142, 138, 134, 255),
            outline=(96, 94, 92, 255), ow=0.9)
    line(im, (34, 76), (76, 66), (96, 62, 34, 255), 6.0)
    line(im, (76, 78), (36, 64), (110, 76, 44, 255), 6.0)
    flame(im, 56, 78, 42, 16, (232, 106, 34, 255))
    flame(im, 53, 78, 31, 11, (246, 160, 52, 255))
    flame(im, 57, 78, 19, 7, (252, 220, 130, 255))
    for _ in range(7):
        ell(im, rnd.uniform(42, 70), rnd.uniform(28, 52), 1.0, 1.0, fill=(255, 190, 90, 230))
    return finish(im, w, h)


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
    cols, rows = 15, 10
    scene = Image.new("RGBA", (cols * T, rows * T), (0, 0, 0, 255))
    G = lambda n: tile_get(atlas, DESERT_ORDER, n, DESERT_COLS)  # noqa: E731
    def paste(im, x, y):
        scene.alpha_composite(im, (int(x), int(y)))
    variants = {(2, 2): "sand_dune", (7, 1): "rocky_sand", (11, 3): "dry_grass",
                (4, 7): "bone_sand", (12, 8): "cracked", (8, 6): "sand_dune"}
    for y in range(rows):
        for x in range(cols):
            paste(G(variants.get((x, y), "sand")), x * T, y * T)
    for x in range(15):
        paste(G("cracked"), x * T, 5 * T)
    water = {(1, 7): "water_a", (2, 7): "water_b", (1, 8): "water_b", (2, 8): "water_a"}
    for (x, y), n in water.items():
        paste(G(n), x * T, y * T)
    for x in (1, 2):
        paste(G("shore_s"), x * T, 6 * T)
        paste(G("shore_n"), x * T, 9 * T)
    paste(G("shore_e"), 0, 7 * T); paste(G("shore_e"), 0, 8 * T)
    paste(G("shore_w"), 3 * T, 7 * T); paste(G("shore_w"), 3 * T, 8 * T)
    paste(props["palm_tree"], 0, 4 * T)
    paste(props["palm_tree"], 3 * T, 7 * T)
    paste(props["tribal_tent"], 9 * T, 1 * T)
    paste(props["bone_rib"], 11 * T, 6 * T)
    paste(props["cactus"], 6 * T, 2 * T)
    paste(props["campfire"], 10 * T, 3 * T)
    return scene


def main():
    tiles = build_desert()
    atlas = save_atlas(tiles, DESERT_ORDER, DESERT_COLS,
                       os.path.join(TILE_DIR, "desert_v1.png"),
                       os.path.join(TILE_DIR, "desert_v1.tres"),
                       "res://assets/tilesets/desert_v1.png")
    print("desert atlas:", atlas.size, "tiles:", len(DESERT_ORDER))
    props = {
        "palm_tree": prop_palm(), "cactus": prop_cactus(),
        "bone_rib": prop_bone_rib(), "tribal_tent": prop_tribal_tent(),
        "campfire": prop_campfire(),
    }
    for name, im in props.items():
        im.save(os.path.join(PROP_DIR, name + ".png"))
        print("prop:", name, im.size)
    mock = build_mockup(atlas, props)
    mock = mock.resize((mock.width * 3 // 2, mock.height * 3 // 2), Image.LANCZOS)
    mock.convert("RGB").save(os.path.join(DESIGN_DIR, "solmaris_mockup_v1.png"))
    print("solmaris mockup:", mock.size)


if __name__ == "__main__":
    main()
