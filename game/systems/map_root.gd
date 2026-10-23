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
			GameState.current_map = cs.scene_file_path
			# Autosave theo map: mỗi lần vào map đều lưu lại để "Tiếp tục" quay đúng map.
			if has_node("/root/SaveSystem"):
				SaveSystem.save_game()
