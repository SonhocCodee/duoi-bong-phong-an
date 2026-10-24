extends Node2D
## Tool mot lan: dung scene NOI THANH FROSTGARD 240x170 o theo layout da duyet
## (design/frostgard_layout.md): tuong da den + bang day 3 o, cong sat Nam mo,
## cong Bac DONG (khong portal), Ngai Bang + Sanh Vua Dong Bang, Nha Nguyen
## Khong Chuong + Thap Chuong (gia treo trong), Doanh Trai Hiep Si Bang,
## Nghia Trang Quan Doan + Dai Danh Sach Ten (bia mo thang hang - chu y),
## LO LON TRUNG TAM, Xuong Ren Thep Bang, Khu Dan Cu Dong Bang THUA
## (~1/3 nha co den), Diem Tap Ket Trung Thu canh cong Nam.
## Cau truc mo phong dung build_city.gd (Aldenmere): TileMap ground, prop +
## collision tu dict _solid, _build_portals_spawns, _npc co schedule,
## _build_player_hud. King Valdemar KHONG dat NPC o day (da o Approach).
## Chay: godot --headless --path game res://tools_paint/build_frostgard.tscn

const TILE := 64.0
const CW := 240
const CH := 170
const ORIGIN := Vector2(-7680.0, -5440.0)
const SAVE_PATH := "res://maps/frostgard.tscn"

const W := {
	"snow": Vector2i(0, 0), "drift": Vector2i(1, 0), "rocky_snow": Vector2i(2, 0),
	"ice": Vector2i(3, 0), "ice_shine": Vector2i(4, 0), "deep_ice": Vector2i(0, 1),
	"shore_s": Vector2i(1, 1), "shore_n": Vector2i(2, 1), "shore_w": Vector2i(3, 1),
	"shore_e": Vector2i(4, 1), "shore_cvx": Vector2i(0, 2), "shore_ccv": Vector2i(1, 2),
	"frost_grass": Vector2i(2, 2), "stone_floor": Vector2i(3, 2), "dark_brick": Vector2i(4, 2),
	"ash_snow": Vector2i(0, 3), "path_s": Vector2i(1, 3), "path_n": Vector2i(2, 3),
	"dead_scrub": Vector2i(3, 3), "packed_snow": Vector2i(4, 3),
}
const INT := {
	"floor_a": Vector2i(0, 0), "floor_b": Vector2i(1, 0), "floor_dark": Vector2i(2, 0),
	"wall_plank": Vector2i(3, 0), "wall_stone": Vector2i(0, 1), "stone_floor": Vector2i(1, 1),
	"rug": Vector2i(2, 1), "floor_c": Vector2i(3, 1),
}

var _rng := RandomNumberGenerator.new()
var _solid := {}
var _root: Node2D
var _tm: TileMap
var _tm_stone: TileMap
var _fail := false
var _house_seq := 0

func _ready() -> void:
	_rng.seed = 240170
	_build()
	print("[FROSTCITY] ====== HOAN TAT, fail=", _fail)
	get_tree().quit(1 if _fail else 0)

# ---------------- helpers (mo phong build_city.gd) ----------------

func _cc(c: float, r: float) -> Vector2:
	# Tam o (c, r): x=(c-120)*64+32, y=(r-85)*64+32
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
		_tm.set_cell(0, Vector2i(c, r), 0, W[t])

func _ps(c: int, r: int, t: String) -> void:
	_tm_stone.set_cell(0, Vector2i(c, r), 0, INT[t])

func _pe_rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_pe(c, r, t)

func _ps_rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_ps(c, r, t)

func _prop(tex_name: String, ground: Vector2, scl: float = 1.0, flip: bool = false,
		node_name: String = "") -> Node2D:
	var holder := Node2D.new()
	holder.position = ground
	holder.y_sort_enabled = true
	holder.name = node_name if node_name != "" else ("Prop_" + tex_name)
	var tex: Texture2D = load("res://assets/props/" + tex_name + ".png")
	if tex == null:
		print("[FROSTCITY] LOI: khong load duoc texture ", tex_name)
		_fail = true
		return holder
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.position = Vector2(0, -tex.get_height() * scl / 2.0 + 8.0)
	sp.scale = Vector2(scl, scl)
	sp.flip_h = flip
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
		print("[FROSTCITY] LOI: khong load duoc texture ", tex_name)
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
	lb.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0))
	lb.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	lb.add_theme_constant_override("shadow_offset_x", 2)
	lb.add_theme_constant_override("shadow_offset_y", 2)
	lb.position = _cc(cell.x, cell.y) + Vector2(-200, -18)
	lb.z_index = 6
	lb.name = "Label_" + text
	_root.add_child(lb)
	lb.owner = _root

# Nha Bac: kind "a" (6 o, den sang), "b" (7 o, den sang), "f" (6 o, dong bang toi)
func _frost_building(kind: String, left_c: int, bottom_r: int, flip: bool = false) -> void:
	var tex_name := "frost_house_a"
	var w_tiles := 6
	if kind == "b":
		tex_name = "frost_house_b"
		w_tiles = 7
	elif kind == "f":
		tex_name = "frost_house_frozen"
		w_tiles = 6
	var ground := Vector2(ORIGIN.x + (left_c + w_tiles / 2.0) * TILE,
		ORIGIN.y + (bottom_r + 1) * TILE)
	_house_seq += 1
	_prop(tex_name, ground, 1.0, flip, "House_%03d" % _house_seq)
	_mark_rect(left_c, bottom_r - 1, left_c + w_tiles - 1, bottom_r)

func _save_scene() -> void:
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err != OK:
		print("[FROSTCITY] PACK LOI: ", err)
		_fail = true
		return
	err = ResourceSaver.save(packed, SAVE_PATH)
	print("[FROSTCITY] save err=", err, " -> ", SAVE_PATH)
	if err != OK:
		_fail = true

# ---------------- build chinh ----------------

func _build() -> void:
	_root = Node2D.new()
	_root.name = "Frostgard"
	_root.y_sort_enabled = true
	_root.set_script(load("res://systems/map_root.gd"))
	add_child(_root)
	_tm = TileMap.new()
	_tm.name = "GroundTiles"
	_tm.z_index = -10
	_tm.position = ORIGIN
	_tm.tile_set = load("res://assets/tilesets/winter_v1.tres")
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
	_build_throne_hall()
	_build_chapel()
	_build_barracks()
	_build_cemetery()
	_build_forge()
	_build_workshop()
	_build_residential()
	_build_levy()
	_scatter_decor()
	_build_collision()
	_build_portals_spawns()
	_build_npcs()
	_build_player_hud()
	_save_scene()

func _paint_ground() -> void:
	# Nen tuyet toan map: ngoai thanh xam tro/ sau, trong thanh nen chat
	for c in CW:
		for r in CH:
			var v := _rng.randf()
			var t := "snow"
			if v < 0.08:
				t = "drift"
			elif v < 0.13:
				t = "rocky_snow"
			elif v < 0.16:
				t = "frost_grass"
			elif v < 0.185:
				t = "dead_scrub"
			_pe(c, r, t)
	for c in range(0, 10):
		for r in CH:
			if _rng.randf() < 0.55:
				_pe(c, r, "ash_snow")
	for c in range(230, 240):
		for r in CH:
			if _rng.randf() < 0.55:
				_pe(c, r, "ash_snow")
	for c in CW:
		for r in range(0, 10):
			if _rng.randf() < 0.55:
				_pe(c, r, "ash_snow")
		for r in range(160, 170):
			if _rng.randf() < 0.4:
				_pe(c, r, "ash_snow")
	# Dat trong thanh: tuyet nen chat
	_pe_rect(8, 8, 231, 161, "packed_snow")
	for i in 900:
		var c := _rng.randi_range(10, 229)
		var r := _rng.randi_range(10, 159)
		_pe(c, r, "snow" if _rng.randf() < 0.6 else "drift")
	# San cac khu
	_pe_rect(98, 66, 142, 104, "stone_floor") # quang truong Lo Lon
	_pe_rect(176, 62, 224, 108, "packed_snow") # xuong ren
	_pe_rect(128, 124, 168, 152, "ash_snow") # diem trung thu - nen tro xam
	_pe_rect(130, 126, 166, 150, "packed_snow")
	_pe_rect(18, 62, 56, 112, "packed_snow") # nghia trang
	_pe_rect(172, 20, 222, 50, "packed_snow") # doanh trai
	# Duong chinh: cong Nam -> Trung Thu -> Lo Lon -> Ngai Bang (cot 117-122)
	_pe_rect(117, 44, 122, 161, "stone_floor")
	# Nhanh ngang hang Lo Lon: tay sang Nghia Trang/Nha Nguyen, dong sang Xuong/Doanh Trai
	_pe_rect(13, 83, 226, 86, "stone_floor")
	# Duong phu xuong khu dan cu (cong, tranh san trong)
	_pe_rect(84, 104, 87, 156, "packed_snow")
	_pe_rect(26, 136, 116, 138, "packed_snow")
	# Loi di nghia trang: truc giua hai khoi bia
	_pe_rect(35, 87, 39, 112, "packed_snow")
	# San ngai bang + sanh
	_ps_rect(93, 19, 147, 43, "stone_floor")
	# San nha nguyen
	_pe_rect(18, 20, 60, 50, "packed_snow")

func _build_walls() -> void:
	# Tuong da den + bang day 3 o (visual dark_brick + collision)
	_pe_rect(10, 10, 229, 12, "dark_brick")
	_pe_rect(10, 159, 229, 161, "dark_brick")
	_pe_rect(10, 10, 12, 161, "dark_brick")
	_pe_rect(227, 10, 229, 161, "dark_brick")
	_mark_rect(10, 10, 229, 12)
	_mark_rect(10, 159, 229, 161)
	_mark_rect(10, 10, 12, 161)
	_mark_rect(227, 10, 229, 161)
	# Vien ngoai thanh khoa chan (tuyet sau / dat chet khong di)
	_mark_rect(0, 0, 239, 7)
	_mark_rect(0, 162, 239, 169)
	_mark_rect(0, 0, 7, 169)
	_mark_rect(232, 0, 239, 169)
	# CONG BAC: DONG - phu bang day, giu collision, KHONG portal
	_pe_rect(115, 10, 124, 12, "deep_ice")
	_pe(116, 11, "ice_shine")
	_pe(121, 10, "ice_shine")
	_prop("ice_rock", _cc(119, 14), 1.2, false, "NorthGateIce")
	_mark(119, 13)
	_label("CỔNG BẮC — ĐÓNG BĂNG", Vector2(119, 16), 16)
	# CONG SAT NAM: mo cot 115-124 hang 159-161
	_pe_rect(115, 159, 124, 161, "stone_floor")
	_unmark_rect(115, 159, 124, 161)
	_prop("lamp", _cc(113, 157), 1.15, false, "GateLampL")
	_mark(113, 157)
	_prop("lamp", _cc(127, 157), 1.15, false, "GateLampR")
	_mark(127, 157)
	_label("CỔNG SẮT NAM", Vector2(120, 154), 18)
	_label("FROSTGARD", Vector2(120, 148), 34)
	# Thap goc + thap canh cong Bac/Nam
	for tp in [[11, 14], [228, 14], [11, 158], [228, 158], [108, 14], [133, 14]]:
		_prop("tower", Vector2(ORIGIN.x + tp[0] * TILE, ORIGIN.y + tp[1] * TILE) + Vector2(32, 0),
			0.9, false, "WallTower_%d_%d" % [tp[0], tp[1]])

func _build_throne_hall() -> void:
	# Vien sanh: dark_brick bao quanh, cua nam ho cot 117-122
	_pe_rect(92, 18, 148, 18, "dark_brick")
	_pe_rect(92, 44, 148, 44, "dark_brick")
	_pe_rect(92, 18, 92, 44, "dark_brick")
	_pe_rect(148, 18, 148, 44, "dark_brick")
	_mark_rect(92, 18, 148, 18)
	_mark_rect(92, 44, 148, 44)
	_mark_rect(92, 18, 92, 44)
	_mark_rect(148, 18, 148, 44)
	_unmark_rect(117, 44, 122, 44)
	# NGAI BANG lon o tam bac sanh (prop 512x448 = 8x7 o)
	_prop("ice_throne", _cc(120, 33), 1.0, false, "NgaiBang")
	_mark_rect(116, 30, 124, 32)
	# Tuong da + bang trang tri hai ben, cot bang
	_prop("statue", _cc(101, 37), 0.85, false, "ThroneStatueW")
	_mark_rect(100, 34, 102, 36)
	_prop("statue", _cc(139, 37), 0.85, true, "ThroneStatueE")
	_mark_rect(138, 34, 140, 36)
	_prop("ice_rock", _cc(96, 24), 1.0, false, "ThroneIceW")
	_mark(96, 23)
	_prop("ice_rock", _cc(144, 24), 1.0, false, "ThroneIceE")
	_mark(144, 23)
	_prop("ice_rock", _cc(108, 26), 0.8, false, "ThroneIceW2")
	_prop("ice_rock", _cc(132, 26), 0.8, false, "ThroneIceE2")
	_label("NGAI BĂNG — SẢNH VUA ĐÓNG BĂNG", Vector2(120, 21), 22)
	_label("King Valdemar, the Frostbound King — ngai trống, vua gác ở Approach", Vector2(120, 40), 14)

func _build_chapel() -> void:
	# THAP CHUONG LON khong chuong (prop 320x512): gia treo trong la chi tiet
	# ke chuyen nam ngay trong sprite (gac chuong toi, xa ngang, day dut)
	_prop("bell_tower", _cc(27, 42), 1.0, false, "ThapChuongLon")
	_mark_rect(25, 38, 29, 41)
	_label("THÁP CHUÔNG — GIÁ TREO TRỐNG", Vector2(27, 32), 15)
	# Nha nguyen: khoi nha da canh thap
	_frost_building("b", 36, 46)
	_frost_building("a", 47, 46, true)
	_prop("fireplace", _cc(55, 40), 0.95, false, "ChapelFire")
	_mark_rect(54, 38, 56, 40)
	_prop("bench", _cc(40, 41), 0.9, false, "ChapelBench1")
	_prop("bench", _cc(48, 41), 0.9, true, "ChapelBench2")
	_prop("snow_pine", _cc(20, 24), 0.95, false, "ChapelPine")
	_mark(20, 23)
	_label("NHÀ NGUYỆN KHÔNG CHUÔNG", Vector2(41, 24), 19)

func _build_barracks() -> void:
	_frost_building("b", 175, 33)
	_frost_building("a", 188, 33, true)
	_frost_building("a", 200, 33)
	_frost_building("f", 212, 33)
	# San tap: hinh nom THANG HANG (doi hinh ca gac - ngoai le huu co co chu y)
	for dx in [178, 188, 198, 208, 218]:
		_prop("dummy", _cc(dx, 44), 1.05, false, "Dummy_%d" % dx)
		_mark(dx, 43)
	for dx in [183, 193, 203, 213]:
		_prop("dummy", _cc(dx, 49), 0.95, false, "DummyB_%d" % dx)
		_mark(dx, 48)
	_prop("banner", _cc(222, 38), 1.0, false, "BarracksBanner")
	_mark(222, 37)
	_prop("barrel", _cc(176, 48), 1.0, false, "BarracksBarrel")
	_prop("sack", _cc(220, 48), 1.0, false, "BarracksSack")
	_label("DOANH TRẠI HIỆP SĨ BĂNG", Vector2(197, 24), 19)
	_label("Đội hình ca gác — không bao giờ đổi", Vector2(197, 52), 14)

func _build_cemetery() -> void:
	# BIA MO THEO HANG THANG QUAN DOI (ngoai le co chu y): 2 khoi bac/nam,
	# chừa trục giữa cot 35-39 + dai danh sach o tam (37, ~85)
	for r in [66, 71, 76, 96, 101, 106]:
		for c in range(21, 54, 4):
			if c >= 34 and c <= 40:
				continue
			_prop("grave_stone", _cc(c, r + 2), _rng.randf_range(0.88, 1.0), false,
				"Grave_%d_%d" % [c, r])
			_mark(c, r + 1)
			_mark(c, r + 2)
	# DAI DANH SACH TEN o giua (prop 384x320)
	_prop("name_memorial", _cc(37, 84), 1.0, false, "DaiDanhSachTen")
	_mark_rect(34, 80, 40, 83)
	_prop("bench", _cc(30, 90), 0.9, false, "MemorialBenchW")
	_prop("bench", _cc(44, 90), 0.9, true, "MemorialBenchE")
	_prop("snow_pine", _cc(19, 64), 0.9, false, "CemeteryPineW")
	_mark(19, 63)
	_prop("snow_pine", _cc(55, 110), 0.9, false, "CemeteryPineE")
	_mark(55, 109)
	_prop("ice_rock", _cc(53, 64), 0.85, false, "CemeteryRock")
	_label("NGHĨA TRANG QUÂN ĐOÀN", Vector2(37, 60), 20)
	_label("ĐÀI DANH SÁCH TÊN", Vector2(37, 92), 16)

func _build_forge() -> void:
	# LO LON TRUNG TAM (prop 768x512 = 12x8 o), tam ~(120, 85)
	_prop("great_forge", _cc(120, 90), 1.0, false, "LoLonTrungTam")
	_mark_rect(115, 85, 125, 89)
	_prop("anvil", _cc(108, 95), 1.15, false, "ForgeAnvil")
	_mark(108, 95)
	_prop("fireplace", _cc(133, 95), 1.35, false, "ForgeSideFire")
	_mark_rect(132, 93, 134, 95)
	_prop("shelf", _cc(102, 93), 1.1, false, "ForgeShelf")
	_mark(102, 92)
	_prop("barrel", _cc(138, 92), 1.0, false, "ForgeBarrel")
	_prop("wine_barrel", _cc(101, 99), 1.0, false, "ForgeBarrel2")
	_prop("bench", _cc(108, 101), 1.0, false, "ForgeBenchW")
	_mark(108, 101)
	_prop("bench", _cc(132, 101), 1.0, true, "ForgeBenchE")
	_mark(132, 101)
	_prop("lamp", _cc(100, 69), 1.1, false, "ForgeLampW")
	_mark(100, 69)
	_prop("lamp", _cc(140, 69), 1.1, false, "ForgeLampE")
	_mark(140, 69)
	# Ban che tao o hub Lo Lon (systems san co)
	var cs: Node = load("res://systems/craft_station.tscn").instantiate()
	cs.name = "CraftStation"
	cs.position = _cc(127, 97)
	cs.set("station_name", "Lò Lớn Frostgard")
	_root.add_child(cs)
	cs.owner = _root
	_label("LÒ LỚN TRUNG TÂM", Vector2(120, 105), 24)
	_label("Điểm sưởi — lò tắt là thành chết", Vector2(120, 64), 14)

func _build_workshop() -> void:
	_frost_building("a", 179, 74)
	_frost_building("b", 191, 74, true)
	_frost_building("f", 204, 74) # kho thep - nha toi dong bang
	_frost_building("a", 216, 74)
	_prop("anvil", _cc(186, 84), 1.1, false, "WorkshopAnvil")
	_mark(186, 84)
	_prop("fireplace", _cc(200, 85), 1.3, false, "WorkshopFire")
	_mark_rect(199, 83, 201, 85)
	_prop("shelf", _cc(214, 82), 1.1, false, "SteelRack")
	_mark(214, 81)
	_prop("ice_rock", _cc(220, 94), 1.0, false, "SteelPile1")
	_mark(220, 93)
	_prop("ice_rock", _cc(182, 96), 0.9, false, "SteelPile2")
	_mark(182, 95)
	_prop("barrel", _cc(222, 84), 1.0, false, "WorkshopBarrel")
	_prop("sack", _cc(178, 88), 1.0, false, "WorkshopSack")
	_label("XƯỞNG RÈN THÉP BĂNG + KHO THÉP", Vector2(200, 66), 19)

func _build_residential() -> void:
	# THUA: 18 nha, chi 7 nha co den (a/b), 11 nha dong bang toi (f).
	# Hang lech co chu y: day khong thang, khoang hem 4-11 o thay doi.
	# Day day 131 (bac khu dan cu)
	_frost_building("a", 28, 131)
	_frost_building("f", 38, 131)
	_frost_building("f", 49, 131, true)
	_frost_building("a", 60, 131)
	_frost_building("f", 73, 131)
	_frost_building("b", 96, 131) # NHA TRO LO SUOI - gan duong chinh nhat
	# Day 143
	_frost_building("f", 30, 143)
	_frost_building("b", 42, 143)
	_frost_building("f", 55, 143, true)
	_frost_building("f", 66, 143)
	_frost_building("a", 79, 143)
	_frost_building("f", 90, 143)
	# Day 152 (nam, sat cong)
	_frost_building("f", 32, 152)
	_frost_building("f", 44, 152, true)
	_frost_building("a", 57, 152)
	_frost_building("f", 68, 152)
	_frost_building("b", 79, 152)
	_frost_building("f", 92, 152)
	# Chi tiet khu dan cu
	_prop("well", _cc(50, 138), 1.0, false, "ResWell")
	_mark_rect(49, 136, 51, 138)
	_prop("fireplace", _cc(103, 136), 1.1, false, "InnFire")
	_mark_rect(102, 134, 104, 136)
	_prop("lamp", _cc(94, 134), 1.05, false, "InnLamp")
	_mark(94, 134)
	_prop("snow_pine", _cc(24, 138), 0.95, false, "ResPine1")
	_mark(24, 137)
	_prop("snow_pine", _cc(106, 148), 0.9, false, "ResPine2")
	_mark(106, 147)
	_prop("ice_rock", _cc(36, 147), 0.85, false, "ResRock")
	_prop("barrel", _cc(64, 138), 0.95, false, "ResBarrel")
	_label("KHU DÂN CƯ ĐÓNG BĂNG", Vector2(67, 122), 19)
	_label("NHÀ TRỌ LÒ SƯỞI", Vector2(99, 126), 16)
	_label("Nhiều nhà đã không còn ai mở cửa", Vector2(67, 156), 13)

func _build_levy() -> void:
	_frost_building("f", 158, 127) # tram gac trung thu - nha toi
	_prop("table", _cc(136, 133), 1.15, false, "LevyLedgerTable")
	_mark_rect(135, 132, 137, 133)
	_prop("shelf", _cc(143, 131), 1.05, false, "LevyShelf")
	_mark(143, 130)
	# Chuong xe truot: ghe dai + thung hang xep thang (san tap ket)
	for bx in [154, 158, 162]:
		_prop("bench", _cc(bx, 146), 1.0, false, "SledBench_%d" % bx)
		_mark(bx, 146)
	for bx in [132, 134, 136]:
		_prop("barrel", _cc(bx, 148), 1.0, false, "LevyBarrel_%d" % bx)
		_prop("sack", _cc(bx + 1, 144), 0.95, false, "LevySack_%d" % bx)
	_prop("banner", _cc(129, 130), 1.0, false, "LevyBanner")
	_mark(129, 129)
	_prop("snow_pine", _cc(166, 152), 0.9, false, "LevyPine")
	_mark(166, 151)
	_label("ĐIỂM TẬP KẾT TRƯNG THU", Vector2(148, 121), 19)
	_label("Sổ trưng thu — tên ai bị gọi, người đó đi gác băng", Vector2(142, 137), 13)

func _scatter_decor() -> void:
	# Den doc duong chinh (tru doan quang truong lo)
	for r in [52, 62, 112, 122, 144]:
		_prop("lamp", _cc(114, r), 1.05, false, "RoadLampW_%d" % r)
		_mark(114, r)
		_prop("lamp", _cc(126, r), 1.05, false, "RoadLampE_%d" % r)
		_mark(126, r)
	# Thong tuyet + da bang ven tuong va goc pho
	for tp in [[16, 56], [60, 56], [160, 56], [224, 56], [16, 118], [110, 118], [176, 118], [224, 118], [70, 18], [168, 18]]:
		_prop("snow_pine", _cc(tp[0], tp[1]), _rng.randf_range(0.85, 1.05), _rng.randf() < 0.5,
			"StreetPine_%d_%d" % [tp[0], tp[1]])
		_mark(tp[0], tp[1] - 1)
	for rp in [[64, 108], [176, 56], [24, 156], [216, 156]]:
		_prop("ice_rock", _cc(rp[0], rp[1]), _rng.randf_range(0.8, 1.0), false,
			"StreetRock_%d_%d" % [rp[0], rp[1]])
		_mark(rp[0], rp[1])

func _build_collision() -> void:
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
	print("[FROSTCITY] collision shapes: ", body.get_child_count(), ", solid cells: ", _solid.size())

func _build_portals_spawns() -> void:
	var portal_ps: PackedScene = load("res://systems/portal.tscn")
	var p: Node = portal_ps.instantiate()
	p.name = "PortalSouthGate"
	p.position = _cc(120, 160)
	p.set("target_scene", "res://maps/frostgard_approach.tscn")
	p.set("target_spawn", "from_frostgard")
	p.set("required_flag", "")
	p.set("label_text", "Frostgard Approach")
	_root.add_child(p)
	p.owner = _root
	# Hop dong co dinh: start + from_approach cung (120,155);
	# from_deadland (120,16) chua vi tri cho dot Dat Chet (chua dung).
	var spawns := [
		["Spawn_start", Vector2(120, 155)],
		["Spawn_from_approach", Vector2(120, 155)],
		["Spawn_from_deadland", Vector2(120, 16)],
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
		steps: Array, frames: String = "", wander: float = -1.0) -> void:
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
	if frames != "":
		var spr: AnimatedSprite2D = n.get_node("AnimatedSprite2D")
		spr.sprite_frames = load(frames)
	if wander >= 0.0:
		n.set("wander_radius", wander)
	var sch: Array[Dictionary] = []
	for s in steps:
		var pt := _cc(float(s[0]), float(s[1]))
		sch.append({"x": pt.x, "y": pt.y, "action": str(s[2]), "time": float(s[3])})
	n.set("schedule", sch)
	n.set("schedule_enabled", true)
	_root.add_child(n)
	n.owner = _root

func _build_npcs() -> void:
	# 1. Tho ren master o Lo Lon (work = go bua)
	_npc("NPC_ThoRenMaster", "frost_tho_ren_master", "Thợ rèn trưởng — Hallvard", Vector2(112, 97),
		Color(1, 0.82, 0.66), 55.0, [], false,
		{"done": ["Lò Lớn này cháy từ đời ông nội ta. Ta tắt lò một đêm thôi là sáng ra nửa thành không ai mở cửa nữa.",
			"Đứng gần lò mà hong người đi. Ở Frostgard, ấm cũng là một loại thuốc."]},
		[[112, 94, "work", 12], [126, 97, "walk", 5], [126, 97, "idle", 4], [108, 96, "walk", 5],
		 [108, 96, "work", 9], [112, 97, "walk", 4]],
		"res://assets/sprites/tho_ren_frames.tres")
	# 2. Tho ren thep bang o xuong (shop)
	_npc("NPC_ThoRenThepBang", "frost_tho_ren_thep", "Thợ rèn thép băng — Runa", Vector2(193, 87),
		Color(0.85, 0.9, 1), 55.0, [], true,
		{"done": ["Thép băng tôi trong nước hồ đóng băng, lưỡi không mẻ khi chém vào đá đen. Cần vũ khí hay giáp thì cứ xem hàng.",
			"Một nửa thép rèn ra ở đây không bán — nó đi thẳng lên tường Bắc cho ca gác đêm."]},
		[[186, 85, "work", 10], [200, 87, "walk", 5], [200, 87, "work", 8], [214, 83, "walk", 5],
		 [214, 83, "idle", 4], [193, 87, "walk", 5]],
		"res://assets/sprites/tho_ren_frames.tres")
	# 3. Nguoi giu Dai Danh Sach o nghia trang
	_npc("NPC_GiuDaiDanhSach", "frost_giu_danh_sach", "Người giữ Đài Danh Sách — Astrid", Vector2(41, 90),
		Color(0.85, 0.82, 0.95), 48.0, [], false,
		{"done": ["Mỗi bia ở đây là một người đã đi gác băng và không về. Ta đọc tên họ mỗi sáng — người còn tên thì chưa hẳn đã mất.",
			"Đài Danh Sách ở giữa nghĩa trang. Khi nghi lễ giải thoát diễn ra, tên phải được đọc lên bên chuông câm. Đừng quên điều đó."]},
		[[41, 90, "idle", 6], [37, 89, "work", 8], [30, 90, "walk", 5], [30, 90, "idle", 4],
		 [44, 90, "walk", 6], [44, 90, "idle", 4], [41, 90, "walk", 4]])
	# 4. Tu si nha nguyen khong chuong
	_npc("NPC_TuSiKhongChuong", "frost_tu_si", "Tu sĩ Không Chuông — Einar", Vector2(44, 41),
		Color(0.92, 0.9, 0.85), 46.0, [], false,
		{"done": ["Nhà nguyện này không có chuông. Chuông vẫn treo ở Hầm Mộ Quân Đoàn — mà không, nó không treo nữa. Nó câm rồi, từ đêm lời nguyền rơi xuống.",
			"Tháp chuông trong thành này cũng trống như tim ta những năm đầu. Người ta quen dần với cả sự im lặng, hiệp sĩ ạ."]},
		[[44, 39, "work", 8], [36, 42, "walk", 5], [36, 42, "idle", 5], [50, 43, "walk", 5],
		 [50, 43, "idle", 4], [44, 41, "walk", 4]])
	# 5. Doi truong ca gac tuong Bac (tuan tra tuyen tuong)
	_npc("NPC_DoiTruongGacBac", "frost_doi_truong_gac", "Đội trưởng ca gác — Freya", Vector2(120, 16),
		Color(0.72, 0.82, 1), 66.0, [], false,
		{"done": ["Ca của ta đi dọc tường Bắc, từ tháp Tây sang tháp Đông. Ngoài kia là đất chết dần về phía Sigilspire — ban đêm đừng nhìn lâu quá.",
			"Cổng Bắc đóng băng rồi, đừng cố. Muốn ra đất chết thì phải chờ nguyền này vỡ trước."]},
		[[60, 16, "walk", 10], [40, 16, "idle", 5], [120, 16, "walk", 11], [200, 16, "walk", 11],
		 [218, 16, "idle", 5], [120, 16, "walk", 11]],
		"res://assets/sprites/linh_tuan_frames.tres")
	# 6. Chu nha tro lo suoi
	_npc("NPC_ChuTroLoSuoi", "frost_chu_tro", "Chủ nhà trọ Lò Sưởi — Marta", Vector2(99, 136),
		Color(1, 0.88, 0.78), 52.0, [], false,
		{"done": ["Nhà trọ của ta là nhà hiếm hoi ở khu này còn khói bếp mỗi tối. Giường gần lò nhất thì phải đặt trước — lính gác đổi ca tranh nhau cái giường đó.",
			"Nhà đóng băng quanh đây không phải nhà hoang từ đầu đâu. Năm nào cũng thêm một hai căn tắt đèn hẳn."]},
		[[99, 135, "work", 8], [92, 138, "walk", 4], [92, 138, "idle", 4], [106, 137, "walk", 5],
		 [106, 137, "idle", 3], [99, 136, "walk", 4]])
	# 7. Thu lai trung thu o Diem Tap Ket (thoai u am)
	_npc("NPC_ThuLaiTrungThu", "frost_thu_lai", "Thư lại trưng thu — Kolbein", Vector2(138, 136),
		Color(0.8, 0.8, 0.86), 48.0, [], false,
		{"done": ["Sổ trưng thu đây. Tên nào ta gạch bút lên, người đó gói chăn, hôn con, rồi đi gác băng. Không ai trong sổ này quay về cả. Không một ai.",
			"Đừng nhìn ta thế. Ta chỉ viết tên. Người chọn tên... đã không còn viết được nữa từ lâu rồi."]},
		[[137, 134, "work", 10], [148, 140, "walk", 5], [148, 140, "idle", 5], [158, 136, "walk", 5],
		 [158, 136, "idle", 4], [138, 136, "walk", 5]])
	# 8-9. Hai hiep si DONG BANG o sanh ngai: NPC TINH (wander 0, chi idle tai cho)
	_npc("NPC_HiepSiBangTrai", "frost_hiep_si_trai", "Hiệp sĩ đóng băng — Leif", Vector2(112, 35),
		Color(0.6, 0.8, 1), 30.0, [], false,
		{"before": ["..."], "done": ["..."]},
		[[112, 35, "idle", 999]],
		"res://assets/sprites/linh_tuan_frames.tres", 0.0)
	_npc("NPC_HiepSiBangPhai", "frost_hiep_si_phai", "Hiệp sĩ đóng băng — Sten", Vector2(128, 35),
		Color(0.6, 0.8, 1), 30.0, [], false,
		{"before": ["...chưa... hết ca..."], "done": ["...chưa... hết ca..."]},
		[[128, 35, "idle", 999]],
		"res://assets/sprites/linh_tuan_frames.tres", 0.0)
	# 10. Dan cu ganh cui: khu dan cu -> Lo Lon
	_npc("NPC_GanhCui", "frost_ganh_cui", "Người gánh củi — Bjorn", Vector2(62, 138),
		Color(0.9, 0.85, 0.75), 58.0, [], false,
		{"done": ["Củi này cho Lò Lớn. Cả thành sưởi bằng một cái lò — nên cả thành gánh củi cho một cái lò. Công bằng mà nói, nó cũng rèn thép cho cả thành."]},
		[[100, 138, "walk", 8], [120, 138, "walk", 6], [120, 110, "walk", 7], [114, 100, "walk", 5],
		 [114, 100, "work", 6], [120, 110, "walk", 6], [120, 138, "walk", 7], [62, 138, "walk", 10]],
		"res://assets/sprites/nong_dan_frames.tres")
	# 11. Nguoi quet tuyet quanh Lo Lon / duong chinh
	_npc("NPC_QuetTuyet", "frost_quet_tuyet", "Người quét tuyết — Helga", Vector2(126, 101),
		Color(0.95, 0.9, 0.95), 50.0, [], false,
		{"done": ["Ta quét tuyết quanh Lò Lớn từ lúc trời còn tối. Tuyết ở đây không rơi xuống để đẹp — nó rơi xuống để chôn cái thành này chậm rãi."]},
		[[124, 99, "work", 8], [106, 100, "walk", 5], [106, 100, "work", 7], [138, 99, "walk", 6],
		 [138, 99, "work", 7], [126, 101, "walk", 5]],
		"res://assets/sprites/nong_dan_frames.tres")
	# 12. Dan cu khu dong bang
	_npc("NPC_DanCu", "frost_dan_cu", "Dân cư — Nils", Vector2(52, 148),
		Color(0.88, 0.92, 1), 50.0, [], false,
		{"done": ["Nhà ta là một trong số ít nhà ở dãy này còn người. Hai bên đều đóng băng cả rồi — đêm ngủ nghe băng nứt trong tường nhà hàng xóm, như ai đang gõ cửa mà không vào."]},
		[[52, 146, "idle", 5], [50, 139, "walk", 5], [50, 139, "work", 5], [72, 148, "walk", 6],
		 [72, 148, "idle", 5], [52, 148, "walk", 6]],
		"res://assets/sprites/nong_dan_frames.tres")
	# 13. Nguoi dua tin: cong Nam <-> Lo Lon (chay nhanh)
	_npc("NPC_DuaTin", "frost_dua_tin", "Người đưa tin — Sanna", Vector2(120, 150),
		Color(1, 0.95, 0.85), 86.0, [], false,
		{"done": ["Thư từ Hearthwick lên, lệnh từ tường Bắc xuống — chân ta thuộc từng viên đá trên đường này. Có tin gì cho Lò Lớn thì cứ nói, ta chạy một mạch."]},
		[[120, 112, "walk", 7], [120, 100, "walk", 4], [120, 100, "idle", 4], [120, 150, "walk", 9],
		 [120, 150, "idle", 4]],
		"res://assets/sprites/linh_tuan_frames.tres")
	# 14. Linh gac cong Nam / dua tin du phong o cong
	_npc("NPC_GacCongNam", "frost_gac_cong_nam", "Lính gác cổng Nam — Torvald", Vector2(113, 154),
		Color(0.78, 0.86, 1), 58.0, [], false,
		{"done": ["Cổng sắt này mười người kéo mới mở hết. Nó sinh ra để đóng, không phải để mở — nhớ thế mỗi khi ngươi đi qua.",
			"Ra cổng là Frostgard Approach, xuống nữa là Howling Pass về Hearthwick."]},
		[[113, 154, "idle", 6], [127, 154, "walk", 5], [127, 154, "idle", 5], [120, 149, "walk", 5],
		 [120, 149, "idle", 4], [113, 154, "walk", 5]],
		"res://assets/sprites/linh_tuan_frames.tres")

func _build_player_hud() -> void:
	var player: Node = load("res://player/player.tscn").instantiate()
	player.name = "Player"
	player.position = _cc(120, 155)
	_root.add_child(player)
	player.owner = _root
	var hud: Node = load("res://ui/hud.tscn").instantiate()
	hud.name = "HUD"
	_root.add_child(hud)
	hud.owner = _root
