extends Node2D
## Tool một lần (đợt 6 — ĐỢT CUỐI): dựng ĐẤT CHẾT + tháp SIGILSPIRE
## (8 map) theo design/world_v2_4_thanh.md mục 3 + sơ đồ
## design/sigilspire_so_do.md:
##   dat_chet (100x75) -> sigilspire_base T0 (80x60) -> sigilspire_f1
##   Tầng 1-2 (90x65, mini-boss Hồi Âm Của Morvain) -> sigilspire_f2
##   Tầng 3-4 (90x65, Hồi Âm Của Hiệp Sĩ Đen) -> sigilspire_f5 Tầng 5
##   Sử Ấn (70x55) -> sigilspire_f6 Tầng 6 Seraphine (70x55) ->
##   sigilspire_summit Tầng 7 Đỉnh (90x65, boss cuối + Bệ Phong Ấn).
## Cổng vào tháp khóa flag "sigilspire_open" (đủ 4 seal key).
## Chạy: godot --headless --path game res://tools_paint/paint_sigilspire.tscn

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
var _open := {}
var _fail := false


func _ready() -> void:
	_rng.seed = 251725
	_build_dat_chet()
	_build_base()
	_build_f1()
	_build_f2()
	_build_f5()
	_build_f6()
	_build_summit()
	print("[SIGILSPIRE] ====== HOAN TAT, fail=", _fail)
	get_tree().quit(1 if _fail else 0)


func _new_map(map_name: String, w: int, h: int) -> void:
	_w = w
	_h = h
	_origin = Vector2(-w * TILE / 2.0, -h * TILE / 2.0)
	_solid.clear()
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


func _fill(mode: String = "ash") -> void:
	for c in _w:
		for r in _h:
			var roll := _rng.randf()
			var tt := "ash_snow"
			if mode == "ash":
				tt = "ash_snow" if roll < 0.58 else ("snow" if roll < 0.86 else ("rocky_snow" if roll < 0.96 else "dead_scrub"))
			elif mode == "dark":
				tt = "dark_brick" if roll < 0.8 else ("stone_floor" if roll < 0.94 else "rocky_snow")
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


func signi(v: int) -> int:
	return 0 if v == 0 else (1 if v > 0 else -1)


func _path_line(c0: int, r0: int, c1: int, r1: int) -> void:
	var dc := signi(c1 - c0)
	var dr := signi(r1 - r0)
	var c := c0
	var r := r0
	while true:
		for o in [0, 1]:
			var cc2: int = c + (o if dc == 0 else 0)
			var rr2: int = r + (o if dr == 0 else 0)
			_paint(cc2, rr2, "packed_snow" if _rng.randf() < 0.8 else "path_s")
			_unmark(cc2, rr2)
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


func _prop(tex_name: String, cell: Vector2, scl: float = 1.0, node_name: String = "") -> Node2D:
	var holder := Node2D.new()
	holder.position = _cc(cell.x, cell.y)
	holder.y_sort_enabled = true
	holder.name = node_name if node_name != "" else ("Prop_" + tex_name)
	var tex: Texture2D = load("res://assets/props/" + tex_name + ".png")
	if tex == null:
		print("[SIGILSPIRE] LOI texture: ", tex_name)
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


func _label(text: String, cell: Vector2, size: int = 22) -> void:
	var lb := Label.new()
	lb.text = text
	lb.position = _cc(cell.x, cell.y) + Vector2(-260, -16)
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", Color(0.93, 0.9, 1.0))
	lb.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
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


func _enemy(scene_file: String, cell: Vector2, elite: bool = false, respawn: float = 45.0) -> Node:
	var ps: PackedScene = load("res://enemies/" + scene_file)
	if ps == null:
		print("[SIGILSPIRE] LOI scene quai: ", scene_file)
		_fail = true
		return null
	var e: Node = ps.instantiate()
	e.position = _cc(cell.x, cell.y)
	if elite:
		e.set("is_elite", true)
	if respawn > 0.0 and not scene_file.begins_with("boss"):
		e.set("respawn_time", respawn)
	_root.add_child(e)
	e.owner = _root
	return e


## Mini-boss Hồi Âm: ghi đè tên/tint/HP TRƯỚC khi add_child (như khuôn
## remembering của builder Frostgard) để _ready dùng đúng số liệu tầng.
func _boss_echo(cell: Vector2, display: String, tint: Color, hp: int) -> void:
	var ps: PackedScene = load("res://enemies/boss_echo.tscn")
	var e: Node = ps.instantiate()
	e.position = _cc(cell.x, cell.y)
	e.set("display_name", display)
	e.set("sprite_modulate", tint)
	e.set("max_hp", hp)
	_root.add_child(e)
	e.owner = _root


func _herb(cell: Vector2) -> void:
	var ps: PackedScene = load("res://systems/herb_pickup.tscn")
	var hnode: Node = ps.instantiate()
	hnode.position = _cc(cell.x, cell.y)
	_root.add_child(hnode)
	hnode.owner = _root


func _craft_station(cell: Vector2, station_name: String = "Bàn Chế Tạo") -> void:
	var ps: PackedScene = load("res://systems/craft_station.tscn")
	var n: Node = ps.instantiate()
	n.name = "CraftStation"
	n.position = _cc(cell.x, cell.y)
	n.set("station_name", station_name)
	_root.add_child(n)
	n.owner = _root


func _seal_altar(cell: Vector2) -> void:
	var ps: PackedScene = load("res://systems/seal_altar.tscn")
	var n: Node = ps.instantiate()
	n.name = "SealAltar"
	n.position = _cc(cell.x, cell.y)
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
		print("[SIGILSPIRE] PACK LOI ", save_path, ": ", err)
		_fail = true
		return
	err = ResourceSaver.save(packed, save_path)
	print("[SIGILSPIRE] saved ", save_path, " err=", err, " solid=", _solid.size())
	if err != OK:
		_fail = true
	remove_child(_root)
	_root.queue_free()


func _stone_rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_tm2.set_cell(0, Vector2i(c, r), 0, STONE[t])


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


# ---------------- ĐẤT CHẾT TRUNG TÂM (100x75) ----------------

func _build_dat_chet() -> void:
	_new_map("DatChet", 100, 75)
	_fill("ash")
	_patch(20, 20, 14, 9, "rocky_snow")
	_patch(80, 55, 15, 10, "dead_scrub")
	_path([Vector2i(50, 72), Vector2i(50, 40)])
	_path([Vector2i(50, 40), Vector2i(30, 18)])
	_path([Vector2i(50, 40), Vector2i(70, 18)])
	for i in 14:
		_prop("grave_stone", Vector2(_rng.randi_range(6, 93), _rng.randi_range(6, 68)), _rng.randf_range(0.8, 1.0))
	for i in 7:
		_prop("boulder", Vector2(_rng.randi_range(6, 93), _rng.randi_range(6, 68)), _rng.randf_range(0.8, 1.1))
	for i in 6:
		_prop("snow_pine", Vector2(_rng.randi_range(4, 95), _rng.randi_range(4, 70)), _rng.randf_range(0.8, 1.0))
	_prop("statue", Vector2(44, 12), 1.0, "GateStatueL")
	_prop("statue", Vector2(56, 12), 1.0, "GateStatueR")
	_label("ĐẤT CHẾT TRUNG TÂM — nơi bốn vùng đất gặp nhau, và không vùng nào nhận nuôi", Vector2(50, 30), 26)
	_label("CỔNG SIGILSPIRE — chỉ mở khi đủ BỐN CHÌA PHONG ẤN", Vector2(50, 16), 20)
	_label("Trạm Gác Tro — điểm dừng cuối trước tháp", Vector2(30, 14), 18)
	_npc("NPC_TramGacTro", "tram_gac_tro", "Người Gác Trạm Tro", Vector2(30, 20),
		Color(0.75, 0.7, 0.8), [],
		{"before": ["Ta gác trạm này bốn mươi năm. Kẻ lên tháp thì nhiều, kẻ xuống thì... ngươi tự đếm bia đá quanh đây mà hiểu.",
			"Nghe cho kỹ: qua cổng tháp là ĐIỂM KHÔNG QUAY LẠI theo nghĩa đen của nó — không phải vì cổng khóa, mà vì những gì ngươi sắp biết sẽ không cho ngươi quay lại làm người cũ nữa. Chuẩn bị bình máu, chế đồ cho tử tế ở lò rèn kia, rồi hẵng đi."],
		 "active": ["Lò rèn ở trạm vẫn đỏ lửa. Chế lấy ít Đại Bình Hồi Phục trước khi leo tháp — trên đó không có ai bán gì cho ngươi đâu."],
		 "ready": ["Ngươi đã qua cổng rồi à? Tốt. Xuống được tới đây là giỏi hơn khối người."],
		 "done": ["Vương quốc đổi khác rồi, hiệp sĩ. Ngươi chọn kết cục nào... thì kết cục đó cũng đã thành sự thật. Ta gác nốt ca này nữa thôi."]},
		[])
	_craft_station(Vector2(26, 18), "Lò Rèn Trạm Gác Tro")
	_enemy("seal_shade.tscn", Vector2(38, 44))
	_enemy("seal_shade.tscn", Vector2(62, 44))
	_enemy("seal_shade.tscn", Vector2(50, 56))
	_enemy("seal_shade.tscn", Vector2(70, 62))
	_enemy("seal_guard.tscn", Vector2(44, 22))
	_enemy("seal_guard.tscn", Vector2(56, 22))
	_herb(Vector2(20, 60))
	_herb(Vector2(84, 24))
	_spawn("start", Vector2(50, 70))
	_spawn("from_frostgard", Vector2(50, 70))
	_spawn("from_tower", Vector2(50, 12))
	_portal("PortalSouth", Vector2(50, 72), "res://maps/frostgard_approach.tscn", "from_dat_chet", "Frostgard Approach")
	_portal("PortalTower", Vector2(50, 6), "res://maps/sigilspire_base.tscn", "from_dat_chet",
		"Sigilspire — Tầng 0", "sigilspire_open",
		"Cổng Sigilspire còn khóa: cần đủ 4 Chìa Phong Ấn của 4 vùng (Đông/Nam/Tây/Bắc).")
	_finish("res://maps/dat_chet.tscn", Vector2(50, 70))


# ---------------- TẦNG 0 — CỔNG BỐN CHÌA (80x60) ----------------

func _build_base() -> void:
	_new_map("SigilspireBase", 80, 60)
	_fill("dark")
	_stone_room(12, 40, 67, 54, [Vector2i(40, 40)])
	_stone_room(10, 8, 69, 34, [Vector2i(40, 34), Vector2i(40, 8)])
	_prop("banner", Vector2(24, 12), 1.0, "SealBannerL")
	_prop("banner", Vector2(56, 12), 1.0, "SealBannerR")
	_prop("campfire", Vector2(40, 21), 0.9, "SealBrazier")
	_label("SIGILSPIRE — TẦNG 0: CỔNG BỐN CHÌA", Vector2(40, 12), 26)
	_label("Bốn ổ khóa, bốn vùng đất. Ngươi đã mở cả bốn.", Vector2(40, 17), 18)
	_npc("NPC_TiengVuaQuaAn", "tieng_vua_qua_an", "Tiếng Vua Qua Ấn", Vector2(40, 26),
		Color(0.9, 0.8, 0.55), [],
		{"before": ["(Một giọng nói vang ra từ chính những viên đá của tháp — không già, không trẻ, và biết tên ngươi.)",
			"Cuối cùng cũng có một kẻ mang đủ bốn chìa. Ta đã xem ngươi đi qua cả bốn vùng, hiệp sĩ. Ngươi giải phóng giỏi lắm. Giỏi đến mức... ta bắt đầu lo cho kế hoạch của chính mình.",
			"Lên đi. Tầng 6 có người ngươi muốn gặp. Tầng 7 có ta. Giữa hai tầng đó — là toàn bộ sự thật của vương quốc này, xếp theo chiều cao."],
		 "active": ["Đừng dừng ở sảnh. Những thứ canh tháp này không phải người của ta — chúng là của THÁP. Ấn tự vệ đấy."],
		 "ready": ["Ngươi đã biết hết rồi mà vẫn leo tiếp. Tốt. Ta chờ ở đỉnh."],
		 "done": ["..."]},
		[])
	_enemy("seal_guard.tscn", Vector2(28, 20))
	_enemy("seal_guard.tscn", Vector2(52, 20))
	_enemy("seal_guard.tscn", Vector2(40, 37))
	_enemy("seal_guard.tscn", Vector2(18, 47))
	_enemy("seal_shade.tscn", Vector2(60, 47))
	_enemy("seal_shade.tscn", Vector2(34, 28))
	_spawn("from_dat_chet", Vector2(40, 50))
	_spawn("from_f1", Vector2(40, 12))
	_portal("PortalDown", Vector2(40, 52), "res://maps/dat_chet.tscn", "from_tower", "Ra Đất Chết")
	_portal("PortalUp", Vector2(40, 4), "res://maps/sigilspire_f1.tscn", "from_base", "Lên Tầng 1–2 (Ký Ức Đông & Nam)")
	_finish("res://maps/sigilspire_base.tscn", Vector2(40, 50))


# ---------------- TẦNG 1–2 — KÝ ỨC ĐÔNG & NAM (90x65) ----------------

func _build_f1() -> void:
	_new_map("SigilspireF1", 90, 65)
	_fill("dark")
	_stone_room(14, 44, 75, 59, [Vector2i(45, 44)])
	_stone_room(12, 6, 77, 38, [Vector2i(45, 38), Vector2i(45, 6)])
	_prop("banner", Vector2(24, 10), 1.0, "MemoryBannerL")
	_prop("banner", Vector2(66, 10), 1.0, "MemoryBannerR")
	_label("TẦNG 1 — KÝ ỨC ĐÔNG: cánh đồng, trạm thuế, hầm mỏ", Vector2(45, 10), 22)
	_label("TẦNG 2 — KÝ ỨC NAM: đầm lầy, thuốc, và những cái tên trong sổ", Vector2(45, 33), 20)
	_label("Phong ấn NHỚ mọi thứ nó từng giữ. Và nó bắt ký ức phải đánh nhau thay nó.", Vector2(45, 41), 18)
	_boss_echo(Vector2(45, 20), "Hồi Âm Của Morvain", Color(0.62, 0.42, 0.88, 1), 2400)
	_enemy("seal_shade.tscn", Vector2(28, 26))
	_enemy("seal_shade.tscn", Vector2(62, 26))
	_enemy("seal_shade.tscn", Vector2(45, 41))
	_enemy("seal_shade.tscn", Vector2(30, 52))
	_enemy("seal_guard.tscn", Vector2(58, 52))
	_spawn("from_base", Vector2(45, 55))
	_spawn("from_f2", Vector2(45, 10))
	_portal("PortalDown", Vector2(45, 57), "res://maps/sigilspire_base.tscn", "from_f1", "Xuống Tầng 0")
	_portal("PortalUp", Vector2(45, 3), "res://maps/sigilspire_f2.tscn", "from_f1", "Lên Tầng 3–4 (Ký Ức Tây & Bắc)")
	_finish("res://maps/sigilspire_f1.tscn", Vector2(45, 55))


# ---------------- TẦNG 3–4 — KÝ ỨC TÂY & BẮC (90x65) ----------------

func _build_f2() -> void:
	_new_map("SigilspireF2", 90, 65)
	_fill("dark")
	_stone_room(14, 44, 75, 59, [Vector2i(45, 44)])
	_stone_room(12, 6, 77, 38, [Vector2i(45, 38), Vector2i(45, 6)])
	_prop("banner", Vector2(24, 10), 1.0, "MemoryBanner2L")
	_prop("banner", Vector2(66, 10), 1.0, "MemoryBanner2R")
	_label("TẦNG 3 — KÝ ỨC TÂY: cát, bão, và tiếng cánh của Vesskar", Vector2(45, 10), 22)
	_label("TẦNG 4 — KÝ ỨC BẮC: tuyết, chuông câm, và năm cái tên đội trưởng", Vector2(45, 33), 20)
	_label("Ký ức càng gần đỉnh, càng ít giống ký ức — càng giống lời cảnh báo.", Vector2(45, 41), 18)
	_boss_echo(Vector2(45, 20), "Hồi Âm Của Hiệp Sĩ Đen", Color(0.45, 0.56, 0.72, 1), 2800)
	_enemy("seal_shade.tscn", Vector2(30, 30))
	_enemy("seal_shade.tscn", Vector2(60, 30))
	_enemy("seal_shade.tscn", Vector2(45, 41))
	_enemy("seal_guard.tscn", Vector2(26, 20))
	_enemy("seal_guard.tscn", Vector2(64, 20))
	_enemy("seal_guard.tscn", Vector2(52, 52))
	_spawn("from_f1", Vector2(45, 55))
	_spawn("from_f5", Vector2(45, 10))
	_portal("PortalDown", Vector2(45, 57), "res://maps/sigilspire_f1.tscn", "from_f2", "Xuống Tầng 1–2")
	_portal("PortalUp", Vector2(45, 3), "res://maps/sigilspire_f5.tscn", "from_f2", "Lên Tầng 5 (Sử Ấn)")
	_finish("res://maps/sigilspire_f2.tscn", Vector2(45, 55))


# ---------------- TẦNG 5 — SỬ ẤN (70x55) ----------------

func _build_f5() -> void:
	_new_map("SigilspireF5", 70, 55)
	_fill("dark")
	_stone_room(10, 34, 59, 49, [Vector2i(35, 34)])
	_stone_room(8, 6, 61, 28, [Vector2i(35, 28), Vector2i(35, 6)])
	_prop("fireplace", Vector2(35, 10), 1.0, "ArchiveHearth")
	_prop("bench", Vector2(22, 20), 1.0, "ArchiveBenchL")
	_prop("bench", Vector2(48, 20), 1.0, "ArchiveBenchR")
	_prop("barrel", Vector2(14, 24), 1.0, "ScrollBarrel")
	_label("TẦNG 5 — SỬ ẤN: thư viện ghi lại MỌI phong ấn từ đời đầu", Vector2(35, 10), 24)
	_label("Bia đá: 'Phong ấn đầu tiên không giam quái vật. Nó giam một LỜI THỀ.'", Vector2(35, 31), 18)
	_npc("NPC_NguoiGhiAn", "nguoi_ghi_an", "Người Ghi Ấn Cuối Cùng", Vector2(35, 18),
		Color(0.85, 0.8, 0.7), ["thap_02_tang_su_an"],
		{"before": ["Ta là Người Ghi Ấn Cuối Cùng. Việc của ta: ghi lại mọi đời phong ấn, để không đời nào được giả vờ mình là đời đầu tiên.",
			"Nghe cho hết, hiệp sĩ: phong ấn này không giam một con quái vật vô danh. Nó giam THỨ ĐÃ ĂN LỜI THỀ của vương quốc đầu tiên — một thực thể lớn lên bằng từng lời thề bị phản bội. Mỗi vua bù nhìn, mỗi trạm thuế, mỗi liều thuốc bị giấu... đều là thức ăn của nó.",
			"Và người giữ cho nó không tràn ra, suốt bao đời nay, là một VẬT PHONG ẤN SỐNG: một con người làm neo. Đời này, neo đó là Công chúa Seraphine. Cô ấy ở tầng trên. CÒN SỐNG — theo cách mà cái neo còn sống."],
		 "active": ["Lên tầng 6 đi. Nghe chính cô ấy nói, trước khi ngươi quyết định thay cả vương quốc."],
		 "ready": ["Giờ thì ngươi biết hết rồi. Ta ghi vào sử: 'Đời phong ấn này, có một hiệp sĩ leo lên đỉnh tháp với đầy đủ sự thật trong tay — lần đầu tiên.' Lên đi. Đừng để cô ấy chờ thêm một đời nữa."],
		 "done": ["Sử Ấn vẫn đang được viết. Trang cuối cùng... ta để trống cho ngươi."]},
		[])
	_spawn("from_f2", Vector2(35, 44))
	_spawn("from_f6", Vector2(35, 10))
	_portal("PortalDown", Vector2(35, 47), "res://maps/sigilspire_f2.tscn", "from_f5", "Xuống Tầng 3–4")
	_portal("PortalUp", Vector2(35, 3), "res://maps/sigilspire_f6.tscn", "from_f5", "Lên Tầng 6 (Phòng Phong Ấn Sống)")
	_finish("res://maps/sigilspire_f5.tscn", Vector2(35, 44))


# ---------------- TẦNG 6 — PHÒNG PHONG ẤN SỐNG / SERAPHINE (70x55) ----------------

func _build_f6() -> void:
	_new_map("SigilspireF6", 70, 55)
	_fill("dark")
	_stone_room(10, 34, 59, 49, [Vector2i(35, 34)])
	_stone_room(8, 6, 61, 28, [Vector2i(35, 28), Vector2i(35, 6)])
	_prop("fireplace", Vector2(35, 9), 1.0, "SeraphineHearth")
	_prop("bench", Vector2(24, 22), 1.0, "SeraphineBench")
	_prop("campfire", Vector2(35, 24), 0.8, "SeraphineLamp")
	_label("TẦNG 6 — PHÒNG PHONG ẤN SỐNG", Vector2(35, 10), 26)
	_label("Một phòng ở. Một đời người. Một cái neo.", Vector2(35, 13), 18)
	_npc("NPC_Seraphine", "seraphine", "Công chúa Seraphine", Vector2(35, 18),
		Color(0.95, 0.85, 0.6), ["thap_03_seraphine"],
		{"before": ["Ngươi đến thật à. Bao nhiêu hiệp sĩ trong truyện cổ tích 'đến cứu công chúa'... mà chưa ai hỏi công chúa xem cô ấy đang GIỮ cái gì.",
			"Ta là vật phong ấn sống, hiệp sĩ. Phong ấn của vương quốc này không nằm trong đá — nó nằm trong NGƯỜI. Ta là cái neo. Nếu ngươi 'cứu' ta ra khỏi tháp này theo cách thông thường, ấn mất neo và vỡ tung — thứ bị giam sẽ tràn ra khắp bốn vùng trong một đêm.",
			"Vua ở đỉnh tháp không hẳn là ác nhân trong truyện của ngươi đâu. Hắn điều khiển bốn vua bù nhìn, đúng. Nhưng hắn cũng đang cố phá ấn CÓ KIỂM SOÁT — để ta được tự do, và để vương quốc không phải trả giá bằng một con người nữa. Cái giá của cách đó... ngươi sẽ nghe chính hắn nói.",
			"Lên đỉnh đi. Đánh bại hắn nếu phải đánh. Rồi TỰ NGƯƠI quyết định ở Bệ Phong Ấn: giữ ấn theo cách mới, phá ấn theo cách của hắn, hay... ngồi vào chỗ của ta. Ta không xin ngươi chọn cách nào. Ta chỉ xin ngươi đừng chọn như một nhân vật trong truyện."],
		 "active": ["Cổng lên đỉnh chỉ mở cho người đã nghe hết sự thật. Ngươi nghe rồi đấy. Đi đi."],
		 "ready": ["Ngươi hiểu rồi. Tốt. Dù ngươi chọn gì ở Bệ Phong Ấn — cảm ơn vì đã hỏi ta trước. Chưa từng có ai hỏi cả."],
		 "done": ["Dù kết cục nào... lần đầu tiên trong đời, ta thấy hồi hộp về ngày mai. Cảm giác lạ thật. Đi đi, hiệp sĩ của bốn vùng đất."]},
		[])
	_spawn("from_f5", Vector2(35, 44))
	_spawn("from_summit", Vector2(35, 10))
	_portal("PortalDown", Vector2(35, 47), "res://maps/sigilspire_f5.tscn", "from_f6", "Xuống Tầng 5")
	_portal("PortalUp", Vector2(35, 3), "res://maps/sigilspire_summit.tscn", "from_f6",
		"Lên Tầng 7 — Đỉnh Tháp", "seraphine_truth",
		"Ấn chặn cầu thang lên đỉnh: hãy gặp Seraphine và nghe hết sự thật ở Tầng 6 trước.")
	_finish("res://maps/sigilspire_f6.tscn", Vector2(35, 44))


# ---------------- TẦNG 7 — ĐỈNH THÁP / NGAI VUA (90x65) ----------------

func _build_summit() -> void:
	_new_map("SigilspireSummit", 90, 65)
	_fill("dark")
	_stone_room(14, 44, 75, 59, [Vector2i(45, 44)])
	_stone_room(10, 6, 79, 38, [Vector2i(45, 38)])
	_prop("statue", Vector2(24, 12), 1.0, "SummitStatueL")
	_prop("statue", Vector2(66, 12), 1.0, "SummitStatueR")
	_prop("banner", Vector2(35, 9), 1.0, "SummitBannerL")
	_prop("banner", Vector2(55, 9), 1.0, "SummitBannerR")
	_label("TẦNG 7 — ĐỈNH SIGILSPIRE: NGAI CỦA KẺ KÉO DÂY", Vector2(45, 9), 26)
	_label("BỆ PHONG ẤN — nơi quyết định kết cục của vương quốc", Vector2(45, 30), 20)
	_npc("NPC_VuaDinhThap", "vua_dinh_thap", "Vua Trên Đỉnh Tháp", Vector2(58, 18),
		Color(0.9, 0.75, 0.45), ["thap_04_vua_dinh_thap"],
		{"before": ["(Vua không ngồi ngai. Hắn đứng cạnh Bệ Phong Ấn, và trông... mệt. Mệt như một người đã kéo bốn sợi dây rối suốt mấy chục năm không được ngủ.)",
			"Ta biết ngươi nghĩ gì: kẻ điều khiển bốn vua bù nhìn, tên bạo chúa trên đỉnh tháp. Đúng một nửa. Nửa còn lại: ấn này ĂN lời thề bị phản bội, hiệp sĩ. Muốn nó không đói đến mức phá neo, ta phải KIỂM SOÁT mọi lời thề trong vương quốc — qua bốn con rối, bốn triều đình giả. Ta không cai trị vì tham. Ta cai trị vì cái neo là một CÔ GÁI, và ta không chịu nổi ý nghĩ để cô ấy gánh một mình thêm một đời nữa.",
			"Kế hoạch của ta: phá ấn có kiểm soát, thả thứ bị giam ra theo điều kiện, và giải thoát Seraphine. Ngươi đến phá hỏng gần hết bộ máy của ta rồi — giỏi. Giờ thì hoặc ngươi để ta hoàn tất... hoặc ngươi đánh bại ta và TỰ GÁNH quyết định đó ở Bệ Phong Ấn. Ta không nhường quyết định này cho kẻ chưa nghe hết sự thật — may cho ngươi, ngươi nghe hết rồi."],
		 "active": ["Đạn của ta không nương tay đâu — cả Chỉ Ấn lẫn băng của phương Bắc. Và khi ấn nứt ở phase cuối, mặt đất dưới chân ngươi cũng thành vũ khí. Né vòng sáng tím, hiệp sĩ."],
		 "ready": ["...Dây rối đứt rồi. Bệ Phong Ấn là của ngươi. Chọn cho tử tế vào — ta đã chọn hộ vương quốc này quá lâu, và ngươi thấy kết quả rồi đấy."],
		 "done": ["Vương quốc không còn vua trên đỉnh nữa. Nó có một Bệ Phong Ấn và một người đã dám tự quyết. Thế là đủ hơn ta từng dám mơ."]},
		[])
	_enemy("boss_puppet_king.tscn", Vector2(45, 18), false, 0.0)
	_seal_altar(Vector2(45, 27))
	_spawn("from_f6", Vector2(45, 52))
	_portal("PortalDown", Vector2(45, 57), "res://maps/sigilspire_f6.tscn", "from_summit", "Xuống Tầng 6")
	_finish("res://maps/sigilspire_summit.tscn", Vector2(45, 52))
