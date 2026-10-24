extends Node
## Test logic toàn tuyến Phần 3 Vùng Tây Solmaris qua API (headless):
##   godot --headless --path game res://tests/part3_chain_test.tscn
## Chuỗi: gate nam_giai_phong -> tay_01 -> tay_02 -> tay_03a -> tay_03b
##   -> tay_04 -> tay_05 (Kassia) -> tay_06 (vào hang) -> chọn tay_07b
##   ĐÀM PHÁN (khoá tay_07a) -> flags hậu quả + tay_giai_phong + seal key tay
##   + signal part3_completed. Cộng kiểm NPC sống trên 4 map Solmaris.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []
var _part3_signal_seen := false


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[PART3TEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[PART3TEST] FAIL: ", label)


func _on_part3_signal() -> void:
	_part3_signal_seen = true


func _status(qid: String) -> String:
	return str(QuestManager.get_quest(qid).get("status", ""))


func _kill(qid: String, type: String, count: int) -> void:
	for i in count:
		QuestManager.on_enemy_killed(type)
	_check(_status(qid) == "ready_turn_in", "%s đủ tiến độ -> ready_turn_in" % qid)


func _ready() -> void:
	print("[PART3TEST] Bắt đầu test toàn tuyến Phần 3 Solmaris.")
	if not GameState.part3_completed.is_connected(_on_part3_signal):
		GameState.part3_completed.connect(_on_part3_signal)
	GameState.reset_game()
	QuestManager.reset_quests()
	_part3_signal_seen = false
	_check(GameState.flags.is_empty(), "Reset: flags rỗng")

	for qid in ["tay_01_den_solmaris", "tay_02_nuoc_oc_dao", "tay_03a_dieu_cat",
			"tay_03b_da_vang", "tay_04_lien_minh", "tay_05_dau_truong",
			"tay_06_gap_vesskar", "tay_07a_danh_vesskar", "tay_07b_dam_phan_vesskar",
			"tay_side_vulture", "tay_side_bones"]:
		_check(not QuestManager.get_quest(qid).is_empty(), "Quest %s tồn tại" % qid)

	# Gate: chưa xong Phần 2 thì chưa nhận được quest đầu vùng Tây
	_check(not QuestManager.accept_quest("tay_01_den_solmaris"),
		"Chặn tay_01 khi chưa có flag nam_giai_phong")
	_check(not QuestManager.accept_quest("tay_02_nuoc_oc_dao"),
		"Chặn tay_02 khi chưa xong tay_01")
	GameState.set_flag("nam_giai_phong")
	_check(GameState.get_flag("nam_giai_phong"), "Đã set flag nam_giai_phong (điều kiện vào vùng)")

	# tay_01: 4 Bọ Cạp Cát
	_check(QuestManager.accept_quest("tay_01_den_solmaris"), "Nhận tay_01 sau khi xong Phần 2")
	_kill("tay_01_den_solmaris", "sand_scorpion", 4)
	_check(QuestManager.turn_in_quest("tay_01_den_solmaris"), "Trả tay_01 tại Hướng Dẫn Caravan")
	_check(_status("tay_01_den_solmaris") == "completed", "tay_01 completed")

	# tay_02: 4 Rắn Cát giữ nước
	_check(QuestManager.accept_quest("tay_02_nuoc_oc_dao"), "Nhận tay_02")
	_kill("tay_02_nuoc_oc_dao", "sand_snake", 4)
	_check(QuestManager.turn_in_quest("tay_02_nuoc_oc_dao"), "Trả tay_02 tại Người Giữ Nước")
	_check(GameState.get_flag("oc_dao_on_dinh"), "Flag oc_dao_on_dinh")

	# tay_03a: điều kiện Dunehawk — 5 lính đánh thuê
	_check(QuestManager.accept_quest("tay_03a_dieu_cat"), "Nhận tay_03a (điều kiện Diều Cát)")
	_kill("tay_03a_dieu_cat", "mercenary", 5)
	_check(QuestManager.turn_in_quest("tay_03a_dieu_cat"), "Trả tay_03a tại Thủ Lĩnh Diều Cát")
	_check(GameState.get_flag("dieu_cat_dong_y"), "Flag dieu_cat_dong_y")

	# tay_03b: điều kiện Stonesong — vào Buried Sand Ruins
	_check(QuestManager.accept_quest("tay_03b_da_vang"), "Nhận tay_03b (điều kiện Đá Vang)")
	QuestManager.on_map_entered("buried_sand_ruins")
	_check(_status("tay_03b_da_vang") == "ready_turn_in", "tay_03b vào ruins -> ready_turn_in")
	_check(QuestManager.turn_in_quest("tay_03b_da_vang"), "Trả tay_03b tại Pháp Sư Đá Vang")
	_check(GameState.get_flag("da_vang_dong_y"), "Flag da_vang_dong_y")
	_check(GameState.get_flag("co_bang_chung_loi_the"), "Flag co_bang_chung_loi_the")

	# tay_04: lập liên minh (complete_on_accept -> ready_turn_in)
	_check(QuestManager.accept_quest("tay_04_lien_minh"), "Nhận tay_04 (dựng liên minh)")
	_check(_status("tay_04_lien_minh") == "ready_turn_in", "tay_04 complete_on_accept -> ready_turn_in")
	_check(QuestManager.turn_in_quest("tay_04_lien_minh"), "Trả tay_04 tại Trưởng Liên Minh")
	_check(GameState.get_flag("lien_minh_bo_lac"), "Flag lien_minh_bo_lac")

	# tay_05: đấu trường Kassia Vane
	_check(QuestManager.accept_quest("tay_05_dau_truong"), "Nhận tay_05 (đấu trường)")
	_kill("tay_05_dau_truong", "boss_mercenary_captain", 1)
	_check(QuestManager.turn_in_quest("tay_05_dau_truong"), "Trả tay_05 tại Chủ Đấu Trường")
	_check(GameState.get_flag("thang_dau_truong"), "Flag thang_dau_truong")
	_check(GameState.get_flag("hoi_dong_suy_yeu"), "Flag hoi_dong_suy_yeu")

	# tay_06: vào hang — không cần turn-in, hoàn thành ngay khi đủ tiến độ
	_check(QuestManager.accept_quest("tay_06_gap_vesskar"), "Nhận tay_06 (vào hang Vesskar)")
	QuestManager.on_map_entered("vesskar_lair")
	_check(_status("tay_06_gap_vesskar") == "completed", "tay_06 vào hang -> completed (không turn-in)")
	_check(GameState.get_flag("da_gap_vesskar"), "Flag da_gap_vesskar")

	# Lựa chọn cuối: ĐÀM PHÁN (07b) -> 07a bị khoá
	_check(QuestManager.accept_quest("tay_07b_dam_phan_vesskar"), "Chọn tay_07b (đàm phán với Vesskar)")
	_check(_status("tay_07a_danh_vesskar") == "locked", "tay_07a bị khoá sau khi chọn đàm phán")
	_check(not QuestManager.accept_quest("tay_07a_danh_vesskar"), "Không nhận được tay_07a đã khoá")
	_check(_status("tay_07b_dam_phan_vesskar") == "ready_turn_in", "tay_07b complete_on_accept -> ready_turn_in")
	_check(QuestManager.turn_in_quest("tay_07b_dam_phan_vesskar"), "Trả tay_07b tại Trưởng Liên Minh")
	_check(GameState.get_flag("tay_end_dam_phan"), "Flag kết phần tay_end_dam_phan")
	_check(GameState.get_flag("vesskar_dam_phan"), "Flag vesskar_dam_phan (boss chuyển hòa bình)")
	_check(GameState.get_flag("vesskar_song"), "Flag hậu quả vesskar_song")
	_check(GameState.get_flag("loi_the_co_duoc_tra"), "Flag loi_the_co_duoc_tra")
	_check(GameState.get_flag("tay_giai_phong"), "Flag tay_giai_phong")
	_check(bool(GameState.seal_keys.get("tay", false)), "Seal key vùng Tây (Chìa Vảy Cát) đã nhận")
	_check(_part3_signal_seen, "Signal part3_completed đã phát")
	_check(GameState.get_reputation("tay") > 0, "Uy tín vùng Tây > 0 (%d)" % GameState.get_reputation("tay"))

	# NPC sống trên map thật vùng Tây
	_check_npc_schedule("res://maps/sunwell_oasis.tscn",
		["huong_dao_oc_dao", "nguoi_giu_nuoc", "truong_lien_minh", "thuong_nhan_oc_dao", "linh_thue_oc_dao"])
	_check_npc_schedule("res://maps/dunehawk_camp.tscn",
		["thu_linh_dieu_cat", "ke_chuyen_dieu_cat"])
	_check_npc_schedule("res://maps/stonesong_camp.tscn",
		["phap_su_da_vang", "ke_chuyen_da_vang"])
	_check_npc_schedule("res://maps/redrock_canyon.tscn", ["chu_dau_truong"])

	print("[PART3TEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
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
