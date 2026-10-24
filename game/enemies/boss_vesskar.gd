extends "res://enemies/enemy_base.gd"
## Vesskar — Rồng Cát, kẻ canh Cổng Phong Ấn Tây bị trói bằng lời thề cổ.
## Pattern riêng:
## - HƠI THỞ CÁT: player trong 300px và lệch hướng mặt <=55 độ -> 30 damage.
## - BÃO CÁT: 8 viên Đạn Cát toả vòng tròn (phase 2: 12 viên).
## - ĐÀO CÁT ÁP SÁT: lặn xuống và trồi lên gần player, lệch tối đa 190px.
## - Phase 2 (<=50% HP): tốc độ x1.25, cooldown pattern ngắn hơn.
## Nếu flag "vesskar_dam_phan" đã set: Vesskar HÒA BÌNH — đứng yên canh cổng,
## không detect/đánh player. Quest lựa chọn mới quyết định flag giải phóng,
## boss không tự set seal key ở đây.

const SAND_BOLT_SCENE: PackedScene = preload("res://enemies/sand_bolt.tscn")

@export var breath_damage: int = 30
@export var breath_range: float = 300.0
@export var breath_half_angle_deg: float = 55.0
@export var breath_cooldown_p1: float = 4.5
@export var breath_cooldown_p2: float = 3.2
@export var storm_damage: int = 22
@export var storm_cooldown_p1: float = 9.0
@export var storm_cooldown_p2: float = 6.5
@export var burrow_cooldown: float = 11.0
@export var burrow_range: float = 190.0

var phase: int = 1
var boss_display_active: bool = false
var peaceful: bool = false
var breath_count: int = 0
var last_breath_hit: bool = false
var storm_count: int = 0
var storm_bolts_fired: int = 0
var burrow_count: int = 0

var _breath_timer: float = 2.0
var _storm_timer: float = 5.0
var _burrow_timer: float = 7.0
var _tint_phase1: Color = Color(1.25, 0.95, 0.42, 1)
var _tint_phase2: Color = Color(1.05, 0.55, 0.22, 1)


func _ready() -> void:
	super._ready()
	attack_cooldown_time = 1.25
	if has_node("/root/GameState") and GameState.get_flag("vesskar_dam_phan"):
		peaceful = true
		wander = false
		state = State.IDLE
		print("[Vesskar] Lời thề cổ đã được trả — Vesskar canh cổng trong hòa bình, không tấn công.")
	else:
		_update_boss_display()


func _move_speed() -> float:
	var base_speed := speed * (1.25 if phase >= 2 else 1.0)
	return base_speed * (slow_factor if slow_timer > 0.0 else 1.0)


func _current_breath_cooldown() -> float:
	return breath_cooldown_p2 if phase >= 2 else breath_cooldown_p1


func _current_storm_cooldown() -> float:
	return storm_cooldown_p2 if phase >= 2 else storm_cooldown_p1


func _current_storm_size() -> int:
	return 12 if phase >= 2 else 8


func _physics_process(delta: float) -> void:
	if peaceful:
		velocity = Vector2.ZERO
		_update_animation()
		_apply_modulate()
		return
	super._physics_process(delta)
	if state == State.DEAD or is_stunned():
		return
	if state != State.CHASE and state != State.ATTACK:
		return
	_breath_timer -= delta
	_storm_timer -= delta
	_burrow_timer -= delta
	if _burrow_timer <= 0.0:
		_burrow_timer = burrow_cooldown
		burrow_strike()
	elif _storm_timer <= 0.0:
		_storm_timer = _current_storm_cooldown()
		summon_sandstorm()
	elif _breath_timer <= 0.0:
		_breath_timer = _current_breath_cooldown()
		sand_breath_attack()


func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


## Hơi thở cát hình nón. Trả true nếu player trúng.
func sand_breath_attack() -> bool:
	if state == State.DEAD or peaceful:
		return false
	breath_count += 1
	last_breath_hit = false
	var p := _find_player()
	if p == null:
		print("[Vesskar] PHÀ HƠI THỞ CÁT vào hư không (không có player).")
		return false
	var to_player: Vector2 = p.global_position - global_position
	var dist := to_player.length()
	if dist > breath_range:
		print("[Vesskar] PHÀ HƠI THỞ CÁT hụt — player ngoài tầm %.0fpx." % breath_range)
		return false
	var facing_dir := _facing if _facing != Vector2.ZERO else Vector2.DOWN
	if dist > 0.01 and rad_to_deg(facing_dir.angle_to(to_player.normalized())) > breath_half_angle_deg:
		print("[Vesskar] PHÀ HƠI THỞ CÁT hụt — player ngoài hình nón hơi thở.")
		return false
	if p.has_method("take_damage"):
		p.take_damage(breath_damage, global_position)
	last_breath_hit = true
	print("[Vesskar] HƠI THỞ CÁT trúng player! %d damage (lần %d)" % [breath_damage, breath_count])
	return true


## Bão cát: bắn Đạn Cát toả đều vòng tròn. Trả số viên đã bắn.
func summon_sandstorm(burst_size: int = -1) -> int:
	if state == State.DEAD or peaceful:
		return 0
	var n: int = burst_size if burst_size > 0 else _current_storm_size()
	var parent: Node = get_parent()
	if parent == null and get_tree() != null:
		parent = get_tree().current_scene
	if parent == null:
		return 0
	storm_count += 1
	for i in n:
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / float(n))
		var bolt: Node2D = SAND_BOLT_SCENE.instantiate()
		parent.add_child(bolt)
		bolt.global_position = global_position + dir * 42.0
		if bolt.has_method("launch"):
			bolt.launch(dir, storm_damage)
		storm_bolts_fired += 1
	print("[Vesskar] BÃO CÁT! %d viên Đạn Cát toả vòng tròn (bão #%d, phase %d)" % [n, storm_count, phase])
	return n


## Đào cát áp sát: dịch tới gần player (không vào đúng vị trí player).
func burrow_strike() -> bool:
	if state == State.DEAD or peaceful:
		return false
	var p := _find_player()
	if p == null:
		return false
	var away: Vector2 = (global_position - p.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.LEFT
	global_position = p.global_position + away * 92.0
	_facing = -away
	burrow_count += 1
	print("[Vesskar] ĐÀO CÁT ÁP SÁT! Trồi lên cách player 92px (lần %d)" % burrow_count)
	return true


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if peaceful:
		print("[Vesskar] Ấn đàm phán bảo vệ lời thề — đòn đánh không phá được thế canh cổng hòa bình.")
		return
	super.take_damage(amount, from_position)
	if state == State.DEAD:
		return
	_check_phase()
	_update_boss_display()


func _check_phase() -> void:
	if phase == 1 and hp <= max_hp / 2:
		phase = 2
		_breath_timer = minf(_breath_timer, breath_cooldown_p2)
		_storm_timer = minf(_storm_timer, storm_cooldown_p2)
		sprite_modulate = _tint_phase2
		_apply_modulate()
		print("[Vesskar] PHASE 2! Cát dưới hang sôi lên — bão 12 viên, hơi thở hồi nhanh hơn, tốc độ x1.25.")


func _update_boss_display() -> void:
	if peaceful:
		return
	boss_display_active = true
	if has_node("/root/GameState") and GameState.has_method("set_boss_display"):
		GameState.set_boss_display(display_name, hp, max_hp)


func _clear_boss_display() -> void:
	boss_display_active = false
	if has_node("/root/GameState") and GameState.has_method("clear_boss_display"):
		GameState.clear_boss_display()


func _on_death() -> void:
	_clear_boss_display()
	print("[Vesskar] Bị hạ! Kẻ canh cổng ngã xuống — bão cát Tây từ nay không còn ai giữ nhịp.")
