class_name Combat
extends RefCounted
## Логика одного боя без графики: шкала хода, касты, эффекты, ИИ противников.
## UI и тесты работают с боем только через этот класс.

signal logged(text: String)

const METER_FULL := 100.0
const FIZZLE_PER_LUCK := 0.05
const WATER_ELEMENTAL_CHANCE := 0.2
const DOUBLE_GRACE_CHANCE := 0.05
## Эти статусы у боссов и предводителей превращаются в Сбив шкалы на 50 %.
const HARD_CONTROL := ["stun", "petrify", "toad"]

var books: Dictionary
var units: Array[Unit] = []
var rng := RandomNumberGenerator.new()
var current: Unit = null
var turn_count: int = 0
var outcome: String = ""  # "", "victory", "defeat"
var _next_id: int = 0


func _init(book_db: Dictionary, wizard_classes: Array, class_db: Dictionary,
		encounter: Dictionary, seed_value: int = 0) -> void:
	books = book_db
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	for class_id in wizard_classes:
		_add_wizard(class_id, class_db[class_id])
	for member in encounter.get("members", []):
		_add_enemy(member)


func _add_wizard(class_id: String, cfg: Dictionary) -> void:
	var u := _new_unit(cfg.name, Unit.PARTY, float(cfg.hp), float(cfg.speed))
	u.class_id = class_id
	for b in cfg.books:
		u.books.append(String(b))
	u.ability = cfg.get("ability", "")
	u.ability_charges = int(cfg.get("ability_charges", 0))


func _add_enemy(cfg: Dictionary) -> void:
	var u := _new_unit(cfg.name, Unit.ENEMIES, float(cfg.hp), float(cfg.speed))
	u.attack = int(cfg.damage)
	u.is_leader = bool(cfg.get("leader", false))
	u.special = cfg.get("special", {})
	u.special_cooldown = 1  # особая атака впервые — на 2-м ходу


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
	while outcome == "":
		var ready := _pop_ready()
		turn_count += 1
		current = ready
		_start_of_turn(ready)
		_check_outcome()
		if outcome != "":
			return null
		if not ready.alive():
			continue
		if ready.has("stun") or ready.has("petrify") or ready.has("toad"):
			_log("%s пропускает ход." % ready.name)
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
		_log("%s горит." % u.name)
		_hurt(u, 1.0, null)
	if u.has("poison"):
		_log("%s страдает от яда." % u.name)
		_hurt(u, float(u.statuses.poison.stacks), null)
	if u.has("regen") and u.alive():
		_restore(u, 1.0)


func end_turn(u: Unit) -> void:
	u.tick_down()
	_check_outcome()


func _check_outcome() -> void:
	if living(Unit.ENEMIES).is_empty():
		outcome = "victory"
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


## Ослепление и Очарование могут подменить выбранную цель.
func resolve_target(caster: Unit, chosen: Unit) -> Unit:
	if caster.has("blind"):
		var any := living()
		var t := any[rng.randi_range(0, any.size() - 1)]
		_log("%s ослеплён и кастует наугад в %s." % [caster.name, t.name])
		return t
	if caster.has("charm"):
		var allies := living(caster.side)
		var t := allies[rng.randi_range(0, allies.size() - 1)]
		_log("%s очарован и кастует в союзника: %s." % [caster.name, t.name])
		return t
	return chosen


func new_bag(caster: Unit, book_id: String) -> ChipBag:
	return ChipBag.new(books[book_id].bag, caster.extra_chaos_chips())


func spell_for(book_id: String, combo: String) -> Dictionary:
	for s in books[book_id].spells:
		if s.combo == combo:
			return s
	return {}


## Применяет заклинание по вытянутым фишкам. Завершает ход кастующего.
func cast(caster: Unit, target: Unit, book_id: String, bag: ChipBag) -> Dictionary:
	if caster.has("confusion"):
		bag.shuffle_order(rng)
	var spell := spell_for(book_id, bag.combo_key())
	_log("%s: «Я кастую!» — %s." % [caster.name, spell.name])
	_apply_spell(caster, target, spell, bag.chips)
	end_turn(caster)
	return spell


func _apply_spell(caster: Unit, target: Unit, spell: Dictionary, chips: Array[String]) -> void:
	var spec := EffectParser.parse(spell)
	if spec.nothing:
		_log("Ничего не произошло.")
	var element := "F" if chips.has("F") else "?"
	var bonus := caster.power_bonus()
	var harmful: bool = spec.damage > 0 or spec.meter < 0 or spec.strip_buffs or spec.statuses.any(
		func(s: Dictionary) -> bool: return Unit.DEBUFFS.has(s.id))

	for r in _recipients(spec, caster, target):
		var who := r
		if harmful and who != caster and who.has("reflect"):
			who.statuses.erase("reflect")
			_log("%s отражает заклинание обратно!" % who.name)
			who = caster
		if spec.area == "target" and _fizzles(caster, who, spec):
			_log("Удача! Заклинание по %s рассеялось." % who.name)
			continue
		if spec.revive_hp > 0 and not who.alive():
			who.hp = minf(who.max_hp, spec.revive_hp)
			who.statuses.clear()
			_log("%s возвращается в бой с %s ЗД!" % [who.name, Unit._num(who.hp)])
			continue
		if not who.alive():
			continue
		if spec.damage > 0:
			_hit(who, float(maxi(0, spec.damage + bonus)), caster, element)
		if spec.heal > 0 and who.alive():
			var times := 1
			if caster.ability == "double_grace" and who.side == caster.side \
					and rng.randf() < DOUBLE_GRACE_CHANCE:
				times = 2
				_log("Двойная благодать!")
			for i in times:
				_restore(who, float(maxi(0, spec.heal + bonus)))
		if spec.shield > 0 and who.alive():
			who.shield += maxi(0, spec.shield + bonus)
			_log("%s получает Щит %d." % [who.name, spec.shield + bonus])
		if spec.cleanse:
			who.remove_debuffs()
			_log("%s очищен." % who.name)
		if spec.strip_buffs:
			who.remove_buffs()
			_log("%s теряет все баффы." % who.name)
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
	if spec.self_damage > 0:
		_log("Отдача по %s." % caster.name)
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


# --- Эффекты -------------------------------------------------------------

func _apply_status(who: Unit, s: Dictionary, source: Unit) -> void:
	if not who.alive():
		return
	var id: String = s.id
	if (who.is_leader or who.has("boss")) and HARD_CONTROL.has(id):
		_log("%s не поддаётся контролю — Сбив шкалы на 50 %%." % who.name)
		_shift_meter(who, -50)
		return
	who.add_status(id, int(s.turns), int(s.get("stacks", 1)), source)
	_log("%s: %s." % [who.name, status_name(id)])


func _shift_meter(who: Unit, percent: int) -> void:
	who.meter = maxf(0.0, who.meter + percent)
	_log("%s: шкала хода %+d %%." % [who.name, percent])


## Удар с учётом Неуязвимости, Элементальной формы, Жабы, Уязвимости, Защиты и Щита.
func _hit(who: Unit, amount: float, source: Unit, element: String = "?") -> void:
	if not who.alive() or amount <= 0.0:
		return
	if who.has("invulnerable"):
		who.statuses.erase("invulnerable")
		_log("%s неуязвим — удар прошёл мимо." % who.name)
		return
	if element != "F" and (who.has("elemental") or (who.ability == "elemental_form"
			and rng.randf() < WATER_ELEMENTAL_CHANCE)):
		_log("%s становится водой — урон не прошёл." % who.name)
		return
	if who.has("toad"):
		amount *= 2.0
		who.statuses.erase("toad")
		_log("%s снова человек (удар по жабе — двойной)." % who.name)
	if who.has("vulnerable"):
		amount += 1.0
	amount = maxf(1.0, amount - who.defense())
	_hurt(who, amount, source)


## Урон без проверок защиты (яд, горение, отдача) — только Щит.
func _hurt(who: Unit, amount: float, source: Unit) -> void:
	if who.shield > 0.0:
		var absorbed := minf(who.shield, amount)
		who.shield -= absorbed
		amount -= absorbed
		if absorbed > 0.0:
			_log("Щит %s поглощает %s." % [who.name, Unit._num(absorbed)])
	if amount <= 0.0:
		return
	who.hp = maxf(0.0, who.hp - amount)
	_log("%s получает %s урона (%s)." % [who.name, Unit._num(amount), who.hp_text()])
	if not who.alive():
		_log("%s выбывает!" % who.name)
		who.statuses.clear()
		who.shield = 0.0
		if who.is_leader:
			_morale_break(who, source)
		_check_outcome()


func _restore(who: Unit, amount: float) -> void:
	if who.has("disease"):
		amount *= 0.5
	var before := who.hp
	who.hp = minf(who.max_hp, who.hp + amount)
	if who.hp > before:
		_log("%s лечится на %s (%s)." % [who.name, Unit._num(who.hp - before), who.hp_text()])


## Предводитель погиб — банда боится того, кто его добил.
func _morale_break(leader: Unit, killer: Unit) -> void:
	if killer == null:
		return
	for u in living(leader.side):
		u.add_status("fear", 2, 1, killer)
	_log("Банда в панике и боится %s!" % killer.name)


# --- Противники ----------------------------------------------------------

## Ход противника: обычная атака или особая, если перезарядилась.
func enemy_act(enemy: Unit) -> void:
	if enemy.is_leader and not enemy.special.is_empty():
		enemy.special_cooldown -= 1
		if enemy.special_cooldown <= 0 and not enemy.has("forget"):
			enemy.special_cooldown = int(enemy.special.cooldown)
			_use_special(enemy)
			end_turn(enemy)
			return
	var target := _enemy_target(enemy)
	if target:
		_log("%s атакует %s." % [enemy.name, target.name])
		_enemy_strike(enemy, target)
	end_turn(enemy)


func _use_special(enemy: Unit) -> void:
	match String(enemy.special.id):
		"all_attack_one":
			var target := _enemy_target(enemy)
			if target == null:
				return
			_log("%s: «%s» — %s → %s!" % [enemy.name, enemy.special.name, enemy.special.text, target.name])
			for u in living(enemy.side):
				if target.alive():
					_enemy_strike(u, target)
		_:
			push_warning("Неизвестная особая атака: %s" % enemy.special.id)


func _enemy_strike(attacker: Unit, target: Unit) -> void:
	var dmg := float(maxi(0, attacker.attack - (1 if attacker.has("weak") else 0)))
	if target.has("reflect") and target.side != attacker.side:
		target.statuses.erase("reflect")
		_log("%s отражает атаку!" % target.name)
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
	for u in living(opposite(enemy.side)):
		if u.has("invisible"):
			continue
		if enemy.fears(u):
			continue
		foes.append(u)
	if foes.is_empty():
		foes = living(opposite(enemy.side))
	if foes.is_empty():
		return null
	return foes[rng.randi_range(0, foes.size() - 1)]


# --- Разное --------------------------------------------------------------

func _log(text: String) -> void:
	logged.emit(text)


static func status_name(id: String) -> String:
	return {
		"burn": "Горение", "poison": "Яд", "stun": "Оглушение", "slow": "Замедление",
		"vulnerable": "Уязвимость", "weak": "Слабость", "regen": "Регенерация",
		"haste": "Ускорение", "fear": "Страх", "blind": "Ослепление", "disease": "Болезнь",
		"confusion": "Путаница", "charm": "Очарование", "forget": "Забывчивость",
		"invisible": "Невидимость", "reflect": "Отражение", "invulnerable": "Неуязвимость",
		"stoneskin": "Каменная кожа", "inspire": "Вдохновение", "bless": "Благословение",
		"chaos_curse": "Проклятие Хаоса", "petrify": "Окаменение", "toad": "Жаба",
		"focus": "Сосредоточенность", "elemental": "Водный элементаль",
	}.get(id, id)
