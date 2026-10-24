extends Node
## Test tự động cho SKILL THẬT (GDD v2 mục 5.1, nhánh Chiến binh):
##   godot --headless --path game res://tests/skill_test.tscn
## Kiểm: (a) lên cấp +1 điểm, mở khoá trừ điểm đúng + to_dict/from_dict giữ
## unlocked, khoá theo cấp; (b) Chém Xoáy gây damage đúng 130% lên quái cạnh;
## (c) cooldown chặn dùng lần 2 ngay; (d) Xung Kích đổi vị trí ~160px +
## gây damage 110%; (e) Cuồng Nộ bật buff (tốc đánh + damage tăng).
## Cộng: skill chưa mở khoá không chạy, panel cây skill + HUD label.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []
var _had_save: bool = false
var _save_backup: String = ""

const SAVE_PATH: String = "user://save.json"


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[SKILLTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[SKILLTEST] FAIL: ", label)


func _spawn_slime(pos: Vector2) -> Node:
	var e: Node = load("res://enemies/slime.tscn").instantiate()
	e.set("drop_potion_chance", 0.0)
	e.set("drop_herb_chance", 0.0)
	e.set("drop_equip_chance", 0.0)
	e.set("wander", false)
	e.global_position = pos
	add_child(e)
	return e


func _ready() -> void:
	print("[SKILLTEST] Bắt đầu test skill.")
	_backup_existing_save()
	SaveSystem.delete_save()
	GameState.reset_game()
	QuestManager.reset_quests()

	# ============ (a) Điểm skill + mở khoá + save dict ============
	_check(GameState.get_skill_points() == 0 and GameState.unlocked_skills.is_empty(),
		"Reset: skill_points = 0, chưa học skill nào")
	_check(load("res://ui/skill_panel.tscn") != null, "Load được ui/skill_panel.tscn")
	_check(not GameState.try_unlock_skill("chem_xoay"),
		"Chưa có điểm: try_unlock_skill('chem_xoay') = false")
	GameState.add_xp(100) # Lv1 -> Lv2
	_check(GameState.level == 2, "add_xp(100) -> level 2 (thấy %d)" % GameState.level)
	_check(GameState.get_skill_points() == 1,
		"Lên 1 cấp -> +1 điểm skill (thấy %d)" % GameState.get_skill_points())
	_check(not GameState.try_unlock_skill("cuong_no"),
		"Khoá theo cấp: Lv2 không mở được Cuồng Nộ (cần Lv4)")
	_check(GameState.try_unlock_skill("chem_xoay"), "Mở khoá Chém Xoáy thành công")
	_check(GameState.get_skill_points() == 0,
		"Mở khoá trừ đúng 1 điểm (còn %d)" % GameState.get_skill_points())
	_check(GameState.is_skill_unlocked("chem_xoay"), "unlocked_skills chứa chem_xoay")
	_check(not GameState.try_unlock_skill("chem_xoay"), "Học lại skill đã học = false")
	var d: Dictionary = GameState.to_dict()
	_check(int(d.get("skill_points", -1)) == 0, "to_dict: skill_points = 0")
	_check((d.get("unlocked_skills", []) as Array).has("chem_xoay"),
		"to_dict: unlocked_skills chứa chem_xoay")
	# Round-trip from_dict khôi phục đúng
	GameState.skill_points = 99
	GameState.unlocked_skills = []
	GameState.from_dict(d)
	_check(GameState.get_skill_points() == 0 and GameState.is_skill_unlocked("chem_xoay"),
		"from_dict: khôi phục skill_points/unlocked_skills đúng")

	# ============ Player + skill chưa khoá / Chém Xoáy / cooldown ============
	var player: Node = load("res://player/player.tscn").instantiate()
	player.global_position = Vector2(500, 500)
	add_child(player)
	await get_tree().process_frame
	await get_tree().process_frame
	player.set("stamina", 100.0)

	var slime1: Node = _spawn_slime(Vector2(550, 500))
	await get_tree().process_frame
	# Đặt lại vị trí ngay trước khi ra chiêu (không await ở giữa -> quái chưa kịp di chuyển)
	player.global_position = Vector2(500, 500)
	slime1.global_position = Vector2(550, 500)
	var hp_before: int = int(slime1.get("hp"))
	var pos_before: Vector2 = player.global_position
	_check(not bool(player.call("_use_skill", "xung_kich")),
		"Skill chưa mở khoá (xung_kich): bấm không chạy")
	_check(int(slime1.get("hp")) == hp_before and player.global_position == pos_before,
		"Skill khoá: quái không mất máu, player không di chuyển")

	# (b) Chém Xoáy: 130% của effective_damage(0)
	var base_dmg: int = int(player.call("effective_damage", 0))
	var expected_chem: int = int(round(float(base_dmg) * 1.3))
	_check(bool(player.call("_use_skill", "chem_xoay")), "Chém Xoáy chạy khi đã mở khoá")
	_check(int(slime1.get("hp")) == hp_before - expected_chem,
		"(b) Chém Xoáy gây %d damage (130%% của %d) — HP quái %d -> %d" % [
			expected_chem, base_dmg, hp_before, int(slime1.get("hp"))])
	_check(is_equal_approx(float(player.get("stamina")), 75.0),
		"Chém Xoáy tốn 25 STA (còn %.0f)" % float(player.get("stamina")))

	# (c) Cooldown chặn lần 2 ngay lập tức
	var hp_after_chem: int = int(slime1.get("hp"))
	_check(float(player.call("get_skill_cooldown", "chem_xoay")) > 5.0,
		"(c) Cooldown Chém Xoáy ~6s sau khi dùng (%.1f)" % float(player.call("get_skill_cooldown", "chem_xoay")))
	_check(not bool(player.call("_use_skill", "chem_xoay")),
		"(c) Dùng Chém Xoáy lần 2 ngay -> bị cooldown chặn")
	_check(int(slime1.get("hp")) == hp_after_chem, "(c) Lần 2 bị chặn: quái không mất thêm máu")
	slime1.queue_free()

	# ============ Lên Lv4, mở nốt 2 skill ============
	GameState.add_xp(375) # Lv2 -(150)-> Lv3 -(225)-> Lv4, +2 điểm
	_check(GameState.level == 4 and GameState.get_skill_points() == 2,
		"Lên Lv4: +2 điểm nữa (Lv%d, %d điểm)" % [GameState.level, GameState.get_skill_points()])
	_check(GameState.try_unlock_skill("xung_kich"), "Mở khoá Xung Kích (Lv2) thành công")
	_check(GameState.try_unlock_skill("cuong_no"), "Mở khoá Cuồng Nộ (Lv4) thành công")
	_check(GameState.get_skill_points() == 0, "Mở hết 3 skill: điểm về 0")

	# ============ (d) Xung Kích: lướt + damage ============
	var slime2: Node = _spawn_slime(Vector2(1080, 1000))
	await get_tree().process_frame
	player.global_position = Vector2(1000, 1000)
	player.set("facing", Vector2.RIGHT)
	player.set("stamina", 100.0)
	slime2.global_position = Vector2(1080, 1000)
	var hp2_before: int = int(slime2.get("hp"))
	var base_dmg2: int = int(player.call("effective_damage", 0))
	var expected_dash: int = int(round(float(base_dmg2) * 1.1))
	_check(bool(player.call("_use_skill", "xung_kich")), "Xung Kích chạy khi đã mở khoá")
	var moved: float = player.global_position.distance_to(Vector2(1000, 1000))
	_check(moved >= 140.0 and player.global_position.x > 1100.0,
		"(d) Xung Kích lướt ~160px theo hướng nhìn (đi được %.0fpx -> %s)" % [moved, str(player.global_position)])
	_check(int(slime2.get("hp")) == hp2_before - expected_dash,
		"(d) Xung Kích gây %d damage (110%%) lên quái trên đường — HP %d -> %d" % [
			expected_dash, hp2_before, int(slime2.get("hp"))])
	_check(is_equal_approx(float(player.get("stamina")), 80.0),
		"Xung Kích tốn 20 STA (còn %.0f)" % float(player.get("stamina")))
	slime2.queue_free()
	await get_tree().process_frame

	# ============ (e) Cuồng Nộ: buff tốc đánh + damage ============
	var cd_before: float = float(player.call("get_effective_attack_cooldown"))
	var dmg_before: int = int(player.call("effective_damage", 0))
	_check(bool(player.call("_use_skill", "cuong_no")), "Cuồng Nộ chạy khi đã mở khoá")
	_check(bool(player.call("is_cuong_no_active")) and float(player.get("cuong_no_timer")) > 9.0,
		"(e) Cuồng Nộ bật: buff timer ~10s (%.1f)" % float(player.get("cuong_no_timer")))
	var cd_after: float = float(player.call("get_effective_attack_cooldown"))
	_check(cd_after < cd_before and is_equal_approx(cd_after, cd_before / 1.25),
		"(e) Tốc đánh +25%%: cooldown %.3f -> %.3f" % [cd_before, cd_after])
	var dmg_after: int = int(player.call("effective_damage", 0))
	_check(dmg_after == int(round(float(dmg_before) * 1.2)) and dmg_after > dmg_before,
		"(e) Damage +20%% khi Cuồng Nộ: %d -> %d" % [dmg_before, dmg_after])
	_check(float(player.call("get_skill_cooldown", "cuong_no")) > 40.0,
		"Cooldown Cuồng Nộ ~45s (%.1f)" % float(player.call("get_skill_cooldown", "cuong_no")))

	# ============ Panel cây skill + HUD ============
	var panel: Node = load("res://ui/skill_panel.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	var summary: String = str(panel.call("build_summary_text"))
	_check(summary.contains("CHIẾN BINH") and summary.contains("Đã học"),
		"Panel: build_summary_text có nhánh Chiến binh + trạng thái Đã học")
	_check(summary.contains("CHIẾN ĐẤU PHÁP SƯ: Chưa mở (cần xong Phần 3)") and summary.contains("mảnh phong ấn"),
		"Panel: nhánh Pháp Sư chưa mở (cần xong Phần 3) + ghi chú mảnh phong ấn")
	panel.call("show_panel")
	_check(bool(panel.get("visible")) and GameState.in_dialogue,
		"Panel: show_panel -> hiện + in_dialogue = true (khoá player)")
	panel.call("hide_panel")
	_check(not bool(panel.get("visible")) and not GameState.in_dialogue,
		"Panel: hide_panel -> ẩn + in_dialogue = false")
	panel.queue_free()

	var hud: Node = load("res://ui/hud.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	await get_tree().process_frame
	var skill_label: Label = hud.get_node("MarginContainer/VBoxContainer/SkillLabel")
	_check(skill_label != null and skill_label.text.contains("Chém Xoáy"),
		"HUD: SkillLabel hiển thị skill + điểm ('%s')" % (skill_label.text if skill_label else ""))
	_check(hud.get_node_or_null("SkillBoxContainer") != null,
		"HUD: có 3 ô skill góc dưới (SkillBoxContainer)")
	_check(hud.get_node_or_null("SkillPanel") != null or hud.find_child("SkillPanel") != null,
		"HUD: chứa SkillPanel (mở bằng phím T)")

	player.queue_free()
	_restore_existing_save()
	print("[SKILLTEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)


func _backup_existing_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			_save_backup = f.get_as_text()
			_had_save = true
			f.close()


func _restore_existing_save() -> void:
	GameState.in_dialogue = false
	if _had_save:
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(_save_backup)
			f.close()
	else:
		SaveSystem.delete_save()
