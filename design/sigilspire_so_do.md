# TRUNG TÂM — SIGILSPIRE: SƠ ĐỒ DỌC THÁP (Đợt cuối / Endgame)

> **Game:** Dưới Bóng Phong Ấn (Godot 4) — Trung tâm / Sigilspire (Lv 25, endgame)  
> **Loại tài liệu:** Thiết kế cấu trúc tháp + trạng thái dựng đợt cuối.  
> **Sơ đồ kèm theo:** `design/sigilspire_so_do.png` — sơ đồ dọc của tháp, từ Đất Chết Trung Tâm ở dưới lên Đỉnh Tháp ở trên (script vẽ: `tools/draw_sigilspire.py`).  
> **Nguồn đối chiếu:** `design/world_v2_4_thanh.md` §3 (Sigilspire — cấu trúc tầng, Seraphine / Vua / boss cuối, twist, khung ending) + `design/cot_truyen_4_phan.md` mục “Sau 4 phần — Sigilspire”.  
> **Bản chất đợt cuối (chốt, không được làm sai):** Công chúa **Seraphine là VẬT PHONG ẤN SỐNG** — chính cô là khoá trung tâm, không phải “công chúa bị nhốt cùng phong ấn”. Cứu cô ra khỏi tháp mà không xử lý ấn là kịch bản vỡ ấn vô kiểm soát. Vua ở đỉnh tháp **không phải boss cuối thuần tuý theo kiểu phản diện**: boss cuối ở Đỉnh Tháp là **Vua Trên Đỉnh (3 phase)** theo thiết kế đợt cuối, và ending chỉ được chọn ở **Bệ Phong Ấn** sau trận đó — đánh thắng boss không tự động cho ending tốt.  
> **Quy ước portal:** dùng `systems/portal.tscn`. Map đích có `Marker2D` tên `Spawn_from_<key của map xuất phát>`; portal đặt `target_scene` + `target_spawn = "from_<key của map hiện tại>"`.  
> **Điểm vào tháp:** cổng Bắc của Frostgard / **Frostgard Approach** đi vào **Đất Chết Trung Tâm**; cổng tháp chỉ mở khi đã đủ **4 Chìa Phong Ấn** (flag `sigilspire_open`, xem mục 4).

---

## 1. TỔNG QUAN

Sigilspire là tháp khổng lồ ở trung tâm thế giới — khoá trung tâm của phong ấn, nhìn thấy được từ xa ở cả 4 vùng. Đây là **dungeon cuối dạng leo tháp**: không có quest phụ, không có shop trong tháp, nhịp chơi dự kiến 2,5–4 giờ + epilogue.

Nguyên tắc kể chuyện của tháp là **đi ngược lịch sử phong ấn**: càng leo lên cao, người chơi càng biết rõ thứ bị giam ở dưới tháp đang được neo bởi người ở trong tháp. Mỗi chặng tầng ôn lại một vùng đã giải phóng (Đông → Nam → Tây → Bắc) dưới dạng ký ức do chính phong ấn ghi lại, rồi mới tới tầng sử, tầng công chúa và đỉnh tháp.

Thứ tự di chuyển bắt buộc trong tháp:

```text
FROSTGARD APPROACH
        │ (cổng Bắc / đường đất chết)
        ▼
ĐẤT CHẾT TRUNG TÂM (dat_chet) — Trạm Gác Tro
        │ (cổng tháp — khoá, cần đủ 4 Chìa Phong Ấn)
        ▼
TẦNG 0 → TẦNG 1–2 → TẦNG 3–4 → TẦNG 5 → TẦNG 6 → TẦNG 7 (ĐỈNH)
```

Save / nghỉ: Tầng 0, Tầng 5 và trước Tầng 6. Không bắt người chơi leo một mạch không nghỉ — độ khó đến từ lựa chọn và boss, không từ việc hành xác. Level 25 là **khuyến nghị / soft wall** qua độ khó địch (đặc biệt là Bóng Ấn ở tầng đầu), không phải hard-lock level: cổng chỉ kiểm tra chìa và quest, đúng nguyên tắc cổng chặn của các phần trước.

Tên boss cuối (**Vua Trên Đỉnh**) và mọi tên riêng trong tài liệu này + trong ảnh sơ đồ là **theo thiết kế đợt cuối**.

---

## 2. BẢNG CẤU TRÚC TẦNG

| Tầng | Map | Nội dung | Địch / Boss | Sự thật lộ ra |
|---|---|---|---|---|
| **Đất Chết Trung Tâm** (ngoài tháp) | `maps/dat_chet.tscn` (key: `dat_chet`) | Vùng đất tro tàn, tĩnh lặng bất thường quanh chân tháp. **Trạm Gác Tro** là điểm dừng cuối trước cổng tháp. Vào từ Frostgard Approach. | Không boss. Địch thưa (nếu có) chỉ để giữ không khí đất chết — đây là map chuyển đoạn, không phải map farm. | Đất chết không phải thiên nhiên: nó là cái giá phong ấn rút từ vùng đất quanh tháp. Cổng tháp ở đây khoá chặt — xem cổng chặn ở mục 4. |
| **Tầng 0 — Cổng Bốn Chìa** | `maps/sigilspire_base.tscn` (key: `sigilspire_base`) | Sảnh chân tháp khổng lồ với **4 ổ khoá trụ**. Tra 4 chìa vào 4 ổ khoá tại đây. Điểm save / nghỉ đầu tiên trong tháp. **★Q1** | **Lính Gác Phong Ấn + Bóng Ấn** (địch gác sảnh, Lv 25). Không boss. | **Vua lên tiếng qua ấn** — cutscene bắt buộc, lần đầu người chơi nghe giọng vua rõ ràng. Vua biết tên người chơi và biết người chơi đã làm gì ở từng thành (game đọc các lựa chọn đã lưu, đọc thành thoại). |
| **Tầng 1–2 — Ký Ức Đông & Nam** | `maps/sigilspire_f1.tscn` (key: `sigilspire_f1`) | Hai lớp phòng biến đổi theo 2 vùng đầu: rừng trong nhà kính đã chết, đầm nước đen không phản chiếu. Puzzle nhẹ ôn lại cơ chế rễ / triều của Đông và Nam. | Địch: **Bóng Ấn** dạng quái Đông / Nam ở mức Lv 25. Mini-boss: **Hồi Âm Của Morvain** — dạng bóng do ấn nhớ lại, không phải nhân vật thật. | Phong ấn **ghi lại** mọi người từng gác nó. Không ai thực sự rời khỏi tháp. |
| **Tầng 3–4 — Ký Ức Tây & Bắc** | `maps/sigilspire_f2.tscn` (key: `sigilspire_f2`) | Hai lớp phòng biến đổi theo 2 vùng sau: sa mạc trong nhà không gió, hành lang băng không lạnh. Trạng thái 4 vùng (thỏa thuận / ai còn sống) có thể mở trợ giúp / đường tắt ở tầng tương ứng. | Địch: **Bóng Ấn** dạng quái Tây / Bắc ở mức Lv 25. Mini-boss: **Hồi Âm Của Hiệp Sĩ Đen** — dạng bóng do ấn nhớ lại, không phải nhân vật thật. | Vua đời đầu không đánh thắng thứ dưới tháp — ông ta **thương lượng** với nó. Phong ấn là một **bản hợp đồng**, không phải nhà tù một chiều. |
| **Tầng 5 — Tầng Sử Ấn** | `maps/sigilspire_f5.tscn` (key: `sigilspire_f5`) | Thư viện / phòng bia đá vòng tròn: toàn bộ lịch sử phong ấn khắc quanh tường, càng lên cao chữ càng mới. Tầng lore thuần. Điểm save / nghỉ. **★Q2** | **Không combat bắt buộc, không boss.** NPC: **Người Ghi Ấn Cuối Cùng** — già, mù, sống trong tháp từ nhỏ; đối thoại dài, có lựa chọn hỏi / không hỏi. | Tên thật, tuổi thật và vai trò thật của công chúa. Vua hiện tại là **hậu duệ kiêm người thừa kế hợp đồng**, không phải kẻ tạo ra phong ấn. |
| **Tầng 6 — Phòng Phong Ấn Sống** | `maps/sigilspire_f6.tscn` (key: `sigilspire_f6`) | Phòng ấm áp, có cây, có ánh sáng như một phòng ngủ bình thường giữa tháp chết — sự bình thường này là thứ khó chịu nhất tháp. Đây là phòng neo ấn, không phải phòng giam xiềng xích: công chúa sống ở đây và **không thể rời phòng quá vài bước** mà không làm tháp rung. **★Q3** | **Không boss** — đối thoại quyết định (decision dialogue) dài nhất game với **Công chúa Seraphine**. Thái độ và yêu cầu của cô phụ thuộc vào việc người chơi đã làm gì ở 4 trụ. | **TWIST CHÍNH:** Seraphine là **vật phong ấn sống** — cơ thể và tên của cô là khoá trung tâm. Cô sống thì ấn giữ; cô rời tháp hoặc chết thì ấn vỡ vô kiểm soát. Cô biết hết mọi chuyện và cảm nhận được từng trụ khi người chơi chạm vào nó ở 4 vùng. |
| **Tầng 7 — Đỉnh Tháp / Đài Sigilspire** | `maps/sigilspire_summit.tscn` (key: `sigilspire_summit`) | Sân thượng tròn nhìn xuống toàn bộ bản đồ 4 vùng — người chơi thấy lại cả 4 thành ở xa. **Bệ Phong Ấn** đặt tại đài. Đối thoại → boss → chọn ending tại bệ. **★Q4** | **Vua Trên Đỉnh — BOSS CUỐI, 3 phase.** Sau trận boss mới mở lựa chọn ending ở Bệ Phong Ấn (mục 6). | Kế hoạch thật của vua và cái giá nếu vua thành công / thất bại. Người chơi cũng đã làm phong ấn **thay đổi** trong lúc “sửa” nó ở 4 vùng — người chơi không đứng ngoài câu chuyện phong ấn. |

---

## 3. SƠ ĐỒ KẾT NỐI

```text
TẦNG 7 — ĐỈNH THÁP / ĐÀI SIGILSPIRE (sigilspire_summit) ★Q4 + Bệ Phong Ấn / 3 ending
        ▲
TẦNG 6 — PHÒNG PHONG ẤN SỐNG (sigilspire_f6) — Seraphine ★Q3
        ▲
TẦNG 5 — TẦNG SỬ ẤN (sigilspire_f5) — Người Ghi Ấn Cuối Cùng ★Q2
        ▲
TẦNG 3–4 — KÝ ỨC TÂY & BẮC (sigilspire_f2) — mini-boss: Hồi Âm Của Hiệp Sĩ Đen
        ▲
TẦNG 1–2 — KÝ ỨC ĐÔNG & NAM (sigilspire_f1) — mini-boss: Hồi Âm Của Morvain
        ▲
TẦNG 0 — CỔNG BỐN CHÌA (sigilspire_base) — vua lên tiếng qua ấn ★Q1
        ▲
ĐẤT CHẾT TRUNG TÂM (dat_chet) — Trạm Gác Tro — cổng tháp khoá (4 chìa)
        ▲
FROSTGARD APPROACH (vào từ cuối Phần 4)
```

---

## 4. CỔNG CHẶN — ĐỦ 4 CHÌA PHONG ẤN

Cổng tháp ở Đất Chết Trung Tâm / Tầng 0 là **hard gate cuối của game**: kiểm tra toàn bộ hành trình 4 vùng, không kiểm tra level thuần tuý.

| Chìa | Vùng | `seal_keys` | Nhận ở |
|---|---|---|---|
| **Chìa Rễ Xanh** | Đông — Aldenmere | `seal_keys["dong"]` | Kết Phần 1 (flag `dong_giai_phong`) |
| **Chìa Triều Ngọc** | Nam — Fenmire | `seal_keys["nam"]` | Kết Phần 2 (flag `nam_giai_phong`) |
| **Chìa Vảy Cát** | Tây — Solmaris | `seal_keys["tay"]` | Kết Phần 3 (flag `tay_giai_phong`) |
| **Chìa Sắt Băng** | Bắc — Frostgard | `seal_keys["bac"]` | Kết Phần 4 (flag `bac_giai_phong`) |

- Đủ 4/4 chìa → `GameState` tự set flag **`sigilspire_open`** (đã có sẵn trong `game/autoload/game_state.gd`: `add_seal_key()` kiểm tra `has_all_seal_keys()` rồi mở flag) → portal cổng tháp ở `dat_chet` mở, vào được `sigilspire_base`.
- Thiếu dù chỉ 1 chìa → cổng **không mở**, dù người chơi có mạnh đến đâu. Chìa phải ở trạng thái mà quest vùng đã chốt (nguyên vẹn, nứt, hay thay thế bằng thỏa thuận — game ghi trạng thái; trạng thái chìa ảnh hưởng hiệu ứng trong Tầng 0 và ending, nhưng không chặn vào tháp khi đã đủ bộ).
- Điều kiện kèm theo: hoàn thành main quest cuối của cả 4 vùng (chính là điều kiện để có 4 chìa ở trên) + xem / kích hoạt cutscene **vua lên tiếng qua ấn** ở Tầng 0 (quest `thap_01`, không skip ở lần đầu).
- Level 25 chỉ là khuyến nghị: dưới mức này cổng vẫn mở nếu đủ chìa, nhưng Lính Gác Phong Ấn + Bóng Ấn ở Tầng 0–2 sẽ là soft wall rất gắt.

---

## 5. TUYẾN QUEST CHÍNH ĐỢT CUỐI (`thap_*`)

Không có quest phụ trong tháp. Tuyến chính chạy thẳng `thap_01` → `thap_04`, rồi rẽ đúng **một** trong ba quest ending `thap_05a/b/c` (loại trừ lẫn nhau).

| Quest | Tên | Nội dung |
|---|---|---|
| `thap_01` | Cổng Bốn Chìa | ★Q1 ở sơ đồ. Vào `sigilspire_base` (điều kiện: flag `sigilspire_open`), tra 4 Chìa Phong Ấn vào 4 ổ khoá trụ, vượt qua **Lính Gác Phong Ấn + Bóng Ấn** ở sảnh. Kích hoạt cutscene **vua lên tiếng qua ấn** — vua gọi đúng tên người chơi và nhắc lại lựa chọn ở từng thành. Mở đường leo lên Tầng 1–2. |
| `thap_02` | Người Ghi Ấn Cuối Cùng | ★Q2 ở sơ đồ. Leo qua Tầng 1–2 (mini-boss **Hồi Âm Của Morvain**) và Tầng 3–4 (mini-boss **Hồi Âm Của Hiệp Sĩ Đen**) lên **Tầng 5 — Tầng Sử Ấn**. Không combat bắt buộc ở Tầng 5: đối thoại dài với **Người Ghi Ấn Cuối Cùng**, đọc vòng bia đá sử ấn. Biết tên / tuổi / vai trò thật của công chúa và nguồn gốc hợp đồng phong ấn trước khi lên gặp cô. |
| `thap_03` | Vật Phong Ấn Sống | ★Q3 ở sơ đồ. Vào **Tầng 6 — Phòng Phong Ấn Sống** (`sigilspire_f6`), gặp **Công chúa Seraphine**. Đối thoại quyết định dài nhất game: twist vật phong ấn sống được nói thẳng, Seraphine nêu yêu cầu của chính cô và nhắc cụ thể những gì người chơi đã làm ở 4 trụ. Xem hết đối thoại bắt buộc ở Tầng 5 + Tầng 6 là điều kiện lên đỉnh (không skip ở lần đầu). |
| `thap_04` | Vua Trên Đỉnh | ★Q4 ở sơ đồ. Lên **Tầng 7 — Đài Sigilspire** (`sigilspire_summit`). Đối thoại với vua ở đỉnh tháp → **boss cuối: Vua Trên Đỉnh, 3 phase**. Hạ boss xong **không** tự kết game: **Bệ Phong Ấn** sáng lên và người chơi phải tự chọn ending ở mục 6. |
| `thap_05a` | Ending: Phong Ấn Mới | **Lựa chọn A tại Bệ Phong Ấn** (sau `thap_04`, loại trừ B/C). Xem chi tiết ở mục 6. Set flag `ending_*` tương ứng → `game_completed`. |
| `thap_05b` | Ending: Phá Ấn | **Lựa chọn B tại Bệ Phong Ấn** (sau `thap_04`, loại trừ A/C). Xem chi tiết ở mục 6. Set flag `ending_*` tương ứng → `game_completed`. |
| `thap_05c` | Ending: Thay Thế | **Lựa chọn C tại Bệ Phong Ấn** (sau `thap_04`, loại trừ A/B). Xem chi tiết ở mục 6. Set flag `ending_*` tương ứng → `game_completed`. |

Cơ chế chốt ending đã có sẵn trong `game/autoload/game_state.gd`: quest `thap_05a/b/c` set flag bắt đầu bằng `ending_` tại Bệ Phong Ấn → `set_flag()` chốt `game_completed = true`, ghi `ending_id` và phát signal `ending_chosen` để save / menu / epilogue đọc.

---

## 6. BA ENDING (chọn 1 tại Bệ Phong Ấn — Tầng 7)

Cả ba ending đều là lựa chọn **có hiểu biết**: game đã cho đủ thông tin ở Tầng 5 + Tầng 6 trước khi người chơi chọn. Không ending nào được game đánh dấu là “đúng”. Mọi ending đều phải nhắc lại cụ thể lựa chọn ở Đông, Nam, Tây, Bắc trong epilogue (ai sống, làng nào mất, thỏa thuận nào còn, linh hồn Bắc được giải thoát ra sao).

| Ending | Quest | Lựa chọn | Hậu quả |
|---|---|---|---|
| **Phong Ấn Mới** | `thap_05a` | Gia hạn / dựng lại phong ấn tại Bệ Phong Ấn — ấn được giữ, Seraphine vẫn (hoặc một cơ chế neo mới vẫn) là khoá trung tâm theo nghi lễ mới. | Vương quốc sống tiếp, thứ bị giam vẫn bị giữ. Cái giá của phong ấn **tiếp tục**, chỉ giảm nhẹ nếu 4 vùng đang ở trạng thái tốt. Đây là ending “an toàn nhất hôm nay, đắt nhất về lâu dài”. |
| **Phá Ấn** | `thap_05b` | Phá phong ấn tại Bệ Phong Ấn theo hướng phá có chủ đích sau khi đã hạ Vua Trên Đỉnh — Seraphine được giải phóng khỏi vai vật neo sống. | Ấn vỡ, Seraphine được tự do. Thứ bị giam thoát ra **có điều kiện / có chuẩn bị** nếu người chơi đã nghe hết Tầng 5–6, nhưng hậu quả với 4 vùng vẫn lớn và không ai hứa chắc vương quốc chịu nổi. Tự do của một người đổi bằng rủi ro của cả vương quốc. |
| **Thay Thế** | `thap_05c` | Người chơi **thay Seraphine** làm vật phong ấn sống / người neo mới tại Bệ Phong Ấn — cô được rời tháp, người chơi ở lại tháp thay cô. | Ấn vẫn giữ mà không bắt Seraphine trả giá nữa: người trả giá lần này là **người chơi**. Seraphine được sống đời của mình; nhân vật chính trở thành khoá trung tâm mới của Sigilspire. Ending bi kịch theo hướng tự nguyện — công bằng theo logic game là cái giá không còn đổ lên dân 4 vùng hay lên một người bị chọn từ nhỏ nữa. |

Ba quest ending **loại trừ lẫn nhau**: chọn một quest là khoá hai quest còn lại. Chọn xong → flag `ending_*` → `game_completed`, chuyển sang epilogue nhắc lại hành trình 4 vùng.

---

## 7. TRẠNG THÁI ART

- **Mức đạt — nói thẳng:** Sigilspire ở đợt cuối là **mức KHUNG** (cấu trúc map / tầng / quest / boss / ending), ngang mức khung của Phần 2–4 khi mới dựng, **không phải art final**.
- **Tileset tái dùng, chưa có tileset riêng cho tháp:** nội thất tháp (sảnh Tầng 0, thư viện Tầng 5, phòng Tầng 6, hành lang các tầng ký ức) tái dùng tileset **interior** hiện có; Đất Chết Trung Tâm và các đoạn lạnh / tro ở chân tháp + tầng Bắc tái dùng tileset **winter** với tint xám tro / tím phong ấn. Chưa có bộ tileset `sigilspire` riêng, chưa có prop riêng cho Bệ Phong Ấn / 4 ổ khoá trụ / vòng bia đá sử ấn ngoài việc ghép từ prop sẵn có.
- **Quái chưa có sprite riêng:** Lính Gác Phong Ấn, Bóng Ấn, **Hồi Âm Của Morvain**, **Hồi Âm Của Hiệp Sĩ Đen** và boss cuối **Vua Trên Đỉnh** đều **chưa có sprite riêng** — tạm tái dùng SpriteFrames của các loài / boss cũ với tint, scale và hiệu ứng bóng / ấn khác nhau (đúng tình trạng đã ghi ở các phần trước). NPC **Seraphine** và **Người Ghi Ấn Cuối Cùng** cũng chưa có sprite riêng.
- Ảnh `design/sigilspire_so_do.png` là **sơ đồ thiết kế** (sơ đồ dọc có nhãn), không phải ảnh chụp trong game và không phải mockup art — không được dùng nó để đánh giá chất lượng art của tháp.
