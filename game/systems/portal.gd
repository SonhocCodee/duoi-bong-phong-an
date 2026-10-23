extends Area2D
## Portal - Cổng chuyển map. Agent bản đồ instance portal.tscn rồi set export.
## Player bước vào: nếu required_flag rỗng hoặc GameState đã có cờ đó thì ghi
## spawn_point/current_map vào GameState rồi change_scene_to_file(target_scene).
## Nếu bị khóa: in log + hiện locked_text trên nhãn tạm phía trên cổng.

@export var target_scene: String = "" # res://maps/....tscn
@export var target_spawn: String = "" # tên spawn ở map đích (Marker2D "Spawn_<tên>")
@export var required_flag: String = "" # rỗng = không khóa
@export var locked_text: String = ""
@export var label_text: String = "" # tên đích hiện trên cổng; rỗng = tự lấy tên file đích

@onready var target_label: Label = $TargetLabel
@onready var locked_label: Label = $LockedLabel


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	locked_label.visible = false
	if label_text != "":
		target_label.text = label_text
	elif target_scene != "":
		target_label.text = target_scene.get_file().get_basename()
	else:
		target_label.text = "Cổng"


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not has_node("/root/GameState"):
		return
	if required_flag == "" or GameState.get_flag(required_flag):
		GameState.spawn_point = target_spawn
		GameState.current_map = target_scene
		print("[Portal] Chuyển map -> %s (spawn: %s)" % [target_scene, target_spawn])
		if target_scene != "":
			get_tree().change_scene_to_file(target_scene)
	else:
		var msg := locked_text if locked_text != "" else "Chưa thể qua lúc này!"
		print("[Portal] Bị khóa (%s): %s" % [required_flag, msg])
		locked_label.text = msg
		locked_label.visible = true
		await get_tree().create_timer(2.0).timeout
		if is_inside_tree() and is_instance_valid(locked_label):
			locked_label.visible = false
