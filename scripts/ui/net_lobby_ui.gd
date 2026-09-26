extends Control
## Лобби сетевой игры: имя, «Создать игру» или «Подключиться», список игроков,
## выбор своих волшебников, чат. Хозяин начинает, когда все выбрали.
##   2 игрока — по 2 волшебника, 3 или 4 игрока — по 1.

signal back_pressed

var classes: Dictionary
var profile: Profile
var _name: LineEdit
var _port: LineEdit
var _address: LineEdit
var _status: Label
var _players: VBoxContainer
var _picks_box: HFlowContainer
var _picks_hint: Label
var _start: Button
var _connect_row: Control
var _my_picks: Array = []


func setup(class_db: Dictionary, p: Profile) -> void:
	classes = class_db
	profile = p


func _ready() -> void:
	add_child(Art.background("bg_party_select", 0.6))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	var title := Label.new()
	title.text = "Игра по сети"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var back := Button.new()
	back.text = "Назад"
	back.pressed.connect(func() -> void: back_pressed.emit())
	head.add_child(back)

	_connect_row = VBoxContainer.new()
	_connect_row.add_theme_constant_override("separation", 8)
	col.add_child(_connect_row)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	_connect_row.add_child(name_row)
	name_row.add_child(_caption("Твоё имя:"))
	_name = LineEdit.new()
	_name.text = String(Settings.value("player_name"))
	_name.custom_minimum_size = Vector2(220, 0)
	_name.max_length = 24
	name_row.add_child(_name)

	var host_row := HBoxContainer.new()
	host_row.add_theme_constant_override("separation", 8)
	_connect_row.add_child(host_row)
	host_row.add_child(_caption("Порт:"))
	_port = LineEdit.new()
	_port.text = str(NetSession.DEFAULT_PORT)
	_port.custom_minimum_size = Vector2(90, 0)
	host_row.add_child(_port)
	var host := Button.new()
	host.text = "Создать игру"
	host.pressed.connect(_on_host)
	host_row.add_child(host)
	host_row.add_child(_caption("   или   "))
	_address = LineEdit.new()
	_address.placeholder_text = "адрес хозяина, например 93.184.216.34:7777"
	_address.custom_minimum_size = Vector2(330, 0)
	host_row.add_child(_address)
	var join := Button.new()
	join.text = "Подключиться"
	join.pressed.connect(_on_join)
	host_row.add_child(join)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	_status.add_theme_color_override("font_color", Color("ffe19a"))
	col.add_child(_status)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)
	left.add_child(_caption("Игроки"))
	_players = VBoxContainer.new()
	left.add_child(_players)
	_picks_hint = _caption("")
	_picks_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	left.add_child(_picks_hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_picks_box = HFlowContainer.new()
	_picks_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picks_box.add_theme_constant_override("h_separation", 8)
	_picks_box.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_picks_box)
	_start = Button.new()
	_start.text = "Начать приключение"
	_start.custom_minimum_size = Vector2(0, 48)
	_start.pressed.connect(func() -> void: NetSession.get_session().start_game(profile.unlocked))
	left.add_child(_start)

	var chat_holder := Control.new()
	chat_holder.custom_minimum_size = Vector2(420, 0)
	row.add_child(chat_holder)
	var chat := ChatOverlay.new()
	add_child(chat)
	chat.dock_into(chat_holder)

	var net := NetSession.get_session()
	net.roster_changed.connect(_refresh)
	net.status.connect(func(t: String) -> void: _status.text = t)
	_refresh()


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _on_host() -> void:
	Settings.set_value("player_name", _name.text)
	var err := NetSession.get_session().host_game(int(_port.text), _name.text.strip_edges())
	if err != "":
		_status.text = err


func _on_join() -> void:
	Settings.set_value("player_name", _name.text)
	var err := NetSession.get_session().join_game(_address.text, _name.text.strip_edges())
	if err != "":
		_status.text = err


func _refresh() -> void:
	var net := NetSession.get_session()
	var in_session := NetSession.online()
	_connect_row.visible = not in_session
	for c in _players.get_children():
		c.queue_free()
	var ids := net.players.keys()
	ids.sort()
	var taken := {}
	for id in ids:
		var p: Dictionary = net.players[id]
		var names: Array = p.picks.map(func(c: String) -> String: return classes.get(c, {}).get("name", c))
		var l := Label.new()
		l.text = "%s%s%s — %s" % [p.name, " (хозяин)" if int(id) == 1 else "", " (ты)" if int(id) == NetSession.my_id() else "",
			", ".join(names) if not names.is_empty() else "выбирает…"]
		_players.add_child(l)
		if int(id) != NetSession.my_id():
			for c in p.picks:
				taken[c] = true
		else:
			_my_picks = p.picks.duplicate()
	var need := net.picks_per_player()
	_picks_hint.text = "" if not in_session else (
		"Ждём других игроков: вдвоём — по 2 волшебника, втроём или вчетвером — по 1." if net.players.size() < 2
		else "Выбери %s (классы в отряде не повторяются):" % ("2 волшебников" if need == 2 else "1 волшебника"))
	for c in _picks_box.get_children():
		c.queue_free()
	if in_session and net.players.size() >= 2:
		for cid in profile.unlocked:
			_picks_box.add_child(_pick_button(cid, taken.has(cid), need))
	_start.visible = in_session and net.is_host
	_start.disabled = not net.can_start()
	_start.text = "Начать приключение" if net.can_start() else "Начать (ждём выбора волшебников)"


func _pick_button(cid: String, taken: bool, need: int) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = _my_picks.has(cid)
	b.disabled = taken
	b.text = classes[cid].name + (" (занят)" if taken else "")
	b.icon = Art.wizard_face(cid)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 40)
	b.custom_minimum_size = Vector2(0, 52)
	b.pressed.connect(func() -> void:
		var picks := _my_picks.duplicate()
		if picks.has(cid):
			picks.erase(cid)
		else:
			picks.append(cid)
			while picks.size() > need:
				picks.pop_front()
		NetSession.get_session().set_picks(picks))
	return b
