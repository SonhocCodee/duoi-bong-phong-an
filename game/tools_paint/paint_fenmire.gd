extends Node2D
## Tool mot lan (dot 3): dung 8 map VUNG NAM FENMIRE theo design/fenmire_so_do.md
## (Miregate, Reedmere, Drownedwood, Venomfen, Fevercamp, Blackmere,
## Sunken Tide Temple, Fenmire Approach). Nen = tileset swamp_v1 (dam lay),
## dungeon dung them interior stone. Nha/NPC/quai/portal dat bang code nhu
## build_city.gd. Chay: godot --headless --path game res://tools_paint/paint_fenmire.tscn
## Moi map ghi ra res://maps/<slug>.tscn rieng.

const TILE := 64.0
const T := {
	"water_a": Vector2i(0, 0), "water_b": Vector2i(1, 0), "water_deep": Vector2i(2, 0),
	"mud_wet": Vector2i(3, 0), "mud_dry": Vector2i(4, 0),
	"grass": Vector2i(0, 1), "grass_reeds": Vector2i(1, 1),
	"plank": Vector2i(2, 1), "plank_mossy": Vector2i(3, 1), "shore_s": Vector2i(4, 1),
	"shore_n": Vector2i(0, 2), "shore_w": Vector2i(1, 2), "shore_e": Vector2i(2, 2),
	"shore_cvx": Vector2i(3, 2), "shore_ccv": Vector2i(4, 2),
	"mud_shore_s": Vector2i(0, 3), "mud_shore_n": Vector2i(1, 3), "mud_path_s": Vector2i(2, 3),
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
	_rng.seed = 424242
	_build_miregate()
	_build_reedmere()
	_build_drownedwood()
	_build_venomfen()
	_build_fevercamp()
	_build_blackmere()
	_build_temple()
	_build_approach()
	print("[FENMIRE] ====== HOAN TAT, fail=", _fail)
	get_tree().quit(1 if _fail else 0)


# ---------------- khoi tao map ----------------

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
	_tm.tile_set = load("res://assets/tilesets/swamp_v1.tres")
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


func _fill(t: String, reed_ratio: float = 0.06) -> void:
	for c in _w:
		for r in _h:
			var tt := t
			if t == "grass" and _rng.randf() < reed_ratio:
				tt = "grass_reeds"
			elif t == "grass" and _rng.randf() < 0.05:
				tt = "mud_wet"
			_paint(c, r, tt)


func _rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
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


# Blob nuoc (ellipse theo o). solid_water=true: chan di (ho sau/ao den).
func _water_blob(cc: int, cr: int, rx: int, ry: int, deep: bool, solid_water: bool) -> void:
	for c in range(cc - rx, cc + rx + 1):
		for r in range(cr - ry, cr + ry + 1):
			var dx := float(c - cc) / maxf(1.0, float(rx))
			var dy := float(r - cr) / maxf(1.0, float(ry))
			if dx * dx + dy * dy <= 1.0:
				_paint(c, r, "water_deep" if deep else ("water_a" if _rng.randf() < 0.5 else "water_b"))
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
			if cur == T["water_a"] or cur == T["water_b"] or cur == T["water_deep"]:
				continue
			if _water.has(c + (r + 1) * 10000):
				_paint(c, r, "shore_s")
			elif _water.has(c + (r - 1) * 10000):
				_paint(c, r, "shore_n")
			elif _water.has((c - 1) + r * 10000):
				_paint(c, r, "shore_w")
			elif _water.has((c + 1) + r * 10000):
				_paint(c, r, "shore_e")


func _mud_patch(cc: int, cr: int, rx: int, ry: int, dry: bool) -> void:
	for c in range(cc - rx, cc + rx + 1):
		for r in range(cr - ry, cr + ry + 1):
			var dx := float(c - cc) / maxf(1.0, float(rx))
			var dy := float(r - cr) / maxf(1.0, float(ry))
			if dx * dx + dy * dy <= 1.0 and _rng.randf() < 0.9:
				_paint(c, r, "mud_dry" if dry else "mud_wet")


# Duong van go 2 o rong, noi cac diem bang doan ngang roi doc (chu L).
func _plank_path(points: Array) -> void:
	for i in range(points.size() - 1):
		var a: Vector2i = points[i]
		var b: Vector2i = points[i + 1]
		_plank_line(a.x, a.y, b.x, a.y)
		_plank_line(b.x, a.y, b.x, b.y)


func _plank_line(c0: int, r0: int, c1: int, r1: int) -> void:
	var dc := signi(c1 - c0)
	var dr := signi(r1 - r0)
	var c := c0
	var r := r0
	while true:
		for o in [0, 1]:
			var cc: int = c + (o if dc == 0 else 0)
			var rr: int = r + (o if dr == 0 else 0)
			_paint(cc, rr, "plank" if _rng.randf() < 0.7 else "plank_mossy")
			_unmark(cc, rr)
			_water.erase(cc + rr * 10000)
		if c == c1 and r == r1:
			break
		c += dc
		r += dr


func signi(v: int) -> int:
	return 0 if v == 0 else (1 if v > 0 else -1)


# ---------------- dat node ----------------

func _prop(tex_name: String, cell: Vector2, scl: float = 1.0, node_name: String = "") -> Node2D:
	var holder := Node2D.new()
	holder.position = _cc(cell.x, cell.y)
	holder.y_sort_enabled = true
	holder.name = node_name if node_name != "" else ("Prop_" + tex_name)
	var tex: Texture2D = load("res://assets/props/" + tex_name + ".png")
	if tex == null:
		print("[FENMIRE] LOI texture: ", tex_name)
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
		print("[FENMIRE] LOI texture nha: ", tex_name)
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
		print("[FENMIRE] LOI scene quai: ", scene_file)
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
	# Vien map: chan toan bo chu vi tru o portal/spawn da unmark
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
		print("[FENMIRE] PACK LOI ", save_path, ": ", err)
		_fail = true
		return
	err = ResourceSaver.save(packed, save_path)
	print("[FENMIRE] saved ", save_path, " err=", err, " solid=", _solid.size())
	if err != OK:
		_fail = true
	remove_child(_root)
	_root.queue_free()


# ---------------- MIREGATE (70x50) ----------------

func _build_miregate() -> void:
	_new_map("Miregate", 70, 50)
	_fill("grass", 0.10)
	_mud_patch(35, 25, 16, 20, false)
	_water_blob(12, 38, 8, 6, false, true)
	_water_blob(58, 10, 7, 5, false, true)
	# Duong mon bun giua map: Bac (Cong Tuong) -> Nam (Reedmere)
	_rect(32, 0, 37, 49, "mud_wet")
	_plank_path([Vector2i(34, 40), Vector2i(20, 40), Vector2i(14, 38)])
	for i in 10:
		_prop("mangrove", Vector2(_rng.randi_range(2, 67), _rng.randi_range(2, 47)), 0.9)
	for i in 8:
		_prop("reed_clump", Vector2(_rng.randi_range(2, 67), _rng.randi_range(2, 47)), 1.0)
	_label("MIREGATE — Cổng Tường Nam", Vector2(35, 6), 26)
	_enemy("swamp_frog.tscn", Vector2(24, 18))
	_enemy("swamp_frog.tscn", Vector2(46, 30))
	_enemy("swamp_frog.tscn", Vector2(30, 40))
	_enemy("swamp_wisp.tscn", Vector2(55, 22))
	_enemy("swamp_wisp.tscn", Vector2(16, 14))
	_spawn("start", Vector2(35, 4))
	_spawn("from_duong", Vector2(35, 4))
	_spawn("from_khung", Vector2(4, 25))
	_spawn("from_reedmere", Vector2(35, 45))
	_portal("PortalNorth", Vector2(35, 1), "res://maps/duong_di_nam.tscn", "from_khung", "Đường Đi Nam (về Aldenmere)")
	_portal("PortalGate", Vector2(1, 25), "res://maps/cong_nam_khung.tscn", "from_duong", "Cổng Tường Nam")
	_portal("PortalSouth", Vector2(35, 48), "res://maps/reedmere.tscn", "from_miregate", "Reedmere")
	_finish("res://maps/miregate.tscn", Vector2(35, 4))


# ---------------- REEDMERE (100x70) — lang khoi vung ----------------

func _build_reedmere() -> void:
	_new_map("Reedmere", 100, 70)
	_fill("grass", 0.08)
	_mud_patch(50, 58, 30, 8, false)
	_water_blob(84, 14, 9, 6, false, true) # ho nho dong-bac
	_water_blob(12, 60, 8, 5, false, true)
	# San lang trung tam + duong van
	_rect(38, 28, 62, 42, "mud_dry")
	_plank_path([Vector2i(50, 1), Vector2i(50, 34)])
	_plank_path([Vector2i(50, 40), Vector2i(30, 52), Vector2i(6, 64)])
	_plank_path([Vector2i(42, 34), Vector2i(20, 30)])
	# Nha san quanh san (nhieu mau/co, xo lech huu co)
	_building("house_a", 30, 26, 6)
	_building("house_b", 40, 24, 7)
	_building("house_f", 52, 26, 5)
	_building("house_c", 60, 24, 8)
	_building("house_d", 28, 44, 6)
	_building("house_e", 44, 46, 9)
	_building("house_b", 58, 44, 7)
	_building("house_f", 70, 34, 5)
	_prop("fountain", Vector2(50, 35), 0.55, "PropWell") # gieng nuoc ngot cua lang
	for i in 12:
		_prop("reed_clump", Vector2(_rng.randi_range(2, 97), _rng.randi_range(50, 67)), 1.0)
	for i in 7:
		_prop("mangrove", Vector2(_rng.randi_range(2, 97), _rng.randi_range(2, 12)), 0.9)
	_label("REEDMERE — Làng Bãi Sậy", Vector2(50, 20), 26)
	_herb(Vector2(24, 54))
	_herb(Vector2(76, 52))
	_herb(Vector2(66, 60))
	# Quai ven lang phia nam (phuc kich o bai say)
	_enemy("swamp_frog.tscn", Vector2(30, 58))
	_enemy("swamp_frog.tscn", Vector2(58, 62))
	_enemy("swamp_frog.tscn", Vector2(80, 56))
	# NPC song: truong lang, dan say, tre con
	_npc("NPC_TruongReedmere", "truong_reedmere", "Trưởng làng Reedmere", Vector2(46, 33),
		Color(0.95, 0.9, 0.8), ["nam_01_den_fenmire", "nam_06c_pha_chu_ky"],
		{"before": ["Chào ngươi tới Reedmere. Thấy thùng thuốc của làng ta không? Giáo phái hứa phát thuốc, mà Đỉa Bùn chặn mất đường ở bìa Drownedwood.",
			"Diệt giúp ta 3 con Đỉa Bùn giữ đường. Thuốc về được làng, người bệnh mới có cửa sống."],
		 "active": ["Đỉa Bùn ở bìa đông Drownedwood, chỗ nước tù có bầy đỉa. Cẩn thận, chúng trâu lắm."],
		 "ready": ["Thuốc về làng rồi! Ngươi không biết mình vừa cứu bao nhiêu người đâu."],
		 "done": ["Reedmere nhớ ơn ngươi. Nhưng nhớ lấy: thuốc của giáo phái lúc nào cũng kèm một cái sổ — và tên dân làng ta nằm trong đó."]},
		[[46, 33, "idle", 6], [50, 35, "walk", 5], [50, 35, "idle", 5], [38, 36, "walk", 6], [38, 36, "idle", 4]])
	_npc("NPC_DanSay", "dan_say_1", "Dân làng Sậy", Vector2(56, 38),
		Color(0.8, 0.95, 0.85), ["nam_03a_pha_vuon", "nam_03b_ghi_chung_cu", "nam_side_herb"],
		{"before": ["Ngươi hỏi chuyện vườn nấm ở Venomfen à? Giáo phái trồng nấm độc ngay cạnh đường, ếch canh ngày đêm.",
			"Phá vườn thì làng mất nguồn thuốc lẫn lộn, để nguyên thì chúng còn thử thuốc lên người. Ngươi tự quyết — ta chỉ giữ chứng cứ giúp ngươi thôi."],
		 "active": ["Venomfen ở phía tây-nam, qua Drownedwood. Đầm độc lắm, nhìn chỗ nấm phát sáng mà tránh."],
		 "ready": ["Ngươi mang được tin về rồi à? Kể ta nghe, ta ghi lại hết vào sổ của làng."],
		 "done": ["Dân Reedmere này sống bằng sậy và cá. Từ ngày có 'thuốc' của giáo phái, sống thêm một thứ nữa: nợ."]},
		[[56, 38, "idle", 4], [66, 55, "walk", 6], [66, 55, "work", 10], [56, 38, "walk", 6]])
	_npc("NPC_TreReedmere", "tre_reedmere", "Đứa trẻ Reedmere", Vector2(43, 37),
		Color(1.0, 0.85, 0.7), [],
		{"done": ["Bệnh thì uống thuốc tím, hết thuốc tím thì... mẹ em bảo nằm im chờ triều rút.",
			"Anh/chị có thấy tên em trong sổ thuốc không? Em không biết chữ, nhưng em thuộc hết tên người trong làng."]},
		[[43, 37, "idle", 3], [54, 33, "walk", 4], [54, 33, "idle", 3], [43, 37, "walk", 4]])
	_spawn("start", Vector2(50, 4))
	_spawn("from_miregate", Vector2(50, 4))
	_spawn("from_drownedwood", Vector2(6, 64))
	_portal("PortalNorth", Vector2(50, 1), "res://maps/miregate.tscn", "from_reedmere", "Miregate")
	_portal("PortalSW", Vector2(4, 65), "res://maps/drownedwood.tscn", "from_reedmere", "Drownedwood")
	_craft_station(Vector2(52, 33), "Bàn Giả Kim Reedmere")
	_finish("res://maps/reedmere.tscn", Vector2(50, 4))


# ---------------- DROWNEDWOOD (130x95) — rung ngap nuoc ----------------

func _build_drownedwood() -> void:
	_new_map("Drownedwood", 130, 95)
	_fill("grass", 0.05)
	# Nuoc ngap nong (di duoc, khong chan) — nhieu vung rai rac
	_water_blob(30, 30, 16, 10, false, false)
	_water_blob(70, 20, 14, 8, false, false)
	_water_blob(100, 40, 15, 9, false, false)
	_water_blob(45, 65, 13, 8, false, false)
	_water_blob(85, 75, 16, 9, false, false)
	# O dia (nuoc sau, chan) o vung nuoc tu phia bac
	_water_blob(60, 45, 7, 5, true, true)
	_water_blob(110, 70, 6, 4, true, true)
	# Duong van muc dut doan
	_plank_path([Vector2i(128, 20), Vector2i(95, 20), Vector2i(70, 38)])
	_plank_path([Vector2i(70, 38), Vector2i(40, 55), Vector2i(8, 78)])
	_plank_path([Vector2i(70, 38), Vector2i(72, 70), Vector2i(70, 92)])
	for i in 42:
		_prop("mangrove", Vector2(_rng.randi_range(2, 127), _rng.randi_range(2, 92)), _rng.randf_range(0.8, 1.1))
	for i in 14:
		_prop("reed_clump", Vector2(_rng.randi_range(2, 127), _rng.randi_range(2, 92)), 1.0)
	for i in 5:
		_prop("swamp_log", Vector2(_rng.randi_range(4, 125), _rng.randi_range(4, 90)), 1.0)
	_label("DROWNEDWOOD — Rừng Ngập Nước", Vector2(65, 8), 26)
	_herb(Vector2(52, 30))
	_herb(Vector2(90, 55))
	_herb(Vector2(35, 72))
	_herb(Vector2(105, 25))
	# Dia giu duong o bia dong (muc tieu nam_01) + bay dia nuoc tu
	_enemy("mire_leech.tscn", Vector2(112, 26))
	_enemy("mire_leech.tscn", Vector2(106, 32))
	_enemy("mire_leech.tscn", Vector2(116, 36))
	_enemy("mire_leech.tscn", Vector2(60, 42))
	_enemy("mire_leech.tscn", Vector2(64, 48))
	_enemy("mire_leech.tscn", Vector2(56, 46))
	_enemy("swamp_frog.tscn", Vector2(38, 40))
	_enemy("swamp_frog.tscn", Vector2(88, 60))
	_enemy("swamp_frog.tscn", Vector2(25, 70))
	_enemy("swamp_frog.tscn", Vector2(100, 15))
	_enemy("swamp_wisp.tscn", Vector2(48, 58))
	_enemy("swamp_wisp.tscn", Vector2(95, 82))
	_enemy("swamp_wisp.tscn", Vector2(20, 25))
	_enemy("water_spider.tscn", Vector2(78, 30))
	_enemy("water_spider.tscn", Vector2(42, 82))
	# NPC an: nguoi thu thao
	_npc("NPC_ThuThao", "nguoi_thu_thao", "Người Hái Thảo", Vector2(70, 60),
		Color(0.85, 1.0, 0.9), [],
		{"done": ["Ta hái thảo độc bán cho cả hai phe — giáo phái mua làm thuốc, dân làng mua làm thuốc giải. Đầm này không chọn phe, người mới chọn.",
			"Thấy nấm phát sáng ở Venomfen không? Đẹp đấy, nhưng đừng sờ vào."]},
		[[70, 60, "work", 9], [58, 66, "walk", 5], [58, 66, "work", 9], [70, 60, "walk", 5]])
	_spawn("start", Vector2(124, 20))
	_spawn("from_reedmere", Vector2(124, 20))
	_spawn("from_venomfen", Vector2(8, 78))
	_spawn("from_blackmere", Vector2(70, 88))
	_portal("PortalEast", Vector2(127, 20), "res://maps/reedmere.tscn", "from_drownedwood", "Reedmere")
	_portal("PortalSW", Vector2(5, 80), "res://maps/venomfen.tscn", "from_drownedwood", "Venomfen")
	_portal("PortalSouthWater", Vector2(70, 92), "res://maps/blackmere.tscn", "from_drownedwood", "Đường thủy → Blackmere", "mo_duong_thuy", "Rễ đước chằng chịt chặn đường thủy. Dân chài Blackmere chưa mở đường này.")
	_finish("res://maps/drownedwood.tscn", Vector2(124, 20))


# ---------------- VENOMFEN (120x85) — dam doc + vuon nam ----------------

func _build_venomfen() -> void:
	_new_map("Venomfen", 120, 85)
	_fill("grass", 0.04)
	_mud_patch(60, 42, 45, 30, false)
	_water_blob(30, 20, 12, 7, true, true) # ho doc
	_water_blob(95, 65, 13, 8, true, true)
	_water_blob(70, 15, 9, 5, false, false)
	_plank_path([Vector2i(112, 12), Vector2i(70, 30), Vector2i(45, 45)])
	_plank_path([Vector2i(45, 45), Vector2i(30, 60), Vector2i(14, 74)])
	_plank_path([Vector2i(45, 45), Vector2i(80, 55), Vector2i(112, 62)])
	# Vuon nam giao phai: vong nam phat sang phia tay
	for a in 14:
		var ang := TAU * float(a) / 14.0
		_prop("glowshroom", Vector2(22 + int(9.0 * cos(ang)), 42 + int(7.0 * sin(ang))), 1.1)
	_prop("glowshroom", Vector2(22, 42), 1.4, "GlowshroomHeart")
	_label("Vườn Nấm của Giáo Phái", Vector2(22, 30), 20)
	_label("VENOMFEN — Đầm Độc", Vector2(60, 6), 26)
	for i in 10:
		_prop("glowshroom", Vector2(_rng.randi_range(4, 115), _rng.randi_range(4, 80)), 0.9)
	for i in 10:
		_prop("mangrove", Vector2(_rng.randi_range(4, 115), _rng.randi_range(4, 80)), 0.9)
	_herb(Vector2(50, 20))
	_herb(Vector2(88, 40))
	# Ech canh vuon nam (muc tieu nam_03a)
	_enemy("swamp_frog.tscn", Vector2(18, 38))
	_enemy("swamp_frog.tscn", Vector2(26, 46))
	_enemy("swamp_frog.tscn", Vector2(22, 34))
	_enemy("swamp_frog.tscn", Vector2(28, 42))
	_enemy("swamp_frog.tscn", Vector2(55, 30))
	_enemy("swamp_frog.tscn", Vector2(100, 45))
	_enemy("water_spider.tscn", Vector2(40, 65))
	_enemy("water_spider.tscn", Vector2(75, 70))
	_enemy("water_spider.tscn", Vector2(105, 20))
	_enemy("swamp_wisp.tscn", Vector2(35, 55))
	_enemy("swamp_wisp.tscn", Vector2(90, 30))
	_enemy("swamp_wisp.tscn", Vector2(60, 68))
	_enemy("mire_leech.tscn", Vector2(48, 48))
	_enemy("mire_leech.tscn", Vector2(98, 58))
	_spawn("start", Vector2(110, 12))
	_spawn("from_drownedwood", Vector2(110, 12))
	_spawn("from_fevercamp", Vector2(110, 62))
	_spawn("from_blackmere", Vector2(14, 74))
	_portal("PortalNE", Vector2(114, 10), "res://maps/drownedwood.tscn", "from_venomfen", "Drownedwood")
	_portal("PortalEast", Vector2(114, 62), "res://maps/fevercamp.tscn", "from_venomfen", "Fevercamp")
	_portal("PortalNW", Vector2(10, 76), "res://maps/blackmere.tscn", "from_venomfen", "Blackmere")
	_finish("res://maps/venomfen.tscn", Vector2(110, 12))


# ---------------- FEVERCAMP (90x65) — trai dich benh ----------------

func _build_fevercamp() -> void:
	_new_map("Fevercamp", 90, 65)
	_fill("grass", 0.03)
	_rect(18, 14, 72, 50, "mud_dry") # nen trai dat kho
	_water_blob(80, 56, 6, 4, false, true)
	_plank_path([Vector2i(4, 32), Vector2i(45, 32)])
	_plank_path([Vector2i(45, 32), Vector2i(70, 44), Vector2i(82, 56)])
	_plank_path([Vector2i(45, 32), Vector2i(45, 6)])
	# Nha thuong + leu benh (dung prop nha/sap lam khung)
	_building("house_e", 24, 24, 9)
	_building("house_f", 58, 22, 5)
	_prop("stall_d", Vector2(45, 30), 1.0, "MedicineStall")
	_prop("stall_b", Vector2(34, 40), 1.0, "TentA")
	_prop("stall_c", Vector2(56, 40), 1.0, "TentB")
	_prop("stall_a", Vector2(66, 34), 1.0, "TentC")
	_prop("glowshroom", Vector2(20, 18), 0.9) # den tim khu cach ly
	_prop("glowshroom", Vector2(70, 18), 0.9)
	_label("FEVERCAMP — Trại Tị Nạn Dịch Bệnh", Vector2(45, 10), 26)
	_label("Khu cách ly", Vector2(24, 16), 18)
	# Quai ngoai hang rao phia tay
	_enemy("mire_leech.tscn", Vector2(6, 20))
	_enemy("mire_leech.tscn", Vector2(8, 48))
	_npc("NPC_YSi", "y_si_tram", "Y Sĩ Trưởng Trạm", Vector2(43, 31),
		Color(0.9, 0.95, 1.0), ["nam_02_danh_sach_thuoc", "nam_02a_thuoc_tre", "nam_06a_giu_thoa_thuan"],
		{"before": ["Ta là y sĩ của trạm này — người của giáo phái trên giấy, người của bệnh nhân ngoài đời.",
			"Sổ thuốc chỉ phát cho một nửa danh sách. Ngươi hái giúp ta 3 thảo dược đầm, ta sắc thuốc ngoài sổ, cứu được ai hay người đó."],
		 "active": ["Thảo dược mọc quanh Reedmere và Drownedwood. Đủ 3 cây mang về đây."],
		 "ready": ["Đủ thảo rồi. Phần thuốc này không có trong sổ của giáo phái — và ta phải chọn phát cho một nhóm thôi. Ngươi quyết thay ta: trẻ bệnh nặng, người già giữ nghề, hay người nuôi cả nhà?"],
		 "done": ["Mỗi lựa chọn ở đây đều để lại người không được cứu. Ta ghi hết vào sổ riêng — sau này đối chất ở Fenmire, đừng để họ nói dân đầm tự chọn lấy cái chết."]},
		[[43, 31, "work", 10], [30, 26, "walk", 5], [30, 26, "work", 8], [43, 31, "walk", 5]], "res://assets/sprites/nong_dan_frames.tres")
	_npc("NPC_BenhNhan", "benh_nhan_1", "Ông Già Giữ Nghề Chài", Vector2(36, 41),
		Color(0.85, 0.85, 0.9), ["nam_02b_thuoc_gia"],
		{"before": ["Ta chài cá ở Blackmere bốn mươi năm. Tay ta run rồi, nhưng lưới nào rách ta còn vá được, triều nào lạ ta còn đọc được.",
			"Thuốc ít thì cho lớp trẻ giữ nghề cũng phải... mà đám trẻ bệnh nặng kia, chúng nó còn chưa biết chài. Khó. Ngươi quyết đi."],
		 "active": ["Ta chờ được. Cả đời chờ triều, chờ cá, chờ thuốc."],
		 "ready": ["Ngươi chọn ta à? Vậy ta phải sống cho đáng — ra khơi lại, dạy hết nghề cho đám nhỏ Reedmere."],
		 "done": ["Cái đầm này nuôi người bằng cá và giết người bằng nước. Giáo phái chỉ là kẻ đến sau, bán thuốc cho cả hai việc."]},
		[[36, 41, "idle", 12], [40, 44, "walk", 4], [40, 44, "idle", 10], [36, 41, "walk", 4]])
	_npc("NPC_MeGoa", "me_goa", "Người Mẹ Góa", Vector2(58, 41),
		Color(1.0, 0.9, 0.85), ["nam_02c_thuoc_nuoi_nha"],
		{"before": ["Chồng tôi nằm trong lều kia. Anh ấy là người duy nhất trong nhà còn gánh được nước, vá được lưới.",
			"Tôi không xin cho mình. Anh ấy mà gục, ba đứa nhỏ nhà tôi chết theo — chậm hơn, nhưng chắc hơn."],
		 "active": ["Anh ấy sốt cả đêm. Tôi đếm từng đợt triều ngoài kia mà chờ."],
		 "ready": ["Ơn này nhà tôi không trả nổi bằng cá đâu. Anh ấy sống lại, cả nhà tôi theo ngươi tới cùng."],
		 "done": ["Người ta bảo giáo phái cứu dân đầm. Đúng — họ cứu, và họ ghi sổ từng mạng một."]},
		[[58, 41, "idle", 8], [52, 36, "walk", 4], [52, 36, "idle", 8], [58, 41, "walk", 4]])
	_spawn("start", Vector2(6, 32))
	_spawn("from_venomfen", Vector2(6, 32))
	_spawn("from_temple", Vector2(82, 56))
	_spawn("from_blackmere", Vector2(45, 6))
	_portal("PortalWest", Vector2(2, 32), "res://maps/venomfen.tscn", "from_fevercamp", "Venomfen")
	_portal("PortalSE", Vector2(84, 58), "res://maps/sunken_tide_temple.tscn", "from_fevercamp", "Sunken Tide Temple")
	_portal("PortalNorth", Vector2(45, 3), "res://maps/blackmere.tscn", "from_fevercamp", "Blackmere (đường bờ kênh)")
	_finish("res://maps/fevercamp.tscn", Vector2(6, 32))


# ---------------- BLACKMERE (140x95) — ho lon + lang chai ----------------

func _build_blackmere() -> void:
	_new_map("Blackmere", 140, 95)
	_fill("grass", 0.05)
	# Ho lon nua tay map (nuoc sau, chan) + mat ho duc
	_water_blob(32, 47, 26, 34, true, true)
	_water_blob(58, 20, 10, 8, false, true)
	_mud_patch(95, 50, 25, 30, false)
	# Ben tau van go tu bo dong ra giua ho
	_plank_path([Vector2i(60, 47), Vector2i(38, 47)])
	_plank_path([Vector2i(95, 90), Vector2i(95, 60), Vector2i(80, 52)])
	_plank_path([Vector2i(80, 30), Vector2i(95, 18), Vector2i(95, 4)])
	# Lang chai bo dong: nha san + cho den long
	_building("house_b", 84, 34, 7)
	_building("house_a", 96, 30, 6)
	_building("house_f", 108, 36, 5)
	_building("house_c", 88, 62, 8)
	_building("house_d", 104, 66, 6)
	_prop("stall_a", Vector2(98, 44), 1.0, "StallBlackmere1")
	_prop("stall_c", Vector2(104, 44), 1.0, "StallBlackmere2")
	_prop("stall_d", Vector2(98, 50), 1.0, "StallBlackmere3")
	for i in 9:
		_prop("mangrove", Vector2(_rng.randi_range(62, 136), _rng.randi_range(2, 12)), 0.9)
	for i in 6:
		_prop("reed_clump", Vector2(_rng.randi_range(60, 70), _rng.randi_range(10, 85)), 1.0)
	_label("BLACKMERE — Hồ Đầm Lớn", Vector2(34, 12), 26)
	_label("Làng chài Blackmere", Vector2(98, 22), 22)
	# Quai ven ho + duong thuy phia bac (muc tieu nam_04) + Dia Chua elite
	_enemy("mire_leech.tscn", Vector2(66, 14))
	_enemy("mire_leech.tscn", Vector2(72, 10))
	_enemy("mire_leech.tscn", Vector2(60, 18))
	_enemy("mire_leech.tscn", Vector2(78, 16))
	_enemy("mire_leech.tscn", Vector2(64, 30), true) # Dia Chua mini-elite
	_enemy("swamp_frog.tscn", Vector2(70, 55))
	_enemy("swamp_frog.tscn", Vector2(74, 62))
	_enemy("swamp_frog.tscn", Vector2(68, 70))
	_enemy("swamp_frog.tscn", Vector2(80, 78))
	_enemy("swamp_croc.tscn", Vector2(84, 84))
	_enemy("swamp_croc.tscn", Vector2(110, 82))
	_npc("NPC_TruongDanChai", "truong_dan_chai_ho", "Trưởng Dân Chài Blackmere", Vector2(94, 46),
		Color(0.85, 0.9, 1.0), ["nam_04_duong_thuy", "nam_05_den_chim_trieu", "nam_06b_giu_trieu_moi"],
		{"before": ["Dân chài ta giấu một chuyện: triều ở Fenmire không tự dâng. Có người giữ nó — và không phải giáo phái.",
			"Dọn giúp ta bầy Đỉa Bùn chắn đường thủy phía bắc hồ, ta mở đường và kể hết phiên bản của Người Giữ Triều."],
		 "active": ["Đỉa ở vùng nước tù phía bắc hồ, có cả con Đỉa Chúa to như cái xuồng. Dọn xong quay lại đây."],
		 "ready": ["Đường thủy thông rồi. Nghe cho kỹ đây — chứng cứ C: tên các đời Người Giữ Triều khắc dưới mực nước trong đền, giáo phái chỉ là kẻ đến sau chiếm lấy triều."],
		 "done": ["Vào đền lúc triều rút, đọc tên khắc dưới nước, rồi đối mặt Morvain. Dân chài đứng sau ngươi — nếu ngươi chọn con đường giữ triều."]},
		[[94, 46, "idle", 5], [70, 47, "walk", 6], [70, 47, "work", 9], [94, 46, "walk", 6]], "res://assets/sprites/nong_dan_frames.tres")
	_npc("NPC_DanChai", "dan_chai_ho_1", "Dân Chài Blackmere", Vector2(100, 52),
		Color(0.9, 1.0, 0.95), ["nam_side_croc"],
		{"before": ["Cá sấu ăn đêm ở bến nam, hai con. Dân ta không dám ra khơi từ dạo ấy. Dẹp giúp, ta trả cá khô cả tháng."],
		 "active": ["Bến phía nam hồ, chỗ nước đen nhất. Nghe tiếng táp nước là nó đấy."],
		 "ready": ["Bến yên rồi! Đêm nay cả làng ra khơi lại."],
		 "done": ["Cá chết nổi vòng tròn hướng về đền — ngươi thấy chưa? Hồ này đang nhìn về phía triều bị giữ."]},
		[[100, 52, "idle", 4], [86, 56, "walk", 5], [86, 56, "work", 8], [100, 52, "walk", 5]])
	_npc("NPC_LaiPha", "lai_pha_ho", "Người Lái Phà", Vector2(120, 47),
		Color(0.95, 0.95, 0.85), [],
		{"done": ["Phà của ta chạy sang Fenmire Approach, sát chân thành. Thành Fenmire thì chưa ai cho ngươi vào đâu — cổng Bắc khóa, layout còn chờ duyệt trên... à quên, ta nói gì nhỉ.",
			"Muốn vào thành, cứ đi đường phà này tới Approach rồi ngó cổng."]},
		[[120, 47, "idle", 10], [126, 47, "walk", 4], [126, 47, "idle", 8], [120, 47, "walk", 4]])
	_spawn("start", Vector2(95, 88))
	_spawn("from_fevercamp", Vector2(95, 88))
	_spawn("from_venomfen", Vector2(95, 88))
	_spawn("from_drownedwood", Vector2(95, 6))
	_spawn("from_temple", Vector2(120, 60))
	_spawn("from_approach", Vector2(132, 47))
	_portal("PortalSouth", Vector2(95, 92), "res://maps/fevercamp.tscn", "from_blackmere", "Fevercamp")
	_portal("PortalNorthWater", Vector2(95, 2), "res://maps/drownedwood.tscn", "from_blackmere", "Đường thủy → Drownedwood")
	_portal("PortalSE", Vector2(124, 62), "res://maps/sunken_tide_temple.tscn", "from_blackmere", "Cửa phụ Sunken Tide Temple")
	_portal("PortalFerry", Vector2(136, 47), "res://maps/fenmire_approach.tscn", "from_blackmere", "Phà → Fenmire Approach")
	_finish("res://maps/blackmere.tscn", Vector2(95, 88))


# ---------------- SUNKEN TIDE TEMPLE (150x100) — dungeon 3 khu ----------------

func _stone_rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_tm2.set_cell(0, Vector2i(c, r), 0, STONE[t])
			_water.erase(c + r * 10000)


func _stone_room(c0: int, r0: int, c1: int, r1: int, doors: Array) -> void:
	_stone_rect(c0, r0, c1, r1, "floor")
	# Tuong bao: ve tile wall + danh solid, tru o cua (doors = [Vector2i])
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


func _build_temple() -> void:
	_new_map("SunkenTideTemple", 150, 100)
	_fill("mud_wet", 0.0)
	_rect(0, 0, 149, 99, "mud_wet")
	# Khu 1: sanh vao (bac)
	_stone_room(55, 6, 95, 30, [Vector2i(75, 30), Vector2i(74, 30), Vector2i(56, 18)])
	# Khu 2: hoi truong ngap (giua) — nuoc + cau van
	_water_blob(75, 48, 34, 13, false, true)
	_plank_path([Vector2i(75, 30), Vector2i(75, 46)])
	_plank_path([Vector2i(75, 50), Vector2i(75, 66)])
	_plank_path([Vector2i(50, 48), Vector2i(75, 48)])
	# Khu 3: dien sau nhat (nam) — phong boss
	_stone_room(50, 66, 100, 94, [Vector2i(75, 66), Vector2i(74, 66), Vector2i(99, 80)])
	_stone_rect(70, 84, 80, 92, "floor_a") # be trieu / san le
	for i in 8:
		_prop("glowshroom", Vector2(_rng.randi_range(56, 94), _rng.randi_range(8, 28)), 0.9)
	for i in 6:
		_prop("glowshroom", Vector2(_rng.randi_range(52, 98), _rng.randi_range(70, 90)), 0.9)
	_prop("mangrove", Vector2(20, 20), 1.0)
	_prop("mangrove", Vector2(130, 25), 1.0)
	_prop("mangrove", Vector2(18, 80), 1.0)
	_label("SUNKEN TIDE TEMPLE — Đền Chìm Triều", Vector2(75, 3), 26)
	_label("Phòng thử thuốc", Vector2(60, 70), 18)
	_label("Tên Người Giữ Triều khắc dưới mực nước", Vector2(75, 56), 16)
	# Canh den: tin do + bong doc (wisp) + nhen nuoc + dia o hoi truong
	_enemy("cultist.tscn", Vector2(64, 16))
	_enemy("cultist.tscn", Vector2(86, 16))
	_enemy("cultist.tscn", Vector2(75, 24))
	_enemy("cultist.tscn", Vector2(60, 74))
	_enemy("cultist.tscn", Vector2(90, 74))
	_enemy("cultist.tscn", Vector2(75, 70))
	_enemy("swamp_wisp.tscn", Vector2(58, 44))
	_enemy("swamp_wisp.tscn", Vector2(92, 52))
	_enemy("water_spider.tscn", Vector2(52, 48))
	_enemy("water_spider.tscn", Vector2(98, 44))
	_enemy("water_spider.tscn", Vector2(66, 88))
	_enemy("mire_leech.tscn", Vector2(84, 90))
	# BOSS: Dai Tu Te Morvain o dien sau nhat
	_enemy("boss_high_priest.tscn", Vector2(75, 80), false, 0.0)
	_spawn("start", Vector2(75, 10))
	_spawn("from_fevercamp", Vector2(75, 10))
	_spawn("from_blackmere", Vector2(52, 48))
	_spawn("from_approach", Vector2(98, 80))
	_portal("PortalDoor", Vector2(56, 18), "res://maps/fevercamp.tscn", "from_temple", "Cửa đền → Fevercamp")
	_portal("PortalSide", Vector2(48, 48), "res://maps/blackmere.tscn", "from_temple", "Cửa phụ (triều rút) → Blackmere")
	_portal("PortalNorthDry", Vector2(99, 80), "res://maps/fenmire_approach.tscn", "from_temple", "Đường cạn → Fenmire Approach")
	_finish("res://maps/sunken_tide_temple.tscn", Vector2(75, 10))


# ---------------- FENMIRE APPROACH (80x55) — duong vao thanh ----------------

func _build_approach() -> void:
	_new_map("FenmireApproach", 80, 55)
	_fill("grass", 0.05)
	_water_blob(14, 27, 11, 20, true, true)
	_water_blob(66, 27, 11, 20, true, true)
	# Duong cạn van go chay len cong thanh phia bac
	_plank_path([Vector2i(8, 47), Vector2i(40, 40), Vector2i(40, 10)])
	_plank_path([Vector2i(40, 40), Vector2i(64, 46)])
	_plank_path([Vector2i(40, 40), Vector2i(24, 48), Vector2i(24, 51)])
	_prop("tower", Vector2(34, 6), 1.0, "GateTowerL")
	_prop("tower", Vector2(46, 6), 1.0, "GateTowerR")
	_mark_rect(30, 2, 50, 5)
	_unmark(40, 5)
	_prop("glowshroom", Vector2(28, 12), 0.9)
	_prop("glowshroom", Vector2(52, 12), 0.9)
	_label("FENMIRE APPROACH — Đường Vào Thành", Vector2(40, 16), 24)
	_label("Cổng Bắc Fenmire — khóa (thành chờ duyệt layout)", Vector2(40, 8), 16)
	_enemy("cultist.tscn", Vector2(30, 22))
	_enemy("cultist.tscn", Vector2(50, 22))
	_enemy("swamp_croc.tscn", Vector2(58, 44))
	_spawn("start", Vector2(8, 47))
	_spawn("from_blackmere", Vector2(8, 47))
	_spawn("from_temple", Vector2(64, 46))
	_spawn("from_approach", Vector2(40, 12))
	_spawn("from_westgate", Vector2(24, 48))
	_portal("PortalFerry", Vector2(4, 47), "res://maps/blackmere.tscn", "from_approach", "Phà → Blackmere")
	_portal("PortalWestgate", Vector2(24, 52), "res://maps/westgate.tscn", "from_approach",
		"Caravan → Westgate (Vùng Tây Solmaris)", "nam_giai_phong",
		"Caravan sang Solmaris chỉ mở sau khi Fenmire được giải phóng.")
	_portal("PortalTemple", Vector2(66, 46), "res://maps/sunken_tide_temple.tscn", "from_approach", "Đường cạn → Sunken Tide Temple")
	_portal("PortalCityGate", Vector2(40, 4), "res://maps/fenmire_approach.tscn", "from_approach", "Fenmire", "thanh_fenmire_mo", "Cổng thành Fenmire khóa kín. (Nội thành chưa dựng — layout đang chờ user duyệt.)")
	_finish("res://maps/fenmire_approach.tscn", Vector2(8, 47))
