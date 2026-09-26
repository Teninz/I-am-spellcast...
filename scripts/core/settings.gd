class_name Settings
extends RefCounted
## Настройки игрока (user://settings.json): скорость боя, громкость, автотяга фишек, обучение.

const SPEEDS := [0.5, 1.0, 1.5, 2.0]
const SPEED_NAMES := ["Медленно", "Обычно", "Быстрее", "Быстро"]
const DEFAULTS := {
	"speed": 1.0,        # множитель скорости анимаций и пауз в бою
	"master": 0.8,       # общая громкость 0..1
	"sfx": 1.0,          # звуки 0..1
	"music": 0.6,        # музыка 0..1 (музыка появится позже)
	"tutorial": true,    # подсказки обучения в бою
}

static var path := "user://settings.json"
static var _data: Dictionary = {}


static func value(key: String) -> Variant:
	_ensure()
	return _data.get(key, DEFAULTS.get(key))


static func set_value(key: String, v: Variant) -> void:
	_ensure()
	_data[key] = v
	save()
	apply()


static func speed() -> float:
	return maxf(0.25, float(value("speed")))


## Пауза в бою с учётом скорости.
static func delay(seconds: float) -> float:
	return seconds / speed()


static func save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_data, "  "))


static func load_from_disk() -> void:
	_data = DEFAULTS.duplicate()
	if FileAccess.file_exists(path):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			for k in DEFAULTS:
				if d.has(k):
					_data[k] = d[k]
	apply()


static func _ensure() -> void:
	if _data.is_empty():
		load_from_disk()


## Громкость шин: Master, SFX и Music (шины создаются при первом вызове).
static func apply() -> void:
	for bus_name in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")
	_set_bus("Master", float(_data.get("master", 0.8)))
	_set_bus("SFX", float(_data.get("sfx", 1.0)))
	_set_bus("Music", float(_data.get("music", 0.6)))


static func _set_bus(bus_name: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i == -1:
		return
	AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
