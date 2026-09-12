## Ports source/Person.hx, including its quirk: every frame forces the pose
## back to idle_down (matching the original's unconditional
## `animation.play("idle_down")` in update()). face_player()'s pose and
## play_win() are only ever visible while PlayState itself isn't running its
## own per-frame update - i.e. while the talk dialog has the tree paused.
class_name Person
extends Node2D

var dead: bool = false
var sprite: AnimatedSprite2D

func setup(p_position: Vector2) -> void:
	position = p_position

	var texture := load("res://assets/images/person.png")
	var sprite_frames := SpriteSheet.build(texture, 64, 64, 2, {
		"idle_down": {"frames": [0]},
		"idle_up": {"frames": [1]},
		"idle_side": {"frames": [2]},
		"win": {"frames": [3, 0], "fps": 2.0},
	})

	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(0, -16)
	sprite.sprite_frames = sprite_frames
	sprite.play("idle_down")
	add_child(sprite)

func get_rect() -> Rect2:
	return Rect2(position, Vector2(64, 64))

func _process(_delta: float) -> void:
	if sprite.animation != "idle_down":
		sprite.play("idle_down")
	sprite.flip_h = false

func die() -> void:
	dead = true
	sprite.modulate = Color(0.5, 0.5, 0.5)
	PlayState.instance.failed_level()

func face_player(player_facing: int) -> void:
	match player_facing:
		Constants.Dir.UP:
			sprite.play("idle_down")
		Constants.Dir.DOWN:
			sprite.play("idle_up")
		Constants.Dir.LEFT:
			sprite.play("idle_side")
			sprite.flip_h = false
		Constants.Dir.RIGHT:
			sprite.play("idle_side")
			sprite.flip_h = true

func play_win() -> void:
	sprite.play("win")
