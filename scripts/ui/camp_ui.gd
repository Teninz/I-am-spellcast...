extends Control
## Привал между уровнями: итог отдыха, инвентарь волшебников и лут.
## У каждого волшебника — карточка-инвентарь без прокрутки: слоты книг, предметов, шляпы и ботинок.
## Выпавшая добыча лежит сверху и светится, а слоты, куда её можно положить, мигают.
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
## Все действия привала: ключ -> {text, cb, owner}. Строятся для всех волшебников одинаково
## у всех игроков (не зависят от того, что кто выделил), поэтому в сети ключ однозначен.
var _buttons := {}
var _btn_owner := -1    # колонка какого волшебника сейчас строится
var _sel := {}          # номер волшебника -> что выделено: {type: offer/book/item/item2/hat/boots, ...}
var _pulse: Tween = null
var _glowing: Array[Control] = []


func setup(adv: Adventure, rest: Array, torn_books: Array) -> void:
	adventure = adv
	rest_report = rest
	torn = torn_books


func _ready() -> void:
	_build()
	for n in notices:
		_say("[color=#ffd35a]%s[/color]" % n)
	for t in torn:
		_say("[color=#ff8a8a]%s: книга «%s» развалилась — растрёпанные книги выдерживают %d боя.[/color]" % [t.wizard.name, adventure.books[t.book].name, Wizard.BOOK_LIFE])
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


const CARD_RATIO := 400.0 / 720.0  # пропорции рамки card_rest — масштабируется целиком
const GLOW := Color("ffd35a")


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Art.background("bg_camp", 0.4))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	margin.add_child(root)

	# Одна строка сверху: заголовок, что дальше, кнопки — чтобы карточкам досталась вся высота.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	root.add_child(head)
	_header = _label("", 22)
	_header.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(_header)
	_info = _label("", 14)
	_info.modulate = Color(1, 1, 1, 0.75)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_info)
	var info := Button.new()
	info.text = "Инфо"
	info.tooltip_text = "Что значат иконки эффектов"
	info.pressed.connect(func() -> void: StatusInfo.open(self))
	head.add_child(info)
	var gear := Button.new()
	gear.text = "Настройки"
	gear.pressed.connect(func() -> void: SettingsView.open(self))
	head.add_child(gear)
	_continue = Button.new()
	_continue.custom_minimum_size = Vector2(220, 0)
	_continue.add_theme_font_size_override("font_size", 17)
	_continue.pressed.connect(func() -> void: continue_pressed.emit())
	head.add_child(_continue)

	_columns = HBoxContainer.new()
	_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_columns.alignment = BoxContainer.ALIGNMENT_CENTER
	_columns.add_theme_constant_override("separation", 2)
	root.add_child(_columns)

	_messages = RichTextLabel.new()
	_messages.bbcode_enabled = true
	_messages.scroll_following = true
	_messages.custom_minimum_size = Vector2(0, 46)
	_messages.add_theme_font_size_override("normal_font_size", 13)
	root.add_child(_messages)


func _rebuild() -> void:
	var done := adventure.level - 1
	_header.text = "Привал после уровня %d" % done
	var next := "дальше — развилка на карте" if adventure.needs_choice() \
		else "следующий бой: %s%s" % [adventure.encounter().name, " (БОСС)" if adventure.is_last_level() else ""]
	_info.text = "Уровень %d из %d, %s. Отказов от книг: %d." % [
		adventure.level, adventure.level_count(), next, adventure.refusals_left]
	_stop_glow()
	for c in _columns.get_children():
		_columns.remove_child(c)
		c.queue_free()
	_collect_actions()
	for i in adventure.wizards.size():
		_columns.add_child(_wizard_column(i))
	_continue.disabled = not adventure.all_resolved() or (NetSession.online() and not NetSession.get_session().is_host)
	var go := "К карте" if adventure.needs_choice() else "В бой!"
	_continue.text = go if adventure.all_resolved() else "Сначала разбери добычу"
	_start_glow()


# --- Действия (одинаковые у всех игроков) ------------------------------------

func _reg(key: String, text: String, cb: Callable) -> void:
	_buttons[key] = {"text": text, "cb": cb, "owner": _btn_owner}


func _collect_actions() -> void:
	_buttons.clear()
	for k in adventure.offers.size():
		var o: Dictionary = adventure.offers[k]
		if o.resolved or not o.has("wizard"):
			continue
		_btn_owner = int(o.wizard)
		_offer_actions(k, o, adventure.wizards[o.wizard])
	for i in adventure.wizards.size():
		_btn_owner = i
		_owned_actions(i, adventure.wizards[i])
	_btn_owner = -1


func _offer_actions(k: int, o: Dictionary, w: Wizard) -> void:
	var p := "o%d:" % k
	match String(o.kind):
		"book":
			var book_name: String = adventure.books[o.id].name
			if adventure.can_take_book(w, o.id):
				_reg(p + "take", "Взять", func() -> void: _act(adventure.take_book(o), "%s берёт «%s»." % [w.name, book_name]))
			elif w.can_use_book(o.id):
				for b in w.books:
					_reg(p + "swap:" + b, "Вместо «%s»" % adventure.books[b].name, func() -> void:
						_act(adventure.take_book(o, b), "%s меняет «%s» на «%s»." % [w.name, adventure.books[b].name, book_name]))
			for j in adventure.wizards.size():
				var ally := adventure.wizards[j]
				if ally != w and adventure.can_give_book(ally, o.id):
					_reg(p + "give:%d" % j, "Отдать: %s" % ally.name, func() -> void:
						_act(adventure.give_offer_book(o, ally), "«%s» → %s." % [book_name, ally.name]))
			if adventure.can_refuse_book(o):
				var label := "Выбросить" if not w.can_use_book(o.id) else "Отказаться (осталось %d)" % adventure.refusals_left
				_reg(p + "refuse", label, func() -> void: _act(adventure.refuse_book(o), "От «%s» отказались." % book_name))
		"item":
			var item_name: String = adventure.items[o.id].name
			_reg(p + "take", "Взять" if w.has_item_slot() else "Взять (вместо своего)", func() -> void:
				adventure.take_item(o)
				_act(true, "%s берёт «%s»." % [w.name, item_name]))
			for j in adventure.wizards.size():
				var ally := adventure.wizards[j]
				if ally != w and ally.has_item_slot():
					_reg(p + "give:%d" % j, "Отдать: %s" % ally.name, func() -> void:
						_act(adventure.give_offer_item(o, ally), "«%s» → %s." % [item_name, ally.name]))
			_reg(p + "drop", "Выбросить", func() -> void:
				adventure.discard_offer(o)
				_act(true, "«%s» выброшен." % item_name))
		"equipment":
			var e: Dictionary = adventure.equipment[o.id]
			for j in adventure.wizards.size():
				var who := adventure.wizards[j]
				var cur := who.equipment(e.slot)
				var label := "Надеть" if who == w else "Отдать: %s" % who.name
				if not cur.is_empty():
					label += " (вместо «%s»)" % cur.name
				_reg(p + "equip:%d" % j, label, func() -> void:
					adventure.equip_offer(o, who)
					_act(true, "%s надевает «%s»." % [who.name, e.name]))
			_reg(p + "drop", "Выбросить", func() -> void:
				adventure.discard_offer(o)
				_act(true, "«%s» выброшено." % e.name))


func _owned_actions(i: int, w: Wizard) -> void:
	var p := "w%d:" % i
	for b in w.books:
		for j in adventure.wizards.size():
			var ally := adventure.wizards[j]
			if ally != w and w.books.size() > 1 and adventure.can_give_book(ally, b):
				_reg(p + "book:%s:give:%d" % [b, j], "Отдать: %s" % ally.name, func() -> void:
					adventure.give_book(w, b, ally)
					_act(true, "%s отдаёт «%s» → %s." % [w.name, adventure.books[b].name, ally.name]))
		if w.books.size() > 1:
			_reg(p + "book:%s:drop" % b, "Выбросить", func() -> void:
				adventure.discard_book(w, b)
				_act(true, "%s выбрасывает «%s»." % [w.name, adventure.books[b].name]))
	if adventure.can_repair_sheep(w):
		for a in w.books.size():
			for c in range(a + 1, w.books.size()):
				var ba: String = w.books[a]
				var bb: String = w.books[c]
				_reg(p + "repair:%s:%s" % [ba, bb], "Починить овцу: ✕ %s + %s" % [adventure.books[ba].name, adventure.books[bb].name], func() -> void:
					_act(adventure.repair_sheep(w, ba, bb), "%s чинит механическую овцу!" % w.name))
	if adventure.can_mix(w):
		_reg(p + "mix", "Смешать два предмета", func() -> void:
			var made := adventure.mix_items(w)
			if made != "":
				Sfx.play("luck")
			_act(made != "", "%s смешивает зелья — получилось «%s»!" % [w.name, adventure.items.get(made, {}).get("name", "")]))
	if w.item != "":
		var targets := adventure.camp_item_targets(w)
		for t in targets:
			_reg(p + "use:%d" % adventure.wizards.find(t), "Применить → %s" % t.name, func() -> void:
				_say(adventure.use_item_camp(w, t))
				_rebuild())
		for j in adventure.wizards.size():
			var ally := adventure.wizards[j]
			if ally != w and ally.has_item_slot():
				_reg(p + "item:give:%d" % j, "Отдать: %s" % ally.name, func() -> void:
					adventure.give_item(w, ally)
					_act(true, "%s отдаёт предмет → %s." % [w.name, ally.name]))


## Ключи действий с данным началом (в порядке добавления).
func _keys(prefix: String) -> Array:
	return _buttons.keys().filter(func(k: String) -> bool: return k.begins_with(prefix))


# --- Карточка волшебника ----------------------------------------------------------

func _pending_offers(i: int) -> Array:
	var out := []
	for k in adventure.offers.size():
		var o: Dictionary = adventure.offers[k]
		if int(o.get("wizard", -1)) == i and not o.resolved:
			out.append(k)
	return out


func _selection(i: int) -> Dictionary:
	var sel: Dictionary = _sel.get(i, {})
	var pending := _pending_offers(i)
	if sel.get("type", "") == "offer" and not pending.has(int(sel.k)):
		sel = {}
	if sel.is_empty() and not pending.is_empty():
		sel = {"type": "offer", "k": pending[0]}
	_sel[i] = sel
	return sel


func _select(i: int, sel: Dictionary) -> void:
	_sel[i] = sel
	_rebuild()


func _wizard_column(i: int) -> Control:
	var w := adventure.wizards[i]
	_btn_owner = i
	var panel := AspectRatioContainer.new()
	panel.ratio = CARD_RATIO
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
	# Содержимое — строго внутри рамки (доли от размера рамки), без прокрутки.
	var col := VBoxContainer.new()
	# Зелёное поле рамки: x 11–89 %, y 13–91 %; ещё отступ от рваного края и угловых накладок.
	col.anchor_left = 0.14
	col.anchor_right = 0.86
	col.anchor_top = 0.16
	col.anchor_bottom = 0.875
	col.add_theme_constant_override("separation", 5)
	col.clip_contents = true
	card.add_child(col)
	var sel := _selection(i)

	# Голова: лицо, имя, здоровье, характеристики, навыки.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	col.add_child(head)
	var face_tex := Art.portrait_head(w.class_id, Art.portrait_state(w.hp, w.max_hp(), w.zombie))
	if face_tex:
		var face := Art.portrait_rect(face_tex, Vector2(40, 52))
		if not w.alive():
			face.modulate = Color(0.45, 0.45, 0.5)
		head.add_child(face)
	var head_text := VBoxContainer.new()
	head_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_text.add_theme_constant_override("separation", 0)
	head.add_child(head_text)
	var name_l := _label(w.name + ("  (зомби)" if w.zombie else ""), 17)
	head_text.add_child(name_l)
	var hp_line := "ЗД %s/%s" % [Unit._num(w.hp), Unit._num(w.max_hp())] if w.alive() else "ВЫБЫЛ"
	if w.fortify > 0.0:
		hp_line += " · Укрепление %s" % Unit._num(w.fortify)
	head_text.add_child(_label(hp_line, 14))
	var st := w.stats()
	var stats_row := HFlowContainer.new()
	stats_row.add_theme_constant_override("h_separation", 6)
	for sd in [["wisdom", str(st.wisdom), "Мудрость"], ["defense", str(st.defense), "Защита"],
			["luck", str(st.luck), "Удача"], ["resist", str(st.resist), "Сопротивление"],
			["speed", Unit._num(st.speed), "Скорость"]]:
		stats_row.add_child(Art.stat(sd[0], sd[1], sd[2]))
	for id in w.carry_statuses:
		stats_row.add_child(StatusIcon.make(id, str(w.carry_statuses[id]), 0, 26))
	col.add_child(stats_row)
	# Навыки класса — справа от имени (наведение — что делают).
	var skills := VBoxContainer.new()
	skills.add_theme_constant_override("separation", 3)
	for s in SkillTile.skills_for(w.class_id):
		var t := SkillTile.make(s, 26)
		t.usable = true
		skills.add_child(t)
	head.add_child(skills)

	# Выпавшая добыча — сверху, светится.
	var pending := _pending_offers(i)
	if not pending.is_empty():
		var loot_row := HBoxContainer.new()
		loot_row.add_theme_constant_override("separation", 6)
		var cap := _label("Выпало:", 14)
		cap.autowrap_mode = TextServer.AUTOWRAP_OFF
		cap.add_theme_color_override("font_color", GLOW)
		cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		loot_row.add_child(cap)
		for k in pending:
			var o: Dictionary = adventure.offers[k]
			var tile := _tile(_offer_texture(o), 46, true, sel.get("type", "") == "offer" and int(sel.k) == k, _offer_rarity_of(o))
			_set_tip(tile, adventure.offer_name(o), _offer_rarity_of(o), Array(_offer_text(o).split("\n", false)))
			tile.pressed.connect(_select.bind(i, {"type": "offer", "k": k}))
			_glowing.append(tile)
			loot_row.add_child(tile)
		col.add_child(loot_row)

	# Инвентарь: книги, предметы, шляпа, ботинки. Подсвечены слоты, куда можно положить выбранную добычу.
	var target := _loot_target(sel)
	var books_row := HBoxContainer.new()
	books_row.add_theme_constant_override("separation", 6)
	for n in maxi(w.max_books, w.books.size()):
		var b: String = w.books[n] if n < w.books.size() else ""
		var tile := _tile(Art.book(b) if b != "" else null, 52, false,
			sel.get("type", "") == "book" and sel.get("id", "") == b and b != "",
			adventure.books[b].rarity if b != "" else "", 1.3)
		if b != "":
			_set_tip(tile, adventure.books[b].name, adventure.books[b].rarity, _book_lines(b, w))
		else:
			tile.tooltip_text = "Пустой слот книги · занято %d из %d" % [w.books.size(), w.max_books]
		var glow: bool = target == "book" and (b == "" and _has_key(sel, "take") or b != "" and _has_key(sel, "swap:" + b))
		if glow:
			_glowing.append(tile)
			var key := _offer_key(sel, "take" if b == "" else "swap:" + b)
			tile.tooltip_text += "\nКлик — положить сюда: %s" % _buttons[key].text
			tile.tip_lines = tile.tip_lines + ["Клик — положить сюда: %s" % _buttons[key].text]
			tile.pressed.connect(_press.bind(key))
		elif b != "":
			tile.pressed.connect(_select.bind(i, {"type": "book", "id": b}))
		if b != "" and b != "sheep" and not w.stats().no_wear:
			var left := w.life_of(b)
			var wear := _label("%d %s" % [left, _battles_word(left)], 11)
			wear.add_theme_color_override("font_color", Color("ff8a6a") if left <= 1 else (Color("ffd35a") if left == 2 else Color.WHITE))
			wear.add_theme_color_override("font_outline_color", Color.BLACK)
			wear.add_theme_constant_override("outline_size", 4)
			wear.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			wear.offset_left = -44
			wear.offset_top = -18
			wear.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.add_child(wear)
		books_row.add_child(tile)
	col.add_child(books_row)

	var gear_row := HBoxContainer.new()
	gear_row.add_theme_constant_override("separation", 6)
	var slots: Array = ["item"]
	if w.max_items > 1:
		slots.append("item2")
	slots.append_array(["hat", "boots"])
	for slot in slots:
		var tex: Texture2D = null
		var tip := ""
		var rarity := ""
		if slot in ["item", "item2"]:
			var id: String = w.item if slot == "item" else w.item2
			if id != "":
				tex = Art.texture("res://assets/items/%s.png" % id)
				tip = adventure.items[id].name
			else:
				tip = "Пустой слот предмета"
		else:
			var e := w.equipment(slot)
			if not e.is_empty():
				tex = Art.texture("res://assets/equipment/%s.png" % e.id)
				tip = e.name
				rarity = e.rarity
			else:
				tip = "Шляпы нет" if slot == "hat" else "Ботинок нет"
		var tile := _tile(tex, 46, false, sel.get("type", "") == slot, rarity)
		tile.tooltip_text = tip
		if slot in ["item", "item2"]:
			var iid: String = w.item if slot == "item" else w.item2
			if iid != "":
				_set_tip(tile, adventure.items[iid].name, "", ["Расходуемый предмет", adventure.items[iid].text])
		elif tex != null:
			var eq := w.equipment(slot)
			_set_tip(tile, eq.name, eq.rarity, [("Шляпа" if slot == "hat" else "Ботинки") + " · " + RARITY_NAMES[eq.rarity],
				_equipment_text(eq).substr(_equipment_text(eq).find(": ") + 2)])
		var glow_key := ""
		if target == "item" and slot == ("item" if w.item == "" or w.max_items < 2 else "item2") and _has_key(sel, "take"):
			glow_key = _offer_key(sel, "take")
		elif target == slot and _has_key(sel, "equip:%d" % i):
			glow_key = _offer_key(sel, "equip:%d" % i)
		if glow_key != "":
			_glowing.append(tile)
			tile.tooltip_text += "\nКлик — %s" % _buttons[glow_key].text.to_lower()
			tile.tip_lines = tile.tip_lines + ["Клик — %s" % _buttons[glow_key].text.to_lower()]
			tile.pressed.connect(_press.bind(glow_key))
		elif tex != null:
			tile.pressed.connect(_select.bind(i, {"type": slot}))
		gear_row.add_child(tile)
	col.add_child(gear_row)

	col.add_child(HSeparator.new())
	col.add_child(_details(i, w, sel))
	_btn_owner = -1
	return panel


## Описание вещи — в карточке при наведении на слот (а не текстом под инвентарём).
func _set_tip(tile: LootTile, title: String, rarity: String, lines: Array) -> void:
	tile.tip_title = title
	tile.tip_color = RARITY_COLORS.get(rarity, Color("ffe9a8"))
	tile.tip_lines = lines
	tile.tooltip_text = title


func _book_lines(b: String, w: Wizard = null) -> Array:
	var lines: Array = Array(_offer_text({"kind": "book", "id": b}).split("\n", false))
	if w != null and b != "sheep" and not w.stats().no_wear:
		var left := w.life_of(b)
		lines.append("Растрёпанная книга: выдержит ещё %d %s%s." % [left, _battles_word(left),
			" — последняя, держится на честном слове" if left == 1 and w.books.size() == 1 else ""])
	return lines


static func _battles_word(n: int) -> String:
	if n % 10 == 1 and n % 100 != 11:
		return "бой"
	if n % 10 in [2, 3, 4] and not (n % 100 in [12, 13, 14]):
		return "боя"
	return "боёв"


## Куда ляжет выбранная добыча: book / item / hat / boots или "".
func _loot_target(sel: Dictionary) -> String:
	if sel.get("type", "") != "offer":
		return ""
	var o: Dictionary = adventure.offers[int(sel.k)]
	match String(o.kind):
		"book":
			return "book"
		"item":
			return "item"
		"equipment":
			return String(adventure.equipment[o.id].slot)
	return ""


func _offer_key(sel: Dictionary, action: String) -> String:
	return "o%d:%s" % [int(sel.k), action]


func _has_key(sel: Dictionary, action: String) -> bool:
	return sel.get("type", "") == "offer" and _buttons.has(_offer_key(sel, action))


## Подробности выделенного: название, описание, кнопки действий.
func _details(i: int, w: Wizard, sel: Dictionary) -> Control:
	var box := ScrollContainer.new()  # на случай длинного описания; добыча и слоты всегда видны выше
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 3)
	box.add_child(col)
	var prefix := ""
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 4)
	row.add_theme_constant_override("v_separation", 4)
	match String(sel.get("type", "")):
		"offer":
			var o: Dictionary = adventure.offers[int(sel.k)]
			var title := _label(adventure.offer_name(o), 16)
			var r := _offer_rarity_of(o)
			if r != "":
				title.add_theme_color_override("font_color", RARITY_COLORS[r])
			col.add_child(title)
			col.add_child(row)  # действия — сразу под названием; описание — при наведении на вещь
			if o.kind == "book":
				col.add_child(_local_btn("Открыть книгу", _open_book.bind(o.id)))
				if not w.can_use_book(o.id):
					col.add_child(_small("%s не может пользоваться этой книгой." % w.name))
			var hint: String = {"book": "Клик по мигающему слоту книги — взять или заменить.",
				"item": "Клик по мигающему слоту предмета — взять.",
				"equipment": "Клик по мигающему слоту — надеть."}.get(String(o.kind), "")
			var h := _small(hint)
			h.add_theme_color_override("font_color", GLOW)
			col.add_child(h)
			prefix = "o%d:" % int(sel.k)
		"book":
			var b: String = sel.id
			col.add_child(_label(adventure.books[b].name, 16))
			col.add_child(_local_btn("Открыть книгу", _open_book.bind(b)))
			prefix = "w%d:book:%s:" % [i, b]
		"item", "item2":
			var id: String = w.item if sel.type == "item" else w.item2
			if id != "":
				col.add_child(_label(adventure.items[id].name, 16))
			if sel.type == "item":
				prefix = "w%d:item" % i
		"hat", "boots":
			var e := w.equipment(sel.type)
			if not e.is_empty():
				var t := _label(e.name, 16)
				t.add_theme_color_override("font_color", RARITY_COLORS.get(e.rarity, Color.WHITE))
				col.add_child(t)
		_:
			col.add_child(_small("Наведи на вещь — появится описание. Кликни — чтобы отдать или выбросить."))
	if row.get_parent() == null:
		col.add_child(row)
	if prefix != "":
		for key in _keys(prefix):
			if prefix == "w%d:item" % i and not (String(key).begins_with("w%d:item:" % i)):
				continue
			row.add_child(_action_btn(key))
		if prefix == "w%d:item" % i:
			for key in _keys("w%d:use:" % i) + _keys("w%d:mix" % i):
				row.add_child(_action_btn(key))
	# Починка овцы — всегда на виду, пока овца сломана.
	for key in _keys("w%d:repair:" % i):
		row.add_child(_action_btn(key))
	return box


func _offer_texture(o: Dictionary) -> Texture2D:
	match String(o.kind):
		"book":
			return Art.book(o.id)
		"item":
			return Art.texture("res://assets/items/%s.png" % o.id)
		"equipment":
			return Art.texture("res://assets/equipment/%s.png" % o.id)
	return null


func _offer_rarity_of(o: Dictionary) -> String:
	return _offer_rarity(o)


## Слот инвентаря: картинка в рамке (цвет редкости), выделенный — золотая рамка.
func _tile(tex: Texture2D, px: int, loot: bool, selected: bool, rarity: String, tall: float = 1.0) -> LootTile:
	var b := LootTile.new()
	b.custom_minimum_size = Vector2(px, px * tall)
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.08, 0.1, 0.85) if tex else Color(0.08, 0.08, 0.1, 0.35)
	box.border_color = GLOW if selected else (RARITY_COLORS.get(rarity, Color(0.6, 0.6, 0.6, 0.6)) if tex else Color(0.6, 0.6, 0.6, 0.35))
	box.set_border_width_all(3 if selected else 2)
	box.set_corner_radius_all(5)
	for st in ["normal", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, box)
	var hover := box.duplicate()
	hover.bg_color = box.bg_color.lightened(0.15)
	b.add_theme_stylebox_override("hover", hover)
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 3
		tr.offset_top = 3
		tr.offset_right = -3
		tr.offset_bottom = -3
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tr)
	b.set_meta("loot", loot)
	return b


## Мигание: добыча и слоты, куда её можно положить.
func _start_glow() -> void:
	if _glowing.is_empty():
		return
	_pulse = create_tween().set_loops()
	for t in _glowing:
		_pulse.parallel().tween_property(t, "modulate", Color(1.35, 1.25, 0.8), 0.5)
	_pulse.chain()
	for t in _glowing:
		_pulse.parallel().tween_property(t, "modulate", Color.WHITE, 0.5)


func _stop_glow() -> void:
	if _pulse:
		_pulse.kill()
		_pulse = null
	_glowing.clear()


## Кнопка действия из таблицы: чужие волшебники в сети — неактивны.
func _action_btn(key: String) -> Button:
	var e: Dictionary = _buttons[key]
	var b := Button.new()
	b.text = e.text
	b.add_theme_font_size_override("font_size", 12)
	b.custom_minimum_size = Vector2(0, 26)
	var owner: int = e.owner
	b.disabled = NetSession.online() and owner >= 0 and not adventure.controls(adventure.wizards[owner], NetSession.my_id())
	b.pressed.connect(_press.bind(key))
	return b


## Кнопка, которая ничего не меняет в игре (открыть книгу) — в сеть не уходит.
func _local_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size = Vector2(0, 30)
	b.pressed.connect(cb)
	return b


func _press(key: String) -> void:
	if not _buttons.has(key):
		return
	var e: Dictionary = _buttons[key]
	var owner: int = e.owner
	if NetSession.online():
		if owner >= 0 and not adventure.controls(adventure.wizards[owner], NetSession.my_id()):
			return
		NetSession.get_session().submit({"t": "camp_btn", "key": key, "text": e.text})
	else:
		e.cb.call()


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
	var cover := Art.book_cover(adventure.books[book_id], width)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cover.tooltip_text = "%s — клик: открыть книгу (заклинания и шансы)" % adventure.books[book_id].name
	cover.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_open_book(book_id))
	return cover


func _open_book(book_id: String) -> void:
	var book: Dictionary = adventure.books[book_id]
	BookView.open(self, book, ChipBag.odds(book.bag), false, {}, "",
		"Шкала удачи — в бою, при Благословении. Здесь книгу можно только прочитать.")


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
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.add_theme_font_size_override("font_size", size)
	return l


func _small(text: String) -> Label:
	return _label(text, 13)


## Команда из сети: нажать ту же кнопку (если нажимающий — хозяин этого волшебника).
func apply_cmd(cmd: Dictionary) -> void:
	if String(cmd.get("t", "")) != "camp_btn":
		return
	var entry: Dictionary = _buttons.get(String(cmd.key), {})
	if entry.is_empty() or entry.text != String(cmd.text):
		push_warning("Привал: кнопка %s не совпала — рассинхрон?" % cmd.key)
		return
	var owner: int = entry.owner
	if owner >= 0 and not adventure.controls(adventure.wizards[owner], int(cmd.get("from", 1))):
		return
	entry.cb.call()
