class_name AutoPlayer
extends RefCounted
## Простой ИИ волшебника: для симуляции боёв и проверки баланса.
## Лечащие книги направляет на самого раненого союзника, остальные — во врага.

const HEALING_BOOKS := ["holy", "cookbook"]


static func choose_book(caster: Unit) -> String:
	# Лечащую книгу берём, только если кто-то ранен; иначе — первую боевую.
	for b in caster.books:
		if not HEALING_BOOKS.has(b):
			return b
	return caster.books[0]


static func choose_target(combat: Combat, caster: Unit, book_id: String) -> Unit:
	var targets := combat.valid_targets(caster)
	if HEALING_BOOKS.has(book_id):
		var best: Unit = null
		for u in targets:
			if u.side == caster.side and u.alive() and (best == null or u.hp / u.max_hp < best.hp / best.max_hp):
				best = u
		if best and best.hp < best.max_hp:
			return best
	var foes: Array[Unit] = []
	for u in targets:
		if u.side != caster.side and u.alive():
			foes.append(u)
	if foes.is_empty():
		return targets[0]
	# Добиваем самого слабого врага.
	foes.sort_custom(func(a: Unit, b: Unit) -> bool: return a.hp < b.hp)
	return foes[0]


## Использует предмет, если это явно полезно. Ход не тратится.
static func maybe_use_item(combat: Combat, u: Unit) -> void:
	if not combat.can_use_item(u):
		return
	var id := u.wizard.item
	var targets := combat.item_targets(u, id)
	match id:
		"potion_heal", "holy_water", "shield_scroll":
			for t in targets:
				if t.hp < t.max_hp * 0.4:
					combat.use_item(u, t)
					return
		"scroll_resurrect", "bomb":
			combat.use_item(u, targets[0])
		"double_cast", "sand_bag":
			combat.use_item(u, u)


## Играет бой до конца. Возвращает итог боя.
static func play(combat: Combat) -> String:
	var guard := 0
	while guard < 3000:
		guard += 1
		var u := combat.next_turn()
		if u == null:
			break
		if u.is_wizard():
			maybe_use_item(combat, u)
			if combat.outcome != "":
				break
			var casts := 1 + u.extra_casts
			u.extra_casts = 0
			for i in casts:
				if combat.outcome != "" or u.books.is_empty():
					break
				var book := choose_book(u)
				if HEALING_BOOKS.has(u.books[0]) and _someone_hurt(combat, u):
					book = u.books[0]
				var target := combat.resolve_target(u, choose_target(combat, u, book))
				var bag := combat.new_bag(u, book)
				while not bag.is_complete():
					bag.draw(combat.rng)
				combat.cast(u, target, book, bag, i == casts - 1)
		else:
			combat.enemy_act(u)
	return combat.outcome


static func _someone_hurt(combat: Combat, u: Unit) -> bool:
	for a in combat.living(u.side):
		if a.hp < a.max_hp * 0.7:
			return true
	return false


## Привал: решения по луту и предметам.
static func camp(adv: Adventure) -> void:
	for o in adv.offers:
		if o.resolved:
			continue
		var w := adv.wizards[o.wizard]
		match String(o.kind):
			"book":
				if adv.can_take_book(w, o.id):
					adv.take_book(o)
					continue
				var given := false
				for ally in adv.wizards:
					if ally != w and adv.can_give_book(ally, o.id):
						given = adv.give_offer_book(o, ally)
						break
				if given:
					continue
				if adv.can_refuse_book(o):
					adv.refuse_book(o)
				else:
					adv.take_book(o, w.books[w.books.size() - 1])
			"item":
				if w.item == "":
					adv.take_item(o)
				else:
					var ally_free := adv.wizards.filter(func(a: Wizard) -> bool: return a.item == "")
					if not ally_free.is_empty():
						adv.give_offer_item(o, ally_free[0])
					else:
						adv.discard_offer(o)
			"equipment":
				var e: Dictionary = adv.equipment[o.id]
				var target: Wizard = null
				for cand in [w] + Array(adv.wizards):
					var cur: Dictionary = cand.equipment(e.slot)
					if cur.is_empty() or _rank(e) > _rank(cur):
						target = cand
						break
				if target:
					adv.equip_offer(o, target)
				else:
					adv.discard_offer(o)
	# Лечебные предметы: воскресить выбывших, подлечить раненых.
	for w in adv.wizards:
		for t in adv.camp_item_targets(w):
			if not t.alive() or t.hp < t.max_hp() * 0.5:
				adv.use_item_camp(w, t)
				break


static func _rank(e: Dictionary) -> int:
	if e.rarity == "cursed":
		return -1  # проклятое ИИ не надевает, если есть что-то другое
	return Adventure.RARITY_ORDER.find(e.rarity)
