import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;

class FireBox extends FlxSprite
{
	var random:FlxRandom;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/fire_box.png");
		random = new FlxRandom();
	}

	public function use()
	{
		PlayState.instance.player.bombSize++;
		PlayState.instance.updateUI();
		FlxG.sound.play("assets/sounds/fire_box.wav");
		kill();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		color = FlxColor.interpolate(FlxColor.WHITE, FlxColor.BLACK, random.float(0, .2));
	}
}
