class_name Wizard
extends RefCounted
## Волшебник между боями: здоровье, книги, предмет, шляпа, ботинки, сколько боёв выдержат книги.
## В бою из него собирается Unit (Combat), после боя состояние записывается обратно.

const MAX_BOOKS := 3
## «Растрёпанные книги»: сколько боёв выдерживает любая книга (используй её или нет).
const BOOK_LIFE := 3

var class_id: String
var name: String
var base_hp: float
var base_speed: float
var ability: String
var ability_charges: int
var forbidden_books: Array[String] = []
var max_books := MAX_BOOKS
var destroys_forbidden := false
var extra_chaos := 0

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
## Сколько боёв ещё выдержит каждая книга: id -> число. Нет записи — книга новая (BOOK_LIFE).
var book_life: Dictionary = {}
## Трофеи боссов ("rat_king:trophy", "rat_king:cursed") и шрамы (id босса).
var trophies: Array[String] = []
var scars: Array[String] = []
## Шрам «Обобранный»: в этом бою предметом пользоваться нельзя.
var no_item_battle := false
## Некромант поднял его зомби: ЗД ×1.2, только 2 книги. Лечится свитком или зельем воскрешения.
var zombie := false
## Учёный: овца сломана (её 2 слота свободны).
var sheep_broken := false
## Алхимик носит 2 предмета: второй лежит здесь.
var item2 := ""
var max_items := 1
## Оракул: +1 Мудрость за каждые 5 пройденных уровней.
var bonus_wisdom := 0
var class_max_books := MAX_BOOKS

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
	max_books = int(cfg.get("max_books", MAX_BOOKS))
	class_max_books = max_books
	max_items = int(cfg.get("max_items", 1))
	extra_chaos = int(cfg.get("extra_chaos", 0))
	for b in cfg.books:
		books.append(String(b))
	_equipment_db = equipment_db
	hp = max_hp()


func alive() -> bool:
	return hp > 0.0


func can_use_book(book_id: String) -> bool:
	return not forbidden_books.has(book_id)


func free_book_slots() -> int:
	return max_books - books.size()


func equipment(slot: String) -> Dictionary:
	var id := hat if slot == "hat" else boots
	return _equipment_db.get(id, {})


## Итоговые характеристики с учётом шляпы и ботинок.
func stats() -> Dictionary:
	var s := {"hp": base_hp, "speed": base_speed, "wisdom": 0, "defense": 0, "luck": 0, "resist": 0,
		"immune": [], "start_meter": 0.0, "start_status": [], "no_wear": false, "random_target": 0.0}
	for m in marks():
		for k in m.get("stats", {}):
			s[k] += m.stats[k]
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
	s.wisdom += bonus_wisdom
	if zombie:
		s.hp *= 1.2
	s.hp = maxf(1.0, s.hp)
	return s


## Трофеи и шрамы волшебника (данные из data/bosses.json).
func marks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var db := GameData.bosses()
	for t in trophies:
		var parts := t.split(":")
		if db.has(parts[0]):
			out.append(db[parts[0]][parts[1]])
	for b in scars:
		if db.has(b):
			out.append(db[b].scar)
	return out


func has_effect(effect: String) -> bool:
	return marks().any(func(m: Dictionary) -> bool: return m.get("effect", "") == effect)


## Проклятое у волшебника: проклятая книга, вещь или проклятый трофей.
func cursed_things(book_db: Dictionary) -> int:
	var n := 0
	for b in books:
		if book_db.get(b, {}).get("rarity", "") == "cursed":
			n += 1
	for slot in ["hat", "boots"]:
		if equipment(slot).get("rarity", "") == "cursed":
			n += 1
	for t in trophies:
		if t.ends_with(":cursed"):
			n += 1
	return n


## Есть ли место под ещё один предмет.
func has_item_slot() -> bool:
	return item == "" or (max_items >= 2 and item2 == "")


## Кладёт предмет в свободный слот. Возвращает false, если места нет.
func add_item(id: String) -> bool:
	if item == "":
		item = id
	elif max_items >= 2 and item2 == "":
		item2 = id
	else:
		return false
	return true


## Первый предмет потрачен — второй (у Алхимика) переходит в руки.
func shift_items() -> void:
	if item == "" and item2 != "":
		item = item2
		item2 = ""


## Становится зомби: навсегда теряет одну книгу (если их больше одной), носит только 2.
func become_zombie(rng: RandomNumberGenerator) -> String:
	zombie = true
	var lost := ""
	if books.size() > 1:
		lost = books[rng.randi_range(0, books.size() - 1)]
		books.erase(lost)
	max_books = mini(max_books, 2)
	while books.size() > max_books:
		books.pop_back()
	return lost


## Свиток или зелье воскрешения возвращают зомби к жизни (потерянная книга не возвращается).
func cure_zombie() -> void:
	var old_max := max_hp()
	zombie = false
	max_books = class_max_books if not sheep_broken else class_max_books + 1
	_after_max_hp_change(old_max)


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


## «Растрёпанные книги»: после каждого боя все книги стареют на один бой.
## Возвращает id порвавшихся книг. Последняя книга волшебника держится «на честном слове» (1 бой),
## механическая овца — не бумага и не рвётся, как и книги владельца «нервущейся» шляпы.
func age_books() -> Array[String]:
	var torn: Array[String] = []
	if stats().no_wear:
		return torn
	for b in books.duplicate():
		if b == "sheep":
			continue
		var left := life_of(b) - 1
		if left <= 0 and books.size() > 1:
			books.erase(b)
			book_life.erase(b)
			torn.append(b)
		else:
			book_life[b] = maxi(1, left)
	return torn


## Сколько боёв ещё выдержит книга.
func life_of(book_id: String) -> int:
	return int(book_life.get(book_id, BOOK_LIFE))


## Новая книга в руках — свежая.
func fresh_book(book_id: String) -> void:
	book_life[book_id] = BOOK_LIFE


## Клей для переплёта: все книги снова как новые.
func glue_books() -> void:
	book_life.clear()
