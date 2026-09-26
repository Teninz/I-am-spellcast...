class_name Unit
extends RefCounted
## Участник боя: волшебник, противник или призванное существо.

const PARTY := "party"
const ENEMIES := "enemies"

## Вредные статусы — их снимает Очищение, от них спасает Сопротивление.
const DEBUFFS := ["burn", "poison", "stun", "slow", "vulnerable", "weak", "fear", "blind",
	"disease", "confusion", "charm", "forget", "chaos_curse", "petrify", "toad", "aching"]
## «Разбитость» после воскрешения: скорость −25 %.
const ACHING_SPEED := 0.75
const BUFFS := ["regen", "haste", "invisible", "reflect", "invulnerable", "stoneskin",
	"inspire", "bless", "focus", "elemental", "taunt", "muse"]

var id: int
var name: String
var side: String
var class_id: String = ""
var wizard: Wizard = null  # для волшебников — их постоянное состояние
var max_hp: float
var hp: float
var speed: float
var meter: float = 0.0
var shield: float = 0.0
## Укрепление: временное здоровье после отдыха, тает по 0.5 за ход.
var fortify: float = 0.0
var fortify_turns: int = 0
var fortify_decay: float = 0.5

# Характеристики (от обмундирования и трофеев)
var wisdom: int = 0
var defense_bonus: int = 0
var luck_bonus: int = 0
var resist: int = 0
var immune: Array = []
var random_target: float = 0.0

var books: Array[String] = []
var books_used: Dictionary = {}  # книги, из которых кастовал в этом бою
var ability: String = ""
var ability_charges: int = 0
var ability_pool: float = 0.0  # запас лечения Паладина на бой
var no_chaos := false
var extra_casts: int = 0

# Противники
var attack: int = 0
var attacks: int = 1
var behaviour: String = ""
var heal_power: int = 0
var is_leader: bool = false
var is_boss: bool = false
var passive: String = ""
var specials: Array = []  # [{..., "cd": ходов до готовности}]

var statuses: Dictionary = {}  # id -> {turns, stacks, source} (source — id участника или -1)


## Здоровье считается с точностью до 0.1.
static func q(v: float) -> float:
	return roundf(v * 10.0) / 10.0


func alive() -> bool:
	return hp > 0.0


func is_wizard() -> bool:
	return side == PARTY


func has(status: String) -> bool:
	return statuses.has(status)


## Боится ли этот участник другого (Страх запрещает выбирать его целью).
func fears(other: Unit) -> bool:
	return statuses.has("fear") and statuses.fear.source == other.id


## Не поддаётся жёсткому контролю (боссы и предводители).
func resists_control() -> bool:
	return is_leader or is_boss


func effective_speed() -> float:
	var s := speed
	if has("slow"):
		s *= 0.7
	if has("aching"):
		s *= ACHING_SPEED
	if has("haste"):
		s *= 1.3
	return s


func defense() -> int:
	var d := defense_bonus
	if has("stoneskin"):
		d += 2
	if has("petrify"):
		d += 3
	return d


## Поправка к числам заклинаний: Мудрость, Вдохновение +1, Слабость −1.
func power_bonus() -> int:
	return wisdom + (1 if has("inspire") else 0) - (1 if has("weak") else 0)


func luck() -> int:
	return luck_bonus + (2 if has("bless") else 0)


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


## Конец собственного хода: статусы и Укрепление убывают.
func tick_down() -> void:
	for s in statuses.keys():
		var st: Dictionary = statuses[s]
		if st.turns >= 99:
			continue
		st.turns -= 1
		if st.turns <= 0:
			statuses.erase(s)
	if fortify_turns > 0:
		fortify_turns -= 1
		fortify = Unit.q(maxf(0.0, fortify - fortify_decay))
		if fortify_turns == 0:
			fortify = 0.0


func hp_text() -> String:
	return "%s/%s" % [_num(hp), _num(max_hp)]


static func _num(v: float) -> String:
	v = Unit.q(v)
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return "%.1f" % v
