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
	test_parser_coverage(books)
	test_rat_pack_simulation(books)
	test_rest_and_fortify()
	test_loot_rules()
	test_map()
	test_revive_after_battle()
	test_party_scaling()
	test_profile_unlocks()
	test_bard_and_paladin()
	test_dead_tongue_cost()
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
	# Картинки, которые ещё только ждут генерации (игра рисует заглушку).
	var pending := ["muse.png", "dead_poison.png"]
	for g in groups:
		var missing: Array = groups[g].filter(func(p): return not ResourceLoader.exists(p) or load(p) == null)
		var waiting: Array = missing.filter(func(p): return pending.has(p.get_file()))
		missing = missing.filter(func(p): return not pending.has(p.get_file()))
		if not waiting.is_empty():
			print("       %s: ждут картинку — %s" % [g, ", ".join(PackedStringArray(waiting.map(func(p): return p.get_file())))])
		check(missing.is_empty(), "%s: %d из %d%s" % [g, groups[g].size() - missing.size() - waiting.size(), groups[g].size(),
			"" if missing.is_empty() else " — нет: " + ", ".join(PackedStringArray(missing.map(func(p): return p.get_file()))) ])
	var chars := 0
	for cid in GameData.load_classes():
		for st in ["healthy", "hurt", "critical", "zombie"]:
			if ResourceLoader.exists("res://assets/characters/%s_%s.png" % [cid, st]):
				chars += 1
	print("       персонажи: %d из %d (пока необязательно)" % [chars, GameData.load_classes().size() * 4])


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
