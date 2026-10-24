# SOLMARIS — LAYOUT CHI TIẾT (Thiết kế để duyệt bố cục, chưa dựng scene)

> **Game:** Dưới Bóng Phong Ấn — Godot 4, Action RPG top-down  
> **Loại tài liệu:** Thiết kế bố cục map thành — CHỈ tài liệu + sơ đồ, chưa dựng `.tscn`.  
> **Trạng thái: BẢN CHỜ USER DUYỆT — CHƯA DỰNG SCENE.** Duyệt bố cục này xong mới được dựng `maps/solmaris.tscn`.  
> **Sơ đồ kèm theo:** `design/solmaris_layout.png` — vẽ đúng lưới 240×170 của tài liệu này. Script vẽ: `tools/draw_solmaris.py`.  
> **Nguồn đối chiếu:** `design/cot_truyen_4_phan.md` Phần 3, `design/world_v2_4_thanh.md` §2.3, `design/solmaris_so_do.md`.

---

## 0. Ý TƯỞNG THÀNH — KHÁC HẲN ALDENMERE VÀ FENMIRE

| Khác biệt cốt lõi | Aldenmere (Đông) | Fenmire (Nam) | Solmaris (Tây) |
|---|---|---|---|
| Địa thế | Đất liền, thềm cao lên bắc | Cù lao giữa đầm | **Ốc đảo bị tường sa thạch khép kín giữa biển cát** |
| Tường | Đá xám dày, tháp canh, mặt tường đi được | Gỗ–đá thấp + hào nước trong tường | **Sa thạch vàng/đỏ dày 3 ô**, cổng hàm cát, không hào nước |
| Trung tâm | Quảng trường + tượng + đài phun đá | Bể chợ nổi + kênh lớn | **Ốc đảo thật + đài phun trung tâm** — nước là tài nguyên quyền lực |
| Chợ | Khu chợ quanh quảng trường | Chợ nổi trên bè | **Chợ phiên lớn (Grand Bazaar)** ở tây–trung: sạp vải, kho caravan, đấu giá nước |
| Quyền lực | Hoàng cung vua bù nhìn | Đền giáo phái ở gò nam | **Phủ Hội Đồng Lính Đánh Thuê** ở gò bắc — vua đã chết, không có cung điện đang dùng |
| Dân bị gạt ra ngoài | Không rõ | Dân chài trong thành | **Khu bộ lạc nằm ngoài tường Đông** — bố cục tự kể chuyện phân biệt đối xử |

---

## 1. CHUẨN KÍCH THƯỚC

| Thông số | Giá trị |
|---|---|
| Kích thước map | **240 cột × 170 hàng ô = 40.800 ô** (15.360 × 10.880 px) |
| Tile | 64×64 px |
| Hệ tọa độ | Ô (cột, hàng): cột 0–239 Tây→Đông, hàng 0–169 Bắc→Nam |
| So sánh | Nhỏ hơn Aldenmere (260×190) một chút, lớn hơn layout Fenmire (220×160); mật độ chợ/nhà cao, nhiều khoảng cát trống có chủ ý quanh ốc đảo và khu caravan |

---

## 2. TƯỜNG SA THẠCH + CỔNG

| Đoạn | Vị trí | Chi tiết |
|---|---|---|
| Đất trong thành | cột 8–211, hàng 8–161 | Ngoài vành này là cát và khu bộ lạc phía đông |
| Tường Bắc | hàng 10–12, cột 10–209 | Sa thạch dày 3 ô, tháp nước/tháp canh thấp |
| Tường Nam | hàng 159–161, cột 10–209 | Không cổng chính; chuồng lạc đà và kho dựa vào tường |
| Tường Tây | cột 10–12, hàng 10–161 | Hở **cổng Tây nhỏ** hàng 80–89 đi hang Vesskar |
| Tường Đông | cột 207–209, hàng 10–161 | Hở **cổng Đông** hàng 78–91 |
| Cổng Đông | cột 207–209, hàng 78–91 | Cổng chính từ Fenmire/caravan + khu bộ lạc ngoài tường; `Spawn_from_approach` dự kiến ở (204, 84) |
| Cổng Tây nhỏ | cột 10–12, hàng 80–89 | Đường tắt đi Vesskar's Lair; chỉ mở rõ sau khi liên minh thành lập (đề xuất gate bằng flag `lien_minh_bo_lac`) |

Không dùng mặt tường đi được như Aldenmere: điểm cao của Solmaris là **tháp nước** và **tháp canh sa thạch**, dự kiến làm khu riêng/polish sau nếu user duyệt.

---

## 3. CÁC KHU CHỨC NĂNG

| Khu | Vị trí (cột × hàng) | Nội dung |
|---|---|---|
| Phủ Hội Đồng Lính Đánh Thuê | 80–165 × 18–45 | Sảnh hội đồng, kho vũ khí, sân duyệt binh; “ngai” trống phủ vải — vua đã chết |
| Tháp Nước + Hầm Chứa | 18–48 × 20–48 | Tháp nước, máy bơm/hầm chứa, điểm kiểm soát nước của hội đồng |
| Grand Bazaar — Chợ Phiên Lớn | 35–96 × 52–124 | 30–40 sạp vải xô lệch, đấu giá nước, bảng nhiệm vụ ở (66, 56), khu ăn đêm |
| Ốc Đảo + Đài Phun Trung Tâm | 104–139 × 66–103 | Hồ nước thật, đài phun ở tâm (khoảng 121, 84), cây chà là, điểm hẹn liên minh |
| Khu Caravan + Kho Hàng | 148–202 × 55–112 | Kho, bãi xe, chuồng tạm, cổng ra vào hàng hóa |
| Đền Cổng Phong Ấn | 15–30 × 66–104 | Đền nhỏ ở sát cổng Tây, giữ bản sao lời thề Vesskar |
| Khu Nhà Đất Nung / Dân Cư | 25–96 × 128–152 | Nhà đất nung nhiều cỡ/mái, hẻm cong, sân trong bất quy tắc khi dựng thật |
| Chuồng Lạc Đà + Xưởng Da | 106–178 × 128–152 | Chuồng, xưởng da, bãi phơi, kho yên cương |
| Khu Bộ Lạc Ngoài Tường | 214–236 × 48–122 | Lều bộ lạc, lửa trại, bãi săn — nằm ngoài tường Đông, nối cổng bằng đường caravan hàng 78–91 |

**Lưu ý dựng thật bắt buộc:** sơ đồ chỉ là phân khu chức năng. Nhà/sạp khi dựng scene phải hữu cơ — lệch hàng 0–2 ô, nhiều cỡ/màu mái, hẻm rộng hẹp thất thường, không xếp đều như mạch điện.

---

## 4. ĐƯỜNG CHÍNH

Đường chính dự kiến đi: **Cổng Đông (208, 84) → nam Khu Caravan (164, 108) → bắc Ốc Đảo (140, 62) → bắc Chợ (70, 60) → Đền Cổng Phong Ấn / Cổng Tây**. Đường vòng tránh hồ trung tâm, không cắt qua mặt nước. Các đường phụ tỏa xuống khu dân cư và chuồng lạc đà theo cung cong, không dùng lưới ô vuông đều.

---

## 5. PORTAL + SPAWN DỰ KIẾN

| # | Điểm trong thành (ô) | Đích | Spawn ở đích | Spawn quay về |
|---|---|---|---|---|
| P1 | Cổng Đông (208, 84) | `fenmire_approach.tscn` / đường caravan về Fenmire | `from_solmaris` | `Spawn_from_approach` tại (204, 84) |
| P2 | Đài phun trung tâm (121, 84) | Không phải portal | — | Điểm hẹn liên minh / cutscene |
| P3 | Cổng Tây nhỏ (11, 84) | `vesskar_lair.tscn` | `from_solmaris` | `Spawn_from_lair` tại (16, 84) |
| P4 | Khu bộ lạc ngoài tường (225, 84) | Trong cùng scene | — | Khu lều/lửa trại ngoài tường, không load map |

---

## 6. ĐIỂM CẦN USER DUYỆT TRƯỚC KHI DỰNG

1. **Bố cục tổng thể + kích thước 240×170** theo `solmaris_layout.png`: phủ hội đồng ở bắc, chợ lớn tây–trung, ốc đảo/đài phun ở tâm, khu bộ lạc ngoài tường Đông.
2. **Tên hai bộ lạc đề xuất:** Dunehawk Tribe (Diều Cát) và Stonesong Tribe (Đá Vang).
3. **Tên chỉ huy đề xuất:** Kassia Vane — boss đấu trường và người đại diện hội đồng.
4. **Khu bộ lạc nằm ngoài tường** như một phần của scene thành: duyệt hướng này hay muốn bộ lạc chỉ ở 2 trại map riêng ngoài vùng?
5. **Cổng Tây nhỏ đi thẳng hang Vesskar** từ thành: duyệt đường tắt này hay giữ hang chỉ đi qua Buried Sand Ruins như tuyến đợt 4 hiện tại?
6. **Không dựng cung điện vua đang dùng** — chỉ có phủ hội đồng + “ngai trống” để nhấn mạnh vua đã chết. Nếu user muốn thêm di tích cung điện cũ thì cần thêm một khu vào layout.

---

*Tài liệu này chỉ thiết kế để duyệt bố cục. Chưa dựng scene nội thành Solmaris.*
