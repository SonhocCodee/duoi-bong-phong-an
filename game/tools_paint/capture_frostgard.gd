extends Node2D
## Chup 3 anh trong game cua Noi thanh Frostgard (chay qua xvfb-run, KHONG headless):
## Lo Lon trung tam / Nghia trang quan doan + Dai Danh Sach / Sanh Ngai Bang.
## Mo phong capture_city.gd. Toa do camera = tam o layout qua cong thuc
## x=(c-120)*64+32, y=(r-85)*64+32.
## godot --path game res://tools_paint/capture_frostgard.tscn

const OUT_DIR := "/home/hatch/workspace/game-phong-an/design/city_shots"
const SHOTS := [
	["frostgard_01_lo_lon.png", Vector2(32, 224), 0.58],
	["frostgard_02_nghia_trang.png", Vector2(-5280, 160), 0.38],
	["frostgard_03_ngai_bang.png", Vector2(32, -3520), 0.55],
]

var _cam: Camera2D

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var ps: PackedScene = load("res://maps/frostgard.tscn")
	var city: Node = ps.instantiate()
	add_child(city)
	_cam = Camera2D.new()
	_cam.zoom = Vector2(0.9, 0.9)
	add_child(_cam)
	_cam.make_current()
	_run()

func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _run() -> void:
	print("[SHOT] start, cho 90 frame...")
	await _wait_frames(90)
	print("[SHOT] bat dau chup")
	for shot in SHOTS:
		_cam.global_position = shot[1] as Vector2
		_cam.zoom = Vector2.ONE * float(shot[2])
		await _wait_frames(12)
		var img := get_viewport().get_texture().get_image()
		var path: String = OUT_DIR + "/" + str(shot[0])
		var err := img.save_png(path)
		print("[SHOT] ", path, " err=", err, " size=", img.get_size())
	print("[SHOT] DONE")
	get_tree().quit(0)
