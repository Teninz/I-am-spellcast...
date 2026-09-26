class_name GameData
extends RefCounted
## Загрузка данных игры из res://data (те же JSON, что и для документации).

const BOOKS_DIR := "res://data/books"


static func load_books() -> Dictionary:
	var out := {}
	for file in DirAccess.get_files_at(BOOKS_DIR):
		if file.get_extension() != "json":
			continue
		var book: Dictionary = load_json("%s/%s" % [BOOKS_DIR, file])
		out[book.id] = book
	return out


static func load_json(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Не удалось прочитать %s" % path)
		return {}
	var data: Variant = JSON.parse_string(text)
	if data == null:
		push_error("Ошибка JSON в %s" % path)
		return {}
	return data


static var _statuses: Dictionary = {}


## Справочник эффектов (названия, описания, вид) — data/statuses.json.
static func statuses() -> Dictionary:
	if _statuses.is_empty():
		_statuses = load_json("res://data/statuses.json")
	return _statuses


static func load_classes() -> Dictionary:
	return load_json("res://data/classes/starting.json")


static func load_encounter(id: String) -> Dictionary:
	return load_json("res://data/encounters/%s.json" % id)
