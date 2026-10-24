extends Node
## LeftUI (autoload) - Cum UI hai ben man hinh (dot lam lai UI):
##   - BEN TRAI (duoi cum HP/STA cua HUD): panel NHIEM VU + tien trinh,
##     nen la texture khung go/dong (panel_frame.png, nine-patch), logic
##     du lieu giu nguyen 100% tu QuestManager qua quest_tracker.gd.
##   - BEN PHAI (goc tren): MINIMAP TRON duong kinh 172px, vanh khung
##     cham khac (ring_frame.png) phu len tren, nut + / - doi nac zoom
##     (chi phong/thu NOI DUNG ban do trong khung, khung giu nguyen),
##     tieu de ten map + chu thich nho.
##   - Chi HIEN khi dang o trong map choi (scene res://maps/ + co player).
##     Phim M an/hien toan cum (doc keycode truc tiep, khong can action).
## Thanh phan: res://ui/minimap.gd (tron, tam nguoi choi) va
## res://ui/quest_tracker.gd (doc QuestManager that).

const MINIMAP_SCRIPT: Script = preload("res://ui/minimap.gd")
const TRACKER_SCRIPT: Script = preload("res://ui/quest_tracker.gd")
const INVENTORY_SCRIPT: Script = preload("res://ui/inventory_panel.gd")
const GUIDANCE_SCRIPT: Script = preload("res://ui/quest_guidance.gd")
const PANEL_TEX: Texture2D = preload("res://assets/ui/panel_frame.png")
const RING_TEX: Texture2D = preload("res://assets/ui/ring_frame.png")
const BTN_PLUS: Array[Texture2D] = [
	preload("res://assets/ui/btn_plus_normal.png"),
	preload("res://assets/ui/btn_plus_hover.png"),
	preload("res://assets/ui/btn_plus_pressed.png"),
]
const BTN_MINUS: Array[Texture2D] = [
	preload("res://assets/ui/btn_minus_normal.png"),
	preload("res://assets/ui/btn_minus_hover.png"),
	preload("res://assets/ui/btn_minus_pressed.png"),
]
const QUEST_LEFT := 10.0
const QUEST_TOP := 94.0 # ngay duoi cum HP/STA moi o goc tren-trai cua HUD
const QUEST_WIDTH := 264.0
const MAP_CLUSTER_W := 196.0
const MAP_SIZE := 172.0

var _layer: CanvasLayer = null
var _quest_panel: PanelContainer = null
var _map_cluster: Control = null
var _minimap: Control = null
var _tracker: Control = null
var _inventory: Control = null
var _guidance: Control = null
var _map_title: Label = null
var _user_hidden := false
var _map_root: Node = null
var _map_key := ""
var _poll := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	if has_node("/root/QuestManager"):
		QuestManager.quest_accepted.connect(_on_quest_signal)
		QuestManager.quest_updated.connect(_on_quest_signal)
		QuestManager.quest_completed.connect(_on_quest_signal)
	_apply_visibility(false)


func _panel_style(margin: float, content: float) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = PANEL_TEX
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = content
	sb.content_margin_top = content - 2.0
	sb.content_margin_right = content
	sb.content_margin_bottom = content - 2.0
	return sb


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "LeftUILayer"
	_layer.layer = 18
	add_child(_layer)
	_build_quest_panel()
	_build_map_cluster()
	_build_guidance()
	_build_inventory()


func _build_guidance() -> void:
	_guidance = GUIDANCE_SCRIPT.new()
	_guidance.name = "QuestGuidance"
	_layer.add_child(_guidance)
	_guidance.set_anchors_preset(Control.PRESET_FULL_RECT)


func _build_inventory() -> void:
	_inventory = INVENTORY_SCRIPT.new()
	_inventory.name = "InventoryPanel"
	_layer.add_child(_inventory)
	_inventory.set_anchors_preset(Control.PRESET_FULL_RECT)


func _build_quest_panel() -> void:
	_quest_panel = PanelContainer.new()
	_quest_panel.name = "QuestPanel"
	_quest_panel.anchor_left = 0.0
	_quest_panel.anchor_top = 0.0
	_quest_panel.anchor_right = 0.0
	_quest_panel.anchor_bottom = 0.0
	_quest_panel.offset_left = QUEST_LEFT
	_quest_panel.offset_top = QUEST_TOP
	_quest_panel.offset_right = QUEST_LEFT + QUEST_WIDTH
	_quest_panel.offset_bottom = QUEST_TOP
	_quest_panel.add_theme_stylebox_override("panel", _panel_style(32.0, 24.0))
	_layer.add_child(_quest_panel)
	_tracker = TRACKER_SCRIPT.new()
	_tracker.name = "QuestTracker"
	_tracker.custom_minimum_size = Vector2(QUEST_WIDTH - 48.0, 0)
	_quest_panel.add_child(_tracker)


func _make_zoom_button(textures: Array[Texture2D]) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = textures[0]
	b.texture_hover = textures[1]
	b.texture_pressed = textures[2]
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.custom_minimum_size = Vector2(32, 32)
	b.focus_mode = Control.FOCUS_NONE
	return b


func _build_map_cluster() -> void:
	_map_cluster = Control.new()
	_map_cluster.name = "MapCluster"
	_map_cluster.anchor_left = 1.0
	_map_cluster.anchor_right = 1.0
	_map_cluster.anchor_top = 0.0
	_map_cluster.anchor_bottom = 0.0
	_map_cluster.offset_left = -MAP_CLUSTER_W - 10.0
	_map_cluster.offset_right = -10.0
	_map_cluster.offset_top = 6.0
	_map_cluster.offset_bottom = 262.0
	_map_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_map_cluster)

	_map_title = Label.new()
	_map_title.text = "BẢN ĐỒ"
	_map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_map_title.add_theme_font_size_override("font_size", 12)
	_map_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_map_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_map_title.add_theme_constant_override("shadow_offset_x", 1)
	_map_title.add_theme_constant_override("shadow_offset_y", 1)
	_map_title.position = Vector2(0, 0)
	_map_title.size = Vector2(MAP_CLUSTER_W, 16)
	_map_cluster.add_child(_map_title)

	var map_x := (MAP_CLUSTER_W - MAP_SIZE) * 0.5
	_minimap = MINIMAP_SCRIPT.new()
	_minimap.name = "Minimap"
	_minimap.position = Vector2(map_x, 20)
	_minimap.size = Vector2(MAP_SIZE, MAP_SIZE)
	_map_cluster.add_child(_minimap)

	# Vanh khung tron trang tri phu len tren minimap (giua trong suot).
	var ring := TextureRect.new()
	ring.name = "MinimapRing"
	ring.texture = RING_TEX
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_SCALE
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.position = Vector2(map_x, 20)
	ring.size = Vector2(MAP_SIZE, MAP_SIZE)
	_map_cluster.add_child(ring)

	# Hang nut zoom: [-] [+] sat duoi vong tron.
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	hbox.position = Vector2(0, 198)
	hbox.size = Vector2(MAP_CLUSTER_W, 32)
	_map_cluster.add_child(hbox)
	var btn_minus := _make_zoom_button(BTN_MINUS)
	btn_minus.pressed.connect(func() -> void:
		if _minimap != null and _minimap.has_method("zoom_out"):
			_minimap.call("zoom_out"))
	hbox.add_child(btn_minus)
	var btn_plus := _make_zoom_button(BTN_PLUS)
	btn_plus.pressed.connect(func() -> void:
		if _minimap != null and _minimap.has_method("zoom_in"):
			_minimap.call("zoom_in"))
	hbox.add_child(btn_plus)

	var legend := Label.new()
	legend.text = "● Bạn  ● Cổng  ● Quest"
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.add_theme_font_size_override("font_size", 9)
	legend.add_theme_color_override("font_color", Color(0.8, 0.82, 0.76))
	legend.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	legend.add_theme_constant_override("shadow_offset_x", 1)
	legend.add_theme_constant_override("shadow_offset_y", 1)
	legend.position = Vector2(0, 234)
	legend.size = Vector2(MAP_CLUSTER_W, 14)
	_map_cluster.add_child(legend)

	var hint := Label.new()
	hint.text = "[M] ẩn/hiện • [I] túi đồ"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.62, 0.64, 0.58))
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 1)
	hint.position = Vector2(0, 248)
	hint.size = Vector2(MAP_CLUSTER_W, 12)
	_map_cluster.add_child(hint)


func _process(delta: float) -> void:
	_poll += delta
	if _poll < 0.6:
		return
	_poll = 0.0
	_check_scene()


func _check_scene() -> void:
	var root := _find_map_root()
	var in_game := root != null and not get_tree().get_nodes_in_group("player").is_empty()
	if not in_game:
		if _map_root != null:
			_map_root = null
			_map_key = ""
		_apply_visibility(false)
		return
	_apply_visibility(not _user_hidden)
	var key := str(root.get_instance_id()) + "|" + root.scene_file_path
	if key != _map_key:
		_map_key = key
		_map_root = root
		_rebuild(root)
	else:
		_map_root = root
	_fit_quest_panel()


func _rebuild(root: Node) -> void:
	if _map_title != null:
		var map_name := root.scene_file_path.get_file().get_basename()
		_map_title.text = "BẢN ĐỒ — " + map_name
	var player: Node2D = null
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Node2D:
		player = players[0]
	if _minimap != null and _minimap.has_method("rebuild"):
		_minimap.call("rebuild", root, player)
	if _guidance != null and _guidance.has_method("set_context"):
		_guidance.call("set_context", root, player)
	if _tracker != null and _tracker.has_method("refresh"):
		_tracker.call("refresh")
	_fit_quest_panel()


## Chieu cao panel nhiem vu = le noi dung stylebox (14+14) + chieu cao
## chu that cua tracker (min-size Label thieu dong khi text xuong dong).
func _fit_quest_panel() -> void:
	if _quest_panel == null or _tracker == null:
		return
	var th := 0.0
	if _tracker.has_method("content_height"):
		th = float(_tracker.call("content_height"))
	if th <= 0.0:
		th = _tracker.get_combined_minimum_size().y
	_quest_panel.size = Vector2(QUEST_WIDTH, 48.0 + th)


func _find_map_root() -> Node:
	var cs: Node = get_tree().current_scene
	if cs != null and cs.scene_file_path.begins_with("res://maps/"):
		return cs
	if _map_root != null and is_instance_valid(_map_root) and _map_root.is_inside_tree():
		return _map_root
	var stack: Array[Node] = []
	for c in get_tree().root.get_children():
		stack.append(c)
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n == self or n == _layer:
			continue
		if n.scene_file_path.begins_with("res://maps/"):
			return n
		for c in n.get_children():
			stack.append(c)
	return null


func _apply_visibility(v: bool) -> void:
	if _layer != null:
		_layer.visible = v
	if _guidance != null and _guidance.has_method("set_ui_visible"):
		_guidance.call("set_ui_visible", v)
	# An toan cum: an UI (phim M / roi map) thi dong luon panel tui do,
	# tranh ket GameState.in_dialogue=true khi panel khong con nhin thay.
	if not v and _inventory != null and _inventory.visible and _inventory.has_method("close_panel"):
		_inventory.call("close_panel")


func is_left_ui_visible() -> bool:
	return _layer != null and _layer.visible


func get_minimap() -> Control:
	return _minimap


func get_quest_tracker() -> Control:
	return _tracker


func get_inventory_panel() -> Control:
	return _inventory


func get_guidance() -> Control:
	return _guidance


## Phim I: mo/dong panel tui do + trang bi (chi khi dang trong map choi).
func _toggle_inventory() -> void:
	if _inventory == null:
		return
	if _inventory.visible:
		_inventory.call("close_panel")
		return
	var root := _find_map_root()
	var in_game := root != null and not get_tree().get_nodes_in_group("player").is_empty()
	if not in_game:
		return
	_user_hidden = false
	_apply_visibility(true)
	_inventory.call("open_panel")


func _on_quest_signal(_quest_id: String) -> void:
	if _tracker != null and _tracker.has_method("refresh"):
		_tracker.call("refresh")
	if _map_root != null and is_instance_valid(_map_root) and _layer != null and _layer.visible:
		_rebuild(_map_root)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and (k.keycode == KEY_M or k.physical_keycode == KEY_M):
			_user_hidden = not _user_hidden
			var root := _find_map_root()
			var in_game := root != null and not get_tree().get_nodes_in_group("player").is_empty()
			_apply_visibility(in_game and not _user_hidden)
			get_viewport().set_input_as_handled()
		elif k.pressed and not k.echo and (k.keycode == KEY_I or k.physical_keycode == KEY_I):
			_toggle_inventory()
			get_viewport().set_input_as_handled()
