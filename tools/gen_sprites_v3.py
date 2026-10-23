#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh spritesheet v3 cho game "Dưới Bóng Phong Ấn" — frame 128x128.

Kỹ thuật (khác hẳn v1/v2):
- Vẽ SUPERSAMPLE ở 512x512 (4x) bằng PIL với hình khối thật: polygon tham số
  (ellipse xoay, bezier), limb bằng đường dày có khớp tròn, shading nhiều lớp
  (base -> bóng đổ theo gradient -> highlight radial -> rim light), chi tiết
  nhỏ vẽ tay (tóc từng lọn, đinh tán, dây đai, khía pauldron, nanh goblin...).
- Mỗi nhân vật vẽ bằng MỘT hàm tham số hoá pose (góc tay/chân, bob, hướng)
  nên mọi frame nhất quán, chỉ pose thay đổi.
- Downscale về 128x128 bằng LANCZOS + unsharp nhẹ -> sprite HD top-down mượt.
- Chân (điểm chạm đất) cố định ở y=112 trong frame cho mọi animation đứng.
- Mỗi HÀNG sheet = 1 animation, frame từ cột 0. Hướng: down/up/side
  (side = nhìn phải, trái dùng flip_h trong Godot).

Chạy: python3 tools/gen_sprites_v3.py
"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageChops, ImageFilter

SS = 4                 # supersample
FS = 128               # frame size cuối
W = FS * SS            # 512 - canvas vẽ
GROUND = 112.0         # y chạm đất trong toạ độ frame 128

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "game", "assets", "sprites")
DESIGN_DIR = os.path.join(ROOT, "design")
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(DESIGN_DIR, exist_ok=True)

random.seed(20261023)

# ---------------- gradients dùng cho shading (tạo 1 lần ở 512) ----------------

def _grad_image(fn):
    small = Image.new("L", (FS, FS))
    px = small.load()
    for y in range(FS):
        for x in range(FS):
            px[x, y] = max(0, min(255, int(fn(x / FS, y / FS) * 255)))
    return small.resize((W, W), Image.BILINEAR)

GRAD_BOTTOM = _grad_image(lambda u, v: max(0.0, (v - 0.35) / 0.65) * 0.85)       # bóng ở đáy hình
GRAD_TOPLIGHT = _grad_image(lambda u, v: max(0.0, 1.0 - math.hypot(u - 0.32, v - 0.2) / 0.95))  # sáng từ trên-trái
GRAD_RIM = _grad_image(lambda u, v: max(0.0, (math.hypot(u - 0.5, v - 0.5) - 0.18) / 0.5))       # viền sáng mép phải/dưới

# ---------------- palette ----------------
OUT_P = (16, 22, 30, 255)      # outline player
OUT_G = (18, 26, 14, 255)      # outline goblin

STEEL_D = (58, 74, 92, 255); STEEL = (110, 134, 156, 255); STEEL_L = (168, 188, 208, 255); STEEL_HI = (228, 238, 248, 255)
GOLD = (198, 158, 44, 255); GOLD_L = (242, 208, 96, 255)
CLOAK_D = (26, 62, 58, 255); CLOAK = (44, 104, 97, 255); CLOAK_L = (84, 152, 140, 255); CLOAK_E = (128, 190, 174, 255)
LEATHER = (110, 74, 42, 255); LEATHER_D = (76, 48, 25, 255); LEATHER_L = (150, 106, 62, 255)
SKIN = (233, 186, 138, 255); SKIN_D = (203, 145, 94, 255); SKIN_L = (248, 216, 174, 255)
HAIR = (96, 64, 34, 255); HAIR_D = (62, 40, 18, 255); HAIR_L = (134, 94, 52, 255)
PANTS = (56, 64, 78, 255); PANTS_D = (36, 42, 54, 255)
BLADE = (224, 233, 240, 255); BLADE_D = (158, 176, 192, 255)
TEAL_GEM = (64, 220, 200, 255)

GSKIN_D = (66, 110, 40, 255); GSKIN = (105, 163, 66, 255); GSKIN_L = (146, 199, 100, 255); GBELLY = (178, 214, 138, 255)
GEAR_IN = (196, 150, 110, 255)
GEYE = (255, 216, 74, 255)
RAG = (122, 92, 52, 255); RAG_D = (88, 64, 34, 255); RAG_L = (158, 124, 78, 255); PATCH = (168, 140, 92, 255)
RUST = (186, 178, 164, 255); RUST_D = (138, 130, 116, 255); RUST_SPOT = (178, 106, 50, 255)
FANG = (244, 242, 232, 255); MOUTH = (38, 30, 20, 255)

# ---------------- helpers vẽ ở không gian 128 (tự nhân SS) ----------------

def A(col, a):
    """Đặt alpha cho một màu RGB(A)."""
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
    d.line([p0[0] * SS, p0[1] * SS, p1[0] * SS, p1[1] * SS], fill=fill, width=max(1, int(w * SS)), joint="curve")
    # đầu tròn
    r = w / 2.0
    ell(im, p0[0], p0[1], r, r, fill=fill)
    ell(im, p1[0], p1[1], r, r, fill=fill)

def limb(im, p0, p1, w, base, dark, light):
    """Tay/chân: viền tối -> lõi base -> sọc sáng lệch trên-trái."""
    line(im, p0, p1, dark, w + 1.6)
    line(im, p0, p1, base, w)
    off = (-w * 0.18, -w * 0.18)
    line(im, (p0[0] + off[0], p0[1] + off[1]), (p1[0] + off[0], p1[1] + off[1]), light, w * 0.34)

def bezier(p0, p1, p2, p3, n=24):
    pts = []
    for i in range(n + 1):
        t = i / n
        mt = 1 - t
        x = mt**3 * p0[0] + 3 * mt * mt * t * p1[0] + 3 * mt * t * t * p2[0] + t**3 * p3[0]
        y = mt**3 * p0[1] + 3 * mt * mt * t * p1[1] + 3 * mt * t * t * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts

def shade(im, pts, dark_rgb, light_rgb, rim_rgb=None, dark_a=95, light_a=80, rim_a=60):
    """Đổ bóng/highlight bị CLIP trong hình pts: bóng gradient đáy, sáng radial trên-trái, rim ở mép."""
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

# ============================================================ SWORD / SWOOSH

def draw_sword(im, grip, tip, back=False):
    """Kiếm: lưỡi 2 nửa sáng/tối + sống lưỡi, chặn vàng, cán quấn dây, núm tròn."""
    gx, gy = grip; tx, ty = tip
    dx, dy = tx - gx, ty - gy
    L = max(math.hypot(dx, dy), 1.0); ux, uy = dx / L, dy / L
    px, py = -uy, ux  # pháp tuyến
    hw = 2.6  # nửa bề rộng lưỡi ở gốc
    root = (gx + ux * 3.0, gy + uy * 3.0)
    left = [(root[0] + px * hw, root[1] + py * hw), (tx, ty),
            (root[0] - px * hw * 0.4, root[1] - py * hw * 0.4)]
    right = [(root[0] - px * hw, root[1] - py * hw), (tx, ty),
             (root[0] + px * hw * 0.4, root[1] + py * hw * 0.4)]
    if back:
        poly(im, left, fill=BLADE_D, outline=OUT_P, ow=0.8)
        poly(im, right, fill=STEEL_L, outline=OUT_P, ow=0.8)
    else:
        poly(im, right, fill=BLADE_D, outline=OUT_P, ow=0.8)
        poly(im, left, fill=BLADE, outline=OUT_P, ow=0.8)
    line(im, root, (tx - ux * 2, ty - uy * 2), STEEL_L, 0.7)  # sống lưỡi
    # chặn kiếm vàng vuông góc
    g0 = (gx + px * 4.6, gy + py * 4.6); g1 = (gx - px * 4.6, gy - py * 4.6)
    line(im, g0, g1, GOLD_D if False else GOLD, 2.6)
    line(im, g0, g1, GOLD_L, 0.8)
    # cán quấn dây: đoạn ngược hướng lưỡi + vạch chéo
    h1 = (gx - ux * 6.5, gy - uy * 6.5)
    line(im, (gx, gy), h1, LEATHER_D, 3.0)
    for t in (0.3, 0.55, 0.8):
        cx, cy = gx - ux * 6.5 * t, gy - uy * 6.5 * t
        line(im, (cx + px * 1.6, cy + py * 1.6), (cx - px * 1.6, cy - py * 1.6), LEATHER_L, 0.7)
    ell(im, h1[0], h1[1], 2.2, 2.2, fill=GOLD, outline=OUT_P, ow=0.7)

GOLD_D = (150, 116, 30, 255)

def draw_swoosh(im, cx, cy, r, a0, a1, alpha=170):
    """Vệt chém cong: 3 lượt arc giảm dần alpha/bề rộng + hạt sáng ở đầu cung."""
    d = ImageDraw.Draw(im)
    bbox = [(cx - r) * SS, (cy - r) * SS, (cx + r) * SS, (cy + r) * SS]
    for wdt, a in ((5.0, alpha // 3), (3.2, alpha * 2 // 3), (1.6, alpha)):
        d.arc(bbox, start=a0, end=a1, fill=(235, 250, 255, a), width=max(1, int(wdt * SS)))
    for t in (0.15, 0.5, 0.85):
        ang = math.radians(a0 + (a1 - a0) * t)
        x, y = cx + r * math.cos(ang), cy + r * math.sin(ang)
        ell(im, x, y, 1.3, 1.3, fill=(255, 255, 255, 150))

# ============================================================ PLAYER

def _player_cloak(im, direction, sway=0.0):
    """Choàng sau lưng: hình thang chảy xuống 2 bên thân, nếp gấp + viền."""
    if direction == "up":
        pts = [(50 + sway, 52), (78 + sway, 52), (84 + sway, 104), (76 + sway, 108),
               (66 + sway, 102), (58 + sway, 108), (46 + sway, 104)]
    else:
        pts = [(49 + sway, 52), (79 + sway, 52), (85 + sway, 100), (79 + sway, 106),
               (70 + sway, 99), (62 + sway, 105), (54 + sway, 99), (44 + sway, 105)]
    poly(im, pts, fill=CLOAK_D, outline=OUT_P, ow=1.2)
    inner = [(x + (64 - x) * 0.14, y - 1) for (x, y) in pts]
    poly(im, inner, fill=CLOAK)
    shade(im, pts, CLOAK_D[:3], CLOAK_L[:3], rim_rgb=CLOAK_E[:3], dark_a=110, light_a=60)
    d = ImageDraw.Draw(im)
    for fx in (0.3, 0.5, 0.7):  # nếp gấp dọc
        x0 = 46 + fx * 38 + sway
        pts_line = bezier((x0, 58), (x0 - 2, 76), (x0 + 2, 92), (x0 - 1, 102), n=16)
        d.line(P_(pts_line), fill=A(CLOAK_D, 170), width=int(1.1 * SS))
    # viền dưới sáng
    d.line(P_([pts[2], pts[3], pts[4], pts[5], pts[6]]), fill=A(CLOAK_E, 200), width=int(1.0 * SS))
    if direction == "side":
        pass

def _player_legs(im, direction, phase, mode):
    """Chân + bốt. phase: -1..1 bước trái, ngược cho phải. Trả về vị trí hông."""
    hip_y = 88.0
    if direction in ("down", "up"):
        hips = [(57.5, hip_y), (70.5, hip_y)]
        if mode == "walk":
            ph = math.sin(phase * math.pi)
            feet = [(57.5 + ph * 4.5, GROUND - max(0.0, math.cos(phase * math.pi)) * 2.5),
                    (70.5 - ph * 4.5, GROUND - max(0.0, -math.cos(phase * math.pi)) * 2.5)]
        elif mode == "attack":
            feet = [(53.0, GROUND), (75.0, GROUND - 1)]
        else:
            feet = [(56.5, GROUND), (71.5, GROUND)]
        for (hx, hy), (fx, fy) in zip(hips, feet):
            mid = ((hx + fx) / 2, (hy + fy) / 2 + 2)
            limb(im, (hx, hy), mid, 6.4, PANTS, PANTS_D, STEEL)
            limb(im, mid, (fx, fy - 5), 5.6, PANTS, PANTS_D, STEEL)
            # bốt da + mũi + đế
            ell(im, fx, fy - 3.4, 5.4, 3.8, fill=LEATHER, outline=OUT_P, ow=0.9)
            ell(im, fx + (1.5 if direction == "down" else -0.5), fy - 2.2, 3.4, 2.2, fill=LEATHER_L)
            line(im, (fx - 5, fy - 0.6), (fx + 5.4, fy - 0.6), LEATHER_D, 1.2)
    else:  # side: chân bước theo trục x
        hips = [(61.0, hip_y), (67.0, hip_y)]
        if mode == "walk":
            ph = math.sin(phase * math.pi)
            feet = [(61.0 + ph * 9.0, GROUND - max(0.0, math.cos(phase * math.pi)) * 3.0),
                    (67.0 - ph * 9.0, GROUND - max(0.0, -math.cos(phase * math.pi)) * 3.0)]
        elif mode == "attack":
            feet = [(50.0, GROUND), (80.0, GROUND)]
        else:
            feet = [(58.0, GROUND), (72.0, GROUND)]
        # chân xa tối hơn
        for idx in (1, 0):
            hx, hy = hips[idx]; fx, fy = feet[idx]
            base = PANTS_D if idx == 1 else PANTS
            mid = ((hx + fx) / 2, (hy + fy) / 2 + 2)
            limb(im, (hx, hy), mid, 6.2, base, PANTS_D, STEEL)
            limb(im, mid, (fx, fy - 5), 5.4, base, PANTS_D, STEEL)
            ell(im, fx + 1.5, fy - 3.4, 5.6, 3.8, fill=LEATHER if idx == 0 else LEATHER_D, outline=OUT_P, ow=0.9)
            ell(im, fx + 3.0, fy - 2.4, 3.2, 2.0, fill=LEATHER_L)
    return hips

def _player_torso(im, direction, lean=0.0):
    cx = 64.0 + lean
    if direction == "up":
        # lưng choàng phủ gần hết thân (đã vẽ ở cloak), chỉ thêm đai + vai giáp
        for sx in (-13.5, 13.5):
            pts = ell_pts(cx + sx, 56, 8.6, 7.0)
            poly(im, pts, fill=STEEL, outline=OUT_P, ow=1.1)
            shade(im, pts, STEEL_D[:3], STEEL_L[:3], dark_a=90, light_a=70)
        belt = [(cx - 13, 84), (cx + 13, 84), (cx + 12, 89.5), (cx - 12, 89.5)]
        poly(im, belt, fill=LEATHER_D, outline=OUT_P, ow=0.9)
        return
    # thân giáp: superellipse thuôn vai -> eo
    pts = ell_pts(cx, 68, 15.5, 17.5)
    pts = [(x, y) for (x, y) in pts if y < 86]
    pts += [(cx + 10.5, 88), (cx - 10.5, 88)]
    poly(im, pts, fill=STEEL, outline=OUT_P, ow=1.2)
    shade(im, pts, STEEL_D[:3], STEEL_HI[:3], rim_rgb=STEEL_L[:3], dark_a=105, light_a=85)
    d = ImageDraw.Draw(im)
    # sống ngực + khía ngang lá giáp
    line(im, (cx, 53), (cx, 82), STEEL_D, 1.0)
    for yy in (62, 71, 79):
        d.line(P_([(cx - 12.5, yy), (cx + 12.5, yy)]), fill=A(STEEL_D, 120), width=int(0.8 * SS))
    dots(im, cx, 66, 11, 13, 5, STEEL_HI, 0.5, 0.9, seed=11)  # xước sáng kim loại
    # dây đai chéo da + khóa vàng
    line(im, (cx - 12, 56), (cx + 11, 84), LEATHER_D, 5.2)
    line(im, (cx - 12, 56), (cx + 11, 84), LEATHER, 3.9)
    line(im, (cx - 11, 55), (cx + 10, 82), LEATHER_L, 0.9)
    bx, by = cx - 0.5, 69.5
    poly(im, [(bx - 3.4, by - 3.0), (bx + 3.4, by - 3.0), (bx + 3.4, by + 3.0), (bx - 3.4, by + 3.0)],
         fill=GOLD, outline=OUT_P, ow=0.9)
    ell(im, bx, by, 1.3, 1.3, fill=GOLD_L)
    # pauldron 2 vai: 2 lá chồng + rãnh + đinh tán
    for sx in (-15.0, 15.0):
        cxp = cx + sx
        for k, (dy, rr) in enumerate(((0, 8.8), (4.6, 7.6))):
            pts2 = ell_pts(cxp, 55 + dy, rr, rr * 0.72)
            poly(im, pts2, fill=STEEL_L if k == 0 else STEEL, outline=OUT_P, ow=1.0)
            shade(im, pts2, STEEL_D[:3], STEEL_HI[:3], dark_a=80, light_a=75)
        ell(im, cxp - 2.5, 53.5, 1.1, 1.1, fill=STEEL_HI, outline=OUT_P, ow=0.5)
        ell(im, cxp + 2.8, 54.5, 1.0, 1.0, fill=STEEL_HI, outline=OUT_P, ow=0.5)
    # đai lưng + váy giáp 3 lá (faulds)
    belt = [(cx - 12.5, 84), (cx + 12.5, 84), (cx + 12, 89), (cx - 12, 89)]
    poly(im, belt, fill=LEATHER_D, outline=OUT_P, ow=0.9)
    ell(im, cx, 86.5, 2.4, 1.9, fill=GOLD, outline=OUT_P, ow=0.7)
    for k, fx in enumerate((-8.0, 0.0, 8.0)):
        fp = [(cx + fx - 4.6, 89), (cx + fx + 4.6, 89), (cx + fx + 3.6, 95), (cx + fx - 3.6, 95)]
        poly(im, fp, fill=STEEL if k != 1 else STEEL_L, outline=OUT_P, ow=0.8)

def _player_head(im, direction, dy=0.0, tilt=0.0):
    cx, cy = 64.0 + tilt, 36.0 + dy
    if direction == "up":
        # sau đầu: tóc phủ kín + lọn xoáy + vòng trán thấy ở mép dưới
        pts = ell_pts(cx, cy, 13.5, 14.0)
        poly(im, pts, fill=HAIR, outline=OUT_P, ow=1.2)
        shade(im, pts, HAIR_D[:3], HAIR_L[:3], dark_a=100, light_a=70)
        d = ImageDraw.Draw(im)
        for (ox, oy, rr) in ((-2.0, 1.0, 7.5), (1.5, 2.5, 10.5)):  # 2 lọn tóc cong lệch tâm, alpha thấp — tránh giống bia tròn
            arc = ell_pts(cx + ox, cy + oy, rr, rr * 0.92, a0=30, a1=150, n=20)
            d.line(P_(arc), fill=A(HAIR_D, 95), width=int(1.1 * SS))
        ell(im, cx, cy - 4, 3.2, 2.6, fill=HAIR_L)  # xoáy tóc
        line(im, (cx - 11, cy + 9.5), (cx + 11, cy + 9.5), STEEL_L, 1.6)  # vòng trán phía sau
        return
    if direction == "side":
        # tóc sau đầu
        pts = ell_pts(cx - 2.5, cy, 13.0, 14.0)
        poly(im, pts, fill=HAIR, outline=OUT_P, ow=1.2)
        shade(im, pts, HAIR_D[:3], HAIR_L[:3], dark_a=95, light_a=65)
        # mặt profile
        face = ell_pts(cx + 2.5, cy + 1.5, 11.0, 12.6)
        poly(im, face, fill=SKIN, outline=OUT_P, ow=1.1)
        shade(im, face, SKIN_D[:3], SKIN_L[:3], dark_a=70, light_a=55)
        poly(im, [(cx + 12.4, cy + 1), (cx + 15.2, cy + 3.6), (cx + 12.2, cy + 5.2)], fill=SKIN_D, outline=OUT_P, ow=0.7)  # mũi
        ell(im, cx + 7.6, cy + 0.5, 2.5, 3.1, fill=(255, 255, 255, 255), outline=OUT_P, ow=0.6)  # mắt
        ell(im, cx + 8.4, cy + 0.7, 1.25, 1.9, fill=(40, 30, 22, 255))
        ell(im, cx + 8.9, cy - 0.1, 0.55, 0.55, fill=(255, 255, 255, 255))
        line(im, (cx + 4.6, cy - 3.4), (cx + 10.6, cy - 2.8), HAIR_D, 1.3)  # mày
        line(im, (cx + 8.6, cy + 8.6), (cx + 11.6, cy + 8.2), SKIN_D, 1.0)  # miệng
        ell(im, cx + 6.0, cy + 6.0, 2.6, 1.7, fill=(240, 160, 120, 90))     # má
        # mái tóc phủ trán + lọn bên
        fringe = ell_pts(cx - 1.5, cy - 6.5, 12.4, 8.0)
        poly(im, fringe, fill=HAIR, outline=OUT_P, ow=1.1)
        shade(im, fringe, HAIR_D[:3], HAIR_L[:3], dark_a=90, light_a=70)
        for k, fx in enumerate((2.0, 6.5, 10.5)):
            poly(im, [(cx + fx - 2.4, cy - 4.5), (cx + fx + 1.6, cy - 4.8), (cx + fx - 0.4, cy + 1.8)], fill=HAIR_D)
        poly(im, [(cx - 13.5, cy - 4), (cx - 9.5, cy - 5), (cx - 10.5, cy + 8), (cx - 13.8, cy + 6)], fill=HAIR_D, outline=OUT_P, ow=0.8)  # lọn sau tai
        # vòng trán thép + ngọc
        line(im, (cx - 10.5, cy - 7.8), (cx + 11.5, cy - 6.4), STEEL_L, 2.2)
        line(im, (cx - 10.5, cy - 8.6), (cx + 11.5, cy - 7.2), STEEL_HI, 0.8)
        poly(im, [(cx + 9.8, cy - 9.4), (cx + 12.2, cy - 7.0), (cx + 9.8, cy - 4.8), (cx + 7.4, cy - 7.0)], fill=TEAL_GEM, outline=OUT_P, ow=0.6)
        return
    # ---- down: mặt chính diện ----
    pts = ell_pts(cx, cy + 1.5, 12.2, 13.2)
    poly(im, pts, fill=SKIN, outline=OUT_P, ow=1.2)
    shade(im, pts, SKIN_D[:3], SKIN_L[:3], dark_a=75, light_a=60)
    d = ImageDraw.Draw(im)
    for ex in (-5.6, 5.6):  # mắt: tròng trắng + mống + điểm sáng + mí
        ell(im, cx + ex, cy + 1.2, 2.7, 3.3, fill=(255, 255, 255, 255), outline=OUT_P, ow=0.6)
        ell(im, cx + ex, cy + 1.6, 1.4, 2.1, fill=(52, 38, 26, 255))
        ell(im, cx + ex + 0.5, cy + 0.6, 0.6, 0.6, fill=(255, 255, 255, 255))
        line(im, (cx + ex - 3.1, cy - 3.2), (cx + ex + 3.1, cy - 2.6), HAIR_D, 1.4)  # mày
    line(im, (cx + 0.4, cy + 4.4), (cx - 0.5, cy + 6.6), SKIN_D, 1.0)   # mũi
    line(im, (cx - 2.6, cy + 9.3), (cx + 2.6, cy + 9.3), (178, 108, 78, 255), 1.2)  # miệng
    ell(im, cx - 8.6, cy + 6.4, 2.8, 1.8, fill=(240, 160, 120, 80))     # má
    ell(im, cx + 8.6, cy + 6.4, 2.8, 1.8, fill=(240, 160, 120, 80))
    ell(im, cx, cy + 12.2, 5.5, 2.2, fill=SKIN_D)                        # bóng cằm
    # tóc: khối phủ trên + lọn mái từng chiếc + 2 lọn bên má
    hair = ell_pts(cx, cy - 5.5, 13.4, 9.6)
    poly(im, hair, fill=HAIR, outline=OUT_P, ow=1.2)
    shade(im, hair, HAIR_D[:3], HAIR_L[:3], dark_a=95, light_a=75)
    for k, fx in enumerate((-10.5, -6.0, -1.5, 3.0, 7.5, 11.0)):
        ln = 6.5 + (2.0 if k % 2 else 0.0)
        poly(im, [(cx + fx - 2.5, cy - 6.0), (cx + fx + 2.2, cy - 6.4), (cx + fx + 0.2, cy - 6.0 + ln)], fill=HAIR_D if k % 2 else HAIR)
        line(im, (cx + fx, cy - 7.5), (cx + fx + 0.2, cy - 6.0 + ln - 1.5), HAIR_L, 0.8)
    for sx in (-1, 1):
        poly(im, [(cx + sx * 12.6, cy - 3), (cx + sx * 10.2, cy - 3.6), (cx + sx * 10.8, cy + 7.5), (cx + sx * 13.0, cy + 6.0)], fill=HAIR_D, outline=OUT_P, ow=0.8)
    # vòng trán thép + ngọc teal ở giữa
    line(im, (cx - 11.6, cy - 6.9), (cx + 11.6, cy - 6.9), STEEL_L, 2.3)
    line(im, (cx - 11.6, cy - 7.8), (cx + 11.6, cy - 7.8), STEEL_HI, 0.9)
    poly(im, [(cx, cy - 10.3), (cx + 2.6, cy - 7.4), (cx, cy - 4.6), (cx - 2.6, cy - 7.4)], fill=TEAL_GEM, outline=OUT_P, ow=0.7)
    ell(im, cx - 0.7, cy - 8.2, 0.8, 1.1, fill=(220, 255, 248, 220))

def _player_arm(im, shoulder, hand, sword_tip=None, sword_back=False):
    """Tay giáp: ống tay thép -> găng da -> (kiếm)."""
    elbow = ((shoulder[0] + hand[0]) / 2 + 1.5, (shoulder[1] + hand[1]) / 2 + 2.5)
    limb(im, shoulder, elbow, 6.0, STEEL, STEEL_D, STEEL_L)
    limb(im, elbow, hand, 5.2, STEEL_D, OUT_P, STEEL)
    ell(im, hand[0], hand[1], 3.1, 3.1, fill=LEATHER, outline=OUT_P, ow=0.8)
    if sword_tip is not None:
        draw_sword(im, hand, sword_tip, back=sword_back)

def player_pose(direction, mode, i, n):
    """Vẽ 1 frame player ở canvas 512. mode: idle/walk/attack/dodge/hurt."""
    im = new_canvas()
    t = i / max(n - 1, 1)
    phase = (i % 6) / 3.0  # pha bước cho walk 6 frame (i chạy 0..5)
    bob = 0.0
    if mode == "idle":
        bob = [0.0, 0.9, 0.0][i % 3]
    elif mode == "walk":
        bob = abs(math.sin(phase * math.pi)) * -1.4
    lean = 1.5 if (mode == "attack" and i >= 2) else 0.0
    by = bob + (2.5 if mode == "attack" and i == 3 else 0.0)  # thân hạ sau chém

    hips = _player_legs(im, direction, phase, mode)
    _player_cloak(im, direction, sway=(1.5 if mode == "walk" else 0.0))
    # dịch thân trên theo bob: vẽ torso/head ở toạ độ +by qua ảnh tạm
    body = new_canvas()
    _player_torso(body, direction, lean=lean)
    # ---- tay + kiếm theo pose ----
    if direction == "down":
        sh_r, sh_l = (79.5, 55 + 0), (48.5, 55)
        if mode == "attack":
            hands = [(84, 34), (88, 44), (86, 66), (78, 76)]
            tips = [(106, 14), (112, 40), (104, 84), (88, 96)]
            _player_arm(body, sh_r, hands[i], tips[i])
            if i == 2:
                draw_swoosh(body, 66, 58, 44, -50, 105)
            elif i == 3:
                draw_swoosh(body, 66, 58, 40, 20, 100, alpha=70)
            _player_arm(body, sh_l, (44, 68), None)
        elif mode == "walk":
            sw = math.sin(phase * math.pi) * 3.5
            _player_arm(body, sh_r, (82, 68 + sw), (94, 101 + sw))
            _player_arm(body, sh_l, (45, 68 - sw), None)
        else:
            _player_arm(body, sh_r, (82, 68), (95, 103))
            _player_arm(body, sh_l, (45, 68), None)
    elif direction == "up":
        sh_r, sh_l = (79.5, 55), (48.5, 55)
        if mode == "attack":
            hands = [(85, 36), (89, 48), (87, 68), (79, 77)]
            tips = [(104, 16), (110, 46), (102, 86), (86, 96)]
            _player_arm(body, sh_r, hands[i], tips[i], sword_back=True)
            if i == 2:
                draw_swoosh(body, 64, 56, 43, -60, 100)
            _player_arm(body, sh_l, (43, 66), None)
        elif mode == "walk":
            sw = math.sin(phase * math.pi) * 3.5
            _player_arm(body, sh_r, (82, 67 + sw), (94, 100 + sw), sword_back=True)
            _player_arm(body, sh_l, (45, 67 - sw), None)
        else:
            _player_arm(body, sh_r, (82, 67), (95, 102), sword_back=True)
            _player_arm(body, sh_l, (45, 67), None)
    else:  # side, mặt hướng phải
        sh_f, sh_b = (72.0, 55), (57.0, 55)
        if mode == "attack":
            hands = [(66, 32), (58, 42), (84, 62), (80, 76)]
            tips = [(52, 8), (40, 34), (112, 78), (98, 98)]
            _player_arm(body, sh_b, (52, 66), None)
            _player_arm(body, sh_f, hands[i], tips[i])
            if i == 2:
                draw_swoosh(body, 70, 56, 40, -80, 55)
            elif i == 3:
                draw_swoosh(body, 70, 56, 37, -15, 50, alpha=70)
        elif mode == "walk":
            sw = math.sin(phase * math.pi) * 4.0
            _player_arm(body, sh_b, (52, 66 - sw * 0.5), None)
            _player_arm(body, sh_f, (76, 66 + sw), (90, 99 + sw))
        else:
            _player_arm(body, sh_b, (52, 66), None)
            _player_arm(body, sh_f, (76, 66), (91, 101))
    _player_head(body, direction, dy=0.0, tilt=(lean * 0.6))
    if by != 0.0:
        shifted = new_canvas()
        shifted.alpha_composite(body, dest=(0, int(by * SS)))
        body = shifted
    im.alpha_composite(body)
    return im

def player_hurt_frame(i):
    im = player_pose("down", "idle", 0, 3)
    # đầu ngửa sang trái: vá da + mắt X + miệng há (vẽ ở 512 rồi hạ — vẽ đè ở 128-space)
    d = ImageDraw.Draw(im)
    for ex in (58.4, 69.6):
        ell(im, ex, 37.2, 2.9, 3.5, fill=SKIN)
        line(im, (ex - 2.2, 34.6), (ex + 2.2, 39.8), OUT_P, 1.3)
        line(im, (ex - 2.2, 39.8), (ex + 2.2, 34.6), OUT_P, 1.3)
    ell(im, 64, 45.8, 2.6, 3.2, fill=MOUTH, outline=OUT_P, ow=0.7)
    shifted = new_canvas()
    shifted.alpha_composite(im, dest=(int(-2.5 * SS), 0))
    im = shifted
    if i == 1:
        a = im.split()[3]
        red = Image.new("RGBA", (W, W), (255, 64, 44, 0))
        red.putalpha(a.point(lambda v: int(v * 0.38)))
        im.alpha_composite(red)
    return im

def _fit(frame512, bottom=119.0, cx=64.0):
    """Dịch hình sao cho bbox alpha nằm gọn trong frame: đáy chạm bottom, tâm x = cx."""
    bbox = frame512.split()[3].getbbox()
    if bbox is None:
        return frame512
    dx = int(cx * SS - (bbox[0] + bbox[2]) / 2.0)
    dy = int(bottom * SS - bbox[3])
    out = new_canvas()
    out.alpha_composite(frame512, dest=(dx, dy))
    return out

def _rot(frame512, deg, dy=0.0, alpha=1.0, fit_bottom=None):
    out = frame512.rotate(deg, resample=Image.BICUBIC, center=(W // 2, int(GROUND * SS)))
    if dy:
        s = new_canvas(); s.alpha_composite(out, dest=(0, int(dy * SS))); out = s
    if fit_bottom is not None:
        out = _fit(out, bottom=fit_bottom)
    if alpha < 1.0:
        a = out.split()[3].point(lambda v: int(v * alpha))
        out.putalpha(a)
    return out

def player_dodge_frame(direction, i):
    base = player_pose(direction, "idle", 0, 3)
    if i == 0:  # cúi thấp + vệt tốc độ
        sq = base.resize((W, int(W * 0.8)), Image.BICUBIC)
        out = new_canvas(); out.alpha_composite(sq, dest=(0, W - sq.height))
        for k, yy in enumerate((86, 94, 102)):
            line(out, (16 - k * 3, yy), (34 - k * 3, yy), (200, 240, 255, 130), 1.6)
        return out
    if i == 1:
        return _rot(base, -52, dy=2, fit_bottom=117)
    return _rot(base, -118, dy=4, fit_bottom=118)

def player_death_frame(i):
    if i == 0:  # gục: đầu cúi, người sụp (idle dịch xuống + mắt X)
        im = player_pose("down", "idle", 0, 3)
        s = new_canvas(); s.alpha_composite(im, dest=(0, int(3.5 * SS))); im = s
        for ex in (58.4, 69.6):
            ell(im, ex, 40.7, 2.9, 3.5, fill=SKIN)
            line(im, (ex - 2.2, 38.1), (ex + 2.2, 43.3), OUT_P, 1.3)
            line(im, (ex - 2.2, 43.3), (ex + 2.2, 38.1), OUT_P, 1.3)
        return im
    base = player_pose("down", "idle", 0, 3)
    lying = _rot(base, -82, dy=6, fit_bottom=120)
    return lying if i == 1 else _rot(base, -82, dy=6, alpha=0.45, fit_bottom=120)

# ============================================================ GOBLIN

def _goblin_ear(im, side_sign, back=False):
    """Tai dài cong: bezier từ đầu vươn ra ngoài, đầu tai cụp xuống; có tai trong."""
    root_top = (64 + side_sign * 13, 27)
    root_bot = (64 + side_sign * 14.5, 40)
    tip = (64 + side_sign * 37, 20 if not back else 23)
    upper = bezier(root_top, (64 + side_sign * 26, 18), (64 + side_sign * 34, 15), tip)
    lower = bezier(tip, (64 + side_sign * 30, 27), (64 + side_sign * 24, 34), root_bot)
    pts = upper + lower[1:]
    poly(im, pts, fill=GSKIN_D if back else GSKIN, outline=OUT_G, ow=1.1)
    shade(im, pts, GSKIN_D[:3], GSKIN_L[:3], dark_a=85, light_a=55)
    iu = bezier((64 + side_sign * 17, 29), (64 + side_sign * 25, 23), (64 + side_sign * 30, 21), (64 + side_sign * 33, 22.5))
    il = bezier((64 + side_sign * 33, 22.5), (64 + side_sign * 27, 28), (64 + side_sign * 22, 31), (64 + side_sign * 17.5, 33))
    poly(im, iu + il[1:], fill=GEAR_IN)

def _goblin_legs(im, direction, phase, mode):
    hip_y = 94.0
    if direction in ("down", "up"):
        hips = [(58.5, hip_y), (69.5, hip_y)]
        if mode == "walk":
            ph = math.sin(phase * math.pi)
            feet = [(58.5 + ph * 4.0, GROUND - max(0.0, math.cos(phase * math.pi)) * 2.2),
                    (69.5 - ph * 4.0, GROUND - max(0.0, -math.cos(phase * math.pi)) * 2.2)]
        else:
            feet = [(57.5, GROUND), (70.5, GROUND)]
        for (hx, hy), (fx, fy) in zip(hips, feet):
            limb(im, (hx, hy), (fx, fy - 4), 6.3, GSKIN_D, OUT_G, GSKIN)
            # bàn chân to + 3 ngón có móng
            ell(im, fx, fy - 2.6, 5.6, 3.4, fill=GSKIN, outline=OUT_G, ow=0.9)
            for tx in (-3.6, 0.0, 3.6):
                poly(im, [(fx + tx - 1.1, fy - 1.2), (fx + tx + 1.1, fy - 1.2), (fx + tx, fy + 1.6)], fill=FANG, outline=OUT_G, ow=0.5)
    else:
        hips = [(61.0, hip_y), (67.0, hip_y)]
        if mode == "walk":
            ph = math.sin(phase * math.pi)
            feet = [(61.0 + ph * 8.0, GROUND - max(0.0, math.cos(phase * math.pi)) * 2.6),
                    (67.0 - ph * 8.0, GROUND - max(0.0, -math.cos(phase * math.pi)) * 2.6)]
        else:
            feet = [(58.0, GROUND), (72.0, GROUND)]
        for idx in (1, 0):
            hx, hy = hips[idx]; fx, fy = feet[idx]
            limb(im, (hx, hy), (fx, fy - 4), 5.4, GSKIN_D if idx == 1 else GSKIN, OUT_G, GSKIN_L)
            ell(im, fx + 1.5, fy - 2.6, 5.8, 3.4, fill=GSKIN if idx == 0 else GSKIN_D, outline=OUT_G, ow=0.9)
            for tx in (2.2, 5.2):
                poly(im, [(fx + tx - 1.0, fy - 1.4), (fx + tx + 1.2, fy - 1.2), (fx + tx + 0.4, fy + 1.6)], fill=FANG, outline=OUT_G, ow=0.5)

def _goblin_torso(im, direction):
    if direction == "up":
        pts = ell_pts(64, 74, 14.5, 19.5)
        poly(im, pts, fill=GSKIN_D, outline=OUT_G, ow=1.2)
        shade(im, pts, (40, 74, 24), GSKIN[:3], dark_a=100, light_a=55)
        dots(im, 64, 72, 10, 15, 9, (52, 92, 32, 160), 0.8, 1.8, seed=21)
        # vải rách phủ lưng
        rag = [(53, 60), (75, 60), (77, 88), (71, 84), (66, 90), (60, 84), (52, 89)]
        poly(im, rag, fill=RAG_D, outline=OUT_G, ow=1.0)
        return
    # thân phệ: bụng sáng lớn + ngực
    pts = ell_pts(64, 73, 15.0, 20.0)
    poly(im, pts, fill=GSKIN, outline=OUT_G, ow=1.2)
    shade(im, pts, GSKIN_D[:3], GSKIN_L[:3], dark_a=95, light_a=70)
    belly = ell_pts(64, 80, 10.6, 12.6)
    poly(im, belly, fill=GBELLY)
    shade(im, belly, GSKIN[:3], (214, 240, 182), dark_a=55, light_a=60)
    ell(im, 64, 84, 1.4, 1.1, fill=GSKIN_D)  # rốn
    dots(im, 64, 70, 12, 16, 10, GSKIN_D, 0.7, 1.7, seed=5)   # đốm da
    dots(im, 64, 66, 11, 14, 5, GSKIN_L, 0.6, 1.2, seed=9)
    # sẹo ngực
    line(im, (55, 60), (61, 66), (226, 240, 200, 200), 1.1)
    line(im, (57, 59), (58.5, 62), GSKIN_D, 0.8)
    # áo/khố vải rách: từ vai trái chéo xuống + vá khâu chỉ
    rag = [(51, 56), (65, 52), (68, 66), (71, 93), (66, 87), (62, 95), (58, 86), (53, 93), (50, 70)]
    poly(im, rag, fill=RAG, outline=OUT_G, ow=1.1)
    shade(im, rag, RAG_D[:3], RAG_L[:3], dark_a=95, light_a=60)
    patch = [(56, 72), (64, 71), (64.5, 79), (56.5, 80)]
    poly(im, patch, fill=PATCH, outline=RAG_D, ow=0.7)
    d = ImageDraw.Draw(im)
    for t in range(4):  # chỉ khâu vá
        x = 56.5 + t * 2.1
        d.line(P_([(x, 71.2), (x + 1.0, 73.2)]), fill=(240, 230, 200, 220), width=int(0.7 * SS))
    for yy in (60, 68, 78):  # sọc vải ngang mờ
        d.line(P_([(52, yy), (72, yy - 2)]), fill=A(RAG_D, 70), width=int(0.8 * SS))
    # dây thừng thắt lưng
    line(im, (50, 92), (78, 92), LEATHER_D, 3.0)
    line(im, (50, 91), (78, 91), LEATHER_L, 1.0)
    ell(im, 71, 93.5, 2.6, 2.2, fill=LEATHER_D, outline=OUT_G, ow=0.7)  # nút thắt

def _goblin_head(im, direction, dy=0.0):
    cx, cy = 64.0, 38.0 + dy
    if direction == "up":
        _goblin_ear(im, -1, back=True); _goblin_ear(im, 1, back=True)
        pts = ell_pts(cx, cy, 15.5, 15.0)
        poly(im, pts, fill=GSKIN_D, outline=OUT_G, ow=1.2)
        shade(im, pts, (40, 74, 24), GSKIN[:3], dark_a=100, light_a=55)
        dots(im, cx - 8, cy - 9, 4, 3, 3, (52, 92, 32, 120), 0.7, 1.2, seed=31)  # đốm ít, lệch góc — tránh giống mắt/mặt
        # chỏm tóc thưa 3 sợi
        for a in (-24, 0, 24):
            ar = math.radians(a - 90)
            line(im, (cx, cy - 13), (cx + 7 * math.cos(ar), cy - 13 + 8 * math.sin(ar)), OUT_G, 1.1)
        return
    if direction == "side":
        _goblin_ear(im, -1)  # tai phía sau vươn về -x (hàm vẽ quanh cx=64, tai trái = sau đầu)
        pts = ell_pts(cx + 1, cy, 14.6, 14.4)
        poly(im, pts, fill=GSKIN, outline=OUT_G, ow=1.2)
        shade(im, pts, GSKIN_D[:3], GSKIN_L[:3], dark_a=90, light_a=65)
        # mõm nhô
        poly(im, [(cx + 11, cy + 3), (cx + 17.5, cy + 5.5), (cx + 16.5, cy + 9.5), (cx + 10.5, cy + 9.8)], fill=GSKIN, outline=OUT_G, ow=0.9)
        ell(im, cx + 16.8, cy + 5.2, 1.5, 1.3, fill=GSKIN_D)  # mũi
        ell(im, cx + 6.5, cy - 0.5, 3.1, 3.7, fill=GEYE, outline=OUT_G, ow=0.7)  # mắt
        ell(im, cx + 7.6, cy - 0.3, 0.85, 2.2, fill=OUT_G)
        ell(im, cx + 7.9, cy - 1.6, 0.5, 0.5, fill=(255, 255, 255, 255))
        line(im, (cx + 2.2, cy - 5.6), (cx + 10.8, cy - 3.8), GSKIN_D, 1.8)  # mày xếch
        mouth = [(cx + 6, cy + 10.6), (cx + 15.5, cy + 9.6), (cx + 15.0, cy + 12.6), (cx + 7.0, cy + 13.2)]
        poly(im, mouth, fill=MOUTH, outline=OUT_G, ow=0.7)
        for fx in (8.6, 12.4):  # nanh
            poly(im, [(cx + fx - 5.6, cy + 10.2), (cx + fx - 3.6, cy + 10.0), (cx + fx - 4.6, cy + 13.4)], fill=FANG)
        dots(im, cx - 4, cy + 4, 8, 9, 5, GSKIN_D, 0.7, 1.4, seed=41)
        return
    # ---- down ----
    _goblin_ear(im, -1); _goblin_ear(im, 1)
    pts = ell_pts(cx, cy, 15.8, 15.2)
    poly(im, pts, fill=GSKIN, outline=OUT_G, ow=1.2)
    shade(im, pts, GSKIN_D[:3], GSKIN_L[:3], dark_a=92, light_a=68)
    ell(im, cx, cy + 6.5, 11.5, 8.6, fill=GSKIN_L)          # mõm sáng
    ell(im, cx - 4.6, cy + 4.6, 1.7, 1.2, fill=GSKIN_D)      # lỗ mũi
    ell(im, cx + 4.6, cy + 4.6, 1.7, 1.2, fill=GSKIN_D)
    line(im, (cx - 11.5, cy - 6.8), (cx - 2.5, cy - 4.4), GSKIN_D, 2.0)  # gờ mày trái
    line(im, (cx + 11.5, cy - 6.8), (cx + 2.5, cy - 4.4), GSKIN_D, 2.0)   # gờ mày phải
    for ex in (-6.8, 6.8):  # mắt vàng + tròng dọc + điểm sáng
        ell(im, cx + ex, cy - 1.2, 3.5, 4.1, fill=GEYE, outline=OUT_G, ow=0.7)
        ell(im, cx + ex, cy - 1.0, 1.0, 2.6, fill=OUT_G)
        ell(im, cx + ex + 0.6, cy - 2.6, 0.55, 0.55, fill=(255, 255, 255, 255))
    line(im, (cx + 8.5, cy - 10.5), (cx + 12.5, cy - 6.0), (226, 240, 200, 210), 1.1)  # sẹo trán
    mouth = [(cx - 8.0, cy + 9.6), (cx + 8.0, cy + 9.6), (cx + 6.4, cy + 13.4), (cx - 6.4, cy + 13.4)]
    poly(im, mouth, fill=MOUTH, outline=OUT_G, ow=0.8)
    for fx in (-6.2, -2.2, 3.4):  # nanh trên chĩa xuống
        poly(im, [(cx + fx, cy + 9.8), (cx + fx + 2.3, cy + 9.8), (cx + fx + 1.1, cy + 13.2)], fill=FANG)
    poly(im, [(cx + 5.8, cy + 13.2), (cx + 8.0, cy + 13.2), (cx + 6.9, cy + 10.6)], fill=FANG)  # nanh dưới chĩa lên
    ell(im, cx - 11.6, cy + 5.5, 2.2, 1.6, fill=(120, 90, 40, 130))  # nốt ruồi/mụn
    dots(im, cx, cy - 6, 12, 8, 6, GSKIN_D, 0.7, 1.4, seed=17)

def _goblin_knife(im, grip, tip):
    gx, gy = grip; tx, ty = tip
    dx, dy = tx - gx, ty - gy
    L = max(math.hypot(dx, dy), 1.0); ux, uy = dx / L, dy / L; px, py = -uy, ux
    root = (gx + ux * 2.0, gy + uy * 2.0)
    blade = [(root[0] + px * 2.3, root[1] + py * 2.3), (tx, ty),
             (root[0] - px * 1.7, root[1] - py * 1.7),
             (root[0] + ux * L * 0.45 - px * 0.6, root[1] + uy * L * 0.45 - py * 0.6)]  # khía gãy trên sống dao
    poly(im, blade, fill=RUST, outline=OUT_G, ow=0.9)
    line(im, root, (tx - ux * 2.5, ty - uy * 2.5), RUST_D, 0.8)
    ell(im, root[0] + ux * L * 0.35, root[1] + uy * L * 0.35, 1.3, 1.0, fill=RUST_SPOT)  # đốm gỉ
    ell(im, root[0] + ux * L * 0.62, root[1] + uy * L * 0.62, 1.0, 0.8, fill=RUST_SPOT)
    h1 = (gx - ux * 5.5, gy - uy * 5.5)  # cán quấn dây
    line(im, (gx, gy), h1, LEATHER_D, 2.8)
    for t in (0.3, 0.6, 0.9):
        cx, cy = gx - ux * 5.5 * t, gy - uy * 5.5 * t
        line(im, (cx + px * 1.4, cy + py * 1.4), (cx - px * 1.4, cy - py * 1.4), LEATHER_L, 0.7)

def _goblin_arm(im, shoulder, hand, knife_tip=None):
    elbow = ((shoulder[0] + hand[0]) / 2, (shoulder[1] + hand[1]) / 2 + 3.5)
    limb(im, shoulder, elbow, 6.2, GSKIN, GSKIN_D, GSKIN_L)
    limb(im, elbow, hand, 5.2, GSKIN, GSKIN_D, GSKIN_L)
    ell(im, hand[0], hand[1], 3.2, 2.9, fill=GSKIN, outline=OUT_G, ow=0.8)
    for k in range(3):  # móng vuốt
        ang = math.radians(40 + k * 28)
        line(im, (hand[0] + 2.6, hand[1] + 1.2), (hand[0] + 2.6 + 2.6 * math.cos(ang), hand[1] + 1.2 + 2.6 * math.sin(ang)), FANG, 0.8)
    if knife_tip is not None:
        _goblin_knife(im, hand, knife_tip)

def goblin_pose(direction, mode, i, n):
    im = new_canvas()
    phase = (i % 6) / 3.0
    bob = 0.0
    if mode == "idle":
        bob = [0.0, 1.0, 0.0][i % 3]
    elif mode == "walk":
        bob = abs(math.sin(phase * math.pi)) * -1.3
    _goblin_legs(im, direction, phase, mode)
    body = new_canvas()
    _goblin_torso(body, direction)
    if direction == "down":
        sh_r, sh_l = (78.5, 60), (49.5, 60)
        if mode == "attack":
            hands = [(83, 38), (88, 52), (85, 72), (79, 80)]
            tips = [(102, 18), (108, 50), (100, 90), (88, 100)]
            _goblin_arm(body, sh_r, hands[i], tips[i])
            if i == 2:
                draw_swoosh(body, 64, 60, 40, -40, 100, alpha=130)
            _goblin_arm(body, sh_l, (45, 74), None)
        elif mode == "walk":
            sw = math.sin(phase * math.pi) * 4.0
            _goblin_arm(body, sh_r, (81, 76 + sw), (92, 94 + sw))
            _goblin_arm(body, sh_l, (46, 76 - sw), None)
        else:
            _goblin_arm(body, sh_r, (81, 76), (93, 95))
            _goblin_arm(body, sh_l, (46, 76), None)
    elif direction == "up":
        sh_r, sh_l = (78.5, 60), (49.5, 60)
        if mode == "attack":
            hands = [(84, 40), (89, 54), (86, 72), (80, 80)]
            tips = [(101, 20), (107, 52), (99, 90), (87, 99)]
            _goblin_arm(body, sh_r, hands[i], tips[i])
            if i == 2:
                draw_swoosh(body, 64, 58, 39, -50, 95, alpha=120)
            _goblin_arm(body, sh_l, (44, 72), None)
        elif mode == "walk":
            sw = math.sin(phase * math.pi) * 4.0
            _goblin_arm(body, sh_r, (81, 74 + sw), (92, 92 + sw))
            _goblin_arm(body, sh_l, (46, 74 - sw), None)
        else:
            _goblin_arm(body, sh_r, (81, 74), (93, 93))
            _goblin_arm(body, sh_l, (46, 74), None)
    else:  # side hướng phải
        sh_f, sh_b = (71.0, 60), (57.0, 60)
        if mode == "attack":
            hands = [(64, 38), (56, 50), (82, 66), (79, 78)]
            tips = [(50, 16), (38, 44), (108, 82), (95, 99)]
            _goblin_arm(body, sh_b, (51, 72), None)
            _goblin_arm(body, sh_f, hands[i], tips[i])
            if i == 2:
                draw_swoosh(body, 66, 58, 37, -80, 50, alpha=130)
        elif mode == "walk":
            sw = math.sin(phase * math.pi) * 4.5
            _goblin_arm(body, sh_b, (51, 72 - sw * 0.5), None)
            _goblin_arm(body, sh_f, (75, 73 + sw), (87, 91 + sw))
        else:
            _goblin_arm(body, sh_b, (51, 72), None)
            _goblin_arm(body, sh_f, (75, 73), (88, 92))
    _goblin_head(body, direction, dy=(1.0 if mode == "attack" and i == 2 else 0.0))
    if bob != 0.0:
        shifted = new_canvas()
        shifted.alpha_composite(body, dest=(0, int(bob * SS)))
        body = shifted
    im.alpha_composite(body)
    return im

def goblin_hurt_frame(i):
    im = goblin_pose("down", "idle", 0, 3)
    for ex in (57.2, 70.8):
        ell(im, ex, 36.8, 3.7, 4.3, fill=GSKIN_L)
        line(im, (ex - 2.6, 33.8), (ex + 2.6, 39.8), OUT_G, 1.4)
        line(im, (ex - 2.6, 39.8), (ex + 2.6, 33.8), OUT_G, 1.4)
    ell(im, 64, 48.6, 4.4, 3.4, fill=MOUTH, outline=OUT_G, ow=0.7)  # miệng há to hơn khi đau
    s = new_canvas(); s.alpha_composite(im, dest=(int(-2.5 * SS), 0)); im = s
    if i == 1:
        a = im.split()[3]
        red = Image.new("RGBA", (W, W), (255, 64, 44, 0))
        red.putalpha(a.point(lambda v: int(v * 0.38)))
        im.alpha_composite(red)
    return im

def goblin_death_frame(i):
    if i == 0:
        im = goblin_pose("down", "idle", 0, 3)
        s = new_canvas(); s.alpha_composite(im, dest=(0, int(3.0 * SS))); im = s
        for ex in (57.2, 70.8):
            ell(im, ex, 39.8, 3.7, 4.3, fill=GSKIN_L)
            line(im, (ex - 2.6, 36.8), (ex + 2.6, 42.8), OUT_G, 1.4)
            line(im, (ex - 2.6, 42.8), (ex + 2.6, 36.8), OUT_G, 1.4)
        return im
    base = goblin_pose("down", "idle", 0, 3)
    return _rot(base, 80, dy=6, fit_bottom=120) if i == 1 else _rot(base, 80, dy=6, alpha=0.45, fit_bottom=120)

# ============================================================ BUILD SHEETS + TRES

def build_rows():
    p = {}
    for ddir in ("down", "up", "side"):
        p[f"idle_{ddir}"] = [player_pose(ddir, "idle", k, 3) for k in range(3)]
        p[f"walk_{ddir}"] = [player_pose(ddir, "walk", k, 6) for k in range(6)]
        p[f"attack_{ddir}"] = [player_pose(ddir, "attack", k, 4) for k in range(4)]
        p[f"dodge_{ddir}"] = [player_dodge_frame(ddir, k) for k in range(3)]
    p["hurt"] = [player_hurt_frame(k) for k in range(2)]
    p["death"] = [player_death_frame(k) for k in range(3)]
    g = {}
    for ddir in ("down", "up", "side"):
        g[f"idle_{ddir}"] = [goblin_pose(ddir, "idle", k, 3) for k in range(3)]
        g[f"walk_{ddir}"] = [goblin_pose(ddir, "walk", k, 6) for k in range(6)]
        g[f"attack_{ddir}"] = [goblin_pose(ddir, "attack", k, 4) for k in range(4)]
    g["hurt"] = [goblin_hurt_frame(k) for k in range(2)]
    g["death"] = [goblin_death_frame(k) for k in range(3)]
    return p, g

PLAYER_ROWS = ["idle_down", "idle_up", "idle_side",
               "walk_down", "walk_up", "walk_side",
               "attack_down", "attack_up", "attack_side",
               "dodge_down", "dodge_up", "dodge_side",
               "hurt", "death"]
GOBLIN_ROWS = ["idle_down", "idle_up", "idle_side",
               "walk_down", "walk_up", "walk_side",
               "attack_down", "attack_up", "attack_side",
               "hurt", "death"]
ANIM_META = {"idle": (4.0, True), "walk": (10.0, True), "attack": (14.0, False),
             "dodge": (12.0, False), "hurt": (8.0, False), "death": (5.0, False)}

def compose_sheet(rows_data, row_order):
    cols = max(len(rows_data[r]) for r in row_order)
    sheet = Image.new("RGBA", (cols * FS, len(row_order) * FS), (0, 0, 0, 0))
    for ri, name in enumerate(row_order):
        for ci, fr512 in enumerate(rows_data[name]):
            sheet.alpha_composite(finish(fr512), dest=(ci * FS, ri * FS))
    return sheet, cols

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

# ============================================================ PREVIEW + MOCKUP

def checker(w, h, cell=16, c1=(46, 48, 54, 255), c2=(58, 60, 68, 255)):
    bg = Image.new("RGBA", (w, h), c1)
    d = ImageDraw.Draw(bg)
    for y in range(0, h, cell):
        for x in range(0, w, cell):
            if (x // cell + y // cell) % 2 == 0:
                d.rectangle([x, y, x + cell - 1, y + cell - 1], fill=c2)
    return bg

def grass_bg(w, h, seed=3):
    rnd = random.Random(seed)
    bg = Image.new("RGBA", (w, h), (38, 62, 34, 255))
    px = bg.load()
    for y in range(h):
        for x in range(w):
            n = rnd.randint(-7, 7)
            px[x, y] = (38 + n, 62 + n, 34 + n // 2, 255)
    d = ImageDraw.Draw(bg)
    for _ in range(w * h // 260):  # lá cỏ
        x, y = rnd.uniform(0, w), rnd.uniform(0, h)
        d.line([x, y, x + rnd.uniform(-2, 2), y - rnd.uniform(3, 6)], fill=(58, 94, 46, 255), width=1)
    for _ in range(7):  # mảng sáng/tối lớn
        x, y = rnd.uniform(0, w), rnd.uniform(0, h)
        r = rnd.uniform(30, 80)
        ov = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(ov).ellipse([x - r, y - r * 0.5, x + r, y + r * 0.5],
                                   fill=(86, 120, 58, 26) if rnd.random() < 0.5 else (16, 30, 14, 30))
        bg.alpha_composite(ov)
    return bg

def frame_at(sheet, row_order, name, idx=0):
    ri = row_order.index(name)
    return sheet.crop((idx * FS, ri * FS, (idx + 1) * FS, (ri + 1) * FS))

def make_preview(p_sheet, g_sheet):
    """Preview v3: (a) sheets native + lưới, (b) size thật 128/64 trên cỏ, (c) mockup."""
    from PIL import ImageFont
    font = ImageFont.load_default()
    # (a) 2 sheet cạnh nhau ở size native, có khung frame
    aw = p_sheet.width + g_sheet.width + 36
    ah = max(p_sheet.height, g_sheet.height) + 12
    a_img = checker(aw, ah, 24)
    a_img.alpha_composite(p_sheet, dest=(6, 6))
    a_img.alpha_composite(g_sheet, dest=(18 + p_sheet.width, 6))
    d = ImageDraw.Draw(a_img)
    for ox, sheet, rows_n, cols_n in ((6, p_sheet, 14, 6), (18 + p_sheet.width, g_sheet, 11, 6)):
        for r in range(rows_n):
            for c in range(cols_n):
                d.rectangle([ox + c * FS, 6 + r * FS, ox + (c + 1) * FS - 1, 6 + (r + 1) * FS - 1],
                            outline=(255, 200, 60, 130))
    # (b) hàng hero: các pose chính ở 128 và 64 trên nền cỏ
    heroes = [("PLAYER idle", frame_at(p_sheet, PLAYER_ROWS, "idle_down", 0)),
              ("walk", frame_at(p_sheet, PLAYER_ROWS, "walk_down", 2)),
              ("attack", frame_at(p_sheet, PLAYER_ROWS, "attack_down", 2)),
              ("dodge", frame_at(p_sheet, PLAYER_ROWS, "dodge_down", 1)),
              ("GOBLIN idle", frame_at(g_sheet, GOBLIN_ROWS, "idle_down", 0)),
              ("walk", frame_at(g_sheet, GOBLIN_ROWS, "walk_down", 2)),
              ("attack", frame_at(g_sheet, GOBLIN_ROWS, "attack_down", 2)),
              ("death", frame_at(g_sheet, GOBLIN_ROWS, "death", 1))]
    bw = 6 * 150 + 12; bh = 150 + 86 + 24
    b_img = grass_bg(bw, bh, seed=5)
    db = ImageDraw.Draw(b_img)
    for k, (label, fr) in enumerate(heroes):
        col = k % 6; rowi = k // 6
        x = 8 + col * 150; y = 8 + rowi * (150 + 22)
        b_img.alpha_composite(fr, dest=(x + 11, y))
        db.text((x + 4, y + 132), label, fill=(240, 240, 220, 255), font=font)
        small = fr.resize((64, 64), Image.LANCZOS)
        if rowi == 0 and col < 4:
            pass
    # hàng size 64 (như hiển thị khi thu nhỏ)
    y64 = 8 + 150 + 22 + 4
    db.text((8, y64 - 14), "size 64:", fill=(240, 240, 220, 255), font=font)
    for k, (label, fr) in enumerate(heroes[:6]):
        small = fr.resize((64, 64), Image.LANCZOS)
        b_img.alpha_composite(small, dest=(70 + k * 90, y64))
    # (c) mockup: player + 2 goblin trên cỏ giống map Đông
    cw, chh = 640, 400
    c_img = grass_bg(cw, chh, seed=8)
    dc = ImageDraw.Draw(c_img)
    def place(fr, cx, feet_y, disp=96):
        r = fr.resize((disp, disp), Image.LANCZOS)
        dc.ellipse([cx - 22, feet_y - 6, cx + 22, feet_y + 5], fill=(0, 0, 0, 90))
        c_img.alpha_composite(r, dest=(int(cx - disp / 2), int(feet_y - disp * (GROUND / FS))))
    place(frame_at(p_sheet, PLAYER_ROWS, "attack_side", 2), 250, 250, 100)
    place(frame_at(g_sheet, GOBLIN_ROWS, "walk_side", 2), 390, 235, 94)
    place(frame_at(g_sheet, GOBLIN_ROWS, "idle_down", 0), 460, 300, 94)
    dc.text((10, 8), "MOCKUP in-game (vung Dong)", fill=(245, 245, 225, 255), font=font)
    # ghép 3 phần dọc
    Wtot = max(a_img.width, b_img.width, c_img.width)
    Htot = a_img.height + b_img.height + c_img.height + 24
    prev = Image.new("RGBA", (Wtot, Htot), (24, 24, 28, 255))
    prev.alpha_composite(a_img, dest=(0, 0))
    prev.alpha_composite(b_img, dest=(0, a_img.height + 8))
    prev.alpha_composite(c_img, dest=(0, a_img.height + b_img.height + 16))
    prev.convert("RGB").save(os.path.join(DESIGN_DIR, "sprite_preview_v3.png"))
    c_img.convert("RGB").save(os.path.join(DESIGN_DIR, "sprite_mockup_v3.png"))
    print("preview ->", os.path.join(DESIGN_DIR, "sprite_preview_v3.png"), prev.size)

def main():
    p_rows, g_rows = build_rows()
    p_sheet, _ = compose_sheet(p_rows, PLAYER_ROWS)
    g_sheet, _ = compose_sheet(g_rows, GOBLIN_ROWS)
    p_sheet.save(os.path.join(OUT_DIR, "player_spritesheet.png"))
    g_sheet.save(os.path.join(OUT_DIR, "goblin_spritesheet.png"))
    print("player sheet:", p_sheet.size, "goblin sheet:", g_sheet.size)
    n1 = write_tres(os.path.join(OUT_DIR, "player_frames.tres"), p_rows, PLAYER_ROWS,
                    "res://assets/sprites/player_spritesheet.png")
    n2 = write_tres(os.path.join(OUT_DIR, "goblin_frames.tres"), g_rows, GOBLIN_ROWS,
                    "res://assets/sprites/goblin_spritesheet.png")
    print("atlas textures:", n1, n2)
    make_preview(p_sheet, g_sheet)

if __name__ == "__main__":
    main()
