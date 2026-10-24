#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh tileset BĂNG TUYẾT v1 cho VÙNG BẮC FROSTGARD.

Kế thừa pipeline supersample 4x + wrap-around texture + transition profile
của tools/gen_tileset_v1.py (qua gen_desert_tileset.py).
Palette: trắng tuyết, xanh băng #A8DADC/#457B9D, xám thép, đen thông.

Đầu ra:
- game/assets/tilesets/winter_v1.png + winter_v1.tres (lưới 5x4, tile 64px)
- game/assets/props/snow_pine.png, ice_rock.png, grave_stone.png
- design/frostgard_mockup_v1.png

Thứ tự atlas (builder paint_frostgard dùng đúng thứ tự này):
 hàng0: snow, drift, rocky_snow, ice, ice_shine
 hàng1: deep_ice, shore_s, shore_n, shore_w, shore_e
 hàng2: shore_cvx, shore_ccv, frost_grass, stone_floor, dark_brick
 hàng3: ash_snow, path_s, path_n, dead_scrub, packed_snow
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

SNOW = (238, 242, 248)
SNOW_L = (252, 253, 255)
SNOW_D = (206, 218, 234)
SNOW_XD = (172, 190, 214)
ICE = (168, 218, 220)       # #A8DADC
ICE_D = (69, 123, 157)      # #457B9D
ICE_L = (208, 238, 240)
ICE_DEEP = (52, 96, 136)
ICE_SHINE = (188, 230, 232)
STEEL = (138, 146, 158)
STEEL_L = (176, 184, 196)
STEEL_D = (88, 96, 108)
PINE = (34, 66, 52)
PINE_D = (22, 44, 36)
PINE_L = (58, 102, 76)
FROST = (152, 182, 150)
FROST_D = (110, 142, 108)
ASH = (196, 198, 204)
ASH_D = (140, 142, 150)
PACKED = (216, 226, 238)
STONE = (148, 152, 160)
STONE_L = (182, 186, 194)
STONE_D = (104, 108, 118)
DARKBRICK = (62, 66, 76)
DARKBRICK_L = (88, 92, 104)
DARKBRICK_D = (38, 40, 48)


def snow_im(seed, drift=False):
    im = base_fill(SNOW)
    ov = canvas(T)
    ell9(ov, 20, 20, 25, 15, A(SNOW_L, 50))
    ell9(ov, 50, 52, 23, 14, A(SNOW_D, 44))
    ov = wrapped_blur(ov, 2.5 * SS)
    im.alpha_composite(ov)
    if drift:
        d = ImageDraw.Draw(im)
        for y in (16, 36, 54):
            pts = []
            for x in range(0, 65, 4):
                pts.append((x * SS, (y + 3.4 * math.sin(x / 64 * math.pi)) * SS))
            d.line(pts, fill=A(SNOW_D, 160), width=int(1.8 * SS))
            pts2 = [(x * SS, (y - 2.2 + 3.4 * math.sin(x / 64 * math.pi)) * SS) for x in range(0, 65, 4)]
            d.line(pts2, fill=A(SNOW_L, 170), width=int(1.0 * SS))
    speck(im, seed, 24, [A(SNOW_L, 60), A(SNOW_D, 48), A(ICE, 30)], 0.25, 0.6)
    return im


def rocky_snow_im(seed):
    im = snow_im(seed)
    rnd = random.Random(seed)
    for _ in range(9):
        x, y = rnd.uniform(5, 59), rnd.uniform(6, 58)
        r = rnd.uniform(2.2, 5.4)
        ell(im, x + 0.8, y + r * 0.45, r, r * 0.4, fill=A(SNOW_XD, 110))
        ell(im, x, y, r, r * 0.72, fill=rnd.choice((STEEL, STEEL_L, STONE_D)) + (255,),
            outline=STEEL_D + (255,), ow=0.8)
        ell(im, x - r * 0.3, y - r * 0.25, r * 0.42, r * 0.24, fill=A(SNOW_L, 190))
    speck(im, seed + 3, 42, [A(STEEL_D, 110), A(SNOW_L, 120)], 0.4, 1.0)
    return im


def ice_im(seed, shine=False, deep=False):
    base = ICE_DEEP if deep else ICE
    im = base_fill(base)
    ov = canvas(T)
    if deep:
        ell9(ov, 20, 18, 26, 14, A(ICE, 52))
        ell9(ov, 50, 52, 24, 13, A((30, 62, 96), 70))
    else:
        ell9(ov, 20, 18, 26, 14, A(ICE_L, 58))
        ell9(ov, 50, 52, 24, 13, A(ICE_D, 52))
    ov = wrapped_blur(ov, 2.6 * SS)
    im.alpha_composite(ov)
    rnd = random.Random(seed)
    # vết nứt băng mảnh
    offs = [(-T, -T), (0, -T), (T, -T), (-T, 0), (0, 0), (T, 0), (-T, T), (0, T), (T, T)]
    for _ in range(6):
        x, y = rnd.uniform(2, 62), rnd.uniform(2, 62)
        pts = [(x, y)]
        for _ in range(rnd.randint(2, 4)):
            x += rnd.uniform(-11, 11)
            y += rnd.uniform(-8, 8)
            pts.append((x, y))
        for dx, dy in offs:
            pp = [(px + dx, py + dy) for px, py in pts]
            for a, b in zip(pp, pp[1:]):
                line(im, a, b, A((240, 252, 252) if not deep else ICE_L, 150), 0.9)
    if shine:
        d = ImageDraw.Draw(im)
        for (x0, y0) in [(10, 14), (36, 30), (22, 48)]:
            pts = [(x0 + k * 1.6, y0 + 1.1 * math.sin(k / 7 * math.pi)) for k in range(8)]
            d.line([(px * SS, py * SS) for px, py in pts], fill=A((255, 255, 255), 200), width=int(1.3 * SS))
        speck(im, seed + 6, 22, [A((255, 255, 255), 190)], 0.35, 0.85)
    else:
        speck(im, seed + 6, 16, [A(ICE_L, 130)], 0.35, 0.8)
    return im


def frost_grass_im(seed):
    im = snow_im(seed)
    rnd = random.Random(seed + 1)
    offs = [(-T, -T), (0, -T), (T, -T), (-T, 0), (0, 0), (T, 0), (-T, T), (0, T), (T, T)]
    for _ in range(10):
        x, y = rnd.uniform(0, T), rnd.uniform(0, T)
        s = rnd.uniform(5.0, 9.5)
        for dx, dy in offs:
            for _k in range(5):
                ddx = rnd.uniform(-2.6, 2.6)
                blade(im, x + dx + ddx, y + dy, s * rnd.uniform(0.7, 1.2),
                      rnd.choice((FROST_D, FROST, (178, 198, 160))), lean=ddx * 0.4)
    # phủ sương trắng ở chân cỏ
    speck(im, seed + 5, 20, [A(SNOW_L, 140)], 0.3, 0.6)
    return im


def stone_floor_im(seed):
    im = base_fill(STONE)
    d = ImageDraw.Draw(im)
    rnd = random.Random(seed)
    for ri, (y0, y1) in enumerate([(0, 32), (32, 64)]):
        off = 0 if ri == 0 else 16
        for x0 in range(-16, 64, 32):
            xx = x0 + off
            tone = rnd.choice((STONE, STONE_L, (158, 162, 170)))
            rrect(im, (xx + 1.8, y0 + 1.8, xx + 30.2, y1 - 1.8), 3.5, fill=tone + (255,))
            ell(im, xx + 10, y0 + 8, 6, 2.3, fill=A(STONE_L, 95))
    speck(im, seed + 3, 44, [A(STONE_D, 82), A(SNOW_L, 90)], 0.3, 0.75)
    d.rectangle([0, 31 * SS, W, 32.2 * SS], fill=A(STONE_D, 130))
    return im


def dark_brick_im(seed):
    im = base_fill(DARKBRICK)
    rnd = random.Random(seed)
    rows = [(0, 21), (21, 43), (43, 64)]
    for ri, (y0, y1) in enumerate(rows):
        off = 0 if ri % 2 == 0 else 21
        for x0 in range(-21, 64, 42):
            xx = x0 + off
            tone = rnd.choice((DARKBRICK, DARKBRICK_L, (72, 76, 88)))
            rrect(im, (xx + 1.6, y0 + 1.6, xx + 40.4, y1 - 1.6), 3.0, fill=tone + (255,))
            ell(im, xx + 12, y0 + 6.2, 7, 2.5, fill=A(STEEL_L, 90))
    # tuyết đọng khe gạch
    speck(im, seed + 1, 40, [A(SNOW_L, 120), A(DARKBRICK_D, 80)], 0.3, 0.7)
    return im


def ash_snow_im(seed):
    im = snow_im(seed)
    speck(im, seed + 9, 90, [A(ASH_D, 130), A(ASH, 140), A((90, 92, 100), 90)], 0.35, 1.0)
    ov = canvas(T)
    ell9(ov, 24, 26, 22, 13, A(ASH_D, 44))
    ov = wrapped_blur(ov, 2.4 * SS)
    im.alpha_composite(ov)
    return im


def packed_snow_im(seed):
    im = base_fill(PACKED)
    ov = canvas(T)
    ell9(ov, 22, 20, 25, 15, A(SNOW_L, 46))
    ell9(ov, 50, 52, 22, 13, A(SNOW_XD, 50))
    ov = wrapped_blur(ov, 2.4 * SS)
    im.alpha_composite(ov)
    rnd = random.Random(seed)
    for _ in range(7):  # dấu chân / vệt nén mờ
        x, y = rnd.uniform(6, 58), rnd.uniform(6, 58)
        ell(im, x, y, rnd.uniform(2.2, 3.4), rnd.uniform(1.2, 1.8), fill=A(SNOW_XD, 95))
    speck(im, seed + 3, 36, [A(SNOW_L, 70), A(SNOW_XD, 60)], 0.3, 0.7)
    return im


def dead_scrub_im(seed):
    im = snow_im(seed)
    rnd = random.Random(seed + 2)
    offs = [(0, 0)]
    for _ in range(7):
        x, y = rnd.uniform(4, 60), rnd.uniform(10, 60)
        for dx, dy in offs:
            for k in range(4):
                lean = rnd.uniform(-6, 6)
                h = rnd.uniform(6, 11)
                line(im, (x + dx + k * 1.2, y + dy), (x + dx + k * 1.2 + lean, y + dy - h),
                     (74, 66, 58, 255), 1.1)
    speck(im, seed + 4, 18, [A(SNOW_D, 80)], 0.3, 0.6)
    return im


def build_winter():
    tiles = {}
    tiles["snow"] = snow_im(801)
    tiles["drift"] = snow_im(802, drift=True)
    tiles["rocky_snow"] = rocky_snow_im(803)
    tiles["ice"] = ice_im(804)
    tiles["ice_shine"] = ice_im(805, shine=True)
    tiles["deep_ice"] = ice_im(806, deep=True)
    s = tiles["snow"]
    ic = tiles["ice"]
    pk = tiles["packed_snow"] if "packed_snow" in tiles else packed_snow_im(819)
    tiles["packed_snow"] = pk
    H = mask_H(); V = mask_V()
    nH = ImageChops.invert(H); nV = ImageChops.invert(V)
    tiles["shore_s"] = transition(s, ic, H, 831, shore=True)
    tiles["shore_n"] = transition(s, ic, nH, 832, shore=True)
    tiles["shore_w"] = transition(s, ic, nV, 833, shore=True)
    tiles["shore_e"] = transition(s, ic, V, 834, shore=True)
    tiles["shore_cvx"] = transition(s, ic, ImageChops.multiply(H, V), 835, shore=True)
    tiles["shore_ccv"] = transition(s, ic, ImageChops.lighter(H, V), 836, shore=True)
    tiles["frost_grass"] = frost_grass_im(841)
    tiles["stone_floor"] = stone_floor_im(851)
    tiles["dark_brick"] = dark_brick_im(861)
    tiles["ash_snow"] = ash_snow_im(871)
    tiles["path_s"] = transition(s, pk, H, 881)
    tiles["path_n"] = transition(s, pk, nH, 882)
    tiles["dead_scrub"] = dead_scrub_im(891)
    return tiles


WINTER_ORDER = [
    "snow", "drift", "rocky_snow", "ice", "ice_shine",
    "deep_ice", "shore_s", "shore_n", "shore_w", "shore_e",
    "shore_cvx", "shore_ccv", "frost_grass", "stone_floor", "dark_brick",
    "ash_snow", "path_s", "path_n", "dead_scrub", "packed_snow",
]
WINTER_COLS = 5


def prop_snow_pine():
    w, h = 176, 216
    im = canvas(w, h)
    soft_shadow(im, 88, 203, 56, 8, 62)
    d = ImageDraw.Draw(im)
    # thân
    d.rectangle([82 * SS, 150 * SS, 94 * SS, 204 * SS], fill=(92, 64, 40, 255))
    d.rectangle([82 * SS, 150 * SS, 86 * SS, 204 * SS], fill=(130, 96, 60, 200))
    # 4 tầng lá hình tam giác xếp chồng, mép dưới phủ tuyết
    layers = [
        (88, 18, 52, 78),
        (88, 52, 68, 112),
        (88, 88, 82, 148),
        (88, 124, 96, 182),
    ]
    for (cx, top, half, bot) in layers:
        poly(im, [(cx - half, bot), (cx + half, bot), (cx, top)], fill=PINE + (255,), outline=PINE_D + (255,), ow=1.2)
        # mảng sáng giữa tầng
        poly(im, [(cx - half * 0.45, bot - 6), (cx + half * 0.2, bot - 6), (cx, top + 14)], fill=A(PINE_L, 130))
        # tuyết phủ mép dưới tầng (dải trắng lượn)
        pts = []
        for k in range(9):
            t = k / 8
            x = cx - half + t * half * 2
            y = bot - 2 + 3.2 * math.sin(t * math.pi)
            pts.append((x, y))
        d.line([(x * SS, y * SS) for x, y in pts], fill=(248, 250, 252, 255), width=int(4.2 * SS))
        # tuyết trên đỉnh tầng
        ell(im, cx, top + 8, half * 0.28, 4.5, fill=A((248, 250, 252), 220))
    speck(im, 817, 40, [A((248, 250, 252), 150)], 0.4, 0.9, wrap=False)
    return finish(im, w, h)


def prop_ice_rock():
    w, h = 128, 120
    im = canvas(w, h)
    soft_shadow(im, 64, 108, 48, 7, 58)
    # cụm đá băng nhọn: đa giác sắc cạnh xanh băng + mặt sáng
    poly(im, [(18, 108), (38, 34), (54, 108)], fill=ICE_D + (255,), outline=(38, 78, 110, 255), ow=1.3)
    poly(im, [(38, 34), (54, 108), (44, 108)], fill=A(ICE, 220))
    poly(im, [(48, 108), (70, 14), (96, 108)], fill=ICE + (255,), outline=(38, 78, 110, 255), ow=1.4)
    poly(im, [(70, 14), (96, 108), (80, 108)], fill=A(ICE_L, 200))
    poly(im, [(88, 108), (104, 52), (116, 108)], fill=ICE_D + (255,), outline=(38, 78, 110, 255), ow=1.2)
    line(im, (70, 18), (76, 60), (255, 255, 255, 220), 1.6)
    line(im, (40, 42), (44, 78), (255, 255, 255, 160), 1.2)
    # tuyết chân đá
    ell(im, 64, 108, 46, 6, fill=A((248, 250, 252), 200))
    return finish(im, w, h)


def prop_grave_stone():
    w, h = 96, 112
    im = canvas(w, h)
    soft_shadow(im, 48, 100, 34, 6, 58)
    d = ImageDraw.Draw(im)
    # bia đá vòm: thân xám thép + viền tối
    rrect(im, (24, 22, 72, 100), 14, fill=STEEL + (255,), outline=STEEL_D + (255,), ow=1.5)
    rrect(im, (29, 27, 67, 95), 11, fill=A(STEEL_L, 90))
    # khắc chữ thập + vệt nứt
    line(im, (48, 42), (48, 66), STEEL_D + (255,), 2.6)
    line(im, (39, 52), (57, 52), STEEL_D + (255,), 2.6)
    line(im, (58, 70), (52, 82), A(STEEL_D, 170), 1.1)
    # tuyết phủ đỉnh bia + chân bia
    ell(im, 48, 23, 22, 6, fill=(248, 250, 252, 255))
    ell(im, 48, 100, 30, 5, fill=A((248, 250, 252), 210))
    speck(im, 823, 26, [A(STEEL_D, 110), A((248, 250, 252), 110)], 0.35, 0.8, wrap=False)
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
    G = lambda n: tile_get(atlas, WINTER_ORDER, n, WINTER_COLS)  # noqa: E731
    def paste(im, x, y):
        scene.alpha_composite(im, (int(x), int(y)))
    variants = {(2, 2): "drift", (7, 1): "rocky_snow", (11, 3): "frost_grass",
                (4, 7): "ash_snow", (12, 8): "rocky_snow", (8, 6): "drift"}
    for y in range(rows):
        for x in range(cols):
            paste(G(variants.get((x, y), "snow")), x * T, y * T)
    for x in range(15):
        paste(G("packed_snow"), x * T, 5 * T)
    ice = {(1, 7): "ice", (2, 7): "ice_shine", (1, 8): "deep_ice", (2, 8): "ice"}
    for (x, y), n in ice.items():
        paste(G(n), x * T, y * T)
    for x in (1, 2):
        paste(G("shore_s"), x * T, 6 * T)
        paste(G("shore_n"), x * T, 9 * T)
    paste(G("shore_e"), 0, 7 * T); paste(G("shore_e"), 0, 8 * T)
    paste(G("shore_w"), 3 * T, 7 * T); paste(G("shore_w"), 3 * T, 8 * T)
    paste(props["snow_pine"], 0, 3 * T)
    paste(props["snow_pine"], 4 * T, 1 * T)
    paste(props["ice_rock"], 10 * T, 2 * T)
    paste(props["grave_stone"], 12 * T, 6 * T)
    paste(props["grave_stone"], 13 * T, 7 * T)
    return scene


def main():
    tiles = build_winter()
    atlas = save_atlas(tiles, WINTER_ORDER, WINTER_COLS,
                       os.path.join(TILE_DIR, "winter_v1.png"),
                       os.path.join(TILE_DIR, "winter_v1.tres"),
                       "res://assets/tilesets/winter_v1.png")
    print("winter atlas:", atlas.size, "tiles:", len(WINTER_ORDER))
    props = {
        "snow_pine": prop_snow_pine(), "ice_rock": prop_ice_rock(),
        "grave_stone": prop_grave_stone(),
    }
    for name, im in props.items():
        im.save(os.path.join(PROP_DIR, name + ".png"))
        print("prop:", name, im.size)
    mock = build_mockup(atlas, props)
    mock = mock.resize((mock.width * 3 // 2, mock.height * 3 // 2), Image.LANCZOS)
    mock.convert("RGB").save(os.path.join(DESIGN_DIR, "frostgard_mockup_v1.png"))
    print("frostgard mockup:", mock.size)


if __name__ == "__main__":
    main()
