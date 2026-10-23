extends Node2D
## Tool mot lan (dot 2B): tang mat do quai + respawn cho cac map da ngoai/dungeon
## dang thua quai so voi chuan gameplay (15-25 con/map da ngoai).
## Chay: godot --headless --path game res://tools_paint/densify_maps.tscn
## Cach lam: load scene map, gom vi tri quai hien co lam moc, them cum quai
## quanh cac moc do (offset co dinh), clamp trong bien map, pack + save lai.

const ENEMY_DIR := "res://enemies/"
const RESPAWN := 45.0

# map -> { "half": Vector2 nua kich thuoc choi duoc, "add": {scene: so luong} }
const PLAN := {
	"res://maps/rung_co_thu.tscn": {
		"half": Vector2(960, 760),
		"add": {"goblin": 4, "slime": 3, "spider": 2},
	},
	"res://maps/ho_suong.tscn": {
		"half": Vector2(960, 660),
		"add": {"frog": 5, "slime": 4},
	},
	"res://maps/nui_thanh_van.tscn": {
		"half": Vector2(960, 860),
		"add": {"goblin": 3, "wolf": 4, "stone_spirit": 3, "boar": 2},
	},
	"res://maps/deo_thanh_van.tscn": {
		"half": Vector2(750, 1050),
		"add": {"stone_spirit": 3, "wolf": 4, "goblin": 3},
	},
	"res://maps/tim_rung.tscn": {
		"half": Vector2(960, 750),
		"add": {"spider": 3, "goblin": 2, "slime": 2},
	},
	"res://maps/mo_da_xanh.tscn": {
		"half": Vector2(860, 600),
		"add": {"bandit": 3, "rat": 2},
	},
	"res://maps/cong_ngam.tscn": {
		"half": Vector2(860, 560),
		"add": {"rat": 3, "spider": 2},
	},
}

const OFFSETS := [
	Vector2(110, 50), Vector2(-130, 70), Vector2(60, -140), Vector2(-80, -110),
	Vector2(170, -40), Vector2(-190, -20), Vector2(30, 160), Vector2(-40, -190),
	Vector2(210, 90), Vector2(-230, 110), Vector2(90, -220), Vector2(-120, 200),
]

var _fail := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 20261023
	for path in PLAN.keys():
		_densify(path, PLAN[path])
	print("[DENSIFY] ====== HOAN TAT, fail=", _fail)
	get_tree().quit(1 if _fail else 0)

func _is_enemy(n: Node) -> bool:
	return n.scene_file_path.begins_with(ENEMY_DIR)

func _collect_enemies(root: Node, out: Array) -> void:
	for c in root.get_children():
		if _is_enemy(c):
			out.append(c)
		_collect_enemies(c, out)

func _densify(path: String, cfg: Dictionary) -> void:
	var ps: PackedScene = load(path)
	if ps == null:
		print("[DENSIFY] LOAD FAIL ", path)
		_fail = true
		return
	var root: Node = ps.instantiate()
	add_child(root)
	var enemies: Array = []
	_collect_enemies(root, enemies)
	# Mo: nhom quai theo loai
	var by_type := {}
	for e in enemies:
		var t: String = e.scene_file_path.get_file().get_basename()
		if not by_type.has(t):
			by_type[t] = []
		by_type[t].append(e)
	# Bat respawn cho quai rac hien co o map da ngoai (tru boss/dac biet)
	var no_respawn_types := ["thu_yeu", "wyvern"]
	for e in enemies:
		var t: String = e.scene_file_path.get_file().get_basename()
		if t in no_respawn_types:
			continue
		if str(e.get("key_flag")) != "":
			continue
		if float(e.get("respawn_time")) == 0.0 and not t.begins_with("boss"):
			if path.ends_with("mo_da_xanh.tscn") and t == "bandit":
				continue # bandit la muc tieu quest dong_06, khong respawn
			e.set("respawn_time", RESPAWN)
	# Them quai theo ke hoach
	var half: Vector2 = cfg["half"]
	var used: Array[Vector2] = []
	for e in enemies:
		used.append((e as Node2D).global_position)
	var add: Dictionary = cfg["add"]
	var counter := 0
	for type_name in add.keys():
		var scene_path: String = ENEMY_DIR + type_name + ".tscn"
		var esc: PackedScene = load(scene_path)
		if esc == null:
			print("[DENSIFY] ENEMY LOAD FAIL ", scene_path)
			_fail = true
			continue
		var anchors: Array = by_type.get(type_name, [])
		if anchors.is_empty():
			anchors = enemies
		for i in int(add[type_name]):
			counter += 1
			var anchor: Node2D = anchors[_rng.randi_range(0, anchors.size() - 1)]
			var pos: Vector2 = anchor.global_position
			for attempt in 8:
				var off: Vector2 = OFFSETS[_rng.randi_range(0, OFFSETS.size() - 1)]
				var cand: Vector2 = anchor.global_position + off
				cand.x = clampf(cand.x, -half.x, half.x)
				cand.y = clampf(cand.y, -half.y, half.y)
				var ok := true
				for u in used:
					if cand.distance_to(u) < 56.0:
						ok = false
						break
				pos = cand
				if ok:
					break
			used.append(pos)
			var inst: Node = esc.instantiate()
			inst.name = "%s_extra_%d" % [type_name, counter]
			root.add_child(inst)
			(inst as Node2D).global_position = pos
			inst.owner = root
			if type_name == "bandit" and path.ends_with("mo_da_xanh.tscn"):
				inst.set("respawn_time", 0.0)
			else:
				inst.set("respawn_time", RESPAWN)
			enemies.append(inst)
	print("[DENSIFY] ", path.get_file(), " tong quai sau them: ", enemies.size())
	# Save lai scene
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		print("[DENSIFY] PACK LOI ", err, " ", path)
		_fail = true
	else:
		err = ResourceSaver.save(packed, path)
		print("[DENSIFY] save err=", err, " -> ", path)
		if err != OK:
			_fail = true
	remove_child(root)
	root.queue_free()
