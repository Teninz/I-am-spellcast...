extends SceneTree
## Симуляция целого акта автоигроком (бои + привалы + лут):
##   godot --headless --path . --script res://tests/simulate_act.gd -- n=500


func _initialize() -> void:
	var n := 500
	for a in OS.get_cmdline_user_args():
		if a.begins_with("n="):
			n = int(a.substr(2))
	var s := run(n)
	print("Акт I, приключений: %d" % n)
	print("  акт пройден: %.1f %%" % s.win_rate)
	print("  поражения по уровням: %s" % s.defeats)
	print("  побед по уровням (из дошедших): %s" % s.level_win_rates)
	print("  ЗД отряда перед боссом (в среднем): %.1f" % s.hp_before_boss)
	quit()


static func run(n: int) -> Dictionary:
	var wins := 0
	var defeats := {}
	var reached := {}
	var won := {}
	var hp_before_boss := 0.0
	var boss_count := 0
	for i in n:
		var adv := Adventure.new(["pyromancer", "priest", "water"], i + 1)
		while true:
			var lvl := adv.level
			reached[lvl] = reached.get(lvl, 0) + 1
			if adv.is_last_level():
				boss_count += 1
				for w in adv.wizards:
					hp_before_boss += w.hp
			var c := adv.start_combat(i * 100 + lvl)
			var result := AutoPlayer.play(c)
			var last := adv.is_last_level()
			adv.finish_combat(c)
			if result != "victory":
				defeats[lvl] = defeats.get(lvl, 0) + 1
				break
			won[lvl] = won.get(lvl, 0) + 1
			if last:
				wins += 1
				break
			adv.rest()
			adv.roll_loot()
			AutoPlayer.camp(adv)
	var rates := {}
	for lvl in reached:
		rates[lvl] = "%.0f%%" % (100.0 * won.get(lvl, 0) / reached[lvl])
	return {
		"win_rate": 100.0 * wins / n,
		"defeats": defeats,
		"level_win_rates": rates,
		"hp_before_boss": hp_before_boss / maxi(1, boss_count),
	}
