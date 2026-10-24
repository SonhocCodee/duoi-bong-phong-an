extends Node2D
## Chup 3 anh nghiem thu NOI THANH FENMIRE (chay qua xvfb-run, KHONG headless):
## hem van nha san (chup som, NPC con o san van) / be cho noi (cho Linh Tuan
## Kenh di xuong giua khung) / den + san doi chat.
## godot --path game res://tools_paint/capture_fenmire.tscn

const OUT_DIR := "/home/hatch/workspace/game-phong-an/design/city_shots"

var _cam: Camera2D

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var ps: PackedScene = load("res://maps/fenmire.tscn")
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

func _shoot(fname: String, pos: Vector2, zoom: float) -> void:
	_cam.global_position = pos
	_cam.zoom = Vector2.ONE * zoom
	await _wait_frames(12)
	var img := get_viewport().get_texture().get_image()
	var path: String = OUT_DIR + "/" + fname
	var err := img.save_png(path)
	print("[SHOT] ", path, " err=", err, " size=", img.get_size())

func _run() -> void:
	print("[SHOT] start, cho 600 frame cho NPC vao lich trinh...")
	await _wait_frames(600)
	# Anh 2 truoc: Truong Dan Chai con o khu san van / hem Chuong Trieu
	await _shoot("fenmire_02_hem_nha_san.png", Vector2(-3680, -224), 1.0)
	# Anh 3 o moc ~16s: Dai Giao Si dang di ngang phia tay den (con thay ro
	# tren nen san, chua bi mai den che nhu khi da toi truoc cua den)
	print("[SHOT] cho 12s (Dai Giao Si tren duong vao den)...")
	await get_tree().create_timer(12.0).timeout
	await _shoot("fenmire_03_den.png", Vector2(-32, 3296), 0.5)
	# Anh 1 sau cung (~34s): Linh Tuan Kenh da xuong doan san cong / bo kenh
	print("[SHOT] cho 18s nua (Linh Tuan Kenh xuong kenh)...")
	await get_tree().create_timer(18.0).timeout
	await _shoot("fenmire_01_cho_noi.png", Vector2(-224, -3552), 0.42)
	print("[SHOT] DONE")
	get_tree().quit(0)
