class_name Adventure
extends RefCounted
## Приключение без графики: уровни акта, отдых после боя, лут и инвентарь.
## Порядок: start_combat() → finish_combat() → rest() → roll_loot() → действия с лутом → снова бой.

const RARITY_ORDER := ["common", "rare", "epic", "legendary", "cursed"]

var books: Dictionary
var classes: Dictionary
var items: Dictionary
var equipment: Dictionary = {}  # id -> вещь
var config: Dictionary
var wizards: Array[Wizard] = []
var rng := RandomNumberGenerator.new()
var level := 1  # номер следующего боя
var refusals_left: int
var offers: Array[Dictionary] = []
var resurrection_dropped := false
var unlocked_classes: Array = ["pyromancer", "priest", "water"]
var _plan: Array[String] = []


func _init(party: Array, seed_value: int = 0, act_id: String = "act1") -> void:
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	books = GameData.load_books()
	classes = GameData.load_classes()
	items = GameData.load_json("res://data/items.json")
	for e in GameData.load_json("res://data/equipment.json").items:
		equipment[e.id] = e
	config = GameData.load_json("res://data/adventure/%s.json" % act_id)
	refusals_left = int(config.refusals)
	for cid in party:
		wizards.append(Wizard.new(cid, classes[cid], equipment))
	_plan_levels()


func _plan_levels() -> void:
	var used := {}
	for options in config.levels:
		var free: Array = options.filter(func(o: String) -> bool: return not used.has(o))
		if free.is_empty():
			free = options
		var pick: String = free[rng.randi_range(0, free.size() - 1)]
		used[pick] = true
		_plan.append(pick)


func level_count() -> int:
	return _plan.size()


func is_last_level() -> bool:
	return level >= level_count()


func encounter() -> Dictionary:
	return GameData.load_encounter(_plan[level - 1])


func start_combat(seed_value: int = 0) -> Combat:
	return Combat.new(books, wizards, encounter(), seed_value, items,
		int(config.fortify_turns), float(config.fortify_decay))


## Записывает итоги боя в волшебников. Возвращает порванные книги: [{wizard, book}].
func finish_combat(c: Combat) -> Array:
	var torn := []
	for u in c.units:
		if u.wizard == null:
			continue
		u.wizard.hp = u.hp
		var b := u.wizard.record_books_used(u.books_used.keys())
		if b != "":
			torn.append({"wizard": u.wizard, "book": b})
	if c.outcome == "victory":
		level += 1
	return torn


# --- Отдых ---------------------------------------------------------------

## Лечит живых на 75 % максимума. Излишек сверх максимума × 10 % → Укрепление.
func rest() -> Array:
	var out := []
	for w in wizards:
		if not w.alive():
			out.append({"wizard": w, "healed": 0.0, "fortify": 0.0, "dead": true})
			continue
		var mx := w.max_hp()
		var total := w.hp + mx * float(config.rest_heal)
		var healed := minf(total, mx) - w.hp
		w.fortify = maxf(0.0, total - mx) * float(config.fortify_rate)
		w.hp = minf(total, mx)
		out.append({"wizard": w, "healed": healed, "fortify": w.fortify, "dead": false})
	return out


# --- Выпадение лута -----------------------------------------------------

func roll_loot() -> Array[Dictionary]:
	offers.clear()
	for i in wizards.size():
		var w := wizards[i]
		var kind := "book" if w.books.size() <= 1 else _weighted(config.loot_kind)
		offers.append(_make_offer(i, kind))
	# Гарантия: свиток или зелье воскрешения до уровня N.
	if not resurrection_dropped and level >= int(config.resurrection_guarantee_level) - 1:
		var i := rng.randi_range(0, offers.size() - 1)
		offers[i] = {"wizard": i, "kind": "item", "id": "scroll_resurrect", "resolved": false}
	for o in offers:
		if o.kind == "item" and items[o.id].get("resurrection", false):
			resurrection_dropped = true
	_auto_resolve_destroyed()
	return offers


func _make_offer(i: int, kind: String) -> Dictionary:
	var id := ""
	match kind:
		"book":
			id = _roll_book()
		"item":
			id = _weighted_item()
		"equipment":
			id = _roll_equipment()
	return {"wizard": i, "kind": kind, "id": id, "resolved": false}


func _roll_book() -> String:
	var rarity := _weighted(config.book_rarity)
	var pool := book_pool()
	for r in _rarities_from(rarity):
		var cands: Array = pool.filter(func(b: String) -> bool: return books[b].rarity == r)
		if not cands.is_empty():
			return cands[rng.randi_range(0, cands.size() - 1)]
	return pool[0]


## Книги, которые могут выпасть: книги лута и книги открытых классов.
func book_pool() -> Array:
	var class_books := {}
	for cid in unlocked_classes:
		for b in classes[cid].books:
			class_books[b] = true
	var out := []
	for id in books:
		var b: Dictionary = books[id]
		if not b.get("loot", true):
			continue
		if b.get("class") == null or class_books.has(id):
			out.append(id)
	out.sort()
	return out


func _roll_equipment() -> String:
	var rarity := _weighted(config.equipment_rarity)
	for r in _rarities_from(rarity):
		var cands := []
		for id in equipment:
			if equipment[id].rarity == r:
				cands.append(id)
		if not cands.is_empty():
			cands.sort()
			return cands[rng.randi_range(0, cands.size() - 1)]
	return equipment.keys()[0]


func _weighted_item() -> String:
	var weights := {}
	for id in items:
		weights[id] = int(items[id].weight)
	return _weighted(weights)


## Если редкости нет в пуле — пробуем более низкие.
func _rarities_from(rarity: String) -> Array:
	var idx := RARITY_ORDER.find(rarity)
	var out := [rarity]
	for i in range(idx - 1, -1, -1):
		out.append(RARITY_ORDER[i])
	return out


func _weighted(weights: Dictionary) -> String:
	var total := 0
	for k in weights:
		total += int(weights[k])
	var roll := rng.randi_range(1, total)
	for k in weights:
		roll -= int(weights[k])
		if roll <= 0:
			return k
	return weights.keys()[0]


## Священник уничтожает выпавший ему Некрономикон сразу.
func _auto_resolve_destroyed() -> void:
	for o in offers:
		var w := wizards[o.wizard]
		if o.kind == "book" and w.destroys_forbidden and not w.can_use_book(o.id):
			o.resolved = true
			o.note = "%s уничтожает «%s»." % [w.name, books[o.id].name]


func all_resolved() -> bool:
	return offers.all(func(o: Dictionary) -> bool: return o.resolved)


func offer_name(o: Dictionary) -> String:
	match String(o.kind):
		"book":
			return books[o.id].name
		"item":
			return items[o.id].name
		"equipment":
			return equipment[o.id].name
	return o.id


# --- Действия с лутом ----------------------------------------------------

func can_take_book(w: Wizard, book_id: String) -> bool:
	return w.can_use_book(book_id) and w.free_book_slots() > 0


func take_book(o: Dictionary, replace: String = "") -> bool:
	var w := wizards[o.wizard]
	if not w.can_use_book(o.id):
		return false
	if replace != "":
		if not w.books.has(replace):
			return false
		w.books[w.books.find(replace)] = o.id
		if w.wear_book == replace:
			w.wear_book = ""
			w.wear_streak = 0
	elif w.free_book_slots() > 0:
		w.books.append(o.id)
	else:
		return false
	o.resolved = true
	return true


func can_give_book(to: Wizard, book_id: String) -> bool:
	return to.can_use_book(book_id) and to.free_book_slots() > 0


func give_offer_book(o: Dictionary, to: Wizard) -> bool:
	if not can_give_book(to, o.id):
		return false
	to.books.append(o.id)
	o.resolved = true
	return true


## Отказ от книги. Книгу, которой владелец пользоваться не может, выбросить можно без лимита.
func can_refuse_book(o: Dictionary) -> bool:
	var w := wizards[o.wizard]
	if w.books.is_empty():
		return false
	return not w.can_use_book(o.id) or refusals_left > 0


func refuse_book(o: Dictionary) -> bool:
	if not can_refuse_book(o):
		return false
	if wizards[o.wizard].can_use_book(o.id):
		refusals_left -= 1
	o.resolved = true
	return true


## Предмет: берёт себе (старый выбрасывается).
func take_item(o: Dictionary) -> void:
	wizards[o.wizard].item = o.id
	o.resolved = true


func give_offer_item(o: Dictionary, to: Wizard) -> bool:
	if to.item != "":
		return false
	to.item = o.id
	o.resolved = true
	return true


func equip_offer(o: Dictionary, to: Wizard = null) -> void:
	var w := to if to else wizards[o.wizard]
	w.equip(equipment[o.id])
	o.resolved = true


## Предметы и вещи выбрасываются без лимита.
func discard_offer(o: Dictionary) -> void:
	o.resolved = true


# --- Инвентарь на привале ------------------------------------------------

func give_book(from: Wizard, book_id: String, to: Wizard) -> bool:
	if from.books.size() <= 1 or not can_give_book(to, book_id):
		return false
	from.books.erase(book_id)
	to.books.append(book_id)
	return true


func discard_book(w: Wizard, book_id: String) -> bool:
	if w.books.size() <= 1:
		return false
	w.books.erase(book_id)
	return true


func give_item(from: Wizard, to: Wizard) -> bool:
	if from.item == "" or to.item != "":
		return false
	to.item = from.item
	from.item = ""
	return true


## Кого можно выбрать целью предмета на привале.
func camp_item_targets(owner: Wizard) -> Array[Wizard]:
	var out: Array[Wizard] = []
	if owner.item == "":
		return out
	var it: Dictionary = items[owner.item]
	if not (it.get("camp", false) or it.get("camp_only", false)):
		return out
	match String(it.target):
		"self":
			out.append(owner)
		"ally":
			out.assign(wizards.filter(func(w: Wizard) -> bool: return w.alive()))
		"dead_ally":
			out.assign(wizards.filter(func(w: Wizard) -> bool: return not w.alive()))
	return out


func use_item_camp(owner: Wizard, target: Wizard) -> String:
	if not camp_item_targets(owner).has(target):
		return ""
	var it: Dictionary = items[owner.item]
	var e: Dictionary = it.effect
	owner.item = ""
	if e.has("revive") and not target.alive():
		target.hp = minf(target.max_hp(), float(e.revive))
	if e.has("heal") and target.alive():
		target.hp = minf(target.max_hp(), target.hp + float(e.heal))
	if e.get("reset_wear", false):
		target.wear_book = ""
		target.wear_streak = 0
	return "%s использует «%s» → %s." % [owner.name, it.name, target.name]
