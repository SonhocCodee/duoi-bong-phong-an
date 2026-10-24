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
signal skill_used(skill_id: String)
signal skill_failed(skill_id: String, reason: String)

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

# --- Skill (GDD v2 mục 5.1, nhánh Chiến binh) ---
# Số liệu STA/CD lấy từ GameState.SKILL_DEFS khi dùng; hằng dưới là fallback
# + thông số hình học/hiệu ứng riêng của từng chiêu.
const SKILL_CHEM_XOAY_RADIUS: float = 96.0 # GDD 80px, nới 96 cho cảm giác
const SKILL_CHEM_XOAY_MULT: float = 1.3
const SKILL_XUNG_KICH_DIST: float = 160.0
const SKILL_XUNG_KICH_WIDTH: float = 48.0 # nửa bề rộng hành lang chém xuyên
const SKILL_XUNG_KICH_MULT: float = 1.1
const SKILL_XUNG_KICH_STUN: float = 0.6
const SKILL_CUONG_NO_DURATION: float = 10.0
const SKILL_CUONG_NO_SPEED_MULT: float = 1.25 # +25% tốc độ đánh
const SKILL_CUONG_NO_DMG_MULT: float = 1.2 # +20% damage
var skill_cooldowns: Dictionary = {"chem_xoay": 0.0, "xung_kich": 0.0, "cuong_no": 0.0,
	"dau_an_lua": 0.0, "bay_hon": 0.0, "hut_sinh_luc": 0.0,
	"cau_lua": 0.0, "gai_bang": 0.0, "set_lan": 0.0,
	"trieu_hoi_bong": 0.0, "cong_phong_an": 0.0, "khien_ma_thuat": 0.0, "mua_thien_thach": 0.0}
var cuong_no_timer: float = 0.0 # >0 = đang Cuồng Nộ
var last_dark_rune: Node = null
var last_soul_trap: Node = null
var last_lifesteal_amount: int = 0
var last_fireball: Node = null
var last_ice_spikes: Node = null
var last_chain_targets: Array = []
var last_chain_total_damage: int = 0
# --- Đợt 6: trang skill 2 (phím Q lật trang) + skill cuối + khiên ---
# Trang 1: phím 1-9 = 9 skill cũ. Trang 2: phím 1-4 = 4 skill đợt 6.
var skill_page: int = 1
const SKILL_PAGE2_SLOTS: Dictionary = {"skill_1": "trieu_hoi_bong", "skill_2": "cong_phong_an",
	"skill_3": "khien_ma_thuat", "skill_4": "mua_thien_thach"}
var magic_shield_hp: int = 0 # HP khiên còn lại (Khiên Ma Thuật)
var magic_shield_timer: float = 0.0 # thời gian khiên còn hiệu lực
var last_shadow_ally: Node = null
var last_meteor_shower: Node = null
var last_seal_gate_from: Vector2 = Vector2.ZERO
var last_seal_gate_to: Vector2 = Vector2.ZERO
const DARK_RUNE_SCENE: PackedScene = preload("res://player/dark_rune.tscn")
const SOUL_TRAP_SCENE: PackedScene = preload("res://player/soul_trap.tscn")
const FIREBALL_SCENE: PackedScene = preload("res://player/fireball.tscn")
const ICE_SPIKES_SCENE: PackedScene = preload("res://player/ice_spikes.tscn")
const SHADOW_ALLY_SCENE: PackedScene = preload("res://player/shadow_ally.tscn")
const METEOR_SHOWER_SCENE: PackedScene = preload("res://player/meteor_shower.tscn")
# Hiệu ứng vẽ bằng _draw (không asset mới)
var _chem_xoay_fx: float = 0.0
var _chain_fx_points: PackedVector2Array = PackedVector2Array()
var _chain_fx: float = 0.0
var _dash_fx: float = 0.0
var _dash_fx_from: Vector2 = Vector2.ZERO
var _dash_fx_to: Vector2 = Vector2.ZERO
var _fx_time: float = 0.0

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
	elif cuong_no_timer > 0.0:
		# Cuồng Nộ: nhuộm đỏ nhẹ liên tục (kèm vòng lửa trong _draw)
		sprite.modulate = Color(1.0, 0.5, 0.4, a)
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
	# --- Skill timers: cooldown từng chiêu + buff Cuồng Nộ + FX ---
	_fx_time += delta
	for sid in skill_cooldowns.keys():
		if float(skill_cooldowns[sid]) > 0.0:
			skill_cooldowns[sid] = maxf(0.0, float(skill_cooldowns[sid]) - delta)
	if cuong_no_timer > 0.0:
		cuong_no_timer = maxf(0.0, cuong_no_timer - delta)
		queue_redraw()
	# Khiên Ma Thuật: hết giờ thì khiên vỡ (phần HP khiên còn lại mất theo)
	if magic_shield_timer > 0.0:
		magic_shield_timer = maxf(0.0, magic_shield_timer - delta)
		queue_redraw()
		if magic_shield_timer <= 0.0 and magic_shield_hp > 0:
			magic_shield_hp = 0
			print("[Player] Khiên Ma Thuật hết giờ — khiên tan.")
	if _chem_xoay_fx > 0.0:
		_chem_xoay_fx -= delta
		queue_redraw()
	if _dash_fx > 0.0:
		_dash_fx -= delta
		queue_redraw()
	if _chain_fx > 0.0:
		_chain_fx -= delta
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
	if Input.is_action_just_pressed("skill_page"):
		skill_page = 2 if skill_page == 1 else 1
		print("[Player] Lật sang trang skill %d." % skill_page)
		queue_redraw()
	elif Input.is_action_just_pressed("dodge"):
		_try_dodge(input_dir)
	elif Input.is_action_just_pressed("attack"):
		_try_attack()
	elif Input.is_action_just_pressed("interact"):
		_try_interact()
	elif Input.is_action_just_pressed("use_potion"):
		_try_use_potion()
	elif Input.is_action_just_pressed("skill_1"):
		_use_skill(_skill_for_slot("skill_1", "chem_xoay"))
	elif Input.is_action_just_pressed("skill_2"):
		_use_skill(_skill_for_slot("skill_2", "xung_kich"))
	elif Input.is_action_just_pressed("skill_3"):
		_use_skill(_skill_for_slot("skill_3", "cuong_no"))
	elif Input.is_action_just_pressed("skill_4"):
		_use_skill(_skill_for_slot("skill_4", "dau_an_lua"))
	elif Input.is_action_just_pressed("skill_5"):
		_use_skill("bay_hon")
	elif Input.is_action_just_pressed("skill_6"):
		_use_skill("hut_sinh_luc")
	elif Input.is_action_just_pressed("skill_7"):
		_use_skill("cau_lua")
	elif Input.is_action_just_pressed("skill_8"):
		_use_skill("gai_bang")
	elif Input.is_action_just_pressed("skill_9"):
		_use_skill("set_lan")

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


## Cooldown đòn thường hiệu dụng: Cuồng Nộ +25% tốc độ đánh -> cooldown / 1.25.
func get_effective_attack_cooldown() -> float:
	if cuong_no_timer > 0.0:
		return attack_cooldown_time / SKILL_CUONG_NO_SPEED_MULT
	return attack_cooldown_time


func is_cuong_no_active() -> bool:
	return cuong_no_timer > 0.0


## Damage hiệu dụng của hit combo_index: damage gốc + ATK trang bị
## (GameState.attack_bonus) + 2 mỗi cấp trên cấp 1.
## Cuồng Nộ đang bật: +20% damage.
func effective_damage(combo_index: int = 0) -> int:
	var base: int = attack_damage[combo_index] if combo_index >= 0 and combo_index < attack_damage.size() else attack_damage[0]
	if has_node("/root/GameState"):
		base += GameState.attack_bonus + (GameState.level - 1) * 2
	if cuong_no_timer > 0.0:
		base = int(round(float(base) * SKILL_CUONG_NO_DMG_MULT))
	return base


func _try_attack() -> void:
	if _attack_cooldown > 0.0 or is_dodging:
		return
	# GHI CHÚ cân bằng: đòn thường hiện không tốn stamina (giữ nguyên thiết
	# kế cũ); khi Cuồng Nộ bật thì điều này thành đặc quyền của buff theo
	# GDD ("đòn thường không tốn stamina trong lúc buff") — không đổi số.
	var cd_now: float = get_effective_attack_cooldown()
	_attack_cooldown = cd_now
	_attack_flash = 0.12
	# Animation chém chạy ngay khi bấm — damage vẫn tính theo hitbox bên dưới,
	# không chờ animation tới frame nào cả.
	_attack_anim_timer = cd_now
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


## Ánh xạ phím số -> skill theo trang hiện tại (trang 2 chỉ có 4 ô đầu).
func _skill_for_slot(action: String, page1_skill: String) -> String:
	if skill_page == 2 and SKILL_PAGE2_SLOTS.has(action):
		return str(SKILL_PAGE2_SLOTS[action])
	return page1_skill


# Dùng bình máu (phím H): hồi 50 HP, trừ qua GameState.use_potion().
# Đợt 6: nếu có Đại Bình Hồi Phục và máu đang hụt >= 90 thì ưu tiên dùng
# đại bình trước (hồi 150 HP) — tránh lãng phí thuốc cấp cao vào vết xước.
func _try_use_potion() -> void:
	if not has_node("/root/GameState"):
		return
	if hp >= max_hp:
		print("[Player] Máu đã đầy, không cần dùng bình.")
		return
	if GameState.greater_potions > 0 and max_hp - hp >= 90 and GameState.use_greater_potion():
		heal(150)
		print("[Player] Dùng ĐẠI BÌNH Hồi Phục: +150 HP (còn %d đại bình)" % GameState.greater_potions)
		return
	if GameState.use_potion():
		heal(50)
		print("[Player] Dùng bình máu: +50 HP (còn %d bình)" % GameState.potions)
	else:
		print("[Player] Hết bình máu!")


# --- Skill thật (GDD v2 mục 5.1) -------------------------------------------

func get_skill_cooldown(skill_id: String) -> float:
	return float(skill_cooldowns.get(skill_id, 0.0))


func get_skill_cooldown_max(skill_id: String) -> float:
	if has_node("/root/GameState") and GameState.SKILL_DEFS.has(skill_id):
		return float(GameState.SKILL_DEFS[skill_id].get("cooldown", 0.0))
	return 0.0


func _skill_def(skill_id: String) -> Dictionary:
	if has_node("/root/GameState") and GameState.SKILL_DEFS.has(skill_id):
		return GameState.SKILL_DEFS[skill_id]
	return {}


## Dùng skill theo id string. Trả true khi chiêu thực sự chạy.
## Chưa mở khoá / đang cooldown / thiếu stamina: không chạy, in log + signal.
func _use_skill(skill_id: String) -> bool:
	var def: Dictionary = _skill_def(skill_id)
	if def.is_empty():
		print("[Player] Skill không tồn tại: %s" % skill_id)
		skill_failed.emit(skill_id, "unknown")
		return false
	# Chưa mở khoá (dữ liệu ở GameState)
	if has_node("/root/GameState") and not GameState.is_skill_unlocked(skill_id):
		print("[Player] Skill '%s' chưa mở khoá — mở cây skill bằng phím T." % str(def.get("name", skill_id)))
		skill_failed.emit(skill_id, "locked")
		return false
	if get_skill_cooldown(skill_id) > 0.0:
		print("[Player] Skill '%s' đang hồi chiêu (%.1fs)." % [str(def.get("name", skill_id)), get_skill_cooldown(skill_id)])
		skill_failed.emit(skill_id, "cooldown")
		return false
	# Hút Sinh Lực không có mục tiêu trong tầm thì không tốn STA/CD.
	if skill_id == "hut_sinh_luc" and _find_dark_target(float(def.get("range", 280.0))) == null:
		print("[Player] Hút Sinh Lực: không có quái trong tầm %.0fpx." % float(def.get("range", 280.0)))
		skill_failed.emit(skill_id, "no_target")
		return false
	# Sét Lan không có mục tiêu trong tầm thì không tốn STA/CD (như Hút Sinh Lực).
	if skill_id == "set_lan" and _find_dark_target(float(def.get("range", 340.0))) == null:
		print("[Player] Sét Lan: không có quái trong tầm %.0fpx." % float(def.get("range", 340.0)))
		skill_failed.emit(skill_id, "no_target")
		return false
	# Cổng Phong Ấn: phía trước bị chặn kín (không khoảng nào đặt chân được
	# trong dải min..max distance) thì không tốn STA/CD.
	if skill_id == "cong_phong_an" and _seal_gate_destination(def) == null:
		print("[Player] Cổng Phong Ấn: phía trước bị chặn kín, không dịch chuyển được.")
		skill_failed.emit(skill_id, "blocked")
		return false
	var cost: float = float(def.get("stamina_cost", 0.0))
	if stamina < cost:
		print("[Player] Không đủ stamina cho '%s' (cần %.0f, có %.0f)" % [str(def.get("name", skill_id)), cost, stamina])
		skill_failed.emit(skill_id, "stamina")
		return false
	stamina -= cost
	stamina_changed.emit(stamina, max_stamina)
	skill_cooldowns[skill_id] = float(def.get("cooldown", 0.0))
	match skill_id:
		"chem_xoay":
			_do_chem_xoay()
		"xung_kich":
			_do_xung_kich()
		"cuong_no":
			_do_cuong_no()
		"dau_an_lua":
			_do_dau_an_lua(def)
		"bay_hon":
			_do_bay_hon(def)
		"hut_sinh_luc":
			_do_hut_sinh_luc(def)
		"cau_lua":
			_do_cau_lua(def)
		"gai_bang":
			_do_gai_bang(def)
		"set_lan":
			_do_set_lan(def)
		"trieu_hoi_bong":
			_do_trieu_hoi_bong(def)
		"cong_phong_an":
			_do_cong_phong_an(def)
		"khien_ma_thuat":
			_do_khien_ma_thuat(def)
		"mua_thien_thach":
			_do_mua_thien_thach(def)
	skill_used.emit(skill_id)
	return true


## Tương thích test/tool gọi trực tiếp theo tên chiêu.
func use_skill_by_id(skill_id: String) -> bool:
	return _use_skill(skill_id)


func _do_chem_xoay() -> void:
	var dmg: int = int(round(float(effective_damage(0)) * SKILL_CHEM_XOAY_MULT))
	var hits := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D and e.has_method("take_damage"):
			if global_position.distance_to(e.global_position) <= SKILL_CHEM_XOAY_RADIUS:
				e.take_damage(dmg, global_position)
				hits += 1
	_chem_xoay_fx = 0.25
	queue_redraw()
	print("[Player] Chém Xoáy! %d damage quanh thân (trúng %d quái)" % [dmg, hits])


## Khoảng cách từ điểm p tới đoạn thẳng a-b (cho hành lang Xung Kích).
func _dist_point_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var len2: float = ab.length_squared()
	if len2 <= 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _do_xung_kich() -> void:
	var dmg: int = int(round(float(effective_damage(0)) * SKILL_XUNG_KICH_MULT))
	var start: Vector2 = global_position
	var dir: Vector2 = facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
	# Lướt vật lý: move_and_collide chặn bởi tường; ngoài physics frame
	# (test gọi trực tiếp) thì lùi về dịch thẳng nếu không di chuyển được.
	var before: Vector2 = global_position
	# "Chém xuyên quái": tạm bỏ lớp Enemy (layer 3 = bit 4) khỏi mask khi lướt
	# để không bị xác quái chặn, vẫn bị tường (layer 1) chặn như thường.
	var saved_mask: int = collision_mask
	collision_mask = collision_mask & ~4
	var collision: KinematicCollision2D = move_and_collide(dir * SKILL_XUNG_KICH_DIST)
	collision_mask = saved_mask
	if global_position.distance_to(before) < 1.0 and collision == null:
		global_position = start + dir * SKILL_XUNG_KICH_DIST
	var end: Vector2 = global_position
	_dash_fx_from = start
	_dash_fx_to = end
	_dash_fx = 0.22
	# Quái trên đường lướt (đoạn thẳng start->end, lệch < 48px): ăn đòn +
	# đẩy lùi + choáng 0.6s. enemy_base hiện KHÔNG có apply_knockback/stun
	# (đã đọc enemy_base.gd) nên fallback: gọi method nếu lớp con có,
	# không thì đẩy vị trí + gán velocity trực tiếp.
	var hits := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D and e.has_method("take_damage"):
			if _dist_point_to_segment(e.global_position, start, end) < SKILL_XUNG_KICH_WIDTH:
				e.take_damage(dmg, start)
				hits += 1
				if e.has_method("apply_knockback"):
					e.apply_knockback(dir * 260.0)
				elif e.has_method("apply_stun"):
					e.apply_stun(SKILL_XUNG_KICH_STUN)
				elif e.has_method("stun"):
					e.stun(SKILL_XUNG_KICH_STUN)
				else:
					# Đẩy lùi thủ công (take_damage của base đã đẩy 8px,
					# cộng thêm cho rõ cảm giác) + vận tốc trượt.
					e.global_position += dir * 14.0
					if e is CharacterBody2D:
						(e as CharacterBody2D).velocity = dir * 240.0
					# Choáng: chỉ gán nếu quái có sẵn thuộc tính stun_timer.
					if (e as Object).get("stun_timer") != null:
						(e as Object).set("stun_timer", SKILL_XUNG_KICH_STUN)
	queue_redraw()
	print("[Player] Xung Kích! Lướt %.0fpx, %d damage xuyên (trúng %d quái, choáng %.1fs)" % [
		start.distance_to(end), dmg, hits, SKILL_XUNG_KICH_STUN])


func _do_cuong_no() -> void:
	# GDD gốc có -2 HP/s; BỎ chi tiết này cho cân bằng bản này (ghi chú GDD):
	# buff thuần lợi 10s, không tự trừ máu.
	cuong_no_timer = SKILL_CUONG_NO_DURATION
	queue_redraw()
	print("[Player] Cuồng Nộ! 10s: +25%% tốc đánh, +20%% damage, đòn thường miễn stamina.")


## Mục tiêu Thuật Đen gần nhất còn sống trong range (ưu tiên con gần nhất).
func _find_dark_target(range_px: float) -> Node2D:
	var best: Node2D = null
	var best_dist := range_px
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D and e.has_method("take_damage"):
			if int(e.get("state")) == 3: # State.DEAD của enemy_base
				continue
			var d: float = global_position.distance_to((e as Node2D).global_position)
			if d <= best_dist:
				best = e as Node2D
				best_dist = d
	return best


func _effect_parent() -> Node:
	var p: Node = get_parent()
	return p if p != null else self


func _do_dau_an_lua(def: Dictionary) -> void:
	var dmg: int = int(round(float(effective_damage(0)) * float(def.get("damage_mult", 1.5))))
	var target: Node2D = _find_dark_target(340.0)
	var rune: Node = DARK_RUNE_SCENE.instantiate()
	_effect_parent().add_child(rune)
	last_dark_rune = rune
	if target != null:
		rune.global_position = target.global_position
	else:
		var dir: Vector2 = facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
		rune.global_position = global_position + dir * 96.0
	if rune.has_method("setup"):
		rune.call("setup", dmg, global_position, target, float(def.get("delay", 1.2)), float(def.get("radius", 96.0)))
	print("[Player] Dấu Ấn Lửa! Gắn ấn %d damage, nổ sau %.1fs (mục tiêu: %s)" % [
		dmg, float(def.get("delay", 1.2)), str(target.get("display_name")) if target != null else "mặt đất phía trước"])


func _do_bay_hon(def: Dictionary) -> void:
	var trap: Node = SOUL_TRAP_SCENE.instantiate()
	_effect_parent().add_child(trap)
	last_soul_trap = trap
	var dir: Vector2 = facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
	trap.global_position = global_position + dir * 72.0
	if trap.has_method("setup_from_def"):
		trap.call("setup_from_def", def)
	print("[Player] Bẫy Hồn! Đặt bẫy tại %s — quái vào vùng sẽ chậm 50%%/3s + choáng 1s" % str(trap.global_position))


func _do_hut_sinh_luc(def: Dictionary) -> void:
	var target: Node2D = _find_dark_target(float(def.get("range", 280.0)))
	last_lifesteal_amount = 0
	if target == null:
		return
	var dmg: int = int(round(float(effective_damage(0)) * float(def.get("damage_mult", 1.2))))
	target.take_damage(dmg, global_position)
	last_lifesteal_amount = int(round(float(dmg) * float(def.get("lifesteal_ratio", 0.4))))
	if last_lifesteal_amount > 0:
		heal(last_lifesteal_amount)
	print("[Player] Hút Sinh Lực! %d damage lên %s, hồi %d HP (%.0f%% sát thương)" % [
		dmg, str(target.get("display_name")), last_lifesteal_amount, float(def.get("lifesteal_ratio", 0.4)) * 100.0])


func _do_cau_lua(def: Dictionary) -> void:
	var dmg: int = int(round(float(effective_damage(0)) * float(def.get("damage_mult", 1.6))))
	var dir: Vector2 = facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
	var ball: Node = FIREBALL_SCENE.instantiate()
	_effect_parent().add_child(ball)
	last_fireball = ball
	if ball is Node2D:
		(ball as Node2D).global_position = global_position + dir * 40.0
	if ball.has_method("launch"):
		ball.call("launch", dir, dmg, global_position, float(def.get("projectile_speed", 520.0)),
			float(def.get("radius", 110.0)), float(def.get("range", 560.0)))
	print("[Player] Cầu Lửa! Bắn đạn lửa %d damage, nổ bán kính %.0fpx" % [dmg, float(def.get("radius", 110.0))])


func _do_gai_bang(def: Dictionary) -> void:
	var dmg: int = int(round(float(effective_damage(0)) * float(def.get("damage_mult", 1.1))))
	var target: Node2D = _find_dark_target(float(def.get("range", 340.0)))
	var center: Vector2
	if target != null:
		center = target.global_position
	else:
		var dir: Vector2 = facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
		center = global_position + dir * 110.0
	var spikes: Node = ICE_SPIKES_SCENE.instantiate()
	_effect_parent().add_child(spikes)
	last_ice_spikes = spikes
	if spikes is Node2D:
		(spikes as Node2D).global_position = center
	if spikes.has_method("setup"):
		spikes.call("setup", dmg, global_position, def)
	print("[Player] Gai Băng! %d damage tại %s, bán kính %.0fpx (chậm + choáng)" % [
		dmg, str(center), float(def.get("radius", 120.0))])


func _do_set_lan(def: Dictionary) -> void:
	last_chain_targets = []
	last_chain_total_damage = 0
	_chain_fx_points = PackedVector2Array()
	_chain_fx_points.append(global_position)
	var chain_range: float = float(def.get("chain_range", 220.0))
	var max_targets: int = int(def.get("chain_count", 4))
	var falloff: float = float(def.get("chain_falloff", 0.85))
	var mult: float = float(def.get("damage_mult", 1.0))
	var target: Node2D = _find_dark_target(float(def.get("range", 340.0)))
	var prev_pos: Vector2 = global_position
	var jump: int = 0
	while target != null and jump < max_targets:
		var target_pos: Vector2 = target.global_position
		var dmg: int = int(round(float(effective_damage(0)) * mult * pow(falloff, float(jump))))
		target.take_damage(dmg, prev_pos)
		last_chain_targets.append(target)
		last_chain_total_damage += dmg
		_chain_fx_points.append(target_pos)
		prev_pos = target_pos
		jump += 1
		if jump >= max_targets:
			break
		var next_target: Node2D = null
		var best_dist := chain_range
		for e in get_tree().get_nodes_in_group("enemy"):
			if e is Node2D and e.has_method("take_damage"):
				if last_chain_targets.has(e):
					continue
				if int(e.get("state")) == 3: # State.DEAD của enemy_base
					continue
				var d: float = prev_pos.distance_to((e as Node2D).global_position)
				if d <= best_dist:
					next_target = e as Node2D
					best_dist = d
		target = next_target
	if last_chain_targets.size() > 0:
		_chain_fx = 0.25
		queue_redraw()
	print("[Player] Sét Lan! Nhảy %d mục tiêu, tổng %d damage" % [last_chain_targets.size(), last_chain_total_damage])


## Điểm đáp của Cổng Phong Ấn: vị trí xa nhất trong dải
## [min_distance, distance] theo hướng mặt mà hình va chạm của player
## KHÔNG chồng vật cản World (layer 1). Nhờ kiểm tra tại điểm đáp thay vì
## quét đường đi, cổng XUYÊN được tường mỏng/vật cản trên đường — đúng
## chất "cổng phong ấn". Trả null nếu mọi khoảng đều bị chặn kín.
func _seal_gate_destination(def: Dictionary) -> Variant:
	var max_dist: float = float(def.get("distance", 220.0))
	var min_dist: float = float(def.get("min_distance", 60.0))
	var dir: Vector2 = facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
	if hitbox_shape == null or hitbox_shape.shape == null:
		return null
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hitbox_shape.shape
	query.collision_mask = 1 # chỉ World (layer 1) mới chặn điểm đáp
	query.exclude = [get_rid()]
	var d := max_dist
	while d >= min_dist:
		var candidate := global_position + dir * d
		query.transform = Transform2D(0.0, candidate)
		if space.intersect_shape(query, 1).is_empty():
			return candidate
		d -= 20.0
	return null


func _do_cong_phong_an(def: Dictionary) -> void:
	var dest: Variant = _seal_gate_destination(def)
	if dest == null:
		return
	last_seal_gate_from = global_position
	last_seal_gate_to = dest
	global_position = dest
	_dash_fx_from = last_seal_gate_from
	_dash_fx_to = last_seal_gate_to
	_dash_fx = 0.22
	queue_redraw()
	print("[Player] Cổng Phong Ấn! Dịch chuyển từ %s -> %s (%.0fpx, xuyên vật cản mỏng)" % [
		str(last_seal_gate_from), str(last_seal_gate_to), last_seal_gate_from.distance_to(last_seal_gate_to)])


func _do_trieu_hoi_bong(def: Dictionary) -> void:
	# Đang có bóng cũ thì cho tan để triệu hồi bóng mới đầy thời lượng.
	if last_shadow_ally != null and is_instance_valid(last_shadow_ally):
		if last_shadow_ally.has_method("dismiss"):
			last_shadow_ally.call("dismiss")
	var dmg: int = int(round(float(effective_damage(0)) * float(def.get("damage_mult", 0.8))))
	var ally: Node = SHADOW_ALLY_SCENE.instantiate()
	_effect_parent().add_child(ally)
	last_shadow_ally = ally
	if ally is Node2D:
		(ally as Node2D).global_position = global_position + Vector2(-44, -34)
	if ally.has_method("setup"):
		ally.call("setup", dmg, global_position, float(def.get("duration", 20.0)),
			float(def.get("tick_interval", 0.9)), float(def.get("range", 210.0)))
	print("[Player] Triệu Hồi Bóng! Bóng đồng minh %d damage/đòn trong %.0fs" % [dmg, float(def.get("duration", 20.0))])


func _do_khien_ma_thuat(def: Dictionary) -> void:
	var lvl: int = GameState.level if has_node("/root/GameState") else 1
	magic_shield_hp = int(def.get("shield_base", 40)) + lvl * int(def.get("shield_per_level", 4))
	magic_shield_timer = float(def.get("duration", 8.0))
	queue_redraw()
	print("[Player] Khiên Ma Thuật! Khiên %d HP trong %.0fs" % [magic_shield_hp, magic_shield_timer])


func _do_mua_thien_thach(def: Dictionary) -> void:
	var dmg: int = int(round(float(effective_damage(0)) * float(def.get("damage_mult", 0.9))))
	var target: Node2D = _find_dark_target(float(def.get("range", 420.0)))
	var center: Vector2
	if target != null:
		center = target.global_position
	else:
		var dir: Vector2 = facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
		center = global_position + dir * 170.0
	var shower: Node = METEOR_SHOWER_SCENE.instantiate()
	_effect_parent().add_child(shower)
	last_meteor_shower = shower
	if shower is Node2D:
		(shower as Node2D).global_position = center
	if shower.has_method("setup"):
		shower.call("setup", dmg, global_position, def)
	print("[Player] Mưa Thiên Thạch! %d đợt thiên thạch (%d damage/viên) tại %s" % [
		int(def.get("waves", 5)), dmg, str(center)])


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or hp <= 0:
		return
	var remaining: int = amount
	# Khiên Ma Thuật hấp thụ damage TRƯỚC mọi giảm trừ khác.
	if magic_shield_hp > 0 and magic_shield_timer > 0.0:
		var absorbed: int = mini(magic_shield_hp, remaining)
		magic_shield_hp -= absorbed
		remaining -= absorbed
		print("[Player] Khiên Ma Thuật hấp thụ %d damage (khiên còn %d HP)" % [absorbed, magic_shield_hp])
		if magic_shield_hp <= 0:
			magic_shield_timer = 0.0
		queue_redraw()
	if remaining <= 0:
		_hurt_flash_timer = 0.12
		return
	# DEF trang bị giảm damage nhận vào; Da Sắt (bị động) giảm thêm 15%
	# trên phần còn lại; tối thiểu vẫn mất 1 HP.
	var effective: int = remaining
	if has_node("/root/GameState"):
		effective = remaining - GameState.defense_bonus
		if GameState.is_skill_unlocked("da_sat"):
			var red: float = float(GameState.SKILL_DEFS["da_sat"].get("damage_reduction", 0.15))
			effective = int(round(float(effective) * (1.0 - red)))
		effective = maxi(1, effective)
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
	# Chém Xoáy: vòng quét lan ra trong 0.25s
	if _chem_xoay_fx > 0.0:
		var t: float = 1.0 - clampf(_chem_xoay_fx / 0.25, 0.0, 1.0)
		var r: float = lerpf(24.0, SKILL_CHEM_XOAY_RADIUS, t)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 0.9, 0.4, 1.0 - t * 0.6), 4.0)
		draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 40, Color(1, 1, 1, 0.5 * (1.0 - t)), 2.0)
	# Xung Kích: vệt dài dọc đường lướt (toạ độ local)
	if _dash_fx > 0.0:
		var a: float = clampf(_dash_fx / 0.22, 0.0, 1.0)
		draw_line(_dash_fx_from - global_position, _dash_fx_to - global_position,
			Color(0.6, 0.9, 1.0, a), 10.0)
		draw_line(_dash_fx_from - global_position, _dash_fx_to - global_position,
			Color(1, 1, 1, a * 0.8), 3.0)
	# Sét Lan: tia sét polyline vàng-xanh nối player -> từng mục tiêu đã nhảy
	if _chain_fx > 0.0 and _chain_fx_points.size() >= 2:
		var a: float = clampf(_chain_fx / 0.25, 0.0, 1.0)
		var pts_local := PackedVector2Array()
		for p in _chain_fx_points:
			pts_local.append(p - global_position)
		draw_polyline(pts_local, Color(0.4, 0.9, 1.0, a * 0.7), 6.0)
		draw_polyline(pts_local, Color(1.0, 0.95, 0.35, a), 2.5)
	# Cuồng Nộ: vòng lửa đỏ nhấp nháy quanh thân suốt thời gian buff
	if cuong_no_timer > 0.0:
		var pulse: float = 30.0 + sin(_fx_time * 6.0) * 4.0
		draw_arc(Vector2(0, -6), pulse, 0.0, TAU, 40, Color(1.0, 0.3, 0.15, 0.85), 3.0)
		draw_arc(Vector2(0, -6), pulse * 0.72, 0.0, TAU, 32, Color(1.0, 0.6, 0.2, 0.55), 2.0)
	# Khiên Ma Thuật: vòng khiên xanh dương bao quanh thân khi khiên còn HP
	if magic_shield_hp > 0 and magic_shield_timer > 0.0:
		var spulse: float = 34.0 + sin(_fx_time * 5.0) * 3.0
		draw_arc(Vector2(0, -8), spulse, 0.0, TAU, 44, Color(0.35, 0.75, 1.0, 0.85), 3.0)
		draw_arc(Vector2(0, -8), spulse * 0.8, 0.0, TAU, 36, Color(0.6, 0.9, 1.0, 0.45), 2.0)
		draw_circle(Vector2(0, -8), spulse * 0.98, Color(0.3, 0.6, 1.0, 0.07))
