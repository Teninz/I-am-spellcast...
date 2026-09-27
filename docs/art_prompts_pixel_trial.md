# Промпты: проба пиксель-арта

Проба перед возможным переходом игры в пиксель-арт: 3 волшебника, 2 крысы и фон Крысиной стаи.
По ним собирается экран боя в пиксельном режиме, и по живому скриншоту решаем, переходить ли.

## Куда класть

`assets/pixel_trial/<имя>.png`: `pyromancer.png`, `water.png`, `necromancer.png`, `rat_thief.png`,
`fat_tail.png`, `bg_battle_rat_pack.png`. Текущие картинки не трогаем, проба лежит отдельно.

## Как это устроено

- **Сетка.** Портрет задуман как спрайт **96×128 пикселей**, увеличенный в 8 раз (768×1024).
  Фон — **480×270**, увеличенный в 4 раза (1920×1080). Генераторы редко держат сетку идеально,
  поэтому после генерации я сам приведу картинку к точной сетке и общей палитре.
  От генератора нужны чистые крупные «пиксели» без размытия.
- **Портреты — по грудь** (голова и плечи крупно), а не по колено: в кольце на карточке
  всего ~74 точки, в пиксель-арте лицо должно занимать большую часть кадра.
- Направление взгляда прежнее: волшебники смотрят **вправо**, враги **влево**.

**Негативный промпт (для всех):**

```
smooth shading, painterly, soft brush, blur, anti-aliasing, gradients, glow bloom, photorealistic, 3D render, vector art, mixed pixel sizes, jpeg noise, text, letters, numbers, logo, watermark, signature, frame, border, multiple characters
```

## Волшебники

### Пиромант — `pyromancer.png`

```
Pixel art character portrait, head-and-shoulders bust, vertical 3:4, drawn as a 96x128 pixel sprite scaled up 8x to 768x1024 with nearest-neighbor, every pixel a crisp clean square, no anti-aliasing. Character faces to the RIGHT, three-quarter view, face large and clearly readable, filling the upper two thirds of the image. Character: an old wizard with a long grey beard singed and smoking at the tip, bushy eyebrows, a red robe with small burn holes, a pointed red hat with a scorched brim; a small flame dancing on one raised fingertip near his face. Expression: gleeful mischievous grin, eyebrows raised. 16-bit SNES-era fantasy RPG portrait style, limited palette of about 32 colors, 1-pixel dark outline around the figure, simple cel shading with 3-4 tones per color, minimal dithering, slightly humorous storybook tone. Plain flat dark background #1b1a24. No text, no frame.
```

### Волшебник Воды — `water.png`

```
Pixel art character portrait, head-and-shoulders bust, vertical 3:4, drawn as a 96x128 pixel sprite scaled up 8x to 768x1024 with nearest-neighbor, every pixel a crisp clean square, no anti-aliasing. Character faces to the RIGHT, three-quarter view, face large and clearly readable, filling the upper two thirds of the image. Character: a thin elderly wizard with a long braided blue-grey beard, flowing blue robes with a dripping wet collar, a soft blue hat with a seashell pin; a few water droplets orbit around his head. Expression: calm and sleepy-eyed, a faint smile. 16-bit SNES-era fantasy RPG portrait style, limited palette of about 32 colors, 1-pixel dark outline around the figure, simple cel shading with 3-4 tones per color, minimal dithering, slightly humorous storybook tone. Plain flat dark background #1b1a24. No text, no frame.
```

### Некромант — `necromancer.png`

```
Pixel art character portrait, head-and-shoulders bust, vertical 3:4, drawn as a 96x128 pixel sprite scaled up 8x to 768x1024 with nearest-neighbor, every pixel a crisp clean square, no anti-aliasing. Character faces to the RIGHT, three-quarter view, face large and clearly readable, filling the upper two thirds of the image. Character: a gaunt pale old man in a dark purple hooded robe, bony fingers steepled under his chin, a tiny friendly skull sitting on his shoulder. Expression: creepy polite smile. 16-bit SNES-era fantasy RPG portrait style, limited palette of about 32 colors, 1-pixel dark outline around the figure, simple cel shading with 3-4 tones per color, minimal dithering, slightly humorous storybook tone. Plain flat dark background #1b1a24. No text, no frame.
```

## Враги

### Крыса-воришка — `rat_thief.png`

```
Pixel art creature portrait, head-and-shoulders bust, vertical 3:4, drawn as a 96x128 pixel sprite scaled up 8x to 768x1024 with nearest-neighbor, every pixel a crisp clean square, no anti-aliasing. The creature faces to the LEFT, three-quarter view, face large and clearly readable, filling the upper two thirds of the image. Creature: a scrawny grey rat standing upright, wearing a tiny torn bandana, clutching a stolen silver spoon near its chest. Expression: sneaky toothy grin, eyes darting. 16-bit SNES-era fantasy RPG portrait style, limited palette of about 32 colors, 1-pixel dark outline around the figure, simple cel shading with 3-4 tones per color, minimal dithering, slightly humorous storybook tone. Plain flat dark background #1b1a24. No text, no frame.
```

### Толстый Хвост — `fat_tail.png`

```
Pixel art creature portrait, head-and-shoulders bust, vertical 3:4, drawn as a 96x128 pixel sprite scaled up 8x to 768x1024 with nearest-neighbor, every pixel a crisp clean square, no anti-aliasing. The creature faces to the LEFT, three-quarter view, face large and clearly readable, filling the upper two thirds of the image. Creature: a fat pompous rat boss with a huge ringed tail, a too-small bowler hat, a waistcoat straining over the belly, a chewed cigar in the corner of the mouth, one paw raised commandingly. Expression: smug half-closed eyes. 16-bit SNES-era fantasy RPG portrait style, limited palette of about 32 colors, 1-pixel dark outline around the figure, simple cel shading with 3-4 tones per color, minimal dithering, slightly humorous storybook tone. Plain flat dark background #1b1a24. No text, no frame.
```

## Фон

### Крысиная стая — `bg_battle_rat_pack.png`

```
Pixel art game battle background, wide 16:9, drawn as a 480x270 pixel scene scaled up 4x to 1920x1080 with nearest-neighbor, every pixel a crisp clean square, no anti-aliasing. A dusty village granary and barn interior at dusk: sacks of grain, gnawed cheese wheels, wooden beams, a ladder, cool blue moonlight through a roof hatch. The middle of the image is calm and low in detail (UI sits on top: party cards on the left third, enemy cards on the right third, chips and buttons in the centre). Muted, desaturated palette with cool light, mid-dark values, no orange cast, no fog. 16-bit SNES-era fantasy RPG background style, limited palette of about 48 colors, clean pixel clusters, light dithering only in the moonlight. No characters, no text.
```
