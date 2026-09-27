class_name NetSession
extends Node
## Сетевая игра через интернет (ENet). Хозяин создаёт игру, остальные подключаются по адресу.
##
## Схема «все повторяют одни и те же действия»: у всех игроков одно и то же «зерно» приключения,
## каждое действие (цель, книга, фишка, каст, добыча, путь) уходит хозяину, он нумерует его и
## рассылает всем, и каждый применяет действия в одном и том же порядке. Так бой у всех одинаковый,
## а пересылать нужно только действия. Кто каким волшебником управляет — adventure.owners.
##
## Без сети (active == false) действия применяются сразу — одиночная игра работает как раньше.

signal roster_changed
signal command(cmd: Dictionary)
signal chat_received(from_name: String, text: String, whisper_to: String)
signal status(text: String)
signal started(setup: Dictionary)
signal ended(reason: String)

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

static var _inst: NetSession

var is_host := false
var my_name := "Игрок"
## peer_id -> {"name", "picks": Array[String]}
var players: Dictionary = {}
var host_unlocked: Array = []
var in_game := false
var _seq := 0
var _upnp: UPNP
var _upnp_port := 0


## Единственная сессия (создаётся по первому обращению и живёт в корне дерева).
static func get_session() -> NetSession:
	if _inst == null or not is_instance_valid(_inst):
		_inst = NetSession.new()
		_inst.name = "NetSession"
		_inst.process_mode = Node.PROCESS_MODE_ALWAYS
		var tree := Engine.get_main_loop() as SceneTree
		tree.root.add_child.call_deferred(_inst)
	return _inst


## Идёт ли сетевая игра (есть подключение).
static func online() -> bool:
	return _inst != null and is_instance_valid(_inst) and _inst.multiplayer.has_multiplayer_peer() \
		and not (_inst.multiplayer.multiplayer_peer is OfflineMultiplayerPeer)


static func my_id() -> int:
	return _inst.multiplayer.get_unique_id() if online() else 1


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(func() -> void:
		_close()
		ended.emit("Не удалось подключиться. Проверь адрес и что хозяин создал игру."))
	multiplayer.server_disconnected.connect(func() -> void:
		_close()
		ended.emit("Связь с хозяином игры потеряна."))


# --- Подключение ----------------------------------------------------------------

## Создать игру. Возвращает "" или текст ошибки.
func host_game(port: int, player_name: String) -> String:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		return "Не удалось открыть порт %d (он занят?)." % port
	multiplayer.multiplayer_peer = peer
	is_host = true
	in_game = false
	my_name = player_name
	players = {1: {"name": player_name, "picks": []}}
	_seq = 0
	roster_changed.emit()
	status.emit("Игра создана на порту %d. Пробую открыть порт на роутере…" % port)
	_open_router_port(port)
	return ""


## Подключиться к игре: адрес «ip:порт» или просто «ip».
func join_game(address: String, player_name: String) -> String:
	var host := address.strip_edges()
	var port := DEFAULT_PORT
	if host.contains(":"):
		port = int(host.get_slice(":", 1))
		host = host.get_slice(":", 0)
	if host == "":
		return "Введи адрес хозяина игры."
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	if err != OK:
		return "Не удалось начать подключение к %s:%d." % [host, port]
	multiplayer.multiplayer_peer = peer
	is_host = false
	in_game = false
	my_name = player_name
	players = {}
	status.emit("Подключаюсь к %s:%d…" % [host, port])
	return ""


func leave() -> void:
	_close()
	roster_changed.emit()


func _close() -> void:
	if _upnp and _upnp_port > 0:
		_upnp.delete_port_mapping(_upnp_port, "UDP")
	_upnp = null
	_upnp_port = 0
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players = {}
	is_host = false
	in_game = false


## UPnP: просим роутер хозяина открыть порт и узнаём внешний адрес (в отдельном потоке — это пара секунд).
func _open_router_port(port: int) -> void:
	var thread := Thread.new()
	thread.start(func() -> void:
		var u := UPNP.new()
		var text := ""
		if u.discover(2000, 2, "InternetGatewayDevice") == UPNP.UPNP_RESULT_SUCCESS \
				and u.get_gateway() and u.get_gateway().is_valid_gateway() \
				and u.add_port_mapping(port, port, "IAmSpellcast", "UDP") == UPNP.UPNP_RESULT_SUCCESS:
			text = "Порт открыт. Адрес для друзей: %s:%d" % [u.query_external_address(), port]
			_set_upnp.call_deferred(u, port)
		else:
			text = "Роутер не открыл порт сам. Друзьям нужен твой внешний адрес и проброс порта %d (UDP) на роутере — или общая виртуальная сеть (Radmin VPN, ZeroTier): тогда адрес — из неё." % port
		status.emit.call_deferred(text)
		thread.wait_to_finish.call_deferred())


func _set_upnp(u: UPNP, port: int) -> void:
	_upnp = u
	_upnp_port = port


func _on_connected() -> void:
	status.emit("Подключено. Ждём, пока хозяин начнёт игру.")
	_hello.rpc_id(1, my_name)


func _on_peer_connected(_id: int) -> void:
	pass  # игрок представится сам (_hello)


func _on_peer_disconnected(id: int) -> void:
	if not is_host or not players.has(id):
		return
	var who: String = players[id].name
	players.erase(id)
	_roster.rpc(players)
	_system_chat("%s отключился.%s" % [who, " Его волшебниками управляет хозяин." if in_game else ""])
	if in_game:
		submit({"t": "reassign", "peer": id})


@rpc("any_peer", "call_remote", "reliable")
func _hello(player_name: String) -> void:
	if not is_host:
		return
	var id := multiplayer.get_remote_sender_id()
	if in_game or players.size() >= MAX_PLAYERS:
		_refuse.rpc_id(id, "Игра уже идёт или мест нет.")
		return
	var taken := players.values().map(func(p: Dictionary) -> String: return p.name)
	var n := player_name if not taken.has(player_name) else "%s (%d)" % [player_name, id % 100]
	players[id] = {"name": n, "picks": []}
	_roster.rpc(players)
	_system_chat("%s присоединился." % n)


@rpc("authority", "call_remote", "reliable")
func _refuse(reason: String) -> void:
	_close()
	ended.emit(reason)


@rpc("authority", "call_local", "reliable")
func _roster(list: Dictionary) -> void:
	players = list
	roster_changed.emit()


# --- Лобби: выбор волшебников ---------------------------------------------------

## Сколько волшебников у каждого игрока: 2 игрока — по 2, 3 или 4 игрока — по 1.
func picks_per_player() -> int:
	return 2 if players.size() == 2 else (1 if players.size() >= 3 else 3)


func set_picks(picks: Array) -> void:
	if is_host:
		_store_picks(1, picks)
	else:
		_picks.rpc_id(1, picks)


@rpc("any_peer", "call_remote", "reliable")
func _picks(picks: Array) -> void:
	if is_host:
		_store_picks(multiplayer.get_remote_sender_id(), picks)


func _store_picks(id: int, picks: Array) -> void:
	if not players.has(id):
		return
	# Классы в отряде не повторяются: занятое другим игроком не берём.
	var taken := {}
	for pid in players:
		if pid != id:
			for c in players[pid].picks:
				taken[c] = true
	players[id].picks = picks.filter(func(c: String) -> bool: return not taken.has(c)).slice(0, picks_per_player())
	_roster.rpc(players)


func can_start() -> bool:
	if not is_host or players.size() < 2:
		return false
	return players.values().all(func(p: Dictionary) -> bool: return p.picks.size() == picks_per_player())


## Хозяин начинает: общее «зерно», отряд по порядку игроков, кто каким волшебником управляет.
func start_game(unlocked: Array) -> void:
	if not can_start():
		return
	var party := []
	var owners := []
	var ids := players.keys()
	ids.sort()
	for id in ids:
		for c in players[id].picks:
			party.append(c)
			owners.append(id)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var setup := {"seed": rng.randi_range(1, 2147483647), "party": party, "owners": owners,
		"names": players.duplicate(true), "unlocked": unlocked}
	_start.rpc(setup)


@rpc("authority", "call_local", "reliable")
func _start(setup: Dictionary) -> void:
	in_game = true
	_seq = 0
	host_unlocked = setup.unlocked
	started.emit(setup)


## Приключение закончилось — все снова в лобби (соединение остаётся).
func back_to_lobby() -> void:
	in_game = false
	if is_host:
		for id in players:
			players[id].picks = []
		_roster.rpc(players)


func player_name(id: int) -> String:
	return String(players.get(id, {}).get("name", "игрок %d" % id))


# --- Действия в игре ------------------------------------------------------------

## Отправить действие. Без сети — применяется сразу; в сети — через хозяина, у всех в одном порядке.
func submit(cmd: Dictionary) -> void:
	cmd["from"] = NetSession.my_id()
	if not NetSession.online():
		command.emit(cmd)
	elif is_host:
		_relay(cmd)
	else:
		_submit.rpc_id(1, cmd)


@rpc("any_peer", "call_remote", "reliable")
func _submit(cmd: Dictionary) -> void:
	if not is_host:
		return
	cmd["from"] = multiplayer.get_remote_sender_id()  # подделать отправителя нельзя
	_relay(cmd)


func _relay(cmd: Dictionary) -> void:
	_seq += 1
	cmd["seq"] = _seq
	_apply.rpc(cmd)


@rpc("authority", "call_local", "reliable")
func _apply(cmd: Dictionary) -> void:
	command.emit(cmd)


# --- Чат и шёпот ------------------------------------------------------------------

## to == 0 — всем; иначе шёпот одному игроку.
func send_chat(text: String, to: int = 0) -> void:
	text = text.strip_edges().left(300)
	if text == "":
		return
	if is_host:
		_route_chat(1, text, to)
	else:
		_chat_up.rpc_id(1, text, to)


@rpc("any_peer", "call_remote", "reliable")
func _chat_up(text: String, to: int) -> void:
	if is_host:
		_route_chat(multiplayer.get_remote_sender_id(), text, to)


func _route_chat(from: int, text: String, to: int) -> void:
	var name_from := player_name(from)
	if to == 0 or not players.has(to):
		_chat_down.rpc(name_from, text, "")
		return
	var name_to := player_name(to)
	for id in [from, to]:
		if id == 1:
			_chat_down(name_from, text, name_to)
		else:
			_chat_down.rpc_id(id, name_from, text, name_to)


@rpc("authority", "call_local", "reliable")
func _chat_down(from_name: String, text: String, whisper_to: String) -> void:
	chat_received.emit(from_name, text, whisper_to)


func _system_chat(text: String) -> void:
	_chat_down.rpc("", text, "")
