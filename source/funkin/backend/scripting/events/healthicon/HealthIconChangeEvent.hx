package funkin.backend.scripting.events.healthicon;

import flixel.util.typeLimit.OneOfTwo;

final class HealthIconChangeEvent extends CancellableEvent {
	/**
	 * Amount
	 */
	public var amount:OneOfTwo<String, Int>;

	/**
	 * The health icon
	 */
	public var healthIcon:funkin.game.HealthIcon;
}