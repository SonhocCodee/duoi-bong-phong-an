#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""(Chạy ở phía Muse) Mã hoá mọi file nhị phân trong repo thành .b64 (base64, bọc dòng 76 ký tự)
để push qua kênh GitHub chỉ-nhận-văn-bản. Danh sách asset lấy từ ASSET_FILES bên dưới —
thêm asset mới thì thêm đường dẫn vào đây rồi chạy lại script.
"""
import base64
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ASSET_FILES = [
    "game/assets/sprites/player_spritesheet.png",
    "game/assets/sprites/goblin_spritesheet.png",
    "design/sprite_preview_v3.png",
    "design/sprite_mockup_v3.png",
]


def main() -> None:
    for rel in ASSET_FILES:
        src = os.path.join(ROOT, rel)
        with open(src, "rb") as f:
            data = f.read()
        enc = base64.encodebytes(data).decode("ascii")
        with open(src + ".b64", "w", encoding="ascii") as f:
            f.write(enc)
        print("encoded:", rel, f"{len(data)} -> {len(enc)} chars")


if __name__ == "__main__":
    main()
