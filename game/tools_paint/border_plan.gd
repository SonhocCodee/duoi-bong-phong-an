extends Node2D
## TEAM VIEN MAP - Buoc 1: lap ke hoach dai prop CHAN o dia map cho cac map
## TileMap ngoai troi (hang cay rung / vach da / cay xuong rong / thong
## tuyet... tuy biome), ghi /tmp/border_plan.json. Buoc ghi vao .tscn do
## apply_border.py lam bang chen text (khong pack+save bang Godot).
##
## Nguyen tac:
## - Dai vien nam BEN TRONG khung map (bounds lay tu chinh
##   map_root.compute_map_bounds() cua scene), 2-3 hang so le nhau.
## - Va cham da co san (WorldCollision/Borders phu 100% chu vi) nen prop
##   vien CHI la hinh anh (y-sort), khong them collision.
## - Ne: portal + spawn (r=175, tao loi di ra cong), NPC + diem lich
##   trinh (r=110) + doan duong lich trinh (r=70), quai/herb/craft
##   (r=100), moi rect collision san co (grow 12), prop goc o root (r=50).
## - Chi dat len o nen hop biome (co/cat/tuyet/dam lay...) - khong dat
##   len nuoc/bo/duong mon/ruong/san da (qua _tile_cat nhu prop_density).
## Chay: godot --headless --path game res://tools_paint/border_plan.tscn

const OUT_PATH := "/tmp/border_plan.json"
const TILE := 64.0

# ---- Phan loai o (copy tu prop_density.gd de tool doc lap) ---------------
func _cat_exterior(a: Vector2i) -> String:
	match a:
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(6, 2):
			return "grass"
		Vector2i(4, 0):
			return "path"
		Vector2i(5, 0):
			return "field"
		Vector2i(6, 0), Vector2i(7, 0):
			return "water"
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1):
			return "path"
		Vector2i(6, 1), Vector2i(7, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2):
			return "shore"
		Vector2i(3, 2), Vector2i(4, 2):
			return "shore"
		Vector2i(5, 2):
			return "stone"
		Vector2i(7, 2):
			return "sand"
	return "none"

const SWAMP_ORDER := ["water_murky_a", "water_murky_b", "water_deep", "mud_wet", "mud_dry",
	"swamp_grass", "swamp_grass_reeds", "plank", "plank_mossy", "shore_s",
	"shore_n", "shore_w", "shore_e", "shore_corner_convex", "shore_corner_concave",
	"mud_shore_s", "mud_shore_n", "mud_path_s", "plank_edge_s", "swamp_grass"]
const DESERT_ORDER := ["sand", "sand_dune", "rocky_sand", "cracked", "water_a",
	"water_b", "shore_s", "shore_n", "shore_w", "shore_e",
	"shore_cvx", "shore_ccv", "dry_grass", "sandstone_floor", "sandstone_brick",
	"bone_sand", "path_s", "path_n", "scrub_sand", "sand_pad"]
const WINTER_ORDER := ["snow", "drift", "rocky_snow", "ice", "ice_shine",
	"deep_ice", "shore_s", "shore_n", "shore_w", "shore_e",
	"shore_cvx", "shore_ccv", "frost_grass", "stone_floor", "dark_brick",
	"ash_snow", "path_s", "path_n", "dead_scrub", "packed_snow"]

func _cat_by_name(n: String, kind: String) -> String:
	if kind == "swamp":
		if n.begins_with("water"):
			return "water"
		if n == "mud_wet" or n == "mud_dry":
			return "mud"
		if n.begins_with("swamp_grass"):
			return "swamp"
		if n.begins_with("plank"):
			return "plank"
		if n.begins_with("shore") or n.begins_with("mud_shore"):
			return "shore"
		if n == "mud_path_s":
			return "path"
	elif kind == "desert":
		if n.begins_with("water"):
			return "water"
		if n.begins_with("shore"):
			return "shore"
		if n == "sandstone_floor":
			return "stone"
		if n == "sandstone_brick":
			return "floor"
		if n.begins_with("path"):
			return "path"
		return "sand"
	elif kind == "winter":
		if n.begins_with("ice") or n == "deep_ice":
			return "water"
		if n.begins_with("shore"):
			return "shore"
		if n == "stone_floor":
			return "stone"
		if n == "dark_brick":
			return "floor"
		if n.begins_with("path"):
			return "path"
		return "snow"
	return "none"

func _cat_order(a: Vector2i, order: Array, cols: int, kind: String) -> String:
	var idx := a.x + a.y * cols
	if idx < 0 or idx >= order.size():
		return "none"
	return _cat_by_name(str(order[idx]), kind)

func _cat_interior(a: Vector2i) -> String:
	if a == Vector2i(1, 1):
		return "stone"
	return "floor"

func _tile_cat(tm: TileMap, cell: Vector2i) -> String:
	if tm.tile_set == null:
		return "none"
	if tm.get_cell_source_id(0, cell) == -1:
		return "none"
	var a := tm.get_cell_atlas_coords(0, cell)
	var p := tm.tile_set.resource_path.get_file()
	match p:
		"exterior_v1.tres":
			return _cat_exterior(a)
		"swamp_v1.tres":
			return _cat_order(a, SWAMP_ORDER, 5, "swamp")
		"desert_v1.tres":
			return _cat_order(a, DESERT_ORDER, 5, "desert")
		"winter_v1.tres":
			return _cat_order(a, WINTER_ORDER, 5, "winter")
		"interior_tavern_v1.tres":
			return _cat_interior(a)
	return "none"

# ---- Cau hinh biome -------------------------------------------------------
# palette: [texture, trong so, scale min, scale max]
func _forest() -> Dictionary:
	return {"palette": [["oak", 55, 0.85, 1.10], ["small_tree", 35, 1.00, 1.25], ["bush", 10, 0.90, 1.20]],
		"rows": [56.0, 128.0], "spacing": 56.0, "grounds": ["grass"]}

func _swamp() -> Dictionary:
	return {"palette": [["mangrove", 55, 0.85, 1.10], ["reed_clump", 35, 0.95, 1.25], ["glowshroom", 10, 0.90, 1.20]],
		"rows": [56.0, 128.0], "spacing": 56.0, "grounds": ["swamp", "mud"]}

func _desert(with_palm: bool) -> Dictionary:
	var pal := [["cactus", 45, 0.85, 1.10], ["boulder", 35, 1.15, 1.55], ["bone_rib", 8, 0.60, 0.85]]
	if with_palm:
		pal = [["palm_tree", 20, 0.85, 1.05], ["cactus", 35, 0.85, 1.10], ["boulder", 35, 1.15, 1.55], ["bone_rib", 10, 0.60, 0.85]]
	return {"palette": pal, "rows": [46.0, 100.0, 152.0], "spacing": 52.0, "grounds": ["sand"]}

func _canyon() -> Dictionary:
	return {"palette": [["boulder", 60, 1.15, 1.60], ["cactus", 30, 0.85, 1.10], ["bone_rib", 10, 0.60, 0.85]],
		"rows": [46.0, 100.0, 152.0], "spacing": 52.0, "grounds": ["sand"]}

func _winter() -> Dictionary:
	return {"palette": [["snow_pine", 65, 0.85, 1.10], ["ice_rock", 35, 0.90, 1.25]],
		"rows": [56.0, 128.0], "spacing": 56.0, "grounds": ["snow"]}

func _ashen() -> Dictionary:
	# dat_chet dung winter_v1 voi tile ash_snow -> _tile_cat tra "snow".
	return {"palette": [["trunk_big", 45, 0.55, 0.75], ["boulder", 35, 1.15, 1.50], ["bone_rib", 20, 0.60, 0.85]],
		"rows": [52.0, 122.0], "spacing": 60.0, "grounds": ["snow"]}

func _maps() -> Array:
	var f := _forest()
	var s := _swamp()
	var dw := _desert(false)
	var dp := _desert(true)
	var c := _canyon()
	var w := _winter()
	var a := _ashen()
	return [
		["res://maps/lang_tan_diep.tscn", f], ["res://maps/dong_mach_nha.tscn", f],
		["res://maps/reedmere.tscn", s], ["res://maps/miregate.tscn", s],
		["res://maps/fevercamp.tscn", s], ["res://maps/fenmire_approach.tscn", s],
		["res://maps/blackmere.tscn", s], ["res://maps/drownedwood.tscn", s],
		["res://maps/venomfen.tscn", s],
		["res://maps/dunefield.tscn", dw], ["res://maps/westgate.tscn", dw],
		["res://maps/dunehawk_camp.tscn", dw], ["res://maps/stonesong_camp.tscn", dw],
		["res://maps/sunwell_oasis.tscn", dp],
		["res://maps/redrock_canyon.tscn", c],
		["res://maps/frostgard_approach.tscn", w], ["res://maps/frozen_lake.tscn", w],
		["res://maps/snowpine_forest.tscn", w], ["res://maps/hearthwick.tscn", w],
		["res://maps/northgate.tscn", w], ["res://maps/ghostwatch_post.tscn", w],
		["res://maps/howling_pass.tscn", w],
		["res://maps/dat_chet.tscn", a],
	]

# ---- Thu thap chuong ngai (theo mau prop_density) -------------------------
var _solid_rects: Array[Rect2] = []
var _hard_pts: Array = []
var _npc_pts: Array = []
var _segments: Array = []
var _prop_pts: Array[Vector2] = []
var _tilemaps: Array[TileMap] = []
var _ground_tm: TileMap = null

const PORTAL_SCRIPT := "res://systems/portal.gd"

func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := 0.0
	if ab.length() > 0.01:
		t = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _collect(node: Node, root: Node) -> void:
	if node != root and (node.name == "DensityProps" or node.name == "MapBorder"):
		return
	if node is TileMap:
		_tilemaps.append(node)
		if node.name == "GroundTiles":
			_ground_tm = node
	if node is CollisionShape2D and node.shape != null:
		var cs := node as CollisionShape2D
		var ctr := cs.global_position
		var sz := Vector2.ZERO
		if cs.shape is RectangleShape2D:
			sz = (cs.shape as RectangleShape2D).size
		elif cs.shape is CircleShape2D:
			var r := (cs.shape as CircleShape2D).radius
			sz = Vector2(r * 2.0, r * 2.0)
		elif cs.shape is CapsuleShape2D:
			var cap := cs.shape as CapsuleShape2D
			sz = Vector2(cap.radius * 2.0, cap.height)
		if sz != Vector2.ZERO:
			_solid_rects.append(Rect2(ctr - sz * 0.5, sz))
	if node is Node2D and node != root:
		var n2 := node as Node2D
		var nm := node.name
		var sc: Script = node.get_script() as Script
		if nm.begins_with("Spawn_") or nm.begins_with("Portal"):
			_hard_pts.append([n2.global_position, 175.0])
		elif sc != null and sc.resource_path == PORTAL_SCRIPT:
			_hard_pts.append([n2.global_position, 175.0])
		elif node.get("npc_id") != null and str(node.get("npc_id")) != "":
			_npc_pts.append([n2.global_position, 110.0])
			var sched: Array = node.get("schedule") if node.get("schedule") != null else []
			var prev := n2.global_position
			var pts: Array[Vector2] = [prev]
			for s in sched:
				if s is Dictionary:
					var sp := Vector2(float(s.get("x", prev.x)), float(s.get("y", prev.y)))
					pts.append(sp)
					_npc_pts.append([sp, 90.0])
			if bool(node.get("schedule_enabled")) and pts.size() > 1:
				for i in pts.size():
					_segments.append([pts[i], pts[(i + 1) % pts.size()]])
		elif node.scene_file_path.begins_with("res://enemies/") or node.get("enemy_type") != null:
			_npc_pts.append([n2.global_position, 100.0])
		elif node.scene_file_path.find("herb_pickup") >= 0 or node.scene_file_path.find("craft_station") >= 0 or node.scene_file_path.find("chest") >= 0:
			_npc_pts.append([n2.global_position, 100.0])
		elif node.get_parent() == root and node is CharacterBody2D:
			_npc_pts.append([n2.global_position, 100.0])
		elif node.get_parent() == root and not (node is TileMap) and not (node is Label) \
				and not (node is Polygon2D) and not (node is ColorRect) and not (node is Camera2D):
			if n2.global_position != Vector2.ZERO:
				_prop_pts.append(n2.global_position)
	for ch in node.get_children():
		_collect(ch, root)

func _ground_cat(p: Vector2) -> String:
	var base := "none"
	for tm in _tilemaps:
		var cell := tm.local_to_map(tm.to_local(p))
		var cat := _tile_cat(tm, cell)
		if cat == "none":
			continue
		if tm == _ground_tm:
			base = cat
			continue
		if cat in ["water", "shore", "field", "floor"]:
			return cat
		if cat == "path":
			return "path"
		if cat == "stone":
			base = "stone"
	return base

func _clear_for(p: Vector2) -> bool:
	for r in _solid_rects:
		if r.grow(12.0).has_point(p):
			return false
	for hp in _hard_pts:
		if p.distance_to(hp[0]) < float(hp[1]):
			return false
	for np_ in _npc_pts:
		if p.distance_to(np_[0]) < float(np_[1]):
			return false
	for s in _segments:
		if _seg_dist(p, s[0], s[1]) < 70.0:
			return false
	for pp in _prop_pts:
		if p.distance_to(pp) < 50.0:
			return false
	return true

func _pick_weighted(pool: Array, rng: RandomNumberGenerator) -> Array:
	var total := 0.0
	for e in pool:
		total += float(e[1])
	var roll := rng.randf() * total
	for e in pool:
		roll -= float(e[1])
		if roll <= 0.0:
			return e
	return pool[pool.size() - 1]

var _plan := {}
var _tex_size := {}

func _tex_h(tex_name: String) -> float:
	if not _tex_size.has(tex_name):
		var t: Texture2D = load("res://assets/props/" + tex_name + ".png")
		_tex_size[tex_name] = float(t.get_size().y) if t != null else 128.0
	return float(_tex_size[tex_name])

func _process_map(path: String, cfg: Dictionary, seed_val: int) -> void:
	_solid_rects.clear()
	_hard_pts.clear()
	_npc_pts.clear()
	_segments.clear()
	_prop_pts.clear()
	_tilemaps.clear()
	_ground_tm = null
	var ps: PackedScene = load(path)
	if ps == null:
		print("[BORDER] LOAD FAIL ", path)
		return
	var m: Node = ps.instantiate()
	add_child(m)
	await get_tree().process_frame
	await get_tree().process_frame
	_collect(m, m)
	var bounds: Rect2 = m.compute_map_bounds()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var spacing := float(cfg["spacing"])
	var rows: Array = cfg["rows"]
	var grounds: Array = cfg["grounds"]
	var props: Array = []
	var grid := {}
	var cats := {}
	var seq := 0
	# 4 canh: [diem bat dau, huong doc canh, huong vao trong]
	var edges := [
		[bounds.position, Vector2(1, 0), Vector2(0, 1), bounds.size.x],
		[Vector2(bounds.position.x, bounds.end.y), Vector2(1, 0), Vector2(0, -1), bounds.size.x],
		[bounds.position, Vector2(0, 1), Vector2(1, 0), bounds.size.y],
		[Vector2(bounds.end.x, bounds.position.y), Vector2(0, 1), Vector2(-1, 0), bounds.size.y],
	]
	for e in edges:
		var origin: Vector2 = e[0]
		var along: Vector2 = e[1]
		var inward: Vector2 = e[2]
		var length := float(e[3])
		for depth in rows:
			var t := 24.0 + rng.randf() * spacing * 0.5
			while t < length - 24.0:
				var p: Vector2 = origin + along * t + inward * (float(depth) + rng.randf_range(-9.0, 9.0))
				p += along * rng.randf_range(-spacing * 0.22, spacing * 0.22)
				t += spacing * rng.randf_range(0.88, 1.12)
				var cat := _ground_cat(p)
				cats[cat] = int(cats.get(cat, 0)) + 1
				if not grounds.has(cat):
					continue
				if not _clear_for(p):
					continue
				# Chong trung nhau (luoi 48px)
				var gx := int(floor(p.x / 48.0))
				var gy := int(floor(p.y / 48.0))
				var clash := false
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var key := "%d:%d" % [gx + dx, gy + dy]
						if grid.has(key):
							for q in grid[key]:
								if p.distance_to(q) < 36.0:
									clash = true
									break
						if clash:
							break
					if clash:
						break
				if clash:
					continue
				var key2 := "%d:%d" % [gx, gy]
				if not grid.has(key2):
					grid[key2] = []
				grid[key2].append(p)
				var pick := _pick_weighted(cfg["palette"], rng)
				var tex_name := str(pick[0])
				props.append({
					"tex": tex_name, "x": snapped(p.x, 1.0), "y": snapped(p.y, 1.0),
					"scl": snapped(rng.randf_range(float(pick[2]), float(pick[3])), 0.001),
					"flip": rng.randf() < 0.5, "h": _tex_h(tex_name), "seq": seq,
				})
				seq += 1
	_plan[path] = {"props": props}
	print("[BORDER] %s: props=%d cats=%s" % [path.get_file(), props.size(), str(cats)])
	remove_child(m)
	m.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	var seed_val := 31000
	for entry in _maps():
		seed_val += 137
		await _process_map(entry[0], entry[1], seed_val)
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_plan, "\t"))
		f.close()
		print("[BORDER] da ghi ", OUT_PATH)
	else:
		print("[BORDER] LOI ghi plan")
	print("[BORDER] ====== HOAN TAT")
	get_tree().quit()
