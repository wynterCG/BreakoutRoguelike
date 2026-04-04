# Monster Movement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add combinable movement patterns (drift, zigzag, orbit, charge) to monsters, configured per MonsterData and driven by a MovementComponent.

**Architecture:** MonsterData gets boolean+speed exports per pattern. Block changes from StaticBody2D to CharacterBody2D. A new MovementComponent calculates combined velocity from enabled patterns. Block calls move_and_slide() each frame.

**Tech Stack:** Godot 4.6, GDScript

---

### Task 1: Add movement properties to MonsterData

**Files:**
- Modify: `res://scripts/data/monster_data.gd`

- [ ] **Step 1: Add movement exports**

```gdscript
extends Resource
class_name MonsterData

@export var monster_name: String = ""
@export_range(1, 100) var hp: int = 1
@export var color: Color = Color(0.2, 0.8, 0.2)
@export var min_level: int = 1
@export_enum("front", "tank", "support", "elite") var role: String = "front"

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
```

- [ ] **Step 2: Verify in Godot**

Open monster editor, click any monster. Confirm "Movement" group appears in inspector with checkboxes and speed values. Existing monsters default to all disabled.

- [ ] **Step 3: Commit**

```bash
git add scripts/data/monster_data.gd
git commit -m "feat: add movement pattern properties to MonsterData"
```

---

### Task 2: Create MovementComponent

**Files:**
- Create: `res://scripts/components/movement_component.gd`

- [ ] **Step 1: Write MovementComponent**

```gdscript
extends Node
class_name MovementComponent

const ARENA_MIN_X: float = 30.0
const ARENA_MAX_X: float = 1250.0
const ARENA_MIN_Y: float = 30.0
const ARENA_MAX_Y: float = 680.0
const DRIFT_BOUND: float = 120.0
const ZIGZAG_BOUND: float = 80.0
const CHARGE_HOLD_TIME: float = 0.5
const CHARGE_TARGET_OFFSET: float = 60.0
const MAX_COMBINED_SPEED: float = 200.0

enum ChargeState { IDLE, CHARGING, HOLDING, RETURNING }

var _spawn_position: Vector2 = Vector2.ZERO
var _monster_data: MonsterData = null
var _paddle_y: float = 650.0

# Drift state
var _drift_direction: float = 1.0

# Zigzag state
var _zigzag_direction: Vector2 = Vector2(1.0, 1.0)

# Orbit state
var _orbit_angle: float = 0.0

# Charge state
var _charge_state: ChargeState = ChargeState.IDLE
var _charge_timer: float = 0.0


func initialize(data: MonsterData, spawn_pos: Vector2) -> void:
	_monster_data = data
	_spawn_position = spawn_pos

	# Randomize starting directions
	_drift_direction = 1.0 if randf() > 0.5 else -1.0
	var diag_x: float = 1.0 if randf() > 0.5 else -1.0
	var diag_y: float = 1.0 if randf() > 0.5 else -1.0
	_zigzag_direction = Vector2(diag_x, diag_y).normalized()
	_orbit_angle = randf() * TAU

	if data.charge_enabled:
		_charge_timer = data.charge_interval * randf()


func get_movement_velocity(current_pos: Vector2, delta: float) -> Vector2:
	if not _monster_data:
		return Vector2.ZERO

	var combined: Vector2 = Vector2.ZERO

	if _monster_data.drift_enabled:
		combined += _calc_drift(current_pos)

	if _monster_data.zigzag_enabled:
		combined += _calc_zigzag(current_pos)

	if _monster_data.orbit_enabled:
		combined += _calc_orbit(current_pos, delta)

	if _monster_data.charge_enabled:
		combined += _calc_charge(current_pos, delta)

	# Clamp combined speed
	if combined.length() > MAX_COMBINED_SPEED:
		combined = combined.normalized() * MAX_COMBINED_SPEED

	return combined


func _calc_drift(current_pos: Vector2) -> Vector2:
	var speed: float = _monster_data.drift_speed
	var drift_offset: float = current_pos.x - _spawn_position.x

	# Reverse at bounds
	if drift_offset > DRIFT_BOUND:
		_drift_direction = -1.0
	elif drift_offset < -DRIFT_BOUND:
		_drift_direction = 1.0

	# Reverse at arena walls
	if current_pos.x >= ARENA_MAX_X:
		_drift_direction = -1.0
	elif current_pos.x <= ARENA_MIN_X:
		_drift_direction = 1.0

	return Vector2(_drift_direction * speed, 0.0)


func _calc_zigzag(current_pos: Vector2) -> Vector2:
	var speed: float = _monster_data.zigzag_speed
	var offset: Vector2 = current_pos - _spawn_position

	# Bounce at bounding box
	if absf(offset.x) > ZIGZAG_BOUND:
		_zigzag_direction.x = -signf(offset.x)
	if absf(offset.y) > ZIGZAG_BOUND:
		_zigzag_direction.y = -signf(offset.y)

	# Bounce at arena walls
	if current_pos.x >= ARENA_MAX_X or current_pos.x <= ARENA_MIN_X:
		_zigzag_direction.x = -_zigzag_direction.x
	if current_pos.y >= ARENA_MAX_Y or current_pos.y <= ARENA_MIN_Y:
		_zigzag_direction.y = -_zigzag_direction.y

	return _zigzag_direction.normalized() * speed


func _calc_orbit(current_pos: Vector2, delta: float) -> Vector2:
	var angular_speed: float = _monster_data.orbit_speed / _monster_data.orbit_radius
	_orbit_angle += angular_speed * delta

	var target: Vector2 = _spawn_position + Vector2(
		cos(_orbit_angle) * _monster_data.orbit_radius,
		sin(_orbit_angle) * _monster_data.orbit_radius
	)

	var diff: Vector2 = target - current_pos
	if diff.length() < 1.0:
		return Vector2.ZERO
	return diff.normalized() * _monster_data.orbit_speed


func _calc_charge(current_pos: Vector2, delta: float) -> Vector2:
	var speed: float = _monster_data.charge_speed

	match _charge_state:
		ChargeState.IDLE:
			_charge_timer -= delta
			if _charge_timer <= 0.0:
				_charge_state = ChargeState.CHARGING
			return Vector2.ZERO

		ChargeState.CHARGING:
			var target_y: float = _paddle_y - CHARGE_TARGET_OFFSET
			if current_pos.y >= target_y:
				_charge_state = ChargeState.HOLDING
				_charge_timer = CHARGE_HOLD_TIME
				return Vector2.ZERO
			return Vector2(0.0, speed)

		ChargeState.HOLDING:
			_charge_timer -= delta
			if _charge_timer <= 0.0:
				_charge_state = ChargeState.RETURNING
			return Vector2.ZERO

		ChargeState.RETURNING:
			var diff_y: float = _spawn_position.y - current_pos.y
			if absf(diff_y) < 2.0:
				_charge_state = ChargeState.IDLE
				_charge_timer = _monster_data.charge_interval
				return Vector2.ZERO
			return Vector2(0.0, signf(diff_y) * speed * 0.5)

	return Vector2.ZERO
```

- [ ] **Step 2: Commit**

```bash
git add scripts/components/movement_component.gd
git commit -m "feat: add MovementComponent with drift/zigzag/orbit/charge patterns"
```

---

### Task 3: Change Block from StaticBody2D to CharacterBody2D

**Files:**
- Modify: `res://scripts/block.gd`
- Modify: `res://scenes/entities/block.tscn`

- [ ] **Step 1: Update block.tscn**

Change the Block node type from StaticBody2D to CharacterBody2D. Set collision_mask to 0 (block doesn't detect collisions — the ball detects blocks). Add MovementComponent child node.

```
[gd_scene format=3 uid="uid://block001"]

[ext_resource type="Script" uid="uid://swv2pbltrx6o" path="res://scripts/block.gd" id="1_block"]
[ext_resource type="Script" uid="uid://b841g0ckswm8v" path="res://scripts/components/health_component.gd" id="2_health"]
[ext_resource type="Script" path="res://scripts/components/movement_component.gd" id="3_movement"]

[node name="Block" type="CharacterBody2D" unique_id=207901202]
collision_layer = 8
collision_mask = 0
script = ExtResource("1_block")

[node name="CollisionShape2D" type="CollisionShape2D" parent="." unique_id=1632343551]

[node name="Background" type="ColorRect" parent="." unique_id=1397264186]

[node name="FillBar" type="ColorRect" parent="Background" unique_id=503227592]
layout_mode = 0

[node name="HPLabel" type="Label" parent="Background" unique_id=1922645270]
layout_mode = 0
horizontal_alignment = 1
vertical_alignment = 1

[node name="HealthComponent" type="Node" parent="." unique_id=512670342]
script = ExtResource("2_health")

[node name="MovementComponent" type="Node" parent="."]
script = ExtResource("3_movement")
```

- [ ] **Step 2: Update block.gd**

Change `extends StaticBody2D` to `extends CharacterBody2D`. Add movement integration:

```gdscript
extends CharacterBody2D
class_name Block

signal destroyed

const BLOCK_WIDTH: float = 60.0
const BLOCK_HEIGHT: float = 24.0
const BAR_PADDING: float = 2.0

# static var because GDScript does not support typed array constants
static var _FALLBACK_COLORS: Array[Color] = [
	Color(0.2, 0.8, 0.2),   # 1 HP - green
	Color(0.9, 0.7, 0.1),   # 2 HP - yellow
	Color(0.9, 0.2, 0.2),   # 3 HP - red
]

@export var monster_data: MonsterData = null
@export var max_hp: int = 1
@export var size_scale: Vector2 = Vector2(1.0, 1.0)

var _total_hp: int = 1
var _block_size: Vector2 = Vector2(BLOCK_WIDTH, BLOCK_HEIGHT)

@onready var _background: ColorRect = $Background
@onready var _fill_bar: ColorRect = $Background/FillBar
@onready var _hp_label: Label = $Background/HPLabel
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _health: HealthComponent = $HealthComponent
@onready var _movement: MovementComponent = $MovementComponent


func _ready() -> void:
	add_to_group("blocks")
	var hp: int = max_hp
	var block_color: Color = Color.WHITE

	if monster_data:
		hp = max_hp if max_hp > 1 else monster_data.hp
		block_color = monster_data.color
	else:
		var color_index: int = clampi(hp - 1, 0, _FALLBACK_COLORS.size() - 1)
		block_color = _FALLBACK_COLORS[color_index]

	_block_size = Vector2(BLOCK_WIDTH * size_scale.x, BLOCK_HEIGHT * size_scale.y)

	_total_hp = hp
	_health.initialize(hp)

	# Collision
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = _block_size
	_collision.shape = rect

	# Background (dark border/empty area)
	_background.size = _block_size
	_background.position = Vector2(-_block_size.x / 2.0, -_block_size.y / 2.0)
	_background.color = Color(0.15, 0.15, 0.15)

	# Fill bar (colored HP fill inside the block)
	_fill_bar.position = Vector2(BAR_PADDING, BAR_PADDING)
	_fill_bar.size = Vector2(_block_size.x - BAR_PADDING * 2.0, _block_size.y - BAR_PADDING * 2.0)
	_fill_bar.color = block_color

	# HP label centered on the block (relative to Background parent)
	_hp_label.position = Vector2.ZERO
	_hp_label.size = _block_size
	_hp_label.text = str(hp)
	var font_scale: float = clampf(minf(size_scale.x, size_scale.y), 0.7, 3.0)
	_hp_label.add_theme_font_size_override("font_size", int(14.0 * font_scale))
	_hp_label.add_theme_color_override("font_color", Color.WHITE)
	_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	_hp_label.add_theme_constant_override("shadow_offset_y", 1)

	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)

	# Initialize movement
	if monster_data:
		_movement.initialize(monster_data, global_position)


func _physics_process(delta: float) -> void:
	var move_velocity: Vector2 = _movement.get_movement_velocity(global_position, delta)
	if move_velocity != Vector2.ZERO:
		velocity = move_velocity
		move_and_slide()


func get_block_size() -> Vector2:
	return _block_size


func hit(amount: int) -> void:
	_health.take_damage(amount)


func _on_health_changed(_new_hp: int, _new_max: int) -> void:
	_update_visual()


func _on_died() -> void:
	destroyed.emit()
	call_deferred("queue_free")


func _update_visual() -> void:
	var current_hp: int = _health.get_current_hp()
	var inner_width: float = _block_size.x - BAR_PADDING * 2.0
	var hp_ratio: float = float(current_hp) / float(_total_hp)
	_fill_bar.size.x = inner_width * hp_ratio
	_hp_label.text = str(current_hp)
```

- [ ] **Step 3: Verify in Godot**

Run the game. All blocks should remain static (no movement patterns enabled on any monster). Ball collision, HP bars, and destruction all work as before.

- [ ] **Step 4: Commit**

```bash
git add scripts/block.gd scenes/entities/block.tscn
git commit -m "feat: block uses CharacterBody2D with MovementComponent integration"
```

---

### Task 4: End-to-end verification

- [ ] **Step 1: Test static behavior**

Run the game with no movement enabled on any monster. Everything should behave identically to before — static blocks, ball bouncing, HP bars, level progression.

- [ ] **Step 2: Test drift**

Open monster editor, click Goblin. Enable `drift_enabled`, set `drift_speed = 40`. Run the game on a level with Goblins. Confirm they drift left/right, reversing at arena walls and at ±120px from spawn.

- [ ] **Step 3: Test zigzag**

Enable `zigzag_enabled` on Imp, set `zigzag_speed = 50`. Run game. Confirm Imps move diagonally, bouncing within ±80px of spawn position.

- [ ] **Step 4: Test orbit**

Enable `orbit_enabled` on Shaman, set `orbit_speed = 50, orbit_radius = 25`. Run game. Confirm Shamans circle their spawn point.

- [ ] **Step 5: Test charge**

Enable `charge_enabled` on Demon, set `charge_speed = 120, charge_interval = 4`. Run game. Confirm Demons sit idle, then rush toward paddle, hold briefly, then return.

- [ ] **Step 6: Test combined patterns**

Enable both `drift_enabled` and `charge_enabled` on Demon. Run game. Confirm Demon drifts AND charges simultaneously.

- [ ] **Step 7: Test ball bounce off moving blocks**

Confirm ball bounces correctly off all moving blocks using the axis-based reflection system. The `get_block_size()` method is called at collision time with the block's current position, so moving blocks should work.

- [ ] **Step 8: Commit**

```bash
git add data/monsters/*.tres
git commit -m "feat: monster movement patterns — complete"
```
