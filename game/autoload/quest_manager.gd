extends Node
## QuestManager - Autoload quản lý nhiệm vụ
## Quest lưu dạng Dictionary: id, title, region, status, xp_reward, gold_reward...
## Field mở rộng (GĐ1): target_type (loại quái cần giết), collect_type (vật phẩm
## cần nhặt), requires_turn_in + turn_in_npc (đủ tiến độ thì phải quay lại NPC
## trả nhiệm vụ mới nhận thưởng), required_quest (quest phải completed trước).
## status: "available" | "active" | "ready_turn_in" | "completed"

signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_updated(quest_id: String)

var quests: Dictionary = {}
var active_quests: Array[String] = []
var completed_quests: Array[String] = []


func _ready() -> void:
	_register_starter_quests()


## Reset toàn bộ quest về trạng thái đăng ký ban đầu (dùng cho "Chơi mới").
func reset_quests() -> void:
	quests.clear()
	active_quests.clear()
	completed_quests.clear()
	_register_starter_quests()
	print("[QuestManager] Đã reset toàn bộ quest.")


func _register_starter_quests() -> void:
	# Bộ quest vùng Đông — Vertical Slice (Elmford + Elmford Cellar)
	_add_quest({
		"id": "dong_01_goblin",
		"quest_type": "main",
		"title": "Dẹp Goblin ở bìa rừng Elmford",
		"region": "dong",
		"description": "Tiêu diệt 3 goblin quấy phá làng Elmford, rồi báo lại Trưởng làng.",
		"target_type": "goblin",
		"target_count": 3,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_lang",
		"xp_reward": 30,
		"gold_reward": 20,
		"reputation_reward": 5,
		"status": "available",
	})
	_add_quest({
		"id": "dong_02_ham_ruou",
		"quest_type": "main",
		"title": "Chuột phá Elmford Cellar",
		"region": "dong",
		"description": "Xuống Elmford Cellar diệt 5 con chuột phá thùng rượu, rồi báo lại Chủ quán.",
		"required_quest": "dong_01_goblin",
		"target_type": "rat",
		"target_count": 5,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "chu_quan",
		"xp_reward": 50,
		"gold_reward": 35,
		"reputation_reward": 8,
		"status": "available",
	})
	_add_quest({
		"id": "dong_03_chuot_chua",
		"quest_type": "main",
		"title": "The Rat King dưới Elmford Cellar",
		"region": "dong",
		"description": "Tiêu diệt The Rat King ở đáy Elmford Cellar, rồi báo lại Chủ quán.",
		"required_quest": "dong_02_ham_ruou",
		"target_type": "boss_rat_king",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "chu_quan",
		"set_flag": "mo_dau_xong",
		"xp_reward": 120,
		"gold_reward": 80,
		"reputation_reward": 15,
		"status": "available",
	})
	_add_quest({
		"id": "dong_side_herb",
		"quest_type": "side",
		"title": "Thảo dược cho quán trọ",
		"region": "dong",
		"description": "Thu thập 4 thảo dược quanh làng cho Chủ quán nấu thuốc.",
		"collect_type": "herb",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "chu_quan",
		"xp_reward": 25,
		"gold_reward": 15,
		"reputation_reward": 3,
		"status": "available",
	})
	_add_quest({
		"id": "dong_side_slime",
		"quest_type": "side",
		"title": "Slime cỏ phá ruộng",
		"region": "dong",
		"description": "Diệt 5 slime cỏ phá ruộng ngoài làng, rồi báo lại Thợ rèn.",
		"target_type": "slime",
		"target_count": 5,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "tho_ren",
		"xp_reward": 40,
		"gold_reward": 25,
		"reputation_reward": 5,
		"status": "available",
	})


	_add_quest({
		"id": "dong_04_golem",
		"title": "Mossback, the Moss Golem",
		"region": "dong",
		"description": "Hạ Mossback, the Moss Golem trong hang dưới Cloudpeak, lấy lại bình yên cho thành.",
		"quest_type": "main",
		"target_type": "boss_golem",
		"target_count": 1,
		"progress": 0,
		"required_quest": "dong_03_chuot_chua",
		"requires_turn_in": true,
		"turn_in_npc": "linh_gac",
		"xp_reward": 200,
		"gold_reward": 100,
		"reputation_reward": 20,
		"status": "available",
	})
	_add_quest({
		"id": "dong_05_tram_thue",
		"title": "Phá trạm thuế Stonebridge",
		"region": "dong",
		"description": "Đánh đuổi 3 lính thuế của vua ở trạm thu thuế Stonebridge trên sông Clearwater.",
		"quest_type": "main",
		"target_type": "soldier",
		"target_count": 3,
		"progress": 0,
		"required_quest": "dong_03_chuot_chua",
		"requires_turn_in": true,
		"turn_in_npc": "truong_lang",
		"set_flag": "tram_thue_pha",
		"xp_reward": 150,
		"gold_reward": 80,
		"reputation_reward": 15,
		"status": "available",
	})
	_add_quest({
		"id": "dong_06_giai_phu",
		"title": "Giải phóng phu Bluestone Mine",
		"region": "dong",
		"description": "Đánh đuổi 4 tên đốc công sơn tặc ở Bluestone Mine để giải phóng phu mỏ bị bắt.",
		"quest_type": "main",
		"target_type": "bandit",
		"target_count": 4,
		"progress": 0,
		"required_quest": "dong_05_tram_thue",
		"requires_turn_in": true,
		"turn_in_npc": "dan_tandiep_1",
		"set_flag": "co_duong_cong",
		"xp_reward": 180,
		"gold_reward": 100,
		"reputation_reward": 20,
		"status": "available",
	})
	_add_quest({
		"id": "dong_07_vua",
		"title": "Lật đổ King Aldric",
		"region": "dong",
		"description": "Đột nhập Royal Palace of Aldenmere qua Aldenmere Sewers và đánh bại King Aldric cùng kẻ thao túng sau lưng hắn.",
		"quest_type": "main",
		"target_type": "boss_vua",
		"target_count": 1,
		"progress": 0,
		"required_quest": "dong_06_giai_phu",
		"requires_turn_in": false,
		"turn_in_npc": "",
		"set_flag": "dong_giai_phong",
		"xp_reward": 400,
		"gold_reward": 250,
		"reputation_reward": 40,
		"status": "available",
	})


func _add_quest(q: Dictionary) -> void:
	quests[str(q.get("id", ""))] = q


func accept_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		push_warning("[QuestManager] Không có quest: " + quest_id)
		return false
	var q: Dictionary = quests[quest_id]
	if str(q.get("status", "")) != "available":
		return false
	# Quest tiên quyết: phải completed mới nhận được quest này
	var required := str(q.get("required_quest", ""))
	if required != "" and not completed_quests.has(required):
		print("[QuestManager] Chưa nhận được '%s': cần hoàn thành quest '%s' trước." % [quest_id, required])
		return false
	q["status"] = "active"
	quests[quest_id] = q
	if not active_quests.has(quest_id):
		active_quests.append(quest_id)
	quest_accepted.emit(quest_id)
	quest_updated.emit(quest_id)
	print("[QuestManager] Nhận quest: ", q.get("title", quest_id))
	return true


func add_quest_progress(quest_id: String, amount: int = 1) -> void:
	if not quests.has(quest_id):
		return
	var q: Dictionary = quests[quest_id]
	if str(q.get("status", "")) != "active":
		return
	q["progress"] = mini(int(q.get("progress", 0)) + amount, int(q.get("target_count", 1)))
	quests[quest_id] = q
	quest_updated.emit(quest_id)
	if int(q["progress"]) >= int(q.get("target_count", 1)):
		if bool(q.get("requires_turn_in", false)):
			# Đủ tiến độ nhưng CHƯA nhận thưởng: chờ player quay lại NPC trả nhiệm vụ
			q["status"] = "ready_turn_in"
			quests[quest_id] = q
			quest_updated.emit(quest_id)
			print("[QuestManager] Quest '%s' đã đủ tiến độ — hãy quay lại gặp NPC '%s' để trả." % [quest_id, str(q.get("turn_in_npc", ""))])
		else:
			complete_quest(quest_id)


# Trả nhiệm vụ tại NPC: chỉ hoàn thành (và phát thưởng) khi đang ready_turn_in.
func turn_in_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		return false
	var q: Dictionary = quests[quest_id]
	if str(q.get("status", "")) != "ready_turn_in":
		return false
	return complete_quest(quest_id)


# Gọi khi enemy chết — generic: mọi quest active có target_type khớp đều +1
func on_enemy_killed(enemy_type: String) -> void:
	print("[QuestManager] Enemy bị hạ: ", enemy_type)
	for qid in quests.keys():
		var q: Dictionary = quests[qid]
		if str(q.get("status", "")) == "active" and str(q.get("target_type", "")) == enemy_type:
			add_quest_progress(qid, 1)


# Gọi khi nhặt vật phẩm quest — generic theo collect_type (vd "herb")
func on_item_collected(item_id: String) -> void:
	print("[QuestManager] Nhặt vật phẩm quest: ", item_id)
	for qid in quests.keys():
		var q: Dictionary = quests[qid]
		if str(q.get("status", "")) == "active" and str(q.get("collect_type", "")) == item_id:
			add_quest_progress(qid, 1)


func complete_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		return false
	var q: Dictionary = quests[quest_id]
	if str(q.get("status", "")) == "completed":
		return false
	q["status"] = "completed"
	quests[quest_id] = q
	active_quests.erase(quest_id)
	if not completed_quests.has(quest_id):
		completed_quests.append(quest_id)
	# Thưởng qua GameState
	if has_node("/root/GameState"):
		GameState.add_xp(int(q.get("xp_reward", 0)))
		GameState.add_gold(int(q.get("gold_reward", 0)))
		var rep: int = int(q.get("reputation_reward", 0))
		if rep != 0:
			GameState.add_reputation(str(q.get("region", "dong")), rep)
	# Hook tuyến giải phóng: quest có thể đặt flag cốt truyện khi hoàn thành
	var sf: String = str(q.get("set_flag", ""))
	if sf != "" and has_node("/root/GameState"):
		GameState.set_flag(sf)
		print("[QuestManager] Đặt flag cốt truyện: ", sf)
	quest_completed.emit(quest_id)
	quest_updated.emit(quest_id)
	print("[QuestManager] Hoàn thành quest: ", q.get("title", quest_id))
	return true


func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})


func to_dict() -> Dictionary:
	return {
		"quests": quests.duplicate(true),
		"active_quests": active_quests.duplicate(),
		"completed_quests": completed_quests.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	if data.has("quests") and data["quests"] is Dictionary:
		quests = data["quests"].duplicate(true)
	active_quests.clear()
	completed_quests.clear()
	for id in data.get("active_quests", []):
		active_quests.append(str(id))
	for id in data.get("completed_quests", []):
		completed_quests.append(str(id))
