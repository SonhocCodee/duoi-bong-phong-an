extends Area2D
## HerbPickup - Cụm thảo dược nhặt được. Agent bản đồ đặt sẵn trong map.
## Player chạm vào: báo QuestManager.on_item_collected(item_id) rồi biến mất.

@export var item_id: String = "herb"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	print("[HerbPickup] Player nhặt thảo dược: ", item_id)
	if has_node("/root/QuestManager"):
		QuestManager.on_item_collected(item_id)
	# Đợt 6: thảo nhặt được cũng vào kho nguyên liệu chế tạo thật.
	if item_id == "herb" and has_node("/root/GameState") and GameState.has_method("add_material"):
		GameState.add_material("herb", 1)
	queue_free()
