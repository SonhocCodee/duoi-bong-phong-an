extends Node
## Test tự động cho QUÁI + BOSS VÙNG TÂY SOLMARIS (headless):
##   godot --headless --path game res://tests/solmaris_enemy_test.tscn
## Kiểm 6 quái thường (chỉ số/frames/tint/scale/script), Xương Khô hồi sinh
## đúng 1 lần, Kassia Vane (Đạn Cát 3/5, triệu hồi mốc 66/33, phase 2),
## Vesskar (hơi thở nón, bão cát 8/12, đào cát, phase 2, trạng thái hòa bình).
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _frame := 0
var _passes: int = 0
var _failures: Array[String] = []

var _scorpion: Node = null
var _snake: Node = null
var _merc: Node = null
var _vulture: Node = null
var _bones: Node = null
var _golem: Node = null
var _captain: Node = null
var _vesskar: Node = null
var _player: Node = null
var _gold_before_captain: int = 0
var _gold_before_vesskar: int = 0


func _spawn(path: String, pos: Vector2) -> Node:
	var n: Node = load(path).instantiate()
	n.global_position = pos
	add_child(n)
	return n


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[SOLMARISTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[SOLMARISTEST] FAIL: ", label)


func _stats(e: Node, type: String, name_vi: String, hp: int, dmg: int, spd: float,
		xp: int, gold: int, label: String) -> void:
	_check(str(e.get("enemy_type")) == type, "%s enemy_type = %s" % [label, type])
	_check(str(e.get("display_name")) == name_vi, "%s display_name đúng" % label)
	_check(int(e.get("max_hp")) == hp and int(e.get("hp")) == hp, "%s HP = %d" % [label, hp])
	_check(int(e.get("damage")) == dmg and is_equal_approx(float(e.get("speed")), spd),
		"%s dmg/speed = %d/%.0f" % [label, dmg, spd])
	_check(int(e.get("xp_reward")) == xp and int(e.get("gold_reward")) == gold,
		"%s xp/gold = %d/%d" % [label, xp, gold])
	_check(e.is_in_group("enemy"), "%s ở group enemy" % label)


func _frames_path(e: Node) -> String:
	var f: Resource = e.get("sprite_frames")
	return f.resource_path if f != null else ""


func _tint_ok(e: Node, r: float, g: float, b: float) -> bool:
	var t: Color = e.get("sprite_modulate")
	return absf(t.r - r) < 0.02 and absf(t.g - g) < 0.02 and absf(t.b - b) < 0.02


func _count_sand_bolts() -> int:
	var n := 0
	for child in get_children():
		if child.get_script() != null and child.get_script().resource_path == "res://enemies/sand_bolt.gd":
			n += 1
	return n


func _count_mercenaries() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if str(e.get("enemy_type")) == "mercenary":
			n += 1
	return n


func _ready() -> void:
	GameState.reset_game()
	QuestManager.reset_quests()
	_scorpion = _spawn("res://enemies/sand_scorpion.tscn", Vector2(0, -1200))
	_snake = _spawn("res://enemies/sand_snake.tscn", Vector2(650, -1200))
	_merc = _spawn("res://enemies/mercenary.tscn", Vector2(1300, -1200))
	_vulture = _spawn("res://enemies/sand_vulture.tscn", Vector2(1950, -1200))
	_bones = _spawn("res://enemies/dry_bones.tscn", Vector2(2600, -1200))
	_golem = _spawn("res://enemies/sand_golem.tscn", Vector2(3250, -1200))
	_captain = _spawn("res://enemies/boss_mercenary_captain.tscn", Vector2(4200, -1200))
	_check(str(GameState.boss_name) == "Kassia Vane, Chỉ Huy Lính Đánh Thuê",
		"Captain _ready set boss display")
	_vesskar = _spawn("res://enemies/boss_vesskar.tscn", Vector2(5600, -1200))
	_check(str(GameState.boss_name) == "Vesskar, Rồng Cát", "Vesskar _ready set boss display")
	print("[SOLMARISTEST] Bắt đầu test quái Solmaris.")


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		5:
			_stats(_scorpion, "sand_scorpion", "Bọ Cạp Cát", 130, 22, 135.0, 70, 14, "SandScorpion")
			_check(_frames_path(_scorpion) == "res://assets/sprites/slime_frames.tres", "Scorpion dùng slime_frames")
			_check(_tint_ok(_scorpion, 0.85, 0.48, 0.18), "Scorpion tint nâu cam")
			_check(is_equal_approx(float(_scorpion.get("sprite_scale")), 1.15), "Scorpion scale 1.15")
			_check(_scorpion.get_script().resource_path == "res://enemies/boar.gd", "Scorpion dùng boar.gd (lao húc)")
			_check(is_equal_approx(float(_scorpion.get("charge_speed")), 430.0), "Scorpion charge_speed 430")

			_stats(_snake, "sand_snake", "Rắn Cát", 110, 24, 120.0, 76, 15, "SandSnake")
			_check(_frames_path(_snake) == "res://assets/sprites/wolf_frames.tres", "Snake dùng wolf_frames")
			_check(_tint_ok(_snake, 0.78, 0.72, 0.32), "Snake tint vàng xanh")
			_check(is_equal_approx(float(_snake.get("charge_speed")), 480.0), "Snake charge_speed 480")
			_check(is_equal_approx(float(_snake.get("charge_cooldown")), 2.4), "Snake charge_cooldown 2.4")

			_stats(_merc, "mercenary", "Lính Đánh Thuê", 180, 26, 105.0, 88, 24, "Mercenary")
			_check(_frames_path(_merc) == "res://assets/sprites/goblin_frames.tres", "Mercenary dùng goblin_frames")
			_check(_tint_ok(_merc, 0.72, 0.38, 0.28), "Mercenary tint đỏ nâu")
			_check(_merc.get_script().resource_path == "res://enemies/soldier.gd", "Mercenary dùng soldier.gd (khiên)")

			_stats(_vulture, "sand_vulture", "Kền Kền Cát", 95, 23, 155.0, 82, 16, "SandVulture")
			_check(_frames_path(_vulture) == "res://assets/sprites/wyvern_frames.tres", "Vulture dùng wyvern_frames")
			_check(_tint_ok(_vulture, 0.95, 0.68, 0.3), "Vulture tint vàng đất")
			_check(_vulture.get_script().resource_path == "res://enemies/wyvern.gd", "Vulture dùng wyvern.gd (lướt)")
			_check(is_equal_approx(float(_vulture.get("dash_speed")), 340.0), "Vulture dash_speed 340")

			_stats(_bones, "dry_bones", "Xương Khô", 150, 25, 90.0, 92, 18, "DryBones")
			_check(_frames_path(_bones) == "res://assets/sprites/goblin_frames.tres", "DryBones dùng goblin_frames")
			_check(_tint_ok(_bones, 1.25, 1.2, 1.02), "DryBones tint xương trắng")
			_check(int(_bones.get("revive_hp")) == 45, "DryBones revive_hp = 45")

			_stats(_golem, "sand_golem", "Golem Cát", 320, 32, 55.0, 130, 28, "SandGolem")
			_check(_frames_path(_golem) == "res://assets/sprites/golem_frames.tres", "SandGolem dùng golem_frames")
			_check(_tint_ok(_golem, 1.15, 0.88, 0.5), "SandGolem tint cát vàng")
			_check(is_equal_approx(float(_golem.get("sprite_scale")), 1.35), "SandGolem scale 1.35")
			_check(_golem.get_script().resource_path == "res://enemies/stone_spirit.gd", "SandGolem dùng stone_spirit.gd")

			_stats(_captain, "boss_mercenary_captain", "Kassia Vane, Chỉ Huy Lính Đánh Thuê",
				1500, 30, 100.0, 900, 600, "Captain")
			_check(_frames_path(_captain) == "res://assets/sprites/goblin_frames.tres", "Captain dùng goblin_frames")
			_check(_tint_ok(_captain, 0.72, 0.34, 0.24), "Captain tint phase 1")
			_check(int(_captain.get("phase")) == 1, "Captain bắt đầu phase 1")
			_check(int(_captain.call("_current_burst_size")) == 3, "Captain phase 1 burst = 3")
			_check(is_equal_approx(float(_captain.call("_current_bolt_cooldown")), 3.2), "Captain phase 1 bolt CD 3.2s")
			_check(is_equal_approx(float(_captain.call("_move_speed")), 100.0), "Captain phase 1 speed 100")

			_stats(_vesskar, "boss_vesskar", "Vesskar, Rồng Cát", 2400, 38, 85.0, 1600, 1000, "Vesskar")
			_check(_frames_path(_vesskar) == "res://assets/sprites/wyvern_frames.tres", "Vesskar dùng wyvern_frames")
			_check(_tint_ok(_vesskar, 1.25, 0.95, 0.42), "Vesskar tint phase 1")
			_check(is_equal_approx(float(_vesskar.get("sprite_scale")), 2.2), "Vesskar scale 2.2")
			_check(not bool(_vesskar.get("peaceful")), "Vesskar mặc định không peaceful")
			_check(int(_vesskar.get("phase")) == 1, "Vesskar bắt đầu phase 1")
			_check(int(_vesskar.call("_current_storm_size")) == 8, "Vesskar phase 1 bão = 8 viên")
		7:
			# take_damage cơ bản (from ZERO để lính có khiên không giảm damage)
			_scorpion.take_damage(10, Vector2.ZERO)
			_check(int(_scorpion.get("hp")) == 120, "Scorpion trúng 10 còn 120 HP")
			_snake.take_damage(10, Vector2.ZERO)
			_check(int(_snake.get("hp")) == 100, "Snake trúng 10 còn 100 HP")
			_merc.take_damage(10, Vector2.ZERO)
			_check(int(_merc.get("hp")) == 170, "Mercenary trúng 10 (không khiên) còn 170 HP")
			_vulture.take_damage(10, Vector2.ZERO)
			_check(int(_vulture.get("hp")) == 85, "Vulture trúng 10 còn 85 HP")
			_golem.take_damage(16, Vector2.ZERO)
			_check(int(_golem.get("hp")) == 310, "SandGolem thân đá: 16 dmg -> mất 10 HP (còn %d)" % int(_golem.get("hp")))
			# Xương Khô: đòn kết liễu đầu tiên -> ráp lại 45 HP
			_bones.take_damage(9999, Vector2.ZERO)
			_check(bool(_bones.get("has_revived")) and int(_bones.get("revive_count")) == 1,
				"DryBones hồi sinh lần 1")
			_check(int(_bones.get("hp")) == 45 and int(_bones.get("state")) != 3,
				"DryBones sau hồi sinh còn 45 HP, chưa chết")
		9:
			_bones.take_damage(9999, Vector2.ZERO)
			_check(int(_bones.get("state")) == 3, "DryBones chết hẳn ở lần hạ thứ hai")
			_check(int(_bones.get("revive_count")) == 1, "DryBones chỉ hồi sinh đúng 1 lần")
			# Captain: loạt phase 1
			_captain.call("shoot_sand_bolt_burst")
			_check(int(_captain.get("bolt_count")) == 3, "Captain phase 1 bắn 3 Đạn Cát")
			_check(int(_captain.get("bursts_fired")) == 1, "Captain bursts_fired = 1")
			_check(_count_sand_bolts() >= 3, "SandBolt của Captain đã spawn (%d)" % _count_sand_bolts())
		11:
			# Captain: chạm mốc 66% -> gọi lính đợt 1 (1500 -> 990)
			_captain.take_damage(510, Vector2.ZERO)
			_check(int(_captain.get("hp")) == 990, "Captain còn 990 HP (mốc 66%)")
			_check(int(_captain.get("summon_waves_done")) == 1, "Captain mốc 66% gọi lính đợt 1")
			_check(int(_captain.get("summons_done")) == 2, "Captain đợt 1 = 2 lính")
			_check(_count_mercenaries() >= 3, "Scene có lính gốc + 2 lính triệu hồi")
			_check(int(_captain.get("phase")) == 1, "Captain 990 HP vẫn phase 1")
		13:
			# Captain: xuống 50% -> phase 2 (990 -> 750)
			_captain.take_damage(240, Vector2.ZERO)
			_check(int(_captain.get("hp")) == 750, "Captain còn 750 HP (mốc 50%)")
			_check(int(_captain.get("phase")) == 2, "Captain vào phase 2")
			_check(is_equal_approx(float(_captain.call("_move_speed")), 125.0), "Captain phase 2 speed x1.25 = 125")
			_check(is_equal_approx(float(_captain.call("_current_bolt_cooldown")), 2.0), "Captain phase 2 bolt CD 2.0s")
			_check(int(_captain.call("_current_burst_size")) == 5, "Captain phase 2 burst = 5")
			_check(_tint_ok(_captain, 0.48, 0.16, 0.12), "Captain phase 2 tint đỏ sẫm")
			_captain.call("shoot_sand_bolt_burst")
			_check(int(_captain.get("bolt_count")) == 8, "Captain tổng Đạn Cát = 3+5 = 8")
		15:
			# Captain: mốc 33% -> đợt lính cuối (750 -> 495)
			_captain.take_damage(255, Vector2.ZERO)
			_check(int(_captain.get("hp")) == 495, "Captain còn 495 HP (mốc 33%)")
			_check(int(_captain.get("summon_waves_done")) == 2, "Captain mốc 33% gọi lính đợt 2")
			_check(int(_captain.get("summons_done")) == 4, "Captain tổng triệu hồi = 4")
			_check(int(_captain.call("summon_mercenaries")) == 0, "Captain hết đợt triệu hồi (hữu hạn)")
		17:
			_gold_before_captain = GameState.gold
			_captain.take_damage(9999, Vector2.ZERO)
			_check(int(_captain.get("state")) == 3, "Captain chết -> DEAD")
			_check(GameState.gold == _gold_before_captain + 600, "Captain chết -> +600 gold")
			_check(str(GameState.boss_name) == "", "Captain chết -> clear boss display")
			# Vesskar: bão cát phase 1
			_check(int(_vesskar.call("summon_sandstorm")) == 8, "Vesskar phase 1 bão cát = 8 viên")
			_check(int(_vesskar.get("storm_bolts_fired")) == 8, "Vesskar storm_bolts_fired = 8")
		19:
			# Vesskar: hơi thở cát theo tầm + nón hướng mặt
			_player = _spawn("res://player/player.tscn", _vesskar.global_position + Vector2(120, 0))
			_vesskar.set("_facing", Vector2.RIGHT)
			_player.set("hp", 100)
			GameState.set_player_hp(100, int(_player.get("max_hp")))
			_check(bool(_vesskar.call("sand_breath_attack")), "Vesskar hơi thở trúng player trước mặt trong 300px")
			_check(bool(_vesskar.get("last_breath_hit")), "Vesskar last_breath_hit = true")
			_check(int(_player.get("hp")) == 70, "Hơi thở cát gây 30 damage (HP player %d)" % int(_player.get("hp")))
			_player.global_position = _vesskar.global_position + Vector2(-120, 0)
			_check(not bool(_vesskar.call("sand_breath_attack")), "Vesskar hơi thở hụt player sau lưng (ngoài nón)")
			_check(int(_player.get("hp")) == 70, "Hơi thở hụt: HP player không đổi")
			_player.global_position = _vesskar.global_position + Vector2(900, 0)
			_check(not bool(_vesskar.call("sand_breath_attack")), "Vesskar hơi thở hụt player ngoài tầm")
		21:
			# Vesskar: đào cát áp sát
			_player.global_position = _vesskar.global_position + Vector2(520, 0)
			_check(bool(_vesskar.call("burrow_strike")), "Vesskar đào cát áp sát chạy")
			var dist: float = _vesskar.global_position.distance_to(_player.global_position)
			_check(dist > 80.0 and dist < 105.0, "Sau đào cát, Vesskar cách player ~92px (%.0f)" % dist)
			_check(int(_vesskar.get("burrow_count")) == 1, "Vesskar burrow_count = 1")
			# Phase 2
			_vesskar.take_damage(1201, Vector2.ZERO)
			_check(int(_vesskar.get("hp")) == 1199, "Vesskar còn 1199 HP")
			_check(int(_vesskar.get("phase")) == 2, "Vesskar vào phase 2")
			_check(is_equal_approx(float(_vesskar.call("_move_speed")), 106.25), "Vesskar phase 2 speed x1.25 = 106.25")
			_check(is_equal_approx(float(_vesskar.call("_current_breath_cooldown")), 3.2), "Vesskar phase 2 breath CD 3.2s")
			_check(is_equal_approx(float(_vesskar.call("_current_storm_cooldown")), 6.5), "Vesskar phase 2 storm CD 6.5s")
			_check(int(_vesskar.call("summon_sandstorm")) == 12, "Vesskar phase 2 bão cát = 12 viên")
			_check(int(_vesskar.get("storm_bolts_fired")) == 20, "Vesskar tổng bão = 8+12 = 20 viên")
		23:
			_gold_before_vesskar = GameState.gold
			_vesskar.take_damage(9999, Vector2.ZERO)
			_check(int(_vesskar.get("state")) == 3, "Vesskar chết -> DEAD")
			_check(GameState.gold == _gold_before_vesskar + 1000, "Vesskar chết -> +1000 gold")
			_check(str(GameState.boss_name) == "", "Vesskar chết -> clear boss display")
			if _player != null:
				_player.queue_free()
		25:
			# Trạng thái hòa bình sau đàm phán: spawn instance mới khi flag đã set
			GameState.set_flag("vesskar_dam_phan")
			var peaceful_boss: Node = _spawn("res://enemies/boss_vesskar.tscn", Vector2(8000, -1200))
			_check(bool(peaceful_boss.get("peaceful")), "Flag vesskar_dam_phan -> Vesskar peaceful")
			var hp_before: int = int(peaceful_boss.get("hp"))
			peaceful_boss.take_damage(100, Vector2.ZERO)
			_check(int(peaceful_boss.get("hp")) == hp_before, "Vesskar peaceful không nhận damage")
			_check(int(peaceful_boss.call("summon_sandstorm")) == 0, "Vesskar peaceful không gọi bão cát")
			_check(not bool(peaceful_boss.call("sand_breath_attack")), "Vesskar peaceful không phà hơi thở")
			print("[SOLMARISTEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
			get_tree().quit(1 if _failures.size() > 0 else 0)
