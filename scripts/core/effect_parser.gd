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
const UNSUPPORTED_WORDS := ["видит", "перевытянуть", "против нежити", "игнорирует защиту"]

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
		"nothing": false, "unsupported": [],
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
		if s.contains("водным элементалем"):
			list.append({"id": "elemental", "turns": _turns_after("на", s, "elemental"), "stacks": 1})

	for word in UNSUPPORTED_WORDS:
		if text.contains(word):
			spec.unsupported.append(word)
	return spec


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
	return (spec.nothing or spec.damage > 0 or spec.heal > 0 or spec.shield > 0
		or spec.splash > 0 or spec.revive_hp > 0 or not spec.statuses.is_empty()
		or not spec.caster_statuses.is_empty() or spec.cleanse or spec.strip_buffs
		or spec.meter != 0 or not spec.remove.is_empty())
