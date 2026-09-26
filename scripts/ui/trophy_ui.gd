extends Control
## После победы над боссом: отряд выбирает Трофей или Проклятый трофей и отдаёт его
## одному волшебнику. Здесь же видно, кто получил шрам босса.

signal done

var adventure: Adventure
var _kind := "trophy"
var _wizard: Wizard
var _kind_cards := {}
var _wizard_buttons := {}
var _take: Button


func setup(adv: Adventure) -> void:
	adventure = adv
	for w in adv.wizards:
		if w.alive():
			_wizard = w
			break
	if _wizard == null:
		_wizard = adv.wizards[0]


func _ready() -> void:
	add_child(Art.background("bg_camp", 0.6))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	center.add_child(col)
	var offer := adventure.trophy_offer()

	var title := Label.new()
	title.text = "%s повержен! Выберите трофей" % offer.get("name", "Босс")
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var hint := Label.new()
	hint.text = "Трофей остаётся у волшебника до конца приключения. Проклятый сильнее, но с подвохом."
	hint.modulate = Color(1, 1, 1, 0.75)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 20)
	col.add_child(cards)
	for kind in ["trophy", "cursed"]:
		var card := _kind_card(kind, offer[kind])
		_kind_cards[kind] = card
		cards.add_child(card)

	var who := Label.new()
	who.text = "Кому отдать:"
	who.add_theme_font_size_override("font_size", 17)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(who)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	for w in adventure.wizards:
		var b := Button.new()
		b.text = w.name + ("" if w.alive() else " (выбыл)")
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(func() -> void:
			_wizard = w
			_sync())
		_wizard_buttons[w] = b
		row.add_child(b)

	if not adventure.last_scars.is_empty():
		var scars := Label.new()
		var lines := []
		var scar: Dictionary = offer.scar
		for s in adventure.last_scars:
			lines.append("%s получает шрам «%s»: %s" % [s.wizard.name, scar.name, scar.text])
		scars.text = "\n".join(lines)
		scars.add_theme_color_override("font_color", Color("ff9a8a"))
		scars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(scars)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(bottom)
	_take = Button.new()
	_take.custom_minimum_size = Vector2(300, 52)
	_take.add_theme_font_size_override("font_size", 18)
	_take.pressed.connect(func() -> void:
		adventure.award_trophy(_kind, _wizard)
		done.emit())
	bottom.add_child(_take)
	_sync()


func _kind_card(kind: String, data: Dictionary) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(340, 150)
	b.pressed.connect(func() -> void:
		_kind = kind
		_sync())
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_right = -18
	box.offset_top = 14
	box.offset_bottom = -14
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var head := Label.new()
	head.text = "Трофей" if kind == "trophy" else "Проклятый трофей"
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", Color("ffd35a") if kind == "trophy" else Color("d07cff"))
	box.add_child(head)
	var name_l := Label.new()
	name_l.text = data.name
	name_l.add_theme_font_size_override("font_size", 20)
	box.add_child(name_l)
	var text := Label.new()
	text.text = data.text
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 14)
	box.add_child(text)
	return b


func _sync() -> void:
	for kind in _kind_cards:
		_kind_cards[kind].set_pressed_no_signal(kind == _kind)
		_kind_cards[kind].modulate = Color.WHITE if kind == _kind else Color(0.65, 0.65, 0.65)
	for w in _wizard_buttons:
		_wizard_buttons[w].set_pressed_no_signal(w == _wizard)
		_wizard_buttons[w].modulate = Color.WHITE if w == _wizard else Color(0.7, 0.7, 0.7)
	var data: Dictionary = adventure.trophy_offer().get(_kind, {})
	_take.text = "Отдать «%s»: %s" % [data.get("name", ""), _wizard.name]
