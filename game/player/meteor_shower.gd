extends Node2D
## Mưa Thiên Thạch — vùng thiên thạch tại một điểm: `waves` đợt, mỗi đợt
## tối đa 3 viên rơi vào vùng radius. Viên đầu của mỗi đợt luôn nhắm một
## quái ngẫu nhiên trong vùng (nếu có), các viên còn lại rơi ngẫu nhiên.
## Mỗi điểm rơi có vòng báo trước (telegraph) 0.35s rồi mới nổ
## meteor_radius, gây damage cho quái bên trong.
## Player tạo qua meteor_shower.tscn và gọi setup().
## Test đọc: waves_done / total_damage / hit_count; gọi
## resolve_strikes_now() để ép mọi điểm rơi đang chờ nổ ngay.

var damage: int = 0
var source_position: Vector2 = Vector2.ZERO
var radius: float = 180.0
var meteor_radius: float = 70.0
var waves: int = 5
var wave_interval: float = 0.5
var strikes_per_wave: int = 3
var waves_done: int = 0
var total_damage: int = 0
var hit_count: int = 0
var finished: bool = false

var _wave_timer: float = 0.0
var _pending: Array = [] # {pos: Vector2, timer: float}
var _recent_blasts: Array = [] # {pos: Vector2, ttl: float} để vẽ dư chấn
var _rng := RandomNumberGenerator.new()

const TELEGRAPH_TIME: float = 0.35


func setup(p_damage: int, p_source_position: Vector2, def: Dictionary) -> void:
	damage = p_damage
	source_position = p_source_position
	radius = float(def.get("radius", radius))
	meteor_radius = float(def.get("meteor_radius", meteor_radius))
	waves = int(def.get("waves", waves))
	wave_interval = float(def.get("wave_interval", wave_interval))
	_rng.randomize()
	_wave_timer = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if finished:
		return
	# Đếm ngược các điểm rơi đã lên lịch
	for s in _pending:
		s["timer"] = float(s["timer"]) - delta
	var still: Array = []
	for s in _pending:
		if float(s["timer"]) <= 0.0:
			_impact(s["pos"])
		else:
			still.append(s)
	_pending = still
	for b in _recent_blasts:
		b["ttl"] = float(b["ttl"]) - delta
	_recent_blasts = _recent_blasts.filter(func(b: Dictionary) -> bool: return float(b["ttl"]) > 0.0)
	# Lên lịch đợt mới
	if waves_done < waves:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_wave_timer = wave_interval
			run_wave_now()
	elif _pending.is_empty():
		finished = true
		print("[Mưa Thiên Thạch] Kết thúc: %d đợt, %d lượt trúng, tổng %d damage" % [waves_done, hit_count, total_damage])
		queue_free()
	queue_redraw()


## Tung một đợt thiên thạch ngay (lên lịch các điểm rơi, nổ sau telegraph).
func run_wave_now() -> void:
	if waves_done >= waves:
		return
	waves_done += 1
	var in_area: Array = []
	if is_inside_tree():
		for e in get_tree().get_nodes_in_group("enemy"):
			if e is Node2D and e.has_method("take_damage"):
				if int(e.get("state")) == 3:
					continue
				if global_position.distance_to((e as Node2D).global_position) <= radius:
					in_area.append(e)
	for i in strikes_per_wave:
		var pos: Vector2
		if i == 0 and not in_area.is_empty():
			var target: Node2D = in_area[_rng.randi_range(0, in_area.size() - 1)]
			pos = target.global_position
		else:
			var ang := _rng.randf_range(0.0, TAU)
			var dist := sqrt(_rng.randf()) * radius
			pos = global_position + Vector2(cos(ang), sin(ang)) * dist
		_pending.append({"pos": pos, "timer": TELEGRAPH_TIME})
	print("[Mưa Thiên Thạch] Đợt %d/%d: %d điểm rơi" % [waves_done, waves, strikes_per_wave])


## Ép mọi điểm rơi đang chờ nổ ngay lập tức (test / dọn dẹp).
func resolve_strikes_now() -> void:
	var pending_copy: Array = _pending.duplicate()
	_pending.clear()
	for s in pending_copy:
		_impact(s["pos"])


func _impact(pos: Vector2) -> void:
	if not is_inside_tree():
		return
	# Chụp danh sách trước: take_damage có thể khiến quái chết/queue_free.
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e is Node2D and e.has_method("take_damage"):
			if pos.distance_to((e as Node2D).global_position) <= meteor_radius:
				(e as Node2D).take_damage(damage, source_position)
				hit_count += 1
				total_damage += damage
	_recent_blasts.append({"pos": pos, "ttl": 0.3})
	print("[Mưa Thiên Thạch] Thiên thạch nổ tại %s (%d damage, bán kính %.0fpx)" % [str(pos), damage, meteor_radius])


func _draw() -> void:
	if finished:
		return
	# Vùng ảnh hưởng tổng
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.45, 0.15, 0.35), 2.0)
	# Telegraph: vòng đỏ thu nhỏ dần tại điểm sắp rơi
	for s in _pending:
		var local: Vector2 = s["pos"] - global_position
		var t: float = clampf(float(s["timer"]) / TELEGRAPH_TIME, 0.0, 1.0)
		draw_arc(local, meteor_radius, 0.0, TAU, 36, Color(1.0, 0.3, 0.1, 0.85), 2.5)
		draw_arc(local, meteor_radius * t, 0.0, TAU, 28, Color(1.0, 0.6, 0.2, 0.9), 2.0)
		draw_circle(local, 4.0, Color(1.0, 0.5, 0.15, 0.9))
	# Dư chấn các vụ nổ vừa xong
	for b in _recent_blasts:
		var local: Vector2 = b["pos"] - global_position
		var a: float = clampf(float(b["ttl"]) / 0.3, 0.0, 1.0)
		draw_circle(local, meteor_radius * (1.15 - 0.35 * a), Color(1.0, 0.5, 0.12, 0.3 * a))
		draw_arc(local, meteor_radius * (1.15 - 0.35 * a), 0.0, TAU, 36, Color(1.0, 0.7, 0.25, 0.8 * a), 3.0)
