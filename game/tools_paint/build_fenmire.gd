extends Node2D
## Tool mot lan: dung scene NOI THANH FENMIRE 220x160 o theo layout da duyet
## (design/fenmire_layout.md): cu lao giua dam, Grand Canal, Cho Noi, nha san
## huu co (nhieu co/mai, lech hang 0-2 o, hem van 2 o), Nha Thuong + Phong Vua
## Benh, Bai Muoi, Den Sanctum of the Sunken Tide o Noi Thanh Thuong phia Nam.
## Mo phong cau truc build_city.gd (Aldenmere): TileMap ground, prop sprite +
## collision tu dict _solid, _build_portals_spawns, _npc voi schedule,
## _build_player_hud.
## Chay: godot --headless --path game res://tools_paint/build_fenmire.tscn
## Ghi ra res://maps/fenmire.tscn.

const TILE := 64.0
const CW := 220
const CH := 160
const ORIGIN := Vector2(-7040.0, -5120.0) # (c-110)*64, (r-80)*64
const SAVE_PATH := "res://maps/fenmire.tscn"

const T := {
	"water_a": Vector2i(0, 0), "water_b": Vector2i(1, 0), "water_deep": Vector2i(2, 0),
	"mud_wet": Vector2i(3, 0), "mud_dry": Vector2i(4, 0),
	"grass": Vector2i(0, 1), "grass_reeds": Vector2i(1, 1),
	"plank": Vector2i(2, 1), "plank_mossy": Vector2i(3, 1), "shore_s": Vector2i(4, 1),
	"shore_n": Vector2i(0, 2), "shore_w": Vector2i(1, 2), "shore_e": Vector2i(2, 2),
	"shore_cvx": Vector2i(3, 2), "shore_ccv": Vector2i(4, 2),
	"mud_shore_s": Vector2i(0, 3), "mud_shore_n": Vector2i(1, 3), "mud_path_s": Vector2i(2, 3),
}
const INT := {
	"floor_a": Vector2i(0, 0), "floor_b": Vector2i(1, 0), "floor_dark": Vector2i(2, 0),
	"wall_plank": Vector2i(3, 0), "wall_stone": Vector2i(0, 1), "stone_floor": Vector2i(1, 1),
	"rug": Vector2i(2, 1), "floor_c": Vector2i(3, 1),
}
const STILT := {
	"stilt_house_a": 8, "stilt_house_b": 10, "stilt_house_c": 7, "stilt_house_d": 9,
}
const RAFTS := ["raft_stall_a", "raft_stall_b", "raft_stall_c"]

var _rng := RandomNumberGenerator.new()
var _solid := {}
var _plank_cells := {}
var _root: Node2D
var _tm: TileMap
var _tm_stone: TileMap
var _fail := false
var _house_seq := 0
var _raft_seq := 0

func _ready() -> void:
	_rng.seed = 20261024
	_build()
	print("[FENMIRE-CITY] ====== HOAN TAT, fail=", _fail)
	get_tree().quit(1 if _fail else 0)

# ---------------- helpers (mo phong build_city.gd) ----------------

func _cc(c: float, r: float) -> Vector2:
	# Tam o (c, r): x=(c-110)*64+32, y=(r-80)*64+32
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
		_tm_stone.set_cell(0, Vector2i(c, r), 0, INT[t])

func _pe_rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_pe(c, r, t)

func _ps_rect(c0: int, r0: int, c1: int, r1: int, t: String) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_ps(c, r, t)

# Son 1 o van go (san di duoc tren nuoc) + ghi nho de khong bi nuoc chan
func _pp(c: int, r: int) -> void:
	if c < 0 or c >= CW or r < 0 or r >= CH:
		return
	_pe(c, r, "plank" if _rng.randf() < 0.72 else "plank_mossy")
	_plank_cells[c + r * 1000] = true

func _pp_rect(c0: int, r0: int, c1: int, r1: int, ratio: float = 1.0) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			if ratio >= 1.0 or _rng.randf() < ratio:
				_pp(c, r)

func _water(c: int, r: int) -> void:
	_pe(c, r, "water_a" if _rng.randf() < 0.5 else "water_b")

func _water_rect(c0: int, r0: int, c1: int, r1: int) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			_water(c, r)

func _prop(tex_name: String, ground: Vector2, scl: float = 1.0, flip: bool = false,
		node_name: String = "") -> Node2D:
	var holder := Node2D.new()
	holder.position = ground
	holder.y_sort_enabled = true
	holder.name = node_name if node_name != "" else ("Prop_" + tex_name)
	var tex: Texture2D = load("res://assets/props/" + tex_name + ".png")
	if tex == null:
		print("[FENMIRE-CITY] LOI: khong load duoc texture ", tex_name)
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
		print("[FENMIRE-CITY] LOI: khong load duoc texture ", tex_name)
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

# Dat 1 toa nha san: tex rong w_tiles o, chan o hang bottom (va cham 2 hang day)
func _building(tex_name: String, left_c: int, bottom_r: int, w_tiles: int,
		depth: int = 2, flip: bool = false) -> void:
	var ground := Vector2(ORIGIN.x + (left_c + w_tiles / 2.0) * TILE,
		ORIGIN.y + (bottom_r + 1) * TILE)
	_house_seq += 1
	_prop(tex_name, ground, 1.0, flip, "House_%03d" % _house_seq)
	_mark_rect(left_c, bottom_r - depth + 1, left_c + w_tiles - 1, bottom_r)
	# Nha o dai nuoc phia nam (bottom >= 100): them bac van truoc san nha
	if bottom_r >= 100 and bottom_r + 1 < CH:
		_pp_rect(left_c, bottom_r + 1, left_c + w_tiles - 1, bottom_r + 1)

func _save_scene() -> void:
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err != OK:
		print("[FENMIRE-CITY] PACK LOI: ", err)
		_fail = true
		return
	err = ResourceSaver.save(packed, SAVE_PATH)
	print("[FENMIRE-CITY] save err=", err, " -> ", SAVE_PATH,
		" nodes=", _count_nodes(_root))
	if err != OK:
		_fail = true

func _count_nodes(n: Node) -> int:
	var total := 1
	for ch in n.get_children():
		total += _count_nodes(ch)
	return total

# ---------------- build chinh ----------------

func _build() -> void:
	_root = Node2D.new()
	_root.name = "Fenmire"
	_root.y_sort_enabled = true
	_root.set_script(load("res://systems/map_root.gd"))
	add_child(_root)
	_tm = TileMap.new()
	_tm.name = "GroundTiles"
	_tm.z_index = -10
	_tm.position = ORIGIN
	_tm.tile_set = load("res://assets/tilesets/swamp_v1.tres")
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
	_build_market()
	_build_fisher_west()
	_build_fisher_east()
	_build_hospice()
	_build_salt()
	_build_temple()
	_scatter_decor()
	_derive_water_collision()
	_build_collision()
	_build_portals_spawns()
	_build_npcs()
	_build_player_hud()
	_save_scene()

func _paint_ground() -> void:
	# Toan map la nuoc dam (ngoai cu lao)
	for c in CW:
		for r in CH:
			_pe(c, r, "water_deep" if _rng.randf() < 0.6 else "water_a")
	# Dat cu lao cot 8-211, hang 8-151: co dam + bun uot rai rac
	for c in range(8, 212):
		for r in range(8, 152):
			var v := _rng.randf()
			var t := "grass"
			if v < 0.14:
				t = "grass_reeds"
			elif v < 0.24:
				t = "mud_wet"
			elif v < 0.30:
				t = "mud_dry"
			_pe(c, r, t)
	# Go cao phia Nam (hang 107-146): bun kho lam nen dat giao phai
	for c in range(13, 207):
		for r in range(107, 147):
			if _rng.randf() < 0.78:
				_pe(c, r, "mud_dry")
	# Khuon vien den (trong tuong trong): nen bun kho dong nhat, sach kieu dat le
	_pe_rect(86, 109, 133, 146, "mud_dry")
	# Hao nuoc trong tuong: vanh hang/cot 13 va 146, cot 206
	_water_rect(13, 13, 206, 13)
	_water_rect(13, 146, 206, 146)
	_water_rect(13, 13, 13, 146)
	_water_rect(206, 13, 206, 146)
	# Grand Canal: cot 104-115, hang 13-104 (nuoc)
	_water_rect(104, 13, 115, 104)
	# Be quay thuyen truoc cong den: mo rong hang 100-104
	_water_rect(100, 100, 119, 104)
	# Be cho noi: cot 76-143, hang 22-40
	_water_rect(76, 22, 143, 40)
	# Dai nuoc duoi nha san phia nam 2 khu dan chai: hang 97-104
	_water_rect(16, 97, 96, 104)
	_water_rect(124, 97, 203, 104)
	# Be Trieu Nghi Le trong den
	_water_rect(100, 141, 119, 144)
	# Duong van 2 bo kenh (truc bo chinh)
	_pp_rect(97, 13, 103, 106)
	_pp_rect(116, 13, 123, 106)
	# San cong + san cong Bac: san van phu kin mieng kenh hang 10-15
	_pp_rect(104, 10, 115, 15)
	_pp_rect(97, 13, 123, 15)
	# Cau can ngoai cong Bac: 2 hanh lang van, giua la cua kenh nuoc
	_pp_rect(104, 0, 105, 9)
	_pp_rect(114, 0, 115, 9)
	# Duong ngang cho (hang 47-51): van 3 o + cau qua kenh
	_pp_rect(13, 48, 206, 50)
	_pp_rect(104, 47, 115, 51)
	# Duong ngang nam chan go cao (hang 105-106)
	_pp_rect(13, 105, 206, 106)
	# Vanh van quanh be cho noi + ben thuyen 2 ben
	_pp_rect(74, 20, 145, 21)
	_pp_rect(74, 41, 145, 42)
	_pp_rect(74, 20, 75, 42)
	_pp_rect(144, 20, 145, 42)
	_pp_rect(64, 16, 75, 46, 0.82)
	_pp_rect(144, 16, 155, 46, 0.82)
	# Ben pha Tay + loi qua cong nuoc
	_pp_rect(13, 56, 20, 60)
	_pp_rect(10, 57, 12, 59)
	# Nen lat da uot quanh den + san doi chat (StoneTiles)
	_ps_rect(92, 112, 127, 115, "stone_floor")
	_ps_rect(92, 139, 127, 145, "stone_floor")

func _build_walls() -> void:
	# Tuong ngoai go-da day 3 o (ve bang tile da tren StoneTiles + collision)
	_ps_rect(10, 10, 209, 12, "wall_stone")
	_ps_rect(10, 147, 209, 149, "wall_stone")
	_ps_rect(10, 10, 12, 149, "wall_stone")
	_ps_rect(207, 10, 209, 149, "wall_stone")
	_mark_rect(10, 10, 209, 12)
	_mark_rect(10, 147, 209, 149)
	_mark_rect(10, 10, 12, 149)
	_mark_rect(207, 10, 209, 149)
	# Ho cong Bac (cot 104-115) + cong nuoc Tay (hang 57-59)
	_unmark_rect(104, 10, 115, 12)
	_unmark_rect(10, 57, 12, 59)
	_ps_rect(104, 10, 115, 12, "floor_dark")
	# Thap canh go 4 goc trong tuong (5x5 o, trang tri + collision co san)
	for corner in [[16, 16], [203, 16], [16, 143], [203, 143]]:
		_prop("tower", _cc(corner[0], corner[1]) + Vector2(0, TILE), 0.85, false,
			"Tower_%d_%d" % [corner[0], corner[1]])
	# Cot cong Bac: 2 thap nho + den long + nhan thanh
	_prop("tower", _cc(101, 12) + Vector2(0, TILE), 0.8, false, "GateTowerL")
	_prop("tower", _cc(118, 12) + Vector2(0, TILE), 0.8, true, "GateTowerR")
	_mark(101, 11)
	_mark(118, 11)
	_prop("lamp", _cc(103, 14), 1.2, false, "GateLampL")
	_prop("lamp", _cc(116, 14), 1.2, false, "GateLampR")
	_mark(103, 14)
	_mark(116, 14)
	_label("FENMIRE", Vector2(109, 8), 40)
	# Tuong trong bao Noi Thanh Thuong (hang 107-108 + 2 hong), cong den MO
	_ps_rect(84, 107, 135, 108, "wall_stone")
	_ps_rect(84, 107, 85, 146, "wall_stone")
	_ps_rect(134, 107, 135, 146, "wall_stone")
	_mark_rect(84, 107, 135, 108)
	_mark_rect(84, 107, 85, 146)
	_mark_rect(134, 107, 135, 146)
	_unmark_rect(104, 107, 115, 108) # cong den mo (2 NPC tin do canh, khong khoa cung)
	_ps_rect(104, 107, 115, 108, "stone_floor")

func _build_market() -> void:
	# Bang nhiem vu goc tay-bac cho + cot den lon giua be
	_prop("table", _cc(66, 18), 1.1, false, "QuestBoard")
	_mark_rect(65, 17, 67, 18)
	_label("BANG NHIEM VU", Vector2(66, 15), 16)
	_prop("market_lamp", _cc(109, 32), 1.0, false, "CotDenCho")
	_label("FLOATING MARKET — CHO NOI", Vector2(109, 18), 22)
	_label("GRAND CANAL", Vector2(109, 70), 18)
	# ~28 sap be xO LECH 3 day long trong be (76-143 x 22-40), khong thang hang
	var raft_rows := [25, 31, 37]
	var deck_raft := Vector2i(97, 30) # be cua Tieu Thuong Be Ca (NPC dung duoc)
	for ri in raft_rows.size():
		var r0: int = raft_rows[ri]
		var cx := 79.0 + _rng.randf_range(-1.0, 1.5)
		while cx <= 138.0:
			var jr := r0 + _rng.randi_range(-1, 1)
			var jc := int(round(cx + _rng.randf_range(-1.2, 1.2)))
			cx += _rng.randf_range(6.4, 8.2)
			if abs(jc - 109) < 4 and jr >= 29 and jr <= 33:
				continue # tranh cot den lon giua be
			if abs(jc - deck_raft.x) < 4 and abs(jr - deck_raft.y) < 3:
				continue # de trong cho be cua NPC
			_raft(jc, jr)
	# Be rieng cua NPC Tieu Thuong (mat be di duoc de NPC dung ban hang)
	_raft(deck_raft.x, deck_raft.y, true)
	# Thuyen con neo o be + kenh + dai nuoc nha san
	for bp in [[84, 35], [126, 26], [136, 36], [109, 58], [110, 84], [40, 100], [170, 100], [90, 44]]:
		_prop("boat_small", _cc(bp[0], bp[1] + 1), 1.0, _rng.randf() < 0.5, "Boat_%d_%d" % [bp[0], bp[1]])
	# Thuyen pha o cong nuoc Tay (tren nuoc ngoai tuong)
	_prop("boat_ferry", _cc(7, 59), 1.0, false, "FerryBoat")
	# Coc neo + thung ca + luoi phoi o 2 ben thuyen
	for dp in [[66, 24], [70, 38], [150, 24], [148, 38], [66, 44], [152, 44]]:
		_prop("barrel" if _rng.randf() < 0.5 else "sack", _cc(dp[0], dp[1]), 1.0, false,
			"DockDeco_%d_%d" % [dp[0], dp[1]])
		_mark(dp[0], dp[1])

func _raft(cx: int, cy: int, walkable: bool = false) -> void:
	_raft_seq += 1
	var v: String = RAFTS[_rng.randi_range(0, RAFTS.size() - 1)]
	_prop(v, _cc(cx, cy + 1), 1.0, _rng.randf() < 0.4, "Raft%02d" % _raft_seq)
	if walkable:
		_unmark_rect(cx - 2, cy - 1, cx + 2, cy + 1)
		# danh dau la o van de _derive_water_collision khong chan lai
		for c in range(cx - 2, cx + 3):
			for r in range(cy - 1, cy + 2):
				_plank_cells[c + r * 1000] = true

# Mot hang nha san HUU CO: nhieu co/mai, lech hang, khoang hem 1-3 o bat quy tac.
# reserved: mang cac doan [c0, c1] phai chua (hem doc, san chung, loi di NPC)
func _house_row(x0: int, x1: int, bottom_r: int, reserved: Array) -> void:
	var keys := STILT.keys()
	var c := x0 + _rng.randi_range(0, 2)
	while c <= x1 - 6:
		if _rng.randf() < 0.18:
			var g := _rng.randi_range(1, 3)
			if g >= 2 and c + 1 <= x1:
				_prop("barrel" if _rng.randf() < 0.5 else "bush", _cc(c + 1, bottom_r), 0.9,
					false, "AlleyDeco_%d_%d" % [c, bottom_r])
			c += g
			continue
		var v: String = keys[_rng.randi_range(0, keys.size() - 1)]
		var w: int = int(STILT[v])
		if c + w - 1 > x1:
			break
		var clash := false
		for seg in reserved:
			if int(seg[1]) >= c and int(seg[0]) <= c + w - 1:
				clash = true
		if clash:
			c += 1
			continue
		_building(v, c, bottom_r, w, 2, _rng.randf() < 0.35)
		if _rng.randf() < 0.3:
			_prop("reed_clump" if _rng.randf() < 0.5 else "barrel",
				_cc(c + w - 1, bottom_r + 1), 0.85, false, "FrontDeco_%d_%d" % [c, bottom_r])
		c += w

func _paint_fisher_alleys() -> void:
	# Hem van ngang H-T1/H-T2/H-T3 ca 2 khu + hem doc + san van chung
	for rr in [64, 65, 78, 79, 92, 93]:
		_pp_rect(16, rr, 96, rr)
		_pp_rect(124, rr, 203, rr)
	for cc in [36, 37, 60, 61, 84, 85]:
		_pp_rect(cc, 52, cc, 104)
	for cc in [140, 141, 164, 165, 188, 189]:
		_pp_rect(cc, 52, cc, 104)
	_pp_rect(44, 82, 56, 90)   # San Van Chung Tay S-T
	_pp_rect(152, 82, 164, 90) # San Van Chung Dong S-D
	_pp_rect(190, 96, 203, 99) # bac van rieng truoc nha Nguoi Giu Trieu Gia

func _fisher_decor() -> void:
	# Decor hem van bat buoc: luoi phoi + ca kho, den long giua 2 day nha, thung
	for lx in [28, 52, 76]:
		_prop("laundry", _cc(lx, 66), 1.0, _rng.randf() < 0.5, "NetW_%d" % lx)
		_prop("laundry", _cc(lx + 4, 80), 1.0, _rng.randf() < 0.5, "NetW2_%d" % lx)
	for lx in [132, 156, 180]:
		_prop("laundry", _cc(lx, 66), 1.0, _rng.randf() < 0.5, "NetE_%d" % lx)
		_prop("laundry", _cc(lx + 4, 80), 1.0, _rng.randf() < 0.5, "NetE2_%d" % lx)
	for lp in [[48, 64], [72, 78], [30, 92], [148, 64], [172, 78], [196, 92]]:
		_prop("lamp", _cc(lp[0], lp[1]), 1.0, false, "AlleyLamp_%d_%d" % [lp[0], lp[1]])
		_mark(lp[0], lp[1])
	# San van chung: ban ca + ghe + gieng nho
	_prop("table", _cc(50, 86), 1.1, false, "SanTableW")
	_mark_rect(49, 85, 51, 86)
	_prop("bench", _cc(46, 88), 1.0, false, "SanBenchW")
	_prop("table", _cc(158, 86), 1.1, false, "SanTableE")
	_mark_rect(157, 85, 159, 86)
	_prop("bench", _cc(162, 88), 1.0, false, "SanBenchE")

func _build_fisher_west() -> void:
	_paint_fisher_alleys()
	var res := [[36, 37], [60, 61], [84, 85]]
	_house_row(16, 96, 63, res)          # day bac H-T1
	_house_row(17, 95, 77, res)          # day giua (lech 1 o so voi day bac)
	_house_row(16, 96, 91, [[36, 37], [44, 56], [60, 61], [84, 85]]) # chua San Van Chung
	_house_row(18, 94, 103, res)         # day nam tren dai nuoc (chan coc trong nuoc)
	# Nha lai pha gan ben pha + vai nha ven ben thuyen tay-bac
	_building("stilt_house_c", 20, 56, 7)
	_house_row(18, 60, 45, [[36, 37]])
	_fisher_decor()
	_label("KHU DAN CHAI TAY — NHA SAN", Vector2(52, 54), 16)

func _build_fisher_east() -> void:
	var res := [[140, 141], [164, 165], [188, 189]]
	_house_row(125, 202, 62, res)        # lech hang 1 o so voi khu Tay (khong doi xung)
	_house_row(124, 203, 76, res)
	_house_row(126, 202, 90, [[140, 141], [152, 164], [164, 165], [188, 189]])
	_house_row(124, 190, 102, res)
	# Nha Nguoi Giu Trieu Gia o cuoi hem cut dong-nam (192-201, day 102)
	_building("stilt_house_b", 192, 102, 10, 2, true)
	# Nha cua Nguoi Giu Den Cho (150, 58)
	_building("stilt_house_a", 146, 57, 8)
	_house_row(160, 200, 45, [[164, 165], [188, 189]])
	_label("KHU DAN CHAI DONG — NHA SAN", Vector2(164, 54), 16)

func _build_hospice() -> void:
	# Nha Thuong Trieu (148-178, day 129): 3 khoi lien nhau co/lech nhe
	_building("stilt_house_d", 148, 129, 9)
	_building("stilt_house_b", 159, 128, 10, 2, true)
	_building("stilt_house_a", 170, 129, 8)
	# Phong Vua Benh (nha rieng ap dong, King Oswin o (183,120))
	_building("stilt_house_b", 179, 125, 10, 2, false)
	_label("NHA THUONG TRIEU — PHONG VUA BENH", Vector2(168, 110), 16)
	# Kho Thuoc (182-201, day 138-139) + san phat thuoc (148-172, 132-139)
	_building("stilt_house_b", 183, 138, 10, 2, true)
	_building("stilt_house_c", 194, 139, 7)
	_pp_rect(148, 132, 172, 139)
	_prop("barrel", _cc(152, 134), 1.0, false, "HospBarrel1")
	_prop("sack", _cc(168, 136), 1.0, false, "HospSack1")
	_prop("bench", _cc(160, 138), 1.0, false, "HospBench")
	_label("SAN PHAT THUOC", Vector2(160, 131), 14)

func _build_salt() -> void:
	# O phoi muoi/ca (20-56, 114-132): nen bun kho + dong muoi + bap van
	_pe_rect(20, 114, 56, 132, "mud_dry")
	_pp_rect(20, 114, 56, 132, 0.30)
	for sp in [[26, 118], [36, 124], [46, 117], [30, 129], [50, 128], [42, 121]]:
		_prop("salt_pile", _cc(sp[0], sp[1]), 1.0, _rng.randf() < 0.5, "Salt_%d_%d" % [sp[0], sp[1]])
		_mark(sp[0], sp[1])
	# Kho muoi (60-74, day 125)
	_building("stilt_house_d", 61, 125, 9)
	_building("stilt_house_c", 71, 124, 7, 2, true)
	_prop("sack", _cc(58, 120), 1.0, false, "SaltSack")
	_label("BAI MUOI — SO CHE CA", Vector2(38, 111), 16)

func _build_temple() -> void:
	# Den Sanctum of the Sunken Tide: module lon chan o cot 98-121, day 138
	var ground := Vector2(ORIGIN.x + 109.5 * TILE, ORIGIN.y + 139 * TILE)
	_prop("temple_sanctum", ground, 1.0, false, "DenSanctum")
	_mark_rect(98, 128, 121, 138)
	# 2 canh phu cua den: nha giao si (86-90) + nha khach/tin do (129-133)
	_building("house_f", 86, 137, 5)
	_building("house_f", 129, 137, 5, 2, true)
	# Tuong nho + den tim 2 ben san nghi le
	for tp in [[96, 124], [123, 124]]:
		_prop("statue", _cc(tp[0], tp[1]), 0.55, false, "TempleStatue_%d" % tp[0])
		_mark(tp[0], tp[1] - 1)
	for lp in [[100, 114], [119, 114], [100, 140], [119, 140]]:
		_prop("lamp", _cc(lp[0], lp[1]), 1.1, false, "TempleLamp_%d_%d" % [lp[0], lp[1]])
		_mark(lp[0], lp[1])
	for gp in [[94, 118], [125, 132], [94, 144]]:
		_prop("glowshroom", _cc(gp[0], gp[1]), 1.0, false, "TempleGlow_%d_%d" % [gp[0], gp[1]])
	_label("SANCTUM OF THE SUNKEN TIDE", Vector2(109, 110), 22)
	_label("BE TRIEU NGHI LE — SAN DOI CHAT", Vector2(109, 146), 14)

func _scatter_decor() -> void:
	# Den doc 2 bo kenh
	for r in [24, 44, 64, 84, 100]:
		_prop("lamp", _cc(99, r), 1.05, false, "CanalLampW_%d" % r)
		_mark(99, r)
		_prop("lamp", _cc(120, r), 1.05, false, "CanalLampE_%d" % r)
		_mark(120, r)
	# Cay duoc + say ven tuong va quanh cu lao
	for tp in [[20, 20], [196, 20], [30, 140], [90, 20], [180, 140], [58, 16]]:
		_prop("mangrove", _cc(tp[0], tp[1]), 0.95, _rng.randf() < 0.5, "Mangrove_%d_%d" % [tp[0], tp[1]])
		_mark(tp[0], tp[1] - 1)
	for i in 14:
		var c := _rng.randi_range(14, 205)
		var r := _rng.randi_range(14, 145)
		_prop("reed_clump", _cc(c, r), 0.9, false, "Reed_%d" % i)
	for i in 6:
		_prop("glowshroom", _cc(_rng.randi_range(16, 200), _rng.randi_range(110, 144)), 0.9,
			false, "Glow_%d" % i)

func _derive_water_collision() -> void:
	# Nuoc = collision toan cuc, tru o co van/be NPC (da ghi trong _plank_cells)
	for c in CW:
		for r in CH:
			var at: Vector2i = _tm.get_cell_atlas_coords(0, Vector2i(c, r))
			if at == T["water_a"] or at == T["water_b"] or at == T["water_deep"]:
				_mark(c, r)
	for key in _plank_cells.keys():
		_solid.erase(key)

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
	print("[FENMIRE-CITY] collision shapes: ", body.get_child_count(), ", solid cells: ", _solid.size())

func _build_portals_spawns() -> void:
	var portal_ps: PackedScene = load("res://systems/portal.tscn")
	var defs := [
		["PortalNorthGate", Vector2(109, 11), "res://maps/fenmire_approach.tscn", "from_fenmire", "Fenmire Approach"],
		["PortalFerry", Vector2(14, 58), "res://maps/blackmere.tscn", "from_fenmire", "Blackmere (pha)"],
	]
	for d in defs:
		var p: Node = portal_ps.instantiate()
		p.name = d[0]
		p.position = _cc(d[1].x, d[1].y)
		p.set("target_scene", d[2])
		p.set("target_spawn", d[3])
		p.set("required_flag", "")
		p.set("label_text", d[4])
		_root.add_child(p)
		p.owner = _root
	var spawns := [
		["Spawn_start", Vector2(109, 14)],
		["Spawn_from_approach", Vector2(109, 14)],
		["Spawn_from_blackmere", Vector2(17, 58)],
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

func _npc_static(node_name: String, npc_id: String, display: String, cell: Vector2,
		tint: Color, quests: Array, dlg: Dictionary) -> void:
	var ps: PackedScene = load("res://systems/npc.tscn")
	var n: Node = ps.instantiate()
	n.name = node_name
	n.position = _cc(cell.x, cell.y)
	n.set("npc_id", npc_id)
	n.set("display_name", display)
	n.set("quest_ids", _sa(quests))
	n.set("shop_enabled", false)
	n.set("tint", tint)
	n.set("wander_radius", 0.0)
	n.set("dialogue_before", _sa(dlg.get("before", [])))
	n.set("dialogue_active", _sa(dlg.get("active", [])))
	n.set("dialogue_ready", _sa(dlg.get("ready", [])))
	n.set("dialogue_done", _sa(dlg.get("done", [])))
	# Schedule 1 buoc idle tai cho + schedule_enabled=false: NPC dung yen theo
	# quest, va tranh loi Godot serialize Array[Dictionary] rong thanh
	# Array[String] (loi type khi load scene).
	var stay: Array[Dictionary] = []
	var p := _cc(cell.x, cell.y)
	stay.append({"x": p.x, "y": p.y, "action": "idle", "time": 6.0})
	n.set("schedule", stay)
	n.set("schedule_enabled", false)
	_root.add_child(n)
	n.owner = _root

func _build_npcs() -> void:
	# 01 Linh canh cong Bac
	_npc("NPC_LinhCanhBac", "linh_canh_bac_fen", "Lính Canh Cổng Bắc", Vector2(106, 14),
		Color(0.8, 0.85, 1), 55.0, [], false,
		{"done": ["Cổng Bắc vừa là cổng bộ vừa là cửa kênh — thuyền hàng qua giữa, người đi hai bên ván.",
				"Chuông trên cổng là chuông triều: nó reo là nước đổi. Dân Fenmire sống theo tiếng chuông đó."]},
		[[106, 14, "idle", 6], [113, 14, "walk", 4], [113, 14, "idle", 6], [106, 14, "walk", 4]])
	# 02 Nguoi giu den cho
	_npc("NPC_GiuDenCho", "giu_den_cho", "Người Giữ Đèn Chợ", Vector2(150, 58),
		Color(1, 0.9, 0.75), 52.0, [], false,
		{"done": ["Đèn chợ mà tắt là chợ đêm đóng — và quái đầm bơi vào bể. Ta giữ ngọn đèn này mười hai năm chưa để tắt đêm nào.",
				"Chiều ta chèo ra cột đèn giữa bể châm dầu. Thấy ta ở vành đông là sắp tối rồi đấy."]},
		[[150, 30, "work", 10], [145, 31, "idle", 5], [150, 30, "walk", 5], [150, 58, "walk", 6], [150, 58, "idle", 6]])
	# 03 Tieu thuong be ca (shop)
	_npc("NPC_TieuThuongBe", "tieu_thuong_be", "Tiểu Thương Bè Cá", Vector2(30, 70),
		Color(0.9, 1, 0.9), 52.0, [], true,
		{"done": ["Cá đầm sáng nay tươi rói, thảo đầm hái ở Venomfen cũng có. Mua đi, bè ta neo giữa bể chợ đấy.",
				"Đứng ở vành ván gọi với sang cũng được — dân Fenmire mua bán bằng tiếng gọi quen rồi."]},
		[[97, 30, "work", 14], [70, 28, "walk", 6], [70, 28, "idle", 4], [97, 30, "walk", 6],
		 [30, 70, "walk", 8], [30, 70, "idle", 5]])
	# 04 Truong dan chai
	_npc("NPC_TruongDanChai", "truong_dan_chai", "Trưởng Dân Chài", Vector2(50, 86),
		Color(0.85, 0.9, 1), 55.0, ["nam_04_duong_thuy"], false,
		{"before": ["Dân chài ta giấu một chuyện: triều ở Fenmire không tự dâng. Có người giữ nó — và không phải giáo phái.",
				"Muốn nghe hết, gặp ta ở Sân Ván Chung. Sáng ta còn ra bến xem cá vào."],
		 "active": ["Đường thủy và chuyện Người Giữ Triều — hai thứ đó dính vào nhau đấy."],
		 "ready": ["Ngươi nghe kỹ chưa? Tên các đời Người Giữ Triều khắc dưới mực nước trong đền."],
		 "done": ["Sân ván này là nhà chung của dân chài. Có chuyện gì, cứ tới đây mà hỏi."]},
		[[70, 28, "work", 6], [50, 86, "walk", 8], [50, 86, "idle", 6], [50, 64, "work", 6], [50, 86, "walk", 6]])
	# 05 Dan chai
	_npc("NPC_DanChai1", "dan_chai_1", "Dân Chài", Vector2(66, 88),
		Color(0.9, 0.95, 0.85), 54.0, [], false,
		{"done": ["Sáng ta phụ bè cá ở chợ, chiều ra bãi muối. Tối ngồi hẻm Chuông Triều nghe ngóng giá thuốc.",
				"Thuốc lên giá là cá xuống giá. Dân đầm tính đời bằng hai thứ đó thôi."]},
		[[146, 34, "idle", 5], [38, 122, "walk", 10], [38, 122, "work", 10], [66, 79, "idle", 5], [66, 88, "walk", 5]])
	# 06 Tre con nha san
	_npc("NPC_TreConSan", "tre_con_san", "Trẻ Con Nhà Sàn", Vector2(172, 70),
		Color(1, 0.85, 0.7), 88.0, [], false,
		{"done": ["Em chạy vòng vành bể chợ nhanh nhất khu Đông đấy! Chiều em trốn tìm ở hẻm cụt gần nhà ông già giữ triều.",
				"Ông già ở cuối hẻm biết triều lên xuống trước cả chuông cổng. Người lớn không tin, chứ em tin."]},
		[[140, 42, "walk", 5], [109, 49, "idle", 3], [80, 42, "walk", 5], [196, 96, "walk", 8],
		 [196, 96, "idle", 4], [172, 70, "walk", 6]])
	# 07 Y si giao phai
	_npc("NPC_YSiGiaoPhai", "y_si_giao_phai", "Y Sĩ Giáo Phái", Vector2(152, 116),
		Color(0.9, 0.95, 1), 54.0, ["nam_02_danh_sach_thuoc", "nam_06a_giu_thoa_thuan"], false,
		{"before": ["Nhà Thương phát thuốc theo danh sách. Có tên trong sổ mới có thuốc — ta không tự quyết được, ngươi hiểu cho.",
				"Sân phát thuốc ở phía nam nhà thương. Sáng nào hàng người cũng dài tới cổng kho."],
		 "active": ["Sổ thuốc là chứng cứ đấy — ai gạch tên ai, đều có vết mực cả."],
		 "ready": ["Ngươi đã thấy cái giá của thỏa thuận rồi chứ?"],
		 "done": ["Ta là người của giáo phái trên giấy, người của bệnh nhân ngoài đời."]},
		[[160, 135, "work", 10], [163, 120, "walk", 6], [163, 120, "idle", 6], [123, 80, "walk", 8],
		 [123, 40, "walk", 7], [146, 30, "walk", 5], [146, 30, "idle", 4], [152, 116, "walk", 8]])
	# 08 Thu kho thuoc
	_npc("NPC_ThuKhoThuoc", "thu_kho_thuoc", "Thủ Kho Thuốc", Vector2(186, 134),
		Color(0.95, 0.9, 0.8), 52.0, [], false,
		{"done": ["Kho khóa hai lớp, sổ khóa một lớp nữa. Trưa ta đi ăn ở chợ — kho tự biết giữ mình.",
				"Dưới kho có hầm nối cống ngập. Ta không nói gì đâu — ta chỉ đang nói chuyện thời tiết thôi."]},
		[[191, 131, "idle", 8], [150, 45, "walk", 6], [150, 45, "idle", 5], [191, 131, "walk", 8], [191, 131, "idle", 8]])
	# 09 Dai giao si
	_npc("NPC_DaiGiaoSi", "dai_giao_si", "Đại Giáo Sĩ Triều Chìm", Vector2(88, 124),
		Color(0.85, 0.8, 1), 50.0, ["nam_05_den_chim_trieu", "nam_06a_giu_thoa_thuan"], false,
		{"before": ["Đền Sanctum giữ triều, giữ thuốc, giữ Fenmire khỏi chết chìm trong dịch. Ngươi đến để hỏi, hay để buộc tội?",
				"Ta tiếp dân trong đền buổi sáng. Chiều ta ra nhà thương xem phát thuốc."],
		 "active": ["Chứng cứ của ngươi nói một nửa. Triều nói nửa còn lại."],
		 "ready": ["Đến sân đền mà đối chất. Trước Bể Triều, không ai nói dối được lâu."],
		 "done": ["Giáo phái không cai Fenmire bằng lính. Chúng ta cai bằng thuốc — và bằng triều."]},
		[[109, 124, "work", 8], [109, 124, "idle", 6], [109, 105, "walk", 6], [150, 109, "walk", 7],
		 [160, 133, "walk", 8], [160, 133, "idle", 5], [109, 140, "work", 6], [88, 124, "walk", 6]])
	# 10 Morvain — NPC tinh theo quest (o Be Trieu Nghi Le, lui 1 o ve bac tranh o nuoc dac)
	_npc_static("NPC_Morvain", "morvain", "Morvain — Người Giữ Triều", Vector2(109, 140),
		Color(0.75, 0.7, 0.95),
		["nam_05_den_chim_trieu", "nam_06b_giu_trieu_moi", "nam_06c_pha_chu_ky"],
		{"before": ["Dân chỉ nói về ta khi triều rút. Ta là Người Giữ Triều — kẻ giáo phái mượn danh để bán thuốc.",
				"Đọc tên khắc dưới mực nước trong đền chìm đi, rồi quay lại đây. Lúc đó ta mới có chuyện để nói."],
		 "active": ["Triều không tự dâng. Nó được giữ — bởi tên, bởi chu kỳ, bởi người dám đọc đúng tên."],
		 "ready": ["Ngươi đã đọc được tên rồi. Vậy thì đối chất ở sân đền này — ba phe, một ông vua bệnh, và sự thật."],
		 "done": ["Giữ triều hay phá chu kỳ, Fenmire từ nay tự chịu lấy triều của mình."]})
	# 11 King Oswin — NPC tinh theo quest o Phong Vua Benh (183,120)
	_npc_static("NPC_VuaOswin", "vua_oswin", "King Oswin", Vector2(183, 120),
		Color(1, 0.9, 0.7), ["nam_02_danh_sach_thuoc", "nam_06a_giu_thoa_thuan", "nam_06b_giu_trieu_moi", "nam_06c_pha_chu_ky"],
		{"before": ["Ta là Oswin, vua của Fenmire... nằm trong nhà thương của kẻ mua nước mình. Ngươi cười đi, ta cũng cười.",
				"Ta ký thỏa thuận để dân có thuốc. Giá của nó, mỗi sáng ta nhìn hàng người ở sân phát thuốc là thấy."],
		 "active": ["Chứng cứ ngươi thu được — mang hết ra sân đền. Ta sẽ tới, dù phải khiêng."],
		 "ready": ["Đưa ta ra sân đền. Vua bệnh cũng là vua — lời của ta vẫn nặng ký ở Fenmire này."],
		 "done": ["Fenmire sau này thế nào, một phần do lựa chọn của ngươi ở sân đền hôm nay."]})
	# 12 Nguoi giu trieu gia
	_npc("NPC_GiuTrieuGia", "giu_trieu_gia", "Người Giữ Triều Già", Vector2(196, 98),
		Color(0.92, 0.92, 0.88), 46.0, ["nam_04_duong_thuy", "nam_05_den_chim_trieu"], false,
		{"before": ["Ta không tiếp người lạ. Trưởng Dân Chài giới thiệu, hoặc đứa trẻ nhà sàn dẫn đường — đó là lệ của hẻm cụt này.",
				"Sáng sớm ta ra hào đọc mực nước. Vạch triều không nói dối — người mới nói dối."],
		 "active": ["Triều ở Fenmire bị giữ từ trước khi giáo phái tới. Họ chỉ là kẻ đến sau, chiếm lấy nó."],
		 "ready": ["Ngươi đọc được vạch triều rồi à? Vậy ngươi hiểu vì sao tên phải khắc dưới nước."],
		 "done": ["Tối ta thắp một đèn nhỏ hướng ra đầm. Đèn cho người giữ triều cũ — và cho người giữ triều sau này."]},
		[[196, 98, "idle", 8], [200, 144, "walk", 10], [200, 144, "work", 6], [196, 98, "walk", 10]])
	# 13 Tin do tre
	_npc("NPC_TinDoTre", "tin_do_tre", "Tín Đồ Trẻ", Vector2(156, 126),
		Color(0.9, 0.9, 1), 54.0, ["nam_03a_pha_vuon", "nam_05_den_chim_trieu"], false,
		{"before": ["Ta phụ phát thuốc ở sân nhà thương. Trưa ta ra vành đông bể chợ — ở đó nói chuyện đỡ bị nghe hơn.",
				"Có chuyện về thuốc thử... nếu ngươi đã có chứng cứ ở Venomfen, trưa nay hãy tìm ta ở bể chợ."],
		 "active": ["Thuốc thử trên người bệnh nặng — ta ghi lại hết, nhưng ta không dám giữ sổ một mình."],
		 "ready": ["Mang chứng cứ ra sân đền đi. Ta sẽ nói phần của ta."],
		 "done": ["Ta vào giáo phái để cứu người. Giờ ta mới biết cứu người cũng phải đúng cách."]},
		[[166, 135, "work", 8], [146, 30, "walk", 7], [146, 30, "idle", 6], [156, 126, "walk", 7]])
	# 14 Nguoi lai pha
	_npc("NPC_LaiPha", "lai_pha", "Người Lái Phà", Vector2(16, 58),
		Color(0.95, 0.95, 0.85), 50.0, [], false,
		{"done": ["Phà của ta chạy từ cổng nước này sang Blackmere. Gọi là đi — triều thuận ta chèo một mạch.",
				"Sau khi đường thủy thông, ta còn chạy thuyền dọc Grand Canal cho ai lười đi ván."]},
		[[16, 58, "idle", 8], [24, 58, "walk", 4], [24, 58, "idle", 5], [16, 58, "walk", 4]])
	# 15 Linh tuan kenh
	_npc("NPC_LinhTuanKenh", "linh_tuan_kenh", "Lính Tuần Kênh", Vector2(120, 14),
		Color(0.85, 0.85, 1), 62.0, [], false,
		{"done": ["Tuyến của ta: cổng Bắc — bờ tây xuống — cầu chợ — bờ đông lên. Thành này ít lính, vì giáo phái cai bằng thuốc chứ không bằng quân."]},
		[[110, 14, "idle", 4], [100, 20, "walk", 5], [100, 60, "walk", 9], [110, 49, "walk", 5],
		 [120, 49, "walk", 4], [120, 30, "walk", 6], [120, 16, "walk", 5], [100, 16, "walk", 5],
		 [100, 105, "walk", 10], [120, 105, "walk", 5], [120, 60, "walk", 7]])
	# 2 tin do canh cong den (cong MO, khong khoa cung)
	_npc("NPC_TinDoCanh1", "tin_do_canh_1", "Tín Đồ Canh Cổng Đền", Vector2(106, 108),
		Color(0.88, 0.84, 1), 48.0, [], false,
		{"done": ["Cổng đền không khóa — nhưng sân đền là đất lễ. Vào thì giữ lễ, hỏi thì hỏi cho đúng người."]},
		[[106, 108, "idle", 6], [104, 108, "walk", 3], [106, 108, "walk", 3]])
	_npc("NPC_TinDoCanh2", "tin_do_canh_2", "Tín Đồ Canh Cổng Đền", Vector2(112, 108),
		Color(0.88, 0.84, 1), 48.0, [], false,
		{"done": ["Ngươi vào bằng cổng này, hay bằng đường nào khác? ...Thôi, ta không hỏi nữa."]},
		[[112, 108, "idle", 6], [114, 108, "walk", 3], [112, 108, "walk", 3]])

func _build_player_hud() -> void:
	var player: Node = load("res://player/player.tscn").instantiate()
	player.name = "Player"
	player.position = _cc(109, 14)
	_root.add_child(player)
	player.owner = _root
	var hud: Node = load("res://ui/hud.tscn").instantiate()
	hud.name = "HUD"
	_root.add_child(hud)
	hud.owner = _root
