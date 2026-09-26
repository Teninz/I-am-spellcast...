# Я кастую (I am spellcast)

Цифровая кооперативная игра про трёх волшебников, которые колдуют из книг случайные заклинания.
Можно играть в соло, переключаясь между всеми тремя героями. 20 уровней, 100 противников.

- Дизайн-документ: [docs/GDD.md](docs/GDD.md)
- Бестиарий: [docs/enemies.md](docs/enemies.md)
- Боссы: [docs/bosses.md](docs/bosses.md)
- Банды с предводителями: [docs/gangs.md](docs/gangs.md)
- Баланс и эффекты: [docs/balance.md](docs/balance.md)
- Обмундирование: [docs/equipment.md](docs/equipment.md)
- Книги заклинаний (26 книг, таблицы и шансы): [docs/spells/README.md](docs/spells/README.md)

Таблицы книг хранятся в `data/books/*.json`. После правки пересоберите документы:

```
python3 tools/gen_spells.py
```

## Прототип в Godot

Проект Godot лежит в корне репозитория (`project.godot`) и читает книги прямо из `data/books`.
Сейчас в прототипе один бой: Пиромант, Священник и Волшебник Воды против Крысиной стаи.

![Бой с Крысиной стаей](docs/images/prototype-battle.png)

**Как запустить**
1. Скачай ветку репозитория (`git clone` или ZIP на GitHub) и распакуй.
2. Открой Godot (4.5 или новее) → **Import** → выбери `project.godot` → **Import & Edit**.
3. Нажми **F5** (Run Project).

**Как играть**
- На ходу волшебника кликни по карточке цели — врагу или союзнику.
- Жми **«Достать фишку»** три раза (или включи «Авто» — фишка раз в 2 секунды).
- Пиромант может кликнуть по вытянутой фишке, чтобы сжечь её и вытянуть новую (3 раза за бой).
- Жми **«Я кастую!»**. Заклинание сработает на выбранную цель, даже если выпало «не то».

**Структура**
- `scripts/core/` — логика боя без графики: мешочек фишек, разбор эффектов, шкала хода, ИИ врагов.
- `scripts/ui/battle_ui.gd` — экран боя (строится кодом).
- `data/classes/`, `data/encounters/` — классы и составы боёв.
- `tests/` — тесты и симулятор.

**Тесты и симулятор** (из папки проекта, `godot` — путь к исполняемому файлу Godot;
на Windows — версия с `_console.exe`):

```
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/ui_smoke.gd
godot --headless --path . --script res://tests/simulate.gd -- encounter=rat_pack n=3000
```
