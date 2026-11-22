extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var intro_video: CanvasLayer = get_node_or_null("IntroVideo")
@onready var hud: CanvasLayer = $HUD
@onready var quest_tracker: VBoxContainer = $HUD/QuestTracker
@onready var hud_controls: Control = $HUD/HUDControls

func _ready() -> void:
	# Hide gameplay HUD and disable controls until intro cutscene completes
	player.input_enabled = false
	quest_tracker.modulate.a = 0.0
	hud_controls.modulate.a = 0.0

	if intro_video:
		intro_video.intro_completed.connect(_on_intro_completed)
	else:
		_on_intro_completed()

func _on_intro_completed() -> void:
	# Enable soul movement
	player.input_enabled = true

	# Smoothly fade in HUD and objective markers
	var tween := create_tween()
	tween.tween_property(quest_tracker, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(hud_controls, "modulate:a", 1.0, 1.0)
