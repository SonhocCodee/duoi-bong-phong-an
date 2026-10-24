extends CanvasLayer
## HUD - Thanh HP / Stamina, nhãn Gold / XP / Level
## Cập nhật qua signal của Player và GameState.

@onready var hp_bar: ProgressBar = $TopLeftBars/VBox/HPBar
@onready var stamina_bar: ProgressBar = $TopLeftBars/VBox/StaminaBar
@onready var hp_label: Label = $TopLeftBars/VBox/HPBar/HPLabel
@onready var stamina_label: Label = $TopLeftBars/VBox/StaminaBar/StaminaLabel
@onready var info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var quest_label: Label = $MarginContainer/VBoxContainer/QuestLabel
@onready var potion_label: Label = $MarginContainer/VBoxContainer/PotionLabel
@onready var boss_container: VBoxContainer = $BossContainer
@onready var boss_name_label: Label = $BossContainer/BossNameLabel
@onready var boss_bar: ProgressBar = $BossContainer/BossBar
@onready var skill_label: Label = $MarginContainer/VBoxContainer/SkillLabel

const SKILL_FRAME_TEX: Texture2D = preload("res://assets/ui/skill_frame.png")
const QUEST_LOG_SCENE: PackedScene = preload("res://ui/quest_log_panel.tscn")
const SKILL_PANEL_SCENE: PackedScene = preload("res://ui/skill_panel.tscn")

var _player: Node = null
var _quest_log: CanvasLayer = null
var _skill_panel: CanvasLayer = null
var _skill_box_labels: Dictionary = {} # skill_id -> Label trạng thái trong ô skill giữa-dưới
var _skill_box_panels: Dictionary = {} # skill_id -> PanelContainer
var _level_up_label: Label = null
var _level_up_tween: Tween = null
var _last_level: int = 1


func _ready() -> void:
	# Sổ quest: preload + add_child bằng code thay vì instance trong hud.tscn
	# (ít rủi ro vỡ scene text, thứ tự khởi tạo do HUD kiểm soát hoàn toàn).
	_quest_log = QUEST_LOG_SCENE.instantiate()
	add_child(_quest_log)
	_skill_panel = SKILL_PANEL_SCENE.instantiate()
	add_child(_skill_panel)
	_build_skill_boxes()
	# Banner LEVEL UP cũng tạo bằng code (giữa-phía trên màn hình, chữ lớn vàng).
	_level_up_label = Label.new()
	_level_up_label.name = "LevelUpLabel"
	_level_up_label.anchor_left = 0.5
	_level_up_label.anchor_right = 0.5
	_level_up_label.anchor_top = 0.0
	_level_up_label.anchor_bottom = 0.0
	_level_up_label.offset_left = -460.0
	_level_up_label.offset_right = 460.0
	_level_up_label.offset_top = 92.0
	_level_up_label.offset_bottom = 140.0
	_level_up_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_up_label.add_theme_font_size_override("font_size", 30)
	_level_up_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_level_up_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_level_up_label.add_theme_constant_override("shadow_offset_x", 2)
	_level_up_label.add_theme_constant_override("shadow_offset_y", 2)
	_level_up_label.visible = false
	add_child(_level_up_label)
	# Nối signal GameState
	if has_node("/root/GameState"):
		_last_level = GameState.level
		GameState.gold_changed.connect(_on_gold_changed)
		GameState.xp_changed.connect(_on_xp_changed)
		GameState.level_changed.connect(_on_level_changed)
		GameState.player_hp_changed.connect(_on_game_hp_changed)
		GameState.potions_changed.connect(_on_potions_changed)
		GameState.boss_changed.connect(_on_boss_changed)
		GameState.stats_changed.connect(_on_stats_changed)
		if GameState.has_signal("skills_changed"):
			GameState.skills_changed.connect(func(_p: int, _u: Array) -> void: _refresh_skill_ui())
	if has_node("/root/QuestManager"):
		QuestManager.quest_updated.connect(_on_quest_updated)
		QuestManager.quest_completed.connect(_on_quest_completed)
	_refresh_info()
	_refresh_quest()
	_refresh_potions()
	if has_node("/root/GameState"):
		_on_boss_changed(GameState.boss_name, GameState.boss_hp, GameState.boss_max_hp)
	# Thử tìm player ngay (nếu HUD được thêm sau player thì _process sẽ nối tiếp)
	_try_connect_player()


# --- Ô skill giữa-dưới (dựng bằng code như banner/quest log) ---------------
# Đợt 6: 2 TRANG skill — phím Q lật trang (player.skill_page giữ trạng thái).
# Trang 1 = 9 skill cũ (phím 1-9). Trang 2 = 4 skill cuối (phím 1-4).
const SKILL_PAGE1: Array = ["chem_xoay", "xung_kich", "cuong_no", "dau_an_lua", "bay_hon", "hut_sinh_luc",
	"cau_lua", "gai_bang", "set_lan"]
const SKILL_PAGE2: Array = ["trieu_hoi_bong", "cong_phong_an", "khien_ma_thuat", "mua_thien_thach"]
const SKILL_ORDER: Array = ["chem_xoay", "xung_kich", "cuong_no", "dau_an_lua", "bay_hon", "hut_sinh_luc",
	"cau_lua", "gai_bang", "set_lan"]
const SKILL_SHORT: Dictionary = {"chem_xoay": "CX", "xung_kich": "XK", "cuong_no": "CN",
	"dau_an_lua": "ĐAL", "bay_hon": "BH", "hut_sinh_luc": "HSL",
	"cau_lua": "CL", "gai_bang": "GB", "set_lan": "SL",
	"trieu_hoi_bong": "THB", "cong_phong_an": "CPA", "khien_ma_thuat": "KMT", "mua_thien_thach": "MTT"}
const SKILL_KEYS: Dictionary = {"chem_xoay": "1", "xung_kich": "2", "cuong_no": "3",
	"dau_an_lua": "4", "bay_hon": "5", "hut_sinh_luc": "6",
	"cau_lua": "7", "gai_bang": "8", "set_lan": "9",
	"trieu_hoi_bong": "1", "cong_phong_an": "2", "khien_ma_thuat": "3", "mua_thien_thach": "4"}
# Màu viền ô theo nhánh: Chiến binh đỏ, Thuật Đen tím, Pháp Sư xanh dương.
const SKILL_BORDER_COLORS: Dictionary = {
	"chem_xoay": Color(0.9, 0.3, 0.2), "xung_kich": Color(0.9, 0.3, 0.2), "cuong_no": Color(0.9, 0.3, 0.2),
	"dau_an_lua": Color(0.62, 0.3, 0.9), "bay_hon": Color(0.62, 0.3, 0.9), "hut_sinh_luc": Color(0.62, 0.3, 0.9),
	"cau_lua": Color(0.3, 0.55, 1.0), "gai_bang": Color(0.3, 0.55, 1.0), "set_lan": Color(0.3, 0.55, 1.0),
	"trieu_hoi_bong": Color(0.62, 0.3, 0.9), "cong_phong_an": Color(0.62, 0.3, 0.9),
	"khien_ma_thuat": Color(0.3, 0.55, 1.0), "mua_thien_thach": Color(0.3, 0.55, 1.0),
}

var _skill_hbox: HBoxContainer = null
var _hud_skill_page: int = 1


func _page_skills(page: int) -> Array:
	return SKILL_PAGE2 if page == 2 else SKILL_PAGE1


func _build_skill_boxes() -> void:
	if _skill_hbox == null:
		_skill_hbox = HBoxContainer.new()
		_skill_hbox.name = "SkillBoxContainer"
		# Hàng skill nhỏ gọn ở GIỮA-DƯỚI màn hình (neo giữa, không che nhân vật).
		_skill_hbox.anchor_left = 0.5
		_skill_hbox.anchor_top = 1.0
		_skill_hbox.anchor_right = 0.5
		_skill_hbox.anchor_bottom = 1.0
		_skill_hbox.offset_left = -252.0
		_skill_hbox.offset_top = -62.0
		_skill_hbox.offset_right = 252.0
		_skill_hbox.offset_bottom = -10.0
		_skill_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		_skill_hbox.add_theme_constant_override("separation", 6)
		add_child(_skill_hbox)
	for c in _skill_hbox.get_children():
		_skill_hbox.remove_child(c)
		c.queue_free()
	_skill_box_labels.clear()
	_skill_box_panels.clear()
	var hbox := _skill_hbox
	for sid in _page_skills(_hud_skill_page):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(50, 50)
		# Khung o skill = texture cham khac (skill_frame.png, tong sang
		# trung tinh) nhuom mau theo nhanh bang modulate: mau vien cu
		# tron voi trang 35% de khong bi dam/mau bu.
		var sb := StyleBoxTexture.new()
		sb.texture = SKILL_FRAME_TEX
		sb.texture_margin_left = 14.0
		sb.texture_margin_top = 14.0
		sb.texture_margin_right = 14.0
		sb.texture_margin_bottom = 14.0
		sb.content_margin_left = 3.0
		sb.content_margin_top = 3.0
		sb.content_margin_right = 3.0
		sb.content_margin_bottom = 3.0
		var bc: Color = SKILL_BORDER_COLORS.get(sid, Color(0.9, 0.3, 0.2))
		sb.modulate_color = bc.lerp(Color(1, 1, 1), 0.35)
		panel.add_theme_stylebox_override("panel", sb)
		# Hai dòng: tên tắt + phím (tĩnh) / trạng thái-CD (động, _skill_box_labels).
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 0)
		var name_lbl := Label.new()
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.text = "%s [%s]" % [SKILL_SHORT[sid], SKILL_KEYS[sid]]
		vbox.add_child(name_lbl)
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.text = "🔒"
		vbox.add_child(lbl)
		panel.add_child(vbox)
		hbox.add_child(panel)
		_skill_box_labels[sid] = lbl
		_skill_box_panels[sid] = panel


func _refresh_skill_ui() -> void:
	# Đồng bộ trang skill từ player (phím Q lật trang ở player.gd)
	if _player != null and _player.get("skill_page") != null:
		var p: int = int(_player.get("skill_page"))
		if p != _hud_skill_page:
			_hud_skill_page = p
			_build_skill_boxes()
	# Đọc trạng thái từ player (cooldown) + GameState (điểm / đã mở khoá)
	var pts: int = 0
	if has_node("/root/GameState"):
		pts = GameState.get_skill_points()
	var parts: Array[String] = []
	for sid in _page_skills(_hud_skill_page):
		var def: Dictionary = {}
		if has_node("/root/GameState"):
			def = GameState.SKILL_DEFS.get(sid, {})
		var sname: String = str(def.get("name", sid))
		var unlocked: bool = has_node("/root/GameState") and GameState.is_skill_unlocked(sid)
		var cd: float = 0.0
		if _player != null and _player.has_method("get_skill_cooldown"):
			cd = float(_player.call("get_skill_cooldown", sid))
		var status: String
		if not unlocked:
			status = "🔒"
		elif cd > 0.05:
			status = "%.0fs" % cd
		else:
			status = "Sẵn sàng"
		parts.append("[%s] %s: %s" % [SKILL_KEYS[sid], sname, status])
		# Ô skill giữa-dưới: dòng trạng thái (tên tắt + phím nằm ở dòng tĩnh phía trên)
		if _skill_box_labels.has(sid):
			var bl: Label = _skill_box_labels[sid]
			if not unlocked:
				bl.text = "🔒"
			elif cd > 0.05:
				bl.text = "%.1fs" % cd
			else:
				bl.text = "✓"
	if skill_label != null:
		var da_sat_txt: String = "✓" if (has_node("/root/GameState") and GameState.is_skill_unlocked("da_sat")) else "🔒"
		skill_label.text = "Skill (trang %d/2, [Q] lật) — Điểm: %d | %s | Da Sắt: %s | [T] cây skill" % [
			_hud_skill_page, pts, " | ".join(parts), da_sat_txt]


func _process(_delta: float) -> void:
	if _player == null:
		_try_connect_player()
	_refresh_skill_ui()
	# Toggle sổ quest bằng phím J (action "quest_log")
	if _quest_log != null and Input.is_action_just_pressed("quest_log"):
		if _quest_log.visible:
			_quest_log.hide_panel()
		else:
			_quest_log.show_panel()
	# Toggle cây skill bằng phím T (action "skill_tree")
	if _skill_panel != null and Input.is_action_just_pressed("skill_tree"):
		if _skill_panel.visible:
			_skill_panel.hide_panel()
		else:
			_skill_panel.show_panel()


func _try_connect_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	_player = players[0]
	if _player.has_signal("health_changed"):
		if not _player.health_changed.is_connected(_on_player_health):
			_player.health_changed.connect(_on_player_health)
	if _player.has_signal("stamina_changed"):
		if not _player.stamina_changed.is_connected(_on_player_stamina):
			_player.stamina_changed.connect(_on_player_stamina)
	# Đồng bộ lần đầu (dùng get() cho an toàn với Object)
	var hp_val: Variant = _player.get("hp")
	var max_hp_val: Variant = _player.get("max_hp")
	if hp_val != null and max_hp_val != null:
		_on_player_health(int(hp_val), int(max_hp_val))
	var sta_val: Variant = _player.get("stamina")
	var max_sta_val: Variant = _player.get("max_stamina")
	if sta_val != null and max_sta_val != null:
		_on_player_stamina(float(sta_val), float(max_sta_val))


func _on_player_health(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_label.text = "HP %d / %d" % [current_hp, max_hp]


func _on_game_hp_changed(current_hp: int, max_hp: int) -> void:
	# Chỉ dùng khi chưa nối được player trực tiếp
	if _player == null:
		_on_player_health(current_hp, max_hp)


func _on_player_stamina(current_stamina: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
	stamina_label.text = "STA %d / %d" % [int(current_stamina), int(max_stamina)]


func _on_gold_changed(_g: int) -> void:
	_refresh_info()

func _on_xp_changed(_x: int, _l: int) -> void:
	_refresh_info()

func _on_level_changed(l: int) -> void:
	_refresh_info()
	# Banner nổi bật CHỈ khi level thực sự tăng (không phải reset/load phát lại).
	if l > _last_level:
		_show_level_up_banner(l)
	_last_level = l


func _on_stats_changed(_atk: int, _def: int) -> void:
	_refresh_info()


func _show_level_up_banner(l: int) -> void:
	if _level_up_label == null:
		return
	_level_up_label.text = "★ LEVEL UP! Đạt cấp %d — +10 HP tối đa, +2 Tấn công ★" % l
	_level_up_label.modulate = Color(1, 1, 1, 1)
	_level_up_label.visible = true
	if _level_up_tween != null and _level_up_tween.is_valid():
		_level_up_tween.kill()
	_level_up_tween = create_tween()
	_level_up_tween.tween_interval(2.2)
	_level_up_tween.tween_property(_level_up_label, "modulate:a", 0.0, 0.8)
	_level_up_tween.tween_callback(func() -> void: _level_up_label.visible = false)


func _refresh_info() -> void:
	if not is_node_ready():
		return
	if has_node("/root/GameState"):
		# ATK hiệu dụng = damage hit 1 gốc (10) + bonus trang bị + 2/cấp trên 1
		var atk: int = 10 + GameState.attack_bonus + (GameState.level - 1) * 2
		info_label.text = "Level %d  |  XP %d / %d  |  Vàng: %d  |  ATK %d  |  DEF %d" % [
			GameState.level, GameState.xp, GameState.xp_to_next_level, GameState.gold,
			atk, GameState.defense_bonus
		]
	else:
		info_label.text = "Level 1  |  XP 0  |  Vàng: 0  |  ATK 10  |  DEF 0"


func _on_potions_changed(_n: int) -> void:
	_refresh_potions()


func _refresh_potions() -> void:
	if not is_node_ready() or potion_label == null:
		return
	if has_node("/root/GameState"):
		potion_label.text = "Bình: %d | Đại bình: %d — [H] dùng" % [GameState.potions, GameState.greater_potions]


# Thanh máu boss: hiện khi GameState.set_boss_display, ẩn khi clear_boss_display
func _on_boss_changed(display_name: String, hp: int, max_hp: int) -> void:
	if not is_node_ready() or boss_container == null:
		return
	if display_name == "" or max_hp <= 0:
		boss_container.visible = false
		return
	boss_container.visible = true
	boss_name_label.text = display_name
	boss_bar.max_value = max_hp
	boss_bar.value = hp


func _on_quest_updated(_id: String) -> void:
	_refresh_quest()

func _on_quest_completed(_id: String) -> void:
	_refresh_quest()


func _refresh_quest() -> void:
	if not is_node_ready() or quest_label == null:
		return
	if not has_node("/root/QuestManager"):
		quest_label.text = ""
		return
	# Chỉ theo dõi quest active đầu tiên (gồm cả quest đang chờ trả ready_turn_in)
	for qid in QuestManager.active_quests:
		var q: Dictionary = QuestManager.get_quest(qid)
		if q.is_empty():
			continue
		var line := "Nhiệm vụ: %s (%d/%d)" % [str(q.get("title", qid)), int(q.get("progress", 0)), int(q.get("target_count", 0))]
		if str(q.get("status", "")) == "ready_turn_in":
			line += " — Quay lại trả nhiệm vụ!"
		quest_label.text = line
		return
	# Không còn quest active
	if QuestManager.completed_quests.size() > 0:
		quest_label.text = "Nhiệm vụ: Đã hoàn thành nhiệm vụ Elmford ✓"
	else:
		quest_label.text = ""
