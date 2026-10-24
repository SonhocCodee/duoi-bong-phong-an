extends Node2D
## Chup anh TRUOC/SAU cho dot Vien map.
## Chay qua xvfb-run (KHONG headless):
##   EDGE_TAG=before xvfb-run -a godot --path game res://tools_paint/capture_edges.tscn
##   EDGE_TAG=after  xvfb-run -a godot --path game res://tools_paint/capture_edges.tscn
## Anh luu vao design/edge_shots/<shot>_<tag>.png
## Cach chup: instance map + dung Player THAT trong scene, dua player toi
## sat dia, dung Camera2D cua player. Ban "after" goi
## map.apply_camera_limits() (dung ham game dung khi choi that); ban
## "before" khong goi -> camera khong gioi han, lo nen den ngoai map.

const OUT_DIR := "/home/hatch/workspace/game-phong-an/design/edge_shots"

# [ten shot, map, vi tri player]
const SHOTS := [
	["elmford_south_lane", "res://maps/lang_tan_diep.tscn", Vector2(0, 1400)],
	["elmford_east_lane", "res://maps/lang_tan_diep.tscn", Vector2(4560, 85)],
	["elmford_north_wall", "res://maps/lang_tan_diep.tscn", Vector2(-800, -3030)],
	["dunefield_east_lane", "res://maps/dunefield.tscn", Vector2(4380, 0)],
	["dunefield_north_wall", "res://maps/dunefield.tscn", Vector2(200, -3180)],
	["blackmere_south", "res://maps/blackmere.tscn", Vector2(300, 2820)],
	["snowpine_east", "res://maps/snowpine_forest.tscn", Vector2(4280, 100)],
	["nui_thanh_van_south", "res://maps/nui_thanh_van.tscn", Vector2(0, 760)],
	["duong_di_nam_center", "res://maps/duong_di_nam.tscn", Vector2(0, 300)],
	["ham_ruou_south", "res://maps/ham_ruou.tscn", Vector2(0, 1450)],
	["aldenmere_south_gate", "res://maps/thanh_xuan_lam.tscn", Vector2(-50, 5780)],
]

var _tag := "before"


func _ready() -> void:
	_tag = OS.get_environment("EDGE_TAG")
	if _tag == "":
		_tag = "before"
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_run()


func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _run() -> void:
	for shot in SHOTS:
		var stem: String = shot[0]
		var map_path: String = shot[1]
		var player_pos: Vector2 = shot[2]
		for c in get_children():
			remove_child(c)
			c.queue_free()
		await _wait_frames(3)
		var ps: PackedScene = load(map_path)
		if ps == null:
			print("[ESHOT] LOAD FAIL ", map_path)
			continue
		var m: Node = ps.instantiate()
		add_child(m)
		var ov := m.get_node_or_null("OpeningOverlay")
		if ov != null:
			ov.queue_free()
		await _wait_frames(2)
		var players := get_tree().get_nodes_in_group("player")
		if players.is_empty():
			print("[ESHOT] NO PLAYER ", map_path)
			continue
		var player := players[0] as Node2D
		player.global_position = player_pos
		if _tag == "after" and m.has_method("apply_camera_limits"):
			m.apply_camera_limits()
		var cam := player.find_child("Camera2D", true, false) as Camera2D
		if cam == null:
			print("[ESHOT] NO CAM ", map_path)
			continue
		cam.make_current()
		await _wait_frames(14)
		var img := get_viewport().get_texture().get_image()
		var out := OUT_DIR + "/" + stem + "_" + _tag + ".png"
		img.save_png(out)
		print("[ESHOT] ", out)
	print("[ESHOT] DONE tag=", _tag)
	get_tree().quit()
