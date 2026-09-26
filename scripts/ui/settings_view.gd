class_name SettingsView
extends Control
## Окно настроек: скорость боя, громкость, автотяга фишек, обучение.
## Открывается кнопкой «Настройки» на выборе отряда, в бою и на привале.

signal closed


static func open(parent: Control) -> SettingsView:
	var v := SettingsView.new()
	parent.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Sfx.play("book_open")
	return v


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	top_level = true
	z_index = 10
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	var box: StyleBox = Art.frame("panel_dialog", 80, 0.6)
	if box == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color("24232f")
		box = flat
	box.set_content_margin_all(40)
	box.content_margin_top = 44
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)

	var title := Label.new()
	title.text = "Настройки"
	title.add_theme_font_size_override("font_size", 26)
	col.add_child(title)

	# Скорость боя — четыре кнопки-переключателя.
	col.add_child(_caption("Скорость боя (паузы и ход врагов)"))
	var speeds := HBoxContainer.new()
	speeds.add_theme_constant_override("separation", 8)
	col.add_child(speeds)
	var group := ButtonGroup.new()
	for i in Settings.SPEEDS.size():
		var b := Button.new()
		b.text = Settings.SPEED_NAMES[i]
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(130, 42)
		b.button_pressed = is_equal_approx(Settings.speed(), Settings.SPEEDS[i])
		var v: float = Settings.SPEEDS[i]
		b.pressed.connect(func() -> void:
			Settings.set_value("speed", v)
			_mark(speeds))
		speeds.add_child(b)
	_mark(speeds)

	col.add_child(_slider("Общая громкость", "master"))
	col.add_child(_slider("Звуки", "sfx"))
	col.add_child(_slider("Музыка (появится позже)", "music"))

	var auto_note := _caption("Фишки тянутся сами, если 5 секунд ничего не нажимать; вручную шанс на нужное заклинание чуть выше.")
	auto_note.autowrap_mode = TextServer.AUTOWRAP_WORD
	auto_note.add_theme_font_size_override("font_size", 13)
	auto_note.modulate = Color(1, 1, 1, 0.7)
	col.add_child(auto_note)
	var soft := _check()
	soft.text = "Мягкие цвета (меньше контраста и яркости)"
	soft.button_pressed = bool(Settings.value("soft_colors"))
	soft.toggled.connect(func(on: bool) -> void:
		Settings.set_value("soft_colors", on)
		var layer := get_tree().root.find_child("ColorGrade", true, false)
		if layer:
			layer.visible = on)
	col.add_child(soft)
	var tut := _check()
	tut.text = "Подсказки обучения в бою"
	tut.tooltip_text = "Показываются в первом бою. Включи снова, чтобы увидеть их ещё раз."
	tut.button_pressed = bool(Settings.value("tutorial"))
	tut.toggled.connect(func(on: bool) -> void: Settings.set_value("tutorial", on))
	col.add_child(tut)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 10)
	col.add_child(bottom)
	var test := Button.new()
	test.text = "Проверить звук"
	test.custom_minimum_size = Vector2(0, 44)
	test.pressed.connect(func() -> void: Sfx.play("cast_shout"))
	bottom.add_child(test)
	var close := Button.new()
	close.text = "Готово"
	close.custom_minimum_size = Vector2(160, 44)
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	bottom.add_child(close)


## Флажок без деревянной подложки кнопок из общей темы.
func _check() -> CheckBox:
	var c := CheckBox.new()
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		c.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	c.add_theme_font_size_override("font_size", 16)
	c.add_theme_icon_override("unchecked", _box_icon(false))
	c.add_theme_icon_override("checked", _box_icon(true))
	return c


## Квадратик флажка: светлая рамка; отмеченный — золотой с галочкой.
static func _box_icon(on: bool) -> Texture2D:
	var n := 22
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var frame := Color("ffd35a") if on else Color("c8c2b0")
	for i in n:
		for t in 2:
			img.set_pixel(i, t, frame)
			img.set_pixel(i, n - 1 - t, frame)
			img.set_pixel(t, i, frame)
			img.set_pixel(n - 1 - t, i, frame)
	if on:
		for y in range(3, n - 3):
			for x in range(3, n - 3):
				img.set_pixel(x, y, Color("ffd35a"))
		var dark := Color("2a1c08")
		for k in 5:  # галочка
			for w in 2:
				img.set_pixel(5 + k, 10 + k + w, dark)
		for k in 9:
			for w in 2:
				img.set_pixel(9 + k, 14 - k + w, dark)
	return ImageTexture.create_from_image(img)


func _mark(row: HBoxContainer) -> void:
	for b in row.get_children():
		b.modulate = Color.WHITE if b.button_pressed else Color(0.65, 0.65, 0.65)


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	return l


func _slider(text: String, key: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := _caption(text)
	l.custom_minimum_size = Vector2(250, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Settings.value(key))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(s)
	var pct := _caption("%d %%" % roundi(s.value * 100.0))
	pct.custom_minimum_size = Vector2(56, 0)
	row.add_child(pct)
	s.value_changed.connect(func(v: float) -> void:
		pct.text = "%d %%" % roundi(v * 100.0)
		Settings.set_value(key, v))
	s.drag_ended.connect(func(_changed: bool) -> void:
		if key != "music":
			Sfx.play("chip_draw"))
	return row
