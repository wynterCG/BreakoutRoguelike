extends Resource
class_name FormationData

@export var formation_name: String = ""
@export_range(1, 20) var grid_columns: int = 14
@export_range(1, 10) var grid_rows: int = 7
@export var template_index: int = -1
@export var cells: Array[FormationCell] = []
