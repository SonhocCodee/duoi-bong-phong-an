extends Node
## QuestManager - Autoload quản lý nhiệm vụ
## Quest lưu dạng Dictionary: id, title, region, status, xp_reward, gold_reward...
## Field mở rộng (GĐ1): target_type (loại quái cần giết), collect_type (vật phẩm
## cần nhặt), requires_turn_in + turn_in_npc (đủ tiến độ thì phải quay lại NPC
## trả nhiệm vụ mới nhận thưởng), required_quest (quest phải completed trước).
## status: "available" | "active" | "ready_turn_in" | "completed"

signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_updated(quest_id: String)

var quests: Dictionary = {}
var active_quests: Array[String] = []
var completed_quests: Array[String] = []


func _ready() -> void:
	_register_starter_quests()
	_register_fenmire_quests()
	_register_solmaris_quests()
	_register_frostgard_quests()
	_register_sigilspire_quests()


## Reset toàn bộ quest về trạng thái đăng ký ban đầu (dùng cho "Chơi mới").
func reset_quests() -> void:
	quests.clear()
	active_quests.clear()
	completed_quests.clear()
	_register_starter_quests()
	_register_fenmire_quests()
	_register_solmaris_quests()
	_register_frostgard_quests()
	_register_sigilspire_quests()
	print("[QuestManager] Đã reset toàn bộ quest.")


func _register_starter_quests() -> void:
	# Bộ quest vùng Đông — Vertical Slice (Elmford + Elmford Cellar)
	_add_quest({
		"id": "dong_01_goblin",
		"quest_type": "main",
		"title": "Dẹp Goblin ở bìa rừng Elmford",
		"region": "dong",
		"description": "Tiêu diệt 3 goblin quấy phá làng Elmford, rồi báo lại Trưởng làng.",
		"target_type": "goblin",
		"target_count": 3,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_lang",
		"xp_reward": 30,
		"gold_reward": 20,
		"reputation_reward": 5,
		"status": "available",
	})
	_add_quest({
		"id": "dong_02_ham_ruou",
		"quest_type": "main",
		"title": "Chuột phá Elmford Cellar",
		"region": "dong",
		"description": "Xuống Elmford Cellar diệt 5 con chuột phá thùng rượu, rồi báo lại Chủ quán.",
		"required_quest": "dong_01_goblin",
		"target_type": "rat",
		"target_count": 5,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "chu_quan",
		"xp_reward": 50,
		"gold_reward": 35,
		"reputation_reward": 8,
		"status": "available",
	})
	_add_quest({
		"id": "dong_03_chuot_chua",
		"quest_type": "main",
		"title": "The Rat King dưới Elmford Cellar",
		"region": "dong",
		"description": "Tiêu diệt The Rat King ở đáy Elmford Cellar, rồi báo lại Chủ quán.",
		"required_quest": "dong_02_ham_ruou",
		"target_type": "boss_rat_king",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "chu_quan",
		"set_flag": "mo_dau_xong",
		"xp_reward": 120,
		"gold_reward": 80,
		"reputation_reward": 15,
		"status": "available",
	})
	_add_quest({
		"id": "dong_side_herb",
		"quest_type": "side",
		"title": "Thảo dược cho quán trọ",
		"region": "dong",
		"description": "Thu thập 4 thảo dược quanh làng cho Chủ quán nấu thuốc.",
		"collect_type": "herb",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "chu_quan",
		"xp_reward": 25,
		"gold_reward": 15,
		"reputation_reward": 3,
		"status": "available",
	})
	_add_quest({
		"id": "dong_side_slime",
		"quest_type": "side",
		"title": "Slime cỏ phá ruộng",
		"region": "dong",
		"description": "Diệt 5 slime cỏ phá ruộng ngoài làng, rồi báo lại Thợ rèn.",
		"target_type": "slime",
		"target_count": 5,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "tho_ren",
		"xp_reward": 40,
		"gold_reward": 25,
		"reputation_reward": 5,
		"status": "available",
	})


	_add_quest({
		"id": "dong_04_golem",
		"title": "Mossback, the Moss Golem",
		"region": "dong",
		"description": "Hạ Mossback, the Moss Golem trong Moss Den — hang rêu dưới chân Cloudpeak, nơi BossGolem đang ở — lấy lại bình yên cho thành.",
		"quest_type": "main",
		"target_type": "boss_golem",
		"target_count": 1,
		"progress": 0,
		"required_quest": "dong_06_giai_phu",
		"requires_turn_in": true,
		"turn_in_npc": "linh_gac",
		"xp_reward": 200,
		"gold_reward": 100,
		"reputation_reward": 20,
		"status": "available",
	})
	_add_quest({
		"id": "dong_05_tram_thue",
		"title": "Phá trạm thuế Stonebridge",
		"region": "dong",
		"description": "Đánh đuổi 3 lính thuế của vua ở trạm thu thuế Stonebridge trên sông Clearwater.",
		"quest_type": "main",
		"target_type": "soldier",
		"target_count": 3,
		"progress": 0,
		"required_quest": "dong_03_chuot_chua",
		"requires_turn_in": true,
		"turn_in_npc": "truong_lang",
		"set_flag": "tram_thue_pha",
		"xp_reward": 150,
		"gold_reward": 80,
		"reputation_reward": 15,
		"status": "available",
	})
	_add_quest({
		"id": "dong_06_giai_phu",
		"title": "Giải phóng phu Bluestone Mine",
		"region": "dong",
		"description": "Đánh đuổi 4 tên đốc công sơn tặc ở Bluestone Mine để giải phóng phu mỏ bị bắt.",
		"quest_type": "main",
		"target_type": "bandit",
		"target_count": 4,
		"progress": 0,
		"required_quest": "dong_05_tram_thue",
		"requires_turn_in": true,
		"turn_in_npc": "dan_tandiep_1",
		"set_flag": "co_duong_cong",
		"xp_reward": 180,
		"gold_reward": 100,
		"reputation_reward": 20,
		"status": "available",
	})
	_add_quest({
		"id": "dong_08_cong_ngam",
		"title": "Đột nhập qua Aldenmere Sewers",
		"region": "dong",
		"description": "Phu mỏ được giải phóng tiết lộ đường cống nối Bluestone Mine → Aldenmere Sewers → thẳng vào Royal Palace; hãy theo đường cống vào tới Royal Palace.",
		"quest_type": "main",
		"target_map": "hoang_cung",
		"target_count": 1,
		"progress": 0,
		"required_quest": "dong_04_golem",
		"requires_turn_in": false,
		"turn_in_npc": "",
		"set_flag": "da_dot_nhap",
		"xp_reward": 150,
		"gold_reward": 50,
		"reputation_reward": 10,
		"status": "available",
	})
	_add_quest({
		"id": "dong_07_vua",
		"title": "Lật đổ King Aldric",
		"region": "dong",
		"description": "Đột nhập Royal Palace of Aldenmere qua Aldenmere Sewers và đánh bại King Aldric cùng kẻ thao túng sau lưng hắn.",
		"quest_type": "main",
		"target_type": "boss_vua",
		"target_count": 1,
		"progress": 0,
		"required_quest": "dong_08_cong_ngam",
		"requires_turn_in": false,
		"turn_in_npc": "",
		"set_flag": "dong_giai_phong",
		"xp_reward": 400,
		"gold_reward": 250,
		"reputation_reward": 40,
		"status": "available",
	})


## Tuyến Phần 2 — Vùng Nam Fenmire (điều tra + lựa chọn đạo đức).
## Thiết kế: design/fenmire_so_do.md §5. Cơ chế lựa chọn: quest có
## "complete_on_accept" (nhận = đã chọn) + "blocks_quests" (khoá các lựa
## chọn còn lại sang status "locked") + "set_flags" (nhiều flag hậu quả,
## game ghi sổ cho epilogue). Gating bằng "required_flag" khi cần.
func _register_fenmire_quests() -> void:
	_add_quest({
		"id": "nam_01_den_fenmire",
		"quest_type": "main",
		"title": "Đến Fenmire",
		"region": "nam",
		"description": "Giáo phái chặn thùng thuốc của Reedmere ở bìa Drownedwood. Diệt 3 con Đỉa Bùn giữ đường, rồi báo lại Trưởng làng Reedmere.",
		"target_type": "mire_leech",
		"target_count": 3,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_reedmere",
		"xp_reward": 220,
		"gold_reward": 100,
		"reputation_reward": 6,
		"status": "available",
	})
	_add_quest({
		"id": "nam_02_danh_sach_thuoc",
		"quest_type": "main",
		"title": "Danh Sách Thuốc",
		"region": "nam",
		"description": "Fevercamp thiếu thuốc: sổ phát thuốc của giáo phái chỉ ghi một nửa danh sách bệnh. Thu 3 thảo dược đầm mang về cho Y sĩ trưởng trạm để trạm tự sắc thêm thuốc ngoài sổ.",
		"required_quest": "nam_01_den_fenmire",
		"collect_type": "herb",
		"target_count": 3,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "y_si_tram",
		"set_flag": "co_so_thuoc",
		"xp_reward": 180,
		"gold_reward": 60,
		"reputation_reward": 4,
		"status": "available",
	})
	# --- Lựa chọn nhỏ 1: thuốc chỉ đủ cho một nhóm người (nam_02a/b/c) ---
	_add_quest({
		"id": "nam_02a_thuoc_tre",
		"quest_type": "main",
		"title": "Thuốc Cho Trẻ Bệnh Nặng",
		"region": "nam",
		"description": "LỰA CHỌN: dành phần thuốc ngoài sổ cho đám trẻ bệnh nặng ở Fevercamp. Chọn đường này thì hai nhóm còn lại không có thuốc.",
		"required_quest": "nam_02_danh_sach_thuoc",
		"complete_on_accept": true,
		"blocks_quests": ["nam_02b_thuoc_gia", "nam_02c_thuoc_nuoi_nha"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "y_si_tram",
		"set_flags": ["nam_thuoc_tre", "da_chon_thuoc"],
		"xp_reward": 60,
		"gold_reward": 0,
		"reputation_reward": 2,
		"status": "available",
	})
	_add_quest({
		"id": "nam_02b_thuoc_gia",
		"quest_type": "main",
		"title": "Thuốc Cho Người Già Giữ Nghề",
		"region": "nam",
		"description": "LỰA CHỌN: dành phần thuốc ngoài sổ cho những người già giữ nghề chài và nghề thuốc của vùng. Chọn đường này thì hai nhóm còn lại không có thuốc.",
		"required_quest": "nam_02_danh_sach_thuoc",
		"complete_on_accept": true,
		"blocks_quests": ["nam_02a_thuoc_tre", "nam_02c_thuoc_nuoi_nha"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "benh_nhan_1",
		"set_flags": ["nam_thuoc_gia", "da_chon_thuoc"],
		"xp_reward": 60,
		"gold_reward": 0,
		"reputation_reward": 2,
		"status": "available",
	})
	_add_quest({
		"id": "nam_02c_thuoc_nuoi_nha",
		"quest_type": "main",
		"title": "Thuốc Cho Người Nuôi Cả Nhà",
		"region": "nam",
		"description": "LỰA CHỌN: dành phần thuốc ngoài sổ cho những lao động chính đang nuôi cả gia đình. Chọn đường này thì hai nhóm còn lại không có thuốc.",
		"required_quest": "nam_02_danh_sach_thuoc",
		"complete_on_accept": true,
		"blocks_quests": ["nam_02a_thuoc_tre", "nam_02b_thuoc_gia"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "me_goa",
		"set_flags": ["nam_thuoc_nuoi_nha", "da_chon_thuoc"],
		"xp_reward": 60,
		"gold_reward": 0,
		"reputation_reward": 2,
		"status": "available",
	})
	# --- Lựa chọn 2: vườn nấm của giáo phái ở Venomfen (nam_03a/b) ---
	_add_quest({
		"id": "nam_03a_pha_vuon",
		"quest_type": "main",
		"title": "Phá Vườn Nấm",
		"region": "nam",
		"description": "LỰA CHỌN: phá vườn nấm độc của giáo phái ở Venomfen — diệt 4 con Ếch Độc canh vườn. Nguồn thuốc thử bị cắt, nhưng thuốc thật của dân cũng vơi theo.",
		"required_flag": "da_chon_thuoc",
		"complete_on_accept": false,
		"blocks_quests": ["nam_03b_ghi_chung_cu"],
		"target_type": "swamp_frog",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "dan_say_1",
		"set_flags": ["pha_vuon_nam", "co_chung_cu"],
		"xp_reward": 260,
		"gold_reward": 80,
		"reputation_reward": 5,
		"status": "available",
	})
	_add_quest({
		"id": "nam_03b_ghi_chung_cu",
		"quest_type": "main",
		"title": "Để Nguyên Vườn Nấm, Ghi Chứng Cứ",
		"region": "nam",
		"description": "LỰA CHỌN: không phá vườn nấm. Tới Venomfen, lấy lọ thuốc thử và sổ tay thu hái ở lều bỏ hoang làm chứng cứ B, mang về cho dân làng Reedmere giữ.",
		"required_flag": "da_chon_thuoc",
		"complete_on_accept": false,
		"blocks_quests": ["nam_03a_pha_vuon"],
		"target_map": "venomfen",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "dan_say_1",
		"set_flags": ["ghi_chung_cu", "co_chung_cu"],
		"xp_reward": 260,
		"gold_reward": 80,
		"reputation_reward": 5,
		"status": "available",
	})
	_add_quest({
		"id": "nam_04_duong_thuy",
		"quest_type": "main",
		"title": "Người Dân Chài Giấu",
		"region": "nam",
		"description": "Dân chài Blackmere nhờ dọn bầy Đỉa Bùn chắn đường thủy (diệt 4 con), đổi lại họ mở đường thủy Drownedwood ↔ Blackmere và kể phiên bản của Người Giữ Triều (chứng cứ C).",
		"required_flag": "co_chung_cu",
		"target_type": "mire_leech",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_dan_chai_ho",
		"set_flags": ["mo_duong_thuy", "chung_cu_c"],
		"xp_reward": 320,
		"gold_reward": 140,
		"reputation_reward": 8,
		"status": "available",
	})
	_add_quest({
		"id": "nam_05_den_chim_trieu",
		"quest_type": "main",
		"title": "Đền Chìm Triều",
		"region": "nam",
		"description": "Vào Sunken Tide Temple lúc triều rút, xuống phòng sâu nhất và đánh bại Đại Tư Tế Morvain — kẻ giữ sổ thuốc và chìa triều của giáo phái.",
		"required_quest": "nam_04_duong_thuy",
		"target_type": "boss_high_priest",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_dan_chai_ho",
		"set_flag": "qua_den",
		"xp_reward": 600,
		"gold_reward": 300,
		"reputation_reward": 12,
		"status": "available",
	})
	# --- LỰA CHỌN CUỐI PHẦN (nam_06a/b/c): không đáp án sạch ---
	_add_quest({
		"id": "nam_06a_giu_thoa_thuan",
		"quest_type": "main",
		"title": "Đối Chất: Giữ Thỏa Thuận, Cải Tổ Từ Trong",
		"region": "nam",
		"description": "KẾT PHẦN — LỰA CHỌN A: giữ thỏa thuận với giáo phái nhưng tước độc quyền sổ thuốc, Morvain làm giám sát. Dịch được kiểm soát, Fenmire vẫn là chư hầu của Tháp.",
		"required_quest": "nam_05_den_chim_trieu",
		"complete_on_accept": true,
		"blocks_quests": ["nam_06b_giu_trieu_moi", "nam_06c_pha_chu_ky"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "y_si_tram",
		"set_flags": ["nam_end_giu_thoa_thuan", "nam_giai_phong"],
		"xp_reward": 400,
		"gold_reward": 200,
		"reputation_reward": 15,
		"status": "available",
	})
	_add_quest({
		"id": "nam_06b_giu_trieu_moi",
		"quest_type": "main",
		"title": "Đối Chất: Phá Thỏa Thuận, Khôi Phục Giữ Triều Mới",
		"region": "nam",
		"description": "KẾT PHẦN — LỰA CHỌN B: đuổi giáo phái, Morvain cùng Người Giữ Triều Già giữ triều bằng cách mới chưa kiểm chứng. Fenmire tự do — nhưng một số bệnh nặng sẽ không qua khỏi khi thuốc bị cắt đột ngột.",
		"required_quest": "nam_05_den_chim_trieu",
		"complete_on_accept": true,
		"blocks_quests": ["nam_06a_giu_thoa_thuan", "nam_06c_pha_chu_ky"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_dan_chai_ho",
		"set_flags": ["nam_end_giu_trieu_moi", "nam_mat_nguoi", "nam_giai_phong"],
		"xp_reward": 400,
		"gold_reward": 200,
		"reputation_reward": 15,
		"status": "available",
	})
	_add_quest({
		"id": "nam_06c_pha_chu_ky",
		"quest_type": "main",
		"title": "Đối Chất: Phá Chu Kỳ Triều",
		"region": "nam",
		"description": "KẾT PHẦN — LỰA CHỌN C: phá cơ chế triều nhân tạo của giáo phái. Không ai phải chết vì nghi lễ hay thuốc thử nữa, nhưng Fenmire mất nguồn nước ngọt dần và nghèo đi rõ rệt.",
		"required_quest": "nam_05_den_chim_trieu",
		"complete_on_accept": true,
		"blocks_quests": ["nam_06a_giu_thoa_thuan", "nam_06b_giu_trieu_moi"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_reedmere",
		"set_flags": ["nam_end_pha_chu_ky", "nam_ngheo_di", "nam_giai_phong"],
		"xp_reward": 400,
		"gold_reward": 200,
		"reputation_reward": 15,
		"status": "available",
	})
	# --- Quest phụ ---
	_add_quest({
		"id": "nam_side_herb",
		"quest_type": "side",
		"title": "Thảo Dược Ngoài Sổ",
		"region": "nam",
		"description": "Thu 4 thảo dược quanh Reedmere mang về cho dân làng — phần thuốc không nằm trong sổ của giáo phái.",
		"collect_type": "herb",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "dan_say_1",
		"xp_reward": 90,
		"gold_reward": 40,
		"reputation_reward": 2,
		"status": "available",
	})
	_add_quest({
		"id": "nam_side_croc",
		"quest_type": "side",
		"title": "Cá Sấu Ăn Đêm",
		"region": "nam",
		"description": "Diệt 2 con Cá Sấu Đầm rình bến Blackmere lúc đêm để dân chài dám ra khơi lại.",
		"target_type": "swamp_croc",
		"target_count": 2,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "dan_chai_ho_1",
		"xp_reward": 160,
		"gold_reward": 90,
		"reputation_reward": 3,
		"status": "available",
	})


## Tuyến Phần 3 — Vùng Tây Solmaris (LIÊN MINH BỘ LẠC + ĐẤU TRƯỜNG).
## Khác Đông (khởi nghĩa/đột nhập) và Nam (điều tra/lựa chọn thuốc):
## vua Tây đã chết, hội đồng lính đánh thuê cầm quyền, Vesskar canh cổng
## phong ấn. Hai bộ lạc có điều kiện gia nhập riêng; cuối phần người chơi
## chọn ĐÁNH hoặc ĐÀM PHÁN với Vesskar. Tên bộ lạc Dunehawk/Stonesong và
## tên chỉ huy Kassia Vane là ĐỀ XUẤT chờ user duyệt.
func _register_solmaris_quests() -> void:
	_add_quest({
		"id": "tay_01_den_solmaris",
		"quest_type": "main",
		"title": "Qua Cổng Tây Vào Solmaris",
		"region": "tay",
		"description": "Đoàn caravan chỉ mở đường sau khi Phần 2 xong. Diệt 4 con Bọ Cạp Cát phục kích quanh Westgate và Dunefield, rồi báo lại Hướng Dẫn Caravan ở Sunwell Oasis.",
		"required_flag": "nam_giai_phong",
		"target_type": "sand_scorpion",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "huong_dao_oc_dao",
		"xp_reward": 650,
		"gold_reward": 260,
		"reputation_reward": 6,
		"status": "available",
	})
	_add_quest({
		"id": "tay_02_nuoc_oc_dao",
		"quest_type": "main",
		"title": "Giữ Nước Cho Sunwell Oasis",
		"region": "tay",
		"description": "Rắn Cát chui vào mạch nước ngầm của Sunwell Oasis. Diệt 4 con quanh thị trấn và Dunefield, rồi báo lại Người Giữ Nước.",
		"required_quest": "tay_01_den_solmaris",
		"target_type": "sand_snake",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "nguoi_giu_nuoc",
		"set_flag": "oc_dao_on_dinh",
		"xp_reward": 720,
		"gold_reward": 300,
		"reputation_reward": 7,
		"status": "available",
	})
	_add_quest({
		"id": "tay_03a_dieu_cat",
		"quest_type": "main",
		"title": "Điều Kiện Của Bộ Lạc Diều Cát",
		"region": "tay",
		"description": "BỘ LẠC 1 (tên đề xuất: Dunehawk): họ chỉ liên minh với người dám dọn lính đánh thuê đào ngũ đang cướp caravan. Diệt 5 lính đánh thuê ở Redrock Canyon, rồi báo lại Thủ Lĩnh Diều Cát.",
		"required_quest": "tay_02_nuoc_oc_dao",
		"target_type": "mercenary",
		"target_count": 5,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "thu_linh_dieu_cat",
		"set_flag": "dieu_cat_dong_y",
		"xp_reward": 850,
		"gold_reward": 360,
		"reputation_reward": 10,
		"status": "available",
	})
	_add_quest({
		"id": "tay_03b_da_vang",
		"quest_type": "main",
		"title": "Điều Kiện Của Bộ Lạc Đá Vang",
		"region": "tay",
		"description": "BỘ LẠC 2 (tên đề xuất: Stonesong): họ cần bằng chứng vua cũ từng thề với Vesskar. Vào Buried Sand Ruins (tới được tàn tích là đủ ghi nhận hành trình), rồi quay lại gặp Pháp Sư Đá Vang.",
		"required_quest": "tay_03a_dieu_cat",
		"target_map": "buried_sand_ruins",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "phap_su_da_vang",
		"set_flags": ["da_vang_dong_y", "co_bang_chung_loi_the"],
		"xp_reward": 900,
		"gold_reward": 380,
		"reputation_reward": 10,
		"status": "available",
	})
	_add_quest({
		"id": "tay_04_lien_minh",
		"quest_type": "main",
		"title": "Dựng Liên Minh Sa Mạc",
		"region": "tay",
		"description": "Hai bộ lạc đã gật đầu. Gặp Trưởng Liên Minh ở Sunwell Oasis để đốt lửa thề: từ giờ hội đồng lính đánh thuê không còn là tiếng nói duy nhất của Solmaris.",
		"required_quest": "tay_03b_da_vang",
		"complete_on_accept": true,
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_lien_minh",
		"set_flag": "lien_minh_bo_lac",
		"xp_reward": 500,
		"gold_reward": 200,
		"reputation_reward": 12,
		"status": "available",
	})
	_add_quest({
		"id": "tay_05_dau_truong",
		"quest_type": "main",
		"title": "Đấu Trường Của Hội Đồng",
		"region": "tay",
		"description": "Thắng chỉ huy lính đánh thuê Kassia Vane (TÊN ĐỀ XUẤT) trong đấu trường ở Redrock Canyon, trước mặt dân và hai bộ lạc — phá huyền thoại rằng 'vua bất tử' cai trị Solmaris. Rồi báo lại Chủ Đấu Trường.",
		"required_quest": "tay_04_lien_minh",
		"target_type": "boss_mercenary_captain",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "chu_dau_truong",
		"set_flags": ["thang_dau_truong", "hoi_dong_suy_yeu"],
		"xp_reward": 1200,
		"gold_reward": 650,
		"reputation_reward": 14,
		"status": "available",
	})
	_add_quest({
		"id": "tay_06_gap_vesskar",
		"quest_type": "main",
		"title": "Vào Hang Vesskar",
		"region": "tay",
		"description": "Theo đường tàn tích vào Vesskar's Lair và đối mặt kẻ canh cổng phong ấn. Đừng vội rút kiếm: quay lại Trưởng Liên Minh sau khi đã tận mắt thấy Vesskar, lựa chọn cuối phần nằm ở đó.",
		"required_quest": "tay_05_dau_truong",
		"target_map": "vesskar_lair",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": false,
		"turn_in_npc": "",
		"set_flag": "da_gap_vesskar",
		"xp_reward": 700,
		"gold_reward": 250,
		"reputation_reward": 8,
		"status": "available",
	})
	# --- LỰA CHỌN CUỐI PHẦN: đánh hoặc đàm phán với Vesskar ---
	_add_quest({
		"id": "tay_07a_danh_vesskar",
		"quest_type": "main",
		"title": "Kết Phần: Giết Kẻ Canh Cổng",
		"region": "tay",
		"description": "LỰA CHỌN A — ĐÁNH: hạ Vesskar trong hang của nó và lấy Chìa Vảy Cát bằng sức mạnh. Nhanh và dứt khoát — nhưng bão cát Tây mất kẻ giữ nhịp vĩnh viễn. Giết xong quay lại Trưởng Liên Minh.",
		"required_quest": "tay_06_gap_vesskar",
		"complete_on_accept": false,
		"blocks_quests": ["tay_07b_dam_phan_vesskar"],
		"target_type": "boss_vesskar",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_lien_minh",
		"set_flags": ["tay_end_danh_vesskar", "vesskar_chet", "tay_bao_cat_mat_kiem_soat", "tay_giai_phong"],
		"xp_reward": 1500,
		"gold_reward": 900,
		"reputation_reward": 18,
		"status": "available",
	})
	_add_quest({
		"id": "tay_07b_dam_phan_vesskar",
		"quest_type": "main",
		"title": "Kết Phần: Trả Lại Lời Thề Cho Vesskar",
		"region": "tay",
		"description": "LỰA CHỌN B — ĐÀM PHÁN: dùng bằng chứng lời thề ở Buried Sand Ruins và uy tín liên minh để trả tự do cho Vesskar khỏi vai 'quái vật'. Nó tự nguyện trao Chìa Vảy Cát và tiếp tục canh bão cát — lần này như đồng minh, không phải tù nhân.",
		"required_quest": "tay_06_gap_vesskar",
		"complete_on_accept": true,
		"blocks_quests": ["tay_07a_danh_vesskar"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_lien_minh",
		"set_flags": ["tay_end_dam_phan", "vesskar_dam_phan", "vesskar_song", "loi_the_co_duoc_tra", "tay_giai_phong"],
		"xp_reward": 1500,
		"gold_reward": 700,
		"reputation_reward": 22,
		"status": "available",
	})
	# --- Quest phụ ---
	_add_quest({
		"id": "tay_side_vulture",
		"quest_type": "side",
		"title": "Kền Kền Rình Caravan",
		"region": "tay",
		"description": "Diệt 3 con Kền Kền Cát rình đoàn caravan quanh Dunefield, rồi báo lại Người Giữ Nước ở Sunwell Oasis.",
		"target_type": "sand_vulture",
		"target_count": 3,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "nguoi_giu_nuoc",
		"xp_reward": 420,
		"gold_reward": 220,
		"reputation_reward": 4,
		"status": "available",
	})
	_add_quest({
		"id": "tay_side_bones",
		"quest_type": "side",
		"title": "Xương Khô Không Ngủ",
		"region": "tay",
		"description": "Diệt 4 Xương Khô quanh Buried Sand Ruins và trại Đá Vang — nhớ rằng chúng tự ráp lại được một lần. Báo lại Pháp Sư Đá Vang.",
		"target_type": "dry_bones",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "phap_su_da_vang",
		"xp_reward": 520,
		"gold_reward": 280,
		"reputation_reward": 5,
		"status": "available",
	})


## Tuyến Phần 4 — Vùng Bắc Frostgard (GIẢI THOÁT LINH HỒN + THỦ THÀNH).
## Khác Đông (đột nhập), Nam (điều tra/lựa chọn thuốc) và Tây (liên minh/
## đấu trường): vua Bắc là UNDEAD bị nguyền băng, "giải phóng" ở đây là
## GIẢI THOÁT linh hồn quân đoàn. Boss chiến đấu chính KHÔNG phải vua mà
## là Kẻ Giữ Nguyền của Tháp; vua là NPC — sau khi phá nguyền, người chơi
## CHỌN nghi lễ giải thoát (bac_07a) hoặc phá vỡ thân xác vua (bac_07b).
## Tên King Valdemar / Vharok / Hearthwick trong tuyến này là ĐỀ XUẤT
## chờ user duyệt (xem design/frostgard_so_do.md mục 0).
func _register_frostgard_quests() -> void:
	_add_quest({
		"id": "bac_01_den_phuong_bac",
		"quest_type": "main",
		"title": "Đến Phương Bắc",
		"region": "bac",
		"description": "Caravan đi Bắc chỉ chạy khi Solmaris đã giải phóng. Diệt 4 con Sói Tuyết chặn đường quanh Northgate, rồi báo lại Trưởng Làng Lò Sưởi ở Hearthwick.",
		"required_flag": "tay_giai_phong",
		"target_type": "snow_wolf",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "truong_lang_lo_suoi",
		"set_flag": "da_den_bac",
		"xp_reward": 1100,
		"gold_reward": 500,
		"reputation_reward": 6,
		"status": "available",
	})
	_add_quest({
		"id": "bac_02_lo_suoi",
		"quest_type": "main",
		"title": "Lò Sưởi Không Được Tắt",
		"region": "bac",
		"description": "Lò Sưởi Lớn của Hearthwick cần thảo lửa chống lạnh để cháy qua đêm bão. Thu 4 thảo dược (thảo lửa) quanh làng và rừng thông, rồi mang về cho Chủ Lò Sưởi.",
		"required_quest": "bac_01_den_phuong_bac",
		"collect_type": "herb",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "chu_lo_suoi",
		"set_flag": "lo_suoi_khong_tat",
		"xp_reward": 950,
		"gold_reward": 420,
		"reputation_reward": 6,
		"status": "available",
	})
	_add_quest({
		"id": "bac_03_giu_tuong_dem",
		"quest_type": "main",
		"title": "Giữ Tường Trong Đêm",
		"region": "bac",
		"description": "Mỗi đêm Wight Bão Tuyết lại trườn về tường làng và pháo đài. Giữ tường: diệt 5 con Wight quanh Hearthwick, Ghostwatch Post và đường lên Frostgard, rồi báo lại Đội Trưởng Gác Làng.",
		"required_quest": "bac_02_lo_suoi",
		"target_type": "wight",
		"target_count": 5,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "doi_truong_gac_lang",
		"set_flag": "da_giu_tuong_dem",
		"xp_reward": 1250,
		"gold_reward": 550,
		"reputation_reward": 8,
		"status": "available",
	})
	_add_quest({
		"id": "bac_04_ten_doi_truong",
		"quest_type": "main",
		"title": "Tên Của Năm Đội Trưởng",
		"region": "bac",
		"description": "Xuống Hầm Mộ Quân Đoàn (Legion Crypt), đọc bia tưởng niệm tên 5 đội trưởng đã chết — Ysolde, Bram, Odric, Sigrun, Tomas (tên đề xuất) — rồi mang danh sách tên về cho Bà Góa Giữ Danh Sách ở Hearthwick. Không có tên, không có giải thoát.",
		"required_quest": "bac_03_giu_tuong_dem",
		"target_map": "legion_crypt",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "ba_goa_giu_ten",
		"set_flags": ["thu_ten_doi_truong", "du_ten_doi_truong"],
		"xp_reward": 1300,
		"gold_reward": 500,
		"reputation_reward": 8,
		"status": "available",
	})
	_add_quest({
		"id": "bac_05_tram_gac_ma",
		"quest_type": "main",
		"title": "Trạm Gác Ma",
		"region": "bac",
		"description": "Các Hiệp Sĩ Băng ở trạm gác ma đã quên tên mình. Đánh thức họ bằng trận đánh để đọc nốt tên khắc trên khiên: hạ 4 Hiệp Sĩ Băng, rồi báo lại Bà Góa Giữ Danh Sách.",
		"required_quest": "bac_04_ten_doi_truong",
		"target_type": "frost_knight",
		"target_count": 4,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "ba_goa_giu_ten",
		"set_flag": "tram_gac_da_sach",
		"xp_reward": 1450,
		"gold_reward": 650,
		"reputation_reward": 10,
		"status": "available",
	})
	_add_quest({
		"id": "bac_06_ke_giu_nguyen",
		"quest_type": "main",
		"title": "Kẻ Giữ Nguyền",
		"region": "bac",
		"description": "Hạ Vharok, Kẻ Giữ Nguyền (tên đề xuất) — tay giữ nguyền của Tháp ở tiền sảnh Frostgard. Vua băng không phải kẻ thù của ngươi; kẻ giữ xích của ông ta mới là. Hạ xong, quay lại gặp Vua Băng Bị Nguyền.",
		"required_quest": "bac_05_tram_gac_ma",
		"target_type": "boss_curse_warden",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "vua_bac_bang",
		"set_flag": "nguyen_da_vo",
		"xp_reward": 1800,
		"gold_reward": 900,
		"reputation_reward": 12,
		"status": "available",
	})
	# --- LỰA CHỌN CUỐI PHẦN: giải thoát hay phá vỡ thân xác vua ---
	_add_quest({
		"id": "bac_07a_giai_thoat",
		"quest_type": "main",
		"title": "Kết Phần: Nghi Lễ Giải Thoát",
		"region": "bac",
		"description": "LỰA CHỌN A — GIẢI THOÁT: đọc to tên 5 đội trưởng và tên thật của vua bên chiếc chuông câm. King Valdemar (tên đề xuất) cảm ơn ngươi, rồi tan biến cùng quân đoàn — linh hồn được siêu thoát, không ai phải ở lại gác nữa.",
		"required_quest": "bac_06_ke_giu_nguyen",
		"complete_on_accept": true,
		"blocks_quests": ["bac_07b_pha_vua"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "vua_bac_bang",
		"set_flags": ["bac_end_giai_thoat", "linh_hon_sieu_thoat", "vua_cam_on", "bac_giai_phong"],
		"xp_reward": 2000,
		"gold_reward": 1000,
		"reputation_reward": 20,
		"status": "available",
	})
	_add_quest({
		"id": "bac_07b_pha_vua",
		"quest_type": "main",
		"title": "Kết Phần: Phá Vỡ Thân Xác Vua",
		"region": "bac",
		"description": "LỰA CHỌN B — PHÁ VỠ: phá vỡ thân xác băng của vua tại ngai ở Frostgard Approach. Nguyền vỡ nhanh — nhưng linh hồn quân đoàn không ai gọi tên nên còn vất vưởng. Xong việc, báo lại Bà Góa Giữ Danh Sách.",
		"required_quest": "bac_06_ke_giu_nguyen",
		"complete_on_accept": false,
		"blocks_quests": ["bac_07a_giai_thoat"],
		"target_map": "frostgard_approach",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "ba_goa_giu_ten",
		"set_flags": ["bac_end_pha_vua", "linh_hon_van_vat", "bac_giai_phong"],
		"xp_reward": 2000,
		"gold_reward": 1000,
		"reputation_reward": 14,
		"status": "available",
	})
	# --- Quest phụ ---
	_add_quest({
		"id": "bac_side_hunt",
		"quest_type": "side",
		"title": "Săn Quái Băng Ở Hồ",
		"region": "bac",
		"description": "Diệt 3 con Quái Băng quanh Frozen Lake và rừng thông — nhớ lùi ra khi chúng sắp vỡ, lõi băng nổ đau đấy. Báo lại Thợ Săn Đầu Đàn ở Hearthwick.",
		"target_type": "ice_elemental",
		"target_count": 3,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "tho_san_dau_dan",
		"xp_reward": 800,
		"gold_reward": 450,
		"reputation_reward": 5,
		"status": "available",
	})
	_add_quest({
		"id": "bac_side_wraith",
		"quest_type": "side",
		"title": "Hồn Ma Trên Mặt Hồ",
		"region": "bac",
		"description": "Diệt 3 Hồn Ma Băng lướt trên Frozen Lake, rồi báo lại Thầy Điềm ở nhà bờ hồ.",
		"target_type": "frost_wraith",
		"target_count": 3,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "thay_diem",
		"xp_reward": 850,
		"gold_reward": 480,
		"reputation_reward": 5,
		"status": "available",
	})


## Tuyến CUỐI — Sigilspire (Đợt 6, Lv 25). Cấu trúc theo world doc mục 3:
## Cổng Bốn Chìa (hard gate đủ 4 seal key -> flag sigilspire_open mở cổng
## ở Đất Chết) -> Tầng Ký Ức (2 mini-boss Hồi Âm, không quest riêng) ->
## Tầng 5 Sử Ấn -> Tầng 6 Seraphine (TWIST: cô là vật phong ấn sống) ->
## Đỉnh tháp: đối thoại với Vua rồi đánh boss cuối -> Bệ Phong Ấn chọn
## 1 trong 3 ENDING (thap_05a/b/c — nhận qua FinalEndingPanel, nhận là
## chốt ending, 2 lựa chọn còn lại bị khoá; flag ending_* làm GameState
## chốt game_completed).
func _register_sigilspire_quests() -> void:
	_add_quest({
		"id": "thap_01_co_bon_chia",
		"quest_type": "main",
		"title": "Cổng Bốn Chìa",
		"region": "trung_tam",
		"description": "Đủ 4 chìa phong ấn, cổng Sigilspire đã mở. Qua Đất Chết, bước vào sảnh chân tháp — Tầng 0, Cổng Bốn Chìa.",
		"required_flag": "bac_giai_phong",
		"target_map": "sigilspire_base",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": false,
		"turn_in_npc": "",
		"set_flag": "da_vao_thap",
		"xp_reward": 2500,
		"gold_reward": 800,
		"reputation_reward": 0,
		"status": "available",
	})
	_add_quest({
		"id": "thap_02_tang_su_an",
		"quest_type": "main",
		"title": "Tầng Sử Ấn",
		"region": "trung_tam",
		"description": "Leo qua hai Tầng Ký Ức tới Tầng 5 — Tầng Sử Ấn, và nghe Người Ghi Ấn Cuối Cùng kể toàn bộ lịch sử của phong ấn.",
		"required_quest": "thap_01_co_bon_chia",
		"target_map": "sigilspire_f5",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "nguoi_ghi_an",
		"set_flag": "biet_su_an",
		"xp_reward": 1500,
		"gold_reward": 400,
		"reputation_reward": 0,
		"status": "available",
	})
	_add_quest({
		"id": "thap_03_seraphine",
		"quest_type": "main",
		"title": "Công Chúa Ở Tầng 6",
		"region": "trung_tam",
		"description": "Gặp Công chúa Seraphine ở Phòng Phong Ấn Sống, Tầng 6. Nghe cô nói hết — rồi mới được lên đỉnh tháp. Đừng 'cứu' cô theo quán tính cổ tích.",
		"required_quest": "thap_02_tang_su_an",
		"complete_on_accept": true,
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": true,
		"turn_in_npc": "seraphine",
		"set_flags": ["da_gap_seraphine", "seraphine_truth"],
		"xp_reward": 1500,
		"gold_reward": 400,
		"reputation_reward": 0,
		"status": "available",
	})
	_add_quest({
		"id": "thap_04_vua_dinh_thap",
		"quest_type": "main",
		"title": "Vua Trên Đỉnh Tháp",
		"region": "trung_tam",
		"description": "Đối mặt Vua Trên Đỉnh — kẻ kéo dây cả 4 vua bù nhìn. Nghe hắn nói, rồi đánh bại hắn để giành quyền quyết định số phận của phong ấn.",
		"required_quest": "thap_03_seraphine",
		"target_type": "boss_puppet_king",
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": false,
		"turn_in_npc": "",
		"set_flag": "final_boss_dead",
		"xp_reward": 4000,
		"gold_reward": 2000,
		"reputation_reward": 0,
		"status": "available",
	})
	# --- 3 ENDING: chọn tại Bệ Phong Ấn (FinalEndingPanel gọi accept) ---
	_add_quest({
		"id": "thap_05a_phong_an_moi",
		"quest_type": "main",
		"title": "ENDING — Phong Ấn Mới",
		"region": "trung_tam",
		"description": "KẾT CỤC A: Seraphine tiếp tục làm vật phong ấn sống — lần này theo một bản thỏa thuận mới công khai, các vùng cùng gánh cái giá thay vì một mình cô. Trật tự được giữ, bi kịch được thừa nhận.",
		"required_quest": "thap_04_vua_dinh_thap",
		"complete_on_accept": true,
		"blocks_quests": ["thap_05b_pha_an", "thap_05c_thay_the"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": false,
		"turn_in_npc": "",
		"set_flags": ["ending_phong_an_moi"],
		"xp_reward": 0,
		"gold_reward": 0,
		"reputation_reward": 0,
		"status": "available",
	})
	_add_quest({
		"id": "thap_05b_pha_an",
		"quest_type": "main",
		"title": "ENDING — Phá Ấn",
		"region": "trung_tam",
		"description": "KẾT CỤC B: giải thoát Seraphine và phá phong ấn theo nghi lễ của vua — có kiểm soát hết mức có thể. Thứ bị giam ra ngoài có điều kiện; thế giới đổi thay, không ai chắc theo hướng nào.",
		"required_quest": "thap_04_vua_dinh_thap",
		"complete_on_accept": true,
		"blocks_quests": ["thap_05a_phong_an_moi", "thap_05c_thay_the"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": false,
		"turn_in_npc": "",
		"set_flags": ["ending_pha_an"],
		"xp_reward": 0,
		"gold_reward": 0,
		"reputation_reward": 0,
		"status": "available",
	})
	_add_quest({
		"id": "thap_05c_thay_the",
		"quest_type": "main",
		"title": "ENDING — Thay Thế",
		"region": "trung_tam",
		"description": "KẾT CỤC C: ngươi tự ngồi vào vị trí vật phong ấn sống, thay Seraphine. Cô được tự do; còn ngươi ở lại trong tháp, gác ấn thay cho cả vương quốc — như mọi đời người gác trước ngươi.",
		"required_quest": "thap_04_vua_dinh_thap",
		"complete_on_accept": true,
		"blocks_quests": ["thap_05a_phong_an_moi", "thap_05b_pha_an"],
		"target_count": 1,
		"progress": 0,
		"requires_turn_in": false,
		"turn_in_npc": "",
		"set_flags": ["ending_thay_the"],
		"xp_reward": 0,
		"gold_reward": 0,
		"reputation_reward": 0,
		"status": "available",
	})


func _add_quest(q: Dictionary) -> void:
	quests[str(q.get("id", ""))] = q


func accept_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		push_warning("[QuestManager] Không có quest: " + quest_id)
		return false
	var q: Dictionary = quests[quest_id]
	if str(q.get("status", "")) != "available":
		return false
	# Quest tiên quyết: phải completed mới nhận được quest này
	var required := str(q.get("required_quest", ""))
	if required != "" and not completed_quests.has(required):
		print("[QuestManager] Chưa nhận được '%s': cần hoàn thành quest '%s' trước." % [quest_id, required])
		return false
	# Cờ tiên quyết (dùng cho các quest sau một LỰA CHỌN ở quest khác nhánh):
	# vd cả 3 lựa chọn thuốc đều set flag "da_chon_thuoc".
	var required_flag := str(q.get("required_flag", ""))
	if required_flag != "" and has_node("/root/GameState") and not GameState.get_flag(required_flag):
		print("[QuestManager] Chưa nhận được '%s': cần cờ '%s'." % [quest_id, required_flag])
		return false
	q["status"] = "active"
	quests[quest_id] = q
	if not active_quests.has(quest_id):
		active_quests.append(quest_id)
	# Lựa chọn loại trừ: nhận quest này thì khoá các lựa chọn còn lại.
	for blocked_id in q.get("blocks_quests", []):
		var bid := str(blocked_id)
		if quests.has(bid) and str(quests[bid].get("status", "")) == "available":
			var bq: Dictionary = quests[bid]
			bq["status"] = "locked"
			quests[bid] = bq
			quest_updated.emit(bid)
			print("[QuestManager] Lựa chọn '%s' đã khoá lựa chọn '%s'." % [quest_id, bid])
	quest_accepted.emit(quest_id)
	quest_updated.emit(quest_id)
	print("[QuestManager] Nhận quest: ", q.get("title", quest_id))
	# Quest lựa chọn: nhận = đã chọn xong, chuyển thẳng sang chờ trả tại NPC
	# (hoặc hoàn thành ngay nếu không cần trả) để set hậu quả qua complete.
	if bool(q.get("complete_on_accept", false)):
		if bool(q.get("requires_turn_in", false)):
			q["status"] = "ready_turn_in"
			quests[quest_id] = q
			active_quests.erase(quest_id)
			quest_updated.emit(quest_id)
		else:
			complete_quest(quest_id)
	return true


func add_quest_progress(quest_id: String, amount: int = 1) -> void:
	if not quests.has(quest_id):
		return
	var q: Dictionary = quests[quest_id]
	if str(q.get("status", "")) != "active":
		return
	q["progress"] = mini(int(q.get("progress", 0)) + amount, int(q.get("target_count", 1)))
	quests[quest_id] = q
	quest_updated.emit(quest_id)
	if int(q["progress"]) >= int(q.get("target_count", 1)):
		if bool(q.get("requires_turn_in", false)):
			# Đủ tiến độ nhưng CHƯA nhận thưởng: chờ player quay lại NPC trả nhiệm vụ
			q["status"] = "ready_turn_in"
			quests[quest_id] = q
			quest_updated.emit(quest_id)
			print("[QuestManager] Quest '%s' đã đủ tiến độ — hãy quay lại gặp NPC '%s' để trả." % [quest_id, str(q.get("turn_in_npc", ""))])
		else:
			complete_quest(quest_id)


# Trả nhiệm vụ tại NPC: chỉ hoàn thành (và phát thưởng) khi đang ready_turn_in.
func turn_in_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		return false
	var q: Dictionary = quests[quest_id]
	if str(q.get("status", "")) != "ready_turn_in":
		return false
	return complete_quest(quest_id)


# Gọi khi enemy chết — generic: mọi quest active có target_type khớp đều +1
func on_enemy_killed(enemy_type: String) -> void:
	print("[QuestManager] Enemy bị hạ: ", enemy_type)
	for qid in quests.keys():
		var q: Dictionary = quests[qid]
		if str(q.get("status", "")) == "active" and str(q.get("target_type", "")) == enemy_type:
			add_quest_progress(qid, 1)


# Gọi khi player vào một map — generic theo target_map (basename scene đích,
# vd "hoang_cung"). Mọi quest đang active có target_map khớp đều +1 tiến độ.
func on_map_entered(map_key: String) -> void:
	print("[QuestManager] Player vào map: ", map_key)
	for qid in quests.keys():
		var q: Dictionary = quests[qid]
		if str(q.get("status", "")) == "active" and str(q.get("target_map", "")) == map_key:
			add_quest_progress(qid, 1)


# Gọi khi nhặt vật phẩm quest — generic theo collect_type (vd "herb")
func on_item_collected(item_id: String) -> void:
	print("[QuestManager] Nhặt vật phẩm quest: ", item_id)
	for qid in quests.keys():
		var q: Dictionary = quests[qid]
		if str(q.get("status", "")) == "active" and str(q.get("collect_type", "")) == item_id:
			add_quest_progress(qid, 1)


func complete_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		return false
	var q: Dictionary = quests[quest_id]
	if str(q.get("status", "")) == "completed":
		return false
	q["status"] = "completed"
	quests[quest_id] = q
	active_quests.erase(quest_id)
	if not completed_quests.has(quest_id):
		completed_quests.append(quest_id)
	# Thưởng qua GameState
	if has_node("/root/GameState"):
		GameState.add_xp(int(q.get("xp_reward", 0)))
		GameState.add_gold(int(q.get("gold_reward", 0)))
		var rep: int = int(q.get("reputation_reward", 0))
		if rep != 0:
			GameState.add_reputation(str(q.get("region", "dong")), rep)
	# Hook tuyến giải phóng: quest có thể đặt flag cốt truyện khi hoàn thành
	var sf: String = str(q.get("set_flag", ""))
	if sf != "" and has_node("/root/GameState"):
		GameState.set_flag(sf)
		print("[QuestManager] Đặt flag cốt truyện: ", sf)
	# Nhiều flag hậu quả cùng lúc (quest lựa chọn Phần 2 dùng "set_flags")
	for extra_flag in q.get("set_flags", []):
		var ef := str(extra_flag)
		if ef != "" and has_node("/root/GameState"):
			GameState.set_flag(ef)
			print("[QuestManager] Đặt flag cốt truyện: ", ef)
	quest_completed.emit(quest_id)
	quest_updated.emit(quest_id)
	print("[QuestManager] Hoàn thành quest: ", q.get("title", quest_id))
	return true


func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})


func to_dict() -> Dictionary:
	return {
		"quests": quests.duplicate(true),
		"active_quests": active_quests.duplicate(),
		"completed_quests": completed_quests.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	if data.has("quests") and data["quests"] is Dictionary:
		quests = data["quests"].duplicate(true)
	active_quests.clear()
	completed_quests.clear()
	for id in data.get("active_quests", []):
		active_quests.append(str(id))
	for id in data.get("completed_quests", []):
		completed_quests.append(str(id))
