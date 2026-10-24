extends Node
## LeftUI (autoload) - Cum UI BEN TRAI man hinh: MINIMAP + O NHIEM VU.
## File moi rieng, khong dung vao hud.gd/hud.tscn:
##   - Tu dung CanvasLayer (layer 18) + PanelContainer bang code, giong
##     mau HUD preload quest_log_panel bang code.
##   - Vi tri: trai man hinh, offset tren = 120px (duoi khoi text goc
##     trai-tren cua HUD, HUD MarginContainer cao toi ~140 nhung text
##     thuc te o tren cung; cum nay rong 252px nen khong de len noi dung
##     giua man hinh), tong rong ~252px, nen ban trong suot.
##   - Chi HIEN khi dang o trong map choi: scene hien tai thuoc
##     res://maps/ HOAC co mot node goc scene res://maps/ trong cay
##     (truong hop capture scene instance map lam con) VA co node group
##     "player". AN o main menu / scene test khong co map that.
##   - Phim an/hien toan cum: M (doc keycode truc tiep trong
##     _unhandled_input, KHONG can them action vao project.godot [input]).
## Thanh phan: res://ui/minimap.gd (Minimap ve tu TileMap that) va
## res://ui/quest_tracker.gd (doc QuestManager that).

const MINIMAP_SCRIPT: Script = preload("res://ui/minimap.gd")
const TRACKER_SCRIPT: Script = preload("res://ui/quest_tracker.gd")
const PANEL_LEFT := 10.0
const PANEL_TOP := 120.0
const PANEL_WIDTH := 252.0

var _layer: CanvasLayer = null
var _root_panel: PanelContainer = null
var _minimap: Control = null
var _tracker: Control = null
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


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "LeftUILayer"
	_layer.layer = 18
	add_child(_layer)
	_root_panel = PanelContainer.new()
	_root_panel.name = "LeftPanel"
	_root_panel.anchor_left = 0.0
	_root_panel.anchor_top = 0.0
	_root_panel.anchor_right = 0.0
	_root_panel.anchor_bottom = 0.0
	_root_panel.offset_left = PANEL_LEFT
	_root_panel.offset_top = PANEL_TOP
	_root_panel.offset_right = PANEL_LEFT + PANEL_WIDTH
	_root_panel.offset_bottom = PANEL_TOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.05, 0.78)
	sb.border_color = Color(0.85, 0.72, 0.4, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	_root_panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(_root_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	vbox.custom_minimum_size = Vector2(PANEL_WIDTH - 16.0, 0)
	_root_panel.add_child(vbox)

	_map_title = Label.new()
	_map_title.text = "BẢN ĐỒ"
	_map_title.add_theme_font_size_override("font_size", 13)
	_map_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox.add_child(_map_title)

	_minimap = MINIMAP_SCRIPT.new()
	_minimap.name = "Minimap"
	_minimap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(_minimap)

	var legend := Label.new()
	legend.text = "● Bạn  ■ Cổng  ● Quest  [M] ẩn/hiện"
	legend.add_theme_font_size_override("font_size", 10)
	legend.add_theme_color_override("font_color", Color(0.75, 0.78, 0.72))
	vbox.add_child(legend)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_tracker = TRACKER_SCRIPT.new()
	_tracker.name = "QuestTracker"
	vbox.add_child(_tracker)


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
	# PanelContainer tu co theo noi dung (min size) vi offset_bottom = top.
	if _root_panel != null:
		_root_panel.size = _root_panel.get_combined_minimum_size()


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
	if _tracker != null and _tracker.has_method("refresh"):
		_tracker.call("refresh")
	if _root_panel != null:
		_root_panel.size = _root_panel.get_combined_minimum_size()


func _find_map_root() -> Node:
	var cs: Node = get_tree().current_scene
	if cs != null and cs.scene_file_path.begins_with("res://maps/"):
		return cs
	if _map_root != null and is_instance_valid(_map_root) and _map_root.is_inside_tree():
		return _map_root
	# Capture / test scene instance map lam node con: tim node goc scene map.
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


func is_left_ui_visible() -> bool:
	return _layer != null and _layer.visible


func get_minimap() -> Control:
	return _minimap


func get_quest_tracker() -> Control:
	return _tracker


func _on_quest_signal(_quest_id: String) -> void:
	if _tracker != null and _tracker.has_method("refresh"):
		_tracker.call("refresh")
	# Diem quest tren minimap phu thuoc quest dang active: dung lai hinh.
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
