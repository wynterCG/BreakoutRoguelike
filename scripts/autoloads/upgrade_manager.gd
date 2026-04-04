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
var thorns_damage: int = 0

# New upgrades
var burn_dps: float = 0.0
var laser_damage: int = 0
var chain_count: int = 0
var poison_stacks: int = 0
var explosive_death_damage: int = 0
var shield_charges: int = 0
var hp_on_kill: int = 0
var slow_field: float = 0.0


func apply_upgrade(upgrade: UpgradeData) -> void:
	match upgrade.effect_id:
		&"ball_damage":
			ball_damage_bonus += int(upgrade.value)
		&"crit_chance":
			crit_chance = minf(crit_chance + upgrade.value, 1.0)
		&"piercing":
			piercing_count += int(upgrade.value)
		&"split_shot":
			split_count += int(upgrade.value)
		&"aoe_damage":
			aoe_damage += int(upgrade.value)
		&"lifesteal":
			lifesteal_percent = minf(lifesteal_percent + upgrade.value, 1.0)
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
		&"burn":
			burn_dps += upgrade.value
		&"laser":
			laser_damage += int(upgrade.value)
		&"chain_lightning":
			chain_count += int(upgrade.value)
		&"poison":
			poison_stacks += int(upgrade.value)
		&"explosive_death":
			explosive_death_damage += int(upgrade.value)
		&"shield":
			shield_charges += int(upgrade.value)
		&"hp_on_kill":
			hp_on_kill += int(upgrade.value)
		&"slow_field":
			slow_field = minf(slow_field + upgrade.value, 0.9)


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
	thorns_damage = 0
	burn_dps = 0.0
	laser_damage = 0
	chain_count = 0
	poison_stacks = 0
	explosive_death_damage = 0
	shield_charges = 0
	hp_on_kill = 0
	slow_field = 0.0
