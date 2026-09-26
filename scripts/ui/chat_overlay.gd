class_name ChatOverlay
extends CanvasLayer
## Чат сетевой игры поверх любого экрана: кнопка «Чат» вверху по центру, окно с сообщениями,
## выбор «Всем» или шёпот одному игроку. Enter — отправить.

var _toggle: Button
var _panel: PanelContainer
var _log: RichTextLabel
var _input: LineEdit
var _to: OptionButton
var _unread := 0


func _ready() -> void:
	layer = 20
	var net := NetSession.get_session()
	net.chat_received.connect(_on_chat)
	net.roster_changed.connect(_fill_targets)

	_toggle = Button.new()
	_toggle.text = "Чат"
	_toggle.anchor_left = 0.5
	_toggle.anchor_right = 0.5
	_toggle.offset_left = -60
	_toggle.offset_right = 60
	_toggle.offset_top = 6
	_toggle.offset_bottom = 38
	_toggle.pressed.connect(func() -> void: _show(not _panel.visible))
	add_child(_toggle)

	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.07, 0.11, 0.95)
	box.border_color = Color("ffd35a")
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", box)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -260
	_panel.offset_right = 260
	_panel.offset_top = 42
	_panel.offset_bottom = 330
	_panel.visible = false
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_panel.add_child(col)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 14)
	col.add_child(_log)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	col.add_child(row)
	_to = OptionButton.new()
	_to.custom_minimum_size = Vector2(130, 0)
	row.add_child(_to)
	_input = LineEdit.new()
	_input.placeholder_text = "Сообщение…"
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.max_length = 300
	_input.text_submitted.connect(func(_t: String) -> void: _send())
	row.add_child(_input)
	var send := Button.new()
	send.text = "Отправить"
	send.pressed.connect(_send)
	row.add_child(send)
	_fill_targets()


## Встроить окно чата в экран (лобби), а не поверх.
func dock_into(parent: Control) -> void:
	_toggle.visible = false
	remove_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.visible = true
	parent.add_child(_panel)


func _show(on: bool) -> void:
	_panel.visible = on
	if on:
		_unread = 0
		_input.grab_focus()
	_update_toggle()


func _update_toggle() -> void:
	_toggle.text = "Чат" if _unread == 0 else "Чат (%d)" % _unread


func _fill_targets() -> void:
	if _to == null:
		return
	var net := NetSession.get_session()
	_to.clear()
	_to.add_item("Всем", 0)
	for id in net.players:
		if id != NetSession.my_id():
			_to.add_item("Шёпот: %s" % net.player_name(id), int(id))


func _send() -> void:
	var text := _input.text
	if text.strip_edges() == "":
		return
	NetSession.get_session().send_chat(text, _to.get_selected_id())
	_input.text = ""


func _on_chat(from_name: String, text: String, whisper_to: String) -> void:
	var safe := text.replace("[", "[lb]")
	if from_name == "":
		_log.append_text("[color=#9a9aa4][i]%s[/i][/color]\n" % safe)
	elif whisper_to != "":
		_log.append_text("[color=#d7a0ff]%s → %s (шёпот):[/color] %s\n" % [from_name, whisper_to, safe])
	else:
		_log.append_text("[color=#ffd35a]%s:[/color] %s\n" % [from_name, safe])
	if not _panel.visible:
		_unread += 1
		_update_toggle()
