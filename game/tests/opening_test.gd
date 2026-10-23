extends Node
## Test tự động cho đoạn mở đầu (chạy headless):
##   godot --headless --path game res://tests/opening_test.tscn
## Kịch bản logic (không cần đi bộ):
##   reset sạch -> dong_01 (3 goblin) -> trả -> dong_02 (5 rat) -> trả
##   -> dong_03: instance Boss The Rat King thật, đánh chết -> ready_turn_in
##   -> trả -> flag mo_dau_xong = true, vàng/XP đúng tổng.
##   Thêm: cổng bị khóa ở mức flag trước khi xong; main menu load được,
##   nút Tiếp tục disabled khi không có save, has_save true sau save_game.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []
var _had_save: bool = false
var _save_backup: String = ""

const SAVE_PATH: String = "user://save.json"


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[OPENTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[OPENTEST] FAIL: ", label)


func _ready() -> void:
	print("[OPENTEST] Bắt đầu test đoạn mở đầu.")
	_backup_existing_save()
	# Dọn save để phần kiểm tra menu về sau xác định (khôi phục ở cuối).
	SaveSystem.delete_save()

	# --- Load được các scene mới ---
	_check(load("res://ui/main_menu.tscn") != null, "Load được ui/main_menu.tscn")
	_check(load("res://ui/opening_overlay.tscn") != null, "Load được ui/opening_overlay.tscn")
	_check(load("res://enemies/boss_rat_king.tscn") != null, "Load được enemies/boss_rat_king.tscn")
	_check(load("res://enemies/goblin.tscn") != null, "Load được enemies/goblin.tscn")

	# --- Reset -> trạng thái sạch ---
	GameState.reset_game()
	QuestManager.reset_quests()
	_check(GameState.gold == 0 and GameState.xp == 0 and GameState.level == 1,
		"Reset: gold/xp/level về 0/0/1 (thấy %d/%d/%d)" % [GameState.gold, GameState.xp, GameState.level])
	_check(GameState.potions == 3, "Reset: potions = 3 (thấy %d)" % GameState.potions)
	_check(GameState.flags.is_empty(), "Reset: flags rỗng")
	_check(not GameState.has_all_seal_keys(), "Reset: chưa có seal key nào")
	_check(GameState.spawn_point == "start" and GameState.current_map == "",
		"Reset: spawn_point='start', current_map rỗng")
	_check(QuestManager.active_quests.is_empty() and QuestManager.completed_quests.is_empty(),
		"Reset: không còn quest active/completed")
	_check(str(QuestManager.get_quest("dong_01_goblin").get("status", "")) == "available",
		"Reset: dong_01_goblin về available")
	_check(str(QuestManager.get_quest("dong_03_chuot_chua").get("set_flag", "")) == "mo_dau_xong",
		"dong_03_chuot_chua có set_flag = mo_dau_xong")

	# --- dong_01: 3 goblin -> ready -> trả tại Trưởng làng ---
	_check(QuestManager.accept_quest("dong_01_goblin"), "Nhận dong_01_goblin")
	for i in 3:
		QuestManager.on_enemy_killed("goblin")
	_check(str(QuestManager.get_quest("dong_01_goblin").get("status", "")) == "ready_turn_in",
		"dong_01 đủ 3 goblin -> ready_turn_in")
	var rep0: int = GameState.get_reputation("dong")
	_check(QuestManager.turn_in_quest("dong_01_goblin"), "Trả dong_01_goblin (NPC truong_lang)")
	_check(str(QuestManager.get_quest("dong_01_goblin").get("status", "")) == "completed",
		"dong_01 -> completed sau khi trả")
	_check(GameState.get_reputation("dong") == rep0 + 5,
		"dong_01: rep dong +5 (thấy %d)" % GameState.get_reputation("dong"))
	_check(GameState.gold == 20, "dong_01: vàng = 20 sau trả (thấy %d)" % GameState.gold)

	# --- Cổng vẫn khóa ở mức flag sau dong_01 ---
	_check(GameState.get_flag("mo_dau_xong") == false,
		"Sau dong_01: flag mo_dau_xong vẫn false (cổng Đông/Bắc còn khóa)")

	# --- dong_02: 5 rat -> ready -> trả ---
	_check(QuestManager.accept_quest("dong_02_ham_ruou"), "Nhận dong_02_ham_ruou")
	for i in 5:
		QuestManager.on_enemy_killed("rat")
	_check(str(QuestManager.get_quest("dong_02_ham_ruou").get("status", "")) == "ready_turn_in",
		"dong_02 đủ 5 rat -> ready_turn_in")
	_check(QuestManager.turn_in_quest("dong_02_ham_ruou"), "Trả dong_02_ham_ruou")
	_check(str(QuestManager.get_quest("dong_02_ham_ruou").get("status", "")) == "completed",
		"dong_02 -> completed sau khi trả")
	_check(GameState.gold == 55, "dong_01+02: vàng = 55 (20+35, thấy %d)" % GameState.gold)
	_check(GameState.get_flag("mo_dau_xong") == false,
		"Sau dong_02: flag mo_dau_xong vẫn false")

	# --- dong_03: giết Boss The Rat King thật ---
	_check(QuestManager.accept_quest("dong_03_chuot_chua"), "Nhận dong_03_chuot_chua")
	var boss: Node2D = load("res://enemies/boss_rat_king.tscn").instantiate()
	add_child(boss)
	await get_tree().process_frame
	_check(int(boss.get("hp")) == int(boss.get("max_hp")) and int(boss.get("max_hp")) == 220,
		"Boss The Rat King spawn với HP đầy 220 (thấy %d)" % int(boss.get("hp")))
	boss.take_damage(9999, boss.global_position + Vector2(10, 0))
	# _die() chạy đồng bộ tới await đầu tiên: state phải là DEAD (enum = 3)
	_check(int(boss.get("state")) == 3, "Boss -> DEAD sau đòn kết liễu (state=%d)" % int(boss.get("state")))
	await get_tree().create_timer(0.2).timeout
	_check(str(QuestManager.get_quest("dong_03_chuot_chua").get("status", "")) == "ready_turn_in",
		"Boss chết -> dong_03 ready_turn_in (requires_turn_in=true, chưa completed)")
	_check(GameState.gold == 135, "Boss rơi loot: vàng = 135 (55+80, thấy %d)" % GameState.gold)
	_check(GameState.get_flag("mo_dau_xong") == false,
		"Chưa trả dong_03: flag mo_dau_xong vẫn false")

	# --- Trả dong_03 -> mở khóa đoạn mở đầu + tổng thưởng 3 quest ---
	_check(QuestManager.turn_in_quest("dong_03_chuot_chua"), "Trả dong_03_chuot_chua")
	_check(str(QuestManager.get_quest("dong_03_chuot_chua").get("status", "")) == "completed",
		"dong_03 -> completed sau khi trả")
	_check(GameState.get_flag("mo_dau_xong") == true,
		"Sau khi trả dong_03: flag mo_dau_xong = true (cổng mở)")
	# Vàng tổng: quest 20+35+80 = 135 + loot boss 80 = 215
	_check(GameState.gold == 215, "Tổng vàng = 215 (quest 135 + loot boss 80, thấy %d)" % GameState.gold)
	# XP tổng: quest 30+50+120 = 200 + loot boss 120 = 320
	# 320 XP từ level 1: -100 lên L2 (còn 220), -150 lên L3 (còn 70)
	_check(GameState.level == 3 and GameState.xp == 70,
		"Tổng XP 320 -> level 3, xp dư 70 (thấy L%d xp %d)" % [GameState.level, GameState.xp])
	_check(GameState.get_reputation("dong") == 28,
		"Tổng rep dong = 28 (5+8+15, thấy %d)" % GameState.get_reputation("dong"))

	# --- Main menu: Tiếp tục disabled khi không có save ---
	_check(not SaveSystem.has_save(), "Menu: has_save false sau khi xóa save")
	var menu: Control = load("res://ui/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var cont_btn: Button = menu.get_node("CenterContainer/VBoxContainer/ContinueButton") as Button
	_check(cont_btn != null and cont_btn.disabled, "Menu: nút Tiếp tục disabled khi chưa có save")
	menu.queue_free()
	await get_tree().process_frame
	_check(SaveSystem.save_game(), "Menu: save_game() thành công")
	_check(SaveSystem.has_save(), "Menu: has_save true sau save_game()")
	var menu2: Control = load("res://ui/main_menu.tscn").instantiate()
	add_child(menu2)
	await get_tree().process_frame
	var cont_btn2: Button = menu2.get_node("CenterContainer/VBoxContainer/ContinueButton") as Button
	_check(cont_btn2 != null and not cont_btn2.disabled, "Menu: nút Tiếp tục bật khi đã có save")
	menu2.queue_free()

	_restore_existing_save()
	print("[OPENTEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)


func _backup_existing_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			_save_backup = f.get_as_text()
			_had_save = true
			f.close()


func _restore_existing_save() -> void:
	if _had_save:
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(_save_backup)
			f.close()
	else:
		SaveSystem.delete_save()
