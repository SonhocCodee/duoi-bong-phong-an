extends "res://enemies/enemy_base.gd"
## Sói xám — quái nhanh nhất đám thường vùng Đông (speed 165).
## HÀNH VI BẦY: khi một con sói vào CHASE, nó "tru gọi bầy": mọi sói khác
## (enemy_type == "wolf") trong bán kính pack_radius (260) đang IDLE cũng
## chuyển sang CHASE. Quét theo chu kỳ pack_scan_interval, có cooldown
## gọi bầy pack_call_cooldown để không spam quét mỗi frame.

@export var pack_radius: float = 260.0
@export var pack_scan_interval: float = 0.25
@export var pack_call_cooldown: float = 1.0

var _pack_scan_timer: float = 0.0
var _pack_call_timer: float = 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD:
		return
	if _pack_call_timer > 0.0:
		_pack_call_timer -= delta
	_pack_scan_timer -= delta
	if _pack_scan_timer > 0.0:
		return
	_pack_scan_timer = pack_scan_interval
	if state == State.CHASE and _pack_call_timer <= 0.0:
		_call_pack()


## Được sói đầu đàn gọi: bật dậy đuổi theo player.
func alert_from_pack() -> void:
	if state == State.IDLE:
		state = State.CHASE
		print("[%s] Nghe tiếng tru gọi bầy -> vào CHASE" % display_name)


func _call_pack() -> void:
	_pack_call_timer = pack_call_cooldown
	var called := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e == self or not is_instance_valid(e):
			continue
		if str(e.get("enemy_type")) != "wolf":
			continue
		if not (e is Node2D):
			continue
		if global_position.distance_to((e as Node2D).global_position) > pack_radius:
			continue
		if int(e.get("state")) == State.IDLE:
			if e.has_method("alert_from_pack"):
				e.alert_from_pack()
			else:
				e.set("state", State.CHASE)
			called += 1
	if called > 0:
		print("[%s] Tru gọi bầy: +%d sói cùng đuổi theo" % [display_name, called])
