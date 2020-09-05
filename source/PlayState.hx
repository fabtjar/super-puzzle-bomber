import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import openfl.Assets;

class PlayState extends FlxState
{
	public static var instance:PlayState;

	public var player:Player;

	var levelNumber = 1;
	var solids:FlxTypedSpriteGroup<FlxSprite>;
	var walls:FlxTypedSpriteGroup<FlxSprite>;
	var bricks:FlxTypedSpriteGroup<FlxSprite>;
	var bombs:FlxTypedSpriteGroup<FlxSprite>;
	var fires:FlxTypedGroup<FlxSprite>;
	var stairs:FlxSprite;
	var bombBoxes:FlxTypedGroup<BombBox>;
	var fireBoxes:FlxTypedGroup<FireBox>;

	var bombUI:FlxTypedGroup<FlxSprite>;
	var fireUI:FlxTypedGroup<FlxSprite>;

	public function new(levelNumber:Int = 1)
	{
		super();

		if (Assets.exists("assets/data/levels/level_" + levelNumber + ".json"))
			this.levelNumber = levelNumber;
		else
			this.levelNumber = 1;
	}

	override public function create()
	{
		super.create();

		instance = this;

		bgColor = FlxColor.fromRGB(129, 240, 155);
		FlxG.mouse.useSystemCursor = true;
		FlxG.inputs.resetOnStateSwitch = false;
		FlxG.camera.antialiasing = true;

		FlxG.camera.flash(FlxColor.WHITE, .5);

		if (FlxG.sound.music == null || !FlxG.sound.music.active)
		{
			FlxG.sound.playMusic("assets/sounds/music.ogg");
			FlxG.sound.music.persist = true;
		}

		stairs = new FlxSprite();
		stairs.loadGraphic("assets/images/stairs.png");
		stairs.visible = false;
		add(stairs);

		bombBoxes = new FlxTypedGroup();
		add(bombBoxes);

		fireBoxes = new FlxTypedGroup();
		add(fireBoxes);

		solids = new FlxTypedSpriteGroup();
		add(solids);

		walls = new FlxTypedSpriteGroup();
		solids.add(walls);

		bricks = new FlxTypedSpriteGroup();
		solids.add(bricks);

		bombs = new FlxTypedSpriteGroup();
		add(bombs);
		solids.add(bombs);

		fires = new FlxTypedGroup();
		add(fires);

		player = new Player();
		add(player);

		loadLevel();
		solids.forEach(solid -> solid.immovable = true, true);

		bombUI = new FlxTypedGroup();
		add(bombUI);
		for (i in 0...19)
		{
			var bomb = new FlxSprite(32 * i, 0);
			bomb.loadGraphic("assets/images/bomb.png", true, 64, 80);
			bomb.offset.y = 6;
			bombUI.add(bomb);
		}

		fireUI = new FlxTypedGroup();
		add(fireUI);
		for (i in 0...10)
		{
			var fire = new FlxSprite(64 * i, FlxG.height - 64);
			fire.loadGraphic("assets/images/fire.png");
			fireUI.add(fire);
		}

		updateUI();
	}

	function loadLevel()
	{
		var levelText = Assets.getText("assets/data/levels/level_" + levelNumber + ".json");
		var levelData = Json.parse(levelText);
		var map:Array<Array<Int>> = levelData.layers[0].data2D;

		for (y in 0...map.length)
		{
			for (x in 0...map[y].length)
			{
				var tileX = x * 64;
				var tileY = y * 64;
				switch map[y][x]
				{
					case 1:
						walls.add(new FlxSprite(tileX, tileY, "assets/images/wall.png"));
						if (x == 0)
							walls.add(new FlxSprite(tileX - 64, tileY, "assets/images/wall.png"));
						else if (x == map[y].length - 1)
							walls.add(new FlxSprite(tileX + 64, tileY, "assets/images/wall.png"));
						else if (y == 0)
							walls.add(new FlxSprite(tileX, tileY - 64, "assets/images/wall.png"));
						else if (y == map.length - 1)
							walls.add(new FlxSprite(tileX, tileY + 64, "assets/images/wall.png"));
					case 2:
						bricks.add(new FlxSprite(tileX, tileY, "assets/images/brick.png"));
					case 3:
						player.setPosition(tileX, tileY);
						player.bombCount = levelData.values.bombs;
						player.bombSize = levelData.values.size;
					case 4:
						bombBoxes.add(new BombBox(tileX, tileY));
					case 5:
						fireBoxes.add(new FireBox(tileX, tileY));
				}
			}
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.R)
			resetLevel();

		if (FlxG.keys.pressed.ESCAPE)
			FlxG.switchState(new TitleState());

		player.collideAndSlide(solids);
		player.updateWrapSprite();

		if (player.canMove && stairs.visible && player.getPosition().distanceTo(stairs.getPosition()) < 10)
		{
			player.canMove = false;
			FlxG.camera.fade(FlxColor.BLACK, .75, false, () -> FlxG.switchState(new PlayState(levelNumber + 1)));
			FlxG.sound.play("assets/sounds/stairs.wav").persist = true;
		}

		FlxG.overlap(bombs, fires, (bomb:Bomb, _) -> bomb.explodeEarly());

		if (player.canMove)
			FlxG.overlap(player, fires, (_, _) -> player.dead());

		FlxG.overlap(player, bombBoxes, (_, bombBox:BombBox) -> bombBox.use());
		FlxG.overlap(player, fireBoxes, (_, fireBox:FireBox) -> fireBox.use());
	}

	public function resetLevel()
	{
		FlxG.switchState(new PlayState(levelNumber));
		FlxG.sound.play("assets/sounds/reset.wav").persist = true;
	}

	public function createBomb(x:Float, y:Float, size:Int):Bool
	{
		x = Math.floor((x + 32) / 64) * 64;
		y = Math.floor((y + 32) / 64) * 64;

		if (bombs.overlapsPoint(new FlxPoint(x, y)))
			return false;

		var bomb = new Bomb(x, y, size);
		bombs.add(bomb);

		return true;
	}

	public function createFires(x:Float, y:Float, size:Int, dir:Int = FlxObject.NONE)
	{
		if (size == 0)
			return;

		var fire = new FlxSprite(x, y);
		fire.loadGraphic("assets/images/fire.png");
		fire.offset.set(24, 24);
		fire.x += 24;
		fire.y += 24;
		fire.setSize(16, 16);
		new FlxTimer().start(.3, _ -> fire.kill());
		fires.add(fire);

		if (fire.overlaps(walls))
		{
			fires.remove(fire);
			fire.destroy();
			return;
		}

		if (fire.overlaps(bricks))
		{
			FlxG.overlap(fire, bricks, (f:FlxSprite, brick:FlxSprite) ->
			{
				new FlxTimer().start(.2, _ ->
				{
					brick.kill();
					if (bricks.countLiving() == 0 && !stairs.visible)
					{
						stairs.visible = true;
						stairs.setPosition(brick.x, brick.y);
						FlxG.sound.music.stop();
						var exitSound = FlxG.sound.play("assets/sounds/find_stairs.wav");
						exitSound.onComplete = () -> FlxG.sound.playMusic("assets/sounds/exit.ogg", 1, false);
					}
					bricks.remove(brick);
				});
			});

			return;
		}

		var dirX = 0;
		var dirY = 0;

		switch dir
		{
			case FlxObject.NONE:
				createFires(x, y - 64, size, FlxObject.UP);
				createFires(x, y + 64, size, FlxObject.DOWN);
				createFires(x - 64, y, size, FlxObject.LEFT);
				createFires(x + 64, y, size, FlxObject.RIGHT);
				return;
			case FlxObject.UP:
				dirY = -1;
			case FlxObject.DOWN:
				dirY = 1;
			case FlxObject.LEFT:
				dirX = -1;
			case FlxObject.RIGHT:
				dirX = 1;
		}

		createFires(x + dirX * 64, y + dirY * 64, size - 1, dir);
	}

	public function updateUI()
	{
		for (i in 0...bombUI.length)
			bombUI.members[i].visible = i < player.bombCount;

		for (i in 0...fireUI.length)
			fireUI.members[i].visible = i < player.bombSize;
	}

	override public function destroy()
	{
		super.destroy();
		if (stairs.visible)
			FlxG.sound.music.destroy();
	}
}
