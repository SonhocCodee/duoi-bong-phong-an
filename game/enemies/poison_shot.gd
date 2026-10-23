extends Area2D
## Đạn độc của Nhện rừng (spider.gd bắn ra).
## Bay thẳng theo hướng đã khoá lúc bắn, tốc độ 260, sống tối đa 1.6s.
## Chạm player (group "player") -> player.take_damage(8) rồi biến mất.
## Kiểm tra trúng bằng cả body_entered (physics) lẫn quét khoảng cách
## mỗi physics frame (dự phòng lệch layer trong test/headless).
## Vẽ: Polygon2D giọt độc xanh lá + vệt mờ (trail) phía sau trong .tscn.

@export var speed: float = 260.0
@export var damage: int = 8
@export var lifetime: float = 1.6
@export var hit_radius: float = 20.0

var direction: Vector2 = Vector2.RIGHT
var _life_timer: float = 0.0
var _spent: bool = false


func _ready() -> void:
	_life_timer = lifetime
	body_entered.connect(_on_body_entered)


## Spider gọi ngay sau khi instance: khoá hướng bay + damage.
func launch(dir: Vector2, dmg: int = 8) -> void:
	if dir != Vector2.ZERO:
		direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if _spent:
		return
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return
	global_position += direction * speed * delta
	# Nhấp nháy nhẹ cho cảm giác giọt độc sống động
	var core: Polygon2D = get_node_or_null("Core") as Polygon2D
	if core != null:
		var s := 1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.03)
		core.scale = Vector2(s, s)
	# Dự phòng: quét player theo khoảng cách
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node2D and global_position.distance_to((p as Node2D).global_position) <= hit_radius:
			_hit_player(p as Node2D)
			return


func _on_body_entered(body: Node2D) -> void:
	if body != null and body.is_in_group("player"):
		_hit_player(body)


func _hit_player(p: Node2D) -> void:
	if _spent:
		return
	_spent = true
	if p.has_method("take_damage"):
		p.take_damage(damage, global_position - direction * 10.0)
		print("[PoisonShot] Trúng player: %d độc damage" % damage)
	queue_free()
