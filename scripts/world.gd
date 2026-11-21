extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var intro_video: CanvasLayer = $IntroVideo
@onready var hud: CanvasLayer = $HUD
@onready var quest_tracker: VBoxContainer = $HUD/QuestTracker
@onready var hud_controls: Control = $HUD/HUDControls

# Gods references for soft breathing animation
@onready var sun_portal: Sprite2D = $ParallaxBackground/ParallaxLayerGods/SunPortal
@onready var alathea: Sprite2D = $ParallaxBackground/ParallaxLayerGods/Alathea
@onready var orion: Sprite2D = $ParallaxBackground/ParallaxLayerGods/Orion
@onready var chronos: Sprite2D = $ParallaxBackground/ParallaxLayerGods/Chronos
@onready var myra: Sprite2D = $ParallaxBackground/ParallaxLayerGods/Myra

var elapsed_time: float = 0.0

func _ready() -> void:
	# Hide gameplay HUD and disable controls until intro cutscene completes
	player.input_enabled = false
	quest_tracker.modulate.a = 0.0
	hud_controls.modulate.a = 0.0
	
	if intro_video:
		intro_video.intro_completed.connect(_on_intro_completed)
	else:
		_on_intro_completed()

func _process(delta: float) -> void:
	elapsed_time += delta
	# Subtle celestial floating breathing effect for gods and portal
	var breathe = sin(elapsed_time * 1.5) * 4.0
	if alathea:
		alathea.position.y = 220.0 + breathe
	if myra:
		myra.position.y = 265.0 - breathe
	if orion:
		orion.position.y = 265.0 + breathe * 0.7
	if chronos:
		chronos.position.y = 215.0 - breathe * 0.7
	if sun_portal:
		sun_portal.position.y = 190.0 + sin(elapsed_time * 1.0) * 2.0

func _on_intro_completed() -> void:
	# Enable soul movement
	player.input_enabled = true
	
	# Smoothly fade in HUD and objective markers
	var tween = create_tween()
	tween.tween_property(quest_tracker, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(hud_controls, "modulate:a", 1.0, 1.0)
