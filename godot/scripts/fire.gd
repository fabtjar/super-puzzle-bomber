## A single blast tile. Draws at full tile size but its hit-test rect is a
## small 16x16 box centered in the tile, matching the original's
## `fire.offset.set(24, 24); fire.setSize(16, 16)` - the visible flame is
## bigger than the area that actually kills you or chain-reacts a bomb.
class_name Fire
extends Node2D

var sprite: Sprite2D

func setup(p_position: Vector2) -> void:
	position = p_position

	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture = load("res://assets/images/fire.png")
	add_child(sprite)

	get_tree().create_timer(0.3).timeout.connect(_expire)

func get_rect() -> Rect2:
	return Rect2(position + Vector2(24, 24), Vector2(16, 16))

func _expire() -> void:
	if is_instance_valid(PlayState.instance):
		PlayState.instance.remove_fire(self)
	queue_free()
