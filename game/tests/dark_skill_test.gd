extends Node
## Test tự động cho nhánh skill DẤU ẤN THUẬT ĐEN (đợt 4):
##   godot --headless --path game res://tests/dark_skill_test.tscn
## Kiểm: gate flag nam_giai_phong, mở 3 skill bằng điểm/cấp, save dict,
## Dấu Ấn Lửa nổ trễ 150%, Bẫy Hồn slow/stun, Hút Sinh Lực 120% + hồi 40%,
## no-target không tốn STA/CD, panel + HUD 9 ô.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[DARKTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[DARKTEST] FAIL: ", label)


func _ready() -> void:
	print("[DARKTEST] Bắt đầu test Thuật Đen.")
	GameState.reset_game()
	QuestManager.reset_quests()
	# Điều khiển cấp/điểm trực tiếp để test gate logic độc lập với đường XP dài.
	GameState.level = 11
	GameState.skill_points = 3

	# --- Gate Phần 2 ---
	_check(not GameState.try_unlock_skill("dau_an_lua"),
		"Chưa có nam_giai_phong: không mở được Dấu Ấn Lửa")
	_check(GameState.get_skill_points() == 3,
		"Mở skill bị gate: không trừ điểm (còn %d)" % GameState.get_skill_points())
	var panel0: Node = load("res://ui/skill_panel.tscn").instantiate()
	add_child(panel0)
	await get_tree().process_frame
	var summary0: String = str(panel0.call("build_summary_text"))
	_check(summary0.contains("DẤU ẤN / THUẬT ĐEN: Chưa mở"),
		"Panel trước Phần 2: nhánh Thuật Đen ghi chưa mở")
	_check(summary0.contains("Triệu Hồi Bóng: Chưa học") and summary0.contains("Cổng Phong Ấn: Chưa học"),
		"Panel: 2 skill Thuật Đen trang 2 chưa học (đợt 6 đã làm thật, chờ mở khoá)")
	panel0.queue_free()

	GameState.set_flag("nam_giai_phong")
	var points_before: int = GameState.get_skill_points()
	_check(GameState.try_unlock_skill("dau_an_lua"), "Sau Phần 2 + Lv11: mở Dấu Ấn Lửa")
	_check(GameState.try_unlock_skill("bay_hon"), "Sau Phần 2 + Lv11: mở Bẫy Hồn")
	_check(GameState.try_unlock_skill("hut_sinh_luc"), "Sau Phần 2 + Lv11: mở Hút Sinh Lực")
	_check(GameState.get_skill_points() == points_before - 3,
		"Mở 3 skill trừ đúng 3 điểm (%d -> %d)" % [points_before, GameState.get_skill_points()])
	var d: Dictionary = GameState.to_dict()
	var unlocked: Array = d.get("unlocked_skills", [])
	_check(unlocked.has("dau_an_lua") and unlocked.has("bay_hon") and unlocked.has("hut_sinh_luc"),
		"to_dict giữ đủ 3 skill Thuật Đen")
	GameState.unlocked_skills = []
	GameState.from_dict(d)
	_check(GameState.is_skill_unlocked("dau_an_lua") and GameState.is_skill_unlocked("bay_hon")
		and GameState.is_skill_unlocked("hut_sinh_luc"),
		"from_dict khôi phục đủ 3 skill Thuật Đen")

	# --- Player + mục tiêu bền (mercenary: HP cao, đòn từ bên hông không bị khiên giảm) ---
	var player: Node = load("res://player/player.tscn").instantiate()
	player.global_position = Vector2(0, 0)
	add_child(player)
	await get_tree().process_frame
	await get_tree().process_frame
	player.set("stamina", 100.0)

	# Hút Sinh Lực khi chưa có mục tiêu: không tốn STA/CD
	_check(not bool(player.call("_use_skill", "hut_sinh_luc")),
		"Hút Sinh Lực không có mục tiêu -> không chạy")
	_check(is_equal_approx(float(player.get("stamina")), 100.0),
		"No-target: stamina giữ nguyên 100")
	_check(float(player.call("get_skill_cooldown", "hut_sinh_luc")) == 0.0,
		"No-target: cooldown Hút Sinh Lực vẫn 0")

	var target: Node = load("res://enemies/mercenary.tscn").instantiate()
	target.set("drop_potion_chance", 0.0)
	target.set("drop_herb_chance", 0.0)
	target.set("drop_equip_chance", 0.0)
	target.set("wander", false)
	target.global_position = Vector2(60, 0)
	add_child(target)
	await get_tree().process_frame
	player.global_position = Vector2(0, 0)
	target.global_position = Vector2(60, 0)
	var base_dmg: int = int(player.call("effective_damage", 0))

	# --- Dấu Ấn Lửa ---
	var hp0: int = int(target.get("hp"))
	var expected_rune: int = int(round(float(base_dmg) * 1.5))
	_check(bool(player.call("_use_skill", "dau_an_lua")), "Dấu Ấn Lửa chạy khi đã mở")
	var rune: Node = player.get("last_dark_rune")
	_check(rune != null and is_instance_valid(rune), "Dấu Ấn Lửa tạo DarkRune")
	if rune != null:
		_check(int(rune.get("damage")) == expected_rune,
			"DarkRune damage = 150%% (%d)" % expected_rune)
		_check(not bool(rune.get("exploded")), "DarkRune chưa nổ ngay khi vừa đặt")
		_check(int(target.get("hp")) == hp0, "Trước khi nổ: mục tiêu chưa mất HP")
		rune.call("explode_now")
		_check(int(target.get("hp")) == hp0 - expected_rune,
			"DarkRune nổ gây đúng %d damage (HP %d -> %d)" % [expected_rune, hp0, int(target.get("hp"))])
	_check(is_equal_approx(float(player.get("stamina")), 80.0), "Dấu Ấn Lửa tốn 20 STA")
	_check(float(player.call("get_skill_cooldown", "dau_an_lua")) > 7.0,
		"Cooldown Dấu Ấn Lửa ~8s")
	_check(not bool(player.call("_use_skill", "dau_an_lua")), "Dùng lại ngay bị cooldown chặn")

	# --- Bẫy Hồn ---
	player.set("facing", Vector2.RIGHT)
	player.set("stamina", 100.0)
	player.global_position = Vector2(0, 0)
	target.global_position = Vector2(60, 0)
	_check(bool(player.call("_use_skill", "bay_hon")), "Bẫy Hồn chạy khi đã mở")
	var trap: Node = player.get("last_soul_trap")
	_check(trap != null and is_instance_valid(trap), "Bẫy Hồn tạo SoulTrap")
	if trap != null:
		_check((trap.global_position as Vector2).distance_to(Vector2(72, 0)) < 2.0,
			"SoulTrap đặt trước mặt player tại %s" % str(trap.global_position))
		_check(bool(trap.call("trigger_enemy", target)), "SoulTrap kích hoạt lên mục tiêu trong vùng")
		_check(bool(target.call("is_slowed")), "Mục tiêu bị làm chậm sau Bẫy Hồn")
		_check(is_equal_approx(float(target.get("slow_factor")), 0.5),
			"Slow factor = 0.5 (chậm 50%)")
		_check(float(target.get("slow_timer")) > 2.8, "Slow timer ~3s (%.2f)" % float(target.get("slow_timer")))
		_check(float(target.get("stun_timer")) > 0.8, "Stun timer ~1s (%.2f)" % float(target.get("stun_timer")))
		var slowed_speed: float = float(target.call("_move_speed"))
		_check(slowed_speed < float(target.get("speed")) and is_equal_approx(slowed_speed, float(target.get("speed")) * 0.5),
			"Tốc độ hiệu dụng giảm còn 50%% (%.1f)" % slowed_speed)
	_check(is_equal_approx(float(player.get("stamina")), 85.0), "Bẫy Hồn tốn 15 STA")
	_check(float(player.call("get_skill_cooldown", "bay_hon")) > 11.0, "Cooldown Bẫy Hồn ~12s")

	# Reset status để đòn Hút Sinh Lực không bị ảnh hưởng bởi trạng thái phụ.
	target.set("slow_timer", 0.0)
	target.set("stun_timer", 0.0)
	target.set("slow_factor", 1.0)

	# --- Hút Sinh Lực ---
	player.global_position = Vector2(0, 0)
	target.global_position = Vector2(100, 0)
	player.set("stamina", 100.0)
	player.set("hp", 50)
	GameState.set_player_hp(50, int(player.get("max_hp")))
	var hp1: int = int(target.get("hp"))
	var expected_drain: int = int(round(float(base_dmg) * 1.2))
	var expected_heal: int = int(round(float(expected_drain) * 0.4))
	_check(bool(player.call("_use_skill", "hut_sinh_luc")), "Hút Sinh Lực chạy khi có mục tiêu")
	_check(int(target.get("hp")) == hp1 - expected_drain,
		"Hút Sinh Lực gây đúng %d damage (120%%) (HP %d -> %d)" % [expected_drain, hp1, int(target.get("hp"))])
	_check(int(player.get("last_lifesteal_amount")) == expected_heal,
		"Hút Sinh Lực ghi nhận hồi %d HP (40%% damage)" % expected_heal)
	_check(int(player.get("hp")) == 50 + expected_heal,
		"HP player hồi đúng 40%% (50 -> %d)" % int(player.get("hp")))
	_check(is_equal_approx(float(player.get("stamina")), 75.0), "Hút Sinh Lực tốn 25 STA")
	_check(float(player.call("get_skill_cooldown", "hut_sinh_luc")) > 9.0, "Cooldown Hút Sinh Lực ~10s")

	# --- Panel + HUD sau khi mở ---
	var panel: Node = load("res://ui/skill_panel.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	var summary: String = str(panel.call("build_summary_text"))
	_check(summary.contains("DẤU ẤN / THUẬT ĐEN: Đã mở"), "Panel sau Phần 2: nhánh Thuật Đen đã mở")
	_check(summary.contains("Dấu Ấn Lửa: Đã học") and summary.contains("Bẫy Hồn: Đã học")
		and summary.contains("Hút Sinh Lực: Đã học"), "Panel: cả 3 skill Thuật Đen đã học")
	_check(summary.contains("Triệu Hồi Bóng: Chưa học") and summary.contains("Cổng Phong Ấn: Chưa học"),
		"Panel: 2 skill trang 2 vẫn chưa học ở thời điểm này")
	panel.queue_free()

	var hud: Node = load("res://ui/hud.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	await get_tree().process_frame
	var box: Node = hud.get_node_or_null("SkillBoxContainer")
	_check(box != null, "HUD có SkillBoxContainer")
	if box != null:
		_check(box.get_child_count() == 9, "HUD có đúng 9 ô skill (thấy %d)" % box.get_child_count())
	var skill_label: Label = hud.get_node("MarginContainer/VBoxContainer/SkillLabel")
	_check(skill_label.text.contains("Dấu Ấn Lửa") and skill_label.text.contains("Bẫy Hồn")
		and skill_label.text.contains("Hút Sinh Lực"), "HUD SkillLabel liệt kê 3 skill Thuật Đen")

	player.queue_free()
	print("[DARKTEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
