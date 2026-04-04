# BreakoutRoguelike — Current State (2026-04-05)

This document replaces all previous specs as the single source of truth for the current game state.

## Core Game

Breakout x Roguelike hybrid. Player controls a small arc paddle with free 2D movement to bounce a ball into monsters. Balls never leave play — missed balls bounce off an invisible back wall and damage the player. Run ends at 0 HP. 30-level progression.

## Paddle

- **Shape:** Small arc (80px wide, 15px tall), CollisionPolygon2D
- **Movement:** Free 2D in bottom area (Y 450-680, X margin 10 + half-width)
- **Input:** Mouse/touch follows cursor, WASD/arrows for keyboard, auto-switch
- **Ball bounce:** Arc-angle calculation — hit position maps to -70 to +70 degree range, always upward
- **Below paddle:** Ball forced downward (away)
- **HurtZone:** Area2D detects projectiles (layer 16) and tokens (layer 32)
- **Signals:** hit_by_projectile(damage), laser_fired(x_pos, damage), token_collected(amount)
- **Laser:** Every 7s fires vertical beam (if upgrade active), visual cyan flash
- **Shield:** Absorbs 1 projectile, recharges 15s after use

## Ball

- **Base damage:** 5 (unified — hits monsters AND player on back wall)
- **Base speed:** 400
- **Collision:** CircleShape2D radius 10, mask includes Paddle+Walls+Blocks
- **Bounce:** Axis-based reflection (signf*absf pattern), reads actual block size for scaled blocks
- **Split:** Every 3 block hits spawns extra balls (5s life, darker visual, destroyed on back wall)
- **Follow:** Sits above paddle arc when not launched

## Blocks (Monsters)

- **Body:** CharacterBody2D (collision_layer=8, mask=0)
- **HP bars:** Dark background + colored fill + HP number text
- **Size scaling:** Per-cell size_scale applied to collision + visuals
- **Components:** HealthComponent, MovementComponent, ShootingComponent
- **Signals:** destroyed, projectile_spawned(proj, pos), killed(pos, token_value)
- **Burn DOT:** _process ticks damage, stops on dead blocks
- **Poison:** Permanent +N extra damage per hit (stacks)
- **Explosive Death:** On kill, 5 dmg to neighbors within 100px (no chain — guard flag)
- **Font:** Scales with block size (clamped 0.7x-3.0x)

## Monsters (8 types)

| Monster | HP | Role | Min Level | Tokens | Movement | Shooting |
|---------|-----|------|-----------|--------|----------|----------|
| Slime | 10 | front | 1 | 1 | none | none |
| Goblin | 20 | front | 3 | 1 | drift (30) | none |
| Shield | 35 | tank | 2 | 2 | drift (20) | none |
| Imp | 25 | support | 4 | 2 | zigzag (35) | straight (4s, 3 dmg) |
| Knight | 50 | tank | 8 | 3 | drift (15) | none |
| Shaman | 40 | support | 10 | 3 | orbit (40, r25) | aimed (5s, 4 dmg) |
| Demon | 80 | elite | 6 | 5 | charge (100, 4s) | spread (5s, 3 dmg, 3 count) |
| Dragon | 150 | elite | 15 | 8 | orbit+drift (30+15, r20) | burst+aimed (4s+6s) |

**HP scaling:** 15% per level. Formula: `ceil(base_hp * (1 + (level-1) * 0.15))`

## Movement Patterns

All configurable per monster via MonsterData exports. Combinable.

- **drift:** Horizontal back-and-forth, reverses at ±120px from spawn or arena walls
- **zigzag:** Diagonal bounce within ±80px bounding box, absf wall pattern
- **orbit:** Circle around spawn point, angle wraps, target clamped to arena
- **charge:** Idle → rush to paddle-60px → hold 0.5s → return at half speed

**Soft avoidance:** Neighbor list rebuilt every 0.3s, repulsion force when too close (150px radius, 80 strength)

**Arena bounds:** X 30-1250, Y 30-680. Clamped after move_and_slide().

## Shooting Patterns

All configurable per monster. Combinable. Randomized initial timer offsets.

- **straight:** Single projectile downward
- **aimed:** Targets paddle position at fire time
- **spread:** Fan of N projectiles (15° apart)
- **burst:** Rapid N-shot burst (0.15s delay between)

**Projectile:** Area2D, layer 16, mask 0. Color matches monster. Destroys at Y>680 or off-screen.

**Slow Field upgrade:** Projectiles move (1 - slow_field)x speed when Y > 400.

## Token Economy

- Monsters drop 1 physical token pickup on death (golden diamond, falls with gravity)
- Token value per monster defined by `token_value` property (editable in monster editor)
- Paddle collects tokens on contact. Missed tokens disappear at bottom.
- Tokens carry over between levels.
- **Upgrade costs:** 3 rounds per level, each round shows 3 cards costing 1, 2, 3 tokens (left to right)
- Cards you can't afford are greyed out and unclickable
- Skip button available to save tokens
- Token counter in top-right during gameplay, hidden during upgrade selection
- HP bar + UI hidden during upgrade picks

## Upgrades (20 total)

### Offense (10)
| Upgrade | effect_id | Value/stack | Notes |
|---------|-----------|-------------|-------|
| Ball Damage + | ball_damage | +2 int | Affects self-damage too |
| Critical Hit | crit_chance | +10% | Cap 100%, monsters only |
| Piercing | piercing | +1 block | Resets on paddle/bounce |
| Split Shot | split_shot | +1 extra ball | Every 3 hits, 5s life |
| AoE Blast | aoe_damage | +3 flat | 80px radius |
| Burn | burn | +0.5 dps | 5 second DOT |
| Paddle Laser | laser | +1 damage | Vertical beam every 7s |
| Chain Lightning | chain_lightning | +2 targets | 50% damage, 120px range |
| Poison | poison | +1 permanent | All damage sources apply it |
| Explosive Death | explosive_death | +5 damage | 100px radius, no chain |

### Defense (7)
| Upgrade | effect_id | Value/stack | Notes |
|---------|-----------|-------------|-------|
| Lifesteal | lifesteal | +5% | Cap 100% |
| Max HP + | max_hp | +10 HP | Heals immediately |
| Damage Reduction | damage_reduction | +10% | Cap 50%, min 1 dmg |
| Regen | regen | +1 rate | 1 HP every (10/stacks)s |
| Thorns | thorns | +2 damage | Random block on back wall hit |
| Shield Charge | shield | +1 charge | 15s recharge |
| HP on Kill | hp_on_kill | +3 HP | Per monster kill |
| Slow Field | slow_field | +30% | Cap 90%, Y>400 |

### Utility (2)
| Upgrade | effect_id | Value/stack | Notes |
|---------|-----------|-------------|-------|
| Ball Speed + | ball_speed | +10% | Multiplicative |
| Wider Paddle | paddle_width | +15% | Multiplicative |

## Formations

- **Grid:** 15 columns, symmetric (center col 7, mirror at 14-x)
- **Templates:** 35 symmetric templates in 5 categories
  - 0-7: Introduction (mixed roles even in early templates)
  - 8-14: Tank Walls (with support+elite mixed in)
  - 15-21: Support Formations
  - 22-28: Elite Encounters
  - 29-34: Mixed Chaos
- **Per-cell properties:** grid_position, role, monster_override, size_scale
- **Max ~20 blocks** per formation with varied sizes (0.5x-3.0x)
- **Row-based Y alignment:** tallest block per row pushes rows below down
- **90 formation .tres files** (3 per level × 30 levels), all editable in formation editor
- **Level pools:** reference external formation files, 3 random options per level

## Editor Plugins

### Monster Editor (`res://addons/monster_editor/`)
- Dock with list + create/delete
- Click monster → EditorInterface.inspect_object()
- All MonsterData properties editable: HP, color, role (dropdown), min_level, token_value, movement toggles+speeds, shooting toggles+speeds+damage

### Formation Editor (`res://addons/formation_editor/`)
- Three-panel HSplitContainer dock
- Left: formation list, level pool manager
- Center: grid editor with paint tools (role painting), template dropdown, arena preview
- Right: cell inspector (role dropdown, monster override, width/height scale sliders)
- Grid preview shows scaled cell sizes
- Arena preview shows actual block layout with row-based alignment

## Collision Layers

| Layer | Bit | Used by |
|-------|-----|---------|
| 1 (Paddle) | 1 | Paddle |
| 2 (Ball) | 2 | Ball |
| 3 (Walls) | 4 | Arena walls |
| 4 (Blocks) | 8 | Blocks/monsters |
| 5 (Projectile) | 16 | Monster projectiles |
| 6 (Token) | 32 | Token pickups |

## Damage Numbers

Floating labels that drift up and fade (0.8s):
- **White:** Normal monster damage
- **Green-yellow:** Poison-boosted damage
- **Orange:** Burn tick damage
- **Red:** Player damage (at HP bar position)
- **Green:** Healing (lifesteal, HP on kill, regen — at HP bar position)

## Files Structure

```
scripts/
  ball.gd               — Ball movement, bounce, upgrade effects
  block.gd              — Monster block, HP, burn/poison/explosive
  paddle.gd             — Arc paddle, 2D movement, laser, shield, hurt zone
  main.gd               — Game manager, spawning, wiring, UI
  projectile.gd         — Enemy projectile movement
  token_pickup.gd       — Physical token with gravity
  formation_templates.gd — 35 symmetric template generators
  data/
    monster_data.gd     — Monster resource (HP, color, role, movement, shooting, tokens)
    formation_cell.gd   — Cell resource (position, role, override, size_scale)
    formation_data.gd   — Formation resource (name, grid, template, cells)
    level_pool.gd       — Level pool resource (level, formations)
    upgrade_data.gd     — Upgrade resource (name, desc, category, effect_id, value)
  components/
    health_component.gd  — Reusable HP tracker
    movement_component.gd — Drift/zigzag/orbit/charge + soft avoidance
    shooting_component.gd — Straight/aimed/spread/burst patterns
  autoloads/
    upgrade_manager.gd   — Global upgrade state + token economy
  ui/
    upgrade_selection.gd — 3 rounds, 1/2/3 token costs, skip
    upgrade_card.gd      — Card display with cost, stack, category
    damage_number.gd     — Floating damage/heal numbers
```
