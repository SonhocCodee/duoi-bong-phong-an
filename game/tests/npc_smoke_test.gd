extends Node
## Smoke test runtime cho NPC/dialogue/portal/map_root/herb (phần systems_test
## không chạm tới): prompt tương tác, mở thoại bằng phím E qua player, sang câu
## bằng sự kiện phím thật (Viewport.push_input), accept quest sau thoại, portal
## khóa hiện locked_text, MapRoot đưa player tới Marker2D Spawn_<tên>.
##   godot --headless --path game res://tests/npc_smoke_test.tscn

var _frame := 0
var _failures: Array[String] = []
var _passes: int = 0
var _player: Node2D = null
var _npc: Node = null
var _herb: Node = null
var _portal: Node = null


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[SMOKE] PASS: ", label)
	else:
		_failures.append(label)
		print("[SMOKE] FAIL: ", label)


# Mở thoại: player đọc Input.is_action_just_pressed trong _physics_process
func _press_interact() -> void:
	Input.action_press("interact")


func _release_interact() -> void:
	Input.action_release("interact")


# Sang câu thoại: DialogueBox đọc sự kiện thật ở _unhandled_input -> push_input
func _push_interact_event() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_E
	ev.pressed = true
	get_viewport().push_input(ev)


func _ready() -> void:
	_player = load("res://player/player.tscn").instantiate()
	_player.global_position = Vector2.ZERO
	add_child(_player)

	_npc = load("res://systems/npc.tscn").instantiate()
	_npc.global_position = Vector2(30, 0)
	var qids: Array[String] = ["dong_side_slime"]
	_npc.set("quest_ids", qids)
	_npc.set("npc_id", "tho_ren")
	_npc.set("display_name", "Thợ rèn")
	var dlg: Array[String] = ["Xin chào!", "Diệt slime giúp ta với!"]
	_npc.set("dialogue_before", dlg)
	add_child(_npc)

	_herb = load("res://systems/herb_pickup.tscn").instantiate()
	_herb.global_position = Vector2(10, 0)
	add_child(_herb)

	_portal = load("res://systems/portal.tscn").instantiate()
	_portal.global_position = Vector2(300, 300)
	_portal.set("target_scene", "res://maps/world_test.tscn")
	_portal.set("target_spawn", "somewhere")
	_portal.set("required_flag", "flag_khong_bao_gio_co")
	_portal.set("locked_text", "Cổng đang bị khóa!")
	add_child(_portal)
	print("[SMOKE] Setup xong.")


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		5:
			_check(not is_instance_valid(_herb), "Herb: player chạm -> nhặt + biến mất")
			var prompt: Label = _npc.get_node("PromptLabel")
			_check(prompt.visible, "NPC: player ở gần -> hiện prompt '[E] Nói chuyện'")
		6:
			# MapRoot: tạo root map giả có Marker2D Spawn_den, spawn_point = "den"
			GameState.spawn_point = "den"
			var root := Node2D.new()
			root.set_script(load("res://systems/map_root.gd"))
			var marker := Marker2D.new()
			marker.name = "Spawn_den"
			marker.position = Vector2(500, 500)
			root.add_child(marker)
			add_child(root)
		10:
			_check(_player.global_position == Vector2(500, 500),
				"MapRoot: player được đưa tới Spawn_den (thấy %s)" % str(_player.global_position))
			_player.global_position = Vector2.ZERO
			GameState.spawn_point = "start"
		15:
			_press_interact()
		19:
			_release_interact()
		25:
			_check(GameState.in_dialogue, "Dialogue: bấm E gần NPC -> mở thoại, in_dialogue = true")
			_check(get_node_or_null("DialogueBox") != null, "Dialogue: DialogueBox đã xuất hiện")
		45:
			_push_interact_event() # sang câu 2
		75:
			_push_interact_event() # hết thoại before -> accept + thoại xác nhận
		90:
			_check(str(QuestManager.get_quest("dong_side_slime").get("status", "")) == "active",
				"NPC: hết thoại -> accept dong_side_slime (status active)")
			_check(GameState.in_dialogue, "Dialogue: thoại xác nhận đang mở (vẫn khóa di chuyển)")
		120:
			_push_interact_event() # đóng thoại xác nhận
		135:
			_check(not GameState.in_dialogue, "Dialogue: đóng hẳn -> in_dialogue = false")
			_player.global_position = Vector2(300, 300) # bước vào portal khóa
		150:
			var locked_label: Label = _portal.get_node("LockedLabel")
			_check(locked_label.visible and locked_label.text == "Cổng đang bị khóa!",
				"Portal khóa: hiện locked_text, không chuyển map")
			_check(GameState.current_map == "", "Portal khóa: current_map không đổi")
			print("[SMOKE] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
			get_tree().quit(1 if _failures.size() > 0 else 0)
