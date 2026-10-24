extends Node2D
## Tool một lần (đợt 4): dựng 8 map VÙNG TÂY SOLMARIS theo
## design/solmaris_so_do.md (Westgate, Sunwell Oasis, Dunefield,
## Dunehawk Camp, Redrock Canyon, Stonesong Camp, Buried Sand Ruins,
## Vesskar's Lair). Nội thành Solmaris KHÔNG dựng (chờ duyệt layout).
## Chạy: godot --headless --path game res://tools_paint/paint_solmaris.tscn

const TILE := 64.0
const T := {
	"sand": Vector2i(0, 0), "dune": Vector2i(1, 0), "rocky": Vector2i(2, 0),
	"cracked": Vector2i(3, 0), "water_a": Vector2i(4, 0), "water_b": Vector2i(0, 1),
	"shore_s": Vector2i(1, 1), "shore_n": Vector2i(2, 1), "shore_w": Vector2i(3, 1),
	"shore_e": Vector2i(4, 1), "shore_cvx": Vector2i(0, 2), "shore_ccv": Vector2i(1, 2),
	"dry_grass": Vector2i(2, 2), "stone_floor": Vector2i(3, 2), "stone_brick": Vector2i(4, 2),
	"bone": Vector2i(0, 3), "path_s": Vector2i(1, 3), "path_n": Vector2i(2, 3),
	"scrub": Vector2i(3, 3), "sand_pad": Vector2i(4, 3),
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
var _open := {}
var _fail := false


func _ready() -> void:
	_rng.seed = 131318
	_build_westgate()
	_build_oasis()
	_build_dunefield()
	_build_dunehawk()
	_build_canyon()
	_build_stonesong()
	_build_ruins()
	_build_lair()
	print("[SOLMARIS] ====== HOAN TAT, fail=", _fail)
	get_tree().quit(1 if _fail else 0)


func _new_map(map_name: String, w: int, h: int) -> void:
	_w = w
	_h = h
	_origin = Vector2(-w * TILE / 2.0, -h * TILE / 2.0)
	_solid.clear()
	_water.clear()
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
	_tm.tile_set = load("res://assets/tilesets/desert_v1.tres")
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


func _fill(mode: String = "sand") -> void:
	for c in _w:
		for r in _h:
			var roll := _rng.randf()
			var tt := "sand"
			if mode == "rocky":
				tt = "rocky" if roll < 0.62 else ("sand" if roll < 0.86 else ("cracked" if roll < 0.96 else "bone"))
			elif mode == "cracked":
				tt = "cracked" if roll < 0.58 else ("sand" if roll < 0.86 else ("rocky" if roll < 0.96 else "bone"))
			else:
				if roll < 0.07:
					tt = "dune"
				elif roll < 0.12:
					tt = "rocky"
				elif roll < 0.145:
					tt = "dry_grass"
				elif roll < 0.16:
					tt = "bone"
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


func _water_blob(cc: int, cr: int, rx: int, ry: int, solid_water: bool) -> void:
	for c in range(cc - rx, cc + rx + 1):
		for r in range(cr - ry, cr + ry + 1):
			var dx := float(c - cc) / maxf(1.0, float(rx))
			var dy := float(r - cr) / maxf(1.0, float(ry))
			if dx * dx + dy * dy <= 1.0:
				_paint(c, r, "water_a" if _rng.randf() < 0.5 else "water_b")
				_water[c + r * 10000] = true
				if solid_water:
					_mark(c, r)
	_paint_shores()


func _paint_shores() -> void:
	for c in _w:
		for r in _h:
			if _water.has(c + r * 10000):
				continue
			var cur := _tile_at(c, r)
			if cur == T["water_a"] or cur == T["water_b"]:
				continue
			if _water.has(c + (r + 1) * 10000):
				_paint(c, r, "shore_s")
			elif _water.has(c + (r - 1) * 10000):
				_paint(c, r, "shore_n")
			elif _water.has((c - 1) + r * 10000):
				_paint(c, r, "shore_w")
			elif _water.has((c + 1) + r * 10000):
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
			_paint(cc, rr, "stone_floor" if _rng.randf() < 0.35 else "cracked")
			_unmark(cc, rr)
			_water.erase(cc + rr * 10000)
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


func _rock_wall(c0: int, r0: int, c1: int, r1: int, gaps: Array = []) -> void:
	_rect(c0, r0, c1, r1, "stone_brick")
	_mark_rect(c0, r0, c1, r1)
	for g in gaps:
		var gv: Vector2i = g
		_paint(gv.x, gv.y, "cracked")
		_unmark(gv.x, gv.y)
		_open[gv.x + gv.y * 10000] = true


func _prop(tex_name: String, cell: Vector2, scl: float = 1.0, node_name: String = "") -> Node2D:
	var holder := Node2D.new()
	holder.position = _cc(cell.x, cell.y)
	holder.y_sort_enabled = true
	holder.name = node_name if node_name != "" else ("Prop_" + tex_name)
	var tex: Texture2D = load("res://assets/props/" + tex_name + ".png")
	if tex == null:
		print("[SOLMARIS] LOI texture: ", tex_name)
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
		print("[SOLMARIS] LOI texture nha: ", tex_name)
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


func _tent(cell: Vector2) -> void:
	_prop("tribal_tent", cell, 1.0)
	_mark_rect(int(cell.x) - 2, int(cell.y) - 1, int(cell.x) + 1, int(cell.y) + 1)


func _label(text: String, cell: Vector2, size: int = 22) -> void:
	var lb := Label.new()
	lb.text = text
	lb.position = _cc(cell.x, cell.y) + Vector2(-260, -16)
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", Color(1, 0.97, 0.85))
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
		frames: String = "") -> void:
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
	_root.add_child(n)
	n.owner = _root


func _enemy(scene_file: String, cell: Vector2, elite: bool = false, respawn: float = 45.0) -> void:
	var ps: PackedScene = load("res://enemies/" + scene_file)
	if ps == null:
		print("[SOLMARIS] LOI scene quai: ", scene_file)
		_fail = true
		return
	var e: Node = ps.instantiate()
	e.position = _cc(cell.x, cell.y)
	if elite:
		e.set("is_elite", true)
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
		print("[SOLMARIS] PACK LOI ", save_path, ": ", err)
		_fail = true
		return
	err = ResourceSaver.save(packed, save_path)
	print("[SOLMARIS] saved ", save_path, " err=", err, " solid=", _solid.size())
	if err != OK:
		_fail = true
	remove_child(_root)
	_root.queue_free()


func _stone_rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_tm2.set_cell(0, Vector2i(c, r), 0, STONE[t])
			_water.erase(c + r * 10000)


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


# ---------------- WESTGATE (100x75) ----------------

func _build_westgate() -> void:
	_new_map("Westgate", 100, 75)
	_fill("sand")
	_patch(24, 24, 18, 12, "dune")
	_patch(76, 52, 16, 10, "bone")
	_water_blob(14, 58, 8, 5, true)
	# Đoạn tường khổng lồ ngang phía bắc + cổng ở giữa
	_rock_wall(30, 2, 70, 5, [Vector2i(49, 3), Vector2i(50, 3), Vector2i(49, 4), Vector2i(50, 4)])
	_path([Vector2i(50, 1), Vector2i(50, 36), Vector2i(50, 72)])
	_path([Vector2i(50, 36), Vector2i(16, 52)])
	_path([Vector2i(50, 36), Vector2i(84, 30)])
	for i in 12:
		_prop("cactus", Vector2(_rng.randi_range(3, 96), _rng.randi_range(8, 71)), _rng.randf_range(0.8, 1.1))
	for i in 5:
		_prop("palm_tree", Vector2(_rng.randi_range(4, 24), _rng.randi_range(48, 68)), 0.9)
	_prop("bone_rib", Vector2(78, 54), 1.0, "GateBones")
	_label("WESTGATE — Cổng Tây Vào Vùng", Vector2(50, 10), 26)
	_enemy("sand_scorpion.tscn", Vector2(30, 24))
	_enemy("sand_scorpion.tscn", Vector2(66, 30))
	_enemy("sand_scorpion.tscn", Vector2(40, 56))
	_enemy("sand_scorpion.tscn", Vector2(72, 58))
	_enemy("sand_snake.tscn", Vector2(56, 20))
	_enemy("sand_snake.tscn", Vector2(24, 42))
	_enemy("sand_vulture.tscn", Vector2(82, 24))
	_enemy("sand_vulture.tscn", Vector2(16, 20))
	_npc("NPC_LinhCuaTay", "linh_thue_cua_tay", "Lính Đánh Thuê Gác Cổng Tây", Vector2(45, 8),
		Color(0.9, 0.65, 0.5), [],
		{"done": ["Cổng này chỉ mở cho người đã xong chuyện Fenmire — hội đồng không muốn rắc rối của giáo phái tràn sang sa mạc.",
			"Đi thẳng xuống Sunwell Oasis. Nhớ: ở đây nước còn quý hơn vàng, và lời thề còn nặng hơn nước."]},
		[[45, 8, "idle", 6], [56, 8, "walk", 5], [56, 8, "idle", 6], [45, 8, "walk", 5]])
	_spawn("start", Vector2(50, 6))
	_spawn("from_approach", Vector2(50, 6))
	_spawn("from_oasis", Vector2(50, 69))
	_portal("PortalNorth", Vector2(50, 1), "res://maps/fenmire_approach.tscn", "from_westgate", "Fenmire Approach (caravan về Nam)")
	_portal("PortalSouth", Vector2(50, 72), "res://maps/sunwell_oasis.tscn", "from_westgate", "Sunwell Oasis")
	_finish("res://maps/westgate.tscn", Vector2(50, 6))


# ---------------- SUNWELL OASIS (110x80) — thị trấn ốc đảo ----------------

func _build_oasis() -> void:
	_new_map("SunwellOasis", 110, 80)
	_fill("sand")
	_patch(20, 16, 18, 10, "dune")
	_patch(90, 64, 16, 9, "bone")
	_water_blob(55, 39, 16, 9, true)
	_prop("fountain", Vector2(55, 39), 0.6, "SunwellFountain")
	# đường đá xuyên qua ốc đảo theo 2 trục (cầu/đê qua mặt nước)
	_path([Vector2i(55, 1), Vector2i(55, 39), Vector2i(55, 76)])
	_path([Vector2i(3, 39), Vector2i(55, 39), Vector2i(106, 39)])
	_building("house_a", 24, 22, 6)
	_building("house_b", 36, 20, 7)
	_building("house_f", 66, 20, 5)
	_building("house_c", 76, 22, 8)
	_building("house_d", 26, 58, 6)
	_building("house_e", 44, 61, 9)
	_building("house_b", 66, 58, 7)
	_prop("stall_a", Vector2(38, 34), 1.0, "OasisStall1")
	_prop("stall_b", Vector2(72, 34), 1.0, "OasisStall2")
	_prop("stall_c", Vector2(38, 46), 1.0, "OasisStall3")
	_prop("stall_d", Vector2(72, 46), 1.0, "OasisStall4")
	for i in 14:
		_prop("palm_tree", Vector2(_rng.randi_range(34, 76), _rng.randi_range(26, 52)), _rng.randf_range(0.85, 1.05))
	for i in 8:
		_prop("cactus", Vector2(_rng.randi_range(3, 106), _rng.randi_range(3, 76)), 0.9)
	_label("SUNWELL OASIS — Thị Trấn Ốc Đảo", Vector2(55, 12), 26)
	_herb(Vector2(30, 48))
	_herb(Vector2(80, 50))
	_enemy("sand_snake.tscn", Vector2(24, 66))
	_enemy("sand_snake.tscn", Vector2(86, 63))
	_enemy("sand_snake.tscn", Vector2(38, 70))
	_enemy("sand_snake.tscn", Vector2(72, 70))
	_enemy("sand_scorpion.tscn", Vector2(16, 56))
	_enemy("sand_scorpion.tscn", Vector2(94, 56))
	_enemy("sand_vulture.tscn", Vector2(14, 30))
	_enemy("sand_vulture.tscn", Vector2(96, 30))
	_npc("NPC_HuongDan", "huong_dao_oc_dao", "Hướng Dẫn Caravan", Vector2(49, 34),
		Color(1.0, 0.88, 0.68), ["tay_01_den_solmaris"],
		{"before": ["Caravan qua được Westgate là nhờ ngươi dọn bọ cạp đấy. Diệt đủ 4 con Bọ Cạp Cát quanh cổng và Dunefield rồi quay lại đây.",
			"Solmaris không có vua đâu — vua chết lâu rồi. Hội đồng lính đánh thuê nói thay ngai trống, còn ai thật sự giữ vùng này thì ngươi sẽ tự thấy."],
		 "active": ["Bọ cạp nấp ở mép đụn quanh Westgate và phía tây Dunefield. Nghe cát sủi là lùi ngay."],
		 "ready": ["Đường caravan sạch rồi! Sunwell Oasis mở nước đón ngươi."],
		 "done": ["Muốn đi tiếp thì giữ nước cho ốc đảo trước. Ở sa mạc, liên minh bắt đầu bằng một ngụm nước chia đúng người."]},
		[[49, 34, "idle", 5], [55, 35, "walk", 5], [55, 35, "work", 8], [42, 42, "walk", 5], [42, 42, "idle", 5], [49, 34, "walk", 5]])
	_npc("NPC_GiuNuoc", "nguoi_giu_nuoc", "Người Giữ Nước Sunwell", Vector2(63, 44),
		Color(0.65, 0.9, 1.0), ["tay_02_nuoc_oc_dao", "tay_side_vulture"],
		{"before": ["Rắn Cát chui vào mạch ngầm rồi. Diệt 4 con quanh ốc đảo và Dunefield, nước mới trong lại.",
			"Kền kền rình caravan cũng là việc của ta phải nhờ ngươi sau này."],
		 "active": ["Rắn hay nằm ở bờ nam ốc đảo và các hốc cát Dunefield. Đừng đứng yên trên cát mềm."],
		 "ready": ["Nước trong lại rồi! Cả thị trấn này nhớ ơn ngươi."],
		 "done": ["Hội đồng giữ tháp nước ở Solmaris, nhưng mạch nước này là của dân. Nhớ lấy khác biệt đó khi ngươi gặp họ."]},
		[[63, 44, "work", 9], [48, 44, "walk", 5], [48, 44, "work", 8], [63, 44, "walk", 5]], "res://assets/sprites/nong_dan_frames.tres")
	_npc("NPC_TruongLienMinh", "truong_lien_minh", "Trưởng Liên Minh Sa Mạc", Vector2(55, 31),
		Color(0.95, 0.78, 0.55), ["tay_04_lien_minh", "tay_07a_danh_vesskar", "tay_07b_dam_phan_vesskar"],
		{"before": ["Ta không có ngai, không có quân thường trực. Ta chỉ có lời của hai bộ lạc — nếu ngươi lấy được cả hai.",
			"Diều Cát cần thấy ngươi dọn lính đào ngũ. Đá Vang cần bằng chứng lời thề trong tàn tích. Xong cả hai, quay lại đây đốt lửa liên minh."],
		 "active": ["Lửa liên minh chưa đốt được khi mới có một nửa sa mạc đứng sau ngươi."],
		 "ready": ["Ngươi đã thấy Vesskar và vẫn quay lại hỏi ý liên minh. Vậy lựa chọn là của ngươi: giết kẻ canh cổng, hay trả lại lời thề cho nó?"],
		 "done": ["Chìa Vảy Cát đã về tay ngươi. Dù Vesskar sống hay chết, Solmaris từ hôm nay không còn quỳ trước hội đồng nữa."]},
		[[55, 31, "idle", 7], [46, 36, "walk", 5], [46, 36, "idle", 6], [64, 36, "walk", 5], [64, 36, "idle", 6], [55, 31, "walk", 5]])
	_npc("NPC_ThuongNhanOasis", "thuong_nhan_oc_dao", "Thương Nhân Ốc Đảo", Vector2(40, 43),
		Color(1.0, 0.8, 0.6), [],
		{"done": ["Ta bán nước, da, vảy và tin đồn — thứ nào cũng đắt hơn khi caravan trễ.",
			"Kassia Vane chưa từng thua trong đấu trường. Cũng chưa ai đánh với cô ta mà có hai bộ lạc đứng xem cả."]},
		[[40, 43, "work", 10], [70, 43, "walk", 6], [70, 43, "work", 9], [40, 43, "walk", 6]])
	_npc("NPC_LinhThueOasis", "linh_thue_oc_dao", "Lính Đánh Thuê Gác Ốc Đảo", Vector2(76, 36),
		Color(0.85, 0.55, 0.45), [],
		{"done": ["Ta ăn lương hội đồng, nhưng ta uống nước của thị trấn này. Hai câu đó dạo này khó đứng cạnh nhau lắm.",
			"Đấu trường ở Redrock Canyon. Nếu ngươi thắng Kassia trước mặt dân, bọn ta sẽ phải tự hỏi mình đang gác cho ai."]},
		[[76, 36, "idle", 5], [88, 39, "walk", 6], [88, 39, "idle", 5], [55, 48, "walk", 6], [55, 48, "idle", 5], [76, 36, "walk", 6]])
	_spawn("start", Vector2(55, 4))
	_spawn("from_westgate", Vector2(55, 4))
	_spawn("from_dunefield", Vector2(6, 39))
	_spawn("from_northgate", Vector2(6, 20))
	_portal("PortalNorth", Vector2(55, 2), "res://maps/westgate.tscn", "from_oasis", "Westgate")
	_portal("PortalEast", Vector2(107, 39), "res://maps/dunefield.tscn", "from_oasis", "Dunefield")
	_portal("PortalNorthgate", Vector2(3, 20), "res://maps/northgate.tscn", "from_oasis", "Northgate — Caravan Đi Bắc", "tay_giai_phong", "Caravan đi Bắc chỉ chạy khi Solmaris đã được giải phóng (hoàn thành Phần 3).")
	_craft_station(Vector2(59, 38), "Lò Rèn Ốc Đảo Sunwell")
	_finish("res://maps/sunwell_oasis.tscn", Vector2(55, 4))


# ---------------- DUNEFIELD (150x105) — biển cát ----------------

func _build_dunefield() -> void:
	_new_map("Dunefield", 150, 105)
	_fill("sand")
	for p in [[30, 26, 24, 14], [76, 20, 26, 13], [118, 34, 22, 15], [44, 76, 26, 14], [104, 78, 28, 15], [76, 56, 20, 12]]:
		_patch(p[0], p[1], p[2], p[3], "dune")
	for p in [[58, 42, 13, 8], [96, 60, 14, 8], [24, 58, 12, 8]]:
		_patch(p[0], p[1], p[2], p[3], "bone")
	_water_blob(132, 88, 7, 4, true)
	_path([Vector2i(3, 52), Vector2i(74, 52), Vector2i(146, 52)])
	_path([Vector2i(74, 52), Vector2i(74, 4)])
	for i in 24:
		_prop("cactus", Vector2(_rng.randi_range(4, 145), _rng.randi_range(4, 100)), _rng.randf_range(0.75, 1.15))
	for i in 7:
		_prop("bone_rib", Vector2(_rng.randi_range(12, 138), _rng.randi_range(10, 94)), _rng.randf_range(0.8, 1.1))
	for i in 6:
		_prop("palm_tree", Vector2(_rng.randi_range(122, 143), _rng.randi_range(78, 98)), 0.9)
	_label("DUNEFIELD — Biển Cát Và Xương Khô", Vector2(75, 47), 26)
	_herb(Vector2(34, 48))
	_herb(Vector2(116, 56))
	# cụm farm phía tây (Q1-Q2)
	_enemy("sand_scorpion.tscn", Vector2(26, 42))
	_enemy("sand_scorpion.tscn", Vector2(34, 62))
	_enemy("sand_scorpion.tscn", Vector2(48, 36))
	_enemy("sand_snake.tscn", Vector2(22, 68))
	_enemy("sand_snake.tscn", Vector2(44, 70))
	_enemy("sand_vulture.tscn", Vector2(30, 24))
	# cụm giữa
	_enemy("sand_scorpion.tscn", Vector2(68, 44))
	_enemy("sand_snake.tscn", Vector2(80, 62))
	_enemy("sand_vulture.tscn", Vector2(74, 28))
	_enemy("dry_bones.tscn", Vector2(58, 78))
	_enemy("dry_bones.tscn", Vector2(96, 42))
	_enemy("mercenary.tscn", Vector2(84, 50))
	# cụm đông + golem elite
	_enemy("sand_scorpion.tscn", Vector2(118, 44))
	_enemy("sand_snake.tscn", Vector2(126, 62))
	_enemy("sand_vulture.tscn", Vector2(132, 30))
	_enemy("dry_bones.tscn", Vector2(108, 78))
	_enemy("sand_golem.tscn", Vector2(122, 82))
	_enemy("sand_golem.tscn", Vector2(64, 18), true)
	_npc("NPC_TrinhSat", "trinh_sat_caravan", "Trinh Sát Caravan", Vector2(74, 48),
		Color(0.95, 0.85, 0.65), [],
		{"done": ["Diều Cát ở phía bắc — họ nhìn một người qua cách người đó đối xử với kẻ đào ngũ.",
			"Redrock Canyon ở phía đông. Nghe tiếng trống đấu trường là biết ngươi tới gần hội đồng rồi."]},
		[[74, 48, "idle", 6], [58, 52, "walk", 5], [58, 52, "idle", 5], [90, 52, "walk", 5], [90, 52, "idle", 5], [74, 48, "walk", 5]])
	_spawn("start", Vector2(5, 52))
	_spawn("from_oasis", Vector2(5, 52))
	_spawn("from_dunehawk", Vector2(74, 6))
	_spawn("from_canyon", Vector2(145, 52))
	_portal("PortalWest", Vector2(3, 52), "res://maps/sunwell_oasis.tscn", "from_dunefield", "Sunwell Oasis")
	_portal("PortalNorth", Vector2(74, 3), "res://maps/dunehawk_camp.tscn", "from_dunefield", "Dunehawk Camp")
	_portal("PortalEast", Vector2(146, 52), "res://maps/redrock_canyon.tscn", "from_dunefield", "Redrock Canyon")
	_finish("res://maps/dunefield.tscn", Vector2(5, 52))


# ---------------- DUNEHAWK CAMP (100x75) — trại bộ lạc 1 ----------------

func _build_dunehawk() -> void:
	_new_map("DunehawkCamp", 100, 75)
	_fill("sand")
	_patch(20, 18, 18, 10, "dune")
	_patch(82, 58, 14, 8, "bone")
	_water_blob(84, 16, 6, 4, true)
	_path([Vector2i(50, 72), Vector2i(50, 40)])
	_path([Vector2i(18, 40), Vector2i(82, 40)])
	_tent(Vector2(28, 28))
	_tent(Vector2(42, 24))
	_tent(Vector2(66, 26))
	_tent(Vector2(76, 42))
	_tent(Vector2(30, 50))
	_prop("campfire", Vector2(50, 38), 1.0, "DunehawkFire")
	_prop("statue", Vector2(56, 34), 0.8, "DunehawkTotem")
	for i in 8:
		_prop("palm_tree", Vector2(_rng.randi_range(74, 94), _rng.randi_range(8, 26)), 0.9)
	for i in 8:
		_prop("cactus", Vector2(_rng.randi_range(3, 96), _rng.randi_range(3, 71)), 0.9)
	_label("DUNEHAWK CAMP — Bộ Lạc Diều Cát (tên đề xuất)", Vector2(50, 10), 24)
	_enemy("sand_vulture.tscn", Vector2(20, 62))
	_enemy("sand_vulture.tscn", Vector2(80, 64))
	_enemy("sand_scorpion.tscn", Vector2(36, 66))
	_enemy("sand_scorpion.tscn", Vector2(64, 66))
	_enemy("sand_snake.tscn", Vector2(50, 60))
	_npc("NPC_ThuLinhDieuCat", "thu_linh_dieu_cat", "Thủ Lĩnh Bộ Lạc Diều Cát", Vector2(54, 36),
		Color(1.0, 0.72, 0.48), ["tay_03a_dieu_cat"],
		{"before": ["Diều Cát không bán lòng trung thành. Có năm tên lính đánh thuê đào ngũ cướp đoàn săn của ta ở Redrock Canyon — dọn chúng, rồi hãy nói chuyện liên minh.",
			"Đừng giết vì giận. Giết để sa mạc biết từ nay ai cướp của bộ lạc cũng phải trả."],
		 "active": ["Năm tên đào ngũ vẫn giữ khiên hội đồng ở Redrock Canyon. Lính Đánh Thuê thường cũng được tính là đồng bọn của chúng trong mắt bộ lạc."],
		 "ready": ["Cát đã kể lại việc ngươi làm. Diều Cát đứng cùng liên minh."],
		 "done": ["Khi trống đấu trường nổi lên, đàn diều của ta sẽ bay trên Redrock. Kassia sẽ thấy khán giả hôm đó không còn của riêng hội đồng."]},
		[[54, 36, "idle", 7], [44, 38, "walk", 5], [44, 38, "work", 8], [54, 36, "walk", 5]])
	_npc("NPC_KeChuyenDieuCat", "ke_chuyen_dieu_cat", "Người Kể Chuyện Diều Cát", Vector2(47, 41),
		Color(0.9, 0.82, 0.62), [],
		{"done": ["Ngày xưa Vesskar không ăn thịt người qua đường. Nó chỉ thổi bay những kẻ phá lời thề ở cổng phong ấn.",
			"Người già nói nó bị trói, không phải bị thuần hóa. Khác nhau xa lắm, khách lạ."]},
		[[47, 41, "work", 10], [58, 41, "walk", 5], [58, 41, "idle", 7], [47, 41, "walk", 5]])
	_spawn("start", Vector2(50, 69))
	_spawn("from_dunefield", Vector2(50, 69))
	_portal("PortalSouth", Vector2(50, 72), "res://maps/dunefield.tscn", "from_dunehawk", "Dunefield")
	_finish("res://maps/dunehawk_camp.tscn", Vector2(50, 69))


# ---------------- REDROCK CANYON (140x100) — hẻm núi + đấu trường ----------------

func _build_canyon() -> void:
	_new_map("RedrockCanyon", 140, 100)
	_fill("rocky")
	_patch(24, 22, 18, 10, "bone")
	_patch(116, 78, 18, 10, "dune")
	# vách hẻm núi chừa khe đi
	_rock_wall(8, 24, 58, 26, [Vector2i(38, 25), Vector2i(39, 25)])
	_rock_wall(76, 24, 132, 26, [Vector2i(98, 25), Vector2i(99, 25)])
	_rock_wall(8, 72, 58, 74, [Vector2i(30, 73), Vector2i(31, 73)])
	_rock_wall(76, 72, 132, 74, [Vector2i(112, 73), Vector2i(113, 73)])
	_path([Vector2i(3, 50), Vector2i(58, 50)])
	_path([Vector2i(82, 50), Vector2i(136, 50)])
	_path([Vector2i(70, 64), Vector2i(70, 96)])
	# ĐẤU TRƯỜNG: sàn đá + vành tường, cửa nam
	_stone_rect(56, 34, 84, 64, "floor")
	for c in range(56, 85):
		for r in [34, 64]:
			_tm2.set_cell(0, Vector2i(c, r), 0, STONE["wall"])
			_mark(c, r)
	for r in range(34, 65):
		for c in [56, 84]:
			_tm2.set_cell(0, Vector2i(c, r), 0, STONE["wall"])
			_mark(c, r)
	for dc in [69, 70, 71]:
		_tm2.set_cell(0, Vector2i(dc, 64), 0, STONE["floor"])
		_unmark(dc, 64)
	_label("REDROCK CANYON — Đấu Trường Hội Đồng", Vector2(70, 28), 26)
	_label("ĐẤU TRƯỜNG KASSIA VANE", Vector2(70, 38), 22)
	for i in 14:
		_prop("boulder", Vector2(_rng.randi_range(4, 135), _rng.randi_range(4, 95)), _rng.randf_range(0.7, 1.1))
	for i in 8:
		_prop("cactus", Vector2(_rng.randi_range(4, 135), _rng.randi_range(4, 95)), 0.9)
	_herb(Vector2(20, 46))
	_herb(Vector2(120, 54))
	# lính đánh thuê: điều kiện Q3A + lính gác canyon
	_enemy("mercenary.tscn", Vector2(24, 42))
	_enemy("mercenary.tscn", Vector2(34, 58))
	_enemy("mercenary.tscn", Vector2(104, 42))
	_enemy("mercenary.tscn", Vector2(114, 58))
	_enemy("mercenary.tscn", Vector2(70, 20))
	_enemy("mercenary.tscn", Vector2(18, 82))
	_enemy("mercenary.tscn", Vector2(122, 82))
	_enemy("sand_scorpion.tscn", Vector2(16, 34))
	_enemy("sand_scorpion.tscn", Vector2(124, 34))
	_enemy("sand_snake.tscn", Vector2(44, 84))
	_enemy("sand_snake.tscn", Vector2(96, 84))
	_enemy("sand_golem.tscn", Vector2(48, 18))
	_enemy("sand_golem.tscn", Vector2(92, 18))
	_enemy("boss_mercenary_captain.tscn", Vector2(70, 46), false, 0.0)
	_npc("NPC_ChuDauTruong", "chu_dau_truong", "Chủ Đấu Trường Redrock", Vector2(70, 68),
		Color(1.0, 0.66, 0.42), ["tay_05_dau_truong"],
		{"before": ["Đấu trường này chỉ mở cho kẻ có liên minh đứng sau. Kassia Vane không đánh với kẻ vô danh không ai chứng kiến.",
			"Khi hai bộ lạc đã gật đầu, quay lại đây. Ta sẽ mở cổng cát."],
		 "active": ["Kassia đang ở giữa đấu trường. Khiên của cô ta chỉ sợ đòn từ sau lưng — và sợ khán giả quay lưng còn hơn."],
		 "ready": ["Cô ta gục rồi... Hội đồng mất đấu trường, mất mặt, và sắp mất cả Solmaris."],
		 "done": ["Ta bán vé cả đời, chưa thấy ngày nào khán giả đứng dậy vì một kẻ ngoài vùng như hôm nay."]},
		[[70, 68, "idle", 6], [62, 68, "walk", 5], [62, 68, "work", 8], [78, 68, "walk", 5], [78, 68, "idle", 6], [70, 68, "walk", 5]])
	_spawn("start", Vector2(5, 50))
	_spawn("from_dunefield", Vector2(5, 50))
	_spawn("from_stonesong", Vector2(70, 94))
	_spawn("from_ruins", Vector2(135, 50))
	_portal("PortalWest", Vector2(3, 50), "res://maps/dunefield.tscn", "from_canyon", "Dunefield")
	_portal("PortalSouth", Vector2(70, 96), "res://maps/stonesong_camp.tscn", "from_canyon", "Stonesong Camp")
	_portal("PortalEast", Vector2(136, 50), "res://maps/buried_sand_ruins.tscn", "from_canyon", "Buried Sand Ruins")
	_finish("res://maps/redrock_canyon.tscn", Vector2(5, 50))


# ---------------- STONESONG CAMP (100x75) — trại bộ lạc 2 ----------------

func _build_stonesong() -> void:
	_new_map("StonesongCamp", 100, 75)
	_fill("rocky")
	_patch(22, 58, 16, 9, "bone")
	_patch(80, 20, 15, 9, "dune")
	_water_blob(16, 16, 6, 4, true)
	_path([Vector2i(50, 3), Vector2i(50, 38)])
	_path([Vector2i(20, 38), Vector2i(80, 38)])
	_tent(Vector2(30, 28))
	_tent(Vector2(44, 24))
	_tent(Vector2(64, 26))
	_tent(Vector2(74, 44))
	_tent(Vector2(28, 50))
	_prop("campfire", Vector2(50, 38), 1.0, "StonesongFire")
	_prop("statue", Vector2(56, 34), 0.85, "StonesongTotem")
	for i in 10:
		_prop("boulder", Vector2(_rng.randi_range(4, 95), _rng.randi_range(4, 70)), _rng.randf_range(0.6, 1.0))
	_label("STONESONG CAMP — Bộ Lạc Đá Vang (tên đề xuất)", Vector2(50, 10), 24)
	_enemy("dry_bones.tscn", Vector2(22, 62))
	_enemy("dry_bones.tscn", Vector2(38, 66))
	_enemy("dry_bones.tscn", Vector2(62, 66))
	_enemy("dry_bones.tscn", Vector2(78, 62))
	_enemy("sand_golem.tscn", Vector2(50, 58))
	_enemy("sand_scorpion.tscn", Vector2(14, 46))
	_npc("NPC_PhapSuDaVang", "phap_su_da_vang", "Pháp Sư Bộ Lạc Đá Vang", Vector2(54, 36),
		Color(0.78, 0.7, 1.0), ["tay_03b_da_vang", "tay_side_bones"],
		{"before": ["Đá Vang không tin lời hứa. Vào Buried Sand Ruins ở phía đông Redrock Canyon, đứng trước bia lời thề trong đền cát — rồi quay lại, mắt ngươi sẽ tự nói thật hay giả.",
			"Xương khô quanh trại cũng đang nghe tiếng cổng phong ấn yếu đi. Dọn chúng nếu ngươi muốn giúp thêm."],
		 "active": ["Tàn tích ở phía đông hẻm núi. Phòng đền ở phía bắc tàn tích — nơi Vesskar từng quỳ xuống thề."],
		 "ready": ["Ngươi đã đứng trước bia lời thề. Đá trong xương ta nghe thấy điều đó. Đá Vang gia nhập liên minh."],
		 "done": ["Lời thề của Vesskar không phải xiềng xích của hội đồng. Nó là giao ước canh cổng — và giao ước thì có thể trả, không nhất thiết phải giết người giữ."]},
		[[54, 36, "work", 9], [44, 38, "walk", 5], [44, 38, "idle", 6], [54, 36, "walk", 5]], "res://assets/sprites/linh_tuan_frames.tres")
	_npc("NPC_KeChuyenDaVang", "ke_chuyen_da_vang", "Người Kể Chuyện Đá Vang", Vector2(47, 41),
		Color(0.88, 0.8, 0.66), [],
		{"done": ["Hội đồng nói Vesskar là quái vật ăn caravan. Nhưng tổ tiên ta chôn cùng bia đá nói khác: nó canh cổng, và kẻ phá thề mới là kẻ đáng sợ.",
			"Nếu ngươi gặp nó, hãy nhìn vào mắt trước khi rút kiếm."]},
		[[47, 41, "work", 10], [58, 41, "walk", 5], [58, 41, "idle", 7], [47, 41, "walk", 5]])
	_spawn("start", Vector2(50, 5))
	_spawn("from_canyon", Vector2(50, 5))
	_portal("PortalNorth", Vector2(50, 3), "res://maps/redrock_canyon.tscn", "from_stonesong", "Redrock Canyon")
	_finish("res://maps/stonesong_camp.tscn", Vector2(50, 5))


# ---------------- BURIED SAND RUINS (150x100) — dungeon nhiều phòng ----------------

func _build_ruins() -> void:
	_new_map("BuriedSandRuins", 150, 100)
	_fill("cracked")
	_stone_rect(0, 0, 149, 99, "floor")
	# Sảnh vào (nam-tây)
	_stone_room(8, 62, 45, 92, [Vector2i(45, 76), Vector2i(26, 62)])
	# Hành lang kho (nam-giữa)
	_stone_room(46, 58, 78, 92, [Vector2i(46, 76), Vector2i(78, 76), Vector2i(62, 58)])
	# Kho phía đông-nam
	_stone_room(79, 58, 112, 92, [Vector2i(79, 76), Vector2i(96, 58)])
	# Sảnh trung tâm
	_stone_room(55, 30, 95, 57, [Vector2i(62, 57), Vector2i(96 - 1, 44), Vector2i(75, 30)])
	# Thư viện phía tây
	_stone_room(10, 25, 45, 57, [Vector2i(45, 44), Vector2i(26, 57)])
	# Kho báu phía đông-bắc
	_stone_room(96, 25, 140, 57, [Vector2i(96, 44), Vector2i(118, 57)])
	# Đền lời thề phía bắc-giữa (Q3B + đường lên hang)
	_stone_room(60, 5, 90, 29, [Vector2i(75, 29)])
	for i in 10:
		_prop("bone_rib", Vector2(_rng.randi_range(12, 138), _rng.randi_range(8, 92)), _rng.randf_range(0.7, 1.0))
	for i in 8:
		_prop("boulder", Vector2(_rng.randi_range(12, 138), _rng.randi_range(8, 92)), _rng.randf_range(0.6, 0.95))
	_prop("campfire", Vector2(75, 16), 0.8, "OathShrineGlow")
	_label("BURIED SAND RUINS — Tàn Tích Cổ Chôn Trong Cát", Vector2(75, 88), 24)
	_label("ĐỀN LỜI THỀ CỦA VESSKAR — HÃY ĐỨNG TRƯỚC BIA NÀY", Vector2(75, 10), 22)
	_herb(Vector2(20, 84))
	_herb(Vector2(104, 84))
	_enemy("dry_bones.tscn", Vector2(24, 76))
	_enemy("dry_bones.tscn", Vector2(62, 76))
	_enemy("dry_bones.tscn", Vector2(96, 76))
	_enemy("dry_bones.tscn", Vector2(28, 40))
	_enemy("mercenary.tscn", Vector2(36, 70))
	_enemy("mercenary.tscn", Vector2(70, 84))
	_enemy("mercenary.tscn", Vector2(104, 66))
	_enemy("mercenary.tscn", Vector2(118, 40))
	_enemy("sand_scorpion.tscn", Vector2(16, 84))
	_enemy("sand_scorpion.tscn", Vector2(86, 84))
	_enemy("sand_snake.tscn", Vector2(52, 66))
	_enemy("sand_snake.tscn", Vector2(128, 50))
	_enemy("sand_golem.tscn", Vector2(75, 44))
	_enemy("sand_golem.tscn", Vector2(118, 32), true)
	_enemy("dry_bones.tscn", Vector2(75, 20))
	_spawn("start", Vector2(14, 88))
	_spawn("from_canyon", Vector2(14, 88))
	_spawn("from_lair", Vector2(75, 8))
	_portal("PortalEntry", Vector2(12, 90), "res://maps/redrock_canyon.tscn", "from_ruins", "Redrock Canyon")
	_portal("PortalNorth", Vector2(75, 6), "res://maps/vesskar_lair.tscn", "from_ruins", "Vesskar's Lair")
	_finish("res://maps/buried_sand_ruins.tscn", Vector2(14, 88))


# ---------------- VESSKAR'S LAIR (120x85) — hang rồng ----------------

func _build_lair() -> void:
	_new_map("VesskarLair", 120, 85)
	_fill("rocky")
	for p in [[24, 22, 18, 11], [94, 24, 18, 11], [28, 64, 20, 11], [92, 64, 20, 11]]:
		_patch(p[0], p[1], p[2], p[3], "bone")
	# vành hang: tường đá/brick ôm miệng hang, chừa cửa nam và đường bắc đi thành
	_rock_wall(8, 8, 112, 10, [Vector2i(60, 9), Vector2i(61, 9)])
	_rock_wall(8, 74, 112, 76, [Vector2i(59, 75), Vector2i(60, 75), Vector2i(61, 75)])
	_rock_wall(8, 8, 10, 76, [Vector2i(9, 42), Vector2i(9, 43)])
	_rock_wall(110, 8, 112, 76, [Vector2i(111, 42), Vector2i(111, 43)])
	_path([Vector2i(60, 80), Vector2i(60, 48)])
	_path([Vector2i(24, 42), Vector2i(96, 42)])
	for i in 10:
		_prop("bone_rib", Vector2(_rng.randi_range(14, 106), _rng.randi_range(14, 70)), _rng.randf_range(0.8, 1.15))
	for i in 8:
		_prop("boulder", Vector2(_rng.randi_range(14, 106), _rng.randi_range(14, 70)), _rng.randf_range(0.7, 1.05))
	_prop("campfire", Vector2(52, 70), 0.8, "LairOathFire")
	_label("VESSKAR'S LAIR — Hang Rồng Cát", Vector2(60, 16), 28)
	_label("Vesskar canh cổng phong ấn. Giết nó, hoặc trả lại lời thề cho nó.", Vector2(60, 52), 22)
	_enemy("sand_golem.tscn", Vector2(34, 34))
	_enemy("sand_golem.tscn", Vector2(86, 34))
	_enemy("sand_scorpion.tscn", Vector2(26, 52))
	_enemy("sand_scorpion.tscn", Vector2(94, 52))
	_enemy("sand_vulture.tscn", Vector2(44, 24))
	_enemy("sand_vulture.tscn", Vector2(76, 24))
	_enemy("boss_vesskar.tscn", Vector2(60, 36), false, 0.0)
	_npc("NPC_GiuLoiThe", "nguoi_giu_loi_the", "Người Giữ Lời Thề", Vector2(66, 72),
		Color(0.82, 0.76, 1.0), [],
		{"done": ["Ta chép lời thề này từ bia trong tàn tích mỗi mùa cát. Vesskar thề canh cổng, không thề phục vụ hội đồng.",
			"Trưởng Liên Minh có cả hai con đường. Nếu ngươi chọn lời nói thay vì kiếm, quay lại Sunwell và chọn đàm phán — Vesskar sẽ nghe thấy qua cát."]},
		[[66, 72, "work", 9], [54, 72, "walk", 5], [54, 72, "idle", 6], [66, 72, "walk", 5]], "res://assets/sprites/linh_tuan_frames.tres")
	_spawn("start", Vector2(60, 78))
	_spawn("from_ruins", Vector2(60, 78))
	_spawn("from_lair", Vector2(60, 6))
	_portal("PortalSouth", Vector2(60, 80), "res://maps/buried_sand_ruins.tscn", "from_lair", "Buried Sand Ruins")
	_portal("PortalCity", Vector2(60, 4), "res://maps/vesskar_lair.tscn", "from_lair",
		"Đường Vào Thành Solmaris (chưa dựng)", "thanh_solmaris_mo",
		"Đường vào thành Solmaris khóa — nội thành chưa dựng, layout đang chờ user duyệt.")
	_finish("res://maps/vesskar_lair.tscn", Vector2(60, 78))
