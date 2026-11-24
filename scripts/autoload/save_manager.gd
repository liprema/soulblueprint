extends Node

## Persistent save state manager for SoulBlueprint (Godot 4.3).
## Registered as Autoload `SaveManager` (no class_name to avoid name collision).

const SAVE_PATH: String = "user://soulblueprint_save.json"
const SAVE_FILENAME: String = "soulblueprint_save.json"
const TEMP_SAVE_FILENAME: String = "soulblueprint_save.json.tmp"
const TEMP_SAVE_PATH: String = "user://soulblueprint_save.json.tmp"

const DEFAULT_PLAYER_POS: Vector3 = Vector3(0.0, 1.3, 36.0)
const VALID_PROLOGUE_STAGES := [
	"intro",
	"exploring",
	"contract_spoken",
	"mirror_awakened",
	"prologue_complete",
]
const VALID_LESSON1_STAGES := [
	"not_started",
	"earth_life",
	"sunset_return",
	"collecting_signs",
	"complete",
]

signal progress_saved
signal progress_loaded

var has_saved_progress: bool = false
var prologue_stage: String = "intro"
var awakened_lanterns: Array[int] = []
var dialogue_choices: Dictionary = {}
var spark_evolution_level: int = 0
var audio_muted: bool = false
var last_player_pos: Vector3 = DEFAULT_PLAYER_POS
var has_custom_player_pos: bool = false
var lesson1_stage: String = "not_started"
var lesson1_signs_found: Array[String] = []
var lesson1_signs_sent: Array[String] = []


func _ready() -> void:
	load_game()


func has_save_data() -> bool:
	return has_saved_progress


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		has_saved_progress = false
		return false

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: failed to open save file for reading: %s" % SAVE_PATH)
		has_saved_progress = false
		return false

	var raw_text: String = file.get_as_text()
	file.close()

	if raw_text.strip_edges().is_empty():
		has_saved_progress = false
		return false

	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(raw_text)
	if parse_err != OK:
		push_warning("SaveManager: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		has_saved_progress = false
		return false

	var parsed_data: Variant = json.data
	if not (parsed_data is Dictionary):
		push_warning("SaveManager: root JSON value is not a Dictionary.")
		has_saved_progress = false
		return false

	var data: Dictionary = parsed_data as Dictionary
	_reset_state_to_defaults()

	var stage_val: Variant = data.get("prologue_stage", "intro")
	if stage_val is String:
		var stage_str: String = stage_val as String
		if VALID_PROLOGUE_STAGES.has(stage_str):
			prologue_stage = stage_str

	var lanterns_val: Variant = data.get("awakened_lanterns", [])
	if lanterns_val is Array:
		var lanterns_raw: Array = lanterns_val as Array
		for item: Variant in lanterns_raw:
			if item is int or item is float:
				var lantern_index: int = int(item)
				if not awakened_lanterns.has(lantern_index):
					awakened_lanterns.append(lantern_index)

	var choices_val: Variant = data.get("dialogue_choices", {})
	if choices_val is Dictionary:
		var choices_raw: Dictionary = choices_val as Dictionary
		for key_variant: Variant in choices_raw.keys():
			var key_str: String = str(key_variant)
			var val_str: String = str(choices_raw[key_variant])
			dialogue_choices[key_str] = val_str

	var spark_val: Variant = data.get("spark_evolution_level", 0)
	if spark_val is int or spark_val is float:
		spark_evolution_level = maxi(0, int(spark_val))

	var muted_val: Variant = data.get("audio_muted", false)
	if muted_val is bool:
		audio_muted = muted_val as bool

	var custom_pos_val: Variant = data.get("has_custom_player_pos", false)
	if custom_pos_val is bool:
		has_custom_player_pos = custom_pos_val as bool

	var pos_val: Variant = data.get("last_player_pos", {})
	if pos_val is Dictionary:
		var pos_dict: Dictionary = pos_val as Dictionary
		var px: float = _read_float(pos_dict, "x", DEFAULT_PLAYER_POS.x)
		var py: float = _read_float(pos_dict, "y", DEFAULT_PLAYER_POS.y)
		var pz: float = _read_float(pos_dict, "z", DEFAULT_PLAYER_POS.z)
		last_player_pos = Vector3(px, py, pz)

	var l1_stage_val: Variant = data.get("lesson1_stage", "not_started")
	if l1_stage_val is String:
		var l1_stage_str: String = l1_stage_val as String
		if VALID_LESSON1_STAGES.has(l1_stage_str):
			lesson1_stage = l1_stage_str

	var l1_found_val: Variant = data.get("lesson1_signs_found", [])
	if l1_found_val is Array:
		var l1_found_raw: Array = l1_found_val as Array
		for item: Variant in l1_found_raw:
			if item is String:
				var sign_id: String = item as String
				if not sign_id.is_empty() and not lesson1_signs_found.has(sign_id):
					lesson1_signs_found.append(sign_id)

	var l1_sent_val: Variant = data.get("lesson1_signs_sent", [])
	if l1_sent_val is Array:
		var l1_sent_raw: Array = l1_sent_val as Array
		for item: Variant in l1_sent_raw:
			if item is String:
				var sign_id: String = item as String
				if not sign_id.is_empty() and not lesson1_signs_sent.has(sign_id):
					lesson1_signs_sent.append(sign_id)

	if lesson1_stage == "complete":
		spark_evolution_level = maxi(spark_evolution_level, 2)

	_apply_audio_mute_state()
	has_saved_progress = true
	progress_loaded.emit()
	return true


func save_game() -> void:
	var payload: Dictionary = {
		"version": 1,
		"prologue_stage": prologue_stage,
		"awakened_lanterns": awakened_lanterns,
		"dialogue_choices": dialogue_choices,
		"spark_evolution_level": spark_evolution_level,
		"audio_muted": audio_muted,
		"has_custom_player_pos": has_custom_player_pos,
		"last_player_pos": {
			"x": last_player_pos.x,
			"y": last_player_pos.y,
			"z": last_player_pos.z,
		},
		"lesson1_stage": lesson1_stage,
		"lesson1_signs_found": lesson1_signs_found,
		"lesson1_signs_sent": lesson1_signs_sent,
	}

	var serialized: String = JSON.stringify(payload, "\t")
	var temp_file: FileAccess = FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if temp_file == null:
		push_warning("SaveManager: failed to open temp save file for writing: %s" % TEMP_SAVE_PATH)
		return

	temp_file.store_string(serialized)
	temp_file.flush()
	temp_file.close()

	var user_dir: DirAccess = DirAccess.open("user://")
	if user_dir != null:
		if user_dir.file_exists(SAVE_FILENAME):
			var remove_err: Error = user_dir.remove(SAVE_FILENAME)
			if remove_err != OK:
				push_warning("SaveManager: could not replace existing save file (err %d)." % remove_err)
		var rename_err: Error = user_dir.rename(TEMP_SAVE_FILENAME, SAVE_FILENAME)
		if rename_err != OK:
			push_warning("SaveManager: atomic rename failed (err %d), writing directly." % rename_err)
			_write_direct_fallback(serialized)
	else:
		_write_direct_fallback(serialized)

	has_saved_progress = true
	progress_saved.emit()


func reset_save() -> void:
	_reset_state_to_defaults()
	has_saved_progress = false

	var user_dir: DirAccess = DirAccess.open("user://")
	if user_dir != null:
		if user_dir.file_exists(SAVE_FILENAME):
			var err: Error = user_dir.remove(SAVE_FILENAME)
			if err != OK:
				push_warning("SaveManager: failed to remove save file (err %d)." % err)
		if user_dir.file_exists(TEMP_SAVE_FILENAME):
			user_dir.remove(TEMP_SAVE_FILENAME)

	_apply_audio_mute_state()


func mark_lantern_awakened(index: int) -> void:
	if awakened_lanterns.has(index):
		return
	awakened_lanterns.append(index)
	save_game()


func is_lantern_awakened(index: int) -> bool:
	return awakened_lanterns.has(index)


func get_awakened_lantern_count() -> int:
	return awakened_lanterns.size()


func set_prologue_stage(stage: String) -> void:
	if not VALID_PROLOGUE_STAGES.has(stage):
		push_warning("SaveManager: unknown prologue stage '%s'." % stage)
	prologue_stage = stage
	if stage == "prologue_complete":
		spark_evolution_level = maxi(spark_evolution_level, 1)
	save_game()


func set_lesson1_stage(stage: String) -> void:
	if not VALID_LESSON1_STAGES.has(stage):
		push_warning("SaveManager: unknown lesson1 stage '%s'." % stage)
	lesson1_stage = stage
	if stage == "complete":
		spark_evolution_level = maxi(spark_evolution_level, 2)
	save_game()


func mark_lesson1_sign_found(sign_id: String) -> void:
	if sign_id.is_empty() or lesson1_signs_found.has(sign_id):
		return
	lesson1_signs_found.append(sign_id)
	save_game()


func mark_lesson1_sign_sent(sign_id: String) -> void:
	if sign_id.is_empty() or lesson1_signs_sent.has(sign_id):
		return
	lesson1_signs_sent.append(sign_id)
	save_game()


func has_lesson1_sign_found(sign_id: String) -> bool:
	return lesson1_signs_found.has(sign_id)


func has_lesson1_sign_sent(sign_id: String) -> bool:
	return lesson1_signs_sent.has(sign_id)


func get_lesson1_signs_found_count() -> int:
	return lesson1_signs_found.size()


func get_lesson1_signs_sent_count() -> int:
	return lesson1_signs_sent.size()


func reset_lesson1_progress() -> void:
	lesson1_stage = "not_started"
	lesson1_signs_found.clear()
	lesson1_signs_sent.clear()
	save_game()


func record_choice(key: String, value: String) -> void:
	dialogue_choices[key] = value
	save_game()


func save_player_checkpoint(pos: Vector3) -> void:
	last_player_pos = pos
	has_custom_player_pos = true
	save_game()


func set_audio_muted(muted: bool) -> void:
	audio_muted = muted
	_apply_audio_mute_state()
	if has_saved_progress:
		save_game()


func _reset_state_to_defaults() -> void:
	prologue_stage = "intro"
	awakened_lanterns.clear()
	dialogue_choices.clear()
	spark_evolution_level = 0
	audio_muted = false
	last_player_pos = DEFAULT_PLAYER_POS
	has_custom_player_pos = false
	lesson1_stage = "not_started"
	lesson1_signs_found.clear()
	lesson1_signs_sent.clear()


func _apply_audio_mute_state() -> void:
	if AudioServer.bus_count > 0:
		AudioServer.set_bus_mute(0, audio_muted)


func _read_float(dict: Dictionary, key: String, fallback: float) -> float:
	var val: Variant = dict.get(key, fallback)
	if val is float or val is int:
		return float(val)
	return fallback


func _write_direct_fallback(serialized: String) -> void:
	var direct_file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if direct_file == null:
		push_warning("SaveManager: direct fallback write failed for %s" % SAVE_PATH)
		return
	direct_file.store_string(serialized)
	direct_file.flush()
	direct_file.close()
