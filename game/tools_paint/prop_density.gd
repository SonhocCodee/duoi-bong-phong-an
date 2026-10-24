extends Node2D
## TEAM 2-A "Density pass": tang mat do prop/decal (va vai NPC phu) cho cac
## map bi che THUA. KHAC cac paint_*/build_* cu: tool nay LOAD scene hien
## tai tren dia (nguon su that) chi de PHAN TICH (TileMap, collision, vi
## tri NPC/quai/portal, lich trinh), tinh vi tri prop/decal/NPC phu roi
## XUAT ke hoach ra /tmp/density_plan.json. Viec ghi vao .tscn do script
## Python tools_paint/apply_density.py lam bang cach CHEN block node dang
## text vao cuoi file goc - giu nguyen 100% noi dung san co.
## (Da thu pack+save bang Godot: packer lam ROI override tren node con
## cua instance, vd sprite_frames rieng cua NPC - nen khong dung cach do.)
## Chay lai ca 2 buoc la an toan: apply_density.py tu xoa khoi
## DensityProps/NPC phu cua dot truoc truoc khi chen lai.
## Chay: godot --headless --path game res://tools_paint/prop_density.tscn
##
## Nguyen tac dat:
## - Chi dung prop TRANG TRI, KHONG tao collision -> khong the chan loi di
##   ve mat vat ly; them vao do la cac kiem tra khoang cach ben duoi.
## - Chi dat len o mat dat hop le theo TileMap (co/bu/swamp/cai tuyet...),
##   khong dat len nuoc/duong mon/ruong/da lat/duong chinh (truc decal thi
##   duoc len duong/da lat, vi decal nam phang z=-5).
## - Chua thong: portal/spawn (r=150), NPC + diem lich trinh (r=110) +
##   doan duong lich trinh (r=64), quai (r=100), herb/craft (r=100),
##   moi hinh chu nhat collision san co (mo rong 26px), prop/nha san co.
## - Rai CUM (3-6 prop/cum, ban kinh ~130) + rai le, seed co dinh tung map.

const TILE := 64.0

# ---- Phan loai o theo tileset -------------------------------------------
# Tra ve: grass / sand / snow / swamp / mud / stone / path / water /
#         shore / field / ice / plank / floor / none
func _cat_exterior(a: Vector2i) -> String:
	match a:
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(6, 2):
			return "grass"
		Vector2i(4, 0):
			return "path" # dirt: duong mon / san dat
		Vector2i(5, 0):
			return "field"
		Vector2i(6, 0), Vector2i(7, 0):
			return "water"
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1):
			return "path"
		Vector2i(6, 1), Vector2i(7, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2):
			return "shore"
		Vector2i(3, 2), Vector2i(4, 2):
			return "shore" # fence tile: chan nhu bo
		Vector2i(5, 2):
			return "stone" # pebbles
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

# ---- Cau hinh tung map ----------------------------------------------------
# veg/clutter: [ten texture, trong so, scale min, scale max]
# npcs: spawn/steps la toa do GLOBAL.
const MAPS := [
	{
		"path": "res://maps/lang_tan_diep.tscn", "seed": 20261024,
		"target_props": 150, "target_decals": 34,
		"veg": [["oak", 18, 0.50, 0.68], ["small_tree", 30, 0.70, 0.90], ["bush", 34, 0.80, 1.00], ["flower_bed", 18, 0.75, 0.95]],
		"clutter": [["boulder", 30, 0.80, 1.00], ["barrel", 25, 0.90, 1.10], ["sack", 25, 0.90, 1.10], ["wine_barrel", 20, 0.90, 1.10]],
		"decals": [["decal_moss", 45, 0.80, 1.10], ["decal_crack", 25, 0.80, 1.10], ["decal_stain", 30, 0.80, 1.10]],
		"veg_grounds": ["grass"], "clutter_grounds": ["grass"], "decal_grounds": ["grass", "path", "stone"],
		"focus": [{"rect": [-950, -750, 1150, 950], "props": 20, "decals": 6}],
		"npcs": [
			{"node": "NPC_Density_PhuHo", "id": "dan_tandiep_2", "display": "Anh Tu — phu ho Elmford",
			 "tint": Color(1, 0.85, 0.7), "spawn": Vector2(560, 470),
			 "steps": [[560, 470, "work", 7], [700, 520, "walk", 6], [700, 520, "idle", 5], [560, 640, "walk", 6], [560, 640, "idle", 4], [560, 470, "walk", 6]],
			 "done": ["Ranh thi giup ta xep may bao gao nhe. Lang minh dao nay yen hon truoc nhieu roi.", "Co cao ven duong la ta trong day — dung dam len nhe!"]},
			{"node": "NPC_Density_BanRau", "id": "dan_tandiep_3", "display": "Co Sau — ban rau Elmford",
			 "tint": Color(0.9, 1, 0.85), "spawn": Vector2(-60, 700),
			 "steps": [[-60, 700, "idle", 5], [140, 760, "walk", 6], [140, 760, "work", 7], [-60, 700, "walk", 6]],
			 "done": ["Rau sang nay tuoi lam, cat tu vuon sau lang day.", "Duong len Barleyfield dao nay bot slime hon truoc, di ban hang cung do so."]},
		],
	},
	{
		"path": "res://maps/dong_mach_nha.tscn", "seed": 20261025,
		"target_props": 160, "target_decals": 30,
		"veg": [["oak", 15, 0.50, 0.68], ["small_tree", 25, 0.70, 0.90], ["bush", 35, 0.80, 1.00], ["flower_bed", 25, 0.75, 0.95]],
		"clutter": [["boulder", 25, 0.80, 1.00], ["sack", 30, 0.90, 1.10], ["barrel", 25, 0.90, 1.10], ["wine_barrel", 20, 0.90, 1.10]],
		"decals": [["decal_moss", 45, 0.80, 1.10], ["decal_crack", 25, 0.80, 1.10], ["decal_stain", 30, 0.80, 1.10]],
		"veg_grounds": ["grass"], "clutter_grounds": ["grass"], "decal_grounds": ["grass", "path", "stone"],
		"focus": [{"rect": [-1150, -850, 1250, 750], "props": 20, "decals": 6}],
		"npcs": [
			{"node": "NPC_Density_NongDan2", "id": "nong_dan_2", "display": "Chu Nam — trong lua Barleyfield",
			 "tint": Color(1, 0.9, 0.75), "spawn": Vector2(-520, 760),
			 "steps": [[-520, 760, "work", 8], [-260, 880, "walk", 6], [-260, 880, "idle", 5], [-520, 760, "walk", 6]],
			 "done": ["Lua nam nay tot hon han — tu ngay bot slime pha ruong.", "Bu nhin ngoai ruong la ta dung day, thay no phat tay la chim bay het."]},
		],
	},
	{
		"path": "res://maps/thanh_xuan_lam.tscn", "seed": 20261026,
		"target_props": 110, "target_decals": 55,
		"veg": [["small_tree", 30, 0.95, 1.15], ["bush", 30, 0.90, 1.20], ["flower_bed", 40, 0.90, 1.10]],
		"clutter": [["barrel", 25, 0.90, 1.20], ["sack", 20, 0.90, 1.20], ["wine_barrel", 15, 0.90, 1.20], ["bench", 20, 0.90, 1.10], ["lamp", 20, 0.95, 1.10]],
		"decals": [["decal_crack", 40, 0.80, 1.10], ["decal_moss", 30, 0.80, 1.10], ["decal_stain", 30, 0.80, 1.10]],
		"veg_grounds": ["grass"], "clutter_grounds": ["grass", "stone"], "decal_grounds": ["grass", "path", "stone"],
		"seg_radius": 46.0, "prop_pt_radius": 54.0,
		"focus": [{"rect": [-2150, -2950, 2150, 1150], "props": 30, "decals": 20}, {"rect": [2550, -2450, 8150, 950], "props": 26, "decals": 12}, {"rect": [-750, 1050, 750, 5950], "props": 14, "decals": 10}],
		"npcs": [],
	},
	{
		"path": "res://maps/reedmere.tscn", "seed": 20261027,
		"target_props": 85, "target_decals": 18,
		"veg": [["reed_clump", 45, 0.90, 1.20], ["mangrove", 20, 0.85, 1.05], ["glowshroom", 15, 0.90, 1.20], ["bush", 20, 0.90, 1.20]],
		"clutter": [["swamp_log", 40, 0.90, 1.10], ["boulder", 20, 0.90, 1.20], ["sack", 20, 0.90, 1.20], ["barrel", 20, 0.90, 1.20]],
		"decals": [["decal_moss", 60, 0.80, 1.10], ["decal_stain", 40, 0.80, 1.10]],
		"veg_grounds": ["swamp", "mud"], "clutter_grounds": ["swamp", "mud"], "decal_grounds": ["swamp", "mud", "path"],
		"focus": [{"rect": [-1450, -350, 1550, 1550], "props": 16, "decals": 5}],
		"npcs": [
			{"node": "NPC_Density_HaiSay", "id": "dan_reedmere_2", "display": "Ba Tu — hai say Reedmere",
			 "tint": Color(0.95, 0.85, 1), "spawn": Vector2(700, 300),
			 "steps": [[700, 300, "idle", 5], [1050, 430, "walk", 6], [1050, 430, "work", 7], [700, 300, "walk", 6]],
			 "done": ["Say phai hai luc nuoc dang len, de lau la chim an het.", "Dam re o phia dong nhieu log muc lam — di can than truot chan."]},
		],
	},
	{
		"path": "res://maps/sunwell_oasis.tscn", "seed": 20261028,
		"target_props": 85, "target_decals": 18,
		"veg": [["palm_tree", 35, 0.85, 1.05], ["cactus", 35, 0.85, 1.10], ["bush", 30, 0.85, 1.10]],
		"clutter": [["boulder", 30, 0.90, 1.20], ["sack", 25, 0.90, 1.20], ["barrel", 25, 0.90, 1.20], ["bone_rib", 20, 0.60, 0.85]],
		"decals": [["decal_crack", 55, 0.80, 1.10], ["decal_stain", 45, 0.80, 1.10]],
		"veg_grounds": ["sand"], "clutter_grounds": ["sand", "stone"], "decal_grounds": ["sand", "path", "stone"],
		"focus": [{"rect": [-1750, -1450, 1850, 1450], "props": 14, "decals": 5}],
		"npcs": [
			{"node": "NPC_Density_LayNuoc", "id": "nguoi_lay_nuoc", "display": "Anh Ba — lay nuoc Sunwell",
			 "tint": Color(1, 0.9, 0.8), "spawn": Vector2(-620, 640),
			 "steps": [[-620, 640, "idle", 5], [-300, 860, "walk", 6], [-300, 860, "work", 7], [-620, 640, "walk", 6]],
			 "done": ["Nuoc oc dao la cua chung — lay vua du dung thoi day.", "Xuong doi phia dong co may xuong thu to lam, dung toi vao, ma cat day."]},
		],
	},
	{
		"path": "res://maps/hearthwick.tscn", "seed": 20261029,
		"target_props": 85, "target_decals": 18,
		"veg": [["snow_pine", 70, 0.85, 1.05], ["bush", 30, 0.85, 1.10]],
		"clutter": [["ice_rock", 35, 0.90, 1.20], ["boulder", 20, 0.90, 1.20], ["barrel", 20, 0.90, 1.20], ["sack", 15, 0.90, 1.20], ["campfire", 10, 0.80, 1.00]],
		"decals": [["decal_crack", 55, 0.80, 1.10], ["decal_stain", 45, 0.80, 1.10]],
		"veg_grounds": ["snow"], "clutter_grounds": ["snow", "stone"], "decal_grounds": ["snow", "path", "stone"],
		"focus": [{"rect": [-1750, -1450, 1850, 1450], "props": 14, "decals": 5}],
		"npcs": [
			{"node": "NPC_Density_QuetTuyet", "id": "dan_hearthwick_2", "display": "Chi Dong — quet tuyet Hearthwick",
			 "tint": Color(0.9, 0.95, 1), "spawn": Vector2(620, 560),
			 "steps": [[620, 560, "idle", 5], [900, 760, "walk", 6], [900, 760, "work", 6], [620, 560, "walk", 6]],
			 "done": ["Tuyet o day khong bao gio tan het — quet duoc lo nao hay lo ay.", "Lo lon cua lang ma tat la ca lang lanh. Nho them cui khi di ngang nhe."]},
		],
	},
	{
		"path": "res://maps/drownedwood.tscn", "seed": 20261030,
		"target_props": 110, "target_decals": 14,
		"veg": [["mangrove", 30, 0.85, 1.05], ["reed_clump", 45, 0.90, 1.20], ["glowshroom", 25, 0.90, 1.20]],
		"clutter": [["swamp_log", 60, 0.90, 1.10], ["boulder", 40, 0.90, 1.20]],
		"decals": [["decal_moss", 100, 0.80, 1.10]],
		"veg_grounds": ["swamp", "mud"], "clutter_grounds": ["swamp", "mud"], "decal_grounds": ["swamp", "mud", "path"],
		"npcs": [],
	},
	{
		"path": "res://maps/dunefield.tscn", "seed": 20261031,
		"target_props": 110, "target_decals": 14,
		"veg": [["cactus", 50, 0.85, 1.10], ["palm_tree", 20, 0.85, 1.05], ["bush", 30, 0.85, 1.10]],
		"clutter": [["bone_rib", 35, 0.60, 0.85], ["boulder", 35, 0.90, 1.20], ["sack", 30, 0.90, 1.20]],
		"decals": [["decal_crack", 100, 0.80, 1.10]],
		"veg_grounds": ["sand"], "clutter_grounds": ["sand"], "decal_grounds": ["sand", "path"],
		"npcs": [],
	},
	{
		"path": "res://maps/snowpine_forest.tscn", "seed": 20261032,
		"target_props": 110, "target_decals": 14,
		"veg": [["snow_pine", 80, 0.85, 1.05], ["bush", 20, 0.85, 1.10]],
		"clutter": [["ice_rock", 50, 0.90, 1.20], ["boulder", 50, 0.90, 1.20]],
		"decals": [["decal_crack", 100, 0.80, 1.10]],
		"veg_grounds": ["snow"], "clutter_grounds": ["snow"], "decal_grounds": ["snow", "path"],
		"npcs": [],
	},
]

var _fail := false
var _seg_radius := 64.0
var _prop_pt_radius := 72.0

var _plan := {}

func _ready() -> void:
	for cfg in MAPS:
		_process_map(cfg)
	var f := FileAccess.open("/tmp/density_plan.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_plan, "\t"))
		f.close()
		print("[DENSITY] da ghi /tmp/density_plan.json")
	else:
		print("[DENSITY] LOI: khong ghi duoc plan json")
		_fail = true
	print("[DENSITY] ====== HOAN TAT, fail=", _fail)
	get_tree().quit(1 if _fail else 0)

# ---- Thu thap chuong ngai --------------------------------------------------

var _solid_rects: Array[Rect2] = [] # collision san co (da tinh toa do global)
var _hard_pts: Array = [] # [Vector2, radius] portal/spawn/player
var _npc_pts: Array = [] # NPC/enemy/herb/craft + diem lich trinh
var _segments: Array = [] # [Vector2 a, Vector2 b] duong di lich trinh NPC
var _prop_pts: Array[Vector2] = [] # vi tri goc cua prop/nha san co (root children)
var _tilemaps: Array[TileMap] = []
var _ground_tm: TileMap = null
var _bounds := Rect2()

func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := 0.0
	if ab.length() > 0.01:
		t = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _collect(node: Node, root: Node) -> void:
	if node != root and node.name == "DensityProps":
		return
	if node is TileMap:
		_tilemaps.append(node)
		if node.name == "GroundTiles":
			_ground_tm = node
	if node is CollisionShape2D and node.shape != null:
		var cs := node as CollisionShape2D
		var c := cs.global_position
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
			_solid_rects.append(Rect2(c - sz * 0.5, sz))
	if node is Node2D and node != root:
		var n2 := node as Node2D
		var nm := node.name
		if nm.begins_with("Spawn_") or nm.begins_with("Portal"):
			_hard_pts.append([n2.global_position, 150.0])
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
		elif node.scene_file_path.find("herb_pickup") >= 0 or node.scene_file_path.find("craft_station") >= 0:
			_npc_pts.append([n2.global_position, 100.0])
		elif node.get_parent() == root and node is CharacterBody2D:
			_npc_pts.append([n2.global_position, 100.0])
		elif node.get_parent() == root and not (node is TileMap) and not (node is Label) \
				and not (node is Polygon2D) and not (node is ColorRect) and not (node is Camera2D):
			# Prop / nha / vat the goc o root: tranh de prop moi de len.
			# (bo qua cac node ao o goc toa do 0,0 kieu Label/Borders)
			if n2.global_position != Vector2.ZERO:
				_prop_pts.append(n2.global_position)
	for ch in node.get_children():
		_collect(ch, root)

func _compute_bounds() -> void:
	var first := true
	for tm in _tilemaps:
		var ur := tm.get_used_rect()
		if ur.size.x == 0 or ur.size.y == 0:
			continue
		var corners := [
			tm.map_to_local(ur.position),
			tm.map_to_local(ur.position + Vector2i(ur.size.x - 1, 0)),
			tm.map_to_local(ur.position + Vector2i(0, ur.size.y - 1)),
			tm.map_to_local(ur.end - Vector2i(1, 1)),
		]
		for lc in corners:
			var g: Vector2 = tm.global_transform * lc
			if first:
				_bounds = Rect2(g, Vector2.ZERO)
				first = false
			else:
				_bounds = _bounds.expand(g)
	_bounds = _bounds.grow_individual(-TILE * 0.5, -TILE * 0.5, -TILE * 0.5, -TILE * 0.5)
	_bounds = _bounds.grow(-48.0)

func _ground_cat(p: Vector2) -> String:
	# Uu tien: nuoc/bo/ruong/san nha (chan tat ca) > duong > da > o cua
	# GroundTiles. Overlay (StoneTiles, BridgeTiles...) duoc xet truoc.
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

func _clear_for(p: Vector2, is_decal: bool) -> bool:
	if not _bounds.has_point(p):
		return false
	for r in _solid_rects:
		if r.grow(20.0 if is_decal else 26.0).has_point(p):
			return false
	for hp in _hard_pts:
		if p.distance_to(hp[0]) < float(hp[1]) * (0.45 if is_decal else 1.0):
			return false
	for np_ in _npc_pts:
		if p.distance_to(np_[0]) < float(np_[1]) * (0.45 if is_decal else 1.0):
			return false
	if not is_decal:
		for s in _segments:
			if _seg_dist(p, s[0], s[1]) < _seg_radius:
				return false
		for pp in _prop_pts:
			if p.distance_to(pp) < _prop_pt_radius:
				return false
	return true

# ---- Tao node ---------------------------------------------------------------

func _make_prop(parent: Node, root: Node, tex_name: String, ground: Vector2,
		scl: float, flip: bool, seq: int, rng: RandomNumberGenerator) -> void:
	var tex: Texture2D = load("res://assets/props/" + tex_name + ".png")
	if tex == null:
		print("[DENSITY] LOI texture: ", tex_name)
		_fail = true
		return
	_plan_props.append({"tex": tex_name, "x": ground.x, "y": ground.y,
		"scl": scl, "flip": flip, "h": tex.get_height(), "seq": seq})

func _make_decal(parent: Node, root: Node, tex_name: String, pos: Vector2,
		scl: float, rng: RandomNumberGenerator) -> void:
	var tex: Texture2D = load("res://assets/props/" + tex_name + ".png")
	if tex == null:
		print("[DENSITY] LOI texture decal: ", tex_name)
		_fail = true
		return
	_plan_decals.append({"tex": tex_name, "x": pos.x, "y": pos.y,
		"scl": scl, "flip": rng.randf() < 0.5, "rot": rng.randf() * TAU})

func _pick_weighted(pool: Array, rng: RandomNumberGenerator) -> Array:
	var total := 0.0
	for it in pool:
		total += float(it[1])
	var r := rng.randf() * total
	for it in pool:
		r -= float(it[1])
		if r <= 0.0:
			return it
	return pool[pool.size() - 1]

func _sa(arr: Array) -> Array[String]:
	var out: Array[String] = []
	for s in arr:
		out.append(str(s))
	return out

var _plan_props: Array = []
var _plan_decals: Array = []
var _plan_npcs: Array = []

func _add_npc(root: Node, cfg_npc: Dictionary) -> void:
	var spawn: Vector2 = cfg_npc["spawn"]
	var steps_arr: Array = []
	for s in cfg_npc["steps"]:
		steps_arr.append([float(s[0]), float(s[1]), str(s[2]), float(s[3])])
	var tint: Color = cfg_npc["tint"]
	_plan_npcs.append({"node": str(cfg_npc["node"]), "id": str(cfg_npc["id"]),
		"display": str(cfg_npc["display"]), "tint": [tint.r, tint.g, tint.b, tint.a],
		"spawn": [spawn.x, spawn.y], "steps": steps_arr,
		"done": cfg_npc["done"]})
	# Dang ky chuong ngai ngay (spawn + diem/doan lich trinh) de prop
	# khong de len duong di cua NPC moi.
	_npc_pts.append([spawn, 110.0])
	var pts: Array[Vector2] = [spawn]
	for s in cfg_npc["steps"]:
		var sp := Vector2(float(s[0]), float(s[1]))
		pts.append(sp)
		_npc_pts.append([sp, 90.0])
	for i in pts.size():
		_segments.append([pts[i], pts[(i + 1) % pts.size()]])

# ---- Xu ly 1 map --------------------------------------------------------------

func _process_map(cfg: Dictionary) -> void:
	_plan_props = []
	_plan_decals = []
	_plan_npcs = []
	var path: String = cfg["path"]
	var ps: PackedScene = load(path)
	if ps == null:
		print("[DENSITY] LOAD FAIL ", path)
		_fail = true
		return
	var root: Node = ps.instantiate()
	add_child(root)
	# Neu map da co DensityProps (dot chay truoc da apply), bo qua khi
	# phan tich chuong ngai - apply_density.py se xoa va chen lai.
	_solid_rects.clear()
	_hard_pts.clear()
	_npc_pts.clear()
	_segments.clear()
	_prop_pts.clear()
	_tilemaps.clear()
	_ground_tm = null
	_collect(root, root)
	if _ground_tm == null and _tilemaps.size() > 0:
		_ground_tm = _tilemaps[0]
	_compute_bounds()
	print("[DENSITY] ", path.get_file(), " bounds=", _bounds, " solid_rects=", _solid_rects.size(),
		" hard=", _hard_pts.size(), " npc_pts=", _npc_pts.size(), " segs=", _segments.size(),
		" prop_pts=", _prop_pts.size())
	# NPC phu truoc, prop sau (de prop tranh duong NPC moi).
	var npc_cfgs: Array = cfg["npcs"]
	for nc in npc_cfgs:
		_add_npc(root, nc)
	var holder_root := Node2D.new() # node ao, chi de truyen vao _make_*
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cfg["seed"])
	var veg_pool: Array = cfg["veg"]
	var clutter_pool: Array = cfg["clutter"]
	var veg_grounds: Array = cfg["veg_grounds"]
	var clutter_grounds: Array = cfg["clutter_grounds"]
	_seg_radius = float(cfg.get("seg_radius", 64.0))
	_prop_pt_radius = float(cfg.get("prop_pt_radius", 72.0))
	var placed: Array[Vector2] = []
	var n_props := 0
	var n_veg := 0
	var n_clutter := 0
	var target := int(cfg["target_props"])
	var attempts := 0
	# Rai cum: 72% so prop di theo cum 3-6, con lai rai le.
	while n_props < target and attempts < target * 60:
		attempts += 1
		var center := Vector2(
			rng.randf_range(_bounds.position.x, _bounds.end.x),
			rng.randf_range(_bounds.position.y, _bounds.end.y))
		var in_cluster := rng.randf() < 0.72
		var cluster_n := rng.randi_range(3, 6) if in_cluster else 1
		for k in cluster_n:
			if n_props >= target:
				break
			var p := center
			if in_cluster and k > 0:
				var ang := rng.randf() * TAU
				var rad := sqrt(rng.randf()) * 130.0
				p = center + Vector2(cos(ang), sin(ang)) * rad
			var is_veg := rng.randf() < 0.65
			var cat := _ground_cat(p)
			if is_veg and not (cat in veg_grounds):
				# Thu doi sang clutter neu o nay hop clutter (vd da lat o thanh)
				if cat in clutter_grounds:
					is_veg = false
				else:
					continue
			if not is_veg and not (cat in clutter_grounds):
				continue
			if not _clear_for(p, false):
				continue
			var ok := true
			for q in placed:
				if p.distance_to(q) < 50.0:
					ok = false
					break
			if not ok:
				continue
			var pool := veg_pool if is_veg else clutter_pool
			if pool.is_empty():
				continue
			var item: Array = _pick_weighted(pool, rng)
			var scl := rng.randf_range(float(item[2]), float(item[3]))
			_make_prop(holder_root, root, str(item[0]), p, scl, rng.randf() < 0.5, n_props, rng)
			placed.append(p)
			n_props += 1
			if is_veg:
				n_veg += 1
			else:
				n_clutter += 1
	# Focus zones: rai bo sung tap trung quanh trung tam lang / quang
	# truong / cho (van dung cung kiem tra an toan, chi khac vung lay mau).
	for zone in cfg.get("focus", []):
		var zr: Array = zone["rect"]
		var zrect := Rect2(float(zr[0]), float(zr[1]), float(zr[2]) - float(zr[0]), float(zr[3]) - float(zr[1]))
		var z_target := n_props + int(zone["props"])
		var z_attempts := 0
		while n_props < z_target and z_attempts < int(zone["props"]) * 80:
			z_attempts += 1
			var zc := Vector2(rng.randf_range(zrect.position.x, zrect.end.x),
				rng.randf_range(zrect.position.y, zrect.end.y))
			var z_in_cluster := rng.randf() < 0.72
			var z_cluster_n := rng.randi_range(2, 4) if z_in_cluster else 1
			for k in z_cluster_n:
				if n_props >= z_target:
					break
				var p := zc
				if z_in_cluster and k > 0:
					var ang := rng.randf() * TAU
					var rad := sqrt(rng.randf()) * 110.0
					p = zc + Vector2(cos(ang), sin(ang)) * rad
				var is_veg := rng.randf() < 0.65
				var cat := _ground_cat(p)
				if is_veg and not (cat in veg_grounds):
					if cat in clutter_grounds:
						is_veg = false
					else:
						continue
				if not is_veg and not (cat in clutter_grounds):
					continue
				if not _clear_for(p, false):
					continue
				var ok := true
				for q in placed:
					if p.distance_to(q) < 50.0:
						ok = false
						break
				if not ok:
					continue
				var pool := veg_pool if is_veg else clutter_pool
				if pool.is_empty():
					continue
				var item: Array = _pick_weighted(pool, rng)
				var scl := rng.randf_range(float(item[2]), float(item[3]))
				_make_prop(holder_root, root, str(item[0]), p, scl, rng.randf() < 0.5, n_props, rng)
				placed.append(p)
				n_props += 1
				if is_veg:
					n_veg += 1
				else:
					n_clutter += 1
	# Decal
	var decal_pool: Array = cfg["decals"]
	var decal_grounds: Array = cfg["decal_grounds"]
	var d_placed: Array[Vector2] = []
	var n_decals := 0
	var d_target := int(cfg["target_decals"])
	var d_attempts := 0
	while n_decals < d_target and d_attempts < d_target * 80:
		d_attempts += 1
		var p := Vector2(
			rng.randf_range(_bounds.position.x, _bounds.end.x),
			rng.randf_range(_bounds.position.y, _bounds.end.y))
		if not (_ground_cat(p) in decal_grounds):
			continue
		if not _clear_for(p, true):
			continue
		var ok := true
		for q in d_placed:
			if p.distance_to(q) < 90.0:
				ok = false
				break
		if not ok:
			continue
		var item: Array = _pick_weighted(decal_pool, rng)
		_make_decal(holder_root, root, str(item[0]), p, rng.randf_range(float(item[2]), float(item[3])), rng)
		d_placed.append(p)
		n_decals += 1
	for zone in cfg.get("focus", []):
		var zr2: Array = zone["rect"]
		var zrect2 := Rect2(float(zr2[0]), float(zr2[1]), float(zr2[2]) - float(zr2[0]), float(zr2[3]) - float(zr2[1]))
		var zd_target := n_decals + int(zone["decals"])
		var zd_attempts := 0
		while n_decals < zd_target and zd_attempts < int(zone["decals"]) * 100:
			zd_attempts += 1
			var p := Vector2(rng.randf_range(zrect2.position.x, zrect2.end.x),
				rng.randf_range(zrect2.position.y, zrect2.end.y))
			if not (_ground_cat(p) in decal_grounds):
				continue
			if not _clear_for(p, true):
				continue
			var ok := true
			for q in d_placed:
				if p.distance_to(q) < 90.0:
					ok = false
					break
			if not ok:
				continue
			var item: Array = _pick_weighted(decal_pool, rng)
			_make_decal(holder_root, root, str(item[0]), p, rng.randf_range(float(item[2]), float(item[3])), rng)
			d_placed.append(p)
			n_decals += 1
	print("[DENSITY] ", path.get_file(), " -> props=", n_props, " (veg=", n_veg, ", clutter=", n_clutter,
		") decals=", n_decals, " npcs=", npc_cfgs.size(), " attempts=", attempts)
	if n_props < target * 0.6:
		print("[DENSITY] CANH BAO: dat it prop hon muc tieu nhieu o ", path.get_file())
	_plan[path] = {"props": _plan_props.duplicate(), "decals": _plan_decals.duplicate(), "npcs": _plan_npcs.duplicate()}
	remove_child(root)
	root.queue_free()
