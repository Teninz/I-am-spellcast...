class_name SkillTile
extends Button
## Плитка навыка класса: активный (золотая рамка, нажимается, число зарядов)
## или пассивный (серо-синяя рамка, только подсказка). Данные — data/class_skills.json,
## картинка — res://assets/icons/skills/<id>.png, без неё — заглушка с буквами.

const ICON_DIR := "res://assets/icons/skills/"
const ACTIVE_COLOR := Color("ffd35a")
const PASSIVE_COLOR := Color("8fa3c0")

static var _db: Dictionary = {}

var skill: Dictionary = {}
var charges := ""   # число в углу (заряды, запас лечения)
var usable := false  # активный навык можно применить прямо сейчас


static func skills_for(class_id: String) -> Array:
	if _db.is_empty():
		_db = GameData.load_json("res://data/class_skills.json")
	return _db.get(class_id, [])


static func make(s: Dictionary, px: int = 54) -> SkillTile:
	var t := SkillTile.new()
	t.skill = s
	t.custom_minimum_size = Vector2(px, px)
	t.focus_mode = Control.FOCUS_NONE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		t.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	t.tooltip_text = "%s\n%s" % [s.name, s.text]
	t.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if s.kind == "active" else Control.CURSOR_HELP
	return t


static func texture_for(id: String) -> Texture2D:
	return Art.texture(ICON_DIR + id + ".png")


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var active: bool = skill.get("kind", "") == "active"
	var frame := ACTIVE_COLOR if active else PASSIVE_COLOR
	var tex := SkillTile.texture_for(String(skill.get("id", "")))
	var dim := active and not usable
	var tint := Color(0.55, 0.55, 0.58) if dim else Color.WHITE
	# Активный — круг (кнопка), пассивный — ромб-«печать» на квадрате.
	if tex:
		draw_rect(r.grow(-3), Color("15161f"))
		draw_texture_rect(tex, r.grow(-3), false, tint)
	else:
		draw_rect(r.grow(-3), Color("3a3326") if active else Color("262d3a"))
		var words := String(skill.get("name", "?")).replace("«", "").split(" ", false)
		var short := ""
		for w in words:
			if short.length() < 2:
				short += w.left(1).to_upper()
		_centered(short, r, int(size.y * 0.36), tint)
	draw_rect(r.grow(-1), frame * tint, false, 3.0 if active and usable else 2.0)
	if active and usable and is_hovered():
		draw_rect(r.grow(-4), Color(1, 1, 1, 0.12))
	if charges != "":
		var fs := clampi(int(size.y * 0.3), 10, 16)
		var font := ThemeDB.fallback_font
		var ts := font.get_string_size(charges, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var bs := Vector2(ts.x + 6, fs + 2)
		var pos := size - bs
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0, 0, 0, 0.85)
		box.set_corner_radius_all(3)
		draw_style_box(box, Rect2(pos, bs))
		draw_string(font, pos + Vector2(3, 1 + fs * 0.82), charges, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


func _centered(text: String, r: Rect2, fs: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(font, Vector2((r.size.x - sz.x) / 2.0, (r.size.y + fs * 0.7) / 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _make_custom_tooltip(_for_text: String) -> Object:
	return SkillTile.card(skill, charges, usable)


## Карточка навыка при наведении: крупная иконка, название, вид, описание, как применить.
static func card(s: Dictionary, charges_text: String = "", is_ready: bool = false) -> Control:
	var active: bool = s.get("kind", "") == "active"
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("24232f")
	box.border_color = ACTIVE_COLOR if active else PASSIVE_COLOR
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var big := SkillTile.make(s, 96)
	big.usable = true
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(big)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(280, 0)
	row.add_child(col)
	var title := Label.new()
	title.text = s.get("name", "")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", box.border_color)
	col.add_child(title)
	var kind := Label.new()
	kind.text = "Активный навык" if active else "Пассивный навык — работает сам"
	if charges_text != "":
		kind.text += " · осталось: %s" % charges_text
	if active and not is_ready:
		kind.text += " · сейчас недоступен"
	kind.add_theme_font_size_override("font_size", 13)
	kind.modulate = Color(1, 1, 1, 0.7)
	col.add_child(kind)
	var desc := Label.new()
	desc.text = s.get("text", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(280, 0)
	desc.add_theme_font_size_override("font_size", 14)
	col.add_child(desc)
	if s.has("how"):
		var how := Label.new()
		how.text = "Как: " + String(s.how)
		how.autowrap_mode = TextServer.AUTOWRAP_WORD
		how.custom_minimum_size = Vector2(280, 0)
		how.add_theme_font_size_override("font_size", 13)
		how.add_theme_color_override("font_color", ACTIVE_COLOR)
		col.add_child(how)
	return panel
