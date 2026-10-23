extends CanvasLayer
## DialogueBox - Hộp thoại dưới màn hình (CanvasLayer, instance tạm thời).
## NPC tạo instance, gọi start_dialogue(tên, mảng câu) rồi nối signal
## dialogue_finished để xử lý logic quest/shop khi thoại kết thúc.
## Trong lúc thoại mở: GameState.in_dialogue = true (player bị khóa di chuyển).
## Bấm interact hoặc attack để sang câu tiếp theo.

signal dialogue_finished

var _lines: Array[String] = []
var _index: int = 0
var _active: bool = false
var _opened_msec: int = 0 # chặn việc cú bấm vừa mở thoại bị tính là "sang câu"

@onready var name_label: Label = $PanelContainer/VBoxContainer/NameLabel
@onready var text_label: Label = $PanelContainer/VBoxContainer/TextLabel


func _ready() -> void:
	visible = false


func start_dialogue(speaker_name: String, lines: Array[String]) -> void:
	_lines = lines.duplicate()
	if _lines.is_empty():
		_lines = ["..."]
	_index = 0
	_active = true
	_opened_msec = Time.get_ticks_msec()
	visible = true
	if has_node("/root/GameState"):
		GameState.in_dialogue = true
	name_label.text = speaker_name
	_show_line()


func _show_line() -> void:
	text_label.text = _lines[_index]


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	# Bỏ qua input trong 150ms đầu (cú bấm mở thoại / vừa đóng thoại trước)
	if Time.get_ticks_msec() - _opened_msec < 150:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_finish()
	else:
		_show_line()


func _finish() -> void:
	_active = false
	visible = false
	if has_node("/root/GameState"):
		GameState.in_dialogue = false
	dialogue_finished.emit()
	queue_free()
