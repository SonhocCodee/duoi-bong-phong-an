extends Node
## Test tự động cho gói "KHỞI ĐẦU ĐÚNG THIẾT KẾ" (chạy headless):
##   godot --headless --path game res://tests/start_state_test.tscn
## Kiểm chứng:
##   1) Ngoại hình: player khởi đầu ÁO VẢI (player_cloth_frames); nhận
##      vũ khí thuần ATK vẫn áo vải; nhận/mặc GIÁP đầu tiên (slot armor)
##      -> chuyển bộ GIÁP (player_frames); bỏ giáp (load state không
##      giáp) -> về áo vải; save/load giữ đúng ngoại hình; di trú save
##      cũ (chỉ có DEF trần + cờ crafted_giap_da_bong) -> hiện giáp.
##   2) HUD skill: lúc mới vào game, ô skill nhánh chưa mở (Thuật Đen)
##      TRỐNG TRƠN (không tên, không khoá, khung trung tính); ô nhánh
##      Chiến binh (mở từ đầu) hiện tên + khoá; mở cờ nam_giai_phong
##      thì ô Thuật Đen lộ diện; học skill thì ô hiện sẵn sàng.
##   3) Mở đầu chơi được: scene Elmford có spawn ở CỔNG NAM (y lớn,
##      phía nam làng) trùng vị trí Player; có NPC gác cổng "gac_cong"
##      với set_flag_on_dialogue_end = "opening_gate_done"; thoại của
##      ông có 3 đoạn; hết thoại -> cờ được đặt; OpeningOverlay đi từ
##      giai đoạn 1 -> 2; player KHÔNG còn tự nhận dong_01 khi spawn;
##      skip_opening() đặt intro_seen; nhận dong_01 -> mở đầu kết thúc.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[STARTTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[STARTTEST] FAIL: ", label)


func _frames_path(p: Node) -> String:
	var spr: AnimatedSprite2D = p.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null or spr.sprite_frames == null:
		return ""
	return spr.sprite_frames.resource_path


func _ready() -> void:
	print("[STARTTEST] Bắt đầu test khởi đầu đúng thiết kế.")
	GameState.reset_game()
	QuestManager.reset_quests()
	await get_tree().process_frame

	# ============ 1) NGOẠI HÌNH ÁO VẢI -> GIÁP ============
	var player: Node = load("res://player/player.tscn").instantiate()
	add_child(player)
	await get_tree().process_frame
	_check(_frames_path(player).ends_with("player_cloth_frames.tres"),
		"Khởi đầu: player mặc ÁO VẢI (thấy %s)" % _frames_path(player))
	_check(not GameState.has_armor_visual, "Khởi đầu: has_armor_visual = false")

	# Vũ khí thuần ATK (rương Kiếm Sắt Cũ) -> vẫn áo vải
	GameState.add_equipment("Kiếm Sắt Cũ", 3, 0)
	await get_tree().process_frame
	_check(_frames_path(player).ends_with("player_cloth_frames.tres"),
		"Nhận kiếm thuần ATK: vẫn ÁO VẢI")
	_check(GameState.get_equipped_item("armor").is_empty(),
		"Kiếm Sắt Cũ vào slot weapon, slot armor vẫn trống")

	# Giáp rơi từ quái (Áo Da Cứng, slot armor) -> chuyển GIÁP
	GameState.add_equipment("Áo Da Cứng", 0, 2)
	await get_tree().process_frame
	_check(GameState.has_armor_visual, "Nhận Áo Da Cứng: has_armor_visual = true")
	_check(_frames_path(player).ends_with("player_frames.tres"),
		"Nhận giáp đầu tiên: player chuyển bộ GIÁP (thấy %s)" % _frames_path(player))

	# Save/load giữ ngoại hình giáp
	var saved: Dictionary = GameState.to_dict()
	GameState.reset_game()
	await get_tree().process_frame
	_check(_frames_path(player).ends_with("player_cloth_frames.tres"),
		"Reset: player về ÁO VẢI")
	GameState.from_dict(saved)
	await get_tree().process_frame
	_check(GameState.has_armor_visual, "Load save có giáp: has_armor_visual = true")
	_check(_frames_path(player).ends_with("player_frames.tres"),
		"Load save có giáp: player hiện GIÁP")

	# Chế Giáp Da Bóng (đường craft thật) cũng bật giáp từ trạng thái vải
	GameState.reset_game()
	GameState.add_material("monster_core", 4)
	GameState.add_material("herb", 2)
	GameState.add_gold(100)
	_check(GameState.craft("giap_da_bong"), "Chế được Giáp Da Bóng")
	await get_tree().process_frame
	_check(GameState.has_armor_visual and _frames_path(player).ends_with("player_frames.tres"),
		"Chế Giáp Da Bóng: player chuyển GIÁP")

	# Di trú save CŨ (bản xương: không khóa equipment, chỉ DEF trần + cờ)
	var old_save: Dictionary = {
		"player_hp": 100, "player_max_hp": 100, "gold": 0, "xp": 0, "level": 1,
		"attack_bonus": 0, "defense_bonus": 4,
		"flags": {"crafted_giap_da_bong": true},
	}
	GameState.reset_game()
	GameState.from_dict(old_save)
	await get_tree().process_frame
	_check(GameState.defense_bonus == 4, "Save cũ: DEF giữ nguyên 4 sau di trú (thấy %d)" % GameState.defense_bonus)
	_check(GameState.has_armor_visual, "Save cũ có giáp: di trú -> has_armor_visual = true")
	_check(_frames_path(player).ends_with("player_frames.tres"),
		"Save cũ có giáp: player hiện GIÁP sau load")
	player.queue_free()
	await get_tree().process_frame

	# ============ 2) HUD: Ô SKILL TRỐNG LÚC KHỞI ĐẦU ============
	GameState.reset_game()
	QuestManager.reset_quests()
	var hud: Node = load("res://ui/hud.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	hud.call("_refresh_skill_ui")
	var name_labels: Dictionary = hud.get("_skill_box_name_labels")
	var box_labels: Dictionary = hud.get("_skill_box_labels")
	_check(str((name_labels["dau_an_lua"] as Label).text) == "" and str((box_labels["dau_an_lua"] as Label).text) == "",
		"HUD khởi đầu: ô Dấu Ấn Lửa (nhánh Thuật Đen chưa mở) TRỐNG TRƠN")
	_check(str((name_labels["cau_lua"] as Label).text) == "" and str((box_labels["cau_lua"] as Label).text) == "",
		"HUD khởi đầu: ô Cầu Lửa (nhánh Pháp Sư chưa mở) TRỐNG TRƠN")
	_check(str((name_labels["chem_xoay"] as Label).text) != "" and str((box_labels["chem_xoay"] as Label).text) == "🔒",
		"HUD khởi đầu: ô Chém Xoáy (nhánh Chiến binh mở từ đầu) hiện tên + khoá")
	# Mở nhánh Thuật Đen (xong Phần 2) -> ô lộ diện, vẫn khoá vì chưa học
	GameState.set_flag("nam_giai_phong")
	hud.call("_refresh_skill_ui")
	_check(str((name_labels["dau_an_lua"] as Label).text) != "" and str((box_labels["dau_an_lua"] as Label).text) == "🔒",
		"HUD sau Phần 2: ô Dấu Ấn Lửa lộ diện (tên + khoá)")
	# Học skill -> ô hiện sẵn sàng
	GameState.level = 7
	GameState.add_skill_points(1)
	_check(GameState.try_unlock_skill("dau_an_lua"), "Học được Dấu Ấn Lửa (đủ điều kiện)")
	hud.call("_refresh_skill_ui")
	_check(str((box_labels["dau_an_lua"] as Label).text) == "✓",
		"HUD sau khi học: ô Dấu Ấn Lửa hiện ✓ sẵn sàng")
	hud.queue_free()
	await get_tree().process_frame

	# ============ 3) MỞ ĐẦU CHƠI ĐƯỢC Ở ELMFORD ============
	GameState.reset_game()
	QuestManager.reset_quests()
	var map: Node = load("res://maps/lang_tan_diep.tscn").instantiate()
	add_child(map)
	await get_tree().process_frame
	await get_tree().process_frame
	var mplayer: Node2D = map.get_node("Player") as Node2D
	var spawn: Node2D = map.get_node("Spawn_start") as Node2D
	_check(mplayer.global_position == spawn.global_position,
		"Elmford: Player khởi đầu đúng tại Spawn_start (%s)" % str(spawn.global_position))
	_check(spawn.global_position.y > 1000.0,
		"Elmford: spawn ở CỔNG NAM (y = %.0f, nửa nam của làng)" % spawn.global_position.y)
	_check(_frames_path(mplayer).ends_with("player_cloth_frames.tres"),
		"Elmford: player vừa vào làng mặc ÁO VẢI")
	_check(str(QuestManager.get_quest("dong_01_goblin").get("status", "")) == "available",
		"Elmford: dong_01 CHƯA tự nhận khi spawn (status = available)")

	var gate: Node = map.get_node_or_null("NPC_GacCong")
	_check(gate != null, "Elmford: có NPC gác cổng NPC_GacCong")
	if gate != null:
		_check(str(gate.get("npc_id")) == "gac_cong", "Gác cổng: npc_id = gac_cong")
		_check(str(gate.get("set_flag_on_dialogue_end")) == "opening_gate_done",
			"Gác cổng: set_flag_on_dialogue_end = opening_gate_done")
		var lines: Array = gate.get("dialogue_done")
		_check(lines.size() == 3, "Gác cổng: thoại mở đầu có 3 đoạn (thấy %d)" % lines.size())
		_check((gate as Node2D).global_position.distance_to(mplayer.global_position) < 90.0,
			"Gác cổng: đứng ngay cạnh điểm spawn ở cổng nam")

	var overlay: Node = map.get_node("OpeningOverlay")
	_check(int(overlay.get("opening_stage")) == 1,
		"Opening: giai đoạn 1 (chờ gặp gác cổng) khi mới vào (thấy %d)" % int(overlay.get("opening_stage")))
	_check(bool(overlay.call("is_opening_active")), "Opening: đang chạy lúc mới vào game")
	# Hết thoại với gác cổng -> npc.gd đặt cờ -> overlay sang giai đoạn 2
	if gate != null:
		gate.call("_end_conversation")
		_check(GameState.get_flag("opening_gate_done"), "Hết thoại gác cổng: cờ opening_gate_done được đặt")
		await get_tree().create_timer(0.4).timeout
		_check(int(overlay.get("opening_stage")) == 2,
			"Opening: sang giai đoạn 2 (tới nhà Trưởng làng) sau thoại cổng (thấy %d)" % int(overlay.get("opening_stage")))
	# Trưởng làng giao dong_01 (đúng cơ chế accept của QuestManager)
	_check(QuestManager.accept_quest("dong_01_goblin"), "Nhận dong_01_goblin từ Trưởng làng")
	await get_tree().create_timer(0.4).timeout
	_check(int(overlay.get("opening_stage")) == 0 and GameState.get_flag("intro_seen"),
		"Opening: kết thúc + intro_seen sau khi nhận dong_01")
	map.queue_free()
	await get_tree().process_frame

	# --- Đường bỏ qua (Esc) trên một phiên mới ---
	GameState.reset_game()
	QuestManager.reset_quests()
	var map2: Node = load("res://maps/lang_tan_diep.tscn").instantiate()
	add_child(map2)
	await get_tree().process_frame
	await get_tree().process_frame
	var overlay2: Node = map2.get_node("OpeningOverlay")
	_check(int(overlay2.get("opening_stage")) == 1, "Opening (phiên 2): lại ở giai đoạn 1")
	overlay2.call("skip_opening")
	_check(int(overlay2.get("opening_stage")) == 0 and GameState.get_flag("intro_seen")
		and GameState.get_flag("opening_gate_done"),
		"Bỏ qua mở đầu: intro_seen + opening_gate_done đều đặt, giai đoạn = 0")
	_check(str(QuestManager.get_quest("dong_01_goblin").get("status", "")) == "available",
		"Bỏ qua mở đầu: dong_01 vẫn available để nhận ở Trưởng làng như bản cũ")
	map2.queue_free()
	await get_tree().process_frame

	print("[STARTTEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
