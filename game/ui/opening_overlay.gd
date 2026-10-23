extends CanvasLayer
## OpeningOverlay - Intro mở đầu + banner hoàn thành đoạn mở đầu.
## Chỉ instance ở Elmford (lang_tan_diep.tscn).
## - Lần đầu vào làng (chưa có flag intro_seen): hiện panel giới thiệu giữa
##   màn hình, khóa player qua GameState.in_dialogue; bấm interact/attack
##   (sau 150ms chống bấm nhầm) để đóng và set_flag("intro_seen").
## - Poll 0.5s: khi flag mo_dau_xong đã có mà chưa từng báo (flag
##   mo_dau_bao_xong chưa có) thì hiện banner trên cùng 7 giây rồi tự ẩn,
##   đồng thời set_flag("mo_dau_bao_xong") để không bao giờ báo lần 2.

const INTRO_TEXT: String = "Bạn là lính đánh thuê trắng tay vừa tới Elmford, trong túi không còn nổi một xu dính túi. Ngôi làng từng yên bình nay bị lính thuế của King Aldric chèn ép, mùa màng bị vét sạch để cống nạp lên thành. Kho lúa và Elmford Cellar — nguồn sống của cả làng — đang bị bầy chuột phá hoại, còn goblin lảng vảng ở bìa rừng khiến không ai dám ra đồng. Dân làng kiệt quệ, chỉ còn biết trông chờ vào một người lạ có kiếm như bạn. Hãy gặp Trưởng làng (phím E) để nhận việc đầu tiên, giúp làng yên ổn rồi mới tính chuyện đi xa."
const BANNER_TEXT: String = "ĐOẠN MỞ ĐẦU HOÀN THÀNH — Đường đi Stonebridge và Elderwood đã mở. Kháng chiến đang tìm bạn..."

var _intro_active: bool = false
var _opened_msec: int = 0
var _poll_timer: float = 0.0
var _banner_shown_this_session: bool = false
var _banner_visible: bool = false
var _banner_timer: float = 0.0

@onready var intro_panel: PanelContainer = $IntroCenter/IntroPanel
@onready var intro_center: CenterContainer = $IntroCenter
@onready var intro_label: Label = $IntroCenter/IntroPanel/VBoxContainer/IntroLabel
@onready var banner_panel: PanelContainer = $BannerPanel
@onready var banner_label: Label = $BannerPanel/BannerLabel


func _ready() -> void:
	intro_label.text = INTRO_TEXT
	banner_label.text = BANNER_TEXT
	banner_panel.visible = false
	intro_center.visible = false
	if has_node("/root/GameState") and not GameState.get_flag("intro_seen"):
		_show_intro()


func _show_intro() -> void:
	_intro_active = true
	_opened_msec = Time.get_ticks_msec()
	intro_center.visible = true
	if has_node("/root/GameState"):
		GameState.in_dialogue = true


func _close_intro() -> void:
	_intro_active = false
	intro_center.visible = false
	if has_node("/root/GameState"):
		GameState.set_flag("intro_seen")
		GameState.in_dialogue = false


func _unhandled_input(event: InputEvent) -> void:
	if not _intro_active:
		return
	if Time.get_ticks_msec() - _opened_msec < 150:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		_close_intro()


func _process(delta: float) -> void:
	# Banner đang hiện: đếm ngược 7 giây rồi tự ẩn (không khóa player).
	if _banner_visible:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner_visible = false
			banner_panel.visible = false
		return
	# Poll 0.5s kiểm tra hoàn thành đoạn mở đầu.
	_poll_timer += delta
	if _poll_timer < 0.5:
		return
	_poll_timer = 0.0
	if _banner_shown_this_session:
		return
	if not has_node("/root/GameState"):
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
