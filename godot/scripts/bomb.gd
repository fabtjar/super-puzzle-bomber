## Ports source/Bomb.hx. Pulses for a 2s fuse, then detonates into fires.
## Not solid until the player who placed it steps off it (so you can walk
## away from your own bomb), matching the original's allowCollisions toggle.
class_name Bomb
extends Node2D

var size: int
var solid: bool = false

var sprite: AnimatedSprite2D
var _fuse_remaining: float = 2.0
var _exploded: bool = false

func setup(p_position: Vector2, p_size: int) -> void:
	position = p_position
	size = p_size

	var texture := load("res://assets/images/bomb.png")
	var sprite_frames := SpriteSheet.build(texture, 64, 80, 3, {
		"pulse": {"frames": [0, 1, 2, 1], "fps": 6.0},
	})

	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(0, -16)
	sprite.sprite_frames = sprite_frames
	sprite.play("pulse")
	add_child(sprite)

	Game.play_sfx("res://assets/sounds/bomb.wav")

func get_rect() -> Rect2:
	return Rect2(position, Vector2(64, 64))

func _process(delta: float) -> void:
	if _exploded:
		return

	if not solid and not get_rect().intersects(Player.instance.get_rect()):
		solid = true

	_fuse_remaining -= delta
	if _fuse_remaining <= 0.0:
		_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	PlayState.instance.create_fires(position, size)
	Game.play_sfx("res://assets/sounds/explode.wav")
	PlayState.instance.remove_bomb(self)
	queue_free()

## A fire tile reached this bomb before its fuse ran out - cut the fuse
## short instead of exploding instantly, matching Bomb.hx explodeEarly().
func explode_early() -> void:
	_fuse_remaining = minf(_fuse_remaining, 0.1)
