extends Node
## SaveSystem - Autoload lưu / tải game bằng JSON
## File lưu: user://save.json
## Dùng FileAccess + JSON của Godot 4.

signal game_saved
signal game_loaded
signal save_failed(reason: String)

const SAVE_PATH: String = "user://save.json"


func _ready() -> void:
	pass


func save_game(extra_data: Dictionary = {}) -> bool:
	var data: Dictionary = {}
	# Lấy dữ liệu từ GameState nếu autoload đã sẵn sàng.
	# GameState.to_dict() đã gồm potions / seal_keys / flags / spawn_point /
	# current_map (GĐ1) nên các dữ liệu này tự đi theo file save.
	if has_node("/root/GameState"):
		data["game_state"] = GameState.to_dict()
	if has_node("/root/QuestManager"):
		data["quests"] = QuestManager.to_dict()
	data.merge(extra_data, true)
	data["version"] = 1
	data["saved_at"] = Time.get_datetime_string_from_system()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		push_warning("[SaveSystem] Không mở được file lưu: %s (err=%d)" % [SAVE_PATH, err])
		save_failed.emit("open_failed_%d" % err)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[SaveSystem] Đã lưu game -> ", SAVE_PATH)
	game_saved.emit()
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveSystem] Chưa có file lưu.")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		save_failed.emit("open_failed")
		return false
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_warning("[SaveSystem] File lưu hỏng / không phải JSON hợp lệ.")
		save_failed.emit("invalid_json")
		return false

	var data: Dictionary = parsed
	if data.has("game_state") and has_node("/root/GameState"):
		GameState.from_dict(data["game_state"])
		# GĐ1: chỉ khôi phục DỮ LIỆU (kể cả current_map / spawn_point trong
		# GameState). Việc chuyển scene sang current_map sau khi load do menu
		# (GD3) đảm nhiệm — SaveSystem không tự change_scene ở đây.
	if data.has("quests") and has_node("/root/QuestManager"):
		QuestManager.from_dict(data["quests"])
	print("[SaveSystem] Đã tải game <- ", SAVE_PATH)
	game_loaded.emit()
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveSystem] Đã xóa file lưu.")
