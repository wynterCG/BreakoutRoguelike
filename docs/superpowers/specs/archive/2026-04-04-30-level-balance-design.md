# 30-Level Balance & Progression Design

## Goal

Create a balanced 30-level progression with 8 monster types, varied formations, and a split ball rebalance. All values are data-driven (.tres files) and editable via the existing editor plugins.

## Monster Roster (8 monsters, 2 per role)

| Monster | Role | Base HP | Color (RGB) | Min Level | Notes |
|---------|------|---------|-------------|-----------|-------|
| Slime | front | 1 | (0.2, 0.8, 0.2) green | 1 | Cannon fodder |
| Goblin | front | 3 | (0.6, 0.8, 0.2) yellow-green | 6 | Tougher filler |
| Shield | tank | 8 | (0.5, 0.5, 0.55) gray | 4 | First wall enemy |
| Knight | tank | 20 | (0.75, 0.75, 0.8) silver | 12 | Heavy wall |
| Imp | support | 5 | (0.9, 0.5, 0.2) orange | 8 | Back-line moderate |
| Shaman | support | 12 | (0.85, 0.2, 0.2) red | 16 | Tough back-line |
| Demon | elite | 30 | (0.6, 0.1, 0.15) dark red | 10 | Mini-boss |
| Dragon | elite | 60 | (0.6, 0.06, 0.59) purple | 20 | Final boss-tier |

Existing monsters (Grunt, Warrior, Brute, Elite Boy) are replaced by these 8. The old .tres files are deleted and new ones created.

## HP Scaling

Change `HP_SCALE_PER_LEVEL` from `0.2` to `0.1`.

Resulting HP at key levels (base HP x scaling multiplier):

| Monster | Lvl 1 | Lvl 5 | Lvl 10 | Lvl 15 | Lvl 20 | Lvl 25 | Lvl 30 |
|---------|-------|-------|--------|--------|--------|--------|--------|
| Slime (1) | 1 | 2 | 2 | 3 | 3 | 4 | 4 |
| Goblin (3) | - | - | 6 | 8 | 9 | 11 | 12 |
| Shield (8) | - | 12 | 16 | 20 | 24 | 28 | 32 |
| Imp (5) | - | - | 10 | 13 | 15 | 18 | 20 |
| Demon (30) | - | - | 57 | 72 | 87 | 102 | 117 |
| Knight (20) | - | - | - | 48 | 58 | 68 | 78 |
| Shaman (12) | - | - | - | - | 35 | 41 | 47 |
| Dragon (60) | - | - | - | - | 174 | 204 | 234 |

With base ball damage of 5, a Dragon at level 30 takes 47 hits. With 3 stacks of Ball Damage (+6), it takes 21 hits. Upgrades are essential for late game.

## Split Ball Rebalance

Change split shot from "split on every block hit" to "split every 3 block hits."

Implementation:
- Add `_split_hit_counter: int = 0` to ball.gd
- Increment counter on each block hit
- When counter reaches 3 AND split_count > 0: emit `split_requested`, reset counter to 0
- Counter resets on paddle bounce (fresh sequence)
- Split balls do NOT have their own split counter (they don't split — same as current)

## Level Progression (30 levels)

### Tier 1: Introduction (Levels 1-5)
- **Monsters**: Slime only (front)
- **Density**: 15-25 blocks
- **Formations**: Open, simple patterns
- **Templates**: scattered, V-shape, diamond, diagonal, zigzag

| Level | Formations (template choices) | Grid | Block Count |
|-------|-------------------------------|------|-------------|
| 1 | 3 rows scattered | 14x3 | ~15 |
| 2 | V-shape, diagonal | 14x4 | ~18-20 |
| 3 | Diamond, zigzag | 14x5 | ~20-25 |
| 4 | + Shield introduced | 14x5 | ~22-28 |
| 5 | Checkerboard, border edges | 14x5 | ~25-30 |

### Tier 2: Building Up (Levels 6-10)
- **Monsters**: Slime, Goblin, Shield
- **Density**: 25-40 blocks
- **Formations**: Mixed patterns, some walls
- **Templates**: pyramid, cross, wave, fortress, frame

| Level | Notes |
|-------|-------|
| 6 | Goblin introduced, front+tank mix |
| 7 | Denser patterns, shields form walls |
| 8 | Imp introduced (support role) |
| 9 | Cross and fortress patterns |
| 10 | Demon introduced, first mini-boss cell |

### Tier 3: Mid-Game (Levels 11-15)
- **Monsters**: All except Knight, Shaman, Dragon
- **Density**: 35-50 blocks
- **Formations**: Strategic layouts with tank walls protecting elites
- **Templates**: hourglass, arrows, spiral, clusters, maze-like

| Level | Notes |
|-------|-------|
| 11 | Dense formations, demons appear more |
| 12 | Knight introduced, heavy tank walls |
| 13 | Mixed role formations, multiple demons |
| 14 | Complex patterns with size-scaled elites |
| 15 | Dense mid-tier gauntlet |

### Tier 4: Escalation (Levels 16-20)
- **Monsters**: All except Dragon
- **Density**: 45-60 blocks
- **Formations**: Dense with layered defenses
- **Templates**: full grids, chevrons, pincer, double-wall

| Level | Notes |
|-------|-------|
| 16 | Shaman introduced, tough back-lines |
| 17 | Knights form double walls |
| 18 | Dense mixed formations |
| 19 | Multiple demons with tank escorts |
| 20 | Dragon introduced, first appearance |

### Tier 5: Gauntlet (Levels 21-25)
- **Monsters**: All types
- **Density**: 50-70 blocks
- **Formations**: Aggressive layouts, size-scaled elites
- **Templates**: dense fills, zigzag walls, fortress with elite cores

| Level | Notes |
|-------|-------|
| 21-25 | All monsters, dense formations, dragons with tank guards, size-scaled bosses |

### Tier 6: Endgame (Levels 26-30)
- **Monsters**: All types, dragon-heavy
- **Density**: 60-80 blocks
- **Formations**: Maximum challenge
- **Templates**: near-full grids, elite cores surrounded by walls

| Level | Notes |
|-------|-------|
| 26-30 | Maximum density, multiple dragons, heavy scaling, only strong builds survive |

## Formation Creation Strategy

Each level pool gets 3-4 formation options (randomly selected per run for variety). Formations use templates from the 100 available and are assigned roles via auto-assign or manual painting.

Total new formations to create: ~60-80 (2-3 unique per level, some reused across adjacent levels).

For efficiency, many formations use `template_index` with auto-role assignment. Unique hand-crafted formations are reserved for milestone levels (10, 15, 20, 25, 30).

## Files Changed

| File | Change |
|------|--------|
| `scripts/ball.gd` | Add `_split_hit_counter`, split every 3 hits |
| `scripts/main.gd` | Change `HP_SCALE_PER_LEVEL` from 0.2 to 0.1 |
| `data/monsters/*.tres` | Delete old 4, create new 8 |
| `data/formations/*.tres` | Create ~60-80 new formations |
| `data/level_pools/*.tres` | Create/update 30 level pools |

## Verification

1. Run game — level 1 has sparse slimes, easy to clear
2. Progress through levels — new monsters appear at their min_level
3. Level 10 — first demon appears, noticeable difficulty increase
4. Level 20 — first dragon, significant challenge
5. Level 30 — brutal, requires good upgrade build to survive
6. Split ball — splits every 3 hits, not every hit
7. All data editable in formation/monster editors
