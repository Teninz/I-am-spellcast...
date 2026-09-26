class_name ChipBag
extends RefCounted
## Мешочек фишек одного каста.
##
## Фишка стихии после вытягивания остаётся на столе до конца каста.
## Фишка Хаоса оставляет чёрную метку и возвращается в мешочек.
## Шанс Хаоса растёт с каждым вытягиванием (за каждую фишку Хаоса в мешочке).

const CHAOS := "X"
const CHAOS_BY_DRAW: Array[float] = [0.05, 0.069, 0.088]
const CHIPS_PER_CAST := 3

var counts: Dictionary = {}  # стихия -> сколько фишек осталось в мешочке
var chaos_chips: int = 0
var chips: Array[String] = []  # вытянутые фишки по порядку ("X" — чёрная метка)
## Фишки, заранее выбранные удачей (сдвиг шкалой удачи): тянутся вместо случайных.
var forced: Array[String] = []


func _init(bag: Dictionary, extra_chaos: int = 0) -> void:
	for element in bag:
		if element == CHAOS:
			continue
		counts[element] = int(bag[element])
	chaos_chips = int(bag.get(CHAOS, 0)) + extra_chaos


func is_complete() -> bool:
	return chips.size() >= CHIPS_PER_CAST


func chaos_chance(slot: int) -> float:
	return minf(1.0, CHAOS_BY_DRAW[mini(slot, CHAOS_BY_DRAW.size() - 1)] * chaos_chips)


## Тянет следующую фишку в следующую ячейку.
func draw(rng: RandomNumberGenerator) -> String:
	assert(not is_complete())
	var slot := chips.size()
	var chip := ""
	if slot < forced.size():
		chip = forced[slot]
		if chip != CHAOS:
			counts[chip] -= 1
	else:
		chip = _draw_for_slot(slot, rng)
	chips.append(chip)
	return chip


## Сжигает фишку в ячейке и тянет вместо неё новую (способность Пироманта).
## Сожжённая фишка стихии в мешочек не возвращается.
func reroll(slot: int, rng: RandomNumberGenerator) -> String:
	assert(slot >= 0 and slot < chips.size())
	var chip := _draw_for_slot(slot, rng)
	chips[slot] = chip
	return chip


## Перемешивает порядок фишек (эффект «Путаница»).
func shuffle_order(rng: RandomNumberGenerator) -> void:
	for i in range(chips.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := chips[i]
		chips[i] = chips[j]
		chips[j] = tmp


func combo_key() -> String:
	return ChipBag.key_for(chips)


static func key_for(drawn: Array[String]) -> String:
	var marks := drawn.count(CHAOS)
	if marks > 0:
		return "X%d" % marks
	return "".join(PackedStringArray(drawn))


func _draw_for_slot(slot: int, rng: RandomNumberGenerator) -> String:
	if rng.randf() < chaos_chance(slot):
		return CHAOS
	var total := 0
	for element in counts:
		total += counts[element]
	if total <= 0:
		return CHAOS
	var roll := rng.randi_range(1, total)
	for element in counts:
		roll -= counts[element]
		if roll <= 0:
			counts[element] -= 1
			return element
	return CHAOS


## Точные шансы каждой тройки (ключ как у combo_key: "FWF", "X1"…) для мешочка книги.
static func odds(bag: Dictionary, extra_chaos: int = 0) -> Dictionary:
	var counts := {}
	for element in bag:
		if element != CHAOS:
			counts[element] = int(bag[element])
	var chaos := maxi(0, int(bag.get(CHAOS, 0)) + extra_chaos)
	var out := {}
	var drawn: Array[String] = []
	_odds_step(counts, chaos, drawn, 1.0, out)
	return out


static func _odds_step(counts: Dictionary, chaos: int, drawn: Array[String], p: float, out: Dictionary) -> void:
	if drawn.size() >= CHIPS_PER_CAST:
		var k := key_for(drawn)
		out[k] = float(out.get(k, 0.0)) + p
		return
	var slot := drawn.size()
	var c := minf(1.0, CHAOS_BY_DRAW[mini(slot, CHAOS_BY_DRAW.size() - 1)] * chaos)
	var total := 0
	for e in counts:
		total += counts[e]
	if total <= 0:
		c = 1.0
	if c > 0.0:
		drawn.append(CHAOS)
		_odds_step(counts, chaos, drawn, p * c, out)
		drawn.pop_back()
	if c < 1.0:
		for e in counts:
			var n: int = counts[e]
			if n <= 0:
				continue
			counts[e] = n - 1
			drawn.append(e)
			_odds_step(counts, chaos, drawn, p * (1.0 - c) * n / total, out)
			drawn.pop_back()
			counts[e] = n


## Фишки, дающие нужную тройку. Для Хаоса ("X2") метки ставятся в случайные ячейки,
## остальные ячейки — обычные фишки стихий из мешочка.
static func chips_for(combo: String, bag: Dictionary, rng: RandomNumberGenerator) -> Array[String]:
	var out: Array[String] = []
	if not combo.begins_with(CHAOS):
		for ch in combo:
			out.append(ch)
		return out
	var marks := int(combo.substr(1))
	var slots := [0, 1, 2]  # порядок не важен для ключа, случайность — для вида
	for i in range(slots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: int = slots[i]
		slots[i] = slots[j]
		slots[j] = tmp
	var counts := {}
	for element in bag:
		if element != CHAOS:
			counts[element] = int(bag[element])
	for i in CHIPS_PER_CAST:
		if slots.find(i) < marks:
			out.append(CHAOS)
			continue
		var total := 0
		for e in counts:
			total += counts[e]
		var roll := rng.randi_range(1, maxi(1, total))
		for e in counts:
			roll -= counts[e]
			if roll <= 0:
				counts[e] -= 1
				out.append(e)
				break
	return out
