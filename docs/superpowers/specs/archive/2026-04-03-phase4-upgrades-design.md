# Phase 4: Upgrade System — Design Spec

## Context

Phases 1–3 are complete: core breakout loop, monster data system, ouch zone with player HP. The game currently has one level — the player either clears all blocks or dies. Phase 4 adds the roguelike progression loop: after clearing a level, the player picks upgrades that modify ball, paddle, and survivability for subsequent levels.

## Upgrade Selection Flow

After the player destroys all blocks:
1. Game pauses, full-screen upgrade selection overlay appears
2. **Round 1**: show 3 random upgrades, player picks 1
3. **Round 2**: show 3 new random upgrades, player picks 1
4. **Round 3**: show 3 new random upgrades, player picks 1
5. Overlay closes, next level starts (fresh blocks, keep upgrades + remaining HP)

Upgrades can appear multiple times across rounds — stacking is allowed and encouraged. Picking "+2 Ball Damage" twice gives +4 total.

## Upgrade Data

Each upgrade is an `UpgradeData` Resource (`res://scripts/data/upgrade_data.gd`):

```
@export var upgrade_name: String
@export_multiline var description: String
@export var category: StringName  # "offense", "defense", "utility"
@export var effect_id: StringName  # code identifier, e.g. "ball_damage"
@export var value: float           # magnitude of the effect
```

Upgrade definitions stored as `.tres` files in `res://data/upgrades/`.

## UpgradeManager (Autoload)

Global singleton (`res://scripts/autoloads/upgrade_manager.gd`) that tracks accumulated upgrade stats. Persists across levels, reset on game restart.

### Tracked Stats

| Stat | Type | Default | Upgrade That Modifies It |
|---|---|---|---|
| `ball_damage_bonus` | int | 0 | Ball Damage + |
| `crit_chance` | float | 0.0 | Critical Hit |
| `piercing_count` | int | 0 | Piercing |
| `split_count` | int | 0 | Split Shot |
| `aoe_damage` | int | 0 | AoE Blast |
| `lifesteal_percent` | float | 0.0 | Lifesteal |
| `max_hp_bonus` | int | 0 | Max HP + |
| `damage_reduction` | float | 0.0 | Damage Reduction |
| `regen_rate` | float | 0.0 | Regen |
| `ball_speed_bonus` | float | 0.0 | Ball Speed + |
| `paddle_width_bonus` | float | 0.0 | Wider Paddle |
| `magnet_pull_strength` | float | 0.0 | Magnet Pull |

### Key Functions

- `apply_upgrade(upgrade: UpgradeData) -> void` — adds the upgrade's value to the matching stat
- `reset() -> void` — resets all stats to default (on new run)
- `get_effective_ball_damage(base: int) -> int` — returns base + bonus
- `get_effective_ball_speed(base: float) -> float` — returns base * (1 + bonus)
- `get_effective_paddle_width(base: float) -> float` — returns base * (1 + bonus)

## The 12 Upgrades

### Offense

| # | Name | effect_id | value | Effect |
|---|---|---|---|---|
| 1 | Ball Damage + | `ball_damage` | 2.0 | Ball's damage increases by 2 (applies to monsters AND player self-damage) |
| 2 | Critical Hit | `crit_chance` | 0.10 | 10% chance to deal 2x damage to monsters only (crits don't apply to back wall) |
| 3 | Piercing | `piercing` | 1.0 | Ball passes through 1 block per stack instead of bouncing. Continues in same direction. |
| 4 | Split Shot | `split_shot` | 1.0 | On block hit, spawn 1 temporary extra ball per stack. Extra balls despawn after 5 seconds. |
| 5 | AoE Blast | `aoe_damage` | 3.0 | On block hit, deal 3 damage to all blocks within 80px radius |

### Defense

| # | Name | effect_id | value | Effect |
|---|---|---|---|---|
| 6 | Lifesteal | `lifesteal` | 0.05 | Heal 5% of damage dealt to monsters |
| 7 | Max HP + | `max_hp` | 10.0 | +10 max HP and immediately heal 10 |
| 8 | Damage Reduction | `damage_reduction` | 0.10 | Reduce back wall self-damage by 10%. Caps at 50%. |
| 9 | Regen | `regen` | 1.0 | Heal 1 HP per second passively |

### Utility

| # | Name | effect_id | value | Effect |
|---|---|---|---|---|
| 10 | Ball Speed + | `ball_speed` | 0.10 | +10% ball speed |
| 11 | Wider Paddle | `paddle_width` | 0.15 | +15% paddle width |
| 12 | Magnet Pull | `magnet_pull` | 30.0 | Ball curves toward paddle center by 30 px/s when below paddle Y |

## Effect Implementation

### Simple stat effects (Ball Damage, Ball Speed, Wider Paddle, Max HP)
Read from UpgradeManager when initializing or each frame. Ball reads `get_effective_ball_damage()`, paddle reads `get_effective_paddle_width()` in `_ready()` at level start.

### Critical Hit
In `ball._handle_collision()` — when hitting a block, roll `randf() < UpgradeManager.crit_chance`. If crit, pass `damage * 2` to `hit()`. Crits do NOT apply on back wall hits.

### Piercing
In `ball._handle_collision()` — when hitting a block, if `piercing_count > 0`, don't bounce. Instead continue in the same direction and decrement a per-bounce counter. Counter resets each frame.

### Split Shot
In `ball._handle_collision()` — when hitting a block, spawn temporary extra balls at the collision point with random directions. Extra balls have a 5-second timer and despawn.

### AoE Blast
In `ball._handle_collision()` — when hitting a block, find all blocks within 80px radius and call `hit(aoe_damage)` on each.

### Lifesteal
In `ball._handle_collision()` — after dealing damage to a block, heal player by `damage_dealt * lifesteal_percent`.

### Damage Reduction
In `main._on_ball_hit_back_wall()` — multiply damage by `(1.0 - damage_reduction)` before applying to player health.

### Regen
In `main._physics_process()` — heal `regen_rate * delta` HP per frame (accumulate fractional HP).

### Magnet Pull
In `ball._physics_process()` — when ball is below paddle Y and launched, apply a horizontal force toward paddle center proportional to `magnet_pull_strength`.

## Selection UI

### Scene: `res://scenes/ui/upgrade_selection.tscn`

- `CanvasLayer` with `process_mode = ALWAYS` (works while paused)
- Semi-transparent dark background overlay
- Title label: "Choose an Upgrade" (round X/3)
- 3 `UpgradeCard` panels side-by-side:
  - Category color bar at top (red=offense, green=defense, blue=utility)
  - Upgrade name (bold)
  - Description text
  - Clickable — emits signal on selection
- On pick: card highlights, brief delay, then next round or close

### Signal Flow

```
All blocks destroyed
  → main.gd: don't call _end_game("YOU WIN!")
  → instead: show upgrade selection overlay, pause game
  → player picks 3 upgrades
  → upgrade_selection emits "all_picks_done" signal
  → main.gd: unpause, increment level, respawn blocks with scaled HP
```

## Level Progression

- After upgrade selection, `_level += 1`
- Blocks respawn with the same MonsterData but HP scaled: `base_hp * (1 + level * 0.2)`
- Player keeps current HP + upgrades
- Ball resets to paddle

## What Changes in Existing Code

| File | Change |
|---|---|
| `ball.gd` | Read damage/speed from UpgradeManager. Implement crit, piercing, split, AoE, lifesteal, magnet. |
| `paddle.gd` | Read width from UpgradeManager at level start. |
| `main.gd` | Level progression, upgrade selection flow, damage reduction, regen. Remove "YOU WIN!" end game. |
| `block.gd` | Accept scaled HP on respawn. |
| `health_component.gd` | Support max_hp changes mid-game. |

## What's New

| File | Purpose |
|---|---|
| `res://scripts/data/upgrade_data.gd` | UpgradeData Resource class |
| `res://scripts/autoloads/upgrade_manager.gd` | Global upgrade state singleton |
| `res://data/upgrades/*.tres` | 12 upgrade definition files |
| `res://scenes/ui/upgrade_selection.tscn` | Upgrade pick overlay scene |
| `res://scripts/ui/upgrade_selection.gd` | Overlay logic |
| `res://scripts/ui/upgrade_card.gd` | Individual card logic |
| `res://scenes/ui/upgrade_card.tscn` | Card scene |

## Verification

1. Clear all blocks → upgrade selection appears (game paused)
2. Pick 3 upgrades across 3 rounds
3. Next level starts with fresh blocks (scaled HP), player keeps HP + upgrades
4. Verify each upgrade works:
   - Ball Damage+: blocks die in fewer hits, back wall hurts more
   - Crit: occasional 2x damage numbers on blocks
   - Piercing: ball passes through blocks
   - Split: extra balls spawn on hit, despawn after 5s
   - AoE: nearby blocks take damage on hit
   - Lifesteal: HP recovers when hitting blocks
   - Max HP: HP bar extends, immediate heal
   - Damage Reduction: back wall hits hurt less
   - Regen: HP slowly recovers over time
   - Ball Speed: ball moves faster
   - Wider Paddle: paddle visually wider
   - Magnet: ball curves toward paddle when below it
5. Stack an upgrade 3x — verify it compounds correctly
6. Die at 0 HP — game over still works
