extends CharacterBody2D

# --- Параметры 2.5D движения Души по монолитной дороге ---
@export var speed: float = 210.0
@export var depth_speed_ratio: float = 0.65 # Скорость вперёд/назад в перспективе
@export var acceleration: float = 1100.0
@export var friction: float = 950.0

# Прыжок и парение (высота над поверхностью платформы)
@export var jump_velocity: float = 260.0
@export var z_gravity: float = 680.0
@export var glide_gravity_scale: float = 0.32 # Плавное парение при удержании Space

# Перспективное масштабирование (от Врат в глубине до переднего плана)
@export var min_depth_y: float = 434.0
@export var max_depth_y: float = 568.0
@export var min_depth_scale: float = 0.85
@export var max_depth_scale: float = 1.45

# Способность [E] Blink (Рывок)
@export var blink_distance: float = 130.0
@export var blink_cooldown: float = 1.0
var can_blink: bool = true

# Способность [Q] Soul Spark
@export var spark_cooldown: float = 1.8
var can_spark: bool = true

const BASE_SPRITE_Y: float = -24.5

var z_height: float = 0.0
var z_velocity: float = 0.0
var last_move_dir: Vector2 = Vector2.RIGHT

@onready var sprite: Sprite2D = $Sprite2D
@onready var ground_shadow: Polygon2D = $GroundShadow
@onready var ground_glow: Polygon2D = $GroundGlow
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var trail: Line2D = $Trail

# Флаг блокировки управления во время катсцены
var input_enabled: bool = false

func _ready() -> void:
	if trail:
		trail.top_level = true
	_update_depth_scale()
	_update_visual_height()

func _physics_process(delta: float) -> void:
	_update_trail()

	if not input_enabled:
		return

	# 2.5D перемещение: влево/вправо (A/D, ←/→) и вперёд/назад вглубь (W/S, ↑/↓)
	var input_vec := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)

	if input_vec.length_squared() > 0.001:
		input_vec = input_vec.normalized()
		last_move_dir = input_vec
		var target_vel := Vector2(input_vec.x * speed, input_vec.y * speed * depth_speed_ratio)
		velocity = velocity.move_toward(target_vel, acceleration * delta)
		if sprite and absf(input_vec.x) > 0.05:
			sprite.flip_h = (input_vec.x < 0.0)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	# Движение по плоскости платформы с учётом невидимых стен
	move_and_slide()

	# Прыжок и парение над поверхностью платформы ([Space])
	if Input.is_action_just_pressed("ui_accept") and z_height <= 0.01:
		z_velocity = jump_velocity

	if z_height > 0.0 or z_velocity > 0.0:
		var current_g := z_gravity
		if Input.is_action_pressed("ui_accept") and z_velocity < 0.0:
			current_g *= glide_gravity_scale
		z_velocity -= current_g * delta
		z_height += z_velocity * delta
		if z_height <= 0.0:
			z_height = 0.0
			z_velocity = 0.0

	_update_depth_scale()
	_update_visual_height()

	# [E] Рывок (Blink) — останавливается у невидимых стен
	if Input.is_action_just_pressed("blink") and can_blink:
		_perform_blink(input_vec)

	# [Q] Вспышка Души (Soul Spark)
	if Input.is_action_just_pressed("soul_spark") and can_spark:
		_perform_soul_spark()

func _update_depth_scale() -> void:
	var t := clampf((global_position.y - min_depth_y) / maxf(1.0, max_depth_y - min_depth_y), 0.0, 1.0)
	var s := lerpf(min_depth_scale, max_depth_scale, t)
	scale = Vector2(s, s)

func _update_visual_height() -> void:
	if sprite:
		sprite.position.y = BASE_SPRITE_Y - z_height
	var shadow_factor := clampf(1.0 - (z_height / 180.0), 0.45, 1.0)
	if ground_shadow:
		ground_shadow.scale = Vector2(shadow_factor, shadow_factor)
		ground_shadow.modulate.a = shadow_factor
	if ground_glow:
		ground_glow.scale = Vector2(shadow_factor, shadow_factor)

func _update_trail() -> void:
	if not trail or not sprite:
		return
	var anchor := sprite.global_position
	if trail.get_point_count() == 0 or trail.get_point_position(trail.get_point_count() - 1).distance_to(anchor) > 2.0:
		trail.add_point(anchor)
	if trail.get_point_count() > 14:
		trail.remove_point(0)

func _perform_blink(dir: Vector2) -> void:
	can_blink = false
	var blink_dir := dir if dir.length_squared() > 0.01 else last_move_dir
	if blink_dir.length_squared() < 0.01:
		blink_dir = Vector2.LEFT if (sprite and sprite.flip_h) else Vector2.RIGHT
	blink_dir = blink_dir.normalized()

	var motion := Vector2(blink_dir.x * blink_distance, blink_dir.y * blink_distance * depth_speed_ratio)
	# Используем move_and_collide, чтобы рывок не проходил сквозь невидимые стены
	move_and_collide(motion)
	_update_depth_scale()

	await get_tree().create_timer(blink_cooldown).timeout
	can_blink = true

func _perform_soul_spark() -> void:
	can_spark = false
	var spark_area := get_node_or_null("SparkArea2D") as Area2D
	if spark_area:
		spark_area.monitoring = true

	# Мягкий золотой импульс на поверхности плиты
	if ground_glow:
		var pulse := create_tween()
		pulse.set_parallel(true)
		pulse.tween_property(ground_glow, "scale", Vector2(3.2, 3.2), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		pulse.tween_property(ground_glow, "modulate:a", 1.0, 0.12)
		pulse.chain().tween_property(ground_glow, "scale", Vector2(1.0, 1.0), 0.35)

	await get_tree().create_timer(0.3).timeout
	if spark_area:
		spark_area.monitoring = false

	await get_tree().create_timer(spark_cooldown).timeout
	can_spark = true
