extends SceneTree
## Сравнение отрядов 3 и 4 волшебников: каждый бой акта I и весь акт.
##   godot --headless --path . --script res://tests/simulate_party.gd -- n=1500 act=500

const PARTY3 := ["pyromancer", "priest", "water"]
const PARTY4 := ["pyromancer", "priest", "water", "magus"]
const FIGHTS := ["rat_pack", "goblin_gang", "bandits", "kobold_crew", "geese_gang", "rat_king"]


func _initialize() -> void:
	var n := 1500
	var act_n := 500
	for a in OS.get_cmdline_user_args():
		if a.begins_with("n="):
			n = int(a.substr(2))
		if a.begins_with("act="):
			act_n = int(a.substr(4))
	var sim = load("res://tests/simulate.gd")
	var cfg: Dictionary = GameData.load_json("res://data/adventure/act1.json")
	print("Бой                    | 3 волшебника       | 4 волшебника (с усилением врагов)")
	for f in FIGHTS:
		var enc := GameData.load_encounter(f)
		var s3: Dictionary = sim.run(Adventure.scale_encounter(enc, 3, cfg), PARTY3, n)
		var s4: Dictionary = sim.run(Adventure.scale_encounter(enc, 4, cfg), PARTY4, n)
		print("%-22s | %5.1f %% · урон %.2f | %5.1f %% · урон %.2f" % [enc.name, s3.win_rate, s3.damage_per_round, s4.win_rate, s4.damage_per_round])
	var act = load("res://tests/simulate_act.gd")
	var a3: Dictionary = act.run(act_n, PARTY3)
	var a4: Dictionary = act.run(act_n, PARTY4)
	print("Акт I целиком: 3 волшебника %.1f %% · 4 волшебника %.1f %%" % [a3.win_rate, a4.win_rate])
	print("  по уровням (3): %s" % a3.level_win_rates)
	print("  по уровням (4): %s" % a4.level_win_rates)
	quit()
