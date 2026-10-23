extends CharacterBody2D
## EnemyBase - Lớp enemy dùng chung (chuột, slime, và boss qua kế thừa).
## AI state machine như goblin: IDLE (wander chậm) / CHASE / ATTACK / DEAD.
## API khớp goblin: take_damage(amount, from_position), group "enemy",
## chết -> GameState.add_xp/add_gold + QuestManager.on_enemy_killed(enemy_type).
## Hình ảnh: AnimatedSprite2D tên "Sprite" + SpriteFrames gán qua @export
## sprite_frames (mỗi loài gán trong .tscn riêng). Animation theo hướng:
## idle_*/walk_*/attack_* (down/up/side, trái = flip_h), hurt, death.
## Thiếu animation nào thì bỏ qua an toàn (has_animation), riêng death
## thiếu thì fallback chờ 0.4s rồi queue_free.

signal died(enemy: Node2D)
signal health_changed(current_hp: int, max_hp: int)

enum State { IDLE, CHASE, ATTACK, DEAD }

@export var enemy_type: String = "enemy"
@export var display_name: String = "Enemy"
@export var max_hp: int = 20
@export var damage: int = 5
@export var speed: float = 100.0
@export var xp_reward: int = 10
@export var gold_reward: int = 3
@export var detect_range: float = 220.0
@export var attack_range: float = 42.0
@export var attack_cooldown_time: float = 1.0
@export var sprite_frames: SpriteFrames = null
@export var sprite_modulate: Color = Color(1, 1, 1, 1)
@export var sprite_scale: float = 1.0
@export var wander: bool = true
@export var death_anim_duration: float = 0.5 # chờ animation death rồi mới queue_free
# --- Rơi vật phẩm / elite / respawn (Gameplay Systems) ---
@export var drop_potion_chance: float = 0.15 # tỉ lệ rơi 1 bình máu khi chết
@export var drop_herb_chance: float = 0.20 # tỉ lệ rơi thảo dược (quest collect "herb")
@export var drop_equip_chance: float = 0.06 # tỉ lệ rơi 1 trang bị ngẫu nhiên
@export var respawn_time: float = 0.0 # 0 = chết hẳn; >0 = hồi sinh tại điểm gốc sau N giây
@export var is_elite: bool = false # biến thể tinh nhuệ: HP/dmg/thưởng x3/x1.5/x3, to + vàng hơn
@export var key_flag: String = "" # flag GameState set khi chết (vd chìa khoá mở cửa khoá)

# Bảng trang bị rơi ngẫu nhiên: [tên, +ATK, +DEF]
const EQUIP_TABLE: Array = [
	["Dao Găm Sắt", 2, 0],
	["Kiếm Ngắn Cũ", 3, 0],
	["Áo Da Cứng", 0, 2],
	["Găng Da Thú", 1, 1],
]

var hp: int = 20
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
var _base_sprite_scale: Vector2 = Vector2.ONE
# Lưu gốc cho respawn (sau khi đã áp elite trong _ready)
var _elite_applied: bool = false
var _respawn_modulate: Color = Color(1, 1, 1, 1)
var _respawn_sprite_scale: Vector2 = Vector2.ONE
var _orig_collision_layer: int = 0
var _orig_collision_mask: int = 0
var _loot_text_count: int = 0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# Elite: áp hệ số TRƯỚC khi chốt hp / scale / modulate gốc.
	if is_elite and not _elite_applied:
		_elite_applied = true
		max_hp *= 3
		damage = int(round(float(damage) * 1.5))
		xp_reward *= 3
		gold_reward *= 3
		sprite_scale *= 1.25
		sprite_modulate = Color(sprite_modulate.r * 1.15, sprite_modulate.g * 1.05,
			sprite_modulate.b * 0.8, sprite_modulate.a)
	hp = max_hp
	add_to_group("enemy")
	_home_position = global_position
	_orig_collision_layer = collision_layer
	_orig_collision_mask = collision_mask
	if sprite != null:
		_base_sprite_scale = sprite.scale
		if sprite_frames != null:
			sprite.sprite_frames = sprite_frames
		sprite.scale = _base_sprite_scale * sprite_scale
		sprite.modulate = sprite_modulate
	# Gốc để respawn khôi phục (đã gồm elite tint/scale nếu có)
	_respawn_modulate = sprite_modulate
	if sprite != null:
		_respawn_sprite_scale = sprite.scale
	health_changed.emit(hp, max_hp)
	_update_animation()


## Tốc độ di chuyển hiệu dụng — boss override để tăng tốc ở phase 2.
func _move_speed() -> float:
	return speed


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
		sprite.modulate = sprite_modulate


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
		# Không có player: vẫn wander nhẹ để quái trông sống động
		if wander:
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_wander_timer = randf_range(1.0, 2.5)
				_wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				if randf() < 0.4:
					_wander_dir = Vector2.ZERO
			velocity = _wander_dir * _move_speed() * 0.35
			if _wander_dir != Vector2.ZERO:
				_facing = _wander_dir
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		_apply_modulate()
		return

	var dist: float = global_position.distance_to(_player.global_position)

	match state:
		State.IDLE:
			# Lang thang nhẹ quanh điểm spawn (nếu bật wander)
			if wander:
				_wander_timer -= delta
				if _wander_timer <= 0.0:
					_wander_timer = randf_range(1.0, 2.5)
					_wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
					if randf() < 0.4:
						_wander_dir = Vector2.ZERO
				velocity = _wander_dir * _move_speed() * 0.35
				if _wander_dir != Vector2.ZERO:
					_facing = _wander_dir
			else:
				velocity = Vector2.ZERO
			if dist <= detect_range:
				state = State.CHASE
		State.CHASE:
			var dir := (_player.global_position - global_position).normalized()
			_facing = dir
			velocity = dir * _move_speed()
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
					print("[%s] Tấn công player, gây %d damage" % [display_name, damage])
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
	print("[%s] Nhận %d damage, HP còn %d/%d" % [display_name, amount, hp, max_hp])
	# Bị đánh thì chuyển sang chase ngay
	if state == State.IDLE:
		state = State.CHASE
	# Knockback nhẹ
	if from_position != Vector2.ZERO:
		var kb_dir := (global_position - from_position).normalized()
		global_position += kb_dir * 8.0
		_facing = (from_position - global_position).normalized() # quay mặt về phía kẻ đánh
	if hp <= 0:
		_die()


## Hook cho lớp con (boss) chạy thêm logic lúc chết — base để trống.
func _on_death() -> void:
	pass


# --- Rơi vật phẩm --------------------------------------------------------

## Chữ loot bay lên + mờ dần tại vị trí quái (phản hồi nhìn thấy được).
## Label thêm vào parent của enemy để không bị queue_free theo xác quái.
func _spawn_loot_text(text: String, color: Color) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.z_index = 100
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var stack_offset := float(_loot_text_count) * 18.0
	_loot_text_count += 1
	lbl.position = global_position + Vector2(-70.0, -64.0 - stack_offset)
	lbl.size = Vector2(140, 22)
	parent_node.add_child(lbl)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 42.0, 1.2)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.2)
	tw.chain().tween_callback(lbl.queue_free)


## Roll rơi vật phẩm khi chết (gọi đồng bộ trong _die trước mọi await,
## để thưởng/loot áp dụng ngay trong frame chết như XP/gold).
func _roll_drops() -> void:
	_loot_text_count = 0
	# Bình máu: elite chắc chắn rơi, thường theo tỉ lệ
	var got_potion: bool = is_elite or randf() < drop_potion_chance
	if got_potion and has_node("/root/GameState"):
		GameState.add_potions(1)
		_spawn_loot_text("+1 Bình máu", Color(1.0, 0.55, 0.6))
		print("[%s] Rơi: Bình máu" % display_name)
	# Thảo dược (vật phẩm quest "herb")
	if randf() < drop_herb_chance and has_node("/root/QuestManager"):
		QuestManager.on_item_collected("herb")
		_spawn_loot_text("Thảo dược!", Color(0.55, 1.0, 0.55))
		print("[%s] Rơi: Thảo dược" % display_name)
	# Trang bị ngẫu nhiên trong bảng nhỏ
	if randf() < drop_equip_chance and has_node("/root/GameState"):
		var row: Array = EQUIP_TABLE[randi() % EQUIP_TABLE.size()]
		var e_name := str(row[0])
		var e_atk := int(row[1])
		var e_def := int(row[2])
		GameState.add_equipment(e_name, e_atk, e_def)
		var bonus_txt := ""
		if e_atk > 0:
			bonus_txt += "+%d ATK" % e_atk
		if e_def > 0:
			bonus_txt += (" " if bonus_txt != "" else "") + "+%d DEF" % e_def
		_spawn_loot_text("Trang bị: %s (%s)" % [e_name, bonus_txt], Color(0.65, 0.85, 1.0))
		print("[%s] Rơi trang bị: %s (%s)" % [display_name, e_name, bonus_txt])
	# Chìa khoá / flag sự kiện từ quái (vd elite giữ chìa hầm)
	if key_flag != "" and has_node("/root/GameState"):
		GameState.set_flag(key_flag)
		_spawn_loot_text("Nhận: Chìa khóa!", Color(1.0, 0.85, 0.3))
		print("[%s] Rơi chìa khoá -> set_flag('%s')" % [display_name, key_flag])


## Hồi sinh sau respawn_time: về điểm gốc, đầy máu, bật lại va chạm.
func _do_respawn() -> void:
	global_position = _home_position
	hp = max_hp
	state = State.IDLE
	velocity = Vector2.ZERO
	_attack_timer = 0.0
	_hurt_flash_timer = 0.0
	_hurt_timer = 0.0
	sprite_modulate = _respawn_modulate
	if sprite != null:
		sprite.scale = _respawn_sprite_scale
		sprite.modulate = _respawn_modulate
		sprite.visible = true
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	set_deferred("collision_layer", _orig_collision_layer)
	set_deferred("collision_mask", _orig_collision_mask)
	visible = true
	_anim_current = &""
	health_changed.emit(hp, max_hp)
	_update_animation()
	_apply_modulate()
	print("[%s] Đã hồi sinh tại điểm gốc (HP %d/%d)" % [display_name, hp, max_hp])


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	died.emit(self)
	print("[%s] Chết! Rơi %d XP, %d gold" % [display_name, xp_reward, gold_reward])
	# Thưởng qua GameState + QuestManager (khớp hợp đồng goblin)
	if has_node("/root/GameState"):
		GameState.add_xp(xp_reward)
		GameState.add_gold(gold_reward)
	if has_node("/root/QuestManager"):
		QuestManager.on_enemy_killed(enemy_type)
	_roll_drops()
	_on_death()
	# Tắt va chạm ngay (không chắn đường / không bị đánh tiếp) nhưng giữ xác
	# trên đất cho animation death chạy hết rồi mới biến mất.
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	_anim_current = &""
	var has_death := sprite != null and sprite.sprite_frames != null \
		and sprite.sprite_frames.has_animation(&"death")
	if has_death:
		_play_anim(&"death")
		await get_tree().create_timer(death_anim_duration).timeout
	else:
		# SpriteFrames thiếu animation death: fallback chờ 0.4s rồi free
		await get_tree().create_timer(0.4).timeout
	if respawn_time > 0.0:
		# Không biến mất: ẩn xác, chờ respawn_time rồi hồi sinh tại điểm gốc.
		# state vẫn DEAD trong lúc chờ -> take_damage bị chặn, không tính kill thêm.
		visible = false
		if sprite != null:
			sprite.visible = false
		await get_tree().create_timer(respawn_time).timeout
		if not is_inside_tree():
			return
		_do_respawn()
		return
	queue_free()
