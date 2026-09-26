#!/usr/bin/env python3
"""Проверяет таблицы книг из data/books/*.json и собирает docs/spells/*.md.

Мешочек: 20 фишек, фишка возвращается сразу после вытягивания,
поэтому шанс каждой фишки постоянен в течение каста.
"""
import itertools
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
BOOKS = ROOT / "data" / "books"
OUT = ROOT / "docs" / "spells"

ICON = {"F": "🔥", "W": "💧", "H": "✨", "X": "🌀"}
ELEMENT = {"F": "Огонь", "W": "Вода", "H": "Святость", "X": "Хаос"}
CATEGORY = {"damage": "Урон", "control": "Контроль", "support": "Польза"}
CHAOS = {"X1": "Хаос I", "X2": "Хаос II", "X3": "Хаос III"}


def combo_probabilities(bag):
    total = sum(bag.values())
    p = {k: v / total for k, v in bag.items()}
    x = p.get("X", 0)
    probs = {}
    for combo in itertools.product("FWH", repeat=3):
        probs["".join(combo)] = p[combo[0]] * p[combo[1]] * p[combo[2]]
    probs["X1"] = 3 * x * (1 - x) ** 2
    probs["X2"] = 3 * x**2 * (1 - x)
    probs["X3"] = x**3
    return probs


def validate(book):
    errors = []
    combos = [s["combo"] for s in book["spells"]]
    expected = {"".join(c) for c in itertools.product("FWH", repeat=3)} | set(CHAOS)
    if set(combos) != expected or len(combos) != 30:
        errors.append(f"комбинации: лишние {set(combos) - expected}, "
                      f"нет {expected - set(combos)}, всего {len(combos)}")
    if sum(book["bag"].values()) != 20:
        errors.append(f"в мешочке {sum(book['bag'].values())} фишек, а не 20")
    counts = {c: 0 for c in CATEGORY}
    for s in book["spells"]:
        counts[s["category"]] += 1
    if counts != book["target_split"]:
        errors.append(f"распределение {counts}, ожидалось {book['target_split']}")
    return errors


def fmt_combo(combo):
    return CHAOS.get(combo) or "".join(ICON[c] for c in combo)


def render(book):
    probs = combo_probabilities(book["bag"])
    spells = sorted(book["spells"], key=lambda s: (s["combo"] in CHAOS, -probs[s["combo"]], s["combo"]))
    by_cat = {c: 0.0 for c in CATEGORY}
    exp_damage = exp_heal = 0.0
    for s in book["spells"]:
        p = probs[s["combo"]]
        by_cat[s["category"]] += p
        exp_damage += p * s.get("damage", 0)
        exp_heal += p * (s.get("heal", 0) + s.get("shield", 0))

    bag = " · ".join(f"{ICON[k]} {ELEMENT[k]} ×{v}" for k, v in book["bag"].items())
    split = " · ".join(f"{CATEGORY[c]} {n}" for c, n in book["target_split"].items())
    lines = [
        f"# {book['name']}",
        "",
        f"*{book['flavor']}*",
        "",
        f"- **Класс:** {book['class']}",
        f"- **Мешочек (20 фишек):** {bag}",
        f"- **Распределение заклинаний:** {split}",
        "",
        "## Сводка шансов",
        "",
        "| Показатель | Значение |",
        "|---|---|",
    ]
    for c, name in CATEGORY.items():
        lines.append(f"| Шанс заклинания «{name}» | {by_cat[c] * 100:.1f} % |")
    lines += [
        f"| Средний урон по цели за каст | {exp_damage:.2f} |",
        f"| Среднее лечение/щит по цели за каст | {exp_heal:.2f} |",
        "",
        "Числа — без Мудрости. Мудрость добавляет +1 к каждому урону, лечению и щиту.",
        "",
        "## Заклинания",
        "",
        "Отсортированы от самых частых к самым редким. Хаос — в конце.",
        "",
        "| Комбинация | Заклинание | Тип | Эффект | Шанс |",
        "|---|---|---|---|---|",
    ]
    for s in spells:
        p = probs[s["combo"]] * 100
        chance = f"{p:.2f} %" if p >= 0.1 else f"{p:.3f} %"
        lines.append(f"| {fmt_combo(s['combo'])} | **{s['name']}** | "
                     f"{CATEGORY[s['category']]} | {s['effect']} | {chance} |")
    lines += ["", "*Файл собран скриптом `tools/gen_spells.py` из "
              f"`data/books/{book['id']}.json`. Правьте JSON, а не этот файл.*", ""]
    return "\n".join(lines)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    failed = False
    for path in sorted(BOOKS.glob("*.json")):
        book = json.loads(path.read_text(encoding="utf-8"))
        errors = validate(book)
        for e in errors:
            print(f"{path.name}: {e}", file=sys.stderr)
        failed |= bool(errors)
        (OUT / f"{book['id']}.md").write_text(render(book), encoding="utf-8")
        print(f"{path.name} -> docs/spells/{book['id']}.md")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
