# VÙNG ĐÔNG — SƠ ĐỒ ĐA MAP (cấu trúc mới)

> **Game:** Dưới Bóng Phong Ấn (Godot 4) — Vùng Đông (Lv 1–6)
> **Cấu trúc:** Vùng Đông KHÔNG còn là 1 map gộp. Vùng gồm **8 map nhỏ nối nhau bằng portal 2 chiều** đặt ở mép map / cổng / cầu thang.
> **Quy ước portal:** dùng `systems/portal.tscn`. Map đích có `Marker2D` tên `Spawn_from_<key của map xuất phát>`; portal đặt `target_scene` + `target_spawn = "from_<key của map hiện tại>"`. Mỗi map root gắn `systems/map_root.gd`, `y_sort_enabled = true`, có sẵn Player + HUD, `Spawn_start` + đủ `Spawn_from_*`.
> **Điểm bắt đầu game thật:** `Spawn_start` ở Elmford. Các map khác `Spawn_start` trùng vị trí cổng vào chính.

---

## 1. SƠ ĐỒ KẾT NỐI (ASCII)

```text
                              CLOUDPEAK (nui_thanh_van)
                              đỉnh tuyết / đường leo zigzag
                              miệng hang ở sườn đông ──┐
                                 ▲            ▲        │
              đường mòn bắc      │            │        ▼
        ┌────────────────────────┘            │   MOSS DEN (hang_golem)
        │                          cổng bắc   │   boss: Mossback
        │                                     │        │
   ELDERWOOD                        ALDENMERE   │ cửa hang
   (rung_co_thu)                       (thanh_xuan_lam)─┘
        │                               ▲   │  ▲
        │ cổng đông              cổng bắc│   │cầu thang Nhà Trọ Liên Hoa
        ▼                               │   ▼  │
   ELMFORD ──cổng bắc──► BARLEYFIELD  ELMFORD CELLAR (ham_ruou)
   (lang_tan_diep)  ★           (dong_mach_nha) boss: The Rat King
    điểm bắt đầu                    │ cổng tây
                                    ▼
                                MISTLAKE (ho_suong)
                                Misthaven / ếch độc
```

Sơ đồ tuyến tính theo hướng địa lý:

```text
        [Moss Den]═[Cloudpeak]═[Aldenmere]═[Elmford Cellar (dưới Nhà Trọ)]
                            ║               ║
        [Elderwood]═══════╝               ║ cổng nam
              ║ cổng tây                    ▼
              ╚════[Elmford]═[Barleyfield]═[Mistlake]
                        ★ cổng bắc ▲        cổng tây ▲
```

---

## 2. BẢNG TỪNG MAP

| Map (file) | Kích thước | Điểm nhấn | NPC | Quái | Cổng đi (portal → đích, spawn ở đích) |
|---|---|---|---|---|---|
| **Elmford** `maps/lang_tan_diep.tscn` | 1800×1400 | Làng khởi đầu: nhà Trưởng làng + 6 nhà dân, giếng làng, hàng rào, ruộng lúa/lúa mì phía nam, đường đất 2 cổng | `truong_lang` (quest `dong_01_goblin`), `dan_tandiep_1` (lore) | Slime ×2 (gần ruộng) · Herb ×2 | Bắc → `dong_mach_nha` (`from_tandiep`) · Đông → `rung_co_thu` (`from_tandiep`) |
| **Barleyfield** `maps/dong_mach_nha.tscn` | 2000×1400 | 4 ô ruộng kẻ luống, kênh nước + cầu gỗ trên đường chính, làng Barleyfield nhỏ (3 nhà + kho thóc) | `nong_dan` (lore) | Rat ×4, Slime ×4 (rải ruộng) · Herb ×4 (map hái thảo chính) | Nam → `lang_tan_diep` (`from_machnha`) · Bắc → `thanh_xuan_lam` (`from_machnha`) · Tây → `ho_suong` (`from_machnha`) |
| **Mistlake** `maps/ho_suong.tscn` | 2000×1400 | Hồ lớn phía tây + nhánh bắc (toàn bộ mặt nước có collision), cầu gỗ qua nhánh kênh, làng chài phía đông (3 nhà sàn + bến thuyền + thuyền + lưới phơi) | `ngu_dan` (lore) | Ếch độc Frog ×4 (ven hồ), Slime ×2 | Đông → `dong_mach_nha` (`from_hosuong`) |
| **Aldenmere** `maps/thanh_xuan_lam.tscn` | 2200×1600 | Tường thành + cổng Nam/Bắc + 6 tháp canh, Nhà Trọ Liên Hoa, Tiệm Rèn + lò rèn, **BẢNG NHIỆM VỤ** ở quảng trường, Elder Tree lớn ở quảng trường bắc | `chu_quan` (trước nhà trọ, shop, `dong_02_ham_ruou` + `dong_03_chuot_chua` + `dong_side_herb`), `tho_ren` (tiệm rèn, `dong_side_slime`), `linh_gac` (cổng bắc, `dong_04_golem`), `linh_gac_nam` (cổng nam, lore) | Không có quái trong thành | Nam → `dong_mach_nha` (`from_thanh`) · Bắc → `nui_thanh_van` (`from_thanh`) · Cầu thang Nhà Trọ → `ham_ruou` (`from_village` — giữ nguyên phía hầm) |
| **Elmford Cellar** `maps/ham_ruou.tscn` (map cũ, chỉ sửa portal về) | ~1400×1000 | Hầm dưới Nhà Trọ Liên Hoa: thùng rượu, kho sâu | — (nhận/trả quest tại `chu_quan` ở thành) | Rat ×6, **Boss The Rat King** | Cửa hầm → `thanh_xuan_lam` (`from_cave`) |
| **Elderwood** `maps/rung_co_thu.tscn` | 2000×1600 | Rừng rậm 44 cây có collision, Elder Tree khổng lồ giữa rừng (thân r≈30, tán nhiều lớp), đường mòn uốn lượn, đá/bụi, nấm sáng | — | Goblin ×4, Slime ×3 · Herb ×3 | Tây → `lang_tan_diep` (`from_rung`) · Đường mòn Bắc → `nui_thanh_van` (`from_rung`) |
| **Cloudpeak** `maps/nui_thanh_van.tscn` | 2000×1800 | Sườn đá xám, **đường leo zigzag** hai bên vách đá chặn (chỉ đi theo đường), thông thưa dần, tuyết ở đỉnh, khoảng trống Cloudpeak Summit + biển "nơi rồng sẽ đến" (để sẵn cho boss rồng sau), miệng hang sườn đông | — | Goblin ×3 (dọc đường leo) | Chân núi Nam → `thanh_xuan_lam` (`from_nui`) · Đường mòn Tây → `rung_co_thu` (`from_nui`) · Miệng hang → `hang_golem` (`from_nui`) |
| **Moss Den** `maps/hang_golem.tscn` | 1600×1200 | Dungeon tối (CanvasModulate), 2 phòng, cột đá/thạch nhũ, rêu phát sáng + PointLight2D, sân tròn phòng cuối | — | Rat ×3, **Boss Mossback** (`enemies/boss_golem.tscn`) ở giữa sân tròn | Cửa hang → `nui_thanh_van` (`from_hang`) |

### Spawn markers từng map

| Map | `Spawn_start` | Các `Spawn_from_*` (vị trí) |
|---|---|---|
| Elmford | Giữa làng (0, 180) ★ | `from_machnha` cổng Bắc · `from_rung` cổng Đông |
| Barleyfield | Cổng Nam | `from_tandiep` cổng Nam · `from_thanh` cổng Bắc · `from_hosuong` cổng Tây |
| Mistlake | Cổng Đông | `from_machnha` cổng Đông |
| Aldenmere | Cổng Nam | `from_machnha` cổng Nam · `from_nui` cổng Bắc · `from_cave` cạnh Nhà Trọ Liên Hoa (điểm quay ra từ Elmford Cellar) |
| Elmford Cellar | Cửa hầm | `from_village` (giữ nguyên như cũ — cổng từ Nhà Trọ ở thành xuống) |
| Elderwood | Cổng Tây | `from_tandiep` cổng Tây · `from_nui` đường mòn Bắc |
| Cloudpeak | Chân núi Nam | `from_thanh` chân núi Nam · `from_rung` đường mòn Tây · `from_hang` trước miệng hang |
| Moss Den | Cửa hang | `from_nui` cửa hang |

Mọi portal đều có nhãn đọc được ngay trên cổng (ví dụ "↑ Barleyfield", "→ Moss Den", "↓ Elmford Cellar") và biển gỗ chỉ hướng đặt cạnh đường đi.

---

## 3. TUYẾN ĐI GỢI Ý (main route)

```text
Elmford ──(cổng bắc)──► Barleyfield ──(cổng bắc)──► Aldenmere
   │ nhận quest goblin          │ hái thảo (side herb)         │ nhận quest Elmford Cellar
   │                            └──(cổng tây)──► Mistlake     ▼ cầu thang Nhà Trọ
   └──(cổng đông)──► Elderwood (goblin)                   ELMFORD CELLAR ──► Boss The Rat King
                                                                 │ quay lại chu_quan trả quest
   Aldenmere ──(cổng bắc, linh_gac giao dong_04_golem)──► Cloudpeak
                                                                 │ leo zigzag lên sườn đông
                                                                 ▼ miệng hang
                                                            MOSS DEN ──► Boss Mossback
```

Thứ tự trải nghiệm dự kiến: **Elmford → Barleyfield → Aldenmere / Elmford Cellar (+ The Rat King) → Elderwood → Cloudpeak → Moss Den**, với Mistlake là nhánh phụ khám phá từ Barleyfield (ếch độc ven hồ).
