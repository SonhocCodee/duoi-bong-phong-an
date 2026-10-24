# FROSTGARD — LAYOUT CHI TIẾT (Thiết kế để duyệt bố cục, chưa dựng scene)

> **Game:** Dưới Bóng Phong Ấn — Godot 4, Action RPG top-down  
> **Loại tài liệu:** Thiết kế bố cục map thành — CHỈ tài liệu + sơ đồ, chưa dựng `.tscn`.  
> **Trạng thái: BẢN CHỜ USER DUYỆT — CHƯA DỰNG SCENE.** Duyệt bố cục này xong mới được dựng `maps/frostgard.tscn`.  
> **Sơ đồ kèm theo:** `design/frostgard_layout.png` — vẽ đúng lưới 240×170 của tài liệu này. Script vẽ: `tools/draw_frostgard.py`.  
> **Nguồn đối chiếu:** `design/cot_truyen_4_phan.md` Phần 4, `design/world_v2_4_thanh.md` §2.4, `design/frostgard_so_do.md`.

---

## 0. Ý TƯỞNG THÀNH — KHÁC HẲN ALDENMERE, FENMIRE VÀ SOLMARIS

| Khác biệt cốt lõi | Aldenmere (Đông) | Fenmire (Nam) | Solmaris (Tây) | Frostgard (Bắc) |
|---|---|---|---|---|
| Địa thế | Đất liền, thềm cao lên bắc | Cù lao giữa đầm | Ốc đảo bị tường sa thạch khép kín giữa biển cát | **Pháo đài trên gò băng, tường đá đen + băng, đêm dài và bão tuyết** |
| Tường | Đá xám dày, tháp canh, mặt tường đi được | Gỗ–đá thấp + hào nước trong tường | Sa thạch vàng/đỏ dày 3 ô, cổng hàm cát | **Đá đen + băng gia cố dày 3 ô**, cổng sắt nặng ở phía Nam, tháp gác trên Tường Bắc |
| Trung tâm | Quảng trường + tượng + đài phun đá | Bể chợ nổi + kênh lớn | Ốc đảo thật + đài phun trung tâm | **Lò Lớn Trung Tâm** — lò rèn khổng lồ cháy ngày đêm, vừa sưởi cả thành vừa rèn thép băng |
| Quyền lực | Hoàng cung vua bù nhìn | Đền giáo phái ở gò nam | Phủ Hội Đồng Lính Đánh Thuê ở gò bắc — vua đã chết | **Ngai Băng ở gò bắc** — vua undead vẫn ngồi gác; không ai “cai trị” theo nghĩa sống nữa |
| Cái giá của trụ | Rễ cây nuốt nhà/mộ | Người giữ triều chết theo nghi lễ | Một sinh vật bị giam trong vai quái vật | **Trụ làm bằng NGƯỜI: đội gác băng từng đời — nghĩa trang + đài danh sách tên nằm ngay trong thành** |
| Dân cư | Đông, sống quanh chợ | Dân chài trong thành | Khu bộ lạc nằm ngoài tường Đông | **Dân cư thưa, nhiều nhà đóng băng bỏ trống** — thành quân sự đang chết dần cùng quân đoàn của nó |

---

## 1. CHUẨN KÍCH THƯỚC

| Thông số | Giá trị |
|---|---|
| Kích thước map | **240 cột × 170 hàng ô = 40.800 ô** (15.360 × 10.880 px) |
| Tile | 64×64 px |
| Hệ tọa độ | Ô (cột, hàng): cột 0–239 Tây→Đông, hàng 0–169 Bắc→Nam |
| So sánh | Bằng Solmaris (240×170), nhỏ hơn Aldenmere (260×190); mật độ nhà thấp có chủ ý (thành thưa người), mật độ tường/khu quân sự cao |

---

## 2. TƯỜNG ĐÁ ĐEN + BĂNG & CỔNG

| Đoạn | Vị trí | Chi tiết |
|---|---|---|
| Đất trong thành | cột 8–231, hàng 8–161 | Ngoài vành này là tuyết sâu và đất chết dần về phía Sigilspire |
| Tường Bắc | hàng 10–12, cột 10–229 | Đá đen + băng dày 3 ô, tháp gác nối tiếp — khu quest phòng thủ ca đêm nhìn ra đất chết |
| Tường Nam | hàng 159–161, cột 10–229 | Hở **cổng sắt Nam** cột 115–124, nối Frostgard Approach |
| Tường Tây | cột 10–12, hàng 10–161 | Không cổng; nhà nguyện và nghĩa trang dựa vào tường tây |
| Tường Đông | cột 227–229, hàng 10–161 | Không cổng; xưởng rèn và doanh trại dựa vào tường đông |
| Cổng sắt Nam | cột 115–124, hàng 159–161 | Cổng chính từ Frostgard Approach; `Spawn_from_approach` dự kiến ở (120, 155) |
| Cổng Bắc (dự kiến, đợt cuối) | cột 115–124, hàng 10–12 | Đường ra đất chết hướng Sigilspire — chỉ mở ở đợt endgame, không thuộc layout đợt này ngoài việc chừa vị trí |

Cổng sắt phải nhiều người kéo mới mở (chi tiết lore khi dựng thật): cổng là điểm nghẽn phòng thủ, không phải cửa chợ.

---

## 3. CÁC KHU CHỨC NĂNG

| Khu | Vị trí (cột × hàng) | Nội dung |
|---|---|---|
| Ngai Băng + Sảnh Vua Đóng Băng | 92–148 × 18–44 | Gò cao phía bắc; ngai băng, sảnh vua trống lạnh, hiệp sĩ đóng băng đứng gác hai bên — bản lớn của Đài Ngai Băng ở Approach |
| Nhà Nguyện Không Chuông + Tháp Chuông Lớn | 18–60 × 20–50 | Nhà nguyện không có chuông (chuông đã bị nguyền làm câm) + tháp chuông lớn ở góc tây-bắc — neo nghi lễ giải thoát |
| Doanh Trại Hiệp Sĩ Băng | 172–222 × 20–50 | Doanh trại, sân tập, hàng hiệp sĩ đóng băng đứng theo đội hình ca gác không bao giờ đổi |
| Nghĩa Trang Quân Đoàn + Đài Danh Sách Tên | 18–56 × 62–112 | Bia mộ theo hàng quân, Đài Danh Sách Tên ở giữa — nơi đọc tên trong nghi lễ / quest tưởng niệm |
| Lò Lớn Trung Tâm | 100–140 × 68–102 | Lò rèn/sưởi khổng lồ ở tâm thành (tâm khoảng 120, 85); điểm hẹn, điểm sưởi (checkpoint ấm), NPC thợ rèn master |
| Xưởng Rèn Thép Băng + Kho Thép | 176–224 × 62–108 | Xưởng rèn thép băng, kho thép, bể tôi băng — shop vũ khí/giáp tốt nhất vòng ngoài |
| Tường Bắc + Tháp Gác | hàng 10–12 + dải hàng 13–17 | Tuyến gác đêm: tháp gác, điểm lửa, quest phòng thủ theo đợt với wight/quân đoàn ma |
| Khu Dân Cư Đóng Băng + Nhà Trọ Lò Sưởi | 26–108 × 120–152 | Nhà thấp mái dày, nhiều nhà đóng băng bỏ trống xen nhà còn người ở; nhà trọ lò sưởi (buff kháng lạnh) ở gần đường chính |
| Điểm Tập Kết Trưng Thu | 128–168 × 124–152 | Góc tối cạnh cổng Nam: sân tập kết người bị chọn đi gác băng, sổ trưng thu, chuồng xe trượt — bố cục tự kể chuyện Trụ Hàn lấy người thế nào |

**Lưu ý dựng thật bắt buộc:** sơ đồ chỉ là phân khu chức năng. Nhà cửa khi dựng scene phải hữu cơ — lệch hàng 0–2 ô, nhiều cỡ/màu mái, hẻm rộng hẹp thất thường, không xếp đều như mạch điện. Riêng hàng bia mộ và đội hình doanh trại được phép (và nên) thẳng hàng: đó là kỷ luật quân đội, là chủ ý tương phản với khu dân cư hữu cơ.

---

## 4. ĐƯỜNG CHÍNH

Đường chính dự kiến đi: **Cổng sắt Nam (120, 160) → bắc qua Điểm Tập Kết Trưng Thu → Lò Lớn Trung Tâm (120, 85) → Ngai Băng (120, 44)**. Nhánh ngang ở hàng Lò Lớn tỏa tây sang Nghĩa Trang/Nhà Nguyện và đông sang Xưởng Rèn/Doanh Trại. Đường phụ xuống khu dân cư uốn cong tránh các sân trong đóng băng, không dùng lưới ô vuông đều.

---

## 5. PORTAL + SPAWN DỰ KIẾN

| # | Điểm trong thành (ô) | Đích | Spawn ở đích | Spawn quay về |
|---|---|---|---|---|
| P1 | Cổng sắt Nam (120, 160) | `frostgard_approach.tscn` | `from_frostgard` | `Spawn_from_approach` tại (120, 155) |
| P2 | Lò Lớn Trung Tâm (120, 85) | Không phải portal | — | Điểm hẹn / checkpoint ấm / cutscene giải thoát |
| P3 | Cổng Bắc (120, 11) | Đất chết hướng Sigilspire (đợt cuối, chưa có map) | — | `Spawn_from_deadland` dự kiến tại (120, 16) — chỉ chừa vị trí ở đợt này |

---

## 6. ĐIỂM CẦN USER DUYỆT TRƯỚC KHI DỰNG

1. **Bố cục tổng thể + kích thước 240×170** theo `frostgard_layout.png`: ngai băng ở gò bắc, lò lớn ở tâm, nhà nguyện không chuông ở tây-bắc, nghĩa trang quân đoàn ở tây, doanh trại + xưởng rèn ở đông, dân cư thưa ở nam.
2. **Tên vua đề xuất:** King Valdemar, the Frostbound King — duyệt tên này hay đổi?
3. **Tên Kẻ Giữ Nguyền đề xuất:** Vharok — duyệt tên này hay đổi?
4. **Tên làng đề xuất:** Hearthwick (Làng Lò Sưởi) — duyệt tên hiển thị này hay giữ thuần “Làng Lò Sưởi”?
5. **Chuông = neo vật lý của lời nguyền:** phương án thiết kế hiện tại là chiếc chuông câm (ở Legion Crypt + tháp chuông thành) là neo giữ nguyền — nghi lễ giải thoát phải đọc tên bên chuông. Duyệt cơ chế “chuông là neo” này hay muốn neo là vật khác (ngai / ấn / sổ ca gác)?
6. **Nghĩa trang quân đoàn trong thành hay ngoài tường:** layout này đặt nghĩa trang + đài danh sách **trong** tường (tây) để người chơi đi qua mỗi ngày. Duyệt trong thành, hay chuyển ra ngoài tường cho thành đỡ nặng?
7. **Khu Điểm Tập Kết Trưng Thu có dựng không:** khu này kể chuyện Trụ Hàn lấy người đi gác băng. Duyệt dựng hẳn một khu, hay chỉ để một sân nhỏ + sổ trưng thu cạnh cổng cho tiết chế?
8. **Dân cư thưa tới mức nào:** đề xuất hiện tại là khu dân cư chỉ còn khoảng 1/3 nhà có người ở, còn lại đóng băng bỏ trống. Duyệt mức thưa này, hay muốn thành còn sức sống hơn (một nửa nhà có người)?

---

*Tài liệu này chỉ thiết kế để duyệt bố cục. Chưa dựng scene nội thành Frostgard.*
