extends CanvasLayer

signal intro_completed

const FADE_IN_DURATION: float = 1.0
const DISSOLVE_DURATION: float = 1.8
const SKIP_FADE_OUT_DURATION: float = 0.5
const SKIP_REVEAL_DURATION: float = 1.1

@onready var backdrop: ColorRect = $Backdrop
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var last_frame_hold: TextureRect = $LastFrameHold
@onready var glow_veil: ColorRect = $GlowVeil
@onready var fade_rect: ColorRect = $FadeRect
@onready var skip_hint: Label = $SkipHint

var is_skipping: bool = false
var is_finished: bool = false
var hint_tween: Tween = null


func _ready() -> void:
	# Start fully opaque deep-space indigo for smooth cinematic fade-in
	fade_rect.modulate.a = 1.0
	glow_veil.modulate.a = 0.0
	skip_hint.modulate.a = 0.0
	last_frame_hold.visible = false

	if not video_player.stream:
		push_warning("IntroVideo: video stream is missing, skipping directly to gameplay.")
		_complete_immediately()
		return

	video_player.finished.connect(_on_video_finished)
	video_player.play()

	# Smooth fade from deep-space indigo into the opening shot
	var in_tween: Tween = create_tween()
	in_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(fade_rect, "modulate:a", 0.0, FADE_IN_DURATION)

	# Show subtle skip hint after 2 seconds
	hint_tween = create_tween()
	hint_tween.tween_interval(2.0)
	hint_tween.tween_property(skip_hint, "modulate:a", 0.72, 1.0)


func _input(event: InputEvent) -> void:
	if is_finished or is_skipping:
		return

	var is_skip_key: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")
	if not is_skip_key and event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			is_skip_key = (
				key_event.keycode == KEY_SPACE
				or key_event.keycode == KEY_ENTER
				or key_event.keycode == KEY_KP_ENTER
				or key_event.keycode == KEY_ESCAPE
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

	# Smoothly fade audio out while washing into deep indigo + soft golden veil
	var skip_tween: Tween = create_tween()
	skip_tween.set_parallel(true)
	skip_tween.tween_property(skip_hint, "modulate:a", 0.0, 0.25)
	skip_tween.tween_property(fade_rect, "modulate:a", 1.0, SKIP_FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	skip_tween.tween_property(glow_veil, "modulate:a", 0.16, SKIP_FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	skip_tween.tween_property(video_player, "volume_db", -42.0, SKIP_FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	skip_tween.chain().tween_callback(func() -> void:
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

	# Capture final video frame BEFORE stop() so we can cross-dissolve seamlessly into the 3D world
	var captured_image: Image = null
	var vid_tex: Texture2D = video_player.get_video_texture()
	if vid_tex:
		captured_image = vid_tex.get_image()

	video_player.stop()
	video_player.visible = false
	backdrop.visible = false

	var out_tween: Tween = create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(skip_hint, "modulate:a", 0.0, 0.35)

	if captured_image and not captured_image.is_empty():
		last_frame_hold.texture = ImageTexture.create_from_image(captured_image)
		last_frame_hold.modulate.a = 1.0
		last_frame_hold.visible = true

		# Cross-dissolve final video frame directly into the live 3D Akasha sanctuary
		out_tween.tween_property(last_frame_hold, "modulate:a", 0.0, DISSOLVE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# Subtle golden-indigo glow veil bridges lighting differences with zero hard cut or black flash
		var veil_tween: Tween = create_tween()
		veil_tween.tween_property(glow_veil, "modulate:a", 0.22, DISSOLVE_DURATION * 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		veil_tween.tween_property(glow_veil, "modulate:a", 0.0, DISSOLVE_DURATION * 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		# Graceful fallback: luminous indigo + golden dissolve (never a black flash)
		fade_rect.modulate.a = 0.85
		glow_veil.modulate.a = 0.22
		out_tween.tween_property(fade_rect, "modulate:a", 0.0, DISSOLVE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		out_tween.tween_property(glow_veil, "modulate:a", 0.0, DISSOLVE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	out_tween.chain().tween_callback(func() -> void:
		intro_completed.emit()
		queue_free()
	)


func _reveal_gameplay_from_fade() -> void:
	is_finished = true
	var out_tween: Tween = create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(fade_rect, "modulate:a", 0.0, SKIP_REVEAL_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	out_tween.tween_property(glow_veil, "modulate:a", 0.0, SKIP_REVEAL_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	out_tween.chain().tween_callback(func() -> void:
		intro_completed.emit()
		queue_free()
	)


func _complete_immediately() -> void:
	is_finished = true
	intro_completed.emit()
	queue_free()
