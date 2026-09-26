# Промпты: персонажи (волшебники)

16 классов × 4 состояния. Картинки пойдут на карточки в бою и на привале, а лицо — в очередь ходов.

## Правила для всего набора

- **Формат:** вертикальный 3:4, **768×1024**, персонаж по колено, по центру, тёмный фон с мягким свечением.
- **Ракурс:** персонаж **смотрит вправо** — туда, где на экране стоят враги, — и **повёрнут к игроку примерно на 30°**
  (вид три четверти), чтобы лицо хорошо читалось.
- **4 состояния** каждого персонажа: здоров · побит (≈ половина ЗД) · тяжело ранен (меньше трети ЗД) · поднятый зомби.
  Игра сама переключает картинку по здоровью.
- **Узнаваемость:** описание внешности во всех 4 промптах персонажа **одинаковое** — меняется только часть «State».
- **Совет:** сначала сделай «здорового», а для остальных трёх используй его как **референс персонажа**
  (image-to-image, Character Reference в Midjourney `--cref`, IP-Adapter в Stable Diffusion) и тот же seed.
- Старики бывают и старушками: Алхимик и Оракул — женщины, это разнообразит отряд.

## Куда класть

`assets/characters/<класс>_<состояние>.png`, например `assets/characters/pyromancer_healthy.png`.

| Состояние | Имя файла | Когда показывается |
|---|---|---|
| здоров | `_healthy` | ЗД больше половины |
| побит | `_hurt` | ЗД от трети до половины |
| тяжело ранен | `_critical` | ЗД меньше трети |
| зомби | `_zombie` | поднят Некромантом |

**Негативный промпт (для всех):**

```
text, letters, numbers, words, title, logo, watermark, signature, photorealistic, 3D render, anime, chibi, modern clothing, cropped, blurry, multiple characters, facing left, back view
```

## Персонажи

### Пиромант (`pyromancer`)

*Выражение: gleeful mischievous grin, eyebrows raised. Поза: leaning forward eagerly, one hand raised with the flame, book tucked under the other arm.*

**`pyromancer_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old wizard with a long grey beard singed and smoking at the tip, bushy eyebrows, a red robe with small burn holes, a pointed red hat with a scorched brim; carries the sooty Fire spell book; a small flame dancing on one fingertip. Signature expression: gleeful mischievous grin, eyebrows raised. Pose: leaning forward eagerly, one hand raised with the flame, book tucked under the other arm. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`pyromancer_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old wizard with a long grey beard singed and smoking at the tip, bushy eyebrows, a red robe with small burn holes, a pointed red hat with a scorched brim; carries the sooty Fire spell book; a small flame dancing on one fingertip. Signature expression: gleeful mischievous grin, eyebrows raised. Pose: leaning forward eagerly, one hand raised with the flame, book tucked under the other arm. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`pyromancer_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old wizard with a long grey beard singed and smoking at the tip, bushy eyebrows, a red robe with small burn holes, a pointed red hat with a scorched brim; carries the sooty Fire spell book; a small flame dancing on one fingertip. Signature expression: gleeful mischievous grin, eyebrows raised. Pose: leaning forward eagerly, one hand raised with the flame, book tucked under the other arm. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`pyromancer_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old wizard with a long grey beard singed and smoking at the tip, bushy eyebrows, a red robe with small burn holes, a pointed red hat with a scorched brim; carries the sooty Fire spell book; a small flame dancing on one fingertip. Signature expression: gleeful mischievous grin, eyebrows raised. Pose: leaning forward eagerly, one hand raised with the flame, book tucked under the other arm. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Священник (`priest`)

*Выражение: serene, slightly smug kindness, eyes half-closed. Поза: upright and dignified, other hand raised in a blessing.*

**`priest_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an elderly priest-wizard, bald with a white fringe and a big white moustache, round spectacles, white-and-gold vestments with a sun embroidery; holds the heavy gold-framed Holy spell book to his chest. Signature expression: serene, slightly smug kindness, eyes half-closed. Pose: upright and dignified, other hand raised in a blessing. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`priest_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an elderly priest-wizard, bald with a white fringe and a big white moustache, round spectacles, white-and-gold vestments with a sun embroidery; holds the heavy gold-framed Holy spell book to his chest. Signature expression: serene, slightly smug kindness, eyes half-closed. Pose: upright and dignified, other hand raised in a blessing. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`priest_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an elderly priest-wizard, bald with a white fringe and a big white moustache, round spectacles, white-and-gold vestments with a sun embroidery; holds the heavy gold-framed Holy spell book to his chest. Signature expression: serene, slightly smug kindness, eyes half-closed. Pose: upright and dignified, other hand raised in a blessing. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`priest_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an elderly priest-wizard, bald with a white fringe and a big white moustache, round spectacles, white-and-gold vestments with a sun embroidery; holds the heavy gold-framed Holy spell book to his chest. Signature expression: serene, slightly smug kindness, eyes half-closed. Pose: upright and dignified, other hand raised in a blessing. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Волшебник Воды (`water`)

*Выражение: calm and sleepy-eyed, a faint smile. Поза: relaxed, slightly swaying, one hand making a wave gesture.*

**`water_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a thin elderly wizard with a long braided blue-grey beard, flowing blue robes whose hem is always dripping wet, a soft blue hat with a seashell pin; holds the swollen damp Water spell book, water droplets orbit around him. Signature expression: calm and sleepy-eyed, a faint smile. Pose: relaxed, slightly swaying, one hand making a wave gesture. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`water_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a thin elderly wizard with a long braided blue-grey beard, flowing blue robes whose hem is always dripping wet, a soft blue hat with a seashell pin; holds the swollen damp Water spell book, water droplets orbit around him. Signature expression: calm and sleepy-eyed, a faint smile. Pose: relaxed, slightly swaying, one hand making a wave gesture. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`water_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a thin elderly wizard with a long braided blue-grey beard, flowing blue robes whose hem is always dripping wet, a soft blue hat with a seashell pin; holds the swollen damp Water spell book, water droplets orbit around him. Signature expression: calm and sleepy-eyed, a faint smile. Pose: relaxed, slightly swaying, one hand making a wave gesture. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`water_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a thin elderly wizard with a long braided blue-grey beard, flowing blue robes whose hem is always dripping wet, a soft blue hat with a seashell pin; holds the swollen damp Water spell book, water droplets orbit around him. Signature expression: calm and sleepy-eyed, a faint smile. Pose: relaxed, slightly swaying, one hand making a wave gesture. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Магус с тростью (`magus`)

*Выражение: stern and focused, one eyebrow raised. Поза: fencer's stance, cane pointed forward toward the enemies.*

**`magus_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a wiry old battle-mage with a neat pointed white beard and a monocle, a fencing jacket over a short robe, a flat-topped wizard hat; holds a walking cane like a rapier, the fencing-manual spell book tucked under his arm. Signature expression: stern and focused, one eyebrow raised. Pose: fencer's stance, cane pointed forward toward the enemies. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`magus_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a wiry old battle-mage with a neat pointed white beard and a monocle, a fencing jacket over a short robe, a flat-topped wizard hat; holds a walking cane like a rapier, the fencing-manual spell book tucked under his arm. Signature expression: stern and focused, one eyebrow raised. Pose: fencer's stance, cane pointed forward toward the enemies. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`magus_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a wiry old battle-mage with a neat pointed white beard and a monocle, a fencing jacket over a short robe, a flat-topped wizard hat; holds a walking cane like a rapier, the fencing-manual spell book tucked under his arm. Signature expression: stern and focused, one eyebrow raised. Pose: fencer's stance, cane pointed forward toward the enemies. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`magus_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a wiry old battle-mage with a neat pointed white beard and a monocle, a fencing jacket over a short robe, a flat-topped wizard hat; holds a walking cane like a rapier, the fencing-manual spell book tucked under his arm. Signature expression: stern and focused, one eyebrow raised. Pose: fencer's stance, cane pointed forward toward the enemies. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Бард-на-пенсии (`bard`)

*Выражение: theatrical, singing with eyes closed. Поза: one arm flung out dramatically mid-song.*

**`bard_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a plump jolly old bard-wizard with rosy cheeks and a curly white beard, a feathered beret-style wizard hat, a patched colourful coat, a lute slung on his back; holds the open songbook. Signature expression: theatrical, singing with eyes closed. Pose: one arm flung out dramatically mid-song. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`bard_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a plump jolly old bard-wizard with rosy cheeks and a curly white beard, a feathered beret-style wizard hat, a patched colourful coat, a lute slung on his back; holds the open songbook. Signature expression: theatrical, singing with eyes closed. Pose: one arm flung out dramatically mid-song. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`bard_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a plump jolly old bard-wizard with rosy cheeks and a curly white beard, a feathered beret-style wizard hat, a patched colourful coat, a lute slung on his back; holds the open songbook. Signature expression: theatrical, singing with eyes closed. Pose: one arm flung out dramatically mid-song. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`bard_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a plump jolly old bard-wizard with rosy cheeks and a curly white beard, a feathered beret-style wizard hat, a patched colourful coat, a lute slung on his back; holds the open songbook. Signature expression: theatrical, singing with eyes closed. Pose: one arm flung out dramatically mid-song. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Паладин в отставке (`paladin`)

*Выражение: solemn noble frown. Поза: chest out, feet planted, one hand over his heart.*

**`paladin_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a broad-shouldered old knight-wizard with a huge white walrus moustache, a dented rusty breastplate over a white robe, a small helmet-like hat; holds the oath-code spell book with a shield-shaped clasp. Signature expression: solemn noble frown. Pose: chest out, feet planted, one hand over his heart. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`paladin_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a broad-shouldered old knight-wizard with a huge white walrus moustache, a dented rusty breastplate over a white robe, a small helmet-like hat; holds the oath-code spell book with a shield-shaped clasp. Signature expression: solemn noble frown. Pose: chest out, feet planted, one hand over his heart. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`paladin_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a broad-shouldered old knight-wizard with a huge white walrus moustache, a dented rusty breastplate over a white robe, a small helmet-like hat; holds the oath-code spell book with a shield-shaped clasp. Signature expression: solemn noble frown. Pose: chest out, feet planted, one hand over his heart. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`paladin_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a broad-shouldered old knight-wizard with a huge white walrus moustache, a dented rusty breastplate over a white robe, a small helmet-like hat; holds the oath-code spell book with a shield-shaped clasp. Signature expression: solemn noble frown. Pose: chest out, feet planted, one hand over his heart. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Друид (`druid`)

*Выражение: grumpy scowl (he disapproves of fire magic). Поза: arms crossed with the staff held in one arm.*

**`druid_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a gnarled old druid with a beard full of twigs and moss, a hat woven from leaves with a small bird nesting in it, bark-coloured robes; holds a wooden staff and the bark-covered Druid spell book. Signature expression: grumpy scowl (he disapproves of fire magic). Pose: arms crossed with the staff held in one arm. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`druid_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a gnarled old druid with a beard full of twigs and moss, a hat woven from leaves with a small bird nesting in it, bark-coloured robes; holds a wooden staff and the bark-covered Druid spell book. Signature expression: grumpy scowl (he disapproves of fire magic). Pose: arms crossed with the staff held in one arm. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`druid_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a gnarled old druid with a beard full of twigs and moss, a hat woven from leaves with a small bird nesting in it, bark-coloured robes; holds a wooden staff and the bark-covered Druid spell book. Signature expression: grumpy scowl (he disapproves of fire magic). Pose: arms crossed with the staff held in one arm. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`druid_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a gnarled old druid with a beard full of twigs and moss, a hat woven from leaves with a small bird nesting in it, bark-coloured robes; holds a wooden staff and the bark-covered Druid spell book. Signature expression: grumpy scowl (he disapproves of fire magic). Pose: arms crossed with the staff held in one arm. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Некромант (`necromancer`)

*Выражение: creepy polite smile. Поза: slightly hunched, fingers steepled over the book.*

**`necromancer_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a gaunt pale old man in a dark purple hooded robe, bony fingers, a tiny friendly skull sitting on his shoulder; holds the Necronomicon with a skull-shaped clasp. Signature expression: creepy polite smile. Pose: slightly hunched, fingers steepled over the book. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`necromancer_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a gaunt pale old man in a dark purple hooded robe, bony fingers, a tiny friendly skull sitting on his shoulder; holds the Necronomicon with a skull-shaped clasp. Signature expression: creepy polite smile. Pose: slightly hunched, fingers steepled over the book. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`necromancer_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a gaunt pale old man in a dark purple hooded robe, bony fingers, a tiny friendly skull sitting on his shoulder; holds the Necronomicon with a skull-shaped clasp. Signature expression: creepy polite smile. Pose: slightly hunched, fingers steepled over the book. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`necromancer_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a gaunt pale old man in a dark purple hooded robe, bony fingers, a tiny friendly skull sitting on his shoulder; holds the Necronomicon with a skull-shaped clasp. Signature expression: creepy polite smile. Pose: slightly hunched, fingers steepled over the book. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Учёный (`scientist`)

*Выражение: skeptical squint, as if saying 'this is unscientific'. Поза: pointing a pencil at the clipboard.*

**`scientist_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old scientist with wild frizzy white hair (no hat), brass goggles on the forehead, a lab coat over a robe, a wrench in the coat pocket, a clipboard in hand; a small steampunk mechanical sheep stands by his leg. Signature expression: skeptical squint, as if saying 'this is unscientific'. Pose: pointing a pencil at the clipboard. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`scientist_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old scientist with wild frizzy white hair (no hat), brass goggles on the forehead, a lab coat over a robe, a wrench in the coat pocket, a clipboard in hand; a small steampunk mechanical sheep stands by his leg. Signature expression: skeptical squint, as if saying 'this is unscientific'. Pose: pointing a pencil at the clipboard. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`scientist_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old scientist with wild frizzy white hair (no hat), brass goggles on the forehead, a lab coat over a robe, a wrench in the coat pocket, a clipboard in hand; a small steampunk mechanical sheep stands by his leg. Signature expression: skeptical squint, as if saying 'this is unscientific'. Pose: pointing a pencil at the clipboard. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`scientist_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old scientist with wild frizzy white hair (no hat), brass goggles on the forehead, a lab coat over a robe, a wrench in the coat pocket, a clipboard in hand; a small steampunk mechanical sheep stands by his leg. Signature expression: skeptical squint, as if saying 'this is unscientific'. Pose: pointing a pencil at the clipboard. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Прорицатель (`seer`)

*Выражение: knowing half-smile, eyes glowing faintly. Поза: gazing into the crystal ball held up in one hand.*

**`seer_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old seer in a star-patterned robe and a turban with a crystal jewel, a long silver beard; holds a small crystal ball above the almanac spell book. Signature expression: knowing half-smile, eyes glowing faintly. Pose: gazing into the crystal ball held up in one hand. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`seer_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old seer in a star-patterned robe and a turban with a crystal jewel, a long silver beard; holds a small crystal ball above the almanac spell book. Signature expression: knowing half-smile, eyes glowing faintly. Pose: gazing into the crystal ball held up in one hand. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`seer_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old seer in a star-patterned robe and a turban with a crystal jewel, a long silver beard; holds a small crystal ball above the almanac spell book. Signature expression: knowing half-smile, eyes glowing faintly. Pose: gazing into the crystal ball held up in one hand. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`seer_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old seer in a star-patterned robe and a turban with a crystal jewel, a long silver beard; holds a small crystal ball above the almanac spell book. Signature expression: knowing half-smile, eyes glowing faintly. Pose: gazing into the crystal ball held up in one hand. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Иллюзионист (`illusionist`)

*Выражение: sly wink. Поза: flourishing one gloved hand as if revealing a trick.*

**`illusionist_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a dapper old illusionist with a waxed white moustache, a top-hat-like wizard hat, a cape with teal lining, white magician gloves; a faint translucent copy of himself stands just behind him. Signature expression: sly wink. Pose: flourishing one gloved hand as if revealing a trick. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`illusionist_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a dapper old illusionist with a waxed white moustache, a top-hat-like wizard hat, a cape with teal lining, white magician gloves; a faint translucent copy of himself stands just behind him. Signature expression: sly wink. Pose: flourishing one gloved hand as if revealing a trick. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`illusionist_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a dapper old illusionist with a waxed white moustache, a top-hat-like wizard hat, a cape with teal lining, white magician gloves; a faint translucent copy of himself stands just behind him. Signature expression: sly wink. Pose: flourishing one gloved hand as if revealing a trick. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`illusionist_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a dapper old illusionist with a waxed white moustache, a top-hat-like wizard hat, a cape with teal lining, white magician gloves; a faint translucent copy of himself stands just behind him. Signature expression: sly wink. Pose: flourishing one gloved hand as if revealing a trick. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Дикий маг (`wild`)

*Выражение: manic wide-eyed grin. Поза: off-balance mid-cast, one leg lifted.*

**`wild_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a wild frazzled old sorcerer whose white hair stands on end from static, a robe of mismatched patches, the torn grimoire losing pages that fly around, small sparks and lightning crackles. Signature expression: manic wide-eyed grin. Pose: off-balance mid-cast, one leg lifted. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`wild_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a wild frazzled old sorcerer whose white hair stands on end from static, a robe of mismatched patches, the torn grimoire losing pages that fly around, small sparks and lightning crackles. Signature expression: manic wide-eyed grin. Pose: off-balance mid-cast, one leg lifted. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`wild_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a wild frazzled old sorcerer whose white hair stands on end from static, a robe of mismatched patches, the torn grimoire losing pages that fly around, small sparks and lightning crackles. Signature expression: manic wide-eyed grin. Pose: off-balance mid-cast, one leg lifted. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`wild_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a wild frazzled old sorcerer whose white hair stands on end from static, a robe of mismatched patches, the torn grimoire losing pages that fly around, small sparks and lightning crackles. Signature expression: manic wide-eyed grin. Pose: off-balance mid-cast, one leg lifted. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Чернокнижник (`warlock`)

*Выражение: guilty nervous smile. Поза: signing the contract with a flourish.*

**`warlock_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an elegant old warlock in a black robe with red lining and a tall collar, a thin grey goatee; holds a very long contract scroll and a quill, a shadowy hand of his patron resting on his shoulder. Signature expression: guilty nervous smile. Pose: signing the contract with a flourish. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`warlock_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an elegant old warlock in a black robe with red lining and a tall collar, a thin grey goatee; holds a very long contract scroll and a quill, a shadowy hand of his patron resting on his shoulder. Signature expression: guilty nervous smile. Pose: signing the contract with a flourish. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`warlock_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an elegant old warlock in a black robe with red lining and a tall collar, a thin grey goatee; holds a very long contract scroll and a quill, a shadowy hand of his patron resting on his shoulder. Signature expression: guilty nervous smile. Pose: signing the contract with a flourish. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`warlock_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an elegant old warlock in a black robe with red lining and a tall collar, a thin grey goatee; holds a very long contract scroll and a quill, a shadowy hand of his patron resting on his shoulder. Signature expression: guilty nervous smile. Pose: signing the contract with a flourish. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Алхимик (`alchemist`)

*Выражение: excited curiosity, tongue slightly out. Поза: holding the flask up to the light to inspect it.*

**`alchemist_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old woman alchemist with thick round goggles, singed eyebrows, a leather apron covered in vials and stains, a headscarf with a pointed hat on top; holds a bubbling flask. Signature expression: excited curiosity, tongue slightly out. Pose: holding the flask up to the light to inspect it. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`alchemist_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old woman alchemist with thick round goggles, singed eyebrows, a leather apron covered in vials and stains, a headscarf with a pointed hat on top; holds a bubbling flask. Signature expression: excited curiosity, tongue slightly out. Pose: holding the flask up to the light to inspect it. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`alchemist_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old woman alchemist with thick round goggles, singed eyebrows, a leather apron covered in vials and stains, a headscarf with a pointed hat on top; holds a bubbling flask. Signature expression: excited curiosity, tongue slightly out. Pose: holding the flask up to the light to inspect it. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`alchemist_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old woman alchemist with thick round goggles, singed eyebrows, a leather apron covered in vials and stains, a headscarf with a pointed hat on top; holds a bubbling flask. Signature expression: excited curiosity, tongue slightly out. Pose: holding the flask up to the light to inspect it. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Хрономант (`chrono`)

*Выражение: sleepy impatience. Поза: checking a pocket watch, leaning on the book.*

**`chrono_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a very old frail wizard with an hourglass-shaped hat, several pocket watches hanging on chains from his robe, a clock-faced spell book; small floating gears around him. Signature expression: sleepy impatience. Pose: checking a pocket watch, leaning on the book. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`chrono_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a very old frail wizard with an hourglass-shaped hat, several pocket watches hanging on chains from his robe, a clock-faced spell book; small floating gears around him. Signature expression: sleepy impatience. Pose: checking a pocket watch, leaning on the book. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`chrono_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a very old frail wizard with an hourglass-shaped hat, several pocket watches hanging on chains from his robe, a clock-faced spell book; small floating gears around him. Signature expression: sleepy impatience. Pose: checking a pocket watch, leaning on the book. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`chrono_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: a very old frail wizard with an hourglass-shaped hat, several pocket watches hanging on chains from his robe, a clock-faced spell book; small floating gears around him. Signature expression: sleepy impatience. Pose: checking a pocket watch, leaning on the book. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

### Оракул (`oracle`)

*Выражение: eerie calm. Поза: one hand raised with an eye symbol glowing on the palm.*

**`oracle_healthy.png` — здоров**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old woman oracle with one cloudy eye (her curse), a dark veil, necklaces of charms and small bones, a mysterious spell book with a closed-eye emblem. Signature expression: eerie calm. Pose: one hand raised with an eye symbol glowing on the palm. State: in full health: clothes intact, standing straight, full of energy. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`oracle_hurt.png` — побит (≈ половина ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old woman oracle with one cloudy eye (her curse), a dark veil, necklaces of charms and small bones, a mysterious spell book with a closed-eye emblem. Signature expression: eerie calm. Pose: one hand raised with an eye symbol glowing on the palm. State: moderately battered at about half health: a torn sleeve, scorched and dusty clothes, the hat crooked, a bruise and a sticking plaster on the cheek, tired but still determined expression (a strained version of the signature expression). Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`oracle_critical.png` — тяжело ранен (меньше трети ЗД)**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old woman oracle with one cloudy eye (her curse), a dark veil, necklaces of charms and small bones, a mysterious spell book with a closed-eye emblem. Signature expression: eerie calm. Pose: one hand raised with an eye symbol glowing on the palm. State: badly battered with less than a third of health left: clothes in tatters, the hat dented and torn, bandages on the head and arm, leaning heavily on the staff/cane/book, one eye half-closed from exhaustion, sweat drops, barely standing but stubborn. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```

**`oracle_zombie.png` — поднятый зомби**

```
Game character card art, vertical 3:4 image, 768x1024 px, knee-up shot of a single character. The character faces to the RIGHT (toward the enemies), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Character: an old woman oracle with one cloudy eye (her curse), a dark veil, necklaces of charms and small bones, a mysterious spell book with a closed-eye emblem. Signature expression: eerie calm. Pose: one hand raised with an eye symbol glowing on the palm. State: raised as a comical zombie by a necromancer: grey-green skin, stitched seams, sunken softly glowing eyes, loose threads, clothes dusty with grave dirt, still wearing the signature hat and holding the signature item, same pose but slightly slumped; funny rather than scary. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips and spell-book covers. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered with a little space above the hat. No text, no frame.
```
