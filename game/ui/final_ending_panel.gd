extends CanvasLayer
## FinalEndingPanel - Màn hình chọn ENDING ở Bệ Phong Ấn (Đợt 6).
## Chỉ mở từ SealAltar tại Đài Sigilspire sau khi boss cuối gục
## (flag "final_boss_dead"). 3 lựa chọn ending -> QuestManager.accept
## quest thap_05a/b/c (complete_on_accept, khoá 2 lựa chọn còn lại) ->
## GameState chốt game_completed/ending_id qua flag ending_* -> tự lưu
## game. Epilogue đọc flags hậu quả THẬT của 4 vùng từ GameState.
## Sau khi chọn: "Chơi tiếp tự do" (post-game free roam, đóng panel)
## hoặc "Về menu chính". choose_ending()/build_epilogue_text() là API
## public cho test gọi trực tiếp.

const ENDING_QUESTS: Dictionary = {
	"ending_phong_an_moi": "thap_05a_phong_an_moi",
	"ending_pha_an": "thap_05b_pha_an",
	"ending_thay_the": "thap_05c_thay_the",
}
const ENDING_TITLES: Dictionary = {
	"ending_phong_an_moi": "PHONG ẤN MỚI",
	"ending_pha_an": "PHÁ ẤN",
	"ending_thay_the": "THAY THẾ",
}

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var epilogue_label: Label = $CenterContainer/PanelContainer/VBoxContainer/EpilogueLabel
@onready var status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatusLabel
@onready var btn_a: Button = $CenterContainer/PanelContainer/VBoxContainer/EndingButtonA
@onready var btn_b: Button = $CenterContainer/PanelContainer/VBoxContainer/EndingButtonB
@onready var btn_c: Button = $CenterContainer/PanelContainer/VBoxContainer/EndingButtonC
@onready var continue_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ButtonRow/ContinueButton
@onready var menu_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ButtonRow/MenuButton


func _ready() -> void:
	visible = false
	btn_a.pressed.connect(func() -> void: choose_ending("ending_phong_an_moi"))
	btn_b.pressed.connect(func() -> void: choose_ending("ending_pha_an"))
	btn_c.pressed.connect(func() -> void: choose_ending("ending_thay_the"))
	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func _flag(key: String) -> bool:
	return has_node("/root/GameState") and GameState.get_flag(key)


## Hiện panel + khóa di chuyển của player. Public để altar/test gọi.
func show_panel() -> void:
	_refresh()
	visible = true
	if has_node("/root/GameState"):
		GameState.in_dialogue = true
	print("[FinalEndingPanel] Mở màn hình chọn ending ở Bệ Phong Ấn.")


## Chọn 1 trong 3 ending. Trả false nếu chưa hạ boss cuối / đã chọn rồi /
## quest bị chặn. Thành công: chốt quest + game_completed + autosave.
func choose_ending(ending_key: String) -> bool:
	if not ENDING_QUESTS.has(ending_key):
		return false
	if not has_node("/root/GameState") or not has_node("/root/QuestManager"):
		return false
	if GameState.game_completed:
		print("[FinalEndingPanel] Đã chọn ending từ trước: %s" % GameState.ending_id)
		return false
	if not GameState.get_flag("final_boss_dead"):
		print("[FinalEndingPanel] Chưa hạ boss cuối — Bệ Phong Ấn chưa mở.")
		return false
	var qid: String = str(ENDING_QUESTS[ending_key])
	if not QuestManager.accept_quest(qid):
		print("[FinalEndingPanel] Không nhận được quest ending %s." % qid)
		return false
	# complete_on_accept + không turn-in -> quest đã completed trong
	# accept_quest, flag ending_* đã set -> GameState đã chốt completed.
	if has_node("/root/SaveSystem"):
		SaveSystem.save_game()
	_refresh()
	print("[FinalEndingPanel] ĐÃ CHỌN ENDING: %s" % str(ENDING_TITLES.get(ending_key, ending_key)))
	return true


func _refresh() -> void:
	var chosen: String = ""
	if has_node("/root/GameState"):
		chosen = GameState.ending_id
	if chosen != "":
		title_label.text = "KẾT CỤC — %s" % str(ENDING_TITLES.get(chosen, chosen))
	else:
		title_label.text = "BỆ PHONG ẤN — HÃY QUYẾT ĐỊNH"
	epilogue_label.text = build_epilogue_text(chosen)
	var done: bool = chosen != ""
	btn_a.disabled = done
	btn_b.disabled = done
	btn_c.disabled = done
	btn_a.visible = not done
	btn_b.visible = not done
	btn_c.visible = not done
	if done:
		status_label.text = "Đã lưu game. Bạn có thể chơi tiếp tự do (post-game) hoặc về menu chính."
	else:
		status_label.text = "Ba con đường, không con đường nào vô tội. Chọn một — hai con đường còn lại sẽ đóng vĩnh viễn."


## Toàn văn epilogue: đoạn mở theo ending + hậu quả CỤ THỂ từng vùng
## đọc từ flags + đoạn kết. ending_key rỗng = trạng thái chưa chọn
## (chỉ hiện phần nhắc hậu quả + lời của Seraphine vọng lại).
func build_epilogue_text(ending_key: String = "") -> String:
	var key: String = ending_key
	if key == "" and has_node("/root/GameState"):
		key = GameState.ending_id
	var lines: Array[String] = []
	match key:
		"ending_phong_an_moi":
			lines.append("Seraphine ở lại trong tháp — nhưng không còn là bí mật, không còn là tù nhân câm lặng. Bản thỏa thuận mới được đọc to ở cả bốn thành: từ nay cái giá của phong ấn do cả vương quốc cùng biết, cùng gánh, và cứ mỗi đời lại được thương lượng lại. Cô vẫn là vật phong ấn sống; nhưng lần đầu tiên, đó là lựa chọn của cô, được ghi thành chữ.")
		"ending_pha_an":
			lines.append("Nghi lễ phá ấn của vua được hoàn tất bởi chính tay bạn. Seraphine bước ra khỏi Tầng 6 lần đầu tiên trong đời — tự do, và run rẩy. Thứ bị giam cũng ra ngoài, theo điều kiện khắc trên Bệ: nó rời khỏi vùng đất của người, và không ai biết chắc nó sẽ giữ lời bao lâu. Vương quốc thức dậy trong một thế giới không còn ấn — nhẹ nhõm, và không còn gì che chắn.")
		"ending_thay_the":
			lines.append("Bạn ngồi xuống vị trí neo ấn ở Tầng 6, và Seraphine — khóc, cười, không tin nổi — bước xuống tháp thay bạn. Vương quốc giữ được phong ấn; một cô gái giữ được cuộc đời. Còn bạn ở lại giữa những trang sử ấn, nghe tháp thở, như mọi đời người gác trước bạn. Không ai trên đời này gọi đó là thua cuộc. Cũng không ai dám gọi đó là chiến thắng.")
		_:
			lines.append("Vua đã gục. Dây rối đứt. Chỉ còn Bệ Phong Ấn giữa Đài — và Seraphine đang chờ ở Tầng 6, chờ xem người đã đi qua cả bốn vùng sẽ quyết định thế nào. Cô từng nói: 'Đừng cứu ta theo quán tính cổ tích. Hãy cứu cả vương quốc này — kể cả khi cách cứu không giống trong truyện.'")
	lines.append("")
	lines.append("— HÀNH TRÌNH CỦA BẠN, GHI LẠI TRONG ẤN —")
	lines.append_array(_region_lines())
	if key != "":
		lines.append("")
		lines.append("★ DƯỚI BÓNG PHONG ẤN — HẾT ★")
		lines.append("Cảm ơn bạn đã đi hết bốn vùng đất. Vương quốc này ghi nhớ cách bạn đã sống trong nó, không chỉ cách bạn kết thúc nó.")
	return "\n".join(PackedStringArray(lines))


## Hậu quả cụ thể từng vùng, đọc flags thật (không có flag = nhánh còn lại).
func _region_lines() -> Array[String]:
	var lines: Array[String] = []
	# --- ĐÔNG (Aldenmere) ---
	if _flag("tram_thue_pha"):
		lines.append("Đông: Trạm thuế Stonebridge đã sập — đường qua sông Clearwater từ đó không còn trạm thu của vua.")
	if _flag("co_duong_cong"):
		lines.append("Đông: Phu mỏ Bluestone Mine được giải phóng; Aldenmere khởi nghĩa từ bên trong và tự đứng lên trước cả khi bạn lên tháp.")
	if _flag("golem_dead"):
		lines.append("Đông: Mossback gục ngã — Elderwood yên bình, Misthaven lại ra khơi.")
	# --- NAM (Fenmire) ---
	if _flag("nam_thuoc_tre"):
		lines.append("Nam: Phần thuốc ngoài sổ năm ấy đã cứu đám trẻ bệnh nặng ở Fevercamp — chúng lớn lên biết tên người đã chọn mình.")
	elif _flag("nam_thuoc_gia"):
		lines.append("Nam: Phần thuốc ngoài sổ đã cứu những người già giữ nghề — nghề chài và nghề thuốc của Fenmire còn người truyền lại.")
	elif _flag("nam_thuoc_nuoi_nha"):
		lines.append("Nam: Phần thuốc ngoài sổ đã cứu những người nuôi cả nhà — nhiều mái nhà ở Fenmire không bị bỏ trống.")
	if _flag("nam_end_giu_thoa_thuan"):
		lines.append("Nam: Fenmire giữ thỏa thuận với giáo phái nhưng tước độc quyền sổ thuốc — dịch được kiểm soát, vùng vẫn là chư hầu của Tháp.")
	elif _flag("nam_end_giu_trieu_moi"):
		lines.append("Nam: Giáo phái bị đuổi, triều được giữ bằng cách mới — Fenmire tự do, dù cái giá chưa dừng ở đó.")
	elif _flag("nam_end_pha_chu_ky"):
		lines.append("Nam: Chu kỳ triều nhân tạo bị phá — không ai chết vì nghi lễ nữa.")
	if _flag("nam_mat_nguoi"):
		lines.append("Nam: Nhưng một số bệnh nặng đã không qua khỏi khi thuốc bị cắt đột ngột. Fenmire ghi tên họ cạnh tên người giải phóng — cả hai việc cùng lúc.")
	if _flag("nam_ngheo_di"):
		lines.append("Nam: Và Fenmire nghèo đi rõ rệt khi nguồn nước ngọt cạn dần theo chu kỳ triều đã mất.")
	# --- TÂY (Solmaris) ---
	if _flag("vesskar_song"):
		lines.append("Tây: Vesskar còn sống — rồng cát canh bão như một đồng minh tự do, không phải tù nhân của lời thề bị đánh cắp.")
	elif _flag("vesskar_chet"):
		lines.append("Tây: Vesskar đã chết dưới tay bạn. Bão cát Solmaris mất kẻ giữ nhịp và mất kiểm soát — các bộ lạc học cách sống chung với nó, khó khăn hơn xưa.")
	if _flag("lien_minh_bo_lac"):
		lines.append("Tây: Liên minh hai bộ lạc vẫn đứng — Solmaris lần đầu có một tiếng nói không phải của lính đánh thuê.")
	# --- BẮC (Frostgard) ---
	if _flag("linh_hon_sieu_thoat"):
		lines.append("Bắc: Quân đoàn Frostgard được gọi đúng tên — Ysolde, Bram, Odric, Sigrun, Tomas và vua của họ — và siêu thoát. Hearthwick thắp lò cho những người cuối cùng cũng được về nhà.")
	elif _flag("linh_hon_van_vat"):
		lines.append("Bắc: Linh hồn quân đoàn Frostgard còn vất vưởng — nguyền đã vỡ nhưng không ai gọi tên họ, nên họ vẫn gác, vô định, quanh những bức tường không còn vua.")
	return lines


func _on_continue_pressed() -> void:
	visible = false
	if has_node("/root/GameState"):
		GameState.in_dialogue = false
	print("[FinalEndingPanel] Đóng panel — chơi tiếp tự do (post-game free roam).")


func _on_menu_pressed() -> void:
	if has_node("/root/GameState"):
		GameState.in_dialogue = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
