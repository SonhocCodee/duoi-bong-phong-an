extends Node
## Test logic toàn tuyến Phần 1 Vùng Đông qua API (headless):
##   godot --headless --path game res://tests/part1_chain_test.tscn
## Thứ tự MỚI: 01 -> 02 -> 03 -> 05 -> 06 -> 04 -> 08 -> 07
## Kiểm tra: gating từng bước (nhận sớm = false), flags sau từng mốc
## (tram_thue_pha, co_duong_cong, da_dot_nhap, dong_giai_phong),
## signal part1_completed khi dong_07 complete, completed_quests đủ 8 main.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []
var _part1_signal_seen := false


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[PART1TEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[PART1TEST] FAIL: ", label)


func _on_part1_signal() -> void:
	_part1_signal_seen = true


func _status(qid: String) -> String:
	return str(QuestManager.get_quest(qid).get("status", ""))


func _finish_kill_quest(qid: String, type: String, count: int) -> void:
	_check(QuestManager.accept_quest(qid), "Nhận quest %s" % qid)
	for i in count:
		QuestManager.on_enemy_killed(type)
	var q: Dictionary = QuestManager.get_quest(qid)
	if bool(q.get("requires_turn_in", false)):
		_check(_status(qid) == "ready_turn_in", "%s đủ tiến độ -> ready_turn_in" % qid)
		_check(QuestManager.turn_in_quest(qid), "Trả quest %s tại NPC %s" % [qid, str(q.get("turn_in_npc", ""))])
	_check(_status(qid) == "completed", "Quest %s -> completed" % qid)


func _ready() -> void:
	print("[PART1TEST] Bắt đầu test toàn tuyến Phần 1.")
	if has_node("/root/GameState"):
		if not GameState.part1_completed.is_connected(_on_part1_signal):
			GameState.part1_completed.connect(_on_part1_signal)
	# Reset sạch
	GameState.reset_game()
	QuestManager.reset_quests()
	_part1_signal_seen = false
	_check(GameState.flags.is_empty(), "Reset: flags rỗng")
	_check(QuestManager.completed_quests.is_empty() and QuestManager.active_quests.is_empty(),
		"Reset: không còn quest active/completed")
	# Dữ liệu quest mới tồn tại
	_check(not QuestManager.get_quest("dong_08_cong_ngam").is_empty(), "Quest dong_08_cong_ngam tồn tại")
	_check(str(QuestManager.get_quest("dong_08_cong_ngam").get("target_map", "")) == "hoang_cung",
		"dong_08 target_map = hoang_cung")
	_check(str(QuestManager.get_quest("dong_04_golem").get("required_quest", "")) == "dong_06_giai_phu",
		"dong_04 required_quest = dong_06_giai_phu")
	_check(str(QuestManager.get_quest("dong_07_vua").get("required_quest", "")) == "dong_08_cong_ngam",
		"dong_07 required_quest = dong_08_cong_ngam")
	_check(str(QuestManager.get_quest("dong_04_golem").get("description", "")).contains("Moss Den"),
		"dong_04 description nhắc Moss Den")

	# --- Gating sớm: chưa xong 01 thì không nhận được các quest sau ---
	_check(not QuestManager.accept_quest("dong_02_ham_ruou"), "Gating: dong_02 sớm == false")
	_check(not QuestManager.accept_quest("dong_03_chuot_chua"), "Gating: dong_03 sớm == false")
	_check(not QuestManager.accept_quest("dong_05_tram_thue"), "Gating: dong_05 sớm == false")
	_check(not QuestManager.accept_quest("dong_06_giai_phu"), "Gating: dong_06 sớm == false")
	_check(not QuestManager.accept_quest("dong_04_golem"), "Gating: dong_04 sớm == false (cần dong_06)")
	_check(not QuestManager.accept_quest("dong_08_cong_ngam"), "Gating: dong_08 sớm == false (cần dong_04)")
	_check(not QuestManager.accept_quest("dong_07_vua"), "Gating: dong_07 sớm == false (cần dong_08)")

	# --- 01, 02, 03: mở đầu ---
	_finish_kill_quest("dong_01_goblin", "goblin", 3)
	_check(not QuestManager.accept_quest("dong_05_tram_thue"), "Gating sau 01: dong_05 vẫn false (cần dong_03)")
	_finish_kill_quest("dong_02_ham_ruou", "rat", 5)
	_finish_kill_quest("dong_03_chuot_chua", "boss_rat_king", 1)
	_check(GameState.get_flag("mo_dau_xong"), "Xong dong_03 -> flag mo_dau_xong = true")

	# --- Gating dong_04 sau 03 (thứ tự cũ) phải vẫn false ---
	_check(not QuestManager.accept_quest("dong_04_golem"),
		"Gating: accept dong_04_golem == false khi dong_06 chưa xong")

	# --- 05 Stonebridge ---
	_finish_kill_quest("dong_05_tram_thue", "soldier", 3)
	_check(GameState.get_flag("tram_thue_pha"), "Xong dong_05 -> flag tram_thue_pha = true")
	_check(not QuestManager.accept_quest("dong_04_golem"), "Gating sau 05: dong_04 vẫn false (cần dong_06)")

	# --- 06 Bluestone Mine ---
	_finish_kill_quest("dong_06_giai_phu", "bandit", 4)
	_check(GameState.get_flag("co_duong_cong"), "Xong dong_06 -> flag co_duong_cong = true")

	# --- 04 Mossback ---
	_finish_kill_quest("dong_04_golem", "boss_golem", 1)

	# --- Gating dong_07 trước dong_08 ---
	_check(not QuestManager.accept_quest("dong_07_vua"),
		"Gating: accept dong_07_vua == false khi dong_08 chưa xong")

	# --- 08 Sewers -> Palace qua on_map_entered ---
	_check(QuestManager.accept_quest("dong_08_cong_ngam"), "Nhận quest dong_08_cong_ngam")
	QuestManager.on_map_entered("cong_ngam")
	_check(_status("dong_08_cong_ngam") == "active",
		"dong_08 vẫn active sau khi vào cong_ngam (chưa tới hoang_cung)")
	_check(not GameState.get_flag("da_dot_nhap"), "Chưa tới hoang_cung: flag da_dot_nhap vẫn false")
	QuestManager.on_map_entered("hoang_cung")
	_check(_status("dong_08_cong_ngam") == "completed", "dong_08 -> completed sau on_map_entered(hoang_cung)")
	_check(GameState.get_flag("da_dot_nhap"), "Xong dong_08 -> flag da_dot_nhap = true")
	_check(not _part1_signal_seen, "Chưa xong dong_07: signal part1_completed chưa phát")

	# --- 07 King Aldric ---
	_check(QuestManager.accept_quest("dong_07_vua"), "Nhận quest dong_07_vua")
	QuestManager.on_enemy_killed("boss_vua")
	_check(_status("dong_07_vua") == "completed", "dong_07 -> completed sau khi hạ boss_vua")
	_check(GameState.get_flag("dong_giai_phong"), "Xong dong_07 -> flag dong_giai_phong = true")
	_check(_part1_signal_seen, "Signal part1_completed đã phát khi dong_07 complete")
	_check(GameState.get_flag("tram_thue_pha") and GameState.get_flag("co_duong_cong")
		and GameState.get_flag("da_dot_nhap") and GameState.get_flag("dong_giai_phong"),
		"Đủ 4 flags mốc: tram_thue_pha/co_duong_cong/da_dot_nhap/dong_giai_phong")

	# --- Completed đủ 8 main quest ---
	var mains: Array[String] = ["dong_01_goblin", "dong_02_ham_ruou", "dong_03_chuot_chua",
		"dong_05_tram_thue", "dong_06_giai_phu", "dong_04_golem", "dong_08_cong_ngam", "dong_07_vua"]
	var ok_count := 0
	for qid in mains:
		if QuestManager.completed_quests.has(qid):
			ok_count += 1
	_check(ok_count == 8, "completed_quests đủ 8 main quest (thấy %d/8)" % ok_count)
	_check(QuestManager.completed_quests.size() >= 8,
		"completed_quests size >= 8 (thấy %d)" % QuestManager.completed_quests.size())

	print("[PART1TEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
