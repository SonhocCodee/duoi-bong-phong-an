# Tileset mẫu v1 — Ghi chú bàn giao

Chuẩn tham chiếu: Stardew Valley (pixel mềm, palette dịu, có bóng đổ, chuyển tiếp tile mượt).
Generator: `tools/gen_tileset_v1.py` (chạy `python3 tools/gen_tileset_v1.py` để sinh lại toàn bộ).
Kỹ thuật: vẽ supersample 4x bằng PIL (texture hạt wrap-around, shading nhiều lớp, profile biên
lượn sóng dùng chung cho tile chuyển tiếp) → downscale LANCZOS + unsharp về 64px.

## Kích thước
- Tile: **64×64 px**. Mọi atlas đều RGBA, kích thước chia hết cho 64.
- Prop: PNG riêng, nền trong suốt, kích thước ghi ở bảng dưới (không theo lưới tile — đặt tự do theo chân vật thể).

## Tileset ngoài trời — `game/assets/tilesets/exterior_v1.png` (512×192, lưới 8×3) + `exterior_v1.tres`
Thứ tự tile (cột:hàng trong atlas):
- Hàng 0: `grass` cỏ trơn · `grass_flower` cỏ có hoa · `grass_tall` cỏ cao · `grass_sparse` cỏ thưa lộ đất ·
  `dirt` đất trơn · `field` đất ruộng có luống + mầm · `water_a`/`water_b` nước 2 pha gợn sóng
- Hàng 1: `path_s` cỏ trên/đất dưới · `path_n` đất trên/cỏ dưới · `path_w` đất trái/cỏ phải · `path_e` cỏ trái/đất phải ·
  `path_corner_convex` đất góc dưới-phải (lồi) · `path_corner_concave` đất gần kín, cỏ lõm góc trên-trái ·
  `shore_s` cỏ trên/nước dưới · `shore_n` nước trên/cỏ dưới
- Hàng 2: `shore_w` nước trái/cỏ phải · `shore_e` cỏ trái/nước phải · `shore_corner` nước góc dưới-phải ·
  `fence_h` rào ngang · `fence_v` rào dọc · `pebbles` sỏi trên cỏ · `grass_dark` cỏ tối (dưới bóng cây) · `sand` cát

Quy ước ghép đường: đường ngang 1 tile = `path_s` (hàng trên) + `path_n` (hàng dưới);
đường dọc 1 tile = `path_e` (tile trái) + `path_w` (tile phải). Mọi tile chuyển tiếp dùng chung một
profile biên nên khớp nhau ở cạnh; tile nền đã kiểm tra lệch màu ở mép ghép ≈ 2–6/255 (gần như không lộ mối nối).

## Prop ngoài trời — `game/assets/props/`
| File | Kích thước | Ghi chú |
|---|---|---|
| `oak.png` | 208×216 | Sồi lớn, cao ~3 tile, tán nhiều lớp, bóng mềm ở gốc |
| `small_tree.png` | 128×152 | Cây ăn quả nhỏ, có quả đỏ |
| `bush.png` | 96×76 | Bụi cây có quả tím |
| `house.png` | 320×264 | Nhà gỗ–đá nguyên căn ~5×4 tile: mái ngói, khung gỗ, cửa vòm, 2 cửa sổ sáng đèn + bậu hoa, ống khói có khói, móng đá |
| `well.png` | 116×118 | Giếng đá, mái nhỏ, trục quay + gàu |
| `barrel.png` | 46×54 | Thùng gỗ 2 đai sắt |
| `sack.png` | 48×50 | Bao tải buộc dây |
| `boulder.png` | 84×66 | Cụm đá tròn có rêu |

## Tileset nội thất quán rượu — `game/assets/tilesets/interior_tavern_v1.png` (256×128, lưới 4×2) + `.tres`
- Hàng 0: `floor_a` sàn ván ngang · `floor_b` sàn ván dọc · `floor_dark` sàn ván tối · `wall_plank` tường ván + xà ngang
- Hàng 1: `wall_stone` tường đá · `stone_floor` sàn đá phiến · `rug` thảm đỏ hoa văn thoi · `floor_c` sàn ván (biến thể tông)

Prop nội thất (cùng thư mục `props/`): `table.png` 168×118 (bàn + 4 ghế + cốc bia + nến) ·
`bar.png` 232×92 (quầy bar + chai/cốc) · `fireplace.png` 152×148 (lò sưởi đá, lửa 4 lớp + hào quang) ·
`lamp.png` 64×84 (đèn treo có hào quang) · `shelf.png` 104×72 (kệ 2 tầng đầy chai) ·
`wine_barrel.png` 52×60 (thùng rượu, dùng lại họ thùng gỗ).

## Cách dùng trong Godot
1. Import `exterior_v1.tres` / `interior_tavern_v1.tres` làm TileSet cho TileMapLayer nền
   (đã khai sẵn atlas source, region 64×64). Đặt `texture_filter = Nearest` nếu muốn giữ nét
   pixel, hoặc Linear nếu muốn giữ độ mượt hiện tại — bộ này vẽ theo hướng mượt, khuyến nghị Linear.
2. Prop là Sprite2D/Node2D riêng: bật Y-sort ở root map, đặt `offset` sao cho điểm neo ở **chân**
   vật thể (gốc cây, chân tường nhà); thứ tự vẽ theo y của chân → nhân vật đi sau cây/nhà sẽ bị che đúng.
   Bóng đổ đã vẽ sẵn trong prop, không cần thêm node bóng.
3. Va chạm: thêm StaticBody2D theo chân vật thể (thân cây ~24px, nhà theo hình chữ nhật tường,
   giếng ~64px) — tileset chỉ lo hình ảnh.
4. Nước/đường là tile nền thuần, không Y-sort.

## Còn thiếu để dựng Elmford hoàn chỉnh
- Nhà biến thể (nhà nhỏ 3×3, quán trọ 2 tầng, nhà thợ rèn có lò + ống khói lớn), cổng làng/biển hiệu.
- Cây biến thể (sồi trụi lá, thông, cây cổ thụ thật to làm điểm nhấn), hoa/bụi theo mùa, cỏ 3–4 biến thể nền nữa để đỡ lặp.
- Tile: cầu gỗ qua suối, bờ nước góc lõm (concave), vách đá/vực (cho map núi), đường mòn cỏ (path trên cỏ nhạt), đất ướt bờ sông.
- Nội thất: giường/tủ/kệ sách cho nhà dân, bếp + nồi, cầu thang, cửa ra vào trong nhà, tường góc trong (inner corner).
- Animation: nước chảy (đã có 2 pha — cần TileSet animated tile hoặc shader), khói ống khói, lửa lò sưởi (hiện là ảnh tĩnh).

## Tự đánh giá nhanh
Đạt: ghép tile liền, không lộ mối nối rõ; nhà/cây/giếng/quầy bar/lò sưởi đọc hình ngay; palette
thống nhất, dịu. Chưa đạt chuẩn vẽ tay chuyên nghiệp: cỏ nhìn gần vẫn hơi "hạt", biên đường lượn
sóng đều theo chu kỳ 1 tile (đi dài sẽ thấy nhịp), mái ngói nhìn xa thành sọc ngang hơn là từng
viên ngói, tán cây còn dạng cụm blob hoạt hình. Đây là mẫu để duyệt hướng art + tích hợp thử,
không phải asset final.
