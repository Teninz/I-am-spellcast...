"""Приводит сгенерированный пиксель-арт к точной сетке и ограниченной палитре.

Генераторы рисуют «пиксели» разного размера (у одних картинок клетка 8 точек, у других 4)
и с шумом по краям. Здесь каждая картинка уменьшается до сетки игры усреднением клетки
и сводится к палитре без дизеринга — получаются чистые квадраты одного размера.

    python tools/pixel/pixelize.py            # assets/pixel_trial/*.png -> assets/pixel_trial/px/
    python tools/pixel/pixelize.py fx         # листы эффектов assets/fx -> assets/pixel_trial/fx (в 4 раза мельче)

Сетка: портреты 96×128, фон 320×180 (ровно 1/4 экрана 1280×720 — масштаб ×4 без неровных пикселей).
"""
import glob
import os
import sys

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
SRC = os.path.join(ROOT, "assets", "pixel_trial")
OUT = os.path.join(SRC, "px")
PORTRAIT_GRID = (96, 128)
BG_GRID = (320, 180)
FX_SHRINK = 4  # кадр эффекта 256 -> 64 точки
FX_SHEETS = {  # кадров, столбцов (как Fx.SHEETS)
    "fireball": (12, 4), "explosion": (20, 5), "steam": (20, 5), "water_orb": (12, 4), "splash": (18, 6),
    "dark_orb": (12, 4), "shadow_burst": (20, 5), "arcane_orb": (12, 4), "arcane_burst": (18, 6),
    "holy_pillar": (20, 5), "zap_hit": (12, 4), "heal": (20, 5), "shield": (18, 6), "rock": (12, 4),
    "rubble": (20, 5), "ice_shard": (12, 4), "shatter": (16, 4), "gust": (20, 5), "illusion_orb": (12, 4),
    "prism": (18, 6), "clock": (20, 5), "sound_rings": (18, 6), "gears": (20, 5), "buff": (20, 5),
    "debuff": (20, 5),
}


def to_grid(im: Image.Image, grid, colors: int) -> Image.Image:
    small = im.convert("RGB").resize(grid, Image.BOX)
    return small.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")


def pixel_fx(path: str, dst: str, frames: int, cols: int) -> None:
    """Лист эффекта в пиксели: каждый кадр мельче в FX_SHRINK раз, прозрачность — да/нет,
    цвета — не больше 16 на лист. В игре показывается с NEAREST, так что пиксели крупные."""
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    small = im.resize((w // FX_SHRINK, h // FX_SHRINK), Image.BOX)
    alpha = small.getchannel("A").point(lambda v: 255 if v > 90 else 0)
    rgb = small.convert("RGB").quantize(colors=16, method=Image.Quantize.MEDIANCUT,
                                        dither=Image.Dither.NONE).convert("RGB")
    out = Image.merge("RGBA", (*rgb.split(), alpha))
    out.save(dst, "WEBP", lossless=True)


def main() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "fx":
        dst_dir = os.path.join(SRC, "fx")
        os.makedirs(dst_dir, exist_ok=True)
        for name, (frames, cols) in FX_SHEETS.items():
            pixel_fx(os.path.join(ROOT, "assets", "fx", name + ".webp"), os.path.join(dst_dir, name + ".webp"), frames, cols)
            print("fx", name)
        return
    os.makedirs(OUT, exist_ok=True)
    for path in sorted(glob.glob(os.path.join(SRC, "*.png"))):
        name = os.path.basename(path)
        im = Image.open(path)
        if name.startswith("bg_"):
            out = to_grid(im, BG_GRID, 48)
        else:
            out = to_grid(im, PORTRAIT_GRID, 40)
        out.save(os.path.join(OUT, name))
        print(name, out.size)


if __name__ == "__main__":
    main()
