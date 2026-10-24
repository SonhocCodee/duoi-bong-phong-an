# VÙNG TÂY — SOLMARIS: SƠ ĐỒ ĐA MAP (Phần 3)

> **Game:** Dưới Bóng Phong Ấn (Godot 4) — Vùng Tây / Solmaris (Lv 13–18)  
> **Loại tài liệu:** Thiết kế cấu trúc vùng + trạng thái dựng đợt 4.  
> **Sơ đồ kèm theo:** `design/solmaris_so_do.png` — sơ đồ tổng thể vùng (script vẽ: `tools/draw_solmaris.py`). Layout riêng của thành: `design/solmaris_layout.md` + `design/solmaris_layout.png`.  
> **Nguồn đối chiếu:** `design/cot_truyen_4_phan.md` Phần 3 (LIÊN MINH + ĐẤU TRƯỜNG), `design/world_v2_4_thanh.md` §2.3.  
> **Bản chất Phần 3 (chốt, không được làm sai):** Vua Solmaris **đã chết từ lâu**. Quyền lực thật là **hội đồng lính đánh thuê** mượn danh vua; phía sau là **Vesskar**, rồng cát canh cổng phong ấn bị trói bằng lời thề cổ. Cao trào không phải đột nhập (Đông) hay điều tra/đạo đức thuốc thang (Nam), mà là **gây dựng liên minh bộ lạc + thắng đấu trường**, rồi **chọn đánh hoặc đàm phán với Vesskar**.  
> **Quy ước portal:** dùng `systems/portal.tscn`. Map đích có `Marker2D` tên `Spawn_from_<key của map xuất phát>`; portal đặt `target_scene` + `target_spawn = "from_<key của map hiện tại>"`.  
> **Điểm vào vùng:** cổng caravan ở **Fenmire Approach** chỉ mở khi đã có flag `nam_giai_phong` (xong Phần 2), đi sang `westgate`.

---

## 0. TÊN ĐỀ XUẤT — CẦN USER DUYỆT

Các tên dưới đây **chưa phải tên chốt**, vì brief đợt 4 yêu cầu đề xuất để user duyệt:

| Đối tượng | Tên đề xuất | Ghi chú |
|---|---|---|
| Bộ lạc 1 | **Dunehawk Tribe** — Bộ Lạc Diều Cát | Bộ lạc du mục săn bắn/di chuyển theo đàn diều cát; trại ở phía tây Dunefield |
| Bộ lạc 2 | **Stonesong Tribe** — Bộ Lạc Đá Vang | Bộ lạc giữ truyền khẩu và bằng chứng lời thề trong Buried Sand Ruins |
| Chỉ huy lính đánh thuê / boss đấu trường | **Kassia Vane** | Hiển thị trong game: “Kassia Vane, Chỉ Huy Lính Đánh Thuê” |
| Thị trấn ốc đảo khởi vùng | **Sunwell Oasis** | Tên địa danh mới cho map hub đầu vùng |
| Cổng vào vùng | **Westgate** | Cửa khẩu trong bức tường khổng lồ phía tây Fenmire |

Tên **Vesskar** và **Solmaris** giữ nguyên theo tài liệu đã chốt.

---

## 1. BẢN ĐỒ TÊN ĐỊA DANH

| # | Tên hiển thị | Slug + file scene | Loại | Kích thước dựng đợt 4 |
|---|---|---|---|---|
| 1 | **Westgate** | `maps/westgate.tscn` (key: `westgate`) | Cổng Tây vào vùng | 100×75 ô |
| 2 | **Sunwell Oasis** | `maps/sunwell_oasis.tscn` (key: `oasis`) | Thị trấn ốc đảo khởi vùng | 110×80 ô |
| 3 | **Dunefield** | `maps/dunefield.tscn` (key: `dunefield`) | Biển cát + đụn | 150×105 ô |
| 4 | **Dunehawk Camp** | `maps/dunehawk_camp.tscn` (key: `dunehawk`) | Trại bộ lạc 1 (tên đề xuất) | 100×75 ô |
| 5 | **Redrock Canyon** | `maps/redrock_canyon.tscn` (key: `canyon`) | Hẻm núi đá + đấu trường | 140×100 ô |
| 6 | **Stonesong Camp** | `maps/stonesong_camp.tscn` (key: `stonesong`) | Trại bộ lạc 2 (tên đề xuất) | 100×75 ô |
| 7 | **Buried Sand Ruins** | `maps/buried_sand_ruins.tscn` (key: `ruins`) | Tàn tích cổ — dungeon nhiều phòng | 150×100 ô |
| 8 | **Vesskar's Lair** | `maps/vesskar_lair.tscn` (key: `lair`) | Hang rồng | 120×85 ô |
| 9 | **Solmaris** | `maps/solmaris.tscn` (key: `solmaris`) | Thành — **chưa dựng, mới layout chờ duyệt** | 240×170 ô theo layout |

---

## 2. SƠ ĐỒ KẾT NỐI

```text
FENMIRE APPROACH ──(caravan, khóa flag nam_giai_phong)──► WESTGATE
                                                            │ nam
                                                            ▼
                                                     SUNWELL OASIS ★ hub
                                                            │ đông
                                                            ▼
                                                       DUNEFIELD
                                                       │           │
                                  tây ─────────────────┘           └───── đông
                                  ▼                                      ▼
                          DUNEHAWK CAMP                         REDROCK CANYON
                          (bộ lạc 1)                            + ĐẤU TRƯỜNG
                                                                          │
                                                        nam ──────────────┼───── đông
                                                        ▼                 ▼
                                                STONESONG CAMP   BURIED SAND RUINS
                                                (bộ lạc 2)       (dungeon)
                                                                          │ bắc
                                                                          ▼
                                                                  VESSKAR'S LAIR
                                                                          │
                                                                          └─ đường vào thành Solmaris
                                                                             (CHƯA DỰNG — chờ duyệt layout)
```

---

## 3. TUYẾN QUEST CHÍNH PHẦN 3 (`tay_*`)

| Quest | Tên | Nội dung |
|---|---|---|
| `tay_01_den_solmaris` | Qua Cổng Tây Vào Solmaris | Điều kiện flag `nam_giai_phong`. Diệt 4 Bọ Cạp Cát, trả tại Hướng Dẫn Caravan ở Sunwell Oasis. |
| `tay_02_nuoc_oc_dao` | Giữ Nước Cho Sunwell Oasis | Diệt 4 Rắn Cát quanh mạch nước, trả tại Người Giữ Nước. Set flag `oc_dao_on_dinh`. |
| `tay_03a_dieu_cat` | Điều Kiện Của Bộ Lạc Diều Cát | Điều kiện bộ lạc 1: diệt 5 lính đánh thuê đào ngũ ở Redrock Canyon, trả tại Thủ Lĩnh Diều Cát. Set flag `dieu_cat_dong_y`. |
| `tay_03b_da_vang` | Điều Kiện Của Bộ Lạc Đá Vang | Điều kiện bộ lạc 2: vào Buried Sand Ruins lấy bối cảnh/bằng chứng lời thề, trả tại Pháp Sư Đá Vang. Set flags `da_vang_dong_y`, `co_bang_chung_loi_the`. |
| `tay_04_lien_minh` | Dựng Liên Minh Sa Mạc | Nhận = đã chọn lập liên minh, trả tại Trưởng Liên Minh. Set flag `lien_minh_bo_lac`. |
| `tay_05_dau_truong` | Đấu Trường Của Hội Đồng | Hạ boss **Kassia Vane** ở Redrock Canyon, trả tại Chủ Đấu Trường. Set flags `thang_dau_truong`, `hoi_dong_suy_yeu`. |
| `tay_06_gap_vesskar` | Vào Hang Vesskar | Vào `vesskar_lair` để tận mắt đối mặt Vesskar. Set flag `da_gap_vesskar`. |
| `tay_07a_danh_vesskar` | Kết Phần: Giết Kẻ Canh Cổng | **Lựa chọn A loại trừ B.** Hạ Vesskar, trả tại Trưởng Liên Minh. Flags: `tay_end_danh_vesskar`, `vesskar_chet`, `tay_bao_cat_mat_kiem_soat`, `tay_giai_phong`. |
| `tay_07b_dam_phan_vesskar` | Kết Phần: Trả Lại Lời Thề Cho Vesskar | **Lựa chọn B loại trừ A.** Nhận = chọn đàm phán, trả tại Trưởng Liên Minh. Flags: `tay_end_dam_phan`, `vesskar_dam_phan`, `vesskar_song`, `loi_the_co_duoc_tra`, `tay_giai_phong`. |

Hoàn thành một trong hai quest kết phần sẽ qua `GameState.set_flag("tay_giai_phong")`: nhận **Chìa Vảy Cát** (`seal_keys["tay"]`) và phát signal **`part3_completed`**.

Quest phụ: `tay_side_vulture` (3 Kền Kền Cát), `tay_side_bones` (4 Xương Khô).

---

## 4. QUÁI + BOSS

| Loại | `enemy_type` | Cơ chế |
|---|---|---|
| Bọ Cạp Cát | `sand_scorpion` | Dùng script húc của boar: gồng rồi lao mũi độc |
| Rắn Cát | `sand_snake` | Lao cắn nhanh hơn, cooldown ngắn hơn |
| Lính Đánh Thuê | `mercenary` | Khiên phía trước chỉ nhận 40% damage (script soldier) |
| Kền Kền Cát | `sand_vulture` | Lướt vào player (script wyvern) |
| Xương Khô | `dry_bones` | Lần đầu bị hạ sẽ tự ráp lại với 45 HP, chỉ 1 lần |
| Golem Cát | `sand_golem` | Thân đá giảm phẳng 6 damage (script stone_spirit) |
| Boss đấu trường | `boss_mercenary_captain` | **Kassia Vane** (đề xuất): khiên + loạt Đạn Cát 3/5 viên + gọi lính ở mốc 66%/33% HP + phase 2 |
| Boss/đối tượng cuối | `boss_vesskar` | Hơi thở cát hình nón 300px + bão cát 8/12 viên + đào cát áp sát + phase 2; nếu flag `vesskar_dam_phan` đã set thì hòa bình |

**Trạng thái sprite quái:** tái dùng SpriteFrames của các loài cũ với tint/scale khác nhau (slime/wolf/goblin/wyvern/golem). **Chưa có sprite riêng cho quái Solmaris** — đây là phần còn treo, không được ghi là art final.

---

## 5. NPC SỐNG

- **Sunwell Oasis:** Hướng Dẫn Caravan, Người Giữ Nước, Trưởng Liên Minh, Thương Nhân Ốc Đảo, Lính Đánh Thuê Gác Ốc Đảo — đều có lịch trình đi lại/làm việc quanh giếng, chợ và cổng.
- **Dunehawk Camp:** Thủ Lĩnh Diều Cát, Người Kể Chuyện Diều Cát quanh lửa trại.
- **Stonesong Camp:** Pháp Sư Đá Vang, Người Kể Chuyện Đá Vang quanh lửa trại.
- **Redrock Canyon:** Chủ Đấu Trường gần đấu trường.
- **Vesskar's Lair:** Người Giữ Lời Thề ở cửa hang (lore + đầu mối quest `tay_06`).

---

## 6. TRẠNG THÁI ART

- Tileset `desert_v1` sinh bằng pipeline supersample của game: cát, đụn cát, cát đá, đất nứt, nước ốc đảo trong 2 pha, bờ nước 4 hướng + góc, cỏ khô, sàn/brick sa thạch, cát xương, đường đất nứt.
- Prop mới: `palm_tree`, `cactus`, `bone_rib`, `tribal_tent`, `campfire`.
- Ảnh soi: `design/solmaris_mockup_v1.png`.
- **Mức đạt — nói thẳng:** đây là **bộ mẫu/khung hướng art để tích hợp và duyệt hướng**, ngang mức tileset mẫu của các vùng trước, **không phải pixel-art final**. Cát còn hạt đều, lá chà là còn mảnh, xương sườn còn stylized. Muốn final cần vòng polish/vẽ tay riêng.
