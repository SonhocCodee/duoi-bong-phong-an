extends "res://enemies/enemy_base.gd"
## Boss The Rat King — boss vùng Đông (hang chuột, Vertical Slice).
## Kế thừa enemy_base: melee như base, attack nhanh hơn (cooldown 0.8).
## 2 phase:
##  - Phase 1 (>50% HP): melee bình thường.
##  - Phase 2 (<=50% HP): tốc độ +20%, mắt đỏ (sprite_modulate đỏ mạnh),
##    mỗi summon_interval (6s) gọi 2 chuột con (rat.tscn), tối đa max_summons lần.
## Boss HP bar: gọi GameState.set_boss_display("The Rat King", hp, max_hp) ở
## _ready và sau mỗi lần take_damage; chết -> GameState.clear_boss_display().
## LƯU Ý HỢP ĐỒNG: GameState hiện CHƯA có set_boss_display/clear_boss_display/
## boss_name (đã kiểm tra toàn project) và agent quái bị cấm sửa autoload,
## nên mọi lời gọi đều phòng thủ bằng has_method — khi GameState được bổ sung
## API (agent HUD/GameState) boss sẽ tự nối mà không cần sửa file này.
## boss_display_active phản ánh trạng thái hiển thị phía boss để test kiểm tra.

const RAT_SCENE: PackedScene = preload("res://enemies/rat.tscn")

@export var summon_interval: float = 6.0
@export var max_summons: int = 3
@export var minions_per_summon: int = 2

var phase: int = 1
var summons_done: int = 0
var boss_display_active: bool = false
var _summon_timer: float = 6.0
var _phase2_speed_mult: float = 1.2


func _ready() -> void:
	super._ready()
	attack_cooldown_time = 0.8 # phase 1 đã đánh nhanh hơn quái thường
	_update_boss_display()


func _move_speed() -> float:
	return speed * _phase2_speed_mult if phase >= 2 else speed


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD or phase < 2:
		return
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = summon_interval
		summon_minions()


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, from_position)
	if state == State.DEAD:
		return # _on_death() đã clear boss display
	_check_phase()
	_update_boss_display()


func _check_phase() -> void:
	if phase == 1 and hp <= max_hp / 2:
		phase = 2
		_summon_timer = summon_interval
		sprite_modulate = Color(1.0, 0.45, 0.45, 1.0) # mắt đỏ / tint đỏ mạnh
		_apply_modulate()
		print("[The Rat King] PHASE 2! HP %d/%d — tăng tốc +20%%, bắt đầu gọi đàn" % [hp, max_hp])


## Gọi đàn chuột con. Phòng thủ: nếu không có current_scene (vd test lạ)
## thì bỏ qua lần gọi này thay vì crash.
func summon_minions() -> void:
	if state == State.DEAD or summons_done >= max_summons:
		return
	if get_tree() == null or get_tree().current_scene == null:
		print("[The Rat King] Bỏ qua gọi đàn: current_scene null")
		return
	summons_done += 1
	var parent: Node = get_tree().current_scene
	var offsets: Array[Vector2] = [Vector2(44, 14), Vector2(-44, 14), Vector2(0, 52)]
	for i in minions_per_summon:
		var minion: Node2D = RAT_SCENE.instantiate()
		parent.add_child(minion)
		minion.global_position = global_position + offsets[i % offsets.size()]
	print("[The Rat King] Gọi đàn lần %d/%d: +%d chuột con" % [summons_done, max_summons, minions_per_summon])


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
	print("[The Rat King] Bị hạ! Boss display đã clear.")
