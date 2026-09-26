class_name Luck
extends RefCounted
## Шкала удачи: при баффе удачи волшебник вкладывает до 10 % в заклинания или их типы.
##
## План — {ключ: проценты}, ключ "spell:<тройка>" или "cat:<тип>". Сумма не больше BUDGET.
## Перед вытягиванием с шансом A (всё вложенное) удача «подправляет» тройку: выпадает
## выбранное заклинание (для типа — случайное заклинание этого типа по обычным шансам),
## иначе — обычное вытягивание. Итог: p' = (1 − A)·p + (вклад в это заклинание),
## то есть выбранные шансы растут, остальные пропорционально уменьшаются.

const BUDGET := 10  # процентов
const STEP := 1
const CATEGORY_NAMES := {
	"damage": "Урон", "control": "Контроль", "support": "Польза", "summon": "Призыв",
	"disease": "Болезнь", "roots": "Щиты и корни", "glitch": "Сбой", "fate": "Судьба",
	"curse": "Проклятие", "wild": "Дикая магия", "item": "Предмет",
}


## Бафф удачи — Благословение.
static func has_luck(u: Unit) -> bool:
	return u != null and u.has("bless")


static func spent(plan: Dictionary) -> int:
	var n := 0
	for k in plan:
		n += int(plan[k])
	return n


static func spell_key(combo: String) -> String:
	return "spell:" + combo


static func cat_key(category: String) -> String:
	return "cat:" + category


## Шансы по типам заклинаний.
static func by_category(book: Dictionary, odds: Dictionary) -> Dictionary:
	var out := {}
	for sp in book.spells:
		out[sp.category] = float(out.get(sp.category, 0.0)) + float(odds.get(sp.combo, 0.0))
	return out


## Можно ли вложить удачу: в заклинание, которое вообще может выпасть, и в тип, у которого шанс > 0.
static func can_invest(book: Dictionary, odds: Dictionary, key: String) -> bool:
	if key.begins_with("spell:"):
		return float(odds.get(key.substr(6), 0.0)) > 0.0
	return float(by_category(book, odds).get(key.substr(4), 0.0)) > 0.0


## Шансы с учётом плана.
static func shifted(book: Dictionary, odds: Dictionary, plan: Dictionary) -> Dictionary:
	var a := spent(plan) / 100.0
	var cats := by_category(book, odds)
	var out := {}
	for sp in book.spells:
		var p := float(odds.get(sp.combo, 0.0))
		var bonus := int(plan.get(spell_key(sp.combo), 0)) / 100.0
		var cat_share := float(cats.get(sp.category, 0.0))
		if cat_share > 0.0:
			bonus += int(plan.get(cat_key(sp.category), 0)) / 100.0 * p / cat_share
		out[sp.combo] = (1.0 - a) * p + bonus
	return out


## Бросок удачи перед кастом: тройка, которую «подправила» удача, или "" — обычное вытягивание.
static func roll(book: Dictionary, odds: Dictionary, plan: Dictionary, rng: RandomNumberGenerator) -> String:
	var a := spent(plan)
	if a <= 0 or rng.randf() * 100.0 >= a:
		return ""
	var pick := rng.randf() * a
	for key in plan:
		pick -= int(plan[key])
		if pick >= 0.0:
			continue
		if key.begins_with("spell:"):
			return key.substr(6)
		# Тип: заклинание этого типа по обычным шансам.
		var cat: String = key.substr(4)
		var total := 0.0
		for sp in book.spells:
			if sp.category == cat:
				total += float(odds.get(sp.combo, 0.0))
		var r := rng.randf() * total
		for sp in book.spells:
			if sp.category == cat:
				r -= float(odds.get(sp.combo, 0.0))
				if r <= 0.0 and float(odds.get(sp.combo, 0.0)) > 0.0:
					return sp.combo
	return ""


## Оставляет в плане только допустимое и не больше BUDGET.
static func clean(book: Dictionary, odds: Dictionary, plan: Dictionary) -> Dictionary:
	var out := {}
	var left := BUDGET
	for key in plan:
		var v := mini(int(plan[key]), left)
		if v > 0 and can_invest(book, odds, key):
			out[key] = v
			left -= v
	return out
