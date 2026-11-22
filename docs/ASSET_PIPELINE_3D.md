# 3D Asset Replacement Pipeline (`.glb`) — SoulBlueprint (Godot 4.3 Forward Plus)

Краткое руководство по замене процедурной архитектуры Пролога (`AkashaArchitectureBuilder`) и модели Искры (`Player3D`) на высокодетализированные `.glb`-ассеты из **Blender**, **Meshy** или **Tripo**.

---

## 1. Структура папок `assets/models/`

Все 3D-модели хранятся в бинарном формате **glTF 2.0 (`.glb`)** со встроенными PBR-текстурами:

```text
assets/models/
├── architecture/
│   ├── monolith_plaza.glb       # Стартовая площадь-мост (z = 24..46, y = 0)
│   ├── viaduct_arch.glb         # Один арочный пролёт виадука (~21.67 м)
│   ├── temple_island.glb        # Парящий остров-храм (радиус ~8.4 м, верхняя плита y = 0)
│   └── akasha_cathedral.glb     # Колоссальный Собор Акаши (z = -280)
├── characters/
│   └── spark.glb                # Модель Искры (замена процедурной сферы/силуэта Player3D)
└── props/
    └── stone_lantern.glb        # Интерактивный Каменный Фонарь (Sprint 2)
```

---

## 2. Требования к экспорту (Blender / Meshy / Tripo)

| Параметр | Значение |
| :--- | :--- |
| **Формат** | `.glb` (glTF Binary) |
| **Масштаб** | `1 единица = 1 метр`, `Apply Scale` (`Ctrl+A` в Blender) обязателен |
| **Ориентация** | `+Y Up`, `-Z Forward` (стандарт glTF 2.0 / Godot 4.3) |
| **Точка опоры (Origin)** | Для площадок и островов — центр верхней ходовой плиты (`y = 0`), чтобы игрок и фонари стояли точно на поверхности |
| **Материалы** | PBR (`Base Color`, `Roughness`, `Metallic`, `Normal`, `Emission`). Для золотой филиграни `#F6D36B` используйте отдельную `Emission`-карту |
| **Коллизии из Blender** | Добавьте суффикс `-col` к имени меша (или `-colonly` для невидимого упрощённого коллайдера) — Godot 4.3 автоматически создаст `StaticBody3D` |

### Советы для Meshy / Tripo
1. Скачивайте модель в формате **`.glb`** (PBR textures enabled).
2. Перед переносом в Godot откройте `.glb` в **Blender**:
   - Выровняйте Origin по нижней/верхней опорной плоскости (`y = 0`).
   - Приведите габариты к метрам (например, остров ~16–17 м в диаметре, пролёт виадука ~21.7 м).
   - Уменьшите полигонаж при необходимости (`Decimate` / ретопология: 5k–25k треугольников для модулей, до 60k для Собора, 3k–10k для Искры).
   - Экспортируйте через `File → Export → glTF 2.0 (.glb)` с включённым **+Y Up** и **Apply Modifiers**.

---

## 3. Замена процедурных модулей архитектуры (Zero-Code Drop-In)

Скрипт [`scripts/akasha_architecture_builder.gd`](../scripts/akasha_architecture_builder.gd) уже поддерживает автоматическую подмену процедурных блоков через `@export`-свойства:

- `plaza_model_path` → `res://assets/models/architecture/monolith_plaza.glb`
- `viaduct_arch_model_path` → `res://assets/models/architecture/viaduct_arch.glb`
- `temple_island_model_path` → `res://assets/models/architecture/temple_island.glb`
- `cathedral_model_path` → `res://assets/models/architecture/akasha_cathedral.glb`

### Как заменить модуль
1. Положите `.glb` по соответствующему пути (или укажите свой путь в Инспекторе на узле `AkashaArchitecture` в сцене `scenes/environment/akasha_architecture.tscn`).
2. При запуске `AkashaArchitectureBuilder`:
   - Автоматически обнаружит файл через `ResourceLoader.exists(...)` и инстанцирует его вместо процедурной геометрии.
   - Сохранит базовые `StaticBody3D`-коллайдеры для стартовой площади и островов, а для Собора оставит анимированные **3 вращающихся кольца Астролябии** и координаты фонарей `get_lantern_anchor_positions()`.
3. Чтобы вернуться к процедурной версии — удалите/переименуйте `.glb` или очистите путь в Инспекторе.

---

## 4. Замена модели Искры (Spark / `Player3D`)

1. Поместите `spark.glb` в `res://assets/models/characters/spark.glb`.
2. Откройте сцену 3D-игрока (`Player3D`):
   - Перетащите `spark.glb` как дочерний узел внутрь визуального контейнера (например, `VisualRoot` / `ModelPivot`), оставив корневой `CharacterBody3D`, `CollisionShape3D` и камеру без изменений.
   - Скройте или удалите временный процедурный `MeshInstance3D` (сферу/капсулу).
   - Убедитесь, что модель смотрит вдоль `-Z` (при необходимости поверните `spark` на `180°` по оси `Y`).
3. Если в `.glb` есть скелетные анимации (`Idle`, `Glide`, `Fly`, `Dash`), нажмите правой кнопкой по `spark` → **Editable Children** и подключите `AnimationPlayer` / `AnimationTree` в скрипте игрока.

---

## 5. Проверка после импорта в Godot 4.3 (Forward Plus)

- **Вкладка Import** (двойной клик по `.glb`):
  - При необходимости включите `Meshes → Light Baking = Static` и `Generate LODs = true`.
  - Для ручной настройки материалов (например, усиления HDR-свечения золота `#F6D36B` до `emission_energy_multiplier = 1.6` для Glow/Bloom в Forward Plus) нажмите **Advanced… → Materials → Extract Materials** в `assets/materials/`.
- **Цветовая палитра (Shot 4 Art Deco Celestial)**:
  - Глубокий ночной индиго: `#0A1F44` / `#0E234D`
  - Средний индиго и кобальт: `#122D6B` / `#1E4B9A`
  - Светящееся золото филиграни: `#F6D36B` (`Emission Energy ≈ 1.4–1.8`)
  - Эфирный циан Наставников: `#58C4FF`
