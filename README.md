# Dưới Bóng Phong Ấn — Godot 4 Action RPG (Prototype)

Game action RPG top-down fantasy trung cổ châu Âu, làm bằng **Godot 4.2 + GDScript**.
Bản hiện tại: **Phần 1 — vùng Đông (lãnh địa Aldenmere)** ở quy mô prototype hoàn chỉnh:
vòng chơi khép kín từ menu → đoạn mở đầu → tuyến giải phóng → boss cuối phần → màn hình kết Phần 1.
Đây KHÔNG phải bản full theo GDD (tầm nhìn 22–26 giờ cho bản thương mại) — bản này chơi vài chục phút.

## Lần đầu clone về: sinh asset trước (bắt buộc)

Repo lưu asset nhị phân (PNG) dưới dạng mã hoá base64 (file `.b64`) — xem mục *Quy trình Git & asset* cuối file. Sau khi clone/pull, chạy:

```bash
python tools/restore_assets.py
```

Chỉ cần Python 3 (thư viện chuẩn). Chạy lại sau mỗi lần pull có asset mới cũng không sao.

## Câu chuyện Phần 1

Bạn là lính đánh thuê trắng tay đến **Elmford**, ngôi làng đang bị lính thuế của
**King Aldric, the Puppet King** — vị vua bù nhìn bị **Sigilspire** (tháp phong ấn ở trung tâm thế giới)
thao túng — chèn ép. Gia nhập kháng chiến ngầm, gây dựng uy tín qua các làng, phá trạm thuế
**Stonebridge**, giải phóng phu ở **Bluestone Mine**, theo **Aldenmere Sewers** đột nhập hoàng cung
và hạ King Aldric để giải phóng Aldenmere. Cuối phần, cổng tường thành phía Nam mở ra (Phần 2 — Fenmire, chưa làm).

Bốn vùng đất bị chia cắt bởi **tường thành khổng lồ**, chỉ qua lại được ở cổng có lính canh:
Aldenmere (Đông) · Fenmire (Nam) · Solmaris (Tây) · Frostgard (Bắc) — 3 vùng sau mới có sơ đồ/khung, chưa làm nội dung.

## Cách chơi (từ đầu đến hết Phần 1)

1. Mở game → **Menu chính** → *Chơi mới* → xem đoạn giới thiệu ở Elmford.
2. Gặp **Trưởng làng Elmford** (phím **E**) nhận quest `dong_01` → ra **Barleyfield** diệt 3 goblin → về trả quest.
3. Nhận `dong_02` dọn chuột trong **Elmford Cellar** (cổng xuống hầm ngay trong làng) → `dong_03` hạ boss **The Rat King**.
   Xong bước này là **hết đoạn mở đầu**: cổng phía đông làng và cổng bắc Barleyfield mở ra.
4. Tuyến giải phóng: lên núi hạ **Mossback, the Moss Golem** (`dong_04`, nhận Chìa Rễ Xanh) →
   phá trạm thuế Stonebridge (`dong_05`) → diệt sơn tặc cứu phu mỏ (`dong_06`, mở đường cống ngầm) →
   qua Aldenmere Sewers vào **Royal Palace of Aldenmere** → boss cuối **King Aldric, the Puppet King** (`dong_07`).
5. Hạ boss → màn hình **kết Phần 1** tổng kết theo việc bạn đã làm (phá trạm thuế? đi đường cống? hạ Mossback? uy tín...) → *Chơi tiếp* tự do, cổng Nam ở Elmford đã mở (hiện là khung chờ Phần 2).

Quest phụ: hái 4 thảo dược quanh làng (`dong_side_herb`), diệt slime cho thợ rèn (`dong_side_slime`).
Mua **Bình máu (10 vàng)** ở chủ quán/shop, bấm **H** để uống hồi 50 HP.

## Phím điều khiển

| Phím | Hành động |
|---|---|
| WASD / phím mũi tên | Di chuyển 8 hướng |
| J / chuột trái | Đánh (combo 3 đòn) |
| Space / Shift | Né (dodge, có i-frame) |
| E | Tương tác / nói chuyện / nhặt đồ |
| H | Uống bình máu |
| F5 / F9 | Lưu / tải game (khi đang chơi) |

## Cách mở & chạy project

1. Cài **Godot 4.2 trở lên** (bản Standard) từ https://godotengine.org/download
2. Chạy `python tools/restore_assets.py` (mục đầu file) để sinh PNG.
3. Mở Godot → **Import** → chọn `game/project.godot` → **Import & Edit** → **F5**. Main scene là `game/ui/main_menu.tscn`.
4. Camera đi theo Player (Camera2D gắn trong player, có làm mượt).

## Bản đồ Phần 1 (16 map + 1 khung)

Sơ đồ kết nối đầy đủ: `design/vung_dong_so_do.md`. Tên file scene giữ slug cũ (mã nội bộ), tên hiển thị trong game là tên mới.

**Đã dùng tileset mẫu kiểu Stardew (TileMap + prop, bộ `assets/tilesets/` + `assets/props/`):**
- `lang_tan_diep` — **Elmford** (làng khởi đầu)
- `dong_mach_nha` — **Barleyfield** (ruộng + thôn)
- `ham_ruou` — **Elmford Cellar** (nội thất, tileset interior quán rượu)

**Khung kỹ thuật chờ asset (gameplay/collision/cổng/NPC/quái thật; hình ảnh là nền phẳng + va chạm vô hình, KHÔNG phải art cuối):**
`bo_song_thanh` (Stonebridge), `rung_co_thu` (Elderwood), `tim_rung` (Heartwood), `ho_suong` (Mistlake + làng chài Misthaven),
`mo_da_xanh` (Bluestone Mine), `hang_golem` (Moss Den), `nui_thanh_van` (Cloudpeak — Sườn), `deo_thanh_van` (Cloudpeak Pass),
`dinh_thanh_van` (Cloudpeak Summit), `ngoai_thanh` (The Wallfoot), `thanh_xuan_lam` (Aldenmere — khung gọn hiện tại;
thiết kế thành đầy đủ xem `design/thanh_xuan_lam_layout.md` + `.png`, đang chờ duyệt bố cục), `cong_ngam` (Aldenmere Sewers),
`hoang_cung` (Royal Palace of Aldenmere), `cong_nam_khung` (Cổng Nam — khung sang Phần 2).

## Hệ thống

- **Thật:** di chuyển/combo/dodge của player; 15 loại quái vùng Đông (goblin, chuột cống, slime, ếch độc, sói, lợn rừng, nhện bắn độc,
  bù nhìn ma, sơn tặc, lính vua có khiên, thạch linh, wyvern non, Heartwood Treant) + 3 boss (The Rat King 2 phase gọi đàn,
  Mossback — slam + kháng, King Aldric 2 phase lộ bản chất con rối: gọi lính, bắn shadow bolt); NPC hội thoại theo trạng thái quest;
  shop bình máu; tuyến quest chính 7 + 2 phụ; uy tín vùng; chìa phong ấn; save/load JSON + autosave theo map; menu chính; màn hình kết phần.
- **NPC sống (mới):** engine lịch trình `schedule` trong `systems/npc.gd` — NPC đi theo điểm hẹn (toạ độ + hành động + thời lượng),
  làm việc với anim `work`, nghỉ, lặp vòng, cấu trúc sẵn sàng gắn giờ giấc sau này; đang làm việc vẫn nói chuyện được
  (dừng việc, quay mặt về người chơi, xong làm tiếp). Đã có sprite việc làm vẽ theo pipeline v3: thợ rèn gõ búa ở đe,
  nông dân cuốc đất, lính tuần cầm giáo/khiên (`game/assets/sprites/tho_ren_frames.tres`, `nong_dan_frames.tres`, `linh_tuan_frames.tres`).
  Gắn lịch trình cụ thể cho NPC trong map sẽ làm khi dựng lại Aldenmere theo layout mới được duyệt.
- **Sprite nhân vật/quái:** vẽ bằng generator Python (`tools/gen_sprites_v3.py` và các `gen_*_sprites.py`): vẽ supersample 512 rồi downscale 128, frame 128×128, quy ước 3 hướng down/up/side (trái = flip). Sửa hình thì sửa script rồi chạy lại, đừng sửa tay PNG.
- **Gọn/stub:** đá lăn ở Cloudpeak Pass mới là đá tĩnh + biển cảnh báo; player chết = hồi máu tại chỗ (chưa có màn hình chết/phạt vàng);
  "Tiếp tục" dựa vào autosave khi vào map; skill 1/2 vẫn là stub; cân bằng số liệu ở mức chơi được, chưa tinh chỉnh kỹ.

## Kiểm tra (headless, Godot 4.2.2)

```bash
godot --headless --path game --check-only --quit                 # exit 0
godot --headless --path game res://tests/opening_test.tscn        # chuỗi mở đầu: 42 PASS
godot --headless --path game res://tests/systems_test.tscn        # 43 PASS
godot --headless --path game res://tests/npc_smoke_test.tscn      # 10 PASS
godot --headless --path game res://tests/npc_schedule_test.tscn   # 9 PASS
godot --headless --path game res://tests/monster_pack_test.tscn   # 85 PASS
godot --headless --path game res://tests/boss_vua_test.tscn       # 68 PASS
godot --headless --path game res://tests/anim_test.tscn           # 13 PASS
python3 tools/validate_maps.py                                    # 18 scene, 38 portal, 0 lỗi liên kết
```

## Tài liệu thiết kế

- `design/world_v2_4_thanh.md` — thế giới 4 vùng + tháp Sigilspire, boss/quest từng vùng (tên hiển thị đã cập nhật tên Âu).
- `design/vung_dong_so_do.md` — sơ đồ 16 map Phần 1 + trạng thái từng map.
- `design/cot_truyen_4_phan.md` — cốt truyện 4 phần, mỗi vùng một cơ chế giải phóng khác nhau (đột nhập / điều tra + lựa chọn đạo đức / liên minh bộ lạc + đấu trường / giải thoát linh hồn) để không lặp công thức.
- `design/thanh_xuan_lam_layout.md` + `.png` — thiết kế **Aldenmere** chuẩn "Mondstadt 2D": tường 2 lớp + tháp canh + mặt tường đi được, quảng trường tượng + đài phun, chợ 18 sạp, khu dân cư dày với hẻm 1 ô (có hẻm cụt giấu miệng cống), khu nghề/quân sự, nội thành thượng, 17 NPC có lịch trình — **chờ duyệt bố cục trước khi dựng scene**.

## Quy trình Git & asset

- Code, tài liệu, script — mọi file văn bản — đi qua GitHub bình thường: phía Muse `push`, người chơi `git pull` là nhận đủ.
- Asset nhị phân (PNG, sau này nhạc/hiệu ứng): kênh push chỉ nhận file văn bản, nên asset được lưu kèm bản base64 `<tên-file>.b64` cạnh file gốc (sinh bằng `tools/encode_assets.py`; thêm asset mới thì thêm đường dẫn vào `ASSET_FILES` trong script đó).
- `tools/restore_assets.py` giải mã mọi `.b64` thành file gốc đúng vị trí, kiểm chứng khớp hash. Pull về chạy 1 lệnh là đủ asset.
- Giới hạn: mỗi lần push tổng dung lượng văn bản ~16MB — đủ cho sprite/tileset hiện tại; asset rất nặng sẽ cần kênh riêng khi tới lúc.

## Đợt 6 — KHÉP GAME (Sigilspire + kết game + crafting cơ bản)

- **Sigilspire (Lv 25):** 7 map mới — `dat_chet` (Đất Chết Trung Tâm + Trạm Gác Tro) → `sigilspire_base` (Tầng 0 Cổng Bốn Chìa) → `sigilspire_f1` (Tầng 1–2, mini-boss Hồi Âm Của Morvain) → `sigilspire_f2` (Tầng 3–4, Hồi Âm Của Hiệp Sĩ Đen) → `sigilspire_f5` (Tầng 5 Sử Ấn) → `sigilspire_f6` (Tầng 6 — Công chúa Seraphine) → `sigilspire_summit` (Tầng 7 — boss cuối + Bệ Phong Ấn). Cổng tháp khóa flag `sigilspire_open` (đủ 4 seal key). Sơ đồ: `design/sigilspire_so_do.png` + `.md`.
- **Twist trong game:** Seraphine là VẬT PHONG ẤN SỐNG (quest `thap_03`, flag `seraphine_truth`); cổng lên đỉnh chỉ mở sau khi nghe cô nói hết. Boss cuối **Vua Trên Đỉnh — Kẻ Kéo Dây Rối** (HP 4500, 3 phase: loạt đạn 3/5/7, gọi lính gác + bóng ấn, Vòng Ấn Vỡ báo trước ở phase 3).
- **3 ENDING thật** tại Bệ Phong Ấn (`ui/final_ending_panel.tscn`, quest `thap_05a/b/c`): Phong Ấn Mới / Phá Ấn / Thay Thế. Epilogue đọc flags hậu quả thật của 4 vùng (Nam mất người/nghèo đi, Tây Vesskar sống/chết, Bắc siêu thoát/vất vưởng, Đông trạm thuế...). Chọn xong: lưu `game_completed` + `ending_id` vào save; chơi tiếp tự do (post-game free roam) hoặc về menu.
- **4 skill cuối làm thật** (trang skill 2, phím **Q** lật trang, phím 1–4): Triệu Hồi Bóng (bóng đồng minh 20s, 80% dmg), Cổng Phong Ấn (dịch chuyển 220px xuyên vật cản mỏng, chặn kín thì không tốn STA/CD), Khiên Ma Thuật (khiên 40+4×Lv HP trong 8s), Mưa Thiên Thạch (5 đợt AoE). Bị động **Da Sắt** làm thật (−15% damage nhận vào sau DEF).
- **Crafting MỨC CƠ BẢN:** kho nguyên liệu (Thảo từ nhặt/rơi, Lõi Quái rơi từ quái — elite chắc chắn rơi), 4 công thức (Bình Máu Từ Thảo, Đại Bình Hồi Phục hồi 150 chỉ có bằng chế, Kiếm Lõi Quái +6 ATK, Giáp Da Bóng +4 DEF — 2 món đồ duy nhất chế 1 lần), UI `ui/craft_panel.tscn` mở tại CraftStation ở 5 hub: Elmford, Reedmere, Sunwell Oasis, Hearthwick, Trạm Gác Tro. Phím H ưu tiên dùng Đại Bình khi máu hụt ≥ 90.
- **Test đợt 6:** `final_skill_test` (37 PASS), `crafting_test` (39 PASS), `part5_chain_test` (67 PASS — gồm cả 3 ending + gate 4 chìa). Toàn suite 24/24 xanh; `validate_maps.py`: 50 scene, 113 portal, 0 lỗi.
- **Chưa làm (polish tồn đọng):** 3 nội thành Fenmire/Solmaris/Frostgard (chờ user duyệt layout); sprite riêng cho quái Nam/Tây/Bắc + quái tháp (đang tái dùng frames + tint); polish tileset các vùng; cơ chế lạnh tích lũy vùng Bắc; wave-defense bac_03 đúng nghĩa; panel kết thúc Phần 2 riêng.
