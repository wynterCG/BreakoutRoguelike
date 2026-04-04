extends Resource
class_name MonsterData

@export var monster_name: String = ""
@export_range(1, 100) var hp: int = 1
@export var color: Color = Color(0.2, 0.8, 0.2)
@export var min_level: int = 1
@export_enum("front", "tank", "support", "elite") var role: String = "front"
@export_range(1, 10) var token_value: int = 1

@export_group("Movement")
@export var drift_enabled: bool = false
@export var drift_speed: float = 30.0
@export var zigzag_enabled: bool = false
@export var zigzag_speed: float = 40.0
@export var orbit_enabled: bool = false
@export var orbit_speed: float = 50.0
@export var orbit_radius: float = 30.0
@export var charge_enabled: bool = false
@export var charge_speed: float = 100.0
@export var charge_interval: float = 3.0

@export_group("Shooting")
@export var shoot_straight_enabled: bool = false
@export var shoot_straight_speed: float = 150.0
@export var shoot_straight_interval: float = 3.0
@export var shoot_straight_damage: int = 5

@export var shoot_aimed_enabled: bool = false
@export var shoot_aimed_speed: float = 120.0
@export var shoot_aimed_interval: float = 4.0
@export var shoot_aimed_damage: int = 5

@export var shoot_spread_enabled: bool = false
@export var shoot_spread_speed: float = 130.0
@export var shoot_spread_interval: float = 5.0
@export var shoot_spread_damage: int = 3
@export_range(2, 7) var shoot_spread_count: int = 3

@export var shoot_burst_enabled: bool = false
@export var shoot_burst_speed: float = 140.0
@export var shoot_burst_interval: float = 4.0
@export var shoot_burst_damage: int = 3
@export_range(2, 5) var shoot_burst_count: int = 3
