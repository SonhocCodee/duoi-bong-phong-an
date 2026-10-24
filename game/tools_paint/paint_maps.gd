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
    # CANH BAO (dot 6): paint_maps la tool CU — chay lai se STRIP cac
    # override chinh tay cua cac dot sau (schedule NPC, stat quai, sprite
    # frames rieng) khoi 3 map Dong. CraftStation cua Elmford da duoc dat
    # bang sua truc tiep file lang_tan_diep.tscn, KHONG qua tool nay.
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

# ---------------- helpers mo rong (idempotent: chay lai tren scene da paint van dung) ----------------

func _poly_rect(root: Node, nname: String, fallback: Rect2) -> Rect2:
    if root.has_node(nname) and root.get_node(nname) is Polygon2D:
        return _poly_global_bbox(root, root.get_node(nname) as Polygon2D)
    return fallback

func _remove_existing(root: Node, nname: String, removed: Array) -> void:
    if root.has_node(nname):
        _remove_node(root, root.get_node(nname), removed)

func _has_sprite(cont: Node) -> bool:
    for ch in cont.get_children():
        if ch is Sprite2D:
            return true
    return false

func _has_poly(cont: Node) -> bool:
    for ch in cont.get_children():
        if ch is Polygon2D:
            return true
    return false

## Container nha/cay/da: chi strip polygon + dat prop khi con polygon goc;
## da co sprite san (scene da paint / node moi) thi giu nguyen.
func _paint_container(root: Node, cont: Node, tex: String, prop_name: String, width_scale: float, removed: Array, pstats: Dictionary, flip: bool = false) -> void:
    if _has_poly(cont):
        var bb := _container_local_bbox(cont)
        _strip_polygons(root, cont, removed)
        if not _has_sprite(cont):
            _prop_fit(cont, root, prop_name, tex, bb, width_scale, pstats, flip)

# ---------------- LANG TAN DIEP (ELMFORD) ----------------
# Ground moi: Rect2(-1600,-3200,6400,4800) = 100x75 tile. Lang cu la hat nhan Tay-Nam/trung tam.

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

    var field_rects: Array = []
    for nname in ["FieldRice", "FieldWheat"]:
        if root.has_node(nname):
            field_rects.append(_poly_global_bbox(root, root.get_node(nname) as Polygon2D))
    if field_rects.is_empty():
        field_rects = [Rect2(1800, 700, 1000, 600), Rect2(-1200, 800, 1000, 600)]
    var road_ns := _poly_rect(root, "RoadNS", Rect2(-64, -3200, 128, 4800))
    var road_ew := _poly_rect(root, "RoadEW", Rect2(-1600, -64, 6400, 128))
    var road_branch := _poly_rect(root, "RoadBranch", Rect2(0, 736, 3000, 128))
    var plaza := _poly_rect(root, "Plaza", Rect2(-160, -140, 540, 460))
    var forest_rects: Array = []
    for nname in ["ForestEast", "ForestNorth"]:
        if root.has_node(nname):
            forest_rects.append(_poly_global_bbox(root, root.get_node(nname) as Polygon2D))
    if forest_rects.is_empty():
        forest_rects = [Rect2(2200, -2600, 2500, 2200), Rect2(-1400, -3000, 3200, 1200)]
    var fence_data: Array = []
    for ch in root.get_children():
        if ch.name.begins_with("Fence") and _has_poly(ch):
            var fb := _container_local_bbox(ch)
            fence_data.append(Rect2((ch as Node2D).position + fb.position, fb.size))

    var root_decor := ["GrassBase", "VillageGround", "FieldRice", "FieldWheat", "RoadNS", "RoadEW", "RoadBranch", "Plaza",
        "ForestEast", "ForestNorth",
        "RiceLine0", "RiceLine1", "RiceLine2", "RiceLine3", "WheatLine0", "WheatLine1", "WheatLine2"]
    for nname in root_decor:
        if root.has_node(nname):
            _remove_node(root, root.get_node(nname), removed)
    _remove_existing(root, "GroundTiles", removed)

    var tm := _make_tilemap(root, "GroundTiles", "res://assets/tilesets/exterior_v1.tres", Vector2(-1664, -3264))
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261023
    var ground := Rect2(-1600, -3200, 6400, 4800)
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
    # ven rung dong/bac: co dam
    for r in forest_rects:
        for c in _cells_of_rect(tm, r):
            var roll2 := rng.randf()
            _paint_cell(tm, EXT, tstats, "grass_tall" if roll2 < 0.25 else "grass_dark", c)
    for r in field_rects:
        _paint_rect(tm, EXT, tstats, "field", r)
    var ns_cells := _cells_of_rect(tm, road_ns)
    var ns_cols := {}
    for c in ns_cells:
        ns_cols[c.x] = true
    var sorted_cols := ns_cols.keys()
    sorted_cols.sort()
    for c in ns_cells:
        _paint_cell(tm, EXT, tstats, "path_e" if c.x == sorted_cols[0] else "path_w", c)
    var ew_cells := _cells_of_rect(tm, road_ew)
    var ew_rows := {}
    for c in ew_cells:
        ew_rows[c.y] = true
    var sorted_rows := ew_rows.keys()
    sorted_rows.sort()
    for c in ew_cells:
        _paint_cell(tm, EXT, tstats, "path_s" if c.y == sorted_rows[0] else "path_n", c)
    for c in ns_cells:
        if ew_rows.has(c.y):
            _paint_cell(tm, EXT, tstats, "dirt", c)
    _paint_rect(tm, EXT, tstats, "dirt", road_branch)
    _paint_rect(tm, EXT, tstats, "dirt", plaza)
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
    for ch in root.get_children():
        if ch.name.begins_with("Fence"):
            _strip_polygons(root, ch, removed)

    for ch in root.get_children():
        var nm := String(ch.name)
        if nm == "ElderHouse":
            _paint_container(root, ch, "house", "PropHouse", 1.15, removed, pstats)
        elif nm.begins_with("House"):
            _paint_container(root, ch, "house", "PropHouse", 1.0, removed, pstats)
        elif nm == "Well":
            _paint_container(root, ch, "well", "PropWell", 1.0, removed, pstats)
        elif nm.begins_with("Tree"):
            var idx := int(nm.trim_prefix("Tree"))
            if idx % 2 == 0:
                _paint_container(root, ch, "oak", "PropOak", 1.0, removed, pstats)
            else:
                _paint_container(root, ch, "small_tree", "PropSmallTree", 1.0, removed, pstats)
        elif nm.begins_with("Rock"):
            _paint_container(root, ch, "boulder", "PropBoulder", 1.0, removed, pstats)
    if not root.has_node("PropBushA"):
        _add_prop(root, root, "PropBushA", "bush", Vector2(182, 168), Vector2(0.85, 0.85), pstats)
    if not root.has_node("PropBushB"):
        _add_prop(root, root, "PropBushB", "bush", Vector2(-168, -78), Vector2(0.9, 0.9), pstats)
    if not root.has_node("PropBushC"):
        _add_prop(root, root, "PropBushC", "bush", Vector2(398, 288), Vector2(0.8, 0.8), pstats)

    print("[PAINT] LangTanDiep collision truoc: bodies=", bodies0, " shapes=", cols0,
        " sau: bodies=", _count_type(root, "StaticBody2D"), " shapes=", _count_type(root, "CollisionShape2D"))
    _verify(root, before, removed, "LangTanDiep")
    _report("LangTanDiep", tstats, pstats, removed.size())
    _save_scene(root, path, "LangTanDiep")

# ---------------- DONG MACH NHA (BARLEYFIELD) ----------------
# Ground moi: Rect2(-2800,-3264,9088,6528) = 142x102 tile.

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
    var trail_pts := PackedVector2Array()
    var forest_strip := Rect2()
    var has_strip := false
    for ch in root.get_children():
        if ch is Polygon2D:
            var nm := String(ch.name)
            if nm.begins_with("Field"):
                field_rects.append(_poly_global_bbox(root, ch as Polygon2D))
            elif nm == "TrailShortcut":
                trail_pts = (ch as Polygon2D).polygon
            elif nm == "ForestStrip":
                forest_strip = _poly_global_bbox(root, ch as Polygon2D)
                has_strip = true
    if field_rects.is_empty():
        field_rects = [Rect2(600, -1600, 2000, 1200), Rect2(-2400, -1800, 1800, 1200), Rect2(-2200, 700, 2400, 1200), Rect2(2800, 600, 2000, 1200), Rect2(3200, -2400, 2000, 1200)]
    if not has_strip:
        forest_strip = Rect2(1500, -3264, 800, 6528)
        has_strip = true
    if trail_pts.size() < 3:
        trail_pts = PackedVector2Array([Vector2(1500, 1200), Vector2(2300, 400), Vector2(2364, 464), Vector2(1564, 1264)])
    var road_ns := _poly_rect(root, "RoadNS", Rect2(-64, -3264, 128, 6528))
    var road_ew := _poly_rect(root, "RoadEW", Rect2(-2800, -64, 9088, 128))
    var road_vil := _poly_rect(root, "RoadVillage", Rect2(400, -640, 600, 480))
    var canal := _poly_rect(root, "Canal", Rect2(-2800, 149, 9088, 56))
    var bridge_pos: Vector2 = (root.get_node("Bridge") as Node2D).position

    var root_targets := []
    for ch in root.get_children():
        if ch is Polygon2D:
            root_targets.append(ch)
    for t in root_targets:
        _remove_node(root, t, removed)
    _strip_polygons(root, root.get_node("Bridge"), removed)
    _remove_existing(root, "GroundTiles", removed)
    _remove_existing(root, "BridgeTiles", removed)

    var tm := _make_tilemap(root, "GroundTiles", "res://assets/tilesets/exterior_v1.tres", Vector2(-2816, -3264))
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261024
    var ground := Rect2(-2800, -3264, 9088, 6528)
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
    if has_strip:
        for c in _cells_of_rect(tm, forest_strip):
            var roll3 := rng.randf()
            _paint_cell(tm, EXT, tstats, "grass_tall" if roll3 < 0.25 else "grass_dark", c)
    for r in field_rects:
        _paint_rect(tm, EXT, tstats, "field", r)
    var ns_cells := _cells_of_rect(tm, road_ns)
    var ns_cols := {}
    for c in ns_cells:
        ns_cols[c.x] = true
    var scol := ns_cols.keys()
    scol.sort()
    for c in ns_cells:
        _paint_cell(tm, EXT, tstats, "path_e" if c.x == scol[0] else "path_w", c)
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
    _paint_rect(tm, EXT, tstats, "dirt", road_vil)
    # loi tat xuyen dai cay: paint dirt cac o co tam nam trong polygon cheo
    if trail_pts.size() >= 3:
        var tb := Rect2(trail_pts[0], Vector2.ZERO)
        for p in trail_pts:
            tb = tb.expand(p)
        for c in _cells_of_rect(tm, tb):
            var center := tm.position + Vector2(c) * TILE + Vector2(TILE * 0.5, TILE * 0.5)
            if Geometry2D.is_point_in_polygon(center, trail_pts):
                _paint_cell(tm, EXT, tstats, "dirt", c)
    var canal_row := _cell_of(tm, canal.get_center()).y
    var canal_c0 := _cell_of(tm, Vector2(canal.position.x, canal.get_center().y)).x
    var canal_c1 := _cell_of(tm, Vector2(canal.end.x - 0.01, canal.get_center().y)).x
    for cx in range(canal_c0, canal_c1 + 1):
        _paint_cell(tm, EXT, tstats, "water_a" if cx % 2 == 0 else "water_b", Vector2i(cx, canal_row))
    var bridge_col0 := _cell_of(tm, bridge_pos + Vector2(-60, 0)).x
    var bridge_col1 := _cell_of(tm, bridge_pos + Vector2(59, 0)).x
    for cx in range(bridge_col0, bridge_col1 + 1):
        _paint_cell(tm, EXT, tstats, "dirt", Vector2i(cx, canal_row))
    var btm := _make_tilemap(root, "BridgeTiles", "res://assets/tilesets/interior_tavern_v1.tres", Vector2(-2816, -3264))
    btm.z_index = -9
    var bstats := {}
    for cx in range(bridge_col0, bridge_col1 + 1):
        _paint_cell(btm, INT, bstats, "floor_a" if cx % 2 == 0 else "floor_b", Vector2i(cx, canal_row))
    print("[PAINT] DongMachNha BRIDGE TILE STATS: ", bstats)

    for ch in root.get_children():
        var nm := String(ch.name)
        if nm.begins_with("MachHouse"):
            _paint_container(root, ch, "house", "PropHouse", 1.0, removed, pstats, nm == "MachHouse2")
        elif nm == "Granary":
            _paint_container(root, ch, "house", "PropGranary", 0.85, removed, pstats)
            if not ch.has_node("PropSack"):
                var gbb := Rect2(-75, -50, 150, 100)
                _add_prop(ch, root, "PropSack", "sack", Vector2(gbb.end.x + 24, gbb.end.y - 25), Vector2.ONE, pstats)
            if not ch.has_node("PropBarrel"):
                _add_prop(ch, root, "PropBarrel", "barrel", Vector2(139, 23), Vector2.ONE, pstats)
        elif nm.begins_with("Tree") or nm == "OldTree":
            _paint_container(root, ch, "oak" if nm == "OldTree" or int(nm.trim_prefix("Tree")) % 2 == 0 else "small_tree",
                "PropOak" if nm == "OldTree" or int(nm.trim_prefix("Tree")) % 2 == 0 else "PropSmallTree", 1.0, removed, pstats)
    if not root.has_node("PropBushA"):
        _add_prop(root, root, "PropBushA", "bush", Vector2(178, 578), Vector2(0.85, 0.85), pstats)
    if not root.has_node("PropBushB"):
        _add_prop(root, root, "PropBushB", "bush", Vector2(-938, 572), Vector2(0.9, 0.9), pstats)
    if not root.has_node("PropBushC"):
        _add_prop(root, root, "PropBushC", "bush", Vector2(-82, -602), Vector2(0.8, 0.8), pstats)

    print("[PAINT] DongMachNha collision truoc: bodies=", bodies0, " shapes=", cols0,
        " sau: bodies=", _count_type(root, "StaticBody2D"), " shapes=", _count_type(root, "CollisionShape2D"))
    _verify(root, before, removed, "DongMachNha")
    _report("DongMachNha", tstats, pstats, removed.size())
    _save_scene(root, path, "DongMachNha")

# ---------------- HAM RUOU (ELMFORD CELLAR) ----------------
# Dungeon 80x60 tile (-2560..2560, -1920..1920): 8 phong + hanh lang chu thap.
# San = cac polygon Floor*/Corr*; con lai la tuong (wall_stone) + Walls collision trong scene.

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

    var floor_rects: Array = []
    for ch in root.get_children():
        if ch is Polygon2D:
            var nm := String(ch.name)
            if nm.begins_with("Floor") or nm.begins_with("Corr"):
                floor_rects.append(_poly_global_bbox(root, ch as Polygon2D))
    if floor_rects.is_empty():
        floor_rects = [Rect2(-384, 1024, 768, 704), Rect2(-2176, 1024, 1600, 704), Rect2(576, 1024, 1600, 704),
            Rect2(-2176, -192, 1600, 768), Rect2(576, -192, 1600, 768),
            Rect2(-2176, -1408, 1600, 768), Rect2(576, -1408, 1600, 768), Rect2(-384, -1408, 768, 768),
            Rect2(-96, -1408, 192, 3136), Rect2(-1472, -1408, 128, 3136), Rect2(1344, -1408, 128, 3136),
            Rect2(-2176, 704, 4352, 320)]
    var boss_rect := _poly_rect(root, "BossFloor", Rect2(576, -1408, 1600, 768))
    var carpet_rect := _poly_rect(root, "Carpet", Rect2(-64, 200, 128, 800))
    var pool_rect := _poly_rect(root, "PoolWater", Rect2(1024, 0, 768, 384))

    var root_targets := []
    for ch in root.get_children():
        if ch is Polygon2D:
            root_targets.append(ch)
    for t in root_targets:
        _remove_node(root, t, removed)
    _remove_existing(root, "GroundTiles", removed)
    _remove_existing(root, "PoolTiles", removed)

    var tm := _make_tilemap(root, "GroundTiles", "res://assets/tilesets/interior_tavern_v1.tres", Vector2(-2560, -1920))
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261025
    var all := Rect2(-2560, -1920, 5120, 3840)
    var all_cells := _cells_of_rect(tm, all)
    for c in all_cells:
        _paint_cell(tm, INT, tstats, "wall_stone", c)
    for r in floor_rects:
        for c in _cells_of_rect(tm, r):
            var roll := rng.randf()
            var t := "floor_a"
            if roll < 0.10:
                t = "floor_b"
            elif roll < 0.20:
                t = "floor_c"
            _paint_cell(tm, INT, tstats, t, c)
    _paint_rect(tm, INT, tstats, "stone_floor", boss_rect)
    _paint_rect(tm, INT, tstats, "rug", carpet_rect)
    # ao nuoc ngam trong phong Pool: TileMap rieng dung tileset exterior (nuoc)
    var ptm := _make_tilemap(root, "PoolTiles", "res://assets/tilesets/exterior_v1.tres", Vector2(-2560, -1920))
    ptm.z_index = -9
    var pstats2 := {}
    for c in _cells_of_rect(ptm, pool_rect):
        _paint_cell(ptm, EXT, pstats2, "water_a" if (c.x + c.y) % 2 == 0 else "water_b", c)
    print("[PAINT] HamRuou POOL TILE STATS: ", pstats2)

    # thung/crate: chi dat prop khi container chua co sprite (scene da paint thi giu nguyen)
    for i in range(1, 16):
        var bname := "Barrel" + str(i)
        if root.has_node(bname):
            var b := root.get_node(bname)
            _strip_polygons(root, b, removed)
            if not _has_sprite(b):
                if i % 2 == 1:
                    _add_prop(b, root, "PropWineBarrel", "wine_barrel", Vector2(0, -4), Vector2.ONE, pstats)
                else:
                    _add_prop(b, root, "PropBarrel", "barrel", Vector2(0, -1), Vector2.ONE, pstats)
    if root.has_node("BrokenBarrel"):
        var broken := root.get_node("BrokenBarrel")
        _strip_polygons(root, broken, removed)
        if not _has_sprite(broken):
            _add_prop(broken, root, "PropBrokenBarrel", "wine_barrel", Vector2(1, 12), Vector2.ONE, pstats, 90.0)
    for i in range(1, 5):
        var crname := "Crate" + str(i)
        if root.has_node(crname):
            var cr := root.get_node(crname)
            _strip_polygons(root, cr, removed)
            if not _has_sprite(cr):
                _add_prop(cr, root, "PropBarrel", "barrel", Vector2(0, -5), Vector2.ONE, pstats)
    if not root.has_node("PropTable"):
        _add_prop(root, root, "PropTable", "table", Vector2(1200, 1500), Vector2.ONE, pstats)
    if not root.has_node("PropShelf"):
        _add_prop(root, root, "PropShelf", "shelf", Vector2(-250, -1350), Vector2.ONE, pstats)
    if not root.has_node("PropLampA"):
        _add_prop(root, root, "PropLampA", "lamp", Vector2(-300, 1100), Vector2.ONE, pstats)
    if not root.has_node("PropLampB"):
        _add_prop(root, root, "PropLampB", "lamp", Vector2(2000, -700), Vector2.ONE, pstats)

    print("[PAINT] HamRuou collision truoc: bodies=", bodies0, " shapes=", cols0,
        " sau: bodies=", _count_type(root, "StaticBody2D"), " shapes=", _count_type(root, "CollisionShape2D"))
    _verify(root, before, removed, "HamRuou")
    _report("HamRuou", tstats, pstats, removed.size())
    _save_scene(root, path, "HamRuou")
