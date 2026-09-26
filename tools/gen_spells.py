#!/usr/bin/env python3
"""Проверяет таблицы книг из data/books/*.json и собирает docs/spells/*.md.

Правило вытягивания:
- в мешочке 19 фишек стихий и 1 фишка Хаоса;
- фишки тянутся по одной, всего 3 вытягивания;
- на каждом вытягивании шанс Хаоса — CHAOS_PER_CHIP за каждую фишку Хаоса;
  Хаос оставляет чёрную метку в ячейке и возвращается в мешочек;
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

CHAOS_PER_CHIP = 0.069

ICON = {"F": "🔥", "W": "💧", "H": "✨", "D": "🌑", "E": "🌿", "M": "⚙️"}
ELEMENT = {"F": "Огонь", "W": "Вода", "H": "Святость", "D": "Тьма", "E": "Земля", "M": "Механика"}
CATEGORY = {
    "damage": "Урон",
    "control": "Контроль",
    "support": "Польза",
    "summon": "Призыв",
    "disease": "Болезнь",
    "roots": "Щиты и корни",
    "glitch": "Сбой",
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
    c = CHAOS_PER_CHIP * book["bag"].get("X", 0)
    probs = {}
    for seq in itertools.product(elements(book), repeat=3):
        probs["".join(seq)] = (1 - c) ** 3 * sequence_probability(counts, seq)
    for k in (1, 2, 3):
        probs[f"X{k}"] = math.comb(3, k) * c**k * (1 - c) ** (3 - k)
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


def render(book):
    probs = combo_probabilities(book)
    spells = sorted(book["spells"], key=lambda s: (s["combo"] in CHAOS, -probs[s["combo"]], s["combo"]))
    cats = list(book["target_split"])
    by_cat = {c: 0.0 for c in cats}
    exp_damage = exp_heal = 0.0
    for s in book["spells"]:
        p = probs[s["combo"]]
        by_cat[s["category"]] += p
        exp_damage += p * s.get("damage", 0)
        exp_heal += p * (s.get("heal", 0) + s.get("shield", 0))

    bag = " · ".join(f"{ICON[k]} {ELEMENT[k]} ×{v}" for k, v in book["bag"].items() if k != "X")
    split = " · ".join(f"{CATEGORY[c]} {n}" for c, n in book["target_split"].items())
    lines = [
        f"# {book['name']}",
        "",
        f"*{book['flavor']}*",
        "",
        f"- **Класс:** {book['class']}",
        f"- **Мешочек:** {bag} · 🌀 Хаос ×1 ({CHAOS_PER_CHIP * 100:.1f} % на каждое вытягивание)",
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
