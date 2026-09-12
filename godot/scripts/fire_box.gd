## Ports source/FireBox.hx. Pickup that grants +1 blast radius.
class_name FireBox
extends Node2D

var sprite: Sprite2D

func setup(p_position: Vector2) -> void:
	position = p_position
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture = load("res://assets/images/fire_box.png")
	add_child(sprite)

func get_rect() -> Rect2:
	return Rect2(position, Vector2(64, 64))

func _process(_delta: float) -> void:
	sprite.modulate = Color.WHITE.lerp(Color.BLACK, randf_range(0.0, 0.2))

func use() -> void:
	Player.instance.bomb_size += 1
	PlayState.instance.update_ui()
	Game.play_sfx("res://assets/sounds/fire_box.wav")
	PlayState.instance.remove_fire_box(self)
	queue_free()
