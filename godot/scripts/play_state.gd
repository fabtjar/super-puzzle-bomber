## Ports source/PlayState.hx. Owns the level and drives the main per-frame
## loop explicitly (player movement -> collision -> stairs check -> bomb/fire
## overlaps -> talk prompt), the same single-pass order the original ran
## through FlxState's automatic object update followed by PlayState.update().
class_name PlayState
extends Node2D

static var instance: PlayState

const TILE := Constants.TILE_SIZE

var player: Player

var level_number: int = 1
var level_failed: bool = false
var stairs_visible: bool = false

var walls: Array = []                 # Array[Rect2], static, never changes
var tile_grid: Dictionary = {}        # Vector2i -> "wall" | "brick"
var brick_sprites: Dictionary = {}    # Vector2i -> Sprite2D
var bricks_remaining: int = 0

var bombs: Array = []                 # Array[Bomb]
var fires: Array = []                 # Array[Fire]
var bomb_boxes: Array = []            # Array[BombBox]
var fire_boxes: Array = []            # Array[FireBox]
var people: Array = []                # Array[Person]

var stairs_sprite: Sprite2D

var bomb_ui: Array = []               # Array[Sprite2D]
var fire_ui: Array = []               # Array[Sprite2D]

var level_text: Label
var press_talk_label: Label

var talk_text: String = ""
var talk_win_text: String = ""

var world_layer: Node2D
var fires_layer: Node2D

var _enter_was_down := false
var _r_was_down := false
var _escape_was_down := false

func _ready() -> void:
	instance = self

	level_number = Game.level_number
	if not FileAccess.file_exists("res://assets/levels/level_%d.json" % level_number):
		level_number = 1

	var bg := ColorRect.new()
	bg.color = Color8(129, 240, 155)
	bg.size = Vector2(Constants.SCREEN_SIZE, Constants.SCREEN_SIZE)
	bg.z_index = -100
	add_child(bg)

	world_layer = Node2D.new()
	add_child(world_layer)
	fires_layer = Node2D.new()
	add_child(fires_layer)

	Game.ensure_music_playing("res://assets/sounds/music.ogg")
	Game.flash(Color.WHITE, 0.5)

	stairs_sprite = Sprite2D.new()
	stairs_sprite.centered = false
	stairs_sprite.texture = load("res://assets/images/stairs.png")
	stairs_sprite.visible = false
	stairs_sprite.z_index = -5
	world_layer.add_child(stairs_sprite)

	player = Player.new()
	player.z_index = 10
	world_layer.add_child(player)

	_load_level()
	_build_ui()

func _load_level() -> void:
	var path := "res://assets/levels/level_%d.json" % level_number
	var text := FileAccess.get_file_as_string(path)
	var data: Dictionary = JSON.parse_string(text)
	var map: Array = data["layers"][0]["data2D"]
	var values: Dictionary = data["values"]

	talk_text = values["talkText"]
	talk_win_text = values["talkWinText"]

	for y in map.size():
		var row: Array = map[y]
		for x in row.size():
			var tile_x := x * TILE
			var tile_y := y * TILE
			match int(row[x]):
				1:
					_add_wall(tile_x, tile_y)
					if x == 0:
						_add_wall(tile_x - TILE, tile_y)
					elif x == row.size() - 1:
						_add_wall(tile_x + TILE, tile_y)
					elif y == 0:
						_add_wall(tile_x, tile_y - TILE)
					elif y == map.size() - 1:
						_add_wall(tile_x, tile_y + TILE)
				2:
					_add_brick(tile_x, tile_y)
				3:
					player.position = Vector2(tile_x, tile_y)
					player.bomb_count = int(values["bombs"])
					player.bomb_size = int(values["size"])
				4:
					_add_bomb_box(tile_x, tile_y)
				5:
					_add_fire_box(tile_x, tile_y)
				7:
					_add_person(tile_x, tile_y)

func _add_wall(x: int, y: int) -> void:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = load("res://assets/images/wall.png")
	sprite.position = Vector2(x, y)
	world_layer.add_child(sprite)
	walls.append(Rect2(Vector2(x, y), Vector2(TILE, TILE)))
	tile_grid[Vector2i(x / TILE, y / TILE)] = "wall"

func _add_brick(x: int, y: int) -> void:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = load("res://assets/images/brick.png")
	sprite.position = Vector2(x, y)
	world_layer.add_child(sprite)
	var grid_pos := Vector2i(x / TILE, y / TILE)
	brick_sprites[grid_pos] = sprite
	tile_grid[grid_pos] = "brick"
	bricks_remaining += 1

func _add_bomb_box(x: int, y: int) -> void:
	var box := BombBox.new()
	box.setup(Vector2(x, y))
	box.z_index = -1
	world_layer.add_child(box)
	bomb_boxes.append(box)

func _add_fire_box(x: int, y: int) -> void:
	var box := FireBox.new()
	box.setup(Vector2(x, y))
	box.z_index = -1
	world_layer.add_child(box)
	fire_boxes.append(box)

func _add_person(x: int, y: int) -> void:
	var person := Person.new()
	person.setup(Vector2(x, y))
	person.z_index = 5
	world_layer.add_child(person)
	people.append(person)

func _build_ui() -> void:
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	var bomb_texture := load("res://assets/images/bomb.png")
	for i in 19:
		var bomb_icon := Sprite2D.new()
		bomb_icon.centered = false
		bomb_icon.offset = Vector2(0, -6)
		bomb_icon.texture = SpriteSheet.atlas_frame(bomb_texture, 64, 80, 3, 0)
		bomb_icon.position = Vector2(32 * i, 0)
		ui_layer.add_child(bomb_icon)
		bomb_ui.append(bomb_icon)

	for i in 10:
		var fire_icon := Sprite2D.new()
		fire_icon.centered = false
		fire_icon.texture = load("res://assets/images/fire.png")
		fire_icon.position = Vector2(64 * i, Constants.SCREEN_SIZE - 64)
		ui_layer.add_child(fire_icon)
		fire_ui.append(fire_icon)

	update_ui()

	var font := load("res://assets/fonts/Roboto-Medium.ttf")

	level_text = Label.new()
	level_text.text = "Level %d" % level_number
	level_text.add_theme_font_override("font", font)
	level_text.add_theme_font_size_override("font_size", 32)
	level_text.add_theme_color_override("font_color", Color.BLACK)
	ui_layer.add_child(level_text)
	call_deferred("_position_level_text")

	press_talk_label = Label.new()
	press_talk_label.text = "Press ENTER to talk"
	press_talk_label.add_theme_font_override("font", font)
	press_talk_label.add_theme_font_size_override("font_size", 32)
	press_talk_label.add_theme_color_override("font_color", Color.BLACK)
	press_talk_label.visible = false
	ui_layer.add_child(press_talk_label)
	call_deferred("_position_press_talk_label")

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(press_talk_label, "modulate:a", 0.0, 0.2)
	tween.tween_property(press_talk_label, "modulate:a", 1.0, 0.2)

func _position_level_text() -> void:
	var size := level_text.get_minimum_size()
	level_text.position = Vector2(Constants.SCREEN_SIZE - 4 - size.x, Constants.SCREEN_SIZE - 4 - size.y)

func _position_press_talk_label() -> void:
	var size := press_talk_label.get_minimum_size()
	press_talk_label.position = Vector2((Constants.SCREEN_SIZE - size.x) / 2.0, Constants.SCREEN_SIZE - 4 - size.y)

func update_ui() -> void:
	for i in bomb_ui.size():
		bomb_ui[i].visible = i < player.bomb_count
	for i in fire_ui.size():
		fire_ui[i].visible = i < player.bomb_size

func get_solid_rects() -> Array:
	var rects: Array = walls.duplicate()
	for grid_pos in brick_sprites.keys():
		rects.append(Rect2(Vector2(grid_pos.x * TILE, grid_pos.y * TILE), Vector2(TILE, TILE)))
	for bomb in bombs:
		if is_instance_valid(bomb) and bomb.solid:
			rects.append(bomb.get_rect())
	for person in people:
		if is_instance_valid(person):
			rects.append(person.get_rect())
	return rects

func _process(delta: float) -> void:
	_handle_global_keys()

	var solid_rects := get_solid_rects()
	player.update_input_and_move(delta, solid_rects)
	player.collide_and_slide(solid_rects)
	player.update_wrap_sprite()

	if player.can_move and stairs_visible:
		var stairs_center := stairs_sprite.position + Vector2(TILE, TILE) / 2.0
		if player.get_center().distance_to(stairs_center) < 10:
			player.can_move = false
			Game.fade_to(Color.BLACK, 0.75, func(): Game.go_to_level(level_number + 1))
			Game.play_sfx("res://assets/sounds/stairs.wav")

	for bomb in bombs.duplicate():
		if not is_instance_valid(bomb):
			continue
		for fire in fires:
			if is_instance_valid(fire) and bomb.get_rect().intersects(fire.get_rect()):
				bomb.explode_early()
				break

	if not level_failed:
		for fire in fires.duplicate():
			if not is_instance_valid(fire):
				continue
			if player.get_rect().intersects(fire.get_rect()):
				player.die()
			for person in people:
				if is_instance_valid(person) and not person.dead and person.get_rect().intersects(fire.get_rect()):
					person.die()

	for box in bomb_boxes.duplicate():
		if is_instance_valid(box) and player.get_rect().intersects(box.get_rect()):
			box.use()
	for box in fire_boxes.duplicate():
		if is_instance_valid(box) and player.get_rect().intersects(box.get_rect()):
			box.use()

	var enter_down := Input.is_key_pressed(KEY_ENTER)
	var enter_just := enter_down and not _enter_was_down
	_enter_was_down = enter_down

	_update_press_talk_text()
	if press_talk_label.visible and enter_just:
		press_talk_label.visible = false
		for person in people:
			if is_instance_valid(person):
				person.face_player(player.facing)
		_open_text_box(talk_win_text if stairs_visible else talk_text)

func _handle_global_keys() -> void:
	var r_down := Input.is_key_pressed(KEY_R)
	if r_down and not _r_was_down:
		reset_level()
	_r_was_down = r_down

	var esc_down := Input.is_key_pressed(KEY_ESCAPE)
	if esc_down and not _escape_was_down:
		Game.destroy_music()
		Game.go_to_title()
	_escape_was_down = esc_down

func _update_press_talk_text() -> void:
	var action_pos := player.get_action_position()
	var is_visible := false
	for person in people:
		if is_instance_valid(person) and person.get_rect().has_point(action_pos):
			is_visible = true
			break
	press_talk_label.visible = is_visible

func _open_text_box(text: String) -> void:
	var box := TextBoxPopup.new()
	add_child(box)
	box.show_text(text)

func reset_level() -> void:
	Game.play_sfx("res://assets/sounds/reset.wav")
	Game.level_number = level_number
	get_tree().change_scene_to_file("res://scenes/Play.tscn")

func failed_level() -> void:
	if level_failed:
		return
	level_failed = true
	player.die()
	Game.stop_music()
	Game.play_sfx("res://assets/sounds/dead.wav")
	Game.flash(Color.RED, 0.2)
	get_tree().create_timer(2.0).timeout.connect(func():
		if PlayState.instance == self:
			reset_level()
	)

func try_place_bomb(pos: Vector2, size: int) -> bool:
	var snapped := Vector2(
		floor((pos.x + 32) / TILE) * TILE,
		floor((pos.y + 32) / TILE) * TILE
	)
	for bomb in bombs:
		if is_instance_valid(bomb) and bomb.position == snapped:
			return false

	var bomb := Bomb.new()
	bomb.z_index = 3
	world_layer.add_child(bomb)
	bomb.setup(snapped, size)
	bombs.append(bomb)
	return true

func remove_bomb(bomb: Bomb) -> void:
	bombs.erase(bomb)

func remove_fire(fire: Fire) -> void:
	fires.erase(fire)

func remove_bomb_box(box: BombBox) -> void:
	bomb_boxes.erase(box)

func remove_fire_box(box: FireBox) -> void:
	fire_boxes.erase(box)

## Ports PlayState.hx createFires(): a recursive plus-shaped blast. Stops
## immediately at a wall tile, stops (after destroying it) at a brick tile,
## otherwise keeps spreading in its direction until size reaches 0.
func create_fires(pos: Vector2, size: int, dir: int = Constants.Dir.NONE) -> void:
	if size == 0:
		return

	var grid_pos := Vector2i(int(pos.x) / TILE, int(pos.y) / TILE)
	var tile: String = tile_grid.get(grid_pos, "")
	if tile == "wall":
		return

	var fire := Fire.new()
	fires_layer.add_child(fire)
	fire.setup(pos)
	fires.append(fire)

	if tile == "brick":
		get_tree().create_timer(0.2).timeout.connect(func(): _destroy_brick(grid_pos, pos))
		return

	var dir_x := 0
	var dir_y := 0
	match dir:
		Constants.Dir.NONE:
			create_fires(pos + Vector2(0, -TILE), size, Constants.Dir.UP)
			create_fires(pos + Vector2(0, TILE), size, Constants.Dir.DOWN)
			create_fires(pos + Vector2(-TILE, 0), size, Constants.Dir.LEFT)
			create_fires(pos + Vector2(TILE, 0), size, Constants.Dir.RIGHT)
			return
		Constants.Dir.UP:
			dir_y = -1
		Constants.Dir.DOWN:
			dir_y = 1
		Constants.Dir.LEFT:
			dir_x = -1
		Constants.Dir.RIGHT:
			dir_x = 1

	create_fires(pos + Vector2(dir_x * TILE, dir_y * TILE), size - 1, dir)

func _destroy_brick(grid_pos: Vector2i, world_pos: Vector2) -> void:
	if PlayState.instance != self:
		return
	var sprite: Sprite2D = brick_sprites.get(grid_pos)
	if sprite == null:
		return

	sprite.queue_free()
	brick_sprites.erase(grid_pos)
	tile_grid.erase(grid_pos)
	bricks_remaining -= 1

	if bricks_remaining == 0 and not stairs_visible:
		_reveal_stairs(world_pos)

func _reveal_stairs(world_pos: Vector2) -> void:
	stairs_visible = true
	stairs_sprite.visible = true
	stairs_sprite.position = world_pos
	Game.stop_music()
	var sfx := Game.play_sfx("res://assets/sounds/find_stairs.wav")
	sfx.finished.connect(func():
		if PlayState.instance != self or level_failed:
			return
		Game.play_music_once("res://assets/sounds/exit.ogg")
		for person in people:
			if is_instance_valid(person):
				person.play_win()
	)

func _exit_tree() -> void:
	if stairs_visible:
		Game.destroy_music()
