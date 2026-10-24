extends Node2D
## Dấu Ấn Lửa — ấn bám theo mục tiêu (nếu có) trong delay giây rồi nổ
## diện rộng. Player tạo qua dau_an_lua.tscn và gọi setup().
## Test có thể gọi explode_now() để kiểm damage mà không chờ hết delay.

var damage: int = 0
var delay: float = 1.2
var radius: float = 96.0
var source_position: Vector2 = Vector2.ZERO
var target: Node2D = null
var exploded: bool = false
var hit_count: int = 0

var _timer: float = 0.0
var _age: float = 0.0


func setup(p_damage: int, p_source_position: Vector2, p_target: Node2D = null, p_delay: float = 1.2, p_radius: float = 96.0) -> void:
	damage = p_damage
	source_position = p_source_position
	target = p_target
	delay = maxf(0.05, p_delay)
	radius = p_radius
	_timer = delay
	if target != null and is_instance_valid(target):
		global_position = target.global_position
	queue_redraw()


func _process(delta: float) -> void:
	if exploded:
		return
	_age += delta
	if target != null and is_instance_valid(target):
		global_position = target.global_position
	_timer -= delta
	queue_redraw()
	if _timer <= 0.0:
		explode_now()


func explode_now() -> void:
	if exploded:
		return
	exploded = true
	hit_count = 0
	# Chụp danh sách trước: take_damage có thể khiến quái chết/queue_free.
	var enemies: Array = get_tree().get_nodes_in_group("enemy") if is_inside_tree() else []
	for e in enemies:
		if e is Node2D and e.has_method("take_damage"):
			if global_position.distance_to((e as Node2D).global_position) <= radius:
				(e as Node2D).take_damage(damage, source_position)
				hit_count += 1
	print("[Dấu Ấn Lửa] NỔ! %d damage, bán kính %.0fpx, trúng %d quái" % [damage, radius, hit_count])
	queue_free()


func _draw() -> void:
	if exploded:
		return
	var pulse := 0.75 + 0.25 * sin(_age * 10.0)
	draw_circle(Vector2.ZERO, radius * 0.32 * pulse, Color(0.45, 0.08, 0.55, 0.35))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.35, 0.1, 0.8), 3.0)
	draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 40, Color(0.72, 0.2, 1.0, 0.9), 2.5)
	draw_arc(Vector2.ZERO, radius * 0.3, 0.0, TAU, 28, Color(1.0, 0.72, 0.25, 1.0), 2.0)
	for i in 6:
		var a := TAU * float(i) / 6.0 + _age * 0.7
		var p0 := Vector2(cos(a), sin(a)) * radius * 0.72
		var p1 := Vector2(cos(a), sin(a)) * radius * 0.92
		draw_line(p0, p1, Color(1.0, 0.45, 0.15, 0.9), 2.0)
