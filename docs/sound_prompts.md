# Звуки и музыка: список и промпты для генерации

Пока настоящих файлов нет, игра играет **временные звуки**, синтезированные в коде
(`scripts/core/sfx.gd`). Как только файл появляется в папке, игра берёт его вместо временного.

## Как класть файлы

| Что | Куда | Формат |
|---|---|---|
| Звуки | `assets/sfx/<id>.ogg` | OGG Vorbis (можно `.wav` или `.mp3`), моно, 44.1 кГц, без тишины в начале, пик около −1 дБ |
| Варианты звука | `assets/sfx/<id>_2.ogg`, `<id>_3.ogg`… | Игра выбирает случайный — удары и крик не повторяются одинаково |
| Музыка | `assets/music/<id>.ogg` | OGG Vorbis, стерео, **бесшовная петля** (конец переходит в начало) |

Громкость каждого звука уже подстроена в коде (`Sfx.MIX`), так что файлы лучше делать нормализованными,
без «тихих» и «громких» версий. Общую громкость, звуки и музыку игрок меняет в «Настройках».

Генераторы: для звуков подойдут ElevenLabs Sound Effects, Stable Audio или похожие; для крика
«Я кастую!» — генератор голоса или живой актёр; для музыки — Suno, Udio или Stable Audio.
Промпты написаны на английском: так генераторы понимают их лучше. Общий стиль для всех звуков —
**уютная сказочная фэнтези-игра со старыми ворчливыми волшебниками**, звуки чуть мультяшные,
тёплые, без жёсткой реалистичной жестокости.

## Звуки

| id | Где звучит | Длина | Промпт |
|---|---|---|---|
| `chip_draw` | Вытянута фишка стихии | 0.2–0.3 с | `A single wooden game token pulled out of a cloth bag and clicked onto a wooden table, short, warm, cozy board game sound, close mic` |
| `chip_chaos` | Вытянута чёрная фишка Хаоса | 0.6–0.8 с | `A dark magical token drawn from a bag, ominous low whoosh with a slightly comic descending wobble, cozy fantasy game, short` |
| `chip_burn` | Фишку сожгли и тянут новую (Пиромант, Муза) | 0.4–0.6 с | `A small magical token bursting into a puff of flame and crackle, then a soft click of a new token, cartoon fantasy, short` |
| `cast_shout` | Каст — крик «Я кастую!» | 0.8–1.5 с | **Голос:** старый ворчливый волшебник громко и гордо кричит по-русски «Я кастую!», чуть хрипло, с комичным пафосом, сразу за криком — короткий звон магии. Сделать 3–5 вариантов (`cast_shout`, `cast_shout_2`…), разные интонации: торжественно, раздражённо, неуверенно. Без голоса — промпт для звона: `Short magical spell cast whoosh with bright sparkling chime tail, whimsical fantasy, cozy` |
| `hit` | Урон по участнику | 0.2–0.3 с | `Cartoon fantasy impact, soft thump with a small magical crackle, not violent, short, game UI hit sound` |
| `hit_big` | Крупный урон (3+) | 0.4–0.6 с | `Heavy cartoon fantasy impact, deep thump with magical burst and debris sprinkle, satisfying, not gory, short` |
| `heal` | Лечение | 0.4–0.6 с | `Gentle healing spell, soft rising harp arpeggio with warm shimmer, cozy fantasy game` |
| `shield` | Щит или Укрепление поглощает урон | 0.3–0.5 с | `Magical shield blocking a hit, glassy metallic ping with a soft dome hum, fantasy game, short` |
| `status_bad` | На кого-то наложен вредный эффект | 0.3 с | `Short comic negative magic sting, two descending wobbly notes with a puff, cozy fantasy UI` |
| `status_good` | На кого-то наложен полезный эффект | 0.3 с | `Short positive magic sting, two rising bright notes with a sparkle, cozy fantasy UI` |
| `down` | Участник выбыл | 0.6–1.0 с | `Cartoon character knocked out, descending slide whistle into a soft thud and a few dizzy chirps, comic fantasy, not sad` |
| `enemy_special` | Особая атака предводителя или босса | 0.5–0.8 с | `Goblin-like creature roaring a battle cry before a special attack, gruff comic growl with a whoosh, fantasy game` |
| `summon` | Появился новый враг (призыв, слизень, крыса) | 0.3–0.5 с | `Small creature pops into existence, cartoon pop with a squeak and dust puff, fantasy game` |
| `luck` | Сработала удача (рассеяние, двойная благодать, шкала удачи) | 0.5 с | `Lucky magical sparkle, quick twinkling chimes like a four-leaf clover glowing, whimsical fantasy` |
| `victory` | Победа в бою | 1.5–2.5 с | `Short triumphant fantasy fanfare on brass and strings, cheerful, slightly comic, cozy RPG victory jingle` |
| `defeat` | Поражение | 1.5–2.5 с | `Short sad but comic fantasy defeat jingle, descending bassoon and strings, gentle, not dramatic` |
| `book_open` | Открыта книга, настройки | 0.4–0.6 с | `An old heavy spellbook opening, leather creak and pages rustling, cozy library` |
| `map_step` | Выбрана дорога на карте | 0.5 с | `Two footsteps on a dirt road with a soft map paper rustle, cozy fantasy travel` |
| `loot` | Взята добыча на привале | 0.3–0.5 с | `Picking up loot, small coin jingle with a soft magical twinkle, cozy RPG` |
| `trophy` | Получен трофей босса | 1.0–1.5 с | `Short heroic reward sting, bright brass and bell, treasure acquired, cozy fantasy RPG` |
| `ui_click` | Нажатия (зарезервировано) | 0.05–0.1 с | `Soft wooden UI click, cozy fantasy game button` |

## Музыка

Музыка играет по кругу на своём экране. Пока файлов нет, игра молчит.

| id | Где | Длина петли | Промпт |
|---|---|---|---|
| `menu` | Выбор отряда | 1–2 мин | `Cozy fantasy tavern music, warm acoustic lute, fiddle and soft flute, slow and friendly, old wizards telling stories by the fire, seamless loop, instrumental` |
| `map` | Карта с развилками | 1–2 мин | `Light adventurous fantasy travel music, pizzicato strings, flute and hand drum, curious and cheerful, seamless loop, instrumental` |
| `battle` | Обычный бой | 1.5–2 мин | `Playful fantasy battle music, bouncy orchestral strings, brass stabs and bassoon, comic but energetic, turn-based RPG, seamless loop, instrumental` |
| `boss` | Бой с боссом | 1.5–2 мин | `Epic yet slightly comic fantasy boss battle music, big drums, low brass, choir hits, mischievous woodwinds, turn-based RPG, seamless loop, instrumental` |
| `camp` | Привал | 1–2 мин | `Calm campfire music at night, soft acoustic guitar, crackling ambience, gentle harp, peaceful rest after battle, seamless loop, instrumental` |

## Что проверить после загрузки

- Звук не начинается с тишины (иначе он запаздывает за действием).
- Музыка зациклена без щелчка на стыке.
- Громкость примерно одинаковая у всех файлов; в «Настройках» есть кнопка «Проверить звук».
