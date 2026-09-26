extends SceneTree
## Тесты без окна:
##   godot --headless --path . --script res://tests/run_tests.gd
## Код выхода 0 — всё прошло, 1 — есть ошибки.

var failures := 0


func _initialize() -> void:
	var books := GameData.load_books()
	test_books_loaded(books)
	test_chaos_odds(books)
	test_combo_odds(books)
	test_parser_coverage(books)
	test_rat_pack_simulation(books)
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
	for id in ["fire", "water", "holy"]:
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
	var classes := GameData.load_classes()
	var encounter := GameData.load_encounter("rat_pack")
	var wins := 0
	var turns := 0
	var hp_left := 0.0
	var n := 2000
	for i in n:
		var c := Combat.new(books, ["pyromancer", "priest", "water"], classes, encounter, i + 1)
		var result := AutoPlayer.play(c)
		turns += c.turn_count
		if result == "victory":
			wins += 1
			for u in c.living(Unit.PARTY):
				hp_left += u.hp
	var rate := 100.0 * wins / n
	print("       побед: %.1f %%, ходов в бою: %.1f, ЗД отряда после победы: %.1f из 28"
		% [rate, float(turns) / n, hp_left / maxi(1, wins)])
	check(rate >= 90.0, "уровень 1 проходится в ≥ 90 %% боёв (%.1f %%)" % rate)
