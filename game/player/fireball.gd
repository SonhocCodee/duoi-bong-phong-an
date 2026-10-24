extends Node2D
## Cầu Lửa — đạn lửa bay thẳng theo direction, chạm quái (<=26px) hoặc bay
## hết max_range thì nổ diện rộng. Player tạo qua fireball.tscn và gọi
## launch(). Test có thể gọi explode_now() để kiểm damage mà không chờ bay.

var damage: int = 0
var direction: Vector2 = Vector2.RIGHT
var speed: float = 520.0
var radius: float = 110.0
var max_range: float = 560.0
var source_position: Vector2 = Vector2.ZERO
var traveled: float = 0.0
var exploded: bool = false
var hit_count: int = 0

var _age: float = 0.0


func launch(p_dir: Vector2, p_damage: int, p_source_position: Vector2, p_speed: float = 520.0, p_radius: float = 110.0, p_max_range: float = 560.0) -> void:
	direction = p_dir.normalized() if p_dir != Vector2.ZERO else Vector2.RIGHT
	damage = p_damage
	source_position = p_source_position
	speed = p_speed
	radius = p_radius
	max_range = p_max_range
	traveled = 0.0
	queue_redraw()


## Tên gọi khác cùng chữ ký (player/test nào quen setup() cũng dùng được).
func setup(p_dir: Vector2, p_damage: int, p_source_position: Vector2, p_speed: float = 520.0, p_radius: float = 110.0, p_max_range: float = 560.0) -> void:
	launch(p_dir, p_damage, p_source_position, p_speed, p_radius, p_max_range)


func _process(delta: float) -> void:
	if exploded:
		return
	_age += delta
	global_position += direction * speed * delta
	traveled += speed * delta
	queue_redraw()
	if not is_inside_tree():
		return
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D and e.has_method("take_damage"):
			if global_position.distance_to((e as Node2D).global_position) <= 26.0:
				explode_now()
				return
	if traveled >= max_range:
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
	print("[Cầu Lửa] NỔ! %d damage, bán kính %.0fpx, trúng %d quái" % [damage, radius, hit_count])
	queue_free()


func _draw() -> void:
	if exploded:
		return
	var flicker := 1.0 + 0.15 * sin(_age * 18.0)
	draw_circle(Vector2.ZERO, 17.0 * flicker, Color(1.0, 0.4, 0.08, 0.55))
	draw_circle(Vector2.ZERO, 12.0 * flicker, Color(1.0, 0.55, 0.12, 0.95))
	draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.82, 0.3, 1.0))
	draw_circle(Vector2.ZERO, 3.5, Color(1.0, 0.98, 0.85, 1.0))
	# Đuôi lửa phía sau hướng bay
	var tail := -direction * 16.0
	draw_line(tail, Vector2.ZERO, Color(1.0, 0.5, 0.15, 0.7), 6.0)
	draw_line(tail * 0.6, Vector2.ZERO, Color(1.0, 0.75, 0.3, 0.8), 3.0)
