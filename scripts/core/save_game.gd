class_name SaveGame
extends RefCounted
## Сохранение приключения: можно выйти из игры и продолжить с того же места.
## Точки сохранения — начало боя, привал, карта, выбор трофея. Бой, прерванный на середине,
## начинается заново (с тем же отрядом и той же бандой). После конца приключения сохранение удаляется.

const VERSION := 1

static var path := "user://adventure.json"


static func exists() -> bool:
	return FileAccess.file_exists(path)


static func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## screen — где продолжить: "battle", "camp", "map", "trophy"; extra — данные этого экрана.
static func write(adv: Adventure, screen: String, extra: Dictionary = {}) -> void:
	if not adv.owners.is_empty():
		return  # сетевую игру не сохраняем: продолжить её в одиночку нельзя
	var data := {"version": VERSION, "screen": screen, "extra": extra, "adventure": dump(adv)}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))


## {"adventure": Adventure, "screen": String, "extra": Dictionary} или {} если сохранения нет или оно битое.
static func read() -> Dictionary:
	if not exists():
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary) or int(data.get("version", 0)) != VERSION:
		return {}
	var adv := restore(data.adventure)
	if adv == null:
		return {}
	return {"adventure": adv, "screen": String(data.screen), "extra": data.get("extra", {})}


## Краткое описание для кнопки «Продолжить».
static func summary() -> String:
	if not exists():
		return ""
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary) or not data.has("adventure"):
		return ""
	var a: Dictionary = data.adventure
	var classes := GameData.load_classes()
	var names: Array = a.wizards.map(func(w: Dictionary) -> String: return classes.get(w.class_id, {}).get("name", w.class_id))
	return "уровень %d · %s" % [int(a.level), ", ".join(names)]


# --- Приключение ↔ словарь --------------------------------------------------

static func dump(adv: Adventure) -> Dictionary:
	var wizards := []
	for w in adv.wizards:
		wizards.append({
			"class_id": w.class_id, "hp": w.hp, "fortify": w.fortify,
			"carry_statuses": w.carry_statuses, "just_revived": w.just_revived,
			"books": w.books, "item": w.item, "hat": w.hat, "boots": w.boots,
			"wear_book": w.wear_book, "wear_streak": w.wear_streak,
			"trophies": w.trophies, "scars": w.scars, "no_item_battle": w.no_item_battle,
			"zombie": w.zombie, "sheep_broken": w.sheep_broken, "item2": w.item2,
			"max_books": w.max_books, "base_hp": w.base_hp,
		})
	var offers := []
	for o in adv.offers:
		offers.append(o.duplicate())
	return {
		"act": adv.act_id, "rng_state": str(adv.rng.state), "level": adv.level,
		"refusals_left": adv.refusals_left, "resurrection_dropped": adv.resurrection_dropped,
		"last_was_boss": adv.last_was_boss, "unlocked_classes": adv.unlocked_classes,
		"map_nodes": adv.map_nodes, "node_id": adv.node_id, "path": adv.path,
		"trophy_boss": adv.trophy_boss, "run": adv.run, "run_stats": adv.run_stats, "earned": adv.earned,
		"patron_due": adv.patron_due.map(func(w: Wizard) -> int: return adv.wizards.find(w)),
		"offers": offers, "wizards": wizards,
	}


static func restore(d: Dictionary) -> Adventure:
	var classes := GameData.load_classes()
	var party := []
	for w in d.get("wizards", []):
		if not classes.has(w.get("class_id", "")):
			return null
		party.append(w.class_id)
	if party.is_empty():
		return null
	var adv := Adventure.new(party, 1, String(d.get("act", "act1")), d.get("unlocked_classes", []))
	adv.rng.state = int(String(d.get("rng_state", "0")))
	adv.level = int(d.level)
	adv.refusals_left = int(d.refusals_left)
	adv.resurrection_dropped = bool(d.resurrection_dropped)
	adv.last_was_boss = bool(d.last_was_boss)
	adv.map_nodes.clear()
	for n in d.map_nodes:
		adv.map_nodes.append({
			"id": int(n.id), "level": int(n.level), "encounter": String(n.encounter), "site": String(n.site),
			"children": n.children.map(func(x: Variant) -> int: return int(x)),
			"parents": n.parents.map(func(x: Variant) -> int: return int(x)),
		})
	adv.node_id = int(d.node_id)
	adv.path.assign(d.path.map(func(x: Variant) -> int: return int(x)))
	adv.trophy_boss = String(d.get("trophy_boss", ""))
	var run: Dictionary = d.get("run", {})
	for k in adv.run:
		if run.has(k):
			adv.run[k] = run[k] if k == "books_cast" else int(run[k])
	var rs: Dictionary = d.get("run_stats", {})
	if rs.has("wizards"):
		adv.run_stats = {"wizards": rs.wizards, "chaos": rs.get("chaos", []),
			"battles": int(rs.get("battles", 0)), "kills": int(rs.get("kills", 0))}
	adv.earned.assign(d.get("earned", []))
	for i in d.get("patron_due", []):
		if int(i) >= 0 and int(i) < adv.wizards.size():
			adv.patron_due.append(adv.wizards[int(i)])
	adv.offers.clear()
	for o in d.get("offers", []):
		var offer: Dictionary = o.duplicate()
		offer.wizard = int(offer.wizard)
		adv.offers.append(offer)
	for i in adv.wizards.size():
		var w := adv.wizards[i]
		var s: Dictionary = d.wizards[i]
		w.books.assign(s.books)
		w.item = String(s.item)
		w.hat = String(s.hat)
		w.boots = String(s.boots)
		w.trophies.assign(s.get("trophies", []))
		w.scars.assign(s.get("scars", []))
		w.hp = float(s.hp)
		w.fortify = float(s.fortify)
		w.carry_statuses = {}
		for k in s.carry_statuses:
			w.carry_statuses[k] = int(s.carry_statuses[k])
		w.just_revived = bool(s.just_revived)
		w.wear_book = String(s.wear_book)
		w.wear_streak = int(s.wear_streak)
		w.no_item_battle = bool(s.get("no_item_battle", false))
		w.zombie = bool(s.get("zombie", false))
		w.sheep_broken = bool(s.get("sheep_broken", false))
		w.item2 = String(s.get("item2", ""))
		w.max_books = int(s.get("max_books", w.max_books))
		w.base_hp = float(s.get("base_hp", w.base_hp))
	return adv
