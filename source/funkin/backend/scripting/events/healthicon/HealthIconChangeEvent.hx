package funkin.backend.scripting.events.healthicon;

import flixel.util.typeLimit.OneOfTwo;

final class HealthIconChangeEvent extends CancellableEvent {
	/**
	 * Animation or Frame that is about to ne played
	 */
	public var animOrFrame:OneOfTwo<String, Int>;

	/**
	 * The health icon
	 */
	public var healthIcon:funkin.game.HealthIcon;
}