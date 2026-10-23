extends Node
## QuestManager - Autoload quản lý nhiệm vụ (STUB cho prototype)
## Quest lưu dạng Dictionary: id, title, region, status, xp_reward, gold_reward
## status: "available" | "active" | "completed"

signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_updated(quest_id: String)

var quests: Dictionary = {}
var active_quests: Array[String] = []
var completed_quests: Array[String] = []


func _ready() -> void:
	_register_starter_quests()


func _register_starter_quests() -> void:
	# Nhiệm vụ mẫu ở Làng Tân Diệp (Đông) — khớp world design
	_add_quest({
		"id": "dong_01_goblin",
		"title": "Dẹp Goblin ở bìa rừng Tân Diệp",
		"region": "dong",
		"description": "Tiêu diệt 3 goblin quấy phá làng Tân Diệp.",
		"target_count": 3,
		"progress": 0,
		"xp_reward": 30,
		"gold_reward": 20,
		"reputation_reward": 5,
		"status": "available",
	})
	_add_quest({
		"id": "dong_02_herb",
		"title": "Hái thảo dược cho thầy lang",
		"region": "dong",
		"description": "Thu thập thảo dược quanh làng (stub).",
		"target_count": 5,
		"progress": 0,
		"xp_reward": 15,
		"gold_reward": 10,
		"reputation_reward": 3,
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
	q["progress"] = int(q.get("progress", 0)) + amount
	quests[quest_id] = q
	quest_updated.emit(quest_id)
	if int(q["progress"]) >= int(q.get("target_count", 1)):
		complete_quest(quest_id)


# Gọi khi enemy chết — stub nối sự kiện săn quái vào quest
func on_enemy_killed(enemy_type: String) -> void:
	print("[QuestManager] Enemy bị hạ: ", enemy_type)
	if enemy_type == "goblin" and active_quests.has("dong_01_goblin"):
		add_quest_progress("dong_01_goblin", 1)


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
