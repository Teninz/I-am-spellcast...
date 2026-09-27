extends SceneTree
## Проверка сетевой игры: два процесса (хозяин и гость) играют одно приключение по сети,
## каждый ходит только своими волшебниками. После каждого боя оба печатают «отпечаток»
## состояния — он должен совпадать строка в строку.
##   godot --headless --path . --script res://tests/net_sync.gd -- role=host port=7790
##   godot --headless --path . --script res://tests/net_sync.gd -- role=client port=7790

const BattleUI := preload("res://scripts/ui/battle_ui.gd")
const CampUI := preload("res://scripts/ui/camp_ui.gd")
const MapUI := preload("res://scripts/ui/map_ui.gd")
const TrophyUI := preload("res://scripts/ui/trophy_ui.gd")
const PartySelectUI := preload("res://scripts/ui/party_select_ui.gd")

var role := "host"
var port := 7790
var game: Node
var frames := 0
var started := false
var picked := false
var last_screen: Node = null
var levels := 0
var cmds := 0
var in_battle := false
var plan_book := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("role="):
			role = a.substr(5)
		if a.begins_with("port="):
			port = int(a.substr(5))
	OS.low_processor_usage_mode = false
	Engine.max_fps = 0
	Profile.path = "user://test_net_profile_%s.json" % role
	Settings.path = "user://test_net_settings_%s.json" % role
	SaveGame.path = "user://test_net_save_%s.json" % role
	game = load("res://scenes/main.tscn").instantiate()
	game.fast = true
	root.add_child(game)
	NetSession.get_session().command.connect(func(c: Dictionary) -> void:
		cmds += 1
		if cmds <= 12:
			print("cmd ", c))


func _process(_delta: float) -> bool:
	frames += 1
	if frames > 400000:
		print("FAIL таймаут")
		quit(1)
		return true
	var net := NetSession.get_session()
	if not started:
		if frames == 5:
			if role == "host":
				print("host: ", net.host_game(port, "Хозяин"))
			else:
				print("client: ", net.join_game("127.0.0.1:%d" % port, "Гость"))
		if net.players.size() >= 2 and not picked:
			picked = true
			net.set_picks(["pyromancer", "priest"] if role == "host" else ["water", "magus"])
		if role == "host" and net.can_start():
			started = true
			net.start_game(["pyromancer", "priest", "water", "magus"])
		if role == "client" and net.in_game:
			started = true
		return false
	var s: Node = game.screen
	if s == null or not is_instance_valid(s):
		return false
	if in_battle and s.get_script() != BattleUI:
		levels += 1
		print("SYNC бой %d: %s" % [levels, _fingerprint()])
	in_battle = s.get_script() == BattleUI
	if s.get_script() == BattleUI:
		if frames % 5000 == 0:
			print("бой: состояние %s, ходит %s, можно мне: %s, в очереди %d" % [s.state, s.actor.name if s.actor else "-", s._can_input(), s._inbox.size()])
		_play(s)
	elif s.get_script() == CampUI:
		_camp(s)
	elif s.get_script() == MapUI and role == "host" and s != last_screen:
		s._on_node_clicked(game.adventure.choices()[0].id)
	elif s.get_script() == TrophyUI and role == "host" and s != last_screen:
		s._take.pressed.emit()
	elif s.get_script() != MapUI and s.get_script() != TrophyUI and s.get_script() != CampUI:
		print("END %s · команд: %d" % [_fingerprint(), cmds])
		quit(0)
		return true
	last_screen = s
	return false


func _fingerprint() -> String:
	var adv: Adventure = game.adventure
	var parts := []
	for w in adv.wizards:
		parts.append("%s:%s:%s:%s" % [w.class_id, Unit._num(w.hp), ",".join(w.books), w.item])
	return "ур%d %s rng=%d" % [adv.level, " | ".join(parts), adv.rng.state]


func _play(ui: Node) -> void:
	if not ui._can_input() or not ui._inbox.is_empty():
		return
	match ui.state:
		ui.State.CHOOSE_TARGET:
			plan_book = AutoPlayer.choose_book(ui.actor, ui.combat)
			ui._on_card_pressed(AutoPlayer.choose_target(ui.combat, ui.actor, plan_book))
		ui.State.CHOOSE_BOOK:
			ui._select_book(plan_book if ui.actor.books.has(plan_book) else ui.actor.books[0])
		ui.State.DRAWING:
			ui._on_draw_pressed()
		ui.State.READY:
			ui._on_cast_pressed()
		ui.State.ITEM_TARGET, ui.State.ABILITY_TARGET:
			ui._on_card_pressed(ui.actor)
		ui.State.REWIND:
			ui._on_rewind_skip()


## Привал: свои предметы добычи — «Взять», иначе выбросить/отказаться; хозяин жмёт «Дальше».
func _camp(camp: Node) -> void:
	var adv: Adventure = game.adventure
	if adv.all_resolved():
		if role == "host" and not camp._continue.disabled:
			camp._continue.pressed.emit()
		return
	if frames % 3 != 0:
		return
	for key in camp._buttons:
		if not String(key).begins_with("o"):
			continue  # только действия с добычей
		var e: Dictionary = camp._buttons[key]
		if e.owner < 0 or not adv.controls(adv.wizards[e.owner], NetSession.my_id()):
			continue
		for prefix in ["Взять", "Надеть", "Выбросить", "Отказаться", "Вместо"]:
			if String(e.text).begins_with(prefix):
				NetSession.get_session().submit({"t": "camp_btn", "key": key, "text": e.text})
				return
