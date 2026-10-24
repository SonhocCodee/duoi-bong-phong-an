extends Node2D
## TEAM VIEN MAP - Phan tich toan bo map de tinh:
##  - khung the gioi (world rect) tu TileMap (used rect) hoac fallback
##    Polygon2D lon nhat / union collision cho map khong co TileMap
##  - vi tri portal (de chua cua khi dung tuong vien), spawn marker
##  - texture Sprite2D dang dung (do biome/palette prop cua chinh map)
## Xuat JSON -> /tmp/map_analysis.json
## Chay: godot --headless --path game res://tools_paint/analyze_edges.tscn

const OUT_PATH := "/tmp/map_analysis.json"
const PORTAL_SCRIPT := "res://systems/portal.gd"

var _maps: Array[String] = []


func _ready() -> void:
	var da := DirAccess.open("res://maps")
	if da != null:
		da.list_dir_begin()
		var fn := da.get_next()
		while fn != "":
			if fn.ends_with(".tscn") and fn != "world_test.tscn":
				_maps.append("res://maps/" + fn)
			fn = da.get_next()
		da.list_dir_end()
	_maps.sort()
	_run()


func _rect_from_corners(tm: TileMap, cell_rect: Rect2i) -> Rect2:
	var ts := Vector2(tm.tile_set.tile_size)
	var local := Rect2(tm.map_to_local(cell_rect.position), Vector2(cell_rect.size) * ts)
	# map_to_local tra tam o dau tien -> tru nua o de ve goc tren-trai that
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
		mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.y))
		mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.y))
	return Rect2(mn, mx - mn)


func _poly_bounds(p: Polygon2D) -> Rect2:
	if p.polygon.is_empty():
		return Rect2()
	var gt: Transform2D = p.global_transform
	var mn := gt * p.polygon[0]
	var mx := mn
	for pt in p.polygon:
		var w := gt * pt
		mn = Vector2(minf(mn.x, w.x), minf(mn.y, w.y))
		mx = Vector2(maxf(mx.x, w.x), maxf(mx.y, w.y))
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
			mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.y))
			mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.y))
		return Rect2(mn, mx - mn)
	if sh is CircleShape2D:
		var r := (sh as CircleShape2D).radius
		var c := gt.origin
		return Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
	if sh is CapsuleShape2D:
		var cp := sh as CapsuleShape2D
		var c := gt.origin
		return Rect2(c - Vector2(cp.radius, cp.height * 0.5), Vector2(cp.radius * 2.0, cp.height))
	return Rect2()


func _r2a(r: Rect2) -> Array:
	return [r.position.x, r.position.y, r.size.x, r.size.y]


func _run() -> void:
	var result := {}
	for map_path in _maps:
		var ps: PackedScene = load(map_path)
		if ps == null:
			print("[ANALYZE] LOAD FAIL ", map_path)
			continue
		var m: Node = ps.instantiate()
		add_child(m)
		await get_tree().process_frame
		await get_tree().process_frame
		var info := {}
		var tilemaps: Array = []
		var union_rect := Rect2()
		var has_union := false
		var placeholder := Rect2()
		var has_placeholder := false
		var body_names: Array = []
		var main_tm: TileMap = null
		var main_cells := -1
		var polys: Array = []
		var col_rects: Array = []
		var portals: Array = []
		var spawns: Array = []
		var tex_count := {}
		var stack: Array[Node] = [m]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			for c in n.get_children():
				stack.append(c)
			if n is TileMap:
				var tm := n as TileMap
				var cells := 0
				var urect := Rect2i()
				var first := true
				for layer in tm.get_layers_count():
					cells += tm.get_used_cells(layer).size()
					var lused := tm.get_used_rect()
					if first:
						urect = lused
						first = false
					else:
						urect = urect.merge(lused)
				if cells > 0:
					if cells > main_cells:
						main_cells = cells
						main_tm = tm
					var wr := _rect_from_corners(tm, urect)
					tilemaps.append({
						"name": tm.name, "cells": cells,
						"cell_rect": [urect.position.x, urect.position.y, urect.size.x, urect.size.y],
						"world_rect": _r2a(wr),
						"tile_size": [tm.tile_set.tile_size.x, tm.tile_set.tile_size.y],
					})
					if not has_union:
						union_rect = wr
						has_union = true
					else:
						union_rect = union_rect.merge(wr)
			if n is ColorRect and n.name == "BackgroundPlaceholder":
				placeholder = (n as ColorRect).get_global_rect()
				has_placeholder = true
			if n is StaticBody2D:
				body_names.append(n.name)
			elif n is Polygon2D:
				var pb := _poly_bounds(n as Polygon2D)
				if pb.size.x > 0.0:
					polys.append({
						"name": n.name, "parent": n.get_parent().name if n.get_parent() else "",
						"rect": _r2a(pb), "area": pb.size.x * pb.size.y,
						"verts": (n as Polygon2D).polygon.size(),
					})
			elif n is CollisionShape2D:
				var sr := _shape_rect(n as CollisionShape2D)
				if sr.size.x > 0.0:
					col_rects.append(sr)
			elif n is Sprite2D:
				var t := (n as Sprite2D).texture
				if t != null and t.resource_path != "":
					var base := t.resource_path.get_file().get_basename()
					tex_count[base] = int(tex_count.get(base, 0)) + 1
			var sc: Script = n.get_script() as Script
			if sc != null and sc.resource_path == PORTAL_SCRIPT and n is Node2D:
				portals.append({
					"pos": [(n as Node2D).global_position.x, (n as Node2D).global_position.y],
					"target": str(n.get("target_scene")),
					"spawn": str(n.get("target_spawn")),
				})
			if n is Marker2D and n.name.begins_with("Spawn_"):
				spawns.append({
					"name": n.name,
					"pos": [(n as Node2D).global_position.x, (n as Node2D).global_position.y],
				})
		polys.sort_custom(func(a, b): return float(a["area"]) > float(b["area"]))
		var col_union := Rect2()
		var has_col := false
		for r in col_rects:
			if not has_col:
				col_union = r
				has_col = true
			else:
				col_union = col_union.merge(r)
		# Texture dung nhieu nhat (toi da 10)
		var tex_list: Array = []
		for k in tex_count.keys():
			tex_list.append([k, tex_count[k]])
		tex_list.sort_custom(func(a, b): return int(a[1]) > int(b[1]))
		# --- Khung chuan cua map: TM union > placeholder > col union ---
		var bounds := Rect2()
		var bounds_src := "none"
		if has_union:
			bounds = union_rect
			bounds_src = "tilemap"
		elif has_placeholder:
			bounds = placeholder
			bounds_src = "placeholder"
		elif has_col:
			bounds = col_union
			bounds_src = "collision"
		info["bounds"] = _r2a(bounds) if bounds_src != "none" else []
		info["bounds_src"] = bounds_src
		info["placeholder"] = _r2a(placeholder) if has_placeholder else []
		info["bodies"] = body_names
		# --- Do phu va cham cua 4 canh (0..1) ---
		var cov := {}
		if bounds_src != "none":
			var band := 80.0
			for side in ["top", "bottom", "left", "right"]:
				var segs: Array = []
				for r in col_rects:
					var hit := false
					var a0 := 0.0
					var a1 := 0.0
					match side:
						"top":
							hit = r.position.y < bounds.position.y + band and r.end.y > bounds.position.y - band
							a0 = maxf(r.position.x, bounds.position.x)
							a1 = minf(r.end.x, bounds.end.x)
						"bottom":
							hit = r.end.y > bounds.end.y - band and r.position.y < bounds.end.y + band
							a0 = maxf(r.position.x, bounds.position.x)
							a1 = minf(r.end.x, bounds.end.x)
						"left":
							hit = r.position.x < bounds.position.x + band and r.end.x > bounds.position.x - band
							a0 = maxf(r.position.y, bounds.position.y)
							a1 = minf(r.end.y, bounds.end.y)
						"right":
							hit = r.end.x > bounds.end.x - band and r.position.x < bounds.end.x + band
							a0 = maxf(r.position.y, bounds.position.y)
							a1 = minf(r.end.y, bounds.end.y)
					if hit and a1 > a0:
						segs.append([a0, a1])
				segs.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
				var covered := 0.0
				var cur0 := -1.0e18
				var cur1 := -1.0e18
				for s in segs:
					if float(s[0]) > cur1:
						if cur1 > cur0:
							covered += cur1 - cur0
						cur0 = float(s[0])
						cur1 = float(s[1])
					else:
						cur1 = maxf(cur1, float(s[1]))
				if cur1 > cur0:
					covered += cur1 - cur0
				var span := bounds.size.x if (side == "top" or side == "bottom") else bounds.size.y
				cov[side] = clampf(covered / maxf(span, 1.0), 0.0, 1.0)
		info["edge_coverage"] = cov
		# --- Vong tile ngoai cung cua TileMap chinh (2 lop) ---
		var ring := {}
		if main_tm != null:
			var urect2 := Rect2i()
			var first2 := true
			for layer in main_tm.get_layers_count():
				var lu := main_tm.get_used_rect()
				if first2:
					urect2 = lu
					first2 = false
				else:
					urect2 = urect2.merge(lu)
			var atlas_count := {}
			var ring_total := 0
			var ring_filled := 0
			for x in range(urect2.position.x, urect2.position.x + urect2.size.x):
				for y in range(urect2.position.y, urect2.position.y + urect2.size.y):
					var d := mini(mini(x - urect2.position.x, urect2.position.x + urect2.size.x - 1 - x),
						mini(y - urect2.position.y, urect2.position.y + urect2.size.y - 1 - y))
					if d > 1:
						continue
					ring_total += 1
					var filled := false
					for layer in main_tm.get_layers_count():
						if main_tm.get_cell_source_id(layer, Vector2i(x, y)) != -1:
							filled = true
							var at := main_tm.get_cell_atlas_coords(layer, Vector2i(x, y))
							var key := "%d,%d" % [at.x, at.y]
							atlas_count[key] = int(atlas_count.get(key, 0)) + 1
							break
					if filled:
						ring_filled += 1
			ring["filled_frac"] = float(ring_filled) / float(maxi(ring_total, 1))
			var top_atlas: Array = []
			for k in atlas_count.keys():
				top_atlas.append([k, atlas_count[k]])
			top_atlas.sort_custom(func(a, b): return int(a[1]) > int(b[1]))
			ring["top_atlas"] = top_atlas.slice(0, 6)
			ring["tilemap_name"] = main_tm.name
		info["ring"] = ring
		info["tilemaps"] = tilemaps
		info["tm_union"] = _r2a(union_rect) if has_union else []
		info["col_union"] = _r2a(col_union) if has_col else []
		info["col_count"] = col_rects.size()
		info["polys_top"] = polys.slice(0, 6)
		info["portals"] = portals
		info["spawns"] = spawns
		info["textures"] = tex_list.slice(0, 10)
		result[map_path] = info
		print("[ANALYZE] %s tm=%d portals=%d union=%s" % [
			map_path.get_file(), tilemaps.size(), portals.size(),
			str(_r2a(union_rect)) if has_union else "NONE"])
		remove_child(m)
		m.queue_free()
		await get_tree().process_frame
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(result, " "))
	f.close()
	print("[ANALYZE] DONE -> ", OUT_PATH)
	get_tree().quit()
