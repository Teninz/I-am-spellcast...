class_name Profile
extends RefCounted
## Личный прогресс игрока между приключениями: открытые классы, счётчики, достижения.
## Хранится в user://profile.json. В совместной игре достижение получает вся группа,
## а сохраняется оно у каждого игрока в его собственном профиле.

static var path := "user://profile.json"

var unlocked: Array = []
var runs := 0
var victories := 0
var achievements: Dictionary = {}  # id -> true

## Особые умения боссов, которые игрок уже видел в деле (до этого их описание — «???»).
const BOSS_PASSIVES := ["split", "mount", "mounted", "rat_guard"]
static var _seen: Array = []
static var _seen_path := ""


static func _load_seen() -> void:
	if _seen_path == path:
		return
	_seen_path = path
	_seen = []
	if FileAccess.file_exists(path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary:
			_seen = data.get("seen_passives", []).duplicate()


## Знает ли игрок, что делает это умение босса.
static func knows_passive(id: String) -> bool:
	if not BOSS_PASSIVES.has(id):
		return true
	_load_seen()
	return _seen.has(id)


## Умение сработало на глазах у игрока — описание открывается навсегда.
static func learn_passive(id: String) -> void:
	_load_seen()
	if _seen.has(id):
		return
	_seen.append(id)
	var data: Dictionary = {}
	if FileAccess.file_exists(path):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			data = d
	data["seen_passives"] = _seen
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))


static func load_or_new(classes: Dictionary) -> Profile:
	var p := Profile.new()
	for cid in classes:
		if classes[cid].get("unlocked", false):
			p.unlocked.append(cid)
	if FileAccess.file_exists(path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary:
			for cid in data.get("unlocked", []):
				if classes.has(cid) and not p.unlocked.has(cid):
					p.unlocked.append(cid)
			p.runs = int(data.get("runs", 0))
			p.victories = int(data.get("victories", 0))
			p.achievements = data.get("achievements", {})
	return p


func save() -> void:
	_load_seen()  # до открытия на запись: иначе файл уже пуст
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"unlocked": unlocked, "runs": runs,
			"victories": victories, "achievements": achievements, "seen_passives": _seen}, "  "))


## Итог приключения. Возвращает список только что открытых классов.
func record_run(victory: bool, classes: Dictionary) -> Array:
	runs += 1
	if victory:
		victories += 1
	var fresh := []
	for cid in classes:
		if unlocked.has(cid):
			continue
		var rule: Dictionary = classes[cid].get("unlock", {})
		var ok := false
		match String(rule.get("type", "")):
			"first_run":
				ok = runs >= 1
			"first_victory":
				ok = victories >= 1
			"achievement":
				ok = achievements.has(rule.get("id", ""))
		if ok:
			unlocked.append(cid)
			fresh.append(cid)
	save()
	return fresh
