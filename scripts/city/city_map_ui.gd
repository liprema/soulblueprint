class_name CityMapUI
extends CanvasLayer

## Interactive City of Souls Map & Memory Bag overlay for SoulBlueprint (Godot 4.3+).
## Palette: noble sapphire + antique gold + warm ivory (Sky / Genshin / Pixar Soul).
## Opens/closes via [M] or [Esc], supports instant fast travel to all 9 districts.

signal fast_travel_requested(district_id: String)
signal map_closed

const COLOR_BACKDROP: Color = Color(0.025, 0.055, 0.125, 0.80)
const COLOR_SAPPHIRE_DEEP: Color = Color(0.055, 0.102, 0.208, 0.97)
const COLOR_SAPPHIRE_PANEL: Color = Color(0.075, 0.138, 0.275, 0.96)
const COLOR_SAPPHIRE_CARD: Color = Color(0.098, 0.176, 0.338, 0.92)
const COLOR_SAPPHIRE_CANVAS: Color = Color(0.043, 0.086, 0.184, 1.0)
const COLOR_GOLD: Color = Color(0.875, 0.725, 0.376, 1.0) # #DFB960 antique gold
const COLOR_GOLD_BRIGHT: Color = Color(0.969, 0.855, 0.525, 1.0) # #F7DA86 sunlit gold
const COLOR_GOLD_SOFT: Color = Color(0.875, 0.725, 0.376, 0.24)
const COLOR_GOLD_GRID: Color = Color(0.875, 0.725, 0.376, 0.11)
const COLOR_IVORY: Color = Color(0.988, 0.973, 0.933, 1.0) # warm ivory
const COLOR_IVORY_MUTED: Color = Color(0.835, 0.845, 0.895, 0.82)
const COLOR_PLAYER_CYAN: Color = Color(0.455, 0.847, 1.0, 1.0) # luminous soul azure
const COLOR_WATER_CANAL: Color = Color(0.185, 0.445, 0.685, 0.52)
const COLOR_WATER_SHIMMER: Color = Color(0.475, 0.765, 0.945, 0.38)
const COLOR_ROAD_GOLD: Color = Color(0.875, 0.725, 0.376, 0.46)
const COLOR_ROAD_HIGHLIGHT: Color = Color(0.969, 0.855, 0.525, 0.22)

const WORLD_MIN_X: float = -64.0
const WORLD_MAX_X: float = 64.0
const WORLD_MIN_Z: float = -302.0
const WORLD_MAX_Z: float = 72.0

const DISTRICTS: Array = [
	{
		"id": "awakening_plaza",
		"name": "Площадь Пробуждения",
		"short_name": "Площадь Пробуждения",
		"pos": Vector3(0.0, 0.0, 48.0),
		"description": "Южные врата Города Душ, где новорождённые души делают первый шаг под сводами Акаши.",
	},
	{
		"id": "school_of_souls",
		"name": "Школа Юных Душ",
		"short_name": "Школа Юных Душ",
		"pos": Vector3(-42.0, 0.0, 8.0),
		"description": "Светлый дворик Наставницы Алатеи. Здесь души учатся слышать сердце и сплетают свой Чертёж.",
	},
	{
		"id": "quiet_lakes_park",
		"name": "Озёрный Парк Тишины",
		"short_name": "Парк Тишины",
		"pos": Vector3(44.0, 0.0, 10.0),
		"description": "Зеркальная гладь Озера Тишины среди белых ив. Вода бережно хранит несказанные слова любви.",
	},
	{
		"id": "central_boulevard",
		"name": "Центральный Бульвар",
		"short_name": "Центральный Бульвар",
		"pos": Vector3(0.0, 0.0, -32.0),
		"description": "Сердце Города и Императорская Аллея, соединяющая кварталы памяти с северным Храмом.",
	},
	{
		"id": "orion_library",
		"name": "Библиотека Ориона",
		"short_name": "Библиотека Ориона",
		"pos": Vector3(-48.0, 0.0, -78.0),
		"description": "Своды Звёздных Свитков, где Архивариус Орион бережёт хроники всех прожитых и будущих жизней.",
	},
	{
		"id": "kronos_tower",
		"name": "Башня Времени Кроноса",
		"short_name": "Башня Кроноса",
		"pos": Vector3(48.0, 0.0, -78.0),
		"description": "Обсерватория золотых песочных часов, с балкона которой виден хрупкий бег земных вёсен.",
	},
	{
		"id": "lantern_garden",
		"name": "Сад Небесных Фонариков",
		"short_name": "Сад Фонариков",
		"pos": Vector3(-34.0, 0.0, -138.0),
		"description": "Тихая терраса, откуда души отпускают к небу огни благодарности и светлой памяти.",
	},
	{
		"id": "mira_sanctuary",
		"name": "Дом Утешения Миры",
		"short_name": "Дом Миры",
		"pos": Vector3(34.0, 0.0, -138.0),
		"description": "Тёплая обитель Матери Утешения, где исцеляют усталость после возвращения с Земли.",
	},
	{
		"id": "earth_mirror_temple",
		"name": "Храм Зеркала Земли",
		"short_name": "Храм Зеркала Земли",
		"pos": Vector3(0.0, 8.0, -280.0),
		"description": "Северная вершина Обители. В его сводах сияет Зеркало Земли — порог первого воплощения.",
	},
]

const ROAD_CONNECTIONS: Array = [
	["awakening_plaza", "central_boulevard"],
	["central_boulevard", "earth_mirror_temple"],
	["awakening_plaza", "school_of_souls"],
	["awakening_plaza", "quiet_lakes_park"],
	["school_of_souls", "central_boulevard"],
	["quiet_lakes_park", "central_boulevard"],
	["school_of_souls", "orion_library"],
	["quiet_lakes_park", "kronos_tower"],
	["central_boulevard", "orion_library"],
	["central_boulevard", "kronos_tower"],
	["orion_library", "lantern_garden"],
	["kronos_tower", "mira_sanctuary"],
	["lantern_garden", "mira_sanctuary"],
	["lantern_garden", "earth_mirror_temple"],
	["mira_sanctuary", "earth_mirror_temple"],
]

var _is_open: bool = false
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
var _player_pos: Vector3 = Vector3(0.0, 0.0, 48.0)
var _time: float = 0.0
var _hovered_district_id: String = ""

var _root_control: Control
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

var _district_by_id: Dictionary = {}
var _district_nodes: Dictionary = {} # district_id -> Control wrapper
var _district_buttons: Dictionary = {} # district_id -> Button


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
# Public API
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
	_update_district_button_styles()
	_set_hovered_district("")

	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()
	_root_control.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_root_control, "modulate:a", 1.0, 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if _map_canvas != null:
		_map_canvas.queue_redraw()


func close_map() -> void:
	if not _is_open:
		return
	_is_open = false
	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()
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
		_quest_title_label.text = title
		_quest_objective_label.text = objective
		_quest_district_label.text = "Ориентир: %s" % _get_district_name(target_district)

		var items_var: Variant = qm.call("get_items")
		if items_var is Array:
			_rebuild_inventory_list(items_var as Array)
		else:
			_rebuild_inventory_list([])
	else:
		_quest_title_label.text = "Первые шаги в Городе Душ"
		_quest_objective_label.text = "Поговорите с Люми на Площади Пробуждения"
		_quest_district_label.text = "Ориентир: Площадь Пробуждения"
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

	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = COLOR_BACKDROP
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root_control.add_child(backdrop)

	# Outer soft-margin container
	var outer_margin: MarginContainer = MarginContainer.new()
	outer_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_theme_constant_override("margin_left", 32)
	outer_margin.add_theme_constant_override("margin_right", 32)
	outer_margin.add_theme_constant_override("margin_top", 24)
	outer_margin.add_theme_constant_override("margin_bottom", 24)
	_root_control.add_child(outer_margin)

	# Main ornate sapphire + gold frame
	var frame_panel: PanelContainer = PanelContainer.new()
	frame_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame_panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_SAPPHIRE_DEEP, COLOR_GOLD, 2, 14))
	outer_margin.add_child(frame_panel)

	var frame_margin: MarginContainer = MarginContainer.new()
	frame_margin.add_theme_constant_override("margin_left", 18)
	frame_margin.add_theme_constant_override("margin_right", 18)
	frame_margin.add_theme_constant_override("margin_top", 14)
	frame_margin.add_theme_constant_override("margin_bottom", 16)
	frame_panel.add_child(frame_margin)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	frame_margin.add_child(main_vbox)

	# Top Header Bar
	var header_hbox: HBoxContainer = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(header_hbox)

	var title_vbox: VBoxContainer = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)

	var title_label: Label = Label.new()
	title_label.text = "КАРТА ГОРОДА ДУШ  ·  ОБИТЕЛЬ ХРОНИК АКАШИ"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	title_vbox.add_child(title_label)

	var subtitle_label: Label = Label.new()
	subtitle_label.text = "Нажмите на любой квартал, чтобы мгновенно перенестись туда"
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", COLOR_IVORY_MUTED)
	title_vbox.add_child(subtitle_label)

	var legend_hbox: HBoxContainer = HBoxContainer.new()
	legend_hbox.alignment = BoxContainer.ALIGNMENT_END
	legend_hbox.add_theme_constant_override("separation", 14)
	header_hbox.add_child(legend_hbox)

	legend_hbox.add_child(_make_legend_pill("✦ Активная цель", COLOR_GOLD_BRIGHT))
	legend_hbox.add_child(_make_legend_pill("◈ Ваша Душа", COLOR_PLAYER_CYAN))
	legend_hbox.add_child(_make_legend_pill("○ Квартал", COLOR_IVORY))

	# Golden hairline divider under header
	var header_line: ColorRect = ColorRect.new()
	header_line.custom_minimum_size = Vector2(0.0, 1.0)
	header_line.color = COLOR_GOLD_SOFT
	main_vbox.add_child(header_line)

	# Content Split: 68% Map Canvas | 32% Quest & Memory Bag Sidebar
	var content_hbox: HBoxContainer = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(content_hbox)

	_build_map_panel(content_hbox)
	_build_sidebar_panel(content_hbox)


func _build_map_panel(parent: HBoxContainer) -> void:
	var map_frame: PanelContainer = PanelContainer.new()
	map_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_frame.size_flags_stretch_ratio = 0.68
	map_frame.add_theme_stylebox_override("panel", _make_panel_style(COLOR_SAPPHIRE_CANVAS, COLOR_GOLD_SOFT, 1, 10))
	parent.add_child(map_frame)

	_map_canvas = Control.new()
	_map_canvas.name = "MapCanvas"
	_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_canvas.clip_contents = true
	_map_canvas.draw.connect(_on_map_canvas_draw)
	_map_canvas.resized.connect(_update_district_node_positions)
	map_frame.add_child(_map_canvas)

	# Create 9 interactive district node buttons
	for entry_var: Variant in DISTRICTS:
		if not (entry_var is Dictionary):
			continue
		var entry: Dictionary = entry_var as Dictionary
		var d_id: String = str(entry.get("id", ""))
		var short_name: String = str(entry.get("short_name", d_id))

		var node_wrapper: Control = Control.new()
		node_wrapper.name = "District_%s" % d_id
		node_wrapper.custom_minimum_size = Vector2(150.0, 48.0)
		node_wrapper.size = Vector2(150.0, 48.0)
		node_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_map_canvas.add_child(node_wrapper)

		var btn: Button = Button.new()
		btn.text = "◈"
		btn.custom_minimum_size = Vector2(28.0, 28.0)
		btn.size = Vector2(28.0, 28.0)
		btn.position = Vector2(61.0, 0.0)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(_on_district_clicked.bind(d_id))
		btn.mouse_entered.connect(_set_hovered_district.bind(d_id))
		btn.mouse_exited.connect(_on_district_mouse_exited.bind(d_id))
		node_wrapper.add_child(btn)

		var name_lbl: Label = Label.new()
		name_lbl.text = short_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.position = Vector2(0.0, 28.0)
		name_lbl.size = Vector2(150.0, 20.0)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", COLOR_IVORY)
		name_lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.1, 0.92))
		name_lbl.add_theme_constant_override("shadow_offset_x", 1)
		name_lbl.add_theme_constant_override("shadow_offset_y", 1)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node_wrapper.add_child(name_lbl)

		_district_nodes[d_id] = node_wrapper
		_district_buttons[d_id] = btn

	# Hover tooltip anchored at top-left of the map canvas (clear of all 9 district nodes)
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.anchor_left = 0.0
	_tooltip_panel.anchor_right = 0.0
	_tooltip_panel.anchor_top = 0.0
	_tooltip_panel.anchor_bottom = 0.0
	_tooltip_panel.offset_left = 14.0
	_tooltip_panel.offset_right = 306.0
	_tooltip_panel.offset_top = 14.0
	_tooltip_panel.offset_bottom = 112.0
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.055, 0.108, 0.225, 0.94), COLOR_GOLD, 1, 8))
	_map_canvas.add_child(_tooltip_panel)

	var tip_margin: MarginContainer = MarginContainer.new()
	tip_margin.add_theme_constant_override("margin_left", 12)
	tip_margin.add_theme_constant_override("margin_right", 12)
	tip_margin.add_theme_constant_override("margin_top", 8)
	tip_margin.add_theme_constant_override("margin_bottom", 8)
	tip_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.add_child(tip_margin)

	var tip_vbox: VBoxContainer = VBoxContainer.new()
	tip_vbox.add_theme_constant_override("separation", 3)
	tip_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_margin.add_child(tip_vbox)

	_tooltip_title = Label.new()
	_tooltip_title.add_theme_font_size_override("font_size", 14)
	_tooltip_title.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	_tooltip_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_vbox.add_child(_tooltip_title)

	_tooltip_desc = Label.new()
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc.add_theme_font_size_override("font_size", 11)
	_tooltip_desc.add_theme_color_override("font_color", COLOR_IVORY)
	_tooltip_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_vbox.add_child(_tooltip_desc)

	_tooltip_hint = Label.new()
	_tooltip_hint.text = "Нажмите на узел квартала для быстрого перемещения"
	_tooltip_hint.add_theme_font_size_override("font_size", 10)
	_tooltip_hint.add_theme_color_override("font_color", COLOR_GOLD)
	_tooltip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_vbox.add_child(_tooltip_hint)

	_tooltip_panel.visible = false


func _build_sidebar_panel(parent: HBoxContainer) -> void:
	var side_panel: PanelContainer = PanelContainer.new()
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.size_flags_stretch_ratio = 0.32
	side_panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_SAPPHIRE_PANEL, COLOR_GOLD_SOFT, 1, 10))
	parent.add_child(side_panel)

	var side_margin: MarginContainer = MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 16)
	side_margin.add_theme_constant_override("margin_right", 16)
	side_margin.add_theme_constant_override("margin_top", 14)
	side_margin.add_theme_constant_override("margin_bottom", 14)
	side_panel.add_child(side_margin)

	var side_vbox: VBoxContainer = VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 12)
	side_margin.add_child(side_vbox)

	# --- Block 1: Current Quest ---
	var quest_header: Label = Label.new()
	quest_header.text = "ТЕКУЩЕЕ ПОРУЧЕНИЕ"
	quest_header.add_theme_font_size_override("font_size", 12)
	quest_header.add_theme_color_override("font_color", COLOR_GOLD)
	side_vbox.add_child(quest_header)

	var quest_card: PanelContainer = PanelContainer.new()
	quest_card.add_theme_stylebox_override("panel", _make_panel_style(COLOR_SAPPHIRE_CARD, COLOR_GOLD_SOFT, 1, 8))
	side_vbox.add_child(quest_card)

	var quest_margin: MarginContainer = MarginContainer.new()
	quest_margin.add_theme_constant_override("margin_left", 12)
	quest_margin.add_theme_constant_override("margin_right", 12)
	quest_margin.add_theme_constant_override("margin_top", 10)
	quest_margin.add_theme_constant_override("margin_bottom", 10)
	quest_card.add_child(quest_margin)

	var quest_vbox: VBoxContainer = VBoxContainer.new()
	quest_vbox.add_theme_constant_override("separation", 6)
	quest_margin.add_child(quest_vbox)

	_quest_title_label = Label.new()
	_quest_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_title_label.add_theme_font_size_override("font_size", 16)
	_quest_title_label.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	quest_vbox.add_child(_quest_title_label)

	_quest_objective_label = Label.new()
	_quest_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_objective_label.add_theme_font_size_override("font_size", 13)
	_quest_objective_label.add_theme_color_override("font_color", COLOR_IVORY)
	quest_vbox.add_child(_quest_objective_label)

	_quest_district_label = Label.new()
	_quest_district_label.add_theme_font_size_override("font_size", 11)
	_quest_district_label.add_theme_color_override("font_color", COLOR_PLAYER_CYAN)
	quest_vbox.add_child(_quest_district_label)

	# Golden divider
	var mid_div: ColorRect = ColorRect.new()
	mid_div.custom_minimum_size = Vector2(0.0, 1.0)
	mid_div.color = COLOR_GOLD_SOFT
	side_vbox.add_child(mid_div)

	# --- Block 2: Memory Bag ---
	var bag_header_hbox: HBoxContainer = HBoxContainer.new()
	side_vbox.add_child(bag_header_hbox)

	var bag_header: Label = Label.new()
	bag_header.text = "СУМКА ПАМЯТИ"
	bag_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_header.add_theme_font_size_override("font_size", 12)
	bag_header.add_theme_color_override("font_color", COLOR_GOLD)
	bag_header_hbox.add_child(bag_header)

	_bag_count_label = Label.new()
	_bag_count_label.text = "0"
	_bag_count_label.add_theme_font_size_override("font_size", 12)
	_bag_count_label.add_theme_color_override("font_color", COLOR_IVORY_MUTED)
	bag_header_hbox.add_child(_bag_count_label)

	var bag_scroll: ScrollContainer = ScrollContainer.new()
	bag_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_vbox.add_child(bag_scroll)

	_bag_list_vbox = VBoxContainer.new()
	_bag_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bag_list_vbox.add_theme_constant_override("separation", 8)
	bag_scroll.add_child(_bag_list_vbox)

	# --- Block 3: Close Button ---
	_close_button = Button.new()
	_close_button.text = "Закрыть карту [M / Esc]"
	_close_button.custom_minimum_size = Vector2(0.0, 40.0)
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_button.add_theme_font_size_override("font_size", 14)
	_close_button.add_theme_color_override("font_color", COLOR_IVORY)
	_close_button.add_theme_color_override("font_hover_color", COLOR_GOLD_BRIGHT)
	_close_button.add_theme_stylebox_override("normal", _make_panel_style(COLOR_SAPPHIRE_CARD, COLOR_GOLD, 1, 8))
	_close_button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.14, 0.23, 0.42, 0.96), COLOR_GOLD_BRIGHT, 2, 8))
	_close_button.add_theme_stylebox_override("pressed", _make_panel_style(COLOR_SAPPHIRE_DEEP, COLOR_GOLD_BRIGHT, 2, 8))
	_close_button.pressed.connect(close_map)
	side_vbox.add_child(_close_button)


func _rebuild_inventory_list(items: Array) -> void:
	for child: Node in _bag_list_vbox.get_children():
		child.queue_free()

	_bag_count_label.text = str(items.size())

	if items.is_empty():
		var empty_panel: PanelContainer = PanelContainer.new()
		empty_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.068, 0.125, 0.25, 0.72), COLOR_GOLD_GRID, 1, 8))
		_bag_list_vbox.add_child(empty_panel)

		var empty_margin: MarginContainer = MarginContainer.new()
		empty_margin.add_theme_constant_override("margin_left", 12)
		empty_margin.add_theme_constant_override("margin_right", 12)
		empty_margin.add_theme_constant_override("margin_top", 14)
		empty_margin.add_theme_constant_override("margin_bottom", 14)
		empty_panel.add_child(empty_margin)

		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Пока пусто — исследуйте кварталы Города"
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", COLOR_IVORY_MUTED)
		empty_margin.add_child(empty_lbl)
		return

	for item_var: Variant in items:
		if not (item_var is Dictionary):
			continue
		var item: Dictionary = item_var as Dictionary
		var item_title: String = str(item.get("title", ""))
		var item_desc: String = str(item.get("description", ""))

		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _make_panel_style(COLOR_SAPPHIRE_CARD, COLOR_GOLD_SOFT, 1, 8))
		_bag_list_vbox.add_child(card)

		var card_margin: MarginContainer = MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 10)
		card_margin.add_theme_constant_override("margin_right", 10)
		card_margin.add_theme_constant_override("margin_top", 8)
		card_margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(card_margin)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		card_margin.add_child(hbox)

		var diamond_lbl: Label = Label.new()
		diamond_lbl.text = "◆"
		diamond_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		diamond_lbl.add_theme_font_size_override("font_size", 16)
		diamond_lbl.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
		hbox.add_child(diamond_lbl)

		var text_vbox: VBoxContainer = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(text_vbox)

		var title_lbl: Label = Label.new()
		title_lbl.text = item_title
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.add_theme_font_size_override("font_size", 13)
		title_lbl.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
		text_vbox.add_child(title_lbl)

		if not item_desc.is_empty():
			var desc_lbl: Label = Label.new()
			desc_lbl.text = item_desc
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.add_theme_font_size_override("font_size", 11)
			desc_lbl.add_theme_color_override("font_color", COLOR_IVORY_MUTED)
			text_vbox.add_child(desc_lbl)


# ---------------------------------------------------------------------------
# Map Projection & Custom Drawing
# ---------------------------------------------------------------------------

func _world_to_map(world_pos: Vector3, canvas_size: Vector2) -> Vector2:
	var pad_x: float = 96.0
	var pad_top: float = 52.0
	var pad_bottom: float = 68.0
	var usable_w: float = maxf(64.0, canvas_size.x - pad_x * 2.0)
	var usable_h: float = maxf(64.0, canvas_size.y - pad_top - pad_bottom)

	var nx: float = clampf((world_pos.x - WORLD_MIN_X) / (WORLD_MAX_X - WORLD_MIN_X), 0.0, 1.0)
	var nz: float = clampf((world_pos.z - WORLD_MIN_Z) / (WORLD_MAX_Z - WORLD_MIN_Z), 0.0, 1.0)

	return Vector2(
		pad_x + nx * usable_w,
		pad_top + nz * usable_h
	)


func _update_district_node_positions() -> void:
	if _map_canvas == null:
		return
	var canvas_size: Vector2 = _map_canvas.size
	if canvas_size.x < 10.0 or canvas_size.y < 10.0:
		return

	for d_id_var: Variant in _district_nodes.keys():
		var d_id: String = str(d_id_var)
		var entry_var: Variant = _district_by_id.get(d_id, {})
		if not (entry_var is Dictionary):
			continue
		var entry: Dictionary = entry_var as Dictionary
		var pos_var: Variant = entry.get("pos", Vector3.ZERO)
		if not (pos_var is Vector3):
			continue
		var map_pt: Vector2 = _world_to_map(pos_var as Vector3, canvas_size)
		var wrapper: Control = _district_nodes[d_id] as Control
		# Center the 28x28 button (at x=61..89, y=0..28 inside 150x48 wrapper) on map_pt
		wrapper.position = Vector2(map_pt.x - 75.0, map_pt.y - 14.0)


func _update_district_button_styles() -> void:
	var target_district: String = ""
	var qm: Node = _get_quest_manager()
	if qm != null:
		target_district = str(qm.call("get_current_target_district"))

	for d_id_var: Variant in _district_buttons.keys():
		var d_id: String = str(d_id_var)
		var btn: Button = _district_buttons[d_id] as Button
		var is_target: bool = (d_id == target_district)
		var border_col: Color = COLOR_GOLD_BRIGHT if is_target else COLOR_GOLD
		var fill_col: Color = Color(0.24, 0.20, 0.09, 0.96) if is_target else COLOR_SAPPHIRE_CARD
		var hover_fill: Color = Color(0.32, 0.26, 0.11, 0.98) if is_target else Color(0.15, 0.25, 0.45, 0.98)

		btn.text = "✦" if is_target else "◈"
		btn.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT if is_target else COLOR_IVORY)
		btn.add_theme_color_override("font_hover_color", COLOR_GOLD_BRIGHT)
		btn.add_theme_stylebox_override("normal", _make_panel_style(fill_col, border_col, 2 if is_target else 1, 14))
		btn.add_theme_stylebox_override("hover", _make_panel_style(hover_fill, COLOR_GOLD_BRIGHT, 2, 14))
		btn.add_theme_stylebox_override("pressed", _make_panel_style(COLOR_SAPPHIRE_DEEP, COLOR_GOLD_BRIGHT, 2, 14))


func _on_map_canvas_draw() -> void:
	var s: Vector2 = _map_canvas.size
	if s.x < 10.0 or s.y < 10.0:
		return

	var center: Vector2 = s * 0.5
	var font: Font = ThemeDB.fallback_font

	# 1. Soft celestial glow halos behind Temple (north) and Boulevard (center)
	var temple_pt: Vector2 = _world_to_map(Vector3(0.0, 8.0, -280.0), s)
	var center_pt: Vector2 = _world_to_map(Vector3(0.0, 0.0, -32.0), s)
	_map_canvas.draw_circle(temple_pt, 96.0, Color(0.875, 0.725, 0.376, 0.055))
	_map_canvas.draw_circle(temple_pt, 52.0, Color(0.875, 0.725, 0.376, 0.08))
	_map_canvas.draw_circle(center_pt, 128.0, Color(0.28, 0.52, 0.88, 0.055))

	# 2. Fine antique-gold compass grid (lines & concentric astrolabe circles)
	var grid_step: float = 56.0
	var gx: float = grid_step
	while gx < s.x:
		_map_canvas.draw_line(Vector2(gx, 0.0), Vector2(gx, s.y), COLOR_GOLD_GRID, 1.0)
		gx += grid_step
	var gy: float = grid_step
	while gy < s.y:
		_map_canvas.draw_line(Vector2(0.0, gy), Vector2(s.x, gy), COLOR_GOLD_GRID, 1.0)
		gy += grid_step

	var max_r: float = minf(s.x, s.y) * 0.44
	_map_canvas.draw_arc(center, max_r * 0.42, 0.0, TAU, 64, COLOR_GOLD_GRID, 1.0, true)
	_map_canvas.draw_arc(center, max_r * 0.75, 0.0, TAU, 64, COLOR_GOLD_GRID, 1.0, true)
	_map_canvas.draw_arc(center, max_r, 0.0, TAU, 72, Color(0.875, 0.725, 0.376, 0.16), 1.0, true)

	# 3. Painted Shining Canal (west-to-east along Z = -32.0 under Memory Bridge) & Lake of Stillness
	var canal_world: Array = [
		Vector3(-64.0, 0.0, -34.0),
		Vector3(-42.0, 0.0, -30.5),
		Vector3(-20.0, 0.0, -33.0),
		Vector3(0.0, 0.0, -32.0),
		Vector3(20.0, 0.0, -30.5),
		Vector3(42.0, 0.0, -33.5),
		Vector3(64.0, 0.0, -32.0),
	]
	var canal_pts: PackedVector2Array = PackedVector2Array()
	for wp_var: Variant in canal_world:
		if wp_var is Vector3:
			canal_pts.append(_world_to_map(wp_var as Vector3, s))
	if canal_pts.size() >= 2:
		_map_canvas.draw_polyline(canal_pts, COLOR_WATER_CANAL, 10.0, true)
		_map_canvas.draw_polyline(canal_pts, COLOR_WATER_SHIMMER, 3.0, true)

	# Lake of Stillness near quiet_lakes_park (44, 0, 10)
	var lake_pt: Vector2 = _world_to_map(Vector3(44.0, 0.0, 10.0), s)
	_draw_ellipse(_map_canvas, lake_pt + Vector2(6.0, 4.0), 42.0, 24.0, Color(0.16, 0.42, 0.66, 0.56))
	_draw_ellipse_outline(_map_canvas, lake_pt + Vector2(6.0, 4.0), 44.0, 26.0, COLOR_WATER_SHIMMER, 1.2)
	_draw_ellipse_outline(_map_canvas, lake_pt + Vector2(6.0, 4.0), 30.0, 16.0, Color(0.875, 0.725, 0.376, 0.22), 1.0)

	# 4. Golden Street Network connecting all 9 districts
	for pair_var: Variant in ROAD_CONNECTIONS:
		if not (pair_var is Array):
			continue
		var pair: Array = pair_var as Array
		if pair.size() < 2:
			continue
		var p1: Vector2 = _get_district_map_pos(str(pair[0]), s)
		var p2: Vector2 = _get_district_map_pos(str(pair[1]), s)
		var is_spine: bool = (str(pair[0]) == "awakening_plaza" and str(pair[1]) == "central_boulevard") \
			or (str(pair[0]) == "central_boulevard" and str(pair[1]) == "earth_mirror_temple")
		var road_w: float = 3.2 if is_spine else 1.8
		_map_canvas.draw_line(p1, p2, COLOR_ROAD_HIGHLIGHT, road_w + 3.0, true)
		_map_canvas.draw_line(p1, p2, COLOR_ROAD_GOLD, road_w, true)

	# 5. Compass Rose in top-right corner of the map canvas
	_draw_compass_rose(_map_canvas, Vector2(s.x - 48.0, 48.0), 22.0, font)

	# 6. Pulsing Active Quest Beacon
	var qm: Node = _get_quest_manager()
	if qm != null:
		var target_pos_var: Variant = qm.call("get_current_target_pos")
		if target_pos_var is Vector3:
			var q_pt: Vector2 = _world_to_map(target_pos_var as Vector3, s)
			var pulse_a: float = fmod(_time * 0.85, 1.0)
			var pulse_b: float = fmod(_time * 0.85 + 0.5, 1.0)
			var rad_a: float = lerpf(12.0, 38.0, pulse_a)
			var rad_b: float = lerpf(12.0, 38.0, pulse_b)
			_map_canvas.draw_arc(q_pt, rad_a, 0.0, TAU, 36, Color(0.969, 0.855, 0.525, (1.0 - pulse_a) * 0.72), 2.0, true)
			_map_canvas.draw_arc(q_pt, rad_b, 0.0, TAU, 36, Color(0.969, 0.855, 0.525, (1.0 - pulse_b) * 0.55), 1.5, true)
			_map_canvas.draw_circle(q_pt, 18.0, Color(0.969, 0.855, 0.525, 0.14))

	# 7. Player (Soul) Current Position Marker
	var p_pt: Vector2 = _world_to_map(_player_pos, s)
	var player_pulse: float = 0.5 + 0.5 * sin(_time * 3.4)
	var halo_r: float = lerpf(10.0, 16.0, player_pulse)
	_map_canvas.draw_circle(p_pt, halo_r, Color(0.455, 0.847, 1.0, 0.22))
	_map_canvas.draw_arc(p_pt, halo_r, 0.0, TAU, 28, Color(0.455, 0.847, 1.0, 0.65), 1.5, true)
	var diamond_r: float = 6.5
	var diamond: PackedVector2Array = PackedVector2Array([
		p_pt + Vector2(0.0, -diamond_r),
		p_pt + Vector2(diamond_r, 0.0),
		p_pt + Vector2(0.0, diamond_r),
		p_pt + Vector2(-diamond_r, 0.0),
	])
	_map_canvas.draw_colored_polygon(diamond, COLOR_PLAYER_CYAN)
	_map_canvas.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), COLOR_IVORY, 1.2, true)

	# 8. Subtle corner filigree on map canvas
	_draw_corner_ornaments(_map_canvas, s)


func _draw_compass_rose(canvas: Control, center: Vector2, radius: float, font: Font) -> void:
	canvas.draw_arc(center, radius, 0.0, TAU, 32, COLOR_GOLD_SOFT, 1.2, true)
	canvas.draw_arc(center, radius * 0.65, 0.0, TAU, 24, COLOR_GOLD_GRID, 1.0, true)
	canvas.draw_line(center + Vector2(0.0, -radius - 4.0), center + Vector2(0.0, radius + 4.0), COLOR_GOLD, 1.2, true)
	canvas.draw_line(center + Vector2(-radius - 4.0, 0.0), center + Vector2(radius + 4.0, 0.0), COLOR_GOLD_SOFT, 1.0, true)
	var north_tip: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -radius - 5.0),
		center + Vector2(4.0, -4.0),
		center + Vector2(-4.0, -4.0),
	])
	canvas.draw_colored_polygon(north_tip, COLOR_GOLD_BRIGHT)
	if font != null:
		canvas.draw_string(font, center + Vector2(-4.0, -radius - 8.0), "С", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_GOLD_BRIGHT)
		canvas.draw_string(font, center + Vector2(-4.0, radius + 16.0), "Ю", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_IVORY_MUTED)
		canvas.draw_string(font, center + Vector2(-radius - 14.0, 4.0), "З", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_IVORY_MUTED)
		canvas.draw_string(font, center + Vector2(radius + 6.0, 4.0), "В", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_IVORY_MUTED)


func _draw_corner_ornaments(canvas: Control, s: Vector2) -> void:
	var m: float = 10.0
	var arm: float = 18.0
	var c: Color = Color(0.875, 0.725, 0.376, 0.42)
	# Top-left
	canvas.draw_line(Vector2(m, m), Vector2(m + arm, m), c, 1.4)
	canvas.draw_line(Vector2(m, m), Vector2(m, m + arm), c, 1.4)
	# Top-right
	canvas.draw_line(Vector2(s.x - m, m), Vector2(s.x - m - arm, m), c, 1.4)
	canvas.draw_line(Vector2(s.x - m, m), Vector2(s.x - m, m + arm), c, 1.4)
	# Bottom-left
	canvas.draw_line(Vector2(m, s.y - m), Vector2(m + arm, s.y - m), c, 1.4)
	canvas.draw_line(Vector2(m, s.y - m), Vector2(m, s.y - m - arm), c, 1.4)
	# Bottom-right
	canvas.draw_line(Vector2(s.x - m, s.y - m), Vector2(s.x - m - arm, s.y - m), c, 1.4)
	canvas.draw_line(Vector2(s.x - m, s.y - m), Vector2(s.x - m, s.y - m - arm), c, 1.4)


func _draw_ellipse(canvas: Control, center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = 32
	for i: int in range(steps):
		var angle: float = TAU * float(i) / float(steps)
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	canvas.draw_colored_polygon(pts, color)


func _draw_ellipse_outline(canvas: Control, center: Vector2, rx: float, ry: float, color: Color, width: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = 32
	for i: int in range(steps + 1):
		var angle: float = TAU * float(i) / float(steps)
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	canvas.draw_polyline(pts, color, width, true)


# ---------------------------------------------------------------------------
# Interaction & Signal Wiring
# ---------------------------------------------------------------------------

func _on_district_clicked(district_id: String) -> void:
	fast_travel_requested.emit(district_id)
	close_map()


func _set_hovered_district(district_id: String) -> void:
	_hovered_district_id = district_id
	if district_id.is_empty() or not _district_by_id.has(district_id):
		_tooltip_panel.visible = false
		return

	var entry: Dictionary = _district_by_id[district_id] as Dictionary
	_tooltip_title.text = str(entry.get("name", district_id))
	_tooltip_desc.text = str(entry.get("description", ""))
	_tooltip_panel.visible = true


func _on_district_mouse_exited(district_id: String) -> void:
	if _hovered_district_id == district_id:
		_set_hovered_district("")


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


func _get_district_map_pos(district_id: String, canvas_size: Vector2) -> Vector2:
	if _district_by_id.has(district_id):
		var entry: Dictionary = _district_by_id[district_id] as Dictionary
		var pos_var: Variant = entry.get("pos", Vector3.ZERO)
		if pos_var is Vector3:
			return _world_to_map(pos_var as Vector3, canvas_size)
	return canvas_size * 0.5


func _make_legend_pill(text: String, text_color: Color) -> PanelContainer:
	var pill: PanelContainer = PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.145, 0.285, 0.85), COLOR_GOLD_GRID, 1, 10))
	var m: MarginContainer = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 9)
	m.add_theme_constant_override("margin_right", 9)
	m.add_theme_constant_override("margin_top", 3)
	m.add_theme_constant_override("margin_bottom", 3)
	pill.add_child(m)
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", text_color)
	m.add_child(lbl)
	return pill


func _make_panel_style(bg_color: Color, border_color: Color, border_w: int, radius: int) -> StyleBoxFlat:
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
	return sb
