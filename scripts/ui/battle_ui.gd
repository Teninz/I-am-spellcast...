extends Control
## Экран боя прототипа. Весь интерфейс строится кодом, логика — в Combat.
##
## Ход волшебника: выбрать цель (клик по карточке) → выбрать книгу →
## трижды «Достать фишку» (или авто раз в 2 секунды) → «Я кастую!».
## Пиромант может кликнуть по вытянутой фишке, чтобы сжечь её (3 раза за бой).
## Предмет можно применить в начале своего хода (ход не тратится).

signal finished(outcome: String)

enum State { ENEMY_TURN, CHOOSE_TARGET, CHOOSE_BOOK, DRAWING, READY, ITEM_TARGET, ABILITY_TARGET, REWIND, OVER }

## Не нажал сам — через столько секунд фишка вытянется (и «Я кастую!» нажмётся) автоматически.
const AUTO_DELAY := 5.0
## Столько секунд на выбор книги, потом — случайная.
const BOOK_TIME := 30.0
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
var _luck_plans := {}  # книга -> вложения шкалы удачи на этот ход
var _queue_label: Label
var _prompt_label: Label
var _spell_label: Label
var _effects_box: HBoxContainer
var _shout_label: Label
var _shout_banner: TextureRect
var _ability_label: Label
var _party_box: VBoxContainer
var _enemy_box: VBoxContainer
var _book_box: HBoxContainer
var _cast_button: Button
## Подсказка с обратным отсчётом (автотяга, выбор книги).
var _timer_label: Label
var _deadline := 0.0     # когда сработает автонажатие (время в секундах, 0 — нет)
var _item_button: Button
var _ability_button: Button
## Ряд под кнопками: видения Прорицателя, выбор фишки для Сделки, Перемотка.
var _extra_box: HFlowContainer
var _critter := ""        # зверушка Учёного, ждущая цель
var _pact_picking := false
var _rewind_again := false
var _title_label: Label
var _log: BattleLog
var _auto_timer: Timer
## Обучение первого боя: панель с шагом и подсветка того, куда нажимать.
var _tutorial: PanelContainer
var _tutorial_label: RichTextLabel
var _pulse_tween: Tween
var _pulsed: Array[Control] = []


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
	combat.turn_started.connect(func(u: Unit) -> void: _log.start_turn(u))
	combat.hp_changed.connect(_float_number)
	combat.unit_added.connect(_add_card)
	combat.status_applied.connect(_stamp)
	var enc := adventure.encounter()
	_title_label.text = "Уровень %d из %d — %s" % [adventure.level, adventure.level_count(), enc.name]
	_log.clear()
	_log.set_units(combat.units)
	_on_log("Бой начинается: %s!" % enc.name, "title")
	for u in combat.units:
		if u.fortify > 0.0:
			_on_log("%s в Укреплении: +%s временного ЗД на 5 ходов." % [u.name, Unit._num(u.fortify)], "shield", "fortify")
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
	_luck_plans.clear()
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
	if Luck.has_luck(u):
		_prompt_label.text += " Удача с тобой: открой книгу и вложи шкалу удачи."


func _on_card_pressed(u: Unit) -> void:
	if state == State.ABILITY_TARGET:
		if _ability_targets().has(u):
			if actor.ability == "workshop":
				combat.use_workshop(actor, _critter, u)
				_after_turn_ability()
			else:
				combat.use_target_ability(actor, u)
				_after_item()
		return
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
	bag = combat.new_bag(actor, id, _luck_plans.get(id, {}))
	_show_book_cover(id)
	_set_state(State.DRAWING)
	_prompt_label.text = "%s → %s. Книга: %s. Доставай фишки!" % [actor.name, target.name, books[id].name]
	_update_chips()
	_auto_step()


## Клик по мешочку (manual) или автотяга: достаёт следующую фишку.
func _on_draw_pressed(manual: bool = true) -> void:
	if state != State.DRAWING:
		return
	var chip := combat.draw_chip(actor, target, book_id, bag, manual)
	if not fast:
		Sfx.play("chip_chaos" if chip == ChipBag.CHAOS else "chip_draw")
	_update_chips()
	if bag.is_complete():
		_set_state(State.READY)
		_show_preview()
	else:
		_ability_button.visible = _ability_available()
	_auto_step()


func _on_chip_pressed(slot: int) -> void:
	if actor == null or not combat.can_reroll(actor):
		return
	if not (state == State.DRAWING or state == State.READY) or slot >= bag.chips.size():
		return
	var old := bag.chips[slot]
	combat.reroll_chip(actor, bag, slot)
	if not fast:
		Sfx.play("chip_burn")
	_on_log("«%s» → «%s»." % [ELEMENT_NAMES[old], ELEMENT_NAMES[bag.chips[slot]]], "luck")
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
	# Хрономант: неудачный каст можно отмотать.
	if combat.outcome == "" and combat.last_cast.get("bad", false) and combat.can_rewind():
		_rewind_again = again
		_set_state(State.REWIND)
		_prompt_label.text = "Каст вышел неудачным. Хрономант может отмотать время (1 раз за бой)."
		return
	_after_cast(again)


func _after_cast(again: bool) -> void:
	if combat.outcome != "":
		_game_over()
	elif again and actor.alive():
		_on_log("%s кастует ещё раз!" % actor.name, "buff")
		_clear_chips()
		_set_state(State.CHOOSE_TARGET)
		_prompt_label.text = "%s, второй каст: выбери цель." % actor.name
	else:
		_advance()


## Кнопка способности: своя для каждой фазы хода (см. Combat.ABILITY_PHASE).
func _ability_available() -> bool:
	if actor == null or not actor.is_wizard():
		return false
	match combat.ability_phase(actor):
		"target", "turn":
			return state == State.CHOOSE_TARGET and combat.can_use_ability(actor)
		"chips":
			return state == State.READY and combat.can_use_ability(actor, bag)
		"draw":
			return state == State.DRAWING and combat.can_use_ability(actor, bag) and not _pact_picking
	return false


func _ability_targets() -> Array[Unit]:
	return combat.ability_targets(actor)


func _on_ability_pressed() -> void:
	if not _ability_available():
		return
	match combat.ability_phase(actor):
		"target":
			_set_state(State.ABILITY_TARGET)
			_prompt_label.text = "%s: выбери %s." % [_ability_name(),
				"выбывшего союзника" if actor.ability == "raise_dead" else "союзника"]
		"turn":
			_critter = combat.roll_workshop()
			if combat.critter_needs_target(_critter):
				_set_state(State.ABILITY_TARGET)
				_prompt_label.text = "%s: выбери, на кого натравить." % Combat.CRITTER_NAMES[_critter]
			else:
				combat.use_workshop(actor, _critter, null)
				_after_turn_ability()
		"chips":
			if actor.ability == "beast_call":
				combat.beast_call(actor, bag, target)
			else:
				combat.surge(actor, bag)
			_chips_changed()
		"draw":
			_pact_picking = true
			_prompt_label.text = "Сделка: выбери фишку, которую достанешь (−%d ЗД)." % int(Combat.PACT_COST)
			_ability_button.visible = false
			_rebuild_extra()


func _ability_name() -> String:
	return combat.ability_name(actor)


## Мастерская заняла ход Учёного.
func _after_turn_ability() -> void:
	_critter = ""
	_set_state(State.ENEMY_TURN)  # ход занят: блокируем ввод на время паузы
	_refresh()
	if combat.outcome != "":
		_game_over()
	else:
		await _wait(0.5)
		_advance()


## Тройка изменилась способностью (зверь, всплеск, видение).
func _chips_changed() -> void:
	_update_chips()
	_refresh()
	if combat.outcome != "":
		_game_over()
		return
	_set_state(State.READY)
	_show_preview()


## Ряд дополнительных действий под кнопками.
func _rebuild_extra() -> void:
	for c in _extra_box.get_children():
		_extra_box.remove_child(c)
		c.queue_free()
	if actor == null or combat == null:
		return
	if state == State.READY and combat.can_use_vision(actor, bag):
		for i in combat.visions.size():
			var chips := combat.vision_chips(combat.visions[i], book_id)
			var spell := combat.spell_for(book_id, ChipBag.key_for(chips))
			var b := _button("Видение: %s" % spell.get("name", "?"), _on_vision.bind(i))
			b.tooltip_text = "Заменить тройку видением Прорицателя: %s — %s" % [spell.get("name", ""), spell.get("effect", "")]
			_extra_box.add_child(b)
	if state == State.DRAWING and _pact_picking and bag != null:
		for letter in Combat.letters_by_count(books[book_id].bag):
			if int(bag.counts.get(letter, 0)) <= 0:
				continue
			var b := _button(ELEMENT_NAMES.get(letter, letter), _on_pact.bind(letter))
			b.icon = Art.chip(letter)
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 28)
			_extra_box.add_child(b)
		_extra_box.add_child(_button("Отмена", func() -> void:
			_pact_picking = false
			_set_state(State.DRAWING)))
	if state == State.REWIND:
		_extra_box.add_child(_button("Перемотка!", _on_rewind))
		_extra_box.add_child(_button("Оставить как есть", _on_rewind_skip))


func _on_vision(i: int) -> void:
	if state != State.READY or not combat.can_use_vision(actor, bag) or i >= combat.visions.size():
		return
	combat.use_vision(actor, bag, i, book_id)
	_chips_changed()


func _on_pact(letter: String) -> void:
	_pact_picking = false
	if combat.pact_deal(actor, bag, letter):
		_refresh()
		_set_state(State.DRAWING)
		_on_draw_pressed()
	else:
		_set_state(State.DRAWING)


func _on_rewind() -> void:
	if state != State.REWIND:
		return
	var u := combat.rewind()
	for id in _cards.keys():
		if not combat.units.any(func(x: Unit) -> bool: return x.id == id):
			_cards[id].queue_free()
			_cards.erase(id)
	_refresh()
	if u == null:
		_after_cast(_rewind_again)
		return
	actor = u
	_clear_chips()
	_show_book_cover("")
	_set_state(State.CHOOSE_TARGET)
	_prompt_label.text = "Время отмотано! %s, кастуй заново: выбери цель." % u.name


func _on_rewind_skip() -> void:
	if state == State.REWIND:
		_after_cast(_rewind_again)


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


## Запускает обратный отсчёт автонажатия для текущего состояния.
func _auto_step() -> void:
	_auto_timer.stop()
	_deadline = 0.0
	if fast:
		return  # в тестах интерфейс ведёт сам тест
	var wait := 0.0
	match state:
		State.DRAWING, State.READY, State.REWIND:
			wait = AUTO_DELAY
		State.CHOOSE_BOOK:
			wait = BOOK_TIME
		_:
			return
	_deadline = Time.get_ticks_msec() / 1000.0 + wait
	_auto_timer.start(wait)


func _on_auto_timer() -> void:
	_deadline = 0.0
	match state:
		State.DRAWING:
			_on_draw_pressed(false)
		State.READY:
			_on_cast_pressed()
		State.REWIND:
			_on_rewind_skip()
		State.CHOOSE_BOOK:
			# Время на выбор вышло — книга выбирается случайно (открытая книга закрывается).
			for c in get_children():
				if c is BookView:
					c.queue_free()
			var pick: String = actor.books[combat.rng.randi_range(0, actor.books.size() - 1)]
			_on_log("Время вышло — %s хватает первую попавшуюся книгу: «%s»." % [actor.name, books[pick].name], "info")
			_select_book(pick)


## Обратный отсчёт в подсказке.
func _process(_delta: float) -> void:
	if _timer_label == null:
		return
	var left := _deadline - Time.get_ticks_msec() / 1000.0
	if _deadline <= 0.0 or left <= 0.0:
		_timer_label.text = ""
		return
	var sec := ceili(left)
	match state:
		State.DRAWING:
			_timer_label.text = "Кликни по мешочку, чтобы достать фишку — сама вытянется через %d с. Вручную шанс на нужное заклинание чуть выше." % sec
		State.READY:
			_timer_label.text = "«Я кастую!» нажмётся само через %d с." % sec
		State.CHOOSE_BOOK:
			_timer_label.text = "На выбор книги — %d с, потом книга выберется случайно." % sec
		State.REWIND:
			_timer_label.text = "Через %d с каст останется как есть." % sec
		_:
			_timer_label.text = ""


func _game_over() -> void:
	if state == State.OVER:
		return
	_set_state(State.OVER)
	var win := combat.outcome == "victory"
	_prompt_label.text = "ПОБЕДА!" if win else "Поражение… Отряд выбыл."
	if not fast:
		Sfx.play("victory" if win else "defeat")
	if _tutorial:
		Settings.set_value("tutorial", false)  # обучение — только в первом бою
		_tutorial.queue_free()
		_tutorial = null
	_on_log(_prompt_label.text, "outcome")
	await _wait(1.2)
	finished.emit(combat.outcome)


func _set_state(s: State) -> void:
	_stop_pulse()
	state = s
	if _bag_button:
		_bag_button.disabled = s != State.DRAWING
		_bag_button.modulate = Color(1, 1, 1) if s == State.DRAWING else Color(0.6, 0.6, 0.6)
	_cast_button.disabled = s != State.READY
	_item_button.visible = s in [State.CHOOSE_TARGET, State.ITEM_TARGET] and actor != null \
		and actor.is_wizard() and combat.can_use_item(actor)
	_ability_button.visible = _ability_available()
	if _ability_button.visible:
		_ability_button.text = _ability_name()
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
			l.autowrap_mode = TextServer.AUTOWRAP_WORD
			l.add_theme_font_size_override("font_size", 11)
			col.add_child(l)
			btn.add_child(col)
			var holder := VBoxContainer.new()
			holder.add_theme_constant_override("separation", 4)
			holder.add_child(btn)
			var open := Button.new()
			open.text = "Открыть" + (" · удача" if Luck.has_luck(actor) else "")
			open.tooltip_text = "Все заклинания книги с шансами" + (" и шкала удачи" if Luck.has_luck(actor) else "")
			open.add_theme_font_size_override("font_size", 12)
			open.pressed.connect(_open_book.bind(b, true))
			holder.add_child(open)
			_book_box.add_child(holder)
	_rebuild_extra()
	_refresh()
	_tutorial_step()
	_auto_step()


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
		if state == State.ABILITY_TARGET:
			targetable = _ability_targets().has(u)
		card.disabled = state in [State.CHOOSE_TARGET, State.ITEM_TARGET, State.ABILITY_TARGET] and not targetable
		card.modulate = Color(1, 1, 1, 1) if u.alive() else Color(1, 1, 1, 0.35)
		if u == actor:
			card.modulate = Color(1.25, 1.2, 0.8)
	_ability_label.text = ""
	if actor and actor.is_wizard():
		var lines := []
		if actor.wizard.item != "":
			lines.append("Предмет: %s — %s" % [adventure.items[actor.wizard.item].name,
				adventure.items[actor.wizard.item].text])
		var ab := String(classes[actor.class_id].ability_text)
		if actor.ability == "burn":
			ab += "  Осталось: %d." % actor.ability_charges
		lines.append(ab)
		_ability_label.text = "\n".join(lines)
	_ability_label.tooltip_text = _ability_label.text


## Кольцо аватарки по состоянию участника.
func _ring_kind(u: Unit) -> String:
	if u.is_wizard():
		if u.wizard != null and u.wizard.zombie:
			return "wizard_zombie"
		if u == actor:
			return "wizard_active"
		if u.alive() and u.hp < u.max_hp / 3.0:
			return "wizard_critical"
		return "wizard"
	if u.is_boss:
		return "enemy_boss"
	if u.is_leader:
		return "enemy_leader"
	if u.has_meta("summoned"):
		return "enemy_summon"
	return "enemy"


func _update_card(card: Button, u: Unit) -> void:
	var name_label: Label = card.get_meta("name")
	name_label.text = "%s%s" % ["▶ " if u == actor else "", u.name]
	var hp_label: Label = card.get_meta("hp")
	hp_label.text = "ЗД %s" % u.hp_text() if u.alive() else "выбыл"
	if card.has_meta("avatar"):
		var av: Control = card.get_meta("avatar")
		if u.is_wizard():
			var zombie := u.wizard != null and u.wizard.zombie
			var face: TextureRect = av.get_meta("face")
			var st := Art.portrait_state(u.hp, u.max_hp, zombie)
			face.texture = Art.wizard_face(u.class_id, st) if av.has_meta("ring") else Art.portrait_head(u.class_id, st)
		if av.has_meta("ring"):
			var r: TextureRect = av.get_meta("ring")
			var t := Art.ring(_ring_kind(u))
			if t:
				r.texture = t
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
		art.visible = chip != "" or Art.texture("res://assets/ui/chip_socket.png") == null
		art.modulate = Color(1, 1, 1, 1.0 if (active or chip != "") else 0.35)
		b.tooltip_text = ELEMENT_NAMES.get(chip, "") if chip != "" else ""
		# Новая фишка ложится рубашкой вверх и переворачивается лицом.
		if chip != "" and b.get_meta("chip") != chip and not fast:
			art.texture = Art.chip("")
			art.scale = Vector2(1.0, 1.0)
			var tw := create_tween()
			tw.tween_property(art, "scale", Vector2(0.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
			tw.tween_callback(func() -> void: art.texture = tex)
			tw.tween_property(art, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
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
		# Обложка текущей книги — кнопка: открыть книгу (до первой фишки — со шкалой удачи).
		var btn := Button.new()
		btn.flat = true
		btn.tooltip_text = "Открыть книгу: заклинания и шансы"
		btn.custom_minimum_size = Vector2(64, 94)
		var cover := Art.book_cover(books[id], 60)
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(cover)
		btn.pressed.connect(_open_book.bind(id, false))
		_book_cover_holder.add_child(btn)


## Просмотр книги. Вкладывать удачу можно, пока у волшебника Благословение и фишки ещё не тянули.
## choosing — открыто из выбора книги: внизу кнопка «Кастовать из этой книги».
func _open_book(id: String, choosing: bool) -> void:
	if actor == null or not actor.is_wizard():
		return
	var before_draw := state == State.CHOOSE_BOOK or (state == State.DRAWING and bag != null and bag.chips.is_empty())
	var can := Luck.has_luck(actor) and before_draw
	var note := ""
	if Luck.has_luck(actor) and not before_draw:
		note = "Фишки уже тянутся — удачу можно вложить только до первой фишки."
	var view := BookView.open(self, books[id], combat.book_odds(actor, id), can, _luck_plans.get(id, {}),
		"Кастовать из этой книги" if choosing else "", note)
	view.plan_changed.connect(func(plan: Dictionary) -> void:
		_luck_plans[id] = plan
		# Книга уже выбрана, фишек ещё нет — пересобираем мешочек с новой удачей.
		if not choosing and state == State.DRAWING and bag != null and bag.chips.is_empty() and book_id == id:
			bag = combat.new_bag(actor, id, plan))
	if choosing:
		view.cast_pressed.connect(func(plan: Dictionary) -> void:
			_luck_plans[id] = plan
			if state == State.CHOOSE_BOOK:
				_select_book(id))


func _show_preview() -> void:
	var spell := combat.spell_for(book_id, bag.combo_key())
	_spell_label.text = "%s\n%s" % [spell.name, spell.effect]
	_show_effects(spell)
	var hint := "Нажми «Я кастую!»."
	if actor.ability == "burn" and actor.ability_charges > 0:
		hint = "Нажми «Я кастую!» или кликни по фишке, чтобы сжечь её."
	elif actor.has("muse"):
		hint = "Нажми «Я кастую!» или кликни по фишке — Муза позволит её перевытянуть."
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
	Sfx.play("status_good" if Unit.BUFFS.has(id) or id in ["shield", "fortify"] else "status_bad")
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
	if not fast:
		Sfx.play("cast_shout")
	_shout_label.text = "«Я кастую!»"
	_shout_label.modulate = Color(1, 1, 1, 1)
	_shout_label.scale = Vector2(0.6, 0.6)
	_shout_banner.modulate.a = 1.0
	_shout_banner.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(_shout_label, "scale", Vector2(1.0, 1.0), 0.15)
	tw.parallel().tween_property(_shout_banner, "scale", Vector2(1.0, 1.0), 0.15)
	tw.tween_interval(0.5)
	tw.tween_property(_shout_label, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(_shout_banner, "modulate:a", 0.0, 0.4)


func _on_log(text: String, kind: String = "info", icon: String = "") -> void:
	_log.add(text, kind, icon)
	if not fast:
		var sound: String = {"kill": "down", "special": "enemy_special", "summon": "summon", "luck": "luck"}.get(kind, "")
		if sound != "":
			Sfx.play(sound)


## Всплывающее число над карточкой: −урон красным, +лечение зелёным, поглощение — голубым.
func _float_number(u: Unit, amount: float, kind: String) -> void:
	if fast or not _cards.has(u.id) or amount <= 0.0:
		return
	match kind:
		"damage":
			Sfx.play("hit_big" if amount >= Combat.BIG_HIT else "hit")
		"heal":
			Sfx.play("heal")
		"block":
			Sfx.play("shield")
	var card: Control = _cards[u.id]
	var l := Label.new()
	l.top_level = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var big := amount >= Combat.BIG_HIT
	l.text = {"damage": "−%s", "heal": "+%s", "block": "(−%s)"}[kind] % Unit._num(amount)
	l.add_theme_font_size_override("font_size", 40 if big else 30)
	l.add_theme_color_override("font_color", {"damage": Color("ff5a4a"), "heal": Color("6cf07a"), "block": Color("8fc0ff")}[kind])
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.02))
	l.add_theme_constant_override("outline_size", 10)
	add_child(l)
	var rect := card.get_global_rect()
	# Несколько чисел подряд по одной карточке — лесенкой, чтобы не слипались.
	var stack: int = card.get_meta("floats", 0)
	card.set_meta("floats", stack + 1)
	l.global_position = Vector2(rect.position.x + rect.size.x * 0.55 + 18 * (stack % 3), rect.position.y + 6)
	l.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "global_position:y", l.global_position.y - 42, 0.9).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.35)
	tw.tween_callback(func() -> void:
		l.queue_free()
		if is_instance_valid(card):
			card.set_meta("floats", maxi(0, int(card.get_meta("floats", 1)) - 1)))


func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(0.01 if fast else Settings.delay(seconds)).timeout


# --- Обучение первого боя -----------------------------------------------

const TUTORIAL := {
	State.CHOOSE_TARGET: "[b]Шаг 1 из 4 · Выбери цель.[/b] Кликни по карточке врага (справа) или союзника (слева). [color=#ffd35a]Цель выбирается до фишек[/color] — поэтому лечение может достаться врагу, а удар своему. В этом весь «Я кастую!».",
	State.CHOOSE_BOOK: "[b]Шаг 2 из 4 · Выбери книгу.[/b] У каждой книги свои 30 заклинаний. Кнопка [color=#ffd35a]«Открыть»[/color] под обложкой покажет их все с шансами. На выбор — 30 секунд.",
	State.DRAWING: "[b]Шаг 3 из 4 · Тяни фишки.[/b] Кликай по [color=#ffd35a]мешочку[/color] — три раза. Порядок фишек определяет заклинание, чёрная фишка — Хаос. Не успеешь за 5 секунд — фишка вытянется сама, но вручную шанс на нужное заклинание чуть выше.",
	State.READY: "[b]Шаг 4 из 4 · Кричи![/b] Над кнопкой видно, что получилось. Жми [color=#ffd35a]«Я кастую!»[/color].",
	State.ENEMY_TURN: "[b]Ходят враги.[/b] Кто ходит следующим — в строке «Очередь» сверху: быстрые ходят чаще. Наведи мышь на иконку эффекта или жми «Инфо», чтобы узнать, что она значит.",
	State.ITEM_TARGET: "[b]Предмет.[/b] Выбери, на кого его использовать. Предмет не тратит ход.",
	State.ABILITY_TARGET: "[b]Способность класса.[/b] Выбери союзника. Способность не тратит ход.",
}


func _build_tutorial() -> void:
	_tutorial = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.13, 0.1, 0.05, 1.0)
	box.border_color = Color("ffd35a")
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(12)
	_tutorial.add_theme_stylebox_override("panel", box)
	_tutorial.z_index = 5
	add_child(_tutorial)
	# Поверх журнала (внизу), чтобы не закрывать карточки и кнопки.
	_tutorial.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_tutorial.offset_left = 16
	_tutorial.offset_right = -130
	_tutorial.offset_top = -124
	_tutorial.offset_bottom = -16
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_tutorial.add_child(row)
	var badge := Label.new()
	badge.text = "Обучение"
	badge.add_theme_color_override("font_color", Color("ffd35a"))
	badge.add_theme_font_size_override("font_size", 15)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(badge)
	_tutorial_label = RichTextLabel.new()
	_tutorial_label.bbcode_enabled = true
	_tutorial_label.fit_content = true
	_tutorial_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tutorial_label.add_theme_font_size_override("normal_font_size", 16)
	_tutorial_label.add_theme_font_size_override("bold_font_size", 17)
	row.add_child(_tutorial_label)
	var hide := Button.new()
	hide.text = "Скрыть обучение"
	hide.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hide.pressed.connect(func() -> void:
		Settings.set_value("tutorial", false)
		_stop_pulse()
		_tutorial.queue_free()
		_tutorial = null)
	row.add_child(hide)


func _tutorial_step() -> void:
	if _tutorial == null:
		return
	_tutorial.visible = TUTORIAL.has(state)
	_tutorial_label.text = TUTORIAL.get(state, "")
	match state:
		State.CHOOSE_TARGET, State.ITEM_TARGET, State.ABILITY_TARGET:
			_pulse([_party_box, _enemy_box])
		State.CHOOSE_BOOK:
			_pulse([_book_box])
		State.DRAWING:
			_pulse([_bag_button])
		State.READY:
			_pulse([_cast_button])
		_:
			_stop_pulse()


## Мягко мигает золотом то, куда нужно нажать.
func _pulse(targets: Array) -> void:
	_stop_pulse()
	for t in targets:
		if t is Control and t.visible:
			_pulsed.append(t)
			t.set_meta("pulse_base", t.modulate)
	if _pulsed.is_empty():
		return
	_pulse_tween = create_tween().set_loops()
	for t in _pulsed:
		var base: Color = t.get_meta("pulse_base")
		_pulse_tween.parallel().tween_property(t, "modulate", base * Color(1.3, 1.18, 0.7), 0.45)
	_pulse_tween.chain()
	for t in _pulsed:
		_pulse_tween.parallel().tween_property(t, "modulate", t.get_meta("pulse_base"), 0.45)


func _stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	for t in _pulsed:
		if is_instance_valid(t) and t.has_meta("pulse_base"):
			t.modulate = t.get_meta("pulse_base")
			t.remove_meta("pulse_base")
	_pulsed.clear()


# --- Построение интерфейса -----------------------------------------------

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Art.background("bg_battle_act1", 0.45))

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
	var gear := Button.new()
	gear.text = "Настройки"
	gear.pressed.connect(func() -> void: SettingsView.open(self))
	top.add_child(gear)
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
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	center.add_child(_prompt_label)

	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 18)
	center.add_child(chips)
	_timer_label = _label("", 13)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_timer_label.modulate = Color(1, 0.9, 0.6, 0.85)
	_timer_label.custom_minimum_size = Vector2(0, 18)
	center.add_child(_timer_label)
	# Мешочек: клик по нему тоже достаёт фишку.
	# Мешочек лежит в такой же ячейке, как фишки: гнездо сзади, мешочек обрезан по кругу.
	var bag_cell := Control.new()
	bag_cell.custom_minimum_size = Vector2(96, 96)
	bag_cell.visible = Art.bag() != null
	chips.add_child(bag_cell)
	var bag_socket := TextureRect.new()
	bag_socket.texture = Art.texture("res://assets/ui/chip_socket.png")
	bag_socket.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bag_socket.offset_left = -6
	bag_socket.offset_top = -6
	bag_socket.offset_right = 6
	bag_socket.offset_bottom = 6
	bag_socket.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bag_socket.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bag_socket.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bag_socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bag_cell.add_child(bag_socket)
	_bag_button = TextureButton.new()
	_bag_button.texture_normal = Art.bag()
	_bag_button.ignore_texture_size = true
	_bag_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_bag_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bag_button.material = Art.circle_material()
	_bag_button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_bag_button.tooltip_text = "Мешочек: достать фишку"
	_bag_button.pressed.connect(_on_draw_pressed.bind(true))
	bag_cell.add_child(_bag_button)
	for i in ChipBag.CHIPS_PER_CAST:
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 96)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_chip_pressed.bind(i))
		var socket := TextureRect.new()
		socket.texture = Art.texture("res://assets/ui/chip_socket.png")
		socket.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		socket.offset_left = -6
		socket.offset_top = -6
		socket.offset_right = 6
		socket.offset_bottom = 6
		socket.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		socket.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		socket.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(socket)
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
	_spell_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	center.add_child(_spell_label)

	_effects_box = HBoxContainer.new()
	_effects_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_effects_box.add_theme_constant_override("separation", 10)
	_effects_box.custom_minimum_size = Vector2(0, 76)
	center.add_child(_effects_box)

	# Баннер «Я кастую!» — накладка: мелькает на полсекунды и не занимает места в раскладке.
	var shout_slot := Control.new()
	shout_slot.custom_minimum_size = Vector2(0, 36)
	shout_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(shout_slot)
	var shout_holder := CenterContainer.new()
	shout_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shout_slot.add_child(shout_holder)
	shout_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shout_holder.offset_top = -40
	shout_holder.offset_bottom = 40
	_shout_banner = TextureRect.new()
	_shout_banner.texture = Art.texture("res://assets/ui/shout_banner.png")
	_shout_banner.custom_minimum_size = Vector2(420, 105)
	_shout_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shout_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_shout_banner.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_shout_banner.modulate.a = 0.0
	_shout_banner.pivot_offset = Vector2(210, 52)
	shout_holder.add_child(_shout_banner)
	_shout_label = _label("", 40)
	_shout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shout_label.add_theme_color_override("font_color", Color("ffd35a"))
	_shout_label.pivot_offset = Vector2(200, 25)
	_shout_label.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.02))
	_shout_label.add_theme_constant_override("outline_size", 8)
	shout_holder.add_child(_shout_label)

	_book_box = HBoxContainer.new()
	_book_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(_book_box)

	var controls := HFlowContainer.new()  # переносится, если кнопок много
	controls.alignment = FlowContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("h_separation", 12)
	controls.add_theme_constant_override("v_separation", 6)
	center.add_child(controls)
	_cast_button = _button("Я кастую!", _on_cast_pressed)
	var cast_box := Art.frame("button_cast", 56, 0.4, -1.0, Color.WHITE, 22)
	if cast_box:
		cast_box.content_margin_left = 24
		cast_box.content_margin_right = 24
		_cast_button.add_theme_stylebox_override("normal", cast_box)
		var ch := cast_box.duplicate()
		ch.modulate_color = Color(1.25, 1.15, 1.1)
		_cast_button.add_theme_stylebox_override("hover", ch)
		var cd := cast_box.duplicate()
		cd.modulate_color = Color(0.5, 0.45, 0.45, 0.8)
		_cast_button.add_theme_stylebox_override("disabled", cd)
		_cast_button.custom_minimum_size = Vector2(210, 52)
	controls.add_child(_cast_button)
	_item_button = _button("Предмет", _on_item_pressed)
	_item_button.visible = false
	controls.add_child(_item_button)
	_ability_button = _button("Способность", _on_ability_pressed)
	_ability_button.visible = false
	controls.add_child(_ability_button)
	_extra_box = HFlowContainer.new()
	_extra_box.alignment = FlowContainer.ALIGNMENT_CENTER
	_extra_box.add_theme_constant_override("h_separation", 8)
	_extra_box.add_theme_constant_override("v_separation", 6)
	center.add_child(_extra_box)


	_ability_label = _label("", 14)
	_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_ability_label.modulate = Color(1, 1, 1, 0.7)
	# Не больше двух строк, полный текст — в подсказке (иначе журнал уезжает за край).
	_ability_label.max_lines_visible = 2
	_ability_label.custom_minimum_size = Vector2(0, 46)
	_ability_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_ability_label.mouse_filter = Control.MOUSE_FILTER_PASS
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

	_log = BattleLog.new()
	_log.custom_minimum_size = Vector2(0, 150)
	root.add_child(_log)

	if Settings.value("tutorial") and not fast:
		_build_tutorial()

	_auto_timer = Timer.new()
	_auto_timer.one_shot = true
	_auto_timer.timeout.connect(_on_auto_timer)
	add_child(_auto_timer)


func _make_card(u: Unit) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(260, 98)  # пропорции рамки 512×192
	b.pressed.connect(_on_card_pressed.bind(u))
	var frame_name := "card_party" if u.is_wizard() else ("card_boss" if u.is_boss else ("card_leader" if u.is_leader else "card_enemy"))
	var box: StyleBox = Art.frame(frame_name, 40, 0.42)
	if box == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color("2d3a52") if u.is_wizard() else Color("522d2d")
		flat.set_corner_radius_all(8)
		box = flat
	var hover := box.duplicate()
	hover.set("modulate_color", Color(1.25, 1.25, 1.25))
	if hover is StyleBoxFlat:
		hover.bg_color = hover.bg_color.lightened(0.2)
	var dis := box.duplicate()
	dis.set("modulate_color", Color(0.5, 0.5, 0.55))
	if dis is StyleBoxFlat:
		dis.bg_color = dis.bg_color.darkened(0.5)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", box)
	b.add_theme_stylebox_override("disabled", dis)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14 if side in ["left", "right"] else 10)
	b.add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	# С кольцами — круглое лицо крупным планом, без колец — прямоугольный портрет по плечи.
	var ringed := Art.ring(_ring_kind(u)) != null
	var face_tex: Texture2D
	if u.is_wizard():
		face_tex = Art.wizard_face(u.class_id) if ringed else Art.portrait_head(u.class_id)
	else:
		face_tex = Art.enemy_face(u.name) if ringed else Art.enemy_head(u.name)
	if face_tex != null:
		var av := Art.avatar(face_tex, _ring_kind(u), 82)
		row.add_child(av)
		b.set_meta("avatar", av)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 3)
	row.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	var name_label := _label("", 14 if u.is_wizard() else 15)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD  # длинное имя — на вторую строку целыми словами
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(name_label)
	var hp_label := _label("", 13 if u.is_wizard() else 14)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ЗД — справа от полоски здоровья, чтобы имени досталась вся ширина строки.
	var bar_row := HBoxContainer.new()
	bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_row.add_theme_constant_override("separation", 6)
	col.add_child(bar_row)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 7)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.45)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("4cc46a") if u.is_wizard() else Color("e0413a")
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	bar_row.add_child(bar)
	bar_row.add_child(hp_label)
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
