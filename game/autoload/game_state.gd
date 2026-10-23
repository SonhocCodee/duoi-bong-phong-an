extends Node
## GameState - Autoload toàn cục
## Giữ trạng thái người chơi: HP, vàng, XP, level, uy tín theo vùng.
## Các hệ thống khác (HUD, Quest, Save) đọc/ghi qua đây.

signal gold_changed(new_gold: int)
signal xp_changed(new_xp: int, new_level: int)
signal level_changed(new_level: int)
signal reputation_changed(region: String, new_value: int)
signal player_hp_changed(new_hp: int, max_hp: int)
signal part1_completed
signal potions_changed(new_count: int)
signal boss_changed(display_name: String, hp: int, max_hp: int)
signal stats_changed(attack_bonus: int, defense_bonus: int)

var player_hp: int = 100
var player_max_hp: int = 100
var gold: int = 0
var xp: int = 0
var level: int = 1
var xp_to_next_level: int = 100

# Uy tín theo 4 vùng: dong (Đông), nam (Nam), tay (Tây), bac (Bắc)
var reputation: Dictionary = {
	"dong": 0,
	"nam": 0,
	"tay": 0,
	"bac": 0,
}

var current_region: String = "dong"

# --- Giai đoạn 1 (Vertical Slice Đông) ---
var potions: int = 3 # Bình máu (dùng bằng phím H, hồi 50 HP — xử lý ở player.gd)
# Chìa khóa phong ấn 4 vùng: lấy đủ 4 mới vào được tầng vua ở Sigilspire
var seal_keys: Dictionary = {"dong": false, "nam": false, "tay": false, "bac": false}
# Cờ sự kiện tự do cho portal / quest / cốt truyện: set_flag / get_flag
var flags: Dictionary = {}
# Hiển thị thanh máu boss trên HUD (boss set khi vào trận, clear khi xong)
var boss_name: String = ""
var boss_hp: int = 0
var boss_max_hp: int = 0
# Điểm spawn + map hiện tại (portal ghi, map_root đọc lúc vào map, save/load giữ lại)
var spawn_point: String = "start"
var current_map: String = ""
# Đang mở hộp thoại / shop: player.gd kiểm tra cờ này để khóa di chuyển
var in_dialogue: bool = false
# --- Chỉ số trang bị (cộng dồn từ add_equipment: rơi từ quái / rương) ---
var attack_bonus: int = 0
var defense_bonus: int = 0


func _ready() -> void:
	pass


## Reset toàn bộ trạng thái về mặc định ban đầu (dùng cho "Chơi mới" ở main menu).
func reset_game() -> void:
	player_hp = 100
	player_max_hp = 100
	gold = 0
	xp = 0
	level = 1
	xp_to_next_level = 100
	reputation = {
		"dong": 0,
		"nam": 0,
		"tay": 0,
		"bac": 0,
	}
	current_region = "dong"
	potions = 3
	seal_keys = {"dong": false, "nam": false, "tay": false, "bac": false}
	flags = {}
	boss_name = ""
	boss_hp = 0
	boss_max_hp = 0
	spawn_point = "start"
	current_map = ""
	in_dialogue = false
	attack_bonus = 0
	defense_bonus = 0
	stats_changed.emit(attack_bonus, defense_bonus)
	gold_changed.emit(gold)
	xp_changed.emit(xp, level)
	level_changed.emit(level)
	player_hp_changed.emit(player_hp, player_max_hp)
	potions_changed.emit(potions)
	boss_changed.emit(boss_name, boss_hp, boss_max_hp)
	print("[GameState] Đã reset game về trạng thái ban đầu.")


func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	gold_changed.emit(gold)


func add_xp(amount: int) -> void:
	xp += amount
	# Kiểm tra lên cấp (có thể lên nhiều cấp)
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = int(xp_to_next_level * 1.5)
		player_max_hp += 10
		player_hp = player_max_hp
		level_changed.emit(level)
		player_hp_changed.emit(player_hp, player_max_hp)
		print("[GameState] Lên cấp! Level = ", level)
	xp_changed.emit(xp, level)


func set_player_hp(value: int, max_value: int) -> void:
	player_max_hp = max_value
	player_hp = clampi(value, 0, player_max_hp)
	player_hp_changed.emit(player_hp, player_max_hp)


func add_reputation(region: String, amount: int) -> void:
	if not reputation.has(region):
		reputation[region] = 0
	reputation[region] = int(reputation[region]) + amount
	reputation_changed.emit(region, int(reputation[region]))
	print("[GameState] Uy tín vùng '%s' = %d" % [region, reputation[region]])


func get_reputation(region: String) -> int:
	return int(reputation.get(region, 0))


# --- Trang bị / chỉ số -----------------------------------------------------

## Cộng dồn chỉ số từ một món trang bị (rơi từ quái hoặc mở rương).
## name chỉ để log/hiển thị; chỉ số cộng thẳng vào attack_bonus/defense_bonus.
func add_equipment(equip_name: String, atk: int, def: int) -> void:
	attack_bonus += atk
	defense_bonus += def
	stats_changed.emit(attack_bonus, defense_bonus)
	print("[GameState] Nhận trang bị '%s' (+%d ATK, +%d DEF) -> ATK bonus %d, DEF bonus %d" % [
		equip_name, atk, def, attack_bonus, defense_bonus])


# --- Bình máu ------------------------------------------------------------

func add_potions(amount: int) -> void:
	potions = max(0, potions + amount)
	potions_changed.emit(potions)


# Trừ 1 bình nếu còn. Trả false khi hết bình (không trừ).
func use_potion() -> bool:
	if potions <= 0:
		return false
	potions -= 1
	potions_changed.emit(potions)
	return true


# --- Chìa khóa phong ấn ----------------------------------------------------

func add_seal_key(region: String) -> void:
	seal_keys[region] = true
	print("[GameState] Nhận chìa phong ấn vùng '%s' (%d/4)" % [region, seal_keys.values().count(true)])


func has_all_seal_keys() -> bool:
	for region in ["dong", "nam", "tay", "bac"]:
		if not bool(seal_keys.get(region, false)):
			return false
	return true


# --- Cờ sự kiện --------------------------------------------------------------

func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value
	if key == "dong_giai_phong" and value:
		part1_completed.emit()


func get_flag(key: String) -> bool:
	return bool(flags.get(key, false))


# --- Thanh máu boss (HUD) -----------------------------------------------------

func set_boss_display(p_name: String, hp: int, max_hp: int) -> void:
	boss_name = p_name
	boss_max_hp = max(0, max_hp)
	boss_hp = clampi(hp, 0, boss_max_hp)
	boss_changed.emit(boss_name, boss_hp, boss_max_hp)


func clear_boss_display() -> void:
	boss_name = ""
	boss_hp = 0
	boss_max_hp = 0
	boss_changed.emit(boss_name, boss_hp, boss_max_hp)


func to_dict() -> Dictionary:
	return {
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"gold": gold,
		"xp": xp,
		"level": level,
		"xp_to_next_level": xp_to_next_level,
		"reputation": reputation.duplicate(),
		"current_region": current_region,
		"potions": potions,
		"seal_keys": seal_keys.duplicate(),
		"flags": flags.duplicate(true),
		"spawn_point": spawn_point,
		"current_map": current_map,
		"attack_bonus": attack_bonus,
		"defense_bonus": defense_bonus,
	}


func from_dict(data: Dictionary) -> void:
	player_hp = int(data.get("player_hp", 100))
	player_max_hp = int(data.get("player_max_hp", 100))
	gold = int(data.get("gold", 0))
	xp = int(data.get("xp", 0))
	level = int(data.get("level", 1))
	xp_to_next_level = int(data.get("xp_to_next_level", 100))
	if data.has("reputation") and data["reputation"] is Dictionary:
		reputation = data["reputation"].duplicate()
	current_region = str(data.get("current_region", "dong"))
	potions = int(data.get("potions", 3))
	if data.has("seal_keys") and data["seal_keys"] is Dictionary:
		seal_keys = data["seal_keys"].duplicate()
	if data.has("flags") and data["flags"] is Dictionary:
		flags = data["flags"].duplicate(true)
	spawn_point = str(data.get("spawn_point", "start"))
	current_map = str(data.get("current_map", ""))
	attack_bonus = int(data.get("attack_bonus", 0))
	defense_bonus = int(data.get("defense_bonus", 0))
	stats_changed.emit(attack_bonus, defense_bonus)
	clear_boss_display()
	gold_changed.emit(gold)
	potions_changed.emit(potions)
	xp_changed.emit(xp, level)
	level_changed.emit(level)
	player_hp_changed.emit(player_hp, player_max_hp)
