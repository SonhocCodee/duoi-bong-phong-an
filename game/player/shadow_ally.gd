extends Node2D
## Triệu Hồi Bóng — một "bóng" đồng minh bay theo player trong duration
## giây; mỗi tick_interval giây nó lao vào quái gần nhất trong range và
## gây damage, rồi quay về bên player. Player tạo qua shadow_ally.tscn
## và gọi setup(). Hết giờ (hoặc player gọi dismiss()) bóng tan biến.
## Test đọc: damage_per_tick / hits / total_damage / expired.

var damage_per_tick: int = 0
var duration: float = 20.0
var tick_interval: float = 0.9
var strike_range: float = 210.0
var source_position: Vector2 = Vector2.ZERO
var hits: int = 0
var total_damage: int = 0
var expired: bool = false

var _age: float = 0.0
var _tick_timer: float = 0.0
var _orbit_phase: float = 0.0
var _strike_flash: float = 0.0
var _strike_pos: Vector2 = Vector2.ZERO


func setup(p_damage: int, p_source_position: Vector2, p_duration: float = 20.0, p_tick: float = 0.9, p_range: float = 210.0) -> void:
	damage_per_tick = p_damage
	source_position = p_source_position
	duration = maxf(1.0, p_duration)
	tick_interval = maxf(0.2, p_tick)
	strike_range = p_range
	_tick_timer = tick_interval * 0.5 # nhịp đầu đến sớm cho có cảm giác
	queue_redraw()


func dismiss() -> void:
	if expired:
		return
	expired = true
	queue_free()


func _player_pos() -> Vector2:
	var players := get_tree().get_nodes_in_group("player") if is_inside_tree() else []
	if players.size() > 0 and players[0] is Node2D:
		return (players[0] as Node2D).global_position
	return global_position


func _process(delta: float) -> void:
	if expired:
		return
	_age += delta
	_orbit_phase += delta * 2.2
	if _age >= duration:
		print("[Triệu Hồi Bóng] Bóng tan biến sau %.0fs (%d đòn, %d damage)" % [duration, hits, total_damage])
		dismiss()
		return
	# Bay lượn quanh player (lệch trái-trên, nhấp nhô theo quỹ đạo)
	var anchor := _player_pos() + Vector2(cos(_orbit_phase) * 44.0, -34.0 + sin(_orbit_phase * 1.7) * 10.0)
	global_position = global_position.lerp(anchor, clampf(delta * 7.0, 0.0, 1.0))
	if _strike_flash > 0.0:
		_strike_flash -= delta
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		strike_once()
	queue_redraw()


## Một nhịp tấn công: đánh quái gần nhất trong strike_range tính từ
## PLAYER (bóng là tay dài của player). Trả true nếu trúng mục tiêu.
func strike_once() -> bool:
	if expired or not is_inside_tree():
		return false
	var origin := _player_pos()
	var best: Node2D = null
	var best_dist := strike_range
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D and e.has_method("take_damage"):
			if int(e.get("state")) == 3: # State.DEAD của enemy_base
				continue
			var d: float = origin.distance_to((e as Node2D).global_position)
			if d <= best_dist:
				best = e as Node2D
				best_dist = d
	if best == null:
		return false
	best.take_damage(damage_per_tick, origin)
	hits += 1
	total_damage += damage_per_tick
	_strike_pos = best.global_position
	_strike_flash = 0.18
	global_position = best.global_position + Vector2(0, -30)
	print("[Triệu Hồi Bóng] Bóng lao vào %s: %d damage" % [str(best.get("display_name")), damage_per_tick])
	return true


func _draw() -> void:
	if expired:
		return
	var remain: float = clampf(1.0 - _age / maxf(0.1, duration), 0.0, 1.0)
	var fade: float = 0.45 + 0.55 * remain
	# Thân bóng: quầng tím đen + lõi + đôi mắt tím sáng
	draw_circle(Vector2.ZERO, 21.0, Color(0.16, 0.05, 0.28, 0.35 * fade))
	draw_circle(Vector2.ZERO, 15.0, Color(0.1, 0.04, 0.2, 0.88 * fade))
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color(0.62, 0.3, 0.95, 0.8 * fade), 2.0)
	draw_circle(Vector2(-5, -3), 2.4, Color(0.85, 0.6, 1.0, fade))
	draw_circle(Vector2(5, -3), 2.4, Color(0.85, 0.6, 1.0, fade))
	# Đòn đánh vừa tung: vệt chém tím tới vị trí mục tiêu
	if _strike_flash > 0.0:
		var a: float = clampf(_strike_flash / 0.18, 0.0, 1.0)
		draw_line(Vector2.ZERO, _strike_pos - global_position, Color(0.7, 0.4, 1.0, a * 0.8), 4.0)
		draw_arc(_strike_pos - global_position, 16.0, 0.0, TAU, 20, Color(0.8, 0.55, 1.0, a), 2.0)
