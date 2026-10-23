extends "res://enemies/enemy_base.gd"
## Boss King Aldric, the Puppet King — BOSS CUỐI PHẦN 1 (Royal Palace of Aldenmere).
## Kế thừa enemy_base: melee như base (attack giữ nguyên, cooldown 0.9 ở .tscn).
## Phase 1 (100% -> 50% HP) — VUA VÀNG:
##  - Tint vàng vương giả (1.05, 0.95, 0.6), sprite player_frames scale 1.35.
##  - Đang combat (CHASE/ATTACK) mỗi summon_interval (5s) "hô lính": triệu hồi
##    1 soldier (soldier.tscn), tối đa max_summons (3) lần.
## Phase 2 (<= 50% HP) — LỘ BẢN CHẤT CON RỐI:
##  - Tint chuyển tím đen (0.45, 0.3, 0.6) + print kể chuyện sợi chỉ ấn,
##    boss display đổi tên thành "Con Rối Của Tháp".
##  - Speed x1.25 (100 -> 125).
##  - Đòn "Chỉ Ấn" (shadow bolt): mỗi bolt_interval (3.5s) bắn 1 đạn
##    shadow_bolt.tscn tint tím, damage bolt_damage (18).
##  - Slam nhẹ (mượn pattern boss_golem): player trong slam_trigger_range
##    (90px) và slam sẵn sàng -> GỒNG 0.4s (đứng yên, tint sáng dần) ->
##    player còn <= slam_hit_range (80px) thì chịu slam_damage (24).
## Boss HP bar: _ready + mỗi take_damage gọi GameState.set_boss_display()
## (tên theo phase). Chết: base _die() ĐÃ lo add_xp/add_gold +
## QuestManager.on_enemy_killed("boss_vua") — quest dong_07_vua khi complete
## sẽ tự set flag "dong_giai_phong" + phát signal part1_completed, nên
## _on_death() KHÔNG tự set flag đó; chỉ clear boss display + set_flag("vua_ha").

const SOLDIER_SCENE: PackedScene = preload("res://enemies/soldier.tscn")
const SHADOW_BOLT_SCENE: PackedScene = preload("res://enemies/shadow_bolt.tscn")

@export var summon_interval: float = 5.0
@export var max_summons: int = 3
@export var bolt_interval: float = 3.5
@export var bolt_damage: int = 18
@export var slam_damage: int = 24
@export var slam_trigger_range: float = 90.0
@export var slam_hit_range: float = 80.0
@export var slam_windup_time: float = 0.4
@export var slam_cooldown: float = 4.5

var phase: int = 1
var summons_done: int = 0
var bolt_count: int = 0
var boss_display_active: bool = false
var slam_timer: float = 0.0 # <= 0 = slam sẵn sàng (test ép slam bằng cách set về 0)
var slam_count: int = 0
var last_slam_hit: bool = false

var _summon_timer: float = 5.0
var _bolt_timer: float = 3.5
var _winding_up: bool = false
var _windup_timer: float = 0.0
var _phase2_speed_mult: float = 1.25
var _tint_phase1: Color = Color(1.05, 0.95, 0.6, 1) # vàng vương giả
var _tint_phase2: Color = Color(0.45, 0.3, 0.6, 1) # tím đen con rối
var _tint_windup: Color = Color(1.35, 0.9, 1.5, 1) # sáng tím khi gồng slam


func _ready() -> void:
	super._ready()
	attack_cooldown_time = 0.9
	_summon_timer = summon_interval
	_bolt_timer = bolt_interval
	_update_boss_display()


## Đang gồng slam thì đứng yên; phase 2 chạy nhanh hơn 25%.
func _move_speed() -> float:
	if _winding_up:
		return 0.0
	return speed * _phase2_speed_mult if phase >= 2 else speed


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD:
		return
	# Phase 1: hô lính khi đang combat
	if phase == 1 and summons_done < max_summons:
		if state == State.CHASE or state == State.ATTACK:
			_summon_timer -= delta
			if _summon_timer <= 0.0:
				_summon_timer = summon_interval
				summon_soldier()
	# Phase 2: Chỉ Ấn + slam nhẹ
	if phase >= 2:
		_bolt_timer -= delta
		if _bolt_timer <= 0.0:
			_bolt_timer = bolt_interval
			shoot_shadow_bolt()
		if slam_timer > 0.0:
			slam_timer -= delta
		if _winding_up:
			_tick_windup(delta)
		else:
			_try_start_slam()


## Tìm player: ưu tiên _player của base, fallback quét group "player".
func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


# --- Phase 1: hô lính -----------------------------------------------------

## Triệu hồi 1 lính vua cạnh boss. Phòng thủ parent/current_scene null.
func summon_soldier() -> void:
	if state == State.DEAD or summons_done >= max_summons:
		return
	var parent: Node = get_parent()
	if parent == null and get_tree() != null:
		parent = get_tree().current_scene
	if parent == null:
		print("[%s] Bỏ qua hô lính: không có node cha/current_scene" % display_name)
		return
	summons_done += 1
	var offsets: Array[Vector2] = [Vector2(56, 20), Vector2(-56, 20), Vector2(0, 56)]
	var minion: Node2D = SOLDIER_SCENE.instantiate()
	parent.add_child(minion)
	minion.global_position = global_position + offsets[(summons_done - 1) % offsets.size()]
	print("[%s] HÔ LÍNH! \"Lính đâu, hộ giá!\" — triệu hồi lính vua (lần %d/%d)" % [display_name, summons_done, max_summons])


# --- Phase 2: Chỉ Ấn (shadow bolt) ----------------------------------------

## Bắn 1 đạn Chỉ Ấn về phía player (không có player thì bắn theo hướng mặt).
func shoot_shadow_bolt() -> void:
	if state == State.DEAD:
		return
	var dir := _facing if _facing != Vector2.ZERO else Vector2.DOWN
	var p := _find_player()
	if p != null:
		var to_player: Vector2 = p.global_position - global_position
		if to_player.length() > 0.01:
			dir = to_player.normalized()
	var parent: Node = get_parent()
	if parent == null and get_tree() != null:
		parent = get_tree().current_scene
	if parent == null:
		print("[%s] Bỏ qua Chỉ Ấn: không có node cha/current_scene" % display_name)
		return
	var bolt: Node2D = SHADOW_BOLT_SCENE.instantiate()
	parent.add_child(bolt)
	bolt.global_position = global_position + dir * 26.0
	if bolt.has_method("launch"):
		bolt.launch(dir, bolt_damage)
	bolt_count += 1
	print("[%s] CHỈ ẤN! Sợi chỉ tím bắn về phía player, %d damage (đạn #%d)" % [display_name, bolt_damage, bolt_count])


# --- Phase 2: slam nhẹ (pattern boss_golem) --------------------------------

func _try_start_slam() -> void:
	if slam_timer > 0.0:
		return
	var p := _find_player()
	if p == null:
		return
	if global_position.distance_to(p.global_position) > slam_trigger_range:
		return
	_winding_up = true
	_windup_timer = slam_windup_time
	print("[%s] GỒNG đòn ấn đập... (player cách %.0fpx)" % [display_name, global_position.distance_to(p.global_position)])


func _tick_windup(delta: float) -> void:
	_windup_timer -= delta
	var t: float = clampf(1.0 - _windup_timer / maxf(slam_windup_time, 0.01), 0.0, 1.0)
	sprite_modulate = _base_tint().lerp(_tint_windup, t)
	_apply_modulate()
	if _windup_timer <= 0.0:
		_winding_up = false
		sprite_modulate = _base_tint()
		_apply_modulate()
		_execute_slam()


func _execute_slam() -> void:
	slam_count += 1
	slam_timer = slam_cooldown
	last_slam_hit = false
	var p := _find_player()
	if p != null and global_position.distance_to(p.global_position) <= slam_hit_range:
		if p.has_method("take_damage"):
			p.take_damage(slam_damage, global_position)
			last_slam_hit = true
			print("[%s] ẤN ĐẬP trúng player! %d damage (slam #%d)" % [display_name, slam_damage, slam_count])
	else:
		print("[%s] ẤN ĐẬP hụt — player đã thoát khỏi %dpx (slam #%d)" % [display_name, int(slam_hit_range), slam_count])


func _base_tint() -> Color:
	return _tint_phase2 if phase >= 2 else _tint_phase1


# --- Phase / boss display / chết -------------------------------------------

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, from_position)
	if state == State.DEAD:
		return # _on_death() đã clear boss display + set flag vua_ha
	_check_phase()
	_update_boss_display()


func _check_phase() -> void:
	if phase == 1 and hp <= max_hp / 2:
		phase = 2
		_bolt_timer = bolt_interval
		slam_timer = 1.5 # cho người chơi một nhịp thở trước slam đầu tiên
		if not _winding_up:
			sprite_modulate = _tint_phase2
		_apply_modulate()
		print("[%s] PHASE 2 — LỘ BẢN CHẤT CON RỐI! Những sợi chỉ ấn hiện ra sau lưng vua, mắt vua đỏ rực, giọng nói không còn là của hắn nữa... (HP %d/%d, speed x1.25 -> %.0f, Chỉ Ấn mỗi %.1fs)" % [display_name, hp, max_hp, speed * _phase2_speed_mult, bolt_interval])


## Tên hiển thị trên thanh máu boss: phase 2 lộ bản chất nên đổi tên.
func _boss_display_name() -> String:
	return "Con Rối Của Tháp" if phase >= 2 else "King Aldric, the Puppet King"


func _update_boss_display() -> void:
	boss_display_active = true
	if has_node("/root/GameState") and GameState.has_method("set_boss_display"):
		GameState.set_boss_display(_boss_display_name(), hp, max_hp)


func _clear_boss_display() -> void:
	boss_display_active = false
	if has_node("/root/GameState") and GameState.has_method("clear_boss_display"):
		GameState.clear_boss_display()


func _on_death() -> void:
	_clear_boss_display()
	if has_node("/root/GameState") and GameState.has_method("set_flag"):
		GameState.set_flag("vua_ha")
	# KHÔNG set "dong_giai_phong" ở đây: QuestManager lo qua quest dong_07_vua
	# khi on_enemy_killed("boss_vua") chạy (base _die đã gọi trước _on_death).
	print("[%s] Bị hạ! Những sợi chỉ ấn đứt đoạn, vua ngã xuống như con rối hết dây — ngai vàng Aldenmere trống không." % display_name)
