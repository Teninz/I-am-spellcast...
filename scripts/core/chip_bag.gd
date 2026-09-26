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
	var chip := _draw_for_slot(chips.size(), rng)
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
