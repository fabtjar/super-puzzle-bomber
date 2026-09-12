## Global singleton. Ports the pieces of the original that lived outside any
## single FlxState: persistent background music (FlxG.sound.music with
## .persist = true), fire-and-forget sound effects (FlxG.sound.play), and
## camera flash/fade (FlxG.camera.flash / .fade). Also carries the level
## number across scene changes, since Godot scenes take no constructor args.
extends Node

var level_number: int = 1

var music_player: AudioStreamPlayer
var _flash_layer: CanvasLayer
var _flash_rect: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)

	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 100
	add_child(_flash_layer)

	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.size = Vector2(Constants.SCREEN_SIZE, Constants.SCREEN_SIZE)
	_flash_layer.add_child(_flash_rect)

## Starts looping music only if nothing is currently playing - mirrors
## `if (FlxG.sound.music == null || !FlxG.sound.music.active)`.
func ensure_music_playing(path: String) -> void:
	if music_player.playing:
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	music_player.stream = stream
	music_player.play()

## Plays a track once, no looping (used for the exit fanfare).
func play_music_once(path: String) -> void:
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = false
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()

## Fully clears the music so the next ensure_music_playing() starts fresh.
func destroy_music() -> void:
	music_player.stop()
	music_player.stream = null

func play_sfx(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player

func flash(color: Color, duration: float) -> void:
	_flash_rect.color = Color(color.r, color.g, color.b, 1.0)
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, duration)

func fade_to(color: Color, duration: float, on_complete: Callable) -> void:
	_flash_rect.color = Color(color.r, color.g, color.b, 0.0)
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 1.0, duration)
	tween.tween_callback(on_complete)

func go_to_level(number: int) -> void:
	level_number = number
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Play.tscn")

func go_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Title.tscn")
