package funkin.game;

import flixel.graphics.FlxGraphic;
import flixel.util.typeLimit.OneOfTwo;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	/**
	 * The currently showing icon
	 */
	public var curCharacter:String = null;

	/**
	 * If the character is for the player
	 */
	public var isPlayer:Bool;

	/**
	 * Health steps in this format:
	 * Min Percentage => Frame Index
	 */
	public var healthSteps:Map<Int, OneOfTwo<String, Int>> = null;

	/**
	 * current animation state
	 */
	public var curAnimState:OneOfTwo<String, Int> = -1;

	/**
	 * The Default Scale For The Icon
	 */
	public var defaultScale:Float = 1;


	/**
	 * Whenever or not the icon is animated
	 */
	 public var animated:Bool = false;

	/**
	 * Helper for HScript who can't make maps
	 * @param steps Something like this: `[[0, 1], [20, 0]]`
	 */
	public function setHealthSteps(steps:Array<Array<OneOfTwo<String, Int>>>) { // helper for hscript that can't do maps
		if (steps == null) return;
		healthSteps = [];
		for(s in steps)
			if (s.length > 1)
				healthSteps[s[0]] = s[1];
		var am = 0;
		for(k=>e in healthSteps) am++;

		if (am <= 0) healthSteps = [
			0 => animated ? "losing" : 1, // losing icon
			20 => animated ? "neutral" : 0, // normal icon
		];
	}

	public function new(?char:String, isPlayer:Bool = false)
	{
		super();
		health = 0.5;
		this.isPlayer = isPlayer;
		setIcon(char != null ? char : Flags.DEFAULT_CHARACTER);

		scrollFactor.set();
	}

	public function setIcon(char:String, animated:Bool = true) {
		if(curCharacter != char) {
			curCharacter = char;
			var iconPath = char;
			var path = Paths.image('icons/$char');
			if (!Assets.exists(path))
			{
				iconPath = Flags.DEFAULT_HEALTH_ICON;
				path = Paths.image('icons/' + Flags.DEFAULT_HEALTH_ICON);
			}
			var iconXmlPath = Paths.getPath('images/icons/$iconPath.xml');
			var iconFoundAnimated = Assets.exists(iconXmlPath);

			this.animated = animated && iconFoundAnimated;

			if (this.animated)
			{
				frames = Paths.getSparrowAtlas('icons/$iconPath');

				//normaized anim name for the engine => animations names for idk what you want
				var animationsPrefixes:Map<String, Array<String>> = [
					"neutral" => ["neutral", "normal"],
					"losing" => ["losing", "loss", "lose"],
					"winning" => ["winning", "win"],
				];
				var animsFound:Map<String, Bool> = [];

				for (name => prefixes in animationsPrefixes)
				{
					for (i in 0...prefixes.length)
					{
						var prefix = prefixes[i];
						var prevPrefix = prefixes[i - 1]; //to check if an anim has started checking stuff
						if (prevPrefix != null)
						{
							if (animation.getByName(name) == null)
								animation.addByPrefix(name, prefix, 24, true, isPlayer);
						} else 
							animation.addByPrefix(name, prefix, 24, true, isPlayer);
					}

					animsFound.set(name, animation.getByName(name) != null);
				}

				animation.play("neutral");

				healthSteps = [
					0  => "losing", // losing icon
					20 => "neutral", // normal icon
				];

				if (animsFound["winning"])
					healthSteps[80] = "winning"; // winning icon
			} else {
				var iconAsset:FlxGraphic = FlxG.bitmap.add(path);
				var assetW:Float = iconAsset.width; var assetH:Float = iconAsset.height;

				var iconAmt:Int = Math.floor(assetW / assetH);
				var iconSize:Int = Math.floor(assetW / iconAmt);

				loadGraphic(iconAsset, true, iconSize, iconSize);

				setGraphicSize(150);
				updateHitbox();

				animation.add(char, [for(i in 0...iconAmt) i], 0, false, isPlayer);
				animation.play(char);

				healthSteps = [
					0  => 1, // losing icon
					20 => 0, // normal icon
				];

				if (iconAmt >= 3)
					healthSteps[80] = 2; // winning icon
			}
			antialiasing = true;
			defaultScale = scale.x;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);

		if (animation.curAnim != null) {
			var i:OneOfTwo<String, Int> = -1;
			var oldKey:Int = -1;
			for (k=>icon in healthSteps) if (k > oldKey && k <= health * 100) {
				oldKey = k;
				i = icon;
			}
			var isInt = Std.isOfType(i, Int);
			var iInt:Int = cast i;

			var localAnimState = animated ? (isInt ? "neutral" : Std.string(i)) : (isInt ? i : 0);
			if ((isInt ? (iInt >= 0) : true) && curAnimState != localAnimState) {
				var event = EventManager.get(funkin.backend.scripting.events.healthicon.HealthIconChangeEvent).recycle(i, this);
				funkin.backend.scripting.GlobalScript.event("onHealthIconAnimChange", event);
				if (!event.cancelled) {
					if (animated) {
						animation.play(event.amount);
					} else
						animation.curAnim.curFrame = event.amount;
				}

				curAnimState = event.amount;
			}
		}
	}
}
