extends "res://enemies/enemy_base.gd"
## Nhện rừng — quái bắn xa: giữ khoảng cách với player và nhả độc.
##  - Player < 120px: lùi ra xa. Player > 200px: tiến lại gần.
##  - Trong dải 120–220px: đứng yên, mỗi shoot_interval (1.8s) bắn 1 viên
##    poison_shot (bay thẳng hướng player lúc bắn, 8 damage).
## Ngoài tầm 260 (shoot_range) hoặc chưa thấy player: nhường AI base
## (wander / chase như thường). Script tự lái khi player trong tầm bắn
## để base không lao vào melee.

const POISON_SHOT_SCENE: PackedScene = preload("res://enemies/poison_shot.tscn")

@export var keep_min_dist: float = 120.0
@export var keep_max_dist: float = 200.0
@export var shoot_band_max: float = 220.0
@export var shoot_range: float = 260.0
@export var shoot_interval: float = 1.8

var shots_fired: int = 0
var _shoot_timer: float = 0.9 # phát đầu sớm hơn một chút cho vui mắt


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity = Vector2.ZERO
		return
	if _shoot_timer > 0.0:
		_shoot_timer -= delta
	var p := _find_player()
	if p == null or global_position.distance_to(p.global_position) > shoot_range:
		super._physics_process(delta)
		return
	# Tự lái: giữ khoảng cách + bắn độc (không gọi super để tránh melee)
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _attack_anim_timer > 0.0:
		_attack_anim_timer -= delta
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
	if _hurt_flash_timer > 0.0:
		_hurt_flash_timer -= delta
	_player = p
	if state == State.IDLE:
		state = State.CHASE
	if state == State.ATTACK:
		state = State.CHASE
	var to_player: Vector2 = p.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized() if dist > 0.01 else Vector2.DOWN
	_facing = dir
	if dist < keep_min_dist:
		velocity = -dir * _move_speed()
	elif dist > keep_max_dist:
		velocity = dir * _move_speed()
	else:
		velocity = Vector2.ZERO
		if _shoot_timer <= 0.0:
			_shoot(p)
	move_and_slide()
	_update_animation()
	_apply_modulate()


func _shoot(p: Node2D) -> void:
	_shoot_timer = shoot_interval
	shots_fired += 1
	_attack_anim_timer = 0.3
	_anim_current = &""
	var shot: Node2D = POISON_SHOT_SCENE.instantiate()
	var parent: Node = get_parent()
	if parent == null:
		return
	parent.add_child(shot)
	shot.global_position = global_position + _facing * 18.0
	if shot.has_method("launch"):
		shot.launch((p.global_position - global_position).normalized(), damage)
	print("[%s] Nhả độc vào player (phát #%d)" % [display_name, shots_fired])


func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null
