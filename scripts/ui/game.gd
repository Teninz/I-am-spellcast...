extends Control
## Корневой экран: бой → привал → бой … → итог акта.

const PARTY := ["pyromancer", "priest", "water"]
const BattleUI := preload("res://scripts/ui/battle_ui.gd")
const CampUI := preload("res://scripts/ui/camp_ui.gd")

## Для тестов: ускоряет задержки в бою.
var fast := false
var adventure: Adventure
var screen: Control
var _auto_draw := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	new_adventure()


func new_adventure() -> void:
	adventure = Adventure.new(PARTY)
	_show_battle()


func _show_battle() -> void:
	var b: Control = BattleUI.new()
	b.fast = fast
	b.auto_draw = _auto_draw
	b.setup(adventure)
	b.finished.connect(_on_battle_finished)
	_swap(b)


func _on_battle_finished(outcome: String) -> void:
	_auto_draw = screen.auto_draw
	var combat: Combat = screen.combat
	var was_last := adventure.is_last_level()
	var torn := adventure.finish_combat(combat)
	if outcome != "victory":
		_show_end(false)
		return
	if was_last:
		_show_end(true)
		return
	var rest := adventure.rest()
	adventure.roll_loot()
	var camp: Control = CampUI.new()
	camp.setup(adventure, rest, torn)
	camp.continue_pressed.connect(_show_battle)
	_swap(camp)


func _show_end(victory: bool) -> void:
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1b1a24")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(bg)
	holder.add_child(c)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	c.add_child(box)
	var title := Label.new()
	title.text = "Акт I пройден! Крысиный Король повержен." if victory \
		else "Поражение на уровне %d. Старики отправились на пенсию окончательно." % adventure.level
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var again := Button.new()
	again.text = "Новое приключение"
	again.custom_minimum_size = Vector2(260, 52)
	again.add_theme_font_size_override("font_size", 18)
	again.pressed.connect(new_adventure)
	box.add_child(again)
	holder.set_meta("victory", victory)
	_swap(holder)


func _swap(next: Control) -> void:
	if screen:
		screen.queue_free()
	screen = next
	add_child(next)
	next.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
