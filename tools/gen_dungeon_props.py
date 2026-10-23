#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh prop hầm ngục cho "Dưới Bóng Phong Ấn": rương loot + cửa khoá.

Kỹ thuật (theo pipeline gen_tileset_v1 / gen_sprites_v3):
- Vẽ SUPERSAMPLE 4x bằng PIL: hình khối thật, shading nhiều lớp
  (base -> bóng gradient đáy -> highlight trên-trái -> viền sáng),
  chi tiết nhỏ vẽ tay (thớ gỗ, đinh tán đai sắt, khoá vàng, vòng nắm cửa).
- Downscale về kích thước cuối bằng LANCZOS + unsharp nhẹ.

Chạy: python3 tools/gen_dungeon_props.py
Đầu ra:
- game/assets/props/chest.png  (128x128)
- game/assets/props/door.png   (128x192)
"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageChops, ImageFilter

SS = 4  # supersample

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROP_DIR = os.path.join(ROOT, "game", "assets", "props")
os.makedirs(PROP_DIR, exist_ok=True)

# ---------------- palette ----------------
OUT = (24, 18, 12, 255)          # outline đậm
WOOD = (146, 102, 62, 255); WOOD_L = (182, 138, 88, 255); WOOD_D = (106, 70, 40, 255); WOOD_XD = (74, 46, 24, 255)
OAK = (132, 94, 56, 255); OAK_L = (168, 126, 78, 255); OAK_D = (94, 62, 34, 255)
IRON = (84, 86, 96, 255); IRON_L = (138, 142, 156, 255); IRON_D = (48, 50, 60, 255)
GOLD = (206, 164, 52, 255); GOLD_L = (250, 218, 110, 255); GOLD_D = (156, 118, 30, 255)
FRAME_D = (52, 46, 44, 255); FRAME = (92, 86, 82, 255)


def A(col, a):
    return col[:3] + (a,)


def canvas(w, h):
    return Image.new("RGBA", (int(w * SS), int(h * SS)), (0, 0, 0, 0))


def P_(pts):
    return [(x * SS, y * SS) for (x, y) in pts]


def poly(im, pts, fill=None, outline=None, ow=1.0):
    d = ImageDraw.Draw(im)
    d.polygon(P_(pts), fill=fill, outline=outline,
              width=max(1, int(ow * SS)) if outline else 1)


def ell_pts(cx, cy, rx, ry, rot=0.0, a0=0.0, a1=360.0, n=40):
    pts = []
    rr = math.radians(rot)
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        ex, ey = rx * math.cos(a), ry * math.sin(a)
        pts.append((cx + ex * math.cos(rr) - ey * math.sin(rr),
                    cy + ex * math.sin(rr) + ey * math.cos(rr)))
    return pts


def ell(im, cx, cy, rx, ry, fill=None, outline=None, ow=1.0, rot=0.0):
    poly(im, ell_pts(cx, cy, rx, ry, rot), fill=fill, outline=outline, ow=ow)


def line(im, p0, p1, fill, w=1.6):
    d = ImageDraw.Draw(im)
    d.line([p0[0] * SS, p0[1] * SS, p1[0] * SS, p1[1] * SS], fill=fill,
           width=max(1, int(w * SS)), joint="curve")
    r = w / 2.0
    ell(im, p0[0], p0[1], r, r, fill=fill)
    ell(im, p1[0], p1[1], r, r, fill=fill)


def rrect(im, box, r, fill=None, outline=None, ow=1.0):
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([box[0] * SS, box[1] * SS, box[2] * SS, box[3] * SS],
                        radius=r * SS, fill=fill, outline=outline,
                        width=max(1, int(ow * SS)) if outline else 1)


def finish(im, w, h):
    out = im.resize((int(w), int(h)), Image.LANCZOS)
    return out.filter(ImageFilter.UnsharpMask(radius=2, percent=52, threshold=3))


def soft_shadow(im, cx, cy, rx, ry, alpha=90):
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS],
              fill=(16, 12, 8, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(3.2 * SS))
    im.alpha_composite(layer)


def shade_band(im, box, top_a=0, bot_a=70):
    """Bóng gradient dọc trong box: sáng trên, tối dưới (vẽ 24 dải alpha)."""
    x0, y0, x1, y1 = box
    steps = 24
    ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    for i in range(steps):
        t = i / (steps - 1)
        a = int(top_a + (bot_a - top_a) * t)
        yy0 = y0 + (y1 - y0) * i / steps
        yy1 = y0 + (y1 - y0) * (i + 1) / steps + 1
        col = (255, 244, 214, a) if a < 0 else (10, 6, 2, 0)
        # a âm = sáng (không dùng ở đây); a dương hiểu là độ tối -> vẽ đen
        d.rectangle([x0 * SS, yy0 * SS, x1 * SS, yy1 * SS], fill=(8, 5, 2, max(0, a)))
    im.alpha_composite(ov)


def wood_grain(im, x0, x1, y0, y1, seed, n=14, vertical=True):
    rnd = random.Random(seed)
    for _ in range(n):
        if vertical:
            x = rnd.uniform(x0 + 2, x1 - 2)
            yy0 = rnd.uniform(y0 + 3, y1 - 16)
            pts = []
            for k in range(9):
                t = k / 8
                pts.append((x + 0.9 * math.sin(t * math.pi * rnd.uniform(0.8, 1.4)),
                            yy0 + t * rnd.uniform(9, 15)))
            d = ImageDraw.Draw(im)
            d.line(P_(pts), fill=A(WOOD_XD, 105), width=int(0.8 * SS))
        else:
            y = rnd.uniform(y0 + 2, y1 - 2)
            xx0 = rnd.uniform(x0 + 3, x1 - 16)
            pts = []
            for k in range(9):
                t = k / 8
                pts.append((xx0 + t * rnd.uniform(9, 15),
                            y + 0.9 * math.sin(t * math.pi)))
            d = ImageDraw.Draw(im)
            d.line(P_(pts), fill=A(WOOD_XD, 105), width=int(0.8 * SS))


def rivets(im, pts, r=1.5):
    for (x, y) in pts:
        ell(im, x, y, r, r, fill=IRON_L, outline=IRON_D, ow=0.6)
        ell(im, x - r * 0.3, y - r * 0.3, r * 0.35, r * 0.35, fill=(235, 240, 250, 255))


# ============================================================ RƯƠNG (128x128)

def draw_chest():
    W, H = 128, 128
    im = canvas(W, H)
    soft_shadow(im, 64, 112, 44, 7, 95)
    d = ImageDraw.Draw(im)

    # --- thân rương: hộp gỗ 26..102 x 56..110 ---
    body = [(26, 56), (102, 56), (102, 110), (26, 110)]
    poly(im, body, fill=WOOD, outline=OUT, ow=1.4)
    # ván dọc: khe + thớ
    for vx in (45, 64, 83):
        line(im, (vx, 58), (vx, 108), A(WOOD_XD, 200), 1.1)
    wood_grain(im, 28, 100, 58, 108, seed=7, n=10)
    # mảng sáng trên-trái + tối đáy thân
    poly(im, [(28, 58), (52, 58), (52, 108), (28, 108)], fill=A(WOOD_L, 60))
    shade_band(im, (26, 84, 102, 110), bot_a=64)
    line(im, (28, 108.5), (100, 108.5), A(WOOD_XD, 220), 1.6)

    # --- nắp vòm: nửa ellipse trên thân, đỉnh ~y=30 ---
    lid_pts = ell_pts(64, 56, 38, 27, a0=180, a1=360, n=36) + [(102, 56), (26, 56)]
    poly(im, lid_pts, fill=WOOD_L, outline=OUT, ow=1.4)
    # ván nắp cong theo vòm (cung đồng tâm mờ)
    for rr, aa in ((0.72, 90), (0.45, 70)):
        arc = ell_pts(64, 56, 38 * rr + 8, 27 * rr + 4, a0=195, a1=345, n=24)
        d.line(P_(arc), fill=A(WOOD_XD, aa + 60), width=int(1.0 * SS))
    for vx in (45, 83):  # khe ván nắp chạy từ vòm xuống mép
        arc = ell_pts(64, 56, abs(vx - 64), 27 * abs(vx - 64) / 38.0, a0=180, a1=360, n=20)
        # chỉ vẽ nửa phía vx: xấp xỉ bằng đoạn thẳng cong qua 3 điểm vòm
        top_y = 56 - 27 * math.sqrt(max(0.0, 1 - ((vx - 64) / 38.0) ** 2))
        line(im, (vx, 56), (vx, top_y + 2), A(WOOD_XD, 170), 1.0)
    wood_grain(im, 34, 94, 34, 54, seed=11, n=6)
    # highlight nóc nắp
    arc_hi = ell_pts(64, 56, 30, 20, a0=205, a1=285, n=18)
    d.line(P_(arc_hi), fill=A((255, 236, 190), 150), width=int(1.6 * SS))

    # --- đai sắt: 2 đai dọc ôm cả nắp + thân, 1 đai ngang ở mép nắp ---
    for bx in (37, 91):
        # phần trên nắp (theo vòm: đoạn cong xấp xỉ 3 đoạn)
        top_y = 56 - 27 * math.sqrt(max(0.0, 1 - ((bx - 64) / 38.0) ** 2))
        rrect(im, (bx - 4, top_y - 1, bx + 4, 110), 1.5, fill=IRON, outline=IRON_D, ow=1.0)
        line(im, (bx - 2.2, top_y + 2), (bx - 2.2, 108), A(IRON_L, 170), 1.1)
    rrect(im, (25, 51, 103, 59), 1.5, fill=IRON, outline=IRON_D, ow=1.0)
    line(im, (27, 53), (101, 53), A(IRON_L, 160), 1.1)
    rivets(im, [(33, 55), (95, 55), (37, 76), (37, 100), (91, 76), (91, 100),
                (52, 55), (76, 55)], r=1.4)

    # --- khoá vàng ở giữa mặt trước ---
    rrect(im, (54, 52, 74, 76), 3.0, fill=GOLD, outline=GOLD_D, ow=1.3)
    rrect(im, (57, 55, 71, 73), 2.0, fill=A(GOLD_L, 120))
    ell(im, 64, 62, 3.4, 3.4, fill=(40, 30, 14, 255), outline=GOLD_D, ow=0.7)
    poly(im, [(62.4, 64), (65.6, 64), (66.6, 71), (61.4, 71)], fill=(40, 30, 14, 255))
    ell(im, 61.5, 57.5, 1.6, 1.6, fill=(255, 246, 200, 255))
    # quai khoá cong phía trên
    arc_lock = ell_pts(64, 53, 6.5, 6.0, a0=180, a1=360, n=20)
    d.line(P_(arc_lock), fill=IRON_D, width=int(2.2 * SS))
    d.line(P_(arc_lock), fill=IRON_L, width=int(0.9 * SS))

    return finish(im, W, H)


# ============================================================ CỬA (128x192)

def draw_door():
    W, H = 128, 192
    im = canvas(W, H)
    soft_shadow(im, 64, 186, 52, 5, 80)
    d = ImageDraw.Draw(im)

    # --- khung đá tối bao quanh ---
    rrect(im, (8, 4, 120, 190), 3, fill=FRAME_D, outline=(20, 18, 16, 255), ow=1.4)
    rrect(im, (13, 9, 115, 190), 2, fill=FRAME, outline=FRAME_D, ow=1.0)
    for (sx, sy) in [(24, 22), (100, 30), (30, 100), (102, 120), (22, 168), (98, 176)]:
        ell(im, sx, sy, 3.2, 2.0, fill=A((150, 144, 138), 110))

    # --- cánh cửa gỗ sồi: ván dọc 20..108, y 14..186 ---
    door = [(20, 14), (108, 14), (108, 186), (20, 186)]
    poly(im, door, fill=OAK, outline=OUT, ow=1.4)
    planks = [20, 42, 64, 86, 108]
    for i in range(4):  # tông xen kẽ từng ván
        x0, x1 = planks[i], planks[i + 1]
        if i % 2 == 1:
            poly(im, [(x0, 14), (x1, 14), (x1, 186), (x0, 186)], fill=A(OAK_D, 70))
        line(im, (x1 - 0.5, 15), (x1 - 0.5, 185), A(WOOD_XD, 230), 1.2)
        line(im, (x0 + 1.2, 15), (x0 + 1.2, 185), A(OAK_L, 130), 0.9)
    wood_grain(im, 22, 106, 16, 184, seed=23, n=20)
    # mắt gỗ
    for (kx, ky) in [(33, 66), (75, 122), (53, 160)]:
        ell(im, kx, ky, 2.6, 3.4, outline=A(WOOD_XD, 190), ow=0.9)
        ell(im, kx, ky, 1.1, 1.5, fill=A(WOOD_XD, 190))
    shade_band(im, (20, 130, 108, 186), bot_a=58)
    # highlight mép trên
    line(im, (22, 16), (106, 16), A((255, 238, 200), 110), 1.4)

    # --- 2 đai sắt ngang + bản lề trái ---
    for by in (42, 142):
        rrect(im, (19, by - 6, 109, by + 6), 1.5, fill=IRON, outline=IRON_D, ow=1.1)
        line(im, (21, by - 3.6), (107, by - 3.6), A(IRON_L, 170), 1.2)
        rivets(im, [(28, by), (50, by), (72, by), (94, by), (103, by)], r=1.6)
        # bản lề: mẩu sắt dài hơn ở mép trái
        rrect(im, (14, by - 4, 26, by + 4), 1.2, fill=IRON_D, outline=(28, 30, 36, 255), ow=0.9)
        ell(im, 17.5, by, 2.2, 2.2, fill=IRON_L, outline=IRON_D, ow=0.6)

    # --- vòng tay nắm bên phải + đế gắn ---
    rrect(im, (86, 84, 102, 100), 2.5, fill=IRON, outline=IRON_D, ow=1.1)
    ell(im, 94, 88.5, 2.0, 2.0, fill=IRON_L, outline=IRON_D, ow=0.6)
    # vòng: vẽ 2 cung tròn (ngoài đậm, trong sáng lệch) tạo khối 3D
    ring = ell_pts(94, 108, 11, 12, n=44)
    d.line(P_(ring), fill=IRON_D, width=int(3.4 * SS))
    d.line(P_(ring), fill=IRON, width=int(2.2 * SS))
    ring_hi = ell_pts(93, 106.5, 11, 12, a0=140, a1=260, n=16)
    d.line(P_(ring_hi), fill=(215, 222, 235, 255), width=int(1.0 * SS))
    ell(im, 94, 99, 3.0, 2.4, fill=IRON_D)  # khớp nối vòng-đế
    # lỗ khoá dưới vòng nắm
    ell(im, 94, 132, 2.6, 2.6, fill=(26, 20, 12, 255), outline=GOLD_D, ow=0.8)
    poly(im, [(92.8, 133.5), (95.2, 133.5), (96, 139), (92, 139)],
         fill=(26, 20, 12, 255), outline=GOLD_D, ow=0.6)

    return finish(im, W, H)


def main():
    chest = draw_chest()
    chest_path = os.path.join(PROP_DIR, "chest.png")
    chest.save(chest_path)
    door = draw_door()
    door_path = os.path.join(PROP_DIR, "door.png")
    door.save(door_path)
    # Đọc lại kiểm chứng: mở được, đúng kích thước, có pixel không trong suốt
    for path, expect in ((chest_path, (128, 128)), (door_path, (128, 192))):
        img = Image.open(path)
        img.load()
        assert img.size == expect, (path, img.size)
        alpha = img.convert("RGBA").split()[3]
        bbox = alpha.getbbox()
        assert bbox is not None, path
        print("OK:", path, img.size, "alpha bbox:", bbox)
    print("chest ->", chest_path)
    print("door  ->", door_path)


if __name__ == "__main__":
    main()
