extends Node

## Multi-step Quest & Memory Bag manager for SoulBlueprint (Godot 4.3+).
## Registered as Autoload `QuestManager` (no class_name to avoid name collision).

signal quest_changed(quest_id: String, title: String, objective: String, target_pos: Vector3)
signal inventory_changed(items: Array[Dictionary])
signal quest_completed_toast(title: String)

const BLUEPRINT_PIECE_ORDER: Array = [
	"memory_drop",
	"blank_page",
	"seven_springs_sand",
]

const BLUEPRINT_PIECE_META: Dictionary = {
	"memory_drop": {
		"title": "Капля Памяти",
		"description": "Прозрачная капля из Озера Тишины, хранящая тихое тепло несказанных слов.",
		"place": "Озёрный Парк Тишины",
		"district": "quiet_lakes_park",
		"pos": Vector3(42.0, 0.0, 10.0),
	},
	"blank_page": {
		"title": "Чистая Страница Судьбы",
		"description": "Светлый лист из Библиотеки Ориона — начало книги, которую будут перечитывать вновь.",
		"place": "Библиотека Ориона",
		"district": "orion_library",
		"pos": Vector3(-42.0, 3.2, -78.0),
	},
	"seven_springs_sand": {
		"title": "Песок Семи Вёсен",
		"description": "Горсть золотого песка из Башни Кроноса — мера короткой, но бесценной земной жизни.",
		"place": "Башня Времени Кроноса",
		"district": "kronos_tower",
		"pos": Vector3(42.0, 3.2, -78.0),
	},
}

const SOUL_BLUEPRINT_SCROLL_ID: String = "soul_blueprint_scroll"
const SOUL_BLUEPRINT_SCROLL_TITLE: String = "Чертёж Первого Воплощения"
const SOUL_BLUEPRINT_SCROLL_DESC: String = "Сплетённый Алатеей светлый свиток Первого Контракта: семь вёсен любви ради двух озябших сердец."

const QUEST_ORDER: Array = [
	"q1_meet_lumi",
	"q2_find_school",
	"q3_gather_blueprint",
	"q4_return_to_school",
	"q5_go_to_mirror",
	"q6_awaken_mirror",
	"q7_sunset_comfort",
	"q8_complete",
]

const QUEST_DATA: Dictionary = {
	"q1_meet_lumi": {
		"title": "Первые шаги в Городе Душ",
		"objective": "Поговорите с Люми на Площади Пробуждения",
		"target_pos": Vector3(0.0, 0.0, 42.0),
		"district": "awakening_plaza",
	},
	"q2_find_school": {
		"title": "Школа Юных Душ",
		"objective": "Найдите Наставницу Алатею в Школе Юных Душ (западнее площади, карта [M])",
		"target_pos": Vector3(-36.0, 3.2, 8.0),
		"district": "school_of_souls",
	},
	"q3_gather_blueprint": {
		"title": "Три основы Чертежа Души",
		"objective": "Соберите три основы Чертежа Души (0 / 3)",
		"target_pos": Vector3(42.0, 0.0, 10.0),
		"district": "quiet_lakes_park",
	},
	"q4_return_to_school": {
		"title": "Сплетение Чертежа",
		"objective": "Вернитесь в Школу Юных Душ к Алатее и передайте три основы",
		"target_pos": Vector3(-36.0, 3.2, 8.0),
		"district": "school_of_souls",
	},
	"q5_go_to_mirror": {
		"title": "Храм Зеркала Земли",
		"objective": "Поднимитесь на север в Храм Зеркала Земли к Мире и Алатее",
		"target_pos": Vector3(0.0, 8.0, -286.0),
		"district": "earth_mirror_temple",
	},
	"q6_awaken_mirror": {
		"title": "Шаг в Земную Жизнь",
		"objective": "Пробудите Зеркало Земли Зовом Света [Q] и шагните в Урок 1",
		"target_pos": Vector3(0.0, 8.0, -296.0),
		"district": "earth_mirror_temple",
	},
	"q7_sunset_comfort": {
		"title": "Знаки Утешения (Золотой закат)",
		"objective": "Найдите и отправьте родителям Знаки Утешения (найдено 0 / 3, отправлено 0 / 3)",
		"target_pos": Vector3(34.0, 3.2, -138.0),
		"district": "mira_sanctuary",
	},
	"q8_complete": {
		"title": "Золотой Свет Любви",
		"objective": "Первый Урок завершён. Исследуйте закатный Город Душ",
		"target_pos": Vector3(0.0, 0.0, -32.0),
		"district": "central_boulevard",
	},
}

var _current_quest_id: String = "q1_meet_lumi"
var _inventory: Array[Dictionary] = []
var _collected_blueprint_pieces: Array[String] = []
var _comfort_signs_found: int = 0
var _comfort_signs_sent: int = 0


func _ready() -> void:
	pass


# ---------------------------------------------------------------------------
# Quest Progression API
# ---------------------------------------------------------------------------

func set_quest(quest_id: String) -> void:
	if not QUEST_DATA.has(quest_id):
		push_warning("QuestManager: unknown quest_id '%s'" % quest_id)
		return

	var prev_id: String = _current_quest_id
	var prev_index: int = QUEST_ORDER.find(prev_id)
	var next_index: int = QUEST_ORDER.find(quest_id)
	var prev_title: String = get_current_quest_title()

	_current_quest_id = quest_id

	if prev_id != quest_id and prev_index >= 0 and next_index > prev_index:
		quest_completed_toast.emit(prev_title)

	_emit_current_quest()


func get_current_quest_id() -> String:
	return _current_quest_id


func get_current_quest_title() -> String:
	var def: Dictionary = _get_quest_def(_current_quest_id)
	return str(def.get("title", ""))


func get_current_objective() -> String:
	if _current_quest_id == "q3_gather_blueprint":
		return _build_gather_blueprint_objective()
	if _current_quest_id == "q7_sunset_comfort":
		return _build_sunset_comfort_objective()

	var def: Dictionary = _get_quest_def(_current_quest_id)
	return str(def.get("objective", ""))


func get_current_target_pos() -> Vector3:
	if _current_quest_id == "q3_gather_blueprint":
		var next_piece: Dictionary = _get_next_uncollected_piece_meta()
		if not next_piece.is_empty():
			var piece_pos_var: Variant = next_piece.get("pos", Vector3(42.0, 0.0, 10.0))
			if piece_pos_var is Vector3:
				return piece_pos_var as Vector3

	if _current_quest_id == "q7_sunset_comfort":
		if _comfort_signs_found >= 3 and _comfort_signs_sent < 3:
			return Vector3(0.0, 8.0, -286.0)
		return Vector3(34.0, 3.2, -138.0)

	var def: Dictionary = _get_quest_def(_current_quest_id)
	var pos_var: Variant = def.get("target_pos", Vector3.ZERO)
	if pos_var is Vector3:
		return pos_var as Vector3
	return Vector3.ZERO


func get_current_target_district() -> String:
	if _current_quest_id == "q3_gather_blueprint":
		var next_piece: Dictionary = _get_next_uncollected_piece_meta()
		if not next_piece.is_empty():
			return str(next_piece.get("district", "quiet_lakes_park"))

	if _current_quest_id == "q7_sunset_comfort":
		if _comfort_signs_found >= 3 and _comfort_signs_sent < 3:
			return "earth_mirror_temple"
		return "mira_sanctuary"

	var def: Dictionary = _get_quest_def(_current_quest_id)
	return str(def.get("district", "awakening_plaza"))


func update_sunset_comfort_progress(found_count: int, sent_count: int) -> void:
	_comfort_signs_found = clampi(found_count, 0, 3)
	_comfort_signs_sent = clampi(sent_count, 0, 3)
	if _current_quest_id == "q7_sunset_comfort":
		_emit_current_quest()


# ---------------------------------------------------------------------------
# Blueprint Pieces API
# ---------------------------------------------------------------------------

func mark_blueprint_piece_collected(item_id: String) -> void:
	if not BLUEPRINT_PIECE_META.has(item_id):
		push_warning("QuestManager: unknown blueprint piece '%s'" % item_id)
		return

	if not _collected_blueprint_pieces.has(item_id):
		_collected_blueprint_pieces.append(item_id)

	var meta_var: Variant = BLUEPRINT_PIECE_META.get(item_id, {})
	if meta_var is Dictionary:
		var meta: Dictionary = meta_var as Dictionary
		add_item(
			item_id,
			str(meta.get("title", item_id)),
			str(meta.get("description", ""))
		)

	if has_all_blueprint_pieces():
		if _current_quest_id == "q1_meet_lumi" or _current_quest_id == "q2_find_school" or _current_quest_id == "q3_gather_blueprint":
			set_quest("q4_return_to_school")
		else:
			_emit_current_quest()
	elif _current_quest_id == "q3_gather_blueprint":
		_emit_current_quest()


func has_all_blueprint_pieces() -> bool:
	for piece_var: Variant in BLUEPRINT_PIECE_ORDER:
		var piece_id: String = str(piece_var)
		if not _collected_blueprint_pieces.has(piece_id):
			return false
	return true


func is_blueprint_piece_collected(item_id: String) -> bool:
	return _collected_blueprint_pieces.has(item_id)


func get_blueprint_collected_count() -> int:
	return _collected_blueprint_pieces.size()


func consume_blueprint_pieces() -> void:
	for piece_var: Variant in BLUEPRINT_PIECE_ORDER:
		var piece_id: String = str(piece_var)
		remove_item(piece_id)

	add_item(
		SOUL_BLUEPRINT_SCROLL_ID,
		SOUL_BLUEPRINT_SCROLL_TITLE,
		SOUL_BLUEPRINT_SCROLL_DESC
	)
	set_quest("q5_go_to_mirror")


# ---------------------------------------------------------------------------
# Memory Bag (Inventory) API
# ---------------------------------------------------------------------------

func add_item(item_id: String, title: String, description: String) -> void:
	if item_id.is_empty():
		return

	for i: int in range(_inventory.size()):
		var existing: Dictionary = _inventory[i]
		if str(existing.get("id", "")) == item_id:
			existing["title"] = title
			existing["description"] = description
			_inventory[i] = existing
			inventory_changed.emit(get_items())
			return

	var entry: Dictionary = {
		"id": item_id,
		"title": title,
		"description": description,
	}
	_inventory.append(entry)
	inventory_changed.emit(get_items())


func has_item(item_id: String) -> bool:
	for entry: Dictionary in _inventory:
		if str(entry.get("id", "")) == item_id:
			return true
	return false


func remove_item(item_id: String) -> void:
	var removed: bool = false
	for i: int in range(_inventory.size() - 1, -1, -1):
		var entry: Dictionary = _inventory[i]
		if str(entry.get("id", "")) == item_id:
			_inventory.remove_at(i)
			removed = true
	if removed:
		inventory_changed.emit(get_items())


func get_items() -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for entry: Dictionary in _inventory:
		copy.append(entry.duplicate(true))
	return copy


func clear_inventory() -> void:
	if _inventory.is_empty():
		return
	_inventory.clear()
	inventory_changed.emit(get_items())


# ---------------------------------------------------------------------------
# Reset & Serialization (for SaveManager)
# ---------------------------------------------------------------------------

func reset_all() -> void:
	_current_quest_id = "q1_meet_lumi"
	_inventory.clear()
	_collected_blueprint_pieces.clear()
	_comfort_signs_found = 0
	_comfort_signs_sent = 0
	inventory_changed.emit(get_items())
	_emit_current_quest()


func export_state() -> Dictionary:
	var inv_out: Array = []
	for entry: Dictionary in _inventory:
		inv_out.append({
			"id": str(entry.get("id", "")),
			"title": str(entry.get("title", "")),
			"description": str(entry.get("description", "")),
		})

	var pieces_out: Array = []
	for piece_id: String in _collected_blueprint_pieces:
		pieces_out.append(piece_id)

	return {
		"current_quest_id": _current_quest_id,
		"inventory": inv_out,
		"collected_blueprint_pieces": pieces_out,
		"comfort_signs_found": _comfort_signs_found,
		"comfort_signs_sent": _comfort_signs_sent,
	}


func import_state(data: Dictionary) -> void:
	_current_quest_id = "q1_meet_lumi"
	_inventory.clear()
	_collected_blueprint_pieces.clear()
	_comfort_signs_found = 0
	_comfort_signs_sent = 0

	var quest_val: Variant = data.get("current_quest_id", "q1_meet_lumi")
	if quest_val is String:
		var quest_str: String = quest_val as String
		if QUEST_DATA.has(quest_str):
			_current_quest_id = quest_str

	var inv_val: Variant = data.get("inventory", [])
	if inv_val is Array:
		var inv_raw: Array = inv_val as Array
		for item_var: Variant in inv_raw:
			if item_var is Dictionary:
				var item_dict: Dictionary = item_var as Dictionary
				var item_id: String = str(item_dict.get("id", ""))
				if not item_id.is_empty() and not has_item(item_id):
					_inventory.append({
						"id": item_id,
						"title": str(item_dict.get("title", item_id)),
						"description": str(item_dict.get("description", "")),
					})

	var pieces_val: Variant = data.get("collected_blueprint_pieces", [])
	if pieces_val is Array:
		var pieces_raw: Array = pieces_val as Array
		for piece_var: Variant in pieces_raw:
			if piece_var is String:
				var piece_id: String = piece_var as String
				if BLUEPRINT_PIECE_META.has(piece_id) and not _collected_blueprint_pieces.has(piece_id):
					_collected_blueprint_pieces.append(piece_id)

	var found_val: Variant = data.get("comfort_signs_found", 0)
	if found_val is int or found_val is float:
		_comfort_signs_found = clampi(int(found_val), 0, 3)

	var sent_val: Variant = data.get("comfort_signs_sent", 0)
	if sent_val is int or sent_val is float:
		_comfort_signs_sent = clampi(int(sent_val), 0, 3)

	inventory_changed.emit(get_items())
	_emit_current_quest()


# ---------------------------------------------------------------------------
# Internal Helpers
# ---------------------------------------------------------------------------

func _get_quest_def(quest_id: String) -> Dictionary:
	var def_var: Variant = QUEST_DATA.get(quest_id, {})
	if def_var is Dictionary:
		return def_var as Dictionary
	return {}


func _get_next_uncollected_piece_meta() -> Dictionary:
	for piece_var: Variant in BLUEPRINT_PIECE_ORDER:
		var piece_id: String = str(piece_var)
		if not _collected_blueprint_pieces.has(piece_id):
			var meta_var: Variant = BLUEPRINT_PIECE_META.get(piece_id, {})
			if meta_var is Dictionary:
				return meta_var as Dictionary
	return {}


func _build_gather_blueprint_objective() -> String:
	var count: int = _collected_blueprint_pieces.size()
	var next_piece: Dictionary = _get_next_uncollected_piece_meta()
	if next_piece.is_empty():
		return "Все три основы Чертежа Души собраны (3 / 3). Вернитесь к Алатее в Школу Юных Душ"
	var piece_title: String = str(next_piece.get("title", ""))
	var piece_place: String = str(next_piece.get("place", ""))
	return "Соберите основы Чертежа Души (%d / 3) — далее: «%s» (%s)" % [count, piece_title, piece_place]


func _build_sunset_comfort_objective() -> String:
	if _comfort_signs_sent >= 3:
		return "Все Знаки Утешения отправлены родителям (3 / 3). Вернитесь к Мире"
	if _comfort_signs_found >= 3:
		return "Отправьте найденные Знаки Утешения сквозь Зеркало Земли (%d / 3)" % _comfort_signs_sent
	return "Найдите Знаки Утешения в закатном Городе (%d / 3) и отправьте их сквозь Зеркало (%d / 3)" % [_comfort_signs_found, _comfort_signs_sent]


func _emit_current_quest() -> void:
	quest_changed.emit(
		_current_quest_id,
		get_current_quest_title(),
		get_current_objective(),
		get_current_target_pos()
	)
