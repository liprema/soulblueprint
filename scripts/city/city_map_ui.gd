class_name CityMapUI
extends CanvasLayer

## Interactive Illustrated City of Souls Wayfinding Map & Memory Bag overlay (Godot 4.3+).
## AAA Parchment Chronicle & Antique Gold aesthetic (Genshin Impact / Zelda TotK / Pixar).
## Opens/closes via [M] or [Esc]. Shows live player position & facing compass, walkable
## road/stairs network, shortest-path golden route, and step-by-step Russian directions.

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
const COLOR_TEAL_SOFT_BG: Color = Color(0.875, 0.945, 0.948, 0.95)
const COLOR_IVORY_PIN: Color = Color(0.992, 0.968, 0.905, 0.97)
const COLOR_IVORY_PIN_HOVER: Color = Color(1.0, 0.985, 0.915, 1.0)
const COLOR_QUEST_PIN_FILL: Color = Color(0.945, 0.775, 0.295, 0.98)
const COLOR_ROUTE_PIN_FILL: Color = Color(0.980, 0.835, 0.360, 0.98)
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

# --- 9 Selectable District Pins ---
const DISTRICTS: Array = [
	{
		"id": "earth_mirror_temple",
		"name": "Верхний Храм Зеркала Земли",
		"short_name": "Храм Зеркала Земли",
		"tier": "Верхний Храм",
		"uv": Vector2(0.50, 0.16),
		"pos": Vector3(0.0, 0.0, -245.0),
		"icon": "◆",
		"description": "Северная вершина Обители. В его сводах сияет Зеркало Земли — порог первого воплощения.",
	},
	{
		"id": "lantern_garden",
		"name": "Сад Небесных Фонариков",
		"short_name": "Сад Фонариков",
		"tier": "Средний ярус",
		"uv": Vector2(0.28, 0.34),
		"pos": Vector3(-34.0, 3.2, -138.0),
		"icon": "◈",
		"description": "Тихая терраса, откуда души отпускают к небу огни благодарности и светлой памяти.",
	},
	{
		"id": "mira_sanctuary",
		"name": "Дом Утешения Миры",
		"short_name": "Дом Миры",
		"tier": "Средний ярус",
		"uv": Vector2(0.69, 0.33),
		"pos": Vector3(34.0, 3.2, -138.0),
		"icon": "◈",
		"description": "Тёплая обитель Матери Утешения, где исцеляют усталость после возвращения с Земли.",
	},
	{
		"id": "orion_library",
		"name": "Библиотека Ориона",
		"short_name": "Библиотека Ориона",
		"tier": "Средний ярус",
		"uv": Vector2(0.36, 0.43),
		"pos": Vector3(-48.0, 3.2, -78.0),
		"icon": "◈",
		"description": "Своды Звёздных Свитков, где Архивариус Орион бережёт хроники всех прожитых и будущих жизней.",
	},
	{
		"id": "kronos_tower",
		"name": "Башня Времени Кроноса",
		"short_name": "Башня Кроноса",
		"tier": "Средний ярус",
		"uv": Vector2(0.62, 0.44),
		"pos": Vector3(48.0, 3.2, -78.0),
		"icon": "◈",
		"description": "Обсерватория золотых песочных часов, с балкона которой виден хрупкий бег земных вёсен.",
	},
	{
		"id": "central_boulevard",
		"name": "Мост Памяти и Бульвар",
		"short_name": "Мост Памяти",
		"tier": "Нижний ярус",
		"uv": Vector2(0.50, 0.54),
		"pos": Vector3(0.0, 1.35, -32.0),
		"icon": "◈",
		"description": "Каменный мост через сияющую реку и Императорская Аллея, соединяющая кварталы с Храмом.",
	},
	{
		"id": "school_of_souls",
		"name": "Школа Юных Душ",
		"short_name": "Школа Юных Душ",
		"tier": "Средний ярус",
		"uv": Vector2(0.33, 0.68),
		"pos": Vector3(-42.0, 3.2, 8.0),
		"icon": "◈",
		"description": "Светлый дворик Наставницы Алатеи. Здесь души учатся слышать сердце и сплетают свой Чертёж.",
	},
	{
		"id": "quiet_lakes_park",
		"name": "Озёрный Парк Тишины",
		"short_name": "Озеро Тишины",
		"tier": "Нижний ярус",
		"uv": Vector2(0.75, 0.76),
		"pos": Vector3(44.0, 0.0, 10.0),
		"icon": "◈",
		"description": "Зеркальная гладь Озера Тишины с лодочками. Вода бережно хранит несказанные слова любви.",
	},
	{
		"id": "awakening_plaza",
		"name": "Площадь Пробуждения",
		"short_name": "Площадь Пробуждения",
		"tier": "Нижний ярус",
		"uv": Vector2(0.50, 0.83),
		"pos": Vector3(0.0, 0.0, 48.0),
		"icon": "◈",
		"description": "Южные врата Города Душ с фонтаном, где новорождённые души делают первый шаг под сводами Акаши.",
	},
]

# --- Walkable City Waypoint Graph (9 districts + 4 interactive venues + stairs/boulevard nodes) ---
const WAYPOINT_DEFS: Array = [
	{
		"id": "awakening_plaza",
		"label": "Площадь Пробуждения",
		"tier": "Нижний ярус",
		"kind": "district",
		"pos": Vector3(0.0, 0.0, 48.0),
		"uv": Vector2(0.50, 0.83),
	},
	{
		"id": "south_boulevard",
		"label": "Главный бульвар",
		"tier": "Нижний ярус",
		"kind": "junction",
		"pos": Vector3(0.0, 0.0, 20.0),
		"uv": Vector2(0.50, 0.72),
	},
	{
		"id": "cafe",
		"label": "Звёздное Кафе",
		"tier": "Нижний ярус",
		"kind": "venue",
		"pos": Vector3(17.5, 0.0, 28.0),
		"uv": Vector2(0.59, 0.75),
	},
	{
		"id": "shop",
		"label": "Лавка Воспоминаний",
		"tier": "Нижний ярус",
		"kind": "venue",
		"pos": Vector3(-17.5, 0.0, 28.0),
		"uv": Vector2(0.41, 0.75),
	},
	{
		"id": "west_school_stairs",
		"label": "Западная лестница",
		"tier": "Нижний ярус",
		"kind": "stairs",
		"pos": Vector3(-20.0, 1.6, 8.0),
		"uv": Vector2(0.41, 0.69),
	},
	{
		"id": "school_of_souls",
		"label": "Школа Юных Душ",
		"tier": "Средний ярус",
		"kind": "district",
		"pos": Vector3(-42.0, 3.2, 8.0),
		"uv": Vector2(0.33, 0.68),
	},
	{
		"id": "lakes_entry",
		"label": "Аллея к Озеру Тишины",
		"tier": "Нижний ярус",
		"kind": "junction",
		"pos": Vector3(30.0, 0.0, 10.0),
		"uv": Vector2(0.63, 0.73),
	},
	{
		"id": "quiet_lakes_park",
		"label": "Озёрный Парк Тишины",
		"tier": "Нижний ярус",
		"kind": "district",
		"pos": Vector3(44.0, 0.0, 10.0),
		"uv": Vector2(0.75, 0.76),
	},
	{
		"id": "central_boulevard",
		"label": "Мост Памяти",
		"tier": "Нижний ярус",
		"kind": "bridge",
		"pos": Vector3(0.0, 1.35, -32.0),
		"uv": Vector2(0.50, 0.54),
	},
	{
		"id": "north_stairs",
		"label": "Парадная лестница",
		"tier": "Средний ярус",
		"kind": "stairs",
		"pos": Vector3(0.0, 1.6, -46.0),
		"uv": Vector2(0.50, 0.49),
	},
	{
		"id": "orrery_plaza",
		"label": "Площадь Астролябии",
		"tier": "Средний ярус",
		"kind": "junction",
		"pos": Vector3(0.0, 3.2, -78.0),
		"uv": Vector2(0.50, 0.435),
	},
	{
		"id": "orion_library",
		"label": "Библиотека Ориона",
		"tier": "Средний ярус",
		"kind": "district",
		"pos": Vector3(-48.0, 3.2, -78.0),
		"uv": Vector2(0.36, 0.43),
	},
	{
		"id": "lantern_garden",
		"label": "Сад Небесных Фонариков",
		"tier": "Средний ярус",
		"kind": "district",
		"pos": Vector3(-34.0, 3.2, -138.0),
		"uv": Vector2(0.28, 0.34),
	},
	{
		"id": "kronos_tower",
		"label": "Башня Времени Кроноса",
		"tier": "Средний ярус",
		"kind": "district",
		"pos": Vector3(48.0, 3.2, -78.0),
		"uv": Vector2(0.62, 0.44),
	},
	{
		"id": "mira_sanctuary",
		"label": "Дом Утешения Миры",
		"tier": "Средний ярус",
		"kind": "district",
		"pos": Vector3(34.0, 3.2, -138.0),
		"uv": Vector2(0.69, 0.33),
	},
	{
		"id": "north_boulevard_mid",
		"label": "Северный бульвар",
		"tier": "Средний ярус",
		"kind": "junction",
		"pos": Vector3(0.0, 3.2, -108.0),
		"uv": Vector2(0.50, 0.38),
	},
	{
		"id": "hall_of_spirit",
		"label": "Зал Силы Духа",
		"tier": "Средний ярус",
		"kind": "venue",
		"pos": Vector3(21.0, 3.2, -108.0),
		"uv": Vector2(0.57, 0.38),
	},
	{
		"id": "akasha_gallery",
		"label": "Галерея Акаши",
		"tier": "Средний ярус",
		"kind": "venue",
		"pos": Vector3(-23.0, 3.2, -108.0),
		"uv": Vector2(0.43, 0.38),
	},
	{
		"id": "north_boulevard_end",
		"label": "Северная арка",
		"tier": "Средний ярус",
		"kind": "junction",
		"pos": Vector3(0.0, 3.2, -148.0),
		"uv": Vector2(0.50, 0.31),
	},
	{
		"id": "overlook_stairs",
		"label": "Лестница на Смотровую",
		"tier": "Смотровая терраса",
		"kind": "stairs",
		"pos": Vector3(0.0, 4.4, -164.0),
		"uv": Vector2(0.50, 0.28),
	},
	{
		"id": "upper_overlook",
		"label": "Смотровая терраса",
		"tier": "Смотровая терраса",
		"kind": "overlook",
		"pos": Vector3(0.0, 5.6, -184.0),
		"uv": Vector2(0.50, 0.245),
	},
	{
		"id": "imperial_descent",
		"label": "Императорский спуск",
		"tier": "Верхний Храм",
		"kind": "stairs",
		"pos": Vector3(0.0, 2.8, -205.0),
		"uv": Vector2(0.50, 0.21),
	},
	{
		"id": "earth_mirror_temple",
		"label": "Верхний Храм Зеркала Земли",
		"tier": "Верхний Храм",
		"kind": "district",
		"pos": Vector3(0.0, 0.0, -245.0),
		"uv": Vector2(0.50, 0.16),
	},
]

const WAYPOINT_EDGES: Array = [
	["awakening_plaza", "south_boulevard"],
	["south_boulevard", "cafe"],
	["south_boulevard", "shop"],
	["south_boulevard", "west_school_stairs"],
	["west_school_stairs", "school_of_souls"],
	["south_boulevard", "lakes_entry"],
	["lakes_entry", "quiet_lakes_park"],
	["south_boulevard", "central_boulevard"],
	["central_boulevard", "north_stairs"],
	["north_stairs", "orrery_plaza"],
	["orrery_plaza", "orion_library"],
	["orion_library", "lantern_garden"],
	["orrery_plaza", "kronos_tower"],
	["kronos_tower", "mira_sanctuary"],
	["orrery_plaza", "north_boulevard_mid"],
	["north_boulevard_mid", "hall_of_spirit"],
	["north_boulevard_mid", "akasha_gallery"],
	["north_boulevard_mid", "north_boulevard_end"],
	["north_boulevard_end", "overlook_stairs"],
	["overlook_stairs", "upper_overlook"],
	["upper_overlook", "imperial_descent"],
	["imperial_descent", "earth_mirror_temple"],
]

# Smooth piecewise Z -> V anchor points matching the illustrated map's perspective
const Z_TO_V_KNOTS: Array = [
	Vector2(-285.0, 0.14),
	Vector2(-245.0, 0.16),
	Vector2(-184.0, 0.245),
	Vector2(-138.0, 0.34),
	Vector2(-78.0, 0.435),
	Vector2(-32.0, 0.54),
	Vector2(10.0, 0.71),
	Vector2(48.0, 0.83),
	Vector2(60.0, 0.87),
]

var _is_open: bool = false
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
var _player_pos: Vector3 = Vector3(0.0, 0.0, 48.0)
var _player_yaw: float = 0.0
var _time: float = 0.0
var _hovered_district_id: String = ""
var _active_target_district_id: String = ""
var _selected_route_district_id: String = ""

var _current_route_path: Array[String] = []
var _current_route_distance_m: float = 0.0

var _root_control: Control
var _map_texture_rect: TextureRect
var _map_canvas: Control
var _player_here_pill: PanelContainer
var _tooltip_panel: PanelContainer
var _tooltip_title: Label
var _tooltip_desc: Label
var _tooltip_hint: Label

var _location_name_label: Label
var _location_tier_label: Label
var _route_header_label: Label
var _route_reset_btn: Button
var _route_dest_label: Label
var _route_meta_label: Label
var _route_steps_vbox: VBoxContainer

var _quest_title_label: Label
var _quest_objective_label: Label
var _quest_district_label: Label
var _bag_count_label: Label
var _bag_list_vbox: VBoxContainer
var _close_button: Button
var _fade_tween: Tween
var _tooltip_tween: Tween

var _district_by_id: Dictionary = {}
var _waypoints_by_id: Dictionary = {}
var _waypoint_adj: Dictionary = {} # node_id -> Array[Dictionary { "to": String, "cost": float }]

var _district_nodes: Dictionary = {} # district_id -> Control wrapper
var _district_buttons: Dictionary = {} # district_id -> Button
var _district_nameplates: Dictionary = {} # district_id -> PanelContainer
var _pin_scale_tweens: Dictionary = {} # district_id -> Tween


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_index_districts()
	_build_waypoint_graph()
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
# Public API (100% preserved, upgraded with player_yaw)
# ---------------------------------------------------------------------------

func open_map(player_pos: Vector3, player_yaw: float = 0.0) -> void:
	_player_pos = player_pos
	_player_yaw = player_yaw
	if not _is_open:
		_previous_mouse_mode = Input.mouse_mode
	_is_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true

	refresh_quest_and_inventory()
	_update_district_node_positions()
	_update_player_here_pill_position()
	call_deferred("_update_district_node_positions")
	call_deferred("_update_player_here_pill_position")
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


func update_player_pos(player_pos: Vector3, player_yaw: float = NAN) -> void:
	_player_pos = player_pos
	if not is_nan(player_yaw):
		_player_yaw = player_yaw
	if _is_open:
		_refresh_wayfinding_panel()
		_update_player_here_pill_position()
		if _map_canvas != null:
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

	_refresh_wayfinding_panel()
	_update_district_button_styles()
	if _map_canvas != null:
		_map_canvas.queue_redraw()


# ---------------------------------------------------------------------------
# Graph Construction & Shortest-Path Wayfinding
# ---------------------------------------------------------------------------

func _index_districts() -> void:
	_district_by_id.clear()
	for entry_var: Variant in DISTRICTS:
		if entry_var is Dictionary:
			var entry: Dictionary = entry_var as Dictionary
			var d_id: String = str(entry.get("id", ""))
			if not d_id.is_empty():
				_district_by_id[d_id] = entry


func _build_waypoint_graph() -> void:
	_waypoints_by_id.clear()
	_waypoint_adj.clear()

	for wp_var: Variant in WAYPOINT_DEFS:
		if wp_var is Dictionary:
			var wp: Dictionary = wp_var as Dictionary
			var wp_id: String = str(wp.get("id", ""))
			if not wp_id.is_empty():
				_waypoints_by_id[wp_id] = wp
				_waypoint_adj[wp_id] = []

	for edge_var: Variant in WAYPOINT_EDGES:
		if not (edge_var is Array):
			continue
		var edge: Array = edge_var as Array
		if edge.size() < 2:
			continue
		var a_id: String = str(edge[0])
		var b_id: String = str(edge[1])
		if not _waypoints_by_id.has(a_id) or not _waypoints_by_id.has(b_id):
			continue
		var pos_a: Vector3 = _get_waypoint_pos(a_id)
		var pos_b: Vector3 = _get_waypoint_pos(b_id)
		var dist: float = pos_a.distance_to(pos_b)
		(_waypoint_adj[a_id] as Array).append({"to": b_id, "cost": dist})
		(_waypoint_adj[b_id] as Array).append({"to": a_id, "cost": dist})


func _get_waypoint_pos(node_id: String) -> Vector3:
	if _waypoints_by_id.has(node_id):
		var wp: Dictionary = _waypoints_by_id[node_id] as Dictionary
		var pos_var: Variant = wp.get("pos", Vector3.ZERO)
		if pos_var is Vector3:
			return pos_var as Vector3
	return Vector3.ZERO


func _get_waypoint_uv(node_id: String) -> Vector2:
	if _waypoints_by_id.has(node_id):
		var wp: Dictionary = _waypoints_by_id[node_id] as Dictionary
		var uv_var: Variant = wp.get("uv", Vector2(0.5, 0.5))
		if uv_var is Vector2:
			return uv_var as Vector2
	return Vector2(0.5, 0.5)


func _get_waypoint_label(node_id: String) -> String:
	if _waypoints_by_id.has(node_id):
		var wp: Dictionary = _waypoints_by_id[node_id] as Dictionary
		return str(wp.get("label", node_id))
	return _get_district_name(node_id)


func _get_waypoint_tier(node_id: String) -> String:
	if _waypoints_by_id.has(node_id):
		var wp: Dictionary = _waypoints_by_id[node_id] as Dictionary
		return str(wp.get("tier", "Нижний ярус"))
	if _district_by_id.has(node_id):
		var d: Dictionary = _district_by_id[node_id] as Dictionary
		return str(d.get("tier", "Нижний ярус"))
	return "Нижний ярус"


func _get_active_route_target_id() -> String:
	if not _selected_route_district_id.is_empty() and _waypoints_by_id.has(_selected_route_district_id):
		return _selected_route_district_id
	if not _active_target_district_id.is_empty() and _waypoints_by_id.has(_active_target_district_id):
		return _active_target_district_id
	return "awakening_plaza"


func _find_nearest_waypoint_id(pos: Vector3) -> String:
	var best_id: String = "awakening_plaza"
	var best_score: float = INF
	for wp_id_var: Variant in _waypoints_by_id.keys():
		var wp_id: String = str(wp_id_var)
		var wp_pos: Vector3 = _get_waypoint_pos(wp_id)
		var dx: float = pos.x - wp_pos.x
		var dy: float = (pos.y - wp_pos.y) * 3.0
		var dz: float = pos.z - wp_pos.z
		var score: float = dx * dx + dy * dy + dz * dz
		if score < best_score:
			best_score = score
			best_id = wp_id
	return best_id


func _compute_shortest_path(start_id: String, goal_id: String) -> Array[String]:
	var result: Array[String] = []
	if not _waypoints_by_id.has(start_id) or not _waypoints_by_id.has(goal_id):
		return result
	if start_id == goal_id:
		result.append(start_id)
		return result

	var dist_map: Dictionary = {}
	var prev_map: Dictionary = {}
	var unvisited: Array[String] = []

	for wp_id_var: Variant in _waypoints_by_id.keys():
		var wp_id: String = str(wp_id_var)
		dist_map[wp_id] = INF
		unvisited.append(wp_id)

	dist_map[start_id] = 0.0

	while not unvisited.is_empty():
		var u_idx: int = -1
		var best_d: float = INF
		for i: int in range(unvisited.size()):
			var cand_id: String = unvisited[i]
			var cand_d: float = float(dist_map[cand_id])
			if cand_d < best_d:
				best_d = cand_d
				u_idx = i

		if u_idx < 0 or best_d == INF:
			break

		var u_id: String = unvisited[u_idx]
		unvisited.remove_at(u_idx)

		if u_id == goal_id:
			break

		var neighbors_var: Variant = _waypoint_adj.get(u_id, [])
		if not (neighbors_var is Array):
			continue
		var neighbors: Array = neighbors_var as Array
		for edge_var: Variant in neighbors:
			if not (edge_var is Dictionary):
				continue
			var edge: Dictionary = edge_var as Dictionary
			var v_id: String = str(edge.get("to", ""))
			var w: float = float(edge.get("cost", 1.0))
			var alt: float = best_d + w
			if alt < float(dist_map.get(v_id, INF)):
				dist_map[v_id] = alt
				prev_map[v_id] = u_id

	if not prev_map.has(goal_id):
		result.append(start_id)
		result.append(goal_id)
		return result

	var rev: Array[String] = []
	var cur: String = goal_id
	while not cur.is_empty():
		rev.append(cur)
		if cur == start_id:
			break
		cur = str(prev_map.get(cur, ""))

	for i: int in range(rev.size() - 1, -1, -1):
		result.append(rev[i])
	return result


func _compute_route_distance_meters(path: Array[String]) -> float:
	if path.is_empty():
		return 0.0
	if path.size() == 1:
		return _player_pos.distance_to(_get_waypoint_pos(path[0]))

	var total: float = _player_pos.distance_to(_get_waypoint_pos(path[0]))
	# If player is already on the first segment between path[0] and path[1], don't double-count
	var p0: Vector3 = _get_waypoint_pos(path[0])
	var p1: Vector3 = _get_waypoint_pos(path[1])
	var seg_vec: Vector3 = p1 - p0
	var seg_len_sq: float = seg_vec.length_squared()
	var start_edge_idx: int = 0
	if seg_len_sq > 1.0:
		var proj_t: float = (_player_pos - p0).dot(seg_vec) / seg_len_sq
		if proj_t > 0.05 and proj_t <= 1.05:
			total = _player_pos.distance_to(p1)
			start_edge_idx = 1

	for i: int in range(start_edge_idx, path.size() - 1):
		total += _get_waypoint_pos(path[i]).distance_to(_get_waypoint_pos(path[i + 1]))
	return total


func _build_route_steps(path: Array[String], total_dist: float) -> Array[String]:
	var steps: Array[String] = []
	if path.is_empty():
		return steps

	var goal_id: String = path[path.size() - 1]
	var goal_name: String = _get_waypoint_label(goal_id)

	if path.size() == 1:
		if total_dist < 12.0:
			steps.append("Вы уже находитесь у цели — %s." % goal_name)
		else:
			var dir_word: String = _cardinal_phrase(_player_pos, _get_waypoint_pos(goal_id))
			steps.append("Пройдите %s прямо к точке «%s»." % [dir_word, goal_name])
		return steps

	var i: int = 0
	var count: int = path.size()
	while i < count - 1:
		var u: String = path[i]
		var v: String = path[i + 1]
		var w: String = path[i + 2] if (i + 2 < count) else ""

		# Merge: south_boulevard -> central_boulevard -> north_stairs -> orrery_plaza
		if u == "awakening_plaza" and v == "south_boulevard" and w == "central_boulevard":
			steps.append("Идите на север по Главному бульвару и перейдите Мост Памяти через канал.")
			i += 2
			continue

		if u == "south_boulevard" and v == "west_school_stairs" and w == "school_of_souls":
			steps.append("Сверните на запад и поднимитесь по Западной лестнице в Школу Юных Душ.")
			i += 2
			continue

		if u == "school_of_souls" and v == "west_school_stairs" and w == "south_boulevard":
			steps.append("Спуститесь по Западной лестнице на Главный бульвар.")
			i += 2
			continue

		if u == "south_boulevard" and v == "lakes_entry" and w == "quiet_lakes_park":
			steps.append("Сверните на восток по Аллее к Озёрному Парку Тишины.")
			i += 2
			continue

		if u == "quiet_lakes_park" and v == "lakes_entry" and w == "south_boulevard":
			steps.append("Выйдите из парка на запад к Главному бульвару.")
			i += 2
			continue

		if u == "central_boulevard" and v == "north_stairs" and w == "orrery_plaza":
			steps.append("Поднимитесь по Парадной лестнице на Площадь Астролябии (Средний ярус).")
			i += 2
			continue

		if u == "orrery_plaza" and v == "north_stairs" and w == "central_boulevard":
			steps.append("Спуститесь по Парадной лестнице на Нижний ярус и перейдите Мост Памяти.")
			i += 2
			continue

		if u == "orrery_plaza" and v == "north_boulevard_mid" and w == "north_boulevard_end":
			steps.append("Идите прямо на север по Северному бульвару (мимо Зала Силы Духа и Галереи) к Северной арке.")
			i += 2
			continue

		if u == "north_boulevard_end" and v == "north_boulevard_mid" and w == "orrery_plaza":
			steps.append("Идите на юг по Северному бульвару к Площади Астролябии.")
			i += 2
			continue

		if u == "north_boulevard_end" and v == "overlook_stairs" and w == "upper_overlook":
			steps.append("Поднимитесь по Лестнице на Смотровую террасу.")
			i += 2
			continue

		if u == "upper_overlook" and v == "overlook_stairs" and w == "north_boulevard_end":
			steps.append("Спуститесь со Смотровой террасы к Северной арке.")
			i += 2
			continue

		if u == "upper_overlook" and v == "imperial_descent" and w == "earth_mirror_temple":
			steps.append("Спуститесь по Императорскому спуску к Верхнему Храму Зеркала Земли.")
			i += 2
			continue

		if u == "earth_mirror_temple" and v == "imperial_descent" and w == "upper_overlook":
			steps.append("Поднимитесь по Императорскому спуску на Смотровую террасу.")
			i += 2
			continue

		if u == "central_boulevard" and v == "south_boulevard" and w == "awakening_plaza":
			steps.append("Идите на юг по Главному бульвару к Площади Пробуждения.")
			i += 2
			continue

		# Single-edge readable step
		var prev_id: String = path[i - 1] if i > 0 else ""
		steps.append(_describe_single_edge(prev_id, u, v))
		i += 1

	return steps


func _describe_single_edge(prev_id: String, u: String, v: String) -> String:
	if v == "central_boulevard":
		return "Перейдите Мост Памяти через канал."
	if v == "north_stairs":
		if u == "central_boulevard":
			return "Поднимитесь по Парадной лестнице на Средний ярус."
		return "Спуститесь по Парадной лестнице на Нижний ярус."
	if v == "west_school_stairs":
		if u == "school_of_souls":
			return "Спуститесь по Западной лестнице вниз."
		return "Поднимитесь по Западной лестнице на Средний ярус."
	if v == "overlook_stairs":
		if u == "upper_overlook":
			return "Спуститесь по Лестнице со Смотровой террасы."
		return "Поднимитесь по Лестнице на Смотровую террасу."
	if v == "imperial_descent":
		if u == "earth_mirror_temple":
			return "Поднимитесь по Императорскому спуску к Смотровой террасе."
		return "Пройдите по Императорскому спуску к Храму."
	if u == "orrery_plaza" and v == "orion_library":
		if prev_id == "north_stairs":
			return "От Площади Астролябии поверните налево (на запад) к Библиотеке Ориона."
		if prev_id == "north_boulevard_mid":
			return "От Площади Астролябии поверните направо (на запад) к Библиотеке Ориона."
		return "От Площади Астролябии идите прямо на запад к Библиотеке Ориона."
	if u == "orrery_plaza" and v == "kronos_tower":
		if prev_id == "north_stairs":
			return "От Площади Астролябии поверните направо (на восток) к Башне Времени Кроноса."
		if prev_id == "north_boulevard_mid":
			return "От Площади Астролябии поверните налево (на восток) к Башне Времени Кроноса."
		return "От Площади Астролябии идите прямо на восток к Башне Времени Кроноса."
	if u == "orion_library" and v == "lantern_garden":
		return "От Библиотеки Ориона идите на север в Сад Небесных Фонариков."
	if u == "lantern_garden" and v == "orion_library":
		return "От Сада Фонариков пройдите на юг к Библиотеке Ориона."
	if u == "kronos_tower" and v == "mira_sanctuary":
		return "От Башни Кроноса идите на север к Дому Утешения Миры."
	if u == "mira_sanctuary" and v == "kronos_tower":
		return "От Дома Миры пройдите на юг к Башне Времени Кроноса."
	if v == "awakening_plaza":
		return "Идите на юг по бульвару к Площади Пробуждения."
	if v == "south_boulevard":
		return "Выйдите на Главный бульвар."
	if v == "orrery_plaza":
		return "Выйдите к Площади Астролябии."

	var dir_word: String = _cardinal_phrase(_get_waypoint_pos(u), _get_waypoint_pos(v))
	return "Идите %s к точке «%s»." % [dir_word, _get_waypoint_label(v)]


func _cardinal_phrase(from_pos: Vector3, to_pos: Vector3) -> String:
	var dx: float = to_pos.x - from_pos.x
	var dz: float = to_pos.z - from_pos.z
	if absf(dx) > absf(dz) * 1.4:
		return "на восток" if dx > 0.0 else "на запад"
	if absf(dz) > absf(dx) * 1.4:
		return "на север" if dz < 0.0 else "на юг"
	if dz < 0.0:
		return "на северо-восток" if dx > 0.0 else "на северо-запад"
	return "на юго-восток" if dx > 0.0 else "на юго-запад"


func _refresh_wayfinding_panel() -> void:
	var nearest_id: String = _find_nearest_waypoint_id(_player_pos)
	var loc_name: String = _get_waypoint_label(nearest_id)
	var loc_tier: String = _get_waypoint_tier(nearest_id)

	if _location_name_label != null:
		_location_name_label.text = loc_name
	if _location_tier_label != null:
		_location_tier_label.text = loc_tier

	var target_id: String = _get_active_route_target_id()
	_current_route_path = _compute_shortest_path(nearest_id, target_id)
	_current_route_distance_m = _compute_route_distance_meters(_current_route_path)

	var dest_name: String = _get_district_name(target_id)
	var dest_tier: String = _get_waypoint_tier(target_id)
	var dist_int: int = int(round(_current_route_distance_m))

	if _route_dest_label != null:
		_route_dest_label.text = dest_name
	if _route_meta_label != null:
		if dist_int < 10 and _current_route_path.size() <= 1:
			_route_meta_label.text = "Вы рядом · %s" % dest_tier
		else:
			_route_meta_label.text = "~%d м пешком · %s" % [dist_int, dest_tier]

	if _route_reset_btn != null:
		var is_custom: bool = (not _selected_route_district_id.is_empty()) and (_selected_route_district_id != _active_target_district_id)
		_route_reset_btn.visible = is_custom

	if _route_steps_vbox != null:
		for child: Node in _route_steps_vbox.get_children():
			child.queue_free()

		var steps: Array[String] = _build_route_steps(_current_route_path, _current_route_distance_m)
		for idx: int in range(steps.size()):
			var step_lbl: Label = Label.new()
			step_lbl.text = "%d. %s" % [idx + 1, steps[idx]]
			step_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			step_lbl.add_theme_font_size_override("font_size", 11)
			step_lbl.add_theme_color_override("font_color", COLOR_INK_SECONDARY)
			_route_steps_vbox.add_child(step_lbl)


# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------

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

	# 69% Illustrated Wayfinding Map | 31% Parchment Chronicle Sidebar
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
	map_frame.size_flags_stretch_ratio = 0.69
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

	# Layer 1: Live custom-drawn canvas (vignette, road network, animated golden route, compass beacon)
	_map_canvas = Control.new()
	_map_canvas.name = "MapCanvas"
	_map_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_canvas.clip_contents = true
	_map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_canvas.draw.connect(_on_map_canvas_draw)
	_map_canvas.resized.connect(_on_map_canvas_resized)
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

	# Layer 2.5: Clean «ВЫ ЗДЕСЬ» pill label next to live player beacon
	_player_here_pill = PanelContainer.new()
	_player_here_pill.name = "PlayerHerePill"
	_player_here_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_here_pill.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.082, 0.215, 0.310, 0.94), COLOR_PLAYER_TURQUOISE, 2, 10, Color(0.02, 0.08, 0.14, 0.55), 6)
	)
	map_clip.add_child(_player_here_pill)

	var here_margin: MarginContainer = MarginContainer.new()
	here_margin.add_theme_constant_override("margin_left", 8)
	here_margin.add_theme_constant_override("margin_right", 8)
	here_margin.add_theme_constant_override("margin_top", 2)
	here_margin.add_theme_constant_override("margin_bottom", 2)
	here_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_here_pill.add_child(here_margin)

	var here_lbl: Label = Label.new()
	here_lbl.text = "ВЫ ЗДЕСЬ"
	here_lbl.add_theme_font_size_override("font_size", 10)
	here_lbl.add_theme_color_override("font_color", COLOR_PLAYER_CORE)
	here_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	here_margin.add_child(here_lbl)

	# Layer 3: Compact Legend Pill in top-right corner of the map
	var legend_panel: PanelContainer = PanelContainer.new()
	legend_panel.anchor_left = 1.0
	legend_panel.anchor_right = 1.0
	legend_panel.anchor_top = 0.0
	legend_panel.anchor_bottom = 0.0
	legend_panel.offset_left = -286.0
	legend_panel.offset_right = -14.0
	legend_panel.offset_top = 14.0
	legend_panel.offset_bottom = 42.0
	legend_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.980, 0.950, 0.880, 0.92), COLOR_GOLD_ANTIQUE, 1, 9, Color(0.10, 0.07, 0.03, 0.25), 5)
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
	leg_hbox.add_theme_constant_override("separation", 10)
	leg_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leg_margin.add_child(leg_hbox)

	var leg_route: Label = Label.new()
	leg_route.text = "✦ Маршрут"
	leg_route.add_theme_font_size_override("font_size", 11)
	leg_route.add_theme_color_override("font_color", COLOR_GOLD_DEEP)
	leg_route.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leg_hbox.add_child(leg_route)

	var leg_soul: Label = Label.new()
	leg_soul.text = "▲ Вы здесь"
	leg_soul.add_theme_font_size_override("font_size", 11)
	leg_soul.add_theme_color_override("font_color", COLOR_TEAL_ACCENT)
	leg_soul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leg_hbox.add_child(leg_soul)

	var leg_stairs: Label = Label.new()
	leg_stairs.text = "≡ Лестницы"
	leg_stairs.add_theme_font_size_override("font_size", 11)
	leg_stairs.add_theme_color_override("font_color", COLOR_INK_MUTED)
	leg_stairs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leg_hbox.add_child(leg_stairs)

	# Layer 4: Parchment-Gold Hover Tooltip Card anchored at top-left of the map
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.anchor_left = 0.0
	_tooltip_panel.anchor_right = 0.0
	_tooltip_panel.anchor_top = 0.0
	_tooltip_panel.anchor_bottom = 0.0
	_tooltip_panel.offset_left = 16.0
	_tooltip_panel.offset_right = 318.0
	_tooltip_panel.offset_top = 16.0
	_tooltip_panel.offset_bottom = 136.0
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
	_tooltip_hint.text = "✦ Нажмите, чтобы проложить маршрут"
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
	side_panel.size_flags_stretch_ratio = 0.31
	side_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(COLOR_PARCHMENT, COLOR_GOLD_ANTIQUE, 2, 8, Color(0.04, 0.03, 0.02, 0.40), 10)
	)
	parent.add_child(side_panel)

	var side_margin: MarginContainer = MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 15)
	side_margin.add_theme_constant_override("margin_right", 15)
	side_margin.add_theme_constant_override("margin_top", 14)
	side_margin.add_theme_constant_override("margin_bottom", 14)
	side_panel.add_child(side_margin)

	var side_vbox: VBoxContainer = VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 9)
	side_margin.add_child(side_vbox)

	# --- Chronicle Title Header (pinned at top) ---
	var title_vbox: VBoxContainer = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 1)
	side_vbox.add_child(title_vbox)

	var title_label: Label = Label.new()
	title_label.text = "КАРТА ПУТИ"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
	title_vbox.add_child(title_label)

	var subtitle_label: Label = Label.new()
	subtitle_label.text = "Обитель Хроник Акаши · Где вы и как пройти"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 11)
	subtitle_label.add_theme_color_override("font_color", COLOR_INK_MUTED)
	title_vbox.add_child(subtitle_label)

	side_vbox.add_child(_make_ornate_divider())

	# --- Scrollable Chronicle Body (guarantees zero clipping/overflow at 1280x720) ---
	var body_scroll: ScrollContainer = ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_vbox.add_child(body_scroll)

	var body_vbox: VBoxContainer = VBoxContainer.new()
	body_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_vbox.add_theme_constant_override("separation", 9)
	body_scroll.add_child(body_vbox)

	# --- Block 1: Current Location Card («Ваше местоположение») ---
	var loc_card: PanelContainer = PanelContainer.new()
	loc_card.add_theme_stylebox_override(
		"panel",
		_make_panel_style(COLOR_TEAL_SOFT_BG, Color(0.24, 0.56, 0.64, 0.72), 1, 8, Color(0.08, 0.18, 0.22, 0.10), 3)
	)
	body_vbox.add_child(loc_card)

	var loc_margin: MarginContainer = MarginContainer.new()
	loc_margin.add_theme_constant_override("margin_left", 11)
	loc_margin.add_theme_constant_override("margin_right", 11)
	loc_margin.add_theme_constant_override("margin_top", 7)
	loc_margin.add_theme_constant_override("margin_bottom", 7)
	loc_card.add_child(loc_margin)

	var loc_vbox: VBoxContainer = VBoxContainer.new()
	loc_vbox.add_theme_constant_override("separation", 3)
	loc_margin.add_child(loc_vbox)

	var loc_header_hbox: HBoxContainer = HBoxContainer.new()
	loc_vbox.add_child(loc_header_hbox)

	var loc_hdr: Label = Label.new()
	loc_hdr.text = "▲ ВАШЕ МЕСТОПОЛОЖЕНИЕ"
	loc_hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loc_hdr.add_theme_font_size_override("font_size", 10)
	loc_hdr.add_theme_color_override("font_color", COLOR_TEAL_ACCENT)
	loc_header_hbox.add_child(loc_hdr)

	var tier_pill: PanelContainer = PanelContainer.new()
	tier_pill.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.985, 0.960, 0.895, 0.92), Color(0.24, 0.56, 0.64, 0.55), 1, 6, Color(0.0, 0.0, 0.0, 0.0), 0)
	)
	loc_header_hbox.add_child(tier_pill)

	var tier_margin: MarginContainer = MarginContainer.new()
	tier_margin.add_theme_constant_override("margin_left", 6)
	tier_margin.add_theme_constant_override("margin_right", 6)
	tier_margin.add_theme_constant_override("margin_top", 1)
	tier_margin.add_theme_constant_override("margin_bottom", 1)
	tier_pill.add_child(tier_margin)

	_location_tier_label = Label.new()
	_location_tier_label.text = "Нижний ярус"
	_location_tier_label.add_theme_font_size_override("font_size", 10)
	_location_tier_label.add_theme_color_override("font_color", COLOR_TEAL_ACCENT)
	tier_margin.add_child(_location_tier_label)

	_location_name_label = Label.new()
	_location_name_label.text = "Площадь Пробуждения"
	_location_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_location_name_label.add_theme_font_size_override("font_size", 14)
	_location_name_label.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
	loc_vbox.add_child(_location_name_label)

	# --- Block 2: Route & Step-by-Step Directions («Маршрут: [Цель]») ---
	var route_header_hbox: HBoxContainer = HBoxContainer.new()
	route_header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	body_vbox.add_child(route_header_hbox)

	_route_header_label = Label.new()
	_route_header_label.text = "✦  МАРШРУТ И ПУТЬ"
	_route_header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_route_header_label.add_theme_font_size_override("font_size", 11)
	_route_header_label.add_theme_color_override("font_color", COLOR_GOLD_DEEP)
	route_header_hbox.add_child(_route_header_label)

	_route_reset_btn = Button.new()
	_route_reset_btn.text = "К цели задания"
	_route_reset_btn.focus_mode = Control.FOCUS_NONE
	_route_reset_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_route_reset_btn.add_theme_font_size_override("font_size", 10)
	_route_reset_btn.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
	_route_reset_btn.add_theme_color_override("font_hover_color", COLOR_INK_PRIMARY)
	var reset_normal: StyleBoxFlat = _make_panel_style(Color(0.96, 0.87, 0.56, 0.94), COLOR_GOLD_DEEP, 1, 6, Color(0.0, 0.0, 0.0, 0.0), 0)
	reset_normal.content_margin_left = 8.0
	reset_normal.content_margin_right = 8.0
	reset_normal.content_margin_top = 3.0
	reset_normal.content_margin_bottom = 3.0
	_route_reset_btn.add_theme_stylebox_override("normal", reset_normal)

	var reset_hover: StyleBoxFlat = _make_panel_style(Color(1.0, 0.91, 0.62, 1.0), COLOR_GOLD_DEEP, 1, 6, Color(0.0, 0.0, 0.0, 0.0), 0)
	reset_hover.content_margin_left = 8.0
	reset_hover.content_margin_right = 8.0
	reset_hover.content_margin_top = 3.0
	reset_hover.content_margin_bottom = 3.0
	_route_reset_btn.add_theme_stylebox_override("hover", reset_hover)

	var reset_pressed: StyleBoxFlat = _make_panel_style(COLOR_GOLD_ANTIQUE, COLOR_GOLD_DEEP, 1, 6, Color(0.0, 0.0, 0.0, 0.0), 0)
	reset_pressed.content_margin_left = 8.0
	reset_pressed.content_margin_right = 8.0
	reset_pressed.content_margin_top = 3.0
	reset_pressed.content_margin_bottom = 3.0
	_route_reset_btn.add_theme_stylebox_override("pressed", reset_pressed)
	_route_reset_btn.pressed.connect(_on_reset_route_to_quest)
	_route_reset_btn.visible = false
	route_header_hbox.add_child(_route_reset_btn)

	var route_card: PanelContainer = PanelContainer.new()
	route_card.add_theme_stylebox_override(
		"panel",
		_make_panel_style(COLOR_PARCHMENT_CARD, COLOR_GOLD_ANTIQUE, 1, 8, Color(0.20, 0.14, 0.05, 0.12), 4)
	)
	body_vbox.add_child(route_card)

	var route_margin: MarginContainer = MarginContainer.new()
	route_margin.add_theme_constant_override("margin_left", 11)
	route_margin.add_theme_constant_override("margin_right", 11)
	route_margin.add_theme_constant_override("margin_top", 8)
	route_margin.add_theme_constant_override("margin_bottom", 9)
	route_card.add_child(route_margin)

	var route_vbox: VBoxContainer = VBoxContainer.new()
	route_vbox.add_theme_constant_override("separation", 5)
	route_margin.add_child(route_vbox)

	_route_dest_label = Label.new()
	_route_dest_label.text = "Площадь Пробуждения"
	_route_dest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_route_dest_label.add_theme_font_size_override("font_size", 14)
	_route_dest_label.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
	route_vbox.add_child(_route_dest_label)

	_route_meta_label = Label.new()
	_route_meta_label.text = "~0 м пешком · Нижний ярус"
	_route_meta_label.add_theme_font_size_override("font_size", 11)
	_route_meta_label.add_theme_color_override("font_color", COLOR_TEAL_ACCENT)
	route_vbox.add_child(_route_meta_label)

	var route_div: ColorRect = ColorRect.new()
	route_div.custom_minimum_size = Vector2(0.0, 1.0)
	route_div.color = COLOR_GOLD_SOFT
	route_vbox.add_child(route_div)

	_route_steps_vbox = VBoxContainer.new()
	_route_steps_vbox.add_theme_constant_override("separation", 4)
	route_vbox.add_child(_route_steps_vbox)

	# --- Block 3: Current Quest («Текущее задание») ---
	var quest_header: Label = Label.new()
	quest_header.text = "✦  ТЕКУЩЕЕ ЗАДАНИЕ"
	quest_header.add_theme_font_size_override("font_size", 11)
	quest_header.add_theme_color_override("font_color", COLOR_GOLD_DEEP)
	body_vbox.add_child(quest_header)

	var quest_card: PanelContainer = PanelContainer.new()
	quest_card.add_theme_stylebox_override(
		"panel",
		_make_panel_style(COLOR_PARCHMENT_CARD, COLOR_GOLD_ANTIQUE, 1, 8, Color(0.20, 0.14, 0.05, 0.10), 3)
	)
	body_vbox.add_child(quest_card)

	var quest_margin: MarginContainer = MarginContainer.new()
	quest_margin.add_theme_constant_override("margin_left", 11)
	quest_margin.add_theme_constant_override("margin_right", 11)
	quest_margin.add_theme_constant_override("margin_top", 8)
	quest_margin.add_theme_constant_override("margin_bottom", 8)
	quest_card.add_child(quest_margin)

	var quest_vbox: VBoxContainer = VBoxContainer.new()
	quest_vbox.add_theme_constant_override("separation", 4)
	quest_margin.add_child(quest_vbox)

	_quest_title_label = Label.new()
	_quest_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_title_label.add_theme_font_size_override("font_size", 13)
	_quest_title_label.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
	quest_vbox.add_child(_quest_title_label)

	_quest_objective_label = Label.new()
	_quest_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_objective_label.add_theme_font_size_override("font_size", 11)
	_quest_objective_label.add_theme_color_override("font_color", COLOR_INK_SECONDARY)
	quest_vbox.add_child(_quest_objective_label)

	_quest_district_label = Label.new()
	_quest_district_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_district_label.add_theme_font_size_override("font_size", 11)
	_quest_district_label.add_theme_color_override("font_color", COLOR_TEAL_ACCENT)
	quest_vbox.add_child(_quest_district_label)

	# --- Block 4: Memory Bag («Сумка Воспоминаний») ---
	var bag_header_hbox: HBoxContainer = HBoxContainer.new()
	body_vbox.add_child(bag_header_hbox)

	var bag_header: Label = Label.new()
	bag_header.text = "✦  СУМКА ВОСПОМИНАНИЙ"
	bag_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_header.add_theme_font_size_override("font_size", 11)
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

	_bag_list_vbox = VBoxContainer.new()
	_bag_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bag_list_vbox.add_theme_constant_override("separation", 6)
	body_vbox.add_child(_bag_list_vbox)

	# --- Bottom Pinned Close Button ---
	_close_button = Button.new()
	_close_button.text = "Закрыть карту [M / Esc]"
	_close_button.custom_minimum_size = Vector2(0.0, 40.0)
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_button.add_theme_font_size_override("font_size", 13)
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
	star.add_theme_font_size_override("font_size", 11)
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
		empty_margin.add_theme_constant_override("margin_left", 10)
		empty_margin.add_theme_constant_override("margin_right", 10)
		empty_margin.add_theme_constant_override("margin_top", 10)
		empty_margin.add_theme_constant_override("margin_bottom", 10)
		empty_panel.add_child(empty_margin)

		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Пока пусто — исследуйте кварталы Города Душ"
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 11)
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
		card_margin.add_theme_constant_override("margin_left", 9)
		card_margin.add_theme_constant_override("margin_right", 9)
		card_margin.add_theme_constant_override("margin_top", 7)
		card_margin.add_theme_constant_override("margin_bottom", 7)
		card.add_child(card_margin)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		card_margin.add_child(hbox)

		var star_lbl: Label = Label.new()
		star_lbl.text = "✦"
		star_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		star_lbl.add_theme_font_size_override("font_size", 13)
		star_lbl.add_theme_color_override("font_color", COLOR_GOLD_DEEP)
		hbox.add_child(star_lbl)

		var text_vbox: VBoxContainer = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(text_vbox)

		var title_lbl: Label = Label.new()
		title_lbl.text = item_title
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.add_theme_font_size_override("font_size", 12)
		title_lbl.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
		text_vbox.add_child(title_lbl)

		if not item_desc.is_empty():
			var desc_lbl: Label = Label.new()
			desc_lbl.text = item_desc
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.add_theme_font_size_override("font_size", 10)
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


func _world_to_uv_base(world_pos: Vector3) -> Vector2:
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


func _world_to_uv(world_pos: Vector3) -> Vector2:
	var base_uv: Vector2 = _world_to_uv_base(world_pos)
	var weighted_uv: Vector2 = Vector2.ZERO
	var total_weight: float = 0.0
	var min_dist: float = INF

	for wp_var: Variant in WAYPOINT_DEFS:
		if not (wp_var is Dictionary):
			continue
		var wp: Dictionary = wp_var as Dictionary
		var pos_var: Variant = wp.get("pos", Vector3.ZERO)
		var uv_var: Variant = wp.get("uv", Vector2(0.5, 0.5))
		if not (pos_var is Vector3) or not (uv_var is Vector2):
			continue
		var anchor_pos: Vector3 = pos_var as Vector3
		var anchor_uv: Vector2 = uv_var as Vector2
		var dx: float = world_pos.x - anchor_pos.x
		var dz: float = world_pos.z - anchor_pos.z
		var dist_sq: float = dx * dx + dz * dz
		var dist: float = sqrt(dist_sq)
		if dist < 0.05:
			return anchor_uv
		if dist < min_dist:
			min_dist = dist
		var w: float = 1.0 / (dist_sq * dist_sq)
		weighted_uv += anchor_uv * w
		total_weight += w

	if total_weight <= 0.0:
		return base_uv

	var idw_uv: Vector2 = weighted_uv / total_weight
	if min_dist > 35.0:
		var far_blend: float = clampf((min_dist - 35.0) / 45.0, 0.0, 1.0)
		return idw_uv.lerp(base_uv, far_blend)
	return idw_uv


func _world_to_map(world_pos: Vector3, canvas_size: Vector2) -> Vector2:
	return _uv_to_canvas(_world_to_uv(world_pos), canvas_size)


func _get_district_canvas_pos(district_id: String, canvas_size: Vector2) -> Vector2:
	if _district_by_id.has(district_id):
		var entry: Dictionary = _district_by_id[district_id] as Dictionary
		var uv_var: Variant = entry.get("uv", Vector2(0.5, 0.5))
		if uv_var is Vector2:
			return _uv_to_canvas(uv_var as Vector2, canvas_size)
	return canvas_size * 0.5


func _get_waypoint_canvas_pos(node_id: String, canvas_size: Vector2) -> Vector2:
	return _uv_to_canvas(_get_waypoint_uv(node_id), canvas_size)


func _on_map_canvas_resized() -> void:
	_update_district_node_positions()
	_update_player_here_pill_position()


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


func _update_player_here_pill_position() -> void:
	if _map_canvas == null or _player_here_pill == null:
		return
	var canvas_size: Vector2 = _map_canvas.size
	if canvas_size.x < 20.0 or canvas_size.y < 20.0:
		return

	var p_pt: Vector2 = _world_to_map(_player_pos, canvas_size)
	var pill_size: Vector2 = _player_here_pill.get_combined_minimum_size()
	var pill_w: float = maxf(pill_size.x, 78.0)
	var pill_h: float = maxf(pill_size.y, 20.0)

	# Place slightly to the right of the player beacon; flip left if near right edge
	var desired_x: float = p_pt.x + 18.0
	if desired_x + pill_w > canvas_size.x - 14.0:
		desired_x = p_pt.x - pill_w - 18.0
	var desired_y: float = p_pt.y - pill_h * 0.5

	var clamped_x: float = clampf(desired_x, 14.0, maxf(14.0, canvas_size.x - pill_w - 14.0))
	var clamped_y: float = clampf(desired_y, 50.0, maxf(50.0, canvas_size.y - pill_h - 14.0))
	_player_here_pill.position = Vector2(clamped_x, clamped_y)


func _update_district_button_styles() -> void:
	var quest_target: String = _active_target_district_id
	var qm: Node = _get_quest_manager()
	if qm != null:
		quest_target = str(qm.call("get_current_target_district"))
		_active_target_district_id = quest_target

	var route_target: String = _get_active_route_target_id()

	for d_id_var: Variant in _district_buttons.keys():
		var d_id: String = str(d_id_var)
		var btn: Button = _district_buttons[d_id] as Button
		var entry: Dictionary = _district_by_id.get(d_id, {}) as Dictionary
		var default_icon: String = str(entry.get("icon", "◈"))
		var is_route_target: bool = (d_id == route_target)
		var is_quest_target: bool = (d_id == quest_target)

		if is_route_target:
			btn.text = "✦"
			btn.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
			btn.add_theme_color_override("font_hover_color", COLOR_INK_PRIMARY)
			btn.add_theme_color_override("font_pressed_color", COLOR_IVORY_PIN)
			btn.add_theme_stylebox_override(
				"normal",
				_make_panel_style(COLOR_ROUTE_PIN_FILL, COLOR_IVORY_PIN, 2, 17, Color(0.55, 0.36, 0.05, 0.58), 8)
			)
			btn.add_theme_stylebox_override(
				"hover",
				_make_panel_style(Color(1.0, 0.87, 0.42, 1.0), COLOR_IVORY_PIN, 3, 17, Color(0.75, 0.52, 0.10, 0.68), 10)
			)
			btn.add_theme_stylebox_override(
				"pressed",
				_make_panel_style(COLOR_GOLD_DEEP, COLOR_GOLD_BRIGHT, 2, 17, Color(0.20, 0.14, 0.04, 0.45), 4)
			)
		elif is_quest_target:
			btn.text = "✦"
			btn.add_theme_color_override("font_color", COLOR_INK_PRIMARY)
			btn.add_theme_color_override("font_hover_color", COLOR_INK_PRIMARY)
			btn.add_theme_color_override("font_pressed_color", COLOR_IVORY_PIN)
			btn.add_theme_stylebox_override(
				"normal",
				_make_panel_style(COLOR_QUEST_PIN_FILL, COLOR_GOLD_DEEP, 2, 17, Color(0.45, 0.30, 0.05, 0.45), 6)
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
			if is_route_target:
				nameplate.add_theme_stylebox_override(
					"panel",
					_make_panel_style(Color(1.0, 0.962, 0.835, 0.96), COLOR_GOLD_DEEP, 2, 7, Color(0.28, 0.18, 0.04, 0.38), 5)
				)
			else:
				nameplate.add_theme_stylebox_override(
					"panel",
					_make_panel_style(Color(0.985, 0.955, 0.885, 0.92), Color(0.788, 0.627, 0.282, 0.85), 1, 7, Color(0.12, 0.08, 0.03, 0.30), 4)
				)


# ---------------------------------------------------------------------------
# Live Custom Overlay Drawing (Road Network, Animated Route, Compass Beacon)
# ---------------------------------------------------------------------------

func _on_map_canvas_draw() -> void:
	var s: Vector2 = _map_canvas.size
	if s.x < 10.0 or s.y < 10.0:
		return

	# 1. Delicate warm sepia edge vignette & antique-gold inner filigree corners
	_draw_soft_vignette(_map_canvas, s)
	_draw_corner_filigree(_map_canvas, s)

	# 2. Subtle Walkable Road, Stairs & Interactive Venues Network
	_draw_walkable_network(_map_canvas, s)

	# 3. Animated Golden-Amber Route Line from player to selected destination
	_draw_animated_route(_map_canvas, s)

	# 4. Pulsing Golden Halo around active route destination (and subtle secondary quest halo)
	var route_target: String = _get_active_route_target_id()
	if not route_target.is_empty() and _district_by_id.has(route_target):
		var dest_pt: Vector2 = _get_district_canvas_pos(route_target, s)
		var pulse_a: float = fmod(_time * 0.72, 1.0)
		var pulse_b: float = fmod(_time * 0.72 + 0.5, 1.0)
		var rad_a: float = lerpf(18.0, 46.0, pulse_a)
		var rad_b: float = lerpf(18.0, 46.0, pulse_b)
		var alpha_a: float = (1.0 - pulse_a) * 0.88
		var alpha_b: float = (1.0 - pulse_b) * 0.68

		_map_canvas.draw_circle(dest_pt, 26.0, Color(0.96, 0.80, 0.30, 0.24))
		_map_canvas.draw_arc(dest_pt, rad_a, 0.0, TAU, 40, Color(0.98, 0.84, 0.36, alpha_a), 2.8, true)
		_map_canvas.draw_arc(dest_pt, rad_b, 0.0, TAU, 40, Color(1.0, 0.92, 0.58, alpha_b), 1.8, true)

	if not _active_target_district_id.is_empty() and _active_target_district_id != route_target and _district_by_id.has(_active_target_district_id):
		var q_pt: Vector2 = _get_district_canvas_pos(_active_target_district_id, s)
		var q_pulse: float = 0.5 + 0.5 * sin(_time * 2.4)
		_map_canvas.draw_arc(q_pt, lerpf(21.0, 26.0, q_pulse), 0.0, TAU, 36, Color(0.94, 0.76, 0.28, 0.55), 2.0, true)

	# 5. Crisp golden hover highlight ring around hovered pin
	if not _hovered_district_id.is_empty() and _district_by_id.has(_hovered_district_id):
		var h_pt: Vector2 = _get_district_canvas_pos(_hovered_district_id, s)
		_map_canvas.draw_circle(h_pt, 24.0, Color(1.0, 0.92, 0.62, 0.22))
		_map_canvas.draw_arc(h_pt, 24.0, 0.0, TAU, 36, Color(0.96, 0.82, 0.38, 0.82), 2.0, true)

	# 6. Luminous Turquoise-and-Gold Player Beacon with Directional Compass Arrowhead
	_draw_player_compass_beacon(_map_canvas, s)


func _draw_walkable_network(canvas: Control, s: Vector2) -> void:
	var road_under: Color = Color(0.98, 0.95, 0.86, 0.34)
	var road_dash: Color = Color(0.42, 0.29, 0.14, 0.48)

	for edge_var: Variant in WAYPOINT_EDGES:
		if not (edge_var is Array):
			continue
		var edge: Array = edge_var as Array
		if edge.size() < 2:
			continue
		var a_id: String = str(edge[0])
		var b_id: String = str(edge[1])
		var pt_a: Vector2 = _get_waypoint_canvas_pos(a_id, s)
		var pt_b: Vector2 = _get_waypoint_canvas_pos(b_id, s)
		canvas.draw_line(pt_a, pt_b, road_under, 4.0, true)
		_draw_dashed_segment(canvas, pt_a, pt_b, road_dash, 1.8, 6.0, 5.0, 0.0)

	# Draw small antique-gold stair badges (≡) & interactive venue diamonds
	for wp_var: Variant in WAYPOINT_DEFS:
		if not (wp_var is Dictionary):
			continue
		var wp: Dictionary = wp_var as Dictionary
		var wp_id: String = str(wp.get("id", ""))
		var kind: String = str(wp.get("kind", ""))
		var pt: Vector2 = _get_waypoint_canvas_pos(wp_id, s)

		if kind == "stairs":
			canvas.draw_circle(pt, 7.5, Color(0.985, 0.955, 0.880, 0.92))
			canvas.draw_arc(pt, 7.5, 0.0, TAU, 20, COLOR_GOLD_DEEP, 1.4, true)
			# Three crisp horizontal step bars (≡)
			canvas.draw_line(pt + Vector2(-3.8, -2.6), pt + Vector2(3.8, -2.6), COLOR_INK_PRIMARY, 1.4, true)
			canvas.draw_line(pt + Vector2(-3.8, 0.0), pt + Vector2(3.8, 0.0), COLOR_INK_PRIMARY, 1.4, true)
			canvas.draw_line(pt + Vector2(-3.8, 2.6), pt + Vector2(3.8, 2.6), COLOR_INK_PRIMARY, 1.4, true)
		elif kind == "venue":
			var r: float = 4.6
			var diamond: PackedVector2Array = PackedVector2Array([
				pt + Vector2(0.0, -r),
				pt + Vector2(r, 0.0),
				pt + Vector2(0.0, r),
				pt + Vector2(-r, 0.0),
			])
			canvas.draw_colored_polygon(diamond, Color(0.96, 0.88, 0.64, 0.92))
			canvas.draw_polyline(
				PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
				COLOR_GOLD_DEEP,
				1.2,
				true
			)


func _draw_animated_route(canvas: Control, s: Vector2) -> void:
	if _current_route_path.is_empty() or (_current_route_path.size() == 1 and _current_route_distance_m < 12.0):
		return

	var p_pt: Vector2 = _world_to_map(_player_pos, s)
	var pts: Array[Vector2] = [p_pt]

	var start_idx: int = 0
	if _current_route_path.size() >= 2:
		var wp0_pt: Vector2 = _get_waypoint_canvas_pos(_current_route_path[0], s)
		var wp1_pt: Vector2 = _get_waypoint_canvas_pos(_current_route_path[1], s)
		var seg: Vector2 = wp1_pt - wp0_pt
		var seg_len_sq: float = seg.length_squared()
		if p_pt.distance_to(wp0_pt) < 12.0:
			start_idx = 1
		elif seg_len_sq > 16.0:
			var proj_t: float = (p_pt - wp0_pt).dot(seg) / seg_len_sq
			if proj_t > 0.05 and proj_t <= 1.05:
				start_idx = 1

	for i: int in range(start_idx, _current_route_path.size()):
		var wp_pt: Vector2 = _get_waypoint_canvas_pos(_current_route_path[i], s)
		if pts[pts.size() - 1].distance_to(wp_pt) > 3.0:
			pts.append(wp_pt)

	if pts.size() < 2:
		return

	var poly: PackedVector2Array = PackedVector2Array()
	for pt: Vector2 in pts:
		poly.append(pt)

	# Soft luminous golden outer glow + warm espresso contrast backing
	canvas.draw_polyline(poly, Color(0.98, 0.80, 0.24, 0.28), 9.5, true)
	canvas.draw_polyline(poly, Color(0.28, 0.17, 0.05, 0.55), 5.2, true)

	# Animated marching golden-amber dashes & directional chevrons
	var dash_len: float = 10.0
	var gap_len: float = 7.0
	var phase: float = fmod(_time * 28.0, dash_len + gap_len)
	var route_gold: Color = Color(1.0, 0.87, 0.34, 0.98)
	var chevron_col: Color = Color(1.0, 0.96, 0.78, 0.95)

	for i: int in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		_draw_dashed_segment(canvas, a, b, route_gold, 3.0, dash_len, gap_len, phase)

		# Place directional chevrons along longer segments
		var seg_len: float = a.distance_to(b)
		if seg_len >= 34.0:
			var dir: Vector2 = (b - a) / seg_len
			var perp: Vector2 = Vector2(-dir.y, dir.x)
			var chev_count: int = clampi(int(seg_len / 56.0), 1, 3)
			for c_idx: int in range(chev_count):
				var frac: float = float(c_idx + 1) / float(chev_count + 1)
				var mid: Vector2 = a.lerp(b, frac)
				var tip: Vector2 = mid + dir * 4.5
				var left_wing: Vector2 = mid - dir * 3.5 + perp * 4.5
				var right_wing: Vector2 = mid - dir * 3.5 - perp * 4.5
				canvas.draw_line(left_wing, tip, Color(0.24, 0.14, 0.03, 0.75), 3.0, true)
				canvas.draw_line(right_wing, tip, Color(0.24, 0.14, 0.03, 0.75), 3.0, true)
				canvas.draw_line(left_wing, tip, chevron_col, 1.7, true)
				canvas.draw_line(right_wing, tip, chevron_col, 1.7, true)


func _draw_dashed_segment(
	canvas: Control,
	a: Vector2,
	b: Vector2,
	col: Color,
	width: float,
	dash_len: float,
	gap_len: float,
	phase: float
) -> void:
	var seg_vec: Vector2 = b - a
	var total_len: float = seg_vec.length()
	if total_len < 1.0:
		return
	var dir: Vector2 = seg_vec / total_len
	var period: float = dash_len + gap_len
	var cursor: float = -period + fmod(phase, period)
	while cursor < total_len:
		var d0: float = maxf(0.0, cursor)
		var d1: float = minf(total_len, cursor + dash_len)
		if d1 > d0 + 0.5:
			canvas.draw_line(a + dir * d0, a + dir * d1, col, width, true)
		cursor += period


func _draw_player_compass_beacon(canvas: Control, s: Vector2) -> void:
	var p_pt: Vector2 = _world_to_map(_player_pos, s)
	var soul_pulse: float = 0.5 + 0.5 * sin(_time * 3.2)
	var ripple_t: float = fmod(_time * 0.9, 1.0)
	var ripple_r: float = lerpf(10.0, 26.0, ripple_t)
	var halo_r: float = lerpf(12.0, 16.5, soul_pulse)

	# Outer turquoise-and-gold ripple + soft luminous aura
	canvas.draw_arc(p_pt, ripple_r, 0.0, TAU, 32, Color(0.28, 0.90, 0.98, (1.0 - ripple_t) * 0.75), 2.0, true)
	canvas.draw_circle(p_pt, halo_r, Color(0.22, 0.84, 0.96, 0.25))
	canvas.draw_arc(p_pt, 11.5, 0.0, TAU, 28, Color(0.98, 0.84, 0.38, 0.75), 1.4, true)

	# Directional compass arrowhead matching player's 3D look yaw:
	# 3D forward = (-sin(yaw), 0, -cos(yaw)) -> 2D map (+X = East, -Y = North) = (-sin(yaw), -cos(yaw))
	var forward_2d: Vector2 = Vector2(-sin(_player_yaw), -cos(_player_yaw))
	if forward_2d.length_squared() < 0.001:
		forward_2d = Vector2(0.0, -1.0)
	else:
		forward_2d = forward_2d.normalized()
	var right_2d: Vector2 = Vector2(-forward_2d.y, forward_2d.x)

	# Subtle view-cone glow in front of the player
	var cone_pts: PackedVector2Array = PackedVector2Array([
		p_pt,
		p_pt + (forward_2d * 22.0 + right_2d * 10.0),
		p_pt + (forward_2d * 25.0),
		p_pt + (forward_2d * 22.0 - right_2d * 10.0),
	])
	canvas.draw_colored_polygon(cone_pts, Color(0.32, 0.92, 1.0, 0.22))

	# Outer sapphire shadow backing for crisp contrast over parchment and turquoise river
	var outer_arrow: PackedVector2Array = PackedVector2Array([
		p_pt + forward_2d * 15.0,
		p_pt - forward_2d * 8.0 + right_2d * 9.5,
		p_pt - forward_2d * 3.5,
		p_pt - forward_2d * 8.0 - right_2d * 9.5,
	])
	canvas.draw_colored_polygon(outer_arrow, Color(0.06, 0.16, 0.28, 0.94))

	# Inner turquoise compass arrow
	var inner_arrow: PackedVector2Array = PackedVector2Array([
		p_pt + forward_2d * 12.2,
		p_pt - forward_2d * 6.0 + right_2d * 7.2,
		p_pt - forward_2d * 2.4,
		p_pt - forward_2d * 6.0 - right_2d * 7.2,
	])
	canvas.draw_colored_polygon(inner_arrow, COLOR_PLAYER_TURQUOISE)
	canvas.draw_circle(p_pt, 2.8, COLOR_PLAYER_CORE)
	canvas.draw_polyline(
		PackedVector2Array([outer_arrow[0], outer_arrow[1], outer_arrow[2], outer_arrow[3], outer_arrow[0]]),
		Color(1.0, 0.94, 0.72, 0.95),
		1.4,
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
# Interaction, Hover Animations & Signal Wiring (ZERO Teleport)
# ---------------------------------------------------------------------------

func _on_district_clicked(district_id: String) -> void:
	_selected_route_district_id = district_id
	_refresh_wayfinding_panel()
	_update_district_button_styles()
	if _hovered_district_id == district_id:
		_update_tooltip_hint(district_id)
	if _map_canvas != null:
		_map_canvas.queue_redraw()


func _on_reset_route_to_quest() -> void:
	_selected_route_district_id = ""
	_refresh_wayfinding_panel()
	_update_district_button_styles()
	if not _hovered_district_id.is_empty():
		_update_tooltip_hint(_hovered_district_id)
	if _map_canvas != null:
		_map_canvas.queue_redraw()


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


func _update_tooltip_hint(district_id: String) -> void:
	if _tooltip_hint == null:
		return
	if district_id == _get_active_route_target_id():
		_tooltip_hint.text = "✦ Выбрано целью маршрута"
		_tooltip_hint.add_theme_color_override("font_color", COLOR_TEAL_ACCENT)
	else:
		_tooltip_hint.text = "✦ Нажмите, чтобы проложить маршрут"
		_tooltip_hint.add_theme_color_override("font_color", COLOR_GOLD_DEEP)


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
	_update_tooltip_hint(district_id)
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
	_selected_route_district_id = ""
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
	if _waypoints_by_id.has(district_id):
		var wp: Dictionary = _waypoints_by_id[district_id] as Dictionary
		return str(wp.get("label", district_id))
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
