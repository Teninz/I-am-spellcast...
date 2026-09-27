extends Control
## Корневой экран: бой → привал → бой … → итог акта.

const BattleUI := preload("res://scripts/ui/battle_ui.gd")
const CampUI := preload("res://scripts/ui/camp_ui.gd")
const PartySelectUI := preload("res://scripts/ui/party_select_ui.gd")
const MapUI := preload("res://scripts/ui/map_ui.gd")
const TrophyUI := preload("res://scripts/ui/trophy_ui.gd")
const LobbyUI := preload("res://scripts/ui/net_lobby_ui.gd")

## Для тестов: ускоряет задержки в бою.
var fast := false
var adventure: Adventure
var profile: Profile
var classes: Dictionary
var screen: Control
## Достижения этого приключения (для экрана итогов).
var _run_achievements: Array[String] = []
var _pending_notices: Array[String] = []
var _chat: ChatOverlay


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Art.ui_theme()
	Settings.load_from_disk()
	var net := NetSession.get_session()
	net.command.connect(_on_command)
	net.started.connect(_on_net_started)
	net.ended.connect(func(reason: String) -> void:
		_hide_chat()
		new_adventure()
		screen.set_meta("net_message", reason)
		if screen.has_method("show_message"):
			screen.show_message(reason))
	new_adventure()


## Экран выбора отряда перед каждым приключением.
func new_adventure() -> void:
	classes = GameData.load_classes()
	profile = Profile.load_or_new(classes)
	var sel: Control = PartySelectUI.new()
	sel.setup(classes, profile)
	sel.start_pressed.connect(start_adventure)
	sel.continue_pressed.connect(continue_adventure)
	sel.online_pressed.connect(open_lobby)
	Sfx.music("menu")
	_swap(sel)


## Сетевая игра: лобби (создать игру или подключиться).
func open_lobby() -> void:
	classes = GameData.load_classes()
	profile = Profile.load_or_new(classes)
	var lobby: Control = LobbyUI.new()
	lobby.setup(classes, profile)
	lobby.back_pressed.connect(func() -> void:
		NetSession.get_session().leave()
		_hide_chat()
		new_adventure())
	Sfx.music("menu")
	_hide_chat()  # в лобби свой чат, встроенный в экран
	_swap(lobby)


## Хозяин начал сетевую игру: у всех одно «зерно» и один отряд.
func _on_net_started(setup: Dictionary) -> void:
	classes = GameData.load_classes()
	profile = Profile.load_or_new(classes)
	adventure = Adventure.new(setup.party, int(setup.seed), "act1", setup.unlocked)
	adventure.owners = setup.owners
	_run_achievements.clear()
	_pending_notices.clear()
	_show_battle()
	_show_chat()


## Действие из сети (или сразу, без сети): общее — здесь, остальное — текущему экрану.
func _on_command(cmd: Dictionary) -> void:
	match String(cmd.get("t", "")):
		"map":
			if screen.get_script() == MapUI and adventure.choose(int(cmd.id)):
				Sfx.play("map_step")
				_show_battle()
		"camp_continue":
			if screen.get_script() == CampUI and adventure.all_resolved():
				_after_camp()
		"reassign":
			if adventure:
				adventure.reassign(int(cmd.peer))
				if screen.has_method("_refresh"):
					screen._refresh()
		_:
			if screen and screen.has_method("apply_cmd"):
				screen.apply_cmd(cmd)


## Решения за весь отряд (путь на карте, «Дальше» на привале, трофей) в сети принимает хозяин.
func _leader() -> bool:
	return not NetSession.online() or NetSession.get_session().is_host


func _show_chat() -> void:
	if not NetSession.online():
		return
	if _chat == null:
		_chat = ChatOverlay.new()
		add_child(_chat)


func _hide_chat() -> void:
	if _chat:
		_chat.queue_free()
		_chat = null


func start_adventure(party: Array) -> void:
	adventure = Adventure.new(party, 0, "act1", profile.unlocked)
	_run_achievements.clear()
	_pending_notices.clear()
	_show_battle()


## Продолжить сохранённое приключение с того экрана, где из него вышли.
func continue_adventure() -> void:
	var data := SaveGame.read()
	if data.is_empty():
		SaveGame.clear()
		new_adventure()
		return
	adventure = data.adventure
	_run_achievements.assign(adventure.earned)
	var extra: Dictionary = data.extra
	match String(data.screen):
		"camp":
			_open_camp(_rest_from(extra.get("rest", [])), [], Array(extra.get("notices", [])))
		"map":
			_show_map()
		"trophy":
			_show_trophy(bool(extra.get("was_last", false)), [])
		_:
			_show_battle()


func _show_battle() -> void:
	SaveGame.write(adventure, "battle")
	var b: Control = BattleUI.new()
	b.fast = fast
	b.setup(adventure)
	b.finished.connect(_on_battle_finished)
	Sfx.music("boss" if adventure.is_last_level() else "battle")
	_swap(b)


func _on_battle_finished(outcome: String) -> void:
	var combat: Combat = screen.combat
	var was_last := adventure.is_last_level()
	var torn := adventure.finish_combat(combat)
	_record_achievements()
	if outcome != "victory":
		_show_end(false)
		return
	if adventure.trophy_boss != "":
		_show_trophy(was_last, torn)
		return
	_after_trophy(was_last, torn)


func _show_trophy(was_last: bool, torn: Array) -> void:
	SaveGame.write(adventure, "trophy", {"was_last": was_last})
	var t: Control = TrophyUI.new()
	t.setup(adventure)
	t.done.connect(func() -> void: _after_trophy(was_last, torn))
	_swap(t)


func _after_trophy(was_last: bool, torn: Array) -> void:
	if was_last:
		_show_end(true)
		return
	var rest := adventure.rest()
	adventure.roll_loot()
	var notices := _pending_notices.duplicate()
	_pending_notices.clear()
	_open_camp(rest, torn, notices)


func _open_camp(rest: Array, torn: Array, notices: Array) -> void:
	# Отчёт об отдыхе хранится с номерами волшебников вместо ссылок.
	var rest_saved := []
	for r in rest:
		var copy: Dictionary = r.duplicate()
		copy.wizard = adventure.wizards.find(r.wizard)
		rest_saved.append(copy)
	SaveGame.write(adventure, "camp", {"rest": rest_saved, "notices": notices})
	var camp: Control = CampUI.new()
	camp.setup(adventure, rest, torn)
	camp.notices.assign(notices)
	camp.continue_pressed.connect(func() -> void:
		if NetSession.online():
			if _leader():
				NetSession.get_session().submit({"t": "camp_continue"})
		else:
			_after_camp())
	Sfx.music("camp")
	_swap(camp)


func _rest_from(saved: Array) -> Array:
	var out := []
	for r in saved:
		var copy: Dictionary = r.duplicate()
		var i := int(copy.wizard)
		if i < 0 or i >= adventure.wizards.size():
			continue
		copy.wizard = adventure.wizards[i]
		out.append(copy)
	return out


## Достижения сразу записываются в профиль — даже если приключение не закончат.
func _record_achievements() -> void:
	var db: Dictionary = GameData.load_json("res://data/achievements.json")
	for id in adventure.take_fresh_achievements():
		profile.achievements[id] = true
		_run_achievements.append(id)
		var a: Dictionary = db.get(id, {"name": id, "class": ""})
		var cls: String = classes.get(a.get("class", ""), {}).get("name", "")
		_pending_notices.append("Достижение «%s»!%s" % [a.name,
			" Класс «%s» откроется после приключения." % cls if cls != "" else ""])
	profile.save()


func _after_camp() -> void:
	if adventure.needs_choice():
		_show_map()
	else:
		_show_battle()


## Карта: выбор одной из двух следующих локаций.
func _show_map() -> void:
	SaveGame.write(adventure, "map")
	Sfx.music("map")
	var m: Control = MapUI.new()
	m.setup(adventure)
	m.chosen.connect(func(id: int) -> void:
		if NetSession.online():
			if _leader():
				NetSession.get_session().submit({"t": "map", "id": id})
		elif adventure.choose(id):
			Sfx.play("map_step")
			_show_battle())
	_swap(m)


func _show_end(victory: bool) -> void:
	if adventure.owners.is_empty():
		SaveGame.clear()  # одиночное сохранение; сетевая игра его не трогает
	var fresh := profile.record_run(victory, classes)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := Art.background("bg_camp" if victory else "bg_battle_act1", 0.6)
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(bg)
	holder.add_child(c)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	c.add_child(box)
	var art := Art.texture("res://assets/ui/%s.png" % ("art_victory" if victory else "art_defeat"))
	if art:
		var pic := TextureRect.new()
		pic.texture = art
		pic.custom_minimum_size = Vector2(220, 220)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		box.add_child(pic)
	var title := Label.new()
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 8)
	title.text = "Акт I пройден! %s повержен." % adventure.boss_name() if victory \
		else "Поражение на уровне %d. Старики отправились на пенсию окончательно." % adventure.level
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(_run_stats_panel())
	var db: Dictionary = GameData.load_json("res://data/achievements.json")
	for id in _run_achievements:
		var got := Label.new()
		got.text = "Достижение «%s»" % db.get(id, {"name": id}).name
		got.add_theme_font_size_override("font_size", 18)
		got.add_theme_color_override("font_color", Color("ffe9a8"))
		got.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(got)
	_run_achievements.clear()
	for cid in fresh:
		var unlocked := Label.new()
		unlocked.text = "Открыт новый класс: %s!" % classes[cid].name
		unlocked.add_theme_font_size_override("font_size", 22)
		unlocked.add_theme_color_override("font_color", Color("ffd35a"))
		unlocked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(unlocked)
	var again := Button.new()
	again.text = "Новое приключение"
	again.custom_minimum_size = Vector2(260, 52)
	again.add_theme_font_size_override("font_size", 18)
	if NetSession.online():
		again.text = "В лобби"
		again.pressed.connect(func() -> void:
			NetSession.get_session().back_to_lobby()
			open_lobby())
	else:
		again.pressed.connect(new_adventure)
	box.add_child(again)
	holder.set_meta("victory", victory)
	_swap(holder)


## Итоги забега: таблица по волшебникам, «награды» и самый громкий хаос.
func _run_stats_panel() -> Control:
	var rs: Dictionary = adventure.run_stats
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.1, 0.9)
	sb.border_color = Color("ffd35a")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var head := Label.new()
	head.text = "Итоги забега · боёв: %d · врагов повержено: %d" % [int(rs.battles), int(rs.kills)]
	head.add_theme_font_size_override("font_size", 18)
	col.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 3)
	col.add_child(grid)
	for h in ["Волшебник", "Кастов", "Урон врагам", "Лечение", "По своим", "Выбывал"]:
		var l := Label.new()
		l.text = h
		l.add_theme_font_size_override("font_size", 13)
		l.modulate = Color(1, 1, 1, 0.65)
		grid.add_child(l)
	var best := {"dmg": [-1.0, ""], "heal": [-1.0, ""], "friendly": [0.0, ""]}
	for i in mini(adventure.wizards.size(), rs.wizards.size()):
		var w := adventure.wizards[i]
		var st: Dictionary = rs.wizards[i]
		for v in [w.name, str(int(st.casts)), Unit._num(float(st.dmg)), Unit._num(float(st.heal)),
				Unit._num(float(st.friendly)), str(int(st.downs))]:
			var l := Label.new()
			l.text = v
			l.add_theme_font_size_override("font_size", 15)
			grid.add_child(l)
		for k in best:
			if float(st[k]) > float(best[k][0]):
				best[k] = [float(st[k]), w.name]
	var lines: Array[String] = []
	if best.dmg[1] != "":
		lines.append("Главный по урону — %s (%s)." % [best.dmg[1], Unit._num(best.dmg[0])])
	if best.heal[0] > 0.0:
		lines.append("Лекарь отряда — %s (%s)." % [best.heal[1], Unit._num(best.heal[0])])
	if best.friendly[0] > 0.0:
		lines.append("«Я целился не в тебя!» — %s: %s урона по своим." % [best.friendly[1], Unit._num(best.friendly[0])])
	var loud: Dictionary = {}
	for m in rs.chaos:
		if loud.is_empty() or int(m.rank) >= int(loud.rank):
			loud = m
	if not loud.is_empty():
		lines.append("Самый громкий хаос: «%s» (Хаос %s) — %s." % [loud.name, "III" if int(loud.rank) == 3 else "II", loud.caster])
	for t in lines:
		var l := Label.new()
		l.text = t
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", Color("ffe9a8"))
		col.add_child(l)
	return panel


func _swap(next: Control) -> void:
	if screen:
		screen.queue_free()
	screen = next
	add_child(next)
	next.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
