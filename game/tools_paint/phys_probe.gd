extends Node2D
## Kiem tra vat ly diem: doc danh sach diem tu bien moi truong PHYS_POINTS
## dang "x1,y1;x2,y2;..." va map tu PHYS_MAP, in diem nao bi chan boi
## StaticBody2D (collision layer 1). Dung de phan dinh cac hanh lang hep
## ma raster o 64px khong phan giai duoc.
## Chay: PHYS_MAP=res://maps/westgate.tscn PHYS_POINTS="288,-1984;288,-2112" \
##   tools_bin/Godot_... --headless --path game res://tools_paint/phys_probe.tscn

func _ready() -> void:
	var map_path := OS.get_environment("PHYS_MAP")
	var pts_str := OS.get_environment("PHYS_POINTS")
	var ps: PackedScene = load(map_path)
	if ps == null:
		print("[PHYS] LOAD FAIL ", map_path)
		get_tree().quit(1)
		return
	var m: Node = ps.instantiate()
	add_child(m)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_2d().direct_space_state
	for pair in pts_str.split(";"):
		var xy := pair.split(",")
		if xy.size() != 2:
			continue
		var p := Vector2(float(xy[0]), float(xy[1]))
		var q := PhysicsPointQueryParameters2D.new()
		q.position = p
		q.collision_mask = 0xFFFFFFFF
		q.collide_with_bodies = true
		q.collide_with_areas = false
		var hits := space.intersect_point(q, 8)
		var names: Array[String] = []
		for h in hits:
			var col: Object = h.get("collider")
			if col is StaticBody2D:
				names.append((col as Node).name)
		print("[PHYS] ", p, " -> ", "CHAN boi " + str(names) if names.size() > 0 else "THONG")
	get_tree().quit(0)
