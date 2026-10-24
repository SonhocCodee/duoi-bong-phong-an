extends Node2D
## Chụp kiểm chứng gói "KHỞI ĐẦU ĐÚNG THIẾT KẾ" ở Elmford, phiên chơi MỚI
## (reset sạch): player ÁO VẢI ở CỔNG NAM, HUD thanh skill gần trống,
## nhãn mục tiêu mở đầu, và một khung hình trong thoại gác cổng.
## Chạy qua xvfb-run (KHÔNG headless):
##   xvfb-run ./tools_bin/Godot_v4.2.2-stable_linux.x86_64 --path game \
##     res://tools_paint/capture_start_state.tscn -- --shot=gate
## --shot=gate : toàn cảnh cổng nam + HUD (mặc định)
## --shot=zoom : cận cảnh player áo vải + gác cổng (zoom 1.7)
## --shot=talk : đang mở thoại với gác cổng (dòng 1)
## --out=<đường dẫn png tuyệt đối>

var _shot := "gate"
var _out_path := "/home/hatch/workspace/game-phong-an/design/start_state_shots/gate_start.png"
var _cam: Camera2D
var _player: Node2D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a.begins_with("--shot="):
			_shot = a.trim_prefix("--shot=")
	# Phiên chơi mới tinh: reset mọi trạng thái như bấm "Chơi mới".
	if has_node("/root/GameState"):
		GameState.reset_game()
	if has_node("/root/QuestManager"):
		QuestManager.reset_quests()
	var ps: PackedScene = load("res://maps/lang_tan_diep.tscn")
	var map: Node = ps.instantiate()
	add_child(map)
	_player = map.get_node_or_null("Player") as Node2D
	_cam = Camera2D.new()
	_cam.zoom = Vector2.ONE
	add_child(_cam)
	_cam.make_current()
	_run(map)


func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _run(map: Node) -> void:
	await get_tree().create_timer(1.2).timeout
	await _wait_frames(20)
	if _shot == "talk":
		var gate: Node = map.get_node_or_null("NPC_GacCong")
		if gate != null and gate.has_method("interact"):
			gate.call("interact")
		await get_tree().create_timer(0.6).timeout
		await _wait_frames(10)
	if _player != null:
		_cam.global_position = _player.global_position
	if _shot == "zoom" or _shot == "talk":
		_cam.zoom = Vector2(1.7, 1.7)
	await _wait_frames(6)
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(_out_path)
	print("[STARTCAP] shot=", _shot, " out=", _out_path, " err=", err, " size=", img.get_size())
	print("[STARTCAP] DONE")
	get_tree().quit(0)
