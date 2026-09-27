class_name EffectParser
extends RefCounted
## Переводит текст эффекта заклинания из data/books/*.json в структуру,
## которую понимает Combat. Тексты в книгах написаны по шаблонам
## («Оглушение на 1 ход», «Лечение 2 всем на стороне цели»), их и разбираем.
##
## Результат — словарь:
##   area: "target" | "target_side" | "arena" | "enemies" | "caster_side" | "random"
##   exclude_caster, damage, heal, shield, splash, self_damage, self_heal,
##   revive_hp, statuses: [{id, turns, stacks}], caster_statuses: [...],
##   cleanse, strip_buffs, remove: [status ids], meter, nothing, unsupported: [..]

const STATUS_WORDS := {
	"горение": "burn",
	"оглушение": "stun",
	"замедление": "slow",
	"уязвимость": "vulnerable",
	"слабость": "weak",
	"регенерация": "regen",
	"ускорение": "haste",
	"страх": "fear",
	"ослепление": "blind",
	"болезнь": "disease",
	"путаница": "confusion",
	"очарование": "charm",
	"забывчивость": "forget",
	"невидимость": "invisible",
	"отражение": "reflect",
	"неуязвимость": "invulnerable",
	"каменная кожа": "stoneskin",
	"вдохновение": "inspire",
	"благословение": "bless",
	"проклятие хаоса": "chaos_curse",
	"окаменение": "petrify",
	"сосредоточенность": "focus",
}

const DEFAULT_TURNS := {
	"stun": 1, "blind": 1, "charm": 1, "invisible": 1, "petrify": 1, "toad": 1,
	"reflect": 99, "invulnerable": 99, "focus": 1, "poison": 3, "regen": 3,
}

## Эффекты, которые прототип пока не умеет применять.
const UNSUPPORTED_WORDS: Array[String] = []

## Особые эффекты: фраза в описании → id (обрабатываются в Combat._special).
## Порядок важен: более длинные фразы раньше.
const SPECIAL_PHRASES := [
	["зелье здоровья", "give_potion"],
	["каждый волшебник отряда получает случайный предмет", "give_item_party"],
	["получает случайный предмет", "give_item"],
	["более высокой редкости", "upgrade_item"],
	["делят входящий урон пополам", "bond"],
	["потерянное за свой последний ход", "undo_turn"],
	["урон, полученный ею за последний ход", "undo_turn"],
	["баффы цели длятся на 2 хода дольше", "extend_buffs"],
	["очередь ходов всех на арене перемешивается", "shuffle_meters"],
	["очередь ближайших 6 ходов перемешивается", "shuffle_meters"],
	["повторяет последнее заклинание", "echo"],
	["копии всех баффов цели", "copy_buffs"],
	["меняется шкалой хода со случайным участником на своей стороне", "swap_meter_side"],
	["кастует следующий раз из случайной книги кастующего", "borrow_book"],
	["следующее действие цели сработает дважды", "double_next"],
	["меняются всеми баффами и дебаффами", "swap_statuses"],
	["следующая атака цели ударит её саму", "self_trap"],
	["урон по цели делится поровну", "share_pain"],
	["следующий вредный эффект на цели переходит", "fate_reflect"],
	["все эффекты на арене меняются на противоположные", "flip_all"],
	["видит свою тройку", "foresight"],
	["следующий удар по цели наносит +3", "doom"],
	["к случайной характеристике", "curse_stat"],
	["урон, равный лечению", "karma"],
	["выбирает любую комбинацию этой книги", "pick_spell"],
	["следующий удар цели уходит в случайного", "misdirect"],
	["цель и кастующий меняются шкалами хода", "swap_meter_caster"],
	["может перевытянуть одну фишку", "fortune"],
	["случайный бафф и случайный дебафф", "random_both"],
	["случайный дебафф", "random_debuff"],
	["случайный бафф", "random_buff"],
	["случайное хаос-заклинание", "random_chaos"],
	["случайное заклинание из любой книги", "random_spell"],
	["меняются текущим здоровьем", "swap_hp"],
	["шкала хода цели становится случайной", "random_meter"],
	["меняется местом в очереди ходов со случайным участником", "swap_meter_any"],
]

static var _cache: Dictionary = {}


static func parse(spell: Dictionary) -> Dictionary:
	var key := "%s|%s|%s" % [spell.get("name", ""), spell.get("combo", ""), spell.get("effect", "")]
	if _cache.has(key):
		return _cache[key]
	var spec := _parse(spell)
	_cache[key] = spec
	return spec


static func _parse(spell: Dictionary) -> Dictionary:
	var text: String = String(spell.get("effect", "")).to_lower()
	var spec := {
		"area": "target", "exclude_caster": false,
		"damage": int(spell.get("damage", 0)), "heal": 0, "shield": 0, "splash": 0,
		"self_damage": 0, "self_heal": 0, "revive_hp": 0,
		"statuses": [], "caster_statuses": [],
		"cleanse": false, "strip_buffs": false, "remove": [], "meter": 0,
		"nothing": false, "unsupported": [], "jumps": [],
		"summon": {}, "raise_fallen": "", "special": [], "pierce": false, "undead_damage": 0,
	}

	if text.contains("ничего не происходит"):
		spec.nothing = true

	# Воскрешение: «Если цель выбыла — поднимает её с 3 ЗД, иначе лечение 5.»
	var m := _match("поднимает её с (\\d+) зд, иначе лечение (\\d+)", text)
	if m:
		spec.revive_hp = int(m.get_string(1))
		spec.heal = int(m.get_string(2))
		text = text.replace(m.get_string(0), "")

	# Добивка по соседям: «2 урона цели и 1 урон всем на её стороне».
	m = _match("(\\d+) урон\\S* всем на (её|его) стороне", text)
	if m:
		spec.splash = int(m.get_string(1))
		text = text.replace(m.get_string(0), "")

	for pair in SPECIAL_PHRASES:
		if text.contains(pair[0]) and not spec.special.has(pair[1]):
			if pair[1] in ["random_debuff", "random_buff"] and spec.special.has("random_both"):
				continue
			spec.special.append(pair[1])
			text = text.replace(pair[0], "")
	if text.contains("игнорирует защиту"):
		spec.pierce = true
	m = _match("против нежити (\\d+)", text)
	if m:
		spec.undead_damage = int(m.get_string(1))
	# Чума — Болезнь и 1 урон (стак Яда) в начале хода, 3 хода.
	if text.contains("чума"):
		spec.statuses.append({"id": "poison", "turns": 3, "stacks": 1})
		if not text.contains("болезнь"):
			spec.statuses.append({"id": "disease", "turns": 3, "stacks": 1})
	# Сбой овцы: «выбирает случайную цель и наносит ей 2 урона».
	m = _match("случайную цель и наносит ей (\\d+) урон", text)
	if m:
		spec.damage = int(m.get_string(1))
		text = text.replace(m.get_string(0), "случайному участнику")
	m = _match("кастующий получает (\\d+) урон", text)
	if m:
		spec.self_damage += int(m.get_string(1))
		text = text.replace(m.get_string(0), "")

	# Призыв существ: «Призывает Скелета», «Призывает 1 случайного зверя на случайную сторону».
	m = _match("призывает (.+?)(\\.|$)", text)
	if m:
		spec.summon = _summon_spec(m.get_string(1))
		if spec.summon.is_empty():
			spec.unsupported.append("призыв: " + m.get_string(1))
		text = text.replace(m.get_string(0), "")
	m = _match("каждый погибший встаёт (\\S+) на стороне кастующего", text)
	if m:
		for id in GameData.creatures():
			if String(GameData.creatures()[id].name).to_lower().left(5) == m.get_string(1).left(5):
				spec.raise_fallen = id
				break

	# Перескоки урона (цепная молния): «1 урон двум случайным участникам на её стороне»,
	# «такой же урон случайному участнику на её стороне», «1 урон случайному союзнику кастующего»,
	# «и 4 урона случайному участнику боя» (вдобавок к удару по цели).
	m = _match("(\\d+|такой же) урон\\S* (одному |двум |трём |)случайн\\S* участник\\S* на (её|его) стороне", text)
	if m:
		spec.jumps.append({"damage": _jump_dmg(m.get_string(1), spec), "count": _count_word(m.get_string(2)), "side": "target"})
		text = text.replace(m.get_string(0), "")
	m = _match("(\\d+) урон\\S* случайному союзнику кастующего", text)
	if m:
		spec.jumps.append({"damage": int(m.get_string(1)), "count": 1, "side": "caster"})
		text = text.replace(m.get_string(0), "")
	m = _match("цели и (\\d+) урон\\S* случайному участнику боя", text)
	if m:
		spec.jumps.append({"damage": int(m.get_string(1)), "count": 1, "side": "any"})
		text = text.replace(m.get_string(0), "цели")

	# Область действия.
	if text.contains("случайному участнику"):
		spec.area = "random"
	elif text.contains("на арене"):
		spec.area = "arena"
		spec.exclude_caster = text.contains("кроме кастующего")
	elif text.contains("всем врагам"):
		spec.area = "enemies"
	elif text.contains("всему отряду кастующего"):
		spec.area = "caster_side"
	elif text.contains("всем на стороне цели"):
		spec.area = "target_side"

	# Урон, который достаётся самому кастующему.
	m = _match("(\\d+) урон\\S* (самому )?кастующему", text)
	if m:
		spec.self_damage = int(m.get_string(1))
		text = text.replace(m.get_string(0), "")
	m = _match("кастующий теряет (\\d+) зд", text)
	if m:
		spec.self_damage += int(m.get_string(1))
		text = text.replace(m.get_string(0), "")
	m = _match("кастующий лечится на (\\d+)", text)
	if m:
		spec.self_heal = int(m.get_string(1))
		text = text.replace(m.get_string(0), "")

	# Урон из текста, если в данных числа нет (например, Хаос I Книги Огня).
	if spec.damage == 0:
		m = _match("^(\\d+) урона", text)
		if m:
			spec.damage = int(m.get_string(1))

	if spec.heal == 0:
		m = _match("лечение (\\d+)", text)
		if m == null:
			m = _match("лечится на (\\d+)", text)
		if m:
			spec.heal = int(m.get_string(1))
	m = _match("щит (\\d+)", text)
	if m:
		spec.shield = int(m.get_string(1))

	if text.contains("очищение"):
		spec.cleanse = true
	if text.contains("теряет все баффы"):
		spec.strip_buffs = true
	if text.contains("снимает горение"):
		spec.remove.append("burn")
	if text.contains("снимает горение и яд"):
		spec.remove.append("poison")

	m = _match("сбив шкалы на (\\d+) %", text)
	if m:
		spec.meter -= int(m.get_string(1))
	m = _match("разгон шкалы на (\\d+) %", text)
	if m:
		spec.meter += int(m.get_string(1))
	if text.contains("дополнительный ход"):
		spec.meter += 100

	# Статусы. Предложение, которое начинается с «кастующий», относится к кастующему.
	for sentence in text.split(".", false):
		var s := sentence.strip_edges()
		var list: Array = spec.caster_statuses if s.begins_with("кастующий") else spec.statuses
		for word in STATUS_WORDS:
			if not s.contains(word) or s.contains("снимает " + word):
				continue
			var id: String = STATUS_WORDS[word]
			list.append({"id": id, "turns": _turns_after(word, s, id), "stacks": 1})
		var pm := _match("(\\d+) стак\\S* яда", s)
		if pm:
			list.append({"id": "poison", "turns": 3, "stacks": int(pm.get_string(1))})
		if s.contains("жаб"):
			list.append({"id": "toad", "turns": 1, "stacks": 1})
		# «Вызов на дуэль»: противники бьют только кастующего.
		if s.contains("бьёт только кастующего"):
			spec.caster_statuses.append({"id": "taunt", "turns": _turns_after("провокация:", s, "taunt"), "stacks": 1})
		if s.contains("водным элементалем"):
			list.append({"id": "elemental", "turns": _turns_after("на", s, "elemental"), "stacks": 1})

	for word in UNSUPPORTED_WORDS:
		if text.contains(word):
			spec.unsupported.append(word)
	return spec


## Что призывает заклинание: {"id": существо или "", "group": для случайного, "side": "caster"/"random"}.
static func _summon_spec(phrase: String) -> Dictionary:
	var side := "caster"
	if phrase.contains("на случайную сторону"):
		side = "random"
		phrase = phrase.replace("на случайную сторону", "")
	phrase = phrase.strip_edges().trim_prefix("1 ").strip_edges()
	if phrase.contains("бестиари"):
		return {"id": "", "group": "bestiary", "side": side}
	if phrase.contains("зверя"):
		return {"id": "", "group": "beast", "side": side}
	for id in GameData.creatures():
		if GameData.creatures()[id].acc == phrase:
			return {"id": id, "group": "", "side": side}
	return {}


static func _jump_dmg(word: String, spec: Dictionary) -> int:
	return int(spec.damage) if word == "такой же" else int(word)


static func _count_word(word: String) -> int:
	match word.strip_edges():
		"двум":
			return 2
		"трём":
			return 3
	return 1


## Наносит ли заклинание урон хоть кому-то (цели, соседям или перескоком).
static func deals_damage(spec: Dictionary) -> bool:
	return spec.damage > 0 or spec.splash > 0 or not spec.get("jumps", []).is_empty()


## Суммарный урон заклинания по стороне цели (для оценки ботом).
static func harm_total(spec: Dictionary) -> int:
	var total: int = spec.damage + spec.splash
	for j in spec.get("jumps", []):
		if j.side != "caster":
			total += int(j.damage) * int(j.count)
	return total


## Длительность «<эффект> на N ход(а)»; если не указана — значение по умолчанию.
static func _turns_after(word: String, sentence: String, id: String) -> int:
	var m := _match(word + " на (\\d+) ход", sentence)
	if m:
		return int(m.get_string(1))
	return DEFAULT_TURNS.get(id, 2)


static func _match(pattern: String, text: String) -> RegExMatch:
	var re := RegEx.new()
	re.compile(pattern)
	return re.search(text)


## Есть ли у заклинания хоть какое-то действие (для проверки покрытия).
static func has_effect(spec: Dictionary) -> bool:
	return (spec.nothing or spec.damage > 0 or spec.heal > 0 or spec.shield > 0 or spec.self_damage > 0
		or spec.splash > 0 or not spec.get("jumps", []).is_empty() or not spec.get("summon", {}).is_empty()
		or spec.get("raise_fallen", "") != "" or not spec.get("special", []).is_empty() or spec.revive_hp > 0 or not spec.statuses.is_empty()
		or not spec.caster_statuses.is_empty() or spec.cleanse or spec.strip_buffs
		or spec.meter != 0 or not spec.remove.is_empty())


## Обратный эффект (GDD 3.5): урон ↔ лечение, щит → Уязвимость, бафф → Слабость,
## контроль → Ускорение цели, воскрешение → цель теряет половину здоровья (как урон).
static func invert(spec: Dictionary) -> Dictionary:
	var out := spec.duplicate(true)
	out.damage = spec.heal
	out.heal = harm_total(spec)
	out.splash = 0
	out.jumps = []
	if not spec.get("summon", {}).is_empty():
		out.summon = spec.summon.duplicate()
		out.summon.side = "enemy"  # наоборот: существо встаёт против кастующего
	out.shield = 0
	out.statuses = []
	if spec.shield > 0:
		out.statuses.append({"id": "vulnerable", "turns": 2})
	for st in spec.statuses:
		if Unit.BUFFS.has(st.id):
			out.statuses.append({"id": "weak", "turns": int(st.turns)})
		elif Unit.DEBUFFS.has(st.id):
			out.statuses.append({"id": "haste", "turns": 2})
	if spec.meter != 0:
		out.meter = -spec.meter
	out.cleanse = false
	out.strip_buffs = spec.cleanse
	if spec.revive_hp > 0:
		out.revive_hp = 0
		out.damage = maxi(out.damage, 3)
	return out
