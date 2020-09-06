import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class Player extends FlxSprite
{
	public var bombCount:Int;
	public var bombSize:Int;
	public var canMove:Bool = true;

	var speed:Float = 240;
	var moveDir:FlxPoint;
	var movement:Float;

	var wrapSprite:FlxSprite;

	public function new()
	{
		super();
		loadGraphic("assets/images/player.png", true, 64, 80);
		animation.add("idle_down", [0]);
		animation.add("idle_up", [4]);
		animation.add("idle_side", [8]);
		animation.add("walk_down", [1, 2, 3, 2], 10);
		animation.add("walk_up", [5, 6, 7, 6], 10);
		animation.add("walk_side", [9, 10, 11, 10], 10);
		animation.play("idle_down");
		offset.y = 16;
		setSize(64, 64);

		wrapSprite = new FlxSprite();
		wrapSprite.offset.y = 16;
		wrapSprite.loadGraphic("assets/images/player.png", true, 64, 80);

		moveDir = new FlxPoint();
	}

	function updateMoveDir()
	{
		moveDir.set();

		if (FlxG.keys.anyPressed([UP, W]))
			moveDir.y -= 1;
		if (FlxG.keys.anyPressed([DOWN, S]))
			moveDir.y += 1;
		if (FlxG.keys.anyPressed([LEFT, A]))
			moveDir.x -= 1;
		if (FlxG.keys.anyPressed([RIGHT, D]))
			moveDir.x += 1;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!canMove)
		{
			animation.play("idle_down");
			return;
		}

		updateMoveDir();

		if (FlxG.keys.justPressed.SPACE && bombCount > 0)
		{
			if (PlayState.instance.createBomb(x, y, bombSize))
			{
				bombCount--;
				PlayState.instance.updateUI();
			}
		}

		movement = speed * elapsed;
		x += moveDir.x * movement;
		y += moveDir.x == 0 ? moveDir.y * movement : 0;
		wrapAroundScreen();

		setAnimation();
	}

	function getFacing():Int
	{
		if (moveDir.y < 0)
			return FlxObject.UP;
		else if (moveDir.y > 0)
			return FlxObject.DOWN;
		else if (moveDir.x < 0)
			return FlxObject.LEFT;
		else if (moveDir.x > 0)
			return FlxObject.RIGHT;
		else
			return FlxObject.DOWN;
	}

	function setAnimation()
	{
		var isMoving = moveDir.x != 0 || moveDir.y != 0;
		flipX = false;
		if (isMoving)
		{
			facing = getFacing();
			switch facing
			{
				case FlxObject.UP:
					animation.play("walk_up");
				case FlxObject.DOWN:
					animation.play("walk_down");
				case FlxObject.LEFT:
					flipX = true;
					animation.play("walk_side");
				case FlxObject.RIGHT:
					animation.play("walk_side");
			}
		}
		else
		{
			switch facing
			{
				case FlxObject.UP:
					animation.play("idle_up");
				case FlxObject.DOWN:
					animation.play("idle_down");
				case FlxObject.LEFT:
					flipX = true;
					animation.play("idle_side");
				case FlxObject.RIGHT:
					animation.play("idle_side");
			}
		}
	}

	function wrapAroundScreen()
	{
		if (x < 0)
		{
			x += FlxG.width;
			last.x += FlxG.width;
		}
		else if (x > FlxG.width)
		{
			x -= FlxG.width;
			last.x -= FlxG.width;
		}
		if (y < 0)
		{
			y += FlxG.height;
			last.y += FlxG.height;
		}
		else if (y > FlxG.height)
		{
			y -= FlxG.height;
			last.y -= FlxG.height;
		}
	}

	public function collideAndSlide(walls:FlxTypedSpriteGroup<FlxSprite>)
	{
		FlxG.collide(this, walls);

		var remainingMovement = movement - (Math.abs(x - last.x) + Math.abs(y - last.y));
		var slidingMovement = remainingMovement * .5;

		var rect = getHitbox();
		if (isTouching(FlxObject.UP))
		{
			if (moveDir.x != 0)
				x += remainingMovement * FlxMath.signOf(moveDir.x);
			else if (!walls.overlapsPoint(new FlxPoint(rect.left + 1, rect.top - 1)))
				x -= slidingMovement;
			else if (!walls.overlapsPoint(new FlxPoint(rect.right - 1, rect.top - 1)))
				x += slidingMovement;
		}
		else if (isTouching(FlxObject.DOWN))
		{
			if (moveDir.x != 0)
				x += remainingMovement * FlxMath.signOf(moveDir.x);
			else if (!walls.overlapsPoint(new FlxPoint(rect.left + 1, rect.bottom + 1)))
				x -= slidingMovement;
			else if (!walls.overlapsPoint(new FlxPoint(rect.right - 1, rect.bottom + 1)))
				x += slidingMovement;
		}
		else if (isTouching(FlxObject.LEFT))
		{
			if (moveDir.y != 0)
				y += remainingMovement * FlxMath.signOf(moveDir.y);
			else if (!walls.overlapsPoint(new FlxPoint(rect.left - 1, rect.top + 1)))
				y -= slidingMovement;
			else if (!walls.overlapsPoint(new FlxPoint(rect.left - 1, rect.bottom - 1)))
				y += slidingMovement;
		}
		else if (isTouching(FlxObject.RIGHT))
		{
			if (moveDir.y != 0)
				y += remainingMovement * FlxMath.signOf(moveDir.y);
			else if (!walls.overlapsPoint(new FlxPoint(rect.right + 1, rect.top + 1)))
				y -= slidingMovement;
			else if (!walls.overlapsPoint(new FlxPoint(rect.right + 1, rect.bottom - 1)))
				y += slidingMovement;
		}
		FlxG.collide(this, walls);
	}

	public function updateWrapSprite()
	{
		var rect = getHitbox();

		wrapSprite.visible = true;
		wrapSprite.frame = frame;
		wrapSprite.x = x;
		wrapSprite.y = y;

		if (rect.left < 0)
			wrapSprite.x = x + FlxG.width;
		else if (rect.right > FlxG.width)
			wrapSprite.x = x - FlxG.width;
		else if (rect.top - offset.y < 0)
			wrapSprite.y = y + FlxG.height;
		else if (rect.bottom > FlxG.height)
			wrapSprite.y = y - FlxG.height;
		else
			wrapSprite.visible = false;
	}

	public function dead()
	{
		canMove = false;
		FlxG.sound.music.stop();
		FlxG.sound.play("assets/sounds/dead.wav");
		color = FlxColor.GRAY;

		FlxG.camera.flash(FlxColor.RED, .2);
		FlxTimer.globalManager.clear();
		new FlxTimer().start(2, _ -> PlayState.instance.resetLevel());
	}

	override public function draw()
	{
		super.draw();
		if (wrapSprite.visible)
			wrapSprite.draw();
	}
}
