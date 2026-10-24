extends Node2D
## Chup anh kiem chung HUD sau sua (chay qua xvfb-run, KHONG headless):
## HP/Stamina o goc tren phai + hang o skill nho o giua-duoi.
## godot --path game res://tools_paint/capture_hud.tscn

const OUT_PATH := "/home/hatch/workspace/game-phong-an/design/hud_after_fix.png"

var _cam: Camera2D
var _player: Node2D


func _ready() -> void:
	var ps: PackedScene = load("res://maps/lang_tan_diep.tscn")
	var map: Node = ps.instantiate()
	add_child(map)
	_player = map.get_node_or_null("Player") as Node2D
	_cam = Camera2D.new()
	_cam.zoom = Vector2.ONE
	add_child(_cam)
	_cam.make_current()
	_run()


func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _run() -> void:
	await _wait_frames(45) # cho HUD dung xong o skill + player on dinh
	if _player != null:
		_cam.global_position = _player.global_position
	await _wait_frames(6)
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(OUT_PATH)
	print("[HUDSHOT] ", OUT_PATH, " err=", err, " size=", img.get_size())
	print("[HUDSHOT] DONE")
	get_tree().quit(0)
