#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sinh prop NOI THANH SOLMARIS (thanh sa mac): nha dat nung mai bang 3 bien
the, sap vai bazaar 2 bien the, phu hoi dong linh danh thue (module lon),
thap nuoc sa thach, ngai trong phu vai (vua da chet).
Ve supersample 2x bang PIL roi downscale LANCZOS - chuan pipeline art game.
Chay: python3 tools/gen_solmaris_city_props.py
"""
import math
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "game", "assets", "props")
SS = 2

INK = (74, 52, 36)
SANDSTONE = (206, 168, 112)
SANDSTONE_L = (232, 200, 146)
SANDSTONE_D = (168, 128, 78)
ADOBE = (216, 178, 128)
ADOBE_L = (238, 206, 158)
ADOBE_D = (182, 142, 92)
TERRA = (198, 128, 88)
TERRA_L = (226, 162, 118)
TERRA_D = (160, 98, 62)
WHITEWASH = (234, 220, 188)
WHITEWASH_D = (206, 188, 148)
TIMBER = (116, 80, 48)
TIMBER_D = (86, 58, 34)
WOOD = (152, 110, 66)
WOOD_D = (116, 80, 46)
GOLD = (226, 184, 92)
CRIMSON = (150, 52, 56)
TEAL = (62, 140, 140)


def A(c, a):
    return (c[0], c[1], c[2], a)


def canvas(w, h):
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))


def finish(im, w, h):
    return im.resize((w, h), Image.LANCZOS)


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name))
    print("prop:", name, im.size)


def soft_shadow(d, cx, cy, rx, ry, alpha=90):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(40, 26, 12, alpha))


def speck(d, seed, box, cols, n, r=1.5):
    rng = random.Random(seed)
    x0, y0, x1, y1 = box
    for _ in range(n):
        x = rng.uniform(x0, x1)
        y = rng.uniform(y0, y1)
        c = rng.choice(cols)
        d.ellipse([x - r, y - r, x + r, y + r], fill=A(c, rng.randint(45, 105)))


def vgrad(d, box, top, bot):
    x0, y0, x1, y1 = box
    steps = max(2, int(y1 - y0))
    for i in range(steps):
        t = i / (steps - 1)
        c = tuple(int(top[k] + (bot[k] - top[k]) * t) for k in range(3)) + (255,)
        d.line([(x0, y0 + i), (x1, y0 + i)], fill=c)


def brick_courses(d, box, col_line, seed, course=15):
    """Gach noi ngang kieu sa thach/dat nung: hang ngang + moi doc lech hang."""
    x0, y0, x1, y1 = box
    rng = random.Random(seed)
    yy = y0 + course * SS
    row = 0
    while yy < y1 - 2 * SS:
        d.line([(x0, yy), (x1, yy)], fill=A(col_line, 110), width=SS)
        jx = x0 + (10 if row % 2 else 22) * SS + rng.uniform(0, 4) * SS
        while jx < x1 - 4 * SS:
            d.line([(jx, yy), (jx, min(yy + course * SS, y1))],
                   fill=A(col_line, 80), width=SS)
            jx += rng.uniform(24, 40) * SS
        yy += course * SS
        row += 1


def small_window(d, x, y, w, h, lit=True, shutter=True):
    if shutter:
        d.rectangle([x - 4 * SS, y + 1 * SS, x - 1 * SS, y + h - 1 * SS], fill=TIMBER + (255,))
        d.rectangle([x + w + 1 * SS, y + 1 * SS, x + w + 4 * SS, y + h - 1 * SS], fill=TIMBER + (255,))
    d.rectangle([x, y, x + w, y + h], fill=TIMBER_D + (255,))
    c = (255, 216, 132, 255) if lit else (64, 84, 92, 255)
    d.rectangle([x + 2 * SS, y + 2 * SS, x + w - 2 * SS, y + h - 2 * SS], fill=c)
    d.line([(x + w / 2, y), (x + w / 2, y + h)], fill=TIMBER_D + (255,), width=SS)


def door(d, x, y, w, h, col=WOOD_D):
    d.rectangle([x - 3 * SS, y - 3 * SS, x + w + 3 * SS, y + h], fill=TIMBER_D + (255,))
    d.rectangle([x, y, x + w, y + h], fill=col + (255,))
    for fx in (0.28, 0.62):
        d.line([(x + w * fx, y + 2 * SS), (x + w * fx, y + h - 2 * SS)],
               fill=A(TIMBER_D, 200), width=SS)
    d.ellipse([x + w - 8 * SS, y + h / 2 - 2 * SS, x + w - 4 * SS, y + h / 2 + 2 * SS],
              fill=GOLD + (255,))


def vigas(d, x0, x1, y, n, col=TIMBER_D):
    """Dam go tron lo ra duoi mai bang (vigas) - net dac trung nha dat nung."""
    if n <= 1:
        xs = [(x0 + x1) / 2]
    else:
        xs = [x0 + (x1 - x0) * i / (n - 1) for i in range(n)]
    for x in xs:
        d.ellipse([x - 3.2 * SS, y - 3.2 * SS, x + 3.2 * SS, y + 3.2 * SS], fill=col + (255,))
        d.ellipse([x - 1.4 * SS, y - 1.4 * SS, x + 1.4 * SS, y + 1.4 * SS],
                  fill=A(WOOD, 255))


def cloth_awning(d, x0, y0, x1, col, col_d):
    """Mai che vai truoc cua: thanh ngang + vai soc + tua rua."""
    d.polygon([(x0, y0), (x1, y0), (x1 - 6 * SS, y0 + 12 * SS), (x0 + 6 * SS, y0 + 12 * SS)],
              fill=col + (255,))
    stripes = 6
    for i in range(0, stripes, 2):
        sx0 = x0 + (x1 - x0) * i / stripes
        sx1 = x0 + (x1 - x0) * (i + 1) / stripes
        d.polygon([(sx0, y0), (sx1, y0), (sx1 - 6 * SS, y0 + 12 * SS),
                   (sx0 - 6 * SS, y0 + 12 * SS)], fill=A(col_d, 255))
    for fx in range(int(x0 + 8 * SS), int(x1 - 6 * SS), 10 * SS):
        d.line([(fx, y0 + 12 * SS), (fx, y0 + 16 * SS)], fill=A(col_d, 220), width=SS)
    for px in (x0 + 5 * SS, x1 - 9 * SS):
        d.rectangle([px, y0 + 10 * SS, px + 4 * SS, y0 + 34 * SS], fill=TIMBER_D + (255,))


def clay_pot(d, x, y, s, col):
    d.polygon([(x - 5 * s, y - 12 * s), (x + 5 * s, y - 12 * s), (x + 7 * s, y - 2 * s),
               (x + 4 * s, y + 6 * s), (x - 4 * s, y + 6 * s), (x - 7 * s, y - 2 * s)],
              fill=col + (255,))
    d.rectangle([x - 5 * s, y - 14 * s, x + 5 * s, y - 11 * s], fill=A(TERRA_D, 255))
    d.line([(x - 6 * s, y - 5 * s), (x + 6 * s, y - 5 * s)], fill=A(TERRA_D, 160), width=max(1, int(s)))


# ---------------------------------------------------------------- nha dat nung

def adobe_house(w, h, wall, wall_l, wall_d, seed, dome=False, tower_bump=False):
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    rng = random.Random(seed * 17 + 3)
    soft_shadow(d, W / 2 + 8 * SS, H - 6 * SS, W * 0.47, 8 * SS, 95)
    margin = 16 * SS
    wall_top = H * 0.30
    wall_bot = H - 6 * SS
    # than tuong dat nung: gradient + gach noi mo + vet loang nang
    vgrad(d, (margin, wall_top, W - margin, wall_bot), wall_l,
          tuple(max(0, c - 26) for c in wall))
    brick_courses(d, (margin, wall_top, W - margin, wall_bot), wall_d, seed)
    speck(d, seed + 21, (margin, wall_top, W - margin, wall_bot),
          [tuple(max(0, c - 34) for c in wall), tuple(min(255, c + 20) for c in wall)], 220, 1.3)
    # chan tuong sa thach dam hon
    bh = 12 * SS
    d.rectangle([margin, wall_bot - bh, W - margin, wall_bot], fill=SANDSTONE_D + (255,))
    brick_courses(d, (margin, wall_bot - bh, W - margin, wall_bot), SANDSTONE, seed + 4, 6)
    d.rectangle([margin, wall_top, W - margin, wall_bot], outline=A(INK, 190), width=SS)
    # mai bang: dai lan can (parapet) + vien gach + dam vigas lo ra
    parapet_h = 10 * SS
    d.rectangle([margin - 5 * SS, wall_top - parapet_h, W - margin + 5 * SS, wall_top],
                fill=wall + (255,))
    d.rectangle([margin - 5 * SS, wall_top - parapet_h, W - margin + 5 * SS,
                 wall_top - parapet_h + 3 * SS], fill=A(wall_l, 255))
    d.line([(margin - 5 * SS, wall_top), (W - margin + 5 * SS, wall_top)],
           fill=A(wall_d, 255), width=2 * SS)
    # rang cua nho tren parapet (xen ke bat quy tac)
    mx = margin + rng.uniform(2, 8) * SS
    while mx < W - margin - 10 * SS:
        mw = rng.uniform(9, 14) * SS
        d.rectangle([mx, wall_top - parapet_h - 5 * SS, mx + mw,
                     wall_top - parapet_h], fill=wall + (255,))
        mx += mw + rng.uniform(8, 15) * SS
    vigas(d, margin + 14 * SS, W - margin - 14 * SS, wall_top + 7 * SS,
          max(3, int(w / 64)), TIMBER_D)
    # san thuong sau parapet: bong toi nhe phia sau
    d.rectangle([margin, wall_top + 12 * SS, W - margin, wall_top + 15 * SS], fill=(60, 36, 16, 40))
    if dome:
        cx = W * (0.68 if seed % 2 else 0.34)
        d.pieslice([cx - 30 * SS, wall_top - parapet_h - 32 * SS, cx + 30 * SS,
                    wall_top - parapet_h + 26 * SS], 180, 360, fill=TEAL + (255,))
        d.pieslice([cx - 30 * SS, wall_top - parapet_h - 32 * SS, cx + 12 * SS,
                    wall_top - parapet_h + 26 * SS], 180, 270, fill=(255, 255, 255, 26))
        d.rectangle([cx - 2 * SS, wall_top - parapet_h - 40 * SS, cx + 2 * SS,
                     wall_top - parapet_h - 30 * SS], fill=GOLD + (255,))
        d.ellipse([cx - 3 * SS, wall_top - parapet_h - 44 * SS, cx + 3 * SS,
                   wall_top - parapet_h - 38 * SS], fill=GOLD + (255,))
        for gx in (-18, 0, 18):
            d.arc([cx + gx * SS - 8 * SS, wall_top - parapet_h - 26 * SS,
                   cx + gx * SS + 8 * SS, wall_top - parapet_h - 6 * SS], 180, 360,
                  fill=A(TEAL_D if False else (44, 104, 104), 200), width=SS)
    if tower_bump:
        # khoi thap nho nhô len o goc trai (nha giau co o cho)
        tx0, tx1 = margin + 2 * SS, margin + 52 * SS
        ty = wall_top - parapet_h - 34 * SS
        vgrad(d, (tx0, ty, tx1, wall_top), wall_l, wall)
        d.rectangle([tx0, ty, tx1, wall_top], outline=A(INK, 170), width=SS)
        d.rectangle([tx0 - 3 * SS, ty - 5 * SS, tx1 + 3 * SS, ty], fill=wall_d + (255,))
        small_window(d, tx0 + 16 * SS, ty + 12 * SS, 14 * SS, 18 * SS, lit=True)
    # cua chinh + mai che vai + bac them
    dw, dh = 32 * SS, 50 * SS
    door_x = W / 2 - dw / 2 + (10 * SS if seed % 3 == 0 else (-8 * SS if seed % 3 == 1 else 0))
    door(d, door_x, wall_bot - dh, dw, dh)
    cloth_awning(d, door_x - 12 * SS, wall_bot - dh - 16 * SS, door_x + dw + 12 * SS,
                 CRIMSON if seed % 2 else TEAL, CRIMSON_D if False else ((110, 36, 40) if seed % 2 else (44, 104, 104)))
    d.rectangle([door_x - 4 * SS, wall_bot - 4 * SS, door_x + dw + 4 * SS, wall_bot],
                fill=SANDSTONE + (255,))
    # cua so 2 ben (so le khac nhau theo bien the)
    nw = 2 if w < 360 else 3
    placed = 0
    for i in range(nw + 1):
        wx = margin + (i + 0.5) * (W - 2 * margin) / (nw + 1) - 10 * SS
        if abs(wx + 10 * SS - (door_x + dw / 2)) < 30 * SS:
            continue
        small_window(d, wx, wall_top + 22 * SS + (4 * SS if i % 2 else 0),
                     20 * SS, 24 * SS, lit=(i % 2 == 0))
        placed += 1
        if placed >= nw:
            break
    # binh gom + bao hang chan tuong
    clay_pot(d, margin + 16 * SS, wall_bot - 4 * SS, 1.5 * SS, TERRA)
    clay_pot(d, W - margin - 14 * SS, wall_bot - 4 * SS, 1.1 * SS, SANDSTONE_D)
    d.rectangle([W - margin - 34 * SS, wall_bot - 12 * SS, W - margin - 20 * SS, wall_bot - 2 * SS],
                fill=(196, 158, 96, 255))
    # vet kho duoi chan tuong + re kho leo
    speck(d, seed + 11, (margin, H - 20 * SS, W - margin, H - 8 * SS),
          [(168, 138, 66), (140, 116, 54)], 18, 1.7)
    return finish(im, w, h)


# ---------------------------------------------------------------- sap bazaar

def bazaar_stall(w, h, canopy, canopy_d, seed):
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    rng = random.Random(seed * 13 + 7)
    soft_shadow(d, W / 2, H - 8 * SS, W * 0.47, 8 * SS)
    # 4 cot go (2 cot truoc cao, 2 cot sau thap hon - mai doc ve truoc)
    back_y = H * 0.16
    front_y = H * 0.40
    for px in (14 * SS, W - 20 * SS):
        d.rectangle([px, back_y + 6 * SS, px + 6 * SS, H - 10 * SS], fill=TIMBER_D + (255,))
    # quay hang
    counter_y = H - 58 * SS
    d.rectangle([8 * SS, counter_y, W - 8 * SS, H - 8 * SS], fill=WOOD + (255,))
    d.rectangle([8 * SS, counter_y, W - 8 * SS, counter_y + 7 * SS], fill=WOOD_D + (255,))
    d.rectangle([8 * SS, counter_y + 7 * SS, W - 8 * SS, counter_y + 10 * SS],
                fill=A(CRIMSON, 200))
    # hang tren quay: cuon vai dung + binh gom + dong gia vi mau
    for i in range(5):
        bx = (18 + i * (w - 40) / 5 + rng.randint(-2, 2)) * SS
        c = rng.choice([(196, 84, 60), (84, 128, 160), (226, 180, 84), (140, 90, 170),
                        (100, 160, 90)])
        bh = rng.choice([26, 32, 22]) * SS
        d.rectangle([bx, counter_y - bh, bx + 13 * SS, counter_y], fill=c + (255,))
        d.rectangle([bx, counter_y - bh, bx + 13 * SS, counter_y - bh + 4 * SS],
                    fill=A(GOLD, 220))
    for i in range(4):
        bx = (26 + i * (w - 56) / 4) * SS
        by = counter_y + 16 * SS
        c = rng.choice([(226, 120, 40), (190, 60, 50), (120, 170, 80), (240, 200, 90)])
        d.pieslice([bx - 9 * SS, by - 7 * SS, bx + 9 * SS, by + 7 * SS], 180, 360,
                   fill=c + (255,))
        d.rectangle([bx - 10 * SS, by, bx + 10 * SS, by + 5 * SS], fill=TERRA_D + (255,))
    clay_pot(d, 22 * SS, H - 12 * SS, 1.2 * SS, TERRA)
    clay_pot(d, W - 20 * SS, H - 12 * SS, 1.0 * SS, SANDSTONE_D)
    # mai vai: soc 2 mau, canh truoc tha tua, doc nhe
    d.polygon([(0, front_y), (W, front_y), (W - 12 * SS, back_y), (12 * SS, back_y)],
              fill=canopy + (255,))
    stripes = 7
    for i in range(0, stripes, 2):
        x0 = 12 * SS + (W - 24 * SS) * i / stripes
        x1 = 12 * SS + (W - 24 * SS) * (i + 1) / stripes
        d.polygon([(x0 - 12 * SS * i / stripes + 0, front_y), (x1, front_y),
                   (x1 - 0, back_y), (x0, back_y)], fill=A(canopy_d, 255))
    # ve lai soc dung chuan (che len ban truoc neu lech)
    d.polygon([(0, front_y), (W, front_y), (W - 12 * SS, back_y), (12 * SS, back_y)],
              outline=A(INK, 120))
    for fx in range(10 * SS, int(W - 8 * SS), 13 * SS):
        d.line([(fx, front_y), (fx, front_y + 5 * SS)], fill=A(canopy_d, 230), width=SS)
    d.line([(0, front_y), (W, front_y)], fill=A(canopy_d, 255), width=2 * SS)
    # den long + hang treo duoi mai
    for i in range(3):
        hx = (40 + i * (w - 80) / 2) * SS
        d.line([(hx, front_y), (hx, front_y + 9 * SS)], fill=TIMBER_D + (255,), width=SS)
        d.ellipse([hx - 4 * SS, front_y + 9 * SS, hx + 4 * SS, front_y + 17 * SS],
                  fill=(255, 196, 96, 240))
        d.ellipse([hx - 7 * SS, front_y + 7 * SS, hx + 7 * SS, front_y + 19 * SS],
                  fill=(255, 190, 90, 36))
    # tham trai truoc quay
    d.polygon([(26 * SS, H - 6 * SS), (W - 26 * SS, H - 6 * SS), (W - 36 * SS, H - 1 * SS),
               (36 * SS, H - 1 * SS)], fill=A(CRIMSON, 150))
    return finish(im, w, h)


# ---------------------------------------------------------------- phu hoi dong

def council_hall():
    w, h = 1024, 576
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 10 * SS, W * 0.48, 11 * SS)
    wall_bot = H - 10 * SS
    # 2 canh phu thap
    for (x0, x1) in [(26 * SS, 330 * SS), (W - 330 * SS, W - 26 * SS)]:
        top = H * 0.40
        vgrad(d, (x0, top, x1, wall_bot), SANDSTONE_L, SANDSTONE)
        brick_courses(d, (x0, top, x1, wall_bot), SANDSTONE_D, 5)
        d.rectangle([x0 - 4 * SS, top - 8 * SS, x1 + 4 * SS, top], fill=SANDSTONE_D + (255,))
        vigas(d, x0 + 16 * SS, x1 - 16 * SS, top + 6 * SS, 6)
        for i in range(3):
            wx = x0 + (i + 0.5) * (x1 - x0) / 3 - 10 * SS
            small_window(d, wx, top + 26 * SS, 20 * SS, 26 * SS, lit=True)
        d.rectangle([x0, top, x1, wall_bot], outline=A(INK, 160), width=SS)
    # khoi giua cao: sanh hoi dong
    kx0, kx1 = 356 * SS, W - 356 * SS
    ktop = H * 0.16
    vgrad(d, (kx0, ktop, kx1, wall_bot), (238, 208, 152), SANDSTONE)
    brick_courses(d, (kx0, ktop, kx1, wall_bot), SANDSTONE_D, 9)
    speck(d, 31, (kx0, ktop, kx1, wall_bot), [SANDSTONE_D, SANDSTONE_L], 200, 1.4)
    d.rectangle([kx0, ktop, kx1, wall_bot], outline=A(INK, 200), width=SS)
    # parapet rang cua khoi giua + vong nguyet vang tren dinh
    d.rectangle([kx0 - 6 * SS, ktop - 9 * SS, kx1 + 6 * SS, ktop], fill=SANDSTONE_D + (255,))
    mx = kx0 + 4 * SS
    while mx < kx1 - 12 * SS:
        d.rectangle([mx, ktop - 16 * SS, mx + 13 * SS, ktop - 9 * SS], fill=SANDSTONE_D + (255,))
        mx += 24 * SS
    d.arc([W / 2 - 17 * SS, ktop - 44 * SS, W / 2 + 17 * SS, ktop - 10 * SS], 180, 360,
          fill=GOLD + (255,), width=3 * SS)
    d.ellipse([W / 2 - 4 * SS, ktop - 30 * SS, W / 2 + 4 * SS, ktop - 22 * SS], fill=GOLD + (255,))
    # cong vom lon giua + cua go 2 canh mo he
    aw, ah = 92 * SS, 118 * SS
    ax0 = W / 2 - aw / 2
    ay0 = wall_bot - ah
    d.rectangle([ax0 - 6 * SS, ay0 - 6 * SS, ax0 + aw + 6 * SS, wall_bot], fill=SANDSTONE_D + (255,))
    d.pieslice([ax0, ay0 - 40 * SS, ax0 + aw, ay0 + 40 * SS], 180, 360, fill=SANDSTONE_D + (255,))
    d.rectangle([ax0 + 4 * SS, ay0 + 6 * SS, ax0 + aw - 4 * SS, wall_bot], fill=(38, 26, 20, 255))
    d.pieslice([ax0 + 4 * SS, ay0 - 32 * SS, ax0 + aw - 4 * SS, ay0 + 36 * SS], 180, 360,
               fill=(38, 26, 20, 255))
    for sx in (-1, 1):
        dx0 = W / 2 + (2 * SS if sx > 0 else -aw / 2 + 6 * SS)
        dx1 = W / 2 + (aw / 2 - 6 * SS if sx > 0 else -2 * SS)
        d.rectangle([dx0, ay0 + 14 * SS, dx1, wall_bot], fill=WOOD_D + (255,))
        d.rectangle([dx0 + 3 * SS, ay0 + 20 * SS, dx1 - 3 * SS, wall_bot - 26 * SS],
                    outline=A(TIMBER_D, 220), width=SS)
    # cua so cao 2 ben cong + huy hieu hoi dong (khien cheo kiem)
    for sx in (-1, 1):
        wx = W / 2 + sx * 92 * SS - 11 * SS
        small_window(d, wx, ktop + 44 * SS, 22 * SS, 34 * SS, lit=True, shutter=False)
        bx = W / 2 + sx * 128 * SS
        d.rectangle([bx - 12 * SS, ktop + 30 * SS, bx + 12 * SS, ktop + 108 * SS],
                    fill=CRIMSON + (255,))
        d.polygon([(bx - 12 * SS, ktop + 108 * SS), (bx + 12 * SS, ktop + 108 * SS),
                   (bx, ktop + 122 * SS)], fill=CRIMSON + (255,))
        d.line([(bx - 7 * SS, ktop + 48 * SS), (bx + 7 * SS, ktop + 76 * SS)],
               fill=GOLD + (255,), width=2 * SS)
        d.line([(bx + 7 * SS, ktop + 48 * SS), (bx - 7 * SS, ktop + 76 * SS)],
               fill=GOLD + (255,), width=2 * SS)
    # bac them dai truoc cong
    for i, bw in enumerate([120, 104, 88]):
        yy = wall_bot + i * 3 * SS
        d.rectangle([W / 2 - bw * SS, yy, W / 2 + bw * SS, yy + 3 * SS], fill=SANDSTONE_D + (255,))
    return finish(im, w, h)


def empty_throne():
    """Ngai trong phu vai: ghe da cao, vai xam phu qua, vuong mien nut tren ghe."""
    w, h = 160, 192
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 6 * SS, W * 0.42, 6 * SS)
    # be da 2 bac
    d.rectangle([W * 0.14, H - 22 * SS, W * 0.86, H - 6 * SS], fill=SANDSTONE_D + (255,))
    d.rectangle([W * 0.22, H - 30 * SS, W * 0.78, H - 22 * SS], fill=SANDSTONE + (255,))
    # lung ghe cao + dinh nhon
    d.rectangle([W * 0.30, H * 0.16, W * 0.70, H - 28 * SS], fill=SANDSTONE + (255,))
    d.polygon([(W * 0.30, H * 0.16), (W * 0.70, H * 0.16), (W * 0.50, H * 0.03)],
              fill=SANDSTONE_D + (255,))
    d.rectangle([W * 0.30, H * 0.16, W * 0.70, H - 28 * SS], outline=A(INK, 170), width=SS)
    # mat ghe + tay vin
    d.rectangle([W * 0.26, H - 52 * SS, W * 0.74, H - 40 * SS], fill=SANDSTONE_D + (255,))
    for sx in (0.24, 0.68):
        d.rectangle([W * sx, H - 66 * SS, W * sx + W * 0.08, H - 30 * SS], fill=SANDSTONE + (255,))
    # vai phu: xam tro, tha tu lung ghe xuong mat ghe, nep gap doc
    d.polygon([(W * 0.34, H * 0.14), (W * 0.62, H * 0.13), (W * 0.66, H - 44 * SS),
               (W * 0.56, H - 40 * SS), (W * 0.50, H - 52 * SS), (W * 0.38, H - 46 * SS)],
              fill=(196, 192, 184, 245))
    for fx in (0.42, 0.50, 0.57):
        d.line([(W * fx, H * 0.16), (W * (fx + 0.02), H - 48 * SS)], fill=(150, 146, 138, 160),
               width=SS)
    d.line([(W * 0.34, H * 0.14), (W * 0.38, H - 46 * SS)], fill=(120, 116, 108, 200), width=SS)
    # vuong mien nut dat lech tren mat ghe
    cx, cy = W * 0.40, H - 46 * SS
    d.polygon([(cx - 9 * SS, cy), (cx - 7 * SS, cy - 8 * SS), (cx - 3 * SS, cy - 3 * SS),
               (cx, cy - 10 * SS), (cx + 3 * SS, cy - 3 * SS), (cx + 7 * SS, cy - 8 * SS),
               (cx + 9 * SS, cy)], fill=GOLD + (255,))
    d.line([(cx - 9 * SS, cy), (cx + 9 * SS, cy)], fill=TERRA_D + (255,), width=SS)
    speck(d, 3, (W * 0.3, H * 0.1, W * 0.7, H - 30 * SS), [SANDSTONE_D], 26, 1.2)
    return finish(im, w, h)


# ---------------------------------------------------------------- thap nuoc

def water_tower():
    w, h = 256, 448
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 8 * SS, W * 0.46, 8 * SS)
    bx0, bx1 = 58 * SS, W - 58 * SS
    body_top = H * 0.34
    body_bot = H - 8 * SS
    vgrad(d, (bx0, body_top, bx1, body_bot), SANDSTONE_L, SANDSTONE_D)
    brick_courses(d, (bx0, body_top, bx1, body_bot), SANDSTONE_D, 12)
    speck(d, 12, (bx0, body_top, bx1, body_bot), [SANDSTONE_D, SANDSTONE_L], 90, 1.5)
    d.rectangle([bx0, body_top, bx1, body_bot], outline=A(INK, 190), width=SS)
    d.rectangle([bx0, body_bot - 14 * SS, bx1, body_bot], fill=(0, 0, 0, 30))
    # dai go mem dau thap + cot cheo
    d.rectangle([bx0 - 12 * SS, body_top - 8 * SS, bx1 + 12 * SS, body_top], fill=TIMBER_D + (255,))
    for sx in (-1, 1):
        d.line([(W / 2 + sx * (bx1 - bx0) / 2, body_top), (W / 2 + sx * ((bx1 - bx0) / 2 + 10 * SS),
                 body_top - 26 * SS)], fill=TIMBER_D + (255,), width=3 * SS)
    # bon nuoc go lon tren dinh: than tru dai sat + nap non + van
    tx0, tx1 = 30 * SS, W - 30 * SS
    ttop, tbot = H * 0.055, body_top - 24 * SS
    vgrad(d, (tx0, ttop + 12 * SS, tx1, tbot), WOOD, WOOD_D)
    for fx in range(int(tx0 + 14 * SS), int(tx1 - 8 * SS), 18 * SS):
        d.line([(fx, ttop + 14 * SS), (fx, tbot)], fill=A(TIMBER_D, 130), width=SS)
    for by in (ttop + 22 * SS, (ttop + tbot) / 2, tbot - 12 * SS):
        d.rectangle([tx0 - 2 * SS, by, tx1 + 2 * SS, by + 5 * SS], fill=(70, 72, 78, 255))
    d.polygon([(tx0 - 6 * SS, ttop + 14 * SS), (tx1 + 6 * SS, ttop + 14 * SS), (W / 2, ttop - 12 * SS)],
              fill=TERRA + (255,))
    d.polygon([(W / 2, ttop - 12 * SS), (tx1 + 6 * SS, ttop + 14 * SS), (W / 2, ttop + 14 * SS)],
              fill=(0, 0, 0, 30))
    d.line([(tx0 - 6 * SS, ttop + 14 * SS), (W / 2, ttop - 12 * SS), (tx1 + 6 * SS, ttop + 14 * SS)],
           fill=A(TERRA_D, 255), width=2 * SS)
    # ong nuoc xuong + van khoa + vet nuoc chay
    d.rectangle([W / 2 - 4 * SS, tbot, W / 2 + 4 * SS, body_bot - 30 * SS], fill=(96, 100, 108, 255))
    d.ellipse([W / 2 - 8 * SS, body_bot - 44 * SS, W / 2 + 8 * SS, body_bot - 28 * SS],
              outline=GOLD + (255,), width=2 * SS)
    d.line([(W / 2, body_bot - 36 * SS), (W / 2 + 8 * SS, body_bot - 36 * SS)],
           fill=GOLD + (255,), width=2 * SS)
    d.rectangle([W / 2 + 6 * SS, body_top + 10 * SS, W / 2 + 10 * SS, body_bot - 50 * SS],
                fill=(70, 110, 120, 44))
    # cua + cua so hep + thang go dua len
    door(d, W / 2 - 34 * SS, body_bot - 42 * SS, 24 * SS, 42 * SS)
    small_window(d, W / 2 + 16 * SS, body_top + 30 * SS, 13 * SS, 20 * SS, lit=True, shutter=False)
    for i in range(5):
        yy = body_top + 44 * SS + i * 20 * SS
        d.rectangle([bx1 - 12 * SS, yy, bx1 - 2 * SS, yy + 3 * SS], fill=TIMBER_D + (255,))
    d.rectangle([bx1 - 13 * SS, body_top + 40 * SS, bx1 - 11 * SS, body_bot - 10 * SS],
                fill=TIMBER_D + (255,))
    return finish(im, w, h)


def main():
    save(adobe_house(384, 320, ADOBE, ADOBE_L, ADOBE_D, 21), "solmaris_house_a.png")
    save(adobe_house(448, 352, TERRA, TERRA_L, TERRA_D, 22, dome=True), "solmaris_house_b.png")
    save(adobe_house(320, 288, WHITEWASH, (246, 236, 208), WHITEWASH_D, 23, tower_bump=True),
         "solmaris_house_c.png")
    save(bazaar_stall(320, 288, CRIMSON, (110, 36, 40), 31), "solmaris_stall_a.png")
    save(bazaar_stall(256, 256, TEAL, (44, 104, 104), 32), "solmaris_stall_b.png")
    save(council_hall(), "solmaris_council.png")
    save(empty_throne(), "solmaris_throne.png")
    save(water_tower(), "solmaris_water_tower.png")


if __name__ == "__main__":
    main()
