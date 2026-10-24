extends VBoxContainer
## QuestTracker - O nhiem vu / tien trinh trong cum UI ben trai.
## Du lieu THAT tu autoload QuestManager (khong sua quest_manager.gd):
##   - QuestManager.active_quests : Array[String] cac quest dang nhan
##     (ngoai ra quet them QuestManager.quests de bat ca quest
##     "ready_turn_in" bi xoa khoi active_quests o nhanh complete_on_accept).
##   - QuestManager.get_quest(id) -> Dictionary, cac key dung o day:
##     "title" (ten), "description" (dong muc tieu), "progress" (so dem
##     hien tai), "target_count" (so dem can dat), "status"
##     ("active" | "ready_turn_in"), "quest_type" ("main" | "side"),
##     "turn_in_npc" (npc can gap de tra khi ready_turn_in).
## Quest chinh dang theo doi = uu tien ready_turn_in, sau do quest_type
## "main", sau do quest dau tien trong danh sach.

var _main_label: Label = null
var _list_label: Label = null


func _ready() -> void:
	add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.text = "— NHIỆM VỤ —"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	add_child(title)
	_main_label = Label.new()
	_main_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_main_label.add_theme_font_size_override("font_size", 12)
	_main_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.88))
	add_child(_main_label)
	_list_label = Label.new()
	_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list_label.add_theme_font_size_override("font_size", 12)
	_list_label.add_theme_color_override("font_color", Color(0.78, 0.85, 0.9))
	add_child(_list_label)
	refresh()


## Danh sach id quest dang theo doi (active + ready_turn_in), khong trung.
func tracked_quest_ids() -> Array[String]:
	var out: Array[String] = []
	if not has_node("/root/QuestManager"):
		return out
	for qid in QuestManager.active_quests:
		var q: Dictionary = QuestManager.get_quest(qid)
		var st := str(q.get("status", ""))
		if (st == "active" or st == "ready_turn_in") and not out.has(qid):
			out.append(qid)
	for qid in QuestManager.quests.keys():
		var sid := str(qid)
		var q2: Dictionary = QuestManager.quests[qid]
		var st2 := str(q2.get("status", ""))
		if (st2 == "active" or st2 == "ready_turn_in") and not out.has(sid):
			out.append(sid)
	return out


## Chon quest chinh: ready_turn_in truoc, roi "main", roi phan tu dau.
func tracked_main_quest_id() -> String:
	var ids := tracked_quest_ids()
	if ids.is_empty() or not has_node("/root/QuestManager"):
		return ""
	for qid in ids:
		var q: Dictionary = QuestManager.get_quest(qid)
		if str(q.get("status", "")) == "ready_turn_in":
			return qid
	for qid in ids:
		var q: Dictionary = QuestManager.get_quest(qid)
		if str(q.get("quest_type", "")) == "main":
			return qid
	return ids[0]


func _quest_line(qid: String) -> String:
	var q: Dictionary = QuestManager.get_quest(qid)
	var title := str(q.get("title", qid))
	if str(q.get("status", "")) == "ready_turn_in":
		return "%s (chờ trả: %s)" % [title, str(q.get("turn_in_npc", ""))]
	return "%s (%d/%d)" % [title, int(q.get("progress", 0)), int(q.get("target_count", 0))]


## Noi dung day du dang text thuan (test / capture goi duoc khi UI an).
func build_tracker_text() -> String:
	var ids := tracked_quest_ids()
	if ids.is_empty():
		return "Chưa có nhiệm vụ đang làm.\nGặp NPC trong làng để nhận nhiệm vụ."
	var main_id := tracked_main_quest_id()
	var q: Dictionary = QuestManager.get_quest(main_id)
	var lines: Array[String] = []
	lines.append("★ " + _quest_line(main_id))
	if str(q.get("status", "")) == "ready_turn_in":
		lines.append("  ✓ Đủ tiến độ — quay lại gặp: " + str(q.get("turn_in_npc", "")))
	else:
		var desc := str(q.get("description", ""))
		if desc != "":
			lines.append("  " + desc)
	for qid in ids:
		if qid == main_id:
			continue
		lines.append("• " + _quest_line(qid))
	return "\n".join(lines)


## Chieu cao noi dung THAT tai be rong hien tai (panel cha dung so nay de
## co chieu cao, vi min-size cua Label khong tinh du dong khi xuong dong).
func content_height() -> float:
	var h := 0.0
	var visible_count := 0
	for c in get_children():
		if c is Label and (c as Label).visible:
			var lbl := c as Label
			var font := lbl.get_theme_font("font")
			var fs := lbl.get_theme_font_size("font_size")
			if font != null:
				h += float(lbl.get_line_count()) * font.get_height(fs)
			visible_count += 1
	if visible_count > 1:
		h += float(get_theme_constant("separation")) * float(visible_count - 1)
	return h


func refresh() -> void:
	if _main_label == null:
		return
	var ids := tracked_quest_ids()
	if ids.is_empty():
		_main_label.text = "Chưa có nhiệm vụ đang làm."
		_list_label.text = "Gặp NPC trong làng để nhận nhiệm vụ."
		return
	var main_id := tracked_main_quest_id()
	var q: Dictionary = QuestManager.get_quest(main_id)
	_main_label.text = "★ " + _quest_line(main_id)
	if str(q.get("status", "")) == "ready_turn_in":
		_main_label.text += "\n  ✓ Đủ tiến độ — quay lại gặp: " + str(q.get("turn_in_npc", ""))
	else:
		var desc := str(q.get("description", ""))
		if desc != "":
			_main_label.text += "\n  " + desc
	var others: Array[String] = []
	for qid in ids:
		if qid != main_id:
			others.append("• " + _quest_line(qid))
	_list_label.text = "\n".join(others)
	_list_label.visible = not others.is_empty()
