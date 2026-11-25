class_name CityMapUI
extends CanvasLayer

## Interactive Illustrated City of Souls Map & Memory Bag overlay (Godot 4.3+).
## AAA Parchment Chronicle & Antique Gold aesthetic (Genshin Impact / Zelda TotK / Pixar).
## Opens/closes via [M] or [Esc], supports instant fast travel to all 9 landmarks.

signal fast_travel_requested(district_id: String)
signal map_closed

const MAP_TEXTURE_PATH: String = "res://assets/ui/city_map_illustrated.jpg"
const DEFAULT_MAP_ASPECT: float = 1376.0 / 768.0

# --- Warm Chronicle & Antique Gold Palette ---
const COLOR_BACKDROP: Color = Color(0.055, 0.052, 0.072, 0.78)
const COLOR_BOOK_COVER: Color = Color(0.145, 0.112, 0.082, 0.96)
const COLOR_PARCHMENT: Color = Color(0.980, 0.950, 0.880, 0.96)
const COLOR_PARCHMENT_CARD: Color = Color(0.955, 0.914, 0.824, 0.94)
const COLOR_PARCHMENT_SOFT: Color = Color(0.968, 0.935, 0.855, 0.92)
const COLOR_PARCHMENT_EMPTY: Color = Color(0.945, 0.905, 0.818, 0.76)

const COLOR_GOLD_ANTIQUE: Color = Color(0.788, 0.627, 0.282, 1.0) # #C9A048
const COLOR_GOLD_BRIGHT: Color = Color(0.933, 0.780, 0.365, 1.0) # sunlit gold
const COLOR_GOLD_DEEP: Color = Color(0.604, 0.435, 0.118, 1.0) # #9A6F1E readable gold on parchment
const COLOR_GOLD_SOFT: Color = Color(0.788, 0.627, 0.282, 0.42)
const COLOR_GOLD_FILL: Color = Color(0.845, 0.680, 0.305, 0.96)
const COLOR_GOLD_FILL_HOVER: Color = Color(0.920, 0.762, 0.370, 1.0)
const COLOR_GOLD_FILL_PRESSED: Color = Color(0.710, 0.550, 0.225, 1.0)

const COLOR_INK_PRIMARY: Color = Color(0.118, 0.173, 0.282, 1.0) # #1E2C48 deep sapphire-chocolate
const COLOR_INK_SECONDARY: Color = Color(0.285, 0.258, 0.228, 1.0) # warm espresso ink
const COLOR_INK_MUTED: Color = Color(0.455, 0.405, 0.340, 0.90)
const COLOR_TEAL_ACCENT: Color = Color(0.115, 0.445, 0.545, 1.0) # river turquoise ink
const COLOR_IVORY_PIN: Color = Color(0.992, 0.968, 0.905, 0.97)
const COLOR_IVORY_PIN_HOVER: Color = Color(1.0, 0.985, 0.915, 1.0)
const COLOR_QUEST_PIN_FILL: Color = Color(0.945, 0.775, 0.295, 0.98)
const COLOR_PLAYER_TURQUOISE: Color = Color(0.260, 0.875, 0.965, 1.0)
const COLOR_PLAYER_CORE: Color = Color(0.965, 0.995, 1.0, 1.0)

const WORLD_MIN_X: float = -64.0
const WORLD_MAX_X: float = 64.0
const WORLD_MIN_Z: float = -285.0
const WORLD_MAX_Z: float = 60.0

const PIN_DIAMETER: float = 34.0
const PIN_RADIUS: float = 17.0
const PIN_WRAPPER_W: float = 168.0
const PIN_WRAPPER_H: float = 62.0

const DISTRICTS: Array = [
	{
		"id": "earth_mirror_temple",
		"name": "Верхний Храм Зеркала Земли",
		"short_name": "Храм Зеркала Земли",
		"uv": Vector2(0.50, 0.16),
		"pos": Vector3(0.0, 8.0, -280.0),
		"icon": "◆",
		"description": "Северная вершина Обители. В его сводах сияет Зеркало Земли — порог первого воплощения.",
	},
	{
		"id": "lantern_garden",
		"name": "Сад Небесных Фонариков",
		"short_name": "Сад Фонариков",
		"uv": Vector2(0.28, 0.34),
		"pos": Vector3(-34.0, 0.0, -138.0),
		"icon": "◈",
		"description": "Тихая терраса, откуда души отпускают к небу огни благодарности и светлой памяти.",
	},
	{
		"id": "mira_sanctuary",
		"name": "Дом Утешения Миры",
		"short_name": "Дом Миры",
		"uv": Vector2(0.69, 0.33),
		"pos": Vector3(34.0, 0.0, -138.0),
		"icon": "◈",
		"description": "Тёплая обитель Матери Утешения, где исцеляют усталость после возвращения с Земли.",
	},
	{
		"id": "orion_library",
		"name": "Библиотека Ориона",
		"short_name": "Библиотека Ориона",
		"uv": Vector2(0.36, 0.43),
		"pos": Vector3(-48.0, 0.0, -78.0),
		"icon": "◈",
		"description": "Своды Звёздных Свитков, где Архивариус Орион бережёт хроники всех прожитых и будущих жизней.",
	},
	{
		"id": "kronos_tower",
		"name": "Башня Времени Кроноса",
		"short_name": "Башня Кроноса",
		"uv": Vector2(0.62, 0.44),
		"pos": Vector3(48.0, 0.0, -78.0),
		"icon": "◈",
		"description": "Обсерватория золотых песочных часов, с балкона которой виден хрупкий бег земных вёсен.",
	},
	{
		"id": "central_boulevard",
		"name": "Мост Памяти и Бульвар",
		"short_name": "Мост Памяти",
		"uv": Vector2(0.50, 0.54),
		"pos": Vector3(0.0, 0.0, -32.0),
		"icon": "◈",
		"description": "Каменный мост через сияющую реку и Императорская Аллея, соединяющая кварталы с Храмом.",
	},
	{
		"id": "school_of_souls",
		"name": "Школа Юных Душ",
		"short_name": "Школа Юных Душ",
		"uv": Vector2(0.33, 0.68),
		"pos": Vector3(-42.0, 0.0, 8.0),
		"icon": "◈",
		"description": "Светлый дворик Наставницы Алатеи. Здесь души учатся слышать сердце и сплетают свой Чертёж.",
	},
	{
		"id": "quiet_lakes_park",
		"name": "Озёрный Парк Тишины",
		"short_name": "Озеро Тишины",
		"uv": Vector2(0.75, 0.76),
		"pos": Vector3(44.0, 0.0, 10.0),
		"icon": "◈",
		"description": "Зеркальная гладь Озера Тишины с лодочками. Вода бережно хранит несказанные слова любви.",
	},
	{
		"id": "awakening_plaza",
		"name": "Площадь Пробуждения",
		"short_name": "Площадь Пробуждения",
		"uv": Vector2(0.50, 0.83),
		"pos": Vector3(0.0, 0.0, 48.0),
		"icon": "◈",
		"description": "Южные врата Города Душ с фонтаном, где новорождённые души делают первый шаг под сводами Акаши.",
	},
]

# Smooth piecewise Z -> V anchor points matching the illustrated map's perspective
const Z_TO_V_KNOTS: Array = [
	Vector2(-285.0, 0.15),
	Vector2(-280.0, 0.16),
	Vector2(-138.0, 0.34),
	Vector2(-78.0, 0.44),
	Vector2(-32.0, 0.54),
	Vector2(10.0, 0.71),
	Vector2(48.0, 0.83),
	Vector2(60.0, 0.87),
]

var _is_open: bool = false
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
var _player_pos: Vector3 = Vector3(0.0, 0.0, 48.0)
var _time: float = 0.0
var _hovered_district_id: String = ""
var _active_target_district_id: String = ""

var _root_control: Control
var _map_texture_rect: TextureRect
var _map_canvas: Control
var _tooltip_panel: PanelContainer
var _tooltip_title: Label
var _tooltip_desc: Label
var _tooltip_hint: Label
var _quest_title_label: Label
var _quest_objective_label: Label
var _quest_district_label: Label
var _bag_count_label: Label
var _bag_list_vbox: VBoxContainer
var _close_button: Button
var _fade_tween: Tween
var _tooltip_tween: Tween

var _district_by_id: Dictionary = {}
var _district_nodes: Dictionary = {} # district_id -> Control wrapper
var _district_buttons: Dictionary = {} # district_id -> Button
var _district_nameplates: Dictionary = {} # district_id -> PanelContainer
var _pin_scale_tweens: Dictionary = {} # district_id -> Tween


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_index_districts()
	_build_ui()
	_connect_quest_manager()

	visible = false
	_root_control.modulate.a = 0.0
	_is_open = false


func _process(delta: float) -> void:
	if not _is_open:
		return
	_time += delta
	if _map_canvas != null:
		_map_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var code: Key = key_event.keycode
			var phys: Key = key_event.physical_keycode
			if code == KEY_M or phys == KEY_M or code == KEY_ESCAPE or phys == KEY_ESCAPE:
				close_map()
				get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Public API (100% preserved)
# ---------------------------------------------------------------------------

func open_map(player_pos: Vector3) -> void:
	_player_pos = player_pos
	if not _is_open:
		_previous_mouse_mode = Input.mouse_mode
	_is_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true

	refresh_quest_and_inventory()
	_update_district_node_positions()
	call_deferred("_update_district_node_positions")
	_update_district_button_styles()
	_set_hovered_district("")

	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()
	_root_control.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_root_control, "modulate:a", 1.0, 0.22) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if _map_canvas != null:
		_map_canvas.queue_redraw()


func close_map() -> void:
	if not _is_open:
		return
	_is_open = false
	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()
	if _tooltip_tween != null and _tooltip_tween.is_running():
		_tooltip_tween.kill()
	for tw_var: Variant in _pin_scale_tweens.values():
		var tw: Tween = tw_var as Tween
		if tw != null and tw.is_running():
			tw.kill()
	_pin_scale_tweens.clear()
	for btn_var: Variant in _district_buttons.values():
		var btn: Button = btn_var as Button
		if btn != null:
			btn.scale = Vector2.ONE
	visible = false
	_root_control.modulate.a = 0.0
	Input.mouse_mode = _previous_mouse_mode
	map_closed.emit()


func is_map_open() -> bool:
	return _is_open


func update_player_pos(player_pos: Vector3) -> void:
	_player_pos = player_pos
	if _is_open and _map_canvas != null:
		_map_canvas.queue_redraw()


func refresh_quest_and_inventory() -> void:
	var qm: Node = _get_quest_manager()
	if qm != null:
		var title: String = str(qm.call("get_current_quest_title"))
		var objective: String = str(qm.call("get_current_objective"))
		var target_district: String = str(qm.call("get_current_target_district"))
		_active_target_district_id = target_district
		_quest_title_label.text = title
		_quest_objective_label.text = objective
		_quest_district_label.text = "◈ Ориентир: %s" % _get_district_name(target_district)

		var items_var: Variant = qm.call("get_items")
		if items_var is Array:
			_rebuild_inventory_list(items_var as Array)
		else:
			_rebuild_inventory_list([])
	else:
		_active_target_district_id = "awakening_plaza"
		_quest_title_label.text = "Первые шаги в Городе Душ"
		_quest_objective_label.text = "Поговорите с Люми на Площади Пробуждения"
		_quest_district_label.text = "◈ Ориентир: Площадь Пробуждения"
		_rebuild_inventory_list([])

	_update_district_button_styles()
	if _map_canvas != null:
		_map_canvas.queue_redraw()


# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------

func _index_districts() -> void:
	_district_by_id.clear()
	for entry_var: Variant in DISTRICTS:
		if entry_var is Dictionary:
			var entry: Dictionary = entry_var as Dictionary
			var d_id: String = str(entry.get("id", ""))
			if not d_id.is_empty():
				_district_by_id[d_id] = entry


func _build_ui() -> void:
	_root_control = Control.new()
	_root_control.name = "CityMapRoot"
	_root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root_control)

	# Soft atmospheric twilight veil behind the Chronicle Book
	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = COLOR_BACKDROP
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root_control.add_child(backdrop)

	# Outer breathing margin (1280x720 -> 1236x680 spread)
	var outer_margin: MarginContainer = MarginContainer.new()
	outer_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_theme_constant_override("margin_left", 22)
	outer_margin.add_theme_constant_override("margin_right", 22)
	outer_margin.add_theme_constant_override("margin_top", 20)
	outer_margin.add_theme_constant_override("margin_bottom", 20)
	_root_control.add_child(outer_margin)

	# Outer Chronicle Book binding frame
	var book_frame: PanelContainer = PanelContainer.new()
	book_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	book_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_frame.add_theme_stylebox_override(
		"panel",
		_make_panel_style(COLOR_BOOK_COVER, COLOR_GOLD_ANTIQUE, 2, 12, Color(0.02, 0.015, 0.025, 0.65), 18)
	)
	outer_margin.add_child(book_frame)

	var book_margin: MarginContainer = MarginContainer.new()
	book_margin.add_theme_constant_override("margin_left", 12)
	book_margin.add_theme_constant_override("margin_right", 12)
	book_margin.add_theme_constant_override("margin_top", 12)
	book_margin.add_theme_constant_override("margin_bottom", 12)
	book_frame.add_child(book_margin)

	# 70% Illustrated Map | 30% Parchment Chronicle Sidebar
	var content_hbox: HBoxContainer = HBoxContainer.new()
	content_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 12)
	book_margin.add_child(content_hbox)

	_build_map_panel(content_hbox)
	_build_sidebar_panel(content_hbox)


func _build_map_panel(parent: HBoxContainer) -> void:
	# Thin antique-gold frame with soft drop shadow
	var map_frame: PanelContainer = PanelContainer.new()
	map_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_frame.size_flags_stretch_ratio = 0.70
	map_frame.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.92, 0.87, 0.76, 1.0), COLOR_GOLD_ANTIQUE, 2, 8, Color(0.04, 0.03, 0.02, 0.45), 10)
	)
	parent.add_child(map_frame)

	# Clip container so TextureRect & overlays respect the framed bounds cleanly
	var map_clip: Control = Control.new()
	map_clip.name = "MapClip"
	map_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_clip.clip_contents = true
	map_frame.add_child(map_clip)

	# Layer 0: Illustrated hand-painted parchment map
	_map_texture_rect = TextureRect.new()
	_map_texture_rect.name = "IllustratedMapTexture"
	_map_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_map_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(MAP_TEXTURE_PATH):
		var map_tex: Texture2D = load(MAP_TEXTURE_PATH) as Texture2D
		if map_tex != null:
			_map_texture_rect.texture = map_tex
	map_clip.add_child(_map_texture_rect)

	# Layer 1: Live custom-drawn canvas (vignette, gold filigree, quest beacon, player soul marker)
	_map_canvas = Control.new()
	_map_canvas.name = "MapCanvas"
	_map_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_canvas.clip_contents = true
	_map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_canvas.draw.connect(_on_map_canvas_draw)
	_map_canvas.resized.connect(_update_district_node_positions)
	map_clip.add_child(_map_canvas)

	# Layer 2: 9 Circular Antique-Gold Medallion Pins + Compact Warm Nameplates
	var pins_layer: Control = Control.new()
	pins_layer.name = "PinsLayer"
	pins_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	pins_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_clip.add_child(pins_layer)

	for entry_var: Variant in DISTRICTS:
		if not (entry_var is Dictionary):
			continue
		var entry: Dictionary = entry_var as Dictionary
		var d_id: String = str(entry.get("id", ""))
		var short_name: String = str(entry.get("short_name", d_id))
		var icon_glyph: String = str(entry.get("icon", "◈"))

		var node_wrapper: Control = Control.new()
		node_wrapper.name = "District_%s" % d_id
		node_wrapper.custom_minimum_size = Vector2(PIN_WRAPPER_W, PIN_WRAPPER_H)
		node_wrapper.size = Vector2(PIN_WRAPPER_W, PIN_WRAPPER_H)
		node_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pins_layer.add_child(node_wrapper)

		# Circular 34x34 golden medallion button centered horizontally in wrapper
		var btn: Button = Button.new()
		btn.text = icon_glyph
		btn.custom_minimum_size = Vector2(PIN_DIAMETER, PIN_DIAMETER)
		btn.size = Vector2(PIN_DIAMETER, PIN_DIAMETER)
		btn.position = Vector2((PIN_WRAPPER_W - PIN_DIAMETER) * 0.5, 0.0)
		btn.pivot_offset = Vector2(PIN_RADIUS, PIN_RADIUS)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_on_district_clicked.bind(d_id))
		btn.mouse_entered.connect(_on_district_mouse_entered.bind(d_id))
		btn.mouse_exited.connect(_on_district_mouse_exited.bind(d_id))
		node_wrapper.add_child(btn)

		# Compact warm parchment nameplate pill directly under the medallion
		var nameplate_center: CenterContainer = CenterContainer.new()
		nameplate_center.position = Vector2(0.0, PIN_DIAMETER + 4.0)
		nameplate_center.size = Vector2(PIN_WRAPPER_W, 24.0)
		nameplate_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node_wrapper.add_child(nameplate_center)

		var nameplate: PanelContainer = PanelContainer.new()
		nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nameplate.add_theme_stylebox_override(
			"panel",
			_make_panel_style(Color(0.985, 0.955, 0.885, 0.93), Color(0.788, 0.627, 0.282, 0.88), 1, 7, Color(0.12, 0.08, 0.03, 0.32), 4)
		)
		nameplate_center.add_child(nameplate)

		var np_margin: MarginContainer = MarginContainer.new()
		np_margin.add_theme_constant_override("margin_left", 7)
		np_margin.add_theme_constant_override("margin_right", 7)
		np_margin.add_theme_constant_override("margin_top", 2)
		np_margin.add_theme_constant_override("margin_bottom", 2)
		np_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nameplate.add_child(np_margin)

		var name_lbl: Label = Label.new()
		name_lbl.text = short_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		np_margin.add_child(name_lbl)

		_district_nodes[d_id] = node_wrapper
		_district_buttons[d_id] = btn
		_district_nameplates[d_id] = nameplate

	# Layer 3: Compact Legend Pill in top-right corner of the map
	var legend_panel: PanelContainer = PanelContainer.new()
	legend_panel.anchor_left = 1.0
	legend_panel.anchor_right = 1.0
	legend_panel.anchor_top = 0.0
	legend_panel.anchor_bottom = 0.0
	legend_panel.offset_left = -214.0
	legend_panel.offset_right = -14.0
	legend_panel.offset_top = 14.0
	legend_panel.offset_bottom = 42.0
	legend_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.980, 0.950, 0.880, 0.90), COLOR_GOLD_ANTIQUE, 1, 9, Color(0.10, 0.07, 0.03, 0.25), 5)
	)
	map_clip.add_child(legend_panel)

	var leg_margin: MarginContainer = MarginContainer.new()
	leg_margin.add_theme_constant_override("margin_left", 10)
	leg_margin.add_theme_constant_override("margin_right", 10)
	leg_margin.add_theme_constant_override("margin_top", 3)
	leg_margin.add_theme_constant_override("margin_bottom", 3)
	leg_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend_panel.add_child(leg_margin)

	var leg_hbox: HBoxContainer = HBoxContainer.new()
	leg_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	leg_hbox.add_theme_constant_override("separation", 12)
	leg_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leg_margin.add_child(leg_hbox)

	var leg_quest: Label = Label.new()
	leg_quest.text = "✦ Цель"
	leg_quest.add_theme_font_size_override("font_size", 11)
	leg_quest.add_theme_color_override("font_color", COLOR_GOLD_DEEP)
	leg_quest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leg_hbox.add_child(leg_quest)

	var leg_soul: Label = Label.new()
	leg_soul.text = "◈ Вы здесь"
	leg_soul.add_theme_font_size_override("font_size", 11)
	leg_soul.add_theme_color_override("font_color", COLOR_TEAL_ACCENT)
	leg_soul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leg_hbox.add_child(leg_soul)

	# Layer 4: Parchment-Gold Hover Tooltip Card anchored at top-left of the map
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.anchor_left = 0.0
	_tooltip_panel.anchor_right = 0.0
	_tooltip_panel.anchor_top = 0.0
	_tooltip_panel.anchor_bottom = 0.0
	_tooltip_panel.offset_left = 16.0
	_tooltip_panel.offset_right = 312.0
	_tooltip_panel.offset_top = 16.0
	_tooltip_panel.offset_bottom = 132.0
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.985, 0.958, 0.892, 0.96), COLOR_GOLD_ANTIQUE, 2, 10, Color(0.10, 0.07, 0.03, 0.38), 10)
	)
	map_clip.add_child(_tooltip_panel)

	var tip_margin: MarginContainer = MarginContainer.new()
	tip_margin.add_theme_constant_override("margin_left", 14)
	tip_margin.add_theme_constant_override("margin_right", 14)
	tip_margin.add_theme_constant_override("margin_top", 10)
	tip_margin.add_theme_constant_override("margin_bottom", 10)
	tip_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.add_child(tip_margin)

	var tip_vbox: VBoxContainer = VBoxContainer.new()
	tip_vbox.add_theme_constant_override("separation", 5)
	tip_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_margin.add_child(tip_vbox)

	_tooltip_title = Label.new()
	_tooltip_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_title.add_theme_font_size_override("font_size", 14)
	_tooltip_title.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
	_tooltip_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_vbox.add_child(_tooltip_title)

	var tip_div: ColorRect = ColorRect.new()
	tip_div.custom_minimum_size = Vector2(0.0, 1.0)
	tip_div.color = COLOR_GOLD_SOFT
	tip_div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_vbox.add_child(tip_div)

	_tooltip_desc = Label.new()
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc.add_theme_font_size_override("font_size", 11)
	_tooltip_desc.add_theme_color_override("font_color", COLOR_INK_SECONDARY)
	_tooltip_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_vbox.add_child(_tooltip_desc)

	_tooltip_hint = Label.new()
	_tooltip_hint.text = "✦ Кликните для быстрого перелёта"
	_tooltip_hint.add_theme_font_size_override("font_size", 11)
	_tooltip_hint.add_theme_color_override("font_color", COLOR_GOLD_DEEP)
	_tooltip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_vbox.add_child(_tooltip_hint)

	_tooltip_panel.visible = false
	_tooltip_panel.modulate.a = 0.0


func _build_sidebar_panel(parent: HBoxContainer) -> void:
	# Warm cream-parchment Chronicle page with antique-gold filigree border
	var side_panel: PanelContainer = PanelContainer.new()
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.size_flags_stretch_ratio = 0.30
	side_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(COLOR_PARCHMENT, COLOR_GOLD_ANTIQUE, 2, 8, Color(0.04, 0.03, 0.02, 0.40), 10)
	)
	parent.add_child(side_panel)

	var side_margin: MarginContainer = MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 18)
	side_margin.add_theme_constant_override("margin_right", 18)
	side_margin.add_theme_constant_override("margin_top", 16)
	side_margin.add_theme_constant_override("margin_bottom", 16)
	side_panel.add_child(side_margin)

	var side_vbox: VBoxContainer = VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 12)
	side_margin.add_child(side_vbox)

	# --- Chronicle Title Header ---
	var title_vbox: VBoxContainer = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 2)
	side_vbox.add_child(title_vbox)

	var title_label: Label = Label.new()
	title_label.text = "КАРТА ГОРОДА ДУШ"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 19)
	title_label.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
	title_vbox.add_child(title_label)

	var subtitle_label: Label = Label.new()
	subtitle_label.text = "Обитель Хроник Акаши · Быстрый перелёт"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 11)
	subtitle_label.add_theme_color_override("font_color", COLOR_INK_MUTED)
	title_vbox.add_child(subtitle_label)

	side_vbox.add_child(_make_ornate_divider())

	# --- Block 1: Current Quest ---
	var quest_header: Label = Label.new()
	quest_header.text = "✦  ТЕКУЩЕЕ ПОРУЧЕНИЕ"
	quest_header.add_theme_font_size_override("font_size", 12)
	quest_header.add_theme_color_override("font_color", COLOR_GOLD_DEEP)
	side_vbox.add_child(quest_header)

	var quest_card: PanelContainer = PanelContainer.new()
	quest_card.add_theme_stylebox_override(
		"panel",
		_make_panel_style(COLOR_PARCHMENT_CARD, COLOR_GOLD_ANTIQUE, 1, 8, Color(0.20, 0.14, 0.05, 0.12), 4)
	)
	side_vbox.add_child(quest_card)

	var quest_margin: MarginContainer = MarginContainer.new()
	quest_margin.add_theme_constant_override("margin_left", 13)
	quest_margin.add_theme_constant_override("margin_right", 13)
	quest_margin.add_theme_constant_override("margin_top", 10)
	quest_margin.add_theme_constant_override("margin_bottom", 10)
	quest_card.add_child(quest_margin)

	var quest_vbox: VBoxContainer = VBoxContainer.new()
	quest_vbox.add_theme_constant_override("separation", 6)
	quest_margin.add_child(quest_vbox)

	_quest_title_label = Label.new()
	_quest_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_title_label.add_theme_font_size_override("font_size", 15)
	_quest_title_label.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
	quest_vbox.add_child(_quest_title_label)

	_quest_objective_label = Label.new()
	_quest_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_objective_label.add_theme_font_size_override("font_size", 12)
	_quest_objective_label.add_theme_color_override("font_color", COLOR_INK_SECONDARY)
	quest_vbox.add_child(_quest_objective_label)

	_quest_district_label = Label.new()
	_quest_district_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_district_label.add_theme_font_size_override("font_size", 11)
	_quest_district_label.add_theme_color_override("font_color", COLOR_TEAL_ACCENT)
	quest_vbox.add_child(_quest_district_label)

	# Subtle golden hairline divider
	var mid_div: ColorRect = ColorRect.new()
	mid_div.custom_minimum_size = Vector2(0.0, 1.0)
	mid_div.color = COLOR_GOLD_SOFT
	side_vbox.add_child(mid_div)

	# --- Block 2: Memory Bag ---
	var bag_header_hbox: HBoxContainer = HBoxContainer.new()
	side_vbox.add_child(bag_header_hbox)

	var bag_header: Label = Label.new()
	bag_header.text = "✦  СУМКА ПАМЯТИ"
	bag_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_header.add_theme_font_size_override("font_size", 12)
	bag_header.add_theme_color_override("font_color", COLOR_GOLD_DEEP)
	bag_header_hbox.add_child(bag_header)

	var count_pill: PanelContainer = PanelContainer.new()
	count_pill.add_theme_stylebox_override(
		"panel",
		_make_panel_style(COLOR_PARCHMENT_CARD, COLOR_GOLD_SOFT, 1, 8, Color(0.0, 0.0, 0.0, 0.0), 0)
	)
	bag_header_hbox.add_child(count_pill)

	var count_margin: MarginContainer = MarginContainer.new()
	count_margin.add_theme_constant_override("margin_left", 8)
	count_margin.add_theme_constant_override("margin_right", 8)
	count_margin.add_theme_constant_override("margin_top", 1)
	count_margin.add_theme_constant_override("margin_bottom", 1)
	count_pill.add_child(count_margin)

	_bag_count_label = Label.new()
	_bag_count_label.text = "0"
	_bag_count_label.add_theme_font_size_override("font_size", 11)
	_bag_count_label.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
	count_margin.add_child(_bag_count_label)

	var bag_scroll: ScrollContainer = ScrollContainer.new()
	bag_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_vbox.add_child(bag_scroll)

	_bag_list_vbox = VBoxContainer.new()
	_bag_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bag_list_vbox.add_theme_constant_override("separation", 8)
	bag_scroll.add_child(_bag_list_vbox)

	# --- Block 3: Golden Close Button ---
	_close_button = Button.new()
	_close_button.text = "Закрыть карту [M / Esc]"
	_close_button.custom_minimum_size = Vector2(0.0, 42.0)
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_button.add_theme_font_size_override("font_size", 14)
	_close_button.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
	_close_button.add_theme_color_override("font_hover_color", COLOR_INK_PRIMARY)
	_close_button.add_theme_color_override("font_pressed_color", COLOR_IVORY_PIN)
	_close_button.add_theme_stylebox_override(
		"normal",
		_make_panel_style(COLOR_GOLD_FILL, COLOR_GOLD_DEEP, 2, 9, Color(0.22, 0.15, 0.04, 0.25), 5)
	)
	_close_button.add_theme_stylebox_override(
		"hover",
		_make_panel_style(COLOR_GOLD_FILL_HOVER, COLOR_GOLD_DEEP, 2, 9, Color(0.42, 0.30, 0.08, 0.32), 7)
	)
	_close_button.add_theme_stylebox_override(
		"pressed",
		_make_panel_style(COLOR_GOLD_FILL_PRESSED, COLOR_GOLD_DEEP, 2, 9, Color(0.15, 0.10, 0.03, 0.20), 2)
	)
	_close_button.pressed.connect(close_map)
	side_vbox.add_child(_close_button)


func _make_ornate_divider() -> HBoxContainer:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)

	var left_line: ColorRect = ColorRect.new()
	left_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left_line.custom_minimum_size = Vector2(0.0, 1.5)
	left_line.color = COLOR_GOLD_ANTIQUE
	hbox.add_child(left_line)

	var star: Label = Label.new()
	star.text = "✦"
	star.add_theme_font_size_override("font_size", 12)
	star.add_theme_color_override("font_color", COLOR_GOLD_ANTIQUE)
	hbox.add_child(star)

	var right_line: ColorRect = ColorRect.new()
	right_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_line.custom_minimum_size = Vector2(0.0, 1.5)
	right_line.color = COLOR_GOLD_ANTIQUE
	hbox.add_child(right_line)

	return hbox


func _rebuild_inventory_list(items: Array) -> void:
	for child: Node in _bag_list_vbox.get_children():
		child.queue_free()

	_bag_count_label.text = str(items.size())

	if items.is_empty():
		var empty_panel: PanelContainer = PanelContainer.new()
		empty_panel.add_theme_stylebox_override(
			"panel",
			_make_panel_style(COLOR_PARCHMENT_EMPTY, COLOR_GOLD_SOFT, 1, 8, Color(0.0, 0.0, 0.0, 0.0), 0)
		)
		_bag_list_vbox.add_child(empty_panel)

		var empty_margin: MarginContainer = MarginContainer.new()
		empty_margin.add_theme_constant_override("margin_left", 12)
		empty_margin.add_theme_constant_override("margin_right", 12)
		empty_margin.add_theme_constant_override("margin_top", 16)
		empty_margin.add_theme_constant_override("margin_bottom", 16)
		empty_panel.add_child(empty_margin)

		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Пока пусто — исследуйте кварталы Города Душ"
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", COLOR_INK_MUTED)
		empty_margin.add_child(empty_lbl)
		return

	for item_var: Variant in items:
		if not (item_var is Dictionary):
			continue
		var item: Dictionary = item_var as Dictionary
		var item_title: String = str(item.get("title", ""))
		var item_desc: String = str(item.get("description", ""))

		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override(
			"panel",
			_make_panel_style(COLOR_PARCHMENT_SOFT, COLOR_GOLD_ANTIQUE, 1, 8, Color(0.20, 0.14, 0.05, 0.10), 3)
		)
		_bag_list_vbox.add_child(card)

		var card_margin: MarginContainer = MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 10)
		card_margin.add_theme_constant_override("margin_right", 10)
		card_margin.add_theme_constant_override("margin_top", 8)
		card_margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(card_margin)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 9)
		card_margin.add_child(hbox)

		var star_lbl: Label = Label.new()
		star_lbl.text = "✦"
		star_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		star_lbl.add_theme_font_size_override("font_size", 15)
		star_lbl.add_theme_color_override("font_color", COLOR_GOLD_DEEP)
		hbox.add_child(star_lbl)

		var text_vbox: VBoxContainer = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(text_vbox)

		var title_lbl: Label = Label.new()
		title_lbl.text = item_title
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.add_theme_font_size_override("font_size", 13)
		title_lbl.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
		text_vbox.add_child(title_lbl)

		if not item_desc.is_empty():
			var desc_lbl: Label = Label.new()
			desc_lbl.text = item_desc
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.add_theme_font_size_override("font_size", 11)
			desc_lbl.add_theme_color_override("font_color", COLOR_INK_SECONDARY)
			text_vbox.add_child(desc_lbl)


# ---------------------------------------------------------------------------
# Map Projection (Exact UV alignment with STRETCH_KEEP_ASPECT_COVERED)
# ---------------------------------------------------------------------------

func _get_covered_image_rect(canvas_size: Vector2) -> Rect2:
	var tex_aspect: float = DEFAULT_MAP_ASPECT
	if _map_texture_rect != null and _map_texture_rect.texture != null:
		var tex_size: Vector2 = _map_texture_rect.texture.get_size()
		if tex_size.y > 1.0:
			tex_aspect = tex_size.x / tex_size.y

	if canvas_size.x < 1.0 or canvas_size.y < 1.0:
		return Rect2(Vector2.ZERO, canvas_size)

	var rect_aspect: float = canvas_size.x / canvas_size.y
	if rect_aspect < tex_aspect:
		var draw_h: float = canvas_size.y
		var draw_w: float = draw_h * tex_aspect
		var offset_x: float = (canvas_size.x - draw_w) * 0.5
		return Rect2(Vector2(offset_x, 0.0), Vector2(draw_w, draw_h))
	else:
		var draw_w: float = canvas_size.x
		var draw_h: float = draw_w / tex_aspect
		var offset_y: float = (canvas_size.y - draw_h) * 0.5
		return Rect2(Vector2(0.0, offset_y), Vector2(draw_w, draw_h))


func _uv_to_canvas(uv: Vector2, canvas_size: Vector2) -> Vector2:
	var img_rect: Rect2 = _get_covered_image_rect(canvas_size)
	return Vector2(
		img_rect.position.x + uv.x * img_rect.size.x,
		img_rect.position.y + uv.y * img_rect.size.y
	)


func _world_to_uv(world_pos: Vector3) -> Vector2:
	var nx: float = clampf((world_pos.x - WORLD_MIN_X) / (WORLD_MAX_X - WORLD_MIN_X), 0.0, 1.0)
	var u: float = lerpf(0.22, 0.78, nx)

	var z_clamped: float = clampf(world_pos.z, WORLD_MIN_Z, WORLD_MAX_Z)
	var v: float = 0.54
	var knot_count: int = Z_TO_V_KNOTS.size()
	if knot_count >= 2:
		var first_knot: Vector2 = Z_TO_V_KNOTS[0] as Vector2
		var last_knot: Vector2 = Z_TO_V_KNOTS[knot_count - 1] as Vector2
		if z_clamped <= first_knot.x:
			v = first_knot.y
		elif z_clamped >= last_knot.x:
			v = last_knot.y
		else:
			for i: int in range(knot_count - 1):
				var k0: Vector2 = Z_TO_V_KNOTS[i] as Vector2
				var k1: Vector2 = Z_TO_V_KNOTS[i + 1] as Vector2
				if z_clamped >= k0.x and z_clamped <= k1.x:
					var span: float = maxf(0.001, k1.x - k0.x)
					var t: float = (z_clamped - k0.x) / span
					v = lerpf(k0.y, k1.y, t)
					break

	return Vector2(u, v)


func _world_to_map(world_pos: Vector3, canvas_size: Vector2) -> Vector2:
	return _uv_to_canvas(_world_to_uv(world_pos), canvas_size)


func _get_district_canvas_pos(district_id: String, canvas_size: Vector2) -> Vector2:
	if _district_by_id.has(district_id):
		var entry: Dictionary = _district_by_id[district_id] as Dictionary
		var uv_var: Variant = entry.get("uv", Vector2(0.5, 0.5))
		if uv_var is Vector2:
			return _uv_to_canvas(uv_var as Vector2, canvas_size)
	return canvas_size * 0.5


func _update_district_node_positions() -> void:
	if _map_canvas == null:
		return
	var canvas_size: Vector2 = _map_canvas.size
	if canvas_size.x < 10.0 or canvas_size.y < 10.0:
		return

	for d_id_var: Variant in _district_nodes.keys():
		var d_id: String = str(d_id_var)
		var map_pt: Vector2 = _get_district_canvas_pos(d_id, canvas_size)
		var wrapper: Control = _district_nodes[d_id] as Control
		# Center the 34x34 circular medallion (top-center of wrapper) directly on map_pt
		wrapper.position = Vector2(map_pt.x - PIN_WRAPPER_W * 0.5, map_pt.y - PIN_RADIUS)


func _update_district_button_styles() -> void:
	var target_district: String = _active_target_district_id
	var qm: Node = _get_quest_manager()
	if qm != null:
		target_district = str(qm.call("get_current_target_district"))
		_active_target_district_id = target_district

	for d_id_var: Variant in _district_buttons.keys():
		var d_id: String = str(d_id_var)
		var btn: Button = _district_buttons[d_id] as Button
		var entry: Dictionary = _district_by_id.get(d_id, {}) as Dictionary
		var default_icon: String = str(entry.get("icon", "◈"))
		var is_target: bool = (d_id == target_district)

		if is_target:
			btn.text = "✦"
			btn.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
			btn.add_theme_color_override("font_hover_color", COLOR_INK_PRIMARY)
			btn.add_theme_color_override("font_pressed_color", COLOR_IVORY_PIN)
			btn.add_theme_stylebox_override(
				"normal",
				_make_panel_style(COLOR_QUEST_PIN_FILL, COLOR_IVORY_PIN, 2, 17, Color(0.55, 0.36, 0.05, 0.55), 8)
			)
			btn.add_theme_stylebox_override(
				"hover",
				_make_panel_style(Color(1.0, 0.85, 0.38, 1.0), COLOR_IVORY_PIN, 3, 17, Color(0.75, 0.52, 0.10, 0.65), 10)
			)
			btn.add_theme_stylebox_override(
				"pressed",
				_make_panel_style(COLOR_GOLD_DEEP, COLOR_GOLD_BRIGHT, 2, 17, Color(0.20, 0.14, 0.04, 0.45), 4)
			)
		else:
			btn.text = default_icon
			btn.add_theme_color_override("font_color", COLOR_GOLD_DEEP)
			btn.add_theme_color_override("font_hover_color", COLOR_INK_PRIMARY)
			btn.add_theme_color_override("font_pressed_color", COLOR_IVORY_PIN)
			btn.add_theme_stylebox_override(
				"normal",
				_make_panel_style(COLOR_IVORY_PIN, COLOR_GOLD_ANTIQUE, 2, 17, Color(0.18, 0.12, 0.04, 0.42), 5)
			)
			btn.add_theme_stylebox_override(
				"hover",
				_make_panel_style(COLOR_IVORY_PIN_HOVER, COLOR_GOLD_BRIGHT, 3, 17, Color(0.50, 0.35, 0.08, 0.52), 8)
			)
			btn.add_theme_stylebox_override(
				"pressed",
				_make_panel_style(COLOR_GOLD_ANTIQUE, COLOR_IVORY_PIN, 2, 17, Color(0.18, 0.12, 0.04, 0.35), 3)
			)

		if _district_nameplates.has(d_id):
			var nameplate: PanelContainer = _district_nameplates[d_id] as PanelContainer
			if is_target:
				nameplate.add_theme_stylebox_override(
					"panel",
					_make_panel_style(Color(1.0, 0.962, 0.835, 0.96), COLOR_GOLD_DEEP, 1, 7, Color(0.28, 0.18, 0.04, 0.38), 5)
				)
			else:
				nameplate.add_theme_stylebox_override(
					"panel",
					_make_panel_style(Color(0.985, 0.955, 0.885, 0.92), Color(0.788, 0.627, 0.282, 0.85), 1, 7, Color(0.12, 0.08, 0.03, 0.30), 4)
				)


# ---------------------------------------------------------------------------
# Live Custom Overlay Drawing (Vignette, Quest Beacon, Soul Marker)
# ---------------------------------------------------------------------------

func _on_map_canvas_draw() -> void:
	var s: Vector2 = _map_canvas.size
	if s.x < 10.0 or s.y < 10.0:
		return

	# 1. Delicate warm sepia edge vignette & antique-gold inner filigree corners
	_draw_soft_vignette(_map_canvas, s)
	_draw_corner_filigree(_map_canvas, s)

	# 2. Pulsing Golden Quest Halo around the active quest target pin
	var quest_pt: Vector2 = Vector2(-1000.0, -1000.0)
	var has_quest_pt: bool = false
	if not _active_target_district_id.is_empty() and _district_by_id.has(_active_target_district_id):
		quest_pt = _get_district_canvas_pos(_active_target_district_id, s)
		has_quest_pt = true
	else:
		var qm: Node = _get_quest_manager()
		if qm != null:
			var target_pos_var: Variant = qm.call("get_current_target_pos")
			if target_pos_var is Vector3:
				quest_pt = _world_to_map(target_pos_var as Vector3, s)
				has_quest_pt = true

	if has_quest_pt:
		var pulse_a: float = fmod(_time * 0.72, 1.0)
		var pulse_b: float = fmod(_time * 0.72 + 0.5, 1.0)
		var rad_a: float = lerpf(18.0, 46.0, pulse_a)
		var rad_b: float = lerpf(18.0, 46.0, pulse_b)
		var alpha_a: float = (1.0 - pulse_a) * 0.85
		var alpha_b: float = (1.0 - pulse_b) * 0.65

		_map_canvas.draw_circle(quest_pt, 26.0, Color(0.96, 0.80, 0.30, 0.22))
		_map_canvas.draw_arc(quest_pt, rad_a, 0.0, TAU, 40, Color(0.98, 0.84, 0.38, alpha_a), 2.6, true)
		_map_canvas.draw_arc(quest_pt, rad_b, 0.0, TAU, 40, Color(1.0, 0.92, 0.60, alpha_b), 1.8, true)

	# 3. Crisp golden hover highlight ring around hovered pin
	if not _hovered_district_id.is_empty() and _district_by_id.has(_hovered_district_id):
		var h_pt: Vector2 = _get_district_canvas_pos(_hovered_district_id, s)
		_map_canvas.draw_circle(h_pt, 24.0, Color(1.0, 0.92, 0.62, 0.22))
		_map_canvas.draw_arc(h_pt, 24.0, 0.0, TAU, 36, Color(0.96, 0.82, 0.38, 0.82), 2.0, true)

	# 4. Luminous Turquoise-White Player Soul Marker
	var p_pt: Vector2 = _world_to_map(_player_pos, s)
	var soul_pulse: float = 0.5 + 0.5 * sin(_time * 3.2)
	var ripple_t: float = fmod(_time * 0.9, 1.0)
	var ripple_r: float = lerpf(9.0, 24.0, ripple_t)
	var halo_r: float = lerpf(11.0, 15.5, soul_pulse)

	# Outer turquoise ripple + soft luminous aura
	_map_canvas.draw_arc(p_pt, ripple_r, 0.0, TAU, 32, Color(0.28, 0.90, 0.98, (1.0 - ripple_t) * 0.72), 1.8, true)
	_map_canvas.draw_circle(p_pt, halo_r, Color(0.22, 0.84, 0.96, 0.26))

	# High-contrast sapphire shadow backing so marker reads clearly on both parchment & turquoise river
	var outer_r: float = 8.5
	var outer_diamond: PackedVector2Array = PackedVector2Array([
		p_pt + Vector2(0.0, -outer_r),
		p_pt + Vector2(outer_r, 0.0),
		p_pt + Vector2(0.0, outer_r),
		p_pt + Vector2(-outer_r, 0.0),
	])
	_map_canvas.draw_colored_polygon(outer_diamond, Color(0.09, 0.20, 0.34, 0.88))

	var mid_r: float = 6.6
	var mid_diamond: PackedVector2Array = PackedVector2Array([
		p_pt + Vector2(0.0, -mid_r),
		p_pt + Vector2(mid_r, 0.0),
		p_pt + Vector2(0.0, mid_r),
		p_pt + Vector2(-mid_r, 0.0),
	])
	_map_canvas.draw_colored_polygon(mid_diamond, COLOR_PLAYER_TURQUOISE)
	_map_canvas.draw_circle(p_pt, 3.0, COLOR_PLAYER_CORE)
	_map_canvas.draw_polyline(
		PackedVector2Array([outer_diamond[0], outer_diamond[1], outer_diamond[2], outer_diamond[3], outer_diamond[0]]),
		COLOR_PLAYER_CORE,
		1.3,
		true
	)


func _draw_soft_vignette(canvas: Control, s: Vector2) -> void:
	var steps: int = 8
	var edge_depth: float = 28.0
	for i: int in range(steps):
		var frac: float = 1.0 - (float(i) / float(steps))
		var alpha: float = frac * frac * 0.16
		var col: Color = Color(0.16, 0.10, 0.04, alpha)
		var inset: float = (float(i) / float(steps)) * edge_depth
		var band: float = (edge_depth / float(steps)) + 0.5
		# Top, bottom, left, right subtle warm strips
		canvas.draw_rect(Rect2(Vector2(0.0, inset), Vector2(s.x, band)), col, true)
		canvas.draw_rect(Rect2(Vector2(0.0, s.y - inset - band), Vector2(s.x, band)), col, true)
		canvas.draw_rect(Rect2(Vector2(inset, 0.0), Vector2(band, s.y)), col, true)
		canvas.draw_rect(Rect2(Vector2(s.x - inset - band, 0.0), Vector2(band, s.y)), col, true)


func _draw_corner_filigree(canvas: Control, s: Vector2) -> void:
	var m: float = 8.0
	var arm: float = 20.0
	var gold: Color = Color(0.788, 0.627, 0.282, 0.68)
	var gold_soft: Color = Color(0.788, 0.627, 0.282, 0.28)

	# Delicate inner antique-gold hairline border
	canvas.draw_rect(Rect2(Vector2(m, m), Vector2(s.x - m * 2.0, s.y - m * 2.0)), gold_soft, false, 1.0)

	# Four corner brackets
	canvas.draw_line(Vector2(m, m), Vector2(m + arm, m), gold, 2.0)
	canvas.draw_line(Vector2(m, m), Vector2(m, m + arm), gold, 2.0)

	canvas.draw_line(Vector2(s.x - m, m), Vector2(s.x - m - arm, m), gold, 2.0)
	canvas.draw_line(Vector2(s.x - m, m), Vector2(s.x - m, m + arm), gold, 2.0)

	canvas.draw_line(Vector2(m, s.y - m), Vector2(m + arm, s.y - m), gold, 2.0)
	canvas.draw_line(Vector2(m, s.y - m), Vector2(m, s.y - m - arm), gold, 2.0)

	canvas.draw_line(Vector2(s.x - m, s.y - m), Vector2(s.x - m - arm, s.y - m), gold, 2.0)
	canvas.draw_line(Vector2(s.x - m, s.y - m), Vector2(s.x - m, s.y - m - arm), gold, 2.0)


# ---------------------------------------------------------------------------
# Interaction, Hover Animations & Signal Wiring
# ---------------------------------------------------------------------------

func _on_district_clicked(district_id: String) -> void:
	fast_travel_requested.emit(district_id)
	close_map()


func _on_district_mouse_entered(district_id: String) -> void:
	_animate_pin_scale(district_id, 1.16)
	_set_hovered_district(district_id)


func _on_district_mouse_exited(district_id: String) -> void:
	_animate_pin_scale(district_id, 1.0)
	if _hovered_district_id == district_id:
		_set_hovered_district("")


func _animate_pin_scale(district_id: String, target_scale: float) -> void:
	if not _district_buttons.has(district_id):
		return
	var btn: Button = _district_buttons[district_id] as Button
	if _pin_scale_tweens.has(district_id):
		var prev_tw: Tween = _pin_scale_tweens[district_id] as Tween
		if prev_tw != null and prev_tw.is_running():
			prev_tw.kill()
	var tw: Tween = create_tween()
	tw.tween_property(btn, "scale", Vector2(target_scale, target_scale), 0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pin_scale_tweens[district_id] = tw


func _set_hovered_district(district_id: String) -> void:
	_hovered_district_id = district_id
	if _tooltip_tween != null and _tooltip_tween.is_running():
		_tooltip_tween.kill()

	if district_id.is_empty() or not _district_by_id.has(district_id):
		_tooltip_panel.visible = false
		_tooltip_panel.modulate.a = 0.0
		if _map_canvas != null:
			_map_canvas.queue_redraw()
		return

	var entry: Dictionary = _district_by_id[district_id] as Dictionary
	_tooltip_title.text = str(entry.get("name", district_id))
	_tooltip_desc.text = str(entry.get("description", ""))
	_tooltip_panel.visible = true
	_tooltip_panel.modulate.a = 0.0
	_tooltip_tween = create_tween()
	_tooltip_tween.tween_property(_tooltip_panel, "modulate:a", 1.0, 0.14) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if _map_canvas != null:
		_map_canvas.queue_redraw()


func _connect_quest_manager() -> void:
	var qm: Node = _get_quest_manager()
	if qm == null:
		return
	if qm.has_signal("quest_changed") and not qm.is_connected("quest_changed", _on_quest_manager_updated):
		qm.connect("quest_changed", _on_quest_manager_updated)
	if qm.has_signal("inventory_changed") and not qm.is_connected("inventory_changed", _on_inventory_updated):
		qm.connect("inventory_changed", _on_inventory_updated)


func _on_quest_manager_updated(_quest_id: String, _title: String, _objective: String, _target_pos: Vector3) -> void:
	if _is_open:
		refresh_quest_and_inventory()


func _on_inventory_updated(_items: Array[Dictionary]) -> void:
	if _is_open:
		refresh_quest_and_inventory()


func _get_quest_manager() -> Node:
	return get_node_or_null("/root/QuestManager")


func _get_district_name(district_id: String) -> String:
	if _district_by_id.has(district_id):
		var entry: Dictionary = _district_by_id[district_id] as Dictionary
		return str(entry.get("name", district_id))
	return district_id


func _make_panel_style(
	bg_color: Color,
	border_color: Color,
	border_w: int,
	radius: int,
	shadow_col: Color = Color(0.0, 0.0, 0.0, 0.0),
	shadow_sz: int = 0
) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.border_width_left = border_w
	sb.border_width_right = border_w
	sb.border_width_top = border_w
	sb.border_width_bottom = border_w
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	if shadow_sz > 0 and shadow_col.a > 0.0:
		sb.shadow_color = shadow_col
		sb.shadow_size = shadow_sz
		sb.shadow_offset = Vector2(0.0, 2.0)
	return sb
