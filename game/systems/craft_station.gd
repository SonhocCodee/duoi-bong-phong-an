extends Area2D
## CraftStation - Lò rèn / bàn giả kim tương tác được (group
## "interactable" + "craft_station"). Player tới gần (<60px) hiện prompt
## "[E] Chế tạo"; bấm interact -> mở CraftPanel (ui/craft_panel.tscn).
## Đặt ở các hub: Elmford (cạnh lò rèn), Reedmere, Sunwell Oasis,
## Hearthwick và Trạm Gác Tro — xem các builder trong tools_paint.

const CRAFT_PANEL_SCENE: PackedScene = preload("res://ui/craft_panel.tscn")

@export var station_name: String = "Bàn Chế Tạo"

@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("craft_station")
	prompt_label.visible = false


func _process(_delta: float) -> void:
	var near_player := false
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node2D:
		near_player = global_position.distance_to((players[0] as Node2D).global_position) < 60.0
	prompt_label.visible = near_player


# Player gọi khi bấm interact ở gần (xem player.gd _try_interact)
func interact() -> void:
	var panel: CanvasLayer = CRAFT_PANEL_SCENE.instantiate()
	var host: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	host.add_child(panel)
	panel.open_craft()
	print("[CraftStation %s] Mở CraftPanel." % station_name)
