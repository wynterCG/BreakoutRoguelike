# Circular Paddle Redesign

## Goal

Replace the arc paddle with a circular paddle that moves freely within a bottom strip (Y: 600-680, X: 30-1250). Ball bounce direction is based on contact angle from paddle center. Starts at radius 30px, scales with Wider Paddle upgrade.

## Paddle Shape

- **Shape:** CircleShape2D, base radius 30px
- **Visual:** Polygon2D circle (16-segment approximation), filled blue (0.2, 0.6, 1.0)
- **No more arc:** Remove CollisionPolygon2D, Polygon2D arc generation, ARC_WIDTH/ARC_HEIGHT/ARC_SEGMENTS constants

## Movement

### Region
- X: 30 to 1250 (inside walls)
- Y: 600 to 680 (bottom strip, above HP bar)
- Free 2D movement within this region

### Mouse/Touch
- Paddle follows cursor position, clamped to the region
- Uses velocity-based `move_and_slide()` toward target (same approach as current touch mode)
- Max speed clamped to MAX_TOUCH_SPEED (3000)

### Keyboard
- WASD or arrow keys for 2D movement
- `move_left`/`move_right` for X, add `move_up`/`move_down` for Y
- Same MOVE_SPEED (600) on both axes
- Auto-switches between touch and keyboard (existing behavior preserved)

## Ball Bounce

When the ball hits the circular paddle:
- Calculate direction from paddle center to ball position: `dir = (ball_pos - paddle_pos).normalized()`
- Ball bounces in that direction
- This naturally handles all angles — hitting the top bounces upward, hitting the side bounces sideways
- No more arc-angle calculation or t-mapping
- Minimum upward component enforced: if `dir.y > -0.2`, clamp to ensure ball goes mostly upward (prevent horizontal trapping)

### Below paddle
If ball is below the paddle (diff.y > 0), force direction downward (away from paddle) — same as current behavior.

## Visual

- 16-point circle polygon (same technique as ball visual)
- Blue fill (0.2, 0.6, 1.0)
- Radius scales with upgrade
- No outline needed (clean look)

## Upgrade Interaction

"Wider Paddle" upgrade increases radius:
- `get_effective_paddle_radius(base)` = `base * (1.0 + paddle_width_bonus)`
- Base: 30px
- Each stack (+15%): 30 → 34.5 → 39 → 43.5 ...
- `apply_width_upgrade()` regenerates circle polygon and collision shape with new radius

## HurtZone

- Area2D with CircleShape2D matching paddle radius
- Updates when `apply_width_upgrade()` is called
- Same collision layer/mask (layer 0, mask 16 for projectiles)

## Collision Setup

- `collision_layer = 1` (Paddle) — unchanged
- `collision_mask = 0` — unchanged
- Ball detects paddle via ball's mask (includes layer 1)

## Input Actions

Add two new input actions in project settings:
- `move_up`: W key / Up arrow
- `move_down`: S key / Down arrow

## Constants Change

Remove:
- `ARC_WIDTH`, `ARC_HEIGHT`, `ARC_SEGMENTS`
- `_generate_arc_points_with_width()`

Add:
- `BASE_RADIUS: float = 30.0`
- `PADDLE_MIN_Y: float = 600.0`
- `PADDLE_MAX_Y: float = 680.0`

Keep:
- `MOVE_SPEED`, `SCREEN_MARGIN`, `MAX_TOUCH_SPEED`

## UpgradeManager Changes

Rename getter:
- `get_effective_paddle_width()` → `get_effective_paddle_radius()` (or keep name, just use for radius)
- Actually: keep `get_effective_paddle_width()` as-is since it's just `base * (1 + bonus)`. The caller passes radius instead of width. No functional change needed in UpgradeManager.

## Ball.gd Changes

Update `_handle_paddle_bounce()`:
- Remove arc-angle calculation (t-mapping to -70/+70 degrees)
- Replace with: `_direction = (global_position - paddle.global_position).normalized()`
- Enforce minimum upward component
- Remove `POST_BOUNCE_CLEARANCE_Y` repositioning — circle doesn't need it
- Place ball at paddle surface: `global_position = paddle.global_position + _direction * (radius + ball_radius + 2)`

## Files Changed

| File | Change |
|------|--------|
| `scripts/paddle.gd` | Circle shape, 2D movement, new constants |
| `scenes/entities/paddle.tscn` | CollisionShape2D (circle) replaces CollisionPolygon2D |
| `scripts/ball.gd` | Simplified paddle bounce (contact angle) |
| `project.godot` | Add move_up/move_down input actions |

## Verification

1. Run game — circular paddle visible at bottom
2. Mouse movement — paddle follows cursor within strip (Y 600-680)
3. Keyboard — WASD moves paddle in 2D within strip
4. Ball launch — ball launches from paddle center
5. Ball bounce — bounces away from paddle center on contact
6. Ball below paddle — bounces downward (away)
7. Wider Paddle upgrade — circle grows visibly
8. Projectile hits paddle — damages player
9. HurtZone matches circle size after upgrade
