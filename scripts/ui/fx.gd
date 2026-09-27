class_name Fx
extends RefCounted
## Анимации боя в духе сказочной книжки: всё на твинах и частицах, без отдельных картинок.
## Каждая функция сама убирает за собой созданные узлы. Скорость — по настройке «Скорость боя».
##   Fx.shake(card), Fx.bolt(host, from, to, color), Fx.burst(host, pos, color), Fx.puff(host, pos) …

static var _dot: Texture2D = null


## Мягкая круглая точка для частиц.
static func dot() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 32
		t.height = 32
		_dot = t
	return _dot


static func t(seconds: float) -> float:
	return Settings.delay(seconds)


static func center(c: Control) -> Vector2:
	var r := c.get_global_rect()
	return r.position + r.size / 2.0


## Встряска: покачивание вокруг центра (контейнеры не сбрасывают поворот).
static func shake(c: Control, strength: float = 1.0) -> void:
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.size / 2.0
	var deg := 2.5 * strength
	var tw := c.create_tween()
	for i in 4:
		tw.tween_property(c, "rotation_degrees", deg * (1 if i % 2 == 0 else -1), t(0.04))
		deg *= 0.6
	tw.tween_property(c, "rotation_degrees", 0.0, t(0.05))


## Вспышка цветом (урон — красным, лечение — зелёным) и возврат к прежнему цвету.
static func flash(c: Control, color: Color) -> void:
	if not is_instance_valid(c):
		return
	var base := c.self_modulate
	var tw := c.create_tween()
	tw.tween_property(c, "self_modulate", color, t(0.06))
	tw.tween_property(c, "self_modulate", base, t(0.25))


## Выпад: карточка на миг подаётся вперёд (враг атакует).
static func lunge(c: Control, to_left: bool) -> void:
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.size / 2.0
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(1.07, 1.07), t(0.08)).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(c, "rotation_degrees", -2.0 if to_left else 2.0, t(0.08))
	tw.tween_property(c, "scale", Vector2.ONE, t(0.14))
	tw.parallel().tween_property(c, "rotation_degrees", 0.0, t(0.14))


## Бросок в атаку: карточка заметно выезжает вперёд (к противнику) и возвращается на место.
static func charge(c: Control, to_left: bool) -> void:
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.size / 2.0
	var dx := -46.0 if to_left else 46.0
	var home := c.position
	var base := c.scale
	c.z_index = 5
	var tw := c.create_tween()
	tw.tween_property(c, "position:x", home.x - dx * 0.15, t(0.08)).set_trans(Tween.TRANS_SINE)  # замах
	tw.tween_property(c, "position:x", home.x + dx, t(0.12)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(c, "scale", base * 1.06, t(0.12))
	tw.tween_interval(t(0.08))
	tw.tween_property(c, "position:x", home.x, t(0.22)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(c, "scale", base, t(0.22))
	tw.tween_callback(func() -> void: c.z_index = 2 if c.get_meta("focus", false) else 0)


## Тот, кто ходит, — карточка чуть крупнее; остальные — обычного размера.
static func focus(c: Control, on: bool) -> void:
	if not is_instance_valid(c):
		return
	var want := Vector2(1.06, 1.06) if on else Vector2.ONE
	if c.scale.is_equal_approx(want) or c.get_meta("focus", false) == on:
		return
	c.set_meta("focus", on)
	c.pivot_offset = c.size / 2.0
	c.z_index = 2 if on else 0
	c.create_tween().tween_property(c, "scale", want, t(0.18)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Появление: карточка выпрыгивает из ничего.
static func pop_in(c: Control) -> void:
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.custom_minimum_size / 2.0
	c.scale = Vector2(0.2, 0.2)
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE, t(0.35)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(c, "modulate:a", 1.0, t(0.2))


## Выбыл: карточка вздрагивает и заваливается набок.
static func fall(c: Control) -> void:
	if not is_instance_valid(c):
		return
	c.pivot_offset = Vector2(c.size.x * 0.15, c.size.y)
	var tw := c.create_tween()
	tw.tween_property(c, "rotation_degrees", 3.0, t(0.08))
	tw.tween_property(c, "rotation_degrees", -2.5, t(0.35)).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


static func stand_up(c: Control) -> void:
	if is_instance_valid(c) and not is_zero_approx(c.rotation_degrees):
		c.create_tween().tween_property(c, "rotation_degrees", 0.0, t(0.25))


## Снаряд заклинания: светящийся шар со шлейфом летит по дуге, в конце — вспышка искр.
## Возвращает время полёта (чтобы дождаться удара).
static func bolt(host: Control, from: Vector2, to: Vector2, color: Color, chaos: bool = false) -> float:
	var dur := t(0.38)
	var orb := Node2D.new()
	orb.top_level = true
	orb.z_index = 20
	host.add_child(orb)
	orb.global_position = from
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var halo := Sprite2D.new()
	halo.texture = dot()
	halo.scale = Vector2(3.2, 3.2)
	halo.modulate = Color(color, 0.55)
	halo.material = glow
	orb.add_child(halo)
	var core := Sprite2D.new()
	core.texture = dot()
	core.scale = Vector2(1.7, 1.7)
	core.modulate = color.lightened(0.55)
	core.material = glow
	orb.add_child(core)
	var trail := CPUParticles2D.new()
	trail.texture = dot()
	trail.amount = 60
	trail.material = glow
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.spread = 180.0
	trail.initial_velocity_min = 10.0
	trail.initial_velocity_max = 40.0
	trail.gravity = Vector2.ZERO
	trail.scale_amount_min = 0.5
	trail.scale_amount_max = 1.1
	trail.color = color
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.9))
	ramp.set_color(1, Color(1, 1, 1, 0))
	trail.color_ramp = ramp
	if chaos:
		trail.hue_variation_min = -0.5
		trail.hue_variation_max = 0.5
	orb.add_child(trail)
	# Дуга: середина пути приподнята.
	var mid := (from + to) / 2.0 + Vector2(0, -minf(140.0, from.distance_to(to) * 0.25))
	var tw := orb.create_tween()
	tw.tween_method(func(k: float) -> void:
		var a := from.lerp(mid, k)
		var b := mid.lerp(to, k)
		orb.global_position = a.lerp(b, k)
		orb.rotation += 0.3, 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		burst(host, to, color, 26, chaos)
		core.visible = false
		halo.visible = false
		trail.emitting = false)
	tw.tween_interval(0.4)
	tw.tween_callback(orb.queue_free)
	return dur


## Разлёт искр из точки.
static func burst(host: Control, pos: Vector2, color: Color, amount: int = 24, rainbow: bool = false) -> void:
	var p := _particles(host, pos, amount, 0.6)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = add
	p.spread = 180.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 220.0
	p.gravity = Vector2(0, 260)
	p.damping_min = 60.0
	p.damping_max = 120.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.7
	p.color = color
	if rainbow:
		p.hue_variation_min = -0.5
		p.hue_variation_max = 0.5


## Искорки лечения: поднимаются вверх и гаснут.
static func sparkle_up(host: Control, rect: Rect2, color: Color) -> void:
	var p := _particles(host, rect.position + rect.size / 2.0, 22, 0.9)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = rect.size / 2.5
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 70.0
	p.gravity = Vector2(0, -40)
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.45
	p.color = color


## Облачко пыли (появление существа).
static func puff(host: Control, pos: Vector2) -> void:
	var p := _particles(host, pos, 30, 0.8)
	p.spread = 180.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.gravity = Vector2(0, -30)
	p.damping_min = 80.0
	p.damping_max = 140.0
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.8
	p.color = Color(0.78, 0.72, 0.62, 0.8)


## Конфетти из маленьких шляп разных цветов (победа).
static func confetti(host: Control) -> void:
	var size := host.get_viewport_rect().size
	for col in [Color("7a5bd6"), Color("d9502e"), Color("3b82d6"), Color("4f9a3a"), Color("e8c547")]:
		var p := _particles(host, Vector2(size.x / 2.0, -20), 18, 2.2)
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(size.x / 2.0, 10)
		p.direction = Vector2(0, 1)
		p.spread = 25.0
		p.initial_velocity_min = 80.0
		p.initial_velocity_max = 200.0
		p.gravity = Vector2(0, 160)
		p.angular_velocity_min = -300.0
		p.angular_velocity_max = 300.0
		p.scale_amount_min = 0.5
		p.scale_amount_max = 0.9
		p.texture = _hat()
		p.color = col


## Дрожь всего экрана (Хаос, крупный удар).
static func screen_shake(root: Control, strength: float = 6.0) -> void:
	if not is_instance_valid(root):
		return
	var base := root.position
	var tw := root.create_tween()
	for i in 6:
		tw.tween_property(root, "position", base + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength, t(0.03))
		strength *= 0.75
	tw.tween_property(root, "position", base, t(0.04))


## «Дыхание»: мягкое пульсирование (кольцо того, кто ходит). Возвращает твин, чтобы его остановить.
static func breathe(c: CanvasItem) -> Tween:
	var tw := c.create_tween().set_loops()
	tw.tween_property(c, "self_modulate", Color(1.35, 1.25, 0.9), 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "self_modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)
	return tw


## Фишка вылетает из мешочка и кувыркаясь ложится в ячейку.
static func chip_fly(host: Control, tex: Texture2D, from: Vector2, to: Vector2, px: float) -> float:
	var dur := t(0.28)
	var s := TextureRect.new()
	s.texture = tex
	s.top_level = true
	s.z_index = 15
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	s.size = Vector2(px, px)
	s.material = Art.circle_material()  # у фишки квадратная картинка с фоном — обрезаем по кругу
	s.pivot_offset = s.size / 2.0
	host.add_child(s)
	s.global_position = from - s.size / 2.0
	s.scale = Vector2(0.4, 0.4)
	var mid := (from + to) / 2.0 + Vector2(0, -70)
	var tw := s.create_tween()
	tw.tween_method(func(k: float) -> void:
		var a := from.lerp(mid, k)
		var b := mid.lerp(to, k)
		s.global_position = a.lerp(b, k) - s.size / 2.0
		s.rotation = k * TAU
		s.scale = Vector2.ONE * lerpf(0.4, 1.0, k), 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(s.queue_free)
	return dur


static func _particles(host: Control, pos: Vector2, amount: int, life: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.top_level = true
	p.z_index = 20
	p.texture = dot()
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.9
	p.local_coords = false
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	host.add_child(p)
	p.global_position = pos
	p.emitting = true
	host.get_tree().create_timer(life + 0.5, false).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free())
	return p


static var _hat_tex: Texture2D = null


## Маленькая остроконечная шляпа для конфетти (белая — красится цветом частицы).
static func _hat() -> Texture2D:
	if _hat_tex == null:
		var n := 24
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in n:
			for x in n:
				var cone := y < 18 and absf(x - 12) <= (y + 1) * 0.42
				var brim := y >= 17 and y <= 20 and x >= 2 and x <= 21
				if cone or brim:
					img.set_pixel(x, y, Color.WHITE if not (y >= 14 and y <= 15) else Color(0.75, 0.75, 0.75))
		_hat_tex = ImageTexture.create_from_image(img)
	return _hat_tex
