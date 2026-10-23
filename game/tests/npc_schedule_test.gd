extends Node
## Test runtime cho engine lịch trình NPC (systems/npc.gd):
##   godot --headless --path game res://tests/npc_schedule_test.tscn
## Kịch bản 1 (npc1, thợ rèn có sprite work):
##   schedule = [điểm A + work 2s, điểm B + idle dài]
##   -> khẳng định NPC rời vị trí đầu, tới gần A, vào trạng thái work
##      (current_action == "work" và anim đang phát == "work");
##   -> set_talk_pause(true) -> NPC đứng yên hẳn trong 0.5s mô phỏng,
##      quay mặt về phía vị trí face (idle_side);
##   -> set_talk_pause(false) -> tiếp tục đúng bước work đang dở rồi đi
##      tiếp tới B và idle (không reset vòng: current_step_index == 1).
## Kịch bản 2 (npc2): bước đầu có đích sau một StaticBody tường ->
##   NPC kẹt ~1.5s thì tự bỏ qua sang bước tiếp theo và tới được đích sau.

var _passes: int = 0
var _failures: Array[String] = []
var _phase: int = 0
var _phase_frame: int = 0
var _npc1: Node = null
var _npc2: Node = null
var _start1: Vector2 = Vector2.ZERO
var _pause_pos: Vector2 = Vector2.ZERO

const POINT_A := Vector2(120, 0)
const POINT_B := Vector2(120, 100)
const POINT_C := Vector2(320, 90) # đích bước 2 của npc2 (sau khi bỏ qua bước kẹt)


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[SCHED] PASS: ", label)
	else:
		_failures.append(label)
		print("[SCHED] FAIL: ", label)


func _make_npc(pos: Vector2, sched: Array[Dictionary], frames_path: String) -> Node:
	var npc: Node = load("res://systems/npc.tscn").instantiate()
	npc.global_position = pos
	npc.set("npc_id", "test_schedule")
	npc.set("display_name", "NPC lịch trình")
	npc.set("schedule", sched)
	npc.set("schedule_enabled", true)
	var spr: AnimatedSprite2D = npc.get_node("AnimatedSprite2D")
	spr.sprite_frames = load(frames_path)
	add_child(npc)
	return npc


func _ready() -> void:
	# Tường chắn đường npc2 -> đích bước 1 của nó
	var wall := StaticBody2D.new()
	wall.global_position = Vector2(370, 0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 90)
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)

	var sched1: Array[Dictionary] = [
		{"x": POINT_A.x, "y": POINT_A.y, "action": "work", "time": 2.0},
		{"x": POINT_B.x, "y": POINT_B.y, "action": "idle", "time": 30.0},
	]
	_npc1 = _make_npc(Vector2.ZERO, sched1, "res://assets/sprites/tho_ren_frames.tres")
	_start1 = _npc1.global_position

	var sched2: Array[Dictionary] = [
		{"x": 420.0, "y": 0.0, "action": "work", "time": 1.0}, # sau tường — không tới được
		{"x": POINT_C.x, "y": POINT_C.y, "action": "idle", "time": 30.0},
	]
	_npc2 = _make_npc(Vector2(320, 0), sched2, "res://assets/sprites/linh_tuan_frames.tres")
	print("[SCHED] Setup xong.")


func _finish() -> void:
	print("[SCHED] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)


func _physics_process(_delta: float) -> void:
	_phase_frame += 1
	match _phase:
		0: # chờ npc1 tới A và vào work
			var spr1: AnimatedSprite2D = _npc1.get_node("AnimatedSprite2D")
			if str(_npc1.get("current_action")) == "work" and str(spr1.animation) == "work":
				_check(_npc1.global_position.distance_to(_start1) > 100.0,
					"Schedule: NPC rời vị trí đầu (đã đi %d px)" % int(_npc1.global_position.distance_to(_start1)))
				_check(_npc1.global_position.distance_to(POINT_A) <= 10.0,
					"Schedule: NPC tới gần điểm A (cách %d px)" % int(_npc1.global_position.distance_to(POINT_A)))
				_check(true, "Schedule: vào trạng thái work (current_action == 'work', anim == 'work')")
				# Tạm dừng hội thoại: face ở phía +x (trục lớn hơn) -> quay mặt side
				_npc1.call("set_talk_pause", true, _npc1.global_position + Vector2(50, 10))
				_pause_pos = _npc1.global_position
				_phase = 1
				_phase_frame = 0
			elif _phase_frame > 400:
				_check(false, "Schedule: NPC tới A + work trong thời gian cho phép")
				_finish()
		1: # giữ pause 0.5s mô phỏng (30 frame vật lý)
			if _phase_frame >= 30:
				_check(_npc1.global_position.distance_to(_pause_pos) < 0.6,
					"Talk pause: NPC đứng yên hẳn 0.5s khi đang work (lệch %s px)" % str(_npc1.global_position.distance_to(_pause_pos)))
				var spr1b: AnimatedSprite2D = _npc1.get_node("AnimatedSprite2D")
				_check(str(spr1b.animation) == "idle_side",
					"Talk pause: NPC quay mặt về phía face_position (anim idle_side, thấy %s)" % str(spr1b.animation))
				_npc1.call("set_talk_pause", false, Vector2.ZERO)
				_check(str(_npc1.get("current_action")) == "work",
					"Talk pause off: vẫn ở đúng bước work đang dở (không reset vòng)")
				_phase = 2
				_phase_frame = 0
		2: # chờ npc1 làm nốt work rồi đi tới B, vào idle ở bước 2
			if int(_npc1.get("current_step_index")) == 1 and str(_npc1.get("current_action")) == "idle" \
					and _npc1.global_position.distance_to(POINT_B) <= 12.0:
				_check(true, "Sau thoại: NPC tiếp tục schedule -> tới B và idle (step_index == 1)")
				_phase = 3
				_phase_frame = 0
			elif _phase_frame > 600:
				_check(false, "Sau thoại: NPC tiếp tục schedule -> tới B và idle (step_index == 1)")
				_phase = 3
				_phase_frame = 0
		3: # npc2: bước kẹt tường phải đã bị bỏ qua, npc2 ở bước 2 gần điểm C
			_check(int(_npc2.get("current_step_index")) == 1,
				"Kẹt vật cản: NPC tự bỏ qua bước sau ~1.5s (step_index == 1, thấy %d)" % int(_npc2.get("current_step_index")))
			_check(str(_npc2.get("current_action")) == "idle" and _npc2.global_position.distance_to(POINT_C) <= 15.0,
				"Kẹt vật cản: NPC đi tiếp bước sau và tới đích C (action %s, cách C %d px)" % [
					str(_npc2.get("current_action")), int(_npc2.global_position.distance_to(POINT_C))])
			_finish()
