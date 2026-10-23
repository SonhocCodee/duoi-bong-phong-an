# ALDENMERE — LAYOUT CHI TIẾT (Thiết kế để duyệt bố cục, chưa dựng scene)

> **Game:** Dưới Bóng Phong Ấn — Godot 4, Action RPG top-down
> **Loại tài liệu:** Thiết kế bố cục map thành — CHỈ tài liệu + sơ đồ, chưa dựng/sửa `.tscn`/`.gd`
> **Sơ đồ kèm theo:** `design/aldenmere_layout.png` — vẽ ĐÚNG lưới 260×190 của tài liệu này (cùng hệ tọa độ), không phải sơ đồ tượng trưng thu nhỏ.
> **Nguồn đối chiếu:** `design/world_v2_4_thanh.md` §2.1 (Vùng Đông, Trụ Mộc, King Aldric, Cổ Thụ), `design/vung_dong_so_do.md`, và các scene hiện hữu `thanh_xuan_lam.tscn`, `hoang_cung.tscn`, `ngoai_thanh.tscn`, `cong_ngam.tscn`, `ham_ruou.tscn` (chỉ đọc để giữ quan hệ portal/spawn).
> **Chuẩn art bắt buộc (chốt 2026-10-23):** tileset + prop pixel art chi tiết cao kiểu Stardew Valley, ghép bằng TileMap, nhân vật đi lại/Y-sort/va chạm tự nhiên, nội thất là map riêng. Không dùng ảnh render phẳng cho khu đi lại được. Thành là map TRỌNG ĐIỂM SỐ 1 của game (hình dung: Mondstadt của Genshin Impact chuyển thành 2D top-down).
> **Quy ước tên hiển thị (fantasy châu Âu, chốt 2026-10-23):** thành = **Aldenmere**; cung điện = **Royal Palace of Aldenmere**; hầm dưới quán rượu = **Elmford Cellar**; cống = **Aldenmere Sewers**; ngoài cổng nam = **The Wallfoot**; làng khởi đầu = **Elmford**; vua bù nhìn Đông = **King Aldric**. Tên file/scene giữ slug nội bộ cũ (`thanh_xuan_lam.tscn`...) — chỉ tên HIỂN THỊ đổi.

---

## 0. HIỆN TRẠNG SCENE CŨ (cái gì đang nối đi đâu — phải giữ khi dựng lại)

Scene `thanh_xuan_lam.tscn` hiện tại là bản prototype cỡ test (~30×22 ô): 1 lớp tường, nhà Polygon2D thô, 4 NPC đứng yên (chu_quan, tho_ren, linh_gac, linh_gac_nam), chưa có chợ/quảng trường tượng/tường trong/mặt tường đi được/hẻm. Các *quan hệ nối* sau là đúng và PHẢI giữ (§8): Nam → `ngoai_thanh.tscn` (The Wallfoot); Bắc → `hoang_cung.tscn` (Royal Palace); miệng cống → `cong_ngam.tscn` (Aldenmere Sewers); cầu thang quán/trọ → `ham_ruou.tscn` (Elmford Cellar). Đường lên Cloudpeak đi qua The Wallfoot (`ngoai_thanh` có PortalWest → `nui_thanh_van`) — thành không cần cổng bắc ra ngoài.

---

## 1. CHUẨN KÍCH THƯỚC (áp dụng chuẩn map toàn game user chốt sau khi chơi thử bản mở đầu)

User chơi thử và chốt: map cỡ test ~30×22 ô là QUÁ BÉ. Chuẩn kích thước dựng thật cho toàn game:

| Loại map | Chuẩn tối thiểu | Ghi chú |
|---|---|---|
| Làng (Elmford) | ~100×75 ô (≈6400×4800 px) | Đi đầu làng → cuối làng phải mất công đi thật |
| Map dã ngoại (Barleyfield, Elderwood, Mistlake...) | ~140×100 ô (≈8960×6400 px) | Nhiều khu con: bãi quái, tài nguyên, lối tắt, điểm mốc |
| Dungeon | Nhiều phòng/hành lang nối nhau, đi hết vài phút | Không 1 phòng trống |
| **Thành Aldenmere (tài liệu này)** | **260×190 ô = 16.640×12.160 px** | Lớn nhất game; tương đương ~2,6 làng theo chiều ngang |

### 1.1. Kích thước thành + hệ tọa độ

| Thông số | Giá trị |
|---|---|
| Kích thước map | **260 cột × 190 hàng ô = 49.400 ô** (16.640 × 12.160 px) |
| Tile | 64 × 64 px (chuẩn tileset đã chốt; nhân vật sprite 128px, hitbox player 28px) |
| Hệ tọa độ tài liệu | Ô (cột, hàng): cột 0–259 Tây→Đông, hàng 0–189 Bắc→Nam |
| Đổi sang Godot (gốc tại tâm map, y dương xuống) | tâm ô (c, r): `x = (c − 130) × 64 + 32`, `y = (r − 95) × 64 + 32`. Vd: cổng chính (129, 188) → (−32, +5984); cổng cung (129, 4) → (−32, −5792) |
| Camera | Camera2D theo player, limit đúng biên map; map ≈ 8,7 × 6,3 màn hình 1920×1080 — cảm giác "thành phố thật" |

### 1.2. Địa hình 3 thềm (leo dần lên phía bắc — Nội Thành ở điểm cao nhất)

| Thềm | Hàng | Khu | Xử lý khi dựng |
|---|---|---|---|
| Thềm 3 (cao nhất) | 3–44 | Nội Thành Thượng (phủ King Aldric, Đền, Cổ Thụ, cổng Royal Palace) | Nền lát đá sáng, 2 bậc thềm tại cổng nội thành |
| Thềm 2 (giữa) | 48–110 | Khu Nghề, Tiền Sân + Quảng Trường, Khu Chợ | 1 bậc thềm + dốc ở hàng 110–111 trên đại lộ và 2 phố bên |
| Thềm 1 (thấp) | 111–186 | Dân Cư Tây/Đông, Khu Quân Sự, Sân Cổng | Nền đá/đất thường |

Thềm chỉ là trình diễn (tông nền + bậc thang trang trí + bóng đổ), trừ mặt tường đi được (§2.3) là khu đi lại tách lớp thật.

### 1.3. Tổ chức node + hiệu năng (dự kiến khi dựng)

1 scene liền mạch (cổng chính → Royal Palace không load màn). Node theo khu: `Ground`, `GroundDetails`, `Walls_Outer`, `Walls_Inner`, `WallTop_Walkable`, `District_NoiThanh / QuangTruong / Cho / Nghe / DanCuTay / DanCuDong / QuanSu`, `Alley_Decor` (dây phơi/cầu mái ở z trên mái), `NPCs`, `PatrolRoutes` (Marker2D P/Q), `Portals`, `Spawns`, `Player`, `HUD`.

Hiệu năng: 49.400 ô nền là việc của TileMapLayer (vẽ theo chunk); prop/nhà dự kiến 800–1.200 node tĩnh (PackedScene dùng chung, collision tĩnh gộp theo khu — 1 StaticBody2D/khu), ~17 NPC có schedule. Phương án dự phòng nếu FPS < 45 ở chợ giờ cao điểm: bật/tắt `visible`/`process_mode` theo District theo khoảng cách camera — KHÔNG tách thành map riêng có portal (phá trải nghiệm liền mạch + tuyến tuần xuyên khu).

---

## 2. (a) TƯỜNG NHIỀU LỚP + MẶT TƯỜNG ĐI ĐƯỢC

### 2.1. Tường ngoài (bao toàn thành) — dày 3 ô

| Đoạn | Vị trí | Chi tiết |
|---|---|---|
| Tường Bắc | hàng 0–2, cột 0–259 | Sau lưng tiền khu Royal Palace — phông nền, không cổng ra ngoài |
| Tường Nam | hàng 187–189, cột 0–259 | Hở cổng chính cột 127–132 (§2.2) |
| Tường Tây | cột 0–2, hàng 0–189 | Chân tường trong trồng dây leo hoa — dấu ấn Aldenmere |
| Tường Đông | cột 257–259, hàng 0–189 | Không cổng |
| Tháp góc ×4 | 6×6 ô tại 4 góc (0–5, 0–5), (254–259, 0–5), (0–5, 184–189), (254–259, 184–189) | Tháp đá mái ngói rêu, cửa sổ hẹp; trang trí + collision, chưa vào trong |
| Tháp giữa đoạn ×4 | Tây (0–2, 92–97), Đông (257–259, 92–97), Bắc (78–83, 0–2) và (176–181, 0–2) | Tạo nhịp thị giác, tránh tường dài đơn điệu |

### 2.2. Cổng chính phía Nam + 2 tháp canh

- **Vị trí:** cột **127–132**, hàng **187–189** — thẳng trục đại lộ (cột 127–132). Lòng cổng rộng 6 ô (384px). Portal sang The Wallfoot (§8-P1).
- **2 tháp canh kẹp cổng:** tháp S1 cột **113–125**, hàng **181–189** (13×9 ô); tháp S2 cột **134–146**, hàng **181–189**. Thân cao hơn tường 1 tầng mái, ban công nhìn ra ngoài.
- Trên cổng: vòm đá + biển tên "ALDENMERE" + cờ Mộc trụ + 2 đèn lồng. Cánh gỗ mở cố định ban ngày (để sẵn hook đóng trong sự kiện cốt truyện).
- **Sân cổng** (trong thành): cột **113–147**, hàng **154–180** — điểm dừng canh của lính tuần, bảng chỉ đường, điểm spawn vào thành.

### 2.3. Mặt tường ĐI LÊN ĐƯỢC (cơ chế bắt buộc — 2 đoạn)

| Đoạn | Mặt tường đi được | Cầu thang lên | Nhìn xuống |
|---|---|---|---|
| **T1 — Tường Nam** | hàng **187–188**, cột **3–112** và **147–256** (+ cầu nối nóc cổng/tháp cột 113–146 ở cùng lớp cao) | **S1:** cột **117–120**, hàng **172–180** (trong sân cổng, phía tây); **S2:** cột **139–142**, hàng **172–180** (phía đông) | The Wallfoot + đường nam ngoài thành; sân cổng + biển mái dân cư Nam bên trong |
| **T2 — Tường Trong** | hàng **45–46**, cột **3–126** và **133–256** (đứt ở cổng nội thành) | **S3:** cột **121–124**, hàng **48–51**; **S4:** cột **135–138**, hàng **48–51** | Toàn cảnh thềm 2 phía nam; sân Nội Thành + Cổ Thụ phía bắc — điểm ngắm "Mondstadt 2D" đẹp nhất map |

Cơ chế khi dựng (ghi rõ để dev không làm sai):
1. Mặt tường là sàn riêng ở lớp cao: nhóm node `WallTop_Walkable`, `z_index` cao hơn mọi mái nhà kề, nhân vật trên tường vẽ trên mái phía dưới (chấp nhận phá y-sort cục bộ, §10).
2. Collision 2 mép: line collision liên tục dọc 2 mép mặt tường, chỉ hở đúng vị trí cầu thang S1–S4 và cầu nối. Không có cơ chế rơi.
3. Chuyển lớp tại cầu thang: `Area2D StairTrigger` ở chân thang bật/tắt 2 bộ collision (mặt đất ↔ mặt tường) — cơ chế layer-swap tại điểm kiểu cầu 2 tầng Stardew, không portal đổi scene, không teleport. NPC thường không dùng mặt tường; chỉ lính tuần B có 1 chặng lên T1 (§7) và lính gác đêm đứng trên T1.
4. Châu mai vẽ ở mép ngoài (nửa ô thị giác, không collision riêng — đã có collision mép). Trên mặt tường rải rác: thùng tên, giá giáo, đèn bão.

### 2.4. Tường trong (bao Nội Thành Thượng) — dày 3 ô

- **Vị trí:** hàng **45–47**, cột **3–256** (hai đầu chạm tường ngoài), đá sáng và ít rêu hơn tường ngoài. Mặt trên đi được = đoạn T2 (§2.3).
- **Cổng nội thành:** cột **127–132**, hàng **45–47**, thẳng trục đại lộ. Cánh sắt + 2 trụ đèn đá, **luôn có lính canh** (NPC-14) và là điểm kiểm soát cốt truyện: chưa đủ uy tín/chưa xong quest thì lính không cho qua — khoá bằng điều kiện quest (portal/trigger `required_flag`), không khoá cứng.
- Hai bên cổng (phía trong): nhà canh + kho ấn nhỏ (cột 108–124 và 136–152, hàng 38–43) — điểm dừng tuần tra.

---

## 3. TRỤC GIAO THÔNG CHÍNH

| Đường | Vị trí (cột × hàng) | Rộng | Vai trò |
|---|---|---|---|
| **Đại lộ trung tâm** | cột **127–132**, hàng **3–186** | 6 ô | Xương sống xuyên 3 thềm: cổng chính → sân cổng → dân cư → quảng trường → cổng nội thành → sân nội thành → cổng Royal Palace. Lát đá sáng, đèn đá + chậu hoa 2 bên. Trục nhìn 3 landmark thẳng hàng: tượng → cổng nội thành → cổng cung |
| Đường ngang thềm 2 | hàng **104–106**, cột 3–256 | 3 ô | Nối Khu Nghề ↔ Quảng Trường ↔ Khu Chợ ở phía nam thềm 2 |
| Đường ngang thềm 1 | hàng **138–140**, cột 3–256 | 3 ô | Xương sống 2 khu dân cư + quân sự; miệng các hẻm chính đổ ra đây |
| Phố Tây | cột **84–87**, hàng 48–186 | 4 ô | Trục dọc tây: lò rèn → quán rượu → dân cư Tây |
| Phố Đông | cột **198–201**, hàng 48–186 | 4 ô | Trục dọc đông: chợ → dân cư Đông → doanh trại |
| Đường chợ chính | hàng **74–84**, cột 172–256 | 11 ô (gồm 2 làn đi bộ sau lưng người mua) | Đường rộng nhất sau đại lộ — 2 luồng NPC ngược chiều + người mua đứng trước sạp vẫn thông |

---

## 4. (b) QUẢNG TRƯỜNG TRUNG TÂM — cột 96–164, hàng 48–110 (68 × 62 ô)

- **Tiền sân** (hàng **48–70**): lát đá thưa + **Bảng Nhiệm Vụ** tại (104, 56) + **Giếng thành** tại (152, 56) + ghế đá — vùng đệm giữa cổng nội thành và quảng trường chính, điểm dân gánh nước qua lại.
- **TƯỢNG LỚN:** bệ 3 bậc cột **124–133**, hàng **76–81** (10×6 ô); thân tượng rộng 4 ô, cao ~7 ô thị giác (≈448px) — tượng **Hộ Mộc Thần / anh hùng gác ấn đời đầu** cầm kiếm cắm xuống gốc rễ đá, đá phủ rêu + hoa leo. Landmark chính + điểm neo sự kiện (lễ hội, tuyên bố của King Aldric, cutscene). Chân tượng có collision.
- **ĐÀI PHUN NƯỚC:** cột **123–134**, hàng **91–102** (bể Ø ~10 ô thị giác) phía nam tượng, thẳng trục tượng → đài phun → cổng chính. Nước động 4 frame (mặt nước + tia phun tách layer). Quanh đài: vòng ghế đá + chậu hoa.
- **Cây Con của Cổ Thụ ×2:** (102–106, 78–85) và (154–158, 78–85) — giữ motif "thành quanh cây" ở nơi dân thường tới được. Cổ Thụ THẬT nằm trong Nội Thành (§5.5) — không đặt 2 cổ thụ.
- Chức năng sống: điểm hẹn NPC — trẻ con chạy vòng quanh đài phun, dân đi chợ cắt ngang, người kể chuyện rong buổi chiều, điểm tập kết sự kiện.

---

## 5. CÁC KHU CHỨC NĂNG — KÍCH THƯỚC TỪNG KHU

### 5.1. (c) Khu Chợ — cột 172–256, hàng 48–110 → **84 × 62 ô**

- **24 sạp** (12 dãy bắc + 12 dãy nam), mỗi sạp **6 ô mặt tiền × 8 ô sâu** (gồm mái che + quầy), pitch 7 ô, sạp đầu dãy bắc tại cột 174, hàng **62–69**; dãy nam hàng **87–94**, quay mặt vào đường chợ (hàng 74–84).
- Sau mỗi dãy sạp là **hậu sạp** (hàng 48–61 phía bắc, hàng 95–110 phía nam): kho hàng nhỏ + nhà ở của tiểu thương (schedule NPC có "nhà" ngay sau sạp).
- Phân công sạp gắn NPC (§7): **B3** (cột 188–193, dãy bắc) = rau quả; **N5** (cột 202–207, dãy nam) = vải & thảo dược; **B7** (cột 216–221, dãy bắc) = đồ sắt & gốm. Sạp còn lại là sạp nền (bạt phủ theo giờ: sáng sớm phủ, 7h mở, 19h đóng).
- Luồng NPC mua bán: vòng chợ 1 chiều — vào từ phố Đông → dọc dãy nam → vòng đầu đông (cột 250) → dọc dãy bắc → ra quảng trường. Trước mỗi sạp 1 ô "chờ khách" (marker dừng 5–15s giả mua hàng).

### 5.2. (d) Khu Dân Cư — nhà SÁT nhau, HẺM là chất sống của thành

**Nguyên tắc bắt buộc:** nhịp **nhà 11–15 ô mặt tiền + hẻm 1–2 ô** lặp lại; nhà sâu 12–13 ô, nhiều nhà 2 tầng; mái gần như chạm nhau — nhìn từ trên là biển mái liên tục bị xẻ bởi các hẻm mảnh. Khác hẳn làng thưa.

**Dân Cư Tây — cột 3–112, hàng 111–168 → 109 × 57 ô, ~19 nhà:**

| Dãy | Hàng nhà | Hàng kề |
|---|---|---|
| Dãy T-A | nhà hàng **111–123** | hẻm **H-T1** hàng **124–125** |
| Dãy T-B | nhà hàng **126–137** | đường chính thềm 1 hàng 138–140 |
| Dãy T-C | nhà hàng **141–153** | phía nam: vườn rau + lối dọc chân tường hàng 183–186 |

| Hẻm | Vị trí | Loại |
|---|---|---|
| **H-T1 Hẻm Dây Phơi** | hàng 124–125, cột 3–112 (2 ô) | Hẻm chính ngang — dây phơi chăng suốt hẻm giữa 2 dãy nhà |
| **H-T2** | cột 24–25, hàng 111–153 | Hẻm dọc nối 3 dãy, đổ ra đường 138–140 |
| **H-T3 Hẻm Gánh Nước** | cột 52, hàng 111–153 (1–2 ô) | Tuyến người gánh nước: giếng thành → nhà dân |
| **H-T4 Hẻm Cụt Cống** | cột 78–79, hàng 126–148, cụt tại hàng 148 | **Hẻm cụt** — cuối hẻm là **MIỆNG CỐNG → Aldenmere Sewers** (§8-P4) + thùng rác + mèo; ánh sáng yếu, chất "lối bí mật" |
| **H-T5** | cột 96, hàng 111–137 | Hẻm phụ dọc qua khe 2 nhà dãy T-B (cửa sau) |
| **S-T Sân Trong Gạch** | cột 88–100, hàng 156–166 (12×10 ô) | **Sân trong**: giếng phụ, dây phơi vòng, bàn đá — điểm sinh hoạt/bắt chuyện của dân dãy T-C |

**Dân Cư Đông — cột 148–196, hàng 111–168 → 48 × 57 ô, ~11 nhà:** dãy Đ-A hàng 111–123, hẻm **H-Đ1 Hẻm Mái Nối** hàng 124–125 (có **cầu nối mái** ván gỗ giữa 2 nhà tầng 2 tại cột 168–172), dãy Đ-B hàng 126–137, dãy Đ-C hàng 141–153, hẻm dọc **H-Đ2 Hẻm Lò Bánh** cột 164, hẻm cụt **H-Đ3 Hẻm Cụt Trẻ Con** cột 188 hàng 126–140 (góc chơi bí mật của trẻ con — vẽ phấn dưới đất), sân trong **S-Đ** cột 172–184, hàng 156–166.

**Chi tiết sống bắt buộc trong hẻm** (node `Alley_Decor`, z trên mái): dây phơi chăng ngang (quần áo đung đưa 2–3 frame), cầu nối mái ở H-Đ1 + 1 chỗ ở H-T1, thùng/chậu hoa chân tường, cửa sau nhà mở ra hẻm, biển số nhà, mèo nằm trên thùng. Hẻm không có dây phơi/cầu mái = chưa đạt thiết kế.

### 5.3. (e) Khu Nghề — cột 3–88, hàng 48–110 → **85 × 62 ô**

| Công trình | Vị trí (cột × hàng) | Kích thước | Chi tiết |
|---|---|---|---|
| **Lò Rèn** | nhà cột 8–32, hàng 52–72; sân rèn cột 8–32, hàng 73–82 | nhà 24×20 ô, sân 24×9 ô | Lò lửa + **đe tại (20, 77)** = điểm làm việc của thợ rèn (NPC-03); khói particle giờ làm việc, thùng nước tôi thép, giá vũ khí, đống than |
| **Quán Rượu Liên Hoa** | cột 44–76, hàng 52–72 | 32×20 ô, 2 tầng — to nhất khu nghề | **Vào được nội thất** (scene riêng, §8-P2): cửa chính (60, 72) mặt nam. Biển đèn lồng "LIÊN HOA". Từ nội thất có cầu thang xuống **Elmford Cellar**. Sân trước hàng 73–82: bàn ngoài trời, thùng rượu, xe bò giao hàng |
| **Kho / Xưởng Mộc** | cột 8–32, hàng 86–108 | 24×22 ô | Kho lương + xưởng mộc; sân kho là điểm giao nhận buổi sáng và "nhà" của người gánh nước (NPC-11) |
| **Nhà Trọ** | cột 44–76, hàng 86–108 | 32×22 ô, 2 tầng | Tách riêng khỏi quán rượu (bản cũ gộp — bản này tách để schedule rõ: chủ quán ≠ chủ trọ). Nghỉ hồi máu/save tại cửa (menu tương tác) — không làm scene nội thất riêng ở giai đoạn này, quyết định tiết kiệm art có chủ ý (§11) |

Lối đi khu nghề rộng rãi kiểu khu làm việc (phố Tây + đường hàng 104–106 + sân chung) — tương phản cố ý với hẻm 1–2 ô của dân cư.

### 5.4. (f) Khu Quân Sự — cột 204–256, hàng 111–168 → **52 × 57 ô**

| Hạng mục | Vị trí | Kích thước | Chi tiết |
|---|---|---|---|
| Nhà chỉ huy | cột 208–224, hàng 114–126 | 16×12 ô | Cờ đội, bàn bản đồ qua cửa sổ |
| **Doanh trại** | cột 228–254, hàng 114–134 | 26×20 ô | Giường tầng, giá giáo ở hiên — nơi lính tuần xuất phát/kết thúc ca (điểm "nhà" trong schedule) |
| **Sân tập** | cột 206–254, hàng 140–164 | 48×24 ô | Hình nộm rơm ×3 (cột 214, 230, 246 — hàng 146–152), vòng chạy, tháp gỗ tập góc (252, 162); góc tây có bãi ngựa nhỏ (cột 206–220, hàng 142–154): hàng rào + máng nước, chỉ trang trí |
| Kho vũ khí | cột 228–254, hàng 160–164 | dãy thấp áp sân tập | Lý do có lính gác đêm ở mặt tường T1 phía đông |

### 5.5. (g) Nội Thành Thượng — cột 3–256, hàng 3–44 → **253 × 41 ô** (sau tường trong, thềm 3)

Vào bằng cổng nội thành (127–132, hàng 45–47). Bố cục đối xứng theo đại lộ:

| Hạng mục | Vị trí | Kích thước | Chi tiết |
|---|---|---|---|
| **Cổng Royal Palace of Aldenmere** | cột 127–132, hàng 3–5 | cổng 6 ô + bậc thềm cột 122–137, hàng 6–8 | **Portal sang `hoang_cung.tscn`** (§8-P5). 2 lính nghi lễ đứng 2 bên ban ngày |
| **Sân Nội Thành** | cột 104–156, hàng 8–43 | 52×35 ô | Sân lát đá sáng nối cổng nội thành → cổng cung; cột đèn đá + thảm hoa; điểm dừng cuối của tuyến tuần A |
| **Phủ King Aldric** | cột 14–68, hàng 10–38 | **55×28 ô** | Nơi ở/làm việc của King Aldric (NPC-15, gắn quest chính Đông 3–4); sân trước có bàn đá + cây cảnh |
| **Đền Nhỏ Xin Mùa** | cột 76–96, hàng 12–26 | 20×14 ô | Hương khói, điểm cầu nguyện/save phụ, sư già (NPC-17) nói lore phong ấn — gieo mầm twist Hồi III |
| **Cổ Thụ — Trụ Mộc** | vườn cột 168–232, hàng 4–36 (**64×32 ô**); gốc cột 196–204, hàng 14–22 | gốc 8 ô, tán phủ ~64×28 ô | Biểu hiện bề mặt của Trụ Mộc (world v2). Rễ nổi ăn vào nền + tràn xuống tường trong (chi tiết cốt truyện: rễ đang nuốt nhà/mộ). **Vòng Ø ~30 ô quanh gốc (cột 185–215, hàng 5–35) để trống = đấu trường boss Mossback, the Moss Golem (Đông 4)** — không đặt prop collision cố định trong vòng này; hàng rào khoá khu là node riêng bật/tắt theo quest. Khoá cho đến Main Quest Đông 3 |
| Nhà canh + kho ấn | cột 108–124 và 136–152, hàng 38–43 | 2 nhà 16×5 ô | Áp tường trong, phía trong nội thành (xem §2.4) |

---

## 6. BẢNG TỔNG HỢP KÍCH THƯỚC TỪNG KHU (tra nhanh khi dựng — số ô)

| Khu / hạng mục | Cột | Hàng | Kích thước (ô) | Node dự kiến |
|---|---|---|---|---|
| Toàn thành | 0–259 | 0–189 | **260 × 190** | `ThanhXuanLam` (gốc) |
| Tường ngoài + tháp + cổng chính | bao biên | bao biên | vành dày 3 ô, tháp góc 6×6 | `Walls_Outer` |
| Nội Thành Thượng (tổng) | 3–256 | 3–44 | 253 × 41 | `District_NoiThanh` |
| — Phủ King Aldric | 14–68 | 10–38 | 55 × 28 | nt |
| — Đền Xin Mùa | 76–96 | 12–26 | 20 × 14 | nt |
| — Sân Nội Thành | 104–156 | 8–43 | 52 × 35 | nt |
| — Vườn Cổ Thụ + đấu trường boss | 168–232 | 4–36 | 64 × 32 (arena Ø ~30) | nt |
| Tường trong + cổng nội thành | 3–256 | 45–47 | 253 × 3 | `Walls_Inner` |
| Khu Nghề (tổng) | 3–88 | 48–110 | 85 × 62 | `District_Nghe` |
| — Lò Rèn + sân rèn | 8–32 | 52–82 | 24 × 30 | nt |
| — Quán Rượu Liên Hoa | 44–76 | 52–72 | 32 × 20 | nt |
| — Kho / Xưởng Mộc | 8–32 | 86–108 | 24 × 22 | nt |
| — Nhà Trọ | 44–76 | 86–108 | 32 × 22 | nt |
| Tiền Sân + Quảng Trường (tổng) | 96–164 | 48–110 | 68 × 62 | `District_QuangTruong` |
| — Tượng Lớn (bệ) | 124–133 | 76–81 | 10 × 6 (thân cao ~7 ô) | nt |
| — Đài Phun Nước | 123–134 | 91–102 | Ø ~10 | nt |
| Khu Chợ (tổng) | 172–256 | 48–110 | 84 × 62 | `District_Cho` |
| — 24 sạp | dãy bắc hàng 62–69, dãy nam hàng 87–94 | — | mỗi sạp 6 × 8 | nt |
| — Đường chợ chính | 172–256 | 74–84 | 84 × 11 | `Ground` |
| Dân Cư Tây | 3–112 | 111–168 | 109 × 57 (~19 nhà) | `District_DanCuTay` |
| Dân Cư Đông | 148–196 | 111–168 | 48 × 57 (~11 nhà) | `District_DanCuDong` |
| Khu Quân Sự (tổng) | 204–256 | 111–168 | 52 × 57 | `District_QuanSu` |
| — Doanh trại | 228–254 | 114–134 | 26 × 20 | nt |
| — Sân tập | 206–254 | 140–164 | 48 × 24 | nt |
| Sân Cổng | 113–147 | 154–180 | 34 × 26 | (gồm trong `Ground` + prop) |
| Đại lộ trung tâm | 127–132 | 3–186 | 6 × 183 | `Ground` + prop đèn |

---

## 7. DANH SÁCH NPC THÀNH + LỊCH TRÌNH TÓM TẮT

Quy ước schedule theo hệ lịch trình NPC sống của game: mỗi NPC có vòng `Ngủ (ở nhà) → Đi làm → Làm việc (tại điểm việc, có animation việc) → Nghỉ → Việc chiều → Dạo/chợ → Về nhà`. Giờ là giờ trong game; "điểm việc" ghi ô lưới để hệ waypoint dùng trực tiếp. NPC kế thừa từ scene cũ ghi rõ id cũ để không mất quest đã gắn. (Hệ schedule hiện tại của game chạy vòng lặp theo thời lượng bước, cấu trúc dữ liệu sẵn sàng gắn `at_hour` sau — xem `game/systems/npc.gd`.)

| # | NPC (id) | Vai trò / quest | Nhà | Điểm làm việc chính (ô) | Lịch trình tóm tắt |
|---|---|---|---|---|---|
| 01 | **Lính Tuần A** (`linh_tuan_a`) | Tuần vòng chính | Doanh trại (241, 124) | Tuyến A: A1 doanh trại (240, 133) → A2 quảng trường cạnh tượng (121, 84) → A3 cổng nội thành (129, 50) → A4 sân nội thành (129, 26) → quay lại → A5 sân cổng (129, 170) | 05:30 dậy → 06:00–11:00 tuần vòng A (dừng canh ~2 phút/điểm) → 11:00–13:00 nghỉ sân tập → 13:00–18:00 tuần vòng A → 18:30 về doanh trại, 22:00 ngủ |
| 02 | **Lính Tuần B** (`linh_tuan_b`) | Tuần vòng phụ + mặt tường | Doanh trại (243, 124) | Tuyến B: B1 cổng chính (136, 176) → thang S1 (119, 176) → **lên mặt tường T1** tới B2 (32, 187) → xuống S1 → phố Tây → B3 (86, 120) → đường thềm 2 → chợ B4 (214, 79) → B5 doanh trại (236, 133) | 06:00–10:00 vòng B → 10:00–14:00 gác tĩnh cổng chính → 14:00–19:00 vòng B → về doanh trại. Vòng B khác hẳn vòng A (tường + chợ + dân cư) để 2 lính không đi trùng tuyến cùng lúc |
| 03 | **Thợ Rèn** (`tho_ren` — id cũ, giữ quest `dong_side_slime`) | Rèn, shop vũ khí | Phòng sau lò rèn (20, 58) | **Đe tại (20, 77)**, lò tại (16, 77) | 05:00 dậy → 05:30–11:30 rèn ở đe (anim gõ búa, khói lò) → 11:30–13:00 nghỉ ở sân quán rượu (60, 78) → 13:00–18:00 rèn + tiếp khách → 18:00–20:00 dạo quảng trường → về ngủ |
| 04 | **Chủ Quán Rượu** (`chu_quan_ruou`) | Quán rượu, tin đồn, đầu mối Elmford Cellar | Lầu quán (60, 58) — qua nội thất | Quầy bar trong **nội thất quán** (scene mới); sáng ra sân nhận hàng (60, 78) | 07:00 xuống sân nhận thùng rượu → 08:00–23:00 trong nội thất quán (NPC hiện diện ở scene nội thất) → 23:30 ngủ |
| 05 | **Chủ Trọ** (`chu_tro` — tách từ `chu_quan` cũ; `chu_quan` cũ giữ quest `dong_02_ham_ruou`, `dong_03_chuot_chua`, `dong_side_herb` — phân lại khi dựng: chủ trọ giữ 02/03 vì Elmford Cellar dưới quán/trọ, chủ quán giữ thoại tin đồn) | Nhà trọ, nghỉ/save | Nhà trọ (60, 97) | Sảnh trọ tại cửa (60, 106) | 06:00 quét sân trọ → 07:00–22:00 trực sảnh → 15:00 đi chợ (sạp B3) rồi về → 22:30 ngủ |
| 06 | **Tiểu Thương Rau Quả** (`tieu_thuong_rau`) | Sạp B3, shop rau/quả | Nhà sau sạp (190, 54) | Sạp B3 (188–193, 62–69), đứng (190, 72) | 04:30 dậy, gánh rau từ kho → 05:30 dọn sạp → 06:30–12:00 bán → nghỉ trưa sau sạp → 13:30–18:30 bán → 19:00 phủ bạt dọn sạp → về |
| 07 | **Tiểu Thương Vải & Thảo Dược** (`tieu_thuong_vai`) | Sạp N5, shop vải + thảo dược (nối side herb) | Nhà sau sạp (204, 102) | Sạp N5 (202–207, 87–94), đứng (204, 85) | 06:00 dậy → 07:00–12:30 bán → trưa về nhà ăn → 14:00–19:00 bán → tối thêu vải ở hiên đến 21:00 → ngủ |
| 08 | **Tiểu Thương Đồ Sắt & Gốm** (`tieu_thuong_sat`) | Sạp B7, shop đồ bền | Nhà sau sạp (218, 54) | Sạp B7 (216–221, 62–69), đứng (218, 72) | 06:30 dậy → 07:00 ghé lò rèn lấy hàng (20, 79) → 07:30–12:00 bán → 13:00–18:00 bán → 18:30 vào quán rượu (nội thất) đến 21:00 → về ngủ |
| 09 | **Dân Đi Chợ 1 — Bà Nội Trợ** (`dan_cho_1`) | Thoại đời sống/lore giá lúa | Nhà dãy T-B (40, 131) | Vòng chợ §5.1 | 06:30 dậy → 07:30 ra giếng phụ S-T (94, 161) lấy nước → 08:00–11:00 đi vòng chợ (dừng B3, N5) → 11:30 về nấu ăn → 15:00–17:00 ngồi sân S-T trò chuyện (cùng NPC-10) → tối về nhà |
| 10 | **Dân Đi Chợ 2 — Anh Gánh Hàng Thuê** (`dan_cho_2`) | Chỉ đường/hint dungeon | Nhà dãy Đ-B (158, 131) | Vòng chợ + kho xưởng (20, 97) | 05:30 dậy → 06:00–09:00 vác hàng ở kho → 09:00–12:00 giao hàng vòng chợ → 13:00–17:00 vác hàng chợ ↔ kho → 18:00 nghỉ ở đài phun (129, 96) → về |
| 11 | **Người Gánh Nước** (`ganh_nuoc`) | Nghề đặc trưng thành; thoại lore về giếng/Cổ Thụ ("nước giếng dạo này ngọt lạ") | Góc ngủ ở Kho/Xưởng (12, 100) | Tuyến nước: giếng thành (152, 56) → hẻm H-T3 (cột 52) → nhà dãy T-B/T-C → giếng phụ S-T (94, 161) → quay lại | 05:00–11:00 gánh 3 vòng tuyến nước (đòn gánh + 2 thùng, anim đi chậm) → 11:00–14:00 nghỉ sân cổng (129, 170) → 14:00–18:00 gánh 2 vòng (đổi dãy Đông qua đường 138–140) → tối về kho. Đây là NPC "đồng hồ sống" dễ thấy nhất của thành |
| 12 | **Trẻ Con 1** (`tre_con_1`) | Chạy chơi, quest nhỏ | Nhà dãy T-A (66, 117) | Vòng quanh đài phun (129, 96) | 07:00 dậy → 08:00–11:00 chơi ở quảng trường cùng NPC-13 (chạy vòng đài phun → tượng → cây con) → 11:30 về ăn → 14:00–17:00 trốn tìm ở hẻm cụt H-Đ3 / sân S-T (đổi điểm mỗi ~20 phút) → 17:30 về. Không ra ngoài sau 18:00 |
| 13 | **Trẻ Con 2** (`tre_con_2`) | Chạy chơi (cặp với 12); nhặt "lá không bao giờ héo" — mầm lore Trụ Mộc | Nhà dãy Đ-A (172, 117) | Quảng trường + H-Đ3 (188, 133) | Như NPC-12 nhưng lệch pha 15 phút, vòng chạy ngược chiều quanh đài phun; chiều giữ vai "người trốn" ở H-Đ3 |
| 14 | **Lính Canh Cổng Nội Thành** (`linh_canh_noi`) | Kiểm soát cổng nội thành — gate theo quest/uy tín | Doanh trại (238, 124) | Đứng tại (129, 50) ngay nam cổng nội thành | 05:30 dậy ở doanh trại → 06:00 có mặt ở cổng → 06:00–18:00 đứng canh (thỉnh thoảng đi vài ô dọc tường trong rồi quay lại) → 18:00 bàn giao ca đêm → về doanh trại. NPC nói câu chặn đường quan trọng nhất thành — phải có thoại theo trạng thái quest |
| 15 | **King Aldric** (`lanh_chua` — tên hiển thị: King Aldric, vua bù nhìn Đông) | Main Quest Đông 3–4, quyết định về Cổ Thụ | Phủ King Aldric (41, 24) | Bàn làm việc phủ (41, 30); 11:00 ra sân nội thành (129, 26); ngó Cổ Thụ (190, 24) | 07:00 dậy → 08:00–11:00 làm việc ở phủ (gặp để nhận quest) → 11:00–12:00 đi sân nội thành + ngó Cổ Thụ → 14:00–17:00 tiếp dân ở phủ → 17:30 dạo tiền sân → tối ở phủ, đèn sáng. Trước Đông 3 chỉ gặp được sau khi qua cổng nội thành (đủ uy tín) — đúng vòng lặp uy tín của world v2 |
| 16 | **Lính Gác Cổng Nam** (`linh_gac_nam` — id cũ, giữ lore) + ca đêm mặt tường | Canh cổng chính | Doanh trại (245, 124) | Ngày: (122, 178) phía tây cổng chính; **đêm: lên mặt tường T1** đứng (60, 187) | Ngày: canh cổng + chào người vào thành (điểm first-impression). Đêm 19:00–05:00: lên T1 bằng thang S1, đứng canh + đi dọc T1 cột 10–112. NPC này chứng minh mặt tường dùng được cho cả NPC. (`linh_gac` id cũ ở cổng bắc bản cũ → chuyển vai lính nghi lễ ở cổng Royal Palace (129, 8), giữ id để không vỡ save/quest đã gắn) |
| 17 | **Sư Già Đền Xin Mùa** (`su_den`, NPC phụ) | Lore phong ấn, save phụ | Đền (86, 19) | Đền (86, 22); chiều ra cây con quảng trường (104, 82) | Sáng tụng ở đền → trưa nghỉ → chiều ngồi dưới cây con quảng trường kể chuyện cũ → tối về đền. Không quest bắt buộc |

**Tổng: 17 NPC có schedule** — tuần tra ×2 khác vòng, thợ rèn, chủ quán, chủ trọ, tiểu thương ×3, dân chợ ×2, gánh nước, trẻ con ×2, canh cổng nội thành, canh cổng nam + ca đêm mặt tường, King Aldric, sư đền.

---

## 8. SƠ ĐỒ KẾT NỐI PORTAL + ĐIỂM SPAWN

Quy ước giữ nguyên hệ hiện tại (`systems/portal.tscn`: `target_scene` + `target_spawn = "from_<key>"`, đích có `Spawn_from_<key>`). Key của Aldenmere là `thanh`.

| # | Điểm trong thành (ô) | Cơ chế | Đích | Spawn ở đích | Spawn quay về trong thành | Ghi chú |
|---|---|---|---|---|---|---|
| P1 | **Cổng chính** (129, 188) | Portal 2 chiều ở lòng cổng | `maps/ngoai_thanh.tscn` (The Wallfoot) | `from_thanh` (đã có ở Wallfoot) | `Spawn_from_ngoai` tại **(129, 182)** trong sân cổng, mặt hướng bắc = cả `Spawn_start` | Từ The Wallfoot đi tiếp được: về **Elmford** và lên **Cloudpeak** (quan hệ sẵn có của ngoai_thanh). Giữ nguyên cặp portal cũ thành ↔ Wallfoot |
| P2 | **Cửa Quán Rượu Liên Hoa** (60, 72) | Portal cửa nhà | **`maps/noi_that_quan_ruou.tscn` — SCENE MỚI cần tạo** | `from_thanh` (ở cửa ra vào trong nội thất) | `Spawn_from_quan` tại **(60, 74)** — trước cửa quán | Nội thất quán: phòng 1 tầng + gác nhỏ, quầy bar (NPC-04 ở đây), bàn ghế, cầu thang xuống hầm ở góc tây-nam. Cần duyệt (§11) |
| P3 | Cầu thang trong nội thất quán | Portal cầu thang | `maps/ham_ruou.tscn` (Elmford Cellar) | `from_village` (**giữ key cũ** — Cellar đã có `Spawn_from_village`, portal về trỏ `from_cave`) | Hầm → nội thất quán (`Spawn_from_cave` trong nội thất, cạnh cầu thang) → cửa quán → thành | Đổi đường xuống hầm sang "qua nội thất quán" là chủ ý: quán giữ chìa hầm, hợp lore `chu_quan` giữ quest `dong_02_ham_ruou`. Phương án B (không làm nội thất): portal cầu thang trực tiếp tại cửa quán (60, 72) → `ham_ruou/from_village`, `Spawn_from_cave` tại (60, 74) |
| P4 | **Miệng cống** cuối hẻm cụt H-T4 (78, 148) | Portal nắp cống (tương tác mở nắp) | `maps/cong_ngam.tscn` (Aldenmere Sewers) | `from_thanh` (đã có trong Sewers) | `Spawn_from_cong` tại **(78, 145)** — trong hẻm, tránh đè nắp cống | Sewers cũng nối ngược về thành + sang Royal Palace + Bluestone Mine — không đổi các nối đó. Đây là đường đột nhập của quest `dong_08_cong_ngam` ở tuyến Phần 1 |
| P5 | **Cổng Royal Palace** (129, 4) | Portal cổng cung | `maps/hoang_cung.tscn` (Royal Palace of Aldenmere) | `from_thanh` (đã có ở cung) | `Spawn_from_cung` tại **(129, 8)** — trên bậc thềm trước cổng cung, nhìn xuống toàn thành | Khác bản cũ: cổng cung nằm TRONG Nội Thành — phải qua cổng nội thành (gate quest) mới tới được, không đi thẳng ra biên bắc như prototype |
| — | Thang S1 (117–120, 172–180), S2 (139–142, 172–180), S3 (121–124, 48–51), S4 (135–138, 48–51) | `StairTrigger` đổi lớp collision (§2.3) — **không phải portal** | Trong cùng scene (mặt tường T1/T2) | — | — | Không Spawn marker; vị trí player giữ nguyên khi đổi lớp |
| — | Cửa Nhà Trọ (60, 108), cửa nhà dân, doanh trại, phủ | Cửa trang trí + tương tác menu (trọ) / khoá (nhà dân) | Không scene nội thất (giai đoạn này) | — | — | Chỉ quán rượu có nội thất riêng — quyết định tiết kiệm art có chủ ý (§11) |

**Bảng spawn trong thành (cho dev):**

| Marker | Ô (cột, hàng) | Pixel Godot (tâm ô) | Nguồn đến |
|---|---|---|---|
| `Spawn_start` = `Spawn_from_ngoai` | (129, 182) | (−32, +5600) | The Wallfoot / vào thành lần đầu |
| `Spawn_from_cung` | (129, 8) | (−32, −5536) | Royal Palace of Aldenmere |
| `Spawn_from_cong` | (78, 145) | (−3296, +3232) | Aldenmere Sewers |
| `Spawn_from_quan` | (60, 74) | (−4448, −1312) | Nội thất quán rượu (scene mới) |
| `Spawn_from_cave` *(chỉ khi dùng phương án B)* | (60, 74) | (−4448, −1312) | Elmford Cellar trực tiếp |

---

## 9. DANH SÁCH TILE / PROP MỚI CẦN BỘ PHẬN ART LÀM

Chuẩn chung: tileset 64px, prop pixel art chi tiết cao (vẽ lớn rồi xử lý xuống như chuẩn sprite 128px đã chốt), palette Aldenmere: xanh lá non `#7FB069`, rêu đậm, nâu đất ẩm, đá xám phủ rêu, ngói đỏ-nâu, accent hồng hoa đào/trắng hoa mận. Mọi prop nhà/tường có **biến thể phủ rêu + dây leo hoa** ở chân tường/mái (dấu ấn vùng).

### 9.1. Tile (TileMap, ô 64px)

| Tile | Biến thể / ghi chú |
|---|---|
| Nền đá lát quảng trường (vòng tròn đồng tâm + ô vuông) | 4–6 biến thể nứt/rêu nhẹ |
| Nền đường đá đại lộ + đường phố | thẳng, vỉa, góc, ngã ba, ngã tư |
| Nền đất nện (sân tập, sân kho), nền đất ẩm hẻm | 3 biến thể |
| Nền sân lát gạch sân trong, nền thềm đá sáng (Nội Thành) | 2 biến thể |
| Bậc thềm / bậc thang đá (thềm 1→2, 2→3, thang lên tường) | bậc ngang, bậc dọc |
| Mặt tường đi được (đá lát + rãnh thoát nước) | thẳng + ô có bóng châu mai |
| Cỏ xuân + hoa đào/mận rơi, cỏ ẩm chân tường | 4 biến thể (tiền sân/vườn Nội Thành) |

### 9.2. Prop / kiến trúc (sprite riêng, y-sort; kích thước px suy từ số ô ở §5–§6)

| Prop | Kích thước gợi ý (px) | Ghi chú |
|---|---|---|
| **Tường thành đá** (đoạn 2 ô) | 128×128 / đoạn (thân + mặt trên + châu mai liền) | + góc trong/ngoài, đầu tường; bản phủ rêu nặng (tường ngoài) / bản sạch (tường trong) |
| **Cổng thành** | cổng chính 384×256 (6×4 ô); cổng nội thành 384×192 | Vòm + 2 cánh gỗ + biển tên; cánh mở/đóng 2 trạng thái |
| **Tháp canh cổng** | 832×576 vùng chân 13×9 ô — vẽ theo module: thân tháp 256×384 + mái 320×192 chồng lớp | Mái ngói rêu, ban công; tháp góc 384×448 |
| **Mặt tường + cầu nối nóc cổng/tháp** | 128×64 / đoạn | Cầu nối có lan can gỗ |
| **Tượng Hộ Mộc Thần** | bệ 640×384 (10×6 ô); thân tượng 256×448 | Đá phủ rêu, kiếm cắm rễ đá — prop quan trọng nhất thành, vẽ ở độ phân giải gấp đôi rồi downscale |
| **Đài phun nước** | 640×640 (Ø ~10 ô) | **4 frame nước động** (mặt nước + tia phun tách layer) |
| **Sạp chợ** | 384×512 (6×8 ô) | **3 biến thể**: bạt sọc rau quả / mái lá vải-thảo dược / mái gỗ đồ sắt-gốm; mỗi biến thể + 1 bản phủ bạt (đóng sạp) |
| **Nhà thành phố** | mặt tiền 11–15 ô → 704–960 px rộng; 1 tầng cao ~512, 2 tầng ~704–768 | **3–4 biến thể** mái (ngói đỏ / ngói rêu / xám đá) × tường (trắng vôi / vàng nhạt / gỗ nâu); bản hẹp cho hẻm, bản rộng cho phố chính; cửa sau mở ra hẻm |
| **Lò rèn** (lò lửa + ống khói) | lò 256×256, ống khói 128×256 | Lửa 3 frame; sprite khói mềm 128×128 cho particle |
| **Đe + thùng tôi + giá vũ khí** | đe 96×96, bộ sân rèn gộp 384×128 | Điểm việc của thợ rèn — chi tiết cao |
| **Biển hiệu quán/trọ + đèn lồng** | biển 256×128 treo, đèn 48×72 | Chữ "LIÊN HOA" vẽ vào biển (không dùng font hệ thống trong game); đèn 2 frame sáng |
| **Dây phơi** | 256×160 / nhịp (chăng ngang hẻm 2–4 ô) | 3 biến thể quần áo, **2–3 frame đung đưa**, layer trên mái |
| **Cầu nối mái** | 256×128 | Decor trên mái, không collision |
| **Thùng / hộp hàng / bao lúa / xe đẩy** | 96×96, 96×72, 72×72, 192×144 | Mỗi loại 2 biến thể |
| **Giếng thành** | 192×192; bản nhỏ sân trong 144×144 | Thành giếng + ròng rọc |
| **Cổ Thụ** | gốc 512×768, rễ tràn 1024×256, tán 4096×1792 vẽ tách 3 lớp | Prop lớn nhất vùng Đông; tán tách lớp để rung nhẹ + hoa rơi particle |
| **Cây con quảng trường + cây hoa phố** | 192×288 | 2 biến thể (đào hồng / mận trắng) |
| **Hình nộm rơm** | 96×192 | 2 frame (nguyên / tơi) nếu dư lực |
| **Bảng nhiệm vụ** | 192×192 | Giấy quest dán sẵn 3–4 tờ vẽ liền |
| **Đèn đá / cột đèn phố** | 48×144 | 2 trạng thái ngày/đêm |
| **Nắp cống sắt** | 96×96 | Frame đóng / mở hé (portal P4) |
| **Cờ Mộc trụ + banner** | 96×192 | 3 frame phấp phới — cổng chính + doanh trại |
| **Bàn ghế ngoài trời / ghế đá** | bàn 96×96, ghế 144×72 | Dùng lặp nhiều nơi |

---

## 10. RỦI RO / LƯU Ý KHI DỰNG SCENE SAU

1. **Hẻm 1–2 ô vs hitbox:** hẻm 1 ô (64px) vẫn lọt hitbox player 28px, nhưng 2 NPC ngược chiều sẽ kẹt nhau — schedule NPC dân cư phải đi hẻm theo vòng 1 chiều (vào H-T2 xuống, ra H-T3 lên) và **không dừng nói chuyện trong hẻm** (điểm dừng chỉ ở sân trong/đường chính). Camera dễ cấn mái nhà 2 tầng khi đi hẻm — mái dãy kề hẻm tự mờ khi player ở hẻm là nice-to-have, không chặn bản dựng đầu.
2. **Y-sort nhà 2 tầng:** origin của nhà đặt ở chân tường nam; hẻm ngang nằm giữa 2 dãy phải tính là "đường" có y lớn hơn chân nhà dãy bắc để nhân vật ở hẻm vẽ đúng lớp. Phải test với 1 dãy nhà mẫu trước khi nhân bản cả khu.
3. **Mặt tường cần lớp z riêng:** `WallTop_Walkable` dùng `z_index` cao + `z_as_relative = false`; bóng của nhân vật trên tường tắt bóng mềm. Lính canh/player trên tường dùng cùng sprite (chỉ đổi lớp collision + z theo trạng thái).
4. **Layer-swap cầu thang (§2.3):** collision mép tường phải là shape LIÊN TỤC qua khớp đoạn (kể cả cầu nối nóc tháp/cổng) — hở 1 khe là player "lọt" tường. NPC tuần B dùng cùng trigger không được kẹt trạng thái khi player cũng đang trên tường. Phương án lùi nếu layer-swap fail: cầu thang = portal nội bộ (fade 150ms) — chỉ dùng khi đã thử và fail, phải ghi log dựng.
5. **Khối lượng dựng tay rất lớn** (260×190, dân cư dày): dựng theo thứ tự Ground + tường + đại lộ → quảng trường → từng `District_*` một, playtest từng khu (đặc biệt là hẻm) trước khi sang khu kế. Không dựng cả thành trong 1 phiên không kiểm tra.
6. **Quest cũ gắn vị trí cũ:** `chu_quan`/`tho_ren`/`linh_gac` ở scene prototype mang quest `dong_02/03/04` + `dong_side_*`. Khi dựng lại phải gán lại điểm đứng/điểm việc theo §7; lưu ý tuyến Phần 1 hiện tại (đợt 2) đặt Mossback ở **Moss Den** (quest `dong_04_golem`) và King Aldric là boss cuối phần ở Royal Palace — đấu trường Cổ Thụ trong tài liệu này là phương án world v2 cho bản mở rộng sau, KHÔNG tự ý đổi id NPC/quest hay vị trí boss của tuyến đang chạy.
7. **Cổ Thụ là đấu trường boss:** vòng Ø ~30 ô quanh gốc không đặt prop collision cố định; hàng rào khoá khu phải là node riêng bật/tắt theo quest.
8. **Trục nhìn:** từ cổng chính (hàng 189) tới tượng (hàng ~78) — không đặt prop cao giữa đại lộ đoạn hàng 111–186 làm đứt trục nhìn cổng → tượng → cổng nội thành → cổng cung.
9. **NPC chen nhau ở chợ giờ cao điểm:** 3 tiểu thương + 2 dân chợ + gánh nước + tuần B ≈ 7 NPC + player trong khu chợ — kiểm tra tránh nhau ở ô chờ khách trước sạp; nếu kẹt thì giảm tốc vòng chợ, không nới đường chợ (đường chợ là chuẩn thiết kế).
10. **Scene nội thất quán mới** `game/maps/noi_that_quan_ruou.tscn`: khi tạo phải đăng ký vào `vung_dong_so_do.md` + bảng spawn §8 — tránh lặp lỗi tài liệu vùng lệch scene như bản cũ.

---

## 11. ĐIỂM CẦN DUYỆT TRƯỚC KHI DỰNG

1. **Bố cục tổng thể + kích thước 260×190** theo sơ đồ `aldenmere_layout.png` (vẽ đúng lưới này) — kích thước đã theo chuẩn user chốt sau bản mở đầu; cần duyệt BỐ CỤC (vị trí các khu, tuyến tuần, điểm portal) trước khi dựng scene.
2. **Có làm scene nội thất quán rượu riêng (`noi_that_quan_ruou.tscn`) không?** Đề xuất: **có** (nội thất duy nhất của thành giai đoạn này; Elmford Cellar xuống từ trong quán). Phương án B: portal cầu thang trực tiếp tại cửa quán (P3 ở §8).
3. **Cơ chế mặt tường:** layer-swap tại cầu thang (mượt, tốn công) hay portal nội bộ fade (đơn giản, hơi cụt)? Đề xuất: thử layer-swap trước, lùi về portal nếu fail (§10.4).
4. **Tách quán rượu / nhà trọ thành 2 công trình + 2 NPC riêng** (bản cũ gộp "Nhà Trọ Liên Hoa" + `chu_quan`) — phân lại quest `dong_02/03` cho chủ trọ, chủ quán giữ tin đồn + đầu mối hầm?
5. **Cổng bắc thành không còn là cổng ra ngoài** (Royal Palace nằm trong Nội Thành; Cloudpeak đi qua The Wallfoot) — bỏ hẳn `PortalNorth → hoang_cung` ở biên bắc kiểu cũ và `Spawn_from_nui` ở thành?

---

*Tài liệu này chỉ thiết kế để duyệt bố cục. Chưa dựng scene thành. Sơ đồ trực quan: `aldenmere_layout.png` (đúng lưới 260×190).*
