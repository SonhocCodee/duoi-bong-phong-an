# -*- coding: utf-8 -*-
"""SPEC cau truc dia hinh tung map da ngoai cho apply_terrain.py.

He o: O TILE (tx,ty); tam o = (tx*64+32, ty*64+32) px.
Op theo thu tu:
  fill_base : son nen toan map (tile + variants {tile: xac suat tich luy})
  paint     : {rect|points+width, tile, block?, forest?} - tile "water" tu
              chon water_a/water_b + block neu block=True
  carve     : {rect|points+width, tile?} - go block (+ son tile neu co)
  block     : {rect|points+width, forest?} - them block khong son
  shore     : tu dong son shore quanh cac o water hien co
"""

GRASS_VAR = {"grass_flower": 0.06, "grass_tall": 0.15, "grass_sparse": 0.21}

SPECS = {
    # ------------------------------------------------------------------
    # STONEBRIDGE - thi diem NOI RONG 36x22 -> 110x80.
    # Song Clearwater chay Dong-Tay qua giua (giu nguyen dai song cu
    # ty[-3,3] o khu trung tam), cau rong 3 o tai truc x=0 (cau cu 2 o).
    # Tram thue + linh + NPC + chuot giu nguyen vi tri o khu cu.
    # ------------------------------------------------------------------
    "bo_song_thanh": {
        "scene": "bo_song_thanh",
        "biome": "exterior",
        "bounds": (-55, -40, 54, 39),
        "strip": ["BackgroundPlaceholder"],
        "ops": [
            {"op": "fill_base", "tile": "grass", "variants": GRASS_VAR},
            # === KHOI RUNG DAY, mep rang cua bat quy tac (v2) ===
            # Tay: khoi goc + 4 thoi nho ra phia dong
            {"op": "paint", "rect": (-55, -40, -36, 39), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-36, -30, -33, -22), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-35, -12, -32, -5), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-36, 6, -33, 14), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-35, 24, -32, 31), "tile": "grass_dark", "block": True, "forest": True},
            # Dong: khoi goc + 3 thoi nho ra phia tay
            {"op": "paint", "rect": (36, -40, 54, 39), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (33, -26, 36, -18), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (32, -2, 35, 6), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (33, 18, 36, 26), "tile": "grass_dark", "block": True, "forest": True},
            # Lum le (giu vai tro chia khu nhu v1, vi tri lech bat quy tac)
            {"op": "paint", "rect": (-14, -20, -10, -15), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-30, -28, -26, -24), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-9, 20, -5, 24), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (14, 16, 18, 20), "tile": "grass_dark", "block": True, "forest": True},
            # Khoanh ruong Dong-Nam (khong block) - giu tu v1
            {"op": "paint", "rect": (8, 17, 19, 23), "tile": "field"},
            # === Trang ===
            {"op": "paint", "rect": (-47, 9, -37, 19), "tile": "sand"},
            {"op": "carve", "rect": (-47, 9, -37, 19)},
            {"op": "paint", "rect": (38, -18, 46, -10), "tile": "sand"},
            {"op": "carve", "rect": (38, -18, 46, -10)},
            # Trang an cuoi loi mon rung Tay
            {"op": "paint", "rect": (-50, 15, -46, 20), "tile": "grass_flower"},
            {"op": "carve", "rect": (-50, 15, -46, 20)},
            # === SONG UON (v2): truc dao dong +-2 o, be rong 6-8 o thay doi theo doan;
            # doan tram thue |tx|<=8 giu tam 0 de khong nuot linh/NPC ===
            {"op": "paint", "points": [(-56, -3), (-46, -2), (-36, 0), (-26, 1), (-16, 0), (-8, 0), (0, 0), (8, 0), (16, 1), (26, 2), (36, 1), (46, -1), (56, -2)],
             "widths": [6, 7, 8, 7, 6, 7, 7, 6, 7, 8, 7, 6, 6], "tile": "water", "block": True},
            {"op": "shore"},
            # Bai boi nho giua song (carve block: len duoc, khong noi hai bo)
            {"op": "paint", "points": [(-24, -2), (-23, -2)], "width": 1, "tile": "sand"},
            {"op": "carve", "points": [(-24, -2), (-23, -2)], "width": 1},
            {"op": "paint", "points": [(21, 3)], "width": 1, "tile": "sand"},
            {"op": "carve", "points": [(21, 3)], "width": 1},
            # === DUONG CHINH CONG Bac-Nam: lech truc toi da 3 o, doan qua cau giu x=0;
            # MOT polyline lien tuc xuyen song tai cau (tx -1..1) ===
            {"op": "carve", "points": [(0, 40), (0, 33), (2, 26), (3, 19), (1, 12), (0, 6), (0, 1), (0, -2), (-1, -9), (-3, -16), (-2, -23), (0, -30), (1, -36), (0, -40)],
             "width": 3, "tile": "dirt"},
            # === Duong ben do: cong theo dia hinh ===
            {"op": "carve", "points": [(-1, 6), (-4, 5), (-10, 5), (-16, 8), (-23, 11), (-29, 12), (-35, 14)],
             "width": 2, "tile": "dirt"},
            # === Duong trang da xuyen rung Dong: ngoan ngoeo hon, vao thang trang cu ===
            {"op": "carve", "points": [(2, 8), (7, 9), (13, 8), (19, 11), (25, 10), (31, 11), (36, 8), (40, 2), (42, -4), (43, -10), (42, -13)],
             "width": 2, "tile": "dirt"},
            # === LOI MON rung Tay: mieng loe 3 o, mon hep 1 o xuyen khoi rung toi trang an ===
            {"op": "carve", "points": [(-23, 11), (-27, 13)], "width": 3, "tile": "grass"},
            {"op": "carve", "points": [(-27, 13), (-32, 12), (-37, 16), (-42, 14), (-47, 17)],
             "width": 1, "tile": "grass"},
        ],
        "move": {
            "PortalNorth": (0, -2528),
            "Spawn_from_ngoai": (0, -2368),
            "LabelNorth": (-200, -2528),
            "PortalSouth": (0, 2528),
            "Spawn_from_machnha": (0, 2368),
            "Spawn_start": (0, 2368),
            "LabelSouth": (-200, 2464),
        },
        "props": {"tex": "oak", "h": 216, "edge_prob": 0.95, "inner_prob": 0.55},
    },

    # ------------------------------------------------------------------
    # ELDERWOOD - noi 33x26 -> 110x80. Khu cu (cay + quai + herb) giu
    # nguyen toa do; vanh moi la RUNG KHOI chan kin, chi chua loi mon
    # chinh Tay-Dong + nhanh Bac len Cloudpeak + vong mon phu phia Nam.
    # ------------------------------------------------------------------
    "rung_co_thu": {
        "scene": "rung_co_thu",
        "biome": "exterior",
        "bounds": (-55, -40, 54, 39),
        "strip": ["ForestFloor", "ForestDeep", "Trail0", "Trail1", "Trail2",
                  "Trail3", "Trail4", "Trail5", "TrailJoint0", "TrailJoint1",
                  "TrailJoint2", "TrailJoint3", "TrailJoint4", "TrailJoint5",
                  "TrailJoint6"],
        "ops": [
            {"op": "fill_base", "tile": "grass", "variants": GRASS_VAR},
            # Toan bo vanh moi la rung khoi
            {"op": "paint", "rect": (-55, -40, 54, -15), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-55, 15, 54, 39), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-55, -14, -19, 14), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (18, -14, 54, 14), "tile": "grass_dark", "block": True, "forest": True},
            # Trang Cay Khong Lo (quanh Giant Elder Tree o (-4,0))
            {"op": "paint", "rect": (-9, -5, 1, 5), "tile": "grass_flower"},
            {"op": "carve", "rect": (-9, -5, 1, 5)},
            # Loi mon chinh Tay -> Dong (di qua khu cu theo hang ty=1)
            {"op": "carve", "points": [(-55, 1), (-30, 2), (-15, 1), (0, 1), (14, 1), (30, 3), (55, 2)],
             "width": 3, "tile": "dirt"},
            # Nhanh Bac len Cloudpeak tu trang Cay Khong Lo
            {"op": "carve", "points": [(-4, -2), (-2, -8), (2, -11), (5, -14), (5, -26), (5, -40)],
             "width": 2, "tile": "dirt"},
            # Vong mon phu phia Nam + trang Nam
            {"op": "carve", "points": [(-10, 2), (-6, 10), (2, 16), (10, 18), (14, 10), (15, 2)],
             "width": 2, "tile": "dirt"},
            {"op": "paint", "rect": (6, 15, 15, 21), "tile": "grass_tall"},
            {"op": "carve", "rect": (6, 15, 15, 21)},
            # Trang Dong (diem dung chan truoc Heartwood)
            {"op": "paint", "rect": (24, -6, 33, 2), "tile": "grass_tall"},
            {"op": "carve", "rect": (24, -6, 33, 2)},
        ],
        "move": {
            "PortalWest": (-3488, 100),
            "Spawn_from_tandiep": (-3328, 100),
            "Spawn_start": (-3328, 100),
            "PortalEast": (3488, 100),
            "Spawn_from_tim": (3328, 100),
            "PortalNorth": (320, -2528),
            "Spawn_from_nui": (320, -2368),
        },
        "props": {"tex": "oak", "h": 216},
    },

    # ------------------------------------------------------------------
    # HEARTWOOD - noi 33x27 -> 84x62. Rung dac bao quanh, mon vong cung
    # vao trang Cay Than o trung tam (boss Thu Yeu), 2 trang phu.
    # ------------------------------------------------------------------
    "tim_rung": {
        "scene": "tim_rung",
        "biome": "exterior",
        "bounds": (-42, -31, 41, 30),
        "strip": ["BackgroundPlaceholder"],
        "ops": [
            {"op": "fill_base", "tile": "grass", "variants": GRASS_VAR},
            # Rung khoi toan vanh (tru khu cu o giua-Tay)
            {"op": "paint", "rect": (-42, -31, 41, -16), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-42, 16, 41, 30), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-42, -15, -20, 15), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (18, -15, 41, 15), "tile": "grass_dark", "block": True, "forest": True},
            # Trang Cay Than (tam (0,-4), chua boss + goc cay than cu)
            {"op": "paint", "rect": (-7, -11, 7, 3), "tile": "grass_flower"},
            {"op": "carve", "rect": (-7, -11, 7, 3)},
            # Mon chinh: cong Tay -> vong cung xuong trang Than
            {"op": "carve", "points": [(-42, 1), (-16, 1), (-10, 0), (-6, -2), (-2, -4)],
             "width": 3, "tile": "dirt"},
            # Mon phu vong cung phia Nam toi trang Dong
            {"op": "carve", "points": [(-2, 2), (2, 8), (10, 12), (20, 11), (26, 8)],
             "width": 2, "tile": "dirt"},
            {"op": "paint", "rect": (22, 4, 31, 12), "tile": "grass_tall"},
            {"op": "carve", "rect": (22, 4, 31, 12)},
            # Loi cut Bac-Dong (ngo cut kham pha)
            {"op": "carve", "points": [(4, -8), (12, -13), (22, -16), (30, -17)],
             "width": 2, "tile": "dirt"},
            {"op": "paint", "rect": (27, -20, 34, -14), "tile": "grass_tall"},
            {"op": "carve", "rect": (27, -20, 34, -14)},
        ],
        "move": {
            "PortalWest": (-2656, 96),
            "Spawn_from_ria": (-2496, 96),
            "Spawn_start": (-2496, 96),
        },
        "props": {"tex": "oak", "h": 216},
    },

    # ------------------------------------------------------------------
    # MISTLAKE - noi 33x23 -> 110x77. Giu nguyen ho cu (collision
    # Body_WaterCol* san co) va son tile nuoc khop hinh hoc cu; mo rong
    # ho ve phia Tay bang nuoc moi co block. Mon men bo Dong xuong
    # trang chai phia Nam; dong phia Dong chia khu bang lum cay.
    # ------------------------------------------------------------------
    "ho_suong": {
        "scene": "ho_suong",
        "biome": "exterior",
        "bounds": (-55, -38, 54, 38),
        "strip": ["GrassBase", "SandShore", "Lake", "LakeNorthArm",
                  "LakeShine1", "LakeShine2", "Channel", "RoadEW", "RoadShore",
                  "WaterColMain", "WaterColNorth", "WaterColChanW", "WaterColChanE"],
        "ops": [
            {"op": "fill_base", "tile": "grass", "variants": GRASS_VAR},
            # Ho mo rong ve Tay (nuoc moi, co block)
            {"op": "paint", "rect": (-55, -16, -17, 14), "tile": "water", "block": True},
            # Ho cu: son khop collision san co (khong block trung)
            {"op": "paint", "rect": (-16, -11, -3, 10), "tile": "water"},
            {"op": "paint", "rect": (-3, -11, 4, -6), "tile": "water"},
            {"op": "paint", "rect": (-2, -2, 6, -1), "tile": "water"},
            {"op": "shore"},
            # Mon chinh: cong Dong -> bo ho -> xuong phia Nam
            {"op": "carve", "points": [(54, 0), (30, 0), (14, 0), (8, 1), (3, 3), (0, 5), (-2, 8), (-2, 14), (2, 20), (8, 25)],
             "width": 3, "tile": "dirt"},
            # Trang lang chai phia Nam (quanh LabelLangChai (7,4)->(450,300))
            {"op": "paint", "rect": (6, 22, 20, 31), "tile": "sand"},
            {"op": "carve", "rect": (6, 22, 20, 31)},
            # Mon phu len bo Nam nhanh Bac
            {"op": "carve", "points": [(8, 0), (8, -4), (6, -8)], "width": 2, "tile": "dirt"},
            # Lum chia khu dong phia Dong
            {"op": "paint", "rect": (22, 10, 29, 17), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (34, -16, 41, -9), "tile": "grass_dark", "block": True, "forest": True},
            # Trang Dong-Bac
            {"op": "carve", "points": [(16, -2), (24, -5), (31, -5)], "width": 2, "tile": "dirt"},
            {"op": "paint", "rect": (28, -9, 38, -1), "tile": "grass_tall"},
            {"op": "carve", "rect": (28, -9, 38, -1)},
        ],
        "move": {
            "PortalEast": (3488, 0),
            "Spawn_from_machnha": (3328, 0),
            "Spawn_start": (3328, 0),
            "Label_SignEast": (3200, -138),
        },
        "props": {"tex": "oak", "h": 216},
    },

    # ------------------------------------------------------------------
    # THE WALLFOOT - noi 39x25 -> 110x77. Tuong thanh giu o hang ty=-10
    # (khop cong + trai linh cu); phia Bac tuong la doc da chan kin tru
    # hanh lang cong; dong phia Nam chia 3 khu bang lum rung + duong re
    # Tay len Cloudpeak.
    # ------------------------------------------------------------------
    "ngoai_thanh": {
        "scene": "ngoai_thanh",
        "biome": "exterior",
        "bounds": (-55, -38, 54, 38),
        "strip": ["BackgroundPlaceholder"],
        "ops": [
            {"op": "fill_base", "tile": "grass", "variants": GRASS_VAR},
            # Doc da phia Bac tuong (chan kin, tru hanh lang cong x=0)
            {"op": "paint", "rect": (-55, -38, -3, -12), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (3, -38, 54, -12), "tile": "grass_dark", "block": True, "forest": True},
            # Lum chia dong phia Nam
            {"op": "paint", "rect": (-36, 12, -28, 20), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (18, 16, 26, 23), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-14, 26, -8, 32), "tile": "grass_dark", "block": True, "forest": True},
            # Duong truc Nam -> cong thanh
            {"op": "carve", "points": [(0, 38), (0, 24), (-1, 12), (0, 2), (0, -8)],
             "width": 3, "tile": "dirt"},
            # Duong re Tay di Cloudpeak
            {"op": "carve", "points": [(-1, 2), (-10, 2), (-19, 1), (-30, 3), (-42, 2), (-55, 2)],
             "width": 3, "tile": "dirt"},
        ],
        "move": {
            "PortalSouth": (0, 2464),
            "Spawn_from_song": (0, 2304),
            "Spawn_start": (0, 2304),
            "LabelSouth": (-210, 2400),
            "PortalWest": (-3488, 128),
            "Spawn_from_nui": (-3328, 128),
            "LabelWest": (-3200, 80),
        },
        "props": {"tex": "oak", "h": 216},
    },

    # ------------------------------------------------------------------
    # CLOUDPEAK (suon) - noi 33x29 -> 100x75. Ba tang dia hinh: dai vach
    # ngang tai ty=4 va ty=-7 chi chua 1 khe moi dai; duong zic-zac
    # Cong Nam -> be giua (hang golem + mo) -> khe Tay -> be tren -> deo.
    # ------------------------------------------------------------------
    "nui_thanh_van": {
        "scene": "nui_thanh_van",
        "biome": "exterior",
        "bounds": (-50, -38, 49, 36),
        "strip": ["RockBase", "SlopeBand0", "SlopeBand1", "SlopeBand2", "SlopeBand3",
                  "Path0", "Path1", "Path2", "Path3", "Path4", "Path5", "Path6", "Path7",
                  "PathJoint0", "PathJoint1", "PathJoint2", "PathJoint3", "PathJoint4",
                  "PathJoint5", "PathJoint6", "PathJoint7", "PathJoint8",
                  "WestTrail0", "WestTrail1", "CaveBranch0", "CaveBranch1"],
        "ops": [
            {"op": "fill_base", "tile": "grass", "variants": GRASS_VAR},
            # Dai vach tang 1 (ty 3..5), khe tai tx -6..4
            {"op": "paint", "rect": (-50, 3, -7, 5), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (5, 3, 49, 5), "tile": "grass_dark", "block": True, "forest": True},
            # Dai vach tang 2 (ty -8..-6), khe tai tx -14..-10
            {"op": "paint", "rect": (-50, -8, -15, -6), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-9, -8, 49, -6), "tile": "grass_dark", "block": True, "forest": True},
            # Vanh da hai ben phia tren (be tren hep lai)
            {"op": "paint", "rect": (-50, -38, -20, -9), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (14, -38, 49, -9), "tile": "grass_dark", "block": True, "forest": True},
            # Duong chinh zic-zac
            {"op": "carve", "points": [(0, 36), (0, 20), (0, 13), (-1, 8), (-2, 4), (-2, 0), (2, -3), (7, -4)],
             "width": 3, "tile": "dirt"},
            {"op": "carve", "points": [(2, -3), (-4, -5), (-10, -6), (-12, -7), (-12, -12), (-8, -18), (-4, -24), (-3, -32), (-3, -38)],
             "width": 3, "tile": "dirt"},
            # Nhanh Tay xuong Elderwood (duoi dai vach tang 1)
            {"op": "carve", "points": [(-2, 8), (-8, 7), (-15, 6), (-28, 6), (-40, 6), (-50, 6)],
             "width": 3, "tile": "dirt"},
            # Trang phu Dong-Bac o be tren
            {"op": "paint", "rect": (4, -26, 12, -19), "tile": "pebbles"},
            {"op": "carve", "rect": (4, -26, 12, -19)},
            {"op": "carve", "points": [(-3, -24), (0, -23), (4, -22)], "width": 2, "tile": "dirt"},
        ],
        "move": {
            "PortalSouth": (0, 2336),
            "Spawn_from_ngoai": (0, 2176),
            "Spawn_start": (0, 2176),
            "Label_SignSouth": (-80, 2272),
            "PortalWest": (-3168, 390),
            "Spawn_from_rung": (-3008, 390),
            "Label_SignWest": (-2900, 262),
            "PortalDeo": (-150, -2400),
            "Spawn_from_deo": (-150, -2240),
        },
        "props": {"tex": "boulder", "h": 66},
    },

    # ------------------------------------------------------------------
    # CLOUDPEAK PASS (deo) - noi 27x36 -> 60x90. Thung chu S giua hai
    # vach dai: vach Tay/Dong chan kin tru hanh lang uon rong 5 o,
    # 2 diem that tai ty=8 va ty=-16.
    # ------------------------------------------------------------------
    "deo_thanh_van": {
        "scene": "deo_thanh_van",
        "biome": "exterior",
        "bounds": (-30, -45, 29, 44),
        "strip": ["BackgroundPlaceholder"],
        "ops": [
            {"op": "fill_base", "tile": "grass", "variants": GRASS_VAR},
            {"op": "paint", "rect": (-30, -45, -6, 44), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (6, -45, 29, 44), "tile": "grass_dark", "block": True, "forest": True},
            # Hanh lang chu S
            {"op": "carve", "points": [(-8, 44), (-7, 30), (-4, 18), (-2, 8), (0, -2), (-2, -12), (0, -22), (2, -32), (4, -45)],
             "width": 5, "tile": "dirt"},
            # Hai diem that (thu hanh lang con ~3 o)
            {"op": "block", "rect": (-5, 6, -5, 10)},
            {"op": "block", "rect": (1, 6, 1, 10)},
            {"op": "block", "rect": (-4, -18, -4, -14)},
            {"op": "block", "rect": (2, -18, 2, -14)},
            # Be da hai ben hanh lang (noi cu cua quai deo - giu lien thong)
            {"op": "paint", "rect": (-13, 7, -6, 12), "tile": "grass_tall"},
            {"op": "carve", "rect": (-13, 7, -6, 12)},
            {"op": "carve", "points": [(-3, 9), (-6, 9)], "width": 2, "tile": "dirt"},
            {"op": "paint", "rect": (3, 0, 8, 7), "tile": "grass_tall"},
            {"op": "carve", "rect": (3, 0, 8, 7)},
            {"op": "carve", "points": [(-1, 3), (3, 3)], "width": 2, "tile": "dirt"},
            # Tui trang giua deo (diem dung chan)
            {"op": "paint", "rect": (-6, 14, 0, 20), "tile": "pebbles"},
            {"op": "carve", "rect": (-6, 14, 0, 20)},
        ],
        "move": {
            "PortalFoot": (-512, 2848),
            "Spawn_from_suon": (-512, 2688),
            "Spawn_start": (-512, 2688),
            "PortalTop": (288, -2848),
            "Spawn_from_dinh": (288, -2688),
        },
        "props": {"tex": "boulder", "h": 66},
    },

    # ------------------------------------------------------------------
    # CLOUDPEAK SUMMIT (dinh) - noi 27x20 -> 60x48. Be dinh o khu cu
    # trung tam; duong vong cung quanh be; vach bao quanh tru duong
    # xuong deo o phia Nam; trang ngam phia Dong.
    # ------------------------------------------------------------------
    "dinh_thanh_van": {
        "scene": "dinh_thanh_van",
        "biome": "exterior",
        "bounds": (-30, -24, 29, 23),
        "strip": ["BackgroundPlaceholder"],
        "ops": [
            {"op": "fill_base", "tile": "grass", "variants": GRASS_VAR},
            {"op": "paint", "rect": (-30, -24, 29, -14), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-30, 14, 29, 23), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-30, -13, -18, 13), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (18, -13, 29, 13), "tile": "grass_dark", "block": True, "forest": True},
            # Duong vong cung quanh be dinh
            {"op": "carve", "points": [(0, 23), (0, 12), (-4, 4), (-4, -4), (0, -10), (6, -12)],
             "width": 3, "tile": "dirt"},
            {"op": "carve", "points": [(-4, 4), (4, 6), (10, 4), (14, 0)], "width": 2, "tile": "dirt"},
            # Trang ngam phia Dong
            {"op": "paint", "rect": (12, -4, 17, 3), "tile": "pebbles"},
            {"op": "carve", "rect": (12, -4, 17, 3)},
        ],
        "move": {
            "PortalDown": (0, 1504),
            "Spawn_from_deo": (0, 1344),
            "Spawn_start": (0, 1344),
        },
        "props": {"tex": "boulder", "h": 66},
    },

    # ------------------------------------------------------------------
    # BLUESTONE MINE (san mo) - noi 30x22 -> 84x64. Duong tu mieng Bac
    # xuong lan phu mo (giu cum cu + NPC phu mo phia Tay-Nam); ho mo
    # phia Dong bao quanh bang vach vong cung; duong cong o Dong-Nam.
    # ------------------------------------------------------------------
    "mo_da_xanh": {
        "scene": "mo_da_xanh",
        "biome": "exterior",
        "bounds": (-42, -32, 41, 31),
        "strip": ["BackgroundPlaceholder"],
        "ops": [
            {"op": "fill_base", "tile": "grass", "variants": GRASS_VAR},
            # Vach bao quanh 3 phia (tru mieng Bac va cong Dong-Nam)
            {"op": "paint", "rect": (-42, -32, -20, 31), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (24, -32, 41, 2), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-42, 24, 41, 31), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-19, -32, -3, -24), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (3, -32, 23, -24), "tile": "grass_dark", "block": True, "forest": True},
            # Mat san ho mo phia Dong
            {"op": "paint", "rect": (13, -8, 26, 8), "tile": "dirt"},
            {"op": "paint", "rect": (15, -6, 24, 6), "tile": "pebbles"},
            {"op": "carve", "rect": (13, -8, 26, 8)},
            # Duong chinh: mieng Bac -> giua san -> lan phu mo / cong
            {"op": "carve", "points": [(0, -31), (0, -12), (0, 0), (-2, 8), (-8, 10)],
             "width": 3, "tile": "dirt"},
            {"op": "carve", "points": [(0, 0), (6, 4), (10, 9), (16, 12), (24, 12), (32, 10), (41, 9)],
             "width": 3, "tile": "dirt"},
            # Duong vao ho mo
            {"op": "carve", "points": [(2, -2), (8, -4), (13, -4)], "width": 2, "tile": "dirt"},
        ],
        "move": {
            "PortalMouth": (0, -2016),
            "Spawn_from_nui": (0, -1856),
            "Spawn_start": (0, -1856),
            "PortalSewer": (2656, 576),
            "Spawn_from_cong": (2496, 480),
        },
        "props": {"tex": "boulder", "h": 66},
    },

    # ------------------------------------------------------------------
    # DUONG DI NAM (truc duong xuong Fenmire) - noi 15x16 -> 60x80.
    # Cum cong/spawn phia Bac GIU NGUYEN (lien ket cong nguoc). Duong
    # keo dai xuong Nam: uon nhe, 1 lach ngang co cau van tai ty=14,
    # lum cay 2 ben chia doan, vong cong da o cuoi duong phia Nam.
    # ------------------------------------------------------------------
    "duong_di_nam": {
        "scene": "duong_di_nam",
        "biome": "exterior",
        "bounds": (-30, -40, 29, 39),
        "strip": ["BackgroundPlaceholder", "Trail"],
        "ops": [
            {"op": "fill_base", "tile": "grass", "variants": GRASS_VAR},
            # Lum chan 2 ben duong
            {"op": "paint", "rect": (-30, -6, -10, 6), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (10, -6, 29, 6), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (-30, 22, -12, 34), "tile": "grass_dark", "block": True, "forest": True},
            {"op": "paint", "rect": (12, 22, 29, 34), "tile": "grass_dark", "block": True, "forest": True},
            # Lach ngang (cat duong tai ty 13..15)
            {"op": "paint", "points": [(-30, 14), (-14, 13), (0, 14), (14, 15), (30, 14)],
             "width": 3, "tile": "water", "block": True},
            {"op": "shore"},
            # Duong chinh (lien tuc qua cau)
            {"op": "carve", "points": [(0, -8), (0, 4), (-1, 14), (0, 24), (1, 34), (0, 39)],
             "width": 3, "tile": "dirt"},
            # Vong cong da cuoi duong
            {"op": "paint", "rect": (-4, 35, 4, 39), "tile": "pebbles"},
            {"op": "carve", "rect": (-4, 35, 4, 39)},
        ],
        "move": {},
        "props": {"tex": "oak", "h": 216},
    },

    # ------------------------------------------------------------------
    # BARLEYFIELD (nhom A, 143x102 - khong noi, khong son lai nen):
    # bien kenh cu (CanalBody tai ty=2, chua cau tai tx -1..0) thanh
    # SONG NHANH Clearwater chay ngang Dong-Tay: son nuoc ty 1..3 +
    # block bo sung (collision cu chi day 55px o ty 2), cau cu giu.
    # Hang rao goc chia ruong phia Dong thanh 2 khu, chua hanh lang ho.
    # ------------------------------------------------------------------
    "dong_mach_nha": {
        "scene": "dong_mach_nha",
        "biome": "exterior",
        "ops": [
            {"op": "paint", "rect": (-71, 1, 98, 3), "tile": "water", "block": True},
            {"op": "shore"},
            # Cau cu tai tx -1..0 (go block ca 3 hang, son mat cau)
            {"op": "carve", "rect": (-1, 1, 0, 3)},
            {"op": "paint", "rect": (-1, 1, 0, 3), "tile": "dirt"},
            # Hang rao chia ruong phia Dong (chua ho ty -9..7)
            {"op": "paint", "rect": (14, -32, 14, -10), "tile": "fence_v", "block": True},
            {"op": "paint", "rect": (14, 8, 14, 28), "tile": "fence_v", "block": True},
        ],
    },
}
