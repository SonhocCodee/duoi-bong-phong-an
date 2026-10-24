extends Node
## Smoke test noi thanh Solmaris (maps/solmaris.tscn): load scene, dem NPC
## >= 14 va tat ca co schedule_enabled, du 3 marker spawn + 2 portal dung
## target_scene/target_spawn theo hop dong coordinator.
##   godot --headless --path game res://tests/solmaris_city_test.tscn

var _passes: int = 0
var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[SOLMARIS-CITY-TEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[SOLMARIS-CITY-TEST] FAIL: ", label)


func _ready() -> void:
	var ps: PackedScene = load("res://maps/solmaris.tscn")
	_check(ps != null, "Load duoc res://maps/solmaris.tscn")
	if ps == null:
		_finish()
		return
	var city: Node = ps.instantiate()
	add_child(city)

	# --- NPC: dem + schedule ---
	var npcs: Array[Node] = []
	for ch in city.get_children():
		if ch.name.begins_with("NPC_"):
			npcs.append(ch)
	_check(npcs.size() >= 14, "So NPC >= 14 (thay %d)" % npcs.size())
	var all_sched := true
	var ids := {}
	for n in npcs:
		if not bool(n.get("schedule_enabled")):
			all_sched = false
			print("[SOLMARIS-CITY-TEST] NPC thieu schedule_enabled: ", n.name)
		var sched: Array = n.get("schedule")
		if sched.is_empty():
			all_sched = false
			print("[SOLMARIS-CITY-TEST] NPC schedule rong: ", n.name)
		var nid := str(n.get("npc_id"))
		if ids.has(nid):
			all_sched = false
			print("[SOLMARIS-CITY-TEST] Trung npc_id: ", nid)
		ids[nid] = true
	_check(all_sched, "Tat ca NPC co schedule_enabled + schedule khong rong + npc_id khong trung")
	_check(ids.has("kassia_vane_thanh"), "Co NPC Kassia Vane o phu (npc_id=kassia_vane_thanh)")

	# --- Marker spawn ---
	for mname in ["Spawn_start", "Spawn_from_approach", "Spawn_from_lair"]:
		_check(city.get_node_or_null(mname) != null, "Co marker " + mname)
	var s_start := city.get_node_or_null("Spawn_start") as Node2D
	var s_app := city.get_node_or_null("Spawn_from_approach") as Node2D
	if s_start != null and s_app != null:
		_check(s_start.position == s_app.position,
			"Spawn_start trung Spawn_from_approach tai (204,84) (thay %s)" % str(s_start.position))

	# --- Portal ---
	var pe := city.get_node_or_null("PortalEastGate")
	_check(pe != null, "Co PortalEastGate")
	if pe != null:
		_check(str(pe.get("target_scene")) == "res://maps/westgate.tscn",
			"PortalEastGate target_scene=westgate.tscn (thay %s)" % str(pe.get("target_scene")))
		_check(str(pe.get("target_spawn")) == "from_solmaris",
			"PortalEastGate target_spawn=from_solmaris (thay %s)" % str(pe.get("target_spawn")))
	var pw := city.get_node_or_null("PortalWestGate")
	_check(pw != null, "Co PortalWestGate")
	if pw != null:
		_check(str(pw.get("target_scene")) == "res://maps/buried_sand_ruins.tscn",
			"PortalWestGate target_scene=buried_sand_ruins.tscn (thay %s)" % str(pw.get("target_scene")))
		_check(str(pw.get("target_spawn")) == "from_solmaris",
			"PortalWestGate target_spawn=from_solmaris (thay %s)" % str(pw.get("target_spawn")))

	# --- Player + HUD + collision ---
	_check(city.get_node_or_null("Player") != null, "Co Player")
	_check(city.get_node_or_null("HUD") != null, "Co HUD")
	_check(city.get_node_or_null("WorldCollision") != null, "Co WorldCollision")
	_finish()


func _finish() -> void:
	print("[SOLMARIS-CITY-TEST] Tong ket: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
