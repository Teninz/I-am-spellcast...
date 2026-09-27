# Промпты: интерфейс, карточки персонажей и привал

Всё в том же стиле, что иконки эффектов, фишки и обложки книг. Первая часть стиля в каждом промпте
одинаковая — не меняй её. **Текст на картинках не нужен:** все надписи, числа и полоски здоровья
рисует сама игра (генераторы плохо пишут по-русски).

## Куда класть и размеры

| Что | Папка | Размер |
|---|---|---|
| Фоны экранов | `assets/ui/` | 1920×1080 (16:9) |
| Рамки карточек, панели, кнопки | `assets/ui/` | как указано у каждого |
| Иконки характеристик | `assets/ui/` | 256×256 |
| Расходуемые предметы | `assets/items/` | 256×256, имя — id предмета |
| Шляпы и ботинки | `assets/equipment/` | 256×256, имя — id вещи |

**Рамки и панели** делай с **пустой серединой** и узором только по краям и в углах — игра растягивает
их под любой размер (так называемый 9-slice), и середина не должна искажаться.

**Негативный промпт (для всех):**

```
text, letters, numbers, words, title, logo, watermark, signature, photorealistic, 3D render, anime, chibi, modern clothing, cropped, blurry
```

## Фоны экранов

### `bg_battle_act1.png` — Арена акта I (окраины деревни)

*Фон боя. Слева стоит отряд, справа враги, в центре — фишки и кнопки, поэтому центр спокойный.*

```
Wide 16:9 game background, 1920x1080. Muddy field on the outskirts of a small village at golden evening light: wooden fences, haystacks, a crooked windmill and cottages far in the distance, a few curious chickens. The middle of the image is calm and low in detail (UI will sit on top), the left third slightly cleaner for the heroes, the right third for the monsters. Soft dark vignette at the edges. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### `bg_camp.png` — Привал

*Фон экрана привала между уровнями.*

```
Wide 16:9 game background, 1920x1080. A cozy night camp of retired old wizards: a crackling campfire, bedrolls and patched blankets, a copper kettle and teacups, pointed wizard hats hanging on a branch, stacks of old books, a starry sky. Warm firelight in the lower middle, darker calm areas where UI panels will sit. Soft vignette. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### `bg_party_select.png` — Выбор отряда

*Фон экрана, где собирают отряд.*

```
Wide 16:9 game background, 1920x1080. The common room of a retirement home for old wizards: worn armchairs, a fireplace, towering bookshelves, a notice board with pinned papers, knitting and teacups on a table, soft lamplight. Calm and slightly dark so that character cards read well on top. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No characters, no text.
```

### `art_victory.png` — Победа

*Картинка на экране итогов после победы (512×512).*

```
Square illustration 512x512, a single scene centered: several pointed wizard hats thrown up into the air above a hill, confetti of magic sparks, a walking cane raised in triumph. Plain dark background #1b1a24 with warm glow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text.
```

### `art_defeat.png` — Поражение

*Картинка на экране итогов после поражения (512×512).*

```
Square illustration 512x512, a single scene centered: pointed wizard hats lying on the grass next to a dropped walking cane, an open spell book and a knocked-over teacup, a single sad puff of smoke. Plain dark background #1b1a24 with a cold soft glow. Melancholic but funny. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text.
```

### `emblem.png` — Эмблема игры (без надписи)

*Название «Я кастую!» игра напишет сама поверх эмблемы.*

```
Game emblem 1024x512, centered: an open old spell book with three glowing game chips (red flame, blue drop, golden sun) flying out of it, a crooked wizard hat and a walking cane crossed behind the book, magical sparks. Empty space in the middle-bottom for a title that will be added later. Plain dark background #1b1a24. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text, no letters.
```

## Карточки персонажей в бою

### `card_party.png` — Рамка карточки волшебника

*512×192. Внутри будут портрет, имя, полоска ЗД и иконки эффектов.*

```
Game UI frame 512x192 for a hero card: horizontal rectangle with a dark blue-steel border, small brass corner caps and rivets, a subtle carved pattern only along the edges, the inside is a flat dark translucent navy panel (#2d3a52) with no pattern. Suitable for 9-slice scaling. Plain transparent or dark background outside the frame. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `card_enemy.png` — Рамка карточки противника

*512×192.*

```
Game UI frame 512x192 for an enemy card: horizontal rectangle with a rusty iron border, dented corners with rough nails, the inside is a flat dark red-brown panel (#522d2d) with no pattern. Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `card_leader.png` — Рамка предводителя банды

*512×192.*

```
Game UI frame 512x192 for a gang leader enemy card: the rusty iron enemy frame with a small torn war banner on the top-left corner and golden accents, flat dark red-brown inside. Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `card_boss.png` — Рамка босса

*512×192.*

```
Game UI frame 512x192 for a boss card: heavy dark iron frame decorated with small bones and a tiny crown on the top edge, faint red glow along the border, flat very dark red inside. Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `portrait_ring.png` — Кольцо-рамка портрета в очереди ходов

*128×128, круглая, центр пустой.*

```
Round game UI frame 128x128: a carved wooden ring with a thin brass rim, completely empty transparent center for a small portrait. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

## Привал

### `card_rest.png` — Колонка волшебника на привале

*400×720, вертикальная. Внутри — ЗД, добыча и инвентарь.*

```
Tall game UI panel 400x720: an old leather-bound board with stitched edges and parchment inner area, a small campfire-and-kettle ornament on the top edge, brass corner caps, inside is a flat warm dark green-brown area (#2b3a30) without pattern. Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `loot_frame_common.png` — Рамка добычи — common

*320×480, вертикальная, центр пустой. Цвет редкости как в игре.*

```
Vertical game UI frame 320x480 for a loot card: plain worn wooden frame, dominant accent colour #b8b8b8, completely empty flat dark center (#1b1a24). Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `loot_frame_rare.png` — Рамка добычи — rare

*320×480, вертикальная, центр пустой. Цвет редкости как в игре.*

```
Vertical game UI frame 320x480 for a loot card: wooden frame with brass corner caps and a faint blue shimmer, dominant accent colour #6fa8ff, completely empty flat dark center (#1b1a24). Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `loot_frame_epic.png` — Рамка добычи — epic

*320×480, вертикальная, центр пустой. Цвет редкости как в игре.*

```
Vertical game UI frame 320x480 for a loot card: ornate silver filigree frame with small purple gems, dominant accent colour #c07dff, completely empty flat dark center (#1b1a24). Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `loot_frame_legendary.png` — Рамка добычи — legendary

*320×480, вертикальная, центр пустой. Цвет редкости как в игре.*

```
Vertical game UI frame 320x480 for a loot card: gold filigree frame with glowing orange ornaments and sparkles, dominant accent colour #ffae42, completely empty flat dark center (#1b1a24). Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `loot_frame_cursed.png` — Рамка добычи — cursed

*320×480, вертикальная, центр пустой. Цвет редкости как в игре.*

```
Vertical game UI frame 320x480 for a loot card: frame wrapped in rusty chains with red cracks glowing, dominant accent colour #ff4a4a, completely empty flat dark center (#1b1a24). Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

## Панели и кнопки

### `panel_dialog.png` — Окно «Инфо» и другие диалоги

*1024×640.*

```
Game UI dialog panel 1024x640: a dark wooden board with brass corners and a thin parchment edge, small carved book-and-quill ornaments in the corners, flat dark inner area (#24232f). Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `button.png` — Обычная кнопка

*384×96. Состояния (наведение, нажатие) игра сделает подсветкой.*

```
Game UI button 384x96: a rounded wooden plank with brass rivets at both ends and a thin dark outline, flat centre for text. Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text.
```

### `button_cast.png` — Кнопка «Я кастую!»

*512×128. Главная кнопка каста.*

```
Big game UI button 512x128: a glowing red wax-seal style button with golden rim, magical sparks at the edges, flat centre for a title. Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text.
```

### `chip_socket.png` — Ячейка для фишки

*256×256, круглая.*

```
Round game UI socket 256x256: a carved wooden round hollow with a brass ring, soft inner shadow, completely empty center where a game chip will sit. Plain dark background #1b1a24. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

### `shout_banner.png` — Лента «Я кастую!»

*1024×256. Под крупной надписью в момент каста.*

```
Game UI ribbon banner 1024x256: a curling parchment ribbon with torn ends and small magical sparks around it, empty flat centre where a big title will be written. Plain transparent or dark background. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. No text.
```

### `hp_bar_frame.png` — Рамка полоски здоровья

*512×48. Заливку игра рисует сама.*

```
Game UI health bar frame 512x48: a thin brass tube frame with rivets at both ends, completely empty dark inside for a fill bar. Suitable for 9-slice scaling. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. 
```

## Иконки характеристик

### `stat_hp.png` — Здоровье

```
Square game UI stat icon 256x256, one clear central symbol readable at 24 px: a red heart with a small knitted patch. Dominant colour #d9433b. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text, no numbers.
```

### `stat_speed.png` — Скорость

```
Square game UI stat icon 256x256, one clear central symbol readable at 24 px: an old leather boot with speed lines. Dominant colour #f0a030. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text, no numbers.
```

### `stat_wisdom.png` — Мудрость

```
Square game UI stat icon 256x256, one clear central symbol readable at 24 px: an open book with a glowing owl-feather quill. Dominant colour #7a5bd6. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text, no numbers.
```

### `stat_defense.png` — Защита

```
Square game UI stat icon 256x256, one clear central symbol readable at 24 px: a round wooden shield with a brass rim. Dominant colour #a08a6a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text, no numbers.
```

### `stat_luck.png` — Удача

```
Square game UI stat icon 256x256, one clear central symbol readable at 24 px: a four-leaf clover. Dominant colour #4fbf6a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text, no numbers.
```

### `stat_resist.png` — Сопротивление

```
Square game UI stat icon 256x256, one clear central symbol readable at 24 px: a cup of hot tea with a steam swirl shaped like a shield. Dominant colour #6fa8ff. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text, no numbers.
```

## Расходуемые предметы

### `potion_heal.png` — Зелье здоровья

*Восстанавливает 5 ЗД союзнику.*

```
Square game item icon 256x256, one object centered, readable at 32 px: a heart-shaped red potion bottle with a cork and a paper label (blank). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `scroll_resurrect.png` — Свиток воскрешения

*Поднимает выбывшего союзника с 5 ЗД.*

```
Square game item icon 256x256, one object centered, readable at 32 px: a glowing rolled scroll sealed with a phoenix-feather wax seal. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `potion_resurrect.png` — Зелье воскрешения

*Срабатывает само: когда владелец выбывает, поднимает его с 3 ЗД.*

```
Square game item icon 256x256, one object centered, readable at 32 px: a golden potion bottle with a tiny phoenix feather floating inside. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `shield_scroll.png` — Свиток щита

*Щит 4 союзнику.*

```
Square game item icon 256x256, one object centered, readable at 32 px: a half-unrolled scroll with a glowing shield emblem rising from it. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `holy_water.png` — Святая вода

*Очищение и лечение 2 союзнику.*

```
Square game item icon 256x256, one object centered, readable at 32 px: a small glass flask of holy water with a sun-halo cork. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `bomb.png` — Бомба алхимика

*3 урона противнику.*

```
Square game item icon 256x256, one object centered, readable at 32 px: a round black alchemist bomb with a sizzling fuse. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `sand_bag.png` — Мешочек с песком

*До конца боя из мешочков владельца убираются фишки Хаоса.*

```
Square game item icon 256x256, one object centered, readable at 32 px: a small burlap bag of sand next to a black game chip crossed out. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `horn.png` — Громкий рог

*Все противники 2 хода бьют только владельца (Провокация).*

```
Square game item icon 256x256, one object centered, readable at 32 px: a brass hunting horn with visible sound waves. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `double_cast.png` — Свиток «Я кастую дважды»

*В этот ход владелец кастует дважды.*

```
Square game item icon 256x256, one object centered, readable at 32 px: a scroll with two overlapping sparkling wand swooshes. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `glue.png` — Клей для переплёта

*Подклеивает все книги владельца: они снова выдержат 3 боя. Только на привале.*

```
Square game item icon 256x256, one object centered, readable at 32 px: a glue pot with a brush and a bandaged book spine. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

## Шляпы и ботинки

### `night_cap.png` — Ночной колпак

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a floppy striped nightcap with a pompom. Quality look: worn and simple. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `straw_hat.png` — Соломенная шляпа

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a battered straw hat with a daisy. Quality look: worn and simple. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `pointy_hat.png` — Остроконечный колпак

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a classic pointed wizard hat, slightly crooked. Quality look: worn and simple. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `star_cap.png` — Колпак со звёздами

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pointed cap embroidered with little stars. Quality look: good quality with brass details. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `ushanka.png` — Шапка-ушанка мага

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a fur hat with ear flaps and a small star badge. Quality look: good quality with brass details. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `ash_hat.png` — Шляпа с пеплом на полях

*Иммунитет к Горению.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a wide-brim wizard hat with ash and glowing embers on the brim. Quality look: ornate with small glowing gems. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `absent_cap.png` — Колпак рассеянного

*Раз за бой — посмотреть первую фишку до выбора цели.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a wizard hat with a pencil, a note and a spoon stuck into its band. Quality look: ornate with small glowing gems. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `seer_turban.png` — Тюрбан прорицателя

*Видит, какую способность босс использует следующей.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a turban with a small crystal-ball jewel. Quality look: ornate with small glowing gems. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `merlin_hat.png` — Шляпа Старого Мерлина

*Раз за бой — Сосредоточенность.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a very tall legendary wizard hat embroidered with moons and stars, glowing. Quality look: masterwork with gold details and a radiant glow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `bookworm_crown.png` — Корона книжного червя

*Книги владельца не рвутся.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a crown made of small bound books with a friendly worm peeking out. Quality look: masterwork with gold details and a radiant glow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `talking_hat.png` — Шляпа, которая говорит

*Подсказывает цель вслух… и 10 % врёт: каст уходит в случайную цель.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pointed hat with two eyes and a big grinning mouth. Quality look: sinister look with a faint red glow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `fool_cap.png` — Колпак дурака

*Над владельцем смеются враги: первый ход боя его бьют все.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a jester cap with bells. Quality look: sinister look with a faint red glow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `pompom_slippers.png` — Тапочки с помпонами

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of fluffy slippers with pompoms. Quality look: worn and simple. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `sandals.png` — Сандалии странника

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of worn leather traveller sandals. Quality look: worn and simple. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `felt_boots.png` — Войлочные боты

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of grey felt boots. Quality look: worn and simple. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `valenki.png` — Валенки архимага

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of patterned felt winter boots (valenki). Quality look: good quality with brass details. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `curly_shoes.png` — Туфли с загнутыми носами

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of shoes with long curled-up toes. Quality look: good quality with brass details. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `seven_league_walkers.png` — Сапоги-скороходы

*Начинает бой с шкалой хода 30 %.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of boots with springs on the soles and speed lines. Quality look: ornate with small glowing gems. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `galoshes.png` — Болотные калоши

*Иммунитет к Замедлению.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of rubber galoshes with swamp mud. Quality look: ornate with small glowing gems. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `velcro_boots.png` — Ботинки на липучках

*Нельзя Оглушить.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of chunky boots with velcro straps. Quality look: ornate with small glowing gems. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `seven_league_boots.png` — Сапоги Семи Лиг

*Ходит первым в каждом бою.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of tall legendary boots with glowing runes and a small compass buckle. Quality look: masterwork with gold details and a radiant glow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `hermit_boots.png` — Ботинки Отшельника

*Регенерация 1 первые 3 хода боя.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of moss-covered hermit boots with a tiny sprout. Quality look: masterwork with gold details and a radiant glow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `skeleton_shoes.png` — Туфли танцующего скелета

*Нельзя Оглушить, но −2 ЗД.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of bony dancing shoes with a cursed purple glow. Quality look: sinister look with a faint red glow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```

### `clogs.png` — Деревянные башмаки

*Громко топают: −2 Скорости.*

```
Square game equipment icon 256x256, one object centered, readable at 32 px: a pair of heavy wooden clogs with a cursed red glow. Quality look: sinister look with a faint red glow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Simple dark background #1b1a24 with a soft radial glow. No frame, no text.
```
