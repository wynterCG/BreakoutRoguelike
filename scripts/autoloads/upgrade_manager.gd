extends Node

var ball_damage_bonus: int = 0
var crit_chance: float = 0.0
var piercing_count: int = 0
var split_count: int = 0
var aoe_damage: int = 0
var lifesteal_percent: float = 0.0
var max_hp_bonus: int = 0
var damage_reduction: float = 0.0
var regen_rate: float = 0.0
var ball_speed_bonus: float = 0.0
var paddle_width_bonus: float = 0.0
var thorns_damage: float = 0.0


func apply_upgrade(upgrade: UpgradeData) -> void:
	match upgrade.effect_id:
		&"ball_damage":
			ball_damage_bonus += int(upgrade.value)
		&"crit_chance":
			crit_chance += upgrade.value
		&"piercing":
			piercing_count += int(upgrade.value)
		&"split_shot":
			split_count += int(upgrade.value)
		&"aoe_damage":
			aoe_damage += int(upgrade.value)
		&"lifesteal":
			lifesteal_percent += upgrade.value
		&"max_hp":
			max_hp_bonus += int(upgrade.value)
		&"damage_reduction":
			damage_reduction = minf(damage_reduction + upgrade.value, 0.5)
		&"regen":
			regen_rate += upgrade.value
		&"ball_speed":
			ball_speed_bonus += upgrade.value
		&"paddle_width":
			paddle_width_bonus += upgrade.value
		&"thorns":
			thorns_damage += int(upgrade.value)


func get_effective_ball_damage(base: int) -> int:
	return base + ball_damage_bonus


func get_effective_ball_speed(base: float) -> float:
	return base * (1.0 + ball_speed_bonus)


func get_effective_paddle_width(base: float) -> float:
	return base * (1.0 + paddle_width_bonus)


func reset() -> void:
	ball_damage_bonus = 0
	crit_chance = 0.0
	piercing_count = 0
	split_count = 0
	aoe_damage = 0
	lifesteal_percent = 0.0
	max_hp_bonus = 0
	damage_reduction = 0.0
	regen_rate = 0.0
	ball_speed_bonus = 0.0
	paddle_width_bonus = 0.0
	thorns_damage = 0.0
