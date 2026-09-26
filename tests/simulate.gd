extends SceneTree
## Симулятор боёв для балансировки:
##   godot --headless --path . --script res://tests/simulate.gd -- encounter=rat_pack n=5000
## Параметры: encounter (id из data/encounters), n (число боёв),
##            party (классы через запятую, по умолчанию pyromancer,priest,water).


func _initialize() -> void:
	var args := {"encounter": "rat_pack", "n": "3000", "party": "pyromancer,priest,water"}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var encounter := GameData.load_encounter(args.encounter)
	var party := Array(args.party.split(","))
	var n := int(args.n)
	var stats := run(encounter, party, n)
	print("Бой: %s · отряд: %s · боёв: %d" % [encounter.get("name", args.encounter), ", ".join(party), n])
	print("  побед: %.1f %%" % stats.win_rate)
	print("  раундов в бою (в среднем): %.1f" % stats.rounds)
	print("  урон по отряду за раунд: %.2f" % stats.damage_per_round)
	print("  ЗД отряда после победы: %.1f из %.0f" % [stats.hp_left, stats.party_hp])
	print("  хотя бы один волшебник выбыл: %.1f %% побед" % stats.lost_wizard)
	quit()


static func run(encounter: Dictionary, party: Array, n: int) -> Dictionary:
	var adv := Adventure.new(party, 1)
	var wins := 0
	var rounds := 0.0
	var dmg := 0.0
	var hp_left := 0.0
	var lost := 0
	var party_hp := 0.0
	for w in adv.wizards:
		party_hp += w.max_hp()
	for i in n:
		var fresh: Array[Wizard] = []
		for cid in party:
			fresh.append(Wizard.new(cid, adv.classes[cid], adv.equipment))
		var c := Combat.new(adv.books, fresh, encounter, i + 1, adv.items)
		var result := AutoPlayer.play(c)
		var r := float(c.turn_count) / c.units.size()
		rounds += r
		var hp_now := 0.0
		for u in c.units:
			if u.is_wizard():
				hp_now += u.hp
		dmg += (party_hp - hp_now) / maxf(1.0, r)
		if result == "victory":
			wins += 1
			hp_left += hp_now
			if c.living(Unit.PARTY).size() < party.size():
				lost += 1
	return {
		"win_rate": 100.0 * wins / n,
		"rounds": rounds / n,
		"damage_per_round": dmg / n,
		"hp_left": hp_left / maxi(1, wins),
		"party_hp": party_hp,
		"lost_wizard": 100.0 * lost / maxi(1, wins),
	}
