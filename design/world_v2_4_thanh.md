# DƯỚI BÓNG PHONG ẤN — THIẾT KẾ THẾ GIỚI & CỐT TRUYỆN v2: BỐN THÀNH, MỘT THÁP

> **Loại tài liệu:** World Design & Main Story Bible — phiên bản 2
> **Game:** Dưới Bóng Phong Ấn — Action RPG top-down fantasy, Godot 4, solo dev
> **Phạm vi:** Thế giới 4 vùng + tháp trung tâm, cốt truyện 3 hồi, quest chính tuyến, hệ thống phong ấn
> **Trạng thái:** Đã chốt theo GDD v1 + cập nhật world design 2026-10-23 — dùng làm chuẩn để map sang prototype
> **Nguyên tắc nhất quán:** Mọi tên thành, tên boss, dải level, tên làng, tên dungeon trong tài liệu này là **chuẩn duy nhất**. Không tự đổi tên ở các tài liệu / scene / code khác.

---

## MỤC LỤC

1. Sơ đồ thế giới & Bảng tổng quan 5 khu vực
2. Chi tiết từng vùng: Đông — Nam — Tây — Bắc
3. Tháp Vương Ấn — Trung tâm & Endgame
4. Tuyến tiến triển & Cổng chặn
5. Hệ thống Phong Ấn: 4 Trụ, 4 Chìa & Cái Giá Của Việc Mở Cổng
6. Quest chính tuyến theo từng vùng & Quest phụ gợi ý
7. Bảng đối chiếu nhất quán cho Dev / Prototype
8. Phụ lục: Timeline cốt truyện 3 hồi, Motif & Tone

---

## 1. SƠ ĐỒ THẾ GIỚI & BẢNG TỔNG QUAN

### 1.1. Ý tưởng cốt lõi của thế giới

Thế giới không phải một lục địa tự do vô hướng. Nó là một **ấn đồ sống** (living seal diagram) được vẽ bằng địa lý:

- 4 tòa thành ở 4 hướng Đông / Tây / Nam / Bắc là 4 **Trụ Phong Ấn**.
- Tòa tháp khổng lồ ở chính giữa — **Tháp Vương Ấn** — là **khóa trung tâm**, nơi thứ bị giam bị neo lại.
- Đất đai, khí hậu, quái vật và cả bệnh tật của từng vùng đều là **triệu chứng** của phong ấn đang yếu dần ở vùng đó.

Người chơi bắt đầu trắng tay ở phía Đông, đi một vòng gần như theo chiều kim đồng hồ — Đông → Nam → Tây → Bắc — và mỗi lần "giải quyết" một thành, người chơi thực chất đang **chạm vào một trụ phong ấn**. Càng tiến về trung tâm, thế giới càng bớt giống truyện cổ tích cứu công chúa, càng giống một nghi lễ đang bị tháo dỡ mà không ai nói rõ tháo xong thì chuyện gì sẽ xảy ra.

> **Câu hỏi trung tâm của game:** Nếu phong ấn giữ công chúa sống, giữ nhà vua trên ngai, và giữ thứ ở dưới tháp không thoát ra — thì "phá phong ấn để cứu công chúa" có còn là việc tốt không?

### 1.2. Sơ đồ thế giới dạng ASCII

```text
                                 BẮC — HÀN ĐỚI
                    Băng tuyết / Bão tuyết / Cực quang
                         Level 19-24
                    ┌─────────────────────┐
                    │   THÀNH HÀN THIẾT   │
                    │  Boss: Hiệp Sĩ Đen  │
                    │     (Hiệp Sĩ Băng)  │
                    └─────────┬───────────┘
              Làng Lò Sưởi ───┼─── Làng Săn Tuyết
                         Làng Cực Quang
                    Dungeon: Pháo Đài Băng Nứt
                                  │
                                  │  Đèo Gió Rít / Đường Băng Phong
                                  │
   TÂY — SA MẠC                   │                         ĐÔNG — ÔN ĐỚI
   Khô nóng / Bão cát      ┌──────┴──────┐            Rừng xanh / Mưa phùn / Xuân vĩnh cửu
   Level 13-18             │             │                  Level 1-6
┌─────────────────┐        │  ĐẤT CHẾT   │        ┌─────────────────────┐
│ THÀNH HỒNG SA   │────────│  TRO TÀN    │────────│  THÀNH XUÂN LÂM     │
│ Boss: Rồng Cát  │  Cổng  │             │  Cổng  │  Boss: Golem Rêu    │
│      Vesskar    │  Tây   │ THÁP VƯƠNG  │  Đông  │       Cổ Thụ        │
└────────┬────────┘        │     ẤN      │        └─────────┬───────────┘
 Làng Giếng Cạn            │  Lv.25      │         Làng Tân Diệp ★ (khởi đầu)
 Làng Chợ Đêm              │  Vua: đỉnh  │         Làng Mạch Lúa
 Làng Ốc Đảo               │  Công chúa: │         Làng Bến Mưa
   Cát Trắng               │  trong tháp │         Dungeon: Hầm Rượu Chuột Chúa
 Dungeon: Lăng Cát Chôn    │  Boss cuối: │                   + Mỏ Rêu Cổ
                           │  dưới / đỉnh│
                           └──────┬──────┘
                                  │  Đầm Ngập Triều / Cầu Muối
                                  │
                    ┌─────────────┴───────────┐
                    │   THÀNH TRIỀU ẨM        │
                    │   Boss: Phù Thủy        │
                    │   Đầm Lầy Morvain       │
                    └─────────────────────────┘
              Làng Bến Bùn ───┼─── Làng Đèn Lồng
                         Làng Muối Đắng
                    Dungeon: Đền Chìm Triều
                         NAM — NHIỆT ĐỚI / ĐẦM LẦY
                    Mưa bão / Rừng ngập / Độc
                         Level 7-12

  ★ = Điểm khởi đầu: người chơi trắng tay tỉnh dậy / đến Làng Tân Diệp (Đông).
  ── = Đường chính tuyến (main route). Các đường phụ, đường tắt mở theo uy tín / chìa.
  Chiều tiến triển bắt buộc về mặt cốt truyện: ĐÔNG → NAM → TÂY → BẮC → THÁP VƯƠNG ẤN
```

**Cách đọc sơ đồ:**

- Vòng ngoài là **vành đai có người sống**: làng mạc bám quanh thành, thành bám vào đường thương mại hình vòng.
- Vòng trong là **vùng đệm chết dần**: càng gần tháp, đất càng xám, cây càng ít, quái càng không giống sinh vật tự nhiên.
- Tâm là **Tháp Vương Ấn**: nhìn thấy được từ rất xa ở mọi vùng (landmark cố định trên skyline) — nhắc người chơi liên tục về đích cuối, kể cả khi đang làm quest bắt chuột ở làng khởi đầu.

### 1.3. Bảng tổng quan 5 khu vực

| # | Khu vực / Hướng | Khí hậu & Địa hình | Thành chính | Dải Level | Boss thành | Dungeon riêng | Trụ / Chìa phong ấn |
|---|---|---|---|---|---|---|---|
| 1 | **ĐÔNG** | Ôn đới, mùa xuân vĩnh cửu, rừng xanh, mưa phùn, đồng ruộng | **Thành Xuân Lâm** | **1–6** | **Golem Rêu Cổ Thụ** | **Hầm Rượu Chuột Chúa** + **Mỏ Rêu Cổ** | Trụ Mộc — Chìa Rễ Xanh |
| 2 | **NAM** | Nhiệt đới, đầm lầy ven biển, mưa bão, rừng ngập nước, độc | **Thành Triều Ẩm** | **7–12** | **Phù Thủy Đầm Lầy Morvain** | **Đền Chìm Triều** | Trụ Thủy — Chìa Triều Ngọc |
| 3 | **TÂY** | Sa mạc khô nóng, bão cát, cao nguyên đá đỏ, ngày nóng đêm lạnh | **Thành Hồng Sa** | **13–18** | **Rồng Cát Vesskar** | **Lăng Cát Chôn** | Trụ Sa — Chìa Vảy Cát |
| 4 | **BẮC** | Hàn đới, băng tuyết, bão tuyết, cực quang | **Thành Hàn Thiết** | **19–24** | **Hiệp Sĩ Đen (Hiệp Sĩ Băng)** | **Pháo Đài Băng Nứt** | Trụ Hàn — Chìa Sắt Băng |
| 5 | **TRUNG TÂM** | Đất chết / tro tàn, không khí hậu tự nhiên, tĩnh lặng bất thường | **Tháp Vương Ấn** | **25 (endgame)** | **Vua ở đỉnh tháp / Boss cuối ở đỉnh–dưới tháp** (xem Mục 3) | **Tháp Vương Ấn** — dungeon leo tháp nhiều tầng | Khóa Trung Tâm — nơi công chúa, vật phong ấn sống, đang bị neo |

### 1.4. Ba hồi cốt truyện — khung toàn cục

| Hồi | Phạm vi | Tone bề ngoài | Sự thật lộ dần | Câu hỏi người chơi tự hỏi |
|---|---|---|---|---|
| **Hồi I — Hiệp Sĩ Tập Sự** | Đông + Nam (Lv.1–12) | Cổ tích sáng: trắng tay làm quest, tăng uy tín, cứu làng, đánh boss thành | Phong ấn là có thật; mỗi thành đang trả giá để giữ nó; người dân không biết toàn bộ sự thật | "Mình đang giúp ai, và giúp bằng cách nào?" |
| **Hồi II — Vòng Ấn Nứt** | Tây + Bắc (Lv.13–24) | Phiêu lưu chuyển dark: lựa chọn có hậu quả không đảo ngược, đồng minh chết / phản bội / hóa quái, đường không giết xuất hiện | Vua không đơn thuần là ác; công chúa không chỉ là nạn nhân chờ cứu; thứ bị giam có trí tuệ và có lý lẽ | "Nếu mở phong ấn là sai, tại sao giữ nó cũng đang giết người mỗi ngày?" |
| **Hồi III — Dưới Bóng Phong Ấn** | Tháp Vương Ấn (Lv.25) | Dark fantasy / bi kịch: leo tháp là đi ngược lịch sử phong ấn, mỗi tầng là một đời người gác ấn | Toàn bộ twist (Mục 3.5, 5.4): công chúa là vật phong ấn sống; vua muốn phá phong ấn vì lý do vừa ích kỷ vừa có thể hiểu được; thứ bị giam không thuần ác | "Kết thúc nào ít tàn nhẫn nhất — và mình có quyền chọn thay cho cả vương quốc không?" |

**Lưu ý thiết kế:** Không hồi nào "lật bàn" vô lý. Mọi twist ở Hồi III phải đã có mầm ở Hồi I: một câu thoại của trưởng làng, một phiến đá trong mỏ, một đứa trẻ ở Nam nói điều người lớn không dám nói. Người chơi chơi lại lần hai phải thấy dấu hiệu ở khắp nơi.

---

## 2. CHI TIẾT TỪNG VÙNG

> Cấu trúc mỗi vùng dưới đây là cố định để dev map 1-1 sang scene / data: **Khí hậu & Palette → Thành → Làng vệ tinh → Quái & Vai trò combat → Dungeon → Lý do cốt truyện → Cái giá dark**.

---

### 2.1. ĐÔNG — Thành Xuân Lâm (Level 1–6)

#### 2.1.1. Khí hậu, địa hình, palette

| Hạng mục | Chi tiết |
|---|---|
| Khí hậu | Ôn đới, **mùa xuân vĩnh cửu** — không bao giờ thực sự sang hè hay đông. Mưa phùn 60% thời gian ban ngày, nắng dịu sau mưa. |
| Địa hình | Rừng lá rộng xanh non, đồi thấp, đồng ruộng bậc thang nhỏ, sông suối trong, đường đất lầy sau mưa. |
| Palette chính | Xanh lá non `#7FB069`, xanh rêu đậm, nâu đất ẩm, vàng lúa non, xám mưa phùn. Accent: hồng hoa đào / trắng hoa mận ở cổng thành. |
| Âm thanh / không khí | Chim hót, mưa rào nhẹ trên lá, chuông gió ở làng. Vùng an toàn nhất về cảm giác — cố ý để tương phản với các vùng sau. |
| Dấu hiệu bất thường | Cây cối **không rụng lá, hoa không tàn đúng mùa**. Người già nói "xuân ở đây dài hơn hồi ta còn trẻ" — nghe như lời khen, thực ra là triệu chứng phong ấn rò rỉ thời gian (xem 2.1.7). |

Vùng Đông là **tutorial trá hình thành thế giới sống**: mọi hệ thống của game (combat, quest uy tín, nghỉ trọ hồi máu, craft cơ bản, chọn thoại, dungeon ngắn) đều được dạy ở đây mà không cần bảng hướng dẫn dài.

#### 2.1.2. Thành Xuân Lâm

| Hạng mục | Chi tiết |
|---|---|
| Vai trò | Thủ phủ nông nghiệp của vương quốc; kho lúa nuôi cả vòng ngoài; nơi đóng **Trụ Mộc**. |
| Lãnh chúa | **Lãnh chúa Lâm Nhược** — quản lý giỏi, hiền, sợ trách nhiệm. Không ác, nhưng sẵn sàng giấu sự thật "vì dân hoảng loạn còn tệ hơn". Là hình mẫu đầu tiên của kiểu nhân vật xuyên suốt game: *người tốt giữ bí mật xấu*. |
| Kiến trúc | Tường đá phủ rêu và dây leo có hoa, tháp canh bằng gỗ cổ thụ, cổng thành kết từ cây sống uốn cong. Nhà mái ngói rêu, chợ trong sân thành quanh một **Cổ Thụ Trung Tâm** — chính là biểu hiện bề mặt của Trụ Mộc. |
| Chức năng gameplay | Hub lớn đầu tiên: chợ vũ khí/khiên gỗ–sắt cơ bản, thợ rèn nâng cấp +1/+2, nhà trọ, bảng quest uy tín cấp Thành, kho chứa đồ, NPC dạy kỹ năng nền (đỡ đòn, né, khóa mục tiêu). |
| Khu vực nội bộ | Sân Chợ Cây / Phố Thợ Rèn / Đền Nhỏ Xin Mùa / Gốc Cổ Thụ (khóa cho đến Main Quest Đông 3) / Nhà Lãnh Chúa. |
| Bí mật | Rễ của Cổ Thụ đã ăn vào nền móng thành và vào **mộ của các đời gác ấn**. Cắt rễ để cứu nhà cửa = làm yếu trụ. Để rễ mọc = nhà dân nứt dần mỗi năm. |

#### 2.1.3. Làng vệ tinh — Đông

| Làng | Vị trí tương đối | Chức năng gameplay chính | NPC / Điểm nhớ | Ghi chú thiết kế |
|---|---|---|---|---|
| **Làng Tân Diệp** ★ | Đông Nam của thành, bìa rừng, nơi người chơi bắt đầu | **Làng khởi đầu** — tutorial, nhà trọ miễn phí lần đầu, shop cùi bắp (gậy gỗ, áo vải), bảng quest vỡ lòng, điểm save đầu tiên | Trưởng làng Tân Diệp; thợ mộc già; đứa bé nhặt được "lá không bao giờ héo" | Người chơi **trắng tay thật**: không vàng, không vũ khí xịn, phải làm quest chặt củi / đuổi slime / tìm đồ mất để có thanh kiếm đầu tiên. Không cho bỏ qua. |
| **Làng Mạch Lúa** | Đồng ruộng phía Nam thành | Quest hub nông nghiệp, shop hạt giống & lương thực, craft nấu ăn (buff hồi stamina), mini-game / quest thu hoạch theo thời gian | Chủ vựa lúa; góa phụ giữ sổ nợ hạt giống | Là nơi dạy hệ thống **uy tín vùng**: giúp Mạch Lúa đủ mức mới được Làng Bến Mưa tin và mới được vào sân trong Thành Xuân Lâm. |
| **Làng Bến Mưa** | Ven sông, phía Đông thành | Bến đò / fast-travel nội vùng, shop cần câu & vật phẩm trị độc nhẹ, quest vận chuyển, nghỉ trọ rẻ | Lão chèo đò nói nhiều, biết nhiều hơn ông ta thừa nhận; thương nhân từ Nam ghé qua (foreshadow vùng Nam) | Đò của Bến Mưa là đường **nghe tin về Nam** đầu tiên. Khóa đường sang Nam bằng lũ / uy tín — xem Mục 4. |

#### 2.1.4. Quái đặc trưng — Đông

| Quái | Habitat | Vai trò combat (dạy người chơi điều gì) | Drop / Dùng cho |
|---|---|---|---|
| **Slime Cỏ** | Đồng cỏ, ruộng ẩm sau mưa | Kẻ địch đầu tiên: chậm, telegraph rõ, dạy đánh thường + né cơ bản. Sát thương rất thấp. | Gel cỏ — nấu ăn, quest vỡ lòng |
| **Goblin Rừng** | Bìa rừng, trại tạm gần đường | Địch theo bầy 2–4 con, một con cầm cung yếu. Dạy ưu tiên mục tiêu, dùng địa hình / cây để chắn tên. | Tai goblin (bounty), dao gỉ, vải |
| **Sói Rừng** | Rừng sâu, lúc chạng vạng / mưa | Địch nhanh, vồ theo cặp, dạy khóa mục tiêu khi di chuyển nhanh + quản lý stamina khi né liên tiếp. | Da sói — craft áo da đầu game |
| **Golem Rêu** (mini-elite) | Quanh Mỏ Rêu Cổ, gốc cây mục | Địch chậm, giáp rêu dày, kháng chém nhẹ, yếu lửa / rìu. Dạy đổi vũ khí / dùng vật phẩm gây lửa, đánh vào lõi lộ ra sau đòn nặng. | Lõi rêu, đá rêu — nguyên liệu nâng cấp, chìa phụ vào Mỏ Rêu Cổ |

**Nguyên tắc:** Không quái Đông nào có độc, nguyền, hay cơ chế "khó chịu". Độ khó ở đây là *đọc đòn*, không phải *chịu đựng trạng thái xấu* — để người chơi mới không nản trước khi hiểu game.

#### 2.1.5. Dungeon riêng — Đông

| Dungeon | Theme | Độ dài ước tính | Boss / Đỉnh điểm | Trick / Cơ chế riêng | Phần thưởng cốt truyện |
|---|---|---|---|---|---|
| **Hầm Rượu Chuột Chúa** | Hầm rượu dưới nhà trọ / kho lúa ở Làng Mạch Lúa, thùng vỡ, mùi men chua | Ngắn: 15–20 phút, 2 tầng nhỏ — **dungeon tutorial** | **Chuột Chúa** — chuột khổng lồ ăn lúa nhiễm rêu phong ấn, phình to bất thường | Lăn thùng để chặn đường / tạo vật chắn; ánh sáng đuốc đuổi đàn chuột nhỏ; không có bẫy giết người | Uy tín Mạch Lúa, kiếm sắt đầu tiên, manh mối đầu tiên: lúa trong hầm **không mốc dù để nhiều năm** |
| **Mỏ Rêu Cổ** | Mỏ đá bỏ hoang dưới chân Cổ Thụ, rễ cây xuyên qua đường hầm, đá phát sáng xanh nhạt | Trung bình: 30–40 phút, 3 khu vực | **Golem Rêu Cổ Thụ** (phiên bản nhỏ / phân thân rễ — **không phải** boss thành ở dạng hoàn chỉnh; xem lưu ý dưới) — hoặc mini-boss **Lõi Rễ Mỏ** nếu dev muốn tách bạch | Rễ mọc lại chặn đường sau 1 khoảng thời gian — phải đi nhanh hoặc đốt rễ tạm; puzzle ánh sáng: phản chiếu sáng qua đá rêu để mở cửa đá | Mảnh **Chìa Rễ Xanh** (mảnh 1/2), nhật ký thợ mỏ đời trước nhắc tới "trụ không được đào" |

> **Lưu ý nhất quán quan trọng cho dev:** **Golem Rêu Cổ Thụ** là **Boss thành** của Đông (Main Quest Đông 4, ở Gốc Cổ Thụ trong Thành Xuân Lâm). Mỏ Rêu Cổ chỉ chứa một **phân thân rễ / lõi rễ** của nó. Không đặt boss thành hoàn chỉnh ở hai nơi. Khi phân thân ở mỏ bị đánh bại, boss thành ở hồi cuối vùng sẽ **yếu hơn / lộ lõi sớm hơn** — đây là phần thưởng cho người chơi chịu khám phá, không phải điều kiện bắt buộc.

#### 2.1.6. Lý do cốt truyện phải đến Đông

Người chơi không "được chọn" bắt đầu ở Đông vì Đông dễ — mà vì **đó là nơi duy nhất còn nhận người lạ không giấy tờ**. Nhân vật chính đến Làng Tân Diệp với hai bàn tay trắng (mất trí nhớ một phần / thân phận mơ hồ — giữ mơ hồ theo GDD v1, không chốt cứng ở tài liệu này), phải sống như một người làm thuê bình thường trước khi là "hiệp sĩ". Đông dạy một chân lý của game: **uy tín không mua được, phải làm từng việc nhỏ mà tích**.

Về mặt phong ấn: Cổ Thụ ở Thành Xuân Lâm đang **mọc nhanh bất thường và bắt đầu nuốt nhà dân, nuốt mộ, nuốt đường**. Lãnh chúa Lâm Nhược cầu cứu khắp nơi không ai tới (các vùng khác cũng đang có biến). Người chơi, từ kẻ vô danh ở Tân Diệp, là người duy nhất leo dần lên thang uy tín đủ để được cho vào Gốc Cổ Thụ.

#### 2.1.7. Cái giá dark riêng của Đông — "Mùa xuân không cho ai già đi, cũng không cho ai được chôn yên"

Bề ngoài Đông là vùng ít dark nhất. Cái giá của nó nằm ở **thời gian và cái chết bị kẹt lại**:

- Nhờ rò rỉ từ Trụ Mộc, cây không tàn, lúa không mốc — nhưng **người chết ở gần Cổ Thụ cũng không phân hủy đúng cách**. Nghĩa trang sau thành có những ngôi mộ mà cỏ không mọc *vì rễ Cổ Thụ đang giữ thứ ở dưới*.
- Thợ mỏ đời trước trong Mỏ Rêu Cổ không chết vì sập mỏ. Nhật ký của họ cho thấy họ **ngừng già đi trong mỏ**, làm việc nhiều năm, rồi khi bước ra ánh sáng thì cơ thể "trả nợ thời gian" cùng lúc. Lãnh chúa các đời biết chuyện này và **niêm phong mỏ bằng lý do an toàn lao động**.
- Lựa chọn cuối vùng (xem Quest Đông 4): làm yếu Cổ Thụ để cứu khu dân cư đang bị rễ nuốt **ngay bây giờ**, hay giữ nguyên trụ và di dời dân **mất nhà, mất mộ tổ**. Không có lựa chọn nào mà "mùa xuân vĩnh cửu" còn nguyên vẹn. Từ đây game hết là cổ tích thuần.

---

### 2.2. NAM — Thành Triều Ẩm (Level 7–12)

#### 2.2.1. Khí hậu, địa hình, palette

| Hạng mục | Chi tiết |
|---|---|
| Khí hậu | Nhiệt đới ẩm, **mưa bão theo triều**, độ ẩm cao thường trực. Mưa không nhẹ như Đông — mưa xối, gió giật, nước dâng nhanh. |
| Địa hình | Đầm lầy ven biển, rừng ngập nước (rễ cây ngập nửa thân), bãi bùn, kênh rạch chằng chịt, làng nổi / nhà sàn. |
| Palette chính | Xanh lục đậm u ám, nâu bùn, xám bão, teal nước đầm. Accent: vàng đèn lồng, cam lửa trại — nguồn sáng ấm duy nhất giữa vùng lạnh ẩm. |
| Âm thanh / không khí | Mưa trên lá to, ếch nhái, tiếng nước rút / dâng, chuông cảnh báo triều ở bến. |
| Dấu hiệu bất thường | **Thủy triều không còn khớp với mặt trăng.** Nước dâng vào giờ lẽ ra phải rút. Cá chết nổi theo hình vòng tròn quanh Đền Chìm Triều. |

Nam là bước nhảy độ khó đầu tiên: thêm **độc, địa hình làm chậm, tầm nhìn kém khi bão**, và kẻ địch dùng trạng thái xấu. Người chơi rời vùng tutorial thực sự ở đây.

#### 2.2.2. Thành Triều Ẩm

| Hạng mục | Chi tiết |
|---|---|
| Vai trò | Cảng / thành đầm lầy duy nhất của vương quốc; kiểm soát muối, cá, thuốc từ đầm; nơi đóng **Trụ Thủy**. |
| Lãnh chúa | **Phù Thủy Đầm Lầy Morvain — đồng thời là lãnh chúa trên thực tế và là Boss thành.** Morvain từng là y sư / người giữ đền được dân tôn kính, nay bị đầm "gọi" và đang dùng dân làm vật thử cho nghi lễ giữ triều. Dân vừa sợ vừa không dám bỏ bà ta, vì chỉ Morvain biết cách đọc triều lạ. Đây là boss người đầu tiên — có lý lẽ, có đối thoại dài trước khi đánh. |
| Kiến trúc | Thành xây trên cọc và nền đá giữa đầm, tường thấp chống ngập thay vì chống công thành, mái dốc thoát nước, kênh đào xuyên thành như phố nước. Đèn lồng treo quanh năm để xua muỗi và "thứ trong sương". |
| Chức năng gameplay | Hub cấp 2: shop thuốc giải độc / kháng độc, thợ rèn vũ khí kháng rỉ, nhà trọ nhà sàn, bảng quest uy tín cấp cao hơn, NPC dạy **quản lý trạng thái xấu** (độc, làm chậm, ướt → yếu điện/lửa thay đổi). |
| Khu vực nội bộ | Bến Triều / Phố Thuốc / Khu Nhà Sàn Quan Lại (bỏ trống — quan bỏ chạy) / Đền Triều Nhỏ / Cống Ngập (đường bí mật). |
| Bí mật | Thành không giữ Trụ Thủy bằng đá hay cây — trụ là **chu kỳ triều nhân tạo** do các đời người giữ đền duy trì bằng nghi lễ. Ngừng nghi lễ 1 ngày = thành ngập. Morvain không tạo ra hệ thống này; bà ta là **nạn nhân kiêm cai ngục** của nó. |

#### 2.2.3. Làng vệ tinh — Nam

| Làng | Vị trí tương đối | Chức năng gameplay chính | NPC / Điểm nhớ | Ghi chú thiết kế |
|---|---|---|---|---|
| **Làng Bến Bùn** | Cửa ngõ từ Đông vào Nam, bãi bùn ven đường | Điểm nghỉ đầu tiên ở Nam, shop cơ bản, quest làm quen địa hình đầm (đi chậm trong bùn, tránh vũng độc), điểm save | Trưởng bến; trẻ con bán "bùa bùn" không có tác dụng — nhưng tin là có | Cổng mềm (soft gate): người chơi thiếu thuốc giải độc sẽ rất khổ ở đây — làng dạy bằng trải nghiệm, không bằng bảng cấm. |
| **Làng Đèn Lồng** | Giữa đầm, làng nổi trên bè và nhà sàn nối bằng cầu tre | **Quest hub chính của Nam**, chợ đêm bằng đèn lồng, craft thuốc / độc, nhà trọ an toàn giữa đầm, điểm fast-travel nội vùng | Hội thắp đèn — những người gác đèn không bao giờ để đèn tắt; góa phụ chèo thuyền đưa thư | Đèn ở đây không phải trang trí: **đèn tắt ở khu nào, quái đầm vào khu đó trong đêm đó**. Quest giữ đèn là quest phòng thủ lặp lại được (repeatable). |
| **Làng Muối Đắng** | Ven biển, cuối vùng Nam, ruộng muối | Shop muối & vật phẩm kháng độc cao cấp, quest thương mại, bến thuyền nghe tin về Tây (đường vòng qua biển / đoàn thương nhân sa mạc), nghỉ hồi phục đầy đủ | Diêm dân già mù do muối; thương nhân sa mạc lạc đường (foreshadow Tây) | Tên "Muối Đắng" là chủ ý: muối ở đây bắt đầu có vị đắng vì nước biển nhiễm từ phong ấn — chi tiết nhỏ, NPC phàn nàn như chuyện làm ăn, không ai nối nó với tháp. |

#### 2.2.4. Quái đặc trưng — Nam

| Quái | Habitat | Vai trò combat | Drop / Dùng cho |
|---|---|---|---|
| **Quái Bùn** | Bãi bùn, kênh cạn | Địch trâu, chậm, kháng chém, khi chết vỡ thành 2 bùn nhỏ. Dạy AoE / lửa / quản lý vị trí trên địa hình trơn. | Bùn thuốc, lõi bùn |
| **Rắn Đầm** | Bụi rậm ngập nước, dưới cầu tre | Địch phục kích, cắn gây **độc** — lần đầu người chơi phải dùng giải độc giữa combat. Telegraph: tiếng rít + gợn nước. | Nọc rắn (craft độc / giải độc), da rắn |
| **Quái Độc** (Bóng Độc Đầm) | Vũng độc, quanh Đền Chìm Triều | Địch tầm trung, phun mây độc, ép người chơi di chuyển liên tục, không đứng yên DPS. | Tuyến độc, thảo độc |
| **Phù Thủy Tập Sự** | Trại quanh đền, nhà bỏ hoang trong đầm | Địch người đầu tiên dùng phép: bắn đạn nước / độc từ xa, bỏ chạy khi bị áp sát, có thể **đầu hàng** ở một số encounter (mở thoại / tha mạng). Dạy áp sát caster + lựa chọn tha / giết có hậu quả uy tín. | Bùa giấy ướt, gậy tập sự, thông tin về Morvain nếu tha |

#### 2.2.5. Dungeon riêng — Nam

| Dungeon | Theme | Độ dài | Boss / Đỉnh điểm | Trick / Cơ chế riêng | Phần thưởng cốt truyện |
|---|---|---|---|---|---|
| **Đền Chìm Triều** | Đền đá chìm nửa dưới nước trong đầm, rêu trơn, tượng thần mặt bị mài nhẵn | Trung bình–dài: 45–60 phút, mực nước thay đổi theo thời gian thực / theo cần gạt | **Morvain — Giai đoạn 1** (đối thoại + đánh thăm dò trong đền) — boss hoàn chỉnh ở Thành Triều Ẩm, Main Quest Nam 4. Trong đền, Morvain rút lui sau khi làm ngập phòng boss phụ. | **Puzzle triều:** gạt cần / đợi chu kỳ để nước dâng–rút mở đường khác nhau; phòng đi được lúc nước rút sẽ ngập lúc nước dâng (có cảnh báo chuông). Đèn dầu mang theo xua sương độc — dầu cạn dần, phải tìm trạm châm dầu. | **Chìa Triều Ngọc** (dạng thô, cần tinh luyện ở thành), sự thật: các đời người giữ đền **chết đuối theo nghi lễ** để "làm mới" trụ — tên họ khắc dưới mực nước, chỉ đọc được lúc triều rút sâu nhất. |

#### 2.2.6. Lý do cốt truyện phải đến Nam

Sau biến cố Cổ Thụ ở Đông, tin đồn "triều điên" ở Nam không còn là chuyện xa: nước đầm Đông–Nam bắt đầu chảy ngược, cá chết trôi về Bến Mưa. Lãnh chúa Lâm Nhược (hoặc Hội Đèn ở Làng Đèn Lồng, tùy lựa chọn của người chơi ở Đông) nhờ / thuê người chơi xuống Nam vì **đội triều quan của vua đã bỏ Nam từ lâu**. Về gameplay: đây là lúc game mở **vòng quest liên vùng** — hành động ở Đông (giúp / không giúp Bến Mưa) ảnh hưởng ai sẽ đón người chơi ở Bến Bùn.

Sâu hơn: Morvain gửi một lá thư ướt không ký tên về Đông — *"Trụ của các người đã nứt thì trụ của ta cũng không giữ được bao lâu. Tới mà xem cái giá, nếu dám."* Đó là lời mời, không phải lời tuyên chiến.

#### 2.2.7. Cái giá dark riêng của Nam — "Mỗi mùa triều yên là một người không trở về"

- Trụ Thủy không tự vận hành. Theo nghi lễ cũ, mỗi thế hệ cần một **Người Giữ Triều** ở lại trong Đền Chìm Triều khi nước dâng cao nhất và **không trở ra**. Dân gọi đó là "được triều chọn". Morvain là Người Giữ Triều **sống sót duy nhất** — bà ta thoát ra, và từ đó triều mới điên. Bà ta vừa là người phá nghi lễ, vừa là bằng chứng nghi lễ đó là giết người có hệ thống.
- Morvain dùng phù thủy tập sự và dân bệnh làm vật thử không phải (chỉ) vì ác — bà ta đang tìm cách **thay nghi lễ chết người bằng một thứ khác**, và thí nghiệm của bà ta cũng giết người, chỉ chậm hơn và có vẻ "khoa học" hơn.
- Lựa chọn cuối vùng (Quest Nam 4): khôi phục nghi lễ cũ (cần một người giữ triều mới — ai sẽ là người đó?), ủng hộ cách của Morvain (đánh cược cả thành vào thí nghiệm chưa xong), hay phá vỡ chu kỳ triều (thành mất nguồn nước / ngập vĩnh viễn nhưng không ai phải chết theo nghi lễ nữa). Mọi lựa chọn đều có người chết hoặc mất nhà — khác nhau ở **ai chết và ai được quyết định**.

---

### 2.3. TÂY — Thành Hồng Sa (Level 13–18)

#### 2.3.1. Khí hậu, địa hình, palette

| Hạng mục | Chi tiết |
|---|---|
| Khí hậu | Sa mạc khô nóng, **ngày nóng cực đoan, đêm lạnh buốt**, bão cát bất chợt làm mất tầm nhìn và đổi địa hình tạm thời (cồn cát dịch chuyển chặn / mở đường). |
| Địa hình | Biển cát, cao nguyên đá đỏ, hẻm núi khô, ốc đảo thưa, di tích chôn nửa trong cát. |
| Palette chính | Đỏ đá `#C1440E` / cam cháy, vàng cát, nâu da, trắng muối ốc đảo. Đêm: xanh lạnh sâu, tím hoàng hôn sa mạc. Accent: turquoise (ngọc sa mạc) ở chợ đêm. |
| Âm thanh / không khí | Gió rít qua đá, im lặng khô ban trưa, tiếng chuông lạc đà và chợ ồn ào ban đêm (người Tây sống về đêm). |
| Dấu hiệu bất thường | Cát **nóng lên từ bên dưới**, không chỉ do mặt trời. Đêm lạnh nhưng cát dưới sâu vẫn ấm như có thứ gì đang thở dưới lòng đất. |

Tây là vùng **sinh tồn và đàm phán**: quản lý nước / nhiệt ban ngày, lạnh ban đêm, bão cát như sự kiện thời tiết có gameplay, và lần đầu tiên một boss thành có **đường không giết** thực sự ngang giá trị với đường giết.

#### 2.3.2. Thành Hồng Sa

| Hạng mục | Chi tiết |
|---|---|
| Vai trò | Thành thương mại sa mạc, kiểm soát đường caravan duy nhất nối vòng ngoài phía Tây; nơi đóng **Trụ Sa**. |
| Lãnh chúa | **Thống Lĩnh Caravan Sa Mạc — bà chúa chợ đêm** (họ tên giữ ở GDD nhân vật; ở tài liệu này gọi theo chức danh để tránh mâu thuẫn): thực dụng, coi mọi thứ đều có giá, kể cả lòng trung thành — nhưng giữ chữ tín tuyệt đối khi đã ra giá. Là lãnh chúa "không tốt không xấu" rõ nhất game. |
| Kiến trúc | Tường đá đỏ dày giữ nhiệt, phố có mái che, chợ trong hang đá mát, tháp nước ngầm, cổng thành hình hàm rồng (hàm của Vesskar theo truyền thuyết — thực ra là xương rồng cổ đại). Nhà chìm nửa dưới cát để tránh nóng. |
| Chức năng gameplay | Hub cấp 3: shop vũ khí cao cấp / kháng nhiệt–lạnh, thợ rèn **đá đỏ** (vũ khí có rãnh nguyên tố), nhà trọ + kho nước, bảng quest caravan (hộ tống, săn bounty sa mạc), NPC dạy **đàm phán / hối lộ / uy tín phe phái**. |
| Khu vực nội bộ | Chợ Đêm Lớn / Khu Caravan / Tháp Nước Ngầm / Cổng Hàm Rồng / Hang Mát Quan Lại. |
| Bí mật | Thành không xây *bên cạnh* Trụ Sa — thành xây **trên lưng / quanh xác canh giữ của Trụ Sa**: Rồng Cát Vesskar ngủ / tuần tra dưới nền cát quanh thành, và chính hơi thở / di chuyển của nó tạo ra chu kỳ bão cát giữ cát phong ấn không tràn vào vùng sống. Giết Vesskar = bỏ người gác cổng tận tụy nhất của vương quốc. |

#### 2.3.3. Làng vệ tinh — Tây

| Làng | Vị trí tương đối | Chức năng gameplay chính | NPC / Điểm nhớ | Ghi chú thiết kế |
|---|---|---|---|---|
| **Làng Giếng Cạn** | Cửa ngõ từ Nam / đường caravan vào Tây | Điểm nghỉ sinh tồn đầu tiên, shop nước & đồ chống nóng, quest dạy quản lý nước / nhiệt, điểm save | Giữ giếng già; đứa trẻ vẽ hình rồng trên cát mỗi ngày rồi xóa | Giếng ở đây **cạn theo chu kỳ hơi thở của Vesskar** — dân biết, coi như thời tiết. Foreshadow đường không giết. |
| **Làng Chợ Đêm** | Ốc đảo nhỏ giữa sa mạc | **Quest hub thương mại của Tây**, chợ đêm (chỉ mở ban đêm — dạy chu kỳ ngày/đêm), craft / đổi hàng hiếm, thông tin / tin đồn có giá | Thương nhân mù nghe giá bằng tai; kẻ bán "bản đồ lăng thật" (nửa thật) | Nhiều quest ở đây không có marker rõ: phải hỏi, trả giá, nghe ngóng. Dạy người chơi game không phải lúc nào cũng chỉ đường tận nơi. |
| **Làng Ốc Đảo Cát Trắng** | Ốc đảo lớn phía Bắc Tây, gần Lăng Cát Chôn | Trạm nghỉ trước dungeon, shop hồi phục cao cấp, quest ốc đảo / chữa bệnh cát phổi, điểm fast-travel nội vùng | Y sư ốc đảo; gia tộc giữ ốc đảo qua 7 đời không ai rời đi được quá 3 ngày | Ốc đảo **không cạn bao giờ** dù không có nguồn nước bề mặt — vì nó nằm ngay trên một mạch của phong ấn. Nếu phong ấn vỡ, ốc đảo là nơi đầu tiên mất nước. Dân ở đây vì thế sợ thay đổi nhất vương quốc. |

#### 2.3.4. Quái đặc trưng — Tây

| Quái | Habitat | Vai trò combat | Drop / Dùng cho |
|---|---|---|---|
| **Bọ Cát** | Dưới cát, quanh xác caravan | Địch ẩn dưới cát, trồi lên theo bầy khi người chơi đứng yên / chạy thẳng quá lâu. Dạy di chuyển liên tục + nghe âm thanh báo hiệu (cát sủi). | Vỏ bọ (giáp nhẹ kháng nhiệt), ngòi cát |
| **Chiến Binh Sa Mạc** (kẻ cướp / lính đánh thuê lạc phe) | Hẻm đá, đường caravan | Địch người có kỷ luật: dùng khiên, phối hợp 2–3 người, có thể **thương lượng / đầu hàng / được thuê lại** ở một số encounter. Dạy đánh với địch có block + parry đơn giản. | Xu caravan, vũ khí đá đỏ cấp thấp, thư / bản đồ |
| **Golem Đá Đỏ** | Cao nguyên đá, cửa Lăng Cát Chôn | Elite chậm, giáp cực dày, điểm yếu là khe đá phát sáng khi quá nhiệt. Dạy dùng môi trường: dụ vào bóng râm / nước ốc đảo để làm nứt giáp, hoặc dùng vũ khí blunt. | Lõi đá đỏ, mảnh giáp |
| **Rồng Cát Con** | Tổ cát quanh Thành Hồng Sa | Địch bay thấp / đào cát, phun cát làm mù tạm thời. **Đánh chúng làm giảm điểm đàm phán với Vesskar** — game ghi lại, NPC nhắc. Dạy hệ quả sinh thái của việc farm quái vô tội vạ. | Vảy cát con (giá trị cao — cám dỗ cố ý), cánh cát |

#### 2.3.5. Dungeon riêng — Tây

| Dungeon | Theme | Độ dài | Boss / Đỉnh điểm | Trick / Cơ chế riêng | Phần thưởng cốt truyện |
|---|---|---|---|---|---|
| **Lăng Cát Chôn** | Lăng mộ / kho ấn chôn dưới cát của các đời vua trước, phòng bị cát tràn theo thời gian, bẫy cát sụt và cửa đá nặng | Dài: 60–75 phút, nhiều nhánh, một số phòng chỉ vào được khi bão cát bên ngoài dâng (cát ép mở / đóng đường) | Mini-boss: **Người Gác Lăng Không Tên** — hiệp sĩ đã chết nhưng ấn trong lăng vẫn bắt ông ta gác; có thể được **giải thoát bằng đối thoại / trả lại tên** thay vì chỉ đánh | Cát chảy như đồng hồ cát khổng lồ: ở lâu trong một khu, cát dâng chặn đường về — phải tiến lên hoặc tìm lỗ thông cát. Mang theo nước nặng người nhưng cần để qua phòng nhiệt. Đánh đổi inventory có chủ ý. | **Chìa Vảy Cát** (nếu đi đường lăng) *hoặc* bằng chứng để đàm phán với Vesskar (tên thật của người gác lăng / sự thật vua đời trước đã hứa gì với rồng). Hai đường lấy chìa ở Tây là **loại trừ một phần**: xem Quest Tây 3–4. |

#### 2.3.6. Lý do cốt truyện phải đến Tây

Hai lý do chồng nhau:

1. **Đường vòng bắt buộc:** Sau biến cố Nam, đường thẳng về phía Bắc qua trung tâm bị đất chết lan rộng cắt đứt. Caravan Tây là đường bộ duy nhất còn đi được lên Bắc — và caravan chỉ đi khi Thành Hồng Sa cấp phép + có người giải quyết chuyện "rồng chặn cổng".
2. **Tin về vua:** Thương nhân ở Làng Muối Đắng và Chợ Đêm đều kể cùng một chuyện: *đoàn người của vua đã đi qua Tây nhiều năm trước, vào Lăng Cát Chôn, và mang ra một thứ khiến Vesskar gầm suốt 3 đêm.* Người chơi đến Tây để tìm chìa, nhưng ở lại vì câu hỏi: vua đã lấy gì khỏi phong ấn trước cả khi người chơi bắt đầu?

#### 2.3.7. Cái giá dark riêng của Tây — "Người gác cổng bị đối xử như quái vật vì nó không nói được tiếng người"

- **Vesskar không phải quái vật hoành hành.** Nó là **linh thú canh ấn bị vua đời trước trói bằng lời thề**: canh cổng Tây, không cho ai vào Lăng Cát Chôn, đổi lại ốc đảo và giếng nước cho dân sa mạc. Nhiều thế hệ sau, người ta quên lời thề, chỉ còn nhớ "rồng chặn đường, giết rồng mở đường".
- Cái giá của Trụ Sa vì thế là **một sinh vật có trí tuệ bị giam trong vai quái vật hàng trăm năm**, và dân sa mạc — những người hưởng lợi từ nước của nó mỗi ngày — là những người đòi giết nó to tiếng nhất khi caravan bị chậm.
- Đường không giết (GDD v1 — bắt buộc giữ): đàm phán / thực hiện lại lời thề / trả lại thứ vua đã lấy khỏi lăng. Đường này **khó hơn, dài hơn, cần uy tín Tây cao + bằng chứng từ Lăng Cát Chôn**, nhưng cho kết quả tốt nhất về lâu dài (Vesskar còn sống = bão cát có kiểm soát, caravan an toàn về sau, đồng minh ở endgame).
- Đường giết: nhanh, được thưởng lớn (vảy, danh tiếng "diệt rồng"), nhưng **bão cát mất kiểm soát vĩnh viễn ở Tây** — một số làng / đường tắt đóng lại, NPC chết ngoài màn hình, và ở Hồi III người chơi sẽ thiếu đi một đồng minh. Game không cấm đường này; game **ghi sổ** nó.

---

### 2.4. BẮC — Thành Hàn Thiết (Level 19–24)

#### 2.4.1. Khí hậu, địa hình, palette

| Hạng mục | Chi tiết |
|---|---|
| Khí hậu | Hàn đới, **bão tuyết, gió cắt da, đêm dài**, cực quang xuất hiện vào đêm quang đãng — đẹp và là điềm theo dân Bắc. |
| Địa hình | Đồng tuyết, rừng thông băng, hồ đóng băng, đèo gió rít, pháo đài / tường băng đá. |
| Palette chính | Trắng tuyết, xám thép, xanh băng sâu `#A8DADC` / `#457B9D`, đen thông. Accent: cam lửa lò sưởi, xanh–tím cực quang. |
| Âm thanh / không khí | Gió hú, tuyết lạo xạo, tiếng băng nứt xa, im lặng sau bão. Ít nhạc nhất trong các vùng — cố ý gây cảm giác tận cùng thế giới. |
| Dấu hiệu bất thường | **Cực quang xuất hiện cả ban ngày** khi phong ấn yếu; người chết trong bão tuyết **không nằm yên** — đó là nguồn gốc của wight. Băng ở Pháo Đài Băng Nứt nứt theo hình **giống hệt vết nứt trên tháp** khi nhìn từ xa. |

Bắc là vùng **khắc nghiệt và đạo đức xám nhất trước endgame**: kẻ địch mạnh nhất vòng ngoài, cơ chế lạnh / bão tuyết, và một boss thành là tấm gương méo mó của chính nhân vật chính.

#### 2.4.2. Thành Hàn Thiết

| Hạng mục | Chi tiết |
|---|---|
| Vai trò | Thành quân sự / pháo đài biên giới phía Bắc; xưởng rèn thép băng và là nơi đóng **Trụ Hàn**; tuyến phòng thủ cuối cùng trước đất chết nếu nhìn từ phía Bắc. |
| Lãnh chúa | Chức danh lãnh chúa để trống trên danh nghĩa — người cai trị thực tế là **Hiệp Sĩ Đen (Hiệp Sĩ Băng)**, chỉ huy đội hiệp sĩ băng giữ thành bằng kỷ luật sắt. Ông ta từng là **người gác ấn đời trước / hiệp sĩ của vua** được cử lên Bắc và không bao giờ được gọi về. Dân Bắc vừa được ông ta bảo vệ khỏi wight mỗi đêm, vừa bị ông ta trưng thu người cho đội gác băng. |
| Kiến trúc | Tường đá đen + băng gia cố, lò rèn khổng lồ cháy ngày đêm ở trung tâm thành (vừa sưởi vừa rèn), cổng sắt nặng phải nhiều người kéo, nhà thấp mái dày chống tuyết. Đẹp theo kiểu khắc khổ, không trang trí thừa. |
| Chức năng gameplay | Hub cấp 4 / hub cuối trước tháp: shop vũ khí & giáp **tốt nhất vòng ngoài**, thợ rèn master (nâng cấp tối đa trước endgame), nhà trọ lò sưởi (buff kháng lạnh), bảng quest quân sự / săn wight, NPC dạy **combat nâng cao** (parry, phá thế, đánh boss người). |
| Khu vực nội bộ | Lò Lớn Trung Tâm / Doanh Trại Hiệp Sĩ Băng / Kho Thép / Tường Bắc (ca gác đêm — quest phòng thủ) / Nhà Nguyện Không Chuông. |
| Bí mật | Trụ Hàn không nằm *trong* thành — trụ là **đội gác băng tự nó**: mỗi đời, một số hiệp sĩ được "đóng băng vào ấn" — đứng gác ở Pháo Đài Băng Nứt và **dần hóa thành hiệp sĩ băng / wight có kỷ luật**. Thành Hàn Thiết tồn tại để **cung cấp người** cho trụ. Đó là bí mật quân sự lâu đời nhất vương quốc. |

#### 2.4.3. Làng vệ tinh — Bắc

| Làng | Vị trí tương đối | Chức năng gameplay chính | NPC / Điểm nhớ | Ghi chú thiết kế |
|---|---|---|---|---|
| **Làng Lò Sưởi** | Cửa ngõ phía Nam của vùng Bắc, thung lũng tránh gió | Điểm nghỉ ấm đầu tiên, shop đồ kháng lạnh, quest làm quen cơ chế lạnh / bão tuyết, điểm save | Chủ lò sưởi lớn của làng — lò này **không được tắt**, cả làng góp củi; bà góa giữ danh sách người đi gác băng không về | Lò sưởi làng là bản nhỏ của Lò Lớn ở thành: motif "giữ lửa = giữ người sống" lặp lại, càng về sau càng tốn người để giữ. |
| **Làng Săn Tuyết** | Rừng thông băng phía Đông Bắc | Quest hub săn bắn, shop cung / bẫy / giáp da tuyết, craft kháng lạnh, quest săn elite tuyết | Thợ săn đầu đàn; đứa trẻ muốn đi săn để **không bị chọn đi gác băng** | Là nơi người chơi nghe rõ nhất tiếng nói phản đối Trụ Hàn: săn quái để sống còn dễ chấp nhận hơn bị chọn đi đóng băng vì một phong ấn không ai giải thích. |
| **Làng Cực Quang** | Cao nguyên phía Bắc, nơi ngắm cực quang rõ nhất | Làng cuối trước Pháo Đài Băng Nứt, nghỉ hồi phục đầy đủ, shop cao cấp nhỏ, quest tâm linh / điềm báo, điểm fast-travel nội vùng cuối | Người xem sao / thầy điềm của làng; những người già **nhớ vua khi còn trẻ** (lore trực tiếp về vua) | Cực quang ở đây **hiện chữ / hình** khi phong ấn nứt mạnh — không giải thích rõ là thật hay ảo giác tập thể. Dùng tiết chế, 2–3 lần trong game. |

#### 2.4.4. Quái đặc trưng — Bắc

| Quái | Habitat | Vai trò combat | Drop / Dùng cho |
|---|---|---|---|
| **Sói Tuyết** | Đồng tuyết, bìa rừng thông | Phiên bản tàn nhẫn của Sói Rừng (Đông): nhanh hơn, vồ theo bầy 3–5, tấn công lúc bão tuyết tầm nhìn kém. Cho thấy game "quay lại bài cũ ở mức khó hơn". | Da tuyết, nanh băng |
| **Quái Băng** (Mảnh Băng Sống) | Hồ băng nứt, quanh pháo đài | Địch nguyên tố thuần: kháng băng tuyệt đối, yếu lửa / blunt, khi chết vỡ gây sát thương băng diện nhỏ. Dạy chuẩn bị kháng nguyên tố trước dungeon. | Mảnh băng lõi, tinh thể lạnh |
| **Hiệp Sĩ Băng** | Đường lên pháo đài, tường thành ban đêm | Địch người–quái lai: block, parry, đòn băng tầm gần, kỷ luật đội hình. Là **dân Bắc bị ấn đóng băng nửa chừng** — một số còn nói được vài từ lúc đánh. Yếu tố gây khó chịu đạo đức có chủ ý: farm chúng = farm người. | Thép băng, mảnh ấn nứt |
| **Wight** | Nghĩa địa bão tuyết, làng bỏ hoang | Địch undead mạnh: trâu, không sợ, tấn công không telegraph rõ như quái sống, chỉ xuất hiện nhiều vào đêm / bão. Dạy quản lý ánh sáng / lửa và rút lui chiến thuật. | Tro lạnh, vật dụng của người chết (bán được — và có NPC từ chối mua) |

#### 2.4.5. Dungeon riêng — Bắc

| Dungeon | Theme | Độ dài | Boss / Đỉnh điểm | Trick / Cơ chế riêng | Phần thưởng cốt truyện |
|---|---|---|---|---|---|
| **Pháo Đài Băng Nứt** | Pháo đài cổ bị băng nuốt, hành lang đầy hiệp sĩ đóng băng đứng gác trong tư thế canh, vết nứt băng phát sáng chạy trên tường như mạch máu | Dài nhất vòng ngoài: 75–90 phút, nhiều tầng, ca gác thay đổi theo thời gian trong dungeon | Mini-boss: **Đội Trưởng Gác Băng Đầu Tiên** — hiệp sĩ bị đóng băng lâu nhất, còn giữ được tên và nói chuyện được trong lúc đánh; là bản xem trước của Hiệp Sĩ Đen | **Lạnh tích lũy:** ở lâu ngoài khu có lửa, nhân vật bị lạnh dần (chậm, mất máu) — phải di chuyển giữa các điểm lửa như "checkpoint ấm". Băng nứt dưới chân ở một số phòng: đứng yên quá lâu = rơi xuống tầng dưới (không chết, nhưng lạc đường). Một số hiệp sĩ đóng băng **có thể được thaw / giải thoát** bằng vật phẩm hiếm — tốn tài nguyên, không cho loot, chỉ cho thông tin + giảm số địch ở phòng boss thành. | **Chìa Sắt Băng**, sự thật đầy đủ về Trụ Hàn (đội gác người), và danh sách tên các đời gác ấn — trong đó có **tên của Hiệp Sĩ Đen khi còn là người**, dùng được trong đối thoại boss thành. |

#### 2.4.6. Lý do cốt truyện phải đến Bắc

- **Chìa cuối cùng:** Không có Chìa Sắt Băng, cổng Tháp Vương Ấn không mở — dù người chơi có mạnh đến đâu (hard gate, xem Mục 4).
- **Quân của vua đã rút khỏi Bắc:** Hiệp Sĩ Đen giữ thành nhưng không còn nhận lệnh từ tháp từ nhiều năm. Người chơi đến Bắc mang theo tin / bằng chứng từ Tây (vua đã vào lăng, vua đang chuẩn bị phá ấn) và buộc Bắc phải chọn: tiếp tục gác một phong ấn mà vua sắp tự phá, hay mở cổng cho người chơi vào tháp trước khi vua ra tay.
- Về gameplay: Bắc là **bài kiểm tra tốt nghiệp** của vòng ngoài — mọi cơ chế đã học (trạng thái xấu, đàm phán, sinh tồn, dungeon dài, boss người) đều xuất hiện ở mức cao nhất trước endgame.

#### 2.4.7. Cái giá dark riêng của Bắc — "Trụ này không làm bằng đá. Nó làm bằng người, từng đời một."

- Trụ Hàn là vùng mà cái giá phong ấn **khó chối cãi nhất**: không phải truyền thuyết, không phải nghi lễ mù mờ — là danh sách tên, sổ trưng thu, và những hiệp sĩ đóng băng còn nói được.
- **Hiệp Sĩ Đen (Hiệp Sĩ Băng)** không tham nhũng, không điên loạn theo kiểu phản diện thường. Ông ta **thực thi đến cùng một mệnh lệnh đã hết ý nghĩa**, vì nếu thừa nhận mệnh lệnh đó là sai, toàn bộ những người đã đóng băng dưới quyền ông ta sẽ chết vô nghĩa. Đánh ông ta là đánh một người đang bảo vệ ý nghĩa cho cái chết của thuộc cấp.
- Lựa chọn cuối vùng (Quest Bắc 4): phá Trụ Hàn (giải thoát đội gác hiện tại, nhưng wight và quái băng tràn xuống không còn ai chặn), thay ca gác bằng một thỏa thuận mới (cần uy tín Bắc tối đa + điều kiện từ các vùng trước — lựa chọn khó nhất, kết quả tốt nhất một cách không trọn vẹn), hoặc để nguyên trụ và chỉ lấy chìa (đi tiếp lên tháp, để Bắc tiếp tục trả giá — lựa chọn "thực dụng" mà game sẽ nhắc lại ở ending).

---

## 3. THÁP VƯƠNG ẤN — TRUNG TÂM & ENDGAME (Level 25)

### 3.1. Vùng đất chết xung quanh tháp

| Hạng mục | Chi tiết |
|---|---|
| Địa hình | Đồng tro xám phẳng lặng, cây chết cháy đen giữ nguyên tư thế, tàn tích làng / trạm gác bỏ hoang của các đời vua, sông khô cạn đáy nứt. Không mưa, không tuyết, không gió đúng nghĩa — chỉ có **tro bay ngang** như có ai đang thở rất chậm. |
| Palette | Xám tro, đen cháy, trắng xương, đỏ thẫm âm ỉ ở các khe nứt. Màu bão hòa gần như bằng 0 — tháp và nhân vật là thứ có màu nhất trong khung hình. |
| Khí hậu | **Không khí hậu tự nhiên.** Ban ngày xám như ban đêm. Nhiệt độ trung tính một cách sai trái. Đây là nơi phong ấn đã "ăn" thời tiết. |
| Quái | Không quái tự nhiên. Chỉ có **Bóng Ấn** — hình người / thú méo mó sinh ra từ ký ức của phong ấn (dùng lại model quái các vùng ở dạng xám tro, như game đang nhớ lại). Xuất hiện thưa, mạnh, không farm được gì đáng giá — cố ý để người chơi không grind ở endgame. |
| Chức năng gameplay | Vùng đệm / hành lang cuối: 1 điểm save duy nhất ở Trạm Gác Tro, không shop (shop cuối là ở Thành Hàn Thiết), không NPC thân thiện ngoài 1–2 nhân vật theo người chơi lên tháp tùy lựa chọn các vùng trước. Đây là điểm **point of no return được báo rõ**: NPC ở Trạm Gác Tro nói thẳng "vào tháp thì không ra bằng đường này nữa" và game hiện xác nhận lưu game. |
| Ý nghĩa cốt truyện | Đất chết không phải do boss cuối phá hoại. Nó là **vết sẹo của lần phong ấn đầu tiên** — và nó đang **lan rộng chậm** mỗi khi một trụ yếu đi. Người chơi đi qua nó sau khi đã chạm vào cả 4 trụ sẽ hiểu: dù chọn ending nào, vùng này cũng đã là cái giá phải trả rồi. |

### 3.2. Điều kiện mở cổng tháp

Xem chi tiết cổng chặn ở Mục 4. Tóm tắt hard gate vào tháp:

1. Có đủ **4 chìa phong ấn**: Chìa Rễ Xanh (Đông), Chìa Triều Ngọc (Nam), Chìa Vảy Cát (Tây), Chìa Sắt Băng (Bắc) — ở bất kỳ dạng / trạng thái nào mà quest vùng đã chốt (nguyên vẹn, nứt, hay được thay thế bằng thỏa thuận — game ghi trạng thái, ảnh hưởng tầng tháp và ending).
2. Hoàn thành Main Quest cuối của cả 4 vùng (Đông 4, Nam 4, Tây 4, Bắc 4).
3. Level khuyến nghị **25** — dưới mức này cổng vẫn mở nếu đủ chìa (không hard-lock level), nhưng Bóng Ấn và tầng đầu tháp sẽ là soft wall rất gắt.
4. Đã xem / kích hoạt cảnh **Vua lên tiếng** ở Cổng Tháp (cutscene bắt buộc, vua nói qua ấn — lần đầu người chơi nghe giọng vua rõ ràng).

### 3.3. Cấu trúc tầng của Tháp Vương Ấn

Tháp là **dungeon cuối dạng leo tháp nhiều tầng** — mỗi tầng là một lớp lịch sử / một đời gác ấn / một chức năng của phong ấn. Leo lên đỉnh để gặp vua, nhưng sự thật nằm ở chiều ngược lại: càng lên cao, càng biết thứ bị giam ở **dưới** tháp đang được neo bởi người ở **trong** tháp.

| Tầng | Tên tầng | Theme & Gameplay | Boss / Đỉnh điểm | Sự thật lộ ra ở tầng này |
|---|---|---|---|---|
| **Cổng — Tầng 0** | Cổng Bốn Chìa | Sảnh đá khổng lồ với 4 ổ khóa trụ. Dùng 4 chìa ở đây (trạng thái chìa ảnh hưởng hiệu ứng: chìa nứt = phòng có rò rỉ ấn, địch Bóng Ấn mạnh hơn nhưng có đường tắt). | Không boss — kiểm tra điều kiện + cutscene vua lên tiếng | Vua biết tên người chơi và biết người chơi đã làm gì ở từng thành (game đọc lựa chọn đã lưu, đọc thành thoại). |
| **Tầng 1–2** | Tầng Ký Ức Đông & Nam | Phòng biến đổi theo 2 vùng đầu: rừng trong nhà kính chết, đầm nước đen không phản chiếu. Địch: Bóng Ấn dạng quái Đông/Nam ở mức Lv.25. Puzzle nhẹ ôn lại cơ chế rễ / triều. | Mini-boss: **Hồi Âm Của Morvain / Cổ Thụ** (dạng bóng — không phải nhân vật thật, là ấn nhớ lại họ) | Phong ấn **ghi lại** mọi người gác nó. Không ai thực sự rời khỏi tháp. |
| **Tầng 3–4** | Tầng Ký Ức Tây & Bắc | Sa mạc trong nhà không gió, hành lang băng không lạnh. Địch Bóng Ấn dạng Tây/Bắc. Nếu Vesskar còn sống / thỏa thuận Bắc còn hiệu lực, tầng tương ứng có **sự trợ giúp** (Vesskar gầm làm sập một phòng khó; hiệp sĩ được giải thoát mở cửa tắt). | Mini-boss: **Hồi Âm Của Vesskar / Hiệp Sĩ Đen** (dạng bóng) | Vua đời đầu không đánh thắng thứ dưới tháp. Ông ta **thương lượng** với nó — và phong ấn là bản hợp đồng, không phải nhà tù một chiều. |
| **Tầng 5** | Tầng Sử Ấn | Thư viện / phòng bia đá vòng tròn: toàn bộ lịch sử phong ấn khắc quanh tường, càng lên cao chữ càng mới. Không combat bắt buộc — tầng lore thuần, có NPC **Người Ghi Ấn Cuối Cùng** (già, mù, sống trong tháp từ nhỏ). | Không boss — đối thoại dài, lựa chọn hỏi / không hỏi | Tên thật, tuổi thật và vai trò của công chúa; vua hiện tại là **hậu duệ kiêm người thừa kế hợp đồng**, không phải kẻ tạo ra nó. |
| **Tầng 6** | Tầng Công Chúa — Phòng Phong Ấn Sống | Phòng ấm áp, có cây, có ánh sáng như một phòng ngủ bình thường giữa tháp chết — sự bình thường này gây khó chịu nhất tháp. **Công chúa ở đây.** Không phải phòng giam xiềng xích: là phòng neo ấn, nơi công chúa sống, đọc sách, biết hết mọi chuyện, và **không thể rời phòng quá vài bước** mà không làm tháp rung. | Không boss — **đối thoại quyết định (decision dialogue)** dài nhất game. Công chúa đưa ra yêu cầu của chính cô (xem 3.4). | Twist chính (3.5). |
| **Tầng 7 — Đỉnh Tháp** | Đài Vương Ấn | Sân thượng tròn nhìn xuống toàn bộ bản đồ 4 vùng (người chơi thấy lại cả 4 thành ở xa). **Vua ở đỉnh tháp.** Đối thoại → lựa chọn → boss cuối kích hoạt theo lựa chọn. | **Vua** (giai đoạn đối thoại / có thể đánh một phần) → **Boss cuối** (3.4) | Kế hoạch thật của vua; cái giá nếu vua thành công / thất bại. |
| **Dưới Tháp (ẩn)** | Giếng Ấn — Đáy Ngược | Sau lựa chọn ở đỉnh, một trong các nhánh mở đường **xuống** Giếng Ấn dưới tháp (không phải leo lên nữa — đi xuống vào lòng đất chết). Không gian phi Euclid nhẹ: cầu thang dài hơn chiều cao tháp. | **Boss cuối — dạng thật của thứ bị giam** (ở một số ending) | Thứ bị giam nói chuyện lần đầu bằng ngôn ngữ người chơi hiểu. Nó đưa ra **đề nghị của nó**. Ending được quyết định ở đây, không chỉ ở đỉnh. |

**Nguyên tắc thời lượng tháp:** 2,5–4 giờ chơi, có điểm save / nghỉ ở Tầng 0, Tầng 5 và trước Tầng 6. Không bắt người chơi leo một mạch không nghỉ — độ khó đến từ lựa chọn và boss, không từ việc hành xác.

### 3.4. Công chúa, Vua, Boss cuối — vai trò chính xác

| Nhân vật | Vị trí | Vai trò bề ngoài (người chơi tưởng) | Vai trò thật (twist — xem 3.5) | Gameplay |
|---|---|---|---|---|
| **Công chúa** | Tầng 6 — Phòng Phong Ấn Sống, **trong tháp** | Công chúa bị vua / thế lực ác giam trong tháp, chờ hiệp sĩ cứu (mô-típ cổ tích game cố ý dựng lên ở Hồi I) | **Vật phong ấn sống** — người neo ấn hiện tại. Sinh ra / được chọn để cơ thể và tên của cô là khóa trung tâm. Cô sống thì ấn giữ; cô rời tháp hoặc chết thì ấn vỡ theo cách không kiểm soát. Cô **biết hết** và có ý chí, mong muốn riêng — không phải vật phẩm thụ động. | NPC đối thoại quyết định. Thái độ của cô với người chơi phụ thuộc vào việc người chơi đã làm gì ở 4 trụ (phá / giữ / thay thế). Cô có thể xin người chơi 1 trong 3 việc mâu thuẫn nhau tùy trạng thái thế giới — game không đánh dấu cái nào là "đúng". |
| **Vua** | **Đỉnh tháp (Tầng 7)** | Vua độc tài giam công chúa, muốn sức mạnh của thứ bị giam (tin đồn Hồi I–II) | **Không đơn thuần là ác.** Vua muốn **phá phong ấn một cách có kiểm soát** — theo GDD v1: để cứu nước / lấy sức mạnh — nhưng ở v2 làm rõ động cơ kép: (a) phong ấn đang giết vương quốc chậm rãi qua 4 cái giá ở 4 vùng, vua tin phá ấn có kiểm soát còn ít chết người hơn giữ ấn thêm 100 năm; (b) công chúa là **con gái / người thân của vua** (giữ đúng quan hệ theo GDD nhân vật chính thức khi chốt — tài liệu này không tự đổi quan hệ), vua không chịu nổi việc cô làm vật neo sống cả đời. Đồng thời vua **cũng** muốn sức mạnh của thứ bị giam để vương quốc không bị nuốt sau khi ấn vỡ — tham vọng và cứu nước quện vào nhau, không tách sạch được. | Đối thoại boss + boss fight một phần. Vua **không phải boss cuối thuần túy**: đánh thắng vua không tự động cho ending tốt; giết vua ở đỉnh có thể làm mất người duy nhất biết nghi lễ phá ấn có kiểm soát. |
| **Thứ bị giam / Boss cuối** | **Dưới tháp (Giếng Ấn) và ở đỉnh tháp khi ấn nứt** — boss cuối xuất hiện ở đỉnh/dưới tháp tùy nhánh ending | "Quái vật cổ đại thuần ác bị phong ấn vì suýt hủy diệt thế giới" (sử sách trong game) | Một thực thể cổ, có trí tuệ, từng **đồng ý** bản hợp đồng phong ấn đầu tiên (đổi lấy một điều nó muốn — để mở ở tài liệu lore sâu, không chốt cứng ở đây để tránh mâu thuẫn). Nó đã bị các đời vua **đơn phương sửa hợp đồng** (thêm người gác, thêm nghi lễ chết người, đổi vật neo thành người sống) mà nó coi là bội ước. Nó muốn ra — và theo logic của nó, nó **có lý**. Nó cũng thực sự nguy hiểm cho con người theo cách không cần ác ý: như lũ lụt nguy hiểm, không phải như sát nhân. | **Boss cuối.** Hình dạng / bộ chiêu thay đổi theo trạng thái 4 trụ và lựa chọn với công chúa / vua. Có nhánh **không đánh boss cuối ở dạng đầy đủ** nếu người chơi đạt thỏa thuận mới (điều kiện rất khắt khe — cần trạng thái tốt ở cả 4 vùng) — nhưng nhánh này vẫn có một trận đánh (với Vua, hoặc với Bóng Ấn của chính người chơi) chứ không "bỏ qua endgame". |

### 3.5. Twist — viết rõ để mọi tài liệu sau không hiểu sai

1. **Công chúa là vật phong ấn sống.** Không phải "công chúa bị nhốt *cùng* phong ấn" — chính cô **là** khóa. Cứu cô ra khỏi tháp theo kiểu cổ tích (đánh bại vua, đưa cô đi) mà không xử lý ấn = **kịch bản tồi tệ nhất mặc định** nếu người chơi làm theo quán tính cổ tích ở đỉnh tháp mà không nghe hết Tầng 5–6. Game phải cho đủ thông tin trước khi người chơi chọn — bi kịch đến từ lựa chọn có hiểu biết, không từ việc game lừa người chơi thiếu dữ kiện.
2. **Vua không đơn thuần là ác.** Vua muốn phá phong ấn. Lý do của vua vừa ích kỷ (sức mạnh, quyền lực, không chịu mất con / người thân vào ấn) vừa có cơ sở thật (4 vùng đang chết dần vì ấn — người chơi đã **tự thấy** cả 4 cái giá). Vì thế đối thoại với vua không được viết thành "phản diện monologue rồi đánh". Ít nhất một lập luận của vua phải khiến người chơi chần chừ thực sự.
3. **Thứ bị giam không thuần ác và không vô tội.** Nó có lý về mặt hợp đồng, và nó vẫn sẽ làm chết rất nhiều người nếu thoát ra tự do hoàn toàn. Cả hai điều cùng đúng. Ending tốt nhất của game (nếu có) không phải "thả nó" hay "giam nó tiếp như cũ" mà là **một bản thỏa thuận mới phải trả giá khác** — và người trả giá, một cách công bằng theo logic game, nên là người chơi / vua / công chúa cùng chia, không phải dân 4 vùng trả thay như trước.
4. **Người chơi cũng đã phá ấn trong lúc "sửa" nó.** Mỗi boss thành bị đánh bại, mỗi trụ bị chạm vào ở 4 vùng đều làm ấn **thay đổi**. Hồi III phải thừa nhận điều này bằng thoại của công chúa: cô cảm nhận được từng trụ khi người chơi chạm vào nó. Người chơi không đứng ngoài câu chuyện phong ấn — người chơi là **biến số mới nhất của nó**.

### 3.6. Ending — khung (không chốt số lượng ở tài liệu này)

Tài liệu thế giới chỉ chốt **trục** ending, chi tiết ending để ở tài liệu cốt truyện / ending riêng:

- **Trục Giữ Ấn:** Ấn được giữ (có thể bằng vật neo mới / người gác mới) — vương quốc sống tiếp, cái giá tiếp tục, có thể giảm nhẹ nếu 4 vùng ở trạng thái tốt.
- **Trục Phá Ấn Có Kiểm Soát:** Đi theo / sửa kế hoạch của vua — ấn vỡ theo nghi lễ, công chúa được giải phóng khỏi vai vật neo, thứ bị giam ra ngoài **có điều kiện**, hậu quả lớn nhưng có chuẩn bị.
- **Trục Thỏa Thuận Mới:** Đàm phán lại với thứ bị giam (khó nhất, cần trạng thái 4 vùng tốt) — ấn cũ kết thúc, một trật tự mới chưa ai biết chắc sẽ tốt hơn, chỉ biết nó **không bắt một người sống làm khóa nữa**.
- **Trục Vỡ Ấn Vô Kiểm Soát (bad end):** Ấn vỡ do lựa chọn hấp tấp / giết sai người / đưa công chúa rời tháp vô điều kiện — đất chết lan, nhưng game vẫn cho đoạn kết đàng hoàng (không "game over, chơi lại") để bi kịch có trọng lượng.

Mọi ending đều phải **nhắc lại cụ thể** lựa chọn ở Đông, Nam, Tây, Bắc (ai sống, làng nào mất, Vesskar còn hay không, đội gác Bắc ra sao) trong đoạn kết / epilogue trượt chữ. Người chơi phải thấy vòng hành trình của mình trong kết cục.

---

## 4. TUYẾN TIẾN TRIỂN & CỔNG CHẶN

### 4.1. Thứ tự bắt buộc & Lý do

```text
ĐÔNG (1–6) ──► NAM (7–12) ──► TÂY (13–18) ──► BẮC (19–24) ──► THÁP VƯƠNG ẤN (25)
  Xuân Lâm       Triều Ẩm        Hồng Sa          Hàn Thiết
```

Thứ tự này là **bắt buộc về cốt truyện (hard order)**, không phải gợi ý. Lý do trong thế giới: đường đi, thời tiết, uy tín và chuỗi tin tức chỉ mở theo chiều này (đò Bến Mưa bị lũ chặn cho đến khi xong Đông; caravan Tây chỉ chạy sau biến cố Nam; đèo Bắc chỉ mở khi có phép của Hồng Sa; cổng tháp cần cả 4 chìa). Người chơi vẫn có **tự do nội vùng** rất rộng: trong mỗi vùng, làm làng nào trước, dungeon phụ trước hay sau boss thành (trong giới hạn), quest phụ lúc nào — đều tự chọn.

### 4.2. Bảng cổng chặn (gate) chi tiết

| Chuyển đoạn | Cổng cứng (Hard Gate) — không qua được nếu thiếu | Cổng mềm (Soft Gate) — qua được nhưng rất khổ / thiếu nội dung nếu bỏ | Level khuyến nghị | Hệ thống dạy ở cổng này |
|---|---|---|---|---|
| Vào game → Đông tự do | Hoàn thành tutorial ở Làng Tân Diệp (có kiếm đầu tiên) | — | 1 | Combat, quest, uy tín |
| Đông → **Ra khỏi Đông / sang Nam** | Hoàn thành **Main Quest Đông 4** (boss Thành Xuân Lâm) + có **Chìa Rễ Xanh** (ở trạng thái quest chốt) + đò Bến Mưa được mở | Uy tín Đông ≥ mức "Được Tin" để có giá trọ / shop tốt ở Nam; chưa làm Mỏ Rêu Cổ vẫn đi được nhưng boss Đông khó hơn và thiếu lore | 6 khi rời Đông | Cổng theo **boss + chìa**, không theo level thuần |
| Nam → **sang Tây** | Hoàn thành **Main Quest Nam 4** (boss Morvain) + có **Chìa Triều Ngọc** + đường caravan / thuyền từ Làng Muối Đắng được mở | Có thuốc / kháng độc dự trữ; uy tín Nam ảnh hưởng giá caravan. Thiếu Làng Đèn Lồng (hub) thì Tây mở đầu thiếu thông tin quan trọng | 12 khi rời Nam | Cổng theo **chuỗi sự kiện liên vùng** (biến cố Nam mở đường Tây) |
| Tây → **sang Bắc** | Hoàn thành **Main Quest Tây 4** (Vesskar — giết **hoặc** thỏa thuận) + có **Chìa Vảy Cát** (hoặc vật thay thế theo đường đàm phán) + giấy phép caravan Hồng Sa qua đèo | Uy tín Tây cao mở đường tắt / giá rèn đá đỏ; giết Rồng Cát Con quá nhiều làm đàm phán Vesskar khó hơn rõ rệt (soft gate đạo đức) | 18 khi rời Tây | Cổng có **hai đường hợp lệ** (giết / không giết) cho cùng một chìa |
| Bắc → **vào Đất Chết / Tháp** | Hoàn thành **Main Quest Bắc 4** (Hiệp Sĩ Đen) + có **Chìa Sắt Băng** + đã đủ **cả 4 chìa** (game kiểm tra ở Cổng Bốn Chìa, Tầng 0) | Trạng thái 4 vùng (ai sống, thỏa thuận nào còn) ảnh hưởng tầng tháp, đồng minh, ending — không chặn vào, nhưng chặn **ending tốt** (soft gate kết cục) | 24 khi rời Bắc, **25** cho tháp | Cổng cuối kiểm tra **toàn bộ hành trình**, không chỉ sức mạnh |
| Trong tháp → Đỉnh / Giếng Ấn | Xem hết đối thoại bắt buộc Tầng 5 + Tầng 6 (không skip lần đầu) | Mang đủ hồi phục từ Hàn Thiết (không shop trong tháp) | 25 | Point of no return có cảnh báo rõ |

**Nguyên tắc cổng chặn:**

- **Không cổng level thuần túy.** Level là khuyến nghị / soft wall qua độ khó địch, không bao giờ có NPC nói "bạn chưa đủ level, quay lại sau".
- **Mọi hard gate đều là vật / sự kiện cốt truyện** (chìa, boss thành, đường mở) mà người chơi nhìn thấy và hiểu được từ sớm.
- **Backtracking được phép và được thưởng:** sau khi sang vùng mới, vẫn quay lại vùng cũ được (trừ điểm no-return ở tháp). Quay lại sau biến cố sẽ thấy làng thay đổi, quest phụ mới, NPC nhắc lại lựa chọn cũ.

### 4.3. Thời lượng ước tính

| Vùng | Main quest | Khám phá + quest phụ + dungeon đầy đủ | Tổng vùng (người chơi trung bình) | Ghi chú nhịp |
|---|---|---|---|---|
| Đông (1–6) | 3–4 giờ | 2–3 giờ | **5–7 giờ** | Chậm nhất về nhịp kể chuyện — cố ý để gắn bó với làng khởi đầu |
| Nam (7–12) | 4–5 giờ | 3–4 giờ | **7–9 giờ** | Dungeon triều tốn thời gian chờ chu kỳ — đã tính vào |
| Tây (13–18) | 5–6 giờ | 4–5 giờ | **9–11 giờ** | Đường đàm phán Vesskar dài hơn đường giết khoảng 1–1,5 giờ |
| Bắc (19–24) | 5–6 giờ | 4–5 giờ | **9–11 giờ** | Dungeon dài nhất vòng ngoài |
| Tháp Vương Ấn (25) | 2,5–4 giờ | + epilogue | **3–4 giờ** | Không quest phụ trong tháp |
| **Tổng** | — | — | **≈ 33–42 giờ** (main + phụ vừa phải) / **≈ 22–26 giờ** (chỉ main, bỏ phụ tối đa cho phép) | Khung cho game solo dev: cắt phụ trước, không cắt main / dungeon riêng |

---

## 5. HỆ THỐNG PHONG ẤN: 4 TRỤ, 4 CHÌA & SỰ GẮN KẾT

### 5.1. Phong ấn hoạt động như thế nào (luật cứng của thế giới)

1. Phong ấn là một **hợp đồng–nghi lễ–kiến trúc** ba trong một: kiến trúc là 4 trụ ở 4 thành + tháp trung tâm; nghi lễ là các đời người gác / giữ / chết để duy trì nó; hợp đồng là thỏa thuận gốc với thứ bị giam.
2. **Không trụ nào tự đứng được.** Mỗi trụ neo một "hướng" của thứ bị giam (thân / triều–hơi thở / bóng–di chuyển / tên–ký ức — cách gọi mang tính biểu tượng trong sử sách; luật vận hành thật là: mất 1 trụ, 3 trụ còn lại gánh thêm và **cái giá ở 3 vùng còn lại tăng lên** — người chơi phải *thấy* điều này: sau mỗi boss thành, quay lại vùng trước sẽ có biến đổi nhỏ xấu đi hoặc lạ đi).
3. **Chìa không phải vật trang trí.** Mỗi chìa là **phần có thể mang đi của trụ** — lấy chìa = trụ chuyển sang trạng thái "neo từ xa qua tháp" yếu hơn. Đó là lý do vua cần 4 chìa tập trung ở tháp để phá ấn có kiểm soát, và cũng là lý do việc người chơi gom chìa **tự nó đã là một bước của việc phá ấn**, dù người chơi tưởng mình đang "thu thập vật phẩm cứu thế giới".
4. **Công chúa là khóa trung tâm, 4 chìa là ổ khóa ở 4 hướng.** Có chìa mà không có / không xử lý khóa trung tâm thì ấn không mở đúng cách — chỉ nứt. Đây là cơ chế cho bad end vỡ ấn vô kiểm soát.

### 5.2. Bảng 4 trụ / 4 chìa

| Hướng | Trụ | Biểu hiện vật lý của trụ | Chìa | Ai / Cái gì giữ trụ hằng ngày | Chuyện gì xảy ra khi trụ bị phá / kích hoạt / lấy chìa |
|---|---|---|---|---|---|
| **Đông** | **Trụ Mộc** | Cổ Thụ Trung Tâm ở Thành Xuân Lâm + hệ rễ xuyên Mỏ Rêu Cổ | **Chìa Rễ Xanh** — lõi gỗ sống không bao giờ khô, phải giữ ẩm / bọc rêu mới mang đi được | Lãnh chúa Lâm Nhược + các đời thợ vườn / thợ mỏ vô tình nuôi rễ | Rễ ngừng mọc nuốt nhà (tốt ngắn hạn) nhưng cây bắt đầu **héo lần đầu tiên trong lịch sử thành**; mùa xuân vĩnh cửu kết thúc — vùng Đông sẽ có mùa đông đầu tiên ở epilogue. Thời gian bị kẹt ở Đông bắt đầu chảy lại: người và vật "già" nhanh hơn trong một thời gian. |
| **Nam** | **Trụ Thủy** | Chu kỳ triều nhân tạo + Đền Chìm Triều ở Thành Triều Ẩm | **Chìa Triều Ngọc** — viên ngọc luôn ướt, nghe như có tiếng nước bên trong | Các đời Người Giữ Triều (nghi lễ chết người) → Morvain phá vỡ chu kỳ | Triều **quay về tự nhiên một cách dữ dội**: một đợt triều lớn cuối cùng, sau đó nước ổn định hơn nhưng Đền Chìm Triều chìm hẳn / hoặc nổi hẳn tùy lựa chọn. Thành Triều Ẩm mất đặc quyền kiểm soát nước — phải học sống như cảng bình thường. |
| **Tây** | **Trụ Sa** | Vesskar + chu kỳ bão cát quanh Thành Hồng Sa + Lăng Cát Chôn | **Chìa Vảy Cát** — một vảy rồng cát cổ (tự rụng / được tặng / bị lấy khi giết — trạng thái khác nhau theo đường đi) | **Rồng Cát Vesskar** — người gác duy nhất không phải con người | Nếu thỏa thuận: Vesskar **tự cho chìa** và vẫn giữ bão cát có kiểm soát — trụ chuyển thành "trụ tự nguyện", trạng thái tốt nhất của bất kỳ trụ nào. Nếu giết: chìa lấy từ xác, bão cát **mất kiểm soát vĩnh viễn**, Lăng Cát Chôn bị cát nuốt hẳn sau một thời gian. |
| **Bắc** | **Trụ Hàn** | Đội Gác Băng ở Pháo Đài Băng Nứt + Lò Lớn ở Thành Hàn Thiết | **Chìa Sắt Băng** — thanh sắt đen lạnh không tan trong lửa thường, chỉ ấm lên khi ở gần tháp | Các đời hiệp sĩ bị trưng thu đi gác băng, dưới quyền Hiệp Sĩ Đen | Đội gác được **đứng xuống** lần đầu: người còn sống thì thaw dần (một số không qua khỏi, một số không nhớ mình là ai), wight mất kỷ luật và tan dần / hoặc tràn xuống tùy lựa chọn. Bắc mất tuyến phòng thủ quái — nhưng lần đầu tiên không phải gửi con em đi đóng băng nữa. |

### 5.3. Chuỗi hệ quả khi từng trụ thay đổi (cho dev làm sự kiện thế giới)

```text
Đông lấy chìa ──► Nam: triều lạ mạnh hơn, cá chết nhiều hơn (NPC Nam nhắc "từ dạo Đông có biến")
Nam lấy chìa ──► Tây: giếng cạn sớm hơn, Vesskar trằn trọc (NPC Tây lo "rồng mất ngủ")
Tây xử lý trụ ─► Bắc: bão tuyết đổi hướng, cực quang ban ngày xuất hiện (điềm ở Làng Cực Quang)
Bắc lấy chìa ──► Đất Chết: lan rộng thấy rõ trên bản đồ, đường về vòng ngoài bắt đầu đóng (chuẩn bị no-return)
Cả 4 chìa về tháp ► Ấn chuyển sang trạng thái "chờ khóa trung tâm" — toàn thế giới rung nhẹ trong cutscene, mọi NPC hub đều có 1 thoại mới
```

Thiết kế này tốn ít tài nguyên (chủ yếu là thoại + vài prop / hiệu ứng thời tiết) nhưng cho cảm giác **thế giới là một hệ thống**, không phải 4 map rời nhau.

### 5.4. Liên hệ với twist công chúa + vua

- 4 trụ là **cái giá phân tán**: thay vì một người chịu hết, các đời vua chia cái giá phong ấn ra 4 vùng để **không ai nhìn thấy toàn bộ hóa đơn**. Dân Đông trả bằng thời gian / mộ phần, dân Nam bằng người giữ triều, dân Tây bằng một sinh vật bị hiểu lầm, dân Bắc bằng con em đi gác băng. Công chúa ở trung tâm là **phần giá đắt nhất bị giấu kỹ nhất** — một người sống làm khóa.
- Vua hiện tại là người đầu tiên (theo sử trong tháp) **nhìn toàn bộ hóa đơn và từ chối trả tiếp theo cách cũ**. Kế hoạch phá ấn của vua là cực đoan và nguy hiểm, nhưng nó sinh ra từ việc nhìn thẳng 4 cái giá này — người chơi, sau khi đi đủ 4 vùng, là người duy nhất trong vương quốc **cũng đã nhìn thấy cả 4**, nên là người duy nhất có thể tranh luận với vua ngang hàng ở Tầng 7.
- Vì thế cấu trúc 4 thành không phải "4 màn chơi rồi boss cuối". Nó là **4 bằng chứng** người chơi thu thập bằng trải nghiệm để đến tháp và nói: *tôi biết cái giá là gì, ở cả 4 nơi, và tôi vẫn / vẫn không đồng ý với ngài.* Mọi lựa chọn ending đều phải viện dẫn được ít nhất một vùng cụ thể.

---

## 6. QUEST CHÍNH TUYẾN THEO TỪNG VÙNG & QUEST PHỤ GỢI Ý

> **Quy ước đọc bảng quest:** *Tên quest* là tên hiển thị trong journal. *Mục tiêu* là việc người chơi làm trên gameplay (không phải tóm tắt phim). *Lựa chọn / Hậu quả* là điểm game ghi sổ (flag) để dùng ở vùng sau / tháp / ending. Quest không ghi lựa chọn = tuyến tính có chủ ý (thường là quest dạy cơ chế).
> **Quy ước uy tín:** Mỗi vùng có thang uy tín riêng: *Lạ Mặt → Được Biết → Được Tin → Được Nhờ Cậy → (riêng từng vùng) Danh hiệu vùng*. Main quest cho nhiều uy tín nhất; quest phụ cho ít hơn nhưng cần để đạt mức cao nhất và mở đường tốt nhất ở quest cuối vùng.

---

### 6.1. ĐÔNG — Main Quest (Level 1–6)

| # | Tên quest | Mục tiêu gameplay | Lựa chọn / Hậu quả |
|---|---|---|---|
| **Đông 1** | **Hai Bàn Tay Trắng** | Tỉnh / đến Làng Tân Diệp không vũ khí, không vàng. Làm 3 việc vỡ lòng theo thứ tự tự chọn: chặt củi (học tương tác), đuổi Slime Cỏ khỏi vườn (combat đầu tiên bằng gậy gỗ), tìm thùng đồ mất ở bìa rừng (học khám phá / goblin đầu tiên). Nhận **kiếm gỗ tập + áo vải**, mở bảng quest làng. | Không lựa chọn lớn. Lựa chọn nhỏ: trả thùng đồ nguyên vẹn hay lấy trộm ít vàng trong thùng (NPC không biết ngay, nhưng uy tín Tân Diệp tăng chậm hơn — lần đầu game dạy "hành động không ai thấy vẫn có sổ"). |
| **Đông 2** | **Sổ Nợ Hạt Giống** | Đi Làng Mạch Lúa + Làng Bến Mưa. Giúp Mạch Lúa xử lý **Hầm Rượu Chuột Chúa** (dungeon tutorial, boss Chuột Chúa) để cứu kho lúa; giúp Bến Mưa dọn goblin ở bến đò. Gom đủ uy tín 2 làng để được giới thiệu vào Thành Xuân Lâm. | Giúp làng nào trước ảnh hưởng ai giới thiệu người chơi nồng nhiệt hơn (thoại + giá shop). Nếu chỉ làm 1 làng và "mua" thư giới thiệu bằng vàng farm được: vào thành được nhưng ở trạng thái *Được Biết* thay vì *Được Tin* — giá rèn đắt hơn, thiếu 1 quest phụ thành. |
| **Đông 3** | **Rễ Ăn Vào Nhà** | Trong Thành Xuân Lâm: điều tra khu dân cư bị rễ Cổ Thụ nuốt. Xuống **Mỏ Rêu Cổ**, đánh phân thân Lõi Rễ Mỏ, đọc nhật ký thợ mỏ, mang **Mảnh Chìa Rễ Xanh 1/2** về. Đối thoại với Lãnh chúa Lâm Nhược — lần đầu nghe chữ "trụ" (ông ta nói lỡ rồi lái đi). | Chọn báo sự thật về mỏ cho dân (dân hoang mang, uy tín dân tăng, uy tín với lãnh chúa giảm, mở quest phụ sơ tán) **hoặc** giữ bí mật cùng lãnh chúa (uy tín lãnh chúa tăng, mở đường vào Gốc Cổ Thụ sớm hơn, dân sau này trách người chơi ở Hồi III nếu quay lại). Flag: `dong_su_that_mo`. |
| **Đông 4** | **Golem Rêu Cổ Thụ** ⭐ Boss thành | Vào Gốc Cổ Thụ. **Boss: Golem Rêu Cổ Thụ** — golem hình thành từ rễ + đá mộ + tượng cũ, 2 phase: Phase 1 đánh rễ phụ / lõi lộ; Phase 2 golem "nhớ" nó từng là người gác (đòn chậm lại, có khoảng ngừng như do dự — chi tiết kể chuyện bằng animation). Sau boss, nhận **Chìa Rễ Xanh** hoàn chỉnh. | **Lựa chọn cuối vùng:** (A) *Cắt rễ chính* — cứu khu dân cư ngay, trụ yếu hẳn, Cổ Thụ héo một phần ngay trước mắt; (B) *Chặt rễ phụ + gia cố nhà* — giữ trụ tốt hơn, khu dân cư phải sơ tán, mất nhà nhưng giữ mộ. Cả hai đều mở đường sang Nam. Khác nhau ở trạng thái Đông trong epilogue + thoại công chúa ở Tầng 6. Flag: `dong_cat_re / dong_so_tan`. |

**Quest phụ gợi ý — Đông:**

| Tên phụ | Làng / Nơi | Nội dung ngắn | Phần thưởng / Ý nghĩa |
|---|---|---|---|
| Lá Không Héo | Làng Tân Diệp | Tìm nguồn gốc chiếc lá không tàn của đứa bé | Lore phong ấn sớm; vật phẩm kỷ niệm không bán được |
| Sổ Nợ Của Góa Phụ | Làng Mạch Lúa | Trả nợ hạt giống bằng vàng / bằng công / bằng cách phanh phui chủ vựa | Dạy quest nhiều cách giải; uy tín Mạch Lúa |
| Lão Chèo Đò Kể Chuyện | Làng Bến Mưa | Nghe đủ 3 câu chuyện của lão đò vào 3 ngày mưa khác nhau | Tin sớm về Nam + Morvain; giảm giá đò vĩnh viễn |
| Chuột Thứ Hai | Hầm Rượu (quay lại) | Sau boss, đàn chuột con còn lại — giết / thả / giao cho chủ hầm nuôi đuổi mèo | Quest đạo đức nhỏ, không thưởng xịn — cố ý |

### 6.2. NAM — Main Quest (Level 7–12)

| # | Tên quest | Mục tiêu gameplay | Lựa chọn / Hậu quả |
|---|---|---|---|
| **Nam 1** | **Triều Không Nghe Trăng** | Từ Làng Bến Bùn vào Nam: học địa hình đầm, chế / mua thuốc giải độc, đến Làng Đèn Lồng đúng lúc **đêm giữ đèn** (quest phòng thủ: giữ 3 cụm đèn không tắt trước sóng Quái Bùn + Rắn Đầm trong 1 đêm). Sáng hôm sau Hội Đèn chính thức nhờ việc. | Nếu để 1 cụm đèn tắt: khu nhà tương ứng bị quái tràn, 1 NPC bị thương (không chết), quest vẫn qua nhưng Làng Đèn Lồng ở trạng thái hư hại đến hết vùng. Flag: `nam_den_tat_so`. |
| **Nam 2** | **Thư Ướt Không Ký Tên** | Điều tra thư của Morvain: hỏi ở Làng Đèn Lồng, Làng Muối Đắng; vào **Đền Chìm Triều** lần 1 (đến phòng triều, gặp Morvain giai đoạn đối thoại / đánh thăm dò, bà ta làm ngập phòng và rút). Mang vật chứng về. | Tha / giết **Phù Thủy Tập Sự** bị bắt trong đền ảnh hưởng trực tiếp: tha → có nhân chứng sống về nghi lễ giữ triều, Morvain mềm hơn ở Nam 4; giết / không cứu → chỉ còn bia đá làm chứng, Morvain coi người chơi là "kẻ của vua". Flag: `nam_tha_tap_su`. |
| **Nam 3** | **Tên Khắc Dưới Nước** | Vào lại Đền Chìm Triều lúc triều rút sâu (puzzle triều hoàn chỉnh), đọc danh sách tên Người Giữ Triều dưới mực nước, lấy **Chìa Triều Ngọc (dạng thô)**. Quay về Thành Triều Ẩm qua Cống Ngập, chứng kiến thành ngập cục bộ / thí nghiệm của Morvain thất bại trong cutscene. | Chọn mang danh sách tên công bố ở chợ thành (dân nổi giận với cả Morvain *và* các đời lãnh chúa trước, mở đường kết cục C ở Nam 4) **hoặc** giao danh sách riêng cho Morvain (bà ta lần đầu mất bình tĩnh — mở đối thoại riêng, giảm độ khó thuyết phục ở Nam 4, nhưng dân vẫn không biết sự thật). Flag: `nam_cong_bo_ten`. |
| **Nam 4** | **Phù Thủy Đầm Lầy Morvain** ⭐ Boss thành | Đối đầu ở Thành Triều Ẩm / Đền Triều trong thành. **Boss: Phù Thủy Đầm Lầy Morvain** — boss phép 3 phase theo mực nước phòng boss: nước cạn (phép độc), nước lưng chừng (phép nước + triệu hồi Quái Bùn), nước ngập (bơi / đứng trên cọc, Morvain mạnh nhất nhưng cũng đang tự làm hại mình). Trước phase cuối có **khoảng đối thoại** — có thể chuyển sang kết cục đàm phán nếu đủ điều kiện. Nhận **Chìa Triều Ngọc** hoàn chỉnh. | **3 kết cục vùng:** (A) *Khôi phục nghi lễ* — cần 1 Người Giữ Triều mới: Morvain tự nhận (nếu đã tha tập sự + đối thoại đủ) hoặc một NPC tình nguyện gây tranh cãi đạo đức lớn; thành yên, người chơi mang tiếng đã đồng ý cái chết nghi lễ. (B) *Đi theo thí nghiệm của Morvain* — Morvain sống làm lãnh chúa–y sư, thành đánh cược, kết quả để ngỏ đến epilogue. (C) *Phá chu kỳ triều* — không ai giữ triều nữa, một phần thành bỏ hoang vì ngập / khô, Morvain bị trục xuất hoặc tự rời đi. Mọi kết cục đều cho chìa và mở đường Tây. Flags: `nam_nghi_le / nam_thi_nghiem / nam_pha_trieu`. |

**Quest phụ gợi ý — Nam:**

| Tên phụ | Làng / Nơi | Nội dung ngắn | Phần thưởng / Ý nghĩa |
|---|---|---|---|
| Bùa Bùn | Làng Bến Bùn | Kiểm chứng "bùa bùn" của trẻ con: vô dụng — nói thật hay để chúng tin? | Quest thoại thuần; ảnh hưởng 1 thoại ở epilogue làng |
| Đèn Của Người Chết | Làng Đèn Lồng | Thắp lại đèn cho khu nhà đã bỏ sau một đêm đèn tắt nhiều năm trước | Lore Người Giữ Triều; vật phẩm đèn dầu nâng cấp cho Đền Chìm Triều |
| Muối Đắng | Làng Muối Đắng | Tìm nguồn vị đắng của muối (mạch phong ấn rò vào ruộng muối) | Kháng độc vĩnh viễn +; thương nhân mở đường Tây sớm hơn |
| Bệnh Triều | Thành Triều Ẩm | Giúp / từ chối làm mẫu thử an toàn cho Morvain | Buff hoặc debuff tạm thời; Morvain nhớ việc này ở Nam 4 |

### 6.3. TÂY — Main Quest (Level 13–18)

| # | Tên quest | Mục tiêu gameplay | Lựa chọn / Hậu quả |
|---|---|---|---|
| **Tây 1** | **Nước Có Giá** | Từ Làng Giếng Cạn học sinh tồn sa mạc (nước, nóng ngày / lạnh đêm). Hộ tống caravan nhỏ đến **Làng Chợ Đêm**, lần đầu nghe bão cát do Vesskar đổi hướng bất thường. Kiếm uy tín caravan. | Chia / không chia nước của mình cho caravan giữa đường (tốn tài nguyên thật): chia → caravan tôn trọng, mở giá tốt + tin quan trọng miễn phí; không chia → 1 người khuân vác gục (không chết nếu người chơi cứu sau bằng thuốc — tốn hơn). Flag: `tay_chia_nuoc`. |
| **Tây 2** | **Hàm Rồng Đóng Cửa** | Đến Thành Hồng Sa, gặp Thống Lĩnh Caravan. Điều tra vì sao cổng Hàm Rồng đóng: Vesskar tuần tra sát thành bất thường. Làm quest caravan / bounty để đạt uy tín *Được Nhờ Cậy*, được phép ra bãi cát gặp dấu vết Vesskar (không đánh — sự kiện truy vết + lần đầu thấy rõ kích thước / trí tuệ của nó qua cách nó tránh làng). | Chọn nhận bounty **săn Rồng Cát Con** (thưởng cao, giảm điểm đàm phán) hay **bounty thay thế khó hơn** (dọn Golem Đá Đỏ ở đường caravan). Game không khóa lựa chọn nào, chỉ ghi sổ sinh thái. Flag: `tay_san_rong_con_so_luong`. |
| **Tây 3** | **Lăng Cát Chôn** | Vào **Lăng Cát Chôn** (dungeon), vượt phòng cát chảy, gặp **Người Gác Lăng Không Tên**, lấy bằng chứng: tên thật của người gác + ghi chép lời hứa của vua đời trước với Vesskar + (nếu đi hết nhánh sâu) **Chìa Vảy Cát dự phòng trong lăng** (chìa này yếu / không hoàn chỉnh — dùng được để qua cổng nhưng không thay được chìa do Vesskar cho ở trạng thái tốt nhất). | Với Người Gác Lăng: đánh bại / **trả lại tên để giải thoát** (cần manh mối tên từ phòng phụ — bỏ qua phòng phụ = mất lựa chọn này). Giải thoát → ông ta cho biết điểm yếu *và* điểm "yếu lòng" của Vesskar; đánh bại → chỉ lấy được vật chứng giấy. Flag: `tay_giai_thoat_gac_lang`. |
| **Tây 4** | **Rồng Cát Vesskar** ⭐ Boss thành — có đường không giết | Đối đầu ở bãi cát / Cổng Hàm Rồng. **Boss: Rồng Cát Vesskar.** Đường đánh: boss lớn 3 phase (đào cát / bay thấp phun cát / trồi lên nuốt địa hình — đấu trường thay đổi hình dạng). Đường không giết: chuỗi sự kiện thay cho phase 2–3 (trình bằng chứng lăng → thực hiện lại nghi lễ lời thề ở 3 điểm quanh thành trong lúc Vesskar quan sát / thử thách → đối thoại bằng hành động, không phải chọn 1 câu thoại "thuyết phục thành công"). Nhận **Chìa Vảy Cát**. | **2 kết cục chính:** (A) *Giết Vesskar* — chìa từ xác, danh hiệu Diệt Rồng, bão cát mất kiểm soát (đóng 1 số đường / làng bị hại về sau), mất đồng minh endgame. (B) *Thỏa thuận mới với Vesskar* — cần uy tín Tây cao + bằng chứng lăng (+ điểm đàm phán không bị trừ quá mức do săn rồng con); Vesskar tự cho vảy, vẫn canh cổng, mở trợ giúp ở tháp. Kết cục B khó hơn và dài hơn có chủ ý — không phải "đường tốt miễn phí". Flags: `tay_giet_vesskar / tay_thoa_thuan_vesskar`. |

**Quest phụ gợi ý — Tây:**

| Tên phụ | Làng / Nơi | Nội dung ngắn | Phần thưởng / Ý nghĩa |
|---|---|---|---|
| Bản Đồ Lăng Thật | Làng Chợ Đêm | Mua / vạch trần / hợp tác với kẻ bán bản đồ nửa thật | Giảm độ khó Lăng Cát Chôn hoặc mất vàng — bài học tin đồn |
| Cát Phổi | Làng Ốc Đảo Cát Trắng | Tìm thuốc cho gia tộc giữ ốc đảo | Mở shop cao cấp ốc đảo; lore mạch phong ấn dưới ốc đảo |
| Caravan Mất Tích | Đường caravan | Tìm caravan mất tích trong bão cát — cứu người hay cứu hàng theo lệnh chủ caravan? | Lựa chọn người / của; uy tín phe thương nhân vs. dân làng |
| Vảy Con | Quanh Thành Hồng Sa | (Ngược với săn) Bảo vệ tổ Rồng Cát Con khỏi thợ săn trộm trong 1 đêm | Điểm đàm phán Vesskar +; vảy tự rụng làm quà |

### 6.4. BẮC — Main Quest (Level 19–24)

| # | Tên quest | Mục tiêu gameplay | Lựa chọn / Hậu quả |
|---|---|---|---|
| **Bắc 1** | **Lò Không Được Tắt** | Vào Làng Lò Sưởi, học cơ chế lạnh / bão tuyết, tham gia **đêm bão gác làng** (phòng thủ + giữ lò: chia người / tài nguyên giữa đánh wight và châm lò — lò tắt là làng thua dù đánh thắng quái). Được nghe lần đầu về "đi gác băng" như một bản án. | Phân bổ ở đêm gác: ưu tiên lò (ít loot, làng nguyên vẹn) hay ưu tiên săn wight ra ngoài bão (loot tốt, lò suýt tắt, 1 nhà bị cháy / lạnh). Flag: `bac_lo_dem_bao`. |
| **Bắc 2** | **Danh Sách Không Ai Đọc** | Ở Làng Săn Tuyết + Thành Hàn Thiết: làm quest quân sự / săn elite để đạt uy tín vào Doanh Trại Hiệp Sĩ Băng. Đánh cắp / được giao / tìm thấy **danh sách trưng thu gác băng** (tùy cách chơi: stealth, đối thoại, hay đánh). Gặp **Hiệp Sĩ Đen (Hiệp Sĩ Băng)** lần đầu trong cutscene không đánh — ông ta biết tên người chơi qua tin từ các vùng trước. | Cách lấy danh sách ảnh hưởng thái độ Hiệp Sĩ Đen ở Bắc 4: lấy bằng đối thoại / được giao → ông ta tôn trọng; đánh cắp → ông ta coi người chơi là kẻ phá kỷ luật (boss khó hơn 1 cơ chế); công bố danh sách ngay → dân Bắc náo loạn, mở đường kết cục khó nhất ở Bắc 4. Flag: `bac_lay_danh_sach_bang`. |
| **Bắc 3** | **Pháo Đài Băng Nứt** | Vào **Pháo Đài Băng Nứt** (dungeon dài nhất vòng ngoài, cơ chế lạnh tích lũy), gặp Đội Trưởng Gác Băng Đầu Tiên, thu thập danh sách tên các đời gác ấn + tên thật của Hiệp Sĩ Đen, lấy **Chìa Sắt Băng (phần trong pháo đài)**. Trên đường ra, bão tuyết lớn nhất game — sự kiện sinh tồn có đồng đội NPC tùy vùng trước. | Giải thoát / để nguyên các hiệp sĩ đóng băng có thể thaw trên đường (mỗi người tốn vật phẩm hiếm): giải thoát nhiều → phòng boss Bắc 4 ít địch hỗ trợ hơn + có nhân chứng sống; để nguyên → giữ tài nguyên cho boss, nhưng Hiệp Sĩ Đen sẽ nhắc từng người người chơi đã đi ngang mà không cứu. Flag: `bac_thaw_so_luong`. |
| **Bắc 4** | **Hiệp Sĩ Đen (Hiệp Sĩ Băng)** ⭐ Boss thành | Đối đầu ở Tường Bắc / Lò Lớn, Thành Hàn Thiết, vào ban đêm có cực quang. **Boss: Hiệp Sĩ Đen (Hiệp Sĩ Băng)** — boss người khó nhất vòng ngoài: khiên + kiếm băng, parry người chơi, phase 2 cởi mũ (lộ mặt người già mệt mỏi — không phải quái), phase 3 gọi đội gác băng (số lượng tùy `bac_thaw_so_luong`). Trước phase cuối, nếu có tên thật + danh sách đầy đủ, mở **đối thoại gọi tên** làm thay đổi kết cục. Nhận **Chìa Sắt Băng** hoàn chỉnh, mở đường vào Đất Chết. | **3 kết cục vùng:** (A) *Đánh bại / giết Hiệp Sĩ Đen* — đội gác tan rã hỗn loạn, chìa lấy được, Bắc mất chỉ huy giữa mùa bão (epilogue nặng). (B) *Thỏa thuận thay ca* — cần uy tín Bắc tối đa + danh sách + tên thật: Hiệp Sĩ Đen tự đứng xuống, đội gác được luân phiên / giải thoát dần, ông ta có thể xuất hiện ở tháp. (C) *Chỉ lấy chìa, giữ nguyên trụ* — đánh đến khi ông ta nhường đường (không kết cục đàm phán, không giết): nhanh nhất ở phase cuối, nhưng Bắc tiếp tục trưng thu — lựa chọn này bị công chúa nhắc thẳng ở Tầng 6. Flags: `bac_giet_hiep_si / bac_thoa_thuan_thay_ca / bac_giu_nguyen_tru`. |

**Quest phụ gợi ý — Bắc:**

| Tên phụ | Làng / Nơi | Nội dung ngắn | Phần thưởng / Ý nghĩa |
|---|---|---|---|
| Củi Cho Lò Người Khác | Làng Lò Sưởi | Mang củi cho nhà neo đơn ngoài làng giữa bão — đi dễ, về khó | Không loot xịn; NPC này là mẹ của một hiệp sĩ đóng băng ở Pháo Đài |
| Săn Để Không Bị Chọn | Làng Săn Tuyết | Giúp đứa trẻ săn đủ chiến tích để thoát danh sách trưng thu — hoặc tìm cách khác công bằng hơn? | Quest đạo đức về đặc quyền; ảnh hưởng danh sách ở Bắc 2 |
| Chữ Trong Cực Quang | Làng Cực Quang | Ghi lại / giải mã hình cực quang bất thường cùng thầy điềm | Lore vua + hợp đồng gốc; vật phẩm kháng băng |
| Nhà Nguyện Không Chuông | Thành Hàn Thiết | Tìm vì sao chuông nhà nguyện bị tháo (đáp án: chuông làm băng ấn nứt khi rung) | Lore cơ chế ấn bằng âm thanh; mở đường tắt trong thành |

### 6.5. THÁP VƯƠNG ẤN — Main Quest Endgame (Level 25)

| # | Tên quest | Mục tiêu gameplay | Lựa chọn / Hậu quả |
|---|---|---|---|
| **Tháp 1** | **Cổng Bốn Chìa** | Qua Đất Chết đến Trạm Gác Tro (xác nhận point of no return), vào Tầng 0, đặt 4 chìa, nghe vua lên tiếng. Vượt Tầng 1–4 (Ký Ức Đông/Nam/Tây/Bắc) với trợ giúp / khó khăn tùy trạng thái 4 vùng. | Trạng thái chìa / vùng quyết định biến thể phòng — không lựa chọn mới ở đây, đây là lúc **hậu quả cũ tự trình diện**. |
| **Tháp 2** | **Người Ghi Ấn Cuối Cùng** | Tầng 5 (Sử Ấn): đối thoại với Người Ghi Ấn, tự chọn thứ tự xem bia đá (người chơi chủ động ghép sự thật). Nghỉ / save cuối trước quyết định. | Chọn hỏi kỹ về công chúa / vua / thứ bị giam (mở thêm lựa chọn ở Tháp 3–4) hay đi thẳng (ít thông tin hơn, đối thoại sau khó hơn). Game không phạt bằng sức mạnh — phạt bằng **thiếu dữ kiện khi quyết định**. |
| **Tháp 3** | **Vật Phong Ấn Sống** | Tầng 6: gặp công chúa. Đối thoại quyết định dài. Công chúa đưa yêu cầu tùy trạng thái thế giới (xin được chết / xin được sống ngoài tháp / xin người chơi thay cô làm neo / xin người chơi đừng tin vua *và* đừng tin cả cô — biến thể theo flag). Không combat. | Cam kết / từ chối / trì hoãn yêu cầu của công chúa — mọi cam kết đều bị ghi và **bị nhắc lại nguyên văn** ở Tháp 4. Không chọn được "không hứa gì" mà không có giá: công chúa sẽ tự quyết nếu người chơi không quyết. Flag: `thap_loi_hua_cong_chua`. |
| **Tháp 4** | **Dưới Bóng Phong Ấn** ⭐ Boss cuối | Tầng 7 Đỉnh Tháp: đối đầu vua (đối thoại → đánh một phần / hoặc đồng minh tạm thời tùy lựa chọn). Xuống Giếng Ấn (ở nhánh áp dụng) gặp thứ bị giam. **Boss cuối** ở đỉnh / dưới tháp theo nhánh (xem 3.4). Sau boss: lựa chọn ending trên trục Giữ Ấn / Phá Ấn Có Kiểm Soát / Thỏa Thuận Mới / Vỡ Ấn Vô Kiểm Soát (3.6). Epilogue nhắc lại từng vùng. | Đây là tổng hợp **mọi flag của 4 vùng + lời hứa ở Tầng 6**. Không có lựa chọn ending nào bị khóa chỉ vì "chưa đủ mạnh" — chỉ bị khóa vì hành trình chưa tạo đủ điều kiện (đồng minh chết, thỏa thuận không có, tên thật không biết). Đó là thông điệp cuối của game: *kết cục được quyết định bởi cách người chơi đã sống trong thế giới, không bởi thanh máu cuối cùng.* |

**Quest phụ trong tháp:** Không có quest phụ đúng nghĩa. Thay vào đó có **phòng phụ / bia phụ** ở Tầng 1–5 (lore, vật phẩm hồi phục cuối, 1 vũ khí kỷ niệm ghép từ 4 vùng nếu người chơi mang đủ 4 vật kỷ niệm vùng — khuyến khích, không bắt buộc).

### 6.6. Nguyên tắc viết quest cho các tài liệu sau

1. Mỗi main quest phải cho **ít nhất một việc làm bằng tay** (đánh, đi, tìm, giữ, hộ tống, giải puzzle) — không main quest nào chỉ là "đi nói chuyện 3 lần".
2. Lựa chọn lớn chỉ đặt ở **cuối vùng và ở tháp** — lựa chọn nhỏ rải đều để người chơi quen với việc game ghi sổ.
3. Mọi lựa chọn đều phải có **giá nhìn thấy được trong cùng vùng** (không dồn hết hậu quả về ending — người chơi cần học luật của game sớm).
4. Không quest nào yêu cầu giết NPC vô tội để qua màn. Đường tàn nhẫn luôn là **lựa chọn**, không bao giờ là yêu cầu duy nhất — trừ bad end do chính chuỗi lựa chọn dẫn tới.

---

## 7. BẢNG ĐỐI CHIẾU NHẤT QUÁN — CHUẨN CHO DEV / PROTOTYPE

> Bảng này là **nguồn sự thật duy nhất (single source of truth)** cho tên và level. Khi tạo scene, node, resource, biến quest trong Godot, copy đúng cột "Tên chuẩn". Nếu cần đổi tên, đổi ở bảng này trước, rồi mới đổi ở code / tài liệu khác — và ghi lý do đổi.

### 7.1. Bảng đối chiếu vùng — thành — boss — level

| ID vùng (gợi ý code) | Hướng | Tên chuẩn — Thành / Khu vực chính | Tên chuẩn — Boss thành | Dải Level chuẩn | Tên chuẩn — Tháp / Khu vực cuối |
|---|---|---|---|---|---|
| `dong` | ĐÔNG | **Thành Xuân Lâm** | **Golem Rêu Cổ Thụ** | **1–6** | — |
| `nam` | NAM | **Thành Triều Ẩm** | **Phù Thủy Đầm Lầy Morvain** | **7–12** | — |
| `tay` | TÂY | **Thành Hồng Sa** | **Rồng Cát Vesskar** | **13–18** | — |
| `bac` | BẮC | **Thành Hàn Thiết** | **Hiệp Sĩ Đen (Hiệp Sĩ Băng)** | **19–24** | — |
| `trung_tam` | TRUNG TÂM | **Tháp Vương Ấn** | **Vua (đỉnh tháp) / Boss cuối (đỉnh–dưới tháp)** | **25** | **Tháp Vương Ấn** |

### 7.2. Bảng đối chiếu làng vệ tinh

| Vùng | Làng 1 | Làng 2 | Làng 3 | Ghi chú |
|---|---|---|---|---|
| ĐÔNG | **Làng Tân Diệp** ★ khởi đầu | **Làng Mạch Lúa** | **Làng Bến Mưa** | ★ = spawn point của người chơi |
| NAM | **Làng Bến Bùn** | **Làng Đèn Lồng** | **Làng Muối Đắng** | — |
| TÂY | **Làng Giếng Cạn** | **Làng Chợ Đêm** | **Làng Ốc Đảo Cát Trắng** | Tên đầy đủ có "Ốc Đảo" — không rút gọn thành "Làng Cát Trắng" |
| BẮC | **Làng Lò Sưởi** | **Làng Săn Tuyết** | **Làng Cực Quang** | — |
| TRUNG TÂM | — (chỉ có Trạm Gác Tro, không tính là làng) | — | — | Không thêm làng ở đất chết |

Tổng: **4 thành + 1 tháp, 12 làng vệ tinh**, mỗi vùng đúng 3 làng.

### 7.3. Bảng đối chiếu quái đặc trưng

| Vùng | Quái chuẩn (đúng 4 loại / vùng) |
|---|---|
| ĐÔNG | Goblin Rừng, Slime Cỏ, Sói Rừng, Golem Rêu |
| NAM | Quái Bùn, Phù Thủy Tập Sự, Quái Độc, Rắn Đầm |
| TÂY | Chiến Binh Sa Mạc, Bọ Cát, Golem Đá Đỏ, Rồng Cát Con |
| BẮC | Sói Tuyết, Hiệp Sĩ Băng, Quái Băng, Wight |
| TRUNG TÂM | Bóng Ấn (dạng xám tro của quái các vùng — không tính là quái mới) |

*Lưu ý:* Chuột Chúa (Hầm Rượu Chuột Chúa) là boss dungeon, **không** nằm trong danh sách quái đặc trưng vùng Đông ở bảng này — tránh nhầm khi làm bảng loot / bestiary.

### 7.4. Bảng đối chiếu dungeon

| Vùng | Dungeon chuẩn | Số lượng | Boss / đỉnh điểm trong dungeon |
|---|---|---|---|
| ĐÔNG | **Hầm Rượu Chuột Chúa**, **Mỏ Rêu Cổ** | 2 | Chuột Chúa; Lõi Rễ Mỏ / phân thân Golem Rêu Cổ Thụ |
| NAM | **Đền Chìm Triều** | 1 | Morvain — Giai đoạn 1 (boss hoàn chỉnh ở thành) |
| TÂY | **Lăng Cát Chôn** | 1 | Người Gác Lăng Không Tên (mini-boss) |
| BẮC | **Pháo Đài Băng Nứt** | 1 | Đội Trưởng Gác Băng Đầu Tiên (mini-boss) |
| TRUNG TÂM | **Tháp Vương Ấn** (leo tháp nhiều tầng) | 1 (endgame) | Vua / Boss cuối — xem Mục 3.4 |

### 7.5. Bảng đối chiếu phong ấn

| Hướng | Trụ chuẩn | Chìa chuẩn | Boss thành giữ / liên quan |
|---|---|---|---|
| ĐÔNG | Trụ Mộc | **Chìa Rễ Xanh** | Golem Rêu Cổ Thụ |
| NAM | Trụ Thủy | **Chìa Triều Ngọc** | Phù Thủy Đầm Lầy Morvain |
| TÂY | Trụ Sa | **Chìa Vảy Cát** | Rồng Cát Vesskar |
| BẮC | Trụ Hàn | **Chìa Sắt Băng** | Hiệp Sĩ Đen (Hiệp Sĩ Băng) |
| TRUNG TÂM | Khóa Trung Tâm | Công chúa — **vật phong ấn sống** (không phải chìa vật phẩm) | Vua / Thứ bị giam |

### 7.6. Kiểm tra nhất quán cuối tài liệu (checklist cho người duyệt)

- [x] ĐÔNG = Thành Xuân Lâm, Lv.1–6, Golem Rêu Cổ Thụ, làng Tân Diệp / Mạch Lúa / Bến Mưa — khớp ở Mục 1, 2.1, 6.1, 7.
- [x] NAM = Thành Triều Ẩm, Lv.7–12, Phù Thủy Đầm Lầy Morvain, làng Bến Bùn / Đèn Lồng / Muối Đắng, dungeon Đền Chìm Triều — khớp ở Mục 1, 2.2, 6.2, 7.
- [x] TÂY = Thành Hồng Sa, Lv.13–18, Rồng Cát Vesskar (có đường không giết), làng Giếng Cạn / Chợ Đêm / Ốc Đảo Cát Trắng, dungeon Lăng Cát Chôn — khớp ở Mục 1, 2.3, 6.3, 7.
- [x] BẮC = Thành Hàn Thiết, Lv.19–24, Hiệp Sĩ Đen (Hiệp Sĩ Băng), làng Lò Sưởi / Săn Tuyết / Cực Quang, dungeon Pháo Đài Băng Nứt — khớp ở Mục 1, 2.4, 6.4, 7.
- [x] TRUNG TÂM = Tháp Vương Ấn, Lv.25, công chúa trong tháp (vật phong ấn sống), vua ở đỉnh tháp, boss cuối ở đỉnh/dưới tháp — khớp ở Mục 1, 3, 6.5, 7.
- [x] Thứ tự tiến triển Đông → Nam → Tây → Bắc → Tháp ở mọi mục (1, 4, 5, 6).
- [x] Không vùng nào bị đổi khí hậu: Đông ôn đới/xuân, Nam nhiệt đới/đầm lầy, Tây sa mạc, Bắc hàn đới, Trung tâm đất chết.

---

## 8. PHỤ LỤC

### 8.1. Timeline tóm tắt — một đời người chơi trong thế giới

```text
Ngày 0      Trắng tay ở Làng Tân Diệp (Đông). Không ai biết người chơi là ai — kể cả người chơi.
Hồi I       Làm thuê → có uy tín → Golem Rêu Cổ Thụ → triều điên ở Nam → Morvain.
            Thế giới còn giống cổ tích, nhưng hóa đơn đầu tiên đã xuất hiện.
Hồi II      Sa mạc dạy đàm phán, Vesskar dạy rằng "quái" có thể là người gác.
            Bắc dạy rằng trụ có thể làm bằng người. Tin về vua ngày càng không giống tin đồn.
Hồi III     Vào tháp với 4 chìa và 4 bằng chứng. Công chúa không xin được "cứu" theo kiểu cổ tích.
            Vua không chờ để bị đánh bại. Thứ bị giam chờ để được nói.
Kết         Người chơi quyết định bản thỏa thuận tiếp theo của vương quốc — và ai sẽ trả giá cho nó.
```

### 8.2. Motif lặp lại có chủ ý (cho level design & art)

| Motif | Đông | Nam | Tây | Bắc | Tháp |
|---|---|---|---|---|---|
| **Thứ không được tắt** | Cổ Thụ không được héo | Đèn lồng không được tắt | Giếng / bão cát theo hơi thở rồng | Lò sưởi không được tắt | Ấn không được vỡ |
| **Danh sách tên** | Tên trên mộ bị rễ nuốt | Tên khắc dưới nước trong đền | Tên thật của người gác lăng bị xóa | Danh sách trưng thu gác băng | Bia Sử Ấn khắc tên mọi đời gác |
| **Nước / thiếu nước** | Mưa phùn thừa nước | Nước dâng giết người | Thiếu nước giết người | Nước đóng băng không dùng được | Không có nước — đất chết |

Khi làm art / level cho vùng mới, kiểm tra 3 motif này trước: nếu một vùng không chạm được vào ít nhất 2 motif, vùng đó đang rời khỏi chủ đề chung của game.

### 8.3. Việc cố ý để mở (không phải thiếu sót)

- Họ tên đầy đủ của Thống Lĩnh Caravan ở Thành Hồng Sa, Người Ghi Ấn Cuối Cùng, và điều thứ bị giam muốn trong hợp đồng gốc: để mở cho tài liệu nhân vật / lore sâu, tài liệu này chỉ chốt **chức năng** của họ để tránh mâu thuẫn.
- Quan hệ huyết thống chính xác vua–công chúa: theo GDD nhân vật chính thức khi chốt; tài liệu này chỉ chốt rằng quan hệ đó **tồn tại và là một phần động cơ của vua**, không tự đặt mới.
- Quá khứ / thân phận thật của nhân vật chính trước khi đến Làng Tân Diệp: giữ mơ hồ theo GDD v1; thế giới được thiết kế để **không cần** đáp án đó mới vận hành được, nhưng có chỗ chứa nó ở Tầng Sử Ấn nếu GDD sau này chốt.

---

*— Hết tài liệu World & Story v2: Bốn Thành, Một Tháp. Tài liệu tham chiếu gốc: GDD v1 (Dưới Bóng Phong Ấn). Mọi thay đổi tên / level sau bản này phải cập nhật Mục 7 trước. —*
