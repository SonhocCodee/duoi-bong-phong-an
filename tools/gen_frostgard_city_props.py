#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sinh prop NOI THANH FROSTGARD (Bac): nha Bac mai day phu tuyet (3 bien the:
2 ban den sang + 1 ban dong bang toi), Lo Lon trung tam, Ngai Bang,
Thap Chuong Khong Chuong (gia treo trong - chi tiet ke chuyen), Dai Danh Sach Ten.
Pipeline chuan game: ve supersample 3x bang PIL roi downscale LANCZOS.
Chay: python3 tools/gen_frostgard_city_props.py
Dau ra: game/assets/props/frost_house_a.png, frost_house_b.png,
frost_house_frozen.png, great_forge.png, ice_throne.png, bell_tower.png,
name_memorial.png
"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "game", "assets", "props")
SS = 3

INK = (30, 34, 44, 255)
STONE = (104, 112, 128)
STONE_L = (142, 152, 170)
STONE_D = (66, 74, 90)
STONE_XD = (44, 50, 64)
TIMBER = (86, 62, 44)
TIMBER_D = (58, 40, 28)
WOOD = (122, 88, 56)
WOOD_D = (88, 60, 36)
SNOW = (240, 246, 252)
SNOW_L = (253, 254, 255)
SNOW_D = (196, 212, 232)
SNOW_XD = (158, 182, 210)
ICE = (168, 218, 220)
ICE_D = (69, 123, 157)
ICE_L = (216, 242, 244)


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


def S(v):
    return v * SS


def vgrad(d, box, top, bot):
    x0, y0, x1, y1 = [S(v) for v in box]
    steps = max(2, int(y1 - y0))
    for i in range(steps):
        t = i / (steps - 1)
        c = tuple(int(top[k] + (bot[k] - top[k]) * t) for k in range(3)) + (255,)
        d.line([(x0, y0 + i), (x1, y0 + i)], fill=c)


def speck(d, seed, box, cols, n, r=1.4, alpha=(40, 110)):
    rng = random.Random(seed)
    x0, y0, x1, y1 = [S(v) for v in box]
    for _ in range(n):
        x = rng.uniform(x0, x1)
        y = rng.uniform(y0, y1)
        c = rng.choice(cols)
        rr = r * SS * rng.uniform(0.6, 1.5)
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=A(c, rng.randint(*alpha)))


def soft_shadow(d, cx, cy, rx, ry, alpha=95):
    d.ellipse([S(cx - rx), S(cy - ry), S(cx + rx), S(cy + ry)], fill=(16, 22, 34, alpha))


def stone_wall(d, box, seed, base=STONE, dark=STONE_D, light=STONE_L):
    x0, y0, x1, y1 = box
    vgrad(d, box, light, base)
    rng = random.Random(seed)
    row_h = 16
    y = y0
    while y < y1:
        d.line([(S(x0), S(y)), (S(x1), S(y))], fill=A(dark, 190), width=max(1, SS))
        x = x0 + rng.uniform(-6, 10)
        while x < x1 - 8:
            wdt = rng.uniform(20, 40)
            d.line([(S(x + wdt), S(y)), (S(x + wdt), S(min(y + row_h, y1)))],
                   fill=A(dark, 150), width=max(1, SS))
            x += wdt
        y += row_h
    speck(d, seed + 7, box, [dark, light, SNOW_D], 90, 1.2)


def snow_roof(d, x0, y0, x1, ridge_y, under, under_d, seed=1, snow_th=13):
    """Mai doc day: lop goi/mai toi ben duoi + phu tuyet day ben tren,
    vien dinh sang, bang treo (icicle) duoi mai hien."""
    cx = (x0 + x1) / 2.0
    d.polygon([(S(x0), S(y0)), (S(x1), S(y0)), (S(cx), S(ridge_y))], fill=under + (255,))
    under_sh = tuple(int(v * 0.78) for v in under)
    d.polygon([(S(cx), S(ridge_y)), (S(x1), S(y0)), (S(cx), S(y0))], fill=under_sh + (255,))
    rng = random.Random(seed)
    rows = 8
    for i in range(1, rows + 1):
        t = i / rows
        yy = ridge_y + (y0 - ridge_y) * t
        half = (x1 - x0) / 2 * t
        d.line([(S(cx - half), S(yy)), (S(cx + half), S(yy))], fill=A(under_d, 165), width=SS)
    # Lop tuyet day tren mai (offset vao trong + len tren)
    inset = (x1 - x0) * 0.055
    d.polygon([(S(x0 + inset), S(y0 - snow_th * 0.35)), (S(x1 - inset), S(y0 - snow_th * 0.35)),
               (S(cx), S(ridge_y - snow_th * 0.55))], fill=SNOW + (255,))
    d.polygon([(S(cx), S(ridge_y - snow_th * 0.55)), (S(x1 - inset), S(y0 - snow_th * 0.35)),
               (S(cx), S(y0 - snow_th * 0.35))], fill=(216, 230, 244, 255))
    speck(d, seed + 3, (x0 + inset, ridge_y, x1 - inset, y0), [SNOW_D, SNOW_XD, SNOW_L], 130, 1.3)
    d.line([(S(x0 + inset), S(y0 - snow_th * 0.35)), (S(cx), S(ridge_y - snow_th * 0.55)),
            (S(x1 - inset), S(y0 - snow_th * 0.35))], fill=SNOW_L + (255,), width=2 * SS)
    # Vien mai toi + bong duoi mai
    d.line([(S(x0), S(y0)), (S(x1), S(y0))], fill=under_d + (255,), width=3 * SS)
    d.rectangle([S(x0), S(y0), S(x1), S(y0 + 6)], fill=(0, 0, 0, 52))
    # Icicle treo duoi mai hien
    x = x0 + 6
    while x < x1 - 8:
        ln = rng.uniform(8, 24)
        wd = rng.uniform(2.2, 4.2)
        d.polygon([(S(x), S(y0 + 2)), (S(x + wd), S(y0 + 2)), (S(x + wd / 2), S(y0 + 2 + ln))],
                  fill=A(ICE_L, 225))
        d.line([(S(x + wd / 2), S(y0 + 3)), (S(x + wd / 2), S(y0 + ln))],
               fill=A((255, 255, 255), 160), width=SS)
        x += rng.uniform(11, 26)


def window(d, x, y, w, h, lit=True, frozen=False):
    d.rectangle([S(x - 3), S(y - 3), S(x + w + 3), S(y + h + 3)], fill=TIMBER_D + (255,))
    if lit:
        vgrad(d, (x, y, x + w, y + h), (255, 226, 150), (238, 158, 64))
        d.rectangle([S(x), S(y), S(x + w), S(y + h)], outline=(120, 70, 30, 255), width=SS)
    elif frozen:
        vgrad(d, (x, y, x + w, y + h), (96, 128, 152), (52, 74, 96))
        rng = random.Random(int(x * 3 + y))
        for _ in range(6):
            fx = rng.uniform(x + 2, x + w - 2)
            fy = rng.uniform(y + 2, y + h - 2)
            d.line([(S(fx), S(fy)), (S(fx + rng.uniform(-7, 7)), S(fy + rng.uniform(-7, 7)))],
                   fill=A(ICE_L, 200), width=SS)
    else:
        vgrad(d, (x, y, x + w, y + h), (70, 86, 104), (40, 52, 68))
    d.line([(S(x + w / 2), S(y)), (S(x + w / 2), S(y + h))], fill=TIMBER_D + (255,), width=SS)
    d.line([(S(x), S(y + h / 2)), (S(x + w), S(y + h / 2))], fill=TIMBER_D + (255,), width=SS)
    # Bau tuyet tren cua so
    d.rectangle([S(x - 4), S(y - 7), S(x + w + 4), S(y - 3)], fill=SNOW + (255,))


def door(d, x, y, w, h, frozen=False):
    d.rectangle([S(x - 3), S(y - 3), S(x + w + 3), S(y + h)], fill=STONE_D + (255,))
    vgrad(d, (x, y, x + w, y + h), WOOD, WOOD_D)
    for gx in (0.28, 0.55, 0.78):
        d.line([(S(x + w * gx), S(y + 3)), (S(x + w * gx), S(y + h - 2))],
               fill=A(TIMBER_D, 160), width=SS)
    d.line([(S(x), S(y + h * 0.32)), (S(x + w), S(y + h * 0.32))], fill=TIMBER_D + (255,), width=2 * SS)
    d.ellipse([S(x + w - 10), S(y + h / 2 - 3), S(x + w - 4), S(y + h / 2 + 3)],
              fill=(196, 204, 214, 255))
    if frozen:
        d.polygon([(S(x), S(y + h)), (S(x + w * 0.4), S(y + h * 0.55)), (S(x + w * 0.2), S(y + h))],
                  fill=A(ICE, 120))
    d.rectangle([S(x - 5), S(y - 9), S(x + w + 5), S(y - 4)], fill=SNOW + (255,))


def chimney(d, x, y, w, h, smoke=True, seed=5):
    stone_wall(d, (x, y, x + w, y + h), seed, base=(96, 104, 120))
    d.rectangle([S(x - 3), S(y - 4), S(x + w + 3), S(y + 2)], fill=SNOW + (255,))
    if smoke:
        rng = random.Random(seed)
        for i in range(5):
            cx = x + w / 2 + rng.uniform(-4, 10) + i * 3.2
            cy = y - 12 - i * 11
            rr = 6 + i * 3.4
            d.ellipse([S(cx - rr), S(cy - rr * 0.7), S(cx + rr), S(cy + rr * 0.7)],
                      fill=(226, 232, 240, 52 + i * 8))


def icicles(d, x0, x1, y, seed, n_span=(11, 26), ln_range=(8, 26)):
    rng = random.Random(seed)
    x = x0 + 4
    while x < x1 - 6:
        ln = rng.uniform(*ln_range)
        wd = rng.uniform(2.0, 4.0)
        d.polygon([(S(x), S(y)), (S(x + wd), S(y)), (S(x + wd / 2), S(y + ln))],
                  fill=A(ICE_L, 225))
        x += rng.uniform(*n_span)


# ---------------------------------------------------------------- nha A (den sang)
def frost_house_a():
    w, h = 384, 320
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    soft_shadow(d, w / 2, h - 14, 168, 13)
    bx0, bx1, by0, by1 = 52, 332, 148, 306
    chimney(d, 268, 62, 30, 74, smoke=True, seed=11)
    stone_wall(d, (bx0, by0 + 58, bx1, by1), 21)
    vgrad(d, (bx0, by0, bx1, by0 + 58), (196, 178, 152), (168, 148, 122))
    speck(d, 22, (bx0, by0, bx1, by0 + 58), [TIMBER_D, SNOW_D], 46, 1.2)
    for tx in (bx0 + 4, (bx0 + bx1) / 2 - 4, bx1 - 12):
        d.rectangle([S(tx), S(by0), S(tx + 8), S(by1)], fill=TIMBER_D + (255,))
    d.rectangle([S(bx0), S(by0 + 54), S(bx1), S(by0 + 62)], fill=TIMBER_D + (255,))
    snow_roof(d, 30, 150, 354, 58, (74, 84, 104), (46, 54, 70), seed=31, snow_th=15)
    window(d, 84, 178, 34, 44, lit=True)
    window(d, 258, 178, 34, 44, lit=True)
    window(d, 172, 96, 30, 36, lit=True)
    door(d, 172, 238, 40, 68)
    d.rectangle([S(66), S(282), S(120), S(300)], fill=TIMBER_D + (255,))  # dong cui
    for i in range(4):
        d.ellipse([S(70 + (i % 2) * 24), S(284 + (i // 2) * 8), S(90 + (i % 2) * 24), S(294 + (i // 2) * 8)],
                  fill=WOOD + (255,), outline=WOOD_D + (255,))
    d.ellipse([S(288), S(286), S(326), S(306)], fill=SNOW + (255,))  # dong tuyet chan nha
    d.ellipse([S(36), S(292), S(96), S(308)], fill=A(SNOW, 235))
    return finish(im, w, h)


# ---------------------------------------------------------------- nha B (den sang, lon hon)
def frost_house_b():
    w, h = 448, 384
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    soft_shadow(d, w / 2, h - 14, 196, 14)
    bx0, bx1, by0, by1 = 54, 394, 176, 368
    chimney(d, 96, 78, 32, 84, smoke=True, seed=41)
    chimney(d, 318, 70, 28, 76, smoke=False, seed=42)
    stone_wall(d, (bx0, by0 + 66, bx1, by1), 43)
    vgrad(d, (bx0, by0, bx1, by0 + 66), (176, 168, 158), (146, 136, 124))
    speck(d, 44, (bx0, by0, bx1, by0 + 66), [STONE_D, SNOW_D], 60, 1.2)
    for tx in (bx0 + 4, bx0 + 112, bx0 + 224, bx1 - 12):
        d.rectangle([S(tx), S(by0), S(tx + 9), S(by1)], fill=(74, 56, 42, 255))
    d.rectangle([S(bx0), S(by0 + 62), S(bx1), S(by0 + 71)], fill=(74, 56, 42, 255))
    snow_roof(d, 28, 178, 420, 66, (96, 66, 58), (62, 40, 36), seed=47, snow_th=17)
    window(d, 88, 206, 36, 48, lit=True)
    window(d, 196, 206, 36, 48, lit=True)
    window(d, 322, 206, 36, 48, lit=True)
    window(d, 200, 118, 32, 38, lit=True)
    door(d, 128, 292, 44, 76)
    d.rectangle([S(300), S(316), S(366), S(336)], fill=TIMBER_D + (255,))
    for i in range(6):
        d.ellipse([S(304 + (i % 3) * 20), S(318 + (i // 3) * 9), S(322 + (i % 3) * 20), S(330 + (i // 3) * 9)],
                  fill=WOOD + (255,), outline=WOOD_D + (255,))
    d.ellipse([S(40), S(348), S(120), S(370)], fill=A(SNOW, 235))
    d.ellipse([S(330), S(350), S(414), S(372)], fill=A(SNOW, 235))
    return finish(im, w, h)


# ---------------------------------------------------------------- nha dong bang (toi)
def frost_house_frozen():
    w, h = 384, 320
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    soft_shadow(d, w / 2, h - 14, 168, 13, alpha=110)
    bx0, bx1, by0, by1 = 52, 332, 148, 306
    chimney(d, 268, 62, 30, 74, smoke=False, seed=61)
    d.rectangle([S(262), S(54), S(304), S(66)], fill=SNOW + (255,))
    stone_wall(d, (bx0, by0 + 58, bx1, by1), 63, base=(88, 98, 114), dark=(54, 64, 80), light=(118, 130, 148))
    vgrad(d, (bx0, by0, bx1, by0 + 58), (128, 138, 152), (100, 110, 126))
    for tx in (bx0 + 4, (bx0 + bx1) / 2 - 4, bx1 - 12):
        d.rectangle([S(tx), S(by0), S(tx + 8), S(by1)], fill=(44, 50, 62, 255))
    d.rectangle([S(bx0), S(by0 + 54), S(bx1), S(by0 + 62)], fill=(44, 50, 62, 255))
    # Bang phu vet nut tren tuong
    rng = random.Random(64)
    for _ in range(7):
        fx = rng.uniform(bx0 + 14, bx1 - 14)
        fy = rng.uniform(by0 + 10, by1 - 40)
        d.line([(S(fx), S(fy)), (S(fx + rng.uniform(-10, 10)), S(fy + rng.uniform(10, 26)))],
               fill=A(ICE_L, 150), width=SS)
    snow_roof(d, 30, 150, 354, 58, (52, 62, 78), (32, 40, 52), seed=67, snow_th=19)
    window(d, 84, 178, 34, 44, lit=False, frozen=True)
    window(d, 258, 178, 34, 44, lit=False, frozen=True)
    window(d, 172, 96, 30, 36, lit=False, frozen=True)
    door(d, 172, 238, 40, 68, frozen=True)
    # Dong tuyet cao chan cua + truot tuyet truoc nha
    d.ellipse([S(140), S(282), S(248), S(310)], fill=SNOW + (255,))
    d.ellipse([S(30), S(288), S(130), S(310)], fill=A(SNOW, 245))
    d.ellipse([S(268), S(290), S(352), S(310)], fill=A(SNOW, 245))
    speck(d, 68, (30, 60, 354, 310), [ICE_L, SNOW_L], 60, 1.1, alpha=(60, 130))
    return finish(im, w, h)


# ---------------------------------------------------------------- Lo Lon
def great_forge():
    w, h = 768, 512
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    soft_shadow(d, w / 2, h - 16, 348, 18, alpha=110)
    # Ong khoi / mui hut lon o giua
    chimney(d, 344, 18, 80, 120, smoke=True, seed=71)
    # Than lo da den lon: khoi chinh
    stone_wall(d, (120, 150, 648, 470), 73, base=(92, 98, 112), dark=(52, 58, 70), light=(128, 138, 154))
    # Mai phu tuyet hai ben than lo
    d.polygon([(S(96), S(168)), (S(384), S(74)), (S(672), S(168)), (S(648), S(196)),
               (S(384), S(112)), (S(120), S(196))], fill=(52, 60, 76, 255))
    d.polygon([(S(110), S(162)), (S(384), S(76)), (S(658), S(162)), (S(646), S(178)),
               (S(384), S(96)), (S(122), S(178))], fill=SNOW + (255,))
    speck(d, 74, (110, 76, 658, 180), [SNOW_D, SNOW_XD], 110, 1.3)
    icicles(d, 128, 640, 196, 75, ln_range=(10, 26))
    # Cua lo chinh: vom da + lua chay sang
    fx0, fy0, fx1, fy1 = 292, 268, 476, 462
    d.rectangle([S(fx0 - 16), S(fy0 + 40), S(fx1 + 16), S(fy1)], fill=STONE_XD + (255,))
    d.ellipse([S(fx0 - 16), S(fy0 - 8), S(fx1 + 16), S(fy0 + 92)], fill=STONE_XD + (255,))
    d.rectangle([S(fx0), S(fy0 + 46), S(fx1), S(fy1)], fill=(24, 12, 8, 255))
    d.ellipse([S(fx0), S(fy0), S(fx1), S(fy0 + 92)], fill=(24, 12, 8, 255))
    # Anh lua: lop glow + ngon lua lop lang
    glow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([S(fx0 - 66), S(fy0 + 6), S(fx1 + 66), S(fy1 + 24)], fill=(255, 138, 42, 92))
    glow = glow.filter(ImageFilter.GaussianBlur(16 * SS // 2))
    im.alpha_composite(glow)
    d = ImageDraw.Draw(im, "RGBA")
    rng = random.Random(77)
    for layer, col, shrink in [(0, (214, 74, 22), 0), (1, (246, 128, 30), 14), (2, (255, 190, 74), 28), (3, (255, 232, 160), 40)]:
        base_y = fy1 - 8
        top_y = fy0 + 66 - layer * 16
        pts = []
        steps = 9
        for i in range(steps + 1):
            t = i / steps
            x = fx0 + 22 + shrink + (fx1 - fx0 - 44 - shrink * 2) * t
            y = base_y - (base_y - top_y) * math.sin(t * math.pi) * rng.uniform(0.82, 1.0)
            pts.append((S(x), S(y)))
        pts += [(S(fx1 - 22 - shrink), S(base_y)), (S(fx0 + 22 + shrink), S(base_y))]
        d.polygon(pts, fill=col + (255,))
    for i in range(7):  # thanh cui chay trong lo
        y = fy1 - 20 - i * 3
        d.rounded_rectangle([S(fx0 + 44 + i * 6), S(y), S(fx1 - 44 - i * 4), S(y + 9)],
                            radius=S(4), fill=(52, 26, 14, 255))
    # Hai cua lo phu nho 2 ben
    for sx in (168, 528):
        d.rectangle([S(sx), S(330), S(sx + 72), S(452)], fill=(30, 18, 12, 255))
        d.ellipse([S(sx), S(302), S(sx + 72), S(360)], fill=(30, 18, 12, 255))
        d.rectangle([S(sx - 7), S(322), S(sx + 79), S(452)], outline=STONE_XD + (255,), width=3 * SS)
        d.ellipse([S(sx + 16), S(384), S(sx + 56), S(438)], fill=(246, 128, 30, 235))
        d.ellipse([S(sx + 25), S(398), S(sx + 47), S(432)], fill=(255, 214, 110, 255))
    # Be thoi + de + gia treo xich
    d.rectangle([S(150), S(452), S(214), S(478)], fill=(40, 44, 54, 255))
    d.rectangle([S(560), S(446), S(606), S(470)], fill=(58, 62, 72, 255))
    d.rectangle([S(566), S(438), S(600), S(448)], fill=(150, 158, 172, 255))
    for cx_ in (210, 552):
        for i in range(5):
            d.ellipse([S(cx_ + i * 2 - 6), S(214 + i * 13), S(cx_ + i * 2 + 6), S(224 + i * 13)],
                      outline=(150, 158, 170, 255), width=SS)
    # Tuyet phu chan lo + vet sang am tren nen
    d.ellipse([S(84), S(462), S(300), S(492)], fill=A(SNOW, 210))
    d.ellipse([S(486), S(466), S(692), S(494)], fill=A(SNOW, 210))
    d.ellipse([S(300), S(470), S(486), S(496)], fill=(255, 166, 84, 66))
    return finish(im, w, h)


# ---------------------------------------------------------------- Ngai Bang
def ice_throne():
    w, h = 512, 448
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    soft_shadow(d, w / 2, h - 14, 218, 15, alpha=100)
    cx = w / 2
    # Bac them bang 3 cap
    for i, (ww, yy) in enumerate([(430, 420), (372, 398), (314, 376)]):
        vgrad(d, (cx - ww / 2, yy, cx + ww / 2, yy + 20), ICE_L, ICE_D)
        d.rectangle([S(cx - ww / 2), S(yy), S(cx + ww / 2), S(yy + 4)], fill=SNOW_L + (255,))
    # Cot tinh the 2 ben
    for sx, hh in [(cx - 196, 268), (cx + 196, 268), (cx - 158, 216), (cx + 158, 216)]:
        d.polygon([(S(sx - 17), S(382)), (S(sx), S(382 - hh)), (S(sx + 17), S(382))], fill=A(ICE, 235))
        d.polygon([(S(sx), S(382 - hh)), (S(sx + 17), S(382)), (S(sx), S(382))], fill=A(ICE_D, 120))
        d.line([(S(sx), S(382 - hh + 8)), (S(sx), S(376))], fill=A((255, 255, 255), 190), width=SS)
        d.rectangle([S(sx - 21), S(376), S(sx + 21), S(386)], fill=SNOW + (255,))
    # Lung ngai: mang tinh the lon hinh quat
    rng = random.Random(83)
    spikes = [(-118, 236), (-84, 292), (-46, 322), (0, 344), (46, 322), (84, 292), (118, 236)]
    for off, hh in spikes:
        wd = 34 - abs(off) / 9
        d.polygon([(S(cx + off - wd / 2), S(348)), (S(cx + off), S(348 - hh)), (S(cx + off + wd / 2), S(348))],
                  fill=A(ICE, 240))
        d.polygon([(S(cx + off), S(348 - hh)), (S(cx + off + wd / 2), S(348)), (S(cx + off), S(348))],
                  fill=A(ICE_D, 110))
        d.line([(S(cx + off), S(348 - hh + 10)), (S(cx + off), S(342))],
               fill=A((255, 255, 255), 200), width=SS)
    # Than ngai: ghe + tay vin
    vgrad(d, (cx - 74, 238, cx + 74, 352), (196, 232, 236), ICE_D)
    d.rectangle([S(cx - 74), S(238), S(cx + 74), S(352)], outline=A(ICE_D, 255), width=2 * SS)
    vgrad(d, (cx - 88, 318, cx + 88, 356), ICE_L, ICE_D)
    for ax in (cx - 104, cx + 88):
        vgrad(d, (ax, 286, ax + 16, 356), ICE_L, ICE_D)
        d.ellipse([S(ax - 3), S(272), S(ax + 19), S(292)], fill=ICE_L + (255,))
    d.polygon([(S(cx - 60), S(356)), (S(cx + 60), S(356)), (S(cx + 74), S(382)), (S(cx - 74), S(382))],
              fill=A(ICE_D, 235))
    # Long lanh tinh the + tuyet chan ngai
    speck(d, 84, (60, 40, 452, 380), [(255, 255, 255), ICE_L], 70, 1.1, alpha=(90, 200))
    d.ellipse([S(66), S(392), S(220), S(416)], fill=A(SNOW, 230))
    d.ellipse([S(292), S(392), S(446), S(416)], fill=A(SNOW, 230))
    return finish(im, w, h)


# ---------------------------------------------------------------- Thap chuong KHONG chuong
def bell_tower():
    w, h = 320, 512
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    soft_shadow(d, w / 2, h - 12, 132, 12, alpha=110)
    cx = w / 2
    # Than thap da den thu hep dan len tren
    stone_wall(d, (104, 208, 216, 500), 91, base=(88, 96, 110), dark=(50, 56, 68), light=(122, 132, 148))
    stone_wall(d, (92, 128, 228, 212), 92, base=(96, 104, 118), dark=(54, 60, 72), light=(130, 140, 156))
    d.rectangle([S(88), S(204), S(232), S(214)], fill=STONE_XD + (255,))
    d.rectangle([S(86), S(198), S(234), S(205)], fill=SNOW + (255,))
    # Cua thap + khe cua so hep dong bang
    door(d, 140, 428, 40, 72, frozen=True)
    window(d, 148, 330, 24, 40, lit=False, frozen=True)
    window(d, 148, 240, 24, 36, lit=False, frozen=True)
    # --- Gac chuong: vom mo RONG, ben trong TOI, chi co xa ngang + doan day
    # dut treo lung lung: KHONG CO CHUONG (chi tiet ke chuyen bat buoc).
    d.rectangle([S(100), S(66), S(220), S(132)], fill=(16, 18, 26, 255))
    d.ellipse([S(100), S(38), S(220), S(96)], fill=(16, 18, 26, 255))
    d.rectangle([S(100), S(66), S(220), S(132)], outline=STONE_XD + (255,), width=3 * SS)
    d.ellipse([S(100), S(38), S(220), S(96)], outline=STONE_XD + (255,), width=3 * SS)
    d.rectangle([S(104), S(84), S(216), S(93)], fill=TIMBER_D + (255,))  # xa ngang trong
    # doan day dut: tu xa xuong mot doan roi het, moc trong
    for i in range(4):
        d.ellipse([S(cx - 4), S(94 + i * 6), S(cx + 4), S(100 + i * 6)], outline=(168, 150, 118, 255), width=SS)
    d.arc([S(cx - 7), S(116), S(cx + 7), S(130)], start=20, end=200, fill=(176, 184, 196, 255), width=2 * SS)
    # Mai chop nhon phu tuyet day
    d.polygon([(S(84), S(52)), (S(cx), S(10)), (S(236), S(52)), (S(224), S(66)), (S(cx), S(24)), (S(96), S(66))],
              fill=SNOW + (255,))
    d.polygon([(S(88), S(58)), (S(cx), S(18)), (S(232), S(58))], fill=(40, 46, 60, 255))
    d.polygon([(S(92), S(54)), (S(cx), S(12)), (S(228), S(54)), (S(220), S(62)), (S(cx), S(22)), (S(100), S(62))],
              fill=SNOW + (255,))
    speck(d, 93, (92, 12, 228, 62), [SNOW_D, SNOW_XD], 42, 1.1)
    icicles(d, 100, 220, 66, 94, ln_range=(8, 20))
    # Dinh chop: qua cau thep + vet tuyet chan thap
    d.ellipse([S(cx - 6), S(4), S(cx + 6), S(16)], fill=(150, 160, 176, 255))
    d.ellipse([S(84), S(486), S(160), S(504)], fill=A(SNOW, 235))
    d.ellipse([S(168), S(488), S(240), S(504)], fill=A(SNOW, 235))
    return finish(im, w, h)


# ---------------------------------------------------------------- Dai Danh Sach Ten
def name_memorial():
    w, h = 384, 320
    im = canvas(w, h)
    d = ImageDraw.Draw(im, "RGBA")
    soft_shadow(d, w / 2, h - 14, 168, 13, alpha=105)
    cx = w / 2
    # Be da 2 cap phu tuyet
    vgrad(d, (cx - 168, 282, cx + 168, 306), STONE_L, STONE_D)
    vgrad(d, (cx - 138, 258, cx + 138, 284), STONE, STONE_D)
    d.rectangle([S(cx - 168), S(282), S(cx + 168), S(288)], fill=SNOW + (255,))
    # Tam bia lon dung, dinh vom, phu tuyet tren dinh
    d.rectangle([S(cx - 92), S(74), S(cx + 92), S(262)], fill=STONE + (255,))
    d.ellipse([S(cx - 92), S(28), S(cx + 92), S(120)], fill=STONE + (255,))
    vgrad(d, (cx - 92, 40, cx + 92, 262), STONE_L, STONE)
    d.ellipse([S(cx - 92), S(28), S(cx + 92), S(120)], fill=(150, 158, 172, 255))
    d.rectangle([S(cx - 92), S(74), S(cx + 92), S(262)], outline=STONE_XD + (255,), width=2 * SS)
    d.pieslice([S(cx - 92), S(28), S(cx + 92), S(120)], start=180, end=360,
               outline=STONE_XD + (255,), width=2 * SS)
    d.rectangle([S(cx - 98), S(30), S(cx + 98), S(44)], fill=SNOW + (255,))
    # Vong nguyet que bang khac tren dinh bia
    d.ellipse([S(cx - 26), S(52), S(cx + 26), S(96)], outline=A(ICE_D, 220), width=2 * SS)
    d.ellipse([S(cx - 7), S(66), S(cx + 7), S(84)], fill=A(ICE, 200))
    # Cac dong ten khac (dong ke ngang dam nhat) - danh sach dai
    rng = random.Random(97)
    y = 118
    while y < 244:
        ln = rng.uniform(96, 148)
        x0 = cx - ln / 2 + rng.uniform(-5, 5)
        d.line([(S(x0), S(y)), (S(x0 + ln), S(y))], fill=A(STONE_XD, 215), width=SS + 1)
        # gach phan doan ten
        xx = x0 + rng.uniform(22, 40)
        while xx < x0 + ln - 14:
            d.line([(S(xx), S(y - 3)), (S(xx), S(y + 3))], fill=A(STONE_XD, 160), width=SS)
            xx += rng.uniform(24, 42)
        y += 13
    # Hai cay nen da / den long nho chan bia (lua am duy nhat o nghia trang)
    for nx in (cx - 128, cx + 112):
        d.rectangle([S(nx), S(236), S(nx + 16), S(262)], fill=(40, 44, 54, 255))
        d.ellipse([S(nx + 2), S(222), S(nx + 14), S(240)], fill=(255, 196, 92, 255))
        d.ellipse([S(nx + 5), S(226), S(nx + 11), S(238)], fill=(255, 236, 170, 255))
    speck(d, 98, (40, 40, 344, 262), [SNOW_L, ICE_L], 36, 1.0, alpha=(60, 130))
    d.ellipse([S(30), S(292), S(140), S(308)], fill=A(SNOW, 225))
    d.ellipse([S(244), S(292), S(354), S(308)], fill=A(SNOW, 225))
    return finish(im, w, h)


if __name__ == "__main__":
    save(frost_house_a(), "frost_house_a.png")
    save(frost_house_b(), "frost_house_b.png")
    save(frost_house_frozen(), "frost_house_frozen.png")
    save(great_forge(), "great_forge.png")
    save(ice_throne(), "ice_throne.png")
    save(bell_tower(), "bell_tower.png")
    save(name_memorial(), "name_memorial.png")
