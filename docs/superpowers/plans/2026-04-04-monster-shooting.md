# Monster Shooting + Block Avoidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Monsters fire projectiles that damage the player on paddle contact. Shooting patterns (straight, aimed, spread, burst) are combinable per monster. Also adds soft avoidance so moving blocks don't overlap each other.

**Architecture:** ShootingComponent on Block manages pattern timers and spawns projectiles. Projectile is an Area2D that moves and self-destructs. Paddle gets a HurtZone Area2D to detect projectile hits. MovementComponent gets neighbor-based soft avoidance (rebuild neighbor list every 0.3s, check only nearby blocks per frame).

**Tech Stack:** Godot 4.6, GDScript

---

### Task 1: Add shooting properties to MonsterData

**Files:**
- Modify: `res://scripts/data/monster_data.gd`

- [ ] **Step 1: Add shooting exports**

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
```

- [ ] **Step 2: Commit**

```bash
git add scripts/data/monster_data.gd
git commit -m "feat: add shooting properties to MonsterData"
```

---

### Task 2: Create Projectile scene and script

**Files:**
- Create: `res://scripts/projectile.gd`
- Create: `res://scenes/entities/projectile.tscn`

- [ ] **Step 1: Write projectile script**

```gdscript
extends Area2D
class_name Projectile

const DESTROY_Y: float = 680.0
const DESTROY_MARGIN: float = 20.0

var direction: Vector2 = Vector2.DOWN
var speed: float = 150.0
var damage: int = 5


func _ready() -> void:
	add_to_group("projectiles")


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	# Destroy before ouch zone or off-screen
	if global_position.y > DESTROY_Y:
		queue_free()
	elif global_position.x < -DESTROY_MARGIN or global_position.x > 1300.0:
		queue_free()
	elif global_position.y < -DESTROY_MARGIN:
		queue_free()


func setup(dir: Vector2, spd: float, dmg: int) -> void:
	direction = dir.normalized()
	speed = spd
	damage = dmg
```

- [ ] **Step 2: Create projectile scene**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/projectile.gd" id="1"]

[node name="Projectile" type="Area2D"]
collision_layer = 16
collision_mask = 0
script = ExtResource("1")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
color = Color(1, 0.3, 0.2, 1)
polygon = PackedVector2Array(-5, 0, -3.5, -3.5, 0, -5, 3.5, -3.5, 5, 0, 3.5, 3.5, 0, 5, -3.5, 3.5)
```

Note: The CollisionShape2D (circle radius 5) is set up in the script's `_ready` or can be added in the scene. For simplicity, set it in the scene file. However since .tscn format for shapes is verbose, the projectile script should create the shape in `_ready`:

Add to projectile.gd `_ready()`:

```gdscript
func _ready() -> void:
	add_to_group("projectiles")
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 5.0
	$CollisionShape2D.shape = shape
```

- [ ] **Step 3: Commit**

```bash
git add scripts/projectile.gd scenes/entities/projectile.tscn
git commit -m "feat: add Projectile scene with movement and self-destruct"
```

---

### Task 3: Create ShootingComponent

**Files:**
- Create: `res://scripts/components/shooting_component.gd`

- [ ] **Step 1: Write ShootingComponent**

```gdscript
extends Node
class_name ShootingComponent

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/entities/projectile.tscn")
const BURST_DELAY: float = 0.15
const SPREAD_ANGLE: float = 15.0

signal projectile_spawned(projectile: Projectile)

var _monster_data: MonsterData = null
var _get_paddle_pos: Callable
var _has_shooting: bool = false

# Independent timers per pattern
var _straight_timer: float = 0.0
var _aimed_timer: float = 0.0
var _spread_timer: float = 0.0
var _burst_timer: float = 0.0
var _burst_remaining: int = 0
var _burst_delay_timer: float = 0.0


func initialize(data: MonsterData, paddle_pos_callable: Callable) -> void:
	_monster_data = data
	_get_paddle_pos = paddle_pos_callable
	_has_shooting = data.shoot_straight_enabled or data.shoot_aimed_enabled \
		or data.shoot_spread_enabled or data.shoot_burst_enabled

	if not _has_shooting:
		set_physics_process(false)
		return

	# Randomize initial timers to prevent synchronized volleys
	if data.shoot_straight_enabled:
		_straight_timer = data.shoot_straight_interval * randf()
	if data.shoot_aimed_enabled:
		_aimed_timer = data.shoot_aimed_interval * randf()
	if data.shoot_spread_enabled:
		_spread_timer = data.shoot_spread_interval * randf()
	if data.shoot_burst_enabled:
		_burst_timer = data.shoot_burst_interval * randf()


func _physics_process(delta: float) -> void:
	if not _monster_data or not _has_shooting:
		return

	var spawn_pos: Vector2 = (get_parent() as Node2D).global_position

	# Handle burst in progress
	if _burst_remaining > 0:
		_burst_delay_timer -= delta
		if _burst_delay_timer <= 0.0:
			_burst_delay_timer = BURST_DELAY
			_burst_remaining -= 1
			_fire_projectile(spawn_pos, Vector2.DOWN, _monster_data.shoot_burst_speed, _monster_data.shoot_burst_damage)

	# Straight
	if _monster_data.shoot_straight_enabled:
		_straight_timer -= delta
		if _straight_timer <= 0.0:
			_straight_timer = _monster_data.shoot_straight_interval
			_fire_projectile(spawn_pos, Vector2.DOWN, _monster_data.shoot_straight_speed, _monster_data.shoot_straight_damage)

	# Aimed
	if _monster_data.shoot_aimed_enabled:
		_aimed_timer -= delta
		if _aimed_timer <= 0.0:
			_aimed_timer = _monster_data.shoot_aimed_interval
			var paddle_pos: Vector2 = _get_paddle_pos.call()
			var aim_dir: Vector2 = (paddle_pos - spawn_pos).normalized()
			_fire_projectile(spawn_pos, aim_dir, _monster_data.shoot_aimed_speed, _monster_data.shoot_aimed_damage)

	# Spread
	if _monster_data.shoot_spread_enabled:
		_spread_timer -= delta
		if _spread_timer <= 0.0:
			_spread_timer = _monster_data.shoot_spread_interval
			var count: int = _monster_data.shoot_spread_count
			var total_angle: float = SPREAD_ANGLE * float(count - 1)
			var start_angle: float = -total_angle / 2.0
			for i: int in range(count):
				var angle: float = deg_to_rad(start_angle + SPREAD_ANGLE * float(i))
				var dir: Vector2 = Vector2(sin(angle), cos(angle))
				_fire_projectile(spawn_pos, dir, _monster_data.shoot_spread_speed, _monster_data.shoot_spread_damage)

	# Burst (start new burst)
	if _monster_data.shoot_burst_enabled and _burst_remaining <= 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = _monster_data.shoot_burst_interval
			_burst_remaining = _monster_data.shoot_burst_count
			_burst_delay_timer = 0.0


func _fire_projectile(pos: Vector2, dir: Vector2, spd: float, dmg: int) -> void:
	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	proj.global_position = pos
	proj.setup(dir, spd, dmg)
	projectile_spawned.emit(proj)
```

- [ ] **Step 2: Commit**

```bash
git add scripts/components/shooting_component.gd
git commit -m "feat: add ShootingComponent with straight/aimed/spread/burst patterns"
```

---

### Task 4: Add soft avoidance to MovementComponent

**Files:**
- Modify: `res://scripts/components/movement_component.gd`

- [ ] **Step 1: Add avoidance logic**

Add these constants and variables at the top of the class (after existing constants):

```gdscript
const AVOIDANCE_RADIUS: float = 150.0
const AVOIDANCE_STRENGTH: float = 80.0
const AVOIDANCE_REBUILD_INTERVAL: float = 0.3
```

Add these variables after the charge state variables:

```gdscript
# Avoidance state
var _avoidance_timer: float = 0.0
var _nearby_blocks: Array[Node2D] = []
var _owner_block: Node2D = null
```

Update `initialize()` to store the owner block reference:

```gdscript
func initialize(data: MonsterData, spawn_pos: Vector2) -> void:
	_monster_data = data
	_spawn_position = spawn_pos
	_owner_block = get_parent() as Node2D

	# Randomize starting directions
	_drift_direction = 1.0 if randf() > 0.5 else -1.0
	var diag_x: float = 1.0 if randf() > 0.5 else -1.0
	var diag_y: float = 1.0 if randf() > 0.5 else -1.0
	_zigzag_direction = Vector2(diag_x, diag_y).normalized()
	_orbit_angle = randf() * TAU

	if data.charge_enabled:
		_charge_timer = data.charge_interval * randf()

	_avoidance_timer = AVOIDANCE_REBUILD_INTERVAL * randf()
```

Update `get_movement_velocity()` to include avoidance after combining pattern velocities, before clamping:

```gdscript
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

	# Soft avoidance
	combined += _calc_avoidance(current_pos, delta)

	# Clamp combined speed
	if combined.length() > MAX_COMBINED_SPEED:
		combined = combined.normalized() * MAX_COMBINED_SPEED

	return combined
```

Add the avoidance methods at the end of the file:

```gdscript
func _calc_avoidance(current_pos: Vector2, delta: float) -> Vector2:
	# Rebuild neighbor list periodically
	_avoidance_timer -= delta
	if _avoidance_timer <= 0.0:
		_avoidance_timer = AVOIDANCE_REBUILD_INTERVAL
		_rebuild_nearby_blocks(current_pos)

	# Push away from nearby blocks
	var repulsion: Vector2 = Vector2.ZERO
	for block: Node2D in _nearby_blocks:
		if not is_instance_valid(block):
			continue
		var diff: Vector2 = current_pos - block.global_position
		var dist: float = diff.length()
		if dist < 1.0:
			# Overlapping exactly — push in random direction
			repulsion += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * AVOIDANCE_STRENGTH
		elif dist < AVOIDANCE_RADIUS:
			# Closer = stronger push
			var strength: float = AVOIDANCE_STRENGTH * (1.0 - dist / AVOIDANCE_RADIUS)
			repulsion += diff.normalized() * strength

	return repulsion


func _rebuild_nearby_blocks(current_pos: Vector2) -> void:
	_nearby_blocks.clear()
	if not _owner_block or not is_instance_valid(_owner_block):
		return
	var all_blocks: Array[Node] = _owner_block.get_tree().get_nodes_in_group("blocks")
	for block_node: Node in all_blocks:
		if block_node == _owner_block:
			continue
		if block_node is Node2D:
			var dist: float = current_pos.distance_to((block_node as Node2D).global_position)
			if dist < AVOIDANCE_RADIUS:
				_nearby_blocks.append(block_node as Node2D)
```

- [ ] **Step 2: Commit**

```bash
git add scripts/components/movement_component.gd
git commit -m "feat: add soft avoidance to MovementComponent"
```

---

### Task 5: Add HurtZone to Paddle

**Files:**
- Modify: `res://scripts/paddle.gd`
- Modify: `res://scenes/entities/paddle.tscn`

- [ ] **Step 1: Update paddle.tscn**

Add a HurtZone Area2D child to the paddle scene:

```
[gd_scene load_steps=2 format=3 uid="uid://paddle001"]

[ext_resource type="Script" path="res://scripts/paddle.gd" id="1_paddle"]

[node name="Paddle" type="CharacterBody2D"]
collision_layer = 1
collision_mask = 0
script = ExtResource("1_paddle")

[node name="CollisionPolygon2D" type="CollisionPolygon2D" parent="."]

[node name="Polygon2D" type="Polygon2D" parent="."]

[node name="HurtZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 16

[node name="HurtShape" type="CollisionShape2D" parent="HurtZone"]
```

- [ ] **Step 2: Update paddle.gd**

Add signal and HurtZone wiring. Add after the existing `@onready` vars:

```gdscript
signal hit_by_projectile(damage: int)

@onready var _hurt_zone: Area2D = $HurtZone
@onready var _hurt_shape: CollisionShape2D = $HurtZone/HurtShape
```

In `_ready()`, after `apply_width_upgrade()`, add:

```gdscript
	_hurt_zone.area_entered.connect(_on_hurt_zone_area_entered)
```

Add `apply_width_upgrade()` update to also resize the hurt shape. At the end of `apply_width_upgrade()`:

```gdscript
	# Update hurt zone to match paddle shape
	var hurt_rect: RectangleShape2D = RectangleShape2D.new()
	hurt_rect.size = Vector2(effective_width, ARC_HEIGHT + 10.0)
	_hurt_shape.shape = hurt_rect
```

Add the handler function:

```gdscript
func _on_hurt_zone_area_entered(area: Area2D) -> void:
	if area is Projectile:
		var proj: Projectile = area as Projectile
		hit_by_projectile.emit(proj.damage)
		proj.queue_free()
```

- [ ] **Step 3: Commit**

```bash
git add scripts/paddle.gd scenes/entities/paddle.tscn
git commit -m "feat: add HurtZone to paddle for projectile detection"
```

---

### Task 6: Integrate ShootingComponent into Block

**Files:**
- Modify: `res://scripts/block.gd`
- Modify: `res://scenes/entities/block.tscn`

- [ ] **Step 1: Update block.tscn**

Add ShootingComponent node and ext_resource:

```
[gd_scene format=3 uid="uid://block001"]

[ext_resource type="Script" uid="uid://swv2pbltrx6o" path="res://scripts/block.gd" id="1_block"]
[ext_resource type="Script" uid="uid://b841g0ckswm8v" path="res://scripts/components/health_component.gd" id="2_health"]
[ext_resource type="Script" uid="uid://wwhb8c2vy3j3" path="res://scripts/components/movement_component.gd" id="3_movement"]
[ext_resource type="Script" path="res://scripts/components/shooting_component.gd" id="4_shooting"]

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

[node name="MovementComponent" type="Node" parent="." unique_id=2045809003]
script = ExtResource("3_movement")

[node name="ShootingComponent" type="Node" parent="."]
script = ExtResource("4_shooting")
```

- [ ] **Step 2: Update block.gd**

Add `@onready` reference and signal. After the `_movement` onready:

```gdscript
@onready var _shooting: ShootingComponent = $ShootingComponent
```

Add a signal for projectile spawning:

```gdscript
signal projectile_spawned(projectile: Projectile)
```

Add a paddle reference variable:

```gdscript
var _paddle_ref: Paddle = null
```

Add a setter function:

```gdscript
func set_paddle(paddle: Paddle) -> void:
	_paddle_ref = paddle
```

In `_ready()`, after the movement initialization block, add shooting initialization:

```gdscript
	# Initialize shooting
	if monster_data and _paddle_ref:
		_shooting.initialize(monster_data, func() -> Vector2: return _paddle_ref.global_position)
		_shooting.projectile_spawned.connect(func(proj: Projectile) -> void: projectile_spawned.emit(proj))
```

- [ ] **Step 3: Commit**

```bash
git add scripts/block.gd scenes/entities/block.tscn
git commit -m "feat: integrate ShootingComponent into Block"
```

---

### Task 7: Wire everything in main.gd

**Files:**
- Modify: `res://scripts/main.gd`

- [ ] **Step 1: Connect paddle projectile damage**

In `_ready()`, after `_upgrade_selection.all_picks_done.connect(_on_all_picks_done)`, add:

```gdscript
	_paddle.hit_by_projectile.connect(_on_paddle_hit_by_projectile)
```

- [ ] **Step 2: Pass paddle to blocks during spawn**

In `_spawn_from_formation()`, after `block.size_scale = cell.size_scale` and before `block.max_hp`, add:

```gdscript
		block.set_paddle(_paddle)
```

Do the same in `_spawn_fallback_grid()` if it exists.

- [ ] **Step 3: Connect block projectile_spawned signal**

In `_spawn_from_formation()`, after `block.destroyed.connect(_on_block_destroyed)`, add:

```gdscript
		block.projectile_spawned.connect(_on_projectile_spawned)
```

- [ ] **Step 4: Add handler functions**

```gdscript
func _on_paddle_hit_by_projectile(damage: int) -> void:
	if _game_over:
		return
	var reduced: int = maxi(int(float(damage) * (1.0 - UpgradeManager.damage_reduction)), 1)
	_player_health.take_damage(reduced)


func _on_projectile_spawned(projectile: Projectile) -> void:
	add_child(projectile)
```

- [ ] **Step 5: Add projectile cleanup**

In `_start_upgrade_selection()`, after the split ball cleanup loop, add:

```gdscript
	# Destroy projectiles
	for proj: Node in get_tree().get_nodes_in_group("projectiles"):
		proj.queue_free()
```

In `_start_next_level()`, after the split ball cleanup loop, add the same:

```gdscript
	# Destroy projectiles
	for proj: Node in get_tree().get_nodes_in_group("projectiles"):
		proj.queue_free()
```

- [ ] **Step 6: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: wire shooting system in main.gd"
```

---

### Task 8: End-to-end verification

- [ ] **Step 1: Test no-shooting baseline**

Run game with no shooting enabled on any monster. Everything should work identically to before.

- [ ] **Step 2: Test straight shooting**

Open monster editor, enable `shoot_straight` on Imp (speed 150, interval 3, damage 5). Run game. Confirm Imps fire straight down periodically. Projectiles vanish before the HP bar.

- [ ] **Step 3: Test aimed shooting**

Enable `shoot_aimed` on Shaman. Run game. Confirm projectiles aim at paddle position.

- [ ] **Step 4: Test spread shooting**

Enable `shoot_spread` on Demon (count 3). Confirm 3 projectiles fire in a fan.

- [ ] **Step 5: Test burst shooting**

Enable `shoot_burst` on Dragon (count 3). Confirm rapid 3-shot burst.

- [ ] **Step 6: Test projectile hitting paddle**

Let a projectile hit the paddle. Confirm player HP drops. Confirm damage reduction applies.

- [ ] **Step 7: Test combined patterns**

Enable straight + spread on Demon. Confirm both fire independently on separate timers.

- [ ] **Step 8: Test soft avoidance**

Enable drift on two adjacent blocks. Confirm they push apart and don't overlap.

- [ ] **Step 9: Test projectile cleanup**

Destroy all blocks while projectiles are in flight. Confirm projectiles are destroyed on level transition.

- [ ] **Step 10: Commit**

```bash
git add data/monsters/*.tres
git commit -m "feat: monster shooting + block avoidance — complete"
```
