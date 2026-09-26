#!/usr/bin/env python3
"""Проверяет таблицы книг из data/books/*.json и собирает docs/spells/*.md.

Правило вытягивания:
- в мешочке 19 фишек стихий и 1 фишка Хаоса;
- фишки тянутся по одной, всего 3 вытягивания;
- шанс Хаоса на 1-м, 2-м и 3-м вытягивании — CHAOS_BY_DRAW (за каждую фишку
  Хаоса); Хаос оставляет чёрную метку в ячейке и возвращается в мешочек;
- иначе выпадает фишка стихии из оставшихся; она остаётся на столе до конца каста.
"""
import itertools
import json
import math
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
BOOKS = ROOT / "data" / "books"
OUT = ROOT / "docs" / "spells"

CHAOS_BY_DRAW = (0.05, 0.069, 0.088)

ICON = {"F": "🔥", "W": "💧", "H": "✨", "D": "🌑", "E": "🌿", "M": "⚙️",
        "S": "🎵", "T": "🔮", "I": "🌀", "L": "⚡", "C": "⏳"}
ELEMENT = {"F": "Огонь", "W": "Вода", "H": "Святость", "D": "Тьма", "E": "Земля", "M": "Механика",
           "S": "Звук", "T": "Тайна", "I": "Иллюзия", "L": "Молния", "C": "Время"}
CATEGORY = {
    "damage": "Урон",
    "control": "Контроль",
    "support": "Польза",
    "summon": "Призыв",
    "disease": "Болезнь",
    "roots": "Щиты и корни",
    "glitch": "Сбой",
    "fate": "Судьба",
    "curse": "Проклятие",
    "wild": "Дикая магия",
    "item": "Предмет",
}
CHAOS = {"X1": "Хаос I", "X2": "Хаос II", "X3": "Хаос III"}


def elements(book):
    return [k for k in book["bag"] if k != "X"]


def sequence_probability(counts, seq):
    """Шанс вытянуть фишки стихий в этом порядке без возвращения."""
    counts = dict(counts)
    total = sum(counts.values())
    p = 1.0
    for e in seq:
        if counts[e] <= 0:
            return 0.0
        p *= counts[e] / total
        counts[e] -= 1
        total -= 1
    return p


def combo_probabilities(book):
    counts = {k: v for k, v in book["bag"].items() if k != "X"}
    chips = book["bag"].get("X", 0)
    chaos = [min(1.0, c * chips) for c in CHAOS_BY_DRAW]
    no_chaos = math.prod(1 - c for c in chaos)
    probs = {}
    for seq in itertools.product(elements(book), repeat=3):
        probs["".join(seq)] = no_chaos * sequence_probability(counts, seq)
    for k in (1, 2, 3):
        probs[f"X{k}"] = 0.0
    for marks in itertools.product((False, True), repeat=3):
        k = sum(marks)
        if k:
            probs[f"X{k}"] += math.prod(c if m else 1 - c for c, m in zip(chaos, marks))
    return probs


def validate(book):
    errors = []
    combos = [s["combo"] for s in book["spells"]]
    expected = {"".join(s) for s in itertools.product(elements(book), repeat=3)} | set(CHAOS)
    if set(combos) != expected or len(combos) != 30:
        errors.append(f"комбинации: лишние {set(combos) - expected}, "
                      f"нет {expected - set(combos)}, всего {len(combos)}")
    if sum(book["bag"].values()) != 20 or book["bag"].get("X") != 1:
        errors.append("в мешочке должно быть 19 фишек стихий и 1 фишка Хаоса")
    counts = {c: 0 for c in book["target_split"]}
    for s in book["spells"]:
        if s["category"] not in counts:
            errors.append(f"{s['combo']}: категория {s['category']} не в распределении книги")
            continue
        counts[s["category"]] += 1
    if counts != book["target_split"]:
        errors.append(f"распределение {counts}, ожидалось {book['target_split']}")
    total = sum(combo_probabilities(book).values())
    if abs(total - 1) > 1e-9:
        errors.append(f"сумма шансов {total}, а не 1")
    return errors


def fmt_combo(combo):
    return CHAOS.get(combo) or "".join(ICON[c] for c in combo)


def fmt_chance(p):
    p *= 100
    return f"{p:.2f} %" if p >= 0.1 else f"{p:.3f} %"


def summary(book):
    probs = combo_probabilities(book)
    by_cat = {c: 0.0 for c in book["target_split"]}
    exp_damage = exp_heal = 0.0
    for s in book["spells"]:
        p = probs[s["combo"]]
        by_cat[s["category"]] += p
        exp_damage += p * s.get("damage", 0)
        exp_heal += p * (s.get("heal", 0) + s.get("shield", 0))
    return by_cat, exp_damage, exp_heal


def render_index(books):
    lines = [
        "# Книги заклинаний",
        "",
        "Сводка по всем книгам. Шансы — за один каст, без Мудрости и способностей класса.",
        "",
        "| Книга | Класс | Стихии | Шансы по типам | Урон за каст | Лечение/щит за каст |",
        "|---|---|---|---|---|---|",
    ]
    for book in books:
        by_cat, dmg, heal = summary(book)
        els = "".join(ICON[e] for e in elements(book))
        cats = " · ".join(f"{CATEGORY[c]} {p * 100:.0f} %" for c, p in by_cat.items())
        lines.append(f"| [{book['name']}]({book['id']}.md) | {book['class']} | {els} | "
                     f"{cats} | {dmg:.2f} | {heal:.2f} |")
    lines += ["", "*Файл собран скриптом `tools/gen_spells.py`.*", ""]
    return "\n".join(lines)


def render(book):
    probs = combo_probabilities(book)
    spells = sorted(book["spells"], key=lambda s: (s["combo"] in CHAOS, -probs[s["combo"]], s["combo"]))
    cats = list(book["target_split"])
    by_cat, exp_damage, exp_heal = summary(book)

    bag = " · ".join(f"{ICON[k]} {ELEMENT[k]} ×{v}" for k, v in book["bag"].items() if k != "X")
    split = " · ".join(f"{CATEGORY[c]} {n}" for c, n in book["target_split"].items())
    lines = [
        f"# {book['name']}",
        "",
        f"*{book['flavor']}*",
        "",
        f"- **Класс:** {book['class']}",
        f"- **Мешочек:** {bag} · ⚫ Хаос ×1 ("
        + " / ".join(f"{c * 100:g} %" for c in CHAOS_BY_DRAW) + " на 1-е / 2-е / 3-е вытягивание)",
        f"- **Распределение заклинаний:** {split}",
    ]
    if book.get("notes"):
        lines += [f"- **Особое:** {book['notes']}"]
    lines += [
        "",
        "## Сводка шансов",
        "",
        "| Показатель | Значение |",
        "|---|---|",
    ]
    for c in cats:
        lines.append(f"| Шанс заклинания «{CATEGORY[c]}» | {by_cat[c] * 100:.1f} % |")
    lines += [
        f"| Средний прямой урон по цели за каст | {exp_damage:.2f} |",
        f"| Среднее лечение/щит по цели за каст | {exp_heal:.2f} |",
        "",
        "Числа — без Мудрости. Мудрость добавляет +1 к каждому урону, лечению и щиту.",
        "Урон призванных существ, ядов и болезней в среднее не входит.",
        "",
        "## Заклинания",
        "",
        "Отсортированы от самых частых к самым редким. Хаос — в конце.",
        "",
        "| Комбинация | Заклинание | Тип | Эффект | Шанс |",
        "|---|---|---|---|---|",
    ]
    for s in spells:
        lines.append(f"| {fmt_combo(s['combo'])} | **{s['name']}** | "
                     f"{CATEGORY[s['category']]} | {s['effect']} | {fmt_chance(probs[s['combo']])} |")
    lines += ["", "*Файл собран скриптом `tools/gen_spells.py` из "
              f"`data/books/{book['id']}.json`. Правьте JSON, а не этот файл.*", ""]
    return "\n".join(lines)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    failed = False
    books = []
    for path in sorted(BOOKS.glob("*.json")):
        book = json.loads(path.read_text(encoding="utf-8"))
        books.append(book)
        errors = validate(book)
        for e in errors:
            print(f"{path.name}: {e}", file=sys.stderr)
        failed |= bool(errors)
        (OUT / f"{book['id']}.md").write_text(render(book), encoding="utf-8")
        print(f"{path.name} -> docs/spells/{book['id']}.md")
    (OUT / "README.md").write_text(render_index(books), encoding="utf-8")
    print("docs/spells/README.md")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
