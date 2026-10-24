extends Area2D
## Bẫy Hồn — đặt trên mặt đất, tự quét group enemy trong radius.
## Quái đầu tiên bước vào: làm chậm 50% trong 3s + choáng 1s rồi bẫy tan.
## Có cả body_entered lẫn quét khoảng cách để headless/test không phụ thuộc
## đúng một đường physics callback.

var radius: float = 56.0
var lifetime: float = 20.0
var slow_factor: float = 0.5
var slow_duration: float = 3.0
var stun_duration: float = 1.0
var triggered: bool = false
var affected_enemy: Node2D = null

var _life: float = 0.0
var _age: float = 0.0


func _ready() -> void:
	_life = lifetime
	body_entered.connect(_on_body_entered)
	queue_redraw()


func setup_from_def(def: Dictionary) -> void:
	radius = float(def.get("radius", radius))
	lifetime = float(def.get("lifetime", lifetime))
	slow_factor = float(def.get("slow_factor", slow_factor))
	slow_duration = float(def.get("slow_duration", slow_duration))
	stun_duration = float(def.get("stun_duration", stun_duration))
	_life = lifetime


func _physics_process(delta: float) -> void:
	if triggered:
		return
	_age += delta
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()
		return
	if not is_inside_tree():
		return
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D and global_position.distance_to((e as Node2D).global_position) <= radius:
			trigger_enemy(e as Node2D)
			return


func _on_body_entered(body: Node2D) -> void:
	if body != null and body.is_in_group("enemy"):
		trigger_enemy(body)


func trigger_enemy(e: Node2D) -> bool:
	if triggered or e == null or not is_instance_valid(e):
		return false
	if e.has_method("apply_slow"):
		e.call("apply_slow", slow_duration, slow_factor)
	if e.has_method("apply_stun"):
		e.call("apply_stun", stun_duration)
	triggered = true
	affected_enemy = e
	print("[Bẫy Hồn] Kích hoạt lên %s: chậm %.0f%% %.1fs + choáng %.1fs" % [
		str(e.get("display_name")), (1.0 - slow_factor) * 100.0, slow_duration, stun_duration])
	visible = false
	set_deferred("monitoring", false)
	queue_free()
	return true


func _draw() -> void:
	if triggered:
		return
	var pulse := 0.8 + 0.2 * sin(_age * 5.0)
	draw_circle(Vector2.ZERO, radius * pulse, Color(0.25, 0.05, 0.4, 0.22))
	draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 44, Color(0.68, 0.35, 1.0, 0.85), 2.5)
	draw_arc(Vector2.ZERO, radius * 0.55, 0.0, TAU, 32, Color(0.35, 0.9, 1.0, 0.7), 2.0)
	for i in 5:
		var a := TAU * float(i) / 5.0 - _age * 0.5
		var p := Vector2(cos(a), sin(a)) * radius * 0.78
		draw_circle(p, 3.0, Color(0.8, 0.55, 1.0, 0.95))
