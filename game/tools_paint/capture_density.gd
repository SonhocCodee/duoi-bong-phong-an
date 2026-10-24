extends Node2D
## Chup anh TRUOC/SAU cho dot Density pass (TEAM 2-A).
## Chay qua xvfb-run (KHONG headless):
##   DENSITY_TAG=before xvfb-run -a godot --path game res://tools_paint/capture_density.tscn
##   DENSITY_TAG=after  xvfb-run -a godot --path game res://tools_paint/capture_density.tscn
## Anh luu vao design/density_shots/<map>_<tag>.png

const OUT_DIR := "/home/hatch/workspace/game-phong-an/design/density_shots"

# [file stem, map path, camera pos, zoom]
const SHOTS := [
	["elmford_a", "res://maps/lang_tan_diep.tscn", Vector2(150, 160), 0.85],
	["elmford_b", "res://maps/lang_tan_diep.tscn", Vector2(2500, -1500), 0.62],
	["aldenmere_a", "res://maps/thanh_xuan_lam.tscn", Vector2(-64, -100), 0.60],
	["aldenmere_b", "res://maps/thanh_xuan_lam.tscn", Vector2(7050, -1080), 0.80],
	["reedmere_a", "res://maps/reedmere.tscn", Vector2(120, 240), 0.75],
	["hearthwick_a", "res://maps/hearthwick.tscn", Vector2(32, 120), 0.75],
	["barleyfield_a", "res://maps/dong_mach_nha.tscn", Vector2(300, -100), 0.70],
	["sunwell_a", "res://maps/sunwell_oasis.tscn", Vector2(32, 60), 0.75],
]

var _cam: Camera2D
var _tag := "before"

func _ready() -> void:
	_tag = OS.get_environment("DENSITY_TAG")
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
	for shot in SHOTS:
		var stem: String = shot[0]
		var map_path: String = shot[1]
		# Free map truoc do (neu cung map thi tai dung cung duoc, nhung cu
		# load tuoi cho giong nhau giua cac shot)
		for c in get_children():
			if c != _cam:
				remove_child(c)
				c.queue_free()
		await _wait_frames(3)
		var ps: PackedScene = load(map_path)
		if ps == null:
			print("[DSHOT] LOAD FAIL ", map_path)
			continue
		var m: Node = ps.instantiate()
		add_child(m)
		# Elmford co OpeningOverlay intro che giua man hinh -> go bo de soi map
		var ov := m.get_node_or_null("OpeningOverlay")
		if ov != null:
			ov.queue_free()
		_cam.global_position = shot[2]
		_cam.zoom = Vector2.ONE * float(shot[3])
		await _wait_frames(50)
		var img := get_viewport().get_texture().get_image()
		var out: String = OUT_DIR + "/" + stem + "_" + _tag + ".png"
		var err := img.save_png(out)
		print("[DSHOT] ", out, " err=", err, " size=", img.get_size())
	print("[DSHOT] DONE tag=", _tag)
	get_tree().quit(0)
