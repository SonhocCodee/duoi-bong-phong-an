extends "res://enemies/enemy_base.gd"
## Heartwood Treant — MINI-BOSS vùng Đông (Elderwood).
## Thân golem phủ lá: golem_frames tint xanh lá đậm, scale 2.0, HP 300.
## Đòn thêm: khi đang combat (CHASE/ATTACK), mỗi summon_interval (7s)
## triệu hồi 1 slime con (slime.tscn), tối đa max_summons (3) lần.
## Boss HP bar: GameState.set_boss_display("Heartwood Treant", ...) khi
## _ready / trúng đòn (bọc has_method như boss_rat_king cho an toàn),
## clear khi chết qua _on_death(). Base đã lo XP/gold/QuestManager lúc chết.

const SLIME_SCENE: PackedScene = preload("res://enemies/slime.tscn")

@export var summon_interval: float = 7.0
@export var max_summons: int = 3

var summons_done: int = 0
var boss_display_active: bool = false
var _summon_timer: float = 7.0


func _ready() -> void:
	super._ready()
	_update_boss_display()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD or summons_done >= max_summons:
		return
	if state != State.CHASE and state != State.ATTACK:
		return # chỉ triệu hồi khi đang combat
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = summon_interval
		summon_minion()


## Triệu hồi 1 slime con cạnh boss. Phòng thủ current_scene/parent null.
func summon_minion() -> void:
	if state == State.DEAD or summons_done >= max_summons:
		return
	var parent: Node = get_parent()
	if parent == null and get_tree() != null:
		parent = get_tree().current_scene
	if parent == null:
		print("[%s] Bỏ qua triệu hồi: không có node cha/current_scene" % display_name)
		return
	summons_done += 1
	var minion: Node2D = SLIME_SCENE.instantiate()
	parent.add_child(minion)
	minion.global_position = global_position + Vector2(52, 20)
	print("[%s] Triệu hồi slime con (lần %d/%d)" % [display_name, summons_done, max_summons])


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, from_position)
	if state == State.DEAD:
		return # _on_death() đã clear boss display
	_update_boss_display()


func _update_boss_display() -> void:
	boss_display_active = true
	if has_node("/root/GameState") and GameState.has_method("set_boss_display"):
		GameState.set_boss_display(display_name, hp, max_hp)


func _clear_boss_display() -> void:
	boss_display_active = false
	if has_node("/root/GameState") and GameState.has_method("clear_boss_display"):
		GameState.clear_boss_display()


func _on_death() -> void:
	_clear_boss_display()
	print("[%s] Bị hạ! Heartwood ngừng đập, boss display đã clear." % display_name)
