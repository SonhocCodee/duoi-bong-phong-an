extends Control
## Minimap - Ban do thu nho ve tu du lieu TileMap THAT cua map dang choi.
## Cach lam (nhe, on dinh):
##   - rebuild(root) chi chay khi DOI MAP (hoac khi quest thay doi, de cap
##     nhat cham quest): duyet moi TileMap trong scene, lay o da dung
##     (get_used_cells tung layer), lay mau trung binh cua tile trong
##     texture cua TileSetAtlasSource (sample vai diem trong vung tile,
##     cache theo source+atlas) roi ve 1 pixel / 1 o vao mot Image.
##   - _draw() chi blit ImageTexture do + ve cac cham (player / portal /
##     diem quest) len tren. Cham player cap nhat bang Timer thua 0.15s
##     (queue_redraw re vi chi blit texture, khong ve lai tung o).
##   - Portal: node co script res://systems/portal.gd trong scene.
##   - Diem quest: NPC (script res://systems/npc.gd) co npc_id khop
##     turn_in_npc cua quest dang active/ready_turn_in, hoac npc co
##     quest_ids chua quest do. Khong co toa do quest rieng trong du lieu
##     QuestManager nen day la cach duy nhat suy ra tu du lieu san co.

const MAX_W := 232.0
const MAX_H := 168.0
const PORTAL_SCRIPT := "res://systems/portal.gd"
const NPC_SCRIPT := "res://systems/npc.gd"

var _texture: ImageTexture = null
var _ref_tm: TileMap = null
var _ref_rect := Rect2i() # khung o (cell) cua TileMap chuan
var _step := 1 # 2 neu map qua lon (>340 o mot chieu)
var _disp_size := Vector2(232, 140)
var _portals: Array[Vector2] = []
var _quest_points: Array[Vector2] = []
var _player: Node2D = null
var _tex_images: Dictionary = {} # duong dan texture -> Image (cache)
var _color_cache: Dictionary = {} # "src:ax:ay" -> Color


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(232, 140)
	var t := Timer.new()
	t.wait_time = 0.15
	t.autostart = true
	t.timeout.connect(func() -> void:
		if visible and _texture != null and _player != null and is_instance_valid(_player):
			queue_redraw())
	add_child(t)


## Dung lai hinh minimap tu goc map (node goc cua scene map). Goi khi doi map.
func rebuild(root: Node, player: Node2D) -> void:
	_texture = null
	_ref_tm = null
	_portals.clear()
	_quest_points.clear()
	_player = player
	if root == null:
		queue_redraw()
		return
	# --- Thu thap TileMap / portal / NPC ---
	var tilemaps: Array[TileMap] = []
	var npc_nodes: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is TileMap:
			tilemaps.append(n)
		var sc: Script = n.get_script() as Script
		if sc != null and n is Node2D:
			if sc.resource_path == PORTAL_SCRIPT:
				_portals.append((n as Node2D).global_position)
			elif sc.resource_path == NPC_SCRIPT:
				npc_nodes.append(n)
		for c in n.get_children():
			stack.append(c)
	# --- Diem quest tu NPC khop turn_in_npc / quest_ids ---
	if has_node("/root/QuestManager"):
		var wanted_npc: Dictionary = {} # npc_id -> true
		var wanted_qnpc: Dictionary = {} # quest_id -> true
		for qid in QuestManager.quests.keys():
			var q: Dictionary = QuestManager.quests[qid]
			var st := str(q.get("status", ""))
			if st != "active" and st != "ready_turn_in":
				continue
			var tn := str(q.get("turn_in_npc", ""))
			if tn != "":
				wanted_npc[tn] = true
			wanted_qnpc[qid] = true
		for npc in npc_nodes:
			var nid := str(npc.get("npc_id"))
			var hit := wanted_npc.has(nid)
			if not hit:
				var qids = npc.get("quest_ids")
				if qids is Array:
					for q in qids:
						if wanted_qnpc.has(str(q)):
							hit = true
							break
			if hit:
				var pos: Vector2 = (npc as Node2D).global_position
				var dup := false
				for p in _quest_points:
					if p.distance_to(pos) < 8.0:
						dup = true
						break
				if not dup:
					_quest_points.append(pos)
	if tilemaps.is_empty():
		queue_redraw()
		return
	# --- TileMap chuan: cai co nhieu o da dung nhat ---
	var best_count := -1
	for tm in tilemaps:
		var cnt := 0
		for layer in tm.get_layers_count():
			cnt += tm.get_used_cells(layer).size()
		if cnt > best_count:
			best_count = cnt
			_ref_tm = tm
			_ref_rect = tm.get_used_rect()
	if _ref_tm == null or _ref_rect.size.x <= 0 or _ref_rect.size.y <= 0:
		queue_redraw()
		return
	_step = 2 if maxi(_ref_rect.size.x, _ref_rect.size.y) > 340 else 1
	var img_w := int(ceil(float(_ref_rect.size.x) / float(_step)))
	var img_h := int(ceil(float(_ref_rect.size.y) / float(_step)))
	var img := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.06, 0.08, 0.06, 1.0))
	_color_cache.clear()
	for tm in tilemaps:
		for layer in tm.get_layers_count():
			for cell in tm.get_used_cells(layer):
				var col := _tile_color(tm, layer, cell)
				if col.a < 0.05:
					continue
				var world: Vector2 = tm.to_global(tm.map_to_local(cell))
				var cf := _world_to_cell_f(world)
				var px := int(floor(cf.x)) - _ref_rect.position.x
				var py := int(floor(cf.y)) - _ref_rect.position.y
				px = int(px / _step)
				py = int(py / _step)
				if px >= 0 and py >= 0 and px < img_w and py < img_h:
					img.set_pixel(px, py, col)
	_texture = ImageTexture.create_from_image(img)
	_update_disp_size(Vector2(img_w, img_h))
	queue_redraw()


func has_map_data() -> bool:
	return _texture != null


func get_portal_count() -> int:
	return _portals.size()


func get_quest_point_count() -> int:
	return _quest_points.size()


func _update_disp_size(img_size: Vector2) -> void:
	var aspect := img_size.x / maxf(img_size.y, 1.0)
	var w := MAX_W
	var h := w / aspect
	if h > MAX_H:
		h = MAX_H
		w = h * aspect
	_disp_size = Vector2(w, h)
	custom_minimum_size = Vector2(MAX_W, h)
	size = custom_minimum_size


func _world_to_cell_f(world: Vector2) -> Vector2:
	if _ref_tm == null:
		return Vector2.ZERO
	var local: Vector2 = _ref_tm.to_local(world)
	var ts: Vector2i = _ref_tm.tile_set.tile_size
	return Vector2(local.x / float(maxi(ts.x, 1)), local.y / float(maxi(ts.y, 1)))


func _disp_rect() -> Rect2:
	return Rect2(Vector2((size.x - _disp_size.x) * 0.5, (size.y - _disp_size.y) * 0.5), _disp_size)


func _world_to_draw(world: Vector2) -> Vector2:
	var cf := _world_to_cell_f(world)
	var u := (cf.x - float(_ref_rect.position.x)) / float(maxi(_ref_rect.size.x, 1))
	var v := (cf.y - float(_ref_rect.position.y)) / float(maxi(_ref_rect.size.y, 1))
	var r := _disp_rect()
	return r.position + Vector2(clampf(u, 0.0, 1.0) * r.size.x, clampf(v, 0.0, 1.0) * r.size.y)


func _tile_color(tm: TileMap, layer: int, cell: Vector2i) -> Color:
	var src_id := tm.get_cell_source_id(layer, cell)
	if src_id == -1:
		return Color(0, 0, 0, 0)
	var atlas := tm.get_cell_atlas_coords(layer, cell)
	var key := "%d:%d:%d" % [src_id, atlas.x, atlas.y]
	if _color_cache.has(key):
		return _color_cache[key]
	var col := _fallback_color(src_id, atlas)
	var src := tm.tile_set.get_source(src_id) as TileSetAtlasSource
	if src != null and src.texture != null:
		var sampled := _sample_atlas_color(src, atlas)
		if sampled.a > 0.05:
			col = sampled
	_color_cache[key] = col
	return col


func _sample_atlas_color(src: TileSetAtlasSource, atlas: Vector2i) -> Color:
	var tex_path := src.texture.resource_path
	if not _tex_images.has(tex_path):
		var im: Image = src.texture.get_image()
		if im == null:
			return Color(0, 0, 0, 0)
		if im.is_compressed():
			im.decompress()
		_tex_images[tex_path] = im
	var img: Image = _tex_images[tex_path]
	# Vung texture cua tile tu tinh tu margins / texture_region_size /
	# separation cua TileSetAtlasSource (Godot 4.2 khong co property
	# texture_margins; dung margins).
	var region: Vector2i = src.texture_region_size
	var origin: Vector2i = src.margins + atlas * (region + src.separation)
	var rect := Rect2i(origin, region)
	if rect.size.x <= 0 or rect.size.y <= 0:
		return Color(0, 0, 0, 0)
	var acc := Vector3.ZERO
	var n := 0
	var fracs := [0.3, 0.5, 0.7]
	for fx in fracs:
		for fy in fracs:
			var px := clampi(rect.position.x + int(float(rect.size.x) * fx), 0, img.get_width() - 1)
			var py := clampi(rect.position.y + int(float(rect.size.y) * fy), 0, img.get_height() - 1)
			var c := img.get_pixel(px, py)
			acc += Vector3(c.r, c.g, c.b)
			n += 1
	if n == 0:
		return Color(0, 0, 0, 0)
	acc /= float(n)
	return Color(acc.x, acc.y, acc.z, 1.0)


func _fallback_color(src_id: int, atlas: Vector2i) -> Color:
	# Mau du phong khi khong sample duoc texture: bang mau am, phan biet theo atlas.
	var palette: Array[Color] = [
		Color(0.40, 0.62, 0.29), Color(0.43, 0.63, 0.31), Color(0.38, 0.58, 0.27),
		Color(0.50, 0.53, 0.29), Color(0.61, 0.46, 0.30), Color(0.49, 0.38, 0.23),
		Color(0.29, 0.51, 0.69), Color(0.29, 0.51, 0.69), Color(0.50, 0.55, 0.30),
		Color(0.35, 0.56, 0.49), Color(0.35, 0.56, 0.48), Color(0.38, 0.58, 0.40),
		Color(0.44, 0.56, 0.28), Color(0.43, 0.55, 0.27), Color(0.40, 0.61, 0.31),
		Color(0.33, 0.54, 0.25), Color(0.85, 0.76, 0.56),
	]
	var idx := absi(atlas.x + atlas.y * 8 + src_id * 17) % palette.size()
	return palette[idx]


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.03, 0.85))
	if _texture == null or _ref_tm == null:
		var font := get_theme_default_font()
		if font != null:
			draw_string(font, Vector2(10, size.y * 0.5), "(chua co du lieu ban do)",
				HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 12, Color(0.8, 0.8, 0.75))
		return
	var r := _disp_rect()
	draw_texture_rect(_texture, r, false)
	draw_rect(r, Color(0.85, 0.72, 0.4, 0.55), false, 1.0)
	# Cham portal: o vuong xanh ngoc.
	for p in _portals:
		var d := _world_to_draw(p)
		draw_rect(Rect2(d - Vector2(3.5, 3.5), Vector2(7, 7)), Color(0.15, 0.9, 0.95))
		draw_rect(Rect2(d - Vector2(3.5, 3.5), Vector2(7, 7)), Color(0, 0.2, 0.25), false, 1.0)
	# Cham diem quest: tron vang.
	for p in _quest_points:
		var d := _world_to_draw(p)
		draw_circle(d, 4.5, Color(0.1, 0.08, 0))
		draw_circle(d, 3.5, Color(1.0, 0.8, 0.2))
	# Cham player: vien trang, loi do.
	if _player != null and is_instance_valid(_player):
		var d := _world_to_draw(_player.global_position)
		draw_circle(d, 5.0, Color(1, 1, 1))
		draw_circle(d, 3.6, Color(0.95, 0.2, 0.15))
