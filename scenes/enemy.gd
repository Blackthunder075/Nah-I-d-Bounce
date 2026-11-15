extends CharacterBody2D

@export var health: float = 60.0
@export var mass_value: float = 5.0 

func take_damage(amount: float):
	health -= amount

	print("Enemy health: ", health)

	if health <= 0:
		die()


func die():
	print("Enemy defeated!")

	var player = get_tree().get_first_node_in_group("player")

	if player:
		player.absorb_enemy(mass_value)

	queue_free()
