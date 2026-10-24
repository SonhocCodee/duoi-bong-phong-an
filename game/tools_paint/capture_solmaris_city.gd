extends Node2D
## Chup 3 anh trong game cua Noi Thanh Solmaris (chay qua xvfb-run, KHONG headless):
## oc dao + dai phun / Grand Bazaar / khu bo lac ngoai tuong dong.
## godot --path game res://tools_paint/capture_solmaris_city.tscn

const OUT_DIR := "/home/hatch/workspace/game-phong-an/design/city_shots"
# Tam anh theo o layout: x=(c-120)*64+32, y=(r-85)*64+32
const SHOTS := [
	["solmaris_01_oc_dao.png", Vector2(96, -32), 0.36], # o (121,84): toan ho + dai phun + diem hen
	["solmaris_02_grand_bazaar.png", Vector2(-3552, 672), 0.48], # o (64,95): 2 day sap + thuong nhan
	["solmaris_03_khu_bo_lac.png", Vector2(6752, -1376), 0.6], # o (225,63): cum leu bac + lua trai
]

var _cam: Camera2D

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var ps: PackedScene = load("res://maps/solmaris.tscn")
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
