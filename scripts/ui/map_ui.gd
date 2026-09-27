extends Control
## Карта акта: дерево локаций. После уровня отряд выбирает одну из двух дорог —
## вторая ветка со всеми продолжениями закрывается.

signal chosen(node_id: int)

const SITE_COLORS := {
	"path": Color("9a7650"),
	"library": Color("3f6f9e"),
	"cellar": Color("5b8a45"),
}
const BOSS_COLOR := Color("9e2b20")  # как сургучная печать
const GOLD := Color("ffd35a")

var adventure: Adventure
var _view: MapView
var _cards: VBoxContainer


func setup(adv: Adventure) -> void:
	adventure = adv


func _ready() -> void:
	add_child(Art.background("bg_map", 0.5, "bg_camp"))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	var title := Label.new()
	title.text = "Карта · %s" % adventure.config.get("name", "")
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 8)
	col.add_child(title)
	var hint := Label.new()
	hint.text = "Уровень %d из %d. Выбери дорогу — вторая ветка и всё, что за ней, закроются. Банды видно на два шага вперёд." % [
		adventure.level, adventure.level_count()]
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(1, 1, 1, 0.8)
	col.add_child(hint)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)

	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.add_theme_stylebox_override("panel", _framed("panel_dialog", 80, 0.45, 40, Color(0.07, 0.06, 0.1, 0.72), Color("5a586e")))
	row.add_child(map_panel)
	# Пергамент карты внутри рамки — затемнён, чтобы дороги и кружки читались.
	var parchment := Art.texture("res://assets/ui/bg_map.png")
	if parchment:
		var pr := TextureRect.new()
		pr.texture = parchment
		pr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		pr.clip_contents = true
		pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_panel.add_child(pr)
	var map_col := VBoxContainer.new()
	map_panel.add_child(map_col)
	_view = MapView.new()
	_view.adventure = adventure
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.node_clicked.connect(_on_node_clicked)
	map_col.add_child(_view)
	map_col.add_child(_legend())

	_cards = VBoxContainer.new()
	_cards.custom_minimum_size = Vector2(420, 0)
	_cards.add_theme_constant_override("separation", 12)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_cards)
	for n in adventure.choices():
		_cards.add_child(_choice_card(n))


func _on_node_clicked(id: int) -> void:
	if adventure.choices().any(func(n: Dictionary) -> bool: return n.id == id):
		chosen.emit(id)


func _panel_box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(12)
	return box


## Рамка из набора интерфейса (как у карточек и окон), без картинки — плоская панель.
func _framed(frame_name: String, margin: float, factor: float, content: float, bg: Color, border: Color) -> StyleBox:
	var sb: StyleBox = Art.frame(frame_name, margin, factor, content)
	return sb if sb != null else _panel_box(bg, border)


static func site_color(site: String) -> Color:
	return SITE_COLORS.get(site, SITE_COLORS.path)


## Карточка дороги: локация, банда, состав, особая атака предводителя, добыча.
func _choice_card(n: Dictionary) -> Control:
	var site := adventure.site_info(n.site)
	var enc := adventure.node_encounter(n.id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _framed("card_party", 40, 0.42, 20, Color(0.1, 0.09, 0.14, 0.9), site_color(n.site)))
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.mouse_entered.connect(func() -> void: _view.set_hover(n.id))
	panel.mouse_exited.connect(func() -> void: _view.set_hover(-1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var place := Label.new()
	place.text = site.get("name", "")
	place.add_theme_font_size_override("font_size", 19)
	place.add_theme_color_override("font_color", site_color(n.site).lightened(0.35))
	box.add_child(place)
	var loot := Label.new()
	loot.text = site.get("desc", "")
	loot.add_theme_font_size_override("font_size", 13)
	loot.modulate = Color(1, 1, 1, 0.75)
	box.add_child(loot)

	var gang := Label.new()
	var total := 0.0
	for m in enc.members:
		total += float(m.hp)
	gang.text = "%s · всего %s ЗД" % [enc.name, Unit._num(total)]
	gang.add_theme_font_size_override("font_size", 16)
	box.add_child(gang)
	var members := Label.new()
	members.text = _members_text(enc.members)
	members.autowrap_mode = TextServer.AUTOWRAP_WORD
	members.add_theme_font_size_override("font_size", 13)
	box.add_child(members)
	for m in enc.members:
		for sp in m.get("specials", []):
			var special := Label.new()
			special.text = "★ %s: «%s» — %s (раз в %d хода)" % [m.name, sp.name, sp.text, int(sp.cooldown)]
			special.autowrap_mode = TextServer.AUTOWRAP_WORD
			special.add_theme_font_size_override("font_size", 13)
			special.add_theme_color_override("font_color", GOLD)
			box.add_child(special)

	var ahead := []
	for c in n.children:
		if adventure.is_revealed(c):
			ahead.append(GameData.load_encounter(adventure.map_nodes[c].encounter).get("name", ""))
	if not ahead.is_empty():
		var further := Label.new()
		var boss_next: bool = adventure.map_nodes[n.children[0]].level == adventure.level_count()
		further.text = ("Дальше — босс: " if boss_next else "Дальше по этой дороге: ") + " или ".join(ahead)
		further.autowrap_mode = TextServer.AUTOWRAP_WORD
		further.add_theme_font_size_override("font_size", 13)
		further.modulate = Color(1, 1, 1, 0.7)
		box.add_child(further)

	var go := Button.new()
	go.text = "Идти сюда"
	go.custom_minimum_size = Vector2(200, 44)
	go.size_flags_horizontal = Control.SIZE_SHRINK_END
	go.add_theme_font_size_override("font_size", 17)
	go.pressed.connect(func() -> void: chosen.emit(n.id))
	go.mouse_entered.connect(func() -> void: _view.set_hover(n.id))
	box.add_child(go)
	panel.set_meta("node_id", n.id)
	panel.set_meta("button", go)
	return panel


## «Пьяный гоблин ×2 (ЗД 4.5, урон 1), …»
static func _members_text(members: Array) -> String:
	var order: Array[String] = []
	var groups := {}
	for m in members:
		var key := "%s|%s|%s|%s" % [m.name, m.hp, m.damage, m.get("attacks", 1)]
		if not groups.has(key):
			order.append(key)
			groups[key] = {"m": m, "n": 0}
		groups[key].n += 1
	var parts := []
	for key in order:
		var m: Dictionary = groups[key].m
		var n: int = groups[key].n
		var hits := " дважды" if int(m.get("attacks", 1)) > 1 else ""
		parts.append("%s%s (ЗД %s, урон %s%s)" % [m.name, " ×%d" % n if n > 1 else "",
			Unit._num(float(m.hp)), Unit._num(float(m.damage)), hits])
	return ", ".join(parts)


func _legend() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	var entries := []
	for site in ["path", "library", "cellar"]:
		entries.append([site_color(site), adventure.site_info(site).get("name", site)])
	entries.append([BOSS_COLOR, "Босс акта"])
	entries.append([GOLD, "Пройденный путь"])
	for e in entries:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 6)
		var dot := ColorRect.new()
		dot.color = e[0]
		dot.custom_minimum_size = Vector2(14, 14)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(dot)
		var l := Label.new()
		l.text = e[1]
		l.add_theme_font_size_override("font_size", 13)
		item.add_child(l)
		row.add_child(item)
	return row


## Само дерево: узлы по столбцам-уровням, линии дорог, пройденный путь золотом.
class MapView:
	extends Control

	signal node_clicked(id: int)

	var adventure: Adventure
	var hover := -1
	var _pos := {}  # id -> Vector2 в долях (0..1)
	var _time := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		tooltip_text = " "  # включает _get_tooltip
		_layout()

	func set_hover(id: int) -> void:
		hover = id
		queue_redraw()

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	## Раскладка: листья (или узлы перед общим боссом) — равномерно по вертикали,
	## родитель — посередине между детьми, общий узел — посередине между родителями.
	func _layout() -> void:
		var counter := [0]
		var ys := {}
		_place(0, ys, counter)
		var leaves := maxi(1, counter[0])
		var levels := adventure.level_count()
		for n in adventure.map_nodes:
			if not ys.has(n.id):
				var sum := 0.0
				for p in n.parents:
					sum += ys[p]
				ys[n.id] = sum / maxf(1.0, n.parents.size())
			var x := 0.07 + 0.8 * float(n.level - 1) / maxf(1.0, levels - 1)
			_pos[n.id] = Vector2(x, 0.1 + 0.84 * (float(ys[n.id]) + 0.5) / leaves)

	func _place(id: int, ys: Dictionary, counter: Array) -> float:
		var n: Dictionary = adventure.map_nodes[id]
		var own: Array = n.children.filter(func(c: int) -> bool:
			return adventure.map_nodes[c].parents.size() == 1)
		if own.is_empty():
			ys[id] = float(counter[0])
			counter[0] += 1
			return ys[id]
		var sum := 0.0
		for c in own:
			sum += _place(c, ys, counter)
		ys[id] = sum / own.size()
		return ys[id]

	func _p(id: int) -> Vector2:
		return _pos[id] * size

	func _radius(id: int) -> float:
		if _is_choice(id):
			return 17.0
		if id == adventure.node_id:
			return 14.0
		if adventure.map_nodes[id].parents.size() > 1:
			return 18.0
		return 9.0

	func _is_choice(id: int) -> bool:
		return adventure.needs_choice() and adventure.node().children.has(id)

	## Узлы, которые откроются, если выбрать hover.
	func _highlighted() -> Dictionary:
		if hover < 0:
			return {}
		var out := adventure._reachable_from(hover)
		out[hover] = true
		return out

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var levels := adventure.level_count()
		for l in levels:
			var x := (0.07 + 0.8 * float(l) / maxf(1.0, levels - 1)) * size.x
			var head := "Босс" if l == levels - 1 else "Ур. %d" % (l + 1)
			var col := Color.WHITE if l + 1 == adventure.level else Color(1, 1, 1, 0.55)
			var w := font.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			draw_string(font, Vector2(x - w / 2.0, 22), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
		var lit := _highlighted()
		# Дороги.
		for n in adventure.map_nodes:
			for c in n.children:
				var on_path := adventure.path.has(n.id) and adventure.path.has(c)
				var col := Color(1, 1, 1, 0.35)
				var width := 2.0
				if on_path:
					col = GOLD
					width = 4.0
				elif lit.has(c) and (lit.has(n.id) or n.id == adventure.node_id):
					col = Color(1, 1, 1, 0.95)
					width = 3.0
				elif adventure.is_closed(c):
					col = Color(1, 1, 1, 0.08)
				draw_line(_p(n.id), _p(c), col, width, true)
		# Узлы.
		for n in adventure.map_nodes:
			var id: int = n.id
			var p := _p(id)
			var r := _radius(id)
			var boss: bool = n.parents.size() > 1 or n.level == levels
			var fill: Color = BOSS_COLOR if boss else SITE_COLORS.get(n.site, SITE_COLORS.path)
			var closed := adventure.is_closed(id)
			if closed:
				fill = Color(0.35, 0.35, 0.38, 0.35)
			elif not adventure.path.has(id) and not _is_choice(id) and not lit.has(id):
				fill = fill.darkened(0.25)
			if _is_choice(id):
				var pulse := 0.5 + 0.5 * sin(_time * 4.0)
				draw_circle(p, r + 6.0 + 3.0 * pulse, Color(GOLD, 0.25 + 0.25 * pulse))
			# Пергаментный жетон: мягкая тень, чернильный обод, выцветшая заливка, тонкое внутреннее кольцо.
			var ink := Color("2e1f12")
			var faded := fill.lerp(Color("e3cf9f"), 0.3) if not closed else Color(0.55, 0.5, 0.42, 0.5)
			draw_circle(p + Vector2(1.5, 2.5), r + 2.0, Color(0.15, 0.1, 0.05, 0.35))
			draw_circle(p, r + 1.5, ink)
			draw_circle(p, r - 1.0, faded)
			draw_circle(p + Vector2(0, r * 0.18), r * 0.78, faded.darkened(0.12))  # тень снизу — «вдавлено» в бумагу
			draw_circle(p - Vector2(0, r * 0.05), r * 0.72, faded)
			draw_arc(p, r * 0.72, 0, TAU, 40, Color(ink, 0.55), 1.2, true)
			draw_arc(p, r - 1.0, PI * 1.1, PI * 1.6, 12, Color(1, 0.97, 0.85, 0.35), 1.5, true)  # блик на ободе
			var ring := Color(0, 0, 0, 0)
			if adventure.path.has(id):
				ring = GOLD
			elif id == hover:
				ring = Color("fff4dc")
			if ring.a > 0.0:
				draw_arc(p, r + 3.5, 0, TAU, 40, ring, 2.5, true)
			if id == adventure.node_id:
				draw_circle(p, r * 0.36, Color("2e1f12"))
				draw_circle(p, r * 0.28, GOLD)
			elif not adventure.is_revealed(id) and not closed:
				_centered(font, "?", p, 14, Color("fff4dc"))
			if _is_choice(id) or (boss and not closed):
				var label: String = GameData.load_encounter(n.encounter).get("name", "") if adventure.is_revealed(id) else "?"
				_centered(font, label, p + Vector2(0, r + 16), 13, Color.WHITE)

	func _centered(font: Font, text: String, at: Vector2, fs: int, col: Color) -> void:
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string_outline(font, at + Vector2(-w / 2.0, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.8))
		draw_string(font, at + Vector2(-w / 2.0, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	func _node_at(at: Vector2) -> int:
		for n in adventure.map_nodes:
			if _p(n.id).distance_to(at) <= _radius(n.id) + 5.0:
				return n.id
		return -1

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var id := _node_at(event.position)
			if id != hover and (id < 0 or _is_choice(id)):
				set_hover(id)
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _is_choice(id) else Control.CURSOR_ARROW
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var id := _node_at(event.position)
			if id >= 0:
				node_clicked.emit(id)

	func _get_tooltip(at: Vector2) -> String:
		var id := _node_at(at)
		if id < 0:
			return ""
		var n: Dictionary = adventure.map_nodes[id]
		var lines := [adventure.site_info(n.site).get("name", "")]
		lines.append(GameData.load_encounter(n.encounter).get("name", "") if adventure.is_revealed(id) else "Кто там — неизвестно")
		if adventure.path.has(id):
			lines.append("Пройдено" if id != adventure.node_id or adventure.needs_choice() else "Здесь отряд")
		elif adventure.is_closed(id):
			lines.append("Дорога закрыта")
		return "\n".join(lines)

