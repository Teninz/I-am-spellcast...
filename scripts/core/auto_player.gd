class_name AutoPlayer
extends RefCounted
## Простой ИИ волшебника: для симуляции боёв и проверки баланса.
## Лечащие книги направляет на самого раненого союзника, остальные — во врага.

const HEALING_BOOKS := ["holy", "cookbook"]


static func choose_book(caster: Unit) -> String:
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


## Играет бой до конца. Возвращает итог боя.
static func play(combat: Combat) -> String:
	var guard := 0
	while guard < 2000:
		guard += 1
		var u := combat.next_turn()
		if u == null:
			break
		if u.is_wizard():
			var book := choose_book(u)
			var target := combat.resolve_target(u, choose_target(combat, u, book))
			var bag := combat.new_bag(u, book)
			while not bag.is_complete():
				bag.draw(combat.rng)
			combat.cast(u, target, book, bag)
		else:
			combat.enemy_act(u)
	return combat.outcome
