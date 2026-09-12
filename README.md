# Super Puzzle Bomber

A top-down Bomberman-style puzzle game: blow up bricks with bombs, rescue the
person trapped in each level, and find the stairs to move on.

This repo has two things in it:

- **[`godot/`](godot/)** — the current version, a port to
  [Godot 4](https://godotengine.org/) (GDScript). This is what's actively
  developed. Open `godot/project.godot` in the Godot editor to run it.
- **[`legacy-haxe-flixel/`](legacy-haxe-flixel/)** — the original game as
  built in [HaxeFlixel](https://haxeflixel.com/), kept for reference. Not
  under active development.

## Playing

Open `godot/project.godot` in Godot 4.x and press Play. Controls:

- Arrow keys / WASD — move
- Space — place a bomb
- Enter — talk to the person you're facing
- R — restart the level
- Escape — back to the title screen

## Porting notes

The Godot version is a faithful 1:1 port of the original: same 5 levels
(loaded from the original Ogmo-format level JSON, reused as-is), same
mechanics, same art and sound assets. The main architectural differences are
just what the engine switch requires:

- HaxeFlixel `FlxState` → Godot `Scene` (`Title.tscn` / `Play.tscn`)
- HaxeFlixel sprite-sheet animation → Godot `AnimatedSprite2D` +
  `SpriteFrames`, built at runtime from `AtlasTexture` regions sliced out of
  the original sheet images (`sprite_sheet.gd`) — no assets were split into
  per-frame files
- HaxeFlixel's custom AABB collide-and-slide → a GDScript port of the same
  algorithm in `player.gd`
