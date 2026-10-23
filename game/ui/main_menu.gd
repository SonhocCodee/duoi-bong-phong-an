extends Control
## MainMenu - Màn hình chính (run/main_scene).
## "Chơi mới": reset GameState + QuestManager, xóa save, vào Elmford.
## "Tiếp tục": disabled khi chưa có save; load_game rồi chuyển tới
## GameState.current_map nếu hợp lệ, ngược lại vào Elmford.
## "Thoát": thoát game.

@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var new_game_button: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_refresh_continue()


func _refresh_continue() -> void:
	var has := false
	if has_node("/root/SaveSystem"):
		has = SaveSystem.has_save()
	continue_button.disabled = not has


func _on_new_game_pressed() -> void:
	if has_node("/root/GameState"):
		GameState.reset_game()
	if has_node("/root/QuestManager"):
		QuestManager.reset_quests()
	if has_node("/root/SaveSystem"):
		SaveSystem.delete_save()
	get_tree().change_scene_to_file("res://maps/lang_tan_diep.tscn")


func _on_continue_pressed() -> void:
	if not has_node("/root/SaveSystem"):
		get_tree().change_scene_to_file("res://maps/lang_tan_diep.tscn")
		return
	SaveSystem.load_game()
	var target := ""
	if has_node("/root/GameState"):
		target = GameState.current_map
	if target != "" and ResourceLoader.exists(target):
		get_tree().change_scene_to_file(target)
	else:
		get_tree().change_scene_to_file("res://maps/lang_tan_diep.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
