class_name AutoPlayer
extends RefCounted
## Простой ИИ волшебника: для симуляции боёв и проверки баланса.
## Лечащие книги направляет на самого раненого союзника, остальные — во врага.

const HEALING_BOOKS := ["holy", "cookbook"]
const LEAN_SAMPLES := 3000

static var _lean: Dictionary = {}


## Лечащую книгу — если кто-то ранен; иначе боевые книги по очереди (как живой игрок,
## который пробует всё, что выпало).
static func choose_book(caster: Unit, combat: Combat = null) -> String:
	var fight: Array = caster.books.filter(func(b: String) -> bool: return not HEALING_BOOKS.has(b))
	if combat != null and _someone_hurt(combat, caster) and fight.size() < caster.books.size():
		return caster.books.filter(func(b: String) -> bool: return HEALING_BOOKS.has(b))[0]
	if fight.is_empty():
		return caster.books[0]
	var counts: Dictionary = caster.get_meta("ai_casts", {})
	var pick: String = fight[0]
	for b in fight:
		if int(counts.get(b, 0)) < int(counts.get(pick, 0)):
			pick = b
	counts[pick] = int(counts.get(pick, 0)) + 1
	caster.set_meta("ai_casts", counts)
	return pick


static func choose_target(combat: Combat, caster: Unit, book_id: String) -> Unit:
	var targets := combat.valid_targets(caster)
	if HEALING_BOOKS.has(book_id):
		var best: Unit = null
		for u in targets:
			if u.side == caster.side and u.alive() and (best == null or u.hp / u.max_hp < best.hp / best.max_hp):
				best = u
		if best and best.hp < best.max_hp:
			return best
	# Цель выбирается до вытягивания фишек: книге поддержки выгоднее целить в своих.
	if book_lean(combat.books, book_id) < 0.0:
		var ally: Unit = null
		for u in targets:
			if u.side == caster.side and u.alive() and (ally == null or u.hp / u.max_hp < ally.hp / ally.max_hp):
				ally = u
		if ally:
			return ally
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
			if use_abilities(combat, u):
				continue  # ход занят способностью (Мастерская Учёного)
			if combat.outcome != "":
				break
			var casts := 1 + u.extra_casts
			u.extra_casts = 0
			for i in casts:
				if combat.outcome != "" or u.books.is_empty():
					break
				var book := combat.take_borrowed_book(u)
				if book == "":
					book = choose_book(u, combat)
				var target := combat.resolve_target(u, choose_target(combat, u, book))
				var bag := combat.new_bag(u, book, luck_plan(combat, u, book))
				# Чернокнижник: сделка на первую фишку, пока здоровья с запасом.
				if u.ability == "pact_deal" and u.hp > 6.0:
					combat.pact_deal(u, bag, Combat.letters_by_count(combat.books[book].bag)[0])
				while not bag.is_complete():
					bag.draw(combat.rng)
				_fix_chips(combat, u, bag, book, target)
				# Хаос — перевытянуть, если есть чем (Сожжение, Муза).
				if bag.chips.has(ChipBag.CHAOS) and combat.can_reroll(u):
					combat.reroll_chip(u, bag, bag.chips.find(ChipBag.CHAOS))
				combat.cast(u, target, book, bag, i == casts - 1)
				# Хрономант: неудачный каст — перемотка, и тот же волшебник кастует снова.
				if combat.outcome == "" and combat.last_cast.get("bad", false) and combat.can_rewind():
					var again := combat.rewind()
					if again == u:
						book = choose_book(u, combat)
						target = combat.resolve_target(u, choose_target(combat, u, book))
						bag = combat.new_bag(u, book)
						while not bag.is_complete():
							bag.draw(combat.rng)
						combat.cast(u, target, book, bag, i == casts - 1)
		else:
			combat.enemy_act(u)
	return combat.outcome


## Способности в начале хода. Возвращает true, если ход занят (Мастерская Учёного).
static func use_abilities(combat: Combat, u: Unit) -> bool:
	if combat.can_lay_on_hands(u):
		for t in combat.lay_on_hands_targets(u):
			if t.hp < t.max_hp * 0.5:
				combat.lay_on_hands(u, t)
				break
	if combat.can_inspire(u):
		combat.inspire(u, combat.inspire_targets(u)[0])
	if u.ability == "raise_dead" and combat.can_use_ability(u):
		combat.use_target_ability(u, combat.ability_targets(u)[0])
	if u.ability == "decoy" and combat.can_use_ability(u):
		for t in combat.ability_targets(u):
			if t.hp < t.max_hp * 0.5:
				combat.use_target_ability(u, t)
				break
	if u.ability == "workshop" and combat.can_use_ability(u) and combat.rng.randf() < 0.35:
		var critter := combat.roll_workshop()
		var foes := combat.living(Unit.ENEMIES)
		combat.use_workshop(u, critter, foes[0] if not foes.is_empty() else null)
		return true
	return false


## Тройка вытянута: если заклинание по врагу не наносит урона — Видение, Зов зверя или Всплеск.
static func _fix_chips(combat: Combat, u: Unit, bag: ChipBag, book: String, target: Unit) -> void:
	if target == null or target.side == u.side:
		return
	if _deals_damage(combat, book, bag.combo_key()):
		return
	if combat.can_use_vision(u, bag):
		for i in combat.visions.size():
			var key := ChipBag.key_for(combat.vision_chips(combat.visions[i], book))
			if _deals_damage(combat, book, key):
				combat.use_vision(u, bag, i, book)
				return
	if u.ability == "beast_call" and combat.can_use_ability(u, bag):
		combat.beast_call(u, bag, target)
	elif u.ability == "surge" and combat.can_use_ability(u, bag):
		combat.surge(u, bag)


static func _deals_damage(combat: Combat, book: String, combo: String) -> bool:
	var spec := EffectParser.parse(combat.spell_for(book, combo))
	return EffectParser.deals_damage(spec)


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
				if w.has_item_slot():
					adv.take_item(o)
				else:
					var ally_free := adv.wizards.filter(func(a: Wizard) -> bool: return a.has_item_slot())
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
	for w in adv.wizards:
		if adv.can_mix(w):
			adv.mix_items(w)
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


## Куда выгоднее целить книгой: > 0 — во врага, < 0 — в союзника.
## Считается по шансам заклинаний (Монте-Карло по мешочку): вредные заклинания
## в цель — «за врага», полезные (лечение, щит, баффы, очищение) — «за союзника».
## Заклинания по площади (все враги, вся арена) от выбора цели не зависят.
static func book_lean(books: Dictionary, book_id: String) -> float:
	if _lean.has(book_id):
		return _lean[book_id]
	var book: Dictionary = books[book_id]
	var value := {}
	for sp in book.spells:
		var spec := EffectParser.parse(sp)
		if not (spec.area == "target" or spec.area == "target_side"):
			value[sp.combo] = 0.0
			continue
		var harm: float = float(EffectParser.harm_total(spec)) + (1.0 if spec.meter < 0 or spec.strip_buffs else 0.0)
		var good: float = float(spec.heal) + spec.shield + (1.0 if spec.cleanse or spec.meter > 0 else 0.0)
		for st in spec.statuses:
			if Unit.DEBUFFS.has(st.id):
				harm += 1.0
			elif Unit.BUFFS.has(st.id):
				good += 1.0
		value[sp.combo] = harm - good
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(book_id)
	var sum := 0.0
	for i in LEAN_SAMPLES:
		var bag := ChipBag.new(book.bag)
		while not bag.is_complete():
			bag.draw(rng)
		sum += float(value.get(bag.combo_key(), 0.0))
	_lean[book_id] = sum / LEAN_SAMPLES
	return _lean[book_id]


## Шкала удачи автоигрока: всё в урон (для книг поддержки — в пользу).
static func luck_plan(combat: Combat, u: Unit, book_id: String) -> Dictionary:
	if not Luck.has_luck(u):
		return {}
	var cat := "damage" if book_lean(combat.books, book_id) >= 0.0 else "support"
	return Luck.clean(combat.books[book_id], combat.book_odds(u, book_id), {Luck.cat_key(cat): Luck.BUDGET})


## После босса: Чернокнижник платит Покровителю предметом, если он есть, иначе здоровьем.
static func pay_patrons(adv: Adventure) -> void:
	for w in adv.patron_due.duplicate():
		adv.pay_patron(w, "item" if w.item != "" else "hp")
