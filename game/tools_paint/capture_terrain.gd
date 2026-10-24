extends Node2D
## Chup anh TRUOC/SAU cho dot cau truc lai dia hinh da ngoai.
## Chay qua xvfb-run (KHONG headless):
##   TERRAIN_TAG=before xvfb-run -a tools_bin/Godot_v4.2.2-stable_linux.x86_64 --path game res://tools_paint/capture_terrain.tscn
##   TERRAIN_TAG=after  xvfb-run -a tools_bin/Godot_v4.2.2-stable_linux.x86_64 --path game res://tools_paint/capture_terrain.tscn
## Chi chup map co ten trong bien moi truong TERRAIN_MAPS (cach nhau dau phay);
## de trong = chup tat ca SHOTS. Anh luu design/terrain_shots/<stem>_<tag>.png

const OUT_DIR := "/home/hatch/workspace/game-phong-an/design/terrain_shots"

# [stem, map path, camera pos, zoom]
const SHOTS := [
	["stonebridge_full", "res://maps/bo_song_thanh.tscn", Vector2(0, 0), 0.14],
	["stonebridge_bridge", "res://maps/bo_song_thanh.tscn", Vector2(0, -60), 0.62],
	["stonebridge_forest", "res://maps/bo_song_thanh.tscn", Vector2(-2656, 928), 0.62],
	["stonebridge_trail", "res://maps/bo_song_thanh.tscn", Vector2(-2240, 832), 0.62],
	["stonebridge_riverbend", "res://maps/bo_song_thanh.tscn", Vector2(1664, 96), 0.45],
	["elderwood_full", "res://maps/rung_co_thu.tscn", Vector2(0, 0), 0.14],
	["elderwood_trail", "res://maps/rung_co_thu.tscn", Vector2(-300, 100), 0.62],
	["mistlake_full", "res://maps/ho_suong.tscn", Vector2(0, 0), 0.15],
	["wallfoot_full", "res://maps/ngoai_thanh.tscn", Vector2(0, 0), 0.15],
	["cloudpeak_full", "res://maps/nui_thanh_van.tscn", Vector2(0, 0), 0.15],
	["barleyfield_river", "res://maps/dong_mach_nha.tscn", Vector2(-1900, 0), 0.55],
]

var _cam: Camera2D
var _tag := "before"

func _ready() -> void:
	_tag = OS.get_environment("TERRAIN_TAG")
	if _tag == "":
		_tag = "before"
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_cam = Camera2D.new()
	add_child(_cam)
	_cam.make_current()
	_run()

func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _run() -> void:
	var only := OS.get_environment("TERRAIN_MAPS")
	for shot in SHOTS:
		var stem: String = shot[0]
		var map_path: String = shot[1]
		if only != "" and not only.split(",").has(stem):
			continue
		for c in get_children():
			if c != _cam:
				remove_child(c)
				c.queue_free()
		await _wait_frames(3)
		var ps: PackedScene = load(map_path)
		if ps == null:
			print("[TSHOT] LOAD FAIL ", map_path)
			continue
		var m: Node = ps.instantiate()
		add_child(m)
		var ov := m.get_node_or_null("OpeningOverlay")
		if ov != null:
			ov.queue_free()
		_cam.global_position = shot[2]
		_cam.zoom = Vector2.ONE * float(shot[3])
		await _wait_frames(50)
		var img := get_viewport().get_texture().get_image()
		var out: String = OUT_DIR + "/" + stem + "_" + _tag + ".png"
		var err := img.save_png(out)
		print("[TSHOT] ", out, " err=", err, " size=", img.get_size())
	print("[TSHOT] DONE tag=", _tag)
	get_tree().quit(0)
