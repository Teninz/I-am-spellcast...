class_name StatusIcon
extends Control
## Иконка эффекта в стиле «квадратик с рамкой»: рамка по виду эффекта
## (красная — дебафф, зелёная — бафф, золотая — особое), число ходов в углу.
## Если есть картинка res://assets/icons/status/<id>.png — рисуется она,
## иначе временная заглушка: цветной квадрат с сокращением.

const ICON_DIR := "res://assets/icons/status/"
const FRAME_COLORS := {
	"debuff": Color("e0413a"),
	"buff": Color("4cc46a"),
	"special": Color("e0b04a"),
}

static var _textures: Dictionary = {}
const HIDDEN_DESC := "Особое умение. Что оно делает, станет ясно, когда оно впервые сработает в бою."

var status_id := ""
var counter := ""  # число в правом нижнем углу (ходы, остаток щита)
var stacks := 0    # число стаков в левом верхнем углу (яд)
var info: Dictionary = {}
var source_name := ""  # кто наложил (для карточки при наведении)
var rich_tooltip := true
var desc_override := ""  # своё описание вместо справочника (призванные существа)


static func make(id: String, counter_text: String = "", stack_count: int = 0, icon_size: int = 30) -> StatusIcon:
	var icon := StatusIcon.new()
	icon.status_id = id
	icon.counter = counter_text
	icon.stacks = stack_count
	icon.info = GameData.statuses().get(id, {"name": id, "kind": "special", "short": "?", "color": "#777777", "desc": ""})
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.tooltip_text = "%s%s\n%s" % [icon.info.name, " (%s)" % counter_text if counter_text != "" else "", icon.info.desc]
	if not Profile.knows_passive(id):
		icon.tooltip_text = "???\n" + HIDDEN_DESC
	return icon


static func texture_for(id: String) -> Texture2D:
	if not _textures.has(id):
		var path := ICON_DIR + id + ".png"
		if not ResourceLoader.exists(path):
			# Своей иконки ещё нет — берём указанную в справочнике картинку (например, портрет слизня).
			path = String(GameData.statuses().get(id, {}).get("icon", path))
			if ResourceLoader.exists(path):
				# Портрет вертикальный — берём квадратный кадр лица, чтобы не сплющить.
				_textures[id] = Art.face_crop(load(path), path.get_file().get_basename())
				return _textures[id]
		_textures[id] = load(path) if ResourceLoader.exists(path) else null
	return _textures[id]


## Крупная карточка эффекта вместо обычной подсказки.
func _make_custom_tooltip(_for_text: String) -> Object:
	if not rich_tooltip:
		return null
	return StatusIcon.big_card(status_id, counter, source_name, 112, desc_override)


## Карточка: крупная иконка, название, ходы, кто наложил, описание.
static func big_card(id: String, counter_text: String = "", source: String = "", icon_size: int = 112, desc_text: String = "") -> Control:
	var info_d: Dictionary = GameData.statuses().get(id, {"name": id, "kind": "special", "desc": ""})
	if not Profile.knows_passive(id):
		info_d = {"name": "???", "kind": "special", "desc": HIDDEN_DESC}
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("24232f")
	box.border_color = FRAME_COLORS.get(info_d.kind, Color.GRAY)
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var big := StatusIcon.make(id, "", 0, icon_size)
	big.rich_tooltip = false
	row.add_child(big)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(260, 0)
	row.add_child(col)
	var title := Label.new()
	title.text = info_d.name
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", FRAME_COLORS.get(info_d.kind, Color.WHITE))
	col.add_child(title)
	var kind := Label.new()
	kind.text = {"debuff": "Дебафф", "buff": "Бафф", "special": "Особое"}.get(info_d.kind, "")
	if counter_text != "":
		kind.text += " · осталось: %s" % counter_text
	if source != "":
		kind.text += " · от: %s" % source
	kind.add_theme_font_size_override("font_size", 13)
	kind.modulate = Color(1, 1, 1, 0.7)
	col.add_child(kind)
	var desc := Label.new()
	desc.text = desc_text if desc_text != "" else info_d.desc
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(260, 0)
	desc.add_theme_font_size_override("font_size", 14)
	col.add_child(desc)
	return panel


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var frame: Color = FRAME_COLORS.get(info.get("kind", "special"), Color.GRAY)
	var tex := StatusIcon.texture_for(status_id)
	if tex:
		# Единая тёмная подложка: у части картинок прозрачный фон.
		draw_rect(r.grow(-2), Color("15161f"))
		draw_texture_rect(tex, r.grow(-2), false)
	else:
		draw_rect(r.grow(-2), Color(info.get("color", "#777777")))
		_draw_text_centered(String(info.get("short", "?")), Rect2(0, 0, size.x, size.y * 0.72), int(size.y * 0.38), Color.WHITE)
	draw_rect(r.grow(-1), frame, false, 2.0)
	var fs := clampi(int(size.y * 0.34), 10, 18)
	if counter != "":
		_badge(counter, fs, true)
	if stacks > 1:
		_badge("×%d" % stacks, fs, false)


## Число на тёмном жетоне: справа снизу (ходы) или слева сверху (стаки).
func _badge(text: String, fs: int, bottom_right: bool) -> void:
	var font := ThemeDB.fallback_font
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pad := Vector2(3, 1)
	var bs := Vector2(ts.x + pad.x * 2, fs + pad.y * 2)
	var pos := Vector2(size.x - bs.x, size.y - bs.y) if bottom_right else Vector2.ZERO
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0.8)
	box.set_corner_radius_all(3)
	draw_style_box(box, Rect2(pos, bs))
	var color := Color.WHITE if bottom_right else Color("ffd35a")
	draw_string(font, pos + Vector2(pad.x, pad.y + fs * 0.82), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _draw_text_centered(text: String, r: Rect2, fs: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pos := Vector2((r.size.x - sz.x) / 2.0, (r.size.y + fs * 0.7) / 2.0)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


## Все иконки участника боя: особые метки, Укрепление, Щит, затем статусы.
static func icons_for(u: Unit, icon_size: int = 30, names: Dictionary = {}) -> Array[StatusIcon]:
	var out: Array[StatusIcon] = []
	if u.is_boss:
		out.append(make("boss", "", 0, icon_size))
	if u.is_leader:
		out.append(make("leader", "", 0, icon_size))
	if u.passive != "":
		out.append(make(u.passive, "", 0, icon_size))
	if u.creature:
		var ic := make("creature", "", 0, icon_size)
		var cr: Dictionary = GameData.creatures().get(u.class_id, {})
		ic.desc_override = "%s. Ходит само, исчезает в конце боя." % String(cr.get("text", "")).trim_suffix(".")
		ic.tooltip_text = ic.desc_override
		out.append(ic)
	if u.fortify > 0.0:
		out.append(make("fortify", Unit._num(u.fortify), 0, icon_size))
	if u.shield > 0.0:
		out.append(make("shield", Unit._num(u.shield), 0, icon_size))
	for id in u.statuses:
		var s: Dictionary = u.statuses[id]
		var turns := "" if s.turns >= 99 else str(s.turns)
		var icon := make(id, turns, int(s.stacks) if id in ["poison", "dead_poison"] else 0, icon_size)
		icon.source_name = names.get(int(s.source), "")
		out.append(icon)
	return out
