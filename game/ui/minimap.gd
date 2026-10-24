extends Control
## Minimap TRON (dot lam lai UI): ban do thu nho dang hinh tron, tam LUON
## la nguoi choi, noi dung ve tu du lieu TileMap THAT cua map dang choi.
##   - rebuild(root, player): quet moi TileMap, sample mau trung binh cua
##     tile -> Image 1px/1 o (giong ban cu). Portal/NPC-quest thu thap nhu cu.
##   - Render: moi 0.15s cat mot vung vuong quanh nguoi choi trong Image
##     ban do (ban kinh = ZOOM_RADII[_zoom_idx] o), resize ve RENDER px,
##     tron qua mat na tron (blend_rect_mask, chay native) roi ve cac cham
##     portal/quest + cham nguoi choi o tam. Ket qua vao ImageTexture.
##   - Zoom: nut +/- (o left_panel) goi zoom_in()/zoom_out(): chi doi ban
##     kinh vung cat -> noi dung phong/thu, KICH THUOC khung tron giu nguyen.
##   - Vanh khung tron trang tri (ring_frame.png) do left_panel phu len tren.

const DISPLAY := 172.0 # duong kinh hien thi cua control (kem vanh)
const RENDER := 258 # do phan giai render noi bo (1.5x DISPLAY, tron dep)
const ZOOM_RADII: Array[float] = [84.0, 56.0, 36.0, 22.0] # ban kinh (o)
const VISIBLE_FRAC := 0.82 # phan duong kinh khong bi vanh khung che
const PORTAL_SCRIPT := "res://systems/portal.gd"
const NPC_SCRIPT := "res://systems/npc.gd"
const BG_COLOR := Color(0.13, 0.16, 0.09, 1.0) # xanh olive toi: vung ngoai map

var _map_img: Image = null
var _ref_tm: TileMap = null
var _ref_rect := Rect2i()
var _step := 1
var _portals: Array[Vector2] = []
var _quest_points: Array[Vector2] = []
var _player: Node2D = null
var _tex_images: Dictionary = {}
var _color_cache: Dictionary = {}
var _zoom_idx := 2
var _render_tex: ImageTexture = null
var _mask: Image = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	custom_minimum_size = Vector2(DISPLAY, DISPLAY)
	size = custom_minimum_size
	_build_mask()
	var t := Timer.new()
	t.wait_time = 0.15
	t.autostart = true
	t.timeout.connect(func() -> void:
		if visible and _map_img != null and _player != null and is_instance_valid(_player):
			_render())
	add_child(t)


func _build_mask() -> void:
	# Mat na tron: trang trong vong, trong suot ngoai vong, vien mem ~3px.
	_mask = Image.create(RENDER, RENDER, false, Image.FORMAT_RGBA8)
	_mask.fill(Color(0, 0, 0, 0))
	var c := float(RENDER) * 0.5
	var r := c - 1.0
	for y in RENDER:
		for x in RENDER:
			var d := Vector2(float(x) + 0.5 - c, float(y) + 0.5 - c).length()
			var a := clampf((r - d) / 3.0 + 0.5, 0.0, 1.0)
			if a > 0.0:
				_mask.set_pixel(x, y, Color(1, 1, 1, a))


func zoom_in() -> void:
	if _zoom_idx < ZOOM_RADII.size() - 1:
		_zoom_idx += 1
		_render()


func zoom_out() -> void:
	if _zoom_idx > 0:
		_zoom_idx -= 1
		_render()


func get_zoom_index() -> int:
	return _zoom_idx


func get_zoom_count() -> int:
	return ZOOM_RADII.size()


## Dung lai du lieu minimap tu goc map. Goi khi doi map / quest thay doi.
func rebuild(root: Node, player: Node2D) -> void:
	_map_img = null
	_ref_tm = null
	_portals.clear()
	_quest_points.clear()
	_player = player
	if root == null:
		queue_redraw()
		return
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
	if has_node("/root/QuestManager"):
		var wanted_npc: Dictionary = {}
		var wanted_qnpc: Dictionary = {}
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
	img.fill(BG_COLOR)
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
	_map_img = img
	_render()


func has_map_data() -> bool:
	return _map_img != null


func get_portal_count() -> int:
	return _portals.size()


func get_quest_point_count() -> int:
	return _quest_points.size()


## Cat vung quanh nguoi choi, tron mat na, ve cham, cap nhat texture.
func _render() -> void:
	if _map_img == null or _player == null or not is_instance_valid(_player):
		queue_redraw()
		return
	var radius_cells := ZOOM_RADII[_zoom_idx]
	var src_size := maxi(int(round(2.0 * radius_cells / float(_step))), 4)
	# Anh vung nguon (vuong, day du kich thuoc ke ca khi nguoi choi o mep map)
	var region := Image.create(src_size, src_size, false, Image.FORMAT_RGBA8)
	region.fill(BG_COLOR)
	var pc := _world_to_px(_player.global_position)
	var src_rect := Rect2i(int(round(pc.x)) - src_size / 2, int(round(pc.y)) - src_size / 2, src_size, src_size)
	var inter := src_rect.intersection(Rect2i(0, 0, _map_img.get_width(), _map_img.get_height()))
	if inter.size.x > 0 and inter.size.y > 0:
		var dst := Vector2i(inter.position.x - src_rect.position.x, inter.position.y - src_rect.position.y)
		region.blit_rect(_map_img, inter, dst)
	region.resize(RENDER, RENDER, Image.INTERPOLATE_BILINEAR)
	# Tron mat na tron
	var out := Image.create(RENDER, RENDER, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	out.blend_rect_mask(region, _mask, Rect2i(0, 0, RENDER, RENDER), Vector2i.ZERO)
	# Cham portal / quest (chi khi nam trong vong nhin thay duoc)
	var px_per_cell := float(RENDER) / (2.0 * radius_cells)
	var vis_r := float(RENDER) * 0.5 * VISIBLE_FRAC
	for p in _portals:
		var d := _marker_pos(p, px_per_cell)
		if d.length() <= vis_r - 6.0:
			_stamp(out, d, 5, Color(0.05, 0.25, 0.3, 1.0))
			_stamp(out, d, 4, Color(0.15, 0.9, 0.95, 1.0))
	for p in _quest_points:
		var d := _marker_pos(p, px_per_cell)
		if d.length() <= vis_r - 6.0:
			_stamp(out, d, 5, Color(0.1, 0.08, 0.0, 1.0))
			_stamp(out, d, 4, Color(1.0, 0.8, 0.2, 1.0))
	# Cham nguoi choi: dung tam, vien trang loi do
	var center := Vector2(RENDER, RENDER) * 0.5
	_stamp(out, center, 7, Color(1, 1, 1, 1))
	_stamp(out, center, 5, Color(0.95, 0.2, 0.15, 1.0))
	if _render_tex == null:
		_render_tex = ImageTexture.create_from_image(out)
	else:
		_render_tex.update(out)
	queue_redraw()


func _marker_pos(world: Vector2, px_per_cell: float) -> Vector2:
	# Tra ve toa do RENDER tu tam; do dai > ban kinh = ngoai tam nhin.
	var cf_p := _world_to_cell_f(_player.global_position)
	var cf := _world_to_cell_f(world)
	return Vector2(RENDER, RENDER) * 0.5 + (cf - cf_p) * px_per_cell


func _stamp(img: Image, center: Vector2, r: int, col: Color) -> void:
	var cx := int(round(center.x))
	var cy := int(round(center.y))
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			if Vector2(x - cx, y - cy).length() <= float(r):
				img.set_pixel(x, y, col)


func _world_to_px(world: Vector2) -> Vector2:
	var cf := _world_to_cell_f(world)
	return Vector2((cf.x - float(_ref_rect.position.x)) / float(_step),
		(cf.y - float(_ref_rect.position.y)) / float(_step))


func _world_to_cell_f(world: Vector2) -> Vector2:
	if _ref_tm == null:
		return Vector2.ZERO
	var local: Vector2 = _ref_tm.to_local(world)
	var ts: Vector2i = _ref_tm.tile_set.tile_size
	return Vector2(local.x / float(maxi(ts.x, 1)), local.y / float(maxi(ts.y, 1)))


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
	var region_sz: Vector2i = src.texture_region_size
	var origin: Vector2i = src.margins + atlas * (region_sz + src.separation)
	var rect := Rect2i(origin, region_sz)
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
	if _render_tex != null:
		draw_texture_rect(_render_tex, Rect2(Vector2.ZERO, size), false)
		return
	# Chua co du lieu: nen tron toi + chu nho o tam.
	var c := size * 0.5
	draw_circle(c, size.x * 0.5 * VISIBLE_FRAC, Color(0.04, 0.05, 0.04, 0.9))
	var font := get_theme_default_font()
	if font != null:
		var msg := "(chưa có bản đồ)"
		var w := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, c + Vector2(-w * 0.5, 4), msg,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.75))
