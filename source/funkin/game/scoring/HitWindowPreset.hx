package funkin.game.scoring;

/**
 * Abstract enum containing generic functions for timing presets.
**/
enum abstract HitWindowPreset(Int) from Int to Int
{
	var CUSTOM = -1;
	var JUDGE_FIVE = 0;
	var CNE_CLASSIC = 1;
	var FNF_CLASSIC = 2;
	var FNF_CURRENT = 3;

	public static function list()
	{
		// TODO: hscript support?
		return [
			JUDGE_FIVE.toString(),
			CNE_CLASSIC.toString(),
			FNF_CLASSIC.toString(),
			FNF_CURRENT.toString(),
			"Custom"
		];
	}

	public function toString():String
	{
		return switch (this)
		{
			case CNE_CLASSIC: "Codename (Classic)";
			case FNF_CLASSIC: "Funkin' (Week 7)";
			case FNF_CURRENT: "Funkin' (V-Slice)";
			case CUSTOM: "Custom";
			case _: "Judge Five";
		}
	}

	public function listTimings():Array<Float>
	{
		return switch (this)
		{
			// old CNE timings, shit ratings are pretty hard to get with these
			case CNE_CLASSIC: [50.0, 187.5, 225.0, 250.0];
			// week 7, these where real specific damn
			case FNF_CLASSIC: [33.334, 125.0025, 150.003, 166.67];
			// current FNF, PBOT1 hit windows
			case FNF_CURRENT: [45.0, 90.0, 135.0, 160.0];
			// self explanatory
			////case CUSTOM: [Options.sick, Options.good, Options.bad, Options.shit];
			// current (default) timings, taken from etterna
			case _: [37.8, 75.6, 113.4, 180.0];
		}
	}
}
