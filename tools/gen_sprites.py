#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh spritesheet pixel art cho game "Dưới Bóng Phong Ấn" bằng PIL.

Quy ước:
- Vẽ trên lưới logic 32x32, phóng x2 -> frame 64x64 (nearest neighbor).
- Mỗi HÀNG trong sheet = 1 animation, frame đặt từ cột 0.
- Player: lính đánh thuê (giáp thép xanh xám, khăn choàng teal, kiếm thép).
- Goblin: da xanh rêu, tai nhọn dài, mắt vàng, áo rách nâu, dao gỉ.
- Hướng: down / up / side (side = nhìn phải, trái dùng flip_h trong Godot).
Chạy: python3 tools/gen_sprites.py
"""
import math
import os
from PIL import Image, ImageDraw

LS = 32          # logical size
SC = 2           # scale
FS = LS * SC     # frame size = 64

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "game", "assets", "sprites")
DESIGN_DIR = os.path.join(ROOT, "design")

# ---------------- palette ----------------
OUTL = (22, 28, 36, 255)
# player
STEEL_L = (168, 190, 208, 255)
STEEL = (120, 148, 172, 255)
STEEL_D = (74, 96, 116, 255)
ARMOR = (84, 104, 126, 255)
ARMOR_D = (56, 72, 92, 255)
CLOAK = (47, 92, 90, 255)
CLOAK_D = (32, 64, 64, 255)
SKIN = (232, 185, 138, 255)
SKIN_D = (201, 143, 95, 255)
BELT = (107, 74, 42, 255)
GOLD = (201, 162, 39, 255)
PANTS = (52, 60, 72, 255)
BOOT = (74, 52, 33, 255)
BLADE = (223, 231, 238, 255)
BLADE_D = (160, 178, 192, 255)
GRIP = (90, 58, 34, 255)
SWOOSH = (255, 255, 255, 190)
SWOOSH2 = (170, 220, 255, 110)
# goblin
GSKIN = (109, 165, 68, 255)
GSKIN_L = (143, 196, 94, 255)
GSKIN_D = (74, 122, 46, 255)
GEYE = (255, 217, 74, 255)
RAG = (122, 92, 51, 255)
RAG_D = (92, 68, 36, 255)
RUST = (185, 176, 160, 255)
RUST_D = (140, 132, 118, 255)
DARK = (30, 34, 26, 255)
FANG = (240, 240, 230, 255)


def new_frame():
    return Image.new("RGBA", (LS, LS), (0, 0, 0, 0))


def R(im, x0, y0, x1, y1, c):
    ImageDraw.Draw(im).rectangle([x0, y0, x1, y1], fill=c)


def P(im, x, y, c):
    if 0 <= x < LS and 0 <= y < LS:
        im.putpixel((x, y), c)


def L(im, p0, p1, c, w=1):
    ImageDraw.Draw(im).line([p0, p1], fill=c, width=w)


def sword(im, grip, tip):
    """Vẽ kiếm: cán nâu ở tay, chặn vàng, lưỡi thép sáng 2px."""
    gx, gy = grip
    tx, ty = tip
    # lưỡi
    L(im, (gx, gy), (tx, ty), BLADE_D, 3)
    L(im, (gx, gy), (tx, ty), BLADE, 2)
    P(im, tx, ty, BLADE)
    # chặn kiếm vàng: đoạn ngắn vuông góc tại grip
    dx, dy = tx - gx, ty - gy
    n = max(abs(dx), abs(dy), 1)
    px_, py_ = -dy / n, dx / n
    L(im, (gx - int(px_ * 2), gy - int(py_ * 2)), (gx + int(px_ * 2), gy + int(py_ * 2)), GOLD, 1)
    # cán
    L(im, (gx, gy), (gx - int(dx / n * 2), gy - int(dy / n * 2)), GRIP, 2)


def swoosh(im, cx, cy, r, a0, a1):
    for a in range(a0, a1 + 1, 6):
        rad = math.radians(a)
        x = cx + int(round(r * math.cos(rad)))
        y = cy + int(round(r * math.sin(rad)))
        P(im, x, y, SWOOSH)
        x2 = cx + int(round((r - 2) * math.cos(rad)))
        y2 = cy + int(round((r - 2) * math.sin(rad)))
        P(im, x2, y2, SWOOSH2)


# ============================================================ PLAYER
def player_legs(im, direction, i, mode):
    if direction == "side":
        lo = [3, 0, -3, 0][i] if mode == "walk" else 0
        ro = [-3, 0, 3, 0][i] if mode == "walk" else 0
        ldy = [0, -1, 0, -1][i] if mode == "walk" else 0
        rdy = [-1, 0, 0, -1][i] if mode == "walk" else 0
        # chân xa (tối hơn)
        R(im, 13 + ro, 22, 14 + ro, 27 + rdy, PANTS)
        R(im, 12 + ro, 28 + rdy, 15 + ro, 29 + rdy, BOOT)
        # chân gần
        R(im, 15 + lo, 22, 16 + lo, 27 + ldy, PANTS)
        R(im, 14 + lo, 28 + ldy, 17 + lo, 29 + ldy, BOOT)
        return
    ldx = [-1, 0, 1, 0][i] if mode == "walk" else 0
    rdx = [1, 0, -1, 0][i] if mode == "walk" else 0
    ldy = [0, -2, -1, -2][i] if mode == "walk" else 0
    rdy = [-2, -1, 0, -1][i] if mode == "walk" else 0
    R(im, 12 + ldx, 22, 14 + ldx, 26 + ldy, PANTS)
    R(im, 11 + ldx, 27 + ldy, 15 + ldx, 28 + ldy, BOOT)
    R(im, 17 + rdx, 22, 19 + rdx, 26 + rdy, PANTS)
    R(im, 16 + rdx, 27 + rdy, 20 + rdx, 28 + rdy, BOOT)


def player_frame(direction, mode, i):
    im = new_frame()
    bob = 0
    if mode == "idle":
        bob = [0, 1][i % 2]
    elif mode == "walk":
        bob = [0, 1, 0, 1][i % 4]
    B = bob  # cộng vào phần thân trên

    player_legs(im, direction, i if mode == "walk" else 0, mode)

    if direction == "down":
        # choàng sau lưng lộ 2 bên
        R(im, 8, 13 + B, 9, 24, CLOAK_D)
        R(im, 22, 13 + B, 23, 24, CLOAK_D)
        # thân giáp
        R(im, 10, 14 + B, 21, 20 + B, ARMOR)
        R(im, 10, 14 + B, 21, 14 + B, STEEL)
        R(im, 15, 15 + B, 16, 19 + B, STEEL)  # sống ngực sáng
        R(im, 10, 21 + B, 21, 22 + B, BELT)
        P(im, 15, 21 + B, GOLD); P(im, 16, 21 + B, GOLD)
        # tay trái
        R(im, 8, 14 + B, 9, 19 + B, ARMOR_D)
        R(im, 8, 20 + B, 9, 21 + B, SKIN)
        # đầu + mặt
        R(im, 12, 10 + B, 19, 13 + B, SKIN)
        P(im, 13, 11 + B, OUTL); P(im, 18, 11 + B, OUTL)  # mắt
        R(im, 14, 13 + B, 17, 13 + B, SKIN_D)
        # mũ thép
        R(im, 12, 4 + B, 19, 5 + B, STEEL_L)
        R(im, 10, 6 + B, 21, 8 + B, STEEL)
        R(im, 10, 9 + B, 21, 9 + B, STEEL_D)  # vành mũ
        R(im, 15, 3 + B, 16, 8 + B, STEEL_L)  # sống mũ
        R(im, 15, 9 + B, 16, 11 + B, STEEL_D)  # che mũi
        # khăn choàng cổ teal
        R(im, 11, 13 + B, 20, 13 + B, CLOAK)
    elif direction == "up":
        R(im, 8, 13 + B, 9, 22, CLOAK_D)
        R(im, 22, 13 + B, 23, 22, CLOAK_D)
        # lưng choàng teal phủ thân
        R(im, 10, 13 + B, 21, 22 + B, CLOAK)
        R(im, 15, 14 + B, 16, 21 + B, CLOAK_D)  # đường may giữa
        R(im, 10, 21 + B, 21, 22 + B, BELT)
        # tay 2 bên
        R(im, 8, 14 + B, 9, 19 + B, CLOAK_D)
        R(im, 8, 20 + B, 9, 21 + B, SKIN)
        R(im, 22, 14 + B, 23, 19 + B, CLOAK_D)
        R(im, 22, 20 + B, 23, 21 + B, SKIN)
        # đầu từ phía sau: mũ phủ kín
        R(im, 12, 4 + B, 19, 5 + B, STEEL_L)
        R(im, 10, 6 + B, 21, 11 + B, STEEL)
        R(im, 10, 12 + B, 21, 12 + B, STEEL_D)
        R(im, 15, 3 + B, 16, 11 + B, STEEL_L)
        R(im, 12, 12 + B, 19, 13 + B, CLOAK)
    else:  # side, mặt hướng phải
        # choàng sau (bên trái hình)
        R(im, 7, 13 + B, 10, 25, CLOAK_D)
        R(im, 8, 13 + B, 10, 20, CLOAK)
        # thân
        R(im, 11, 14 + B, 19, 20 + B, ARMOR)
        R(im, 11, 14 + B, 19, 14 + B, STEEL)
        R(im, 11, 21 + B, 19, 22 + B, BELT)
        P(im, 16, 21 + B, GOLD)
        # đầu profile
        R(im, 11, 10 + B, 19, 13 + B, SKIN)
        R(im, 18, 10 + B, 20, 12 + B, SKIN)  # mặt trước
        P(im, 20, 12 + B, SKIN_D)  # mũi
        P(im, 18, 11 + B, OUTL)  # mắt
        # mũ
        R(im, 12, 4 + B, 18, 5 + B, STEEL_L)
        R(im, 9, 6 + B, 19, 8 + B, STEEL)
        R(im, 9, 9 + B, 20, 9 + B, STEEL_D)
        R(im, 14, 3 + B, 15, 8 + B, STEEL_L)
        R(im, 10, 13 + B, 19, 13 + B, CLOAK)

    # tay phải + kiếm theo pose
    if mode == "attack":
        poses = {
            "down": [((24, 13), (29, 5)), ((24, 17), (31, 13)), ((21, 21), (13, 28))],
            "up":   [((24, 13), (29, 5)), ((24, 17), (31, 13)), ((21, 21), (13, 28))],
            "side": [((20, 13), (13, 6)), ((23, 16), (31, 14)), ((23, 21), (30, 27))],
        }
        grip, tip = poses[direction][i]
        grip = (grip[0], grip[1] + B)
        tip = (tip[0], tip[1] + B)
        sx = 21 if direction != "side" else 18
        L(im, (sx, 15 + B), grip, ARMOR_D, 2)
        sword(im, grip, tip)
        if i == 1:  # frame vung: vệt kiếm
            if direction == "down":
                swoosh(im, 15, 13, 14, 5, 140)
            elif direction == "up":
                swoosh(im, 16, 19, 14, 195, 335)
            else:
                swoosh(im, 12, 16, 14, -55, 55)
    else:
        # tay phải buông, kiếm chúc xuống bên hông
        if direction == "side":
            R(im, 20, 14 + B, 21, 19 + B, ARMOR_D)
            sword(im, (22, 20 + B), (27, 28))
        else:
            R(im, 22, 14 + B, 23, 19 + B, ARMOR_D)
            R(im, 22, 20 + B, 23, 21 + B, SKIN)
            sword(im, (24, 20 + B), (25, 29))
    # viền tối chân/đáy cho dễ đọc
    return im


def player_hurt(i):
    im = player_frame("down", "idle", 0)
    # vẽ lại mắt thành X + miệng há + nghiêng người bằng cách dịch ảnh
    for ex in (13, 18):
        P(im, ex - 1, 10, OUTL); P(im, ex, 11, OUTL); P(im, ex + 1, 10, OUTL)
        P(im, ex - 1, 12, OUTL); P(im, ex + 1, 12, OUTL)
        P(im, ex, 11, SKIN)
    R(im, 15, 13, 16, 13, OUTL)
    out = new_frame()
    out.alpha_composite(im, dest=(-1 if i == 0 else 1, 0))
    if i == 1:  # frame 2: vệt đỏ nhạt báo đau
        ov = Image.new("RGBA", (LS, LS), (255, 60, 40, 0))
        px = ov.load()
        src = out.load()
        for y in range(LS):
            for x in range(LS):
                if src[x, y][3] > 0:
                    px[x, y] = (255, 60, 40, 70)
        out.alpha_composite(ov)
    return out


def squash(im, h=22):
    body = im.resize((LS, h), Image.NEAREST)
    out = new_frame()
    out.alpha_composite(body, dest=(0, LS - h))
    return out


def tumble(im):
    return im.rotate(-90, resample=Image.NEAREST)


def build_player_rows():
    rows = {}
    for d in ("down", "up", "side"):
        rows[f"idle_{d}"] = [("sprite", player_frame(d, "idle", k)) for k in range(2)]
        rows[f"walk_{d}"] = [("sprite", player_frame(d, "walk", k)) for k in range(4)]
        rows[f"attack_{d}"] = [("sprite", player_frame(d, "attack", k)) for k in range(3)]
        base = player_frame(d, "walk", 0)
        dodge_frames = [squash(player_frame(d, "idle", 0)), tumble(base)]
        # vệt tốc độ cho frame cúi
        for k, (x, y) in enumerate([(2, 24), (1, 27), (3, 21)]):
            P(dodge_frames[0], x, y, SWOOSH2)
        rows[f"dodge_{d}"] = [("sprite", f) for f in dodge_frames]
    rows["hurt"] = [("sprite", player_hurt(k)) for k in range(2)]
    dead0 = tumble(player_frame("down", "idle", 0))
    dead1 = dead0.copy()
    a = dead1.split()[3].point(lambda v: int(v * 0.5))
    dead1.putalpha(a)
    rows["death"] = [("sprite", dead0), ("sprite", dead1)]
    return rows


# ============================================================ GOBLIN
def goblin_legs(im, direction, i, mode):
    if direction == "side":
        lo = [2, 0, -2, 0][i] if mode == "walk" else 0
        ro = [-2, 0, 2, 0][i] if mode == "walk" else 0
        R(im, 13 + ro, 23, 14 + ro, 27, GSKIN_D)
        R(im, 15 + lo, 23, 16 + lo, 27, GSKIN_D)
        R(im, 12 + ro, 28, 15 + ro, 28, GSKIN_D)
        R(im, 14 + lo, 28, 17 + lo, 28, GSKIN)
        return
    ldx = [-1, 0, 1, 0][i] if mode == "walk" else 0
    rdx = [1, 0, -1, 0][i] if mode == "walk" else 0
    R(im, 12 + ldx, 23, 13 + ldx, 26, GSKIN_D)
    R(im, 11 + ldx, 27, 14 + ldx, 27, GSKIN_D)
    R(im, 18 + rdx, 23, 19 + rdx, 26, GSKIN_D)
    R(im, 17 + rdx, 27, 20 + rdx, 27, GSKIN_D)


def goblin_frame(direction, mode, i):
    im = new_frame()
    bob = [0, 1][i % 2] if mode == "idle" else ([0, 1, 0, 1][i % 4] if mode == "walk" else 0)
    B = bob
    goblin_legs(im, direction, i if mode == "walk" else 0, mode)

    if direction == "down":
        # tai nhọn dài 2 bên
        for yy, (lx0, lx1, rx0, rx1) in enumerate([(6, 8, 23, 25), (3, 8, 23, 28), (5, 8, 23, 26)]):
            y = 8 + yy + B
            R(im, lx0, y, lx1, y, GSKIN)
            R(im, rx0, y, rx1, y, GSKIN)
        R(im, 4, 11 + B, 7, 11 + B, GSKIN_D)
        R(im, 24, 11 + B, 27, 11 + B, GSKIN_D)
        # đầu to
        R(im, 11, 5 + B, 20, 5 + B, GSKIN_L)
        R(im, 9, 6 + B, 22, 14 + B, GSKIN)
        R(im, 11, 15 + B, 20, 15 + B, GSKIN)
        R(im, 10, 9 + B, 21, 9 + B, GSKIN_D)  # gờ mày cáu
        # mắt vàng xếch
        R(im, 11, 10 + B, 13, 11 + B, GEYE)
        R(im, 18, 10 + B, 20, 11 + B, GEYE)
        P(im, 12, 11 + B, OUTL); P(im, 19, 11 + B, OUTL)
        R(im, 15, 12 + B, 16, 12 + B, GSKIN_D)  # mũi
        R(im, 12, 14 + B, 19, 14 + B, DARK)  # miệng
        P(im, 13, 15 + B, FANG); P(im, 18, 15 + B, FANG)  # nanh
        # thân áo rách
        R(im, 11, 16 + B, 20, 22 + B, RAG)
        R(im, 11, 19 + B, 20, 19 + B, RAG_D)
        for x in (12, 15, 18):  # mép rách
            P(im, x, 23 + B, RAG)
        # tay trái dài
        R(im, 8, 16 + B, 9, 22 + B, GSKIN)
        R(im, 8, 23 + B, 9, 23 + B, GSKIN_L)
    elif direction == "up":
        for yy, (lx0, lx1, rx0, rx1) in enumerate([(6, 8, 23, 25), (3, 8, 23, 28), (5, 8, 23, 26)]):
            y = 8 + yy + B
            R(im, lx0, y, lx1, y, GSKIN_D)
            R(im, rx0, y, rx1, y, GSKIN_D)
        R(im, 11, 5 + B, 20, 5 + B, GSKIN)
        R(im, 9, 6 + B, 22, 15 + B, GSKIN_D)  # gáy tối
        R(im, 14, 7 + B, 17, 12 + B, GSKIN)  # mảng da sáng giữa
        R(im, 11, 16 + B, 20, 22 + B, RAG_D)
        R(im, 11, 19 + B, 20, 19 + B, RAG)
        R(im, 8, 16 + B, 9, 22 + B, GSKIN_D)
        R(im, 22, 16 + B, 23, 22 + B, GSKIN_D)
    else:  # side hướng phải
        # tai dài hất ra sau
        R(im, 2, 8 + B, 9, 9 + B, GSKIN)
        R(im, 4, 10 + B, 9, 10 + B, GSKIN_D)
        # đầu profile + mõm nhọn
        R(im, 11, 5 + B, 19, 5 + B, GSKIN_L)
        R(im, 10, 6 + B, 20, 14 + B, GSKIN)
        R(im, 20, 11 + B, 23, 12 + B, GSKIN)  # mõm
        P(im, 23, 13 + B, GSKIN_D)
        R(im, 16, 10 + B, 18, 11 + B, GEYE)
        P(im, 17, 11 + B, OUTL)
        R(im, 18, 14 + B, 21, 14 + B, DARK)
        P(im, 19, 15 + B, FANG)
        # thân
        R(im, 11, 16 + B, 19, 22 + B, RAG)
        R(im, 11, 19 + B, 19, 19 + B, RAG_D)
        R(im, 9, 16 + B, 10, 22 + B, GSKIN_D)

    # tay phải + dao gỉ
    if mode == "attack":
        poses = {
            "down": [((24, 12), (28, 5)), ((25, 17), (30, 20)), ((23, 22), (27, 27))],
            "up":   [((24, 12), (28, 5)), ((25, 17), (30, 20)), ((23, 22), (27, 27))],
            "side": [((20, 12), (15, 5)), ((24, 16), (31, 17)), ((23, 21), (29, 25))],
        }
        grip, tip = poses[direction][i]
        grip = (grip[0], grip[1] + B)
        tip = (tip[0], tip[1] + B)
        L(im, (20 if direction != "side" else 18, 16 + B), grip, GSKIN_D, 2)
        L(im, grip, tip, RUST_D, 3)
        L(im, grip, tip, RUST, 2)
        L(im, grip, (grip[0] - 2, grip[1] + 2), GRIP, 2)
        if i == 1:
            if direction == "side":
                swoosh(im, 13, 16, 13, -40, 40)
            else:
                swoosh(im, 15, 14, 13, 10, 120)
    else:
        if direction == "side":
            R(im, 20, 16 + B, 21, 21 + B, GSKIN)
            L(im, (22, 22 + B), (26, 26), RUST, 2)
            L(im, (21, 21 + B), (22, 22 + B), GRIP, 2)
        else:
            R(im, 22, 16 + B, 23, 22 + B, GSKIN)
            R(im, 22, 23 + B, 23, 23 + B, GSKIN_L)
            L(im, (24, 22 + B), (27, 27), RUST, 2)
            L(im, (23, 21 + B), (24, 22 + B), GRIP, 2)
    return im


def goblin_hurt(i):
    im = goblin_frame("down", "idle", 0)
    for ex in (12, 19):
        P(im, ex - 1, 10, OUTL); P(im, ex, 11, GEYE); P(im, ex + 1, 10, OUTL)
        P(im, ex - 1, 12, OUTL); P(im, ex + 1, 12, OUTL)
    R(im, 14, 14, 17, 15, DARK)  # miệng há to
    out = new_frame()
    out.alpha_composite(im, dest=(-1 if i == 0 else 1, 0))
    if i == 1:
        ov = Image.new("RGBA", (LS, LS), (255, 60, 40, 0))
        px = ov.load(); src = out.load()
        for y in range(LS):
            for x in range(LS):
                if src[x, y][3] > 0:
                    px[x, y] = (255, 60, 40, 70)
        out.alpha_composite(ov)
    return out


def build_goblin_rows():
    rows = {}
    for d in ("down", "up", "side"):
        rows[f"idle_{d}"] = [("sprite", goblin_frame(d, "idle", k)) for k in range(2)]
        rows[f"walk_{d}"] = [("sprite", goblin_frame(d, "walk", k)) for k in range(4)]
        rows[f"attack_{d}"] = [("sprite", goblin_frame(d, "attack", k)) for k in range(3)]
    rows["hurt"] = [("sprite", goblin_hurt(k)) for k in range(2)]
    dead0 = tumble(goblin_frame("down", "idle", 0))
    dead1 = dead0.copy()
    a = dead1.split()[3].point(lambda v: int(v * 0.5))
    dead1.putalpha(a)
    rows["death"] = [("sprite", dead0), ("sprite", dead1)]
    return rows


# thứ tự hàng cố định để .tres khớp tọa độ
PLAYER_ROWS = ["idle_down", "idle_up", "idle_side",
               "walk_down", "walk_up", "walk_side",
               "attack_down", "attack_up", "attack_side",
               "dodge_down", "dodge_up", "dodge_side",
               "hurt", "death"]
GOBLIN_ROWS = ["idle_down", "idle_up", "idle_side",
               "walk_down", "walk_up", "walk_side",
               "attack_down", "attack_up", "attack_side",
               "hurt", "death"]

ANIM_META = {  # name-prefix -> (speed, loop)
    "idle": (3.0, True), "walk": (8.0, True), "attack": (12.0, False),
    "dodge": (10.0, False), "hurt": (8.0, False), "death": (4.0, False),
}


def compose_sheet(rows_data, row_order):
    cols = max(len(rows_data[r]) for r in row_order)
    sheet = Image.new("RGBA", (cols * FS, len(row_order) * FS), (0, 0, 0, 0))
    for ri, name in enumerate(row_order):
        for ci, (_tag, fr) in enumerate(rows_data[name]):
            big = fr.resize((FS, FS), Image.NEAREST)
            sheet.alpha_composite(big, dest=(ci * FS, ri * FS))
    return sheet, cols


def write_tres(path, rows_data, row_order, sheet_res_path):
    atlas_lines = []
    anim_chunks = []
    aid = 0
    for ri, name in enumerate(row_order):
        tex_ids = []
        for ci in range(len(rows_data[name])):
            aid += 1
            tid = f"AtlasTexture_{aid:03d}"
            tex_ids.append(tid)
            atlas_lines.append(
                f'[sub_resource type="AtlasTexture" id="{tid}"]\n'
                f'atlas = ExtResource("1_sheet")\n'
                f'region = Rect2({ci * FS}, {ri * FS}, {FS}, {FS})\n'
            )
        prefix = name.split("_")[0]
        speed, loop = ANIM_META[prefix]
        frames_txt = ", ".join(
            '{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % t for t in tex_ids)
        anim_chunks.append(
            '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
            % (frames_txt, "true" if loop else "false", name, speed))
    load_steps = aid + 2
    content = (
        f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{sheet_res_path}" id="1_sheet"]\n\n'
        + "\n".join(atlas_lines)
        + "\n[resource]\nanimations = ["
        + ", ".join(anim_chunks)
        + "]\n"
    )
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


def make_preview(player_sheet, goblin_sheet):
    scale = 2
    pw, ph = player_sheet.width * scale, player_sheet.height * scale
    gw, gh = goblin_sheet.width * scale, goblin_sheet.height * scale
    pad = 24
    W = pw + gw + pad * 3
    H = max(ph, gh) + pad * 2
    prev = checker(W, H, 24)
    p_big = player_sheet.resize((pw, ph), Image.NEAREST)
    g_big = goblin_sheet.resize((gw, gh), Image.NEAREST)
    prev.alpha_composite(p_big, dest=(pad, pad))
    prev.alpha_composite(g_big, dest=(pad * 2 + pw, pad))
    d = ImageDraw.Draw(prev)
    # khung từng frame để soi lệch hàng
    for ox, sheet, rows_n, cols_n in ((pad, player_sheet, 14, 4), (pad * 2 + pw, goblin_sheet, 11, 4)):
        for r in range(rows_n):
            for c in range(cols_n):
                x0 = ox + c * FS * scale
                y0 = pad + r * FS * scale
                d.rectangle([x0, y0, x0 + FS * scale - 1, y0 + FS * scale - 1],
                            outline=(255, 200, 60, 160))
    prev.convert("RGB").save(os.path.join(DESIGN_DIR, "sprite_preview.png"))


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(DESIGN_DIR, exist_ok=True)

    p_rows = build_player_rows()
    g_rows = build_goblin_rows()

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
    print("preview ->", os.path.join(DESIGN_DIR, "sprite_preview.png"))


if __name__ == "__main__":
    main()
