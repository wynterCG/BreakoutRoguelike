extends Node
class_name HealthComponent

signal health_changed(current_hp: int, max_hp: int)
signal died

@export var max_hp: int = 1

var _current_hp: int = 0


func _ready() -> void:
	_current_hp = max_hp


func initialize(hp: int) -> void:
	max_hp = hp
	_current_hp = hp


func take_damage(amount: int = 1) -> void:
	if _current_hp <= 0:
		return
	_current_hp = maxi(_current_hp - amount, 0)
	health_changed.emit(_current_hp, max_hp)
	if _current_hp <= 0:
		died.emit()


func heal(amount: int) -> void:
	if _current_hp <= 0:
		return
	_current_hp = mini(_current_hp + amount, max_hp)
	health_changed.emit(_current_hp, max_hp)


func get_current_hp() -> int:
	return _current_hp


func is_alive() -> bool:
	return _current_hp > 0
