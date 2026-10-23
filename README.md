# Dưới Bóng Phong Ấn — Prototype Godot 4

Action RPG top-down fantasy, 2D pixel / 2.5D Y-Sort, phát triển solo trên **Godot 4 + GDScript**, nền tảng PC.

Project Godot nằm ở thư mục con `game/` của repo này.

## Lần đầu clone về: sinh asset trước (bắt buộc)

Repo lưu asset nhị phân (PNG) dưới dạng mã hoá base64 (file `.b64`) — xem lý do ở mục *Quy trình Git & asset* cuối file. Sau khi clone, chạy 1 lệnh để sinh lại toàn bộ PNG:

```bash
python tools/restore_assets.py
```

Chỉ cần Python 3 (thư viện chuẩn, không cài thêm gì). Chạy lại lệnh này sau mỗi lần `git pull` mà có asset mới/đổi — chạy thừa cũng không sao.

## Cách mở & chạy project

1. Cài **Godot 4.2 trở lên** (bản Standard, không cần .NET) từ https://godotengine.org/download
2. Mở Godot → **Import** → chọn file `game/project.godot` trong thư mục này → **Import & Edit**.
3. Nhấn **F5** (Run Project) trong editor. Main scene là `res://maps/world_test.tscn` (`game/maps/world_test.tscn`).
4. Bạn xuất hiện ở **khu Đông — Làng Tân Diệp**. Di chuyển ra xung quanh để gặp 3 goblin, chém hạ chúng để hoàn thành nhiệm vụ mẫu và nhận XP / vàng.
5. Phím debug ngoài input map chính: **F5 trong game = lưu** (`user://save.json`), **F9 = tải lại** — lưu ý F5 trong editor là chạy game, chỉ dùng F5/F9 khi game đang chạy.

> Camera: **Camera2D gắn vào Player** (trong `player/player.tscn`), có làm mượt (`position_smoothing`). Camera đi theo nhân vật, không phải camera cố định toàn bản đồ — bản đồ test rộng 2600×1900 nên cần đi lại mới thấy hết 4 thành và tháp.

## Phím điều khiển

| Hành động | Phím chính | Phím phụ |
|---|---|---|
| Di chuyển trái | A | ← (mũi tên trái) |
| Di chuyển phải | D | → |
| Di chuyển lên | W | ↑ |
| Di chuyển xuống | S | ↓ |
| Tấn công (combo 3 hit) | Chuột trái | J |
| Dodge / lăn (i-frame, tốn stamina) | Space | Shift |
| Skill 1 (stub) | 1 | K |
| Skill 2 (stub) | 2 | L |
| Lưu game (debug, khi đang chơi) | F5 | — |
| Tải game (debug, khi đang chơi) | F9 | — |

Di chuyển 8 hướng bằng `Input.get_vector`. Chém liên tiếp trong cửa sổ combo 0.9s sẽ đi đủ combo 3 hit (damage 10 / 12 / 18).

## Thế giới trong map test

Bản đồ test `maps/world_test.tscn` thể hiện đúng cấu trúc thế giới — Đông phải, Tây trái, Bắc trên, Nam dưới:

| Vị trí | Vùng | Thành | Màu placeholder |
|---|---|---|---|
| Trên (Bắc) | Băng tuyết | Thành Hàn Thiết | Trắng / xanh băng |
| Dưới (Nam) | Đầm lầy, rừng rêu | Thành Triều Ẩm | Xanh rêu |
| Trái (Tây) | Sa mạc | Thành Hồng Sa | Vàng cát / đỏ |
| Phải (Đông) | Rừng xuân | Thành Xuân Lâm | Xanh lá xuân |
| Giữa | Đất chết | **Tháp Vương Ấn** (vua / trùm cuối) | Xám / tím, hình tháp cao |

Xung quanh mỗi thành về sau sẽ có làng mạc; trong prototype mới có **Làng Tân Diệp** (Đông) là điểm xuất phát. Root của map bật Y-Sort (`y_sort_enabled = true`).

## Cấu trúc thư mục

```
game/
├── project.godot          # config_version=5, autoload, input map
├── icon.svg
├── autoload/
│   ├── game_state.gd      # GameState: HP/gold/xp/level/uy tín 4 vùng + signal
│   ├── save_system.gd     # SaveSystem: save/load JSON user://save.json
│   └── quest_manager.gd   # QuestManager: accept/progress/complete quest (stub)
├── player/
│   ├── player.gd          # di chuyển, combo 3 hit, dodge i-frame, HP/stamina
│   └── player.tscn        # CharacterBody2D + AttackArea + Camera2D
├── enemies/
│   ├── goblin.gd          # AI idle/chase/attack/dead, take_damage, rơi XP/gold
│   └── goblin.tscn
├── assets/
│   └── sprites/           # spritesheet PNG + SpriteFrames .tres (player/goblin)
├── maps/
│   ├── world_test.gd      # log + phím debug lưu/tải
│   └── world_test.tscn    # MAIN SCENE: 4 thành + tháp, player, 3 goblin, HUD
├── ui/
│   ├── hud.gd             # nối signal Player + GameState + QuestManager
│   └── hud.tscn           # CanvasLayer: thanh HP, stamina, gold/xp/level, quest
├── systems/               # (trống - .gitkeep) hệ thống sau: combat, inventory...
├── quests/                # (trống - .gitkeep) dữ liệu quest dạng resource sau này
└── items/                 # (trống - .gitkeep) vật phẩm / loot sau này
```

## Đã làm được (chạy được thật)

- [x] `project.godot` hợp lệ Godot 4.x: `config_version=5`, main scene trỏ đúng, 3 autoload `GameState` / `SaveSystem` / `QuestManager`, input map đủ 8 action với cả WASD + mũi tên, chuột trái, Space/Shift, 1/2 + K/L.
- [x] Player: di chuyển 8 hướng, combo chém 3 hit (Area2D hitbox + kiểm tra khoảng cách dự phòng), dodge lăn có i-frame 0.28s tốn 25 stamina, regen stamina, signal `health_changed` / `stamina_changed`, chết thì respawn stub hồi đầy máu.
- [x] Goblin mẫu: state machine idle (đi lang thang) / chase / attack / dead, phát hiện player theo khoảng cách (220), HP + `take_damage()` + knockback nhẹ, chết gọi `GameState.add_xp/add_gold` và `QuestManager.on_enemy_killed()`, chơi animation death ~0,6s rồi mới `queue_free()`.
- [x] GameState: `player_hp`, `gold`, `xp`, `level` (lên cấp tăng máu tối đa), `reputation` dạng Dictionary với khóa `dong` / `nam` / `tay` / `bac`, đầy đủ signal.
- [x] SaveSystem: lưu / tải JSON thật vào `user://save.json` bằng `FileAccess` + `JSON`, kèm `has_save()` / `delete_save()`.
- [x] QuestManager: danh sách quest dạng Dictionary, `accept_quest` / `add_quest_progress` / `complete_quest`, thưởng XP/gold/uy tín khi hoàn thành, 2 quest mẫu ở Tân Diệp (quest diệt 3 goblin tự nhận khi vào game và chạy thật).
- [x] HUD: thanh HP + stamina (ProgressBar + StyleBox), nhãn Level / XP / Vàng, nhãn nhiệm vụ đang làm — cập nhật qua signal, không polling dữ liệu (chỉ polling tìm node Player lúc khởi tạo).
- [x] Map test: 5 khu vực có nhãn đúng vị trí, tháp ở giữa, Player ở Đông gần Làng Tân Diệp, 3 goblin ở khu Đông, Y-Sort bật.
- [x] Sprite / animation pixel art thật cho Player + Goblin (vẽ bằng code PIL, xem mục Sprite / Animation bên dưới) — đã thay toàn bộ placeholder `Polygon2D` cũ; chỉ còn giữ vòng chớp `_draw()` lúc chém và bóng đổ đơn giản dưới chân.
- [x] Goblin chết chơi animation `death` rồi mới biến mất (trước đây `queue_free()` ngay); lúc chết tắt va chạm ngay để không chắn đường / không bị đánh tiếp.

## Chưa làm / đang là stub

- Skill 1 / Skill 2: chỉ tốn stamina + in log, chưa có hiệu ứng / damage riêng.
- Loot: goblin chết chỉ cộng XP/gold trực tiếp + in log, chưa rơi vật phẩm nhặt được trên đất.
- Quest thứ hai (hái thảo dược) và mọi quest ở Bắc / Nam / Tây: mới đăng ký dữ liệu, chưa có NPC giao quest, chưa có hội thoại.
- Chưa có: NPC, cửa hàng, inventory, trang bị, quái khác (rồng / golem / boss), hầm ngục, công thành, chiêu thức / phép, âm thanh, nhạc, menu chính, màn hình chết / respawn đúng nghĩa, cân bằng số liệu.
- 4 thành mới là vùng màu + nhãn trên 1 map test duy nhất, chưa tách thành scene riêng, chưa có cổng chuyển map.
- Save mới lưu GameState + Quest; chưa lưu vị trí player, inventory, trạng thái quái.

## Sprite / Animation

Asset nằm ở `game/assets/sprites/`, được sinh bằng script `tools/gen_sprites_v3.py` (Python + PIL) — sửa hình thì sửa script rồi chạy lại, đừng sửa tay file PNG. **Bản v3 — frame 128×128** (thay v2 64×64 vẫn bị chê khối vuông / shading phẳng): đổi hẳn kỹ thuật vẽ — vẽ **supersample ở 512×512** bằng hình khối thật (polygon tham số / bezier / limb có khớp), shading nhiều lớp bị clip trong từng mảng (base → bóng gradient đáy → highlight radial → rim light), chi tiết nhỏ vẽ riêng (tóc từng lọn, mắt có tròng + điểm sáng, pauldron có rãnh + đinh tán, dây đai chéo + khóa vàng, choàng có nếp gấp, kiếm có sống lưỡi + vệt chém cong; goblin có tai cong + tai trong, nanh từng chiếc, sẹo, khố vá khâu chỉ, dao có khía + đốm gỉ), rồi **downscale về 128 bằng LANCZOS** → sprite mượt kiểu HD top-down (không phải pixel khối thô). Nhân vật cao ~92px (player) / ~84px (goblin) trong frame, chân chạm đất cố định ở y=112 mọi frame. Đã qua 3 vòng xuất preview → tự soi ảnh → sửa (vòng 2: kéo dài lưỡi kiếm lúc đứng yên — v3 nháp đầu kiếm ngắn như dao găm; thu vệt chém hướng side kẻo bay khỏi frame; ép xác chết/lăn lộn nằm gọn trong frame bằng fit theo bbox; vòng 3: sửa lọn tóc sau đầu hướng up kẻo trông như bia tròn). Script cũ giữ ở `tools/gen_sprites.py` (v1) và `tools/gen_sprites_v2.py` (v2) để đối chiếu.

| File | Nội dung |
|---|---|
| `player_spritesheet.png` | Sheet player 768×1792 = lưới 6 cột × 14 hàng, frame 128×128 |
| `player_frames.tres` | `SpriteFrames` của player (53 AtlasTexture), nối sẵn trong `player.tscn` |
| `goblin_spritesheet.png` | Sheet goblin 768×1408 = lưới 6 cột × 11 hàng, frame 128×128 |
| `goblin_frames.tres` | `SpriteFrames` của goblin (44 AtlasTexture), nối sẵn trong `goblin.tscn` |

Ảnh xem trước: `design/sprite_preview_v3.png` gồm (a) toàn bộ 2 sheet ở size thật + khung frame, (b) các pose chính ở đúng size 128 và thu nhỏ 64 trên nền cỏ, (c) mockup ghép player + 2 goblin trên nền cỏ giống map (bản riêng: `design/sprite_mockup_v3.png`; bản sao preview mới nhất ở `design/sprite_preview.png`).

**Hiển thị trong game:** node `AnimatedSprite2D` để `scale 0,75` (player) / `0,72` (goblin) và `texture_filter = Linear` (2) — nhân vật hiển thị ~66–69px, không phình gấp đôi theo frame 128; vị trí node đã chỉnh để chân khớp bóng đổ / collision như bản cũ.

**Quy ước hướng:** chỉ vẽ 3 hướng `down` / `up` / `side` (side = nhìn sang phải); hướng trái dùng `flip_h` tự động trong code. Mỗi hàng của sheet là 1 animation, frame xếp từ cột 0.

**Player** — lính đánh thuê: tóc nâu có mái + vòng trán thép gắn ngọc teal, giáp thép xanh xám (pauldron có rãnh chia lá, dây đai chéo da + khóa vàng, găng thép, bốt da), áo choàng teal có nếp gấp + viền sáng, kiếm thép có sống kiếm và chặn vàng.

| Animation | Frame | FPS / lặp | Nối vào trạng thái |
|---|---|---|---|
| `idle_down/up/side` | 3 | 4, lặp | Đứng yên (nhịp thở nhẹ) |
| `walk_down/up/side` | 6 | 10, lặp | Di chuyển (ưu tiên theo `facing`) |
| `attack_down/up/side` | 4 (giơ kiếm → thủ thế → vung có vệt kiếm → thu) | 14, không lặp | Bấm chém — chạy ngay khi bấm, damage vẫn theo hitbox cũ, không chờ frame animation |
| `dodge_down/up/side` | 3 (cúi thấp có vệt tốc độ → lộn 2 nhịp) | 12, không lặp | Dodge/lăn, sprite mờ 0,55 trong i-frame |
| `hurt` | 2 (mắt X, frame 2 nhuốm đỏ) | 8, không lặp | `take_damage()` + flash đỏ 0,12s |
| `death` | 3 (gục → ngã nằm → mờ dần) | 5, không lặp | HP về 0, hiện 0,6s trước respawn stub |

Thứ tự ưu tiên animation trong `player.gd`: `death > dodge > attack > hurt > walk > idle`.

**Goblin** — da xanh nhiều tông có đốm bẩn, tai nhọn cong có tai trong sẫm, mắt vàng có tròng dọc, nanh trắng, bụng phệ sáng, khố/áo rách nâu có miếng vá khâu chỉ, dao gỉ có sống dao + đốm gỉ cam; khác player rõ ở size in-game. Animation: `idle_*` 3 frame, `walk_*` 6 frame (chase chạy tốc độ thường, đi lang thang ở IDLE chạy `speed_scale 0,45`), `attack_*` 4 frame, `hurt` 2 frame, `death` 3 frame — chết thì tắt collision ngay, chơi hết `death` (~0,6s) mới `queue_free()`.

**Cách thay sprite thật sau này:**
1. Giữ nguyên kích thước frame 128×128, lưới hàng = animation / cột = frame, và đúng tên animation trong bảng trên (code chỉ gọi theo tên này).
2. Cách dễ nhất: vẽ sheet mới đè lên đúng vị trí hàng/cột như sheet cũ (thứ tự hàng khai báo trong `tools/gen_sprites_v3.py`: idle, walk, attack, dodge cho player; idle, walk, attack cho goblin; cuối là hurt, death) rồi import lại — `.tres` không cần sửa nếu giữ nguyên số frame từng hàng; đổi số frame thì chạy lại script hoặc sửa `.tres`.
3. Nếu vẽ bằng file rời theo từng animation: tạo `SpriteFrames` mới trong editor, đặt tên animation y hệt, gán vào node `AnimatedSprite2D` trong `player.tscn` / `goblin.tscn`; sprite v3 là art mượt (downscale LANCZOS) nên để `texture_filter = Linear` — chỉ dùng `Nearest` nếu thay bằng pixel art thật. Nhớ giữ tỉ lệ hiển thị: frame 128 hiển thị ở scale ~0,75.
4. Mọi lần phát animation trong code đều kiểm tra `has_animation()` trước — thiếu/sai tên animation thì game vẫn chạy, chỉ mất hình động, không crash.

**Còn thiếu:** animation chém riêng cho từng hit của combo (hiện 3 hit dùng chung 1 animation attack), animation skill 1/2, sprite + animation cho NPC và các quái/boss khác, hiệu ứng hạt (particles) khi chém trúng, animation mở rương / nhặt loot.

## Lộ trình

### 1. Prototype — ✅ bản này
**Tiêu chí hoàn thành:** Mở project bằng Godot 4, F5 chạy không lỗi; di chuyển / chém combo / dodge được; giết được goblin, nhận XP/gold, hoàn thành được 1 quest; HUD hiển thị đúng; lưu / tải được. → **Đã đạt** (kiểm chứng headless, xem mục Kiểm tra bên dưới).

### 2. Vertical Slice
Một vùng chơi hoàn chỉnh đại diện cho game thật: khu Đông hoàn thiện.
- [ ] Scene riêng cho Thành Xuân Lâm + Làng Tân Diệp (tilemap / sprite thật, nhà cửa, cổng thành), NPC giao / trả quest có hội thoại đơn giản.
- [ ] Ít nhất 3 quest ở Đông chạy trọn vòng: nhận → làm → trả → nhận thưởng + tăng uy tín vùng Đông.
- [ ] Inventory tối thiểu + 1 loại loot rơi trên đất nhặt được, 1 cửa hàng mua / bán bằng vàng.
- [ ] Thêm 1 loại quái thứ hai + 1 mini-boss ở Đông, skill 1 thành kỹ năng thật có damage / hiệu ứng.
- [ ] Lưu / tải đầy đủ gồm vị trí player và tiến trình quest; menu chính + tạm dừng.
**Tiêu chí:** Người chơi mới vào chơi liền 20–30 phút ở khu Đông không cần dùng phím debug, không lỗi chặn tiến trình.

### 3. Alpha
Đủ 4 thành + tháp, toàn bộ vòng lặp chính có mặt dù chưa bóng bẩy.
- [ ] 4 vùng Đông / Nam / Tây / Bắc đều vào được, mỗi vùng có thành, làng, khí hậu / màu sắc riêng, quái riêng và chuỗi quest tăng uy tín riêng; đủ uy tín mới mở đường vào vùng tiếp theo / tháp.
- [ ] Hầm ngục đầu tiên, boss vùng đầu tiên, hệ thống trang bị + kỹ năng đầy đủ bản đầu.
- [ ] Cốt truyện chính chạy từ đầu đến khi mở cổng Tháp Vương Ấn (chưa cần mọi nhánh / twist hoàn chỉnh).
**Tiêu chí:** Chơi được từ tạo nhân vật đến cổng tháp trên một lượt save, mọi hệ thống chính đều tồn tại và dùng được.

### 4. Beta
Đóng băng nội dung, tập trung sửa lỗi và cân bằng.
- [ ] Đủ mọi boss kể cả trùm cuối ở Tháp Vương Ấn, twist cốt truyện về công chúa và nhà vua hoàn chỉnh, có ending.
- [ ] Không còn tính năng mới; cân bằng damage / XP / kinh tế vàng / uy tín cả 4 vùng; tối ưu hiệu năng PC.
- [ ] Test save tương thích, test chơi dài hạn, sửa toàn bộ lỗi mức chặn / nghiêm trọng.
**Tiêu chí:** Chơi trọn game từ đầu đến ending không lỗi chặn, không placeholder lộ rõ với người chơi.

### 5. Release
- [ ] Build PC (Windows, cân nhắc Linux) qua Export Preset của Godot, kiểm tra trên máy sạch chưa cài Godot.
- [ ] Trang giới thiệu / hướng dẫn phím, số phiên bản, ghi chú phát hành.
**Tiêu chí:** File build chạy độc lập, hoàn thành được toàn bộ game, save ổn định sau khi đóng / mở lại.

## Kiểm tra bản prototype này

- Máy build không cài sẵn Godot trong PATH, nên đã tải **Godot 4.2.2 stable (Linux x86_64)** về thư mục tạm để kiểm tra thật:
  - `godot --headless --path game --check-only --quit` → **exit 0**, không lỗi script / scene; log cho thấy QuestManager nhận quest, World load, Player spawn đúng thông điệp thiết kế.
  - `godot --headless --path game --quit-after 120` → **exit 0**; trong 120 frame goblin đã tự đuổi theo và đánh trúng player (HP 100 → 92), chứng minh AI chase/attack và `take_damage` hoạt động đầu-cuối.
- Kiểm tra tĩnh bổ sung: mọi `ext_resource` trong các file `.tscn` đều trỏ tới file tồn tại, tên action trong code (`move_*`, `attack`, `dodge`, `skill_*`) khớp chính tả với input map trong `project.godot`, tên autoload khớp mọi nơi.
- Kiểm tra đợt thêm sprite/animation (cùng Godot 4.2.2 headless, sau khi `--import`): `--check-only` → **exit 0**, không lỗi. Chạy scene test tự động `game/tests/anim_test.tscn` (175 physics frame) → **exit 0, 13/13 check PASS**: player đứng yên = `idle_down`, đi phải = `walk_side`, bấm chém thấy `attack_*`; goblin chase rút khoảng cách 150 → 90 và chạy `walk_*`; goblin chết còn xác + chơi `death` + tắt collision ở +10 frame, biến mất ở +80 frame. Chạy main scene 300 frame → **exit 0**, goblin vẫn đuổi và đánh trúng player như trước (HP 100 → 68).
- Kiểm tra đợt vẽ lại sprite v2 (cùng Godot 4.2.2 headless): `--import` → exit 0, `--check-only` → **exit 0**; scene test `game/tests/anim_test.tscn` → **13/13 PASS, 0 FAIL** (giữ nguyên kết quả như v1 vì chỉ thay hình, không đổi tên animation / logic); main scene 300 frame → **exit 0, 0 lỗi**, goblin vẫn đánh trúng player (HP 100 → 68). Chất lượng hình đã tự soi qua `design/sprite_preview_v2.png` 3 vòng (xem mục Sprite / Animation).
- Kiểm tra đợt vẽ lại sprite **v3 — 128×128** (cùng Godot 4.2.2 headless, sau khi `--import`): `--check-only` → **exit 0**; scene test `game/tests/anim_test.tscn` → **exit 0, 13/13 PASS, 0 FAIL** (tên animation giữ nguyên, chỉ tăng số frame walk 6 / attack 4 / death 3 và đổi grid `.tres` sang 128); main scene 300 frame → **exit 0**, goblin vẫn đuổi và đánh trúng player (HP 100 → 68). Chất lượng hình đã tự soi qua `design/sprite_preview_v3.png` + `design/sprite_mockup_v3.png` 3 vòng (xem mục Sprite / Animation).

## Quy trình Git & asset

- Code, tài liệu, script — mọi file văn bản — đi qua GitHub bình thường: phía Muse `push`, người chơi `git pull` là nhận đủ.
- Asset nhị phân (PNG, sau này là nhạc .ogg, hiệu ứng .wav...): kênh push của Muse chỉ nhận file văn bản, nên asset được lưu kèm bản base64 `<tên-file>.b64` ngay cạnh file gốc (sinh bằng `tools/encode_assets.py`, thêm asset mới thì thêm đường dẫn vào script đó).
- `tools/restore_assets.py` giải mã mọi `.b64` trong repo thành file gốc đúng vị trí, kiểm chứng khớp 100% theo hash. Nhờ vậy pull về là có đủ asset, không thiếu file nào.
- Giới hạn hiện tại: mỗi lần push tổng dung lượng văn bản ~16MB — đủ cho sprite/âm thanh ngắn; asset rất nặng (nhạc dài, video) sẽ cần kênh riêng khi tới lúc.
