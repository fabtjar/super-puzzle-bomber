import flixel.FlxSprite;
import flixel.util.FlxColor;

class Person extends FlxSprite
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/person.png", true, 64, 64);
		animation.add("idle_down", [0]);
		animation.add("win", [3, 0], 2);
		animation.play("idle_down");
		offset.y = 16;
	}

	public function dead()
	{
		color = FlxColor.GRAY;
		animation.play("idle_down");
		PlayState.instance.failedLevel();
	}
}
