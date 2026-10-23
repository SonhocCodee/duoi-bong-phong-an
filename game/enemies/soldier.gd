extends "res://enemies/enemy_base.gd"
## Lính vua (lính thuế) — mang KHIÊN phía trước:
## Đòn đánh từ phía trước (vị trí kẻ đánh nằm trong góc 100° quanh hướng
## mặt _facing hiện tại) được đỡ: chỉ nhận 40% damage (giảm 60%).
## Đòn từ sau lưng / bên hông sau nhận đủ damage. Muốn đánh lính hiệu quả
## phải vòng ra sau — hoặc chờ nó quay mặt đi chỗ khác.

@export var shield_arc_deg: float = 100.0
@export var shield_damage_mult: float = 0.4 # nhận 40% = giảm 60%

var shield_blocks: int = 0


## True nếu kẻ đánh ở phía trước khiên. Dùng cho cả test bên ngoài.
func is_blocked_from(from_position: Vector2) -> bool:
	if from_position == Vector2.ZERO:
		return false
	var to_attacker: Vector2 = from_position - global_position
	if to_attacker.length() < 0.01:
		return false
	var facing_dir: Vector2 = _facing if _facing != Vector2.ZERO else Vector2.DOWN
	return rad_to_deg(facing_dir.angle_to(to_attacker.normalized())) <= shield_arc_deg * 0.5


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if state != State.DEAD and is_blocked_from(from_position):
		var reduced: int = maxi(1, int(round(amount * shield_damage_mult)))
		shield_blocks += 1
		print("[%s] KHIÊN ĐỠ! %d -> %d damage (đỡ lần %d)" % [display_name, amount, reduced, shield_blocks])
		super.take_damage(reduced, from_position)
		return
	super.take_damage(amount, from_position)
