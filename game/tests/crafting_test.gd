extends Node
## Test tự động cho CRAFTING CƠ BẢN (đợt 6):
##   godot --headless --path game res://tests/crafting_test.tscn
## Kiểm: kho nguyên liệu add/get, can_afford/spend, 4 công thức
## (bình máu từ thảo, đại bình hồi phục, kiếm lõi quái +6 ATK 1 lần,
## giáp da bóng +4 DEF 1 lần), herb pickup cộng kho thật, save/load
## roundtrip materials + greater_potions + trạng thái hoàn thành game,
## và node CraftStation có mặt ở 5 hub.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[CRAFTTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[CRAFTTEST] FAIL: ", label)


func _count_craft_stations(node: Node) -> int:
	# Đếm qua export station_name (group "craft_station" chỉ được add
	# trong _ready — map ở đây chỉ instantiate để kiểm, chưa vào tree).
	var n := 0
	if node.get("station_name") != null:
		n += 1
	for child in node.get_children():
		n += _count_craft_stations(child)
	return n


func _check_hub(map_path: String, label: String) -> void:
	var ps: PackedScene = load(map_path)
	_check(ps != null, "Load được %s" % map_path)
	if ps == null:
		return
	var map: Node = ps.instantiate()
	_check(_count_craft_stations(map) >= 1, "%s có ít nhất 1 CraftStation" % label)
	map.free()


func _ready() -> void:
	print("[CRAFTTEST] Bắt đầu test crafting cơ bản.")
	GameState.reset_game()
	QuestManager.reset_quests()

	# --- Kho nguyên liệu ---
	_check(GameState.get_material("herb") == 0, "Kho khởi đầu: 0 thảo")
	GameState.add_material("herb", 3)
	GameState.add_material("monster_core", 2)
	_check(GameState.get_material("herb") == 3, "add_material herb +3")
	_check(GameState.get_material("monster_core") == 2, "add_material monster_core +2")
	_check(GameState.can_afford_cost({"herb": 2}), "can_afford herb x2: đủ")
	_check(not GameState.can_afford_cost({"herb": 9}), "can_afford herb x9: thiếu")
	_check(not GameState.spend_cost({"monster_core": 5}), "spend vượt số có: false, không trừ")
	_check(GameState.get_material("monster_core") == 2, "Sau spend fail: core giữ nguyên")

	# --- Công thức 1: bình máu từ thảo ---
	var potions0: int = GameState.potions
	# herb đang có 3 -> chế được 1 bình (tốn 2), còn 1 thì không chế nổi nữa
	_check(GameState.craft("binh_mau_tu_thao"), "Chế Bình Máu Từ Thảo (herb x2)")
	_check(GameState.potions == potions0 + 1, "Bình máu +1 sau chế")
	_check(GameState.get_material("herb") == 1, "Herb trừ đúng 2 (còn 1)")
	_check(not GameState.craft("binh_mau_tu_thao"), "Thiếu herb: chế bình máu fail")

	# --- Công thức 2: đại bình hồi phục ---
	GameState.add_material("herb", 3) # herb: 4
	GameState.add_gold(100)
	var greater0: int = GameState.greater_potions
	_check(GameState.craft("dai_binh_hoi_phuc"), "Chế Đại Bình Hồi Phục (herb x3 + core x1 + 15 vàng)")
	_check(GameState.greater_potions == greater0 + 1, "Đại bình +1")
	_check(GameState.get_material("herb") == 1 and GameState.get_material("monster_core") == 1,
		"Trừ đúng herb/core cho đại bình")
	_check(GameState.gold == 85, "Trừ đúng 15 vàng (còn %d)" % GameState.gold)
	_check(GameState.use_greater_potion(), "Dùng được đại bình vừa chế")
	_check(GameState.greater_potions == greater0, "Đại bình trừ 1 sau khi dùng")

	# --- Công thức 3: kiếm lõi quái (+6 ATK, duy nhất 1 lần) ---
	GameState.add_material("monster_core", 6) # core: 7
	GameState.add_gold(200)
	var atk0: int = GameState.attack_bonus
	_check(GameState.craft("kiem_loi_quai"), "Chế Kiếm Lõi Quái (core x6 + 150 vàng)")
	_check(GameState.attack_bonus == atk0 + 6, "ATK +6 sau khi chế kiếm")
	_check(not GameState.craft("kiem_loi_quai"), "Kiếm Lõi Quái chỉ chế được 1 lần")

	# --- Công thức 4: giáp da bóng (+4 DEF, duy nhất 1 lần) ---
	GameState.add_material("monster_core", 4)
	GameState.add_material("herb", 2)
	GameState.add_gold(200)
	var def0: int = GameState.defense_bonus
	_check(GameState.craft("giap_da_bong"), "Chế Giáp Da Bóng (core x4 + herb x2 + 100 vàng)")
	_check(GameState.defense_bonus == def0 + 4, "DEF +4 sau khi chế giáp")
	_check(not GameState.can_craft("giap_da_bong"), "can_craft giáp = false sau khi đã chế")

	# --- Herb pickup cộng kho nguyên liệu thật ---
	var player: Node = load("res://player/player.tscn").instantiate()
	player.global_position = Vector2(0, 0)
	add_child(player)
	await get_tree().process_frame
	var herb_before: int = GameState.get_material("herb")
	var pickup: Node = load("res://systems/herb_pickup.tscn").instantiate()
	pickup.global_position = Vector2(30, 0)
	add_child(pickup)
	await get_tree().process_frame
	pickup.call("_on_body_entered", player)
	_check(GameState.get_material("herb") == herb_before + 1,
		"Nhặt herb ngoài map: kho nguyên liệu +1")
	player.queue_free()

	# --- Save/load roundtrip ---
	GameState.set_flag("ending_pha_an")
	_check(GameState.game_completed, "set_flag ending_* chốt game_completed")
	var d: Dictionary = GameState.to_dict()
	GameState.reset_game()
	_check(GameState.get_material("herb") == 0 and not GameState.game_completed,
		"Reset: materials rỗng + chưa hoàn thành")
	GameState.from_dict(d)
	_check(GameState.get_material("herb") == int(d["materials"].get("herb", -1)),
		"from_dict khôi phục materials")
	_check(GameState.greater_potions == int(d.get("greater_potions", -1)),
		"from_dict khôi phục greater_potions")
	_check(GameState.game_completed and GameState.ending_id == "ending_pha_an",
		"from_dict khôi phục trạng thái hoàn thành + ending_id")

	# --- CraftStation ở các hub ---
	_check_hub("res://maps/lang_tan_diep.tscn", "Elmford")
	_check_hub("res://maps/reedmere.tscn", "Reedmere")
	_check_hub("res://maps/sunwell_oasis.tscn", "Sunwell Oasis")
	_check_hub("res://maps/hearthwick.tscn", "Hearthwick")
	_check_hub("res://maps/dat_chet.tscn", "Trạm Gác Tro (Đất Chết)")

	print("[CRAFTTEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
