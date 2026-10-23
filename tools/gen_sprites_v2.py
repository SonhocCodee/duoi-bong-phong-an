#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh spritesheet pixel art V2 cho game "Dưới Bóng Phong Ấn" bằng PIL.

Khác v1 (vẽ 32x32 rồi phóng x2 -> bị khối vuông, shading phẳng):
- Vẽ TRỰC TIẾP ở frame 64x64, từng pixel thật.
- Mỗi mảng vật liệu có >= 3 tông (dark/base/light/highlight).
- Outline tối 1px bao quanh silhouette (dãn alpha mask rồi lót dưới).
- Tỉ lệ bớt chibi: đầu ~17px trên tổng cao ~55px, thân/chân dài hơn v1.
- Player: lính đánh thuê tóc nâu + vòng trán thép, giáp thép xanh xám có
  pauldron/dây đai/găng/bốt, áo choàng teal có nếp + viền, kiếm thép.
- Goblin: da xanh nhiều tông + đốm bẩn, tai nhọn cong, mắt vàng có tròng,
  nanh, khố rách có miếng vá, dao gỉ có sống dao.

Quy ước sheet giữ nguyên v1 để không phải sửa logic game:
- Frame 64x64, mỗi HÀNG = 1 animation, frame từ cột 0.
- Hướng: down / up / side (side = nhìn phải, trái dùng flip_h).

Chạy: python3 tools/gen_sprites_v2.py
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

FS = 64  # frame size, vẽ trực tiếp

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "game", "assets", "sprites")
DESIGN_DIR = os.path.join(ROOT, "design")

# ---------------- palette ----------------
def C(hexs, a=255):
    h = hexs.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

P_OUTLINE = C("#191d26")
STEEL = {"dark": C("#3d4c5e"), "base": C("#687e94"), "light": C("#9db4c8"), "hi": C("#e6f0f8")}
CLOAK = {"dark": C("#14332f"), "base": C("#22635a"), "light": C("#3d8a7c"), "hi": C("#63b3a0")}
SKIN = {"dark": C("#c0824f"), "base": C("#eab183"), "light": C("#f8d6a8")}
HAIR = {"dark": C("#2a1c12"), "base": C("#54381f"), "light": C("#82603a")}
LEATHER = {"dark": C("#4a2e16"), "base": C("#7d5227"), "light": C("#a97a44")}
GOLD = {"dark": C("#8f6a1d"), "base": C("#cfa03c"), "light": C("#f4d47c")}
PANTS = {"dark": C("#232b3a"), "base": C("#3c4a61"), "light": C("#5a6d8a")}

G_OUTLINE = C("#141f0d")
GSKIN = {"dark": C("#38601f"), "base": C("#5f9c36"), "light": C("#86c154"), "hi": C("#b7e189"),
         "belly": C("#a5c96e")}
GDIRT = C("#5d6b2c")
GEAR_IN = C("#96604e")
GEYE = C("#f7c948")
RAG = {"dark": C("#4f3517"), "base": C("#7a5a2c"), "light": C("#a37f47"), "patch": C("#c2a066")}
RUST = {"dark": C("#5f574c"), "base": C("#968c7a"), "light": C("#cfc6b2"), "spot": C("#a85f2e")}

# ---------------- helpers ----------------
def new_frame():
    return Image.new("RGBA", (FS, FS), (0, 0, 0, 0))

def D(im):
    return ImageDraw.Draw(im)

def poly(d, pts, fill):
    d.polygon(pts, fill=fill)

def rect(d, box, fill):
    d.rectangle(box, fill=fill)

def ell(d, box, fill):
    d.ellipse(box, fill=fill)

def line(d, pts, fill, w=1):
    d.line(pts, fill=fill, width=w, joint="curve")

def px(d, x, y, c):
    d.point((x, y), fill=c)

def add_outline(im, color):
    """Lót outline 1px quanh silhouette: dãn alpha mask 1px rồi đặt hình lên."""
    alpha = im.split()[3]
    dil = alpha.filter(ImageFilter.MaxFilter(3))
    out = Image.new("RGBA", im.size, color)
    out.putalpha(dil)
    out.alpha_composite(im)
    return out

def swoosh(im, cx, cy, r, a0, a1, core=C("#ffffff")):
    """Vệt chém cong: 3 lớp cung (mờ rộng -> sáng -> lõi trắng), alpha phai ở 2 đầu."""
    ov = Image.new("RGBA", (FS, FS), (0, 0, 0, 0))
    d = D(ov)
    steps = max(int(abs(a1 - a0) // 3), 2)
    for layer, (rr, w, col, amax) in enumerate([
            (r, 6, C("#9fd8e8", 0), 70), (r - 2, 4, C("#cfeef8", 0), 130), (r - 3, 2, core, 220)]):
        pts = []
        for k in range(steps + 1):
            t = k / steps
            a = math.radians(a0 + (a1 - a0) * t)
            pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
        for k in range(steps):
            t = (k + 0.5) / steps
            fade = math.sin(math.pi * t)  # phai ở hai đầu cung
            c = (col[0], col[1], col[2], int(amax * fade))
            d.line([pts[k], pts[k + 1]], fill=c, width=w)
    im.alpha_composite(ov)

def sword(d, grip, tip):
    """Kiếm thép: lưỡi polygon thuôn, sống kiếm tối, mép sáng, chặn vàng, cán da."""
    gx, gy = grip
    tx, ty = tip
    dx, dy = tx - gx, ty - gy
    ln = max(math.hypot(dx, dy), 1.0)
    ux, uy = dx / ln, dy / ln
    nx, ny = -uy, ux
    # lưỡi
    poly(d, [(gx + nx * 2.2, gy + ny * 2.2), (tx, ty), (gx - nx * 2.2, gy - ny * 2.2)], STEEL["light"])
    line(d, [(gx + nx * 1.2, gy + ny * 1.2), (tx - ux * 3, ty - uy * 3)], STEEL["hi"], 1)
    line(d, [(gx, gy), (tx - ux * 4, ty - uy * 4)], STEEL["dark"], 1)  # sống kiếm
    # chặn kiếm vàng
    line(d, [(gx + nx * 5, gy + ny * 5), (gx - nx * 5, gy - ny * 5)], GOLD["dark"], 3)
    line(d, [(gx + nx * 5, gy + ny * 4), (gx - nx * 5, gy - ny * 4)], GOLD["light"], 1)
    # cán + núm
    line(d, [(gx, gy), (gx - ux * 5, gy - uy * 5)], LEATHER["dark"], 4)
    line(d, [(gx - ux * 1, gy - uy * 1), (gx - ux * 4, gy - uy * 4)], LEATHER["light"], 1)
    ex, ey = gx - ux * 6.5, gy - uy * 6.5
    ell(d, [ex - 2, ey - 2, ex + 2, ey + 2], GOLD["base"])
    px(d, int(ex - 1), int(ey - 1), GOLD["light"])

def knife(d, grip, tip):
    """Dao gỉ goblin: lưỡi ngắn cong nhẹ, sống dao tối, đốm gỉ cam, cán gỗ."""
    gx, gy = grip
    tx, ty = tip
    dx, dy = tx - gx, ty - gy
    ln = max(math.hypot(dx, dy), 1.0)
    ux, uy = dx / ln, dy / ln
    nx, ny = -uy, ux
    mid = (gx + dx * 0.55 + nx * 1.5, gy + dy * 0.55 + ny * 1.5)
    poly(d, [(gx + nx * 1.8, gy + ny * 1.8), mid, (tx, ty), (gx - nx * 1.8, gy - ny * 1.8)], RUST["base"])
    line(d, [(gx - nx * 1.2, gy - ny * 1.2), (tx - ux * 3, ty - uy * 3)], RUST["dark"], 1)  # sống dao
    line(d, [(gx + nx * 1.0, gy + ny * 1.0), mid], RUST["light"], 1)  # mép sắc
    for t in (0.3, 0.55, 0.75):  # đốm gỉ
        px(d, int(gx + dx * t + nx), int(gy + dy * t + ny), RUST["spot"])
    line(d, [(gx, gy), (gx - ux * 4.5, gy - uy * 4.5)], LEATHER["dark"], 3)

def arm_armor(d, sh, hand, main=STEEL):
    """Tay giáp: ống tay 2 tông + găng thép có highlight và kẽ ngón."""
    line(d, [sh, hand], main["dark"], 8)
    line(d, [(sh[0] - 1, sh[1] - 1), (hand[0] - 1, hand[1] - 1)], main["base"], 5)
    hx, hy = hand
    ell(d, [hx - 4, hy - 4, hx + 4, hy + 4], main["base"])
    ell(d, [hx - 4, hy - 4, hx + 1, hy], main["light"])
    line(d, [(hx - 2, hy + 1), (hx - 2, hy + 4)], main["dark"], 1)
    line(d, [(hx + 1, hy + 1), (hx + 1, hy + 4)], main["dark"], 1)

def arm_skin(d, sh, hand, tones):
    line(d, [sh, hand], tones["dark"], 7)
    line(d, [(sh[0] - 1, sh[1] - 1), (hand[0] - 1, hand[1] - 1)], tones["base"], 4)
    hx, hy = hand
    ell(d, [hx - 3, hy - 3, hx + 3, hy + 3], tones["base"])
    px(d, hx - 1, hy - 2, tones["light"])

def leg_pants(d, hip, foot, lift, far=False):
    """Chân quần: ống 2 tông + bốt da có mũi sáng. lift = độ nhấc chân."""
    hx, hy = hip
    fx, fy = foot[0], foot[1] - lift
    base = PANTS["dark"] if far else PANTS["base"]
    side = PANTS["base"] if far else PANTS["light"]
    poly(d, [(hx - 3, hy), (hx + 3, hy), (fx + 3, fy), (fx - 3, fy)], base)
    line(d, [(hx - 2, hy + 1), (fx - 2, fy - 1)], side, 2)
    # bốt
    poly(d, [(fx - 4, fy - 1), (fx + 4, fy - 1), (fx + 5, fy + 4), (fx - 4, fy + 4)], LEATHER["dark"])
    line(d, [(fx - 3, fy), (fx + 4, fy)], LEATHER["base"], 2)
    px(d, fx + 3, fy + 3, LEATHER["light"])
    line(d, [(fx - 4, fy + 4), (fx + 5, fy + 4)], C("#2c1c0e"), 1)

def leg_skin(d, hip, foot, lift, far=False):
    hx, hy = hip
    fx, fy = foot[0], foot[1] - lift
    base = GSKIN["dark"] if far else GSKIN["base"]
    poly(d, [(hx - 3, hy), (hx + 3, hy), (fx + 2, fy), (fx - 3, fy)], base)
    # bàn chân dài + ngón
    poly(d, [(fx - 3, fy), (fx + 4, fy), (fx + 5, fy + 3), (fx - 3, fy + 3)], base)
    for tx_ in (fx + 1, fx + 3):
        line(d, [(tx_, fy + 1), (tx_, fy + 3)], GSKIN["dark"], 1)
    px(d, fx - 2, fy + 1, GSKIN["light"])

# ============================================================ PLAYER
CX = 32

def p_head_down(d, b, style="normal"):
    """Đầu nhìn xuống: mặt đọc được + tóc có mái xéo + vòng trán thép."""
    # cổ + bóng dưới cằm
    rect(d, [29, 21 + b, 35, 25 + b], SKIN["dark"])
    # mặt
    poly(d, [(26, 10 + b), (38, 10 + b), (38, 19 + b), (36, 22 + b), (28, 22 + b), (26, 19 + b)], SKIN["base"])
    poly(d, [(34, 10 + b), (38, 10 + b), (38, 19 + b), (36, 22 + b), (34, 22 + b)], SKIN["dark"])  # bóng phải
    ell(d, [27, 12 + b, 31, 18 + b], SKIN["light"])  # gò má sáng trái
    # tóc: đỉnh bo tròn + mái zigzag sâu + hai bên mai dài
    poly(d, [(28, 3 + b), (36, 3 + b), (39, 6 + b), (40, 11 + b), (37, 10 + b), (36, 14 + b),
              (33, 10 + b), (31, 14 + b), (28, 10 + b), (26, 13 + b), (24, 10 + b), (25, 6 + b)], HAIR["base"])
    poly(d, [(28, 3 + b), (36, 3 + b), (38, 5 + b), (27, 5 + b)], HAIR["light"])  # vệt sáng đỉnh đầu
    line(d, [(30, 5 + b), (29, 9 + b)], HAIR["light"], 1)
    line(d, [(34, 5 + b), (35, 9 + b)], HAIR["dark"], 1)
    line(d, [(27, 5 + b), (28, 9 + b)], HAIR["dark"], 1)
    line(d, [(36, 5 + b), (35, 9 + b)], HAIR["dark"], 1)
    rect(d, [24, 10 + b, 26, 17 + b], HAIR["base"])  # mai trái
    rect(d, [38, 10 + b, 40, 17 + b], HAIR["dark"])  # mai phải (tối)
    # vòng trán thép + ngọc teal
    line(d, [(26, 11 + b), (38, 11 + b)], STEEL["light"], 2)
    px(d, 32, 11 + b, CLOAK["hi"])
    px(d, 32, 10 + b, STEEL["hi"])
    if style == "hurt":
        for ex in (28, 35):  # mắt X
            line(d, [(ex - 1, 15 + b), (ex + 1, 17 + b)], C("#241a12"), 1)
            line(d, [(ex - 1, 17 + b), (ex + 1, 15 + b)], C("#241a12"), 1)
        ell(d, [30, 19 + b, 33, 21 + b], C("#5e2f22"))  # miệng há
    else:
        for ex in (29, 36):
            rect(d, [ex - 1, 15 + b, ex, 17 + b], C("#221812"))  # mắt
            px(d, ex - 1, 15 + b, C("#ffffff"))
        line(d, [(27, 13 + b), (30, 13 + b)], HAIR["dark"], 1)  # mày
        line(d, [(34, 13 + b), (37, 13 + b)], HAIR["dark"], 1)
        px(d, 32, 18 + b, SKIN["dark"])  # mũi
        px(d, 31, 18 + b, SKIN["light"])
        line(d, [(30, 20 + b), (33, 20 + b)], C("#a06a42"), 1)  # miệng

def p_head_up(d, b):
    """Đầu nhìn lên: tóc phủ kín sau đầu, đỉnh bo tròn, có lọn + bóng gáy."""
    rect(d, [29, 20 + b, 35, 24 + b], SKIN["dark"])
    poly(d, [(28, 4 + b), (36, 4 + b), (39, 8 + b), (39, 20 + b), (36, 22 + b), (28, 22 + b),
              (25, 20 + b), (25, 8 + b)], HAIR["base"])
    poly(d, [(34, 4 + b), (36, 4 + b), (39, 8 + b), (39, 20 + b), (36, 22 + b), (34, 22 + b)], HAIR["dark"])
    poly(d, [(28, 4 + b), (36, 4 + b), (37, 6 + b), (27, 6 + b)], HAIR["light"])
    for x in (28, 31, 35):  # lọn tóc dọc hơi cong
        line(d, [(x, 8 + b), (x - 1, 14 + b), (x, 19 + b)], HAIR["dark"], 1)
    line(d, [(27, 8 + b), (26, 15 + b)], HAIR["light"], 1)
    for x in range(26, 39, 2):  # mép tóc dưới răng cưa rõ
        line(d, [(x, 21 + b), (x, 23 + b)], HAIR["dark"], 1)
    ell(d, [27, 6 + b, 33, 10 + b], HAIR["light"])  # mảng sáng đỉnh đầu sau

def p_head_side(d, b):
    """Đầu profile hướng phải: 1 mắt, mũi nhô, tóc sau gáy."""
    rect(d, [28, 20 + b, 32, 24 + b], SKIN["dark"])
    poly(d, [(27, 10 + b), (37, 10 + b), (38, 15 + b), (41, 16 + b), (41, 18 + b),
              (38, 19 + b), (37, 22 + b), (29, 22 + b), (27, 19 + b)], SKIN["base"])
    poly(d, [(27, 10 + b), (31, 10 + b), (30, 22 + b), (29, 22 + b), (27, 19 + b)], SKIN["light"])
    # tóc: đỉnh bo tròn + sau đầu, mái trước ngắn
    poly(d, [(28, 3 + b), (36, 3 + b), (38, 6 + b), (39, 10 + b), (35, 9 + b), (34, 12 + b), (31, 9 + b),
              (29, 12 + b), (27, 10 + b), (25, 12 + b), (25, 18 + b), (28, 19 + b), (28, 12 + b)], HAIR["base"])
    poly(d, [(28, 3 + b), (36, 3 + b), (37, 5 + b), (27, 5 + b)], HAIR["light"])
    line(d, [(29, 6 + b), (28, 11 + b)], HAIR["dark"], 1)
    line(d, [(25, 12 + b), (28, 12 + b)], STEEL["light"], 2)  # vòng trán phía sau
    px(d, 30, 12 + b, CLOAK["hi"])
    rect(d, [35, 15 + b, 36, 17 + b], C("#221812"))  # mắt
    px(d, 35, 15 + b, C("#ffffff"))
    line(d, [(34, 13 + b), (37, 13 + b)], HAIR["dark"], 1)
    px(d, 39, 19 + b, SKIN["dark"])
    line(d, [(36, 20 + b), (39, 20 + b)], C("#a06a42"), 1)

def p_torso_down(d, b, lean=0):
    """Thân giáp nhìn xuống/lên dùng chung khung: giáp ngực 3 tông + đai + dây chéo."""
    t = b + lean
    # giáp ngực
    poly(d, [(25, 26 + t), (39, 26 + t), (41, 38 + t), (37, 42 + t), (27, 42 + t), (23, 38 + t)], STEEL["base"])
    poly(d, [(33, 26 + t), (39, 26 + t), (41, 38 + t), (37, 42 + t), (33, 42 + t)], STEEL["dark"])  # bóng phải
    poly(d, [(28, 27 + t), (31, 27 + t), (31, 40 + t), (28, 40 + t)], STEEL["light"])  # sống ngực sáng
    px(d, 29, 28 + t, STEEL["hi"])
    ell(d, [26, 29 + t, 30, 35 + t], STEEL["light"])  # mảng sáng ngực trái
    poly(d, [(24, 38 + t), (40, 38 + t), (37, 42 + t), (27, 42 + t)], STEEL["dark"])  # bóng nửa dưới giáp
    line(d, [(24, 37 + t), (40, 37 + t)], STEEL["dark"], 1)  # rãnh giáp ngang
    line(d, [(25, 26 + t), (39, 26 + t)], STEEL["hi"], 1)  # viền cổ sáng
    for rx, ry in ((26, 28), (38, 28)):  # đinh tán
        px(d, rx, ry + t, STEEL["hi"])
    # dây đai chéo da (dày, dễ đọc)
    line(d, [(26, 29 + t), (38, 39 + t)], LEATHER["dark"], 5)
    line(d, [(26, 28 + t), (38, 38 + t)], LEATHER["base"], 3)
    line(d, [(26, 28 + t), (38, 38 + t)], LEATHER["light"], 1)
    rect(d, [31, 33 + t, 34, 36 + t], GOLD["base"])
    px(d, 32, 34 + t, GOLD["light"])
    # thắt lưng + khóa vàng + đầu dây thừa
    rect(d, [24, 42 + t, 40, 45 + t], LEATHER["dark"])
    line(d, [(24, 42 + t), (40, 42 + t)], LEATHER["base"], 1)
    rect(d, [30, 42 + t, 34, 45 + t], GOLD["base"])
    rect(d, [31, 43 + t, 33, 44 + t], LEATHER["dark"])
    poly(d, [(37, 45 + t), (40, 45 + t), (39, 50 + t), (37, 49 + t)], LEATHER["dark"])

def p_pauldrons(d, b, back=False):
    for cx, dark_side in ((21, False), (43, True)):
        ell(d, [cx - 6, 24 + b, cx + 6, 32 + b], STEEL["dark"] if dark_side else STEEL["base"])
        ell(d, [cx - 5, 24 + b, cx + 3, 28 + b], STEEL["base"] if dark_side else STEEL["light"])
        line(d, [(cx - 4, 25 + b), (cx + 2, 24 + b)], STEEL["hi"], 1)
        line(d, [(cx - 5, 28 + b), (cx + 5, 28 + b)], STEEL["dark"], 1)  # rãnh chia lá pauldron
        line(d, [(cx - 6, 31 + b), (cx + 6, 31 + b)], STEEL["dark"], 1)
        px(d, cx, 26 + b, STEEL["hi"])  # đinh pauldron

def p_cloak_down(d, sway=0):
    poly(d, [(24, 27), (40, 27), (45, 48), (43, 53), (39, 49), (36, 54), (32 + sway, 50),
              (29, 54), (25, 49), (21, 53), (19, 48)], CLOAK["base"])
    poly(d, [(36, 27), (40, 27), (45, 48), (43, 53), (39, 49), (36, 54)], CLOAK["dark"])
    poly(d, [(28, 28), (31, 28), (30, 50), (27, 48)], CLOAK["dark"])  # nếp gấp tối
    poly(d, [(32 + sway, 28), (34, 28), (34, 49), (32 + sway, 50)], CLOAK["light"])  # nếp sáng giữa
    line(d, [(21, 52), (25, 48), (29, 53), (32 + sway, 49), (36, 53), (39, 48), (43, 52)], CLOAK["hi"], 1)

def p_cloak_up(d, sway=0):
    """Lưng choàng phủ gần hết thân khi nhìn từ sau."""
    poly(d, [(23, 25), (41, 25), (46, 50), (43, 55), (38, 51), (35, 56), (32 + sway, 51),
              (28, 56), (24, 51), (20, 55), (18, 50)], CLOAK["base"])
    for fx, tone in ((26, CLOAK["dark"]), (31, CLOAK["light"]), (37, CLOAK["dark"]), (41, CLOAK["light"])):
        poly(d, [(fx, 27), (fx + 3, 27), (fx + 4, 50), (fx + 1, 52)], tone)
    line(d, [(32 + sway, 27), (32 + sway, 50)], CLOAK["dark"], 1)  # đường may giữa
    line(d, [(20, 54), (24, 50), (28, 55), (32 + sway, 50), (35, 55), (38, 50), (43, 54)], CLOAK["hi"], 1)
    line(d, [(23, 25), (41, 25)], GOLD["dark"], 2)  # ghim choàng vàng ở cổ
    px(d, 32, 25, GOLD["light"])

# poses kiếm cho attack: (grip, tip) theo frame
P_ATK = {
    "down": [((47, 28), (58, 8)), ((45, 35), (22, 48)), ((48, 42), (58, 54))],
    "up":   [((47, 28), (58, 8)), ((48, 34), (60, 36)), ((48, 42), (56, 54))],
    "side": [((41, 27), (30, 7)), ((45, 33), (62, 29)), ((46, 40), (58, 52))],
}
WALK_L = {"dx": [-8, 0, 8, 0], "lift": [0, 7, 0, 7]}
WALK_R = {"dx": [8, 0, -8, 0], "lift": [7, 0, 7, 0]}

def player_frame(direction, mode, i):
    im = new_frame()
    d = D(im)
    if mode == "idle":
        bob = [0, 1][i % 2]
        sway = [0, 1][i % 2]
    elif mode == "walk":
        bob = [0, 1, 0, 1][i % 4]
        sway = 0
    else:
        bob, sway = 0, 0
    lean = 2 if mode == "attack" else 0

    if direction == "down":
        p_cloak_down(d, sway)  # choàng sau lưng: vẽ trước chân/thân
        if mode == "walk":
            leg_pants(d, (28, 41), (26 + WALK_L["dx"][i], 57), WALK_L["lift"][i], far=True)
            leg_pants(d, (36, 41), (38 + WALK_R["dx"][i], 57), WALK_R["lift"][i])
        elif mode == "attack":
            leg_pants(d, (28, 41), (23, 57), 0, far=True)
            leg_pants(d, (36, 41), (42, 57), 0)
        else:
            leg_pants(d, (28, 41), (24, 57), 0, far=True)
            leg_pants(d, (36, 41), (40, 57), 0)
        p_torso_down(d, bob, lean if direction == "down" else 0)
        p_head_down(d, bob)
        p_pauldrons(d, bob + lean)
        # tay trái buông
        arm_armor(d, (21, 30 + bob), (17, 41 + bob))
        # tay phải + kiếm
        if mode == "attack":
            grip, tip = P_ATK["down"][i]
            arm_armor(d, (43, 30 + bob), grip)
            sword(d, grip, tip)
        else:
            arm_armor(d, (43, 30 + bob), (47, 41 + bob))
            sword(d, (47, 41 + bob), (53, 60 + bob))
    elif direction == "up":
        if mode == "walk":
            leg_pants(d, (28, 41), (26 + WALK_L["dx"][i], 57), WALK_L["lift"][i], far=True)
            leg_pants(d, (36, 41), (38 + WALK_R["dx"][i], 57), WALK_R["lift"][i])
        else:
            leg_pants(d, (28, 41), (26, 57), 0, far=True)
            leg_pants(d, (36, 41), (38, 57), 0)
        p_cloak_up(d, sway)
        p_head_up(d, bob)
        p_pauldrons(d, bob)
        arm_armor(d, (20, 30 + bob), (16, 42 + bob))
        if mode == "attack":
            grip, tip = P_ATK["up"][i]
            arm_armor(d, (44, 30 + bob), grip)
            sword(d, grip, tip)
        else:
            arm_armor(d, (44, 30 + bob), (48, 42 + bob))
            sword(d, (48, 42 + bob), (55, 59 + bob))
    else:  # side
        # chân xa (tối) rồi chân gần
        if mode == "walk":
            leg_pants(d, (30, 41), (29 + WALK_R["dx"][i], 57), WALK_R["lift"][i], far=True)
            leg_pants(d, (35, 41), (36 + WALK_L["dx"][i], 57), WALK_L["lift"][i])
        elif mode == "attack":
            leg_pants(d, (30, 41), (24, 57), 0, far=True)
            leg_pants(d, (35, 41), (43, 57), 0)
        else:
            leg_pants(d, (30, 41), (28, 57), 0, far=True)
            leg_pants(d, (35, 41), (38, 57), 0)
        # choàng bay ra sau (trái)
        poly(d, [(28, 26 + bob), (21, 30 + bob), (14, 48), (17, 54), (24, 51), (28, 44)], CLOAK["base"])
        poly(d, [(24, 30 + bob), (21, 32 + bob), (17, 50), (20, 52), (24, 46)], CLOAK["dark"])
        line(d, [(17, 53), (24, 50)], CLOAK["hi"], 1)
        # thân profile: giáp hẹp hơn, sáng phía trước
        poly(d, [(27, 26 + bob), (38, 26 + bob), (40, 38 + bob), (37, 42 + bob), (28, 42 + bob), (25, 38 + bob)], STEEL["base"])
        poly(d, [(35, 26 + bob), (38, 26 + bob), (40, 38 + bob), (37, 42 + bob), (35, 42 + bob)], STEEL["light"])
        poly(d, [(27, 26 + bob), (29, 26 + bob), (27, 42 + bob), (28, 42 + bob)], STEEL["dark"])
        line(d, [(26, 37 + bob), (39, 37 + bob)], STEEL["dark"], 1)
        rect(d, [26, 42 + bob, 39, 45 + bob], LEATHER["dark"])
        rect(d, [33, 42 + bob, 37, 45 + bob], GOLD["base"])
        p_head_side(d, bob)
        # pauldron gần: gọn hơn, có rãnh chia lá
        ell(d, [32, 24 + bob, 44, 32 + bob], STEEL["base"])
        ell(d, [33, 24 + bob, 42, 29 + bob], STEEL["light"])
        line(d, [(34, 26 + bob), (40, 25 + bob)], STEEL["hi"], 1)
        line(d, [(33, 28 + bob), (43, 28 + bob)], STEEL["dark"], 1)
        line(d, [(32, 31 + bob), (44, 31 + bob)], STEEL["dark"], 1)
        px(d, 38, 26 + bob, STEEL["hi"])
        if mode == "attack":
            grip, tip = P_ATK["side"][i]
            arm_armor(d, (38, 30 + bob), grip)
            sword(d, grip, tip)
        else:
            arm_armor(d, (38, 30 + bob), (43, 41 + bob))
            sword(d, (43, 41 + bob), (50, 59 + bob))

    im = add_outline(im, P_OUTLINE)
    if mode == "attack" and i == 1:  # vệt chém ở frame vung
        if direction == "down":
            swoosh(im, 32, 28, 30, 15, 155)
        elif direction == "up":
            swoosh(im, 28, 32, 30, -95, 25)
        else:
            swoosh(im, 28, 30, 32, -60, 60)
    return im

def player_hurt(i):
    im = new_frame()
    d = D(im)
    p_cloak_down(d, 0)
    leg_pants(d, (28, 41), (25, 57), 0, far=True)
    leg_pants(d, (36, 41), (39, 57), 0)
    p_torso_down(d, 0)
    p_head_down(d, 0, style="hurt")
    p_pauldrons(d, 0)
    arm_armor(d, (21, 30), (17, 41))
    arm_armor(d, (43, 30), (47, 41))
    sword(d, (47, 41), (53, 60))
    im = add_outline(im, P_OUTLINE)
    out = new_frame()
    out.alpha_composite(im, dest=(-2 if i == 0 else 1, 0))
    if i == 1:  # nhuốm đỏ nhẹ báo đau
        ov = Image.new("RGBA", (FS, FS), (0, 0, 0, 0))
        pxa = ov.load()
        src = out.load()
        for y in range(FS):
            for x in range(FS):
                if src[x, y][3] > 0:
                    pxa[x, y] = (255, 64, 44, 64)
        out.alpha_composite(ov)
    return out

def squash(im, h):
    body = im.resize((FS, h), Image.NEAREST)
    out = new_frame()
    out.alpha_composite(body, dest=(0, FS - h))
    return out

def build_player_rows():
    rows = {}
    for dirn in ("down", "up", "side"):
        rows[f"idle_{dirn}"] = [player_frame(dirn, "idle", k) for k in range(2)]
        rows[f"walk_{dirn}"] = [player_frame(dirn, "walk", k) for k in range(4)]
        rows[f"attack_{dirn}"] = [player_frame(dirn, "attack", k) for k in range(3)]
        crouch = squash(player_frame(dirn, "idle", 0), 46)
        dd = D(crouch)  # vệt tốc độ khi cúi lăn
        for (x, y) in ((4, 44), (2, 50), (5, 55)):
            line(dd, [(x, y), (x + 5, y)], C("#bfe6f2", 120), 2)
        rows[f"dodge_{dirn}"] = [crouch, player_frame(dirn, "idle", 0).rotate(-90, resample=Image.NEAREST)]
    rows["hurt"] = [player_hurt(k) for k in range(2)]
    dead0 = player_hurt(0).rotate(90, resample=Image.NEAREST)
    dead1 = dead0.copy()
    dead1.putalpha(dead1.split()[3].point(lambda v: int(v * 0.5)))
    rows["death"] = [dead0, dead1]
    return rows

# ============================================================ GOBLIN
def g_head_down(d, b, style="normal"):
    """Đầu goblin nhìn xuống: tai cong dài, mắt vàng có tròng, nanh, đốm bẩn."""
    # tai: polygon cong ra hai bên, tai trong sẫm
    poly(d, [(24, 15 + b), (8, 8 + b), (5, 10 + b), (16, 19 + b), (23, 20 + b)], GSKIN["base"])
    poly(d, [(40, 15 + b), (56, 8 + b), (59, 10 + b), (48, 19 + b), (41, 20 + b)], GSKIN["dark"])
    poly(d, [(21, 15 + b), (11, 11 + b), (17, 17 + b)], GEAR_IN)
    poly(d, [(43, 15 + b), (53, 11 + b), (47, 17 + b)], GEAR_IN)
    # đầu (đỉnh bo tròn, hai bên má tối dần xuống cằm)
    poly(d, [(26, 7 + b), (38, 7 + b), (41, 10 + b), (43, 20 + b), (40, 27 + b), (24, 27 + b),
              (21, 20 + b), (23, 10 + b)], GSKIN["base"])
    poly(d, [(36, 7 + b), (38, 7 + b), (41, 10 + b), (43, 20 + b), (40, 27 + b), (36, 27 + b)], GSKIN["dark"])
    poly(d, [(23, 18 + b), (26, 18 + b), (25, 27 + b), (24, 27 + b), (21, 20 + b)], GSKIN["dark"])  # má trái tối
    ell(d, [25, 8 + b, 33, 15 + b], GSKIN["light"])  # trán sáng
    ell(d, [28, 22 + b, 36, 27 + b], GSKIN["light"])  # mõm/gò má dưới sáng
    # đốm bẩn trên da
    for (x, y) in ((38, 12), (25, 22), (39, 24)):
        px(d, x, y + b, GDIRT)
        px(d, x + 1, y + b, GDIRT)
    ell(d, [37, 11 + b, 40, 14 + b], GDIRT)
    # gờ mày cáu kỉnh
    line(d, [(24, 17 + b), (31, 19 + b)], GSKIN["dark"], 2)
    line(d, [(40, 17 + b), (33, 19 + b)], GSKIN["dark"], 2)
    if style == "hurt":
        for ex in (27, 36):
            line(d, [(ex - 1, 20 + b), (ex + 2, 23 + b)], C("#1c1408"), 1)
            line(d, [(ex - 1, 23 + b), (ex + 2, 20 + b)], C("#1c1408"), 1)
        ell(d, [29, 25 + b, 35, 28 + b], C("#2c1c0c"))  # miệng há to
    else:
        for ex in (28, 37):  # mắt vàng + tròng dọc + điểm sáng
            poly(d, [(ex - 2, 20 + b), (ex + 1, 19 + b), (ex + 2, 21 + b), (ex, 23 + b), (ex - 2, 22 + b)], GEYE)
            line(d, [(ex, 20 + b), (ex, 22 + b)], C("#1c1408"), 1)
            px(d, ex - 1, 20 + b, C("#ffffff"))
        px(d, 31, 23 + b, GSKIN["dark"])  # mũi
        px(d, 33, 23 + b, GSKIN["dark"])
        # miệng rộng + 2 nanh lên
        line(d, [(26, 26 + b), (38, 26 + b)], C("#2c1c0c"), 2)
        poly(d, [(27, 26 + b), (29, 26 + b), (28, 23 + b)], C("#f2efe2"))  # nanh trái
        poly(d, [(35, 26 + b), (37, 26 + b), (36, 23 + b)], C("#e2ddca"))  # nanh phải
    line(d, [(28, 28 + b), (36, 28 + b)], GSKIN["dark"], 1)  # cằm

def g_head_up(d, b):
    poly(d, [(24, 15 + b), (8, 8 + b), (5, 10 + b), (16, 19 + b), (23, 20 + b)], GSKIN["dark"])
    poly(d, [(40, 15 + b), (56, 8 + b), (59, 10 + b), (48, 19 + b), (41, 20 + b)], GSKIN["dark"])
    poly(d, [(26, 7 + b), (38, 7 + b), (41, 10 + b), (43, 20 + b), (40, 27 + b), (24, 27 + b),
              (21, 20 + b), (23, 10 + b)], GSKIN["dark"])
    poly(d, [(26, 9 + b), (36, 9 + b), (35, 24 + b), (27, 24 + b)], GSKIN["base"])  # mảng gáy sáng
    for x in (28, 32, 36):
        line(d, [(x, 11 + b), (x, 20 + b)], GSKIN["dark"], 1)
    px(d, 38, 13 + b, GDIRT)
    px(d, 27, 18 + b, GDIRT)

def g_head_side(d, b):
    """Profile phải: tai hất sau, mõm nhô, 1 mắt, 1 nanh."""
    poly(d, [(28, 14 + b), (10, 7 + b), (7, 9 + b), (20, 18 + b), (27, 19 + b)], GSKIN["base"])  # tai sau
    poly(d, [(25, 14 + b), (14, 10 + b), (21, 16 + b)], GEAR_IN)
    poly(d, [(26, 8 + b), (40, 8 + b), (42, 16 + b), (46, 19 + b), (46, 22 + b), (42, 23 + b),
              (40, 27 + b), (27, 27 + b), (24, 20 + b)], GSKIN["base"])
    poly(d, [(26, 8 + b), (32, 8 + b), (30, 26 + b), (27, 27 + b), (24, 20 + b)], GSKIN["light"])
    ell(d, [37, 11 + b, 40, 14 + b], GDIRT)
    line(d, [(33, 17 + b), (39, 18 + b)], GSKIN["dark"], 2)  # gờ mày
    poly(d, [(35, 19 + b), (38, 19 + b), (39, 21 + b), (36, 22 + b)], GEYE)
    px(d, 37, 20 + b, C("#1c1408"))
    px(d, 36, 19 + b, C("#ffffff"))
    px(d, 44, 20 + b, GSKIN["dark"])  # lỗ mũi trên mõm
    line(d, [(38, 25 + b), (45, 25 + b)], C("#2c1c0c"), 2)  # miệng
    poly(d, [(41, 25 + b), (43, 25 + b), (42, 22 + b)], C("#f2efe2"))  # nanh

def g_torso(d, b, back=False, side=False):
    """Thân goblin: bụng sáng + khố/áo rách nâu có vá, dây thừng thắt lưng."""
    if back:
        poly(d, [(24, 29 + b), (40, 29 + b), (42, 44 + b), (22, 44 + b)], RAG["base"])
        poly(d, [(34, 29 + b), (40, 29 + b), (42, 44 + b), (35, 44 + b)], RAG["dark"])
        rect(d, [27, 34 + b, 33, 40 + b], RAG["patch"])  # miếng vá sau lưng
        for sx in range(28, 33, 2):
            px(d, sx, 34 + b, RAG["dark"])
            px(d, sx, 39 + b, RAG["dark"])
    elif side:
        poly(d, [(26, 29 + b), (39, 29 + b), (40, 44 + b), (25, 44 + b)], GSKIN["base"])
        poly(d, [(26, 29 + b), (31, 29 + b), (29, 44 + b), (25, 44 + b)], RAG["base"])
        ell(d, [31, 33 + b, 39, 43 + b], GSKIN["belly"])
        rect(d, [33, 36 + b, 38, 41 + b], RAG["patch"])
        px(d, 34, 36 + b, RAG["dark"])
        px(d, 37, 40 + b, RAG["dark"])
    else:
        poly(d, [(24, 29 + b), (40, 29 + b), (42, 44 + b), (22, 44 + b)], GSKIN["base"])
        poly(d, [(36, 29 + b), (40, 29 + b), (42, 44 + b), (37, 44 + b)], GSKIN["dark"])
        ell(d, [26, 31 + b, 38, 45 + b], GSKIN["light"])  # viền bụng mềm
        ell(d, [27, 32 + b, 37, 44 + b], GSKIN["belly"])  # bụng phệ sáng
        px(d, 32, 38 + b, GSKIN["dark"])  # rốn
        # áo rách phủ vai + hai vạt hai bên, mép zigzag
        poly(d, [(24, 29 + b), (40, 29 + b), (41, 34 + b), (22, 34 + b)], RAG["base"])
        poly(d, [(23, 34 + b), (27, 34 + b), (26, 43 + b), (24, 40 + b), (22, 43 + b)], RAG["base"])
        poly(d, [(37, 34 + b), (41, 34 + b), (42, 43 + b), (40, 40 + b), (38, 43 + b)], RAG["dark"])
        rect(d, [35, 30 + b, 39, 34 + b], RAG["patch"])  # vá vai phải + chỉ khâu
        for sx, sy in ((35, 30), (39, 30), (35, 34), (39, 34), (37, 32)):
            px(d, sx, sy + b, RAG["dark"])
        line(d, [(24, 31 + b), (31, 31 + b)], RAG["light"], 1)
    # dây thừng thắt lưng + nút thắt
    line(d, [(23, 44 + b), (41, 44 + b)], LEATHER["dark"], 3)
    line(d, [(23, 43 + b), (41, 43 + b)], LEATHER["light"], 1)
    ell(d, [30, 43 + b, 34, 47 + b], LEATHER["base"])
    # khố rách dưới thắt lưng
    poly(d, [(25, 46 + b), (39, 46 + b), (38, 51 + b), (35, 49 + b), (32, 52 + b), (29, 49 + b), (26, 51 + b)], RAG["dark"])
    line(d, [(27, 47 + b), (30, 47 + b)], RAG["light"], 1)

G_ATK = {
    "down": [((49, 30), (58, 12)), ((50, 38), (60, 44)), ((49, 44), (57, 56))],
    "up":   [((49, 30), (58, 12)), ((50, 36), (61, 34)), ((49, 44), (57, 56))],
    "side": [((43, 30), (34, 12)), ((47, 36), (61, 33)), ((47, 42), (59, 52))],
}

def goblin_frame(direction, mode, i):
    im = new_frame()
    d = D(im)
    bob = [0, 1][i % 2] if mode == "idle" else ([0, 1, 0, 1][i % 4] if mode == "walk" else 0)
    if direction == "down":
        if mode == "walk":
            leg_skin(d, (27, 47), (24 + WALK_L["dx"][i], 55), WALK_L["lift"][i], far=True)
            leg_skin(d, (37, 47), (40 + WALK_R["dx"][i], 55), WALK_R["lift"][i])
        else:
            leg_skin(d, (27, 47), (24, 55), 0, far=True)
            leg_skin(d, (37, 47), (40, 55), 0)
        g_torso(d, bob)
        g_head_down(d, bob)
        arm_skin(d, (22, 32 + bob), (16, 45 + bob), GSKIN)
        if mode == "attack":
            grip, tip = G_ATK["down"][i]
            arm_skin(d, (42, 32 + bob), grip, GSKIN)
            knife(d, grip, tip)
        else:
            arm_skin(d, (42, 32 + bob), (48, 45 + bob), GSKIN)
            knife(d, (48, 45 + bob), (54, 55 + bob))
    elif direction == "up":
        if mode == "walk":
            leg_skin(d, (27, 47), (24 + WALK_L["dx"][i], 55), WALK_L["lift"][i], far=True)
            leg_skin(d, (37, 47), (40 + WALK_R["dx"][i], 55), WALK_R["lift"][i])
        else:
            leg_skin(d, (27, 47), (24, 55), 0, far=True)
            leg_skin(d, (37, 47), (40, 55), 0)
        g_torso(d, bob, back=True)
        g_head_up(d, bob)
        arm_skin(d, (22, 32 + bob), (16, 45 + bob), GSKIN)
        if mode == "attack":
            grip, tip = G_ATK["up"][i]
            arm_skin(d, (42, 32 + bob), grip, GSKIN)
            knife(d, grip, tip)
        else:
            arm_skin(d, (42, 32 + bob), (48, 45 + bob), GSKIN)
            knife(d, (48, 45 + bob), (54, 55 + bob))
    else:  # side
        if mode == "walk":
            leg_skin(d, (30, 47), (27 + WALK_R["dx"][i], 55), WALK_R["lift"][i], far=True)
            leg_skin(d, (35, 47), (38 + WALK_L["dx"][i], 55), WALK_L["lift"][i])
        elif mode == "attack":
            leg_skin(d, (30, 47), (25, 55), 0, far=True)
            leg_skin(d, (35, 47), (43, 55), 0)
        else:
            leg_skin(d, (30, 47), (27, 55), 0, far=True)
            leg_skin(d, (35, 47), (40, 55), 0)
        g_torso(d, bob, side=True)
        g_head_side(d, bob)
        far = {"dark": C("#2c4c18"), "base": GSKIN["dark"], "light": GSKIN["base"]}
        arm_skin(d, (27, 32 + bob), (22, 44 + bob), far)  # tay xa (tối hơn để tách lớp)
        if mode == "attack":
            grip, tip = G_ATK["side"][i]
            arm_skin(d, (38, 32 + bob), grip, GSKIN)
            knife(d, grip, tip)
        else:
            arm_skin(d, (38, 32 + bob), (44, 44 + bob), GSKIN)
            knife(d, (44, 44 + bob), (50, 54 + bob))
    im = add_outline(im, G_OUTLINE)
    if mode == "attack" and i == 1:
        if direction == "down":
            swoosh(im, 30, 30, 30, 20, 130, core=C("#ffe9b0"))
        elif direction == "up":
            swoosh(im, 28, 32, 30, -80, 20, core=C("#ffe9b0"))
        else:
            swoosh(im, 34, 34, 26, -50, 60, core=C("#ffe9b0"))
    return im

def goblin_hurt(i):
    im = new_frame()
    d = D(im)
    leg_skin(d, (27, 47), (23, 55), 0, far=True)
    leg_skin(d, (37, 47), (41, 55), 0)
    g_torso(d, 0)
    g_head_down(d, 0, style="hurt")
    arm_skin(d, (22, 32), (16, 45), GSKIN)
    arm_skin(d, (42, 32), (48, 45), GSKIN)
    knife(d, (48, 45), (54, 55))
    im = add_outline(im, G_OUTLINE)
    out = new_frame()
    out.alpha_composite(im, dest=(-2 if i == 0 else 1, 0))
    if i == 1:
        ov = Image.new("RGBA", (FS, FS), (0, 0, 0, 0))
        pxa = ov.load()
        src = out.load()
        for y in range(FS):
            for x in range(FS):
                if src[x, y][3] > 0:
                    pxa[x, y] = (255, 64, 44, 64)
        out.alpha_composite(ov)
    return out

def build_goblin_rows():
    rows = {}
    for dirn in ("down", "up", "side"):
        rows[f"idle_{dirn}"] = [goblin_frame(dirn, "idle", k) for k in range(2)]
        rows[f"walk_{dirn}"] = [goblin_frame(dirn, "walk", k) for k in range(4)]
        rows[f"attack_{dirn}"] = [goblin_frame(dirn, "attack", k) for k in range(3)]
    rows["hurt"] = [goblin_hurt(k) for k in range(2)]
    dead0 = goblin_hurt(0).rotate(90, resample=Image.NEAREST)
    dead1 = dead0.copy()
    dead1.putalpha(dead1.split()[3].point(lambda v: int(v * 0.5)))
    rows["death"] = [dead0, dead1]
    return rows

# ============================================================ XUẤT SHEET / TRES / PREVIEW
PLAYER_ROWS = ["idle_down", "idle_up", "idle_side",
               "walk_down", "walk_up", "walk_side",
               "attack_down", "attack_up", "attack_side",
               "dodge_down", "dodge_up", "dodge_side",
               "hurt", "death"]
GOBLIN_ROWS = ["idle_down", "idle_up", "idle_side",
               "walk_down", "walk_up", "walk_side",
               "attack_down", "attack_up", "attack_side",
               "hurt", "death"]
ANIM_META = {
    "idle": (3.0, True), "walk": (8.0, True), "attack": (12.0, False),
    "dodge": (10.0, False), "hurt": (8.0, False), "death": (4.0, False),
}

def compose_sheet(rows_data, row_order):
    cols = max(len(rows_data[r]) for r in row_order)
    sheet = Image.new("RGBA", (cols * FS, len(row_order) * FS), (0, 0, 0, 0))
    for ri, name in enumerate(row_order):
        for ci, fr in enumerate(rows_data[name]):
            sheet.alpha_composite(fr, dest=(ci * FS, ri * FS))
    return sheet

def write_tres(path, rows_data, row_order, sheet_res_path):
    atlas_lines, anim_chunks, aid = [], [], 0
    for ri, name in enumerate(row_order):
        tex_ids = []
        for ci in range(len(rows_data[name])):
            aid += 1
            tid = f"AtlasTexture_{aid:03d}"
            tex_ids.append(tid)
            atlas_lines.append(
                f'[sub_resource type="AtlasTexture" id="{tid}"]\n'
                f'atlas = ExtResource("1_sheet")\n'
                f'region = Rect2({ci * FS}, {ri * FS}, {FS}, {FS})\n')
        speed, loop = ANIM_META[name.split("_")[0]]
        frames_txt = ", ".join(
            '{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % t for t in tex_ids)
        anim_chunks.append(
            '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
            % (frames_txt, "true" if loop else "false", name, speed))
    content = (
        f'[gd_resource type="SpriteFrames" load_steps={aid + 2} format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{sheet_res_path}" id="1_sheet"]\n\n'
        + "\n".join(atlas_lines)
        + "\n[resource]\nanimations = ["
        + ", ".join(anim_chunks) + "]\n")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    return aid

def checker(w, h, cell=16):
    bg = Image.new("RGBA", (w, h), (40, 42, 48, 255))
    d = ImageDraw.Draw(bg)
    for y in range(0, h, cell):
        for x in range(0, w, cell):
            if (x // cell + y // cell) % 2 == 0:
                d.rectangle([x, y, x + cell - 1, y + cell - 1], fill=(56, 58, 66, 255))
    return bg

def make_preview(p_sheet, g_sheet, p_rows, g_rows):
    """Preview v2: 2 sheet phóng x2 (có khung frame) + hàng 'hero' phóng x5 để soi chi tiết."""
    scale = 2
    pw, ph = p_sheet.width * scale, p_sheet.height * scale
    gw, gh = g_sheet.width * scale, g_sheet.height * scale
    pad = 24
    hero = [("P idle", p_rows["idle_down"][0]), ("P walk", p_rows["walk_side"][2]),
            ("P atk", p_rows["attack_down"][1]), ("G idle", g_rows["idle_down"][0]),
            ("G atk", g_rows["attack_side"][1]), ("G die", g_rows["death"][0])]
    hero_h = FS * 5
    W = pw + gw + pad * 3
    H = max(ph, gh) + hero_h + pad * 3
    prev = checker(W, H, 24)
    prev.alpha_composite(p_sheet.resize((pw, ph), Image.NEAREST), dest=(pad, pad))
    prev.alpha_composite(g_sheet.resize((gw, gh), Image.NEAREST), dest=(pad * 2 + pw, pad))
    d = ImageDraw.Draw(prev)
    for ox, sheet, rows_n, cols_n in ((pad, p_sheet, 14, 4), (pad * 2 + pw, g_sheet, 11, 4)):
        for r in range(rows_n):
            for c in range(cols_n):
                x0, y0 = ox + c * FS * scale, pad + r * FS * scale
                d.rectangle([x0, y0, x0 + FS * scale - 1, y0 + FS * scale - 1],
                            outline=(255, 200, 60, 160))
    hy = pad * 2 + max(ph, gh)
    cell_w = (W - pad * 2) // len(hero)
    for k, (_label, fr) in enumerate(hero):
        big = fr.resize((hero_h, hero_h), Image.NEAREST)
        x0 = pad + k * cell_w + (cell_w - hero_h) // 2
        prev.alpha_composite(big, dest=(x0, hy))
        d.rectangle([x0, hy, x0 + hero_h - 1, hy + hero_h - 1], outline=(120, 220, 255, 200))
    prev.convert("RGB").save(os.path.join(DESIGN_DIR, "sprite_preview_v2.png"))
    prev.convert("RGB").save(os.path.join(DESIGN_DIR, "sprite_preview.png"))

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(DESIGN_DIR, exist_ok=True)
    p_rows = build_player_rows()
    g_rows = build_goblin_rows()
    p_sheet = compose_sheet(p_rows, PLAYER_ROWS)
    g_sheet = compose_sheet(g_rows, GOBLIN_ROWS)
    p_sheet.save(os.path.join(OUT_DIR, "player_spritesheet.png"))
    g_sheet.save(os.path.join(OUT_DIR, "goblin_spritesheet.png"))
    print("player sheet:", p_sheet.size, "goblin sheet:", g_sheet.size)
    n1 = write_tres(os.path.join(OUT_DIR, "player_frames.tres"), p_rows, PLAYER_ROWS,
                    "res://assets/sprites/player_spritesheet.png")
    n2 = write_tres(os.path.join(OUT_DIR, "goblin_frames.tres"), g_rows, GOBLIN_ROWS,
                    "res://assets/sprites/goblin_spritesheet.png")
    print("atlas textures:", n1, n2)
    make_preview(p_sheet, g_sheet, p_rows, g_rows)
    print("preview ->", os.path.join(DESIGN_DIR, "sprite_preview_v2.png"))

if __name__ == "__main__":
    main()
