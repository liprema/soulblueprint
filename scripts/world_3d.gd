extends Node3D

## Root orchestrator for the SoulBlueprint 3D Sky-style Prologue Vertical Slice.
## Wires Player3D, SkyHUD, SoulCall3D, StoneLantern3D instances, AkashaAudioManager,
## and seamless intro video handoff.

const STONE_LANTERN_SCENE: PackedScene = preload("res://scenes/interactables/stone_lantern_3d.tscn")

@onready var architecture: Node3D = $AkashaArchitecture
@onready var player: CharacterBody3D = $Player3D
@onready var soul_call: Node3D = $SoulCall3D
@onready var sky_hud: CanvasLayer = $SkyHUD
@onready var audio_manager: Node = $AkashaAudioManager
@onready var intro_video: Node = get_node_or_null("IntroVideo")

var _prev_wing_energy: float = 5.0
var _cathedral_dialogue_shown: bool = false
var _lantern_container: Node3D


func _ready() -> void:
	_spawn_lanterns()
	_connect_signals()
	_setup_intro_handoff()


func _spawn_lanterns() -> void:
	_lantern_container = Node3D.new()
	_lantern_container.name = "StoneLanterns"
	add_child(_lantern_container)

	if architecture and architecture.has_method("get_lantern_anchor_positions"):
		var anchors: Array = architecture.call("get_lantern_anchor_positions")
		for idx in range(anchors.size()):
			var lantern: Node3D = STONE_LANTERN_SCENE.instantiate() as Node3D
			lantern.name = "StoneLantern_%02d" % idx
			lantern.position = anchors[idx]
			_lantern_container.add_child(lantern)
			if lantern.has_signal("awakened"):
				lantern.connect("awakened", _on_lantern_awakened.bind(idx))


func _connect_signals() -> void:
	if not player:
		return

	if player.has_signal("soul_call_triggered"):
		player.connect("soul_call_triggered", _on_player_soul_call)
	if player.has_signal("wing_energy_changed"):
		player.connect("wing_energy_changed", _on_player_wing_energy_changed)
	if player.has_signal("flight_mode_changed"):
		player.connect("flight_mode_changed", _on_player_flight_mode_changed)


func _setup_intro_handoff() -> void:
	if intro_video and intro_video.has_signal("intro_finished"):
		if player and "input_enabled" in player:
			player.set("input_enabled", false)
		intro_video.connect("intro_finished", _on_intro_finished)
	else:
		_enable_gameplay()


func _on_intro_finished() -> void:
	_enable_gameplay()


func _enable_gameplay() -> void:
	if player and "input_enabled" in player:
		player.set("input_enabled", true)
	if sky_hud and sky_hud.has_method("show_chapter_title"):
		sky_hud.call("show_chapter_title", "П Р О Л О Г", "Обитель Хроник Акаши", 4.5)


func _on_player_soul_call(origin: Vector3) -> void:
	if soul_call and soul_call.has_method("trigger"):
		soul_call.call("trigger", origin)
	if audio_manager and audio_manager.has_method("play_soul_call"):
		audio_manager.call("play_soul_call")


func _on_player_wing_energy_changed(current: float, max_energy: float) -> void:
	if current < _prev_wing_energy - 0.5:
		if audio_manager and audio_manager.has_method("play_wing_flap"):
			audio_manager.call("play_wing_flap")
	_prev_wing_energy = current

	if sky_hud and sky_hud.has_method("update_wing_energy"):
		sky_hud.call("update_wing_energy", current, max_energy)


func _on_player_flight_mode_changed(is_flying: bool) -> void:
	if is_flying and sky_hud and sky_hud.has_method("hide_flight_hint"):
		sky_hud.call("hide_flight_hint")


func _on_lantern_awakened(_lantern: Node, index: int) -> void:
	if audio_manager and audio_manager.has_method("play_lantern_chime"):
		audio_manager.call("play_lantern_chime", index)


func _process(_delta: float) -> void:
	if not _cathedral_dialogue_shown and player and player.global_position.z < -185.0:
		_cathedral_dialogue_shown = true
		if sky_hud and sky_hud.has_method("show_dialogue"):
			sky_hud.call(
				"show_dialogue",
				"АЛАТЕЯ  ·  ТКАЧИХА СУДЕБ",
				"«Твой свет окреп, юная Искра. Готова ли ты взглянуть на нити своего первого земного воплощения?»"
			)
