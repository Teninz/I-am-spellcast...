"""Эффекты заклинаний, отрендеренные в Blender (bpy), в листы кадров для Godot.

Стиль — «мультяшный огонь»: сферы, искажённые шумом, со ступенчатой заливкой
(жёлтый → оранжевый → красный → копоть) и растворением по шуму, без фотореализма.

    python render_fx.py <эффект> <папка>     эффекты: fireball, explosion, steam, all

Нужен модуль bpy (pip install bpy==4.2.0, Python 3.11) и Pillow.
Лист кадров: assets/fx/<эффект>.webp, кадры слева направо, сверху вниз (см. SPECS).
"""
import math
import os
import sys

import bpy
from PIL import Image

# кадров, размер кадра, столбцов
SPECS = {  # лист: кадров, размер кадра, столбцов, сцена, палитра
    "fireball": (12, 160, 4, "orb", "FIRE"),
    "explosion": (20, 256, 5, "explosion", "FIRE"),
    "steam": (20, 256, 5, "steam", "STEAM"),
    "water_orb": (12, 160, 4, "orb", "WATER"),
    "splash": (18, 256, 6, "splash", "WATER"),
    "dark_orb": (12, 160, 4, "orb", "DARK"),
    "shadow_burst": (20, 256, 5, "explosion", "DARK"),
    "arcane_orb": (12, 160, 4, "orb", "ARCANE"),
    "arcane_burst": (18, 256, 6, "star_burst", "ARCANE"),
    "holy_pillar": (20, 256, 5, "pillar", "HOLY"),
    "zap_hit": (12, 256, 4, "star_burst", "LIGHT"),
    "heal": (20, 256, 5, "heal", "HEAL"),
    "shield": (18, 256, 6, "shield", "SHIELD"),
}

FIRE = [  # позиция на шкале «жара» → цвет (ступеньками)
    (0.00, (0.10, 0.04, 0.04, 1)),
    (0.22, (0.42, 0.07, 0.03, 1)),
    (0.42, (0.85, 0.20, 0.03, 1)),
    (0.62, (1.00, 0.52, 0.06, 1)),
    (0.80, (1.00, 0.84, 0.30, 1)),
    (0.93, (1.00, 0.97, 0.78, 1)),
]
WATER = [
    (0.00, (0.03, 0.10, 0.25, 1)),
    (0.22, (0.05, 0.24, 0.58, 1)),
    (0.42, (0.12, 0.48, 0.90, 1)),
    (0.62, (0.42, 0.76, 1.00, 1)),
    (0.82, (0.86, 0.96, 1.00, 1)),
]
DARK = [
    (0.00, (0.04, 0.02, 0.07, 1)),
    (0.22, (0.14, 0.05, 0.22, 1)),
    (0.42, (0.32, 0.09, 0.50, 1)),
    (0.62, (0.60, 0.28, 0.88, 1)),
    (0.82, (0.90, 0.74, 1.00, 1)),
]
ARCANE = [
    (0.00, (0.07, 0.05, 0.20, 1)),
    (0.22, (0.22, 0.14, 0.58, 1)),
    (0.45, (0.45, 0.34, 0.95, 1)),
    (0.68, (0.72, 0.68, 1.00, 1)),
    (0.86, (1.00, 1.00, 1.00, 1)),
]
HOLY = [
    (0.00, (0.45, 0.28, 0.05, 1)),
    (0.22, (0.85, 0.58, 0.12, 1)),
    (0.45, (1.00, 0.84, 0.35, 1)),
    (0.68, (1.00, 0.96, 0.70, 1)),
    (0.86, (1.00, 1.00, 0.96, 1)),
]
LIGHT = [
    (0.00, (0.30, 0.24, 0.05, 1)),
    (0.25, (0.80, 0.68, 0.10, 1)),
    (0.50, (1.00, 0.94, 0.40, 1)),
    (0.75, (1.00, 1.00, 0.90, 1)),
]
HEAL = [
    (0.00, (0.08, 0.28, 0.08, 1)),
    (0.25, (0.25, 0.62, 0.15, 1)),
    (0.50, (0.58, 0.90, 0.30, 1)),
    (0.74, (0.95, 1.00, 0.62, 1)),
]
SHIELD = [
    (0.00, (0.45, 0.72, 1.00, 1)),
    (0.45, (0.62, 0.84, 1.00, 1)),
    (0.68, (0.86, 0.95, 1.00, 1)),
    (0.85, (1.00, 1.00, 1.00, 1)),
]
STEAM = [
    (0.00, (0.38, 0.40, 0.46, 1)),
    (0.30, (0.62, 0.65, 0.72, 1)),
    (0.58, (0.84, 0.87, 0.92, 1)),
    (0.82, (0.98, 0.99, 1.00, 1)),
]


def reset(size: int, frames: int) -> bpy.types.Scene:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 12
    sc.cycles.use_denoising = False
    sc.cycles.max_bounces = 0
    sc.render.film_transparent = True
    sc.render.resolution_x = size
    sc.render.resolution_y = size
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"  # цвета ровно как в шкале, без киношной кривой
    sc.frame_start = 1
    sc.frame_end = frames
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 4.0
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    cam.location = (0, -10, 0)
    cam.rotation_euler = (math.pi / 2, 0, 0)
    sc.camera = cam
    return sc


def key(obj, path: str, frame: int, value, index: int = -1) -> None:
    setattr(obj, path, value) if index < 0 else getattr(obj, path).__setitem__(index, value)
    obj.keyframe_insert(path, frame=frame, index=index)


def linear(obj) -> None:
    ad = obj.animation_data
    if ad and ad.action:
        for fc in ad.action.fcurves:
            for kp in fc.keyframe_points:
                kp.interpolation = "LINEAR"


def toon_material(name: str, stops, churn_obj, erosion_keys, heat_keys, noise_scale: float = 2.2):
    """Заливка ступеньками: жар = «лицом к камере» + шум + общий жар (ключи), минус возраст.
    Прозрачность — растворение по шуму: порог растёт по ключам erosion_keys [(кадр, 0..1)]."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.blend_method = "BLEND"
    nt = m.node_tree
    n = nt.nodes
    n.clear()
    out = n.new("ShaderNodeOutputMaterial")
    tc = n.new("ShaderNodeTexCoord")
    tc.object = churn_obj
    noise = n.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = noise_scale
    noise.inputs["Detail"].default_value = 3.0
    noise.inputs["Roughness"].default_value = 0.55
    nt.links.new(tc.outputs["Object"], noise.inputs["Vector"])
    lw = n.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.45
    face = n.new("ShaderNodeMath")
    face.operation = "SUBTRACT"
    face.inputs[0].default_value = 1.0
    nt.links.new(lw.outputs["Facing"], face.inputs[1])
    mix = n.new("ShaderNodeMath")
    mix.operation = "MULTIPLY_ADD"
    nt.links.new(noise.outputs["Fac"], mix.inputs[0])
    mix.inputs[1].default_value = 0.55
    nt.links.new(face.outputs[0], mix.inputs[2])
    heat = n.new("ShaderNodeMath")
    heat.operation = "MULTIPLY"
    nt.links.new(mix.outputs[0], heat.inputs[0])
    for f, v in heat_keys:
        heat.inputs[1].default_value = v
        heat.inputs[1].keyframe_insert("default_value", frame=f)
    ramp = n.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = stops[0]
    els[1].position, els[1].color = stops[1]
    for pos, col in stops[2:]:
        e = els.new(pos)
        e.color = col
    nt.links.new(heat.outputs[0], ramp.inputs["Fac"])
    emit = n.new("ShaderNodeEmission")
    nt.links.new(ramp.outputs["Color"], emit.inputs["Color"])
    # Растворение: видно там, где шум выше порога.
    thr = n.new("ShaderNodeMath")
    thr.operation = "GREATER_THAN"
    nt.links.new(noise.outputs["Fac"], thr.inputs[0])
    for f, v in erosion_keys:
        thr.inputs[1].default_value = v
        thr.inputs[1].keyframe_insert("default_value", frame=f)
    transp = n.new("ShaderNodeBsdfTransparent")
    mixs = n.new("ShaderNodeMixShader")
    nt.links.new(thr.outputs[0], mixs.inputs["Fac"])
    nt.links.new(transp.outputs[0], mixs.inputs[1])
    nt.links.new(emit.outputs[0], mixs.inputs[2])
    nt.links.new(mixs.outputs[0], out.inputs["Surface"])
    if nt.animation_data and nt.animation_data.action:
        for fc in nt.animation_data.action.fcurves:
            for kp in fc.keyframe_points:
                kp.interpolation = "LINEAR"
    return m


def blob(name: str, loc, radius: float, churn_obj, strength: float, tex_size: float, mat) -> bpy.types.Object:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=5, radius=radius, location=loc)
    o = bpy.context.active_object
    o.name = name
    tex = bpy.data.textures.new(name + "_tex", "CLOUDS")
    tex.noise_scale = tex_size
    tex.noise_depth = 2
    d = o.modifiers.new("disp", "DISPLACE")
    d.texture = tex
    d.texture_coords = "OBJECT"
    d.texture_coords_object = churn_obj
    d.strength = strength
    d.mid_level = 0.5
    bpy.ops.object.shade_smooth()
    o.data.materials.append(mat)
    return o


def churn_empty(frames: int, loop_radius: float = 0.0, rise: float = 0.0) -> bpy.types.Object:
    """Пустышка, по которой «течёт» шум. loop_radius — ходит по кругу (зацикленная анимация)."""
    e = bpy.data.objects.new("churn", None)
    bpy.context.scene.collection.objects.link(e)
    steps = frames
    for i in range(steps + 1):
        f = 1 + i
        a = 2 * math.pi * i / steps
        e.location = (loop_radius * math.cos(a), loop_radius * math.sin(a), -rise * i / steps)
        e.keyframe_insert("location", frame=f)
    linear(e)
    return e


# ——— эффекты ———

def orb(frames: int, pal) -> None:
    """Летящий шар-комета (зацикленный): горячее ядро, вокруг пламя/вода/тьма по палитре,
    хвост из язычков тянется влево и рвётся по шуму — шар летит вправо."""
    FIRE = pal
    ch = churn_empty(frames, loop_radius=0.6)
    core = toon_material("fb_core", FIRE, ch, [(1, 0.0)], [(1, 0.95)], 2.4)
    blob("core", (0.55, 0, 0), 0.55, ch, 0.28, 0.4, core)
    shell = toon_material("fb_shell", FIRE, ch, [(1, 0.2)], [(1, 0.6)], 3.0)
    o = blob("shell", (0.45, 0, 0), 0.72, ch, 0.4, 0.35, shell)
    o.scale = (1.1, 1, 1)
    tail = toon_material("fb_tail", FIRE, ch, [(1, 0.34)], [(1, 0.5)], 3.6)
    for i, (x, r, z) in enumerate([(-0.2, 0.5, 0.1), (-0.7, 0.38, -0.08), (-1.15, 0.3, 0.12),
                                    (-1.5, 0.22, -0.05), (-1.8, 0.15, 0.08)]):
        o = blob(f"tail{i}", (x, 0, z), r, ch, 0.5, 0.3, tail)
        o.scale = (1.6, 1, 0.8)


def explosion(frames: int, pal) -> None:
    """Взрыв: вспышка, клубы разбухают, темнеют (по палитре) и растворяются."""
    FIRE = pal
    ch = churn_empty(frames, rise=-1.2)
    end = frames
    mat = toon_material("ex", FIRE, ch,
        [(1, 0.0), (int(end * 0.5), 0.1), (int(end * 0.8), 0.4), (end, 0.7)],
        [(1, 1.2), (int(end * 0.2), 0.95), (int(end * 0.5), 0.55), (end, 0.2)], 2.0)
    puffs = [((0, 0, 0), 0.85, 0), ((0.72, 0, 0.3), 0.5, 1), ((-0.68, 0, 0.22), 0.55, 1),
             ((0.4, 0, -0.55), 0.45, 2), ((-0.45, 0, -0.48), 0.42, 2), ((0.1, 0, 0.78), 0.5, 1),
             ((-0.3, 0, 0.62), 0.35, 3), ((0.85, 0, -0.15), 0.32, 3), ((-0.9, 0, -0.1), 0.3, 2)]
    for i, (loc, r, delay) in enumerate(puffs):
        o = blob(f"puff{i}", loc, r, ch, 0.5, 0.5, mat)
        f0 = 1 + delay
        o.scale = (0.05, 0.05, 0.05)
        o.keyframe_insert("scale", frame=1)
        o.keyframe_insert("scale", frame=f0)
        o.scale = (1.0, 1.0, 1.0)
        o.keyframe_insert("scale", frame=f0 + int(end * 0.3))
        o.scale = (1.25, 1.25, 1.25)
        o.location = (loc[0] * 1.3, 0, loc[2] * 1.3 + 0.35)
        o.keyframe_insert("scale", frame=end)
        o.keyframe_insert("location", frame=end)
        o.location = loc
        o.keyframe_insert("location", frame=1)
        for fc in o.animation_data.action.fcurves:
            for kp in fc.keyframe_points:
                kp.interpolation = "SINE"
                kp.easing = "EASE_OUT"


def steam(frames: int, pal) -> None:
    """Шипение: огонёк гаснет в клубе пара — белые клубы вздуваются, поднимаются и тают."""
    ch = churn_empty(frames, rise=-1.6)
    end = frames
    smoke = toon_material("st", STEAM, ch,
        [(1, 0.12), (int(end * 0.45), 0.2), (int(end * 0.8), 0.45), (end, 0.7)],
        [(1, 0.8), (end, 0.5)], 2.4)
    ember = toon_material("st_fire", FIRE, ch,
        [(1, 0.0), (int(end * 0.25), 0.55), (int(end * 0.4), 1.0)],
        [(1, 1.4), (int(end * 0.4), 0.8)], 3.0)
    core = blob("ember", (0, 0, -0.3), 0.45, ch, 0.3, 0.4, ember)
    core.scale = (1, 1, 1)
    core.keyframe_insert("scale", frame=1)
    core.scale = (0.3, 0.3, 0.3)
    core.keyframe_insert("scale", frame=int(end * 0.4))
    puffs = [((0, 0, -0.1), 0.6, 0), ((0.6, 0, 0.1), 0.45, 1), ((-0.55, 0, 0.15), 0.48, 2),
             ((0.25, 0, 0.55), 0.42, 3), ((-0.3, 0, 0.6), 0.38, 3)]
    for i, (loc, r, delay) in enumerate(puffs):
        o = blob(f"steam{i}", loc, r, ch, 0.45, 0.45, smoke)
        o.scale = (0.05, 0.05, 0.05)
        o.keyframe_insert("scale", frame=1)
        o.keyframe_insert("scale", frame=1 + delay)
        o.scale = (1.0, 1.0, 1.0)
        o.keyframe_insert("scale", frame=1 + delay + int(end * 0.35))
        o.scale = (1.3, 1.3, 1.3)
        o.keyframe_insert("scale", frame=end)
        o.location = loc
        o.keyframe_insert("location", frame=1)
        o.location = (loc[0] * 1.2, 0, loc[2] + 0.9)
        o.keyframe_insert("location", frame=end)
        for fc in o.animation_data.action.fcurves:
            for kp in fc.keyframe_points:
                kp.interpolation = "SINE"
                kp.easing = "EASE_OUT"


def grow(o, keys, ease: str = "EASE_OUT") -> None:
    """Ключи масштаба/положения: [(кадр, масштаб, (x, z) или None)]."""
    for f, sc, loc in keys:
        o.scale = (sc, sc, sc) if isinstance(sc, (int, float)) else sc
        o.keyframe_insert("scale", frame=f)
        if loc is not None:
            o.location = (loc[0], o.location[1], loc[1])
            o.keyframe_insert("location", frame=f)
    for fc in o.animation_data.action.fcurves:
        for kp in fc.keyframe_points:
            kp.interpolation = "SINE"
            kp.easing = ease


def splash(frames: int, pal) -> None:
    """Всплеск воды: капля бьёт и плющится, по краю встаёт корона, брызги летят дугами и падают."""
    ch = churn_empty(frames, rise=-0.6)
    end = frames
    body = toon_material("sp_body", pal, ch, [(1, 0.0), (int(end * 0.5), 0.15), (end, 0.75)],
        [(1, 0.95), (end, 0.5)], 2.4)
    o = blob("body", (0, 0, 0), 0.7, ch, 0.35, 0.4, body)
    grow(o, [(1, (0.6, 0.6, 0.8), (0, 0.5)), (3, (1.25, 1.0, 0.8), (0, -0.3)), (end, (1.9, 1.0, 0.4), (0, -0.9))])
    crown = toon_material("sp_crown", pal, ch, [(1, 0.05), (int(end * 0.55), 0.2), (end, 0.8)], [(1, 0.9), (end, 0.55)], 2.8)
    for i in range(7):
        x = -1.2 + 2.4 * i / 6
        c = blob(f"crown{i}", (x, 0, -0.5), 0.26, ch, 0.15, 0.3, crown)
        h = 1.0 - abs(x) * 0.25
        grow(c, [(1, 0.01, (x * 0.4, -0.5)), (2, (0.6, 0.6, 1.0), (x * 0.6, -0.4)),
                 (6, (0.8, 0.8, 2.4 * h), (x, 0.0)), (int(end * 0.6), (0.6, 0.6, 1.4), (x * 1.15, -0.4)),
                 (end, (0.2, 0.2, 0.3), (x * 1.25, -0.9))])
    drops = toon_material("sp_drop", pal, ch, [(1, 0.0), (int(end * 0.6), 0.1), (end, 0.7)], [(1, 1.0), (end, 0.7)], 3.0)
    import random
    rnd = random.Random(7)
    for i in range(12):
        a = math.pi * (0.08 + 0.84 * i / 11)  # веер вверх
        sp = rnd.uniform(1.2, 1.9)
        r = rnd.uniform(0.14, 0.26)
        d = blob(f"drop{i}", (0, 0, 0), r, ch, 0.05, 0.3, drops)
        for f in range(1, end + 1, 2):
            k = (f - 1) / (end - 1)
            d.location = (math.cos(a) * sp * k * 1.2, 0, -0.2 + math.sin(a) * sp * k * 2.4 - 2.8 * k * k)
            d.keyframe_insert("location", frame=f)
            sc = min(1.0, k * 8) * (1.0 if k < 0.7 else 0.6)
            d.scale = (sc, sc * 1.0, sc * 1.3)
            d.keyframe_insert("scale", frame=f)


def star_burst(frames: int, pal) -> None:
    """Вспышка-звезда: яркое ядро и лучи-шипы в две смены, потом искры тают (молния, тайна)."""
    ch = churn_empty(frames, loop_radius=0.4)
    end = frames
    mat = toon_material("sb", pal, ch, [(1, 0.0), (int(end * 0.5), 0.12), (end, 0.8)],
        [(1, 1.0), (int(end * 0.5), 0.7), (end, 0.4)], 2.6)
    core = blob("core", (0, 0, 0), 0.55, ch, 0.3, 0.4, mat)
    grow(core, [(1, 0.2, None), (3, 1.25, None), (int(end * 0.45), 0.7, None), (end, 0.15, None)])
    import random
    rnd = random.Random(3)
    for wave in range(2):
        for i in range(6):
            ang = (i + 0.5 * wave) * math.pi / 3 + rnd.uniform(-0.25, 0.25)
            bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.16, radius2=0.0, depth=1.6,
                location=(math.cos(ang) * 0.95, 0, math.sin(ang) * 0.95))
            c = bpy.context.active_object
            c.rotation_euler = (0, math.pi / 2 - ang, 0)
            c.data.materials.append(mat)
            f0 = 1 + wave * int(end * 0.22)
            ln = rnd.uniform(0.8, 1.25)
            grow(c, [(f0, (0.01, 0.01, 0.01), None), (f0 + 1, (1, 1, 0.4 * ln), None),
                     (f0 + 3, (1, 1, ln), None), (f0 + int(end * 0.35), (0.4, 0.4, ln * 1.2), None),
                     (f0 + int(end * 0.45), (0.01, 0.01, 0.01), None)])


def pillar(frames: int, pal) -> None:
    """Столп света сверху: луч бьёт в цель, у подножия расходится кольцо, вверх летят искры."""
    ch = churn_empty(frames, rise=2.5)
    end = frames
    beam = toon_material("pl_beam", pal, ch, [(1, 0.0), (int(end * 0.55), 0.1), (end, 0.8)],
        [(1, 1.0), (int(end * 0.5), 0.8), (end, 0.5)], 1.8)
    glow = toon_material("pl_glow", pal, ch, [(1, 0.25), (int(end * 0.55), 0.3), (end, 0.85)],
        [(1, 0.6), (end, 0.35)], 3.2)
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.8, depth=4.4, location=(0, 0, 0.3))
    halo = bpy.context.active_object
    halo.data.materials.append(glow)
    grow(halo, [(1, (0.05, 0.05, 1), None), (4, (1.2, 1.2, 1), None), (int(end * 0.45), (1.0, 1.0, 1), None),
                (end, (0.05, 0.05, 1), None)])
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.42, depth=4.4, location=(0, 0, 0.3))
    col = bpy.context.active_object
    col.location.y = -1.0
    col.data.materials.append(beam)
    grow(col, [(1, (0.05, 0.05, 1), None), (3, (1.15, 1.15, 1), None), (int(end * 0.4), (0.9, 0.9, 1), None),
               (end, (0.05, 0.05, 1), None)])
    bpy.ops.mesh.primitive_torus_add(major_radius=1.0, minor_radius=0.1, location=(0, 0, -1.25))
    ring = bpy.context.active_object
    ring.rotation_euler = (math.radians(18), 0, 0)
    ring.location.y = -1.5
    ring.data.materials.append(beam)
    grow(ring, [(1, 0.05, None), (3, 0.05, None), (int(end * 0.5), 1.1, None), (end, 1.6, None)])
    motes = toon_material("pl_mote", pal, ch, [(1, 0.0), (int(end * 0.6), 0.1), (end, 0.7)], [(1, 1.2)], 3.0)
    import random
    rnd = random.Random(11)
    for i in range(8):
        x = rnd.uniform(-0.9, 0.9)
        m = blob(f"mote{i}", (x, 0, -1.2), rnd.uniform(0.07, 0.13), ch, 0.02, 0.3, motes)
        f0 = 2 + rnd.randint(0, int(end * 0.4))
        grow(m, [(1, 0.01, (x, -1.2)), (f0, 0.01, (x, -1.2)), (f0 + 1, 1.0, (x, -1.1)),
                 (end, 0.4, (x * 1.2, 1.6))], "EASE_IN_OUT")


def heal(frames: int, pal) -> None:
    """Лечение: зелёно-золотые искорки поднимаются спиралью, всплывают светлые крестики."""
    ch = churn_empty(frames, rise=1.5)
    end = frames
    mat = toon_material("hl", pal, ch, [(1, 0.0), (int(end * 0.6), 0.1), (end, 0.75)],
        [(1, 0.95), (end, 0.6)], 2.8)
    for i in range(10):
        m = blob(f"spark{i}", (0, 0, -1.3), 0.2, ch, 0.03, 0.3, mat)
        ph = i * 2 * math.pi / 10 * 2.2
        f0 = 1 + int(i * end * 0.035)
        for f in range(f0, end + 1, 2):
            k = (f - f0) / max(1, end - f0)
            a = ph + k * 5.0
            m.location = (math.cos(a) * 0.9 * (1 - 0.3 * k), 0, -1.4 + 2.8 * k)
            m.keyframe_insert("location", frame=f)
            sc = min(1.0, k * 6) * (1 - 0.5 * k)
            m.scale = (sc, sc, sc)
            m.keyframe_insert("scale", frame=f)
        m.scale = (0, 0, 0)
        m.keyframe_insert("scale", frame=1)
    for i, (x, f0) in enumerate([(-0.45, 3), (0.5, 6), (0.05, 9)]):
        for dims in ((0.26, 0.26, 0.85), (0.85, 0.26, 0.26)):
            bpy.ops.mesh.primitive_cube_add(size=1, location=(x, 0, -0.9))
            c = bpy.context.active_object
            c.data.materials.append(mat)
            grow(c, [(1, (0, 0, 0), (x, -0.9)), (f0, (0, 0, 0), (x, -0.9)), (f0 + 2, dims, (x, -0.7)),
                     (min(end, f0 + 9), (dims[0] * 0.8, dims[1], dims[2] * 0.8), (x, 0.8)),
                     (end, (0, 0, 0), (x, 1.2))])


def shield(frames: int, pal) -> None:
    """Щит: пузырь с яркой кромкой вспыхивает вокруг цели, чуть пружинит и тает."""
    end = frames
    m = bpy.data.materials.new("sh")
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes
    n.clear()
    out = n.new("ShaderNodeOutputMaterial")
    lw = n.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.35
    ramp = n.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = pal[0]
    els[1].position, els[1].color = pal[1]
    for pos, c in pal[2:]:
        els.new(pos).color = c
    nt.links.new(lw.outputs["Facing"], ramp.inputs["Fac"])
    emit = n.new("ShaderNodeEmission")
    nt.links.new(ramp.outputs["Color"], emit.inputs["Color"])
    # Прозрачность: кромка плотная, середина полупрозрачная; к концу гаснет целиком.
    rim = n.new("ShaderNodeMath")
    rim.operation = "GREATER_THAN"
    rim.inputs[1].default_value = 0.4
    nt.links.new(lw.outputs["Facing"], rim.inputs[0])
    fill = n.new("ShaderNodeMath")
    fill.operation = "MAXIMUM"
    nt.links.new(rim.outputs[0], fill.inputs[0])
    fill.inputs[1].default_value = 0.09
    fade = n.new("ShaderNodeMath")
    fade.operation = "MULTIPLY"
    nt.links.new(fill.outputs[0], fade.inputs[0])
    for f, v in [(1, 1.0), (int(end * 0.6), 1.0), (end, 0.0)]:
        fade.inputs[1].default_value = v
        fade.inputs[1].keyframe_insert("default_value", frame=f)
    transp = n.new("ShaderNodeBsdfTransparent")
    mix = n.new("ShaderNodeMixShader")
    nt.links.new(fade.outputs[0], mix.inputs["Fac"])
    nt.links.new(transp.outputs[0], mix.inputs[1])
    nt.links.new(emit.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs["Surface"])
    m.blend_method = "BLEND"
    bpy.ops.mesh.primitive_uv_sphere_add(segments=64, ring_count=32, radius=1.55)
    o = bpy.context.active_object
    bpy.ops.object.shade_smooth()
    o.data.materials.append(m)
    grow(o, [(1, 0.2, None), (4, 1.12, None), (7, 0.96, None), (10, 1.0, None), (end, 1.05, None)])
    # Искры по кромке в момент вспышки.
    ch = churn_empty(frames, loop_radius=0.3)
    sp = toon_material("sh_sp", pal, ch, [(1, 0.0), (int(end * 0.5), 0.3), (int(end * 0.7), 1.0)], [(1, 1.3)], 3.0)
    for i in range(8):
        a = i * math.pi / 4
        s_ = blob(f"sp{i}", (math.cos(a) * 1.55, -1, math.sin(a) * 1.55), 0.1, ch, 0.02, 0.3, sp)
        grow(s_, [(1, 0.01, None), (3, 0.01, None), (5, 1.2, None), (int(end * 0.6), 0.01, None)])


def outline(path: str, px: int = 3, color=(46, 20, 12)) -> None:
    """Тёмный контур вокруг силуэта — как обводка в книжной графике игры."""
    from PIL import ImageFilter
    im = Image.open(path).convert("RGBA")
    a = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    ring = a.filter(ImageFilter.MaxFilter(px * 2 + 1)).filter(ImageFilter.GaussianBlur(0.7))
    base = Image.new("RGBA", im.size, color + (0,))
    base.putalpha(ring)
    base.alpha_composite(im)
    base.save(path)


NO_OUTLINE = {"shield"}  # полупрозрачный пузырь — контур бы его запачкал


def render(name: str, out_dir: str) -> str:
    frames, size, cols, scene, pal = SPECS[name]
    sc = reset(size, frames)
    globals()[scene](frames, globals()[pal])
    tmp = os.path.join(out_dir, "_frames_" + name)
    os.makedirs(tmp, exist_ok=True)
    paths = []
    for f in range(1, frames + 1):
        sc.frame_set(f)
        p = os.path.join(tmp, f"{f:03d}.png")
        sc.render.filepath = p
        bpy.ops.render.render(write_still=True)
        paths.append(p)
    if name not in NO_OUTLINE:
        for p in paths:
            outline(p)
    rows = math.ceil(frames / cols)
    sheet = Image.new("RGBA", (cols * size, rows * size), (0, 0, 0, 0))
    for i, p in enumerate(paths):
        sheet.paste(Image.open(p).convert("RGBA"), ((i % cols) * size, (i // cols) * size))
    dst = os.path.join(out_dir, name + ".webp")
    sheet.save(dst, "WEBP", lossless=True)
    return dst


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    which, out = args[0], args[1]
    os.makedirs(out, exist_ok=True)
    for nm in (SPECS if which == "all" else [which]):
        print("rendered", render(nm, out))
