# Я кастую (I am spellcast)

Цифровая кооперативная игра про трёх волшебников, которые колдуют из книг случайные заклинания.
Можно играть в соло, переключаясь между всеми тремя героями. 20 уровней, 100 противников.

- Дизайн-документ: [docs/GDD.md](docs/GDD.md)
- Бестиарий: [docs/enemies.md](docs/enemies.md)
- Боссы: [docs/bosses.md](docs/bosses.md)
- Баланс и эффекты: [docs/balance.md](docs/balance.md)
- Обмундирование: [docs/equipment.md](docs/equipment.md)
- Таблицы заклинаний: [Огонь](docs/spells/fire.md) · [Вода](docs/spells/water.md) · [Святость](docs/spells/holy.md)

Таблицы книг хранятся в `data/books/*.json`. После правки пересоберите документы:

```
python3 tools/gen_spells.py
```
