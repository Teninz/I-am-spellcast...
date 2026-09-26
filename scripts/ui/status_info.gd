class_name StatusInfo
extends Control
## Окно «Инфо»: все иконки эффектов с объяснениями (как справка в Raid).

const GROUPS := [
	["debuff", "Дебаффы — вредные эффекты"],
	["buff", "Баффы — полезные эффекты"],
	["special", "Особые метки"],
]


static func open(parent: Control) -> StatusInfo:
	var w := StatusInfo.new()
	parent.add_child(w)
	w.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return w


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	top_level = true  # поверх всего, включая «штампы» эффектов
	z_index = 10
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1040, 600)
	var box: StyleBox = Art.frame("panel_dialog", 80, 0.6)
	if box == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color("24232f")
		flat.set_corner_radius_all(10)
		flat.border_color = Color("5a586e")
		flat.set_border_width_all(2)
		box = flat
	box.set_content_margin_all(34)
	box.content_margin_top = 42
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := Label.new()
	title.text = "Инфо: что значат иконки"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(queue_free)
	head.add_child(close)
	var hint := Label.new()
	hint.text = "Число в правом нижнем углу — сколько ходов эффект ещё продержится (у Щита и Укрепления — сколько осталось). Наведи мышь на иконку в бою, чтобы увидеть подсказку."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(1, 1, 1, 0.7)
	col.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var all := GameData.statuses()
	for g in GROUPS:
		var gl := Label.new()
		gl.text = g[1]
		gl.add_theme_font_size_override("font_size", 17)
		gl.add_theme_color_override("font_color", StatusIcon.FRAME_COLORS[g[0]])
		list.add_child(gl)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 18)
		grid.add_theme_constant_override("v_separation", 12)
		list.add_child(grid)
		for id in all:
			if all[id].kind != g[0]:
				continue
			var row := HBoxContainer.new()
			row.custom_minimum_size = Vector2(480, 0)
			row.add_theme_constant_override("separation", 12)
			row.add_child(StatusIcon.make(id, "", 0, 80))
			var text_col := VBoxContainer.new()
			text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var name_l := Label.new()
			name_l.text = all[id].name
			name_l.add_theme_font_size_override("font_size", 17)
			text_col.add_child(name_l)
			var text := Label.new()
			text.text = all[id].desc
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text.custom_minimum_size = Vector2(380, 0)
			text.add_theme_font_size_override("font_size", 13)
			text.modulate = Color(1, 1, 1, 0.85)
			text_col.add_child(text)
			row.add_child(text_col)
			grid.add_child(row)
