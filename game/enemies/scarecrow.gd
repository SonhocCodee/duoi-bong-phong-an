extends "res://enemies/enemy_base.gd"
## Bù nhìn ma — quái bẫy đồng ruộng vùng Đông.
## Trạng thái DORMANT (mặc định khi spawn): đứng yên hoàn toàn — không
## wander, không detect player dù player ở sát trong detect_range của base.
## Player vào < wake_range (90px) hoặc bị đánh trúng -> "BẬT DẬY": flash
## sáng, chuyển CHASE bình thường của base từ đó về sau.
## Sprite: player_frames tint rơm (set trong .tscn qua sprite_modulate).

@export var wake_range: float = 90.0

var dormant: bool = true


func _ready() -> void:
	super._ready()
	wander = false


func _physics_process(delta: float) -> void:
	if dormant and state != State.DEAD:
		# Đứng yên như bù nhìn thật: chỉ trừ timer hiệu ứng + giữ idle anim
		if _hurt_flash_timer > 0.0:
			_hurt_flash_timer -= delta
		velocity = Vector2.ZERO
		_apply_modulate()
		var p := _find_player()
		if p != null and global_position.distance_to(p.global_position) < wake_range:
			wake_up()
			# Vừa bật dậy thì chạy tiếp AI base ngay trong frame này
			super._physics_process(delta)
		return
	super._physics_process(delta)


func wake_up() -> void:
	if not dormant:
		return
	dormant = false
	state = State.CHASE
	_hurt_flash_timer = 0.25 # flash sáng lúc bật dậy
	_apply_modulate()
	print("[%s] BẬT DẬY! Bù nhìn ma sống dậy đuổi theo player" % display_name)


## Bị đánh khi đang ngủ cũng làm nó bật dậy (rồi mới nhận damage qua base).
func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if dormant and state != State.DEAD:
		wake_up()
	super.take_damage(amount, from_position)


func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null
