#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh spritesheet cho QUÁI GIAI ĐOẠN 1 (Đông) của "Dưới Bóng Phong Ấn":
chuột (rat) + slime cỏ (slime) + golem rêu (golem, boss). Frame 128x128.

Kỹ thuật giống tools/gen_sprites_v3.py:
- Vẽ SUPERSAMPLE ở 512x512 (4x) bằng PIL: polygon/ellipse tham số, shading
  nhiều lớp (gradient đáy, sáng radial trên-trái, rim), chi tiết vẽ tay.
- Downscale về 128x128 bằng LANCZOS + unsharp nhẹ.
- Mỗi HÀNG sheet = 1 animation, frame từ cột 0. Hướng: down/up/side
  (side = nhìn phải, trái dùng flip_h trong Godot).

THỨ TỰ HÀNG (khai báo ở ROWS bên dưới — .tres sinh theo đúng thứ tự này):
  0 idle_down    (2 frame)   1 idle_up    (2 frame)   2 idle_side   (2 frame)
  3 walk_down    (4 frame)   4 walk_up    (4 frame)   5 walk_side   (4 frame)
  6 attack_down  (2 frame)   7 attack_up  (2 frame)   8 attack_side (2 frame)
  9 hurt         (1 frame)  10 death      (2 frame)

Chạy: python3 tools/gen_enemy_sprites.py   (cần Pillow)
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
os.makedirs(OUT_DIR, exist_ok=True)

random.seed(20261024)

# ---------------- gradients dùng cho shading (tạo 1 lần ở 512) ----------------

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

# ---------------- palette ----------------
OUT_R = (30, 24, 20, 255)        # outline chuột
FUR_D = (94, 76, 58, 255); FUR = (130, 110, 88, 255); FUR_L = (172, 150, 124, 255)
BELLY = (192, 172, 148, 255)
EAR_PINK = (236, 164, 162, 255); EAR_IN = (206, 116, 116, 255)
NOSE = (232, 130, 130, 255)
EYE_RED = (224, 44, 38, 255); EYE_HI = (255, 190, 170, 255)
TAIL = (198, 152, 140, 255); TAIL_D = (164, 118, 108, 255)
PAW = (160, 128, 104, 255)
WHISKER = (240, 236, 226, 170)

GEL_D = (38, 122, 52, 255); GEL = (86, 196, 92, 235); GEL_L = (150, 232, 130, 235)
GEL_CORE = (178, 244, 160, 150)
GEL_HI = (235, 255, 225, 190)
OUT_S = (22, 74, 34, 255)
LEAF = (46, 140, 60, 255)

# ---------------- helpers vẽ ở không gian 128 (tự nhân SS) ----------------

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

def _fit(frame512, bottom=119.0, cx=64.0):
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

# ============================================================ RAT

def _rat_tail(im, root, sway=0.0, curl=1.0):
    """Đuôi dài cong: 3 đoạn bezier thuôn dần + vạch đốt mờ."""
    rx, ry = root
    pts = bezier((rx, ry), (rx - 16 - sway, ry - 10), (rx - 30 - sway * 1.6, ry + 4),
                 (rx - 26 - sway * 2.0, ry + 16 * curl))
    d = ImageDraw.Draw(im)
    for wdt, col in ((4.6, TAIL_D), (3.4, TAIL)):
        d.line(P_(pts), fill=col, width=max(1, int(wdt * SS)), joint="curve")
    tip = pts[-1]
    ell(im, tip[0], tip[1], 1.7, 1.7, fill=TAIL)
    for t in (0.3, 0.55, 0.8):  # đốt đuôi
        i = min(int(t * (len(pts) - 1)), len(pts) - 2)
        p0, p1 = pts[i], pts[i + 1]
        mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
        ell(im, mx, my, 1.9, 1.2, fill=A(TAIL_D, 130))

def _rat_ear(im, cx, cy, r=7.0, back=False):
    ell(im, cx, cy, r, r * 0.92, fill=FUR_D if back else EAR_PINK, outline=OUT_R, ow=1.0)
    if not back:
        ell(im, cx, cy + 0.6, r * 0.55, r * 0.5, fill=EAR_IN)
        ell(im, cx - r * 0.2, cy - r * 0.2, r * 0.2, r * 0.16, fill=A((255, 220, 214, 255), 200))

def _rat_eye(im, cx, cy, r=2.6, fierce=False):
    ell(im, cx, cy, r, r * 1.15, fill=EYE_RED, outline=OUT_R, ow=0.6)
    ell(im, cx + r * 0.25, cy - r * 0.3, r * 0.32, r * 0.32, fill=EYE_HI)
    if fierce:
        line(im, (cx - r * 1.2, cy - r * 1.5), (cx + r * 1.1, cy - r * 0.7), FUR_D, 1.2)

def _rat_whiskers(im, cx, cy, sign=1):
    for k, dy in enumerate((-1.5, 0.5, 2.5)):
        line(im, (cx, cy + dy * 0.4), (cx + sign * (11 - k), cy + dy * 1.6), WHISKER, 0.55)

def rat_pose(direction, mode, i, n):
    """1 frame chuột. mode: idle/walk/attack. i: index frame trong animation."""
    im = new_canvas()
    ph = math.sin(i / max(n, 1) * math.pi * 2) if n > 1 else 0.0
    bob = 0.0
    if mode == "idle":
        bob = [0.0, 1.2][i % 2]
    elif mode == "walk":
        bob = -abs(ph) * 1.6
    lunge = 0.0
    if mode == "attack":
        lunge = [3.0, 9.0][i % 2]          # frame 2 vồ tới
    sway = ph * 3.0 if mode == "walk" else (1.5 if mode == "idle" and i == 1 else 0.0)
    step = ph if mode == "walk" else 0.0  # pha chân chạy vụt

    if direction == "down":
        cy = 62 + bob + lunge * 0.4
        _rat_tail(im, (58, cy - 24), sway=sway)
        # chân sau + chân trước (vụt qua lại khi chạy)
        for sx, off in ((-1, step), (1, -step)):
            ell(im, 64 + sx * 24, cy + 16 + off * 3, 5.5, 4.0, fill=PAW, outline=OUT_R, ow=0.8)
            ell(im, 64 + sx * 20, cy - 14 - off * 3, 5.0, 3.8, fill=PAW, outline=OUT_R, ow=0.8)
        # thân thuôn dọc
        body = ell_pts(64, cy, 25, 31)
        poly(im, body, fill=FUR, outline=OUT_R, ow=1.2)
        shade(im, body, FUR_D[:3], FUR_L[:3], rim_rgb=FUR_L[:3], dark_a=100, light_a=70)
        belly = ell_pts(64, cy + 8, 15, 20)
        poly(im, belly, fill=A(BELLY, 130))
        dots(im, 64, cy - 8, 17, 22, 9, A(FUR_D, 150), 0.7, 1.6, seed=13)   # đốm lông lưng
        dots(im, 64, cy - 14, 14, 16, 5, A(FUR_L, 160), 0.6, 1.1, seed=29)
        # đầu ở dưới (hướng mặt xuống)
        hy = cy + 26 + lunge * 0.5
        _rat_ear(im, 64 - 13, hy - 8, 7.0)
        _rat_ear(im, 64 + 13, hy - 8, 7.0)
        head = ell_pts(64, hy, 16.5, 14.5)
        poly(im, head, fill=FUR, outline=OUT_R, ow=1.2)
        shade(im, head, FUR_D[:3], FUR_L[:3], dark_a=85, light_a=65)
        ell(im, 64, hy + 6, 9.5, 7.5, fill=FUR_L)                    # mõm sáng
        _rat_eye(im, 64 - 7.5, hy - 1.5, 2.7, fierce=(mode == "attack"))
        _rat_eye(im, 64 + 7.5, hy - 1.5, 2.7, fierce=(mode == "attack"))
        if mode == "attack" and i == 1:  # miệng há + răng cửa
            ell(im, 64, hy + 9.5, 4.6, 3.4, fill=(46, 26, 22, 255), outline=OUT_R, ow=0.7)
            poly(im, [(62.2, hy + 7.2), (64.0, hy + 7.2), (63.1, hy + 10.6)], fill=(246, 244, 234, 255))
            poly(im, [(64.2, hy + 7.2), (65.9, hy + 7.2), (65.0, hy + 10.6)], fill=(246, 244, 234, 255))
        ell(im, 64, hy + 11.5, 2.6, 1.9, fill=NOSE, outline=OUT_R, ow=0.6)  # mũi hồng
        _rat_whiskers(im, 56, hy + 8, sign=-1)
        _rat_whiskers(im, 72, hy + 8, sign=1)
    elif direction == "up":
        cy = 66 + bob - lunge * 0.4
        _rat_tail(im, (70, cy + 26), sway=-sway)
        for sx, off in ((-1, -step), (1, step)):
            ell(im, 64 + sx * 24, cy - 16 + off * 3, 5.5, 4.0, fill=PAW, outline=OUT_R, ow=0.8)
            ell(im, 64 + sx * 20, cy + 14 - off * 3, 5.0, 3.8, fill=PAW, outline=OUT_R, ow=0.8)
        body = ell_pts(64, cy, 25, 31)
        poly(im, body, fill=FUR_D, outline=OUT_R, ow=1.2)
        shade(im, body, (60, 46, 34), FUR[:3], dark_a=105, light_a=55)
        dots(im, 64, cy + 6, 17, 22, 10, A((52, 40, 28, 255), 150), 0.7, 1.6, seed=17)
        # sống lưng: vệt lông tối dọc
        line(im, (64, cy - 22), (64, cy + 20), A((52, 40, 28, 255), 170), 2.2)
        # đầu ở trên — chỉ thấy gáy + tai từ phía sau (không mắt)
        hy = cy - 27 - lunge * 0.5
        _rat_ear(im, 64 - 13, hy + 7, 7.0, back=True)
        _rat_ear(im, 64 + 13, hy + 7, 7.0, back=True)
        head = ell_pts(64, hy, 16.0, 14.0)
        poly(im, head, fill=FUR_D, outline=OUT_R, ow=1.2)
        shade(im, head, (60, 46, 34), FUR[:3], dark_a=100, light_a=50)
        ell(im, 64, hy - 3, 4.5, 3.4, fill=A(FUR, 160))              # xoáy lông gáy
    else:  # side — mặt hướng phải
        cy = 68 + bob
        _rat_tail(im, (34, cy - 14), sway=sway * 0.7, curl=0.8)
        for off, fx in ((step, 46), (-step, 58), (-step, 76), (step, 88)):
            ell(im, fx + off * 3.5, cy + 15, 5.2, 3.8, fill=PAW, outline=OUT_R, ow=0.8)
        body = ell_pts(62, cy, 31, 20)
        poly(im, body, fill=FUR, outline=OUT_R, ow=1.2)
        shade(im, body, FUR_D[:3], FUR_L[:3], rim_rgb=FUR_L[:3], dark_a=100, light_a=70)
        belly = ell_pts(64, cy + 6, 20, 11)
        poly(im, belly, fill=A(BELLY, 120))
        dots(im, 52, cy - 6, 18, 10, 7, A(FUR_D, 150), 0.7, 1.5, seed=23)
        # đầu phía phải
        hx = 94 + lunge
        _rat_ear(im, hx - 9, cy - 16, 7.2)
        head = ell_pts(hx, cy - 4, 15.5, 13.0)
        poly(im, head, fill=FUR, outline=OUT_R, ow=1.2)
        shade(im, head, FUR_D[:3], FUR_L[:3], dark_a=85, light_a=65)
        ell(im, hx + 6, cy + 1, 8.0, 6.4, fill=FUR_L)                 # mõm
        _rat_eye(im, hx + 2.5, cy - 6.5, 2.8, fierce=(mode == "attack"))
        if mode == "attack" and i == 1:
            ell(im, hx + 9, cy + 5.5, 4.2, 3.0, fill=(46, 26, 22, 255), outline=OUT_R, ow=0.7)
            poly(im, [(hx + 6.8, cy + 3.4), (hx + 8.6, cy + 3.4), (hx + 7.7, cy + 6.6)], fill=(246, 244, 234, 255))
        ell(im, hx + 13.5, cy + 1.5, 2.6, 2.0, fill=NOSE, outline=OUT_R, ow=0.6)
        _rat_whiskers(im, hx + 9, cy + 3, sign=1)
    return im

def rat_hurt_frame():
    im = rat_pose("down", "idle", 0, 2)
    for ex in (56.5, 71.5):  # mắt X
        ell(im, ex, 86.5, 3.4, 3.8, fill=FUR_L)
        line(im, (ex - 2.4, 83.6), (ex + 2.4, 89.4), OUT_R, 1.3)
        line(im, (ex - 2.4, 89.4), (ex + 2.4, 83.6), OUT_R, 1.3)
    s = new_canvas(); s.alpha_composite(im, dest=(int(-2.5 * SS), 0))
    return s

def rat_death_frame(i):
    if i == 0:
        im = rat_pose("down", "idle", 0, 2)
        s = new_canvas(); s.alpha_composite(im, dest=(0, int(3.0 * SS))); im = s
        for ex in (56.5, 71.5):
            ell(im, ex, 89.5, 3.4, 3.8, fill=FUR_L)
            line(im, (ex - 2.4, 86.6), (ex + 2.4, 92.4), OUT_R, 1.3)
            line(im, (ex - 2.4, 92.4), (ex + 2.4, 86.6), OUT_R, 1.3)
        return _fit(im, bottom=118)
    base = rat_pose("down", "idle", 0, 2)
    return _rot(base, 96, dy=5, alpha=0.55, fit_bottom=119)  # nằm lật + mờ dần

# ============================================================ SLIME

def _slime_blob_pts(cx, cy, rx, ry, squash=0.0, seed=3, wobble=1.6):
    """Đường viền khối gel: ellipse biến dạng — đáy phẳng hơn, đỉnh vòm, mép lượn sóng nhẹ."""
    rnd = random.Random(seed)
    pts = []
    n = 36
    for k in range(n + 1):
        a = math.radians(360.0 * k / n)
        wob = 1.0 + wobble * 0.012 * math.sin(a * 3 + seed)
        x = cx + rx * wob * math.cos(a)
        y = cy + ry * (1.0 - squash) * math.sin(a)
        if math.sin(a) > 0:  # nửa dưới: nén xuống đất, dẹt hơn
            y = cy + (y - cy) * 0.82
        pts.append((x, y))
    return pts

def slime_pose(direction, mode, i, n):
    """1 frame slime cỏ. mode: idle/walk/attack. Nhún/nén/phình theo nhịp frame."""
    im = new_canvas()
    if mode == "idle":
        squash = [0.0, 0.16][i % 2]           # nhún
        cy = 74 + squash * 10
    elif mode == "walk":
        squash = [0.22, 0.02, -0.06, 0.10][i % 4]  # bò: nén -> duỗi -> vươn -> nén
        cy = 74 + max(squash, 0.0) * 10
    else:  # attack: frame 1 nén lấy đà, frame 2 phình to vồ
        squash = [0.18, -0.14][i % 2]
        cy = 74 + (6 if i == 0 else -2)
    grow = 1.10 if (mode == "attack" and i == 1) else 1.0
    rx, ry = 30 * grow, 27 * grow
    cx = 64.0
    if direction == "side":
        cx += [0, 1.5, 3.0, 1.5][i % 4] if mode == "walk" else (5.0 if (mode == "attack" and i == 1) else 0.0)
    pts = _slime_blob_pts(cx, cy, rx, ry, squash=squash, seed=3 + i)
    poly(im, pts, fill=GEL, outline=OUT_S, ow=1.3)
    shade(im, pts, GEL_D[:3], GEL_L[:3], rim_rgb=(210, 255, 190), dark_a=70, light_a=65, rim_a=70)
    # lõi gel sáng trong mờ + bọt khí
    core = _slime_blob_pts(cx - 2, cy + 3, rx * 0.58, ry * 0.52, squash=squash, seed=11)
    poly(im, core, fill=GEL_CORE)
    for (bx, by, br) in ((-12, 6, 2.6), (8, 12, 1.9), (14, -2, 1.4), (-4, -10, 1.6)):
        ell(im, cx + bx, cy + by, br, br, fill=A((230, 255, 220, 255), 150), outline=A(OUT_S, 90), ow=0.5)
    # highlight bóng nước trên-trái
    ell(im, cx - rx * 0.42, cy - ry * 0.48, rx * 0.26, ry * 0.17, fill=GEL_HI, rot=-24)
    ell(im, cx - rx * 0.18, cy - ry * 0.62, rx * 0.10, ry * 0.07, fill=A((255, 255, 255, 255), 220), rot=-24)
    # chiếc lá cỏ trên đầu (dấu hiệu slime cỏ)
    leaf = bezier((cx + 2, cy - ry * (1 - squash) - 1), (cx + 4, cy - ry - 9),
                  (cx + 11, cy - ry - 11), (cx + 15, cy - ry - 6))
    leaf2 = bezier((cx + 15, cy - ry - 6), (cx + 10, cy - ry - 3), (cx + 6, cy - ry - 1),
                   (cx + 2, cy - ry * (1 - squash) - 1))
    poly(im, leaf + leaf2[1:], fill=LEAF, outline=OUT_S, ow=0.8)
    line(im, (cx + 3, cy - ry - 1.5), (cx + 5, cy + 2), GEL_D, 1.6)  # cuống + gân thân

    fy = cy - 2  # mặt ở nửa trên khối gel
    if direction == "down":
        for ex in (-10, 10):
            ell(im, cx + ex, fy, 3.6, 4.6, fill=(255, 255, 255, 235), outline=OUT_S, ow=0.6)
            ell(im, cx + ex, fy + 0.8, 1.9, 2.7, fill=(24, 40, 26, 255))
            ell(im, cx + ex + 0.7, fy - 0.6, 0.7, 0.7, fill=(255, 255, 255, 255))
            if mode == "attack":
                line(im, (cx + ex - 4.2, fy - 7.0), (cx + ex + 3.6, fy - 5.2), GEL_D, 1.5)
        if mode == "attack" and i == 1:  # miệng há tròn khi phình cắn
            ell(im, cx, fy + 10, 5.2, 4.2, fill=(30, 66, 34, 255), outline=OUT_S, ow=0.7)
            ell(im, cx, fy + 11.6, 3.4, 2.0, fill=(120, 220, 110, 200))
        else:  # miệng cười nhỏ
            arc = ell_pts(cx, fy + 7.5, 4.6, 3.6, a0=25, a1=155, n=14)
            d = ImageDraw.Draw(im)
            d.line(P_(arc), fill=(24, 52, 28, 255), width=int(1.1 * SS))
        ell(im, cx - 16, fy + 6, 3.2, 2.0, fill=A((140, 235, 130, 255), 130))  # má gel sáng
        ell(im, cx + 16, fy + 6, 3.2, 2.0, fill=A((140, 235, 130, 255), 130))
    elif direction == "side":
        ex = 13
        ell(im, cx + ex, fy, 3.6, 4.6, fill=(255, 255, 255, 235), outline=OUT_S, ow=0.6)
        ell(im, cx + ex + 0.8, fy + 0.8, 1.9, 2.7, fill=(24, 40, 26, 255))
        ell(im, cx + ex + 1.5, fy - 0.6, 0.7, 0.7, fill=(255, 255, 255, 255))
        if mode == "attack":
            line(im, (cx + ex - 4.0, fy - 7.0), (cx + ex + 3.8, fy - 5.0), GEL_D, 1.5)
        if mode == "attack" and i == 1:
            ell(im, cx + 17, fy + 9, 4.6, 3.6, fill=(30, 66, 34, 255), outline=OUT_S, ow=0.7)
        else:
            arc = ell_pts(cx + 14, fy + 7.0, 4.0, 3.2, a0=25, a1=150, n=12)
            d = ImageDraw.Draw(im)
            d.line(P_(arc), fill=(24, 52, 28, 255), width=int(1.1 * SS))
    else:  # up — mặt khuất, chỉ thấy vệt gel tối + bọt ở lưng
        dots(im, cx, cy - 4, 18, 14, 6, A(GEL_D, 130), 1.0, 2.2, seed=37)
    return im

def slime_hurt_frame():
    im = slime_pose("down", "idle", 1, 2)  # frame nén
    for ex in (54, 74):
        ell(im, ex, 74, 3.8, 4.4, fill=(235, 255, 225, 235))
        line(im, (ex - 2.5, 71.2), (ex + 2.5, 76.8), OUT_S, 1.3)
        line(im, (ex - 2.5, 76.8), (ex + 2.5, 71.2), OUT_S, 1.3)
    s = new_canvas(); s.alpha_composite(im, dest=(int(-2.0 * SS), 0))
    return s

def slime_death_frame(i):
    """Xẹp dần thành vũng gel."""
    im = new_canvas()
    if i == 0:
        pts = _slime_blob_pts(64, 92, 33, 15, squash=0.35, seed=5)
        poly(im, pts, fill=GEL, outline=OUT_S, ow=1.2)
        shade(im, pts, GEL_D[:3], GEL_L[:3], dark_a=70, light_a=55)
        for ex in (54, 74):  # mắt X trên khối xẹp
            line(im, (ex - 2.5, 86.5), (ex + 2.5, 92.0), OUT_S, 1.3)
            line(im, (ex - 2.5, 92.0), (ex + 2.5, 86.5), OUT_S, 1.3)
        ell(im, 50, 84, 5.5, 2.6, fill=GEL_HI, rot=-18)
        return im
    pts = _slime_blob_pts(64, 100, 38, 8, squash=0.6, seed=9)
    poly(im, pts, fill=A(GEL, 165), outline=A(OUT_S, 170), ow=1.0)
    ell(im, 52, 97, 7.0, 2.8, fill=A(GEL_HI, 130), rot=-14)
    ell(im, 82, 103, 4.5, 1.9, fill=A(GEL_L, 130))
    ell(im, 40, 105, 3.2, 1.5, fill=A(GEL, 140))  # vệt gel văng
    ell(im, 90, 94, 2.6, 1.3, fill=A(GEL, 140))
    return im

# ============================================================ GOLEM
# Golem đá phủ rêu (boss vùng Đông): khối đá xám nhiều mảng ghép, rêu xanh
# trên vai/đầu/lưng, mắt + lõi ngực vàng sáng, tay to quá khổ, chân trụ ngắn.
# Death: frame 1 sụp xuống, frame 2 thành đống đá vụn + rêu + mảnh lõi tắt.

STONE_DD = (46, 44, 50, 255); STONE_D = (72, 70, 76, 255)
STONE = (112, 110, 114, 255); STONE_L = (152, 150, 154, 255)
CRACK = (36, 34, 40, 255)
MOSS_D = (40, 102, 40, 255); MOSS = (72, 156, 58, 255); MOSS_L = (124, 202, 92, 255)
CORE_G = (255, 196, 36, 255); CORE_HI = (255, 242, 178, 255)
OUT_G = (26, 24, 28, 255)

def _golem_moss(im, cx, cy, rx, ry, seed=5, n=7):
    """Cụm rêu: mảng nền tối + đốm sáng chồng lên."""
    ell(im, cx, cy, rx, ry, fill=MOSS_D)
    dots(im, cx, cy, rx * 0.85, ry * 0.8, n, MOSS, 1.0, 2.2, seed=seed)
    dots(im, cx, cy - ry * 0.2, rx * 0.6, ry * 0.5, max(3, n // 2), MOSS_L, 0.7, 1.4, seed=seed + 3)

def _golem_cracks(im, pts_list):
    for p0, p1 in pts_list:
        line(im, p0, p1, A(CRACK, 190), 1.1)

def _golem_fist(im, cx, cy, r=10.0, dark=False):
    pts = ell_pts(cx, cy, r, r * 1.12)
    poly(im, pts, fill=STONE_D if dark else STONE, outline=OUT_G, ow=1.1)
    shade(im, pts, STONE_DD[:3], STONE_L[:3], dark_a=95, light_a=55)
    for k in (-0.35, 0.0, 0.35):  # khớp ngón tay
        line(im, (cx + r * k - 1.5, cy + r * 0.55), (cx + r * k + 1.0, cy + r * 0.95), A(CRACK, 160), 0.9)

def _golem_eye(im, cx, cy, r=2.3):
    ell(im, cx, cy, r * 1.9, r * 1.9, fill=A(CORE_G, 110))       # quầng sáng lõi
    ell(im, cx, cy, r, r * 1.15, fill=CORE_G, outline=OUT_G, ow=0.5)
    ell(im, cx + r * 0.25, cy - r * 0.3, r * 0.32, r * 0.32, fill=CORE_HI)

def golem_pose(direction, mode, i, n):
    """1 frame golem. mode: idle/walk/attack. Tay phải (phía trước) là tay đập."""
    im = new_canvas()
    ph = math.sin(i / max(n, 1) * math.pi * 2) if n > 1 else 0.0
    bob = 0.0
    step = 0.0
    if mode == "idle":
        bob = [0.0, 1.4][i % 2]
    elif mode == "walk":
        bob = -abs(ph) * 1.6
        step = ph
    lean = 0.0        # cúi người khi đập
    fist_r = None     # override vị trí nắm đấm phải theo mode attack
    fist_l = None
    if mode == "attack":
        if i == 0:    # gồng: hai tay giơ lên, người nhổm
            bob = -2.5
            fist_r, fist_l = (86.0, 58.0), (42.0, 58.0)
        else:         # đập xuống trước mặt
            lean = 5.0
            fist_r, fist_l = (80.0, 100.0), (48.0, 100.0)

    if direction == "down":
        cy = 60 + bob + lean * 0.4
        # chân trụ đá (bước so le khi walk)
        for sx, off in ((-1, step), (1, -step)):
            lx = 64 + sx * 11
            leg = [(lx - 7, cy + 14), (lx + 7, cy + 14), (lx + 8, cy + 40 + off * 3), (lx - 8, cy + 40 + off * 3)]
            poly(im, leg, fill=STONE_D, outline=OUT_G, ow=1.1)
            ell(im, lx, cy + 42 + off * 3, 9.5, 4.2, fill=STONE_DD, outline=OUT_G, ow=0.9)  # bàn chân
        # tay trái / phải treo hai bên (vẽ trước thân để vai chìm vào thân)
        fl = fist_l if fist_l else (29.0, cy + 26 - (step * 3 if mode == "walk" else 0.0))
        fr = fist_r if fist_r else (99.0, cy + 26 + (step * 3 if mode == "walk" else 0.0))
        poly(im, [(38, cy - 14), (47, cy - 16), (fl[0] + 4, fl[1] - 6), (fl[0] - 6, fl[1] - 4)], fill=STONE_D, outline=OUT_G, ow=1.1)
        poly(im, [(81, cy - 16), (90, cy - 14), (fr[0] + 6, fr[1] - 4), (fr[0] - 4, fr[1] - 6)], fill=STONE_D, outline=OUT_G, ow=1.1)
        # thân: khối thang vai rộng eo hẹp, ghép mảng
        torso = [(36, cy - 20), (92, cy - 20), (89, cy + 4), (83, cy + 20), (45, cy + 20), (39, cy + 4)]
        poly(im, torso, fill=STONE, outline=OUT_G, ow=1.3)
        shade(im, torso, STONE_D[:3], STONE_L[:3], rim_rgb=STONE_L[:3], dark_a=95, light_a=60)
        # đường ghép mảng đá + nứt
        line(im, (64, cy - 20), (62, cy + 20), A(CRACK, 150), 1.2)
        line(im, (38, cy + 2), (88, cy - 2), A(CRACK, 120), 1.0)
        _golem_cracks(im, [((48, cy - 12), (54, cy - 4)), ((54, cy - 4), (51, cy + 3)),
                           ((76, cy + 6), (82, cy + 12))])
        dots(im, 64, cy, 22, 16, 10, A(STONE_D, 140), 0.7, 1.7, seed=41)   # đốm đá
        dots(im, 64, cy - 8, 20, 10, 5, A(STONE_L, 150), 0.6, 1.2, seed=43)
        # lõi ngực vàng sáng
        ell(im, 63, cy + 2, 8.5, 8.5, fill=A(CORE_G, 110))
        ell(im, 63, cy + 2, 5.0, 5.0, fill=CORE_G, outline=OUT_G, ow=0.8)
        ell(im, 61.5, cy + 0.5, 1.6, 1.6, fill=CORE_HI)
        _golem_fist(im, fl[0], fl[1], 10.5, dark=True)
        _golem_fist(im, fr[0], fr[1], 11.5)
        # rêu vai
        _golem_moss(im, 40, cy - 19, 9, 4.5, seed=51)
        _golem_moss(im, 88, cy - 18, 7, 3.8, seed=57, n=5)
        # đầu đá nhỏ lún giữa hai vai — gờ mày, mắt lõi vàng, rêu phủ đỉnh
        hy = cy - 30 + lean * 0.3
        head = [(50, hy - 9), (78, hy - 9), (80, hy + 7), (48, hy + 7)]
        poly(im, head, fill=STONE, outline=OUT_G, ow=1.2)
        shade(im, head, STONE_D[:3], STONE_L[:3], dark_a=90, light_a=55)
        poly(im, [(48, hy - 1), (80, hy - 1), (80, hy + 2.5), (48, hy + 2.5)], fill=STONE_D)  # gờ mày
        _golem_eye(im, 57.5, hy + 4.5, 2.3)
        _golem_eye(im, 70.5, hy + 4.5, 2.3)
        if mode == "attack":
            line(im, (53, hy - 0.5), (61, hy + 1.5), CRACK, 1.3)   # mày cau khi gồng/đập
            line(im, (75, hy - 0.5), (67, hy + 1.5), CRACK, 1.3)
        _golem_moss(im, 58, hy - 10, 11, 4.0, seed=61)
        _golem_moss(im, 74, hy - 8, 6, 3.0, seed=67, n=4)
    elif direction == "up":
        cy = 62 + bob
        for sx, off in ((-1, -step), (1, step)):
            lx = 64 + sx * 11
            leg = [(lx - 7, cy + 14), (lx + 7, cy + 14), (lx + 8, cy + 40 + off * 3), (lx - 8, cy + 40 + off * 3)]
            poly(im, leg, fill=STONE_D, outline=OUT_G, ow=1.1)
            ell(im, lx, cy + 42 + off * 3, 9.5, 4.2, fill=STONE_DD, outline=OUT_G, ow=0.9)
        fl = (29.0, cy + 26 + (step * 3 if mode == "walk" else 0.0))
        fr = (99.0, cy + 26 - (step * 3 if mode == "walk" else 0.0))
        if mode == "attack":
            fl, fr = ((42.0, 58.0), (86.0, 58.0)) if i == 0 else ((48.0, 98.0), (80.0, 98.0))
            if i == 1:
                cy += 3
        poly(im, [(38, cy - 14), (47, cy - 16), (fl[0] + 4, fl[1] - 6), (fl[0] - 6, fl[1] - 4)], fill=STONE_D, outline=OUT_G, ow=1.1)
        poly(im, [(81, cy - 16), (90, cy - 14), (fr[0] + 6, fr[1] - 4), (fr[0] - 4, fr[1] - 6)], fill=STONE_D, outline=OUT_G, ow=1.1)
        torso = [(36, cy - 20), (92, cy - 20), (89, cy + 4), (83, cy + 20), (45, cy + 20), (39, cy + 4)]
        poly(im, torso, fill=STONE_D, outline=OUT_G, ow=1.3)
        shade(im, torso, STONE_DD[:3], STONE[:3], dark_a=100, light_a=50)
        # lưng: mảng đá lớn hình khiên + nứt chéo, rêu phủ dày (lưng hướng nắng ẩm)
        shield = [(48, cy - 14), (80, cy - 14), (84, cy + 2), (76, cy + 16), (52, cy + 16), (44, cy + 2)]
        poly(im, shield, fill=STONE, outline=OUT_G, ow=1.0)
        _golem_cracks(im, [((54, cy - 10), (66, cy + 2)), ((66, cy + 2), (62, cy + 12)),
                           ((74, cy - 8), (70, cy + 4))])
        _golem_moss(im, 56, cy - 6, 12, 8, seed=71, n=9)
        _golem_moss(im, 76, cy + 6, 9, 6, seed=73, n=6)
        _golem_fist(im, fl[0], fl[1], 10.5, dark=True)
        _golem_fist(im, fr[0], fr[1], 11.5)
        _golem_moss(im, 40, cy - 19, 9, 4.5, seed=51)
        hy = cy - 30
        head = [(50, hy - 9), (78, hy - 9), (80, hy + 7), (48, hy + 7)]
        poly(im, head, fill=STONE_D, outline=OUT_G, ow=1.2)
        shade(im, head, STONE_DD[:3], STONE[:3], dark_a=95, light_a=45)
        _golem_moss(im, 64, hy - 8, 13, 5.0, seed=79, n=9)   # rêu phủ gần kín đầu từ phía sau
    else:  # side — mặt hướng phải, tay trước (phải) to hơn
        cy = 62 + bob + lean * 0.4
        for off, lx in ((step, 52), (-step, 74)):
            leg = [(lx - 7, cy + 12), (lx + 7, cy + 12), (lx + 8, cy + 38 + off * 3), (lx - 8, cy + 38 + off * 3)]
            poly(im, leg, fill=STONE_D, outline=OUT_G, ow=1.1)
            ell(im, lx + 2, cy + 40 + off * 3, 10.0, 4.2, fill=STONE_DD, outline=OUT_G, ow=0.9)
        back_fist = (40.0, cy + 24 - (step * 3 if mode == "walk" else 0.0))
        front_fist = (96.0, cy + 24 + (step * 3 if mode == "walk" else 0.0))
        if mode == "attack":
            front_fist = (102.0, cy - 6) if i == 0 else (106.0, cy + 34)
            back_fist = (44.0, cy + 4) if i == 0 else (42.0, cy + 28)
        poly(im, [(46, cy - 14), (54, cy - 16), (back_fist[0] + 4, back_fist[1] - 6), (back_fist[0] - 5, back_fist[1] - 4)], fill=STONE_DD, outline=OUT_G, ow=1.1)
        torso = [(42, cy - 20), (86, cy - 20), (88, cy + 4), (80, cy + 20), (48, cy + 20), (42, cy + 4)]
        poly(im, torso, fill=STONE, outline=OUT_G, ow=1.3)
        shade(im, torso, STONE_D[:3], STONE_L[:3], rim_rgb=STONE_L[:3], dark_a=95, light_a=60)
        line(im, (64, cy - 20), (66, cy + 20), A(CRACK, 130), 1.1)
        _golem_cracks(im, [((50, cy - 8), (57, cy)), ((57, cy), (54, cy + 8))])
        dots(im, 62, cy, 18, 15, 8, A(STONE_D, 140), 0.7, 1.6, seed=83)
        # lõi ngực lộ một phần ở mép trước thân
        ell(im, 80, cy + 2, 6.5, 6.5, fill=A(CORE_G, 110))
        ell(im, 80, cy + 2, 3.8, 3.8, fill=CORE_G, outline=OUT_G, ow=0.7)
        _golem_moss(im, 48, cy - 19, 9, 4.5, seed=89)   # rêu vai sau
        poly(im, [(74, cy - 16), (84, cy - 18), (front_fist[0] - 4, front_fist[1] - 6), (front_fist[0] - 12, front_fist[1] - 2)], fill=STONE_D, outline=OUT_G, ow=1.1)
        _golem_fist(im, back_fist[0], back_fist[1], 9.5, dark=True)
        _golem_fist(im, front_fist[0], front_fist[1], 12.0)
        # đầu nhô phía trước-trên thân
        hx, hy = 80.0, cy - 30 + lean * 0.3
        head = [(hx - 13, hy - 9), (hx + 15, hy - 9), (hx + 16, hy + 7), (hx - 14, hy + 7)]
        poly(im, head, fill=STONE, outline=OUT_G, ow=1.2)
        shade(im, head, STONE_D[:3], STONE_L[:3], dark_a=90, light_a=55)
        poly(im, [(hx - 14, hy - 1), (hx + 16, hy - 1), (hx + 16, hy + 2.5), (hx - 14, hy + 2.5)], fill=STONE_D)
        _golem_eye(im, hx + 7, hy + 4.5, 2.3)
        if mode == "attack":
            line(im, (hx + 2, hy - 0.5), (hx + 11, hy + 1.5), CRACK, 1.3)
        _golem_moss(im, hx - 4, hy - 10, 11, 4.0, seed=97)
    return im

def golem_hurt_frame():
    im = golem_pose("down", "idle", 0, 2)
    # mắt nhắm nghiến (vạch ngang đè lên mắt lõi) + nứt thêm ở trán/thân
    for ex in (57.5, 70.5):
        ell(im, ex, 34.5, 3.6, 2.6, fill=STONE_D)
        line(im, (ex - 3.2, 33.2), (ex + 3.2, 35.8), CRACK, 1.4)
    _golem_cracks(im, [((60, 22), (64, 28)), ((64, 28), (61, 33)), ((44, 66), (52, 72))])
    s = new_canvas(); s.alpha_composite(im, dest=(int(-2.5 * SS), int(1.5 * SS)))
    return s

def golem_death_frame(i):
    if i == 0:
        # Sụp xuống: toàn thân hạ thấp, nứt lan, mắt/lõi mờ dần
        im = golem_pose("down", "idle", 0, 2)
        s = new_canvas(); s.alpha_composite(im, dest=(0, int(6.0 * SS))); im = s
        _golem_cracks(im, [((40, 50), (58, 62)), ((58, 62), (52, 76)), ((84, 48), (70, 64)),
                           ((70, 64), (78, 78)), ((58, 30), (64, 38))])
        for ex in (57.5, 70.5):  # mắt tắt dần
            ell(im, ex, 40.5, 3.4, 3.4, fill=A(STONE_DD, 170))
        ell(im, 63, 68, 5.2, 5.2, fill=A(STONE_DD, 150))  # lõi ngực vỡ mờ
        return _fit(im, bottom=119)
    # Đống đá vụn phủ rêu + mảnh lõi vàng đã tắt
    im = new_canvas()
    rocks = [(64, 100, 30, 12, STONE), (40, 105, 12, 8, STONE_D), (90, 103, 11, 8, STONE),
             (64, 90, 10, 7, STONE_L), (52, 95, 8, 6, STONE_D), (78, 93, 7, 5, STONE)]
    for (cx, cy, rx, ry, col) in rocks:
        pts = ell_pts(cx, cy, rx, ry)
        poly(im, pts, fill=col, outline=OUT_G, ow=1.1)
        shade(im, pts, STONE_D[:3], STONE_L[:3], dark_a=85, light_a=50)
    _golem_cracks(im, [((46, 96), (56, 102)), ((74, 88), (80, 94))])
    _golem_moss(im, 58, 92, 10, 4.5, seed=101, n=8)
    _golem_moss(im, 84, 100, 8, 4.0, seed=103, n=6)
    _golem_moss(im, 40, 103, 7, 3.5, seed=107, n=5)
    ell(im, 70, 101, 3.2, 2.6, fill=A(CORE_G, 120), outline=A(OUT_G, 160), ow=0.6)  # mảnh lõi tắt
    return im

# ============================================================ WOLF
# Sói xám: thân 4 chân lông xám, tai nhọn, mõm dài, đuôi rậm. Nhanh nhẹn.

WF_D = (66, 68, 76, 255); WF = (116, 120, 130, 255); WF_L = (172, 176, 186, 255)
WF_BELLY = (198, 198, 204, 255)
OUT_W = (26, 26, 32, 255)
EYE_AMBER = (238, 168, 44, 255)
NOSE_B = (22, 20, 24, 255)
TONGUE = (214, 110, 116, 255)

def _wolf_ear(im, cx, cy, s=1.0, back=False):
    poly(im, [(cx - 6 * s, cy + 3), (cx - 3.5 * s, cy - 8 * s), (cx + 1.5 * s, cy - 1),
              (cx + 4 * s, cy + 3)], fill=WF_D if back else WF, outline=OUT_W, ow=0.9)
    if not back:
        poly(im, [(cx - 3.4 * s, cy + 1), (cx - 2.4 * s, cy - 4.6 * s), (cx + 0.4 * s, cy - 0.6)],
             fill=(188, 150, 140, 255))

def _wolf_eye(im, cx, cy, r=2.5, fierce=False):
    ell(im, cx, cy, r, r * 1.1, fill=EYE_AMBER, outline=OUT_W, ow=0.6)
    ell(im, cx, cy, r * 0.45, r * 0.6, fill=(20, 16, 12, 255))
    ell(im, cx + r * 0.3, cy - r * 0.35, r * 0.28, r * 0.28, fill=(255, 240, 210, 255))
    if fierce:
        line(im, (cx - r * 1.3, cy - r * 1.6), (cx + r * 1.2, cy - r * 0.8), WF_D, 1.2)

def _wolf_tail(im, root, sway=0.0, up=False):
    rx, ry = root
    pts = bezier((rx, ry), (rx - 10 - sway, ry - (12 if up else 2)),
                 (rx - 20 - sway * 1.5, ry - (16 if up else -4)),
                 (rx - 26 - sway * 2.0, ry - (10 if up else -10)))
    d = ImageDraw.Draw(im)
    for wdt, col in ((8.5, WF_D), (6.0, WF)):
        d.line(P_(pts), fill=col, width=max(1, int(wdt * SS)), joint="curve")
    tip = pts[-1]
    ell(im, tip[0], tip[1], 3.4, 3.0, fill=WF_L)

def wolf_pose(direction, mode, i, n):
    im = new_canvas()
    ph = math.sin(i / max(n, 1) * math.pi * 2) if n > 1 else 0.0
    bob = 0.0
    if mode == "idle":
        bob = [0.0, 1.0][i % 2]
    elif mode == "walk":
        bob = -abs(ph) * 1.8
    lunge = 0.0
    if mode == "attack":
        lunge = [3.0, 10.0][i % 2]
    step = ph if mode == "walk" else 0.0
    sway = ph * 3.0 if mode == "walk" else (1.2 if mode == "idle" and i == 1 else 0.0)

    if direction == "down":
        cy = 58 + bob + lunge * 0.3
        _wolf_tail(im, (64, cy - 26), sway=sway)
        for sx, off in ((-1, step), (1, -step)):
            ell(im, 64 + sx * 22, cy + 15 + off * 3, 5.2, 3.8, fill=WF_D, outline=OUT_W, ow=0.8)
            ell(im, 64 + sx * 18, cy - 13 - off * 3, 4.8, 3.6, fill=WF_D, outline=OUT_W, ow=0.8)
        body = ell_pts(64, cy, 23, 29)
        poly(im, body, fill=WF, outline=OUT_W, ow=1.2)
        shade(im, body, WF_D[:3], WF_L[:3], rim_rgb=WF_L[:3], dark_a=95, light_a=65)
        mane = ell_pts(64, cy + 14, 18, 15)
        poly(im, mane, fill=A(WF_L, 150))
        dots(im, 64, cy - 10, 15, 20, 8, A(WF_D, 150), 0.7, 1.5, seed=31)
        hy = cy + 27 + lunge * 0.5
        _wolf_ear(im, 64 - 12, hy - 9, 1.0)
        _wolf_ear(im, 64 + 12, hy - 9, 1.0)
        head = ell_pts(64, hy, 15.5, 13.5)
        poly(im, head, fill=WF, outline=OUT_W, ow=1.2)
        shade(im, head, WF_D[:3], WF_L[:3], dark_a=80, light_a=60)
        snout = [(58, hy + 4), (70, hy + 4), (67.5, hy + 13 + lunge * 0.3), (60.5, hy + 13 + lunge * 0.3)]
        poly(im, snout, fill=WF_L, outline=OUT_W, ow=0.9)
        ell(im, 64, hy + 12.5 + lunge * 0.3, 3.2, 2.3, fill=NOSE_B)
        _wolf_eye(im, 64 - 7.5, hy - 2.5, 2.5, fierce=(mode == "attack"))
        _wolf_eye(im, 64 + 7.5, hy - 2.5, 2.5, fierce=(mode == "attack"))
        if mode == "attack" and i == 1:
            poly(im, [(60.5, hy + 8), (63.0, hy + 8), (61.8, hy + 11.5)], fill=(246, 244, 234, 255))
            poly(im, [(65.0, hy + 8), (67.5, hy + 8), (66.2, hy + 11.5)], fill=(246, 244, 234, 255))
            ell(im, 64, hy + 14.5, 2.2, 1.6, fill=TONGUE)
    elif direction == "up":
        cy = 62 + bob - lunge * 0.3
        _wolf_tail(im, (64, cy + 24), sway=-sway, up=True)
        for sx, off in ((-1, -step), (1, step)):
            ell(im, 64 + sx * 22, cy - 15 + off * 3, 5.2, 3.8, fill=WF_D, outline=OUT_W, ow=0.8)
            ell(im, 64 + sx * 18, cy + 13 - off * 3, 4.8, 3.6, fill=WF_D, outline=OUT_W, ow=0.8)
        body = ell_pts(64, cy, 23, 29)
        poly(im, body, fill=WF_D, outline=OUT_W, ow=1.2)
        shade(im, body, (44, 46, 54), WF[:3], dark_a=100, light_a=50)
        line(im, (64, cy - 20), (64, cy + 18), A((40, 42, 50, 255), 170), 2.4)
        dots(im, 64, cy + 4, 15, 20, 9, A((40, 42, 50, 255), 150), 0.7, 1.5, seed=33)
        hy = cy - 27 - lunge * 0.5
        _wolf_ear(im, 64 - 12, hy + 6, 1.0, back=True)
        _wolf_ear(im, 64 + 12, hy + 6, 1.0, back=True)
        head = ell_pts(64, hy, 15.0, 13.0)
        poly(im, head, fill=WF_D, outline=OUT_W, ow=1.2)
        shade(im, head, (44, 46, 54), WF[:3], dark_a=95, light_a=45)
    else:  # side - huong phai
        cy = 64 + bob
        _wolf_tail(im, (36, cy - 12), sway=sway * 0.7)
        for off, fx, back in ((step, 44, True), (-step, 56, False), (-step, 76, True), (step, 88, False)):
            col = WF_D if back else WF
            poly(im, [(fx - 3, cy + 8), (fx + 3, cy + 8), (fx + off * 3 + 2, cy + 24), (fx + off * 3 - 3, cy + 24)],
                 fill=col, outline=OUT_W, ow=0.8)
            ell(im, fx + off * 3, cy + 25, 4.6, 2.8, fill=WF_D, outline=OUT_W, ow=0.7)
        body = ell_pts(62, cy, 31, 19)
        poly(im, body, fill=WF, outline=OUT_W, ow=1.2)
        shade(im, body, WF_D[:3], WF_L[:3], rim_rgb=WF_L[:3], dark_a=95, light_a=65)
        belly = ell_pts(63, cy + 7, 20, 10)
        poly(im, belly, fill=A(WF_BELLY, 130))
        dots(im, 50, cy - 7, 17, 9, 7, A(WF_D, 150), 0.7, 1.4, seed=37)
        hx = 92 + lunge
        _wolf_ear(im, hx - 8, cy - 17, 1.05)
        head = ell_pts(hx, cy - 5, 14.5, 12.0)
        poly(im, head, fill=WF, outline=OUT_W, ow=1.2)
        shade(im, head, WF_D[:3], WF_L[:3], dark_a=80, light_a=60)
        snout = [(hx + 6, cy - 1), (hx + 16 + lunge * 0.3, cy + 2), (hx + 13, cy + 8), (hx + 5, cy + 6)]
        poly(im, snout, fill=WF_L, outline=OUT_W, ow=0.9)
        ell(im, hx + 15.5 + lunge * 0.3, cy + 2.5, 3.0, 2.2, fill=NOSE_B)
        _wolf_eye(im, hx + 1.5, cy - 7.5, 2.5, fierce=(mode == "attack"))
        if mode == "attack" and i == 1:
            poly(im, [(hx + 8, cy + 6.5), (hx + 10.5, cy + 6.5), (hx + 9.2, cy + 10)], fill=(246, 244, 234, 255))
    return im

def _x_eyes(im, coords, col_bg, col_x):
    for (ex, ey) in coords:
        ell(im, ex, ey, 3.4, 3.8, fill=col_bg)
        line(im, (ex - 2.4, ey - 2.9), (ex + 2.4, ey + 2.9), col_x, 1.3)
        line(im, (ex - 2.4, ey + 2.9), (ex + 2.4, ey - 2.9), col_x, 1.3)

def wolf_hurt_frame():
    im = wolf_pose("down", "idle", 0, 2)
    _x_eyes(im, [(56.5, 82.5), (71.5, 82.5)], WF_L, OUT_W)
    s = new_canvas(); s.alpha_composite(im, dest=(int(-2.5 * SS), 0))
    return s

def wolf_death_frame(i):
    if i == 0:
        im = wolf_pose("down", "idle", 0, 2)
        s = new_canvas(); s.alpha_composite(im, dest=(0, int(3.0 * SS))); im = s
        _x_eyes(im, [(56.5, 85.5), (71.5, 85.5)], WF_L, OUT_W)
        return _fit(im, bottom=118)
    base = wolf_pose("down", "idle", 0, 2)
    return _rot(base, 94, dy=5, alpha=0.55, fit_bottom=119)

# ============================================================ SPIDER
# Nhen rung: than tron den tim, 8 chan khuyu, cum mat do, tui doc xanh.

SP_DD = (30, 22, 44, 255); SP_D = (52, 38, 72, 255); SP = (84, 62, 108, 255)
SP_L = (138, 112, 168, 255)
OUT_SP = (16, 12, 26, 255)
EYE_R = (238, 52, 44, 255); EYE_RH = (255, 190, 170, 255)
VENOM = (120, 230, 90, 255)

def _spider_leg(im, hip, knee, foot, w=2.6):
    line(im, hip, knee, SP_DD, w)
    line(im, knee, foot, SP_D, w * 0.8)
    ell(im, knee[0], knee[1], w * 0.55, w * 0.55, fill=SP_D)

def _spider_legs_side(im, cx, cy, step, front_dir=0.0):
    """8 chan hai ben than (front_dir: dich cum chan theo huong mat)."""
    for sgn in (-1, 1):
        for k in range(4):
            hx = cx + sgn * 10 + front_dir
            hy = cy - 12 + k * 8
            lift = (step if (k % 2 == 0) == (sgn < 0) else -step) * 2.2
            knee = (cx + sgn * (26 + (k % 2) * 3), hy - 6 - abs(lift) * 0.4)
            foot = (cx + sgn * (33 + (k % 2) * 4), hy + 10 + lift)
            _spider_leg(im, (hx, hy), knee, foot)

def _spider_eyes(im, cx, cy, spread=1.0):
    for (dx, dy, r) in ((-6, 0, 2.6), (6, 0, 2.6), (-2.2, -2.6, 2.0), (2.2, -2.6, 2.0),
                        (-9.5, -2.0, 1.5), (9.5, -2.0, 1.5)):
        ex, ey = cx + dx * spread, cy + dy
        ell(im, ex, ey, r, r * 1.1, fill=EYE_R, outline=OUT_SP, ow=0.5)
        ell(im, ex + r * 0.3, ey - r * 0.3, r * 0.3, r * 0.3, fill=EYE_RH)

def spider_pose(direction, mode, i, n):
    im = new_canvas()
    ph = math.sin(i / max(n, 1) * math.pi * 2) if n > 1 else 0.0
    bob = 0.0
    if mode == "idle":
        bob = [0.0, 0.8][i % 2]
    elif mode == "walk":
        bob = -abs(ph) * 1.2
    lunge = 0.0
    if mode == "attack":
        lunge = [2.0, 7.0][i % 2]
    step = ph if mode == "walk" else (0.4 if mode == "idle" and i == 1 else 0.0)

    if direction == "down":
        cy = 56 + bob
        _spider_legs_side(im, 64, cy + 8, step)
        abd = ell_pts(64, cy, 24, 22)
        poly(im, abd, fill=SP, outline=OUT_SP, ow=1.2)
        shade(im, abd, SP_DD[:3], SP_L[:3], rim_rgb=SP_L[:3], dark_a=95, light_a=60)
        dots(im, 64, cy - 4, 15, 13, 7, A(SP_D, 170), 0.8, 1.8, seed=43)
        ell(im, 64, cy - 10, 4.2, 5.2, fill=A(VENOM, 150))  # tui doc tren lung
        hy = cy + 26 + lunge * 0.5
        head = ell_pts(64, hy, 13.5, 10.5)
        poly(im, head, fill=SP_D, outline=OUT_SP, ow=1.1)
        shade(im, head, SP_DD[:3], SP_L[:3], dark_a=80, light_a=50)
        _spider_eyes(im, 64, hy + 3.5)
        for sgn in (-1, 1):  # rang nanh
            poly(im, [(64 + sgn * 6, hy + 8), (64 + sgn * 8.5, hy + 8), (64 + sgn * 7, hy + 13)],
                 fill=(232, 228, 220, 255), outline=OUT_SP, ow=0.5)
        if mode == "attack" and i == 1:
            ell(im, 64, hy + 12, 2.0, 2.6, fill=VENOM)  # giot doc
    elif direction == "up":
        cy = 70 + bob
        _spider_legs_side(im, 64, cy - 8, step)
        hy = cy - 30 - lunge * 0.5
        head = ell_pts(64, hy, 13.0, 10.0)
        poly(im, head, fill=SP_DD, outline=OUT_SP, ow=1.1)
        abd = ell_pts(64, cy, 24, 22)
        poly(im, abd, fill=SP_D, outline=OUT_SP, ow=1.2)
        shade(im, abd, SP_DD[:3], SP[:3], dark_a=100, light_a=50)
        dots(im, 64, cy + 2, 15, 13, 8, A(SP_DD, 170), 0.8, 1.8, seed=47)
        ell(im, 64, cy + 6, 5.0, 6.0, fill=A(SP_L, 130))  # hoa van lung
        ell(im, 64, cy + 6, 2.4, 3.0, fill=A(VENOM, 120))
    else:  # side
        cy = 62 + bob
        for k in range(4):  # chan xa (toi)
            hx = 52 + k * 5
            _spider_leg(im, (hx, cy + 2), (hx - 8 + k * 7, cy - 8), (hx - 12 + k * 8, cy + 16 - step * 2), 2.2)
        abd = ell_pts(46, cy, 22, 19)
        poly(im, abd, fill=SP, outline=OUT_SP, ow=1.2)
        shade(im, abd, SP_DD[:3], SP_L[:3], dark_a=95, light_a=55)
        dots(im, 44, cy - 4, 13, 11, 6, A(SP_D, 170), 0.8, 1.7, seed=53)
        hx = 76 + lunge
        head = ell_pts(hx, cy + 2, 12.5, 10.0)
        poly(im, head, fill=SP_D, outline=OUT_SP, ow=1.1)
        shade(im, head, SP_DD[:3], SP_L[:3], dark_a=80, light_a=50)
        _spider_eyes(im, hx + 6, cy + 4, spread=0.55)
        for k in range(4):  # chan gan
            fx = 56 + k * 6
            _spider_leg(im, (fx, cy + 6), (fx - 6 + k * 8, cy - 2), (fx - 10 + k * 9, cy + 20 + step * 2), 2.6)
        poly(im, [(hx + 9, cy + 8), (hx + 12, cy + 8), (hx + 10, cy + 13)], fill=(232, 228, 220, 255), outline=OUT_SP, ow=0.5)
    return im

def spider_hurt_frame():
    im = spider_pose("down", "idle", 0, 2)
    _x_eyes(im, [(58, 85.5), (70, 85.5)], SP_L, OUT_SP)
    s = new_canvas(); s.alpha_composite(im, dest=(int(-2.0 * SS), 0))
    return s

def spider_death_frame(i):
    if i == 0:
        im = spider_pose("down", "idle", 0, 2)
        s = new_canvas(); s.alpha_composite(im, dest=(0, int(3.0 * SS))); im = s
        _x_eyes(im, [(58, 88.5), (70, 88.5)], SP_L, OUT_SP)
        return _fit(im, bottom=118)
    base = spider_pose("down", "idle", 0, 2)
    return _rot(base, 180, dy=4, alpha=0.55, fit_bottom=119)  # ngua bung

# ============================================================ WYVERN
# Wyvern non: than than lan xanh xam, canh mang nau do, sung nho, duoi dai.

WY_D = (56, 92, 90, 255); WY = (96, 138, 130, 255); WY_L = (150, 186, 174, 255)
WY_BELLY = (196, 206, 178, 255)
WING_BONE = (74, 62, 58, 255); WING_MEM = (176, 122, 96, 255); WING_MEM_D = (146, 96, 74, 255)
OUT_Y = (24, 34, 32, 255)
EYE_Y = (250, 196, 52, 255)
HORN = (226, 220, 200, 255)

def _wyvern_wing(im, root, tip, mid, flip=1):
    """Canh mang: xuong canh tren + mang xoe scallop xuong duoi."""
    rx, ry = root
    tx, ty = tip
    mx, my = mid
    mem = [(rx, ry), (tx, ty), (mx + 6 * flip, my + 12), (mx - 2 * flip, my + 4),
           (rx + 10 * flip, ry + 14)]
    poly(im, mem, fill=WING_MEM, outline=OUT_Y, ow=1.0)
    shade(im, mem, WING_MEM_D[:3], (226, 168, 130), dark_a=70, light_a=45)
    line(im, (rx, ry), (tx, ty), WING_BONE, 2.4)
    line(im, (rx + 4 * flip, ry + 6), (mx + 6 * flip, my + 12), A(WING_BONE, 170), 1.2)
    line(im, (rx + 2 * flip, ry + 3), (mx - 2 * flip, my + 4), A(WING_BONE, 170), 1.2)
    ell(im, tx, ty, 2.2, 2.2, fill=WING_BONE)  # mong vuot dau canh

def _wyvern_eye(im, cx, cy, r=2.4, fierce=False):
    ell(im, cx, cy, r, r * 1.1, fill=EYE_Y, outline=OUT_Y, ow=0.6)
    ell(im, cx, cy, r * 0.4, r * 0.62, fill=(18, 20, 16, 255))
    if fierce:
        line(im, (cx - r * 1.3, cy - r * 1.6), (cx + r * 1.2, cy - r * 0.8), WY_D, 1.2)

def _wyvern_tail(im, root, sway=0.0, down=False):
    rx, ry = root
    pts = bezier((rx, ry), (rx + sway, ry + (14 if down else -8)),
                 (rx - 6 + sway * 1.6, ry + (24 if down else -16)),
                 (rx - 14 + sway * 2.0, ry + (20 if down else -22)))
    d = ImageDraw.Draw(im)
    for wdt, col in ((5.5, WY_D), (3.8, WY)):
        d.line(P_(pts), fill=col, width=max(1, int(wdt * SS)), joint="curve")
    tip = pts[-1]  # cho mui ten duoi
    poly(im, [(tip[0] - 3.4, tip[1] + (3 if down else -3)), (tip[0] + 3.4, tip[1] + (3 if down else -3)),
              (tip[0], tip[1] + (-4 if down else 4))], fill=WY_D, outline=OUT_Y, ow=0.7)

def wyvern_pose(direction, mode, i, n):
    im = new_canvas()
    ph = math.sin(i / max(n, 1) * math.pi * 2) if n > 1 else 0.0
    bob = 0.0
    flap = 0.0
    if mode == "idle":
        bob = [0.0, -1.6][i % 2]       # bay: nhap nhay len xuong
        flap = [0.0, 5.0][i % 2]
    elif mode == "walk":
        bob = -abs(ph) * 2.2
        flap = ph * 5.0
    lunge = 0.0
    if mode == "attack":
        lunge = [3.0, 9.0][i % 2]
        flap = [6.0, -3.0][i % 2]
    step = ph if mode == "walk" else 0.0

    if direction == "down":
        cy = 56 + bob + lunge * 0.3
        _wyvern_tail(im, (64, cy - 24), sway=ph * 2 if mode == "walk" else 1.0)
        _wyvern_wing(im, (48, cy - 8), (16, cy - 20 - flap), (30, cy + 2), flip=-1)
        _wyvern_wing(im, (80, cy - 8), (112, cy - 20 - flap), (98, cy + 2), flip=1)
        for sx, off in ((-1, step), (1, -step)):
            line(im, (64 + sx * 12, cy + 14), (64 + sx * 16, cy + 26 + off * 2), WY_D, 3.0)
            ell(im, 64 + sx * 17, cy + 27 + off * 2, 3.0, 2.2, fill=WY_D, outline=OUT_Y, ow=0.6)
        body = ell_pts(64, cy, 17, 26)
        poly(im, body, fill=WY, outline=OUT_Y, ow=1.2)
        shade(im, body, WY_D[:3], WY_L[:3], rim_rgb=WY_L[:3], dark_a=90, light_a=60)
        belly = ell_pts(64, cy + 8, 10, 17)
        poly(im, belly, fill=A(WY_BELLY, 150))
        for k in range(3):  # vay bung
            line(im, (57, cy + 2 + k * 7), (71, cy + 2 + k * 7), A(WY_D, 130), 0.9)
        hy = cy + 26 + lunge * 0.5
        for sgn in (-1, 1):
            poly(im, [(64 + sgn * 9, hy - 8), (64 + sgn * 13, hy - 15), (64 + sgn * 6, hy - 12)],
                 fill=HORN, outline=OUT_Y, ow=0.7)
        head = ell_pts(64, hy, 13.5, 11.5)
        poly(im, head, fill=WY, outline=OUT_Y, ow=1.2)
        shade(im, head, WY_D[:3], WY_L[:3], dark_a=80, light_a=55)
        snout = [(58.5, hy + 3), (69.5, hy + 3), (67, hy + 11 + lunge * 0.3), (61, hy + 11 + lunge * 0.3)]
        poly(im, snout, fill=WY_L, outline=OUT_Y, ow=0.9)
        ell(im, 61.5, hy + 6.5, 1.3, 1.0, fill=WY_D)
        ell(im, 66.5, hy + 6.5, 1.3, 1.0, fill=WY_D)
        _wyvern_eye(im, 64 - 6.5, hy - 2.5, 2.4, fierce=(mode == "attack"))
        _wyvern_eye(im, 64 + 6.5, hy - 2.5, 2.4, fierce=(mode == "attack"))
        if mode == "attack" and i == 1:
            poly(im, [(61, hy + 8), (63.2, hy + 8), (62.1, hy + 11.4)], fill=(246, 244, 234, 255))
            poly(im, [(64.8, hy + 8), (67, hy + 8), (65.9, hy + 11.4)], fill=(246, 244, 234, 255))
    elif direction == "up":
        cy = 62 + bob - lunge * 0.3
        _wyvern_tail(im, (64, cy + 22), sway=-(ph * 2 if mode == "walk" else 1.0), down=True)
        _wyvern_wing(im, (48, cy - 4), (16, cy - 16 - flap), (30, cy + 6), flip=-1)
        _wyvern_wing(im, (80, cy - 4), (112, cy - 16 - flap), (98, cy + 6), flip=1)
        body = ell_pts(64, cy, 17, 26)
        poly(im, body, fill=WY_D, outline=OUT_Y, ow=1.2)
        shade(im, body, (36, 62, 60), WY[:3], dark_a=95, light_a=50)
        for k in range(4):  # gai song lung
            gy = cy - 18 + k * 10
            poly(im, [(61.5, gy), (66.5, gy), (64, gy - 4.5)], fill=HORN, outline=OUT_Y, ow=0.6)
        hy = cy - 26 - lunge * 0.5
        for sgn in (-1, 1):
            poly(im, [(64 + sgn * 9, hy + 6), (64 + sgn * 13, hy + 12), (64 + sgn * 6, hy + 10)],
                 fill=HORN, outline=OUT_Y, ow=0.7)
        head = ell_pts(64, hy, 13.0, 11.0)
        poly(im, head, fill=WY_D, outline=OUT_Y, ow=1.2)
        shade(im, head, (36, 62, 60), WY[:3], dark_a=90, light_a=45)
    else:  # side
        cy = 58 + bob
        _wyvern_tail(im, (36, cy + 2), sway=step)
        # canh xa (toi, nho hon)
        _wyvern_wing(im, (56, cy - 12), (34, cy - 30 - flap), (44, cy - 6), flip=-1)
        for off, fx in ((step, 52), (-step, 74)):
            line(im, (fx, cy + 10), (fx + 2, cy + 22 + off * 2), WY_D, 3.0)
            ell(im, fx + 3, cy + 23 + off * 2, 3.0, 2.2, fill=WY_D, outline=OUT_Y, ow=0.6)
        body = ell_pts(60, cy, 27, 16)
        poly(im, body, fill=WY, outline=OUT_Y, ow=1.2)
        shade(im, body, WY_D[:3], WY_L[:3], rim_rgb=WY_L[:3], dark_a=90, light_a=60)
        belly = ell_pts(61, cy + 6, 17, 8)
        poly(im, belly, fill=A(WY_BELLY, 140))
        # canh gan lon vuot len tren lung
        _wyvern_wing(im, (64, cy - 10), (44, cy - 38 - flap), (58, cy - 14), flip=-1)
        hx = 88 + lunge
        poly(im, [(hx - 6, cy - 14), (hx - 2, cy - 22), (hx + 3, cy - 13)], fill=HORN, outline=OUT_Y, ow=0.7)
        head = ell_pts(hx, cy - 6, 12.5, 10.5)
        poly(im, head, fill=WY, outline=OUT_Y, ow=1.2)
        shade(im, head, WY_D[:3], WY_L[:3], dark_a=80, light_a=55)
        snout = [(hx + 6, cy - 2), (hx + 15 + lunge * 0.3, cy), (hx + 12, cy + 5), (hx + 5, cy + 4)]
        poly(im, snout, fill=WY_L, outline=OUT_Y, ow=0.9)
        ell(im, hx + 12.5 + lunge * 0.3, cy + 0.5, 2.4, 1.8, fill=WY_D)
        _wyvern_eye(im, hx + 1, cy - 7.5, 2.4, fierce=(mode == "attack"))
        if mode == "attack" and i == 1:
            poly(im, [(hx + 7, cy + 4.5), (hx + 9.5, cy + 4.5), (hx + 8.2, cy + 8)], fill=(246, 244, 234, 255))
    return im

def wyvern_hurt_frame():
    im = wyvern_pose("down", "idle", 0, 2)
    _x_eyes(im, [(57.5, 79.5), (70.5, 79.5)], WY_L, OUT_Y)
    s = new_canvas(); s.alpha_composite(im, dest=(int(-2.0 * SS), 0))
    return s

def wyvern_death_frame(i):
    if i == 0:
        im = wyvern_pose("down", "idle", 0, 2)
        s = new_canvas(); s.alpha_composite(im, dest=(0, int(3.0 * SS))); im = s
        _x_eyes(im, [(57.5, 82.5), (70.5, 82.5)], WY_L, OUT_Y)
        return _fit(im, bottom=118)
    base = wyvern_pose("down", "idle", 0, 2)
    return _rot(base, 88, dy=5, alpha=0.55, fit_bottom=119)  # roi xuong dat

# ============================================================ BUILD SHEETS + TRES

ROWS = ["idle_down", "idle_up", "idle_side",
        "walk_down", "walk_up", "walk_side",
        "attack_down", "attack_up", "attack_side",
        "hurt", "death"]
ANIM_META = {"idle": (4.0, True), "walk": (9.0, True), "attack": (10.0, False),
             "hurt": (8.0, False), "death": (5.0, False)}

def build_rows(kind):
    r = {}
    for ddir in ("down", "up", "side"):
        if kind == "rat":
            r[f"idle_{ddir}"] = [rat_pose(ddir, "idle", k, 2) for k in range(2)]
            r[f"walk_{ddir}"] = [rat_pose(ddir, "walk", k, 4) for k in range(4)]
            r[f"attack_{ddir}"] = [rat_pose(ddir, "attack", k, 2) for k in range(2)]
        elif kind == "slime":
            r[f"idle_{ddir}"] = [slime_pose(ddir, "idle", k, 2) for k in range(2)]
            r[f"walk_{ddir}"] = [slime_pose(ddir, "walk", k, 4) for k in range(4)]
            r[f"attack_{ddir}"] = [slime_pose(ddir, "attack", k, 2) for k in range(2)]
        elif kind == "golem":
            r[f"idle_{ddir}"] = [golem_pose(ddir, "idle", k, 2) for k in range(2)]
            r[f"walk_{ddir}"] = [golem_pose(ddir, "walk", k, 4) for k in range(4)]
            r[f"attack_{ddir}"] = [golem_pose(ddir, "attack", k, 2) for k in range(2)]
        elif kind == "wolf":
            r[f"idle_{ddir}"] = [wolf_pose(ddir, "idle", k, 2) for k in range(2)]
            r[f"walk_{ddir}"] = [wolf_pose(ddir, "walk", k, 4) for k in range(4)]
            r[f"attack_{ddir}"] = [wolf_pose(ddir, "attack", k, 2) for k in range(2)]
        elif kind == "spider":
            r[f"idle_{ddir}"] = [spider_pose(ddir, "idle", k, 2) for k in range(2)]
            r[f"walk_{ddir}"] = [spider_pose(ddir, "walk", k, 4) for k in range(4)]
            r[f"attack_{ddir}"] = [spider_pose(ddir, "attack", k, 2) for k in range(2)]
        elif kind == "wyvern":
            r[f"idle_{ddir}"] = [wyvern_pose(ddir, "idle", k, 2) for k in range(2)]
            r[f"walk_{ddir}"] = [wyvern_pose(ddir, "walk", k, 4) for k in range(4)]
            r[f"attack_{ddir}"] = [wyvern_pose(ddir, "attack", k, 2) for k in range(2)]
    if kind == "rat":
        r["hurt"] = [rat_hurt_frame()]
        r["death"] = [rat_death_frame(k) for k in range(2)]
    elif kind == "slime":
        r["hurt"] = [slime_hurt_frame()]
        r["death"] = [slime_death_frame(k) for k in range(2)]
    elif kind == "golem":
        r["hurt"] = [golem_hurt_frame()]
        r["death"] = [golem_death_frame(k) for k in range(2)]
    elif kind == "wolf":
        r["hurt"] = [wolf_hurt_frame()]
        r["death"] = [wolf_death_frame(k) for k in range(2)]
    elif kind == "spider":
        r["hurt"] = [spider_hurt_frame()]
        r["death"] = [spider_death_frame(k) for k in range(2)]
    elif kind == "wyvern":
        r["hurt"] = [wyvern_hurt_frame()]
        r["death"] = [wyvern_death_frame(k) for k in range(2)]
    return r

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

def main():
    for kind in ("rat", "slime", "golem", "wolf", "spider", "wyvern"):
        rows = build_rows(kind)
        sheet, _cols = compose_sheet(rows, ROWS)
        png = os.path.join(OUT_DIR, f"{kind}_spritesheet.png")
        sheet.save(png)
        n = write_tres(os.path.join(OUT_DIR, f"{kind}_frames.tres"), rows, ROWS,
                       f"res://assets/sprites/{kind}_spritesheet.png")
        print(f"{kind}: sheet {sheet.size} -> {png} | atlas textures: {n} | rows: {ROWS}")

if __name__ == "__main__":
    main()
