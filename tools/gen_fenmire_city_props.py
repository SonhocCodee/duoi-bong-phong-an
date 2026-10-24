#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sinh prop NOI THANH FENMIRE: nha san (4 bien the), sap be (3 bien the),
den Sanctum of the Sunken Tide (module lon), thuyen con + thuyen pha,
cot den cho noi, dong muoi. Ve supersample 2x bang PIL roi downscale
LANCZOS - cung chuan pipeline art game (xem gen_city_props.py).
Chay: python3 tools/gen_fenmire_city_props.py
Dau ra: game/assets/props/stilt_house_{a,b,c,d}.png, raft_stall_{a,b,c}.png,
temple_sanctum.png, boat_small.png, boat_ferry.png, market_lamp.png,
salt_pile.png
"""
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "game", "assets", "props")
SS = 2

INK = (38, 32, 26, 255)
TIMBER = (104, 74, 48)
TIMBER_D = (78, 54, 34)
WOOD = (140, 102, 62)
WOOD_D = (106, 74, 44)
PLANKC = (150, 116, 78)
THATCH = (168, 138, 84)
THATCH_D = (128, 102, 58)
STONE = (128, 130, 124)
STONE_D = (92, 94, 90)
STONE_L = (160, 162, 154)
TEAL = (52, 96, 92)
PURPLE = (96, 70, 128)


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


def soft_shadow(d, cx, cy, rx, ry, alpha=80):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(16, 22, 18, alpha))


def speck(d, seed, box, cols, n, r=1.5):
    rng = random.Random(seed)
    x0, y0, x1, y1 = box
    for _ in range(n):
        x = rng.uniform(x0, x1); y = rng.uniform(y0, y1)
        c = rng.choice(cols)
        d.ellipse([x - r, y - r, x + r, y + r], fill=A(c, rng.randint(45, 105)))


def vgrad(d, box, top, bot):
    x0, y0, x1, y1 = box
    steps = max(2, int(y1 - y0))
    for i in range(steps):
        t = i / (steps - 1)
        c = tuple(int(top[k] + (bot[k] - top[k]) * t) for k in range(3)) + (255,)
        d.line([(x0, y0 + i), (x1, y0 + i)], fill=c)


def lantern(d, x, y, s=1.0, col=(255, 196, 96)):
    d.rectangle([x - 1 * SS, y - 7 * SS * s, x + 1 * SS, y], fill=TIMBER_D + (255,))
    d.ellipse([x - 5 * SS * s, y, x + 5 * SS * s, y + 10 * SS * s], fill=col + (235,))
    d.ellipse([x - 8 * SS * s, y - 2 * SS * s, x + 8 * SS * s, y + 12 * SS * s],
              fill=A(col, 36))


def window_lit(d, x, y, w, h, lit=True):
    d.rectangle([x, y, x + w, y + h], fill=TIMBER_D + (255,))
    c = (255, 214, 130, 255) if lit else (64, 80, 88, 255)
    d.rectangle([x + 2 * SS, y + 2 * SS, x + w - 2 * SS, y + h - 2 * SS], fill=c)
    d.line([(x + w / 2, y), (x + w / 2, y + h)], fill=TIMBER_D + (255,), width=SS)


def roof_thatch(d, x0, y0, x1, ridge_y, col, col_d, seed=1):
    cx = (x0 + x1) / 2
    d.polygon([(x0, y0), (x1, y0), (cx, ridge_y)], fill=col + (255,))
    shade = tuple(int(col[k] * 0.81 + (20, 14, 8)[k] * 0.19) for k in range(3))
    d.polygon([(cx, ridge_y), (x1, y0), (cx, y0)], fill=shade + (255,))
    rng = random.Random(seed)
    rows = 8
    for i in range(1, rows + 1):
        t = i / rows
        yy = ridge_y + (y0 - ridge_y) * t
        half = (x1 - x0) / 2 * t
        d.line([(cx - half, yy), (cx + half, yy)], fill=col_d + (255,), width=2 * SS)
        tx = cx - half + rng.uniform(0, 6 * SS)
        while tx < cx + half - 3 * SS:
            d.line([(tx, yy), (tx + 2 * SS, yy + (y0 - ridge_y) / rows * 0.8)],
                   fill=col_d + (255,), width=SS)
            tx += rng.uniform(9, 15) * SS
    d.line([(x0, y0), (cx, ridge_y), (x1, y0)], fill=col_d + (255,), width=2 * SS)
    d.rectangle([x0, y0, x1, y0 + 4 * SS], fill=col_d + (255,))


def roof_plank(d, x0, y0, x1, ridge_y, col, col_d, seed=1):
    cx = (x0 + x1) / 2
    d.polygon([(x0, y0), (x1, y0), (cx, ridge_y)], fill=col + (255,))
    shade = tuple(int(col[k] * 0.80 + (16, 10, 20)[k] * 0.20) for k in range(3))
    d.polygon([(cx, ridge_y), (x1, y0), (cx, y0)], fill=shade + (255,))
    for i in range(1, 7):
        t = i / 6.0
        yy = ridge_y + (y0 - ridge_y) * t
        half = (x1 - x0) / 2 * t
        d.line([(cx - half, yy), (cx + half, yy)], fill=col_d + (255,), width=2 * SS)
    d.line([(x0, y0), (cx, ridge_y), (x1, y0)], fill=col_d + (255,), width=2 * SS)
    d.rectangle([x0, y0, x1, y0 + 4 * SS], fill=col_d + (255,))


def stilt_house(w, h, wall_col, roof_kind, roof_col, roof_d, seed, floors=1,
                net_side=0):
    """Nha san: coc cao o phan duoi (nuoc ngap chan coc), san go, tuong van,
    mai doc, cau thang van xuong phia truoc, long ga duoi san."""
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    rng = random.Random(seed * 17 + 3)
    soft_shadow(d, W / 2 + 8 * SS, H - 5 * SS, W * 0.48, 7 * SS, 90)
    margin = 16 * SS
    floor_y = H * 0.66           # mat san nha
    wall_top = H * (0.30 if floors == 1 else 0.36)
    # --- coc san: cot go cham xuong day anh (chan o nuoc) ---
    n_piles = max(3, w // 110)
    for i in range(n_piles):
        px = margin + 6 * SS + i * (W - 2 * margin - 12 * SS) / max(1, n_piles - 1)
        d.rectangle([px, floor_y, px + 9 * SS, H - 4 * SS], fill=TIMBER_D + (255,))
        d.rectangle([px, floor_y + 22 * SS, px + 9 * SS, floor_y + 27 * SS],
                    fill=(52, 62, 52, 255))  # vach nuoc tren coc
        d.line([(px + 9 * SS, floor_y + 4 * SS), (px - 12 * SS, H - 6 * SS)],
               fill=TIMBER_D + (255,), width=3 * SS)  # thanh cheo
    # long ga duoi san (ben trai) + thuyen con neo duoi san (ben phai)
    gx = margin + 14 * SS
    gy = floor_y + 16 * SS
    for k in range(4):
        d.line([(gx + k * 7 * SS, gy), (gx + k * 7 * SS, gy + 20 * SS)],
               fill=(70, 60, 48, 220), width=SS)
    d.rectangle([gx, gy, gx + 28 * SS, gy + 20 * SS], outline=(70, 60, 48, 235), width=SS)
    d.ellipse([gx + 8 * SS, gy + 7 * SS, gx + 16 * SS, gy + 14 * SS], fill=(226, 220, 200, 255))
    # --- than nha: tuong van go doc + gradient sang tren toi duoi ---
    vgrad(d, (margin, wall_top, W - margin, floor_y), wall_col,
          tuple(max(0, c - 34) for c in wall_col))
    vx = margin + 10 * SS
    while vx < W - margin - 4 * SS:
        d.line([(vx, wall_top + 4 * SS), (vx, floor_y - 2 * SS)],
               fill=(60, 44, 30, 90), width=SS)
        vx += rng.uniform(13, 20) * SS
    d.rectangle([margin, wall_top, W - margin, floor_y], outline=INK, width=SS)
    d.rectangle([margin, wall_top, W - margin, wall_top + 6 * SS], fill=TIMBER + (255,))
    d.rectangle([margin, floor_y - 7 * SS, W - margin, floor_y], fill=TIMBER_D + (255,))
    for fx in (margin + 3 * SS, W - margin - 10 * SS):
        d.rectangle([fx, wall_top, fx + 7 * SS, floor_y], fill=TIMBER + (255,))
    speck(d, seed + 5, (margin, wall_top, W - margin, floor_y),
          [tuple(max(0, c - 40) for c in wall_col), (96, 138, 74)], 130, 1.3)
    # mai
    if roof_kind == "thatch":
        roof_thatch(d, margin - 12 * SS, wall_top + 2 * SS, W - margin + 12 * SS,
                    5 * SS, roof_col, roof_d, seed)
    else:
        roof_plank(d, margin - 12 * SS, wall_top + 2 * SS, W - margin + 12 * SS,
                   5 * SS, roof_col, roof_d, seed)
    # cua chinh + bac thang van xuong truoc san
    dw, dh = 32 * SS, int(floor_y - wall_top) - 14 * SS
    door_x = W / 2 - dw / 2 + rng.choice([-8, 0, 8]) * SS
    d.rectangle([door_x, floor_y - dh, door_x + dw, floor_y], fill=TIMBER_D + (255,))
    d.rectangle([door_x + 3 * SS, floor_y - dh + 3 * SS, door_x + dw - 3 * SS, floor_y],
                fill=WOOD_D + (255,))
    d.ellipse([door_x + dw - 9 * SS, floor_y - dh / 2 - 2 * SS,
               door_x + dw - 5 * SS, floor_y - dh / 2 + 2 * SS], fill=(230, 200, 110, 255))
    sx0 = door_x - 6 * SS
    for i in range(4):
        yy = floor_y + i * 9 * SS
        d.rectangle([sx0 - i * 2 * SS, yy, sx0 + dw + 12 * SS + i * 2 * SS, yy + 4 * SS],
                    fill=PLANKC + (255,))
    # cua so 2 ben
    nw = 2 if w < 560 else 3
    for i in range(nw):
        wx = margin + (i + 0.5) * (W - 2 * margin) / nw - 11 * SS
        if abs(wx + 11 * SS - W / 2) < 30 * SS:
            continue
        window_lit(d, wx, wall_top + 15 * SS, 22 * SS, 24 * SS, lit=(i % 2 == 0))
    if floors == 2:
        for i in range(nw):
            wx = margin + (i + 0.5) * (W - 2 * margin) / nw - 10 * SS
            window_lit(d, wx, wall_top * 0.52, 20 * SS, 22 * SS, lit=(i % 2 == 1))
    # luoi phoi truoc hien (1 ben)
    if net_side != 0:
        nx = margin + 8 * SS if net_side < 0 else W - margin - 66 * SS
        ny = floor_y - 30 * SS
        for gx2 in range(0, 60, 10):
            d.line([(nx + gx2 * SS, ny), (nx + gx2 * SS, ny + 22 * SS)],
                   fill=(200, 205, 190, 255), width=SS)
        for gy2 in range(0, 24, 8):
            d.line([(nx, ny + gy2 * SS), (nx + 58 * SS, ny + gy2 * SS)],
                   fill=(200, 205, 190, 255), width=SS)
        for fx in range(6, 56, 12):
            d.ellipse([nx + fx * SS, ny + 8 * SS, nx + (fx + 5) * SS, ny + 13 * SS],
                      fill=(196, 178, 140, 255))  # ca kho treo tren luoi
    lantern(d, W - margin - 4 * SS, wall_top + 10 * SS, 0.9)
    return finish(im, w, h)


def raft_stall(kind, seed):
    """Sap be 5x3 o (320x192): be go + mai bat + hang hoa theo loai."""
    w, h = 320, 192
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    rng = random.Random(seed)
    soft_shadow(d, W / 2, H - 6 * SS, W * 0.49, 6 * SS, 70)
    # be: hang khuc go ngang + day van
    raft_y = H - 52 * SS
    for i in range(5):
        yy = raft_y + i * 9 * SS
        d.rectangle([6 * SS, yy, W - 6 * SS, yy + 7 * SS], fill=WOOD + (255,) if i % 2 else WOOD_D + (255,))
    d.rectangle([6 * SS, raft_y, W - 6 * SS, raft_y + 3 * SS], fill=PLANKC + (255,))
    # 4 cot + quay hang
    for px in (16 * SS, W - 22 * SS):
        d.rectangle([px, H * 0.26, px + 6 * SS, raft_y + 4 * SS], fill=TIMBER_D + (255,))
    counter_y = raft_y - 16 * SS
    d.rectangle([10 * SS, counter_y, W - 10 * SS, raft_y], fill=WOOD + (255,))
    d.rectangle([10 * SS, counter_y, W - 10 * SS, counter_y + 5 * SS], fill=WOOD_D + (255,))
    # hang hoa
    if kind == "fish":
        for i in range(6):
            bx = (18 + i * 46 + rng.randint(-3, 3)) * SS
            d.rectangle([bx, counter_y - 13 * SS, bx + 34 * SS, counter_y], fill=(96, 74, 50, 255))
            for f in range(3):
                fx = bx + (4 + f * 10) * SS
                d.ellipse([fx, counter_y - 11 * SS, fx + 8 * SS, counter_y - 5 * SS],
                          fill=(168, 182, 178, 255))
                d.polygon([(fx + 8 * SS, counter_y - 8 * SS), (fx + 12 * SS, counter_y - 11 * SS),
                           (fx + 12 * SS, counter_y - 5 * SS)], fill=(140, 152, 148, 255))
        d.line([(30 * SS, H * 0.30), (30 * SS, counter_y - 20 * SS)], fill=TIMBER_D + (255,), width=SS)
        d.ellipse([22 * SS, counter_y - 32 * SS, 38 * SS, counter_y - 18 * SS], fill=(178, 60, 54, 255))
    elif kind == "medicine":
        for i in range(7):
            bx = (20 + i * 40 + rng.randint(-2, 2)) * SS
            bh = rng.choice([16, 21, 13]) * SS
            d.rectangle([bx, counter_y - bh, bx + 9 * SS, counter_y], fill=(112, 84, 150, 255))
            d.rectangle([bx + 2 * SS, counter_y - bh - 4 * SS, bx + 7 * SS, counter_y - bh],
                        fill=(70, 54, 96, 255))
            d.rectangle([bx + 2 * SS, counter_y - bh + 4 * SS, bx + 7 * SS, counter_y - bh + 9 * SS],
                        fill=(226, 214, 240, 220))
        d.rectangle([W * 0.62, counter_y - 30 * SS, W * 0.62 + 44 * SS, counter_y - 14 * SS],
                    fill=(88, 62, 118, 255))  # hop thuoc tim cua giao phai
    else:  # herb
        for i in range(6):
            bx = (18 + i * 46 + rng.randint(-3, 3)) * SS
            d.ellipse([bx, counter_y - 15 * SS, bx + 32 * SS, counter_y], fill=(150, 124, 74, 255))
            for lf in range(5):
                lx = bx + rng.randint(4, 24) * SS
                d.ellipse([lx, counter_y - rng.randint(16, 24) * SS, lx + 5 * SS,
                           counter_y - rng.randint(10, 15) * SS], fill=(104, 148, 76, 255))
    # mai bat soc
    top = 14 * SS
    awn = {"fish": (178, 92, 62), "medicine": PURPLE, "herb": (84, 128, 80)}[kind]
    awn_d = tuple(max(0, c - 44) for c in awn)
    d.polygon([(0, H * 0.30), (W, H * 0.30), (W - 14 * SS, top), (14 * SS, top)], fill=awn + (255,))
    for i in range(0, 8, 2):
        x0 = 14 * SS + (W - 28 * SS) * i / 8
        x1 = 14 * SS + (W - 28 * SS) * (i + 1) / 8
        d.polygon([(x0, H * 0.30), (x1, H * 0.30), (x1 - 7 * SS, top), (x0 - 7 * SS, top)],
                  fill=A(awn_d, 255))
    lantern(d, W - 20 * SS, H * 0.30, 0.8)
    return finish(im, w, h)


def temple():
    """Den Sanctum of the Sunken Tide: nen da uot, than da reu, mai 3 lop
    teal-tim, tuong than mat mai nhan o cua, chuong trieu lon."""
    w, h = 1408, 960
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    rng = random.Random(99)
    soft_shadow(d, W / 2, H - 8 * SS, W * 0.49, 10 * SS, 95)
    base_y = H - 10 * SS
    # nen da 2 bac
    d.rectangle([30 * SS, base_y - 26 * SS, W - 30 * SS, base_y], fill=STONE_D + (255,))
    d.rectangle([52 * SS, base_y - 46 * SS, W - 52 * SS, base_y - 26 * SS], fill=STONE + (255,))
    speck(d, 41, (30 * SS, base_y - 46 * SS, W - 30 * SS, base_y), [STONE_L, (96, 138, 74)], 60, 1.8)
    # than den da
    bx0, bx1 = 150 * SS, W - 150 * SS
    wall_top = H * 0.46
    vgrad(d, (bx0, wall_top, bx1, base_y - 46 * SS), (142, 144, 134), (104, 106, 100))
    d.rectangle([bx0, wall_top, bx1, base_y - 46 * SS], outline=A(INK, 200), width=SS)
    speck(d, 43, (bx0, wall_top, bx1, base_y - 46 * SS), [(96, 138, 74), STONE_D, STONE_L], 200, 1.6)
    yy = wall_top + 18 * SS
    while yy < base_y - 52 * SS:
        d.line([(bx0, yy), (bx1, yy)], fill=A(STONE_D, 130), width=SS)
        yy += 20 * SS
    # cot da 2 ben cua + cua lon toi
    for sx in (-1, 1):
        px = W / 2 + sx * 120 * SS
        d.rectangle([px - 16 * SS, wall_top - 8 * SS, px + 16 * SS, base_y - 46 * SS], fill=STONE_L + (255,))
        d.rectangle([px - 20 * SS, wall_top - 14 * SS, px + 20 * SS, wall_top - 2 * SS], fill=STONE_D + (255,))
    dw = 110 * SS
    door_y = base_y - 46 * SS - 150 * SS
    d.rectangle([W / 2 - dw / 2, door_y, W / 2 + dw / 2, base_y - 46 * SS], fill=(36, 32, 34, 255))
    d.rectangle([W / 2 - dw / 2 + 6 * SS, door_y + 6 * SS, W / 2 + dw / 2 - 6 * SS, base_y - 46 * SS],
                fill=(52, 44, 50, 255))
    # tuong than mat mai nhan tren cua: vong tron + than mo khong mat
    cx, cy = W / 2, door_y - 34 * SS
    d.ellipse([cx - 30 * SS, cy - 44 * SS, cx + 30 * SS, cy + 16 * SS], fill=(168, 166, 156, 255))
    d.ellipse([cx - 30 * SS, cy - 44 * SS, cx + 30 * SS, cy + 16 * SS], outline=STONE_D + (255,), width=2 * SS)
    d.rectangle([cx - 12 * SS, cy - 30 * SS, cx + 12 * SS, cy - 24 * SS], fill=(150, 148, 140, 160))
    # mai 3 lop
    tiers = [(bx0 - 30 * SS, bx1 + 30 * SS, wall_top + 4 * SS, H * 0.335, (58, 84, 88)),
             (bx0 + 40 * SS, bx1 - 40 * SS, H * 0.345, H * 0.225, (66, 74, 104)),
             (bx0 + 130 * SS, bx1 - 130 * SS, H * 0.235, H * 0.115, (80, 66, 110))]
    for i, (x0, x1, y0, ry, col) in enumerate(tiers):
        col_d = tuple(max(0, c - 30) for c in col)
        roof_plank(d, x0, y0, x1, ry, col, col_d, 50 + i)
        # dau mai cong 2 ben
        d.polygon([(x0, y0), (x0 - 12 * SS, y0 - 10 * SS), (x0 + 14 * SS, y0 - 2 * SS)], fill=col_d + (255,))
        d.polygon([(x1, y0), (x1 + 12 * SS, y0 - 10 * SS), (x1 - 14 * SS, y0 - 2 * SS)], fill=col_d + (255,))
    # dinh vang + chuong trieu treo duoi mai giua
    d.ellipse([W / 2 - 7 * SS, H * 0.115 - 16 * SS, W / 2 + 7 * SS, H * 0.115 - 2 * SS],
              fill=(226, 184, 92, 255))
    bx = W / 2 + 190 * SS
    d.line([(bx, H * 0.345), (bx, H * 0.345 + 14 * SS)], fill=TIMBER_D + (255,), width=2 * SS)
    d.polygon([(bx - 13 * SS, H * 0.345 + 30 * SS), (bx + 13 * SS, H * 0.345 + 30 * SS),
               (bx + 9 * SS, H * 0.345 + 14 * SS), (bx - 9 * SS, H * 0.345 + 14 * SS)],
              fill=(178, 148, 84, 255))
    d.rectangle([bx - 15 * SS, H * 0.345 + 30 * SS, bx + 15 * SS, H * 0.345 + 34 * SS],
                fill=(140, 114, 62, 255))
    # den tim + bua giay 2 ben cua
    for sx in (-1, 1):
        lantern(d, W / 2 + sx * 88 * SS, door_y + 8 * SS, 1.1, col=(196, 150, 255))
        px = W / 2 + sx * 150 * SS
        d.rectangle([px - 7 * SS, wall_top + 12 * SS, px + 7 * SS, wall_top + 52 * SS],
                    fill=(232, 224, 200, 235))
        d.line([(px, wall_top + 20 * SS), (px, wall_top + 44 * SS)], fill=PURPLE + (255,), width=SS)
    return finish(im, w, h)


def boat(w, h, seed, ferry=False):
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    rng = random.Random(seed)
    soft_shadow(d, W / 2, H - 4 * SS, W * 0.48, 4 * SS, 60)
    cy = H * 0.52
    hull_h = (30 if ferry else 24) * SS
    d.polygon([(8 * SS, cy - hull_h / 2), (W - 8 * SS, cy - hull_h / 2),
               (W - 26 * SS, cy + hull_h / 2), (26 * SS, cy + hull_h / 2)], fill=WOOD_D + (255,))
    d.polygon([(2 * SS, cy - hull_h / 2 - 4 * SS), (14 * SS, cy - hull_h / 2 + 2 * SS),
               (10 * SS, cy - hull_h / 2 + 6 * SS)], fill=TIMBER_D + (255,))  # mui nhon
    d.rectangle([14 * SS, cy - hull_h / 2 + 3 * SS, W - 14 * SS, cy - hull_h / 2 + 8 * SS],
                fill=PLANKC + (255,))
    for i in range(3 if not ferry else 5):
        bx = W * (0.24 + 0.16 * i)
        d.rectangle([bx, cy - hull_h / 2 + 6 * SS, bx + 4 * SS, cy + hull_h / 2 - 4 * SS],
                    fill=TIMBER_D + (255,))
    if ferry:
        d.rectangle([W * 0.34, cy - hull_h / 2 - 16 * SS, W * 0.66, cy - hull_h / 2 + 2 * SS],
                    fill=THATCH + (255,))  # mai che pha
        for px in (W * 0.36, W * 0.62):
            d.rectangle([px, cy - hull_h / 2 - 16 * SS, px + 4 * SS, cy], fill=TIMBER_D + (255,))
        for i in range(3):
            bx = W * (0.38 + 0.1 * i)
            d.rectangle([bx, cy - 6 * SS, bx + 12 * SS, cy + 6 * SS], fill=(150, 124, 74, 255))
    else:
        d.ellipse([W * 0.40, cy - 8 * SS, W * 0.40 + 16 * SS, cy + 2 * SS], fill=(168, 182, 178, 255))
        d.rectangle([W * 0.60, cy - 7 * SS, W * 0.60 + 18 * SS, cy + 3 * SS], fill=(150, 124, 74, 255))
    # mai cheo
    d.line([(W * 0.68, cy - hull_h / 2), (W * 0.90, cy + hull_h / 2 + 10 * SS)],
           fill=TIMBER_D + (255,), width=3 * SS)
    d.ellipse([W * 0.90 - 5 * SS, cy + hull_h / 2 + 8 * SS, W * 0.90 + 5 * SS,
               cy + hull_h / 2 + 16 * SS], outline=WOOD + (255,), width=2 * SS)
    lantern(d, 16 * SS, cy - hull_h / 2 - 12 * SS, 0.7)
    return finish(im, w, h)


def market_lamp():
    w, h = 96, 320
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 5 * SS, 26 * SS, 5 * SS, 70)
    # be co dinh nho duoi cot
    d.rectangle([W / 2 - 26 * SS, H - 22 * SS, W / 2 + 26 * SS, H - 5 * SS], fill=WOOD_D + (255,))
    d.rectangle([W / 2 - 26 * SS, H - 22 * SS, W / 2 + 26 * SS, H - 18 * SS], fill=PLANKC + (255,))
    d.rectangle([W / 2 - 4 * SS, 36 * SS, W / 2 + 4 * SS, H - 18 * SS], fill=TIMBER_D + (255,))
    d.line([(W / 2 - 4 * SS, 90 * SS), (W / 2 - 22 * SS, H - 20 * SS)], fill=A(TIMBER_D, 180), width=2 * SS)
    d.line([(W / 2 + 4 * SS, 90 * SS), (W / 2 + 22 * SS, H - 20 * SS)], fill=A(TIMBER_D, 180), width=2 * SS)
    # long den lon
    d.ellipse([W / 2 - 26 * SS, 6 * SS, W / 2 + 26 * SS, 40 * SS], fill=(255, 196, 96, 46))
    d.rectangle([W / 2 - 13 * SS, 10 * SS, W / 2 + 13 * SS, 36 * SS], fill=(255, 208, 110, 245))
    d.rectangle([W / 2 - 15 * SS, 7 * SS, W / 2 + 15 * SS, 11 * SS], fill=TIMBER_D + (255,))
    d.rectangle([W / 2 - 15 * SS, 35 * SS, W / 2 + 15 * SS, 39 * SS], fill=TIMBER_D + (255,))
    d.ellipse([W / 2 - 4 * SS, 17 * SS, W / 2 + 4 * SS, 29 * SS], fill=(255, 244, 200, 255))
    return finish(im, w, h)


def salt_pile():
    w, h = 128, 96
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 5 * SS, W * 0.46, 5 * SS, 60)
    d.rectangle([6 * SS, H - 16 * SS, W - 6 * SS, H - 5 * SS], fill=WOOD_D + (255,))  # bạt/ván lót
    for (cx, cy, r) in [(W * 0.30, H - 14 * SS, 22 * SS), (W * 0.58, H - 14 * SS, 30 * SS),
                        (W * 0.82, H - 14 * SS, 18 * SS)]:
        d.polygon([(cx - r, H - 13 * SS), (cx + r, H - 13 * SS), (cx, cy - r * 1.15)],
                  fill=(238, 236, 228, 255))
        d.polygon([(cx, cy - r * 1.15), (cx + r, H - 13 * SS), (cx, H - 13 * SS)],
                  fill=(208, 206, 198, 255))
    speck(d, 7, (W * 0.1, H * 0.3, W * 0.9, H * 0.9), [(210, 208, 198)], 40, 1.1)
    return finish(im, w, h)


def main():
    save(stilt_house(512, 448, (172, 148, 108), "thatch", THATCH, THATCH_D, 1, 1, -1), "stilt_house_a.png")
    save(stilt_house(640, 480, (158, 128, 96), "plank", (94, 110, 118), (62, 76, 84), 2, 1, 1), "stilt_house_b.png")
    save(stilt_house(448, 416, (182, 158, 122), "thatch", (146, 116, 70), (110, 86, 50), 3, 1, 0), "stilt_house_c.png")
    save(stilt_house(576, 512, (166, 138, 104), "plank", TEAL, (36, 66, 62), 4, 2, -1), "stilt_house_d.png")
    save(raft_stall("fish", 11), "raft_stall_a.png")
    save(raft_stall("medicine", 12), "raft_stall_b.png")
    save(raft_stall("herb", 13), "raft_stall_c.png")
    save(temple(), "temple_sanctum.png")
    save(boat(192, 96, 21), "boat_small.png")
    save(boat(256, 128, 22, ferry=True), "boat_ferry.png")
    save(market_lamp(), "market_lamp.png")
    save(salt_pile(), "salt_pile.png")


if __name__ == "__main__":
    main()
