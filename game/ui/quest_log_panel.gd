extends CanvasLayer
## QuestLogPanel - Sổ nhiệm vụ (phím J, HUD lo phần toggle).
## CanvasLayer layer 30, mặc định ẩn. Nội dung dựng bởi build_log_text()
## (hàm thuần, test gọi được mà không cần mở UI):
##   — ĐANG LÀM — : mọi quest trong QuestManager.active_quests kèm tiến độ,
##                  hoặc "(chờ trả: <turn_in_npc>)" khi status ready_turn_in.
##   — ĐÃ HOÀN THÀNH — : mọi quest trong QuestManager.completed_quests.
## Khi hiện: GameState.in_dialogue = true (khóa di chuyển player);
## ẩn thì trả về false.

@onready var content_label: Label = $CenterContainer/PanelContainer/VBoxContainer/ContentLabel
@onready var close_button: Button = $CenterContainer/PanelContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	if close_button != null:
		close_button.pressed.connect(hide_panel)


## Dựng toàn bộ nội dung sổ quest dạng text (không phụ thuộc UI đã hiện).
func build_log_text() -> String:
	var lines: Array[String] = []
	lines.append("— ĐANG LÀM —")
	if not has_node("/root/QuestManager"):
		lines.append("• (không có dữ liệu nhiệm vụ)")
	else:
		if QuestManager.active_quests.is_empty():
			lines.append("• (chưa có nhiệm vụ nào đang làm)")
		for qid in QuestManager.active_quests:
			var q: Dictionary = QuestManager.get_quest(qid)
			if q.is_empty():
				continue
			var title := str(q.get("title", qid))
			if str(q.get("status", "")) == "ready_turn_in":
				lines.append("• %s (chờ trả: %s)" % [title, str(q.get("turn_in_npc", ""))])
			else:
				lines.append("• %s (%d/%d)" % [title, int(q.get("progress", 0)), int(q.get("target_count", 0))])
		lines.append("")
		lines.append("— ĐÃ HOÀN THÀNH —")
		if QuestManager.completed_quests.is_empty():
			lines.append("• (chưa hoàn thành nhiệm vụ nào)")
		for qid2 in QuestManager.completed_quests:
			var q2: Dictionary = QuestManager.get_quest(qid2)
			lines.append("• %s ✓" % str(q2.get("title", qid2)))
	return "\n".join(lines)


func show_panel() -> void:
	if content_label != null:
		content_label.text = build_log_text()
	visible = true
	if has_node("/root/GameState"):
		GameState.in_dialogue = true


func hide_panel() -> void:
	visible = false
	if has_node("/root/GameState"):
		GameState.in_dialogue = false
