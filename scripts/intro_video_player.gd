extends CanvasLayer

signal intro_completed

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var fade_rect: ColorRect = $FadeRect
@onready var skip_hint: Label = $SkipHint

var is_skipping: bool = false
var is_finished: bool = false

func _ready() -> void:
	# Start fully opaque black for smooth cinematic fade-in
	fade_rect.modulate.a = 1.0
	skip_hint.modulate.a = 0.0
	
	video_player.finished.connect(_on_video_finished)
	video_player.play()
	
	# Smooth fade from black into video
	var in_tween = create_tween()
	in_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	
	# Show subtle skip hint after 2 seconds
	var hint_tween = create_tween()
	hint_tween.tween_interval(2.0)
	hint_tween.tween_property(skip_hint, "modulate:a", 0.6, 1.0)

func _input(event: InputEvent) -> void:
	if is_finished or is_skipping:
		return
		
	# Skip on Space, Enter or Escape
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		skip_cutscene()

func skip_cutscene() -> void:
	if is_skipping or is_finished:
		return
	is_skipping = true
	
	# Smooth fast dissolve to white/dark for skip
	var skip_tween = create_tween()
	skip_tween.tween_property(skip_hint, "modulate:a", 0.0, 0.2)
	skip_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	skip_tween.tween_callback(func():
		video_player.stop()
		_finish_transition()
	)

func _on_video_finished() -> void:
	if is_finished or is_skipping:
		return
	_finish_transition()

func _finish_transition() -> void:
	is_finished = true
	
	# Fade-in seamlessly into gameplay
	var out_tween = create_tween()
	# Ensure video is hidden/stopped
	video_player.stop()
	video_player.visible = false
	skip_hint.visible = false
	
	# Dissolve overlay to reveal player on the monolithic platform
	out_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.2)
	out_tween.tween_callback(func():
		intro_completed.emit()
		queue_free()
	)
