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

var status_id := ""
var counter := ""  # число в правом нижнем углу (ходы, остаток щита)
var stacks := 0    # число стаков в левом верхнем углу (яд)
var info: Dictionary = {}


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
	icon.tooltip_text = "%s%s\n%s" % [icon.info.name, " (%s)" % counter_text if counter_text != "" else "", icon.info.desc]
	return icon


static func texture_for(id: String) -> Texture2D:
	if not _textures.has(id):
		var path := ICON_DIR + id + ".png"
		_textures[id] = load(path) if ResourceLoader.exists(path) else null
	return _textures[id]


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var frame: Color = FRAME_COLORS.get(info.get("kind", "special"), Color.GRAY)
	var tex := StatusIcon.texture_for(status_id)
	if tex:
		draw_texture_rect(tex, r.grow(-2), false)
	else:
		draw_rect(r.grow(-2), Color(info.get("color", "#777777")))
		_draw_text_centered(String(info.get("short", "?")), Rect2(0, 0, size.x, size.y * 0.72), int(size.y * 0.38), Color.WHITE)
	draw_rect(r.grow(-1), frame, false, 2.0)
	var font := ThemeDB.fallback_font
	var fs := int(size.y * 0.4)
	if counter != "":
		var w := font.get_string_size(counter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(size.x - w - 1, size.y - 2)
		draw_string_outline(font, pos, counter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.BLACK)
		draw_string(font, pos, counter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	if stacks > 1:
		var t := "×%d" % stacks
		var pos2 := Vector2(2, fs)
		draw_string_outline(font, pos2, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, 4, Color.BLACK)
		draw_string(font, pos2, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, Color("ffd35a"))


func _draw_text_centered(text: String, r: Rect2, fs: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pos := Vector2((r.size.x - sz.x) / 2.0, (r.size.y + fs * 0.7) / 2.0)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


## Все иконки участника боя: особые метки, Укрепление, Щит, затем статусы.
static func icons_for(u: Unit, icon_size: int = 30) -> Array[StatusIcon]:
	var out: Array[StatusIcon] = []
	if u.is_boss:
		out.append(make("boss", "", 0, icon_size))
	if u.is_leader:
		out.append(make("leader", "", 0, icon_size))
	if u.passive != "":
		out.append(make(u.passive, "", 0, icon_size))
	if u.fortify > 0.0:
		out.append(make("fortify", Unit._num(u.fortify), 0, icon_size))
	if u.shield > 0.0:
		out.append(make("shield", Unit._num(u.shield), 0, icon_size))
	for id in u.statuses:
		var s: Dictionary = u.statuses[id]
		var turns := "" if s.turns >= 99 else str(s.turns)
		out.append(make(id, turns, int(s.stacks) if id == "poison" else 0, icon_size))
	return out
