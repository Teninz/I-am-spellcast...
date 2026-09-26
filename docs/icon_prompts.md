# Промпты для иконок эффектов

Иконки показываются на карточках в бою, на привале и в окне «Инфо».
Рамку по типу эффекта (красная — дебафф, зелёная — бафф, золотая — особое) и числа
(ходы, остаток Щита, стаки яда) **рисует сама игра**. Поэтому на картинке нужен только символ,
без рамки и цифр.

## Как сгенерировать и подключить

1. Сгенерируй картинку по промпту ниже (подходят Midjourney, DALL·E, Stable Diffusion, Leonardo и т. п.).
   Если генератор поддерживает негативный промпт — добавь его.
2. Сохрани как **PNG 256×256** с именем из заголовка: `assets/icons/status/<id>.png`
   (например `assets/icons/status/burn.png`).
3. Открой проект в Godot — картинка импортируется сама, и игра начнёт показывать её вместо заглушки.
   Код менять не нужно.

## Чтобы иконки были своими, а не копией Raid

- Стиль — **рисованная сказочная книжка с чернильным контуром**, а не металлические эмблемы с градиентом.
- Символы — **наши мотивы**: старики, бороды, шляпы, очки, трости, книги, фишки из мешочка.
- Рамки и цвета — наша палитра, рамку добавляет игра.
- Не давай генератору иконки из Raid как референс.
- Держи во всех промптах одинаковую первую часть (стиль), чтобы набор выглядел единым.

**Негативный промпт (для всех):**

```
text, letters, numbers, frame, border, bevel, metallic emblem, gradient badge, photorealistic, 3D render, watermark, signature, logo, copy of existing game icons
```

## Дебаффы

### `burn.png` — Горение

*1 урон в начале каждого хода. Снимается заклинаниями воды и Очищением.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: the tip of a long grey wizard beard catching fire, small orange flames and a curl of smoke. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #d9502e. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `poison.png` — Яд

*1 урон в начале хода за каждый стак (до 3 стаков).*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a cracked green potion vial leaking bubbling green ooze, one bubble shaped like a tiny skull. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #5fa83a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `stun.png` — Оглушение

*Пропускает ход. Боссы и предводители вместо этого теряют 50 % шкалы хода.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a crooked pointed wizard hat knocked sideways, three little stars and a swirl spinning above it. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #e8c547. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `slow.png` — Замедление

*Скорость −30 %: ходит реже.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a snail carrying a small stack of old books on its shell instead of a house. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #5b8fd6. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `aching.png` — Разбитость

*После воскрешения: скорость −25 % на 10 ходов (переходит в следующий бой). Снимается любым положительным эффектом: лечением, щитом, баффом или Очищением.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a wooden walking cane crossed with a rubber hot-water bottle, a small sticking plaster on the cane. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #8a7a6a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `vulnerable.png` — Уязвимость

*Каждый удар по цели наносит +1 урон.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a cracked round wooden shield with a red bullseye target painted in the middle. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #d9433b. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `weak.png` — Слабость

*Заклинания −1 к урону, лечению и щиту; у противника атака −1.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a magic wand drooping and bent like a wilted flower, a few dim sparks falling from its tip. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #9a6ad6. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `fear.png` — Страх

*Нельзя выбрать целью того, кто напугал.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: two wide frightened eyes and a sweat drop peeking out from under the brim of a wizard hat. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #6a4a8a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `blind.png` — Ослепление

*Волшебник кастует в случайную цель из случайной книги; противник бьёт случайную цель.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a pair of old round spectacles with both lenses cracked and shattered. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #444444. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `disease.png` — Болезнь

*Любое лечение цели вдвое слабее.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a sickly green thermometer with small round germ blobs floating around it. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #8aa84a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `confusion.png` — Путаница

*Волшебник: фишки перемешиваются. Противник: 50 % ударить случайную цель.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a tangled ball of yarn with question marks spiralling out of it. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #c96fb0. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `charm.png` — Очарование

*Следующий каст или атака уходит в собственного союзника.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a pink heart with a hypnotic spiral inside it, a small wand tapping it. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #e86fa0. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `forget.png` — Забывчивость

*Одна книга недоступна. Противник не может использовать особые атаки.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: an open book with blank pages, the last few letters drifting away like dust. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #8a8f98. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `chaos_curse.png` — Проклятие Хаоса

*В мешочках +2 фишки Хаоса. У противника 25 % ударить случайную цель.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a round black game chip with a jagged white swirl mark, cracked, spitting purple sparks. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #222222. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `petrify.png` — Окаменение

*Пропускает ход, но Защита +3.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: an old wizard's pointed boot turned to grey stone, with cracks and a few pebbles. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #8a8a7a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `toad.png` — Жаба

*Не кастует. Первый удар по жабе двойной и расколдовывает.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a grumpy green toad wearing a tiny wizard hat and round spectacles. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #4f9a3a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

## Баффы

### `regen.png` — Регенерация

*Восстанавливает 1 ЗД в начале каждого хода.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a green sprout with two leaves growing out of a heart-shaped seed, soft healing glow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #4fbf6a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `haste.png` — Ускорение

*Скорость +30 %: ходит чаще.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a worn leather boot with small feathered wings on the heel and motion lines. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #f0a030. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `invisible.png` — Невидимость

*Противники не могут выбрать целью одиночной атаки.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a wizard hat and round spectacles floating in the air with nobody underneath, dotted outline of a missing head. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #9ab8c8. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `reflect.png` — Отражение

*Следующее вредное заклинание или атака возвращается в автора.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: an ornate hand mirror bouncing a small magic bolt back, the bolt curving away. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #b8d8f0. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `invulnerable.png` — Неуязвимость

*Следующий удар по цели не проходит.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a golden soap-bubble dome over a small candle flame, sparkles on the bubble. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #fff0a0. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `stoneskin.png` — Каменная кожа

*Защита +2: каждый удар слабее на 2 (минимум 1).*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a raised forearm covered in grey stone plates like armour. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #a08a6a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `inspire.png` — Вдохновение

*Заклинания +1 к урону, лечению и щиту.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a bright candle flame rising from the pages of an open book, golden rays. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #ffd35a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `bless.png` — Благословение

*Удача +2: «неподходящее» заклинание с шансом 10 % рассеется.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a four-leaf clover with a small golden halo floating above it. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #f5e6a8. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `focus.png` — Сосредоточенность

*Можно выбрать порядок фишек в тройке. (В прототипе пока не работает.)*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a magnifying glass held over three coloured round chips lying in a row. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #7ac0e8. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `elemental.png` — Водный элементаль

*Игнорирует урон всех стихий, кроме огня.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a water droplet shaped like a tiny wizard with a pointed hat, splashing. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #3b82d6. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `taunt.png` — Провокация

*Все противники бьют только этого участника.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: an old man's fist shaking a wooden walking cane, an angry puff of steam above it. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #c0392b. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

## Особые метки

### `shield.png` — Щит

*Поглощает урон, пока не кончится. Число — сколько осталось.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a round wooden shield with a brass rim and a simple star rune. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #6fa8ff. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `fortify.png` — Укрепление

*Временное здоровье после отдыха. Тратится первым, тает на 0.5 за ход. Число — сколько осталось.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a knitted woollen scarf wrapped around a heart, warm golden glow (rested and cosy). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #c9a24a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `leader.png` — Предводитель

*Глава банды: особая атака с перезарядкой, не оглушается. Когда гибнет, банда паникует.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: a battered golden crown with a single feather, slightly crooked. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #b08a5a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `boss.png` — Босс

*Несколько особых атак, не оглушается.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: an ominous crown made of bones with two glowing red eyes in the darkness beneath it. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #ff5a5a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```

### `rat_guard.png` — Крысиная охрана

*Пока рядом есть хоть одна крыса, получает −1 урон от каждого удара.*

```
Square game UI status icon, 256x256 px. One clear central symbol that is readable even at 24 px: three small rats with tiny spears standing guard in front of a large rat shadow. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books). Limited palette of 3-4 colours dominated by #7a6a5a. Simple dark background #1b1a24 with a soft radial glow behind the symbol. Symbol fills about 75% of the canvas, centered. No frame, no border, no text, no letters, no numbers.
```
