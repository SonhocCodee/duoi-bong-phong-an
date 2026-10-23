extends "res://enemies/enemy_base.gd"
## Thạch linh núi — thân đá cứng: mọi đòn đánh bị giảm phẳng flat_reduction
## (4) damage, tối thiểu vẫn nhận 1. Dùng golem_frames tint xám xanh,
## scale lớn, chậm chạp (speed 45) nhưng HP cao (90) và đấm đau (16).

@export var flat_reduction: int = 4


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEAD:
		super.take_damage(amount, from_position)
		return
	var reduced: int = maxi(1, amount - flat_reduction)
	if reduced != amount:
		print("[%s] Thân đá kháng: %d -> %d damage" % [display_name, amount, reduced])
	super.take_damage(reduced, from_position)
