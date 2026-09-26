class_name Sfx
extends RefCounted
## Звуки игры. Sfx.play("hit") ищет файл assets/sfx/hit.ogg (.wav, .mp3) и варианты hit_2, hit_3…
## (из них выбирается случайный); если файлов ещё нет — играет временный звук, синтезированный в коде.
## Музыка: Sfx.music("battle") — assets/music/battle.ogg по кругу; без файла — тишина.
## Список звуков и промпты для генерации — docs/sound_prompts.md.

const DIR := "res://assets/sfx/"
const MUSIC_DIR := "res://assets/music/"
const EXTS := ["ogg", "wav", "mp3"]
const RATE := 22050
const VOICES := 12
## Один и тот же звук не чаще, чем раз в столько секунд (иначе 5 ударов сливаются в треск).
const MIN_GAP := 0.045

## id -> [громкость дБ, разброс высоты] — у каждого звука своя.
const MIX := {
	"ui_click": [-12.0, 0.05], "chip_draw": [-4.0, 0.12], "chip_chaos": [-3.0, 0.0],
	"chip_burn": [-5.0, 0.05], "cast_shout": [-2.0, 0.04], "hit": [-5.0, 0.12], "hit_big": [-2.0, 0.08],
	"heal": [-7.0, 0.05], "shield": [-8.0, 0.08], "status_bad": [-10.0, 0.05], "status_good": [-10.0, 0.05],
	"down": [-3.0, 0.0], "enemy_special": [-4.0, 0.05], "summon": [-7.0, 0.1], "victory": [-3.0, 0.0],
	"defeat": [-3.0, 0.0], "book_open": [-6.0, 0.08], "map_step": [-6.0, 0.05], "loot": [-6.0, 0.06],
	"trophy": [-4.0, 0.0], "luck": [-6.0, 0.0],
}

static var _players: Array[AudioStreamPlayer] = []
static var _next := 0
static var _streams := {}
static var _last := {}
static var _music: AudioStreamPlayer
static var _music_id := ""


static func play(id: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(id, -1.0)) < MIN_GAP:
		return
	_last[id] = now
	var variants := streams_for(id)
	if variants.is_empty():
		return
	var stream: AudioStream = variants[randi() % variants.size()]
	if _players.is_empty() or not is_instance_valid(_players[0]):
		_make_players(tree)
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	if not p.is_inside_tree():
		return  # проигрыватели ещё добавляются в дерево (первый кадр)
	var mix: Array = MIX.get(id, [-6.0, 0.05])
	p.stream = stream
	p.volume_db = mix[0]
	p.pitch_scale = 1.0 + randf_range(-mix[1], mix[1])
	p.play()


static func _make_players(tree: SceneTree) -> void:
	Settings.apply()  # создаёт шину SFX и выставляет громкость
	_players.clear()
	var holder := Node.new()
	holder.name = "Sfx"
	tree.root.add_child.call_deferred(holder)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		holder.add_child(p)
		_players.append(p)


## Файлы звука (id, id_2, id_3…) или временный синтезированный звук.
static func streams_for(id: String) -> Array:
	if _streams.has(id):
		return _streams[id]
	var out := []
	var s := _load_first(DIR + id)
	if s:
		out.append(s)
	for n in range(2, 10):
		var v := _load_first("%s%s_%d" % [DIR, id, n])
		if v == null:
			break
		out.append(v)
	if out.is_empty():
		out.append(_synth(id))
	_streams[id] = out
	return out


static func stream_for(id: String) -> AudioStream:
	return streams_for(id)[0]


static func _load_first(base: String) -> AudioStream:
	for ext in EXTS:
		if ResourceLoader.exists("%s.%s" % [base, ext]):
			return load("%s.%s" % [base, ext])
	return null


## Есть ли настоящий файл (а не временный звук).
static func has_file(id: String) -> bool:
	return _load_first(DIR + id) != null


## Фоновая музыка экрана: menu, map, battle, boss, camp. Без файла — тишина.
static func music(id: String) -> void:
	if id == _music_id:
		return
	_music_id = id
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	if _music == null or not is_instance_valid(_music):
		Settings.apply()
		_music = AudioStreamPlayer.new()
		_music.bus = "Music"
		_music.volume_db = -8.0
		tree.root.add_child.call_deferred(_music)
	var s := _load_first(MUSIC_DIR + id)
	if s == null:
		_music.stop.call_deferred()
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	elif s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = true
	_music.stream = s
	_music.play.call_deferred()


# --- Временные звуки ---------------------------------------------------------

static func _synth(id: String) -> AudioStreamWAV:
	var buf := PackedFloat32Array()
	match id:
		"ui_click":
			_tone(buf, 0.0, 0.02, 2200.0, 2200.0, 0.4, "sine")
		"chip_draw":  # деревянный стук фишки
			_noise(buf, 0.0, 0.03, 0.5)
			_tone(buf, 0.0, 0.06, 900.0, 700.0, 0.6, "sine")
		"chip_chaos":  # чёрная фишка: провал вниз
			_tone(buf, 0.0, 0.35, 420.0, 90.0, 0.7, "saw")
			_noise(buf, 0.0, 0.3, 0.15)
		"chip_burn":
			_noise(buf, 0.0, 0.25, 0.35)
			_tone(buf, 0.0, 0.2, 300.0, 900.0, 0.3, "sine")
		"cast_shout":  # взмах и звон заклинания (голос — в настоящем файле)
			_tone(buf, 0.0, 0.18, 250.0, 950.0, 0.6, "saw")
			for i in 4:
				_tone(buf, 0.12 + i * 0.05, 0.25, 1400.0 + i * 350.0, 1400.0 + i * 350.0, 0.25, "sine")
		"hit":
			_noise(buf, 0.0, 0.09, 0.8)
			_tone(buf, 0.0, 0.12, 140.0, 70.0, 0.8, "sine")
		"hit_big":
			_noise(buf, 0.0, 0.18, 0.9)
			_tone(buf, 0.0, 0.25, 110.0, 45.0, 1.0, "sine")
		"heal":
			for i in 3:
				_tone(buf, i * 0.07, 0.18, [660.0, 880.0, 1100.0][i], [660.0, 880.0, 1100.0][i], 0.35, "sine")
		"shield":
			_tone(buf, 0.0, 0.3, 1250.0, 1200.0, 0.4, "sine")
			_tone(buf, 0.0, 0.3, 1870.0, 1800.0, 0.25, "sine")
		"status_bad":
			_tone(buf, 0.0, 0.1, 440.0, 440.0, 0.3, "square")
			_tone(buf, 0.1, 0.14, 330.0, 330.0, 0.3, "square")
		"status_good":
			_tone(buf, 0.0, 0.1, 523.0, 523.0, 0.3, "square")
			_tone(buf, 0.1, 0.14, 784.0, 784.0, 0.3, "square")
		"down":
			_tone(buf, 0.0, 0.5, 320.0, 55.0, 0.8, "saw")
			_noise(buf, 0.0, 0.15, 0.4)
		"enemy_special":  # рык
			_tone(buf, 0.0, 0.35, 95.0, 80.0, 0.8, "saw", 9.0)
			_noise(buf, 0.0, 0.3, 0.25)
		"summon":
			_tone(buf, 0.0, 0.12, 200.0, 650.0, 0.5, "sine")
			_noise(buf, 0.0, 0.05, 0.3)
		"victory":
			var notes := [523.0, 659.0, 784.0, 1046.0]
			for i in notes.size():
				_tone(buf, i * 0.12, 0.3 if i < 3 else 0.6, notes[i], notes[i], 0.4, "square")
		"defeat":
			var down_notes := [392.0, 330.0, 262.0]
			for i in down_notes.size():
				_tone(buf, i * 0.22, 0.35, down_notes[i], down_notes[i] * 0.98, 0.4, "saw")
		"book_open":  # шелест страниц
			_noise(buf, 0.0, 0.2, 0.35)
			_noise(buf, 0.08, 0.15, 0.25)
		"map_step":
			_tone(buf, 0.0, 0.07, 120.0, 90.0, 0.7, "sine")
			_tone(buf, 0.18, 0.07, 120.0, 90.0, 0.7, "sine")
		"loot":  # монетка
			_tone(buf, 0.0, 0.08, 1500.0, 1500.0, 0.4, "sine")
			_tone(buf, 0.06, 0.25, 2000.0, 2000.0, 0.35, "sine")
		"trophy":
			var fan := [392.0, 523.0, 659.0, 784.0]
			for i in fan.size():
				_tone(buf, i * 0.09, 0.25, fan[i], fan[i], 0.35, "square")
		"luck":
			for i in 6:
				_tone(buf, i * 0.04, 0.15, 1800.0 + (i * 377 % 900), 1800.0 + (i * 377 % 900), 0.2, "sine")
		_:
			_tone(buf, 0.0, 0.05, 1000.0, 1000.0, 0.3, "sine")
	return _to_wav(buf)


## Тон с затуханием: частота плавно идёт от f0 к f1; vibrato — частота дрожания (Гц).
static func _tone(buf: PackedFloat32Array, start: float, dur: float, f0: float, f1: float,
		amp: float, wave: String, vibrato: float = 0.0) -> void:
	var s0 := int(start * RATE)
	var n := int(dur * RATE)
	_grow(buf, s0 + n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t) * (1.0 + (0.03 * sin(TAU * vibrato * i / RATE) if vibrato > 0.0 else 0.0))
		phase += f / RATE
		var x := 0.0
		match wave:
			"sine":
				x = sin(TAU * phase)
			"square":
				x = 0.6 if fmod(phase, 1.0) < 0.5 else -0.6
			"saw":
				x = (fmod(phase, 1.0) * 2.0 - 1.0) * 0.7
		var env := minf(1.0, i / (RATE * 0.004)) * pow(1.0 - t, 2.0)
		buf[s0 + i] += x * amp * env


static func _noise(buf: PackedFloat32Array, start: float, dur: float, amp: float) -> void:
	var s0 := int(start * RATE)
	var n := int(dur * RATE)
	_grow(buf, s0 + n)
	var prev := 0.0
	for i in n:
		var t := float(i) / n
		prev = lerpf(prev, randf_range(-1.0, 1.0), 0.35)  # немного сглаженный шум
		buf[s0 + i] += prev * amp * pow(1.0 - t, 3.0)


static func _grow(buf: PackedFloat32Array, size: int) -> void:
	if buf.size() < size:
		var old := buf.size()
		buf.resize(size)
		for i in range(old, size):
			buf[i] = 0.0


static func _to_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
