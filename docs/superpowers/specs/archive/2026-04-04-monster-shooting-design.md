# Monster Shooting System Design

## Goal

Monsters fire projectiles at the player. Projectiles damage the player if they hit the paddle. The player must dodge projectiles while still bouncing the ball — creating tension between catching and dodging. Shooting patterns are configurable per monster type, combinable like movement patterns.

## MonsterData Properties

Add to `monster_data.gd` under a new `@export_group("Shooting")`:

```
shoot_straight_enabled: bool = false
shoot_straight_speed: float = 150.0
shoot_straight_interval: float = 3.0
shoot_straight_damage: int = 5

shoot_aimed_enabled: bool = false
shoot_aimed_speed: float = 120.0
shoot_aimed_interval: float = 4.0
shoot_aimed_damage: int = 5

shoot_aimed_enabled: bool = false
shoot_aimed_speed: float = 120.0
shoot_aimed_interval: float = 4.0
shoot_aimed_damage: int = 5

shoot_spread_enabled: bool = false
shoot_spread_speed: float = 130.0
shoot_spread_interval: float = 5.0
shoot_spread_damage: int = 3
shoot_spread_count: int = 3

shoot_burst_enabled: bool = false
shoot_burst_speed: float = 140.0
shoot_burst_interval: float = 4.0
shoot_burst_damage: int = 3
shoot_burst_count: int = 3
```

All editable in the Godot inspector when clicking a monster in the monster editor.

## Shooting Patterns

### Straight Down
Single projectile fired straight down (direction = Vector2(0, 1)). Predictable, easy to dodge. Good for weaker shooters.

### Aimed at Paddle
Projectile aimed at the paddle's current X position at the moment of firing. Direction calculated as `(paddle_pos - block_pos).normalized()`. Forces the player to move after the shot. Good for support enemies.

### Spread Shot
Multiple projectiles (default 3) fired in a fan pattern. Center projectile goes straight down, others spread at ±15° and ±30° angles. Harder to dodge. Good for elites.

### Burst
Rapid succession of projectiles (default 3) fired straight down with 0.15s delay between each. Creates a wall of projectiles. Can combine with aimed — burst of aimed shots.

### Combining Patterns
Multiple patterns can be enabled simultaneously. Each pattern runs on its own independent timer. A demon with straight + spread fires both on separate intervals.

## Projectile

### Scene: `res://scenes/entities/projectile.tscn`
- **Area2D** root node
- **CollisionShape2D** — small circle (radius 5)
- **Visual** — Polygon2D small circle, red/orange color
- `collision_layer = 16` (new Projectile layer)
- `collision_mask = 0` (projectile doesn't detect anything — paddle detects it)

### Script: `res://scripts/projectile.gd`
- Properties: `direction: Vector2`, `speed: float`, `damage: int`
- `_physics_process`: move by `direction * speed * delta`
- Destroy when `global_position.y > 680` (before the ouch zone / HP bar area)
- Destroy when off-screen on any side (x < -20 or x > 1300 or y < -20)

## ShootingComponent

### Script: `res://scripts/components/shooting_component.gd`
- Attached to Block as a child node
- `initialize(data: MonsterData, get_paddle_pos: Callable)` — stores monster config, callable to get paddle position
- Manages independent timers per enabled pattern
- Each timer starts with a random offset (like movement) to prevent synchronized volleys
- On timer fire: spawns projectile(s) via signal or direct instantiation
- Signal: `projectile_spawned(projectile: Area2D)` — main.gd connects to add projectile to scene tree

## Paddle Changes

### HurtZone
- Add `Area2D` child to paddle scene called `HurtZone`
- `collision_layer = 0`
- `collision_mask = 16` (detects Projectile layer)
- Shape matches paddle collision shape
- On `area_entered` → emit `hit_by_projectile(damage: int)` signal

### Paddle Script
- Add signal: `hit_by_projectile(damage: int)`
- Connect HurtZone's `area_entered` to handler that reads projectile damage and emits signal
- Projectile is destroyed on contact (`queue_free()`)

## Main.gd Wiring

- Connect `paddle.hit_by_projectile` → `_on_paddle_hit_by_projectile(damage)`
- Handler applies damage reduction and deals damage to player HP (same formula as back wall hits)
- When level ends: destroy all projectiles (same pattern as split ball cleanup)

## Block.gd Integration

- Add `@onready var _shooting: ShootingComponent = $ShootingComponent`
- In `_ready()`, initialize shooting with monster data
- Pass a callable for paddle position: `func() -> Vector2: return _paddle_ref.global_position`
- Block needs a reference to the paddle — passed during spawn from main.gd (`block.set_paddle(paddle)`)

## Projectile Cleanup

- On level end (`_start_upgrade_selection` and `_start_next_level`): destroy all projectiles
- Add projectiles to a group `"projectiles"` for easy cleanup: `get_tree().get_nodes_in_group("projectiles").map(func(n): n.queue_free())`

## Collision Layers Summary

| Layer | Bit | Used by |
|-------|-----|---------|
| 1 (Paddle) | 1 | Paddle |
| 2 (Ball) | 2 | Ball |
| 3 (Walls) | 4 | Walls |
| 4 (Blocks) | 8 | Blocks |
| 5 (Projectile) | 16 | Monster projectiles |

## Files Changed

| File | Change |
|------|--------|
| `scripts/data/monster_data.gd` | Add shooting exports |
| `scripts/projectile.gd` | New — projectile movement + self-destruct |
| `scenes/entities/projectile.tscn` | New — Area2D scene |
| `scripts/components/shooting_component.gd` | New — shooting pattern logic |
| `scripts/block.gd` | Add ShootingComponent integration |
| `scenes/entities/block.tscn` | Add ShootingComponent node |
| `scripts/paddle.gd` | Add hit_by_projectile signal |
| `scenes/entities/paddle.tscn` | Add HurtZone Area2D |
| `scripts/main.gd` | Wire projectile damage, cleanup on level end |

## Verification

1. Enable `shoot_straight` on Imp — fires straight down periodically
2. Enable `shoot_aimed` on Shaman — projectile aims at paddle position
3. Enable `shoot_spread` on Demon — 3 projectiles in a fan
4. Enable `shoot_burst` on Dragon — rapid 3-shot burst
5. Enable straight + spread on Demon — both fire independently
6. Projectile hits paddle → player takes damage
7. Projectile misses paddle → destroyed before ouch zone (y > 680)
8. Level ends → all projectiles destroyed
9. Monsters with no shooting enabled → no overhead (no timers)
