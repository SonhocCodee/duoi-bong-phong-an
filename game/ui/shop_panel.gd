extends CanvasLayer
## ShopPanel - Cửa hàng đơn giản (mở sau khi nói chuyện với NPC shop_enabled).
## Chốt GĐ1: chỉ bán 1 loại "Bình máu" 10 vàng — dùng bằng phím H, hồi 50 HP.
## Mua: GameState.add_gold(-10) + GameState.add_potions(1).
## Đóng bằng nút Đóng, Esc hoặc interact. Khi mở: khóa di chuyển của player.

signal shop_closed

const POTION_PRICE: int = 10

var _opened_msec: int = 0

@onready var gold_label: Label = $CenterContainer/PanelContainer/VBoxContainer/GoldLabel
@onready var potions_label: Label = $CenterContainer/PanelContainer/VBoxContainer/PotionsLabel
@onready var buy_button: Button = $CenterContainer/PanelContainer/VBoxContainer/BuyButton
@onready var close_button: Button = $CenterContainer/PanelContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	buy_button.pressed.connect(func() -> void: buy_potion())
	close_button.pressed.connect(close_shop)
	if has_node("/root/GameState"):
		GameState.gold_changed.connect(func(_g: int) -> void: _refresh())
		GameState.potions_changed.connect(func(_n: int) -> void: _refresh())
	_refresh()


func open_shop() -> void:
	visible = true
	_opened_msec = Time.get_ticks_msec()
	if has_node("/root/GameState"):
		GameState.in_dialogue = true
	_refresh()


func close_shop() -> void:
	visible = false
	if has_node("/root/GameState"):
		GameState.in_dialogue = false
	shop_closed.emit()
	queue_free()


func buy_potion() -> bool:
	if not has_node("/root/GameState"):
		return false
	if GameState.gold < POTION_PRICE:
		_refresh()
		return false
	GameState.add_gold(-POTION_PRICE)
	GameState.add_potions(1)
	print("[Shop] Mua 1 Bình máu (-%d vàng). Còn %d vàng, %d bình." % [POTION_PRICE, GameState.gold, GameState.potions])
	_refresh()
	return true


func _refresh() -> void:
	if not is_node_ready() or not has_node("/root/GameState"):
		return
	gold_label.text = "Vàng của bạn: %d" % GameState.gold
	potions_label.text = "Bình máu đang có: %d" % GameState.potions
	buy_button.disabled = GameState.gold < POTION_PRICE
	buy_button.text = "Mua Bình máu (%d vàng)" % POTION_PRICE


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Bỏ qua input trong 250ms đầu (cú bấm vừa kết thúc thoại mở shop)
	if Time.get_ticks_msec() - _opened_msec < 250:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_shop()
