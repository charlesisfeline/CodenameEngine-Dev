package funkin.game.scoring;

using StringTools;

// wip
enum abstract HitWindowPreset(Int) from Int to Int {
	var JUDGE_FIVE = 0;
	var CNE_CLASSIC = 1;
	var FNF_CLASSIC = 2;
	var FNF_CURRENT = 3;

	public function list():Array<Float> {
		return switch (this) {
			// old CNE timings, shit ratings are pretty hard to get with these
			case CNE_CLASSIC: [50.0, 187.5, 225.0, 250.0];
			// week 7, these where real specific damn
			case FNF_CLASSIC: [33.334, 125.0025, 150.003, 166.67];
			// current FNF, PBOT1 hit windows
			case FNF_CURRENT: [45.0, 90.0, 135.0, 160.0];
			// current timings, based on etterna
			case _: [37.8, 75.6, 113.4, 180.0];
		}
	}

	public function toString():String {
		return switch (this) {
			// current timings
			case CNE_CLASSIC: "Codename (Classic)";
			case FNF_CLASSIC: "Funkin' (Week 7)";
			case FNF_CURRENT: "Funkin' (V-Slice)";
			case _: "Judge Five";
		}
	}
}

/**
 * Judges thing and returns thing.
 *
 * please describe this better later, I don't know how to :P
 * @author crowplexus
 */
class RatingManager {
	public var ratingsList:Array<RatingData> = [];

	public function new():Void {
		ratingsList = getRatingsDefault();
	}

	/**
	 * Returns a rating based on a window of time
	 * @param time		The timing window to judge, usually `Math.abs(Conductor.songPosition - note.strumTime)`.
	**/
	public function judgeNote(time:Float):RatingData {
		for (idx => rating in ratingsList)
			if (rating.hittable && rating.window > -1 && time <= rating.window)
				return rating;
		return ratingsList.last();
	}

	/**
	 * Simply returns a default ratings list, containing the classic four judgements.
	 *
	 * "Sick, Good, Bad, Shit"
	 */
	public static function getRatingsDefault():Array<RatingData> {
		// this kinda sucks and I need to make this *actually* customisable later
		// this is just to have timing presets in the meantime we implement this new system
		// whatever comes off as better windows for the engine generally.
		var hitWindows: Array<Float> = HitWindowPreset.JUDGE_FIVE.list();
		return [
			{name: "Sick", image: "sick", window: hitWindows[0], accuracy: 1.0, score: 350, splash: true},
			{name: "Good", image: "good", window: hitWindows[1], accuracy: 0.75, score: 200, splash: false},
			{name: "Bad", image: "bad", window: hitWindows[2], accuracy: 0.45, score: 100, splash: false},
			{name: "Shit", image: "shit", window: hitWindows[3], accuracy: 0.25, score: 50, splash: false}
		];
	}

	/**
	 * Old judgeNote function just in case you want the old system.
	**/
	public static function judgeNoteLegacy(diff:Float, hitWindow:Float = 250.0):RatingData {
		// TODO: make this not shit preferably thank you
		var oldRating:String = "sick";
		var oldScore:Int = 300;
		var oldAccuracy:Float = 1;
		var oldWindow:Float = hitWindow * 0.2;
		if (diff > hitWindow * 0.9) {
			oldWindow = hitWindow * 0.9;
			oldRating = 'shit';
			oldScore = 50;
			oldAccuracy = 0.25;
		}
		else if (diff > hitWindow * 0.75) {
			oldWindow = hitWindow * 0.75;
			oldRating = 'bad';
			oldScore = 100;
			oldAccuracy = 0.45;
		}
		else if (diff > hitWindow * 0.2) {
			oldWindow = hitWindow * 0.2;
			oldRating = 'good';
			oldScore = 200;
			oldAccuracy = 0.75;
		}
		return {
			name: oldRating.charAt(0).toUpperCase() + oldRating.substr(1), // real specific ik
			window: oldWindow,
			accuracy: oldAccuracy,
			score: oldScore,
			image: oldRating,
			splash: oldRating == "sick",
		};
	}
}
