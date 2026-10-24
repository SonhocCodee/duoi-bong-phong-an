extends Node2D
## Tool mot lan: dung scene NOI THANH SOLMARIS 240x170 o theo layout da duyet
## (design/solmaris_layout.md + 2 diem user chot ghi de: khu bo lac NAM TRONG
## scene thanh, NGOAI tuong dong; cong Tay giu tuyen qua Buried Sand Ruins,
## KHONG mo duong thang toi hang Vesskar).
## Nha/sap HUU CO: lech hang 0-2 o, nhieu co/mau mai, hem 1-3 o bat quy tac.
## Chay: godot --headless --path game res://tools_paint/build_solmaris.tscn
## Ghi res://maps/solmaris.tscn.

const TILE := 64.0
const CW := 240
const CH := 170
const ORIGIN := Vector2(-7680.0, -5440.0) # (c-120)*64+32, (r-85)*64+32
const SAVE_PATH := "res://maps/solmaris.tscn"

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
const ADOBE := [
	["solmaris_house_a", 6], ["solmaris_house_b", 7], ["solmaris_house_c", 5],
]

var _rng := RandomNumberGenerator.new()
var _solid := {}
var _water := {}
var _root: Node2D
var _tm: TileMap
var _tm_stone: TileMap
var _fail := false
var _seq := 0
var _stall_count := 0

func _ready() -> void:
	_rng.seed = 240170
	_build()
	print("[SOLMARIS-CITY] ====== HOAN TAT, fail=", _fail, " stalls=", _stall_count)
	get_tree().quit(1 if _fail else 0)

# ---------------- helpers ----------------

func _cc(c: float, r: float) -> Vector2:
	return ORIGIN + Vector2((c + 0.5) * TILE, (r + 0.5) * TILE)

func _mark(c: int, r: int) -> void:
	if c >= 0 and c < CW and r >= 0 and r < CH:
		_solid[c + r * 1000] = true

func _unmark(c: int, r: int) -> void:
	_solid.erase(c + r * 1000)

func _mark_rect(c0: int, r0: int, c1: int, r1: int) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_mark(c, r)

func _unmark_rect(c0: int, r0: int, c1: int, r1: int) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_unmark(c, r)

func _pe(c: int, r: int, t: String) -> void:
	if c >= 0 and c < CW and r >= 0 and r < CH:
		_tm.set_cell(0, Vector2i(c, r), 0, T[t])

func _ps(c: int, r: int, t: String) -> void:
	if c >= 0 and c < CW and r >= 0 and r < CH:
		_tm_stone.set_cell(0, Vector2i(c, r), 0, STONE[t])

func _pe_rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_pe(c, r, t)

func _ps_rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_ps(c, r, t)

func _pe_mix(c0: int, r0: int, c1: int, r1: int, main_t: String, main_w: float,
		alt_t: String, alt2_t: String = "") -> void:
	# Nen chinh + cac MANG (patch) tile phu cum lai huu co — tron theo tung o
	# se tao hieu ung mosaic bi bac, nen phai ve theo cum elip 1-2 o.
	_pe_rect(c0, r0, c1, r1, main_t)
	var area := float((c1 - c0 + 1) * (r1 - r0 + 1))
	var n_alt := int(area * (1.0 - main_w) / 9.0)
	for i in n_alt:
		_pe_patch(_rng.randi_range(c0, c1), _rng.randi_range(r0, r1),
			_rng.randi_range(1, 2), _rng.randi_range(1, 2), alt_t, c0, r0, c1, r1)
	if alt2_t != "":
		var n_alt2 := int(area * (1.0 - main_w) / 26.0)
		for i in n_alt2:
			_pe_patch(_rng.randi_range(c0, c1), _rng.randi_range(r0, r1),
				1, 1, alt2_t, c0, r0, c1, r1)

func _pe_patch(cc: int, cr: int, rx: int, ry: int, t: String,
		c0: int, r0: int, c1: int, r1: int) -> void:
	for c in range(cc - rx, cc + rx + 1):
		for r in range(cr - ry, cr + ry + 1):
			if c < c0 or c > c1 or r < r0 or r > r1:
				continue
			var dx := float(c - cc) / maxf(1.0, float(rx))
			var dy := float(r - cr) / maxf(1.0, float(ry))
			if dx * dx + dy * dy <= 1.0 and _rng.randf() < 0.88:
				_pe(c, r, t)

func _prop(tex_name: String, ground: Vector2, scl: float = 1.0, flip: bool = false,
		node_name: String = "", tint: Color = Color.WHITE) -> Node2D:
	var holder := Node2D.new()
	holder.position = ground
	holder.y_sort_enabled = true
	_seq += 1
	holder.name = node_name if node_name != "" else ("Prop_%s_%03d" % [tex_name, _seq])
	var tex: Texture2D = load("res://assets/props/" + tex_name + ".png")
	if tex == null:
		print("[SOLMARIS-CITY] LOI: khong load duoc texture ", tex_name)
		_fail = true
		return holder
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.position = Vector2(0, -tex.get_height() * scl / 2.0 + 8.0)
	sp.scale = Vector2(scl, scl)
	sp.flip_h = flip
	sp.modulate = tint
	_root.add_child(holder)
	holder.add_child(sp)
	sp.owner = _root
	holder.owner = _root
	return holder

func _prop_centered(tex_name: String, center: Vector2, node_name: String) -> Node2D:
	var holder := Node2D.new()
	holder.position = center
	holder.name = node_name
	var sp := Sprite2D.new()
	sp.texture = load("res://assets/props/" + tex_name + ".png")
	if sp.texture == null:
		print("[SOLMARIS-CITY] LOI: khong load duoc texture ", tex_name)
		_fail = true
	_root.add_child(holder)
	holder.add_child(sp)
	sp.owner = _root
	holder.owner = _root
	return holder

func _label(text: String, cell: Vector2, size: int = 20) -> void:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", Color(1, 0.96, 0.8))
	lb.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	lb.add_theme_constant_override("shadow_offset_x", 2)
	lb.add_theme_constant_override("shadow_offset_y", 2)
	lb.position = _cc(cell.x, cell.y) + Vector2(-200, -18)
	lb.z_index = 6
	lb.name = "Label_" + text
	_root.add_child(lb)
	lb.owner = _root

# Nha/module: sprite rong w_tiles o, chan o hang bottom (va cham depth hang day)
func _building(tex_name: String, left_c: int, bottom_r: int, w_tiles: int,
		depth: int = 2, flip: bool = false, tint: Color = Color.WHITE) -> void:
	var ground := Vector2(ORIGIN.x + (left_c + w_tiles / 2.0) * TILE,
		ORIGIN.y + (bottom_r + 1) * TILE)
	_prop(tex_name, ground, 1.0, flip, "", tint)
	_mark_rect(left_c, bottom_r - depth + 1, left_c + w_tiles - 1, bottom_r)

func _stall(tex_name: String, left_c: int, bottom_r: int, w_tiles: int, scl: float = 1.0) -> void:
	var ground := Vector2(ORIGIN.x + (left_c + w_tiles / 2.0) * TILE,
		ORIGIN.y + (bottom_r + 1) * TILE)
	_prop(tex_name, ground, scl, _rng.randf() < 0.3)
	_mark_rect(left_c, bottom_r - 1, left_c + w_tiles - 1, bottom_r)
	_stall_count += 1

func _tent(cell: Vector2) -> void:
	_prop("tribal_tent", _cc(cell.x, cell.y), 1.0)
	_mark_rect(int(cell.x) - 2, int(cell.y) - 1, int(cell.x) + 1, int(cell.y) + 1)

func _signi(v: int) -> int:
	return 0 if v == 0 else (1 if v > 0 else -1)

func _road_line(c0: int, r0: int, c1: int, r1: int) -> void:
	var dc := _signi(c1 - c0)
	var dr := _signi(r1 - r0)
	var c := c0
	var r := r0
	while true:
		for o in [0, 1]:
			var cc2: int = c + (o if dc == 0 else 0)
			var rr2: int = r + (o if dr == 0 else 0)
			_pe(cc2, rr2, "stone_floor" if _rng.randf() < 0.55 else "cracked")
			_unmark(cc2, rr2)
			_water.erase(cc2 + rr2 * 1000)
		if c == c1 and r == r1:
			break
		c += dc
		r += dr

func _road(points: Array) -> void:
	for i in range(points.size() - 1):
		var a: Vector2i = points[i]
		var b: Vector2i = points[i + 1]
		_road_line(a.x, a.y, b.x, a.y)
		_road_line(b.x, a.y, b.x, b.y)

func _save_scene() -> void:
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err != OK:
		print("[SOLMARIS-CITY] PACK LOI: ", err)
		_fail = true
		return
	err = ResourceSaver.save(packed, SAVE_PATH)
	print("[SOLMARIS-CITY] save err=", err, " -> ", SAVE_PATH)
	if err != OK:
		_fail = true

# ---------------- build chinh ----------------

func _build() -> void:
	_root = Node2D.new()
	_root.name = "Solmaris"
	_root.y_sort_enabled = true
	_root.set_script(load("res://systems/map_root.gd"))
	add_child(_root)
	_tm = TileMap.new()
	_tm.name = "GroundTiles"
	_tm.z_index = -10
	_tm.position = ORIGIN
	_tm.tile_set = load("res://assets/tilesets/desert_v1.tres")
	_root.add_child(_tm)
	_tm.owner = _root
	_tm_stone = TileMap.new()
	_tm_stone.name = "StoneTiles"
	_tm_stone.z_index = -9
	_tm_stone.position = ORIGIN
	_tm_stone.tile_set = load("res://assets/tilesets/interior_tavern_v1.tres")
	_root.add_child(_tm_stone)
	_tm_stone.owner = _root

	_paint_ground()
	_build_walls()
	_build_council()
	_build_water_tower()
	_build_bazaar()
	_build_oasis()
	_build_caravan()
	_build_temple()
	_build_residential()
	_build_stables()
	_build_tribal()
	_scatter_decor()
	_build_collision()
	_build_portals_spawns()
	_build_npcs()
	_build_player_hud()
	_save_scene()

func _paint_ground() -> void:
	# Nen cat hoang toan map voi bien the ngau nhien
	for c in CW:
		for r in CH:
			var v := _rng.randf()
			var t := "sand"
			if v < 0.08:
				t = "dune"
			elif v < 0.11:
				t = "rocky"
			elif v < 0.15:
				t = "dry_grass"
			elif v < 0.185:
				t = "scrub"
			elif v < 0.20:
				t = "bone"
			_pe(c, r, t)
	# Nen dat nen trong thanh (cat dam + dat nut rai rac)
	_pe_mix(13, 13, 206, 158, "sand_pad", 0.68, "sand", "cracked")
	# Nen tung khu
	_pe_mix(33, 50, 98, 126, "cracked", 0.45, "sand_pad", "sand") # bazaar
	_pe_mix(146, 53, 204, 114, "sand_pad", 0.6, "cracked", "bone") # caravan
	_pe_mix(23, 126, 98, 154, "sand_pad", 0.66, "sand", "cracked") # dan cu
	_pe_mix(104, 126, 180, 154, "dry_grass", 0.4, "sand_pad", "sand") # chuong/xuong
	_pe_mix(212, 44, 238, 124, "sand", 0.6, "dune", "scrub") # khu bo lac
	# San da: phu hoi dong + den phong an
	_ps_rect(78, 16, 167, 53, "floor")
	_ps_rect(14, 64, 32, 106, "floor")
	# Duong chinh: Cong Dong -> nam Caravan -> bac Oc Dao -> bac Cho ->
	# Den / Cong Tay (vong tranh mat ho o tam)
	_road([Vector2i(208, 84), Vector2i(192, 84), Vector2i(192, 106),
		Vector2i(164, 106), Vector2i(164, 64), Vector2i(140, 64),
		Vector2i(140, 60), Vector2i(72, 60), Vector2i(72, 66),
		Vector2i(40, 66), Vector2i(40, 84), Vector2i(11, 84)])
	# Duong nhanh: xuong dan cu / chuong lac da + ra oc dao phia nam
	_road([Vector2i(60, 66), Vector2i(60, 130)])
	_road([Vector2i(164, 106), Vector2i(164, 140), Vector2i(140, 140)])
	_road([Vector2i(121, 96), Vector2i(121, 128)])
	# Duong caravan ngoai tuong dong toi khu bo lac (dat nen, khong lat da)
	_pe_mix(210, 81, 238, 88, "sand_pad", 0.55, "cracked", "sand")

func _build_walls() -> void:
	# Tuong sa thach day 3 o (layout muc 2)
	_pe_rect(10, 10, 209, 12, "stone_brick")
	_pe_rect(10, 159, 209, 161, "stone_brick")
	_pe_rect(10, 10, 12, 161, "stone_brick")
	_pe_rect(207, 10, 209, 161, "stone_brick")
	_mark_rect(10, 10, 209, 12)
	_mark_rect(10, 159, 209, 161)
	_mark_rect(10, 10, 12, 161)
	_mark_rect(207, 10, 209, 161)
	# Cong Dong hang 78-91, cong Tay nho hang 80-89
	_unmark_rect(207, 78, 209, 91)
	_unmark_rect(10, 80, 12, 89)
	_pe_mix(207, 78, 209, 91, "stone_floor", 0.6, "cracked")
	_pe_mix(10, 80, 12, 89, "stone_floor", 0.6, "cracked")
	# Thap canh goc + giua doan (sprite tower doi mau cat bang modulate)
	var sand_tint := Color(1.05, 0.92, 0.72)
	for corner in [[11, 12], [208, 12], [11, 159], [208, 159], [110, 12], [110, 159]]:
		_prop("tower", _cc(corner[0], corner[1]) + Vector2(0, TILE), 0.9, false,
			"WallTower_%d_%d" % [corner[0], corner[1]], sand_tint)
	# Co + den 2 ben cong
	_prop("banner", _cc(205, 76), 1.0, false, "GateBannerE1")
	_mark(205, 76)
	_prop("banner", _cc(205, 93), 1.0, false, "GateBannerE2")
	_mark(205, 93)
	_prop("lamp", _cc(213, 79), 1.15, false, "GateLampE1")
	_mark(213, 79)
	_prop("lamp", _cc(213, 90), 1.15, false, "GateLampE2")
	_mark(213, 90)
	_prop("lamp", _cc(14, 79), 1.1, false, "GateLampW1")
	_mark(14, 79)
	_prop("lamp", _cc(14, 90), 1.1, false, "GateLampW2")
	_mark(14, 90)
	_label("SOLMARIS", Vector2(196, 72), 34)
	_label("CONG TAY", Vector2(20, 74), 16)

func _build_council() -> void:
	# Phu Hoi Dong Linh Danh Thue: module lon o tam bac (KHONG cung dien vua)
	_building("solmaris_council", 114, 38, 16, 3)
	# 2 canh phu: doanh linh + kho vu khi (nha dat nung lech hang 0-2 o)
	_building("solmaris_house_a", 84, 36, 6)
	_building("solmaris_house_c", 97, 37, 5, 2, true)
	_building("solmaris_house_b", 133, 36, 7)
	_building("solmaris_house_a", 149, 37, 6, 2, true, Color(1.0, 0.94, 0.86))
	# San dieu binh + NGAI TRONG phu vai o san truoc phu
	_prop_centered("solmaris_throne", _cc(121.5, 41), "NgaiTrong")
	_mark_rect(121, 40, 122, 41)
	_prop("banner", _cc(110, 40), 1.0, false, "CouncilBannerL")
	_mark(110, 40)
	_prop("banner", _cc(134, 40), 1.0, true, "CouncilBannerR")
	_mark(134, 40)
	_prop("dummy", _cc(100, 44), 1.1, false, "CouncilDummy1")
	_mark(100, 44)
	_prop("dummy", _cc(144, 44), 1.1, true, "CouncilDummy2")
	_mark(144, 44)
	_prop("shelf", _cc(90, 42), 1.1, false, "WeaponRack")
	_mark(90, 42)
	_prop("barrel", _cc(158, 43), 1.0, false, "CouncilBarrel1")
	_prop("wine_barrel", _cc(160, 44), 1.0, false, "CouncilBarrel2")
	_label("PHU HOI DONG LINH DANH THUE", Vector2(122, 27), 22)
	_label("NGAI TRONG — VUA DA CHET", Vector2(121, 45), 14)

func _build_water_tower() -> void:
	# Thap Nuoc + Ham Chua (18-48 x 20-48): hoi dong giu nuoc = giu quyen
	_building("solmaris_water_tower", 24, 34, 4, 2)
	_building("solmaris_house_b", 34, 46, 7)
	_building("solmaris_house_a", 19, 47, 6, 2, true)
	_prop("well", _cc(30, 40), 1.1, false, "WaterVaultWell")
	_mark_rect(29, 39, 31, 40)
	_prop("barrel", _cc(36, 38), 1.0, false, "WaterBarrel1")
	_prop("barrel", _cc(38, 39), 1.0, false, "WaterBarrel2")
	_prop("wine_barrel", _cc(44, 41), 1.0, false, "WaterBarrel3")
	_prop("sack", _cc(42, 38), 1.1, false, "WaterSack")
	_prop("lamp", _cc(32, 36), 1.1, false, "WaterLamp")
	_mark(32, 36)
	_label("THAP NUOC", Vector2(33, 18), 20)

func _build_bazaar() -> void:
	# GRAND BAZAAR (35-96 x 52-124): 3 day sap chinh + day an dem + 2 sap ria bac
	_stall("solmaris_stall_a", 42, 58, 5)
	_stall("solmaris_stall_b", 85, 58, 4)
	_bazaar_band(71, 37, 93)
	_bazaar_band(87, 38, 94)
	_bazaar_band(103, 37, 93)
	_bazaar_band(119, 40, 70)
	# Bang nhiem vu tai (66,56) - ngay ria bac cho, canh duong chinh
	_prop("table", _cc(66, 56), 1.15, false, "QuestBoard")
	_mark_rect(65, 55, 67, 56)
	_prop("banner", _cc(62, 57), 1.0, false, "BoardBanner")
	_mark(62, 57)
	_label("BANG NHIEM VU", Vector2(66, 52), 16)
	# Khu an dem (nam cho): bep lua + ban ghe + den long
	_prop("fireplace", _cc(72, 114), 1.4, false, "NightFoodFire")
	_mark_rect(71, 113, 73, 114)
	_prop("table", _cc(64, 116), 1.0, false, "FoodTable1")
	_mark(64, 116)
	_prop("table", _cc(80, 116), 1.0, true, "FoodTable2")
	_mark(80, 116)
	_prop("bench", _cc(64, 118), 1.0, false, "FoodBench1")
	_mark(64, 118)
	_prop("bench", _cc(80, 118), 1.0, false, "FoodBench2")
	_mark(80, 118)
	_prop("lamp", _cc(58, 110), 1.1, false, "FoodLamp1")
	_mark(58, 110)
	_prop("lamp", _cc(86, 110), 1.1, false, "FoodLamp2")
	_mark(86, 110)
	_prop("barrel", _cc(88, 118), 1.0, false, "FoodBarrel")
	_prop("sack", _cc(56, 120), 1.1, false, "FoodSack")
	_label("GRAND BAZAAR", Vector2(65, 63), 22)
	_label("KHU AN DEM", Vector2(72, 108), 15)

func _bazaar_band(bottom_r: int, c_start: int, c_end: int) -> void:
	var variants := [
		["solmaris_stall_a", 5, 1.0], ["solmaris_stall_b", 4, 1.0],
		["stall_a", 5, 0.8], ["stall_c", 5, 0.8], ["stall_d", 5, 0.8],
		["solmaris_stall_a", 5, 1.0], ["solmaris_stall_b", 4, 1.0],
	]
	var c := c_start + _rng.randi_range(0, 1)
	while c <= c_end - 4:
		# Hem/ngo nghi bat quy tac giua cac sap
		if _rng.randf() < 0.16:
			var g := _rng.randi_range(1, 3)
			if _rng.randf() < 0.5 and c + 1 <= c_end:
				_prop("barrel" if _rng.randf() < 0.5 else "sack",
					_cc(c + 1, bottom_r), 0.95, false)
			c += g
			continue
		var v: Array = variants[_rng.randi_range(0, variants.size() - 1)]
		var w: int = int(v[1])
		if c + w - 1 > c_end:
			break
		_stall(str(v[0]), c, bottom_r, w, float(v[2]))
		c += w + (0 if _rng.randf() < 0.4 else 1)

func _build_oasis() -> void:
	# Oc dao that: ho nuoc elip tam (121,84) ban kinh 12x9, co va cham
	for c in range(104, 140):
		for r in range(66, 104):
			var d := Vector2((c - 121) / 12.0, (r - 84) / 9.0).length()
			if d <= 1.0:
				_pe(c, r, "water_a" if (c + r) % 2 == 0 else "water_b")
				_water[c + r * 1000] = true
				_mark(c, r)
	# Bo ho: o sat nuoc doi sang tile shore theo huong
	for c in range(102, 142):
		for r in range(64, 106):
			if _water.has(c + r * 1000):
				continue
			if _water.has(c + (r + 1) * 1000):
				_pe(c, r, "shore_s")
			elif _water.has(c + (r - 1) * 1000):
				_pe(c, r, "shore_n")
			elif _water.has((c - 1) + r * 1000):
				_pe(c, r, "shore_w")
			elif _water.has((c + 1) + r * 1000):
				_pe(c, r, "shore_e")
	# Dai phun o tam ho
	_prop_centered("fountain", _cc(121, 84), "DaiPhunTrungTam")
	# Cay cha la quanh ho + ghe + den
	for tp in [[106, 72], [136, 72], [106, 96], [136, 96], [121, 71], [110, 68], [132, 68], [110, 100], [132, 100]]:
		_prop("palm_tree", _cc(tp[0], tp[1]), _rng.randf_range(0.9, 1.05), _rng.randf() < 0.5,
			"OasisPalm_%d_%d" % [tp[0], tp[1]])
		_mark(tp[0], tp[1])
	for bp in [[113, 74], [129, 74], [113, 94], [129, 94]]:
		_prop("bench", _cc(bp[0], bp[1]), 1.0, false, "OasisBench_%d_%d" % [bp[0], bp[1]])
		_mark(bp[0], bp[1])
	_prop("lamp", _cc(108, 84), 1.1, false, "OasisLampW")
	_mark(108, 84)
	_prop("lamp", _cc(134, 84), 1.1, false, "OasisLampE")
	_mark(134, 84)
	# Diem hen lien minh: lua + co o bo nam ho
	_prop("campfire", _cc(123, 97), 1.0, false, "AllianceFire")
	_mark(123, 97)
	_prop("banner", _cc(117, 96), 1.0, false, "AllianceBannerL")
	_mark(117, 96)
	_prop("banner", _cc(127, 96), 1.0, true, "AllianceBannerR")
	_mark(127, 96)
	_label("OC DAO TRUNG TAM", Vector2(121, 63), 20)
	_label("DIEM HEN LIEN MINH", Vector2(121, 100), 15)

func _build_caravan() -> void:
	# Khu Caravan + Kho (148-202 x 55-112): kho dat nung + leu caravan + hang hoa
	_building("solmaris_house_b", 152, 70, 7)
	_building("solmaris_house_a", 168, 68, 6, 2, true)
	_building("solmaris_house_c", 182, 70, 5)
	_building("solmaris_house_b", 156, 100, 7, 2, true, Color(0.97, 0.92, 0.85))
	_building("solmaris_house_a", 176, 102, 6)
	_tent(Vector2(197, 63))
	_tent(Vector2(197, 97))
	_prop("chest", _cc(170, 84), 1.0, false, "CargoChest1")
	_mark(170, 84)
	_prop("chest", _cc(172, 85), 1.0, false, "CargoChest2")
	_mark(172, 85)
	_prop("sack", _cc(158, 84), 1.1, false, "CargoSack1")
	_prop("sack", _cc(186, 88), 1.1, false, "CargoSack2")
	_prop("barrel", _cc(160, 88), 1.0, false, "CargoBarrel1")
	_prop("barrel", _cc(184, 78), 1.0, false, "CargoBarrel2")
	_prop("table", _cc(180, 90), 1.0, false, "CargoTable")
	_mark(180, 90)
	_prop("lamp", _cc(166, 76), 1.1, false, "CargoLamp")
	_mark(166, 76)
	_label("KHU CARAVAN & KHO", Vector2(175, 57), 20)

func _build_temple() -> void:
	# Den Cong Phong An (15-30 x 66-104) sat cong Tay: giu ban sao loi the Vesskar
	_building("solmaris_house_c", 17, 78, 5, 2, false, Color(1.02, 0.98, 0.9))
	_prop("statue", Vector2(ORIGIN.x + 23.5 * TILE, ORIGIN.y + 87 * TILE), 0.75, false, "SealStatue")
	_mark_rect(22, 85, 24, 86)
	_prop("campfire", _cc(19, 96), 0.85, false, "TempleGlow")
	_mark(19, 96)
	_prop("banner", _cc(16, 84), 1.0, false, "TempleBannerL")
	_mark(16, 84)
	_prop("banner", _cc(30, 84), 1.0, true, "TempleBannerR")
	_mark(30, 84)
	_prop("lamp", _cc(20, 100), 1.05, false, "TempleLamp")
	_mark(20, 100)
	_label("DEN CONG PHONG AN", Vector2(23, 62), 18)
	_label("BAN SAO LOI THE VESSKAR", Vector2(23, 93), 13)

func _build_residential() -> void:
	# Khu Nha Dat Nung (25-96 x 128-152): 2 day nha lech hang + san trong
	_house_row_organic(27, 92, 138, [59, 60, 61])
	_house_row_organic(30, 94, 150, [45])
	# San trong bat quy tac: gieng + ghe + day phoi + cay
	_prop("well", _cc(48, 144), 1.0, false, "CourtWell")
	_mark_rect(47, 143, 49, 144)
	_prop("bench", _cc(44, 145), 1.0, false, "CourtBench")
	_mark(44, 145)
	_prop("laundry", _cc(53, 143), 1.0, false, "CourtLaundry")
	_prop("small_tree", _cc(84, 144), 1.1, false, "CourtTree")
	_mark(84, 143)
	_prop("flower_bed", _cc(36, 145), 0.9, false, "CourtBed")
	_prop("barrel", _cc(66, 144), 1.0, false, "CourtBarrel")
	_prop("lamp", _cc(58, 141), 1.05, false, "CourtLamp")
	_mark(58, 141)
	_label("KHU NHA DAT NUNG", Vector2(60, 126), 17)

func _house_row_organic(x0: int, x1: int, bottom_r: int, reserved: Array) -> void:
	var tints := [Color.WHITE, Color(1.0, 0.94, 0.86), Color(0.96, 0.9, 0.94), Color(1.03, 0.97, 0.88)]
	var c := x0 + _rng.randi_range(0, 1)
	while c <= x1 - 5:
		if _rng.randf() < 0.15:
			var g := _rng.randi_range(1, 3)
			if g >= 2 and c + 1 <= x1:
				_prop("bush" if _rng.randf() < 0.4 else "barrel", _cc(c + 1, bottom_r), 0.85,
					false)
			c += g
			continue
		var v: Array = ADOBE[_rng.randi_range(0, ADOBE.size() - 1)]
		var w: int = int(v[1])
		if c + w - 1 > x1:
			break
		var clash := false
		for rc in reserved:
			if int(rc) >= c and int(rc) <= c + w - 1:
				clash = true
		if clash:
			c += 1
			continue
		_building(str(v[0]), c, bottom_r, w, 2, _rng.randf() < 0.35,
			tints[_rng.randi_range(0, tints.size() - 1)])
		c += w

func _build_stables() -> void:
	# Chuong Lac Da + Xuong Da (106-178 x 128-152)
	_building("solmaris_house_a", 112, 138, 6)
	_building("solmaris_house_b", 150, 140, 7, 2, true)
	_prop("laundry", _cc(130, 142), 1.0, false, "HideRack1")
	_prop("laundry", _cc(137, 142), 1.0, true, "HideRack2")
	_prop("shelf", _cc(146, 142), 1.05, false, "SaddleShelf")
	_mark(146, 142)
	_prop("barrel", _cc(160, 144), 1.0, false, "StableBarrel")
	# 2 bai quây: xuong + da lam "hang rao" thap + mang an (ban) + rom (bao)
	_prop("bone_rib", _cc(108, 145), 0.85, false, "PenRib1")
	_prop("bone_rib", _cc(124, 152), 0.85, true, "PenRib2")
	_prop("bone_rib", _cc(134, 145), 0.85, false, "PenRib3")
	_prop("bone_rib", _cc(156, 150), 0.85, true, "PenRib4")
	_prop("table", _cc(118, 149), 0.95, false, "Trough1")
	_mark(118, 149)
	_prop("table", _cc(144, 149), 0.95, false, "Trough2")
	_mark(144, 149)
	_prop("sack", _cc(114, 147), 1.1, false, "HaySack1")
	_prop("sack", _cc(148, 147), 1.1, false, "HaySack2")
	_prop("boulder", _cc(170, 148), 0.9, false, "StableRock")
	_mark(170, 147)
	_label("CHUONG LAC DA & XUONG DA", Vector2(142, 126), 17)

func _build_tribal() -> void:
	# KHU BO LAC NGOAI TUONG DONG (214-236 x 48-122) - van trong scene thanh
	_tent(Vector2(221, 54))
	_tent(Vector2(230, 58))
	_tent(Vector2(234, 68))
	_tent(Vector2(219, 70))
	_tent(Vector2(221, 106))
	_tent(Vector2(231, 110))
	_tent(Vector2(224, 118))
	_prop("campfire", _cc(225, 60), 1.0, false, "TribalFireN")
	_mark(225, 60)
	_prop("campfire", _cc(226, 112), 1.0, false, "TribalFireS")
	_mark(226, 112)
	_prop("statue", _cc(225, 78), 0.55, false, "TribalTotem")
	_mark(225, 77)
	# Bai san phia nam: hinh nom + xuong + da
	_prop("dummy", _cc(231, 98), 1.0, false, "HuntDummy1")
	_mark(231, 98)
	_prop("dummy", _cc(236, 104), 1.0, true, "HuntDummy2")
	_mark(236, 104)
	_prop("bone_rib", _cc(218, 96), 0.9, false, "HuntBones1")
	_prop("bone_rib", _cc(236, 96), 0.9, true, "HuntBones2")
	_prop("cactus", _cc(216, 50), 0.95, false, "TribalCactus1")
	_mark(216, 49)
	_prop("cactus", _cc(237, 76), 0.9, false, "TribalCactus2")
	_mark(237, 75)
	# Ho nuoc nho cua bo lac (co va cham)
	for c in range(229, 238):
		for r in range(118, 125):
			var d := Vector2((c - 233) / 3.0, (r - 121) / 2.0).length()
			if d <= 1.0:
				_pe(c, r, "water_a" if (c + r) % 2 == 0 else "water_b")
				_mark(c, r)
	_prop("palm_tree", _cc(229, 117), 0.9, false, "TribalPalm1")
	_mark(229, 116)
	_prop("palm_tree", _cc(236, 124), 0.9, true, "TribalPalm2")
	_mark(236, 123)
	_label("KHU BO LAC NGOAI TUONG", Vector2(225, 44), 19)
	_label("BAI SAN", Vector2(226, 92), 13)

func _scatter_decor() -> void:
	# Den doc duong chinh (lech khoi mat duong 2 o)
	for lp in [[196, 80], [180, 102], [166, 70], [150, 62], [128, 58], [100, 62],
			[84, 63], [52, 63], [44, 80], [120, 124], [162, 124], [196, 88]]:
		_prop("lamp", _cc(lp[0], lp[1]), 1.05, false, "RoadLamp_%d_%d" % [lp[0], lp[1]])
		_mark(lp[0], lp[1])
	# Cay dua + xuong + da ven tuong ngoai va goc hoang
	for dp in [[6, 40], [6, 120], [100, 5], [180, 5], [60, 165], [150, 165], [216, 130], [236, 140]]:
		_prop("cactus" if _rng.randf() < 0.6 else "boulder", _cc(dp[0], dp[1]),
			_rng.randf_range(0.85, 1.1), _rng.randf() < 0.5, "EdgeDeco_%d_%d" % [dp[0], dp[1]])
		_mark(dp[0], dp[1])
	for pp in [[16, 56], [100, 118], [204, 120]]:
		_prop("palm_tree", _cc(pp[0], pp[1]), 0.95, _rng.randf() < 0.5,
			"StreetPalm_%d_%d" % [pp[0], pp[1]])
		_mark(pp[0], pp[1])

func _build_collision() -> void:
	# Vien map ao: khong cho thoat khoi scene
	_mark_rect(0, 0, CW - 1, 0)
	_mark_rect(0, CH - 1, CW - 1, CH - 1)
	_mark_rect(0, 0, 0, CH - 1)
	_mark_rect(CW - 1, 0, CW - 1, CH - 1)
	var body := StaticBody2D.new()
	body.name = "WorldCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	_root.add_child(body)
	body.owner = _root
	for r in CH:
		var c := 0
		while c < CW:
			if _solid.has(c + r * 1000):
				var c0 := c
				while c < CW and _solid.has(c + r * 1000):
					c += 1
				var cs := CollisionShape2D.new()
				var shape := RectangleShape2D.new()
				shape.size = Vector2((c - c0) * TILE, TILE)
				cs.shape = shape
				cs.position = ORIGIN + Vector2((c0 + (c - c0) / 2.0) * TILE, (r + 0.5) * TILE)
				body.add_child(cs)
				cs.owner = _root
			else:
				c += 1
	print("[SOLMARIS-CITY] collision shapes: ", body.get_child_count(), ", solid cells: ", _solid.size())

func _build_portals_spawns() -> void:
	var portal_ps: PackedScene = load("res://systems/portal.tscn")
	var defs := [
		["PortalEastGate", Vector2(208, 84), "res://maps/westgate.tscn", "from_solmaris", "", "Westgate — Duong Caravan"],
		["PortalWestGate", Vector2(11, 84), "res://maps/buried_sand_ruins.tscn", "from_solmaris", "", "Buried Sand Ruins"],
	]
	for d in defs:
		var p: Node = portal_ps.instantiate()
		p.name = d[0]
		p.position = _cc(d[1].x, d[1].y)
		p.set("target_scene", d[2])
		p.set("target_spawn", d[3])
		p.set("required_flag", d[4])
		p.set("label_text", d[5])
		_root.add_child(p)
		p.owner = _root
	var spawns := [
		["Spawn_start", Vector2(204, 84)],
		["Spawn_from_approach", Vector2(204, 84)],
		["Spawn_from_lair", Vector2(16, 84)],
	]
	for s in spawns:
		var m := Marker2D.new()
		m.name = s[0]
		m.position = _cc(s[1].x, s[1].y)
		_root.add_child(m)
		m.owner = _root

# ---------------- NPC ----------------

func _sa(arr: Array) -> Array[String]:
	var out: Array[String] = []
	for s in arr:
		out.append(str(s))
	return out

func _npc(node_name: String, npc_id: String, display: String, spawn_cell: Vector2,
		tint: Color, spd: float, quests: Array, shop: bool, dlg: Dictionary,
		steps: Array) -> void:
	var ps: PackedScene = load("res://systems/npc.tscn")
	var n: Node = ps.instantiate()
	n.name = node_name
	n.position = _cc(spawn_cell.x, spawn_cell.y)
	n.set("npc_id", npc_id)
	n.set("display_name", display)
	n.set("quest_ids", _sa(quests))
	n.set("shop_enabled", shop)
	n.set("tint", tint)
	n.set("speed", spd)
	n.set("dialogue_before", _sa(dlg.get("before", [])))
	n.set("dialogue_active", _sa(dlg.get("active", [])))
	n.set("dialogue_ready", _sa(dlg.get("ready", [])))
	n.set("dialogue_done", _sa(dlg.get("done", [])))
	var sch: Array[Dictionary] = []
	for s in steps:
		var p := _cc(float(s[0]), float(s[1]))
		sch.append({"x": p.x, "y": p.y, "action": str(s[2]), "time": float(s[3])})
	n.set("schedule", sch)
	n.set("schedule_enabled", true)
	_root.add_child(n)
	n.owner = _root

func _build_npcs() -> void:
	# Kassia Vane: dai dien hoi dong o phu (NPC tinh, chi di lai trong san phu).
	# npc_id co hau to _thanh de phan biet voi boss dau truong Kassia o Redrock.
	_npc("NPC_KassiaVane", "kassia_vane_thanh", "Kassia Vane, Chi Huy Hoi Dong", Vector2(122, 44),
		Color(1.0, 0.82, 0.66), 50.0, [], false,
		{"before": ["Ta la Kassia Vane. Hoi dong noi thay ngai trong kia — cai ngai phu vai, vi vua Solmaris chet lau roi, chang ai ngoi nua.",
					"Muon danh voi ta thi ra dau truong Redrock, truoc mat dan va hai bo lac. Trong phu nay, ta chi noi chuyen."],
		 "done": ["O Solmaris, nuoc la quyen luc, va hoi dong dang giu ca hai. Nguoi se thay dieu do o Thap Nuoc truoc khi thay o dau truong."]},
		[[122, 44, "idle", 8], [119, 44, "walk", 4], [125, 44, "walk", 4], [122, 42, "work", 6]])
	# 2 truong lao bo lac: nha o khu bo lac ngoai tuong, diem hen o dai phun
	_npc("NPC_TruongLaoDieuCat", "truong_lao_dieu_cat_thanh", "Truong Lao Sefra — Dieu Cat", Vector2(224, 64),
		Color(1.0, 0.74, 0.5), 56.0, [], false,
		{"done": ["Dieu Cat song ngoai tuong, nhung uong nuoc trong tuong. Nguoi thay su vo ly do chua?",
					"Khi lien minh hop o dai phun, ta se o do. Bo lac khong quy truoc hoi dong nua."]},
		[[224, 64, "work", 9], [216, 70, "walk", 5], [208, 84, "walk", 6], [196, 84, "walk", 5],
		 [175, 84, "walk", 6], [160, 70, "walk", 5], [140, 68, "walk", 5], [126, 72, "walk", 4],
		 [120, 74, "idle", 10], [126, 72, "walk", 4], [148, 66, "walk", 5], [170, 80, "walk", 5],
		 [196, 84, "walk", 5], [210, 84, "walk", 5], [220, 70, "walk", 5]])
	_npc("NPC_TruongLaoDaVang", "truong_lao_da_vang_thanh", "Truong Lao Bramok — Da Vang", Vector2(228, 114),
		Color(0.8, 0.72, 1.0), 56.0, [], false,
		{"done": ["Da Vang nho loi the cua Vesskar chu khong nho mat hoi dong. Ai tra loi the, nguoi do co da cua ta.",
					"Ta hay dung o bo nam dai phun khi hop lien minh. Nuoc o do trong nhat thanh, va loi noi o do cung phai vay."]},
		[[228, 114, "work", 9], [222, 100, "walk", 5], [210, 90, "walk", 5], [200, 92, "walk", 5],
		 [180, 108, "walk", 6], [150, 108, "walk", 6], [132, 100, "walk", 5], [119, 97, "idle", 10],
		 [132, 100, "walk", 5], [160, 104, "walk", 6], [190, 96, "walk", 5], [206, 88, "walk", 5],
		 [218, 98, "walk", 5]])
	# Nguoi giu nuoc o Thap Nuoc
	_npc("NPC_GiuNuocThap", "nguoi_giu_nuoc_thap_thanh", "Nguoi Giu Nuoc — Mira Solen", Vector2(30, 42),
		Color(0.65, 0.9, 1.0), 52.0, [], false,
		{"done": ["Moi binh nuoc ra khoi thap nay deu qua so cua hoi dong. Dan khoc khan o ngoai, con so thi day.",
					"Ta chi la nguoi ghi so. Nhung ta ghi ca nhung gi hoi dong khong muon ai nho."]},
		[[30, 42, "work", 8], [26, 38, "walk", 4], [34, 42, "walk", 4], [40, 44, "idle", 5],
		 [30, 44, "walk", 4]])
	# Thuong nhan bazaar (1 nguoi mo shop)
	_npc("NPC_ThuongNhanVai", "thuong_nhan_vai_bazaar", "Thuong Nhan Vai — Oren Tal", Vector2(50, 73),
		Color(1.0, 0.88, 0.68), 52.0, [], true,
		{"done": ["Vai tot, lua tot, ca vai boc ngai trong cung co — nhung cai do ta khong ban, chi hoi dong moi co.",
					"Mua gi thi mua nhanh, gio phat nuoc sap toi, ca cho se chay ve Thap Nuoc het."]},
		[[50, 73, "work", 10], [54, 74, "idle", 3], [50, 73, "work", 9]])
	_npc("NPC_ThuongNhanGiaVi", "thuong_nhan_gia_vi_bazaar", "Thuong Nhan Nuoc & Gia Vi — Hessa Rill", Vector2(80, 89),
		Color(0.95, 0.78, 0.55), 52.0, [], false,
		{"done": ["Gia vi cua ta tinh bang vang. Nuoc cua hoi dong tinh bang long trung thanh. Nguoi do thu nao dat hon?",
					"Dem xuong khu an dem phia nam cho, bap nuong cua Sana se ke cho nguoi nghe gia nuoc that."]},
		[[80, 89, "work", 10], [76, 90, "idle", 3], [80, 89, "work", 9]])
	_npc("NPC_ThuongNhanDa", "thuong_nhan_da_bazaar", "Thuong Nhan Da & Vay — Corvath", Vector2(58, 105),
		Color(0.9, 0.66, 0.48), 52.0, [], false,
		{"done": ["Da lac da, vay ran, ca vay rong cat gia — tru mot thu that ma ca thanh chi dam thi tham: Vesskar.",
					"Hoi dong treo gia cho cai dau cua no. Ta thi nghi no dang cho ai do tra lai loi the hon la cho thoi de chet."]},
		[[58, 105, "work", 9], [62, 106, "idle", 3], [58, 105, "work", 8]])
	# Chu caravan
	_npc("NPC_ChuCaravan", "chu_caravan_thanh", "Chu Caravan — Darian Voss", Vector2(175, 82),
		Color(0.95, 0.85, 0.6), 58.0, [], false,
		{"done": ["Caravan cua ta chay tu Westgate toi tan Fenmire. Hoi dong thue ta, nhung lac da cua ta chi nghe tieng nuoc.",
					"Hang vao kho phai qua cong Dong va qua mat Kassia. Thieu mot trong hai, cat se giu hang lai."]},
		[[175, 82, "idle", 6], [186, 84, "walk", 5], [196, 84, "walk", 5], [188, 92, "idle", 4],
		 [175, 90, "walk", 5]])
	# Nguoi nuoi lac da
	_npc("NPC_NuoiLacDa", "nguoi_nuoi_lac_da_thanh", "Nguoi Nuoi Lac Da — Tomas Rhee", Vector2(140, 140),
		Color(0.88, 0.8, 0.62), 54.0, [], false,
		{"done": ["Lac da nhin nuoc truoc khi nhin chu. Chung biet thap nuoc dang can dan truoc ca dan thanh.",
					"Xuong da ben canh thom mui nang va mui hoi dong — hai mui do gan nhau lam."]},
		[[140, 140, "work", 8], [126, 142, "walk", 5], [118, 148, "idle", 4], [144, 148, "walk", 6],
		 [156, 142, "work", 6]])
	# Nguoi giu den Cong Phong An
	_npc("NPC_GiuDen", "nguoi_giu_den_thanh", "Nguoi Giu Den — Su Gia Anselm", Vector2(23, 92),
		Color(0.92, 0.88, 0.78), 48.0, [], false,
		{"done": ["Den nay giu ban sao loi the Vesskar the canh cong phong an. Hoi dong muon dot no ba lan roi.",
					"Vesskar khong the phuc vu hoi dong. No the canh cong — va giao uoc thi co the tra, khong nhat thiet phai giet nguoi giu."]},
		[[23, 92, "work", 8], [20, 84, "walk", 5], [26, 84, "idle", 4], [23, 88, "walk", 4]])
	# Linh danh thue gac cong Dong
	_npc("NPC_LinhGacDong", "linh_thue_gac_dong_thanh", "Linh Danh Thue Gac Cong Dong — Bram Kade", Vector2(203, 80),
		Color(0.85, 0.55, 0.45), 55.0, [], false,
		{"done": ["Cong Dong do ta gac: caravan vao, bo lac... dung ngoai. Lenh cua hoi dong ghi the, khong phai long ta.",
					"Hai truong lao van qua cong nay hop o dai phun. Ta mo cong, vi cat sap toi se khong hoi phep ai nua."]},
		[[203, 80, "idle", 6], [203, 88, "walk", 5], [200, 84, "idle", 4], [205, 84, "walk", 4]])
	# Dan bo lac ngoai tuong
	_npc("NPC_DanDieuCat", "dan_dieu_cat_thanh", "Dan Dieu Cat — Yara", Vector2(222, 66),
		Color(1.0, 0.8, 0.58), 54.0, [], false,
		{"done": ["Leu cua ta cach tuong muoi buoc, nhung cach mot binh nuoc ca mot doi nguoi.",
					"Truong lao Sefra noi nguoi ngoai vung nhu nguoi co the thay doi dieu do. Ta cho xem cat co nghe loi ba khong."]},
		[[222, 66, "work", 8], [226, 63, "idle", 4], [221, 68, "walk", 4]])
	_npc("NPC_ThoSanDaVang", "tho_san_da_vang_thanh", "Tho San Da Vang — Kolm", Vector2(228, 102),
		Color(0.85, 0.75, 0.6), 57.0, [], false,
		{"done": ["Ta tap ban o bai san nay moi sang. Muc tieu la hinh nom — tam thoi la the.",
					"Khi nao trong lien minh o dai phun noi len, Da Vang se co mat. Ca cung ten cua ta nua."]},
		[[228, 102, "work", 7], [233, 100, "idle", 4], [226, 106, "walk", 4]])
	# Dan cu khu nha dat nung
	_npc("NPC_DanCuElif", "dan_cu_elif_thanh", "Cu Dan — Elif Maro", Vector2(50, 142),
		Color(1.0, 0.9, 0.95), 50.0, [], false,
		{"done": ["Nha dat nung cua ta mat vao ban ngay, nong vao ban dem — nhu cai thanh nay, nguoc voi moi loi hua cua hoi dong.",
					"Nuoc gieng san trong la nuoc mua cu. Ca khu chia nhau tung gau, khong ai ghi so ca."]},
		[[50, 142, "work", 6], [46, 144, "idle", 4], [56, 141, "walk", 4]])
	_npc("NPC_ThoGom", "tho_gom_petr_thanh", "Tho Gom — Petr Halden", Vector2(75, 134),
		Color(0.9, 0.95, 1.0), 52.0, [], false,
		{"done": ["Ta lam binh dung nuoc cho ca khu. Binh cang tot, nguoi ta cang thay ro minh dang khac den the nao.",
					"Nghe noi truong lien minh dang tim nguoi. Neu la nguoi, nho mang theo mot binh nuoc day khi toi dai phun."]},
		[[75, 134, "work", 8], [70, 135, "idle", 3], [80, 134, "walk", 4]])
	# Dau bep khu an dem
	_npc("NPC_DauBepDem", "dau_bep_dem_thanh", "Dau Bep An Dem — Sana Vey", Vector2(72, 112),
		Color(1.0, 0.85, 0.7), 52.0, [], false,
		{"done": ["Khu an dem chi mo khi mat troi chet. Bap nuong, che dau, va tin tuc nong hon ca lua bep.",
					"Tin moi nhat: linh thue o Oc Dao dang tu hoi minh gac thap nuoc cho ai. Ta nghe trong luc nuong bap day."]},
		[[72, 112, "work", 9], [68, 115, "idle", 3], [76, 115, "walk", 4]])

func _build_player_hud() -> void:
	var player: Node = load("res://player/player.tscn").instantiate()
	player.name = "Player"
	player.position = _cc(204, 84)
	_root.add_child(player)
	player.owner = _root
	var hud: Node = load("res://ui/hud.tscn").instantiate()
	hud.name = "HUD"
	_root.add_child(hud)
	hud.owner = _root
