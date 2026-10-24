# VÙNG BẮC — FROSTGARD: SƠ ĐỒ ĐA MAP (Phần 4)

> **Game:** Dưới Bóng Phong Ấn (Godot 4) — Vùng Bắc / Frostgard (Lv 19–24)  
> **Loại tài liệu:** Thiết kế cấu trúc vùng + trạng thái dựng đợt 5.  
> **Sơ đồ kèm theo:** `design/frostgard_so_do.png` — sơ đồ tổng thể vùng (script vẽ: `tools/draw_frostgard.py`). Layout riêng của thành: `design/frostgard_layout.md` + `design/frostgard_layout.png`.  
> **Nguồn đối chiếu:** `design/cot_truyen_4_phan.md` Phần 4 (GIẢI THOÁT LINH HỒN), `design/world_v2_4_thanh.md` §2.4 (Bắc — Pháo Đài Băng Nứt, Hiệp Sĩ Băng, Làng Lò Sưởi, Chìa Sắt Băng, Trụ Hàn làm bằng người).  
> **Bản chất Phần 4 (chốt, không được làm sai):** Vua Bắc là **undead bị nguyền băng**; "giải phóng" ở đây là **GIẢI THOÁT linh hồn quân đoàn**, không phải lật đổ. Boss chiến đấu chính **không phải vua** mà là **Kẻ Giữ Nguyền của Tháp**; vua là NPC — sau khi phá nguyền, người chơi **chọn** làm nghi lễ giải thoát hoặc phá vỡ thân xác vua (xem mục 7).  
> **Quy ước portal:** dùng `systems/portal.tscn`. Map đích có `Marker2D` tên `Spawn_from_<key của map xuất phát>`; portal đặt `target_scene` + `target_spawn = "from_<key của map hiện tại>"`.  
> **Điểm vào vùng:** cổng caravan ở **Sunwell Oasis** chỉ mở khi đã có flag `tay_giai_phong` (xong Phần 3), đi sang `northgate`.

---

## 0. TÊN ĐỀ XUẤT — CẦN USER DUYỆT

Các tên dưới đây **chưa phải tên chốt**, đề xuất ở đợt 5 để user duyệt:

| Đối tượng | Tên đề xuất | Ghi chú |
|---|---|---|
| Vua Bắc (NPC, `vua_bac_bang`) | **King Valdemar, the Frostbound King** | Hiển thị trong game: “King Valdemar (tên đề xuất) — Vua Băng Bị Nguyền” |
| Kẻ Giữ Nguyền / boss (`boss_curse_warden`) | **Vharok, Kẻ Giữ Nguyền** | Tay giữ nguyền của Tháp ở Frostgard Approach — boss chiến đấu chính của Phần 4 |
| Làng trú đông (hub) | **Hearthwick — Làng Lò Sưởi** | Map `hearthwick.tscn`; lò sưởi lớn không bao giờ được tắt |
| Đội trưởng 1 (đội cung) | **Ysolde** | Tên khắc trên bia tưởng niệm ở Legion Crypt |
| Đội trưởng 2 (đội khiên) | **Bram** | Tên khắc trên bia tưởng niệm ở Legion Crypt |
| Đội trưởng 3 (đội gác chuông) | **Odric** | Tên khắc trên bia tưởng niệm ở Legion Crypt |
| Đội trưởng 4 (đội trinh sát) | **Sigrun** | Tên khắc trên bia tưởng niệm ở Legion Crypt |
| Đội trưởng 5 (đội hậu cần) | **Tomas** | Tên khắc trên bia tưởng niệm ở Legion Crypt |

Tên **Frostgard** và **Chìa Sắt Băng** giữ nguyên theo tài liệu đã chốt.

---

## 1. BẢN ĐỒ TÊN ĐỊA DANH

| # | Tên hiển thị | Slug + file scene | Loại | Kích thước dựng đợt 5 |
|---|---|---|---|---|
| 1 | **Northgate** | `maps/northgate.tscn` (key: `northgate`) | Cổng Bắc vào vùng | 100×75 ô |
| 2 | **Hearthwick** | `maps/hearthwick.tscn` (key: `hearthwick`) | Làng trú đông — hub khởi vùng | 110×80 ô |
| 3 | **Snowpine Forest** | `maps/snowpine_forest.tscn` (key: `snowpine`) | Rừng thông tuyết | 140×100 ô |
| 4 | **Frozen Lake** | `maps/frozen_lake.tscn` (key: `frozenlake`) | Hồ đóng băng (đi trên băng được) | 130×95 ô |
| 5 | **Ghostwatch Post** | `maps/ghostwatch_post.tscn` (key: `ghostwatch`) | Trạm gác ma bỏ hoang | 110×80 ô |
| 6 | **Legion Crypt** | `maps/legion_crypt.tscn` (key: `crypt`) | Hầm mộ quân đoàn — dungeon nhiều phòng | 150×100 ô |
| 7 | **Howling Pass** | `maps/howling_pass.tscn` (key: `pass`) | Đèo gió rít | 140×100 ô |
| 8 | **Frostgard Approach** | `maps/frostgard_approach.tscn` (key: `approach`) | Tiền sảnh pháo đài — ngai băng + boss | 120×85 ô |
| 9 | **Frostgard** | `maps/frostgard.tscn` (key: `frostgard`) | Thành — **chưa dựng, mới layout chờ duyệt** | 240×170 ô theo layout |

---

## 2. SƠ ĐỒ KẾT NỐI

```text
SUNWELL OASIS ──(caravan, khóa flag tay_giai_phong)──► NORTHGATE
                                                            │ bắc
                                                            ▼
                                                       HEARTHWICK ★ hub
                                                       │               │
                                  bắc ─────────────────┘               └───── đông
                                  ▼                                      ▼
                          SNOWPINE FOREST                         HOWLING PASS
                                  │ đông                                 │ đông
                                  ▼                                      ▼
                            FROZEN LAKE                        FROSTGARD APPROACH
                                  │ đông                          + NGAI BĂNG + VHAROK
                                  ▼                                      │
                            GHOSTWATCH POST                              └─ cổng thành
                                  │ đông                                    (CHƯA DỰNG — chờ duyệt layout)
                                  ▼
                            LEGION CRYPT (dungeon)
```

---

## 3. TUYẾN QUEST CHÍNH PHẦN 4 (`bac_*`)

| Quest | Tên | Nội dung |
|---|---|---|
| `bac_01_den_phuong_bac` | Đến Phương Bắc | Điều kiện flag `tay_giai_phong`. Diệt 4 Sói Tuyết, trả tại Trưởng Làng Lò Sưởi ở Hearthwick. Set flag `da_den_bac`. |
| `bac_02_lo_suoi` | Lò Sưởi Không Được Tắt | Thu 4 thảo lửa (herb) quanh làng/rừng, trả tại Chủ Lò Sưởi. Set flag `lo_suoi_khong_tat`. |
| `bac_03_giu_tuong_dem` | Giữ Tường Trong Đêm | Diệt 5 Wight quanh Hearthwick/Ghostwatch/Approach, trả tại Đội Trưởng Gác Làng. Set flag `da_giu_tuong_dem`. |
| `bac_04_ten_doi_truong` | Tên Của Năm Đội Trưởng | Vào `legion_crypt` đọc bia 5 đội trưởng, trả tại Bà Góa Giữ Danh Sách. Set flags `thu_ten_doi_truong`, `du_ten_doi_truong`. |
| `bac_05_tram_gac_ma` | Trạm Gác Ma | Hạ 4 Hiệp Sĩ Băng (đánh thức để đọc tên trên khiên), trả tại Bà Góa Giữ Danh Sách. Set flag `tram_gac_da_sach`. |
| `bac_06_ke_giu_nguyen` | Kẻ Giữ Nguyền | Hạ boss **Vharok** ở Frostgard Approach, trả tại Vua Băng Bị Nguyền. Set flag `nguyen_da_vo`. |
| `bac_07a_giai_thoat` | Kết Phần: Nghi Lễ Giải Thoát | **Lựa chọn A loại trừ B.** Nhận = chọn giải thoát, trả tại Vua Băng. Flags: `bac_end_giai_thoat`, `linh_hon_sieu_thoat`, `vua_cam_on`, `bac_giai_phong`. |
| `bac_07b_pha_vua` | Kết Phần: Phá Vỡ Thân Xác Vua | **Lựa chọn B loại trừ A.** Tới ngai ở `frostgard_approach`, trả tại Bà Góa Giữ Danh Sách. Flags: `bac_end_pha_vua`, `linh_hon_van_vat`, `bac_giai_phong`. |

Hoàn thành một trong hai quest kết phần sẽ qua `GameState.set_flag("bac_giai_phong")`: nhận **Chìa Sắt Băng** (`seal_keys["bac"]`) và phát signal **`part4_completed`**.

Quest phụ: `bac_side_hunt` (3 Quái Băng), `bac_side_wraith` (3 Hồn Ma Băng).

---

## 4. QUÁI + BOSS

| Loại | `enemy_type` | Cơ chế |
|---|---|---|
| Sói Tuyết | `snow_wolf` | Script sói bầy đàn của Đông, bản tàn nhẫn hơn: nhanh, vồ theo bầy (script `wolf.gd`) |
| Wight Bão Tuyết | `wight` | Undead trâu, chậm, không sợ — người chết trong bão tuyết không nằm yên (script `enemy_base.gd`) |
| Hiệp Sĩ Băng | `frost_knight` | **Cơ chế KÝ ỨC:** khi “đang nhớ” (`remembering=true`) chỉ gác theo ca cũ, `detect_range` = 70 — chỉ đánh khi player lại rất gần; bị đánh trúng lần đầu thì nhớ tên mình (`last_memory_line`), detect về 300 và đánh thường |
| Quái Băng | `ice_elemental` | Thân băng giảm damage phẳng (kế thừa `stone_spirit.gd`); **chết thì NỔ BĂNG**: player trong 100px chịu 24 damage |
| Hồn Ma Băng | `frost_wraith` | Lướt (dash) vào player như kền kền cát (script `wyvern.gd`) |
| Boss Phần 4 | `boss_curse_warden` | **Vharok, Kẻ Giữ Nguyền** (đề xuất): loạt Đạn Băng 3 viên (phase 2: 5 viên, CD 3.4s → 2.2s, tốc độ ×1.25) + gọi 2 Hiệp Sĩ Băng ở mốc 66%/33% HP (hiệp sĩ triệu hồi `remembering=false`) |

**Trạng thái sprite quái:** tái dùng SpriteFrames của các loài cũ với tint/scale khác nhau (wolf/golem/goblin/slime/wyvern). **Chưa có sprite riêng cho quái Frostgard** — đây là phần còn treo, không được ghi là art final.

---

## 5. NPC SỐNG

- **Hearthwick:** Trưởng Làng Lò Sưởi, Chủ Lò Sưởi, Bà Góa Giữ Danh Sách, Đội Trưởng Gác Làng, Thợ Săn Đầu Đàn, Trẻ Săn Tuyết (lore: đứa trẻ muốn đi săn để không bị chọn đi gác băng) — đều có lịch trình đi lại/làm việc quanh lò, nhà và tường làng.
- **Northgate:** Lính Caravan Đi Bắc tuần tra 2 điểm ở cổng tường.
- **Frozen Lake:** Thầy Điềm đi lại quanh bờ hồ và nhà bờ hồ.
- **Frostgard Approach:** Vua Băng Bị Nguyền ngồi yên ở Đài Ngai Băng (không lịch trình, `wander_radius` = 0) — nói bằng giọng của người đã chết nhưng vẫn giữ kỷ luật ca gác.

---

## 6. TRẠNG THÁI ART

- Tileset `winter_v1` sinh bằng pipeline supersample của game: tuyết, đụn tuyết, tuyết đá, băng + băng bóng + băng sâu, bờ tuyết→băng 4 hướng + góc, cỏ sương, sàn đá, gạch đá đen, tuyết tro, đường tuyết nén.
- Prop mới: `snow_pine` (thông phủ tuyết), `ice_rock` (đá băng nhọn), `grave_stone` (bia mộ đá).
- Ảnh soi: `design/frostgard_mockup_v1.png`.
- **Mức đạt — nói thẳng:** đây là **bộ mẫu/khung hướng art để tích hợp và duyệt hướng**, ngang mức tileset mẫu của các vùng trước, **không phải pixel-art final**. Mặt băng còn đều, thông tuyết còn stylized. Muốn final cần vòng polish/vẽ tay riêng.

---

## 7. PHƯƠNG ÁN BOSS + GIẢI THOÁT (lựa chọn thiết kế — đọc kỹ)

Đây là điểm Phần 4 **cố ý khác** cả 3 phần trước, theo `cot_truyen_4_phan.md`:

1. **Vua không phải boss đánh nhau.** King Valdemar (tên đề xuất) là **NPC** ở Đài Ngai Băng (`frostgard_approach`). Ông ta là undead bị nguyền: không sống cũng không chết, vẫn thi hành mệnh lệnh của Tháp hàng trăm năm sau khi mệnh lệnh đã hết ý nghĩa. Đánh vua không giải quyết được gì — xích giữ ông ta nằm ở kẻ khác.
2. **Boss chiến đấu chính là Vharok, Kẻ Giữ Nguyền** (`boss_curse_warden`, quest `bac_06_ke_giu_nguyen`): tay giữ nguyền của Tháp đóng ở giữa sân tiền sảnh. Hạ Vharok → flag `nguyen_da_vo` → nguyền vỡ, vua lần đầu “nghe thấy im lặng”.
3. **Điều kiện nghi lễ giải thoát = đã thu đủ tên 5 đội trưởng** (quest `bac_04_ten_doi_truong` set flags `thu_ten_doi_truong` + `du_ten_doi_truong` ở Hầm Mộ Quân Đoàn). Nghi lễ (`bac_07a`) là đọc to tên 5 đội trưởng **và tên thật của vua** bên chiếc chuông câm ở Legion Crypt / Đài Ngai Băng. Thiết kế tuyến quest bắt buộc chạy `bac_04` trước `bac_06`/`bac_07`, nên khi tới lựa chọn cuối phần, người chơi luôn đã có đủ tên — khác biệt giữa hai nhánh là **chọn dùng tên hay không**, không phải thiếu điều kiện.
4. **Hai kết cục (loại trừ nhau qua `blocks_quests`):**
   - **A — Giải thoát (`bac_07a_giai_thoat`, nhận = đã chọn):** vua cảm ơn, tan biến cùng quân đoàn. Flags hậu quả: `bac_end_giai_thoat`, `linh_hon_sieu_thoat`, `vua_cam_on`, `bac_giai_phong`. Uy tín Bắc +20.
   - **B — Phá vỡ thân xác vua (`bac_07b_pha_vua`):** tới ngai ở `frostgard_approach` phá thân xác băng — nguyền vỡ nhanh, nhưng linh hồn quân đoàn **không ai gọi tên** nên còn vất vưởng. Flags hậu quả: `bac_end_pha_vua`, `linh_hon_van_vat`, `bac_giai_phong`. Uy tín Bắc +14 (thấp hơn A — dân Bắc ghi sổ cách ngươi “giải phóng” họ).
5. Cả hai nhánh đều set `bac_giai_phong` → Chìa Sắt Băng + signal `part4_completed`. Hậu quả từng nhánh (`linh_hon_sieu_thoat` vs `linh_hon_van_vat`, `vua_cam_on`) được game ghi lại để nhắc cụ thể ở epilogue/Sigilspire, đúng khung chống lặp của tài liệu cốt truyện.
