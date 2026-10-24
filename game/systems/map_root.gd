extends Node2D
## MapRoot - Script gắn vào node gốc của mỗi map scene (res://systems/map_root.gd).
## Khi vào map: nếu GameState.spawn_point khác "start", tìm Marker2D tên
## "Spawn_<spawn_point>" trong scene và đưa Player (group "player") tới đó.
## Map không có marker khớp thì giữ nguyên vị trí mặc định của Player trong scene.
## Cuối _ready: autosave theo map (để nút "Tiếp tục" ở main menu vào đúng map).

func _ready() -> void:
	if has_node("/root/GameState"):
		var sp: String = GameState.spawn_point
		if sp != "" and sp != "start":
			var marker := find_child("Spawn_" + sp, true, false) as Node2D
			if marker == null:
				push_warning("[MapRoot] Không tìm thấy Marker2D 'Spawn_%s' trong map này." % sp)
			else:
				var players := get_tree().get_nodes_in_group("player")
				if players.size() > 0 and players[0] is Node2D:
					(players[0] as Node2D).global_position = marker.global_position
					print("[MapRoot] Đưa player tới Spawn_%s tại %s" % [sp, str(marker.global_position)])
		# Ghi nhớ map hiện tại từ scene đang chạy (hỗ trợ trường hợp vào map
		# trực tiếp từ menu mà portal chưa kịp set current_map).
		# CHỈ áp dụng cho scene map thật (res://maps/...): scene test cũng gắn
		# MapRoot giả, không được phép ghi đè current_map hay autosave.
		var cs: Node = get_tree().current_scene
		if cs != null and cs.scene_file_path.begins_with("res://maps/"):
			# Gioi han camera theo khung map: vien man hinh dung dung o dia
			# map (vach nui/rung/tuong), khong bao gio lo nen den ben ngoai.
			apply_camera_limits()
			GameState.current_map = cs.scene_file_path
			# Autosave theo map: mỗi lần vào map đều lưu lại để "Tiếp tục" quay đúng map.
			if has_node("/root/SaveSystem"):
				SaveSystem.save_game()
			# Quest theo map (vd dong_08_cong_ngam: vào tới hoang_cung)
			if has_node("/root/QuestManager") and QuestManager.has_method("on_map_entered"):
				QuestManager.on_map_entered(cs.scene_file_path.get_file().get_basename())


## ---- Gioi han camera theo khung map ------------------------------------
## Tinh khung the gioi cua map theo thu tu uu tien:
##   1. Hop nhat used rect cua moi TileMap (map ve bang tile).
##   2. ColorRect "BackgroundPlaceholder" (map khung ve bang Polygon2D).
##   3. Polygon2D co khung bao lon nhat (nen san: CaveFloor/RockBase...).
## Map nho hon khung hinh o mot chieu thi mo rong khung doi xung o chieu
## do cho bang khung hinh -> camera tu can giua map, khong lech mot ben.

func _tm_world_rect(tm: TileMap, cell_rect: Rect2i) -> Rect2:
	var ts := Vector2(tm.tile_set.tile_size)
	var local := Rect2(tm.map_to_local(cell_rect.position), Vector2(cell_rect.size) * ts)
	local.position -= ts * 0.5 # map_to_local tra tam o dau, lui ve goc that
	var gt: Transform2D = tm.global_transform
	var pts: Array[Vector2] = [
		gt * local.position,
		gt * (local.position + Vector2(local.size.x, 0.0)),
		gt * (local.position + Vector2(0.0, local.size.y)),
		gt * (local.position + local.size),
	]
	var mn := pts[0]
	var mx := pts[0]
	for p in pts:
		mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.y))
		mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.y))
	return Rect2(mn, mx - mn)


func _poly_world_bounds(p: Polygon2D) -> Rect2:
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


func compute_map_bounds() -> Rect2:
	var rect := Rect2()
	var has_rect := false
	var placeholder: ColorRect = null
	var best_poly := Rect2()
	var best_area := 0.0
	var stack: Array[Node] = [self]
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
				var lu := tm.get_used_rect()
				if first:
					urect = lu
					first = false
				else:
					urect = urect.merge(lu)
			if cells > 0:
				var wr := _tm_world_rect(tm, urect)
				if not has_rect:
					rect = wr
					has_rect = true
				else:
					rect = rect.merge(wr)
		elif n is ColorRect and n.name == "BackgroundPlaceholder":
			placeholder = n as ColorRect
		elif n is Polygon2D:
			var pb := _poly_world_bounds(n as Polygon2D)
			var a := pb.size.x * pb.size.y
			if a > best_area:
				best_area = a
				best_poly = pb
	if has_rect:
		return rect
	if placeholder != null:
		return placeholder.get_global_rect()
	return best_poly


func apply_camera_limits() -> void:
	var bounds := compute_map_bounds()
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	var cam: Camera2D = null
	for p in get_tree().get_nodes_in_group("player"):
		var found := (p as Node).find_child("Camera2D", true, false) as Camera2D
		if found != null:
			cam = found
			break
	if cam == null:
		return
	# Map nho hon man hinh: mo rong khung doi xung -> camera can giua map.
	var view := get_viewport().get_visible_rect().size
	if bounds.size.x < view.x:
		var dx := (view.x - bounds.size.x) * 0.5
		bounds = bounds.grow_individual(dx, 0.0, dx, 0.0)
	if bounds.size.y < view.y:
		var dy := (view.y - bounds.size.y) * 0.5
		bounds = bounds.grow_individual(0.0, dy, 0.0, dy)
	cam.limit_left = int(floor(bounds.position.x))
	cam.limit_top = int(floor(bounds.position.y))
	cam.limit_right = int(ceil(bounds.end.x))
	cam.limit_bottom = int(ceil(bounds.end.y))
	cam.reset_smoothing()
	print("[MapRoot] Camera limits: %s" % str(bounds))
