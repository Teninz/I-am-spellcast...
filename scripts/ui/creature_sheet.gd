class_name CreatureSheet
extends Control
## Карточка существа в духе D&D: полный портрет в рамке и блок характеристик —
## здоровье, атака, скорость, защита, особенности, эффекты. Открывается кликом по значку существа
## (или правым кликом по любой карточке врага). Закрывается кликом мимо или Esc.

const TRAIT_NAMES := {
	"taunt": ["Провокация", "Враги бьют его первым."],
	"reassemble": ["Собирается", "Один раз за бой встаёт после гибели с половиной здоровья."],
	"invisible_first": ["Бесплотный", "В первый ход невидим."],
	"pierce_shield": ["Сквозь щиты", "Его удары игнорируют Щит."],
	"double_if_wounded": ["Чует кровь", "Бьёт дважды, если цель ранена."],
	"every_other": ["Разбег", "Бьёт раз в два хода, зато сильно."],
	"thorns": ["Колючки", "Кто его бьёт, получает 1 урон."],
	"owl": ["Зоркость", "Снимает Невидимость с врагов, хозяина нельзя Ослепить."],
	"swarm": ["Рой", "Бьёт всех на стороне цели разом."],
	"drunk": ["Навеселе", "20 %: спьяну бьёт своих."],
	"true_sight": ["Меткий глаз", "Попадает даже по невидимым."],
	"underground": ["Под землёй", "Первый ход неуязвим."],
}
const GROUP_NAMES := {"undead": "Нежить · Некрономикон", "beast": "Зверь · Книга Друида", "bestiary": "Чудище · Бестиарий"}


static func open(parent: Control, u: Unit, owner_name: String, flip: bool) -> CreatureSheet:
	var s := CreatureSheet.new()
	s.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(s)
	s._build(u, owner_name, flip)
	Sfx.play("book_open")
	return s


func _build(u: Unit, owner_name: String, flip: bool) -> void:
	top_level = true
	z_index = 12
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			queue_free())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var box: StyleBox = Art.frame("panel_dialog", 80, 0.55)
	if box == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color("24232f")
		box = flat
	box.set_content_margin_all(40)
	box.content_margin_top = 48
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	panel.add_child(row)

	# Портрет целиком в рамке цвета «редкости» существа.
	var cr: Dictionary = GameData.creatures().get(u.class_id, {})
	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var rarity := "epic" if u.is_boss else ("rare" if u.is_leader or u.creature else "common")
	frame.add_theme_stylebox_override("panel", Art.rarity_box(rarity, 300))
	var pic := TextureRect.new()
	pic.texture = Art.enemy_portrait(u.name)
	pic.custom_minimum_size = Vector2(270, 360)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.texture_filter = Art.filter_for(pic.texture)
	pic.flip_h = flip
	frame.add_child(pic)
	row.add_child(frame)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(360, 0)
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)
	col.add_child(_l(u.name, 28, Color("ffe9a8")))
	var kind := "Предводитель" if u.is_leader else ("Босс" if u.is_boss else "Противник")
	if u.creature:
		kind = String(GROUP_NAMES.get(cr.get("group", ""), "Призванное существо"))
	var sub := kind
	if owner_name != "":
		sub += " · призвал %s" % owner_name
	col.add_child(_l(sub, 14, Color(1, 1, 1, 0.7)))
	col.add_child(_rule())

	# Блок характеристик, как в бестиарии D&D.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	col.add_child(grid)
	var atk := "—" if u.attack <= 0 else ("%d × %d" % [u.attack, u.attacks] if u.attacks > 1 else str(u.attack))
	if u.heal_power > 0:
		atk = "лечит %d" % u.heal_power
	var stats := [["hp", "Здоровье", u.hp_text()], ["wisdom", "Атака", atk],
		["speed", "Скорость", Unit._num(u.effective_speed())], ["defense", "Защита", str(u.defense())]]
	for s in stats:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(160, 0)
		cell.add_theme_constant_override("separation", 0)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 4)
		var ic := Art.texture("res://assets/ui/stat_%s.png" % s[0])
		if ic:
			var tr := TextureRect.new()
			tr.texture = ic
			tr.custom_minimum_size = Vector2(22, 22)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			head.add_child(tr)
		head.add_child(_l(s[1], 13, Color("c9b98f")))
		cell.add_child(head)
		cell.add_child(_l(s[2], 22, Color.WHITE))
		grid.add_child(cell)
	col.add_child(_rule())

	# Особенности: черты существа, пассивка, особые атаки врага.
	var feats: Array = []
	for t in u.traits:
		if TRAIT_NAMES.has(t):
			feats.append(TRAIT_NAMES[t])
	if u.has_meta("on_hit_status"):
		var st: Dictionary = u.get_meta("on_hit_status")
		feats.append(["Ядовитый удар" if st.id == "poison" else "Особый удар", "Удар накладывает: %s." % Combat.status_name(st.id)])
	if u.has_meta("split"):
		feats.append(["Деление", "Получив много урона, делится надвое."] if u.creature else
			[Combat.status_name("split"), GameData.statuses().get("split", {}).get("desc", "")])
	if u.passive != "" and not u.has_meta("split"):
		var known := Profile.knows_passive(u.passive)
		var info: Dictionary = GameData.statuses().get(u.passive, {})
		feats.append([info.get("name", "???") if known else "???", info.get("desc", "") if known else StatusIcon.HIDDEN_DESC])
	for sp in u.specials:
		feats.append([String(sp.get("name", "Особая атака")), "%s (раз в %d хода)." % [String(sp.get("text", "")), int(sp.get("cooldown", 3))]])
	if cr.has("text") and feats.is_empty():
		feats.append(["Особенность", cr.text])
	col.add_child(_l("Особенности", 16, Color("e0b04a")))
	if feats.is_empty():
		col.add_child(_l("Ничего особенного — просто бьёт.", 14, Color(1, 1, 1, 0.75)))
	for f in feats:
		var rt := RichTextLabel.new()
		rt.bbcode_enabled = true
		rt.fit_content = true
		rt.scroll_active = false
		rt.custom_minimum_size = Vector2(360, 0)
		rt.add_theme_font_size_override("normal_font_size", 15)
		rt.add_theme_font_size_override("bold_font_size", 15)
		rt.text = "[b][color=#ffe9a8]%s.[/color][/b] %s" % [f[0], f[1]]
		col.add_child(rt)

	var st_names: Array[String] = []
	for id in u.statuses:
		st_names.append("%s (%d)" % [Combat.status_name(id), int(u.statuses[id].turns)] if int(u.statuses[id].turns) < 99 else Combat.status_name(id))
	if u.shield > 0.0:
		st_names.append("Щит %s" % Unit._num(u.shield))
	if not st_names.is_empty():
		col.add_child(_rule())
		col.add_child(_l("Сейчас: " + ", ".join(st_names), 14, Color("8fc0ff")))
	if u.creature:
		col.add_child(_l("Ходит само. В конце боя уходит.", 13, Color(1, 1, 1, 0.6)))
	var close := Button.new()
	close.text = "Закрыть"
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(queue_free)
	col.add_child(close)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()
		get_viewport().set_input_as_handled()


func _l(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _rule() -> HSeparator:
	var s := HSeparator.new()
	s.modulate = Color(0.9, 0.75, 0.45, 0.6)
	return s
