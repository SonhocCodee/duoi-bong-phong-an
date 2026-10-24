extends "res://enemies/soldier.gd"
## Boss đấu trường Solmaris — Kassia Vane, Chỉ Huy Lính Đánh Thuê
## (TÊN ĐỀ XUẤT, chờ user duyệt).
## Kế thừa soldier.gd: khiên phía trước chỉ nhận 40% damage.
## Pattern riêng:
## - Phase 1: mỗi 3.2s bắn loạt 3 viên Đạn Cát toả 12 độ.
## - Mốc 66% và 33% HP: gọi 2 lính đánh thuê mỗi đợt, tối đa 2 đợt.
## - Phase 2 (<=50%): loạt 5 viên, cooldown 2.0s, tốc độ x1.25, tint đỏ sẫm.
## Chết chỉ clear boss display; quest tay_05 quyết định flag cốt truyện.

const MERCENARY_SCENE: PackedScene = preload("res://enemies/mercenary.tscn")
const SAND_BOLT_SCENE: PackedScene = preload("res://enemies/sand_bolt.tscn")

@export var bolt_damage: int = 24
@export var bolt_cooldown_p1: float = 3.2
@export var bolt_cooldown_p2: float = 2.0
@export var bolt_range: float = 430.0
@export var max_summon_waves: int = 2
@export var mercenaries_per_wave: int = 2

var phase: int = 1
var boss_display_active: bool = false
var bolt_count: int = 0
var bursts_fired: int = 0
var summons_done: int = 0
var summon_waves_done: int = 0

var _bolt_timer: float = 3.2
var _summoned_at_66: bool = false
var _summoned_at_33: bool = false
var _tint_phase1: Color = Color(0.72, 0.34, 0.24, 1)
var _tint_phase2: Color = Color(0.48, 0.16, 0.12, 1)


func _ready() -> void:
	super._ready()
	attack_cooldown_time = 1.05
	_bolt_timer = bolt_cooldown_p1
	_update_boss_display()


func _move_speed() -> float:
	var base_speed := speed * (1.25 if phase >= 2 else 1.0)
	return base_speed * (slow_factor if slow_timer > 0.0 else 1.0)


func _current_bolt_cooldown() -> float:
	return bolt_cooldown_p2 if phase >= 2 else bolt_cooldown_p1


func _current_burst_size() -> int:
	return 5 if phase >= 2 else 3


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD or is_stunned():
		return
	if state != State.CHASE and state != State.ATTACK:
		return
	var p := _find_player()
	if p == null or global_position.distance_to(p.global_position) > bolt_range:
		return
	_bolt_timer -= delta
	if _bolt_timer <= 0.0:
		_bolt_timer = _current_bolt_cooldown()
		shoot_sand_bolt_burst()


func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


func shoot_sand_bolt_burst(burst_size: int = -1) -> void:
	if state == State.DEAD:
		return
	var n: int = burst_size if burst_size > 0 else _current_burst_size()
	var base_dir := _facing if _facing != Vector2.ZERO else Vector2.DOWN
	var p := _find_player()
	if p != null:
		var to_player: Vector2 = p.global_position - global_position
		if to_player.length() > 0.01:
			base_dir = to_player.normalized()
	var parent: Node = get_parent()
	if parent == null and get_tree() != null:
		parent = get_tree().current_scene
	if parent == null:
		return
	var spread_step: float = deg_to_rad(12.0)
	bursts_fired += 1
	for i in n:
		var offset: float = (float(i) - float(n - 1) * 0.5) * spread_step
		var dir := base_dir.rotated(offset)
		var bolt: Node2D = SAND_BOLT_SCENE.instantiate()
		parent.add_child(bolt)
		bolt.global_position = global_position + dir * 30.0
		if bolt.has_method("launch"):
			bolt.launch(dir, bolt_damage)
		bolt_count += 1
	print("[%s] ĐẠN CÁT LOẠT %d viên! (phase %d, %d damage/viên)" % [display_name, n, phase, bolt_damage])


func summon_mercenaries() -> int:
	if state == State.DEAD or summon_waves_done >= max_summon_waves:
		return 0
	var parent: Node = get_parent()
	if parent == null and get_tree() != null:
		parent = get_tree().current_scene
	if parent == null:
		return 0
	summon_waves_done += 1
	var offsets: Array[Vector2] = [Vector2(70, 28), Vector2(-70, 28), Vector2(54, -44), Vector2(-54, -44)]
	var spawned: int = 0
	for i in mercenaries_per_wave:
		var minion: Node2D = MERCENARY_SCENE.instantiate()
		parent.add_child(minion)
		minion.global_position = global_position + offsets[(summon_waves_done - 1) * mercenaries_per_wave + i]
		summons_done += 1
		spawned += 1
	print("[%s] GỌI LÍNH! %d lính đánh thuê nhảy vào đấu trường (đợt %d/%d)" % [display_name, spawned, summon_waves_done, max_summon_waves])
	return spawned


func _check_summons() -> void:
	if not _summoned_at_66 and hp <= int(max_hp * 0.66):
		_summoned_at_66 = true
		summon_mercenaries()
	if not _summoned_at_33 and hp <= int(max_hp * 0.33):
		_summoned_at_33 = true
		summon_mercenaries()


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, from_position)
	if state == State.DEAD:
		return
	_check_phase()
	_check_summons()
	_update_boss_display()


func _check_phase() -> void:
	if phase == 1 and hp <= max_hp / 2:
		phase = 2
		_bolt_timer = minf(_bolt_timer, bolt_cooldown_p2)
		sprite_modulate = _tint_phase2
		_apply_modulate()
		print("[%s] PHASE 2! Kassia Vane xé áo choàng hội đồng: loạt 5 viên Đạn Cát, tốc độ x1.25." % display_name)


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
	print("[%s] Bị hạ! Huyền thoại 'vua bất tử' của hội đồng lính đánh thuê sụp đổ trước đấu trường." % display_name)
