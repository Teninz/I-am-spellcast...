class_name LootTile
extends Button
## Слот инвентаря на привале. При наведении — карточка с описанием вещи
## (название цветом редкости, вид, свойства), чтобы не читать описание внизу колонки.

var tip_title := ""
var tip_color := Color.WHITE
var tip_lines: Array = []
## Растрёпанная книга: 2 — жёлтая рамка с трещинками (осталось 2 боя), 1 — красная, почти развалилась.
## Рисуется отдельным слоем поверх обложки.
func set_wear(level: int) -> void:
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.draw.connect(func() -> void: _draw_cracks(layer, level))
	add_child(layer)


static func _draw_cracks(c: Control, level: int) -> void:
	var sz := c.size
	var col := Color("ff4a3a") if level == 1 else Color("ffc93a")
	c.draw_rect(Rect2(Vector2.ZERO, sz).grow(-1.5), col, false, 3.0)
	var n := 3 if level == 2 else 6
	var reach := 0.24 if level == 2 else 0.36
	var starts := [Vector2(0, 0.2), Vector2(1, 0.7), Vector2(0.3, 0), Vector2(0.75, 1), Vector2(0, 0.85), Vector2(1, 0.15)]
	for i in n:
		var p0 := Vector2(starts[i].x * sz.x, starts[i].y * sz.y)
		var dir := (sz / 2.0 - p0).normalized()
		var pts := PackedVector2Array([p0])
		var p := p0
		for k in 4:
			var side := Vector2(-dir.y, dir.x) * (1 if k % 2 == 0 else -1) * sz.x * 0.05
			p += dir * sz.x * reach / 4.0 + side
			pts.append(p)
		c.draw_polyline(pts, Color(0, 0, 0, 0.8), 2.8)
		c.draw_polyline(pts, col, 1.4)


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
