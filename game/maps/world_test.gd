extends Node2D
## WorldTest - Map test thể hiện thế giới 4 thành + tháp trung tâm
## Layout: Bắc trên, Nam dưới, Tây trái, Đông phải, Tháp ở giữa.
## Phím tắt debug: F5 lưu game, F9 tải game (ngoài input map chính)

func _ready() -> void:
	print("[World] Map test đã load: 4 thành + Tháp Vương Ấn ở trung tâm.")
	print("[World] Player spawn ở Đông - Làng Tân Diệp. Hãy đánh 3 goblin gần đó!")
	# Thử tự nhận quest mẫu nếu player chưa nhận (player cũng tự nhận)
	if has_node("/root/QuestManager"):
		if QuestManager.active_quests.is_empty() and QuestManager.completed_quests.is_empty():
			QuestManager.accept_quest("dong_01_goblin")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			if has_node("/root/SaveSystem"):
				SaveSystem.save_game()
		elif event.keycode == KEY_F9:
			if has_node("/root/SaveSystem"):
				SaveSystem.load_game()
