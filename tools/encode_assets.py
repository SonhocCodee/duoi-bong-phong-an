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
    "design/sprite_preview.png",
    "design/sprite_preview_v2.png",
    "design/world_map_sketch.png",
    "design/tileset_mockup_v1.png",
    "design/tavern_mockup_v1.png",
    "design/thanh_xuan_lam_layout.png",
    "game/assets/sprites/rat_spritesheet.png",
    "game/assets/sprites/slime_spritesheet.png",
    "game/assets/sprites/golem_spritesheet.png",
    "game/assets/sprites/wolf_spritesheet.png",
    "game/assets/sprites/spider_spritesheet.png",
    "game/assets/sprites/wyvern_spritesheet.png",
    "game/assets/sprites/tho_ren_spritesheet.png",
    "game/assets/sprites/nong_dan_spritesheet.png",
    "game/assets/sprites/linh_tuan_spritesheet.png",
    "game/assets/tilesets/exterior_v1.png",
    "game/assets/tilesets/interior_tavern_v1.png",
    "game/assets/props/oak.png",
    "game/assets/props/small_tree.png",
    "game/assets/props/bush.png",
    "game/assets/props/house.png",
    "game/assets/props/well.png",
    "game/assets/props/barrel.png",
    "game/assets/props/sack.png",
    "game/assets/props/boulder.png",
    "game/assets/props/table.png",
    "game/assets/props/bar.png",
    "game/assets/props/fireplace.png",
    "game/assets/props/lamp.png",
    "game/assets/props/shelf.png",
    "game/assets/props/wine_barrel.png",
    "design/art_samples/media-generation-lang-tan-diep-render-sample-0-6276c1c4-1a37-4903-9b95-90e26dac03f1.webp",
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
