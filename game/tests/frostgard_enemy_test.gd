extends Node
## Test tự động cho QUÁI + BOSS VÙNG BẮC FROSTGARD (headless):
##   godot --headless --path game res://tests/frostgard_enemy_test.tscn
## Kiểm 5 quái thường (chỉ số/frames/tint/scale/script), Hiệp Sĩ Băng
## cơ chế KÝ ỨC (detect 70 -> tỉnh khi bị đánh), Quái Băng NỔ BĂNG khi
## chết theo khoảng cách, Vharok (Đạn Băng 3/5, triệu hồi mốc 66/33,
## phase 2). Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _frame := 0
var _passes: int = 0
var _failures: Array[String] = []

var _wolf: Node = null
var _wight: Node = null
var _knight: Node = null
var _elemental: Node = null
var _wraith: Node = null
var _warden: Node = null
var _player: Node = null
var _gold_before_warden: int = 0


func _spawn(path: String, pos: Vector2) -> Node:
	var n: Node = load(path).instantiate()
	n.global_position = pos
	add_child(n)
	return n


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[FROSTTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[FROSTTEST] FAIL: ", label)


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


func _count_frost_bolts() -> int:
	var n := 0
	for child in get_children():
		if child.get_script() != null and child.get_script().resource_path == "res://enemies/frost_bolt.gd":
			n += 1
	return n


func _count_awake_knights() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if str(e.get("enemy_type")) == "frost_knight" and not bool(e.get("remembering")):
			n += 1
	return n


func _heal_player() -> void:
	if _player == null:
		return
	_player.set("hp", 100)
	GameState.set_player_hp(100, int(_player.get("max_hp")))


func _ready() -> void:
	GameState.reset_game()
	QuestManager.reset_quests()
	_wolf = _spawn("res://enemies/snow_wolf.tscn", Vector2(0, -1200))
	_wight = _spawn("res://enemies/wight.tscn", Vector2(650, -1200))
	_knight = _spawn("res://enemies/frost_knight.tscn", Vector2(1300, -1200))
	_elemental = _spawn("res://enemies/ice_elemental.tscn", Vector2(1950, -1200))
	_wraith = _spawn("res://enemies/frost_wraith.tscn", Vector2(2600, -1200))
	_warden = _spawn("res://enemies/boss_curse_warden.tscn", Vector2(4200, -1200))
	_check(str(GameState.boss_name) == "Vharok, Kẻ Giữ Nguyền",
		"Warden _ready set boss display")
	print("[FROSTTEST] Bắt đầu test quái Frostgard.")


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		5:
			_stats(_wolf, "snow_wolf", "Sói Tuyết", 250, 30, 155.0, 140, 20, "SnowWolf")
			_check(_frames_path(_wolf) == "res://assets/sprites/wolf_frames.tres", "SnowWolf dùng wolf_frames")
			_check(_tint_ok(_wolf, 0.82, 0.9, 1.05), "SnowWolf tint lạnh")
			_check(is_equal_approx(float(_wolf.get("sprite_scale")), 1.1), "SnowWolf scale 1.1")
			_check(_wolf.get_script().resource_path == "res://enemies/wolf.gd", "SnowWolf dùng wolf.gd (bầy)")

			_stats(_wight, "wight", "Wight Bão Tuyết", 430, 38, 88.0, 170, 26, "Wight")
			_check(_frames_path(_wight) == "res://assets/sprites/golem_frames.tres", "Wight dùng golem_frames")
			_check(_tint_ok(_wight, 0.62, 0.78, 0.9), "Wight tint xám băng")
			_check(is_equal_approx(float(_wight.get("sprite_scale")), 1.15), "Wight scale 1.15")
			_check(_wight.get_script().resource_path == "res://enemies/enemy_base.gd", "Wight dùng enemy_base.gd")
			_check(is_equal_approx(float(_wight.get("detect_range")), 260.0), "Wight detect_range 260")

			_stats(_knight, "frost_knight", "Hiệp Sĩ Băng", 340, 34, 95.0, 180, 30, "FrostKnight")
			_check(_frames_path(_knight) == "res://assets/sprites/goblin_frames.tres", "FrostKnight dùng goblin_frames")
			_check(_tint_ok(_knight, 0.55, 0.75, 1.0), "FrostKnight tint băng")
			_check(is_equal_approx(float(_knight.get("sprite_scale")), 1.12), "FrostKnight scale 1.12")
			_check(_knight.get_script().resource_path == "res://enemies/frost_knight.gd", "FrostKnight dùng frost_knight.gd")
			_check(bool(_knight.get("remembering")) == true, "FrostKnight spawn với remembering = true")
			_check(is_equal_approx(float(_knight.get("detect_range")), 70.0), "FrostKnight đang nhớ: detect_range = 70")
			_check(is_equal_approx(float(_knight.get("base_detect_range")), 300.0), "FrostKnight base_detect_range = 300")

			_stats(_elemental, "ice_elemental", "Quái Băng", 300, 30, 70.0, 160, 22, "IceElemental")
			_check(_frames_path(_elemental) == "res://assets/sprites/slime_frames.tres", "IceElemental dùng slime_frames")
			_check(_tint_ok(_elemental, 0.45, 0.85, 1.05), "IceElemental tint băng")
			_check(is_equal_approx(float(_elemental.get("sprite_scale")), 1.35), "IceElemental scale 1.35")
			_check(_elemental.get_script().resource_path == "res://enemies/ice_elemental.gd", "IceElemental dùng ice_elemental.gd")
			_check(int(_elemental.get("burst_damage")) == 24, "IceElemental burst_damage = 24")
			_check(is_equal_approx(float(_elemental.get("burst_radius")), 100.0), "IceElemental burst_radius = 100")

			_stats(_wraith, "frost_wraith", "Hồn Ma Băng", 210, 32, 165.0, 150, 18, "FrostWraith")
			_check(_frames_path(_wraith) == "res://assets/sprites/wyvern_frames.tres", "FrostWraith dùng wyvern_frames")
			_check(_tint_ok(_wraith, 0.75, 0.88, 1.1), "FrostWraith tint băng mờ")
			_check(is_equal_approx(float(_wraith.get("sprite_scale")), 1.05), "FrostWraith scale 1.05")
			_check(_wraith.get_script().resource_path == "res://enemies/wyvern.gd", "FrostWraith dùng wyvern.gd (lướt)")
			_check(is_equal_approx(float(_wraith.get("dash_speed")), 340.0), "FrostWraith dash_speed 340")

			_stats(_warden, "boss_curse_warden", "Vharok, Kẻ Giữ Nguyền",
				3000, 40, 92.0, 2400, 1500, "Warden")
			_check(_frames_path(_warden) == "res://assets/sprites/goblin_frames.tres", "Warden dùng goblin_frames")
			_check(_tint_ok(_warden, 0.55, 0.7, 1.0), "Warden tint phase 1")
			_check(is_equal_approx(float(_warden.get("sprite_scale")), 1.8), "Warden scale 1.8")
			_check(int(_warden.get("phase")) == 1, "Warden bắt đầu phase 1")
			_check(int(_warden.call("_current_burst_size")) == 3, "Warden phase 1 burst = 3")
			_check(is_equal_approx(float(_warden.call("_current_bolt_cooldown")), 3.4), "Warden phase 1 bolt CD 3.4s")
			_check(is_equal_approx(float(_warden.call("_move_speed")), 92.0), "Warden phase 1 speed 92")
			_check(is_equal_approx(float(_warden.get("detect_range")), 400.0), "Warden detect_range 400")
			_check(is_equal_approx(float(_warden.get("attack_range")), 60.0), "Warden attack_range 60")
		7:
			_wolf.take_damage(10, Vector2.ZERO)
			_check(int(_wolf.get("hp")) == 240, "SnowWolf trúng 10 còn 240 HP")
			_wight.take_damage(10, Vector2.ZERO)
			_check(int(_wight.get("hp")) == 420, "Wight trúng 10 còn 420 HP")
			_wraith.take_damage(10, Vector2.ZERO)
			_check(int(_wraith.get("hp")) == 200, "FrostWraith trúng 10 còn 200 HP")
			_elemental.take_damage(16, Vector2.ZERO)
			_check(int(_elemental.get("hp")) == 288, "IceElemental thân băng: 16 dmg -> mất 12 HP (còn %d)" % int(_elemental.get("hp")))
			# Hiệp Sĩ Băng: đòn đầu tiên phá ký ức
			_knight.take_damage(10, Vector2.ZERO)
			_check(int(_knight.get("hp")) == 330, "FrostKnight trúng 10 còn 330 HP")
			_check(bool(_knight.get("remembering")) == false, "FrostKnight bị đánh -> remembering = false")
			_check(is_equal_approx(float(_knight.get("detect_range")), 300.0), "FrostKnight tỉnh: detect_range = 300")
			_check(str(_knight.get("last_memory_line")) != "", "FrostKnight last_memory_line có câu ký ức: \"%s\"" % str(_knight.get("last_memory_line")))
		9:
			# Warden: loạt phase 1
			_warden.call("shoot_frost_bolt_burst")
			_check(int(_warden.get("bolt_count")) == 3, "Warden phase 1 bắn 3 Đạn Băng")
			_check(int(_warden.get("bursts_fired")) == 1, "Warden bursts_fired = 1")
			_check(_count_frost_bolts() >= 3, "FrostBolt của Warden đã spawn (%d)" % _count_frost_bolts())
		11:
			# Warden: chạm mốc 66% -> gọi hiệp sĩ đợt 1 (3000 -> 1980)
			_warden.take_damage(1020, Vector2.ZERO)
			_check(int(_warden.get("hp")) == 1980, "Warden còn 1980 HP (mốc 66%)")
			_check(int(_warden.get("summon_waves_done")) == 1, "Warden mốc 66% gọi hiệp sĩ đợt 1")
			_check(int(_warden.get("summons_done")) == 2, "Warden đợt 1 = 2 hiệp sĩ")
			_check(_count_awake_knights() >= 2, "Hiệp sĩ triệu hồi có remembering = false (%d)" % _count_awake_knights())
			_check(int(_warden.get("phase")) == 1, "Warden 1980 HP vẫn phase 1")
		13:
			# Warden: xuống 50% -> phase 2 (1980 -> 1500)
			_warden.take_damage(480, Vector2.ZERO)
			_check(int(_warden.get("hp")) == 1500, "Warden còn 1500 HP (mốc 50%)")
			_check(int(_warden.get("phase")) == 2, "Warden vào phase 2")
			_check(is_equal_approx(float(_warden.call("_move_speed")), 115.0), "Warden phase 2 speed x1.25 = 115")
			_check(is_equal_approx(float(_warden.call("_current_bolt_cooldown")), 2.2), "Warden phase 2 bolt CD 2.2s")
			_check(int(_warden.call("_current_burst_size")) == 5, "Warden phase 2 burst = 5")
			_check(_tint_ok(_warden, 0.35, 0.45, 0.95), "Warden phase 2 tint sẫm")
			_warden.call("shoot_frost_bolt_burst")
			_check(int(_warden.get("bolt_count")) == 8, "Warden tổng Đạn Băng = 3+5 = 8")
		15:
			# Warden: mốc 33% -> đợt hiệp sĩ cuối (1500 -> 990)
			_warden.take_damage(510, Vector2.ZERO)
			_check(int(_warden.get("hp")) == 990, "Warden còn 990 HP (mốc 33%)")
			_check(int(_warden.get("summon_waves_done")) == 2, "Warden mốc 33% gọi hiệp sĩ đợt 2")
			_check(int(_warden.get("summons_done")) == 4, "Warden tổng triệu hồi = 4")
			_check(int(_warden.call("summon_knights")) == 0, "Warden hết đợt triệu hồi (hữu hạn)")
		17:
			_gold_before_warden = GameState.gold
			_warden.take_damage(9999, Vector2.ZERO)
			_check(int(_warden.get("state")) == 3, "Warden chết -> DEAD")
			_check(GameState.gold == _gold_before_warden + 1500, "Warden chết -> +1500 gold")
			_check(str(GameState.boss_name) == "", "Warden chết -> clear boss display")
		19:
			# Quái Băng nổ khi chết: player cách 60px -> mất đúng burst_damage
			var burst_near: Node = _spawn("res://enemies/ice_elemental.tscn", Vector2(10000, -1200))
			_player = _spawn("res://player/player.tscn", burst_near.global_position + Vector2(60, 0))
			_heal_player()
			_check(GameState.defense_bonus == 0, "DEF GameState = 0 sau reset (burst trừ đúng số)")
			burst_near.take_damage(9999, Vector2.ZERO)
			_check(int(burst_near.get("state")) == 3, "Quái Băng (gần) chết -> DEAD")
			_check(bool(burst_near.get("burst_done")) == true, "Quái Băng (gần) burst_done = true")
			_check(int(_player.get("hp")) == 76, "Nổ băng cách 60px: player mất đúng 24 HP (còn %d)" % int(_player.get("hp")))
		21:
			# Player cách 200px -> ngoài tầm nổ, không mất HP
			var burst_far: Node = _spawn("res://enemies/ice_elemental.tscn", Vector2(12000, -1200))
			_player.global_position = burst_far.global_position + Vector2(200, 0)
			_heal_player()
			burst_far.take_damage(9999, Vector2.ZERO)
			_check(int(burst_far.get("state")) == 3, "Quái Băng (xa) chết -> DEAD")
			_check(int(_player.get("hp")) == 100, "Nổ băng cách 200px: player không mất HP (còn %d)" % int(_player.get("hp")))
			if _player != null:
				_player.queue_free()
			print("[FROSTTEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
			get_tree().quit(1 if _failures.size() > 0 else 0)
