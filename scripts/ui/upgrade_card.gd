extends PanelContainer
class_name UpgradeCard

signal selected(upgrade: UpgradeData)

const CATEGORY_COLORS: Dictionary = {
	&"offense": Color(0.9, 0.2, 0.2),
	&"defense": Color(0.2, 0.8, 0.2),
	&"utility": Color(0.2, 0.6, 1.0),
}

const STAT_FORMATS: Dictionary = {
	&"ball_damage": ["Ball Damage", "+%d", "ball_damage_bonus"],
	&"crit_chance": ["Crit Chance", "%.0f%%", "crit_chance"],
	&"piercing": ["Piercing", "%d blocks", "piercing_count"],
	&"split_shot": ["Split Balls", "%d extra", "split_count"],
	&"aoe_damage": ["AoE Damage", "%d", "aoe_damage"],
	&"lifesteal": ["Lifesteal", "%.0f%%", "lifesteal_percent"],
	&"max_hp": ["Max HP Bonus", "+%d", "max_hp_bonus"],
	&"damage_reduction": ["Dmg Reduction", "%.0f%%", "damage_reduction"],
	&"regen": ["Regen", "%d stacks", "regen_rate"],
	&"ball_speed": ["Ball Speed", "+%.0f%%", "ball_speed_bonus"],
	&"paddle_width": ["Paddle Width", "+%.0f%%", "paddle_width_bonus"],
	&"thorns": ["Thorns Damage", "%d", "thorns_damage"],
	&"burn": ["Burn DPS", "%.1f/s", "burn_dps"],
	&"laser": ["Laser Damage", "%d", "laser_damage"],
	&"chain_lightning": ["Chain Targets", "%d", "chain_count"],
	&"poison": ["Poison Stacks", "+%d", "poison_stacks"],
	&"explosive_death": ["Death Explosion", "%d", "explosive_death_damage"],
	&"shield": ["Shield Charges", "%d", "shield_charges"],
	&"hp_on_kill": ["HP on Kill", "+%d", "hp_on_kill"],
	&"slow_field": ["Slow Field", "%.0f%%", "slow_field"],
}

var _upgrade: UpgradeData = null
var _cost: int = 0
var _affordable: bool = true

@onready var _category_bar: ColorRect = $VBox/CategoryBar
@onready var _name_label: Label = $VBox/NameLabel
@onready var _description_label: Label = $VBox/DescriptionLabel
@onready var _stack_label: Label = $VBox/StackLabel
@onready var _cost_label: Label = $VBox/CostLabel


func setup(upgrade: UpgradeData, cost: int = 0) -> void:
	_upgrade = upgrade
	_cost = cost


func _ready() -> void:
	if _upgrade:
		_apply_data()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _apply_data() -> void:
	_name_label.text = _upgrade.upgrade_name
	_description_label.text = _upgrade.description
	var color: Color = CATEGORY_COLORS.get(_upgrade.category, Color.WHITE)
	_category_bar.color = color
	_update_stack_label()

	# Cost display
	if _cost > 0:
		_affordable = UpgradeManager.tokens >= _cost
		_cost_label.text = "Cost: %d token%s" % [_cost, "" if _cost == 1 else "s"]
		if _affordable:
			_cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			_cost_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			modulate = Color(0.4, 0.4, 0.4, 0.5)
			mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		_cost_label.text = ""


func _update_stack_label() -> void:
	if not STAT_FORMATS.has(_upgrade.effect_id):
		_stack_label.text = ""
		return

	var info: Array = STAT_FORMATS[_upgrade.effect_id]
	var prop: String = info[2]
	var current_value: float = float(UpgradeManager.get(prop))

	# Special display for regen: show interval
	if _upgrade.effect_id == &"regen" and current_value > 0.0:
		var interval: float = 10.0 / current_value
		_stack_label.text = "Current: 1 HP / %.1fs" % interval
		return

	var fmt: String = info[1]

	if current_value == 0.0:
		_stack_label.text = ""
	else:
		_stack_label.text = "Current: " + _format_stat(fmt, current_value)


func _format_stat(fmt: String, value: float) -> String:
	# Percentage stats need *100 for display
	if fmt.contains("%%"):
		return fmt % (value * 100.0)
	return fmt % value


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(_upgrade)
	elif event is InputEventScreenTouch and event.pressed:
		selected.emit(_upgrade)


func _on_mouse_entered() -> void:
	modulate = Color(1.2, 1.2, 1.2)


func _on_mouse_exited() -> void:
	modulate = Color.WHITE
