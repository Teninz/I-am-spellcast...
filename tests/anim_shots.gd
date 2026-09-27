extends SceneTree
## Кадры анимаций боя (нужен дисплей): godot --path . --script res://tests/anim_shots.gd -- out=/tmp/anim
const BattleUI := preload("res://scripts/ui/battle_ui.gd")
const PartySelectUI := preload("res://scripts/ui/party_select_ui.gd")
var game: Node
var out := ""
var casts := 0
var busy := false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	Profile.path = "user://test_anim_profile.json"
	Settings.path = "user://test_anim_settings.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.load_from_disk()
	Settings.set_value("tutorial", false)
	SaveGame.path = "user://test_anim_save.json"
	game = load("res://scenes/main.tscn").instantiate()
	game.fast = true
	root.add_child(game)

func _process(_d: float) -> bool:
	if busy:
		return false
	var s: Node = game.screen
	if s == null:
		return false
	if s.get_script() == PartySelectUI:
		s.start_pressed.emit(["pyromancer", "necromancer", "water"])
		return false
	if s.get_script() != BattleUI:
		return false
	match s.state:
		s.State.CHOOSE_TARGET:
			var foes: Array = s.combat.valid_targets(s.actor).filter(func(u): return u.side != s.actor.side)
			s._on_card_pressed(foes[0] if not foes.is_empty() else s.actor)
		s.State.CHOOSE_BOOK:
			s._select_book(s.actor.books[0])
		s.State.DRAWING:
			if casts == 2 and s.bag.chips.is_empty():
				busy = true
				s.fast = false
				_draw_seq(s)
				return false
			s._on_draw_pressed()
		s.State.READY:
			casts += 1
			if casts == 3:
				busy = true
				s.fast = false
				s.combat.summon("bear", s.actor, Unit.PARTY)
				_seq(s)
				return false
			s._on_cast_pressed()
	return false

func _draw_seq(ui) -> void:
	ui._on_draw_pressed()
	for i in 4:
		await create_timer(0.07).timeout
		root.get_texture().get_image().save_png(out.path_join("draw_%d.png" % i))
	ui.fast = true
	busy = false

func _seq(ui) -> void:
	await create_timer(0.8).timeout
	root.get_texture().get_image().save_png(out.path_join("summon.png"))
	ui._on_cast_pressed()
	for i in 8:
		await create_timer(0.08).timeout
		root.get_texture().get_image().save_png(out.path_join("cast_%d.png" % i))
	quit()
