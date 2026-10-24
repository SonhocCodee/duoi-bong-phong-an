extends Node
## Test logic toàn tuyến Phần 2 Vùng Nam Fenmire qua API (headless):
##   godot --headless --path game res://tests/part2_chain_test.tscn
## Chuỗi: nam_01 -> nam_02 -> lựa chọn thuốc (02a/b/c loại trừ nhau)
##   -> lựa chọn vườn nấm (03a/b loại trừ nhau) -> nam_04 -> nam_05 (boss)
##   -> lựa chọn cuối phần (06a/b/c) -> flag nam_giai_phong + seal key nam
##   + signal part2_completed. Cộng kiểm NPC Reedmere/Fevercamp có lịch trình.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []
var _part2_signal_seen := false


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[PART2TEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[PART2TEST] FAIL: ", label)


func _on_part2_signal() -> void:
	_part2_signal_seen = true


func _status(qid: String) -> String:
	return str(QuestManager.get_quest(qid).get("status", ""))


func _kill(qid: String, type: String, count: int) -> void:
	for i in count:
		QuestManager.on_enemy_killed(type)
	_check(_status(qid) == "ready_turn_in", "%s đủ tiến độ -> ready_turn_in" % qid)


func _ready() -> void:
	print("[PART2TEST] Bắt đầu test toàn tuyến Phần 2 Fenmire.")
	if not GameState.part2_completed.is_connected(_on_part2_signal):
		GameState.part2_completed.connect(_on_part2_signal)
	GameState.reset_game()
	QuestManager.reset_quests()
	_part2_signal_seen = false
	_check(GameState.flags.is_empty(), "Reset: flags rỗng")
	# Dữ liệu quest Nam tồn tại
	for qid in ["nam_01_den_fenmire", "nam_02_danh_sach_thuoc", "nam_02a_thuoc_tre",
			"nam_02b_thuoc_gia", "nam_02c_thuoc_nuoi_nha", "nam_03a_pha_vuon",
			"nam_03b_ghi_chung_cu", "nam_04_duong_thuy", "nam_05_den_chim_trieu",
			"nam_06a_giu_thoa_thuan", "nam_06b_giu_trieu_moi", "nam_06c_pha_chu_ky",
			"nam_side_herb", "nam_side_croc"]:
		_check(not QuestManager.get_quest(qid).is_empty(), "Quest %s tồn tại" % qid)
	# Gating: nhận sớm phải bị chặn
	_check(not QuestManager.accept_quest("nam_02_danh_sach_thuoc"), "Chặn nam_02 khi chưa xong nam_01")
	_check(not QuestManager.accept_quest("nam_03a_pha_vuon"), "Chặn nam_03a khi chưa có cờ da_chon_thuoc")
	_check(not QuestManager.accept_quest("nam_06a_giu_thoa_thuan"), "Chặn nam_06a khi chưa xong nam_05")
	# nam_01: diệt 3 mire_leech
	_check(QuestManager.accept_quest("nam_01_den_fenmire"), "Nhận nam_01")
	_kill("nam_01_den_fenmire", "mire_leech", 3)
	_check(QuestManager.turn_in_quest("nam_01_den_fenmire"), "Trả nam_01")
	_check(_status("nam_01_den_fenmire") == "completed", "nam_01 completed")
	# nam_02: thu 3 herb
	_check(QuestManager.accept_quest("nam_02_danh_sach_thuoc"), "Nhận nam_02")
	for i in 3:
		QuestManager.on_item_collected("herb")
	_check(_status("nam_02_danh_sach_thuoc") == "ready_turn_in", "nam_02 đủ herb -> ready_turn_in")
	_check(QuestManager.turn_in_quest("nam_02_danh_sach_thuoc"), "Trả nam_02")
	_check(GameState.get_flag("co_so_thuoc"), "Flag co_so_thuoc đã đặt")
	# Lựa chọn thuốc: chọn 02a -> 02b/02c bị khoá
	_check(QuestManager.accept_quest("nam_02a_thuoc_tre"), "Chọn nam_02a (thuốc cho trẻ)")
	_check(_status("nam_02a_thuoc_tre") == "ready_turn_in", "nam_02a complete_on_accept -> ready_turn_in")
	_check(_status("nam_02b_thuoc_gia") == "locked", "nam_02b bị khoá sau khi chọn 02a")
	_check(_status("nam_02c_thuoc_nuoi_nha") == "locked", "nam_02c bị khoá sau khi chọn 02a")
	_check(not QuestManager.accept_quest("nam_02b_thuoc_gia"), "Không nhận được nam_02b đã khoá")
	_check(QuestManager.turn_in_quest("nam_02a_thuoc_tre"), "Trả nam_02a")
	_check(GameState.get_flag("nam_thuoc_tre"), "Flag nam_thuoc_tre (ghi sổ lựa chọn)")
	_check(GameState.get_flag("da_chon_thuoc"), "Flag da_chon_thuoc mở khoá chặng sau")
	# Lựa chọn vườn nấm: chọn 03b (ghi chứng cứ) -> 03a khoá
	_check(QuestManager.accept_quest("nam_03b_ghi_chung_cu"), "Chọn nam_03b (ghi chứng cứ)")
	_check(_status("nam_03a_pha_vuon") == "locked", "nam_03a bị khoá sau khi chọn 03b")
	QuestManager.on_map_entered("venomfen")
	_check(_status("nam_03b_ghi_chung_cu") == "ready_turn_in", "nam_03b tới Venomfen -> ready_turn_in")
	_check(QuestManager.turn_in_quest("nam_03b_ghi_chung_cu"), "Trả nam_03b")
	_check(GameState.get_flag("ghi_chung_cu") and GameState.get_flag("co_chung_cu"), "Flags ghi_chung_cu + co_chung_cu")
	# nam_04: dọn đường thủy
	_check(QuestManager.accept_quest("nam_04_duong_thuy"), "Nhận nam_04")
	_kill("nam_04_duong_thuy", "mire_leech", 4)
	_check(QuestManager.turn_in_quest("nam_04_duong_thuy"), "Trả nam_04")
	_check(GameState.get_flag("mo_duong_thuy"), "Flag mo_duong_thuy (đường thủy mở)")
	_check(GameState.get_flag("chung_cu_c"), "Flag chung_cu_c (phiên bản Người Giữ Triều)")
	# nam_05: boss đền
	_check(QuestManager.accept_quest("nam_05_den_chim_trieu"), "Nhận nam_05")
	_kill("nam_05_den_chim_trieu", "boss_high_priest", 1)
	_check(QuestManager.turn_in_quest("nam_05_den_chim_trieu"), "Trả nam_05")
	_check(GameState.get_flag("qua_den"), "Flag qua_den")
	# Lựa chọn cuối phần: chọn 06b (giữ triều mới)
	_check(QuestManager.accept_quest("nam_06b_giu_trieu_moi"), "Chọn nam_06b (giữ triều mới)")
	_check(_status("nam_06a_giu_thoa_thuan") == "locked", "nam_06a bị khoá")
	_check(_status("nam_06c_pha_chu_ky") == "locked", "nam_06c bị khoá")
	_check(QuestManager.turn_in_quest("nam_06b_giu_trieu_moi"), "Trả nam_06b")
	_check(GameState.get_flag("nam_end_giu_trieu_moi"), "Flag kết phần: nam_end_giu_trieu_moi")
	_check(GameState.get_flag("nam_mat_nguoi"), "Flag hậu quả: nam_mat_nguoi (ghi sổ epilogue)")
	_check(GameState.get_flag("nam_giai_phong"), "Flag nam_giai_phong")
	_check(bool(GameState.seal_keys.get("nam", false)), "Seal key vùng Nam đã nhận")
	_check(_part2_signal_seen, "Signal part2_completed đã phát")
	_check(GameState.get_reputation("nam") > 0, "Uy tín vùng Nam > 0 (%d)" % GameState.get_reputation("nam"))
	# NPC sống ở map thật vùng Nam
	_check_npc_schedule("res://maps/reedmere.tscn",
		["truong_reedmere", "dan_say_1", "tre_reedmere"])
	_check_npc_schedule("res://maps/fevercamp.tscn",
		["y_si_tram", "benh_nhan_1", "me_goa"])
	_check_npc_schedule("res://maps/blackmere.tscn",
		["truong_dan_chai_ho", "dan_chai_ho_1", "lai_pha_ho"])
	print("[PART2TEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)


func _check_npc_schedule(map_path: String, npc_ids: Array) -> void:
	var ps: PackedScene = load(map_path)
	_check(ps != null, "Load được map %s" % map_path.get_file())
	if ps == null:
		return
	var map: Node = ps.instantiate()
	var found := {}
	_collect_npcs(map, found)
	for nid in npc_ids:
		_check(found.has(nid), "Map %s có NPC %s" % [map_path.get_file(), nid])
		if found.has(nid):
			var npc: Node = found[nid]
			_check(bool(npc.get("schedule_enabled")) == true,
				"NPC %s schedule_enabled == true" % nid)
			var sched: Array = npc.get("schedule")
			_check(sched.size() >= 3, "NPC %s có >= 3 bước lịch trình (%d)" % [nid, sched.size()])
	map.free()


func _collect_npcs(node: Node, out: Dictionary) -> void:
	var nid := str(node.get("npc_id")) if node.get("npc_id") != null else ""
	if nid != "":
		out[nid] = node
	for child in node.get_children():
		_collect_npcs(child, out)
