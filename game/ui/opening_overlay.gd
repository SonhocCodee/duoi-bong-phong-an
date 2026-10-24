extends CanvasLayer
## OpeningOverlay — "đạo diễn" đoạn mở đầu ở Elmford (chỉ instance ở
## lang_tan_diep.tscn) + banner hoàn thành đoạn mở đầu.
##
## MỞ ĐẦU CHƠI ĐƯỢC (thay cho panel chữ trơ của bản cũ):
## - Người chơi xuất hiện ở CỔNG NAM Elmford (vị trí Player / Spawn_start
##   trong scene), không còn bị thả giữa làng.
## - Giai đoạn 1: nhãn mục tiêu bảo NÓI CHUYỆN VỚI NGƯỜI GÁC CỔNG
##   (NPC "gac_cong" — Bác Từ, đứng ngay cổng). Thoại của ông dựng bối
##   cảnh (lính thuế King Aldric chèn ép, kho lúa bị chuột phá) và chỉ
##   đường; npc.gd đặt cờ "opening_gate_done" khi thoại kết thúc.
## - Giai đoạn 2: mục tiêu = ĐI TỚI NHÀ TRƯỞNG LÀNG ở phía tây bắc làng
##   và nói chuyện với ông. Trưởng làng giao dong_01_goblin qua cơ chế
##   thoại/quest có sẵn của npc.gd — nhận được quest (hoặc đã qua mốc
##   đó) là mở đầu hoàn thành: đặt cờ intro_seen, ẩn nhãn mục tiêu.
## - BỎ QUA: bấm Esc (ui_cancel) bất cứ lúc nào, trừ khi đang trong hội
##   thoại -> skip_opening(): đặt đủ cờ như đã chơi hết mở đầu; trạng
##   thái sau đó y như bản cũ (intro_seen = true, dong_01 vẫn nhận
##   được ở Trưởng làng). Người chơi lại không bị ép xem lại.
## - Panel chữ giới thiệu cũ: BỎ HẲN — toàn bộ nội dung của nó đã được
##   chuyển vào thoại gác cổng + thoại Trưởng làng. Node IntroCenter
##   trong .tscn giữ nguyên nhưng không bao giờ hiện nữa.
## - Banner "ĐOẠN MỞ ĐẦU HOÀN THÀNH" khi flag mo_dau_xong xuất hiện:
##   GIỮ NGUYÊN hành vi bản cũ (báo 7 giây, một lần duy nhất).

const BANNER_TEXT: String = "ĐOẠN MỞ ĐẦU HOÀN THÀNH — Đường đi Stonebridge và Elderwood đã mở. Kháng chiến đang tìm bạn..."
const OBJECTIVE_GATE_TEXT: String = "— MỞ ĐẦU —  Nói chuyện với Bác Từ, người gác cổng (tới gần rồi bấm E)   •   [Esc] Bỏ qua mở đầu"
const OBJECTIVE_ELDER_TEXT: String = "— MỞ ĐẦU —  Tới nhà Trưởng làng ở phía tây bắc làng, gặp ông để nhận việc đầu tiên   •   [Esc] Bỏ qua mở đầu"

# Giai đoạn mở đầu: 0 = không chạy (đã xong / không áp dụng),
# 1 = chờ nói chuyện với gác cổng, 2 = chờ tới nhà Trưởng làng.
var opening_stage: int = 0

var _poll_timer: float = 0.0
var _banner_shown_this_session: bool = false
var _banner_visible: bool = false
var _banner_timer: float = 0.0
var _objective_panel: PanelContainer = null
var _objective_label: Label = null

@onready var intro_center: CenterContainer = $IntroCenter
@onready var banner_panel: PanelContainer = $BannerPanel
@onready var banner_label: Label = $BannerPanel/BannerLabel


func _ready() -> void:
	banner_label.text = BANNER_TEXT
	banner_panel.visible = false
	# Panel chữ cũ: không bao giờ hiện nữa (xem ghi chú đầu file).
	intro_center.visible = false
	_build_objective_ui()
	# Xác định giai đoạn từ cờ đã lưu (hỗ trợ cả save đang chơi dở mở đầu).
	if not has_node("/root/GameState") or GameState.get_flag("intro_seen"):
		opening_stage = 0
	elif GameState.get_flag("opening_gate_done"):
		opening_stage = 2
	else:
		opening_stage = 1
	_update_objective_ui()


## Nhãn mục tiêu mở đầu dựng bằng code (như HUD vẫn làm) để không phải
## sửa .tscn: panel nhỏ ở giữa-phía trên, dưới vị trí banner.
func _build_objective_ui() -> void:
	_objective_panel = PanelContainer.new()
	_objective_panel.name = "ObjectivePanel"
	_objective_panel.anchor_left = 0.5
	_objective_panel.anchor_right = 0.5
	_objective_panel.anchor_top = 0.0
	_objective_panel.anchor_bottom = 0.0
	_objective_panel.offset_left = -320.0
	_objective_panel.offset_right = 430.0
	_objective_panel.offset_top = 74.0
	_objective_panel.offset_bottom = 118.0
	_objective_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.03, 0.85)
	sb.border_color = Color(0.85, 0.7, 0.35, 1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	_objective_panel.add_theme_stylebox_override("panel", sb)
	_objective_label = Label.new()
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.add_theme_font_size_override("font_size", 15)
	_objective_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7, 1))
	_objective_panel.add_child(_objective_label)
	_objective_panel.visible = false
	add_child(_objective_panel)


func _update_objective_ui() -> void:
	if _objective_panel == null:
		return
	match opening_stage:
		1:
			_objective_label.text = OBJECTIVE_GATE_TEXT
			_objective_panel.visible = true
		2:
			_objective_label.text = OBJECTIVE_ELDER_TEXT
			_objective_panel.visible = true
		_:
			_objective_panel.visible = false


func is_opening_active() -> bool:
	return opening_stage > 0


## Mở đầu hoàn thành theo nhịp chơi tự nhiên (đã nhận dong_01 từ
## Trưởng làng): chỉ đặt intro_seen — phần còn lại của game không đổi.
func finish_opening() -> void:
	if opening_stage == 0:
		return
	opening_stage = 0
	if has_node("/root/GameState"):
		GameState.set_flag("intro_seen")
	_update_objective_ui()
	print("[OpeningOverlay] Đoạn mở đầu kết thúc (đã gặp Trưởng làng).")


## Bỏ qua mở đầu: đặt đủ cờ như đã chơi hết (gồm cả cờ gác cổng) để
## không còn trạng thái treo nào về sau; dong_01 vẫn nhận ở Trưởng làng.
func skip_opening() -> void:
	if opening_stage == 0:
		return
	opening_stage = 0
	if has_node("/root/GameState"):
		GameState.set_flag("opening_gate_done")
		GameState.set_flag("intro_seen")
	_update_objective_ui()
	print("[OpeningOverlay] Người chơi BỎ QUA đoạn mở đầu.")


func _unhandled_input(event: InputEvent) -> void:
	if opening_stage == 0:
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	# Đang trong hội thoại thì Esc không bỏ qua — nghe hết thoại đã
	# (thoại chính là nội dung mở đầu).
	if has_node("/root/GameState") and GameState.in_dialogue:
		return
	get_viewport().set_input_as_handled()
	skip_opening()


func _process(delta: float) -> void:
	# Banner đang hiện: đếm ngược 7 giây rồi tự ẩn (không khóa player).
	if _banner_visible:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner_visible = false
			banner_panel.visible = false
		return
	_poll_timer += delta
	if _poll_timer < 0.25:
		return
	_poll_timer = 0.0
	if not has_node("/root/GameState"):
		return
	# --- Nhịp mở đầu: theo dõi cờ gác cổng + trạng thái dong_01 ---
	if opening_stage == 1 and GameState.get_flag("opening_gate_done"):
		opening_stage = 2
		_update_objective_ui()
	if opening_stage > 0 and has_node("/root/QuestManager"):
		var st: String = str(QuestManager.get_quest("dong_01_goblin").get("status", ""))
		if st == "active" or st == "ready_turn_in" or st == "completed":
			finish_opening()
	# --- Banner hoàn thành đoạn mở đầu (giữ nguyên bản cũ) ---
	if _banner_shown_this_session:
		return
	if GameState.get_flag("mo_dau_bao_xong"):
		_banner_shown_this_session = true
		return
	if GameState.get_flag("mo_dau_xong"):
		_banner_shown_this_session = true
		_banner_visible = true
		_banner_timer = 7.0
		banner_panel.visible = true
		GameState.set_flag("mo_dau_bao_xong")
		print("[OpeningOverlay] Đã báo hoàn thành đoạn mở đầu.")
