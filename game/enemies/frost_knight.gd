extends "res://enemies/enemy_base.gd"
## Hiệp Sĩ Băng — Frostgard (Lv 19-24). Dân Bắc bị Trụ Hàn đóng băng
## nửa chừng: khi "đang nhớ" (remembering) họ chỉ gác theo ca cũ, detect
## rất ngắn (70px) — chỉ đánh khi player lại rất gần. Bị đánh trúng lần
## đầu thì ký ức vỡ ra: họ nhớ tên mình, detect trở về đầy đủ và đánh
## như địch thường. Đây là điểm khác biệt cốt truyện của quái Bắc:
## farm chúng là farm người đang cố nhớ mình là ai.

const MEMORY_LINES: Array[String] = [
	"Ta... còn ca gác nữa...",
	"Chuông... sao chuông không rung?",
	"Tên ta là... ta có tên mà...",
	"Lò... lò còn cháy không?",
	"Đội trưởng... tên đội trưởng là gì?",
]

@export var remembering: bool = true

var base_detect_range: float = 300.0
var last_memory_line: String = ""


func _ready() -> void:
	super._ready()
	base_detect_range = detect_range
	if remembering:
		detect_range = 70.0


func _physics_process(delta: float) -> void:
	# Đồng bộ khi code ngoài (boss triệu hồi / builder map) tắt remembering
	# SAU khi _ready đã chạy: khôi phục tầm phát hiện đầy đủ.
	if not remembering and base_detect_range > 0.0 and is_equal_approx(detect_range, 70.0):
		detect_range = base_detect_range
	super._physics_process(delta)


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if remembering and state != State.DEAD:
		remembering = false
		detect_range = base_detect_range
		last_memory_line = MEMORY_LINES[int(abs(get_instance_id())) % MEMORY_LINES.size()]
		print("[%s] KÝ ỨC VỠ RA: \"%s\"" % [display_name, last_memory_line])
	super.take_damage(amount, from_position)
