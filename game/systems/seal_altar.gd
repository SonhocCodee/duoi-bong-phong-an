extends Area2D
## SealAltar - Bệ Phong Ấn giữa Đài Sigilspire (group "interactable" +
## "seal_altar"). Player tới gần (<64px) hiện prompt; bấm interact:
##  - Chưa hạ boss cuối (chưa có flag "final_boss_dead"): bệ còn neo
##    chặt, chỉ hiện thông điệp.
##  - Đã hạ boss + chưa chọn ending: mở FinalEndingPanel chọn ending.
##  - Đã chọn ending: hiện tên kết cục đã chốt.

const FINAL_PANEL_SCENE: PackedScene = preload("res://ui/final_ending_panel.tscn")

var _msg_token: int = 0

@onready var prompt_label: Label = $PromptLabel
@onready var msg_label: Label = $MsgLabel


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("seal_altar")
	prompt_label.visible = false
	msg_label.visible = false


func _process(_delta: float) -> void:
	var near_player := false
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node2D:
		near_player = global_position.distance_to((players[0] as Node2D).global_position) < 64.0
	prompt_label.visible = near_player


func _show_msg(text: String, duration: float = 3.0) -> void:
	_msg_token += 1
	var token := _msg_token
	msg_label.text = text
	msg_label.visible = true
	await get_tree().create_timer(duration).timeout
	if is_inside_tree() and token == _msg_token:
		msg_label.visible = false


# Player gọi khi bấm interact ở gần (xem player.gd _try_interact)
func interact() -> void:
	if not has_node("/root/GameState"):
		return
	if not GameState.get_flag("final_boss_dead"):
		_show_msg("Bệ Phong Ấn còn neo chặt vào ngai của Vua. Hạ kẻ kéo dây trước đã.")
		print("[SealAltar] Chưa hạ boss cuối — bệ chưa mở.")
		return
	if GameState.game_completed:
		_show_msg("Phong ấn đã có kết cục. Vương quốc đang sống trong kết cục đó.")
		print("[SealAltar] Ending đã chốt: %s" % GameState.ending_id)
		return
	var panel: CanvasLayer = FINAL_PANEL_SCENE.instantiate()
	var host: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	host.add_child(panel)
	panel.show_panel()
	print("[SealAltar] Mở FinalEndingPanel.")
