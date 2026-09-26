extends Control
## Выбор отряда перед приключением: 3 или 4 разных волшебника из открытых классов.
## Закрытые классы видны с условием открытия.

signal start_pressed(party: Array)
signal continue_pressed

const MIN_PARTY := 3
const MAX_PARTY := 4

var classes: Dictionary
var profile: Profile
var selected: Array = []

var _grid: GridContainer
var _start: Button
var _hint: Label


func setup(class_db: Dictionary, p: Profile) -> void:
	classes = class_db
	profile = p
	# По умолчанию — первые три открытых.
	for cid in profile.unlocked:
		if selected.size() < MIN_PARTY:
			selected.append(cid)


func _ready() -> void:
	add_child(Art.background("bg_party_select", 0.55))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var emblem := Art.texture("res://assets/ui/emblem.png")
	if emblem:
		var em := TextureRect.new()
		em.texture = emblem
		em.custom_minimum_size = Vector2(200, 100)
		em.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		em.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		em.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		head.add_child(em)
	var title := Label.new()
	title.text = "Я кастую! — собери отряд"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 8)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var gear := Button.new()
	gear.text = "Настройки"
	gear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gear.pressed.connect(func() -> void: SettingsView.open(self))
	head.add_child(gear)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.modulate = Color(1, 1, 1, 0.75)
	col.add_child(_hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grid)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(bottom)
	if SaveGame.exists():
		var cont := Button.new()
		cont.text = "Продолжить приключение"
		cont.tooltip_text = "Сохранено: %s.\nНовое приключение заменит сохранённое." % SaveGame.summary()
		cont.custom_minimum_size = Vector2(300, 52)
		cont.add_theme_font_size_override("font_size", 18)
		cont.pressed.connect(func() -> void: continue_pressed.emit())
		bottom.add_child(cont)
		var saved := Label.new()
		saved.text = SaveGame.summary()
		saved.modulate = Color(1, 1, 1, 0.7)
		saved.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		saved.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		saved.clip_text = true
		saved.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		bottom.add_child(saved)
	_start = Button.new()
	_start.custom_minimum_size = Vector2(260, 52)
	_start.add_theme_font_size_override("font_size", 19)
	_start.pressed.connect(func() -> void: start_pressed.emit(selected.duplicate()))
	bottom.add_child(_start)
	_rebuild()


func _rebuild() -> void:
	for c in _grid.get_children():
		c.queue_free()
	for cid in classes:
		_grid.add_child(_card(cid))
	var n := selected.size()
	_hint.text = "Выбери 3 или 4 разных волшебника. Выбрано: %d. Приключений сыграно: %d, побед: %d." % [
		n, profile.runs, profile.victories]
	_start.disabled = n < MIN_PARTY or n > MAX_PARTY
	_start.text = "В путь! (%d волшебника)" % n if not _start.disabled else "Нужно 3–4 волшебника"


func _card(cid: String) -> Control:
	var cfg: Dictionary = classes[cid]
	var open := profile.unlocked.has(cid)
	var on := selected.has(cid)
	var b := Button.new()
	b.custom_minimum_size = Vector2(380, 150)
	b.toggle_mode = true
	b.button_pressed = on
	b.disabled = not open
	var box := StyleBoxFlat.new()
	box.bg_color = Color("2d3a52") if on else Color("25283a")
	box.border_color = Color("ffd35a") if on else Color("3a3d52")
	box.set_border_width_all(3 if on else 1)
	box.set_corner_radius_all(8)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, box)
	var dis := box.duplicate()
	dis.bg_color = Color("1f2030")
	b.add_theme_stylebox_override("disabled", dis)
	b.pressed.connect(func() -> void:
		if selected.has(cid):
			selected.erase(cid)
		elif selected.size() < MAX_PARTY:
			selected.append(cid)
		_rebuild())

	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 10)
	b.add_child(m)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	m.add_child(row)
	var book: String = cfg.books[0]
	var cover: Control
	if Art.portrait(cid) != null:
		cover = Art.portrait_rect(Art.portrait_head(cid), Vector2(96, 128))
		if not open:
			cover.modulate = Color(0.35, 0.35, 0.4)  # закрытый класс — в тени
	else:
		cover = Art.book_cover(GameData.load_books_cached().get(book, {"id": book, "name": book}), 60)
	row.add_child(cover)
	var text := VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var name_l := Label.new()
	name_l.text = ("✔ " if on else "") + cfg.name + ("" if open else "  🔒")
	name_l.add_theme_font_size_override("font_size", 18)
	text.add_child(name_l)
	var info := Label.new()
	var book_name: String = GameData.load_books_cached().get(book, {}).get("name", book)
	info.text = "ЗД %s · %s · %s" % [Unit._num(float(cfg.hp)), book_name, cfg.ability_text] if open else "Закрыт. " + String(cfg.get("unlock", {}).get("text", ""))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(280, 0)
	info.add_theme_font_size_override("font_size", 12)
	info.modulate = Color(1, 1, 1, 0.85 if open else 0.6)
	text.add_child(info)
	for c in [m, row, text, name_l, info, cover]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b
