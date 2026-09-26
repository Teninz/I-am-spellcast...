class_name Unit
extends RefCounted
## Участник боя: волшебник, противник или призванное существо.

const PARTY := "party"
const ENEMIES := "enemies"

## Вредные статусы — их снимает Очищение, на них проверяется Отражение.
const DEBUFFS := ["burn", "poison", "stun", "slow", "vulnerable", "weak", "fear", "blind",
	"disease", "confusion", "charm", "forget", "chaos_curse", "petrify", "toad"]
const BUFFS := ["regen", "haste", "invisible", "reflect", "invulnerable", "stoneskin",
	"inspire", "bless", "focus", "elemental"]

var id: int
var name: String
var side: String
var class_id: String = ""
var max_hp: float
var hp: float
var speed: float
var meter: float = 0.0
var shield: float = 0.0
var attack: int = 0  # урон обычной атаки противника
var books: Array[String] = []
var ability: String = ""
var ability_charges: int = 0
var is_leader: bool = false
var special: Dictionary = {}
var special_cooldown: int = 0
var statuses: Dictionary = {}  # id -> {turns, stacks, source} (source — id участника или -1)


func alive() -> bool:
	return hp > 0.0


func is_wizard() -> bool:
	return side == PARTY


func has(status: String) -> bool:
	return statuses.has(status)


## Боится ли этот участник другого (Страх запрещает выбирать его целью).
func fears(other: Unit) -> bool:
	return statuses.has("fear") and statuses.fear.source == other.id


func effective_speed() -> float:
	var s := speed
	if has("slow"):
		s *= 0.7
	if has("haste"):
		s *= 1.3
	return s


func defense() -> int:
	var d := 0
	if has("stoneskin"):
		d += 2
	if has("petrify"):
		d += 3
	return d


## Поправка к числам заклинаний: Вдохновение +1, Слабость −1.
func power_bonus() -> int:
	return (1 if has("inspire") else 0) - (1 if has("weak") else 0)


func luck() -> int:
	return 2 if has("bless") else 0


func extra_chaos_chips() -> int:
	return 2 if has("chaos_curse") else 0


func add_status(status_id: String, turns: int, stacks: int = 1, source: Unit = null) -> void:
	var source_id := source.id if source else -1
	if statuses.has(status_id):
		var s: Dictionary = statuses[status_id]
		s.turns = maxi(s.turns, turns)
		if status_id == "poison":
			s.stacks = mini(3, s.stacks + stacks)
		if source:
			s.source = source_id
	else:
		statuses[status_id] = {"turns": turns, "stacks": stacks, "source": source_id}


func remove_debuffs() -> void:
	for s in DEBUFFS:
		statuses.erase(s)


func remove_buffs() -> void:
	for s in BUFFS:
		statuses.erase(s)
	shield = 0.0


## Уменьшает длительность статусов в конце собственного хода.
func tick_down() -> void:
	for s in statuses.keys():
		var st: Dictionary = statuses[s]
		if st.turns >= 99:
			continue
		st.turns -= 1
		if st.turns <= 0:
			statuses.erase(s)


func hp_text() -> String:
	return "%s/%s" % [_num(hp), _num(max_hp)]


static func _num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return "%.1f" % v
