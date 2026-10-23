extends CanvasLayer
## EndingPanel - Màn hình kết thúc PHẦN 1 (CanvasLayer, layer cao).
## Chỉ instance vào map hoang_cung: hiện khi GameState phát signal
## part1_completed (flag "dong_giai_phong" được set qua quest dong_07_vua).
## Phòng trường hợp flag đã set TRƯỚC khi scene load (signal bị lỡ):
## _ready kiểm tra thêm GameState.get_flag("dong_giai_phong") và hiện ngay.
## Nội dung tổng kết đọc flags THẬT từ GameState / QuestManager lúc hiện —
## mỗi sự kiện 1 dòng, có/không ra chữ khác nhau.
## Trong lúc hiện: GameState.in_dialogue = true (khóa player); bấm nút
## "Chơi tiếp" -> ẩn panel + in_dialogue = false (tự do khám phá tiếp).
## Panel vẽ bằng Control/Label/Button thuần + nền mờ đen — KHÔNG vẽ tranh
## trang trí bằng code, đúng pipeline art hiện tại.

@onready var summary_label: Label = $CenterContainer/PanelContainer/VBoxContainer/SummaryLabel
@onready var continue_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ContinueButton


func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	if has_node("/root/GameState"):
		if not GameState.part1_completed.is_connected(_on_part1_completed):
			GameState.part1_completed.connect(_on_part1_completed)
		# Signal có thể đã lỡ (flag set trước khi panel load) -> kiểm tra flag
		if GameState.get_flag("dong_giai_phong"):
			show_panel()


func _on_part1_completed() -> void:
	show_panel()


## Hiện panel + khóa di chuyển của player. Public để test gọi trực tiếp.
func show_panel() -> void:
	_refresh_summary()
	visible = true
	if has_node("/root/GameState"):
		GameState.in_dialogue = true
	print("[EndingPanel] PHẦN 1 HOÀN THÀNH — hiện màn hình kết thúc Aldenmere Giải Phóng.")


func _on_continue_pressed() -> void:
	visible = false
	if has_node("/root/GameState"):
		GameState.in_dialogue = false
	print("[EndingPanel] Đóng panel kết thúc — chơi tiếp tự do khám phá.")


func _flag(key: String) -> bool:
	return has_node("/root/GameState") and GameState.get_flag(key)


func _refresh_summary() -> void:
	if summary_label == null:
		return
	var lines: Array[String] = []
	# Trạm thuế Stonebridge (quest dong_05 đặt flag tram_thue_pha)
	if _flag("tram_thue_pha"):
		lines.append("✓ Trạm thuế Stonebridge đã bị phá — dân qua cầu không còn bị lính vua bóc lột.")
	else:
		lines.append("• Trạm thuế Stonebridge vẫn còn đó — lính thuế vẫn chặn cầu thu tiền của dân.")
	# Phu mỏ Bluestone Mine (quest dong_06 đặt flag co_duong_cong)
	if _flag("co_duong_cong"):
		lines.append("✓ Phu mỏ Bluestone Mine đã được giải phóng khỏi tay đốc công sơn tặc.")
	else:
		lines.append("• Phu mỏ Bluestone Mine vẫn bị bắt làm khổ sai trong mỏ đá.")
	# Mossback, the Moss Golem (boss_golem đặt flag golem_dead)
	if _flag("golem_dead"):
		lines.append("✓ Mossback, the Moss Golem đã gục ngã — Elderwood và Mistlake yên bình trở lại.")
	else:
		lines.append("• Mossback, the Moss Golem vẫn canh giữ hang sâu dưới Cloudpeak.")
	# The Rat King (quest dong_03 completed qua QuestManager)
	var rat_done := false
	if has_node("/root/QuestManager"):
		if QuestManager.completed_quests.has("dong_03_chuot_chua"):
			rat_done = true
		elif str(QuestManager.get_quest("dong_03_chuot_chua").get("status", "")) == "completed":
			rat_done = true
	if rat_done:
		lines.append("✓ The Rat King dưới Elmford Cellar đã bị tiêu diệt — Elmford Cellar sạch bóng chuột.")
	else:
		lines.append("• The Rat King vẫn ẩn mình dưới đáy Elmford Cellar.")
	# Uy tín Aldenmere
	var rep := 0
	if has_node("/root/GameState"):
		rep = GameState.get_reputation("dong")
	if rep > 0:
		lines.append("★ Uy tín Aldenmere: %d — dân Aldenmere đã đặt niềm tin vào bạn." % rep)
	else:
		lines.append("★ Uy tín Aldenmere: 0 — dân Aldenmere vẫn chưa biết đến bạn.")
	summary_label.text = "\n".join(PackedStringArray(lines))
