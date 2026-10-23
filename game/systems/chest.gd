extends Area2D
## Chest - Rương loot tương tác được (group "interactable" + "chest").
## Player tới gần (<60px) hiện prompt "[E] Mở rương"; bấm interact (player.gd
## gọi interact()) để mở: nhận gold / bình máu / trang bị theo export.
## Trạng thái đã mở lưu bằng GameState flag "chest_" + chest_id — mở rồi thì
## interact chỉ hiện "Rương đã mở", không phát thưởng nữa, sprite xám đi.

@export var chest_id: String = ""
@export var gold_reward: int = 0
@export var potion_count: int = 0
@export var equip_name: String = ""
@export var equip_attack: int = 0
@export var equip_defense: int = 0

var _msg_token: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel
@onready var loot_label: Label = $LootLabel


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("chest")
	prompt_label.visible = false
	loot_label.visible = false
	if _is_opened():
		_apply_opened_visual()


func _flag_key() -> String:
	return "chest_" + (chest_id if chest_id != "" else name)


func _is_opened() -> bool:
	return has_node("/root/GameState") and GameState.get_flag(_flag_key())


func _apply_opened_visual() -> void:
	if sprite != null:
		sprite.modulate = Color(0.55, 0.55, 0.55, 1.0)


func _process(_delta: float) -> void:
	# Prompt theo khoảng cách tới player (như npc.gd)
	var near_player := false
	if not _is_opened():
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Node2D:
			near_player = global_position.distance_to((players[0] as Node2D).global_position) < 60.0
	prompt_label.visible = near_player


func _show_loot(text: String, duration: float = 2.5) -> void:
	_msg_token += 1
	var token := _msg_token
	loot_label.text = text
	loot_label.visible = true
	await get_tree().create_timer(duration).timeout
	if is_inside_tree() and token == _msg_token:
		loot_label.visible = false


# Player gọi khi bấm interact ở gần (xem player.gd _try_interact)
func interact() -> void:
	if not has_node("/root/GameState"):
		return
	if _is_opened():
		_show_loot("Rương đã mở")
		return
	GameState.set_flag(_flag_key())
	var lines: Array[String] = []
	if gold_reward > 0:
		GameState.add_gold(gold_reward)
		lines.append("+%d Vàng" % gold_reward)
	if potion_count > 0:
		GameState.add_potions(potion_count)
		lines.append("+%d Bình máu" % potion_count)
	if equip_name != "":
		GameState.add_equipment(equip_name, equip_attack, equip_defense)
		var bonus_txt := ""
		if equip_attack > 0:
			bonus_txt += "+%d ATK" % equip_attack
		if equip_defense > 0:
			bonus_txt += (" " if bonus_txt != "" else "") + "+%d DEF" % equip_defense
		lines.append("Trang bị: %s (%s)" % [equip_name, bonus_txt])
	if lines.is_empty():
		lines.append("Rương trống...")
	_apply_opened_visual()
	_show_loot("\n".join(lines))
	print("[Chest %s] Đã mở: %s" % [chest_id, ", ".join(lines)])
