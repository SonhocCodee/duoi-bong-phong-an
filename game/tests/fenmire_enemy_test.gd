extends Node
## Test tự động cho QUÁI MỚI VÙNG NAM FENMIRE (đầm lầy, Lv 7-12, headless):
##   godot --headless --path game res://tests/fenmire_enemy_test.tscn
## Kiểm tra: 6 loài mới (swamp_frog / mire_leech / swamp_wisp / cultist /
## swamp_croc / water_spider) đúng enemy_type + chỉ số + frames/tint/scale;
## take_damage trừ HP đúng; cultist bắn được shadow_bolt (damage 15) qua
## method công khai; boss Đại Tư Tế Morvain: boss display set sau _ready,
## loạt 3 viên phase 1, mốc 66% HP triệu hồi 2 cultist, <=50% HP ->
## phase 2 (speed x1.3, cooldown đạn 1.8s, loạt 5 viên, tint tím đậm),
## mốc 33% HP triệu hồi đợt 2 (tổng 4, hữu hạn), chết -> boss display
## rỗng + gold thưởng, key_flag trống.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _frame := 0
var _passes: int = 0
var _failures: Array[String] = []
var _gold0: int = 0
var _gold_before_frog: int = 0
var _gold_before_boss: int = 0

var _frog: Node = null
var _leech: Node = null
var _wisp: Node = null
var _cultist: Node = null
var _croc: Node = null
var _wspider: Node = null
var _boss: Node = null


func _spawn(path: String, pos: Vector2) -> Node:
	var n: Node = load(path).instantiate()
	n.global_position = pos
	add_child(n)
	return n


func _ready() -> void:
	_gold0 = GameState.gold
	# Rải xa nhau (600px) để các quái không tương tác lẫn nhau; test này
	# không spawn player nên quái chỉ wander tại chỗ / đứng yên.
	_frog = _spawn("res://enemies/swamp_frog.tscn", Vector2(0, -1000))
	_leech = _spawn("res://enemies/mire_leech.tscn", Vector2(600, -1000))
	_wisp = _spawn("res://enemies/swamp_wisp.tscn", Vector2(1200, -1000))
	_cultist = _spawn("res://enemies/cultist.tscn", Vector2(1800, -1000))
	_croc = _spawn("res://enemies/swamp_croc.tscn", Vector2(2400, -1000))
	_wspider = _spawn("res://enemies/water_spider.tscn", Vector2(3000, -1000))
	_boss = _spawn("res://enemies/boss_high_priest.tscn", Vector2(4000, -1000))
	print("[FENMIRETEST] Bắt đầu test quái Fenmire (gold ban đầu = %d)." % _gold0)


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[FENMIRETEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[FENMIRETEST] FAIL: ", label)


func _stats(e: Node, type: String, name_vi: String, hp: int, dmg: int, spd: float, xp: int, gold: int, label: String) -> void:
	_check(str(e.get("enemy_type")) == type, "%s enemy_type = %s" % [label, type])
	_check(str(e.get("display_name")) == name_vi, "%s display_name = %s" % [label, name_vi])
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


func _count_shadow_bolts() -> int:
	var n := 0
	for child in get_children():
		if child is Area2D and child.get_script() != null \
				and child.get_script().resource_path == "res://enemies/shadow_bolt.gd":
			n += 1
	return n


func _count_cultists() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if str(e.get("enemy_type")) == "cultist":
			n += 1
	return n


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		5:
			# --- 6 loài thường: chỉ số + hình (frames tái dùng + tint/scale) ---
			_stats(_frog, "swamp_frog", "Ếch Độc Đầm Lầy", 70, 14, 100.0, 26, 6, "SwampFrog")
			_check(_frames_path(_frog) == "res://assets/sprites/slime_frames.tres", "SwampFrog dùng slime_frames")
			_check(_tint_ok(_frog, 0.35, 0.65, 0.3), "SwampFrog tint xanh rêu đậm")
			_check(is_equal_approx(float(_frog.get("sprite_scale")), 1.1), "SwampFrog sprite_scale = 1.1")
			_stats(_leech, "mire_leech", "Đỉa Bùn Khổng Lồ", 130, 16, 45.0, 34, 8, "MireLeech")
			_check(_frames_path(_leech) == "res://assets/sprites/slime_frames.tres", "MireLeech dùng slime_frames")
			_check(_tint_ok(_leech, 0.65, 0.3, 0.25), "MireLeech tint nâu đỏ")
			_check(is_equal_approx(float(_leech.get("sprite_scale")), 1.35), "MireLeech sprite_scale = 1.35")
			_stats(_wisp, "swamp_wisp", "Ma Trơi Đầm Lầy", 45, 18, 135.0, 30, 7, "SwampWisp")
			_check(_frames_path(_wisp) == "res://assets/sprites/slime_frames.tres", "SwampWisp dùng slime_frames")
			_check(is_equal_approx(float(_wisp.get("detect_range")), 300.0), "SwampWisp detect_range = 300")
			var wisp_tint: Color = _wisp.get("sprite_modulate")
			_check(wisp_tint.g > 1.0 and wisp_tint.b > 1.0, "SwampWisp tint xanh lơ phát sáng (modulate > 1): %s" % str(wisp_tint))
			_stats(_cultist, "cultist", "Tín Đồ Giáo Phái", 85, 15, 95.0, 38, 12, "Cultist")
			_check(_frames_path(_cultist) == "res://assets/sprites/goblin_frames.tres", "Cultist dùng goblin_frames")
			_check(_tint_ok(_cultist, 0.45, 0.35, 0.65), "Cultist tint tím than")
			_check(_cultist.has_method("shoot_shadow_bolt"), "Cultist có method bắn shoot_shadow_bolt")
			_check(is_equal_approx(float(_cultist.get("shoot_interval")), 2.2), "Cultist shoot_interval = 2.2s")
			_check(_cultist.get_script().resource_path == "res://enemies/cultist.gd", "Cultist dùng script cultist.gd")
			_stats(_croc, "swamp_croc", "Cá Sấu Đầm", 150, 24, 75.0, 44, 10, "SwampCroc")
			_check(_frames_path(_croc) == "res://assets/sprites/wolf_frames.tres", "SwampCroc dùng wolf_frames")
			_check(_tint_ok(_croc, 0.35, 0.5, 0.3), "SwampCroc tint xanh rêu sẫm")
			_check(is_equal_approx(float(_croc.get("sprite_scale")), 1.25), "SwampCroc sprite_scale = 1.25")
			_check(_croc.get_script().resource_path == "res://enemies/boar.gd", "SwampCroc dùng script húc boar.gd")
			_check(is_equal_approx(float(_croc.get("charge_speed")), 400.0), "SwampCroc charge_speed = 400")
			_stats(_wspider, "water_spider", "Nhện Nước", 65, 13, 115.0, 28, 7, "WaterSpider")
			_check(_frames_path(_wspider) == "res://assets/sprites/spider_frames.tres", "WaterSpider dùng spider_frames")
			_check(_tint_ok(_wspider, 0.4, 0.7, 1.1), "WaterSpider tint xanh nước")
			_check(_wspider.get_script().resource_path == "res://enemies/spider.gd", "WaterSpider dùng script spider.gd")
			# --- Boss: thông số ---
			_stats(_boss, "boss_high_priest", "Đại Tư Tế Morvain", 900, 12, 70.0, 550, 320, "BossHighPriest")
			_check(_frames_path(_boss) == "res://assets/sprites/goblin_frames.tres", "Boss dùng goblin_frames")
			_check(_tint_ok(_boss, 0.5, 0.35, 0.8), "Boss tint tím giáo phái phase 1")
			_check(is_equal_approx(float(_boss.get("sprite_scale")), 1.3), "Boss sprite_scale = 1.3")
			_check(str(_boss.get("key_flag")) == "", "Boss key_flag trống (quest Nam nối sau)")
			_check(int(_boss.get("phase")) == 1, "Boss bắt đầu ở phase 1")
			_check(bool(_boss.get("boss_display_active")), "Boss display active sau _ready")
			_check(str(GameState.boss_name) == "Đại Tư Tế Morvain" and int(GameState.boss_max_hp) == 900,
				"GameState boss display = Đại Tư Tế Morvain/900 (thấy '%s'/%d)" % [str(GameState.boss_name), int(GameState.boss_max_hp)])
			_check(is_equal_approx(float(_boss.call("_current_bolt_cooldown")), 3.0), "Boss phase 1 bolt cooldown = 3.0s")
			_check(int(_boss.call("_current_burst_size")) == 3, "Boss phase 1 loạt = 3 viên")
			_check(is_equal_approx(float(_boss.call("_move_speed")), 70.0), "Boss phase 1 _move_speed = 70")
		6:
			# --- take_damage trừ HP đúng cho mọi loài (đòn nhẹ, chưa chết) ---
			_frog.take_damage(10, Vector2(-100, -1000))
			_check(int(_frog.get("hp")) == 60 and int(_frog.get("state")) != 3, "SwampFrog trúng 10 dmg còn 60 HP")
			_leech.take_damage(10, Vector2(500, -1000))
			_check(int(_leech.get("hp")) == 120, "MireLeech trúng 10 dmg còn 120 HP")
			_wisp.take_damage(10, Vector2(1100, -1000))
			_check(int(_wisp.get("hp")) == 35, "SwampWisp trúng 10 dmg còn 35 HP")
			_cultist.take_damage(10, Vector2(1700, -1000))
			_check(int(_cultist.get("hp")) == 75, "Cultist trúng 10 dmg còn 75 HP")
			_croc.take_damage(10, Vector2(2300, -1000))
			_check(int(_croc.get("hp")) == 140, "SwampCroc trúng 10 dmg còn 140 HP")
			_wspider.take_damage(10, Vector2(2900, -1000))
			_check(int(_wspider.get("hp")) == 55, "WaterSpider trúng 10 dmg còn 55 HP")
			_boss.take_damage(10, Vector2(3900, -1000))
			_check(int(_boss.get("hp")) == 890, "Boss trúng 10 dmg còn 890 HP")
			_check(int(_boss.get("summons_done")) == 0, "Boss 890 HP (>66%) chưa triệu hồi")
		8:
			# --- Cultist bắn Chỉ Ấn qua method công khai ---
			_cultist.call("shoot_shadow_bolt")
			_check(int(_cultist.get("shots_fired")) == 1, "Cultist đã bắn 1 phát (shots_fired = 1)")
			_check(_count_shadow_bolts() >= 1, "Shadow bolt của cultist đã spawn (thấy %d)" % _count_shadow_bolts())
			for child in get_children():
				if child is Area2D and child.get_script() != null \
						and child.get_script().resource_path == "res://enemies/shadow_bolt.gd":
					_check(int(child.get("damage")) == 15, "Bolt của cultist damage = 15 (thấy %d)" % int(child.get("damage")))
					break
		10:
			# --- Boss: qua mốc 66% -> triệu hồi đợt 1; loạt phase 1 = 3 viên ---
			_boss.take_damage(310, Vector2(3900, -1000))
			_check(int(_boss.get("hp")) == 580, "Boss sau tổng 320 dmg còn 580 HP (thấy %d)" % int(_boss.get("hp")))
			_check(int(_boss.get("phase")) == 1, "Boss 580 HP (>50%) vẫn phase 1")
			_check(int(_boss.get("summon_waves_done")) == 1, "Boss <=66% HP -> triệu hồi đợt 1")
			_check(int(_boss.get("summons_done")) == 2, "Đợt 1 = 2 cultist (summons_done = 2)")
			_check(_count_cultists() == 3, "Tổng cultist trong scene = 1 gốc + 2 triệu hồi (thấy %d)" % _count_cultists())
			_boss.call("shoot_bolt_burst")
			_check(int(_boss.get("bolt_count")) == 3, "Boss phase 1 bắn loạt 3 viên (bolt_count = 3)")
			_check(int(_boss.get("bursts_fired")) == 1, "Boss bursts_fired = 1")
		12:
			# --- Boss: xuống dưới 50% -> phase 2 ---
			_boss.take_damage(200, Vector2(3900, -1000))
			_check(int(_boss.get("hp")) == 380, "Boss còn 380 HP (thấy %d)" % int(_boss.get("hp")))
			_check(int(_boss.get("phase")) == 2, "Boss <=50% HP -> phase 2")
			_check(is_equal_approx(float(_boss.call("_move_speed")), 91.0),
				"Boss phase 2 speed x1.3 = 91 (thấy %.1f)" % float(_boss.call("_move_speed")))
			_check(is_equal_approx(float(_boss.call("_current_bolt_cooldown")), 1.8), "Boss phase 2 bolt cooldown = 1.8s")
			_check(int(_boss.call("_current_burst_size")) == 5, "Boss phase 2 loạt = 5 viên")
			_check(_tint_ok(_boss, 0.32, 0.18, 0.5), "Boss phase 2 tint tím đậm")
			_check(int(_boss.get("summons_done")) == 2, "Boss 380 HP (>33%) chưa triệu hồi đợt 2")
			_check(int(GameState.boss_hp) == 380, "Boss display cập nhật HP phase 2 (boss_hp = 380)")
			_boss.call("shoot_bolt_burst")
			_check(int(_boss.get("bolt_count")) == 8, "Boss phase 2 bắn loạt 5 viên (bolt_count = 3+5 = 8)")
		14:
			# --- Boss: qua mốc 33% -> triệu hồi đợt 2 (đợt cuối, hữu hạn) ---
			_boss.take_damage(100, Vector2(3900, -1000))
			_check(int(_boss.get("hp")) == 280, "Boss còn 280 HP (thấy %d)" % int(_boss.get("hp")))
			_check(int(_boss.get("summon_waves_done")) == 2, "Boss <=33% HP -> triệu hồi đợt 2")
			_check(int(_boss.get("summons_done")) == 4, "Tổng triệu hồi = 4 cultist (2 đợt x 2)")
			_check(_count_cultists() == 5, "Tổng cultist trong scene = 1 gốc + 4 triệu hồi (thấy %d)" % _count_cultists())
			_check(int(_boss.call("summon_cultists")) == 0, "Triệu hồi thêm bị chặn: đã hết 2 đợt (hữu hạn)")
			_check(int(_boss.get("summons_done")) == 4, "summons_done vẫn = 4 sau lệnh gọi thừa")
		16:
			# --- Giết ếch: DEAD + gold qua GameState ---
			_gold_before_frog = GameState.gold
			_frog.take_damage(9999, Vector2(-100, -1000))
			_check(int(_frog.get("state")) == 3, "SwampFrog chết -> state DEAD")
			_check(GameState.gold == _gold_before_frog + 6, "SwampFrog chết -> +6 gold (gold=%d)" % GameState.gold)
		18:
			# --- Giết boss: DEAD + clear display + gold ---
			_gold_before_boss = GameState.gold
			_boss.take_damage(9999, Vector2(3900, -1000))
			_check(int(_boss.get("state")) == 3, "Boss chết -> state DEAD")
			_check(not bool(_boss.get("boss_display_active")), "Boss chết -> boss_display_active = false")
			_check(str(GameState.boss_name) == "", "Boss chết -> GameState boss display rỗng")
			_check(GameState.gold == _gold_before_boss + 320, "Boss chết -> +320 gold (gold=%d)" % GameState.gold)
		90:
			_check(not is_instance_valid(_boss) or not _boss.is_inside_tree(), "Boss biến mất sau death animation")
			_check(not is_instance_valid(_frog) or not _frog.is_inside_tree(), "SwampFrog biến mất sau death animation")
			print("[FENMIRETEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
			get_tree().quit(1 if _failures.size() > 0 else 0)
