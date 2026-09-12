# Agent instructions

## Commit policy

Always commit changes as you make them — don't let work sit uncommitted.
Concretely:

- After finishing a coherent change (a bug fix, a feature, an asset update,
  a refactor), commit it before moving on to the next thing. Don't batch
  unrelated changes into one commit.
- Write real commit messages: what changed and why, not just "update".
- After committing, push to `origin` (`master`) so GitHub stays current.
  Don't leave commits local-only.
- If you're mid-change and about to do something risky (e.g. a large
  rewrite), commit the last known-good state first.

This repo's remote:

- `origin` → https://github.com/fabtjar/super-puzzle-bomber (the active
  Godot port — push here)
- `legacy-origin` → https://github.com/fabtjar/puzzle-bomber (the original
  HaxeFlixel repo this was ported from — do not push here)

## Project layout

- [`godot/`](godot/) — the Godot 4 (GDScript) port, actively developed.
  Open `godot/project.godot` in the Godot editor.
- [`legacy-haxe-flixel/`](legacy-haxe-flixel/) — the original HaxeFlixel
  source, kept for reference only. Not under active development.

## Validating changes to the Godot project

There's no GUI automation available for the native Godot editor window in
this environment, so validate changes headlessly before handing off for a
human playtest:

```bash
GODOT="C:/Users/Fab/Desktop/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64_console.exe"
cd godot
"$GODOT" --headless --path . --import          # catches parse/compile errors
"$GODOT" --headless --path . --quit-after 60   # runs the main scene for real frames
```

To smoke-test `Play.tscn` (or a specific level) instead of the title screen,
temporarily point `run/main_scene` in `project.godot` at `res://scenes/Play.tscn`
and/or edit the default `level_number` in `autoload/game.gd`, run the check,
then restore both back to their defaults (`Title.tscn` / `1`) before
committing — don't leave test scaffolding or temporary main-scene changes in
a commit.
