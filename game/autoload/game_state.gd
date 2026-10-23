extends Node
## GameState - Autoload toàn cục
## Giữ trạng thái người chơi: HP, vàng, XP, level, uy tín theo vùng.
## Các hệ thống khác (HUD, Quest, Save) đọc/ghi qua đây.

signal gold_changed(new_gold: int)
signal xp_changed(new_xp: int, new_level: int)
signal level_changed(new_level: int)
signal reputation_changed(region: String, new_value: int)
signal player_hp_changed(new_hp: int, max_hp: int)

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


func _ready() -> void:
	pass


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
	gold_changed.emit(gold)
	xp_changed.emit(xp, level)
	level_changed.emit(level)
	player_hp_changed.emit(player_hp, player_max_hp)
