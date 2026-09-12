import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxTimer;

class Bomb extends FlxSprite
{
	var timer:FlxTimer;
	var size:Int;

	public function new(x:Float, y:Float, size:Int)
	{
		super(x, y);
		loadGraphic("assets/images/bomb.png", true, 64, 80);
		animation.add("pulse", [0, 1, 2, 1], 6);
		animation.play("pulse");
		offset.y = 16;
		setSize(64, 64);
		immovable = true;
		allowCollisions = FlxObject.NONE;
		this.size = size;
		explodeTimer(2);
		FlxG.sound.play("assets/sounds/bomb.wav");
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (allowCollisions == FlxObject.ANY)
			return;

		if (!overlaps(PlayState.instance.player))
			allowCollisions = FlxObject.ANY;
	}

	function explodeTimer(time:Float)
	{
		timer = new FlxTimer().start(time, _ ->
		{
			PlayState.instance.createFires(x, y, size);
			FlxG.sound.play("assets/sounds/explode.wav");
			kill();
		});
	}

	public function explodeEarly()
	{
		var timeLeft = timer.timeLeft;
		timer.cancel();
		explodeTimer(Math.min(timeLeft, .1));
	}
}
