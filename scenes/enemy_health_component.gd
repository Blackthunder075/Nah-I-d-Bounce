extends Node

signal health_changed(current_health: float, maximum_health: float)
signal died

@export var max_health: float = 30.0

var current_health: float
var is_dead: bool = false


func _ready():
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(amount: float):
	if is_dead or amount <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		is_dead = true
		died.emit()


func heal(amount: float):
	if is_dead or amount <= 0.0:
		return

	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
