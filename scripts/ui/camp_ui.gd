extends Control
## Привал между уровнями: итог отдыха, инвентарь волшебников и лут.
## Кнопка «В бой!» активна, когда весь лут разобран.

signal continue_pressed

const STAT_NAMES := {
	"hp": "ЗД", "speed": "Скорость", "wisdom": "Мудрость", "defense": "Защита",
	"luck": "Удача", "resist": "Сопротивление",
}
const RARITY_NAMES := {
	"common": "Обычная", "rare": "Редкая", "epic": "Эпическая",
	"legendary": "Легендарная", "cursed": "Проклятая",
}
const RARITY_COLORS := {
	"common": Color("d6d6d6"), "rare": Color("6fa8ff"), "epic": Color("c07dff"),
	"legendary": Color("ffae42"), "cursed": Color("ff5a5a"),
}
const ELEMENT_NAMES := {
	"F": "Огонь", "W": "Вода", "H": "Святость", "D": "Тьма", "E": "Земля", "M": "Механика",
	"S": "Звук", "T": "Тайна", "I": "Иллюзия", "L": "Молния", "C": "Время", "K": "Лёд", "A": "Воздух",
}

var adventure: Adventure
var rest_report: Array = []
var torn: Array = []

var _columns: HBoxContainer
var _header: Label
var _info: Label
var _messages: RichTextLabel
var _continue: Button
## Строки, которые показать при открытии привала (например, полученные достижения).
var notices: Array[String] = []


func setup(adv: Adventure, rest: Array, torn_books: Array) -> void:
	adventure = adv
	rest_report = rest
	torn = torn_books


func _ready() -> void:
	_build()
	for n in notices:
		_say("[color=#ffd35a]%s[/color]" % n)
	for t in torn:
		_say("[color=#ff8a8a]%s: книга «%s» порвалась от износа![/color]" % [t.wizard.name, adventure.books[t.book].name])
	for r in rest_report:
		if r.get("revived", false):
			_say("[color=#e0b04a]%s выбыл в бою, но поднялся: %s ЗД (50 %%) и Разбитость — скорость −25 %% на %d ходов. Снимается лечением, щитом, баффом или Очищением.[/color]"
				% [r.wizard.name, Unit._num(r.wizard.hp), r.wizard.carry_statuses.get("aching", 0)])
		elif r.dead:
			_say("%s выбыл и не отдыхает — нужен свиток или зелье воскрешения." % r.wizard.name)
		else:
			var line := "%s отдыхает: +%s ЗД." % [r.wizard.name, Unit._num(r.healed)]
			if r.fortify > 0.0:
				line += " Излишек лечения → Укрепление %s на следующий бой." % Unit._num(r.fortify)
			_say(line)
	for o in adventure.offers:
		if o.has("note"):
			_say(o.note)
	_rebuild()


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Art.background("bg_camp", 0.5))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var head := HBoxContainer.new()
	root.add_child(head)
	_header = _label("", 22)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_header)
	var info := Button.new()
	info.text = "Инфо"
	info.tooltip_text = "Что значат иконки эффектов"
	info.pressed.connect(func() -> void: StatusInfo.open(self))
	head.add_child(info)
	_info = _label("", 15)
	_info.modulate = Color(1, 1, 1, 0.75)
	root.add_child(_info)

	_columns = HBoxContainer.new()
	_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_columns.alignment = BoxContainer.ALIGNMENT_CENTER
	_columns.add_theme_constant_override("separation", 12)
	root.add_child(_columns)

	_messages = RichTextLabel.new()
	_messages.bbcode_enabled = true
	_messages.scroll_following = true
	_messages.custom_minimum_size = Vector2(0, 64)
	_messages.add_theme_font_size_override("normal_font_size", 14)
	root.add_child(_messages)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 10)
	root.add_child(bottom)
	var gear := Button.new()
	gear.text = "Настройки"
	gear.custom_minimum_size = Vector2(0, 48)
	gear.pressed.connect(func() -> void: SettingsView.open(self))
	bottom.add_child(gear)
	_continue = Button.new()
	_continue.custom_minimum_size = Vector2(220, 48)
	_continue.add_theme_font_size_override("font_size", 18)
	_continue.pressed.connect(func() -> void: continue_pressed.emit())
	bottom.add_child(_continue)


func _rebuild() -> void:
	var done := adventure.level - 1
	_header.text = "Привал после уровня %d" % done
	var next := "Дальше — развилка: выбор пути на карте" if adventure.needs_choice() \
		else "Следующий бой: %s%s" % [adventure.encounter().name, " (БОСС)" if adventure.is_last_level() else ""]
	_info.text = "Уровень %d из %d. %s.   Отказов от книг у отряда осталось: %d." % [
		adventure.level, adventure.level_count(), next, adventure.refusals_left]
	for c in _columns.get_children():
		c.queue_free()
	for i in adventure.wizards.size():
		_columns.add_child(_wizard_column(i))
	_continue.disabled = not adventure.all_resolved()
	var go := "К карте" if adventure.needs_choice() else "В бой!"
	_continue.text = go if adventure.all_resolved() else "Сначала разбери добычу"


func _wizard_column(i: int) -> Control:
	var w := adventure.wizards[i]
	# Колонка всегда в пропорциях рамки (400×720): рамка масштабируется целиком, не растягиваясь.
	var panel := AspectRatioContainer.new()
	panel.ratio = 400.0 / 720.0
	panel.stretch_mode = AspectRatioContainer.STRETCH_FIT
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card := Control.new()
	panel.add_child(card)
	var frame_tex := Art.keyed("res://assets/ui/card_rest.png")
	if frame_tex:
		var tr := TextureRect.new()
		tr.texture = frame_tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(tr)
	else:
		var flat := ColorRect.new()
		flat.color = Color("2b3a30")
		flat.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(flat)
	# Содержимое — внутри рамки (доли от размера, чтобы масштабировались вместе с ней).
	var inner := ScrollContainer.new()
	inner.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner.anchor_left = 0.07
	inner.anchor_right = 0.93
	inner.anchor_top = 0.15
	inner.anchor_bottom = 0.965
	card.add_child(inner)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	inner.add_child(col)

	col.add_child(_label(w.name + ("  (зомби)" if w.zombie else ""), 19))
	var st := w.stats()
	var hp_line := "ЗД %s/%s" % [Unit._num(w.hp), Unit._num(w.max_hp())] if w.alive() else "ВЫБЫЛ"
	if w.fortify > 0.0:
		hp_line += "   Укрепление %s" % Unit._num(w.fortify)
	col.add_child(_label(hp_line, 16))
	var icons := HFlowContainer.new()
	if w.fortify > 0.0:
		icons.add_child(StatusIcon.make("fortify", Unit._num(w.fortify), 0, 36))
	for id in w.carry_statuses:
		icons.add_child(StatusIcon.make(id, str(w.carry_statuses[id]), 0, 36))
	if icons.get_child_count() > 0:
		col.add_child(icons)
	var stats_row := HFlowContainer.new()
	stats_row.add_theme_constant_override("h_separation", 10)
	for sd in [["wisdom", str(st.wisdom), "Мудрость"], ["defense", str(st.defense), "Защита"],
			["luck", str(st.luck), "Удача"], ["resist", str(st.resist), "Сопротивление"],
			["speed", Unit._num(st.speed), "Скорость"]]:
		stats_row.add_child(Art.stat(sd[0], sd[1], sd[2]))
	col.add_child(stats_row)

	col.add_child(_section("Добыча"))
	for o in adventure.offers:
		if o.wizard == i:
			_offer_card(col, o, w)
	col.add_child(HSeparator.new())
	col.add_child(_section("Книги (%d/%d)" % [w.books.size(), w.max_books]))
	for b in w.books:
		var row := _row()
		var wear := w.wear_of(b)
		row.add_child(_book_link(b, 30))
		var book_label := _small("%s%s" % [adventure.books[b].name, "  (износ %d/%d)" % [wear, Wizard.WEAR_LIMIT] if wear > 0 else ""])
		book_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(book_label)
		for ally in adventure.wizards:
			if ally != w and w.books.size() > 1 and adventure.can_give_book(ally, b):
				row.add_child(_btn("→ %s" % ally.name, func() -> void:
					adventure.give_book(w, b, ally)
					_say("%s отдаёт «%s» → %s." % [w.name, adventure.books[b].name, ally.name])
					_rebuild()))
		if w.books.size() > 1:
			row.add_child(_btn("✕", func() -> void:
				adventure.discard_book(w, b)
				_say("%s выбрасывает «%s»." % [w.name, adventure.books[b].name])
				_rebuild()))
		col.add_child(row)

	# Учёный: починка овцы — выбросить две книги.
	if adventure.can_repair_sheep(w):
		col.add_child(_small("Овца сломана. Починить — выбросить 2 книги:"))
		var pairs := _row()
		for a in w.books.size():
			for b in range(a + 1, w.books.size()):
				var ba: String = w.books[a]
				var bb: String = w.books[b]
				pairs.add_child(_btn("✕ %s + %s" % [adventure.books[ba].name, adventure.books[bb].name], func() -> void:
					if adventure.repair_sheep(w, ba, bb):
						_say("%s чинит механическую овцу!" % w.name)
					_rebuild()))
		col.add_child(pairs)

	col.add_child(_section("Предметы (%d)" % w.max_items if w.max_items > 1 else "Предмет"))
	if w.item2 != "":
		col.add_child(_small("Второй: %s — %s" % [adventure.items[w.item2].name, adventure.items[w.item2].text]))
	if adventure.can_mix(w):
		col.add_child(_btn("Смешать два предмета в один редкий", func() -> void:
			var made := adventure.mix_items(w)
			if made != "":
				_say("%s смешивает зелья — получилось «%s»!" % [w.name, adventure.items[made].name])
				Sfx.play("luck")
			_rebuild()))
	if w.item == "":
		col.add_child(_small("—"))
	else:
		var it: Dictionary = adventure.items[w.item]
		var item_row := HBoxContainer.new()
		item_row.add_theme_constant_override("separation", 8)
		item_row.add_child(Art.item_icon(w.item, 40, it.text))
		var item_text := _small("%s — %s" % [it.name, it.text])
		item_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_row.add_child(item_text)
		col.add_child(item_row)
		var row := _row()
		for t in adventure.camp_item_targets(w):
			row.add_child(_btn("Применить → %s" % t.name, func() -> void:
				_say(adventure.use_item_camp(w, t))
				_rebuild()))
		for ally in adventure.wizards:
			if ally != w and ally.has_item_slot():
				row.add_child(_btn("→ %s" % ally.name, func() -> void:
					adventure.give_item(w, ally)
					_rebuild()))
		col.add_child(row)

	for slot in ["hat", "boots"]:
		col.add_child(_section("Шляпа" if slot == "hat" else "Ботинки"))
		var e := w.equipment(slot)
		if e.is_empty():
			col.add_child(_small("—"))
		else:
			var eq_row := HBoxContainer.new()
			eq_row.add_theme_constant_override("separation", 8)
			eq_row.add_child(Art.equipment_icon(e.id, 40, e.name))
			var eq_text := _small(_equipment_text(e))
			eq_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			eq_row.add_child(eq_text)
			col.add_child(eq_row)

	return panel


func _offer_card(col: VBoxContainer, o: Dictionary, w: Wizard) -> void:
	var outer := col  # кнопки действий — на всю ширину колонки, под картинкой
	if o.kind in ["book", "item", "equipment"]:
		var cover_row := HBoxContainer.new()
		cover_row.add_theme_constant_override("separation", 10)
		match String(o.kind):
			"book":
				cover_row.add_child(_book_link(o.id, 80))
			"item":
				cover_row.add_child(Art.item_icon(o.id, 72))
			"equipment":
				var frame := PanelContainer.new()
				frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				frame.add_theme_stylebox_override("panel", Art.rarity_box(adventure.equipment[o.id].rarity, 80))
				frame.add_child(Art.equipment_icon(o.id, 64))
				cover_row.add_child(frame)
		var side := VBoxContainer.new()
		side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cover_row.add_child(side)
		col.add_child(cover_row)
		col = side
	var title := _label(adventure.offer_name(o), 17)
	var rarity := _offer_rarity(o)
	if rarity != "":
		title.add_theme_color_override("font_color", RARITY_COLORS[rarity])
	col.add_child(title)
	var lines := _offer_text(o).split("\n", false, 1)
	col.add_child(_small(lines[0]))
	if lines.size() > 1:
		outer.add_child(_small(lines[1]))
	if o.resolved:
		col.add_child(_small("✔ Разобрано"))
		return
	var row := HFlowContainer.new()
	outer.add_child(row)
	match String(o.kind):
		"book":
			var book_name: String = adventure.books[o.id].name
			if adventure.can_take_book(w, o.id):
				row.add_child(_btn("Взять", func() -> void: _act(adventure.take_book(o), "%s берёт «%s»." % [w.name, book_name])))
			elif w.can_use_book(o.id):
				for b in w.books:
					row.add_child(_btn("Вместо «%s»" % adventure.books[b].name, func() -> void:
						_act(adventure.take_book(o, b), "%s меняет «%s» на «%s»." % [w.name, adventure.books[b].name, book_name])))
			else:
				col.add_child(_small("%s не может пользоваться этой книгой." % w.name))
			for ally in adventure.wizards:
				if ally != w and adventure.can_give_book(ally, o.id):
					row.add_child(_btn("Отдать: %s" % ally.name, func() -> void:
						_act(adventure.give_offer_book(o, ally), "«%s» → %s." % [book_name, ally.name])))
			if adventure.can_refuse_book(o):
				var label := "Выбросить" if not w.can_use_book(o.id) else "Отказаться (осталось %d)" % adventure.refusals_left
				row.add_child(_btn(label, func() -> void: _act(adventure.refuse_book(o), "От «%s» отказались." % book_name)))
		"item":
			var item_name: String = adventure.items[o.id].name
			row.add_child(_btn("Взять" if w.has_item_slot() else "Взять (вместо своего)", func() -> void:
				adventure.take_item(o)
				_act(true, "%s берёт «%s»." % [w.name, item_name])))
			for ally in adventure.wizards:
				if ally != w and ally.has_item_slot():
					row.add_child(_btn("Отдать: %s" % ally.name, func() -> void:
						_act(adventure.give_offer_item(o, ally), "«%s» → %s." % [item_name, ally.name])))
			row.add_child(_btn("Выбросить", func() -> void:
				adventure.discard_offer(o)
				_act(true, "«%s» выброшен." % item_name)))
		"equipment":
			var e: Dictionary = adventure.equipment[o.id]
			for who in adventure.wizards:
				var cur := who.equipment(e.slot)
				var label := "Надеть" if who == w else "Отдать: %s" % who.name
				if not cur.is_empty():
					label += " (вместо «%s»)" % cur.name
				row.add_child(_btn(label, func() -> void:
					adventure.equip_offer(o, who)
					_act(true, "%s надевает «%s»." % [who.name, e.name])))
			row.add_child(_btn("Выбросить", func() -> void:
				adventure.discard_offer(o)
				_act(true, "«%s» выброшено." % e.name)))


func _act(ok: bool, message: String) -> void:
	if ok:
		_say(message)
		Sfx.play("loot")
	_rebuild()


func _offer_rarity(o: Dictionary) -> String:
	match String(o.kind):
		"book":
			return adventure.books[o.id].rarity
		"equipment":
			return adventure.equipment[o.id].rarity
	return ""


func _offer_text(o: Dictionary) -> String:
	match String(o.kind):
		"book":
			var b: Dictionary = adventure.books[o.id]
			var els: Array[String] = []
			for k in b.bag:
				if k != "X":
					els.append(ELEMENT_NAMES.get(k, k))
			var owner: String = b.class if b.class != null else "без класса"
			return "Книга · %s · %s\nСтихии: %s\n%s" % [RARITY_NAMES[b.rarity], owner, ", ".join(PackedStringArray(els)), b.flavor]
		"item":
			return "Расходуемый предмет\n%s" % adventure.items[o.id].text
		"equipment":
			var e: Dictionary = adventure.equipment[o.id]
			var full := _equipment_text(e)
			return "%s · %s\n%s" % ["Шляпа" if e.slot == "hat" else "Ботинки", RARITY_NAMES[e.rarity], full.substr(full.find(": ") + 2)]
	return ""


func _equipment_text(e: Dictionary) -> String:
	var parts: Array[String] = []
	for k in e.stats:
		parts.append("%s %+d" % [STAT_NAMES.get(k, k), e.stats[k]])
	var text := "%s (%s): %s" % [e.name, RARITY_NAMES[e.rarity], ", ".join(PackedStringArray(parts))]
	if e.has("text"):
		text += ". " + e.text
	if e.has("prototype_note"):
		text += " (" + e.prototype_note + ")"
	return text


## Обложка-кнопка: открывает книгу (все заклинания и шансы) — чтобы решить, брать ли её.
func _book_link(book_id: String, width: int) -> Control:
	var b := Button.new()
	b.flat = true
	b.tooltip_text = "Открыть книгу: заклинания и шансы"
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cover := Art.book_cover(adventure.books[book_id], width)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.custom_minimum_size = cover.get_combined_minimum_size()
	b.add_child(cover)
	b.pressed.connect(func() -> void:
		var book: Dictionary = adventure.books[book_id]
		BookView.open(self, book, ChipBag.odds(book.bag), false, {}, "",
			"Шкала удачи — в бою, при Благословении. Здесь книгу можно только прочитать."))
	return b


func _say(text: String) -> void:
	_messages.append_text(text + "\n")


func _section(text: String) -> Label:
	var l := _label(text, 14)
	l.add_theme_color_override("font_color", Color("a9d7b2"))
	return l


func _row() -> HFlowContainer:
	return HFlowContainer.new()


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	return l


func _small(text: String) -> Label:
	return _label(text, 13)


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(cb)
	return b
