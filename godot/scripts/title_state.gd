## Ports source/TitleState.hx.
extends Node2D

const START_KEYS := [
	KEY_ENTER, KEY_SPACE, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT,
	KEY_W, KEY_A, KEY_S, KEY_D,
]

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color8(129, 240, 155)
	bg.size = Vector2(Constants.SCREEN_SIZE, Constants.SCREEN_SIZE)
	add_child(bg)

	_load_background()

	var font := load("res://assets/fonts/Roboto-Medium.ttf")

	var title := Label.new()
	title.text = "Super Puzzle Bomber"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.BLACK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 160)
	title.size = Vector2(Constants.SCREEN_SIZE, 60)
	add_child(title)

	var instructions := Label.new()
	instructions.text = "Arrow keys to move\nSpacebar to bomb\nR to restart\n\nDestroy all the bricks\nto find the exit"
	instructions.add_theme_font_override("font", font)
	instructions.add_theme_font_size_override("font_size", 32)
	instructions.add_theme_color_override("font_color", Color.BLACK)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.position = Vector2(0, 250)
	instructions.size = Vector2(Constants.SCREEN_SIZE, 220)
	add_child(instructions)

func _load_background() -> void:
	var text := FileAccess.get_file_as_string("res://assets/levels/title.json")
	var data: Dictionary = JSON.parse_string(text)
	var map: Array = data["layers"][0]["data2D"]

	for y in map.size():
		var row: Array = map[y]
		for x in row.size():
			var tile_x := x * Constants.TILE_SIZE
			var tile_y := y * Constants.TILE_SIZE
			match int(row[x]):
				1:
					_add_tile("res://assets/images/wall.png", tile_x, tile_y)
				2:
					_add_tile("res://assets/images/brick.png", tile_x, tile_y)

func _add_tile(path: String, x: int, y: int) -> void:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = load(path)
	sprite.position = Vector2(x, y)
	add_child(sprite)

func _process(_delta: float) -> void:
	for key in START_KEYS:
		if Input.is_key_pressed(key):
			Game.go_to_level(1)
			return
