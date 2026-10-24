extends Node2D
## Chup kiem chung cum UI trai (minimap + quest tracker) tren map that
## Elmford (chay qua xvfb-run, KHONG headless):
##   xvfb-run ./tools_bin/Godot_v4.2.2-stable_linux.x86_64 --path game res://tools_paint/capture_left_ui.tscn
## Nhan san 2 quest that qua QuestManager + cong tien do that (1 goblin,
## 1 herb) de anh co du lieu tien trinh that, khong phai text gia.

const OUT_PATH := "/home/hatch/workspace/game-phong-an/design/left_ui_shot.png"

var _cam: Camera2D
var _player: Node2D


func _ready() -> void:
	# Quest that: dong_01 (main, goblin 1/3) + dong_side_herb (side, 1/4)
	if has_node("/root/QuestManager"):
		QuestManager.accept_quest("dong_01_goblin")
		QuestManager.on_enemy_killed("goblin")
		QuestManager.accept_quest("dong_side_herb")
		QuestManager.on_item_collected("herb")
	var ps: PackedScene = load("res://maps/lang_tan_diep.tscn")
	var map: Node = ps.instantiate()
	add_child(map)
	_player = map.get_node_or_null("Player") as Node2D
	_cam = Camera2D.new()
	_cam.zoom = Vector2.ONE
	add_child(_cam)
	_cam.make_current()
	_run()


func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _run() -> void:
	# Cho LeftUI poll (0.6s) nhan ra map + HUD/Player on dinh; them timer
	# 1.2s that de chac poll da chay it nhat 1 lan.
	await get_tree().create_timer(1.2).timeout
	await _wait_frames(30)
	if _player != null:
		_cam.global_position = _player.global_position
	await _wait_frames(6)
	if has_node("/root/LeftUI"):
		var lui: Node = get_node("/root/LeftUI")
		print("[LEFTSHOT] visible=", lui.call("is_left_ui_visible"))
		var mm: Control = lui.call("get_minimap")
		if mm != null:
			print("[LEFTSHOT] minimap has_data=", mm.call("has_map_data"),
				" portals=", mm.call("get_portal_count"),
				" quest_points=", mm.call("get_quest_point_count"))
		var tr: Control = lui.call("get_quest_tracker")
		if tr != null:
			print("[LEFTSHOT] tracker:\n", tr.call("build_tracker_text"))
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(OUT_PATH)
	print("[LEFTSHOT] ", OUT_PATH, " err=", err, " size=", img.get_size())
	print("[LEFTSHOT] DONE")
	get_tree().quit(0)
