package funkin.game.scoring;

/**
 * Basic structure for a rating.
 */
@:structInit
class RatingData {
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
	@:optional public var splash:Bool = false;

	/**
	 * Image file name (e.g: "sick")
	 *
	 * If unspecified, this rating won't show up when hitting notes.
	 */
	@:optional public var image:String = null;

	/**
	 * If this rating is hittable, doesn't get accounted for otherwise.
	 */
	@:optional public var hittable:Bool = true;
}
