# Промпты: фишки стихий и книги заклинаний

Тот же стиль, что у иконок эффектов (сказочная книжка, чернильный контур), чтобы весь визуал был единым.
Первая часть каждого промпта — одинаковая: не меняй её, иначе набор разъедется по стилю.

## Куда класть файлы

| Что | Папка | Размер | Имя файла |
|---|---|---|---|
| Фишки стихий и Хаоса | `assets/chips/` | 256×256 | из заголовка, например `fire.png` |
| Рубашка фишки, мешочек | `assets/chips/` | 256×256 / 512×512 | `chip_back.png`, `bag.png` |
| Обложки книг | `assets/books/` | 512×768 (2:3) | id книги, например `fire.png` |

Загрузка — как с иконками: GitHub → ветка `claude/three-mages-cooperative-game-p8wdyz` → нужная папка →
**Add file → Upload files** → **Commit changes**. После загрузки я сначала посмотрю картинки и только потом подключу.

## Как это будет выглядеть в игре

- **Фишки** заменят цветные кружки в трёх ячейках каста. Игра обрежет картинку по кругу, поэтому фон вокруг жетона
  может быть любым тёмным. Пустая ячейка — рубашка фишки; над ячейками — мешочек.
- **Обложки книг** появятся на кнопках выбора книги, в инвентаре и в добыче на привале. Название книги игра
  пишет сама, поэтому на обложке текста быть не должно.
- **Редкость видна по отделке обложки**: обычная — потёртая кожа, редкая — латунь, эпическая — самоцветы,
  легендарная — золото и сияние, проклятая — цепи и красное свечение.

**Негативный промпт (для всех):**

```
text, letters, numbers, title, words, runes that look like letters, watermark, signature, logo, photorealistic, 3D render, metallic bevel badge, frame, border, multiple objects, cropped object
```

## Фишки стихий

Буква в скобках — обозначение стихии в данных игры (`data/books/*.json`).

### `fire.png` — Огонь (F)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: a stylised flame emblem in ember-red and orange enamel. Dominant colour #d9502e. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `water.png` — Вода (W)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: a water droplet with a curling wave inside, deep blue enamel. Dominant colour #3b82d6. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `holy.png` — Святость (H)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: a radiant sunburst with a small halo, gold and cream enamel. Dominant colour #e8c547. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `dark.png` — Тьма (D)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: a crescent moon being swallowed by curling black smoke, dark purple enamel. Dominant colour #5b3a7a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `earth.png` — Земля (E)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: an oak leaf lying on a round pebble, moss green and brown enamel. Dominant colour #4f9a3a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `mechanic.png` — Механика (M)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: a brass cogwheel with a small puff of steam, copper and steel. Dominant colour #8a8f98. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `sound.png` — Звук (S)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: a musical note surrounded by sound rings, pink-magenta enamel. Dominant colour #d46fb0. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `mystery.png` — Тайна (T)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: an eye inside a small crystal ball with tiny stars, violet enamel. Dominant colour #7a5bd6. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `illusion.png` — Иллюзия (I)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: a spiral mirage with a faint mask outline, shimmering teal enamel. Dominant colour #5fc9c9. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `lightning.png` — Молния (L)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: a zigzag lightning bolt, bright yellow on dark blue enamel. Dominant colour #f0e04a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `time.png` — Время (C)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: an hourglass with falling sand, bronze and amber enamel. Dominant colour #b08a5a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `ice.png` — Лёд (K)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: a six-pointed snowflake crystal, icy pale blue enamel with frost on the rim. Dominant colour #a8e0f5. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `air.png` — Воздух (A)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: three swirling wind lines around a small feather, mint and white enamel. Dominant colour #c9e8d0. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `chaos.png` — Хаос (чёрная метка) (X)

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: a jet-black glossy token, cracked, with a jagged white swirl mark, faint purple sparks escaping from the cracks (it is the ominous 'black mark' chip). Dominant colour #111111. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

## Рубашка фишки и мешочек

### `chip_back.png` — Рубашка фишки

*Пустая ячейка до вытягивания фишки.*

```
Game token for a board-game style UI, 256x256 px, viewed straight from the front. A thick round token like a big chunky poker chip with a raised rim and small notches on the edge; the token fills 90% of the canvas and is perfectly centered and circular. The face shows: the back side of the tokens: dark polished walnut wood with a small embossed pointed wizard hat in the middle. Dominant colour #5a4632. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain flat dark background #1b1a24 around the token (it will be cut to a circle in game). No text, no letters, no numbers.
```

### `bag.png` — Мешочек с фишками

*Мешочек, из которого тянут фишки (над ячейками на экране каста).*

```
Game UI illustration, 512x512 px, a single object centered: a patched velvet drawstring pouch embroidered with little stars, slightly open, a few colourful round game tokens peeking out of the top, one black cracked token among them. Dominant colour #5a3a6a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the pouch. No text, no letters, no numbers.
```

## Обложки книг

### `cookbook.png` — Бабушкина поваренная книга

*Обычная · без класса. Рецепты на полях дописаны тремя поколениями. Пахнет пирожками.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: grandma's cookbook with a red-and-white checkered cloth cover, flour dust, recipe cards sticking out, a wooden spoon tucked in. Rarity look: worn plain leather cover, simple stitching, scuffed corners. Dominant colour #d9502e. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `ice.png` — Книга Льда

*Обычная · без класса. Холодная на ощупь даже летом. Чернила замёрзли на середине фразы.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: frosted book covered in hoarfrost, icicles hanging from the bottom edge, a snowflake emblem. Rarity look: worn plain leather cover, simple stitching, scuffed corners. Dominant colour #a8e0f5. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `storm.png` — Книга Молний

*Обычная · без класса. Обложка слегка бьёт током. Страницы стоят дыбом.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: cover crackling with static electricity, pages standing on end, a lightning bolt emblem. Rarity look: worn plain leather cover, simple stitching, scuffed corners. Dominant colour #f0e04a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `bestiary.png` — Бестиарий

*Редкая · без класса. Энциклопедия чудовищ. Если открыть не на той странице, чудовище выходит погулять.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: monster encyclopedia with claw marks across the cover, a small furry tail sticking out of the pages, a paw print. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #4f9a3a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `wind.png` — Книга Ветров

*Редкая · без класса. Страницы перелистываются сами, особенно у открытого окна.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: pale mint cover with pages fluttering open in the wind, a feather and swirling wind lines. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #c9e8d0. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `guild.png` — Устав Гильдии Магов

*Редкая · без класса. Тысяча страниц правил, форм и печатей. Магия в нём тоже есть — бюрократическая.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: enormously thick bureaucratic tome covered in wax seals, rubber stamps and ribbons, paper forms sticking out everywhere. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #7a5bd6. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `mirror.png` — Книга Зеркал

*Эпическая · без класса. Вместо страниц — тонкие зеркала. В них отражается не совсем тот, кто читает.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: cover that is an ornate silver mirror in a carved frame, reflecting a slightly different grumpy old wizard. Rarity look: ornate cover with inlaid softly glowing gems and silver filigree, soft purple aura. Dominant colour #5fc9c9. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `blood.png` — Книга Крови

*Эпическая · без класса. Страницы склеились от засохшего. Лучше не спрашивать, от чего.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: crimson cover with a heart emblem, pages stuck together with dried red ink, a single drop about to fall (not gory). Rarity look: ornate cover with inlaid softly glowing gems and silver filigree, soft purple aura. Dominant colour #5b3a7a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `archmage.png` — Гримуар Архимага

*Легендарная · без класса. Личный гримуар великого архимага. На форзаце: «Если нашёл — верни. Или не возвращай, я всё равно умер».*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: grand personal grimoire of a great archmage with a star-and-sun emblem and small floating sparks around it. Rarity look: masterwork cover with gold filigree and glowing ornaments, radiant warm orange aura. Dominant colour #d9502e. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `deadtongue.png` — Книга Мёртвого Языка

*Проклятая · без класса. Написана на языке, на котором никто не говорит уже тысячу лет. Потому что все, кто говорил, умерли.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: ancient black book with a grey stone cover and an emblem of a stitched-shut mouth, faint whispering wisps rising. Rarity look: cover bound with rusty chains, dripping dark ink, faint red glow leaking from inside. Dominant colour #5b3a7a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `water.png` — Книга Воды

*Обычная · Волшебник Воды. Разбухший от сырости том. Страницы никогда не высыхают до конца.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: water-swollen blue-green leather, damp wavy pages, droplets running down, a wave emblem, a small puddle under the book. Rarity look: worn plain leather cover, simple stitching, scuffed corners. Dominant colour #3b82d6. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `fire.png` — Книга Огня

*Обычная · Пиромант. Закопчённый том с обугленными закладками. Пахнет шашлыком.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: sooty scorched leather with charred bookmarks sticking out, a flame emblem burnt into the cover, a thin curl of smoke. Rarity look: worn plain leather cover, simple stitching, scuffed corners. Dominant colour #d9502e. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `holy.png` — Книга Святости

*Обычная · Священник. Тяжёлый том в золотом окладе. Между страниц засушены цветы с чьих-то похорон.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: heavy book in a gilded metal frame with a sunburst-and-halo emblem, dried flowers pressed between the pages. Rarity look: worn plain leather cover, simple stitching, scuffed corners. Dominant colour #e8c547. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `pact.png` — Договор с Покровителем

*Редкая · Чернокнижник. Книга подписана кровью. Мелкий шрифт в конце занимает сорок страниц.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: black book sealed with a red wax seal, a very long contract ribbon of tiny unreadable fine print hanging out. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #5b3a7a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `oath.png` — Клятвенный кодекс

*Редкая · Паладин в отставке. Свод обетов с пометками «уже не актуально» напротив половины пунктов.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: stern white leather book with a shield-shaped clasp and a sword emblem, several bookmarks with crossed-out marks. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #e8c547. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `druid.png` — Книга Друида

*Редкая · Друид. Между страниц растёт мох. Из корешка торчит жёлудь, который никто не решается вынуть.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: cover made of tree bark with moss growing on it, an acorn stuck in the spine, a few leaves and a tiny snail. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #4f9a3a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `illusion.png` — Книга Миражей

*Редкая · Иллюзионист. Если смотреть на эту книгу долго, она притворяется другой книгой.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: cover that shimmers and seems doubled, a swirl of teal mirage, one corner of the book fading into mist. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #5fc9c9. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `mystery.png` — Книга Тайн

*Редкая · Оракул. Текст проступает, только когда читающий чем-то проклят. Оракулу повезло.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: closed-eye emblem above a keyhole lock, deep purple shadows swirling around the book. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #7a5bd6. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `sheep.png` — Механическая овца

*Редкая · Учёный. Паровая овца на заклёпках. Блеет через свисток, пахнет машинным маслом.*

Это не книга, а механическая овца Учёного — поэтому промпт другой.

```
Game UI illustration, vertical 2:3 image, 512x768 px, a single figure centered: a steampunk mechanical sheep made of riveted copper plates, its wool made of coiled springs, a brass steam whistle on its head, big round glass eyes, standing on four little pistons, a puff of steam. Rarity look: good brass details, faint blue shimmer. Dominant colour #8a8f98. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind it. No text, no letters, no numbers.
```

### `necronomicon.png` — Некрономикон

*Редкая · Некромант. Переплёт из чего-то подозрительно мягкого. Иногда страницы переворачиваются сами.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: suspiciously soft pale leather with stitched seams, a skull-shaped bone clasp, one page lifting by itself. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #5b3a7a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `wild.png` — Растрёпанный гримуар

*Редкая · Дикий маг. Страницы вшиты в случайном порядке, часть — вверх ногами. Одна страница из другой книги.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: messy grimoire with pages sewn in at random, some sticking out upside down, a stray page from another book, small lightning crackles. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #d9502e. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `alchemy.png` — Рецептурник

*Редкая · Алхимик. Книга в пятнах всех цветов. Некоторые пятна до сих пор шипят.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: recipe book stained with colourful splashes, some stains still fizzing, a small corked vial tied to the spine. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #3b82d6. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `bard.png` — Сборник баллад

*Редкая · Бард-на-пенсии. Потрёпанный песенник с нотами на полях. Половина песен — про то, как автор был молод.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: battered songbook with a lute-shaped clasp, musical notes doodled on the leather, a feather quill tucked in. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #d46fb0. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `blade.png` — Трактат о клинке и слове

*Редкая · Магус с тростью. Учебник фехтования для магов. На полях — схемы ударов тростью.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: fencing manual for wizards, emblem of a walking cane crossed with a rapier, lightning scratches on the leather. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #f0e04a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `seer.png` — Хрустальный альманах

*Редкая · Прорицатель. Альманах с прогнозами на сто лет вперёд. Сбылись пока только прогнозы погоды.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: almanac with a small crystal ball set into the cover and star-chart constellations drawn around it. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #7a5bd6. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```

### `chrono.png` — Часослов

*Редкая · Хрономант. Книга тикает. Закладка — минутная стрелка от чьих-то часов.*

```
Front cover of a single closed old spellbook, standing upright, seen straight from the front with a hint of the spine on the left. Vertical 2:3 image, 512x768 px, the book fills about 85% of the height and is centered. Cover design: a clock face set into the cover, a minute hand used as a bookmark, small brass gears on the corners. Rarity look: good leather cover with brass corner caps and a brass clasp, faint blue shimmer. Dominant colour #b08a5a. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons. Plain dark background #1b1a24 with a soft radial glow behind the book. No title, no text, no letters on the cover (the game writes the name).
```
