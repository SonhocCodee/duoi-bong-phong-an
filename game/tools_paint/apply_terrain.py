#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""APPLY TERRAIN - cau truc lai dia hinh map da ngoai bang TEXT (khong pack+save).

Doc spec tu terrain_specs.py (dict theo ten map) va sua .tscn:
 - Them/sua TileMap "TerrainTiles" (map chua co TileMap) hoac sua tile_data
   cua GroundTiles san co (map da co TileMap): son nen, song, duong, rung...
 - Them StaticBody2D "TerrainBlocks" + CollisionShape2D phan ra tu vung block.
 - Them Node2D "TerrainProps" chua prop cay ria rung (pattern nhu MapBorder).
 - Strip node nen phang cu (BackgroundPlaceholder / polygon nen) theo spec.
 - Di chuyen portal/spawn/label ra bien moi theo spec (chi node liet ke).
 - Cap nhat 4 border collision theo bien moi (khi spec co "bounds").
 - Sua loi san co: schedule = Array[String]([]) -> Array[Dictionary]([])
   (chi 3 map bi loi nay: ho_suong, mo_da_xanh, dat_chet).

Idempotent: TerrainTiles/TerrainBlocks/TerrainProps cua lan chay truoc bi
xoa va lam lai tu spec; load_steps chinh theo delta resource thuc te.

He toa do: O TILE (tx,ty), tam o = (tx*64+32, ty*64+32) px. Voi TileMap
moi position=(0,0) nen o tile == o the gioi. Voi GroundTiles san co, engine
doc position cua TileMap va quy doi: o the gioi -> o tilemap cong offset.

Chay: python3 game/tools_paint/apply_terrain.py <ten_map> [<ten_map>...]
"""
import json
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MAPS_DIR = os.path.join(ROOT, "game", "maps")
TILE = 64

# Bang tile theo vung: ten logic -> (atlas_x, atlas_y). Nguon: paint_*.gd.
TILES = {
    "exterior": {
        "grass": (0, 0), "grass_flower": (1, 0), "grass_tall": (2, 0),
        "grass_sparse": (3, 0), "dirt": (4, 0), "field": (5, 0),
        "water_a": (6, 0), "water_b": (7, 0),
        "path_s": (0, 1), "path_n": (1, 1), "path_w": (2, 1), "path_e": (3, 1),
        "shore_s": (6, 1), "shore_n": (7, 1),
        "shore_w": (0, 2), "shore_e": (1, 2), "shore_corner": (2, 2),
        "fence_h": (3, 2), "fence_v": (4, 2), "pebbles": (5, 2),
        "grass_dark": (6, 2), "sand": (7, 2),
    },
    "swamp": {
        "water_a": (0, 0), "water_b": (1, 0), "water_deep": (2, 0),
        "mud_wet": (3, 0), "mud_dry": (4, 0),
        "grass": (0, 1), "grass_reeds": (1, 1),
        "plank": (2, 1), "plank_mossy": (3, 1), "shore_s": (4, 1),
        "shore_n": (0, 2), "shore_w": (1, 2), "shore_e": (2, 2),
        "shore_cvx": (3, 2), "shore_ccv": (4, 2),
        "mud_shore_s": (0, 3), "mud_shore_n": (1, 3), "mud_path_s": (2, 3),
    },
    "desert": {
        "sand": (0, 0), "dune": (1, 0), "rocky": (2, 0), "cracked": (3, 0),
        "water_a": (4, 0), "water_b": (0, 1),
        "shore_s": (1, 1), "shore_n": (2, 1), "shore_w": (3, 1),
        "shore_e": (4, 1), "shore_cvx": (0, 2), "shore_ccv": (1, 2),
        "dry_grass": (2, 2), "stone_floor": (3, 2), "stone_brick": (4, 2),
        "bone": (0, 3), "path_s": (1, 3), "path_n": (2, 3),
        "scrub": (3, 3), "sand_pad": (4, 3),
    },
    "winter": {
        "snow": (0, 0), "drift": (1, 0), "rocky_snow": (2, 0),
        "ice": (3, 0), "ice_shine": (4, 0), "deep_ice": (0, 1),
        "shore_s": (1, 1), "shore_n": (2, 1), "shore_w": (3, 1),
        "shore_e": (4, 1), "shore_cvx": (0, 2), "shore_ccv": (1, 2),
        "frost_grass": (2, 2), "stone_floor": (3, 2), "dark_brick": (4, 2),
        "ash_snow": (0, 3), "path_s": (1, 3), "path_n": (2, 3),
        "dead_scrub": (3, 3), "packed_snow": (4, 3),
    },
}
TILESET_PATH = {
    "exterior": "res://assets/tilesets/exterior_v1.tres",
    "swamp": "res://assets/tilesets/swamp_v1.tres",
    "desert": "res://assets/tilesets/desert_v1.tres",
    "winter": "res://assets/tilesets/winter_v1.tres",
}


def h2(x, y, salt=0):
    """Hash deterministic theo o -> [0,1)."""
    v = (x * 374761393 + y * 668265263 + salt * 974634211) & 0xFFFFFFFF
    v = ((v ^ (v >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((v ^ (v >> 16)) & 0xFFFFFF) / float(0x1000000)


def fmt_num(v):
    v = float(v)
    if abs(v - round(v)) < 1e-9:
        return str(int(round(v)))
    return ("%.4f" % v).rstrip("0").rstrip(".")


# ---------------------------------------------------------------------------
# Phan tich .tscn thanh cac block: prefix (gd_scene+ext+sub) + node blocks.
# ---------------------------------------------------------------------------

def split_blocks(txt):
    idx = txt.find("[node ")
    if idx < 0:
        return txt, []
    prefix = txt[:idx]
    body = txt[idx:]
    parts = re.split(r"(?=\[node )", body)
    blocks = []
    for p in parts:
        if not p.strip():
            continue
        header = p.split("\n", 1)[0]
        m = re.search(r'\[node name="([^"]+)"', header)
        parent = re.search(r'parent="([^"]*)"', header)
        blocks.append({
            "name": m.group(1) if m else "",
            "parent": parent.group(1) if parent else None,
            "text": p,
        })
    return prefix, blocks


def node_pos(block_text):
    m = re.search(r"^position = Vector2\((-?[\d.]+), (-?[\d.]+)\)", block_text, flags=re.M)
    if m:
        return float(m.group(1)), float(m.group(2))
    return None


def set_node_pos(block_text, x, y):
    line = "position = Vector2(%s, %s)" % (fmt_num(x), fmt_num(y))
    if re.search(r"^position = Vector2\(", block_text, flags=re.M):
        return re.sub(r"^position = Vector2\([^)]*\)", line, block_text, count=1, flags=re.M)
    # Chen ngay sau header
    nl = block_text.find("\n")
    return block_text[:nl + 1] + line + "\n" + block_text[nl + 1:]


# ---------------------------------------------------------------------------
# Tile data (Godot 4): moi o 3 int32: x|(y<<16), src|(atlas_x<<16), atlas_y|(alt<<16)
# ---------------------------------------------------------------------------

def enc_cell(x, y, ax, ay):
    def s32(v):
        v &= 0xFFFFFFFF
        return v - 0x100000000 if v >= 0x80000000 else v
    return (s32((x & 0xFFFF) | ((y & 0xFFFF) << 16)),
            s32((ax & 0xFFFF) << 16),
            s32(ay & 0xFFFF))


def parse_tile_data(s):
    vals = [int(v) for v in s.split(",") if v.strip()]
    cells = {}
    for i in range(0, len(vals) - 2, 3):
        a, b, c = vals[i], vals[i + 1], vals[i + 2]
        x = a & 0xFFFF
        y = (a >> 16) & 0xFFFF
        if x >= 0x8000:
            x -= 0x10000
        if y >= 0x8000:
            y -= 0x10000
        ax = (b >> 16) & 0xFFFF
        ay = c & 0xFFFF
        cells[(x, y)] = (ax, ay)
    return cells


def dump_tile_data(cells):
    out = []
    for (x, y) in sorted(cells.keys(), key=lambda k: (k[1], k[0])):
        ax, ay = cells[(x, y)]
        out.extend(enc_cell(x, y, ax, ay))
    return ", ".join(str(v) for v in out)


# ---------------------------------------------------------------------------
# Raster hoa hinh hoc theo o
# ---------------------------------------------------------------------------

def raster_polyline(points, width, widths=None):
    """Tra ve set o bi phu boi polyline day `width` o (but tron).
    `widths`: be rong rieng cho tung diem neo — noi suy tuyen tinh doc doan
    (song uon rong/hep theo doan)."""
    cells = set()
    pts = [(float(px), float(py)) for px, py in points]
    ws = [float(w) for w in widths] if widths else [float(width)] * len(pts)
    if len(ws) < 2:
        ws = ws * 2
    segs = list(zip(pts, pts[1:])) if len(pts) > 1 else [(pts[0], pts[0])]
    for si, ((x1, y1), (x2, y2)) in enumerate(segs):
        steps = max(1, int(math.hypot(x2 - x1, y2 - y1) * 4))
        for i in range(steps + 1):
            t = i / steps
            rr = (ws[si] + (ws[si + 1] - ws[si]) * t) / 2.0
            cx, cy = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
            for dx in range(int(math.floor(-rr)), int(math.ceil(rr)) + 1):
                for dy in range(int(math.floor(-rr)), int(math.ceil(rr)) + 1):
                    if math.hypot(dx, dy) <= rr + 0.01:
                        cells.add((int(round(cx)) + dx, int(round(cy)) + dy))
    return cells


def rect_cells(x0, y0, x1, y1):
    return {(x, y) for x in range(min(x0, x1), max(x0, x1) + 1)
            for y in range(min(y0, y1), max(y0, y1) + 1)}


def decompose_rects(blocked):
    """Phan ra tap o thanh cac hinh chu nhat (px) bang greedy gop hang + gop doc."""
    rows = {}
    for (x, y) in blocked:
        rows.setdefault(y, []).append(x)
    spans_by_y = {}
    for y, xs in rows.items():
        xs.sort()
        spans = []
        start = prev = xs[0]
        for x in xs[1:]:
            if x == prev + 1:
                prev = x
            else:
                spans.append((start, prev))
                start = prev = x
        spans.append((start, prev))
        spans_by_y[y] = spans
    rects = []  # (x0, y0, x1, y1) theo o
    used = set()
    ys = sorted(spans_by_y.keys())
    for y in ys:
        for (a, b) in spans_by_y[y]:
            if (y, a, b) in used:
                continue
            y2 = y
            while (y2 + 1 in spans_by_y and (a, b) in spans_by_y[y2 + 1]
                   and (y2 + 1, a, b) not in used):
                y2 += 1
                used.add((y2, a, b))
            used.add((y, a, b))
            rects.append((a, y, b, y2))
    return rects


# ---------------------------------------------------------------------------
# Ap spec vao mot map
# ---------------------------------------------------------------------------

TERRAIN_NODE_NAMES = {"TerrainTiles", "TerrainBlocks", "TerrainProps"}


def is_terrain_block(b):
    return (b["name"] in TERRAIN_NODE_NAMES or b["parent"] in TERRAIN_NODE_NAMES
            or (b["parent"] or "").startswith("TerrainProps/")
            or (b["parent"] or "").startswith("TerrainBlocks/"))


PROTECT_EXCLUDE = {
    "Collisions", "Borders", "MapBorder", "TerrainTiles", "TerrainBlocks",
    "TerrainProps", "BackgroundPlaceholder", "GroundTiles", "StoneTiles",
    "BridgeTiles", "WorldCollision",
}


def collect_protected(txt, blocks, dump_entry):
    """O bao ve: moi node con truc tiep cua root co position (portal, spawn,
    NPC, quai, herb, craft, cay co collision, nha...) tru node nen/collision
    thuan tuy + waypoint lich trinh NPC trich tu property schedule."""
    prot = set()
    for b in blocks:
        if b["parent"] != "." or b["name"] in PROTECT_EXCLUDE:
            continue
        pos = node_pos(b["text"])
        if pos is None:
            continue
        prot.add((int(math.floor(pos[0] / TILE)), int(math.floor(pos[1] / TILE))))
    if dump_entry:
        for key in ("portals", "spawns", "npcs", "blockers_entities"):
            for e in dump_entry.get(key, []):
                pos = e.get("pos")
                if not pos:
                    continue
                px, py = pos[0], pos[1]
                prot.add((int(math.floor(px / TILE)), int(math.floor(py / TILE))))
    # Waypoint lich trinh NPC: {"x": .., "y": ..} trong property schedule
    for m in re.finditer(r'"x":\s*(-?[\d.]+),\s*"y":\s*(-?[\d.]+)', txt):
        px, py = float(m.group(1)), float(m.group(2))
        prot.add((int(math.floor(px / TILE)), int(math.floor(py / TILE))))
    return prot


def apply_map(spec, dump):
    name = spec["scene"]
    fpath = os.path.join(MAPS_DIR, name + ".tscn")
    txt = open(fpath, encoding="utf-8").read()
    biome = spec.get("biome", "exterior")
    tiles = TILES[biome]
    warnings = []

    # --- Sua loi schedule Array[String] san co (neu co) ---
    txt = txt.replace("schedule = Array[String]([])", "schedule = Array[Dictionary]([])")

    prefix, blocks = split_blocks(txt)

    # --- Xoa terrain cua lan chay truoc (idempotent) ---
    removed_sub_ids = set()
    for b in blocks:
        if b["name"] == "TerrainBlocks" or b["parent"] == "TerrainBlocks":
            for m in re.finditer(r'shape = SubResource\("([^"]+)"\)', b["text"]):
                removed_sub_ids.add(m.group(1))
    blocks = [b for b in blocks if not is_terrain_block(b)]
    if removed_sub_ids:
        for sid in removed_sub_ids:
            prefix = re.sub(
                r'\[sub_resource type="RectangleShape2D" id="%s"\]\nsize = Vector2\([^)]*\)\n\n?' % re.escape(sid),
                "", prefix)

    # --- ext_resource hien co ---
    ext = {}
    for m in re.finditer(r'\[ext_resource type="([^"]+)" path="([^"]+)" id="([^"]+)"\]', prefix):
        ext[m.group(2)] = m.group(3)
    new_ext = []  # (type, path, id)

    def ensure_ext(type_, path, rid):
        if path in ext:
            return ext[path]
        ext[path] = rid
        new_ext.append((type_, path, rid))
        return rid

    # --- Tim TileMap dich ---
    tm_idx = None
    tm_offset = (0, 0)  # o tilemap = o the gioi + offset (theo o)
    tm_cells = {}
    for i, b in enumerate(blocks):
        if b["name"] in ("TerrainTiles", "GroundTiles") and 'type="TileMap"' in b["text"].split("\n", 1)[0]:
            tm_idx = i
            break
    created_tm = False
    if tm_idx is not None:
        b = blocks[tm_idx]
        pos = node_pos(b["text"]) or (0.0, 0.0)
        tm_offset = (int(round(pos[0] / TILE)), int(round(pos[1] / TILE)))
        m = re.search(r"layer_0/tile_data = PackedInt32Array\(([^)]*)\)", b["text"])
        if m:
            tm_cells = parse_tile_data(m.group(1))
    else:
        ts_id = ensure_ext("TileSet", TILESET_PATH[biome], "ter_tileset")
        tm_block = {
            "name": "TerrainTiles", "parent": ".",
            "text": ('[node name="TerrainTiles" type="TileMap" parent="."]\n'
                     "z_index = -10\n"
                     'tile_set = ExtResource("%s")\n'
                     "format = 2\n"
                     "layer_0/tile_data = PackedInt32Array()\n"),
        }
        tm_idx = 1 if len(blocks) > 0 else 0  # ngay sau node goc
        blocks.insert(tm_idx, tm_block)
        created_tm = True

    # --- Bien map (o the gioi) ---
    if spec.get("bounds"):
        bx0, by0, bx1, by1 = spec["bounds"]
    else:
        xs = [c[0] for c in tm_cells]
        ys = [c[1] for c in tm_cells]
        gx0, gy0 = min(xs) + tm_offset[0], min(ys) + tm_offset[1]
        gx1, gy1 = max(xs) + tm_offset[0], max(ys) + tm_offset[1]
        bx0, by0, bx1, by1 = gx0, gy0, gx1, gy1

    # --- O bao ve (khong duoc block de len) ---
    dump_entry = dump.get(name) if dump else None
    protected = collect_protected(txt, blocks, dump_entry)
    protected_dilated = set()
    for (x, y) in protected:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                protected_dilated.add((x + dx, y + dy))

    # --- Ap cac op theo thu tu ---
    paint = {}   # (x,y) o the gioi -> ten tile logic
    blocked = set()
    forest = set()

    def op_cells(op):
        if "rect" in op:
            return rect_cells(*op["rect"])
        if "points" in op:
            return raster_polyline(op["points"], op.get("width", 2), op.get("widths"))
        if "cells" in op:
            return {tuple(c) for c in op["cells"]}
        return set()

    for op in spec.get("ops", []):
        kind = op["op"]
        if kind == "fill_base":
            base = op.get("tile", "grass")
            variants = op.get("variants", {})
            for x in range(bx0, bx1 + 1):
                for y in range(by0, by1 + 1):
                    t = base
                    hv = h2(x, y, 7)
                    acc = 0.0
                    for vn, prob in variants.items():
                        acc += prob
                        if hv < acc:
                            t = vn
                            break
                    paint[(x, y)] = t
            continue
        cells = op_cells(op)
        cells = {c for c in cells if bx0 <= c[0] <= bx1 and by0 <= c[1] <= by1}
        if kind == "shore":
            water_cells = {c for c, t in paint.items() if t in ("water_a", "water_b")}
            for (x, y) in water_cells:
                for dx, dy, tn in ((0, -1, "shore_n"), (0, 1, "shore_s"),
                                   (-1, 0, "shore_w"), (1, 0, "shore_e")):
                    nc = (x + dx, y + dy)
                    if nc not in water_cells and paint.get(nc, "").startswith("grass"):
                        paint[nc] = tn
            continue
        if kind == "paint":
            tile = op["tile"]
            for c in cells:
                if tile == "water":
                    paint[c] = "water_a" if (c[0] + c[1]) % 2 == 0 else "water_b"
                    forest.discard(c)
                elif tile == "base_variants":
                    pass
                else:
                    paint[c] = tile
            if op.get("forest"):
                forest |= cells
            if op.get("block"):
                bad = cells & protected_dilated
                if bad:
                    warnings.append("op paint %s block trung %d o bao ve (da carve)" % (op.get("tile"), len(bad)))
                    cells -= protected_dilated
                blocked |= cells
        elif kind == "carve":
            blocked -= cells
            if op.get("tile"):
                for c in cells:
                    paint[c] = op["tile"]
        elif kind == "block":
            bad = cells & protected_dilated
            if bad:
                warnings.append("op block trung %d o bao ve (da carve)" % len(bad))
                cells -= protected_dilated
            blocked |= cells
            if op.get("forest"):
                forest |= cells
    # O bao ve khong bao gio bi block boi dot nay
    blocked -= protected_dilated
    # Chi giu block trong bien
    blocked = {c for c in blocked if bx0 <= c[0] <= bx1 and by0 <= c[1] <= by1}

    # --- Ghi tile vao TileMap dich (quy doi sang o tilemap) ---
    for (x, y), tname in paint.items():
        if tname not in tiles:
            warnings.append("tile khong co trong biome %s: %s" % (biome, tname))
            continue
        tm_cells[(x - tm_offset[0], y - tm_offset[1])] = tiles[tname]
    b = blocks[tm_idx]
    data_str = dump_tile_data(tm_cells)
    if "layer_0/tile_data = PackedInt32Array(" in b["text"]:
        b["text"] = re.sub(r"layer_0/tile_data = PackedInt32Array\([^)]*\)",
                            "layer_0/tile_data = PackedInt32Array(%s)" % data_str,
                            b["text"], count=1)
    else:
        b["text"] = b["text"].rstrip("\n") + "\nlayer_0/tile_data = PackedInt32Array(%s)\n" % data_str
    if created_tm:
        b["text"] = b["text"] % ext[TILESET_PATH[biome]]

    # --- TerrainBlocks: phan ra blocked thanh rect ---
    rects = decompose_rects(blocked)
    new_sub = []
    block_nodes = []
    if rects:
        block_nodes.append('[node name="TerrainBlocks" type="StaticBody2D" parent="."]\n')
        for i, (rx0, ry0, rx1, ry1) in enumerate(rects):
            sid = "RectangleShape2D_ter%d" % i
            wpx = (rx1 - rx0 + 1) * TILE
            hpx = (ry1 - ry0 + 1) * TILE
            cx = rx0 * TILE + wpx / 2.0
            cy = ry0 * TILE + hpx / 2.0
            new_sub.append('[sub_resource type="RectangleShape2D" id="%s"]\nsize = Vector2(%s, %s)\n'
                           % (sid, fmt_num(wpx), fmt_num(hpx)))
            block_nodes.append('[node name="TB%d" type="CollisionShape2D" parent="TerrainBlocks"]\n'
                               "position = Vector2(%s, %s)\n"
                               'shape = SubResource("%s")\n' % (i, fmt_num(cx), fmt_num(cy), sid))

    # --- TerrainProps: cay ria rung ---
    prop_nodes = []
    if spec.get("props"):
        pr = spec["props"]
        tex = pr["tex"]
        tex_id = ensure_ext("Texture2D", "res://assets/props/%s.png" % tex, "ter_" + tex)
        edge_cells = []
        for c in forest:
            if c not in blocked:
                continue
            near_open = any((c[0] + dx, c[1] + dy) not in blocked
                            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            hv = h2(c[0], c[1], 31)
            if near_open and hv < pr.get("edge_prob", 0.85):
                edge_cells.append(c)
            elif not near_open and hv < pr.get("inner_prob", 0.18):
                edge_cells.append(c)
        edge_cells.sort()
        if edge_cells:
            prop_nodes.append('[node name="TerrainProps" type="Node2D" parent="."]\ny_sort_enabled = true\n')
            for i, (x, y) in enumerate(edge_cells):
                jx = (h2(x, y, 41) - 0.5) * 26
                jy = (h2(x, y, 43) - 0.5) * 18
                scl = 0.9 + h2(x, y, 47) * 0.3
                px = x * TILE + 32 + jx
                py = y * TILE + 32 + jy
                off_y = -float(pr.get("h", 216)) * scl / 2.0 + 8.0
                flip = "\nflip_h = true" if h2(x, y, 53) < 0.5 else ""
                prop_nodes.append(
                    '[node name="T_%s_%03d" type="Node2D" parent="TerrainProps"]\n'
                    "position = Vector2(%s, %s)\n"
                    "y_sort_enabled = true\n"
                    "\n"
                    '[node name="Sprite2D" type="Sprite2D" parent="TerrainProps/T_%s_%03d"]\n'
                    "position = Vector2(0, %s)\n"
                    "scale = Vector2(%s, %s)\n"
                    'texture = ExtResource("%s")%s\n'
                    % (tex, i, fmt_num(px), fmt_num(py), tex, i,
                       fmt_num(off_y), fmt_num(scl), fmt_num(scl), tex_id, flip))

    # --- Strip node nen cu ---
    for sname in spec.get("strip", []):
        before = len(blocks)
        blocks = [bb for bb in blocks if not (bb["name"] == sname and bb["parent"] == ".")]
        if len(blocks) == before:
            warnings.append("strip khong thay node: %s" % sname)

    # --- Di chuyen node ---
    for mv_name, (mx, my) in spec.get("move", {}).items():
        hit = False
        for bb in blocks:
            if bb["name"] == mv_name:
                bb["text"] = set_node_pos(bb["text"], mx, my)
                hit = True
        if not hit:
            warnings.append("move khong thay node: %s" % mv_name)

    # --- Cap nhat border theo bien moi ---
    if spec.get("bounds") and spec.get("update_borders", True):
        rect_px = (bx0 * TILE, by0 * TILE, (bx1 - bx0 + 1) * TILE, (by1 - by0 + 1) * TILE)
        prefix = update_borders(prefix, blocks, rect_px, warnings)

    # --- Ghep file: them ext moi + sub moi vao prefix ---
    if new_ext:
        lines = ['[ext_resource type="%s" path="%s" id="%s"]' % (t, p, i) for (t, p, i) in new_ext]
        matches = list(re.finditer(r"^\[ext_resource [^\]]*\]\n", prefix, flags=re.M))
        if matches:
            pos = matches[-1].end()
            prefix = prefix[:pos] + "\n".join(lines) + "\n" + prefix[pos:]
        else:
            prefix = prefix + "\n".join(lines) + "\n"
    if new_sub:
        # Chen sub moi ngay truoc [node dau tien (cuoi prefix)
        prefix = prefix.rstrip("\n") + "\n\n" + "\n\n".join(new_sub) + "\n\n"

    # --- load_steps: delta = ext moi + sub moi - sub cu da xoa ---
    delta = len(new_ext) + len(new_sub) - len(removed_sub_ids)
    m = re.search(r"load_steps=(\d+)", prefix)
    if m and delta != 0:
        prefix = re.sub(r"load_steps=(\d+)",
                        "load_steps=%d" % (int(m.group(1)) + delta), prefix, count=1)

    out_txt = prefix + "".join(bb["text"] for bb in blocks)
    if block_nodes:
        out_txt = out_txt.rstrip("\n") + "\n\n" + "\n".join(block_nodes)
    if prop_nodes:
        out_txt = out_txt.rstrip("\n") + "\n\n" + "\n".join(prop_nodes)
    out_txt = out_txt.rstrip("\n") + "\n"
    open(fpath, "w", encoding="utf-8").write(out_txt)
    print("%s: paint=%d blocked=%d rects=%d props=%d tm_offset=%s%s"
          % (name, len(paint), len(blocked), len(rects),
             sum(1 for p in prop_nodes if p.startswith('[node name="T_')),
             tm_offset, " [TM moi]" if created_tm else ""))
    for w in warnings:
        print("   WARN:", w)
    return warnings


def set_sub_size(prefix, sid, w, h):
    pat = re.compile(r'(\[sub_resource type="RectangleShape2D" id="%s"\]\nsize = Vector2\()[^)]*(\))'
                     % re.escape(sid))
    new_prefix, n = pat.subn(r"\g<1>%s, %s\g<2>" % (fmt_num(w), fmt_num(h)), prefix, count=1)
    return new_prefix, n


def get_sub_size(prefix, sid):
    m = re.search(r'\[sub_resource type="RectangleShape2D" id="%s"\]\nsize = Vector2\((-?[\d.]+), (-?[\d.]+)\)'
                  % re.escape(sid), prefix)
    if m:
        return float(m.group(1)), float(m.group(2))
    return None


def update_borders(prefix, blocks, rect_px, warnings):
    """Sua 4 border (Border*/Col*) theo rect the gioi moi: keo dai shape +
    dat lai tam ra ngoai bien dung bang nua do day (giu do day cu)."""
    x0, y0, w, h = rect_px
    cx, cy = x0 + w / 2.0, y0 + h / 2.0
    found = 0
    for bb in blocks:
        nm = bb["name"]
        if nm not in ("BorderTop", "BorderBottom", "BorderLeft", "BorderRight",
                      "ColTop", "ColBottom", "ColLeft", "ColRight"):
            continue
        m = re.search(r'shape = SubResource\("([^"]+)"\)', bb["text"])
        if not m:
            continue
        old = get_sub_size(prefix, m.group(1))
        thick = 44.0
        if old:
            thick = old[1] if nm in ("BorderTop", "BorderBottom", "ColTop", "ColBottom") else old[0]
            if thick <= 0 or thick > 200:
                thick = 44.0
        if nm in ("BorderTop", "ColTop"):
            prefix, n = set_sub_size(prefix, m.group(1), w + 2 * thick, thick)
            bb["text"] = set_node_pos(bb["text"], cx, y0 - thick / 2.0)
        elif nm in ("BorderBottom", "ColBottom"):
            prefix, n = set_sub_size(prefix, m.group(1), w + 2 * thick, thick)
            bb["text"] = set_node_pos(bb["text"], cx, y0 + h + thick / 2.0)
        elif nm in ("BorderLeft", "ColLeft"):
            prefix, n = set_sub_size(prefix, m.group(1), thick, h + 2 * thick)
            bb["text"] = set_node_pos(bb["text"], x0 - thick / 2.0, cy)
        else:
            prefix, n = set_sub_size(prefix, m.group(1), thick, h + 2 * thick)
            bb["text"] = set_node_pos(bb["text"], x0 + w + thick / 2.0, cy)
        found += 1
    if found < 4:
        warnings.append("update_borders: chi tim thay %d/4 border" % found)
    return prefix


def main():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    mod_name = os.environ.get("TERRAIN_SPEC_MODULE", "terrain_specs")
    import importlib
    SPECS = importlib.import_module(mod_name).SPECS
    dump = None
    if os.path.exists("/tmp/terrain_dump.json"):
        dump = json.load(open("/tmp/terrain_dump.json", encoding="utf-8"))
    names = sys.argv[1:]
    if not names:
        print("Dung: apply_terrain.py <ten_map> [...]")
        return 1
    for n in names:
        if n not in SPECS:
            print("Khong co spec cho map:", n)
            return 1
        apply_map(SPECS[n], dump)
    return 0


if __name__ == "__main__":
    sys.exit(main())
