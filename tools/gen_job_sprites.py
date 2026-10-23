#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh spritesheet NPC việc làm cho game "Dưới Bóng Phong Ấn" — frame 128x128.

Cùng pipeline v3 (tools/gen_sprites_v3.py):
- Vẽ SUPERSAMPLE ở 512x512 (4x) bằng PIL: polygon tham số, limb có khớp,
  shading nhiều lớp (base -> gradient tối đáy -> highlight radial -> rim).
- Downscale về 128x128 bằng LANCZOS + unsharp nhẹ.
- Chân (điểm chạm đất) cố định ở y=112 trong frame.
- Mỗi HÀNG sheet = 1 animation, frame từ cột 0. Hướng: down/up/side
  (side = nhìn phải, trái dùng flip_h trong Godot).
- Animation theo quy ước npc.gd: idle_down/up/side, walk_down/up/side,
  riêng thợ rèn + nông dân có thêm "work" (4 frame, hướng xuống — NPC
  đứng tại điểm làm việc quay mặt xuống như quy ước engine schedule).

Bộ sprite:
- tho_ren   : áo rust sẫm, tạp dề da có đinh tán/túi, băng trán đỏ, râu,
              búa rèn (work: giơ cao -> bổ xuống đe -> giữ -> nhấc, có tia lửa).
- nong_dan  : nón lá/rơm, khăn rằn đỏ, áo xanh rêu, cuốc
              (work: giơ cuốc -> bổ xuống đất -> kéo về -> đứng lên).
- linh_tuan : giáp thép + tabard đỏ + mũ giáp, giáo dài + khiên luôn đọc
              được ở cả idle/walk 3 hướng; idle = đứng nghiêm canh gác
              (engine coi action "work" của lính = idle khi thiếu anim work).

Chạy: python3 tools/gen_job_sprites.py
Xuất: game/assets/sprites/{tho_ren,nong_dan,linh_tuan}_spritesheet.png
      game/assets/sprites/{tho_ren,nong_dan,linh_tuan}_frames.tres
"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageChops, ImageFilter

SS = 4
FS = 128
W = FS * SS
GROUND = 112.0

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "game", "assets", "sprites")
os.makedirs(OUT_DIR, exist_ok=True)
random.seed(20261023)

# ---------------- gradients / helpers (theo gen_sprites_v3) ----------------

def _grad_image(fn):
    small = Image.new("L", (FS, FS))
    px = small.load()
    for y in range(FS):
        for x in range(FS):
            px[x, y] = max(0, min(255, int(fn(x / FS, y / FS) * 255)))
    return small.resize((W, W), Image.BILINEAR)

GRAD_BOTTOM = _grad_image(lambda u, v: max(0.0, (v - 0.35) / 0.65) * 0.85)
GRAD_TOPLIGHT = _grad_image(lambda u, v: max(0.0, 1.0 - math.hypot(u - 0.32, v - 0.2) / 0.95))
GRAD_RIM = _grad_image(lambda u, v: max(0.0, (math.hypot(u - 0.5, v - 0.5) - 0.18) / 0.5))

OUT = (16, 22, 30, 255)
SKIN = (233, 186, 138, 255); SKIN_D = (203, 145, 94, 255); SKIN_L = (248, 216, 174, 255)
STEEL_D = (58, 74, 92, 255); STEEL = (110, 134, 156, 255); STEEL_L = (168, 188, 208, 255); STEEL_HI = (228, 238, 248, 255)
GOLD = (198, 158, 44, 255); GOLD_L = (242, 208, 96, 255)
LEATHER = (110, 74, 42, 255); LEATHER_D = (76, 48, 25, 255); LEATHER_L = (150, 106, 62, 255)
WOOD = (122, 84, 46, 255); WOOD_D = (84, 56, 28, 255); WOOD_L = (164, 120, 70, 255)
BLADE = (224, 233, 240, 255)

def A(col, a):
    return col[:3] + (a,)

def P_(pts):
    return [(x * SS, y * SS) for (x, y) in pts]

def poly(im, pts, fill=None, outline=None, ow=1.1):
    d = ImageDraw.Draw(im)
    d.polygon(P_(pts), fill=fill, outline=outline, width=max(1, int(ow * SS)) if outline else 1)

def ell_pts(cx, cy, rx, ry, rot=0.0, a0=0.0, a1=360.0, n=40):
    pts = []
    rot_r = math.radians(rot)
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        ex, ey = rx * math.cos(a), ry * math.sin(a)
        pts.append((cx + ex * math.cos(rot_r) - ey * math.sin(rot_r),
                    cy + ex * math.sin(rot_r) + ey * math.cos(rot_r)))
    return pts

def ell(im, cx, cy, rx, ry, fill=None, outline=None, ow=1.1, rot=0.0):
    poly(im, ell_pts(cx, cy, rx, ry, rot), fill=fill, outline=outline, ow=ow)

def line(im, p0, p1, fill, w=2.0):
    d = ImageDraw.Draw(im)
    d.line([p0[0] * SS, p0[1] * SS, p1[0] * SS, p1[1] * SS], fill=fill,
           width=max(1, int(w * SS)), joint="curve")
    r = w / 2.0
    ell(im, p0[0], p0[1], r, r, fill=fill)
    ell(im, p1[0], p1[1], r, r, fill=fill)

def limb(im, p0, p1, w, base, dark, light):
    line(im, p0, p1, dark, w + 1.6)
    line(im, p0, p1, base, w)
    off = (-w * 0.18, -w * 0.18)
    line(im, (p0[0] + off[0], p0[1] + off[1]), (p1[0] + off[0], p1[1] + off[1]), light, w * 0.34)

def shade(im, pts, dark_rgb, light_rgb, rim_rgb=None, dark_a=95, light_a=80, rim_a=60):
    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).polygon(P_(pts), fill=255)
    for rgb, grad, amax in ((dark_rgb, GRAD_BOTTOM, dark_a), (light_rgb, GRAD_TOPLIGHT, light_a)):
        ov = Image.new("RGBA", (W, W), rgb + (0,))
        a = ImageChops.multiply(mask, grad).point(lambda v: v * amax // 255)
        ov.putalpha(a)
        im.alpha_composite(ov)
    if rim_rgb is not None:
        rim = ImageChops.subtract(mask, mask.transform((W, W), Image.AFFINE, (1, 0, 3.0, 0, 1, 3.0)))
        a = ImageChops.multiply(rim, GRAD_RIM).point(lambda v: v * rim_a // 255)
        ov = Image.new("RGBA", (W, W), rim_rgb + (0,))
        ov.putalpha(a)
        im.alpha_composite(ov)

def dots(im, cx, cy, rx, ry, n, col, rmin=0.7, rmax=1.6, seed=7):
    rnd = random.Random(seed)
    for _ in range(n):
        a = rnd.uniform(0, 2 * math.pi); rr = math.sqrt(rnd.uniform(0, 1))
        x, y = cx + rx * rr * math.cos(a), cy + ry * rr * math.sin(a)
        r = rnd.uniform(rmin, rmax)
        ell(im, x, y, r, r * 0.8, fill=col)

def new_canvas():
    return Image.new("RGBA", (W, W), (0, 0, 0, 0))

def finish(frame512):
    out = frame512.resize((FS, FS), Image.LANCZOS)
    return out.filter(ImageFilter.UnsharpMask(radius=2, percent=58, threshold=3))

# ---------------- bảng màu từng nghề ----------------
CHARS = {
    "tho_ren": {
        "hair": (52, 36, 24, 255), "hair_d": (32, 22, 14, 255), "hair_l": (84, 58, 34, 255),
        "shirt": (122, 54, 38, 255), "shirt_d": (84, 36, 26, 255), "shirt_l": (162, 82, 58, 255),
        "pants": (58, 50, 46, 255), "pants_d": (38, 32, 30, 255),
        "accent": (178, 44, 40, 255),  # băng trán đỏ
    },
    "nong_dan": {
        "hair": (40, 30, 20, 255), "hair_d": (26, 19, 12, 255), "hair_l": (66, 50, 32, 255),
        "shirt": (94, 122, 66, 255), "shirt_d": (62, 84, 42, 255), "shirt_l": (128, 156, 92, 255),
        "pants": (96, 70, 44, 255), "pants_d": (66, 47, 29, 255),
        "accent": (172, 52, 44, 255),  # khăn rằn đỏ
        "straw": (216, 182, 104, 255), "straw_d": (178, 142, 70, 255), "straw_l": (240, 208, 140, 255),
    },
    "linh_tuan": {
        "hair": (44, 32, 22, 255), "hair_d": (28, 20, 13, 255), "hair_l": (72, 54, 34, 255),
        "shirt": STEEL, "shirt_d": STEEL_D, "shirt_l": STEEL_L,
        "pants": (52, 60, 72, 255), "pants_d": (34, 40, 50, 255),
        "accent": (156, 42, 46, 255),  # tabard / mào đỏ
    },
}

# ---------------- chân / thân / đầu dùng chung ----------------

def draw_legs(im, direction, phase, mode, pal, wide=False):
    hip_y = 88.0
    pants, pants_d = pal["pants"], pal["pants_d"]
    leg_light = tuple(min(255, c + 36) for c in pants[:3]) + (255,)  # highlight dịu theo màu quần
    if direction in ("down", "up"):
        hips = [(57.5, hip_y), (70.5, hip_y)]
        if mode == "walk":
            ph = math.sin(phase * math.pi)
            feet = [(57.5 + ph * 4.5, GROUND - max(0.0, math.cos(phase * math.pi)) * 2.5),
                    (70.5 - ph * 4.5, GROUND - max(0.0, -math.cos(phase * math.pi)) * 2.5)]
        elif wide:
            feet = [(51.5, GROUND), (76.5, GROUND)]
        else:
            feet = [(56.5, GROUND), (71.5, GROUND)]
        for (hx, hy), (fx, fy) in zip(hips, feet):
            mid = ((hx + fx) / 2, (hy + fy) / 2 + 2)
            limb(im, (hx, hy), mid, 6.4, pants, pants_d, leg_light)
            limb(im, mid, (fx, fy - 5), 5.6, pants, pants_d, leg_light)
            ell(im, fx, fy - 3.4, 5.4, 3.8, fill=LEATHER, outline=OUT, ow=0.9)
            ell(im, fx + 1.2, fy - 2.2, 3.4, 2.2, fill=LEATHER_L)
            line(im, (fx - 5, fy - 0.6), (fx + 5.4, fy - 0.6), LEATHER_D, 1.2)
    else:
        hips = [(61.0, hip_y), (67.0, hip_y)]
        if mode == "walk":
            ph = math.sin(phase * math.pi)
            feet = [(61.0 + ph * 9.0, GROUND - max(0.0, math.cos(phase * math.pi)) * 3.0),
                    (67.0 - ph * 9.0, GROUND - max(0.0, -math.cos(phase * math.pi)) * 3.0)]
        elif wide:
            feet = [(52.0, GROUND), (78.0, GROUND)]
        else:
            feet = [(58.0, GROUND), (72.0, GROUND)]
        for idx in (1, 0):
            hx, hy = hips[idx]; fx, fy = feet[idx]
            base = pants_d if idx == 1 else pants
            mid = ((hx + fx) / 2, (hy + fy) / 2 + 2)
            limb(im, (hx, hy), mid, 6.2, base, pants_d, leg_light)
            limb(im, mid, (fx, fy - 5), 5.4, base, pants_d, leg_light)
            ell(im, fx + 1.5, fy - 3.4, 5.6, 3.8, fill=LEATHER if idx == 0 else LEATHER_D, outline=OUT, ow=0.9)
            ell(im, fx + 3.0, fy - 2.4, 3.2, 2.0, fill=LEATHER_L)

def _torso_pts(cx, cy=68, rx=15.5, ry=17.5):
    pts = ell_pts(cx, cy, rx, ry)
    pts = [(x, y) for (x, y) in pts if y < 86]
    pts += [(cx + 10.5, 88), (cx - 10.5, 88)]
    return pts

def draw_torso(im, key, direction, pal, lean=0.0):
    cx = 64.0 + lean
    shirt, shirt_d, shirt_l = pal["shirt"], pal["shirt_d"], pal["shirt_l"]
    if direction == "up":
        pts = _torso_pts(cx)
        if key == "linh_tuan":
            # áo choàng đỏ phủ lưng giáp
            poly(im, pts, fill=pal["accent"], outline=OUT, ow=1.2)
            shade(im, pts, (96, 22, 26, 255)[:3], (196, 84, 84, 255)[:3], dark_a=110, light_a=55)
            d = ImageDraw.Draw(im)
            for fx in (0.32, 0.5, 0.68):
                x0 = cx - 13 + fx * 26
                d.line(P_([(x0, 56), (x0 - 1, 86)]), fill=A((96, 22, 26, 255), 170), width=int(1.0 * SS))
        else:
            poly(im, pts, fill=shirt, outline=OUT, ow=1.2)
            shade(im, pts, shirt_d[:3], shirt_l[:3], dark_a=105, light_a=70)
            if key == "tho_ren":
                # quai tạp dề bắt chéo sau lưng
                line(im, (cx - 11, 56), (cx + 11, 84), LEATHER_D, 3.4)
                line(im, (cx + 11, 56), (cx - 11, 84), LEATHER_D, 3.4)
                line(im, (cx - 11, 56), (cx + 11, 84), LEATHER_L, 1.0)
            else:
                # dây đeo gùi chéo
                line(im, (cx - 12, 55), (cx + 10, 85), WOOD_D, 4.4)
                line(im, (cx - 12, 55), (cx + 10, 85), WOOD, 3.0)
        belt = [(cx - 12.5, 84), (cx + 12.5, 84), (cx + 12, 89), (cx - 12, 89)]
        poly(im, belt, fill=LEATHER_D, outline=OUT, ow=0.9)
        return
    if direction == "side":
        pts = _torso_pts(cx, rx=12.5)
        base = STEEL if key == "linh_tuan" else shirt
        dark = STEEL_D if key == "linh_tuan" else shirt_d
        light = STEEL_HI if key == "linh_tuan" else shirt_l
        poly(im, pts, fill=base, outline=OUT, ow=1.2)
        shade(im, pts, dark[:3], light[:3], dark_a=100, light_a=70)
        if key == "tho_ren":
            apron = [(cx + 1, 56), (cx + 11.5, 60), (cx + 11, 88), (cx + 1, 88)]
            poly(im, apron, fill=LEATHER_L, outline=OUT, ow=0.9)
            shade(im, apron, LEATHER_D[:3], (186, 140, 92, 255)[:3], dark_a=80, light_a=50)
        elif key == "nong_dan":
            poly(im, [(cx + 6, 51), (cx + 12, 53), (cx + 7, 60)], fill=pal["accent"], outline=OUT, ow=0.7)
        else:
            # pauldron vai trước lớn + mép tabard đỏ ở ngực
            pts2 = ell_pts(cx + 8, 55, 8.4, 6.4)
            poly(im, pts2, fill=STEEL_L, outline=OUT, ow=1.0)
            shade(im, pts2, STEEL_D[:3], STEEL_HI[:3], dark_a=80, light_a=70)
            line(im, (cx + 10.5, 60), (cx + 10.5, 86), pal["accent"], 2.6)
        belt = [(cx - 10, 84), (cx + 11, 84), (cx + 10.5, 89), (cx - 9.5, 89)]
        poly(im, belt, fill=LEATHER_D, outline=OUT, ow=0.9)
        return
    # ---- down ----
    pts = _torso_pts(cx)
    if key == "linh_tuan":
        poly(im, pts, fill=STEEL, outline=OUT, ow=1.2)
        shade(im, pts, STEEL_D[:3], STEEL_HI[:3], rim_rgb=STEEL_L[:3], dark_a=105, light_a=85)
        d = ImageDraw.Draw(im)
        line(im, (cx, 53), (cx, 82), STEEL_D, 1.0)
        for yy in (62, 71, 79):
            d.line(P_([(cx - 12.5, yy), (cx + 12.5, yy)]), fill=A(STEEL_D, 110), width=int(0.8 * SS))
        # tabard đỏ giữa ngực chạy xuống qua đai
        tab = [(cx - 5, 57), (cx + 5, 57), (cx + 6, 96), (cx, 101), (cx - 6, 96)]
        poly(im, tab, fill=pal["accent"], outline=OUT, ow=0.9)
        shade(im, tab, (96, 22, 26, 255)[:3], (200, 92, 92, 255)[:3], dark_a=90, light_a=55)
        line(im, (cx, 60), (cx, 95), GOLD, 0.9)
        for sx in (-15.0, 15.0):
            for k, (dy, rr) in enumerate(((0, 8.8), (4.6, 7.6))):
                pts2 = ell_pts(cx + sx, 55 + dy, rr, rr * 0.72)
                poly(im, pts2, fill=STEEL_L if k == 0 else STEEL, outline=OUT, ow=1.0)
                shade(im, pts2, STEEL_D[:3], STEEL_HI[:3], dark_a=80, light_a=75)
            ell(im, cx + sx - 2.5, 53.5, 1.1, 1.1, fill=STEEL_HI, outline=OUT, ow=0.5)
    elif key == "tho_ren":
        poly(im, pts, fill=shirt, outline=OUT, ow=1.2)
        shade(im, pts, shirt_d[:3], shirt_l[:3], dark_a=105, light_a=70)
        # tạp dề da: thân thang + quai cổ + đinh tán + túi
        apron = [(cx - 9.5, 57), (cx + 9.5, 57), (cx + 12, 89), (cx - 12, 89)]
        poly(im, apron, fill=LEATHER_L, outline=OUT, ow=1.1)
        shade(im, apron, LEATHER_D[:3], (196, 152, 102, 255)[:3], dark_a=95, light_a=60)
        line(im, (cx - 13, 53), (cx - 8, 58), LEATHER_D, 2.6)
        line(im, (cx + 13, 53), (cx + 8, 58), LEATHER_D, 2.6)
        for rx_ in (-8.2, 8.2):
            ell(im, cx + rx_, 60.5, 1.2, 1.2, fill=GOLD, outline=OUT, ow=0.5)
            ell(im, cx + rx_, 86.5, 1.2, 1.2, fill=GOLD, outline=OUT, ow=0.5)
        pocket = [(cx - 6, 73), (cx + 6, 73), (cx + 5.4, 82), (cx - 5.4, 82)]
        poly(im, pocket, fill=LEATHER, outline=LEATHER_D, ow=0.9)
        line(im, (cx - 6, 76), (cx + 6, 76), LEATHER_D, 0.9)
        dots(im, cx, 68, 8, 10, 5, LEATHER_D, 0.5, 1.0, seed=21)  # vết cháy xém trên tạp dề
    else:  # nong_dan
        poly(im, pts, fill=shirt, outline=OUT, ow=1.2)
        shade(im, pts, shirt_d[:3], shirt_l[:3], dark_a=100, light_a=70)
        # khăn rằn đỏ tam giác ở cổ
        poly(im, [(cx - 6.5, 51.5), (cx + 6.5, 51.5), (cx, 63)], fill=pal["accent"], outline=OUT, ow=0.8)
        line(im, (cx - 4, 53), (cx, 59), GOLD_L, 0.7)
        dots(im, cx, 72, 11, 12, 6, shirt_d, 0.5, 1.0, seed=31)
    if key != "linh_tuan":
        belt = [(cx - 12.5, 84), (cx + 12.5, 84), (cx + 12, 89), (cx - 12, 89)]
        if key == "nong_dan":
            poly(im, belt, fill=WOOD, outline=OUT, ow=0.9)  # đai dây thừng
            ell(im, cx + 7, 86.5, 2.2, 1.8, fill=WOOD_D, outline=OUT, ow=0.6)
        else:
            poly(im, belt, fill=LEATHER_D, outline=OUT, ow=0.9)
            ell(im, cx, 86.5, 2.4, 1.9, fill=GOLD, outline=OUT, ow=0.7)
    else:
        belt = [(cx - 12.5, 84), (cx + 12.5, 84), (cx + 12, 89), (cx - 12, 89)]
        poly(im, belt, fill=LEATHER_D, outline=OUT, ow=0.9)
        ell(im, cx, 86.5, 2.4, 1.9, fill=GOLD, outline=OUT, ow=0.7)

def _face_down(im, cx, cy, pal):
    pts = ell_pts(cx, cy + 1.5, 12.2, 13.2)
    poly(im, pts, fill=SKIN, outline=OUT, ow=1.2)
    shade(im, pts, SKIN_D[:3], SKIN_L[:3], dark_a=75, light_a=60)
    for ex in (-5.6, 5.6):
        ell(im, cx + ex, cy + 1.2, 2.7, 3.3, fill=(255, 255, 255, 255), outline=OUT, ow=0.6)
        ell(im, cx + ex, cy + 1.6, 1.4, 2.1, fill=(52, 38, 26, 255))
        ell(im, cx + ex + 0.5, cy + 0.6, 0.6, 0.6, fill=(255, 255, 255, 255))
        line(im, (cx + ex - 3.1, cy - 3.2), (cx + ex + 3.1, cy - 2.6), pal["hair_d"], 1.4)
    line(im, (cx + 0.4, cy + 4.4), (cx - 0.5, cy + 6.6), SKIN_D, 1.0)
    line(im, (cx - 2.6, cy + 9.3), (cx + 2.6, cy + 9.3), (178, 108, 78, 255), 1.2)
    ell(im, cx - 8.6, cy + 6.4, 2.8, 1.8, fill=(240, 160, 120, 80))
    ell(im, cx + 8.6, cy + 6.4, 2.8, 1.8, fill=(240, 160, 120, 80))

def _face_side(im, cx, cy, pal):
    pts = ell_pts(cx - 2.5, cy, 13.0, 14.0)
    poly(im, pts, fill=pal["hair"], outline=OUT, ow=1.2)
    shade(im, pts, pal["hair_d"][:3], pal["hair_l"][:3], dark_a=95, light_a=65)
    face = ell_pts(cx + 2.5, cy + 1.5, 11.0, 12.6)
    poly(im, face, fill=SKIN, outline=OUT, ow=1.1)
    shade(im, face, SKIN_D[:3], SKIN_L[:3], dark_a=70, light_a=55)
    poly(im, [(cx + 12.4, cy + 1), (cx + 15.2, cy + 3.6), (cx + 12.2, cy + 5.2)], fill=SKIN_D, outline=OUT, ow=0.7)
    ell(im, cx + 7.6, cy + 0.5, 2.5, 3.1, fill=(255, 255, 255, 255), outline=OUT, ow=0.6)
    ell(im, cx + 8.4, cy + 0.7, 1.25, 1.9, fill=(40, 30, 22, 255))
    line(im, (cx + 4.6, cy - 3.4), (cx + 10.6, cy - 2.8), pal["hair_d"], 1.3)
    line(im, (cx + 8.6, cy + 8.6), (cx + 11.6, cy + 8.2), SKIN_D, 1.0)

def draw_head(im, key, direction, pal, dy=0.0, lean=0.0):
    cx, cy = 64.0 + lean, 36.0 + dy
    if direction == "up":
        if key == "nong_dan":
            # nón nhìn từ trên: vành tròn lớn + chóp + nan
            ell(im, cx, cy + 1, 21, 17.5, fill=pal["straw"], outline=OUT, ow=1.2)
            shade(im, ell_pts(cx, cy + 1, 21, 17.5), pal["straw_d"][:3], pal["straw_l"][:3], dark_a=80, light_a=60)
            d = ImageDraw.Draw(im)
            for ang in range(0, 360, 30):
                a = math.radians(ang)
                d.line(P_([(cx + 4 * math.cos(a), cy + 1 + 3.2 * math.sin(a)),
                           (cx + 19 * math.cos(a), cy + 1 + 15.5 * math.sin(a))]),
                       fill=A(pal["straw_d"], 130), width=int(0.8 * SS))
            ell(im, cx, cy - 1, 10.5, 8.5, fill=pal["straw_l"], outline=OUT, ow=1.0)
            ell(im, cx, cy - 2, 3.0, 2.4, fill=pal["straw_d"])
            return
        if key == "linh_tuan":
            pts = ell_pts(cx, cy, 13.5, 14.0)
            poly(im, pts, fill=STEEL, outline=OUT, ow=1.2)
            shade(im, pts, STEEL_D[:3], STEEL_HI[:3], dark_a=95, light_a=75)
            poly(im, [(cx - 1.8, cy - 15), (cx + 1.8, cy - 15), (cx + 1.2, cy + 8), (cx - 1.2, cy + 8)],
                 fill=pal["accent"], outline=OUT, ow=0.7)  # mào đỏ dọc đỉnh mũ
            line(im, (cx - 11, cy + 9.5), (cx + 11, cy + 9.5), STEEL_D, 1.6)
            return
        pts = ell_pts(cx, cy, 13.5, 14.0)
        poly(im, pts, fill=pal["hair"], outline=OUT, ow=1.2)
        shade(im, pts, pal["hair_d"][:3], pal["hair_l"][:3], dark_a=100, light_a=70)
        ell(im, cx, cy - 4, 3.2, 2.6, fill=pal["hair_l"])
        line(im, (cx - 11.5, cy + 8.5), (cx + 11.5, cy + 8.5), pal["accent"], 2.2)  # băng trán sau đầu
        return
    if direction == "side":
        _face_side(im, cx, cy, pal)
        if key == "tho_ren":
            # râu quai nón phía trước + băng trán
            poly(im, ell_pts(cx + 8.5, cy + 8.5, 5.5, 6.5, a0=-40, a1=130, n=20), fill=pal["hair_d"], outline=OUT, ow=0.7)
            fringe = ell_pts(cx - 1.5, cy - 6.5, 12.4, 8.0)
            poly(im, fringe, fill=pal["hair"], outline=OUT, ow=1.1)
            shade(im, fringe, pal["hair_d"][:3], pal["hair_l"][:3], dark_a=90, light_a=70)
            line(im, (cx - 11, cy - 6.8), (cx + 11.5, cy - 5.6), pal["accent"], 2.4)
        elif key == "nong_dan":
            ell(im, cx + 1, cy - 7.5, 22, 5.2, fill=pal["straw"], outline=OUT, ow=1.1, rot=-4)
            ell(im, cx - 1, cy - 10.5, 10.5, 6.4, fill=pal["straw_l"], outline=OUT, ow=1.0)
            line(im, (cx - 8, cy - 11), (cx + 12, cy - 12.5), pal["straw_d"], 0.8)
            line(im, (cx + 9, cy - 5), (cx + 10.5, cy + 9), pal["straw_d"], 0.9)  # dây quai nón
        else:
            dome = ell_pts(cx - 1, cy - 3.5, 13.2, 10.5)
            poly(im, dome, fill=STEEL, outline=OUT, ow=1.1)
            shade(im, dome, STEEL_D[:3], STEEL_HI[:3], dark_a=85, light_a=75)
            poly(im, [(cx - 13, cy - 9), (cx + 9, cy - 12.5), (cx + 11, cy - 8.5), (cx - 11, cy - 5.5)],
                 fill=pal["accent"], outline=OUT, ow=0.7)  # mào đỏ nằm dọc đỉnh
            poly(im, [(cx + 10.8, cy - 4), (cx + 13.4, cy - 3), (cx + 13.0, cy + 7), (cx + 10.6, cy + 7)],
                 fill=STEEL_D, outline=OUT, ow=0.7)  # tấm che mũi/gò má
        return
    # ---- down ----
    _face_down(im, cx, cy, pal)
    if key == "tho_ren":
        # râu quai nón ôm cằm
        poly(im, ell_pts(cx, cy + 7.5, 10.8, 8.2, a0=15, a1=165, n=24), fill=pal["hair_d"], outline=OUT, ow=0.8)
        line(im, (cx - 2.4, cy + 9.0), (cx + 2.4, cy + 9.0), (200, 130, 96, 255), 1.1)
        hair = ell_pts(cx, cy - 5.5, 13.4, 9.6)
        poly(im, hair, fill=pal["hair"], outline=OUT, ow=1.2)
        shade(im, hair, pal["hair_d"][:3], pal["hair_l"][:3], dark_a=95, light_a=75)
        for fx in (-9.0, -4.5, 0.0, 4.5, 9.0):
            poly(im, [(cx + fx - 2.3, cy - 6.0), (cx + fx + 2.0, cy - 6.4), (cx + fx + 0.2, cy + 0.5)], fill=pal["hair_d"])
        line(im, (cx - 12.2, cy - 6.6), (cx + 12.2, cy - 6.6), pal["accent"], 2.6)  # băng trán
        line(im, (cx - 12.2, cy - 8.0), (cx + 12.2, cy - 8.0), (216, 92, 84, 255), 0.9)
        poly(im, [(cx + 11.5, cy - 7.2), (cx + 15.5, cy - 4.5), (cx + 12.0, cy - 3.2)], fill=pal["accent"], outline=OUT, ow=0.6)  # nút thắt
    elif key == "nong_dan":
        # nón lá: chóp + vành rộng phủ trán, dây quai 2 bên má
        ell(im, cx, cy - 3.5, 23, 7.0, fill=pal["straw"], outline=OUT, ow=1.2)
        d = ImageDraw.Draw(im)
        for fx in (-18, -12, -6, 0, 6, 12, 18):
            d.line(P_([(cx + fx * 0.35, cy - 8.5), (cx + fx, cy - 3.2)]), fill=A(pal["straw_d"], 140), width=int(0.8 * SS))
        ell(im, cx, cy - 7.5, 11.5, 7.6, fill=pal["straw_l"], outline=OUT, ow=1.0)
        shade(im, ell_pts(cx, cy - 7.5, 11.5, 7.6), pal["straw_d"][:3], (252, 228, 168, 255)[:3], dark_a=60, light_a=60)
        ell(im, cx, cy - 11.5, 2.8, 2.2, fill=pal["straw_d"])
        line(im, (cx - 15.5, cy - 2.5), (cx - 10.5, cy + 11), pal["straw_d"], 0.9)
        line(im, (cx + 15.5, cy - 2.5), (cx + 10.5, cy + 11), pal["straw_d"], 0.9)
    else:
        # mũ giáp thép: vòm + vành + sống mũi + che gáy 2 bên
        dome = ell_pts(cx, cy - 4.5, 13.6, 10.8)
        poly(im, dome, fill=STEEL, outline=OUT, ow=1.2)
        shade(im, dome, STEEL_D[:3], STEEL_HI[:3], dark_a=90, light_a=80)
        line(im, (cx - 13.2, cy - 4.2), (cx + 13.2, cy - 4.2), STEEL_D, 1.8)
        poly(im, [(cx - 1.7, cy - 16.5), (cx + 1.7, cy - 16.5), (cx + 1.1, cy - 6), (cx - 1.1, cy - 6)],
             fill=pal["accent"], outline=OUT, ow=0.7)
        poly(im, [(cx - 1.6, cy - 3), (cx + 1.6, cy - 3), (cx + 1.2, cy + 6), (cx - 1.2, cy + 6)],
             fill=STEEL_L, outline=OUT, ow=0.6)  # sống mũi
        for sx in (-1, 1):
            poly(im, [(cx + sx * 12.8, cy - 2), (cx + sx * 10.4, cy - 2.4), (cx + sx * 10.8, cy + 8), (cx + sx * 13.2, cy + 6.5)],
                 fill=STEEL_D, outline=OUT, ow=0.8)

# ---------------- tay + công cụ ----------------

def draw_arm(im, shoulder, hand, sleeve, fore, hand_col=None):
    elbow = ((shoulder[0] + hand[0]) / 2 + 1.5, (shoulder[1] + hand[1]) / 2 + 2.5)
    dark = (fore[0] // 2 + 20, fore[1] // 2 + 16, fore[2] // 2 + 14, 255) if fore != SKIN else SKIN_D
    limb(im, shoulder, elbow, 6.0, sleeve, OUT, SKIN_L)
    limb(im, elbow, hand, 5.4, fore, dark, SKIN_L if fore == SKIN else STEEL_L)
    ell(im, hand[0], hand[1], 3.1, 3.1, fill=hand_col or SKIN, outline=OUT, ow=0.8)

def draw_hammer(im, grip, head_pos):
    gx, gy = grip; hx, hy = head_pos
    dx, dy = hx - gx, hy - gy
    L = max(math.hypot(dx, dy), 1.0); ux, uy = dx / L, dy / L
    px, py = -uy, ux
    line(im, (gx - ux * 3, gy - uy * 3), (hx, hy), WOOD_D, 3.6)
    line(im, (gx - ux * 3, gy - uy * 3), (hx, hy), WOOD, 2.5)
    hl, hw = 7.0, 3.6
    corners = [(hx + px * hl + ux * hw, hy + py * hl + uy * hw),
               (hx - px * hl + ux * hw, hy - py * hl + uy * hw),
               (hx - px * hl - ux * hw, hy - py * hl - uy * hw),
               (hx + px * hl - ux * hw, hy + py * hl - uy * hw)]
    poly(im, corners, fill=STEEL, outline=OUT, ow=1.0)
    shade(im, corners, STEEL_D[:3], STEEL_HI[:3], dark_a=90, light_a=70)
    line(im, (hx + px * (hl - 1), hy + py * (hl - 1)), (hx - px * (hl - 1), hy - py * (hl - 1)), STEEL_HI, 0.9)

def draw_hoe(im, grip_top, blade_pos, second_hand=True):
    tx, ty = grip_top; bx, by = blade_pos
    dx, dy = bx - tx, by - ty
    L = max(math.hypot(dx, dy), 1.0); ux, uy = dx / L, dy / L
    px, py = -uy, ux
    start = (tx - ux * 7, ty - uy * 7)
    line(im, start, (bx, by), WOOD_D, 3.6)
    line(im, start, (bx, by), WOOD, 2.5)
    blade = [(bx + px * 8 + ux * 1.5, by + py * 8 + uy * 1.5),
             (bx + px * 3.5 + ux * 7, by + py * 3.5 + uy * 7),
             (bx - px * 3.5 + ux * 7, by - py * 3.5 + uy * 7),
             (bx - px * 8 + ux * 1.5, by - py * 8 + uy * 1.5),
             (bx - ux * 1.5, by - uy * 1.5)]
    poly(im, blade, fill=STEEL, outline=OUT, ow=1.0)
    shade(im, blade, STEEL_D[:3], BLADE[:3], dark_a=85, light_a=65)
    poly(im, [(bx + px * 2.6, by + py * 2.6), (bx - px * 2.6, by - py * 2.6),
              (bx - px * 2.6 - ux * 3.4, by - py * 2.6 - uy * 3.4), (bx + px * 2.6 - ux * 3.4, by + py * 2.6 - uy * 3.4)],
         fill=STEEL_D, outline=OUT, ow=0.7)  # cổ nối cán

def draw_spear(im, x, top_y, bot_y, glint=False):
    line(im, (x, top_y), (x, bot_y), WOOD_D, 3.2)
    line(im, (x, top_y), (x, bot_y), WOOD, 2.2)
    tip = [(x, top_y - 11), (x - 3.4, top_y + 1), (x + 3.4, top_y + 1)]
    poly(im, tip, fill=BLADE, outline=OUT, ow=0.8)
    line(im, (x, top_y - 9), (x, top_y), STEEL_L, 0.8)
    ell(im, x, bot_y, 1.8, 1.8, fill=STEEL_D, outline=OUT, ow=0.5)
    if glint:
        line(im, (x - 4, top_y - 8), (x + 4, top_y - 8), (255, 255, 255, 220), 0.9)
        line(im, (x, top_y - 12), (x, top_y - 4), (255, 255, 255, 220), 0.9)

def draw_shield(im, cx, cy, rx=13.5, ry=16.5):
    pts = [(cx - rx, cy - ry), (cx + rx, cy - ry), (cx + rx, cy + ry * 0.25),
           (cx, cy + ry), (cx - rx, cy + ry * 0.25)]
    poly(im, pts, fill=STEEL, outline=OUT, ow=1.2)
    shade(im, pts, STEEL_D[:3], STEEL_HI[:3], dark_a=95, light_a=70)
    inner = [(cx + (x - cx) * 0.76, cy + (y - cy) * 0.8) for (x, y) in pts]
    poly(im, inner, fill=(52, 84, 128, 255), outline=GOLD, ow=1.0)
    shade(im, inner, (26, 44, 72, 255)[:3], (96, 132, 184, 255)[:3], dark_a=85, light_a=55)
    dia = [(cx, cy - 6.5), (cx + 4.6, cy), (cx, cy + 6.5), (cx - 4.6, cy)]
    poly(im, dia, fill=GOLD, outline=OUT, ow=0.7)
    ell(im, cx, cy, 1.5, 1.5, fill=GOLD_L)
    for (rx_, ry_) in ((-rx + 3, -ry + 3), (rx - 3, -ry + 3)):
        ell(im, cx + rx_, cy + ry_, 1.1, 1.1, fill=STEEL_HI, outline=OUT, ow=0.5)

# ---------------- pose thường (idle / walk) ----------------

def pose(key, direction, mode, i, n):
    pal = CHARS[key]
    im = new_canvas()
    t = i / max(n - 1, 1)
    phase = (i % 6) / 3.0
    bob = 0.0
    if mode == "idle":
        bob = [0.0, 0.9, 0.0][i % 3]
    elif mode == "walk":
        bob = abs(math.sin(phase * math.pi)) * -1.4
    sw = math.sin(phase * math.pi) * 3.5 if mode == "walk" else 0.0
    sleeve = pal["shirt"] if key != "linh_tuan" else STEEL
    fore = SKIN if key != "linh_tuan" else STEEL
    hand_col = SKIN if key != "linh_tuan" else LEATHER

    # Vẽ theo lớp: chân giữ nguyên ở mặt đất, thân/đầu/tay ở canvas riêng có bob
    legs_only = new_canvas()
    draw_legs(legs_only, direction, phase, mode, pal)
    upper = new_canvas()
    draw_torso(upper, key, direction, pal)

    if direction == "down":
        sh_r, sh_l = (79.5, 55), (48.5, 55)
        if key == "tho_ren":
            draw_arm(upper, sh_l, (45, 68 - sw), sleeve, fore)
            hand_r = (82, 68 + sw)
            draw_arm(upper, sh_r, hand_r, sleeve, fore)
            draw_hammer(upper, hand_r, (hand_r[0] + 10, hand_r[1] + 27))
        elif key == "nong_dan":
            draw_arm(upper, sh_l, (45, 68 - sw), sleeve, fore)
            hand_r = (81, 65 + sw)
            draw_hoe(upper, hand_r, (99, 105 + sw * 0.3))
            draw_arm(upper, sh_r, hand_r, sleeve, fore)
            ell(upper, 90, 84 + sw * 0.5, 2.9, 2.9, fill=SKIN, outline=OUT, ow=0.7)
        else:
            draw_shield(upper, 37, 71)
            draw_arm(upper, sh_l, (43, 66), sleeve, fore, hand_col)
            draw_spear(upper, 87, 17, 108, glint=(mode == "idle" and i == 2))
            draw_arm(upper, sh_r, (83, 63 - sw * 0.4), sleeve, fore, hand_col)
            ell(upper, 87, 60, 3.1, 3.4, fill=LEATHER, outline=OUT, ow=0.7)
    elif direction == "up":
        sh_r, sh_l = (79.5, 55), (48.5, 55)
        if key == "linh_tuan":
            draw_shield(upper, 64, 68, 15, 17.5)  # khiên đeo sau lưng
            draw_spear(upper, 88, 18, 107)
            draw_arm(upper, sh_r, (84, 63 - sw * 0.4), sleeve, fore, hand_col)
            draw_arm(upper, sh_l, (45, 68 - sw), sleeve, fore, hand_col)
        elif key == "tho_ren":
            draw_arm(upper, sh_l, (45, 68 - sw), sleeve, fore)
            hand_r = (82, 67 + sw)
            draw_arm(upper, sh_r, hand_r, sleeve, fore)
            draw_hammer(upper, hand_r, (hand_r[0] + 10, hand_r[1] + 27))
        else:
            draw_arm(upper, sh_l, (45, 68 - sw), sleeve, fore)
            hand_r = (81, 65 + sw)
            draw_hoe(upper, hand_r, (99, 104 + sw * 0.3))
            draw_arm(upper, sh_r, hand_r, sleeve, fore)
    else:  # side, hướng phải
        sh_f, sh_b = (72.0, 55), (57.0, 55)
        if key == "tho_ren":
            draw_arm(upper, sh_b, (52, 66 - sw * 0.5), sleeve, fore)
            hand_f = (77, 66 + sw)
            draw_arm(upper, sh_f, hand_f, sleeve, fore)
            draw_hammer(upper, hand_f, (hand_f[0] + 11, hand_f[1] + 28))
        elif key == "nong_dan":
            draw_arm(upper, sh_b, (52, 66 - sw * 0.5), sleeve, fore)
            hand_f = (78, 64 + sw)
            draw_hoe(upper, hand_f, (103, 105 + sw * 0.3))
            draw_arm(upper, sh_f, hand_f, sleeve, fore)
            ell(upper, 91, 83 + sw * 0.5, 2.9, 2.9, fill=SKIN, outline=OUT, ow=0.7)
        else:
            draw_arm(upper, sh_b, (54, 64), sleeve, fore, hand_col)
            draw_spear(upper, 93, 16, 108, glint=(mode == "idle" and i == 2))
            ell(upper, 93, 58, 3.1, 3.4, fill=LEATHER, outline=OUT, ow=0.7)
            draw_arm(upper, sh_f, (74, 68 + sw * 0.4), sleeve, fore, hand_col)
            draw_shield(upper, 76, 73, 11.5, 14.5)
    draw_head(upper, key, direction, pal)
    if bob != 0.0:
        shifted = new_canvas()
        shifted.alpha_composite(upper, dest=(0, int(bob * SS)))
        upper = shifted
    out = new_canvas()
    out.alpha_composite(legs_only)
    out.alpha_composite(upper)
    return out

# ---------------- pose work (chỉ hướng xuống) ----------------

def work_pose(key, i):
    pal = CHARS[key]
    im = new_canvas()
    draw_legs(im, "down", 0.0, "idle", pal, wide=True)
    if key == "tho_ren":
        lean = [-1.0, 3.0, 3.0, 0.0][i]
        dy = [0.0, 2.0, 2.0, 0.0][i]
        # đe rèn ở góc phải-dưới (chỉ trong anim work)
        anvil_top = [(90, 91), (117, 91), (114, 96), (93, 96)]
        poly(im, anvil_top, fill=STEEL_L, outline=OUT, ow=1.0)
        poly(im, [(96, 96), (111, 96), (108, 102), (99, 102)], fill=STEEL, outline=OUT, ow=0.9)
        poly(im, [(92, 102), (115, 102), (117, 107), (90, 107)], fill=STEEL_D, outline=OUT, ow=0.9)
        poly(im, [(117, 91.8), (124, 93.2), (117, 95.2)], fill=STEEL, outline=OUT, ow=0.8)  # sừng đe
        ell(im, 103.5, 93.2, 3.2, 1.1, fill=(255, 176, 84, 255))  # phôi sắt nung đỏ trên đe
        body = new_canvas()
        draw_torso(body, key, "down", pal, lean=lean)
        draw_arm(body, (48.5 + lean, 55), [(46, 72), (50, 80), (50, 80), (47, 74)][i], pal["shirt"], SKIN)
        hand_r = [(84, 28), (86, 60), (86, 64), (84, 42)][i]
        head_pos = [(98, 6), (100, 83), (100, 85), (97, 21)][i]
        draw_arm(body, (79.5 + lean, 55), hand_r, pal["shirt"], SKIN)
        draw_hammer(body, hand_r, head_pos)
        draw_head(body, key, "down", pal, dy=dy, lean=lean * 0.6)
        if dy != 0.0:
            shifted = new_canvas()
            shifted.alpha_composite(body, dest=(0, int(dy * SS)))
            body = shifted
        im.alpha_composite(body)
        if i in (1, 2):  # tia lửa lúc búa chạm phôi
            for (sx, sy, ln, ang) in ((100, 88, 5, -70), (105, 87, 4, -30), (97, 87, 3.6, -110), (103, 86, 3, -50)):
                a = math.radians(ang)
                line(im, (sx, sy), (sx + ln * math.cos(a), sy + ln * math.sin(a)), GOLD_L, 1.1)
            ell(im, 101, 89, 1.6, 1.2, fill=(255, 240, 190, 255))
        return im
    # nong_dan: cuốc đất
    lean = [-1.0, 3.0, 4.0, 1.0][i]
    dy = [0.0, 2.0, 2.5, 0.5][i]
    # mô đất trước mặt (chỉ trong anim work)
    ell(im, 97, 110.5, 15, 4.2, fill=(104, 76, 46, 255), outline=OUT, ow=0.8)
    dots(im, 97, 109.5, 12, 3.0, 9, (76, 54, 30, 255), 0.6, 1.3, seed=41 + i)
    dots(im, 97, 109.0, 11, 2.6, 5, (140, 106, 64, 255), 0.5, 1.0, seed=53 + i)
    body = new_canvas()
    draw_torso(body, key, "down", pal, lean=lean)
    grips = [(80, 26), (78, 50), (74, 58), (79, 42)][i]
    second = [(73, 41), (69, 61), (65, 67), (71, 53)][i]
    blades = [(104, 52), (102, 105), (86, 107), (100, 92)][i]
    draw_hoe(body, grips, blades)
    draw_arm(body, (48.5 + lean, 55), second, pal["shirt"], SKIN)
    draw_arm(body, (79.5 + lean, 55), grips, pal["shirt"], SKIN)
    ell(body, second[0], second[1], 2.9, 2.9, fill=SKIN, outline=OUT, ow=0.7)
    draw_head(body, key, "down", pal, dy=dy, lean=lean * 0.6)
    if dy != 0.0:
        shifted = new_canvas()
        shifted.alpha_composite(body, dest=(0, int(dy * SS)))
        body = shifted
    im.alpha_composite(body)
    if i == 1:  # đất văng lúc cuốc bổ xuống
        for (sx, sy) in ((96, 102), (103, 100), (108, 104)):
            ell(im, sx, sy, 1.3, 1.1, fill=(120, 90, 54, 255))
    return im

# ---------------- build sheets + tres (theo gen_sprites_v3) ----------------

BASE_ROWS = ["idle_down", "idle_up", "idle_side", "walk_down", "walk_up", "walk_side"]
ANIM_META = {"idle": (4.0, True), "walk": (10.0, True), "work": (6.0, True)}

def build_rows(key):
    rows = {}
    for ddir in ("down", "up", "side"):
        rows[f"idle_{ddir}"] = [pose(key, ddir, "idle", k, 3) for k in range(3)]
        rows[f"walk_{ddir}"] = [pose(key, ddir, "walk", k, 6) for k in range(6)]
    if key in ("tho_ren", "nong_dan"):
        rows["work"] = [work_pose(key, k) for k in range(4)]
    return rows

def compose_sheet(rows_data, row_order):
    cols = max(len(rows_data[r]) for r in row_order)
    sheet = Image.new("RGBA", (cols * FS, len(row_order) * FS), (0, 0, 0, 0))
    for ri, name in enumerate(row_order):
        for ci, fr512 in enumerate(rows_data[name]):
            sheet.alpha_composite(finish(fr512), dest=(ci * FS, ri * FS))
    return sheet

def write_tres(path, rows_data, row_order, sheet_res_path):
    atlas_lines = []; anim_chunks = []; aid = 0
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

def main():
    for key in ("tho_ren", "nong_dan", "linh_tuan"):
        rows_data = build_rows(key)
        row_order = BASE_ROWS + (["work"] if "work" in rows_data else [])
        sheet = compose_sheet(rows_data, row_order)
        sheet_path = os.path.join(OUT_DIR, f"{key}_spritesheet.png")
        sheet.save(sheet_path)
        n = write_tres(os.path.join(OUT_DIR, f"{key}_frames.tres"), rows_data, row_order,
                       f"res://assets/sprites/{key}_spritesheet.png")
        counts = {r: len(rows_data[r]) for r in row_order}
        print(f"{key}: sheet {sheet.size} -> {sheet_path}; atlas={n}; frames={counts}")

if __name__ == "__main__":
    main()
