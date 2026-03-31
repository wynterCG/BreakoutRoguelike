# CLAUDE.md — Breakout × Roguelike Project

## 1. Project Overview
* **Description:** A hybrid Breakout/Roguelike where the player controls a bottom-screen arc paddle to bounce balls into dynamic, moving enemies.
* **Core Loop:** Clear procedurally generated combat rooms, navigate a branching map, and draft upgrades.
* **Key Twist:** Balls never leave play. If a ball passes behind the paddle, it hits a back wall and bounces back into the arena, but the player takes damage. The run ends when Paddle HP reaches zero.
* **Entities:**
  * **Paddle:** Player-controlled arc shape (curved, like the game Ricochet). Takes damage from missed balls and enemy projectiles.
  * **Balls:** Projectiles that bounce off walls, enemies, and the paddle.
  * **Enemies:** Mobile entities with HP. Types include Tanks, Movers, Healers, Spawners, and Shooters. Bosses are small, fast, and susceptible to knockback pinning.

## 2. Tech Stack & Environment
* **Engine:** Godot 4.6
* **Language:** GDScript 2.0 ONLY. Do not use C# unless explicitly asked.
* **Physics Approach:** Arcade-style custom physics using `CharacterBody2D` (for precise control over balls, paddle, and enemies) rather than `RigidBody2D`.

## 3. Coding Standards (GDScript)
* **Typing:** STRICTLY use static typing for all variables, parameters, and return types (e.g., `var hp: int = 100`, `func apply_damage(amount: int) -> void:`).
* **Naming Conventions:**
    * `snake_case` for variables, functions, and file names (e.g., `ball_controller.gd`).
    * `PascalCase` for class names and node names (e.g., `BallController`, `EnemyTank`).
    * ALL_CAPS for constants (e.g., `BASE_SPEED`).
    * Prefix private variables/functions with an underscore (e.g., `_on_hit()`).

## 4. Architecture & Structure
* **Globals (Autoloads):**
  * `RunManager`: Tracks current HP, currency, and map progression.
  * `UpgradeManager`: Stores active modifiers (Offense: extra balls, piercing, fire trails, splitting, homing, knockback. Defense: wider paddle, extra HP, dash, shield, magnetic pull).
* **File Structure:**
    * `res://scenes/entities/` — Paddle, Ball, Enemy base classes.
    * `res://scenes/levels/` — Arena generation and map rooms.
    * `res://scripts/` — GDScript files mirroring scene structure.
* **Component Pattern:** Use child nodes for reusable logic (e.g., a `HealthComponent` node or `HitboxComponent` node attached to enemies).

## 5. Specific Mechanic Implementations
* **Paddle Shape:** The paddle is an arc (curved surface). Ball deflection angle depends on where the ball hits along the arc — hitting the edge produces steeper angles, hitting the center reflects more vertically. This is the primary aiming mechanic.
* **The "Ouch" Zone:** The area behind the paddle uses an `Area2D` to detect the ball for damage, layered over a bouncy `StaticBody2D` that physically forces the ball back into the arena.
* **Enemy States:** Enemies use a Finite State Machine (Idle, Move, Attack, Stunned/Knockback).
* **Signal Routing:** Always connect signals via code (`.connect()`) in the `_ready()` function. Do not rely on Godot Editor UI signal connections.

## 6. Phase Roadmap
1. **Phase 1:** Core breakout loop — arc paddle, ball physics, walls, breakable blocks
2. **Phase 2:** Replace blocks with basic moving enemies (HP, destruction)
3. **Phase 3:** "Ouch zone" mechanic (missed balls damage paddle instead of losing ball)
4. **Phase 4:** Upgrades (extra balls, piercing, wider paddle, etc.)
5. **Phase 5:** Roguelike systems (room generation, branching map, run progression)
6. **Phase 6:** Polish & balancing

## 7. AI Agent Instructions
* Before suggesting code changes, check the file extension (`.gd` vs `.tscn`).
* Keep the tradeoff philosophy in mind: more balls = more DPS but higher cognitive load for the player. Keep physics performant and predictable.
* If a script has a syntax error, assume it is a Godot 4 API change and double-check standard Godot 4 GDScript documentation.
