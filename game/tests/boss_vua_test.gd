extends Node
## Test tự động cho BOSS King Aldric, the Puppet King + màn hình kết thúc Phần 1 (headless):
##   godot --headless --path game res://tests/boss_vua_test.tscn
## Kiểm tra: thông số boss; triệu hồi lính không crash; đánh xuống <=50% HP
## -> phase 2 + tint tím + speed x1.25 + boss display đổi tên "Con Rối Của
## Tháp"; ép bắn Chỉ Ấn -> shadow bolt spawn (damage 18); ép slam -> player
## -24 HP; đánh chết -> flag vua_ha + boss display rỗng; chạy trọn tuyến
## quest dong_01..dong_07 qua API QuestManager (accept -> on_enemy_killed
## đúng số lần -> turn_in_quest) -> quest dong_07_vua complete tự set flag
## dong_giai_phong + signal part1_completed + ending_panel hiện visible,
## tổng kết đọc đúng flags, nút "Chơi tiếp" ẩn panel + mở khóa player.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _frame := 0
var _passes: int = 0
var _failures: Array[String] = []
var _boss: Node = null
var _player: Node = null
var _panel: CanvasLayer = null
var _part1_signal_seen := false
var _slam_started := false
var _slam_checked := false
var _slam_deadline := -1
var _player_hp0 := -1
var _gold_before_kill := 0
var _kill_frame := -1
var _chain_done := false


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[VUATEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[VUATEST] FAIL: ", label)


func _on_part1_signal() -> void:
	_part1_signal_seen = true


func _ready() -> void:
	if has_node("/root/GameState"):
		GameState.part1_completed.connect(_on_part1_signal)
	_boss = load("res://enemies/boss_vua.tscn").instantiate()
	_boss.global_position = Vector2(1000, 1000)
	add_child(_boss)
	_player = load("res://player/player.tscn").instantiate()
	_player.global_position = Vector2(1600, 1000) # xa 600px: ngoài tầm detect của boss
	add_child(_player)
	_panel = load("res://ui/ending_panel.tscn").instantiate()
	add_child(_panel)
	print("[VUATEST] Bắt đầu test Boss King Aldric, the Puppet King + Ending Phần 1.")


func _count_soldiers() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if str(e.get("enemy_type")) == "soldier":
			n += 1
	return n


func _count_shadow_bolts() -> int:
	var n := 0
	for child in get_children():
		if child is Area2D and child.get_script() != null \
				and child.get_script().resource_path == "res://enemies/shadow_bolt.gd":
			n += 1
	return n


func _physics_process(_delta: float) -> void:
	_frame += 1

	# --- Chờ slam sau khi đã thả player cạnh boss (pattern golem_test) ---
	if _slam_started and not _slam_checked:
		if int(_boss.get("slam_count")) >= 1:
			_slam_checked = true
			_check(bool(_boss.get("last_slam_hit")), "Slam phase 2 trúng player trong 80px (last_slam_hit)")
			_check(int(_player.get("hp")) == _player_hp0 - 24,
				"Player mất đúng 24 HP vì slam (hp=%d, trước=%d)" % [int(_player.get("hp")), _player_hp0])
			_player.global_position = Vector2(8000, 8000)
			_kill_frame = _frame + 3
		elif _slam_deadline > 0 and _frame > _slam_deadline:
			_slam_checked = true
			_check(false, "Boss đã slam trong thời hạn (slam_count=%d)" % int(_boss.get("slam_count")))
			_player.global_position = Vector2(8000, 8000)
			_kill_frame = _frame + 3

	# --- Đòn kết liễu boss ---
	if _kill_frame > 0 and _frame == _kill_frame:
		_gold_before_kill = GameState.gold
		_boss.take_damage(9999, (_boss as Node2D).global_position + Vector2(200, 0))
		_check(int(_boss.get("state")) == 3, "Boss chết -> state DEAD")
		_check(GameState.get_flag("vua_ha"), "Boss chết -> flag vua_ha = true")
		_check(not GameState.get_flag("dong_giai_phong"),
			"Boss chết KHÔNG tự set dong_giai_phong (QuestManager mới lo qua dong_07_vua)")
		_check(str(GameState.boss_name) == "", "Boss chết -> boss display rỗng (boss_name='%s')" % str(GameState.boss_name))
		_check(not bool(_boss.get("boss_display_active")), "Boss chết -> boss_display_active = false (phía boss)")
		_check(GameState.gold == _gold_before_kill + 250, "Boss chết -> +250 gold (gold=%d)" % GameState.gold)
	if _kill_frame > 0 and _frame == _kill_frame + 10 and not _chain_done:
		_chain_done = true
		_run_liberation_chain()
	if _kill_frame > 0 and _frame == _kill_frame + 75:
		_check(not is_instance_valid(_boss) or not _boss.is_inside_tree(), "Boss biến mất sau death animation")
		print("[VUATEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
		get_tree().quit(1 if _failures.size() > 0 else 0)
		return

	match _frame:
		5:
			# --- Thông số boss ---
			_check(str(_boss.get("enemy_type")) == "boss_vua", "Boss enemy_type = boss_vua")
			_check(str(_boss.get("display_name")) == "King Aldric, the Puppet King", "Boss display_name = King Aldric, the Puppet King")
			_check(int(_boss.get("max_hp")) == 520 and int(_boss.get("hp")) == 520, "Boss HP = 520")
			_check(int(_boss.get("damage")) == 20 and is_equal_approx(float(_boss.get("speed")), 100.0),
				"Boss dmg/speed = 20/100")
			_check(int(_boss.get("xp_reward")) == 400 and int(_boss.get("gold_reward")) == 250,
				"Boss xp/gold = 400/250")
			_check(is_equal_approx(float(_boss.get("attack_cooldown_time")), 0.9), "Boss attack_cooldown = 0.9")
			_check(is_equal_approx(float(_boss.get("sprite_scale")), 1.35), "Boss sprite_scale = 1.35")
			var frames: Resource = _boss.get("sprite_frames")
			_check(frames != null and frames.resource_path == "res://assets/sprites/player_frames.tres",
				"Boss dùng player_frames.tres")
			var tint: Color = _boss.get("sprite_modulate")
			_check(absf(tint.r - 1.05) < 0.02 and absf(tint.g - 0.95) < 0.02 and absf(tint.b - 0.6) < 0.02,
				"Boss tint vàng vương giả (1.05, 0.95, 0.6) — thấy %s" % str(tint))
			var shape: CollisionShape2D = _boss.get_node("CollisionShape2D")
			var rect := (shape.shape as RectangleShape2D).size
			_check(is_equal_approx(rect.x, 30.0) and is_equal_approx(rect.y, 24.0),
				"Boss collision = 30x24 (thấy %s)" % str(rect))
			_check(int(_boss.get("phase")) == 1, "Boss bắt đầu ở phase 1")
			_check(int(_boss.get("summons_done")) == 0 and int(_boss.get("bolt_count")) == 0,
				"Boss summons_done/bolt_count = 0 lúc đầu")
			_check(str(GameState.boss_name) == "King Aldric, the Puppet King" and int(GameState.boss_max_hp) == 520,
				"Boss display đã set sau _ready (name='%s', max=%d)" % [str(GameState.boss_name), int(GameState.boss_max_hp)])
			_check(not _panel.visible, "EndingPanel ẩn lúc đầu (chưa giải phóng)")
			_check(not GameState.in_dialogue, "Player chưa bị khóa lúc đầu (in_dialogue = false)")
		6:
			# --- Triệu hồi lính: gọi thẳng hàm nội bộ, không crash ---
			_boss.call("summon_soldier")
			_check(int(_boss.get("summons_done")) == 1, "Triệu hồi lính chạy: summons_done = 1")
			_check(_count_soldiers() >= 1, "Có soldier xuất hiện cạnh boss (thấy %d)" % _count_soldiers())
		8:
			# --- Đánh xuống đúng 50% -> phase 2 ---
			_boss.take_damage(260, (_boss as Node2D).global_position + Vector2(100, 0))
			_check(int(_boss.get("hp")) == 260, "Boss trúng 260 dmg còn 260 HP (thấy %d)" % int(_boss.get("hp")))
			_check(int(_boss.get("phase")) == 2, "Boss <=50% HP -> phase 2 (LỘ BẢN CHẤT CON RỐI)")
			_check(is_equal_approx(float(_boss.call("_move_speed")), 125.0),
				"Boss phase 2 speed x1.25 = 125 (thấy %.1f)" % float(_boss.call("_move_speed")))
			var tint2: Color = _boss.get("sprite_modulate")
			_check(absf(tint2.r - 0.45) < 0.02 and absf(tint2.g - 0.3) < 0.02 and absf(tint2.b - 0.6) < 0.02,
				"Boss phase 2 tint tím đen (0.45, 0.3, 0.6) — thấy %s" % str(tint2))
			_check(str(GameState.boss_name) == "Con Rối Của Tháp",
				"Boss display đổi tên phase 2 = 'Con Rối Của Tháp' (thấy '%s')" % str(GameState.boss_name))
			_check(int(GameState.boss_hp) == 260, "Boss display cập nhật HP phase 2 (boss_hp=%d)" % int(GameState.boss_hp))
		10:
			# --- Ép bắn Chỉ Ấn: gọi hàm nội bộ, kiểm tra bolt spawn ---
			_boss.call("shoot_shadow_bolt")
			_check(int(_boss.get("bolt_count")) == 1, "Ép bắn Chỉ Ấn: bolt_count = 1")
			_check(_count_shadow_bolts() >= 1, "Shadow bolt đã spawn vào scene (thấy %d)" % _count_shadow_bolts())
			for child in get_children():
				if child is Area2D and child.get_script() != null \
						and child.get_script().resource_path == "res://enemies/shadow_bolt.gd":
					_check(int(child.get("damage")) == 18, "Shadow bolt damage = 18 qua export (thấy %d)" % int(child.get("damage")))
		12:
			# --- Ép slam: dời lính triệu hồi đi xa (tránh melee chen vào),
			# thả player thật đứng cách boss 70px (trong tầm slam 90/80,
			# ngoài tầm melee 42*1.25) và ép slam sẵn sàng ---
			for e in get_tree().get_nodes_in_group("enemy"):
				if str(e.get("enemy_type")) == "soldier":
					(e as Node2D).global_position = Vector2(5000, 5000)
			_player.global_position = (_boss as Node2D).global_position + Vector2(-70, 0)
			_boss.set("slam_timer", 0.0)
			_slam_started = true
			_slam_deadline = _frame + 120
		13:
			_player_hp0 = int(_player.get("hp"))
			_check(_player_hp0 > 24, "Player dummy sẵn sàng cho slam (hp=%d)" % _player_hp0)


# --- Tuyến giải phóng Đông qua API: 01->02->03->05->06->04->08->07 ---------

func _quest_status(qid: String) -> String:
	return str(QuestManager.get_quest(qid).get("status", ""))


func _finish_kill_quest(qid: String, type: String, count: int) -> void:
	# dong_01 có thể đã được player.tscn tự accept lúc spawn -> accept trả
	# false nhưng status vẫn active, cả hai đều coi là nhận được.
	var accepted: bool = QuestManager.accept_quest(qid)
	_check(accepted or _quest_status(qid) == "active",
		"Nhận quest %s (status=%s)" % [qid, _quest_status(qid)])
	for i in count:
		QuestManager.on_enemy_killed(type)
	if _quest_status(qid) == "ready_turn_in":
		_check(QuestManager.turn_in_quest(qid), "Trả quest %s thành công" % qid)
	_check(_quest_status(qid) == "completed", "Quest %s -> completed" % qid)


func _run_liberation_chain() -> void:
	_finish_kill_quest("dong_01_goblin", "goblin", 3)
	_finish_kill_quest("dong_02_ham_ruou", "rat", 5)
	_finish_kill_quest("dong_03_chuot_chua", "boss_rat_king", 1)
	# Gating thứ tự MỚI: dong_04 cần dong_06 xong trước
	_check(not QuestManager.accept_quest("dong_04_golem"),
		"Gating: accept dong_04_golem == false khi dong_06 chưa xong")
	_finish_kill_quest("dong_05_tram_thue", "soldier", 3)
	_check(GameState.get_flag("tram_thue_pha"), "Xong dong_05 -> flag tram_thue_pha = true")
	_finish_kill_quest("dong_06_giai_phu", "bandit", 4)
	_check(GameState.get_flag("co_duong_cong"), "Xong dong_06 -> flag co_duong_cong = true")
	_finish_kill_quest("dong_04_golem", "boss_golem", 1)
	# Gating: dong_07 cần dong_08 xong trước
	_check(not QuestManager.accept_quest("dong_07_vua"),
		"Gating: accept dong_07_vua == false khi dong_08 chưa xong")
	# dong_08: hoàn thành bằng on_map_entered("hoang_cung"), requires_turn_in=false
	_check(QuestManager.accept_quest("dong_08_cong_ngam"), "Nhận quest dong_08_cong_ngam")
	QuestManager.on_map_entered("hoang_cung")
	_check(_quest_status("dong_08_cong_ngam") == "completed", "dong_08 -> completed sau on_map_entered(hoang_cung)")
	_check(GameState.get_flag("da_dot_nhap"), "Xong dong_08 -> flag da_dot_nhap = true")
	# dong_07: requires_turn_in = false -> on_enemy_killed tự complete,
	# QuestManager tự set flag dong_giai_phong (boss KHÔNG tự set).
	_check(QuestManager.accept_quest("dong_07_vua"), "Nhận quest dong_07_vua")
	QuestManager.on_enemy_killed("boss_vua")
	_check(_quest_status("dong_07_vua") == "completed", "dong_07_vua -> completed sau khi hạ boss_vua")
	_check(GameState.get_flag("dong_giai_phong"), "Flag dong_giai_phong = true (do QuestManager set)")
	_check(_part1_signal_seen, "Signal GameState.part1_completed đã phát và bắt được")
	_check(GameState.get_reputation("dong") > 0, "Uy tín Aldenmere > 0 sau tuyến giải phóng (thấy %d)" % GameState.get_reputation("dong"))
	# --- Ending panel: hiện qua signal, khóa player, tổng kết đúng flags ---
	_check(_panel.visible, "EndingPanel hiện visible sau part1_completed")
	_check(GameState.in_dialogue, "Panel hiện -> in_dialogue = true (khóa player)")
	var summary: Label = _panel.get_node("CenterContainer/PanelContainer/VBoxContainer/SummaryLabel")
	_check(summary.text.contains("Trạm thuế Stonebridge đã bị phá"),
		"Tổng kết ending: dòng trạm thuế ở nhánh ĐÃ phá")
	_check(summary.text.contains("Uy tín Aldenmere: %d" % GameState.get_reputation("dong")),
		"Tổng kết ending: dòng uy tín khớp GameState")
	var final_label: Label = _panel.get_node("CenterContainer/PanelContainer/VBoxContainer/FinalLabel")
	_check(final_label.text.contains("Cổng Tường Nam đã mở"), "Ending có dòng kết mở Cổng Tường Nam / Vùng Nam")
	# Nút "Chơi tiếp": ẩn panel + mở khóa player
	var btn: Button = _panel.get_node("CenterContainer/PanelContainer/VBoxContainer/ContinueButton")
	btn.pressed.emit()
	_check(not _panel.visible, "Bấm 'Chơi tiếp' -> EndingPanel ẩn")
	_check(not GameState.in_dialogue, "Bấm 'Chơi tiếp' -> in_dialogue = false (mở khóa player)")
