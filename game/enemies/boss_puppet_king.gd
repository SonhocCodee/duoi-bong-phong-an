extends "res://enemies/enemy_base.gd"
## BOSS CUỐI — Vua Trên Đỉnh Sigilspire, KẺ KÉO DÂY RỐI.
## Kẻ đã điều khiển cả 4 vua bù nhìn qua phong ấn. Hắn không đơn thuần
## là ác: hắn muốn phá ấn có kiểm soát để cứu vương quốc khỏi cái giá
## của ấn — và để giải thoát Seraphine, vật phong ấn sống, khỏi vai neo
## (xem thoại NPC vua ở sigilspire_summit + world doc mục 3.4). Đánh
## bại hắn mới mở được Bệ Phong Ấn để người chơi tự quyết kết cục.
## 3 PHASE:
## - Phase 1 (>66% HP): loạt 3 viên Đạn Chỉ Ấn mỗi 3.2s.
## - Phase 2 (<=66%): loạt 5 viên xen kẽ Chỉ Ấn/Đạn Băng mỗi 2.4s,
##   tốc độ x1.15; vào phase gọi 2 Lính Gác Phong Ấn.
## - Phase 3 (<=33%) "ẤN NỨT": loạt 7 viên mỗi 1.9s, tốc độ x1.3;
##   mỗi 6.5s niệm Vòng Ấn Vỡ tại vị trí player (báo trước 0.9s,
##   45 damage trong 170px); vào phase gọi 2 Bóng Ấn.

const SEAL_GUARD_SCENE: PackedScene = preload("res://enemies/seal_guard.tscn")
const SEAL_SHADE_SCENE: PackedScene = preload("res://enemies/seal_shade.tscn")
const SHADOW_BOLT_SCENE: PackedScene = preload("res://enemies/shadow_bolt.tscn")
const FROST_BOLT_SCENE: PackedScene = preload("res://enemies/frost_bolt.tscn")
const SEAL_BLAST_SCENE: PackedScene = preload("res://enemies/seal_blast.tscn")

@export var bolt_damage: int = 32
@export var blast_damage: int = 45
@export var blast_radius: float = 170.0
@export var blast_cooldown: float = 6.5
@export var bolt_range: float = 460.0

var phase: int = 1
var boss_display_active: bool = false
var bolt_count: int = 0
var bursts_fired: int = 0
var summons_done: int = 0
var blasts_cast: int = 0

var _bolt_timer: float = 3.2
var _blast_timer: float = 6.5
var _tint_phase1: Color = Color(0.85, 0.7, 0.4, 1)
var _tint_phase2: Color = Color(0.8, 0.55, 0.45, 1)
var _tint_phase3: Color = Color(0.62, 0.35, 0.85, 1)


func _ready() -> void:
	super._ready()
	attack_cooldown_time = 1.15
	_bolt_timer = _current_bolt_cooldown()
	_blast_timer = blast_cooldown
	_update_boss_display()


func _move_speed() -> float:
	var mult := 1.0
	if phase == 2:
		mult = 1.15
	elif phase >= 3:
		mult = 1.3
	return speed * mult * (slow_factor if slow_timer > 0.0 else 1.0)


func _current_bolt_cooldown() -> float:
	if phase >= 3:
		return 1.9
	if phase == 2:
		return 2.4
	return 3.2


func _current_burst_size() -> int:
	if phase >= 3:
		return 7
	if phase == 2:
		return 5
	return 3


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
		shoot_burst()
	# Phase 3: Vòng Ấn Vỡ niệm tại vị trí hiện tại của player
	if phase >= 3:
		_blast_timer -= delta
		if _blast_timer <= 0.0:
			_blast_timer = blast_cooldown
			cast_seal_blast(p.global_position)


func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


func shoot_burst(burst_size: int = -1) -> void:
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
	var spread_step: float = deg_to_rad(11.0)
	bursts_fired += 1
	for i in n:
		var offset: float = (float(i) - float(n - 1) * 0.5) * spread_step
		var dir := base_dir.rotated(offset)
		# Phase 2+: xen kẽ đạn băng giữa loạt chỉ ấn cho khó đoán
		var scene: PackedScene = SHADOW_BOLT_SCENE
		if phase >= 2 and i % 2 == 1:
			scene = FROST_BOLT_SCENE
		var bolt: Node2D = scene.instantiate()
		parent.add_child(bolt)
		bolt.global_position = global_position + dir * 32.0
		if bolt.has_method("launch"):
			bolt.launch(dir, bolt_damage)
		bolt_count += 1
	print("[%s] LOẠT ĐẠN PHASE %d: %d viên! (%d damage/viên)" % [display_name, phase, n, bolt_damage])


## Niệm Vòng Ấn Vỡ tại một điểm (thường là vị trí player lúc bắt đầu).
func cast_seal_blast(at_position: Vector2) -> Node:
	if state == State.DEAD:
		return null
	var parent: Node = get_parent()
	if parent == null and get_tree() != null:
		parent = get_tree().current_scene
	if parent == null:
		return null
	var blast: Node2D = SEAL_BLAST_SCENE.instantiate()
	parent.add_child(blast)
	blast.global_position = at_position
	if blast.has_method("setup"):
		blast.call("setup", blast_damage, 0.9, blast_radius)
	blasts_cast += 1
	print("[%s] VÒNG ẤN VỠ đang niệm tại %s — 0.9s nữa sẽ nổ %d damage!" % [display_name, str(at_position), blast_damage])
	return blast


func summon_minions(kind: String, count: int) -> int:
	if state == State.DEAD:
		return 0
	var parent: Node = get_parent()
	if parent == null and get_tree() != null:
		parent = get_tree().current_scene
	if parent == null:
		return 0
	var scene: PackedScene = SEAL_GUARD_SCENE if kind == "guard" else SEAL_SHADE_SCENE
	var offsets: Array[Vector2] = [Vector2(84, 30), Vector2(-84, 30), Vector2(60, -52), Vector2(-60, -52)]
	var spawned: int = 0
	for i in count:
		var minion: Node2D = scene.instantiate()
		parent.add_child(minion)
		minion.global_position = global_position + offsets[i % offsets.size()]
		summons_done += 1
		spawned += 1
	print("[%s] GỌI %s! %d quân lên đỉnh tháp" % [display_name, "LÍNH GÁC PHONG ẤN" if kind == "guard" else "BÓNG ẤN", spawned])
	return spawned


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, from_position)
	if state == State.DEAD:
		return
	_check_phase()
	_update_boss_display()


func _check_phase() -> void:
	if phase == 1 and hp <= int(max_hp * 0.66):
		phase = 2
		_bolt_timer = minf(_bolt_timer, _current_bolt_cooldown())
		sprite_modulate = _tint_phase2
		_apply_modulate()
		summon_minions("guard", 2)
		print("[%s] PHASE 2! Vua rút dây rối của bốn thành cùng lúc: loạt 5 viên xen băng, gọi lính gác." % display_name)
	if phase == 2 and hp <= int(max_hp * 0.33):
		phase = 3
		_bolt_timer = minf(_bolt_timer, _current_bolt_cooldown())
		_blast_timer = minf(_blast_timer, 2.0)
		sprite_modulate = _tint_phase3
		_apply_modulate()
		summon_minions("shade", 2)
		print("[%s] PHASE 3 — ẤN NỨT! Thứ bị giam mượn thân vua: loạt 7 viên + Vòng Ấn Vỡ." % display_name)


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
	print("[%s] GỤC XUỐNG! Mọi sợi dây rối đứt cùng lúc. Bệ Phong Ấn giữa Đài đã mở — kết cục giờ thuộc về người chơi." % display_name)
