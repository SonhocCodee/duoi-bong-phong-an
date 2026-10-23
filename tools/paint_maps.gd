extends Node2D
## Tool mot lan: ap tileset mau + prop len 3 map mo dau.
## Chay: godot --headless --path game res://tools_paint/paint_maps.tscn
## Chu giai tile lay tu tools/gen_tileset_v1.py (EXTERIOR_ORDER 8 cot, INTERIOR_ORDER 4 cot).

const TILE := 64.0

# Exterior atlas (col,row) theo EXTERIOR_ORDER trong gen_tileset_v1.py
const EXT := {
    "grass": Vector2i(0, 0), "grass_flower": Vector2i(1, 0), "grass_tall": Vector2i(2, 0),
    "grass_sparse": Vector2i(3, 0), "dirt": Vector2i(4, 0), "field": Vector2i(5, 0),
    "water_a": Vector2i(6, 0), "water_b": Vector2i(7, 0),
    "path_s": Vector2i(0, 1), "path_n": Vector2i(1, 1), "path_w": Vector2i(2, 1),
    "path_e": Vector2i(3, 1), "path_corner_convex": Vector2i(4, 1), "path_corner_concave": Vector2i(5, 1),
    "shore_s": Vector2i(6, 1), "shore_n": Vector2i(7, 1),
    "shore_w": Vector2i(0, 2), "shore_e": Vector2i(1, 2), "shore_corner": Vector2i(2, 2),
    "fence_h": Vector2i(3, 2), "fence_v": Vector2i(4, 2), "pebbles": Vector2i(5, 2),
    "grass_dark": Vector2i(6, 2), "sand": Vector2i(7, 2),
}
# Interior atlas (col,row) theo INTERIOR_ORDER
const INT := {
    "floor_a": Vector2i(0, 0), "floor_b": Vector2i(1, 0), "floor_dark": Vector2i(2, 0),
    "wall_plank": Vector2i(3, 0), "wall_stone": Vector2i(0, 1), "stone_floor": Vector2i(1, 1),
    "rug": Vector2i(2, 1), "floor_c": Vector2i(3, 1),
}
const PROP_SIZE := {
    "house": Vector2(320, 264), "oak": Vector2(208, 216), "small_tree": Vector2(128, 152),
    "well": Vector2(116, 118), "bush": Vector2(96, 76), "boulder": Vector2(84, 66),
    "barrel": Vector2(46, 54), "wine_barrel": Vector2(52, 60), "table": Vector2(168, 118),
    "shelf": Vector2(104, 72), "lamp": Vector2(64, 84), "sack": Vector2(48, 50),
}

var _fail := false

func _ready() -> void:
    _paint_village()
    _paint_fields()
    _paint_cellar()
    print("[PAINT] ====== HOAN TAT, fail=", _fail)
    get_tree().quit(1 if _fail else 0)

# ---------------- helpers ----------------

func _fdiv(a: float) -> int:
    return int(floor(a))

func _cell_of(tm: TileMap, world: Vector2) -> Vector2i:
    return Vector2i(_fdiv((world.x - tm.position.x) / TILE), _fdiv((world.y - tm.position.y) / TILE))

func _cells_of_rect(tm: TileMap, r: Rect2) -> Array:
    var c0 := _cell_of(tm, r.position)
    var c1 := _cell_of(tm, r.end - Vector2(0.01, 0.01))
    var out := []
    for cx in range(c0.x, c1.x + 1):
        for cy in range(c0.y, c1.y + 1):
            out.append(Vector2i(cx, cy))
    return out

func _paint_cell(tm: TileMap, atlas: Dictionary, stats: Dictionary, tile: String, cell: Vector2i) -> void:
    tm.set_cell(0, cell, 0, atlas[tile])
    stats[tile] = int(stats.get(tile, 0)) + 1

func _paint_rect(tm: TileMap, atlas: Dictionary, stats: Dictionary, tile: String, r: Rect2) -> void:
    for c in _cells_of_rect(tm, r):
        _paint_cell(tm, atlas, stats, tile, c)

func _global_point(root: Node, n: Node, p: Vector2) -> Vector2:
    var cur: Node = n
    while cur != null:
        if cur is Node2D:
            p = (cur as Node2D).transform * p
        if cur == root:
            break
        cur = cur.get_parent()
    return p

func _poly_global_bbox(root: Node, n: Polygon2D) -> Rect2:
    var pts := n.polygon
    if pts.size() == 0:
        return Rect2()
    var g0 := _global_point(root, n, pts[0])
    var r := Rect2(g0, Vector2.ZERO)
    for i in range(1, pts.size()):
        r = r.expand(_global_point(root, n, pts[i]))
    return r

func _container_local_bbox(cont: Node) -> Rect2:
    var r := Rect2()
    var first := true
    for ch in cont.get_children():
        if ch is Polygon2D:
            var poly := (ch as Polygon2D).polygon
            for p in poly:
                var lp: Vector2 = (ch as Node2D).transform * p
                if first:
                    r = Rect2(lp, Vector2.ZERO)
                    first = false
                else:
                    r = r.expand(lp)
    return r

func _collect_paths(root: Node) -> Dictionary:
    var out := {}
    var stack: Array = [root]
    while not stack.is_empty():
        var n: Node = stack.pop_back()
        out[str(root.get_path_to(n))] = n.get_class()
        for ch in n.get_children():
            stack.append(ch)
    return out

func _count_type(root: Node, cls: String) -> int:
    var c := 0
    var stack: Array = [root]
    while not stack.is_empty():
        var n: Node = stack.pop_back()
        if n.is_class(cls):
            c += 1
        for ch in n.get_children():
            stack.append(ch)
    return c

func _remove_node(root: Node, n: Node, removed: Array) -> void:
    removed.append(str(root.get_path_to(n)))
    var parent := n.get_parent()
    if parent != null:
        parent.remove_child(n)
    n.free()

func _strip_polygons(root: Node, cont: Node, removed: Array) -> void:
    var targets := []
    for ch in cont.get_children():
        if ch is Polygon2D:
            targets.append(ch)
    for t in targets:
        _remove_node(root, t, removed)

func _make_tilemap(root: Node, tname: String, tileset_path: String, origin: Vector2) -> TileMap:
    var tm := TileMap.new()
    tm.name = tname
    tm.tile_set = load(tileset_path)
    tm.position = origin
    tm.z_index = -10
    root.add_child(tm)
    tm.owner = root
    return tm

func _add_prop(parent: Node, root: Node, node_name: String, tex: String, pos: Vector2, scl: Vector2, stats: Dictionary, rot_deg: float = 0.0) -> Sprite2D:
    var sp := Sprite2D.new()
    sp.name = node_name
    sp.texture = load("res://assets/props/" + tex + ".png")
    sp.position = pos
    sp.scale = scl
    sp.rotation_degrees = rot_deg
    parent.add_child(sp)
    sp.owner = root
    stats[tex] = int(stats.get(tex, 0)) + 1
    return sp

## Dat prop theo bbox cu: can giua x theo tam bbox, day prop trung day bbox.
func _prop_fit(parent: Node, root: Node, node_name: String, tex: String, bbox: Rect2, width_scale: float, stats: Dictionary, flip: bool = false) -> void:
    var size: Vector2 = PROP_SIZE[tex]
    var s: float = bbox.size.x / size.x * width_scale
    var pos := Vector2(bbox.get_center().x, bbox.end.y - size.y * s * 0.5)
    var scl := Vector2(-s if flip else s, s)
    _add_prop(parent, root, node_name, tex, pos, scl, stats)

func _verify(root: Node, before: Dictionary, removed: Array, label: String) -> void:
    var missing := []
    for p in before.keys():
        if removed.has(p):
            continue
        if not root.has_node(NodePath(p)):
            # duong dan "." cua root: has_node(".") khong dung, bo qua
            if p == ".":
                continue
            missing.append(p)
    print("[PAINT] ", label, " verify: node truoc=", before.size(), " da xoa trang tri=", removed.size(), " thieu sau paint=", missing.size(), " ", missing)
    if not missing.is_empty():
        _fail = true

func _save_scene(root: Node, path: String, label: String) -> void:
    var packed := PackedScene.new()
    var err := packed.pack(root)
    if err != OK:
        print("[PAINT] ", label, " PACK LOI: ", err)
        _fail = true
        return
    err = ResourceSaver.save(packed, path)
    print("[PAINT] ", label, " save err=", err, " -> ", path)
    if err != OK:
        _fail = true

func _load_map(path: String) -> Node:
    var ps: PackedScene = load(path)
    if ps == null:
        print("[PAINT] KHONG LOAD DUOC: ", path)
        _fail = true
        return null
    return ps.instantiate()

func _report(label: String, tstats: Dictionary, pstats: Dictionary, removed_count: int) -> void:
    print("[PAINT] ", label, " TILE STATS: ", tstats)
    print("[PAINT] ", label, " PROP STATS: ", pstats)
    print("[PAINT] ", label, " REMOVED DECOR COUNT: ", removed_count)

# ---------------- LANG TAN DIEP ----------------

func _paint_village() -> void:
    var path := "res://maps/lang_tan_diep.tscn"
    var root := _load_map(path)
    if root == null:
        return
    var before := _collect_paths(root)
    var bodies0 := _count_type(root, "StaticBody2D")
    var cols0 := _count_type(root, "CollisionShape2D")
    var removed: Array = []
    var tstats := {}
    var pstats := {}

    # --- doc bbox cac vung dat truoc khi xoa ---
    var field_rects: Array = []
    for nname in ["FieldRice", "FieldWheat"]:
        field_rects.append(_poly_global_bbox(root, root.get_node(nname) as Polygon2D))
    var road_ns := _poly_global_bbox(root, root.get_node("RoadNS") as Polygon2D)
    var road_ew := _poly_global_bbox(root, root.get_node("RoadEW") as Polygon2D)
    var plaza := _poly_global_bbox(root, root.get_node("Plaza") as Polygon2D)
    var fence_data: Array = []
    for i in range(5):
        var f := root.get_node("Fence" + str(i))
        var fb := _container_local_bbox(f)
        fence_data.append(Rect2((f as Node2D).position + fb.position, fb.size))

    # --- xoa polygon nen duong ruong o root ---
    var root_decor := ["GrassBase", "VillageGround", "FieldRice", "FieldWheat", "RoadNS", "RoadEW", "Plaza",
        "RiceLine0", "RiceLine1", "RiceLine2", "RiceLine3", "WheatLine0", "WheatLine1", "WheatLine2"]
    for nname in root_decor:
        if root.has_node(nname):
            _remove_node(root, root.get_node(nname), removed)

    # --- TileMap nen ---
    var tm := _make_tilemap(root, "GroundTiles", "res://assets/tilesets/exterior_v1.tres", Vector2(-960, -704))
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261023
    var ground := Rect2(-900, -700, 1800, 1400)
    for c in _cells_of_rect(tm, ground):
        var roll := rng.randf()
        var t := "grass"
        if roll < 0.05:
            t = "grass_flower"
        elif roll < 0.09:
            t = "grass_tall"
        elif roll < 0.12:
            t = "grass_sparse"
        _paint_cell(tm, EXT, tstats, t, c)
    for r in field_rects:
        _paint_rect(tm, EXT, tstats, "field", r)
    # duong NS: 2 cot path_e/path_w
    var ns_cells := _cells_of_rect(tm, road_ns)
    var ns_cols := {}
    for c in ns_cells:
        ns_cols[c.x] = true
    var sorted_cols := ns_cols.keys()
    sorted_cols.sort()
    for c in ns_cells:
        _paint_cell(tm, EXT, tstats, "path_e" if c.x == sorted_cols[0] else "path_w", c)
    # duong EW: 2 hang path_s/path_n
    var ew_cells := _cells_of_rect(tm, road_ew)
    var ew_rows := {}
    for c in ew_cells:
        ew_rows[c.y] = true
    var sorted_rows := ew_rows.keys()
    sorted_rows.sort()
    for c in ew_cells:
        _paint_cell(tm, EXT, tstats, "path_s" if c.y == sorted_rows[0] else "path_n", c)
    # giao lo + quang truong: dat tron
    for c in ns_cells:
        if ew_rows.has(c.y):
            _paint_cell(tm, EXT, tstats, "dirt", c)
    _paint_rect(tm, EXT, tstats, "dirt", plaza)
    # hang rao: tile fence theo truc dai cua bbox cu
    for fr in fence_data:
        var r: Rect2 = fr
        if r.size.y > r.size.x:
            var col := _cell_of(tm, r.get_center()).x
            var rows := _cells_of_rect(tm, r)
            var seen := {}
            for c in rows:
                if not seen.has(c.y):
                    seen[c.y] = true
                    _paint_cell(tm, EXT, tstats, "fence_v", Vector2i(col, c.y))
        else:
            var row := _cell_of(tm, r.get_center()).y
            var cols := _cells_of_rect(tm, r)
            var seen2 := {}
            for c in cols:
                if not seen2.has(c.x):
                    seen2[c.x] = true
                    _paint_cell(tm, EXT, tstats, "fence_h", Vector2i(c.x, row))
    # xoa polygon trong cac fence (khong co collision ben trong)
    for i in range(5):
        _strip_polygons(root, root.get_node("Fence" + str(i)), removed)

    # --- prop: nha / gieng / cay / da ---
    var houses := ["ElderHouse", "House1", "House2", "House3", "House4", "House5", "House6"]
    for hname in houses:
        var h := root.get_node(hname)
        var bb := _container_local_bbox(h)
        _strip_polygons(root, h, removed)
        _prop_fit(h, root, "PropHouse", "house", bb, 1.15 if hname == "ElderHouse" else 1.0, pstats)
    var well := root.get_node("Well")
    var wbb := _container_local_bbox(well)
    _strip_polygons(root, well, removed)
    _prop_fit(well, root, "PropWell", "well", wbb, 1.0, pstats)
    for i in range(10):
        var tr := root.get_node("Tree" + str(i))
        var bb2 := _container_local_bbox(tr)
        _strip_polygons(root, tr, removed)
        if i % 2 == 0:
            _prop_fit(tr, root, "PropOak", "oak", bb2, 1.0, pstats)
        else:
            _prop_fit(tr, root, "PropSmallTree", "small_tree", bb2, 1.0, pstats)
    for i in range(1, 4):
        var rk := root.get_node("Rock" + str(i))
        var bb3 := _container_local_bbox(rk)
        _strip_polygons(root, rk, removed)
        _prop_fit(rk, root, "PropBoulder", "boulder", bb3, 1.0, pstats)
    # bui co trang tri them canh gieng / nha truong / nha 3 (khong collision)
    _add_prop(root, root, "PropBushA", "bush", Vector2(182, 168), Vector2(0.85, 0.85), pstats)
    _add_prop(root, root, "PropBushB", "bush", Vector2(-168, -78), Vector2(0.9, 0.9), pstats)
    _add_prop(root, root, "PropBushC", "bush", Vector2(398, 288), Vector2(0.8, 0.8), pstats)

    print("[PAINT] LangTanDiep collision truoc: bodies=", bodies0, " shapes=", cols0,
        " sau: bodies=", _count_type(root, "StaticBody2D"), " shapes=", _count_type(root, "CollisionShape2D"))
    _verify(root, before, removed, "LangTanDiep")
    _report("LangTanDiep", tstats, pstats, removed.size())
    _save_scene(root, path, "LangTanDiep")

# ---------------- DONG MACH NHA ----------------

func _paint_fields() -> void:
    var path := "res://maps/dong_mach_nha.tscn"
    var root := _load_map(path)
    if root == null:
        return
    var before := _collect_paths(root)
    var bodies0 := _count_type(root, "StaticBody2D")
    var cols0 := _count_type(root, "CollisionShape2D")
    var removed: Array = []
    var tstats := {}
    var pstats := {}

    var field_rects: Array = []
    for nname in ["FieldA", "FieldB", "FieldC", "FieldD"]:
        field_rects.append(_poly_global_bbox(root, root.get_node(nname) as Polygon2D))
    var road_ns := _poly_global_bbox(root, root.get_node("RoadNS") as Polygon2D)
    var road_ew := _poly_global_bbox(root, root.get_node("RoadEW") as Polygon2D)
    var road_vil := _poly_global_bbox(root, root.get_node("RoadVillage") as Polygon2D)
    var canal := _poly_global_bbox(root, root.get_node("Canal") as Polygon2D)
    var bridge_pos: Vector2 = (root.get_node("Bridge") as Node2D).position

    # xoa toan bo polygon trang tri o root (Grass/Field*/Road*/Canal*)
    var root_targets := []
    for ch in root.get_children():
        if ch is Polygon2D:
            root_targets.append(ch)
    for t in root_targets:
        _remove_node(root, t, removed)
    _strip_polygons(root, root.get_node("Bridge"), removed)

    var tm := _make_tilemap(root, "GroundTiles", "res://assets/tilesets/exterior_v1.tres", Vector2(-1024, -704))
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261024
    var ground := Rect2(-1000, -700, 2000, 1400)
    for c in _cells_of_rect(tm, ground):
        var roll := rng.randf()
        var t := "grass"
        if roll < 0.05:
            t = "grass_flower"
        elif roll < 0.09:
            t = "grass_tall"
        elif roll < 0.12:
            t = "grass_sparse"
        _paint_cell(tm, EXT, tstats, t, c)
    for r in field_rects:
        _paint_rect(tm, EXT, tstats, "field", r)
    # duong NS
    var ns_cells := _cells_of_rect(tm, road_ns)
    var ns_cols := {}
    for c in ns_cells:
        ns_cols[c.x] = true
    var scol := ns_cols.keys()
    scol.sort()
    for c in ns_cells:
        _paint_cell(tm, EXT, tstats, "path_e" if c.x == scol[0] else "path_w", c)
    # duong EW (chi doan tay theo bbox cu)
    var ew_cells := _cells_of_rect(tm, road_ew)
    var ew_rows := {}
    for c in ew_cells:
        ew_rows[c.y] = true
    var srow := ew_rows.keys()
    srow.sort()
    for c in ew_cells:
        _paint_cell(tm, EXT, tstats, "path_s" if c.y == srow[0] else "path_n", c)
    for c in ns_cells:
        if ew_rows.has(c.y):
            _paint_cell(tm, EXT, tstats, "dirt", c)
    # duong vao lang Mach Nha: dat tron
    _paint_rect(tm, EXT, tstats, "dirt", road_vil)
    # kenh nuoc: 1 hang tile nuoc tai hang chua tam kenh, xen water_a/b
    var canal_row := _cell_of(tm, canal.get_center()).y
    var canal_c0 := _cell_of(tm, Vector2(canal.position.x, canal.get_center().y)).x
    var canal_c1 := _cell_of(tm, Vector2(canal.end.x - 0.01, canal.get_center().y)).x
    for cx in range(canal_c0, canal_c1 + 1):
        _paint_cell(tm, EXT, tstats, "water_a" if cx % 2 == 0 else "water_b", Vector2i(cx, canal_row))
    # cau: nen dat + mat cau go (TileMap rieng dung tileset noi that - van go)
    var bridge_col0 := _cell_of(tm, bridge_pos + Vector2(-60, 0)).x
    var bridge_col1 := _cell_of(tm, bridge_pos + Vector2(59, 0)).x
    for cx in range(bridge_col0, bridge_col1 + 1):
        _paint_cell(tm, EXT, tstats, "dirt", Vector2i(cx, canal_row))
    var btm := _make_tilemap(root, "BridgeTiles", "res://assets/tilesets/interior_tavern_v1.tres", Vector2(-1024, -704))
    btm.z_index = -9
    var bstats := {}
    for cx in range(bridge_col0, bridge_col1 + 1):
        _paint_cell(btm, INT, bstats, "floor_a" if cx % 2 == 0 else "floor_b", Vector2i(cx, canal_row))
    print("[PAINT] DongMachNha BRIDGE TILE STATS: ", bstats)

    # nha lang Mach Nha + kho thoc
    var mh := ["MachHouse1", "MachHouse2", "MachHouse3"]
    for idx in range(mh.size()):
        var h := root.get_node(mh[idx])
        var bb := _container_local_bbox(h)
        _strip_polygons(root, h, removed)
        _prop_fit(h, root, "PropHouse", "house", bb, 1.0, pstats, idx == 1)
    var gr := root.get_node("Granary")
    var gbb := _container_local_bbox(gr)
    _strip_polygons(root, gr, removed)
    _prop_fit(gr, root, "PropGranary", "house", gbb, 0.85, pstats)
    _add_prop(gr, root, "PropSack", "sack", Vector2(gbb.end.x + 24, gbb.end.y - 25), Vector2.ONE, pstats)
    _add_prop(gr, root, "PropBarrel", "barrel", Vector2(gbb.end.x + 52, gbb.end.y - 27), Vector2.ONE, pstats)
    # cay thua
    for i in range(6):
        var tr := root.get_node("Tree" + str(i))
        var bb2 := _container_local_bbox(tr)
        _strip_polygons(root, tr, removed)
        if i % 2 == 0:
            _prop_fit(tr, root, "PropOak", "oak", bb2, 1.0, pstats)
        else:
            _prop_fit(tr, root, "PropSmallTree", "small_tree", bb2, 1.0, pstats)
    # bui co canh cay (khong collision)
    _add_prop(root, root, "PropBushA", "bush", Vector2(178, 578), Vector2(0.85, 0.85), pstats)
    _add_prop(root, root, "PropBushB", "bush", Vector2(-938, 572), Vector2(0.9, 0.9), pstats)
    _add_prop(root, root, "PropBushC", "bush", Vector2(-82, -602), Vector2(0.8, 0.8), pstats)

    print("[PAINT] DongMachNha collision truoc: bodies=", bodies0, " shapes=", cols0,
        " sau: bodies=", _count_type(root, "StaticBody2D"), " shapes=", _count_type(root, "CollisionShape2D"))
    _verify(root, before, removed, "DongMachNha")
    _report("DongMachNha", tstats, pstats, removed.size())
    _save_scene(root, path, "DongMachNha")

# ---------------- HAM RUOU ----------------

func _paint_cellar() -> void:
    var path := "res://maps/ham_ruou.tscn"
    var root := _load_map(path)
    if root == null:
        return
    var before := _collect_paths(root)
    var bodies0 := _count_type(root, "StaticBody2D")
    var cols0 := _count_type(root, "CollisionShape2D")
    var removed: Array = []
    var tstats := {}
    var pstats := {}

    var boss_rect := _poly_global_bbox(root, root.get_node("BossFloor") as Polygon2D)
    var carpet_rect := _poly_global_bbox(root, root.get_node("Carpet") as Polygon2D)
    var part_l := _poly_global_bbox(root, root.get_node("PartitionL/WallPoly") as Polygon2D)
    var part_r := _poly_global_bbox(root, root.get_node("PartitionR/WallPoly") as Polygon2D)

    # xoa polygon san/tuong o root
    var root_targets := []
    for ch in root.get_children():
        if ch is Polygon2D:
            root_targets.append(ch)
    for t in root_targets:
        _remove_node(root, t, removed)
    # vach ngan: xoa hinh, giu Body collision; tuong duoc paint bang tile o duoi
    _strip_polygons(root, root.get_node("PartitionL"), removed)
    _strip_polygons(root, root.get_node("PartitionR"), removed)

    var tm := _make_tilemap(root, "GroundTiles", "res://assets/tilesets/interior_tavern_v1.tres", Vector2(-704, -512))
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261025
    var all := Rect2(-704, -512, 1408, 1024)
    var all_cells := _cells_of_rect(tm, all)
    for c in all_cells:
        var roll := rng.randf()
        var t := "floor_a"
        if roll < 0.10:
            t = "floor_b"
        elif roll < 0.20:
            t = "floor_c"
        _paint_cell(tm, INT, tstats, t, c)
    # phong boss: san da
    var boss_cells := _cells_of_rect(tm, boss_rect)
    var boss_rows := {}
    var boss_cols := {}
    for c in boss_cells:
        boss_rows[c.y] = true
        boss_cols[c.x] = true
    var brow := boss_rows.keys()
    brow.sort()
    var bcol := boss_cols.keys()
    bcol.sort()
    # chi paint hang/cot ben trong (tru hang tuong bao + hang vach ngan)
    for c in boss_cells:
        if c.y > brow[0] and c.y < brow[brow.size() - 1] and c.x > bcol[0] and c.x < bcol[bcol.size() - 1]:
            _paint_cell(tm, INT, tstats, "stone_floor", c)
    # tuong bao: hang tren/duoi = wall_plank, cot trai/phai = wall_stone
    var min_c := Vector2i(999, 999)
    var max_c := Vector2i(-999, -999)
    for c in all_cells:
        min_c.x = mini(min_c.x, c.x)
        min_c.y = mini(min_c.y, c.y)
        max_c.x = maxi(max_c.x, c.x)
        max_c.y = maxi(max_c.y, c.y)
    for cx in range(min_c.x, max_c.x + 1):
        _paint_cell(tm, INT, tstats, "wall_stone" if cx == min_c.x or cx == max_c.x else "wall_plank", Vector2i(cx, min_c.y))
        _paint_cell(tm, INT, tstats, "wall_stone" if cx == min_c.x or cx == max_c.x else "wall_plank", Vector2i(cx, max_c.y))
    for cy in range(min_c.y + 1, max_c.y):
        _paint_cell(tm, INT, tstats, "wall_stone", Vector2i(min_c.x, cy))
        _paint_cell(tm, INT, tstats, "wall_stone", Vector2i(max_c.x, cy))
    # vach ngan boss/cellar: wall_plank theo bbox WallPoly cu (tru cot tuong bao)
    for pr in [part_l, part_r]:
        var row := _cell_of(tm, pr.get_center()).y
        var c0 := _cell_of(tm, pr.position).x
        var c1 := _cell_of(tm, pr.end - Vector2(0.01, 0)).x
        for cx in range(c0, c1 + 1):
            if cx > min_c.x and cx < max_c.x:
                _paint_cell(tm, INT, tstats, "wall_plank", Vector2i(cx, row))
    # tham do doc loi di giua
    _paint_rect(tm, INT, tstats, "rug", carpet_rect)

    # thung ruou / thung vo / crate
    for i in range(1, 16):
        var b := root.get_node("Barrel" + str(i))
        _strip_polygons(root, b, removed)
        if i % 2 == 1:
            _add_prop(b, root, "PropWineBarrel", "wine_barrel", Vector2(0, -4), Vector2.ONE, pstats)
        else:
            _add_prop(b, root, "PropBarrel", "barrel", Vector2(0, -1), Vector2.ONE, pstats)
    var broken := root.get_node("BrokenBarrel")
    var bbb := _container_local_bbox(broken)
    _strip_polygons(root, broken, removed)
    _add_prop(broken, root, "PropBrokenBarrel", "wine_barrel", bbb.get_center(), Vector2.ONE, pstats, 90.0)
    for i in range(1, 5):
        var cr := root.get_node("Crate" + str(i))
        _strip_polygons(root, cr, removed)
        _add_prop(cr, root, "PropBarrel", "barrel", Vector2(0, -5), Vector2.ONE, pstats)
    # ban + ke + den (trang tri, khong collision)
    _add_prop(root, root, "PropTable", "table", Vector2(-400, 150), Vector2.ONE, pstats)
    _add_prop(root, root, "PropShelf", "shelf", Vector2(-600, -260), Vector2.ONE, pstats)
    _add_prop(root, root, "PropLampA", "lamp", Vector2(-300, -100), Vector2.ONE, pstats)
    _add_prop(root, root, "PropLampB", "lamp", Vector2(300, -100), Vector2.ONE, pstats)

    print("[PAINT] HamRuou collision truoc: bodies=", bodies0, " shapes=", cols0,
        " sau: bodies=", _count_type(root, "StaticBody2D"), " shapes=", _count_type(root, "CollisionShape2D"))
    _verify(root, before, removed, "HamRuou")
    _report("HamRuou", tstats, pstats, removed.size())
    _save_scene(root, path, "HamRuou")
