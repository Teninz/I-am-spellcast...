class_name Art
extends RefCounted
## Картинки игры: фишки стихий, мешочек, обложки книг.
## Если картинки нет, функции возвращают null — интерфейс рисует заглушку.

const CHIP_FILES := {
	"F": "fire", "W": "water", "H": "holy", "D": "dark", "E": "earth", "M": "mechanic",
	"S": "sound", "T": "mystery", "I": "illusion", "L": "lightning", "C": "time",
	"K": "ice", "A": "air", "X": "chaos",
}
const RARITY_COLORS := {
	"common": Color("b8b8b8"), "rare": Color("6fa8ff"), "epic": Color("c07dff"),
	"legendary": Color("ffae42"), "cursed": Color("ff4a4a"),
}

static var _cache: Dictionary = {}
static var _circle: ShaderMaterial = null


static func texture(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


## Фишка по букве стихии ("" — рубашка).
static func chip(letter: String) -> Texture2D:
	if letter == "":
		return texture("res://assets/chips/chip_back.png")
	return texture("res://assets/chips/%s.png" % CHIP_FILES.get(letter, "chip_back"))


static func bag() -> Texture2D:
	return texture("res://assets/chips/bag.png")


## Портреты волшебников: assets/characters/<файл>_<состояние>.png. Имена файлов у двух классов короче id.
const PORTRAIT_FILES := {"chronomancer": "chrono", "wild_mage": "wild"}


## Состояние портрета по здоровью: больше половины — healthy, от трети — hurt, меньше — critical.
static func portrait_state(hp: float, max_hp: float, zombie: bool = false) -> String:
	if zombie:
		return "zombie"
	var r := hp / maxf(0.1, max_hp)
	if r > 0.5:
		return "healthy"
	return "hurt" if r >= 1.0 / 3.0 else "critical"


static func portrait(class_id: String, state: String = "healthy") -> Texture2D:
	return texture("res://assets/characters/%s_%s.png" % [PORTRAIT_FILES.get(class_id, class_id), state])


## Верхняя часть портрета (голова и плечи) — для маленьких карточек.
static func portrait_head(class_id: String, state: String = "healthy") -> Texture2D:
	var key := "head:%s:%s" % [class_id, state]
	if _cache.has(key):
		return _cache[key]
	var full := portrait(class_id, state)
	var out: Texture2D = _head_of(full, key) if full else null
	_cache[key] = out
	return out


## Верхняя часть картинки 3:4 — голова и плечи.
static func _head_of(full: Texture2D, key: String) -> Texture2D:
	if _cache.has("atlas:" + key):
		return _cache["atlas:" + key]
	var a := AtlasTexture.new()
	a.atlas = full
	var w := full.get_width()
	var h := full.get_height()
	a.region = Rect2(w * 0.17, h * 0.03, w * 0.66, minf(h * 0.97, w * 0.66 * 4.0 / 3.0))
	_cache["atlas:" + key] = a
	return a


## Картинка портрета нужного размера (или пустое место, если файла нет).
static func portrait_rect(tex: Texture2D, size: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = size
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.clip_contents = true
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tr


static var _enemy_ids: Dictionary = {}


## Портрет врага по имени (data/enemy_portraits.json): assets/enemies/<id>.png или null.
static func enemy_portrait(enemy_name: String) -> Texture2D:
	var id := enemy_portrait_id(enemy_name)
	return texture("res://assets/enemies/%s.png" % id) if id != "" else null


## Файл портрета врага или призванного существа (data/enemy_portraits.json, data/creatures.json).
static func enemy_portrait_id(enemy_name: String) -> String:
	if _enemy_ids.is_empty():
		_enemy_ids = GameData.load_json("res://data/enemy_portraits.json")
	var id: String = _enemy_ids.get(enemy_name, "")
	if id == "":
		for c in GameData.creatures().values():
			if c.name == enemy_name:
				return String(c.get("portrait", ""))
	return id


static func enemy_head(enemy_name: String) -> Texture2D:
	var full := enemy_portrait(enemy_name)
	return _head_of(full, "enemy:" + enemy_name) if full else null


static var _crops: Dictionary = {}


## Квадратный кадр по голове для круглой аватарки (data/portrait_crops.json).
static func face_crop(full: Texture2D, crop_id: String) -> Texture2D:
	if full == null:
		return null
	var key := "face:%s:%s" % [crop_id, full.resource_path if full.resource_path != "" else str(full.get_instance_id())]
	if _cache.has(key):
		return _cache[key]
	if _crops.is_empty():
		_crops = GameData.load_json("res://data/portrait_crops.json")
	var c: Array = _crops.get(crop_id, _crops.get("_default", [0.5, 0.2, 0.56]))
	var w := float(full.get_width())
	var h := float(full.get_height())
	var side := w * float(c[2])
	var x := clampf(float(c[0]) * w - side / 2.0, 0.0, w - side)
	var y := clampf(float(c[1]) * h - side / 2.0, 0.0, h - side)
	var a := AtlasTexture.new()
	a.atlas = full
	a.region = Rect2(x, y, side, side)
	_cache[key] = a
	return a


static func wizard_face(class_id: String, state: String = "healthy") -> Texture2D:
	return face_crop(portrait(class_id, state), PORTRAIT_FILES.get(class_id, class_id))


static func enemy_face(enemy_name: String) -> Texture2D:
	if _enemy_ids.is_empty():
		_enemy_ids = GameData.load_json("res://data/enemy_portraits.json")
	return face_crop(enemy_portrait(enemy_name), enemy_portrait_id(enemy_name))


## Кольцо аватарки: assets/ui/ring_<вид>.png (ring_wizard, ring_wizard_active, ring_enemy_boss…).
static func ring(kind: String) -> Texture2D:
	return texture("res://assets/ui/ring_%s.png" % kind)


## Аватарка: лицо в круге и кольцо поверх. Без файла кольца — прямоугольное лицо.
## Возвращает Control; лицо и кольцо лежат в мете "face" и "ring", чтобы их можно было менять.
static func avatar(face: Texture2D, ring_kind: String, px: int) -> Control:
	var ring_tex := Art.ring(ring_kind)
	if ring_tex == null:
		var rect := portrait_rect(face, Vector2(px * 0.76, px))
		rect.set_meta("face", rect)
		return rect
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(px, px)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var f := TextureRect.new()
	f.texture = face
	f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	f.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	f.material = circle_material()
	f.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Кольцо — маска: лицо — круг чуть больше самого широкого места отверстия этого кольца.
	# Край лица всегда прячется под кольцом: ни зазора внутри, ни лица снаружи.
	var face_r := ring_hole(ring_kind) + 0.015
	var inset := (px - face_r * px / 0.4925) / 2.0
	f.offset_left = inset
	f.offset_top = inset
	f.offset_right = -inset
	f.offset_bottom = -inset
	holder.add_child(f)
	var r := TextureRect.new()
	r.texture = ring_tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(r)
	holder.set_meta("face", f)
	holder.set_meta("ring", r)
	return holder


static var _holes: Dictionary = {}


## Радиус отверстия кольца (самое широкое место) в долях стороны — по прозрачности картинки.
static func ring_hole(kind: String) -> float:
	if _holes.has(kind):
		return _holes[kind]
	var r_max := 0.37
	var tex := Art.ring(kind)
	if tex:
		var img := tex.get_image()
		if img.is_compressed():
			img.decompress()
		var w := img.get_width()
		var c := Vector2(w, img.get_height()) / 2.0
		r_max = 0.0
		for k in 48:
			var dir := Vector2.from_angle(TAU * k / 48.0)
			var r := 0.0
			while r < w / 2.0 - 1.0:
				var p := c + dir * r
				if img.get_pixel(int(p.x), int(p.y)).a > 0.5:
					break
				r += 1.0
			r_max = maxf(r_max, r / w)
	_holes[kind] = r_max
	return r_max


static func book(id: String) -> Texture2D:
	return texture("res://assets/books/%s.png" % id)


## Материал, обрезающий картинку по кругу (для фишек).
static func circle_material() -> ShaderMaterial:
	if _circle == null:
		var sh := Shader.new()
		sh.code = """
shader_type canvas_item;
void fragment() {
	// COLOR уже содержит цвет картинки — меняем только прозрачность по кругу, цвета не трогаем.
	float d = distance(UV, vec2(0.5));
	COLOR.a *= 1.0 - smoothstep(0.485, 0.5, d);
}
"""
		_circle = ShaderMaterial.new()
		_circle.shader = sh
	return _circle


## Обложка книги в рамке цвета редкости. Без картинки — цветная плашка с названием.
static func book_cover(book: Dictionary, width: int) -> Control:
	var h := int(width * 1.5)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", Art.rarity_box(book.get("rarity", "common"), width))
	var tex := Art.book(book.id)
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(width, h)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(tr)
	else:
		var l := Label.new()
		l.text = book.name
		l.custom_minimum_size = Vector2(width, h)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 11)
		panel.add_child(l)
	panel.tooltip_text = book.name
	return panel


# --- Интерфейс: фоны, рамки, кнопки ----------------------------------------

## Картинка без сплошного фона по краям: пиксели цвета угла, связанные с краем, становятся
## прозрачными. Нужно для рамок, у которых вокруг нарисован тёмный фон вместо прозрачности.
## threshold — насколько цвет может отличаться от фона; soft — мягкий край (для картинок с плавным фоном).
static func keyed(path: String, threshold: float = 0.12, soft: bool = false) -> Texture2D:
	var key := "%s@keyed%s%s" % [path, threshold, soft]
	if _cache.has(key):
		return _cache[key]
	var tex := Art.texture(path)
	if tex == null:
		_cache[key] = null
		return null
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var bg := img.get_pixel(1, 1)
	if bg.a < 0.5:
		_cache[key] = tex  # фон уже прозрачный
		return tex
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var idx: int = stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if seen[idx]:
			continue
		seen[idx] = 1
		var px := idx % w
		var py := idx / w
		var c := img.get_pixel(px, py)
		if absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b) > threshold:
			continue
		img.set_pixel(px, py, Color(c.r, c.g, c.b, 0.0))
		if px > 0: stack.append(idx - 1)
		if px < w - 1: stack.append(idx + 1)
		if py > 0: stack.append(idx - w)
		if py < h - 1: stack.append(idx + w)
	if soft:
		_feather(img, w, h)
	img.generate_mipmaps()
	var out := ImageTexture.create_from_image(img)
	_cache[key] = out
	return out


## Мягкий край: непрозрачные пиксели рядом с вырезанным фоном становятся полупрозрачными (2 пикселя).
static func _feather(img: Image, w: int, h: int) -> void:
	for pass_i in 2:
		var alpha := PackedFloat32Array()
		alpha.resize(w * h)
		for i in w * h:
			alpha[i] = img.get_pixel(i % w, i / w).a
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var i := y * w + x
				if alpha[i] < 0.99:
					continue
				var clear := 0.0
				for d in [-1, 1, -w, w]:
					clear += 1.0 - alpha[i + d]
				if clear > 0.0:
					var c := img.get_pixel(x, y)
					c.a = clampf(1.0 - clear * 0.3, 0.25, 1.0)
					img.set_pixel(x, y, c)


## Уменьшенная копия картинки (для рамок: углы 9-slice рисуются в «родном» размере).
static func scaled(path: String, factor: float) -> Texture2D:
	var key := "%s@%s" % [path, factor]
	if not _cache.has(key):
		var tex := Art.keyed(path) if path.contains("/ui/") else Art.texture(path)
		if tex == null or is_equal_approx(factor, 1.0):
			_cache[key] = tex
		else:
			var img := tex.get_image()
			if img.is_compressed():
				img.decompress()
			img.resize(maxi(1, int(img.get_width() * factor)), maxi(1, int(img.get_height() * factor)), Image.INTERPOLATE_LANCZOS)
			_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


## Рамка-«резинка» (9-slice) из картинки. margin — толщина края в исходных пикселях.
static func frame(name: String, margin: float, factor: float = 0.5, content: float = -1.0, tint: Color = Color.WHITE, margin_v: float = -1.0) -> StyleBox:
	var tex := Art.scaled("res://assets/ui/%s.png" % name, factor)
	if tex == null:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.set_texture_margin_all(margin * factor)
	if margin_v >= 0.0:
		sb.texture_margin_top = margin_v * factor
		sb.texture_margin_bottom = margin_v * factor
	sb.set_content_margin_all(content if content >= 0.0 else margin * factor)
	sb.modulate_color = tint
	return sb


## Фон экрана: картинка «на весь экран» с затемнением сверху.
static func background(name: String, _dim: float = 0.0, fallback: String = "") -> Control:
	var tex := Art.texture("res://assets/ui/%s.png" % name)
	if tex == null and fallback != "":
		tex = Art.texture("res://assets/ui/%s.png" % fallback)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var base := ColorRect.new()
	base.color = Color("1b1a24")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(base)
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tr)  # фон как есть: без затемнения и подкраски
	return holder


## Картинка по пути, вписанная в квадрат size (с тёмной подложкой — часть картинок прозрачная).
static func picture(path: String, size: int, tooltip: String = "") -> Control:
	var tex := Art.texture(path)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS if tooltip != "" else Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var box := StyleBoxFlat.new()
	box.bg_color = Color("15161f")
	box.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", box)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(size, size)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tr)
	panel.tooltip_text = tooltip
	return panel


static func item_icon(id: String, size: int, tooltip: String = "") -> Control:
	return Art.picture("res://assets/items/%s.png" % id, size, tooltip)


static func equipment_icon(id: String, size: int, tooltip: String = "") -> Control:
	return Art.picture("res://assets/equipment/%s.png" % id, size, tooltip)


## Иконка характеристики с числом: [картинка] 2
static func stat(id: String, value: String, tooltip: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.tooltip_text = tooltip
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var tex := Art.texture("res://assets/ui/stat_%s.png" % id)
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(22, 22)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tr)
	var l := Label.new()
	l.text = value if tex else "%s %s" % [tooltip, value]
	l.add_theme_font_size_override("font_size", 14)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	return row


## Общая тема: деревянные кнопки.
static func ui_theme() -> Theme:
	var th := Theme.new()
	var normal := Art.frame("button", 40, 0.4, -1.0, Color.WHITE, 14)
	if normal == null:
		return th
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	normal.content_margin_top = 7
	normal.content_margin_bottom = 7
	var hover := normal.duplicate()
	hover.modulate_color = Color(1.2, 1.15, 1.0)
	var pressed := normal.duplicate()
	pressed.modulate_color = Color(0.8, 0.75, 0.7)
	var disabled := normal.duplicate()
	disabled.modulate_color = Color(0.55, 0.55, 0.6, 0.8)
	th.set_stylebox("normal", "Button", normal)
	th.set_stylebox("hover", "Button", hover)
	th.set_stylebox("pressed", "Button", pressed)
	th.set_stylebox("disabled", "Button", disabled)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", Color("fff4dc"))
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.45))
	th.set_color("font_outline_color", "Button", Color(0.1, 0.06, 0.03))
	th.set_constant("outline_size", "Button", 4)
	return th


## Рамка редкости: для крупных — картинка рамки добычи, для мелких — цветная обводка.
static func rarity_box(rarity: String, width: int) -> StyleBox:
	if width >= 70:
		var sb := Art.frame("loot_frame_" + rarity, 40, width / 320.0 * 1.6, -1.0)
		if sb:
			sb.draw_center = true
			return sb
	var box := StyleBoxFlat.new()
	box.bg_color = Color("15161f")
	box.border_color = RARITY_COLORS.get(rarity, Color.GRAY)
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.set_content_margin_all(2)
	return box
