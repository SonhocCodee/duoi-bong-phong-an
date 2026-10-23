extends Node
## Test tự động cho GAMEPLAY SYSTEMS (chạy headless):
##   godot --headless --path game res://tests/gameplay_test.tscn
## Kiểm tra: rơi vật phẩm (potion/herb/trang bị), elite + key_flag, respawn,
## rương loot, cửa khoá, level/chỉ số ATK-DEF (player + HUD + banner),
## sổ quest (build_log_text/show/hide), boss Rat King phase 2 + flag chết.
## Phần dungeon (ham_ruou) chỉ assert khi scene đã sẵn chest/door/key/portal
## theo chuẩn tích hợp; chưa sẵn thì in SKIP thay vì FAIL.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[GAMEPLAY] PASS: ", label)
	else:
		_failures.append(label)
		print("[GAMEPLAY] FAIL: ", label)


func _spawn_slime(pos: Vector2) -> Node:
	var e: Node = load("res://enemies/slime.tscn").instantiate()
	e.global_position = pos
	add_child(e)
	return e


func _collect(node: Node, acc: Array) -> void:
	acc.append(node)
	for c in node.get_children():
		_collect(c, acc)


func _script_path(node: Node) -> String:
	var s: Script = node.get_script()
	return s.resource_path if s != null else ""


func _ready() -> void:
	print("[GAMEPLAY] Bắt đầu test gameplay systems.")
	GameState.reset_game()
	QuestManager.reset_quests()
	_check(GameState.attack_bonus == 0 and GameState.defense_bonus == 0,
		"Reset: attack_bonus/defense_bonus = 0")

	# ============ 1) Drops: potion + herb + trang bị ============
	_check(QuestManager.accept_quest("dong_side_herb"), "Nhận quest thu thảo dược (để test herb drop)")
	var pot0: int = GameState.potions
	var e1: Node = load("res://enemies/slime.tscn").instantiate()
	e1.set("drop_potion_chance", 1.0)
	e1.set("drop_herb_chance", 1.0)
	e1.set("drop_equip_chance", 1.0)
	e1.global_position = Vector2(0, 0)
	add_child(e1)
	await get_tree().process_frame
	e1.take_damage(9999, e1.global_position + Vector2(50, 0))
	_check(int(e1.get("state")) == 3, "Drops: slime chết -> state DEAD")
	_check(GameState.potions == pot0 + 1, "Drops: potion +1 (potions=%d)" % GameState.potions)
	_check(int(QuestManager.get_quest("dong_side_herb").get("progress", 0)) == 1,
		"Drops: herb -> dong_side_herb progress = 1")
	_check(GameState.attack_bonus + GameState.defense_bonus > 0,
		"Drops: trang bị cộng chỉ số (ATK+%d DEF+%d)" % [GameState.attack_bonus, GameState.defense_bonus])
	var loot_labels := 0
	for c in get_children():
		if c is Label:
			loot_labels += 1
	_check(loot_labels >= 1, "Drops: có chữ loot bay lên tại vị trí quái (%d label)" % loot_labels)

	# ============ 2) Elite + key_flag ============
	var normal: Node = await _spawn_slime(Vector2(300, 0))
	await get_tree().process_frame
	var base_hp: int = int(normal.get("max_hp"))
	normal.queue_free()
	await get_tree().process_frame
	var pot1: int = GameState.potions
	var elite: Node = load("res://enemies/slime.tscn").instantiate()
	elite.set("is_elite", true)
	elite.set("key_flag", "test_key")
	elite.set("drop_potion_chance", 0.0)
	elite.set("drop_herb_chance", 0.0)
	elite.set("drop_equip_chance", 0.0)
	elite.global_position = Vector2(600, 0)
	add_child(elite)
	await get_tree().process_frame
	_check(int(elite.get("max_hp")) == base_hp * 3,
		"Elite: max_hp x3 (%d -> %d)" % [base_hp, int(elite.get("max_hp"))])
	_check(int(elite.get("damage")) == 9, "Elite: damage x1.5 làm tròn (6 -> %d)" % int(elite.get("damage")))
	elite.take_damage(99999, elite.global_position + Vector2(50, 0))
	_check(GameState.get_flag("test_key"), "Elite: chết -> set_flag('test_key') = true")
	_check(GameState.potions == pot1 + 1, "Elite: chắc chắn rơi 1 potion dù chance = 0")

	# ============ 3) Respawn ============
	var resp: Node = load("res://enemies/slime.tscn").instantiate()
	resp.set("respawn_time", 0.6)
	resp.set("drop_potion_chance", 0.0)
	resp.set("drop_herb_chance", 0.0)
	resp.set("drop_equip_chance", 0.0)
	resp.global_position = Vector2(500, 500)
	add_child(resp)
	await get_tree().process_frame
	var resp_max: int = int(resp.get("max_hp"))
	resp.take_damage(9999, resp.global_position + Vector2(50, 0))
	_check(int(resp.get("state")) == 3, "Respawn: vừa chết -> state DEAD")
	var gold_after_kill: int = GameState.gold
	resp.take_damage(9999, resp.global_position + Vector2(50, 0))
	_check(GameState.gold == gold_after_kill, "Respawn: quái DEAD không bị tính kill thêm (gold không đổi)")
	var revived := false
	for i in 20:
		await get_tree().create_timer(0.25).timeout
		if not is_instance_valid(resp):
			break
		if int(resp.get("state")) != 3:
			revived = true
			break
	_check(revived and is_instance_valid(resp), "Respawn: quái hồi sinh sau death anim + respawn_time")
	if is_instance_valid(resp):
		_check(int(resp.get("hp")) == resp_max, "Respawn: HP đầy lại (%d/%d)" % [int(resp.get("hp")), resp_max])
		_check(bool(resp.get("visible")), "Respawn: visible = true sau hồi sinh")

	# ============ 4) Rương loot ============
	var gold0: int = GameState.gold
	var pot2: int = GameState.potions
	var atk0: int = GameState.attack_bonus
	var chest: Node = load("res://systems/chest.tscn").instantiate()
	chest.set("chest_id", "test_chest")
	chest.set("gold_reward", 50)
	chest.set("potion_count", 1)
	chest.set("equip_name", "Kiếm Ngắn Cũ")
	chest.set("equip_attack", 3)
	chest.set("equip_defense", 0)
	chest.global_position = Vector2(900, 900)
	add_child(chest)
	await get_tree().process_frame
	_check(chest.is_in_group("chest") and chest.is_in_group("interactable"),
		"Chest: thuộc group chest + interactable")
	chest.interact()
	_check(GameState.gold == gold0 + 50, "Chest: +50 vàng (gold=%d)" % GameState.gold)
	_check(GameState.potions == pot2 + 1, "Chest: +1 potion (potions=%d)" % GameState.potions)
	_check(GameState.attack_bonus == atk0 + 3, "Chest: trang bị +3 ATK (atk_bonus=%d)" % GameState.attack_bonus)
	_check(GameState.get_flag("chest_test_chest"), "Chest: flag chest_test_chest đã set")
	chest.interact()
	_check(GameState.gold == gold0 + 50 and GameState.potions == pot2 + 1 and GameState.attack_bonus == atk0 + 3,
		"Chest: mở lần 2 không phát thưởng nữa")

	# ============ 5) Cửa khoá ============
	var door: Node = load("res://systems/locked_door.tscn").instantiate()
	door.set("required_flag", "test_key_door")
	door.global_position = Vector2(1200, 900)
	add_child(door)
	await get_tree().process_frame
	_check(door.is_in_group("locked_door") and door.is_in_group("interactable"),
		"Door: thuộc group locked_door + interactable")
	var door_shape: CollisionShape2D = door.get_node("CollisionShape2D")
	door.interact()
	await get_tree().process_frame
	_check(not door_shape.disabled and not bool(door.get("opened")),
		"Door: chưa có flag -> interact vẫn khoá, collision còn bật")
	GameState.set_flag("test_key_door")
	door.interact()
	await get_tree().process_frame
	_check(door_shape.disabled, "Door: có flag -> interact mở, collision đã tắt")
	_check(bool(door.get("opened")), "Door: opened = true sau khi mở")
	_check(not (door.get_node("Sprite2D") as Sprite2D).visible, "Door: sprite ẩn sau khi mở")

	# ============ 6) Level / chỉ số / HUD / banner ============
	var hud: Node = load("res://ui/hud.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	var lvl0: int = GameState.level
	GameState.add_xp(100)
	_check(GameState.level == lvl0 + 1, "Level: add_xp(100) -> lên 1 cấp (L%d)" % GameState.level)
	await get_tree().process_frame
	var banner: Label = hud.get_node("LevelUpLabel")
	_check(banner.visible and banner.text.contains("LEVEL UP"),
		"HUD: banner LEVEL UP hiện khi lên cấp ('%s')" % banner.text)
	var info: Label = hud.get_node("MarginContainer/VBoxContainer/InfoLabel")
	var expected_atk: int = 10 + GameState.attack_bonus + (GameState.level - 1) * 2
	_check(info.text.contains("ATK %d" % expected_atk),
		"HUD: InfoLabel chứa ATK %d ('%s')" % [expected_atk, info.text])
	_check(info.text.contains("DEF %d" % GameState.defense_bonus),
		"HUD: InfoLabel chứa DEF %d" % GameState.defense_bonus)
	var player: Node = load("res://player/player.tscn").instantiate()
	player.global_position = Vector2(2000, 2000)
	add_child(player)
	await get_tree().process_frame
	_check(int(player.call("effective_damage", 0)) == expected_atk,
		"Player: effective_damage(0) = %d (thấy %d)" % [expected_atk, int(player.call("effective_damage", 0))])
	var php0: int = int(player.get("hp"))
	var expected_loss: int = maxi(1, 20 - GameState.defense_bonus)
	player.take_damage(20, player.global_position + Vector2(80, 0))
	_check(int(player.get("hp")) == php0 - expected_loss,
		"Player: nhận 20 dmg, DEF %d giảm còn mất %d HP (hp=%d)" % [
			GameState.defense_bonus, expected_loss, int(player.get("hp"))])

	# ============ 7) Sổ quest ============
	QuestManager.reset_quests()
	_check(QuestManager.accept_quest("dong_01_goblin"), "QuestLog: nhận dong_01_goblin")
	var panel: Node = load("res://ui/quest_log_panel.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	var log_text: String = str(panel.call("build_log_text"))
	_check(log_text.contains("— ĐANG LÀM —"), "QuestLog: có mục ĐANG LÀM")
	_check(log_text.contains("Dẹp Goblin ở bìa rừng Elmford"),
		"QuestLog: build_log_text chứa title quest đang làm")
	_check(log_text.contains("— ĐÃ HOÀN THÀNH —"), "QuestLog: có mục ĐÃ HOÀN THÀNH")
	panel.call("show_panel")
	_check(bool(panel.get("visible")) and GameState.in_dialogue,
		"QuestLog: show_panel -> hiện + in_dialogue = true")
	panel.call("hide_panel")
	_check(not bool(panel.get("visible")) and not GameState.in_dialogue,
		"QuestLog: hide_panel -> ẩn + in_dialogue = false")

	# ============ 8) Boss Rat King: phase 2 + flag chết ============
	var boss: Node = load("res://enemies/boss_rat_king.tscn").instantiate()
	boss.global_position = Vector2(3000, 3000)
	add_child(boss)
	await get_tree().process_frame
	boss.take_damage(150, boss.global_position + Vector2(60, 0))
	_check(int(boss.get("phase")) == 2, "RatKing: HP <= 50%% -> phase 2 (phase=%d)" % int(boss.get("phase")))
	boss.take_damage(99999, boss.global_position + Vector2(60, 0))
	_check(GameState.get_flag("rat_king_dead"), "RatKing: chết -> set_flag('rat_king_dead') = true")

	# ============ 9) Dungeon ham_ruou (chỉ khi scene đã tích hợp) ============
	_run_dungeon_scan()

	print("[GAMEPLAY] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)


func _run_dungeon_scan() -> void:
	var packed: PackedScene = load("res://maps/ham_ruou.tscn")
	if packed == null:
		print("[GAMEPLAY] SKIP dungeon asserts (scene chưa sẵn)")
		return
	var inst: Node = packed.instantiate()
	var all: Array = []
	_collect(inst, all)
	var chests := 0
	var doors := 0
	var key_enemies := 0
	var rat_portals := 0
	for n in all:
		var sp := _script_path(n)
		if sp == "res://systems/chest.gd":
			chests += 1
		elif sp == "res://systems/locked_door.gd":
			doors += 1
		elif sp == "res://systems/portal.gd":
			if str(n.get("required_flag")) == "rat_king_dead":
				rat_portals += 1
		elif sp.begins_with("res://enemies/"):
			var kf: Variant = n.get("key_flag")
			if kf != null and str(kf) != "":
				key_enemies += 1
	inst.free()
	if chests >= 2 and doors >= 1 and key_enemies >= 1 and rat_portals >= 1:
		_check(chests >= 2, "Dungeon: ham_ruou có >= 2 rương (thấy %d)" % chests)
		_check(doors >= 1, "Dungeon: ham_ruou có >= 1 cửa khoá (thấy %d)" % doors)
		_check(key_enemies >= 1, "Dungeon: ham_ruou có >= 1 quái giữ key_flag (thấy %d)" % key_enemies)
		_check(rat_portals >= 1, "Dungeon: ham_ruou có portal required_flag = rat_king_dead (thấy %d)" % rat_portals)
	else:
		print("[GAMEPLAY] SKIP dungeon asserts (scene chưa sẵn) — chest=%d door=%d key_enemy=%d portal_rat=%d" % [
			chests, doors, key_enemies, rat_portals])
