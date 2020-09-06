import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class TextBoxState extends FlxSubState
{
	var width:Int = 500;
	var height:Int = 200;
	var border:Int = 5;
	var text:String;

	public function new(text:String)
	{
		super();
		this.text = text;
	}

	override function create()
	{
		super.create();

		FlxG.inputs.reset();

		var x = (FlxG.width - width) / 2;
		var y = FlxG.height - (height + 50);

		var background = new FlxSprite(x, y);
		background.makeGraphic(width, height, FlxColor.BLUE);
		add(background);

		var boxText = new FlxText(x + border, y + border, width - border * 2);
		boxText.setFormat("assets/fonts/Roboto-Medium.ttf", 32, FlxColor.WHITE);
		boxText.text = text;
		add(boxText);

		var enterText = new FlxText(x + width, y + height, 0, "ENTER");
		enterText.setFormat("assets/fonts/Roboto-Medium.ttf", 16, FlxColor.WHITE);
		enterText.x -= enterText.width + border;
		enterText.y -= enterText.height + border;
		FlxTween.tween(enterText, {alpha: 0}, .2, {type: FlxTweenType.PINGPONG});
		add(enterText);

		FlxG.sound.play("assets/sounds/reset.wav");
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.sound.play("assets/sounds/reset.wav");
			close();
		}
	}
}
