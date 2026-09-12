## Ports source/Player.hx. PlayState drives this explicitly each frame
## (update_input_and_move -> collide_and_slide -> update_wrap_sprite) instead
## of relying on Godot's automatic node process order, mirroring the
## original's single-threaded FlxState update loop.
class_name Player
extends Node2D

static var instance: Player

const SPEED := 240.0
const HITBOX_SIZE := Vector2(64, 64)

var bomb_count: int = 0
var bomb_size: int = 0
var can_move: bool = true
var facing: int = Constants.Dir.DOWN

var move_dir: Vector2 = Vector2.ZERO
var touching: Dictionary = {}

var sprite: AnimatedSprite2D
var wrap_sprite: AnimatedSprite2D

var _space_was_down := false

func _ready() -> void:
	instance = self

	var texture := load("res://assets/images/player.png")
	var sprite_frames := SpriteSheet.build(texture, 64, 80, 4, {
		"idle_down": {"frames": [0]},
		"idle_up": {"frames": [4]},
		"idle_side": {"frames": [8]},
		"walk_down": {"frames": [1, 2, 3, 2], "fps": 10.0},
		"walk_up": {"frames": [5, 6, 7, 6], "fps": 10.0},
		"walk_side": {"frames": [9, 10, 11, 10], "fps": 10.0},
	})

	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(0, -16)
	sprite.sprite_frames = sprite_frames
	sprite.play("idle_down")
	add_child(sprite)

	wrap_sprite = AnimatedSprite2D.new()
	wrap_sprite.centered = false
	wrap_sprite.offset = Vector2(0, -16)
	wrap_sprite.sprite_frames = sprite_frames
	wrap_sprite.visible = false
	add_child(wrap_sprite)

	_reset_touching()

func _reset_touching() -> void:
	touching = {
		Constants.Dir.UP: false,
		Constants.Dir.DOWN: false,
		Constants.Dir.LEFT: false,
		Constants.Dir.RIGHT: false,
	}

func get_rect() -> Rect2:
	return Rect2(position, HITBOX_SIZE)

func get_center() -> Vector2:
	return position + HITBOX_SIZE / 2.0

func update_input_and_move(delta: float) -> void:
	if not can_move:
		_play(sprite, "idle_down")
		return

	_update_move_dir()

	var space_now := Input.is_key_pressed(KEY_SPACE)
	if space_now and not _space_was_down and bomb_count > 0:
		if PlayState.instance.try_place_bomb(position, bomb_size):
			bomb_count -= 1
			PlayState.instance.update_ui()
	_space_was_down = space_now

	var movement_amount := SPEED * delta
	position.x += move_dir.x * movement_amount
	position.y += 0.0 if move_dir.x != 0 else move_dir.y * movement_amount

	_apply_lane_assist(delta)
	_wrap_around_screen()
	_set_animation()

## The SNES-Zelda/Bomberman trick: while walking a straight line, gently pull
## the perpendicular axis toward the center of the current tile row/column,
## so imprecise keyboard input still lines you up with a single-tile gap
## instead of clipping its edge and stopping dead. Only runs when the player
## isn't also pressing the perpendicular direction, so it never fights a
## deliberate turn - and it only nudges position, so collide_and_slide still
## blocks it same as any other movement if the nudge would walk into a wall.
func _apply_lane_assist(delta: float) -> void:
	var assist_speed := SPEED * delta
	if move_dir.x != 0 and move_dir.y == 0:
		var target_y := roundf(position.y / Constants.TILE_SIZE) * Constants.TILE_SIZE
		position.y = move_toward(position.y, target_y, assist_speed)
	elif move_dir.y != 0 and move_dir.x == 0:
		var target_x := roundf(position.x / Constants.TILE_SIZE) * Constants.TILE_SIZE
		position.x = move_toward(position.x, target_x, assist_speed)

func _update_move_dir() -> void:
	move_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		move_dir.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		move_dir.y += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		move_dir.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		move_dir.x += 1

func get_action_position() -> Vector2:
	var rect := get_rect()
	var pos := rect.position + rect.size / 2.0
	var distance := 20.0
	match facing:
		Constants.Dir.UP:
			pos.y = rect.position.y - distance
		Constants.Dir.DOWN:
			pos.y = rect.end.y + distance
		Constants.Dir.LEFT:
			pos.x = rect.position.x - distance
		Constants.Dir.RIGHT:
			pos.x = rect.end.x + distance
	return pos

func _get_facing() -> int:
	if move_dir.y < 0:
		return Constants.Dir.UP
	elif move_dir.y > 0:
		return Constants.Dir.DOWN
	elif move_dir.x < 0:
		return Constants.Dir.LEFT
	elif move_dir.x > 0:
		return Constants.Dir.RIGHT
	return Constants.Dir.DOWN

func _play(target: AnimatedSprite2D, anim_name: String) -> void:
	if target.animation != anim_name:
		target.play(anim_name)

func _set_animation() -> void:
	var moving := move_dir.x != 0 or move_dir.y != 0
	sprite.flip_h = false
	if moving:
		facing = _get_facing()
		match facing:
			Constants.Dir.UP:
				_play(sprite, "walk_up")
			Constants.Dir.DOWN:
				_play(sprite, "walk_down")
			Constants.Dir.LEFT:
				sprite.flip_h = true
				_play(sprite, "walk_side")
			Constants.Dir.RIGHT:
				_play(sprite, "walk_side")
	else:
		match facing:
			Constants.Dir.UP:
				_play(sprite, "idle_up")
			Constants.Dir.DOWN:
				_play(sprite, "idle_down")
			Constants.Dir.LEFT:
				sprite.flip_h = true
				_play(sprite, "idle_side")
			Constants.Dir.RIGHT:
				_play(sprite, "idle_side")

func _wrap_around_screen() -> void:
	if position.x < 0:
		position.x += Constants.SCREEN_SIZE
	elif position.x > Constants.SCREEN_SIZE:
		position.x -= Constants.SCREEN_SIZE
	if position.y < 0:
		position.y += Constants.SCREEN_SIZE
	elif position.y > Constants.SCREEN_SIZE:
		position.y -= Constants.SCREEN_SIZE

## Resolves overlap against every solid using minimum-translation-vector
## (MTV) separation: for each overlapping solid, push out along whichever
## axis has the smaller penetration. This replaced a direct port of
## Player.hx's delta-sign-based collideAndSlide(), which could disagree with
## itself frame to frame near a corner (two adjacent solids, each resolved
## against a different axis) and visibly jitter. MTV is deterministic from
## the current geometry alone, so it converges instead of oscillating, and
## since movement here is always single-axis per frame, resolving the
## shallower-penetration axis already produces the smooth corner-nudge the
## original's separate "slide" pass was for.
func collide_and_slide(solid_rects: Array) -> void:
	_reset_touching()
	for solid_rect in solid_rects:
		_separate_against(solid_rect)

func _separate_against(solid: Rect2) -> void:
	var rect := get_rect()
	if not rect.intersects(solid):
		return

	var overlap_x: float = minf(rect.end.x, solid.end.x) - maxf(rect.position.x, solid.position.x)
	var overlap_y: float = minf(rect.end.y, solid.end.y) - maxf(rect.position.y, solid.position.y)
	if overlap_x <= 0.0 or overlap_y <= 0.0:
		return

	var center := rect.position + rect.size / 2.0
	var solid_center := solid.position + solid.size / 2.0

	if overlap_x < overlap_y:
		if center.x < solid_center.x:
			position.x -= overlap_x
			touching[Constants.Dir.RIGHT] = true
		else:
			position.x += overlap_x
			touching[Constants.Dir.LEFT] = true
	else:
		if center.y < solid_center.y:
			position.y -= overlap_y
			touching[Constants.Dir.DOWN] = true
		else:
			position.y += overlap_y
			touching[Constants.Dir.UP] = true

func update_wrap_sprite() -> void:
	var rect := get_rect()

	wrap_sprite.visible = true
	if wrap_sprite.animation != sprite.animation:
		wrap_sprite.animation = sprite.animation
	wrap_sprite.frame = sprite.frame
	wrap_sprite.flip_h = sprite.flip_h
	wrap_sprite.position = position

	if rect.position.x < 0:
		wrap_sprite.position.x = position.x + Constants.SCREEN_SIZE
	elif rect.end.x > Constants.SCREEN_SIZE:
		wrap_sprite.position.x = position.x - Constants.SCREEN_SIZE
	elif rect.position.y - 16 < 0:
		wrap_sprite.position.y = position.y + Constants.SCREEN_SIZE
	elif rect.end.y > Constants.SCREEN_SIZE:
		wrap_sprite.position.y = position.y - Constants.SCREEN_SIZE
	else:
		wrap_sprite.visible = false

func die() -> void:
	can_move = false
	sprite.modulate = Color(0.5, 0.5, 0.5)
	wrap_sprite.modulate = Color(0.5, 0.5, 0.5)
	PlayState.instance.failed_level()
