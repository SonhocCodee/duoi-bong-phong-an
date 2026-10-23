extends Node
## Test tự động cho enemy Giai đoạn 1 (chạy headless):
##   godot --headless --path game res://tests/enemy_test.tscn
## Kiểm tra: rat/slime dùng enemy_base đúng thông số, take_damage đến chết
## -> state DEAD, thưởng gold qua GameState (QuestManager.on_enemy_killed
## in log "[QuestManager] Enemy bị hạ: <type>"), boss The Rat King chuyển
## phase 2 ở <=50% HP, gọi được chuột con, chết thì clear boss display.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _frame := 0
var _failures: Array[String] = []
var _rat: Node = null
var _slime: Node = null
var _boss: Node = null
var _gold0: int = 0


func _ready() -> void:
	_gold0 = GameState.gold
	_rat = load("res://enemies/rat.tscn").instantiate()
	_rat.global_position = Vector2(0, -200)
	add_child(_rat)
	_slime = load("res://enemies/slime.tscn").instantiate()
	_slime.global_position = Vector2(220, -200)
	add_child(_slime)
	_boss = load("res://enemies/boss_rat_king.tscn").instantiate()
	_boss.global_position = Vector2(-260, 120)
	add_child(_boss)
	print("[ENEMYTEST] Bắt đầu test enemy (gold ban đầu = %d)." % _gold0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("[ENEMYTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[ENEMYTEST] FAIL: ", label)


func _count_rats() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if str(e.get("enemy_type")) == "rat":
			n += 1
	return n


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		5:
			_check(str(_rat.get("enemy_type")) == "rat", "Rat enemy_type = rat")
			_check(int(_rat.get("max_hp")) == 15 and int(_rat.get("hp")) == 15, "Rat HP = 15")
			_check(is_equal_approx(float(_rat.get("speed")), 130.0), "Rat speed = 130")
			_check(int(_rat.get("damage")) == 5 and int(_rat.get("xp_reward")) == 8 and int(_rat.get("gold_reward")) == 2,
				"Rat dmg/xp/gold = 5/8/2")
			_check(_rat.is_in_group("enemy"), "Rat ở group enemy")
			var r_sprite: AnimatedSprite2D = _rat.get_node("Sprite")
			_check(r_sprite.sprite_frames != null and r_sprite.sprite_frames.has_animation(&"death"),
				"Rat có SpriteFrames + animation death")
			_check(str(_slime.get("enemy_type")) == "slime", "Slime enemy_type = slime")
			_check(int(_slime.get("max_hp")) == 25 and is_equal_approx(float(_slime.get("speed")), 60.0),
				"Slime HP = 25, speed = 60")
			_check(int(_slime.get("damage")) == 6 and int(_slime.get("xp_reward")) == 10 and int(_slime.get("gold_reward")) == 3,
				"Slime dmg/xp/gold = 6/10/3")
			_check(str(_boss.get("enemy_type")) == "boss_rat_king", "Boss enemy_type = boss_rat_king")
			_check(int(_boss.get("max_hp")) == 220 and int(_boss.get("damage")) == 14
				and is_equal_approx(float(_boss.get("speed")), 95.0), "Boss HP/dmg/speed = 220/14/95")
			_check(int(_boss.get("phase")) == 1, "Boss bắt đầu ở phase 1")
			_check(bool(_boss.get("boss_display_active")), "Boss display đang active sau _ready")
			if not GameState.has_method("set_boss_display"):
				print("[ENEMYTEST] NOTE: GameState chưa có set_boss_display/clear_boss_display (boss gọi phòng thủ has_method)")
		6:
			_rat.take_damage(999, Vector2(-100, -200))
			_check(int(_rat.get("state")) == 3, "Rat chết -> state DEAD")
			_check(GameState.gold == _gold0 + 2, "Rat chết -> +2 gold qua GameState (gold=%d)" % GameState.gold)
		8:
			_slime.take_damage(10, Vector2(120, -200))
			_check(int(_slime.get("hp")) == 15 and int(_slime.get("state")) != 3,
				"Slime trúng 10 dmg còn 15 HP, chưa chết")
		9:
			_slime.take_damage(999, Vector2(120, -200))
			_check(int(_slime.get("state")) == 3, "Slime chết -> state DEAD")
			_check(GameState.gold == _gold0 + 5, "Slime chết -> +3 gold (gold=%d)" % GameState.gold)
		70:
			_check(not is_instance_valid(_rat) or not _rat.is_inside_tree(), "Rat biến mất sau death animation")
			_check(not is_instance_valid(_slime) or not _slime.is_inside_tree(), "Slime biến mất sau death animation")
			_boss.take_damage(120, Vector2(-400, 120))
			_check(int(_boss.get("hp")) == 100, "Boss sau 120 dmg còn 100 HP (thấy %d)" % int(_boss.get("hp")))
			_check(int(_boss.get("phase")) == 2, "Boss <=50%% HP -> phase 2")
			_check(is_equal_approx(float(_boss.call("_move_speed")), 114.0),
				"Boss phase 2 tốc độ +20%% = 114 (thấy %.1f)" % float(_boss.call("_move_speed")))
			_boss.set("_summon_timer", 0.05) # rút ngắn chờ gọi đàn cho test
		100:
			_check(int(_boss.get("summons_done")) >= 1, "Boss phase 2 đã gọi đàn (summons_done=%d)" % int(_boss.get("summons_done")))
			_check(_count_rats() >= 2, "Có >=2 chuột con được spawn (thấy %d)" % _count_rats())
		105:
			_boss.take_damage(9999, Vector2(-400, 120))
			_check(int(_boss.get("state")) == 3, "Boss chết -> state DEAD")
			_check(not bool(_boss.get("boss_display_active")), "Boss chết -> boss display đã clear (phía boss)")
			var bn: Variant = GameState.get("boss_name")
			_check(bn == null or str(bn) == "", "GameState.boss_name rỗng sau khi boss chết (thấy: %s)" % str(bn))
			_check(GameState.gold == _gold0 + 85, "Boss chết -> +80 gold (gold=%d)" % GameState.gold)
		175:
			_check(not is_instance_valid(_boss) or not _boss.is_inside_tree(), "Boss biến mất sau death animation")
			print("[ENEMYTEST] Tổng kết: %d FAIL" % _failures.size())
			get_tree().quit(1 if _failures.size() > 0 else 0)
