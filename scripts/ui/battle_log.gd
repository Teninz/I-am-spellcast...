class_name BattleLog
extends HBoxContainer
## Журнал боя: записи по ходам, цвет и иконка по типу события, главное выделено.
## Режим «Главное» оставляет только важное: касты, Хаос, выбывания, особые атаки,
## крупный урон и лечение, отражения, промахи целью, удачу.

## kind -> [цвет, иконка (путь или ""), главное?, выделить фоном?]
const STYLES := {
	"title": ["ffffff", "", true, false],
	"cast": ["ffd35a", "res://assets/chips/bag.png", true, false],
	"chaos": ["e8a0ff", "res://assets/icons/status/chaos_curse.png", true, true],
	"damage": ["ff9a8a", "res://assets/icons/status/vulnerable.png", false, false],
	"big_damage": ["ff7a66", "res://assets/icons/status/vulnerable.png", true, false],
	"heal": ["86e08a", "res://assets/icons/status/regen.png", false, false],
	"big_heal": ["6cf07a", "res://assets/icons/status/regen.png", true, false],
	"shield": ["8fc0ff", "res://assets/icons/status/shield.png", false, false],
	"block": ["a9bccf", "res://assets/icons/status/shield.png", false, false],
	"buff": ["ffe19a", "", false, false],
	"debuff": ["cfa8ff", "", false, false],
	"dot": ["b8d68a", "", false, false],
	"curse": ["9fbf8f", "", false, false],
	"kill": ["ff6b6b", "res://assets/ui/art_defeat.png", true, true],
	"revive": ["8affc1", "res://assets/ui/stat_hp.png", true, true],
	"special": ["ffb347", "res://assets/icons/status/leader.png", true, true],
	"summon": ["ffb347", "res://assets/icons/status/leader.png", true, false],
	"misfire": ["ff9ff3", "res://assets/icons/status/confusion.png", true, false],
	"reflect": ["a0e0ff", "res://assets/icons/status/reflect.png", true, false],
	"luck": ["d2f59a", "res://assets/ui/stat_luck.png", true, false],
	"resist": ["b8c0d0", "res://assets/ui/stat_resist.png", false, false],
	"meter": ["9fd0e0", "res://assets/ui/stat_speed.png", false, false],
	"control": ["b0b0b8", "res://assets/icons/status/stun.png", false, false],
	"enemy": ["e8c2b4", "", false, false],
	"enemy_heal": ["a8d8a8", "res://assets/icons/status/regen.png", false, false],
	"item": ["e0cfa8", "", false, false],
	"bad": ["ff7070", "", true, false],
	"fizzle": ["9a9aa4", "", false, false],
	"outcome": ["ffd35a", "", true, true],
	"info": ["d8d8e0", "", false, false],
}
const HIGHLIGHT := {
	"chaos": "#3b2150", "kill": "#4a1818", "revive": "#16402c", "special": "#46300f", "outcome": "#3d3310",
}
const PARTY_COLOR := "9cc8ff"
const ENEMY_COLOR := "ffab8f"
const ICON := 18

var key_only := false
var _text: RichTextLabel
var _all_btn: Button
var _key_btn: Button
var _entries: Array[Dictionary] = []  # {turn, text, kind, icon}
var _turns: Array[Dictionary] = []    # {name, side}
var _names := {}  # имя -> сторона


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_following = true
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.05, 0.09, 0.8)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(8)
	_text.add_theme_stylebox_override("normal", box)
	_text.add_theme_font_size_override("normal_font_size", 14)
	_text.add_theme_font_size_override("bold_font_size", 15)
	add_child(_text)
	# Переключатели справа, столбиком — журнал не теряет строку по высоте.
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 6)
	add_child(side)
	var title := Label.new()
	title.text = "Журнал"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	side.add_child(title)
	_key_btn = _toggle("Главное", true)
	side.add_child(_key_btn)
	_all_btn = _toggle("Всё", false)
	side.add_child(_all_btn)
	_sync_buttons()


func _toggle(label: String, key: bool) -> Button:
	var b := Button.new()
	b.text = label
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size = Vector2(96, 30)
	b.pressed.connect(func() -> void:
		key_only = key
		_sync_buttons()
		_render())
	return b


func _sync_buttons() -> void:
	_all_btn.set_pressed_no_signal(not key_only)
	_key_btn.set_pressed_no_signal(key_only)
	_all_btn.modulate = Color(1, 1, 1, 1) if not key_only else Color(0.6, 0.6, 0.6, 0.8)
	_key_btn.modulate = Color(1, 1, 1, 1) if key_only else Color(0.6, 0.6, 0.6, 0.8)


## Имена участников — чтобы раскрашивать их цветом стороны.
func set_units(units: Array) -> void:
	for u in units:
		_names[u.name] = u.side


func clear() -> void:
	_entries.clear()
	_turns.clear()
	_names.clear()
	_text.clear()


func start_turn(u: Unit) -> void:
	_names[u.name] = u.side
	_turns.append({"name": u.name, "side": u.side})


func add(text: String, kind: String = "info", icon: String = "") -> void:
	var e := {"turn": _turns.size() - 1, "text": text, "kind": kind, "icon": icon}
	_entries.append(e)
	if not _visible(e):
		return
	# Заголовок хода — перед первой показанной записью этого хода.
	if e.turn >= 0 and _first_visible_in_turn(e):
		_text.append_text(_turn_line(e.turn))
	_text.append_text(_line(e))


static func is_key(kind: String) -> bool:
	return STYLES.get(kind, STYLES.info)[2]


func _visible(e: Dictionary) -> bool:
	return not key_only or is_key(e.kind)


func _first_visible_in_turn(e: Dictionary) -> bool:
	for other in _entries:
		if other == e:
			return true
		if other.turn == e.turn and _visible(other):
			return false
	return true


func _render() -> void:
	_text.clear()
	var shown_turn := -2
	for e in _entries:
		if not _visible(e):
			continue
		if e.turn >= 0 and e.turn != shown_turn:
			_text.append_text(_turn_line(e.turn))
		shown_turn = e.turn
		_text.append_text(_line(e))


func _turn_line(turn: int) -> String:
	var t: Dictionary = _turns[turn]
	var col := PARTY_COLOR if t.side == Unit.PARTY else ENEMY_COLOR
	return "[font_size=12][color=#%s80]━━  Ход %d · %s  ━━[/color][/font_size]\n" % [col, turn + 1, t.name]


func _line(e: Dictionary) -> String:
	var st: Array = STYLES.get(e.kind, STYLES.info)
	var body := _escape(String(e.text))
	if e.kind in ["damage", "big_damage", "heal", "big_heal", "shield", "block", "revive"]:
		body = _bold_numbers(body)
	body = _paint_names(body)
	if st[2]:
		body = "[b]%s[/b]" % body
	var line := "%s[color=#%s]%s[/color]" % [_icon(e, st), st[0], body]
	if HIGHLIGHT.has(e.kind):
		line = "[bgcolor=%s]%s [/bgcolor]" % [HIGHLIGHT[e.kind], line]
	return line + "\n"


func _icon(e: Dictionary, st: Array) -> String:
	var path: String = st[1]
	if e.icon != "":
		var status_path := "res://assets/icons/status/%s.png" % e.icon
		if ResourceLoader.exists(status_path):
			path = status_path
	if path == "" or not ResourceLoader.exists(path):
		return ""
	return "[img=%dx%d]%s[/img] " % [ICON, ICON, path]


static func _escape(s: String) -> String:
	return s.replace("[", "[lb]")


static func _bold_numbers(s: String) -> String:
	var re := RegEx.create_from_string("(\\d+(?:\\.\\d)?)")
	return re.sub(s, "[b]$1[/b]", true)


func _paint_names(s: String) -> String:
	var names := _names.keys()
	names.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	# Сначала метки, потом цвет — чтобы короткое имя не нашлось внутри длинного.
	var marks := {}
	for i in names.size():
		var n: String = names[i]
		if s.contains(n):
			var mark := "\u0001%d\u0002" % i
			s = s.replace(n, mark)
			marks[mark] = "[color=#%s]%s[/color]" % [PARTY_COLOR if _names[n] == Unit.PARTY else ENEMY_COLOR, n]
	for mark in marks:
		s = s.replace(mark, marks[mark])
	return s
