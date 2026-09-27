class_name LootTile
extends Button
## Слот инвентаря на привале. При наведении — карточка с описанием вещи
## (название цветом редкости, вид, свойства), чтобы не читать описание внизу колонки.

var tip_title := ""
var tip_color := Color.WHITE
var tip_lines: Array = []


func _make_custom_tooltip(_for_text: String) -> Object:
	if tip_title == "":
		return null
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("24232f")
	box.border_color = tip_color
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	var t := Label.new()
	t.text = tip_title
	t.add_theme_font_size_override("font_size", 19)
	t.add_theme_color_override("font_color", tip_color)
	col.add_child(t)
	for line in tip_lines:
		var l := Label.new()
		l.text = String(line)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size = Vector2(320, 0)
		l.add_theme_font_size_override("font_size", 14)
		col.add_child(l)
	return panel
