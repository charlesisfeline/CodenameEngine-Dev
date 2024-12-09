package funkin.backend.scripting.events.healthicon;

final class HealthIconAnimFinishedEvent extends CancellableEvent {

	/**
	 * Animation thats finished playing
	 */
	public var animation:String;

	/**
	 * The health icon
	 */
	public var healthIcon:funkin.game.HealthIcon;
}