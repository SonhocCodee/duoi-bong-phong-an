extends Node
## Test logic toàn tuyến KẾT GAME — Sigilspire (đợt 6) qua API (headless):
##   godot --headless --path game res://tests/part5_chain_test.tscn
## Chuỗi: gate 4 seal key -> thap_01 (vào sảnh) -> thap_02 (Sử Ấn) ->
##   thap_03 (Seraphine, flag seraphine_truth) -> thap_04 (boss cuối)
##   -> CẢ 3 ENDING qua FinalEndingPanel.choose_ending: chốt quest +
##   game_completed + ending_id + epilogue nhắc hậu quả từng vùng theo
##   flags thật (Nam mất người / Tây Vesskar chết / Bắc vất vưởng...).
## Cộng kiểm NPC/SealAltar/portal khoá trên các map tháp thật.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[PART5TEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[PART5TEST] FAIL: ", label)


func _status(qid: String) -> String:
	return str(QuestManager.get_quest(qid).get("status", ""))


## Reset + chạy nhanh chuỗi thap_01..04 tới trạng thái đứng trước Bệ.
func _run_to_altar() -> void:
	GameState.reset_game()
	QuestManager.reset_quests()
	GameState.set_flag("bac_giai_phong")
	QuestManager.accept_quest("thap_01_co_bon_chia")
	QuestManager.on_map_entered("sigilspire_base")
	QuestManager.accept_quest("thap_02_tang_su_an")
	QuestManager.on_map_entered("sigilspire_f5")
	QuestManager.turn_in_quest("thap_02_tang_su_an")
	QuestManager.accept_quest("thap_03_seraphine")
	QuestManager.turn_in_quest("thap_03_seraphine")
	QuestManager.accept_quest("thap_04_vua_dinh_thap")
	QuestManager.on_enemy_killed("boss_puppet_king")


func _collect_npcs(node: Node, out: Dictionary) -> void:
	var nid := str(node.get("npc_id")) if node.get("npc_id") != null else ""
	if nid != "":
		out[nid] = node
	for child in node.get_children():
		_collect_npcs(child, out)


func _find_node_named(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found: Node = _find_node_named(child, target)
		if found != null:
			return found
	return null


func _ready() -> void:
	print("[PART5TEST] Bắt đầu test toàn tuyến kết game Sigilspire.")

	# --- Tồn tại quest ---
	GameState.reset_game()
	QuestManager.reset_quests()
	for qid in ["thap_01_co_bon_chia", "thap_02_tang_su_an", "thap_03_seraphine",
			"thap_04_vua_dinh_thap", "thap_05a_phong_an_moi", "thap_05b_pha_an",
			"thap_05c_thay_the"]:
		_check(not QuestManager.get_quest(qid).is_empty(), "Quest %s tồn tại" % qid)

	# --- Gate 4 seal key ---
	_check(not bool(GameState.flags.get("sigilspire_open", false)),
		"Chưa có chìa nào: sigilspire_open = false")
	GameState.add_seal_key("dong")
	GameState.add_seal_key("nam")
	GameState.add_seal_key("tay")
	_check(not GameState.has_all_seal_keys(), "3/4 chìa: chưa đủ")
	_check(not bool(GameState.flags.get("sigilspire_open", false)),
		"3/4 chìa: cổng tháp vẫn khóa")
	GameState.add_seal_key("bac")
	_check(GameState.has_all_seal_keys(), "Đủ 4/4 chìa phong ấn")
	_check(bool(GameState.flags.get("sigilspire_open", false)),
		"Chìa thứ 4: flag sigilspire_open bật — cổng tháp mở")

	# --- Gate quest đầu tháp ---
	_check(not QuestManager.accept_quest("thap_01_co_bon_chia"),
		"Chặn thap_01 khi chưa giải phóng Bắc (chưa có bac_giai_phong)")
	GameState.set_flag("bac_giai_phong")

	# --- Chuỗi thap_01 -> 04 (kiểm từng bước) ---
	_check(QuestManager.accept_quest("thap_01_co_bon_chia"), "Nhận thap_01 Cổng Bốn Chìa")
	QuestManager.on_map_entered("sigilspire_base")
	_check(_status("thap_01_co_bon_chia") == "completed", "Vào sảnh chân tháp: thap_01 completed")
	_check(GameState.get_flag("da_vao_thap"), "Flag da_vao_thap")

	_check(QuestManager.accept_quest("thap_02_tang_su_an"), "Nhận thap_02 Tầng Sử Ấn")
	QuestManager.on_map_entered("sigilspire_f5")
	_check(_status("thap_02_tang_su_an") == "ready_turn_in", "Tới Tầng 5: thap_02 ready_turn_in")
	_check(QuestManager.turn_in_quest("thap_02_tang_su_an"), "Trả thap_02 tại Người Ghi Ấn")
	_check(GameState.get_flag("biet_su_an"), "Flag biet_su_an")

	_check(QuestManager.accept_quest("thap_03_seraphine"), "Nhận thap_03 Seraphine")
	_check(_status("thap_03_seraphine") == "ready_turn_in",
		"thap_03 complete_on_accept: nhận là ready_turn_in")
	_check(QuestManager.turn_in_quest("thap_03_seraphine"), "Trả thap_03 tại Seraphine")
	_check(GameState.get_flag("seraphine_truth"),
		"TWIST đã vào game: flag seraphine_truth (cô là vật phong ấn sống)")

	_check(QuestManager.accept_quest("thap_04_vua_dinh_thap"), "Nhận thap_04 Vua Trên Đỉnh")
	QuestManager.on_enemy_killed("boss_puppet_king")
	_check(_status("thap_04_vua_dinh_thap") == "completed", "Hạ boss cuối: thap_04 completed")
	_check(GameState.get_flag("final_boss_dead"), "Flag final_boss_dead")
	_check(not GameState.game_completed, "Chưa chọn ending: game chưa chốt hoàn thành")

	# === ENDING A — Phong Ấn Mới (hậu quả: Nam mất người, Vesskar sống, Bắc siêu thoát) ===
	GameState.set_flag("tram_thue_pha")
	GameState.set_flag("nam_thuoc_tre")
	GameState.set_flag("nam_mat_nguoi")
	GameState.set_flag("vesskar_song")
	GameState.set_flag("linh_hon_sieu_thoat")
	var panel_a: Node = load("res://ui/final_ending_panel.tscn").instantiate()
	add_child(panel_a)
	await get_tree().process_frame
	_check(bool(panel_a.call("choose_ending", "ending_phong_an_moi")), "Chọn được Ending A")
	_check(_status("thap_05a_phong_an_moi") == "completed", "thap_05a completed")
	_check(GameState.game_completed, "Ending A: game_completed = true")
	_check(GameState.ending_id == "ending_phong_an_moi", "Ending A: ending_id đúng")
	_check(not QuestManager.accept_quest("thap_05b_pha_an"), "Đã chọn A: thap_05b bị khoá")
	_check(not QuestManager.accept_quest("thap_05c_thay_the"), "Đã chọn A: thap_05c bị khoá")
	_check(not bool(panel_a.call("choose_ending", "ending_pha_an")), "Không chọn lại ending lần 2")
	var epi_a: String = str(panel_a.call("build_epilogue_text"))
	_check(epi_a.contains("Seraphine ở lại trong tháp"), "Epilogue A: Seraphine ở lại làm neo theo thỏa thuận mới")
	_check(epi_a.contains("không qua khỏi"), "Epilogue A nhắc hậu quả Nam: mất người vì thuốc cắt đột ngột")
	_check(epi_a.contains("Vesskar còn sống"), "Epilogue A nhắc hậu quả Tây: Vesskar còn sống")
	_check(epi_a.contains("siêu thoát"), "Epilogue A nhắc hậu quả Bắc: linh hồn siêu thoát")
	_check(epi_a.contains("Trạm thuế Stonebridge"), "Epilogue A nhắc hậu quả Đông: trạm thuế sập")
	panel_a.queue_free()

	# === ENDING B — Phá Ấn (hậu quả: Vesskar chết, Bắc vất vưởng, Nam nghèo đi) ===
	_run_to_altar()
	_check(GameState.get_flag("final_boss_dead"), "Chạy nhanh lần 2: tới được Bệ Phong Ấn")
	GameState.set_flag("vesskar_chet")
	GameState.set_flag("linh_hon_van_vat")
	GameState.set_flag("nam_ngheo_di")
	var panel_b: Node = load("res://ui/final_ending_panel.tscn").instantiate()
	add_child(panel_b)
	await get_tree().process_frame
	_check(bool(panel_b.call("choose_ending", "ending_pha_an")), "Chọn được Ending B")
	_check(GameState.game_completed and GameState.ending_id == "ending_pha_an",
		"Ending B: game_completed + ending_id đúng")
	var epi_b: String = str(panel_b.call("build_epilogue_text"))
	_check(epi_b.contains("bước ra khỏi Tầng 6"), "Epilogue B: Seraphine được giải thoát")
	_check(epi_b.contains("mất kiểm soát"), "Epilogue B nhắc hậu quả Tây: Vesskar chết, bão cát mất kiểm soát")
	_check(epi_b.contains("vất vưởng"), "Epilogue B nhắc hậu quả Bắc: linh hồn vất vưởng")
	_check(epi_b.contains("nghèo đi rõ rệt"), "Epilogue B nhắc hậu quả Nam: nghèo đi")
	panel_b.queue_free()

	# === ENDING C — Thay Thế + save/load giữ trạng thái hoàn thành ===
	_run_to_altar()
	var panel_c: Node = load("res://ui/final_ending_panel.tscn").instantiate()
	add_child(panel_c)
	await get_tree().process_frame
	_check(bool(panel_c.call("choose_ending", "ending_thay_the")), "Chọn được Ending C")
	var epi_c: String = str(panel_c.call("build_epilogue_text"))
	_check(epi_c.contains("vị trí neo ấn"), "Epilogue C: người chơi thay Seraphine làm neo ấn")
	_check(GameState.game_completed and GameState.ending_id == "ending_thay_the",
		"Ending C: game_completed + ending_id đúng")
	panel_c.queue_free()
	var d: Dictionary = GameState.to_dict()
	GameState.reset_game()
	_check(not GameState.game_completed, "Reset: game_completed về false")
	GameState.from_dict(d)
	_check(GameState.game_completed and GameState.ending_id == "ending_thay_the",
		"Save/load roundtrip giữ trạng thái hoàn thành + ending")

	# --- Chưa hạ boss cuối thì Bệ không cho chọn ---
	GameState.reset_game()
	QuestManager.reset_quests()
	var panel_x: Node = load("res://ui/final_ending_panel.tscn").instantiate()
	add_child(panel_x)
	await get_tree().process_frame
	_check(not bool(panel_x.call("choose_ending", "ending_pha_an")),
		"Chưa có final_boss_dead: choose_ending bị chặn")
	panel_x.queue_free()

	# --- Kiểm map/NPC/Bệ thật ---
	_check_tower_maps()

	print("[PART5TEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)


func _check_tower_maps() -> void:
	# Đất Chết: portal vào tháp khoá bằng sigilspire_open
	var ps_dc: PackedScene = load("res://maps/dat_chet.tscn")
	_check(ps_dc != null, "Load được dat_chet.tscn")
	if ps_dc != null:
		var m_dc: Node = ps_dc.instantiate()
		var portal_tower: Node = _find_node_named(m_dc, "PortalTower")
		_check(portal_tower != null, "Đất Chết có PortalTower")
		if portal_tower != null:
			_check(str(portal_tower.get("required_flag")) == "sigilspire_open",
				"PortalTower khoá bằng flag sigilspire_open (đủ 4 chìa mới qua)")
		m_dc.free()
	# Tầng 5: Người Ghi Ấn giữ thap_02
	var ps5: PackedScene = load("res://maps/sigilspire_f5.tscn")
	_check(ps5 != null, "Load được sigilspire_f5.tscn")
	if ps5 != null:
		var m5: Node = ps5.instantiate()
		var npcs5 := {}
		_collect_npcs(m5, npcs5)
		_check(npcs5.has("nguoi_ghi_an"), "Tầng 5 có NPC nguoi_ghi_an")
		if npcs5.has("nguoi_ghi_an"):
			var q5: Array = npcs5["nguoi_ghi_an"].get("quest_ids")
			_check(q5.has("thap_02_tang_su_an"), "nguoi_ghi_an giữ quest thap_02")
		m5.free()
	# Tầng 6: Seraphine giữ thap_03
	var ps6: PackedScene = load("res://maps/sigilspire_f6.tscn")
	_check(ps6 != null, "Load được sigilspire_f6.tscn")
	if ps6 != null:
		var m6: Node = ps6.instantiate()
		var npcs6 := {}
		_collect_npcs(m6, npcs6)
		_check(npcs6.has("seraphine"), "Tầng 6 có NPC seraphine (Công chúa)")
		if npcs6.has("seraphine"):
			var q6: Array = npcs6["seraphine"].get("quest_ids")
			_check(q6.has("thap_03_seraphine"), "seraphine giữ quest thap_03")
		m6.free()
	# Đỉnh: NPC vua + boss cuối + Bệ Phong Ấn
	var pss: PackedScene = load("res://maps/sigilspire_summit.tscn")
	_check(pss != null, "Load được sigilspire_summit.tscn")
	if pss != null:
		var ms: Node = pss.instantiate()
		var npcss := {}
		_collect_npcs(ms, npcss)
		_check(npcss.has("vua_dinh_thap"), "Đỉnh tháp có NPC vua_dinh_thap")
		if npcss.has("vua_dinh_thap"):
			var qs: Array = npcss["vua_dinh_thap"].get("quest_ids")
			_check(qs.has("thap_04_vua_dinh_thap"), "vua_dinh_thap giữ quest thap_04")
		_check(_find_node_named(ms, "SealAltar") != null, "Đỉnh tháp có Bệ Phong Ấn (SealAltar)")
		var boss_found := false
		_check_boss_type(ms, "boss_puppet_king", boss_found)
		ms.free()


func _check_boss_type(node: Node, enemy_type: String, _found: bool) -> void:
	# Quét đệ quy tìm node có enemy_type khớp (boss cuối trên đỉnh).
	var stack: Array = [node]
	var ok := false
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.get("enemy_type") != null and str(n.get("enemy_type")) == enemy_type:
			ok = true
			break
		for child in n.get_children():
			stack.append(child)
	_check(ok, "Đỉnh tháp có boss cuối enemy_type = %s" % enemy_type)
