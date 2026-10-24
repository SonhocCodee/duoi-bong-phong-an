extends Node
## Test logic toàn tuyến Phần 4 Vùng Bắc Frostgard qua API (headless):
##   godot --headless --path game res://tests/part4_chain_test.tscn
## Chuỗi: gate tay_giai_phong -> bac_01 -> bac_02 (herb) -> bac_03 (wight)
##   -> bac_04 (vào legion_crypt) -> bac_05 (frost_knight) -> bac_06 (Vharok)
##   -> chọn bac_07a GIẢI THOÁT (khoá bac_07b) -> flags hậu quả +
##   bac_giai_phong + seal key bac + signal part4_completed.
## Cộng kiểm NPC sống trên hearthwick và vua_bac_bang ở approach.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []
var _part4_signal_seen := false


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[PART4TEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[PART4TEST] FAIL: ", label)


func _on_part4_signal() -> void:
	_part4_signal_seen = true


func _status(qid: String) -> String:
	return str(QuestManager.get_quest(qid).get("status", ""))


func _kill(qid: String, type: String, count: int) -> void:
	for i in count:
		QuestManager.on_enemy_killed(type)
	_check(_status(qid) == "ready_turn_in", "%s đủ tiến độ -> ready_turn_in" % qid)


func _ready() -> void:
	print("[PART4TEST] Bắt đầu test toàn tuyến Phần 4 Frostgard.")
	if not GameState.part4_completed.is_connected(_on_part4_signal):
		GameState.part4_completed.connect(_on_part4_signal)
	GameState.reset_game()
	QuestManager.reset_quests()
	_part4_signal_seen = false
	_check(GameState.flags.is_empty(), "Reset: flags rỗng")

	for qid in ["bac_01_den_phuong_bac", "bac_02_lo_suoi", "bac_03_giu_tuong_dem",
			"bac_04_ten_doi_truong", "bac_05_tram_gac_ma", "bac_06_ke_giu_nguyen",
			"bac_07a_giai_thoat", "bac_07b_pha_vua",
			"bac_side_hunt", "bac_side_wraith"]:
		_check(not QuestManager.get_quest(qid).is_empty(), "Quest %s tồn tại" % qid)

	# Gate: chưa xong Phần 3 thì chưa nhận được quest đầu vùng Bắc
	_check(not QuestManager.accept_quest("bac_01_den_phuong_bac"),
		"Chặn bac_01 khi chưa có flag tay_giai_phong")
	_check(not QuestManager.accept_quest("bac_02_lo_suoi"),
		"Chặn bac_02 khi chưa xong bac_01")
	GameState.set_flag("tay_giai_phong")
	_check(GameState.get_flag("tay_giai_phong"), "Đã set flag tay_giai_phong (điều kiện vào vùng)")

	# bac_01: 4 Sói Tuyết
	_check(QuestManager.accept_quest("bac_01_den_phuong_bac"), "Nhận bac_01 sau khi xong Phần 3")
	_kill("bac_01_den_phuong_bac", "snow_wolf", 4)
	_check(QuestManager.turn_in_quest("bac_01_den_phuong_bac"), "Trả bac_01 tại Trưởng Làng Lò Sưởi")
	_check(_status("bac_01_den_phuong_bac") == "completed", "bac_01 completed")
	_check(GameState.get_flag("da_den_bac"), "Flag da_den_bac")

	# bac_02: thu 4 thảo lửa (herb)
	_check(QuestManager.accept_quest("bac_02_lo_suoi"), "Nhận bac_02")
	for i in 4:
		QuestManager.on_item_collected("herb")
	_check(_status("bac_02_lo_suoi") == "ready_turn_in", "bac_02 thu đủ herb -> ready_turn_in")
	_check(QuestManager.turn_in_quest("bac_02_lo_suoi"), "Trả bac_02 tại Chủ Lò Sưởi")
	_check(GameState.get_flag("lo_suoi_khong_tat"), "Flag lo_suoi_khong_tat")

	# bac_03: giữ tường đêm — 5 Wight
	_check(QuestManager.accept_quest("bac_03_giu_tuong_dem"), "Nhận bac_03")
	_kill("bac_03_giu_tuong_dem", "wight", 5)
	_check(QuestManager.turn_in_quest("bac_03_giu_tuong_dem"), "Trả bac_03 tại Đội Trưởng Gác Làng")
	_check(GameState.get_flag("da_giu_tuong_dem"), "Flag da_giu_tuong_dem")

	# bac_04: vào Legion Crypt đọc bia 5 đội trưởng
	_check(QuestManager.accept_quest("bac_04_ten_doi_truong"), "Nhận bac_04")
	QuestManager.on_map_entered("legion_crypt")
	_check(_status("bac_04_ten_doi_truong") == "ready_turn_in", "bac_04 vào crypt -> ready_turn_in")
	_check(QuestManager.turn_in_quest("bac_04_ten_doi_truong"), "Trả bac_04 tại Bà Góa Giữ Danh Sách")
	_check(GameState.get_flag("thu_ten_doi_truong"), "Flag thu_ten_doi_truong")
	_check(GameState.get_flag("du_ten_doi_truong"), "Flag du_ten_doi_truong (điều kiện nghi lễ)")

	# bac_05: trạm gác ma — 4 Hiệp Sĩ Băng
	_check(QuestManager.accept_quest("bac_05_tram_gac_ma"), "Nhận bac_05")
	_kill("bac_05_tram_gac_ma", "frost_knight", 4)
	_check(QuestManager.turn_in_quest("bac_05_tram_gac_ma"), "Trả bac_05 tại Bà Góa Giữ Danh Sách")
	_check(GameState.get_flag("tram_gac_da_sach"), "Flag tram_gac_da_sach")

	# bac_06: hạ Vharok, Kẻ Giữ Nguyền
	_check(QuestManager.accept_quest("bac_06_ke_giu_nguyen"), "Nhận bac_06")
	_kill("bac_06_ke_giu_nguyen", "boss_curse_warden", 1)
	_check(QuestManager.turn_in_quest("bac_06_ke_giu_nguyen"), "Trả bac_06 tại Vua Băng Bị Nguyền")
	_check(GameState.get_flag("nguyen_da_vo"), "Flag nguyen_da_vo")

	# Lựa chọn cuối: GIẢI THOÁT (07a) -> 07b bị khoá
	_check(QuestManager.accept_quest("bac_07a_giai_thoat"), "Chọn bac_07a (nghi lễ giải thoát)")
	_check(_status("bac_07b_pha_vua") == "locked", "bac_07b bị khoá sau khi chọn giải thoát")
	_check(not QuestManager.accept_quest("bac_07b_pha_vua"), "Không nhận được bac_07b đã khoá")
	_check(_status("bac_07a_giai_thoat") == "ready_turn_in", "bac_07a complete_on_accept -> ready_turn_in")
	_check(QuestManager.turn_in_quest("bac_07a_giai_thoat"), "Trả bac_07a tại Vua Băng Bị Nguyền")
	_check(GameState.get_flag("bac_end_giai_thoat"), "Flag kết phần bac_end_giai_thoat")
	_check(GameState.get_flag("linh_hon_sieu_thoat"), "Flag hậu quả linh_hon_sieu_thoat")
	_check(GameState.get_flag("vua_cam_on"), "Flag vua_cam_on")
	_check(GameState.get_flag("bac_giai_phong"), "Flag bac_giai_phong")
	_check(bool(GameState.seal_keys.get("bac", false)), "Seal key vùng Bắc (Chìa Sắt Băng) đã nhận")
	_check(_part4_signal_seen, "Signal part4_completed đã phát")
	_check(GameState.get_reputation("bac") > 0, "Uy tín vùng Bắc > 0 (%d)" % GameState.get_reputation("bac"))

	# NPC sống trên map thật vùng Bắc
	_check_npc_schedule("res://maps/hearthwick.tscn",
		["truong_lang_lo_suoi", "chu_lo_suoi", "ba_goa_giu_ten", "doi_truong_gac_lang", "tho_san_dau_dan"])
	_check_king_npc()

	print("[PART4TEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
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


func _check_king_npc() -> void:
	var ps: PackedScene = load("res://maps/frostgard_approach.tscn")
	_check(ps != null, "Load được map frostgard_approach.tscn")
	if ps == null:
		return
	var map: Node = ps.instantiate()
	var found := {}
	_collect_npcs(map, found)
	_check(found.has("vua_bac_bang"), "Frostgard Approach có NPC vua_bac_bang")
	if found.has("vua_bac_bang"):
		var king: Node = found["vua_bac_bang"]
		var qids: Array = king.get("quest_ids")
		_check(qids.has("bac_07a_giai_thoat"), "vua_bac_bang quest_ids chứa bac_07a_giai_thoat")
		_check(qids.has("bac_06_ke_giu_nguyen"), "vua_bac_bang quest_ids chứa bac_06_ke_giu_nguyen")
	map.free()


func _collect_npcs(node: Node, out: Dictionary) -> void:
	var nid := str(node.get("npc_id")) if node.get("npc_id") != null else ""
	if nid != "":
		out[nid] = node
	for child in node.get_children():
		_collect_npcs(child, out)
