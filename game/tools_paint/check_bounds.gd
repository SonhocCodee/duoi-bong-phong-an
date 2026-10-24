extends Node2D
## Kiem chung compute_map_bounds() cua map_root.gd tren vai map dai dien.
## Chay: godot --headless --path game res://tools_paint/check_bounds.tscn

const CASES := [
	"res://maps/lang_tan_diep.tscn",   # TileMap
	"res://maps/ngoai_thanh.tscn",     # placeholder ColorRect
	"res://maps/nui_thanh_van.tscn",   # Polygon2D lon nhat
	"res://maps/duong_di_nam.tscn",    # placeholder hep (< man hinh)
	"res://maps/ham_ruou.tscn",        # noi that TileMap
	"res://maps/thanh_xuan_lam.tscn",  # thanh lon
]


func _ready() -> void:
	for path in CASES:
		var ps: PackedScene = load(path)
		var m: Node = ps.instantiate()
		add_child(m)
		await get_tree().process_frame
		await get_tree().process_frame
		var b: Rect2 = m.compute_map_bounds()
		print("[BOUNDS] %s -> x=%.0f y=%.0f w=%.0f h=%.0f" % [
			path.get_file(), b.position.x, b.position.y, b.size.x, b.size.y])
		# Thu ca apply_camera_limits (can player trong scene)
		m.apply_camera_limits()
		var players := get_tree().get_nodes_in_group("player")
		for p in players:
			var cam := (p as Node).find_child("Camera2D", true, false) as Camera2D
			if cam != null:
				print("[BOUNDS]   cam limits L%d T%d R%d B%d" % [
					cam.limit_left, cam.limit_top, cam.limit_right, cam.limit_bottom])
				break
		remove_child(m)
		m.queue_free()
		await get_tree().process_frame
	print("[BOUNDS] DONE")
	get_tree().quit()
