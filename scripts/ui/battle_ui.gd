extends Control
## Экран боя прототипа. Весь интерфейс строится кодом, логика — в Combat.
##
## Ход волшебника: выбрать цель (клик по карточке) → выбрать книгу →
## трижды «Достать фишку» (или авто раз в 2 секунды) → «Я кастую!».
## Пиромант может кликнуть по вытянутой фишке, чтобы сжечь её (3 раза за бой).

enum State { ENEMY_TURN, CHOOSE_TARGET, CHOOSE_BOOK, DRAWING, READY, OVER }

const PARTY := ["pyromancer", "priest", "water"]
const ENCOUNTER := "rat_pack"
const AUTO_DRAW_DELAY := 2.0
const AUTO_CAST_DELAY := 1.2
const ENEMY_DELAY := 0.8

const ELEMENT_NAMES := {
	"F": "Огонь", "W": "Вода", "H": "Святость", "D": "Тьма", "E": "Земля", "M": "Механика",
	"S": "Звук", "T": "Тайна", "I": "Иллюзия", "L": "Молния", "C": "Время", "K": "Лёд",
	"A": "Воздух", "X": "ХАОС",
}
const ELEMENT_COLORS := {
	"F": Color("d9502e"), "W": Color("3b82d6"), "H": Color("e8c547"), "D": Color("5b3a7a"),
	"E": Color("4f9a3a"), "M": Color("8a8f98"), "S": Color("d46fb0"), "T": Color("7a5bd6"),
	"I": Color("5fc9c9"), "L": Color("f0e04a"), "C": Color("b08a5a"), "K": Color("a8e0f5"),
	"A": Color("c9e8d0"), "X": Color("111111"),
}

## Для тестов: ускоряет все задержки.
var fast := false

var books: Dictionary
var classes: Dictionary
var combat: Combat
var state: State = State.OVER
var actor: Unit
var target: Unit
var book_id := ""
var bag: ChipBag

var _cards := {}  # id участника -> Button
var _chip_buttons: Array[Button] = []
var _queue_label: Label
var _prompt_label: Label
var _spell_label: Label
var _shout_label: Label
var _ability_label: Label
var _party_box: VBoxContainer
var _enemy_box: VBoxContainer
var _book_box: HBoxContainer
var _draw_button: Button
var _cast_button: Button
var _auto_check: CheckBox
var _restart_button: Button
var _log: RichTextLabel
var _auto_timer: Timer


func _ready() -> void:
	books = GameData.load_books()
	classes = GameData.load_classes()
	_build_ui()
	start_battle()


func start_battle() -> void:
	combat = Combat.new(books, PARTY, classes, GameData.load_encounter(ENCOUNTER))
	combat.logged.connect(_on_log)
	_log.clear()
	_on_log("[b]Бой начинается: Крысиная стая![/b]")
	for c in _cards.values():
		c.queue_free()
	_cards.clear()
	for u in combat.units:
		var card := _make_card(u)
		(_party_box if u.is_wizard() else _enemy_box).add_child(card)
		_cards[u.id] = card
	_restart_button.visible = false
	_advance()


# --- Ход -----------------------------------------------------------------

func _advance() -> void:
	actor = null
	target = null
	bag = null
	_clear_chips()
	_spell_label.text = ""
	var u := combat.next_turn()
	if u == null:
		_game_over()
		return
	actor = u
	if not u.is_wizard():
		_set_state(State.ENEMY_TURN)
		_prompt_label.text = "Ходит %s…" % u.name
		await _wait(ENEMY_DELAY)
		if combat.outcome != "" or state == State.OVER:
			return
		combat.enemy_act(u)
		_refresh()
		_advance()
		return
	# Ослеплённый кастует в случайную цель из случайной книги.
	if u.has("blind"):
		target = combat.resolve_target(u, u)
		_select_book(u.books[combat.rng.randi_range(0, u.books.size() - 1)])
		return
	_set_state(State.CHOOSE_TARGET)
	_prompt_label.text = "%s, выбери цель: противника или союзника." % u.name


func _on_card_pressed(u: Unit) -> void:
	if state != State.CHOOSE_TARGET or not combat.can_target(actor, u):
		return
	target = combat.resolve_target(actor, u)
	if actor.books.size() == 1:
		_select_book(actor.books[0])
	else:
		_set_state(State.CHOOSE_BOOK)
		_prompt_label.text = "Цель: %s. Выбери книгу." % target.name


func _select_book(id: String) -> void:
	book_id = id
	bag = combat.new_bag(actor, id)
	_set_state(State.DRAWING)
	_prompt_label.text = "%s → %s. Книга: %s. Доставай фишки!" % [actor.name, target.name, books[id].name]
	_update_chips()
	if _auto_check.button_pressed:
		_auto_step()


func _on_draw_pressed() -> void:
	if state != State.DRAWING:
		return
	bag.draw(combat.rng)
	_update_chips()
	if bag.is_complete():
		_set_state(State.READY)
		_show_preview()
	if _auto_check.button_pressed:
		_auto_step()


func _on_chip_pressed(slot: int) -> void:
	if actor == null or actor.ability != "burn" or actor.ability_charges <= 0:
		return
	if not (state == State.DRAWING or state == State.READY) or slot >= bag.chips.size():
		return
	actor.ability_charges -= 1
	var old := bag.chips[slot]
	bag.reroll(slot, combat.rng)
	_on_log("%s сжигает фишку «%s» → «%s» (осталось %d)." % [actor.name,
		ELEMENT_NAMES[old], ELEMENT_NAMES[bag.chips[slot]], actor.ability_charges])
	_update_chips()
	if state == State.READY:
		_show_preview()


func _on_cast_pressed() -> void:
	if state != State.READY:
		return
	_set_state(State.ENEMY_TURN)  # блокируем ввод на время анимации
	var spell := combat.cast(actor, target, book_id, bag)
	_update_chips()
	_spell_label.text = "%s\n%s" % [spell.name, spell.effect]
	_shout()
	_refresh()
	await _wait(0.6)
	if state != State.OVER:
		_advance()


func _auto_step() -> void:
	var delay := AUTO_DRAW_DELAY if state == State.DRAWING else AUTO_CAST_DELAY
	_auto_timer.start(0.01 if fast else delay)


func _on_auto_timer() -> void:
	if not _auto_check.button_pressed:
		return
	if state == State.DRAWING:
		_on_draw_pressed()
	elif state == State.READY:
		_on_cast_pressed()


func _game_over() -> void:
	_set_state(State.OVER)
	var win := combat.outcome == "victory"
	_prompt_label.text = "ПОБЕДА! Крысы разбежались." if win else "Поражение… Крысы победили стариков."
	_on_log("[b]%s[/b]" % _prompt_label.text)
	_restart_button.visible = true


func _set_state(s: State) -> void:
	state = s
	_draw_button.disabled = s != State.DRAWING
	_cast_button.disabled = s != State.READY
	for c in _book_box.get_children():
		c.queue_free()
	if s == State.CHOOSE_BOOK:
		for b in actor.books:
			var btn := Button.new()
			btn.text = books[b].name
			btn.pressed.connect(_select_book.bind(b))
			_book_box.add_child(btn)
	_refresh()


# --- Отрисовка -----------------------------------------------------------

func _refresh() -> void:
	if combat == null:
		return
	var names: Array[String] = []
	for u in combat.turn_queue(6):
		names.append(u.name)
	_queue_label.text = "Очередь: " + "  →  ".join(PackedStringArray(names))
	for u in combat.units:
		var card: Button = _cards[u.id]
		card.text = _card_text(u)
		var targetable := state == State.CHOOSE_TARGET and combat.can_target(actor, u)
		card.disabled = state == State.CHOOSE_TARGET and not targetable
		card.modulate = Color(1, 1, 1, 1) if u.alive() else Color(1, 1, 1, 0.35)
		if u == actor:
			card.modulate = Color(1.25, 1.2, 0.8)
	_ability_label.text = ""
	if actor and actor.is_wizard():
		_ability_label.text = String(classes[actor.class_id].ability_text)
		if actor.ability == "burn":
			_ability_label.text += "  Осталось: %d." % actor.ability_charges


func _card_text(u: Unit) -> String:
	var lines := ["%s%s" % ["▶ " if u == actor else "", u.name]]
	var hp_line := "ЗД %s" % u.hp_text() if u.alive() else "выбыл"
	if u.shield > 0:
		hp_line += "   Щит %s" % Unit._num(u.shield)
	lines.append(hp_line)
	var st: Array[String] = []
	for id in u.statuses:
		var s: Dictionary = u.statuses[id]
		var label := Combat.status_name(id)
		if s.turns < 99:
			label += " %d" % s.turns
		st.append(label)
	if u.is_leader:
		st.push_front("Предводитель")
	if not st.is_empty():
		lines.append(", ".join(PackedStringArray(st)))
	return "\n".join(PackedStringArray(lines))


func _clear_chips() -> void:
	for b in _chip_buttons:
		_style_chip(b, "", false)


func _update_chips() -> void:
	for i in _chip_buttons.size():
		var chip := bag.chips[i] if bag and i < bag.chips.size() else ""
		_style_chip(_chip_buttons[i], chip, true)


func _style_chip(b: Button, chip: String, active: bool) -> void:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(48)
	box.set_border_width_all(3)
	box.border_color = Color(1, 1, 1, 0.5)
	box.bg_color = ELEMENT_COLORS.get(chip, Color(0.18, 0.18, 0.22)) if chip != "" else Color(0.18, 0.18, 0.22)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, box)
	b.text = ELEMENT_NAMES.get(chip, "?") if chip != "" else ("…" if active else "")
	var dark := chip in ["H", "L", "K", "A"]
	var font_color := Color.BLACK if dark else Color.WHITE
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		b.add_theme_color_override(c, font_color)


func _show_preview() -> void:
	var spell := combat.spell_for(book_id, bag.combo_key())
	_spell_label.text = "%s\n%s" % [spell.name, spell.effect]
	var hint := "Нажми «Я кастую!»."
	if actor.ability == "burn" and actor.ability_charges > 0:
		hint = "Нажми «Я кастую!» или кликни по фишке, чтобы сжечь её."
	_prompt_label.text = hint


func _shout() -> void:
	_shout_label.text = "«Я кастую!»"
	_shout_label.modulate = Color(1, 1, 1, 1)
	_shout_label.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(_shout_label, "scale", Vector2(1.0, 1.0), 0.15)
	tw.tween_interval(0.5)
	tw.tween_property(_shout_label, "modulate:a", 0.0, 0.4)


func _on_log(text: String) -> void:
	_log.append_text(text + "\n")


func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(0.01 if fast else seconds).timeout


# --- Построение интерфейса -----------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1b1a24")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var title := _label("Я кастую — уровень 1", 22)
	top.add_child(title)
	_queue_label = _label("", 16)
	_queue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_queue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_queue_label)

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 16)
	root.add_child(middle)

	_party_box = VBoxContainer.new()
	_party_box.custom_minimum_size = Vector2(260, 0)
	_party_box.add_child(_label("Отряд", 18))
	middle.add_child(_party_box)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 10)
	middle.add_child(center)

	_prompt_label = _label("", 18)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(_prompt_label)

	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 18)
	center.add_child(chips)
	for i in ChipBag.CHIPS_PER_CAST:
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 96)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_chip_pressed.bind(i))
		_style_chip(b, "", false)
		chips.add_child(b)
		_chip_buttons.append(b)

	_spell_label = _label("", 18)
	_spell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(_spell_label)

	_shout_label = _label("", 40)
	_shout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shout_label.add_theme_color_override("font_color", Color("ffd35a"))
	_shout_label.pivot_offset = Vector2(200, 25)
	center.add_child(_shout_label)

	_book_box = HBoxContainer.new()
	_book_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(_book_box)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 12)
	center.add_child(controls)
	_draw_button = _button("Достать фишку", _on_draw_pressed)
	controls.add_child(_draw_button)
	_cast_button = _button("Я кастую!", _on_cast_pressed)
	controls.add_child(_cast_button)
	_auto_check = CheckBox.new()
	_auto_check.text = "Авто (фишка раз в 2 с)"
	_auto_check.toggled.connect(func(on: bool) -> void:
		if on and (state == State.DRAWING or state == State.READY):
			_auto_step())
	controls.add_child(_auto_check)
	_restart_button = _button("Сыграть заново", start_battle)
	_restart_button.visible = false
	controls.add_child(_restart_button)

	_ability_label = _label("", 14)
	_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ability_label.modulate = Color(1, 1, 1, 0.7)
	center.add_child(_ability_label)

	_enemy_box = VBoxContainer.new()
	_enemy_box.custom_minimum_size = Vector2(260, 0)
	_enemy_box.add_child(_label("Противники", 18))
	middle.add_child(_enemy_box)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(0, 170)
	_log.add_theme_font_size_override("normal_font_size", 14)
	_log.add_theme_font_size_override("bold_font_size", 14)
	root.add_child(_log)

	_auto_timer = Timer.new()
	_auto_timer.one_shot = true
	_auto_timer.timeout.connect(_on_auto_timer)
	add_child(_auto_timer)


func _make_card(u: Unit) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(260, 84)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(_on_card_pressed.bind(u))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("2d3a52") if u.is_wizard() else Color("522d2d")
	box.set_corner_radius_all(8)
	box.set_content_margin_all(10)
	var hover := box.duplicate()
	hover.bg_color = box.bg_color.lightened(0.2)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", box)
	var dis := box.duplicate()
	dis.bg_color = box.bg_color.darkened(0.5)
	b.add_theme_stylebox_override("disabled", dis)
	return b


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(160, 44)
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(cb)
	return b
