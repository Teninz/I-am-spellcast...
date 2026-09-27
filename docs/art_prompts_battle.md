# Промпты: навыки, новые эффекты, призванные существа и фоны локаций

Всё, что нужно для понятных навыков в бою, призыва и новых фонов. Пока картинки нет, игра рисует заглушку — ничего не ломается.

## Иконки навыков классов

- **Формат:** PNG **256×256**, `assets/icons/skills/<id>.png`.
- Рамку рисует игра: у активных навыков — **золотая** (плитка нажимается), у пассивных — **серо-синяя**. На картинке — только символ, без рамки и текста.
- Описание и «как применить» берутся из `data/class_skills.json`.

**Негативный промпт (для всех иконок):**

```
text, letters, numbers, frame, border, bevel, metallic emblem, gradient badge, photorealistic, 3D render, watermark, signature, logo
```

| Файл | Класс | Навык | Вид |
|---|---|---|---|
| `burn.png` | Пиромант | Сожжение | активный |
| `pyro_ban.png` | Пиромант | Огонь не терпит воды | пассивный |
| `double_grace.png` | Священник | Двойная благодать | пассивный |
| `priest_ban.png` | Священник | Сжигает ересь | пассивный |
| `elemental_form.png` | Волшебник Воды | Элементальная форма | пассивный |
| `cane.png` | Магус с тростью | Удар тростью | пассивный |
| `two_books.png` | Магус с тростью | Лёгкий багаж | пассивный |
| `inspiration.png` | Бард-на-пенсии | Вдохновение | активный |
| `critics.png` | Бард-на-пенсии | Критики | пассивный |
| `lay_on_hands.png` | Паладин в отставке | Наложение рук | активный |
| `oath.png` | Паладин в отставке | Клятва | пассивный |
| `beast_call.png` | Друид | Зов зверя | активный |
| `grumble.png` | Друид | Ворчун | пассивный |
| `raise_dead.png` | Некромант | Поднятие | активный |
| `unholy.png` | Некромант | Святость наоборот | пассивный |
| `workshop.png` | Учёный | Мастерская | активный |
| `unscientific.png` | Учёный | «Это ненаучно!» | пассивный |
| `visions.png` | Прорицатель | Видения | активный |
| `foresaw.png` | Прорицатель | «Я это предвидел» | пассивный |
| `decoy.png` | Иллюзионист | Двойник | активный |
| `not_real.png` | Иллюзионист | «Всё не по-настоящему» | пассивный |
| `surge.png` | Дикий маг | Всплеск | активный |
| `chaos_bag.png` | Дикий маг | Хаос в карманах | пассивный |
| `pact_deal.png` | Чернокнижник | Сделка | активный |
| `hungry_patron.png` | Чернокнижник | Покровитель голоден | пассивный |
| `mix.png` | Алхимик | Смешать | активный |
| `unstable.png` | Алхимик | Нестабильная смесь | пассивный |
| `rewind.png` | Хрономант | Перемотка | активный |
| `old_age.png` | Хрономант | Старость | пассивный |
| `revelation.png` | Оракул | Откровение | пассивный |
| `oracle_curse.png` | Оракул | Проклятие Оракула | пассивный |

### Пиромант — Сожжение · `assets/icons/skills/burn.png`

*3 раза за бой: сжечь вытянутую фишку и вытянуть вместо неё новую.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: an old wizard's gnarled hand tossing a glowing element chip into a small flame, the chip crumbling to ash. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Пиромант — Огонь не терпит воды · `assets/icons/skills/pyro_ban.png`

*Не может пользоваться Книгой Воды — её нужно отдать или выбросить.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a blue water-book cover with a scorch mark and a small red 'no' circle made of flame. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Священник — Двойная благодать · `assets/icons/skills/double_grace.png`

*Лечение союзника с шансом 5 % срабатывает дважды.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: two overlapping golden healing sparkles above an open prayer book, like an echo. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Священник — Сжигает ересь · `assets/icons/skills/priest_ban.png`

*Уничтожает Некрономикон, если тот попадает к нему.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a dark skull-bound book crumbling into holy golden light. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Волшебник Воды — Элементальная форма · `assets/icons/skills/elemental_form.png`

*20 %: любой урон, кроме огня, проходит сквозь него.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: an old wizard's silhouette dissolving into splashing water, an arrow passing through him. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Магус с тростью — Удар тростью · `assets/icons/skills/cane.png`

*Если каст по противнику не нанёс урона, Магус добивает его тростью на 1.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a knobbly wooden walking cane swinging with a comic 'bonk' impact star. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Магус с тростью — Лёгкий багаж · `assets/icons/skills/two_books.png`

*Носит только 2 книги.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a small leather satchel holding exactly two spell books, neatly strapped. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Бард-на-пенсии — Вдохновение · `assets/icons/skills/inspiration.png`

*2 раза за бой: союзник получает Музу — может перевытянуть одну фишку.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a lute with a tiny winged muse spark rising from its strings. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Бард-на-пенсии — Критики · `assets/icons/skills/critics.png`

*10 %: баллада фальшивая — весь отряд Замедлен на 1 ход.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a squashed tomato hitting a music sheet with sour notes. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Паладин в отставке — Наложение рук · `assets/icons/skills/lay_on_hands.png`

*Запас 5 лечения на бой, раздаётся союзникам в свой ход, ход не тратится.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: two wrinkled glowing hands held over a heart, warm golden light. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Паладин в отставке — Клятва · `assets/icons/skills/oath.png`

*Если каст ранил союзника, запас Наложения рук сгорает до конца боя.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a paladin's oath scroll with a wax seal, a crack running through it. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Друид — Зов зверя · `assets/icons/skills/beast_call.png`

*2 раза за бой, когда тройка вытянута: медведь перевытягивает все 3 фишки и кусает цель, заяц меняет одну фишку, ворон ослепляет цель, кошка лечит её на 1.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a wooden druid whistle with a bear, hare, raven and cat silhouettes curling out of it as smoke. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Друид — Ворчун · `assets/icons/skills/grumble.png`

*Не берёт Книгу Огня и ворчит на огненную магию.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a grumpy bearded face puffing a storm cloud at a small campfire. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Некромант — Поднятие · `assets/icons/skills/raise_dead.png`

*1 раз за бой поднимает выбывшего союзника зомби (6 ЗД). Зомби теряет одну книгу навсегда.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a skeletal hand bursting out of a grave mound with green necromantic wisps. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Некромант — Святость наоборот · `assets/icons/skills/unholy.png`

*Книга Святости у него в 50 % срабатывает наоборот.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a holy sun symbol turned upside down, half gold half sickly green. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Учёный — Мастерская · `assets/icons/skills/workshop.png`

*2 раза за бой вместо каста: овца (2 урона, Щит 1), пугало (Провокация, Щит 2) или стальной волк (2 урона, Провокация).*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a tiny clockwork sheep with a wind-up key and brass gears. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Учёный — «Это ненаучно!» · `assets/icons/skills/unscientific.png`

*Из обычных книг 5 % — заклинание не срабатывает, 5 % — наоборот. Овца ломается от Хаоса II/III.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a pair of round spectacles with a raised eyebrow and a question mark made of smoke. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Прорицатель — Видения · `assets/icons/skills/visions.png`

*В начале боя видит 2 тройки; дважды за бой любой волшебник может заменить свою тройку видением.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a crystal ball showing three element chips floating inside. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Прорицатель — «Я это предвидел» · `assets/icons/skills/foresaw.png`

*Хаос II и III в его руках задевают и его самого.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: an eye with a spiral chaos chip in the pupil, lightning cracks around it. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Иллюзионист — Двойник · `assets/icons/skills/decoy.png`

*1 раз за бой: иллюзорная копия союзника принимает следующий удар.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a wizard and his translucent shimmering copy side by side. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Иллюзионист — «Всё не по-настоящему» · `assets/icons/skills/not_real.png`

*10 % его лечений иллюзорны и исчезают через 2 хода.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a healing heart made of fading dotted outlines, half transparent. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Дикий маг — Всплеск · `assets/icons/skills/surge.png`

*1 раз за бой нарочно превращает фишку своей тройки в Хаос.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: an element chip cracking open into a purple chaos spiral. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Дикий маг — Хаос в карманах · `assets/icons/skills/chaos_bag.png`

*Во всех его мешочках на 2 фишки Хаоса больше.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a patched chip bag overflowing with purple chaos chips. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Чернокнижник — Сделка · `assets/icons/skills/pact_deal.png`

*Перед вытягиванием фишки отдаёт 2 ЗД и выбирает фишку сам.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a quill signing a contract with a drop of blood, a chip chosen on the parchment. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Чернокнижник — Покровитель голоден · `assets/icons/skills/hungry_patron.png`

*После каждого босса теряет 1 макс. ЗД или свой предмет.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a shadowy horned patron's mouth nibbling a heart-shaped health gem. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Алхимик — Смешать · `assets/icons/skills/mix.png`

*Носит 2 предмета; на привале смешивает два в один более редкий.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: two potion flasks pouring into one bigger bubbling rare flask. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Алхимик — Нестабильная смесь · `assets/icons/skills/unstable.png`

*5 %: предмет взрывается в руках (2 урона ему и соседу).*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a potion flask cracking with a small comic explosion puff. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Хрономант — Перемотка · `assets/icons/skills/rewind.png`

*1 раз за бой отменяет неудачный каст любого волшебника — тот кастует заново.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: an hourglass flipping backwards with a curved arrow around it. This is a active ability — feels like a button to press, a bit brighter. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Хрономант — Старость · `assets/icons/skills/old_age.png`

*−3 Скорости.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a slow snail wearing a tiny wizard hat and spectacles. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Оракул — Откровение · `assets/icons/skills/revelation.png`

*Каждые 5 пройденных уровней — +1 Мудрость.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: an open third eye on a wise wrinkled forehead, stars around it. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Оракул — Проклятие Оракула · `assets/icons/skills/oracle_curse.png`

*С начала приключения носит случайный шрам босса, его нельзя снять.*

```
Square game ability icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a claw-mark scar glowing on an old parchment, chained with a padlock. This is a passive trait — calmer, like a seal or emblem. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

## Иконки новых эффектов

Как остальные эффекты (`docs/icon_prompts.md`): PNG 256×256, `assets/icons/status/<id>.png`, рамку и числа рисует игра.

### Призванное существо — `assets/icons/status/creature.png`

```
Square game status effect icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a paw print and a skull print side by side inside a summoning circle. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Кровная связь — `assets/icons/status/bond.png`

```
Square game status effect icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: two hearts joined by a thin red thread. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Преломление — `assets/icons/status/shared_pain.png`

```
Square game status effect icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a crystal prism splitting one red lightning bolt into several thin ones. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Кармический долг — `assets/icons/status/doom.png`

```
Square game status effect icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a heavy iron weight with a karmic swirl, dangling over a head. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Дурной знак — `assets/icons/status/misdirect.png`

```
Square game status effect icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a black cat crossing a cracked arrow that bends away. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Зеркальная ловушка — `assets/icons/status/self_trap.png`

```
Square game status effect icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a hand mirror with a fist punching out of it back at the viewer. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Колесо фортуны — `assets/icons/status/miss.png`

```
Square game status effect icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: a small wooden fortune wheel with a spinning pointer. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

### Двойник заклинания — `assets/icons/status/echo_next.png`

```
Square game status effect icon, 256x256, a single bold symbol centered on a plain dark background #1b1a24 with a soft glow, readable at 32 px. Symbol: two identical spell sparks, one a ghostly echo of the other. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no frame.
```

## Портреты призванных существ

- Как портреты врагов (`docs/art_prompts_enemies.md`): вертикальный 3:4, **768×1024**, голова и плечи в верхней половине.
- Существо может встать на любую сторону, поэтому смотрит **прямо на зрителя в три четверти**, без поворота влево или вправо.
- Звери Бестиария, у которых уже есть портрет врага (Волк-переросток, Кусачий гриб и т. д.), используют его — новые нужны только ниже.
- Куда класть: `assets/enemies/<файл>.png`.

### Скелет — `assets/enemies/creature_skeleton.png`

*Разваливается и собирается один раз за бой.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a clattering skeleton in a torn wizard-school robe, loose jaw grinning, bones held with string. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Костяной пёс — `assets/enemies/creature_bone_dog.png`

*Быстрый и кусачий.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a skeletal hound with glowing green eye sockets, wagging bony tail. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Зомби-утопленник — `assets/enemies/creature_drowned.png`

*Провокация: враги бьют его первым.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a bloated drowned zombie with seaweed hair and a bucket on its head, dripping water. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Призрак — `assets/enemies/creature_ghost.png`

*Невидим в первый ход, игнорирует Щиты.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a wispy translucent ghost of an old man in a nightcap, grumpy face. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Медведь — `assets/enemies/creature_bear.png`

*Провокация: враги бьют его первым.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a huge brown bear standing tall, moss on its fur, protective roar. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Волк — `assets/enemies/creature_wolf.png`

*Атакует дважды, если цель ранена.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a lean grey forest wolf with a wild mane, bared fangs. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Олень — `assets/enemies/creature_deer.png`

*Лечит союзника с наименьшим здоровьем на 1 каждый ход.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a gentle stag with flowering antlers, soft healing glow on its muzzle. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Кабан — `assets/enemies/creature_boar.png`

*Бьёт раз в 2 хода.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a stocky wild boar with curved tusks, snorting. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Змея — `assets/enemies/creature_snake.png`

*Удар накладывает Яд.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a green forest snake coiled, venom dripping from fangs. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Барсук — `assets/enemies/creature_badger.png`

*Не боится Яда.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a tough striped badger with a scarf, fists raised. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Ёж — `assets/enemies/creature_hedgehog.png`

*Кто его бьёт, получает 1 урон.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a round hedgehog with bristling needles, determined face. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Сова — `assets/enemies/creature_owl.png`

*Снимает Невидимость с врагов, хозяина нельзя Ослепить.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a wise horned owl with round spectacles, huge amber eyes. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Рой пчёл — `assets/enemies/creature_bees.png`

*Бьёт всех на стороне цели.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a buzzing swarm of fat bumblebees forming an angry face. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Скелет-недоучка — `assets/enemies/creature_skeleton_novice.png`

*Собирается один раз после гибели.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a clumsy apprentice skeleton holding an upside-down textbook, a dunce cap. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Ведьмина кошка — `assets/enemies/creature_witch_cat.png`

*Удар накладывает Путаницу.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: a scruffy black witch cat with mismatched glowing eyes and a tiny pointed hat. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

### Рой ос — `assets/enemies/creature_wasps.png`

*Бьёт всех на стороне цели.*

```
Game creature card art, vertical 3:4 image, 768x1024 px, a single summoned creature, three-quarter view facing the viewer, the face clearly visible in the upper half. Creature: an angry swarm of striped wasps shaped like an arrowhead. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the creature. No text, no frame.
```

## Фоны локаций

- **Формат:** 16:9, **1920×1080**, `assets/ui/<файл>.png`.
- У каждой встречи свой фон боя: `bg_battle_<id встречи>.png`. Пока его нет, берётся общий `bg_battle_act1.png`.
- **Главное правило после отзывов:** без оранжевого зарева и красного заката на всю картинку, без белёсой дымки. Свет нейтральный или прохладный, середина спокойная и тёмная, чтобы карточки и лица читались. Игра дополнительно слегка приглушает фон.

**Негативный промпт (для всех фонов):**

```
text, letters, characters, people, animals in foreground, orange colour cast, red sky, sunset glow, heavy fog, white haze, bloom, lens flare, photorealistic, 3D render, watermark, signature
```

### Крысиная стая — `assets/ui/bg_battle_rat_pack.png`

```
Wide 16:9 game battle background, 1920x1080. a dusty village granary and barn interior at dusk: sacks of grain, gnawed cheese wheels, wooden beams, cool blue moonlight through a hatch. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Гоблинская шайка — `assets/ui/bg_battle_goblin_gang.png`

```
Wide 16:9 game battle background, 1920x1080. a goblin junkyard by an old quarry: piles of broken pots and crates, a rickety scaffold, overcast grey-green daylight. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Разбойники с большой дороги — `assets/ui/bg_battle_bandits.png`

```
Wide 16:9 game battle background, 1920x1080. a narrow forest road with a fallen tree blocking it, a broken cart wheel, tall dark pines, cool morning light. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Кобольдова артель — `assets/ui/bg_battle_kobold_crew.png`

```
Wide 16:9 game battle background, 1920x1080. the entrance to a small kobold mine in a hillside: wooden supports, mine carts on rails, lanterns with soft greenish light, stone walls. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Гусиная банда — `assets/ui/bg_battle_geese_gang.png`

```
Wide 16:9 game battle background, 1920x1080. a village pond with reeds and a little wooden bridge, scattered feathers, overcast soft daylight, cool blue-green water. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Звери с опушки — `assets/ui/bg_battle_wild_beasts.png`

```
Wide 16:9 game battle background, 1920x1080. the edge of a deep forest next to a field: old oaks, a mossy fence, tall grass, soft cloudy daylight (replaces the orange sunset version). The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Грибная поляна — `assets/ui/bg_battle_mushroom_ring.png`

```
Wide 16:9 game battle background, 1920x1080. a mossy forest glade with a big ring of spotted toadstools, faint violet bioluminescent spores, deep teal shadows. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Крысиный Король (босс) — `assets/ui/bg_battle_rat_king.png`

```
Wide 16:9 game battle background, 1920x1080. the rat king's cellar lair under the village: a throne of junk and cheese rinds, stone arches, candle stubs with small cool flames, dark blue shadows. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Гоблинский Вождь на Свинье (босс) — `assets/ui/bg_battle_goblin_chief.png`

```
Wide 16:9 game battle background, 1920x1080. a goblin war camp of patched tents and spiky wooden palisades, a trough for the war pig, grey cloudy sky. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Матушка-Слизь (босс) — `assets/ui/bg_battle_mother_slime.png`

```
Wide 16:9 game battle background, 1920x1080. a sewer cistern under the old town: slimy green puddles, brick arches, dripping pipes, muted green-teal light. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Одноглазый Бо (босс) — `assets/ui/bg_battle_one_eyed_bo.png`

```
Wide 16:9 game battle background, 1920x1080. a bandit hideout in a ruined watchtower: stolen chests, tattered banners, a map pinned with a dagger, cool dusk light. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Гусь-Патриарх (босс) — `assets/ui/bg_battle_goose_patriarch.png`

```
Wide 16:9 game battle background, 1920x1080. a farmyard ruled by geese: a huge straw nest like a throne on a hay cart, a royal feather banner, pale overcast morning light. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with neutral or cool light, mid-dark values; NO orange or red colour cast over the whole image, no bright sunset glow, no fog or white haze. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Привал — `assets/ui/bg_camp.png`

```
Wide 16:9 game background, 1920x1080. A night camp of retired old wizards in a forest clearing: a small campfire kept low in the lower middle, bedrolls, a copper kettle and teacups, wizard hats on a branch, stacks of old books, a starry deep-blue sky. The fire light stays small and local; the rest of the scene is cool blue night. Calm, low-detail middle for UI panels. Muted palette, no orange cast, no haze. Soft dark vignette. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Карта похода — `assets/ui/bg_map.png`

```
Wide 16:9 game background, 1920x1080. A top-down old parchment map of the village outskirts and forest, drawn in ink with small doodles of a windmill, a pond, a mine and a ruined tower, coffee stains and wizard notes in the margins (no readable text), muted beige and faded green. Calm, low-detail middle for UI panels. Muted palette, no orange cast, no haze. Soft dark vignette. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### Выбор отряда — `assets/ui/bg_party_select.png`

```
Wide 16:9 game background, 1920x1080. The cozy common room of a retirement home for wizards: armchairs, bookshelves, a cold fireplace with a sleeping cat, moonlight through a round window, calm muted colours. Calm, low-detail middle for UI panels. Muted palette, no orange cast, no haze. Soft dark vignette. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```
