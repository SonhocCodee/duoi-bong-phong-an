# VÙNG NAM — FENMIRE: SƠ ĐỒ ĐA MAP (Phần 2)

> **Game:** Dưới Bóng Phong Ấn (Godot 4) — Vùng Nam / Fenmire (Lv 7–12)
> **Loại tài liệu:** Thiết kế cấu trúc vùng — CHỈ tài liệu + sơ đồ + tileset mẫu, chưa dựng scene/code cho vùng Nam.
> **Sơ đồ kèm theo:** `design/fenmire_so_do.png` — sơ đồ tổng thể vùng (script vẽ: `tools/draw_fenmire.py`). Layout riêng của thành: `design/fenmire_layout.md` + `design/fenmire_layout.png`.
> **Nguồn đối chiếu:** `design/cot_truyen_4_phan.md` Phần 2 (ĐIỀU TRA + LỰA CHỌN ĐẠO ĐỨC), `design/world_v2_4_thanh.md` §2.2 (Fenmire, Morvain, Đền Chìm Triều, Chìa Triều Ngọc), `design/vung_dong_so_do.md` (format + quy ước portal của Vùng Đông).
> **Bản chất Phần 2 (chốt, không được làm sai):** Vua Nam **King Oswin** *(tên mới đề xuất, chờ user duyệt — xem `fenmire_layout.md` §11.2)* **tự nguyện bán vùng cho giáo phái Triều Chìm** để đổi thuốc cứu hoàng hậu và cứu dân khỏi **dịch bệnh đầm lầy**. Không có kẻ ác rõ ràng: phá thỏa thuận = dịch bùng lại, dân chết; giữ thỏa thuận = Fenmire mãi là chư hầu và kho thuốc mãi là xiềng xích. Tuyến chính là **ĐIỀU TRA** (thu thập chứng cứ, đối chất 3 phe) → **LỰA CHỌN ĐẠO ĐỨC** không có đáp án sạch ở cuối phần.
> **Quy ước portal:** dùng `systems/portal.tscn`. Map đích có `Marker2D` tên `Spawn_from_<key của map xuất phát>`; portal đặt `target_scene` + `target_spawn = "from_<key của map hiện tại>"`. Mỗi map root gắn `systems/map_root.gd`, `y_sort_enabled = true`, có sẵn Player + HUD, `Spawn_start` + đủ `Spawn_from_*`.
> **Điểm vào vùng:** `Spawn_start` ở Miregate, ngay sau khi Cổng Tường Nam mở ở cuối Phần 1.

---

## 1. BẢN ĐỒ TÊN ĐỊA DANH (tên hiển thị + slug file dự kiến)

Quy ước như Vùng Đông sau đợt đổi tên 2026-10-23: tên HIỂN THỊ là tên Âu fantasy (hậu tố đầm lầy: *…mire / …fen / …mere / …marsh*), tên file giữ slug nội bộ ngắn. **Toàn bộ tên dưới đây là tên đặt mới cho Vùng Nam trong tài liệu này** (tài liệu cũ chỉ có Fenmire / Đền Chìm Triều / Morvain).

| # | Tên hiển thị (trong game) | Tên gọi tắt / nghĩa | Slug + file scene dự kiến | Loại |
|---|---|---|---|---|
| 1 | **Miregate** | Cổng Tường Nam — cửa khẩu trong bức tường khổng lồ giữa Đông và Nam | `maps/miregate.tscn` (key: `miregate`) | Map cửa ngõ |
| 2 | **Reedmere** | Làng Bãi Sậy — làng khởi vùng Nam (vai trò như Làng Bến Bùn trong world v2: điểm nghỉ đầu tiên, dạy địa hình đầm) | `maps/reedmere.tscn` (key: `reedmere`) | Làng hub đầu vùng |
| 3 | **Drownedwood** | Rừng Ngập Nước | `maps/drownedwood.tscn` (key: `drownedwood`) | Map dã ngoại |
| 4 | **Venomfen** | Đầm Độc | `maps/venomfen.tscn` (key: `venomfen`) | Map dã ngoại |
| 5 | **Fevercamp** | Trại Tị Nạn Dịch Bệnh (trại bệnh do giáo phái dựng và phát thuốc) | `maps/fevercamp.tscn` (key: `fevercamp`) | Trại / hub quest |
| 6 | **Blackmere** | Hồ Đầm Lớn + làng chài bờ hồ (gộp vai trò Làng Đèn Lồng + Làng Muối Đắng của world v2: chợ đèn lồng bờ hồ, bến muối ở bờ nam hồ) | `maps/blackmere.tscn` (key: `blackmere`) | Map hồ + làng chài |
| 7 | **Sunken Tide Temple** | Đền Chìm Triều — dungeon giáo phái/người giữ triều | `maps/sunken_tide_temple.tscn` (key: `temple`) | Dungeon |
| 8 | **Fenmire Approach** | Đường Vào Thành — đường cạn + ván từ đền ra cổng Bắc thành Fenmire | `maps/fenmire_approach.tscn` (key: `approach`) | Map nối |
| 9 | **Fenmire** | Thành Fenmire trên cù lao giữa đầm — **mới ở mức layout, CHƯA dựng** | `maps/fenmire.tscn` (key: `fenmire`) | Thành (hub lớn) |
| + | **Fenmire Cistern** | Cống Ngập — cống/hầm dưới thành Fenmire (nêu ở `fenmire_layout.md` §8-P2) | `maps/cong_ngap_fenmire.tscn` (key: `cong_fenmire`) | Dungeon nhỏ trong thành |

---

## 2. SƠ ĐỒ KẾT NỐI (ASCII)

```text
   VÙNG ĐÔNG (Aldenmere) ── Cổng Tường Nam mở cuối Phần 1
                        │
                        ▼
                   MIREGATE (miregate)  cửa khẩu tường, trạm kiểm + bãi bùn đầu vùng
                        │ đường ván nam
                        ▼
                   REEDMERE (reedmere) ★ làng khởi vùng — nhà sàn, bãi sậy, điểm save
                        │ đường mòn tây-nam qua bãi bùn
                        ▼
                 DROWNEDWOOD (drownedwood)  rừng ngập nước, đước + rễ ngập
                   │                                    ╲ đường thủy (thuyền dân chài, mở sau nam_04)
                   ▼ đường ván tây-nam                      ╲
                 VENOMFEN (venomfen)  đầm độc, nấm phát sáng   ╲
                   │            ╲ nhánh đông                  ╲
                   ▼ đường cạn   ╲                             ▼
                 FEVERCAMP        ╲────► BLACKMERE (blackmere) hồ lớn, làng chài, chợ đèn lồng
                 (fevercamp)               │ đường bờ hồ đông-nam
                 trại bệnh giáo phái       ▼
                   │ đường ván đông   SUNKEN TIDE TEMPLE (sunken_tide_temple)
                   └───────────────►  DUNGEON — đền chìm nửa dưới nước, puzzle triều
                                            │ đường cạn bắc (Fenmire Approach)
                                            ▼
                                   FENMIRE APPROACH (fenmire_approach)
                                            │ cầu cạn vào Cổng Bắc
                                            ▼
                                   FENMIRE (fenmire) — THÀNH, chưa dựng (xem fenmire_layout)
                                            └─ Cống Ngập (cong_ngap_fenmire) dưới Kho Thuốc
```

Sơ đồ tuyến tính theo hướng địa lý (bắc → nam):

```text
[Đông]═[Miregate]═[Reedmere]═[Drownedwood]═[Venomfen]═[Fevercamp]
                                          ║ nhánh hồ      ║
                                          ╚═[Blackmere]═══╝ (đường bờ hồ)
                                                        ║
                              [Fenmire]═[Approach]═[Sunken Tide Temple]
```

---

## 3. BẢNG TỪNG MAP

Kích thước theo chuẩn map toàn game đã chốt (làng ~100×75 ô, dã ngoại ~140×100 ô, dungeon nhiều phòng). Cấp độ quái ghi theo dải Lv 7–12 của vùng.

| Map (file) | Kích thước dự kiến | Điểm nhấn | NPC chính | Quái (Lv) | Cổng đi (portal → đích, spawn ở đích) |
|---|---|---|---|---|---|
| **Miregate** `maps/miregate.tscn` | ~100×75 ô | Đoạn **bức tường khổng lồ** chạy ngang bắc map (nhìn thấy quy mô tường chia cắt 4 vùng lần đầu từ phía nam), cổng kiểm, bãi bùn + đường ván bắt đầu; lính cổng Đông đã rút, cổng do dân quân Reedmere giữ | `linh_miregate` (lore + cảnh báo dịch), thương nhân quay đầu xe (lore: "hàng vào Nam chỉ có thuốc đi ngược ra") | Không quái trong bãi cổng; bìa nam: Slime Đầm ×3 (Lv 7) dạy địa hình bùn làm chậm | Bắc → quay về The Wallfoot/Aldenmere *(portal khóa cho tới khi xong Phần 1 — hook sẵn)* · Nam → `reedmere` (`from_miregate`) |
| **Reedmere** `maps/reedmere.tscn` ★ | ~110×80 ô | Làng khởi vùng: ~10 nhà sàn quanh bãi sậy lớn, bến thuyền con, giếng nước ngọt (hiếm ở đầm — chi tiết lore: giếng này là lý do làng còn đứng được), bảng nhiệm vụ đầu vùng | `truong_reedmere` (quest `nam_01`), `dan_say_1` (lore dịch bệnh), `tre_reedmere` (lore trẻ con: "bệnh thì uống thuốc tím, hết thuốc thì…") | Ven làng: Rắn Đầm ×3 (Lv 7, phục kích ở bụi sậy — telegraph gợn nước), Herb độc ×3 | Bắc → `miregate` (`from_reedmere`) · Tây-nam → `drownedwood` (`from_reedmere`) |
| **Drownedwood** `maps/drownedwood.tscn` | ~150×110 ô | Rừng ngập nước: đước rễ cong (prop `mangrove`), nửa map ngập đến đầu gối (đi chậm, không bơi), đường ván mục đứt đoạn phải nhảy/ghép, tổ đỉa ở vùng nước tù | — (1 NPC ẩn: `nguoi_thu_thao` hái thảo, đổi thảo độc lấy giải độc, chỉ gặp ban ngày) | Rắn Đầm ×5 (Lv 7–8) · Đỉa Trâu theo bầy ×3 nhóm (Lv 8, bám gây chảy máu nhẹ) · Quái Bùn ×3 (Lv 8–9, trâu, kháng chém) | Đông → `reedmere` (`from_drownedwood`) · Tây-nam → `venomfen` (`from_drownedwood`) · Đường thủy phía nam → `blackmere` (`from_drownedwood`, **mở sau `nam_04`** — trước đó bị rễ đước chặn) |
| **Venomfen** `maps/venomfen.tscn` | ~140×100 ô | Đầm độc: vũng độc xanh-đen (đứng vào trúng độc), **nấm độc phát sáng** (prop `glowshroom`) tụ thành "vườn nấm" ở trung tâm — đẹp và nguy hiểm, dấu vết **giáo phái thu hái nấm độc làm thuốc** (lều thu hái bỏ hoang + lọ thuốc dở) | — (chỉ có xác/lều bỏ hoang — sự vắng mặt là chứng cứ) | Bóng Độc Đầm ×5 (Lv 9–10, phun mây độc) · Ếch Độc Lớn ×4 (Lv 9) · Rắn Đầm ×3 (Lv 9) | Đông-bắc → `drownedwood` (`from_venomfen`) · Đông → `fevercamp` (`from_venomfen`) · Nam → `blackmere` (`from_venomfen`) |
| **Fevercamp** `maps/fevercamp.tscn` | ~100×75 ô | Trại tị nạn dịch bệnh: lều bệnh + nhà thương dã chiến của giáo phái, hàng phát thuốc, khu cách ly phía tây (hàng rào + đèn tím); trại **an toàn** nhưng không khí nặng — điểm quest đạo đức đầu tiên của phần (`nam_02`: thuốc chỉ đủ cho một nửa danh sách) | `y_si_tram` (y sĩ trưởng trạm — người tốt trong hệ thống xấu), `benh_nhan_1` (lore), `me_goa` (quest phụ: xin thuốc cho con không có tên trong sổ) | Không quái trong trại; bìa tây ngoài hàng rào: Quái Bùn ×2 (Lv 8) | Tây → `venomfen` (`from_fevercamp`) · Đông-nam → `sunken_tide_temple` (`from_fevercamp`) · Bắc (đường tắt bờ kênh) → `blackmere` (`from_fevercamp`) |
| **Blackmere** `maps/blackmere.tscn` | ~160×110 ô | **Hồ đầm lớn** chiếm nửa tây map (nước sâu, cá chết nổi theo vòng tròn hướng về đền — dấu hiệu phong ấn), làng chài bờ đông: nhà sàn + **chợ đèn lồng** (mở buổi tối), bến muối bờ nam; dân chài là phe thứ hai của phần | `truong_dan_chai_ho` (quest `nam_04`), `dan_chai_ho_1` (lore), `lai_pha_ho` (phà sang Fenmire — nối P4 của thành) | Ven hồ: Ếch Độc ×4 (Lv 10) · Quái Bùn ×3 (Lv 10) · **Đỉa Chúa (mini-elite)** ×1 ở vùng nước tù phía bắc hồ (Lv 11, drop Tuyến Đỉa — nguyên liệu giải độc mạnh) | Bắc → `drownedwood` (`from_blackmere`, đường thủy) · Tây-bắc → `venomfen` (`from_blackmere`) · Nam → `fevercamp` (`from_blackmere`) · Đông-nam → `sunken_tide_temple` (`from_blackmere`) · Phà đông → `fenmire` (`from_blackmere`, **mở sau `nam_04`**) |
| **Sunken Tide Temple** `maps/sunken_tide_temple.tscn` | Dungeon 3 khu, đi 45–60 phút | Đền đá **chìm nửa dưới nước**: mực nước thay đổi theo chu kỳ cần gạt/chuông (puzzle triều như world v2 — phòng đi được lúc rút sẽ ngập lúc dâng, có chuông cảnh báo); tên các đời **Người Giữ Triều khắc dưới mực nước**, chỉ đọc được lúc triều rút sâu nhất; phòng sâu nhất là nơi giáo phái **thử thuốc** | `morvain` (đối thoại dài + đánh thăm dò — **Giai đoạn 1**, rút lui làm ngập phòng, theo world v2), tín đồ canh đền (có thể **đầu hàng** — mở thoại tha/giết) | Tín Đồ Canh Đền ×6 (Lv 11, caster nước/độc) · Bóng Độc ×4 (Lv 11) · Quái Bùn ×3 (Lv 11) · **Không boss hoàn chỉnh ở đây** — boss thành là ở Fenmire (`nam_06`), Morvain tại đền chỉ là Giai đoạn 1 | Cửa đền → `fevercamp` (`from_temple`) · Cửa phụ triều rút → `blackmere` (`from_temple`, chỉ mở lúc triều rút) · Đường cạn bắc → `fenmire_approach` (`from_temple`, mở sau khi qua đền lần đầu) |
| **Fenmire Approach** `maps/fenmire_approach.tscn` | ~120×90 ô | Đường vào thành: đường cạn + ván men theo kênh thoát của thành, ruộng muối bỏ hoang, trạm kiểm của giáo phái ở giữa đường (kiểm "giấy thông hành thuốc" — qua bằng giấy, bằng chứng cứ đối chất, hoặc bằng đường vòng bãi bùn) | `tin_do_tram` (tín đồ gác trạm — đối thoại theo chứng cứ đã có) | Bãi bùn phía tây: Quái Bùn ×3 (Lv 11–12), Bóng Độc ×2 (Lv 12) — đường vòng tránh trạm kiểm là đường khó hơn có chủ ý | Nam → `sunken_tide_temple` (`from_approach`) · Bắc → `fenmire` Cổng Bắc (`from_approach`) |
| **Fenmire** `maps/fenmire.tscn` | **220×160 ô** (xem layout) | Thành trên cù lao — **chưa dựng, mới có layout chờ duyệt** | 15 NPC theo `fenmire_layout.md` §7 (King Oswin, Morvain, Đại Giáo Sĩ, Trưởng Dân Chài…) | Không quái trong thành | Bắc → `fenmire_approach` (`from_fenmire`) · Cống Ngập → `cong_ngap_fenmire` (`from_fenmire`) · Phà Tây → `blackmere` (`from_fenmire`) |

### Spawn markers từng map

| Map | `Spawn_start` | Các `Spawn_from_*` (vị trí) |
|---|---|---|
| Miregate | Giữa bãi cổng (từ Đông xuống) | `from_reedmere` cổng Nam |
| Reedmere | Bến thuyền phía bắc làng ★ | `from_miregate` cổng Bắc · `from_drownedwood` cổng Tây-nam |
| Drownedwood | Cổng Đông | `from_reedmere` cổng Đông · `from_venomfen` cổng Tây-nam · `from_blackmere` đường thủy phía nam |
| Venomfen | Cổng Đông-bắc | `from_drownedwood` cổng Đông-bắc · `from_fevercamp` cổng Đông · `from_blackmere` cổng Nam |
| Fevercamp | Cổng Tây | `from_venomfen` cổng Tây · `from_temple` cổng Đông-nam · `from_blackmere` cổng Bắc |
| Blackmere | Bến làng bờ đông | `from_venomfen` cổng Tây-bắc · `from_drownedwood` đường thủy phía bắc · `from_fevercamp` cổng Nam · `from_temple` cửa bờ hồ phía đông-nam · `from_fenmire` bến phà |
| Sunken Tide Temple | Cửa đền | `from_fevercamp` cửa đền · `from_blackmere` cửa phụ triều rút · `from_approach` đường cạn bắc |
| Fenmire Approach | Cổng Nam | `from_temple` cổng Nam · `from_fenmire` cầu cạn phía bắc |
| Fenmire | Sân Cổng Bắc (109, 14) | `from_approach` cổng Bắc · `from_cong` sân Kho Thuốc (194, 134) · `from_blackmere` bến phà Tây (17, 58) — chi tiết ở `fenmire_layout.md` §8 |

Mọi portal đều có nhãn đọc được ngay trên cổng (ví dụ "↑ Miregate", "→ Drownedwood", "↓ Sunken Tide Temple") và biển gỗ chỉ hướng đặt cạnh đường đi — giữ đúng quy ước Vùng Đông.

---

## 4. CÁC PHE CỦA PHẦN 2 (điều tra = đi giữa 3 phe này)

| Phe | Là ai | Họ muốn gì | Họ giấu gì | Điểm tiếp cận chính |
|---|---|---|---|---|
| **Giáo phái Triều Chìm** (Order of the Sunken Tide) | Giáo phái thờ triều/đền, nay nắm kho thuốc và nhà thương của cả vùng theo thỏa thuận với vua | Giữ thỏa thuận, giữ vai trò "người cứu vùng khỏi dịch"; trong nội bộ có phe cứng rắn muốn Fenmire thành **giáo quốc** | Thuốc được **thử trên người bệnh nặng** trước khi phát; một phần "dịch bệnh" bùng phát đúng lúc đàm phán năm xưa — trùng hợp đến mức đáng ngờ | Đại Giáo Sĩ + Y Sĩ + Tín Đồ Trẻ (thành), y sĩ trưởng Fevercamp |
| **Dân chài Blackmere** | Dân chài hồ lớn + làng Reedmere — người chịu dịch và chịu giá thuốc trực tiếp | Thuốc đều cho mọi người, không sổ sách chọn lọc; nhiều người muốn **đuổi giáo phái** dù chưa biết thay bằng gì | Họ **giấu Người Giữ Triều già** và giấu đường thủy cũ vào đền; một số dân chài **bán tháo thảo độc cho giáo phái** để lấy thuốc cho nhà mình | Trưởng Dân Chài (hồ + thành), dân chài Reedmere |
| **Người Giữ Triều** (Tidekeepers) | Dòng người giữ đền cũ, gần như tuyệt chủng sau khi nghi lễ giữ triều bị bỏ; **Morvain là Người Giữ Triều sống sót** (theo world v2 + cốt truyện 4 phần) | Khôi phục cách giữ triều cũ **mà không ai phải chết** — điều chính họ cũng chưa chứng minh được là khả thi | Nghi lễ cũ **đòi một người ở lại trong đền khi triều dâng cao nhất**; Morvain sống sót thoát ra là nguyên nhân triều điên — bà vừa là nạn nhân vừa là "tội đồ" trong mắt cả 2 phe kia | Người Giữ Triều Già (thành), Morvain (đền + thành) |
| *(Bên thứ tư — không phải phe)* **King Oswin + hoàng gia** | Vua Nam, đang bệnh nằm ở nhà thương giáo phái | Cứu hoàng hậu và dân — theo đúng thứ tự ưu tiên đó, và ông biết điều đó đáng xấu hổ | Ông ký thỏa thuận **khi chưa đọc điều khoản về thử thuốc**; hoàng hậu khỏi bệnh là nhờ thuốc thật — ông không dám phá thỏa thuận vì sợ bà tái phát | Phòng Vua Bệnh (thành), chỉ gặp theo tiến độ điều tra |

---

## 5. TUYẾN ĐI + QUEST CHÍNH PHẦN 2 (dự kiến, id `nam_*`)

```text
Miregate ──► Reedmere ──► Drownedwood ──► Venomfen ──► Fevercamp ──► Sunken Tide Temple ──► Approach ──► FENMIRE
                │               │              │ nhánh hồ      (điều tra trong đền)                    (đối chất + lựa chọn)
                │               └──────────────┴──► Blackmere (dân chài, Người Giữ Triều) ──phà──►───────┘
```

| Quest | Tên / nơi | Nội dung điều tra — lựa chọn |
|---|---|---|
| `nam_01` | **Đến Fenmire** — Reedmere | Làm quen vùng: giúp làng lấy lại thùng thuốc bị Quái Bùn chặn ở Drownedwood bìa đông. Hé mở: thùng thuốc có **2 loại tem** — tem phát dân và tem "thử". |
| `nam_02` | **Danh Sách Thuốc** — Fevercamp | Y sĩ trạm nhờ phân phát: thuốc chỉ đủ cho **một nửa danh sách**. Người chơi chọn phát cho ai (trẻ bệnh nặng / người già giữ nghề / người nuôi cả nhà) — **lựa chọn nhỏ đầu tiên, game ghi sổ, NPC ở thành nhắc lại ở `nam_06`**. Lấy được bản sao sổ phát thuốc (chứng cứ A). |
| `nam_03` | **Vườn Nấm** — Venomfen | Theo dấu thu hái nấm độc của giáo phái; chọn **phá vườn nấm** (giảm nguồn thuốc thử, dân mất nguồn thuốc thật lẫn lộn) hay **để nguyên và ghi chứng cứ** (chứng cứ B — lọ thuốc thử + sổ tay thu hái ở lều bỏ hoang). Gặp Tín Đồ Trẻ lần đầu (ở thành, sau quest này). |
| `nam_04` | **Người Dân Chài Giấu** — Blackmere | Dân chài nhờ cứu Đỉa Chúa / dọn đường thủy, đổi lại họ giới thiệu **Người Giữ Triều Già**. Mở đường thủy Drownedwood↔Blackmere + phà sang Fenmire. Nghe phiên bản của phe giữ triều (chứng cứ C — danh sách tên khắc ở đền). |
| `nam_05` | **Đền Chìm Triều** — Dungeon | Vào đền lúc triều rút: đọc tên người giữ triều dưới mực nước, tìm phòng thử thuốc, đối thoại dài với **Morvain** + đánh thăm dò (bà rút lui, làm ngập phòng). Ra khỏi đền với **Chìa Triều Ngọc dạng thô** và đủ 3 chứng cứ A/B/C (thiếu chứng cứ nào, đối chất ở `nam_06` yếu đi tương ứng — không khóa cứng). |
| `nam_06` | **Đối Chất Ở Fenmire** — Thành | Vào thành (cổng Bắc hoặc phà), gặp King Oswin ở nhà thương, đối chất 3 phe ở sân đền. **LỰA CHỌN CUỐI PHẦN** (không đáp án sạch): (1) **Giữ thỏa thuận, cải tổ từ trong** — giáo phái ở lại nhưng mất độc quyền sổ thuốc, Morvain giám sát; dịch được kiểm soát, vùng vẫn chư hầu. (2) **Phá thỏa thuận, khôi phục giữ triều mới** — đuổi giáo phái, Morvain + Người Giữ Triều Già giữ triều bằng cách mới chưa kiểm chứng: **một số NPC bệnh nặng chết ngoài màn hình**, tự do nhưng trả giá người. (3) **Phá chu kỳ triều** — phá cơ chế triều nhân tạo: thành mất nguồn nước ngọt dần, Reedmere/Blackmere phải di dời một phần, không ai phải chết vì nghi lễ/thuốc thử nữa nhưng vùng nghèo đi rõ rệt ở các phần sau. Mọi đường đều nhận **Chìa Triều Ngọc** (tinh luyện ở đền) và mở đường sang Vùng Tây (đoàn caravan ở Blackmere) — khác nhau ở **trạng thái Fenmire về sau** (NPC sống/chết, chợ còn hay mất, Morvain là đồng minh hay không), game ghi sổ cho epilogue ở Sigilspire. |

Thứ tự trải nghiệm dự kiến: **Miregate → Reedmere → Drownedwood → Venomfen → Fevercamp → Blackmere (nhánh điều tra chính) → Sunken Tide Temple → Fenmire**, với Fevercamp là điểm quay lại nhiều lần (phát thuốc theo ngày — quest lặp có chủ ý để người chơi thấy hậu quả lựa chọn của mình tích lũy).

---

## 6. TRẠNG THÁI ART + KIỂM CHỨNG (ghi đúng thực tế, cập nhật 2026-10-23)

### 6.1. Tileset đầm lầy `swamp_v1` — MẪU DUYỆT HƯỚNG, CHƯA FINAL

- **Đã có:** `game/assets/tilesets/swamp_v1.png` (atlas 320×256, lưới 5×4, tile 64px) + `game/assets/tilesets/swamp_v1.tres`, sinh bởi `tools/gen_swamp_tileset.py` (kế thừa pipeline supersample 4x + texture wrap-around + profile biên lượn sóng chung của `tools/gen_tileset_v1.py`).
- **19 tile dùng thật** (ô thứ 20 của lưới là ô đệm lặp `swamp_grass`): nước đục xanh rêu 2 pha (`water_murky_a/b`) + nước sâu, bùn ướt, bùn khô nứt, cỏ đầm + cỏ sậy, đường ván gỗ + ván rêu + mép ván, bờ chuyển tiếp cỏ↔nước 4 hướng + góc lồi + góc lõm, bờ bùn↔nước 2 hướng, lối mòn bùn giữa cỏ.
- **Prop mẫu (PNG trong suốt, `game/assets/props/`):** `mangrove.png` 200×208 (cây đước rễ chống cong + gợn nước chân rễ), `reed_clump.png` 96×104 (bụi sậy + bông đuôi mèo), `glowshroom.png` 88×76 (nấm độc phát sáng nhẹ tím–teal), `swamp_log.png` 128×56 (gỗ mục phủ rêu).
- **Ảnh soi:** `design/fenmire_mockup_v1.png` (1440×960, cảnh đầm 15×10 ô ghép từ chính tileset + prop này).
- **Tự soi đã làm (2 vòng):** vòng 1 phát hiện tile ván bị **bán trong suốt** (lỗi ImageDraw ghi đè alpha khi vẽ lớp tông ván — nền cỏ/bùn lộ qua ván, mỗi ô ván một màu) → đã sửa (vẽ lớp tông lên layer riêng rồi alpha-composite) và sinh lại; vòng 2 soi lại mockup: ván đồng nhất, đường ván đọc rõ, đước/sậy/nấm/bùn nứt/nước đục đều đọc ra chất đầm lầy ngay. Sơ đồ vùng + layout thành cũng đã soi 2 vòng sửa chồng chữ (xem §6.2).
- **Mức đạt — nói thẳng:** ngang mức `exterior_v1` của Vùng Đông, tức **khung/mẫu để duyệt hướng art + tích hợp thử, KHÔNG phải asset final**. Hạn chế đã biết: ván gỗ chạy dọc theo chiều đường (ghép ngang dài sẽ thấy nhịp ván liền), bùn khô nhìn gần hơi "hạt/chấm", tán đước còn dạng cụm blob như tán cây v1, nước đục mới có 2 pha gợn tĩnh. Muốn lên final cần vòng vẽ tay/polish riêng như đã làm với sprite 128px của nhân vật.

### 6.2. Sơ đồ

- `design/fenmire_so_do.png` (1800×1560) và `design/fenmire_layout.png` (1830×1300) đều do `tools/draw_fenmire.py` sinh. Đã tự soi: vòng 1 thấy (a) chú thích sơ đồ vùng bị cắt chữ ở mép phải, (b) mũi tên "từ Vùng Đông" chỉ sai hướng (chỉ ra ngoài thay vì vào Miregate), (c) layout thành có 4 điểm chồng chữ (nhãn chợ đè nhãn Bảng Nhiệm Vụ/P1, nhãn khu dân bị hẻm ván đè, nhãn nội thành bị khối đền + nhãn P2 đè) → đã sửa hết và soi lại vòng 2: không còn nhãn nào chồng/cắt, mọi khu đọc được tên + tọa độ.

### 6.3. Kiểm chứng Godot — ĐÃ KIỂM CHỨNG ĐƯỢC (2026-10-23)

- Binary dùng: `tools_bin/Godot_v4.2.2-stable_linux.x86_64` trong repo (đường `/tmp/godot_bin/` không còn tồn tại trên máy — binary thật nằm ở `tools_bin/`).
- Chạy `Godot --headless --import` trong `game/`: **thoát mã 0**, sinh đủ `swamp_v1.png.import` + `.import` cho 4 prop mới. Log import có lỗi load ở một số scene trong `game/tests/` (file đang dở của tuyến việc khác, tồn tại từ trước, **không liên quan** tới file của vùng Nam lần này).
- Kiểm chứng đích danh bằng script headless nạp tài nguyên: `swamp_v1.tres` **load thành công**, TileSet có **20 tile**, `tile_size = (64, 64)`, atlas PNG 320×256; cả 4 prop (`mangrove` 200×208, `reed_clump` 96×104, `glowshroom` 88×76, `swamp_log` 128×56) đều load được. → `.tres` không lỗi import, dùng được ngay cho TileMapLayer.
