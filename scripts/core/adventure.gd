class_name Adventure
extends RefCounted
## Приключение без графики: уровни акта, отдых после боя, лут и инвентарь.
## Порядок: start_combat() → finish_combat() → rest() → roll_loot() → действия с лутом → снова бой.

const RARITY_ORDER := ["common", "rare", "epic", "legendary", "cursed"]
## После победы выбывшие поднимаются с этой долей здоровья и Разбитостью.
const REVIVE_HP := 0.5
const ACHING_TURNS := 10

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
var last_was_boss := false  # был ли последний пройденный бой с боссом
var unlocked_classes: Array = []
## Карта акта: дерево локаций. Узел: {id, level, encounter, site, children: [id], parents: [id]}.
## После каждого уровня отряд выбирает одного из двух потомков текущего узла —
## вторая ветка со всеми продолжениями закрывается.
var map_nodes: Array[Dictionary] = []
var node_id := 0  # узел текущего (или только что пройденного) боя
var path: Array[int] = [0]


func _init(party: Array, seed_value: int = 0, act_id: String = "act1", unlocked: Array = []) -> void:
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
	unlocked_classes = unlocked.duplicate()
	if unlocked_classes.is_empty():
		for cid in classes:
			if classes[cid].get("unlocked", false):
				unlocked_classes.append(cid)
	for cid in party:
		wizards.append(Wizard.new(cid, classes[cid], equipment))
		if not unlocked_classes.has(cid):
			unlocked_classes.append(cid)
	_build_map()


# --- Карта ----------------------------------------------------------------

## Строит дерево: у каждого узла два потомка с разными бандами (если пул уровня позволяет),
## банды не повторяются на одном пути. Если на уровне одна банда (босс акта) —
## все ветки сходятся в один узел.
func _build_map() -> void:
	map_nodes.clear()
	var levels: Array = config.levels
	var root := _new_node(1, _pick_encounter(levels[0], []), [])
	var frontier: Array[int] = [root]
	for li in range(1, levels.size()):
		var pool: Array = levels[li]
		var next: Array[int] = []
		if pool.size() == 1:
			var shared := _new_node(li + 1, pool[0], frontier)
			for p in frontier:
				map_nodes[p].children.append(shared)
			next.append(shared)
		else:
			for p in frontier:
				var taken := _path_encounters(p)
				for k in 2:
					var avoid := taken.duplicate()
					for c in map_nodes[p].children:
						avoid.append(map_nodes[c].encounter)
					var child := _new_node(li + 1, _pick_encounter(pool, avoid), [p])
					map_nodes[p].children.append(child)
					next.append(child)
		frontier = next


func _new_node(lvl: int, enc: String, parents: Array) -> int:
	var id := map_nodes.size()
	var site := "path" if lvl == 1 or parents.size() > 1 else _weighted(_site_weights())
	map_nodes.append({"id": id, "level": lvl, "encounter": enc, "site": site,
		"children": [], "parents": parents.duplicate()})
	return id


func _site_weights() -> Dictionary:
	var out := {}
	var sites: Dictionary = config.get("sites", {})
	for k in sites:
		out[k] = int(sites[k].get("weight", 1))
	return out if not out.is_empty() else {"path": 1}


func _pick_encounter(pool: Array, avoid: Array) -> String:
	var free: Array = pool.filter(func(o: String) -> bool: return not avoid.has(o))
	if free.is_empty():
		free = pool.filter(func(o: String) -> bool: return o != avoid.back()) if not avoid.is_empty() else pool
	if free.is_empty():
		free = pool
	return free[rng.randi_range(0, free.size() - 1)]


## Банды на пути от старта до узла (включительно).
func _path_encounters(id: int) -> Array:
	var out := []
	var cur := id
	while true:
		out.append(map_nodes[cur].encounter)
		if map_nodes[cur].parents.is_empty():
			break
		cur = map_nodes[cur].parents[0]
	return out


func node() -> Dictionary:
	return map_nodes[node_id]


## Нужно ли выбрать следующую локацию (после победы, перед следующим боем).
func needs_choice() -> bool:
	return node().level < level and not node().children.is_empty()


## Куда можно пойти дальше.
func choices() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if needs_choice():
		for c in node().children:
			out.append(map_nodes[c])
	return out


func choose(id: int) -> bool:
	if not needs_choice() or not node().children.has(id):
		return false
	node_id = id
	path.append(id)
	return true


## Узел закрыт: он не на пройденном пути и до него уже не дойти.
func is_closed(id: int) -> bool:
	if path.has(id):
		return false
	return not _reachable_from(node_id).has(id)


func _reachable_from(id: int) -> Dictionary:
	var out := {}
	var stack: Array = [id]
	while not stack.is_empty():
		var cur: int = stack.pop_back()
		for c in map_nodes[cur].children:
			if not out.has(c):
				out[c] = true
				stack.append(c)
	return out


## Видно ли, какая банда ждёт в узле: пройденный путь и два уровня вперёд.
func is_revealed(id: int) -> bool:
	return path.has(id) or map_nodes[id].level <= level + 1 or map_nodes[id].parents.size() > 1


## Без выбора игрока (симуляторы, автоигрок) — случайная ветка.
func _ensure_node() -> void:
	while needs_choice():
		var ch: Array = node().children
		choose(ch[rng.randi_range(0, ch.size() - 1)])


func site_info(site: String) -> Dictionary:
	return config.get("sites", {}).get(site, {"name": "Дорога"})


## Банда узла с усилением под отряд — для превью на карте.
func node_encounter(id: int) -> Dictionary:
	return Adventure.scale_encounter(GameData.load_encounter(map_nodes[id].encounter), wizards.size(), config)


func level_count() -> int:
	return config.levels.size()


func is_last_level() -> bool:
	return level >= level_count()


## Банда следующего боя. Если игрок не выбрал путь — ветка выбирается случайно.
func encounter() -> Dictionary:
	_ensure_node()
	return node_encounter(node_id)


## Усиление врагов под размер отряда (настройки — config.party_scaling["<размер>"]):
## hp — множитель здоровья всех врагов, extra_members — сколько рядовых добавить
## (копии первого рядового), boss_hp — отдельный множитель для боссов.
static func scale_encounter(enc: Dictionary, party_size: int, cfg: Dictionary) -> Dictionary:
	var rule: Dictionary = cfg.get("party_scaling", {}).get(str(party_size), {})
	var base: Dictionary = cfg.get("enemy_scaling", {})
	if rule.is_empty() and base.is_empty():
		return enc
	var out: Dictionary = enc.duplicate(true)
	var grunt: Dictionary = {}
	for m in out.members:
		var boss: bool = m.get("boss", false)
		var mult := float(rule.get("boss_hp", rule.get("hp", 1.0))) if boss else float(rule.get("hp", 1.0))
		mult *= float(base.get("boss_hp", base.get("hp", 1.0))) if boss else float(base.get("hp", 1.0))
		m.hp = maxi(1, roundi(float(m.hp) * mult))
		if grunt.is_empty() and not m.get("leader", false) and not m.get("boss", false):
			grunt = m
	for i in int(rule.get("extra_members", 0)):
		if not grunt.is_empty():
			out.members.append(grunt.duplicate(true))
	return out


func start_combat(seed_value: int = 0) -> Combat:
	return Combat.new(books, wizards, encounter(), seed_value, items,
		int(config.fortify_turns), float(config.fortify_decay))


## Записывает итоги боя в волшебников. Возвращает порванные книги: [{wizard, book}].
func finish_combat(c: Combat) -> Array:
	var torn := []
	last_was_boss = false
	for u in c.units:
		if u.is_boss:
			last_was_boss = true
		if u.wizard == null:
			continue
		var w := u.wizard
		w.hp = u.hp
		w.carry_statuses.clear()
		if u.has("aching"):
			w.carry_statuses["aching"] = u.statuses.aching.turns
		var b := w.record_books_used(u.books_used.keys())
		if b != "":
			torn.append({"wizard": w, "book": b})
		# Победа: выбывший поднимается с 50 % ЗД и Разбитостью на 10 ходов.
		if c.outcome == "victory" and not w.alive():
			w.hp = Unit.q(w.max_hp() * REVIVE_HP)
			w.carry_statuses["aching"] = ACHING_TURNS
			w.just_revived = true
	if c.outcome == "victory":
		level += 1
	return torn


# --- Отдых ---------------------------------------------------------------

## Лечит живых на 75 % максимума. Излишек сверх максимума × 10 % → Укрепление.
func rest() -> Array:
	var out := []
	for w in wizards:
		if w.just_revived:
			w.just_revived = false
			out.append({"wizard": w, "healed": 0.0, "fortify": 0.0, "dead": false, "revived": true})
			continue
		if not w.alive():
			out.append({"wizard": w, "healed": 0.0, "fortify": 0.0, "dead": true})
			continue
		var mx := w.max_hp()
		var total := w.hp + mx * float(config.rest_heal)
		var healed := Unit.q(minf(total, mx) - w.hp)
		w.fortify = Unit.q(maxf(0.0, total - mx) * float(config.fortify_rate))
		w.hp = Unit.q(minf(total, mx))
		out.append({"wizard": w, "healed": healed, "fortify": w.fortify, "dead": false})
	return out


# --- Выпадение лута -----------------------------------------------------

## Лут после пройденного уровня:
## - после 1-го уровня и после босса: каждому +1 книга и +1 шляпа/ботинки;
##   после босса ещё и расходуемый предмет с шансом 20 % каждому;
## - после остальных уровней: каждому +1 книга ИЛИ +1 расходуемый предмет
##   (у кого одна книга — всегда книга).
## boss — был ли пройденный уровень боссом (по умолчанию — из последнего боя).
func roll_loot(boss: Variant = null) -> Array[Dictionary]:
	offers.clear()
	var was_boss: bool = last_was_boss if boss == null else bool(boss)
	var big := level - 1 == 1 or was_boss
	for i in wizards.size():
		var w := wizards[i]
		if big:
			offers.append(_make_offer(i, "book"))
			offers.append(_make_offer(i, "equipment"))
			if was_boss and rng.randf() < float(config.get("boss_item_chance", 0.2)):
				offers.append(_make_offer(i, "item"))
		else:
			var kind := "book" if w.books.size() <= 1 else _weighted(loot_kind())
			offers.append(_make_offer(i, kind))
	# Гарантия: свиток или зелье воскрешения до уровня N.
	if not resurrection_dropped and level >= int(config.resurrection_guarantee_level) - 1:
		var i := rng.randi_range(0, wizards.size() - 1)
		offers.append({"wizard": i, "kind": "item", "id": "scroll_resurrect", "resolved": false})
	for o in offers:
		if o.kind == "item" and items[o.id].get("resurrection", false):
			resurrection_dropped = true
	_auto_resolve_destroyed()
	return offers


## Что выпадает на обычном уровне: книга или предмет. Локация может сдвигать шансы
## (в библиотеке чаще книги, в погребе — предметы).
func loot_kind() -> Dictionary:
	return site_info(node().site).get("loot_kind", config.loot_kind)


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
		target.hp = Unit.q(minf(target.max_hp(), float(e.revive)))
	if e.has("heal") and target.alive():
		target.hp = Unit.q(minf(target.max_hp(), target.hp + float(e.heal)))
		target.carry_statuses.erase("aching")  # положительный эффект снимает Разбитость
	if e.get("reset_wear", false):
		target.wear_book = ""
		target.wear_streak = 0
	return "%s использует «%s» → %s." % [owner.name, it.name, target.name]
