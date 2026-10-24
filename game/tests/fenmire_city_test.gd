extends Node
## Smoke test NOI THANH FENMIRE (maps/fenmire.tscn): scene load duoc, du NPC
## theo layout S7 (>= 13, thuc te 17 gom 2 tin do canh cong den), co NPC chay
## schedule song, du 3 marker spawn + 2 portal dung target theo hop dong.
##   godot --headless --path game res://tests/fenmire_city_test.tscn

var _failures: Array[String] = []
var _passes: int = 0


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[FEN-CITY] PASS: ", label)
	else:
		_failures.append(label)
		print("[FEN-CITY] FAIL: ", label)


func _collect_npcs(n: Node, out: Array) -> void:
	var idv = n.get("npc_id")
	if idv != null and str(idv) != "":
		out.append(n)
	for ch in n.get_children():
		_collect_npcs(ch, out)


func _ready() -> void:
	var ps: PackedScene = load("res://maps/fenmire.tscn")
	_check(ps != null, "Scene fenmire.tscn load duoc (PackedScene != null)")
	if ps == null:
		print("[FEN-CITY] Tong ket: %d PASS, %d FAIL" % [_passes, _failures.size()])
		get_tree().quit(1)
		return
	var city: Node = ps.instantiate()
	add_child(city)

	var npcs: Array = []
	_collect_npcs(city, npcs)
	_check(npcs.size() >= 13, "So NPC >= 13 (thay %d)" % npcs.size())
	var ids := {}
	var has_schedule := false
	for n in npcs:
		ids[str(n.get("npc_id"))] = true
		if bool(n.get("schedule_enabled")):
			has_schedule = true
	_check(has_schedule, "Co NPC schedule_enabled (NPC song)")
	for want in ["linh_canh_bac_fen", "giu_den_cho", "tieu_thuong_be", "truong_dan_chai",
			"dan_chai_1", "tre_con_san", "y_si_giao_phai", "thu_kho_thuoc", "dai_giao_si",
			"morvain", "vua_oswin", "giu_trieu_gia", "tin_do_tre", "lai_pha", "linh_tuan_kenh"]:
		_check(ids.has(want), "Co NPC id '%s'" % want)
	# King Oswin o Phong Vua Benh (183,120) -> pixel (-32+... ) kiem tra gan dung o
	var oswin: Node = null
	var morvain: Node = null
	for n in npcs:
		if str(n.get("npc_id")) == "vua_oswin":
			oswin = n
		if str(n.get("npc_id")) == "morvain":
			morvain = n
	if oswin != null:
		var expect := Vector2((183 - 110) * 64 + 32, (120 - 80) * 64 + 32)
		_check((oswin as Node2D).position.distance_to(expect) < 1.0,
			"King Oswin dung o (183,120) (thay %s)" % str((oswin as Node2D).position))
		_check(not bool(oswin.get("schedule_enabled")) and float(oswin.get("wander_radius")) == 0.0,
			"King Oswin tinh theo quest (schedule off, wander 0)")
	if morvain != null:
		_check(not bool(morvain.get("schedule_enabled")) and float(morvain.get("wander_radius")) == 0.0,
			"Morvain tinh theo quest (schedule off, wander 0)")

	for mname in ["Spawn_start", "Spawn_from_approach", "Spawn_from_blackmere"]:
		_check(city.get_node_or_null(mname) != null, "Co marker %s" % mname)
	var s1: Node2D = city.get_node_or_null("Spawn_start")
	var s2: Node2D = city.get_node_or_null("Spawn_from_approach")
	if s1 != null and s2 != null:
		_check(s1.position == s2.position and s1.position == Vector2(-32, -4192),
			"Spawn_start = Spawn_from_approach tai o (109,14) (thay %s)" % str(s1.position))
	var s3: Node2D = city.get_node_or_null("Spawn_from_blackmere")
	if s3 != null:
		_check(s3.position == Vector2(-5920, -1376),
			"Spawn_from_blackmere tai o (17,58) (thay %s)" % str(s3.position))

	var pg: Node = city.get_node_or_null("PortalNorthGate")
	_check(pg != null, "Co PortalNorthGate")
	if pg != null:
		_check(str(pg.get("target_scene")) == "res://maps/fenmire_approach.tscn"
			and str(pg.get("target_spawn")) == "from_fenmire",
			"PortalNorthGate target approach/from_fenmire (thay %s/%s)"
			% [str(pg.get("target_scene")), str(pg.get("target_spawn"))])
	var pf: Node = city.get_node_or_null("PortalFerry")
	_check(pf != null, "Co PortalFerry")
	if pf != null:
		_check(str(pf.get("target_scene")) == "res://maps/blackmere.tscn"
			and str(pf.get("target_spawn")) == "from_fenmire",
			"PortalFerry target blackmere/from_fenmire (thay %s/%s)"
			% [str(pf.get("target_scene")), str(pf.get("target_spawn"))])
	_check(city.get_node_or_null("Player") != null, "Co Player")
	_check(city.get_node_or_null("HUD") != null, "Co HUD")
	print("[FEN-CITY] Tong ket: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
