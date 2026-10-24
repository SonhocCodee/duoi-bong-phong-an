extends Node
## Test tự động cho nhánh skill PHÁP SƯ (đợt 5):
##   godot --headless --path game res://tests/mage_skill_test.tscn
## Kiểm: gate flag tay_giai_phong, mở 3 skill bằng điểm/cấp, save dict,
## Cầu Lửa 160% nổ diện rộng, Gai Băng 110% + slow 0.4 + stun 0.8s,
## Sét Lan nhảy 4 mục tiêu falloff 0.85, no-target không tốn STA/CD,
## panel + HUD 9 ô.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[MAGETEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[MAGETEST] FAIL: ", label)


func _spawn_merc(pos: Vector2) -> Node:
	var e: Node = load("res://enemies/mercenary.tscn").instantiate()
	e.set("drop_potion_chance", 0.0)
	e.set("drop_herb_chance", 0.0)
	e.set("drop_equip_chance", 0.0)
	e.set("wander", false)
	e.global_position = pos
	add_child(e)
	# Sau add_child (_ready đã chốt hp = max_hp gốc 180) tăng bền lên 1000
	# để ăn đủ các đòn test mà không chết giữa chừng.
	e.set("max_hp", 1000)
	e.set("hp", 1000)
	return e


func _free_enemies(list: Array) -> void:
	for e in list:
		if e != null and is_instance_valid(e):
			e.queue_free()


func _ready() -> void:
	print("[MAGETEST] Bắt đầu test Pháp Sư.")
	GameState.reset_game()
	QuestManager.reset_quests()
	# Điều khiển cấp/điểm trực tiếp để test gate logic độc lập với đường XP dài.
	GameState.level = 17
	GameState.skill_points = 3

	# --- Gate Phần 3 ---
	_check(not GameState.try_unlock_skill("cau_lua"),
		"Chưa có tay_giai_phong: không mở được Cầu Lửa")
	_check(GameState.get_skill_points() == 3,
		"Mở skill bị gate: không trừ điểm (còn %d)" % GameState.get_skill_points())
	var panel0: Node = load("res://ui/skill_panel.tscn").instantiate()
	add_child(panel0)
	await get_tree().process_frame
	var summary0: String = str(panel0.call("build_summary_text"))
	_check(summary0.contains("CHIẾN ĐẤU PHÁP SƯ: Chưa mở"),
		"Panel trước Phần 3: nhánh Pháp Sư ghi chưa mở")
	_check(summary0.contains("Khiên Ma Thuật: Chưa học") and summary0.contains("Mưa Thiên Thạch: Chưa học"),
		"Panel: 2 skill Pháp Sư trang 2 chưa học (đợt 6 đã làm thật, chờ mở khoá)")
	panel0.queue_free()

	GameState.set_flag("tay_giai_phong")
	var points_before: int = GameState.get_skill_points()
	_check(GameState.try_unlock_skill("cau_lua"), "Sau Phần 3 + Lv17: mở Cầu Lửa")
	_check(GameState.try_unlock_skill("gai_bang"), "Sau Phần 3 + Lv17: mở Gai Băng")
	_check(GameState.try_unlock_skill("set_lan"), "Sau Phần 3 + Lv17: mở Sét Lan")
	_check(GameState.get_skill_points() == points_before - 3,
		"Mở 3 skill trừ đúng 3 điểm (%d -> %d)" % [points_before, GameState.get_skill_points()])
	var d: Dictionary = GameState.to_dict()
	var unlocked: Array = d.get("unlocked_skills", [])
	_check(unlocked.has("cau_lua") and unlocked.has("gai_bang") and unlocked.has("set_lan"),
		"to_dict giữ đủ 3 skill Pháp Sư")
	GameState.unlocked_skills = []
	GameState.from_dict(d)
	_check(GameState.is_skill_unlocked("cau_lua") and GameState.is_skill_unlocked("gai_bang")
		and GameState.is_skill_unlocked("set_lan"),
		"from_dict khôi phục đủ 3 skill Pháp Sư")

	# --- Player ---
	var player: Node = load("res://player/player.tscn").instantiate()
	player.global_position = Vector2(0, 0)
	add_child(player)
	await get_tree().process_frame
	await get_tree().process_frame
	player.set("stamina", 100.0)

	# Sét Lan khi chưa có mục tiêu: không tốn STA/CD
	_check(not bool(player.call("_use_skill", "set_lan")),
		"Sét Lan không có mục tiêu -> không chạy")
	_check(is_equal_approx(float(player.get("stamina")), 100.0),
		"No-target: stamina giữ nguyên 100")
	_check(float(player.call("get_skill_cooldown", "set_lan")) == 0.0,
		"No-target: cooldown Sét Lan vẫn 0")

	var base_dmg: int = int(player.call("effective_damage", 0))

	# --- Cầu Lửa ---
	player.set("facing", Vector2.RIGHT)
	player.set("stamina", 100.0)
	player.global_position = Vector2(0, 0)
	var f1: Node = _spawn_merc(Vector2(120, 0))
	var f2: Node = _spawn_merc(Vector2(120, 60))
	var f_out: Node = _spawn_merc(Vector2(350, 0))
	await get_tree().process_frame
	# Đặt lại vị trí ngay trước khi ra chiêu (quái chưa kịp di chuyển/chase)
	player.global_position = Vector2(0, 0)
	f1.global_position = Vector2(120, 0)
	f2.global_position = Vector2(120, 60)
	f_out.global_position = Vector2(350, 0)
	var expected_fire: int = int(round(float(base_dmg) * 1.6))
	var f1_hp0: int = int(f1.get("hp"))
	var f2_hp0: int = int(f2.get("hp"))
	var fout_hp0: int = int(f_out.get("hp"))
	_check(bool(player.call("_use_skill", "cau_lua")), "Cầu Lửa chạy khi đã mở")
	var ball: Node = player.get("last_fireball")
	_check(ball != null and is_instance_valid(ball), "Cầu Lửa tạo Fireball")
	if ball != null:
		_check(int(ball.get("damage")) == expected_fire,
			"Fireball damage = 160%% (%d)" % expected_fire)
		_check(not bool(ball.get("exploded")), "Fireball chưa nổ ngay khi vừa bắn")
		_check(int(f1.get("hp")) == f1_hp0, "Trước khi nổ: mục tiêu chưa mất HP")
		ball.call("explode_now")
		_check(int(f1.get("hp")) == f1_hp0 - expected_fire,
			"Fireball nổ gây đúng %d damage cho quái 1 trong radius (HP %d -> %d)" % [expected_fire, f1_hp0, int(f1.get("hp"))])
		_check(int(f2.get("hp")) == f2_hp0 - expected_fire,
			"Fireball nổ gây đúng %d damage cho quái 2 trong radius (HP %d -> %d)" % [expected_fire, f2_hp0, int(f2.get("hp"))])
		_check(int(f_out.get("hp")) == fout_hp0, "Fireball: quái ngoài radius nguyên vẹn")
		_check(int(ball.get("hit_count")) == 2, "Fireball hit_count = 2 (thấy %d)" % int(ball.get("hit_count")))
	_check(is_equal_approx(float(player.get("stamina")), 75.0), "Cầu Lửa tốn 25 STA")
	_check(float(player.call("get_skill_cooldown", "cau_lua")) > 8.0,
		"Cooldown Cầu Lửa ~9s")
	_check(not bool(player.call("_use_skill", "cau_lua")), "Dùng lại Cầu Lửa ngay bị cooldown chặn")
	_free_enemies([f1, f2, f_out])
	await get_tree().process_frame
	await get_tree().process_frame

	# --- Gai Băng ---
	player.set("facing", Vector2.RIGHT)
	player.set("stamina", 100.0)
	player.global_position = Vector2(0, 0)
	var i_in: Node = _spawn_merc(Vector2(150, 0))
	var i_out: Node = _spawn_merc(Vector2(350, 0))
	await get_tree().process_frame
	player.global_position = Vector2(0, 0)
	i_in.global_position = Vector2(150, 0)
	i_out.global_position = Vector2(350, 0)
	var expected_ice: int = int(round(float(base_dmg) * 1.1))
	var iin_hp0: int = int(i_in.get("hp"))
	var iout_hp0: int = int(i_out.get("hp"))
	_check(bool(player.call("_use_skill", "gai_bang")), "Gai Băng chạy khi đã mở")
	var spikes: Node = player.get("last_ice_spikes")
	_check(spikes != null and is_instance_valid(spikes), "Gai Băng tạo IceSpikes")
	_check(int(i_in.get("hp")) == iin_hp0 - expected_ice,
		"Gai Băng gây đúng %d damage (110%%) cho quái trong radius (HP %d -> %d)" % [expected_ice, iin_hp0, int(i_in.get("hp"))])
	_check(bool(i_in.call("is_slowed")), "Quái trong radius bị làm chậm sau Gai Băng")
	_check(is_equal_approx(float(i_in.get("slow_factor")), 0.4),
		"Slow factor = 0.4 (còn 40%% tốc độ, thấy %.2f)" % float(i_in.get("slow_factor")))
	_check(float(i_in.get("stun_timer")) > 0.7, "Stun timer ~0.8s (%.2f)" % float(i_in.get("stun_timer")))
	if spikes != null:
		_check(int(spikes.get("hit_count")) == 1, "IceSpikes hit_count = 1 (thấy %d)" % int(spikes.get("hit_count")))
		_check((spikes.get("affected") as Array).size() == 1, "IceSpikes affected = 1 quái")
	_check(int(i_out.get("hp")) == iout_hp0, "Gai Băng: quái ngoài radius nguyên vẹn")
	_check(not bool(i_out.call("is_slowed")), "Gai Băng: quái ngoài radius không bị chậm")
	_check(is_equal_approx(float(player.get("stamina")), 80.0), "Gai Băng tốn 20 STA")
	_check(float(player.call("get_skill_cooldown", "gai_bang")) > 10.0,
		"Cooldown Gai Băng ~11s")
	_free_enemies([i_in, i_out])
	await get_tree().process_frame
	await get_tree().process_frame

	# --- Sét Lan ---
	player.set("facing", Vector2.RIGHT)
	player.set("stamina", 100.0)
	player.global_position = Vector2(0, 0)
	var chain: Array = []
	chain.append(_spawn_merc(Vector2(200, 0)))
	chain.append(_spawn_merc(Vector2(350, 0)))
	chain.append(_spawn_merc(Vector2(500, 0)))
	chain.append(_spawn_merc(Vector2(650, 0)))
	var c_far: Node = _spawn_merc(Vector2(1000, 0))
	await get_tree().process_frame
	player.global_position = Vector2(0, 0)
	for idx in chain.size():
		(chain[idx] as Node2D).global_position = Vector2(200 + 150 * idx, 0)
	c_far.global_position = Vector2(1000, 0)
	var chain_hp0: Array = []
	for e in chain:
		chain_hp0.append(int(e.get("hp")))
	var far_hp0: int = int(c_far.get("hp"))
	var expected_chain: Array = []
	var expected_total: int = 0
	for jump in 4:
		var dmg_j: int = int(round(float(base_dmg) * 1.0 * pow(0.85, float(jump))))
		expected_chain.append(dmg_j)
		expected_total += dmg_j
	_check(bool(player.call("_use_skill", "set_lan")), "Sét Lan chạy khi có mục tiêu")
	var hit_targets: Array = player.get("last_chain_targets")
	_check(hit_targets.size() == 4, "Sét Lan trúng đúng 4 mục tiêu (thấy %d)" % hit_targets.size())
	if hit_targets.size() == 4:
		_check(hit_targets[0] == chain[0] and hit_targets[3] == chain[3],
			"Sét Lan nhảy theo thứ tự gần -> xa dọc chuỗi")
	for idx in chain.size():
		_check(int(chain[idx].get("hp")) == int(chain_hp0[idx]) - int(expected_chain[idx]),
			"Sét Lan nhảy %d gây %d damage (falloff 0.85, HP %d -> %d)" % [
				idx + 1, int(expected_chain[idx]), int(chain_hp0[idx]), int(chain[idx].get("hp"))])
	_check(int(player.get("last_chain_total_damage")) == expected_total,
		"Sét Lan tổng damage = %d (thấy %d)" % [expected_total, int(player.get("last_chain_total_damage"))])
	_check(int(c_far.get("hp")) == far_hp0, "Sét Lan: quái thứ 5 ngoài chain_range không trúng")
	_check(is_equal_approx(float(player.get("stamina")), 75.0), "Sét Lan tốn 25 STA")
	_check(float(player.call("get_skill_cooldown", "set_lan")) > 11.0,
		"Cooldown Sét Lan ~12s")
	_free_enemies(chain + [c_far])
	await get_tree().process_frame
	await get_tree().process_frame

	# --- Panel + HUD sau khi mở ---
	var panel: Node = load("res://ui/skill_panel.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	var summary: String = str(panel.call("build_summary_text"))
	_check(summary.contains("CHIẾN ĐẤU PHÁP SƯ: Đã mở"), "Panel sau Phần 3: nhánh Pháp Sư đã mở")
	_check(summary.contains("Cầu Lửa: Đã học") and summary.contains("Gai Băng: Đã học")
		and summary.contains("Sét Lan: Đã học"), "Panel: cả 3 skill Pháp Sư đã học")
	_check(summary.contains("Khiên Ma Thuật: Chưa học") and summary.contains("Mưa Thiên Thạch: Chưa học"),
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
	_check(skill_label.text.contains("Cầu Lửa") and skill_label.text.contains("Gai Băng")
		and skill_label.text.contains("Sét Lan"), "HUD SkillLabel liệt kê 3 skill Pháp Sư")

	player.queue_free()
	print("[MAGETEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
