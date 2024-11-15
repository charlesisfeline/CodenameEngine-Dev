package funkin.game;

using StringTools;
//using flixel.util.FlxArrayUtil;

/**
 * Judges thing and returns thing.
 *
 * please describe this better later, I don't know how to :P
 * @author crowplexus
 */
class RatingManager {
	public var ratingsList:Array<Rating> = [];
	
	public function new():Void {
		ratingsList = getRatingsDefault();
	}

	/**
	 * Returns a rating based on a window of time
	 * @param diff		The timing window to judge, usually `Math.abs(Conductor.songPosition - note.strumTime)`.
	**/
	public function judgeNote(diff: Float):Rating {
		for (idx => rating in ratingsList)
			if (rating.window <= diff)
				return rating;
		return ratingsList.last();
	}

	/**
	 * Simply returns a default ratings list, containing the classic four judgements.
	 *
	 * "Sick, Good, Bad, Shit"
	 */
	 public static function getRatingsDefault():Array<Rating> {
		return [
			{name: "Sick", image: "sick", window: 50.0, accuracy: 1.0, score: 350, splash: true},
			{name: "Good", image: "good", window: 187.5, accuracy: 0.75, score: 200, splash: false},
			{name: "Bad", image: "bad", window: 225.0, accuracy: 0.45, score: 100, splash: false},
			{name: "Shit", image: "shit", window: 250.0, accuracy: 0.25, score: 50, splash: false}
		];
	}


	/**
	 * Old judgeNote function just in case you want the old system.
	**/
	public static function judgeNoteLegacy(diff: Float, hitWindow: Float = 250.0):Rating {
		// TODO: make this not shit preferably thank you
		var oldRating:String = "sick";
		var oldScore:Int = 300;
		var oldAccuracy:Float = 1;
		var oldWindow: Float = hitWindow * 0.2;
		if (diff > hitWindow * 0.9)
		{
			oldWindow = hitWindow * 0.9;
			oldRating = 'shit';
			oldScore = 50;
			oldAccuracy = 0.25;
		}
		else if (diff > hitWindow * 0.75)
		{
			oldWindow = hitWindow * 0.75;
			oldRating = 'bad';
			oldScore = 100;
			oldAccuracy = 0.45;
		}
		else if (diff > hitWindow * 0.2)
		{
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

/**
 * Basic structure for a rating.
 */
@:structInit
class Rating {
	/**
	 * Judgement name.
	 */
	public var name:String = "Unknown";
	/**
	 * Accuracy amount gained when hitting this judgement.
	 */
	public var accuracy:Float = 0.00;
	/**
	 * Timing window (in milliseconds) to hit this rating.
	 */
	public var window:Float = -1;
	/**
	 * Score amount gained when hitting this rating.
	 */
	public var score:Int = 0;
	/**
	 * If hitting this rating causes a splash to appear on the strumline.
	 */
	@:optional public var splash: Bool = false;
	/**
	 * Image file name (e.g: "sick")
	 *
	 * If unspecified, this rating won't show up when hitting notes.
	 */
	@:optional public var image: String = null;
}
