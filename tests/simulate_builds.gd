extends SceneTree
## Баланс с учётом лута: насколько исход боя зависит от выпавших книг и вещей.
##   godot --headless --path . --script res://tests/simulate_builds.gd -- builds=150 fights=30 n=200 size=3
##
## Часть 1 — «Разброс сборок»: для каждой банды акта I собираем случайные отряды
##   (3 разных класса из 6) и прогоняем реальный лут до её уровня (roll_loot + решения автоигрока),
##   затем каждая сборка дерётся fights раз с полным здоровьем. Показываем разброс побед
##   от худшей сборки до лучшей.
## Часть 2 — «Цена находки»: стартовый отряд (Пиромант, Священник, Водник) против банд
##   уровней 3–5; каждому, кто может, даём одну и ту же книгу (или надеваем вещь на всех троих)
##   и сравниваем с отрядом без неё. Так видно, какие книги и вещи ломают баланс.

const CLASSES := ["pyromancer", "priest", "water", "magus", "bard", "paladin"]
const BASE_PARTY := ["pyromancer", "priest", "water"]

var cfg: Dictionary
var books: Dictionary
var classes: Dictionary
var items: Dictionary
var equipment: Dictionary = {}


func _initialize() -> void:
	OS.low_processor_usage_mode = false
	var args := {"builds": "150", "fights": "30", "n": "200", "size": "3", "part": "all"}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	cfg = GameData.load_json("res://data/adventure/act1.json")
	books = GameData.load_books()
	classes = GameData.load_classes()
	items = GameData.load_json("res://data/items.json")
	for e in GameData.load_json("res://data/equipment.json").items:
		equipment[e.id] = e
	if args.part in ["all", "spread"]:
		spread(int(args.builds), int(args.fights), int(args.size))
	if args.part in ["all", "finds"]:
		finds(int(args.n))
	quit()


# --- Часть 1 --------------------------------------------------------------

## Банды акта и первый уровень, на котором каждая встречается.
func encounter_levels() -> Array:
	var out := []
	var seen := {}
	for li in cfg.levels.size():
		for e in cfg.levels[li]:
			if not seen.has(e):
				seen[e] = true
				out.append([e, li + 1])
	return out


func spread(n_builds: int, fights: int, size: int) -> void:
	print("=== Часть 1. Разброс сборок: отряд из %d, %d сборок × %d боёв на банду ===" % [size, n_builds, fights])
	print("Сборка = случайные классы + лут, выпавший к этому уровню. Бой с полным здоровьем.")
	print("")
	print("| Банда | Ур. | Худшая | 10 % | Медиана | 90 % | Лучшая | В среднем |")
	print("|---|---|---|---|---|---|---|---|")
	var extremes := []
	for pair in encounter_levels():
		var enc_id: String = pair[0]
		var lvl: int = pair[1]
		var enc := Adventure.scale_encounter(GameData.load_encounter(enc_id), size, cfg)
		var results := []
		for b in n_builds:
			var adv := build(b * 7919 + lvl, size, lvl)
			var rate := fight_many(adv.wizards, enc, fights, b * 1000)
			results.append({"rate": rate, "desc": describe(adv)})
		results.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.rate < y.rate)
		var rates: Array = results.map(func(r: Dictionary) -> float: return r.rate)
		var mean := 0.0
		for r in rates:
			mean += r
		mean /= rates.size()
		print("| %s | %d | %s | %s | %s | %s | %s | %s |" % [enc.name, lvl, pct(rates[0]), pct(q(rates, 0.1)),
			pct(q(rates, 0.5)), pct(q(rates, 0.9)), pct(rates.back()), pct(mean)])
		extremes.append([enc.name, results[0], results.back()])
	print("")
	print("Крайние сборки:")
	for e in extremes:
		print("  %s" % e[0])
		print("    худшая (%s): %s" % [pct(e[1].rate), e[1].desc])
		print("    лучшая (%s): %s" % [pct(e[2].rate), e[2].desc])
	print("")


## Случайный отряд и лут, собранный за уровни 1..lvl-1 (без боёв).
func build(seed_value: int, size: int, lvl: int) -> Adventure:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pool := CLASSES.duplicate()
	var party := []
	while party.size() < size:
		party.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	var adv := Adventure.new(party, seed_value, "act1", CLASSES)
	for l in range(2, lvl + 1):
		adv.level = l
		adv.roll_loot(false)
		AutoPlayer.camp(adv)
	return adv


func describe(adv: Adventure) -> String:
	var parts := []
	for w in adv.wizards:
		var gear := []
		for id in [w.hat, w.boots]:
			if id != "":
				gear.append(equipment[id].name)
		var bk: Array = w.books.map(func(b: String) -> String: return books[b].name)
		parts.append("%s [%s%s]" % [w.name, ", ".join(bk), "; " + ", ".join(gear) if not gear.is_empty() else ""])
	return " · ".join(parts)


## Доля побед сборки: n боёв с полным здоровьем, предмет возвращается после каждого боя.
func fight_many(wizards: Array[Wizard], enc: Dictionary, n: int, seed_base: int) -> float:
	var wins := 0
	var kept := []
	for w in wizards:
		kept.append(w.item)
	for i in n:
		for k in wizards.size():
			var w := wizards[k]
			w.hp = w.max_hp()
			w.fortify = 0.0
			w.carry_statuses.clear()
			w.item = kept[k]
		var c := Combat.new(books, wizards, enc, seed_base + i + 1, items)
		if AutoPlayer.play(c) == "victory":
			wins += 1
	return 100.0 * wins / n


# --- Часть 2 --------------------------------------------------------------

func finds(n: int) -> void:
	var encs := []
	for pair in encounter_levels():
		if pair[1] >= 3:
			encs.append(Adventure.scale_encounter(GameData.load_encounter(pair[0]), 3, cfg))
	var names: Array = encs.map(func(e: Dictionary) -> String: return e.name)
	print("=== Часть 2. Цена находки: стартовый отряд, %d боёв на банду ===" % n)
	print("Банды: %s." % ", ".join(names))
	var base := finds_row(func(_w: Wizard) -> void: pass, encs, n)
	print("Без находок: в среднем %s" % pct(base.mean))
	print("")

	var adv := Adventure.new(BASE_PARTY, 1, "act1", CLASSES)
	var book_rows := []
	for id in adv.book_pool():
		var holders := 0
		for cid in BASE_PARTY:
			var w := Wizard.new(cid, classes[cid], equipment)
			if w.can_use_book(id) and not w.books.has(id):
				holders += 1
		if holders == 0:
			continue
		var r := finds_row(func(w: Wizard) -> void:
			if w.can_use_book(id) and not w.books.has(id) and w.free_book_slots() > 0:
				w.books.append(id), encs, n)
		book_rows.append([books[id].name, books[id].rarity, holders, r])
	book_rows.sort_custom(func(a: Array, b: Array) -> bool: return a[3].mean > b[3].mean)
	print("Книга выдана каждому, кто может ею пользоваться (кастуют по очереди со своей):")
	print("")
	print("| Книга | Редкость | Кому | %s | В среднем | Разница |" % " | ".join(names))
	print("|---|---|---|%s---|---|" % "---|".repeat(names.size()))
	for row in book_rows:
		print("| %s | %s | %d из 3 | %s | %s | %s |" % [row[0], row[1], row[2],
			" | ".join(row[3].rates.map(func(x: float) -> String: return pct(x))), pct(row[3].mean), delta(row[3].mean - base.mean)])
	print("")

	var eq_rows := []
	for id in equipment:
		var e: Dictionary = equipment[id]
		var r := finds_row(func(w: Wizard) -> void: w.equip(e), encs, n)
		eq_rows.append([e.name, e.rarity, r])
	eq_rows.sort_custom(func(a: Array, b: Array) -> bool: return a[2].mean > b[2].mean)
	print("Вещь надета на всех троих (эффект ×3 — чтобы разница была заметна):")
	print("")
	print("| Вещь | Редкость | В среднем | Разница |")
	print("|---|---|---|---|")
	for row in eq_rows:
		print("| %s | %s | %s | %s |" % [row[0], row[1], pct(row[2].mean), delta(row[2].mean - base.mean)])
	print("")


func finds_row(modify: Callable, encs: Array, n: int) -> Dictionary:
	var rates := []
	for ei in encs.size():
		var wizards: Array[Wizard] = []
		for cid in BASE_PARTY:
			var w := Wizard.new(cid, classes[cid], equipment)
			modify.call(w)
			wizards.append(w)
		rates.append(fight_many(wizards, encs[ei], n, ei * 100000))
	var mean := 0.0
	for r in rates:
		mean += r
	return {"rates": rates, "mean": mean / rates.size()}


# --- Разное ---------------------------------------------------------------

static func q(sorted: Array, p: float) -> float:
	return sorted[clampi(roundi(p * (sorted.size() - 1)), 0, sorted.size() - 1)]


static func pct(x: float) -> String:
	return "%.0f %%" % x


static func delta(x: float) -> String:
	return "%+.0f" % x
