extends CanvasLayer
## SkillPanel - Cây skill (phím T, HUD lo phần toggle khi panel nằm trong HUD;
## panel cũng tự xử lý T/Esc khi đứng độc lập trong test).
## CanvasLayer layer 30, mặc định ẩn. Khi hiện: GameState.in_dialogue = true
## (khoá di chuyển player — cùng cách quest_log_panel / shop_panel đang làm,
## không pause tree để tránh kẹt _process của HUD).
## 3 nhánh GDD: Chiến binh (đỏ, mở khoá thật qua GameState.try_unlock_skill),
## Chiến đấu pháp sư (xanh, mở khoá thật sau Phần 3), Dấu ấn/Thuật đen
## (tím, mở khoá thật sau Phần 2).

# Nhánh Chiến binh: id khớp GameState.SKILL_DEFS / player.gd
const WARRIOR_SKILLS: Array = [
	{"id": "chem_xoay", "name": "Chém Xoáy", "desc": "25 STA, CD 6s — 130% damage quanh thân (bán kính 80px)."},
	{"id": "xung_kich", "name": "Xung Kích (Lướt Chém)", "desc": "20 STA, CD 5s — lướt 160px, chém xuyên 110% damage, đẩy lùi + choáng 0.6s."},
	{"id": "cuong_no", "name": "Cuồng Nộ", "desc": "CD 45s — 10s: +25% tốc đánh, +20% damage, đòn thường miễn stamina."},
]
const WARRIOR_PASSIVE: Dictionary = {"id": "da_sat", "name": "Da Sắt (bị động)", "desc": "Giảm 15% damage nhận vào (sau khi trừ DEF). Luôn hiệu lực khi đã học — không tốn phím."}
const MAGE_SKILLS: Array = [
	{"id": "cau_lua", "name": "Cầu Lửa", "desc": "25 STA, CD 9s — đạn lửa bay, nổ 160% damage trong bán kính 110px."},
	{"id": "gai_bang", "name": "Gai Băng", "desc": "20 STA, CD 11s — 110% damage trong bán kính 120px, chậm còn 40% trong 3s + choáng 0.8s."},
	{"id": "set_lan", "name": "Sét Lan", "desc": "25 STA, CD 12s — sét nhảy tối đa 4 mục tiêu, damage giảm 15% mỗi lần nhảy."},
	{"id": "khien_ma_thuat", "name": "Khiên Ma Thuật", "desc": "[Trang 2 - phím 3] 20 STA, CD 18s — khiên hấp thụ (40 + 4×cấp) damage trong 8s."},
	{"id": "mua_thien_thach", "name": "Mưa Thiên Thạch", "desc": "[Trang 2 - phím 4] 35 STA, CD 20s — 5 đợt thiên thạch diện rộng quanh mục tiêu, 90% damage/viên."},
]
const MAGE_FUTURE_SKILLS: Array = []
const MAGE_NOTE: String = "Mở cuối chặng Tây khi chạm mảnh phong ấn."
const DARK_SKILLS: Array = [
	{"id": "dau_an_lua", "name": "Dấu Ấn Lửa", "desc": "20 STA, CD 8s — gắn ấn 150% damage, nổ trễ 1.2s trong bán kính 96px."},
	{"id": "bay_hon", "name": "Bẫy Hồn", "desc": "15 STA, CD 12s — đặt bẫy 20s; quái vào vùng bị chậm 50% trong 3s + choáng 1s."},
	{"id": "hut_sinh_luc", "name": "Hút Sinh Lực", "desc": "25 STA, CD 10s — đánh mục tiêu gần nhất 120% damage, hồi 40% sát thương thành HP."},
	{"id": "trieu_hoi_bong", "name": "Triệu Hồi Bóng", "desc": "[Trang 2 - phím 1] 30 STA, CD 30s — gọi 1 bóng đồng minh đánh cùng 20s, 80% damage mỗi 0.9s."},
	{"id": "cong_phong_an", "name": "Cổng Phong Ấn", "desc": "[Trang 2 - phím 2] 15 STA, CD 14s — dịch chuyển tối đa 220px theo hướng mặt, xuyên vật cản mỏng."},
]
const DARK_FUTURE_SKILLS: Array = []
const DARK_NOTE: String = "Mở cuối chặng Nam khi chạm mảnh phong ấn."

@onready var points_label: Label = $CenterContainer/PanelContainer/VBoxContainer/PointsLabel
@onready var content_box: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/ContentContainer
@onready var close_button: Button = $CenterContainer/PanelContainer/VBoxContainer/CloseButton

var _opened_msec: int = 0


func _ready() -> void:
	visible = false
	if close_button != null:
		close_button.pressed.connect(hide_panel)
	if has_node("/root/GameState") and GameState.has_signal("skills_changed"):
		GameState.skills_changed.connect(func(_p: int, _u: Array) -> void:
			if visible:
				refresh())
	refresh()


func _branch_header(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", color)
	return l


func _skill_row(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 14)
	return l


## Dựng lại toàn bộ nội dung cây skill từ GameState (test gọi được khi ẩn).
func refresh() -> void:
	if content_box == null:
		return
	for c in content_box.get_children():
		c.queue_free()
	var pts: int = 0
	var lvl: int = 1
	if has_node("/root/GameState"):
		pts = GameState.get_skill_points()
		lvl = GameState.level
	if points_label != null:
		points_label.text = "Điểm skill: %d  |  Cấp: %d  (mỗi cấp +1 điểm)" % [pts, lvl]
	# --- Nhánh Chiến binh (đỏ) ---
	content_box.add_child(_branch_header("🔴 CHIẾN BINH", Color(1.0, 0.45, 0.4)))
	for entry in WARRIOR_SKILLS:
		var sid: String = str(entry.get("id", ""))
		var def: Dictionary = {}
		if has_node("/root/GameState"):
			def = GameState.SKILL_DEFS.get(sid, {})
		var req: int = int(def.get("required_level", 1))
		var unlocked: bool = has_node("/root/GameState") and GameState.is_skill_unlocked(sid)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lbl := _skill_row("%s (Lv%d) — %s" % [str(entry.get("name", sid)), req, str(entry.get("desc", ""))])
		lbl.custom_minimum_size = Vector2(430, 0)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var btn := Button.new()
		btn.name = "Unlock_" + sid
		if unlocked:
			btn.text = "Đã học"
			btn.disabled = true
		elif lvl < req:
			btn.text = "Cần Lv%d" % req
			btn.disabled = true
		elif pts < 1:
			btn.text = "Mở khoá (1 điểm)"
			btn.disabled = true
		else:
			btn.text = "Mở khoá (1 điểm)"
			btn.disabled = false
			var captured_id: String = sid
			btn.pressed.connect(func() -> void:
				if has_node("/root/GameState") and GameState.try_unlock_skill(captured_id):
					refresh())
		row.add_child(btn)
		content_box.add_child(row)
	# Bị động Da Sắt (đợt 6): hàng mở khoá như skill thường, id "da_sat".
	var ds_id: String = str(WARRIOR_PASSIVE.get("id", "da_sat"))
	var ds_def: Dictionary = {}
	if has_node("/root/GameState"):
		ds_def = GameState.SKILL_DEFS.get(ds_id, {})
	var ds_req: int = int(ds_def.get("required_level", 3))
	var ds_unlocked: bool = has_node("/root/GameState") and GameState.is_skill_unlocked(ds_id)
	var ds_row := HBoxContainer.new()
	ds_row.add_theme_constant_override("separation", 10)
	var ds_lbl := _skill_row("• %s (Lv%d) — %s" % [str(WARRIOR_PASSIVE.get("name", "")), ds_req, str(WARRIOR_PASSIVE.get("desc", ""))])
	ds_lbl.custom_minimum_size = Vector2(430, 0)
	ds_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ds_row.add_child(ds_lbl)
	var ds_btn := Button.new()
	ds_btn.name = "Unlock_" + ds_id
	if ds_unlocked:
		ds_btn.text = "Đã học"
		ds_btn.disabled = true
	elif lvl < ds_req:
		ds_btn.text = "Cần Lv%d" % ds_req
		ds_btn.disabled = true
	elif pts < 1:
		ds_btn.text = "Mở khoá (1 điểm)"
		ds_btn.disabled = true
	else:
		ds_btn.text = "Mở khoá (1 điểm)"
		ds_btn.disabled = false
		ds_btn.pressed.connect(func() -> void:
			if has_node("/root/GameState") and GameState.try_unlock_skill(ds_id):
				refresh())
	ds_row.add_child(ds_btn)
	content_box.add_child(ds_row)
	# --- Nhánh Chiến đấu pháp sư (xanh): 3 skill làm thật, mở sau Phần 3 ---
	content_box.add_child(_branch_header("🔵 CHIẾN ĐẤU PHÁP SƯ", Color(0.45, 0.7, 1.0)))
	var mage_open: bool = has_node("/root/GameState") and GameState.get_flag("tay_giai_phong")
	if not mage_open:
		content_box.add_child(_skill_row("🔒 Nhánh chưa mở: hoàn thành Phần 3 Solmaris để mở. %s" % MAGE_NOTE))
	for entry in MAGE_SKILLS:
		var sid: String = str(entry.get("id", ""))
		var def: Dictionary = {}
		if has_node("/root/GameState"):
			def = GameState.SKILL_DEFS.get(sid, {})
		var req: int = int(def.get("required_level", 1))
		var unlocked: bool = has_node("/root/GameState") and GameState.is_skill_unlocked(sid)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lbl := _skill_row("%s (Lv%d) — %s" % [str(entry.get("name", sid)), req, str(entry.get("desc", ""))])
		lbl.custom_minimum_size = Vector2(430, 0)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var btn := Button.new()
		btn.name = "Unlock_" + sid
		if unlocked:
			btn.text = "Đã học"
			btn.disabled = true
		elif not mage_open:
			btn.text = "Cần xong Phần 3"
			btn.disabled = true
		elif lvl < req:
			btn.text = "Cần Lv%d" % req
			btn.disabled = true
		elif pts < 1:
			btn.text = "Mở khoá (1 điểm)"
			btn.disabled = true
		else:
			btn.text = "Mở khoá (1 điểm)"
			btn.disabled = false
			var captured_id: String = sid
			btn.pressed.connect(func() -> void:
				if has_node("/root/GameState") and GameState.try_unlock_skill(captured_id):
					refresh())
		row.add_child(btn)
		content_box.add_child(row)
	for n in MAGE_FUTURE_SKILLS:
		content_box.add_child(_skill_row("• %s — 🔒 Chưa làm" % str(n)))
	content_box.add_child(_skill_row("Ghi chú: %s" % MAGE_NOTE))
	# --- Nhánh Dấu ấn / Thuật đen (tím): 3 skill làm thật, mở sau Phần 2 ---
	content_box.add_child(_branch_header("🟣 DẤU ẤN / THUẬT ĐEN", Color(0.8, 0.55, 1.0)))
	var dark_open: bool = has_node("/root/GameState") and GameState.get_flag("nam_giai_phong")
	if not dark_open:
		content_box.add_child(_skill_row("🔒 Nhánh chưa mở: hoàn thành Phần 2 Fenmire để mở. %s" % DARK_NOTE))
	for entry in DARK_SKILLS:
		var sid: String = str(entry.get("id", ""))
		var def: Dictionary = {}
		if has_node("/root/GameState"):
			def = GameState.SKILL_DEFS.get(sid, {})
		var req: int = int(def.get("required_level", 1))
		var unlocked: bool = has_node("/root/GameState") and GameState.is_skill_unlocked(sid)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lbl := _skill_row("%s (Lv%d) — %s" % [str(entry.get("name", sid)), req, str(entry.get("desc", ""))])
		lbl.custom_minimum_size = Vector2(430, 0)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var btn := Button.new()
		btn.name = "Unlock_" + sid
		if unlocked:
			btn.text = "Đã học"
			btn.disabled = true
		elif not dark_open:
			btn.text = "Cần xong Phần 2"
			btn.disabled = true
		elif lvl < req:
			btn.text = "Cần Lv%d" % req
			btn.disabled = true
		elif pts < 1:
			btn.text = "Mở khoá (1 điểm)"
			btn.disabled = true
		else:
			btn.text = "Mở khoá (1 điểm)"
			btn.disabled = false
			var captured_id: String = sid
			btn.pressed.connect(func() -> void:
				if has_node("/root/GameState") and GameState.try_unlock_skill(captured_id):
					refresh())
		row.add_child(btn)
		content_box.add_child(row)
	for n in DARK_FUTURE_SKILLS:
		content_box.add_child(_skill_row("• %s — 🔒 Chưa làm" % str(n)))
	content_box.add_child(_skill_row("Ghi chú: %s" % DARK_NOTE))


## Chuỗi tóm tắt thuần logic (test kiểm tra nội dung mà không cần đọc UI node).
func build_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("CHIẾN BINH")
	for entry in WARRIOR_SKILLS:
		var sid: String = str(entry.get("id", ""))
		var unlocked: bool = has_node("/root/GameState") and GameState.is_skill_unlocked(sid)
		lines.append("%s: %s" % [str(entry.get("name", sid)), "Đã học" if unlocked else "Chưa học"])
	var ds_unlocked: bool = has_node("/root/GameState") and GameState.is_skill_unlocked("da_sat")
	lines.append("Da Sắt: %s" % ("Đã học" if ds_unlocked else "Chưa học"))
	var mage_open: bool = has_node("/root/GameState") and GameState.get_flag("tay_giai_phong")
	lines.append("CHIẾN ĐẤU PHÁP SƯ: %s — %s" % ["Đã mở" if mage_open else "Chưa mở (cần xong Phần 3)", MAGE_NOTE])
	for entry in MAGE_SKILLS:
		var sid: String = str(entry.get("id", ""))
		var unlocked: bool = has_node("/root/GameState") and GameState.is_skill_unlocked(sid)
		lines.append("%s: %s" % [str(entry.get("name", sid)), "Đã học" if unlocked else "Chưa học"])
	for n in MAGE_FUTURE_SKILLS:
		lines.append("%s: Chưa làm" % str(n))
	var dark_open: bool = has_node("/root/GameState") and GameState.get_flag("nam_giai_phong")
	lines.append("DẤU ẤN / THUẬT ĐEN: %s — %s" % ["Đã mở" if dark_open else "Chưa mở (cần xong Phần 2)", DARK_NOTE])
	for entry in DARK_SKILLS:
		var sid: String = str(entry.get("id", ""))
		var unlocked: bool = has_node("/root/GameState") and GameState.is_skill_unlocked(sid)
		lines.append("%s: %s" % [str(entry.get("name", sid)), "Đã học" if unlocked else "Chưa học"])
	for n in DARK_FUTURE_SKILLS:
		lines.append("%s: Chưa làm" % str(n))
	return "\n".join(lines)


func show_panel() -> void:
	refresh()
	visible = true
	_opened_msec = Time.get_ticks_msec()
	if has_node("/root/GameState"):
		GameState.in_dialogue = true


func hide_panel() -> void:
	visible = false
	if has_node("/root/GameState"):
		GameState.in_dialogue = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if Time.get_ticks_msec() - _opened_msec < 200:
		return
	if event.is_action_pressed("skill_tree") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide_panel()
