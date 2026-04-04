# Circular Paddle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace arc paddle with circular paddle that moves freely in a bottom strip (Y 600-680). Ball bounce uses contact angle from paddle center. Radius starts at 30px, scales with Wider Paddle upgrade.

**Architecture:** Paddle uses CircleShape2D instead of CollisionPolygon2D. Movement is 2D within a clamped region. Ball bounce simplified to direction-from-center. Input adds move_up/move_down actions.

**Tech Stack:** Godot 4.6, GDScript

---

### Task 1: Add move_up/move_down input actions

**Files:**
- Modify: `project.godot`

- [ ] **Step 1: Add input actions**

Add after the `move_right` block in `project.godot`:

```
move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194320,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":119,"location":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"location":0,"echo":false,"script":null)
]
}
```

Physical keycodes: 4194320=Up Arrow, 4194322=Down Arrow, 87=W, 83=S.

- [ ] **Step 2: Commit**

```bash
git add project.godot
git commit -m "feat: add move_up/move_down input actions"
```

---

### Task 2: Rewrite paddle.gd for circular shape and 2D movement

**Files:**
- Modify: `res://scripts/paddle.gd`

- [ ] **Step 1: Rewrite paddle.gd**

```gdscript
extends CharacterBody2D
class_name Paddle

const MOVE_SPEED: float = 600.0
const BASE_RADIUS: float = 30.0
const CIRCLE_SEGMENTS: int = 16
const SCREEN_MARGIN: float = 10.0
const MAX_TOUCH_SPEED: float = 3000.0
const PADDLE_MIN_Y: float = 600.0
const PADDLE_MAX_Y: float = 680.0

signal hit_by_projectile(damage: int)

var _screen_width: float = 0.0
var _use_touch: bool = false
var _touch_target: Vector2 = Vector2(640.0, 650.0)

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: Polygon2D = $Polygon2D
@onready var _hurt_zone: Area2D = $HurtZone
@onready var _hurt_shape: CollisionShape2D = $HurtZone/HurtShape


func _ready() -> void:
	_screen_width = get_viewport_rect().size.x
	_hurt_zone.area_entered.connect(_on_hurt_zone_area_entered)
	apply_width_upgrade()


func apply_width_upgrade() -> void:
	var effective_radius: float = UpgradeManager.get_effective_paddle_width(BASE_RADIUS)

	# Collision shape
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = effective_radius
	_collision.shape = circle

	# Visual
	_visual.polygon = _generate_circle_points(effective_radius)
	_visual.color = Color(0.2, 0.6, 1.0)

	# Hurt zone matches paddle
	var hurt_circle: CircleShape2D = CircleShape2D.new()
	hurt_circle.radius = effective_radius
	_hurt_shape.shape = hurt_circle


func get_radius() -> float:
	return UpgradeManager.get_effective_paddle_width(BASE_RADIUS)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_use_touch = true
		_touch_target = event.position
	elif event is InputEventMouseButton and event.pressed:
		_use_touch = true
		_touch_target = event.position
	elif event is InputEventScreenTouch and event.pressed:
		_use_touch = true
		_touch_target = event.position
	elif event is InputEventScreenDrag:
		_use_touch = true
		_touch_target = event.position
	elif event is InputEventKey:
		_use_touch = false


func _physics_process(_delta: float) -> void:
	var radius: float = get_radius()
	var min_x: float = SCREEN_MARGIN + radius
	var max_x: float = _screen_width - SCREEN_MARGIN - radius

	if _use_touch:
		var target: Vector2 = Vector2(
			clampf(_touch_target.x, min_x, max_x),
			clampf(_touch_target.y, PADDLE_MIN_Y, PADDLE_MAX_Y)
		)
		var diff: Vector2 = target - position
		velocity = diff / _delta_safe(_delta) 
		if velocity.length() > MAX_TOUCH_SPEED:
			velocity = velocity.normalized() * MAX_TOUCH_SPEED
	else:
		var dir_x: float = Input.get_axis("move_left", "move_right")
		var dir_y: float = Input.get_axis("move_up", "move_down")
		velocity = Vector2(dir_x, dir_y).normalized() * MOVE_SPEED

	move_and_slide()
	position.x = clampf(position.x, min_x, max_x)
	position.y = clampf(position.y, PADDLE_MIN_Y, PADDLE_MAX_Y)


func _delta_safe(delta: float) -> float:
	return delta if delta > 0.0001 else 0.016


func _generate_circle_points(radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(CIRCLE_SEGMENTS):
		var angle: float = TAU * float(i) / float(CIRCLE_SEGMENTS)
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	return points


func _on_hurt_zone_area_entered(area: Area2D) -> void:
	if area.is_in_group("projectiles"):
		hit_by_projectile.emit(area.damage)
		area.queue_free()
```

Note: The `_delta_safe` helper prevents division by zero on the first frame.

- [ ] **Step 2: Commit**

```bash
git add scripts/paddle.gd
git commit -m "feat: circular paddle with 2D movement in bottom strip"
```

---

### Task 3: Update paddle.tscn

**Files:**
- Modify: `res://scenes/entities/paddle.tscn`

- [ ] **Step 1: Replace scene — CollisionShape2D instead of CollisionPolygon2D**

```
[gd_scene load_steps=2 format=3 uid="uid://paddle001"]

[ext_resource type="Script" path="res://scripts/paddle.gd" id="1_paddle"]

[node name="Paddle" type="CharacterBody2D"]
collision_layer = 1
collision_mask = 0
script = ExtResource("1_paddle")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]

[node name="Polygon2D" type="Polygon2D" parent="."]

[node name="HurtZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 16

[node name="HurtShape" type="CollisionShape2D" parent="HurtZone"]
```

- [ ] **Step 2: Commit**

```bash
git add scenes/entities/paddle.tscn
git commit -m "feat: paddle scene uses CollisionShape2D for circle"
```

---

### Task 4: Update ball.gd paddle bounce

**Files:**
- Modify: `res://scripts/ball.gd`

- [ ] **Step 1: Simplify _handle_paddle_bounce**

Replace the entire `_handle_paddle_bounce` function:

```gdscript
func _handle_paddle_bounce(paddle: Paddle, _col: KinematicCollision2D) -> void:
	var diff: Vector2 = global_position - paddle.global_position

	if diff.y > 0.0:
		# Ball is below paddle — force it downward (away from paddle)
		_direction.y = absf(_direction.y)
		_direction = _direction.normalized()
		return

	# Ball hit from above/side — bounce away from paddle center
	_direction = diff.normalized()

	# Enforce minimum upward component to prevent horizontal trapping
	if _direction.y > -0.2:
		_direction.y = -0.2
		_direction = _direction.normalized()

	# Place ball at paddle surface to prevent re-collision
	var radius: float = paddle.get_radius()
	global_position = paddle.global_position + _direction * (radius + 12.0)
```

- [ ] **Step 2: Remove POST_BOUNCE_CLEARANCE_Y constant**

Remove this line from the constants at the top of ball.gd:

```
const POST_BOUNCE_CLEARANCE_Y: float = -12.0
```

- [ ] **Step 3: Update _follow_paddle for circle**

The ball follows the paddle when not launched. Update the offset to be above the circle:

```gdscript
func _follow_paddle() -> void:
	if _paddle:
		var radius: float = _paddle.get_radius()
		global_position = _paddle.global_position + Vector2(0.0, -(radius + 12.0))
```

Remove the old `PADDLE_FOLLOW_OFFSET_Y` constant.

- [ ] **Step 4: Remove old paddle constants**

Remove these two constants from ball.gd:

```
const PADDLE_FOLLOW_OFFSET_Y: float = -40.0
const POST_BOUNCE_CLEARANCE_Y: float = -12.0
```

- [ ] **Step 5: Commit**

```bash
git add scripts/ball.gd
git commit -m "feat: ball bounce uses contact angle from circular paddle center"
```

---

### Task 5: Update main.gd paddle position

**Files:**
- Modify: `res://scripts/main.gd`

- [ ] **Step 1: Update paddle starting position**

Change `PADDLE_Y` to match the center of the paddle strip:

```gdscript
const PADDLE_Y: float = 640.0
```

This puts the paddle in the middle of the 600-680 strip.

- [ ] **Step 2: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: update paddle starting position for circular paddle"
```

---

### Task 6: End-to-end verification

- [ ] **Step 1: Visual check** — Run game, confirm circular blue paddle visible at bottom
- [ ] **Step 2: Mouse movement** — Paddle follows cursor in 2D within strip (Y 600-680)
- [ ] **Step 3: Keyboard** — WASD/arrows move paddle in 2D within strip
- [ ] **Step 4: Ball launch** — Ball launches from above paddle center
- [ ] **Step 5: Ball bounce** — Ball bounces away from paddle center on contact
- [ ] **Step 6: Ball below paddle** — Bounces downward (away)
- [ ] **Step 7: Wider Paddle upgrade** — Circle grows visibly
- [ ] **Step 8: Projectile hit** — Projectile hitting paddle damages player
- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat: circular paddle — complete"
```
