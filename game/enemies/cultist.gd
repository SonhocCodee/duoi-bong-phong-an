extends "res://enemies/enemy_base.gd"
## Tín Đồ Giáo Phái Fenmire — quái người bắn xa bằng Chỉ Ấn (shadow_bolt).
## Pattern theo spider.gd (Nhện rừng): giữ khoảng cách với player và bắn đạn.
##  - Player < keep_min_dist (140px): lùi ra xa. Player > keep_max_dist
##    (220px): tiến lại gần.
##  - Trong dải 140–260px: đứng yên, mỗi shoot_interval (2.2s) bắn 1 viên
##    shadow_bolt (bay thẳng hướng player lúc bắn, damage = export damage
##    = 15, truyền qua launch(dir, damage) như boss_vua).
## Ngoài tầm shoot_range (320px) hoặc chưa thấy player: nhường AI base
## (wander / chase như thường). Script tự lái khi player trong tầm bắn
## để base không lao vào melee. Melee của base vẫn dùng chung damage=15
## nếu player áp sát ngoài ý muốn (giống spider: damage dùng cho cả
## đạn độc lẫn đòn melee của base).

const SHADOW_BOLT_SCENE: PackedScene = preload("res://enemies/shadow_bolt.tscn")

@export var keep_min_dist: float = 140.0
@export var keep_max_dist: float = 220.0
@export var shoot_band_max: float = 260.0
@export var shoot_range: float = 320.0
@export var shoot_interval: float = 2.2

var shots_fired: int = 0
var _shoot_timer: float = 1.1 # phát đầu sớm hơn một chút cho vui mắt


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
	# Tự lái: giữ khoảng cách + bắn Chỉ Ấn (không gọi super để tránh melee)
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
		if _shoot_timer <= 0.0 and dist <= shoot_band_max:
			_shoot(p)
	move_and_slide()
	_update_animation()
	_apply_modulate()


func _shoot(p: Node2D) -> void:
	_shoot_timer = shoot_interval
	var dir := (p.global_position - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = _facing if _facing != Vector2.ZERO else Vector2.DOWN
	_spawn_bolt(dir)


## Bắn 1 viên Chỉ Ấn — API công khai cho boss/test gọi thẳng (bỏ qua
## cooldown/khoảng cách). Không có player thì bắn theo hướng mặt.
func shoot_shadow_bolt() -> void:
	if state == State.DEAD:
		return
	_shoot_timer = shoot_interval
	var dir := _facing if _facing != Vector2.ZERO else Vector2.DOWN
	var p := _find_player()
	if p != null:
		var to_player: Vector2 = p.global_position - global_position
		if to_player.length() > 0.01:
			dir = to_player.normalized()
	_spawn_bolt(dir)


func _spawn_bolt(dir: Vector2) -> void:
	shots_fired += 1
	_attack_anim_timer = 0.3
	_anim_current = &""
	var bolt: Node2D = SHADOW_BOLT_SCENE.instantiate()
	var parent: Node = get_parent()
	if parent == null:
		return
	parent.add_child(bolt)
	bolt.global_position = global_position + dir * 20.0
	if bolt.has_method("launch"):
		bolt.launch(dir, damage)
	print("[%s] Bắn Chỉ Ấn vào player (phát #%d, %d damage)" % [display_name, shots_fired, damage])


func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null
