extends Node
## Test tự động cho MONSTER PACK vùng Đông (chạy headless):
##   godot --headless --path game res://tests/monster_pack_test.tscn
## Kiểm tra: 9 loài mới (wolf/boar/spider/scarecrow/bandit/soldier/
## stone_spirit/wyvern/thu_yeu) đúng thông số + sprite source; wolf gọi
## bầy; wolf/spider take_damage đến chết -> DEAD + gold; soldier khiên
## (đánh từ trước giảm 60% so với từ sau); stone_spirit kháng phẳng -4;
## scarecrow dormant -> bật dậy khi player (player.tscn thật) tới gần;
## poison_shot bay trúng player -8 HP và nhện tự bắn trúng player -8 HP;
## thu_yeu triệu hồi slime + boss display clear khi chết.
## Thoát exit code 0 nếu PASS hết, 1 nếu có FAIL.

var _frame := 0
var _failures: Array[String] = []
var _gold0: int = 0
var _player: Node = null
var _player_hp0: int = -1

var _wolf_a: Node = null
var _wolf_b: Node = null
var _boar: Node = null
var _spider: Node = null
var _spider2: Node = null
var _scarecrow: Node = null
var _bandit: Node = null
var _soldier: Node = null
var _stone: Node = null
var _wyvern: Node = null
var _thu: Node = null


func _spawn(path: String, pos: Vector2) -> Node:
	var n: Node = load(path).instantiate()
	n.global_position = pos
	add_child(n)
	return n


func _ready() -> void:
	_gold0 = GameState.gold
	_wolf_a = _spawn("res://enemies/wolf.tscn", Vector2(-400, -600))
	_wolf_b = _spawn("res://enemies/wolf.tscn", Vector2(-300, -600))
	_boar = _spawn("res://enemies/boar.tscn", Vector2(0, -600))
	_spider = _spawn("res://enemies/spider.tscn", Vector2(400, -600))
	_spider2 = _spawn("res://enemies/spider.tscn", Vector2(1650, 400)) # pha 1 ở xa 400px: ngoài tầm bắn, chỉ test đạn thẳng
	_scarecrow = _spawn("res://enemies/scarecrow.tscn", Vector2(1000, 400))
	_bandit = _spawn("res://enemies/bandit.tscn", Vector2(800, -600))
	_soldier = _spawn("res://enemies/soldier.tscn", Vector2(1600, -600))
	_stone = _spawn("res://enemies/stone_spirit.tscn", Vector2(2000, -600))
	_wyvern = _spawn("res://enemies/wyvern.tscn", Vector2(2400, -600))
	_thu = _spawn("res://enemies/thu_yeu.tscn", Vector2(3000, -600))
	print("[MONSTERTEST] Bắt đầu test monster pack (gold ban đầu = %d)." % _gold0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("[MONSTERTEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[MONSTERTEST] FAIL: ", label)


func _stats(e: Node, type: String, hp: int, dmg: int, spd: float, xp: int, gold: int, label: String) -> void:
	_check(str(e.get("enemy_type")) == type, "%s enemy_type = %s" % [label, type])
	_check(int(e.get("max_hp")) == hp and int(e.get("hp")) == hp, "%s HP = %d" % [label, hp])
	_check(int(e.get("damage")) == dmg and is_equal_approx(float(e.get("speed")), spd),
		"%s dmg/speed = %d/%.0f" % [label, dmg, spd])
	_check(int(e.get("xp_reward")) == xp and int(e.get("gold_reward")) == gold,
		"%s xp/gold = %d/%d" % [label, xp, gold])
	_check(e.is_in_group("enemy"), "%s ở group enemy" % label)


func _frames_path(e: Node) -> String:
	var f: Resource = e.get("sprite_frames")
	return f.resource_path if f != null else ""


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		5:
			_stats(_wolf_a, "wolf", 30, 9, 165.0, 14, 4, "Wolf")
			_check(_frames_path(_wolf_a) == "res://assets/sprites/wolf_frames.tres", "Wolf dùng wolf_frames.tres (sprite vẽ riêng)")
			_stats(_boar, "boar", 45, 12, 85.0, 16, 5, "Boar")
			_check(_frames_path(_boar) == "res://assets/sprites/rat_frames.tres", "Boar dùng rat_frames")
			_check(is_equal_approx(float(_boar.get("sprite_scale")), 1.5), "Boar sprite_scale = 1.5")
			_stats(_spider, "spider", 22, 8, 105.0, 13, 4, "Spider")
			_check(_frames_path(_spider) == "res://assets/sprites/spider_frames.tres", "Spider dùng spider_frames.tres (sprite vẽ riêng)")
			_stats(_scarecrow, "scarecrow", 35, 11, 70.0, 15, 5, "Scarecrow")
			_check(_frames_path(_scarecrow) == "res://assets/sprites/player_frames.tres", "Scarecrow dùng player_frames")
			_check(bool(_scarecrow.get("dormant")), "Scarecrow bắt đầu ở trạng thái dormant")
			_check(int(_scarecrow.get("state")) == 0, "Scarecrow dormant: state IDLE, không detect")
			_stats(_bandit, "bandit", 40, 12, 120.0, 18, 12, "Bandit")
			_check(_frames_path(_bandit) == "res://assets/sprites/player_frames.tres", "Bandit dùng player_frames")
			_stats(_soldier, "soldier", 55, 12, 95.0, 20, 15, "Soldier")
			_stats(_stone, "stone_spirit", 90, 16, 45.0, 26, 8, "StoneSpirit")
			_check(_frames_path(_stone) == "res://assets/sprites/golem_frames.tres", "StoneSpirit dùng golem_frames")
			_stats(_wyvern, "wyvern", 70, 15, 135.0, 32, 10, "Wyvern")
			_check(_frames_path(_wyvern) == "res://assets/sprites/wyvern_frames.tres", "Wyvern dùng wyvern_frames.tres (sprite vẽ riêng)")
			var w_sprite: AnimatedSprite2D = _wyvern.get_node("Sprite")
			_check(is_equal_approx(w_sprite.position.y, -36.0), "Wyvern sprite bay cao (offset y = -36)")
			_stats(_thu, "thu_yeu", 300, 16, 50.0, 150, 60, "ThuYeu")
			_check(is_equal_approx(float(_thu.get("sprite_scale")), 2.0), "ThuYeu sprite_scale = 2.0")
			_check(bool(_thu.get("boss_display_active")), "ThuYeu boss display active sau _ready")
			_check(str(GameState.boss_name) == "Heartwood Treant" and int(GameState.boss_max_hp) == 300,
				"GameState boss display = Heartwood Treant/300 (thấy '%s'/%d)" % [str(GameState.boss_name), int(GameState.boss_max_hp)])
			# Ép sói A vào CHASE để kiểm tra gọi bầy
			_wolf_a.set("state", 1)
		20:
			# --- Khiên lính: ép mặt hướng PHẢI, đánh từ trước ---
			_soldier.set("_facing", Vector2.RIGHT)
			var front_from: Vector2 = (_soldier as Node2D).global_position + Vector2(100, 0)
			_check(bool(_soldier.call("is_blocked_from", front_from)), "Soldier: đòn từ trước bị khiên tính là blocked")
			_soldier.take_damage(20, front_from)
			_check(int(_soldier.get("hp")) == 47, "Soldier khiên đỡ: 20 dmg -> nhận 8, HP 47 (thấy %d)" % int(_soldier.get("hp")))
			_check(int(_soldier.get("shield_blocks")) == 1, "Soldier shield_blocks = 1")
		22:
			# --- Đánh từ sau lưng: nhận đủ ---
			_soldier.set("_facing", Vector2.RIGHT)
			var back_from: Vector2 = (_soldier as Node2D).global_position + Vector2(-100, 0)
			_check(not bool(_soldier.call("is_blocked_from", back_from)), "Soldier: đòn từ sau không bị khiên đỡ")
			_soldier.take_damage(20, back_from)
			_check(int(_soldier.get("hp")) == 27, "Soldier sau lưng: nhận đủ 20, HP 27 (thấy %d)" % int(_soldier.get("hp")))
			_check(int(_soldier.get("shield_blocks")) == 1, "Soldier shield_blocks vẫn = 1")
			# --- Thạch linh kháng phẳng -4 ---
			_stone.take_damage(14, (_stone as Node2D).global_position + Vector2(50, 0))
			_check(int(_stone.get("hp")) == 80, "StoneSpirit kháng -4: 14 dmg -> nhận 10, HP 80 (thấy %d)" % int(_stone.get("hp")))
			_stone.take_damage(3, (_stone as Node2D).global_position + Vector2(50, 0))
			_check(int(_stone.get("hp")) == 79, "StoneSpirit: 3 dmg -> nhận tối thiểu 1, HP 79 (thấy %d)" % int(_stone.get("hp")))
		30:
			_thu.call("summon_minion")
			_check(int(_thu.get("summons_done")) == 1, "ThuYeu triệu hồi được slime (summons_done = 1)")
			var slimes := 0
			for e in get_tree().get_nodes_in_group("enemy"):
				if str(e.get("enemy_type")) == "slime":
					slimes += 1
			_check(slimes >= 1, "Có slime con xuất hiện cạnh ThuYeu (thấy %d)" % slimes)
		40:
			_check(int(_wolf_b.get("state")) == 1, "Wolf B được gọi bầy -> CHASE (state=%d)" % int(_wolf_b.get("state")))
			_wolf_a.take_damage(999, Vector2(-500, -600))
			_check(int(_wolf_a.get("state")) == 3, "Wolf chết -> state DEAD")
			_spider.take_damage(999, Vector2(300, -600))
			_check(int(_spider.get("state")) == 3, "Spider chết -> state DEAD")
			_check(GameState.gold == _gold0 + 8, "Wolf + Spider chết -> +8 gold (gold=%d)" % GameState.gold)
		50:
			# Player thật đứng cách bù nhìn 250px (ngoài tầm bật dậy 90)
			# và cách nhện 2 đúng 150px (trong dải bắn 120-220).
			_player = load("res://player/player.tscn").instantiate()
			_player.global_position = Vector2(1250, 400)
			add_child(_player)
		53:
			_player_hp0 = int(_player.get("hp"))
			_check(_player_hp0 > 16, "Player sẵn sàng cho test độc (hp=%d)" % _player_hp0)
			_check(bool(_scarecrow.get("dormant")), "Scarecrow vẫn dormant khi player cách 250px")
			# Bắn thẳng 1 viên poison_shot vào player từ phía trái 60px
			var shot: Node2D = load("res://enemies/poison_shot.tscn").instantiate()
			add_child(shot)
			shot.global_position = (_player as Node2D).global_position + Vector2(-60, 0)
			shot.call("launch", Vector2.RIGHT, 8)
		85:
			_check(int(_player.get("hp")) == _player_hp0 - 8,
				"PoisonShot bay trúng player: -8 HP (hp=%d, đầu=%d)" % [int(_player.get("hp")), _player_hp0])
			# Dịch nhện 2 lại cách player đúng 150px (dải bắn 120-220):
			# nó sẽ tự bắn ngay (timer đã chờ sẵn) và đạn trúng sau ~0.5s.
			_spider2.global_position = (_player as Node2D).global_position + Vector2(150, 0)
		175:
			_check(int(_spider2.get("shots_fired")) >= 1, "Spider2 đã tự bắn độc (shots=%d)" % int(_spider2.get("shots_fired")))
			_check(int(_player.get("hp")) == _player_hp0 - 16,
				"Độc của Spider2 trúng player: tổng -16 HP (hp=%d)" % int(_player.get("hp")))
			_check(bool(_scarecrow.get("dormant")), "Scarecrow vẫn dormant (player chưa tới gần)")
			# Đưa player tới sát bù nhìn (60px < 90px)
			_player.global_position = (_scarecrow as Node2D).global_position + Vector2(60, 0)
		195:
			_check(not bool(_scarecrow.get("dormant")), "Scarecrow BẬT DẬY khi player vào <90px")
			_check(int(_scarecrow.get("state")) == 1 or int(_scarecrow.get("state")) == 2,
				"Scarecrow sau bật dậy ở CHASE/ATTACK (state=%d)" % int(_scarecrow.get("state")))
		200:
			_thu.take_damage(9999, (_thu as Node2D).global_position + Vector2(200, 0))
			_check(int(_thu.get("state")) == 3, "ThuYeu chết -> state DEAD")
			_check(not bool(_thu.get("boss_display_active")), "ThuYeu chết -> boss_display_active = false")
			_check(str(GameState.boss_name) == "", "ThuYeu chết -> GameState boss display rỗng")
			_check(GameState.gold == _gold0 + 68, "Tổng gold: wolf 4 + spider 4 + thu_yeu 60 (gold=%d)" % GameState.gold)
		215:
			print("[MONSTERTEST] Tổng kết: %d FAIL" % _failures.size())
			get_tree().quit(1 if _failures.size() > 0 else 0)
