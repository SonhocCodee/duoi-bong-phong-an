extends Node
## Smoke test cho NOI THANH FROSTGARD (maps/frostgard.tscn, builder
## tools_paint/build_frostgard.gd): load scene, dem NPC >= 13 va
## schedule_enabled, kiem tra marker Spawn_* + PortalSouthGate dung
## hop dong (target frostgard_approach / spawn from_frostgard),
## Player + HUD ton tai, 2 hiep si dong bang tinh (wander_radius == 0).
##   godot --headless --path game res://tests/frostgard_city_test.tscn

var _passes: int = 0
var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("[FROSTCITY-TEST] PASS: ", label)
	else:
		_failures.append(label)
		print("[FROSTCITY-TEST] FAIL: ", label)


func _ready() -> void:
	var ps: PackedScene = load("res://maps/frostgard.tscn")
	_check(ps != null, "Load duoc maps/frostgard.tscn")
	if ps == null:
		_finish()
		return
	var city: Node = ps.instantiate()
	add_child(city)

	# --- NPC: dem qua method dac trung cua systems/npc.gd ---
	var npcs: Array[Node] = []
	_collect_npcs(city, npcs)
	_check(npcs.size() >= 13, "So NPC >= 13 (thay %d)" % npcs.size())
	var sched_on := 0
	var ids := {}
	for n in npcs:
		if bool(n.get("schedule_enabled")):
			sched_on += 1
		var sched: Array = n.get("schedule")
		_check(sched.size() > 0, "NPC %s co schedule (%d buoc)" % [str(n.get("npc_id")), sched.size()])
		ids[str(n.get("npc_id"))] = n
	_check(sched_on >= 13, "NPC schedule_enabled >= 13 (thay %d)" % sched_on)
	for want in ["frost_tho_ren_master", "frost_tho_ren_thep", "frost_giu_danh_sach",
			"frost_tu_si", "frost_doi_truong_gac", "frost_chu_tro", "frost_thu_lai",
			"frost_hiep_si_trai", "frost_hiep_si_phai", "frost_ganh_cui",
			"frost_quet_tuyet", "frost_dua_tin", "frost_gac_cong_nam"]:
		_check(ids.has(want), "Co NPC id=" + want)
	# Hiep si dong bang: TINH - wander 0
	for kid in ["frost_hiep_si_trai", "frost_hiep_si_phai"]:
		if ids.has(kid):
			_check(is_equal_approx(float(ids[kid].get("wander_radius")), 0.0),
				"Hiep si bang %s wander_radius == 0 (tinh)" % kid)
	# Shop: tho ren thep bang
	if ids.has("frost_tho_ren_thep"):
		_check(bool(ids["frost_tho_ren_thep"].get("shop_enabled")),
			"Tho ren thep bang shop_enabled == true")
	# King Valdemar KHONG duoc dat NPC trong thanh (tranh trung Approach)
	_check(not ids.has("vua_bac_bang"), "Khong co NPC vua_bac_bang trong thanh")

	# --- Marker + Portal theo hop dong co dinh ---
	for mname in ["Spawn_start", "Spawn_from_approach", "Spawn_from_deadland"]:
		_check(city.find_child(mname, true, false) != null, "Co marker " + mname)
	var portal: Node = city.find_child("PortalSouthGate", true, false)
	_check(portal != null, "Co PortalSouthGate")
	if portal != null:
		_check(str(portal.get("target_scene")) == "res://maps/frostgard_approach.tscn",
			"PortalSouthGate target_scene == frostgard_approach (thay %s)" % str(portal.get("target_scene")))
		_check(str(portal.get("target_spawn")) == "from_frostgard",
			"PortalSouthGate target_spawn == from_frostgard (thay %s)" % str(portal.get("target_spawn")))
	_check(city.find_child("Player", true, false) != null, "Co Player")
	_check(city.find_child("HUD", true, false) != null, "Co HUD")
	_check(city.find_child("LoLonTrungTam", true, false) != null, "Co prop LoLonTrungTam")
	_check(city.find_child("NgaiBang", true, false) != null, "Co prop NgaiBang")
	_check(city.find_child("ThapChuongLon", true, false) != null, "Co prop ThapChuongLon")
	_check(city.find_child("DaiDanhSachTen", true, false) != null, "Co prop DaiDanhSachTen")
	_finish()


func _collect_npcs(node: Node, out: Array[Node]) -> void:
	if node.has_method("set_talk_pause"):
		out.append(node)
	for ch in node.get_children():
		_collect_npcs(ch, out)


func _finish() -> void:
	print("[FROSTCITY-TEST] Tong ket: %d PASS, %d FAIL" % [_passes, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)
