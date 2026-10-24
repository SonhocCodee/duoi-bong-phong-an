extends CanvasLayer
## CraftPanel - Bàn chế tạo / giả kim (Đợt 6, crafting MỨC CƠ BẢN).
## Mở từ CraftStation (lò rèn / bàn giả kim ở các hub). Danh sách công
## thức lấy từ GameState.CRAFT_RECIPES — nguồn số liệu duy nhất; chế qua
## GameState.craft() (tự kiểm tra nguyên liệu/vàng/đồ 1 lần).
## Đóng bằng nút Đóng hoặc Esc. Khi mở: khóa di chuyển của player
## (GameState.in_dialogue, cùng khuôn ShopPanel).

signal craft_closed

var _opened_msec: int = 0
var _recipe_rows: Dictionary = {} # recipe_id -> Button

@onready var materials_label: Label = $CenterContainer/PanelContainer/VBoxContainer/MaterialsLabel
@onready var recipe_box: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/RecipeBox
@onready var close_button: Button = $CenterContainer/PanelContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	close_button.pressed.connect(close_panel)
	if has_node("/root/GameState"):
		GameState.materials_changed.connect(func(_m: Dictionary) -> void: _refresh())
		GameState.gold_changed.connect(func(_g: int) -> void: _refresh())
	_build_rows()
	_refresh()


func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in cost.keys():
		var label := str(key)
		if label == "herb":
			label = "Thảo"
		elif label == "monster_core":
			label = "Lõi Quái"
		elif label == "gold":
			label = "Vàng"
		parts.append("%s ×%d" % [label, int(cost[key])])
	return ", ".join(parts)


func _build_rows() -> void:
	if recipe_box == null or not has_node("/root/GameState"):
		return
	for c in recipe_box.get_children():
		c.queue_free()
	_recipe_rows.clear()
	for r in GameState.CRAFT_RECIPES:
		var rid: String = str(r.get("id", ""))
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var lbl := Label.new()
		lbl.text = "%s — %s" % [str(r.get("name", rid)), str(r.get("desc", ""))]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(lbl)
		var btn := Button.new()
		btn.name = "Craft_" + rid
		btn.add_theme_font_size_override("font_size", 14)
		var captured: String = rid
		btn.pressed.connect(func() -> void:
			if GameState.craft(captured):
				_refresh())
		row.add_child(btn)
		recipe_box.add_child(row)
		_recipe_rows[rid] = btn


func _refresh() -> void:
	if not is_node_ready() or not has_node("/root/GameState"):
		return
	materials_label.text = "Nguyên liệu: Thảo ×%d | Lõi Quái ×%d | Vàng: %d" % [
		GameState.get_material("herb"), GameState.get_material("monster_core"), GameState.gold]
	for r in GameState.CRAFT_RECIPES:
		var rid: String = str(r.get("id", ""))
		if not _recipe_rows.has(rid):
			continue
		var btn: Button = _recipe_rows[rid]
		var once: String = str(r.get("once_flag", ""))
		if once != "" and GameState.get_flag(once):
			btn.text = "Đã chế (duy nhất 1 lần)"
			btn.disabled = true
		elif GameState.can_craft(rid):
			btn.text = "Chế tạo (%s)" % _cost_text(r.get("cost", {}))
			btn.disabled = false
		else:
			btn.text = "Thiếu nguyên liệu (%s)" % _cost_text(r.get("cost", {}))
			btn.disabled = true


func open_craft() -> void:
	visible = true
	_opened_msec = Time.get_ticks_msec()
	if has_node("/root/GameState"):
		GameState.in_dialogue = true
	_refresh()
	print("[CraftPanel] Mở bàn chế tạo.")


func close_panel() -> void:
	visible = false
	if has_node("/root/GameState"):
		GameState.in_dialogue = false
	craft_closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if Time.get_ticks_msec() - _opened_msec < 250:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_panel()
