extends Control
## InventoryPanel - Man hinh TUI DO + TRANG BI (worker B).
## Xay hoan toan bang code trong _ready (nhu left_panel.gd), extends
## Control anchor full-rect, mac dinh AN (visible = false). Coordinator
## (LeftUI) giu nhiem vu tao/gan panel nay va goi open/close/toggle.
##
## API cho coordinator:
##   open_panel()   - hien panel, GameState.in_dialogue = true, refresh.
##   close_panel()  - an panel, GameState.in_dialogue = false.
##                    (KHONG queue_free nhu CraftPanel: panel nay dung
##                    lai nhieu lan qua toggle.)
##   toggle_panel() - dang mo thi dong, dang dong thi mo.
##   refresh()      - dung lai noi dung tu GameState (test goi duoc).
## Tu xu ly ESC de dong trong _unhandled_input (chi khi visible).
##
## Du lieu doc theo HOP DONG GameState (worker A):
##   equipment_items: Array[Dictionary{uid,name,slot,atk,def}]
##   equipped_uids:   Dictionary{weapon: uid, armor: uid}
##   equip_item(uid) -> bool, get_equipped_item(slot) -> Dictionary
##   attack_bonus / defense_bonus, signal equipment_changed.
## Doc cac truong trang bi qua get()/call() + has_method/has_signal de
## panel khong vo khi chay chung voi save/build cu thieu API moi.
##
## Nut "Dung" binh: HOI MAU THAT theo dung duong player.gd dang dung
## cho phim H (_try_use_potion, player.gd): tru binh qua
## GameState.use_potion() / use_greater_potion() ROI player.heal(50/150).
## Hai nut tach rieng tung loai binh (khong goi nguyen _try_use_potion
## cho ca hai, vi ham do tu uu tien dai binh khi mau hut >= 90 — bam
## nut "Binh mau" ma bi tru dai binh thi sai nhan nut).

const PANEL_TEX: Texture2D = preload("res://assets/ui/panel_frame.png")
const PANEL_W := 680.0
const PANEL_H := 500.0
const POTION_HEAL := 50 # khop player.gd _try_use_potion: heal(50)
const GREATER_POTION_HEAL := 150 # khop player.gd: heal(150)

const COLOR_TITLE := Color(1.0, 0.85, 0.4)
const COLOR_TEXT := Color(0.96, 0.92, 0.82)
const COLOR_MUTED := Color(0.78, 0.76, 0.68)
const COLOR_SECTION := Color(1.0, 0.78, 0.45)

var _weapon_item_label: Label = null
var _armor_item_label: Label = null
var _totals_label: Label = null
var _item_box: VBoxContainer = null
var _gold_label: Label = null
var _hp_label: Label = null
var _potion_label: Label = null
var _greater_label: Label = null
var _herb_label: Label = null
var _core_label: Label = null
var _potion_use_btn: Button = null
var _greater_use_btn: Button = null


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# set_anchors_preset giu nguyen rect hien tai (0x0 khi vua add vao
	# CanvasLayer) -> phai dua offset ve 0 thi rect moi bang viewport.
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_connect_signals()
	refresh()


# --- Xay UI bang code -------------------------------------------------------

func _panel_style() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = PANEL_TEX
	sb.texture_margin_left = 32.0
	sb.texture_margin_top = 32.0
	sb.texture_margin_right = 32.0
	sb.texture_margin_bottom = 32.0
	sb.content_margin_left = 22.0
	sb.content_margin_top = 16.0
	sb.content_margin_right = 22.0
	sb.content_margin_bottom = 16.0
	return sb


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	# KHONG bat autowrap: Label autowrap trong Container bao min-height
	# theo be rong toi thieu (~1px) -> panel phinh cao hang nghin px.
	# Cac dong trong panel nay deu ngan, 1 dong la du.
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


func _make_section_label(text: String) -> Label:
	return _make_label(text, 15, COLOR_SECTION)


func _make_use_button() -> Button:
	var b := Button.new()
	b.text = "Dùng"
	b.custom_minimum_size = Vector2(64, 0)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 14)
	return b


func _build_ui() -> void:
	# Nen mo full man hinh: chan click ra ngoai panel khi dang mo.
	# Khi panel an (visible = false) thi toan bo cay an theo, khong
	# chan input cua game.
	var dim := ColorRect.new()
	dim.name = "DimBackground"
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "InventoryPanelContainer"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -PANEL_W * 0.5
	panel.offset_top = -PANEL_H * 0.5
	panel.offset_right = PANEL_W * 0.5
	panel.offset_bottom = PANEL_H * 0.5
	panel.custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	panel.add_child(root_vbox)

	# --- Hang tieu de + nut Dong ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root_vbox.add_child(header)
	var title := _make_label("TÚI ĐỒ & TRANG BỊ", 20, COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "Đóng"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(close_panel)
	header.add_child(close_btn)

	# --- Than panel: 2 cot ---
	var main_hbox := HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 14)
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(main_hbox)

	_build_equipment_column(main_hbox)
	_build_bag_column(main_hbox)

	var hint := _make_label("Bấm vào món đồ trong danh sách để mặc. Bình máu hồi 50 HP, Đại Bình hồi 150 HP. [ESC] đóng.", 11, COLOR_MUTED)
	root_vbox.add_child(hint)


func _build_equipment_column(parent: Container) -> void:
	var col := VBoxContainer.new()
	col.name = "EquipmentColumn"
	col.add_theme_constant_override("separation", 6)
	col.custom_minimum_size = Vector2(378, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)

	col.add_child(_make_section_label("TRANG BỊ ĐANG MẶC"))

	col.add_child(_make_label("Vũ khí:", 14, COLOR_TEXT))
	_weapon_item_label = _make_label("— Chưa có —", 14, COLOR_MUTED)
	col.add_child(_weapon_item_label)

	col.add_child(_make_label("Giáp:", 14, COLOR_TEXT))
	_armor_item_label = _make_label("— Chưa có —", 14, COLOR_MUTED)
	col.add_child(_armor_item_label)

	_totals_label = _make_label("", 15, COLOR_TITLE)
	col.add_child(_totals_label)

	var sep := HSeparator.new()
	col.add_child(sep)

	col.add_child(_make_section_label("ĐỒ SỞ HỮU — bấm để mặc"))

	var scroll := ScrollContainer.new()
	scroll.name = "ItemScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	_item_box = VBoxContainer.new()
	_item_box.name = "ItemList"
	_item_box.add_theme_constant_override("separation", 4)
	_item_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_item_box)


func _build_bag_column(parent: Container) -> void:
	var col := VBoxContainer.new()
	col.name = "BagColumn"
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(216, 0)
	parent.add_child(col)

	col.add_child(_make_section_label("TÚI ĐỒ"))

	_gold_label = _make_label("", 15, COLOR_TITLE)
	col.add_child(_gold_label)

	_hp_label = _make_label("", 14, COLOR_TEXT)
	col.add_child(_hp_label)

	# Binh mau thuong + nut Dung
	var potion_row := HBoxContainer.new()
	potion_row.add_theme_constant_override("separation", 8)
	col.add_child(potion_row)
	_potion_label = _make_label("", 14, COLOR_TEXT)
	_potion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	potion_row.add_child(_potion_label)
	_potion_use_btn = _make_use_button()
	_potion_use_btn.name = "UsePotionButton"
	_potion_use_btn.pressed.connect(_on_use_potion_pressed)
	potion_row.add_child(_potion_use_btn)

	# Dai binh + nut Dung
	var greater_row := HBoxContainer.new()
	greater_row.add_theme_constant_override("separation", 8)
	col.add_child(greater_row)
	_greater_label = _make_label("", 14, COLOR_TEXT)
	_greater_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	greater_row.add_child(_greater_label)
	_greater_use_btn = _make_use_button()
	_greater_use_btn.name = "UseGreaterPotionButton"
	_greater_use_btn.pressed.connect(_on_use_greater_pressed)
	greater_row.add_child(_greater_use_btn)

	_herb_label = _make_label("", 14, COLOR_TEXT)
	col.add_child(_herb_label)

	_core_label = _make_label("", 14, COLOR_TEXT)
	col.add_child(_core_label)


func _connect_signals() -> void:
	if not has_node("/root/GameState"):
		return
	GameState.gold_changed.connect(func(_g: int) -> void: refresh())
	GameState.potions_changed.connect(func(_n: int) -> void: refresh())
	GameState.materials_changed.connect(func(_m: Dictionary) -> void: refresh())
	if GameState.has_signal("equipment_changed"):
		GameState.equipment_changed.connect(func() -> void: refresh())
	if GameState.has_signal("stats_changed"):
		GameState.stats_changed.connect(func(_a: int, _d: int) -> void: refresh())
	if GameState.has_signal("player_hp_changed"):
		GameState.player_hp_changed.connect(func(_hp: int, _max_hp: int) -> void: refresh())
	if GameState.has_signal("level_changed"):
		GameState.level_changed.connect(func(_l: int) -> void: refresh())


# --- API cho coordinator -----------------------------------------------------

func open_panel() -> void:
	visible = true
	if has_node("/root/GameState"):
		GameState.in_dialogue = true
	refresh()
	print("[InventoryPanel] Mở túi đồ / trang bị.")


func close_panel() -> void:
	visible = false
	if has_node("/root/GameState"):
		GameState.in_dialogue = false
	print("[InventoryPanel] Đóng túi đồ / trang bị.")


func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()


## Alias theo khuon show/hide cua quest_log_panel / skill_panel.
func show_panel() -> void:
	open_panel()


func hide_panel() -> void:
	close_panel()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var is_esc := event.is_action_pressed("ui_cancel")
	if not is_esc and event is InputEventKey:
		var k := event as InputEventKey
		is_esc = k.pressed and not k.echo and k.keycode == KEY_ESCAPE
	if is_esc:
		get_viewport().set_input_as_handled()
		close_panel()


# --- Doc du lieu trang bi (theo hop dong worker A, doc phong thu) -----------

func _equipment_items() -> Array:
	if not has_node("/root/GameState"):
		return []
	var v: Variant = GameState.get("equipment_items")
	return v if v is Array else []


func _equipped_uids() -> Dictionary:
	if not has_node("/root/GameState"):
		return {}
	var v: Variant = GameState.get("equipped_uids")
	return v if v is Dictionary else {}


func _find_item(uid: String) -> Dictionary:
	for item in _equipment_items():
		if item is Dictionary and str(item.get("uid", "")) == uid:
			return item
	return {}


func _get_equipped_item(slot: String) -> Dictionary:
	if has_node("/root/GameState") and GameState.has_method("get_equipped_item"):
		var v: Variant = GameState.call("get_equipped_item", slot)
		if v is Dictionary and not (v as Dictionary).is_empty():
			return v
	var uid := str(_equipped_uids().get(slot, ""))
	if uid != "":
		return _find_item(uid)
	return {}


func _is_equipped(item: Dictionary) -> bool:
	var uid := str(item.get("uid", ""))
	if uid == "":
		return false
	for equipped_uid in _equipped_uids().values():
		if str(equipped_uid) == uid:
			return true
	var slot := str(item.get("slot", ""))
	if slot != "":
		var equipped := _get_equipped_item(slot)
		if not equipped.is_empty() and str(equipped.get("uid", "")) == uid:
			return true
	return false


func _stats_text(item: Dictionary) -> String:
	return "(+%d ATK, +%d DEF)" % [int(item.get("atk", 0)), int(item.get("def", 0))]


func _slot_text(slot: String) -> String:
	var item := _get_equipped_item(slot)
	if item.is_empty():
		return "— Chưa có —"
	return "%s %s" % [str(item.get("name", "?")), _stats_text(item)]


# --- Player / mau -------------------------------------------------------------

func _get_player() -> Node:
	if not is_inside_tree():
		return null
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if not players.is_empty() else null


## Tra [hp, max_hp, lay_duoc_khong]. Uu tien doc thang tu player (group
## "player"); khong co player thi lui ve GameState.player_hp da dong bo.
func _player_hp_info() -> Array:
	var p := _get_player()
	if p != null:
		var hp_v: Variant = p.get("hp")
		var max_v: Variant = p.get("max_hp")
		if hp_v != null and max_v != null:
			return [int(hp_v), int(max_v), true]
	if has_node("/root/GameState"):
		return [GameState.player_hp, GameState.player_max_hp, true]
	return [0, 0, false]


# --- Refresh -------------------------------------------------------------------

func refresh() -> void:
	if not is_node_ready() or _item_box == null:
		return
	if not has_node("/root/GameState"):
		return
	# (a) Cot trang bi dang mac + tong chi so.
	_weapon_item_label.text = _slot_text("weapon")
	_armor_item_label.text = _slot_text("armor")
	var total_atk: int = 10 + GameState.attack_bonus + (GameState.level - 1) * 2
	_totals_label.text = "ATK: %d (đồ +%d) — DEF: %d" % [
		total_atk, GameState.attack_bonus, GameState.defense_bonus]
	# (b) Danh sach do so huu.
	_rebuild_item_list()
	# (c) Cot tui do.
	_gold_label.text = "Vàng: %d" % GameState.gold
	var hp_info := _player_hp_info()
	if bool(hp_info[2]):
		_hp_label.text = "Máu: %d / %d" % [int(hp_info[0]), int(hp_info[1])]
	else:
		_hp_label.text = "Máu: —"
	_potion_label.text = "Bình máu ×%d" % GameState.potions
	_greater_label.text = "Đại Bình Hồi Phục ×%d" % GameState.greater_potions
	_herb_label.text = "Thảo dược ×%d" % int(GameState.materials.get("herb", 0))
	_core_label.text = "Lõi Quái ×%d" % int(GameState.materials.get("monster_core", 0))
	var hp_full: bool = bool(hp_info[2]) and int(hp_info[1]) > 0 and int(hp_info[0]) >= int(hp_info[1])
	_potion_use_btn.disabled = GameState.potions <= 0 or hp_full
	_greater_use_btn.disabled = GameState.greater_potions <= 0 or hp_full


## Alias noi bo theo khuon _refresh cua cac panel khac.
func _refresh() -> void:
	refresh()


func _rebuild_item_list() -> void:
	for c in _item_box.get_children():
		_item_box.remove_child(c)
		c.queue_free()
	var items := _equipment_items()
	if items.is_empty():
		var empty_label := _make_label(
			"Chưa có trang bị nào — đánh quái/mở rương để nhặt.", 13, COLOR_MUTED)
		_item_box.add_child(empty_label)
		return
	for item in items:
		if not (item is Dictionary):
			continue
		var uid := str(item.get("uid", ""))
		var btn := Button.new()
		btn.name = "Equip_" + (uid if uid != "" else str(item.get("name", "item")))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 14)
		btn.text = "%s %s" % [str(item.get("name", "?")), _stats_text(item)]
		if _is_equipped(item):
			btn.text += " • Đang mặc"
		var captured_uid: String = uid
		btn.pressed.connect(func() -> void: _on_item_pressed(captured_uid))
		_item_box.add_child(btn)


func _on_item_pressed(uid: String) -> void:
	if uid == "" or not has_node("/root/GameState"):
		return
	if GameState.has_method("equip_item"):
		if bool(GameState.call("equip_item", uid)):
			print("[InventoryPanel] Đã mặc món uid=%s." % uid)
	# equipment_changed (neu co) cung se refresh; refresh truc tiep de
	# panel cap nhat ngay ca khi signal chua kip noi.
	refresh()


# --- Dung binh (hoi mau that qua player.heal, nhu player.gd phim H) ----------

func _on_use_potion_pressed() -> void:
	_use_potion_kind(false)


func _on_use_greater_pressed() -> void:
	_use_potion_kind(true)


func _use_potion_kind(greater: bool) -> void:
	if not has_node("/root/GameState"):
		return
	var p := _get_player()
	if p == null:
		# Khong co player trong scene thi khong tru binh — tru ma khong
		# hoi duoc mau la mat binh oan.
		print("[InventoryPanel] Không tìm thấy player — không dùng bình.")
		return
	var hp_info := _player_hp_info()
	if bool(hp_info[2]) and int(hp_info[1]) > 0 and int(hp_info[0]) >= int(hp_info[1]):
		print("[InventoryPanel] Máu đã đầy, không cần dùng bình.")
		return
	if p.has_method("heal"):
		var consumed := false
		if greater:
			consumed = GameState.use_greater_potion()
			if consumed:
				p.call("heal", GREATER_POTION_HEAL)
		else:
			consumed = GameState.use_potion()
			if consumed:
				p.call("heal", POTION_HEAL)
		if not consumed:
			print("[InventoryPanel] Hết %s!" % ("đại bình" if greater else "bình máu"))
	elif not greater and p.has_method("_try_use_potion"):
		# Duong du phong (player ban nay luon co heal nen gan nhu khong
		# bao gio chay): goi dung ham player dang dung cho phim H, ham
		# do tu tru binh + tu hoi mau.
		p.call("_try_use_potion")
	else:
		print("[InventoryPanel] Player không có cách hồi máu — không dùng bình.")
	refresh()
