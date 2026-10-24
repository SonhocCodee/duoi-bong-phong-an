extends Node2D
## Tool một lần (đợt 5): dựng 8 map VÙNG BẮC FROSTGARD theo
## design/frostgard_so_do.md (Northgate, Hearthwick, Snowpine Forest,
## Frozen Lake, Ghostwatch Post, Legion Crypt, Howling Pass,
## Frostgard Approach). Nội thành Frostgard KHÔNG dựng (chờ duyệt layout).
## Chạy: godot --headless --path game res://tools_paint/paint_frostgard.tscn

const TILE := 64.0
const T := {
	"snow": Vector2i(0, 0), "drift": Vector2i(1, 0), "rocky_snow": Vector2i(2, 0),
	"ice": Vector2i(3, 0), "ice_shine": Vector2i(4, 0), "deep_ice": Vector2i(0, 1),
	"shore_s": Vector2i(1, 1), "shore_n": Vector2i(2, 1), "shore_w": Vector2i(3, 1),
	"shore_e": Vector2i(4, 1), "shore_cvx": Vector2i(0, 2), "shore_ccv": Vector2i(1, 2),
	"frost_grass": Vector2i(2, 2), "stone_floor": Vector2i(3, 2), "dark_brick": Vector2i(4, 2),
	"ash_snow": Vector2i(0, 3), "path_s": Vector2i(1, 3), "path_n": Vector2i(2, 3),
	"dead_scrub": Vector2i(3, 3), "packed_snow": Vector2i(4, 3),
}
const STONE := {"wall": Vector2i(0, 1), "floor": Vector2i(1, 1), "floor_a": Vector2i(0, 0)}

var _rng := RandomNumberGenerator.new()
var _root: Node2D
var _tm: TileMap
var _tm2: TileMap
var _w := 0
var _h := 0
var _origin := Vector2.ZERO
var _solid := {}
var _water := {}
var _ice := {}
var _open := {}
var _fail := false


func _ready() -> void:
	_rng.seed = 241924
	_build_northgate()
	_build_hearthwick()
	_build_snowpine()
	_build_frozen_lake()
	_build_ghostwatch()
	_build_crypt()
	_build_howling_pass()
	_build_approach()
	print("[FROSTGARD] ====== HOAN TAT, fail=", _fail)
	get_tree().quit(1 if _fail else 0)


func _new_map(map_name: String, w: int, h: int) -> void:
	_w = w
	_h = h
	_origin = Vector2(-w * TILE / 2.0, -h * TILE / 2.0)
	_solid.clear()
	_water.clear()
	_ice.clear()
	_open.clear()
	_root = Node2D.new()
	_root.name = map_name
	_root.y_sort_enabled = true
	_root.set_script(load("res://systems/map_root.gd"))
	add_child(_root)
	_tm = TileMap.new()
	_tm.name = "GroundTiles"
	_tm.z_index = -10
	_tm.position = _origin
	_tm.tile_set = load("res://assets/tilesets/winter_v1.tres")
	_root.add_child(_tm)
	_tm.owner = _root
	_tm2 = TileMap.new()
	_tm2.name = "StoneTiles"
	_tm2.z_index = -9
	_tm2.position = _origin
	_tm2.tile_set = load("res://assets/tilesets/interior_tavern_v1.tres")
	_root.add_child(_tm2)
	_tm2.owner = _root


func _cc(c: float, r: float) -> Vector2:
	return _origin + Vector2((c + 0.5) * TILE, (r + 0.5) * TILE)


func _paint(c: int, r: int, t: String) -> void:
	if c >= 0 and c < _w and r >= 0 and r < _h:
		_tm.set_cell(0, Vector2i(c, r), 0, T[t])


func _tile_at(c: int, r: int) -> Vector2i:
	if c < 0 or c >= _w or r < 0 or r >= _h:
		return Vector2i(-1, -1)
	return _tm.get_cell_atlas_coords(0, Vector2i(c, r))


func _fill(mode: String = "snow") -> void:
	for c in _w:
		for r in _h:
			var roll := _rng.randf()
			var tt := "snow"
			if mode == "rocky":
				tt = "rocky_snow" if roll < 0.62 else ("snow" if roll < 0.86 else ("frost_grass" if roll < 0.96 else "ash_snow"))
			elif mode == "ash":
				tt = "ash_snow" if roll < 0.58 else ("snow" if roll < 0.86 else ("rocky_snow" if roll < 0.96 else "dead_scrub"))
			else:
				if roll < 0.07:
					tt = "drift"
				elif roll < 0.12:
					tt = "rocky_snow"
				elif roll < 0.145:
					tt = "frost_grass"
				elif roll < 0.16:
					tt = "dead_scrub"
			_paint(c, r, tt)


func _rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_paint(c, r, t)


func _patch(cc: int, cr: int, rx: int, ry: int, t: String, chance: float = 0.9) -> void:
	for c in range(cc - rx, cc + rx + 1):
		for r in range(cr - ry, cr + ry + 1):
			var dx := float(c - cc) / maxf(1.0, float(rx))
			var dy := float(r - cr) / maxf(1.0, float(ry))
			if dx * dx + dy * dy <= 1.0 and _rng.randf() < chance:
				_paint(c, r, t)


func _mark(c: int, r: int) -> void:
	if c >= 0 and c < _w and r >= 0 and r < _h:
		_solid[c + r * 10000] = true


func _unmark(c: int, r: int) -> void:
	_solid.erase(c + r * 10000)


func _mark_rect(c0: int, r0: int, c1: int, r1: int) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_mark(c, r)


## Băng ĐI ĐƯỢC: sơn ice/ice_shine/deep_ice + shore_* lên tuyết quanh rìa,
## KHÔNG mark solid (khác _water_blob của sa mạc vốn chặn nước).
func _ice_blob(cc: int, cr: int, rx: int, ry: int) -> void:
	for c in range(cc - rx, cc + rx + 1):
		for r in range(cr - ry, cr + ry + 1):
			var dx := float(c - cc) / maxf(1.0, float(rx))
			var dy := float(r - cr) / maxf(1.0, float(ry))
			var d2 := dx * dx + dy * dy
			if d2 <= 1.0:
				var tt := "ice"
				if d2 < 0.3:
					tt = "deep_ice" if _rng.randf() < 0.6 else "ice"
				elif _rng.randf() < 0.3:
					tt = "ice_shine"
				_paint(c, r, tt)
				_ice[c + r * 10000] = true
	_paint_ice_shores()


func _paint_ice_shores() -> void:
	for c in _w:
		for r in _h:
			if _ice.has(c + r * 10000):
				continue
			var cur := _tile_at(c, r)
			if cur == T["ice"] or cur == T["ice_shine"] or cur == T["deep_ice"]:
				continue
			if _ice.has(c + (r + 1) * 10000):
				_paint(c, r, "shore_s")
			elif _ice.has(c + (r - 1) * 10000):
				_paint(c, r, "shore_n")
			elif _ice.has((c - 1) + r * 10000):
				_paint(c, r, "shore_w")
			elif _ice.has((c + 1) + r * 10000):
				_paint(c, r, "shore_e")


func signi(v: int) -> int:
	return 0 if v == 0 else (1 if v > 0 else -1)


func _path_line(c0: int, r0: int, c1: int, r1: int) -> void:
	var dc := signi(c1 - c0)
	var dr := signi(r1 - r0)
	var c := c0
	var r := r0
	while true:
		for o in [0, 1]:
			var cc: int = c + (o if dc == 0 else 0)
			var rr: int = r + (o if dr == 0 else 0)
			_paint(cc, rr, "packed_snow" if _rng.randf() < 0.8 else "path_s")
			_unmark(cc, rr)
			_water.erase(cc + rr * 10000)
			_ice.erase(cc + rr * 10000)
		if c == c1 and r == r1:
			break
		c += dc
		r += dr


func _path(points: Array) -> void:
	for i in range(points.size() - 1):
		var a: Vector2i = points[i]
		var b: Vector2i = points[i + 1]
		_path_line(a.x, a.y, b.x, a.y)
		_path_line(b.x, a.y, b.x, b.y)


func _rock_wall(c0: int, r0: int, c1: int, r1: int, gaps: Array = [], tile_name: String = "dark_brick") -> void:
	_rect(c0, r0, c1, r1, tile_name)
	_mark_rect(c0, r0, c1, r1)
	for g in gaps:
		var gv: Vector2i = g
		_paint(gv.x, gv.y, "packed_snow")
		_unmark(gv.x, gv.y)
		_open[gv.x + gv.y * 10000] = true


func _prop(tex_name: String, cell: Vector2, scl: float = 1.0, node_name: String = "") -> Node2D:
	var holder := Node2D.new()
	holder.position = _cc(cell.x, cell.y)
	holder.y_sort_enabled = true
	holder.name = node_name if node_name != "" else ("Prop_" + tex_name)
	var tex: Texture2D = load("res://assets/props/" + tex_name + ".png")
	if tex == null:
		print("[FROSTGARD] LOI texture: ", tex_name)
		_fail = true
		return holder
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.position = Vector2(0, -tex.get_height() * scl / 2.0 + 8.0)
	sp.scale = Vector2(scl, scl)
	_root.add_child(holder)
	holder.add_child(sp)
	sp.owner = _root
	holder.owner = _root
	return holder


func _building(tex_name: String, left_c: int, bottom_r: int, w_tiles: int, depth: int = 2) -> void:
	var ground := Vector2(_origin.x + (left_c + w_tiles / 2.0) * TILE,
		_origin.y + (bottom_r + 1) * TILE)
	var holder := Node2D.new()
	holder.position = ground
	holder.y_sort_enabled = true
	holder.name = "House_" + tex_name + "_" + str(left_c) + "_" + str(bottom_r)
	var tex: Texture2D = load("res://assets/props/" + tex_name + ".png")
	if tex == null:
		print("[FROSTGARD] LOI texture nha: ", tex_name)
		_fail = true
		return
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.position = Vector2(0, -tex.get_height() / 2.0 + 8.0)
	_root.add_child(holder)
	holder.add_child(sp)
	sp.owner = _root
	holder.owner = _root
	_mark_rect(left_c, bottom_r - depth + 1, left_c + w_tiles - 1, bottom_r)


func _pine(cell: Vector2) -> void:
	_prop("snow_pine", cell, _rng.randf_range(0.85, 1.05))
	_mark_rect(int(cell.x) - 1, int(cell.y), int(cell.x), int(cell.y) + 1)


func _label(text: String, cell: Vector2, size: int = 22) -> void:
	var lb := Label.new()
	lb.text = text
	lb.position = _cc(cell.x, cell.y) + Vector2(-260, -16)
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	lb.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lb.z_index = 5
	_root.add_child(lb)
	lb.owner = _root


func _sa(arr: Array) -> Array[String]:
	var out: Array[String] = []
	for s in arr:
		out.append(str(s))
	return out


func _npc(node_name: String, npc_id: String, display: String, cell: Vector2,
		tint: Color, quests: Array, dlg: Dictionary, steps: Array,
		frames: String = "", wander_radius: float = -1.0) -> void:
	var ps: PackedScene = load("res://systems/npc.tscn")
	var n: Node = ps.instantiate()
	n.name = node_name
	n.position = _cc(cell.x, cell.y)
	n.set("npc_id", npc_id)
	n.set("display_name", display)
	n.set("quest_ids", _sa(quests))
	n.set("tint", tint)
	n.set("dialogue_before", _sa(dlg.get("before", [])))
	n.set("dialogue_active", _sa(dlg.get("active", [])))
	n.set("dialogue_ready", _sa(dlg.get("ready", [])))
	n.set("dialogue_done", _sa(dlg.get("done", [])))
	if frames != "":
		var spr: AnimatedSprite2D = n.get_node("AnimatedSprite2D")
		spr.sprite_frames = load(frames)
	var sch: Array[Dictionary] = []
	for s in steps:
		var p := _cc(float(s[0]), float(s[1]))
		sch.append({"x": p.x, "y": p.y, "action": str(s[2]), "time": float(s[3])})
	n.set("schedule", sch)
	n.set("schedule_enabled", not sch.is_empty())
	if wander_radius >= 0.0:
		n.set("wander_radius", wander_radius)
	_root.add_child(n)
	n.owner = _root


## remembering: -1 = giữ mặc định của scene, 0 = tắt (đánh thường), 1 = bật.
func _enemy(scene_file: String, cell: Vector2, elite: bool = false, respawn: float = 45.0, remembering: int = -1) -> void:
	var ps: PackedScene = load("res://enemies/" + scene_file)
	if ps == null:
		print("[FROSTGARD] LOI scene quai: ", scene_file)
		_fail = true
		return
	var e: Node = ps.instantiate()
	e.position = _cc(cell.x, cell.y)
	if elite:
		e.set("is_elite", true)
	if remembering >= 0 and e.get("remembering") != null:
		e.set("remembering", remembering == 1)
	if respawn > 0.0 and not scene_file.begins_with("boss"):
		e.set("respawn_time", respawn)
	_root.add_child(e)
	e.owner = _root


func _herb(cell: Vector2) -> void:
	var ps: PackedScene = load("res://systems/herb_pickup.tscn")
	var hnode: Node = ps.instantiate()
	hnode.position = _cc(cell.x, cell.y)
	_root.add_child(hnode)
	hnode.owner = _root


## Đợt 6: bàn chế tạo/giả kim (crafting cơ bản) ở hub của vùng.
func _craft_station(cell: Vector2, station_name: String = "Bàn Chế Tạo") -> void:
	var ps: PackedScene = load("res://systems/craft_station.tscn")
	var n: Node = ps.instantiate()
	n.name = "CraftStation"
	n.position = _cc(cell.x, cell.y)
	n.set("station_name", station_name)
	_root.add_child(n)
	n.owner = _root


func _portal(node_name: String, cell: Vector2, target: String, spawn: String,
		label: String, required_flag: String = "", locked_text: String = "") -> void:
	var ps: PackedScene = load("res://systems/portal.tscn")
	var p: Node = ps.instantiate()
	p.name = node_name
	p.position = _cc(cell.x, cell.y)
	p.set("target_scene", target)
	p.set("target_spawn", spawn)
	p.set("label_text", label)
	if required_flag != "":
		p.set("required_flag", required_flag)
		p.set("locked_text", locked_text)
	_root.add_child(p)
	p.owner = _root
	_unmark(int(cell.x), int(cell.y))
	_open[int(cell.x) + int(cell.y) * 10000] = true


func _spawn(spawn_name: String, cell: Vector2) -> void:
	var m := Marker2D.new()
	m.name = "Spawn_" + spawn_name
	m.position = _cc(cell.x, cell.y)
	_root.add_child(m)
	m.owner = _root
	_unmark(int(cell.x), int(cell.y))
	_open[int(cell.x) + int(cell.y) * 10000] = true


func _finish(save_path: String, start_cell: Vector2) -> void:
	for c in _w:
		_mark(c, 0)
		_mark(c, _h - 1)
	for r in _h:
		_mark(0, r)
		_mark(_w - 1, r)
	for key in _open.keys():
		_solid.erase(key)
	var body := StaticBody2D.new()
	body.name = "WorldCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	_root.add_child(body)
	body.owner = _root
	for r in _h:
		var c := 0
		while c < _w:
			if _solid.has(c + r * 10000):
				var c0 := c
				while c < _w and _solid.has(c + r * 10000):
					c += 1
				var cs := CollisionShape2D.new()
				var shape := RectangleShape2D.new()
				shape.size = Vector2((c - c0) * TILE, TILE)
				cs.shape = shape
				cs.position = _origin + Vector2((c0 + (c - c0) / 2.0) * TILE, (r + 0.5) * TILE)
				body.add_child(cs)
				cs.owner = _root
			else:
				c += 1
	var player: Node = load("res://player/player.tscn").instantiate()
	player.name = "Player"
	player.position = _cc(start_cell.x, start_cell.y)
	_root.add_child(player)
	player.owner = _root
	var hud: Node = load("res://ui/hud.tscn").instantiate()
	hud.name = "HUD"
	_root.add_child(hud)
	hud.owner = _root
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err != OK:
		print("[FROSTGARD] PACK LOI ", save_path, ": ", err)
		_fail = true
		return
	err = ResourceSaver.save(packed, save_path)
	print("[FROSTGARD] saved ", save_path, " err=", err, " solid=", _solid.size())
	if err != OK:
		_fail = true
	remove_child(_root)
	_root.queue_free()


func _stone_rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_tm2.set_cell(0, Vector2i(c, r), 0, STONE[t])
			_water.erase(c + r * 10000)
			_ice.erase(c + r * 10000)


func _stone_room(c0: int, r0: int, c1: int, r1: int, doors: Array) -> void:
	_stone_rect(c0, r0, c1, r1, "floor")
	for c in range(c0, c1 + 1):
		for r in [r0, r1]:
			_tm2.set_cell(0, Vector2i(c, r), 0, STONE["wall"])
			_mark(c, r)
	for r in range(r0, r1 + 1):
		for c in [c0, c1]:
			_tm2.set_cell(0, Vector2i(c, r), 0, STONE["wall"])
			_mark(c, r)
	for d in doors:
		_tm2.set_cell(0, d, 0, STONE["floor"])
		_unmark(d.x, d.y)


# ---------------- NORTHGATE (100x75) ----------------

func _build_northgate() -> void:
	_new_map("Northgate", 100, 75)
	_fill("snow")
	_patch(24, 24, 18, 12, "drift")
	_patch(76, 52, 16, 10, "ash_snow")
	# Đoạn tường khổng lồ ngang phía bắc + cổng ở giữa
	_rock_wall(30, 2, 70, 5, [Vector2i(49, 3), Vector2i(50, 3), Vector2i(49, 4), Vector2i(50, 4)])
	_path([Vector2i(50, 1), Vector2i(50, 36), Vector2i(50, 72)])
	_path([Vector2i(50, 36), Vector2i(16, 52)])
	_path([Vector2i(50, 36), Vector2i(84, 30)])
	for i in 10:
		_pine(Vector2(_rng.randi_range(3, 96), _rng.randi_range(8, 71)))
	for i in 5:
		_prop("ice_rock", Vector2(_rng.randi_range(4, 95), _rng.randi_range(8, 70)), _rng.randf_range(0.8, 1.05))
	_label("NORTHGATE — Cổng Bắc Vào Vùng", Vector2(50, 10), 26)
	_enemy("snow_wolf.tscn", Vector2(30, 24))
	_enemy("snow_wolf.tscn", Vector2(66, 30))
	_enemy("snow_wolf.tscn", Vector2(40, 56))
	_enemy("snow_wolf.tscn", Vector2(72, 58))
	_enemy("frost_wraith.tscn", Vector2(82, 24))
	_enemy("snow_wolf.tscn", Vector2(18, 40))
	_npc("NPC_LinhCaravanBac", "linh_caravan_bac", "Lính Caravan Đi Bắc", Vector2(45, 8),
		Color(0.75, 0.85, 1.0), [],
		{"done": ["Caravan đi Bắc chỉ chạy khi Solmaris đã yên — ngươi tới được đây nghĩa là phía Tây đã xong.",
			"Đi thẳng lên Hearthwick, làng Lò Sưởi. Nhớ: ở đây lò tắt là người chết, và người chết thì không nằm yên đâu."]},
		[[45, 8, "idle", 6], [56, 8, "walk", 5], [56, 8, "idle", 6], [45, 8, "walk", 5]])
	_spawn("start", Vector2(50, 69))
	_spawn("from_oasis", Vector2(50, 69))
	_spawn("from_hearthwick", Vector2(50, 6))
	_portal("PortalSouth", Vector2(50, 72), "res://maps/sunwell_oasis.tscn", "from_northgate", "Sunwell Oasis")
	_portal("PortalNorth", Vector2(50, 2), "res://maps/hearthwick.tscn", "from_northgate", "Hearthwick")
	_finish("res://maps/northgate.tscn", Vector2(50, 69))


# ---------------- HEARTHWICK (110x80) — làng trú đông ----------------

func _build_hearthwick() -> void:
	_new_map("Hearthwick", 110, 80)
	_fill("snow")
	_patch(20, 16, 18, 10, "drift")
	_patch(90, 64, 16, 9, "ash_snow")
	_path([Vector2i(55, 1), Vector2i(55, 39), Vector2i(55, 77)])
	_path([Vector2i(55, 40), Vector2i(107, 40)])
	_building("house_a", 24, 22, 6)
	_building("house_b", 36, 20, 7)
	_building("house_f", 66, 20, 5)
	_building("house_c", 76, 22, 8)
	_building("house_d", 26, 58, 6)
	_building("house_e", 66, 58, 7)
	# Lò Sưởi Lớn ở tâm làng — không bao giờ được tắt
	_prop("fireplace", Vector2(55, 36), 1.0, "GreatHearth")
	_prop("campfire", Vector2(55, 43), 1.0, "HearthFire")
	_prop("stall_a", Vector2(38, 34), 1.0, "HearthwickStall1")
	_prop("stall_b", Vector2(72, 34), 1.0, "HearthwickStall2")
	for i in 8:
		_pine(Vector2(_rng.randi_range(3, 106), _rng.randi_range(3, 76)))
	_label("HEARTHWICK — Làng Lò Sưởi (tên đề xuất)", Vector2(55, 12), 26)
	_label("LÒ SƯỞI LỚN — KHÔNG BAO GIỜ ĐƯỢC TẮT", Vector2(55, 32), 20)
	_herb(Vector2(30, 48))
	_herb(Vector2(80, 50))
	_herb(Vector2(20, 36))
	_herb(Vector2(90, 30))
	_enemy("snow_wolf.tscn", Vector2(12, 66))
	_enemy("snow_wolf.tscn", Vector2(98, 66))
	_enemy("snow_wolf.tscn", Vector2(55, 70))
	_enemy("wight.tscn", Vector2(8, 8))
	_enemy("wight.tscn", Vector2(102, 10))
	_npc("NPC_TruongLangLoSuoi", "truong_lang_lo_suoi", "Trưởng Làng Lò Sưởi", Vector2(49, 34),
		Color(0.9, 0.8, 0.65), ["bac_01_den_phuong_bac"],
		{"before": ["Ngươi là người của caravan sao? Sói Tuyết chặn đường Northgate từ đầu mùa rồi — dọn 4 con quanh cổng, làng này mới dám mở cửa đón ngươi.",
			"Ở Bắc, khách lạ không phải là gánh nặng. Khách lạ là thêm một đôi tay giữ lò, giữ tường."],
		 "active": ["Sói ở quanh Northgate và mép đường phía nam. Nghe tiếng tru theo bầy là biết chúng không đi một mình."],
		 "ready": ["Đường sạch rồi! Hearthwick mở lò đón ngươi. Ngồi xuống hong khô người đã."],
		 "done": ["Lò cháy được là nhờ ngươi. Giờ giữ cho nó đừng tắt — việc đó khó hơn dọn sói nhiều."]},
		[[49, 34, "idle", 5], [55, 35, "walk", 5], [55, 35, "work", 8], [42, 42, "walk", 5], [42, 42, "idle", 5], [49, 34, "walk", 5]])
	_npc("NPC_ChuLoSuoi", "chu_lo_suoi", "Chủ Lò Sưởi Hearthwick", Vector2(60, 44),
		Color(1.0, 0.72, 0.5), ["bac_02_lo_suoi"],
		{"before": ["Lò này cháy liên tục mấy đời rồi. Đêm nay bão to, ta cần thảo lửa chống lạnh — thứ cỏ đỏ mọc quanh làng và mép rừng thông. Thu đủ 4 cây mang về đây.",
			"Lò tắt một đêm thôi là sáng ra có nhà không ai mở cửa nữa. Ở Bắc, lạnh giết chậm hơn quái, nhưng chắc hơn."],
		 "active": ["Thảo lửa quanh làng và bìa Snowpine Forest. Nhặt đủ rồi quay lại, đừng để ta phải đi tìm ngươi trong bão."],
		 "ready": ["Đủ thảo lửa rồi! Đêm nay cả làng ngủ ấm. Ngươi vừa cứu nhiều mạng hơn ngươi tưởng đấy."],
		 "done": ["Từ nay lò này có phần công của ngươi. Người Bắc nhớ ơn bằng củi và canh nóng, không bằng lời hoa hòe."]},
		[[60, 44, "work", 9], [48, 44, "walk", 5], [48, 44, "work", 8], [60, 44, "walk", 5]], "res://assets/sprites/nong_dan_frames.tres")
	_npc("NPC_BaGoaGiuTen", "ba_goa_giu_ten", "Bà Góa Giữ Danh Sách", Vector2(47, 46),
		Color(0.82, 0.78, 0.9), ["bac_04_ten_doi_truong", "bac_05_tram_gac_ma", "bac_07b_pha_vua"],
		{"before": ["Ta giữ danh sách tên những người đi gác băng không về. Chồng ta ở dòng đầu tiên. Muốn giải thoát cho họ, phải gọi đúng tên — xuống Hầm Mộ Quân Đoàn đọc bia 5 đội trưởng cho ta.",
			"Ysolde, Bram, Odric, Sigrun, Tomas — ta thuộc lòng, nhưng nghi lễ cần người sống tận mắt đọc bia rồi mang tên về."],
		 "active": ["Hầm mộ ở phía đông Ghostwatch Post. Đọc đủ tên 5 đội trưởng, rồi tính chuyện trạm gác ma — hiệp sĩ ở đó quên cả tên khắc trên khiên của chính mình."],
		 "ready": ["Ngươi mang đủ tên về rồi... Vậy là họ vẫn còn là người, không phải chỉ là 'quân đoàn ma' như người ta gọi."],
		 "done": ["Dù kết cục thế nào, danh sách này từ nay đóng lại được rồi. Cảm ơn ngươi đã không để họ ra đi vô danh."]},
		[[47, 46, "idle", 6], [55, 46, "walk", 5], [55, 46, "work", 8], [47, 46, "walk", 5]])
	_npc("NPC_DoiTruongGacLang", "doi_truong_gac_lang", "Đội Trưởng Gác Làng", Vector2(66, 36),
		Color(0.7, 0.8, 0.95), ["bac_03_giu_tuong_dem"],
		{"before": ["Đêm xuống là Wight lại về. Người chết trong bão tuyết ở đây không nằm yên — chúng nhớ đường về tường làng. Diệt 5 con Wight quanh làng, trạm gác và đường lên thành, đêm nay dân mới ngủ được.",
			"Đừng coi thường chúng: wight không biết sợ, cũng không biết mệt. Ngươi thì có cả hai."],
		 "active": ["Wight ở góc xa của làng, quanh Ghostwatch Post và Frostgard Approach. Đánh ban ngày vẫn hơn chờ chúng tới ban đêm."],
		 "ready": ["Tường đứng vững qua đêm nay là nhờ ngươi. Ca gác này ghi tên ngươi vào sổ."],
		 "done": ["Ngươi giữ tường một đêm đã mệt thế này. Tưởng tượng giữ mấy trăm năm như quân đoàn trên kia xem."]},
		[[66, 36, "idle", 5], [74, 40, "walk", 5], [74, 40, "idle", 6], [55, 48, "walk", 5], [55, 48, "idle", 5], [66, 36, "walk", 5]])
	_npc("NPC_ThoSanDauDan", "tho_san_dau_dan", "Thợ Săn Đầu Đàn", Vector2(40, 43),
		Color(0.85, 0.9, 0.8), ["bac_side_hunt"],
		{"before": ["Quái Băng quanh Frozen Lake vỡ ra là nổ băng — săn chúng phải tính cả đòn chết của chúng. Hạ 3 con rồi về đây lĩnh thưởng.",
			"Săn quái để sống còn dễ chấp nhận hơn bị chọn đi gác băng cho một phong ấn không ai giải thích. Nhớ lấy điều đó."],
		 "active": ["Quái Băng ở hồ đông và rừng thông. Kết liễu xong thì lùi ngay, đừng đứng ngắm lõi băng vỡ."],
		 "ready": ["Ba lõi băng! Da tuyết và nanh đổi được khối củi đấy. Tay săn của ngươi được làng này công nhận rồi."],
		 "done": ["Lần sau đi săn, cứ tới tìm ta. Người Bắc không bỏ thợ săn giỏi lại phía sau trong bão."]},
		[[40, 43, "work", 9], [70, 43, "walk", 6], [70, 43, "work", 8], [40, 43, "walk", 6]])
	_npc("NPC_TreSan", "tre_san", "Trẻ Săn Tuyết", Vector2(58, 50),
		Color(1.0, 0.9, 0.7), [],
		{"done": ["Em tập săn mỗi ngày đấy. Săn giỏi thì được ở lại làng — dở thì bị chọn đi gác băng trên thành, mà đi gác băng thì không ai về cả.",
			"Anh/chị gặp vua băng chưa? Người già nói ông ấy vẫn ra lệnh đổi ca mỗi đêm, dù chẳng còn ai sống để nghe."]},
		[[58, 50, "idle", 5], [62, 52, "walk", 5], [62, 52, "idle", 5], [58, 50, "walk", 5]])
	_spawn("start", Vector2(55, 74))
	_spawn("from_northgate", Vector2(55, 74))
	_spawn("from_snowpine", Vector2(55, 5))
	_spawn("from_pass", Vector2(104, 40))
	_portal("PortalSouth", Vector2(55, 77), "res://maps/northgate.tscn", "from_hearthwick", "Northgate")
	_portal("PortalNorth", Vector2(55, 2), "res://maps/snowpine_forest.tscn", "from_hearthwick", "Snowpine Forest")
	_portal("PortalEast", Vector2(107, 40), "res://maps/howling_pass.tscn", "from_hearthwick", "Howling Pass")
	_craft_station(Vector2(62, 46), "Lò Rèn Hearthwick")
	_finish("res://maps/hearthwick.tscn", Vector2(55, 74))


# ---------------- SNOWPINE FOREST (140x100) ----------------

func _build_snowpine() -> void:
	_new_map("SnowpineForest", 140, 100)
	_fill("snow")
	_patch(40, 30, 22, 13, "frost_grass")
	_patch(100, 70, 24, 13, "frost_grass")
	for i in 42:
		_pine(Vector2(_rng.randi_range(4, 135), _rng.randi_range(4, 95)))
	for i in 10:
		_prop("ice_rock", Vector2(_rng.randi_range(6, 133), _rng.randi_range(6, 93)), _rng.randf_range(0.75, 1.05))
	_path([Vector2i(3, 50), Vector2i(70, 50), Vector2i(136, 50)])
	_label("SNOWPINE FOREST — Rừng Thông Tuyết", Vector2(70, 44), 26)
	_herb(Vector2(34, 48))
	_herb(Vector2(70, 56))
	_herb(Vector2(116, 44))
	_enemy("snow_wolf.tscn", Vector2(26, 42))
	_enemy("snow_wolf.tscn", Vector2(44, 62))
	_enemy("snow_wolf.tscn", Vector2(66, 36))
	_enemy("snow_wolf.tscn", Vector2(84, 64))
	_enemy("snow_wolf.tscn", Vector2(106, 38))
	_enemy("snow_wolf.tscn", Vector2(124, 62))
	_enemy("frost_wraith.tscn", Vector2(50, 24))
	_enemy("frost_wraith.tscn", Vector2(92, 78))
	_enemy("frost_wraith.tscn", Vector2(120, 24))
	_enemy("ice_elemental.tscn", Vector2(36, 80))
	_enemy("ice_elemental.tscn", Vector2(110, 82))
	_spawn("start", Vector2(5, 50))
	_spawn("from_hearthwick", Vector2(5, 50))
	_spawn("from_frozenlake", Vector2(134, 50))
	_portal("PortalWest", Vector2(3, 50), "res://maps/hearthwick.tscn", "from_snowpine", "Hearthwick")
	_portal("PortalEast", Vector2(136, 50), "res://maps/frozen_lake.tscn", "from_snowpine", "Frozen Lake")
	_finish("res://maps/snowpine_forest.tscn", Vector2(5, 50))


# ---------------- FROZEN LAKE (130x95) ----------------

func _build_frozen_lake() -> void:
	_new_map("FrozenLake", 130, 95)
	_fill("snow")
	_ice_blob(65, 47, 38, 26)
	_patch(50, 40, 7, 4, "packed_snow")
	_patch(82, 56, 8, 5, "packed_snow")
	_patch(65, 30, 6, 4, "packed_snow")
	_prop("grave_stone", Vector2(52, 38), 1.0, "LakeGrave1")
	_prop("grave_stone", Vector2(84, 58), 0.9, "LakeGrave2")
	_prop("ice_rock", Vector2(66, 28), 1.0, "LakeIceRock1")
	_prop("ice_rock", Vector2(40, 60), 0.9, "LakeIceRock2")
	_prop("ice_rock", Vector2(92, 36), 0.9, "LakeIceRock3")
	_building("house_c", 10, 20, 8)
	_path([Vector2i(3, 47), Vector2i(30, 47)])
	_path([Vector2i(100, 47), Vector2i(126, 47)])
	_label("FROZEN LAKE — Hồ Đóng Băng (đi trên mặt băng được)", Vector2(65, 14), 26)
	_enemy("ice_elemental.tscn", Vector2(48, 44))
	_enemy("ice_elemental.tscn", Vector2(65, 52))
	_enemy("ice_elemental.tscn", Vector2(82, 42))
	_enemy("ice_elemental.tscn", Vector2(58, 62))
	_enemy("frost_wraith.tscn", Vector2(40, 30))
	_enemy("frost_wraith.tscn", Vector2(90, 60))
	_enemy("frost_wraith.tscn", Vector2(70, 36))
	_enemy("wight.tscn", Vector2(24, 70))
	_enemy("wight.tscn", Vector2(106, 24))
	_npc("NPC_ThayDiem", "thay_diem", "Thầy Điềm Bờ Hồ", Vector2(16, 24),
		Color(0.78, 0.82, 1.0), ["bac_side_wraith"],
		{"before": ["Cực quang dạo này hiện cả ban ngày — điềm phong ấn yếu đi, người già bảo thế. Hồn Ma Băng lướt trên mặt hồ làm dân không dám qua. Dẹp 3 con rồi quay lại đây.",
			"Đứng trên băng mà nghe tiếng nứt xa... đó là hồ đang thở, hoặc là thứ gì dưới hồ đang cựa mình."],
		 "active": ["Hồn ma lướt nhanh lắm, chúng lao vào ngươi theo kiểu wyvern. Đừng đứng giữa hồ trống trải mà không có đường lùi."],
		 "ready": ["Mặt hồ yên lại rồi. Đêm nay cực quang chắc sẽ chỉ đẹp, không dọa người nữa."],
		 "done": ["Ngươi đi trên băng nhẹ như người Bắc chính gốc vậy. Ít khách phương xa làm được thế."]},
		[[16, 24, "idle", 6], [24, 30, "walk", 5], [24, 30, "idle", 6], [16, 36, "walk", 5], [16, 36, "idle", 5], [16, 24, "walk", 5]], "res://assets/sprites/linh_tuan_frames.tres")
	_spawn("start", Vector2(5, 47))
	_spawn("from_snowpine", Vector2(5, 47))
	_spawn("from_ghostwatch", Vector2(124, 47))
	_portal("PortalWest", Vector2(3, 47), "res://maps/snowpine_forest.tscn", "from_frozenlake", "Snowpine Forest")
	_portal("PortalEast", Vector2(126, 47), "res://maps/ghostwatch_post.tscn", "from_frozenlake", "Ghostwatch Post")
	_finish("res://maps/frozen_lake.tscn", Vector2(5, 47))


# ---------------- GHOSTWATCH POST (110x80) — trạm gác ma ----------------

func _build_ghostwatch() -> void:
	_new_map("GhostwatchPost", 110, 80)
	_fill("ash")
	_patch(30, 20, 18, 10, "snow")
	# Tường đá đen đổ nát bao trạm, chừa khe sập
	_rock_wall(14, 18, 46, 20, [Vector2i(30, 19), Vector2i(31, 19)])
	_rock_wall(64, 18, 96, 20, [Vector2i(80, 19)])
	_rock_wall(14, 60, 46, 62, [Vector2i(28, 61)])
	_rock_wall(64, 60, 96, 62, [Vector2i(78, 61), Vector2i(79, 61)])
	_prop("tower", Vector2(16, 14), 0.9, "GhostTower1")
	_prop("tower", Vector2(94, 14), 0.9, "GhostTower2")
	_path([Vector2i(3, 40), Vector2i(55, 40), Vector2i(106, 40)])
	for i in 6:
		_prop("grave_stone", Vector2(_rng.randi_range(8, 101), _rng.randi_range(8, 71)), _rng.randf_range(0.8, 1.0))
	_label("GHOSTWATCH POST — Trạm Gác Ma Bỏ Hoang", Vector2(55, 10), 26)
	_label("Hiệp sĩ ở đây ĐANG NHỚ — họ chỉ đánh khi ngươi lại rất gần. Đừng giết vội cũng được.", Vector2(55, 30), 19)
	# 4 hiệp sĩ "đang nhớ" tại các điểm gác (mặc định remembering=true)
	_enemy("frost_knight.tscn", Vector2(30, 24))
	_enemy("frost_knight.tscn", Vector2(80, 24))
	_enemy("frost_knight.tscn", Vector2(30, 56))
	_enemy("frost_knight.tscn", Vector2(80, 56))
	# 2 hiệp sĩ gần cửa hầm đã tỉnh hẳn (remembering=false)
	_enemy("frost_knight.tscn", Vector2(98, 36), false, 45.0, 0)
	_enemy("frost_knight.tscn", Vector2(98, 44), false, 45.0, 0)
	_enemy("wight.tscn", Vector2(24, 40))
	_enemy("wight.tscn", Vector2(55, 28))
	_enemy("wight.tscn", Vector2(55, 52))
	_enemy("wight.tscn", Vector2(88, 40))
	_spawn("start", Vector2(5, 40))
	_spawn("from_frozenlake", Vector2(5, 40))
	_spawn("from_crypt", Vector2(104, 40))
	_portal("PortalWest", Vector2(3, 40), "res://maps/frozen_lake.tscn", "from_ghostwatch", "Frozen Lake")
	_portal("PortalEast", Vector2(106, 40), "res://maps/legion_crypt.tscn", "from_ghostwatch", "Legion Crypt")
	_finish("res://maps/ghostwatch_post.tscn", Vector2(5, 40))


# ---------------- LEGION CRYPT (150x100) — hầm mộ quân đoàn ----------------

func _build_crypt() -> void:
	_new_map("LegionCrypt", 150, 100)
	_fill("ash")
	_stone_rect(0, 0, 149, 99, "floor")
	# Sảnh vào (nam-tây)
	_stone_room(8, 62, 45, 92, [Vector2i(45, 76), Vector2i(26, 62)])
	# Hành lang kho (nam-giữa)
	_stone_room(46, 58, 78, 92, [Vector2i(46, 76), Vector2i(78, 76), Vector2i(62, 58)])
	# Doanh trại cũ (đông-nam)
	_stone_room(79, 58, 112, 92, [Vector2i(79, 76), Vector2i(96, 58)])
	# PHÒNG BIA TƯỞNG NIỆM (giữa): 5 tượng + tên 5 đội trưởng
	_stone_room(55, 30, 95, 57, [Vector2i(62, 57), Vector2i(95, 44), Vector2i(75, 30)])
	# Thư viện phía tây
	_stone_room(10, 25, 45, 57, [Vector2i(45, 44), Vector2i(26, 57)])
	# Kho sâu phía đông-bắc (đội trưởng gác đầu tiên)
	_stone_room(96, 25, 140, 57, [Vector2i(96, 44), Vector2i(118, 57)])
	# PHÒNG CHUÔNG CÂM (bắc-giữa)
	_stone_room(60, 5, 90, 29, [Vector2i(75, 29)])
	_prop("statue", Vector2(62, 38), 0.85, "MemorialStatue1")
	_prop("statue", Vector2(68, 38), 0.85, "MemorialStatue2")
	_prop("statue", Vector2(75, 38), 0.9, "MemorialStatue3")
	_prop("statue", Vector2(82, 38), 0.85, "MemorialStatue4")
	_prop("statue", Vector2(88, 38), 0.85, "MemorialStatue5")
	_prop("campfire", Vector2(75, 16), 0.8, "SilentBellGlow")
	for i in 6:
		_prop("grave_stone", Vector2(_rng.randi_range(12, 138), _rng.randi_range(8, 92)), _rng.randf_range(0.75, 0.95))
	_label("LEGION CRYPT — Hầm Mộ Quân Đoàn", Vector2(75, 88), 24)
	_label("PHÒNG BIA TƯỞNG NIỆM — NĂM ĐỘI TRƯỞNG", Vector2(75, 33), 20)
	_label("Ysolde (đội cung) • Bram (đội khiên) • Odric (đội gác chuông) • Sigrun (đội trinh sát) • Tomas (đội hậu cần)", Vector2(75, 46), 17)
	_label("PHÒNG CHUÔNG CÂM — chuông này đã không rung mấy trăm năm", Vector2(75, 9), 19)
	_label("KHO SÂU — Đội Trưởng Gác Đầu Tiên, người bị đóng băng lâu nhất", Vector2(118, 28), 17)
	_herb(Vector2(20, 84))
	_herb(Vector2(104, 84))
	_enemy("wight.tscn", Vector2(24, 76))
	_enemy("wight.tscn", Vector2(62, 76))
	_enemy("wight.tscn", Vector2(28, 40))
	_enemy("wight.tscn", Vector2(75, 20))
	_enemy("frost_knight.tscn", Vector2(96, 76))
	_enemy("frost_knight.tscn", Vector2(75, 44))
	_enemy("frost_knight.tscn", Vector2(36, 70))
	_enemy("ice_elemental.tscn", Vector2(52, 66))
	_enemy("ice_elemental.tscn", Vector2(128, 50))
	_enemy("frost_knight.tscn", Vector2(118, 36), true, 0.0)
	_spawn("start", Vector2(14, 88))
	_spawn("from_ghostwatch", Vector2(14, 88))
	_portal("PortalEntry", Vector2(12, 90), "res://maps/ghostwatch_post.tscn", "from_crypt", "Ghostwatch Post")
	_finish("res://maps/legion_crypt.tscn", Vector2(14, 88))


# ---------------- HOWLING PASS (140x100) ----------------

func _build_howling_pass() -> void:
	_new_map("HowlingPass", 140, 100)
	_fill("rocky")
	_patch(24, 22, 18, 10, "ash_snow")
	_patch(116, 78, 18, 10, "drift")
	# Vách hẻm núi đá chừa khe đi
	_rock_wall(8, 24, 58, 26, [Vector2i(38, 25), Vector2i(39, 25)])
	_rock_wall(76, 24, 132, 26, [Vector2i(98, 25), Vector2i(99, 25)])
	_rock_wall(8, 72, 58, 74, [Vector2i(30, 73), Vector2i(31, 73)])
	_rock_wall(76, 72, 132, 74, [Vector2i(112, 73), Vector2i(113, 73)])
	_ice_blob(70, 60, 10, 6)
	_path([Vector2i(3, 50), Vector2i(70, 50), Vector2i(136, 50)])
	_label("HOWLING PASS — Đèo Gió Rít", Vector2(70, 44), 26)
	for i in 10:
		_prop("ice_rock", Vector2(_rng.randi_range(4, 135), _rng.randi_range(4, 95)), _rng.randf_range(0.7, 1.05))
	_enemy("snow_wolf.tscn", Vector2(24, 42))
	_enemy("snow_wolf.tscn", Vector2(44, 62))
	_enemy("snow_wolf.tscn", Vector2(70, 36))
	_enemy("snow_wolf.tscn", Vector2(96, 62))
	_enemy("snow_wolf.tscn", Vector2(118, 42))
	_enemy("frost_wraith.tscn", Vector2(34, 84))
	_enemy("frost_wraith.tscn", Vector2(70, 84))
	_enemy("frost_wraith.tscn", Vector2(106, 84))
	_enemy("ice_elemental.tscn", Vector2(70, 58), true)
	_spawn("start", Vector2(5, 50))
	_spawn("from_hearthwick", Vector2(5, 50))
	_spawn("from_approach", Vector2(134, 50))
	_portal("PortalWest", Vector2(3, 50), "res://maps/hearthwick.tscn", "from_pass", "Hearthwick")
	_portal("PortalEast", Vector2(136, 50), "res://maps/frostgard_approach.tscn", "from_pass", "Frostgard Approach")
	_finish("res://maps/howling_pass.tscn", Vector2(5, 50))


# ---------------- FROSTGARD APPROACH (120x85) — tiền sảnh pháo đài ----------------

func _build_approach() -> void:
	_new_map("FrostgardApproach", 120, 85)
	_fill("snow")
	_patch(24, 64, 20, 11, "ash_snow")
	_patch(96, 64, 18, 10, "drift")
	# Tường đá đen phía bắc + cổng thành (portal khóa vào nội thành chưa dựng)
	_rock_wall(8, 8, 112, 10, [Vector2i(60, 9), Vector2i(61, 9)])
	_rock_wall(8, 8, 10, 40, [])
	_rock_wall(110, 8, 112, 40, [])
	_path([Vector2i(60, 80), Vector2i(60, 48)])
	_path([Vector2i(24, 42), Vector2i(96, 42)])
	# Đài Ngai Băng ở phía bắc-giữa, dưới chân tường
	_prop("statue", Vector2(52, 16), 1.0, "ThroneStatueL")
	_prop("statue", Vector2(68, 16), 1.0, "ThroneStatueR")
	_prop("ice_rock", Vector2(44, 20), 0.9, "ThroneIceL")
	_prop("ice_rock", Vector2(76, 20), 0.9, "ThroneIceR")
	for i in 6:
		_prop("grave_stone", Vector2(_rng.randi_range(12, 108), _rng.randi_range(56, 78)), _rng.randf_range(0.8, 0.95))
	_label("FROSTGARD APPROACH — Tiền Sảnh Pháo Đài Băng Nứt", Vector2(60, 14), 26)
	_label("ĐÀI NGAI BĂNG — Vua vẫn ngồi gác, mấy trăm năm chưa đổi ca", Vector2(60, 24), 20)
	_enemy("wight.tscn", Vector2(34, 34))
	_enemy("wight.tscn", Vector2(86, 34))
	_enemy("wight.tscn", Vector2(60, 62))
	_enemy("frost_knight.tscn", Vector2(54, 20), false, 45.0, 0)
	_enemy("frost_knight.tscn", Vector2(66, 20), false, 45.0, 0)
	_enemy("boss_curse_warden.tscn", Vector2(60, 42), false, 0.0)
	_npc("NPC_VuaBacBang", "vua_bac_bang", "King Valdemar (tên đề xuất) — Vua Băng Bị Nguyền", Vector2(60, 18),
		Color(0.6, 0.8, 1.0), ["bac_06_ke_giu_nguyen", "bac_07a_giai_thoat"],
		{"before": ["...Ca gác... chưa hết ca gác. Kẻ Giữ Nguyền còn đứng giữa sân kia — chừng nào nó còn giữ sổ nguyền, chừng đó ta còn phải ngồi đây thi hành một mệnh lệnh đã chết cùng người ra lệnh.",
			"Ngươi đánh nó, không phải đánh ta. Nhớ lấy điều đó, hiệp sĩ sống."],
		 "active": ["Đạn Băng của nó bay theo loạt. Hiệp sĩ hai bên ngai của ta đã bị nguyền kéo cạn ký ức rồi — chúng không còn 'đang nhớ' nữa đâu."],
		 "ready": ["Nguyền... vỡ rồi. Lần đầu tiên sau mấy trăm năm, ta nghe thấy im lặng. Ngươi mang tên các đội trưởng tới chứ? Đọc chúng lên bên chiếc chuông câm — đọc cả tên ta nữa. Ta muốn ra đi như một người có tên, không phải như một cái ngai.",
			"Cảm ơn ngươi. Nói với bà góa giữ danh sách: ca gác cuối cùng đã xong. Mọi người được về nhà rồi."],
		 "done": ["...Gió Bắc hôm nay nhẹ. Quân đoàn ngủ yên. Ngươi đi tiếp đi — tháp ở giữa thế gian kia còn nợ nhiều người một lời giải thích hơn ta nhiều."]},
		[], "", 0.0)
	_spawn("start", Vector2(60, 78))
	_spawn("from_pass", Vector2(60, 78))
	_spawn("from_city_stub", Vector2(52, 6))
	_spawn("from_dat_chet", Vector2(60, 6))
	_portal("PortalSouth", Vector2(60, 80), "res://maps/howling_pass.tscn", "from_approach", "Howling Pass")
	_portal("PortalCity", Vector2(52, 4), "res://maps/frostgard_approach.tscn", "from_city_stub",
		"Frostgard (nội thành chưa dựng)", "thanh_frostgard_mo",
		"Nội thành Frostgard chưa dựng — layout đang chờ user duyệt.")
	# Đợt 6: đường lên Đất Chết + Sigilspire, mở sau khi Bắc giải phóng.
	_portal("PortalNorth", Vector2(60, 4), "res://maps/dat_chet.tscn", "from_frostgard",
		"Đất Chết Trung Tâm — Sigilspire", "bac_giai_phong",
		"Đường lên Đất Chết còn bị nguyền băng chặn: hãy giải phóng Frostgard trước (quest Bắc 07).")
	_finish("res://maps/frostgard_approach.tscn", Vector2(60, 78))
