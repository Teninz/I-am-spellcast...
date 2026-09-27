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
var _queue_box: HBoxContainer  # очередь ходов: лица в кольцах
var _prompt_label: Label
var _spell_label: Label
var _effects_box: HBoxContainer
var _shout_label: Label
var _shout_banner: TextureRect
var _ability_label: Label
var _skills_row: HBoxContainer
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
	combat.spell_triggered.connect(_announce_spell)
	combat.passive_triggered.connect(_on_passive)
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
	_cards_ready = true
	_advance()


func _add_card(u: Unit) -> void:
	if u.creature and u.side == Unit.PARTY:
		_tip_once("summon", "Призванное существо",
			"Появилось под своим волшебником круглым значком и ходит само, как враги. Первым ходом бьёт цель "
			+ "заклинания (или закрывает собой союзника). У волшебника не больше 2 существ, в конце боя они уходят. "
			+ "Наведи на значок — там написано, что оно умеет.")
		_add_token(u)
		return
	var card := _make_card(u)
	(_party_box if u.side == Unit.PARTY else _enemy_box).add_child(card)
	_cards[u.id] = card
	if _cards_ready and _anim():
		Fx.pop_in(card)
		await get_tree().process_frame
		await get_tree().process_frame  # контейнер расставляет карточки на следующем кадре
		if is_instance_valid(card):
			Fx.puff(self, Fx.center(card))


# --- Призванные существа отряда: круглые значки под призывателем ------------------

var _summon_rows := {}  # id призывателя -> HBoxContainer со значками


func _add_token(u: Unit) -> void:
	var row := _summon_row_for(u)
	var t := _make_token(u)
	row.add_child(t)
	row.get_parent().visible = true
	_cards[u.id] = t
	_update_token(t, u)
	if _cards_ready and _anim():
		Fx.pop_in(t)
		await get_tree().process_frame
		await get_tree().process_frame
		if is_instance_valid(t):
			Fx.puff(self, Fx.center(t))


## Ряд значков сразу под карточкой призывателя: он раздвигает карточки ниже.
func _summon_row_for(u: Unit) -> HBoxContainer:
	var owner_id := int(u.get_meta("owner", -1))
	if not _cards.has(owner_id) or _cards[owner_id].has_meta("token"):
		owner_id = -1
		for w in combat.units:
			if w.is_wizard():
				owner_id = w.id
				break
	if _summon_rows.has(owner_id) and is_instance_valid(_summon_rows[owner_id]):
		return _summon_rows[owner_id]
	var holder := MarginContainer.new()
	holder.add_theme_constant_override("margin_left", 30)
	holder.add_theme_constant_override("margin_top", -24)  # значки чуть заходят на карточку призывателя
	holder.add_theme_constant_override("margin_bottom", 0)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.z_index = 3  # поверх увеличенной карточки того, кто ходит
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(row)
	_party_box.add_child(holder)
	if _cards.has(owner_id):
		_party_box.move_child(holder, _cards[owner_id].get_index() + 1)
	_summon_rows[owner_id] = row
	return row


func _make_token(u: Unit) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(62, 78)
	b.pressed.connect(func() -> void:
		if state in [State.CHOOSE_TARGET, State.ITEM_TARGET, State.ABILITY_TARGET] and _can_input():
			_on_card_pressed(u)
		else:
			_open_sheet(u))
	b.set_meta("token", true)
	# ПКМ — карточка существа; ЛКМ — цель, если сейчас выбирают цель, иначе тоже карточка.
	b.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
			_open_sheet(u))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 1)
	b.add_child(col)
	var tex := Art.enemy_face(u.name)
	var av: Control = Art.avatar(tex, "enemy_summon", 56) if tex else _label(u.name.left(1), 24)
	if tex and _faces_left(u):
		var face: TextureRect = av.get_meta("face")
		face.flip_h = true  # портрет врага смотрит влево — на стороне отряда смотрит вправо, на врагов
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(av)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(52, 6)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("4cc46a")
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	col.add_child(bar)
	var hp := _label("", 11)
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp.add_theme_color_override("font_outline_color", Color.BLACK)
	hp.add_theme_constant_override("outline_size", 4)
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(hp)
	b.set_meta("bar", bar)
	b.set_meta("hp", hp)
	return b


func _update_token(t: Button, u: Unit) -> void:
	var bar: ProgressBar = t.get_meta("bar")
	bar.max_value = u.max_hp
	bar.value = u.hp
	var hp: Label = t.get_meta("hp")
	hp.text = u.hp_text()
	var cr: Dictionary = GameData.creatures().get(u.class_id, {})
	var lines: Array[String] = ["%s — ЗД %s" % [u.name, u.hp_text()], String(cr.get("text", "")), "Ходит само, в конце боя уходит."]
	var st: Array[String] = []
	for id in u.statuses:
		st.append(Combat.status_name(id))
	if u.shield > 0.0:
		st.append("Щит %s" % Unit._num(u.shield))
	if not st.is_empty():
		lines.append("Эффекты: " + ", ".join(st))
	lines.append("Клик — карточка характеристик.")
	t.tooltip_text = "\n".join(lines)


## Погибшее существо сразу исчезает; пустой ряд прячется.
func _drop_token(u: Unit) -> void:
	var t: Control = _cards.get(u.id)
	_cards.erase(u.id)
	if t == null or not is_instance_valid(t):
		return
	var row := t.get_parent()
	if _anim():
		Fx.burst(self, Fx.center(t), Color(0.6, 0.55, 0.5), 14)
	row.remove_child(t)
	t.queue_free()
	if row.get_child_count() == 0:
		row.get_parent().visible = false


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
		if _anim() and _cards.has(u.id):
			Fx.charge(_cards[u.id], u.side == Unit.ENEMIES)
			await _wait(0.2)
			if combat.outcome != "" or state == State.OVER:
				return
		combat.enemy_act(u)
		_refresh()
		_advance()
		return
	# Ослеплённый кастует в случайную цель из случайной книги.
	if u.has("blind"):
		target = combat.resolve_target(u, u)
		_do_select_book(u.books[combat.rng.randi_range(0, u.books.size() - 1)])
		return
	_set_state(State.CHOOSE_TARGET)
	_prompt_label.text = "%s, выбери цель: противника или союзника." % u.name
	if Luck.has_luck(u):
		_prompt_label.text += " Удача с тобой: открой книгу и вложи шкалу удачи."


# --- Действия игрока → команды (в сети — у всех в одном порядке) -------------------

## Состояния, в которых бой ждёт действия игрока.
const INPUT_STATES := [State.CHOOSE_TARGET, State.CHOOSE_BOOK, State.DRAWING, State.READY,
	State.ITEM_TARGET, State.ABILITY_TARGET, State.REWIND]

var _inbox: Array[Dictionary] = []


## Может ли этот игрок сейчас действовать (в сети — только за своих волшебников).
func _can_input() -> bool:
	if actor == null or not actor.is_wizard() or actor.wizard == null:
		return false
	return not NetSession.online() or adventure.controls(actor.wizard, NetSession.my_id())


## Действие игрока: без сети — сразу, в сети — через хозяина игры.
func _act(cmd: Dictionary) -> void:
	if not _can_input():
		return
	if NetSession.online():
		# Метка «где отправлено»: ход, состояние, сколько фишек уже вытянуто. Повторные клики,
		# пришедшие позже, у всех одинаково отбрасываются (см. _exec).
		cmd["turn"] = combat.turn_count
		cmd["state"] = state
		cmd["chips"] = bag.chips.size() if bag else 0
		NetSession.get_session().submit(cmd)
	else:
		_exec(cmd)


## Команда из сети: выполняется, когда бой дошёл до того же места (анимации у всех идут своим темпом).
func apply_cmd(cmd: Dictionary) -> void:
	_inbox.append(cmd)
	_pump()


func _pump() -> void:
	while not _inbox.is_empty() and state in INPUT_STATES:
		_exec(_inbox.pop_front())


func _exec(cmd: Dictionary) -> void:
	if NetSession.online() and (actor == null or actor.wizard == null
			or not adventure.controls(actor.wizard, int(cmd.get("from", 1)))):
		return  # не его ход — у всех игроков это действие одинаково пропускается
	if cmd.has("turn") and (int(cmd.turn) != combat.turn_count or int(cmd.state) != state
			or int(cmd.chips) != (bag.chips.size() if bag else 0)):
		return  # устаревшее действие (двойной клик, запоздалый повтор)
	match String(cmd.t):
		"card":
			for x in combat.units:
				if x.id == int(cmd.u):
					_do_card(x)
		"book":
			_do_select_book(String(cmd.id), cmd.get("plan", null))
		"book_random":
			if state == State.CHOOSE_BOOK:
				var pick: String = actor.books[combat.rng.randi_range(0, actor.books.size() - 1)]
				_on_log("Время вышло — %s хватает первую попавшуюся книгу: «%s»." % [actor.name, books[pick].name], "info")
				_do_select_book(pick)
		"plan":
			if state == State.DRAWING and bag != null and bag.chips.is_empty() and book_id == String(cmd.book):
				_luck_plans[book_id] = cmd.plan
				bag = combat.new_bag(actor, book_id, cmd.plan)
		"draw":
			_do_draw(bool(cmd.get("manual", true)))
		"reroll":
			_do_reroll(int(cmd.slot))
		"cast":
			if cmd.has("pick") and state == State.READY and actor:
				actor.set_meta("picked_combo", String(cmd.pick))
			_do_cast()
		"item":
			_do_item()
		"ability":
			_do_ability()
		"vision":
			_do_vision(int(cmd.i))
		"pact":
			_do_pact(String(cmd.letter))
		"rewind":
			_do_rewind()
		"rewind_skip":
			_do_rewind_skip()


func _on_card_pressed(u: Unit) -> void:
	_act({"t": "card", "u": u.id})


func _select_book(id: String, plan: Variant = null) -> void:
	_act({"t": "book", "id": id, "plan": plan if plan is Dictionary else _luck_plans.get(id, {})})


func _on_draw_pressed(manual: bool = true) -> void:
	_act({"t": "draw", "manual": manual})


func _on_chip_pressed(slot: int) -> void:
	_act({"t": "reroll", "slot": slot})


func _on_cast_pressed() -> void:
	# «Судьба переписана»: сначала игрок выбирает заклинание книги (в тестах — выбирает игра).
	if not fast and state == State.READY and _can_input() and combat.needs_pick(book_id, bag) and _picker == null:
		_open_picker()
		return
	_act({"t": "cast"})


func _on_item_pressed() -> void:
	_act({"t": "item"})


func _on_ability_pressed() -> void:
	# Сделка Чернокнижника сначала открывает выбор фишки — это только на экране у игрока.
	if combat.ability_phase(actor) == "draw" and _ability_available():
		_do_ability()
		return
	_act({"t": "ability"})


func _on_vision(i: int) -> void:
	_act({"t": "vision", "i": i})


func _on_pact(letter: String) -> void:
	_act({"t": "pact", "letter": letter})


func _on_rewind() -> void:
	_act({"t": "rewind"})


func _on_rewind_skip() -> void:
	_act({"t": "rewind_skip"})


func _do_card(u: Unit) -> void:
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
	var borrowed := combat.take_borrowed_book(actor)
	if borrowed != "":
		_on_log("Копия приёма: %s кастует из чужой книги «%s»." % [actor.name, books[borrowed].name], "misfire")
		_do_select_book(borrowed)
		return
	# Выбор книги — даже если она одна: можно открыть и прочитать заклинания и шансы.
	_set_state(State.CHOOSE_BOOK)
	_prompt_label.text = "Цель: %s. %s" % [target.name, "Выбери книгу." if actor.books.size() > 1 else "Открой книгу, чтобы прочитать заклинания, или сразу выбирай её."]


func _do_select_book(id: String, plan: Variant = null) -> void:
	if plan is Dictionary:
		_luck_plans[id] = plan
	book_id = id
	bag = combat.new_bag(actor, id, _luck_plans.get(id, {}))
	_show_book_cover(id)
	_set_state(State.DRAWING)
	_prompt_label.text = "%s → %s. Книга: %s. Доставай фишки!" % [actor.name, target.name, books[id].name]
	_update_chips()
	_auto_step()


## Клик по мешочку (manual) или автотяга: достаёт следующую фишку.
func _do_draw(manual: bool) -> void:
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


func _do_reroll(slot: int) -> void:
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


func current_is_enemy() -> bool:
	return actor != null and not actor.is_wizard()


## Анимации включены: не в тестах и не выключены в настройках.
func _anim() -> bool:
	return not fast and bool(Settings.value("animations"))


func _card_of(u: Unit) -> Control:
	return _cards.get(u.id, null) if u != null else null


func _do_cast() -> void:
	if state != State.READY:
		return
	var pre_spell := combat.spell_for(book_id, bag.combo_key())
	_set_state(State.ENEMY_TURN)  # блокируем ввод на время анимации
	# Снаряд заклинания цветом стихии летит к тем, кого заденет; хаос — радужный и трясёт экран.
	if _anim() and _cards.has(actor.id):
		var chaos := bag.chips.has(ChipBag.CHAOS)
		var color := _spell_color(bag.chips)
		var sets := _aim_sets(EffectParser.parse(pre_spell))
		var hits: Array[Unit] = sets[0]
		if hits.is_empty() and target:
			hits = [target]
		var from := Fx.center(_cards[actor.id])
		var fly := 0.0
		for u in hits.slice(0, 6):
			if _cards.has(u.id) and u != actor:
				fly = Fx.bolt(self, from, Fx.center(_cards[u.id]), color, chaos)
			elif u == actor:
				Fx.sparkle_up(self, _cards[u.id].get_global_rect(), color)
		if bag.combo_key() in ["X2", "X3"]:
			Fx.screen_shake(self, 9.0 if bag.combo_key() == "X3" else 6.0)
		if fly > 0.0:
			await get_tree().create_timer(fly, false).timeout
			if state == State.OVER or not is_inside_tree():
				return
	var again := actor.extra_casts > 0
	if again:
		actor.extra_casts -= 1
	_summary.clear()
	_collecting = true
	var spell := combat.cast(actor, target, book_id, bag, not again)
	_show_summary()
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


func _do_ability() -> void:
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


func _do_vision(i: int) -> void:
	if state != State.READY or not combat.can_use_vision(actor, bag) or i >= combat.visions.size():
		return
	combat.use_vision(actor, bag, i, book_id)
	_chips_changed()


func _do_pact(letter: String) -> void:
	_pact_picking = false
	if combat.pact_deal(actor, bag, letter):
		_refresh()
		_set_state(State.DRAWING)
		_do_draw(true)
	else:
		_set_state(State.DRAWING)


func _do_rewind() -> void:
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


func _do_rewind_skip() -> void:
	if state == State.REWIND:
		_after_cast(_rewind_again)


func _do_item() -> void:
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
	if fast or not _can_input():
		return  # в тестах интерфейс ведёт сам тест; в сети отсчёт идёт только у того, чей ход
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
			_close_picker()
			_act({"t": "cast"})  # время вышло — заклинание выберет судьба
		State.REWIND:
			_on_rewind_skip()
		State.CHOOSE_BOOK:
			_act({"t": "book_random"})


## Обратный отсчёт в подсказке.
func _process(_delta: float) -> void:
	if _timer_label == null:
		return
	var left := _auto_timer.time_left if not _auto_timer.is_stopped() else 0.0
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
	if win and _anim():
		Fx.confetti(self)
	await _wait(1.2)
	finished.emit(combat.outcome)


func _set_state(s: State) -> void:
	_stop_pulse()
	_clear_aim()
	if s != State.READY:
		_close_picker()
	state = s
	if _bag_button:
		_bag_button.disabled = s != State.DRAWING
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
			# Растрёпанные книги: сколько боёв книга ещё выдержит.
			if actor.wizard and b != "sheep" and not actor.wizard.stats().no_wear:
				var left := actor.wizard.life_of(b)
				var lf := Label.new()
				lf.text = "выдержит ещё %d %s" % [left, "бой" if left == 1 else "боя"]
				lf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lf.add_theme_font_size_override("font_size", 11)
				lf.add_theme_color_override("font_color", Color("ff8a6a") if left <= 1 else Color("ffd35a"))
				col.add_child(lf)
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
	_pump.call_deferred()


# --- Отрисовка -----------------------------------------------------------

func _refresh() -> void:
	if combat == null:
		return
	_rebuild_queue()
	for u in combat.units:
		if not _cards.has(u.id):
			continue
		var card: Button = _cards[u.id]
		if card.has_meta("token"):
			if not u.alive():
				_drop_token(u)
				continue
			_update_token(card, u)
		else:
			_update_card(card, u)
		var targetable := state == State.CHOOSE_TARGET and combat.can_target(actor, u)
		if state == State.ITEM_TARGET:
			targetable = combat.item_targets(actor, actor.wizard.item).has(u)
		if state == State.ABILITY_TARGET:
			targetable = _ability_targets().has(u)
		card.disabled = state in [State.CHOOSE_TARGET, State.ITEM_TARGET, State.ABILITY_TARGET] and not targetable
		card.modulate = Color(1, 1, 1, 1) if u.alive() else Color(1, 1, 1, 0.35)
		if _anim():
			Fx.focus(card, u == actor and u.alive())
	_ability_label.text = ""
	if actor and actor.is_wizard() and actor.wizard.item != "":
		_ability_label.text = "Предмет: %s — %s" % [adventure.items[actor.wizard.item].name,
			adventure.items[actor.wizard.item].text]
	_ability_label.tooltip_text = _ability_label.text
	_ability_label.visible = _ability_label.text != ""
	_rebuild_skills()


## Навыки того, кто ходит: активные — плитки-кнопки, пассивные — плитки с подсказкой.
func _rebuild_skills() -> void:
	if _skills_row == null:
		return
	# Пересобираем, только если что-то поменялось, — иначе подсказка при наведении пропадает.
	var sig := "" if actor == null else "%d|%d|%s|%s|%s|%s|%s" % [actor.id, state, actor.ability_charges, actor.ability_pool, combat.visions.size(), bag.chips.size() if bag else -1, _pact_picking]
	if _skills_row.get_meta("sig", "-") == sig:
		return
	_skills_row.set_meta("sig", sig)
	for c in _skills_row.get_children():
		_skills_row.remove_child(c)
		c.queue_free()
	if actor == null or not actor.is_wizard():
		return
	for s in SkillTile.skills_for(actor.class_id):
		var t := SkillTile.make(s, 46)
		if s.kind == "active":
			t.charges = _skill_charges(actor, String(s.id))
			t.usable = _ability_available() or _skill_usable_now(String(s.id))
			if _ability_available():
				t.pressed.connect(_on_ability_pressed)
		_skills_row.add_child(t)


func _skill_charges(u: Unit, id: String) -> String:
	match id:
		"lay_on_hands":
			return Unit._num(u.ability_pool)
		"visions":
			return str(combat.visions.size())
		"mix":
			return ""
	return str(u.ability_charges)


## Навыки, которые применяются не плиткой, а по месту (фишка, «Перемотка!», видения).
func _skill_usable_now(id: String) -> bool:
	match id:
		"burn":
			return state == State.READY and actor.ability_charges > 0
		"visions":
			return state == State.READY and combat.can_use_vision(actor, bag)
		"rewind":
			return state == State.REWIND
	return false


## Очередь ходов: сейчас ходит — крупно в золотом кольце, дальше — следующие 6 ходов.
func _rebuild_queue() -> void:
	for c in _queue_box.get_children():
		_queue_box.remove_child(c)
		c.queue_free()
	var title := _label("Очередь:", 15)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_queue_box.add_child(title)
	var list: Array[Unit] = []
	if actor != null and actor.alive():
		list.append(actor)
	list.append_array(combat.turn_queue(6))
	for i in list.size():
		if i > 0:
			var arrow := _label("›", 18)
			arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			arrow.modulate = Color(1, 1, 1, 0.6)
			_queue_box.add_child(arrow)
		_queue_box.add_child(_queue_face(list[i], i == 0 and list[i] == actor))


## Одно лицо очереди. Без портрета — первая буква имени в кольце.
func _queue_face(u: Unit, now: bool) -> Control:
	var size := 52 if now else 42
	var kind := "wizard_active" if now and u.is_wizard() else _ring_kind(u)
	var face: Texture2D = Art.wizard_face(u.class_id) if u.is_wizard() else Art.enemy_face(u.name)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(size, size)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.tooltip_text = ("Сейчас ходит: " if now else "") + u.name
	# Наведение на лицо подсвечивает карточку этого участника.
	holder.mouse_entered.connect(func() -> void:
		if _cards.has(u.id):
			_cards[u.id].modulate = Color(1.15, 1.15, 1.15))
	holder.mouse_exited.connect(_refresh)
	if face != null and Art.ring(kind) != null:
		var av := Art.avatar(face, kind, size)
		if _faces_left(u) and av.has_meta("face"):
			(av.get_meta("face") as TextureRect).flip_h = true
		av.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(av)
	else:
		var disc := Panel.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color("2d3a52") if u.is_wizard() else Color("522d2d")
		box.border_color = Color("ffd35a") if now else Color(0.6, 0.55, 0.45)
		box.set_border_width_all(2)
		box.set_corner_radius_all(size / 2)
		disc.add_theme_stylebox_override("panel", box)
		disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(disc)
		var letter := _label(u.name.substr(0, 1), 16 if now else 13)
		letter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(letter)
	return holder


## Карточка характеристик существа или врага.
func _open_sheet(u: Unit) -> void:
	for c in get_children():
		if c is CreatureSheet:
			c.queue_free()
	var owner := _unit_by_id_ui(int(u.get_meta("owner", -1)))
	CreatureSheet.open(self, u, owner.name if owner else "", _faces_left(u))


func _unit_by_id_ui(id: int) -> Unit:
	for x in combat.units:
		if x.id == id:
			return x
	return null


## Призванный на сторону отряда враг из Бестиария: его портрет нарисован лицом влево.
func _faces_left(u: Unit) -> bool:
	return u.side == Unit.PARTY and not u.is_wizard() \
		and not Art.enemy_portrait_id(u.name).begins_with("creature_")


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
			# В кольце лицо всегда чистое (раны читаются по кольцу и полоске ЗД), иначе мелкое лицо не разобрать.
			var st := "zombie" if zombie else "healthy"
			face.texture = Art.wizard_face(u.class_id, st) if av.has_meta("ring") else Art.portrait_head(u.class_id, Art.portrait_state(u.hp, u.max_hp, zombie))
		if av.has_meta("ring"):
			var r: TextureRect = av.get_meta("ring")
			var t := Art.ring(_ring_kind(u))
			if t:
				r.texture = t
			# Кольцо того, кто ходит, мягко «дышит».
			if u == actor and _anim() and r.get_meta("breathing", false) == false:
				if _breath:
					_breath.kill()
				for other in _cards.values():
					var oav: Control = other.get_meta("avatar", null)
					if oav and oav.has_meta("ring"):
						var orr: TextureRect = oav.get_meta("ring")
						orr.set_meta("breathing", false)
						orr.self_modulate = Color.WHITE
				r.set_meta("breathing", true)
				_breath = Fx.breathe(r)
	var bar: ProgressBar = card.get_meta("bar")
	bar.max_value = u.max_hp
	bar.value = u.hp
	var icons: HFlowContainer = card.get_meta("icons")
	# Значки пересобираются, только если статусы изменились: иначе подсказка при наведении
	# пропадает на каждом обновлении экрана (в чужой ход — постоянно).
	var sig := "%s|%s|%s|%s" % [u.alive(), JSON.stringify(u.statuses), u.shield, u.fortify]
	if card.get_meta("icons_sig", "") == sig:
		return
	card.set_meta("icons_sig", sig)
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
			if _anim() and _bag_button and b.get_meta("chip") == "":
				# Фишка вылетает из мешочка рубашкой вверх и ложится в ячейку.
				art.modulate.a = 0.0
				var fly := Fx.chip_fly(self, Art.chip(""), Fx.center(_bag_button), Fx.center(b), b.size.x * 0.8)
				tw.tween_interval(fly)
				tw.tween_callback(func() -> void: art.modulate.a = 1.0)
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
		if _anim():
			Fx.pop_in(btn)


## Просмотр книги. Вкладывать удачу можно, пока у волшебника Благословение и фишки ещё не тянули.
## choosing — открыто из выбора книги: внизу кнопка «Кастовать из этой книги».
func _open_book(id: String, choosing: bool) -> void:
	if actor == null or not actor.is_wizard():
		return
	var before_draw := state == State.CHOOSE_BOOK or (state == State.DRAWING and bag != null and bag.chips.is_empty())
	var can := Luck.has_luck(actor) and before_draw and _can_input()
	var note := ""
	if Luck.has_luck(actor) and not before_draw:
		note = "Фишки уже тянутся — удачу можно вложить только до первой фишки."
	var view := BookView.open(self, books[id], combat.book_odds(actor, id), can, _luck_plans.get(id, {}),
		(("Использовать механическую овцу" if id == "sheep" else "Кастовать из этой книги") if choosing and _can_input() else ""), note)
	view.plan_changed.connect(func(plan: Dictionary) -> void:
		_luck_plans[id] = plan
		# Книга уже выбрана, фишек ещё нет — пересобираем мешочек с новой удачей.
		if not choosing and state == State.DRAWING and bag != null and bag.chips.is_empty() and book_id == id:
			_act({"t": "plan", "book": id, "plan": plan}))
	if choosing:
		view.cast_pressed.connect(func(plan: Dictionary) -> void:
			_luck_plans[id] = plan
			if state == State.CHOOSE_BOOK:
				_select_book(id, plan))


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
	if combat.needs_pick(book_id, bag):
		_prompt_label.text = "«Судьба переписана»: нажми «Я кастую!» и выбери любое заклинание книги."
	_mark_aim(spell)


# --- Кого заденет заклинание ------------------------------------------------------

## Рамки на карточках: сплошная — точно заденет, полупрозрачная с «?» — может задеть (случайно).
func _mark_aim(spell: Dictionary) -> void:
	_clear_aim()
	if spell.is_empty() or actor == null:
		return
	var spec := EffectParser.parse(spell)
	var harm: bool = EffectParser.deals_damage(spec) or spec.meter < 0 or spec.strip_buffs \
		or spec.statuses.any(func(st: Dictionary) -> bool: return Unit.DEBUFFS.has(st.id))
	var sets := _aim_sets(spec)
	var sure: Array[Unit] = sets[0]
	var maybe: Array[Unit] = sets[1]
	for u in sure:
		var foe := u.side != actor.side
		var text := ("ранит своего!" if harm and not foe else "поможет врагу!" if not harm and foe else "удар" if harm else "поможет")
		var warn := (harm and not foe) or (not harm and foe)
		_aim(u, Color("ff9a4a") if warn else (Color("ff5a4a") if harm else Color("6cf07a")), text, false)
	for u in maybe:
		_aim(u, Color("ffd35a"), "может задеть", true)
	if spec.self_damage > 0 or not spec.caster_statuses.is_empty():
		if not sure.has(actor):
			_aim(actor, Color("ff9a4a") if spec.self_damage > 0 else Color("8fc0ff"), "отдача" if spec.self_damage > 0 else "на себя", false)


## Цвет заклинания — самой частой стихии тройки (хаос — фиолетовый).
func _spell_color(chips: Array) -> Color:
	var best := ""
	var n := 0
	for c in chips:
		if c != ChipBag.CHAOS and chips.count(c) > n:
			best = c
			n = chips.count(c)
	return Color("b070ff") if best == "" else ELEMENT_COLORS.get(best, Color("ffd35a"))


## Кого заклинание заденет точно и кого может задеть случайно: [sure, maybe].
func _aim_sets(spec: Dictionary) -> Array:
	var sure: Array[Unit] = []
	var maybe: Array[Unit] = []
	match String(spec.area):
		"target":
			if target:
				sure.append(target)
		"target_side":
			if target:
				sure.append_array(combat.living(target.side))
		"arena":
			for u in combat.living():
				if not (spec.exclude_caster and u == actor):
					sure.append(u)
		"enemies":
			sure.append_array(combat.living(combat.opposite(actor.side)))
		"caster_side":
			sure.append_array(combat.living(actor.side))
		"random":
			maybe.append_array(combat.living())
	if spec.splash > 0 and target:
		for u in combat.living(target.side):
			if not sure.has(u):
				sure.append(u)
	for j in spec.get("jumps", []):
		var pool: Array[Unit] = combat.living() if j.side == "any" else combat.living(actor.side if j.side == "caster" else (target.side if target else actor.side))
		for u in pool:
			if not sure.has(u) and not maybe.has(u) and u != target:
				maybe.append(u)
	var special: Array = spec.get("special", [])
	if special.has("random_chaos") or special.has("random_spell"):
		for u in combat.living():
			if not sure.has(u) and not maybe.has(u):
				maybe.append(u)
	return [sure, maybe]


func _aim(u: Unit, color: Color, text: String, uncertain: bool) -> void:
	if not _cards.has(u.id):
		return
	var card: Control = _cards[u.id]
	var p := Panel.new()
	p.name = "Aim"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = Color(color, 0.55 if uncertain else 0.95)
	box.set_border_width_all(2 if uncertain else 4)
	box.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel", box)
	var tag := Label.new()
	tag.text = text
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", color)
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.add_theme_constant_override("outline_size", 4)
	tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tag.offset_left = -130
	tag.offset_right = -10
	tag.offset_top = 4
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	p.add_child(tag)
	card.add_child(p)


func _clear_aim() -> void:
	for id in _cards:
		var card: Control = _cards[id]
		for c in card.get_children():
			if c.name.begins_with("Aim"):
				card.remove_child(c)
				c.queue_free()


# --- «Судьба переписана»: выбор заклинания ---------------------------------------

var _picker: Control = null


func _open_picker() -> void:
	_close_picker()
	var o := Control.new()
	o.top_level = true
	o.z_index = 8
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(center)
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("24232f")
	box.border_color = Color("ffd35a")
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	col.add_child(_label("Судьба переписана: выбери заклинание «%s» → %s" % [books[book_id].name, target.name if target else actor.name], 20))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	for sp in combat.pickable_spells(book_id):
		var b := Button.new()
		b.text = "%s — %s" % [sp.name, sp.effect]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.custom_minimum_size = Vector2(720, 0)
		b.add_theme_font_size_override("font_size", 14)
		b.tooltip_text = "Категория: %s" % Luck.CATEGORY_NAMES.get(sp.get("category", ""), sp.get("category", ""))
		var combo := String(sp.combo)
		b.pressed.connect(func() -> void:
			_close_picker()
			_act({"t": "cast", "pick": combo}))
		list.add_child(b)
	var fate := Button.new()
	fate.text = "Пусть выберет судьба (лучшее для цели)"
	fate.pressed.connect(func() -> void:
		_close_picker()
		_act({"t": "cast"}))
	col.add_child(fate)
	add_child(o)
	_picker = o


func _close_picker() -> void:
	if _picker != null:
		_picker.queue_free()
		_picker = null


# --- Итог каста над карточками ---------------------------------------------------

var _cards_ready := false  # начальные карточки построены — новые появляются с анимацией
var _breath: Tween = null
var _summary: Dictionary = {}  # id участника -> {dmg, heal, block, st: [имена]}
var _collecting := false


func _note(u: Unit, key: String, value: Variant) -> void:
	if not _collecting:
		return
	if not _summary.has(u.id):
		_summary[u.id] = {"dmg": 0.0, "heal": 0.0, "block": 0.0, "st": []}
	var e: Dictionary = _summary[u.id]
	if key == "st":
		if not e.st.has(value):
			e.st.append(value)
	else:
		e[key] = e[key] + float(value)


## Плашка «−3 · Горение · Щит 2» над каждой задетой карточкой.
func _show_summary() -> void:
	_collecting = false
	if fast:
		_summary.clear()
		return
	for id in _summary:
		if not _cards.has(id):
			continue
		var e: Dictionary = _summary[id]
		var parts: Array[String] = []
		if e.dmg > 0.0:
			parts.append("−%s" % Unit._num(e.dmg))
		if e.heal > 0.0:
			parts.append("+%s" % Unit._num(e.heal))
		if e.block > 0.0:
			parts.append("щит поглотил %s" % Unit._num(e.block))
		for n in e.st:
			parts.append(n)
		if parts.is_empty():
			continue
		var card: Control = _cards[id]
		var plate := PanelContainer.new()
		plate.top_level = true
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.07, 0.06, 0.09, 0.92)
		box.border_color = Color("ff5a4a") if e.dmg > 0.0 else Color("6cf07a") if e.heal > 0.0 else Color("ffd35a")
		box.set_border_width_all(2)
		box.set_corner_radius_all(6)
		box.set_content_margin_all(5)
		plate.add_theme_stylebox_override("panel", box)
		var l := _label(" · ".join(parts), 15)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		plate.add_child(l)
		add_child(plate)
		var r := card.get_global_rect()
		plate.global_position = Vector2(r.position.x + 90, r.position.y + r.size.y - 30)
		var tw := create_tween()
		tw.tween_interval(Settings.delay(2.2))
		tw.tween_property(plate, "modulate:a", 0.0, 0.4)
		tw.tween_callback(plate.queue_free)
	_summary.clear()


# --- Подсказки, которые показываются один раз -------------------------------------

func _tip_once(key: String, title: String, text: String) -> void:
	if fast:
		return
	var seen: Array = Settings.value("tips_seen")
	if seen.has(key):
		return
	seen = seen.duplicate()
	seen.append(key)
	Settings.set_value("tips_seen", seen)
	var panel := PanelContainer.new()
	panel.top_level = true
	panel.z_index = 6
	var box := StyleBoxFlat.new()
	box.bg_color = Color("24232f")
	box.border_color = Color("ffd35a")
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var t := _label(title, 18)
	t.add_theme_color_override("font_color", Color("ffd35a"))
	col.add_child(t)
	var body := _label(text, 14)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.custom_minimum_size = Vector2(440, 0)
	col.add_child(body)
	var ok := Button.new()
	ok.text = "Понятно"
	ok.size_flags_horizontal = Control.SIZE_SHRINK_END
	ok.pressed.connect(panel.queue_free)
	col.add_child(ok)
	add_child(panel)
	panel.position = Vector2((get_viewport_rect().size.x - 470) / 2.0, 70)
	get_tree().create_timer(15.0, false).timeout.connect(func() -> void:
		if is_instance_valid(panel):
			panel.queue_free())


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
	if id != "shield":
		_note(u, "st", Combat.status_name(id))
	if fast or not _cards.has(u.id):
		return
	Sfx.play("status_good" if Unit.BUFFS.has(id) or id in ["shield", "fortify"] else "status_bad")
	var icon := StatusIcon.make(id, "", 0, 56)
	icon.rich_tooltip = false
	var kind: String = GameData.statuses().get(id, {}).get("kind", "special")
	_announce("%s: %s" % [u.name, Combat.status_name(id)], icon, StatusIcon.FRAME_COLORS.get(kind, Color("ffd35a")))


# --- Объявления посреди экрана (эффекты, атаки врагов) --------------------------

## Пассивка босса сработала впервые — описание открывается и показывается посреди экрана.
func _on_passive(u: Unit, id: String) -> void:
	if Profile.knows_passive(id):
		return
	Profile.learn_passive(id)
	for card in _cards.values():
		card.set_meta("icons_sig", "")  # значки пересоберутся уже с описанием
	var info: Dictionary = GameData.statuses().get(id, {})
	var icon := StatusIcon.make(id, "", 0, 56)
	icon.rich_tooltip = false
	_announce("Раскрыто умение: %s" % info.get("name", id), icon, Color("e0b04a"))
	_on_log("Раскрыто умение %s — «%s»: %s" % [u.name, info.get("name", id), info.get("desc", "")], "special")
	_refresh()


## Заклинание «из ниоткуда» — крупно посреди экрана: как сработало, название, книга и что делает.
func _announce_spell(caster: Unit, spell: Dictionary, book: String, how: String) -> void:
	if fast:
		return
	var panel := PanelContainer.new()
	panel.top_level = true
	panel.z_index = 8
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.09, 0.06, 0.13, 0.96)
	box.border_color = Color("b070ff")
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	if books.has(book):
		var cover := Art.book_cover(books[book], 64)
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cover)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var head := _label("%s · %s" % [how, caster.name], 15)
	head.add_theme_color_override("font_color", Color("d8b8ff"))
	col.add_child(head)
	var title := _label("«%s»" % spell.get("name", "?"), 26)
	title.add_theme_color_override("font_color", Color("ffe9a8"))
	col.add_child(title)
	if books.has(book):
		var from := _label("из книги «%s»" % books[book].name, 14)
		from.modulate = Color(1, 1, 1, 0.75)
		col.add_child(from)
	var eff := _label(String(spell.get("effect", "")), 18)
	eff.autowrap_mode = TextServer.AUTOWRAP_WORD
	eff.custom_minimum_size = Vector2(460, 0)
	col.add_child(eff)
	add_child(panel)
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return
	var vp := get_viewport_rect().size
	panel.position = Vector2((vp.x - panel.size.x) / 2.0, vp.y * 0.12)
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.6, 0.6)
	panel.modulate.a = 0.0
	if _anim():
		Fx.burst(self, panel.position + panel.size / 2.0, Color("b070ff"), 30, true)
	var tw := panel.create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, Settings.delay(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(panel, "modulate:a", 1.0, Settings.delay(0.15))
	tw.tween_interval(Settings.delay(3.2))
	tw.tween_property(panel, "modulate:a", 0.0, Settings.delay(0.4))
	tw.tween_callback(panel.queue_free)


var _announcer: VBoxContainer = null


## Плашка посреди экрана: иконка и текст. Несколько подряд встают столбиком и гаснут по очереди,
## не закрывая значки на карточках.
func _announce(text: String, icon: Control = null, color: Color = Color("ffd35a")) -> void:
	if fast:
		if icon:
			icon.queue_free()
		return
	if _announcer == null or not is_instance_valid(_announcer):
		_announcer = VBoxContainer.new()
		_announcer.top_level = true
		_announcer.z_index = 7
		_announcer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_announcer.alignment = BoxContainer.ALIGNMENT_CENTER
		_announcer.add_theme_constant_override("separation", 6)
		add_child(_announcer)
	var vp := get_viewport_rect().size
	_announcer.size = Vector2(520, 0)
	_announcer.position = Vector2((vp.x - 520) / 2.0, vp.y * 0.44)
	while _announcer.get_child_count() >= 4:
		var old := _announcer.get_child(0)
		_announcer.remove_child(old)
		old.queue_free()
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.06, 0.09, 0.93)
	box.border_color = color
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.content_margin_left = 10
	box.content_margin_right = 14
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	plate.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	if icon:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	var l := _label(text, 20)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	row.add_child(l)
	_announcer.add_child(plate)
	plate.pivot_offset = Vector2(120, 30)
	plate.scale = Vector2(0.7, 0.7)
	plate.modulate.a = 0.0
	var tw := plate.create_tween()
	tw.tween_property(plate, "scale", Vector2.ONE, Settings.delay(0.15)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(plate, "modulate:a", 1.0, Settings.delay(0.12))
	tw.tween_interval(Settings.delay(1.3))
	tw.tween_property(plate, "modulate:a", 0.0, Settings.delay(0.35))
	tw.tween_callback(plate.queue_free)


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
	# Полученные предметы — тоже посреди экрана, с картинкой предмета.
	if kind == "item" and not fast and text.contains("получает предмет"):
		var item_name := text.get_slice(": ", 1).trim_suffix(".")
		var pic: Control = null
		for id in adventure.items:
			if adventure.items[id].name == item_name:
				pic = Art.item_icon(id, 52)
		_announce(text.trim_suffix("."), pic, Color("ffd35a"))
	# Неожиданные повороты (наоборот, отражение, призыв, воскрешение, «не сработало») — тоже по центру.
	if not fast and kind in ["misfire", "reflect", "summon", "revive", "fizzle"]:
		var tint: Color = {"misfire": Color("b070ff"), "reflect": Color("8fc0ff"), "summon": Color("e0b04a"),
			"revive": Color("6cf07a"), "fizzle": Color("9a9aa4")}[kind]
		_announce(text.trim_suffix("."), null, tint)
	# Атаки и особые приёмы врагов — посреди экрана, с лицом нападающего.
	if kind in ["enemy", "special", "enemy_heal"] and not fast and current_is_enemy():
		var face: Control = null
		if actor and not actor.is_wizard():
			var tex := Art.enemy_face(actor.name)
			if tex:
				face = Art.avatar(tex, _ring_kind(actor), 52)
				if _faces_left(actor) and face.has_meta("face"):
					(face.get_meta("face") as TextureRect).flip_h = true
		_announce(text.trim_suffix("."), face, Color("e0413a") if kind != "enemy_heal" else Color("6cf07a"))
	if not fast:
		var sound: String = {"kill": "down", "special": "enemy_special", "summon": "summon", "luck": "luck"}.get(kind, "")
		if sound != "":
			Sfx.play(sound)


## Всплывающее число над карточкой: −урон красным, +лечение зелёным, поглощение — голубым.
func _float_number(u: Unit, amount: float, kind: String) -> void:
	if amount > 0.0:
		_note(u, {"damage": "dmg", "heal": "heal", "block": "block"}.get(kind, "dmg"), amount)
	if _anim() and _cards.has(u.id) and amount > 0.0:
		var card: Control = _cards[u.id]
		match kind:
			"damage":
				Fx.shake(card, 1.7 if amount >= Combat.BIG_HIT else 1.0)
				Fx.flash(card, Color(1.6, 0.55, 0.5))
				if amount >= Combat.BIG_HIT:
					Fx.screen_shake(self, 4.0)
				if not u.alive():
					Fx.fall(card)
					Fx.burst(self, Fx.center(card), Color(0.55, 0.5, 0.5), 18)
			"heal":
				Fx.flash(card, Color(0.7, 1.5, 0.75))
				Fx.sparkle_up(self, card.get_global_rect(), Color("8cff9a"))
				Fx.stand_up(card)
			"block":
				Fx.burst(self, Fx.center(card), Color("8fc0ff"), 12)
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
	# process_always = false: на паузе ход врагов тоже стоит.
	return get_tree().create_timer(0.01 if fast else Settings.delay(seconds), false).timeout


# --- Пауза ----------------------------------------------------------------

var _pause_overlay: Control = null


## Горячие клавиши: Esc/P — пауза; 1–4 — книга; пробел или Enter — достать фишку / «Я кастую!».
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: Key = event.keycode
	if key == KEY_ESCAPE or key == KEY_P:
		if _picker != null and key == KEY_ESCAPE:
			_close_picker()
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if _pause_overlay != null or _picker != null or not _can_input():
		return
	if state == State.CHOOSE_BOOK and key >= KEY_1 and key <= KEY_4:
		var n := int(key - KEY_1)
		if n < actor.books.size():
			_select_book(actor.books[n])
			get_viewport().set_input_as_handled()
	elif key == KEY_SPACE or key == KEY_ENTER or key == KEY_KP_ENTER:
		if state == State.DRAWING:
			_on_draw_pressed(true)
		elif state == State.READY:
			_on_cast_pressed()
		else:
			return
		get_viewport().set_input_as_handled()


## Останавливает бой: ход врагов, отсчёт автонажатия и выбора книги, анимации.
## В сетевой игре пауза своя: чужие команды копятся и доиграются после паузы.
func toggle_pause() -> void:
	if _pause_overlay != null:
		_pause_overlay.queue_free()
		_pause_overlay = null
		get_tree().paused = false
		return
	get_tree().paused = true
	var o := Control.new()
	o.process_mode = Node.PROCESS_MODE_ALWAYS
	o.top_level = true
	o.z_index = 9
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)
	var title := _label("Пауза", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	if NetSession.online():
		var note := _label("Сетевая игра: у остальных бой идёт дальше, их ходы доиграются после паузы.", 15)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(note)
	for pair in [["Продолжить", toggle_pause], ["Настройки", func() -> void:
			var v := SettingsView.open(o)
			v.process_mode = Node.PROCESS_MODE_ALWAYS]]:
		var b := Button.new()
		b.text = pair[0]
		b.custom_minimum_size = Vector2(260, 52)
		b.pressed.connect(pair[1])
		col.add_child(b)
	add_child(o)
	_pause_overlay = o


func _exit_tree() -> void:
	if _pause_overlay != null:
		get_tree().paused = false
	if _ability_button and not _ability_button.is_inside_tree():
		_ability_button.free()


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
	# Свой фон у каждой локации: assets/ui/bg_battle_<id встречи>.png, иначе общий фон акта.
	var enc_id: String = adventure.encounter().get("id", "") if adventure else ""
	add_child(Art.background("bg_battle_" + enc_id, 0.35, "bg_battle_act1"))

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
	var pause := Button.new()
	pause.text = "Пауза"
	pause.tooltip_text = "Пауза (Esc или P)"
	pause.pressed.connect(toggle_pause)
	top.add_child(pause)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_queue_box = HBoxContainer.new()
	_queue_box.add_theme_constant_override("separation", 2)
	_queue_box.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(_queue_box)

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 16)
	root.add_child(middle)

	# Отряд с призванными существами может не влезть — колонка прокручивается, как у противников.
	var party_col := VBoxContainer.new()
	party_col.custom_minimum_size = Vector2(270, 0)
	party_col.add_child(_label("Отряд", 18))
	middle.add_child(party_col)
	var party_scroll := ScrollContainer.new()
	party_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	party_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	party_scroll.clip_contents = false  # увеличенная карточка того, кто ходит, не обрезается
	party_col.add_child(party_scroll)
	_party_box = VBoxContainer.new()
	_party_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_party_box.add_theme_constant_override("separation", -2)  # карточки плотнее
	party_scroll.add_child(_party_box)

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
	# Активный навык нажимается плиткой на панели навыков; кнопка остаётся как флаг доступности.
	_ability_button = _button("Способность", _on_ability_pressed)
	_ability_button.visible = false
	_extra_box = HFlowContainer.new()
	_extra_box.alignment = FlowContainer.ALIGNMENT_CENTER
	_extra_box.add_theme_constant_override("h_separation", 8)
	_extra_box.add_theme_constant_override("v_separation", 6)
	center.add_child(_extra_box)


	_skills_row = HBoxContainer.new()
	_skills_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_skills_row.add_theme_constant_override("separation", 10)
	_skills_row.custom_minimum_size = Vector2(0, 48)
	center.add_child(_skills_row)
	_ability_label = _label("", 14)
	_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_ability_label.modulate = Color(1, 1, 1, 0.7)
	# Одна строка, полный текст — в подсказке (иначе журнал уезжает за край).
	_ability_label.max_lines_visible = 1
	_ability_label.custom_minimum_size = Vector2(0, 22)
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
	enemy_scroll.clip_contents = false  # враг в броске выезжает из колонки
	enemy_col.add_child(enemy_scroll)
	_enemy_box = VBoxContainer.new()
	_enemy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_box.add_theme_constant_override("separation", -2)
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
	b.custom_minimum_size = Vector2(260, 104)
	if u.creature:
		b.custom_minimum_size = Vector2(260, 88)  # существа — чуть ниже, чтобы отряд влезал
	b.pressed.connect(_on_card_pressed.bind(u))
	if not u.is_wizard():
		b.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
				_open_sheet(u))
		b.tooltip_text = "ПКМ — карточка характеристик"
	var frame_name := "card_party" if u.side == Unit.PARTY else ("card_boss" if u.is_boss else ("card_leader" if u.is_leader else "card_enemy"))
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
	# Отступы — внутрь узорной рамки (её край ≈ 17 px), чтобы лицо, имя и ЗД не залезали на рамку.
	var pads := {"left": 16, "right": 20, "top": 14, "bottom": 13}
	for side in pads:
		margin.add_theme_constant_override("margin_" + side, pads[side])
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
		var av := Art.avatar(face_tex, _ring_kind(u), 60 if u.creature else 74)
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
	fill.bg_color = Color("4cc46a") if u.side == Unit.PARTY else Color("e0413a")
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
