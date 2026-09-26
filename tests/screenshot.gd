extends SceneTree
## Снимок экрана боя в середине хода (нужен дисплей, например xvfb-run):
##   godot --path . --script res://tests/screenshot.gd -- out=/tmp/battle.png

var ui: Node
var frames := 0
var casts := 0
var out := "user://battle.png"
var capturing := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	ui = load("res://scenes/main.tscn").instantiate()
	ui.fast = true
	root.add_child(ui)


func _process(_delta: float) -> bool:
	frames += 1
	if capturing:
		return false
	match ui.state:
		ui.State.CHOOSE_TARGET:
			if casts >= 4:
				var enemies: Array = ui.combat.valid_targets(ui.actor).filter(
					func(u): return u.side != ui.actor.side and u.alive())
				ui._on_card_pressed(enemies[-1])
			else:
				var t: Array = ui.combat.valid_targets(ui.actor).filter(
					func(u): return u.side != ui.actor.side and u.alive())
				ui._on_card_pressed(t[0])
		ui.State.DRAWING:
			ui._on_draw_pressed()
		ui.State.READY:
			if casts >= 4:
				capturing = true
				_capture()
				return false
			ui._on_cast_pressed()
			casts += 1
	return false


func _capture() -> void:
	for i in 10:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("saved ", out)
	quit()
