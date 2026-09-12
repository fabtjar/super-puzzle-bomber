import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class Person extends FlxSprite
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/person.png", true, 64, 64);
		animation.add("idle_down", [0]);
		animation.add("idle_up", [1]);
		animation.add("idle_side", [2]);
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

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		animation.play("idle_down");
		flipX = false;
	}

	public function facePlayer(playerFacing:Int)
	{
		switch playerFacing
		{
			case FlxObject.UP:
				animation.play("idle_down");
			case FlxObject.DOWN:
				animation.play("idle_up");
			case FlxObject.LEFT:
				animation.play("idle_side");
			case FlxObject.RIGHT:
				animation.play("idle_side");
				flipX = true;
		}
	}
}
