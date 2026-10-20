# Breakout Roguelike

A Breakout and roguelike hybrid in Godot 4.6. You steer a curved paddle at the bottom of the screen and bounce balls into moving enemies. Fight through 30 levels and draft upgrades between fights.

**The twist:** balls never leave play. A ball that gets past the paddle hits a back wall and bounces back, but you take damage. The paddle is the player, and the run ends when its HP reaches zero.

## Features

- **Arc paddle:** where the ball hits along the curve sets the deflection angle, which is the main aiming skill
- **Enemies:** 8 monster types that move and shoot, each driven by a state machine
- **Upgrades:** 20 upgrades, from extra balls, piercing and splitting to defensive picks such as a wider paddle and a shield. More balls means more damage but more to track, so every pick is a trade-off
- **Editor tools:** custom Godot dock plugins for designing monsters and enemy formations

## Tech

GDScript with static typing, arcade-style custom physics on `CharacterBody2D`, component nodes for health and hitboxes, and autoloads for run and upgrade state.

## Run

Open `project.godot` in Godot 4.6 and press F5.
