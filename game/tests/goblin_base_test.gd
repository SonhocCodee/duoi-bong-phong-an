extends Node
## Test tự động cho GOBLIN SAU REFACTOR về enemy_base (chạy headless):
##   godot --headless --path game res://tests/goblin_base_test.tscn
## Kiểm tra:
##  (0) Chỉ số gốc giữ nguyên + enemy_type/sprite_frames qua cơ chế base.
##  (a) is_elite=true đặt TRƯỚC add_child -> max_hp = 90 (30 x 3).
##  (b) respawn_time=0.6 -> giết bằng take_damage -> hồi sinh HP đầy + visible.
##  (c) Giết goblin khi đang giữ quest dong_01_goblin -> progress = 1
##      (base gọi QuestManager.on_enemy_killed("goblin")).
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[GOBLINBASE] PASS: ", label)
	else:
		_failures.append(label)
		print("[GOBLINBASE] FAIL: ", label)


func _spawn_goblin(pos: Vector2) -> Node:
	var e: Node = load("res://enemies/goblin.tscn").instantiate()
	e.global_position = pos
	add_child(e)
	return e


func _ready() -> void:
	print("[GOBLINBASE] Bắt đầu test goblin trên enemy_base.")
	GameState.reset_game()
	QuestManager.reset_quests()

	# ============ 0) Chỉ số gốc + hợp đồng base ============
	var g: Node = await _spawn_goblin(Vector2(0, 0))
	await get_tree().process_frame
	_check(str(g.get("enemy_type")) == "goblin", "enemy_type = goblin")
	_check(str(g.get("display_name")) == "Goblin", "display_name = Goblin")
	_check(int(g.get("max_hp")) == 30 and int(g.get("hp")) == 30, "HP = 30")
	_check(is_equal_approx(float(g.get("speed")), 110.0), "speed = 110")
	_check(int(g.get("damage")) == 8, "damage = 8")
	_check(is_equal_approx(float(g.get("detect_range")), 220.0), "detect_range = 220")
	_check(is_equal_approx(float(g.get("attack_range")), 42.0), "attack_range = 42")
	_check(is_equal_approx(float(g.get("attack_cooldown_time")), 1.0), "attack_cooldown_time = 1.0")
	_check(int(g.get("xp_reward")) == 15 and int(g.get("gold_reward")) == 5, "xp/gold = 15/5")
	_check(is_equal_approx(float(g.get("death_anim_duration")), 0.6), "death_anim_duration = 0.6")
	_check(g.is_in_group("enemy"), "Ở group enemy")
	var frames: Resource = g.get("sprite_frames")
	_check(frames != null and frames.resource_path == "res://assets/sprites/goblin_frames.tres",
		"sprite_frames = goblin_frames.tres qua export của base")
	var spr: AnimatedSprite2D = g.get_node("Sprite") if g.has_node("Sprite") else g.get_node("AnimatedSprite2D")
	_check(spr != null and spr.sprite_frames != null and spr.sprite_frames.has_animation(&"death"),
		"Sprite có SpriteFrames + animation death")
	# Các export mới của base phải tồn tại trên goblin (bản cũ bị rớt)
	_check(g.get("respawn_time") != null and g.get("is_elite") != null
		and g.get("drop_potion_chance") != null and g.get("key_flag") != null,
		"Có đủ export base: respawn_time/is_elite/drop_*/key_flag")
	g.queue_free()
	await get_tree().process_frame

	# ============ a) Elite: set is_elite TRƯỚC add_child ============
	var elite: Node = load("res://enemies/goblin.tscn").instantiate()
	elite.set("is_elite", true)
	elite.global_position = Vector2(400, 0)
	add_child(elite)
	await get_tree().process_frame
	_check(int(elite.get("max_hp")) == 90, "Elite: max_hp = 90 (30 x 3, thấy %d)" % int(elite.get("max_hp")))
	_check(int(elite.get("hp")) == 90, "Elite: hp đầy 90 sau _ready")
	_check(int(elite.get("damage")) == 12, "Elite: damage = 12 (8 x 1.5, thấy %d)" % int(elite.get("damage")))
	elite.queue_free()
	await get_tree().process_frame

	# ============ b) Respawn: respawn_time=0.6, giết -> sống lại ============
	var resp: Node = load("res://enemies/goblin.tscn").instantiate()
	resp.set("respawn_time", 0.6)
	resp.set("drop_potion_chance", 0.0)
	resp.set("drop_herb_chance", 0.0)
	resp.set("drop_equip_chance", 0.0)
	resp.global_position = Vector2(800, 0)
	add_child(resp)
	await get_tree().process_frame
	var resp_max: int = int(resp.get("max_hp"))
	resp.take_damage(9999, resp.global_position + Vector2(50, 0))
	_check(int(resp.get("state")) == 3, "Respawn: vừa chết -> state DEAD")
	# death anim 0.6s + respawn_time 0.6s ~= 1.2s; poll tối đa 4s cho chắc
	var revived := false
	for i in 16:
		await get_tree().create_timer(0.25).timeout
		if not is_instance_valid(resp):
			break
		if int(resp.get("state")) != 3:
			revived = true
			break
	_check(revived and is_instance_valid(resp), "Respawn: goblin hồi sinh sau death anim + respawn_time")
	if is_instance_valid(resp):
		_check(int(resp.get("hp")) == resp_max, "Respawn: HP đầy lại (%d/%d)" % [int(resp.get("hp")), resp_max])
		_check(bool(resp.get("visible")), "Respawn: visible = true sau hồi sinh")
		resp.queue_free()
		await get_tree().process_frame

	# ============ c) Quest dong_01_goblin đếm kill qua base ============
	QuestManager.reset_quests()
	_check(QuestManager.accept_quest("dong_01_goblin"), "Nhận dong_01_goblin")
	var victim: Node = await _spawn_goblin(Vector2(1200, 0))
	await get_tree().process_frame
	victim.set("drop_potion_chance", 0.0)
	victim.set("drop_herb_chance", 0.0)
	victim.set("drop_equip_chance", 0.0)
	victim.take_damage(9999, victim.global_position + Vector2(50, 0))
	await get_tree().process_frame
	_check(int(victim.get("state")) == 3, "Quest: goblin chết -> state DEAD")
	_check(int(QuestManager.get_quest("dong_01_goblin").get("progress", 0)) == 1,
		"Quest: dong_01_goblin progress = 1 sau 1 kill (thấy %d)" % int(QuestManager.get_quest("dong_01_goblin").get("progress", 0)))

	print("[GOBLINBASE] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
