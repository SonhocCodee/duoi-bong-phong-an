extends Node2D
## KHẢO SÁT ĐỊA HÌNH — dump cấu trúc các map dã ngoại ra JSON phục vụ đợt
## cấu trúc lại địa hình (KHÔNG sửa gì trong scene).
## Với mỗi map trong MAPS: TileMap (layer đang bật, used_rect theo ô,
## histogram atlas), world_rect_px theo thứ tự ưu tiên (TileMap union ->
## Border* trong node Collisions -> union mọi CollisionShape2D), portal,
## spawn, NPC, blockers/entities, StaticBody2D shapes, props nền cho map
## không có TileMap.
## Histogram key "sx,sy:ax,ay": sx = source_id, sy = alternative_tile_id,
## ax,ay = atlas coords.
## Xuất JSON -> /tmp/terrain_dump.json
## Chạy: godot --headless --path game res://tools_paint/dump_terrain.tscn

const OUT_PATH := "/tmp/terrain_dump.json"
const PORTAL_SCRIPT := "res://systems/portal.gd"
const NPC_SCRIPT := "res://systems/npc.gd"
const MAX_HIST := 25
const MAX_STATIC_SHAPES := 60

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

var _claimed: Dictionary = {} # instance_id -> true (node đã thuộc 1 mục liệt kê)


func _ready() -> void:
	_run()


# --- helpers ---------------------------------------------------------------

func _f(v: float) -> float:
	return snappedf(v, 0.01)


# Godot 4.2.2 chưa có Vector2.min/max (vào từ 4.3) — thay bằng min/max theo trục.
# (analyze_edges.gd dùng mn.min(p) nên thực ra cũng parse-error trên 4.2.2.)
func _vmin(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(minf(a.x, b.x), minf(a.y, b.y))


func _vmax(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(maxf(a.x, b.x), maxf(a.y, b.y))


func _v2a(v: Vector2) -> Array:
	return [_f(v.x), _f(v.y)]


func _r2d(r: Rect2) -> Dictionary:
	return {"x": _f(r.position.x), "y": _f(r.position.y),
		"w": _f(r.size.x), "h": _f(r.size.y)}


func _r2id(r: Rect2i) -> Dictionary:
	return {"x": r.position.x, "y": r.position.y, "w": r.size.x, "h": r.size.y}


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
		return _v2a((n as Node2D).global_position)
	return null


func _rect_from_corners(tm: TileMap, cell_rect: Rect2i) -> Rect2:
	var ts := Vector2(tm.tile_set.tile_size)
	var local := Rect2(tm.map_to_local(cell_rect.position), Vector2(cell_rect.size) * ts)
	local.position -= ts * 0.5
	var gt: Transform2D = tm.global_transform
	var pts: Array[Vector2] = [
		gt * local.position,
		gt * (local.position + Vector2(local.size.x, 0)),
		gt * (local.position + Vector2(0, local.size.y)),
		gt * (local.position + local.size),
	]
	var mn := pts[0]
	var mx := pts[0]
	for p in pts:
		mn = _vmin(mn, p)
		mx = _vmax(mx, p)
	return Rect2(mn, mx - mn)


func _shape_rect(cs: CollisionShape2D) -> Rect2:
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
	# Fallback: Shape2D.get_rect() nội bộ (bỏ qua nếu vô hạn / quá lớn)
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


func _layer_used_rect(tm: TileMap, layer: int) -> Dictionary:
	var cells := tm.get_used_cells(layer)
	if cells.is_empty():
		return {"has": false, "rect": Rect2i(), "cells": cells}
	var mn := cells[0]
	var mx := cells[0]
	for c in cells:
		mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
		mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
	return {"has": true, "rect": Rect2i(mn, mx - mn + Vector2i.ONE), "cells": cells}


# --- dump 1 map --------------------------------------------------------------

func _dump_map(slug: String) -> Dictionary:
	var entry := {}
	entry["map"] = slug
	var map_path := "res://maps/%s.tscn" % slug
	entry["scene"] = map_path
	if not ResourceLoader.exists(map_path):
		entry["error"] = "scene_not_found"
		return entry
	var ps: PackedScene = load(map_path) as PackedScene
	if ps == null:
		entry["error"] = "load_returned_null"
		return entry
	var m: Node = ps.instantiate()
	if m == null:
		entry["error"] = "instantiate_returned_null"
		return entry
	add_child(m)
	await get_tree().process_frame
	await get_tree().process_frame

	_claimed.clear()
	var all: Array = []
	_walk(m, all)
	entry["node_count"] = all.size()

	# ---- 1. TileMap ------------------------------------------------------
	var tilemap_nodes: Array[TileMap] = []
	for n in all:
		if n is TileMap:
			tilemap_nodes.append(n as TileMap)
	var tilemaps: Array = []
	var tm_union := Rect2()
	var has_tm_union := false
	for tm in tilemap_nodes:
		_claimed[tm.get_instance_id()] = true
		var ts_path := ""
		var tile_size := Vector2i(64, 64)
		if tm.tile_set != null:
			ts_path = tm.tile_set.resource_path
			tile_size = tm.tile_set.tile_size
		var layers: Array = []
		var tm_total := 0
		var tm_union_cells := Rect2i()
		var tm_has_cells := false
		var disabled := 0
		for layer in tm.get_layers_count():
			if not tm.is_layer_enabled(layer):
				disabled += 1
				continue
			var lu := _layer_used_rect(tm, layer)
			var cells: Array = lu["cells"]
			var rect: Rect2i = lu["rect"]
			var hist := {}
			for cell in cells:
				var key := "%d,%d:%d,%d" % [
					tm.get_cell_source_id(layer, cell),
					tm.get_cell_alternative_tile(layer, cell),
					tm.get_cell_atlas_coords(layer, cell).x,
					tm.get_cell_atlas_coords(layer, cell).y]
				hist[key] = int(hist.get(key, 0)) + 1
			var pairs: Array = []
			for k in hist.keys():
				pairs.append([k, hist[k]])
			pairs.sort_custom(func(a, b): return int(a[1]) > int(b[1]))
			var top := {}
			for i in mini(MAX_HIST, pairs.size()):
				top[str(pairs[i][0])] = int(pairs[i][1])
			var lname := ""
			lname = tm.get_layer_name(layer)
			layers.append({
				"index": layer, "name": lname,
				"used_rect": _r2id(rect) if bool(lu["has"]) else null,
				"size_px": {"w": rect.size.x * tile_size.x, "h": rect.size.y * tile_size.y},
				"total_cells": cells.size(),
				"distinct_tiles": hist.size(),
				"histogram_top25": top,
			})
			tm_total += cells.size()
			if bool(lu["has"]):
				if not tm_has_cells:
					tm_union_cells = rect
					tm_has_cells = true
				else:
					tm_union_cells = tm_union_cells.merge(rect)
		var tm_entry := {}
		tm_entry["path"] = str(m.get_path_to(tm))
		tm_entry["name"] = tm.name
		tm_entry["tile_set"] = ts_path
		tm_entry["tile_size"] = [tile_size.x, tile_size.y]
		tm_entry["layers"] = layers
		tm_entry["disabled_layers"] = disabled
		tm_entry["total_cells"] = tm_total
		if tm_has_cells:
			var wr := _rect_from_corners(tm, tm_union_cells)
			tm_entry["used_rect_cells"] = _r2id(tm_union_cells)
			tm_entry["world_rect_px"] = _r2d(wr)
			if not has_tm_union:
				tm_union = wr
				has_tm_union = true
			else:
				tm_union = tm_union.merge(wr)
		else:
			tm_entry["used_rect_cells"] = null
			tm_entry["world_rect_px"] = null
		tilemaps.append(tm_entry)
	entry["tilemaps"] = tilemaps

	# ---- 3/4/5. Portal / Spawn / NPC ------------------------------------
	var portals: Array = []
	var spawns: Array = []
	var npcs: Array = []
	for n in all:
		var sp := _script_path(n)
		if sp == PORTAL_SCRIPT:
			_claimed[n.get_instance_id()] = true
			portals.append({
				"name": n.name, "path": str(m.get_path_to(n)),
				"pos": _pos_of(n),
				"target_scene": str(n.get("target_scene")),
				"target_spawn": str(n.get("target_spawn")),
				"required_flag": str(n.get("required_flag")),
			})
		elif n is Marker2D and n.name.begins_with("Spawn"):
			_claimed[n.get_instance_id()] = true
			spawns.append({
				"name": n.name, "path": str(m.get_path_to(n)),
				"pos": _pos_of(n),
			})
		elif _has_prop(n, "npc_id") or n.is_in_group("npc") or sp == NPC_SCRIPT:
			_claimed[n.get_instance_id()] = true
			npcs.append({
				"name": n.name, "path": str(m.get_path_to(n)),
				"pos": _pos_of(n),
				"npc_id": str(n.get("npc_id")) if _has_prop(n, "npc_id") else "",
				"script": sp,
			})
	entry["portals"] = portals
	entry["spawns"] = spawns
	entry["npcs"] = npcs

	# ---- 6. Blockers / entities ------------------------------------------
	var blockers: Array = []
	for n in all:
		if n == m or _claimed.has(n.get_instance_id()):
			continue
		if _is_under_claimed(n, m):
			continue
		var sp2 := _script_path(n)
		var category := ""
		if _has_prop(n, "enemy_type") or sp2.begins_with("res://enemies/") \
				or n.is_in_group("enemy"):
			category = "enemy"
		elif n.name.contains("Herb"):
			category = "herb"
		elif n.name.contains("Craft"):
			category = "craft"
		elif n is Area2D:
			category = "area_trigger"
		if category != "":
			_claimed[n.get_instance_id()] = true
			blockers.append({
				"category": category, "name": n.name,
				"path": str(m.get_path_to(n)), "type": n.get_class(),
				"pos": _pos_of(n), "script": sp2,
				"scene": n.scene_file_path,
			})
	# Mọi node trực tiếp dưới root chưa thuộc các mục đã liệt kê
	for c in m.get_children():
		if _claimed.has(c.get_instance_id()) or c is TileMap or c is StaticBody2D:
			continue
		blockers.append({
			"category": "root_child", "name": c.name,
			"path": str(m.get_path_to(c)), "type": c.get_class(),
			"pos": _pos_of(c), "script": _script_path(c),
			"scene": c.scene_file_path,
		})
	entry["blockers_entities"] = blockers

	# ---- 7. StaticBody2D ---------------------------------------------------
	var bodies: Array[StaticBody2D] = []
	for n in all:
		if n is StaticBody2D:
			bodies.append(n as StaticBody2D)
	var shapes: Array = []
	var total_shapes := 0
	for b in bodies:
		for cs in b.get_children():
			if not (cs is CollisionShape2D):
				continue
			total_shapes += 1
			if shapes.size() >= MAX_STATIC_SHAPES:
				continue
			var c2 := cs as CollisionShape2D
			var size_v: Variant = null
			var shape_type := "none"
			if c2.shape != null:
				shape_type = c2.shape.get_class()
				if c2.shape is RectangleShape2D:
					size_v = _v2a((c2.shape as RectangleShape2D).size)
			shapes.append({
				"body_path": str(m.get_path_to(b)),
				"name": c2.name, "path": str(m.get_path_to(c2)),
				"center": _v2a(c2.global_transform.origin),
				"size": size_v, "shape_type": shape_type,
			})
	entry["static_bodies"] = {
		"total_bodies": bodies.size(), "total_shapes": total_shapes,
		"truncated": total_shapes > shapes.size(), "shapes": shapes,
	}

	# ---- 2. world_rect_px --------------------------------------------------
	var world := Rect2()
	var has_world := false
	var world_source := "none"
	if has_tm_union:
		world = tm_union
		has_world = true
		world_source = "tilemap_union"
	else:
		# Ưu tiên 2: CollisionShape2D tên Border* trong node tên "Collisions"
		var border_rects: Array[Rect2] = []
		for n in all:
			if n.name == "Collisions":
				var sub: Array = []
				_walk(n, sub)
				for s in sub:
					if s is CollisionShape2D and s.name.begins_with("Border"):
						var r := _shape_rect(s as CollisionShape2D)
						if r.size.x > 0.0:
							border_rects.append(r)
		if not border_rects.is_empty():
			world = border_rects[0]
			for i in range(1, border_rects.size()):
				world = world.merge(border_rects[i])
			has_world = true
			world_source = "border_collisions"
		else:
			# Ưu tiên 3: union toàn bộ CollisionShape2D
			var any := false
			for n in all:
				if n is CollisionShape2D:
					var r2 := _shape_rect(n as CollisionShape2D)
					if r2.size.x > 0.0:
						if not any:
							world = r2
							any = true
						else:
							world = world.merge(r2)
			if any:
				has_world = true
				world_source = "all_collisions"
	if has_world:
		entry["world_rect_px"] = _r2d(world)
		entry["world_rect_source"] = world_source
		entry["world_rect_cells64"] = {
			"x": int(round(world.position.x / 64.0)),
			"y": int(round(world.position.y / 64.0)),
			"w": int(round(world.size.x / 64.0)),
			"h": int(round(world.size.y / 64.0)),
		}
	else:
		entry["world_rect_px"] = null
		entry["world_rect_source"] = "none"
		entry["world_rect_cells64"] = null

	# ---- 8. props_top (chỉ map không có TileMap) ---------------------------
	var props: Array = []
	if tilemap_nodes.is_empty():
		var counts := {}
		for c in m.get_children():
			if c is Polygon2D or c is ColorRect or c is Sprite2D:
				props.append({"name": c.name, "type": c.get_class()})
				counts[c.get_class()] = int(counts.get(c.get_class(), 0)) + 1
		entry["props_top"] = {"counts": counts, "nodes": props}
	else:
		entry["props_top"] = {"counts": {}, "nodes": []}

	remove_child(m)
	m.queue_free()
	await get_tree().process_frame
	return entry


func _run() -> void:
	var result := {}
	result["_meta"] = {
		"tool": "res://tools_paint/dump_terrain.gd",
		"histogram_key_format": "sx,sy:ax,ay = source_id,alternative_tile_id:atlas_x,atlas_y",
		"map_count": MAPS.size(),
	}
	for slug in MAPS:
		var entry := await _dump_map(slug)
		result[slug] = entry
		if entry.has("error"):
			print("[DUMP] %s ERROR %s" % [slug, str(entry["error"])])
		else:
			var wr: Variant = entry["world_rect_px"]
			print("[DUMP] %s tm=%d portals=%d npcs=%d world=%s src=%s" % [
				slug, (entry["tilemaps"] as Array).size(),
				(entry["portals"] as Array).size(),
				(entry["npcs"] as Array).size(),
				str(wr), str(entry["world_rect_source"])])
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[DUMP] Không mở được file xuất: " + OUT_PATH)
		get_tree().quit(1)
		return
	f.store_string(JSON.stringify(result, " "))
	f.close()
	print("[DUMP] DONE -> ", OUT_PATH)
	get_tree().quit()
