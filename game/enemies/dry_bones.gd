extends "res://enemies/enemy_base.gd"
## Xương Khô Sa Mạc — lần đầu bị hạ, xương tự ráp lại với revive_hp HP.
## Chỉ hồi sinh 1 lần; lần hạ thứ hai chết hẳn theo enemy_base.

@export var revive_hp: int = 45

var has_revived: bool = false
var revive_count: int = 0


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if state != State.DEAD and not has_revived and amount >= hp:
		var non_lethal: int = maxi(0, hp - maxi(1, revive_hp))
		has_revived = true
		revive_count += 1
		super.take_damage(non_lethal, from_position)
		_hurt_flash_timer = 0.3
		print("[%s] Xương vỡ tung rồi TỰ RÁP LẠI! Hồi sinh với %d HP (lần duy nhất)" % [display_name, hp])
		return
	super.take_damage(amount, from_position)
