
extends CharacterBody2D

@export var move_speed: float = 65.0
@export var contact_range: float = 55.0
@export var contact_damage: float = 20.0
@export var damage_cooldown: float = 1.0

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var max_minions: int = 4
@export var spawn_distance: float = 90.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component = $BossHealthComponent

var player: CharacterBody2D
var is_dying: bool = false

var spawn_timer: float = 0.0
var damage_timer: float = 0.0


func _ready():
	add_to_group("enemies")

	health_component.died.connect(_on_died)

	player = get_tree().get_first_node_in_group("player")

	spawn_timer = spawn_interval


func _physics_process(delta):
	if is_dying:
		return

	spawn_timer -= delta
	damage_timer = maxf(damage_timer - delta, 0.0)

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var distance = global_position.distance_to(player.global_position)

	var direction = global_position.direction_to(player.global_position)

	velocity = direction * move_speed
	move_and_slide()

	if distance <= contact_range:
		try_damage_player()

	if spawn_timer <= 0.0:
		spawn_minions()
		spawn_timer = spawn_interval

	update_animation()


func spawn_minions():
	if enemy_scene == null:
		push_warning("Assign an enemy scene to the Slime King!")
		return

	var minion_count = get_tree().get_nodes_in_group("boss_minions").size()

	if minion_count >= max_minions:
		return

	var minions_to_spawn = min(2, max_minions - minion_count)

	for i in range(minions_to_spawn):
		var enemy = enemy_scene.instantiate()

		get_parent().add_child(enemy)

		var angle = randf_range(0.0, TAU)
		var offset = Vector2.RIGHT.rotated(angle) * spawn_distance

		enemy.global_position = global_position + offset
		enemy.add_to_group("boss_minions")


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

	animated_sprite.play("death")
	await animated_sprite.animation_finished

	queue_free()
