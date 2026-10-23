extends "res://enemies/enemy_base.gd"
## Boss Mossback, the Moss Golem — boss vùng Đông (Mistlake / Elderwood).
## Kế thừa enemy_base: melee như base (attack_cooldown_time = 1.2 set ở .tscn).
## Đòn đặc biệt — ĐẬP ĐẤT (slam):
##  - Player trong slam_trigger_range (110px) và slam_timer đã sẵn sàng
##    (cooldown 4s, phase 2 còn 2.5s) -> GỒNG 0.5s: đứng yên (_move_speed = 0),
##    sprite sáng dần (modulate lerp tới màu gồng), có print log.
##  - Hết gồng -> ĐẬP: player còn trong slam_hit_range (85px) thì chịu
##    slam_damage (26) qua player.take_damage(damage, boss_pos) — player tự
##    tôn trọng i-frame dodge trong take_damage của nó.
## 2 phase:
##  - Phase 1 (>50% HP): melee + slam cooldown 4s.
##  - Phase 2 (<=50% HP): speed x1.3 (55 -> 71.5), slam cooldown 2.5s,
##    tint đỏ nhẹ, mỗi root_interval (9s) mọc "rễ chắn" hồi 15 HP, tối đa
##    max_roots (3) lần. (Bản gọn của cơ chế rễ chắn: hồi máu trực tiếp thay
##    vì spawn thực thể rễ chắn đường — nâng cấp sau nếu cần.)
## Boss HP bar: _ready + mỗi take_damage gọi
## GameState.set_boss_display("Mossback, the Moss Golem", hp, max_hp) (bọc has_method
## cho an toàn, dù GameState hiện đã có API này).
## Chết: base _die() ĐÃ lo add_xp/add_gold + QuestManager.on_enemy_killed(
## enemy_type) nên _on_death() KHÔNG gọi trùng — chỉ clear boss display +
## GameState.add_seal_key("dong") + set_flag("golem_dead").

@export var slam_damage: int = 26
@export var slam_trigger_range: float = 110.0
@export var slam_hit_range: float = 85.0
@export var slam_windup_time: float = 0.5
@export var slam_cooldown_p1: float = 4.0
@export var slam_cooldown_p2: float = 2.5
@export var root_interval: float = 9.0
@export var root_heal: int = 15
@export var max_roots: int = 3

var phase: int = 1
var boss_display_active: bool = false
var slam_timer: float = 0.0 # <= 0 = slam sẵn sàng (test ép slam bằng cách set về 0)
var slam_count: int = 0
var last_slam_hit: bool = false
var roots_done: int = 0

var _winding_up: bool = false
var _windup_timer: float = 0.0
var _root_timer: float = 9.0
var _phase2_speed_mult: float = 1.3
var _tint_normal: Color = Color(1, 1, 1, 1)
var _tint_phase2: Color = Color(1.0, 0.78, 0.72, 1) # đỏ nhẹ
var _tint_windup: Color = Color(1.6, 1.45, 1.1, 1) # sáng dần khi gồng


func _ready() -> void:
	super._ready()
	attack_cooldown_time = 1.2
	_update_boss_display()


## Đang gồng thì đứng yên; phase 2 chạy nhanh hơn 30%.
func _move_speed() -> float:
	if _winding_up:
		return 0.0
	return speed * _phase2_speed_mult if phase >= 2 else speed


func _current_slam_cooldown() -> float:
	return slam_cooldown_p2 if phase >= 2 else slam_cooldown_p1


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD:
		return
	if slam_timer > 0.0:
		slam_timer -= delta
	if _winding_up:
		_tick_windup(delta)
	else:
		_try_start_slam()
	if phase >= 2:
		_tick_roots(delta)


## Tìm player: ưu tiên _player của base, fallback quét group "player".
func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


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
	print("[%s] GỒNG đòn đập đất... (player cách %.0fpx)" % [display_name, global_position.distance_to(p.global_position)])


func _tick_windup(delta: float) -> void:
	_windup_timer -= delta
	# Sáng dần theo tiến độ gồng: tint hiện tại -> tint gồng
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
	slam_timer = _current_slam_cooldown()
	last_slam_hit = false
	var p := _find_player()
	if p != null and global_position.distance_to(p.global_position) <= slam_hit_range:
		if p.has_method("take_damage"):
			p.take_damage(slam_damage, global_position)
			last_slam_hit = true
			print("[%s] ĐẬP ĐẤT trúng player! %d damage (slam #%d)" % [display_name, slam_damage, slam_count])
	else:
		print("[%s] ĐẬP ĐẤT hụt — player đã thoát khỏi %dpx (slam #%d)" % [display_name, int(slam_hit_range), slam_count])


func _base_tint() -> Color:
	return _tint_phase2 if phase >= 2 else _tint_normal


## "Rễ chắn" bản gọn: hồi HP trực tiếp + log (xem comment đầu file).
func _tick_roots(delta: float) -> void:
	if roots_done >= max_roots:
		return
	_root_timer -= delta
	if _root_timer > 0.0:
		return
	_root_timer = root_interval
	roots_done += 1
	hp = mini(max_hp, hp + root_heal)
	health_changed.emit(hp, max_hp)
	_update_boss_display()
	print("[%s] Rễ cổ thụ trồi lên chắn đỡ — hồi %d HP (lần %d/%d), HP %d/%d" % [display_name, root_heal, roots_done, max_roots, hp, max_hp])


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, from_position)
	if state == State.DEAD:
		return # _on_death() đã clear boss display + trao chìa phong ấn
	_check_phase()
	_update_boss_display()


func _check_phase() -> void:
	if phase == 1 and hp <= max_hp / 2:
		phase = 2
		_root_timer = root_interval
		if not _winding_up:
			sprite_modulate = _tint_phase2
		_apply_modulate()
		print("[%s] PHASE 2! HP %d/%d — speed x1.3 (%.1f), slam cooldown %.1fs, rễ chắn bắt đầu mọc" % [display_name, hp, max_hp, speed * _phase2_speed_mult, slam_cooldown_p2])


func _update_boss_display() -> void:
	boss_display_active = true
	if has_node("/root/GameState") and GameState.has_method("set_boss_display"):
		GameState.set_boss_display(display_name, hp, max_hp)


func _clear_boss_display() -> void:
	boss_display_active = false
	if has_node("/root/GameState") and GameState.has_method("clear_boss_display"):
		GameState.clear_boss_display()


func _on_death() -> void:
	_clear_boss_display()
	# Chìa phong ấn vùng Đông + cờ cốt truyện (base đã lo XP/gold/quest kill)
	if has_node("/root/GameState"):
		if GameState.has_method("add_seal_key"):
			GameState.add_seal_key("dong")
		if GameState.has_method("set_flag"):
			GameState.set_flag("golem_dead")
	print("[%s] Bị hạ! Boss display đã clear, rơi chìa phong ấn vùng Đông." % display_name)
