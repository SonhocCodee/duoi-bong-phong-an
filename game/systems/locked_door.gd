extends StaticBody2D
## LockedDoor - Cửa khoá tương tác được (group "interactable" + "locked_door").
## Player tới gần (<60px) hiện prompt "[E] Mở cửa"; bấm interact:
##  - required_flag rỗng hoặc GameState đã có flag -> MỞ: tắt collision
##    (deferred), ẩn sprite, hiện "Cạch! Cửa đã mở."
##  - Chưa có flag -> hiện locked_text (hoặc câu mặc định) trong 2 giây,
##    cửa vẫn chặn đường.
## Lưu ý: nếu flag đã có sẵn từ save, cửa vẫn đóng cho tới lần interact đầu
## (chấp nhận được ở mức prototype).

@export var required_flag: String = ""
@export var locked_text: String = ""

var opened: bool = false
var _msg_token: int = 0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel
@onready var msg_label: Label = $MsgLabel


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("locked_door")
	prompt_label.visible = false
	msg_label.visible = false


func _process(_delta: float) -> void:
	var near_player := false
	if not opened:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Node2D:
			near_player = global_position.distance_to((players[0] as Node2D).global_position) < 60.0
	prompt_label.visible = near_player


func _show_msg(text: String, duration: float = 2.0) -> void:
	_msg_token += 1
	var token := _msg_token
	msg_label.text = text
	msg_label.visible = true
	await get_tree().create_timer(duration).timeout
	if is_inside_tree() and token == _msg_token:
		msg_label.visible = false


# Player gọi khi bấm interact ở gần (xem player.gd _try_interact)
func interact() -> void:
	if opened:
		return
	var unlocked: bool = required_flag == ""
	if not unlocked and has_node("/root/GameState"):
		unlocked = GameState.get_flag(required_flag)
	if unlocked:
		opened = true
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		if sprite:
			sprite.visible = false
		prompt_label.visible = false
		_show_msg("Cạch! Cửa đã mở.")
		print("[LockedDoor] Đã mở (flag yêu cầu: '%s')" % required_flag)
	else:
		var msg := locked_text if locked_text != "" else "Khoá chặt. Cần chìa khoá mới mở được."
		_show_msg(msg)
		print("[LockedDoor] Còn khoá (cần flag '%s')" % required_flag)
