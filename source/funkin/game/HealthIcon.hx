package funkin.game;

import haxe.xml.Access;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import flixel.util.typeLimit.OneOfTwo;

class HealthIcon extends FunkinSprite
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
	 * XML Animated Icon data
	 */
	public var xmlData:Access;

	/**
	 * Extra offsets to add when updating the hitbox
	 */
	public var extraOffsets:FlxPoint = FlxPoint.get();

	/**
	 * Helper for HScript who can't make maps
	 * @param steps Something like this: `[[0, 1], [20, 0]]` or `[[0, "losing"], [20, "neutral"]]` for animated icons
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

		animation.finishCallback = animFinishCallback;

		scrollFactor.set();
	}

	public dynamic function bump()
	{
		var iconScale = Flags.BOP_ICON_SCALE;
		scale.set(defaultScale * iconScale, defaultScale * iconScale);
		updateHitbox();
	}

	public dynamic function updateBump()
	{
		var iconLerp = Flags.ICON_LERP;
		scale.set(CoolUtil.fpsLerp(scale.x, defaultScale, iconLerp), CoolUtil.fpsLerp(scale.y, defaultScale, iconLerp));
		updateHitbox();
	}

	public function setIcon(char:String, animated:Bool = true) {
		if(curCharacter != char) {
			curCharacter = char;
			var iconPath = char;
			var path = Paths.image('icons/$char');
			var iconXmlPath = Paths.getPath('images/icons/$char/data.xml');
			var iconFoundAnimated = Assets.exists(iconXmlPath);
			if (!Assets.exists(path) && !iconFoundAnimated)
			{
				iconPath = Flags.DEFAULT_HEALTH_ICON;
				path = Paths.image('icons/' + Flags.DEFAULT_HEALTH_ICON);
			}

			this.animated = animated && iconFoundAnimated;

			if (this.animated)
			{
				frames = Paths.getSparrowAtlas('icons/$iconPath/icon');
				
				var plainXML:String = Assets.getText(iconXmlPath);

				var iconDataXML:Xml = Xml.parse(plainXML).firstElement();
				if (iconDataXML == null)  {
					//go to normal icon instead
					setIcon(char, false);
					return;
				}
				xmlData = new Access(iconDataXML);

				for(node in xmlData.elements)
					switch(node.name) {
						case "transition":
							if (node.has.offsetx || node.has.offsety)
								addOffset('from-${node.x.get("from")}-to-${node.x.get("to")}', Std.parseFloat(node.x.get("offsetx")).getDefault(0), Std.parseFloat(node.x.get("offsety")).getDefault(0));
							animation.addByPrefix('from-${node.x.get("from")}-to-${node.x.get("to")}', node.x.get("anim"), Std.parseInt(node.x.get("fps")).getDefault(24), node.x.get("looped").getDefault("false").toLowerCase() == "true", isPlayer);
						case "anim":
							if (node.has.offsetx || node.has.offsety)
								addOffset(node.x.get("name"), Std.parseFloat(node.x.get("offsetx")).getDefault(0), Std.parseFloat(node.x.get("offsety")).getDefault(0));
							animation.addByPrefix(node.x.get("name"), node.x.get("anim"), Std.parseInt(node.x.get("fps")).getDefault(24), node.x.get("looped").getDefault("false").toLowerCase() == "true", isPlayer);
						case "steps":
							var parsedSteps:Map<Int, String> = [];
							for(subnode in node.elements)
								parsedSteps.set(Std.parseInt(subnode.x.get("percent")).getDefault(0), subnode.x.get("type"));
							
							healthSteps = parsedSteps;
					}

				//normaized anim name for the engine to check if a certain exists
				var animationsPrefixes:Array<String> = ["neutral", "losing", "winning"];
				var animsFound:Map<String, Bool> = [];

				for (name in animationsPrefixes)
					animsFound.set(name, animation.getByName(name) != null);

				playAnim("neutral");

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
				playAnim(char);

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
						var animName = 'from-${animation.curAnim.name.substr(animation.curAnim.name.lastIndexOf('-') + 1)}-to-${event.animOrFrame}';
						var toAnimExists = hasAnimation(animName);
						if (!toAnimExists)
							animName = event.animOrFrame;

						if (hasAnimation(animName))
							playAnim(animName);
					} else
						animation.curAnim.curFrame = event.animOrFrame;
				}

				curAnimState = event.animOrFrame;
			}
		}
	}

	function animFinishCallback(anim:String)
	{
		var event = EventManager.get(funkin.backend.scripting.events.healthicon.HealthIconAnimFinishedEvent).recycle(anim, this);
		funkin.backend.scripting.GlobalScript.event("onHealthIconAnimFinished", event);
		if (animated) {
			if (anim.startsWith("from-"))
				playAnim(anim.substr(anim.lastIndexOf('-') + 1));
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset += extraOffsets;
	}
}
