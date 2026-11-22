extends CanvasLayer

signal intro_completed

@onready var backdrop: ColorRect = $Backdrop
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var last_frame_hold: TextureRect = $LastFrameHold
@onready var fade_rect: ColorRect = $FadeRect
@onready var skip_hint: Label = $SkipHint

var is_skipping: bool = false
var is_finished: bool = false
var hint_tween: Tween

func _ready() -> void:
	# Start fully opaque deep-space blue for smooth cinematic fade-in
	fade_rect.modulate.a = 1.0
	skip_hint.modulate.a = 0.0
	last_frame_hold.visible = false

	if not video_player.stream:
		push_warning("IntroVideo: video stream is missing, skipping directly to gameplay.")
		_complete_immediately()
		return

	video_player.finished.connect(_on_video_finished)
	video_player.play()

	# Smooth fade from deep-space blue into video
	var in_tween := create_tween()
	in_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)

	# Show subtle skip hint after 2 seconds
	hint_tween = create_tween()
	hint_tween.tween_interval(2.0)
	hint_tween.tween_property(skip_hint, "modulate:a", 0.65, 1.0)

func _input(event: InputEvent) -> void:
	if is_finished or is_skipping:
		return

	# Skip on Space, Enter or Escape
	var is_skip_key := (
		event.is_action_pressed("ui_accept")
		or event.is_action_pressed("ui_cancel")
		or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE))
	)
	if is_skip_key:
		get_viewport().set_input_as_handled()
		skip_cutscene()

func skip_cutscene() -> void:
	if is_skipping or is_finished:
		return
	is_skipping = true

	if hint_tween and hint_tween.is_running():
		hint_tween.kill()

	# Smooth fade to deep-space blue and fade audio out simultaneously
	var skip_tween := create_tween()
	skip_tween.set_parallel(true)
	skip_tween.tween_property(skip_hint, "modulate:a", 0.0, 0.2)
	skip_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	skip_tween.tween_property(video_player, "volume_db", -40.0, 0.45)
	skip_tween.chain().tween_callback(func():
		video_player.stop()
		video_player.visible = false
		backdrop.visible = false
		skip_hint.visible = false
		_reveal_gameplay_from_fade()
	)

func _on_video_finished() -> void:
	if is_finished or is_skipping:
		return
	is_finished = true

	if hint_tween and hint_tween.is_running():
		hint_tween.kill()

	# Capture final video frame so we can cross-dissolve seamlessly into the 2.5D scene
	var captured_image: Image = null
	var vid_tex: Texture2D = video_player.get_video_texture()
	if vid_tex:
		captured_image = vid_tex.get_image()

	video_player.stop()
	video_player.visible = false
	backdrop.visible = false

	var out_tween := create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(skip_hint, "modulate:a", 0.0, 0.3)

	if captured_image and not captured_image.is_empty():
		last_frame_hold.texture = ImageTexture.create_from_image(captured_image)
		last_frame_hold.modulate.a = 1.0
		last_frame_hold.visible = true
		out_tween.tween_property(last_frame_hold, "modulate:a", 0.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		fade_rect.modulate.a = 1.0
		out_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	out_tween.chain().tween_callback(func():
		intro_completed.emit()
		queue_free()
	)

func _reveal_gameplay_from_fade() -> void:
	is_finished = true
	var out_tween := create_tween()
	out_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	out_tween.tween_callback(func():
		intro_completed.emit()
		queue_free()
	)

func _complete_immediately() -> void:
	is_finished = true
	intro_completed.emit()
	queue_free()
