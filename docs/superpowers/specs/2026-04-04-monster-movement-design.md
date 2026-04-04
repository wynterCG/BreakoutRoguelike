# Monster Movement Patterns Design

## Goal

Add movement to monsters so they're no longer static blocks. Each monster type defines which movement patterns it uses (none, drift, zigzag, orbit, charge) with individual speeds. Multiple patterns can combine — a Demon can drift AND charge simultaneously. All configurable per monster in the monster editor.

## Architecture

Block changes from `StaticBody2D` to `CharacterBody2D` to support movement. A new `MovementComponent` node attached to each block reads the monster's movement config and applies velocity each frame. Multiple patterns run simultaneously, their velocities summed.

## MonsterData Changes

Add these exported properties to `monster_data.gd`:

```
drift_enabled: bool = false
drift_speed: float = 30.0
zigzag_enabled: bool = false
zigzag_speed: float = 40.0
orbit_enabled: bool = false
orbit_speed: float = 50.0
orbit_radius: float = 30.0
charge_enabled: bool = false
charge_speed: float = 100.0
charge_interval: float = 3.0
```

All editable in the Godot inspector when clicking a monster in the monster editor dock (checkboxes + speed values).

## Movement Patterns

### None
No movement properties enabled. Block stays static at spawn position. Classic breakout behavior.

### Drift
Horizontal back-and-forth movement. The block moves left/right, reversing direction when hitting arena walls or reaching a max drift distance from spawn.

- Speed: `drift_speed` pixels/sec
- Direction reverses on wall collision or after drifting `±120px` from spawn X
- Smooth, predictable — good for walls of enemies

### Zigzag
Diagonal bounce movement within a bounding box around the spawn point.

- Speed: `zigzag_speed` pixels/sec
- Moves diagonally, bounces when hitting bounds (±80px from spawn on each axis)
- Direction starts random (one of 4 diagonals)
- Harder to aim at — good for support/back-line enemies

### Orbit
Circular movement around the spawn point.

- Speed: `orbit_speed` pixels/sec (angular speed)
- Radius: `orbit_radius` pixels from spawn center
- Block traces a circle, starting at a random angle
- Visually dynamic, creates rotating formations

### Charge
Periodically rushes toward the paddle's Y level, then returns to spawn.

- Idle at spawn for `charge_interval` seconds
- Then rush downward at `charge_speed` pixels/sec
- Stop at paddle Y - 60px (don't overlap paddle), hold for 0.5 seconds
- Return to spawn position at half speed
- Aggressive, threatening — good for elites

### Combining Patterns
When multiple patterns are enabled, their velocity contributions are summed each frame. Drift + Charge = the block drifts normally, then periodically charges downward while still drifting horizontally. The combined velocity is clamped to prevent excessive speed.

## Block.gd Changes

### Body Type
Change `extends StaticBody2D` to `extends CharacterBody2D`. This allows `move_and_slide()` for movement while keeping collision detection working.

### Collision Setup
- `collision_layer = 4` (Blocks) — unchanged
- `collision_mask = 0` — block doesn't detect collisions itself (ball detects blocks via ball's mask)
- The ball's `move_and_collide()` still detects CharacterBody2D blocks — no change needed to ball code

### Movement Integration
- Store `_spawn_position: Vector2` in `_ready()`
- Each frame, MovementComponent calculates velocity from enabled patterns
- Block calls `move_and_slide()` with combined velocity
- Position clamped to arena bounds (walls)

## MovementComponent

New script: `res://scripts/components/movement_component.gd`

Attached as a child node of Block. Reads monster_data movement properties. Calculates combined velocity from all enabled patterns.

Public interface:
- `initialize(monster_data: MonsterData, spawn_pos: Vector2) -> void`
- `get_movement_velocity() -> Vector2` — called each frame by block

Internal state per pattern:
- Drift: `_drift_direction: float` (1.0 or -1.0)
- Zigzag: `_zigzag_direction: Vector2` (diagonal unit vector)
- Orbit: `_orbit_angle: float` (current angle in radians)
- Charge: `_charge_state: enum` (IDLE, CHARGING, HOLDING, RETURNING), `_charge_timer: float`

## Arena Bounds

Movement is clamped within the playable arena:
- X: 20 to 1260 (inside left/right walls)
- Y: 20 to 680 (inside top wall, above paddle area)

Blocks that hit bounds reverse their relevant direction component (drift reverses X, zigzag bounces, etc.)

## Ball Bounce Interaction

The axis-based bounce system already reads the block's `global_position` and `get_block_size()` to determine which side was hit. Moving blocks don't change this — the ball calculates reflection based on where the block IS at the moment of collision, not where it started. No changes needed to ball.gd.

## Paddle Scene Change

`paddle.tscn` collision_mask is already 0, so the paddle won't be blocked by moving blocks.

## Block Scene Change

`block.tscn` needs to change from StaticBody2D to CharacterBody2D and add a MovementComponent child node.

## Files Changed

| File | Change |
|------|--------|
| `scripts/data/monster_data.gd` | Add drift/zigzag/orbit/charge properties |
| `scripts/block.gd` | Change to CharacterBody2D, add movement integration |
| `scenes/entities/block.tscn` | Change node type, add MovementComponent |
| `scripts/components/movement_component.gd` | New — pattern logic |
| `data/monsters/*.tres` | User assigns patterns via editor (no code change) |

## Verification

1. Create a Slime with no movement — stays static (classic behavior)
2. Enable drift on Goblin (speed 30) — drifts left/right, reverses at bounds
3. Enable zigzag on Imp (speed 40) — bounces diagonally within bounding box
4. Enable orbit on Shaman (speed 50, radius 30) — circles spawn point
5. Enable charge on Demon (speed 100, interval 3s) — rushes toward paddle periodically
6. Enable drift+charge on Demon — drifts AND charges simultaneously
7. Ball bounces correctly off all moving blocks
8. Blocks stay within arena bounds
9. Existing formations work — blocks with no movement enabled behave identically to before
