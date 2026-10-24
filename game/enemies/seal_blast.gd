extends Node2D
## Vòng Ấn Vỡ — đòn AoE báo trước của boss cuối (boss_puppet_king.gd tạo
## ra tại vị trí player lúc bắt đầu niệm): vòng telegraph hiện trong
## `delay` giây, sau đó nổ: player còn đứng trong radius sẽ ăn damage.
## Boss tạo qua seal_blast.tscn và gọi setup(). Test gọi detonate_now().

var damage: int = 45
var radius: float = 170.0
var delay: float = 0.9
var detonated: bool = false
var hit_player: bool = false

var _timer: float = 0.0


func setup(p_damage: int, p_delay: float = 0.9, p_radius: float = 170.0) -> void:
	damage = p_damage
	delay = maxf(0.1, p_delay)
	radius = p_radius
	_timer = delay
	queue_redraw()


func _process(delta: float) -> void:
	if detonated:
		return
	_timer -= delta
	queue_redraw()
	if _timer <= 0.0:
		detonate_now()


func detonate_now() -> void:
	if detonated:
		return
	detonated = true
	hit_player = false
	if is_inside_tree():
		for p in get_tree().get_nodes_in_group("player"):
			if p is Node2D and global_position.distance_to((p as Node2D).global_position) <= radius:
				if p.has_method("take_damage"):
					p.take_damage(damage, global_position)
					hit_player = true
	print("[Vòng Ấn Vỡ] NỔ! %d damage trong bán kính %.0fpx (trúng player: %s)" % [damage, radius, str(hit_player)])
	queue_free()


func _draw() -> void:
	if detonated:
		return
	var t: float = clampf(1.0 - _timer / maxf(0.1, delay), 0.0, 1.0)
	# Vòng ngoài cố định + vòng trong thu hẹp dần báo thời điểm nổ
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(0.75, 0.35, 1.0, 0.9), 3.0)
	draw_arc(Vector2.ZERO, radius * (1.0 - t), 0.0, TAU, 48, Color(1.0, 0.45, 0.9, 0.9), 2.5)
	draw_circle(Vector2.ZERO, radius * t, Color(0.6, 0.2, 0.9, 0.12))
	draw_circle(Vector2.ZERO, 5.0, Color(0.85, 0.55, 1.0, 0.95))
