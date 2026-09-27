extends SceneTree
## Тесты без окна:
##   godot --headless --path . --script res://tests/run_tests.gd
## Код выхода 0 — всё прошло, 1 — есть ошибки.

var failures := 0


func _initialize() -> void:
	var books := GameData.load_books()
	test_books_loaded(books)
	test_art_assets(books)
	test_chaos_odds(books)
	test_combo_odds(books)
	test_luck_scale(books)
	test_parser_coverage(books)
	test_chain_lightning()
	test_summons(books)
	test_every_spell_runs(books)
	test_pick_and_stats(books)
	test_rat_pack_simulation(books)
	test_rest_and_fortify()
	test_loot_rules()
	test_map()
	test_revive_after_battle()
	test_party_scaling()
	test_profile_unlocks()
	test_bard_and_paladin()
	test_dead_tongue_cost()
	test_bosses()
	test_trophies_and_scars()
	test_achievements()
	test_save_and_load()
	test_settings_and_sound()
	test_class_abilities()
	test_manual_draw_edge()
	test_act_simulation()
	print("")
	print("ИТОГО: %s" % ("все тесты прошли" if failures == 0 else "ошибок: %d" % failures))
	quit(1 if failures else 0)


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


func test_books_loaded(books: Dictionary) -> void:
	print("Книги:")
	check(books.size() >= 26, "загружено книг: %d" % books.size())
	for id in ["fire", "water", "holy"]:
		check(books.has(id) and books[id].spells.size() == 30, "%s: 30 заклинаний" % id)


## Картинки: у каждого эффекта, стихии, книги, предмета, вещи и элемента интерфейса есть файл,
## и Godot его загружает. Персонажи пока необязательны.
func test_art_assets(books: Dictionary) -> void:
	print("Картинки:")
	var groups := {}
	groups["эффекты"] = GameData.statuses().keys().map(func(id): return "res://assets/icons/status/%s.png" % id)
	var letters := {}
	for b in books.values():
		for k in b.bag:
			letters[k] = true
	groups["фишки"] = letters.keys().map(func(k): return "res://assets/chips/%s.png" % Art.CHIP_FILES[k]) \
		+ ["res://assets/chips/chip_back.png", "res://assets/chips/bag.png"]
	groups["книги"] = books.keys().map(func(id): return "res://assets/books/%s.png" % id)
	groups["предметы"] = GameData.load_json("res://data/items.json").keys().map(func(id): return "res://assets/items/%s.png" % id)
	groups["шляпы и ботинки"] = GameData.load_json("res://data/equipment.json").items.map(func(e): return "res://assets/equipment/%s.png" % e.id)
	var ui := ["bg_battle_act1", "bg_camp", "bg_party_select", "art_victory", "art_defeat", "emblem",
		"card_party", "card_enemy", "card_leader", "card_boss", "card_rest", "portrait_ring",
		"panel_dialog", "button", "button_cast", "chip_socket", "shout_banner", "hp_bar_frame",
		"stat_hp", "stat_speed", "stat_wisdom", "stat_defense", "stat_luck", "stat_resist"]
	for r in ["common", "rare", "epic", "legendary", "cursed"]:
		ui.append("loot_frame_" + r)
	groups["интерфейс"] = ui.map(func(n): return "res://assets/ui/%s.png" % n)
	var skill_files := []
	var skill_db: Dictionary = GameData.load_json("res://data/class_skills.json")
	for cid in skill_db:
		if skill_db[cid] is Array:
			for sk in skill_db[cid]:
				skill_files.append("res://assets/icons/skills/%s.png" % sk.id)
	groups["навыки"] = skill_files
	groups["призванные существа"] = GameData.creatures().values().map(func(c): return "res://assets/enemies/%s.png" % c.portrait)
	var encs := []
	for f in DirAccess.get_files_at("res://data/encounters"):
		if f.get_extension() == "json":
			encs.append("res://assets/ui/bg_battle_%s.png" % f.get_basename())
	groups["фоны локаций"] = encs + ["res://assets/ui/bg_map.png"]
	# Картинки, которые ещё только ждут генерации (игра рисует заглушку).
	var pending := []
	for g in groups:
		var missing: Array = groups[g].filter(func(p): return not ResourceLoader.exists(p) or load(p) == null)
		var waiting: Array = missing.filter(func(p): return pending.has(p.get_file()))
		missing = missing.filter(func(p): return not pending.has(p.get_file()))
		if not waiting.is_empty():
			print("       %s: ждут картинку — %s" % [g, ", ".join(PackedStringArray(waiting.map(func(p): return p.get_file())))])
		check(missing.is_empty(), "%s: %d из %d%s" % [g, groups[g].size() - missing.size() - waiting.size(), groups[g].size(),
			"" if missing.is_empty() else " — нет: " + ", ".join(PackedStringArray(missing.map(func(p): return p.get_file()))) ])
	var lost := []
	var total := 0
	for cid in GameData.load_classes():
		for st in ["healthy", "hurt", "critical", "zombie"]:
			total += 1
			if Art.portrait(cid, st) == null:
				lost.append("%s_%s" % [cid, st])
	check(lost.is_empty(), "персонажи: %d из %d%s" % [total - lost.size(), total,
		"" if lost.is_empty() else " — нет: " + ", ".join(PackedStringArray(lost))])
	# Портреты врагов акта I и кольца аватарок — ждут картинок (docs/art_prompts_enemies.md).
	var enemy_ids: Dictionary = GameData.load_json("res://data/enemy_portraits.json")
	var uniq := {}
	for n in enemy_ids:
		uniq[enemy_ids[n]] = true
	var have := uniq.keys().filter(func(id): return ResourceLoader.exists("res://assets/enemies/%s.png" % id)).size()
	var rings := ["wizard", "wizard_active", "wizard_critical", "wizard_zombie", "enemy", "enemy_leader", "enemy_boss", "enemy_summon"]
	var have_rings := rings.filter(func(r): return Art.ring(r) != null).size()
	check(have == uniq.size() and have_rings == rings.size(), "портреты врагов: %d из %d, кольца аватарок: %d из %d" % [have, uniq.size(), have_rings, rings.size()])
	var names_ok := true
	for f in DirAccess.get_files_at("res://data/encounters"):
		if f.ends_with(".json"):
			for m in GameData.load_json("res://data/encounters/" + f).members:
				if not enemy_ids.has(m.name):
					names_ok = false
					print("       нет id портрета: ", m.name)
	check(names_ok, "у каждого врага акта I есть id портрета")
	check(Art.portrait_state(9.0, 10.0) == "healthy" and Art.portrait_state(4.0, 10.0) == "hurt"
		and Art.portrait_state(3.0, 10.0) == "critical" and Art.portrait_state(9.0, 10.0, true) == "zombie",
		"портрет по здоровью: >1/2 здоров, от 1/3 ранен, <1/3 при смерти, зомби отдельно")


## Шансы Хаоса за каст должны совпадать с документацией (18.0 / 1.30 / 0.03 %).
func test_chaos_odds(books: Dictionary) -> void:
	print("Шансы Хаоса (200 000 кастов Книги Огня):")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var n := 200000
	var marks: Array[int] = [0, 0, 0, 0]
	for i in n:
		var bag := ChipBag.new(books.fire.bag)
		while not bag.is_complete():
			bag.draw(rng)
		marks[bag.chips.count(ChipBag.CHAOS)] += 1
	var x1: float = 100.0 * marks[1] / n
	var x2: float = 100.0 * marks[2] / n
	check(absf(x1 - 18.01) < 0.4, "Хаос I: %.2f %% (ожидается 18.01)" % x1)
	check(absf(x2 - 1.30) < 0.15, "Хаос II: %.2f %% (ожидается 1.30)" % x2)


## Фишки стихий не возвращаются: «три огня подряд» = 10/19 · 9/18 · 8/17 · (без Хаоса).
func test_combo_odds(books: Dictionary) -> void:
	print("Шанс «Огненного шара» (🔥🔥🔥):")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var n := 200000
	var hits := 0
	for i in n:
		var bag := ChipBag.new(books.fire.bag)
		while not bag.is_complete():
			bag.draw(rng)
		if bag.combo_key() == "FFF":
			hits += 1
	var expected := 100.0 * (10.0 / 19 * 9.0 / 18 * 8.0 / 17) * 0.95 * 0.931 * 0.912
	var got := 100.0 * hits / n
	check(absf(got - expected) < 0.4, "FFF: %.2f %% (ожидается %.2f)" % [got, expected])


## Каждое заклинание стартовых книг должно что-то делать в прототипе.
func test_luck_scale(books: Dictionary) -> void:
	print("Просмотр книги и шкала удачи:")
	var fire: Dictionary = books.fire
	var odds := ChipBag.odds(fire.bag)
	var total := 0.0
	for k in odds:
		total += odds[k]
	check(absf(total - 1.0) < 1e-9 and absf(odds.X1 * 100.0 - 18.01) < 0.1,
		"точные шансы: сумма 100 %%, Хаос I %.2f %% (как у симуляции)" % (odds.X1 * 100.0))
	var p: float = odds.FFF
	var plan := {Luck.spell_key("FFF"): 10}
	var now := Luck.shifted(fire, odds, plan)
	var sum_now := 0.0
	for k in now:
		sum_now += now[k]
	check(absf(now.FFF - (p + 0.1 * (1.0 - p))) < 1e-9 and absf(sum_now - 1.0) < 1e-9,
		"10 %% в «Огненный шар»: %.1f %% → %.1f %%, сумма по-прежнему 100 %%" % [p * 100.0, now.FFF * 100.0])
	var other: String = "FFW"
	check(absf(now[other] - odds[other] * 0.9) < 1e-9, "остальные шансы уменьшаются пропорционально (×0.9)")
	var cats := Luck.by_category(fire, odds)
	var cats_now := Luck.by_category(fire, Luck.shifted(fire, odds, {Luck.cat_key("damage"): 10}))
	check(absf(cats_now.damage - (cats.damage + 0.1 * (1.0 - cats.damage))) < 1e-9,
		"10 %% в тип «Урон»: %.0f %% → %.0f %%" % [cats.damage * 100.0, cats_now.damage * 100.0])
	var split := Luck.shifted(fire, odds, {Luck.spell_key("FFF"): 4, Luck.cat_key("control"): 6})
	check(absf(split.FFF - (0.9 * p + 0.04)) < 1e-9, "шкалу можно разделить: 4 % в заклинание и 6 % в тип")
	check(Luck.spent(Luck.clean(fire, odds, {Luck.spell_key("FFF"): 8, Luck.spell_key("FWF"): 8})) == 10,
		"больше 10 % вложить нельзя")
	# Сам бросок: с Благословением «Огненный шар» выпадает чаще, без — как обычно.
	var w := Wizard.new("pyromancer", GameData.load_classes().pyromancer, {})
	var c := Combat.new(books, [w], GameData.load_encounter("rat_pack"), 5, {})
	var u: Unit = c.living(Unit.PARTY)[0]
	var n := 20000
	var hits := [0, 0]
	for with_bless in [false, true]:
		if with_bless:
			u.add_status("bless", 99)
		for i in n:
			var bag := c.new_bag(u, "fire", plan)
			while not bag.is_complete():
				bag.draw(c.rng)
			if bag.combo_key() == "FFF":
				hits[int(with_bless)] += 1
	var base_rate: float = 100.0 * hits[0] / n
	var luck_rate: float = 100.0 * hits[1] / n
	check(absf(base_rate - p * 100.0) < 0.7, "без баффа удачи план не действует (%.1f %%)" % base_rate)
	check(absf(luck_rate - now.FFF * 100.0) < 0.8, "с Благословением «Огненный шар» выпадает в %.1f %% (ожидается %.1f %%)" % [luck_rate, now.FFF * 100.0])


func test_parser_coverage(books: Dictionary) -> void:
	print("Разбор заклинаний стартовых книг:")
	for id in ["fire", "water", "holy", "blade", "bard", "oath"]:
		var missing: Array[String] = []
		var partial: Array[String] = []
		for s in books[id].spells:
			var spec := EffectParser.parse(s)
			if not EffectParser.has_effect(spec):
				missing.append("%s «%s»" % [s.combo, s.name])
			elif not spec.unsupported.is_empty():
				partial.append("%s (%s)" % [s.name, ", ".join(PackedStringArray(spec.unsupported))])
		check(missing.is_empty(), "%s: все 30 заклинаний разобраны%s" % [id,
			"" if missing.is_empty() else " — нет эффекта у: " + ", ".join(PackedStringArray(missing))])
		if not partial.is_empty():
			print("       частично: ", ", ".join(PackedStringArray(partial)))


## Уровень 1 должен проходиться почти всегда.
func test_chain_lightning() -> void:
	print("Цепная молния:")
	var storm := EffectParser.parse({"effect": "3 урона цели и 1 урон двум случайным участникам на её стороне.", "damage": 3})
	check(storm.jumps.size() == 1 and storm.jumps[0].count == 2 and storm.jumps[0].damage == 1, "Книга Бурь: перескок 1 урона на двоих")
	var wild := EffectParser.parse({"effect": "2 урона цели, 1 урон всем на её стороне и 1 урон случайному союзнику кастующего.", "damage": 2})
	check(wild.splash == 1 and wild.jumps.size() == 1 and wild.jumps[0].side == "caster", "Дикая книга: добивка по всем и удар по своему")
	var mirror := EffectParser.parse({"effect": "7 урона цели и такой же урон случайному участнику на её стороне.", "damage": 7})
	check(mirror.area == "target" and mirror.jumps[0].damage == 7, "Зеркало: такой же урон перескакивает")
	var chaos := EffectParser.parse({"effect": "4 урона цели и 4 урона случайному участнику боя.", "damage": 4})
	check(chaos.area == "target" and chaos.jumps[0].side == "any", "Дикий хаос: бьёт цель и ещё кого-то")
	var adv := Adventure.new(["pyromancer", "priest"], 5)
	var c := adv.start_combat(5)
	var caster: Unit = c.units[0]
	var foes: Array[Unit] = c.living(c.opposite(caster.side))
	while foes.size() < 3:
		foes = c.living(c.opposite(caster.side))
		break
	var before := {}
	for u in foes:
		u.shield = 0
		before[u] = u.hp
	var chips: Array[String] = ["W", "L", "L"]
	c._apply_spell(caster, foes[0], c.spell_for("storm", "WLL"), chips, "storm")
	var hit_others := 0
	for u in foes:
		if u != foes[0] and (u.hp < before[u] or not u.alive()):
			hit_others += 1
	check(foes[0].hp < before[foes[0]] and hit_others == mini(2, foes.size() - 1), "урон перескочил на %d соседей цели" % hit_others)


func test_summons(books: Dictionary) -> void:
	print("Призыв существ:")
	var missing: Array[String] = []
	for id in ["bestiary", "necronomicon", "druid"]:
		for sp in books[id].spells:
			if String(sp.effect).contains("Призывает") and EffectParser.parse(sp).summon.is_empty():
				missing.append(sp.name)
	check(missing.is_empty(), "все «Призывает…» разобраны%s" % ("" if missing.is_empty() else ": " + ", ".join(PackedStringArray(missing))))
	var adv := Adventure.new(["pyromancer", "priest"], 9)
	var c := adv.start_combat(9)
	var caster: Unit = c.units[0]
	var foe: Unit = c.living(Unit.ENEMIES)[0]
	var chips: Array[String] = ["D", "W", "F"]
	var before := c.units.size()
	c._apply_spell(caster, foe, c.spell_for("necronomicon", "DWF"), chips, "necronomicon")
	var sk: Unit = c.units[c.units.size() - 1]
	check(c.units.size() == before + 1 and sk.creature and sk.side == Unit.PARTY and not sk.is_wizard(), "Подъём скелета: скелет на стороне отряда")
	check(int(sk.get_meta("first_target", -1)) == foe.id, "первый ход скелет бьёт цель заклинания")
	c.summon("bear", caster, Unit.PARTY)
	c.summon("wolf", caster, Unit.PARTY)
	var own := c.living(Unit.PARTY).filter(func(u: Unit) -> bool: return u.creature)
	check(own.size() == 2 and not sk.alive(), "лимит 2 существа: самый старый уходит")
	var bear: Unit = own[0]
	check(bear.has("taunt"), "Медведь провоцирует")
	var skel := c.summon("skeleton", caster, Unit.PARTY)
	c._hurt(skel, 10.0, foe)
	check(skel.alive() and skel.hp == 2.0, "скелет собирается один раз")
	c._hurt(skel, 10.0, foe)
	check(not skel.alive(), "второй раз — рассыпается насовсем")
	var deer := c.summon("deer", caster, Unit.PARTY)
	caster.hp = caster.max_hp - 2.0
	c.enemy_act(deer)
	check(caster.hp == caster.max_hp - 1.0, "Олень лечит раненого на 1")
	for u in c.party_wizards():
		u.hp = 0.0
	c.outcome = ""
	c._check_outcome()
	check(c.outcome == "defeat", "пали волшебники — поражение, даже если звери живы")
	var rnd := EffectParser.parse(books.bestiary.spells.filter(func(sp: Dictionary) -> bool: return sp.combo == "X1")[0])
	check(rnd.summon.group == "bestiary" and rnd.summon.side == "random", "Сбежал со страницы: случайное существо на случайную сторону")
	var reap := EffectParser.parse(books.necronomicon.spells.filter(func(sp: Dictionary) -> bool: return sp.combo == "X3")[0])
	check(reap.raise_fallen == "skeleton", "Жатва: погибшие встают скелетами")


## Каждое заклинание каждой книги срабатывает по врагу и по союзнику без ошибок и хоть что-то меняет.
func test_every_spell_runs(books: Dictionary) -> void:
	print("Все заклинания срабатывают:")
	var silent: Array[String] = []
	var count := 0
	var ids := books.keys()
	ids.sort()
	for bid in ids:
		for sp in books[bid].spells:
			for on_foe in [true, false]:
				var adv := Adventure.new(["pyromancer", "priest", "water"], 77)
				var c := adv.start_combat(77)
				var caster: Unit = c.units[0]
				caster.hp = caster.max_hp - 3.0
				var t: Unit = c.living(Unit.ENEMIES)[0] if on_foe else c.units[1]
				t.hp = maxf(1.0, t.max_hp - 3.0)
				t.set_meta("turn_mark", t.max_hp)
				t.set_meta("healed_total", 2.0)
				var before := _state_sig(c)
				var chips: Array[String] = []
				var combo := String(sp.combo)
				if combo.begins_with("X"):
					for i in int(combo.substr(1)):
						chips.append(ChipBag.CHAOS)
				else:
					for ch in combo:
						chips.append(ch)
				c._apply_spell(caster, t, sp, chips, bid)
				count += 1
				var spec := EffectParser.parse(sp)
				if _state_sig(c) == before and not spec.nothing and on_foe:
					silent.append("%s %s «%s»" % [bid, combo, sp.name])
	print("       проверено кастов: %d" % count)
	if not silent.is_empty():
		print("       по врагу ничего не изменили (бывает при промахе удачи или без условий): %s" % ", ".join(silent))
	check(silent.size() <= 12, "почти каждое заклинание меняет бой (молчат: %d)" % silent.size())


func _state_sig(c: Combat) -> String:
	var parts := []
	for u in c.units:
		parts.append("%s|%s|%s|%s|%s|%s|%s" % [u.hp, u.shield, JSON.stringify(u.statuses), snappedf(u.meter, 0.01), u.wisdom + u.defense_bonus + u.luck_bonus, u.speed,
			u.get_meta_list().size()])
		if u.wizard:
			parts.append(u.wizard.item + u.wizard.item2)
	parts.append(str(c.units.size()))
	return ";".join(parts)


func test_pick_and_stats(books: Dictionary) -> void:
	print("Выбор заклинания и итоги забега:")
	var adv := Adventure.new(["pyromancer", "priest"], 21)
	var c := adv.start_combat(21)
	var caster: Unit = c.units[0]
	var foe: Unit = c.living(Unit.ENEMIES)[0]
	var bag := ChipBag.new(books.mystery.bag, 0)
	bag.chips.assign(["X", "X", "T"])
	check(c.needs_pick("mystery", bag), "«Судьба переписана» просит выбрать заклинание")
	var pick: Dictionary = c.pickable_spells("mystery").filter(func(sp: Dictionary) -> bool: return EffectParser.parse(sp).damage > 0)[0]
	caster.set_meta("picked_combo", pick.combo)
	var said: Array[String] = []
	c.logged.connect(func(t: String, _k: String, _i: String) -> void: said.append(t))
	c.cast(caster, foe, "mystery", bag)
	check(said.any(func(t: String) -> bool: return t.contains("«%s»" % pick.name) and t.contains("выбирает")), "сработало выбранное: %s" % pick.name)
	check(float(c.stats[caster.id].dmg) > 0.0 and int(c.stats[caster.id].casts) == 1, "статистика боя: урон и касты кастующего")
	adv.finish_combat(c)
	check(adv.run_stats.battles == 1 and float(adv.run_stats.wizards[0].dmg) > 0.0, "итоги забега копятся")
	var back := SaveGame.restore(JSON.parse_string(JSON.stringify(SaveGame.dump(adv))))
	check(back != null and float(back.run_stats.wizards[0].dmg) == float(adv.run_stats.wizards[0].dmg), "итоги забега переживают сохранение")


func test_rat_pack_simulation(books: Dictionary) -> void:
	print("Симуляция: стартовый отряд против Крысиной стаи (2000 боёв):")
	var stats: Dictionary = load("res://tests/simulate.gd").run(
		GameData.load_encounter("rat_pack"), ["pyromancer", "priest", "water"], 2000)
	print("       побед: %.1f %%, раундов: %.1f, урон по отряду за раунд: %.2f"
		% [stats.win_rate, stats.rounds, stats.damage_per_round])
	check(stats.win_rate >= 90.0, "уровень 1 проходится в ≥ 90 %% боёв (%.1f %%)" % stats.win_rate)


## Отдых: 75 % лечения, излишек × 10 % → Укрепление на 5 ходов, тает по 0.5.
func test_rest_and_fortify() -> void:
	print("Отдых и Укрепление:")
	var adv := Adventure.new(["pyromancer", "priest", "water"], 3)
	var pyro := adv.wizards[0]
	var water := adv.wizards[2]
	pyro.hp = 2.0      # 2 + 7.5 = 9.5 → без излишка
	adv.wizards[1].hp = 10.0  # 10 + 7.5 → излишек 7.5 → Укрепление 0.75 → 0.8 (шаг 0.1)
	water.hp = 0.0     # выбыл — не лечится
	adv.rest()
	check(is_equal_approx(pyro.hp, 9.5) and is_equal_approx(pyro.fortify, 0.0), "раненый: 2 → 9.5, без Укрепления")
	check(is_equal_approx(adv.wizards[1].fortify, 0.8), "полный: Укрепление 0.8 — шаг 0.1 (%.2f)" % adv.wizards[1].fortify)
	check(water.hp == 0.0, "выбывший не лечится")
	var c := adv.start_combat(5)
	var priest_unit: Unit = c.units[1]
	check(is_equal_approx(priest_unit.fortify, 0.8) and priest_unit.fortify_turns == 5, "Укрепление перешло в бой на 5 ходов")
	check(adv.wizards[1].fortify == 0.0, "в волшебнике Укрепление обнулилось (только на один бой)")
	priest_unit.shield = 1.0
	c._hurt(priest_unit, 2.0, null)
	check(is_equal_approx(priest_unit.fortify, 0.0) and is_equal_approx(priest_unit.shield, 0.0)
		and is_equal_approx(priest_unit.hp, 9.8), "урон 2: сначала Укрепление 0.8, потом Щит 1, потом 0.2 ЗД (%s)" % Unit._num(priest_unit.hp))
	var u := Unit.new()
	u.fortify = 3.0
	u.fortify_turns = 5
	for i in 5:
		u.tick_down()
	check(u.fortify == 0.0 and u.fortify_turns == 0, "Укрепление тает по 0.5 за ход и исчезает через 5 ходов")


## Выбывший после победы поднимается с 50 % ЗД и Разбитостью (−25 % скорости, 10 ходов).
func test_revive_after_battle() -> void:
	print("Воскрешение после боя и Разбитость:")
	var adv := Adventure.new(["pyromancer", "priest", "water"], 21)
	var c := adv.start_combat(21)
	var pyro_unit: Unit = c.units[0]
	pyro_unit.hp = 0.0
	for u in c.living(Unit.ENEMIES):
		u.hp = 0.0
	c._check_outcome()
	adv.finish_combat(c)
	var pyro := adv.wizards[0]
	check(is_equal_approx(pyro.hp, 5.0), "поднялся с 50 %% ЗД (%s)" % Unit._num(pyro.hp))
	check(pyro.carry_statuses.get("aching", 0) == 10, "Разбитость на 10 ходов")
	var rest := adv.rest()
	check(rest[0].get("revived", false) and is_equal_approx(pyro.hp, 5.0) and pyro.fortify == 0.0,
		"на этом привале не отдыхает и не получает Укрепление")
	var c2 := adv.start_combat(22)
	var u: Unit = c2.units[0]
	check(u.has("aching") and is_equal_approx(u.effective_speed(), 7.5), "в следующем бою: скорость 10 → 7.5")
	for i in 3:
		u.tick_down()
	c2.outcome = "victory"
	adv.finish_combat(c2)
	check(pyro.carry_statuses.get("aching", 0) == 7, "недоигранные ходы переходят дальше (осталось 7)")
	var c3 := adv.start_combat(23)
	var u3: Unit = c3.units[0]
	c3._restore(u3, 1.0)
	check(not u3.has("aching"), "лечение снимает Разбитость")
	var c4 := adv.start_combat(24)
	var u4: Unit = c4.units[0]
	c4._apply_status(u4, {"id": "haste", "turns": 2}, c4.units[1])
	check(not u4.has("aching"), "бафф снимает Разбитость")


## Отряд из 4: враги крепче, в банде на одного рядового больше, босс заметно крепче.
func test_party_scaling() -> void:
	print("Усиление врагов под отряд из 4:")
	var cfg: Dictionary = GameData.load_json("res://data/adventure/act1.json")
	var gob := GameData.load_encounter("goblin_gang")
	var g4 := Adventure.scale_encounter(gob, 4, cfg)
	check(g4.members.size() == gob.members.size() + 1, "в банде на одного рядового больше")
	check(int(g4.members[3].hp) == roundi(float(gob.members[3].hp) * 1.5 * 1.5), "здоровье предводителя ×1.5 (общее) ×1.5 (отряд из 4)")
	var g3 := Adventure.scale_encounter(gob, 3, cfg)
	check(g3.members.size() == gob.members.size() and int(g3.members[3].hp) == roundi(float(gob.members[3].hp) * 1.5),
		"для 3 волшебников — только общий множитель ×1.5")
	var king := Adventure.scale_encounter(GameData.load_encounter("rat_king"), 4, cfg)
	check(int(king.members[0].hp) == roundi(22 * 1.8 * 2.4), "здоровье босса ×1.8 ×2.4 (%d)" % int(king.members[0].hp))
	var adv := Adventure.new(["pyromancer", "priest", "water", "magus"], 5)
	check(adv.wizards[3].max_books == 2 and adv.book_pool().has("blade"), "Магус: 2 слота книг, его книга в пуле лута")


## Прогресс: 4 стартовых класса, Бард после первого приключения, Паладин после первой победы.
func test_profile_unlocks() -> void:
	print("Открытие классов:")
	Profile.path = "user://test_profile.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Profile.path))
	var classes := GameData.load_classes()
	var p := Profile.load_or_new(classes)
	p.unlocked.sort()
	check(p.unlocked == ["magus", "priest", "pyromancer", "water"], "сразу открыты: Огонь, Вода, Священник, Магус")
	var fresh := p.record_run(false, classes)
	check(fresh == ["bard"], "поражение в первом приключении открывает Барда")
	fresh = p.record_run(true, classes)
	check(fresh == ["paladin"], "первая победа открывает Паладина")
	var again := Profile.load_or_new(classes)
	check(again.unlocked.has("bard") and again.unlocked.has("paladin") and again.runs == 2, "прогресс сохраняется в профиле")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Profile.path))


func test_bard_and_paladin() -> void:
	print("Бард и Паладин:")
	var adv := Adventure.new(["pyromancer", "priest", "bard", "paladin"], 31)
	var c := adv.start_combat(31)
	var pyro: Unit = c.units[0]
	var bard: Unit = c.units[2]
	var pal: Unit = c.units[3]
	check(c.can_inspire(bard) and bard.ability_charges == 2, "Бард: 2 Вдохновения за бой")
	c.inspire(bard, pyro)
	check(pyro.has("muse") and c.can_reroll(pyro), "Муза даёт право перевытянуть фишку")
	pyro.ability_charges = 0
	var bag := c.new_bag(pyro, "fire")
	while not bag.is_complete():
		bag.draw(c.rng)
	c.reroll_chip(pyro, bag, 0)
	check(not pyro.has("muse"), "Муза тратится на одно перевытягивание")
	pyro.hp = 4.0
	c.lay_on_hands(pal, pyro)
	check(is_equal_approx(pyro.hp, 9.0) and is_equal_approx(pal.ability_pool, 0.0), "Наложение рук: 5 лечения из запаса")
	pal.ability_pool = 5.0
	c._check_oath(pal, true)
	check(pal.ability_pool == 0.0, "каст ранил союзника — клятва нарушена, запас сгорел")


## Лут: правила выпадения и инвентаря.
func test_map() -> void:
	print("Карта с развилками:")
	var adv := Adventure.new(["pyromancer", "priest", "water"], 5)
	var nodes := adv.map_nodes
	var last := adv.level_count()
	var ok_fork := true
	var ok_distinct := true
	var ok_no_repeat := true
	var bosses := 0
	for n in nodes:
		if n.level == last:
			bosses += 1
			continue
		if n.children.size() != 2 and adv.map_nodes[n.children[0]].level != last:
			ok_fork = false
		if n.children.size() == 2 and nodes[n.children[0]].encounter == nodes[n.children[1]].encounter:
			ok_distinct = false
		var seen := {}
		for e in adv._path_encounters(n.id):
			if seen.has(e):
				ok_no_repeat = false
			seen[e] = true
	check(nodes[0].level == 1 and nodes[0].encounter == "rat_pack", "старт — Крысиная стая")
	check(ok_fork, "после каждого уровня — две дороги")
	check(ok_distinct, "на развилке разные банды")
	check(ok_no_repeat, "на одном пути банды не повторяются")
	check(bosses == 1 and nodes.back().parents.size() == 8, "все дороги сходятся к одному боссу")
	check(not adv.needs_choice() and adv.choices().is_empty(), "до первого боя выбирать нечего")
	adv.level = 2  # пройден 1-й уровень
	var ch := adv.choices()
	check(adv.needs_choice() and ch.size() == 2, "после 1-го уровня — выбор из двух")
	check(not adv.choose(nodes[0].id), "нельзя пойти не на соседнюю локацию")
	var other: int = ch[1].id
	check(adv.choose(ch[0].id) and adv.encounter().id == ch[0].encounter, "следующий бой — выбранная банда")
	var closed: bool = adv.is_closed(other) and nodes[other].children.all(func(c: int) -> bool: return adv.is_closed(c))
	check(closed and not adv.is_closed(nodes[ch[0].id].children[0]), "вторая ветка закрылась со всеми продолжениями")
	check(not adv.is_closed(nodes.back().id), "босс по-прежнему впереди")
	# Локация сдвигает добычу: в библиотеке чаще книги, в погребе — предметы.
	for w in adv.wizards:
		w.books.assign(["fire", "storm"])
	adv.level = 3
	var rates := {}
	for site in ["library", "cellar"]:
		adv.map_nodes[adv.node_id].site = site
		var got := 0
		var total := 0
		for i in 300:
			for o in adv.roll_loot(false):
				if o.kind == "book":
					got += 1
				total += 1
		rates[site] = float(got) / total
	check(rates.library > 0.7 and rates.cellar < 0.3,
		"добыча зависит от локации: книги в библиотеке %.0f %%, в погребе %.0f %%" % [rates.library * 100, rates.cellar * 100])


func test_dead_tongue_cost() -> void:
	print("Плата за Книгу Мёртвого Языка:")
	var books := GameData.load_books()
	var w := Wizard.new("pyromancer", GameData.load_classes().pyromancer, {})
	w.books.append("deadtongue")
	var enc := GameData.load_encounter("rat_king")
	var c := Combat.new(books, [w], enc, 3, {})
	var u: Unit = c.living(Unit.PARTY)[0]
	var foe: Unit = c.living(Unit.ENEMIES)[0]
	for i in 2:
		var bag := c.new_bag(u, "deadtongue")
		while not bag.is_complete():
			bag.draw(c.rng)
		c.cast(u, foe, "deadtongue", bag, false)
	check(u.has("dead_poison") and u.statuses.dead_poison.stacks == 2, "каждый каст — стак Мёртвого яда (2 каста → 2 стака)")
	u.hp = 10.0
	c._start_of_turn(u)
	check(is_equal_approx(u.hp, 9.0), "в начале хода 0.5 урона за стак (10 → %s)" % Unit._num(u.hp))
	u.remove_debuffs()
	check(not u.has("dead_poison"), "снимается Очищением")


func _fight(encounter_id: String, party: Array = ["pyromancer", "priest", "water"]) -> Combat:
	var books := GameData.load_books_cached()
	var ws: Array[Wizard] = []
	for cid in party:
		ws.append(Wizard.new(cid, GameData.load_classes()[cid], {}))
	return Combat.new(books, ws, GameData.load_encounter(encounter_id), 7, {})


func test_bosses() -> void:
	print("Боссы акта I:")
	var act: Dictionary = GameData.load_json("res://data/adventure/act1.json")
	var seen := {}
	for i in 60:
		var adv := Adventure.new(["pyromancer", "priest", "water"], i + 1)
		seen[adv.map_nodes.back().encounter] = true
	check(seen.size() == 5 and act.levels[4].size() == 5, "на 5-м уровне — случайный из 5 боссов (встретились: %d)" % seen.size())
	var c := _fight("goblin_chief")
	var pig: Unit = c.living(Unit.ENEMIES)[0]
	var chief: Unit = c.living(Unit.ENEMIES)[1]
	c._hurt(pig, 99.0, c.living(Unit.PARTY)[0])
	check(chief.speed == 9.0 and chief.attack == 3, "свинья пала — вождь спешился: скорость 9, урон 3")
	c = _fight("mother_slime")
	var slime: Unit = c.living(Unit.ENEMIES)[0]
	c._hurt(slime, 9.0, null)
	check(c.living(Unit.ENEMIES).size() == 3, "Матушка-Слизь: 9 урона → отделились 2 слизня")
	var hp_before := slime.hp
	c._use_special(slime, {"id": "absorb", "name": "Поглощение", "text": ""})
	check(c.living(Unit.ENEMIES).size() == 1 and slime.hp > hp_before, "Поглощение: слизни исчезли, Матушка вылечилась")
	c = _fight("goose_patriarch")
	var goose: Unit = c.living(Unit.ENEMIES)[0]
	c._hit(goose, 5.0, c.living(Unit.PARTY)[0], "?")
	c._hit(goose, 5.0, c.living(Unit.PARTY)[0], "?")
	check(goose.hp == goose.max_hp and goose.has("invulnerable"), "Гусь неуязвим первые ходы — и не после первого удара")
	c = _fight("one_eyed_bo")
	var bo: Unit = c.living(Unit.ENEMIES)[0]
	check(bo.has("invisible") and not c.can_target(c.living(Unit.PARTY)[0], bo), "Бо невидим, пока рядом подручный")
	c = _fight("goblin_chief")
	chief = c.living(Unit.ENEMIES)[1]
	c._use_special(chief, chief.specials[0])
	check(chief.attack == 4 and c.living(Unit.ENEMIES).all(func(u: Unit) -> bool: return u.has("haste")),
		"Боевой клич: все враги ускорены, вождь +2 к урону")
	for i in 3:
		c.end_turn(chief)
	check(chief.attack == 2, "через 2 хода бонус к урону проходит")


func test_trophies_and_scars() -> void:
	print("Трофеи и шрамы боссов:")
	var adv := Adventure.new(["pyromancer", "priest", "water"], 3)
	adv.map_nodes.back().encounter = "rat_king"
	adv.level = adv.level_count()
	adv.node_id = adv.map_nodes.back().id
	var c := adv.start_combat(5)
	var water: Unit = c.living(Unit.PARTY)[2]
	c._hurt(water, 99.0, null)
	for e in c.living(Unit.ENEMIES):
		e.hp = 0.0
	c._check_outcome()
	adv.finish_combat(c)
	var w := adv.wizards[2]
	check(adv.trophy_boss == "rat_king" and w.scars == ["rat_king"], "выбывший в бою с боссом получил шрам «Укушенный»")
	check(w.max_hp() == 7.0, "шрам: −1 макс. ЗД (8 → %s)" % Unit._num(w.max_hp()))
	var pyro := adv.wizards[0]
	check(adv.award_trophy("cursed", pyro) and pyro.max_hp() == 13.0 and adv.trophy_boss == "",
		"Корона Крысиного Короля: +3 ЗД Пироманту")
	var c2 := adv.start_combat(9)
	check(c2.living(Unit.ENEMIES).any(func(u: Unit) -> bool: return u.name == "Крыса из свиты"),
		"проклятый трофей: в начале боя у врага появляется крыса")
	var p := Wizard.new("priest", GameData.load_classes().priest, {})
	p.scars.append("mother_slime")
	var c3 := Combat.new(GameData.load_books_cached(), [p], GameData.load_encounter("rat_pack"), 1, {})
	var pu: Unit = c3.living(Unit.PARTY)[0]
	pu.hp = 2.0
	c3._restore(pu, 3.0)
	check(pu.hp == 4.0, "шрам «Разъеденный»: лечение на 1 меньше")
	var g := Wizard.new("priest", GameData.load_classes().priest, {})
	g.scars.append("goose_patriarch")
	var c4 := Combat.new(GameData.load_books_cached(), [g], GameData.load_encounter("geese_gang"), 1, {})
	check(c4.living(Unit.PARTY)[0].has("fear"), "шрам «Гусебоязнь»: в бою с гусями — Страх")


func test_achievements() -> void:
	print("Достижения:")
	var adv := Adventure.new(["priest", "water", "magus"], 4)
	for i in 3:
		var c := adv.start_combat(i + 1)
		for e in c.living(Unit.ENEMIES):
			e.hp = 0.0
		c._check_outcome()
		adv.finish_combat(c)
		if adv.needs_choice():
			adv.choose(adv.choices()[0].id)
	check(adv.earned.has("forester"), "«Лесник»: 3 победы подряд без выбывших без Пироманта")
	var adv2 := Adventure.new(["pyromancer", "priest", "water"], 4)
	var c2 := adv2.start_combat(1)
	c2.tally.chaos_big = 3
	c2.tally.items = 12
	for e in c2.living(Unit.ENEMIES):
		e.hp = 0.0
	c2._check_outcome()
	adv2.finish_combat(c2)
	check(adv2.earned.has("chaos_ally") and adv2.earned.has("hoarder"), "«Хаос — мой союзник» и «Запасливый» по счётчикам")
	check(not adv2.earned.has("forester"), "с Пиромантом «Лесника» не дают")
	var fresh := adv2.take_fresh_achievements()
	check(fresh.size() == 2 and adv2.take_fresh_achievements().is_empty(), "новые достижения выдаются один раз")
	Profile.path = "user://test_profile_ach.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Profile.path))
	var classes := GameData.load_classes()
	var prof := Profile.load_or_new(classes)
	prof.achievements["chaos_ally"] = true
	var opened := prof.record_run(false, classes)
	check(opened.has("wild_mage") and opened.has("bard"), "после приключения открыт Дикий маг (и Бард за первый забег)")
	var ach: Dictionary = GameData.load_json("res://data/achievements.json")
	var ok := true
	for id in ach:
		if classes.get(ach[id].class, {}).get("unlock", {}).get("id", "") != id:
			ok = false
	check(ok and ach.size() == 10, "10 достижений, каждое открывает свой класс")


func test_save_and_load() -> void:
	print("Сохранение приключения:")
	SaveGame.path = "user://test_adventure.json"
	SaveGame.clear()
	var adv := Adventure.new(["pyromancer", "priest", "water", "magus"], 21)
	var c := adv.start_combat(3)
	AutoPlayer.play(c)
	for e in c.living(Unit.ENEMIES):
		e.hp = 0.0
	c._check_outcome()
	adv.finish_combat(c)
	adv.rest()
	adv.roll_loot()
	adv.wizards[1].trophies.append("goose_patriarch:trophy")
	adv.wizards[2].scars.append("rat_king")
	adv.choose(adv.choices()[1].id)
	SaveGame.write(adv, "map", {"note": 1})
	check(SaveGame.exists() and SaveGame.summary().begins_with("уровень 2"), "сохранено: %s" % SaveGame.summary())
	var data := SaveGame.read()
	var b: Adventure = data.adventure
	var same := b.level == adv.level and b.node_id == adv.node_id and b.path == adv.path \
		and b.map_nodes.size() == adv.map_nodes.size() and b.offers.size() == adv.offers.size()
	for i in adv.wizards.size():
		var x := adv.wizards[i]
		var y := b.wizards[i]
		same = same and x.hp == y.hp and x.books == y.books and x.item == y.item and x.hat == y.hat \
			and x.boots == y.boots and x.trophies == y.trophies and x.scars == y.scars
	check(same and data.screen == "map", "загружено то же самое: уровень, карта, отряд, книги, вещи, трофеи, шрамы, добыча")
	check(b.rng.randi() == adv.rng.randi(), "генератор случайности продолжается с того же места")
	check(b.encounter().id == adv.encounter().id, "следующий бой — та же банда")
	SaveGame.clear()
	check(not SaveGame.exists(), "после конца приключения сохранение удаляется")


func test_settings_and_sound() -> void:
	print("Настройки и звук:")
	Settings.path = "user://test_settings.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.load_from_disk()
	check(Settings.speed() == 1.0 and Settings.value("tutorial") == true,
		"по умолчанию: обычная скорость, обучение включено (скорость %s, обучение %s)" % [Settings.speed(), Settings.value("tutorial")])
	Settings.set_value("speed", 2.0)
	Settings.set_value("tutorial", false)
	Settings.set_value("sfx", 0.0)
	Settings.load_from_disk()
	check(Settings.speed() == 2.0 and Settings.value("tutorial") == false and is_equal_approx(Settings.delay(0.8), 0.4),
		"настройки сохраняются: скорость ×2 (пауза 0.8 → 0.4 с), обучение выключено")
	check(AudioServer.get_bus_index("SFX") != -1 and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),
		"шина звуков создана, громкость 0 → звук выключен")
	var ok := true
	for id in Sfx.MIX:
		var st := Sfx.stream_for(id)
		if st == null or (st is AudioStreamWAV and (st as AudioStreamWAV).data.size() < 400):
			ok = false
	check(ok, "у всех %d звуков есть файл или временный звук" % Sfx.MIX.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.load_from_disk()


func _party_fight(party: Array, enc: String = "rat_king", seed_value: int = 11) -> Combat:
	var classes := GameData.load_classes()
	var ws: Array[Wizard] = []
	for cid in party:
		ws.append(Wizard.new(cid, classes[cid], {}))
	return Combat.new(GameData.load_books_cached(), ws, GameData.load_encounter(enc), seed_value, GameData.load_json("res://data/items.json"))


func _full_bag(c: Combat, u: Unit, book: String) -> ChipBag:
	var bag := c.new_bag(u, book)
	while not bag.is_complete():
		bag.draw(c.rng)
	return bag


func test_manual_draw_edge() -> void:
	print("Ручное вытягивание:")
	check(is_equal_approx(Combat.MANUAL_EDGE, 0.001), "бонус вручную — 0.1 %")
	var c := _party_fight(["pyromancer", "priest", "water"], "rat_pack")
	var pyro: Unit = c.living(Unit.PARTY)[0]
	var foe: Unit = c.living(Unit.ENEMIES)[0]
	var ok_enemy := true
	var ok_ally := true
	for i in 200:
		for want_enemy in [true, false]:
			var bag := c.new_bag(pyro, "fire")
			var tgt: Unit = foe if want_enemy else pyro
			for k in 3:
				var letter := c.nudged_letter(pyro, tgt, "fire", bag)
				if letter == "":
					break
				var forced: Array[String] = bag.chips.duplicate()
				forced.append(letter)
				bag.forced = forced
				bag.draw(c.rng)
			if bag.is_complete():
				var spec := EffectParser.parse(c.spell_for("fire", bag.combo_key()))
				var dmg: bool = spec.damage > 0 or spec.splash > 0
				if want_enemy and not dmg:
					ok_enemy = false
				if not want_enemy and dmg:
					ok_ally = false
	check(ok_enemy, "подыгрыш по врагу ведёт к заклинанию с уроном")
	check(ok_ally, "подыгрыш по союзнику ведёт к защите, лечению или нейтральному")


func test_class_abilities() -> void:
	print("Способности классов:")
	# Некромант: Поднятие — зомби с 6 ЗД из 12, одна книга потеряна, слотов 2.
	var c := _party_fight(["necromancer", "priest", "pyromancer"])
	var necro: Unit = c.living(Unit.PARTY)[0]
	var pyro: Unit = c.living(Unit.PARTY)[2]
	pyro.wizard.books.append("storm")
	pyro.books.append("storm")
	c._hurt(pyro, 99.0, null)
	check(c.can_use_ability(necro) and c.ability_targets(necro) == [pyro], "Поднятие: цель — выбывший союзник")
	c.use_target_ability(necro, pyro)
	check(pyro.alive() and pyro.hp == 6.0 and pyro.max_hp == 12.0 and pyro.wizard.zombie
		and pyro.wizard.books.size() == 1 and pyro.wizard.max_books == 2, "зомби: 6/12 ЗД, одна книга потеряна, 2 слота")
	pyro.wizard.cure_zombie()
	check(not pyro.wizard.zombie and pyro.wizard.max_books == 3 and pyro.wizard.max_hp() == 10.0, "свиток воскрешения снова делает живым")
	# Обратный эффект: урон ↔ лечение.
	var inv := EffectParser.invert({"damage": 3, "heal": 0, "shield": 2, "splash": 0, "statuses": [{"id": "stun", "turns": 1}],
		"meter": -30, "cleanse": false, "strip_buffs": false, "revive_hp": 0})
	check(inv.heal == 3 and inv.damage == 0 and inv.meter == 30 and inv.statuses.any(func(x): return x.id == "vulnerable")
		and inv.statuses.any(func(x): return x.id == "haste"), "обратный эффект: урон → лечение, щит → Уязвимость, контроль → Ускорение")
	# Иллюзионист: Двойник принимает следующий удар.
	c = _party_fight(["illusionist", "priest", "water"])
	var ill: Unit = c.living(Unit.PARTY)[0]
	var pr: Unit = c.living(Unit.PARTY)[1]
	c.use_target_ability(ill, pr)
	var hp := pr.hp
	c._hit(pr, 3.0, c.living(Unit.ENEMIES)[0], "?")
	check(pr.hp == hp and not pr.has("invulnerable") and ill.ability_charges == 0, "Двойник принял удар и исчез")
	# Учёный: Мастерская заменяет ход; овца ломается от Хаоса II.
	c = _party_fight(["scientist", "priest", "water"])
	var sci: Unit = c.living(Unit.PARTY)[0]
	var king: Unit = c.living(Unit.ENEMIES)[0]
	hp = king.hp
	c.use_workshop(sci, "wolf", king)
	check(king.hp < hp and sci.has("taunt") and sci.ability_charges == 1, "Стальной волк кусает врага, Учёный провоцирует")
	var bag := ChipBag.new(c.books.sheep.bag)
	bag.chips.assign(["X", "X", "M"])
	var sw := sci.wizard
	c.cast(sci, king, "sheep", bag)
	check(sw.sheep_broken and not sw.books.has("sheep") and sw.max_books == 3, "Хаос II ломает овцу — её слоты свободны")
	var adv := Adventure.new(["scientist", "priest", "water"], 2)
	var aw := adv.wizards[0]
	aw.books.assign(["storm", "fire", "ice"])
	aw.sheep_broken = true
	aw.max_books = 3
	check(adv.repair_sheep(aw, "fire", "ice") and aw.books == ["sheep", "storm"] and aw.max_books == 2, "починка: 2 книги выброшены, овца снова в слотах")
	# Друид: Зов зверя меняет тройку или цель.
	c = _party_fight(["druid", "priest", "water"])
	var dr: Unit = c.living(Unit.PARTY)[0]
	bag = _full_bag(c, dr, "druid")
	check(c.can_use_ability(dr, bag), "Зов зверя — когда тройка вытянута")
	var beast := c.beast_call(dr, bag, c.living(Unit.ENEMIES)[0])
	check(beast in ["bear", "hare", "raven", "cat"] and dr.ability_charges == 1, "пришёл зверь: %s" % beast)
	check(not c.living(Unit.PARTY)[0].wizard.can_use_book("fire"), "Друид не пользуется Книгой Огня")
	# Дикий маг: Всплеск превращает фишку в Хаос.
	c = _party_fight(["wild_mage", "priest", "water"])
	var wm: Unit = c.living(Unit.PARTY)[0]
	bag = ChipBag.new(c.books.wild.bag)
	bag.chips.assign(["F", "W", "F"])
	c.surge(wm, bag)
	check(bag.combo_key() == "X1" and wm.extra_chaos == 2, "Всплеск: тройка стала Хаосом I; у Дикого мага +2 фишки Хаоса")
	# Чернокнижник: Сделка — 2 ЗД за выбранную фишку.
	c = _party_fight(["warlock", "priest", "water"])
	var wl: Unit = c.living(Unit.PARTY)[0]
	bag = c.new_bag(wl, "pact")
	var letter: String = Combat.letters_by_count(c.books.pact.bag)[2]
	check(c.pact_deal(wl, bag, letter) and wl.hp == 8.0, "Сделка стоит 2 ЗД")
	bag.draw(c.rng)
	check(bag.chips[0] == letter, "следующая фишка — выбранная (%s)" % letter)
	var adv2 := Adventure.new(["warlock", "priest", "water"], 2)
	adv2.patron_due.append(adv2.wizards[0])
	adv2.pay_patron(adv2.wizards[0], "hp")
	check(adv2.wizards[0].max_hp() == 9.0 and adv2.patron_due.is_empty(), "Покровитель голоден: −1 макс. ЗД после босса")
	# Прорицатель: 2 видения, любой может заменить тройку.
	c = _party_fight(["seer", "priest", "pyromancer"])
	var pyro2: Unit = c.living(Unit.PARTY)[2]
	check(c.visions.size() == 2, "Видения: 2 тройки увидены заранее")
	bag = _full_bag(c, pyro2, "fire")
	var want := c.vision_chips(c.visions[0], "fire")
	c.use_vision(pyro2, bag, 0, "fire")
	check(bag.chips == want and c.visions.size() == 1, "Пиромант заменил тройку видением: %s" % "".join(want))
	# Хрономант: Перемотка возвращает бой к моменту перед кастом.
	c = _party_fight(["chronomancer", "priest", "water"])
	var ch: Unit = c.living(Unit.PARTY)[0]
	var pw: Unit = c.living(Unit.PARTY)[1]
	var hp_before := pw.hp
	bag = ChipBag.new(c.books.chrono.bag)
	bag.chips.assign(["C", "C", "C"])
	c.cast(pw, pw, "chrono", bag)
	c._hurt(pw, 3.0, null)
	c.last_cast = {"caster": pw.id, "bad": true}
	check(c.can_rewind(), "после неудачного каста можно перемотать")
	var again := c.rewind()
	check(again == pw and pw.hp == hp_before and ch.ability_charges == 0 and not c.can_rewind(),
		"Перемотка: здоровье вернулось, кастует снова тот же, заряд потрачен")
	# Алхимик: 2 предмета и смешивание.
	var adv3 := Adventure.new(["alchemist", "priest", "water"], 3)
	var al := adv3.wizards[0]
	adv3.take_item({"wizard": 0, "kind": "item", "id": "potion_heal", "resolved": false})
	adv3.take_item({"wizard": 0, "kind": "item", "id": "bomb", "resolved": false})
	check(al.item == "potion_heal" and al.item2 == "bomb", "Алхимик носит 2 предмета")
	var made := adv3.mix_items(al)
	check(made != "" and al.item == made and al.item2 == "" and int(adv3.items[made].weight) < 6,
		"смешал в более редкий: %s" % adv3.items.get(made, {}).get("name", made))
	# Оракул: шрам с начала, +1 Мудрость за каждые 5 уровней.
	var adv4 := Adventure.new(["oracle", "priest", "water"], 4)
	var orc := adv4.wizards[0]
	adv4.level = 6
	adv4.start_combat(1)
	check(orc.scars.size() == 1 and orc.bonus_wisdom == 1 and orc.stats().wisdom >= 1, "Оракул: шрам с начала, на 6-м уровне +1 Мудрость")


func test_loot_rules() -> void:
	print("Лут и инвентарь:")
	var adv := Adventure.new(["pyromancer", "priest", "water"], 11)
	adv.level = 2  # пройден 1-й уровень
	var first := adv.roll_loot(false)
	var per_w := {}
	for o in first:
		per_w[o.wizard] = per_w.get(o.wizard, []) + [o.kind]
	check(per_w.values().all(func(k: Array) -> bool: return k.has("book") and k.has("equipment")),
		"после 1-го уровня: каждому книга и шляпа/ботинки")
	adv.level = 3
	var ok_books := true
	var no_equipment := true
	for i in 200:
		for o in adv.roll_loot(false):
			if o.kind != "book":
				ok_books = false
	check(ok_books, "у кого одна книга — всегда выпадает книга")
	for w in adv.wizards:
		w.books.assign(["fire", "storm"])
	var kinds := {}
	for i in 300:
		for o in adv.roll_loot(false):
			kinds[o.kind] = true
			if o.kind == "equipment":
				no_equipment = false
	check(no_equipment and kinds.has("book") and kinds.has("item"), "обычный уровень: книга или расходуемый предмет, без вещей")
	var boss_items := 0
	for i in 500:
		for o in adv.roll_loot(true):
			if o.kind == "item" and o.id != "scroll_resurrect":
				boss_items += 1
	var rate := boss_items / 1500.0
	check(absf(rate - 0.2) < 0.04, "после босса: книга + вещь, и предмет с шансом 20 %% (%.0f %%)" % (rate * 100))
	var pool := adv.book_pool()
	check(pool.has("fire") and pool.has("storm") and not pool.has("sheep") and not pool.has("bard"),
		"в пуле: книги лута и открытых классов, без овцы и закрытых классов")
	var pyro := adv.wizards[0]
	var o := {"wizard": 0, "kind": "book", "id": "water", "resolved": false}
	check(not adv.take_book(o), "Пиромант не может взять Книгу Воды")
	var refusals := adv.refusals_left
	check(adv.refuse_book(o) and adv.refusals_left == refusals, "выбросить запретную книгу можно без траты отказа")
	pyro.books.assign(["fire", "storm", "ice"])
	var o2 := {"wizard": 0, "kind": "book", "id": "cookbook", "resolved": false}
	check(not adv.take_book(o2), "4-ю книгу без замены не взять")
	check(adv.take_book(o2, "ice") and pyro.books.has("cookbook") and not pyro.books.has("ice"), "замена книги")
	adv.refusals_left = 0
	var o3 := {"wizard": 0, "kind": "book", "id": "wind", "resolved": false}
	check(not adv.refuse_book(o3), "лимит отказов отряда исчерпан — отказаться нельзя")
	var boots: Dictionary = adv.equipment["pompom_slippers"]
	pyro.hp = 5.0
	pyro.equip(boots)
	check(is_equal_approx(pyro.max_hp(), 12.0) and is_equal_approx(pyro.hp, 7.0), "Тапочки: +2 к максимуму и к текущему ЗД")
	pyro.books.assign(["fire", "storm"])
	var torn := ""
	for i in 10:
		torn = pyro.record_books_used(["fire"])
	check(torn == "fire" and not pyro.books.has("fire"), "10 боёв подряд одной книгой — книга рвётся")


## Целый акт I с автоигроком: сколько приключений доходит до конца.
func test_act_simulation() -> void:
	print("Симуляция акта I (300 приключений):")
	var stats: Dictionary = load("res://tests/simulate_act.gd").run(300)
	print("       акт пройден: %.1f %%; поражения по уровням: %s" % [stats.win_rate, stats.defeats])
	check(stats.win_rate >= 15.0, "автоигрок проходит акт хотя бы в 15 %% приключений (%.1f %%)" % stats.win_rate)
