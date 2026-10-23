# ALDENMERE — LAYOUT CHI TIẾT (Thiết kế, chưa dựng scene)

> **Game:** Dưới Bóng Phong Ấn — Godot 4, Action RPG top-down
> **Loại tài liệu:** Thiết kế bố cục map — CHỈ tài liệu + sơ đồ, chưa dựng/sửa `.tscn`/`.gd`
> **Sơ đồ kèm theo:** `design/thanh_xuan_lam_layout.png` (top-down có nhãn, cùng hệ toạ độ lưới với tài liệu này)
> **Nguồn đối chiếu:** `design/world_v2_4_thanh.md` §2.1 (Vùng Đông, Trụ Mộc, King Aldric, Cổ Thụ),
> `design/vung_dong_so_do.md`, và scene hiện hữu `game/maps/thanh_xuan_lam.tscn`,
> `game/maps/hoang_cung.tscn`, `game/maps/ngoai_thanh.tscn`, `game/maps/cong_ngam.tscn`, `game/maps/ham_ruou.tscn` (chỉ đọc).
> **Chuẩn art bắt buộc (đã chốt 2026-10-23):** tileset + prop pixel art chi tiết cao kiểu Stardew Valley,
> ghép bằng TileMap, nhân vật đi lại/Y-sort/va chạm tự nhiên, nội thất là map riêng. Không dùng ảnh render phẳng cho khu đi lại được.
> **Quy ước tên hiển thị (đổi tên toàn game sang fantasy châu Âu, chốt 2026-10-23):** thành = **Aldenmere**;
> cung điện = **Royal Palace of Aldenmere**; hầm dưới quán rượu = **Elmford Cellar**; cống = **Aldenmere Sewers**;
> map ngoài cổng nam = **The Wallfoot**; làng khởi đầu = **Elmford**; vua bù nhìn Đông = **King Aldric**.
> Tên file/scene giữ slug nội bộ cũ (`thanh_xuan_lam.tscn`, `hoang_cung.tscn`, `ham_ruou.tscn`, `cong_ngam.tscn`, `ngoai_thanh.tscn`) — chỉ tên HIỂN THỊ đổi.

---

## 0. HIỆN TRẠNG SCENE CŨ (để biết cái gì đang nối đi đâu)

Scene `thanh_xuan_lam.tscn` hiện tại, theo file đã đọc:

| Hạng mục | Hiện trạng |
|---|---|
| Kích thước | 2200×1600 px (toạ độ Godot −1100…+1100 × −800…+800), nền Polygon2D + nhà Polygon2D thô — bản prototype |
| Tường | 1 lớp tường bao, 4 tháp góc + 2 tháp kẹp cổng Nam/Bắc |
| Công trình | Nhà Trọ (Inn, −400,−170), Tiệm Rèn + Lò rèn (430,−170 / 345,−95), Cổ Thụ (0,−470), Bảng Nhiệm Vụ (150,60), 4 nhà dân thưa |
| NPC | `chu_quan`, `tho_ren`, `linh_gac` (cổng bắc), `linh_gac_nam` (cổng nam) — đều đứng yên |
| Portal ra | Nam → `ngoai_thanh.tscn` (`from_thanh`); Bắc → `hoang_cung.tscn` (`from_thanh`); cầu thang Nhà Trọ → `ham_ruou.tscn` (`from_village`); miệng cống tại (−560,290) → `cong_ngam.tscn` (`from_thanh`) |
| Spawn vào | `Spawn_start` / `Spawn_from_ngoai` (0,640); `Spawn_from_nui` (0,−640); `Spawn_from_cave` (−315,−85); `Spawn_from_cong` (−520,330); `Spawn_from_cung` (0,−600) |

**Kết luận:** các *quan hệ nối* ở trên là đúng ý đồ và PHẢI giữ khi dựng lại (xem §8), nhưng *bố cục* cũ
quá thưa (4 nhà dân cho cả một tòa thành), không có chợ, không có quảng trường tượng/đài phun, không có
tường trong, không có mặt tường đi được, không có khu quân sự, không có hẻm. Tài liệu này thiết kế lại toàn bộ bố cục.

> ⚠️ Lưu ý nhất quán tên: `vung_dong_so_do.md` (bản cũ hơn) ghi thành nối Barleyfield ở cổng nam và
> Cloudpeak ở cổng bắc. Bản scene hiện hành mới hơn đã đổi thành: **Nam → The Wallfoot, Bắc (qua Nội Thành) → Royal Palace of Aldenmere**,
> và có thêm Aldenmere Sewers. Tài liệu này đi theo **scene hiện hành** + chỉ đạo thiết kế mới nhất
> (thành nối The Wallfoot ở phía nam; Royal Palace of Aldenmere là scene riêng qua cổng trong thành).
> Đường lên Cloudpeak khi đó đi qua The Wallfoot (`ngoai_thanh.tscn` đã có sẵn `PortalWest → nui_thanh_van`, `Spawn_from_nui`) — không cần cổng bắc ra ngoài ở thành nữa.

---

## 1. KÍCH THƯỚC, LƯỚI, HỆ TOẠ ĐỘ

### 1.1. Kích thước đề xuất

| Thông số | Giá trị | Lý do |
|---|---|---|
| Kích thước map | **3840 × 2560 px** | Lớn nhất Vùng Đông — thành phải "nuốt" được 7 khu chức năng + dân cư dày + 2 lớp tường mà không chèn ép hẻm xuống dưới 1 ô. Gấp ~2,8 lần diện tích scene cũ (2200×1600) nhưng vẫn là 1 scene nhẹ (xem §1.4). |
| Tile | **64 × 64 px** | Chuẩn tileset đã chốt (nhân vật 128px chi tiết, hitbox player 28px — xem §10). |
| Lưới | **60 cột × 40 hàng** | 3840/64 = 60, 2560/64 = 40. Mọi toạ độ trong tài liệu này đều theo lưới này. |
| Camera | Camera2D theo player, giới hạn (limit) đúng biên map | Map lớn hơn màn hình ~3–4 lần theo mỗi chiều: đủ cảm giác "thành phố", không cần streaming. |

### 1.2. Hệ toạ độ dùng trong toàn bộ tài liệu

- **Ô (cột, hàng)** — cột `0–59` tính từ **Tây → Đông** (trái → phải), hàng `0–39` tính từ **Bắc → Nam** (trên → dưới).
  Ghi dạng khoảng: `cột 22–37, hàng 18–25`.
- **Đổi sang toạ độ Godot** (gốc ở tâm map như các scene hiện tại, y xuống là dương):
  tâm ô (c, r) có `x = (c − 30) × 64 + 32`, `y = (r − 20) × 64 + 32`.
  Ví dụ: ô (30, 20) → (32, 32) ≈ tâm thành; cổng chính ô (29–30, 39) → y ≈ +1248 (sát biên nam).
- **Hướng:** Bắc = lên trên sơ đồ = hàng nhỏ = y âm. Mọi mô tả "phía bắc/nam" đều theo quy ước này.

### 1.3. Phân bổ chiều cao (địa hình 3 bậc — "điểm cao nhất ở phía bắc")

Thành dốc nhẹ lên phía bắc theo 3 thềm, tạo cảm giác leo dần lên Nội Thành — đúng vai trò pháo đài/trụ phong ấn:

| Thềm | Hàng | Khu | Cách xử lý khi dựng |
|---|---|---|---|
| Thềm 1 (thấp) | 26–39 | Dân cư Nam, Quân sự, cổng chính | Nền đá/đất thường |
| Thềm 2 (giữa) | 12–25 | Quảng trường, Chợ, Khu Nghề | 1 bậc thềm + dốc/bậc thang ở hàng 25–26 trên đại lộ và 2 phố bên |
| Thềm 3 (cao nhất) | 2–9 | Nội Thành Thượng / tiền khu Royal Palace of Aldenmere | 2 bậc thềm ở cổng nội thành (hàng 10–11); nền lát đá sáng, Cổ Thụ nhìn xuống toàn thành |

Thềm chỉ là *trình diễn* (tile nền khác tông + bậc thang trang trí + bóng đổ), không phải cơ chế nhảy/độ cao thật —
trừ mặt tường đi được (§2.3) là khu đi lại tách lớp thật.

### 1.4. Tổ chức node, hiệu năng, phương án tách khu dự phòng

**Nguyên tắc: 1 scene liền mạch.** Người chơi đi từ cổng chính lên Royal Palace of Aldenmere không load màn.
Tổ chức node đề xuất khi dựng (chỉ ghi cấu trúc, chưa dựng):

```text
ThanhXuanLam (Node2D, y_sort_enabled = true, script map_root.gd)
├─ Ground            (TileMapLayer z=-10: nền đất/đá/đường theo thềm)
├─ GroundDetails     (TileMapLayer z=-9: cỏ, hoa, vệt đá, bóng thềm)
├─ Walls_Outer       (Node2D: tường ngoài + tháp + cổng chính — thân tường y-sort, chân tường collision)
├─ Walls_Inner       (Node2D: tường trong)
├─ WallTop_Walkable  (Node2D, z_index cao + lớp collision riêng — §2.3)
├─ District_NoiThanh   (Node2D)   # hàng 2–9
├─ District_QuangTruong(Node2D)   # hàng 12–25, cột 22–37
├─ District_Cho        (Node2D)   # hàng 12–25, cột 38–57
├─ District_Nghe       (Node2D)   # hàng 12–25, cột 2–21
├─ District_DanCuTay   (Node2D)   # hàng 26–37, cột 2–27
├─ District_DanCuDong  (Node2D)   # hàng 26–37, cột 32–43
├─ District_QuanSu     (Node2D)   # hàng 26–37, cột 44–57
├─ Alley_Decor       (Node2D, z trên mái: dây phơi, cầu nối mái — §5.3)
├─ NPCs              (Node2D: mọi NPC có schedule, gom 1 chỗ để hệ schedule quản)
├─ PatrolRoutes      (Node2D: các Marker2D điểm tuần tra P1…P8, Q1…Q6)
├─ Portals           (Node2D: instance portal.tscn)
├─ Spawns            (Node2D: các Marker2D Spawn_*)
├─ Player / HUD      (như quy ước map_root hiện tại)
```

**Hiệu năng (ước tính):** 2400 ô nền là việc của TileMapLayer (vẽ theo chunk, không tốn node);
prop/nhà dự kiến 250–400 node tĩnh + ~17 NPC — nằm thoải mái trong khả năng Godot 4 trên máy yếu.
Quy tắc giữ hiệu năng: nhà/tường/sạp là **PackedScene prop dùng chung** (instance), không vẽ Polygon2D từng cái như prototype;
collision tĩnh gộp theo khu (1 StaticBody2D / khu với nhiều shape) thay vì 1 body / prop;
NPC ngoài tầm camera tự ngủ (hệ schedule lo — ngoài map này).

**Phương án tách khu dự phòng (chỉ khi máy yếu kêu):** các `District_*` đã tách node sẵn nên có thể
bật/tắt `visible` + `process_mode` theo khoảng cách camera, hoặc tách Nội Thành thành sub-scene load nền —
**không** tách thành map riêng có portal, vì sẽ phá trải nghiệm liền mạch và phá tuyến lính tuần xuyên khu.
Ưu tiên thử: giảm bóng đổ thời gian thực → dùng bóng vẽ sẵn trong tile. Chỉ tách khu khi FPS đo thực tế < 45 ở khu chợ giờ cao điểm.

---

## 2. (a) TƯỜNG NHIỀU LỚP + MẶT TƯỜNG ĐI ĐƯỢC

### 2.1. Tường ngoài (bao toàn thành)

| Đoạn | Vị trí lưới | Chi tiết |
|---|---|---|
| Tường Bắc ngoài | hàng 0–1, cột 0–59 | Dày 2 ô (128px). Đoạn cột 26–33 nằm sau tiền khu Royal Palace of Aldenmere — là phông nền, không có cổng ra ngoài. |
| Tường Nam ngoài | hàng 38–39, cột 0–59 | Dày 2 ô. Hở **cổng chính** ở cột 28–31 (xem §2.2). |
| Tường Tây ngoài | cột 0–1, hàng 0–39 | Dày 2 ô, không cổng. Chân tường phía trong (cột 2) trồng dây leo hoa — dấu ấn Aldenmere (tường đá phủ rêu/dây leo có hoa theo world v2). |
| Tường Đông ngoài | cột 58–59, hàng 0–39 | Dày 2 ô, không cổng. |
| Tháp góc ×4 | (0–1, 0–1), (58–59, 0–1), (0–1, 38–39), (58–59, 38–39) gộp trong khối tường góc, đội lên 3×3 ô thị giác | Tháp tròn/vuông đá, mái ngói rêu, cửa sổ hẹp phát sáng đêm. Chỉ trang trí + collision, không vào trong (giai đoạn này). |
| Tháp canh giữa đoạn | Tây: (0–1, 19–20); Đông: (58–59, 19–20); Nam: kẹp cổng (§2.2); Bắc: (18–19, 0–1) và (40–41, 0–1) | Tạo nhịp thị giác mỗi ~20 ô, tránh tường dài đơn điệu kiểu prototype. |

### 2.2. Cổng chính phía Nam + 2 tháp canh

- **Vị trí:** cột **28–31**, hàng **38–39** — thẳng trục đại lộ trung tâm (cột 28–31, §3.1).
  Lòng cổng rộng 4 ô (256px): 2 làn người + 1 xe bò vẫn lọt; là portal sang The Wallfoot (§8).
- **2 tháp canh kẹp cổng:** tháp Tây tại cột **25–27**, hàng **37–39**; tháp Đông tại cột **32–34**, hàng **37–39**.
  Mỗi tháp chân 3×3 ô thị giác (thân 2 ô + mái đua 1 ô), cao hơn tường 1 tầng mái, có ban công nhìn ra ngoài thành và ô cửa sổ.
- Trên cổng: vòm đá + biển tên thành "ALDENMERE" + 2 đèn lồng/cờ Mộc trụ. Cổng gỗ 2 cánh mở cố định ban ngày
  (đóng trong sự kiện cốt truyện — để sẵn AnimationPlayer hook, không làm ở bản dựng đầu).
- Trong cổng (hàng 36–37, cột 28–31): **sân cổng** — điểm dừng canh của lính tuần, chỗ người gánh nước nghỉ, bảng chỉ đường.

### 2.3. Mặt tường ĐI LÊN ĐƯỢC (cơ chế bắt buộc)

Hai đoạn mặt tường là **khu đi lại thật**, không phải trang trí:

| Đoạn | Vị trí mặt tường (đi được) | Cầu thang lên | Nhìn xuống thấy gì |
|---|---|---|---|
| **Đoạn T1 — Tường Nam** | hàng **38**, cột **2–27** và cột **35–57** (đứt quãng ở cổng + 2 tháp canh; đi qua nóc cổng/tháp bằng cầu nối ô cột 25–34 hàng 38 ở lớp cao hơn — xem lưu ý) | **Thang S1:** cột **24**, hàng **35–37** (trong sân cổng phía tây, lên theo hướng bắc→nam rồi rẽ đông lên mặt tường); **Thang S2:** cột **35**, hàng **35–37** (phía đông cổng, đối xứng) | The Wallfoot + đường nam bên ngoài (qua khe châu mai), sân cổng và mái nhà dân cư Nam bên trong |
| **Đoạn T2 — Tường Trong** | hàng **10**, cột **2–27** và cột **32–57** (đứt ở cổng nội thành cột 28–31) | **Thang S3:** cột **26**, hàng **10–12** (phía nam tường trong, trong ngõ thềm 2 phía tây đại lộ); **Thang S4:** cột **33**, hàng **10–12** (phía đông, đối xứng) | Toàn cảnh thềm 2 (quảng trường, chợ, khu nghề) ở phía nam; sân Nội Thành + Cổ Thụ phía bắc — đây là điểm ngắm "thành Mondstadt 2D" đẹp nhất map |

**Cơ chế khi dựng (ghi rõ để dev không làm sai):**

1. Mặt tường là **sàn riêng ở lớp cao**: dùng một `TileMapLayer`/nhóm node `WallTop_Walkable` có `z_index` cao hơn mọi mái nhà kề bên,
   player/NPC khi ở trên mặt tường vẽ **trên** mái nhà phía dưới (chấp nhận phá y-sort cục bộ — xem §10).
2. **Collision 2 mép:** dọc 2 mép bắc/nam của mặt tường đặt collision line liên tục (StaticBody2D mỏng 8–16px ở mép),
   chỉ hở đúng vị trí cầu thang (S1–S4) và cầu nối qua tháp/cổng. Rơi khỏi tường = không thể xảy ra (không có cơ chế rơi).
3. **Chuyển lớp tại cầu thang:** chân thang là `Area2D StairTrigger` — khi player bước vào, bật/tắt 2 bộ collision:
   bộ "mặt đất" (chân tường chặn như tường thường) ↔ bộ "mặt tường" (mép tường chặn, chân tường hết chặn ở ô thang).
   Đây là cơ chế *layer-swap tại điểm*, cùng họ với cầu 2 tầng Stardew — không dùng portal đổi scene, không teleport (trừ khi dev chọn phương án đơn giản hoá: teleport 1 ô — phải báo lại khi duyệt).
   NPC thường **không** dùng mặt tường; chỉ lính tuần vòng B có 1 chặng lên T1 (§7).
4. Châu mai (merlon) vẽ ở mép ngoài mặt tường, cao nửa ô thị giác, không collision riêng (đã có collision mép).
5. Trên mặt tường đặt rải rác: thùng tên, giá giáo, đèn bão, 1–2 lính canh đứng (NPC tĩnh theo schedule đêm — xem §7, NPC-16 phụ).

### 2.4. Tường trong (bao Nội Thành Thượng)

- **Vị trí:** hàng **10–11**, cột **2–57** (dày 2 ô, cùng规格 tường ngoài nhưng lát đá sáng hơn, ít rêu hơn — càng gần cung càng "quan").
  Hai đầu đông/tây chạm tường ngoài tại cột 0–1 và 58–59, khép kín khu nội thành ở hàng 2–9.
- **Cổng nội thành:** cột **28–31**, hàng **10–11**, thẳng trục đại lộ + cổng chính. Cổng nhỏ hơn cổng chính
  (vòm 4 ô nhưng có cánh sắt + 2 trụ đèn đá), **luôn có lính canh** (NPC-15) và là điểm kiểm soát cốt truyện:
  trước Main Quest Đông 3, lính canh không cho qua ("chưa đủ uy tín / chưa có lệnh King Aldric") — cổng khoá bằng điều kiện quest, không khoá cứng.
- Hai bên cổng nội thành là **nhà canh + kho ấn nhỏ** (cột 24–27 và 32–35, hàng 8–9, phía trong tường) — trang trí + điểm dừng tuần tra.

---

## 3. TRỤC GIAO THÔNG CHÍNH

### 3.1. Đại lộ trung tâm (xương sống của thành)

- **Vị trí:** cột **28–31** (rộng 4 ô = 256px), chạy hàng **39 → 2** xuyên 3 thềm:
  cổng chính (39) → sân cổng (36–37) → dân cư Nam (26–35) → bậc thềm (25–26) → quảng trường (18–25) →
  tiền sân (12–17) → cổng nội thành (10–11) → sân Nội Thành (2–9) → cổng Royal Palace of Aldenmere (2).
- Lát đá sáng, 2 hàng đèn đá + chậu hoa đào/mận ở đoạn thềm 2–3. Đây là tuyến lính tuần chính (§7) và là trục người chơi tự định hướng: đứng ở cổng chính nhìn thẳng thấy tượng quảng trường, cổng nội thành và mái tiền khu Royal Palace of Aldenmere — 3 landmark thẳng hàng.

### 3.2. Đường vành đai + các phố chính

| Đường | Vị trí | Vai trò |
|---|---|---|
| Đường Đông–Tây thềm 2 | hàng **17**, cột 2–57 (rộng 1 hàng lát đá, cộng vỉa thành 2 ô đi lại hiệu dụng với hàng 16/18 kề) | Nối Khu Nghề ↔ Quảng trường ↔ Khu Chợ ở phía bắc; sạp chợ và xưởng nghề đều mở mặt ra đường này |
| Đường Đông–Tây thềm 1 | hàng **33**, cột 2–57 | Xương sống của 2 khu dân cư + khu quân sự; miệng cống và các hẻm chính đều đổ ra đường này |
| Phố Tây | cột **10**, hàng 12–37 | Trục dọc phía tây: lò rèn → quán rượu → hẻm dân cư Tây |
| Phố Đông | cột **49**, hàng 12–37 | Trục dọc phía đông: chợ → dân cư Đông → doanh trại |

---

## 4. (b) QUẢNG TRƯỜNG TRUNG TÂM

- **Vị trí:** cột **22–37**, hàng **18–25** (16 × 8 ô = 1024 × 512px) — tâm hình học của thành (tâm ô (29.5, 21.5) ≈ tâm map).
  Phía bắc quảng trường là **tiền sân** cột 22–37, hàng 12–17: lát đá thưa + Bảng Nhiệm Vụ (cột 24, hàng 14) + giếng thành (cột 35, hàng 14) + 2 hàng ghế đá — vùng đệm giữa đại lộ và quảng trường chính.
- **TƯỢNG LỚN:** tại cột **29–30**, hàng **19–20** (chân tượng 2×2 ô, tượng cao ~3 ô thị giác ≈ 192px) —
  tượng **Hộ Mộc Thần / vị anh hùng gác ấn đời đầu** cầm kiếm cắm xuống gốc rễ đá, phong cách tượng đá phủ rêu + hoa leo như mọi thứ ở Aldenmere.
  Bệ tượng 3 bậc (cột 28–31, hàng 19–21 là vùng bệ, chỉ bậc ngoài đi lên được 1 ô trang trí, chân tượng có collision).
  Tượng là landmark chính + điểm neo sự kiện (lễ hội, tuyên bố của King Aldric, cutscene Đông 3/4 đều đặt ở đây).
- **ĐÀI PHUN NƯỚC:** tại cột **29–30**, hàng **23–24** (bể tròn Ø 2 ô, thị giác Ø ~2.5 ô) phía nam tượng, cách tượng 2 ô sân —
  trục tượng → đài phun → cổng chính thẳng hàng để người chơi vào thành là thấy cả 2.
  Nước động: khung animation 4 frame cho mặt nước + tia phun (art ghi ở §9). Quanh đài phun: vòng ghế đá + chậu hoa.
- **Chức năng sống:** điểm hẹn NPC — trẻ con chạy chơi vòng quanh đài phun (§7), dân đi chợ cắt ngang, người kể chuyện rong buổi chiều (NPC phụ), điểm tập kết sự kiện.
  Sân lát đá vòng tròn đồng tâm quanh tượng/đài phun (tile riêng), 4 góc quảng trường trồng cây hoa + đèn.
- Cổ Thụ của world v2 ("chợ quanh Cổ Thụ Trung Tâm / Gốc Cổ Thụ") được xử lý nhất quán như sau:
  **Cổ Thụ thật (Trụ Mộc lộ thiên) nằm trong Nội Thành** (§6, cột 46–51, hàng 3–7) — là gốc bị khoá đến Main Quest Đông 3, đúng world v2 ("Gốc Cổ Thụ khoá cho đến Main Quest Đông 3").
  Quảng trường thềm 2 trồng **Cây Con của Cổ Thụ** (cột 22–23, hàng 20–21 và cột 36–37, hàng 20–21, 2 cây đối xứng) để giữ motif "thành quanh cây" ở nơi dân thường tới được. Không đặt 2 "Cổ Thụ Trung Tâm" — tránh mâu thuẫn tài liệu.

---

## 5. (c) KHU CHỢ + (d) KHU DÂN CƯ + (e) KHU NGHỀ + (f) KHU QUÂN SỰ + (g) NỘI THÀNH

### 5.1. (c) Khu Chợ — cột 38–57, hàng 12–25 (thềm 2, phía đông)

- **Đường chợ chính:** hàng **18–20**, cột 38–57 (rộng 3 ô) chạy đông–tây, nối quảng trường (qua cột 37) tới phố Đông (cột 49) và cửa đông giả trang trí ở tường (không phải portal).
  Đường rộng nhất sau đại lộ — cố ý để 2 luồng NPC ngược chiều + người chơi chen giữa vẫn thông.
- **Dãy sạp: 18 sạp**, mỗi sạp 2×2 ô (128×128px gồm mái che + quầy), xếp 2 dãy quay mặt vào đường chợ:
  - Dãy bắc: 9 sạp tại hàng **15–16**, cột bắt đầu 38, 40, 42, 44, 46, 48, 50, 52, 54 (sạp cách nhau 0 ô — san sát, mái nối mái).
  - Dãy nam: 9 sạp tại hàng **21–22**, cột bắt đầu 38, 40, 42, 44, 46, 48, 50, 52, 54.
  - Hàng 12–14 (bắc dãy bắc) và hàng 23–25 (nam dãy nam): hậu sạp — kho hàng nhỏ, thùng, xe đẩy, chỗ ở của tiểu thương (nhà nhỏ 3×2) để schedule NPC có "nhà" ngay sau sạp.
- **Phân công sạp (gắn NPC §7):** sạp B3 (cột 42–43) = rau quả (Tiểu thương 1); sạp N5 (cột 46–47, hàng 21–22) = vải/thảo dược (Tiểu thương 2);
  sạp B7 (cột 50–51) = đồ sắt/gốm (Tiểu thương 3); các sạp còn lại là sạp nền có NPC khách vãng lai/bóng người trang trí theo giờ (mở/đóng bằng bạt phủ theo schedule: sáng sớm phủ bạt, 7h mở, 19h đóng).
- **Luồng NPC mua bán:** vòng lặp chợ = dân đi chợ đi từ phố Đông/hàng 23 → dọc dãy nam → vòng qua đầu đông (cột 56) → dọc dãy bắc ngược lại → ra quảng trường.
  Điểm dừng mua: trước mỗi sạp có 1 ô "ô chờ khách" (marker) — NPC dừng 5–15 giây giả mua hàng. Hàng 17 và hàng 23 là 2 làn đi bộ sau lưng người đứng mua, tránh tắc đường chợ.

### 5.2. (d) Khu Dân Cư Dày — thềm 1, hai khối Tây & Đông

**Nguyên tắc bắt buộc:** nhà **sát nhau**, khác hẳn làng thưa. Nhà phố 3–5 ô mặt tiền, sâu 3 ô, nhiều nhà 2 tầng,
chia ô đất theo nhịp **nhà 4 ô + hẻm 1 ô** lặp lại; mái nhà gần như chạm nhau, nhìn từ trên là một biển mái liên tục bị xẻ bởi các hẻm mảnh.

**Khối Dân Cư Tây — cột 2–27, hàng 26–37** (26 × 12 ô), chia 3 dãy nhà bởi 2 hẻm ngang:

| Dãy | Hàng nhà | Hàng hẻm/đường | Ghi chú |
|---|---|---|---|
| Dãy T-A | nhà hàng 26–28 | đường: hàng 29 là hẻm ngang H-T1 (1 ô) | 5 nhà: mặt tiền tại cột 2–5, 7–10, 12–15, 17–20, 22–26 |
| Dãy T-B | nhà hàng 30–32 | đường chính thềm 1: hàng 33 (§3.2) | 5 nhà: cột 2–5, 7–10, 12–16, 18–21, 23–27 |
| Dãy T-C | nhà hàng 34–36 | sân/hẻm: hàng 37 là lối dọc chân tường (2 ô với hàng 36 vỉa) | 4 nhà + 1 sân trong: cột 2–5, 7–10, 12–15, 18–21; sân trong S-T tại cột 23–26, hàng 34–36 |

**Các hẻm Dân Cư Tây (liệt kê theo thiết kế):**

| Hẻm | Vị trí (rộng 1 ô = 64px trừ khi ghi khác) | Loại |
|---|---|---|
| **H-T1 Hẻm Dây Phơi** | hàng 29, cột 2–27 | Hẻm chính ngang — dây phơi chăng qua lại giữa 2 dãy nhà suốt hẻm (§5.2 chi tiết sống) |
| **H-T2 Hẻm Thẳng Đứng** | cột 6, hàng 26–37 | Hẻm chính dọc, nối 3 dãy, đổ ra đường hàng 33 |
| **H-T3 Hẻm Gánh Nước** | cột 11, hàng 26–36 | Hẻm chính dọc — tuyến của người gánh nước (§7): giếng thành → nhà dân |
| **H-T4 Hẻm Cụt Cống** | cột 16, hàng 30–34, cụt ở hàng 34 | **Hẻm cụt** — cuối hẻm là **miệng cống** (§8) + thùng rác + mèo; ánh sáng yếu, cảm giác "lối bí mật" nhưng thực ra ai cũng biết |
| **H-T5 Hẻm Xiên Nhỏ** | cột 22, hàng 26–32 | Hẻm phụ dọc, nối dãy T-A xuống đường 33 qua khe giữa 2 nhà dãy T-B tại cột 22, hàng 30–32 (ô cửa sau) |
| **S-T Sân Trong Gạch** | cột 23–26, hàng 34–36 (4×3 ô) | **Sân trong nhỏ**: giếng phụ, dây phơi vòng, bàn đá — điểm sinh hoạt/bắt chuyện của dân dãy T-C, trẻ con trốn tìm |

**Khối Dân Cư Đông — cột 32–43, hàng 26–37** (12 × 12 ô, hẹp hơn vì nhường đất cho Quân sự):

| Dãy | Hàng nhà | Ghi chú |
|---|---|---|
| Dãy Đ-A | nhà hàng 26–28, hẻm ngang H-Đ1 ở hàng 29 | 3 nhà: cột 32–35, 37–39, 41–43 |
| Dãy Đ-B | nhà hàng 30–32, mặt ra đường hàng 33 | 3 nhà: cột 32–35, 37–40, 41–43 |
| Dãy Đ-C | nhà hàng 34–36, lối chân tường hàng 37 | 2 nhà + 1 sân trong S-Đ tại cột 38–40, hàng 34–36 |

**Các hẻm Dân Cư Đông:**

| Hẻm | Vị trí | Loại |
|---|---|---|
| **H-Đ1 Hẻm Mái Nối** | hàng 29, cột 32–43 | Hẻm chính ngang — có **cầu nối mái** (tấm ván/mái phụ nối 2 nhà ở tầng 2, trang trí trên cao, §5.2) tại cột 37–38 |
| **H-Đ2 Hẻm Lò Bánh** | cột 36, hàng 26–37 | Hẻm chính dọc, mùi bánh — 1 nhà dãy Đ-B (cột 32–35) là lò bánh nhỏ mở cửa sau ra hẻm |
| **H-Đ3 Hẻm Cụt Trẻ Con** | cột 41, hàng 30–33, cụt ở hàng 30 | Hẻm cụt — góc chơi bí mật của trẻ con (vẽ phấn dưới đất), nối cốt truyện nhỏ với 2 NPC trẻ con §7 |

**Chi tiết sống bắt buộc trong hẻm (trang trí, node `Alley_Decor`, z cao hơn mái):**
dây phơi chăng ngang hẻm (quần áo đung đưa 2–3 frame), cầu nối mái bằng ván ở H-Đ1 + 1 chỗ ở H-T1 (cột 11–12),
thùng/chậu hoa ở chân tường, cửa sau nhà mở ra hẻm, biển số nhà vẽ tay, mèo nằm trên thùng (sprite tĩnh + thỉnh thoảng vẫy đuôi nếu art dư lực).
Những chi tiết này là "chất thành phố sống" — khi dựng, hẻm không có dây phơi/cầu mái thì coi như chưa đạt thiết kế.

### 5.3. (e) Khu Nghề — cột 2–21, hàng 12–25 (thềm 2, phía tây)

| Công trình | Vị trí | Chi tiết |
|---|---|---|
| **Lò Rèn** | nhà chính cột **3–8**, hàng **12–15** (6×4 ô); sân rèn mở cột **3–8**, hàng **16–17** | Lò rèn lộ thiên ở sân: lò lửa + **đe tại ô (5, 16)** = điểm làm việc của thợ rèn (NPC-03), ống khói trên mái nhà chính bốc **khói particle** liên tục giờ làm việc, thùng nước tôi thép, giá vũ khí, đống than. Tiếng đe là âm thanh định vị của khu — player nghe thấy trước khi thấy. |
| **Quán Rượu Liên Hoa** | cột **11–18**, hàng **12–15** (8×4 ô, nhà 2 tầng — to nhất khu nghề) | **Vào được nội thất:** cửa chính tại ô (14, 15) mặt nam là **portal sang scene nội thất riêng** `noi_that_quan_ruou.tscn` (**scene MỚI cần tạo** — xem §8 + điểm cần duyệt). Biển hiệu đèn lồng "LIÊN HOA" treo trên cửa. Từ nội thất quán mới có cầu thang xuống **Elmford Cellar** (giữ đúng quan hệ scene hiện tại: Elmford Cellar xuống từ quán/trọ trong thành). Sân trước quán (hàng 16–17): bàn ngoài trời, thùng rượu, xe bò giao hàng. |
| **Nhà Trọ** | cột **11–18**, hàng **19–24** (8×6 ô, 2 tầng) | Trọ riêng, tách khỏi quán rượu (scene cũ gộp "Nhà Trọ Liên Hoa" — bản mới tách 2 chức năng cho rõ schedule: chủ quán ≠ chủ trọ). Cửa tại (14, 24) mặt nam ra phố nhỏ hàng 25. Chức năng: nghỉ hồi máu/save theo world v2; nội thất trọ **không** làm scene riêng ở giai đoạn này — tương tác tại cửa (menu nghỉ) để tiết kiệm công art, ghi rõ là quyết định chủ ý. |
| **Kho / Xưởng Mộc** | cột **3–8**, hàng **19–24** (6×6 ô) | Kho lương + xưởng mộc chung tường với lò rèn (cùng dãy nghề ồn/bụi). Sân kho: thùng, bao lúa, gỗ xẻ — điểm giao nhận của người gánh nước/xe bò buổi sáng, và là "nhà" (nơi ngủ) của người gánh nước (NPC-11). |

Lối đi trong khu nghề: phố Tây (cột 10) dọc + đường hàng 17 ngang + khoảng sân chung hàng 16–18 phía trước các công trình — rộng rãi kiểu khu làm việc, tương phản cố ý với hẻm 1 ô của dân cư.

### 5.4. (f) Khu Quân Sự — cột 44–57, hàng 26–37 (thềm 1, đông nam)

| Hạng mục | Vị trí | Chi tiết |
|---|---|---|
| **Doanh trại** | nhà dài cột **50–56**, hàng **27–31** (7×5 ô) + nhà chỉ huy nhỏ cột **45–48**, hàng **27–29** | Giường tầng nhìn qua cửa sổ, giá giáo ở hiên, cờ đội. Nơi lính tuần **xuất phát/kết thúc ca** (điểm nhà trong schedule). |
| **Sân tập** | cột **44–56**, hàng **32–36** (13×5 ô sân đất nện) | Hình nộm rơm ×3 (cột 46, 50, 54 hàng 33), vòng sân chạy, tháp gỗ tập nhỏ ở góc (56, 36). Buổi sáng lính tập theo đội hình (2 NPC lính phụ đứng tập — dùng lại NPC-01/02 ngoài giờ tuần hoặc bóng lính nền). |
| **Bãi ngựa / chuồng nhỏ** | cột 44–48, hàng 32–34 lề tây sân tập — gộp vào sân tập khi dựng nếu chật | Hàng rào + máng nước; chỉ trang trí (chưa có cơ chế ngựa). |
| Kho vũ khí | cột 51–56, hàng 37 (dãy 1 ô sâu thị giác, sát chân tường nam) | Nhà kho thấp áp tường — lý do có lính gác đêm ở đoạn tường T1 phía đông. |

### 5.5. (g) Nội Thành Thượng — cột 2–57, hàng 2–9 (thềm 3, sau tường trong)

Vào bằng cổng nội thành (cột 28–31, hàng 10–11). Bố cục đối xứng theo trục đại lộ:

| Hạng mục | Vị trí | Chi tiết |
|---|---|---|
| **Sân Nội Thành** | cột 22–37, hàng 5–9 | Sân lát đá sáng nối cổng nội thành → cổng Royal Palace of Aldenmere; 2 hàng cột đèn đá + thảm hoa. Điểm dừng cuối của tuyến tuần A. |
| **Cổng Royal Palace of Aldenmere** | cột **28–31**, hàng **2** (áp tường bắc ngoài, thị giác là cổng cung điện 4 ô + 2 trụ) | **Portal sang `hoang_cung.tscn`** (§8). Trước cổng: 2 lính nghi lễ đứng cố định ban ngày (bóng trang trí có thoại), bậc thềm rộng cột 26–33, hàng 3–4. `Spawn_from_cung` đặt tại (29–30, 4) — bước ra khỏi cổng cung là đứng trên bậc thềm nhìn xuống toàn thành. |
| **Phủ King Aldric / Nha Hiệu Quan** | cột **4–15**, hàng **3–8** (12×6 ô) phía tây | Nơi ở + làm việc của King Aldric / hiệu quan (NPC-15, gắn quest). Sân trước có bàn đá + cây cảnh; là nơi nhận/trả Main Quest Đông 3–4 sau khi qua được cổng nội thành. |
| **Cổ Thụ — Trụ Mộc** | gốc tại cột **46–48**, hàng **5–6**; tán phủ cột **43–53**, hàng **2–8** phía đông | Cây khổng lồ — biểu hiện bề mặt của Trụ Mộc (world v2 §2.1.2/§2.1.5). Rễ nổi ăn vào nền sân và tường trong (vẽ rễ tràn xuống hàng 9–10 ở cột 44–50 — chi tiết cốt truyện: rễ đang nuốt nhà/mộ). Khu gốc cây khoá bằng hàng rào gỗ + lính/biển cấm cho đến Main Quest Đông 3; sân gốc cây là đấu trường boss Mossback, the Moss Golem ở Đông 4 (để trống vòng Ø ~7 ô quanh gốc, không đặt prop cố định trong vòng này). |
| **Đền Nhỏ Xin Mùa** | cột **17–20**, hàng **3–5** | Đền nhỏ theo world v2 (khu vực nội bộ thành có "Đền Nhỏ Xin Mùa"): hương khói, điểm cầu nguyện/save phụ, NPC sư già phụ (thoại lore về phong ấn — gieo mầm twist Hồi III). |
| Nhà canh + kho ấn | cột 24–27 và 32–35, hàng 8–9 | Đã ghi ở §2.4 — nhà thấp áp tường trong, phía trong nội thành. |

---

## 6. BẢNG TỔNG HỢP KHU (tra nhanh khi dựng)

| Khu | Cột | Hàng | Diện tích (ô) | Node |
|---|---|---|---|---|
| Tường ngoài + tháp + cổng chính | bao biên | bao biên | chu vi 60×40 | `Walls_Outer` |
| Nội Thành Thượng | 2–57 | 2–9 | 56×8 | `District_NoiThanh` |
| Tường trong + cổng nội thành | 2–57 | 10–11 | 56×2 | `Walls_Inner` |
| Tiền sân + Quảng trường | 22–37 | 12–25 | 16×14 (quảng trường chính 16×8 ở hàng 18–25) | `District_QuangTruong` |
| Khu Nghề | 2–21 | 12–25 | 20×14 | `District_Nghe` |
| Khu Chợ | 38–57 | 12–25 | 20×14 | `District_Cho` |
| Dân Cư Tây | 2–27 | 26–37 | 26×12 | `District_DanCuTay` |
| Dân Cư Đông | 32–43 | 26–37 | 12×12 | `District_DanCuDong` |
| Khu Quân Sự | 44–57 | 26–37 | 14×12 | `District_QuanSu` |
| Đại lộ trung tâm | 28–31 | 2–39 | 4×38 | `Ground` + prop đèn |

---

## 7. DANH SÁCH NPC THÀNH + LỊCH TRÌNH TÓM TẮT

**Quy ước schedule** (theo hệ lịch trình đang xây song song): mỗi NPC có các chặng
`Ngủ (ở nhà) → Đi làm → Làm việc (tại điểm việc, có animation việc) → Nghỉ/giải lao → Việc chiều → Đi chợ/dạo → Về nhà → Ngủ`.
Giờ dưới đây là giờ trong game; "điểm việc" ghi ô lưới để hệ waypoint dùng trực tiếp.
NPC kế thừa từ scene cũ được ghi rõ id cũ để không mất quest đã gắn.

| # | NPC (id đề xuất) | Vai trò / quest | Nhà (nơi ngủ) | Điểm làm việc chính (ô) | Lịch trình tóm tắt |
|---|---|---|---|---|---|
| 01 | **Lính Tuần A** (`linh_tuan_a`) | Tuần tra vòng chính | Doanh trại (52, 29) | Tuyến A: P1 sân cổng (29,36) → P2 quảng trường cạnh tượng (27,21) → P3 cổng nội thành (29,12) → quay lại theo đại lộ | 05:30 dậy ở doanh trại → 06:00–11:00 tuần vòng A (dừng canh 2 phút mỗi P) → 11:00–13:00 nghỉ ở sân tập → 13:00–18:00 tuần vòng A → 18:30 về doanh trại, 22:00 ngủ. Đêm: không tuần (vòng đêm do NPC-16 phụ trách tĩnh). |
| 02 | **Lính Tuần B** (`linh_tuan_b`) | Tuần tra vòng phụ + mặt tường | Doanh trại (54, 29) | Tuyến B: Q1 cổng chính (32,36) → thang S1 (24,36) → **lên mặt tường T1** đi tới (10,38) → xuống S1 → Q2 đường hàng 33 (20,33) → Q3 chợ (49,20) → Q4 phố Đông (49,30) → về doanh trại | 06:00–10:00 vòng B → 10:00–14:00 gác tĩnh ở cổng chính (đứng cạnh `linh_gac_nam` cũ nếu giữ) → 14:00–19:00 vòng B → về doanh trại. Vòng B khác hẳn vòng A về khu vực (tường + chợ + dân cư) để 2 lính không bao giờ đi trùng tuyến cùng lúc. |
| 03 | **Thợ Rèn** (`tho_ren` — id cũ, giữ quest `dong_side_slime` + nâng cấp) | Rèn, shop vũ khí | Nhà rèn — phòng sau lò rèn (7, 13) | **Đe tại (5, 16)**, lò tại (4, 16) | 05:00 dậy → 05:30–11:30 rèn ở đe (anim gõ búa, khói lò bật) → 11:30–13:00 nghỉ, ăn ở sân quán rượu (15, 17) → 13:00–18:00 rèn + tiếp khách tại quầy (6, 17) → 18:00–20:00 dạo quảng trường → về ngủ. |
| 04 | **Chủ Quán Rượu** (`chu_quan_ruou`) | Quán rượu, tin đồn, đầu mối Elmford Cellar | Phòng trên lầu quán (17, 13) — qua nội thất quán | Quầy bar trong **nội thất quán** (scene mới); buổi sáng ra sân nhận hàng (15, 17) | 07:00 xuống sân nhận thùng rượu từ xe bò → 08:00–23:00 ở trong nội thất quán (NPC hiện diện ở scene nội thất, ẩn ở scene thành) → 23:30 ngủ. Khi người chơi ở ngoài thành ban ngày, quán vẫn "có người" qua cửa sổ sáng đèn — không cần NPC đứng ngoài. |
| 05 | **Chủ Trọ** (`chu_tro` — tách từ `chu_quan` cũ; `chu_quan` cũ giữ quest `dong_02_ham_ruou`, `dong_03_chuot_chua`, `dong_side_herb` — phân lại quest khi dựng: chủ trọ giữ 02/03 vì Elmford Cellar dưới quán/trọ, chủ quán giữ thoại tin đồn) | Nhà trọ, nghỉ/save | Nhà trọ (17, 21) | Sảnh trọ tại cửa (14, 23); sáng phơi chăn ở sân trong S-T kề? — không, sân trọ riêng (12–13, 25) | 06:00 dậy, quét sân trọ → 07:00–22:00 trực sảnh trọ (điểm (14,23)) → thỉnh thoảng 15:00 đi chợ (điểm mua ở sạp B3) rồi về → 22:30 ngủ. |
| 06 | **Tiểu Thương 1 — Rau Quả** (`tieu_thuong_rau`) | Sạp B3, shop rau/quả, quest phụ thu mua | Nhà sau sạp (42, 13) | Sạp B3 (42–43, 15–16), đứng (42, 17) mặt ra đường chợ | 04:30 dậy, ra kho (40, 13) gánh rau → 05:30 dọn sạp → 06:30–12:00 bán → 12:00–13:30 nghỉ sau sạp → 13:30–18:30 bán → 19:00 dọn sạp (bạt phủ) → về nhà. |
| 07 | **Tiểu Thương 2 — Vải & Thảo Dược** (`tieu_thuong_vai`) | Sạp N5, shop vải + thảo dược (nối side herb) | Nhà sau sạp (46, 24) | Sạp N5 (46–47, 21–22), đứng (46, 20) | 06:00 dậy → 07:00–12:30 bán → 12:30–14:00 về nhà ăn (46,24) → 14:00–19:00 bán → tối thêu vải ở hiên nhà tới 21:00 → ngủ. |
| 08 | **Tiểu Thương 3 — Đồ Sắt & Gốm** (`tieu_thuong_sat`) | Sạp B7, shop đồ bền, đối thoại với thợ rèn (khoe nguồn hàng) | Nhà sau sạp (50, 13) | Sạp B7 (50–51, 15–16), đứng (50, 17) | 06:30 dậy → ghé lò rèn lấy hàng (6, 17) lúc 07:00 → 07:30–12:00 bán → 13:00–18:00 bán → 18:30 qua quán rượu (vào nội thất, ẩn ở thành) tới 21:00 → về ngủ. |
| 09 | **Dân Đi Chợ 1 — Bà Nội Trợ** (`dan_cho_1`) | Dân thường, thoại đời sống/lore giá lúa | Nhà dãy T-B (13, 31) | Vòng chợ §5.1 | 06:30 dậy ở nhà → 07:30 ra giếng S-T lấy nước → 08:00–11:00 đi vòng chợ (dừng mua ở B3, N5) → 11:30 về nấu ăn → 15:00–17:00 ngồi sân trong S-T trò chuyện (cùng NPC-10) → tối về nhà. |
| 10 | **Dân Đi Chợ 2 — Anh Gánh Hàng Thuê** (`dan_cho_2`) | Dân thường, chỉ đường/hint dungeon | Nhà dãy Đ-B (33, 31) | Vòng chợ + bến xe kho xưởng (5, 22) | 05:30 dậy → 06:00–09:00 vác hàng ở kho xưởng → 09:00–12:00 đi vòng chợ giao hàng (dừng ở B7, N3) → 13:00–17:00 vác hàng chợ ↔ kho → 18:00 ngồi đài phun quảng trường (30, 25) nghỉ → về nhà. |
| 11 | **Người Gánh Nước** (`ganh_nuoc`) | Nghề đặc trưng thành, thoại về giếng/Cổ Thụ ("nước giếng dạo này ngọt lạ") | Kho/Xưởng — góc ngủ (4, 23) | Tuyến nước: giếng thành (35, 14) → hẻm H-T3 (cột 11) → các nhà dãy T-B/T-C → giếng phụ S-T (24, 35) → quay lại | 05:00–11:00 gánh 3 vòng tuyến nước (đòn gánh + 2 thùng, anim đi chậm) → 11:00–14:00 nghỉ ở sân cổng (30, 36) → 14:00–18:00 gánh 2 vòng (đổi sang dãy Đông qua đường 33) → tối về kho. Đây là NPC "đồng hồ sống" dễ thấy nhất — đi ngang mọi khu thềm 1–2. |
| 12 | **Trẻ Con 1** (`tre_con_1`) | Chạy chơi, quest nhỏ tìm đồ/thả diều | Nhà dãy T-A (18, 27) | Quảng trường — vòng quanh đài phun (29–30, 23–24) | 07:00 dậy → 08:00–11:00 chơi ở quảng trường cùng NPC-13 (chạy vòng đài phun → tượng → cây con) → 11:30 về ăn → 14:00–17:00 chơi ở hẻm cụt H-Đ3 / sân S-T (trốn tìm, đổi điểm mỗi 20 phút) → 17:30 về nhà. Không ra ngoài sau 18:00. |
| 13 | **Trẻ Con 2** (`tre_con_2`) | Chạy chơi (cặp với 12), nhặt "lá không bao giờ héo" — mầm lore Trụ Mộc | Nhà dãy Đ-A (38, 27) | Quảng trường + H-Đ3 | Lịch như NPC-12 nhưng lệch pha 15 phút và vòng chạy ngược chiều quanh đài phun; buổi chiều giữ vai "người trốn" ở H-Đ3. |
| 14 | **Lính Canh Cổng Nội Thành** (`linh_canh_noi`) | Kiểm soát cổng nội thành, gate theo quest/uy tín | Doanh trại (53, 30) — ngủ ca kíp | Đứng tại (30, 12) ngay nam cổng nội thành | 05:30 dậy ở doanh trại → 06:00 có mặt ở cổng → 06:00–18:00 đứng canh (thỉnh thoảng đi 3 ô dọc tường trong rồi quay lại) → 18:00 bàn giao cho ca đêm (bóng lính tĩnh) → về doanh trại. Là NPC nói câu chặn đường quan trọng nhất thành — phải có thoại theo trạng thái quest. |
| 15 | **King Aldric** (`lanh_chua` — nhân vật world v2 §2.1.2 (tên hiển thị mới: King Aldric, vua bù nhìn Đông); kiêm vai "hiệu quan" gắn quest chính) | Main Quest Đông 3–4, quyết định về Cổ Thụ | Phủ King Aldric (9, 5) | Bàn làm việc phủ (9, 6); 10:00 ra sân Nội Thành (29, 7) nghe báo cáo; lễ/sự kiện ra bệ tượng quảng trường | 07:00 dậy ở phủ → 08:00–11:00 làm việc ở phủ (gặp được để nhận quest) → 11:00–12:00 đi sân Nội Thành + ngó Cổ Thụ (44, 7) → 14:00–17:00 tiếp dân ở phủ → 17:30 dạo tiền sân (đi cùng NPC-14 đoạn ngắn) → tối ở phủ, đèn sáng. Trước Đông 3: chỉ gặp ở phủ qua cổng nội thành bị chặn → người chơi phải đủ uy tín mới vào được (đúng vòng lặp uy tín world v2). |
| 16 | **Lính Gác Cổng Nam** (`linh_gac_nam` — id cũ, giữ lore) + ca đêm mặt tường | Canh cổng chính | Doanh trại (55, 30) | (27, 36) phía tây cổng chính ban ngày; **ban đêm lên mặt tường T1** đứng tại (20, 38) | Ngày: canh cổng + chào người vào thành (điểm first-impression). Đêm (19:00–05:00): lên T1 bằng S1, đứng canh + thỉnh thoảng đi dọc T1 cột 10–27. NPC này chứng minh mặt tường dùng được cả cho NPC. (`linh_gac` id cũ ở cổng bắc bản cũ: cổng bắc không còn là cổng ra ngoài — chuyển vai thành lính nghi lễ ở cổng Royal Palace of Aldenmere (29, 3), giữ id để khỏi vỡ save/quest `dong_04_golem` — khi dựng, quest `dong_04_golem` cần rà lại điểm giao vì boss golem đã dời về Gốc Cổ Thụ/Moss Den theo tài liệu vùng.) |
| 17 | **Sư Già Đền Xin Mùa** (`su_den`, NPC phụ) | Lore phong ấn, save phụ | Đền (18, 4) | Đền (18, 5); chiều ra gốc cây con quảng trường (23, 21) | Sáng tụng ở đền → trưa nghỉ → chiều ngồi dưới cây con quảng trường kể chuyện cũ (điểm lore tự nguyện) → tối về đền. Không quest bắt buộc. |

**Tổng: 17 NPC có schedule** (vượt mức tối thiểu 15 yêu cầu: tuần ×2 khác vòng, rèn, chủ quán, chủ trọ, tiểu thương ×3, dân chợ ×2, gánh nước, trẻ con ×2, canh cổng nội, King Aldric/hiệu quan — đủ và có dư sư đền + gác cổng nam).

---

## 8. SƠ ĐỒ KẾT NỐI PORTAL + ĐIỂM SPAWN

Quy ước giữ nguyên hệ thống hiện tại (`systems/portal.tscn`, `target_scene` + `target_spawn = "from_<key>"`,
đích có `Spawn_from_<key>`). "Key" của Aldenmere là `thanh`.

| # | Điểm trong thành (ô) | Portal / cơ chế | Đích | `target_spawn` ở đích | Spawn quay về trong thành | Ghi chú |
|---|---|---|---|---|---|---|
| P1 | **Cổng chính** (29–30, 39) — portal đặt (29–30, 38) | Portal 2 chiều ở lòng cổng | `maps/ngoai_thanh.tscn` | `from_thanh` (đã có: (0,−480) ở The Wallfoot) | `Spawn_from_ngoai` tại (29–30, 36) — trong sân cổng, mặt hướng bắc | Giữ nguyên quan hệ scene cũ: thành `PortalSouth → ngoai_thanh/from_thanh`; The Wallfoot `PortalGate → thanh_xuan_lam/from_ngoai`. `Spawn_start` của thành = trùng `Spawn_from_ngoai` (lần đầu vào thành cũng từ phía nam). |
| P2 | **Cửa Quán Rượu Liên Hoa** (14, 15) | Portal cửa nhà (bước vào cửa) | **`maps/noi_that_quan_ruou.tscn` — SCENE MỚI** | `from_thanh` (đặt ở cửa ra vào trong nội thất) | `Spawn_from_quan` tại (14, 16) — ngay trước cửa quán, sân hàng 16 | Scene nội thất: phòng quán 1 tầng + gác nhỏ, quầy bar (NPC-04 ở đây), bàn ghế, cầu thang xuống hầm ở góc tây-nam nội thất. **Cần duyệt: có làm scene này không** (§11). |
| P3 | Cầu thang trong nội thất quán (góc hầm của scene mới) | Portal cầu thang | `maps/ham_ruou.tscn` | `from_village` (**giữ nguyên key cũ** — Elmford Cellar hiện có `Spawn_from_village`, portal về của nó trỏ `from_cave`) | Qua 2 bước: Hầm → nội thất quán (`Spawn_from_cave` đặt trong nội thất quán cạnh cầu thang) → cửa quán → thành | Việc đổi đường xuống hầm từ "cầu thang nhà trọ ngoài sân" (bản cũ, portal tại nhà trọ) sang "qua nội thất quán" là thay đổi có chủ ý theo thiết kế mới: quán là nơi giữ chìa hầm — hợp lore `chu_quan` giữ quest `dong_02_ham_ruou`. Nếu không làm nội thất quán (phương án B §11), giữ portal cầu thang trực tiếp tại cửa quán như bản cũ: (14,15) → `ham_ruou/from_village`, và `Spawn_from_cave` đặt tại (14,16). |
| P4 | **Miệng cống** cuối hẻm cụt H-T4 (16, 34) | Portal nắp cống (tương tác mở nắp) | `maps/cong_ngam.tscn` | `from_thanh` (đã có: (768,480) trong Aldenmere Sewers) | `Spawn_from_cong` tại (16, 33) — miệng hẻm, tránh spawn đè lên nắp cống | Giữ nguyên đích/key của scene cũ (cũ đặt tại (−520,290) ≈ ô (9, 24) — dời vào hẻm cụt cho có chất "lối xuống giấu trong hẻm"). Aldenmere Sewers hiện cũng nối ngược về thành (`from_cong`) và sang Royal Palace of Aldenmere (`from_cong` ở cung) + Mỏ Đá Xanh — không đổi các nối đó. |
| P5 | **Cổng Royal Palace of Aldenmere** (29–30, 2) | Portal cổng cung | `maps/hoang_cung.tscn` | `from_thanh` (đã có: (0,608) ở Royal Palace of Aldenmere) | `Spawn_from_cung` tại (29–30, 4) — trên bậc thềm trước cổng cung | Giữ đúng quan hệ cũ (cũ là `PortalNorth` ở biên bắc). Khác biệt: nay cổng cung nằm **trong** Nội Thành — người chơi phải qua cổng nội thành (gate quest) mới tới được, thay vì đi thẳng ra biên bắc như bản cũ. Royal Palace of Aldenmere portal về (`PortalMainGate → thanh/from_cung`) giữ nguyên. |
| — | Thang S1 (24, 35–37), S2 (35, 35–37), S3 (26, 10–12), S4 (33, 10–12) | `StairTrigger` đổi lớp collision (§2.3) — **không phải portal đổi scene** | Trong cùng scene (mặt tường T1/T2) | — | — | Không có Spawn marker; vị trí player giữ nguyên khi đổi lớp. |
| — | Cửa Nhà Trọ (14, 24), cửa nhà dân, doanh trại, phủ | Cửa trang trí + tương tác menu (trọ) / khoá (nhà dân) | Không scene nội thất (giai đoạn này) | — | — | Chỉ quán rượu có nội thất riêng — quyết định tiết kiệm art có chủ ý, cần duyệt (§11). |

**Bảng Spawn trong thành (tổng hợp cho dev):**

| Marker | Ô | Pixel Godot (tâm ô) | Nguồn đến |
|---|---|---|---|
| `Spawn_start` = `Spawn_from_ngoai` | (29, 36) | (−32, 1056) | The Wallfoot / bắt đầu vào thành lần đầu |
| `Spawn_from_cung` | (29, 4) | (−32, −992) | Royal Palace of Aldenmere |
| `Spawn_from_cong` | (16, 33) | (−864, 864) | Aldenmere Sewers |
| `Spawn_from_quan` | (14, 16) | (−992, −224) | Nội thất quán rượu (scene mới) |
| `Spawn_from_cave` *(chỉ khi dùng phương án B không nội thất)* | (14, 16) | (−992, −224) | Elmford Cellar trực tiếp |

---

## 9. DANH SÁCH TILE / PROP MỚI CẦN BỘ PHẬN ART LÀM

Chuẩn chung: tileset 64px, prop pixel art chi tiết cao (vẽ lớn rồi xử lý xuống như chuẩn sprite 128px đã chốt),
palette Aldenmere: xanh lá non `#7FB069`, rêu đậm, nâu đất ẩm, đá xám phủ rêu, ngói đỏ-nâu, accent hồng hoa đào/trắng hoa mận.
Mọi prop nhà/tường phải có **biến thể phủ rêu + dây leo hoa** (dấu ấn vùng) — ít nhất ở chân tường/mái.

### 9.1. Tile (TileMap, ô 64px)

| Tile | Biến thể / ghi chú | Kích thước |
|---|---|---|
| Nền đá lát quảng trường (vòng tròn đồng tâm + ô vuông) | 4–6 biến thể nứt/rêu nhẹ | 64×64 / tile |
| Nền đường đá đại lộ + đường phố | thẳng, vỉa, góc, ngã ba, ngã tư | 64×64 / tile |
| Nền đất nện (sân tập, sân kho), nền đất ẩm hẻm | 3 biến thể | 64×64 / tile |
| Nền sân lát gạch sân trong, nền thềm đá sáng (Nội Thành) | 2 biến thể | 64×64 / tile |
| Bậc thềm / bậc thang đá (thềm 1→2, 2→3, thang lên tường) | bậc ngang, bậc dọc | 64×64 / tile |
| Mặt tường đi được (đá lát + rãnh thoát nước) | thẳng + ô có châu mai bóng đổ | 64×64 / tile |
| Cỏ xuân + hoa đào/mận rơi, cỏ ẩm chân tường | 4 biến thể (cho tiền sân/vườn Nội Thành) | 64×64 / tile |

### 9.2. Prop / kiến trúc (sprite riêng, y-sort)

| Prop | Kích thước gợi ý (px) | Biến thể / ghi chú |
|---|---|---|
| **Tường thành đá** (đoạn thẳng) | 128×128 / đoạn 2 ô (thân + mặt trên + châu mai vẽ liền) | + góc trong, góc ngoài, đầu tường; bản phủ rêu nặng cho tường ngoài, bản sạch cho tường trong |
| **Cổng thành** (vòm + 2 cánh gỗ + biển tên) | 256×192 (4×3 ô) cho cổng chính; 256×160 cho cổng nội thành | Cánh mở/cánh đóng (2 frame trạng thái) |
| **Tháp canh** | 192×256 (chân 3 ô, cao 4 ô thị giác) | Mái ngói rêu; bản tháp góc to 256×288 |
| **Mặt tường + cầu nối nóc cổng/tháp** | 128×64 / đoạn | Đoạn cầu nối có lan can gỗ |
| **Tượng Hộ Mộc Thần** | 128×192 (chân 2 ô, cao 3 ô) + bệ 256×128 | Đá phủ rêu, kiếm cắm rễ đá; là prop quan trọng nhất — vẽ ở độ phân giải gấp đôi rồi downscale |
| **Đài phun nước** | 192×192 (Ø ~3 ô thị giác, chân 2 ô) | **4 frame nước động** (mặt nước + tia phun tách layer để animate độc lập) |
| **Sạp chợ** | 128×128 (2×2 ô) | **3 biến thể**: mái bạt sọc rau quả, mái lá vải/thảo dược, mái gỗ đồ sắt/gốm; + trạng thái phủ bạt đóng sạp (mỗi biến thể 1 bản) |
| **Nhà thành phố 1 tầng** | 192–320 × 160–192 (3–5 ô mặt tiền) | Nằm trong bộ nhà dưới |
| **Nhà thành phố 2 tầng** | 192–320 × 224–288 | **Tổng bộ nhà: 3–4 biến thể** khác mái (ngói đỏ / ngói rêu / mái xám đá) + màu tường (trắng vôi / vàng nhạt / gỗ nâu), có bản nhà hẹp 3 ô cho hẻm và nhà rộng 5 ô cho phố chính; cửa sau cho nhà mở ra hẻm |
| **Lò rèn** (lò lửa + ống khói) | lò 128×128, ống khói 64×128 | Lửa 3 frame; khói dùng particle của engine nhưng cần sprite khói mềm 64×64 |
| **Đe + thùng tôi + giá vũ khí** | đe 64×64, bộ sân rèn gộp 192×64 | Điểm việc của thợ rèn — chi tiết cao |
| **Biển hiệu quán rượu / nhà trọ** | 128×64 treo + đèn lồng 32×48 | Chữ "LIÊN HOA" vẽ vào biển (đừng dùng font hệ thống trong game); đèn lồng 2 frame sáng |
| **Dây phơi** (sào + dây + quần áo) | 128×96 / nhịp (chăng ngang hẻm 1–2 ô) | 3 biến thể quần áo; **2–3 frame đung đưa**; vẽ ở layer trên mái |
| **Cầu nối mái** (ván + mái phụ) | 128×64 | Đặt ở lớp decor trên mái, không collision |
| **Thùng / hộp hàng chợ / bao lúa / xe đẩy** | thùng 64×64, hộp 64×48, bao 48×48, xe 128×96 | Mỗi loại 2 biến thể (đầy/rỗng, có nắp/không) |
| **Giếng thành** (thành giếng + ròng rọc) | 128×128 | Dùng cho giếng quảng trường (35,14) + bản nhỏ 96×96 cho sân trong S-T |
| **Cổ Thụ** (gốc + rễ nổi + tán) | gốc 192×256, rễ tràn 256×128, tán 704×384 vẽ tách 3 lớp | Prop lớn nhất game vùng Đông; tán tách lớp để rung nhẹ + hoa rơi particle |
| **Cây con quảng trường + cây hoa phố** | 128×192 | 2 biến thể (đào hồng / mận trắng) |
| **Hình nộm rơm sân tập** | 64×128 | 2 frame (nguyên / bị đánh tơi) nếu dư lực |
| **Bảng nhiệm vụ** (bản nâng cấp từ prototype) | 128×128 | Giấy quest dán sẵn 3–4 tờ vẽ liền |
| **Đèn đá / cột đèn phố** | 32×96 | 2 trạng thái ngày/tắt — đêm/sáng (frame đèn cháy) |
| **Nắp cống sắt + miệng cống** | 64×64 | Frame nắp đóng / nắp mở hé (cho portal P4) |
| **Cờ Mộc trụ + banner thành** | 64×128 | 3 frame phấp phới, treo cổng chính + doanh trại |
| **Bàn ghế ngoài trời quán / ghế đá quảng trường** | bàn 64×64, ghế 96×48 | Bộ nhỏ, dùng lặp nhiều nơi |

---

## 10. RỦI RO / LƯU Ý KHI DỰNG SCENE SAU

1. **Hẻm 1 ô (64px) vs hitbox player 28px:** lọt về lý thuyết (64 > 28 + NPC 28 khi tránh nhau), nhưng
   **2 NPC ngược chiều trong hẻm sẽ kẹt nhau** — hệ schedule phải cho NPC dân cư đi hẻm theo vòng 1 chiều
   (đã thiết kế hẻm chính thành vòng: vào H-T2 xuống, ra H-T3 lên) và NPC **không dừng/đứng nói chuyện trong hẻm** (điểm dừng chỉ ở sân trong/đường chính).
   Camera cũng dễ "cấn" mái nhà 2 tầng khi đi hẻm sát tường — cân nhắc mái nhà dãy kề hẻm tự mờ (fade) khi player ở hẻm (shader/opacity theo Area2D) — ghi là nice-to-have, không chặn bản dựng đầu.
2. **Y-sort nhà 2 tầng:** nhà cao 224–288px sẽ che nhân vật đứng phía bắc nhà (đúng vật lý top-down) — nhưng với nhà **sát nhau** ở dân cư,
   nhân vật đi hẻm ngang H-T1/H-Đ1 (nằm giữa 2 dãy nhà) sẽ bị mái dãy bắc che liên tục. Xử lý: điểm neo y-sort (origin) của nhà đặt ở **chân tường nam** của nhà,
   và hẻm ngang tính là "đường" có y lớn hơn chân nhà dãy bắc → nhân vật ở hẻm luôn vẽ trên chân nhà bắc, chỉ bị che bởi nhà dãy nam khi đứng sát — phải test thực tế với 1 dãy nhà trước khi nhân bản cả khu.
3. **Mặt tường cần lớp z riêng:** `WallTop_Walkable` phá y-sort toàn cục (người trên tường phải vẽ trên mái nhà thấp hơn ở phía nam tường).
   Dùng `z_index` tương đối cao + `z_as_relative = false` cho nhóm này, và lính canh/player trên tường dùng bản sao sprite cùng hình (tránh phải đổi z của Player dùng chung mọi map).
   Rủi ro phụ: bóng (shadow) của nhân vật trên tường rơi sai lớp — chấp nhận tắt bóng mềm cho trạng thái trên tường.
4. **Layer-swap cầu thang (§2.3 mục 3):** phải đảm bảo NPC tuần B (NPC-02) dùng cùng trigger mà không kẹt trạng thái khi người chơi cũng đang trên tường;
   collision mép tường phải là shape liên tục (không缝 hở ở khớp đoạn) nếu không player sẽ "lọt" tại điểm nối đoạn T1 qua nóc tháp canh.
   Nếu layer-swap hóa ra tốn công hơn dự kiến, phương án lùi: cầu thang là portal nội bộ (fade 150ms, dời player lên mặt tường) — xấu hơn nhưng chắc chắn chạy; **chỉ dùng khi đã thử layer-swap và fail, và phải ghi vào log dựng**.
5. **Độ lớn scene & thời gian dựng tay:** 60×40 với dân cư dày là khối lượng đặt prop lớn nhất vùng Đông.
   Dựng theo thứ tự: Ground + tường + đại lộ → quảng trường → từng `District_*` một, playtest từng khu (đặc biệt là hẻm) trước khi sang khu kế.
   Đừng dựng cả thành trong 1 phiên không kiểm tra — bài học từ các map trước.
6. **Quest cũ gắn với vị trí cũ:** `chu_quan`/`tho_ren`/`linh_gac` hiện đứng ở toạ độ bản cũ và mang quest `dong_02/03/04`, `dong_side_*`.
   Khi dựng lại phải **gán lại điểm đứng/điểm việc theo §7 và rà `dong_04_golem`** (điểm giao ở cổng bắc cũ không còn tồn tại; boss Mossback, the Moss Golem theo world v2 ở Gốc Cổ Thụ — Nội Thành — còn phân thân ở Mỏ/Moss Den theo `vung_dong_so_do.md`). Không tự ý đổi id NPC/quest.
7. **Cổ Thụ là đấu trường boss:** vòng Ø ~7 ô quanh gốc (cột 43–53, hàng 2–8) không đặt prop có collision cố định ngoài gốc cây;
   hàng rào khoá khu phải là node riêng bật/tắt theo quest, không vẽ chết vào tile nền.
8. **Đài phun + tượng ở tâm trục nhìn:** từ cổng chính (hàng 39) tới tượng là ~19 ô trống trục — tránh đặt prop cao (cây, đèn cao) giữa đại lộ đoạn hàng 26–35 làm đứt trục nhìn 3 landmark (cổng → tượng → cổng nội thành).
9. **Số NPC đồng thời ở chợ giờ cao điểm:** 3 tiểu thương + 2 dân chợ + gánh nước + tuần B có thể cùng ở khu chợ (~7 NPC + player) — kiểm tra tránh nhau (navigation) ở ô chờ khách trước sạp; nếu kẹt, giảm tốc độ vòng chợ thay vì nới đường chợ (đường chợ 3 ô là chuẩn thiết kế, không nới).
10. **Tên file scene nội thất quán:** đề xuất `game/maps/noi_that_quan_ruou.tscn` — khi tạo phải đăng ký vào sơ đồ vùng (`vung_dong_so_do.md`) và bảng spawn §8, nếu không sẽ lặp lại lỗi tài liệu vùng lệch scene như bản cũ (thành từng nối Barleyfield/Cloudpeak trong tài liệu nhưng scene nối The Wallfoot/Royal Palace of Aldenmere).

---

## 11. ĐIỂM CẦN DUYỆT TRƯỚC KHI DỰNG

1. **Kích thước thành 3840×2560 (60×40)** — giữ nguyên hay thu xuống (ví dụ 3200×2240 / 50×35, phải cắt bớt 1 dãy dân cư)?
   Đề xuất của thiết kế: **giữ 60×40** — đây là thành phải "chú trọng nhất" theo yêu cầu đã chốt.
2. **Có làm scene nội thất quán rượu riêng (`noi_that_quan_ruou.tscn`) không?** — Đề xuất: **có**
   (đây là nội thất duy nhất của thành ở giai đoạn này; Elmford Cellar xuống từ trong quán như thiết kế mới).
   Phương án B nếu cắt: portal cầu thang trực tiếp tại cửa quán như scene cũ (P3 ở §8).
3. **Cơ chế mặt tường:** layer-swap tại cầu thang (mượt, tốn công) hay portal nội bộ fade (đơn giản, hơi cụt)?
   Đề xuất: thử layer-swap trước, lùi về portal nếu fail (§10.4).
4. **Tách quán rượu / nhà trọ thành 2 NPC + 2 công trình riêng** (bản cũ gộp "Nhà Trọ Liên Hoa" + `chu_quan`) — đồng ý phân lại quest `dong_02/03` cho chủ trọ, chủ quán giữ tin đồn + đầu mối hầm?
5. **Cổng bắc thành không còn là cổng ra ngoài** (Royal Palace of Aldenmere nằm trong Nội Thành; Cloudpeak đi qua The Wallfoot) — xác nhận bỏ hẳn `PortalNorth → hoang_cung` ở biên bắc kiểu cũ và `Spawn_from_nui` ở thành.

---

*Tài liệu này chỉ thiết kế. Chưa file `.tscn`/`.gd` nào được tạo hay sửa. Sơ đồ trực quan: `thanh_xuan_lam_layout.png`.*
