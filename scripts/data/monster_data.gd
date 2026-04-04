extends Resource
class_name MonsterData

@export var monster_name: String = ""
@export_range(1, 100) var hp: int = 1
@export var color: Color = Color(0.2, 0.8, 0.2)
@export var min_level: int = 1
@export_enum("front", "tank", "support", "elite") var role: String = "front"
