# Phase 4: Upgrade System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a roguelike upgrade loop — after clearing blocks, player picks 3 upgrades from random choices, then a new level starts with scaled difficulty. 12 upgrades across offense, defense, and utility categories.

**Architecture:** UpgradeData Resource defines each upgrade. UpgradeManager autoload singleton tracks accumulated stats. Upgrade selection is a CanvasLayer overlay. Ball/paddle/main read upgrade values from UpgradeManager. Level progression respawns blocks with HP scaling.

**Tech Stack:** Godot 4.6, GDScript 2.0, strict static typing, component pattern, signals via code.

---

### Task 1: UpgradeData Resource + UpgradeManager Autoload

**Files:**
- Create: `res://scripts/data/upgrade_data.gd`
- Create: `res://scripts/autoloads/upgrade_manager.gd`
- Modify: `project.godot` (add autoload)

- [ ] **Step 1: Create UpgradeData resource class**

```gdscript
# res://scripts/data/upgrade_data.gd
extends Resource
class_name UpgradeData

@export var upgrade_name: String = ""
@export_multiline var description: String = ""
@export var category: StringName = &"offense"
@export var effect_id: StringName = &""
@export var value: float = 0.0
```

- [ ] **Step 2: Create UpgradeManager autoload**

```gdscript
# res://scripts/autoloads/upgrade_manager.gd
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
var magnet_pull_strength: float = 0.0


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
		&"magnet_pull":
			magnet_pull_strength += upgrade.value


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
	magnet_pull_strength = 0.0
```

- [ ] **Step 3: Register autoload in project.godot**

Add to `[autoload]` section in `project.godot`:
```
UpgradeManager="*res://scripts/autoloads/upgrade_manager.gd"
```

- [ ] **Step 4: Commit**

```
git add scripts/data/upgrade_data.gd scripts/autoloads/upgrade_manager.gd project.godot
git commit -m "feat: add UpgradeData resource and UpgradeManager autoload"
```

---

### Task 2: Create 12 Upgrade .tres Files

**Files:**
- Create: `res://data/upgrades/ball_damage.tres`
- Create: `res://data/upgrades/crit_chance.tres`
- Create: `res://data/upgrades/piercing.tres`
- Create: `res://data/upgrades/split_shot.tres`
- Create: `res://data/upgrades/aoe_damage.tres`
- Create: `res://data/upgrades/lifesteal.tres`
- Create: `res://data/upgrades/max_hp.tres`
- Create: `res://data/upgrades/damage_reduction.tres`
- Create: `res://data/upgrades/regen.tres`
- Create: `res://data/upgrades/ball_speed.tres`
- Create: `res://data/upgrades/paddle_width.tres`
- Create: `res://data/upgrades/magnet_pull.tres`

- [ ] **Step 1: Create all 12 .tres files**

Each file follows this format (example for ball_damage):
```
[gd_resource type="Resource" script_class="UpgradeData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/data/upgrade_data.gd" id="1"]
[resource]
script = ExtResource("1")
upgrade_name = "Ball Damage +"
description = "Ball damage increases by 2. Hits monsters AND hurts you more on misses."
category = &"offense"
effect_id = &"ball_damage"
value = 2.0
```

Values for all 12:
| File | upgrade_name | description | category | effect_id | value |
|---|---|---|---|---|---|
| ball_damage.tres | Ball Damage + | Ball damage increases by 2. Hits monsters AND hurts you more on misses. | offense | ball_damage | 2.0 |
| crit_chance.tres | Critical Hit | 10% chance to deal 2x damage to monsters. Crits don't apply to self-damage. | offense | crit_chance | 0.10 |
| piercing.tres | Piercing | Ball passes through 1 block instead of bouncing. | offense | piercing | 1.0 |
| split_shot.tres | Split Shot | Ball splits into an extra ball on block hit. Extra balls last 5 seconds. | offense | split_shot | 1.0 |
| aoe_damage.tres | AoE Blast | On block hit, deal 3 damage to all blocks within range. | offense | aoe_damage | 3.0 |
| lifesteal.tres | Lifesteal | Heal 5% of damage dealt to monsters. | defense | lifesteal | 0.05 |
| max_hp.tres | Max HP + | +10 max HP. Immediately heals 10 HP. | defense | max_hp | 10.0 |
| damage_reduction.tres | Damage Reduction | Back wall self-damage reduced by 10%. Caps at 50%. | defense | damage_reduction | 0.10 |
| regen.tres | Regen | Heal 1 HP per second passively. | defense | regen | 1.0 |
| ball_speed.tres | Ball Speed + | Ball moves 10% faster. | utility | ball_speed | 0.10 |
| paddle_width.tres | Wider Paddle | Paddle width increases by 15%. | utility | paddle_width | 0.15 |
| magnet_pull.tres | Magnet Pull | Ball curves toward paddle when below it. | utility | magnet_pull | 30.0 |

- [ ] **Step 2: Commit**

```
git add data/upgrades/
git commit -m "feat: add 12 upgrade resource definitions"
```

---

### Task 3: Upgrade Card UI Scene

**Files:**
- Create: `res://scenes/ui/upgrade_card.tscn`
- Create: `res://scripts/ui/upgrade_card.gd`

- [ ] **Step 1: Create upgrade_card.gd**

```gdscript
# res://scripts/ui/upgrade_card.gd
extends PanelContainer
class_name UpgradeCard

signal selected(upgrade: UpgradeData)

const CATEGORY_COLORS: Dictionary = {
	&"offense": Color(0.9, 0.2, 0.2),
	&"defense": Color(0.2, 0.8, 0.2),
	&"utility": Color(0.2, 0.6, 1.0),
}

var _upgrade: UpgradeData = null

@onready var _category_bar: ColorRect = $VBox/CategoryBar
@onready var _name_label: Label = $VBox/NameLabel
@onready var _description_label: Label = $VBox/DescriptionLabel


func setup(upgrade: UpgradeData) -> void:
	_upgrade = upgrade


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


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(_upgrade)
	elif event is InputEventScreenTouch and event.pressed:
		selected.emit(_upgrade)


func _on_mouse_entered() -> void:
	modulate = Color(1.2, 1.2, 1.2)


func _on_mouse_exited() -> void:
	modulate = Color.WHITE
```

- [ ] **Step 2: Create upgrade_card.tscn via MCP**

Create scene with root `PanelContainer` named `UpgradeCard`, attach script. Add children:
- `VBox` (VBoxContainer)
  - `CategoryBar` (ColorRect) — height 6px, full width
  - `NameLabel` (Label) — bold, centered
  - `DescriptionLabel` (Label) — word wrap, smaller font

- [ ] **Step 3: Commit**

```
git add scenes/ui/upgrade_card.tscn scripts/ui/upgrade_card.gd
git commit -m "feat: add UpgradeCard UI component"
```

---

### Task 4: Upgrade Selection Overlay

**Files:**
- Create: `res://scenes/ui/upgrade_selection.tscn`
- Create: `res://scripts/ui/upgrade_selection.gd`

- [ ] **Step 1: Create upgrade_selection.gd**

```gdscript
# res://scripts/ui/upgrade_selection.gd
extends CanvasLayer
class_name UpgradeSelection

signal all_picks_done

const UPGRADE_CARD_SCENE: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")
const UPGRADES_DIR: String = "res://data/upgrades/"
const PICKS_PER_LEVEL: int = 3
const CARDS_PER_PICK: int = 3

var _all_upgrades: Array[UpgradeData] = []
var _current_pick: int = 0

@onready var _overlay: ColorRect = $Overlay
@onready var _title_label: Label = $Overlay/TitleLabel
@onready var _card_container: HBoxContainer = $Overlay/CardContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_all_upgrades()
	visible = false


func _load_all_upgrades() -> void:
	_all_upgrades.clear()
	if not DirAccess.dir_exists_absolute(UPGRADES_DIR):
		return

	var dir: DirAccess = DirAccess.open(UPGRADES_DIR)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: Resource = ResourceLoader.load(UPGRADES_DIR + file_name)
			if res is UpgradeData:
				_all_upgrades.append(res as UpgradeData)
		file_name = dir.get_next()
	dir.list_dir_end()


func show_selection() -> void:
	_current_pick = 0
	visible = true
	_show_pick_round()


func _show_pick_round() -> void:
	_title_label.text = "Choose an Upgrade (" + str(_current_pick + 1) + "/" + str(PICKS_PER_LEVEL) + ")"

	# Clear old cards
	for child: Node in _card_container.get_children():
		child.queue_free()

	# Pick 3 random upgrades
	var shuffled: Array[UpgradeData] = _all_upgrades.duplicate()
	shuffled.shuffle()
	var count: int = mini(CARDS_PER_PICK, shuffled.size())

	for i: int in range(count):
		var card: UpgradeCard = UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
		card.setup(shuffled[i])
		card.selected.connect(_on_card_selected)
		_card_container.add_child(card)


func _on_card_selected(upgrade: UpgradeData) -> void:
	UpgradeManager.apply_upgrade(upgrade)
	_current_pick += 1

	if _current_pick >= PICKS_PER_LEVEL:
		visible = false
		all_picks_done.emit()
	else:
		_show_pick_round()
```

- [ ] **Step 2: Create upgrade_selection.tscn via MCP**

Create scene with root `CanvasLayer` named `UpgradeSelection`, attach script. Add children:
- `Overlay` (ColorRect) — full screen, semi-transparent dark `Color(0, 0, 0, 0.7)`, anchors full rect
  - `TitleLabel` (Label) — centered top, font size 24
  - `CardContainer` (HBoxContainer) — centered, with separation between cards

- [ ] **Step 3: Commit**

```
git add scenes/ui/upgrade_selection.tscn scripts/ui/upgrade_selection.gd
git commit -m "feat: add upgrade selection overlay UI"
```

---

### Task 5: Wire Level Progression + Upgrade Selection into main.gd

**Files:**
- Modify: `res://scripts/main.gd`
- Modify: `res://scenes/main.tscn`

- [ ] **Step 1: Add UpgradeSelection to main.tscn**

Add instance of `upgrade_selection.tscn` as child of Main.

- [ ] **Step 2: Modify main.gd for level progression**

Changes to `res://scripts/main.gd`:

Add new variables:
```gdscript
var _level: int = 1
```

Add `@onready` reference:
```gdscript
@onready var _upgrade_selection: UpgradeSelection = $UpgradeSelection
```

In `_ready()`, connect upgrade selection signal:
```gdscript
_upgrade_selection.all_picks_done.connect(_on_all_picks_done)
```

Replace `_on_block_destroyed()`:
```gdscript
func _on_block_destroyed() -> void:
	_blocks_remaining -= 1
	if _blocks_remaining <= 0:
		_start_upgrade_selection()
```

Add new functions:
```gdscript
func _start_upgrade_selection() -> void:
	get_tree().paused = true
	_upgrade_selection.show_selection()


func _on_all_picks_done() -> void:
	get_tree().paused = false
	_level += 1
	_start_next_level()


func _start_next_level() -> void:
	# Clear remaining blocks
	for child: Node in _block_container.get_children():
		child.queue_free()
	_blocks_remaining = 0

	# Apply max HP bonus if gained
	var total_max_hp: int = PLAYER_MAX_HP + UpgradeManager.max_hp_bonus
	_player_health.max_hp = total_max_hp
	_player_health._current_hp = mini(_player_health.get_current_hp(), total_max_hp)

	# Respawn blocks with scaled HP
	_spawn_enemies()

	# Reset ball to paddle
	if _current_ball and is_instance_valid(_current_ball):
		_current_ball.reset_to_paddle()
	else:
		_spawn_ball()

	_update_hp_bar()
```

Modify `_spawn_enemies()` to apply level HP scaling:
```gdscript
# After setting block.monster_data or block.max_hp, scale by level:
# Replace the hp assignment with:
if monster_data:
	block.monster_data = _monster_types[type_index]
	block.max_hp = int(ceilf(float(monster_data.hp) * (1.0 + (_level - 1) * 0.2)))
```

Add `_physics_process` for regen:
```gdscript
func _physics_process(delta: float) -> void:
	if _game_over:
		return
	if UpgradeManager.regen_rate > 0.0:
		_regen_accumulator += UpgradeManager.regen_rate * delta
		if _regen_accumulator >= 1.0:
			var heal_amount: int = int(_regen_accumulator)
			_regen_accumulator -= float(heal_amount)
			_player_health.heal(heal_amount)
```

Add `var _regen_accumulator: float = 0.0` to variables.

Modify `_on_ball_hit_back_wall()` for damage reduction:
```gdscript
func _on_ball_hit_back_wall(ball_damage: int) -> void:
	if _game_over:
		return
	var reduced: int = maxi(int(float(ball_damage) * (1.0 - UpgradeManager.damage_reduction)), 1)
	_player_health.take_damage(reduced)
```

Modify `_input()` restart to reset UpgradeManager:
```gdscript
# In the restart block, before reload_current_scene():
UpgradeManager.reset()
```

- [ ] **Step 3: Add heal() to HealthComponent**

Add to `res://scripts/components/health_component.gd`:
```gdscript
func heal(amount: int) -> void:
	if _current_hp <= 0:
		return
	_current_hp = mini(_current_hp + amount, max_hp)
	health_changed.emit(_current_hp, max_hp)
```

- [ ] **Step 4: Commit**

```
git add scripts/main.gd scenes/main.tscn scripts/components/health_component.gd
git commit -m "feat: wire upgrade selection and level progression into main"
```

---

### Task 6: Implement Simple Stat Upgrades (Ball Damage, Ball Speed, Wider Paddle)

**Files:**
- Modify: `res://scripts/ball.gd`
- Modify: `res://scripts/paddle.gd`

- [ ] **Step 1: Ball reads effective damage and speed from UpgradeManager**

In `ball.gd`, modify `_handle_collision()` to use effective damage:
```gdscript
# Replace collider.hit(damage) with:
var effective_damage: int = UpgradeManager.get_effective_ball_damage(damage)
collider.hit(effective_damage)

# Replace hit_back_wall.emit(damage) with:
var effective_damage_wall: int = UpgradeManager.get_effective_ball_damage(damage)
hit_back_wall.emit(effective_damage_wall)
```

In `ball.gd`, modify `_physics_process()` to use effective speed:
```gdscript
# Replace: var motion: Vector2 = _direction * _speed * delta
var effective_speed: float = UpgradeManager.get_effective_ball_speed(_speed)
var motion: Vector2 = _direction * effective_speed * delta
```

- [ ] **Step 2: Paddle reads effective width from UpgradeManager**

In `paddle.gd`, modify `_ready()`:
```gdscript
func _ready() -> void:
	_screen_width = get_viewport_rect().size.x
	apply_width_upgrade()


func apply_width_upgrade() -> void:
	var effective_width: float = UpgradeManager.get_effective_paddle_width(ARC_WIDTH)
	var arc_points: PackedVector2Array = _generate_arc_points_with_width(effective_width)
	_collision.polygon = arc_points
	_visual.polygon = arc_points
	_visual.color = Color(0.2, 0.6, 1.0)
```

Rename `_generate_arc_points()` to `_generate_arc_points_with_width(width: float)` and use `width` instead of `ARC_WIDTH` for `half_width`.

Also update `_physics_process()` to use effective width for clamping:
```gdscript
var effective_width: float = UpgradeManager.get_effective_paddle_width(ARC_WIDTH)
var half_width: float = effective_width / 2.0
```

- [ ] **Step 3: Commit**

```
git add scripts/ball.gd scripts/paddle.gd
git commit -m "feat: implement ball damage, ball speed, and wider paddle upgrades"
```

---

### Task 7: Implement Critical Hit + Lifesteal

**Files:**
- Modify: `res://scripts/ball.gd`
- Modify: `res://scripts/main.gd`

- [ ] **Step 1: Add crit logic to ball collision**

In `ball.gd`, modify the block hit section of `_handle_collision()`:
```gdscript
# Replace the block hit notification section with:
if collider is not Paddle and collider.has_method("hit"):
	var effective_damage: int = UpgradeManager.get_effective_ball_damage(damage)

	# Critical hit (monsters only)
	var is_crit: bool = UpgradeManager.crit_chance > 0.0 and randf() < UpgradeManager.crit_chance
	if is_crit:
		effective_damage *= 2

	collider.hit(effective_damage)

	# Lifesteal
	if UpgradeManager.lifesteal_percent > 0.0:
		var heal_amount: int = maxi(int(float(effective_damage) * UpgradeManager.lifesteal_percent), 1)
		_heal_player(heal_amount)
```

Add signal for healing:
```gdscript
signal heal_player(amount: int)
```

Add helper:
```gdscript
func _heal_player(amount: int) -> void:
	heal_player.emit(amount)
```

- [ ] **Step 2: Connect heal signal in main.gd**

In `_spawn_ball()`:
```gdscript
_current_ball.heal_player.connect(_on_ball_heal_player)
```

Add handler:
```gdscript
func _on_ball_heal_player(amount: int) -> void:
	_player_health.heal(amount)
	_update_hp_bar()
```

- [ ] **Step 3: Commit**

```
git add scripts/ball.gd scripts/main.gd
git commit -m "feat: implement critical hit and lifesteal upgrades"
```

---

### Task 8: Implement AoE Blast

**Files:**
- Modify: `res://scripts/ball.gd`

- [ ] **Step 1: Add AoE logic after block hit**

In `ball.gd`, add after the `collider.hit()` call in `_handle_collision()`:
```gdscript
	# AoE Blast
	if UpgradeManager.aoe_damage > 0 and collider is Node2D:
		var hit_position: Vector2 = (collider as Node2D).global_position
		var blocks: Array[Node] = get_tree().get_nodes_in_group("blocks")
		for block_node: Node in blocks:
			if block_node == collider:
				continue
			if block_node is Node2D and block_node.has_method("hit"):
				var dist: float = (block_node as Node2D).global_position.distance_to(hit_position)
				if dist <= 80.0:
					(block_node as Node2D).hit(UpgradeManager.aoe_damage)
```

- [ ] **Step 2: Add blocks to "blocks" group**

In `block.gd`, add in `_ready()`:
```gdscript
add_to_group("blocks")
```

- [ ] **Step 3: Commit**

```
git add scripts/ball.gd scripts/block.gd
git commit -m "feat: implement AoE blast upgrade"
```

---

### Task 9: Implement Piercing

**Files:**
- Modify: `res://scripts/ball.gd`

- [ ] **Step 1: Add piercing logic**

Add variable to ball.gd:
```gdscript
var _piercing_remaining: int = 0
```

At the start of `_physics_process()`, after the launched check, reset piercing counter:
```gdscript
_piercing_remaining = UpgradeManager.piercing_count
```

In `_handle_collision()`, modify the block bounce behavior:
```gdscript
if collider is Paddle:
	_handle_paddle_bounce(collider as Paddle, collision)
else:
	# Check piercing: if we have piercing charges and hit a block, don't bounce
	var is_block: bool = collider.has_method("hit")
	if is_block and _piercing_remaining > 0:
		_piercing_remaining -= 1
		# Don't change direction — ball passes through
	else:
		_direction = _direction.bounce(collision.get_normal())
```

- [ ] **Step 2: Commit**

```
git add scripts/ball.gd
git commit -m "feat: implement piercing upgrade"
```

---

### Task 10: Implement Split Shot

**Files:**
- Modify: `res://scripts/ball.gd`
- Modify: `res://scripts/main.gd`

- [ ] **Step 1: Add split signal to ball**

In `ball.gd`, add signal:
```gdscript
signal split_requested(position: Vector2, count: int)
```

In `_handle_collision()`, after the block hit section:
```gdscript
	# Split Shot
	if UpgradeManager.split_count > 0 and collider.has_method("hit"):
		split_requested.emit(global_position, UpgradeManager.split_count)
```

- [ ] **Step 2: Handle split in main.gd**

In `_spawn_ball()`, connect:
```gdscript
_current_ball.split_requested.connect(_on_ball_split_requested)
```

Add handler:
```gdscript
func _on_ball_split_requested(pos: Vector2, count: int) -> void:
	for i: int in range(count):
		var split_ball: Ball = BALL_SCENE.instantiate() as Ball
		split_ball.global_position = pos
		split_ball._is_launched = true
		split_ball._direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, -0.3)).normalized()
		split_ball._speed = BASE_SPEED
		split_ball.hit_back_wall.connect(_on_ball_hit_back_wall)
		split_ball.heal_player.connect(_on_ball_heal_player)
		add_child(split_ball)

		# Despawn after 5 seconds
		var timer: SceneTreeTimer = get_tree().create_timer(5.0)
		timer.timeout.connect(split_ball.queue_free)
```

Note: split balls do NOT connect `split_requested` — they don't split further (prevents infinite chains).

- [ ] **Step 3: Commit**

```
git add scripts/ball.gd scripts/main.gd
git commit -m "feat: implement split shot upgrade"
```

---

### Task 11: Implement Magnet Pull

**Files:**
- Modify: `res://scripts/ball.gd`

- [ ] **Step 1: Add magnet pull to _physics_process()**

In `ball.gd`, modify `_physics_process()`, after the motion calculation:
```gdscript
# Magnet pull: curve ball toward paddle when below paddle Y
if _paddle and UpgradeManager.magnet_pull_strength > 0.0:
	if global_position.y > _paddle.global_position.y - 100.0:
		var pull_dir: float = _paddle.global_position.x - global_position.x
		var pull_sign: float = signf(pull_dir)
		_direction.x += pull_sign * UpgradeManager.magnet_pull_strength * delta / _speed
		_direction = _direction.normalized()
```

- [ ] **Step 2: Commit**

```
git add scripts/ball.gd
git commit -m "feat: implement magnet pull upgrade"
```

---

### Task 12: Implement Max HP Upgrade (immediate heal on pick)

**Files:**
- Modify: `res://scripts/main.gd`

- [ ] **Step 1: Handle max HP change when upgrade is picked**

In `_on_all_picks_done()`, after unpausing:
```gdscript
# Apply max HP bonus
var total_max_hp: int = PLAYER_MAX_HP + UpgradeManager.max_hp_bonus
if _player_health.max_hp != total_max_hp:
	var hp_gained: int = total_max_hp - _player_health.max_hp
	_player_health.max_hp = total_max_hp
	_player_health.heal(hp_gained)
	_update_hp_bar()
```

- [ ] **Step 2: Commit**

```
git add scripts/main.gd
git commit -m "feat: implement max HP upgrade with immediate heal"
```

---

### Task 13: Final Integration + Verification

**Files:**
- All modified files

- [ ] **Step 1: Run the game via MCP and verify**

1. Play scene, launch ball, clear all blocks
2. Verify upgrade selection overlay appears (game paused)
3. Pick 3 upgrades, verify cards show name/description/category color
4. Verify next level starts with fresh scaled blocks
5. Verify HP carries over between levels

- [ ] **Step 2: Test each upgrade**

Pick specific upgrades and verify:
- Ball Damage+: blocks die faster, back wall hurts more
- Ball Speed+: ball moves visibly faster
- Wider Paddle: paddle visually wider
- Crit: some hits deal double (check HP numbers on blocks)
- Lifesteal: HP recovers when hitting blocks
- Max HP: HP bar grows, immediate heal
- Damage Reduction: back wall hits hurt less
- Regen: HP slowly recovers over time
- AoE: nearby blocks take damage
- Piercing: ball passes through blocks
- Split: extra balls spawn, despawn after 5s
- Magnet: ball curves toward paddle near bottom

- [ ] **Step 3: Test stacking**

Pick Ball Damage+ 3 times. Verify ball does 5 + 6 = 11 damage (base 5 + 3*2 bonus).

- [ ] **Step 4: Test game over**

Let HP reach 0 — "GAME OVER" appears. Tap to restart. Verify UpgradeManager resets.

- [ ] **Step 5: Code review + commit**

Run superpowers:code-reviewer agent on all changes.
Fix any issues found.

```
git add -A
git commit -m "phase4_00: upgrade system with 12 upgrades and level progression"
git push
```
