extends Node2D
## Chup kiem chung dot LAM LAI UI (anh TRUOC va SAU dung chung 1 script,
## cung canh/goc/quest de doi chieu cong bang): Elmford ngoai troi,
## quest that dong_01 (goblin 1/3) + dong_side_herb (1/4) dang active.
## Chay qua xvfb-run (KHONG headless):
##   xvfb-run ./tools_bin/Godot_v4.2.2-stable_linux.x86_64 --path game \
##     res://tools_paint/capture_ui_redo.tscn -- --out=<duong dan png>
## Mac dinh out = design/ui_redo_before.png (duong dan TUYET DOI).

var _out_path := "/home/hatch/workspace/game-phong-an/design/ui_redo_before.png"
var _cam: Camera2D
var _player: Node2D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
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
	await get_tree().create_timer(1.4).timeout
	await _wait_frames(30)
	if _player != null:
		_cam.global_position = _player.global_position
	await _wait_frames(6)
	if has_node("/root/LeftUI"):
		var lui: Node = get_node("/root/LeftUI")
		print("[UIREDO] left_visible=", lui.call("is_left_ui_visible"))
		var mm: Control = lui.call("get_minimap")
		if mm != null:
			print("[UIREDO] minimap has_data=", mm.call("has_map_data"),
				" portals=", mm.call("get_portal_count"),
				" quest_points=", mm.call("get_quest_point_count"))
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(_out_path)
	print("[UIREDO] ", _out_path, " err=", err, " size=", img.get_size())
	print("[UIREDO] DONE")
	get_tree().quit(0)
