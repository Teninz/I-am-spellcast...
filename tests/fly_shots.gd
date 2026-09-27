extends SceneTree
## Кадры полёта заклинаний (нужен дисплей): перенаправление, цепная молния, массовое.
##   godot --path . --script res://tests/fly_shots.gd -- out=/tmp/fly
const BattleUI := preload("res://scripts/ui/battle_ui.gd")
const PartySelectUI := preload("res://scripts/ui/party_select_ui.gd")
var game: Node
var out := ""
var busy := false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	Profile.path = "user://test_fly_profile.json"
	Settings.path = "user://test_fly_settings.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.load_from_disk()
	Settings.set_value("tutorial", false)
	SaveGame.path = "user://test_fly_save.json"
	game = load("res://scenes/main.tscn").instantiate()
	game.fast = true
	root.add_child(game)

func _process(_d: float) -> bool:
	if busy or game.screen == null:
		return false
	var s: Node = game.screen
	if s.get_script() == PartySelectUI:
		s.start_pressed.emit(["pyromancer", "necromancer", "water"])
	elif s.get_script() == BattleUI and s.state == s.State.CHOOSE_TARGET and s.actor.is_wizard():
		busy = true
		_run(s)
	return false

func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func _run(ui) -> void:
	ui.fast = false
	await create_timer(0.5).timeout
	var me: Unit = ui.actor
	var foes: Array = ui.combat.living(ui.combat.opposite(me.side))
	var a: Unit = foes[0]
	var b: Unit = foes[foes.size() - 1]
	# 1. Дурной знак: целились в первого врага, ушло в союзника.
	var ally: Unit = ui.combat.living(me.side)[1]
	ui._fly_spell([{"kind": "hit", "caster": me.id, "to": ally.id, "aimed": a.id, "turn": "mid"}], ["F", "F", "W"], "FFW")
	await create_timer(Fx.t(0.3)).timeout
	await _shot("1_mid_turn")
	await create_timer(Fx.t(0.25)).timeout
	await _shot("2_after_turn")
	await create_timer(1.0).timeout
	# 2. Цепная молния: удар по цели и ветки к остальным.
	var tr: Array = [{"kind": "hit", "caster": me.id, "to": a.id, "aimed": a.id, "turn": ""}]
	for f in foes.slice(1):
		tr.append({"kind": "jump", "from": a.id, "to": f.id})
	var land: float = ui._fly_spell(tr, ["L", "L", "W"], "LLW")
	await create_timer(Fx.t(0.08)).timeout
	await _shot("3_zap")
	await create_timer(land - Fx.t(0.08) + 0.02).timeout
	await _shot("4_chain")
	await create_timer(1.0).timeout
	# 3. Массовое: один шар до развилки, дальше врассыпную.
	var mass: Array = []
	for f in foes:
		mass.append({"kind": "hit", "caster": me.id, "to": f.id, "aimed": f.id, "turn": ""})
	ui._fly_spell(mass, ["F", "F", "F"], "FFF")
	await create_timer(Fx.t(0.3)).timeout
	await _shot("5_mass_fork")
	await create_timer(Fx.t(0.25)).timeout
	await _shot("6_mass_split")
	await create_timer(1.0).timeout
	# 4. Огненный шар (листы из Blender) и Шипящий залп.
	var fb: float = ui._fly_spell([{"kind": "hit", "caster": me.id, "to": a.id, "aimed": a.id, "turn": ""}], ["F", "F", "F"], "FFF", "fire")
	await create_timer(Fx.t(0.25)).timeout
	await _shot("8_fireball")
	await create_timer(fb - Fx.t(0.25) + Fx.t(0.12)).timeout
	await _shot("9_explosion")
	await create_timer(Fx.t(0.3)).timeout
	await _shot("10_explosion_late")
	await create_timer(1.2).timeout
	var vl: float = ui._fly_spell([{"kind": "hit", "caster": me.id, "to": b.id, "aimed": b.id, "turn": ""}], ["F", "F", "W"], "FFW", "fire")
	await create_timer(Fx.t(0.3)).timeout
	await _shot("11_volley")
	await create_timer(vl - Fx.t(0.3) + Fx.t(0.2)).timeout
	await _shot("12_steam")
	await create_timer(1.2).timeout
	# 5. Отражение.
	ui._fly_spell([{"kind": "hit", "caster": me.id, "to": me.id, "aimed": b.id, "turn": "bounce"}], ["F", "F", "W"], "FFW")
	await create_timer(Fx.t(0.5)).timeout
	await _shot("7_bounce")
	quit()
