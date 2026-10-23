extends Node
## Test tự động cho hệ thống GĐ1 (chạy headless):
##   godot --headless --path game res://tests/systems_test.tscn
## Kịch bản: nhận dong_01 -> giết 3 goblin -> ready_turn_in (chưa có thưởng)
## -> trả quest -> +20 vàng, +5 rep -> nhận được dong_02 (required đã xong)
## -> nhặt herb đủ 4 -> ready_turn_in -> mua bình ở shop -> dùng bình
## -> save/load round-trip giữ potions / seal_keys / flags / spawn / map.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []
var _had_save: bool = false
var _save_backup: String = ""

const SAVE_PATH: String = "user://save.json"


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[SYSTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[SYSTEST] FAIL: ", label)


func _ready() -> void:
	print("[SYSTEST] Bắt đầu test hệ thống GĐ1.")
	_backup_existing_save()

	# --- Scene mới load được ---
	_check(load("res://systems/npc.tscn") != null, "Load được systems/npc.tscn")
	_check(load("res://systems/portal.tscn") != null, "Load được systems/portal.tscn")
	_check(load("res://systems/herb_pickup.tscn") != null, "Load được systems/herb_pickup.tscn")
	_check(load("res://ui/dialogue_box.tscn") != null, "Load được ui/dialogue_box.tscn")
	_check(load("res://ui/shop_panel.tscn") != null, "Load được ui/shop_panel.tscn")

	# --- Trạng thái ban đầu ---
	_check(GameState.potions == 3, "Potions khởi tạo = 3 (thấy %d)" % GameState.potions)
	_check(not GameState.has_all_seal_keys(), "Chưa có seal key nào lúc đầu")

	# --- required_quest: chưa xong dong_01 thì không nhận được dong_02 ---
	_check(not QuestManager.accept_quest("dong_02_ham_ruou"),
		"Chưa xong dong_01 -> không nhận được dong_02_ham_ruou")

	# --- dong_01: giết 3 goblin -> ready_turn_in, chưa phát thưởng ---
	_check(QuestManager.accept_quest("dong_01_goblin"), "Nhận dong_01_goblin")
	var gold0: int = GameState.gold
	var rep0: int = GameState.get_reputation("dong")
	for i in 3:
		QuestManager.on_enemy_killed("goblin")
	var q1: Dictionary = QuestManager.get_quest("dong_01_goblin")
	_check(str(q1.get("status", "")) == "ready_turn_in",
		"dong_01 đủ 3 goblin -> ready_turn_in (thấy: %s)" % str(q1.get("status", "")))
	_check(GameState.gold == gold0, "Chưa trả quest -> vàng chưa tăng")
	_check(not QuestManager.turn_in_quest("dong_02_ham_ruou"),
		"turn_in_quest cho quest chưa ready -> false")

	# --- Trả quest tại NPC -> mới phát thưởng ---
	_check(QuestManager.turn_in_quest("dong_01_goblin"), "Trả dong_01_goblin thành công")
	_check(GameState.gold == gold0 + 20, "Trả quest: vàng +20 (thấy %d)" % GameState.gold)
	_check(GameState.get_reputation("dong") == rep0 + 5, "Trả quest: rep dong +5 (thấy %d)" % GameState.get_reputation("dong"))
	_check(str(QuestManager.get_quest("dong_01_goblin").get("status", "")) == "completed",
		"dong_01 -> completed sau khi trả")

	# --- required_quest đã xong -> nhận được dong_02, generic target_type rat ---
	_check(QuestManager.accept_quest("dong_02_ham_ruou"), "Đã xong dong_01 -> nhận được dong_02_ham_ruou")
	QuestManager.on_enemy_killed("rat")
	_check(int(QuestManager.get_quest("dong_02_ham_ruou").get("progress", 0)) == 1,
		"on_enemy_killed('rat') -> dong_02 progress = 1 (generic target_type)")
	QuestManager.on_enemy_killed("slime") # không quest active nào cần slime lúc này
	_check(int(QuestManager.get_quest("dong_02_ham_ruou").get("progress", 0)) == 1,
		"Giết slime không cộng nhầm progress dong_02")

	# --- Collect quest: nhặt 4 herb -> ready_turn_in -> trả -> +15 vàng ---
	_check(QuestManager.accept_quest("dong_side_herb"), "Nhận dong_side_herb")
	for i in 4:
		QuestManager.on_item_collected("herb")
	_check(str(QuestManager.get_quest("dong_side_herb").get("status", "")) == "ready_turn_in",
		"Nhặt 4 herb -> dong_side_herb ready_turn_in")
	var gold1: int = GameState.gold
	_check(QuestManager.turn_in_quest("dong_side_herb"), "Trả dong_side_herb thành công")
	_check(GameState.gold == gold1 + 15, "Trả side herb: vàng +15 (thấy %d)" % GameState.gold)

	# --- Shop: mua bình máu bằng vàng qua ShopPanel thật ---
	var shop: CanvasLayer = load("res://ui/shop_panel.tscn").instantiate()
	add_child(shop)
	var gold2: int = GameState.gold
	var pot2: int = GameState.potions
	_check(shop.buy_potion(), "Shop: mua bình máu thành công")
	_check(GameState.gold == gold2 - 10, "Shop: trừ đúng 10 vàng (thấy %d)" % GameState.gold)
	_check(GameState.potions == pot2 + 1, "Shop: potions +1 (thấy %d)" % GameState.potions)
	shop.close_shop()

	# --- Dùng bình qua GameState ---
	_check(GameState.use_potion(), "use_potion() khi còn bình -> true")
	_check(GameState.potions == pot2, "use_potion() trừ đúng 1 bình (thấy %d)" % GameState.potions)

	# --- Boss display + seal + flag ---
	GameState.set_boss_display("The Rat King", 50, 100)
	_check(GameState.boss_name == "The Rat King" and GameState.boss_hp == 50 and GameState.boss_max_hp == 100,
		"set_boss_display lưu đúng name/hp/max_hp")
	GameState.clear_boss_display()
	_check(GameState.boss_name == "" and GameState.boss_hp == 0, "clear_boss_display xoá hiển thị boss")
	GameState.add_seal_key("dong")
	_check(bool(GameState.seal_keys.get("dong", false)) and not GameState.has_all_seal_keys(),
		"add_seal_key('dong') -> có 1/4, chưa đủ bộ")
	GameState.set_flag("mo_cua_ham_ruou")
	_check(GameState.get_flag("mo_cua_ham_ruou") and not GameState.get_flag("flag_khong_co"),
		"set_flag/get_flag đúng")

	# --- Save / load round-trip ---
	GameState.add_potions(2) # potions thành giá trị phân biệt để kiểm chứng
	var potions_before: int = GameState.potions
	var gold_before: int = GameState.gold
	GameState.spawn_point = "ham_ruou_in"
	GameState.current_map = "res://maps/ham_ruou.tscn"
	_check(SaveSystem.save_game(), "save_game() thành công")
	# Xáo trộn trạng thái rồi load lại
	GameState.potions = 0
	GameState.gold = 0
	GameState.seal_keys = {"dong": false, "nam": false, "tay": false, "bac": false}
	GameState.flags = {}
	GameState.spawn_point = "start"
	GameState.current_map = ""
	_check(SaveSystem.load_game(), "load_game() thành công")
	_check(GameState.potions == potions_before, "Round-trip: potions giữ nguyên (%d)" % GameState.potions)
	_check(GameState.gold == gold_before, "Round-trip: gold giữ nguyên (%d)" % GameState.gold)
	_check(bool(GameState.seal_keys.get("dong", false)), "Round-trip: seal_keys['dong'] = true")
	_check(GameState.get_flag("mo_cua_ham_ruou"), "Round-trip: flags giữ nguyên")
	_check(GameState.spawn_point == "ham_ruou_in", "Round-trip: spawn_point giữ nguyên")
	_check(GameState.current_map == "res://maps/ham_ruou.tscn", "Round-trip: current_map giữ nguyên")
	_check(str(QuestManager.get_quest("dong_01_goblin").get("status", "")) == "completed",
		"Round-trip: trạng thái quest giữ nguyên")
	_check(int(QuestManager.get_quest("dong_02_ham_ruou").get("progress", 0)) == 1,
		"Round-trip: progress dong_02 giữ nguyên")

	# --- use_potion khi hết bình ---
	GameState.potions = 0
	_check(not GameState.use_potion() and GameState.potions == 0,
		"use_potion() khi hết bình -> false, không trừ âm")

	_restore_existing_save()
	print("[SYSTEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
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
