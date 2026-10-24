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
signal part2_completed
signal part3_completed
signal part4_completed
signal potions_changed(new_count: int)
signal boss_changed(display_name: String, hp: int, max_hp: int)
signal stats_changed(attack_bonus: int, defense_bonus: int)
signal appearance_changed(has_armor: bool)
signal equipment_changed
signal skills_changed(skill_points: int, unlocked_skills: Array)
signal materials_changed(materials: Dictionary)
signal ending_chosen(ending_id: String)

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
# --- Trang bị ---------------------------------------------------------------
# Hệ trang bị thật: người chơi SỞ HỮU danh sách món (equipment_items) và
# MẶC tối đa 1 món / slot ("weapon" / "armor") qua equipped_uids.
# attack_bonus / defense_bonus GIỮ NGUYÊN là biến công khai (player.gd,
# hud.gd và các test đọc trực tiếp) nhưng từ nay là GIÁ TRỊ SUY RA, chỉ
# _recalc_equipment_bonus() mới được ghi:
#   attack_bonus  = legacy_attack_bonus  + tổng atk của 2 món đang mặc
#   defense_bonus = legacy_defense_bonus + tổng def của 2 món đang mặc
# legacy_*: phần chỉ số "trần" di trú từ save cũ (bản xương cộng dồn thẳng,
# không có danh sách đồ) — xem from_dict(). Game mới luôn có legacy = 0.
# CÂN BẰNG: đồ chế/rương chủ chốt (Kiếm Lõi Quái +6 ATK, Giáp Da Bóng
# +4 DEF, Kiếm Sắt Cũ +3 ATK) luôn là món mạnh nhất trong slot của chúng
# tính tới mốc nhận được, nên tổng chỉ số ở các mốc chính KHÔNG đổi so với
# bản cũ. Khác biệt duy nhất: đồ rác rơi ngẫu nhiên trùng slot mà yếu hơn
# món đang mặc không còn cộng dồn vô hạn như bản xương cũ (trước đây farm
# quái thường cộng ATK không giới hạn — đó là hệ quả của bản khung chưa có
# hệ trang bị, không phải thiết kế cân bằng).
var attack_bonus: int = 0
var defense_bonus: int = 0
var equipment_items: Array = [] # Array[Dictionary]: {"uid": String, "name": String, "slot": "weapon"|"armor", "atk": int, "def": int}
var equipped_uids: Dictionary = {"weapon": "", "armor": ""}
var legacy_attack_bonus: int = 0
var legacy_defense_bonus: int = 0
var _equipment_counter: int = 0
# Ngoại hình player ("lính đánh thuê trắng tay"): mặc ÁO VẢI lúc khởi đầu,
# chuyển sang bộ GIÁP hiệp sĩ khi đang MẶC một món ở slot "armor".
# Đây là giá trị SUY RA — _recalc_equipment_bonus() đồng bộ nó (và phát
# appearance_changed) tại mọi điểm trang bị thay đổi; player.gd nghe
# signal đó để hoán đổi SpriteFrames áo vải <-> giáp.
var has_armor_visual: bool = false
# --- Skill (GDD v2 mục 5.1): mỗi level +1 điểm skill ---
var skill_points: int = 0
var unlocked_skills: Array = [] # Array[String] id skill đã mở, vd "chem_xoay"
# --- Crafting / nguyên liệu (Đợt 6, mức cơ bản theo GDD) ---
# herb: nhặt từ HerbPickup + rơi từ quái (drop herb cũ nay cộng kho thật);
# monster_core ("Lõi Quái"): rơi từ quái (25%, elite chắc chắn rơi).
var materials: Dictionary = {"herb": 0, "monster_core": 0}
# Đại Bình Hồi Phục: chỉ có được bằng chế tạo, hồi 150 HP (phím H dùng
# trước bình thường khi máu hụt >= 90 — xem player.gd _try_use_potion).
var greater_potions: int = 0
# --- Kết game (Đợt 6): set khi người chơi chọn ending ở Bệ Phong Ấn ---
var game_completed: bool = false
var ending_id: String = "" # "ending_phong_an_moi" | "ending_pha_an" | "ending_thay_the"

# Định nghĩa skill (nguồn số liệu duy nhất cho player/panel/test).
# Nhánh Thuật Đen mở sau Phần 2: mọi skill có required_flag="nam_giai_phong"
# đều bị try_unlock_skill chặn cho tới khi người chơi thực sự xong Fenmire.
# Nhánh Pháp Sư mở sau Phần 3 (required_flag="tay_giai_phong", đợt 5) — cùng
# khuôn tiến trình: mỗi phần game mở thêm một nhánh, cấp yêu cầu 13/15/17
# khớp dải cấp Phần 3-4 mà người chơi đạt được khi tới lượt nhánh này.
const SKILL_DEFS: Dictionary = {
	"chem_xoay": {"name": "Chém Xoáy", "branch": "warrior", "required_level": 1, "point_cost": 1, "stamina_cost": 25.0, "cooldown": 6.0},
	"xung_kich": {"name": "Xung Kích", "branch": "warrior", "required_level": 2, "point_cost": 1, "stamina_cost": 20.0, "cooldown": 5.0},
	"cuong_no": {"name": "Cuồng Nộ", "branch": "warrior", "required_level": 4, "point_cost": 1, "stamina_cost": 0.0, "cooldown": 45.0},
	"dau_an_lua": {"name": "Dấu Ấn Lửa", "branch": "dark", "required_level": 7, "required_flag": "nam_giai_phong", "point_cost": 1, "stamina_cost": 20.0, "cooldown": 8.0, "damage_mult": 1.5, "delay": 1.2, "radius": 96.0},
	"bay_hon": {"name": "Bẫy Hồn", "branch": "dark", "required_level": 9, "required_flag": "nam_giai_phong", "point_cost": 1, "stamina_cost": 15.0, "cooldown": 12.0, "radius": 56.0, "lifetime": 20.0, "slow_factor": 0.5, "slow_duration": 3.0, "stun_duration": 1.0},
	"hut_sinh_luc": {"name": "Hút Sinh Lực", "branch": "dark", "required_level": 11, "required_flag": "nam_giai_phong", "point_cost": 1, "stamina_cost": 25.0, "cooldown": 10.0, "damage_mult": 1.2, "lifesteal_ratio": 0.4, "range": 280.0},
	"cau_lua": {"name": "Cầu Lửa", "branch": "mage", "required_level": 13, "required_flag": "tay_giai_phong", "point_cost": 1, "stamina_cost": 25.0, "cooldown": 9.0, "damage_mult": 1.6, "radius": 110.0, "range": 560.0, "projectile_speed": 520.0},
	"gai_bang": {"name": "Gai Băng", "branch": "mage", "required_level": 15, "required_flag": "tay_giai_phong", "point_cost": 1, "stamina_cost": 20.0, "cooldown": 11.0, "damage_mult": 1.1, "radius": 120.0, "range": 340.0, "slow_factor": 0.4, "slow_duration": 3.0, "stun_duration": 0.8},
	"set_lan": {"name": "Sét Lan", "branch": "mage", "required_level": 17, "required_flag": "tay_giai_phong", "point_cost": 1, "stamina_cost": 25.0, "cooldown": 12.0, "damage_mult": 1.0, "range": 340.0, "chain_range": 220.0, "chain_count": 4, "chain_falloff": 0.85},
	# --- Đợt 6: 4 skill cuối + bị động Da Sắt (trang skill 2, phím Q lật trang) ---
	"da_sat": {"name": "Da Sắt", "branch": "warrior", "required_level": 3, "point_cost": 1, "stamina_cost": 0.0, "cooldown": 0.0, "passive": true, "damage_reduction": 0.15},
	"trieu_hoi_bong": {"name": "Triệu Hồi Bóng", "branch": "dark", "required_level": 13, "required_flag": "nam_giai_phong", "point_cost": 1, "stamina_cost": 30.0, "cooldown": 30.0, "duration": 20.0, "damage_mult": 0.8, "tick_interval": 0.9, "range": 210.0},
	"cong_phong_an": {"name": "Cổng Phong Ấn", "branch": "dark", "required_level": 15, "required_flag": "nam_giai_phong", "point_cost": 1, "stamina_cost": 15.0, "cooldown": 14.0, "distance": 220.0, "min_distance": 60.0},
	"khien_ma_thuat": {"name": "Khiên Ma Thuật", "branch": "mage", "required_level": 19, "required_flag": "tay_giai_phong", "point_cost": 1, "stamina_cost": 20.0, "cooldown": 18.0, "duration": 8.0, "shield_base": 40, "shield_per_level": 4},
	"mua_thien_thach": {"name": "Mưa Thiên Thạch", "branch": "mage", "required_level": 21, "required_flag": "tay_giai_phong", "point_cost": 1, "stamina_cost": 35.0, "cooldown": 20.0, "damage_mult": 0.9, "radius": 180.0, "meteor_radius": 70.0, "waves": 5, "wave_interval": 0.5, "range": 420.0},
}

# Công thức chế tạo (nguồn số liệu duy nhất cho CraftPanel / craft() / test).
# cost: nguyên liệu trong `materials` + "gold" (trừ qua add_gold sau khi đủ).
# once_flag: công thức chế 1 lần duy nhất (trang bị), flag GameState ghi lại.
const CRAFT_RECIPES: Array = [
	{"id": "binh_mau_tu_thao", "name": "Bình Máu (chế từ thảo)", "desc": "Hồi 50 HP khi dùng (phím H). Rẻ hơn mua ở shop nếu sẵn thảo.",
		"cost": {"herb": 2}},
	{"id": "dai_binh_hoi_phuc", "name": "Đại Bình Hồi Phục", "desc": "Hồi 150 HP khi dùng (phím H tự ưu tiên khi máu hụt nhiều). Thuốc cấp cao — chỉ chế được, shop không bán.",
		"cost": {"herb": 3, "monster_core": 1, "gold": 15}},
	{"id": "kiem_loi_quai", "name": "Kiếm Lõi Quái", "desc": "Trang bị vĩnh viễn: +6 ATK. Chế 1 lần duy nhất.",
		"cost": {"monster_core": 6, "gold": 150}, "once_flag": "crafted_kiem_loi_quai", "equip_atk": 6, "equip_def": 0},
	{"id": "giap_da_bong", "name": "Giáp Da Bóng", "desc": "Trang bị vĩnh viễn: +4 DEF. Chế 1 lần duy nhất.",
		"cost": {"monster_core": 4, "herb": 2, "gold": 100}, "once_flag": "crafted_giap_da_bong", "equip_atk": 0, "equip_def": 4},
]


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
	equipment_items = []
	equipped_uids = {"weapon": "", "armor": ""}
	legacy_attack_bonus = 0
	legacy_defense_bonus = 0
	_equipment_counter = 0
	_recalc_equipment_bonus()
	skill_points = 0
	unlocked_skills = []
	materials = {"herb": 0, "monster_core": 0}
	greater_potions = 0
	game_completed = false
	ending_id = ""
	materials_changed.emit(materials)
	skills_changed.emit(skill_points, unlocked_skills)
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
		skill_points += 1 # GDD v2 mục 5.1: mỗi level +1 điểm skill
		skills_changed.emit(skill_points, unlocked_skills)
		level_changed.emit(level)
		player_hp_changed.emit(player_hp, player_max_hp)
		print("[GameState] Lên cấp! Level = %d (+1 điểm skill, tổng %d)" % [level, skill_points])
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

## Suy slot từ chỉ số: atk>0,def=0 -> weapon; def>0,atk=0 -> armor;
## cả hai >0 -> atk>=def ? weapon : armor; cả hai =0 -> weapon.
func _infer_equipment_slot(atk: int, def: int) -> String:
	if atk > 0 and def == 0:
		return "weapon"
	if def > 0 and atk == 0:
		return "armor"
	if atk > 0 and def > 0:
		return "weapon" if atk >= def else "armor"
	return "weapon"


## Tính lại attack_bonus/defense_bonus từ legacy + 2 món đang mặc, rồi
## phát stats_changed (player/hud đọc) + equipment_changed (panel trang bị).
func _recalc_equipment_bonus() -> void:
	var atk_total: int = legacy_attack_bonus
	var def_total: int = legacy_defense_bonus
	for slot in ["weapon", "armor"]:
		var item: Dictionary = get_equipped_item(slot)
		if not item.is_empty():
			atk_total += int(item.get("atk", 0))
			def_total += int(item.get("def", 0))
	attack_bonus = atk_total
	defense_bonus = def_total
	# Đồng bộ ngoại hình: đang mặc món ở slot giáp -> hiện bộ giáp.
	# Cộng thêm dấu vết của SAVE CŨ (bản xương, không có danh sách đồ):
	# DEF trần di trú > 0 hoặc đã từng chế Giáp Da Bóng cũng tính là
	# "đã có giáp" — load game cũ có giáp thì hiện giáp, không bắt
	# người chơi quay về áo vải. Game mới luôn có legacy = 0 và chưa
	# có cờ đó nên không bị ảnh hưởng.
	var wearing_armor: bool = str(equipped_uids.get("armor", "")) != "" \
		or legacy_defense_bonus > 0 or get_flag("crafted_giap_da_bong")
	if wearing_armor != has_armor_visual:
		has_armor_visual = wearing_armor
		appearance_changed.emit(has_armor_visual)
	stats_changed.emit(attack_bonus, defense_bonus)
	equipment_changed.emit()


## Món `candidate` có mạnh HƠN HẲN món `current` trong cùng slot không?
## Vũ khí so atk trước rồi def; giáp so def trước rồi atk. Bằng nhau ở cả
## hai chỉ số thì KHÔNG mạnh hơn (giữ món đang mặc).
func _is_stronger_equipment(candidate: Dictionary, current: Dictionary) -> bool:
	if str(candidate.get("slot", "weapon")) == "armor":
		if int(candidate.get("def", 0)) != int(current.get("def", 0)):
			return int(candidate.get("def", 0)) > int(current.get("def", 0))
		return int(candidate.get("atk", 0)) > int(current.get("atk", 0))
	if int(candidate.get("atk", 0)) != int(current.get("atk", 0)):
		return int(candidate.get("atk", 0)) > int(current.get("atk", 0))
	return int(candidate.get("def", 0)) > int(current.get("def", 0))


## Nhận một món trang bị (rơi từ quái, mở rương hoặc chế tạo).
## Giữ nguyên chữ ký cũ. Món được thêm vào equipment_items và TỰ ĐỘNG
## TRANG BỊ nếu slot còn trống hoặc món mới mạnh hơn hẳn món đang mặc
## trong slot đó; yếu hơn/bằng thì chỉ nằm trong túi, không đổi chỉ số.
func add_equipment(equip_name: String, atk: int, def: int) -> void:
	var slot: String = _infer_equipment_slot(atk, def)
	_equipment_counter += 1
	var item: Dictionary = {
		"uid": "eq_%d" % _equipment_counter,
		"name": equip_name,
		"slot": slot,
		"atk": atk,
		"def": def,
	}
	equipment_items.append(item)
	var current: Dictionary = get_equipped_item(slot)
	if current.is_empty() or _is_stronger_equipment(item, current):
		equipped_uids[slot] = str(item["uid"])
	_recalc_equipment_bonus()
	print("[GameState] Nhận trang bị '%s' (+%d ATK, +%d DEF) -> ATK bonus %d, DEF bonus %d" % [
		equip_name, atk, def, attack_bonus, defense_bonus])


## Trang bị món đang sở hữu theo uid (theo slot của chính món đó).
## Trả false nếu uid không tồn tại (không đổi gì).
func equip_item(uid: String) -> bool:
	var item: Dictionary = get_equipment_by_uid(uid)
	if item.is_empty():
		return false
	equipped_uids[str(item.get("slot", "weapon"))] = uid
	_recalc_equipment_bonus()
	return true


## Món đang mặc ở slot ("weapon"/"armor"), {} nếu slot trống/không hợp lệ.
func get_equipped_item(slot: String) -> Dictionary:
	var uid: String = str(equipped_uids.get(slot, ""))
	if uid == "":
		return {}
	return get_equipment_by_uid(uid)


## Tìm món theo uid trong equipment_items, {} nếu không có.
func get_equipment_by_uid(uid: String) -> Dictionary:
	if uid == "":
		return {}
	for raw in equipment_items:
		if raw is Dictionary and str(raw.get("uid", "")) == uid:
			return raw
	return {}


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


# --- Đại Bình Hồi Phục (chỉ có bằng chế tạo) ------------------------------

func add_greater_potions(amount: int) -> void:
	greater_potions = max(0, greater_potions + amount)
	potions_changed.emit(potions)


# Trừ 1 đại bình nếu còn. Trả false khi hết (không trừ).
func use_greater_potion() -> bool:
	if greater_potions <= 0:
		return false
	greater_potions -= 1
	potions_changed.emit(potions)
	return true


# --- Nguyên liệu chế tạo ----------------------------------------------------

func get_material(material_id: String) -> int:
	return int(materials.get(material_id, 0))


func add_material(material_id: String, amount: int) -> void:
	materials[material_id] = max(0, int(materials.get(material_id, 0)) + amount)
	materials_changed.emit(materials)
	print("[GameState] Nguyên liệu '%s' = %d" % [material_id, int(materials[material_id])])


## Kiểm tra đủ nguyên liệu + vàng cho 1 chi phí (không trừ gì).
func can_afford_cost(cost: Dictionary) -> bool:
	for key in cost.keys():
		if str(key) == "gold":
			if gold < int(cost[key]):
				return false
		elif get_material(str(key)) < int(cost[key]):
			return false
	return true


## Trừ nguyên liệu + vàng theo cost (gọi sau can_afford_cost). Trả false
## nếu không đủ (không trừ gì cả).
func spend_cost(cost: Dictionary) -> bool:
	if not can_afford_cost(cost):
		return false
	for key in cost.keys():
		if str(key) == "gold":
			add_gold(-int(cost[key]))
		else:
			materials[str(key)] = int(materials.get(str(key), 0)) - int(cost[key])
	materials_changed.emit(materials)
	return true


# --- Chế tạo (mức cơ bản theo GDD) -------------------------------------------

func get_craft_recipe(recipe_id: String) -> Dictionary:
	for r in CRAFT_RECIPES:
		if str(r.get("id", "")) == recipe_id:
			return r
	return {}


## Có chế được công thức này ngay lúc này không (đủ nguyên liệu/vàng +
## chưa chế nếu là đồ 1 lần).
func can_craft(recipe_id: String) -> bool:
	var r: Dictionary = get_craft_recipe(recipe_id)
	if r.is_empty():
		return false
	var once: String = str(r.get("once_flag", ""))
	if once != "" and get_flag(once):
		return false
	return can_afford_cost(r.get("cost", {}))


## Chế 1 món theo CRAFT_RECIPES. Trả false nếu không đủ điều kiện
## (không trừ gì). Thành công: trừ chi phí, áp kết quả, ghi log.
func craft(recipe_id: String) -> bool:
	var r: Dictionary = get_craft_recipe(recipe_id)
	if r.is_empty() or not can_craft(recipe_id):
		return false
	if not spend_cost(r.get("cost", {})):
		return false
	match recipe_id:
		"binh_mau_tu_thao":
			add_potions(1)
		"dai_binh_hoi_phuc":
			add_greater_potions(1)
		"kiem_loi_quai", "giap_da_bong":
			add_equipment(str(r.get("name", recipe_id)), int(r.get("equip_atk", 0)), int(r.get("equip_def", 0)))
			set_flag(str(r.get("once_flag", "")))
	print("[GameState] Đã chế tạo: %s" % str(r.get("name", recipe_id)))
	return true


# --- Chìa khóa phong ấn ----------------------------------------------------

func add_seal_key(region: String) -> void:
	seal_keys[region] = true
	print("[GameState] Nhận chìa phong ấn vùng '%s' (%d/4)" % [region, seal_keys.values().count(true)])
	# Đủ 4 chìa -> Cổng Bốn Chìa của Sigilspire mở (portal dùng flag này).
	if has_all_seal_keys() and not bool(flags.get("sigilspire_open", false)):
		flags["sigilspire_open"] = true
		print("[GameState] ĐÃ ĐỦ 4 CHÌA PHONG ẤN — cổng Sigilspire mở (flag sigilspire_open).")


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
	if key == "nam_giai_phong" and value:
		add_seal_key("nam")
		part2_completed.emit()
	if key == "tay_giai_phong" and value:
		add_seal_key("tay")
		part3_completed.emit()
	if key == "bac_giai_phong" and value:
		add_seal_key("bac")
		part4_completed.emit()
	# Chọn ending ở Bệ Phong Ấn (quest thap_05a/b/c set các flag này):
	# chốt trạng thái hoàn thành game + nhớ ending để save/menu đọc.
	if value and key.begins_with("ending_"):
		game_completed = true
		ending_id = key
		ending_chosen.emit(key)
		print("[GameState] ĐÃ CHỌN ENDING: %s — game hoàn thành." % key)


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


# --- Skill -----------------------------------------------------------------

func get_skill_points() -> int:
	return skill_points


func is_skill_unlocked(skill_id: String) -> bool:
	return unlocked_skills.has(skill_id)


## Mở khoá skill: kiểm tra tồn tại + cấp yêu cầu + điểm, trừ điểm khi thành công.
## Trả false (không trừ) nếu đã học / thiếu cấp / thiếu điểm / id lạ.
func try_unlock_skill(skill_id: String) -> bool:
	if not SKILL_DEFS.has(skill_id):
		return false
	if is_skill_unlocked(skill_id):
		return false
	var def: Dictionary = SKILL_DEFS[skill_id]
	var required_flag := str(def.get("required_flag", ""))
	if required_flag != "" and not get_flag(required_flag):
		print("[GameState] Chưa mở được skill '%s': cần hoàn thành điều kiện '%s'." % [skill_id, required_flag])
		return false
	if level < int(def.get("required_level", 1)):
		return false
	var cost: int = int(def.get("point_cost", 1))
	if skill_points < cost:
		return false
	skill_points -= cost
	unlocked_skills.append(skill_id)
	skills_changed.emit(skill_points, unlocked_skills)
	print("[GameState] Mở khoá skill '%s' (-%d điểm, còn %d)" % [skill_id, cost, skill_points])
	return true


## Cộng điểm skill trực tiếp (thưởng sự kiện / test).
func add_skill_points(amount: int) -> void:
	skill_points = max(0, skill_points + amount)
	skills_changed.emit(skill_points, unlocked_skills)


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
		"has_armor_visual": has_armor_visual,
		"equipment_items": equipment_items.duplicate(true),
		"equipped_uids": equipped_uids.duplicate(),
		"legacy_attack_bonus": legacy_attack_bonus,
		"legacy_defense_bonus": legacy_defense_bonus,
		"equipment_counter": _equipment_counter,
		"skill_points": skill_points,
		"unlocked_skills": unlocked_skills.duplicate(),
		"materials": materials.duplicate(),
		"greater_potions": greater_potions,
		"game_completed": game_completed,
		"ending_id": ending_id,
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
	# --- Trang bị: nạp danh sách đồ HOẶC di trú save cũ ---
	# KHÔNG gán thẳng attack_bonus/defense_bonus ở đây: hai biến đó là giá
	# trị suy ra, _recalc_equipment_bonus() ở cuối from_dict() sẽ tính lại.
	if data.has("equipment_items") and data["equipment_items"] is Array:
		# Save mới: nạp danh sách đồ (làm sạch từng phần tử), legacy lấy từ
		# save, counter lấy từ save để uid sinh sau không trùng uid cũ.
		equipment_items = []
		for raw in data["equipment_items"]:
			if not (raw is Dictionary):
				continue
			var c_atk: int = int(raw.get("atk", 0))
			var c_def: int = int(raw.get("def", 0))
			var c_slot: String = str(raw.get("slot", ""))
			if c_slot != "weapon" and c_slot != "armor":
				c_slot = _infer_equipment_slot(c_atk, c_def)
			var c_uid: String = str(raw.get("uid", ""))
			if c_uid == "":
				continue
			equipment_items.append({
				"uid": c_uid,
				"name": str(raw.get("name", "")),
				"slot": c_slot,
				"atk": c_atk,
				"def": c_def,
			})
		legacy_attack_bonus = int(data.get("legacy_attack_bonus", 0))
		legacy_defense_bonus = int(data.get("legacy_defense_bonus", 0))
		_equipment_counter = int(data.get("equipment_counter", equipment_items.size()))
		# equipped_uids: chỉ giữ uid thực sự tồn tại trong danh sách đồ.
		equipped_uids = {"weapon": "", "armor": ""}
		if data.has("equipped_uids") and data["equipped_uids"] is Dictionary:
			for slot in ["weapon", "armor"]:
				var e_uid: String = str(data["equipped_uids"].get(slot, ""))
				if e_uid != "" and not get_equipment_by_uid(e_uid).is_empty():
					equipped_uids[slot] = e_uid
	else:
		# DI TRÚ SAVE CŨ (chưa có equipment keys): bản xương cộng dồn thẳng
		# vào attack_bonus/defense_bonus và không lưu món nào. Chuyển toàn
		# bộ tổng cũ sang legacy_* để tổng chỉ số người chơi giữ nguyên
		# 100% khi load; danh sách đồ bắt đầu rỗng, đồ nhặt từ nay mới vào
		# hệ slot. (Save mới lưu legacy riêng nên không cộng trùng: khi đó
		# attack_bonus trong save đã là giá trị suy ra, không đọc trực tiếp.)
		equipment_items = []
		equipped_uids = {"weapon": "", "armor": ""}
		legacy_attack_bonus = int(data.get("attack_bonus", 0))
		legacy_defense_bonus = int(data.get("defense_bonus", 0))
		_equipment_counter = 0
		# NGOẠI HÌNH của save cũ được lo ở _recalc_equipment_bonus()
		# (legacy_defense_bonus > 0 / cờ crafted_giap_da_bong -> coi như
		# đã có giáp) — KHÔNG tạo món giả vào danh sách đồ ở đây.
	skill_points = int(data.get("skill_points", 0))
	materials = {"herb": 0, "monster_core": 0}
	if data.has("materials") and data["materials"] is Dictionary:
		for mk in data["materials"].keys():
			materials[str(mk)] = int(data["materials"][mk])
	greater_potions = int(data.get("greater_potions", 0))
	game_completed = bool(data.get("game_completed", false))
	ending_id = str(data.get("ending_id", ""))
	# Save cũ có đủ 4 chìa nhưng chưa có flag cổng tháp (save từ trước đợt 6)
	if has_all_seal_keys() and not bool(flags.get("sigilspire_open", false)):
		flags["sigilspire_open"] = true
	materials_changed.emit(materials)
	unlocked_skills = []
	if data.has("unlocked_skills") and data["unlocked_skills"] is Array:
		for sid in data["unlocked_skills"]:
			unlocked_skills.append(str(sid))
	skills_changed.emit(skill_points, unlocked_skills)
	# Tính lại attack_bonus/defense_bonus suy ra từ legacy + đồ đang mặc
	# (hàm này tự emit stats_changed + equipment_changed).
	_recalc_equipment_bonus()
	clear_boss_display()
	gold_changed.emit(gold)
	potions_changed.emit(potions)
	xp_changed.emit(xp, level)
	level_changed.emit(level)
	player_hp_changed.emit(player_hp, player_max_hp)
