extends CharacterBody2D
class_name NPC
## NPC - Nhân vật làng: đi quanh nhẹ quanh điểm gốc, hiện prompt "[E] Nói
## chuyện" khi player đến gần, mở DialogueBox khi player bấm interact.
## Thoại + hành động sau thoại dựa trên trạng thái quest trong quest_ids:
##   ready_turn_in (của NPC này) -> thoại ready -> turn_in_quest -> thoại done
##   available (+ đủ required)  -> thoại before  -> accept_quest -> thoại xác nhận
##   active                      -> thoại active
##   còn lại (đã xong / chưa mở) -> thoại done
## Nếu shop_enabled: kết thúc hội thoại sẽ mở ShopPanel.

const DIALOGUE_BOX_SCENE: PackedScene = preload("res://ui/dialogue_box.tscn")
const SHOP_PANEL_SCENE: PackedScene = preload("res://ui/shop_panel.tscn")

@export var npc_id: String = ""
@export var display_name: String = "NPC"
@export var quest_ids: Array[String] = [] # các quest NPC này giao / nhận trả
@export var dialogue_before: Array[String] = [] # chưa nhận quest
@export var dialogue_active: Array[String] = [] # đang làm quest
@export var dialogue_ready: Array[String] = [] # đủ tiến độ, chờ trả quest
@export var dialogue_done: Array[String] = [] # đã xong / chào xã giao
@export var shop_enabled: bool = false
# Cờ GameState đặt khi MỘT cuộc thoại với NPC này kết thúc hẳn (sau cả
# thoại xác nhận accept/turn_in). Mặc định "" = không làm gì — mọi NPC
# cũ không đổi hành vi. Dùng cho nhịp mở đầu (người gác cổng Elmford
# đặt cờ "opening_gate_done" khi người chơi nghe hết lời dặn).
@export var set_flag_on_dialogue_end: String = ""
@export var tint: Color = Color.WHITE # màu nhuộm sprite để phân biệt NPC
@export var sprite_scale: float = 0.75
@export var wander_radius: float = 24.0 # 0 = đứng yên
@export var wander_speed: float = 30.0

# --- Lịch trình sống (schedule) -------------------------------------------
# Mỗi phần tử của schedule là một Dictionary:
#   {"x": float, "y": float, "action": String, "time": float}
# - x, y: TỌA ĐỘ GLOBAL trong map của điểm đến của bước này.
# - action: "walk" | "work" | "idle".
#     "walk": chỉ đi tới (x, y); tới nơi (<= 6px) hoặc hết "time" giây thì
#             chuyển bước tiếp theo.
#     "work"/"idle": đi tới (x, y) trước, tới nơi thì đứng tại đó làm
#             việc / đứng nghỉ trong "time" giây rồi chuyển bước tiếp theo.
#             ("time" <= 0 với work/idle được hiểu mặc định là 2 giây.)
# - Lặp vòng vô hạn: hết bước cuối quay lại bước đầu.
# Tương lai gắn giờ giấc game: thay khóa "time" bằng "at_hour": float
# (giờ trong ngày mà bước bắt đầu, vd 7.5 = 07:30) — cấu trúc mảng /
# Dictionary và vòng lặp bước KHÔNG đổi, chỉ đổi điều kiện chuyển bước
# từ "hết timer" sang "đồng hồ game tới at_hour của bước tiếp theo".
# Ví dụ thợ rèn ở Aldenmere (tọa độ global trong map thành):
#   schedule = [
#     {"x": 412.0, "y": 268.0, "action": "work", "time": 20.0}, # ra lò rèn gõ búa
#     {"x": 356.0, "y": 300.0, "action": "idle", "time": 6.0},  # ra giếng rửa tay / nghỉ
#     {"x": 430.0, "y": 240.0, "action": "walk", "time": 8.0},  # đi lấy quặng ở kho
#   ]
#   schedule_enabled = true, sprite dùng tho_ren_frames.tres (có anim "work")
@export var schedule: Array[Dictionary] = []
@export var schedule_enabled: bool = false
@export var work_anim: String = "work" # anim phát khi action == "work"
@export var speed: float = 55.0 # tốc độ đi khi chạy schedule (wander vẫn dùng wander_speed)

# Trạng thái schedule công khai (cho test / debug đọc):
var current_action: String = "" # "", "walk", "work", "idle" (của bước đang chạy)
var current_step_index: int = 0 # chỉ số bước schedule đang chạy
var is_talk_paused: bool = false # đang bị tạm dừng vì hội thoại (set_talk_pause)

var _schedule_phase: String = "move" # "move" = đang đi tới điểm, "act" = đang work/idle tại điểm
var _schedule_timer: float = 0.0 # thời gian đã ở pha "act" của bước hiện tại
var _walk_elapsed: float = 0.0 # thời gian đã đi ở pha "move" (để áp trần "time" của action walk)
var _stuck_timer: float = 0.0 # thời gian không tiến được khi đang đi (kẹt vật cản)
var _stuck_anchor: Vector2 = Vector2.ZERO # mốc vị trí để đo kẹt

var _home_position: Vector2 = Vector2.ZERO
var _wander_target: Vector2 = Vector2.ZERO
var _wander_wait: float = 0.0
var _facing: Vector2 = Vector2.DOWN
var _anim_current: StringName = &""
var _talking: bool = false
var _pending_action: String = "" # "", "accept", "turn_in", "after"
var _pending_quest: String = ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: Label = $NameLabel
@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	add_to_group("interactable")
	_home_position = global_position
	_wander_target = _home_position
	_stuck_anchor = global_position
	name_label.text = display_name
	prompt_label.visible = false
	if sprite:
		sprite.modulate = tint
		sprite.scale = Vector2.ONE * sprite_scale
	_update_animation(false)


# --- Animation (giống player/goblin: an toàn nếu thiếu animation) --------

func _facing_suffix() -> String:
	if absf(_facing.x) > absf(_facing.y):
		return "side"
	return "up" if _facing.y < 0.0 else "down"


func _play_anim(anim_name: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(anim_name):
		return
	if _anim_current != anim_name:
		sprite.play(anim_name)
		_anim_current = anim_name


func _update_animation(moving: bool) -> void:
	if sprite == null:
		return
	var suffix := _facing_suffix()
	sprite.flip_h = suffix == "side" and _facing.x < 0.0
	_play_anim(StringName(("walk_" if moving else "idle_") + suffix))


func _play_work_animation() -> void:
	# action "work": phát anim work_anim (mặc định "work", mặt hướng xuống)
	# nếu SpriteFrames có; không có thì idle hướng xuống.
	if sprite == null:
		return
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(StringName(work_anim)):
		sprite.flip_h = false
		_play_anim(StringName(work_anim))
	else:
		sprite.flip_h = false
		_play_anim(&"idle_down")


# --- Engine lịch trình ------------------------------------------------------

# Đặt lại lịch trình về bước đầu (dùng khi gán schedule mới lúc runtime).
func restart_schedule() -> void:
	current_step_index = 0
	_schedule_phase = "move"
	_schedule_timer = 0.0
	_walk_elapsed = 0.0
	_stuck_timer = 0.0
	_stuck_anchor = global_position
	current_action = ""


# Tạm dừng / tiếp tục schedule vì hội thoại. Khi paused: NPC đứng yên hẳn
# (kể cả đang work), quay mặt về face_position theo trục lớn hơn; timer và
# bước đang dở được GIỮ NGUYÊN — hết thoại quay lại đúng chỗ đang dở,
# không reset vòng. npc.gd tự gọi hàm này khi thoại của chính NPC bắt đầu /
# kết thúc (xem _start_dialogue / _end_conversation); tích hợp ngoài (vd
# sự kiện map) cũng có thể gọi trực tiếp.
func set_talk_pause(paused: bool, face_position: Vector2 = Vector2.ZERO) -> void:
	is_talk_paused = paused
	if paused:
		velocity = Vector2.ZERO
		var to_pos := face_position - global_position
		if to_pos.length() > 1.0:
			if absf(to_pos.x) > absf(to_pos.y):
				_facing = Vector2(signf(to_pos.x), 0.0)
			else:
				_facing = Vector2(0.0, signf(to_pos.y))


func _advance_schedule_step() -> void:
	if schedule.is_empty():
		return
	current_step_index = (current_step_index + 1) % schedule.size()
	_schedule_phase = "move"
	_schedule_timer = 0.0
	_walk_elapsed = 0.0
	_stuck_timer = 0.0
	_stuck_anchor = global_position


func _physics_schedule(delta: float) -> void:
	if schedule.is_empty():
		current_action = ""
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(false)
		return
	if current_step_index < 0 or current_step_index >= schedule.size():
		current_step_index = 0
	var step: Dictionary = schedule[current_step_index]
	var target := Vector2(float(step.get("x", global_position.x)),
		float(step.get("y", global_position.y)))
	var action := str(step.get("action", "idle"))
	var step_time := float(step.get("time", 0.0))

	if _schedule_phase == "move":
		current_action = "walk"
		if global_position.distance_to(target) <= 6.0:
			# Tới nơi: walk -> xong bước; work/idle -> chuyển sang pha hành động
			if action == "work" or action == "idle":
				_schedule_phase = "act"
				_schedule_timer = 0.0
				_stuck_timer = 0.0
				_stuck_anchor = global_position
			else:
				_advance_schedule_step()
			velocity = Vector2.ZERO
			move_and_slide()
			return
		_walk_elapsed += delta
		# action "walk": "time" là trần thời gian đi — hết giờ thì bỏ bước
		if action == "walk" and step_time > 0.0 and _walk_elapsed >= step_time:
			_advance_schedule_step()
			return
		var dir := (target - global_position).normalized()
		_facing = dir
		velocity = dir * speed
		move_and_slide()
		_update_animation(true)
		# Kẹt vật cản (đường thẳng — mức prototype): 1.5s không rời mốc
		# quá 4px thì coi như kẹt, bỏ qua sang bước tiếp theo.
		if global_position.distance_to(_stuck_anchor) > 4.0:
			_stuck_anchor = global_position
			_stuck_timer = 0.0
		else:
			_stuck_timer += delta
			if _stuck_timer >= 1.5:
				_advance_schedule_step()
		return

	# Pha "act": đứng tại điểm đích làm hành động của bước
	velocity = Vector2.ZERO
	move_and_slide()
	if action == "work":
		current_action = "work"
		_play_work_animation()
	else:
		current_action = "idle"
		_update_animation(false)
	_schedule_timer += delta
	var duration := step_time if step_time > 0.0 else 2.0
	if _schedule_timer >= duration:
		_advance_schedule_step()


# --- Di chuyển lang thang + prompt ----------------------------------------

func _physics_process(delta: float) -> void:
	# Cập nhật prompt theo khoảng cách tới player
	var player := _get_player()
	var near_player := false
	if player != null:
		near_player = global_position.distance_to(player.global_position) < 48.0
	prompt_label.visible = near_player and not _talking

	# Đang hội thoại (bất kỳ) hoặc bị talk-pause thì đứng yên: schedule bị
	# đóng băng tại đúng bước / timer đang dở, không reset vòng.
	var dialogue_open := has_node("/root/GameState") and GameState.in_dialogue
	if _talking or dialogue_open or is_talk_paused:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(false)
		return

	# Có lịch trình thì đi theo lịch trình thay cho lang thang
	if schedule_enabled and not schedule.is_empty():
		_physics_schedule(delta)
		return

	if wander_radius <= 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(false)
		return

	# Lang thang nhẹ quanh điểm gốc (kiểu IDLE của goblin)
	if _wander_wait > 0.0:
		_wander_wait -= delta
		velocity = Vector2.ZERO
	elif global_position.distance_to(_wander_target) < 4.0:
		_wander_wait = randf_range(1.0, 2.5)
		_wander_target = _home_position + Vector2(
			randf_range(-wander_radius, wander_radius),
			randf_range(-wander_radius, wander_radius))
		velocity = Vector2.ZERO
	else:
		var dir := (_wander_target - global_position).normalized()
		_facing = dir
		velocity = dir * wander_speed
	move_and_slide()
	_update_animation(velocity.length() > 5.0)


func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


# --- Tương tác / hội thoại ---------------------------------------------------

# Player gọi hàm này khi bấm interact ở gần (xem player.gd _try_interact)
func interact() -> void:
	if _talking or not has_node("/root/QuestManager"):
		return
	var ctx := _pick_dialogue()
	_start_dialogue(ctx["lines"], str(ctx["action"]), str(ctx["quest_id"]))


func _pick_dialogue() -> Dictionary:
	# Ưu tiên 1: quest đã đủ tiến độ chờ trả tại NPC này
	for qid in quest_ids:
		var q: Dictionary = QuestManager.get_quest(qid)
		if str(q.get("status", "")) == "ready_turn_in" and str(q.get("turn_in_npc", "")) == npc_id:
			return {"lines": _lines_or(dialogue_ready, ["Ngươi đã làm xong rồi à? Tuyệt vời!"]),
				"action": "turn_in", "quest_id": qid}
	# Ưu tiên 2: quest available và đã đủ quest tiên quyết
	for qid in quest_ids:
		var q2: Dictionary = QuestManager.get_quest(qid)
		if str(q2.get("status", "")) != "available":
			continue
		var req := str(q2.get("required_quest", ""))
		if req != "" and str(QuestManager.get_quest(req).get("status", "")) != "completed":
			continue
		var req_flag := str(q2.get("required_flag", ""))
		if req_flag != "" and has_node("/root/GameState") and not GameState.get_flag(req_flag):
			continue
		return {"lines": _lines_or(dialogue_before, ["Ta có một việc cần ngươi giúp..."]),
			"action": "accept", "quest_id": qid}
	# Ưu tiên 3: quest đang làm dở
	for qid in quest_ids:
		var q3: Dictionary = QuestManager.get_quest(qid)
		if str(q3.get("status", "")) == "active":
			return {"lines": _lines_or(dialogue_active, ["Việc ta nhờ, ngươi làm tới đâu rồi?"]),
				"action": "", "quest_id": ""}
	# Còn lại: đã xong hết / chưa mở khóa — chào xã giao (hoặc mở shop nếu có)
	return {"lines": _lines_or(dialogue_done, ["Chào ngươi. Làng Elmford hôm nay yên bình lắm."]),
		"action": "", "quest_id": ""}


func _lines_or(lines: Array[String], fallback: Array) -> Array[String]:
	if not lines.is_empty():
		return lines.duplicate()
	var out: Array[String] = []
	for s in fallback:
		out.append(str(s))
	return out


func _start_dialogue(lines: Array[String], action: String, quest_id: String) -> void:
	_talking = true
	_pending_action = action
	_pending_quest = quest_id
	# Dừng schedule + quay mặt về phía player trong lúc nói chuyện
	var player := _get_player()
	set_talk_pause(true, player.global_position if player != null else global_position)
	prompt_label.visible = false
	var box: CanvasLayer = DIALOGUE_BOX_SCENE.instantiate()
	var host: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	host.add_child(box)
	box.dialogue_finished.connect(_on_dialogue_finished)
	box.start_dialogue(display_name, lines)


func _on_dialogue_finished() -> void:
	var action := _pending_action
	var qid := _pending_quest
	_pending_action = ""
	_pending_quest = ""
	match action:
		"accept":
			if QuestManager.accept_quest(qid):
				var title := str(QuestManager.get_quest(qid).get("title", qid))
				_start_dialogue(["Đã nhận nhiệm vụ: " + title], "after", "")
				return
		"turn_in":
			if QuestManager.turn_in_quest(qid):
				_start_dialogue(_lines_or(dialogue_done, ["Cảm ơn ngươi rất nhiều!"]), "after", "")
				return
	_end_conversation()


func _end_conversation() -> void:
	_talking = false
	# Cờ sự kiện khi thoại kết thúc (opt-in theo từng NPC, xem export).
	if set_flag_on_dialogue_end != "" and has_node("/root/GameState"):
		GameState.set_flag(set_flag_on_dialogue_end)
		print("[NPC %s] Đặt cờ sau thoại: %s" % [npc_id, set_flag_on_dialogue_end])
	# Thoại xong (kể cả sau thoại xác nhận accept/turn_in — các thoại đó đi
	# qua _start_dialogue nên vẫn giữ pause, chỉ kết thúc hẳn mới mở lại):
	# tiếp tục đúng bước schedule đang dở.
	set_talk_pause(false)
	if shop_enabled:
		var shop: CanvasLayer = SHOP_PANEL_SCENE.instantiate()
		var host: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
		host.add_child(shop)
		shop.open_shop()
