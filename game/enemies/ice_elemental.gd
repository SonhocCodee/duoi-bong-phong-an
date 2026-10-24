extends "res://enemies/stone_spirit.gd"
## Quái Băng — Frostgard (Lv 19-24). Thân băng cứng (kế thừa giảm damage
## phẳng của stone_spirit.gd). Khi chết, lõi băng NỔ: player đứng trong
## burst_radius bị burst_damage sát thương băng. Dạy người chơi kết liễu
## từ xa / lùi ra trước đòn cuối.

@export var burst_damage: int = 24
@export var burst_radius: float = 100.0

var burst_done: bool = false


func _on_death() -> void:
	if burst_done:
		return
	burst_done = true
	var hit := false
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node2D and global_position.distance_to((p as Node2D).global_position) <= burst_radius:
			if p.has_method("take_damage"):
				p.take_damage(burst_damage, global_position)
				hit = true
	print("[%s] NỔ BĂNG! Lõi băng vỡ tung trong %.0fpx — %s" % [display_name, burst_radius, "player trúng %d damage băng" % burst_damage if hit else "không ai trong tầm nổ"])
