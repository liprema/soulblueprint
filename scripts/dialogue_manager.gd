class_name DialogueManager
extends Node

## Data-driven Mentor Dialogue manager for SoulBlueprint (Godot 4.3).
## Loads multi-step branching dialogue sequences from JSON and emits presentation
## and choice events for SkyHUD and gameplay controllers.

signal dialogue_started(sequence_id: String)
signal line_presented(speaker_id: String, speaker_title: String, accent_color: Color, text: String, choices: Array)
signal choice_recorded(choice_key: String, choice_id: String)
signal dialogue_ended(sequence_id: String)

const DEFAULT_DIALOGUE_PATH: String = "res://data/dialogues/prologue_contract.json"
const LESSON1_DIALOGUE_PATH: String = "res://data/dialogues/lesson1_return.json"
const CITY_DIALOGUE_PATH: String = "res://data/dialogues/city_quests.json"
const DEFAULT_ACCENT: Color = Color(0.964706, 0.827451, 0.419608, 1.0) # #F6D36B

@export var dialogue_file_path: String = DEFAULT_DIALOGUE_PATH

var _speakers: Dictionary = {}
var _sequences: Dictionary = {}
var _recorded_choices: Dictionary = {}

var _active: bool = false
var _current_sequence_id: String = ""
var _current_nodes: Dictionary = {}
var _current_node_id: String = ""


func _ready() -> void:
	load_dialogue_file(dialogue_file_path)
	if FileAccess.file_exists(LESSON1_DIALOGUE_PATH):
		merge_dialogue_file(LESSON1_DIALOGUE_PATH)
	if FileAccess.file_exists(CITY_DIALOGUE_PATH):
		merge_dialogue_file(CITY_DIALOGUE_PATH)


## Loads and parses a dialogue JSON resource from disk.
func load_dialogue_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("DialogueManager: dialogue file not found at '%s'" % path)
		return false

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: failed to open '%s'" % path)
		return false

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("DialogueManager: invalid JSON root in '%s'" % path)
		return false

	var data: Dictionary = parsed as Dictionary
	var speakers_var: Variant = data.get("speakers", {})
	var sequences_var: Variant = data.get("sequences", {})

	_speakers = speakers_var as Dictionary if speakers_var is Dictionary else {}
	_sequences = sequences_var as Dictionary if sequences_var is Dictionary else {}
	return true


## Merges speakers and sequences from an additional dialogue JSON file into existing dictionaries.
func merge_dialogue_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("DialogueManager: additional dialogue file not found at '%s'" % path)
		return false

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: failed to open '%s'" % path)
		return false

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("DialogueManager: invalid JSON root in '%s'" % path)
		return false

	var data: Dictionary = parsed as Dictionary
	var speakers_var: Variant = data.get("speakers", {})
	if speakers_var is Dictionary:
		var extra_speakers: Dictionary = speakers_var as Dictionary
		for speaker_key: Variant in extra_speakers.keys():
			_speakers[str(speaker_key)] = extra_speakers[speaker_key]

	var sequences_var: Variant = data.get("sequences", {})
	if sequences_var is Dictionary:
		var extra_sequences: Dictionary = sequences_var as Dictionary
		for seq_key: Variant in extra_sequences.keys():
			_sequences[str(seq_key)] = extra_sequences[seq_key]

	return true


## Returns true if a dialogue sequence is currently in progress.
func is_active() -> bool:
	return _active


## Starts a dialogue sequence by ID. Returns false if the sequence cannot be started.
func start_sequence(sequence_id: String) -> bool:
	if _sequences.is_empty():
		load_dialogue_file(dialogue_file_path)
		if FileAccess.file_exists(LESSON1_DIALOGUE_PATH):
			merge_dialogue_file(LESSON1_DIALOGUE_PATH)
		if FileAccess.file_exists(CITY_DIALOGUE_PATH):
			merge_dialogue_file(CITY_DIALOGUE_PATH)

	if not _sequences.has(sequence_id):
		push_warning("DialogueManager: unknown dialogue sequence '%s'" % sequence_id)
		return false

	var seq_var: Variant = _sequences.get(sequence_id, {})
	if not (seq_var is Dictionary):
		return false
	var seq: Dictionary = seq_var as Dictionary

	var nodes_var: Variant = seq.get("nodes", {})
	if not (nodes_var is Dictionary):
		return false
	var nodes: Dictionary = nodes_var as Dictionary

	var start_id: String = str(seq.get("start", ""))
	if start_id.is_empty() or not nodes.has(start_id):
		push_warning("DialogueManager: sequence '%s' has invalid start node '%s'" % [sequence_id, start_id])
		return false

	_active = true
	_current_sequence_id = sequence_id
	_current_nodes = nodes
	_current_node_id = start_id

	dialogue_started.emit(sequence_id)
	_present_current_node()
	return true


## Advances to the next node when the current node has no choices; ends if next is empty.
func advance() -> void:
	if not _active:
		return

	var node: Dictionary = _get_current_node()
	if node.is_empty():
		_finish_sequence()
		return

	var choices: Array = _extract_choices(node)
	if not choices.is_empty():
		# Wait for explicit choice selection via select_choice()
		return

	var next_var: Variant = node.get("next", "")
	var next_id: String = "" if next_var == null else str(next_var)
	if next_id.is_empty() or not _current_nodes.has(next_id):
		_finish_sequence()
		return

	_current_node_id = next_id
	_present_current_node()


## Selects one of the current node's choices by index, records it, and jumps to its target node.
func select_choice(choice_index: int) -> void:
	if not _active:
		return

	var node: Dictionary = _get_current_node()
	if node.is_empty():
		return

	var choices: Array = _extract_choices(node)
	if choice_index < 0 or choice_index >= choices.size():
		return

	var chosen_var: Variant = choices[choice_index]
	if not (chosen_var is Dictionary):
		return
	var chosen: Dictionary = chosen_var as Dictionary

	var choice_key: String = str(node.get("choice_key", _current_node_id))
	var choice_id: String = str(chosen.get("id", str(choice_index)))
	_recorded_choices[choice_key] = choice_id
	choice_recorded.emit(choice_key, choice_id)

	var next_var: Variant = chosen.get("next", "")
	var next_id: String = "" if next_var == null else str(next_var)
	if next_id.is_empty() or not _current_nodes.has(next_id):
		_finish_sequence()
		return

	_current_node_id = next_id
	_present_current_node()


## Returns a copy of all recorded Spark choices keyed by choice_key.
func get_recorded_choices() -> Dictionary:
	return _recorded_choices.duplicate()


## Returns the recorded choice_id for a given choice_key, or default_value if unset.
func get_choice(choice_key: String, default_value: String = "") -> String:
	if not _recorded_choices.has(choice_key):
		return default_value
	return str(_recorded_choices.get(choice_key, default_value))


func _get_current_node() -> Dictionary:
	if not _current_nodes.has(_current_node_id):
		return {}
	var node_var: Variant = _current_nodes.get(_current_node_id, {})
	if node_var is Dictionary:
		return node_var as Dictionary
	return {}


func _extract_choices(node: Dictionary) -> Array:
	var choices_var: Variant = node.get("choices", [])
	if choices_var is Array:
		return choices_var as Array
	return []


func _present_current_node() -> void:
	var node: Dictionary = _get_current_node()
	if node.is_empty():
		_finish_sequence()
		return

	var speaker_id: String = str(node.get("speaker", ""))
	var speaker_title: String = speaker_id.to_upper()
	var accent_color: Color = DEFAULT_ACCENT

	if _speakers.has(speaker_id):
		var speaker_var: Variant = _speakers.get(speaker_id, {})
		if speaker_var is Dictionary:
			var speaker_info: Dictionary = speaker_var as Dictionary
			speaker_title = str(speaker_info.get("title", speaker_title))
			var accent_hex: String = str(speaker_info.get("accent", ""))
			if not accent_hex.is_empty():
				accent_color = Color.from_string(accent_hex, DEFAULT_ACCENT)

	var text: String = str(node.get("text", ""))
	var choices: Array = _extract_choices(node)
	line_presented.emit(speaker_id, speaker_title, accent_color, text, choices)


func _finish_sequence() -> void:
	var finished_id: String = _current_sequence_id
	_active = false
	_current_sequence_id = ""
	_current_nodes = {}
	_current_node_id = ""
	dialogue_ended.emit(finished_id)
