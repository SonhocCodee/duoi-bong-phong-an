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

# --- Kịch bản 3: NPC thật trong map thật -----------------------------------
# ngoai_thanh + thanh_xuan_lam (phase 4-6), lang_tan_diep (phase 7-8),
# dong_mach_nha (phase 9). Map Elmford có OpeningOverlay tự bật intro và
# set GameState.in_dialogue = true -> phải free overlay + mở khóa lại thì
# NPC mới chạy schedule được.
var _s3_map: Node = null
var _s3_npcs: Dictionary = {} # npc_id -> Node
var _s3_starts: Dictionary = {} # npc_id -> Vector2
var _s3_linh_moved: bool = false
var _s3_thoren_worked: bool = false
var _s3_dan_well: bool = false # dan_tandiep_1 có lúc cách PropWell <= 48px
var _s3_truong_moved: bool = false # truong_lang di chuyển > 80px khỏi điểm đầu
var _s3_nong_worked: bool = false # nong_dan đạt current_action == "work"

const PROP_WELL_POS := Vector2(110, 191) # vị trí PropWell trong Elmford mới


func _s3_check_config(npc: Node, label: String) -> void:
	_check(npc != null, "KB3: tìm thấy NPC " + label)
	if npc == null:
		return
	_check(bool(npc.get("schedule_enabled")) == true,
		"KB3: " + label + " schedule_enabled == true")
	var sched: Array = npc.get("schedule")
	_check(sched.size() > 0, "KB3: " + label + " schedule không rỗng (%d bước)" % sched.size())


func _s3_check_sprite(npc: Node, label: String, expect_path: String) -> void:
	if npc == null:
		_check(false, "KB3: sprite " + label + " (thiếu NPC)")
		return
	var spr: AnimatedSprite2D = npc.get_node_or_null("AnimatedSprite2D")
	var path := ""
	if spr != null and spr.sprite_frames != null:
		path = spr.sprite_frames.resource_path
	_check(path == expect_path, "KB3: sprite %s == %s (thấy %s)" % [
		label, expect_path.get_file(), path.get_file() if path != "" else "(không có)"])

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
			_phase = 4
			_phase_frame = 0
		4: # KB3a: nạp The Wallfoot, kiểm tra linh_gac_ngoai + mô phỏng tuần tra
			if _phase_frame == 1:
				Engine.time_scale = 3.0
				_s3_map = load("res://maps/ngoai_thanh.tscn").instantiate()
				add_child(_s3_map)
				var linh: Node = _s3_map.get_node_or_null("NPC_LinhGac")
				_s3_npcs["linh_gac_ngoai"] = linh
				_s3_check_config(linh, "linh_gac_ngoai (Wallfoot)")
				_s3_check_sprite(linh, "linh_gac_ngoai", "res://assets/sprites/linh_tuan_frames.tres")
				if linh != null:
					_s3_starts["linh_gac_ngoai"] = linh.global_position
			var lg: Node = _s3_npcs.get("linh_gac_ngoai") as Node
			if lg != null and _s3_starts.has("linh_gac_ngoai"):
				if lg.global_position.distance_to(_s3_starts["linh_gac_ngoai"]) > 80.0:
					_s3_linh_moved = true
			if _s3_linh_moved or _phase_frame > 700:
				_check(_s3_linh_moved,
					"KB3: linh_gac_ngoai tuần tra di chuyển > 80px khỏi vị trí đầu")
				if _s3_map != null:
					_s3_map.queue_free()
					_s3_map = null
				_s3_npcs.clear()
				_phase = 5
				_phase_frame = 0
		5: # chờ map cũ free hẳn trước khi nạp map tiếp theo
			if _phase_frame >= 5:
				_phase = 6
				_phase_frame = 0
		6: # KB3b: nạp Aldenmere, kiểm tra 4 NPC + mô phỏng tho_ren gõ búa
			if _phase_frame == 1:
				_s3_map = load("res://maps/thanh_xuan_lam.tscn").instantiate()
				add_child(_s3_map)
				for pair in [["NPC_ThoRen", "tho_ren"], ["NPC_ChuQuan", "chu_quan"],
						["NPC_LinhGac", "linh_gac"], ["NPC_LinhGacNam", "linh_gac_nam"]]:
					var n: Node = _s3_map.get_node_or_null(pair[0])
					_s3_npcs[pair[1]] = n
					_s3_check_config(n, pair[1] + " (Aldenmere)")
				_s3_check_sprite(_s3_npcs.get("tho_ren") as Node, "tho_ren",
					"res://assets/sprites/tho_ren_frames.tres")
				_s3_check_sprite(_s3_npcs.get("linh_gac") as Node, "linh_gac",
					"res://assets/sprites/linh_tuan_frames.tres")
				_s3_check_sprite(_s3_npcs.get("linh_gac_nam") as Node, "linh_gac_nam",
					"res://assets/sprites/linh_tuan_frames.tres")
			var tr: Node = _s3_npcs.get("tho_ren") as Node
			if tr != null and str(tr.get("current_action")) == "work":
				_s3_thoren_worked = true
			if _s3_thoren_worked or _phase_frame > 900:
				_check(_s3_thoren_worked,
					"KB3: tho_ren đạt current_action == 'work' (gõ búa tại đe)")
				if _s3_map != null:
					_s3_map.queue_free()
					_s3_map = null
				_s3_npcs.clear()
				_phase = 7
				_phase_frame = 0
		7: # KB3c: Elmford — dan ganh nuoc + truong lang di xuyen lang
			if _phase_frame == 1:
				_s3_map = load("res://maps/lang_tan_diep.tscn").instantiate()
				add_child(_s3_map)
				var ov: Node = _s3_map.get_node_or_null("OpeningOverlay")
				if ov != null:
					ov.queue_free()
				var gs: Node = get_node_or_null("/root/GameState")
				if gs != null:
					gs.set("in_dialogue", false)
				for pair in [["NPC_DanLang", "dan_tandiep_1"], ["NPC_TruongLang", "truong_lang"]]:
					var n: Node = _s3_map.get_node_or_null(pair[0])
					_s3_npcs[pair[1]] = n
					_s3_check_config(n, pair[1] + " (Elmford)")
					if n != null:
						_s3_starts[pair[1]] = n.global_position
			var dan: Node = _s3_npcs.get("dan_tandiep_1") as Node
			if dan != null and dan.global_position.distance_to(PROP_WELL_POS) <= 48.0:
				_s3_dan_well = true
			var truong: Node = _s3_npcs.get("truong_lang") as Node
			if truong != null and _s3_starts.has("truong_lang") \
					and truong.global_position.distance_to(_s3_starts["truong_lang"]) > 80.0:
				_s3_truong_moved = true
			if (_s3_dan_well and _s3_truong_moved) or _phase_frame > 2000:
				_check(_s3_dan_well,
					"KB3: dan_tandiep_1 có lúc tới cách PropWell <= 48px (gánh nước)")
				_check(_s3_truong_moved,
					"KB3: truong_lang di chuyển > 80px khỏi điểm đầu (đi xuyên làng)")
				if _s3_map != null:
					_s3_map.queue_free()
					_s3_map = null
				_s3_npcs.clear()
				_s3_starts.clear()
				_phase = 8
				_phase_frame = 0
		8: # chờ map cũ free hẳn
			if _phase_frame >= 5:
				_phase = 9
				_phase_frame = 0
		9: # KB3d: Barleyfield — nong_dan cuoc dat trong FieldA
			if _phase_frame == 1:
				_s3_map = load("res://maps/dong_mach_nha.tscn").instantiate()
				add_child(_s3_map)
				var nd: Node = _s3_map.get_node_or_null("NPC_NongDan")
				_s3_npcs["nong_dan"] = nd
				_s3_check_config(nd, "nong_dan (Barleyfield)")
				_s3_check_sprite(nd, "nong_dan", "res://assets/sprites/nong_dan_frames.tres")
			var nd2: Node = _s3_npcs.get("nong_dan") as Node
			if nd2 != null and str(nd2.get("current_action")) == "work":
				_s3_nong_worked = true
			if _s3_nong_worked or _phase_frame > 2000:
				_check(_s3_nong_worked,
					"KB3: nong_dan đạt current_action == 'work' (cuốc đất FieldA)")
				if _s3_map != null:
					_s3_map.queue_free()
					_s3_map = null
				Engine.time_scale = 1.0
				_finish()
