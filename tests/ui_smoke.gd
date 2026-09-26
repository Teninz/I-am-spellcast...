extends SceneTree
## Дымовой тест интерфейса: играет бой кликами за игрока, без окна.
##   godot --headless --path . --script res://tests/ui_smoke.gd

var ui: Node
var frames := 0
var battles := 0
var wins := 0


func _initialize() -> void:
	ui = load("res://scenes/main.tscn").instantiate()
	ui.fast = true
	root.add_child(ui)


func _process(_delta: float) -> bool:
	frames += 1
	if frames > 20000:
		print("FAIL: бой не закончился за 20000 кадров")
		quit(1)
		return true
	match ui.state:
		ui.State.CHOOSE_TARGET:
			var targets: Array = ui.combat.valid_targets(ui.actor)
			var pick = targets.filter(func(u): return u.side != ui.actor.side and u.alive())
			ui._on_card_pressed(pick[0] if not pick.is_empty() else targets[0])
		ui.State.DRAWING:
			ui._on_draw_pressed()
		ui.State.READY:
			if ui.actor.ability == "burn" and ui.actor.ability_charges > 0 and ui.bag.chips.has("X"):
				ui._on_chip_pressed(ui.bag.chips.find("X"))
			ui._on_cast_pressed()
		ui.State.OVER:
			battles += 1
			if ui.combat.outcome == "victory":
				wins += 1
			if battles >= 5:
				print("ok: интерфейс доиграл %d боёв, побед: %d" % [battles, wins])
				quit(0)
				return true
			ui.start_battle()
	return false
