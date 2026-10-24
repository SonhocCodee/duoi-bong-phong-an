extends Node2D
## PHÂN TÍCH LƯỚI — raster hoá va chạm của mỗi map dã ngoại thành lưới ô 64px
## và xuất bản đồ ASCII + summary (KHÔNG sửa gì trong scene).
## Với mỗi map trong MAPS:
##  - Lưới ô 64px bao phủ world rect (ưu tiên đọc /tmp/terrain_dump.json của
##    dump_terrain.gd; không có thì tự tính: TileMap union -> union shapes).
##  - Raster MỌI CollisionShape2D thuộc StaticBody2D: biến đổi về toạ độ toàn
##    cục, nới mỗi shape +8px mỗi phía. LOẠI TRỪ body thuộc instance NPC/quái/
##    player (kiểm tra scene_file_path + script của node tổ tiên instance).
##  - Độ phủ ô ước lượng bằng lấy mẫu 8x8 điểm con + test bao trọn 4 góc
##    (mọi shape hỗ trợ đều lồi nên 4 góc trong 1 shape => ô bị phủ 100%).
##    '#' = phủ >= 60% diện tích ô, '+' = phủ một phần (>0% và <60%), '.' = trống.
##  - Đè ký tự thực thể: P portal, S spawn, N npc, E quái, H herb, C craft,
##    L Label/điểm đặc biệt; kèm chú thích cuối file.
## Xuất: /tmp/grids/<ten_map>.txt cho từng map + /tmp/grids/summary.json
## Chạy: godot --headless --path game res://tools_paint/grid_probe.tscn

const OUT_DIR := "/tmp/grids"
const DUMP_PATH := "/tmp/terrain_dump.json"
const CELL := 64.0
const PAD := 8.0
const SUB := 8 # lấy mẫu SUB x SUB điểm trong 1 ô
const FULL_RATIO := 0.6

const PORTAL_SCRIPT := "res://systems/portal.gd"
const NPC_SCRIPT := "res://systems/npc.gd"
const PLAYER_SCRIPT := "res://player/player.gd"

# kind shape
const K_RECT := 0
const K_CIRCLE := 1
const K_CAPSULE := 2
const K_WBOUND := 3
const K_POLY := 4
const K_RECT_LOCAL := 5 # fallback: rect trong không gian local của shape (get_rect)
const K_SEGMENT := 6

const MAPS: Array[String] = [
	"lang_tan_diep", "dong_mach_nha", "bo_song_thanh", "rung_co_thu",
	"tim_rung", "ho_suong", "ngoai_thanh", "nui_thanh_van",
	"deo_thanh_van", "dinh_thanh_van", "mo_da_xanh", "duong_di_nam",
	"fenmire_approach", "miregate", "reedmere", "drownedwood",
	"venomfen", "blackmere", "fevercamp", "westgate", "dunefield",
	"sunwell_oasis", "redrock_canyon", "dunehawk_camp", "stonesong_camp",
	"buried_sand_ruins", "northgate", "hearthwick", "snowpine_forest",
	"frozen_lake", "howling_pass", "ghostwatch_post",
	"frostgard_approach", "dat_chet",
]

const CHAR_RANK := {"P": 7, "S": 6, "N": 5, "E": 4, "H": 3, "C": 2, "L": 1}

var _dump: Dictionary = {}
var _claimed: Dictionary = {} # instance_id -> true (node đã thuộc 1 mục thực thể)


func _ready() -> void:
	_run()


# --- helpers ---------------------------------------------------------------

func _vmin(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(minf(a.x, b.x), minf(a.y, b.y))


func _vmax(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(maxf(a.x, b.x), maxf(a.y, b.y))


func _script_path(n: Node) -> String:
	var sc: Script = n.get_script() as Script
	return sc.resource_path if sc != null else ""


func _has_prop(n: Node, pname: String) -> bool:
	for p in n.get_property_list():
		if str(p.get("name", "")) == pname:
			return true
	return false


func _pos_of(n: Node) -> Variant:
	if n is Node2D:
		return (n as Node2D).global_position
	if n is Control:
		return (n as Control).global_position
	return null


func _walk(n: Node, out: Array) -> void:
	out.append(n)
	for c in n.get_children():
		_walk(c, out)


func _is_under_claimed(n: Node, root: Node) -> bool:
	var cur: Node = n
	while cur != null and cur != root:
		if _claimed.has(cur.get_instance_id()):
			return true
		cur = cur.get_parent()
	return false


func _shape_aabb(cs: CollisionShape2D) -> Rect2:
	# AABB toàn cục của shape (chưa nới PAD), dùng cho bucket + fallback world rect.
	var sh := cs.shape
	if sh == null:
		return Rect2()
	var gt: Transform2D = cs.global_transform
	if sh is RectangleShape2D:
		var half := (sh as RectangleShape2D).size * 0.5
		var pts: Array[Vector2] = [
			gt * (-half), gt * Vector2(half.x, -half.y),
			gt * Vector2(-half.x, half.y), gt * half]
		var mn := pts[0]
		var mx := pts[0]
		for p in pts:
			mn = _vmin(mn, p)
			mx = _vmax(mx, p)
		return Rect2(mn, mx - mn)
	if sh is CircleShape2D:
		var r := (sh as CircleShape2D).radius
		var c := gt.origin
		return Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
	if sh is CapsuleShape2D:
		var cp := sh as CapsuleShape2D
		var c := gt.origin
		return Rect2(c - Vector2(cp.radius, cp.height * 0.5),
			Vector2(cp.radius * 2.0, cp.height))
	if sh is WorldBoundaryShape2D:
		return Rect2() # vô hạn — xử lý riêng khi raster
	var lr: Rect2 = sh.get_rect()
	if lr.size.x > 0.0 and lr.size.x < 100000.0 and lr.size.y < 100000.0:
		var pts2: Array[Vector2] = [
			gt * lr.position, gt * (lr.position + Vector2(lr.size.x, 0)),
			gt * (lr.position + Vector2(0, lr.size.y)), gt * (lr.position + lr.size)]
		var mn2 := pts2[0]
		var mx2 := pts2[0]
		for p in pts2:
			mn2 = _vmin(mn2, p)
			mx2 = _vmax(mx2, p)
		return Rect2(mn2, mx2 - mn2)
	return Rect2()


# --- shape records -----------------------------------------------------------

func _make_shape_rec(cs: CollisionShape2D, stats: Dictionary) -> Dictionary:
	# Trả {} nếu shape không dùng được (đã ghi vào stats).
	var sh := cs.shape
	if sh == null:
		stats["null_shapes"] = int(stats.get("null_shapes", 0)) + 1
		return {}
	var rec := {}
	rec["inv"] = cs.global_transform.affine_inverse()
	if sh is RectangleShape2D:
		rec["kind"] = K_RECT
		rec["half"] = (sh as RectangleShape2D).size * 0.5 + Vector2(PAD, PAD)
		rec["aabb"] = _shape_aabb(cs).grow(PAD)
		stats["rect"] = int(stats.get("rect", 0)) + 1
	elif sh is CircleShape2D:
		rec["kind"] = K_CIRCLE
		rec["r"] = (sh as CircleShape2D).radius + PAD
		rec["aabb"] = _shape_aabb(cs).grow(PAD)
		stats["circle"] = int(stats.get("circle", 0)) + 1
	elif sh is CapsuleShape2D:
		var cp := sh as CapsuleShape2D
		rec["kind"] = K_CAPSULE
		rec["r"] = cp.radius + PAD
		rec["hs"] = maxf(0.0, cp.height * 0.5 - cp.radius)
		rec["aabb"] = _shape_aabb(cs).grow(PAD)
		stats["capsule"] = int(stats.get("capsule", 0)) + 1
	elif sh is WorldBoundaryShape2D:
		var pl: Plane = (sh as WorldBoundaryShape2D).plane
		rec["kind"] = K_WBOUND
		rec["n"] = Vector2(pl.normal.x, pl.normal.y)
		rec["d"] = pl.d
		rec["aabb"] = Rect2() # vô hạn: bucket = toàn lưới
		stats["world_boundary"] = int(stats.get("world_boundary", 0)) + 1
	elif sh is ConvexPolygonShape2D:
		rec["kind"] = K_POLY
		rec["pts"] = (sh as ConvexPolygonShape2D).points
		rec["aabb"] = _shape_aabb(cs).grow(PAD)
		stats["convex_polygon"] = int(stats.get("convex_polygon", 0)) + 1
	elif sh is SegmentShape2D:
		var sg := sh as SegmentShape2D
		rec["kind"] = K_SEGMENT
		rec["a"] = sg.a
		rec["b"] = sg.b
		rec["aabb"] = _shape_aabb(cs).grow(PAD)
		stats["segment"] = int(stats.get("segment", 0)) + 1
	else:
		# Shape lạ: fallback rect theo get_rect() trong không gian local.
		var lr: Rect2 = sh.get_rect()
		var kinds: Dictionary = stats.get("unknown_shapes", {})
		kinds[sh.get_class()] = int(kinds.get(sh.get_class(), 0)) + 1
		stats["unknown_shapes"] = kinds
		if lr.size.x <= 0.0 or lr.size.x >= 100000.0 or lr.size.y >= 100000.0:
			stats["skipped_shapes"] = int(stats.get("skipped_shapes", 0)) + 1
			return {}
		rec["kind"] = K_RECT_LOCAL
		rec["c"] = lr.get_center()
		rec["half"] = lr.size * 0.5 + Vector2(PAD, PAD)
		rec["aabb"] = _shape_aabb(cs).grow(PAD)
	return rec


func _pin(rec: Dictionary, p: Vector2) -> bool:
	# Điểm p (toạ độ thế giới) có nằm trong shape (đã nới PAD) không?
	var lp: Vector2 = rec["inv"] * p
	match int(rec["kind"]):
		K_RECT:
			var h: Vector2 = rec["half"]
			return absf(lp.x) <= h.x and absf(lp.y) <= h.y
		K_CIRCLE:
			var r: float = rec["r"]
			return lp.length_squared() <= r * r
		K_CAPSULE:
			var r2: float = rec["r"]
			var cy := clampf(lp.y, -float(rec["hs"]), float(rec["hs"]))
			var dv := Vector2(lp.x, lp.y - cy)
			return dv.length_squared() <= r2 * r2
		K_WBOUND:
			var n: Vector2 = rec["n"]
			# Phía đặc của WorldBoundary là phía ngược normal; nới ra PAD.
			return n.dot(lp) - float(rec["d"]) <= PAD
		K_POLY:
			var pts: PackedVector2Array = rec["pts"]
			if Geometry2D.is_point_in_polygon(lp, pts):
				return true
			for i in pts.size():
				var a := pts[i]
				var b := pts[(i + 1) % pts.size()]
				if Geometry2D.get_closest_point_to_segment(lp, a, b).distance_to(lp) <= PAD:
					return true
			return false
		K_RECT_LOCAL:
			var c: Vector2 = rec["c"]
			var h2: Vector2 = rec["half"]
			return absf(lp.x - c.x) <= h2.x and absf(lp.y - c.y) <= h2.y
		K_SEGMENT:
			var a2: Vector2 = rec["a"]
			var b2: Vector2 = rec["b"]
			return Geometry2D.get_closest_point_to_segment(lp, a2, b2).distance_to(lp) <= PAD
	return false


func _coverage(cands: Array, x0: float, y0: float) -> float:
	# Ước lượng tỉ lệ diện tích ô [x0,x0+64) x [y0,y0+64) bị phủ bởi shapes.
	if cands.is_empty():
		return 0.0
	# Test bao trọn: shape lồi chứa cả 4 góc => phủ 100%.
	var corners: Array[Vector2] = [
		Vector2(x0, y0), Vector2(x0 + CELL, y0),
		Vector2(x0, y0 + CELL), Vector2(x0 + CELL, y0 + CELL)]
	for rec in cands:
		var all_in := true
		for cn in corners:
			if not _pin(rec, cn):
				all_in = false
				break
		if all_in:
			return 1.0
	# Lấy mẫu SUB x SUB, thoát sớm khi đã chắc chắn phân loại.
	var total := SUB * SUB
	var need := int(ceil(FULL_RATIO * float(total))) # >= need điểm => '#'
	var blocked := 0
	var tested := 0
	var step := CELL / float(SUB)
	for sy in SUB:
		for sx in SUB:
			var p := Vector2(x0 + (float(sx) + 0.5) * step,
				y0 + (float(sy) + 0.5) * step)
			tested += 1
			for rec in cands:
				if _pin(rec, p):
					blocked += 1
					break
			if blocked >= need:
				return float(blocked) / float(total)
			if blocked > 0 and blocked + (total - tested) < need:
				return float(blocked) / float(total) # chắc chắn '+'
	return float(blocked) / float(total)


# --- loại trừ body của NPC/quái/player ---------------------------------------

func _is_excluded_body(b: StaticBody2D, root: Node) -> bool:
	var cur: Node = b
	while cur != null and cur != root:
		var sfp := cur.scene_file_path
		if sfp.begins_with("res://enemies/") or sfp.begins_with("res://player/") \
				or sfp == "res://systems/npc.tscn":
			return true
		var sp := _script_path(cur)
		if sp == NPC_SCRIPT or sp == PLAYER_SCRIPT or sp.begins_with("res://enemies/"):
			return true
		if cur.is_in_group("enemy") or cur.is_in_group("npc"):
			return true
		cur = cur.get_parent()
	return false


# --- world rect ----------------------------------------------------------------

func _world_rect(slug: String, m: Node, all: Array) -> Rect2:
	# Ưu tiên 1: /tmp/terrain_dump.json
	if _dump.has(slug):
		var e: Dictionary = _dump[slug]
		var wr: Variant = e.get("world_rect_px", null)
		if wr is Dictionary:
			var d: Dictionary = wr
			return Rect2(float(d.get("x", 0.0)), float(d.get("y", 0.0)),
				float(d.get("w", 0.0)), float(d.get("h", 0.0)))
	# Fallback: union TileMap (layer đang bật)
	var world := Rect2()
	var has := false
	for n in all:
		if n is TileMap:
			var tm := n as TileMap
			if tm.tile_set == null:
				continue
			var ts := Vector2(tm.tile_set.tile_size)
			for layer in tm.get_layers_count():
				if not tm.is_layer_enabled(layer):
					continue
				var cells := tm.get_used_cells(layer)
				if cells.is_empty():
					continue
				var mn := cells[0]
				var mx := cells[0]
				for c in cells:
					mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
					mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
				var local := Rect2(tm.map_to_local(mn), Vector2(mx - mn + Vector2i.ONE) * ts)
				local.position -= ts * 0.5
				var gt: Transform2D = tm.global_transform
				var pts: Array[Vector2] = [
					gt * local.position,
					gt * (local.position + Vector2(local.size.x, 0)),
					gt * (local.position + Vector2(0, local.size.y)),
					gt * (local.position + local.size)]
				var pmn := pts[0]
				var pmx := pts[0]
				for p in pts:
					pmn = _vmin(pmn, p)
					pmx = _vmax(pmx, p)
				var r := Rect2(pmn, pmx - pmn)
				if not has:
					world = r
					has = true
				else:
					world = world.merge(r)
	if has:
		return world
	# Fallback 2: union mọi CollisionShape2D
	for n in all:
		if n is CollisionShape2D:
			var r2 := _shape_aabb(n as CollisionShape2D)
			if r2.size.x > 0.0:
				if not has:
					world = r2
					has = true
				else:
					world = world.merge(r2)
	return world


# --- thực thể -------------------------------------------------------------------

func _under_canvas_layer(n: Node) -> bool:
	var cur: Node = n.get_parent()
	while cur != null:
		if cur is CanvasLayer:
			return true
		cur = cur.get_parent()
	return false


func _classify_entity(n: Node) -> Dictionary:
	# Trả {"ch": ký tự, "extra": mô tả} hoặc {} nếu không phải thực thể cần ghi.
	# Node dưới CanvasLayer là UI/HUD (vd Label trong SkillPanel của player)
	# chứ không phải điểm đặc biệt trong thế giới — bỏ qua.
	if _under_canvas_layer(n):
		return {}
	var sp := _script_path(n)
	var sfp := n.scene_file_path
	if sp == PORTAL_SCRIPT or sfp == "res://systems/portal.tscn":
		var extra := "target_scene=%s target_spawn=%s" % [
			str(n.get("target_scene")) if _has_prop(n, "target_scene") else "?",
			str(n.get("target_spawn")) if _has_prop(n, "target_spawn") else "?"]
		if _has_prop(n, "required_flag") and str(n.get("required_flag")) != "":
			extra += " required_flag=%s" % str(n.get("required_flag"))
		return {"ch": "P", "extra": extra}
	if n is Marker2D and n.name.begins_with("Spawn"):
		return {"ch": "S", "extra": "marker"}
	if _has_prop(n, "npc_id") or n.is_in_group("npc") or sp == NPC_SCRIPT \
			or sfp == "res://systems/npc.tscn":
		var extra := "npc_id=%s" % (str(n.get("npc_id")) if _has_prop(n, "npc_id") else "")
		return {"ch": "N", "extra": extra}
	if _has_prop(n, "enemy_type") or sp.begins_with("res://enemies/") \
			or sfp.begins_with("res://enemies/") or n.is_in_group("enemy"):
		var src := sfp if sfp != "" else sp
		return {"ch": "E", "extra": "scene=%s" % src.get_file()}
	if n.name.contains("Herb") or sp == "res://systems/herb_pickup.gd" \
			or sfp == "res://systems/herb_pickup.tscn":
		return {"ch": "H", "extra": ""}
	if n.name.contains("Craft") or sp == "res://systems/craft_station.gd" \
			or sfp == "res://systems/craft_station.tscn":
		return {"ch": "C", "extra": ""}
	if n is Label:
		var txt := str(n.get("text")) if _has_prop(n, "text") else ""
		if txt.length() > 40:
			txt = txt.substr(0, 40) + "..."
		return {"ch": "L", "extra": "label text=\"%s\"" % txt.replace("\n", " ")}
	if sfp == "res://systems/chest.tscn" or sfp == "res://systems/seal_altar.tscn" \
			or sfp == "res://systems/locked_door.tscn" \
			or sp == "res://systems/chest.gd" or sp == "res://systems/seal_altar.gd" \
			or sp == "res://systems/locked_door.gd":
		return {"ch": "L", "extra": "special scene=%s" % sfp.get_file()}
	if n is Marker2D:
		return {"ch": "L", "extra": "marker"}
	return {}


# --- xử lý 1 map ------------------------------------------------------------------

func _probe_map(slug: String) -> Dictionary:
	var summary := {}
	var map_path := "res://maps/%s.tscn" % slug
	if not ResourceLoader.exists(map_path):
		print("[GRID] %s ERROR scene_not_found" % slug)
		return {"error": "scene_not_found"}
	var ps: PackedScene = load(map_path) as PackedScene
	if ps == null:
		print("[GRID] %s ERROR load_returned_null" % slug)
		return {"error": "load_returned_null"}
	var m: Node = ps.instantiate()
	if m == null:
		print("[GRID] %s ERROR instantiate_returned_null" % slug)
		return {"error": "instantiate_returned_null"}
	add_child(m)
	await get_tree().process_frame
	await get_tree().process_frame

	var all: Array = []
	_walk(m, all)

	# ---- world rect -> lưới
	var world := _world_rect(slug, m, all)
	if world.size.x <= 0.0 or world.size.y <= 0.0:
		remove_child(m)
		m.queue_free()
		await get_tree().process_frame
		print("[GRID] %s ERROR no_world_rect" % slug)
		return {"error": "no_world_rect"}
	var origin := Vector2(floor(world.position.x / CELL) * CELL,
		floor(world.position.y / CELL) * CELL)
	var wend := world.position + world.size
	var endp := Vector2(ceil(wend.x / CELL) * CELL,
		ceil(wend.y / CELL) * CELL)
	var gw := int(round((endp.x - origin.x) / CELL))
	var gh := int(round((endp.y - origin.y) / CELL))

	# ---- thu thập shapes của StaticBody2D (trừ NPC/quái/player)
	var stats := {}
	var recs: Array = []
	var bodies_total := 0
	var bodies_excluded := 0
	for n in all:
		if not (n is StaticBody2D):
			continue
		bodies_total += 1
		var b := n as StaticBody2D
		if _is_excluded_body(b, m):
			bodies_excluded += 1
			continue
		for cs in b.get_children():
			if not (cs is CollisionShape2D):
				continue
			var c2 := cs as CollisionShape2D
			if c2.disabled:
				stats["disabled_shapes"] = int(stats.get("disabled_shapes", 0)) + 1
				continue
			var rec := _make_shape_rec(c2, stats)
			if not rec.is_empty():
				recs.append(rec)

	# ---- bucket: ô -> danh sách shape index giao nhau (theo AABB đã nới PAD)
	var buckets := {}
	for idx in recs.size():
		var rec: Dictionary = recs[idx]
		var aabb: Rect2 = rec["aabb"]
		if int(rec["kind"]) == K_WBOUND:
			aabb = Rect2(origin, Vector2(gw, gh) * CELL)
		var cx0 := clampi(int(floor((aabb.position.x - origin.x) / CELL)), 0, gw - 1)
		var cy0 := clampi(int(floor((aabb.position.y - origin.y) / CELL)), 0, gh - 1)
		var aend := aabb.position + aabb.size
		var cx1 := clampi(int(floor((aend.x - 0.01 - origin.x) / CELL)), 0, gw - 1)
		var cy1 := clampi(int(floor((aend.y - 0.01 - origin.y) / CELL)), 0, gh - 1)
		for cy in range(cy0, cy1 + 1):
			for cx in range(cx0, cx1 + 1):
				var key := cy * gw + cx
				if not buckets.has(key):
					buckets[key] = []
				(buckets[key] as Array).append(idx)

	# ---- raster
	var rows: Array = [] # Array[Array[String]] — từng ký tự 1 ô, để đè overlay
	var n_full := 0
	var n_part := 0
	var n_free := 0
	for cy in gh:
		var row: Array = []
		var y0 := origin.y + float(cy) * CELL
		for cx in gw:
			var key := cy * gw + cx
			var ch := "."
			if buckets.has(key):
				var cands: Array = []
				for idx in buckets[key]:
					cands.append(recs[idx])
				var cov := _coverage(cands, origin.x + float(cx) * CELL, y0)
				if cov >= FULL_RATIO:
					ch = "#"
					n_full += 1
				elif cov > 0.0:
					ch = "+"
					n_part += 1
				else:
					n_free += 1
			else:
				n_free += 1
			row.append(ch)
		rows.append(row)

	# ---- thực thể
	_claimed.clear()
	var entities: Array = []
	for n in all:
		if n == m or _claimed.has(n.get_instance_id()) or _is_under_claimed(n, m):
			continue
		var info := _classify_entity(n)
		if info.is_empty():
			continue
		_claimed[n.get_instance_id()] = true
		var pos: Variant = _pos_of(n)
		if pos == null:
			continue
		var pv: Vector2 = pos
		var cx := int(floor((pv.x - origin.x) / CELL))
		var cy := int(floor((pv.y - origin.y) / CELL))
		entities.append({
			"ch": str(info["ch"]), "name": n.name,
			"path": str(m.get_path_to(n)), "pos": pv,
			"cx": cx, "cy": cy, "extra": str(info["extra"]),
			"inside": cx >= 0 and cx < gw and cy >= 0 and cy < gh,
		})
	# Đè lên lưới theo thứ hạng
	for e in entities:
		if not bool(e["inside"]):
			continue
		var cx2: int = e["cx"]
		var cy2: int = e["cy"]
		var row_arr: Array = rows[cy2]
		var cur := str(row_arr[cx2])
		var new_rank: int = CHAR_RANK.get(str(e["ch"]), 0)
		var cur_rank: int = CHAR_RANK.get(cur, 0)
		if new_rank > cur_rank:
			row_arr[cx2] = str(e["ch"])

	# ---- ghi file
	var lines: Array[String] = []
	lines.append("# MAP: %s" % slug)
	lines.append("# scene: %s" % map_path)
	lines.append("# world_rect_px: x=%.0f y=%.0f w=%.0f h=%.0f" % [
		world.position.x, world.position.y, world.size.x, world.size.y])
	lines.append("# world_rect_cells64: x=%d y=%d w=%d h=%d" % [
		int(round(world.position.x / CELL)), int(round(world.position.y / CELL)),
		int(round(world.size.x / CELL)), int(round(world.size.y / CELL))])
	lines.append("# grid: W=%d H=%d cell=64px" % [gw, gh])
	lines.append("# origin: cell (0,0) = world px (%.0f, %.0f) [goc tren-trai cua o]; tam o (cx,cy) = origin + (cx*64+32, cy*64+32)" % [
		origin.x, origin.y])
	lines.append("# legend: '#' chan >=60% dien tich o | '+' chan mot phan (<60%) | '.' trong")
	lines.append("# overlay: P portal | S spawn | N npc | E quai | H herb | C craft | L label/diem dac biet")
	lines.append("# dem theo va cham (truoc overlay): full=%d partial=%d free=%d tong=%d (%.1f%% chan it nhat mot phan)" % [
		n_full, n_part, n_free, gw * gh,
		100.0 * float(n_full + n_part) / float(maxi(1, gw * gh))])
	lines.append("# static_bodies: tong=%d loai_tru_npc_quai_player=%d shapes_dung=%d rect=%d circle=%d capsule=%d world_boundary=%d convex=%d segment=%d disabled_bo_qua=%d shape_la=%s shape_bo_qua=%d" % [
		bodies_total, bodies_excluded, recs.size(),
		int(stats.get("rect", 0)), int(stats.get("circle", 0)),
		int(stats.get("capsule", 0)), int(stats.get("world_boundary", 0)),
		int(stats.get("convex_polygon", 0)), int(stats.get("segment", 0)),
		int(stats.get("disabled_shapes", 0)),
		str(stats.get("unknown_shapes", {})),
		int(stats.get("skipped_shapes", 0))])
	lines.append("# --- GRID (hang 0 = phia bac / y nho nhat) ---")
	for cy3 in gh:
		lines.append("".join(PackedStringArray(rows[cy3])))
	lines.append("# --- CHU THICH THUC THE ---")
	var portal_count := 0
	for e in entities:
		if str(e["ch"]) == "P":
			portal_count += 1
	for ch_kind in ["P", "S", "N", "E", "H", "C", "L"]:
		var label: String = str({"P": "PORTALS", "S": "SPAWNS", "N": "NPCS", "E": "ENEMIES",
			"H": "HERBS", "C": "CRAFT", "L": "LABELS/SPECIAL"}.get(ch_kind, ch_kind))
		lines.append("# %s:" % label)
		var found := false
		for e in entities:
			if str(e["ch"]) != ch_kind:
				continue
			found = true
			var pv2: Vector2 = e["pos"]
			lines.append("#  %s @ cell (%d,%d) world (%.0f, %.0f) name=%s path=%s %s%s" % [
				ch_kind, int(e["cx"]), int(e["cy"]), pv2.x, pv2.y,
				str(e["name"]), str(e["path"]), str(e["extra"]),
				"" if bool(e["inside"]) else " [NGOAI LUOI]"])
		if not found:
			lines.append("#  (khong co)")
	var out_path := "%s/%s.txt" % [OUT_DIR, slug]
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		push_error("[GRID] Khong mo duoc file xuat: " + out_path)
	else:
		f.store_string("\n".join(PackedStringArray(lines)) + "\n")
		f.close()

	remove_child(m)
	m.queue_free()
	await get_tree().process_frame

	summary = {
		"w": gw, "h": gh, "blocked_full": n_full,
		"blocked_partial": n_part, "free": n_free,
		"portal_count": portal_count,
	}
	print("[GRID] %s %dx%d full=%d part=%d free=%d portals=%d shapes=%d bodies_excl=%d" % [
		slug, gw, gh, n_full, n_part, n_free, portal_count, recs.size(), bodies_excluded])
	return summary


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	# Nạp terrain dump (nếu có) để lấy world rect cho khớp với dump_terrain.
	if FileAccess.file_exists(DUMP_PATH):
		var df := FileAccess.open(DUMP_PATH, FileAccess.READ)
		if df != null:
			var parsed: Variant = JSON.parse_string(df.get_as_text())
			df.close()
			if parsed is Dictionary:
				_dump = parsed
				print("[GRID] Da nap %s (%d muc)" % [DUMP_PATH, _dump.size()])
	if _dump.is_empty():
		print("[GRID] Khong co terrain dump — world rect se tu tinh.")
	var summary_all := {}
	for slug in MAPS:
		var s := await _probe_map(slug)
		if s.has("error"):
			summary_all[slug] = {"error": str(s["error"])}
		else:
			summary_all[slug] = s
	var sf := FileAccess.open(OUT_DIR + "/summary.json", FileAccess.WRITE)
	if sf == null:
		push_error("[GRID] Khong mo duoc summary.json")
		get_tree().quit(1)
		return
	sf.store_string(JSON.stringify(summary_all, " "))
	sf.close()
	print("[GRID] DONE -> ", OUT_DIR)
	get_tree().quit()
