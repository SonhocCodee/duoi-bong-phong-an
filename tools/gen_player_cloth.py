#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh spritesheet player ÁO VẢI (trạng thái "lính đánh thuê trắng tay")
cho game "Dưới Bóng Phong Ấn" — frame 128x128, CÙNG layout/animation
với player_frames.tres (bản giáp hiệp sĩ) để thay thế 1-1 không sửa
logic animation trong player.gd.

Cách làm: import tools/gen_sprites_v3.py làm thư viện vẽ (pose/hàm vẽ
nguyên vẹn), chỉ THAY BẢNG MÀU trước khi dựng frame:
  - STEEL* (giáp thép + pauldron + váy giáp) -> vải thô nâu xám
    (áo tunic + miếng vá vai bằng vải) — hết hẳn ánh kim loại.
  - GOLD* (khóa/đinh vàng) -> đồng xỉn / gỗ sẫm.
  - CLOAK* (choàng teal của hiệp sĩ) -> choàng xám nâu bạc màu.
  - PANTS* -> nâu đất thường dân.
  - BLADE* (lưỡi kiếm sáng) -> thép xỉn nâu rỉ + chấm rỉ cam nâu
    rải dọc lưỡi (bọc hàm draw_sword của v3).
TEAL_GEM -> nâu gỗ (hạt cườm gỗ thay cho ngọc).

Chạy: python3 tools/gen_player_cloth.py
Kết quả: game/assets/sprites/player_cloth_spritesheet.png
         game/assets/sprites/player_cloth_frames.tres
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_sprites_v3 as g
from PIL import Image

# ---------------- THAY BẢNG MÀU: giáp hiệp sĩ -> áo vải trắng tay ---------
# Áo tunic vải thô (họ màu STEEL của v3 = thân + vai + váy thân dưới)
g.STEEL_D = (96, 76, 48, 255)     # vải tối (bóng)
g.STEEL = (138, 110, 70, 255)     # vải nâu xám chủ đạo
g.STEEL_L = (170, 140, 96, 255)   # vải sáng (vai / lá ngoài)
g.STEEL_HI = (198, 170, 124, 255) # điểm sáng vải (thay highlight kim loại)
# Khóa / chốt: đồng xỉn thay vàng
g.GOLD = (122, 90, 44, 255)
g.GOLD_L = (158, 122, 64, 255)
g.GOLD_D = (92, 66, 30, 255)
# Choàng: xám nâu bạc màu thay teal hiệp sĩ
g.CLOAK_D = (62, 52, 38, 255)
g.CLOAK = (94, 80, 58, 255)
g.CLOAK_L = (126, 110, 80, 255)
g.CLOAK_E = (152, 134, 100, 255)
# Quần thường dân nâu đất
g.PANTS = (80, 66, 48, 255)
g.PANTS_D = (54, 43, 30, 255)
# Lưỡi kiếm rỉ: thép xỉn nâu thay lưỡi sáng
g.BLADE = (186, 170, 148, 255)
g.BLADE_D = (136, 120, 100, 255)
# Ngọc ngực -> hạt gỗ
g.TEAL_GEM = (110, 82, 46, 255)

# Bọc draw_sword: sau khi vẽ kiếm như thường, rải chấm rỉ dọc lưỡi.
_orig_draw_sword = g.draw_sword


def draw_sword_rusty(im, grip, tip, back=False):
    _orig_draw_sword(im, grip, tip, back=back)
    gx, gy = grip
    tx, ty = tip
    rnd = random.Random(97)
    for i in range(9):
        t = 0.15 + 0.8 * (i / 8.0) + rnd.uniform(-0.04, 0.04)
        x = gx + (tx - gx) * t + rnd.uniform(-1.2, 1.2)
        y = gy + (ty - gy) * t + rnd.uniform(-1.2, 1.2)
        r = rnd.uniform(0.5, 1.1)
        g.ell(im, x, y, r, r * 0.8, fill=g.A(g.RUST_SPOT, rnd.randint(120, 200)))


g.draw_sword = draw_sword_rusty


def main():
    rows = {}
    for ddir in ("down", "up", "side"):
        rows[f"idle_{ddir}"] = [g.player_pose(ddir, "idle", k, 3) for k in range(3)]
        rows[f"walk_{ddir}"] = [g.player_pose(ddir, "walk", k, 6) for k in range(6)]
        rows[f"attack_{ddir}"] = [g.player_pose(ddir, "attack", k, 4) for k in range(4)]
        rows[f"dodge_{ddir}"] = [g.player_dodge_frame(ddir, k) for k in range(3)]
    rows["hurt"] = [g.player_hurt_frame(k) for k in range(2)]
    rows["death"] = [g.player_death_frame(k) for k in range(3)]

    sheet, _cols = g.compose_sheet(rows, g.PLAYER_ROWS)
    out_png = os.path.join(g.OUT_DIR, "player_cloth_spritesheet.png")
    sheet.save(out_png)
    print("cloth sheet:", sheet.size, "->", out_png)
    n = g.write_tres(os.path.join(g.OUT_DIR, "player_cloth_frames.tres"), rows,
                     g.PLAYER_ROWS, "res://assets/sprites/player_cloth_spritesheet.png")
    print("atlas textures:", n)

    # Ảnh đối chiếu nhanh: idle_down giáp (sheet gốc) vs áo vải, cạnh nhau.
    armor_sheet = Image.open(os.path.join(g.OUT_DIR, "player_spritesheet.png"))
    a = armor_sheet.crop((0, 0, 128, 128)).resize((256, 256), Image.NEAREST)
    b = sheet.crop((0, 0, 128, 128)).resize((256, 256), Image.NEAREST)
    comp = Image.new("RGBA", (512, 256), (40, 60, 34, 255))
    comp.alpha_composite(a, dest=(0, 0))
    comp.alpha_composite(b, dest=(256, 0))
    comp_path = "/tmp/cloth_vs_armor.png"
    comp.convert("RGB").save(comp_path)
    print("compare ->", comp_path)


if __name__ == "__main__":
    main()
