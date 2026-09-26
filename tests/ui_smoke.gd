extends SceneTree
## Дымовой тест интерфейса: играет приключения кликами за игрока, без окна.
##   godot --headless --path . --script res://tests/ui_smoke.gd

const BattleUI := preload("res://scripts/ui/battle_ui.gd")
const CampUI := preload("res://scripts/ui/camp_ui.gd")

var game: Node
var frames := 0
var runs := 0
var wins := 0
var camps := 0
var items_used := 0
var last_screen: Node = null


func _initialize() -> void:
	OS.low_processor_usage_mode = false
	Engine.max_fps = 0
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
	if s.get_script() == BattleUI:
		_play_battle(s)
	elif s.get_script() == CampUI:
		if s != last_screen:
			last_screen = s
			camps += 1
			AutoPlayer.camp(game.adventure)
			s._rebuild()
			if not game.adventure.all_resolved():
				print("FAIL: автоигрок не разобрал лут")
				quit(1)
				return true
			s._continue.pressed.emit()
	elif s != last_screen:
		last_screen = s
		runs += 1
		if s.get_meta("victory", false):
			wins += 1
		if runs >= 6:
			print("ok: интерфейс доиграл %d приключений (актов пройдено: %d, привалов: %d, предметов в бою: %d)"
				% [runs, wins, camps, items_used])
			quit(0)
			return true
		game.new_adventure()
	return false


func _play_battle(ui: Node) -> void:
	match ui.state:
		ui.State.CHOOSE_TARGET:
			if ui.combat.can_use_item(ui.actor) and ui._item_button.visible:
				items_used += 1
				ui._on_item_pressed()
				return
			var targets: Array = ui.combat.valid_targets(ui.actor)
			var pick = targets.filter(func(u): return u.side != ui.actor.side and u.alive())
			ui._on_card_pressed(pick[0] if not pick.is_empty() else targets[0])
		ui.State.CHOOSE_BOOK:
			ui._select_book(AutoPlayer.choose_book(ui.actor))
		ui.State.ITEM_TARGET:
			var ts: Array = ui.combat.item_targets(ui.actor, ui.actor.wizard.item)
			ui._on_card_pressed(ts[0])
		ui.State.DRAWING:
			ui._on_draw_pressed()
		ui.State.READY:
			if ui.actor.ability == "burn" and ui.actor.ability_charges > 0 and ui.bag.chips.has("X"):
				ui._on_chip_pressed(ui.bag.chips.find("X"))
			ui._on_cast_pressed()
