extends Node
## Test tự động cho HỆ TRANG BỊ (GameState):
##   godot --headless --path game res://tests/equipment_test.tscn
## Kiểm: add_equipment suy slot + tự trang bị khi mạnh hơn hẳn (yếu/bằng
## thì không thay), add giáp, Găng Da Thú (1,1) vào slot weapon,
## equip_item đổi qua lại đổi đúng attack_bonus/defense_bonus suy ra,
## roundtrip to_dict -> reset -> from_dict giữ nguyên items/equipped/tổng,
## DI TRÚ SAVE CŨ (dict không có equipment keys, attack_bonus=7 /
## defense_bonus=5 -> tổng vẫn 7/5, legacy=7/5), reset xoá sạch.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _passes: int = 0
var _failures: Array[String] = []
var _equipment_changed_count: int = 0


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[EQUIPTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[EQUIPTEST] FAIL: ", label)


func _on_equipment_changed() -> void:
	_equipment_changed_count += 1


func _uid_of_last_item() -> String:
	if GameState.equipment_items.is_empty():
		return ""
	return str(GameState.equipment_items[GameState.equipment_items.size() - 1].get("uid", ""))


func _has_item_named(item_name: String) -> bool:
	for raw in GameState.equipment_items:
		if raw is Dictionary and str(raw.get("name", "")) == item_name:
			return true
	return false


func _ready() -> void:
	print("[EQUIPTEST] Bắt đầu test hệ trang bị.")
	GameState.equipment_changed.connect(_on_equipment_changed)
	GameState.reset_game()

	# --- Trạng thái khởi đầu: trống sạch ---
	_check(GameState.equipment_items.is_empty(), "Reset: equipment_items rỗng")
	_check(GameState.get_equipped_item("weapon").is_empty(), "Reset: slot weapon trống")
	_check(GameState.get_equipped_item("armor").is_empty(), "Reset: slot armor trống")
	_check(GameState.attack_bonus == 0 and GameState.defense_bonus == 0,
		"Reset: attack_bonus/defense_bonus = 0")
	_check(GameState.legacy_attack_bonus == 0 and GameState.legacy_defense_bonus == 0,
		"Reset: legacy = 0/0")
	_check(GameState.get_equipment_by_uid("eq_999").is_empty(),
		"get_equipment_by_uid uid lạ -> {}")
	_check(not GameState.equip_item("eq_999"), "equip_item uid lạ -> false")

	# --- Vũ khí yếu -> mạnh: tự trang bị món đầu, tự thay khi mạnh hơn ---
	var signal_before: int = _equipment_changed_count
	GameState.add_equipment("Dao Găm Sắt", 2, 0)
	_check(GameState.equipment_items.size() == 1, "Add Dao Găm Sắt: items = 1")
	_check(_uid_of_last_item() == "eq_1", "Món đầu có uid eq_1 (thấy %s)" % _uid_of_last_item())
	_check(str(GameState.get_equipped_item("weapon").get("name", "")) == "Dao Găm Sắt",
		"Dao Găm Sắt (2/0) -> slot weapon, tự trang bị khi slot trống")
	_check(GameState.attack_bonus == 2 and GameState.defense_bonus == 0,
		"Sau Dao: ATK 2 / DEF 0 (thấy %d/%d)" % [GameState.attack_bonus, GameState.defense_bonus])
	_check(_equipment_changed_count > signal_before, "add_equipment phát signal equipment_changed")

	GameState.add_equipment("Kiếm Ngắn Cũ", 3, 0)
	var kiem_uid: String = _uid_of_last_item()
	_check(str(GameState.get_equipped_item("weapon").get("name", "")) == "Kiếm Ngắn Cũ",
		"Kiếm Ngắn Cũ (3/0) mạnh hơn Dao (2/0) -> tự thay vào slot weapon")
	_check(GameState.attack_bonus == 3 and GameState.defense_bonus == 0,
		"Sau Kiếm: ATK 3 / DEF 0 (không cộng dồn Dao)")

	# Vũ khí yếu hơn rơi sau: vào túi, KHÔNG thay, KHÔNG đổi chỉ số.
	GameState.add_equipment("Dao Găm Sắt", 2, 0)
	_check(GameState.equipment_items.size() == 3, "Add Dao yếu hơn: vẫn vào túi (items = 3)")
	_check(str(GameState.get_equipped_item("weapon").get("uid", "")) == kiem_uid,
		"Dao yếu hơn không chiếm slot weapon")
	_check(GameState.attack_bonus == 3, "Dao yếu hơn không đổi ATK (vẫn 3)")

	# Vũ khí bằng sức mạnh: giữ nguyên món đang mặc (chỉ thay khi mạnh hơn hẳn).
	GameState.add_equipment("Kiếm Sắt Cũ", 3, 0)
	_check(str(GameState.get_equipped_item("weapon").get("uid", "")) == kiem_uid,
		"Kiếm Sắt Cũ (3/0) bằng Kiếm Ngắn Cũ -> giữ nguyên món đang mặc")
	_check(GameState.attack_bonus == 3, "Đồ bằng sức mạnh không đổi ATK (vẫn 3)")

	# --- Giáp: slot armor, cộng DEF, không đụng ATK ---
	GameState.add_equipment("Áo Da Cứng", 0, 2)
	var ao_uid: String = _uid_of_last_item()
	_check(str(GameState.get_equipment_by_uid(ao_uid).get("slot", "")) == "armor",
		"Áo Da Cứng (0/2) -> slot armor")
	_check(str(GameState.get_equipped_item("armor").get("name", "")) == "Áo Da Cứng",
		"Áo Da Cứng tự trang bị vào slot armor trống")
	_check(GameState.attack_bonus == 3 and GameState.defense_bonus == 2,
		"Sau Áo: ATK 3 / DEF 2 (thấy %d/%d)" % [GameState.attack_bonus, GameState.defense_bonus])

	# --- Găng Da Thú (1,1): cả hai > 0, atk >= def -> slot weapon ---
	GameState.add_equipment("Găng Da Thú", 1, 1)
	var gang_uid: String = _uid_of_last_item()
	_check(str(GameState.get_equipment_by_uid(gang_uid).get("slot", "")) == "weapon",
		"Găng Da Thú (1/1) -> slot weapon (atk >= def)")
	_check(str(GameState.get_equipped_item("weapon").get("uid", "")) == kiem_uid,
		"Găng (atk 1) yếu hơn Kiếm (atk 3) -> không tự thay")
	_check(GameState.attack_bonus == 3 and GameState.defense_bonus == 2,
		"Găng trong túi: tổng vẫn ATK 3 / DEF 2")

	# --- equip_item: đổi qua lại thấy tổng đổi đúng ---
	_check(GameState.equip_item(gang_uid), "equip_item(Găng Da Thú) -> true")
	_check(GameState.attack_bonus == 1 and GameState.defense_bonus == 3,
		"Mặc Găng: ATK 1, DEF = giáp 2 + găng 1 = 3 (thấy %d/%d)" % [
			GameState.attack_bonus, GameState.defense_bonus])
	_check(GameState.equip_item(kiem_uid), "equip_item(Kiếm Ngắn Cũ) -> true")
	_check(GameState.attack_bonus == 3 and GameState.defense_bonus == 2,
		"Mặc lại Kiếm: ATK 3 / DEF 2")
	_check(GameState.equip_item(ao_uid), "equip_item(Áo Da Cứng) -> true")
	_check(GameState.attack_bonus == 3 and GameState.defense_bonus == 2,
		"equip lại giáp đang mặc: tổng không đổi")

	# --- Giáp mạnh hơn tự thay; giáp yếu hơn thì không ---
	GameState.add_equipment("Giáp Da Bóng", 0, 4)
	_check(str(GameState.get_equipped_item("armor").get("name", "")) == "Giáp Da Bóng",
		"Giáp Da Bóng (0/4) mạnh hơn Áo (0/2) -> tự thay slot armor")
	_check(GameState.attack_bonus == 3 and GameState.defense_bonus == 4,
		"Sau Giáp Da Bóng: ATK 3 / DEF 4")
	GameState.add_equipment("Áo Da Cứng", 0, 2)
	_check(str(GameState.get_equipped_item("armor").get("name", "")) == "Giáp Da Bóng",
		"Áo yếu hơn rơi sau không chiếm slot armor")
	_check(GameState.defense_bonus == 4, "Áo yếu hơn không đổi DEF (vẫn 4)")

	# --- Save/load roundtrip: items + equipped + tổng giữ nguyên ---
	var items_before: int = GameState.equipment_items.size()
	var weapon_uid_before: String = str(GameState.equipped_uids.get("weapon", ""))
	var armor_uid_before: String = str(GameState.equipped_uids.get("armor", ""))
	var d: Dictionary = GameState.to_dict()
	_check(d.has("equipment_items") and d.has("equipped_uids")
		and d.has("legacy_attack_bonus") and d.has("legacy_defense_bonus")
		and d.has("equipment_counter"),
		"to_dict có đủ keys trang bị mới")
	_check(int(d.get("attack_bonus", -1)) == 3 and int(d.get("defense_bonus", -1)) == 4,
		"to_dict vẫn giữ attack_bonus/defense_bonus đã recalc (3/4)")
	GameState.reset_game()
	_check(GameState.equipment_items.is_empty() and GameState.attack_bonus == 0,
		"Reset giữa roundtrip: sạch đồ, ATK 0")
	GameState.from_dict(d)
	_check(GameState.equipment_items.size() == items_before,
		"Roundtrip: giữ nguyên %d món (thấy %d)" % [items_before, GameState.equipment_items.size()])
	_check(str(GameState.equipped_uids.get("weapon", "")) == weapon_uid_before
		and str(GameState.equipped_uids.get("armor", "")) == armor_uid_before,
		"Roundtrip: equipped_uids giữ nguyên")
	_check(str(GameState.get_equipped_item("weapon").get("name", "")) == "Kiếm Ngắn Cũ"
		and str(GameState.get_equipped_item("armor").get("name", "")) == "Giáp Da Bóng",
		"Roundtrip: món đang mặc giữ nguyên (Kiếm Ngắn Cũ + Giáp Da Bóng)")
	_check(GameState.attack_bonus == 3 and GameState.defense_bonus == 4,
		"Roundtrip: tổng giữ nguyên ATK 3 / DEF 4")
	_check(GameState.legacy_attack_bonus == 0 and GameState.legacy_defense_bonus == 0,
		"Roundtrip: legacy vẫn 0/0 (save mới không bị tính trùng thành legacy)")

	# Counter khôi phục từ save: món nhặt sau load không trùng uid cũ.
	var uids_before: Array = []
	for raw in GameState.equipment_items:
		uids_before.append(str(raw.get("uid", "")))
	GameState.add_equipment("Kiếm Lõi Quái", 6, 0)
	_check(not uids_before.has(_uid_of_last_item()),
		"Sau load, món mới có uid không trùng món cũ (%s)" % _uid_of_last_item())
	_check(GameState.attack_bonus == 6 and GameState.defense_bonus == 4,
		"Kiếm Lõi Quái (+6) tự thay Kiếm Ngắn Cũ: ATK 6 / DEF 4")

	# --- DI TRÚ SAVE CŨ: không có equipment keys, tổng giữ nguyên 100% ---
	var old_save: Dictionary = {
		"player_hp": 80,
		"player_max_hp": 100,
		"gold": 123,
		"attack_bonus": 7,
		"defense_bonus": 5,
	}
	_check(not old_save.has("equipment_items"), "Dict save cũ thật sự không có equipment keys")
	GameState.reset_game()
	GameState.from_dict(old_save)
	_check(GameState.attack_bonus == 7 and GameState.defense_bonus == 5,
		"Di trú save cũ: tổng giữ nguyên ATK 7 / DEF 5 (thấy %d/%d)" % [
			GameState.attack_bonus, GameState.defense_bonus])
	_check(GameState.legacy_attack_bonus == 7 and GameState.legacy_defense_bonus == 5,
		"Di trú save cũ: legacy = 7/5")
	_check(GameState.equipment_items.is_empty(), "Di trú save cũ: danh sách đồ rỗng")
	_check(GameState.get_equipped_item("weapon").is_empty()
		and GameState.get_equipped_item("armor").is_empty(),
		"Di trú save cũ: không món nào đang mặc")
	# Đồ nhặt sau khi di trú cộng lên trên legacy, không ghi đè legacy.
	GameState.add_equipment("Kiếm Ngắn Cũ", 3, 0)
	_check(GameState.attack_bonus == 10 and GameState.defense_bonus == 5,
		"Sau di trú, nhặt Kiếm (+3): ATK = legacy 7 + 3 = 10, DEF vẫn 5")

	# --- Reset xoá sạch tất cả (kể cả legacy + counter) ---
	GameState.reset_game()
	_check(GameState.equipment_items.is_empty(), "Reset cuối: equipment_items rỗng")
	_check(str(GameState.equipped_uids.get("weapon", "")) == ""
		and str(GameState.equipped_uids.get("armor", "")) == "",
		"Reset cuối: equipped_uids về trống")
	_check(GameState.legacy_attack_bonus == 0 and GameState.legacy_defense_bonus == 0,
		"Reset cuối: legacy về 0/0")
	_check(GameState.attack_bonus == 0 and GameState.defense_bonus == 0,
		"Reset cuối: attack_bonus/defense_bonus = 0")
	GameState.add_equipment("Dao Găm Sắt", 2, 0)
	_check(_uid_of_last_item() == "eq_1",
		"Reset cuối: counter về 0, món mới lại là eq_1 (thấy %s)" % _uid_of_last_item())
	_check(_has_item_named("Dao Găm Sắt"), "Danh sách đồ chứa món vừa add theo tên")

	GameState.reset_game()
	print("[EQUIPTEST] Tổng kết: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
