package funkin.options.categories;

import funkin.options.categories.*;

class AppearanceOptions extends OptionsScreen {
	public override function new(title:String, desc:String) {
		super(title, desc, "AppearanceOptions.");
		add(new ArrayOption(
			"Overall quality",
			"Automatically adjusts some quality settings depending on which value you choose",
			["low", "high", "custom"],
			["Low", "High", "Custom"],
			"overallQuality"));
		add(new NumOption(
			getName("framerate"),
			getDesc("framerate"),
			30, // minimum
			240, // maximum
			10, // change
			"framerate", // save name or smth
			__changeFPS)); // callback
		#if sys
		if (!Main.forceGPUOnlyBitmapsOff) {
			add(new Checkbox(
				"Load sprites on GPU",
				"If checked, will only store the bitmaps in the GPU, freeing a LOT of memory (EXPERIMENTAL). Turning this off will consume a lot of memory, especially on bigger sprites. If you aren't sure, leave this on.",
				"gpuOnlyBitmaps"));
		}
		#end
		add(new Separator());
		add(new Checkbox(
			getName("antialiasing"),
			getDesc("antialiasing"),
			"antialiasing"));
		add(new Checkbox(
			getName("colorHealthBar"),
			getDesc("colorHealthBar"),
			"colorHealthBar"));
		add(new Checkbox(
			getName("week6PixelPerfect"),
			getDesc("week6PixelPerfect"),
			"week6PixelPerfect"));
		add(new Separator());
		add(new TextOption(
			"Advanced",
			"Options for advanced preferences.",
			function() parent.add(new AppearanceAdvancedOptions())
		));
	}

	private function __changeFPS(change:Float) {
		// if statement cause of the flixel warning
		if(FlxG.updateFramerate < Std.int(change))
			FlxG.drawFramerate = FlxG.updateFramerate = Std.int(change);
		else
			FlxG.updateFramerate = FlxG.drawFramerate = Std.int(change);
	}
}