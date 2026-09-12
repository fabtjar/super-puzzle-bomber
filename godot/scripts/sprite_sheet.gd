## Slices a grid-based sprite sheet (the original .png assets, unmodified)
## into AtlasTexture regions and assembles them into a SpriteFrames resource,
## the standard Godot way to drive AnimatedSprite2D from a single sheet
## without splitting it into separate frame files.
class_name SpriteSheet

## animations: { anim_name: { "frames": [int, ...], "fps": float, "loop": bool } }
## Frame indices are numbered left-to-right, top-to-bottom, matching the
## original HaxeFlixel `loadGraphic(path, true, frameWidth, frameHeight)` order.
static func build(texture: Texture2D, frame_width: int, frame_height: int, columns: int, animations: Dictionary) -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")

	var atlas_cache: Dictionary = {}

	for anim_name in animations.keys():
		var config: Dictionary = animations[anim_name]
		var indices: Array = config["frames"]
		var fps: float = config.get("fps", 0.0)
		var loop: bool = config.get("loop", true)

		sprite_frames.add_animation(anim_name)
		# A single-frame "animation" never advances, so any fps > 0 is inert;
		# 1.0 just avoids Godot's speed_scale edge cases at exactly 0.
		sprite_frames.set_animation_speed(anim_name, maxf(fps, 1.0))
		sprite_frames.set_animation_loop(anim_name, loop)

		for raw_index in indices:
			var index: int = raw_index
			if not atlas_cache.has(index):
				var col: int = index % columns
				var row: int = index / columns
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
				atlas_cache[index] = atlas
			sprite_frames.add_frame(anim_name, atlas_cache[index])

	return sprite_frames

## For static, non-animated UI icons that just need one frame of a sheet.
static func atlas_frame(texture: Texture2D, frame_width: int, frame_height: int, columns: int, index: int) -> AtlasTexture:
	var col: int = index % columns
	var row: int = index / columns
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
	return atlas
