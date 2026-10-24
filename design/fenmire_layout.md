# FENMIRE — LAYOUT CHI TIẾT (Thiết kế để duyệt bố cục, chưa dựng scene)

> **Game:** Dưới Bóng Phong Ấn — Godot 4, Action RPG top-down
> **Loại tài liệu:** Thiết kế bố cục map thành — CHỈ tài liệu + sơ đồ, chưa dựng/sửa `.tscn`/`.gd`
> **Trạng thái: BẢN CHỜ USER DUYỆT — CHƯA DỰNG SCENE.** Duyệt bố cục này xong mới được dựng `maps/fenmire.tscn`.
> **Sơ đồ kèm theo:** `design/fenmire_layout.png` — vẽ ĐÚNG lưới 220×160 của tài liệu này (cùng hệ tọa độ), không phải sơ đồ tượng trưng thu nhỏ. Script vẽ: `tools/draw_fenmire.py`.
> **Nguồn đối chiếu:** `design/cot_truyen_4_phan.md` (Phần 2 — vua Nam tự nguyện hợp tác với giáo phái để đổi thuốc), `design/world_v2_4_thanh.md` §2.2 (Fenmire: thành trên cọc/nền đá giữa đầm, kênh đào xuyên thành, Bến Triều / Phố Thuốc / Khu Nhà Sàn / Đền Triều Nhỏ / Cống Ngập), `design/fenmire_so_do.md` (sơ đồ toàn vùng).
> **Chuẩn art bắt buộc (chốt 2026-10-23):** tileset + prop pixel art chi tiết cao kiểu Stardew Valley, ghép bằng TileMap, nhân vật đi lại/Y-sort/va chạm tự nhiên, nội thất là map riêng. Không dùng ảnh render phẳng cho khu đi lại được.
> **Quy ước tên hiển thị (fantasy châu Âu):** thành = **Fenmire**; đền giáo phái trong thành = **Sanctum of the Sunken Tide** (phân biệt với dungeon **Sunken Tide Temple** ở ngoài đầm — xem `fenmire_so_do.md`); kênh chính = **Grand Canal**; chợ = **Floating Market**; vua Nam = **King Oswin** *(tên mới đề xuất ở tài liệu này, chờ user duyệt — các tài liệu cũ chưa đặt tên vua Nam)*. Tên file/scene dùng slug nội bộ (`fenmire.tscn`...) — chỉ tên HIỂN THỊ là tên Âu.

---

## 0. Ý TƯỞNG THÀNH — KHÁC HẲN ALDENMERE

Aldenmere (Đông) là thành đá trên đất liền, 3 thềm leo lên phía bắc, tường đá nhiều lớp. Fenmire phải đọc ra chất **đầm lầy** ngay từ bố cục, không bê nguyên khung Đông đổi màu:

| Khác biệt cốt lõi | Aldenmere (Đông) | Fenmire (Nam) |
|---|---|---|
| Địa thế | Đất liền, thềm cao dần lên bắc | **Cù lao / gò đất giữa đầm** — ngoài tường là nước và bùn bốn phía |
| Tường | Đá dày 3 ô, tháp đá, mặt tường đi được | **Gỗ–đá thấp chống ngập** dày 3 ô + **hào nước sát trong tường**; không có mặt tường đi được — bù lại có **đường ván trên mặt nước** là "tầng giao thông" thứ hai |
| Trục chính | Đại lộ đá xuyên thành | **Grand Canal** — kênh nước xuyên thành, đi lại bằng thuyền + đường ván 2 bờ |
| Khu dân | Nhà sát nhau, hẻm đất 1–2 ô | **Nhà sàn trên mặt nước**, di chuyển bằng **hẻm ván gỗ** (cầu ván 2 ô) giữa các dãy nhà sàn |
| Vị trí quyền lực | Nội thành ở thềm cao phía BẮC (xa cổng Nam) | **Đền giáo phái chiếm Nội Thành Thượng ở gò cao phía NAM** (xa cổng Bắc nhất) — giáo phái, không phải vua, ngồi ở vị trí cao nhất thành: bố cục tự nó kể câu chuyện "ai mới thật sự cai trị Fenmire" |
| Cổng chính | Phía Nam | **Phía Bắc** (hướng về đường từ Đền Chìm Triều / Vùng Đông đi xuống) |

---

## 1. CHUẨN KÍCH THƯỚC

### 1.1. Kích thước thành + hệ tọa độ

| Thông số | Giá trị |
|---|---|
| Kích thước map | **220 cột × 160 hàng ô = 35.200 ô** (14.080 × 10.240 px) |
| Tile | 64 × 64 px (chuẩn tileset đã chốt; nhân vật sprite 128px, hitbox player 28px) |
| Hệ tọa độ tài liệu | Ô (cột, hàng): cột 0–219 Tây→Đông, hàng 0–159 Bắc→Nam |
| Đổi sang Godot (gốc tại tâm map, y dương xuống) | tâm ô (c, r): `x = (c − 110) × 64 + 32`, `y = (r − 80) × 64 + 32`. Vd: cổng Bắc (109, 11) → (−32, −4384); cổng đền (109, 107) → (−32, +1760) |
| So với Aldenmere | Nhỏ hơn Aldenmere (260×190) có chủ ý: Fenmire là hub cấp 2, mật độ kênh/nước ăn mất ~25% diện tích đi bộ; cảm giác "to" đến từ 2 lớp giao thông (đường ván trên nước + đường đất trên gò) chồng nhau |

### 1.2. Địa hình 2 gò + 1 trũng kênh

| Vùng cao độ | Hàng | Khu | Xử lý khi dựng |
|---|---|---|---|
| Trũng kênh/bến (thấp, ngang mực nước) | 13–46 (bắc) + dải nước nhà sàn hàng 97–104 | Bến thuyền, chợ nổi, Grand Canal, chân nhà sàn | Nền nước/ván; đi lại trên ván và thuyền |
| Gò giữa (vừa) | 47–106 | Hai khu dân chài nhà sàn, đường ván bờ kênh | Nền cỏ đầm/bùn khô, nhà sàn chân cao dần về phía nam |
| **Gò cao phía Nam (cao nhất)** | 107–146 | **Nội Thành Thượng — đền giáo phái**, nhà thương/kho thuốc, bãi muối | Nền bùn khô + đá lát quanh đền; bậc cấp lên cổng đền ở hàng 105–106 |

Cao độ chỉ là trình diễn (tông nền + bậc ván/thềm + bóng đổ), trừ mặt nước là collision thật và đường ván là sàn đi được tách lớp thị giác (xem §2.3).

### 1.3. Tổ chức node + hiệu năng (dự kiến khi dựng)

1 scene liền mạch (cổng Bắc → đền không load màn). Node theo khu: `Ground`, `Water`, `Boardwalks` (đường ván — lớp sàn trên nước), `Walls_Outer`, `Walls_Inner`, `District_ChoNoi / DanChaiTay / DanChaiDong / NhaThuong / BaiMuoi / DenGiaoPhai`, `NPCs`, `PatrolRoutes`, `Portals`, `Spawns`, `Player`, `HUD`.

Hiệu năng: mặt nước lớn dùng TileMapLayer + tile nước 2 pha (`swamp_v1`: `water_murky_a/b`); nhà sàn dự kiến 45–60 căn là PackedScene dùng chung; ~15 NPC có schedule. Đường ván là tile (`plank`/`plank_mossy` trong `swamp_v1`), không phải prop rời.

---

## 2. (a) TƯỜNG GỖ–ĐÁ + HÀO NƯỚC + CỔNG BẮC

### 2.1. Cù lao + tường ngoài — dày 3 ô

| Đoạn | Vị trí | Chi tiết |
|---|---|---|
| Đất cù lao | cột **8–211**, hàng **8–151** | Ngoài vành này là nước đầm/bùn ngập (cùng map, có collision nước) — thành thật sự "nổi" giữa đầm |
| Tường Bắc | hàng **10–12**, cột 10–209 | Hở cổng chính cột 104–115 (§2.2) |
| Tường Nam | hàng **147–149**, cột 10–209 | Không cổng — phía nam là đầm sâu và mặt sau gò đền |
| Tường Tây | cột **10–12**, hàng 10–149 | Hở **cổng nước / bến phà** hàng 57–59 (§8-P4) |
| Tường Đông | cột **207–209**, hàng 10–149 | Không cổng |
| **Hào nước trong tường** | vành 1 ô: hàng/cột **13** và hàng/cột **146** (sát mặt trong tường) | Hào chạy kín vòng trong tường — vừa là phòng thủ, vừa là kênh thoát/thoát nước triều; dân gánh nước và giặt ở hào đoạn gần khu dân (chi tiết sống) |
| Tháp canh ×4 | 5×5 ô tại 4 góc trong tường: (14–18, 14–18), (201–205, 14–18), (14–18, 141–145), (201–205, 141–145) | Tháp gỗ mái lá dốc (chống mưa bão), đèn lồng chống tắt; trang trí + collision, chưa vào trong |

Tường gỗ–đá: thân dưới đá cao ~1 ô thị giác (chống ngập/mối), trên là cọc gỗ + ván + mái che mưa chạy dọc — khác hẳn tường đá nguyên khối của Aldenmere. Chân tường phía ngoài có cọc chống xói và sậy mọc (dấu ấn Fenmire).

### 2.2. Cổng chính phía Bắc + cầu cạn

- **Vị trí:** cột **104–115**, hàng **10–12** — thẳng trục Grand Canal (cột 104–115). Lòng cổng rộng 12 ô vì vừa là cổng bộ vừa là **cửa kênh**: thuyền hàng qua cổng bằng đường nước ở giữa, người đi bộ qua 2 hành lang ván 2 bên (cột 104–105 và 114–115).
- **Cầu cạn vào thành:** cột **104–115**, hàng **0–9** — đường cạn/ván bắc qua đầm từ bờ bắc (đường Fenmire Approach, §8-P1) tới cổng. Hai bên cầu cạn là nước thật.
- Trên cổng: vòm gỗ + biển tên "FENMIRE" + chuông cảnh báo triều (chuông này là cơ chế: reo khi triều đổi — hook sang puzzle triều của Đền Chìm Triều) + 2 đèn lồng không bao giờ tắt.
- **Sân cổng / bến trong:** cột **97–123**, hàng **13–15** — đường ván 2 bờ kênh nối xuống, điểm spawn vào thành (§8), điểm dừng của lính canh cổng.

### 2.3. Đường ván trên mặt nước (cơ chế giao thông thứ hai — thay cho "mặt tường đi được" của Đông)

1. Mọi đường ván (bờ kênh, hẻm nhà sàn, bến chợ) là sàn ở lớp thị giác trên mặt nước: nhóm node `Boardwalks`, nhân vật đi trên ván vẽ trên mặt nước và trên bóng thuyền.
2. Va chạm: nước có collision toàn cục; ô có ván thì không collision — ván là "đất" theo dữ liệu tile, không cần layer-swap như cầu thang tường của Aldenmere. Rìa ván **không có lan can ở hẻm dân** (rơi xuống nước = bị đẩy về ô ván gần nhất + ướt/làm chậm, không chết) — cơ chế nhẹ, đúng chất đầm.
3. NPC dân chài dùng đường ván theo vòng 1 chiều ở hẻm hẹp (xem §10.1 của tài liệu này về kẹt NPC — áp dụng cùng quy tắc như hẻm Aldenmere).

---

## 3. TRỤC GIAO THÔNG CHÍNH

| Đường | Vị trí (cột × hàng) | Rộng | Vai trò |
|---|---|---|---|
| **Grand Canal** | cột **104–115**, hàng **13–104** | 12 ô (nước) | Xương sống của thành: thuyền chở thuốc/cá/muối chạy dọc; kết thúc ở **bể quay thuyền** hàng **100–104** trước cổng đền. Người chơi đi bộ 2 bờ, đi thuyền là dịch vụ của lái phà (NPC-14) sau quest |
| Đường ván bờ Tây kênh | cột **97–103**, hàng 13–106 | 7 ô | Trục bộ phía tây: cổng Bắc → chợ → dân chài Tây → bãi muối → cổng đền |
| Đường ván bờ Đông kênh | cột **116–123**, hàng 13–106 | 7 ô | Trục bộ phía đông: cổng Bắc → chợ → dân chài Đông → nhà thương → cổng đền |
| Đường ngang chợ | hàng **47–51**, cột 13–206 | 5 ô | Nối 2 khu dân chài qua cầu ván bắc qua kênh tại hàng 47–51 (cầu là điểm nghẽn sinh hoạt: gánh cá qua cầu buổi sáng) |
| Đường ngang nam | hàng **105–106**, cột 13–206 | 2 ô + bậc cấp | Chân gò cao: nối bãi muối ↔ cổng đền ↔ nhà thương; là "ranh giới xã hội" của thành — phía nam đường này là đất của giáo phái |

---

## 4. (b) QUẢNG TRƯỜNG CHỢ NỔI + BẾN THUYỀN — cột 64–155, hàng 16–46 (92 × 31 ô)

Đây là "quảng trường" của Fenmire — nhưng thay cho quảng trường lát đá có tượng/đài phun của Aldenmere, Fenmire có **một bể nước đầy sạp bè**:

- **Bể chợ nổi:** cột **76–143**, hàng **22–40** (68×19 ô nước) — **~28 sạp trên bè** neo thành 3 dãy lỏng (không thẳng hàng — bè xô lệch theo nước), mỗi bè 5×3 ô, bán cá/thuốc/thảo đầm/muối. Người mua đi bằng **thuyền con** (NPC chèo qua lại) hoặc đứng ở **vành ván quanh bể** (vành rộng 4–6 ô thuộc ô chợ) gọi với sang.
- **Bến thuyền:** dải cột **64–75** và **144–155**, hàng 16–46 — cọc neo, thuyền con, lưới phơi, thùng cá; điểm lên/xuống thuyền phà P4 phía tây nối tiếp ra cổng nước.
- **Bảng Nhiệm Vụ** tại **(66, 18)** góc tây-bắc chợ (điểm ★ trên sơ đồ) + **Cột Đèn Lớn** giữa bể tại (109, 31) — cột đèn dầu trên bè cố định, "đèn không tắt" thứ hai của thành (sau cổng Bắc): đèn chợ tắt = chợ đêm đóng, quái đầm bơi vào bể (hook sự kiện).
- Chức năng sống: sáng sớm bè cá vào bể (NPC chèo thật theo tuyến nước), trưa bè thuốc của giáo phái cập bến phía đông, tối chợ đèn lồng. Đây là nơi người chơi nghe được **cả 3 phe nói về nhau** một cách tự nhiên nhất (điểm điều tra xã hội của Phần 2).

---

## 5. CÁC KHU CHỨC NĂNG — KÍCH THƯỚC TỪNG KHU

### 5.1. (c) Khu Dân Chài Nhà Sàn — nhà sàn trên mặt nước, HẺM VÁN là chất sống

**Nguyên tắc bắt buộc:** nhà sàn chân cọc cao, sàn nhà ngang mặt đường ván; nhịp **nhà 8–12 ô mặt tiền + hẻm ván 2 ô**; phía nam mỗi khu nhà sàn đứng **trên dải nước thật** (hàng 97–104) — đi lại hoàn toàn bằng ván, nhìn xuống thấy nước và thuyền con neo dưới sàn nhà. Khác hẳn dân cư đất liền của Aldenmere.

**Dân Chài Tây — cột 16–96, hàng 52–104 → 81 × 53 ô, ~22 nhà sàn:**

| Hẻm ván | Vị trí | Loại |
|---|---|---|
| **H-T1 Hẻm Lưới Phơi** | hàng **64–65**, cột 16–96 (2 ô) | Hẻm chính ngang — lưới phơi + cá khô chăng 2 bên, NPC phơi lưới giờ sáng |
| **H-T2 Hẻm Chuông Triều** | hàng **78–79**, cột 16–96 | Hẻm chính ngang — có chuông con báo triều ở đầu đông (cột 94); tuyến gánh nước từ hào |
| **H-T3** | hàng **92–93**, cột 16–96 | Hẻm ngang phía nam — sát dải nước, ván thường ngập khi triều lên (đi chậm) |
| **V-1 / V-2 / V-3** | cột **36–37 / 60–61 / 84–85**, hàng 52–104 | Hẻm dọc nối 3 hẻm ngang + đường chợ (hàng 47–51) và đường nam (105–106) |
| **S-T Sân Ván Chung** | cột 44–56, hàng 82–90 (13×9 ô) | **Sân trong trên ván**: bếp chung, bàn cá, điểm sinh hoạt/bắt chuyện; nhà của Trưởng Dân Chài (NPC-04) nhìn ra sân này |

**Dân Chài Đông — cột 124–203, hàng 52–104 → 80 × 53 ô, ~21 nhà sàn:** đối xứng chức năng nhưng không đối xứng hình: hẻm ngang cùng hàng **64–65 / 78–79 / 92–93**, hẻm dọc cột **140–141 / 164–165 / 188–189**; sân ván chung **S-Đ** cột 152–164, hàng 82–90; nhà của **Người Giữ Triều già (NPC-12)** nấp ở cuối hẻm cụt phía đông-nam (cột 192–201, hàng 94–103) — nhà sàn trông bình thường nhất khu, là điểm điều tra quan trọng (Q4→Q5).

**Chi tiết sống bắt buộc trong hẻm ván** (node `Alley_Decor`): lưới phơi + cá khô (2–3 frame gió), thùng nước mưa ở đầu cọc, dây đèn lồng giấy dầu giữa 2 dãy nhà, thuyền con neo dưới sàn, gà vịt nuôi trong lồng treo dưới sàn nhà, biển số nhà bằng vỏ sò. Hẻm ván không có lưới phơi/đèn = chưa đạt thiết kế.

### 5.2. (d) Khu Chứa Thuốc + Nhà Thương của Giáo Phái — cột 144–203, hàng 110–140 → 60 × 31 ô

Khu này là **bằng chứng vật chất của thỏa thuận bán vùng**: giáo phái không chiếm thành bằng lính — họ chiếm bằng thuốc.

| Công trình | Vị trí (cột × hàng) | Kích thước | Chi tiết |
|---|---|---|---|
| **Nhà Thương Triều (Cult Hospice)** | cột 148–178, hàng 112–130 | 30×18 ô, nhà sàn lớn mái cao | Giường bệnh xếp dãy nhìn qua cửa (không làm nội thất riêng giai đoạn này — tương tác ở cửa + sân); nơi phát thuốc theo **danh sách** — ai có tên trong sổ mới được thuốc (cơ chế điều tra: sổ phát thuốc là chứng cứ Q2/Q6) |
| **Phòng Vua Bệnh** | cột 176–190, hàng 114–126 (trong khuôn viên nhà thương, nhà riêng áp đông) | 14×12 ô | **King Oswin nằm điều trị tại nhà thương của giáo phái** — vua của Fenmire là bệnh nhân của kẻ mua nước mình. Gặp vua ở đây theo quest (NPC-11), luôn có y sĩ giáo phái túc trực |
| **Kho Thuốc** | cột 182–201, hàng 132–139 + hầm dưới kho | dãy 19×7 ô | Kho khóa 2 lớp, lính giáo phái canh; **hầm kho nối Cống Ngập** (§8-P2) — đường điều tra lén của Q5/Q6 |
| Sân phát thuốc | cột 148–172, hàng 132–139 | 24×7 ô | Hàng người chờ phát thuốc buổi sáng (hàng NPC tĩnh có thoại luân phiên) — điểm người chơi thấy rõ nhất cái giá của thỏa thuận |

### 5.3. (e) Bãi Muối + Sơ Chế Cá — cột 16–76, hàng 110–140 → 61 × 31 ô

- Ô phơi muối/cá lát ván + bạt: cột 20–56, hàng 114–132; kho muối cột 60–74, hàng 114–126; bến muối nhỏ ở mép tây (cột 16–19) nối cổng nước P4.
- Đây là khu lao động của dân chài phía nam + điểm làm việc của NPC-05 (dân chài) buổi chiều; tương phản cố ý: phía tây-nam là **dân lao động**, phía đông-nam là **giáo phái phát thuốc**, ở giữa là **đền** — bản đồ xã hội của Fenmire đọc được bằng mắt.

### 5.4. (f) Nội Thành Thượng — Khu Đền Giáo Phái — cột 84–135, hàng 107–146 → 52 × 40 ô

Sau tường trong (§6). Bố cục gồm:

| Hạng mục | Vị trí | Kích thước | Chi tiết |
|---|---|---|---|
| **Đền Triều Chìm — Sanctum of the Sunken Tide** | cột **92–127**, hàng **116–138** | **36×23 ô** | Đền chính của giáo phái trong thành (đây là **đền hành chính/nghi lễ**, không phải dungeon Đền Chìm Triều ngoài đầm): mái dốc 3 lớp, sân nghi lễ lát đá ướt phía trước (hàng 112–115), chuông triều lớn, tượng thần mặt mài nhẵn như tượng ở dungeon — motif lặp có chủ ý |
| **Bể Triều Nghi Lễ** | cột **100–119**, hàng **141–144** | 20×4 ô | Bể nước dài nối thẳng ra kênh ngầm — mực nước trong bể khớp chu kỳ triều của dungeon (gợi ý cơ chế cho người chơi tinh ý) |
| Nhà giáo sĩ + nhà khách | cột 86–90 và 129–133, hàng 116–138 | 2 dãy hẹp | Nhà của Đại Giáo Sĩ (NPC-09) và chỗ ở của tín đồ trực đền |
| Sân trong đền | cột 92–127, hàng 139–145 (trừ bể) | — | Điểm **đối chất cuối Phần 2 (Q6)**: 3 phe + vua bệnh được đưa tới đây; bố cục sân phải đủ rộng cho cutscene nhiều NPC |

Vào bằng **cổng đền** (cột 104–115, hàng 107–108) — gate theo quest (điều kiện: xong Q5 hoặc đi đường Cống Ngập lén vào — xem §8-P3).

---

## 6. TƯỜNG TRONG (bao Nội Thành Thượng)

- **Vị trí:** hàng **107–108**, cột 84–135 (mặt bắc); cột **84–85** và **134–135**, hàng 107–146 (2 mặt hông); mặt nam là tường ngoài thành (hàng 147–149). Gỗ–đá như tường ngoài nhưng sạch và có treo bùa giấy + đèn tím của giáo phái (dấu hiệu "đất này của đền").
- **Cổng đền:** cột **104–115**, hàng **107–108**, thẳng trục kênh. Luôn có 2 tín đồ canh; mở theo trạng thái quest (`required_flag` của tuyến Nam), không khóa cứng — và **không phải đường duy nhất**: Cống Ngập (§8-P2) là đường vào thứ hai cho lối chơi điều tra/lén.

---

## 7. DANH SÁCH NPC THÀNH + LỊCH TRÌNH TÓM TẮT

Quy ước schedule như hệ NPC sống của game (xem `aldenmere_layout.md` §7): mỗi NPC có vòng `Ngủ → Đi làm → Làm việc (có animation việc) → Nghỉ → Việc chiều → Dạo/chợ → Về nhà`. Giờ là giờ trong game; "điểm việc" ghi ô lưới để hệ waypoint dùng trực tiếp.

| # | NPC (id) | Vai trò / quest | Nhà | Điểm làm việc chính (ô) | Lịch trình tóm tắt |
|---|---|---|---|---|---|
| 01 | **Lính Canh Cổng Bắc** (`linh_canh_bac_fen`) | Canh cổng + chuông triều | Nhà gác cổng (98, 14) | Đứng (106, 14) + (113, 14) 2 bên cổng kênh | 05:30 dậy → 06:00–18:00 canh cổng, **đánh chuông khi triều đổi** (sáng/chiều) → 18:00 bàn giao ca đêm (lính ca đêm là node tĩnh) → về |
| 02 | **Người Giữ Đèn Chợ** (`giu_den_cho`) | Giữ cột đèn lớn bể chợ | Nhà sàn Đông (150, 58) | Cột đèn bể chợ (109, 31) — đi thuyền con | 16:00 chèo ra cột đèn châm dầu → 17:00–22:00 trực đèn ở bè đèn → khuya chèo về. Ban ngày sửa đèn/lưới ở bến đông (150, 30). NPC "đồng hồ sống" buổi tối của thành |
| 03 | **Tiểu Thương Bè Cá** (`tieu_thuong_be`) | Sạp bè ở chợ nổi, shop cá/thảo đầm | Nhà sàn Tây (30, 70) | Bè sạp tại bể chợ (96, 30) — **chèo thuyền từ nhà ra sạp** | 04:30 dậy → 05:00 chèo ra bể → 05:30–11:00 bán → 11:30 chèo về ăn → 14:00–18:00 bán buổi chiều → phủ bạt bè → về |
| 04 | **Trưởng Dân Chài** (`truong_dan_chai`) | Đầu mối phe dân chài, quest `nam_04` | Nhà nhìn ra Sân Ván Chung Tây (50, 84) | Sân Ván Chung (50, 86); sáng ở bến cá (70, 28) | 05:00 ra bến xem cá vào → 07:00–11:00 ở sân ván (gặp để nhận/trả quest) → chiều vá lưới ở H-T1 (50, 64) → tối họp dân ở sân đến 21:00 |
| 05 | **Dân Chài** (`dan_chai_1`) | Thoại đời sống/lore giá thuốc | Nhà sàn Tây (66, 88) | Sáng: bè cá bể chợ (120, 34); chiều: bãi muối (38, 122) | 05:00–10:00 phụ bè cá → 10:30 về nhà → 13:00–17:30 làm ở bãi muối → tối ngồi hẻm H-T2 nghe ngóng (điểm bắt chuyện lore) |
| 06 | **Trẻ Con Nhà Sàn** (`tre_con_san`) | Chạy chơi trên ván, quest nhỏ | Nhà sàn Đông (172, 70) | Vòng quanh bể chợ trên vành ván + cầu hàng 47–51 | 07:00 dậy → 08:00–11:00 chạy vòng vành bể chợ (không xuống thuyền) → chiều trốn tìm ở hẻm H-Đ cụt gần nhà Người Giữ Triều (196, 96) — **đứa trẻ này là người đầu tiên hé lộ "ông già biết triều"** → 17:30 về |
| 07 | **Y Sĩ Giáo Phái** (`y_si_giao_phai`) | Phát thuốc ở Nhà Thương, quest `nam_02`/`nam_06` | Phòng trực nhà thương (152, 116) | Sân phát thuốc (160, 135); trong nhà thương (163, 120) | 06:00 dậy → 07:00–11:00 phát thuốc theo sổ ở sân → 11:00–16:00 trực nhà thương (gặp theo quest) → 16:00 đi bè thuốc ở bể chợ phía đông nhận hàng → tối ghi sổ ở phòng trực |
| 08 | **Thủ Kho Thuốc** (`thu_kho_thuoc`) | Canh kho thuốc, đầu mối Cống Ngập | Nhà gác kho (186, 134) | Cửa kho (191, 131) | 06:00–12:00 canh kho → 12:00–13:00 **bỏ vị trí đi ăn ở chợ** (khe hở thời gian cho lối điều tra — người chơi tinh ý sẽ nhận ra) → 13:00–19:00 canh → tối khóa kho, treo đèn, về |
| 09 | **Đại Giáo Sĩ Triều Chìm** (`dai_giao_si`) | Đầu mối phe giáo phái, quest `nam_05`/`nam_06` | Nhà giáo sĩ trong nội thành (88, 124) | Đền (109, 124); chiều ra sân phát thuốc (160, 133) | 05:00 tụng triều ở đền → 08:00–11:00 tiếp dân trong đền (gặp theo quest) → 15:00 ra nhà thương thị sát phát thuốc → 18:00 nghi lễ triều tối ở bể nghi lễ (109, 142) → về |
| 10 | **Morvain — Người Giữ Triều** (`morvain`) | Boss/đồng minh tùy lựa chọn Phần 2 | Không có nhà trong thành — xuất hiện theo pha quest | Pha điều tra: bể nghi lễ (109, 142); pha đối chất: sân đền (109, 142)→(109, 120) | NPC theo **trạng thái quest**, không chạy schedule thường: chỉ xuất hiện khi tuyến Nam chạm mốc `nam_05` trở đi. Trước đó dân chỉ nói về bà ta — sự vắng mặt có chủ ý |
| 11 | **King Oswin** (`vua_oswin`) *(tên mới, chờ duyệt)* | Vua Nam — người ký thỏa thuận bán vùng | **Phòng Vua Bệnh ở Nhà Thương** (183, 120) | Nằm điều trị (183, 120); pha đối chất được đưa ra sân đền | NPC tĩnh theo quest: gặp được khi có flag của `nam_02` trở đi; thoại thay đổi theo chứng cứ người chơi đã thu (hệ đối chất của Phần 2) |
| 12 | **Người Giữ Triều Già** (`giu_trieu_gia`) | Đầu mối phe Người Giữ Triều, quest `nam_04`/`nam_05` | Nhà sàn cụt Đông-Nam (196, 98) | Nhà (196, 98); sáng sớm ra hào nước (200, 144) đọc triều | 04:30 dậy, ra hào **đọc mực nước** (anim cúi xem vạch triều) → về nhà, **không tiếp người lạ cho đến khi có giới thiệu của Trưởng Dân Chài hoặc Trẻ Con Nhà Sàn** → tối thắp 1 đèn nhỏ hướng ra đầm (điểm nhận diện từ xa) |
| 13 | **Tín Đồ Trẻ** (`tin_do_tre`) | Tín đồ giáo phái bắt đầu nghi ngờ — nguồn tin nội bộ, quest `nam_03`/`nam_05` | Phòng tập sự ở nhà thương (156, 126) | Phụ phát thuốc (166, 135); trưa ở bể chợ vành đông (140, 30) | Schedule như y sĩ phụ tá; **điểm bắt chuyện riêng ở bể chợ giờ trưa** — nơi cậu ta hé lộ chuyện "thuốc thử trên người bệnh nặng" nếu người chơi đã có chứng cứ Venomfen |
| 14 | **Người Lái Phà** (`lai_pha`) | Dịch vụ phà P4 + thuyền kênh | Nhà sàn Tây (24, 58) | Bến phà cổng nước (16, 58); khi mở dịch vụ kênh: bể quay thuyền (109, 102) | 06:00–18:00 trực bến phà (chèo khách ra Blackmere khi được gọi) → tối neo thuyền, về nhà. Sau `nam_04`, mở thêm tuyến thuyền dọc Grand Canal (đi nhanh trong thành) |
| 15 | **Lính Tuần Kênh** (`linh_tuan_kenh`) | Tuần tra 2 bờ kênh | Nhà gác cổng (120, 14) | Tuyến: cổng Bắc (110, 14) → bờ tây xuống (100, 60) → cầu chợ (110, 49) → bờ đông lên (120, 30) → vòng lại; chiều đổi chiều vòng | 06:00–11:00 tuần vòng kênh → nghỉ ở sân cổng → 13:00–18:00 tuần vòng ngược → về. Tuyến tuần duy nhất của thành — thành này **ít lính hẳn** Aldenmere (giáo phái cai bằng thuốc, không bằng quân) |

**Tổng: 15 NPC** (13 chạy schedule sống + Morvain và King Oswin theo trạng thái quest) — ít lính, nhiều dân chài/y sĩ: thành phần NPC tự nó nói lên cách Fenmire bị cai trị.

---

## 8. SƠ ĐỒ KẾT NỐI PORTAL + ĐIỂM SPAWN

Quy ước giữ nguyên hệ hiện tại (`systems/portal.tscn`: `target_scene` + `target_spawn = "from_<key>"`). Key của thành Fenmire là `fenmire`.

| # | Điểm trong thành (ô) | Cơ chế | Đích | Spawn ở đích | Spawn quay về trong thành | Ghi chú |
|---|---|---|---|---|---|---|
| P1 | **Cổng Bắc** (109, 11) | Portal 2 chiều ở lòng cổng + cầu cạn | `maps/fenmire_approach.tscn` — **Fenmire Approach** (đường vào thành, xem `fenmire_so_do.md`) | `from_fenmire` | `Spawn_from_approach` tại **(109, 14)** ở sân cổng, mặt hướng nam = cả `Spawn_start` | Approach nối tiếp lên Sunken Tide Temple và đường về Reedmere |
| P2 | **Miệng Cống Ngập** ở hầm Kho Thuốc (196, 136) *(ô đánh dấu trên sơ đồ ở góc đông-nam khu nhà thương)* | Portal nắp cống (tương tác, cần đã vào được hầm kho — qua quest hoặc khe hở giờ ăn trưa của NPC-08) | `maps/cong_ngap_fenmire.tscn` — **Fenmire Cistern / Cống Ngập** (scene dungeon nhỏ dự kiến) | `from_fenmire` | `Spawn_from_cong` tại **(194, 134)** — trong sân kho, tránh đè nắp cống | Cống Ngập nối: hầm kho thuốc ↔ **sau lưng đền trong Nội Thành Thượng** (đường vào lén, §6) ↔ cửa ngầm ra đầm hướng Sunken Tide Temple. Đây là xương sống lối chơi điều tra của Phần 2 trong thành |
| P3 | **Cổng đền** (109, 107) | **Không phải portal** — cổng trong cùng scene, khóa bằng `required_flag` quest | Trong cùng scene (Nội Thành Thượng) | — | — | 2 tín đồ canh (trong tốp NPC đền); mở khi xong `nam_05` hoặc khi người chơi đã vào nội thành bằng P2 rồi mở từ trong |
| P4 | **Cổng nước / Bến phà Tây** (14, 58) | Portal phà (nói chuyện với NPC-14 để đi — portal có điều kiện NPC) | `maps/blackmere.tscn` — **Blackmere** (bến phà bờ đông hồ) | `from_fenmire` | `Spawn_from_blackmere` tại **(17, 58)** — trên bến phà trong tường | Đường tắt về hồ sau khi đã mở phà ở `nam_04`; trước đó cổng nước khóa, phà không chạy |

**Bảng spawn trong thành (cho dev):**

| Marker | Ô (cột, hàng) | Pixel Godot (tâm ô) | Nguồn đến |
|---|---|---|---|
| `Spawn_start` = `Spawn_from_approach` | (109, 14) | (−32, −4192) | Fenmire Approach / vào thành lần đầu |
| `Spawn_from_cong` | (194, 134) | (+5408, +3488) | Fenmire Cistern (Cống Ngập) |
| `Spawn_from_blackmere` | (17, 58) | (−5920, −1376) | Blackmere (phà) |

---

## 9. DANH SÁCH TILE / PROP MỚI CẦN BỘ PHẬN ART LÀM

Chuẩn chung: tileset 64px, prop pixel art chi tiết cao (vẽ lớn rồi downscale như chuẩn đã chốt), palette Fenmire: xanh lục đậm u ám, nâu bùn, xám bão, teal nước đầm; accent vàng đèn lồng/cam lửa. **Đã có sẵn bản mẫu v1:** tileset `game/assets/tilesets/swamp_v1.png/.tres` + prop `mangrove / reed_clump / glowshroom / swamp_log` (xem trạng thái art ở `fenmire_so_do.md` §6) — danh sách dưới đây là phần CÒN THIẾU để dựng thành.

### 9.1. Tile (TileMap, ô 64px)

| Tile | Trạng thái / ghi chú |
|---|---|
| Nước đục xanh rêu 2 pha, nước sâu | ✅ Đã có ở `swamp_v1` (`water_murky_a/b`, `water_deep`) |
| Bùn ướt, bùn khô nứt, cỏ đầm, cỏ sậy | ✅ Đã có ở `swamp_v1` |
| Đường ván gỗ + ván rêu + mép ván nhìn xuống nước | ✅ Đã có (`plank`, `plank_mossy`, `plank_edge_s` — còn thiếu mép 3 hướng còn lại) |
| Bờ nước chuyển tiếp 4 hướng + góc lồi/lõm (cỏ↔nước), bờ bùn↔nước | ✅ Đã có ở `swamp_v1` |
| Nền lát đá ướt quanh đền, nền sân ván chợ (vành bể) | ⬜ Chưa có — cần mới |
| Mặt hào/cống trong nhà (đá ướt tối, cho Cống Ngập) | ⬜ Chưa có — gộp vào bộ dungeon đầm sau |
| Vạch triều khắc trên cọc đá (tile trang trí có số/vạch) | ⬜ Chưa có — prop nhỏ cũng được |

### 9.2. Prop / kiến trúc (sprite riêng, y-sort)

| Prop | Kích thước gợi ý (px) | Ghi chú |
|---|---|---|
| **Nhà sàn dân chài** | mặt tiền 8–12 ô → 512–768 px rộng, sàn cao ~1 ô thị giác | **3–4 biến thể** (mái lá/mái ván, tường ván/vách đất), có cầu thang ván lên sàn + lồng gà dưới sàn; bản có lưới phơi trước hiên |
| **Tường gỗ–đá thành** (đoạn 2 ô) | 128×128 / đoạn | Thân đá thấp + cọc gỗ + mái che mưa; + góc, + đoạn có tháp canh gỗ 320×384 |
| **Cổng Bắc + cổng nước** | cổng chính 768×256 (12×4 ô); cổng nước 256×192 | Vòm gỗ, biển "FENMIRE", chuông triều, đèn lồng 2 frame sáng |
| **Đền Triều Chìm (trong thành)** | 2304×1472 vùng chân 36×23 ô — vẽ module: thân đền 768×640 + mái 3 lớp chồng | Đá ướt phủ rêu, tượng thần mặt mài nhẵn, chuông triều lớn — prop quan trọng nhất thành |
| **Sạp bè chợ nổi** | 320×192 (5×3 ô) / bè | **3 biến thể**: bè cá (thùng + lưới) / bè thuốc (lọ + bạt tím giáo phái) / bè thảo đầm (giỏ sậy); mỗi biến thể + bản phủ bạt |
| **Thuyền con + thuyền phà** | thuyền con 160×64, phà 256×96 | 2 frame chèo (dùng cho NPC di chuyển trên kênh/bể) |
| **Cột đèn lớn bể chợ** | 96×320 | Đèn dầu trên bè cố định, hào quang ấm; 2 trạng thái ngày/đêm |
| **Cọc neo + thùng cá + lưới phơi đứng** | 64×96, 96×96, 192×128 | Dùng lặp ở bến/hẻm |
| **Giường bệnh + bình thuốc lớn (nhà thương)** | giường 128×64, bình 64×96 | Đặt ở sân/hiên nhà thương (không nội thất giai đoạn này) |
| **Bùa giấy giáo phái + đèn tím** | 48×96, 48×80 | Treo ở tường trong/cổng đền — dấu hiệu lãnh địa giáo phái |
| **Cây đước, bụi sậy, nấm độc phát sáng, gỗ mục** | xem `game/assets/props/mangrove.png` v.v. | ✅ Đã có bản mẫu v1 trong `swamp` pipeline |

---

## 10. RỦI RO / LƯU Ý KHI DỰNG SCENE SAU

1. **Hẻm ván 2 ô vs hitbox:** ván 2 ô (128px) đi 2 chiều được, nhưng NPC chèo/gánh cá ngược chiều vẫn kẹt ở cầu thang lên sàn — schedule dân chài phải đi hẻm theo vòng 1 chiều (vào hẻm dọc tây, ra hẻm dọc đông) và không dừng nói chuyện giữa hẻm (điểm dừng chỉ ở sân ván/bến).
2. **Hai lớp giao thông (ván trên nước):** thuyền NPC chạy trên kênh/bể là node di chuyển tự do trên mặt nước — phải tách vùng di chuyển của thuyền (kênh + bể + dải nước nhà sàn) khỏi vùng đi bộ; thuyền không được "leo" lên ô đất khi tìm đường (dùng navigation region riêng cho thuyền).
3. **Triều thay đổi mực nước:** nếu làm cơ chế triều trong thành (hẻm H-T3 ngập theo giờ) thì collision của ô ngập phải đổi theo trạng thái triều — làm bằng 1 TileMapLayer phụ bật/tắt + vùng làm chậm, không đổi tile nền. Chuông triều của NPC-01 là tín hiệu báo cho người chơi.
4. **Y-sort nhà sàn:** origin nhà sàn đặt ở chân cọc phía nam; thuyền con neo dưới sàn ở phía bắc nhà phải vẽ dưới sàn nhưng trên nước — cần lớp z riêng cho "dưới sàn nhà" (tương tự vấn đề mặt tường của Aldenmere, §10.2 ở tài liệu đó).
5. **Cổng đền là gate quest, không khóa cứng:** luôn tồn tại đường P2 (Cống Ngập) vào nội thành — khi dựng phải test cả 2 đường vào và trường hợp người chơi vào bằng P2 trước khi gặp NPC canh cổng (thoại canh cổng phải có biến thể "ngươi vào bằng đường nào?!" — chi tiết lore đáng giữ).
6. **Khối lượng bè sạp ở chợ nổi:** ~28 bè + thuyền NPC qua lại là điểm nghẽn hiệu năng/AI nhất thành — dựng bể chợ xong phải playtest riêng khu này trước khi nhân bản các khu khác.
7. **Vua bệnh nằm ở nhà thương:** vị trí NPC-11 phụ thuộc flag quest — khi dựng, chuẩn bị sẵn 2 điểm hiện diện (giường nhà thương / sân đền pha đối chất) và chuyển bằng flag, không spawn 2 bản.

---

## 11. ĐIỂM CẦN DUYỆT TRƯỚC KHI DỰNG

1. **Bố cục tổng thể + kích thước 220×160** theo sơ đồ `fenmire_layout.png` (vẽ đúng lưới này) — đặc biệt: đền giáo phái ở gò cao phía NAM, cổng chính phía BẮC, Grand Canal làm trục thay đại lộ.
2. **Tên vua Nam "King Oswin"** — tên mới đề xuất trong tài liệu này (tài liệu cũ chưa đặt tên vua Nam; Morvain đã chốt là Người Giữ Triều sống sót, không phải vua). User duyệt hoặc đổi tên trước khi gắn vào quest/thoại.
3. **Chợ nổi thay quảng trường tượng/đài phun** — quảng trường của Fenmire là bể nước + sạp bè, không có tượng lớn ở giữa (tượng thần mặt mài nhẵn chỉ ở đền) — duyệt hướng "thành nước" này hay muốn thêm 1 quảng trường đất nhỏ ở sân cổng?
4. **Cống Ngập làm scene dungeon nhỏ riêng** (`cong_ngap_fenmire.tscn`) nối kho thuốc ↔ đền ↔ ngoài đầm — duyệt phạm vi (1 scene nhỏ 3 nhánh) hay gộp đường cống thành 1 phòng hầm đơn giản dưới kho thuốc ở giai đoạn đầu?
5. **King Oswin không có cung điện riêng** — vua nằm ở nhà thương giáo phái (chủ ý cốt truyện). Nếu user muốn có dinh vua (dù bỏ trống/bị giáo phái mượn) thì cần thêm 1 khu — hiện tại vị trí ứng viên là dải cột 16–60, hàng 16–46 phía tây chợ (đang là đất trống dự phòng trong sơ đồ).

---

*Tài liệu này chỉ thiết kế để duyệt bố cục. Chưa dựng scene thành. Sơ đồ trực quan: `fenmire_layout.png` (đúng lưới 220×160).*
