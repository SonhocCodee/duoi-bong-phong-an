extends Control
## QuestGuidance - Mui ten chi duong toi muc tieu quest CHINH dang active.
## File moi (Worker C), chua duoc scene nao tham chieu: LeftUI (coordinator)
## se tao instance, goi set_context(root, player) moi khi doi map va
## set_ui_visible(v) de dong bo an/hien voi phim M (cum LeftUI).
##
## Co che dich (tinh lai moi 0.2s + ngay khi QuestManager phat signal
## quest_accepted / quest_updated / quest_completed):
##   - Quet QuestManager.quests theo thu tu khoa (thu tu dang ky), lay quest
##     DAU TIEN co quest_type == "main" va status "active"/"ready_turn_in".
##     Chi xet dung quest do: dich khong o map hien tai thi khong co dich,
##     KHONG nhay sang quest chinh tiep theo.
##   - Neu status == "ready_turn_in", hoac (progress >= target_count va
##     requires_turn_in): dich = node NPC trong root hien tai co
##     npc_id == turn_in_npc (script res://systems/npc.gd). Giu THAM CHIEU
##     node va doc global_position truc tiep moi frame vi NPC di chuyen
##     theo lich trinh (schedule).
##   - Nguoc lai, neu target_type != "": dich = quai gan player nhat trong
##     group "enemy" thuoc root, enemy_type khop, UU TIEN quai con song
##     (hp > 0 va state != DEAD cua enemy_base). Khong con con song nao
##     thi lay node quai khop gan nhat con ton tai (diem spawn / xac dang
##     cho respawn) — van giu tham chieu node do.
##   - Nguoc lai, neu collect_type != "": dich = node HerbPickup gan nhat
##     trong root (script res://systems/herb_pickup.gd, item_id khop
##     collect_type, vd "herb"). Day la co che nhat do duy nhat trong game.
##   - Cac truong hop con lai (quest chi co target_map, complete_on_accept
##     chua du tien do, ...), hoac node dich khong ton tai trong root hien
##     tai (dich o map khac): KHONG co dich -> an mui ten.
##
## Hien thi: Control full-rect, mouse_filter IGNORE toan bo (ke ca con).
## Mui ten la Control con tu ve bang _draw() (tam giac vang vien sam,
## ~46px), dat tai tam viewport + huong toi dich x ban kinh 120px,
## rotation theo goc toi dich. Label con (khong xoay theo mui ten) nam
## duoi mui ten, hien khoang cach "%d o" (1 o = 64px, Euclid, lam tron).
## Dich gan hon ~1.5 o (96px) -> an (coi nhu da toi).
## Tu an khi: khong co dich / dang hoi thoai (GameState.in_dialogue) /
## set_ui_visible(false) / root hoac player null. Node dich bi freed ->
## tinh lai dich ngay o lan quet ke tiep (toi da 0.2s).

const NPC_SCRIPT := "res://systems/npc.gd"
const HERB_SCRIPT := "res://systems/herb_pickup.gd"
const ENEMY_DEAD_STATE := 3 # enemy_base.gd: enum State { IDLE, CHASE, ATTACK, DEAD }
const CELL_PX := 64.0 # 1 o = 64px de quy doi khoang cach
const ARROW_RADIUS := 120.0 # ban kinh dat mui ten quanh tam viewport
const ARRIVE_DIST := 96.0 # ~1.5 o: gan hon thi coi nhu da toi, an mui ten
const ARROW_SIZE := 92.0 # khung Control con cua mui ten (tam giac ~46px ben trong)
const RECALC_INTERVAL := 0.2

## Control con tu ve mui ten: ve trong toa do local, xoay bang rotation
## cua chinh Control (pivot o tam) nen _draw chi ve mui ten huong sang phai.
class ArrowControl:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		# Vien sam (ve truoc, to hon) roi loi vang nho hon de lo vien.
		var outline: PackedVector2Array = [
			c + Vector2(23.0, 0.0),
			c + Vector2(-17.0, -15.0),
			c + Vector2(-9.0, 0.0),
			c + Vector2(-17.0, 15.0),
		]
		draw_colored_polygon(outline, Color(0.16, 0.11, 0.02, 1.0))
		var fill: PackedVector2Array = []
		for p in outline:
			fill.append(c + (p - c) * 0.76)
		draw_colored_polygon(fill, Color(1.0, 0.84, 0.18, 1.0))

var _root: Node = null
var _player: Node2D = null
var _target_node: Node2D = null
var _target_quest_id := ""
var _ui_visible := true
var _recalc_timer := 0.0
var _arrow: Control = null
var _dist_label: Label = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow = ArrowControl.new()
	_arrow.name = "GuidanceArrow"
	_arrow.size = Vector2(ARROW_SIZE, ARROW_SIZE)
	_arrow.pivot_offset = Vector2(ARROW_SIZE, ARROW_SIZE) * 0.5
	_arrow.visible = false
	add_child(_arrow)
	_dist_label = Label.new()
	_dist_label.name = "GuidanceDistance"
	_dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dist_label.add_theme_font_size_override("font_size", 14)
	_dist_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	_dist_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_dist_label.add_theme_constant_override("shadow_offset_x", 1)
	_dist_label.add_theme_constant_override("shadow_offset_y", 1)
	_dist_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dist_label.size = Vector2(90.0, 20.0)
	_dist_label.visible = false
	add_child(_dist_label)
	if has_node("/root/QuestManager"):
		var qm: Node = get_node("/root/QuestManager")
		if qm.has_signal("quest_accepted") and not qm.is_connected("quest_accepted", _on_quest_signal):
			qm.connect("quest_accepted", _on_quest_signal)
		if qm.has_signal("quest_updated") and not qm.is_connected("quest_updated", _on_quest_signal):
			qm.connect("quest_updated", _on_quest_signal)
		if qm.has_signal("quest_completed") and not qm.is_connected("quest_completed", _on_quest_signal):
			qm.connect("quest_completed", _on_quest_signal)
	_resolve_target()


## API cho coordinator: LeftUI goi khi doi map (root = map root, player moi).
func set_context(root: Node, player: Node2D) -> void:
	_root = root
	_player = player
	_target_node = null
	_target_quest_id = ""
	_recalc_timer = 0.0
	_resolve_target()
	_refresh_arrow()


## API cho coordinator: dong bo an/hien voi phim M cua cum LeftUI.
func set_ui_visible(v: bool) -> void:
	_ui_visible = v
	_refresh_arrow()


## Diem dich hien tai (toa do global) hoac null — tien cho test/debug.
func get_target_position() -> Variant:
	if _target_node != null and is_instance_valid(_target_node):
		return _target_node.global_position
	return null


func get_target_quest_id() -> String:
	return _target_quest_id


func _on_quest_signal(_quest_id: String) -> void:
	_recalc_timer = 0.0
	_resolve_target()


func _process(delta: float) -> void:
	_recalc_timer -= delta
	if _recalc_timer <= 0.0:
		_recalc_timer = RECALC_INTERVAL
		_resolve_target()
	_refresh_arrow()


# --- Xac dinh dich ---------------------------------------------------------

func _resolve_target() -> void:
	_target_node = null
	_target_quest_id = ""
	if _root == null or not is_instance_valid(_root) or not _root.is_inside_tree():
		return
	if _player == null or not is_instance_valid(_player):
		return
	if not has_node("/root/QuestManager"):
		return
	var quests: Dictionary = QuestManager.quests
	for qid in quests.keys():
		var q: Dictionary = quests[qid]
		if str(q.get("quest_type", "")) != "main":
			continue
		var st := str(q.get("status", ""))
		if st != "active" and st != "ready_turn_in":
			continue
		# Quest chinh active dau tien: chi xet quest nay roi dung han.
		_target_quest_id = str(qid)
		_target_node = _pick_target_for(q, st)
		return


func _pick_target_for(q: Dictionary, st: String) -> Node2D:
	var progress := int(q.get("progress", 0))
	var target_count := int(q.get("target_count", 1))
	var need_turn_in := st == "ready_turn_in" \
		or (progress >= target_count and bool(q.get("requires_turn_in", false)))
	if need_turn_in:
		var tn := str(q.get("turn_in_npc", ""))
		if tn == "":
			return null
		return _find_npc(tn)
	var target_type := str(q.get("target_type", ""))
	if target_type != "":
		return _find_enemy(target_type)
	var collect_type := str(q.get("collect_type", ""))
	if collect_type != "":
		return _find_pickup(collect_type)
	return null


## Quet toan bo cay node duoi _root (giong mau quet cua minimap).
func _scan_root() -> Array[Node]:
	var out: Array[Node] = []
	if _root == null or not is_instance_valid(_root):
		return out
	var stack: Array[Node] = [_root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		out.append(n)
		for c in n.get_children():
			stack.append(c)
	return out


func _script_path_of(n: Node) -> String:
	var sc: Script = n.get_script() as Script
	return sc.resource_path if sc != null else ""


func _find_npc(wanted_id: String) -> Node2D:
	for n in _scan_root():
		if n is Node2D and _script_path_of(n) == NPC_SCRIPT \
				and str(n.get("npc_id")) == wanted_id:
			return n as Node2D
	return null


func _is_alive_enemy(n: Node) -> bool:
	var hp_v: Variant = n.get("hp")
	if hp_v != null and int(hp_v) <= 0:
		return false
	var st_v: Variant = n.get("state")
	if st_v != null and int(st_v) == ENEMY_DEAD_STATE:
		return false
	return true


func _find_enemy(wanted_type: String) -> Node2D:
	var best_alive: Node2D = null
	var best_alive_d := INF
	var best_any: Node2D = null
	var best_any_d := INF
	for n in _scan_root():
		if not (n is Node2D) or not n.is_in_group("enemy"):
			continue
		if str(n.get("enemy_type")) != wanted_type:
			continue
		var node2d := n as Node2D
		var d := _player.global_position.distance_squared_to(node2d.global_position)
		if d < best_any_d:
			best_any_d = d
			best_any = node2d
		if _is_alive_enemy(n) and d < best_alive_d:
			best_alive_d = d
			best_alive = node2d
	return best_alive if best_alive != null else best_any


func _find_pickup(wanted_item: String) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for n in _scan_root():
		if not (n is Node2D) or _script_path_of(n) != HERB_SCRIPT:
			continue
		if str(n.get("item_id")) != wanted_item:
			continue
		var node2d := n as Node2D
		var d := _player.global_position.distance_squared_to(node2d.global_position)
		if d < best_d:
			best_d = d
			best = node2d
	return best


# --- Hien thi ---------------------------------------------------------------

func _refresh_arrow() -> void:
	if _arrow == null:
		return
	var show := _ui_visible
	if _player == null or not is_instance_valid(_player):
		show = false
	if _target_node == null or not is_instance_valid(_target_node):
		show = false
	if show and has_node("/root/GameState") and bool(GameState.in_dialogue):
		show = false
	if not show:
		_arrow.visible = false
		_dist_label.visible = false
		return
	var target_pos: Vector2 = _target_node.global_position
	var to_target: Vector2 = target_pos - _player.global_position
	var dist := to_target.length()
	if dist < ARRIVE_DIST:
		_arrow.visible = false
		_dist_label.visible = false
		return
	var center := size * 0.5
	# size co the chua co luc vua tao (chua vao layout): dung viewport thay the.
	if center.length() < 1.0:
		center = get_viewport_rect().size * 0.5
	var dir := to_target / dist
	var arrow_center := center + dir * ARROW_RADIUS
	_arrow.position = arrow_center - _arrow.pivot_offset
	_arrow.rotation = dir.angle()
	_arrow.visible = true
	_dist_label.text = "%d ô" % int(round(dist / CELL_PX))
	_dist_label.position = arrow_center + Vector2(-_dist_label.size.x * 0.5, ARROW_SIZE * 0.5 + 2.0)
	_dist_label.visible = true
