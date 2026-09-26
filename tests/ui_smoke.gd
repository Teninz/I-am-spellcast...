extends SceneTree
## Дымовой тест интерфейса: играет приключения кликами за игрока, без окна.
##   godot --headless --path . --script res://tests/ui_smoke.gd

const BattleUI := preload("res://scripts/ui/battle_ui.gd")
const CampUI := preload("res://scripts/ui/camp_ui.gd")
const PartySelectUI := preload("res://scripts/ui/party_select_ui.gd")
const MapUI := preload("res://scripts/ui/map_ui.gd")
const TrophyUI := preload("res://scripts/ui/trophy_ui.gd")

var game: Node
var frames := 0
var runs := 0
var wins := 0
var camps := 0
var items_used := 0
var forks := 0
var books_opened := 0
var trophies := 0
var resumed := 0
var abilities_used := 0
var last_screen: Node = null


func _initialize() -> void:
	OS.low_processor_usage_mode = false
	Engine.max_fps = 0
	Profile.path = "user://test_profile.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Profile.path))
	Settings.path = "user://test_ui_settings.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	SaveGame.path = "user://test_smoke_adventure.json"
	SaveGame.clear()
	game = load("res://scenes/main.tscn").instantiate()
	game.fast = true
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if frames > 200000:
		print("FAIL: приключения не закончились за 200000 кадров")
		quit(1)
		return true
	var s: Node = game.screen
	if s == null or not is_instance_valid(s):
		return false
	if s.get_script() == PartySelectUI:
		if s != last_screen:
			last_screen = s
			# Чередуем отряды: 3 стартовых и 4 с Магусом (и Бардом, если открыт).
			# Каждый забег — новые классы: так в интерфейсе пробуются все способности.
			var all := ["druid", "necromancer", "scientist", "seer", "illusionist", "wild_mage",
				"warlock", "alchemist", "chronomancer", "oracle", "bard", "paladin"]
			var party := ["pyromancer", all[(runs * 2) % all.size()], all[(runs * 2 + 1) % all.size()]]
			if runs % 2 == 1:
				party.append("water")
			s.selected = party
			s.start_pressed.emit(party)
		return false
	if s.get_script() == BattleUI:
		_play_battle(s)
	elif s.get_script() == CampUI:
		if s != last_screen:
			last_screen = s
			camps += 1
			# Раз в несколько привалов «выходим из игры» и продолжаем с сохранения.
			if camps % 3 == 0 and s.get_meta("resumed", false) == false:
				var lvl: int = game.adventure.level
				game.new_adventure()
				if not SaveGame.exists():
					print("FAIL: нет сохранения на привале")
					quit(1)
					return true
				game.continue_adventure()
				if game.screen.get_script() != CampUI or game.adventure.level != lvl:
					print("FAIL: продолжение открыло не тот экран")
					quit(1)
					return true
				game.screen.set_meta("resumed", true)
				last_screen = game.screen
				resumed += 1
				s = game.screen
			AutoPlayer.camp(game.adventure)
			s._rebuild()
			if not game.adventure.all_resolved():
				print("FAIL: автоигрок не разобрал лут")
				quit(1)
				return true
			s._continue.pressed.emit()
	elif s.get_script() == TrophyUI:
		if s != last_screen:
			last_screen = s
			trophies += 1
			s._kind = "cursed" if trophies % 2 == 0 else "trophy"
			s._take.pressed.emit()
	elif s.get_script() == MapUI:
		if s != last_screen:
			last_screen = s
			forks += 1
			var ch: Array = game.adventure.choices()
			s._on_node_clicked(ch[forks % ch.size()].id)
	elif s != last_screen:
		last_screen = s
		runs += 1
		if s.get_meta("victory", false):
			wins += 1
		if runs >= 6:
			print("ok: интерфейс доиграл %d приключений (актов пройдено: %d, привалов: %d, развилок: %d, книг открыто: %d, трофеев: %d, продолжений с сохранения: %d, способностей: %d, предметов в бою: %d)"
				% [runs, wins, camps, forks, books_opened, trophies, resumed, abilities_used, items_used])
			quit(0)
			return true
		game.new_adventure()
	return false


func _play_battle(ui: Node) -> void:
	match ui.state:
		ui.State.REWIND:
			abilities_used += 1
			ui._on_rewind()
		ui.State.CHOOSE_TARGET:
			if ui._ability_button.visible:
				abilities_used += 1
				ui._on_ability_pressed()
				return
			if ui.combat.can_use_item(ui.actor) and ui._item_button.visible:
				items_used += 1
				ui._on_item_pressed()
				return
			var targets: Array = ui.combat.valid_targets(ui.actor)
			var pick = targets.filter(func(u): return u.side != ui.actor.side and u.alive())
			ui._on_card_pressed(pick[0] if not pick.is_empty() else targets[0])
		ui.State.CHOOSE_BOOK:
			# Через просмотр книги: вложить удачу (если есть Благословение) и кастовать кнопкой книги.
			var b := AutoPlayer.choose_book(ui.actor)
			ui.actor.add_status("bless", 2)
			ui._open_book(b, true)
			var view: BookView = null
			for c in ui.get_children():
				if c is BookView:
					view = c
			view._invest(Luck.cat_key(ui.books[b].spells[0].category), 3)
			books_opened += 1
			view.cast_pressed.emit(view.plan)
			view.queue_free()
		ui.State.ABILITY_TARGET:
			var ts: Array = ui._ability_targets()
			if ts.is_empty():
				ui._set_state(ui.State.CHOOSE_TARGET)
			else:
				ui._on_card_pressed(ts[0])
		ui.State.ITEM_TARGET:
			var ts: Array = ui.combat.item_targets(ui.actor, ui.actor.wizard.item)
			ui._on_card_pressed(ts[0])
		ui.State.DRAWING:
			if ui._ability_button.visible and ui.bag.chips.is_empty():
				abilities_used += 1
				ui._on_ability_pressed()  # Сделка: выбрать первую фишку
				var picks: Array = ui._extra_box.get_children().filter(func(b): return b is Button and b.text != "Отмена")
				if not picks.is_empty():
					picks[0].pressed.emit()
				return
			ui._on_draw_pressed()
		ui.State.READY:
			if ui._ability_button.visible and ui.actor.ability_charges > 0 and randf() < 0.5:
				abilities_used += 1
				ui._on_ability_pressed()  # Зов зверя, Всплеск
				return
			var visions: Array = ui._extra_box.get_children().filter(func(b): return b is Button)
			if not visions.is_empty() and randf() < 0.3:
				abilities_used += 1
				visions[0].pressed.emit()
				return
			if ui.combat.can_reroll(ui.actor) and ui.bag.chips.has("X"):
				ui._on_chip_pressed(ui.bag.chips.find("X"))
			ui._on_cast_pressed()
