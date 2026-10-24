#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sinh prop thanh Aldenmere (dot 2B): nha nhieu mau/co/mai, sap cho, tuong,
dai phun, thap canh, phu, than co thu, de ren, hinh nom, day phoi, ghe da.
Ve supersample 2x bang PIL roi downscale LANCZOS - cung chuan pipeline art game.
Chay: python3 tools/gen_city_props.py
"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "game", "assets", "props")
SS = 2

INK = (43, 34, 28, 255)
STONE = (148, 146, 140); STONE_L = (178, 176, 168); STONE_D = (108, 106, 100)
PLASTER = (216, 199, 168); PLASTER_D = (188, 168, 138)
TIMBER = (110, 78, 52); TIMBER_D = (84, 58, 38)
WOOD = (146, 106, 66); WOOD_D = (112, 78, 46)


def A(c, a):
    return (c[0], c[1], c[2], a)


def canvas(w, h):
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))


def finish(im, w, h):
    return im.resize((w, h), Image.LANCZOS)


def save(im, name):
    im.save(os.path.join(OUT, name))
    print("prop:", name, im.size)


def soft_shadow(d, cx, cy, rx, ry, alpha=85):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(20, 26, 16, alpha))


def speck(d, seed, box, cols, n, r=1.6):
    rng = random.Random(seed)
    x0, y0, x1, y1 = box
    for _ in range(n):
        x = rng.uniform(x0, x1); y = rng.uniform(y0, y1)
        c = rng.choice(cols)
        d.ellipse([x - r, y - r, x + r, y + r], fill=A(c, rng.randint(50, 110)))


def vgrad(d, box, top, bot):
    x0, y0, x1, y1 = box
    steps = max(2, int(y1 - y0))
    for i in range(steps):
        t = i / (steps - 1)
        c = tuple(int(top[k] + (bot[k] - top[k]) * t) for k in range(3)) + (255,)
        d.line([(x0, y0 + i), (x1, y0 + i)], fill=c)


def window(d, x, y, w, h, lit=True):
    # cua che 2 ben
    d.rectangle([x - 5 * SS, y + 1 * SS, x - 1 * SS, y + h - 1 * SS], fill=TIMBER + (255,))
    d.rectangle([x + w + 1 * SS, y + 1 * SS, x + w + 5 * SS, y + h - 1 * SS], fill=TIMBER + (255,))
    d.rectangle([x, y, x + w, y + h], fill=TIMBER_D + (255,))
    c = (255, 214, 130, 255) if lit else (70, 84, 96, 255)
    d.rectangle([x + 2 * SS, y + 2 * SS, x + w - 2 * SS, y + h - 2 * SS], fill=c)
    d.line([(x + w / 2, y), (x + w / 2, y + h)], fill=TIMBER_D + (255,), width=SS)
    d.line([(x, y + h / 2), (x + w, y + h / 2)], fill=TIMBER_D + (255,), width=SS)
    # bau hoa duoi cua so: hop go + hoa mau + la
    d.rectangle([x - 3 * SS, y + h + 1 * SS, x + w + 3 * SS, y + h + 7 * SS],
                fill=TIMBER_D + (255,))
    frng = random.Random(int(x * 7 + y))
    for fx in range(int(x - 1 * SS), int(x + w + 1 * SS), 4 * SS):
        fc = frng.choice([(214, 84, 100), (240, 170, 80), (226, 120, 170), (240, 240, 230)])
        d.ellipse([fx, y + h - 1 * SS, fx + 3 * SS, y + h + 3 * SS], fill=fc + (255,))
        d.ellipse([fx + 1 * SS, y + h + 2 * SS, fx + 4 * SS, y + h + 5 * SS],
                  fill=(96, 140, 70, 255))


def roof(d, x0, y0, x1, ridge_y, col, col_d, seed=1):
    """Mai nha: dinh o giua, hang ngoi ngang dam + gach doc lech hang,
    slope phai toi hon (anh sang tu trai), vien dinh sang."""
    cx = (x0 + x1) / 2
    d.polygon([(x0, y0), (x1, y0), (cx, ridge_y)], fill=col + (255,))
    # shading 2 slope: trai sang nhe, phai toi
    d.polygon([(cx, ridge_y), (x1, y0), (cx, y0)], fill=(20, 10, 30, 44))
    d.polygon([(x0, y0), (cx, ridge_y), (cx, y0)], fill=(255, 244, 214, 20))
    rng = random.Random(seed)
    rows = 9
    prev_y, prev_half = ridge_y, 0.0
    for i in range(1, rows + 1):
        t = i / rows
        yy = ridge_y + (y0 - ridge_y) * t
        half = (x1 - x0) / 2 * t
        d.line([(cx - half, yy), (cx + half, yy)], fill=A(col_d, 205), width=2 * SS)
        # gach doc ngan giua 2 hang, lech nua nhip theo hang chan/le
        if i < rows:
            next_y = ridge_y + (y0 - ridge_y) * ((i + 1) / rows)
            tick_gap = 15 * SS
            off = (tick_gap / 2) if i % 2 else 0.0
            tx = cx - half + off + rng.uniform(0, 3 * SS)
            while tx < cx + half - 2 * SS:
                d.line([(tx, yy + 1 * SS), (tx, next_y - 1 * SS)],
                       fill=A(col_d, 120), width=SS)
                tx += tick_gap
        prev_y, prev_half = yy, half
    # vien mai + dinh mai sang + bong duoi mai
    d.line([(x0, y0), (cx, ridge_y), (x1, y0)], fill=A(col_d, 255), width=2 * SS)
    d.line([(cx, ridge_y), (cx, ridge_y + (y0 - ridge_y) * 0.30)],
           fill=(255, 240, 210, 110), width=2 * SS)
    d.rectangle([x0, y0, x1, y0 + 5 * SS], fill=(0, 0, 0, 46))


def door(d, x, y, w, h):
    d.rectangle([x, y, x + w, y + h], fill=TIMBER_D + (255,))
    d.rectangle([x + 2 * SS, y + 2 * SS, x + w - 2 * SS, y + h], fill=WOOD_D + (255,))
    d.ellipse([x + w - 8 * SS, y + h / 2 - 2 * SS, x + w - 4 * SS, y + h / 2 + 2 * SS],
              fill=(230, 200, 110, 255))


def house(w, h, wall_col, roof_col, roof_d, floors=1, seed=1, stone_base=True):
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    rng = random.Random(seed * 31 + 5)
    # bong do mem lech phai-xuong (1 huong nhat quan cho ca thanh)
    soft_shadow(d, W / 2 + 10 * SS, H - 6 * SS, W * 0.47, 9 * SS, 95)
    wall_top = H * (0.34 if floors == 1 else 0.40)
    margin = 14 * SS
    wall_bot = H - 6 * SS
    # tuong: gradient + texture vua (vet loang sang/toi + cham li ti)
    vgrad(d, (margin, wall_top, W - margin, wall_bot), wall_col,
          tuple(max(0, c - 30) for c in wall_col))
    # texture vua: chi dung hat li ti cung tong tuong (khong dung mang loang)
    speck(d, seed + 21, (margin, wall_top, W - margin, wall_bot),
          [tuple(max(0, c - 40) for c in wall_col), tuple(min(255, c + 22) for c in wall_col)],
          240, 1.3)
    # vet nuoc chay duoi mai + reu leo chan tuong
    for _ in range(5):
        sx = rng.uniform(margin + 8 * SS, W - margin - 10 * SS)
        d.rectangle([sx, wall_top + 6 * SS, sx + 2 * SS,
                     wall_top + rng.uniform(14, 30) * SS], fill=(80, 66, 48, 17))
    d.rectangle([margin, wall_top, W - margin, wall_bot], outline=A(INK, 200), width=SS)
    # da chan tuong: khoi da co gach noi
    if stone_base:
        bh = 13 * SS
        d.rectangle([margin, wall_bot - bh, W - margin, wall_bot], fill=STONE_D + (255,))
        sx = margin + 8 * SS
        while sx < W - margin - 6 * SS:
            d.rectangle([sx, wall_bot - bh + 2 * SS, sx + rng.uniform(10, 18) * SS,
                         wall_bot - 2 * SS], outline=A(STONE, 130), width=SS)
            sx += rng.uniform(16, 26) * SS
        speck(d, seed + 7, (margin, wall_bot - bh, W - margin, wall_bot), [STONE, STONE_L], 26)
    # khung xa go: ngang tren + cot goc day + nep cheo goc + cot giua
    d.rectangle([margin, wall_top, W - margin, wall_top + 6 * SS], fill=TIMBER + (255,))
    for fx in (margin + 3 * SS, W - margin - 10 * SS):
        d.rectangle([fx, wall_top, fx + 7 * SS, wall_bot], fill=A(TIMBER, 235))
        d.line([(fx, wall_top), (fx + 7 * SS, wall_top)], fill=TIMBER_D + (255,), width=SS)
    d.line([(margin + 3 * SS, wall_top + 22 * SS), (margin + 25 * SS, wall_top + 6 * SS)],
           fill=A(TIMBER, 220), width=4 * SS)
    d.line([(W - margin - 3 * SS, wall_top + 22 * SS), (W - margin - 25 * SS, wall_top + 6 * SS)],
           fill=A(TIMBER, 220), width=4 * SS)
    mid_x = margin + (W - 2 * margin) * (0.30 if seed % 2 else 0.68)
    d.rectangle([mid_x, wall_top + 6 * SS, mid_x + 5 * SS, wall_bot], fill=A(TIMBER, 150))
    # mai (cheo ra ngoai tuong) + bong duoi mai xuong tuong
    roof(d, margin - 10 * SS, wall_top + 2 * SS, W - margin + 10 * SS,
         6 * SS, roof_col, roof_d, seed)
    speck(d, seed + 3, (margin, 8 * SS, W - margin, wall_top), [roof_d], 40, 1.3)
    d.rectangle([margin, wall_top + 6 * SS, W - margin, wall_top + 12 * SS], fill=(30, 20, 14, 52))
    # ong khoi da tren mai (phia phai, moc tu giua slope) + khoi bay len
    chx = W * 0.70
    ch_top = wall_top * 0.42
    d.rectangle([chx, ch_top, chx + 21 * SS, wall_top - 4 * SS], fill=STONE_D + (255,))
    d.rectangle([chx - 2 * SS, ch_top - 4 * SS, chx + 23 * SS, ch_top + 1 * SS], fill=STONE + (255,))
    speck(d, seed + 13, (chx, ch_top + 2 * SS, chx + 21 * SS, wall_top - 6 * SS), [STONE, STONE_L], 14)
    for i, (sr, sa) in enumerate([(5 * SS, 60), (8 * SS, 38), (11 * SS, 20)]):
        cy = ch_top - 6 * SS - i * 4 * SS
        d.ellipse([chx + 5 * SS + i * 6 * SS, cy - sr * 0.6,
                   chx + 5 * SS + i * 6 * SS + sr * 2, cy + sr * 0.6],
                  fill=(228, 230, 232, sa))
    # dam go ngang giua tuong (chia tang)
    if floors == 2:
        d.rectangle([margin, wall_top + (H - 6 * SS - wall_top) * 0.52,
                     W - margin, wall_top + (H - 6 * SS - wall_top) * 0.52 + 4 * SS],
                    fill=A(TIMBER, 200))
    # cua chinh giua + cua so
    dw, dh = 34 * SS, 52 * SS
    door(d, W / 2 - dw / 2, H - 6 * SS - dh, dw, dh)
    # hien nho truoc cua: mai che cheo + 2 cot + den long ben cua
    py = H - 6 * SS - dh - 9 * SS
    d.polygon([(W / 2 - dw / 2 - 9 * SS, py + 7 * SS), (W / 2 + dw / 2 + 9 * SS, py + 7 * SS),
               (W / 2 + dw / 2 + 4 * SS, py), (W / 2 - dw / 2 - 4 * SS, py)],
              fill=A(roof_d, 255))
    d.line([(W / 2 - dw / 2 - 9 * SS, py + 7 * SS), (W / 2 + dw / 2 + 9 * SS, py + 7 * SS)],
           fill=A(roof_col, 255), width=2 * SS)
    for px in (W / 2 - dw / 2 - 7 * SS, W / 2 + dw / 2 + 3 * SS):
        d.rectangle([px, py + 7 * SS, px + 4 * SS, H - 8 * SS], fill=TIMBER_D + (255,))
    lx = W / 2 + dw / 2 + 13 * SS
    d.rectangle([lx, py + 12 * SS, lx + 2 * SS, py + 17 * SS], fill=TIMBER_D + (255,))
    d.ellipse([lx - 2 * SS, py + 17 * SS, lx + 4 * SS, py + 24 * SS], fill=(255, 196, 96, 235))
    d.ellipse([lx - 4 * SS, py + 15 * SS, lx + 6 * SS, py + 26 * SS], fill=(255, 190, 90, 40))
    d.rectangle([W / 2 - dw / 2 - 3 * SS, H - 8 * SS, W / 2 + dw / 2 + 3 * SS, H - 4 * SS],
                fill=STONE + (255,))  # bac them da
    nw = 2 if w < 340 else 3
    for i in range(nw):
        wx = margin + (i + 0.5) * (W - 2 * margin) / nw - 11 * SS
        if abs(wx + 11 * SS - W / 2) < 26 * SS:
            continue
        window(d, wx, wall_top + 16 * SS, 22 * SS, 26 * SS, lit=(i % 2 == 0))
    if floors == 2:
        for i in range(nw):
            wx = margin + (i + 0.5) * (W - 2 * margin) / nw - 10 * SS
            window(d, wx, wall_top * 0.50, 20 * SS, 24 * SS, lit=(i % 2 == 1))
    # reu chan tuong
    speck(d, seed + 11, (margin, H - 22 * SS, W - margin, H - 8 * SS),
          [(96, 138, 74), (120, 160, 88)], 22, 1.8)
    return finish(im, w, h)


def stall(awning_col, awning_d, seed=1):
    w, h = 384, 512
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 10 * SS, W * 0.47, 10 * SS)
    # 4 cot + quay hang phia duoi
    for px in (18 * SS, W - 24 * SS):
        d.rectangle([px, H * 0.30, px + 6 * SS, H - 8 * SS], fill=TIMBER_D + (255,))
    counter_y = H - 64 * SS
    d.rectangle([10 * SS, counter_y, W - 10 * SS, H - 8 * SS], fill=WOOD + (255,))
    d.rectangle([10 * SS, counter_y, W - 10 * SS, counter_y + 8 * SS], fill=WOOD_D + (255,))
    # hang hoa tren quay: thung + tui + chai (2 lop)
    rng = random.Random(seed)
    for i in range(7):
        bx = (14 + i * 25 + rng.randint(-2, 2)) * SS
        bh = rng.choice([20, 26, 17]) * SS
        by = counter_y - bh
        c = rng.choice([(196, 84, 60), (110, 160, 84), (226, 180, 84), (150, 110, 180)])
        d.rectangle([bx, by, bx + 21 * SS, counter_y], fill=c + (255,))
        d.rectangle([bx, by, bx + 21 * SS, by + 4 * SS], fill=A((60, 44, 34), 200))
    for i in range(4):
        bx = (30 + i * 42 + rng.randint(-3, 3)) * SS
        by = counter_y - 40 * SS
        c = rng.choice([(226, 180, 84), (196, 84, 60), (120, 170, 90)])
        d.rectangle([bx, by, bx + 16 * SS, counter_y - 24 * SS], fill=A(c, 255))
    # mai bat che: soc 2 mau
    top = 26 * SS
    d.polygon([(0, H * 0.34), (W, H * 0.34), (W - 16 * SS, top), (16 * SS, top)],
              fill=awning_col + (255,))
    stripes = 8
    for i in range(0, stripes, 2):
        x0 = 16 * SS + (W - 32 * SS) * i / stripes
        x1 = 16 * SS + (W - 32 * SS) * (i + 1) / stripes
        y0b = H * 0.34
        d.polygon([(x0, y0b), (x1, y0b), (x1 - 8 * SS, top), (x0 - 8 * SS, top)],
                  fill=A(awning_d, 255))
    d.line([(0, H * 0.34), (W, H * 0.34)], fill=A(INK, 160), width=SS)
    # hang treo duoi mai
    for i in range(4):
        hx = (40 + i * 78) * SS
        d.line([(hx, H * 0.34), (hx, H * 0.34 + 12 * SS)], fill=TIMBER_D + (255,), width=SS)
        d.ellipse([hx - 5 * SS, H * 0.34 + 12 * SS, hx + 5 * SS, H * 0.34 + 22 * SS],
                  fill=A(rng.choice([(226, 180, 84), (196, 84, 60), (120, 170, 90)]), 255))
    return finish(im, w, h)


def statue():
    w, h = 256, 448
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 8 * SS, W * 0.4, 9 * SS)
    # be 3 bac
    for i, (bw, by) in enumerate([(110, 26), (92, 24), (74, 22)]):
        yy = H - 8 * SS - (i + 1) * by * SS / 1.4
        d.rectangle([W / 2 - bw * SS, yy, W / 2 + bw * SS, yy + by * SS / 1.4],
                    fill=STONE_D + (255,) if i % 2 else STONE + (255,))
    top_y = H - 8 * SS - 52 * SS
    # tam bia khac o be: nen toi + 3 vach vang
    d.rectangle([W / 2 - 30 * SS, top_y + 14 * SS, W / 2 + 30 * SS, top_y + 40 * SS],
                fill=STONE_D + (255,))
    for i in range(3):
        d.line([(W / 2 - 20 * SS, top_y + (21 + i * 6) * SS),
                (W / 2 + 20 * SS, top_y + (21 + i * 6) * SS)], fill=(226, 184, 92, 200), width=SS)
    # than tuong: ao choang + kiem cam xuong
    cx = W / 2
    d.polygon([(cx - 30 * SS, top_y), (cx + 30 * SS, top_y), (cx + 20 * SS, top_y - 120 * SS),
               (cx - 20 * SS, top_y - 120 * SS)], fill=STONE + (255,))
    # shading nua phai ao choang + nep gap doc + vien toi
    d.polygon([(cx + 4 * SS, top_y), (cx + 30 * SS, top_y), (cx + 20 * SS, top_y - 120 * SS),
               (cx + 4 * SS, top_y - 120 * SS)], fill=(0, 0, 0, 36))
    for fx in (-16, -6, 12, 20):
        d.line([(cx + fx * SS, top_y - 4 * SS), (cx + (fx - 3) * SS, top_y - 112 * SS)],
               fill=A(STONE_D, 170), width=SS)
    d.line([(cx - 30 * SS, top_y), (cx - 20 * SS, top_y - 120 * SS)], fill=A(INK, 160), width=SS)
    d.line([(cx + 30 * SS, top_y), (cx + 20 * SS, top_y - 120 * SS)], fill=A(INK, 160), width=SS)
    d.polygon([(cx - 20 * SS, top_y - 120 * SS), (cx + 20 * SS, top_y - 120 * SS),
               (cx + 13 * SS, top_y - 168 * SS), (cx - 13 * SS, top_y - 168 * SS)],
              fill=STONE_L + (255,))
    d.polygon([(cx + 2 * SS, top_y - 120 * SS), (cx + 20 * SS, top_y - 120 * SS),
               (cx + 13 * SS, top_y - 168 * SS), (cx + 2 * SS, top_y - 168 * SS)], fill=(0, 0, 0, 30))
    # dau: bong mu tru + vong vang phong an
    d.ellipse([cx - 12 * SS, top_y - 196 * SS, cx + 12 * SS, top_y - 172 * SS], fill=STONE_L + (255,))
    d.arc([cx - 12 * SS, top_y - 197 * SS, cx + 12 * SS, top_y - 171 * SS], 300, 60,
          fill=(70, 62, 56, 200), width=3 * SS)
    d.rectangle([cx - 12 * SS, top_y - 192 * SS, cx + 12 * SS, top_y - 188 * SS],
                fill=(226, 184, 92, 255))
    # vong nguyet quế + mu
    d.arc([cx - 15 * SS, top_y - 200 * SS, cx + 15 * SS, top_y - 170 * SS], 200, 340,
          fill=(96, 138, 74, 255), width=3 * SS)
    # kiem: luoi sang + chuoi kiem vang
    d.rectangle([cx - 2 * SS, top_y - 150 * SS, cx + 2 * SS, top_y - 30 * SS], fill=(196, 194, 188, 255))
    d.rectangle([cx - 13 * SS, top_y - 148 * SS, cx + 13 * SS, top_y - 142 * SS], fill=(226, 184, 92, 255))
    d.rectangle([cx - 3 * SS, top_y - 156 * SS, cx + 3 * SS, top_y - 148 * SS], fill=STONE_D + (255,))
    # tay dang xuong nam chuoi kiem
    d.polygon([(cx - 20 * SS, top_y - 150 * SS), (cx - 4 * SS, top_y - 138 * SS),
               (cx - 8 * SS, top_y - 128 * SS), (cx - 24 * SS, top_y - 140 * SS)], fill=STONE + (255,))
    d.polygon([(cx + 20 * SS, top_y - 150 * SS), (cx + 4 * SS, top_y - 138 * SS),
               (cx + 8 * SS, top_y - 128 * SS), (cx + 24 * SS, top_y - 140 * SS)], fill=STONE + (255,))
    # re xuoi chan tuong (re da)
    for s in (-1, 1):
        d.line([(cx + s * 8 * SS, top_y - 4 * SS), (cx + s * 26 * SS, top_y + 6 * SS)],
               fill=STONE_D + (255,), width=3 * SS)
    speck(d, 5, (cx - 30 * SS, top_y - 190 * SS, cx + 30 * SS, top_y), [(96, 138, 74)], 30, 1.5)
    return finish(im, w, h)


def fountain():
    w = h = 768
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W = H = w * SS
    cx = cy = W / 2
    # bong + vien be 2 lop
    d.ellipse([cx - 372 * SS, cy - 372 * SS, cx + 372 * SS, cy + 372 * SS], fill=(20, 26, 16, 60))
    d.ellipse([cx - 368 * SS, cy - 368 * SS, cx + 368 * SS, cy + 368 * SS], fill=STONE_D + (255,))
    d.ellipse([cx - 344 * SS, cy - 344 * SS, cx + 344 * SS, cy + 344 * SS], fill=STONE + (255,))
    d.ellipse([cx - 322 * SS, cy - 322 * SS, cx + 322 * SS, cy + 322 * SS], fill=STONE_L + (255,))
    speck(d, 9, (cx - 360 * SS, cy - 360 * SS, cx + 360 * SS, cy + 360 * SS), [(96, 138, 74)], 26, 1.6)
    # khoet rong long be (de lo tile nuoc ben duoi khi dat trong game)
    mask = Image.new("L", im.size, 255)
    md = ImageDraw.Draw(mask)
    md.ellipse([cx - 298 * SS, cy - 298 * SS, cx + 298 * SS, cy + 298 * SS], fill=0)
    alpha = im.getchannel("A").point(lambda a: a)
    from PIL import ImageChops
    im.putalpha(ImageChops.multiply(alpha, mask))
    d = ImageDraw.Draw(im, "RGBA")
    d.ellipse([cx - 300 * SS, cy - 300 * SS, cx + 300 * SS, cy + 300 * SS], outline=A(STONE_D, 220), width=5 * SS)
    # tru giua + bup nuoc da
    d.ellipse([cx - 54 * SS, cy - 54 * SS, cx + 54 * SS, cy + 54 * SS], fill=STONE + (255,))
    d.ellipse([cx - 30 * SS, cy - 84 * SS, cx + 30 * SS, cy - 24 * SS], fill=STONE_L + (255,))
    return finish(im, w, h)


def tower():
    w, h = 384, 448
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 8 * SS, W * 0.48, 10 * SS)
    bx0, bx1 = 52 * SS, W - 52 * SS
    vgrad(d, (bx0, H * 0.30, bx1, H - 6 * SS), STONE_L, STONE_D)
    d.rectangle([bx0, H * 0.30, bx1, H - 6 * SS], outline=A(INK, 200), width=SS)
    speck(d, 4, (bx0, H * 0.30, bx1, H - 6 * SS), [STONE, STONE_D], 60, 1.8)
    # hang khoi da ngang + moi noi doc lech hang
    rngt = random.Random(4)
    yy = H * 0.30 + 16 * SS
    while yy < H - 10 * SS:
        d.line([(bx0, yy), (bx1, yy)], fill=A(STONE_D, 150), width=SS)
        jx = bx0 + rngt.uniform(6, 20) * SS
        while jx < bx1 - 4 * SS:
            d.line([(jx, yy), (jx, min(yy + 16 * SS, H - 6 * SS))], fill=A(STONE_D, 110), width=SS)
            jx += rngt.uniform(22, 38) * SS
        yy += 16 * SS
    # chan thap toi + bong phai
    d.rectangle([bx0, H - 22 * SS, bx1, H - 6 * SS], fill=(0, 0, 0, 34))
    d.rectangle([W / 2 + 14 * SS, H * 0.32, bx1, H - 6 * SS], fill=(0, 0, 0, 22))
    # cua so hep + cua chinh + co treo truoc thap
    window(d, W / 2 - 7 * SS, H * 0.44, 14 * SS, 22 * SS, lit=True)
    door(d, W / 2 - 13 * SS, H - 6 * SS - 40 * SS, 26 * SS, 40 * SS)
    d.polygon([(W / 2 + 34 * SS, H * 0.50), (W / 2 + 62 * SS, H * 0.50), (W / 2 + 62 * SS, H * 0.50 + 62 * SS),
               (W / 2 + 48 * SS, H * 0.50 + 48 * SS), (W / 2 + 34 * SS, H * 0.50 + 62 * SS)],
              fill=(148, 50, 58, 255))
    d.polygon([(W / 2 + 48 * SS, H * 0.50 + 16 * SS), (W / 2 + 55 * SS, H * 0.50 + 27 * SS),
               (W / 2 + 48 * SS, H * 0.50 + 38 * SS), (W / 2 + 41 * SS, H * 0.50 + 27 * SS)],
              fill=(226, 184, 92, 255))
    # dai lan can co rang cưa + mai non gach hang
    d.rectangle([bx0 - 10 * SS, H * 0.26, bx1 + 10 * SS, H * 0.32], fill=STONE_D + (255,))
    mx = bx0 - 10 * SS
    while mx < bx1 + 2 * SS:
        d.rectangle([mx, H * 0.26 - 7 * SS, mx + 12 * SS, H * 0.26], fill=STONE_D + (255,))
        mx += 22 * SS
    d.polygon([(bx0 - 16 * SS, H * 0.26), (bx1 + 16 * SS, H * 0.26), (W / 2, 8 * SS)],
              fill=(122, 62, 48, 255))
    for i in range(1, 6):
        t = i / 6.0
        ry = 8 * SS + (H * 0.26 - 8 * SS) * t
        rhw = (bx1 - bx0 + 32 * SS) / 2 * t
        d.line([(W / 2 - rhw, ry), (W / 2 + rhw, ry)], fill=A((84, 40, 34), 170), width=SS)
    d.polygon([(W / 2, 8 * SS), (bx1 + 16 * SS, H * 0.26), (W / 2, H * 0.26)], fill=(0, 0, 0, 36))
    d.line([(bx0 - 16 * SS, H * 0.26), (W / 2, 8 * SS), (bx1 + 16 * SS, H * 0.26)],
           fill=A((84, 40, 34), 255), width=2 * SS)
    speck(d, 6, (bx0, H * 0.62, bx1, H - 8 * SS), [(96, 138, 74)], 16, 1.6)
    return finish(im, w, h)


def palace():
    w, h = 1408, 768
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 10 * SS, W * 0.48, 12 * SS)
    # 2 canh phu
    for (x0, x1) in [(30 * SS, 430 * SS), (W - 430 * SS, W - 30 * SS)]:
        vgrad(d, (x0, H * 0.42, x1, H - 8 * SS), PLASTER, PLASTER_D)
        roof(d, x0 - 8 * SS, H * 0.42, x1 + 8 * SS, H * 0.20, (122, 62, 48), (84, 40, 34), 3)
        for i in range(3):
            window(d, x0 + (i + 0.5) * (x1 - x0) / 3 - 11 * SS, H * 0.52, 22 * SS, 28 * SS, lit=True)
    # keep giua cao
    kx0, kx1 = 470 * SS, W - 470 * SS
    vgrad(d, (kx0, H * 0.30, kx1, H - 8 * SS), (226, 210, 178), PLASTER)
    d.rectangle([kx0, H * 0.30, kx1, H - 8 * SS], outline=A(INK, 200), width=SS)
    roof(d, kx0 - 12 * SS, H * 0.30, kx1 + 12 * SS, H * 0.03, (96, 52, 60), (64, 34, 42), 8)
    # cua lon + cot
    dw = 74 * SS
    door(d, W / 2 - dw / 2, H - 8 * SS - 96 * SS, dw, 96 * SS)
    for sx in (-1, 1):
        px = W / 2 + sx * 92 * SS
        d.rectangle([px - 7 * SS, H * 0.36, px + 7 * SS, H - 8 * SS], fill=STONE_L + (255,))
    for i in (-1, 0, 1):
        window(d, W / 2 + i * 56 * SS - 11 * SS, H * 0.40, 22 * SS, 30 * SS, lit=(i == 0))
    # banner 2 ben cua
    for sx in (-1, 1):
        bx = W / 2 + sx * 130 * SS
        d.rectangle([bx - 11 * SS, H * 0.37, bx + 11 * SS, H * 0.37 + 74 * SS], fill=(116, 44, 52, 255))
        d.polygon([(bx - 11 * SS, H * 0.37 + 74 * SS), (bx + 11 * SS, H * 0.37 + 74 * SS),
                   (bx, H * 0.37 + 88 * SS)], fill=(116, 44, 52, 255))
        d.ellipse([bx - 5 * SS, H * 0.37 + 16 * SS, bx + 5 * SS, H * 0.37 + 26 * SS],
                  fill=(226, 190, 96, 255))
    return finish(im, w, h)


def trunk():
    w, h = 320, 384
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 8 * SS, W * 0.48, 10 * SS)
    cx = W / 2
    # than: rong o goc, hep dan len (dinh van rong de tan cay phu len)
    d.polygon([(cx - 78 * SS, H - 8 * SS), (cx + 78 * SS, H - 8 * SS),
               (cx + 46 * SS, 20 * SS), (cx - 46 * SS, 20 * SS)], fill=(96, 66, 44, 255))
    # canh thua ra 2 ben o dinh
    d.polygon([(cx - 40 * SS, 44 * SS), (cx - 96 * SS, 12 * SS), (cx - 84 * SS, 4 * SS),
               (cx - 26 * SS, 30 * SS)], fill=(90, 62, 42, 255))
    d.polygon([(cx + 40 * SS, 44 * SS), (cx + 96 * SS, 12 * SS), (cx + 84 * SS, 4 * SS),
               (cx + 26 * SS, 30 * SS)], fill=(90, 62, 42, 255))
    # re noi
    for s in (-1, 1):
        d.polygon([(cx + s * 30 * SS, H - 30 * SS), (cx + s * 108 * SS, H - 6 * SS),
                   (cx + s * 40 * SS, H - 6 * SS)], fill=(84, 58, 38, 255))
    # van go doc
    rng = random.Random(3)
    for _ in range(9):
        x = cx + rng.randint(-52, 52) * SS
        d.line([(x, 26 * SS), (x + rng.randint(-8, 8) * SS, H - 12 * SS)],
               fill=A((70, 48, 30), 160), width=2 * SS)
    speck(d, 8, (cx - 70 * SS, H - 60 * SS, cx + 70 * SS, H - 8 * SS), [(96, 138, 74), (140, 180, 100)], 30, 1.8)
    return finish(im, w, h)


def anvil():
    w, h = 96, 80
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 6 * SS, W * 0.4, 6 * SS)
    d.rectangle([W * 0.32, H * 0.55, W * 0.68, H - 6 * SS], fill=(110, 78, 52, 255))  # goc cay
    d.polygon([(W * 0.14, H * 0.30), (W * 0.86, H * 0.30), (W * 0.62, H * 0.46),
               (W * 0.38, H * 0.46)], fill=(120, 124, 132, 255))  # than de
    d.rectangle([W * 0.38, H * 0.44, W * 0.62, H * 0.58], fill=(92, 96, 104, 255))
    d.line([(W * 0.14, H * 0.30), (W * 0.86, H * 0.30)], fill=(170, 176, 186, 255), width=2 * SS)
    return finish(im, w, h)


def dummy():
    w, h = 96, 160
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 6 * SS, W * 0.36, 6 * SS)
    d.rectangle([W / 2 - 3 * SS, H * 0.30, W / 2 + 3 * SS, H - 6 * SS], fill=TIMBER_D + (255,))
    d.rectangle([W * 0.16, H * 0.36, W * 0.84, H * 0.36 + 6 * SS], fill=TIMBER + (255,))
    d.ellipse([W / 2 - 17 * SS, H * 0.06, W / 2 + 17 * SS, H * 0.40], fill=(216, 186, 110, 255))
    d.ellipse([W / 2 - 11 * SS, H * 0.02, W / 2 + 11 * SS, H * 0.16], fill=(232, 204, 128, 255))
    speck(d, 2, (W / 2 - 16 * SS, H * 0.08, W / 2 + 16 * SS, H * 0.38), [(178, 146, 80)], 22, 1.2)
    return finish(im, w, h)


def laundry():
    w, h = 256, 96
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    for px in (6 * SS, W - 10 * SS):
        d.rectangle([px, 8 * SS, px + 4 * SS, H - 4 * SS], fill=TIMBER_D + (255,))
    d.line([(8 * SS, 10 * SS), (W - 8 * SS, 10 * SS)], fill=(60, 48, 40, 255), width=SS)
    rng = random.Random(7)
    cols = [(226, 220, 200), (168, 84, 70), (96, 130, 170), (226, 196, 110), (140, 170, 120)]
    x = 18 * SS
    while x < W - 44 * SS:
        cw = rng.choice([22, 28, 18]) * SS
        c = rng.choice(cols)
        sag = rng.randint(2, 5) * SS
        d.polygon([(x, 10 * SS), (x + cw, 10 * SS), (x + cw, 10 * SS + 26 * SS + sag),
                   (x, 10 * SS + 26 * SS)], fill=A(c, 235))
        x += cw + rng.randint(6, 12) * SS
    return finish(im, w, h)


def bench():
    w, h = 128, 64
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2, H - 5 * SS, W * 0.48, 5 * SS)
    d.rectangle([6 * SS, H * 0.34, W - 6 * SS, H * 0.52], fill=STONE + (255,))
    for fx in (14 * SS, W - 22 * SS):
        d.rectangle([fx, H * 0.52, fx + 8 * SS, H - 5 * SS], fill=STONE_D + (255,))
    return finish(im, w, h)


def flower_bed():
    w, h = 192, 96
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2 + 4 * SS, H - 5 * SS, W * 0.48, 5 * SS, 70)
    d.rectangle([4 * SS, 10 * SS, W - 4 * SS, H - 8 * SS], fill=TIMBER_D + (255,))
    d.rectangle([8 * SS, 14 * SS, W - 8 * SS, H - 12 * SS], fill=(74, 56, 40, 255))
    rng = random.Random(9)
    cols = [(216, 84, 100), (240, 170, 80), (200, 120, 200), (240, 240, 230), (230, 110, 70)]
    for row in range(3):
        for i in range(9):
            x = 16 * SS + i * 20 * SS + rng.uniform(-3, 3) * SS
            y = 22 * SS + row * 20 * SS + rng.uniform(-3, 3) * SS
            d.ellipse([x - 3 * SS, y + 1 * SS, x + 3 * SS, y + 6 * SS], fill=(88, 128, 62, 255))
            c = rng.choice(cols)
            d.ellipse([x - 3 * SS, y - 4 * SS, x + 3 * SS, y + 2 * SS], fill=c + (255,))
            d.ellipse([x - 1 * SS, y - 2 * SS, x + 1 * SS, y], fill=(255, 244, 200, 255))
    return finish(im, w, h)


def banner():
    w, h = 96, 224
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    soft_shadow(d, W / 2 + 4 * SS, H - 4 * SS, 20 * SS, 4 * SS, 60)
    # cot go + tay ngang + qua cau vang tren dinh
    d.rectangle([10 * SS, 8 * SS, 15 * SS, H - 4 * SS], fill=TIMBER_D + (255,))
    d.rectangle([10 * SS, 10 * SS, 82 * SS, 14 * SS], fill=TIMBER_D + (255,))
    d.ellipse([9 * SS, 2 * SS, 16 * SS, 9 * SS], fill=(226, 184, 92, 255))
    # la co do tham vien vang, huy hieu kim cuong, cat V duoi
    d.polygon([(22 * SS, 14 * SS), (76 * SS, 14 * SS), (76 * SS, 148 * SS),
               (49 * SS, 128 * SS), (22 * SS, 148 * SS)], fill=(148, 50, 58, 255))
    d.line([(22 * SS, 14 * SS), (22 * SS, 148 * SS), (49 * SS, 128 * SS),
            (76 * SS, 148 * SS), (76 * SS, 14 * SS)], fill=(226, 184, 92, 255), width=2 * SS)
    d.polygon([(49 * SS, 44 * SS), (62 * SS, 66 * SS), (49 * SS, 88 * SS), (36 * SS, 66 * SS)],
              fill=(226, 184, 92, 255))
    d.polygon([(49 * SS, 52 * SS), (56 * SS, 66 * SS), (49 * SS, 80 * SS), (43 * SS, 66 * SS)],
              fill=(110, 130, 92, 255))
    for fx in range(27 * SS, 72 * SS, 9 * SS):
        d.line([(fx, 140 * SS), (fx, 146 * SS)], fill=(226, 184, 92, 200), width=SS)
    return finish(im, w, h)


def decal(kind, seed):
    """Decal phang dan mat dat: nut lat / reu / vet ban (sprite trong suot)."""
    w, h = 256, 256
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    W, H = w * SS, h * SS
    rng = random.Random(seed)
    if kind == "crack":
        for _ in range(7):
            x, y = rng.uniform(30, 226) * SS, rng.uniform(30, 226) * SS
            pts = [(x, y)]
            for _ in range(rng.randint(3, 6)):
                x += rng.uniform(-26, 26) * SS; y += rng.uniform(-8, 20) * SS
                pts.append((x, y))
            d.line(pts, fill=(40, 36, 32, 120), width=SS)
            d.line([(px + 2 * SS, py + 2 * SS) for px, py in pts], fill=(210, 205, 195, 40), width=SS)
    elif kind == "moss":
        for _ in range(46):
            x, y = rng.uniform(16, 240) * SS, rng.uniform(16, 240) * SS
            r = rng.uniform(2, 7) * SS
            c = rng.choice([(96, 138, 74), (110, 152, 84), (80, 120, 64)])
            d.ellipse([x - r, y - r * 0.6, x + r, y + r * 0.6], fill=A(c, rng.randint(40, 95)))
    else:  # stain: vet loang toi + vet banh xe mo
        for _ in range(10):
            x, y = rng.uniform(20, 236) * SS, rng.uniform(20, 236) * SS
            r = rng.uniform(8, 26) * SS
            d.ellipse([x - r, y - r * 0.5, x + r, y + r * 0.5], fill=(52, 44, 36, rng.randint(18, 42)))
        d.arc([30 * SS, 60 * SS, 226 * SS, 200 * SS], 200, 320, fill=(52, 44, 36, 50), width=5 * SS)
    return finish(im, w, h)


def main():
    random.seed(42)
    save(house(384, 320, PLASTER, (178, 92, 62), (128, 62, 44), 1, 1), "house_a.png")
    save(house(448, 384, (206, 196, 178), (94, 110, 132), (62, 76, 96), 1, 2), "house_b.png")
    save(house(512, 384, (196, 178, 148), (128, 106, 66), (92, 74, 44), 1, 3), "house_c.png")
    save(house(384, 448, PLASTER, (148, 62, 56), (104, 42, 40), 2, 4), "house_d.png")
    save(house(576, 400, (220, 206, 182), (84, 96, 122), (56, 66, 88), 2, 5), "house_e.png")
    save(house(320, 288, (210, 192, 160), (176, 138, 78), (128, 98, 52), 1, 6), "house_f.png")
    save(stall((178, 70, 58), (128, 50, 42), 11), "stall_a.png")
    save(stall((84, 128, 80), (54, 92, 54), 12), "stall_b.png")
    save(stall((76, 104, 158), (50, 72, 112), 13), "stall_c.png")
    save(stall((206, 156, 66), (156, 114, 44), 14), "stall_d.png")
    save(statue(), "statue.png")
    save(fountain(), "fountain.png")
    save(tower(), "tower.png")
    save(palace(), "palace.png")
    save(trunk(), "trunk_big.png")
    save(anvil(), "anvil.png")
    save(dummy(), "dummy.png")
    save(laundry(), "laundry.png")
    save(bench(), "bench.png")
    save(flower_bed(), "flower_bed.png")
    save(banner(), "banner.png")
    save(decal("crack", 31), "decal_crack.png")
    save(decal("moss", 32), "decal_moss.png")
    save(decal("stain", 33), "decal_stain.png")


if __name__ == "__main__":
    main()
