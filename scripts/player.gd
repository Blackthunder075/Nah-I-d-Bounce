
extends CharacterBody2D

@export var move_speed: float = 250.0
@export var bounce_speed: float = 600.0
@export var bounce_duration: float = 0.35
@export var bounce_damage: float = 15.0
@export var starting_mass: float = 10.0
@export var maximum_scale: float = 3.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component = $HealthComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var camera: Camera2D = $Camera2D

var mass: float
var is_bouncing: bool = false
var is_absorbing: bool = false
var is_hurt: bool = false
var can_take_damage: bool = true

var bounce_direction: Vector2 = Vector2.ZERO
var bounce_timer: float = 0.0
var base_sprite_scale: Vector2


func _ready():
	add_to_group("player")

	mass = starting_mass
	base_sprite_scale = animated_sprite.scale

	camera.make_current()

	health_component.died.connect(_on_player_died)
	health_component.health_changed.connect(_on_health_changed)

	update_slime_scale()
	_on_health_changed(
		health_component.current_health,
		health_component.max_health
	)


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			start_bounce()


func _physics_process(delta):
	if is_bouncing:
		bounce_timer -= delta
		velocity = bounce_direction * bounce_speed

		if bounce_timer <= 0.0:
			is_bouncing = false
	else:
		var input_direction = Input.get_vector(
			"move_left",
			"move_right",
			"move_up",
			"move_down"
		)

		velocity = input_direction * move_speed

	move_and_slide()

	check_bounce_collision()
	update_animation()


func start_bounce():
	if is_bouncing or is_hurt:
		return

	bounce_direction = global_position.direction_to(
		get_global_mouse_position()
	)

	if bounce_direction == Vector2.ZERO:
		return

	is_bouncing = true
	bounce_timer = bounce_duration


func check_bounce_collision():
	if not is_bouncing:
		return

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider.is_in_group("enemies"):
			if collider.has_method("take_damage"):
				collider.take_damage(bounce_damage)

			is_bouncing = false
			velocity = Vector2.ZERO
			break


func update_animation():
	if is_absorbing:
		play_animation("absorb")
	elif is_hurt:
		play_animation("hurt")
	elif is_bouncing:
		play_animation("bounce")
	elif velocity.length() > 10.0:
		play_animation("move")
	else:
		play_animation("idle")


func play_animation(animation_name: String):
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


func absorb_enemy(enemy_mass: float):
	mass += enemy_mass
	update_slime_scale()

	is_absorbing = true
	animated_sprite.play("absorb")


func update_slime_scale():
	var growth = sqrt(mass / starting_mass)
	growth = clampf(growth, 1.0, maximum_scale)

	animated_sprite.scale = base_sprite_scale * growth


func take_damage(amount: float):
	if not can_take_damage or health_component.is_dead:
		return

	health_component.take_damage(amount)

	if health_component.is_dead:
		return

	can_take_damage = false
	is_hurt = true
	update_animation()

	await get_tree().create_timer(0.5).timeout

	is_hurt = false
	can_take_damage = true


func _on_health_changed(current_health: float, maximum_health: float):
	health_bar.max_value = maximum_health
	health_bar.value = current_health


func _on_player_died():
	is_bouncing = false
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	set_physics_process(false)
	set_process_input(false)


func _on_animated_sprite_2d_animation_finished():
	if animated_sprite.animation == "absorb":
		is_absorbing = false

	if animated_sprite.animation == "hurt":
		is_hurt = false

	update_animation()
