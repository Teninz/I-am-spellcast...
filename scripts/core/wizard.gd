class_name Wizard
extends RefCounted
## Волшебник между боями: здоровье, книги, предмет, шляпа, ботинки, износ книг.
## В бою из него собирается Unit (Combat), после боя состояние записывается обратно.

const MAX_BOOKS := 3
const WEAR_LIMIT := 10

var class_id: String
var name: String
var base_hp: float
var base_speed: float
var ability: String
var ability_charges: int
var forbidden_books: Array[String] = []
var destroys_forbidden := false

var hp: float
var fortify := 0.0  # Укрепление на следующий бой
## Статусы, которые переходят в следующий бой: id -> сколько ходов осталось.
var carry_statuses: Dictionary = {}
## Поднялся после боя — на этом привале не отдыхает.
var just_revived := false
var books: Array[String] = []
var item := ""
var hat := ""
var boots := ""
## Износ: книга, которой пользовались в одиночку, и сколько боёв подряд.
var wear_book := ""
var wear_streak := 0

var _equipment_db: Dictionary  # id -> данные вещи


func _init(id: String, cfg: Dictionary, equipment_db: Dictionary) -> void:
	class_id = id
	name = cfg.name
	base_hp = float(cfg.hp)
	base_speed = float(cfg.speed)
	ability = cfg.get("ability", "")
	ability_charges = int(cfg.get("ability_charges", 0))
	for b in cfg.get("forbidden_books", []):
		forbidden_books.append(String(b))
	destroys_forbidden = bool(cfg.get("destroys_forbidden", false))
	for b in cfg.books:
		books.append(String(b))
	_equipment_db = equipment_db
	hp = max_hp()


func alive() -> bool:
	return hp > 0.0


func can_use_book(book_id: String) -> bool:
	return not forbidden_books.has(book_id)


func free_book_slots() -> int:
	return MAX_BOOKS - books.size()


func equipment(slot: String) -> Dictionary:
	var id := hat if slot == "hat" else boots
	return _equipment_db.get(id, {})


## Итоговые характеристики с учётом шляпы и ботинок.
func stats() -> Dictionary:
	var s := {"hp": base_hp, "speed": base_speed, "wisdom": 0, "defense": 0, "luck": 0, "resist": 0,
		"immune": [], "start_meter": 0.0, "start_status": [], "no_wear": false, "random_target": 0.0}
	for slot in ["hat", "boots"]:
		var e := equipment(slot)
		if e.is_empty():
			continue
		for k in e.get("stats", {}):
			s[k] += e.stats[k]
		var p: Dictionary = e.get("props", {})
		s.immune.append_array(p.get("immune", []))
		s.start_meter = maxf(s.start_meter, float(p.get("start_meter", 0)))
		if p.has("start_status"):
			s.start_status.append(p.start_status)
		s.no_wear = s.no_wear or bool(p.get("no_wear", false))
		s.random_target = maxf(s.random_target, float(p.get("random_target", 0.0)))
	s.hp = maxf(1.0, s.hp)
	return s


func max_hp() -> float:
	return stats().hp


## Надевает вещь и возвращает id снятой (или "").
func equip(e: Dictionary) -> String:
	var old_max := max_hp()
	var old := ""
	if e.slot == "hat":
		old = hat
		hat = e.id
	else:
		old = boots
		boots = e.id
	_after_max_hp_change(old_max)
	return old


func unequip(slot: String) -> void:
	var old_max := max_hp()
	if slot == "hat":
		hat = ""
	else:
		boots = ""
	_after_max_hp_change(old_max)


func _after_max_hp_change(old_max: float) -> void:
	if not alive():
		return
	var new_max := max_hp()
	hp = clampf(hp + (new_max - old_max), 1.0, new_max)


## Учёт износа после боя. Возвращает id порванной книги или "".
func record_books_used(used: Array) -> String:
	if used.is_empty():
		return ""  # не кастовал (например, выбыл сразу) — счётчик не трогаем
	if stats().no_wear or used.size() != 1:
		wear_book = ""
		wear_streak = 0
		return ""
	var b: String = used[0]
	if b == wear_book:
		wear_streak += 1
	else:
		wear_book = b
		wear_streak = 1
	if wear_streak >= WEAR_LIMIT and books.has(b):
		books.erase(b)
		wear_book = ""
		wear_streak = 0
		return b
	return ""


func wear_of(book_id: String) -> int:
	return wear_streak if book_id == wear_book else 0
