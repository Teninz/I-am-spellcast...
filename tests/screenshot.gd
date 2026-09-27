extends SceneTree
## Снимки экранов (нужен дисплей, например xvfb-run):
##   godot --path . --script res://tests/screenshot.gd -- out=/tmp/shots
## Сохраняет camp.png (первый привал), map.png и map_hover.png (развилка), battle.png (середина 2-го боя) и info.png (окно «Инфо»).

const BattleUI := preload("res://scripts/ui/battle_ui.gd")
const CampUI := preload("res://scripts/ui/camp_ui.gd")
const PartySelectUI := preload("res://scripts/ui/party_select_ui.gd")
const MapUI := preload("res://scripts/ui/map_ui.gd")

var game: Node
var out := "user://"
var busy := false
var camp_shot := false
var select_shot := false
var map_shot := false
var casts_in_second := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	Profile.path = "user://test_profile.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Profile.path))
	Settings.path = "user://test_ui_settings.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	SaveGame.path = "user://test_shot_adventure.json"
	SaveGame.clear()
	game = load("res://scenes/main.tscn").instantiate()
	game.fast = true
	root.add_child(game)


func _process(_delta: float) -> bool:
	if busy:
		return false
	var s: Node = game.screen
	if s == null or not is_instance_valid(s):
		return false
	if s.get_script() == CampUI and not camp_shot:
		camp_shot = true
		busy = true
		_shot("camp.png", func() -> void:
			var w: Wizard = game.adventure.wizards[0]
			s._open_book(w.books[0])
			_shot("camp_book.png", func() -> void:
				for c in s.get_children():
					if c is BookView:
						c.queue_free()
				AutoPlayer.camp(game.adventure)
				s._continue.pressed.emit()
				busy = false))
		return false
	if s.get_script() == PartySelectUI:
		if not select_shot:
			select_shot = true
			busy = true
			_shot("select.png", func() -> void:
				s.start_pressed.emit(["pyromancer", "priest", "water", "magus"])
				busy = false)
		else:
			s.start_pressed.emit(["pyromancer", "priest", "water", "magus"])
		return false
	if s.get_script() == MapUI:
		var first: int = game.adventure.choices()[0].id
		if map_shot:
			s._on_node_clicked(first)
			return false
		map_shot = true
		busy = true
		_shot("map.png", func() -> void:
			s._view.set_hover(first)
			_shot("map_hover.png", func() -> void:
				busy = false
				s._on_node_clicked(first)))
		return false
	if s.get_script() == BattleUI:
		_play(s)
	elif s.get_script() != CampUI:
		game.new_adventure()  # проиграли первый бой — начнём заново
	return false


func _play(ui: Node) -> void:
	match ui.state:
		ui.State.CHOOSE_TARGET:
			var t: Array = ui.combat.valid_targets(ui.actor).filter(
				func(u): return u.side != ui.actor.side and u.alive())
			ui._on_card_pressed(t[0] if not t.is_empty() else ui.actor)
		ui.State.ABILITY_TARGET:
			ui._on_card_pressed(ui._ability_targets()[0])
		ui.State.CHOOSE_BOOK:
			ui._select_book(ui.actor.books[0])
		ui.State.DRAWING:
			ui._on_draw_pressed()
		ui.State.READY:
			if camp_shot:
				casts_in_second += 1
				if casts_in_second == 5:
					busy = true
					ui.fast = false
					# Призванные существа на поле — посмотреть их портреты в кольцах.
					ui.combat.summon("bear", ui.actor, Unit.PARTY)
					ui.combat.summon("skeleton", ui.actor, Unit.PARTY)
					ui._refresh()
					ui._build_tutorial()
					ui._tutorial_step()
					_shot("battle.png", func() -> void:
						ui._open_picker()
						_shot("picker.png", func() -> void: ui._close_picker())
						await create_timer(0.6).timeout
						ui._tutorial.queue_free()
						ui._tutorial = null
						ui._stop_pulse()
						var card := StatusIcon.big_card("aching", "7", "")
						card.top_level = true
						ui.add_child(card)
						card.position = Vector2(420, 430)
						_shot("card.png", func() -> void:
							card.queue_free()
							# Демонстрация: предпросмотр эффектов и «штамп» в полёте.
							ui._show_effects(ui.combat.spell_for("pact", "DDT"))
							ui._stamp(ui.combat.living(Unit.ENEMIES)[0], "burn")
							_shot("stamp.png", func() -> void:
								ui._log.key_only = true
								ui._log._sync_buttons()
								ui._log._render()
								_shot("log_key.png", func() -> void:
									StatusInfo.open(ui)
									_shot("info.png", func() -> void:
										for c in ui.get_children():
											if c is StatusInfo:
												c.queue_free()
										# Книга с Благословением: 10 % вложено в «Огненный шар» и тип «Контроль».
										var plan := {Luck.spell_key("FFF"): 6, Luck.cat_key("control"): 4}
										BookView.open(ui, ui.books["fire"], ChipBag.odds(ui.books["fire"].bag), true, plan,
											"Кастовать из этой книги")
										_shot("book.png", func() -> void:
											# Экран трофея: как после победы над Гусём-Патриархом, Водник выбывал.
											game.adventure.trophy_boss = "goose_patriarch"
											game.adventure.last_scars = [{"wizard": game.adventure.wizards[2], "boss": "goose_patriarch"}]
											game._show_trophy(false, [])
											_shot("trophy.png", func() -> void:
												game.new_adventure()
												_shot("select_continue.png", func() -> void:
													SettingsView.open(game.screen)
													_shot("settings.png", func() -> void:
														for sv in game.screen.get_children():
															if sv is SettingsView:
																sv.queue_free()
														game._show_end(true)
														_shot("end.png", func() -> void: quit()))))))), 0.25)))
					return
			ui._on_cast_pressed()


func _shot(file: String, then: Callable, delay: float = 0.0) -> void:
	if delay > 0.0:
		await create_timer(delay).timeout
	for i in 12:
		await process_frame
	root.get_texture().get_image().save_png(out.path_join(file))
	print("saved ", out.path_join(file))
	then.call()
