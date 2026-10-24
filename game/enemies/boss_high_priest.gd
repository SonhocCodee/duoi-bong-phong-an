extends "res://enemies/enemy_base.gd"
## Boss Đại Tư Tế Morvain — BOSS VÙNG NAM FENMIRE (đầm lầy, Lv 7-12).
## Kế thừa enemy_base: cận chiến yếu như base (damage 12 ở .tscn,
## attack_cooldown_time = 1.2), đòn chính là Chỉ Ấn tầm xa.
## Phase 1 (100% -> 50% HP):
##  - Mỗi bolt_cooldown_p1 (3.0s) bắn LOẠT 3 viên shadow_bolt toả nhẹ
##    (bolt_damage 20/viên) về phía player.
##  - Mốc 66% HP: triệu hồi 2 cultist (cultist.tscn) — 1 đợt.
## Phase 2 (<= 50% HP):
##  - Cooldown đạn rút còn bolt_cooldown_p2 (1.8s), loạt tăng lên 5 viên
##    toả rộng hơn, tốc độ +30% (70 -> 91), tint tím đậm hơn.
##  - Mốc 33% HP: triệu hồi thêm 2 cultist — đợt cuối (tổng tối đa
##    max_summon_waves = 2 đợt / 4 cultist, hữu hạn).
## Boss HP bar: _ready + mỗi take_damage gọi
## GameState.set_boss_display(display_name, hp, max_hp) (bọc has_method
## cho an toàn như boss_golem/boss_vua).
## Chết: base _die() ĐÃ lo add_xp/add_gold + QuestManager.on_enemy_killed(
## enemy_type) nên _on_death() KHÔNG gọi trùng — chỉ clear boss display.
## key_flag để TRỐNG trong .tscn (quest/giải phóng vùng Nam nối sau,
## không tự set seal key / flag cốt truyện ở đây).

const CULTIST_SCENE: PackedScene = preload("res://enemies/cultist.tscn")
const SHADOW_BOLT_SCENE: PackedScene = preload("res://enemies/shadow_bolt.tscn")

@export var bolt_damage: int = 20
@export var bolt_cooldown_p1: float = 3.0
@export var bolt_cooldown_p2: float = 1.8
@export var bolt_range: float = 420.0
@export var max_summon_waves: int = 2
@export var cultists_per_wave: int = 2

var phase: int = 1
var boss_display_active: bool = false
var bolt_count: int = 0 # tổng số VIÊN đạn đã bắn (không phải số loạt)
var bursts_fired: int = 0
var summons_done: int = 0 # tổng số cultist đã triệu hồi
var summon_waves_done: int = 0

var _bolt_timer: float = 3.0
var _summoned_at_66: bool = false
var _summoned_at_33: bool = false
var _phase2_speed_mult: float = 1.3
var _tint_phase1: Color = Color(0.5, 0.35, 0.8, 1) # tím giáo phái
var _tint_phase2: Color = Color(0.32, 0.18, 0.5, 1) # tím đậm phase 2


func _ready() -> void:
	super._ready()
	attack_cooldown_time = 1.2
	_bolt_timer = bolt_cooldown_p1
	_update_boss_display()


## Phase 2 chạy nhanh hơn 30%.
func _move_speed() -> float:
	return speed * _phase2_speed_mult if phase >= 2 else speed


func _current_bolt_cooldown() -> float:
	return bolt_cooldown_p2 if phase >= 2 else bolt_cooldown_p1


## Số viên mỗi loạt: phase 1 = 3, phase 2 = 5.
func _current_burst_size() -> int:
	return 5 if phase >= 2 else 3


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD:
		return
	# Chỉ bắn khi đang combat (đã thấy player) và player trong tầm đạn —
	# đứng ngoài tầm thì chỉ đi tuần/wander như base, không bắn vào hư không.
	if state != State.CHASE and state != State.ATTACK:
		return
	var p := _find_player()
	if p == null:
		return
	if global_position.distance_to(p.global_position) > bolt_range:
		return
	_bolt_timer -= delta
	if _bolt_timer <= 0.0:
		_bolt_timer = _current_bolt_cooldown()
		shoot_bolt_burst()


## Tìm player: ưu tiên _player của base, fallback quét group "player".
func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


# --- Chỉ Ấn loạt -----------------------------------------------------------

## Bắn 1 loạt đạn toả về phía player (không có player thì theo hướng mặt).
## burst_size < 0 = tự theo phase (3 / 5). Test gọi thẳng hàm này.
func shoot_bolt_burst(burst_size: int = -1) -> void:
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
		print("[%s] Bỏ qua loạt Chỉ Ấn: không có node cha/current_scene" % display_name)
		return
	# Toả đều quanh hướng chính: mỗi viên lệch 12 độ so với viên kề.
	var spread_step: float = deg_to_rad(12.0)
	bursts_fired += 1
	for i in n:
		var offset: float = (float(i) - float(n - 1) * 0.5) * spread_step
		var dir := base_dir.rotated(offset)
		var bolt: Node2D = SHADOW_BOLT_SCENE.instantiate()
		parent.add_child(bolt)
		bolt.global_position = global_position + dir * 28.0
		if bolt.has_method("launch"):
			bolt.launch(dir, bolt_damage)
		bolt_count += 1
	print("[%s] CHỈ ẤN LOẠT %d viên! (loạt #%d, %d damage/viên, phase %d)" % [display_name, n, bursts_fired, bolt_damage, phase])


# --- Triệu hồi cultist ở mốc HP ---------------------------------------------

## Triệu hồi 1 đợt cultists_per_wave (2) tín đồ quanh boss.
## Trả số lượng thực tế đã spawn (0 nếu hết đợt / đã chết / không có cha).
func summon_cultists() -> int:
	if state == State.DEAD or summon_waves_done >= max_summon_waves:
		return 0
	var parent: Node = get_parent()
	if parent == null and get_tree() != null:
		parent = get_tree().current_scene
	if parent == null:
		print("[%s] Bỏ qua triệu hồi: không có node cha/current_scene" % display_name)
		return 0
	summon_waves_done += 1
	var offsets: Array[Vector2] = [Vector2(64, 24), Vector2(-64, 24), Vector2(48, -40), Vector2(-48, -40)]
	var spawned: int = 0
	for i in cultists_per_wave:
		var minion: Node2D = CULTIST_SCENE.instantiate()
		parent.add_child(minion)
		minion.global_position = global_position + offsets[(summon_waves_done - 1) * cultists_per_wave + i % offsets.size()]
		summons_done += 1
		spawned += 1
	print("[%s] TRIỆU HỒI! \"Tín đồ đâu, hộ pháp!\" — %d cultist trồi lên từ đầm lầy (đợt %d/%d, tổng %d)" % [display_name, spawned, summon_waves_done, max_summon_waves, summons_done])
	return spawned


func _check_summons() -> void:
	# Hai mốc độc lập: một đòn lớn nhảy qua cả hai mốc thì gọi cả hai đợt.
	if not _summoned_at_66 and hp <= int(max_hp * 0.66):
		_summoned_at_66 = true
		summon_cultists()
	if not _summoned_at_33 and hp <= int(max_hp * 0.33):
		_summoned_at_33 = true
		summon_cultists()


# --- Phase / boss display / chết -------------------------------------------

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, from_position)
	if state == State.DEAD:
		return # _on_death() đã clear boss display
	_check_phase()
	_check_summons()
	_update_boss_display()


func _check_phase() -> void:
	if phase == 1 and hp <= max_hp / 2:
		phase = 2
		_bolt_timer = minf(_bolt_timer, bolt_cooldown_p2)
		sprite_modulate = _tint_phase2
		_apply_modulate()
		print("[%s] PHASE 2! Nước đầm sôi lên, áo choàng tư tế nhuộm tím đậm — loạt Chỉ Ấn 5 viên mỗi %.1fs, tốc độ x1.3 (%.0f). (HP %d/%d)" % [display_name, bolt_cooldown_p2, speed * _phase2_speed_mult, hp, max_hp])


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
	# key_flag trống + KHÔNG set seal key/flag giải phóng ở đây:
	# tuyến quest vùng Nam sẽ nối sau (như vua_ha/dong_giai_phong của Đông
	# do QuestManager quyết định, boss không tự quyết).
	print("[%s] Bị hạ! Đại Tư Tế Morvain chìm xuống đầm lầy Fenmire, những tiếng tụng niệm tắt dần trong sương." % display_name)
