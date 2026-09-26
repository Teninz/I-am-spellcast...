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


static func book(id: String) -> Texture2D:
	return texture("res://assets/books/%s.png" % id)


## Материал, обрезающий картинку по кругу (для фишек).
static func circle_material() -> ShaderMaterial:
	if _circle == null:
		var sh := Shader.new()
		sh.code = """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = distance(UV, vec2(0.5));
	c.a *= 1.0 - smoothstep(0.485, 0.5, d);
	COLOR = c * COLOR;
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
	var box := StyleBoxFlat.new()
	box.bg_color = Color("15161f")
	box.border_color = RARITY_COLORS.get(book.get("rarity", "common"), Color.GRAY)
	box.set_border_width_all(2 if width < 80 else 3)
	box.set_corner_radius_all(4)
	box.set_content_margin_all(2)
	panel.add_theme_stylebox_override("panel", box)
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
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 11)
		panel.add_child(l)
	panel.tooltip_text = book.name
	return panel
