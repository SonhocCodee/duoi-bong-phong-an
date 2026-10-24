extends Node2D
## Chup 3 anh trong game cua Thanh Aldenmere (chay qua xvfb-run, KHONG headless):
## quang truong / hem dan cu Tay / mat tuong Nam.
## godot --path game res://tools_paint/capture_city.tscn

const OUT_DIR := "/home/hatch/workspace/game-phong-an/design/city_shots"
const SHOTS := [
	["01_quang_truong.png", Vector2(-32, -992), 0.62],
	["02_hem_dan_cu.png", Vector2(-3264, 1728), 1.05],
	["03_mat_tuong.png", Vector2(-800, 5664), 0.58],
]

var _cam: Camera2D

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var ps: PackedScene = load("res://maps/thanh_xuan_lam.tscn")
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
	await _wait_frames(90) # cho NPC vao lich trinh, sprite on dinh
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
