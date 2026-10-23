extends "res://enemies/enemy_base.gd"
## Goblin — quái cơ bản vùng Đông, nay là subclass mỏng của enemy_base
## như boar/wolf (trước đây là script độc lập extends CharacterBody2D
## nên các export mới của base như respawn_time / is_elite / drop_* /
## key_flag bị rớt khi đặt trên instance trong map).
## Chỉ số gốc của prototype giữ nguyên, khai trong goblin.tscn:
## max_hp 30, speed 110, damage 8, detect_range 220, attack_range 42,
## attack_cooldown_time 1.0, xp_reward 15, gold_reward 5,
## death_anim_duration 0.6. Toàn bộ AI idle wander / chase / attack /
## hurt / death do base đảm nhiệm; enemy_type = "goblin" trong .tscn
## để khi chết base gọi QuestManager.on_enemy_killed("goblin")
## (quest dong_01_goblin). Goblin không có hành vi riêng ngoài base.


func _ready() -> void:
	super._ready()
	# Tương thích ngược tên node sprite: scene dùng tên "Sprite" như mọi
	# quái theo chuẩn base (base tra $Sprite ở @onready), nhưng code/test
	# cũ tra cứu sprite của goblin theo tên gốc "AnimatedSprite2D"
	# (anim_test). Base chỉ giữ tham chiếu qua biến `sprite` sau _ready
	# và không tra cứu lại theo đường dẫn, nên đổi tên node ở đây là an
	# toàn và giữ cả hai hợp đồng.
	if sprite != null:
		sprite.name = "AnimatedSprite2D"
