import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;

class TitleState extends FlxState
{
	override public function create()
	{
		super.create();
		FlxG.mouse.useSystemCursor = true;
		bgColor = FlxColor.fromRGB(129, 240, 155);

		loadBackground();

		var title = new FlxText(0, 160, FlxG.width);
		title.text = "Puzzle Bomber";
		title.setFormat("assets/fonts/Roboto-Medium.ttf", 48, FlxColor.BLACK, CENTER);
		add(title);

		var intructions = new FlxText(0, 250, FlxG.width);
		intructions.text = "Arrow keys to move\nSpacebar to bomb\nR to restart\n\nDestroy all the bricks\nto find the exit";
		intructions.setFormat("assets/fonts/Roboto-Medium.ttf", 32, FlxColor.BLACK, CENTER);
		add(intructions);
	}

	function loadBackground()
	{
		var levelText = Assets.getText("assets/data/levels/title.json");
		var levelData = Json.parse(levelText);
		var map:Array<Array<Int>> = levelData.layers[0].data2D;

		var tiles = new FlxSpriteGroup();
		add(tiles);

		for (y in 0...map.length)
		{
			for (x in 0...map[y].length)
			{
				var tileX = x * 64;
				var tileY = y * 64;
				switch map[y][x]
				{
					case 1:
						tiles.add(new FlxSprite(tileX, tileY, "assets/images/wall.png"));
					case 2:
						tiles.add(new FlxSprite(tileX, tileY, "assets/images/brick.png"));
				}
			}
		}
	}

	override public function update(elapased:Float)
	{
		super.update(elapased);
		if (FlxG.keys.anyPressed([ENTER, SPACE, UP, DOWN, LEFT, RIGHT, W, A, S, D]))
			FlxG.switchState(new PlayState());
	}
}
