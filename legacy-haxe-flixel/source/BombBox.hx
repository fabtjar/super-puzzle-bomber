import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;

class BombBox extends FlxSprite
{
	var random:FlxRandom;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/bomb_box.png");
		random = new FlxRandom();
	}

	public function use()
	{
		PlayState.instance.player.bombCount++;
		PlayState.instance.updateUI();
		FlxG.sound.play("assets/sounds/bomb_box.wav");
		kill();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		color = FlxColor.interpolate(FlxColor.WHITE, FlxColor.BLACK, random.float(0, .2));
	}
}
