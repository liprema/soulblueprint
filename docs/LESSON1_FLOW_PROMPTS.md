# Урок 1: «Было всё, кроме времени» — Промпты для Google Flow и инструкция без терминала

Этот документ содержит готовые кинематографичные промпты для генерации 4 коротких видеосцен Урока 1 в **Google Flow** (Veo) и пошаговую инструкцию, как добавить их в проект **SoulBlueprint** без использования командной строки.

> **Важно:** Если видеофайлы ещё не добавлены в папку `assets/videos/lesson1/`, игра автоматически и плавно покажет атмосферные художественные сцены-заменители, поэтому Урок 1 полностью проходим уже сейчас. Как только вы положите `.ogv`-файлы по указанным ниже путям, игра подхватит их сама.

---

## Пошаговая инструкция (без терминала)

### Шаг 1. Сгенерируйте 4 клипа в Google Flow
1. Откройте **Google Flow** в браузере и создайте новый проект.
2. В настройках генерации выберите:
   - **Соотношение сторон (Aspect Ratio):** `16:9` (Landscape / широкоэкранный).
   - **Длительность:** `6–8 секунд` (один плавный кинематографичный план без резких склеек).
   - **Модель:** Veo 2 / Veo 3 (режим максимального качества).
3. По очереди скопируйте каждый из 4 промптов ниже (английский текст в блоке кода) и запустите генерацию.
4. Выберите лучший дубль для каждой сцены — без артефактов, лишнего текста и резких движений камеры — и скачайте файл в формате `.mp4`.

### Шаг 2. Переведите `.mp4` в формат `.ogv` (Ogg Theora) для Godot 4
Godot 4 воспроизводит встроенное видео в формате **Ogg Theora (`.ogv`)**. Перевести файлы можно без терминала любым из двух способов:

- **Способ А (онлайн в браузере, 1 минута):**
  1. Откройте любой бесплатный конвертер, например **CloudConvert** (`cloudconvert.com/mp4-to-ogv`) или **Convertio** (`convertio.co/mp4-ogv`).
  2. Загрузите 4 скачанных `.mp4`-файла.
  3. Выберите целевой формат **`OGV`** (если доступны настройки видео: разрешение `1280x720` или `1920x1080`, 24–30 fps, звук можно оставить или убрать — в игре звучит собственный саундтрек).
  4. Нажмите «Конвертировать» и скачайте готовые `.ogv`-файлы.

- **Способ Б (локально через программу VLC):**
  1. Откройте **VLC Media Player** → меню **Медиа → Конвертировать / Сохранить…**
  2. Добавьте `.mp4`-файл → нажмите **Конвертировать / Сохранить**.
  3. В поле **Профиль** выберите **Video – Theora + Vorbis (OGG)**.
  4. Укажите имя выходного файла с расширением `.ogv` и нажмите **Начать**.

### Шаг 3. Положите файлы в папку проекта с точными именами
Откройте папку проекта `soulblueprint` в Проводнике / Finder, перейдите в папку `assets/videos/lesson1/` (если папки `lesson1` ещё нет — просто создайте её обычным кликом правой кнопки мыши) и переименуйте файлы **в точности** так:

| № | Сцена | Точный путь и имя файла |
|---|---|---|
| 1 | Дом до встречи — тихая зима между двумя | `assets/videos/lesson1/01_winter_home.ogv` |
| 2 | Семь вёсен — сад, смех и мыльные пузыри | `assets/videos/lesson1/02_seven_springs.ogv` |
| 3 | Восьмая зима — тихое прощание у окна | `assets/videos/lesson1/03_eighth_winter.ogv` |
| 4 | Две руки в темноте — начало исцеления | `assets/videos/lesson1/04_two_hands_darkness.ogv` |

После копирования просто откройте проект в Godot — редактор сам импортирует видео за пару секунд.

---

## Кинематографичные промпты для Google Flow (16:9)

Единая художественная стилистика всех 4 сцен: поэтичная взрослая анимация в духе **Макото Синкая**, **Violet Evergarden (Kyoto Animation)** и акварельной мягкости **GRIS** — деликатный свет, естественное дыхание воздуха, сдержанная эмоциональность, никаких надписей и логотипов.

---

### Клип 1 — `assets/videos/lesson1/01_winter_home.ogv`
**Смысл сцены:** Квартира с погашенным теплом. Отец прячется в бумагах под лампой, мать в тишине стоит у зимнего окна, пряча озябшие пальцы в рукавах. Между ними — целая зима.

```text
Cinematic anime film still brought to life in the style of Makoto Shinkai and Violet Evergarden, 16:9 widescreen, delicate painterly brushwork and atmospheric lighting. Inside a quiet, dimly lit modern apartment during a pale winter dusk, snow drifting softly outside tall windows. In the foreground by the frosted glass, a young woman in a soft wool sweater stands alone, gently tucking her cold fingers into her sleeves as she gazes out in silence. Across the hushed room in cool blue-grey shadows, her husband sits at a desk buried in papers under a single muted desk lamp, shoulders heavy with unspoken fatigue. Two untouched tea cups rest on the table between them. Slow, contemplative camera drift from left to right, floating dust motes in cold winter twilight, restrained melancholy, poetic stillness, 24fps film grain, no text, no subtitles, no watermark.
```

---

### Клип 2 — `assets/videos/lesson1/02_seven_springs.ogv`
**Смысл сцены:** Семь вёсен абсолютного счастья. Залитый золотым солнцем сад, мама кружит ребёнка, в воздухе дрожат мыльные пузыри, отец смеётся рядом, забыв о времени и делах.

```text
Cinematic anime film scene in the style of Makoto Shinkai and Violet Evergarden with soft watercolor warmth inspired by GRIS, 16:9 widescreen. A sun-drenched lush backyard garden in late spring golden hour, glowing lens flare filtering through blossoming apple trees and swaying grass. A radiant mother spins joyfully with her small seven-year-old child in her arms, both laughing freely as iridescent soap bubbles float and shimmer across the warm sunlight. Nearby on the grass, the father sits with an abandoned open notebook beside him, smiling warmly with soft tears of happiness as he reaches up to catch a bubble. Golden pollen and light petals drifting on a gentle breeze, smooth floating tracking shot, luminous amber and emerald palette, deeply tender and nostalgic atmosphere, 24fps, no text, no watermark.
```

---

### Клип 3 — `assets/videos/lesson1/03_eighth_winter.ogv`
**Смысл сцены:** Восьмая зима. Тихая, светлая, бережная сцена прощания: за окном падает медленный снег, маленькая детская ладонь мягко держит пальцы родителей, на стене — детские рисунки солнца.

```text
Cinematic anime film scene in the style of Violet Evergarden and Makoto Shinkai, 16:9 widescreen, tender and restrained emotional realism. A quiet, softly lit bedroom on a snowy winter afternoon, pale silver daylight and a faint warm golden glow entering through sheer curtains as slow snowflakes fall outside. Gentle close-up and slow pull-back on a small child's hand resting peacefully atop a soft cream blanket, delicately holding the fingers of both the mother's and father's trembling hands. In the soft-focus background, faint pastel crayon drawings of a sun and three stick figures are taped to the wallpaper. Peaceful, dignified stillness, floating specks of light in the cold air, soft shallow depth of field, deeply moving without harshness, 24fps, no text, no watermark.
```

---

### Клип 4 — `assets/videos/lesson1/04_two_hands_darkness.ogv`
**Смысл сцены:** Ночь после прощания. В тихом полумраке пустой комнаты рука отца впервые за долгие годы находит дрожащую руку матери и бережно сжимает её, не отпуская; за окном намечается первый тёплый отблеск рассвета.

```text
Cinematic anime film scene in the style of Makoto Shinkai and GRIS, 16:9 widescreen, painterly chiaroscuro lighting. Deep indigo twilight inside a quiet bedroom after midnight, gentle moonlight falling across a wooden floor and illuminating faint child's drawings on the wall. Close-up on a dark wooden windowsill and the edge of an empty bed: a woman's trembling hand rests alone in cool moonlight; slowly, the father's weathered hand enters the frame, tenderly finds her fingers in the darkness, and gently clasps them without letting go. As their hands interlace, a subtle, delicate thread of warm golden dawn light begins to touch the horizon outside the window, reflecting softly on their joined palms. Ultra-slow intimate camera push-in, poetic silence, healing through grief, 24fps filmic texture, no text, no watermark.
```

---

## Советы по единому визуальному стилю
- Если Google Flow предлагает прикрепить **референс-кадр (Ingredients / Reference Image)**, используйте удачный кадр из **Клипа 2** или **Клипа 1**, чтобы лица и одежда родителей выглядели максимально похоже во всех четырёх сценах.
- Не добавляйте в промпты диалоги или закадровый голос: все реплики и субтитры Урока 1 отображаются самой игрой синхронно с музыкой.
