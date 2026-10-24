#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh texture UI cho game "Dưới Bóng Phong Ấn" — phong cách fantasy trung cổ:
gỗ sẫm / da + viền đồng-vàng chạm khắc, gradient có chiều sâu, vẽ MƯỢT
(không pixel hoá).

Kỹ thuật (theo phong cách tools/gen_sprites_v3.py):
- Vẽ SUPERSAMPLE 3–4x bằng PIL + numpy (gradient / gloss / nhiễu hạt tính
  theo pixel ở độ phân giải lớn), rồi downscale về kích thước cuối bằng
  LANCZOS + unsharp nhẹ -> cạnh mịn, không răng cưa, không pixel-art.
- panel_frame.png: TOÀN BỘ viền + họa tiết góc + đinh tán nằm gọn trong
  vùng biên 32px (nine-patch margins = 32, dùng được cho cả panel thấp
  ~76px bọc thanh HP/STA). Phần giữa (từ 32px trở vào) chỉ là nền mượt.

Bảng màu chốt:
  vàng đồng sáng #e8c766, đồng #c9a227, đồng sẫm #7a5c1e,
  gỗ óc chó #2e1c10 -> #1c110a, da sẫm #241610, nền tối #120b06.

Chạy: python3 tools/gen_ui_assets.py
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SS = 4  # supersample mặc định

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "game", "assets", "ui")
os.makedirs(OUT_DIR, exist_ok=True)

random.seed(20261024)
np.random.seed(20261024)

# ---------------- palette ----------------
GOLD_HI = (232, 199, 102, 255)   # #e8c766
GOLD = (201, 162, 39, 255)       # #c9a227
GOLD_D = (122, 92, 30, 255)      # #7a5c1e
GOLD_XD = (74, 54, 16, 255)
WALNUT = (46, 28, 16, 255)       # #2e1c10
WALNUT_D = (28, 17, 10, 255)     # #1c110a
LEATHER = (36, 22, 16, 255)      # #241610
BG_DARK = (18, 11, 6, 255)       # #120b06
OUTLINE = (10, 6, 3, 255)


def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


# ---------------- helpers ở không gian cuối (tự nhân SS) ----------------

def S(v, ss):
    return v * ss


def rrect(d, box, ss, radius, **kw):
    d.rounded_rectangle([box[0] * ss, box[1] * ss, box[2] * ss, box[3] * ss],
                        radius=radius * ss, **kw)


def ell(d, cx, cy, rx, ry, ss, **kw):
    d.ellipse([(cx - rx) * ss, (cy - ry) * ss, (cx + rx) * ss, (cy + ry) * ss], **kw)


def line_round(d, p0, p1, ss, fill, w):
    d.line([p0[0] * ss, p0[1] * ss, p1[0] * ss, p1[1] * ss],
           fill=fill, width=max(1, int(w * ss)))
    for p in (p0, p1):
        ell(d, p[0], p[1], w / 2.0, w / 2.0, ss, fill=fill)


def diamond(d, cx, cy, rw, rh, ss, **kw):
    d.polygon([(cx * ss, (cy - rh) * ss), ((cx + rw) * ss, cy * ss),
               (cx * ss, (cy + rh) * ss), ((cx - rw) * ss, cy * ss)], **kw)


def rivet(d, cx, cy, r, ss, base=GOLD, hi=GOLD_HI, dark=GOLD_XD):
    ell(d, cx, cy, r, r, ss, fill=dark)
    ell(d, cx, cy, r * 0.78, r * 0.78, ss, fill=base)
    ell(d, cx - r * 0.25, cy - r * 0.25, r * 0.28, r * 0.28, ss, fill=hi)


def corner_diamond(d, cx, cy, r, ss, fill=GOLD, ring=GOLD_HI, dot=GOLD_XD):
    """Họa tiết góc: hình thoi + vòng tròn nhỏ ở tâm."""
    diamond(d, cx, cy, r, r, ss, fill=GOLD_XD)
    diamond(d, cx, cy, r * 0.78, r * 0.78, ss, fill=fill)
    ell(d, cx, cy, r * 0.34, r * 0.34, ss, fill=ring)
    ell(d, cx, cy, r * 0.17, r * 0.17, ss, fill=dot)


def finish(im_ss, size, unsharp=32):
    out = im_ss.resize(size, Image.LANCZOS)
    if unsharp:
        out = out.filter(ImageFilter.UnsharpMask(radius=2, percent=unsharp, threshold=3))
    return out


def save(im, name):
    path = os.path.join(OUT_DIR, name)
    im.save(path)
    print(f"{name}: {im.size[0]}x{im.size[1]}")
    return path


def grain(arr, seed=7, amp=3.0, low_amp=4.0):
    """Nhiễu hạt rất nhẹ + mảng tần số thấp (vân da/gỗ) cộng vào mảng float RGB."""
    rng = np.random.RandomState(seed)
    h, w = arr.shape[:2]
    noise = rng.normal(0.0, amp, (h, w, 1))
    low = rng.normal(0.0, 1.0, (max(2, h // 48), max(2, w // 48), 1))
    low_im = Image.fromarray(((low - low.min()) / (low.ptp() + 1e-6) * 255).astype(np.uint8)[:, :, 0])
    low_big = np.asarray(low_im.resize((w, h), Image.BILINEAR), dtype=np.float32)[:, :, None]
    low_big = (low_big / 255.0 - 0.5) * 2.0 * low_amp
    return arr + noise + low_big


def to_image(arr):
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


# ============================================================ 1. PANEL FRAME
# Biên nine-patch = 32px: MỌI viền / họa tiết góc / đinh tán đều nằm trong
# dải 0..32 (và đối xứng ở 3 phía còn lại). Giữa chỉ là nền gradient mượt.

PANEL_BORDER = 32


def make_panel():
    W, H, ss = 720, 480, 3
    w, h = W * ss, H * ss
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    u, v = xx / w, yy / h
    # radial: giữa sáng hơn, rìa tối + vignette
    r = np.sqrt(((u - 0.5) * 1.18) ** 2 + ((v - 0.5) * 1.18) ** 2)
    r = np.clip(r / 0.84, 0, 1)
    centre = np.array([58.0, 38.0, 22.0])    # gỗ sáng ở giữa
    mid = np.array([36.0, 22.0, 16.0])       # da sẫm #241610
    edge = np.array([18.0, 11.0, 6.0])       # nền tối #120b06
    arr = np.zeros((h, w, 4), np.float32)
    t1 = np.clip(r * 1.6, 0, 1)[:, :, None]
    t2 = np.clip((r - 0.45) * 2.2, 0, 1)[:, :, None]
    base = centre[None, None, :] * (1 - t1) + mid[None, None, :] * t1
    base = base * (1 - t2) + edge[None, None, :] * t2
    # vệt sáng dọc rất nhẹ phía trên
    base += (np.clip(1.0 - v, 0, 1) * 5.0)[:, :, None]
    arr[:, :, :3] = grain(base, seed=11, amp=2.6, low_amp=4.5)
    arr[:, :, 3] = 255
    im = to_image(arr)
    d = ImageDraw.Draw(im, "RGBA")

    B = PANEL_BORDER  # 32
    # --- viền đồng-vàng 2 lớp, toàn bộ trong dải biên 32px ---
    # outline ngoài tối
    rrect(d, (1, 1, W - 1, H - 1), ss, 13, outline=OUTLINE, width=int(2.4 * ss))
    # lớp dày ~9px: đồng sẫm -> đồng -> sáng (vẽ chồng 3 outline)
    rrect(d, (4.5, 4.5, W - 4.5, H - 4.5), ss, 11, outline=GOLD_D, width=int(9 * ss))
    rrect(d, (5.5, 5.5, W - 5.5, H - 5.5), ss, 10, outline=GOLD, width=int(6.5 * ss))
    rrect(d, (4.8, 4.8, W - 4.8, H - 4.8), ss, 11, outline=(GOLD_HI[0], GOLD_HI[1], GOLD_HI[2], 150),
          width=int(2.0 * ss))
    # pinline mảnh bên trong lớp dày
    rrect(d, (11.5, 11.5, W - 11.5, H - 11.5), ss, 8, outline=GOLD_XD, width=int(1.6 * ss))
    rrect(d, (14, 14, W - 14, H - 14), ss, 7, outline=(GOLD_HI[0], GOLD_HI[1], GOLD_HI[2], 170),
          width=int(1.2 * ss))
    # đường khung trong mảnh + bóng trong ngay sát biên trong (<= 30px)
    rrect(d, (21, 21, W - 21, H - 21), ss, 6, outline=(0, 0, 0, 110), width=int(2.6 * ss))
    rrect(d, (24.5, 24.5, W - 24.5, H - 24.5), ss, 5,
          outline=(GOLD[0], GOLD[1], GOLD[2], 120), width=int(1.1 * ss))
    rrect(d, (29, 29, W - 29, H - 29), ss, 4, outline=(0, 0, 0, 70), width=int(1.4 * ss))

    # --- họa tiết góc: thoi + vòng tròn, gọn trong ô góc 32x32 ---
    for cx, cy in ((16, 16), (W - 16, 16), (16, H - 16), (W - 16, H - 16)):
        corner_diamond(d, cx, cy, 9.0, ss)
    # chấm nhỏ phụ ở 2 đầu mỗi góc (vẫn trong biên 32)
    for cx, cy in ((27, 16), (16, 27), (W - 27, 16), (W - 16, 27),
                   (27, H - 16), (16, H - 27), (W - 27, H - 16), (W - 16, H - 27)):
        ell(d, cx, cy, 1.7, 1.7, ss, fill=GOLD_HI)
        ell(d, cx, cy, 0.8, 0.8, ss, fill=GOLD_XD)

    # --- đinh tán giữa các cạnh (trên dải viền) ---
    rivet(d, W / 2, 9, 4.2, ss)
    rivet(d, W / 2, H - 9, 4.2, ss)
    rivet(d, 9, H / 2, 4.2, ss)
    rivet(d, W - 9, H / 2, 4.2, ss)

    assert B == 32
    im.putalpha(255)  # panel là texture đặc hoàn toàn, không có vùng trong suốt
    return finish(im, (W, H), unsharp=30)


# ============================================================ 2. RING FRAME

def make_ring():
    W = H = 512
    ss = 4
    w = W * ss
    yy, xx = np.mgrid[0:w, 0:w].astype(np.float32)
    cx = cy = w / 2.0
    dx, dy = xx - cx, yy - cy
    r = np.sqrt(dx ** 2 + dy ** 2) / ss          # bán kính theo px cuối
    ang = np.arctan2(dy, dx)                      # 0 = phải, tăng theo chiều kim (y xuống)
    R_OUT, R_IN = 250.0, 206.0
    # gradient hướng sáng: sáng hơn phía trên-trái
    lx, ly = -0.7071, -0.7071
    dot = (dx * lx + dy * ly) / np.maximum(r * ss, 1.0)
    mid = (R_OUT + R_IN) / 2.0
    radial_t = 1.0 - np.clip(np.abs(r - mid) / ((R_OUT - R_IN) / 2.0), 0, 1)  # 1 ở giữa vành
    light = np.clip(0.52 + 0.34 * dot + 0.30 * radial_t, 0, 1)
    c_dark = np.array(GOLD_D[:3], np.float32)
    c_mid = np.array(GOLD[:3], np.float32)
    c_hi = np.array(GOLD_HI[:3], np.float32)
    t = light[:, :, None]
    col = np.where(t < 0.55,
                   c_dark[None, None, :] + (c_mid - c_dark)[None, None, :] * (t / 0.55),
                   c_mid[None, None, :] + (c_hi - c_mid)[None, None, :] * ((t - 0.55) / 0.45))
    alpha = np.where((r >= R_IN) & (r <= R_OUT), 255.0, 0.0)
    # làm mềm mép 1px cuối bằng độ phủ theo khoảng cách (trước downscale đã AA thêm)
    alpha = np.where(r < R_IN, np.clip((r - (R_IN - 1.2)) / 1.2, 0, 1) * 255.0, alpha)
    alpha = np.where(r > R_OUT, np.clip(((R_OUT + 1.2) - r) / 1.2, 0, 1) * 255.0, alpha)
    arr = np.zeros((w, w, 4), np.float32)
    arr[:, :, :3] = grain(col, seed=23, amp=2.2, low_amp=2.5)
    arr[:, :, 3] = alpha
    im = to_image(arr)
    d = ImageDraw.Draw(im, "RGBA")
    C = W / 2.0

    # vạch khắc mỗi 15 độ (trừ 4 hướng chéo có thoi)
    for deg in range(0, 360, 15):
        if deg % 90 == 45:
            continue
        a = math.radians(deg)
        long_tick = (deg % 45 == 0)
        r0, r1 = (229.0, 246.0) if long_tick else (236.0, 246.0)
        p0 = (C + r0 * math.cos(a), C + r0 * math.sin(a))
        p1 = (C + r1 * math.cos(a), C + r1 * math.sin(a))
        line_round(d, (p0[0], p0[1] + 0.8), (p1[0], p1[1] + 0.8), ss,
                   (255, 240, 190, 90), 1.1)   # highlight lệch dưới (khắc chìm)
        line_round(d, p0, p1, ss, (74, 54, 16, 190), 1.5 if long_tick else 1.1)

    # họa tiết thoi ở 4 hướng chéo trên vành
    for deg in (45, 135, 225, 315):
        a = math.radians(deg)
        ccx, ccy = C + mid * math.cos(a), C + mid * math.sin(a)
        # thoi hướng tâm: trục dài theo hướng bán kính
        ux, uy = math.cos(a), math.sin(a)
        vx, vy = -uy, ux
        L, T = 15.0, 9.5
        pts = [(ccx + ux * L, ccy + uy * L), (ccx + vx * T, ccy + vy * T),
               (ccx - ux * L, ccy - uy * L), (ccx - vx * T, ccy - vy * T)]
        d.polygon([(x * ss, y * ss) for x, y in pts], fill=GOLD_XD)
        pts2 = [(ccx + (x - ccx) * 0.74, ccy + (y - ccy) * 0.74) for x, y in pts]
        d.polygon([(x * ss, y * ss) for x, y in pts2], fill=GOLD_HI)
        ell(d, ccx, ccy, 3.0, 3.0, ss, fill=GOLD)
        ell(d, ccx, ccy, 1.4, 1.4, ss, fill=GOLD_XD)

    # viền trong: inner shadow mảnh; viền ngoài: outline tối mảnh
    d.ellipse([(C - R_IN) * ss, (C - R_IN) * ss, (C + R_IN) * ss, (C + R_IN) * ss],
              outline=(0, 0, 0, 165), width=int(3.2 * ss))
    d.ellipse([(C - R_IN - 3.4) * ss, (C - R_IN - 3.4) * ss,
               (C + R_IN + 3.4) * ss, (C + R_IN + 3.4) * ss],
              outline=(0, 0, 0, 70), width=int(2.0 * ss))
    d.ellipse([(C - R_OUT) * ss, (C - R_OUT) * ss, (C + R_OUT) * ss, (C + R_OUT) * ss],
              outline=(12, 8, 3, 220), width=int(2.6 * ss))
    # highlight mảnh phía trên-trái ở mép ngoài
    d.arc([(C - R_OUT + 2) * ss, (C - R_OUT + 2) * ss, (C + R_OUT - 2) * ss, (C + R_OUT - 2) * ss],
          start=150, end=285, fill=(255, 244, 200, 130), width=int(1.6 * ss))
    # Chuẩn hoá alpha theo hình học vành: trong vành đặc 255, ngoài vành 0,
    # chỉ AA ~1.4px ở hai mép (nét vẽ bán trong suốt không được làm vành bị trong).
    arr_im = np.asarray(im).copy()
    yy2, xx2 = np.mgrid[0:w, 0:w].astype(np.float32)
    rr2 = np.sqrt((xx2 - cx) ** 2 + (yy2 - cy) ** 2) / ss
    arr_im[:, :, 3] = (np.clip((np.minimum(rr2 - R_IN, R_OUT - rr2) + 0.7) / 1.4, 0, 1) * 255).astype(np.uint8)
    im = Image.fromarray(arr_im, "RGBA")
    return finish(im, (W, H), unsharp=26)


# ============================================================ 3/4. BAR FRAMES

def make_bar_frame(W, H, frame_w, orn_r):
    ss = 4
    im = Image.new("RGBA", (W * ss, H * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(im, "RGBA")
    rad = H / 2.0
    cy = H / 2.0
    # xếp lớp filled bo tròn: outline tối -> đồng sẫm -> đồng -> sáng -> lòng tối
    rrect(d, (0.8, 0.8, W - 0.8, H - 0.8), ss, rad, fill=OUTLINE)
    rrect(d, (2.0, 2.0, W - 2.0, H - 2.0), ss, rad - 1, fill=GOLD_D)
    rrect(d, (3.2, 3.2, W - 3.2, H - 3.2), ss, rad - 2, fill=GOLD)
    rrect(d, (3.2, 3.2, W - 3.2, H / 2.0 + 2), ss, rad - 2, fill=(GOLD_HI[0], GOLD_HI[1], GOLD_HI[2], 120))
    inset = frame_w
    rrect(d, (inset, inset, W - inset, H - inset), ss, rad - inset + 1, fill=BG_DARK)
    # bóng trong phía trên lòng thanh + vệt sáng mảnh phía dưới lòng
    for i in range(5):
        a = int(120 * (1 - i / 5.0))
        rrect(d, (inset + 1 + i * 0.7, inset + 1 + i * 0.7, W - inset - 1 - i * 0.7,
                  H - inset - 1 - i * 0.4), ss, max(2, rad - inset - i), outline=(0, 0, 0, a),
              width=int(1.1 * ss))
    # họa tiết thoi nhỏ / đinh tán ở hai đầu (trên lòng tối sát đầu)
    for cx in (inset + orn_r + 3.5, W - inset - orn_r - 3.5):
        diamond(d, cx, cy, orn_r, orn_r * 0.78, ss, fill=GOLD_XD)
        diamond(d, cx, cy, orn_r * 0.72, orn_r * 0.55, ss, fill=GOLD)
        ell(d, cx, cy, orn_r * 0.22, orn_r * 0.22, ss, fill=GOLD_HI)
    # alpha theo đúng hình pill: trong đặc 255, góc ngoài pill trong suốt 0
    pill = Image.new("L", im.size, 0)
    pd = ImageDraw.Draw(pill)
    rrect(pd, (0.8, 0.8, W - 0.8, H - 0.8), ss, rad, fill=255)
    im.putalpha(pill)
    return finish(im, (W, H), unsharp=30)


# ============================================================ 5/6/7. BAR FILLS

def make_bar_fill(top_hex, bot_hex, seed):
    W, H = 256, 48
    ss = 4
    w, h = W * ss, H * ss
    top = np.array(hex2rgb(top_hex), np.float32)
    bot = np.array(hex2rgb(bot_hex), np.float32)
    yy = np.linspace(0, 1, h, dtype=np.float32)[:, None, None]
    # gradient dọc hơi cong (sáng lâu ở trên, tối nhanh ở đáy)
    t = np.power(yy, 0.85)
    arr = np.zeros((h, w, 4), np.float32)
    arr[:, :, :3] = top[None, None, :] * (1 - t) + bot[None, None, :] * t
    # gloss: dải trắng mờ ở 40% phía trên, mạnh nhất quanh 12% rồi tắt dần
    gy = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    gloss = np.clip(1.0 - gy / 0.40, 0, 1) ** 1.4 * 0.34
    gloss = gloss * (0.75 + 0.25 * np.cos(np.linspace(-0.4, 0.4, w, dtype=np.float32)))[None, :]
    arr[:, :, :3] += (255.0 - arr[:, :, :3]) * gloss[:, :, None]
    arr[:, :, :3] = grain(arr[:, :, :3], seed=seed, amp=1.6, low_amp=1.2)
    arr[:, :, 3] = 255
    im = to_image(arr)
    d = ImageDraw.Draw(im, "RGBA")
    d.line([0, 0.8 * ss, w, 0.8 * ss], fill=(255, 255, 255, 70), width=int(1.0 * ss))
    d.line([0, (H - 0.8) * ss, w, (H - 0.8) * ss], fill=(0, 0, 0, 80), width=int(1.0 * ss))
    im.putalpha(255)  # fill là hình chữ nhật đặc, Godot tự cắt theo lòng khung
    return finish(im, (W, H), unsharp=0)


# ============================================================ 8. BUTTONS +/-

def disc_gradient(size, ss, bright, seed):
    """Đĩa đồng-vàng: gradient hướng sáng trên-trái + radial bevel."""
    w = size * ss
    yy, xx = np.mgrid[0:w, 0:w].astype(np.float32)
    u, v = xx / w, yy / w
    r = np.sqrt((u - 0.5) ** 2 + (v - 0.5) ** 2) * 2.0
    dot = np.clip(0.5 - (u * 0.55 + v * 0.75), -0.6, 0.6)  # sáng trên-trái
    light = np.clip(0.58 + dot * 0.75 - np.clip(r - 0.72, 0, 1) * 0.38, 0, 1) * bright
    c_dark = np.array(GOLD_D[:3], np.float32)
    c_mid = np.array(GOLD[:3], np.float32)
    c_hi = np.array(GOLD_HI[:3], np.float32)
    t = light[:, :, None]
    col = np.where(t < 0.55,
                   c_dark[None, None, :] + (c_mid - c_dark)[None, None, :] * (t / 0.55),
                   c_mid[None, None, :] + (c_hi - c_mid)[None, None, :] * ((t - 0.55) / 0.45))
    arr = np.zeros((w, w, 4), np.float32)
    arr[:, :, :3] = grain(col, seed=seed, amp=2.0, low_amp=2.0)
    arr[:, :, 3] = 255
    return to_image(arr)


def make_button(symbol, state):
    size = 96
    ss = 4
    C = size / 2.0
    bright = {"normal": 1.0, "hover": 1.13, "pressed": 0.80}[state]
    im = Image.new("RGBA", (size * ss, size * ss), (0, 0, 0, 0))

    if state == "hover":
        glow = Image.new("RGBA", im.size, (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        ell(gd, C, C, 47, 47, ss, fill=(232, 199, 102, 150))
        glow = glow.filter(ImageFilter.GaussianBlur(5.5 * ss))
        im.alpha_composite(glow)
        ring = Image.new("RGBA", im.size, (0, 0, 0, 0))
        rd = ImageDraw.Draw(ring)
        ell(rd, C, C, 45.5, 45.5, ss, outline=(255, 226, 130, 235), width=int(1.8 * ss))
        im.alpha_composite(ring.filter(ImageFilter.GaussianBlur(0.7 * ss)))

    disc = disc_gradient(size, ss, bright, seed=31 if symbol == "+" else 37)
    mask = Image.new("L", im.size, 0)
    md = ImageDraw.Draw(mask)
    R_OUT = 41.0 if state != "pressed" else 40.0
    ell(md, C, C, R_OUT, R_OUT, ss, fill=255)
    im.paste(disc, (0, 0), mask)
    d = ImageDraw.Draw(im, "RGBA")

    # outline tối ngoài + vòng bevel
    ell(d, C, C, R_OUT, R_OUT, ss, outline=(12, 8, 3, 235), width=int(2.2 * ss))
    ell(d, C, C, R_OUT - 3.4, R_OUT - 3.4, ss, outline=GOLD_XD, width=int(1.6 * ss))
    # highlight bevel trên-trái / bóng dưới-phải
    d.arc([(C - R_OUT + 4) * ss, (C - R_OUT + 4) * ss, (C + R_OUT - 4) * ss, (C + R_OUT - 4) * ss],
          start=140, end=305, fill=(255, 246, 205, 190), width=int(2.4 * ss))
    d.arc([(C - R_OUT + 4) * ss, (C - R_OUT + 4) * ss, (C + R_OUT - 4) * ss, (C + R_OUT - 4) * ss],
          start=-35, end=130, fill=(60, 42, 10, 170), width=int(2.4 * ss))
    # đĩa trong (mặt khắc)
    R_IN = 29.0
    ell(d, C, C, R_IN, R_IN, ss, outline=(GOLD_XD[0], GOLD_XD[1], GOLD_XD[2], 200),
        width=int(1.8 * ss))
    if state == "pressed":
        # bóng trong đè mặt đĩa: vòng tối trong (mặt đĩa tự tối hơn nhờ bright=0.80)
        ell(d, C, C, R_IN - 1.5, R_IN - 1.5, ss, outline=(0, 0, 0, 120), width=int(3.0 * ss))
        d.arc([(C - R_IN + 2) * ss, (C - R_IN + 2) * ss, (C + R_IN - 2) * ss, (C + R_IN - 2) * ss],
              start=180, end=360, fill=(0, 0, 0, 90), width=int(2.6 * ss))
    else:
        d.arc([(C - R_IN) * ss, (C - R_IN) * ss, (C + R_IN) * ss, (C + R_IN) * ss],
              start=150, end=300, fill=(255, 246, 205, 110), width=int(1.4 * ss))

    # ký hiệu khắc chìm: vệt sáng lệch dưới-phải (mép khắc bắt sáng) + nét tối chính
    half = 13.0
    wdt = 6.6 if state != "pressed" else 7.2
    dark = (58, 40, 10, 255) if state != "pressed" else (40, 27, 6, 255)
    lite = (255, 240, 185, 150) if state != "pressed" else (255, 240, 185, 80)
    segs = [((C - half, C), (C + half, C))]
    if symbol == "+":
        segs.append(((C, C - half), (C, C + half)))
    off = 1.5
    for p0, p1 in segs:
        line_round(d, (p0[0] + off, p0[1] + off), (p1[0] + off, p1[1] + off), ss, lite, wdt)
    if state == "pressed":  # bóng trong thêm ở mép trên nét khắc (lún sâu)
        for p0, p1 in segs:
            line_round(d, (p0[0] - 1.0, p0[1] - 1.2), (p1[0] - 1.0, p1[1] - 1.2), ss,
                       (0, 0, 0, 110), wdt)
    for p0, p1 in segs:
        line_round(d, p0, p1, ss, dark, wdt)
    # alpha: trong đĩa nút đặc 255; ngoài đĩa giữ nguyên (0, hoặc glow ở hover)
    arr_im = np.asarray(im).copy()
    yy2, xx2 = np.mgrid[0:im.size[1], 0:im.size[0]].astype(np.float32)
    inside = np.sqrt((xx2 - C * ss) ** 2 + (yy2 - C * ss) ** 2) <= (R_OUT - 0.5) * ss
    arr_im[:, :, 3] = np.where(inside, 255, arr_im[:, :, 3]).astype(np.uint8)
    im = Image.fromarray(arr_im, "RGBA")
    return finish(im, (size, size), unsharp=24)


# ============================================================ 9. SKILL FRAME

def make_skill():
    W = H = 160
    ss = 4
    w = W * ss
    yy, xx = np.mgrid[0:w, 0:w].astype(np.float32)
    u, v = xx / w, yy / w
    r = np.clip(np.sqrt((u - 0.5) ** 2 + (v - 0.5) ** 2) / 0.72, 0, 1)
    centre = np.array([30.0, 26.0, 20.0])   # radial hơi sáng giữa
    edge = np.array([20.0, 16.0, 12.0])     # #14100c
    arr = np.zeros((w, w, 4), np.float32)
    base = centre[None, None, :] * (1 - r[:, :, None]) + edge[None, None, :] * r[:, :, None]
    arr[:, :, :3] = grain(base, seed=41, amp=1.8, low_amp=1.6)
    arr[:, :, 3] = 255
    im = to_image(arr)
    d = ImageDraw.Draw(im, "RGBA")
    # viền sáng trung tính hơi ấm (để Godot modulate nhuộm màu theo nhánh)
    NEU = (216, 207, 192, 255)      # #d8cfc0
    NEU_L = (242, 234, 220, 255)
    NEU_D = (122, 114, 102, 255)
    NEU_XD = (70, 64, 56, 255)
    rad = 18
    rrect(d, (1, 1, W - 1, H - 1), ss, rad, outline=(12, 10, 8, 255), width=int(2.2 * ss))
    rrect(d, (4.5, 4.5, W - 4.5, H - 4.5), ss, rad - 3, outline=NEU_D, width=int(9.5 * ss))
    rrect(d, (5.5, 5.5, W - 5.5, H - 5.5), ss, rad - 4, outline=NEU, width=int(6.5 * ss))
    rrect(d, (4.8, 4.8, W - 4.8, H - 4.8), ss, rad - 3, outline=(NEU_L[0], NEU_L[1], NEU_L[2], 150),
          width=int(2.0 * ss))
    rrect(d, (11, 11, W - 11, H - 11), ss, rad - 8, outline=NEU_XD, width=int(1.6 * ss))
    rrect(d, (13.5, 13.5, W - 13.5, H - 13.5), ss, rad - 9,
          outline=(NEU_L[0], NEU_L[1], NEU_L[2], 140), width=int(1.1 * ss))
    rrect(d, (17, 17, W - 17, H - 17), ss, rad - 11, outline=(0, 0, 0, 100), width=int(2.0 * ss))
    # thoi nhỏ 4 góc
    for cx, cy in ((19, 19), (W - 19, 19), (19, H - 19), (W - 19, H - 19)):
        diamond(d, cx, cy, 7.5, 7.5, ss, fill=NEU_XD)
        diamond(d, cx, cy, 5.6, 5.6, ss, fill=NEU)
        ell(d, cx, cy, 1.5, 1.5, ss, fill=NEU_XD)
    # chấm giữa các cạnh
    for cx, cy in ((W / 2, 9), (W / 2, H - 9), (9, H / 2), (W - 9, H / 2)):
        ell(d, cx, cy, 2.4, 2.4, ss, fill=NEU_D)
        ell(d, cx, cy, 1.5, 1.5, ss, fill=NEU_L)
    im.putalpha(255)  # ô skill là texture đặc hoàn toàn
    return finish(im, (W, H), unsharp=28)


# ============================================================ MAIN

def main():
    save(make_panel(), "panel_frame.png")
    save(make_ring(), "ring_frame.png")
    save(make_bar_frame(688, 64, frame_w=6.5, orn_r=6.0), "bar_frame_hp.png")
    save(make_bar_frame(688, 48, frame_w=5.5, orn_r=4.6), "bar_frame_sta.png")
    save(make_bar_fill("#d8262c", "#7d0f16", seed=51), "bar_fill_hp.png")
    save(make_bar_fill("#3ecf4e", "#177a26", seed=53), "bar_fill_sta.png")
    save(make_bar_fill("#e83e6e", "#8d1030", seed=59), "bar_fill_boss.png")
    for symbol, tag in (("+", "plus"), ("-", "minus")):
        for state in ("normal", "hover", "pressed"):
            save(make_button(symbol, state), f"btn_{tag}_{state}.png")
    save(make_skill(), "skill_frame.png")
    print("done ->", OUT_DIR)


if __name__ == "__main__":
    main()
