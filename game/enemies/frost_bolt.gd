extends Area2D
## Đạn Băng — đạn của Vharok, Kẻ Giữ Nguyền (boss_curse_warden.gd bắn ra).
## Bay thẳng, chạm player thì gây damage truyền qua launch().

@export var speed: float = 300.0
@export var damage: int = 20
@export var lifetime: float = 1.7
@export var hit_radius: float = 20.0

var direction: Vector2 = Vector2.RIGHT
var _life_timer: float = 0.0
var _spent: bool = false


func _ready() -> void:
	_life_timer = lifetime
	body_entered.connect(_on_body_entered)


func launch(dir: Vector2, dmg: int = 20) -> void:
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
	var core: Polygon2D = get_node_or_null("Core") as Polygon2D
	if core != null:
		var s := 1.0 + 0.13 * sin(Time.get_ticks_msec() * 0.03)
		core.scale = Vector2(s, s)
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
		print("[FrostBolt] Đạn Băng trúng player: %d damage" % damage)
	queue_free()
