extends Node
## Test tự động cho 4 SKILL CUỐI + bị động DA SẮT (đợt 6 — đợt cuối):
##   godot --headless --path game res://tests/final_skill_test.tscn
## Kiểm: gate flag từng skill (Thuật Đen <- nam_giai_phong, Pháp Sư <-
## tay_giai_phong), Da Sắt giảm đúng 15% sau DEF, Triệu Hồi Bóng đánh
## 80% damage, Cổng Phong Ấn dịch chuyển xuyên tường mỏng + chặn kín
## thì fail không tốn STA/CD, Khiên Ma Thuật hấp thụ theo HP khiên,
## Mưa Thiên Thạch trúng quái trong vùng, HUD lật trang 2 còn 4 ô.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[FINALSKILL] PASS: ", label)
	else:
		_failures.append(label)
		print("[FINALSKILL] FAIL: ", label)


func _spawn_merc(pos: Vector2) -> Node:
	var e: Node = load("res://enemies/mercenary.tscn").instantiate()
	e.set("drop_potion_chance", 0.0)
	e.set("drop_herb_chance", 0.0)
	e.set("drop_equip_chance", 0.0)
	e.set("drop_core_chance", 0.0)
	e.set("wander", false)
	e.global_position = pos
	add_child(e)
	e.set("max_hp", 1000)
	e.set("hp", 1000)
	return e


func _reset_cd(player: Node, skill_id: String) -> void:
	var cds: Dictionary = player.get("skill_cooldowns")
	cds[skill_id] = 0.0
	player.set("skill_cooldowns", cds)


func _ready() -> void:
	print("[FINALSKILL] Bắt đầu test 4 skill cuối + Da Sắt.")
	GameState.reset_game()
	QuestManager.reset_quests()
	GameState.level = 25
	GameState.skill_points = 12

	# --- Gate flag ---
	_check(not GameState.try_unlock_skill("trieu_hoi_bong"),
		"Chưa có nam_giai_phong: không mở được Triệu Hồi Bóng")
	_check(not GameState.try_unlock_skill("cong_phong_an"),
		"Chưa có nam_giai_phong: không mở được Cổng Phong Ấn")
	_check(not GameState.try_unlock_skill("khien_ma_thuat"),
		"Chưa có tay_giai_phong: không mở được Khiên Ma Thuật")
	_check(not GameState.try_unlock_skill("mua_thien_thach"),
		"Chưa có tay_giai_phong: không mở được Mưa Thiên Thạch")
	GameState.set_flag("nam_giai_phong")
	GameState.set_flag("tay_giai_phong")
	_check(GameState.try_unlock_skill("trieu_hoi_bong"), "Đủ điều kiện: mở Triệu Hồi Bóng")
	_check(GameState.try_unlock_skill("cong_phong_an"), "Đủ điều kiện: mở Cổng Phong Ấn")
	_check(GameState.try_unlock_skill("khien_ma_thuat"), "Đủ điều kiện: mở Khiên Ma Thuật")
	_check(GameState.try_unlock_skill("mua_thien_thach"), "Đủ điều kiện: mở Mưa Thiên Thạch")

	# Save dict giữ đủ 4 skill mới
	var d: Dictionary = GameState.to_dict()
	var unlocked: Array = d.get("unlocked_skills", [])
	_check(unlocked.has("trieu_hoi_bong") and unlocked.has("cong_phong_an")
		and unlocked.has("khien_ma_thuat") and unlocked.has("mua_thien_thach"),
		"to_dict giữ đủ 4 skill đợt 6")

	# --- Player ---
	var player: Node = load("res://player/player.tscn").instantiate()
	player.global_position = Vector2(0, 0)
	add_child(player)
	await get_tree().process_frame
	await get_tree().process_frame
	player.set("max_hp", 1000)
	player.set("hp", 1000)
	player.set("stamina", 100.0)
	var base_dmg: int = int(player.call("effective_damage", 0))

	# --- Triệu Hồi Bóng ---
	var merc1: Node = _spawn_merc(Vector2(120, 0))
	await get_tree().process_frame
	player.global_position = Vector2(0, 0)
	merc1.global_position = Vector2(120, 0)
	player.set("stamina", 100.0)
	_check(bool(player.call("_use_skill", "trieu_hoi_bong")), "Triệu Hồi Bóng chạy khi đã mở")
	var ally: Node = player.get("last_shadow_ally")
	_check(ally != null, "Bóng đồng minh được triệu hồi (last_shadow_ally)")
	var merc1_hp0: int = int(merc1.get("hp"))
	if ally != null:
		var struck: bool = bool(ally.call("strike_once"))
		_check(struck, "Bóng strike_once trúng quái trong tầm")
		var expected_shadow: int = int(round(float(base_dmg) * 0.8))
		_check(int(merc1.get("hp")) == merc1_hp0 - expected_shadow,
			"Bóng gây đúng 80%% damage (%d -> %d)" % [merc1_hp0, int(merc1.get("hp"))])
		ally.call("dismiss")
	merc1.queue_free()

	# --- Cổng Phong Ấn: xuyên tường mỏng ---
	var wall_thin := StaticBody2D.new()
	wall_thin.collision_layer = 1
	wall_thin.collision_mask = 0
	var cs_thin := CollisionShape2D.new()
	var rect_thin := RectangleShape2D.new()
	rect_thin.size = Vector2(20, 240)
	cs_thin.shape = rect_thin
	wall_thin.add_child(cs_thin)
	wall_thin.global_position = Vector2(110, 0)
	add_child(wall_thin)
	await get_tree().physics_frame
	await get_tree().physics_frame
	player.global_position = Vector2(0, 0)
	player.set("facing", Vector2.RIGHT)
	player.set("stamina", 100.0)
	_reset_cd(player, "cong_phong_an")
	_check(bool(player.call("_use_skill", "cong_phong_an")), "Cổng Phong Ấn chạy qua tường mỏng")
	_check(player.global_position.x > 150.0,
		"Player dịch sang phía bên kia tường (x=%.0f)" % player.global_position.x)
	_check(player.global_position.x <= 230.0,
		"Điểm đáp trong tầm dịch tối đa 220px (x=%.0f)" % player.global_position.x)

	# --- Cổng Phong Ấn: chặn kín -> fail, không tốn STA/CD ---
	wall_thin.global_position = Vector2(170, 0)
	rect_thin.size = Vector2(360, 240)
	await get_tree().physics_frame
	await get_tree().physics_frame
	player.global_position = Vector2(0, 0)
	player.set("facing", Vector2.RIGHT)
	player.set("stamina", 100.0)
	_reset_cd(player, "cong_phong_an")
	_check(not bool(player.call("_use_skill", "cong_phong_an")),
		"Chặn kín phía trước: Cổng Phong Ấn không chạy")
	_check(is_equal_approx(float(player.get("stamina")), 100.0),
		"Blocked: stamina giữ nguyên 100")
	_check(float(player.call("get_skill_cooldown", "cong_phong_an")) == 0.0,
		"Blocked: cooldown Cổng Phong Ấn vẫn 0")
	wall_thin.queue_free()

	# --- Khiên Ma Thuật ---
	player.global_position = Vector2(0, 0)
	player.set("stamina", 100.0)
	player.set("hp", 1000)
	_check(bool(player.call("_use_skill", "khien_ma_thuat")), "Khiên Ma Thuật chạy khi đã mở")
	var shield0: int = int(player.get("magic_shield_hp"))
	_check(shield0 == 40 + 25 * 4, "Khiên = 40 + 4xLv25 = %d HP" % shield0)
	player.call("take_damage", 100, Vector2(-50, 0))
	_check(int(player.get("magic_shield_hp")) == shield0 - 100,
		"Khiên hấp thụ trọn đòn 100 đầu (còn %d)" % int(player.get("magic_shield_hp")))
	_check(int(player.get("hp")) == 1000, "Đòn đầu không lọt vào HP")
	player.call("take_damage", 100, Vector2(-50, 0))
	_check(int(player.get("magic_shield_hp")) == 0, "Khiên vỡ sau khi hấp thụ nốt")
	_check(int(player.get("hp")) == 1000 - 60,
		"Phần dư 60 lọt qua khiên vào HP (HP=%d)" % int(player.get("hp")))

	# --- Mưa Thiên Thạch ---
	var merc2: Node = _spawn_merc(Vector2(150, 0))
	await get_tree().process_frame
	player.global_position = Vector2(0, 0)
	player.set("facing", Vector2.RIGHT)
	merc2.global_position = Vector2(150, 0)
	player.set("stamina", 100.0)
	var merc2_hp0: int = int(merc2.get("hp"))
	_check(bool(player.call("_use_skill", "mua_thien_thach")), "Mưa Thiên Thạch chạy khi đã mở")
	var shower: Node = player.get("last_meteor_shower")
	_check(shower != null, "Có node Mưa Thiên Thạch (last_meteor_shower)")
	if shower != null:
		shower.call("run_wave_now")
		shower.call("resolve_strikes_now")
		_check(int(shower.get("hit_count")) >= 1, "Thiên thạch trúng ít nhất 1 quái trong vùng")
		_check(int(merc2.get("hp")) < merc2_hp0,
			"Quái trong vùng mất HP (%d -> %d)" % [merc2_hp0, int(merc2.get("hp"))])
	merc2.queue_free()

	# --- Da Sắt (bị động Chiến binh) ---
	var panel0: Node = load("res://ui/skill_panel.tscn").instantiate()
	add_child(panel0)
	await get_tree().process_frame
	var summary0: String = str(panel0.call("build_summary_text"))
	_check(summary0.contains("Da Sắt: Chưa học"), "Panel: Da Sắt chưa học trước khi mở")
	panel0.queue_free()
	player.set("hp", 1000)
	player.call("take_damage", 200, Vector2(-50, 0))
	_check(int(player.get("hp")) == 800, "Chưa có Da Sắt: đòn 200 trừ đủ 200 (HP=%d)" % int(player.get("hp")))
	_check(GameState.try_unlock_skill("da_sat"), "Mở khoá bị động Da Sắt (Lv3+)")
	player.set("hp", 1000)
	player.call("take_damage", 200, Vector2(-50, 0))
	_check(int(player.get("hp")) == 1000 - 170,
		"Có Da Sắt: đòn 200 chỉ còn 170 (-15%%) (HP=%d)" % int(player.get("hp")))
	var panel1: Node = load("res://ui/skill_panel.tscn").instantiate()
	add_child(panel1)
	await get_tree().process_frame
	var summary1: String = str(panel1.call("build_summary_text"))
	_check(summary1.contains("Da Sắt: Đã học"), "Panel: Da Sắt đã học sau khi mở")
	_check(summary1.contains("Triệu Hồi Bóng: Đã học") and summary1.contains("Mưa Thiên Thạch: Đã học"),
		"Panel: skill trang 2 hiện Đã học")
	panel1.queue_free()

	# --- HUD lật trang 2 ---
	player.set("skill_page", 2)
	var hud: Node = load("res://ui/hud.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var box: Node = hud.get_node_or_null("SkillBoxContainer")
	_check(box != null, "HUD có SkillBoxContainer")
	if box != null:
		_check(box.get_child_count() == 4,
			"HUD trang 2 có đúng 4 ô skill (thấy %d)" % box.get_child_count())
	hud.queue_free()
	player.set("skill_page", 1)

	player.queue_free()
	print("[FINALSKILL] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
