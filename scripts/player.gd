extends CharacterBody2D

# --- Параметры движения Души (Дзен / Легкость) ---
@export var speed: float = 260.0
@export var jump_velocity: float = -420.0
@export var acceleration: float = 1200.0
@export var friction: float = 900.0
@export var glide_gravity_scale: float = 0.35 # Плавное парение при удержании прыжка

# Способность [E] Blink (Рывок)
@export var blink_distance: float = 180.0
@export var blink_cooldown: float = 1.2
var can_blink: bool = true

# Способность [Q] Soul Spark
@export var spark_cooldown: float = 2.0
var can_spark: bool = true

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var trail: Line2D = $Trail

# Флаг блокировки управления во время катсцены
var input_enabled: bool = false

func _ready() -> void:
	if trail:
		trail.top_level = true

func _physics_process(delta: float) -> void:
	# Шлейф света, тянущийся за Душой
	_update_trail()
	
	if not input_enabled:
		move_and_slide()
		return

	# Гравитация и парение (Glide)
	if not is_on_floor():
		var current_gravity = gravity
		# Если игрок удерживает кнопку прыжка при падении — парим плавно
		if Input.is_action_pressed("ui_accept") and velocity.y > 0:
			current_gravity *= glide_gravity_scale
		velocity.y += current_gravity * delta

	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Горизонтальное перемещение
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		if sprite:
			sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# [E] Рывок (Blink)
	if Input.is_action_just_pressed("blink") and can_blink:
		_perform_blink(direction)

	# [Q] Вспышка Души (Soul Spark)
	if Input.is_action_just_pressed("soul_spark") and can_spark:
		_perform_soul_spark()

	move_and_slide()

func _update_trail() -> void:
	if not trail:
		return
	trail.add_point(global_position)
	if trail.get_point_count() > 16:
		trail.remove_point(0)

func _perform_blink(dir: float) -> void:
	can_blink = false
	var blink_dir = Vector2.RIGHT if sprite.flip_h == false else Vector2.LEFT
	if dir != 0:
		blink_dir = Vector2(dir, 0).normalized()
	
	# Мгновенное смещение
	position += blink_dir * blink_distance
	
	# Сброс кулдауна
	await get_tree().create_timer(blink_cooldown).timeout
	can_blink = true

func _perform_soul_spark() -> void:
	can_spark = false
	# Вспышка рун (событие для интерактивных объектов вокруг)
	var spark_area = $SparkArea2D
	if spark_area:
		spark_area.monitoring = true
		await get_tree().create_timer(0.3).timeout
		spark_area.monitoring = false
	
	await get_tree().create_timer(spark_cooldown).timeout
	can_spark = true
