extends CharacterBody2D
## Goblin - Enemy mẫu
## AI state machine: idle / chase / attack / dead
## Hình ảnh: AnimatedSprite2D + SpriteFrames (assets/sprites/goblin_frames.tres),
## animation bám theo state. Chết: chơi hết animation death rồi mới biến mất.

signal died(enemy: Node2D)
signal health_changed(current_hp: int, max_hp: int)

enum State { IDLE, CHASE, ATTACK, DEAD }

@export var max_hp: int = 30
@export var speed: float = 110.0
@export var damage: int = 8
@export var detect_range: float = 220.0
@export var attack_range: float = 42.0
@export var attack_cooldown_time: float = 1.0
@export var xp_reward: int = 15
@export var gold_reward: int = 5
@export var death_anim_duration: float = 0.6 # chờ animation death (2 frame @4fps = 0.5s) rồi mới queue_free

var hp: int = 30
var state: State = State.IDLE
var _player: Node2D = null
var _attack_timer: float = 0.0
var _wander_dir: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _home_position: Vector2 = Vector2.ZERO

# Animation
var _facing: Vector2 = Vector2.DOWN
var _anim_current: StringName = &""
var _attack_anim_timer: float = 0.0
var _hurt_timer: float = 0.0
var _hurt_flash_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	_home_position = global_position
	health_changed.emit(hp, max_hp)
	_update_animation()


# --- Animation helpers -------------------------------------------------

func _facing_suffix() -> String:
	if absf(_facing.x) > absf(_facing.y):
		return "side"
	return "up" if _facing.y < 0.0 else "down"


func _play_anim(anim_name: StringName) -> void:
	# An toàn: thiếu sprite/frames/animation thì bỏ qua, không crash game.
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(anim_name):
		return
	if _anim_current != anim_name:
		sprite.play(anim_name)
		_anim_current = anim_name


func _update_animation() -> void:
	if sprite == null or state == State.DEAD:
		return
	var suffix := _facing_suffix()
	sprite.flip_h = suffix == "side" and _facing.x < 0.0
	# Đi lang thang ở IDLE thì walk chạy chậm lại cho khác chase
	var target_scale := 0.45 if (state == State.IDLE and velocity.length() > 5.0) else 1.0
	if not is_equal_approx(sprite.speed_scale, target_scale):
		sprite.speed_scale = target_scale
	var target: StringName
	if _attack_anim_timer > 0.0:
		target = StringName("attack_" + suffix)
	elif _hurt_timer > 0.0:
		target = &"hurt"
	elif state == State.CHASE:
		target = StringName("walk_" + suffix)
	elif state == State.ATTACK:
		target = StringName("idle_" + suffix)
	elif velocity.length() > 5.0:
		target = StringName("walk_" + suffix)
	else:
		target = StringName("idle_" + suffix)
	_play_anim(target)


func _apply_modulate() -> void:
	if sprite == null:
		return
	if _hurt_flash_timer > 0.0:
		sprite.modulate = Color(1.0, 0.35, 0.35, 1.0)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


# --- AI / gameplay -------------------------------------------------------

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity = Vector2.ZERO
		return
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _attack_anim_timer > 0.0:
		_attack_anim_timer -= delta
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
	if _hurt_flash_timer > 0.0:
		_hurt_flash_timer -= delta

	# Tìm player
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		_player = players[0] if players.size() > 0 else null
	if _player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		_apply_modulate()
		return

	var dist: float = global_position.distance_to(_player.global_position)

	match state:
		State.IDLE:
			# Lang thang nhẹ quanh điểm spawn
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_wander_timer = randf_range(1.0, 2.5)
				_wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				if randf() < 0.4:
					_wander_dir = Vector2.ZERO
			velocity = _wander_dir * speed * 0.35
			if _wander_dir != Vector2.ZERO:
				_facing = _wander_dir
			if dist <= detect_range:
				state = State.CHASE
		State.CHASE:
			var dir := (_player.global_position - global_position).normalized()
			_facing = dir
			velocity = dir * speed
			if dist <= attack_range:
				state = State.ATTACK
			elif dist > detect_range * 1.4:
				state = State.IDLE
		State.ATTACK:
			velocity = Vector2.ZERO
			_facing = (_player.global_position - global_position).normalized()
			if dist > attack_range * 1.25:
				state = State.CHASE
			elif _attack_timer <= 0.0:
				_attack_timer = attack_cooldown_time
				_attack_anim_timer = 0.3
				_anim_current = &"" # ép animation attack chạy lại từ đầu
				if _player.has_method("take_damage"):
					_player.take_damage(damage, global_position)
					print("[Goblin] Tấn công player, gây %d damage" % damage)
		State.DEAD:
			pass

	move_and_slide()
	_update_animation()
	_apply_modulate()


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEAD:
		return
	hp = max(0, hp - amount)
	health_changed.emit(hp, max_hp)
	# Flash đỏ + animation hurt khi trúng đòn
	_hurt_flash_timer = 0.12
	_hurt_timer = 0.15
	print("[Goblin] Nhận %d damage, HP còn %d/%d" % [amount, hp, max_hp])
	# Bị đánh thì chuyển sang chase ngay
	if state == State.IDLE:
		state = State.CHASE
	# Knockback nhẹ
	if from_position != Vector2.ZERO:
		var kb_dir := (global_position - from_position).normalized()
		global_position += kb_dir * 8.0
	if from_position != Vector2.ZERO:
		_facing = (from_position - global_position).normalized() # quay mặt về phía kẻ đánh
	if hp <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	died.emit(self)
	print("[Goblin] Chết! Rơi %d XP, %d gold (stub loot)" % [xp_reward, gold_reward])
	# Thưởng stub qua GameState + QuestManager
	if has_node("/root/GameState"):
		GameState.add_xp(xp_reward)
		GameState.add_gold(gold_reward)
	if has_node("/root/QuestManager"):
		QuestManager.on_enemy_killed("goblin")
	# TODO: spawn loot item thật ở vertical slice
	# Tắt va chạm ngay (không chắn đường / không bị đánh tiếp) nhưng giữ xác
	# trên đất cho animation death chạy hết rồi mới biến mất.
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	_anim_current = &""
	_play_anim(&"death")
	await get_tree().create_timer(death_anim_duration).timeout
	queue_free()
