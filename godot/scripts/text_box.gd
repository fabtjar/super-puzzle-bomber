## Ports source/TextBoxState.hx. A modal dialog box. Pauses the whole scene
## tree while open (process_mode ALWAYS keeps this node itself running) so
## gameplay - bomb fuses, fires, Person's per-frame pose reset - freezes for
## the duration, exactly like the original FlxSubState pausing its parent.
class_name TextBoxPopup
extends CanvasLayer

const WIDTH := 500
const HEIGHT := 200
const BORDER := 5

var _enter_was_down := true

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50

func show_text(text: String) -> void:
	var x := (Constants.SCREEN_SIZE - WIDTH) / 2.0
	var y := float(Constants.SCREEN_SIZE - (HEIGHT + 50))
	var font := load("res://assets/fonts/Roboto-Medium.ttf")

	var background := ColorRect.new()
	background.color = Color(0, 0, 1)
	background.position = Vector2(x, y)
	background.size = Vector2(WIDTH, HEIGHT)
	add_child(background)

	var box_text := Label.new()
	box_text.text = text
	box_text.position = Vector2(x + BORDER, y + BORDER)
	box_text.size = Vector2(WIDTH - BORDER * 2, HEIGHT - BORDER * 2)
	box_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	box_text.add_theme_font_override("font", font)
	box_text.add_theme_font_size_override("font_size", 32)
	box_text.add_theme_color_override("font_color", Color.WHITE)
	add_child(box_text)

	var enter_label := Label.new()
	enter_label.text = "ENTER"
	enter_label.add_theme_font_override("font", font)
	enter_label.add_theme_font_size_override("font_size", 16)
	enter_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(enter_label)
	call_deferred("_position_enter_label", enter_label, x, y)

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(enter_label, "modulate:a", 0.0, 0.2)
	tween.tween_property(enter_label, "modulate:a", 1.0, 0.2)

	Game.play_sfx("res://assets/sounds/reset.wav")
	get_tree().paused = true

func _position_enter_label(enter_label: Label, x: float, y: float) -> void:
	var size := enter_label.get_minimum_size()
	enter_label.position = Vector2(x + WIDTH - size.x - BORDER, y + HEIGHT - size.y - BORDER)

func _process(_delta: float) -> void:
	var down := Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
	if down and not _enter_was_down:
		Game.play_sfx("res://assets/sounds/reset.wav")
		get_tree().paused = false
		queue_free()
	_enter_was_down = down
