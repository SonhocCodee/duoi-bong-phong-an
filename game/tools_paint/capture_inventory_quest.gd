extends Node2D
## Chup kiem chung goi TUI DO + CHI DUONG (3 che do qua --mode=):
##   inventory: Elmford + do mau trong GameState -> mo panel tui do (phim I).
##   guidance : Elmford + quest chinh dong_01 active -> mui ten chi goblin.
##   minimap  : Stonebridge (bo_song_thanh) -> minimap tron tuong phan moi,
##              song Clearwater + duong + cau phai doc duoc o goc phai tren.
## Chay qua xvfb-run (KHONG headless):
##   xvfb-run ./tools_bin/Godot_v4.2.2-stable_linux.x86_64 --path game \
##     res://tools_paint/capture_inventory_quest.tscn -- --mode=<m> --out=<png>

var _mode := "inventory"
var _out_path := "/home/hatch/workspace/game-phong-an/design/inventory_panel_shot.png"
var _cam: Camera2D
var _player: Node2D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			_mode = a.trim_prefix("--mode=")
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
	var scene_path := "res://maps/lang_tan_diep.tscn"
	if _mode == "inventory":
		_setup_inventory_state()
	elif _mode == "guidance":
		if has_node("/root/QuestManager"):
			QuestManager.accept_quest("dong_01_goblin")
	elif _mode == "minimap":
		scene_path = "res://maps/bo_song_thanh.tscn"
	var ps: PackedScene = load(scene_path)
	var map: Node = ps.instantiate()
	add_child(map)
	_player = map.get_node_or_null("Player") as Node2D
	_cam = Camera2D.new()
	_cam.zoom = Vector2.ONE
	add_child(_cam)
	_cam.make_current()
	_run()


func _setup_inventory_state() -> void:
	if not has_node("/root/GameState"):
		return
	GameState.reset_game()
	GameState.add_gold(123)
	GameState.add_potions(2)
	GameState.add_greater_potions(1)
	GameState.add_material("herb", 7)
	GameState.add_material("monster_core", 4)
	# 6 mon do: dang mac = Kiem Loi Quai + Giap Da Bong (manh nhat moi slot)
	GameState.add_equipment("Kiếm Ngắn Cũ", 3, 0)
	GameState.add_equipment("Dao Găm Sắt", 2, 0)
	GameState.add_equipment("Kiếm Lõi Quái", 6, 0)
	GameState.add_equipment("Áo Da Cứng", 0, 2)
	GameState.add_equipment("Giáp Da Bóng", 0, 4)
	GameState.add_equipment("Găng Da Thú", 1, 1)


func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _run() -> void:
	await get_tree().create_timer(1.6).timeout
	await _wait_frames(30)
	if _player != null:
		_cam.global_position = _player.global_position
	if has_node("/root/LeftUI"):
		var lui: Node = get_node("/root/LeftUI")
		print("[CAP] left_visible=", lui.call("is_left_ui_visible"))
		if _mode == "inventory":
			var panel: Control = lui.call("get_inventory_panel")
			print("[CAP] inventory panel = ", panel)
			if panel != null:
				panel.call("open_panel")
				print("[CAP] panel visible = ", panel.visible,
					" in_dialogue = ", GameState.in_dialogue)
				print("[CAP] panel rect = ", panel.get_global_rect(),
					" size = ", panel.size, " anchors = ",
					panel.anchor_right, ",", panel.anchor_bottom)
				for ch in panel.get_children():
					if ch is PanelContainer:
						print("[CAP] inner PanelContainer rect = ", ch.get_global_rect())
		elif _mode == "guidance":
			var g: Control = lui.call("get_guidance")
			print("[CAP] guidance = ", g)
			if g != null:
				print("[CAP] target quest = ", g.call("get_target_quest_id"),
					" target pos = ", g.call("get_target_position"),
					" player pos = ", _player.global_position if _player != null else Vector2.ZERO)
		elif _mode == "minimap":
			var mm: Control = lui.call("get_minimap")
			if mm != null:
				print("[CAP] minimap has_data=", mm.call("has_map_data"),
					" main_point=", mm.call("get_main_quest_point"))
	await _wait_frames(10)
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(_out_path)
	print("[CAP] ", _mode, " -> ", _out_path, " err=", err, " size=", img.get_size())
	print("[CAP] DONE")
	get_tree().quit(0)
