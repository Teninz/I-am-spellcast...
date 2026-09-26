# Промпты: враги акта I и кольца аватарок

Портреты для карточек врагов в бою (акт I — «Окраины деревни») и кольца аватарок для волшебников и врагов.

## Портреты врагов — правила

- **Формат:** вертикальный 3:4, **768×1024**, как у волшебников. На карточке в бою видна верхняя часть — голова и плечи, поэтому лицо должно быть в верхней половине картинки.
- **Ракурс:** враг **смотрит влево** — туда, где стоит отряд, — и повёрнут к игроку примерно на 30°.
- **Одна картинка на врага** (без состояний).
- **Тон:** враги опасные, но смешные — это деревенская окраина, а не ад.
- **Куда класть:** `assets/enemies/<id>.png`, например `assets/enemies/rat_thief.png`. Пока картинки нет, карточка остаётся без портрета.

**Негативный промпт (для всех):**

```
text, letters, numbers, words, title, logo, watermark, signature, photorealistic, 3D render, anime, chibi, cropped head, blurry, multiple characters, facing right, back view, gore
```

## Враги

| Файл | Кто | Где встречается |
|---|---|---|
| `rat_thief.png` | Крыса-воришка | рядовой · Крысиная стая; ещё «Крыса» Крысиного Короля и «Крыса из свиты» |
| `fat_tail.png` | Толстый Хвост | предводитель Крысиной стаи |
| `rat_king.png` | Крысиный Король | босс акта I |
| `drunk_goblin.png` | Пьяный гоблин | рядовой · Гоблинская шайка |
| `goblin_plate_thrower.png` | Гоблин-метатель тарелок | рядовой · Гоблинская шайка |
| `goblin_foreman.png` | Бригадир Гнырк | предводитель Гоблинской шайки |
| `bandit.png` | Разбойник | рядовой · Разбойники; ещё «Подручный Бо» |
| `bandit_crossbow.png` | Разбойник-арбалетчик | рядовой · Разбойники; призыв Одноглазого Бо |
| `ataman_krivoy.png` | Атаман Кривой | предводитель Разбойников |
| `kobold_digger.png` | Кобольд-копатель | рядовой · Кобольдова артель |
| `kobold_shaman.png` | Кобольд-шаман | рядовой · Кобольдова артель, лечит своих |
| `kobold_foreman.png` | Прораб Кирка | предводитель Кобольдовой артели |
| `mad_goose.png` | Бешеный гусь | рядовой · Гусиная банда |
| `armored_gander.png` | Гусак Бронированный | предводитель Гусиной банды |
| `boar.png` | Кабан-таран | рядовой · Звери с опушки |
| `big_wolf.png` | Волк-переросток | предводитель Зверей с опушки |
| `biting_mushroom.png` | Кусачий гриб | рядовой · Грибная поляна |
| `old_toadstool.png` | Старый Мухомор | предводитель Грибной поляны |
| `war_pig.png` | Боевая свинья | босс · Гоблинский Вождь (скакун) |
| `goblin_chief.png` | Гоблинский Вождь | босс акта I |
| `mother_slime.png` | Матушка-Слизь | босс акта I |
| `slimeling.png` | Слизень | отделяется от Матушки-Слизи |
| `one_eyed_bo.png` | Одноглазый Бо | босс акта I |
| `goose_patriarch.png` | Гусь-Патриарх | босс акта I |

### Крыса-воришка — `assets/enemies/rat_thief.png`

*рядовой · Крысиная стая; ещё «Крыса» Крысиного Короля и «Крыса из свиты». Выражение и поза: sneaky toothy grin, eyes darting; crouched, ready to scurry.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a scrawny grey rat standing on its hind legs, wearing a tiny torn bandana, clutching a stolen silver spoon, long pink tail. Signature expression and pose: sneaky toothy grin, eyes darting; crouched, ready to scurry. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Толстый Хвост — `assets/enemies/fat_tail.png`

*предводитель Крысиной стаи. Выражение и поза: smug half-closed eyes; one paw raised to command the pack with a squeak.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a fat pompous rat boss with a huge ringed tail, a too-small bowler hat, a waistcoat straining over the belly, a chewed cigar. Signature expression and pose: smug half-closed eyes; one paw raised to command the pack with a squeak. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Крысиный Король — `assets/enemies/rat_king.png`

*босс акта I. Выражение и поза: arrogant sneer showing yellow teeth; gesturing grandly as if summoning his swarm.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a huge regal rat with a crooked tin crown and a moth-eaten red mantle, sitting on a small throne of junk and cheese rinds, several rat tails knotted together behind him. Signature expression and pose: arrogant sneer showing yellow teeth; gesturing grandly as if summoning his swarm. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Пьяный гоблин — `assets/enemies/drunk_goblin.png`

*рядовой · Гоблинская шайка. Выражение и поза: hiccupping lopsided grin, cross-eyed; wobbling unsteadily.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a small green goblin with a red nose, patched tunic, holding a wooden mug of ale that sloshes over, a dented pot helmet askew. Signature expression and pose: hiccupping lopsided grin, cross-eyed; wobbling unsteadily. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Гоблин-метатель тарелок — `assets/enemies/goblin_plate_thrower.png`

*рядовой · Гоблинская шайка. Выражение и поза: focused tongue sticking out; mid-throw pose.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a wiry goblin with a stack of chipped dinner plates under one arm, one plate raised to throw like a discus, apron with food stains. Signature expression and pose: focused tongue sticking out; mid-throw pose. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Бригадир Гнырк — `assets/enemies/goblin_foreman.png`

*предводитель Гоблинской шайки. Выражение и поза: shouting bossily, one finger pointing; about to hurl the barrel.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a stocky goblin foreman with a hard hat, a whistle on a string, a rolled-up blueprint and a small barrel on his shoulder. Signature expression and pose: shouting bossily, one finger pointing; about to hurl the barrel. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Разбойник — `assets/enemies/bandit.png`

*рядовой · Разбойники; ещё «Подручный Бо». Выражение и поза: shifty squint above the scarf; slouched menacing stance.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a scruffy highway bandit with a dark scarf over the lower face, patched leather jerkin, a short club. Signature expression and pose: shifty squint above the scarf; slouched menacing stance. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Разбойник-арбалетчик — `assets/enemies/bandit_crossbow.png`

*рядовой · Разбойники; призыв Одноглазого Бо. Выражение и поза: concentrated aim, smirking; crossbow raised.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a lanky bandit with a battered crossbow and a quiver of mismatched bolts, feathered cap, one eye closed aiming. Signature expression and pose: concentrated aim, smirking; crossbow raised. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Атаман Кривой — `assets/enemies/ataman_krivoy.png`

*предводитель Разбойников. Выражение и поза: greedy gap-toothed grin; reaching out as if to snatch an item.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a big bandit chief with a crooked broken nose, a wide-brimmed hat with a plume, gold tooth, a heavy sack of loot over the shoulder and a cudgel. Signature expression and pose: greedy gap-toothed grin; reaching out as if to snatch an item. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Кобольд-копатель — `assets/enemies/kobold_digger.png`

*рядовой · Кобольдова артель. Выражение и поза: eager wide yellow eyes; poised to dig.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a small reptilian kobold miner with a candle stuck on a tiny helmet, a pickaxe bigger than itself, dirt on its snout. Signature expression and pose: eager wide yellow eyes; poised to dig. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Кобольд-шаман — `assets/enemies/kobold_shaman.png`

*рядовой · Кобольдова артель, лечит своих. Выражение и поза: mystical humming, eyes half shut; holding the glowing staff forward to heal.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a kobold shaman with a mask made of a tin can, beads and feathers, a staff topped with a glowing crystal and a bandage roll. Signature expression and pose: mystical humming, eyes half shut; holding the glowing staff forward to heal. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Прораб Кирка — `assets/enemies/kobold_foreman.png`

*предводитель Кобольдовой артели. Выражение и поза: grumpy scowl; stomping the ground to cause a rockfall.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a burly kobold foreman with a big safety helmet, a clipboard, a huge double-headed pickaxe resting on the shoulder, pebbles falling around. Signature expression and pose: grumpy scowl; stomping the ground to cause a rockfall. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Бешеный гусь — `assets/enemies/mad_goose.png`

*рядовой · Гусиная банда. Выражение и поза: hissing with beak wide open, crazed eyes; charging.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a furious white farm goose with wings spread wide, neck stretched out, feathers ruffled. Signature expression and pose: hissing with beak wide open, crazed eyes; charging. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Гусак Бронированный — `assets/enemies/armored_gander.png`

*предводитель Гусиной банды. Выражение и поза: stern veteran glare; wings half raised like a knight's shield.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a big grey gander wearing a dented kettle-helmet and a small breastplate made from a frying pan, battle scars on the beak. Signature expression and pose: stern veteran glare; wings half raised like a knight's shield. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Кабан-таран — `assets/enemies/boar.png`

*рядовой · Звери с опушки. Выражение и поза: snorting angrily, steam from the nostrils; about to ram.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a stocky wild boar with big tusks, bristly back, head lowered with a patch of bark stuck on its forehead. Signature expression and pose: snorting angrily, steam from the nostrils; about to ram. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Волк-переросток — `assets/enemies/big_wolf.png`

*предводитель Зверей с опушки. Выражение и поза: growling with bared fangs but slightly dopey eyes; crouched to lunge for the throat.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: an oversized shaggy grey wolf, a bit clumsy and too big for itself, with a torn village-dog collar. Signature expression and pose: growling with bared fangs but slightly dopey eyes; crouched to lunge for the throat. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Кусачий гриб — `assets/enemies/biting_mushroom.png`

*рядовой · Грибная поляна. Выражение и поза: snapping jaws, mischievous; hopping forward.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a small walking brown mushroom with stubby legs and a wide mouth full of tiny sharp teeth under the cap, spores drifting. Signature expression and pose: snapping jaws, mischievous; hopping forward. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Старый Мухомор — `assets/enemies/old_toadstool.png`

*предводитель Грибной поляны. Выражение и поза: wise but sinister smile; exhaling a cloud of glowing green spores.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: an ancient fly agaric mushroom with a huge red cap with white spots, a long white moss beard, a gnarled root walking stick. Signature expression and pose: wise but sinister smile; exhaling a cloud of glowing green spores. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Боевая свинья — `assets/enemies/war_pig.png`

*босс · Гоблинский Вождь (скакун). Выражение и поза: furious snorting, head lowered; mid-charge.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a muscular war pig with iron plates strapped on, a spiked leather collar and a small saddle, mud-splattered. Signature expression and pose: furious snorting, head lowered; mid-charge. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Гоблинский Вождь — `assets/enemies/goblin_chief.png`

*босс акта I. Выражение и поза: shouting a battle cry with the spear raised high.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a goblin chieftain with a horned helmet too big for him, a bone necklace, a long wooden spear with a ribbon, a war-paint stripe across the face. Signature expression and pose: shouting a battle cry with the spear raised high. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Матушка-Слизь — `assets/enemies/mother_slime.png`

*босс акта I. Выражение и поза: doting smile with too many teeth; small slime blobs budding off her sides.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a huge translucent green slime blob with a kind but creepy motherly face, a lace doily on top like a bonnet, small objects floating inside (a spoon, a boot). Signature expression and pose: doting smile with too many teeth; small slime blobs budding off her sides. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Слизень — `assets/enemies/slimeling.png`

*отделяется от Матушки-Слизи. Выражение и поза: happy wobbly grin; bouncing.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a small green slime blob with big curious eyes and a tiny drop-shaped tuft on top. Signature expression and pose: happy wobbly grin; bouncing. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Одноглазый Бо — `assets/enemies/one_eyed_bo.png`

*босс акта I. Выражение и поза: sly one-eyed wink; pulling a stolen purse from a pocket.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: a lean bandit leader with an eyepatch, a long dark coat with many hidden pockets, a flail over the shoulder, half his body fading into shadow as if invisible. Signature expression and pose: sly one-eyed wink; pulling a stolen purse from a pocket. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

### Гусь-Патриарх — `assets/enemies/goose_patriarch.png`

*босс акта I. Выражение и поза: outraged honking, beak wide open, wings spread majestically.*

```
Game enemy card art, vertical 3:4 image, 768x1024 px, knee-up (or full body for small creatures) shot of a single creature. The creature faces to the LEFT (toward the wizards), body turned about 30 degrees toward the viewer (three-quarter view), so the face is clearly visible. Creature: an enormous old white goose with a long grey beard of feathers, a tiny golden crown and a monocle, a faint golden shimmer of invulnerability around him. Signature expression and pose: outraged honking, beak wide open, wings spread majestically. Cozy hand-painted storybook illustration style, bold dark ink outlines, slightly humorous tone (theme: grumpy old wizards who cast random spells from books), same style as a matching set of game icons, chips, spell-book covers and wizard portraits. Plain dark background #1b1a24 with a soft radial glow behind the character, character centered, the head and shoulders clearly readable in the upper half of the image. No text, no frame.
```

## Кольца аватарок в бою

Круглые рамки вокруг лица на карточке в бою: 4 для волшебников и 4 для врагов. Игра сама выбирает кольцо по состоянию.

- **Формат:** квадрат **512×512**, **прозрачный фон (PNG с альфа-каналом)**, кольцо по центру.
- **Середина кольца — пустая и прозрачная**: туда игра подставит лицо. Внутренний диаметр — примерно 70 % картинки, толщина кольца — около 12 % ширины.
- Все 4 кольца одной стороны — **одинаковой формы и размера**, отличаются только отделкой и цветом, чтобы можно было подменять их без сдвига.
- **Куда класть:** `assets/ui/<id>.png`. Прежний `portrait_ring.png` больше не нужен.

| Файл | Кольцо | Когда показывается |
|---|---|---|
| `ring_wizard.png` | Кольцо волшебника | обычное |
| `ring_wizard_active.png` | Кольцо волшебника — ходит сейчас | подсветка того, чей ход |
| `ring_wizard_critical.png` | Кольцо волшебника — при смерти | ЗД меньше трети |
| `ring_wizard_zombie.png` | Кольцо волшебника — зомби | поднят Некромантом |
| `ring_enemy.png` | Кольцо врага | обычный враг |
| `ring_enemy_leader.png` | Кольцо врага — предводитель | предводитель банды |
| `ring_enemy_boss.png` | Кольцо врага — босс | босс акта |
| `ring_enemy_summon.png` | Кольцо врага — призванный | призванный или отделившийся |

### Кольцо волшебника — `assets/ui/ring_wizard.png`

```
Game UI avatar frame, square 512x512 px, transparent background, a single circular ring frame centered, the inside of the ring completely empty and transparent (a round window for a character portrait, inner diameter about 70% of the image), ring thickness about 12% of the width. Ring design: warm polished bronze ring engraved with tiny runes and little stars, a small book emblem at the bottom. Dominant colour #c9a45c. Cozy hand-painted storybook illustration style, bold dark ink outlines, matching a set of fantasy game UI frames and buttons. Perfectly round, symmetrical, flat front view. No text, no letters, no character inside, no background.
```

### Кольцо волшебника — ходит сейчас — `assets/ui/ring_wizard_active.png`

```
Game UI avatar frame, square 512x512 px, transparent background, a single circular ring frame centered, the inside of the ring completely empty and transparent (a round window for a character portrait, inner diameter about 70% of the image), ring thickness about 12% of the width. Ring design: the same bronze rune ring but glowing bright gold, with sparkles and a soft magical halo radiating outward. Dominant colour #ffd35a. Cozy hand-painted storybook illustration style, bold dark ink outlines, matching a set of fantasy game UI frames and buttons. Perfectly round, symmetrical, flat front view. No text, no letters, no character inside, no background.
```

### Кольцо волшебника — при смерти — `assets/ui/ring_wizard_critical.png`

```
Game UI avatar frame, square 512x512 px, transparent background, a single circular ring frame centered, the inside of the ring completely empty and transparent (a round window for a character portrait, inner diameter about 70% of the image), ring thickness about 12% of the width. Ring design: the same bronze rune ring but cracked and chipped, with a faint red glow seeping through the cracks. Dominant colour #c0392b. Cozy hand-painted storybook illustration style, bold dark ink outlines, matching a set of fantasy game UI frames and buttons. Perfectly round, symmetrical, flat front view. No text, no letters, no character inside, no background.
```

### Кольцо волшебника — зомби — `assets/ui/ring_wizard_zombie.png`

```
Game UI avatar frame, square 512x512 px, transparent background, a single circular ring frame centered, the inside of the ring completely empty and transparent (a round window for a character portrait, inner diameter about 70% of the image), ring thickness about 12% of the width. Ring design: the same bronze rune ring overgrown with sickly green moss, with a small bone and a tiny skull at the bottom, faint green glow. Dominant colour #7fbf5a. Cozy hand-painted storybook illustration style, bold dark ink outlines, matching a set of fantasy game UI frames and buttons. Perfectly round, symmetrical, flat front view. No text, no letters, no character inside, no background.
```

### Кольцо врага — `assets/ui/ring_enemy.png`

```
Game UI avatar frame, square 512x512 px, transparent background, a single circular ring frame centered, the inside of the ring completely empty and transparent (a round window for a character portrait, inner diameter about 70% of the image), ring thickness about 12% of the width. Ring design: rough dark iron ring with rivets and scratches, a small crossed-claws emblem at the bottom. Dominant colour #8a5a4a. Cozy hand-painted storybook illustration style, bold dark ink outlines, matching a set of fantasy game UI frames and buttons. Perfectly round, symmetrical, flat front view. No text, no letters, no character inside, no background.
```

### Кольцо врага — предводитель — `assets/ui/ring_enemy_leader.png`

```
Game UI avatar frame, square 512x512 px, transparent background, a single circular ring frame centered, the inside of the ring completely empty and transparent (a round window for a character portrait, inner diameter about 70% of the image), ring thickness about 12% of the width. Ring design: the same iron ring with a spiky crest on top and a small golden star emblem, a strip of red cloth tied to it. Dominant colour #e0913a. Cozy hand-painted storybook illustration style, bold dark ink outlines, matching a set of fantasy game UI frames and buttons. Perfectly round, symmetrical, flat front view. No text, no letters, no character inside, no background.
```

### Кольцо врага — босс — `assets/ui/ring_enemy_boss.png`

```
Game UI avatar frame, square 512x512 px, transparent background, a single circular ring frame centered, the inside of the ring completely empty and transparent (a round window for a character portrait, inner diameter about 70% of the image), ring thickness about 12% of the width. Ring design: a massive blackened iron ring with horns and a skull crest on top, embers glowing in the cracks, red-orange menacing glow. Dominant colour #c0392b. Cozy hand-painted storybook illustration style, bold dark ink outlines, matching a set of fantasy game UI frames and buttons. Perfectly round, symmetrical, flat front view. No text, no letters, no character inside, no background.
```

### Кольцо врага — призванный — `assets/ui/ring_enemy_summon.png`

```
Game UI avatar frame, square 512x512 px, transparent background, a single circular ring frame centered, the inside of the ring completely empty and transparent (a round window for a character portrait, inner diameter about 70% of the image), ring thickness about 12% of the width. Ring design: a thin wobbly iron ring wrapped in faint purple magical smoke, looking temporary and unstable. Dominant colour #9b59b6. Cozy hand-painted storybook illustration style, bold dark ink outlines, matching a set of fantasy game UI frames and buttons. Perfectly round, symmetrical, flat front view. No text, no letters, no character inside, no background.
```

**Негативный промпт для колец:**

```
text, letters, numbers, face, character, portrait inside, filled center, background, scenery, perspective, tilted, 3D render, photorealistic, watermark
```
