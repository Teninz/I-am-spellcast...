extends Control
## Экран боя прототипа. Весь интерфейс строится кодом, логика — в Combat.
##
## Ход волшебника: выбрать цель (клик по карточке) → выбрать книгу →
## трижды «Достать фишку» (или авто раз в 2 секунды) → «Я кастую!».
## Пиромант может кликнуть по вытянутой фишке, чтобы сжечь её (3 раза за бой).
## Предмет можно применить в начале своего хода (ход не тратится).

signal finished(outcome: String)

enum State { ENEMY_TURN, CHOOSE_TARGET, CHOOSE_BOOK, DRAWING, READY, ITEM_TARGET, OVER }

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
## Сохраняется между боями.
var auto_draw := false

var adventure: Adventure
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
var _bag_button: TextureButton
var _book_cover_holder: CenterContainer
var _queue_label: Label
var _prompt_label: Label
var _spell_label: Label
var _effects_box: HBoxContainer
var _shout_label: Label
var _ability_label: Label
var _party_box: VBoxContainer
var _enemy_box: VBoxContainer
var _book_box: HBoxContainer
var _draw_button: Button
var _cast_button: Button
var _auto_check: CheckBox
var _item_button: Button
var _title_label: Label
var _log: RichTextLabel
var _auto_timer: Timer


func setup(adv: Adventure) -> void:
	adventure = adv
	books = adv.books
	classes = adv.classes


func _ready() -> void:
	_build_ui()
	start_battle()


func start_battle() -> void:
	combat = adventure.start_combat()
	combat.logged.connect(_on_log)
	combat.unit_added.connect(_add_card)
	combat.status_applied.connect(_stamp)
	var enc := adventure.encounter()
	_title_label.text = "Уровень %d из %d — %s" % [adventure.level, adventure.level_count(), enc.name]
	_log.clear()
	_on_log("[b]Бой начинается: %s![/b]" % enc.name)
	for u in combat.units:
		if u.fortify > 0.0:
			_on_log("%s в Укреплении: +%s временного ЗД на 5 ходов." % [u.name, Unit._num(u.fortify)])
		if u.passive != "":
			_on_log("%s: %s" % [u.name, enc.members[0].get("passive_text", "")])
	for c in _cards.values():
		c.queue_free()
	_cards.clear()
	for u in combat.units:
		_add_card(u)
	_advance()


func _add_card(u: Unit) -> void:
	var card := _make_card(u)
	(_party_box if u.is_wizard() else _enemy_box).add_child(card)
	_cards[u.id] = card


# --- Ход -----------------------------------------------------------------

func _advance() -> void:
	actor = null
	target = null
	bag = null
	_clear_chips()
	_spell_label.text = ""
	_show_effects({})
	_show_book_cover("")
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
	if state == State.ITEM_TARGET:
		if combat.item_targets(actor, actor.wizard.item).has(u):
			combat.use_item(actor, u)
			_after_item()
		return
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
	_show_book_cover(id)
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
	var again := actor.extra_casts > 0
	if again:
		actor.extra_casts -= 1
	var spell := combat.cast(actor, target, book_id, bag, not again)
	_update_chips()
	_spell_label.text = "%s\n%s" % [spell.name, spell.effect]
	_show_effects(spell)
	_shout()
	_refresh()
	await _wait(0.6)
	if state == State.OVER:
		return
	if combat.outcome != "":
		_game_over()
	elif again and actor.alive():
		_on_log("%s кастует ещё раз!" % actor.name)
		_clear_chips()
		_set_state(State.CHOOSE_TARGET)
		_prompt_label.text = "%s, второй каст: выбери цель." % actor.name
	else:
		_advance()


func _on_item_pressed() -> void:
	if state != State.CHOOSE_TARGET or not combat.can_use_item(actor):
		return
	var it: Dictionary = adventure.items[actor.wizard.item]
	if it.target == "self":
		combat.use_item(actor, actor)
		_after_item()
		return
	_set_state(State.ITEM_TARGET)
	_prompt_label.text = "%s: %s Выбери цель." % [it.name, it.text]


func _after_item() -> void:
	if combat.outcome != "":
		_game_over()
		return
	_set_state(State.CHOOSE_TARGET)
	_prompt_label.text = "%s, выбери цель: противника или союзника." % actor.name


func _auto_step() -> void:
	var delay := AUTO_DRAW_DELAY if state == State.DRAWING else AUTO_CAST_DELAY
	_auto_timer.start(0.01 if fast else delay)


func _on_auto_timer() -> void:
	if not _auto_check.button_pressed or state == State.OVER:
		return
	if state == State.DRAWING:
		_on_draw_pressed()
	elif state == State.READY:
		_on_cast_pressed()


func _game_over() -> void:
	if state == State.OVER:
		return
	_set_state(State.OVER)
	var win := combat.outcome == "victory"
	_prompt_label.text = "ПОБЕДА!" if win else "Поражение… Отряд выбыл."
	_on_log("[b]%s[/b]" % _prompt_label.text)
	await _wait(1.2)
	finished.emit(combat.outcome)


func _set_state(s: State) -> void:
	state = s
	_draw_button.disabled = s != State.DRAWING
	if _bag_button:
		_bag_button.disabled = s != State.DRAWING
		_bag_button.modulate = Color(1, 1, 1, 1.0 if s == State.DRAWING else 0.45)
	_cast_button.disabled = s != State.READY
	_item_button.visible = s in [State.CHOOSE_TARGET, State.ITEM_TARGET] and actor != null \
		and actor.is_wizard() and combat.can_use_item(actor)
	if _item_button.visible:
		_item_button.text = "Предмет: %s" % adventure.items[actor.wizard.item].name
	for c in _book_box.get_children():
		c.queue_free()
	if s == State.CHOOSE_BOOK:
		for b in actor.books:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(110, 176)
			btn.tooltip_text = books[b].name
			btn.pressed.connect(_select_book.bind(b))
			var col := VBoxContainer.new()
			col.mouse_filter = Control.MOUSE_FILTER_IGNORE
			col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			col.alignment = BoxContainer.ALIGNMENT_CENTER
			var cc := CenterContainer.new()
			cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cc.add_child(Art.book_cover(books[b], 88))
			col.add_child(cc)
			var l := Label.new()
			l.text = books[b].name
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.add_theme_font_size_override("font_size", 11)
			col.add_child(l)
			btn.add_child(col)
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
		_update_card(card, u)
		var targetable := state == State.CHOOSE_TARGET and combat.can_target(actor, u)
		if state == State.ITEM_TARGET:
			targetable = combat.item_targets(actor, actor.wizard.item).has(u)
		card.disabled = state in [State.CHOOSE_TARGET, State.ITEM_TARGET] and not targetable
		card.modulate = Color(1, 1, 1, 1) if u.alive() else Color(1, 1, 1, 0.35)
		if u == actor:
			card.modulate = Color(1.25, 1.2, 0.8)
	_ability_label.text = ""
	if actor and actor.is_wizard():
		_ability_label.text = String(classes[actor.class_id].ability_text)
		if actor.wizard.item != "":
			_ability_label.text += "\nПредмет: %s — %s" % [adventure.items[actor.wizard.item].name,
				adventure.items[actor.wizard.item].text]
		if actor.ability == "burn":
			_ability_label.text += "  Осталось: %d." % actor.ability_charges


func _update_card(card: Button, u: Unit) -> void:
	var name_label: Label = card.get_meta("name")
	name_label.text = "%s%s" % ["▶ " if u == actor else "", u.name]
	var hp_label: Label = card.get_meta("hp")
	hp_label.text = "ЗД %s" % u.hp_text() if u.alive() else "выбыл"
	var bar: ProgressBar = card.get_meta("bar")
	bar.max_value = u.max_hp
	bar.value = u.hp
	var icons: HFlowContainer = card.get_meta("icons")
	for c in icons.get_children():
		c.queue_free()
	if u.alive():
		var names := {}
		for x in combat.units:
			names[x.id] = x.name
		for icon in StatusIcon.icons_for(u, 38, names):
			icons.add_child(icon)


func _clear_chips() -> void:
	for b in _chip_buttons:
		_style_chip(b, "", false)


func _update_chips() -> void:
	for i in _chip_buttons.size():
		var chip := bag.chips[i] if bag and i < bag.chips.size() else ""
		_style_chip(_chip_buttons[i], chip, true)


func _style_chip(b: Button, chip: String, active: bool) -> void:
	var art: TextureRect = b.get_meta("art")
	var tex := Art.chip(chip)
	if tex:
		var clear := StyleBoxEmpty.new()
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(st, clear)
		b.text = ""
		art.texture = tex
		art.visible = true
		art.modulate = Color(1, 1, 1, 1.0 if (active or chip != "") else 0.35)
		b.tooltip_text = ELEMENT_NAMES.get(chip, "") if chip != "" else ""
		# Новая фишка переворачивается рубашкой вниз.
		if chip != "" and b.get_meta("chip") != chip and not fast:
			art.scale = Vector2(0.0, 1.0)
			create_tween().tween_property(art, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_SINE)
		b.set_meta("chip", chip)
		return
	art.visible = false
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
	b.set_meta("chip", chip)


func _show_book_cover(id: String) -> void:
	for c in _book_cover_holder.get_children():
		c.queue_free()
	if id != "":
		_book_cover_holder.add_child(Art.book_cover(books[id], 60))


func _show_preview() -> void:
	var spell := combat.spell_for(book_id, bag.combo_key())
	_spell_label.text = "%s\n%s" % [spell.name, spell.effect]
	_show_effects(spell)
	var hint := "Нажми «Я кастую!»."
	if actor.ability == "burn" and actor.ability_charges > 0:
		hint = "Нажми «Я кастую!» или кликни по фишке, чтобы сжечь её."
	_prompt_label.text = hint


## Крупные иконки эффектов, которые наложит заклинание.
func _show_effects(spell: Dictionary) -> void:
	for c in _effects_box.get_children():
		c.queue_free()
	if spell.is_empty():
		return
	var spec := EffectParser.parse(spell)
	var ids: Array[String] = []
	if spec.shield > 0:
		ids.append("shield")
	for s in spec.statuses:
		ids.append(s.id)
	for id in ids:
		_effects_box.add_child(StatusIcon.make(id, "", 0, 72))
	for s in spec.caster_statuses:
		var icon := StatusIcon.make(s.id, "", 0, 52)
		icon.tooltip_text += "\n(накладывается на самого кастующего)"
		_effects_box.add_child(icon)


## Эффект «штамп»: крупная иконка появляется над карточкой и впечатывается в неё.
func _stamp(u: Unit, id: String) -> void:
	if fast or not _cards.has(u.id):
		return
	var card: Control = _cards[u.id]
	var big := StatusIcon.make(id, "", 0, 128)
	big.rich_tooltip = false
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big.top_level = true
	add_child(big)
	var rect := card.get_global_rect()
	big.size = Vector2(128, 128)
	big.pivot_offset = Vector2(64, 64)
	big.global_position = rect.get_center() - Vector2(64, 80)
	big.scale = Vector2(1.4, 1.4)
	big.modulate.a = 0.0
	var target_pos := Vector2(rect.position.x + 8 - 64 + 19, rect.end.y - 27 - 64)
	var tw := create_tween()
	tw.tween_property(big, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(big, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35)
	tw.tween_property(big, "global_position", target_pos, 0.25).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(big, "scale", Vector2(0.3, 0.3), 0.25).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(big, "modulate:a", 0.0, 0.25)
	tw.tween_callback(big.queue_free)


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
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1b1a24")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	_title_label = _label("", 22)
	top.add_child(_title_label)
	var info := Button.new()
	info.text = "Инфо"
	info.tooltip_text = "Что значат иконки эффектов"
	info.pressed.connect(func() -> void: StatusInfo.open(self))
	top.add_child(info)
	_queue_label = _label("", 16)
	_queue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_queue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_queue_label.clip_text = true
	_queue_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	# Мешочек: клик по нему тоже достаёт фишку.
	_bag_button = TextureButton.new()
	_bag_button.texture_normal = Art.bag()
	_bag_button.ignore_texture_size = true
	_bag_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_bag_button.custom_minimum_size = Vector2(96, 96)
	_bag_button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_bag_button.tooltip_text = "Мешочек: достать фишку"
	_bag_button.pressed.connect(_on_draw_pressed)
	_bag_button.visible = Art.bag() != null
	chips.add_child(_bag_button)
	for i in ChipBag.CHIPS_PER_CAST:
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 96)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_chip_pressed.bind(i))
		var art := TextureRect.new()
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.material = Art.circle_material()
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.pivot_offset = Vector2(48, 48)
		b.add_child(art)
		b.set_meta("art", art)
		b.set_meta("chip", "")
		_style_chip(b, "", false)
		chips.add_child(b)
		_chip_buttons.append(b)
	# Обложка книги, из которой сейчас кастуют.
	_book_cover_holder = CenterContainer.new()
	_book_cover_holder.custom_minimum_size = Vector2(70, 96)
	chips.add_child(_book_cover_holder)

	_spell_label = _label("", 18)
	_spell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(_spell_label)

	_effects_box = HBoxContainer.new()
	_effects_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_effects_box.add_theme_constant_override("separation", 10)
	_effects_box.custom_minimum_size = Vector2(0, 76)
	center.add_child(_effects_box)

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
	_item_button = _button("Предмет", _on_item_pressed)
	_item_button.visible = false
	controls.add_child(_item_button)
	_auto_check = CheckBox.new()
	_auto_check.text = "Авто (фишка раз в 2 с)"
	_auto_check.button_pressed = auto_draw
	_auto_check.toggled.connect(func(on: bool) -> void:
		auto_draw = on
		if on and (state == State.DRAWING or state == State.READY):
			_auto_step())
	controls.add_child(_auto_check)

	_ability_label = _label("", 14)
	_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ability_label.modulate = Color(1, 1, 1, 0.7)
	center.add_child(_ability_label)

	var enemy_col := VBoxContainer.new()
	enemy_col.custom_minimum_size = Vector2(270, 0)
	enemy_col.add_child(_label("Противники", 18))
	middle.add_child(enemy_col)
	var enemy_scroll := ScrollContainer.new()
	enemy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	enemy_col.add_child(enemy_scroll)
	_enemy_box = VBoxContainer.new()
	_enemy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_scroll.add_child(_enemy_box)

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
	b.custom_minimum_size = Vector2(260, 86)
	b.pressed.connect(_on_card_pressed.bind(u))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("2d3a52") if u.is_wizard() else Color("522d2d")
	box.set_corner_radius_all(8)
	var hover := box.duplicate()
	hover.bg_color = box.bg_color.lightened(0.2)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", box)
	var dis := box.duplicate()
	dis.bg_color = box.bg_color.darkened(0.5)
	b.add_theme_stylebox_override("disabled", dis)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	b.add_child(margin)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 3)
	margin.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	var name_label := _label("", 15)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(name_label)
	var hp_label := _label("", 14)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(hp_label)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 7)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.45)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("4cc46a") if u.is_wizard() else Color("e0413a")
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	col.add_child(bar)
	var icons := HFlowContainer.new()
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icons.add_theme_constant_override("h_separation", 3)
	col.add_child(icons)
	b.set_meta("name", name_label)
	b.set_meta("hp", hp_label)
	b.set_meta("bar", bar)
	b.set_meta("icons", icons)
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
