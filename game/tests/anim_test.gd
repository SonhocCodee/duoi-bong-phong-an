extends Node
## Test tự động cho sprite/animation (chạy headless):
##   godot --headless --path game res://tests/anim_test.tscn --quit-after 600
## Kiểm tra: player idle/walk/attack đổi animation đúng, goblin chase như cũ,
## goblin chết chơi animation death và chỉ biến mất SAU một khoảng delay.
## Thoát với exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _frame := 0
var _world: Node = null
var _player: Node = null
var _goblin: Node = null
var _failures: Array[String] = []
var _attack_seen := false
var _chase_start_dist := 0.0
var _kill_frame := -1


func _ready() -> void:
	var packed: PackedScene = load("res://maps/world_test.tscn")
	_world = packed.instantiate()
	add_child(_world)
	_player = _world.get_node("Player")
	_goblin = _world.get_node("Goblin1")
	print("[ANIMTEST] Bắt đầu test animation.")


func _check(cond: bool, label: String) -> void:
	if cond:
		print("[ANIMTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[ANIMTEST] FAIL: ", label)


func _physics_process(_delta: float) -> void:
	if _player == null:
		return
	_frame += 1
	var p_sprite: AnimatedSprite2D = _player.get_node("AnimatedSprite2D")

	match _frame:
		10:
			_check(p_sprite.sprite_frames != null, "Player có SpriteFrames")
			if p_sprite.sprite_frames != null:
				_check(p_sprite.sprite_frames.has_animation(&"attack_down"), "SpriteFrames player có attack_down")
				_check(p_sprite.sprite_frames.has_animation(&"death"), "SpriteFrames player có death")
			_check(p_sprite.animation == &"idle_down", "Player đứng yên = idle_down (thấy: %s)" % p_sprite.animation)
		12:
			Input.action_press("move_right")
		30:
			_check(p_sprite.animation == &"walk_side" and not p_sprite.flip_h,
				"Player đi phải = walk_side, không lật (thấy: %s)" % p_sprite.animation)
		40:
			Input.action_release("move_right")
			Input.action_press("attack")
		44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55:
			if String(p_sprite.animation).begins_with("attack_"):
				_attack_seen = true
		56:
			Input.action_release("attack")
			_check(_attack_seen, "Player bấm chém = attack_* (đã thấy trong cửa sổ kiểm tra)")
			# Đưa goblin ra cách player 150px để kiểm tra chase
			if is_instance_valid(_goblin):
				_goblin.global_position = _player.global_position + Vector2(-150, 0)
				_chase_start_dist = _goblin.global_position.distance_to(_player.global_position)
		90:
			if is_instance_valid(_goblin):
				var dist_now: float = _goblin.global_position.distance_to(_player.global_position)
				_check(dist_now < _chase_start_dist - 25.0,
					"Goblin vẫn chase player (dist %.0f -> %.0f)" % [_chase_start_dist, dist_now])
				var g_sprite: AnimatedSprite2D = _goblin.get_node("AnimatedSprite2D")
				_check(String(g_sprite.animation).begins_with("walk_"),
					"Goblin chase = walk_* (thấy: %s)" % g_sprite.animation)
			else:
				_check(false, "Goblin còn sống ở mốc chase")
		95:
			if is_instance_valid(_goblin):
				_goblin.take_damage(999, _player.global_position)
				_kill_frame = _frame
			else:
				_check(false, "Goblin còn sống ở mốc giết")
		105:
			# +10 frame sau khi chết: xác phải CÒN đó, đang chơi death, không va chạm
			_check(is_instance_valid(_goblin) and _goblin.is_inside_tree(),
				"Goblin chết KHÔNG biến mất ngay (còn xác sau 10 frame)")
			if is_instance_valid(_goblin):
				_check(int(_goblin.get("state")) == 3, "Goblin ở state DEAD")
				var g_sprite2: AnimatedSprite2D = _goblin.get_node("AnimatedSprite2D")
				_check(g_sprite2.animation == &"death",
					"Goblin đang chơi animation death (thấy: %s)" % g_sprite2.animation)
				var g_shape: CollisionShape2D = _goblin.get_node("CollisionShape2D")
				_check(g_shape.disabled, "Goblin chết đã tắt collision shape")
		175:
			# +80 frame (~1.3s) sau khi chết: phải đã biến mất (death anim 0.6s)
			_check(not is_instance_valid(_goblin) or not _goblin.is_inside_tree(),
				"Goblin biến mất SAU khi death animation xong")
			print("[ANIMTEST] Tổng kết: %d FAIL" % _failures.size())
			get_tree().quit(1 if _failures.size() > 0 else 0)
