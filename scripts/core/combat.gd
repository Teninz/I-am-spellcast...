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
## Волшебники, выбывавшие в этом бою (даже если их потом подняли).
var downed: Array[Unit] = []
## Счётчики боя для достижений: выбывания волшебников, предметы, Хаос II/III, «промахи»
## (отряд вылечил, защитил или усилил врага либо ранил своего).
var tally := {"downs": 0, "items": 0, "chaos_big": 0, "mishaps": 0}
## Видения Прорицателя: тройки, увиденные в начале боя (ранги фишек: 0 — самая частая
## стихия книги, 1, 2; -1 — Хаос). Любой волшебник может заменить свою тройку видением.
var visions: Array = []
## Снимок боя перед последним кастом волшебника (для Перемотки Хрономанта).
var _snapshot: Dictionary = {}
## Каст, который можно отмотать: кто кастовал и был ли он «неудачным».
var last_cast := {}
var _next_id: int = 0
var _splitting := false  # урон уже делится (Кровная связь, Преломление) — не делить снова
var _spell_depth := 0    # вложенные случайные заклинания (Дикий всплеск)


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
	_apply_marks(encounter)
	_prepare_visions()


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
	u.extra_chaos = w.extra_chaos
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


## Трофеи и шрамы боссов, которые срабатывают в начале боя.
func _apply_marks(encounter: Dictionary) -> void:
	for u in living(Unit.PARTY):
		var w := u.wizard
		if w == null:
			continue
		if w.has_effect("heal_minus"):
			u.set_meta("heal_minus", 1.0)
		if w.has_effect("rat_follows"):
			add_enemy({"name": "Крыса из свиты", "hp": 2, "damage": 1, "speed": 12})
		if w.has_effect("marked"):
			u.add_status("taunt", 2)
		if w.has_effect("bird_fear") and encounter.get("birds", false):
			var foes := living(Unit.ENEMIES)
			if not foes.is_empty():
				u.add_status("fear", 2, 1, foes[0])


func add_enemy(cfg: Dictionary, side: String = Unit.ENEMIES) -> Unit:
	var u := _new_unit(cfg.name, side, float(cfg.hp), float(cfg.speed))
	u.attack = int(cfg.damage)
	u.attacks = int(cfg.get("attacks", 1))
	u.behaviour = cfg.get("behaviour", "")
	u.heal_power = int(cfg.get("heal", 0))
	u.is_leader = bool(cfg.get("leader", false))
	u.is_boss = bool(cfg.get("boss", false))
	u.passive = cfg.get("passive", "")
	u.defense_bonus = int(cfg.get("defense", 0))
	u.immune = cfg.get("immune", []).duplicate()
	u.traits = cfg.get("traits", []).duplicate()
	if u.traits.has("taunt"):
		u.add_status("taunt", 99)
	if u.traits.has("invisible_first"):
		u.add_status("invisible", 1)
	if u.traits.has("underground"):
		u.add_status("invulnerable", 1)
		u.statuses.invulnerable.hold = true
	for key in ["dismount", "split", "on_hit_status"]:
		if cfg.has(key):
			u.set_meta(key, cfg[key])
	for st in cfg.get("start_status", []):
		u.add_status(st.id, int(st.turns))
		if st.get("hold", false):
			u.statuses[st.id].hold = true  # не снимается первым ударом
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


## Живые волшебники (без призванных существ).
func party_wizards() -> Array[Unit]:
	return living(Unit.PARTY).filter(func(u: Unit) -> bool: return u.is_wizard())


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
	u.set_meta("turn_mark", u.hp)
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
	if u.has_meta("illusory"):
		var keep := []
		for il in u.get_meta("illusory"):
			il.turns -= 1
			if il.turns > 0:
				keep.append(il)
			elif u.alive():
				u.hp = Unit.q(maxf(0.1, u.hp - float(il.amount)))
				_log("Иллюзорное лечение %s рассеялось (−%s ЗД)." % [u.name, Unit._num(il.amount)], "debuff")
		if keep.is_empty():
			u.remove_meta("illusory")
		else:
			u.set_meta("illusory", keep)
	if u.has_meta("rally"):
		var r: Dictionary = u.get_meta("rally")
		r.turns -= 1
		if r.turns <= 0:
			u.attack -= int(r.bonus)
			u.remove_meta("rally")
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
	elif party_wizards().is_empty():
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


## luck_plan — вложения шкалы удачи (см. Luck); действуют только при баффе удачи.
func new_bag(caster: Unit, book_id: String, luck_plan: Dictionary = {}) -> ChipBag:
	var bag: Dictionary = books[book_id].bag
	var extra := bag_extra_chaos(caster, book_id)
	var out := ChipBag.new(bag, extra)
	if caster.has_meta("foresight"):
		out.forced = vision_chips(caster.get_meta("foresight"), book_id)
		caster.remove_meta("foresight")
		return out
	if not luck_plan.is_empty() and Luck.has_luck(caster):
		var odds := ChipBag.odds(bag, extra)
		var combo := Luck.roll(books[book_id], odds, Luck.clean(books[book_id], odds, luck_plan), rng)
		if combo != "":
			out.forced = ChipBag.chips_for(combo, bag, rng)
	return out


## Сколько фишек Хаоса добавлено (или убрано) в мешочек книги у этого волшебника.
func bag_extra_chaos(caster: Unit, book_id: String) -> int:
	if caster.no_chaos:
		return -int(books[book_id].bag.get("X", 0))
	return caster.extra_chaos_chips()


## Шансы троек книги для этого волшебника (с учётом лишних или убранных фишек Хаоса).
func book_odds(caster: Unit, book_id: String) -> Dictionary:
	return ChipBag.odds(books[book_id].bag, bag_extra_chaos(caster, book_id))


func spell_for(book_id: String, combo: String) -> Dictionary:
	for s in books[book_id].spells:
		if s.combo == combo:
			return s
	return {}


## Применяет заклинание по вытянутым фишкам.
## finish=false — ход не заканчивается (свиток «Я кастую дважды»).
func cast(caster: Unit, target: Unit, book_id: String, bag: ChipBag, finish: bool = true) -> Dictionary:
	if caster.is_wizard():
		_snapshot = snapshot()
		_snapshot.caster = caster.id
	var mishaps_before := int(tally.mishaps)
	var hp_before := _side_hp()
	if caster.has("confusion"):
		bag.shuffle_order(rng)
	var spell := spell_for(book_id, bag.combo_key())
	if bag.combo_key() in ["X2", "X3"] and caster.is_wizard():
		tally.chaos_big += 1
	caster.books_used[book_id] = true
	var aim := "" if target == null or target == caster else " → %s" % target.name
	_log("%s: «Я кастую!» — %s%s." % [caster.name, spell.name, aim], "chaos" if bag.chips.has(ChipBag.CHAOS) else "cast")
	if not bag.forced.is_empty():
		_log("Удача подправила фишки!", "luck")
	_apply_spell(caster, target, spell, bag.chips, book_id)
	if caster.has("echo_next") and caster.alive():
		caster.statuses.erase("echo_next")
		_log("Двойник заклинания: «%s» срабатывает ещё раз!" % spell.name, "misfire")
		_apply_spell(caster, target if target and target.alive() else caster, spell, bag.chips, book_id)
	_pay_cast_cost(caster, book_id)
	_sheep_check(caster, book_id, bag)
	_druid_grumble(caster, bag)
	_cane_strike(caster, target, spell)
	_bard_critics(caster)
	if caster.is_wizard():
		# «Неудачный» каст: навредил своим / помог врагам или не задел врагов вовсе.
		var now := _side_hp()
		var bad: bool = int(tally.mishaps) > mishaps_before or float(now.enemies) >= float(hp_before.enemies)
		last_cast = {"caster": caster.id, "bad": bad, "book": book_id}
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


# --- Общий интерфейс способностей ------------------------------------------
# Когда применяется (phase):
#   "target" — при выборе цели, не тратит ход, цель — союзник (Паладин, Бард, Некромант, Иллюзионист);
#   "turn"   — вместо каста, может нужна цель-враг (Учёный);
#   "chips"  — когда тройка вытянута, до крика (Друид, Дикий маг; Видения — у любого);
#   "draw"   — перед вытягиванием фишки (Чернокнижник);
#   "rewind" — после неудачного каста (Хрономант).

const ABILITY_PHASE := {
	"lay_on_hands": "target", "inspiration": "target", "raise_dead": "target", "decoy": "target",
	"workshop": "turn", "beast_call": "chips", "surge": "chips", "pact_deal": "draw",
}


func ability_phase(u: Unit) -> String:
	return ABILITY_PHASE.get(u.ability, "")


## Можно ли прямо сейчас применить способность своей фазы.
func can_use_ability(u: Unit, bag: ChipBag = null) -> bool:
	if u == null or not u.is_wizard() or not u.alive():
		return false
	match u.ability:
		"lay_on_hands":
			return can_lay_on_hands(u)
		"inspiration":
			return can_inspire(u)
		"raise_dead", "decoy":
			return u.ability_charges > 0 and not ability_targets(u).is_empty()
		"workshop":
			return u.ability_charges > 0
		"beast_call":
			return u.ability_charges > 0 and bag != null and bag.is_complete()
		"surge":
			return u.ability_charges > 0 and bag != null and bag.is_complete() \
				and bag.chips.any(func(c: String) -> bool: return c != ChipBag.CHAOS)
		"pact_deal":
			return u.hp > PACT_COST and bag != null and not bag.is_complete()
	return false


## Цели способности фазы "target" (и врагов для зверушек Учёного).
func ability_targets(u: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	match u.ability:
		"lay_on_hands":
			return lay_on_hands_targets(u)
		"inspiration":
			return inspire_targets(u)
		"raise_dead":
			for x in units:
				if x.side == u.side and not x.alive() and x.wizard != null:
					out.append(x)
		"decoy":
			for x in living(u.side):
				if not x.has("invulnerable"):
					out.append(x)
		"workshop":
			return living(opposite(u.side))
	return out


func ability_name(u: Unit) -> String:
	match u.ability:
		"lay_on_hands":
			return "Наложение рук (%s)" % Unit._num(u.ability_pool)
		"inspiration":
			return "Вдохновение (%d)" % u.ability_charges
		"raise_dead":
			return "Поднятие зомби (%d)" % u.ability_charges
		"decoy":
			return "Двойник (%d)" % u.ability_charges
		"workshop":
			return "Мастерская (%d)" % u.ability_charges
		"beast_call":
			return "Зов зверя (%d)" % u.ability_charges
		"surge":
			return "Всплеск Хаоса"
		"pact_deal":
			return "Сделка (−%d ЗД)" % int(PACT_COST)
	return ""


## Способность фазы "target": союзник (или выбывший для Поднятия).
func use_target_ability(u: Unit, target: Unit) -> void:
	match u.ability:
		"lay_on_hands":
			lay_on_hands(u, target)
		"inspiration":
			inspire(u, target)
		"raise_dead":
			raise_dead(u, target)
		"decoy":
			u.ability_charges -= 1
			target.add_status("invulnerable", 99)
			_log("%s создаёт двойника %s — он примет следующий удар." % [u.name, target.name], "buff", "invulnerable")
			status_applied.emit(target, "invulnerable")


## Вытягивание вручную (клик по мешочку): с этим шансом фишка «подыгрывает» цели —
## по врагу ведёт к заклинанию с уроном, по союзнику — к защите, лечению или нейтральному.
const MANUAL_EDGE := 0.001


## Тянет фишку. manual — игрок кликнул сам (а не сработала автотяга): маленький бонус к нужной фишке.
func draw_chip(caster: Unit, target: Unit, book_id: String, bag: ChipBag, manual: bool) -> String:
	if manual and bag.chips.size() >= bag.forced.size() and rng.randf() < MANUAL_EDGE:
		var letter := nudged_letter(caster, target, book_id, bag)
		if letter != "":
			var forced: Array[String] = bag.chips.duplicate()
			forced.append(letter)
			bag.forced = forced
	return bag.draw(rng)


## Какая следующая фишка ведёт к «нужному» заклинанию (с учётом уже вытянутых). "" — такой нет.
func nudged_letter(caster: Unit, target: Unit, book_id: String, bag: ChipBag) -> String:
	var want_damage := target != null and target.side != caster.side
	var prefix := "".join(PackedStringArray(bag.chips))
	if prefix.contains(ChipBag.CHAOS):
		return ""
	var odds := book_odds(caster, book_id)
	var pool := {}
	var total := 0.0
	for sp in books[book_id].spells:
		var combo: String = sp.combo
		if combo.begins_with(ChipBag.CHAOS) or not combo.begins_with(prefix) or combo.length() <= prefix.length():
			continue
		var letter := combo[prefix.length()]
		if int(bag.counts.get(letter, 0)) <= 0:
			continue
		var spec := EffectParser.parse(sp)
		var harmful: bool = EffectParser.deals_damage(spec) or spec.statuses.any(
			func(st: Dictionary) -> bool: return Unit.DEBUFFS.has(st.id))
		var good: bool = EffectParser.deals_damage(spec) if want_damage else not harmful
		if not good:
			continue
		var p := float(odds.get(combo, 0.0))
		pool[letter] = float(pool.get(letter, 0.0)) + p
		total += p
	if total <= 0.0:
		return ""
	var r := rng.randf() * total
	for letter in pool:
		r -= pool[letter]
		if r <= 0.0:
			return letter
	return pool.keys().back()


const PACT_COST := 2.0
const ZOMBIE_HP := 6.0


## Некромант: выбывший союзник встаёт зомби.
func raise_dead(necro: Unit, target: Unit) -> void:
	necro.ability_charges -= 1
	var w := target.wizard
	var lost := w.become_zombie(rng)
	target.books = w.books.duplicate()
	target.max_hp = w.max_hp()
	_revive(target, ZOMBIE_HP)
	_log("%s поднимает %s зомби!%s" % [necro.name, target.name,
		" Книга «%s» потеряна навсегда." % books[lost].name if lost != "" else ""], "revive")


## Учёный: вместо каста — случайная зверушка. Возвращает её id (sheep / scarecrow / wolf).
func roll_workshop() -> String:
	return ["sheep", "scarecrow", "wolf"][rng.randi_range(0, 2)]


const CRITTER_NAMES := {"sheep": "Механическая овца", "scarecrow": "Пугало", "wolf": "Стальной волк"}


func critter_needs_target(critter: String) -> bool:
	return critter != "scarecrow"


## Ход зверушки: урон врагу и/или провокация и щит Учёному. Ход Учёного заканчивается.
func use_workshop(u: Unit, critter: String, target: Unit) -> void:
	if not CRITTER_NAMES.has(critter) or u.ability_charges <= 0:
		return
	u.ability_charges -= 1
	_log("%s заводит зверушку: %s!" % [u.name, CRITTER_NAMES[critter]], "special")
	match critter:
		"sheep":
			if target and target.alive():
				_hit(target, 2.0, u)
			_add_shield(u, 1.0)
		"scarecrow":
			_apply_status(u, {"id": "taunt", "turns": 3}, u)
			_add_shield(u, 2.0)
		"wolf":
			if target and target.alive():
				_hit(target, 2.0, u)
			_apply_status(u, {"id": "taunt", "turns": 2}, u)
	end_turn(u)


func _add_shield(u: Unit, amount: float) -> void:
	u.shield += amount
	_log("%s получает Щит %s." % [u.name, Unit._num(amount)], "shield", "shield")
	status_applied.emit(u, "shield")


## Друид: Зов зверя. Возвращает, кто пришёл (bear / hare / raven / cat).
func beast_call(druid: Unit, bag: ChipBag, target: Unit) -> String:
	druid.ability_charges -= 1
	var beast: String = ["bear", "hare", "raven", "cat"][rng.randi_range(0, 3)]
	match beast:
		"bear":
			for i in bag.chips.size():
				bag.reroll(i, rng)
			_log("%s зовёт медведя: тройка перевытянута, цель укушена!" % druid.name, "special")
			if target and target.alive():
				_hit(target, 1.0, druid)
		"hare":
			bag.reroll(rng.randi_range(0, bag.chips.size() - 1), rng)
			_log("%s зовёт зайца: одна фишка заменена." % druid.name, "luck")
		"raven":
			_log("%s зовёт ворона!" % druid.name, "special")
			if target and target.alive():
				_apply_status(target, {"id": "blind", "turns": 2}, druid)
		"cat":
			_log("%s зовёт кошку: она мурчит на цель." % druid.name, "heal")
			if target and target.alive():
				_restore(target, 1.0)
	_check_outcome()
	return beast


## Дикий маг: Всплеск — фишка тройки становится Хаосом.
func surge(mage: Unit, bag: ChipBag) -> void:
	mage.ability_charges -= 1
	var slots := []
	for i in bag.chips.size():
		if bag.chips[i] != ChipBag.CHAOS:
			slots.append(i)
	if slots.is_empty():
		return
	bag.chips[slots[rng.randi_range(0, slots.size() - 1)]] = ChipBag.CHAOS
	_log("%s нарочно добавляет Хаос!" % mage.name, "chaos")


## Чернокнижник: Сделка — 2 ЗД за право выбрать следующую фишку.
func pact_deal(warlock: Unit, bag: ChipBag, letter: String) -> bool:
	if not can_use_ability(warlock, bag) or int(bag.counts.get(letter, 0)) <= 0:
		return false
	warlock.hp = Unit.q(warlock.hp - PACT_COST)
	hp_changed.emit(warlock, PACT_COST, "damage")
	var forced: Array[String] = bag.chips.duplicate()
	forced.append(letter)
	bag.forced = forced
	_log("%s заключает сделку: −%d ЗД, следующая фишка — по выбору." % [warlock.name, int(PACT_COST)], "curse")
	return true


## Прорицатель: видения — 2 тройки на бой, увиденные заранее из его книги.
func _prepare_visions() -> void:
	for u in living(Unit.PARTY):
		if u.ability != "visions" or u.books.is_empty():
			continue
		var book: Dictionary = books[u.books[0]]
		var order := letters_by_count(book.bag)
		for i in u.ability_charges:
			var bag := ChipBag.new(book.bag, bag_extra_chaos(u, u.books[0]))
			while not bag.is_complete():
				bag.draw(rng)
			visions.append(bag.chips.map(func(c: String) -> int: return -1 if c == ChipBag.CHAOS else order.find(c)))
		return  # Прорицатель в отряде один


## Стихии мешочка от самой частой к самой редкой.
static func letters_by_count(bag: Dictionary) -> Array:
	var letters: Array = bag.keys().filter(func(k: String) -> bool: return k != ChipBag.CHAOS)
	letters.sort_custom(func(a: String, b: String) -> bool:
		return int(bag[a]) > int(bag[b]) or (int(bag[a]) == int(bag[b]) and a < b))
	return letters


## Видение в фишках книги: ранг 0 — самая частая стихия этой книги и т. д.
func vision_chips(vision: Array, book_id: String) -> Array[String]:
	var order := letters_by_count(books[book_id].bag)
	var out: Array[String] = []
	for r in vision:
		out.append(ChipBag.CHAOS if int(r) < 0 else order[mini(int(r), order.size() - 1)])
	return out


func seer_alive() -> bool:
	return living(Unit.PARTY).any(func(u: Unit) -> bool: return u.ability == "visions")


func can_use_vision(u: Unit, bag: ChipBag) -> bool:
	return u != null and u.is_wizard() and not visions.is_empty() and seer_alive() and bag != null and bag.is_complete()


func use_vision(u: Unit, bag: ChipBag, index: int, book_id: String) -> void:
	var v: Array = visions[index]
	visions.remove_at(index)
	bag.chips = vision_chips(v, book_id)
	for s in living(Unit.PARTY):
		if s.ability == "visions":
			s.ability_charges = visions.size()
	_log("%s заменяет тройку видением Прорицателя." % u.name, "luck")


## Учёный: овца ломается от Хаоса II/III — её 2 слота освобождаются.
func _sheep_check(caster: Unit, book_id: String, bag: ChipBag) -> void:
	if book_id != "sheep" or caster.wizard == null or not (bag.combo_key() in ["X2", "X3"]):
		return
	var w := caster.wizard
	w.books.erase("sheep")
	caster.books.erase("sheep")
	w.sheep_broken = true
	w.max_books += 1
	_log("Механическая овца %s ломается! Её слоты свободны до починки." % caster.name, "bad")


## Друид ворчит, когда в отряде колдуют огнём.
func _druid_grumble(caster: Unit, bag: ChipBag) -> void:
	if not caster.is_wizard() or not bag.chips.has("F") or rng.randf() > 0.35:
		return
	for u in living(Unit.PARTY):
		if u.ability == "beast_call" and u != caster:
			var lines: Array = GameData.load_classes().druid.get("grumbles", [])
			if not lines.is_empty():
				_log("%s: «%s»" % [u.name, lines[rng.randi_range(0, lines.size() - 1)]], "info")
			return


# --- Перемотка (Хрономант) -----------------------------------------------------

func _side_hp() -> Dictionary:
	var out := {"party": 0.0, "enemies": 0.0}
	for u in units:
		if u.alive():
			out["party" if u.side == Unit.PARTY else "enemies"] += u.hp + u.shield + u.fortify
	return out


func can_rewind() -> bool:
	if _snapshot.is_empty() or last_cast.is_empty():
		return false
	for u in living(Unit.PARTY):
		if u.ability == "rewind" and u.ability_charges > 0:
			return true
	return false


## Отматывает бой к состоянию перед последним кастом волшебника. Возвращает того, кто кастует заново.
func rewind() -> Unit:
	if not can_rewind():
		return null
	var chrono: Unit = null
	for u in living(Unit.PARTY):
		if u.ability == "rewind" and u.ability_charges > 0:
			chrono = u
	var caster_id: int = _snapshot.caster
	restore(_snapshot)
	# Заряд тратится уже после восстановления (иначе снимок вернул бы его).
	for u in units:
		if u.id == chrono.id:
			u.ability_charges -= 1
	_snapshot = {}
	last_cast = {}
	_log("%s отматывает время назад — каст переигрывается!" % chrono.name, "luck")
	for u in units:
		if u.id == caster_id:
			current = u
			return u
	return null


func snapshot() -> Dictionary:
	var list := []
	for u in units:
		list.append({
			"hp": u.hp, "max_hp": u.max_hp, "shield": u.shield, "fortify": u.fortify,
			"fortify_turns": u.fortify_turns, "statuses": u.statuses.duplicate(true), "meter": u.meter,
			"speed": u.speed, "attack": u.attack, "charges": u.ability_charges, "pool": u.ability_pool,
			"extra_casts": u.extra_casts, "books": u.books.duplicate(), "used": u.books_used.duplicate(),
			"item": u.wizard.item if u.wizard else "", "item2": u.wizard.item2 if u.wizard else "",
		})
	return {"units": list, "count": units.size(), "outcome": outcome, "downed": downed.duplicate(),
		"tally": tally.duplicate(), "stolen": stolen.duplicate(true), "turn_count": turn_count,
		"visions": visions.duplicate(true)}


func restore(snap: Dictionary) -> void:
	units.resize(int(snap.count))
	for i in units.size():
		var u := units[i]
		var d: Dictionary = snap.units[i]
		u.hp = d.hp
		u.max_hp = d.max_hp
		u.shield = d.shield
		u.fortify = d.fortify
		u.fortify_turns = d.fortify_turns
		u.statuses = d.statuses.duplicate(true)
		u.meter = d.meter
		u.speed = d.speed
		u.attack = d.attack
		u.ability_charges = d.charges
		u.ability_pool = d.pool
		u.extra_casts = d.extra_casts
		u.books.assign(d.books)
		u.books_used = d.used.duplicate()
		if u.wizard:
			u.wizard.item = d.item
			u.wizard.item2 = d.item2
	outcome = snap.outcome
	downed.assign(snap.downed)
	tally = snap.tally.duplicate()
	stolen = snap.stolen.duplicate(true)
	turn_count = snap.turn_count
	visions = snap.visions.duplicate(true)


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
	if EffectParser.deals_damage(spec):
		return
	_log("%s добивает тростью!" % caster.name, "damage")
	_hit(target, 1.0, caster)


func _apply_spell(caster: Unit, target: Unit, spell: Dictionary, chips: Array[String], book_id: String = "") -> void:
	var spec := EffectParser.parse(spell)
	# Некромант и Книга Святости: 50 % — наоборот. Учёный и «ненаучные» книги: 5 % мимо, 5 % наоборот.
	if caster.ability == "raise_dead" and book_id == "holy" and rng.randf() < 0.5:
		spec = EffectParser.invert(spec)
		_log("Святость в руках Некроманта срабатывает наоборот!", "misfire")
	elif caster.ability == "workshop" and book_id != "" and book_id != "sheep":
		var r := rng.randf()
		if r < 0.05:
			_log("«Это ненаучно!» — %s не верит в заклинание, и оно не срабатывает." % caster.name, "fizzle")
			return
		if r < 0.1:
			spec = EffectParser.invert(spec)
			_log("«Это ненаучно!» — заклинание срабатывает наоборот.", "misfire")
	if spec.nothing:
		_log("Ничего не произошло.", "fizzle")
	var element := "F" if chips.has("F") else "?"
	var bonus := caster.power_bonus()
	var hurt_ally := false
	var helped_enemy := false
	var harmful: bool = spec.damage > 0 or spec.meter < 0 or spec.strip_buffs or spec.statuses.any(
		func(s: Dictionary) -> bool: return Unit.DEBUFFS.has(s.id))

	var alive_before := living()
	if target and harmful and caster.has("misdirect"):
		caster.statuses.erase("misdirect")
		var any := living()
		target = any[rng.randi_range(0, any.size() - 1)]
		_log("Дурной знак: заклинание уходит в %s!" % target.name, "misfire")
	if target and harmful and caster.has("self_trap") and target != caster:
		caster.statuses.erase("self_trap")
		target = caster
		_log("Зеркальная ловушка: %s бьёт сам себя!" % caster.name, "misfire")
	var recipients := _recipients(spec, caster, target)
	if caster.ability == "visions" and ChipBag.key_for(chips) in ["X2", "X3"] and not recipients.has(caster):
		recipients.append(caster)
		_log("«Я это предвидел…» — Хаос задевает и %s." % caster.name, "misfire")
	for r in recipients:
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
			var dmg: int = spec.damage
			if spec.get("undead_damage", 0) > 0 and is_undead(who):
				dmg = spec.undead_damage
				_log("Святой огонь жжёт нежить!", "damage")
			_hit(who, float(maxi(0, dmg + bonus)), caster, element, spec.get("pierce", false))
			if who != caster and who.side == caster.side:
				hurt_ally = true
		if who.side != caster.side and (spec.heal > 0 or spec.shield > 0
				or spec.statuses.any(func(st: Dictionary) -> bool: return Unit.BUFFS.has(st.id))):
			helped_enemy = true
		if spec.heal > 0 and who.alive():
			var times := 1
			if caster.ability == "double_grace" and who.side == caster.side \
					and rng.randf() < DOUBLE_GRACE_CHANCE:
				times = 2
				_log("Двойная благодать!", "luck")
			for i in times:
				var before := who.hp
				_restore(who, float(maxi(0, spec.heal + bonus)))
				if caster.ability == "decoy" and who.hp > before and rng.randf() < 0.1:
					var list: Array = who.get_meta("illusory", [])
					list.append({"amount": who.hp - before, "turns": 2})
					who.set_meta("illusory", list)
					_log("Лечение %s — иллюзия: исчезнет через 2 хода." % who.name, "misfire")
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
		for sid in spec.get("special", []):
			if not ONCE_SPECIALS.has(sid):
				_special(sid, caster, who, spell, book_id)
		if not spec.get("special", []).has("echo"):
			who.set_meta("last_spell", {"spell": spell, "book": book_id, "chips": chips})

	if spec.splash > 0 and target:
		for u in living(target.side):
			if u != target:
				_hit(u, float(spec.splash), caster, element)
				if u != caster and u.side == caster.side:
					hurt_ally = true
	for j in spec.jumps:
		for u in _jump_targets(j, caster, target):
			_log("Молния перескакивает на %s!" % u.name, "damage")
			_hit(u, float(j.damage), caster, element)
			if u != caster and u.side == caster.side:
				hurt_ally = true
	_check_oath(caster, hurt_ally)
	if caster.is_wizard() and (hurt_ally or helped_enemy):
		tally.mishaps += 1
	if spec.self_damage > 0:
		_log("Отдача по %s." % caster.name, "damage")
		_hurt(caster, float(spec.self_damage), null)
	if spec.self_heal > 0 and caster.alive():
		_restore(caster, float(spec.self_heal))
	for s in spec.caster_statuses:
		_apply_status(caster, s, caster)
	for sid in spec.get("special", []):
		if ONCE_SPECIALS.has(sid):
			_special(sid, caster, target, spell, book_id)
	if not spec.get("summon", {}).is_empty():
		_summon_from_spec(spec.summon, caster, target)
	if spec.get("raise_fallen", "") != "":
		for u in alive_before:
			if not u.alive() and not u.is_wizard() and u.side != caster.side:
				_log("%s встаёт из мёртвых на стороне %s!" % [u.name, caster.name], "revive")
				summon(spec.raise_fallen, caster, caster.side)


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


## Кого задевает перескок урона: случайные живые, кроме основной цели (и кастующего — для союзников).
func _jump_targets(jump: Dictionary, caster: Unit, target: Unit) -> Array[Unit]:
	var pool: Array[Unit] = []
	match String(jump.side):
		"target":
			if target:
				pool = living(target.side)
		"caster":
			pool = living(caster.side)
		_:
			pool = living()
	pool = pool.filter(func(u: Unit) -> bool: return u != target and (jump.side != "caster" or u != caster))
	var out: Array[Unit] = []
	for i in mini(int(jump.count), pool.size()):
		var k := rng.randi_range(0, pool.size() - 1)
		out.append(pool[k])
		pool.remove_at(k)
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
				if u.side == owner.side and (not u.alive() or (u.wizard != null and u.wizard.zombie)):
					out.append(u)
		"enemy":
			out = living(opposite(owner.side))
	return out


func can_use_item(owner: Unit) -> bool:
	if owner.wizard == null or owner.wizard.item == "" or owner.wizard.no_item_battle:
		return false
	var it: Dictionary = items[owner.wizard.item]
	if it.get("camp_only", false) or it.target == "passive":
		return false
	return not item_targets(owner, owner.wizard.item).is_empty()


## Применяет предмет владельца. Ход не тратится.
func use_item(owner: Unit, target: Unit) -> void:
	var item_id := owner.wizard.item
	var it: Dictionary = items[item_id]
	tally.items += 1
	owner.wizard.item = ""
	owner.wizard.shift_items()
	# Алхимик: «Нестабильная смесь» — 5 %, что предмет взрывается в руках.
	if owner.ability == "mix" and rng.randf() < 0.05:
		_log("%s: «%s» взрывается в руках!" % [owner.name, it.name], "bad")
		var allies := living(owner.side)
		var i := allies.find(owner)
		_hurt(owner, 2.0, null)
		if allies.size() > 1:
			_hurt(allies[(i + 1) % allies.size()], 2.0, null)
		_check_outcome()
		return
	_log("%s использует предмет: %s." % [owner.name, it.name], "item")
	var e: Dictionary = it.effect
	if e.has("revive") and target.alive() and target.wizard and target.wizard.zombie:
		target.wizard.cure_zombie()
		target.max_hp = target.wizard.max_hp()
		target.hp = Unit.q(minf(target.max_hp, target.hp + float(e.revive)))
		_log("%s снова живой — больше не зомби!" % target.name, "revive")
		return
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
func _hit(who: Unit, amount: float, source: Unit, element: String = "?", pierce: bool = false) -> void:
	if not who.alive() or amount <= 0.0:
		return
	if who.has("doom"):
		who.statuses.erase("doom")
		amount += 3.0
		_log("Кармический долг: +3 урона по %s." % who.name, "damage")
	if who.has("invulnerable"):
		if not who.statuses.invulnerable.get("hold", false):
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
	var guard := 0 if pierce else who.defense()
	if who.passive == "rat_guard" and living(who.side).size() > 1:
		guard += 1
	amount = maxf(1.0, amount - guard)
	_hurt(who, amount, source)


## Урон без проверок защиты (яд, горение, отдача).
## Сначала тратится Укрепление, потом Щит, потом здоровье.
func _hurt(who: Unit, amount: float, source: Unit) -> void:
	amount = Unit.q(amount)
	if not _splitting and amount > 0.0:
		if who.has("shared_pain"):
			var side := living(who.side)
			if side.size() > 1:
				_splitting = true
				var part := Unit.q(amount / side.size())
				_log("Преломление: урон по %s делится на всех на её стороне." % who.name, "block")
				for u in side:
					_hurt(u, part, source)
				_splitting = false
				return
		if who.has("bond"):
			var mate := _unit_by_id(int(who.statuses.bond.source))
			if mate and mate.alive() and mate != who:
				_splitting = true
				var half := Unit.q(amount / 2.0)
				_log("Кровная связь: %s принимает половину урона." % mate.name, "block")
				_hurt(mate, half, source)
				_splitting = false
				amount = Unit.q(amount - half)
	for layer in ["fortify", "shield"]:
		if layer == "shield" and source and source.traits.has("pierce_shield"):
			continue
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
	if who.alive() and who.has_meta("split"):
		_split(who, amount)
	_log("%s получает %s урона (%s)." % [who.name, Unit._num(amount), who.hp_text()], "big_damage" if amount >= BIG_HIT else "damage")
	if not who.alive():
		_on_down(who, source)


func _on_down(who: Unit, source: Unit) -> void:
	if who.is_wizard():
		tally.downs += 1
		if not downed.has(who):
			downed.append(who)
	_log("%s выбывает!" % who.name, "kill")
	who.statuses.clear()
	who.shield = 0.0
	who.fortify = 0.0
	if who.wizard and who.wizard.item != "" and items.get(who.wizard.item, {}).get("effect", {}).has("auto_revive"):
		var hp: float = items[who.wizard.item].effect.auto_revive
		_log("Срабатывает %s!" % items[who.wizard.item].name, "revive")
		who.wizard.item = ""
		who.wizard.shift_items()
		_revive(who, hp)
		return
	if who.traits.has("reassemble") and not who.get_meta("reassembled", false):
		who.set_meta("reassembled", true)
		_log("%s рассыпается… и собирается обратно!" % who.name, "revive")
		_revive(who, ceilf(who.max_hp / 2.0))
		return
	if who.passive == "mount":
		for rider in living(who.side):
			if rider.has_meta("dismount"):
				var d: Dictionary = rider.get_meta("dismount")
				rider.speed = float(d.speed)
				rider.attack += int(d.damage)
				rider.remove_meta("dismount")
				_log("%s спешивается: медленнее, но злее (урон +%d)!" % [rider.name, int(d.damage)], "special", "leader")
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
	if who.has_meta("heal_minus"):
		amount = maxf(0.0, amount - float(who.get_meta("heal_minus")))
	var before := who.hp
	who.hp = Unit.q(minf(who.max_hp, who.hp + amount))
	if who.hp > before:
		who.set_meta("healed_total", float(who.get_meta("healed_total", 0.0)) + who.hp - before)
		hp_changed.emit(who, who.hp - before, "heal")
		_log("%s лечится на %s (%s)." % [who.name, Unit._num(who.hp - before), who.hp_text()], "big_heal" if who.hp - before >= BIG_HIT else "heal")


## Любой положительный эффект (лечение, щит, бафф) снимает Разбитость.
func _cheer(who: Unit) -> void:
	if who.has("aching"):
		who.statuses.erase("aching")
		_log("%s приходит в себя — Разбитость снята." % who.name, "buff", "aching")


## Деление (Матушка-Слизь): каждые N полученного урона отделяется слизень.
func _split(who: Unit, amount: float) -> void:
	var cfg: Dictionary = who.get_meta("split")
	var acc := float(who.get_meta("split_acc", 0.0)) + amount
	while acc >= float(cfg.every):
		acc -= float(cfg.every)
		var u := add_enemy(cfg.unit, who.side)
		u.creature = who.creature
		u.set_meta("spawned_by", who.id)
		u.set_meta("summoned", true)
		_log("От %s отделяется %s!" % [who.name, u.name], "summon")
		unit_added.emit(u)
		if cfg.get("once", false):
			who.remove_meta("split")
			return
	who.set_meta("split_acc", acc)


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
	if enemy.has("echo_next"):
		enemy.statuses.erase("echo_next")
		_log("Двойник заклинания: %s действует дважды!" % enemy.name, "misfire")
		_enemy_action(enemy)
		if not enemy.alive() or outcome != "":
			end_turn(enemy)
			return
	_enemy_action(enemy)
	end_turn(enemy)


func _enemy_action(enemy: Unit) -> void:
	var special := _ready_special(enemy)
	if not special.is_empty():
		special.cd = int(special.cooldown)
		_use_special(enemy, special)
	elif enemy.behaviour == "healer" and _heal_ally(enemy):
		pass
	elif enemy.attack <= 0:
		_log("%s ждёт." % enemy.name, "enemy")
	elif enemy.traits.has("every_other") and enemy.get_meta("resting", false):
		enemy.set_meta("resting", false)
		_log("%s переводит дух." % enemy.name, "enemy")
	else:
		if enemy.traits.has("every_other"):
			enemy.set_meta("resting", true)
		if enemy.traits.has("owl"):
			_owl_watch(enemy)
		var wounded := false
		for i in enemy.attacks:
			var target := _enemy_target(enemy)
			if target == null or not enemy.alive():
				break
			if i == 0:
				wounded = target.hp < target.max_hp
			var hits: Array[Unit] = [target]
			if enemy.traits.has("swarm"):
				hits = living(target.side)
				_log("%s налетает на всех на стороне %s." % [enemy.name, target.name], "enemy")
			else:
				_log("%s атакует %s." % [enemy.name, target.name], "enemy")
			for t in hits:
				_enemy_strike(enemy, t, float(enemy.attack))
				if enemy.has_meta("on_hit_status") and t.alive():
					var st: Dictionary = enemy.get_meta("on_hit_status")
					_apply_status(t, {"id": st.id, "turns": int(st.turns)}, enemy)
		if enemy.traits.has("double_if_wounded") and wounded:
			var again := _enemy_target(enemy)
			if again and enemy.alive():
				_log("%s чует кровь и бьёт ещё раз!" % enemy.name, "enemy")
				_enemy_strike(enemy, again, float(enemy.attack))


## Сова: снимает Невидимость с врагов и Ослепление с хозяина.
func _owl_watch(owl: Unit) -> void:
	for u in living(opposite(owl.side)):
		if u.has("invisible"):
			u.statuses.erase("invisible")
			_log("%s замечает %s — Невидимость снята." % [owl.name, u.name], "debuff", "invisible")
	var master := _unit_by_id(int(owl.get_meta("owner", -1)))
	if master and master.has("blind"):
		master.statuses.erase("blind")
		_log("%s ведёт %s — Ослепление снято." % [owl.name, master.name], "buff", "blind")


# --- Особые эффекты заклинаний (EffectParser.SPECIAL_PHRASES) -------------------

## Срабатывают один раз на каст, а не на каждого получателя.
const ONCE_SPECIALS := ["give_item_party", "shuffle_meters", "flip_all", "random_chaos", "random_spell", "pick_spell"]
const RANDOM_DEBUFFS := ["burn", "poison", "slow", "vulnerable", "weak", "blind", "confusion", "forget", "disease"]
const RANDOM_BUFFS := ["regen", "haste", "stoneskin", "inspire", "bless", "reflect", "invulnerable"]


## Нежить: призванные Некрономиконом и все скелеты, зомби, призраки.
func is_undead(u: Unit) -> bool:
	if u.creature and GameData.creatures().get(u.class_id, {}).get("group", "") == "undead":
		return true
	var n := u.name.to_lower()
	return n.contains("скелет") or n.contains("зомби") or n.contains("призрак") \
		or (u.wizard != null and u.wizard.zombie)


func _pick(list: Array) -> Variant:
	return list[rng.randi_range(0, list.size() - 1)]


func _special(id: String, caster: Unit, who: Unit, spell: Dictionary, book_id: String) -> void:
	match id:
		"give_potion", "give_item":
			if who == null or who.wizard == null:
				_log("Предмет достаётся только волшебнику — не сработало.", "fizzle")
				return
			var item_id := "potion_heal" if id == "give_potion" else String(_pick(_item_ids()))
			if who.wizard.add_item(item_id):
				_log("%s получает предмет: %s." % [who.name, items[item_id].name], "item")
			else:
				_log("У %s нет места под предмет." % who.name, "fizzle")
		"give_item_party":
			for u in party_wizards():
				var item_id := String(_pick(_item_ids()))
				if u.wizard.add_item(item_id):
					_log("%s получает предмет: %s." % [u.name, items[item_id].name], "item")
		"upgrade_item":
			if who == null or who.wizard == null:
				return
			var w := who.wizard
			if w.item == "":
				_special("give_item", caster, who, spell, book_id)
				return
			var better: Array = _item_ids().filter(func(i: String) -> bool: return int(items[i].weight) < int(items[w.item].weight))
			if better.is_empty():
				_log("Предмет %s и так редчайший." % who.name, "fizzle")
				return
			var old: String = items[w.item].name
			w.item = String(_pick(better))
			_log("%s: «%s» становится «%s»." % [who.name, old, items[w.item].name], "item")
		"bond":
			if who == caster:
				return
			who.add_status("bond", 2, 1, caster)
			caster.add_status("bond", 2, 1, who)
			_log("%s и %s связаны кровью: урон делится пополам." % [caster.name, who.name], "buff")
			status_applied.emit(who, "bond")
		"undo_turn":
			var lost := float(who.get_meta("turn_mark", who.hp)) - who.hp
			if lost <= 0.0:
				_log("%s ничего не терял с прошлого хода." % who.name, "fizzle")
			else:
				_restore(who, minf(4.0, lost))
		"extend_buffs":
			for sid in who.statuses:
				if Unit.BUFFS.has(sid) and int(who.statuses[sid].turns) < 99:
					who.statuses[sid].turns += 2
			_log("Баффы %s продлены на 2 хода." % who.name, "buff")
		"shuffle_meters":
			var all := living()
			var meters: Array = all.map(func(u: Unit) -> float: return u.meter)
			for i in range(meters.size() - 1, 0, -1):
				var j := rng.randi_range(0, i)
				var t: float = meters[i]
				meters[i] = meters[j]
				meters[j] = t
			for i in all.size():
				all[i].meter = meters[i]
			_log("Очередь ходов перемешана!", "misfire")
		"echo":
			var last: Dictionary = who.get_meta("last_spell", {})
			if last.is_empty() or _spell_depth > 1:
				_log("На %s ещё ничего не кастовали — эху нечего повторить." % who.name, "fizzle")
				return
			_log("Эхо: «%s» повторяется по %s." % [last.spell.name, who.name], "misfire")
			_nested(caster, who, last.spell, last.book)
		"copy_buffs":
			for sid in who.statuses:
				if Unit.BUFFS.has(sid):
					caster.add_status(sid, int(who.statuses[sid].turns))
			_log("%s копирует баффы %s." % [caster.name, who.name], "buff")
		"swap_meter_side", "swap_meter_any":
			var pool := living() if id == "swap_meter_any" else living(who.side)
			pool.erase(who)
			if pool.is_empty():
				return
			var other: Unit = _pick(pool)
			var t := who.meter
			who.meter = other.meter
			other.meter = t
			_log("%s и %s меняются местами в очереди." % [who.name, other.name], "misfire")
		"swap_meter_caster":
			var t := who.meter
			who.meter = caster.meter
			caster.meter = t
			_log("%s и %s меняются шкалами хода." % [caster.name, who.name], "misfire")
		"random_meter":
			who.meter = rng.randf_range(0.0, 100.0)
			_log("Шкала хода %s теперь %d %%." % [who.name, int(who.meter)], "misfire")
		"borrow_book":
			if who.is_wizard() and not caster.books.is_empty():
				var b: String = _pick(caster.books)
				who.set_meta("borrowed_book", b)
				_log("%s в следующий раз кастует из книги «%s»." % [who.name, books[b].name], "misfire")
			elif not who.is_wizard():
				_log("%s повторяет свою атаку по самому себе!" % who.name, "misfire")
				_hit(who, float(maxi(1, who.attack)), who)
		"double_next":
			who.add_status("echo_next", 99)
			status_applied.emit(who, "echo_next")
		"swap_statuses":
			if who == caster:
				return
			var t := who.statuses
			who.statuses = caster.statuses
			caster.statuses = t
			_log("%s и %s меняются всеми эффектами." % [caster.name, who.name], "misfire")
		"self_trap", "misdirect", "doom":
			who.add_status(id, 99)
			status_applied.emit(who, id)
		"share_pain":
			who.add_status("shared_pain", 2)
			status_applied.emit(who, "shared_pain")
		"fate_reflect":
			who.add_status("reflect", 3)
			status_applied.emit(who, "reflect")
		"flip_all":
			for u in living():
				var flipped := {}
				for sid in u.statuses:
					var st: Dictionary = u.statuses[sid]
					if Unit.BUFFS.has(sid):
						flipped[_pick(RANDOM_DEBUFFS)] = {"turns": st.turns, "stacks": 1, "source": st.source}
					elif Unit.DEBUFFS.has(sid):
						flipped[_pick(RANDOM_BUFFS)] = {"turns": st.turns, "stacks": 1, "source": st.source}
					else:
						flipped[sid] = st
				u.statuses = flipped
			_log("Зеркальный мир: все эффекты на арене — наоборот!", "misfire")
		"foresight":
			if who.is_wizard():
				var bag := ChipBag.new(books[who.books[0]].bag, bag_extra_chaos(who, who.books[0])) if not who.books.is_empty() else null
				if bag == null:
					return
				while not bag.is_complete():
					bag.draw(rng)
				var order := letters_by_count(books[who.books[0]].bag)
				who.set_meta("foresight", bag.chips.map(func(c: String) -> int: return -1 if c == ChipBag.CHAOS else order.find(c)))
				_log("%s видит свою следующую тройку заранее." % who.name, "luck")
			else:
				var sp := _ready_special_peek(who)
				_log("Раскрыто: следующая способность %s — %s." % [who.name, sp], "luck")
		"curse_stat":
			match rng.randi_range(0, 3):
				0:
					who.wisdom -= 1
					_log("%s: −1 Мудрость до конца боя." % who.name, "debuff")
				1:
					who.defense_bonus -= 1
					_log("%s: −1 Защита до конца боя." % who.name, "debuff")
				2:
					who.luck_bonus -= 1
					_log("%s: −1 Удача до конца боя." % who.name, "debuff")
				_:
					who.speed = maxf(1.0, who.speed - 1.0)
					_log("%s: −1 Скорость до конца боя." % who.name, "debuff")
		"karma":
			var dmg := minf(5.0, float(who.get_meta("healed_total", 0.0)))
			if dmg <= 0.0:
				_log("%s за бой не лечился — карма чиста." % who.name, "fizzle")
			else:
				_log("Карма: %s получает %s урона за всё своё лечение." % [who.name, Unit._num(dmg)], "damage")
				_hurt(who, dmg, caster)
		"fortune":
			if who.is_wizard():
				who.add_status("muse", 99)
				status_applied.emit(who, "muse")
			else:
				who.add_status("miss", 99)
				status_applied.emit(who, "miss")
		"random_debuff", "random_buff", "random_both":
			if id != "random_buff":
				_apply_status(who, {"id": _pick(RANDOM_DEBUFFS), "turns": 2}, caster)
			if id != "random_debuff":
				_apply_status(who, {"id": _pick(RANDOM_BUFFS), "turns": 2}, caster)
		"swap_hp":
			if who == caster or who.is_boss:
				_log("%s невосприимчив к обмену телами." % who.name, "fizzle")
				return
			var a := who.hp
			who.hp = Unit.q(clampf(caster.hp, 0.1, who.max_hp))
			caster.hp = Unit.q(clampf(a, 0.1, caster.max_hp))
			_log("%s и %s меняются здоровьем: %s и %s." % [caster.name, who.name, caster.hp_text(), who.hp_text()], "misfire")
			hp_changed.emit(who, 0.0, "heal")
			hp_changed.emit(caster, 0.0, "heal")
		"random_spell", "random_chaos", "pick_spell":
			_random_cast(id, caster, who, book_id)
		_:
			push_warning("Неизвестный особый эффект: %s" % id)


func _item_ids() -> Array:
	var ids := items.keys()
	ids.sort()
	return ids


## Вложенный каст (эхо, случайное заклинание). Глубина ограничена, чтобы хаос не вызывал хаос бесконечно.
func _nested(caster: Unit, target: Unit, spell: Dictionary, book_id: String) -> void:
	if _spell_depth > 2:
		return
	_spell_depth += 1
	var chips: Array[String] = []
	var combo := String(spell.combo)
	if combo.begins_with("X"):
		for i in int(combo.substr(1)):
			chips.append(ChipBag.CHAOS)
	else:
		for c in combo:
			chips.append(c)
	_apply_spell(caster, target, spell, chips, book_id)
	_spell_depth -= 1


## Дикий всплеск (хаос из любой книги), Всплеск (любое заклинание по цели),
## «Судьба переписана» (лучшая комбинация своей книги).
func _random_cast(kind: String, caster: Unit, target: Unit, book_id: String) -> void:
	var ids := books.keys()
	ids.sort()
	var picks: Array = []  # [book, spell]
	for b in ids:
		if kind == "pick_spell" and b != book_id:
			continue
		for sp in books[b].spells:
			var chaos := String(sp.combo).begins_with("X")
			if kind == "random_chaos" and not chaos:
				continue
			if kind != "random_chaos" and chaos:
				continue
			var sid: Array = EffectParser.parse(sp).get("special", [])
			if sid.has("random_chaos") or sid.has("random_spell") or sid.has("pick_spell"):
				continue
			picks.append([b, sp])
	if picks.is_empty():
		return
	var choice: Array = _pick(picks)
	if kind == "pick_spell":
		var foe := target != null and target.side != caster.side
		var best := -1.0
		for p in picks:
			var spec := EffectParser.parse(p[1])
			var v: float = float(EffectParser.harm_total(spec)) if foe else float(spec.heal + spec.shield)
			if v > best:
				best = v
				choice = p
		_log("%s переписывает судьбу и выбирает «%s»." % [caster.name, choice[1].name], "luck")
	else:
		_log("Срабатывает «%s» из книги «%s»!" % [choice[1].name, books[choice[0]].name], "chaos")
	var aim := target if target != null and target.alive() else caster
	_nested(caster, aim, choice[1], choice[0])


## Какая особая атака врага будет следующей (без изменения перезарядок).
func _ready_special_peek(enemy: Unit) -> String:
	var best: Dictionary = {}
	for sp in enemy.specials:
		if best.is_empty() or int(sp.cd) < int(best.cd):
			best = sp
	if best.is_empty():
		return "обычная атака"
	return "«%s» через %d ход(а)" % [best.name, maxi(0, int(best.cd))]


## Одолженная книга (Копия приёма): волшебник обязан кастовать из неё. Возвращает id или "".
func take_borrowed_book(u: Unit) -> String:
	if not u.has_meta("borrowed_book"):
		return ""
	var b: String = u.get_meta("borrowed_book")
	u.remove_meta("borrowed_book")
	return b


# --- Призванные существа (balance.md, раздел 6) ----------------------------------

const SUMMON_LIMIT := 2


## Призывает существо из data/creatures.json. side — сторона, target — цель заклинания:
## первым ходом существо атакует её (враг) или принимает первый удар по ней (союзник).
func summon(creature_id: String, caster: Unit, side: String, target: Unit = null) -> Unit:
	var db := GameData.creatures()
	if not db.has(creature_id):
		return null
	var cfg: Dictionary = db[creature_id]
	var u := add_enemy(cfg, side)
	u.creature = true
	u.class_id = creature_id
	u.set_meta("summoned", true)
	if caster and side == caster.side:
		u.set_meta("owner", caster.id)
		var own: Array[Unit] = living(side).filter(func(x: Unit) -> bool:
			return x.creature and int(x.get_meta("owner", -1)) == caster.id)
		while own.size() > SUMMON_LIMIT:
			var old: Unit = own.pop_front()
			old.hp = 0.0
			old.statuses.clear()
			_log("%s уходит: у %s не больше %d существ." % [old.name, caster.name, SUMMON_LIMIT], "info")
			hp_changed.emit(old, 0.0, "damage")
	if target and target.alive() and target != u:
		if target.side != side:
			u.set_meta("first_target", target.id)
		else:
			target.set_meta("guarded_by", u.id)
	var whose := "" if caster == null else (" на стороне %s" % caster.name if side == caster.side else " — против %s" % caster.name)
	_log("Появляется %s%s!" % [u.name, whose], "summon")
	unit_added.emit(u)
	return u


func _summon_from_spec(sm: Dictionary, caster: Unit, target: Unit) -> void:
	var id: String = sm.get("id", "")
	if id == "":
		var pool: Array = []
		for cid in GameData.creatures():
			if GameData.creatures()[cid].group == sm.group:
				pool.append(cid)
		pool.sort()
		if pool.is_empty():
			return
		id = pool[rng.randi_range(0, pool.size() - 1)]
	var side := caster.side
	match String(sm.side):
		"random":
			side = caster.side if rng.randf() < 0.5 else opposite(caster.side)
		"enemy":
			side = opposite(caster.side)
	summon(id, caster, side, target)


func _unit_by_id(id: int) -> Unit:
	for u in units:
		if u.id == id:
			return u
	return null


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
					target.wizard.shift_items()
		"aoe":
			for u in living(opposite(enemy.side)):
				_hit(u, float(sp.get("damage", 0)), enemy)
				if sp.has("status") and u.alive():
					_apply_status(u, {"id": sp.status, "turns": int(sp.turns)}, enemy)
			if sp.get("stun_one", false):
				var foes := living(opposite(enemy.side))
				if not foes.is_empty():
					_apply_status(foes[rng.randi_range(0, foes.size() - 1)], {"id": "stun", "turns": 1}, enemy)
		"rally":
			for u in living(enemy.side):
				_apply_status(u, {"id": "haste", "turns": int(sp.turns)}, enemy)
			enemy.attack += int(sp.bonus)
			enemy.set_meta("rally", {"bonus": int(sp.bonus), "turns": int(sp.turns) + 1})
		"absorb":
			var healed := 0.0
			for u in living(enemy.side):
				if u != enemy and u.get_meta("spawned_by", -1) == enemy.id:
					healed += u.hp
					u.hp = 0.0
					_log("%s поглощает %s." % [enemy.name, u.name], "special")
			if healed > 0.0:
				_restore(enemy, healed)
			_check_outcome()
		"summon":
			for i in int(sp.count):
				var u := add_enemy(sp.unit)
				u.set_meta("summoned", true)
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
	if target.has_meta("guarded_by"):
		var guard := _unit_by_id(int(target.get_meta("guarded_by")))
		target.remove_meta("guarded_by")
		if guard and guard.alive() and guard.side == target.side:
			_log("%s закрывает собой %s!" % [guard.name, target.name], "block")
			target = guard
	if attacker.has("self_trap"):
		attacker.statuses.erase("self_trap")
		_log("Зеркальная ловушка: %s бьёт сам себя!" % attacker.name, "misfire")
		target = attacker
	elif attacker.has("miss"):
		attacker.statuses.erase("miss")
		if rng.randf() < 0.5:
			_log("Колесо фортуны: %s промахивается!" % attacker.name, "block")
			return
	if target.traits.has("thorns") and attacker.alive():
		_log("%s колется: %s получает 1 урон." % [target.name, attacker.name], "damage")
		_hurt(attacker, 1.0, target)
	if target.has("reflect") and target.side != attacker.side:
		target.statuses.erase("reflect")
		_log("%s отражает атаку!" % target.name, "reflect", "reflect")
		target = attacker
	_hit(target, dmg, attacker)


func _enemy_target(enemy: Unit) -> Unit:
	var any := living()
	any.erase(enemy)
	if enemy.has("misdirect"):
		enemy.statuses.erase("misdirect")
		if not any.is_empty():
			var t := any[rng.randi_range(0, any.size() - 1)]
			_log("Дурной знак: удар %s уходит в %s!" % [enemy.name, t.name], "misfire")
			return t
	if enemy.has_meta("first_target"):
		var first := _unit_by_id(int(enemy.get_meta("first_target")))
		enemy.remove_meta("first_target")
		if first and first.alive() and first.side != enemy.side and not enemy.has("blind"):
			return first
	if enemy.traits.has("drunk") and rng.randf() < 0.2:
		var mates := living(enemy.side)
		mates.erase(enemy)
		if not mates.is_empty():
			_log("%s спьяну путает своих с чужими!" % enemy.name, "misfire")
			return mates[rng.randi_range(0, mates.size() - 1)]
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
		if (u.has("invisible") and not enemy.traits.has("true_sight")) or enemy.fears(u):
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
