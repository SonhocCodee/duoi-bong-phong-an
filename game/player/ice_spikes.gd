extends Node2D
## Gai Băng — vùng băng mọc tại một điểm, áp dụng NGAY khi setup():
## damage + làm chậm + choáng mọi quái trong radius, rồi vẽ gai băng
## thêm ~0.5s và tự vỡ (queue_free). Player tạo qua ice_spikes.tscn.

var damage: int = 0
var source_position: Vector2 = Vector2.ZERO
var radius: float = 120.0
var slow_factor: float = 0.4
var slow_duration: float = 3.0
var stun_duration: float = 0.8
var hit_count: int = 0
var affected: Array = []
var applied: bool = false

var _life: float = 0.5
var _age: float = 0.0


func setup(p_damage: int, p_source_position: Vector2, def: Dictionary) -> void:
	damage = p_damage
	source_position = p_source_position
	radius = float(def.get("radius", radius))
	slow_factor = float(def.get("slow_factor", slow_factor))
	slow_duration = float(def.get("slow_duration", slow_duration))
	stun_duration = float(def.get("stun_duration", stun_duration))
	apply_now()
	queue_redraw()


## Áp damage + slow + stun tức thì cho mọi quái trong radius (chỉ 1 lần).
func apply_now() -> void:
	if applied:
		return
	applied = true
	hit_count = 0
	affected = []
	# Chụp danh sách trước: take_damage có thể khiến quái chết/queue_free.
	var enemies: Array = get_tree().get_nodes_in_group("enemy") if is_inside_tree() else []
	for e in enemies:
		if e is Node2D and e.has_method("take_damage"):
			if global_position.distance_to((e as Node2D).global_position) <= radius:
				(e as Node2D).take_damage(damage, source_position)
				if e.has_method("apply_slow"):
					e.call("apply_slow", slow_duration, slow_factor)
				if e.has_method("apply_stun"):
					e.call("apply_stun", stun_duration)
				hit_count += 1
				affected.append(e)
	print("[Gai Băng] %d damage, bán kính %.0fpx, trúng %d quái (chậm còn %.0f%% %.1fs + choáng %.1fs)" % [
		damage, radius, hit_count, slow_factor * 100.0, slow_duration, stun_duration])


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if applied:
		_life -= delta
		if _life <= 0.0:
			queue_free()


func _draw() -> void:
	var fade: float = clampf(_life / 0.5, 0.0, 1.0) if applied else 1.0
	draw_circle(Vector2.ZERO, radius, Color(0.45, 0.75, 1.0, 0.16 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.55, 0.85, 1.0, 0.75 * fade), 2.5)
	draw_arc(Vector2.ZERO, radius * 0.6, 0.0, TAU, 36, Color(0.75, 0.92, 1.0, 0.5 * fade), 1.5)
	# Gai băng: tam giác nhọn mọc rải trong vùng
	for i in 9:
		var a := TAU * float(i) / 9.0 + 0.35
		var dist := radius * (0.25 + 0.13 * float(i % 3))
		var c := Vector2(cos(a), sin(a)) * dist
		var h := (24.0 + 7.0 * float(i % 3)) * (0.6 + 0.4 * fade)
		var w := 8.0
		var pts := PackedVector2Array([c + Vector2(-w, 6.0), c + Vector2(0.0, -h), c + Vector2(w, 6.0)])
		draw_colored_polygon(pts, Color(0.55, 0.85, 1.0, 0.9 * fade))
		var inner := PackedVector2Array([c + Vector2(-w * 0.45, 4.0), c + Vector2(0.0, -h * 0.7), c + Vector2(w * 0.45, 4.0)])
		draw_colored_polygon(inner, Color(0.85, 0.96, 1.0, 0.9 * fade))
	# Gai giữa tâm to nhất
	var mid := PackedVector2Array([Vector2(-11, 8), Vector2(0, -40.0 * (0.6 + 0.4 * fade)), Vector2(11, 8)])
	draw_colored_polygon(mid, Color(0.6, 0.88, 1.0, 0.95 * fade))
