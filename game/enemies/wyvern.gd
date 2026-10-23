extends "res://enemies/enemy_base.gd"
## Wyvern non — quái bay vùng núi Đông: melee như base, thỉnh thoảng LƯỚT
## (dash) vào player: khi đang CHASE, player cách 70–260px và dash sẵn
## sàng -> lao thẳng tốc độ dash_speed (300) trong dash_duration (0.3s),
## cooldown dash_cooldown (4s). Cơ chế giống đòn húc của lợn rừng nhưng
## nhẹ và không cần gồng. Sprite đặt cao hơn mặt đất trong .tscn (bay).

@export var dash_range_min: float = 70.0
@export var dash_range_max: float = 260.0
@export var dash_speed: float = 300.0
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 4.0

var dash_count: int = 0
var _dash_cd_timer: float = 2.0 # lần lướt đầu chờ 2s sau khi vào trận
var _dashing: bool = false
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity = Vector2.ZERO
		return
	if _dash_cd_timer > 0.0:
		_dash_cd_timer -= delta
	if _dashing:
		_tick_dash(delta)
		return
	super._physics_process(delta)
	_try_start_dash()


func _tick_dash(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _attack_anim_timer > 0.0:
		_attack_anim_timer -= delta
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
	if _hurt_flash_timer > 0.0:
		_hurt_flash_timer -= delta
	_dash_timer -= delta
	velocity = _dash_dir * dash_speed
	_facing = _dash_dir
	move_and_slide()
	var p := _find_player()
	if p != null and global_position.distance_to(p.global_position) <= attack_range:
		_end_dash()
		state = State.ATTACK
	elif _dash_timer <= 0.0:
		_end_dash()
	_update_animation()
	_apply_modulate()


func _end_dash() -> void:
	_dashing = false
	_dash_cd_timer = dash_cooldown
	velocity = Vector2.ZERO


func _try_start_dash() -> void:
	if _dash_cd_timer > 0.0 or state != State.CHASE:
		return
	var p := _find_player()
	if p == null:
		return
	var dist := global_position.distance_to(p.global_position)
	if dist < dash_range_min or dist > dash_range_max:
		return
	_dash_dir = (p.global_position - global_position).normalized()
	_dashing = true
	_dash_timer = dash_duration
	dash_count += 1
	print("[%s] LƯỚT vào player! (lần %d, cách %.0fpx)" % [display_name, dash_count, dist])


func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null
