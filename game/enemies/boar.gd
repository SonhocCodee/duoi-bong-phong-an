extends "res://enemies/enemy_base.gd"
## Lợn rừng — chậm (speed 85) nhưng có đòn HÚC:
## Player trong charge_range (240px) và gần thẳng hướng mặt của lợn
## (chênh hướng tới player < charge_angle_deg = 25°) -> GỒNG 0.4s đứng yên,
## rồi LAO thẳng theo hướng đã khoá với tốc độ charge_speed (380) trong
## 0.45s. Chạm tầm attack_range của base trong lúc lao -> chuyển ATTACK
## để base gây damage như thường. Cooldown charge_cooldown (3s).
## Khi gồng/lao, script tự lái velocity (không gọi super phần di chuyển)
## nhưng vẫn trừ timer + cập nhật animation/flash như base.

@export var charge_range: float = 240.0
@export var charge_angle_deg: float = 25.0
@export var charge_windup_time: float = 0.4
@export var charge_speed: float = 380.0
@export var charge_duration: float = 0.45
@export var charge_cooldown: float = 3.0

var charge_count: int = 0
var _charge_cd_timer: float = 0.0
var _charge_phase: int = 0 # 0 = không húc, 1 = gồng, 2 = đang lao
var _phase_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity = Vector2.ZERO
		return
	if _charge_cd_timer > 0.0:
		_charge_cd_timer -= delta
	if _charge_phase > 0:
		_tick_charge(delta)
		return
	# Chưa húc: chạy AI base trước, rồi mới xét điều kiện kích hoạt húc
	# (sau super, _player và _facing đã được base cập nhật trong frame này).
	super._physics_process(delta)
	_try_start_charge()


func _tick_charge(delta: float) -> void:
	# Trừ các timer hiệu ứng như base làm
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _attack_anim_timer > 0.0:
		_attack_anim_timer -= delta
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
	if _hurt_flash_timer > 0.0:
		_hurt_flash_timer -= delta
	_phase_timer -= delta
	if _charge_phase == 1:
		velocity = Vector2.ZERO
		move_and_slide()
		if _phase_timer <= 0.0:
			_charge_phase = 2
			_phase_timer = charge_duration
			print("[%s] LAO HÚC! tốc độ %.0f theo hướng %s" % [display_name, charge_speed, str(_charge_dir)])
	else: # đang lao
		velocity = _charge_dir * charge_speed
		_facing = _charge_dir
		move_and_slide()
		# Chạm tầm đánh của base -> kết thúc lao, để base ATTACK gây damage
		var p := _find_player()
		if p != null and global_position.distance_to(p.global_position) <= attack_range:
			_end_charge()
			state = State.ATTACK
		elif _phase_timer <= 0.0:
			_end_charge()
	_update_animation()
	_apply_modulate()


func _end_charge() -> void:
	_charge_phase = 0
	_charge_cd_timer = charge_cooldown
	velocity = Vector2.ZERO


func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


func _try_start_charge() -> void:
	if _charge_cd_timer > 0.0 or state != State.CHASE:
		return
	var p := _find_player()
	if p == null:
		return
	var to_player: Vector2 = p.global_position - global_position
	var dist := to_player.length()
	if dist > charge_range or dist <= attack_range:
		return
	# Phải gần thẳng tầm: hướng mặt hiện tại lệch hướng tới player < 25°
	if rad_to_deg(_facing.angle_to(to_player.normalized())) > charge_angle_deg:
		return
	_charge_dir = to_player.normalized()
	_charge_phase = 1
	_phase_timer = charge_windup_time
	charge_count += 1
	print("[%s] GỒNG húc... (player cách %.0fpx)" % [display_name, dist])
