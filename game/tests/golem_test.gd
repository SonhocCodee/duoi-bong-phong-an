extends Node
## Test tự động cho ếch độc + Boss Mossback, the Moss Golem (chạy headless):
##   godot --headless --path game res://tests/golem_test.tscn
## Kiểm tra: frog dùng enemy_base + slime_frames đúng thông số, chết -> DEAD
## + gold +2; boss golem: boss display set khi trúng đòn, <=50% HP -> phase 2
## (speed 55 -> 71.5), ép slam bằng player.tscn thật đứng cạnh (player -26 HP),
## chết -> seal_keys["dong"] = true + flag golem_dead + boss display rỗng.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.
## Ghi chú: ếch độc ở prototype gây damage thường (chưa có DoT) — xem frog.tscn.

var _frame := 0
var _failures: Array[String] = []
var _frog: Node = null
var _boss: Node = null
var _player: Node = null
var _gold0: int = 0
var _player_hp0: int = -1
var _slam_checked := false
var _slam_deadline := -1
var _kill_frame := -1


func _ready() -> void:
	_gold0 = GameState.gold
	_frog = load("res://enemies/frog.tscn").instantiate()
	_frog.global_position = Vector2(0, -300)
	add_child(_frog)
	_boss = load("res://enemies/boss_golem.tscn").instantiate()
	_boss.global_position = Vector2(500, -300)
	add_child(_boss)
	print("[GOLEMTEST] Bắt đầu test frog + boss golem (gold ban đầu = %d)." % _gold0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("[GOLEMTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[GOLEMTEST] FAIL: ", label)


func _physics_process(_delta: float) -> void:
	_frame += 1

	# --- Chờ slam sau khi đã thả player cạnh boss ---
	if _player != null and not _slam_checked:
		if int(_boss.get("slam_count")) >= 1:
			_slam_checked = true
			_check(bool(_boss.get("last_slam_hit")), "Slam trúng player trong 85px (last_slam_hit)")
			_check(int(_player.get("hp")) == _player_hp0 - 26,
				"Player mất đúng 26 HP vì slam (hp=%d, trước=%d)" % [int(_player.get("hp")), _player_hp0])
			# Đưa player ra xa để boss không melee thêm trước đòn kết liễu
			_player.global_position = Vector2(5000, 5000)
			_kill_frame = _frame + 3
		elif _slam_deadline > 0 and _frame > _slam_deadline:
			_slam_checked = true
			_check(false, "Boss đã slam trong thời hạn (slam_count=%d)" % int(_boss.get("slam_count")))
			_kill_frame = _frame + 3

	# --- Đòn kết liễu boss ---
	if _kill_frame > 0 and _frame == _kill_frame:
		_boss.take_damage(9999, Vector2(0, -300))
		_check(int(_boss.get("state")) == 3, "Boss chết -> state DEAD")
		_check(bool(GameState.seal_keys.get("dong", false)), "Boss chết -> seal_keys[dong] = true")
		_check(GameState.get_flag("golem_dead"), "Boss chết -> flag golem_dead = true")
		_check(str(GameState.boss_name) == "", "Boss chết -> boss display rỗng (boss_name='%s')" % str(GameState.boss_name))
		_check(not bool(_boss.get("boss_display_active")), "Boss chết -> boss_display_active = false (phía boss)")
		_check(GameState.gold == _gold0 + 122, "Tổng gold: frog +2, boss +120 (gold=%d)" % GameState.gold)
	if _kill_frame > 0 and _frame == _kill_frame + 70:
		_check(not is_instance_valid(_boss) or not _boss.is_inside_tree(), "Boss biến mất sau death animation")
		print("[GOLEMTEST] Tổng kết: %d FAIL" % _failures.size())
		get_tree().quit(1 if _failures.size() > 0 else 0)
		return

	match _frame:
		5:
			# --- Frog: thông số + hình ---
			_check(str(_frog.get("enemy_type")) == "frog", "Frog enemy_type = frog")
			_check(str(_frog.get("display_name")) == "Ếch độc Mistlake", "Frog display_name = Ếch độc Mistlake")
			_check(int(_frog.get("max_hp")) == 18 and int(_frog.get("hp")) == 18, "Frog HP = 18")
			_check(int(_frog.get("damage")) == 7 and int(_frog.get("xp_reward")) == 9 and int(_frog.get("gold_reward")) == 2,
				"Frog dmg/xp/gold = 7/9/2")
			_check(is_equal_approx(float(_frog.get("speed")), 95.0), "Frog speed = 95")
			_check(is_equal_approx(float(_frog.get("attack_range")), 40.0), "Frog attack_range = 40")
			_check(_frog.is_in_group("enemy"), "Frog ở group enemy")
			_check(is_equal_approx(float(_frog.get("sprite_scale")), 0.9), "Frog sprite_scale = 0.9")
			var f_frames: Resource = _frog.get("sprite_frames")
			_check(f_frames != null and f_frames.resource_path == "res://assets/sprites/slime_frames.tres",
				"Frog dùng slime_frames.tres")
			var f_mod: Color = _frog.get_node("Sprite").modulate
			_check(absf(f_mod.r - 0.55) < 0.02 and absf(f_mod.g - 0.95) < 0.02 and absf(f_mod.b - 1.05) < 0.02,
				"Frog sprite modulate xanh lơ/cyan (thấy %s)" % str(f_mod))
			# --- Boss: thông số ---
			_check(str(_boss.get("enemy_type")) == "boss_golem", "Boss enemy_type = boss_golem")
			_check(str(_boss.get("display_name")) == "Mossback, the Moss Golem", "Boss display_name = Mossback, the Moss Golem")
			_check(int(_boss.get("max_hp")) == 380 and int(_boss.get("damage")) == 18
				and is_equal_approx(float(_boss.get("speed")), 55.0), "Boss HP/dmg/speed = 380/18/55")
			_check(int(_boss.get("xp_reward")) == 200 and int(_boss.get("gold_reward")) == 120,
				"Boss xp/gold = 200/120")
			_check(is_equal_approx(float(_boss.get("attack_cooldown_time")), 1.2), "Boss attack_cooldown = 1.2")
			_check(is_equal_approx(float(_boss.get("sprite_scale")), 2.3), "Boss sprite_scale = 2.3")
			_check(int(_boss.get("phase")) == 1, "Boss bắt đầu ở phase 1")
			_check(is_equal_approx(float(_boss.call("_move_speed")), 55.0), "Boss phase 1 _move_speed = 55")
			var b_frames: Resource = _boss.get("sprite_frames")
			_check(b_frames != null and b_frames.resource_path == "res://assets/sprites/golem_frames.tres",
				"Boss dùng golem_frames.tres")
			var b_sprite: AnimatedSprite2D = _boss.get_node("Sprite")
			_check(b_sprite.sprite_frames != null and b_sprite.sprite_frames.has_animation(&"death"),
				"Boss có SpriteFrames + animation death")
			_check(str(GameState.boss_name) == "Mossback, the Moss Golem" and int(GameState.boss_max_hp) == 380,
				"Boss display đã set sau _ready (name='%s', max=%d)" % [str(GameState.boss_name), int(GameState.boss_max_hp)])
		6:
			_frog.take_damage(999, Vector2(-100, -300))
			_check(int(_frog.get("state")) == 3, "Frog chết -> state DEAD")
			_check(GameState.gold == _gold0 + 2, "Frog chết -> +2 gold qua GameState (gold=%d)" % GameState.gold)
		8:
			_boss.take_damage(10, Vector2(0, -300))
			_check(int(_boss.get("hp")) == 370, "Boss trúng 10 dmg còn 370 HP (thấy %d)" % int(_boss.get("hp")))
			_check(int(GameState.boss_hp) == 370 and str(GameState.boss_name) == "Mossback, the Moss Golem",
				"Boss display cập nhật khi trúng đòn (boss_hp=%d)" % int(GameState.boss_hp))
		10:
			_boss.take_damage(200, Vector2(0, -300))
			_check(int(_boss.get("hp")) == 170, "Boss sau tổng 210 dmg còn 170 HP (thấy %d)" % int(_boss.get("hp")))
			_check(int(_boss.get("phase")) == 2, "Boss <=50% HP -> phase 2")
			_check(is_equal_approx(float(_boss.call("_move_speed")), 71.5),
				"Boss phase 2 speed x1.3 = 71.5 (thấy %.1f)" % float(_boss.call("_move_speed")))
			_check(is_equal_approx(float(_boss.call("_current_slam_cooldown")), 2.5),
				"Boss phase 2 slam cooldown = 2.5s")
		12:
			# Thả player thật đứng cạnh boss (70px: trong tầm slam 110/85,
			# ngoài tầm melee) và ép slam sẵn sàng.
			_player = load("res://player/player.tscn").instantiate()
			_player.global_position = _boss.global_position + Vector2(70, 0)
			add_child(_player)
			_boss.set("slam_timer", 0.0)
			_slam_deadline = _frame + 150
		13:
			_player_hp0 = int(_player.get("hp"))
			_check(_player_hp0 > 26, "Player dummy sẵn sàng cho slam (hp=%d)" % _player_hp0)
