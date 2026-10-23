extends CharacterBody2D
## Player - Nhân vật chính
## Di chuyển 8 hướng, combo chém 3 hit, dodge lăn có i-frame, HP/Stamina.
## Hình ảnh: AnimatedSprite2D + SpriteFrames (assets/sprites/player_frames.tres).
## Animation theo trạng thái, ưu tiên: death > dodge > attack > hurt > walk > idle.
## Hướng: down/up/side (trái = flip_h của side). Nếu SpriteFrames lỗi/thiếu
## thì game vẫn chạy (mọi lần play đều kiểm tra has_animation trước).

signal health_changed(current_hp: int, max_hp: int)
signal stamina_changed(current_stamina: float, max_stamina: float)
signal died

@export var speed: float = 220.0
@export var max_hp: int = 100
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 28.0
@export var dodge_stamina_cost: float = 25.0
@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.28
@export var attack_range: float = 56.0
@export var attack_damage: Array[int] = [10, 12, 18] # damage 3 hit combo

var hp: int = 100
var stamina: float = 100.0

var facing: Vector2 = Vector2.DOWN
var is_dodging: bool = false
var is_invincible: bool = false # i-frame khi dodge
var _dodge_timer: float = 0.0
var _dodge_dir: Vector2 = Vector2.DOWN

# Combo
var _combo_index: int = 0
var _combo_timer: float = 0.0
var combo_window: float = 0.9 # quá thời gian này thì reset combo
var _attack_cooldown: float = 0.0
var attack_cooldown_time: float = 0.32
var _attack_flash: float = 0.0

# Animation
var _anim_current: StringName = &""
var _attack_anim_timer: float = 0.0 # giữ animation chém theo nhịp cooldown
var _hurt_timer: float = 0.0 # thời gian hiện animation hurt
var _hurt_flash_timer: float = 0.0 # thời gian flash đỏ khi trúng đòn
var _death_timer: float = 0.0 # thời gian hiện animation death (trước respawn stub)

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	hp = max_hp
	# Khởi tạo HP từ GameState (save/load) thay vì luôn đầy máu:
	# nếu GameState có HP > 0 thì lấy theo, clamp trong 1..max_hp.
	if has_node("/root/GameState"):
		if GameState.player_max_hp > 0:
			max_hp = GameState.player_max_hp
		if GameState.player_hp > 0:
			hp = clampi(GameState.player_hp, 1, max_hp)
	stamina = max_stamina
	add_to_group("player")
	# Đồng bộ HP khởi tạo sang GameState
	if has_node("/root/GameState"):
		GameState.set_player_hp(hp, max_hp)
	health_changed.emit(hp, max_hp)
	stamina_changed.emit(stamina, max_stamina)
	if attack_shape:
		attack_shape.disabled = true
	_update_animation(false)
	# Nhận quest mẫu đầu game (để goblin kill có tác dụng ngay khi test)
	if has_node("/root/QuestManager"):
		QuestManager.accept_quest("dong_01_goblin")


# --- Animation helpers -------------------------------------------------

func _facing_suffix() -> String:
	if absf(facing.x) > absf(facing.y):
		return "side"
	return "up" if facing.y < 0.0 else "down"


func _play_anim(anim_name: StringName) -> void:
	# An toàn: thiếu sprite/frames/animation thì bỏ qua, không crash game.
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
	# Lật ngang chỉ áp dụng cho hướng side
	sprite.flip_h = suffix == "side" and facing.x < 0.0
	var target: StringName
	if _death_timer > 0.0:
		target = &"death"
	elif is_dodging:
		target = StringName("dodge_" + suffix)
	elif _attack_anim_timer > 0.0:
		target = StringName("attack_" + suffix)
	elif _hurt_timer > 0.0:
		target = &"hurt"
	elif moving:
		target = StringName("walk_" + suffix)
	else:
		target = StringName("idle_" + suffix)
	_play_anim(target)


func _apply_modulate() -> void:
	if sprite == null:
		return
	# Flash đỏ khi trúng đòn (không liên quan i-frame), mờ 0.55 khi dodge (i-frame)
	var a := 0.55 if is_dodging else 1.0
	if _hurt_flash_timer > 0.0:
		sprite.modulate = Color(1.0, 0.35, 0.35, a)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, a)


# --- Gameplay ----------------------------------------------------------

func _physics_process(delta: float) -> void:
	# Đang nói chuyện / mua đồ: khóa toàn bộ input + di chuyển
	if has_node("/root/GameState") and GameState.in_dialogue:
		velocity = Vector2.ZERO
		return

	# --- Timers ---
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_index = 0
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _attack_anim_timer > 0.0:
		_attack_anim_timer -= delta
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
	if _hurt_flash_timer > 0.0:
		_hurt_flash_timer -= delta
	if _death_timer > 0.0:
		_death_timer -= delta
	if _attack_flash > 0.0:
		_attack_flash -= delta
		queue_redraw()

	# --- Dodge ---
	if is_dodging:
		_dodge_timer -= delta
		velocity = _dodge_dir * dodge_speed
		if _dodge_timer <= 0.0:
			is_dodging = false
			is_invincible = false
		move_and_slide()
		_update_animation(false)
		_apply_modulate()
		return

	# --- Di chuyển 8 hướng ---
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()
	velocity = input_dir * speed
	move_and_slide()
	_update_animation(input_dir != Vector2.ZERO)

	# --- Regen stamina (không regen ngay khi vừa dodge/attack vẫn cho regen chậm) ---
	if stamina < max_stamina:
		stamina = min(max_stamina, stamina + stamina_regen * delta)
		stamina_changed.emit(stamina, max_stamina)

	# --- Hành động ---
	if Input.is_action_just_pressed("dodge"):
		_try_dodge(input_dir)
	elif Input.is_action_just_pressed("attack"):
		_try_attack()
	elif Input.is_action_just_pressed("interact"):
		_try_interact()
	elif Input.is_action_just_pressed("use_potion"):
		_try_use_potion()
	elif Input.is_action_just_pressed("skill_1"):
		_use_skill(1)
	elif Input.is_action_just_pressed("skill_2"):
		_use_skill(2)

	_apply_modulate()


func _try_dodge(input_dir: Vector2) -> void:
	if is_dodging or stamina < dodge_stamina_cost:
		return
	stamina -= dodge_stamina_cost
	stamina_changed.emit(stamina, max_stamina)
	_dodge_dir = input_dir if input_dir != Vector2.ZERO else facing
	facing = _dodge_dir
	is_dodging = true
	is_invincible = true
	_dodge_timer = dodge_duration
	_anim_current = &"" # ép animation dodge chạy lại từ frame đầu
	print("[Player] Dodge! i-frame %.2fs" % dodge_duration)


## Damage hiệu dụng của hit combo_index: damage gốc + ATK trang bị
## (GameState.attack_bonus) + 2 mỗi cấp trên cấp 1.
func effective_damage(combo_index: int = 0) -> int:
	var base: int = attack_damage[combo_index] if combo_index >= 0 and combo_index < attack_damage.size() else attack_damage[0]
	if has_node("/root/GameState"):
		base += GameState.attack_bonus + (GameState.level - 1) * 2
	return base


func _try_attack() -> void:
	if _attack_cooldown > 0.0 or is_dodging:
		return
	_attack_cooldown = attack_cooldown_time
	_attack_flash = 0.12
	# Animation chém chạy ngay khi bấm — damage vẫn tính theo hitbox bên dưới,
	# không chờ animation tới frame nào cả.
	_attack_anim_timer = attack_cooldown_time
	_anim_current = &""
	_play_anim(StringName("attack_" + _facing_suffix()))
	var dmg: int = effective_damage(_combo_index)
	print("[Player] Chém hit %d - damage %d" % [_combo_index + 1, dmg])

	# Đặt hitbox về phía đang nhìn rồi kiểm tra enemy trong vùng
	if attack_area:
		attack_area.position = facing * 36.0
		if attack_shape:
			attack_shape.disabled = false
		# Chờ 1 physics frame để Area2D cập nhật overlap — dùng kiểm tra khoảng cách bổ sung cho chắc chắn chạy được
		await get_tree().physics_frame
		var hit_any := false
		for body in attack_area.get_overlapping_bodies():
			if body.has_method("take_damage") and body.is_in_group("enemy"):
				body.take_damage(dmg, global_position)
				hit_any = true
		# Fallback: kiểm tra khoảng cách (phòng khi setup collision layer khác nhau)
		if not hit_any:
			for e in get_tree().get_nodes_in_group("enemy"):
				if e is Node2D and e.has_method("take_damage"):
					var dist: float = global_position.distance_to(e.global_position)
					var dir_to: Vector2 = (e.global_position - global_position).normalized()
					if dist <= attack_range and facing.dot(dir_to) > 0.3:
						e.take_damage(dmg, global_position)
		if attack_shape:
			attack_shape.disabled = true

	# Tăng combo
	_combo_index = (_combo_index + 1) % attack_damage.size()
	_combo_timer = combo_window
	queue_redraw()


# Tương tác: gọi interact() của interactable gần nhất trong 56px (NPC...)
func _try_interact() -> void:
	var best: Node2D = null
	var best_dist := 56.0
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is Node2D and n.has_method("interact"):
			var d: float = global_position.distance_to(n.global_position)
			if d <= best_dist:
				best = n
				best_dist = d
	if best != null:
		best.interact()


# Dùng bình máu (phím H): hồi 50 HP, trừ qua GameState.use_potion()
func _try_use_potion() -> void:
	if not has_node("/root/GameState"):
		return
	if hp >= max_hp:
		print("[Player] Máu đã đầy, không cần dùng bình.")
		return
	if GameState.use_potion():
		heal(50)
		print("[Player] Dùng bình máu: +50 HP (còn %d bình)" % GameState.potions)
	else:
		print("[Player] Hết bình máu!")


func _use_skill(skill_id: int) -> void:
	# Stub — sẽ làm ở vertical slice
	var cost: float = 20.0 if skill_id == 1 else 35.0
	if stamina < cost:
		print("[Player] Không đủ stamina cho skill_%d" % skill_id)
		return
	stamina -= cost
	stamina_changed.emit(stamina, max_stamina)
	print("[Player] Dùng skill_%d (STUB) - tốn %.0f stamina" % [skill_id, cost])


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or hp <= 0:
		return
	# DEF trang bị giảm damage nhận vào, tối thiểu vẫn mất 1 HP.
	var effective: int = amount
	if has_node("/root/GameState"):
		effective = maxi(1, amount - GameState.defense_bonus)
	hp = max(0, hp - effective)
	health_changed.emit(hp, max_hp)
	if has_node("/root/GameState"):
		GameState.set_player_hp(hp, max_hp)
	# Hiệu ứng trúng đòn: flash đỏ + animation hurt (i-frame không đổi)
	_hurt_flash_timer = 0.12
	_hurt_timer = 0.18
	print("[Player] Nhận %d damage, HP còn %d/%d" % [effective, hp, max_hp])
	if hp <= 0:
		died.emit()
		print("[Player] Đã gục! (Respawn stub)")
		# Hiện animation death một nhịp ngắn rồi mới respawn stub hồi đầy máu tại chỗ
		_death_timer = 0.6
		_anim_current = &""
		_play_anim(&"death")
		hp = max_hp
		health_changed.emit(hp, max_hp)
		if has_node("/root/GameState"):
			GameState.set_player_hp(hp, max_hp)


func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	health_changed.emit(hp, max_hp)
	if has_node("/root/GameState"):
		GameState.set_player_hp(hp, max_hp)


func _draw() -> void:
	# Vẽ vòng tấn công chớp nhoáng khi chém (giữ lại: vẫn hợp với vệt kiếm của sprite)
	if _attack_flash > 0.0:
		var arc_center := facing * 36.0
		draw_circle(arc_center, 22.0, Color(1, 1, 1, 0.35))
