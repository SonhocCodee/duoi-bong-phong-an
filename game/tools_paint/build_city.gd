extends Node2D
## Tool mot lan (dot 2B): dung scene Thanh Aldenmere 260x190 o theo layout
## da duyet (design/aldenmere_layout.md), PHA LUOI HUU CO: nha nhieu mau/co/
## mai, xo lech 0-2 o, hem 1-3 o bat quy tac, sap cho khong deu.
## Chay: godot --headless --path game res://tools_paint/build_city.tscn
## Ghi de res://maps/thanh_xuan_lam.tscn (giu nguyen ket noi portal cu).

const TILE := 64.0
const CW := 260
const CH := 190
const ORIGIN := Vector2(-8320.0, -6080.0)
const SAVE_PATH := "res://maps/thanh_xuan_lam.tscn"

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
const INT := {
	"floor_a": Vector2i(0, 0), "floor_b": Vector2i(1, 0), "floor_dark": Vector2i(2, 0),
	"wall_plank": Vector2i(3, 0), "wall_stone": Vector2i(0, 1), "stone_floor": Vector2i(1, 1),
	"rug": Vector2i(2, 1), "floor_c": Vector2i(3, 1),
}
const HOUSES := [
	["house_a", 6], ["house_b", 7], ["house_c", 8],
	["house_d", 6], ["house_e", 9], ["house_f", 5],
]
const STALLS := ["stall_a", "stall_b", "stall_c", "stall_d"]

var _rng := RandomNumberGenerator.new()
var _solid := {}
var _root: Node2D
var _tm_ext: TileMap
var _tm_stone: TileMap
var _fail := false
var _house_seq := 0

func _ready() -> void:
	_rng.seed = 777123
	_build()
	print("[CITY] ====== HOAN TAT, fail=", _fail)
	get_tree().quit(1 if _fail else 0)

# ---------------- helpers ----------------

func _cc(c: float, r: float) -> Vector2:
	# Tam o (c, r) theo toa do layout (chap nhan so thap phan)
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
	_tm_ext.set_cell(0, Vector2i(c, r), 0, EXT[t])

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
		print("[CITY] LOI: khong load duoc texture ", tex_name)
		_fail = true
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
		print("[CITY] LOI: khong load duoc texture ", tex_name)
		_fail = true
	_root.add_child(holder)
	holder.add_child(sp)
	sp.owner = _root
	holder.owner = _root
	return holder

func _decal(tex_name: String, cell: Vector2) -> void:
	# Decal phang tren mat dat (z thap, khong y-sort offset, khong va cham)
	var holder := Node2D.new()
	holder.position = _cc(cell.x, cell.y)
	holder.z_index = -5
	holder.rotation = _rng.randf() * TAU
	holder.name = "Decal_" + tex_name
	var sp := Sprite2D.new()
	sp.texture = load("res://assets/props/" + tex_name + ".png")
	sp.flip_h = _rng.randf() < 0.5
	holder.add_child(sp)
	_root.add_child(holder)
	holder.owner = _root
	sp.owner = _root

func _label(text: String, cell: Vector2, size: int = 20) -> void:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", Color(1, 0.96, 0.8))
	lb.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	lb.add_theme_constant_override("shadow_offset_x", 2)
	lb.add_theme_constant_override("shadow_offset_y", 2)
	lb.position = _cc(cell.x, cell.y) + Vector2(-160, -18)
	lb.z_index = 6
	lb.name = "Label_" + text
	_root.add_child(lb)
	lb.owner = _root

# Dat 1 toa nha: tex rong w_tiles o, chan o hang bottom (va cham 2 hang day)
func _building(tex_name: String, left_c: int, bottom_r: int, w_tiles: int,
		depth: int = 2, flip: bool = false) -> void:
	var ground := Vector2(ORIGIN.x + (left_c + w_tiles / 2.0) * TILE,
		ORIGIN.y + (bottom_r + 1) * TILE)
	_house_seq += 1
	_prop(tex_name, ground, 1.0, flip, "House_%03d" % _house_seq)
	_mark_rect(left_c, bottom_r - depth + 1, left_c + w_tiles - 1, bottom_r)

func _save_scene() -> void:
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err != OK:
		print("[CITY] PACK LOI: ", err)
		_fail = true
		return
	err = ResourceSaver.save(packed, SAVE_PATH)
	print("[CITY] save err=", err, " -> ", SAVE_PATH)
	if err != OK:
		_fail = true

# ---------------- build chinh ----------------

func _build() -> void:
	_root = Node2D.new()
	_root.name = "ThanhXuanLam"
	_root.y_sort_enabled = true
	_root.set_script(load("res://systems/map_root.gd"))
	add_child(_root)
	_tm_ext = TileMap.new()
	_tm_ext.name = "GroundTiles"
	_tm_ext.z_index = -10
	_tm_ext.position = ORIGIN
	_tm_ext.tile_set = load("res://assets/tilesets/exterior_v1.tres")
	_root.add_child(_tm_ext)
	_tm_ext.owner = _root
	_tm_stone = TileMap.new()
	_tm_stone.name = "StoneTiles"
	_tm_stone.z_index = -9
	_tm_stone.position = ORIGIN
	_tm_stone.tile_set = load("res://assets/tilesets/interior_tavern_v1.tres")
	_root.add_child(_tm_stone)
	_tm_stone.owner = _root

	_paint_ground()
	_build_walls()
	_build_plaza()
	_build_craft()
	_build_market()
	_build_residential()
	_build_military()
	_build_citadel()
	_scatter_decor()
	_build_collision()
	_build_portals_spawns()
	_build_npcs()
	_build_player_hud()
	_save_scene()

func _paint_ground() -> void:
	# Nen co toan thanh voi bien the ngau nhien
	for c in CW:
		for r in CH:
			var v := _rng.randf()
			var t := "grass"
			if v < 0.10:
				t = "grass_flower"
			elif v < 0.20:
				t = "grass_tall"
			elif v < 0.28:
				t = "grass_dark"
			elif v < 0.33:
				t = "grass_sparse"
			_pe(c, r, t)
	# Khu dat: cho, nghe, dan cu, quan su
	_pe_rect(172, 48, 256, 110, "dirt")
	_pe_rect(3, 48, 88, 110, "dirt")
	_pe_rect(3, 111, 112, 168, "dirt")
	_pe_rect(148, 111, 196, 168, "dirt")
	_pe_rect(204, 111, 256, 168, "dirt")
	# Lat da: noi thanh, quang truong, cac truc duong, san cong
	_ps_rect(3, 3, 256, 44, "stone_floor")
	_ps_rect(96, 48, 164, 110, "stone_floor")
	_ps_rect(127, 3, 132, 186, "stone_floor")
	_ps_rect(3, 104, 256, 106, "stone_floor")
	_ps_rect(3, 138, 256, 140, "stone_floor")
	_ps_rect(84, 48, 87, 186, "stone_floor")
	_ps_rect(198, 48, 201, 186, "stone_floor")
	_ps_rect(113, 154, 147, 180, "stone_floor")
	# Duong cho chinh ram soI
	_pe_rect(172, 74, 256, 84, "pebbles")
	# San tap cat
	_pe_rect(206, 140, 254, 164, "sand")
	# Vuon rau dai nam dan cu (cham pha, giu lo courtyards)
	for patch in [[8, 157, 84, 165], [104, 157, 146, 165], [150, 157, 168, 165], [186, 157, 200, 165]]:
		for c in range(patch[0], patch[2] + 1):
			for r in range(patch[1], patch[3] + 1):
				if _rng.randf() < 0.8:
					_pe(c, r, "field")
	# Tuong: dai wall_stone + mat tuong di duoc floor_dark
	_ps_rect(0, 0, 259, 2, "wall_stone")
	_ps_rect(0, 187, 259, 189, "wall_stone")
	_ps_rect(0, 0, 2, 189, "wall_stone")
	_ps_rect(257, 0, 259, 189, "wall_stone")
	_ps_rect(3, 45, 256, 47, "wall_stone")
	_ps_rect(3, 187, 256, 188, "floor_dark")
	_ps_rect(3, 45, 256, 46, "floor_dark")
	# Cong chinh + cong noi thanh lat da sang
	_ps_rect(127, 187, 132, 189, "stone_floor")
	_ps_rect(127, 45, 132, 47, "stone_floor")
	# Nuoc dai phun (dia tron tam (128.5, 96.5), ban kinh 5 o)
	for c in range(122, 136):
		for r in range(90, 104):
			var d := Vector2(c - 128.5, r - 96.5).length()
			if d <= 5.0:
				_pe(c, r, "water_a" if (c + r) % 2 == 0 else "water_b")

func _build_walls() -> void:
	# Va cham: toan bo dai tuong ngoai la dac
	_mark_rect(0, 0, 259, 2)
	_mark_rect(0, 0, 2, 189)
	_mark_rect(257, 0, 259, 189)
	_mark_rect(0, 189, 259, 189) # mat ngoai tuong nam (hang 189)
	# Mat tuong T1 (187-188) DI DUOC: chi chan o 2 thap canh S1/S2 phia san
	# Tuong trong: hang 47 dac (tru cong), 45-46 di duoc
	_mark_rect(3, 47, 256, 47)
	_unmark_rect(127, 47, 132, 47)
	_unmark_rect(127, 189, 132, 189)
	# Thap goc x4 + thap giua doan
	for corner in [[2, 5], [256, 5], [2, 189], [256, 189], [81, 5], [179, 5], [2, 97], [256, 97]]:
		var g := Vector2(ORIGIN.x + corner[0] * TILE, ORIGIN.y + corner[1] * TILE)
		_prop("tower", g + Vector2(32, 0), 1.0, false, "Tower_%d_%d" % [corner[0], corner[1]])
	# 2 thap canh cong chinh S1 (113-125) / S2 (134-146): chan chi de lai loi thang
	_prop("tower", _cc(118.5, 186) + Vector2(0, TILE), 1.0, false, "TowerGateS1")
	_prop("tower", _cc(139.5, 186) + Vector2(0, TILE), 1.0, false, "TowerGateS2")
	_mark_rect(113, 181, 116, 183)
	_mark_rect(121, 181, 125, 183)
	_mark_rect(134, 181, 138, 183)
	_mark_rect(143, 181, 146, 183)
	# Den 2 ben cong + nhan thanh
	_prop("lamp", _cc(125, 184), 1.2, false, "GateLampL")
	_prop("lamp", _cc(134, 184), 1.2, false, "GateLampR")
	_mark(125, 184)
	_mark(134, 184)
	_label("ALDENMERE", Vector2(129, 181), 40)

func _build_plaza() -> void:
	# Tuong lon (be cot 124-133, hang 76-81)
	_prop("statue", Vector2(ORIGIN.x + 129 * TILE, ORIGIN.y + 82 * TILE), 1.0, false, "StatueLon")
	_mark_rect(124, 78, 133, 81)
	# Dai phun: vien sprite + chan dia nuoc
	_prop_centered("fountain", ORIGIN + Vector2(129 * TILE, 97 * TILE), "DaiPhun")
	for c in range(122, 136):
		for r in range(90, 104):
			if Vector2(c - 128.5, r - 96.5).length() <= 5.2:
				_mark(c, r)
	# Ghe da quanh dai phun
	for gp in [[118, 97], [140, 97], [129, 86], [129, 108]]:
		_prop("bench", _cc(gp[0], gp[1]), 1.0, false, "Bench_%d_%d" % [gp[0], gp[1]])
		_mark(gp[0], gp[1])
	# Bang nhiem vu + gieng thanh o tien san
	_prop("table", _cc(104, 57), 1.1, false, "QuestBoard")
	_mark_rect(103, 56, 105, 57)
	_label("BANG NHIEM VU", Vector2(104, 53), 16)
	_prop("well", _cc(152, 57), 1.1, false, "GiengThanh")
	_mark_rect(151, 55, 153, 57)
	# 2 cay con cua Co Thu
	_prop("oak", _cc(104, 85), 1.25, false, "CayConTay")
	_mark(104, 84)
	_prop("oak", _cc(156, 85), 1.25, true, "CayConDong")
	_mark(156, 84)
	# Bon hoa quanh tuong + dai phun
	for bp in [[119, 74], [139, 74], [117, 86], [141, 86], [116, 97], [142, 97]]:
		_prop("flower_bed", _cc(bp[0], bp[1]), 1.0, _rng.randf() < 0.5, "Bed_%d_%d" % [bp[0], bp[1]])
		_mark_rect(bp[0] - 1, bp[1], bp[0] + 1, bp[1])
	# Co bang ron 2 ben dai lo quanh quang truong
	for bp in [[123, 64], [136, 64], [123, 114], [136, 114]]:
		_prop("banner", _cc(bp[0], bp[1]), 1.0, false, "Banner_%d_%d" % [bp[0], bp[1]])
		_mark(bp[0], bp[1])
	# 2 sap nho o ria quang truong (ban hoa + ban banh)
	_prop("stall_b", Vector2(ORIGIN.x + 101 * TILE, ORIGIN.y + 69 * TILE), 0.7, false, "PlazaStallW")
	_mark_rect(99, 66, 103, 68)
	_prop("stall_d", Vector2(ORIGIN.x + 158 * TILE, ORIGIN.y + 69 * TILE), 0.7, true, "PlazaStallE")
	_mark_rect(155, 66, 159, 68)
	_label("QUANG TRUONG", Vector2(129, 68), 22)

func _build_craft() -> void:
	# Lo ren: khoi nha cot 8-29, day hang 72; san ren hang 73-82
	_building("house_c", 8, 72, 8)
	_building("house_c", 16, 72, 8, 2, true)
	_building("house_d", 24, 72, 6)
	_prop("fireplace", _cc(15, 78), 1.7, false, "ForgeFire")
	_mark_rect(14, 76, 16, 78)
	_prop("anvil", _cc(20, 78), 1.1, false, "TheAnvil")
	_mark(20, 78)
	_prop("shelf", _cc(26, 77), 1.1, false, "WeaponRack")
	_mark(26, 76)
	_prop("barrel", _cc(11, 80), 1.0, false, "ForgeBarrel")
	_prop("wine_barrel", _cc(29, 81), 1.0, false, "ForgeBarrel2")
	_label("LO REN", Vector2(19, 84), 18)
	# Quan ruou Lien Hoa: khoi cot 45-73, day hang 72 (portal cua o (60,73))
	_building("house_e", 45, 72, 9)
	_building("house_e", 54, 72, 9, 2, true)
	_building("house_d", 63, 72, 6)
	_building("house_f", 69, 72, 5)
	_prop("lamp", _cc(58, 74), 1.1, false, "TavernLampL")
	_prop("lamp", _cc(62, 74), 1.1, true, "TavernLampR")
	_prop("table", _cc(52, 78), 1.0, false, "TavernTableOut")
	_prop("wine_barrel", _cc(70, 77), 1.0, false, "TavernBarrel")
	_label("QUAN RUOU LIEN HOA", Vector2(59, 75), 18)
	# Kho / xuong moc cot 8-31 day 108
	_building("house_c", 9, 108, 8)
	_building("house_b", 17, 108, 7)
	_building("house_c", 24, 108, 8, 2, true)
	_prop("sack", _cc(13, 104), 1.1, false, "KhoSack1")
	_prop("sack", _cc(27, 104), 1.1, false, "KhoSack2")
	_prop("barrel", _cc(20, 103), 1.0, false, "KhoBarrel")
	# Nha tro cot 45-70 day 108
	_building("house_e", 45, 108, 9)
	_building("house_c", 54, 108, 8)
	_building("house_e", 62, 108, 9, 2, true)
	_prop("lamp", _cc(59, 105), 1.1, false, "InnLamp")
	_label("NHA TRO", Vector2(57, 101), 18)

func _build_market() -> void:
	var stalls_n: Array[int] = []
	var x := 173
	for i in 12:
		var jx := x
		if i > 0 and _rng.randf() < 0.35:
			jx += _rng.randi_range(-1, 1)
		stalls_n.append(jx)
		x += 7
	# Day bac: sprite day hang 69; quay (nam) chan hang 67-69, lung chan 62-64
	for i in stalls_n.size():
		var c: int = stalls_n[i]
		var v: String = STALLS[_rng.randi_range(0, 3)]
		_prop(v, Vector2(ORIGIN.x + (c + 3) * TILE, ORIGIN.y + 70 * TILE), 1.0,
			_rng.randf() < 0.3, "StallN%02d" % i)
		_mark_rect(c, 67, c + 5, 69)
		_mark_rect(c, 62, c + 5, 64)
		if _rng.randf() < 0.5:
			_prop("barrel" if _rng.randf() < 0.5 else "sack", _cc(c + 6, 71), 1.0, false, "StallN%02d_side" % i)
	# Day nam: sprite day hang 94; quay (bac) chan hang 87-89, lung chan 92-94
	for i in stalls_n.size():
		var c: int = stalls_n[i] + (1 if i % 3 == 2 else 0)
		if c + 5 > 256:
			c = 251
		var v: String = STALLS[_rng.randi_range(0, 3)]
		_prop(v, Vector2(ORIGIN.x + (c + 3) * TILE, ORIGIN.y + 95 * TILE), 1.0,
			_rng.randf() < 0.3, "StallS%02d" % i)
		_mark_rect(c, 87, c + 5, 89)
		_mark_rect(c, 92, c + 5, 94)
	# Nha hau sap: bac day 61, nam day 103
	for hx in [176, 189, 202, 215, 228, 241]:
		_building("house_f" if _rng.randf() < 0.5 else "house_b", hx, 61,
			5 if _rng.randf() < 0.5 else 7)
		_building("house_b" if _rng.randf() < 0.5 else "house_f", hx + _rng.randi_range(-1, 1), 103,
			7 if _rng.randf() < 0.5 else 5)
	_prop("well", _cc(214, 57), 1.0, false, "GiengCho")
	_mark_rect(213, 56, 215, 57)
	_label("KHU CHO", Vector2(214, 71), 20)

func _build_residential() -> void:
	var reserved_w := [24, 25, 52, 78, 79, 96]
	var reserved_e := [164, 188]
	for band_bottom in [123, 137, 153]:
		_house_row(4, 111, band_bottom, reserved_w)
		_house_row(149, 195, band_bottom, reserved_e)
	# San trong S-T (88-100, 156-166) + S-D (172-184, 156-166)
	_prop("well", _cc(94, 162), 1.0, false, "WellST")
	_mark_rect(93, 160, 95, 162)
	_prop("bench", _cc(90, 163), 1.0, false, "BenchST")
	_prop("oak", _cc(98, 166), 1.1, false, "OakST")
	_mark(98, 165)
	_prop("laundry", _cc(91, 158), 1.0, false, "LaundryST")
	_prop("bench", _cc(178, 163), 1.0, false, "BenchSD")
	_prop("small_tree", _cc(181, 166), 1.1, false, "TreeSD")
	_mark(181, 165)
	# Day phoi trong hem H-T1 (hang 124-125)
	for lx in [30, 58, 84]:
		_prop("laundry", _cc(lx, 126), 1.0, _rng.randf() < 0.5, "LaundryHT1_%d" % lx)
	# Mieng cong o cuoi hem cut H-T4 (78-79, 126-148): thung rac + den mo
	_prop("barrel", _cc(77, 146), 1.0, false, "SewerBarrel")
	_prop("sack", _cc(80, 147), 1.0, false, "SewerSack")
	# Hem cut H-T4 song dong: day phoi giang ngang mieng hem bac (giua 2 nha
	# cot 70-77 va 80-88 day 123) + thung go + bon hoa o mieng hem
	_prop("laundry", _cc(78.5, 125), 1.0, false, "LaundryHT4a")
	_prop("laundry", _cc(78.5, 142), 1.0, true, "LaundryHT4b")
	_prop("barrel", _cc(81, 126), 1.0, false, "AlleyBarrel")
	_prop("flower_bed", _cc(74, 127), 0.8, false, "AlleyBed")
	# Bon hoa trong 2 san trong
	_prop("flower_bed", _cc(89, 159), 1.0, false, "BedST")
	_prop("flower_bed", _cc(179, 159), 1.0, true, "BedSD")
	# Hang rao nho quanh cac manh vuon dai nam (co loi vao)
	for patch in [[8, 157, 84, 165], [104, 157, 146, 165], [150, 157, 168, 165], [186, 157, 200, 165]]:
		var gap: int = (int(patch[0]) + int(patch[2])) / 2
		for c in range(patch[0], patch[2] + 1):
			if abs(c - gap) <= 1:
				continue
			_pe(c, patch[1], "fence_h")
			_mark(c, patch[1])
		for r in range(patch[1] + 1, patch[3] + 1):
			_pe(patch[0], r, "fence_v")
			_mark(patch[0], r)
	_label("DAN CU - HEM NHO", Vector2(58, 118), 16)

func _house_row(x0: int, x1: int, bottom_r: int, reserved: Array) -> void:
	var c := x0 + _rng.randi_range(0, 1)
	while c <= x1 - 5:
		# Gap hem bat quy tac
		if _rng.randf() < 0.16:
			var g := _rng.randi_range(1, 3)
			if g >= 2 and c + 1 <= x1:
				_prop("bush" if _rng.randf() < 0.5 else "barrel", _cc(c + 1, bottom_r), 0.9,
					false, "AlleyDeco_%d_%d" % [c, bottom_r])
			c += g
			continue
		var v: Array = HOUSES[_rng.randi_range(0, HOUSES.size() - 1)]
		var w: int = int(v[1])
		if c + w - 1 > x1:
			break
		# Khong de nha de len cot hem danh rieng
		var clash := false
		for rc in reserved:
			if int(rc) >= c and int(rc) <= c + w - 1:
				clash = true
		if clash:
			c += 1
			continue
		_building(str(v[0]), c, bottom_r, w, 2, _rng.randf() < 0.35)
		if _rng.randf() < 0.3:
			_prop("bush" if _rng.randf() < 0.6 else "barrel",
				_cc(c + w - 1, bottom_r + 1), 0.85, false, "FrontDeco_%d_%d" % [c, bottom_r])
		c += w

func _build_military() -> void:
	# Nha chi huy (208-221, day 126) + doanh trai (228-250, day 134)
	_building("house_c", 208, 126, 8)
	_building("house_d", 216, 126, 6)
	_building("house_e", 228, 134, 9)
	_building("house_e", 237, 134, 9, 2, true)
	_building("house_f", 246, 134, 5)
	# San tap: hinh nom x3 + hang rao
	for dx in [214, 230, 246]:
		_prop("dummy", _cc(dx, 150), 1.1, false, "Dummy_%d" % dx)
		_mark(dx, 149)
	for fc in range(206, 255):
		if fc % 9 != 4:
			_pe(fc, 140, "fence_h")
	_prop("barrel", _cc(210, 162), 1.0, false, "YardBarrel")
	_prop("sack", _cc(250, 162), 1.0, false, "YardSack")
	_label("KHU QUAN SU", Vector2(230, 137), 18)

func _build_citadel() -> void:
	# Phu King Aldric: keep lon + 2 canh
	_prop("palace", Vector2(ORIGIN.x + 41.5 * TILE, ORIGIN.y + 39 * TILE), 1.0, false, "PhuAldric")
	_mark_rect(31, 36, 52, 38)
	_building("house_c", 16, 38, 8)
	_building("house_c", 59, 38, 8, 2, true)
	# Den Xin Mua (81-86, day 26)
	_building("house_d", 81, 26, 6)
	_prop("lamp", _cc(79, 24), 1.1, false, "TempleLampL")
	_prop("lamp", _cc(89, 24), 1.1, false, "TempleLampR")
	# Nha canh + kho an ap tuong trong
	_building("house_f", 110, 43, 5)
	_building("house_f", 140, 43, 5, 2, true)
	# Co Thu - Tru Moc: than + tan la soi lon
	_prop("trunk_big", _cc(200, 23), 1.0, false, "CoThuTrunk")
	_mark_rect(198, 20, 202, 22)
	for cp in [[188, 16], [200, 8], [212, 16], [194, 3], [206, 3]]:
		_prop("oak", _cc(cp[0], cp[1]), 2.6, _rng.randf() < 0.5, "CoThuCanopy_%d_%d" % [cp[0], cp[1]])
	# Vong hang rao dau truong boss (elip tam (200,20), ban kinh 15) - ho 2 loi vao
	for c in range(184, 217):
		for r in range(4, 37):
			var e := Vector2((c - 200) / 15.0, (r - 20) / 15.0).length()
			if e >= 0.88 and e <= 1.12:
				if (c == 185 and r == 20) or (c == 200 and r == 35):
					continue
				_pe(c, r, "fence_h" if abs(c - 200) >= abs(r - 20) else "fence_v")
				_mark(c, r)
	# Cay trang tri vuon noi thanh
	for tp in [[176, 10], [224, 10], [176, 32], [224, 32]]:
		_prop("oak", _cc(tp[0], tp[1]), 1.35, _rng.randf() < 0.5, "CitadelOak_%d_%d" % [tp[0], tp[1]])
		_mark(tp[0], tp[1] - 1)
	_label("NOI THANH THUONG", Vector2(129, 42), 20)
	_label("CO THU - TRU MOC", Vector2(200, 38), 16)

func _scatter_decor() -> void:
	# Den da doc dai lo
	for r in [16, 36, 56, 76, 96, 116, 136, 156, 176]:
		_prop("lamp", _cc(125, r), 1.05, false, "AvenueLampW_%d" % r)
		_mark(125, r)
		_prop("lamp", _cc(134, r), 1.05, false, "AvenueLampE_%d" % r)
		_mark(134, r)
	# Cay nho rai rac ven pho + san cong
	for tp in [[86, 60], [86, 150], [199, 60], [199, 170], [118, 160], [142, 160], [60, 160], [160, 176]]:
		_prop("small_tree", _cc(tp[0], tp[1]), 1.1, _rng.randf() < 0.5, "StreetTree_%d_%d" % [tp[0], tp[1]])
		_mark(tp[0], tp[1] - 1)
	# Da tang + bui ven tuong tay/dong
	for bp in [[6, 120], [6, 60], [253, 120], [253, 66], [100, 184], [170, 184]]:
		_prop("boulder" if _rng.randf() < 0.5 else "bush", _cc(bp[0], bp[1]), 1.0, false,
			"EdgeDeco_%d_%d" % [bp[0], bp[1]])
	# Decal mat dat pha don dieu: nut lat / reu / vet ban tren quang truong,
	# dai lo, duong cho va pho dan cu (tranh dai phun + be tuong)
	var decal_kinds := ["decal_crack", "decal_moss", "decal_stain"]
	var placed := 0
	var guard := 0
	while placed < 30 and guard < 300:
		guard += 1
		var dc := _rng.randi_range(98, 161)
		var dr := _rng.randi_range(50, 108)
		if Vector2(dc - 128.5, dr - 96.5).length() <= 6.5:
			continue
		if dc >= 123 and dc <= 134 and dr >= 76 and dr <= 83:
			continue
		_decal(decal_kinds[_rng.randi_range(0, 2)], Vector2(dc, dr))
		placed += 1
	for i in 12:
		_decal(decal_kinds[_rng.randi_range(0, 2)],
			Vector2(_rng.randi_range(120, 139), _rng.randi_range(112, 178)))
	for i in 8:
		_decal(decal_kinds[_rng.randi_range(0, 2)],
			Vector2(_rng.randi_range(176, 252), _rng.randi_range(75, 83)))
	for i in 10:
		_decal("decal_moss", Vector2(_rng.randi_range(6, 250), _rng.randi_range(168, 185)))

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
	# Vien duoi cung (hang 190 ao) - chua cong chinh
	for seg in [[0, 126], [133, 259]]:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2((seg[1] - seg[0] + 1) * TILE, TILE)
		cs.shape = shape
		cs.position = ORIGIN + Vector2((seg[0] + (seg[1] - seg[0] + 1) / 2.0) * TILE, 190.5 * TILE)
		body.add_child(cs)
		cs.owner = _root
	print("[CITY] collision shapes: ", body.get_child_count(), ", solid cells: ", _solid.size())

func _build_portals_spawns() -> void:
	var portal_ps: PackedScene = load("res://systems/portal.tscn")
	var defs := [
		["PortalSouth", Vector2(129, 188), "res://maps/ngoai_thanh.tscn", "from_thanh", "", "The Wallfoot"],
		["PortalNorth", Vector2(129, 5), "res://maps/hoang_cung.tscn", "from_thanh", "dong_giai_phong", "Royal Palace of Aldenmere"],
		["PortalToCellar", Vector2(60, 73), "res://maps/ham_ruou.tscn", "from_village", "", "Elmford Cellar (sau quan Lien Hoa)"],
		["PortalSewer", Vector2(78, 148), "res://maps/cong_ngam.tscn", "from_thanh", "co_duong_cong", "Aldenmere Sewers"],
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
		["Spawn_start", Vector2(-32, 5600)],
		["Spawn_from_ngoai", Vector2(-32, 5600)],
		["Spawn_from_cung", Vector2(-32, -5536)],
		["Spawn_from_cong", Vector2(-3296, 3232)],
		["Spawn_from_cave", Vector2(-4448, -1312)],
		["Spawn_from_quan", Vector2(-4384, -1312)],
		["Spawn_from_nui", Vector2(-96, -5536)],
	]
	for s in spawns:
		var m := Marker2D.new()
		m.name = s[0]
		m.position = s[1]
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
	# --- 4 NPC ke thua scene cu (giu nguyen quest + hoi thoai) ---
	_npc("NPC_ThoRen", "tho_ren", "Thợ rèn Đạt", Vector2(20, 77), Color(0.9, 0.9, 0.95), 55.0,
		["dong_side_slime"], false,
		{"before": ["Slime cỏ tràn ra ruộng ở Barleyfield, ăn hết lúa non. Dẹp giúp ta 5 con, ta trả công hậu."],
		 "active": ["Slime ở ruộng phía nam thành, qua Barleyfield là thấy."],
		 "ready": ["Ruộng yên rồi à? Tay nghề ngươi khá đấy!"],
		 "done": ["Kiếm cùn thì mang qua đây, ta mài cho."]},
		[[20, 77, "work", 12], [60, 78, "idle", 4], [85, 78, "walk", 6], [85, 105, "walk", 6],
		 [129, 105, "walk", 6], [129, 103, "idle", 4], [129, 105, "walk", 6], [85, 105, "walk", 6],
		 [85, 78, "walk", 6], [60, 78, "idle", 2]])
	_npc("NPC_ChuQuan", "chu_quan", "Chủ quán Liên Hoa", Vector2(60, 74), Color(1, 0.85, 0.85), 55.0,
		["dong_02_ham_ruou", "dong_03_chuot_chua", "dong_side_herb"], true,
		{"before": ["Quán Liên Hoa lúc nào cũng có phòng và rượu ngon — trừ khi chuột phá Elmford Cellar của ta!",
					"Xuống Elmford Cellar dưới quán, dẹp lũ chuột giúp ta trước đã. Cầu thang ngay trong quán này."],
		 "active": ["Elmford Cellar ở ngay dưới quán. Nghe nói còn một con Rat King to lắm ở kho sâu..."],
		 "ready": ["Hết chuột rồi sao? Mũi ta không còn ngửi thấy mùi hôi nữa!"],
		 "done": ["Cần nghỉ ngơi hay mua đồ, cứ ghé quán Liên Hoa. Thảo dược quanh Barleyfield cũng tốt cho thuốc của quán lắm."]},
		[[58, 76, "work", 6], [66, 76, "idle", 4]])
	_npc("NPC_LinhGac", "linh_gac", "Lính nghi lễ cổng cung", Vector2(124, 9), Color(0.8, 0.85, 1), 55.0,
		["dong_04_golem"], false,
		{"before": ["Trên Cloudpeak có hang Moss Den — con golem canh trong hang đã làm bị thương hai lính gác.",
					"Nếu ngươi đủ gan, lên núi theo cổng bắc này, vào hang ở sườn đông mà dẹp nó."],
		 "active": ["Đường leo núi gấp khúc, hai bên là vách đá. Cứ men theo đường đất sáng là tới miệng hang golem."],
		 "ready": ["Ngươi thật sự hạ được Mossback sao? Cả thành này nợ ngươi một chén rượu!"],
		 "done": ["Cloudpeak Summit nhìn rõ Sigilspire lắm. Người già nói rồng sẽ đáp xuống đó một ngày kia..."]},
		[[124, 9, "idle", 5], [134, 9, "walk", 6], [129, 12, "idle", 3]])
	_npc("NPC_LinhGacNam", "linh_gac_nam", "Lính gác cổng Nam", Vector2(122, 178), Color(0.85, 0.9, 1), 55.0,
		[], false,
		{"done": ["Cổng nam này ra Barleyfield. Đi thêm về nam là Elmford, làng khởi đầu của bao hiệp sĩ."]},
		[[122, 178, "idle", 5], [118, 182, "walk", 5], [100, 187, "walk", 8], [60, 187, "idle", 5],
		 [100, 187, "walk", 8], [118, 182, "walk", 5], [136, 178, "idle", 4]])
	# --- NPC moi theo layout muc 7 ---
	_npc("NPC_LinhTuanA", "linh_tuan_a", "Lính tuần A — Bram", Vector2(241, 137), Color(0.85, 0.85, 1), 62.0,
		[], false,
		{"done": ["Tuyến A của ta: doanh trại — quảng trường — cổng nội thành — sân cung. Ngày nào cũng vậy, mưa cũng vậy."]},
		[[241, 137, "idle", 5], [199, 139, "walk", 9], [199, 105, "walk", 9], [130, 105, "walk", 9],
		 [112, 105, "walk", 6], [112, 88, "walk", 6], [118, 84, "idle", 5], [130, 84, "walk", 4],
		 [130, 52, "idle", 5], [130, 26, "idle", 6], [130, 52, "walk", 6], [130, 105, "walk", 9],
		 [130, 170, "idle", 5], [199, 139, "walk", 9]])
	_npc("NPC_LinhTuanB", "linh_tuan_b", "Lính tuần B — Cedric", Vector2(243, 137), Color(0.85, 0.9, 1), 62.0,
		[], false,
		{"done": ["Đứng trên mặt tường thành nhìn xuống biển mái Aldenmere mới hiểu sao người ta không nỡ rời thành."]},
		[[130, 139, "walk", 9], [136, 176, "idle", 4], [118, 182, "walk", 5], [100, 187, "walk", 8],
		 [32, 187, "idle", 4], [100, 187, "walk", 8], [118, 182, "walk", 5], [122, 178, "idle", 3],
		 [85, 170, "walk", 8], [85, 140, "walk", 8], [85, 105, "walk", 8], [199, 105, "walk", 11],
		 [214, 79, "idle", 5], [199, 79, "walk", 6], [199, 139, "walk", 9], [241, 137, "idle", 4]])
	_npc("NPC_ChuTro", "chu_tro", "Chủ nhà trọ", Vector2(60, 105), Color(0.95, 0.9, 0.8), 55.0,
		[], false,
		{"done": ["Đi xa về thì ghé nhà trọ nghỉ chân — giường êm nhất khu nghề đấy."]},
		[[60, 105, "work", 7], [64, 103, "idle", 3], [85, 105, "walk", 6], [199, 105, "walk", 11],
		 [199, 80, "walk", 6], [190, 73, "idle", 5], [199, 80, "walk", 6], [199, 105, "walk", 6],
		 [85, 105, "walk", 11], [64, 103, "idle", 2]])
	_npc("NPC_TieuThuongRau", "tieu_thuong_rau", "Tiểu thương rau quả — Sạp B3", Vector2(190, 71), Color(0.9, 1, 0.9), 55.0,
		[], true,
		{"done": ["Rau quả tươi hái sáng nay ở Barleyfield, mua ít về ăn dọc đường đi."]},
		[[190, 71, "work", 10], [186, 79, "idle", 3], [190, 71, "work", 10]])
	_npc("NPC_TieuThuongVai", "tieu_thuong_vai", "Tiểu thương vải & thảo dược — Sạp N5", Vector2(204, 85), Color(1, 0.95, 0.85), 55.0,
		[], true,
		{"done": ["Vải tốt, thảo dược phơi khô — thảo dược thì người ta mua cho quán Liên Hoa là chính."]},
		[[204, 85, "work", 10], [209, 79, "idle", 3], [204, 85, "work", 9]])
	_npc("NPC_TieuThuongSat", "tieu_thuong_sat", "Tiểu thương đồ sắt & gốm — Sạp B7", Vector2(218, 71), Color(0.95, 0.95, 1), 55.0,
		[], true,
		{"done": ["Đồ sắt gốm bền như đá thành. Hỏng mang lại ta đổi."]},
		[[218, 71, "work", 10], [222, 79, "idle", 3], [218, 71, "work", 9]])
	_npc("NPC_DanCho1", "dan_cho_1", "Bà nội trợ đi chợ", Vector2(94, 163), Color(1, 0.9, 0.95), 52.0,
		[], false,
		{"done": ["Giá lúa năm nay lại tăng... lính thuế ở Stonebridge chặn hết xe hàng."]},
		[[94, 163, "work", 4], [94, 184, "walk", 7], [129, 170, "idle", 3], [129, 139, "walk", 7],
		 [199, 139, "walk", 11], [199, 79, "walk", 11], [190, 73, "idle", 5], [204, 85, "idle", 4],
		 [199, 79, "walk", 6], [199, 139, "walk", 11], [129, 139, "walk", 11], [129, 184, "walk", 7],
		 [94, 184, "walk", 7]])
	_npc("NPC_DanCho2", "dan_cho_2", "Anh gánh hàng thuê", Vector2(20, 97), Color(0.9, 0.95, 1), 58.0,
		[], false,
		{"done": ["Vác hàng thuê khắp chợ với kho. Cần tìm đường tắt trong thành thì hỏi ta."]},
		[[20, 97, "work", 5], [85, 97, "walk", 9], [85, 105, "walk", 3], [199, 105, "walk", 12],
		 [214, 79, "idle", 4], [199, 105, "walk", 9], [85, 105, "walk", 11], [20, 105, "walk", 9]])
	_npc("NPC_GanhNuoc", "ganh_nuoc", "Người gánh nước", Vector2(152, 58), Color(0.85, 0.95, 1), 50.0,
		[], false,
		{"done": ["Nước giếng thành dạo này ngọt lạ. Người già bảo nhờ rễ Cổ Thụ lọc đấy."]},
		[[152, 58, "work", 3], [130, 80, "walk", 7], [130, 139, "walk", 11], [52, 139, "walk", 11],
		 [52, 120, "work", 3], [52, 139, "walk", 7], [130, 139, "walk", 11], [130, 184, "walk", 9],
		 [94, 184, "walk", 7], [94, 163, "work", 3], [94, 184, "walk", 7], [130, 184, "walk", 7],
		 [130, 58, "walk", 13]])
	_npc("NPC_TreCon1", "tre_con_1", "Bé Tí — trẻ con quảng trường", Vector2(122, 90), Color(1, 1, 0.85), 88.0,
		[], false,
		{"done": ["Đố ngươi bắt được ta! Ta chạy quanh đài phun nhanh nhất thành!"]},
		[[122, 90, "idle", 1], [137, 90, "walk", 5], [137, 103, "walk", 5], [122, 103, "walk", 5],
		 [118, 84, "idle", 2]])
	_npc("NPC_TreCon2", "tre_con_2", "Bé Na — trẻ con quảng trường", Vector2(136, 103), Color(1, 0.85, 0.9), 88.0,
		[], false,
		{"done": ["Hẻm cụt bên khu Đông là chỗ trốn bí mật của bọn ta. Đừng mách lính tuần!"]},
		[[136, 103, "walk", 5], [122, 103, "walk", 5], [122, 90, "walk", 5], [136, 90, "walk", 5],
		 [199, 105, "walk", 9], [199, 139, "walk", 9], [188, 139, "walk", 5], [188, 133, "idle", 4],
		 [188, 139, "walk", 5], [199, 139, "walk", 7], [199, 105, "walk", 9], [136, 105, "walk", 9]])
	_npc("NPC_LinhCanhNoi", "linh_canh_noi", "Lính canh cổng nội thành", Vector2(129, 50), Color(0.85, 0.85, 1), 55.0,
		[], false,
		{"before": ["Muốn qua cổng nội thành, phải có uy tín với dân Aldenmere — hoặc việc của King Aldric gọi."],
		 "done": ["Cổng nội thành do ta canh. Trong kia là phủ King Aldric và Cổ Thụ — đất thiêng của thành."]},
		[[129, 50, "idle", 6], [124, 50, "walk", 4], [134, 50, "walk", 4]])
	_npc("NPC_LanhChua", "lanh_chua", "King Aldric, the Puppet King", Vector2(41, 32), Color(1, 0.9, 0.7), 50.0,
		[], false,
		{"before": ["Ta là Aldric, vua của Aldenmere... mọi việc trong thành đều phải qua mắt ta.",
					"Dạo này ta hay mơ thấy những sợi chỉ bạc buộc vào tay mình. Lạ thật."],
		 "done": ["Aldenmere đứng vững là nhờ dân nó. Ngươi cũng thấy đấy."]},
		[[41, 32, "work", 6], [90, 32, "walk", 7], [129, 26, "idle", 5], [180, 24, "idle", 4],
		 [129, 26, "idle", 3], [90, 32, "walk", 7]])
	# --- Cum NPC quang truong (sinh hoat quanh tuong + dai phun) ---
	_npc("NPC_BanHoa", "ban_hoa", "Người bán hoa — Lệ", Vector2(101, 71), Color(1, 0.9, 0.9), 50.0,
		[], true,
		{"done": ["Hoa tươi cắt ở vườn Cổ Thụ sáng nay — mua một bó tặng người thương đi."]},
		[[101, 71, "work", 9], [104, 73, "idle", 3]])
	_npc("NPC_NgamTuong", "ngam_tuong", "Ông lão ngắm tượng", Vector2(120, 84), Color(0.92, 0.92, 0.88), 42.0,
		[], false,
		{"done": ["Tượng này dựng từ đời phong ấn đầu tiên. Nghe nói đêm trăng tròn, mắt tượng ươn ướt."]},
		[[120, 84, "idle", 5], [136, 84, "walk", 6], [136, 88, "idle", 4], [120, 88, "walk", 6]])
	_npc("NPC_ChoChim", "cho_chim", "Bà cụ cho chim ăn", Vector2(138, 92), Color(0.95, 0.88, 0.95), 44.0,
		[], false,
		{"done": ["Lũ sẻ ở đài phun này quen ta rồi. Người đi hết, chim vẫn ở lại với thành."]},
		[[138, 92, "work", 5], [134, 101, "walk", 5], [138, 101, "work", 5], [142, 96, "idle", 3]])
	_npc("NPC_CuGia", "cu_gia", "Cụ đồ tể về hưu", Vector2(118, 97), Color(0.9, 0.88, 0.85), 40.0,
		[], false,
		{"done": ["Ta đi quanh đài phun đủ mười vòng mỗi sáng. Chân còn khoẻ là đời còn vui."]},
		[[118, 97, "idle", 3], [129, 108, "walk", 6], [140, 97, "walk", 6], [129, 86, "walk", 6]])
	_npc("NPC_ChiTu", "chi_tu", "Chị Tư — buôn chuyện", Vector2(126, 85), Color(1, 0.92, 0.85), 45.0,
		[], false,
		{"done": ["Nghe gì chưa? Đêm qua lính gác Nam bảo thấy bóng người đi trên mặt tường mà không có ca trực..."]},
		[[126, 85, "idle", 6], [127, 87, "idle", 4]])
	_npc("NPC_ChiNam", "chi_nam", "Chị Năm — buôn chuyện", Vector2(132, 85), Color(0.88, 0.95, 1), 45.0,
		[], false,
		{"done": ["Chuyện trong thành này, hỏi hai chị em ta là rõ nhất. Cả chuyện King Aldric hay nói mớ ban đêm."]},
		[[132, 85, "idle", 5], [131, 87, "idle", 4]])
	_npc("NPC_SuDen", "su_den", "Sư già Đền Xin Mùa", Vector2(86, 27), Color(0.95, 0.95, 0.9), 48.0,
		[], false,
		{"done": ["Đền Xin Mùa giữ lễ từ đời phong ấn đầu tiên. Nghe nói khi Trụ Mộc héo, tháp giữa trời sẽ rung."]},
		[[86, 27, "work", 6], [120, 30, "walk", 6], [129, 49, "walk", 6], [129, 80, "walk", 9],
		 [106, 82, "idle", 5], [129, 80, "walk", 6], [129, 49, "walk", 6], [120, 30, "walk", 6],
		 [86, 28, "walk", 6]])

func _build_player_hud() -> void:
	var player: Node = load("res://player/player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector2(-32, 5600)
	_root.add_child(player)
	player.owner = _root
	var hud: Node = load("res://ui/hud.tscn").instantiate()
	hud.name = "HUD"
	_root.add_child(hud)
	hud.owner = _root
