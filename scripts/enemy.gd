
extends CharacterBody2D

@export var move_speed: float = 80.0
@export var mass_value: float = 5.0
@export var detection_range: float = 300.0
@export var contact_range: float = 55.0
@export var contact_damage: float = 10.0
@export var damage_cooldown: float = 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component = $EnemyHealthComponent

var player: CharacterBody2D
var is_dying: bool = false
var damage_timer: float = 0.0


func _ready():
	add_to_group("enemies")
	health_component.died.connect(_on_died)

	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta):
	if is_dying:
		return

	damage_timer = maxf(damage_timer - delta, 0.0)

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		velocity = Vector2.ZERO
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= detection_range:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	if distance <= contact_range:
		try_damage_player()

	update_animation()


func try_damage_player():
	if damage_timer > 0.0:
		return

	if player and player.has_method("take_damage"):
		player.take_damage(contact_damage)
		damage_timer = damage_cooldown


func take_damage(amount: float):
	if is_dying:
		return

	health_component.take_damage(amount)

	if not health_component.is_dead:
		animated_sprite.play("hurt")


func update_animation():
	if animated_sprite.animation == "hurt" and animated_sprite.is_playing():
		return

	if velocity.length() > 5.0:
		animated_sprite.play("move")
	else:
		animated_sprite.play("idle")


func _on_died():
	if is_dying:
		return

	is_dying = true
	velocity = Vector2.ZERO

	var player_node = get_tree().get_first_node_in_group("player")

	if player_node and player_node.has_method("absorb_enemy"):
		player_node.absorb_enemy(mass_value)

	animated_sprite.play("death")
	await animated_sprite.animation_finished

	queue_free()
