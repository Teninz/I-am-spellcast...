class_name BookView
extends Control
## Просмотр книги: все 30 заклинаний с шансами, шансы по типам, состав мешочка.
## При баффе удачи — шкала удачи на 10 %: проценты вкладываются в заклинания или типы,
## шансы остальных заклинаний пропорционально уменьшаются. Без баффа — только просмотр.

signal plan_changed(plan: Dictionary)
signal cast_pressed(plan: Dictionary)

const UP := Color("7ee08a")
const DOWN := Color("ff8f80")

var book: Dictionary
var odds: Dictionary
var plan: Dictionary = {}
var luck := false
var cast_label := ""
var luck_note := ""  # почему шкала недоступна (если luck == false)

var _cats_box: GridContainer
var _list: VBoxContainer
var _scroll: ScrollContainer
var _meter: ProgressBar
var _meter_label: Label


## parent — куда открыть; odds — шансы троек для этого волшебника (Combat.book_odds).
static func open(parent: Control, book_data: Dictionary, book_odds: Dictionary, can_luck: bool,
		start_plan: Dictionary = {}, cast_text: String = "", note: String = "") -> BookView:
	var v := BookView.new()
	v.book = book_data
	v.odds = book_odds
	v.luck = can_luck
	v.plan = start_plan.duplicate()
	v.cast_label = cast_text
	v.luck_note = note
	parent.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return v


func _ready() -> void:
	Sfx.play("book_open")
	mouse_filter = Control.MOUSE_FILTER_STOP
	top_level = true
	z_index = 10
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1180, 640)
	var box: StyleBox = Art.frame("panel_dialog", 80, 0.6)
	if box == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color("24232f")
		flat.set_corner_radius_all(10)
		box = flat
	box.set_content_margin_all(30)
	box.content_margin_top = 36
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)
	row.add_child(_left_column())
	row.add_child(_right_column())

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 12)
	col.add_child(bottom)
	var close := Button.new()
	close.text = "Закрыть"
	close.custom_minimum_size = Vector2(160, 44)
	close.pressed.connect(queue_free)
	bottom.add_child(close)
	if cast_label != "":
		var cast := Button.new()
		cast.text = cast_label
		cast.custom_minimum_size = Vector2(280, 44)
		cast.pressed.connect(func() -> void:
			cast_pressed.emit(plan.duplicate())
			queue_free())
		bottom.add_child(cast)
	_rebuild()


func _left_column() -> Control:
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(330, 0)
	left.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	left.add_child(head)
	head.add_child(Art.book_cover(book, 90))
	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_col)
	var name_l := _label(book.name, 20)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_col.add_child(name_l)
	var rarity := _label({"common": "Обычная", "rare": "Редкая", "epic": "Эпическая",
		"legendary": "Легендарная", "cursed": "Проклятая"}.get(book.get("rarity", ""), ""), 13)
	rarity.modulate = Color(1, 1, 1, 0.7)
	title_col.add_child(rarity)
	var flavor := _label(book.get("flavor", ""), 12)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.modulate = Color(1, 1, 1, 0.65)
	title_col.add_child(flavor)

	left.add_child(_label("Мешочек", 15))
	left.add_child(_bag_row())

	left.add_child(_label("Шансы по типам", 15))
	_cats_box = GridContainer.new()
	_cats_box.columns = 3 if not luck else 4
	_cats_box.add_theme_constant_override("h_separation", 10)
	_cats_box.add_theme_constant_override("v_separation", 4)
	left.add_child(_cats_box)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(spacer)
	left.add_child(_luck_panel())
	return left


func _bag_row() -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	var letters: Array = book.bag.keys()
	letters.erase(ChipBag.CHAOS)
	letters.append(ChipBag.CHAOS)
	for k in letters:
		if not book.bag.has(k):
			continue
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 2)
		item.add_child(_chip_icon(k, 26))
		item.add_child(_label("×%d" % int(book.bag[k]), 14))
		flow.add_child(item)
	return flow


func _luck_panel() -> Control:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.2, 0.17, 0.08, 0.6) if luck else Color(0.1, 0.1, 0.12, 0.6)
	box.border_color = Color("ffd35a") if luck else Color("55546a")
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var icon := TextureRect.new()
	icon.texture = Art.texture("res://assets/ui/stat_luck.png")
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(icon)
	var t := _label("Шкала удачи", 16)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	if luck:
		var reset := Button.new()
		reset.text = "Сбросить"
		reset.add_theme_font_size_override("font_size", 13)
		reset.pressed.connect(func() -> void: _set_plan({}))
		head.add_child(reset)
	_meter = ProgressBar.new()
	_meter.max_value = Luck.BUDGET
	_meter.show_percentage = false
	_meter.custom_minimum_size = Vector2(0, 14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ffd35a")
	fill.set_corner_radius_all(4)
	_meter.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(4)
	_meter.add_theme_stylebox_override("background", bg)
	v.add_child(_meter)
	_meter_label = _label("", 13)
	_meter_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_meter_label)
	if not luck:
		panel.modulate = Color(1, 1, 1, 0.7)
	return panel


func _right_column() -> Control:
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	right.add_child(_label("Заклинания — от частых к редким", 17))
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_list)
	return right


# --- Перерисовка ---------------------------------------------------------

func _set_plan(p: Dictionary) -> void:
	plan = Luck.clean(book, odds, p)
	plan_changed.emit(plan.duplicate())
	_rebuild()


func _invest(key: String, delta: int) -> void:
	var p := plan.duplicate()
	var cur := int(p.get(key, 0))
	if delta > 0 and Luck.spent(plan) + delta > Luck.BUDGET:
		return
	p[key] = maxi(0, cur + delta)
	if p[key] == 0:
		p.erase(key)
	_set_plan(p)


func _rebuild() -> void:
	var now := Luck.shifted(book, odds, plan)
	var base_cats := Luck.by_category(book, odds)
	var new_cats := Luck.by_category(book, now)
	for c in _cats_box.get_children():
		c.queue_free()
	var cat_ids := base_cats.keys()
	cat_ids.sort_custom(func(a: String, b: String) -> bool: return base_cats[a] > base_cats[b])
	for cat in cat_ids:
		_cats_box.add_child(_label(Luck.CATEGORY_NAMES.get(cat, cat), 14))
		_cats_box.add_child(_label(_pct(base_cats[cat]), 14))
		_cats_box.add_child(_change_label(base_cats[cat], new_cats[cat]))
		if luck:
			_cats_box.add_child(_stepper(Luck.cat_key(cat)))

	var used := Luck.spent(plan)
	_meter.value = used
	if luck:
		_meter_label.text = "Вложено %d %% из %d %%. Жми «+» у заклинания или типа — его шанс вырастет, остальные уменьшатся. Действует на этот каст." % [used, Luck.BUDGET]
	else:
		_meter_label.text = luck_note if luck_note != "" else "Нужен бафф удачи (Благословение) — без него шансы менять нельзя."

	var keep := _scroll.scroll_vertical
	for c in _list.get_children():
		c.queue_free()
	var spells: Array = book.spells.duplicate()
	spells.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(odds.get(a.combo, 0.0)) > float(odds.get(b.combo, 0.0)))
	for sp in spells:
		_list.add_child(_spell_row(sp, float(odds.get(sp.combo, 0.0)), float(now.get(sp.combo, 0.0))))
	await get_tree().process_frame
	_scroll.scroll_vertical = keep


func _spell_row(sp: Dictionary, base: float, now: float) -> Control:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	var invested := int(plan.get(Luck.spell_key(sp.combo), 0)) > 0
	box.bg_color = Color(0.3, 0.25, 0.08, 0.55) if invested else Color(0.08, 0.07, 0.11, 0.6)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", box)
	if base <= 0.0:
		panel.modulate = Color(1, 1, 1, 0.45)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var chips := HBoxContainer.new()
	chips.custom_minimum_size = Vector2(84, 0)
	chips.add_theme_constant_override("separation", 2)
	if sp.combo.begins_with(ChipBag.CHAOS):
		for i in int(sp.combo.substr(1)):
			chips.add_child(_chip_icon(ChipBag.CHAOS, 26))
	else:
		for ch in sp.combo:
			chips.add_child(_chip_icon(ch, 26))
	row.add_child(chips)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	var name_l := _label(sp.name, 15)
	name_l.add_theme_color_override("font_color", Color("ffd35a") if sp.category == "damage" else Color.WHITE)
	text.add_child(name_l)
	var eff := _label("%s · %s" % [Luck.CATEGORY_NAMES.get(sp.category, sp.category), sp.effect], 12)
	eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eff.modulate = Color(1, 1, 1, 0.8)
	text.add_child(eff)
	row.add_child(text)

	var chance := VBoxContainer.new()
	chance.custom_minimum_size = Vector2(76, 0)
	var b := _label(_pct(base) if base > 0.0 else "не выпадет", 15)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chance.add_child(b)
	var n := _change_label(base, now)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chance.add_child(n)
	row.add_child(chance)
	if luck:
		row.add_child(_stepper(Luck.spell_key(sp.combo)))
	return panel


## [−] 3 % [+] — вклад удачи.
func _stepper(key: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 2)
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ok := Luck.can_invest(book, odds, key)
	var cur := int(plan.get(key, 0))
	var minus := _small_button("−", cur <= 0)
	minus.pressed.connect(_invest.bind(key, -Luck.STEP))
	h.add_child(minus)
	var v := _label("%d %%" % cur if cur > 0 else "", 13)
	v.custom_minimum_size = Vector2(34, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_color_override("font_color", Color("ffd35a"))
	h.add_child(v)
	var plus := _small_button("+", not ok or Luck.spent(plan) >= Luck.BUDGET)
	plus.pressed.connect(_invest.bind(key, Luck.STEP))
	h.add_child(plus)
	return h


func _small_button(text: String, disabled: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(32, 28)
	b.add_theme_font_size_override("font_size", 15)
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color("4a3a1a")
	flat.border_color = Color("ffd35a")
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(5)
	b.add_theme_stylebox_override("normal", flat)
	var hover := flat.duplicate()
	hover.bg_color = Color("6a5424")
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var off := flat.duplicate()
	off.bg_color = Color(0.15, 0.15, 0.17, 0.6)
	off.border_color = Color("444")
	b.add_theme_stylebox_override("disabled", off)
	return b


func _change_label(base: float, now: float) -> Label:
	var l := _label("", 13)
	if absf(now - base) >= 0.0005:
		l.text = "→ %s" % _pct(now)
		l.add_theme_color_override("font_color", UP if now > base else DOWN)
	return l


func _chip_icon(letter: String, size_px: int) -> Control:
	var tr := TextureRect.new()
	tr.texture = Art.chip(letter)
	tr.material = Art.circle_material()
	tr.custom_minimum_size = Vector2(size_px, size_px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tr


static func _pct(p: float) -> String:
	var v := p * 100.0
	return "%.1f %%" % v if v < 10.0 else "%.0f %%" % v


func _label(text: String, size_px: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	return l
