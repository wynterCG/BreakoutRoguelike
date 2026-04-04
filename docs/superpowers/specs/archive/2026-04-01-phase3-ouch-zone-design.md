# Phase 3: Ouch Zone + Player HP — Design Spec

## Context

Phase 2 is complete — the game has monster data resources, HP bar visuals on blocks, mouse/touch input, and clean bounce physics. Currently, missing a ball costs a "life" (3 total) and the ball resets to the paddle.

Phase 3 replaces this with the core mechanical twist: **balls never leave play**. An invisible back wall behind the paddle bounces balls back into the arena, but every bounce damages the player. This creates a risk/reward dynamic where more powerful balls clear enemies faster but hurt more on misses.

## Ball Damage Stat

The ball gets a `damage` property (default: 5) that unifies all ball-inflicted damage.

- **Ball hits monster**: monster takes `ball.damage` HP
- **Ball hits back wall**: player takes `ball.damage` HP
- Future upgrades (Phase 4) increase `damage` — more DPS but riskier misses

### Block refactor

Currently `Block.hit()` calls `_health.take_damage(1)` (hardcoded 1 damage). This changes to accept an amount parameter:

- `Block.hit(amount: int)` → `_health.take_damage(amount)`
- Ball passes `damage` to `Block.hit(damage)` on collision

`HealthComponent.take_damage()` already supports an `amount` parameter — no changes needed there.

## Back Wall (replaces BottomKillZone)

The current `BottomKillZone` Area2D at `(640, 730)` is replaced with two layered nodes:

### BackWall (StaticBody2D)
- Position: same as current kill zone `(640, 730)`
- Collision layer: 3 (Walls) — ball already collides with walls
- Collision mask: 2 (Ball)
- Shape: `RectangleShape2D` 1300x20 (same as top wall)
- Ball bounces off this physically via standard `.bounce()` reflection

### OuchZone (Area2D)
- Position: same, layered over the back wall
- Collision layer: 5 (KillZone) — reuse existing layer
- Collision mask: 2 (Ball)
- Shape: `RectangleShape2D` 1300x100 (tall, same as current kill zone)
- `body_entered` signal → deals `ball.damage` to player HP
- Ball is NOT reset to paddle — it bounces back and continues playing

## Player HP System

### HP Management
- `HealthComponent` node added as child of `Main`
- Max HP: 100, starts at 100
- Takes damage when ball enters OuchZone
- Game over when HP reaches 0

### HP Bar UI
- Big boss-style bar at the bottom of the screen
- Full viewport width (with small margins), below the paddle
- Visual structure:
  - Dark background rectangle (the "empty" bar)
  - Colored fill rectangle (red/crimson) that shrinks left as HP decreases
  - Text label showing "HP: 70 / 100"
- Implemented as UI nodes on the existing `CanvasLayer` (UI layer in main.tscn)

## What Gets Removed

- `_lives: int = 3` variable from main.gd
- `LivesLabel` from UI (replaced by HP bar)
- Ball reset-to-paddle on kill zone entry (ball stays in play)
- `reset_to_paddle()` on ball still exists but only used on game restart

## What Stays the Same

- Ball bounce physics (paddle direct-angle, walls/blocks `.bounce()`)
- Paddle movement (keyboard + mouse/touch)
- Block/monster data system
- Monster editor plugin
- Win condition (all blocks destroyed)

## Signal Flow

```
Ball enters OuchZone (Area2D)
    → main._on_ouch_zone_body_entered(ball)
        → _player_health.take_damage(ball.damage)
            → health_changed signal → update HP bar UI
            → died signal → _end_game("GAME OVER")
```

## Game Over Changes

- `_end_game("GAME OVER")` triggers when player HP reaches 0 (not when lives = 0)
- `_end_game("YOU WIN!")` unchanged — all blocks destroyed
- Restart (Space/tap) reloads scene — full reset

## Verification

1. Run game — HP bar visible at bottom showing "100 / 100"
2. Launch ball — ball bounces off blocks dealing 5 damage each
3. Ball passes paddle — bounces off back wall, player takes 5 damage, HP bar updates
4. Ball continues playing after back wall bounce — no reset
5. Let HP reach 0 — "GAME OVER" appears
6. Tap/Space to restart — full reset with 100 HP
7. Destroy all blocks — "YOU WIN!" still works
