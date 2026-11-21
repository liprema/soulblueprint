extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var intro_cutscene: CanvasLayer = $IntroCutscene
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	# На старте блокируем управление персонажем
	player.input_enabled = false
	intro_cutscene.cutscene_finished.connect(_on_cutscene_finished)

func _on_cutscene_finished() -> void:
	# После завершения реплик Богов активируем управление Душой
	player.input_enabled = true
