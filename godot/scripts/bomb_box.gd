## Ports source/BombBox.hx. Pickup that grants +1 bomb capacity. The gentle
## per-frame brightness jitter matches the original's random color interpolate.
class_name BombBox
extends Node2D

var sprite: Sprite2D

func setup(p_position: Vector2) -> void:
	position = p_position
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture = load("res://assets/images/bomb_box.png")
	add_child(sprite)

func get_rect() -> Rect2:
	return Rect2(position, Vector2(64, 64))

func _process(_delta: float) -> void:
	sprite.modulate = Color.WHITE.lerp(Color.BLACK, randf_range(0.0, 0.2))

func use() -> void:
	Player.instance.bomb_count += 1
	PlayState.instance.update_ui()
	Game.play_sfx("res://assets/sounds/bomb_box.wav")
	PlayState.instance.remove_bomb_box(self)
	queue_free()
