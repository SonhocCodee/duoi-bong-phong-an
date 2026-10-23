extends CanvasLayer
## HUD - Thanh HP / Stamina, nhãn Gold / XP / Level
## Cập nhật qua signal của Player và GameState.

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPBar/HPLabel
@onready var stamina_label: Label = $MarginContainer/VBoxContainer/StaminaBar/StaminaLabel
@onready var info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var quest_label: Label = $MarginContainer/VBoxContainer/QuestLabel
@onready var potion_label: Label = $MarginContainer/VBoxContainer/PotionLabel
@onready var boss_container: VBoxContainer = $BossContainer
@onready var boss_name_label: Label = $BossContainer/BossNameLabel
@onready var boss_bar: ProgressBar = $BossContainer/BossBar

var _player: Node = null


func _ready() -> void:
	# Nối signal GameState
	if has_node("/root/GameState"):
		GameState.gold_changed.connect(_on_gold_changed)
		GameState.xp_changed.connect(_on_xp_changed)
		GameState.level_changed.connect(_on_level_changed)
		GameState.player_hp_changed.connect(_on_game_hp_changed)
		GameState.potions_changed.connect(_on_potions_changed)
		GameState.boss_changed.connect(_on_boss_changed)
	if has_node("/root/QuestManager"):
		QuestManager.quest_updated.connect(_on_quest_updated)
		QuestManager.quest_completed.connect(_on_quest_completed)
	_refresh_info()
	_refresh_quest()
	_refresh_potions()
	if has_node("/root/GameState"):
		_on_boss_changed(GameState.boss_name, GameState.boss_hp, GameState.boss_max_hp)
	# Thử tìm player ngay (nếu HUD được thêm sau player thì _process sẽ nối tiếp)
	_try_connect_player()


func _process(_delta: float) -> void:
	if _player == null:
		_try_connect_player()


func _try_connect_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	_player = players[0]
	if _player.has_signal("health_changed"):
		if not _player.health_changed.is_connected(_on_player_health):
			_player.health_changed.connect(_on_player_health)
	if _player.has_signal("stamina_changed"):
		if not _player.stamina_changed.is_connected(_on_player_stamina):
			_player.stamina_changed.connect(_on_player_stamina)
	# Đồng bộ lần đầu (dùng get() cho an toàn với Object)
	var hp_val: Variant = _player.get("hp")
	var max_hp_val: Variant = _player.get("max_hp")
	if hp_val != null and max_hp_val != null:
		_on_player_health(int(hp_val), int(max_hp_val))
	var sta_val: Variant = _player.get("stamina")
	var max_sta_val: Variant = _player.get("max_stamina")
	if sta_val != null and max_sta_val != null:
		_on_player_stamina(float(sta_val), float(max_sta_val))


func _on_player_health(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_label.text = "HP %d / %d" % [current_hp, max_hp]


func _on_game_hp_changed(current_hp: int, max_hp: int) -> void:
	# Chỉ dùng khi chưa nối được player trực tiếp
	if _player == null:
		_on_player_health(current_hp, max_hp)


func _on_player_stamina(current_stamina: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
	stamina_label.text = "STA %d / %d" % [int(current_stamina), int(max_stamina)]


func _on_gold_changed(_g: int) -> void:
	_refresh_info()

func _on_xp_changed(_x: int, _l: int) -> void:
	_refresh_info()

func _on_level_changed(_l: int) -> void:
	_refresh_info()


func _refresh_info() -> void:
	if not is_node_ready():
		return
	if has_node("/root/GameState"):
		info_label.text = "Level %d  |  XP %d / %d  |  Vàng: %d" % [
			GameState.level, GameState.xp, GameState.xp_to_next_level, GameState.gold
		]
	else:
		info_label.text = "Level 1  |  XP 0  |  Vàng: 0"


func _on_potions_changed(_n: int) -> void:
	_refresh_potions()


func _refresh_potions() -> void:
	if not is_node_ready() or potion_label == null:
		return
	if has_node("/root/GameState"):
		potion_label.text = "Bình: %d — [H] dùng" % GameState.potions


# Thanh máu boss: hiện khi GameState.set_boss_display, ẩn khi clear_boss_display
func _on_boss_changed(display_name: String, hp: int, max_hp: int) -> void:
	if not is_node_ready() or boss_container == null:
		return
	if display_name == "" or max_hp <= 0:
		boss_container.visible = false
		return
	boss_container.visible = true
	boss_name_label.text = display_name
	boss_bar.max_value = max_hp
	boss_bar.value = hp


func _on_quest_updated(_id: String) -> void:
	_refresh_quest()

func _on_quest_completed(_id: String) -> void:
	_refresh_quest()


func _refresh_quest() -> void:
	if not is_node_ready() or quest_label == null:
		return
	if not has_node("/root/QuestManager"):
		quest_label.text = ""
		return
	# Chỉ theo dõi quest active đầu tiên (gồm cả quest đang chờ trả ready_turn_in)
	for qid in QuestManager.active_quests:
		var q: Dictionary = QuestManager.get_quest(qid)
		if q.is_empty():
			continue
		var line := "Nhiệm vụ: %s (%d/%d)" % [str(q.get("title", qid)), int(q.get("progress", 0)), int(q.get("target_count", 0))]
		if str(q.get("status", "")) == "ready_turn_in":
			line += " — Quay lại trả nhiệm vụ!"
		quest_label.text = line
		return
	# Không còn quest active
	if QuestManager.completed_quests.size() > 0:
		quest_label.text = "Nhiệm vụ: Đã hoàn thành nhiệm vụ Elmford ✓"
	else:
		quest_label.text = ""
