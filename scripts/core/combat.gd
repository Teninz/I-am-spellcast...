class_name Combat
extends RefCounted
## Логика одного боя без графики: шкала хода, касты, эффекты, предметы, ИИ противников.
## UI и тесты работают с боем только через этот класс.

## Запись журнала: kind — тип события (урон, лечение, эффект…), icon — id эффекта для иконки.
signal logged(text: String, kind: String, icon: String)
## Начало хода участника (в журнале — заголовок хода).
signal turn_started(u: Unit)
## Изменение здоровья или поглощение урона (для всплывающих чисел): kind — damage, heal, block.
signal hp_changed(u: Unit, amount: float, kind: String)
signal unit_added(u: Unit)
## Эффект наложен (для анимации «штампа» в интерфейсе).
signal status_applied(u: Unit, status_id: String)

const METER_FULL := 100.0
const FIZZLE_PER_LUCK := 0.05
const RESIST_PER_POINT := 0.1
const WATER_ELEMENTAL_CHANCE := 0.2
const DOUBLE_GRACE_CHANCE := 0.05
## Мёртвый яд (плата за Книгу Мёртвого Языка): урон за стак в начале хода.
const DEAD_POISON_DAMAGE := 0.5
## С какого числа урон или лечение считаются крупными (выделяются в журнале).
const BIG_HIT := 3.0
## Эти статусы у боссов и предводителей превращаются в Сбив шкалы на 50 %.
const HARD_CONTROL := ["stun", "petrify", "toad"]

var books: Dictionary
var items: Dictionary
var units: Array[Unit] = []
var rng := RandomNumberGenerator.new()
var current: Unit = null
var turn_count: int = 0
var outcome: String = ""  # "", "victory", "defeat"
## Украденные предметы: [{wizard, item}] — возвращаются после победы.
var stolen: Array = []
var _next_id: int = 0


## wizards — Array[Wizard]; fortify_turns/decay — параметры Укрепления.
func _init(book_db: Dictionary, wizards: Array, encounter: Dictionary, seed_value: int = 0,
		item_db: Dictionary = {}, fortify_turns: int = 5, fortify_decay: float = 0.5) -> void:
	books = book_db
	items = item_db
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	for w in wizards:
		_add_wizard(w, fortify_turns, fortify_decay)
	for member in encounter.get("members", []):
		add_enemy(member)


func _add_wizard(w: Wizard, fortify_turns: int, fortify_decay: float) -> void:
	var st := w.stats()
	var u := _new_unit(w.name, Unit.PARTY, st.hp, st.speed)
	u.wizard = w
	u.class_id = w.class_id
	u.hp = w.hp
	u.books = w.books.duplicate()
	u.ability = w.ability
	u.ability_charges = w.ability_charges
	if w.ability == "lay_on_hands":
		u.ability_pool = float(w.ability_charges)
	u.wisdom = st.wisdom
	u.defense_bonus = st.defense
	u.luck_bonus = st.luck
	u.resist = st.resist
	u.immune = st.immune
	u.random_target = st.random_target
	u.meter += st.start_meter
	if w.fortify > 0.0 and w.alive():
		u.fortify = w.fortify
		u.fortify_turns = fortify_turns
		u.fortify_decay = fortify_decay
	w.fortify = 0.0  # Укрепление действует только на следующий бой
	for s in st.start_status:
		u.add_status(s.id, int(s.turns))
	for id in w.carry_statuses:  # например, Разбитость после воскрешения
		u.add_status(id, int(w.carry_statuses[id]))


func add_enemy(cfg: Dictionary) -> Unit:
	var u := _new_unit(cfg.name, Unit.ENEMIES, float(cfg.hp), float(cfg.speed))
	u.attack = int(cfg.damage)
	u.attacks = int(cfg.get("attacks", 1))
	u.behaviour = cfg.get("behaviour", "")
	u.heal_power = int(cfg.get("heal", 0))
	u.is_leader = bool(cfg.get("leader", false))
	u.is_boss = bool(cfg.get("boss", false))
	u.passive = cfg.get("passive", "")
	for sp in cfg.get("specials", []):
		var s: Dictionary = sp.duplicate(true)
		s.cd = int(sp.get("first", 2))  # на каком по счёту ходу впервые (по умолчанию — на 2-м)
		u.specials.append(s)
	return u


func _new_unit(unit_name: String, side: String, hp: float, speed: float) -> Unit:
	var u := Unit.new()
	u.id = _next_id
	_next_id += 1
	u.name = unit_name
	u.side = side
	u.max_hp = hp
	u.hp = hp
	u.speed = speed
	u.meter = rng.randf_range(0.0, 10.0)  # чтобы одинаково быстрые не ходили строем
	units.append(u)
	return u


# --- Очерёдность ---------------------------------------------------------

func living(side: String = "") -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units:
		if u.alive() and (side == "" or u.side == side):
			out.append(u)
	return out


func opposite(side: String) -> String:
	return Unit.ENEMIES if side == Unit.PARTY else Unit.PARTY


## Двигает шкалы, пока кто-то не наберёт 100 %. Обрабатывает начало его хода.
## Возвращает участника, чей сейчас ход, или null, если бой окончен.
func next_turn() -> Unit:
	_check_outcome()
	while outcome == "":
		var ready := _pop_ready()
		turn_count += 1
		current = ready
		turn_started.emit(ready)
		_start_of_turn(ready)
		_check_outcome()
		if outcome != "":
			return null
		if not ready.alive():
			continue
		if ready.has("stun") or ready.has("petrify") or ready.has("toad"):
			_log("%s пропускает ход." % ready.name, "control")
			end_turn(ready)
			continue
		return ready
	return null


func _pop_ready() -> Unit:
	var alive := living()
	while true:
		var best: Unit = null
		for u in alive:
			if u.meter >= METER_FULL and (best == null or _before(u, best)):
				best = u
		if best:
			best.meter -= METER_FULL
			return best
		for u in alive:
			u.meter += u.effective_speed()
	return null


func _before(a: Unit, b: Unit) -> bool:
	if a.meter != b.meter:
		return a.meter > b.meter
	if a.effective_speed() != b.effective_speed():
		return a.effective_speed() > b.effective_speed()
	return a.is_wizard() and not b.is_wizard()


## Ближайшие n ходов (для полоски очереди в интерфейсе).
func turn_queue(n: int) -> Array[Unit]:
	var meters := {}
	var alive := living()
	for u in alive:
		meters[u] = u.meter
	var out: Array[Unit] = []
	var guard := 0
	while out.size() < n and not alive.is_empty() and guard < 10000:
		guard += 1
		var best: Unit = null
		for u in alive:
			if meters[u] >= METER_FULL and (best == null or meters[u] > meters[best]):
				best = u
		if best:
			meters[best] -= METER_FULL
			out.append(best)
			continue
		for u in alive:
			meters[u] += u.effective_speed()
	return out


func _start_of_turn(u: Unit) -> void:
	if u.has("burn"):
		_log("%s горит." % u.name, "dot", "burn")
		_hurt(u, 1.0, null)
	if u.has("poison") and u.alive():
		_log("%s страдает от яда." % u.name, "dot", "poison")
		_hurt(u, float(u.statuses.poison.stacks), null)
	if u.has("dead_poison") and u.alive():
		_log("%s: Мёртвый яд." % u.name, "dot", "dead_poison")
		_hurt(u, Unit.q(DEAD_POISON_DAMAGE * u.statuses.dead_poison.stacks), null)
	if u.has("regen") and u.alive():
		_restore(u, 1.0)


func end_turn(u: Unit) -> void:
	u.tick_down()
	_check_outcome()


func _check_outcome() -> void:
	if outcome != "":
		return
	if living(Unit.ENEMIES).is_empty():
		outcome = "victory"
		for s in stolen:
			if s.wizard.item == "":
				s.wizard.item = s.item
				_log("%s возвращает украденный предмет: %s." % [s.wizard.name, items.get(s.item, {}).get("name", s.item)], "item")
		stolen.clear()
	elif living(Unit.PARTY).is_empty():
		outcome = "defeat"


# --- Каст волшебника -----------------------------------------------------

## Можно ли выбрать эту цель (Страх, Невидимость, выбывшие).
func can_target(caster: Unit, target: Unit) -> bool:
	if caster.fears(target):
		return false
	if not target.alive():
		return target.side == caster.side  # выбывшего союзника можно воскресить
	if target.has("invisible") and target.side != caster.side:
		return living(target.side).all(func(x: Unit) -> bool: return x.has("invisible"))
	return true


func valid_targets(caster: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units:
		if can_target(caster, u):
			out.append(u)
	return out


## Ослепление, Очарование и «говорящая шляпа» могут подменить выбранную цель.
func resolve_target(caster: Unit, chosen: Unit) -> Unit:
	if caster.has("blind"):
		var any := living()
		var t := any[rng.randi_range(0, any.size() - 1)]
		_log("%s ослеплён и кастует наугад в %s." % [caster.name, t.name], "misfire", "blind")
		return t
	if caster.has("charm"):
		var allies := living(caster.side)
		var t := allies[rng.randi_range(0, allies.size() - 1)]
		_log("%s очарован и кастует в союзника: %s." % [caster.name, t.name], "misfire", "charm")
		return t
	if caster.random_target > 0.0 and rng.randf() < caster.random_target:
		var any := living()
		var t := any[rng.randi_range(0, any.size() - 1)]
		_log("Шляпа подсказала не ту цель: %s." % t.name, "misfire")
		return t
	return chosen


func new_bag(caster: Unit, book_id: String) -> ChipBag:
	var bag: Dictionary = books[book_id].bag
	var extra := caster.extra_chaos_chips()
	if caster.no_chaos:
		extra = -int(bag.get("X", 0))
	return ChipBag.new(bag, extra)


func spell_for(book_id: String, combo: String) -> Dictionary:
	for s in books[book_id].spells:
		if s.combo == combo:
			return s
	return {}


## Применяет заклинание по вытянутым фишкам.
## finish=false — ход не заканчивается (свиток «Я кастую дважды»).
func cast(caster: Unit, target: Unit, book_id: String, bag: ChipBag, finish: bool = true) -> Dictionary:
	if caster.has("confusion"):
		bag.shuffle_order(rng)
	var spell := spell_for(book_id, bag.combo_key())
	caster.books_used[book_id] = true
	var aim := "" if target == null or target == caster else " → %s" % target.name
	_log("%s: «Я кастую!» — %s%s." % [caster.name, spell.name, aim], "chaos" if bag.chips.has(ChipBag.CHAOS) else "cast")
	_apply_spell(caster, target, spell, bag.chips)
	_pay_cast_cost(caster, book_id)
	_cane_strike(caster, target, spell)
	_bard_critics(caster)
	if finish:
		end_turn(caster)
	else:
		_check_outcome()
	return spell


## Проклятые книги берут плату за каст (Книга Мёртвого Языка — стак Мёртвого яда).
func _pay_cast_cost(caster: Unit, book_id: String) -> void:
	var cost: Dictionary = books[book_id].get("cast_cost", {})
	if cost.is_empty() or not caster.alive():
		return
	caster.add_status(cost.status, int(cost.turns), int(cost.get("stacks", 1)), caster)
	_log("%s платит за проклятую книгу: %s." % [caster.name, status_name(cost.status)], "curse", cost.status)
	status_applied.emit(caster, cost.status)


# --- Способности классов ------------------------------------------------

## Можно ли перевытянуть фишку: Сожжение Пироманта или Муза от Барда.
func can_reroll(caster: Unit) -> bool:
	return (caster.ability == "burn" and caster.ability_charges > 0) or caster.has("muse")


## Перевытягивает фишку в ячейке. Возвращает описание для журнала или "".
func reroll_chip(caster: Unit, bag: ChipBag, slot: int) -> String:
	if slot < 0 or slot >= bag.chips.size() or not can_reroll(caster):
		return ""
	var how := ""
	if caster.ability == "burn" and caster.ability_charges > 0:
		caster.ability_charges -= 1
		how = "сжигает фишку (осталось %d)" % caster.ability_charges
	else:
		caster.statuses.erase("muse")
		how = "по вдохновению перевытягивает фишку"
	bag.reroll(slot, rng)
	var text := "%s %s." % [caster.name, how]
	_log(text)
	return text


## Паладин: Наложение рук — лечит союзника из запаса на бой.
func can_lay_on_hands(paladin: Unit) -> bool:
	return paladin.ability == "lay_on_hands" and paladin.ability_pool > 0.0 \
		and not lay_on_hands_targets(paladin).is_empty()


func lay_on_hands_targets(paladin: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in living(paladin.side):
		if u.hp < u.max_hp:
			out.append(u)
	return out


func lay_on_hands(paladin: Unit, target: Unit) -> void:
	var amount := Unit.q(minf(paladin.ability_pool, target.max_hp - target.hp))
	paladin.ability_pool = Unit.q(paladin.ability_pool - amount)
	_log("%s: Наложение рук на %s (запас %s)." % [paladin.name, target.name, Unit._num(paladin.ability_pool)], "heal")
	_restore(target, amount)


## Бард: Вдохновение — союзник может перевытянуть одну фишку в следующем касте.
func can_inspire(bard: Unit) -> bool:
	return bard.ability == "inspiration" and bard.ability_charges > 0 and not inspire_targets(bard).is_empty()


func inspire_targets(bard: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in living(bard.side):
		if u != bard and not u.has("muse"):
			out.append(u)
	return out


func inspire(bard: Unit, target: Unit) -> void:
	bard.ability_charges -= 1
	_log("%s поёт для %s: Вдохновение!" % [bard.name, target.name], "buff", "inspire")
	_apply_status(target, {"id": "muse", "turns": 99}, bard)


## Бард, дебафф «Критики»: 10 % — фальшивая баллада замедляет весь отряд.
func _bard_critics(caster: Unit) -> void:
	if caster.ability == "inspiration" and rng.randf() < 0.1:
		_log("Критики освистали балладу — отряд приуныл!", "bad")
		for u in living(caster.side):
			u.add_status("slow", 1)
			status_applied.emit(u, "slow")


## Паладин, клятва: каст ранил союзника — запас Наложения рук сгорает.
func _check_oath(caster: Unit, hurt_ally: bool) -> void:
	if hurt_ally and caster.ability == "lay_on_hands" and caster.ability_pool > 0.0:
		caster.ability_pool = 0.0
		_log("%s нарушает клятву — Наложение рук недоступно до конца боя." % caster.name, "bad")


## Магус: каст по противнику без урона — добивает тростью на 1.
func _cane_strike(caster: Unit, target: Unit, spell: Dictionary) -> void:
	if caster.ability != "cane" or target == null or target.side == caster.side or not target.alive():
		return
	var spec := EffectParser.parse(spell)
	if spec.damage > 0 or spec.splash > 0:
		return
	_log("%s добивает тростью!" % caster.name, "damage")
	_hit(target, 1.0, caster)


func _apply_spell(caster: Unit, target: Unit, spell: Dictionary, chips: Array[String]) -> void:
	var spec := EffectParser.parse(spell)
	if spec.nothing:
		_log("Ничего не произошло.", "fizzle")
	var element := "F" if chips.has("F") else "?"
	var bonus := caster.power_bonus()
	var hurt_ally := false
	var harmful: bool = spec.damage > 0 or spec.meter < 0 or spec.strip_buffs or spec.statuses.any(
		func(s: Dictionary) -> bool: return Unit.DEBUFFS.has(s.id))

	for r in _recipients(spec, caster, target):
		var who := r
		if harmful and who != caster and who.has("reflect"):
			who.statuses.erase("reflect")
			_log("%s отражает заклинание обратно!" % who.name, "reflect", "reflect")
			who = caster
		if spec.area == "target" and _fizzles(caster, who, spec):
			_log("Удача! Заклинание по %s рассеялось." % who.name, "luck")
			continue
		if spec.revive_hp > 0 and not who.alive():
			_revive(who, float(spec.revive_hp))
			continue
		if not who.alive():
			continue
		if spec.damage > 0:
			_hit(who, float(maxi(0, spec.damage + bonus)), caster, element)
			if who != caster and who.side == caster.side:
				hurt_ally = true
		if spec.heal > 0 and who.alive():
			var times := 1
			if caster.ability == "double_grace" and who.side == caster.side \
					and rng.randf() < DOUBLE_GRACE_CHANCE:
				times = 2
				_log("Двойная благодать!", "luck")
			for i in times:
				_restore(who, float(maxi(0, spec.heal + bonus)))
		if spec.shield > 0 and who.alive():
			who.shield += maxi(0, spec.shield + bonus)
			_log("%s получает Щит %d." % [who.name, spec.shield + bonus], "shield", "shield")
			status_applied.emit(who, "shield")
			_cheer(who)
		if spec.cleanse:
			who.remove_debuffs()
			_log("%s очищен." % who.name, "buff")
		if spec.strip_buffs:
			who.remove_buffs()
			_log("%s теряет все баффы." % who.name, "debuff")
		for s in spec.remove:
			who.statuses.erase(s)
		for s in spec.statuses:
			_apply_status(who, s, caster)
		if spec.meter != 0:
			_shift_meter(who, spec.meter)

	if spec.splash > 0 and target:
		for u in living(target.side):
			if u != target:
				_hit(u, float(spec.splash), caster, element)
				if u != caster and u.side == caster.side:
					hurt_ally = true
	_check_oath(caster, hurt_ally)
	if spec.self_damage > 0:
		_log("Отдача по %s." % caster.name, "damage")
		_hurt(caster, float(spec.self_damage), null)
	if spec.self_heal > 0 and caster.alive():
		_restore(caster, float(spec.self_heal))
	for s in spec.caster_statuses:
		_apply_status(caster, s, caster)


func _recipients(spec: Dictionary, caster: Unit, target: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	match spec.area:
		"target":
			out.append(target)
		"target_side":
			out = living(target.side)
		"arena":
			for u in living():
				if not (spec.exclude_caster and u == caster):
					out.append(u)
		"enemies":
			out = living(opposite(caster.side))
		"caster_side":
			out = living(caster.side)
		"random":
			var any := living()
			out.append(any[rng.randi_range(0, any.size() - 1)])
	return out


## Удача: «неподходящее» заклинание (урон по своим, лечение врага) может рассеяться.
func _fizzles(caster: Unit, who: Unit, spec: Dictionary) -> bool:
	var wrong: bool = (spec.damage > 0 and who.side == caster.side) \
		or ((spec.heal > 0 or spec.shield > 0) and who.side != caster.side)
	return wrong and rng.randf() < caster.luck() * FIZZLE_PER_LUCK


# --- Предметы ------------------------------------------------------------

## Кого можно выбрать целью предмета.
func item_targets(owner: Unit, item_id: String) -> Array[Unit]:
	var out: Array[Unit] = []
	match String(items[item_id].target):
		"self":
			out.append(owner)
		"ally":
			out = living(owner.side)
		"dead_ally":
			for u in units:
				if u.side == owner.side and not u.alive():
					out.append(u)
		"enemy":
			out = living(opposite(owner.side))
	return out


func can_use_item(owner: Unit) -> bool:
	if owner.wizard == null or owner.wizard.item == "":
		return false
	var it: Dictionary = items[owner.wizard.item]
	if it.get("camp_only", false) or it.target == "passive":
		return false
	return not item_targets(owner, owner.wizard.item).is_empty()


## Применяет предмет владельца. Ход не тратится.
func use_item(owner: Unit, target: Unit) -> void:
	var item_id := owner.wizard.item
	var it: Dictionary = items[item_id]
	owner.wizard.item = ""
	_log("%s использует предмет: %s." % [owner.name, it.name], "item")
	var e: Dictionary = it.effect
	if e.has("revive") and not target.alive():
		_revive(target, float(e.revive))
	if not target.alive():
		return
	if e.has("damage"):
		_hit(target, float(e.damage), owner)
	if e.get("cleanse", false):
		target.remove_debuffs()
	if e.has("heal"):
		_restore(target, float(e.heal))
	if e.has("shield"):
		target.shield += float(e.shield)
		_log("%s получает Щит %d." % [target.name, e.shield], "shield", "shield")
		_cheer(target)
	if e.get("no_chaos", false):
		target.no_chaos = true
		_log("Из мешочков %s высыпаны фишки Хаоса." % target.name, "item")
	if e.has("status"):
		target.add_status(e.status, int(e.turns))
		_log("%s: %s." % [target.name, status_name(e.status)], "buff" if Unit.BUFFS.has(e.status) else "debuff", e.status)
		status_applied.emit(target, e.status)
		if Unit.BUFFS.has(e.status):
			_cheer(target)
	if e.has("extra_cast"):
		target.extra_casts += int(e.extra_cast)
	_check_outcome()


# --- Эффекты -------------------------------------------------------------

func _apply_status(who: Unit, s: Dictionary, source: Unit) -> void:
	if not who.alive():
		return
	var id: String = s.id
	if who.immune.has(id):
		_log("%s невосприимчив: %s." % [who.name, status_name(id)], "resist", id)
		return
	if Unit.DEBUFFS.has(id) and source != who and who.resist > 0 \
			and rng.randf() < who.resist * RESIST_PER_POINT:
		_log("%s устоял: %s." % [who.name, status_name(id)], "resist", id)
		return
	if who.resists_control() and HARD_CONTROL.has(id):
		_log("%s не поддаётся контролю — Сбив шкалы на 50 %%." % who.name, "resist")
		_shift_meter(who, -50)
		return
	who.add_status(id, int(s.turns), int(s.get("stacks", 1)), source)
	_log("%s: %s." % [who.name, status_name(id)], "buff" if Unit.BUFFS.has(id) else "debuff", id)
	status_applied.emit(who, id)
	if Unit.BUFFS.has(id):
		_cheer(who)


func _shift_meter(who: Unit, percent: int) -> void:
	who.meter = maxf(0.0, who.meter + percent)
	_log("%s: шкала хода %+d %%." % [who.name, percent], "meter")


## Удар с учётом Неуязвимости, Элементальной формы, Жабы, Уязвимости и Защиты.
func _hit(who: Unit, amount: float, source: Unit, element: String = "?") -> void:
	if not who.alive() or amount <= 0.0:
		return
	if who.has("invulnerable"):
		who.statuses.erase("invulnerable")
		_log("%s неуязвим — удар прошёл мимо." % who.name, "block", "invulnerable")
		return
	if element != "F" and (who.has("elemental") or (who.ability == "elemental_form"
			and rng.randf() < WATER_ELEMENTAL_CHANCE)):
		_log("%s становится водой — урон не прошёл." % who.name, "block")
		return
	if who.has("toad"):
		amount *= 2.0
		who.statuses.erase("toad")
		_log("%s снова человек (удар по жабе — двойной)." % who.name, "debuff", "toad")
	if who.has("vulnerable"):
		amount += 1.0
	var guard := who.defense()
	if who.passive == "rat_guard" and living(who.side).size() > 1:
		guard += 1
	amount = maxf(1.0, amount - guard)
	_hurt(who, amount, source)


## Урон без проверок защиты (яд, горение, отдача).
## Сначала тратится Укрепление, потом Щит, потом здоровье.
func _hurt(who: Unit, amount: float, source: Unit) -> void:
	amount = Unit.q(amount)
	for layer in ["fortify", "shield"]:
		var pool: float = who.get(layer)
		if pool <= 0.0 or amount <= 0.0:
			continue
		var absorbed := minf(pool, amount)
		who.set(layer, Unit.q(pool - absorbed))
		amount = Unit.q(amount - absorbed)
		_log("%s %s поглощает %s." % ["Укрепление" if layer == "fortify" else "Щит", who.name, Unit._num(absorbed)], "block", layer)
		hp_changed.emit(who, absorbed, "block")
	if amount <= 0.0:
		return
	who.hp = Unit.q(maxf(0.0, who.hp - amount))
	hp_changed.emit(who, amount, "damage")
	_log("%s получает %s урона (%s)." % [who.name, Unit._num(amount), who.hp_text()], "big_damage" if amount >= BIG_HIT else "damage")
	if not who.alive():
		_on_down(who, source)


func _on_down(who: Unit, source: Unit) -> void:
	_log("%s выбывает!" % who.name, "kill")
	who.statuses.clear()
	who.shield = 0.0
	who.fortify = 0.0
	if who.wizard and who.wizard.item != "" and items.get(who.wizard.item, {}).get("effect", {}).has("auto_revive"):
		var hp: float = items[who.wizard.item].effect.auto_revive
		_log("Срабатывает %s!" % items[who.wizard.item].name, "revive")
		who.wizard.item = ""
		_revive(who, hp)
		return
	if who.is_leader:
		_morale_break(who, source)
	_check_outcome()


func _revive(who: Unit, hp: float) -> void:
	who.hp = Unit.q(minf(who.max_hp, hp))
	who.statuses.clear()
	_log("%s возвращается в бой с %s ЗД!" % [who.name, Unit._num(who.hp)], "revive")
	hp_changed.emit(who, who.hp, "heal")


func _restore(who: Unit, amount: float) -> void:
	if amount > 0.0:
		_cheer(who)
	if who.has("disease"):
		amount *= 0.5
	var before := who.hp
	who.hp = Unit.q(minf(who.max_hp, who.hp + amount))
	if who.hp > before:
		hp_changed.emit(who, who.hp - before, "heal")
		_log("%s лечится на %s (%s)." % [who.name, Unit._num(who.hp - before), who.hp_text()], "big_heal" if who.hp - before >= BIG_HIT else "heal")


## Любой положительный эффект (лечение, щит, бафф) снимает Разбитость.
func _cheer(who: Unit) -> void:
	if who.has("aching"):
		who.statuses.erase("aching")
		_log("%s приходит в себя — Разбитость снята." % who.name, "buff", "aching")


## Предводитель погиб — банда боится того, кто его добил.
func _morale_break(leader: Unit, killer: Unit) -> void:
	if killer == null:
		return
	for u in living(leader.side):
		u.add_status("fear", 2, 1, killer)
	_log("Банда в панике и боится %s!" % killer.name, "kill", "fear")


# --- Противники ----------------------------------------------------------

## Ход противника: особая атака, если перезарядилась, иначе обычное действие.
func enemy_act(enemy: Unit) -> void:
	var special := _ready_special(enemy)
	if not special.is_empty():
		special.cd = int(special.cooldown)
		_use_special(enemy, special)
	elif enemy.behaviour == "healer" and _heal_ally(enemy):
		pass
	else:
		for i in enemy.attacks:
			var target := _enemy_target(enemy)
			if target == null or not enemy.alive():
				break
			_log("%s атакует %s." % [enemy.name, target.name], "enemy")
			_enemy_strike(enemy, target, float(enemy.attack))
	end_turn(enemy)


## Уменьшает перезарядки и возвращает готовую особую атаку (первая по списку).
func _ready_special(enemy: Unit) -> Dictionary:
	var ready: Dictionary = {}
	for s in enemy.specials:
		s.cd -= 1
		if s.cd <= 0 and ready.is_empty() and not enemy.has("forget"):
			ready = s
	for s in enemy.specials:
		if s != ready and s.cd < 0:
			s.cd = 0  # готовая, но отложенная атака ждёт следующего хода
	return ready


func _use_special(enemy: Unit, sp: Dictionary) -> void:
	_log("%s: «%s» — %s!" % [enemy.name, sp.name, sp.get("text", "")], "special", "leader")
	match String(sp.id):
		"all_attack_one":
			var target := _enemy_target(enemy)
			for u in living(enemy.side):
				if target and target.alive():
					_enemy_strike(u, target, float(u.attack))
		"strike":
			var target := _enemy_target(enemy)
			if target == null:
				return
			_enemy_strike(enemy, target, float(sp.get("damage", enemy.attack)))
			if target.alive():
				if sp.has("meter"):
					_shift_meter(target, int(sp.meter))
				if sp.has("status"):
					_apply_status(target, {"id": sp.status, "turns": int(sp.turns)}, enemy)
				if sp.get("steal", false) and target.wizard and target.wizard.item != "":
					stolen.append({"wizard": target.wizard, "item": target.wizard.item})
					_log("%s крадёт у %s предмет: %s!" % [enemy.name, target.name,
						items.get(target.wizard.item, {}).get("name", target.wizard.item)], "special")
					target.wizard.item = ""
		"aoe":
			for u in living(opposite(enemy.side)):
				_hit(u, float(sp.get("damage", 0)), enemy)
				if sp.has("status") and u.alive():
					_apply_status(u, {"id": sp.status, "turns": int(sp.turns)}, enemy)
		"summon":
			for i in int(sp.count):
				var u := add_enemy(sp.unit)
				_log("Появляется: %s." % u.name, "summon")
				unit_added.emit(u)
		_:
			push_warning("Неизвестная особая атака: %s" % sp.id)


func _heal_ally(healer: Unit) -> bool:
	var worst: Unit = null
	for u in living(healer.side):
		if u.hp < u.max_hp and (worst == null or u.hp / u.max_hp < worst.hp / worst.max_hp):
			worst = u
	if worst == null:
		return false
	_log("%s лечит %s." % [healer.name, worst.name], "enemy_heal")
	_restore(worst, float(healer.heal_power))
	return true


func _enemy_strike(attacker: Unit, target: Unit, damage: float) -> void:
	var dmg := maxf(0.0, damage - (1.0 if attacker.has("weak") else 0.0))
	if target.has("reflect") and target.side != attacker.side:
		target.statuses.erase("reflect")
		_log("%s отражает атаку!" % target.name, "reflect", "reflect")
		target = attacker
	_hit(target, dmg, attacker)


func _enemy_target(enemy: Unit) -> Unit:
	var any := living()
	any.erase(enemy)
	if enemy.has("blind") or (enemy.has("confusion") and rng.randf() < 0.5) \
			or (enemy.has("chaos_curse") and rng.randf() < 0.25):
		return any[rng.randi_range(0, any.size() - 1)] if not any.is_empty() else null
	if enemy.has("charm"):
		var own := living(enemy.side)
		own.erase(enemy)
		if not own.is_empty():
			return own[rng.randi_range(0, own.size() - 1)]
	var foes: Array[Unit] = []
	var taunting: Array[Unit] = []
	for u in living(opposite(enemy.side)):
		if u.has("invisible") or enemy.fears(u):
			continue
		foes.append(u)
		if u.has("taunt"):
			taunting.append(u)
	if not taunting.is_empty():
		foes = taunting
	if foes.is_empty():
		foes = living(opposite(enemy.side))
	if foes.is_empty():
		return null
	return foes[rng.randi_range(0, foes.size() - 1)]


# --- Разное --------------------------------------------------------------

func _log(text: String, kind: String = "info", icon: String = "") -> void:
	logged.emit(text, kind, icon)


static func status_name(id: String) -> String:
	return GameData.statuses().get(id, {}).get("name", id)
